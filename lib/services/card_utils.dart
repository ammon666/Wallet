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
}
