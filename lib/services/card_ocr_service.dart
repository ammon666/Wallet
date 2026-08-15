import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:wallet/services/card_utils.dart';

/// Structured result of parsing a card image (front + optional back).
///
/// Any field that we failed to parse is `null` so the UI can leave its
/// existing TextEditingController value alone (letting the user edit it).
class CardOcrResult {
  final String? number; // raw digits only, no spaces
  final String? expiry; // "MM/YY" canonical format
  final String? cvv; // 3-4 digits
  final String? holderName; // "JOHN DOE" style; may be null
  final String? network; // "visa"/"mastercard"/"unionpay"/...
  final List<String> rawLines; // debug-friendly dump of all OCR lines
  final bool cvvFromBack; // true if cvv came from back-image OCR

  CardOcrResult({
    this.number,
    this.expiry,
    this.cvv,
    this.holderName,
    this.network,
    this.rawLines = const [],
    this.cvvFromBack = false,
  });

  CardOcrResult copyWith({
    String? number,
    String? expiry,
    String? cvv,
    String? holderName,
    String? network,
    List<String>? rawLines,
    bool? cvvFromBack,
  }) {
    return CardOcrResult(
      number: number ?? this.number,
      expiry: expiry ?? this.expiry,
      cvv: cvv ?? this.cvv,
      holderName: holderName ?? this.holderName,
      network: network ?? this.network,
      rawLines: rawLines ?? this.rawLines,
      cvvFromBack: cvvFromBack ?? this.cvvFromBack,
    );
  }
}

/// On-device text recognition wrapper around Google ML Kit bundled English
/// recogniser. This is 100% offline: the model lives in the APK thanks to
/// the gradle dependency `com.google.mlkit:text-recognition:16.0.1`
/// (see android/app/build.gradle.kts). No INTERNET permission used.
class CardOcrService {
  final TextRecognizer _recognizer;

  CardOcrService._()
      : _recognizer = TextRecognizer(
          script: TextRecognitionScript.latin,
        );

  static final CardOcrService instance = CardOcrService._();

  /// Must be called when the app (or this feature) is no longer needed to
  /// free up native resources.
  void dispose() => _recognizer.close();

  // ================================================================
  // Public APIs
  // ================================================================

  /// Parse just a card number from an arbitrary image of card numbers.
  /// Returns raw digits only, or null if nothing looked like a valid card.
  /// Used by the "scan button next to the card number field" entry point.
  Future<String?> recognizeCardNumberOnly(
      InputImage inputImage) async {
    final result = await _safeRun(inputImage);
    final candidates = result._extractCardNumbers();
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Parse every field we can from a cropped front-card photo.
  Future<CardOcrResult> parseFrontCard(InputImage frontImage) async {
    final lines = await _allLines(frontImage);
    return _parseFrontFromRawLines(lines);
  }

  /// Parse the back of a card: currently only CVV extraction.
  Future<String?> parseBackCardForCvv(InputImage backImage) async {
    final lines = await _allLines(backImage);
    return _extractCvv(lines);
  }

  /// Convenience: parse front and (optionally) back together.
  Future<CardOcrResult> parseFullCard({
    required InputImage front,
    InputImage? back,
  }) async {
    final frontResult = await parseFrontCard(front);
    if (back == null) return frontResult;
    final cvv = await parseBackCardForCvv(back);
    if (cvv == null) return frontResult;
    return frontResult.copyWith(cvv: cvv, cvvFromBack: true);
  }

  // ================================================================
  // Internal helpers
  // ================================================================

  Future<RecognizedText> _safeRun(InputImage image) async {
    try {
      return await _recognizer.processImage(image);
    } catch (_) {
      return RecognizedText(text: '', blocks: const []);
    }
  }

  Future<List<String>> _allLines(InputImage image) async {
    final recognized = await _safeRun(image);
    final List<String> out = [];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) out.add(t);
      }
    }
    return out;
  }

  CardOcrResult _parseFrontFromRawLines(List<String> lines) {
    final numbers = _extractCardNumbersFromLines(lines);
    final number = numbers.isEmpty ? null : numbers.first;
    final network =
        number == null ? null : CardUtils.detectCardNetwork(number);
    final expiry = _extractExpiry(lines, number);
    final holder = _extractHolderName(lines);
    final cvv = _extractCvv(lines); // rare, but some cards print CVV front
    return CardOcrResult(
      number: number,
      expiry: expiry,
      cvv: cvv,
      holderName: holder,
      network: network,
      rawLines: lines,
      cvvFromBack: false,
    );
  }

  // ---- Number extraction ----

  static final _digitOnlyRe = RegExp(r'[0-9]+');
  static final _splitToChunks4 =
      RegExp(r'[0-9]{4}[\s\-._·]?[0-9]{4}[\s\-._·]?[0-9]{4}[\s\-._·]?[0-9]{1,7}');
  static final _amexRe =
      RegExp(r'3[47][0-9]{2}[\s\-._·]?[0-9]{6}[\s\-._·]?[0-9]{5}');

  List<String> _extractCardNumbers() {
    // Placeholder (used only if someone else calls the old API)
    return [];
  }

  static List<String> _extractCardNumbersFromLines(List<String> lines) {
    final Set<String> candidates = {};
    final joined = lines.join('  ');

    // 1. Look for a canonical 4+4+4+4 or 4-6-5 (Amex) format — most reliable.
    final mergedFmt = joined.replaceAllMapped(
        RegExp(r'(\d)[\s\-._·–/\\]+(\d)'), (m) => '${m.group(1)}${m.group(2)}');

    for (final m in _splitToChunks4.allMatches(joined)) {
      final cleaned = _digitsOnly(m.group(0)!);
      if (cleaned.length >= 13 && cleaned.length <= 19) {
        candidates.add(cleaned);
      }
    }
    for (final m in _amexRe.allMatches(joined)) {
      final cleaned = _digitsOnly(m.group(0)!);
      if (cleaned.length == 15) candidates.add(cleaned);
    }
    // 2. Fallback: any run of 13–19 digits in the concatenated text.
    for (final m in RegExp(r'[0-9]{13,19}').allMatches(mergedFmt)) {
      candidates.add(m.group(0)!);
    }
    // 3. Validate with Luhn; order by length (longer = more likely valid).
    final list = candidates.where(_luhnCheck).toList();
    list.sort((a, b) => b.length.compareTo(a.length));
    return list;
  }

  static String _digitsOnly(String s) =>
      s.replaceAll(RegExp(r'\D'), '');

  // ---- Luhn check ----
  static bool _luhnCheck(String number) {
    if (number.length < 13 || number.length > 19) return false;
    int sum = 0;
    bool alt = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int n = number.codeUnitAt(i) - 0x30;
      if (n < 0 || n > 9) return false;
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  // ---- Expiry (MM/YY or MMYY) ----
  static final _expiryPatterns = [
    RegExp(r'(0[1-9]|1[0-2])\s*[/\-\.]\s*([0-9]{2})'),
    RegExp(r'(0[1-9]|1[0-2])([0-9]{2})'),
  ];

  static String? _extractExpiry(List<String> lines, String? number) {
    // Join lines that look like expiry (avoid false-positive month/year from
    // "Valid Thru" style fragments).
    for (final rawLine in lines) {
      final line = rawLine;
      for (final pattern in _expiryPatterns) {
        for (final m in pattern.allMatches(line)) {
          final mm = m.group(1)!;
          final yy = m.group(2)!;
          // Skip 00/00 style obvious garbage.
          if (mm == '00' || yy == '00') continue;

          // Reject 19xx style ancient dates.
          final yyInt = int.tryParse(yy);
          if (yyInt == null || yyInt < 20) continue; // reject pre-2020

          // Reject if the pattern accidentally captured the first 4 digits of
          // the card number (e.g. VISA 4xxxx...).
          if (number != null && number.contains('$mm$yy')) continue;

          return '$mm/$yy';
        }
      }
    }
    return null;
  }

  // ---- CVV (3 or 4 digits, typically after the signature strip on the back) ----
  static String? _extractCvv(List<String> lines) {
    // 3-digit or 4-digit runs only (Amex uses 4 on the front).
    final cvvRe = RegExp(r'\b(\d{3,4})\b');
    // Sometimes the OCR reads "CVV: 123" or "CVC 123".
    final cvvLabelRe = RegExp(r'(?i)(?:cvv|cvc|cvv2|安全码|后三?位)\D{0,6}(\d{3,4})');
    for (final line in lines) {
      final m = cvvLabelRe.firstMatch(line);
      if (m != null) return m.group(1);
    }
    // Fallback: any isolated 3/4-digit that isn't part of an expiry or
    // card number segment.
    final candidates = <String>[];
    for (final line in lines) {
      for (final m in cvvRe.allMatches(line)) {
        final token = m.group(1)!;
        // Skip if it matches YYMM / MMYY look-alike (1st in {01,02..12} or 2nd in {20..39}).
        if (token.length == 4) {
          final p1 = int.tryParse(token.substring(0, 2));
          final p2 = int.tryParse(token.substring(2, 4));
          if (p1 != null &&
              p2 != null &&
              ((p1 >= 1 && p1 <= 12 && p2 >= 20) ||
                  (p2 >= 1 && p2 <= 12 && p1 >= 20))) {
            continue; // looks like YYMM / MMYY
          }
        }
        candidates.add(token);
      }
    }
    if (candidates.isEmpty) return null;
    // Prefer a 3-digit CVV (Visa/MC/UnionPay) over 4-digit; take the first
    // occurrence. Amex cards will usually provide 4-digit later in the list.
    candidates.sort((a, b) => a.length.compareTo(b.length)); // 3→4 order
    return candidates.first;
  }

  // ---- Holder name (Latin only, on standard embossed card faces) ----
  static final _nameRe =
      RegExp(r'^[A-Z][A-Z.\s\-]{1,39}[A-Z]$');
  static const _blacklisted = {
    'VALID',
    'THRU',
    'FROM',
    'GOOD',
    'CARDHOLDER',
    'CARD',
    'HOLDER',
    'MEMBER',
    'SINCE',
    'EXPIRATION',
    'EXPIRES',
    'MONTH',
    'YEAR',
  };

  static String? _extractHolderName(List<String> lines) {
    for (final line in lines) {
      final trimmed = line.trim();
      // Cardholder label may precede the name: "Card Holder: JOHN DOE"
      String? nameOnly;
      final label =
          RegExp(r'(?i)(card\s*holder|cardholder|name|持卡人)[:\s]+(.*)$')
              .firstMatch(trimmed);
      if (label != null) {
        nameOnly = label.group(2)!.trim();
      } else {
        nameOnly = trimmed;
      }
      nameOnly = nameOnly!.toUpperCase();
      if (!_nameRe.hasMatch(nameOnly)) continue;
      final tokens = nameOnly.split(RegExp(r'\s+'));
      if (tokens.length < 2) continue;
      if (tokens.every((t) => _blacklisted.contains(t))) continue;
      // Reject any token that looks like a year (e.g. "GOOD THRU 2024").
      if (tokens.any((t) => RegExp(r'^(19|20)\d{2}$').hasMatch(t))) continue;
      return trimmed.toUpperCase();
    }
    return null;
  }
}
