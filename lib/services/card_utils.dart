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
  /// The mapping covers the most common Chinese bank BIN ranges. Users can
  /// always override the result manually via the dropdown.
  static String? detectCardIssuer(String? cardNumber) {
    if (cardNumber == null) return null;
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 6) return null;

    final prefix6 = cleaned.substring(0, 6);

    // 中国工商银行 ICBC
    if (RegExp(r'^62220[0-2]').hasMatch(prefix6)) return '工商银行';
    if (prefix6.startsWith('621226') ||
        prefix6.startsWith('621227') ||
        prefix6.startsWith('621281') ||
        prefix6.startsWith('621282') ||
        prefix6.startsWith('621619') ||
        prefix6.startsWith('621671') ||
        prefix6.startsWith('621673') ||
        prefix6.startsWith('621785') ||
        prefix6.startsWith('621797') ||
        prefix6.startsWith('621799') ||
        prefix6.startsWith('622210') ||
        prefix6.startsWith('622211') ||
        prefix6.startsWith('622212') ||
        prefix6.startsWith('622213') ||
        prefix6.startsWith('622214') ||
        prefix6.startsWith('955880')) {
      return '工商银行';
    }

    // 中国建设银行 CCB
    if (prefix6.startsWith('622280') ||
        prefix6.startsWith('436742') ||
        prefix6.startsWith('436745') ||
        prefix6.startsWith('622700') ||
        prefix6.startsWith('622707') ||
        prefix6.startsWith('622708') ||
        prefix6.startsWith('552245') ||
        prefix6.startsWith('621700')) {
      return '建设银行';
    }

    // 中国农业银行 ABC
    if (prefix6.startsWith('622848') ||
        prefix6.startsWith('622849') ||
        prefix6.startsWith('621282') ||
        prefix6.startsWith('621336') ||
        prefix6.startsWith('621619') ||
        prefix6.startsWith('621671') ||
        prefix6.startsWith('621673') ||
        prefix6.startsWith('622840') ||
        prefix6.startsWith('622841') ||
        prefix6.startsWith('622842') ||
        prefix6.startsWith('622843') ||
        prefix6.startsWith('622844') ||
        prefix6.startsWith('622845') ||
        prefix6.startsWith('622846') ||
        prefix6.startsWith('622847') ||
        prefix6.startsWith('955599') ||
        prefix6.startsWith('625996') ||
        prefix6.startsWith('625997')) {
      return '农业银行';
    }

    // 中国银行 BOC
    if (prefix6.startsWith('622760') ||
        prefix6.startsWith('622761') ||
        prefix6.startsWith('622762') ||
        prefix6.startsWith('622763') ||
        prefix6.startsWith('622764') ||
        prefix6.startsWith('622765') ||
        prefix6.startsWith('622766') ||
        prefix6.startsWith('622767') ||
        prefix6.startsWith('622768') ||
        prefix6.startsWith('622769') ||
        prefix6.startsWith('621785') ||
        prefix6.startsWith('621786') ||
        prefix6.startsWith('621787') ||
        prefix6.startsWith('621788') ||
        prefix6.startsWith('621789') ||
        prefix6.startsWith('621790')) {
      return '中国银行';
    }

    // 交通银行 BOCOM
    if (prefix6.startsWith('622260') ||
        prefix6.startsWith('622261') ||
        prefix6.startsWith('622262') ||
        prefix6.startsWith('955590') ||
        prefix6.startsWith('621436')) {
      return '交通银行';
    }

    // 招商银行 CMB
    if (prefix6.startsWith('622588') ||
        prefix6.startsWith('621483') ||
        prefix6.startsWith('621485') ||
        prefix6.startsWith('621486') ||
        prefix6.startsWith('622575') ||
        prefix6.startsWith('622576') ||
        prefix6.startsWith('622577') ||
        prefix6.startsWith('622578') ||
        prefix6.startsWith('622579') ||
        prefix6.startsWith('622580') ||
        prefix6.startsWith('622581') ||
        prefix6.startsWith('622582') ||
        prefix6.startsWith('356885') ||
        prefix6.startsWith('356886') ||
        prefix6.startsWith('356887') ||
        prefix6.startsWith('356888') ||
        prefix6.startsWith('356889') ||
        prefix6.startsWith('356890')) {
      return '招商银行';
    }

    // 浦发银行 SPDB
    if (prefix6.startsWith('622517') ||
        prefix6.startsWith('622518') ||
        prefix6.startsWith('622521') ||
        prefix6.startsWith('622522') ||
        prefix6.startsWith('621792') ||
        prefix6.startsWith('621793')) {
      return '浦发银行';
    }

    // 中信银行 CITIC
    if (prefix6.startsWith('622690') ||
        prefix6.startsWith('622691') ||
        prefix6.startsWith('622692') ||
        prefix6.startsWith('622696') ||
        prefix6.startsWith('622698') ||
        prefix6.startsWith('622699') ||
        prefix6.startsWith('621771') ||
        prefix6.startsWith('621770') ||
        prefix6.startsWith('955580')) {
      return '中信银行';
    }

    // 光大银行 CEB
    if (prefix6.startsWith('622660') ||
        prefix6.startsWith('622662') ||
        prefix6.startsWith('622663') ||
        prefix6.startsWith('622664') ||
        prefix6.startsWith('622665') ||
        prefix6.startsWith('622666') ||
        prefix6.startsWith('622667') ||
        prefix6.startsWith('622668') ||
        prefix6.startsWith('622669') ||
        prefix6.startsWith('622670') ||
        prefix6.startsWith('622671') ||
        prefix6.startsWith('622672') ||
        prefix6.startsWith('622673') ||
        prefix6.startsWith('620518') ||
        prefix6.startsWith('621488') ||
        prefix6.startsWith('621489')) {
      return '光大银行';
    }

    // 民生银行 CMBC
    if (prefix6.startsWith('622615') ||
        prefix6.startsWith('622616') ||
        prefix6.startsWith('622618') ||
        prefix6.startsWith('622619') ||
        prefix6.startsWith('622620') ||
        prefix6.startsWith('622621') ||
        prefix6.startsWith('622622') ||
        prefix6.startsWith('622623') ||
        prefix6.startsWith('621691') ||
        prefix6.startsWith('622600') ||
        prefix6.startsWith('622601') ||
        prefix6.startsWith('622602') ||
        prefix6.startsWith('622603')) {
      return '民生银行';
    }

    // 广发银行 CGB
    if (prefix6.startsWith('622555') ||
        prefix6.startsWith('622556') ||
        prefix6.startsWith('622557') ||
        prefix6.startsWith('622558') ||
        prefix6.startsWith('622559') ||
        prefix6.startsWith('622560') ||
        prefix6.startsWith('955080') ||
        prefix6.startsWith('621462')) {
      return '广发银行';
    }

    // 兴业银行 CIB
    if (prefix6.startsWith('622909') ||
        prefix6.startsWith('622901') ||
        prefix6.startsWith('622902') ||
        prefix6.startsWith('622903') ||
        prefix6.startsWith('622908') ||
        prefix6.startsWith('621423') ||
        prefix6.startsWith('622900')) {
      return '兴业银行';
    }

    // 平安银行 PAB
    if (prefix6.startsWith('622155') ||
        prefix6.startsWith('622156') ||
        prefix6.startsWith('622157') ||
        prefix6.startsWith('622158') ||
        prefix6.startsWith('622159') ||
        prefix6.startsWith('622161') ||
        prefix6.startsWith('622162') ||
        prefix6.startsWith('622163') ||
        prefix6.startsWith('998800') ||
        prefix6.startsWith('621626')) {
      return '平安银行';
    }

    // 华夏银行 HXB
    if (prefix6.startsWith('622630') ||
        prefix6.startsWith('622631') ||
        prefix6.startsWith('622632') ||
        prefix6.startsWith('622633') ||
        prefix6.startsWith('621665') ||
        prefix6.startsWith('621666') ||
        prefix6.startsWith('621667') ||
        prefix6.startsWith('621668') ||
        prefix6.startsWith('621669') ||
        prefix6.startsWith('622637') ||
        prefix6.startsWith('622638')) {
      return '华夏银行';
    }

    // 邮储银行 PSBC
    if (prefix6.startsWith('621096') ||
        prefix6.startsWith('621098') ||
        prefix6.startsWith('621095') ||
        prefix6.startsWith('622150') ||
        prefix6.startsWith('622151') ||
        prefix6.startsWith('621799') ||
        prefix6.startsWith('621899')) {
      return '邮储银行';
    }

    // 北京银行 BOB
    if (prefix6.startsWith('621468') ||
        prefix6.startsWith('621420') ||
        prefix6.startsWith('622163') ||
        prefix6.startsWith('622164')) {
      return '北京银行';
    }

    // 上海银行 BOS
    if (prefix6.startsWith('622173') ||
        prefix6.startsWith('622174') ||
        prefix6.startsWith('621740') ||
        prefix6.startsWith('621741')) {
      return '上海银行';
    }

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
