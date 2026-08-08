import 'dart:math' as math;
import 'dart:ui';

import '../stitch_symbol_geometry.dart';
import '../stitch_symbol_metrics.dart';

// Step2: T系（中長 / 長 / 長々）の描画
// Step3 の増減でも同じベース・掛け目を再利用する
class Step2TFamilySymbols {
  Step2TFamilySymbols._();

  /// 中長編みベース（縦線 + 上横棒）。[top]/[bottom] は正規化座標。
  static void paintHalfDoubleBase(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry, {
    Offset? top,
    Offset? bottom,
  }) {
    final metrics = geometry.metrics;
    final ends = _stemEnds(metrics, top: top, bottom: bottom);

    geometry.drawStem(
      canvas,
      contentRect,
      from: ends.top,
      to: ends.bottom,
    );
    geometry.drawTopBar(
      canvas,
      contentRect,
      center: ends.top,
    );
  }

  /// ステム中央（正規化）。増減の脚にも使える。
  static Offset stemMidpoint(
    StitchSymbolMetrics metrics, {
    Offset? top,
    Offset? bottom,
  }) {
    final ends = _stemEnds(metrics, top: top, bottom: bottom);
    return Offset(
      (ends.top.dx + ends.bottom.dx) / 2,
      (ends.top.dy + ends.bottom.dy) / 2,
    );
  }

  /// 掛け目をステム上に描く（0=なし, 1=長編み, 2=長々編みの間隔規則）
  /// [alongFromTop] はステム上端からの位置（0=上端, 1=下端）。既定 0.5。
  /// [screenAligned] が true のとき、脚の傾きに回転させず画面上の「／」方向を維持する。
  static void paintYarnOverTicks(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry, {
    required Offset stemTop,
    required Offset stemBottom,
    required int count,
    double alongFromTop = 0.5,
    bool screenAligned = false,
    double? tickLength,
    Offset anchorOffset = Offset.zero,
  }) {
    if (count <= 0) {
      return;
    }

    final metrics = geometry.metrics;
    final length = tickLength ?? metrics.tickLength;
    final t = alongFromTop.clamp(0.0, 1.0);
    final anchor = Offset(
          stemTop.dx + (stemBottom.dx - stemTop.dx) * t,
          stemTop.dy + (stemBottom.dy - stemTop.dy) * t,
        ) +
        anchorOffset;

    void drawOne(Offset center) {
      if (screenAligned) {
        geometry.drawScreenAlignedTick(
          canvas,
          contentRect,
          center: center,
          length: length,
        );
      } else {
        geometry.drawSingleTick(canvas, contentRect, center: center);
      }
    }

    if (count == 1) {
      drawOne(anchor);
      return;
    }

    final delta = stemBottom - stemTop;
    final distance = delta.distance;
    if (distance <= 1e-6) {
      return;
    }

    // Keep Step2 treble spacing: abut upper tick bottom-right with lower tick top-left
    final unit = Offset(delta.dx / distance, delta.dy / distance);
    final halfTick = length / 2;
    final verticalHalf = halfTick * math.sin(metrics.tickAngle).abs();
    final centerSpacing = verticalHalf * 2;
    final half = unit * (centerSpacing / 2);

    drawOne(anchor - half);
    drawOne(anchor + half);
  }

  // 中長編み — T
  static void paintHalfDoubleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    paintHalfDoubleBase(canvas, contentRect, geometry);
  }

  // 長編み — T + 掛け目1
  static void paintDoubleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final ends = _stemEnds(metrics);
    paintHalfDoubleBase(canvas, contentRect, geometry);
    paintYarnOverTicks(
      canvas,
      contentRect,
      geometry,
      stemTop: ends.top,
      stemBottom: ends.bottom,
      count: 1,
    );
  }

  // 長々編み — T + 掛け目2
  static void paintTrebleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final ends = _stemEnds(metrics);
    paintHalfDoubleBase(canvas, contentRect, geometry);
    paintYarnOverTicks(
      canvas,
      contentRect,
      geometry,
      stemTop: ends.top,
      stemBottom: ends.bottom,
      count: 2,
    );
  }

  static ({Offset top, Offset bottom}) _stemEnds(
    StitchSymbolMetrics metrics, {
    Offset? top,
    Offset? bottom,
  }) {
    if (top != null && bottom != null) {
      return (top: top, bottom: bottom);
    }

    final stemHeight = metrics.stemHeight;
    final topY = (1.0 - stemHeight) / 2;
    final bottomY = topY + stemHeight;
    return (
      top: Offset(0.5, topY),
      bottom: Offset(0.5, bottomY),
    );
  }
}
