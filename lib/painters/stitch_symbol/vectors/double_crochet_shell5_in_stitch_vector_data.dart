import 'dart:math' as math;
import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.33 長編み5目を前段の1目に編み入れる — 公式トレース Path（正規化 0〜1）。
///
/// 扇の tip 座標は公式画像をトレース（均等角の機械扇にしない）。
/// 掛け目はすべて同じ画面角度「\」（左上→右下）。鏡像にしない。
class DoubleCrochetShell5InStitchVectorData {
  DoubleCrochetShell5InStitchVectorData._();

  static const Size viewBox = Size(1, 1);

  /// 5本の合流点
  static const Offset apex = Offset(0.50, 0.66);

  // tip: 外側ほどやや低く、中央が高い弧。左右対称。
  // 角度（垂直から）≈ 51° / 24° / 0° / 24° / 51°、長さは中央がやや長い。
  static const Offset tip0 = Offset(0.10, 0.34);
  static const Offset tip1 = Offset(0.28, 0.16);
  static const Offset tip2 = Offset(0.50, 0.08);
  static const Offset tip3 = Offset(0.72, 0.16);
  static const Offset tip4 = Offset(0.90, 0.34);

  static List<StitchVectorLayer> get layers => [
        StitchVectorLayer.stroke(() => stems),
        StitchVectorLayer.stroke(() => topBars),
        StitchVectorLayer.stroke(() => ticks),
        StitchVectorLayer.stroke(() => bottomX),
      ];

  static final Path stems = Path()
    ..moveTo(tip0.dx, tip0.dy)
    ..lineTo(apex.dx, apex.dy)
    ..moveTo(tip1.dx, tip1.dy)
    ..lineTo(apex.dx, apex.dy)
    ..moveTo(tip2.dx, tip2.dy)
    ..lineTo(apex.dx, apex.dy)
    ..moveTo(tip3.dx, tip3.dy)
    ..lineTo(apex.dx, apex.dy)
    ..moveTo(tip4.dx, tip4.dy)
    ..lineTo(apex.dx, apex.dy);

  /// 各ステムに垂直な短い上端横棒
  static final Path topBars = () {
    final path = Path();
    for (final tip in [tip0, tip1, tip2, tip3, tip4]) {
      path.addPath(_topBar(tip), Offset.zero);
    }
    return path;
  }();

  /// 掛け目×5 — すべて「\」
  static final Path ticks = () {
    final path = Path();
    for (final tip in [tip0, tip1, tip2, tip3, tip4]) {
      path.addPath(_tick(tip), Offset.zero);
    }
    return path;
  }();

  /// 下部の X（扇の合流点の下に隙間を空けて配置）
  static final Path bottomX = Path()
    ..moveTo(0.42, 0.78)
    ..lineTo(0.58, 0.94)
    ..moveTo(0.58, 0.78)
    ..lineTo(0.42, 0.94);

  static Path _topBar(Offset tip) {
    const half = 0.066;
    final dx = tip.dx - apex.dx;
    final dy = tip.dy - apex.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final ux = dx / len;
    final uy = dy / len;
    // ステムに垂直
    final px = -uy * half;
    final py = ux * half;
    return Path()
      ..moveTo(tip.dx - px, tip.dy - py)
      ..lineTo(tip.dx + px, tip.dy + py);
  }

  static Path _tick(Offset tip) {
    const half = 0.052;
    const alongFromTop = 0.42;
    final mid = Offset(
      tip.dx + (apex.dx - tip.dx) * alongFromTop,
      tip.dy + (apex.dy - tip.dy) * alongFromTop,
    );
    // 画面上の「\」（左上→右下）。ステム角度に依存させない。
    return Path()
      ..moveTo(mid.dx - half, mid.dy - half)
      ..lineTo(mid.dx + half, mid.dy + half);
  }
}
