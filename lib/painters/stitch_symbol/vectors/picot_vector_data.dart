import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.23 ピコット編み — 公式トレース Path（正規化 0〜1）。
///
/// 線幅は保持しない。描画時の共通 strokeWidth を使う。
class PicotVectorData {
  PicotVectorData._();

  static const Size viewBox = Size(1, 1);

  static List<StitchVectorLayer> get layers => [
        StitchVectorLayer.stroke(() => topOval),
        StitchVectorLayer.stroke(() => leftPetal),
        StitchVectorLayer.stroke(() => rightPetal),
        StitchVectorLayer.fill(() => bottomDot),
      ];

  /// ① 上部横長楕円 — 公式: 幅広くやや扁平、やや上寄せ
  static final Path topOval = Path()
    ..addOval(
      Rect.fromCenter(
        center: const Offset(0.50, 0.12),
        width: 0.80,
        height: 0.18,
      ),
    );

  /// ② 左ループ — 楕円下端の外側寄りから接続、縦長・内傾、下端は丸く離す
  static final Path leftPetal = Path()
    ..moveTo(0.20, 0.20)
    ..cubicTo(0.12, 0.30, 0.11, 0.48, 0.18, 0.66)
    ..cubicTo(0.22, 0.76, 0.30, 0.80, 0.36, 0.76)
    ..cubicTo(0.42, 0.70, 0.40, 0.48, 0.34, 0.30)
    ..cubicTo(0.31, 0.22, 0.26, 0.19, 0.20, 0.20)
    ..close();

  /// ② 右ループ — 左右対称
  static final Path rightPetal = Path()
    ..moveTo(0.80, 0.20)
    ..cubicTo(0.88, 0.30, 0.89, 0.48, 0.82, 0.66)
    ..cubicTo(0.78, 0.76, 0.70, 0.80, 0.64, 0.76)
    ..cubicTo(0.58, 0.70, 0.60, 0.48, 0.66, 0.30)
    ..cubicTo(0.69, 0.22, 0.74, 0.19, 0.80, 0.20)
    ..close();

  /// ③ 下黒丸 — 小さめ、ループ下端(≈0.80)から明確な隙間
  static final Path bottomDot = Path()
    ..addOval(
      Rect.fromCenter(
        center: const Offset(0.50, 0.93),
        width: 0.09,
        height: 0.09,
      ),
    );
}
