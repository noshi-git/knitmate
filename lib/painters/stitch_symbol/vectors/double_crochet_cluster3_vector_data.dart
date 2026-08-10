import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.28 長編み3目の玉編み — 公式トレース Path（正規化 0〜1）。
///
/// No.24 のアーモンド輪郭・中央縦線をベースに、短い上横棒と掛け目×3を追加。
/// 掛け目は左右とも同じ画面角度「\」（左上→右下）。鏡像にしない。
class DoubleCrochetCluster3VectorData {
  DoubleCrochetCluster3VectorData._();

  static const Size viewBox = Size(1, 1);

  static List<StitchVectorLayer> get layers => [
        StitchVectorLayer.stroke(() => outline),
        StitchVectorLayer.stroke(() => centerStem),
        StitchVectorLayer.stroke(() => topBar),
        StitchVectorLayer.stroke(() => leftTick),
        StitchVectorLayer.stroke(() => centerTick),
        StitchVectorLayer.stroke(() => rightTick),
      ];

  /// 外側アーモンド輪郭（No.24 と同形・左右対称・上下尖り）
  static final Path outline = Path()
    ..moveTo(0.50, 0.08)
    ..cubicTo(0.28, 0.20, 0.20, 0.36, 0.20, 0.50)
    ..cubicTo(0.20, 0.64, 0.28, 0.80, 0.50, 0.92)
    ..cubicTo(0.72, 0.80, 0.80, 0.64, 0.80, 0.50)
    ..cubicTo(0.80, 0.36, 0.72, 0.20, 0.50, 0.08)
    ..close();

  /// 中央縦線（上尖端〜下尖端）
  static final Path centerStem = Path()
    ..moveTo(0.50, 0.08)
    ..lineTo(0.50, 0.92);

  /// 上部横棒（長編み用・アーモンド最大幅より短い）
  static final Path topBar = Path()
    ..moveTo(0.35, 0.08)
    ..lineTo(0.65, 0.08);

  // 掛け目×3: すべて同じ画面角度「\」、各線の中心を横切る
  static final Path leftTick = Path()
    ..moveTo(0.13, 0.43)
    ..lineTo(0.27, 0.57);

  static final Path centerTick = Path()
    ..moveTo(0.43, 0.43)
    ..lineTo(0.57, 0.57);

  static final Path rightTick = Path()
    ..moveTo(0.73, 0.43)
    ..lineTo(0.87, 0.57);
}
