import 'dart:math' as math;
import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.30 長編み表引き上げ編み — 公式トレース Path（正規化 0〜1）。
///
/// No.25（中長編み表引き上げ）の棒・フック構成を参考に、
/// 長編み用の掛け目1本（画面上「\」）を追加。
class DoubleCrochetFrontPostVectorData {
  DoubleCrochetFrontPostVectorData._();

  static const Size viewBox = Size(1, 1);

  // No.25 系: short top bar + stem + round hook (CW, open left)
  static const double _topY = 0.08;
  static const double _stemBottomY = 0.54;
  static const double _barHalf = 0.19; // barWidth 0.38
  static const double _hookRadius = 0.18;

  static List<StitchVectorLayer> get layers => [
        StitchVectorLayer.stroke(() => topBar),
        StitchVectorLayer.stroke(() => stem),
        StitchVectorLayer.stroke(() => tick),
        StitchVectorLayer.stroke(() => hook),
      ];

  static final Path topBar = Path()
    ..moveTo(0.5 - _barHalf, _topY)
    ..lineTo(0.5 + _barHalf, _topY);

  static final Path stem = Path()
    ..moveTo(0.5, _topY)
    ..lineTo(0.5, _stemBottomY);

  /// 掛け目×1 — 左上→右下「\」、ステム上半を横切る
  static final Path tick = Path()
    ..moveTo(0.38, 0.26)
    ..lineTo(0.62, 0.42);

  /// 下部フック: ステム下端（12時）から時計回り ≈261°、開口は左
  static final Path hook = () {
    final center = Offset(0.5, _stemBottomY + _hookRadius);
    final rect = Rect.fromCircle(center: center, radius: _hookRadius);
    return Path()..addArc(rect, -math.pi / 2, math.pi * 1.45);
  }();
}
