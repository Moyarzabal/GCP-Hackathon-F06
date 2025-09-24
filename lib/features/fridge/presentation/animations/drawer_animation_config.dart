import 'package:flutter/material.dart';

/// 引き出しアニメーションの設定
class DrawerAnimationConfig {
  /// アニメーション開始の遅延
  static const Duration initialDelay = Duration(milliseconds: 100);

  /// 引き出しの開くアニメーション時間
  static const Duration drawerOpenDuration = Duration(milliseconds: 600);

  /// 視点変更のアニメーション時間
  static const Duration viewTransitionDuration = Duration(milliseconds: 400);

  /// 全体のアニメーション時間
  static const Duration totalAnimationDuration = Duration(milliseconds: 700);

  /// 引き出しの開く距離（画面比率）
  static const double drawerOpenDistance = 0.15;

  /// アニメーションカーブ
  static const Curve drawerOpenCurve = Curves.easeOutCubic;
  static const Curve viewTransitionCurve = Curves.easeInOutQuart;

  /// 引き出しアニメーションの段階
  static const double drawerPullPhaseStart = 0.0;
  static const double drawerPullPhaseEnd = 0.4;
  static const double viewTransitionPhaseStart = 0.3;
  static const double viewTransitionPhaseEnd = 1.0;

  /// 視覚効果
  static const double perspectiveStartAngle = 0.0; // 正面ビュー
  static const double perspectiveEndAngle = -1.2; // 上から見下ろす角度（ラジアン）
  static const double zoomOutStartScale = 1.0;
  static const double zoomOutEndScale = 0.7;

  /// 引き出しの影とハイライト
  static const Color drawerShadowColor = Color(0x40000000);
  static const double drawerShadowBlurRadius = 8.0;
  static const Offset drawerShadowOffset = Offset(0, 4);

  /// 引き出し内部の背景色
  static const Color drawerInteriorColor = Color(0xFFF8F8F8);
  static const Color drawerRimColor = Color(0xFFD0D0D0);
}
