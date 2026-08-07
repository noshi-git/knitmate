import 'package:flutter/material.dart';

import '../models/stitch_symbol.dart';

// 編み図本体の罫線と編み記号を描画する
class PatternGridPainter extends CustomPainter {
  PatternGridPainter({
    required this.rows,
    required this.columns,
    required this.grid,
    required this.cellSize,
    required this.theme,
  });

  final int rows;
  final int columns;
  final List<List<StitchSymbol>> grid;
  final double cellSize;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final borderColor = theme.colorScheme.outline;

    final gridPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 横罫線と編み記号（上から rows → 1 の順）
    final bodyLargeStyle =
        theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final labelSmallStyle =
        theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    final symbolLineColor = theme.colorScheme.onSurface;

    for (var displayIndex = 0; displayIndex < rows; displayIndex++) {
      final row = rows - 1 - displayIndex;
      final y = displayIndex * cellSize;

      canvas.drawLine(
        Offset(0, y),
        Offset(columns * cellSize, y),
        gridPaint,
      );

      for (var column = 0; column < columns; column++) {
        final x = column * cellSize;
        final cellRect = Rect.fromLTWH(x, y, cellSize, cellSize);
        _paintSymbol(
          canvas,
          grid[row][column],
          cellRect,
          bodyLargeStyle,
          labelSmallStyle,
          symbolLineColor,
        );
      }
    }

    // 最下段の横罫線
    canvas.drawLine(
      Offset(0, rows * cellSize),
      Offset(columns * cellSize, rows * cellSize),
      gridPaint,
    );

    // 縦罫線
    for (var column = 0; column <= columns; column++) {
      final x = column * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, rows * cellSize),
        gridPaint,
      );
    }
  }

  // 1マス分の編み記号を Canvas で描画する
  void _paintSymbol(
    Canvas canvas,
    StitchSymbol symbol,
    Rect cellRect,
    TextStyle bodyLargeStyle,
    TextStyle labelSmallStyle,
    Color lineColor,
  ) {
    switch (symbol) {
      case StitchSymbol.empty:
        return;
      case StitchSymbol.singleCrochet:
        _paintCenteredText(canvas, '×', bodyLargeStyle, cellRect);
      case StitchSymbol.doubleCrochet:
        _paintCenteredText(canvas, 'T', bodyLargeStyle, cellRect);
      case StitchSymbol.trebleCrochet:
        _paintTrebleCrochet(
          canvas,
          cellRect,
          labelSmallStyle,
          lineColor,
        );
      case StitchSymbol.slipStitch:
        _paintCenteredText(canvas, '●', bodyLargeStyle, cellRect);
    }
  }

  // 長々編み：横線2本 + T
  void _paintTrebleCrochet(
    Canvas canvas,
    Rect cellRect,
    TextStyle labelSmallStyle,
    Color lineColor,
  ) {
    const lineWidth = 12.0;
    const lineHeight = 1.5;
    const gap = 1.0;

    final textPainter = TextPainter(
      text: TextSpan(text: 'T', style: labelSmallStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final totalHeight = lineHeight + gap + lineHeight + gap + textPainter.height;
    var top = cellRect.center.dy - totalHeight / 2;
    final centerX = cellRect.center.dx;

    final linePaint = Paint()..color = lineColor;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, top + lineHeight / 2),
        width: lineWidth,
        height: lineHeight,
      ),
      linePaint,
    );
    top += lineHeight + gap;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, top + lineHeight / 2),
        width: lineWidth,
        height: lineHeight,
      ),
      linePaint,
    );
    top += lineHeight + gap;

    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, top),
    );
  }

  // 指定矩形の中央に文字を描画する
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
  bool shouldRepaint(covariant PatternGridPainter oldDelegate) {
    // _grid は同一Listを直接変更するため、参照比較では変更を検出できない。
    // 確実に再描画を優先する。
    // TODO(200x300): 差分Undoや repaintRevision などで必要時のみ再描画するよう最適化する。
    return true;
  }
}
