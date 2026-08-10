import 'package:flutter/material.dart';

import '../models/stitch_definition.dart';
import '../models/stitch_symbol_type.dart';
import 'stitch_symbol/stitch_symbol_painter.dart';

// 編み図本体の罫線と編み記号を描画する
class PatternGridPainter extends CustomPainter {
  PatternGridPainter({
    required this.rows,
    required this.columns,
    required this.grid,
    required this.definitionsByStorageIndex,
    required this.cellSize,
    required this.theme,
    required this.cellSymbolScale,
  });

  final int rows;
  final int columns;
  final List<List<int>> grid;
  final Map<int, StitchDefinition> definitionsByStorageIndex;
  final double cellSize;
  final ThemeData theme;
  final double cellSymbolScale;

  static const _symbolPainter = StitchSymbolPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final borderColor = theme.colorScheme.outline;

    final gridPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final baseStyle =
        theme.textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final symbolColor = theme.colorScheme.onSurface;

    // 横罫線と編み記号（上から rows → 1 の順）
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
          baseStyle,
          symbolColor,
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

  // storageIndex → Definition → id → Type → Painter
  void _paintSymbol(
    Canvas canvas,
    int storageIndex,
    Rect cellRect,
    TextStyle baseStyle,
    Color symbolColor,
  ) {
    if (storageIndex == StitchDefinition.emptyStorageIndex) {
      return;
    }

    final definition = definitionsByStorageIndex[storageIndex];
    if (definition == null) {
      return;
    }

    final type = StitchSymbolTypeMapper.fromId(definition.id);
    if (type == StitchSymbolType.empty) {
      return;
    }

    if (type != StitchSymbolType.unknown) {
      _symbolPainter.paint(
        canvas: canvas,
        cellRect: cellRect,
        type: type,
        color: symbolColor,
        displayScale: cellSymbolScale,
      );
      return;
    }

    // unknown のみ既存の文字描画へフォールバック
    if (definition.symbol.isEmpty) {
      return;
    }

    final fontSize = _fontSizeForSymbol(definition.symbol, cellRect.width);
    _paintCenteredText(
      canvas,
      definition.symbol,
      baseStyle.copyWith(fontSize: fontSize, height: 1.0),
      cellRect,
    );
  }

  // 1～3文字がセル内に収まるよう文字サイズを調整する
  double _fontSizeForSymbol(String symbol, double cellSize) {
    switch (symbol.length) {
      case 1:
        return cellSize * 0.45;
      case 2:
        return cellSize * 0.34;
      case 3:
        return cellSize * 0.28;
      default:
        return cellSize * 0.24;
    }
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
  bool shouldRepaint(covariant PatternGridPainter oldDelegate) {
    // _grid は同一Listを直接変更するため、参照比較では変更を検出できない。
    // 確実に再描画を優先する。
    // TODO(200x300): 差分Undoや repaintRevision などで必要時のみ再描画するよう最適化する。
    return true;
  }
}
