import 'package:flutter/material.dart';

import '../models/stitch_symbol.dart';
import '../painters/pattern_column_header_painter.dart';
import '../painters/pattern_grid_painter.dart';
import '../painters/pattern_row_header_painter.dart';

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
  late final ScrollController _horizontalGridController;
  late final ScrollController _horizontalHeaderController;
  late final ScrollController _verticalGridController;
  late final ScrollController _verticalHeaderController;

  bool _isSyncingHorizontal = false;
  bool _isSyncingVertical = false;

  int? _lastEditedRow;
  int? _lastEditedColumn;

  double get _gridWidth => widget.columns * widget.cellSize;
  double get _gridHeight => widget.rows * widget.cellSize;

  @override
  void initState() {
    super.initState();
    _horizontalGridController = ScrollController();
    _horizontalHeaderController = ScrollController();
    _verticalGridController = ScrollController();
    _verticalHeaderController = ScrollController();

    _horizontalGridController.addListener(_syncHorizontalFromGrid);
    _horizontalHeaderController.addListener(_syncHorizontalFromHeader);
    _verticalGridController.addListener(_syncVerticalFromGrid);
    _verticalHeaderController.addListener(_syncVerticalFromHeader);
  }

  @override
  void dispose() {
    _horizontalGridController.removeListener(_syncHorizontalFromGrid);
    _horizontalHeaderController.removeListener(_syncHorizontalFromHeader);
    _verticalGridController.removeListener(_syncVerticalFromGrid);
    _verticalHeaderController.removeListener(_syncVerticalFromHeader);
    _horizontalGridController.dispose();
    _horizontalHeaderController.dispose();
    _verticalGridController.dispose();
    _verticalHeaderController.dispose();
    super.dispose();
  }

  // グリッド本体の横スクロール → 列番号へ同期
  void _syncHorizontalFromGrid() {
    if (_isSyncingHorizontal) {
      return;
    }
    _isSyncingHorizontal = true;
    if (_horizontalHeaderController.hasClients) {
      _horizontalHeaderController.jumpTo(_horizontalGridController.offset);
    }
    _isSyncingHorizontal = false;
  }

  // 列番号の横スクロール → グリッド本体へ同期
  void _syncHorizontalFromHeader() {
    if (_isSyncingHorizontal) {
      return;
    }
    _isSyncingHorizontal = true;
    if (_horizontalGridController.hasClients) {
      _horizontalGridController.jumpTo(_horizontalHeaderController.offset);
    }
    _isSyncingHorizontal = false;
  }

  // グリッド本体の縦スクロール → 段番号へ同期
  void _syncVerticalFromGrid() {
    if (_isSyncingVertical) {
      return;
    }
    _isSyncingVertical = true;
    if (_verticalHeaderController.hasClients) {
      _verticalHeaderController.jumpTo(_verticalGridController.offset);
    }
    _isSyncingVertical = false;
  }

  // 段番号の縦スクロール → グリッド本体へ同期
  void _syncVerticalFromHeader() {
    if (_isSyncingVertical) {
      return;
    }
    _isSyncingVertical = true;
    if (_verticalGridController.hasClients) {
      _verticalGridController.jumpTo(_verticalHeaderController.offset);
    }
    _isSyncingVertical = false;
  }

  // 同じセルを連続処理しないよう、最後に編集したセルをリセットする
  void _resetLastEdited() {
    _lastEditedRow = null;
    _lastEditedColumn = null;
  }

  // グリッド本体上の座標から row / column を求め、親へ編集通知する
  void _editCellFromPosition(Offset localPosition) {
    // localPosition は表示中の領域内座標のため、スクロール量を加算して全体座標へ変換
    final horizontalOffset = _horizontalGridController.hasClients
        ? _horizontalGridController.offset
        : 0.0;
    final verticalOffset = _verticalGridController.hasClients
        ? _verticalGridController.offset
        : 0.0;

    final gridX = localPosition.dx + horizontalOffset;
    final gridY = localPosition.dy + verticalOffset;

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

  // 左上の固定コーナー
  Widget _buildFixedCorner() {
    return Container(
      width: widget.rowNumberWidth,
      height: widget.columnNumberHeight,
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        border: Border.all(color: widget.theme.colorScheme.outline),
      ),
    );
  }

  // 上部：列番号（縦方向固定、横方向はグリッドと同期）
  Widget _buildColumnHeader() {
    return SizedBox(
      height: widget.columnNumberHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalHeaderController,
        child: CustomPaint(
          size: Size(_gridWidth, widget.columnNumberHeight),
          painter: PatternColumnHeaderPainter(
            columns: widget.columns,
            cellSize: widget.cellSize,
            headerHeight: widget.columnNumberHeight,
            theme: widget.theme,
          ),
        ),
      ),
    );
  }

  // 左側：段番号（横方向固定、縦方向はグリッドと同期）
  Widget _buildRowHeader() {
    return SizedBox(
      width: widget.rowNumberWidth,
      child: SingleChildScrollView(
        controller: _verticalHeaderController,
        child: CustomPaint(
          size: Size(widget.rowNumberWidth, _gridHeight),
          painter: PatternRowHeaderPainter(
            rows: widget.rows,
            cellSize: widget.cellSize,
            headerWidth: widget.rowNumberWidth,
            theme: widget.theme,
          ),
        ),
      ),
    );
  }

  // 本体：罫線 + 編み記号（縦横スクロール）
  Widget _buildGridBody() {
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
      child: SingleChildScrollView(
        controller: _verticalGridController,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalGridController,
          child: CustomPaint(
            size: Size(_gridWidth, _gridHeight),
            painter: PatternGridPainter(
              rows: widget.rows,
              columns: widget.columns,
              grid: widget.grid,
              cellSize: widget.cellSize,
              theme: widget.theme,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFixedCorner(),
            Expanded(child: _buildColumnHeader()),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRowHeader(),
              Expanded(child: _buildGridBody()),
            ],
          ),
        ),
      ],
    );
  }
}
