import 'dart:math' as math;

// 編み記号全体の寸法を一元管理する
class StitchSymbolMetrics {
  const StitchSymbolMetrics({
    required this.cellSize,
    required this.padding,
    required this.strokeWidth,
    required this.stemHeight,
    required this.topBarWidth,
    required this.tickLength,
    required this.tickSpacing,
    required this.tickAngle,
    required this.ovalWidth,
    required this.ovalHeight,
    required this.crossSize,
    required this.vHalfWidth,
    required this.vHeight,
    required this.vInc3HalfWidth,
    required this.vInc3Height,
    required this.hookRadius,
    required this.hookSweep,
    required this.clusterWidth,
    required this.clusterHeight,
    required this.fanSpreadAngle,
    required this.smallLoopRadius,
    required this.underBarWidth,
    required this.wavyAmplitude,
    required this.triangleSize,
  });

  final double cellSize;

  // セル全体
  final double padding;
  final double strokeWidth;

  // ステム系
  final double stemHeight;
  final double topBarWidth;

  // ティック（掛け目）
  final double tickLength;
  final double tickSpacing;
  final double tickAngle;

  // 楕円
  final double ovalWidth;
  final double ovalHeight;

  // X / V
  final double crossSize;
  /// SC inc2 / dec2 default V (interior ≈ 65°)
  final double vHalfWidth;
  final double vHeight;
  /// SC inc3 wider V (interior ≈ 90°)
  final double vInc3HalfWidth;
  final double vInc3Height;

  // フック
  final double hookRadius;
  final double hookSweep;

  // クラスタ / ファン
  final double clusterWidth;
  final double clusterHeight;
  final double fanSpreadAngle;

  // その他
  final double smallLoopRadius;
  final double underBarWidth;
  final double wavyAmplitude;
  final double triangleSize;

  // 描画に使える内側領域の一辺（padding 適用後）
  double get contentSize => math.max(0, cellSize * (1 - padding * 2));

  // セルサイズから寸法を算出する
  factory StitchSymbolMetrics.forCell(double cellSize) {
    final safeCell = cellSize <= 0 ? 1.0 : cellSize;
    return StitchSymbolMetrics(
      cellSize: safeCell,
      padding: 0.14,
      strokeWidth: math.max(1.0, safeCell * 0.06),
      stemHeight: 0.78,
      topBarWidth: 0.54,
      tickLength: 0.26,
      tickSpacing: 0.11,
      // "/" slant (top-left -> bottom-right) for yarn-over ticks
      tickAngle: math.pi / 4,
      ovalWidth: 0.62,
      ovalHeight: 0.28,
      crossSize: 0.56,
      // Official SC V / Λ interior ≈ 65° (2*atan(halfWidth/height))
      vHalfWidth: 0.385,
      vHeight: 0.605,
      // Official SC inc3 wider V ≈ 90°
      vInc3HalfWidth: 0.455,
      vInc3Height: 0.455,
      hookRadius: 0.16,
      hookSweep: math.pi,
      clusterWidth: 0.48,
      clusterHeight: 0.64,
      fanSpreadAngle: math.pi * 0.62,
      smallLoopRadius: 0.08,
      underBarWidth: 0.5,
      wavyAmplitude: 0.06,
      triangleSize: 0.46,
    );
  }
}
