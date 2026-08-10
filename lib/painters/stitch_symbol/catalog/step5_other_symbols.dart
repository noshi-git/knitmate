import 'dart:ui';

import '../stitch_symbol_geometry.dart';
import '../vectors/double_crochet_back_post_vector_data.dart';
import '../vectors/double_crochet_front_post_vector_data.dart';
import '../vectors/double_crochet_shell5_in_stitch_vector_data.dart';
import '../vectors/double_crochet_shell5_over_stitches_vector_data.dart';
import '../vectors/ring_stitch_vector_data.dart';
import '../vectors/stitch_vector_painter.dart';

// Step5: リング / シェル / 糸処理（＋長編み引き上げで公式36種を完了）
class Step5OtherSymbols {
  Step5OtherSymbols._();

  // リング編み — No.32 Path（上部 X + 下部 U、別 Path）
  static void paintRingStitch(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: RingStitchVectorData.viewBox,
      layers: RingStitchVectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }

  // 長編み5目を前段の1目に編み入れる — No.33 Path（扇5本 + 掛け目 + 下 X）
  static void paintDoubleCrochetShell5InStitch(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: DoubleCrochetShell5InStitchVectorData.viewBox,
      layers: DoubleCrochetShell5InStitchVectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }

  // 前段の目を束にすくって長編み5目編む — No.34 Path（扇5本 + 下楕円 + V）
  static void paintDoubleCrochetShell5OverStitches(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: DoubleCrochetShell5OverStitchesVectorData.viewBox,
      layers: DoubleCrochetShell5OverStitchesVectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }

  // 糸をつける — 中空三角形（先端は左下）
  static void paintAttachYarn(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    geometry.drawTriangle(
      canvas,
      contentRect,
      center: const Offset(0.5, 0.5),
      filled: false,
    );
  }

  // 糸を切る — 塗りつぶし三角形（同形）
  static void paintCutYarn(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    geometry.drawTriangle(
      canvas,
      contentRect,
      center: const Offset(0.5, 0.5),
      filled: true,
    );
  }

  // 長編み表引き上げ編み — No.30 Path（T + 掛け目1 + 下フック開口左）
  static void paintDoubleCrochetFrontPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: DoubleCrochetFrontPostVectorData.viewBox,
      layers: DoubleCrochetFrontPostVectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }

  // 長編み裏引き上げ編み — No.31 Path（T + 掛け目1 + 下フック開口右）
  static void paintDoubleCrochetBackPost(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    const StitchVectorPainter().paint(
      canvas: canvas,
      contentRect: contentRect,
      viewBox: DoubleCrochetBackPostVectorData.viewBox,
      layers: DoubleCrochetBackPostVectorData.layers,
      color: geometry.style.color,
      strokeWidth: geometry.metrics.strokeWidth,
    );
  }
}
