import 'dart:math' as math;
import 'dart:ui';

import 'stitch_symbol_metrics.dart';
import 'stitch_symbol_style.dart';

// Metrics を参照して編み記号の部品を描画する
class StitchSymbolGeometry {
  StitchSymbolGeometry({
    required this.metrics,
    required this.style,
  });

  final StitchSymbolMetrics metrics;
  final StitchSymbolStyle style;

  Paint get _stroke {
    return style.strokePaint..strokeWidth = metrics.strokeWidth;
  }

  Paint get _fill => style.fillPaint;

  // 正規化座標 (0,0)-(1,1) を contentRect 上の実座標へ変換する
  Offset mapPoint(Rect contentRect, Offset normalized) {
    return Offset(
      contentRect.left + normalized.dx * contentRect.width,
      contentRect.top + normalized.dy * contentRect.height,
    );
  }

  double mapX(Rect contentRect, double normalizedX) {
    return contentRect.left + normalizedX * contentRect.width;
  }

  double mapY(Rect contentRect, double normalizedY) {
    return contentRect.top + normalizedY * contentRect.height;
  }

  double mapLength(Rect contentRect, double normalized) {
    return normalized * contentRect.shortestSide;
  }

  void drawStem(
    Canvas canvas,
    Rect contentRect, {
    required Offset from,
    required Offset to,
  }) {
    canvas.drawLine(
      mapPoint(contentRect, from),
      mapPoint(contentRect, to),
      _stroke,
    );
  }

  void drawTopBar(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? width,
  }) {
    final barWidth = width ?? metrics.topBarWidth;
    final half = barWidth / 2;
    canvas.drawLine(
      mapPoint(contentRect, Offset(center.dx - half, center.dy)),
      mapPoint(contentRect, Offset(center.dx + half, center.dy)),
      _stroke,
    );
  }

  void drawSingleTick(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
  }) {
    _drawTickAt(canvas, contentRect, center);
  }

  void drawDoubleTick(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
  }) {
    final halfSpacing = metrics.tickSpacing / 2;
    final direction = Offset(
      math.cos(metrics.tickAngle + math.pi / 2),
      math.sin(metrics.tickAngle + math.pi / 2),
    );
    _drawTickAt(
      canvas,
      contentRect,
      center + direction * halfSpacing,
    );
    _drawTickAt(
      canvas,
      contentRect,
      center - direction * halfSpacing,
    );
  }

  /// Screen-fixed "/" tick. Does not rotate with a slanted stem/leg.
  void drawScreenAlignedTick(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? length,
  }) {
    final halfPx = mapLength(contentRect, length ?? metrics.tickLength) / 2;
    final origin = mapPoint(contentRect, center);
    final dx = math.cos(metrics.tickAngle) * halfPx;
    final dy = math.sin(metrics.tickAngle) * halfPx;
    canvas.drawLine(
      Offset(origin.dx - dx, origin.dy - dy),
      Offset(origin.dx + dx, origin.dy + dy),
      _stroke,
    );
  }

  void _drawTickAt(Canvas canvas, Rect contentRect, Offset center) {
    final half = metrics.tickLength / 2;
    final dx = math.cos(metrics.tickAngle) * half;
    final dy = math.sin(metrics.tickAngle) * half;
    canvas.drawLine(
      mapPoint(contentRect, Offset(center.dx - dx, center.dy - dy)),
      mapPoint(contentRect, Offset(center.dx + dx, center.dy + dy)),
      _stroke,
    );
  }

  void drawOval(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? width,
    double? height,
  }) {
    final w = width ?? metrics.ovalWidth;
    final h = height ?? metrics.ovalHeight;
    final rect = Rect.fromCenter(
      center: mapPoint(contentRect, center),
      width: mapLength(contentRect, w),
      height: mapLength(contentRect, h),
    );
    canvas.drawOval(rect, _stroke);
  }

  void drawFilledOval(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? width,
    double? height,
  }) {
    final w = width ?? metrics.ovalWidth;
    final h = height ?? metrics.ovalHeight;
    final rect = Rect.fromCenter(
      center: mapPoint(contentRect, center),
      width: mapLength(contentRect, w),
      height: mapLength(contentRect, h),
    );
    canvas.drawOval(rect, _fill);
  }

  /// Stem-end post hook. [openLeft] true = front-post style (opening left).
  void drawHook(
    Canvas canvas,
    Rect contentRect, {
    required Offset anchor,
    bool openLeft = true,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    double rotation = 0,
    double? radius,
  }) {
    _withTransform(
      canvas,
      contentRect,
      anchor: anchor,
      mirrorHorizontal: mirrorHorizontal,
      mirrorVertical: mirrorVertical,
      rotation: rotation,
      draw: () {
        final r = mapLength(contentRect, radius ?? metrics.hookRadius);
        final origin = mapPoint(contentRect, anchor);
        final center = Offset(origin.dx, origin.dy + r * 0.15);
        final rect = Rect.fromCircle(center: center, radius: r);
        // From stem attachment (-pi/2) through bottom to open side
        final sweep = openLeft ? -metrics.hookSweep : metrics.hookSweep;
        canvas.drawArc(rect, -math.pi / 2, sweep, false, _stroke);
      },
    );
  }

  /// U / ∩ hook connecting the bottom legs of an X (single-crochet posts).
  void drawUHookUnderX(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? crossSize,
    required bool openingUp,
  }) {
    final size = crossSize ?? metrics.crossSize;
    final half = size / 2;
    final left = Offset(center.dx - half * 0.72, center.dy + half * 0.55);
    final right = Offset(center.dx + half * 0.72, center.dy + half * 0.55);
    final depth = metrics.hookRadius * (openingUp ? 1.15 : 0.95);
    final controlY = openingUp
        ? center.dy + half * 0.55 + depth
        : center.dy + half * 0.55 - depth * 0.35;
    final path = Path()
      ..moveTo(mapPoint(contentRect, left).dx, mapPoint(contentRect, left).dy)
      ..quadraticBezierTo(
        mapPoint(contentRect, Offset(center.dx, controlY)).dx,
        mapPoint(contentRect, Offset(center.dx, controlY)).dy,
        mapPoint(contentRect, right).dx,
        mapPoint(contentRect, right).dy,
      );
    canvas.drawPath(path, _stroke);
  }

  void drawUnderBar(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? width,
  }) {
    final barWidth = width ?? metrics.underBarWidth;
    final half = barWidth / 2;
    canvas.drawLine(
      mapPoint(contentRect, Offset(center.dx - half, center.dy)),
      mapPoint(contentRect, Offset(center.dx + half, center.dy)),
      _stroke,
    );
  }

  void drawWavyBar(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? width,
    double? amplitude,
  }) {
    final barWidth = width ?? metrics.underBarWidth;
    final amp = amplitude ?? metrics.wavyAmplitude;
    final left = center.dx - barWidth / 2;
    final right = center.dx + barWidth / 2;
    final y = center.dy;
    // Single wave: left-low, mid-high, right-low (~)
    final wave = Path()
      ..moveTo(
        mapPoint(contentRect, Offset(left, y + amp * 0.3)).dx,
        mapPoint(contentRect, Offset(left, y + amp * 0.3)).dy,
      )
      ..quadraticBezierTo(
        mapPoint(contentRect, Offset(center.dx, y - amp)).dx,
        mapPoint(contentRect, Offset(center.dx, y - amp)).dy,
        mapPoint(contentRect, Offset(right, y + amp * 0.3)).dx,
        mapPoint(contentRect, Offset(right, y + amp * 0.3)).dy,
      );
    canvas.drawPath(wave, _stroke);
  }

  void drawSmallLoop(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? radius,
  }) {
    final r = mapLength(contentRect, radius ?? metrics.smallLoopRadius);
    final origin = mapPoint(contentRect, center);
    canvas.drawCircle(origin, r, _stroke);
  }

  void drawX(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? size,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    double rotation = 0,
  }) {
    final crossSize = size ?? metrics.crossSize;
    final half = crossSize / 2;

    _withTransform(
      canvas,
      contentRect,
      anchor: center,
      mirrorHorizontal: mirrorHorizontal,
      mirrorVertical: mirrorVertical,
      rotation: rotation,
      draw: () {
        canvas.drawLine(
          mapPoint(contentRect, Offset(center.dx - half, center.dy - half)),
          mapPoint(contentRect, Offset(center.dx + half, center.dy + half)),
          _stroke,
        );
        canvas.drawLine(
          mapPoint(contentRect, Offset(center.dx + half, center.dy - half)),
          mapPoint(contentRect, Offset(center.dx - half, center.dy + half)),
          _stroke,
        );
      },
    );
  }

  void drawV(
    Canvas canvas,
    Rect contentRect, {
    required Offset bottom,
    double? halfWidth,
    double? height,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    double rotation = 0,
  }) {
    final hw = halfWidth ?? metrics.vHalfWidth;
    final h = height ?? metrics.vHeight;

    _withTransform(
      canvas,
      contentRect,
      anchor: bottom,
      mirrorHorizontal: mirrorHorizontal,
      mirrorVertical: mirrorVertical,
      rotation: rotation,
      draw: () {
        final topY = bottom.dy - h;
        canvas.drawLine(
          mapPoint(contentRect, Offset(bottom.dx - hw, topY)),
          mapPoint(contentRect, bottom),
          _stroke,
        );
        canvas.drawLine(
          mapPoint(contentRect, Offset(bottom.dx + hw, topY)),
          mapPoint(contentRect, bottom),
          _stroke,
        );
      },
    );
  }

  void drawInverseV(
    Canvas canvas,
    Rect contentRect, {
    required Offset top,
    double? halfWidth,
    double? height,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    double rotation = 0,
  }) {
    final hw = halfWidth ?? metrics.vHalfWidth;
    final h = height ?? metrics.vHeight;

    _withTransform(
      canvas,
      contentRect,
      anchor: top,
      mirrorHorizontal: mirrorHorizontal,
      mirrorVertical: mirrorVertical,
      rotation: rotation,
      draw: () {
        final bottomY = top.dy + h;
        canvas.drawLine(
          mapPoint(contentRect, top),
          mapPoint(contentRect, Offset(top.dx - hw, bottomY)),
          _stroke,
        );
        canvas.drawLine(
          mapPoint(contentRect, top),
          mapPoint(contentRect, Offset(top.dx + hw, bottomY)),
          _stroke,
        );
      },
    );
  }

  /// Almond/cluster outline + internal stems meeting at top and bottom.
  /// Returns stem top/bottom pairs in normalized coords for tick placement.
  List<({Offset top, Offset bottom})> drawCluster(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    int stemCount = 3,
    double? width,
    double? height,
    bool drawOutline = true,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    double rotation = 0,
  }) {
    final halfW = (width ?? metrics.clusterWidth) / 2;
    final halfH = (height ?? metrics.clusterHeight) / 2;
    final top = Offset(center.dx, center.dy - halfH);
    final bottom = Offset(center.dx, center.dy + halfH);
    final count = math.max(1, stemCount);
    final stems = <({Offset top, Offset bottom})>[];

    _withTransform(
      canvas,
      contentRect,
      anchor: center,
      mirrorHorizontal: mirrorHorizontal,
      mirrorVertical: mirrorVertical,
      rotation: rotation,
      draw: () {
        if (drawOutline) {
          final path = Path()
            ..moveTo(
              mapPoint(contentRect, top).dx,
              mapPoint(contentRect, top).dy,
            )
            ..quadraticBezierTo(
              mapPoint(contentRect, Offset(center.dx - halfW, center.dy)).dx,
              mapPoint(contentRect, Offset(center.dx - halfW, center.dy)).dy,
              mapPoint(contentRect, bottom).dx,
              mapPoint(contentRect, bottom).dy,
            )
            ..quadraticBezierTo(
              mapPoint(contentRect, Offset(center.dx + halfW, center.dy)).dx,
              mapPoint(contentRect, Offset(center.dx + halfW, center.dy)).dy,
              mapPoint(contentRect, top).dx,
              mapPoint(contentRect, top).dy,
            );
          canvas.drawPath(path, _stroke);
        }

        for (var i = 0; i < count; i++) {
          final t = count == 1 ? 0.5 : i / (count - 1);
          final x = center.dx - halfW * 0.72 + halfW * 1.44 * t;
          final stemTop = Offset(x, top.dy);
          final stemBottom = bottom;
          drawStem(canvas, contentRect, from: stemTop, to: stemBottom);
          stems.add((top: stemTop, bottom: stemBottom));
        }
      },
    );

    return stems;
  }

  /// Fan of stems from [origin] upward. Returns outer/inner ends (normalized).
  List<({Offset top, Offset bottom})> drawFan(
    Canvas canvas,
    Rect contentRect, {
    required Offset origin,
    required int spokeCount,
    double? radius,
    double? spreadAngle,
    double? topBarWidth,
    bool drawTopBars = true,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    double rotation = 0,
  }) {
    final count = math.max(1, spokeCount);
    final spread = spreadAngle ?? metrics.fanSpreadAngle;
    final length = radius ?? metrics.stemHeight * 0.72;
    final barW = topBarWidth ?? metrics.topBarWidth * 0.38;
    final stems = <({Offset top, Offset bottom})>[];

    _withTransform(
      canvas,
      contentRect,
      anchor: origin,
      mirrorHorizontal: mirrorHorizontal,
      mirrorVertical: mirrorVertical,
      rotation: rotation,
      draw: () {
        final start = -spread / 2;
        for (var i = 0; i < count; i++) {
          final t = count == 1 ? 0.5 : i / (count - 1);
          // 0 = straight up; fans left/right symmetrically
          final angle = start + spread * t - math.pi / 2;
          final end = Offset(
            origin.dx + math.cos(angle) * length,
            origin.dy + math.sin(angle) * length,
          );
          drawStem(canvas, contentRect, from: origin, to: end);
          if (drawTopBars) {
            // Top bar perpendicular to the spoke (T tip)
            final barAngle = angle + math.pi / 2;
            final half = barW / 2;
            canvas.drawLine(
              mapPoint(
                contentRect,
                Offset(
                  end.dx - math.cos(barAngle) * half,
                  end.dy - math.sin(barAngle) * half,
                ),
              ),
              mapPoint(
                contentRect,
                Offset(
                  end.dx + math.cos(barAngle) * half,
                  end.dy + math.sin(barAngle) * half,
                ),
              ),
              _stroke,
            );
          }
          stems.add((top: end, bottom: origin));
        }
      },
    );

    return stems;
  }

  /// Smooth U / ∩ curve. [openingUp] true = ∪ (open at top).
  void drawUCurve(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? width,
    double? height,
    bool openingUp = true,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    double rotation = 0,
  }) {
    final w = width ?? metrics.clusterWidth;
    final h = height ?? metrics.clusterHeight * 0.85;

    _withTransform(
      canvas,
      contentRect,
      anchor: center,
      mirrorHorizontal: mirrorHorizontal,
      mirrorVertical: mirrorVertical,
      rotation: rotation,
      draw: () {
        final left = Offset(center.dx - w / 2, center.dy - h / 2);
        final right = Offset(center.dx + w / 2, center.dy - h / 2);
        final bottom = Offset(center.dx, center.dy + h / 2);
        final top = Offset(center.dx, center.dy - h / 2);
        final path = Path();
        if (openingUp) {
          path
            ..moveTo(mapPoint(contentRect, left).dx, mapPoint(contentRect, left).dy)
            ..quadraticBezierTo(
              mapPoint(contentRect, bottom).dx,
              mapPoint(contentRect, bottom).dy,
              mapPoint(contentRect, right).dx,
              mapPoint(contentRect, right).dy,
            );
        } else {
          path
            ..moveTo(
              mapPoint(contentRect, Offset(left.dx, center.dy + h / 2)).dx,
              mapPoint(contentRect, Offset(left.dx, center.dy + h / 2)).dy,
            )
            ..quadraticBezierTo(
              mapPoint(contentRect, top).dx,
              mapPoint(contentRect, top).dy,
              mapPoint(contentRect, Offset(right.dx, center.dy + h / 2)).dx,
              mapPoint(contentRect, Offset(right.dx, center.dy + h / 2)).dy,
            );
        }
        canvas.drawPath(path, _stroke);
      },
    );
  }

  /// Right triangle used for attach/cut yarn. Tip points bottom-left.
  void drawTriangle(
    Canvas canvas,
    Rect contentRect, {
    required Offset center,
    double? size,
    bool filled = false,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    double rotation = 0,
  }) {
    final s = size ?? metrics.triangleSize;

    _withTransform(
      canvas,
      contentRect,
      anchor: center,
      mirrorHorizontal: mirrorHorizontal,
      mirrorVertical: mirrorVertical,
      rotation: rotation,
      draw: () {
        // Tip bottom-left; hypotenuse top-left → bottom-right (公式画像準拠)
        final tip = Offset(center.dx - s * 0.48, center.dy + s * 0.38);
        final top = Offset(center.dx - s * 0.18, center.dy - s * 0.48);
        final right = Offset(center.dx + s * 0.48, center.dy + s * 0.28);
        final path = Path()
          ..moveTo(mapPoint(contentRect, tip).dx, mapPoint(contentRect, tip).dy)
          ..lineTo(mapPoint(contentRect, top).dx, mapPoint(contentRect, top).dy)
          ..lineTo(
            mapPoint(contentRect, right).dx,
            mapPoint(contentRect, right).dy,
          )
          ..close();
        canvas.drawPath(path, filled ? _fill : _stroke);
      },
    );
  }

  void _withTransform(
    Canvas canvas,
    Rect contentRect, {
    required Offset anchor,
    required bool mirrorHorizontal,
    required bool mirrorVertical,
    required double rotation,
    required void Function() draw,
  }) {
    if (!mirrorHorizontal && !mirrorVertical && rotation == 0) {
      draw();
      return;
    }

    final pivot = mapPoint(contentRect, anchor);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    if (rotation != 0) {
      canvas.rotate(rotation);
    }
    canvas.scale(
      mirrorHorizontal ? -1.0 : 1.0,
      mirrorVertical ? -1.0 : 1.0,
    );
    canvas.translate(-pivot.dx, -pivot.dy);
    draw();
    canvas.restore();
  }
}
