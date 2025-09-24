import 'package:flutter/material.dart';

/// テスラ風ミニマルデザインのカラーパレット
/// テスラの公式サイトのような洗練されたシンプルなカラーを定義
class TeslaStyleColors {
  // 基本カラー（Tesla公式サイト準拠）

  /// 背景色: 純白 - テスラの清潔でミニマルな印象
  static const Color background = Color(0xFFFFFFFF);

  /// セカンダリ背景色: わずかに青みがかったオフホワイト
  static const Color backgroundSecondary = Color(0xFFFCFDFE);

  /// メインカラー: テスラブルー（明るい水色）
  /// テスラのブランドカラーに近い、清涼感のあるブルー
  static const Color primary = Color(0xFF3ABFF8);

  /// プライマリダーク: より深みのあるテスラブルー
  static const Color primaryDark = Color(0xFF1E90D4);

  /// アクセントカラー: より濃い水色
  /// インタラクション要素や強調表示に使用
  static const Color accent = Color(0xFF0EA5E9);

  /// アクセントダーク: 深い水色
  static const Color accentDark = Color(0xFF0284C7);

  /// シャドウカラー: 薄いグレー
  /// 影や境界線などの微細な表現に使用
  static const Color shadow = Color(0xFFE2E8F0);
  static const Color shadowLight = Color(0xFFF1F5F9);

  /// テキストカラー: ダークグレー
  /// 高いコントラストを保ちながらも優しい印象
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);

  /// サーフェス（表面）カラー
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC);

  /// 成功・エラー・警告カラー（テスラ風に調整）
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  /// ホバー・フォーカス状態
  static const Color primaryHover = Color(0xFF22D3EE);
  static const Color accentHover = Color(0xFF0369A1);

  /// 透明度付きカラー
  static Color get primaryWithOpacity => primary.withOpacity(0.1);
  static Color get accentWithOpacity => accent.withOpacity(0.1);
  static Color get shadowWithOpacity => shadow.withOpacity(0.5);

  // カスタムグラデーション

  /// テスラ風グラデーション: 水色から青へ
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3ABFF8),
      Color(0xFF0EA5E9),
    ],
  );

  /// サブルグラデーション: 薄い青のグラデーション
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );

  /// 影のグラデーション
  static final LinearGradient shadowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      shadow.withOpacity(0.1),
    ],
  );

  // テーマ定義

  /// テスラスタイルのライトテーマカラースキーム
  static ColorScheme get lightColorScheme => ColorScheme.light(
        primary: primary,
        primaryContainer: primaryWithOpacity,
        secondary: accent,
        secondaryContainer: accentWithOpacity,
        surface: surface,
        surfaceVariant: surfaceVariant,
        background: background,
        error: error,
        onPrimary: background,
        onSecondary: background,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: background,
        brightness: Brightness.light,
        outline: shadow,
      );

  /// BoxShadow定義（テスラ風の洗練された影）
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 20,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: shadow.withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  /// ハイライト効果（ホバーやフォーカス時）
  static List<BoxShadow> get highlightShadow => [
        BoxShadow(
          color: primary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 0),
          spreadRadius: 2,
        ),
      ];

  // 冷蔵庫ウィジェット専用カラー

  /// 冷蔵庫のドアカラー（テスラ風ホワイト）
  static const Color fridgeDoor = Color(0xFFFAFAFA);

  /// 冷蔵庫の内部カラー（微かにブルーティント）
  static const Color fridgeInterior = Color(0xFFF0F9FF);

  /// 冷蔵庫のハンドル（シルバーグレー）
  static const Color fridgeHandle = Color(0xFFCBD5E1);

  /// 冷蔵庫のアクセント（テスラブルー）
  static const Color fridgeAccent = primary;

  /// バッジ・ラベルカラー
  static const Color badgeBackground = primary;
  static const Color badgeText = background;

  /// インタラクション状態のカラー
  static Color get fridgeDoorHover => fridgeDoor.withOpacity(0.9);
  static Color get fridgeAccentGlow => primary.withOpacity(0.3);
}

/// カラーパレットのユーティリティ拡張
extension TeslaColorExtensions on Color {
  /// より薄いバリエーションを生成
  Color get lighter {
    return Color.lerp(this, Colors.white, 0.3) ?? this;
  }

  /// より濃いバリエーションを生成
  Color get darker {
    return Color.lerp(this, Colors.black, 0.2) ?? this;
  }

  /// 透明度を調整したカラーを生成
  Color withAlpha(double alpha) {
    return withOpacity(alpha.clamp(0.0, 1.0));
  }
}
