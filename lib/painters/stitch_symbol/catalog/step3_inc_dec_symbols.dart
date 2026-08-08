import 'dart:ui';

import '../stitch_symbol_geometry.dart';
import 'step2_t_family_symbols.dart';

/// Per-symbol V / Λ proportions (normalized). Avoids one global V size.
class _IncDecVSpec {
  const _IncDecVSpec({
    required this.halfWidth,
    required this.height,
    this.tickLength,
    this.tickAlongFromTop = 0.45,
    this.tickOutward = 0,
  });

  final double halfWidth;
  final double height;
  final double? tickLength;
  final double tickAlongFromTop;

  /// Shift yarn-over ticks outward from the leg (normalized).
  final double tickOutward;
}

// Step3: 増減記号の描画
class Step3IncDecSymbols {
  Step3IncDecSymbols._();

  // Official comparison ratios (content-normalized)
  // SC opening widened ~8% from the previous fine pass
  static const _scV = _IncDecVSpec(halfWidth: 0.181, height: 0.62);
  static const _hdcIncV = _IncDecVSpec(halfWidth: 0.195, height: 0.70);
  // Keep the OK decrease look from the comparison sheet
  static const _hdcDecV = _IncDecVSpec(halfWidth: 0.22, height: 0.74);
  static const _dcV = _IncDecVSpec(
    halfWidth: 0.185,
    height: 0.74,
    tickLength: 0.20,
    tickAlongFromTop: 0.44,
    tickOutward: 0.038,
  );
  static const _trV = _IncDecVSpec(
    halfWidth: 0.185,
    height: 0.76,
    tickLength: 0.20,
    tickAlongFromTop: 0.44,
    tickOutward: 0.038,
  );

  // --- こま編み ---

  static void paintSingleCrochetInc2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final bottom = Offset(0.5, 0.5 + _scV.height / 2);
    geometry.drawV(
      canvas,
      contentRect,
      bottom: bottom,
      halfWidth: _scV.halfWidth,
      height: _scV.height,
    );
  }

  static void paintSingleCrochetInc3(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final halfWidth = _scV.halfWidth;
    final height = _scV.height;
    final bottom = Offset(0.5, 0.5 + height / 2);
    final topY = bottom.dy - height;
    // Official: X sits near the top opening; short stem from X center to V tip
    final xSize = metrics.crossSize * 0.36;
    final xCenter = Offset(0.5, topY + xSize * 0.42);

    geometry.drawV(
      canvas,
      contentRect,
      bottom: bottom,
      halfWidth: halfWidth,
      height: height,
    );
    geometry.drawStem(
      canvas,
      contentRect,
      from: xCenter,
      to: bottom,
    );
    geometry.drawX(
      canvas,
      contentRect,
      center: xCenter,
      size: xSize,
    );
  }

  static void paintSingleCrochetDec2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final top = Offset(0.5, 0.5 - _scV.height / 2);
    geometry.drawInverseV(
      canvas,
      contentRect,
      top: top,
      halfWidth: _scV.halfWidth,
      height: _scV.height,
    );
  }

  // --- T系 増減 ---

  // Separate top bars with a center gap (official)
  static void paintHalfDoubleCrochetInc2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    _paintTallInc2(
      canvas,
      contentRect,
      geometry,
      spec: _hdcIncV,
      yarnOverCount: 0,
      spanTopBar: false,
    );
  }

  // Comparison sheet: OK — do not alter proportions/structure
  static void paintHalfDoubleCrochetDec2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    _paintTallDec2(
      canvas,
      contentRect,
      geometry,
      spec: _hdcDecV,
      yarnOverCount: 0,
      screenAlignedTicks: false,
    );
  }

  static void paintDoubleCrochetInc2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    _paintTallInc2(
      canvas,
      contentRect,
      geometry,
      spec: _dcV,
      yarnOverCount: 1,
      spanTopBar: false,
    );
  }

  static void paintDoubleCrochetDec2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    _paintTallDec2(
      canvas,
      contentRect,
      geometry,
      spec: _dcV,
      yarnOverCount: 1,
      screenAlignedTicks: true,
    );
  }

  static void paintTrebleCrochetInc2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    _paintTallInc2(
      canvas,
      contentRect,
      geometry,
      spec: _trV,
      yarnOverCount: 2,
      spanTopBar: false,
    );
  }

  static void paintTrebleCrochetDec2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    _paintTallDec2(
      canvas,
      contentRect,
      geometry,
      spec: _trV,
      yarnOverCount: 2,
      screenAlignedTicks: true,
    );
  }

  static void _paintTallInc2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry, {
    required _IncDecVSpec spec,
    required int yarnOverCount,
    required bool spanTopBar,
  }) {
    final metrics = geometry.metrics;
    final halfWidth = spec.halfWidth;
    final height = spec.height;
    final bottom = Offset(0.5, 0.5 + height / 2);
    final topY = bottom.dy - height;
    final leftTop = Offset(bottom.dx - halfWidth, topY);
    final rightTop = Offset(bottom.dx + halfWidth, topY);
    final legBarWidth = metrics.topBarWidth * 0.78;

    geometry.drawV(
      canvas,
      contentRect,
      bottom: bottom,
      halfWidth: halfWidth,
      height: height,
    );

    if (spanTopBar) {
      geometry.drawTopBar(
        canvas,
        contentRect,
        center: Offset(0.5, topY),
        width: halfWidth * 2,
      );
    } else {
      // Independent top bars with a visible center gap
      geometry.drawTopBar(
        canvas,
        contentRect,
        center: leftTop,
        width: legBarWidth,
      );
      geometry.drawTopBar(
        canvas,
        contentRect,
        center: rightTop,
        width: legBarWidth,
      );
    }

    if (yarnOverCount > 0) {
      Step2TFamilySymbols.paintYarnOverTicks(
        canvas,
        contentRect,
        geometry,
        stemTop: leftTop,
        stemBottom: bottom,
        count: yarnOverCount,
        alongFromTop: spec.tickAlongFromTop,
        screenAligned: true,
        tickLength: spec.tickLength,
        anchorOffset: _outwardShift(leftTop, bottom, spec.tickOutward),
      );
      Step2TFamilySymbols.paintYarnOverTicks(
        canvas,
        contentRect,
        geometry,
        stemTop: rightTop,
        stemBottom: bottom,
        count: yarnOverCount,
        alongFromTop: spec.tickAlongFromTop,
        screenAligned: true,
        tickLength: spec.tickLength,
        anchorOffset: _outwardShift(rightTop, bottom, spec.tickOutward),
      );
    }
  }

  static void _paintTallDec2(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry, {
    required _IncDecVSpec spec,
    required int yarnOverCount,
    required bool screenAlignedTicks,
  }) {
    final metrics = geometry.metrics;
    final halfWidth = spec.halfWidth;
    final height = spec.height;
    final top = Offset(0.5, 0.5 - height / 2);
    final bottomY = top.dy + height;
    final leftBottom = Offset(top.dx - halfWidth, bottomY);
    final rightBottom = Offset(top.dx + halfWidth, bottomY);

    geometry.drawInverseV(
      canvas,
      contentRect,
      top: top,
      halfWidth: halfWidth,
      height: height,
    );
    // Shared single top bar at the joined apex
    geometry.drawTopBar(
      canvas,
      contentRect,
      center: top,
      width: metrics.topBarWidth,
    );

    if (yarnOverCount > 0) {
      Step2TFamilySymbols.paintYarnOverTicks(
        canvas,
        contentRect,
        geometry,
        stemTop: top,
        stemBottom: leftBottom,
        count: yarnOverCount,
        alongFromTop: spec.tickAlongFromTop,
        screenAligned: screenAlignedTicks,
        tickLength: spec.tickLength,
        anchorOffset: _outwardShift(top, leftBottom, spec.tickOutward),
      );
      Step2TFamilySymbols.paintYarnOverTicks(
        canvas,
        contentRect,
        geometry,
        stemTop: top,
        stemBottom: rightBottom,
        count: yarnOverCount,
        alongFromTop: spec.tickAlongFromTop,
        screenAligned: screenAlignedTicks,
        tickLength: spec.tickLength,
        anchorOffset: _outwardShift(top, rightBottom, spec.tickOutward),
      );
    }
  }

  /// Unit normal pointing away from symbol center, scaled by [amount].
  static Offset _outwardShift(Offset stemTop, Offset stemBottom, double amount) {
    if (amount == 0) {
      return Offset.zero;
    }
    final delta = stemBottom - stemTop;
    final length = delta.distance;
    if (length <= 1e-6) {
      return Offset.zero;
    }

    var nx = -delta.dy / length;
    var ny = delta.dx / length;
    final mid = Offset(
      (stemTop.dx + stemBottom.dx) / 2,
      (stemTop.dy + stemBottom.dy) / 2,
    );
    final toCenter = Offset(0.5 - mid.dx, 0.5 - mid.dy);
    if (nx * toCenter.dx + ny * toCenter.dy > 0) {
      nx = -nx;
      ny = -ny;
    }
    return Offset(nx * amount, ny * amount);
  }
}
