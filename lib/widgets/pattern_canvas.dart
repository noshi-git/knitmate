import 'package:flutter/material.dart';

import '../models/stitch_symbol.dart';
import '../painters/pattern_grid_painter.dart';

// 編み図の表示とポインター入力を担当する
class PatternCanvas extends StatefulWidget {
  const PatternCanvas({
    super.key,
    required this.rows,
    required this.columns,
    required this.grid,
    required this.cellSize,
    required this.rowNumberWidth,
    required this.columnNumberHeight,
    required this.theme,
    required this.onCellEdit,
    this.onEditStart,
    this.onEditEnd,
  });

  final int rows;
  final int columns;
  final List<List<StitchSymbol>> grid;
  final double cellSize;
  final double rowNumberWidth;
  final double columnNumberHeight;
  final ThemeData theme;
  final void Function(int row, int column) onCellEdit;
  final VoidCallback? onEditStart;
  final VoidCallback? onEditEnd;

  @override
  State<PatternCanvas> createState() => _PatternCanvasState();
}

class _PatternCanvasState extends State<PatternCanvas> {
  int? _lastEditedRow;
  int? _lastEditedColumn;

  // 同じセルを連続処理しないよう、最後に編集したセルをリセットする
  void _resetLastEdited() {
    _lastEditedRow = null;
    _lastEditedColumn = null;
  }

  // 画面座標から row / column を求め、親へ編集通知する
  void _editCellFromPosition(Offset localPosition) {
    final gridX = localPosition.dx - widget.rowNumberWidth;
    final gridY = localPosition.dy - widget.columnNumberHeight;

    if (gridX < 0 || gridY < 0) {
      return;
    }

    final column = (gridX / widget.cellSize).floor();
    final displayRow = (gridY / widget.cellSize).floor();

    if (column < 0 ||
        column >= widget.columns ||
        displayRow < 0 ||
        displayRow >= widget.rows) {
      return;
    }

    // 内部では第1段をrow 0に保存し、画面では下から上へ表示する。
    final row = widget.rows - 1 - displayRow;

    if (_lastEditedRow == row && _lastEditedColumn == column) {
      return;
    }

    _lastEditedRow = row;
    _lastEditedColumn = column;
    widget.onCellEdit(row, column);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _resetLastEdited();
        widget.onEditStart?.call();
        _editCellFromPosition(event.localPosition);
      },
      onPointerMove: (event) {
        _editCellFromPosition(event.localPosition);
      },
      onPointerUp: (_) {
        _resetLastEdited();
        widget.onEditEnd?.call();
      },
      onPointerCancel: (_) {
        _resetLastEdited();
        widget.onEditEnd?.call();
      },
      child: CustomPaint(
        size: Size(
          widget.rowNumberWidth + widget.columns * widget.cellSize,
          widget.columnNumberHeight + widget.rows * widget.cellSize,
        ),
        painter: PatternGridPainter(
          rows: widget.rows,
          columns: widget.columns,
          grid: widget.grid,
          cellSize: widget.cellSize,
          rowNumberWidth: widget.rowNumberWidth,
          columnNumberHeight: widget.columnNumberHeight,
          theme: widget.theme,
        ),
      ),
    );
  }
}
