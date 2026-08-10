import 'dart:math' as math;
import 'dart:ui';

import '../stitch_symbol_geometry.dart';
import '../vectors/crossed_double_crochet_vector_data.dart';
import '../vectors/double_crochet_cluster3_vector_data.dart';
import '../vectors/double_crochet_popcorn5_vector_data.dart';
import '../vectors/half_double_crochet_cluster3_vector_data.dart';
import '../vectors/picot_vector_data.dart';
import '../vectors/stitch_vector_painter.dart';
import 'step2_t_family_symbols.dart';

// Step4: 特殊記号（引き上げ・すじ・玉・交差・ポップコーンなど）
class Step4SpecialSymbols {
  Step4SpecialSymbols._();

  // --- こま編み系 ---

  // こま編み表引き上げ編み — X + 右脚から垂直に降り左へ曲がる J
  static void paintSingleCrochetFrontPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final center = const Offset(0.5, 0.36);
    final size = metrics.crossSize * 0.88;
    final half = size / 2;

    geometry.drawX(canvas, contentRect, center: center, size: size);

    // Official: attach at X bottom-right tip → straight down → leftward J curve
    final attach = Offset(center.dx + half, center.dy + half);
    final stemEnd = Offset(attach.dx, attach.dy + half * 1.05);
    final radius = half * 0.95;

    final attachPx = geometry.mapPoint(contentRect, attach);
    final stemEndPx = geometry.mapPoint(contentRect, stemEnd);
    final rPx = geometry.mapLength(contentRect, radius);
    final arcCenterPx = Offset(stemEndPx.dx - rPx, stemEndPx.dy);

    final paint = geometry.style.strokePaint
      ..strokeWidth = metrics.strokeWidth;
    final path = Path()
      ..moveTo(attachPx.dx, attachPx.dy)
      ..lineTo(stemEndPx.dx, stemEndPx.dy)
      // Clockwise from east through south to west (+ slight up)
      ..arcTo(
        Rect.fromCircle(center: arcCenterPx, radius: rPx),
        0,
        math.pi * 1.08,
        false,
      );
    canvas.drawPath(path, paint);
  }

  // こま編み裏引き上げ編み — No.16 の左右鏡像（左脚から垂直に降り右へ曲がる）
  static void paintSingleCrochetBackPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final center = const Offset(0.5, 0.36);
    final size = metrics.crossSize * 0.88;
    final half = size / 2;

    geometry.drawX(canvas, contentRect, center: center, size: size);

    // Mirror of front post: attach at X bottom-left tip → straight down → rightward curve
    final attach = Offset(center.dx - half, center.dy + half);
    final stemEnd = Offset(attach.dx, attach.dy + half * 1.05);
    final radius = half * 0.95;

    final attachPx = geometry.mapPoint(contentRect, attach);
    final stemEndPx = geometry.mapPoint(contentRect, stemEnd);
    final rPx = geometry.mapLength(contentRect, radius);
    final arcCenterPx = Offset(stemEndPx.dx + rPx, stemEndPx.dy);

    final paint = geometry.style.strokePaint
      ..strokeWidth = metrics.strokeWidth;
    final path = Path()
      ..moveTo(attachPx.dx, attachPx.dy)
      ..lineTo(stemEndPx.dx, stemEndPx.dy)
      // Counter-clockwise from west through south to east (+ slight up)
      ..arcTo(
        Rect.fromCircle(center: arcCenterPx, radius: rPx),
        math.pi,
        -math.pi * 1.08,
        false,
      );
    canvas.drawPath(path, paint);
  }

  // こま編み1、くさり1、こま編み1 — 上段楕円 + 下段V（入れ子にしない）
  static void paintSingleCrochetCh1SingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    // Official: oval above V with gap; deeper V (shared stroke width)
    const ovalWidth = 0.62;
    const ovalHeight = 0.16;
    const halfWidth = 0.36;
    const vHeight = 0.62;
    const gap = 0.14;

    final ovalCenter = Offset(0.5, 0.11 + ovalHeight / 2);
    final ovalBottom = ovalCenter.dy + ovalHeight / 2;
    final vTopY = ovalBottom + gap;
    final bottom = Offset(0.5, math.min(0.96, vTopY + vHeight));

    geometry.drawOval(
      canvas,
      contentRect,
      center: ovalCenter,
      width: ovalWidth,
      height: ovalHeight,
    );
    geometry.drawV(
      canvas,
      contentRect,
      bottom: bottom,
      halfWidth: halfWidth,
      height: bottom.dy - vTopY,
    );
  }

  // こま編み1、くさり2、こま編み1 — 中央一点で接する傾斜楕円2つ + 下段V
  static void paintSingleCrochetCh2SingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    // Official sheet: tilted ovals touch at top-center; V matches No.18 angle
    const halfWidth = 0.36; // same as No.18
    const vHeight = 0.55; // same effective depth ratio as No.18
    const ovalW = 0.44;
    const ovalH = 0.17;
    const gap = 0.13;
    // Left: 左下→右上 (/). Right: 左上→右下 (\).
    const tilt = 0.50;

    const contact = Offset(0.5, 0.09);
    final along = ovalW * 0.49;
    final leftCenter = Offset(
      contact.dx - math.cos(tilt) * along,
      contact.dy + math.sin(tilt) * along,
    );
    final rightCenter = Offset(
      contact.dx + math.cos(tilt) * along,
      contact.dy + math.sin(tilt) * along,
    );
    // Outer/lower tips of the pair sit below the contact
    final ovalBottomY = contact.dy + 2 * math.sin(tilt) * along;
    final vTopY = ovalBottomY + gap;
    final bottom = Offset(0.5, math.min(0.96, vTopY + vHeight));

    _drawTiltedOval(
      canvas,
      contentRect,
      geometry,
      center: leftCenter,
      width: ovalW,
      height: ovalH,
      rotation: -tilt,
    );
    _drawTiltedOval(
      canvas,
      contentRect,
      geometry,
      center: rightCenter,
      width: ovalW,
      height: ovalH,
      rotation: tilt,
    );
    geometry.drawV(
      canvas,
      contentRect,
      bottom: bottom,
      halfWidth: halfWidth,
      height: bottom.dy - vTopY,
    );
  }

  static void _drawTiltedOval(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry, {
    required Offset center,
    required double width,
    required double height,
    required double rotation,
  }) {
    final origin = geometry.mapPoint(contentRect, center);
    final w = geometry.mapLength(contentRect, width);
    final h = geometry.mapLength(contentRect, height);
    final paint = geometry.style.strokePaint
      ..strokeWidth = geometry.metrics.strokeWidth;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(rotation);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      paint,
    );
    canvas.restore();
  }

  // すじ編み — X + 下の水平線
  static void paintRibSingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final center = const Offset(0.5, 0.42);
    final size = metrics.crossSize * 0.9;
    geometry.drawX(canvas, contentRect, center: center, size: size);
    // Official: shorter bar, clear gap below X tips (X unchanged)
    geometry.drawUnderBar(
      canvas,
      contentRect,
      center: Offset(0.5, center.dy + size * 0.5 + 0.12),
      width: size * 0.62,
    );
  }

  // バックこま編み — X + 上の自然な「~」
  static void paintReverseSingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final center = const Offset(0.5, 0.52);
    final size = metrics.crossSize * 0.9;
    // Official: asymmetric tilde above X with a clear gap (X unchanged)
    _drawReverseCrochetTilde(
      canvas,
      contentRect,
      geometry,
      center: Offset(0.5, center.dy - size * 0.5 - 0.14),
      width: size * 1.08,
      amplitude: size * 0.14,
    );
    geometry.drawX(canvas, contentRect, center: center, size: size);
  }

  /// Natural "~" for No.21 only (not a symmetric arch).
  static void _drawReverseCrochetTilde(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry, {
    required Offset center,
    required double width,
    required double amplitude,
  }) {
    final left = center.dx - width / 2;
    final right = center.dx + width / 2;
    final y = center.dy;
    final amp = amplitude;

    Offset p(double nx, double ny) =>
        geometry.mapPoint(contentRect, Offset(nx, ny));

    // Left rises, crosses down through center, right lifts slightly (official ~)
    final path = Path()
      ..moveTo(p(left, y + amp * 0.15).dx, p(left, y + amp * 0.15).dy)
      ..cubicTo(
        p(left + width * 0.18, y - amp * 1.15).dx,
        p(left + width * 0.18, y - amp * 1.15).dy,
        p(left + width * 0.32, y - amp * 1.05).dx,
        p(left + width * 0.32, y - amp * 1.05).dy,
        p(center.dx - width * 0.02, y + amp * 0.25).dx,
        p(center.dx - width * 0.02, y + amp * 0.25).dy,
      )
      ..cubicTo(
        p(center.dx + width * 0.18, y + amp * 1.2).dx,
        p(center.dx + width * 0.18, y + amp * 1.2).dy,
        p(right - width * 0.18, y + amp * 0.85).dx,
        p(right - width * 0.18, y + amp * 0.85).dy,
        p(right, y - amp * 0.25).dx,
        p(right, y - amp * 0.25).dy,
      );

    final paint = geometry.style.strokePaint
      ..strokeWidth = geometry.metrics.strokeWidth;
    canvas.drawPath(path, paint);
  }

  // ねじりこま編み — No.22専用Painter（縦長の閉じた輪 + 左右腕 + 余白 + X）
  static void paintTwistedSingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    final paint = geometry.style.strokePaint
      ..strokeWidth = metrics.strokeWidth;

    Offset p(double nx, double ny) =>
        geometry.mapPoint(contentRect, Offset(nx, ny));

    // ① 縦長の閉じた輪（楕円）— Y / Ω / 桃形にしない
    const ringCenter = Offset(0.5, 0.18);
    const ringW = 0.16;
    const ringH = 0.28;
    final ringRect = Rect.fromCenter(
      center: p(ringCenter.dx, ringCenter.dy),
      width: geometry.mapLength(contentRect, ringW),
      height: geometry.mapLength(contentRect, ringH),
    );
    canvas.drawOval(ringRect, paint);

    // ② 輪の最下点から左右へ短い腕（わずかに上へ開く）
    final contact = Offset(0.5, ringCenter.dy + ringH / 2); // 0.32
    const armLen = 0.13;
    const armLift = 0.035;
    final arms = Path()
      ..moveTo(p(contact.dx - armLen, contact.dy - armLift).dx,
          p(contact.dx - armLen, contact.dy - armLift).dy)
      ..quadraticBezierTo(
        p(contact.dx - armLen * 0.45, contact.dy + armLift * 0.35).dx,
        p(contact.dx - armLen * 0.45, contact.dy + armLift * 0.35).dy,
        p(contact.dx, contact.dy).dx,
        p(contact.dx, contact.dy).dy,
      )
      ..quadraticBezierTo(
        p(contact.dx + armLen * 0.45, contact.dy + armLift * 0.35).dx,
        p(contact.dx + armLen * 0.45, contact.dy + armLift * 0.35).dy,
        p(contact.dx + armLen, contact.dy - armLift).dx,
        p(contact.dx + armLen, contact.dy - armLift).dy,
      );
    canvas.drawPath(arms, paint);

    // ③ 余白 ④ X
    final xCenter = const Offset(0.5, 0.70);
    final xSize = metrics.crossSize * 0.88;
    geometry.drawX(canvas, contentRect, center: xCenter, size: xSize);
  }

  // ピコット編み — No.23専用（トレース済み Vector Path 試作）
  static void paintPicot(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    // Tech validation: static Path data (not PNG, not runtime tracing).
    // Existing Geometry pipeline remains for all other symbols.
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: PicotVectorData.viewBox,
      layers: PicotVectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }

  // --- 中長編み系 ---

  // 中長編み3目の玉編み — No.24 Path（アーモンド + 中央縦線 + 上横棒）
  static void paintHalfDoubleCrochetCluster3(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: HalfDoubleCrochetCluster3VectorData.viewBox,
      layers: HalfDoubleCrochetCluster3VectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }

  // 中長編み表引き上げ編み — No.25専用（Geometry部品のみ・共有TallPostは使わない）
  static void paintHalfDoubleCrochetFrontPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    // Official: short top bar, long stem, round hook (CW from 12 → open left)
    const topY = 0.10;
    const stemBottomY = 0.54;
    const barWidth = 0.40;
    const hookRadius = 0.17; // ≈ half of top-bar width

    final top = const Offset(0.5, topY);
    final stemBottom = const Offset(0.5, stemBottomY);

    geometry.drawTopBar(
      canvas,
      contentRect,
      center: top,
      width: barWidth,
    );
    geometry.drawStem(
      canvas,
      contentRect,
      from: top,
      to: stemBottom,
    );

    // Hook center directly below stem tip so attachment is at 12 o'clock.
    // Sweep clockwise: right → bottom → left (~9 o'clock), opening to the left.
    final hookCenter = Offset(0.5, stemBottomY + hookRadius);
    final paint = geometry.style.strokePaint
      ..strokeWidth = metrics.strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(
        center: geometry.mapPoint(contentRect, hookCenter),
        radius: geometry.mapLength(contentRect, hookRadius),
      ),
      -math.pi / 2,
      math.pi * 1.45,
      false,
      paint,
    );
  }

  // 中長編み裏引き上げ編み — No.26専用（No.25の左右反転）
  static void paintHalfDoubleCrochetBackPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    final metrics = geometry.metrics;
    // Mirror of No.25: same stem/bar/radius; hook opens to the right
    const topY = 0.10;
    const stemBottomY = 0.54;
    const barWidth = 0.40;
    const hookRadius = 0.17;

    final top = const Offset(0.5, topY);
    final stemBottom = const Offset(0.5, stemBottomY);

    geometry.drawTopBar(
      canvas,
      contentRect,
      center: top,
      width: barWidth,
    );
    geometry.drawStem(
      canvas,
      contentRect,
      from: top,
      to: stemBottom,
    );

    // Attachment at 12 o'clock; CCW: left → bottom → right (~3 o'clock), open right
    final hookCenter = Offset(0.5, stemBottomY + hookRadius);
    final paint = geometry.style.strokePaint
      ..strokeWidth = metrics.strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(
        center: geometry.mapPoint(contentRect, hookCenter),
        radius: geometry.mapLength(contentRect, hookRadius),
      ),
      -math.pi / 2,
      -math.pi * 1.45,
      false,
      paint,
    );
  }

  // --- 長編み系 ---

  // 長編み交差 — No.27 Path（2本交差・背面に隙間・掛け目×2）
  static void paintCrossedDoubleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: CrossedDoubleCrochetVectorData.viewBox,
      layers: CrossedDoubleCrochetVectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }

  // 長編み3目の玉編み — No.28 Path（No.24輪郭ベース + 短い上横棒 + 掛け目×3）
  static void paintDoubleCrochetCluster3(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: DoubleCrochetCluster3VectorData.viewBox,
      layers: DoubleCrochetCluster3VectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }

  // 長編み5目のポップコーン — No.29 Path（上楕円 + 5脚 + 掛け目×5）
  static void paintDoubleCrochetPopcorn5(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: DoubleCrochetPopcorn5VectorData.viewBox,
      layers: DoubleCrochetPopcorn5VectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }

  static void _paintTallPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry, {
    required int yarnOverCount,
    required bool openLeft,
  }) {
    final metrics = geometry.metrics;
    final topY = (1.0 - metrics.stemHeight) / 2 + 0.02;
    final bottomY = topY + metrics.stemHeight * 0.78;
    final top = Offset(0.5, topY);
    final bottom = Offset(0.5, bottomY);

    geometry.drawStem(canvas, contentRect, from: top, to: bottom);
    geometry.drawTopBar(canvas, contentRect, center: top);
    if (yarnOverCount > 0) {
      Step2TFamilySymbols.paintYarnOverTicks(
        canvas,
        contentRect,
        geometry,
        stemTop: top,
        stemBottom: bottom,
        count: yarnOverCount,
        alongFromTop: 0.42,
        screenAligned: true,
      );
    }
    geometry.drawHook(
      canvas,
      contentRect,
      anchor: bottom,
      openLeft: openLeft,
      radius: metrics.hookRadius * 1.05,
    );
  }
}
