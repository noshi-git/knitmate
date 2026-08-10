import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.12 長編み2目編み入れる — 公式トレース Path（正規化 0〜1）。
///
/// 掛け目は左右とも同じ画面角度「\」（左上→右下）。鏡像にしない。
class DoubleCrochetInc2VectorData {
  DoubleCrochetInc2VectorData._();

  static const Size viewBox = Size(1, 1);

  static List<StitchVectorLayer> get layers => [
        StitchVectorLayer.stroke(() => vLegs),
        StitchVectorLayer.stroke(() => leftTopBar),
        StitchVectorLayer.stroke(() => rightTopBar),
        StitchVectorLayer.stroke(() => leftTick),
        StitchVectorLayer.stroke(() => rightTick),
      ];

  // V: tips → single bottom point
  static final Path vLegs = Path()
    ..moveTo(0.26, 0.10)
    ..lineTo(0.50, 0.90)
    ..moveTo(0.74, 0.10)
    ..lineTo(0.50, 0.90);

  // Independent short horizontal bars (gap in the center)
  static final Path leftTopBar = Path()
    ..moveTo(0.14, 0.10)
    ..lineTo(0.38, 0.10);

  static final Path rightTopBar = Path()
    ..moveTo(0.62, 0.10)
    ..lineTo(0.86, 0.10);

  // Both ticks: top-left → bottom-right (\), centered on each leg midsection
  static final Path leftTick = Path()
    ..moveTo(0.29, 0.37)
    ..lineTo(0.43, 0.51);

  // Same screen angle as leftTick — not mirrored
  static final Path rightTick = Path()
    ..moveTo(0.57, 0.37)
    ..lineTo(0.71, 0.51);
}
