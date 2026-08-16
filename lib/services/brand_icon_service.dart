import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Loads SVG brand icons from bundled text assets and renders them
/// with a consistent target size so card network & issuer badges line up.
///
/// Sources are plain text files (one SVG per entry) bundled under:
///   - assets/icons/network_icons.txt
///   - assets/icons/issuer_icons.txt
class BrandIconService {
  BrandIconService._();
  static final BrandIconService instance = BrandIconService._();

  static const _networkAsset = 'assets/icons/network_icons.txt';
  static const _issuerAsset = 'assets/icons/issuer_icons.txt';

  Map<String, String> _networkSvgs = {};
  Map<String, String> _issuerSvgs = {};
  bool _initialized = false;

  /// Map the internal network key (e.g. "unionpay") to the label used
  /// inside the bundled text file (e.g. "银联").
  static const Map<String, String> _networkKeyToLabel = {
    'unionpay': '银联',
    'visa': 'VISA',
    'mastercard': '万事达',
    'jcb': 'JCB',
    'amex': 'American Express',
    'discover': 'Discover',
    'rupay': 'Rupay',
  };

  /// Initialises the in-memory caches; safe to call multiple times.
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final nwText = await rootBundle.loadString(_networkAsset);
      _networkSvgs = _parseIconText(nwText);
    } catch (_) {
      _networkSvgs = {};
    }
    try {
      final issText = await rootBundle.loadString(_issuerAsset);
      _issuerSvgs = _parseIconText(issText);
    } catch (_) {
      _issuerSvgs = {};
    }
  }

  /// Parses an icon bundle text file.
  ///
  /// Format:
  ///   标签名：
  ///   <svg ...>...</svg>
  ///
  ///   下一个标签：
  ///   <svg ...>...</svg>
  static Map<String, String> _parseIconText(String raw) {
    final out = <String, String>{};
    final lines = raw.split(RegExp(r'\r?\n'));
    String? currentName;
    final buf = StringBuffer();
    bool inSvg = false;

    void flushSvg() {
      if (currentName != null && buf.isNotEmpty) {
        out[_normalizeName(currentName!)] = _sanitizeSvg(buf.toString());
      }
      buf.clear();
      inSvg = false;
      currentName = null;
    }

    for (final line in lines) {
      final trimmed = line.trim();
      // Empty line between entries flushes any pending SVG.
      if (trimmed.isEmpty) {
        if (inSvg && currentName != null) {
          // Keep collecting; SVGs can contain blank-ish metadata lines.
        }
        continue;
      }

      // Skip XML prolog that some entries have.
      if (trimmed.startsWith('<?xml')) {
        // But still mark that we're starting the SVG section.
        inSvg = true;
        continue;
      }

      // New label "NAME：" starts a new entry.
      if (!inSvg && trimmed.contains('：') && !trimmed.startsWith('<')) {
        // Flush previous entry if present.
        flushSvg();
        final idx = trimmed.indexOf('：');
        currentName = trimmed.substring(0, idx).trim();
        continue;
      }

      // Also support ASCII ':' as a fallback separator.
      if (!inSvg &&
          trimmed.contains(':') &&
          !trimmed.startsWith('<') &&
          !trimmed.startsWith('http')) {
        flushSvg();
        final idx = trimmed.indexOf(':');
        final candidate = trimmed.substring(0, idx).trim();
        if (candidate.isNotEmpty && !candidate.contains('<')) {
          currentName = candidate;
          continue;
        }
      }

      // SVG content collection (accumulates until we hit the next label).
      if (currentName != null) {
        if (trimmed.startsWith('<svg') || trimmed.startsWith('</svg>') || inSvg) {
          inSvg = true;
          buf.writeln(line);
          if (trimmed.endsWith('</svg>') || trimmed.contains('</svg>')) {
            // Completed an SVG block; still buffer it in case the name/entry
            // repeats later; final flush happens on next label or EOF.
            flushSvg();
          }
          continue;
        } else if (trimmed.startsWith('<')) {
          inSvg = true;
          buf.writeln(line);
          continue;
        }
      }
    }
    // End of file: flush whatever was in progress.
    if (currentName != null && buf.isNotEmpty) {
      out[_normalizeName(currentName!)] = _sanitizeSvg(buf.toString());
    }
    return out;
  }

  /// Normalises a name before lookup so that 中国工商银行 / 工商银行
  /// (and other small punctuation/case/whitespace variations) still match.
  static String _normalizeName(String name) {
    if (name.isEmpty) return '';
    return name
        .replaceAll(' ', '')
        .replaceAll('\t', '')
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('　', '')
        .toLowerCase()
        .trim();
  }

  /// Returns the raw SVG string for a network key, or null when not bundled.
  String? getNetworkSvg(String? networkKey) {
    if (networkKey == null) return null;
    final label = _networkKeyToLabel[networkKey.toLowerCase()] ?? networkKey;
    return _networkSvgs[_normalizeName(label)] ??
        _networkSvgs[_normalizeName(networkKey)];
  }

  /// Returns the raw SVG string for an issuer (exact or partial match),
  /// or null when not bundled.
  String? getIssuerSvg(String? issuerName) {
    if (issuerName == null || issuerName.trim().isEmpty) return null;
    final key = _normalizeName(issuerName);
    if (key.isEmpty) return null;
    if (_issuerSvgs.containsKey(key)) return _issuerSvgs[key];

    // Fuzzy partial match: the bundle might store "中国工商银行" while
    // the user typed "工商银行" or "工行". Try longest partial first.
    String? best;
    int bestLen = 0;
    for (final entry in _issuerSvgs.entries) {
      if (entry.key.contains(key) || key.contains(entry.key)) {
        if (entry.key.length > bestLen) {
          bestLen = entry.key.length;
          best = entry.value;
        }
      }
    }
    return best;
  }

  // ---------------------------------------------------------------------------
  // Widget builders
  // ---------------------------------------------------------------------------

  /// Renders the network icon for [networkKey] inside a fixed bounding box so
  /// all network badges share the same overall visual footprint.
  ///
  /// Using a fixed width+height constraint (instead of height-only) prevents
  /// extra-wide SVGs like VISA from appearing visually larger than squarish
  /// SVGs like UnionPay/Mastercard: long logos simply shrink to fit the box.
  ///
  /// Returns `null` when the network is not bundled so the caller can fall
  /// back to text (matching the original `_NetworkLogo` contract).
  Widget? buildNetworkIcon(
    BuildContext context,
    String? networkKey, {
    double width = 92,
    double height = 30,
  }) {
    final svg = getNetworkSvg(networkKey);
    if (svg == null) return null;
    return _renderSvg(svg, width: width, height: height, alignment: Alignment.centerRight);
  }

  /// Renders the issuer icon for [issuerName] inside a fixed bounding box.
  ///
  /// Height is deliberately pinned to the same default (30) used by
  /// [buildNetworkIcon] so the two top-corner badges share a consistent
  /// visual "ruler" / scale on the card face.
  ///
  /// Returns `null` when the issuer is not bundled so the caller can fall
  /// back to text (matching the original `_IssuerBadge` contract).
  Widget? buildIssuerIcon(
    BuildContext context,
    String? issuerName, {
    double width = 160,
    double height = 30,
  }) {
    final svg = getIssuerSvg(issuerName);
    if (svg == null) return null;
    return _renderSvg(svg, width: width, height: height);
  }

  static Widget _renderSvg(
    String svgContent, {
    required double width,
    required double height,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: alignment,
        child: SvgPicture.string(
          svgContent,
          height: height,
          width: width,
          fit: BoxFit.contain,
          clipBehavior: Clip.none,
        ),
      ),
    );
  }

  /// Strips explicit `width=".."` / `height=".."` attributes from the root
  /// `<svg>` tag so that the flutter_svg widget's size parameters take full
  /// control (otherwise the bundled SVGs' `width="200"` / `height="200"` can
  /// interfere with the fixed-height rendering and cause clipping or
  /// inconsistently-sized badges).
  ///
  /// Also strips the `t=".."` / `p-id=".."` attributes which are non-standard
  /// carry-overs from iconfont exports that flutter_svg doesn't need.
  static String _sanitizeSvg(String rawSvg) {
    if (rawSvg.isEmpty) return rawSvg;
    const svgTag = r'<svg\s+';
    final match = RegExp(svgTag, caseSensitive: false).firstMatch(rawSvg);
    if (match == null) return rawSvg;

    final start = match.start;
    // Find the end of the opening <svg ...> tag
    int i = match.end;
    int depth = 1;
    while (i < rawSvg.length && depth > 0) {
      final ch = rawSvg[i];
      if (ch == '<') {
        break;
      }
      if (ch == '>') {
        i++;
        break;
      }
      i++;
    }
    final head = rawSvg.substring(0, start);
    final tag = rawSvg.substring(start, i);
    final tail = rawSvg.substring(i);

    // Remove width / height (both quotes), and t / p-id attributes.
    final attrRe = RegExp(
      r'''\s(?:width|height|t|p-id)\s*=\s*(?:"[^"]*"|'[^']*')''',
      caseSensitive: false,
      dotAll: false,
    );
    final cleanedTag = tag.replaceAllMapped(attrRe, (_) => '');

    return '$head$cleanedTag$tail';
  }

  // ---------------------------------------------------------------------------
  // Public metadata used by card entry forms to build issuer dropdowns
  // ---------------------------------------------------------------------------

  /// All bundled issuer names (sorted by pinyin initial of the second
  /// character — the first meaningful character of Chinese bank names,
  /// e.g. "交通银行" → "交" → J).
  ///
  /// Custom entries not in the pinyin table fall back to Unicode order.
  List<String> get availableIssuers {
    final list = _issuerSvgs.keys.toList();
    list.sort((a, b) {
      final pa = _pinyinOrder(a);
      final pb = _pinyinOrder(b);
      if (pa != pb) return pa.compareTo(pb);
      return a.compareTo(b);
    });
    return List.unmodifiable(list);
  }

  /// Returns a sortable key for Chinese issuer names based on the pinyin
  /// initial of the second character (the name's first meaningful char).
  ///
  /// "交通银行" → second char "交" → J → "J_交通银行"
  /// "招商银行" → second char "招" → Z → "Z_招商银行"
  ///
  /// Unknown characters fall back to Unicode code point (prefixed with "~"
  /// so they sort after all pinyin-mapped entries).
  static String _pinyinOrder(String name) {
    if (name.length < 2) return '~$name';
    final ch = name[1];
    final initial = _pinyinInitials[ch];
    if (initial != null) return '${initial}_$name';
    return '~${ch.codeUnits.first.toRadixString(16)}_$name';
  }

  /// Maps common Chinese characters used in bank names to their pinyin
  /// initial letter. Covers all bundled issuer_icons.txt entries plus
  /// common additions.
  static const Map<String, String> _pinyinInitials = {
    '北': 'B', '邮': 'Y',
    '建': 'J', '交': 'J', '江': 'J',
    '广': 'G', '工': 'G', '光': 'G', '国': 'G', '桂': 'G',
    '华': 'H', '汇': 'H', '徽': 'H',
    '浦': 'P', '平': 'P',
    '三': 'S', '上': 'S', '深': 'S', '苏': 'S',
    '网': 'W',
    '招': 'Z', '中': 'Z', '众': 'Z',
    '杭': 'H', '恒': 'H', '湖': 'H',
    '农': 'N', '宁': 'N', '南': 'N',
    '民': 'M',
    '兴': 'X',
    '渝': 'Y',
    '浙': 'Z',
  };

  /// Sentinel value used by dropdown menus to signal that the user wants
  /// to enter a free-form issuer name that is not bundled in the icon set.
  static const String issuerOtherSentinel = '__other__';
}
