import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.29 長編み5目のポップコーン編み — 公式トレース Path（正規化 0〜1）。
///
/// No.28 の掛け目角度・共通 stroke 方針を踏襲。
/// 差分: 上部は横棒ではなく楕円、脚は5本（外側曲線が輪郭）、掛け目×5。
/// 掛け目はすべて同じ画面角度「\」（左上→右下）。鏡像にしない。
class DoubleCrochetPopcorn5VectorData {
  DoubleCrochetPopcorn5VectorData._();

  static const Size viewBox = Size(1, 1);

  static const double _topY = 0.18;
  static const double _bottomY = 0.94;
  static const double _tickY = 0.48;
  static const double _tickHalf = 0.06;

  static List<StitchVectorLayer> get layers => [
        StitchVectorLayer.stroke(() => leftOuter),
        StitchVectorLayer.stroke(() => leftInner),
        StitchVectorLayer.stroke(() => centerStem),
        StitchVectorLayer.stroke(() => rightInner),
        StitchVectorLayer.stroke(() => rightOuter),
        StitchVectorLayer.stroke(() => topOval),
        StitchVectorLayer.stroke(() => tick0),
        StitchVectorLayer.stroke(() => tick1),
        StitchVectorLayer.stroke(() => tick2),
        StitchVectorLayer.stroke(() => tick3),
        StitchVectorLayer.stroke(() => tick4),
      ];

  /// ポップコーン上部の横長楕円
  static final Path topOval = Path()
    ..addOval(
      Rect.fromCenter(
        center: const Offset(0.50, 0.10),
        width: 0.54,
        height: 0.16,
      ),
    );

  /// 外側左脚（膨らみ・下端合流）
  static final Path leftOuter = Path()
    ..moveTo(0.24, _topY)
    ..cubicTo(0.08, 0.38, 0.14, 0.70, 0.50, _bottomY);

  /// 内側左脚
  static final Path leftInner = Path()
    ..moveTo(0.37, _topY)
    ..cubicTo(0.28, 0.40, 0.36, 0.70, 0.50, _bottomY);

  /// 中央縦線
  static final Path centerStem = Path()
    ..moveTo(0.50, _topY)
    ..lineTo(0.50, _bottomY);

  /// 内側右脚
  static final Path rightInner = Path()
    ..moveTo(0.63, _topY)
    ..cubicTo(0.72, 0.40, 0.64, 0.70, 0.50, _bottomY);

  /// 外側右脚（膨らみ・下端合流）
  static final Path rightOuter = Path()
    ..moveTo(0.76, _topY)
    ..cubicTo(0.92, 0.38, 0.86, 0.70, 0.50, _bottomY);

  // 掛け目×5: すべて「\」。各脚の中腹を横切る。
  // 脚の x 位置（y≈0.48）: ≈0.18, 0.34, 0.50, 0.66, 0.82
  static final Path tick0 = _tickAt(0.18);
  static final Path tick1 = _tickAt(0.34);
  static final Path tick2 = _tickAt(0.50);
  static final Path tick3 = _tickAt(0.66);
  static final Path tick4 = _tickAt(0.82);

  static Path _tickAt(double cx) {
    return Path()
      ..moveTo(cx - _tickHalf, _tickY - _tickHalf)
      ..lineTo(cx + _tickHalf, _tickY + _tickHalf);
  }
}
