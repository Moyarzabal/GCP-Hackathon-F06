/// プラットフォーム適応型ウィジェットライブラリ
///
/// このファイルはすべての適応型ウィジェットへの統一インターフェースを提供します。
/// iOS、Android、Webで一貫したUXを実現しながら、各プラットフォームの
/// ネイティブな操作感を維持します。
library adaptive_widgets;

export 'adaptive_button.dart';
export 'adaptive_dialog.dart';
export 'adaptive_navigation.dart';
export 'adaptive_scaffold.dart';

/// アダプティブウィジェットの設定
class AdaptiveWidgetsConfig {
  static bool _debugMode = false;

  /// デバッグモードの有効化
  static void enableDebugMode() {
    _debugMode = true;
  }

  /// デバッグモードの無効化
  static void disableDebugMode() {
    _debugMode = false;
  }

  /// デバッグモードの状態を取得
  static bool get isDebugMode => _debugMode;
}

/// アダプティブウィジェットのユーティリティクラス
class AdaptiveWidgetsUtils {
  /// プラットフォーム別の推奨パディング値を取得
  static double getRecommendedPadding() {
    return 16.0; // 全プラットフォーム共通
  }

  /// プラットフォーム別の推奨ボーダー半径を取得
  static double getRecommendedBorderRadius() {
    return 12.0; // 全プラットフォーム共通
  }

  /// プラットフォーム別の推奨スペーシングを取得
  static double getRecommendedSpacing() {
    return 8.0; // 全プラットフォーム共通
  }
}
