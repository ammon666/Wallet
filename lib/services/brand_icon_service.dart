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
        out[_normalizeName(currentName!)] = buf.toString();
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
      out[_normalizeName(currentName!)] = buf.toString();
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

  /// Renders the network icon for [networkKey] inside a fixed-height box so
  /// all network badges share the same vertical footprint.
  ///
  /// Returns `null` when the network is not bundled so the caller can fall
  /// back to text (matching the original `_NetworkLogo` contract).
  Widget? buildNetworkIcon(
    BuildContext context,
    String? networkKey, {
    double height = 32,
  }) {
    final svg = getNetworkSvg(networkKey);
    if (svg == null) return null;
    return _renderSvg(svg, height: height);
  }

  /// Renders the issuer icon for [issuerName] inside a fixed-height box.
  ///
  /// Returns `null` when the issuer is not bundled so the caller can fall
  /// back to text (matching the original `_IssuerBadge` contract).
  Widget? buildIssuerIcon(
    BuildContext context,
    String? issuerName, {
    double height = 28,
  }) {
    final svg = getIssuerSvg(issuerName);
    if (svg == null) return null;
    return _renderSvg(svg, height: height);
  }

  static Widget _renderSvg(String svgContent, {required double height}) {
    return SizedBox(
      height: height,
      child: Center(
        child: SvgPicture.string(
          svgContent,
          height: height,
          fit: BoxFit.contain,
          clipBehavior: Clip.none,
        ),
      ),
    );
  }
}
