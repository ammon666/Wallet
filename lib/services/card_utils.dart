import 'package:wallet/l10n/app_localizations.dart';

class CardUtils {
  static String? detectCardNetwork(String? cardNumber) {
    if (cardNumber == null) return null;

    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return null;

    // American Express: starts with 34 or 37
    if (cleaned.length >= 2) {
      final prefix2 = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      if (prefix2 == 34 || prefix2 == 37) {
        return 'amex';
      }
    }

    // JCB: starts with 3528-3589
    if (cleaned.length >= 4) {
      final prefix4 = int.tryParse(cleaned.substring(0, 4)) ?? 0;
      if (prefix4 >= 3528 && prefix4 <= 3589) {
        return 'jcb';
      }
    }

    // RuPay: starts with 60, 65, 81, 82, or 508
    // Must check before Discover since both can start with 60/65
    if (cleaned.length >= 2) {
      final prefix2 = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      if (prefix2 == 81 || prefix2 == 82) {
        return 'rupay';
      }
      if (prefix2 == 50) {
        if (cleaned.length >= 3 && cleaned[2] == '8') {
          return 'rupay';
        }
      }
    }

    // Discover: starts with 6011, 644-649, or 65
    if (cleaned.length >= 2) {
      final prefix2 = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      if (prefix2 >= 64 && prefix2 <= 69) {
        return 'discover';
      }
      if (prefix2 == 65) {
        return 'discover';
      }
    }
    if (cleaned.length >= 4) {
      final prefix4 = int.tryParse(cleaned.substring(0, 4)) ?? 0;
      if (prefix4 == 6011) {
        return 'discover';
      }
    }

    // UnionPay: starts with 62
    if (cleaned.startsWith('62')) {
      return 'unionpay';
    }

    // Mastercard: starts with 51-55 or 2221-2720
    if (cleaned.length >= 2) {
      final prefix2 = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      if (prefix2 >= 51 && prefix2 <= 55) {
        return 'mastercard';
      }
    }
    if (cleaned.length >= 4) {
      final prefix4 = int.tryParse(cleaned.substring(0, 4)) ?? 0;
      if (prefix4 >= 2221 && prefix4 <= 2720) {
        return 'mastercard';
      }
    }

    // Visa: starts with 4
    if (cleaned.startsWith('4')) {
      return 'visa';
    }

    return null;
  }

  /// Display names for each supported card network.

  /// Attempts to detect the card issuer (发卡行) from the card number's
  /// BIN/IIN prefix. Returns the issuer name in Chinese, or null if the
  /// prefix is not recognised. This is purely offline — no network calls.
  ///
  /// Uses numeric range comparison (faster & cleaner than string prefix
  /// matching). Each bank maps to one or more BIN ranges; ranges are
  /// checked in order so more-specific entries win.
  ///
  /// Users can always override the result manually via the dropdown.
  static String? detectCardIssuer(String? cardNumber) {
    if (cardNumber == null) return null;
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 6) return null;
    final bin = int.tryParse(cleaned.substring(0, 6));
    if (bin == null) return null;

    // ── 中国工商银行 ICBC ──
    if (bin >= 621226 && bin <= 621227) return '工商银行';
    if (bin >= 621281 && bin <= 621282) return '工商银行';
    if (bin >= 621558 && bin <= 621559) return '工商银行';
    if (bin >= 621618 && bin <= 621619) return '工商银行';
    if (bin >= 621670 && bin <= 621672) return '工商银行';
    if (bin >= 621784 && bin <= 621786) return '工商银行';
    if (bin >= 621797 && bin <= 621799) return '工商银行';
    if (bin >= 622200 && bin <= 622203) return '工商银行';
    if (bin >= 622208 && bin <= 622214) return '工商银行';
    if (bin >= 622225 && bin <= 622230) return '工商银行';
    if (bin >= 955880 && bin <= 955882) return '工商银行';

    // ── 中国建设银行 CCB ──
    if (bin >= 436742 && bin <= 436745) return '建设银行';
    if (bin >= 552245 && bin <= 552246) return '建设银行';
    if (bin >= 621080 && bin <= 621082) return '建设银行';
    if (bin >= 621466 && bin <= 621467) return '建设银行';
    if (bin >= 621488 && bin <= 621489) return '建设银行';
    if (bin >= 621598 && bin <= 621599) return '建设银行';
    if (bin >= 621673 && bin <= 621674) return '建设银行';
    if (bin >= 621700 && bin <= 621701) return '建设银行';
    if (bin >= 622280 && bin <= 622281) return '建设银行';
    if (bin >= 622700 && bin <= 622708) return '建设银行';
    if (bin >= 622725 && bin <= 622726) return '建设银行';

    // ── 中国农业银行 ABC ──
    if (bin >= 621282 && bin <= 621283) return '农业银行';
    if (bin >= 621336 && bin <= 621337) return '农业银行';
    if (bin >= 621619 && bin <= 621620) return '农业银行';
    if (bin >= 621671 && bin <= 621673) return '农业银行';
    if (bin >= 622836 && bin <= 622839) return '农业银行';
    if (bin >= 622840 && bin <= 622849) return '农业银行';
    if (bin >= 625996 && bin <= 625999) return '农业银行';
    if (bin >= 955599 && bin <= 955599) return '农业银行';

    // ── 中国银行 BOC ──
    if (bin >= 621660 && bin <= 621663) return '中国银行';
    if (bin >= 621756 && bin <= 621758) return '中国银行';
    if (bin >= 621785 && bin <= 621786) return '中国银行';
    if (bin >= 621788 && bin <= 621790) return '中国银行';
    if (bin >= 622760 && bin <= 622769) return '中国银行';
    if (bin >= 622770 && bin <= 622771) return '中国银行';
    if (bin >= 622775 && bin <= 622777) return '中国银行';

    // ── 交通银行 BOCOM ──
    if (bin >= 621436 && bin <= 621437) return '交通银行';
    if (bin >= 622260 && bin <= 622262) return '交通银行';
    if (bin >= 622282 && bin <= 622283) return '交通银行';
    if (bin >= 955590 && bin <= 955591) return '交通银行';

    // ── 招商银行 CMB ──
    if (bin >= 356885 && bin <= 356890) return '招商银行';
    if (bin >= 621483 && bin <= 621487) return '招商银行';
    if (bin >= 622575 && bin <= 622582) return '招商银行';
    if (bin >= 622588 && bin <= 622589) return '招商银行';
    if (bin >= 625888 && bin <= 625889) return '招商银行';

    // ── 浦发银行 SPDB ──
    if (bin >= 621792 && bin <= 621793) return '浦发银行';
    if (bin >= 622500 && bin <= 622501) return '浦发银行';
    if (bin >= 622517 && bin <= 622522) return '浦发银行';
    if (bin >= 625957 && bin <= 625958) return '浦发银行';

    // ── 中信银行 CITIC ──
    if (bin >= 621770 && bin <= 621773) return '中信银行';
    if (bin >= 622675 && bin <= 622679) return '中信银行';
    if (bin >= 622680 && bin <= 622681) return '中信银行';
    if (bin >= 622688 && bin <= 622692) return '中信银行';
    if (bin >= 622695 && bin <= 622699) return '中信银行';

    // ── 光大银行 CEB ──
    if (bin >= 620518 && bin <= 620519) return '光大银行';
    if (bin >= 621488 && bin <= 621489) return '光大银行';
    if (bin >= 622660 && bin <= 622669) return '光大银行';
    if (bin >= 622670 && bin <= 622674) return '光大银行';

    // ── 民生银行 CMBC ──
    if (bin >= 621691 && bin <= 621692) return '民生银行';
    if (bin >= 622600 && bin <= 622603) return '民生银行';
    if (bin >= 622615 && bin <= 622623) return '民生银行';

    // ── 广发银行 CGB ──
    if (bin >= 621462 && bin <= 621463) return '广发银行';
    if (bin >= 622555 && bin <= 622560) return '广发银行';
    if (bin >= 955080 && bin <= 955081) return '广发银行';

    // ── 兴业银行 CIB ──
    if (bin >= 621423 && bin <= 621424) return '兴业银行';
    if (bin >= 622900 && bin <= 622903) return '兴业银行';
    if (bin >= 622907 && bin <= 622909) return '兴业银行';

    // ── 平安银行 PAB ──
    if (bin >= 621626 && bin <= 621627) return '平安银行';
    if (bin >= 622155 && bin <= 622163) return '平安银行';
    if (bin >= 998800 && bin <= 998801) return '平安银行';

    // ── 华夏银行 HXB ──
    if (bin >= 621665 && bin <= 621669) return '华夏银行';
    if (bin >= 622630 && bin <= 622638) return '华夏银行';

    // ── 邮储银行 PSBC ──
    if (bin >= 621095 && bin <= 621098) return '邮储银行';
    if (bin >= 621799 && bin <= 621800) return '邮储银行';
    if (bin >= 622150 && bin <= 622151) return '邮储银行';
    if (bin >= 622181 && bin <= 622184) return '邮储银行';

    // ── 北京银行 BOB ──
    if (bin >= 621420 && bin <= 621422) return '北京银行';
    if (bin >= 621468 && bin <= 621469) return '北京银行';
    if (bin >= 622163 && bin <= 622166) return '北京银行';

    // ── 上海银行 BOS ──
    if (bin >= 621740 && bin <= 621741) return '上海银行';
    if (bin >= 622173 && bin <= 622174) return '上海银行';

    return null;
  }

  /// Returns the card category (credit/debit) based on the first digit
  /// of the card number. This is a rough heuristic:
  ///   - Cards starting with '62' (UnionPay debit) → 'debit'
  ///   - Cards starting with '4' (Visa) or '5' (Mastercard) → 'credit'
  ///   - Returns null when uncertain.
  static String? detectCardCategory(String? cardNumber) {
    if (cardNumber == null) return null;
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return null;
    if (cleaned.startsWith('62')) return 'debit';
    if (cleaned.startsWith('4') || cleaned.startsWith('5')) return 'credit';
    return null;
  }
  /// Brand names (银联, JCB) are kept consistent across locales.
  static const Map<String, String> networkDisplayNames = {
    'visa': 'VISA',
    'mastercard': 'MASTERCARD',
    'amex': 'AMEX',
    'discover': 'DISCOVER',
    'rupay': 'RUPAY',
    'unionpay': '银联',
    'jcb': 'JCB',
  };

  /// Returns the display name for a network key, falling back to uppercase.
  static String? networkDisplayName(String? network) {
    if (network == null) return null;
    return networkDisplayNames[network] ?? network.toUpperCase();
  }

  /// Returns the LOCALIZED display name for a network key.
  /// Uses AppLocalizations so "mastercard" → "万事达" in zh, "Mastercard" in en.
  static String? networkDisplayNameLocalized(String? network, AppLocalizations l) {
    if (network == null) return null;
    switch (network) {
      case 'visa':
        return l.networkVisa;
      case 'mastercard':
        return l.networkMastercard;
      case 'amex':
        return l.networkAmex;
      case 'discover':
        return l.networkDiscover;
      case 'rupay':
        return l.networkRupay;
      case 'unionpay':
        return l.networkUnionpay;
      case 'jcb':
        return l.networkJcb;
      default:
        return network.toUpperCase();
    }
  }
}
