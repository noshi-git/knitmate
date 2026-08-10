import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.24 中長編み3目の玉編み — 公式トレース Path（正規化 0〜1）。
///
/// 線幅は保持しない。描画時の共通 strokeWidth を使う。
class HalfDoubleCrochetCluster3VectorData {
  HalfDoubleCrochetCluster3VectorData._();

  static const Size viewBox = Size(1, 1);

  static List<StitchVectorLayer> get layers => [
        StitchVectorLayer.stroke(() => outline),
        StitchVectorLayer.stroke(() => centerStem),
        StitchVectorLayer.stroke(() => topBar),
      ];

  /// 外側アーモンド輪郭（左右対称・上下尖り）
  static final Path outline = Path()
    ..moveTo(0.50, 0.08)
    ..cubicTo(0.28, 0.20, 0.20, 0.36, 0.20, 0.50)
    ..cubicTo(0.20, 0.64, 0.28, 0.80, 0.50, 0.92)
    ..cubicTo(0.72, 0.80, 0.80, 0.64, 0.80, 0.50)
    ..cubicTo(0.80, 0.36, 0.72, 0.20, 0.50, 0.08)
    ..close();

  /// 中央縦線（上横棒中央〜下尖端）
  static final Path centerStem = Path()
    ..moveTo(0.50, 0.08)
    ..lineTo(0.50, 0.92);

  /// 上部横棒（アーモンド最大幅より広い）
  static final Path topBar = Path()
    ..moveTo(0.18, 0.08)
    ..lineTo(0.82, 0.08);
}
