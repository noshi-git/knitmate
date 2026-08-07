import 'package:flutter/material.dart';

// 編み図左側の段番号を描画する
class PatternRowHeaderPainter extends CustomPainter {
  PatternRowHeaderPainter({
    required this.rows,
    required this.cellSize,
    required this.headerWidth,
    required this.theme,
  });

  final int rows;
  final double cellSize;
  final double headerWidth;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle =
        theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    final borderColor = theme.colorScheme.outline;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 上から rows → 1 の順（下が1段目）
    for (var displayIndex = 0; displayIndex < rows; displayIndex++) {
      final rowNumber = rows - displayIndex;
      final y = displayIndex * cellSize;

      _paintCenteredText(
        canvas,
        '$rowNumber',
        textStyle,
        Rect.fromLTWH(0, y, headerWidth, cellSize),
      );

      canvas.drawLine(
        Offset(0, y),
        Offset(headerWidth, y),
        borderPaint,
      );
    }

    canvas.drawLine(
      Offset(0, rows * cellSize),
      Offset(headerWidth, rows * cellSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(headerWidth, 0),
      Offset(headerWidth, rows * cellSize),
      borderPaint,
    );
  }

  void _paintCenteredText(
    Canvas canvas,
    String text,
    TextStyle style,
    Rect rect,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: rect.width);
    final offset = Offset(
      rect.left + (rect.width - textPainter.width) / 2,
      rect.top + (rect.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant PatternRowHeaderPainter oldDelegate) {
    return true;
  }
}
