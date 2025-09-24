import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// プラットフォーム情報を提供するクラス
class PlatformInfo {
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isWeb => kIsWeb;
  static bool get isMobile => isIOS || isAndroid;
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  static String get platformName {
    if (isWeb) return 'Web';
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Webでアクセスしているかどうかを判定
  static bool get isWebAccess => kIsWeb;

  /// スマートフォンサイズかどうかを判定（Webの場合）
  static bool isMobileSize(BuildContext context) {
    if (!kIsWeb) return isMobile;

    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 768; // タブレットサイズ以下をモバイルと判定
  }

  /// PCサイズかどうかを判定（Webの場合）
  static bool isDesktopSize(BuildContext context) {
    if (!kIsWeb) return isDesktop;

    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 768; // タブレットサイズ以上をデスクトップと判定
  }

  /// 警告メッセージを表示すべきかどうかを判定
  static bool shouldShowWarning(BuildContext context) {
    return isWebAccess && isDesktopSize(context);
  }
}
