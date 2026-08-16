import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:wallet/l10n/app_localizations.dart';

/// Modes the scanner page can run in.
enum CardScannerMode { fullCard, numberOnly }

/// Data returned from the full-card scanner.
class CardScannerResult {
  final String? number;
  final String? expiry; // "MM/YY"
  final String? holderName;
  final String? frontImagePath; // Path to captured card photo

  const CardScannerResult({
    this.number,
    this.expiry,
    this.holderName,
    this.frontImagePath,
  });
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
/// Uses a more robust strategy: collect all digit sequences, then try
/// concatenating nearby groups to find a valid Luhn sequence.
String? _extractCardNumber(String fullText) {
  // Normalize: replace common OCR misreads
  String normalized = fullText
      .replaceAll('O', '0')
      .replaceAll('o', '0')
      .replaceAll('I', '1')
      .replaceAll('l', '1')
      .replaceAll('B', '8')
      .replaceAll(RegExp(r'[^0-9\s\-]'), ' ');

  // Extract all digit groups (length >= 3 to filter out noise like "2", "02" from dates)
  final groups = RegExp(r'\d{3,}')
      .allMatches(normalized)
      .map((m) => m.group(0)!.replaceAll(RegExp(r'\D'), ''))
      .where((g) => g.length >= 3)
      .toList();

  if (groups.isEmpty) return null;

  // Strategy 1: single group of 13-19 digits with valid Luhn
  for (final g in groups) {
    if (g.length >= 13 && g.length <= 19 && _luhnCheck(g)) return g;
  }

  // Strategy 2: concatenate consecutive groups to form 13-19 digit number
  // Try starting from each group
  for (int start = 0; start < groups.length; start++) {
    final buf = StringBuffer();
    for (int end = start; end < groups.length; end++) {
      buf.write(groups[end]);
      final candidate = buf.toString();
      if (candidate.length > 19) break;
      if (candidate.length >= 13 && candidate.length <= 19 && _luhnCheck(candidate)) {
        return candidate;
      }
    }
  }

  // Strategy 3: if we have groups that look like 4x4 card number formatting
  // (four groups of 4 digits), concatenate them
  for (int i = 0; i + 3 < groups.length; i++) {
    if (groups[i].length == 4 && groups[i+1].length == 4 &&
        groups[i+2].length == 4 && groups[i+3].length == 4) {
      final candidate = groups[i] + groups[i+1] + groups[i+2] + groups[i+3];
      if (_luhnCheck(candidate)) return candidate;
    }
  }

  // Strategy 4: take all digits combined, then scan for any 13-19 subsequence
  // that passes Luhn. Use as fallback.
  final allDigits = normalized.replaceAll(RegExp(r'\D'), '');
  if (allDigits.length >= 13) {
    // Prefer the longest valid subsequence, but also prefer 16-digit (most common)
    String? best16;
    String? bestLongest;
    int bestLen = 0;
    for (int len = 19; len >= 13; len--) {
      for (int start = 0; start + len <= allDigits.length; start++) {
        final candidate = allDigits.substring(start, start + len);
        if (_luhnCheck(candidate)) {
          if (len == 16 && best16 == null) best16 = candidate;
          if (len > bestLen) {
            bestLen = len;
            bestLongest = candidate;
          }
        }
      }
    }
    return best16 ?? bestLongest;
  }

  return null;
}

/// Extract expiry date in MM/YY format.
String? _extractExpiry(String fullText) {
  // Look for patterns like MM/YY, MM/YYYY, MM-YY, MM-YYYY
  final patterns = [
    RegExp(r'(\d{2})[/\-](\d{2,4})'),
    // Also look for "VALID THRU 02/25" or "MONTH/YEAR" style
    RegExp(r'(\d{2})(\d{2})', multiLine: false), // MMYY without separator (ambiguous, low priority)
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
      // Accept years 2020-2040 (20-40 in 2-digit format)
      if (year < 20 || year > 40) continue;
      return '${month.toString().padLeft(2, '0')}/$yy';
    }
  }
  return null;
}

/// Extract cardholder name (uppercase words with spaces, no digits).
String? _extractHolderName(String fullText) {
  final lines = fullText.split('\n');
  // Common keywords that appear near/on cards that should NOT be treated as names
  final excludeWords = {
    'VALID', 'THRU', 'GOOD', 'FROM', 'MONTH', 'YEAR', 'DATE', 'MEMBER',
    'SINCE', 'BANK', 'CARD', 'CREDIT', 'DEBIT', 'VISA', 'MASTERCARD',
    'AMEX', 'AMERICAN', 'EXPRESS', 'DISCOVER', 'UNIONPAY', 'RUPAY',
    'JCB', 'DINERS', 'CLUB', 'INTERNATIONAL', 'INC', 'CORP', 'CORPORATION',
    'LTD', 'LIMITED', 'THE', 'AND', 'OR', 'OF', 'CHINA', 'PAY',
    'SERVICE', 'SERVICES', 'CARDHOLDER', 'AUTHORIZED',
    'SIGNATURE', 'NUMBER', 'EXPIRES', 'END', 'START',
    'ELECTRONIC', 'USE', 'ONLY', 'WORLDWIDE', 'ACCOUNT',
    'SECURITY', 'CODE', 'PLEASE', 'SEE', 'REVERSE', 'NOT', 'TRANSFERABLE',
    'PLATINUM', 'GOLD', 'SILVER', 'CLASSIC', 'STANDARD', 'PREMIUM',
    'BUSINESS', 'TITANIUM', 'INFINITE',
    'WORLD', 'ELITE', 'PRIORITY', 'SELECT', 'ADVANTAGE', 'PREFERRED',
    'MR', 'MRS', 'MS', 'DR', // Titles that may appear but are not full names alone
  };

  String? bestCandidate;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.length < 5) continue;
    // Must contain at least one space (at least first + last name)
    if (!trimmed.contains(' ')) continue;
    // Must be mostly uppercase letters
    if (!RegExp(r'^[A-Z][A-Z\s\.\-]+$').hasMatch(trimmed)) continue;
    // Must not contain digits
    if (trimmed.contains(RegExp(r'[0-9]'))) continue;

    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    if (words.length < 2) continue;

    // Filter out common non-name words
    final filtered = words.where((w) {
      // Remove words with dots (initials like "J.")
      if (w.contains('.')) return false;
      return !excludeWords.contains(w.toUpperCase());
    }).toList();

    if (filtered.length >= 2) {
      final candidate = filtered.join(' ');
      // Prefer longer names, but avoid lines that are mostly keywords
      if (candidate.length >= 5 && candidate.length <= 30) {
        // Prefer candidates that look like real names (2-4 words, proper length)
        if (bestCandidate == null ||
            (filtered.length >= 2 && candidate.length > bestCandidate.length && candidate.length < 30)) {
          bestCandidate = candidate;
        }
      }
    }
  }

  return bestCandidate;
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
  bool _isCapturing = false;
  String? _detectedNumber;

  // Detection state
  String? _bestNumber;
  String? _bestExpiry;
  String? _bestName;
  int _stableFrames = 0;
  int _missedFrames = 0; // consecutive frames without a valid number
  DateTime? _firstDetectionTime;
  Timer? _globalTimeoutTimer;

  static const _requiredStableFrames = 2; // be less strict: 2 similar frames
  static const _detectionTimeoutMs = 6000; // 6s of valid detection to return
  static const _globalTimeoutMs = 12000; // absolute max 12s in scanner
  static const _maxMissedFrames = 4; // allow up to 4 missed frames before resetting

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _startGlobalTimeout();
  }

  void _startGlobalTimeout() {
    _globalTimeoutTimer = Timer(Duration(milliseconds: _globalTimeoutMs), () {
      // Global timeout: if we haven't returned yet after max time, force return
      // with whatever we have (even if null)
      if (!_returned && mounted) {
        _captureAndReturn();
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).scannerNoCameraFound)),
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
          SnackBar(content: Text(AppLocalizations.of(context).scannerCameraInitFailed)),
        );
        Navigator.pop(context);
      }
    }
  }

  void _processImage(CameraImage image) async {
    if (_isProcessing || _returned || _isCapturing) return;
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
        _missedFrames = 0; // reset missed frame counter
        _firstDetectionTime ??= now;

        final isSimilar = _numbersAreSimilar(_bestNumber, number);

        if (_bestNumber == null || !isSimilar) {
          // New/different number: reset stable frames, but keep first detection time
          _bestNumber = number;
          _stableFrames = 1;
        } else {
          _stableFrames++;
          // Update to the longer/complete number if we have it
          if (number.length >= _bestNumber!.length) {
            _bestNumber = number;
          }
        }

        // Always update expiry/name if we find them
        if (expiry != null) _bestExpiry = expiry;
        if (name != null) _bestName = name;

        if (mounted) {
          setState(() => _detectedNumber = _bestNumber);
        }

        final elapsed = now.difference(_firstDetectionTime!).inMilliseconds;
        final shouldReturnByStability = _stableFrames >= _requiredStableFrames;
        final shouldReturnByTimeout = elapsed >= _detectionTimeoutMs && _stableFrames >= 1;

        if (shouldReturnByStability || shouldReturnByTimeout) {
          // Don't await here directly inside image stream callback - schedule it
          // to avoid stopping the stream while we're inside its callback.
          _isProcessing = false; // release processing lock before scheduling return
          _scheduleCaptureAndReturn();
          return;
        }
      } else {
        // No valid number in this frame
        _missedFrames++;
        if (_missedFrames >= _maxMissedFrames) {
          // Only reset after several consecutive misses to be tolerant
          _stableFrames = 0;
          _firstDetectionTime = null;
          _missedFrames = 0;
          if (mounted && _detectedNumber != null) {
            setState(() => _detectedNumber = null);
          }
        }
      }
    } catch (_) {
      // Ignore frame processing errors
    } finally {
      _isProcessing = false;
    }
  }

  /// Schedule capture and return to run after the current frame processing
  /// completes. This avoids calling stopImageStream/takePicture from directly
  /// inside the image stream callback.
  void _scheduleCaptureAndReturn() {
    if (_returned || _isCapturing) return;
    // Use a short delay to ensure we're out of the image stream callback
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_returned) {
        _captureAndReturn();
      }
    });
  }

  bool _numbersAreSimilar(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;

    // Same length: allow up to 2 digits difference (OCR can misread 1-2 digits)
    if (a.length == b.length) {
      int diffs = 0;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) diffs++;
        if (diffs > 2) return false;
      }
      return diffs <= 2;
    }

    // Length differs by 1: check if one is the other with an extra/missing digit
    if ((a.length - b.length).abs() == 1) {
      final shorter = a.length < b.length ? a : b;
      final longer = a.length > b.length ? a : b;
      for (int offset = 0; offset <= 1; offset++) {
        bool matches = true;
        int diffs = 0;
        for (int i = 0; i < shorter.length; i++) {
          if (longer[i + offset] != shorter[i]) {
            diffs++;
            if (diffs > 1) {
              matches = false;
              break;
            }
          }
        }
        if (matches || diffs <= 1) return true;
      }
    }

    // Length differs by 2: possible if OCR added/removed digits at edges
    if ((a.length - b.length).abs() == 2) {
      final shorter = a.length < b.length ? a : b;
      final longer = a.length > b.length ? a : b;
      // Check if shorter matches a substring of longer (allowing for extra digits at either end)
      if (longer.contains(shorter)) return true;
      // Or check with offset up to 2
      for (int offset = 0; offset <= 2; offset++) {
        bool matches = true;
        int diffs = 0;
        for (int i = 0; i < shorter.length; i++) {
          if (longer[i + offset] != shorter[i]) {
            diffs++;
            if (diffs > 1) {
              matches = false;
              break;
            }
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

    late final Uint8List bytes;
    late final int bytesPerRow;

    if (Platform.isAndroid) {
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

  Future<void> _captureAndReturn() async {
    if (_returned || _isCapturing) return;
    _isCapturing = true;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _returnResult(null);
      return;
    }

    String? imagePath;

    try {
      // Stop image stream first
      try {
        await controller.stopImageStream();
      } catch (_) {
        // May already be stopped
      }

      // Small delay to let camera settle after stopping stream
      await Future.delayed(const Duration(milliseconds: 200));

      if (widget.mode == CardScannerMode.fullCard) {
        // Take a picture with timeout protection
        try {
          final XFile photo = await controller.takePicture().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw TimeoutException('takePicture timed out');
            },
          );
          final tempDir = await getTemporaryDirectory();
          final fileName = 'card_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedPath = path.join(tempDir.path, fileName);
          await File(photo.path).copy(savedPath);
          imagePath = savedPath;
        } catch (e) {
          // Ignore capture errors - still return OCR results
          debugPrint('Card scanner photo capture failed: $e');
        }
      }
    } catch (_) {
      // Ignore errors, always try to return what we have
    }

    _returnResult(imagePath);
  }

  void _returnResult(String? imagePath) {
    if (_returned) return;
    _returned = true;
    _globalTimeoutTimer?.cancel();

    // Stop camera and clean up
    try {
      _controller?.stopImageStream();
    } catch (_) {}

    if (!mounted) return;

    if (widget.mode == CardScannerMode.numberOnly) {
      Navigator.pop(context, _bestNumber);
    } else {
      Navigator.pop(context, CardScannerResult(
        number: _bestNumber,
        expiry: _bestExpiry,
        holderName: _bestName,
        frontImagePath: imagePath,
      ));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      try {
        controller.stopImageStream();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      if (!_returned && !_isCapturing) {
        try {
          controller.startImageStream(_processImage);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _globalTimeoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _textRecognizer.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          if (!_isInitializing)
            Positioned.fill(
              child: CustomPaint(
                painter: _CardOverlayPainter(
                  detectedNumber: _detectedNumber != null,
                ),
              ),
            ),
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
                    if (_isCapturing) ...[
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.greenAccent,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Taking photo...',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                          ),
                        ],
                      ),
                    ] else if (_detectedNumber != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _formatCardNumber(_detectedNumber!),
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.scannerDetecting,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
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
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    final cardWidth = size.width * 0.9;
    final cardHeight = cardWidth / 1.586;
    final cardLeft = (size.width - cardWidth) / 2;
    final cardTop = (size.height - cardHeight) / 2 - size.height * 0.05;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight),
      const Radius.circular(16),
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cardRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = detectedNumber ? Colors.greenAccent : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = detectedNumber ? 3 : 2;
    canvas.drawRRect(cardRect, borderPaint);

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
