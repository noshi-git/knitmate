import 'package:flutter/material.dart';

// 編み記号の色など見た目トークン（寸法は Metrics 側）
class StitchSymbolStyle {
  const StitchSymbolStyle({
    required this.color,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
  });

  final Color color;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;

  Paint get strokePaint => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeCap = strokeCap
    ..strokeJoin = strokeJoin;

  Paint get fillPaint => Paint()
    ..color = color
    ..style = PaintingStyle.fill;
}
