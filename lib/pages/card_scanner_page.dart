import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:wallet/l10n/app_localizations.dart';

/// Modes the scanner page can run in.
enum CardScannerMode { fullCard, numberOnly }

/// Data returned from the full-card scanner.
class CardScannerResult {
  final String? number;
  final String? expiry; // "MM/YY"
  final String? holderName;

  const CardScannerResult({this.number, this.expiry, this.holderName});
}

/// Luhn checksum validation for card numbers.
bool _luhnCheck(String digits) {
  if (digits.length < 13 || digits.length > 19) return false;
  int sum = 0;
  bool alternate = false;
  for (int i = digits.length - 1; i >= 0; i--) {
    int n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

/// Extract a valid card number from OCR text.
/// Collects all digit sequences across the entire text, joins nearby groups,
/// and returns the first Luhn-valid 13-19 digit string.
String? _extractCardNumber(String fullText) {
  // Normalize: replace common OCR confusions
  String normalized = fullText
      .replaceAll('O', '0')
      .replaceAll('o', '0')
      .replaceAll('I', '1')
      .replaceAll('l', '1')
      .replaceAll('B', '8')
      .replaceAll(RegExp(r'[^0-9\s\-]'), ' ');

  // Extract all contiguous digit groups
  final groups = RegExp(r'\d{4,}')
      .allMatches(normalized)
      .map((m) => m.group(0)!)
      .toList();

  if (groups.isEmpty) return null;

  // Strategy 1: single group of 13-19 digits
  for (final g in groups) {
    final d = g.replaceAll(RegExp(r'\D'), '');
    if (d.length >= 13 && d.length <= 19 && _luhnCheck(d)) return d;
  }

  // Strategy 2: concatenate consecutive 4-digit groups (common card format: XXXX XXXX XXXX XXXX)
  for (int i = 0; i < groups.length; i++) {
    final buf = StringBuffer();
    for (int j = i; j < groups.length; j++) {
      final d = groups[j].replaceAll(RegExp(r'\D'), '');
      if (d.length > 4 && j > i) break;
      if (d.length < 3) break;
      buf.write(d);
      final total = buf.toString();
      if (total.length >= 13 && total.length <= 19 && _luhnCheck(total)) {
        return total;
      }
      if (total.length > 19) break;
    }
  }

  // Strategy 3: take all digits from the whole text, scan for valid subsequences
  final allDigits = normalized.replaceAll(RegExp(r'\D'), '');
  if (allDigits.length >= 13) {
    for (int len = 19; len >= 13; len--) {
      for (int start = 0; start + len <= allDigits.length; start++) {
        final candidate = allDigits.substring(start, start + len);
        if (_luhnCheck(candidate)) return candidate;
      }
    }
  }

  return null;
}

/// Extract expiry date in MM/YY format.
String? _extractExpiry(String fullText) {
  // Patterns: MM/YY, MM/YYYY, MM-YY, MM-YYYY
  final patterns = [
    RegExp(r'(\d{2})[/\-](\d{2,4})'),
  ];
  for (final p in patterns) {
    for (final m in p.allMatches(fullText)) {
      int? month = int.tryParse(m.group(1)!);
      String yearStr = m.group(2)!;
      if (month == null || month < 1 || month > 12) continue;
      String yy;
      if (yearStr.length == 4) {
        yy = yearStr.substring(2);
      } else if (yearStr.length == 2) {
        yy = yearStr;
      } else {
        continue;
      }
      int? year = int.tryParse(yy);
      if (year == null) continue;
      // Basic sanity: year between 20 and 40 (2020-2040)
      if (year < 20 || year > 40) continue;
      return '${month.toString().padLeft(2, '0')}/$yy';
    }
  }
  return null;
}

/// Extract cardholder name (uppercase words with spaces, no digits).
String? _extractHolderName(String fullText) {
  final lines = fullText.split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.length < 5) continue;
    if (trimmed.contains(RegExp(r'[0-9]'))) continue;
    // Must be mostly uppercase letters with spaces
    if (RegExp(r'^[A-Z][A-Z\s\.\-]+$').hasMatch(trimmed)) {
      final words = trimmed.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
      if (words.length >= 2) {
        // Exclude common non-name words
        final exclude = {'VALID', 'THRU', 'GOOD', 'FROM', 'MONTH', 'YEAR', 'DATE', 'MEMBER', 'SINCE', 'BANK', 'CARD'};
        final filtered = words.where((w) => !exclude.contains(w)).toList();
        if (filtered.length >= 2) return filtered.join(' ');
      }
    }
  }
  return null;
}

class CardScannerPage extends StatefulWidget {
  final CardScannerMode mode;
  const CardScannerPage({super.key, required this.mode});

  @override
  State<CardScannerPage> createState() => _CardScannerPageState();
}

class _CardScannerPageState extends State<CardScannerPage> with WidgetsBindingObserver {
  CameraController? _controller;
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _returned = false;
  String? _detectedNumber;

  // Detection state accumulates best results across frames
  String? _bestNumber;
  String? _bestExpiry;
  String? _bestName;
  int _stableFrames = 0;
  DateTime? _firstDetectionTime;
  static const _requiredStableFrames = 3;
  static const _maxWaitMs = 8000; // 8 seconds max wait before returning best result

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.scannerNoCameraFound)),
          );
          Navigator.pop(context);
        }
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) return;

      _controller = controller;
      setState(() => _isInitializing = false);

      await controller.startImageStream(_processImage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.scannerNoCameraFound)),
        );
        Navigator.pop(context);
      }
    }
  }

  void _processImage(CameraImage image) async {
    if (_isProcessing || _returned) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return;

      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      final number = _extractCardNumber(text);
      final expiry = widget.mode == CardScannerMode.fullCard ? _extractExpiry(text) : null;
      final name = widget.mode == CardScannerMode.fullCard ? _extractHolderName(text) : null;

      final now = DateTime.now();

      if (number != null) {
        // Initialize first detection time if not set
        _firstDetectionTime ??= now;

        // Check if new number is similar to best number (compatible detection)
        final isSimilar = _numbersAreSimilar(_bestNumber, number);

        if (_bestNumber == null || !isSimilar) {
          // New/different number - reset stable frames to 1
          _bestNumber = number;
          _stableFrames = 1;
        } else {
          // Same or similar number detected - increment stable frames
          _stableFrames++;
          // Keep the longer/more complete number as best
          if (number.length > _bestNumber!.length) {
            _bestNumber = number;
          }
        }

        if (expiry != null) _bestExpiry = expiry;
        if (name != null) _bestName = name;

        if (mounted) {
          setState(() => _detectedNumber = _bestNumber);
        }

        // Check if we should return result
        final elapsed = now.difference(_firstDetectionTime!).inMilliseconds;
        final shouldReturnByStability = _stableFrames >= _requiredStableFrames;
        final shouldReturnByTimeout = elapsed >= _maxWaitMs && _stableFrames >= 1;

        if (shouldReturnByStability || shouldReturnByTimeout) {
          _returnResult();
        }
      } else {
        // No valid number in this frame
        _stableFrames = 0;
        _firstDetectionTime = null;
        if (mounted && _detectedNumber != null) {
          setState(() => _detectedNumber = null);
        }
      }
    } catch (_) {
      // Ignore frame processing errors
    } finally {
      _isProcessing = false;
    }
  }

  /// Check if two card numbers are "similar" - meaning they likely represent
  /// the same card but with minor OCR differences (one digit off, missing/extra digit)
  bool _numbersAreSimilar(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;

    // If one contains the other (e.g., "123456789012345" vs "1234567890123456")
    if (a.contains(b) || b.contains(a)) return true;

    // If lengths are same and differ by at most 1 digit (allowing for single OCR error)
    if (a.length == b.length) {
      int diffs = 0;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) diffs++;
        if (diffs > 1) return false;
      }
      return diffs <= 1;
    }

    // If lengths differ by at most 1, check common substring alignment
    if ((a.length - b.length).abs() == 1) {
      final shorter = a.length < b.length ? a : b;
      final longer = a.length > b.length ? a : b;
      // Check if shorter matches starting at position 0 or 1 in longer
      for (int offset = 0; offset <= 1; offset++) {
        bool matches = true;
        for (int i = 0; i < shorter.length; i++) {
          if (longer[i + offset] != shorter[i]) {
            matches = false;
            break;
          }
        }
        if (matches) return true;
      }
    }

    return false;
  }

  InputImage? _convertCameraImage(CameraImage image) {
    final controller = _controller;
    if (controller == null) return null;

    final camera = controller.description;
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    InputImageFormat format;
    if (Platform.isAndroid) {
      format = InputImageFormat.nv21;
    } else {
      format = InputImageFormat.bgra8888;
    }

    if (image.planes.isEmpty) return null;

    // For NV21 on Android, we need to concatenate all planes
    // because Y and UV data are in separate planes
    late final Uint8List bytes;
    late final int bytesPerRow;

    if (Platform.isAndroid) {
      // Concatenate all planes for NV21 format
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
      bytesPerRow = image.planes[0].bytesPerRow;
    } else {
      bytes = image.planes.first.bytes;
      bytesPerRow = image.planes.first.bytesPerRow;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );
  }

  void _returnResult() {
    if (_returned) return;
    _returned = true;
    _controller?.stopImageStream();

    if (widget.mode == CardScannerMode.numberOnly) {
      Navigator.pop(context, _bestNumber);
    } else {
      Navigator.pop(context, CardScannerResult(
        number: _bestNumber,
        expiry: _bestExpiry,
        holderName: _bestName,
      ));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      controller.startImageStream(_processImage);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = widget.mode == CardScannerMode.numberOnly
        ? l.scannerTitleNumberOnly
        : l.scannerTitleFront;
    final hint = widget.mode == CardScannerMode.numberOnly
        ? l.scannerHintNumberOnly
        : l.scannerHintFront;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(child: CameraPreview(_controller!)),
          if (_isInitializing)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    l.scannerCameraInitializing,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

          // Scanning overlay
          if (!_isInitializing)
            Positioned.fill(
              child: CustomPaint(
                painter: _CardOverlayPainter(
                  detectedNumber: _detectedNumber != null,
                ),
              ),
            ),

          // Bottom hint bar
          if (!_isInitializing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black54,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_detectedNumber != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _formatCardNumber(_detectedNumber!),
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.scannerDetecting,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ] else ...[
                      Text(
                        hint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCardNumber(String number) {
    // Group into 4s
    final buf = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(number[i]);
    }
    return buf.toString();
  }
}

class _CardOverlayPainter extends CustomPainter {
  final bool detectedNumber;
  _CardOverlayPainter({required this.detectedNumber});

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    // Card frame dimensions (standard credit card aspect ratio ~1.586:1)
    final cardWidth = size.width * 0.9;
    final cardHeight = cardWidth / 1.586;
    final cardLeft = (size.width - cardWidth) / 2;
    final cardTop = (size.height - cardHeight) / 2 - size.height * 0.05;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight),
      const Radius.circular(16),
    );

    // Draw overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cardRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Card frame border
    final borderPaint = Paint()
      ..color = detectedNumber ? Colors.greenAccent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = detectedNumber ? 3 : 2;
    canvas.drawRRect(cardRect, borderPaint);

    // Corner markers for guidance
    final cornerPaint = Paint()
      ..color = detectedNumber ? Colors.greenAccent : Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLen = 30.0;
    // Top-left
    canvas.drawLine(Offset(cardLeft, cardTop + cornerLen), Offset(cardLeft, cardTop), cornerPaint);
    canvas.drawLine(Offset(cardLeft, cardTop), Offset(cardLeft + cornerLen, cardTop), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(cardLeft + cardWidth - cornerLen, cardTop), Offset(cardLeft + cardWidth, cardTop), cornerPaint);
    canvas.drawLine(Offset(cardLeft + cardWidth, cardTop), Offset(cardLeft + cardWidth, cardTop + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(cardLeft, cardTop + cardHeight - cornerLen), Offset(cardLeft, cardTop + cardHeight), cornerPaint);
    canvas.drawLine(Offset(cardLeft, cardTop + cardHeight), Offset(cardLeft + cornerLen, cardTop + cardHeight), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(cardLeft + cardWidth - cornerLen, cardTop + cardHeight), Offset(cardLeft + cardWidth, cardTop + cardHeight), cornerPaint);
    canvas.drawLine(Offset(cardLeft + cardWidth, cardTop + cardHeight - cornerLen), Offset(cardLeft + cardWidth, cardTop + cardHeight), cornerPaint);

    // Scanning line indicator in center
    if (!detectedNumber) {
      canvas.drawRect(
        Rect.fromLTWH(cardLeft, cardTop + cardHeight / 2, cardWidth, 2),
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardOverlayPainter oldDelegate) {
    return oldDelegate.detectedNumber != detectedNumber;
  }
}
