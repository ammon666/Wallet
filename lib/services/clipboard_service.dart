import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  static final ClipboardService _instance = ClipboardService._();
  static ClipboardService get instance => _instance;

  ClipboardService._();

  Timer? _clearTimer;
  String? _currentContent;
  DateTime? _lastCopyAt;

  static const Duration _defaultClearDuration = Duration(seconds: 15);

  /// Minimum gap between two copy operations; anything faster than this is
  /// treated as a duplicate tap and silently dropped so that the caller can
  /// avoid stacking SnackBars / haptics.
  static const Duration _throttleWindow = Duration(milliseconds: 900);

  /// Copies [text] to the system clipboard.
  ///
  /// Returns `true` when the text was actually written, `false` when the
  /// call was throttled (duplicate tap within [_throttleWindow]).
  Future<bool> copy(String text, {Duration? clearAfter}) async {
    final now = DateTime.now();
    if (_lastCopyAt != null &&
        now.difference(_lastCopyAt!) < _throttleWindow) {
      return false;
    }
    _lastCopyAt = now;

    await Clipboard.setData(ClipboardData(text: text));
    _currentContent = text;

    _clearTimer?.cancel();
    _clearTimer = Timer(clearAfter ?? _defaultClearDuration, _clearClipboard);
    return true;
  }

  Future<void> _clearClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == _currentContent) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (_) {}

    _currentContent = null;
    _clearTimer = null;
  }
}
