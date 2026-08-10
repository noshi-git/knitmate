import 'dart:math' as math;
import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.32 — 添付公式画像のベクタートレース（正規化 0〜1）。
class RingStitchVectorData {
  RingStitchVectorData._();

  static const Size viewBox = Size(1, 1);

  static List<StitchVectorLayer> get layers => [
        StitchVectorLayer.stroke(() => outerStroke),
        StitchVectorLayer.stroke(() => innerStrokeA),
        StitchVectorLayer.stroke(() => innerStrokeB),
      ];

  /// 外枠 — 左縦線 → 下弧 → 右縦線（画像上で1本の連続線）
  static final Path outerStroke = () {
    const leftX = 0.11;
    const rightX = 0.89;
    const topY = 0.02;
    const joinY = 0.57;
    const radius = (rightX - leftX) / 2;
    final arcRect = Rect.fromCircle(
      center: const Offset(0.5, joinY),
      radius: radius,
    );
    return Path()
      ..moveTo(leftX, topY)
      ..lineTo(leftX, joinY)
      ..arcTo(arcRect, math.pi, math.pi, false)
      ..lineTo(rightX, topY);
  }();

  /// 内側斜線 A — 左上 → 右下
  static final Path innerStrokeA = Path()
    ..moveTo(0.26, 0.14)
    ..lineTo(0.74, 0.48);

  /// 内側斜線 B — 右上 → 左下
  static final Path innerStrokeB = Path()
    ..moveTo(0.74, 0.14)
    ..lineTo(0.26, 0.48);
}
