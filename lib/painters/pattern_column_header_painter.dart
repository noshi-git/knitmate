import 'package:flutter/material.dart';

// 編み図上部の列番号を描画する
class PatternColumnHeaderPainter extends CustomPainter {
  PatternColumnHeaderPainter({
    required this.columns,
    required this.cellSize,
    required this.headerHeight,
    required this.theme,
  });

  final int columns;
  final double cellSize;
  final double headerHeight;
  final ThemeData theme;

  // 1～99列は11px、100列以上は9px
  static const double _normalFontSize = 11;
  static const double _compactFontSize = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final baseStyle =
        theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    final borderColor = theme.colorScheme.outline;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var column = 0; column < columns; column++) {
      final columnNumber = column + 1;
      final fontSize =
          columnNumber >= 100 ? _compactFontSize : _normalFontSize;

      _paintCenteredText(
        canvas,
        '$columnNumber',
        baseStyle.copyWith(
          fontSize: fontSize,
          height: 1.0,
        ),
        Rect.fromLTWH(column * cellSize, 0, cellSize, headerHeight),
      );
    }

    // 列番号領域の枠線
    for (var column = 0; column <= columns; column++) {
      final x = column * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, headerHeight),
        borderPaint,
      );
    }
    canvas.drawLine(
      Offset(0, headerHeight),
      Offset(columns * cellSize, headerHeight),
      borderPaint,
    );
  }

  // 1行・中央揃えで文字を描画する
  void _paintCenteredText(
    Canvas canvas,
    String text,
    TextStyle style,
    Rect rect,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout(minWidth: 0, maxWidth: rect.width);
    final offset = Offset(
      rect.left + (rect.width - textPainter.width) / 2,
      rect.top + (rect.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant PatternColumnHeaderPainter oldDelegate) {
    return true;
  }
}
