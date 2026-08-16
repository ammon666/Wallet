import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
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
  final String? frontImagePath; // Path to captured (cropped+enhanced) card photo

  const CardScannerResult({
    this.number,
    this.expiry,
    this.holderName,
    this.frontImagePath,
  });
}

// =============================================================================
//  Card number validation utilities
// =============================================================================

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

/// OCR character confusion mapping: common misreads for digits.
const Map<String, String> _digitCorrections = {
  'O': '0', 'o': '0', 'Q': '0', 'D': '0',
  'I': '1', 'l': '1', 'i': '1', '|': '1', '!': '1',
  'Z': '2', 'z': '2',
  'E': '3', 'e': '3',
  'A': '4', 'h': '4',
  'S': '5', 's': '5',
  'G': '6', 'b': '6',
  'T': '7', '?': '7', '/': '7',
  'B': '8', 'g': '9', 'q': '9',
};

/// Normalize OCR text by replacing common misread characters with digits.
String _normalizeOcrDigits(String text) {
  final buf = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    final ch = text[i];
    if (RegExp(r'[0-9]').hasMatch(ch)) {
      buf.write(ch);
    } else if (_digitCorrections.containsKey(ch)) {
      buf.write(_digitCorrections[ch]);
    }
    // Skip non-digit, non-correctable characters entirely
  }
  return buf.toString();
}

// =============================================================================
//  Coordinate transform utilities for ROI filtering
// =============================================================================

/// Transform a point from raw sensor image coordinates to normalized (0-1)
/// display coordinates, accounting for the camera sensor rotation.
///
/// [imgW]/[imgH] are the raw CameraImage dimensions (sensor native).
Offset _normalizePoint(
  double x, double y,
  int imgW, int imgH,
  InputImageRotation rotation,
) {
  double nx, ny;
  switch (rotation) {
    case InputImageRotation.rotation0deg:
      nx = x / imgW;
      ny = y / imgH;
      break;
    case InputImageRotation.rotation90deg:
      // 90° clockwise: (x,y) → (y, W-x)
      nx = y / imgH;
      ny = (imgW - x) / imgW;
      break;
    case InputImageRotation.rotation180deg:
      nx = (imgW - x) / imgW;
      ny = (imgH - y) / imgH;
      break;
    case InputImageRotation.rotation270deg:
      // 270° clockwise (= 90° counterclockwise): (x,y) → (H-y, x)
      nx = (imgH - y) / imgH;
      ny = x / imgW;
      break;
  }
  return Offset(nx, ny);
}

/// Get the center point of a rectangle in normalized coordinates.
Offset _normalizedCenterOfRect(
  Rect rect,
  int imgW, int imgH,
  InputImageRotation rotation,
) {
  final cx = rect.left + rect.width / 2;
  final cy = rect.top + rect.height / 2;
  return _normalizePoint(cx, cy, imgW, imgH, rotation);
}

/// Compute the card overlay rectangle in normalized (0-1) display coordinates.
///
/// This must match the layout of [_CardOverlayPainter].
Rect _cardRegionNormalized(double aspectRatio) {
  // The overlay painter draws:
  //   cardWidth  = size.width  * 0.9
  //   cardHeight = cardWidth / 1.586
  //   cardLeft   = (size.width  - cardWidth)  / 2
  //   cardTop    = (size.height - cardHeight) / 2 - size.height * 0.05
  //
  // We normalize to the full widget (0,0)-(1,1).

  const cardW = 0.9;
  final cardH = cardW / 1.586;
  final left = (1.0 - cardW) / 2;
  final top = (1.0 - cardH) / 2 - 0.05;

  // Use a slightly inset region (about 85% of card width) for more aggressive
  // noise rejection around the card edges.
  const padX = 0.04;
  const padY = 0.04;
  return Rect.fromLTWH(left + padX, top + padY, cardW - padX * 2, cardH - padY * 2);
}

// =============================================================================
//  Per-digit voting across frames
// =============================================================================

class _DigitVoteTracker {
  /// vote[i][d] = number of times digit d was observed at position i.
  final List<List<int>> _votes = [];
  int _totalVotes = 0;

  void reset() {
    _votes.clear();
    _totalVotes = 0;
  }

  int get totalVotes => _totalVotes;

  void vote(String number) {
    // Ensure we have enough slots
    while (_votes.length < number.length) {
      _votes.add(List.filled(10, 0));
    }
    for (int i = 0; i < number.length; i++) {
      final d = int.tryParse(number[i]);
      if (d != null && d >= 0 && d <= 9) {
        _votes[i][d]++;
      }
    }
    _totalVotes++;
  }

  /// Get the consensus number. Returns null if there aren't enough votes.
  String? getConsensus(int minVotes) {
    if (_totalVotes < minVotes) return null;
    // Find the most common length: the position of the last vote that
    // has significant data.
    int maxLen = 0;
    for (int i = 0; i < _votes.length; i++) {
      final sum = _votes[i].reduce((a, b) => a + b);
      if (sum >= minVotes) maxLen = i + 1;
    }
    if (maxLen < 13) return null; // Too short for a valid card number

    final buf = StringBuffer();
    for (int i = 0; i < maxLen; i++) {
      int bestDigit = 0;
      int bestCount = -1;
      for (int d = 0; d < 10; d++) {
        if (_votes[i][d] > bestCount) {
          bestCount = _votes[i][d];
          bestDigit = d;
        }
      }
      // Require that the best digit got at least 40% of votes at this position
      final totalAtPos = _votes[i].reduce((a, b) => a + b);
      if (bestCount < totalAtPos * 0.4) return null;
      buf.write(bestDigit);
    }
    final result = buf.toString();
    if (result.length >= 13 && result.length <= 19 && _luhnCheck(result)) {
      return result;
    }
    return null;
  }
}

// =============================================================================
//  Card number / expiry / name extraction from RecognizedText
// =============================================================================

/// Extract the most likely card number from OCR text, filtering by position
/// using the card region ROI.
String? _extractCardNumberFromText(
  RecognizedText recognizedText,
  int imgW, int imgH,
  InputImageRotation rotation,
  double screenAspectRatio,
) {
  final cardRegion = _cardRegionNormalized(screenAspectRatio);

  // Collect all digit sequences from elements that fall within the card region.
  final candidates = <String>[];
  final inCardDigitSequences = <String>[];

  for (final block in recognizedText.blocks) {
    for (final line in block.lines) {
      // Check position: line center must be within card region
      final center = _normalizedCenterOfRect(
        line.boundingBox, imgW, imgH, rotation,
      );

      // Card numbers typically appear in the lower 2/3 of the card region.
      // The card region in normalized coords: from (left,top) to (right,bottom).
      // Card numbers are usually in the vertical 30%-80% range of the card face.
      final inCardRegion = cardRegion.contains(center);
      final inCardNumberZone = inCardRegion &&
          center.dy >= cardRegion.top + cardRegion.height * 0.2 &&
          center.dy <= cardRegion.bottom - cardRegion.height * 0.05;

      // Concatenate all text in this line and extract digits
      final lineText = line.elements.map((e) => e.text).join('');
      final digits = _normalizeOcrDigits(lineText);

      if (digits.length >= 4) {
        if (inCardNumberZone) {
          inCardDigitSequences.add(digits);
        }
        // Also collect as fallback candidate
        candidates.add(digits);
      }
    }
  }

  // Strategy 1: Concatenate consecutive 4-digit groups in the card number zone
  // (this matches the standard "1234 5678 9012 3456" formatting).
  final zoneGroups = inCardDigitSequences
      .where((s) => s.length == 4)
      .toList();
  if (zoneGroups.length >= 4) {
    for (int start = 0; start + 3 < zoneGroups.length; start++) {
      final candidate = zoneGroups.sublist(start, start + 4).join();
      if (candidate.length == 16 && _luhnCheck(candidate)) {
        return candidate;
      }
    }
    // Try 3+4+4+4+... patterns (15-19 digit cards)
    for (int start = 0; start < zoneGroups.length; start++) {
      final buf = StringBuffer(zoneGroups[start]);
      for (int end = start + 1; end < zoneGroups.length; end++) {
        buf.write(zoneGroups[end]);
        final c = buf.toString();
        if (c.length > 19) break;
        if (c.length >= 13 && c.length <= 19 && _luhnCheck(c)) {
          return c;
        }
      }
    }
  }

  // Strategy 2: Concatenate ALL in-region digit sequences
  if (inCardDigitSequences.isNotEmpty) {
    final allInRegion = inCardDigitSequences.join();
    if (allInRegion.length >= 13 && allInRegion.length <= 19 && _luhnCheck(allInRegion)) {
      return allInRegion;
    }
    // Scan for any valid 13-19 digit subsequence
    for (int len = 19; len >= 13; len--) {
      for (int start = 0; start + len <= allInRegion.length; start++) {
        final c = allInRegion.substring(start, start + len);
        if (_luhnCheck(c)) return c;
      }
    }
  }

  // Strategy 3: Single long digit group (sometimes OCR doesn't split groups)
  for (final digits in candidates) {
    if (digits.length >= 13 && digits.length <= 19 && _luhnCheck(digits)) {
      return digits;
    }
  }

  // Strategy 4: Concatenate all candidates and search
  final allDigits = candidates.join();
  if (allDigits.length >= 13) {
    // Prefer 16-digit numbers, then longest valid
    String? best16;
    String? best;
    int bestLen = 0;
    for (int len = 19; len >= 13; len--) {
      for (int start = 0; start + len <= allDigits.length; start++) {
        final c = allDigits.substring(start, start + len);
        if (_luhnCheck(c)) {
          if (len == 16 && best16 == null) best16 = c;
          if (len > bestLen) {
            bestLen = len;
            best = c;
          }
        }
      }
    }
    return best16 ?? best;
  }

  return null;
}

/// Extract expiry date in MM/YY format, preferring text in the card region.
String? _extractExpiryFromText(
  RecognizedText recognizedText,
  int imgW, int imgH,
  InputImageRotation rotation,
  double screenAspectRatio,
) {
  final cardRegion = _cardRegionNormalized(screenAspectRatio);
  // Expiry is typically in the lower portion of the card, below the card number.
  final expiryRegion = Rect.fromLTWH(
    cardRegion.left,
    cardRegion.top + cardRegion.height * 0.45,
    cardRegion.width,
    cardRegion.height * 0.5,
  );

  final expiryPattern = RegExp(r'(\d{2})\s*[/\-–—]\s*(\d{2,4})');
  final mmYyPattern = RegExp(r'(0[1-9]|1[0-2])\s*(\d{2})'); // MMYY without separator

  // First try within the expiry zone
  for (final block in recognizedText.blocks) {
    for (final line in block.lines) {
      final center = _normalizedCenterOfRect(
        line.boundingBox, imgW, imgH, rotation,
      );
      if (!expiryRegion.contains(center)) continue;

      final text = line.text;
      // Check for MM/YY or MM/YYYY pattern
      final m1 = expiryPattern.firstMatch(text);
      if (m1 != null) {
        final month = int.tryParse(m1.group(1)!);
        var yearStr = m1.group(2)!;
        if (month != null && month >= 1 && month <= 12) {
          if (yearStr.length == 4) yearStr = yearStr.substring(2);
          final year = int.tryParse(yearStr);
          if (year != null && year >= 20 && year <= 40) {
            return '${month.toString().padLeft(2, '0')}/$yearStr';
          }
        }
      }
      // Check for MMYY without separator
      final m2 = mmYyPattern.firstMatch(_normalizeOcrDigits(text));
      if (m2 != null) {
        final month = int.tryParse(m2.group(1)!);
        final yearStr = m2.group(2)!;
        if (month != null && month >= 1 && month <= 12) {
          final year = int.tryParse(yearStr);
          if (year != null && year >= 20 && year <= 40) {
            return '${month.toString().padLeft(2, '0')}/$yearStr';
          }
        }
      }
    }
  }

  // Fallback: search all text
  for (final block in recognizedText.blocks) {
    for (final line in block.lines) {
      final m = expiryPattern.firstMatch(line.text);
      if (m != null) {
        final month = int.tryParse(m.group(1)!);
        var yearStr = m.group(2)!;
        if (month != null && month >= 1 && month <= 12) {
          if (yearStr.length == 4) yearStr = yearStr.substring(2);
          final year = int.tryParse(yearStr);
          if (year != null && year >= 20 && year <= 40) {
            return '${month.toString().padLeft(2, '0')}/$yearStr';
          }
        }
      }
    }
  }

  return null;
}

/// Extract cardholder name (uppercase Latin words), preferring the bottom area
/// of the card where names are typically printed.
String? _extractHolderNameFromText(
  RecognizedText recognizedText,
  int imgW, int imgH,
  InputImageRotation rotation,
  double screenAspectRatio,
) {
  final cardRegion = _cardRegionNormalized(screenAspectRatio);
  // Name is typically in the lower 30% of the card
  final nameRegion = Rect.fromLTWH(
    cardRegion.left,
    cardRegion.top + cardRegion.height * 0.65,
    cardRegion.width,
    cardRegion.height * 0.35,
  );

  final excludeWords = <String>{
    'VALID', 'THRU', 'GOOD', 'FROM', 'MONTH', 'YEAR', 'DATE', 'MEMBER',
    'SINCE', 'BANK', 'CARD', 'CREDIT', 'DEBIT', 'VISA', 'MASTERCARD',
    'AMEX', 'AMERICAN', 'EXPRESS', 'DISCOVER', 'UNIONPAY', 'RUPAY', 'JCB',
    'DINERS', 'CLUB', 'INTERNATIONAL', 'INC', 'CORP', 'CORPORATION', 'LTD',
    'LIMITED', 'THE', 'AND', 'OR', 'OF', 'CHINA', 'PAY', 'SERVICE', 'SERVICES',
    'CARDHOLDER', 'AUTHORIZED', 'SIGNATURE', 'NUMBER', 'EXPIRES', 'END', 'START',
    'ELECTRONIC', 'USE', 'ONLY', 'WORLDWIDE', 'ACCOUNT', 'SECURITY', 'CODE',
    'PLEASE', 'SEE', 'REVERSE', 'NOT', 'TRANSFERABLE', 'PLATINUM', 'GOLD',
    'SILVER', 'CLASSIC', 'STANDARD', 'PREMIUM', 'BUSINESS', 'TITANIUM',
    'INFINITE', 'WORLD', 'ELITE', 'PRIORITY', 'SELECT', 'ADVANTAGE',
    'PREFERRED', 'MR', 'MRS', 'MS', 'DR', 'ATM', 'ELECTRON', 'PURSE',
    'CHIP', 'CONTACTLESS', 'PAYPASS', 'VAPAY', 'THROUGH',
  };

  String? bestInRegion;
  String? bestAnywhere;

  for (final block in recognizedText.blocks) {
    for (final line in block.lines) {
      final text = line.text.trim();
      if (text.length < 5) continue;
      if (text.contains(RegExp(r'[0-9]'))) continue;
      // Must look like a name: mostly uppercase letters, at least 2 words
      final words = text
          .toUpperCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 2)
          .where((w) => RegExp(r"^[A-Z][A-Z\.\-']*$").hasMatch(w))
          .where((w) => !excludeWords.contains(w.replaceAll('.', '')))
          .toList();
      if (words.length < 2) continue;
      final candidate = words.join(' ');
      if (candidate.length < 5 || candidate.length > 40) continue;

      final center = _normalizedCenterOfRect(
        line.boundingBox, imgW, imgH, rotation,
      );
      if (nameRegion.contains(center)) {
        if (bestInRegion == null || candidate.length > bestInRegion.length) {
          bestInRegion = candidate;
        }
      } else if (cardRegion.contains(center)) {
        if (bestAnywhere == null || candidate.length > bestAnywhere.length) {
          bestAnywhere = candidate;
        }
      }
    }
  }

  return bestInRegion ?? bestAnywhere;
}

// =============================================================================
//  Image processing helpers for captured photos
// =============================================================================

/// Crop a high-resolution photo to the card region and enhance it.
/// Returns the path to the saved cropped image, or null if processing fails.
Future<String?> _cropAndEnhancePhoto(String photoPath) async {
  try {
    final photoBytes = await File(photoPath).readAsBytes();
    final image = img.decodeImage(photoBytes);
    if (image == null) return null;

    // Compute the card crop rectangle matching the overlay proportions.
    final w = image.width;
    final h = image.height;

    const cardWRatio = 0.9;
    final cardHRatio = cardWRatio / 1.586;
    final cardW = (w * cardWRatio).toInt();
    final cardH = (w * cardHRatio).toInt();
    final cardX = ((w - cardW) / 2).round();
    final cardY = ((h - cardH) / 2 - h * 0.05).round();

    // Clamp to image bounds
    final cropX = cardX.clamp(0, w - 1);
    final cropY = cardY.clamp(0, h - 1);
    final cropW = cardW.clamp(1, w - cropX);
    final cropH = cardH.clamp(1, h - cropY);

    var cropped = img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH);

    // Apply contrast enhancement for better OCR
    cropped = img.adjustColor(cropped, contrast: 1.5);

    final tempDir = await getTemporaryDirectory();
    final fileName = 'card_final_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = path.join(tempDir.path, fileName);
    final jpgBytes = img.encodeJpg(cropped, quality: 90);
    await File(savedPath).writeAsBytes(jpgBytes);
    return savedPath;
  } catch (e) {
    debugPrint('Card photo crop/enhance failed: $e');
    return null;
  }
}

/// Run OCR on a still image file (high resolution, after cropping/enhancement).
/// Returns a CardScannerResult with the extracted fields.
Future<CardScannerResult?> _ocrStillImage(String imagePath) async {
  try {
    // First decode the image to get its actual dimensions
    final imageBytes = await File(imagePath).readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) return null;

    final imgH = decodedImage.height.toDouble();

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);

      String? number;
      String? expiry;
      String? name;

      // Strategy: look for digit groups forming a card number across all lines
      final allDigitGroups = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          // Prefer lines in the card number zone (vertical 35%-70% of image)
          final lineCenterY = line.boundingBox.center.dy;
          final normalizedY = lineCenterY / imgH;

          final lineText = line.elements.map((e) => e.text).join('');
          final digits = _normalizeOcrDigits(lineText);
          if (digits.length >= 4) {
            // Give positional weight (in card number zone = higher priority)
            if (normalizedY >= 0.30 && normalizedY <= 0.75) {
              allDigitGroups.insert(0, digits);
            } else {
              allDigitGroups.add(digits);
            }
          }

          // Look for expiry date (lower portion of image: 50%-90%)
          if (normalizedY >= 0.50 && normalizedY <= 0.92) {
            final ep = RegExp(r'(\d{2})\s*[/\-–—]\s*(\d{2,4})').firstMatch(lineText);
            if (ep != null) {
              final month = int.tryParse(ep.group(1)!);
              var yearStr = ep.group(2)!;
              if (month != null && month >= 1 && month <= 12) {
                if (yearStr.length == 4) yearStr = yearStr.substring(2);
                final year = int.tryParse(yearStr);
                if (year != null && year >= 20 && year <= 40) {
                  expiry = '${month.toString().padLeft(2, '0')}/$yearStr';
                }
              }
            }
            // Also try MMYY without separator
            final mmyy = RegExp(r'(0[1-9]|1[0-2])\s*(\d{2})').firstMatch(_normalizeOcrDigits(lineText));
            if (mmyy != null && expiry == null) {
              final month = int.tryParse(mmyy.group(1)!);
              final yearStr = mmyy.group(2)!;
              if (month != null && month >= 1 && month <= 12) {
                final year = int.tryParse(yearStr);
                if (year != null && year >= 20 && year <= 40) {
                  expiry = '${month.toString().padLeft(2, '0')}/$yearStr';
                }
              }
            }
          }

          // Look for name (bottom of image: 60%-98%, no digits, multiple words)
          if (normalizedY >= 0.60 && normalizedY <= 0.98) {
            final trimmed = line.text.trim();
            if (trimmed.length >= 5 && !trimmed.contains(RegExp(r'[0-9]'))) {
              final words = trimmed
                  .toUpperCase()
                  .split(RegExp(r'\s+'))
                  .where((w) => w.length >= 2)
                  .where((w) => RegExp(r"^[A-Z][A-Z\.\-']*$").hasMatch(w))
                  .where((w) => !_containsExcludedWord(w))
                  .toList();
              if (words.length >= 2) {
                final candidate = words.join(' ');
                if (candidate.length >= 5 && candidate.length < 40) {
                  name = candidate;
                }
              }
            }
          }
        }
      }

      // Try to find a valid card number from collected digit groups
      // First try: concatenate 4-digit groups (standard card formatting)
      final groups4 = allDigitGroups.where((g) => g.length == 4).toList();
      if (groups4.length >= 4) {
        for (int start = 0; start + 3 < groups4.length; start++) {
          final c = groups4.sublist(start, start + 4).join();
          if (c.length == 16 && _luhnCheck(c)) {
            number = c;
            break;
          }
        }
      }
      // Second try: any single long group that passes Luhn
      if (number == null) {
        for (final g in allDigitGroups) {
          if (g.length >= 13 && g.length <= 19 && _luhnCheck(g)) {
            number = g;
            break;
          }
        }
      }
      // Third try: concatenate all and search for valid subsequence
      if (number == null) {
        final allDigits = allDigitGroups.join();
        for (int len = 19; len >= 13; len--) {
          for (int start = 0; start + len <= allDigits.length; start++) {
            final c = allDigits.substring(start, start + len);
            if (_luhnCheck(c)) {
              number = c;
              break;
            }
          }
          if (number != null) break;
        }
      }

      return CardScannerResult(
        number: number,
        expiry: expiry,
        holderName: name,
      );
    } finally {
      textRecognizer.close();
    }
  } catch (e) {
    debugPrint('Still image OCR failed: $e');
    return null;
  }
}

bool _containsExcludedWord(String word) {
  const excluded = <String>{
    'VALID', 'THRU', 'MONTH', 'YEAR', 'MEMBER', 'SINCE', 'BANK', 'CARD',
    'CREDIT', 'DEBIT', 'VISA', 'MASTERCARD', 'SIGNATURE', 'AUTHORIZED',
    'AMEX', 'AMERICAN', 'EXPRESS', 'UNIONPAY', 'DISCOVER', 'JCB', 'DINERS',
    'CLUB', 'INTERNATIONAL', 'CHINA', 'PAY', 'PLATINUM', 'GOLD', 'SILVER',
    'CLASSIC', 'STANDARD', 'PREMIUM', 'BUSINESS', 'TITANIUM', 'WORLD',
    'ELITE', 'PRIORITY', 'SELECT', 'PREFERRED', 'CHIP', 'CONTACTLESS',
    'PAYPASS', 'VAPAY', 'ELECTRON', 'PURSE', 'ATM',
    'GOOD', 'FROM', 'THROUGH', 'DATE', 'START', 'END',
  };
  final upper = word.toUpperCase().replaceAll('.', '');
  return excluded.contains(upper);
}

// =============================================================================
//  Main scanner page
// =============================================================================

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

  // Detection state for real-time preview
  String? _detectedNumber;
  String? _previewExpiry;
  String? _previewName;
  _ScanState _scanState = _ScanState.searching;

  // Multi-frame voting
  final _voteTracker = _DigitVoteTracker();
  String? _votedNumber;

  // Frame counter for skip logic
  int _frameCounter = 0;

  // Cached screen size for ROI calculations
  Size? _screenSize;

  // Camera/image properties
  int _imgW = 0;
  int _imgH = 0;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;

  // Global timeout
  Timer? _globalTimeoutTimer;
  static const _globalTimeoutMs = 15000;
  static const _stableVoteThreshold = 3;
  static const _frameSkip = 2; // Process every 3rd frame

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _startGlobalTimeout();
  }

  void _startGlobalTimeout() {
    _globalTimeoutTimer = Timer(const Duration(milliseconds: _globalTimeoutMs), () {
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
        ResolutionPreset.medium, // 720p - much faster than high, sufficient for OCR
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) return;

      _controller = controller;

      // Cache rotation value
      _rotation = InputImageRotationValue.fromRawValue(
            backCamera.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      setState(() => _isInitializing = false);

      // Wait a frame for layout to complete before starting stream
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_returned) {
          _screenSize = MediaQuery.of(context).size;
          controller.startImageStream(_processImage);
        }
      });
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

    // Frame skipping: only process every Nth frame
    _frameCounter++;
    if (_frameCounter % (_frameSkip + 1) != 0) return;

    _isProcessing = true;

    try {
      if (_imgW == 0) {
        _imgW = image.width;
        _imgH = image.height;
      }

      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return;

      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Determine screen aspect ratio for ROI calculations
      final screenSize = _screenSize ?? const Size(360, 800);
      final aspectRatio = screenSize.width / screenSize.height;

      final number = _extractCardNumberFromText(
        recognizedText, _imgW, _imgH, _rotation, aspectRatio,
      );
      final expiry = widget.mode == CardScannerMode.fullCard
          ? _extractExpiryFromText(
              recognizedText, _imgW, _imgH, _rotation, aspectRatio,
            )
          : null;
      final name = widget.mode == CardScannerMode.fullCard
          ? _extractHolderNameFromText(
              recognizedText, _imgW, _imgH, _rotation, aspectRatio,
            )
          : null;

      if (number != null) {
        // Feed into per-digit voter
        _voteTracker.vote(number);
        if (expiry != null) _previewExpiry = expiry;
        if (name != null) _previewName = name;

        // Check for consensus
        final consensus = _voteTracker.getConsensus(_stableVoteThreshold);
        if (consensus != null) {
          _votedNumber = consensus;
          if (mounted) {
            setState(() {
              _detectedNumber = consensus;
              _scanState = _ScanState.confirmed;
            });
          }
          // Haptic feedback on confirmation
          HapticFeedback.mediumImpact();
          // Schedule capture after brief delay to let the UI show "confirmed" state
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_returned) _captureAndReturn();
          });
          return;
        } else {
          // Partial detection: show best guess so far
          if (mounted) {
            setState(() {
              _detectedNumber = number;
              _scanState = _ScanState.detecting;
            });
          }
        }
      } else {
        // No number found this frame - let voter accumulate, but don't reset
        // immediately (allow for occasional miss frames).
        if (_voteTracker.totalVotes > 0 && _voteTracker.totalVotes % 5 == 0) {
          // Reset if we've had several consecutive misses
          _voteTracker.reset();
          if (mounted) {
            setState(() {
              _detectedNumber = null;
              _scanState = _ScanState.searching;
            });
          }
        }
      }
    } catch (_) {
      // Ignore frame processing errors
    } finally {
      _isProcessing = false;
    }
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
    _globalTimeoutTimer?.cancel();

    if (mounted) {
      setState(() => _scanState = _ScanState.capturing);
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _returnResult(_votedNumber ?? _detectedNumber, _previewExpiry, _previewName, null);
      return;
    }

    String? finalImagePath;
    String? finalNumber = _votedNumber ?? _detectedNumber;
    String? finalExpiry = _previewExpiry;
    String? finalName = _previewName;

    try {
      // Stop image stream before taking picture
      try {
        await controller.stopImageStream();
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 200));

      if (widget.mode == CardScannerMode.fullCard) {
        try {
          final XFile photo = await controller.takePicture().timeout(
            const Duration(seconds: 4),
            onTimeout: () => throw TimeoutException('takePicture timed out'),
          );

          // Save original temporarily
          final tempDir = await getTemporaryDirectory();
          final origName = 'card_orig_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final origPath = path.join(tempDir.path, origName);
          await File(photo.path).copy(origPath);

          // Crop and enhance to get the final card-only image
          final croppedPath = await _cropAndEnhancePhoto(origPath);
          finalImagePath = croppedPath ?? origPath;

          // Run high-accuracy OCR on the cropped/enhanced photo for best results
          final ocrPath = croppedPath ?? origPath;
          final stillResult = await _ocrStillImage(ocrPath).timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );

          if (stillResult != null) {
            // Prefer still-image OCR results if they pass Luhn check
            if (stillResult.number != null && _luhnCheck(stillResult.number!)) {
              finalNumber = stillResult.number;
            }
            finalExpiry = stillResult.expiry ?? finalExpiry;
            finalName = stillResult.holderName ?? finalName;
          }

          // Clean up original if we have a cropped version
          if (croppedPath != null && origPath != croppedPath) {
            try { await File(origPath).delete(); } catch (_) {}
          }
        } catch (e) {
          debugPrint('Photo capture/OCR failed: $e');
        }
      }
    } catch (_) {
    }

    _returnResult(finalNumber, finalExpiry, finalName, finalImagePath);
  }

  void _returnResult(String? number, String? expiry, String? name, String? imagePath) {
    if (_returned) return;
    _returned = true;
    _globalTimeoutTimer?.cancel();

    try {
      _controller?.stopImageStream();
    } catch (_) {}

    if (!mounted) return;

    if (widget.mode == CardScannerMode.numberOnly) {
      Navigator.pop(context, number);
    } else {
      Navigator.pop(context, CardScannerResult(
        number: number,
        expiry: expiry,
        holderName: name,
        frontImagePath: imagePath,
      ));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      try { controller.stopImageStream(); } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      if (!_returned && !_isCapturing) {
        try { controller.startImageStream(_processImage); } catch (_) {}
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
    _screenSize = MediaQuery.of(context).size;

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
                  state: _scanState,
                ),
              ),
            ),
          if (!_isInitializing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomPanel(l),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations l) {
    String statusText;
    Color statusColor;
    IconData? statusIcon;

    switch (_scanState) {
      case _ScanState.searching:
        statusText = widget.mode == CardScannerMode.numberOnly
            ? l.scannerHintNumberOnly
            : l.scannerHintFront;
        statusColor = Colors.white;
        statusIcon = null;
        break;
      case _ScanState.detecting:
        statusText = l.scannerDetecting;
        statusColor = Colors.amberAccent;
        statusIcon = Icons.search;
        break;
      case _ScanState.confirmed:
        statusText = _detectedNumber != null
            ? _formatCardNumber(_detectedNumber!)
            : l.scannerDetecting;
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case _ScanState.capturing:
        statusText = l.scannerCameraInitializing; // Generic "processing" text
        statusColor = Colors.greenAccent;
        statusIcon = null;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCapturing || _scanState == _ScanState.capturing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.greenAccent,
                    strokeWidth: 2.5,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  l.scannerProcessing,
                  style: TextStyle(color: Colors.greenAccent, fontSize: 15),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (statusIcon != null) ...[
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: _scanState == _ScanState.confirmed ? 18 : 14,
                      fontWeight: _scanState == _ScanState.confirmed
                          ? FontWeight.w600
                          : FontWeight.normal,
                      letterSpacing: _scanState == _ScanState.confirmed ? 1.2 : 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
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

enum _ScanState { searching, detecting, confirmed, capturing }

// =============================================================================
//  Overlay painter with improved visual feedback
// =============================================================================

class _CardOverlayPainter extends CustomPainter {
  final _ScanState state;
  _CardOverlayPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    // Dimmed background
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

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
    canvas.drawPath(path, bgPaint);

    // Border color based on state
    Color borderColor;
    double borderWidth;
    switch (state) {
      case _ScanState.searching:
        borderColor = Colors.white;
        borderWidth = 2;
        break;
      case _ScanState.detecting:
        borderColor = Colors.amberAccent;
        borderWidth = 2.5;
        break;
      case _ScanState.confirmed:
        borderColor = Colors.greenAccent;
        borderWidth = 3;
        break;
      case _ScanState.capturing:
        borderColor = Colors.greenAccent;
        borderWidth = 3;
        break;
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(cardRect, borderPaint);

    // Corner accents
    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLen = 32.0;

    // Top-left
    canvas.drawLine(
      Offset(cardLeft, cardTop + cornerLen),
      Offset(cardLeft, cardTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardLeft, cardTop),
      Offset(cardLeft + cornerLen, cardTop),
      cornerPaint,
    );
    // Top-right
    canvas.drawLine(
      Offset(cardLeft + cardWidth - cornerLen, cardTop),
      Offset(cardLeft + cardWidth, cardTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardLeft + cardWidth, cardTop),
      Offset(cardLeft + cardWidth, cardTop + cornerLen),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawLine(
      Offset(cardLeft, cardTop + cardHeight - cornerLen),
      Offset(cardLeft, cardTop + cardHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardLeft, cardTop + cardHeight),
      Offset(cardLeft + cornerLen, cardTop + cardHeight),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawLine(
      Offset(cardLeft + cardWidth - cornerLen, cardTop + cardHeight),
      Offset(cardLeft + cardWidth, cardTop + cardHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cardLeft + cardWidth, cardTop + cardHeight - cornerLen),
      Offset(cardLeft + cardWidth, cardTop + cardHeight),
      cornerPaint,
    );

    // Scanning line animation (subtle horizontal line in card region when searching)
    if (state == _ScanState.detecting) {
      final scanLineY = cardTop + cardHeight * 0.4;
      final scanPaint = Paint()
        ..color = Colors.amberAccent.withValues(alpha: 0.6)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(cardLeft + 12, scanLineY),
        Offset(cardLeft + cardWidth - 12, scanLineY),
        scanPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardOverlayPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
