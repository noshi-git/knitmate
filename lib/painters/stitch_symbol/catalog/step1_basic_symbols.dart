import 'dart:ui';

import '../stitch_symbol_geometry.dart';

// Step1: 基本記号の描画
class Step1BasicSymbols {
  Step1BasicSymbols._();

  // くさり編み — 横長の中空楕円
  static void paintChain(Canvas canvas, Rect contentRect, StitchSymbolGeometry geometry) {
    geometry.drawOval(
      canvas,
      contentRect,
      center: const Offset(0.5, 0.5),
    );
  }

  // 引き抜き編み — 横長の塗りつぶし楕円
  static void paintSlipStitch(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    geometry.drawFilledOval(
      canvas,
      contentRect,
      center: const Offset(0.5, 0.5),
    );
  }

  // こま編み / 細編み — X
  static void paintSingleCrochet(
    Canvas canvas,
    Rect contentRect,
    StitchSymbolGeometry geometry,
  ) {
    geometry.drawX(
      canvas,
      contentRect,
      center: const Offset(0.5, 0.5),
    );
  }
}
