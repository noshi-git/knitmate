import 'dart:ui';

import '../stitch_symbol_geometry.dart';
import 'step2_t_family_symbols.dart';

// Step4: 特殊記号（引き上げ・すじ・玉・交差・ポップコーンなど）
class Step4SpecialSymbols {
  Step4SpecialSymbols._();

  // --- こま編み系 ---

  // こま編み表引き上げ編み — X + 下の U（開口上向き）
  static void paintSingleCrochetFrontPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final center = const Offset(0.5, 0.42);
    final size = geometry.metrics.crossSize * 0.9;
    geometry.drawX(canvas, contentRect, center: center, size: size);
    geometry.drawUHookUnderX(
      canvas,
      contentRect,
      center: center,
      crossSize: size,
      openingUp: true,
    );
  }

  // こま編み裏引き上げ編み — X + 下の ∩（開口下向き）
  static void paintSingleCrochetBackPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final center = const Offset(0.5, 0.42);
    final size = geometry.metrics.crossSize * 0.9;
    geometry.drawX(canvas, contentRect, center: center, size: size);
    geometry.drawUHookUnderX(
      canvas,
      contentRect,
      center: center,
      crossSize: size,
      openingUp: false,
    );
  }

  // こま編み1、くさり1、こま編み1 — V + 楕円1
  static void paintSingleCrochetCh1SingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final halfWidth = 0.26;
    final height = 0.52;
    final bottom = Offset(0.5, 0.5 + height / 2 + 0.06);
    final topY = bottom.dy - height;
    geometry.drawV(
      canvas,
      contentRect,
      bottom: bottom,
      halfWidth: halfWidth,
      height: height,
    );
    geometry.drawOval(
      canvas,
      contentRect,
      center: Offset(0.5, topY + metrics.ovalHeight * 0.15),
      width: halfWidth * 2.05,
      height: metrics.ovalHeight * 0.85,
    );
  }

  // こま編み1、くさり2、こま編み1 — V + 楕円2（横並び）
  static void paintSingleCrochetCh2SingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final halfWidth = 0.28;
    final height = 0.52;
    final bottom = Offset(0.5, 0.5 + height / 2 + 0.06);
    final topY = bottom.dy - height;
    final ovalW = halfWidth * 0.95;
    final ovalH = metrics.ovalHeight * 0.8;
    final ovalY = topY + ovalH * 0.2;
    geometry.drawV(
      canvas,
      contentRect,
      bottom: bottom,
      halfWidth: halfWidth,
      height: height,
    );
    geometry.drawOval(
      canvas,
      contentRect,
      center: Offset(0.5 - ovalW * 0.55, ovalY),
      width: ovalW,
      height: ovalH,
    );
    geometry.drawOval(
      canvas,
      contentRect,
      center: Offset(0.5 + ovalW * 0.55, ovalY),
      width: ovalW,
      height: ovalH,
    );
  }

  // すじ編み — X + 下の水平線
  static void paintRibSingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final center = const Offset(0.5, 0.42);
    final size = metrics.crossSize * 0.9;
    geometry.drawX(canvas, contentRect, center: center, size: size);
    geometry.drawUnderBar(
      canvas,
      contentRect,
      center: Offset(0.5, center.dy + size * 0.55 + 0.04),
      width: size * 0.95,
    );
  }

  // バックこま編み — X + 上の波形
  static void paintReverseSingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final center = const Offset(0.5, 0.52);
    final size = metrics.crossSize * 0.9;
    geometry.drawWavyBar(
      canvas,
      contentRect,
      center: Offset(0.5, center.dy - size * 0.55 - 0.06),
      width: size * 0.95,
    );
    geometry.drawX(canvas, contentRect, center: center, size: size);
  }

  // ねじりこま編み — X + 上部の小ループ
  static void paintTwistedSingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final center = const Offset(0.5, 0.52);
    final size = metrics.crossSize * 0.88;
    geometry.drawX(canvas, contentRect, center: center, size: size);
    geometry.drawSmallLoop(
      canvas,
      contentRect,
      center: Offset(0.5, center.dy - size * 0.42),
      radius: metrics.smallLoopRadius * 1.15,
    );
  }

  // ピコット編み — V + 上部楕円 + 下端の塗りつぶし点
  static void paintPicot(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final halfWidth = 0.24;
    final height = 0.48;
    final bottom = Offset(0.5, 0.58);
    final topY = bottom.dy - height;
    geometry.drawV(
      canvas,
      contentRect,
      bottom: bottom,
      halfWidth: halfWidth,
      height: height,
    );
    geometry.drawOval(
      canvas,
      contentRect,
      center: Offset(0.5, topY + metrics.ovalHeight * 0.1),
      width: halfWidth * 1.9,
      height: metrics.ovalHeight * 0.8,
    );
    geometry.drawFilledOval(
      canvas,
      contentRect,
      center: Offset(0.5, bottom.dy + 0.06),
      width: 0.12,
      height: 0.12,
    );
  }

  // --- 中長編み系 ---

  // 中長編み3目の玉編み — アーモンド + 中央縦線 + 上横棒
  static void paintHalfDoubleCrochetCluster3(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final center = const Offset(0.5, 0.52);
    final stems = geometry.drawCluster(
      canvas,
      contentRect,
      center: center,
      stemCount: 3,
      width: 0.46,
      height: 0.62,
    );
    final top = stems.isNotEmpty
        ? Offset(0.5, stems.first.top.dy)
        : const Offset(0.5, 0.21);
    geometry.drawTopBar(canvas, contentRect, center: top);
  }

  // 中長編み表引き上げ編み — T + 下フック（開口左）
  static void paintHalfDoubleCrochetFrontPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    _paintTallPost(
      canvas,
      contentRect,
      geometry,
      yarnOverCount: 0,
      openLeft: true,
    );
  }

  // 中長編み裏引き上げ編み — T + 下フック（開口右）
  static void paintHalfDoubleCrochetBackPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    _paintTallPost(
      canvas,
      contentRect,
      geometry,
      yarnOverCount: 0,
      openLeft: false,
    );
  }

  // --- 長編み系 ---

  // 長編み交差 — 交差する2本の長編み
  static void paintCrossedDoubleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    const halfW = 0.26;
    const topY = 0.16;
    const bottomY = 0.88;
    final leftTop = const Offset(0.5 - halfW, topY);
    final rightTop = const Offset(0.5 + halfW, topY);
    final leftBottom = const Offset(0.5 - halfW, bottomY);
    final rightBottom = const Offset(0.5 + halfW, bottomY);

    // Cross: leftTop -> rightBottom, rightTop -> leftBottom
    geometry.drawStem(canvas, contentRect, from: leftTop, to: rightBottom);
    geometry.drawStem(canvas, contentRect, from: rightTop, to: leftBottom);
    geometry.drawTopBar(
      canvas,
      contentRect,
      center: leftTop,
      width: metrics.topBarWidth * 0.75,
    );
    geometry.drawTopBar(
      canvas,
      contentRect,
      center: rightTop,
      width: metrics.topBarWidth * 0.75,
    );
    Step2TFamilySymbols.paintYarnOverTicks(
      canvas,
      contentRect,
      geometry,
      stemTop: leftTop,
      stemBottom: rightBottom,
      count: 1,
      alongFromTop: 0.32,
      screenAligned: true,
      tickLength: 0.2,
    );
    Step2TFamilySymbols.paintYarnOverTicks(
      canvas,
      contentRect,
      geometry,
      stemTop: rightTop,
      stemBottom: leftBottom,
      count: 1,
      alongFromTop: 0.32,
      screenAligned: true,
      tickLength: 0.2,
    );
  }

  // 長編み3目の玉編み — アーモンド + 3線 + 上横棒 + 掛け目×3
  static void paintDoubleCrochetCluster3(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final center = const Offset(0.5, 0.52);
    final stems = geometry.drawCluster(
      canvas,
      contentRect,
      center: center,
      stemCount: 3,
      width: 0.5,
      height: 0.64,
    );
    geometry.drawTopBar(
      canvas,
      contentRect,
      center: Offset(0.5, stems.first.top.dy),
    );
    for (final stem in stems) {
      Step2TFamilySymbols.paintYarnOverTicks(
        canvas,
        contentRect,
        geometry,
        stemTop: stem.top,
        stemBottom: stem.bottom,
        count: 1,
        alongFromTop: 0.38,
        screenAligned: true,
        tickLength: 0.18,
      );
    }
  }

  // 長編み5目のポップコーン — 下尖り + 上楕円 + 5線 + 掛け目×5
  static void paintDoubleCrochetPopcorn5(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final center = const Offset(0.5, 0.54);
    const halfW = 0.34;
    const halfH = 0.34;
    final top = Offset(center.dx, center.dy - halfH);
    final bottom = Offset(center.dx, center.dy + halfH);
    final leftTop = Offset(center.dx - halfW * 0.85, top.dy);
    final rightTop = Offset(center.dx + halfW * 0.85, top.dy);

    // Outer cup via cluster outline without the closed top join look:
    // left curve + right curve meeting at bottom
    geometry.drawCluster(
      canvas,
      contentRect,
      center: center,
      stemCount: 5,
      width: halfW * 2,
      height: halfH * 2,
      drawOutline: true,
    );

    geometry.drawOval(
      canvas,
      contentRect,
      center: Offset(0.5, top.dy - metrics.ovalHeight * 0.12),
      width: halfW * 1.7,
      height: metrics.ovalHeight * 0.7,
    );

    // Ticks on five stems (cluster already drew stems)
    for (var i = 0; i < 5; i++) {
      final t = i / 4;
      final x = leftTop.dx + (rightTop.dx - leftTop.dx) * t;
      Step2TFamilySymbols.paintYarnOverTicks(
        canvas,
        contentRect,
        geometry,
        stemTop: Offset(x, top.dy),
        stemBottom: bottom,
        count: 1,
        alongFromTop: 0.4,
        screenAligned: true,
        tickLength: 0.16,
      );
    }
  }

  static void _paintTallPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry, {
    required int yarnOverCount,
    required bool openLeft,
  }) {
    final metrics = geometry.metrics;
    final topY = (1.0 - metrics.stemHeight) / 2 + 0.02;
    final bottomY = topY + metrics.stemHeight * 0.78;
    final top = Offset(0.5, topY);
    final bottom = Offset(0.5, bottomY);

    geometry.drawStem(canvas, contentRect, from: top, to: bottom);
    geometry.drawTopBar(canvas, contentRect, center: top);
    if (yarnOverCount > 0) {
      Step2TFamilySymbols.paintYarnOverTicks(
        canvas,
        contentRect,
        geometry,
        stemTop: top,
        stemBottom: bottom,
        count: yarnOverCount,
        alongFromTop: 0.42,
        screenAligned: true,
      );
    }
    geometry.drawHook(
      canvas,
      contentRect,
      anchor: bottom,
      openLeft: openLeft,
      radius: metrics.hookRadius * 1.05,
    );
  }
}
