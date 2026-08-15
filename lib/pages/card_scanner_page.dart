import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallet/l10n/app_localizations.dart';
import 'package:wallet/services/card_ocr_service.dart';
import 'package:wallet/services/card_scanner_service.dart';

/// Modes the scanner page can run in.
enum CardScannerMode {
  /// Capture front + back → edge crop both → run full OCR (card number,
  /// expiry, holder name, CVV). Returned via `CardScannerResult`.
  fullCard,

  /// Capture a single frame → detect only the card number. OCR output is
  /// returned as a plain `String` via `Navigator.pop`.
  numberOnly,
}

/// The data returned from the scanner page when the user finishes.
///
/// - In [CardScannerMode.numberOnly] only [numberOnly] is populated and
///   everything else is null.
/// - In [CardScannerMode.fullCard] at least [ocr] is populated (may be
///   partially empty — null fields = OCR didn't find it). Front image bytes
///   are always provided; back image bytes are optional (user may skip).
class CardScannerResult {
  final String? numberOnly; // filled by numberOnly mode

  final CardOcrResult? ocr; // filled by fullCard mode
  final Uint8List? frontImageBytes; // fullCard mode
  final Uint8List? backImageBytes; // fullCard mode, nullable
  final bool frontCropOk;
  final bool backCropOk;

  CardScannerResult({
    this.numberOnly,
    this.ocr,
    this.frontImageBytes,
    this.backImageBytes,
    this.frontCropOk = false,
    this.backCropOk = false,
  });
}

class CardScannerPage extends StatefulWidget {
  final CardScannerMode mode;

  const CardScannerPage({super.key, required this.mode});

  @override
  State<CardScannerPage> createState() => _CardScannerPageState();
}

class _CardScannerPageState extends State<CardScannerPage> {
  // ---- Camera state ----
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraReady = false;
  bool _cameraError = false;
  String? _cameraErrorText;
  final ResolutionPreset _resolution = ResolutionPreset.high;

  // ---- Stage navigation (fullCard) ----
  // frontReview → backCapture → backReview → resultPop
  enum _Stage {
    captureFront,
    reviewFront,
    captureBack,
    reviewBack,
  }
  _Stage _stage = _Stage.captureFront;

  // ---- Current image under review (byte array after crop) ----
  Uint8List? _frontCropped;
  Uint8List? _backCropped;
  bool _frontCropOk = false;
  bool _backCropOk = false;

  // ---- Processing state ----
  bool _processing = false;
  String _statusText = '';

  // ---- OCR ----
  CardOcrResult? _ocrResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ================================================================
  // Camera lifecycle
  // ================================================================
  Future<void> _initCamera() async {
    try {
      final perm = await Permission.camera.request();
      if (!perm.isGranted) {
        setState(() {
          _cameraError = true;
          final l = AppLocalizations.of(context)!;
          _cameraErrorText = l.scannerCameraPermissionDenied;
        });
        return;
      }
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _cameraError = true;
          final l = AppLocalizations.of(context)!;
          _cameraErrorText = l.scannerNoCameraFound;
        });
        return;
      }
      final back = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      final ctl = CameraController(
        back,
        _resolution,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
        enableAudio: false,
      );
      await ctl.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = ctl;
        _cameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = true;
        _cameraErrorText = e.toString();
      });
    }
  }

  // ================================================================
  // Workflow: capture → crop → review
  // ================================================================
  Future<void> _takePicture({required bool isFront}) async {
    final ctl = _cameraController;
    if (ctl == null || !ctl.value.isInitialized) return;
    HapticFeedback.mediumImpact();
    setState(() => _processing = true);
    try {
      // Give the flash / auto-exposure a chance to settle.
      await Future.delayed(const Duration(milliseconds: 300));
      final image = await ctl.takePicture();
      final bytes = await File(image.path).readAsBytes();

      final crop = await CardScannerService.instance.processCardPhoto(bytes);
      if (!mounted) return;

      if (isFront) {
        setState(() {
          _frontCropped = crop.croppedBytes;
          _frontCropOk = crop.cornersFound;
          _stage = _Stage.reviewFront;
          _processing = false;
          _statusText = '';
        });
      } else {
        setState(() {
          _backCropped = crop.croppedBytes;
          _backCropOk = crop.cornersFound;
          _stage = _Stage.reviewBack;
          _processing = false;
          _statusText = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        final l = AppLocalizations.of(context)!;
        _statusText = '${l.scannerCaptureFailed}: $e';
      });
    }
  }

  // ---- Accept review → move forward or run OCR ----
  Future<void> _acceptFrontAndGoBack() async {
    if (widget.mode == CardScannerMode.numberOnly) {
      // OCR only the card number on the front, then return immediately.
      await _runNumberOnlyOcr(_frontCropped!);
      return;
    }
    // fullCard → advance to capture back of card (CVV).
    setState(() => _stage = _Stage.captureBack);
  }

  Future<void> _acceptBackAndFinish() async {
    await _runFullCardOcr();
  }

  Future<void> _skipBackAndFinish() async {
    _backCropped = null;
    _backCropOk = false;
    await _runFullCardOcr();
  }

  // ================================================================
  // OCR wrappers
  // ================================================================
  Future<void> _runNumberOnlyOcr(Uint8List frontBytes) async {
    setState(() {
      _processing = true;
      final l = AppLocalizations.of(context)!;
      _statusText = l.scannerOcrInProgress;
    });
    try {
      // Write the cropped JPEG to a temp file and let ML Kit read it
      // directly via fromFilePath — this avoids the fragile
      // InputImage.fromBytes metadata (size / format / rotation) that we
      // don't reliably know after perspective warping.
      final tmp = File(
          '${Directory.systemTemp.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tmp.writeAsBytes(frontBytes);
      final number = await CardOcrService.instance
          .recognizeCardNumberOnly(InputImage.fromFilePath(tmp.path));
      await tmp.delete();
      if (!mounted) return;
      // Pop with result — even if number is null so the page can close.
      Navigator.pop(
        context,
        CardScannerResult(numberOnly: number),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        final l = AppLocalizations.of(context)!;
        _statusText = '${l.scannerOcrFailed}: $e';
      });
    }
  }

  Future<void> _runFullCardOcr() async {
    setState(() {
      _processing = true;
      final l = AppLocalizations.of(context)!;
      _statusText = l.scannerOcrInProgress;
    });
    try {
      final tmpDir = Directory.systemTemp;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final f = File('${tmpDir.path}/front_$ts.jpg');
      await f.writeAsBytes(_frontCropped!);
      CardOcrResult result = await CardOcrService.instance
          .parseFullCard(front: InputImage.fromFilePath(f.path));
      if (_backCropped != null) {
        final b = File('${tmpDir.path}/back_$ts.jpg');
        await b.writeAsBytes(_backCropped!);
        final cvv = await CardOcrService.instance
            .parseBackCardForCvv(InputImage.fromFilePath(b.path));
        await b.delete();
        if (cvv != null) {
          result = result.copyWith(cvv: cvv, cvvFromBack: true);
        }
      }
      await f.delete();
      if (!mounted) return;
      Navigator.pop(
        context,
        CardScannerResult(
          ocr: result,
          frontImageBytes: _frontCropped,
          backImageBytes: _backCropped,
          frontCropOk: _frontCropOk,
          backCropOk: _backCropOk,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        final l = AppLocalizations.of(context)!;
        _statusText = '${l.scannerOcrFailed}: $e';
      });
    }
  }

  // ================================================================
  // Build
  // ================================================================
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final fg = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: fg,
        title: Text(_appBarTitle(l)),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // ---- Main body --------------------------------------------------
            if (_cameraError)
              _ErrorView(message: _cameraErrorText ?? l.scannerUnknownError)
            else if (!_cameraReady)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l.scannerCameraInitializing,
                        style: TextStyle(color: fg.withValues(alpha: 0.7))),
                  ],
                ),
              )
            else if (_stage == _Stage.reviewFront)
              _ReviewView(
                bytes: _frontCropped!,
                isFront: true,
                cropOk: _frontCropOk,
                onRetake: () => setState(() => _stage = _Stage.captureFront),
                onAccept: _acceptFrontAndGoBack,
                acceptLabel: widget.mode == CardScannerMode.numberOnly
                    ? l.scannerFinish
                    : l.scannerNextBack,
              )
            else if (_stage == _Stage.reviewBack)
              _ReviewView(
                bytes: _backCropped!,
                isFront: false,
                cropOk: _backCropOk,
                onRetake: () => setState(() => _Stage.captureBack),
                onAccept: _acceptBackAndFinish,
                acceptLabel: l.scannerFinish,
                showSkip: true,
                onSkip: _skipBackAndFinish,
              )
            else
              _CaptureView(
                controller: _cameraController!,
                isFront: _stage == _Stage.captureFront,
                isNumberOnly: widget.mode == CardScannerMode.numberOnly,
                onShutter: () => _takePicture(
                    isFront: _stage == _Stage.captureFront),
                onCancelBackSide: widget.mode == CardScannerMode.fullCard &&
                        _stage == _Stage.captureBack
                    ? _skipBackAndFinish
                    : null,
              ),

            // ---- Status / processing overlay on capture phase ----------------
            if (_processing || _statusText.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: _processing
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(_statusText.isNotEmpty
                                  ? _statusText
                                  : l.scannerProcessing),
                            ],
                          )
                        : Text(_statusText),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _appBarTitle(AppLocalizations l) {
    if (widget.mode == CardScannerMode.numberOnly) {
      return l.scannerTitleNumberOnly;
    }
    switch (_stage) {
      case _Stage.captureFront:
      case _Stage.reviewFront:
        return l.scannerTitleFront;
      case _Stage.captureBack:
      case _Stage.reviewBack:
        return l.scannerTitleBack;
    }
    // Fallback: new enum values added later, impossible today but Dart's
    // type-system requires a non-null return for every code path.
    return l.scannerTitleFront;
  }
}

// ======================================================================
// Sub-widgets
// ======================================================================

class _CaptureView extends StatelessWidget {
  final CameraController controller;
  final bool isFront;
  final bool isNumberOnly;
  final VoidCallback onShutter;
  final VoidCallback? onCancelBackSide;

  const _CaptureView({
    required this.controller,
    required this.isFront,
    required this.isNumberOnly,
    required this.onShutter,
    this.onCancelBackSide,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context).size;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(controller)),
        // ---- Guide overlay ----
        CustomPaint(
          size: media,
          painter: _CutoutPainter(
            cardRatio: 3.375 / 2.125,
            isNumberOnly: isNumberOnly,
          ),
        ),
        // ---- Top hint text ----
        Positioned(
          top: 18,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isNumberOnly
                    ? l.scannerHintNumberOnly
                    : isFront
                        ? l.scannerHintFront
                        : l.scannerHintBack,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        // ---- Bottom controls ----
        Positioned(
          left: 0,
          right: 0,
          bottom: 30,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onCancelBackSide != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextButton(
                    onPressed: onCancelBackSide,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      backgroundColor: Colors.black.withValues(alpha: 0.55),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(l.scannerSkipBack),
                  ),
                ),
              SizedBox(
                width: 78,
                height: 78,
                child: RawMaterialButton(
                  shape: const CircleBorder(
                      side: BorderSide(color: Colors.white, width: 4)),
                  fillColor: Colors.white,
                  elevation: 4,
                  padding: const EdgeInsets.all(8),
                  onPressed: onShutter,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.black54, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.scannerShutterHint,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CutoutPainter extends CustomPainter {
  final double cardRatio;
  final bool isNumberOnly;

  _CutoutPainter({
    required this.cardRatio,
    required this.isNumberOnly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final whole = Rect.fromLTWH(0, 0, size.width, size.height);

    final double cutWidth = size.width * (isNumberOnly ? 0.86 : 0.80);
    final double cutHeight = isNumberOnly
        ? cutWidth * 0.42
        : cutWidth / cardRatio; // a 40% tall bar for number-only
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2,
          isNumberOnly ? size.height / 2 : size.height * 0.45),
      width: cutWidth,
      height: cutHeight,
    );
    final radius = Radius.circular(isNumberOnly ? 8 : 14);

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(whole),
      Path()..addRRect(RRect.fromRectAndRadius(rect, radius)),
    );
    canvas.drawPath(path, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), borderPaint);

    // Corner ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final tick = cutWidth * 0.07;
    void tickLine(Offset p1, Offset p2) =>
        canvas.drawLine(p1, p2, tickPaint);

    final tl = rect.topLeft;
    final tr = rect.topRight;
    final bl = rect.bottomLeft;
    final br = rect.bottomRight;
    tickLine(Offset(tl.dx, tl.dy + tick), Offset(tl.dx, tl.dy));
    tickLine(Offset(tl.dx, tl.dy), Offset(tl.dx + tick, tl.dy));
    tickLine(Offset(tr.dx - tick, tr.dy), Offset(tr.dx, tr.dy));
    tickLine(Offset(tr.dx, tr.dy), Offset(tr.dx, tr.dy + tick));
    tickLine(Offset(bl.dx, bl.dy - tick), Offset(bl.dx, bl.dy));
    tickLine(Offset(bl.dx, bl.dy), Offset(bl.dx + tick, bl.dy));
    tickLine(Offset(br.dx - tick, br.dy), Offset(br.dx, br.dy));
    tickLine(Offset(br.dx, br.dy), Offset(br.dx, br.dy - tick));
  }

  @override
  bool shouldRepaint(covariant _CutoutPainter oldDelegate) => false;
}

class _ReviewView extends StatelessWidget {
  final Uint8List bytes;
  final bool isFront;
  final bool cropOk;
  final VoidCallback onRetake;
  final VoidCallback onAccept;
  final String acceptLabel;
  final bool showSkip;
  final VoidCallback? onSkip;

  const _ReviewView({
    required this.bytes,
    required this.isFront,
    required this.cropOk,
    required this.onRetake,
    required this.onAccept,
    required this.acceptLabel,
    this.showSkip = false,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cropOk
                  ? const Color(0xFF4ADE80).withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cropOk
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.6)
                    : Colors.amber.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              cropOk
                  ? l.scannerCropOk
                  : l.scannerCropFallback,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ColoredBox(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l.scannerRetake),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(acceptLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
          if (showSkip && onSkip != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(l.scannerSkipBack),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(l.scannerCameraInitFailed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7))),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.cancelButton),
            ),
          ],
        ),
      ),
    );
  }
}
