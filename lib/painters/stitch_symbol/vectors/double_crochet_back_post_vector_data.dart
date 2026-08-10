import 'dart:math' as math;
import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.31 長編み裏引き上げ編み — 公式トレース Path（正規化 0〜1）。
///
/// No.30 と同形の棒・掛け目。差分は下部フックのみ（反時計回り、開口右）。
class DoubleCrochetBackPostVectorData {
  DoubleCrochetBackPostVectorData._();

  static const Size viewBox = Size(1, 1);

  // No.30 と同じステム／横棒／掛け目／半径
  static const double _topY = 0.08;
  static const double _stemBottomY = 0.54;
  static const double _barHalf = 0.19;
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

  /// 掛け目×1 — No.30 と同じ画面上「\」
  static final Path tick = Path()
    ..moveTo(0.38, 0.26)
    ..lineTo(0.62, 0.42);

  /// 下部フック: ステム下端（12時）から反時計回り ≈261°、開口は右
  static final Path hook = () {
    final center = Offset(0.5, _stemBottomY + _hookRadius);
    final rect = Rect.fromCircle(center: center, radius: _hookRadius);
    return Path()..addArc(rect, -math.pi / 2, -math.pi * 1.45);
  }();
}
