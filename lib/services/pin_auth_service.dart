import 'package:flutter/services.dart';

/// 强制使用设备凭据（PIN / 密码 / 图案）进行身份验证的服务。
///
/// 与 [LocalAuthentication] 不同，本服务在 Android 端通过原生
/// [BiometricPrompt] + [Authenticators.DEVICE_CREDENTIAL] 仅允许设备凭据，
/// **完全排除指纹 / 人脸等生物识别**。用于"删除所有数据"等高危险操作，
/// 以满足"只能验证 PIN 而不能验证指纹"的需求。
///
/// 仅 Android 平台可用；其他平台视为不支持（[isSupported] 返回 false）。
class PinAuthService {
  static const _channel = MethodChannel('com.sidhant.wallet/pin_auth');

  /// 当前平台是否支持「仅 PIN 验证」。
  static Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 弹出系统级 PIN / 密码 / 图案验证界面。
  ///
  /// [title] 验证窗口标题（必填）。
  /// [subtitle] 验证窗口副标题（可选）。
  ///
  /// 返回 true 表示验证成功；false 表示用户取消或验证失败。
  /// 平台不支持时返回 false。
  static Future<bool> authenticate({
    required String title,
    String? subtitle,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('authenticate', {
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
