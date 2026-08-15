import 'package:flutter/material.dart';
import 'package:flutter_credit_card_scanner/credit_card_scanner.dart';
import 'package:wallet/l10n/app_localizations.dart';

/// Modes the scanner page can run in.
///
/// - [fullCard]: Scan card number + expiry + holder name. Returned via
///   [CardScannerResult] from `Navigator.pop`.
/// - [numberOnly]: Scan only the card number. Returned as a plain `String`
///   from `Navigator.pop`.
enum CardScannerMode { fullCard, numberOnly }

/// Data returned from the full-card scanner.
///
/// Any field may be null if the OCR engine couldn't read it; the form should
/// leave its existing controller value alone in that case.
class CardScannerResult {
  final String? number;       // digits only, no spaces
  final String? expiry;       // "MM/YY" canonical format
  final String? holderName;   // "JOHN DOE" style; may be null

  const CardScannerResult({
    this.number,
    this.expiry,
    this.holderName,
  });
}

/// A full-screen card scanner page powered by `flutter_credit_card_scanner`.
///
/// This delegates ALL edge detection + OCR to the native ML Kit / Apple
/// Vision pipeline inside the package — we no longer attempt our own Dart
/// Sobel/contour edge detection or custom OCR regex parsing.
///
/// The package's `CameraScannerWidget` runs a real-time camera stream and
/// invokes [CameraScannerWidget.onScan] once a Luhn-valid card number is
/// detected. We then pop the result back to the caller.
///
/// This is 100% offline: the ML Kit text recognition model is bundled into
/// the APK via the gradle dependency (no INTERNET permission required).
class CardScannerPage extends StatefulWidget {
  final CardScannerMode mode;

  const CardScannerPage({super.key, required this.mode});

  @override
  State<CardScannerPage> createState() => _CardScannerPageState();
}

class _CardScannerPageState extends State<CardScannerPage> {
  bool _returned = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = widget.mode == CardScannerMode.numberOnly
        ? l.scannerTitleNumberOnly
        : l.scannerTitleFront;

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
          // Real-time camera scanner. onScan fires when a Luhn-valid card
          // number is read; we convert it to our result type and pop.
          CameraScannerWidget(
            onNoCamera: () {
              if (!_returned && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.scannerNoCameraFound)),
                );
                Navigator.pop(context);
              }
            },
            onScan: (ctx, cardModel) {
              if (_returned || cardModel == null) return;
              _returned = true;

              if (widget.mode == CardScannerMode.numberOnly) {
                if (cardModel.number.isEmpty) {
                  _returned = false; // keep scanning for a valid number
                  return;
                }
                Navigator.pop(ctx, cardModel.number);
                return;
              }

              // fullCard mode — convert CreditCardModel → CardScannerResult.
              //
              // CreditCardModel.expiryDate returns "MM/YYYY" (4-digit year).
              // Our form stores MM/YY (2-digit year), so we slice the year.
              // Empty strings are converted to null so the form leaves existing
              // controller values untouched.
              String? expiry;
              final expRaw = cardModel.expiryDate; // "MM/YYYY" or ""
              if (expRaw.isNotEmpty && expRaw.contains('/')) {
                final parts = expRaw.split('/');
                if (parts.length == 2 && parts[0].length >= 2 && parts[1].length >= 4) {
                  expiry = '${parts[0]}/${parts[1].substring(2)}'; // MM/YY
                }
              }

              final result = CardScannerResult(
                number: cardModel.number.isEmpty ? null : cardModel.number,
                expiry: expiry,
                holderName: cardModel.holderName.isEmpty ? null : cardModel.holderName,
              );
              Navigator.pop(ctx, result);
            },
            loadingHolder: Center(
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
            // Scan all fields by default; for numberOnly mode we still let
            // the package scan everything and just discard what we don't
            // need — simpler than re-configuring per-mode.
            cardNumber: true,
            cardHolder: widget.mode == CardScannerMode.fullCard,
            cardExpiryDate: widget.mode == CardScannerMode.fullCard,
            useLuhnValidation: true,
          ),

          // Overlay hint at the bottom telling the user what to do.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: Text(
                widget.mode == CardScannerMode.numberOnly
                    ? l.scannerHintNumberOnly
                    : l.scannerHintFront,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
