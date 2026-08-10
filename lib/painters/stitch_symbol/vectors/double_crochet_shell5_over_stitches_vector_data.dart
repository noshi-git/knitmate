import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'stitch_vector_painter.dart';

/// No.34 前段の目を束にすくって長編み5目編む — 公式トレース Path（正規化 0〜1）。
///
/// 上部扇は固定。下部は No.19 完成形を複製して下配置。
/// 八の字と V は別 Path（別 drawPath）。接続しない。
class DoubleCrochetShell5OverStitchesVectorData {
  DoubleCrochetShell5OverStitchesVectorData._();

  static const Size viewBox = Size(1, 1);

  /// 5本の収束付近（下部 No.19 直上）
  static const Offset apex = Offset(0.50, 0.62);

  // tip: 上部は固定（変更禁止）
  static const Offset tip0 = Offset(0.12, 0.30);
  static const Offset tip1 = Offset(0.29, 0.14);
  static const Offset tip2 = Offset(0.50, 0.08);
  static const Offset tip3 = Offset(0.71, 0.14);
  static const Offset tip4 = Offset(0.88, 0.30);

  // --- No.19 完成形パラメータ（そのままコピー） ---
  static const double _n19OvalW = 0.44;
  static const double _n19OvalH = 0.17;
  static const double _n19Tilt = 0.50;
  static const double _n19Gap = 0.13;
  static const double _n19HalfWidth = 0.36;
  static const double _n19VHeight = 0.55;
  static const Offset _n19Contact = Offset(0.50, 0.09);
  static const double _n19BottomY = 0.96;

  /// No.19 全体を扇の下へ収める配置（均一スケール）
  static const double _placeContactY = 0.68;
  static const double _placeBottomY = 0.985;
  static final double _placeScale =
      (_placeBottomY - _placeContactY) / (_n19BottomY - _n19Contact.dy);

  static List<StitchVectorLayer> get layers => [
        StitchVectorLayer.stroke(() => stems),
        StitchVectorLayer.stroke(() => topBars),
        StitchVectorLayer.stroke(() => ticks),
        // Path A: 八の字（左右楕円を別 drawPath）
        StitchVectorLayer.stroke(() => no19LeftOval),
        StitchVectorLayer.stroke(() => no19RightOval),
        // Path B: V（左右脚を別 drawPath。八の字とは接続しない）
        StitchVectorLayer.stroke(() => no19VLeft),
        StitchVectorLayer.stroke(() => no19VRight),
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

  static final Path topBars = () {
    final path = Path();
    for (final tip in [tip0, tip1, tip2, tip3, tip4]) {
      path.addPath(_topBar(tip), Offset.zero);
    }
    return path;
  }();

  static final Path ticks = () {
    final path = Path();
    for (final tip in [tip0, tip1, tip2, tip3, tip4]) {
      path.addPath(_tick(tip), Offset.zero);
    }
    return path;
  }();

  // --- No.19 ネイティブ座標 → No.34 下部配置 ---

  static Offset _mapNo19(Offset p) {
    return Offset(
      0.5 + (p.dx - 0.5) * _placeScale,
      _placeContactY + (p.dy - _n19Contact.dy) * _placeScale,
    );
  }

  static final double _n19Along = _n19OvalW * 0.49;

  static final Offset _n19LeftCenter = Offset(
    _n19Contact.dx - math.cos(_n19Tilt) * _n19Along,
    _n19Contact.dy + math.sin(_n19Tilt) * _n19Along,
  );

  static final Offset _n19RightCenter = Offset(
    _n19Contact.dx + math.cos(_n19Tilt) * _n19Along,
    _n19Contact.dy + math.sin(_n19Tilt) * _n19Along,
  );

  static final double _n19OvalBottomY =
      _n19Contact.dy + 2 * math.sin(_n19Tilt) * _n19Along;

  static final double _n19VTopY = _n19OvalBottomY + _n19Gap;

  static final Offset _n19VBottom = Offset(
    0.5,
    math.min(_n19BottomY, _n19VTopY + _n19VHeight),
  );

  /// Path A-left: No.19 左傾斜楕円
  static final Path no19LeftOval = _tiltedOval(
    _mapNo19(_n19LeftCenter),
    _n19OvalW * _placeScale,
    _n19OvalH * _placeScale,
    -_n19Tilt,
  );

  /// Path A-right: No.19 右傾斜楕円
  static final Path no19RightOval = _tiltedOval(
    _mapNo19(_n19RightCenter),
    _n19OvalW * _placeScale,
    _n19OvalH * _placeScale,
    _n19Tilt,
  );

  /// Path B-left: No.19 V 左脚（単独 Path）
  static final Path no19VLeft = () {
    final top = _mapNo19(Offset(_n19VBottom.dx - _n19HalfWidth, _n19VTopY));
    final bottom = _mapNo19(_n19VBottom);
    return Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(bottom.dx, bottom.dy);
  }();

  /// Path B-right: No.19 V 右脚（単独 Path）
  static final Path no19VRight = () {
    final top = _mapNo19(Offset(_n19VBottom.dx + _n19HalfWidth, _n19VTopY));
    final bottom = _mapNo19(_n19VBottom);
    return Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(bottom.dx, bottom.dy);
  }();

  static Path _tiltedOval(
    Offset center,
    double width,
    double height,
    double rotation,
  ) {
    final local = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: width,
          height: height,
        ),
      );
    final c = math.cos(rotation);
    final s = math.sin(rotation);
    final matrix = Float64List.fromList(<double>[
      c, s, 0, 0,
      -s, c, 0, 0,
      0, 0, 1, 0,
      center.dx, center.dy, 0, 1,
    ]);
    return local.transform(matrix);
  }

  static Path _topBar(Offset tip) {
    const half = 0.066;
    final dx = tip.dx - apex.dx;
    final dy = tip.dy - apex.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final ux = dx / len;
    final uy = dy / len;
    final px = -uy * half;
    final py = ux * half;
    return Path()
      ..moveTo(tip.dx - px, tip.dy - py)
      ..lineTo(tip.dx + px, tip.dy + py);
  }

  static Path _tick(Offset tip) {
    const half = 0.052;
    const alongFromTop = 0.40;
    final mid = Offset(
      tip.dx + (apex.dx - tip.dx) * alongFromTop,
      tip.dy + (apex.dy - tip.dy) * alongFromTop,
    );
    return Path()
      ..moveTo(mid.dx - half, mid.dy - half)
      ..lineTo(mid.dx + half, mid.dy + half);
  }
}
