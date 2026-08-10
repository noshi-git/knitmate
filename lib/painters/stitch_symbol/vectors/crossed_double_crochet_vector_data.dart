import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.27 長編み交差 — 公式トレース Path（正規化 0〜1）。
///
/// 背面ステム（左上→右下）は交点で隙間を空け、
/// 前面ステム（右上→左下）を連続線で重ねる。
/// 掛け目は左右とも同じ画面角度「\」。
class CrossedDoubleCrochetVectorData {
  CrossedDoubleCrochetVectorData._();

  static const Size viewBox = Size(1, 1);

  // Tips / bottoms（上が狭く下が広い）
  static const Offset leftTop = Offset(0.30, 0.08);
  static const Offset rightTop = Offset(0.70, 0.08);
  static const Offset leftBottom = Offset(0.12, 0.92);
  static const Offset rightBottom = Offset(0.88, 0.92);

  static List<StitchVectorLayer> get layers => [
        // 背面（隙間あり）→ 前面の順で描画
        StitchVectorLayer.stroke(() => backStem),
        StitchVectorLayer.stroke(() => frontStem),
        StitchVectorLayer.stroke(() => leftTopBar),
        StitchVectorLayer.stroke(() => rightTopBar),
        StitchVectorLayer.stroke(() => leftTick),
        StitchVectorLayer.stroke(() => rightTick),
      ];

  /// 背面: 左上 → 右下。交点付近で切断して前面を通す。
  static final Path backStem = Path()
    ..moveTo(leftTop.dx, leftTop.dy)
    ..lineTo(0.465, 0.32)
    ..moveTo(0.535, 0.42)
    ..lineTo(rightBottom.dx, rightBottom.dy);

  /// 前面: 右上 → 左下（連続）
  static final Path frontStem = Path()
    ..moveTo(rightTop.dx, rightTop.dy)
    ..lineTo(leftBottom.dx, leftBottom.dy);

  static final Path leftTopBar = Path()
    ..moveTo(0.20, leftTop.dy)
    ..lineTo(0.40, leftTop.dy);

  static final Path rightTopBar = Path()
    ..moveTo(0.60, rightTop.dy)
    ..lineTo(0.80, rightTop.dy);

  /// 掛け目（背面ステム上）— 「\」
  static final Path leftTick = Path()
    ..moveTo(0.35, 0.18)
    ..lineTo(0.46, 0.29);

  /// 掛け目（前面ステム上）— 同じ画面角度「\」
  static final Path rightTick = Path()
    ..moveTo(0.54, 0.18)
    ..lineTo(0.65, 0.29);
}
