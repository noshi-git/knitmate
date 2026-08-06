import 'package:flutter/material.dart';

import '../models/stitch_symbol.dart';

class PatternEditorPage extends StatefulWidget {
  const PatternEditorPage({super.key});

  // 試作版グリッドのサイズ
  static const int gridRows = 10;
  static const int gridColumns = 10;
  static const double cellSize = 36;

  // 段番号・列番号を表示する部分のサイズ
  static const double rowNumberWidth = 28;
  static const double columnNumberHeight = 28;

  @override
  State<PatternEditorPage> createState() => _PatternEditorPageState();
}

class _PatternEditorPageState extends State<PatternEditorPage> {
  // 各マスに配置されている記号
  late List<List<StitchSymbol>> _grid;

  // 選択中の記号
  StitchSymbol _selectedSymbol = StitchSymbol.singleCrochet;

  // 直前の操作を戻すためのグリッド
  List<List<StitchSymbol>>? _undoGrid;

  // 現在の操作を始める直前のグリッド
  List<List<StitchSymbol>>? _gestureStartGrid;

  // 現在の操作で実際にマスを変更したか
  bool _gestureChanged = false;

  // ドラッグ中に最後に変更したマス
  int? _lastEditedRow;
  int? _lastEditedColumn;

  @override
  void initState() {
    super.initState();

    _grid = List.generate(
      PatternEditorPage.gridRows,
      (_) => List.generate(
        PatternEditorPage.gridColumns,
        (_) => StitchSymbol.empty,
      ),
    );
  }

  // グリッドを完全にコピーする
  List<List<StitchSymbol>> _copyGrid(
    List<List<StitchSymbol>> source,
  ) {
    return source
        .map((row) => List<StitchSymbol>.from(row))
        .toList();
  }

  // クリックまたはドラッグ操作の開始
  void _startEditing() {
    _lastEditedRow = null;
    _lastEditedColumn = null;

    // 操作開始前の状態を保存する
    _gestureStartGrid = _copyGrid(_grid);
    _gestureChanged = false;
  }

  // クリックまたはドラッグ操作の終了
  void _finishEditing() {
    _lastEditedRow = null;
    _lastEditedColumn = null;
    _gestureStartGrid = null;
    _gestureChanged = false;
  }

  // 指またはマウスの位置から対象マスを求めて編集する
  void _editCellFromPosition(Offset localPosition) {
    final gridX =
        localPosition.dx - PatternEditorPage.rowNumberWidth;
    final gridY =
        localPosition.dy - PatternEditorPage.columnNumberHeight;

    // 段番号・列番号やグリッド外では何もしない
    if (gridX < 0 || gridY < 0) {
      return;
    }

    final column =
        (gridX / PatternEditorPage.cellSize).floor();
    final displayRow =
        (gridY / PatternEditorPage.cellSize).floor();

    if (column < 0 ||
        column >= PatternEditorPage.gridColumns ||
        displayRow < 0 ||
        displayRow >= PatternEditorPage.gridRows) {
      return;
    }

    // 表示上の行を、内部データの行番号へ変換
    final row =
        PatternEditorPage.gridRows - 1 - displayRow;

    // 同じマスを連続して更新しない
    if (_lastEditedRow == row &&
        _lastEditedColumn == column) {
      return;
    }

    _lastEditedRow = row;
    _lastEditedColumn = column;

    // すでに同じ記号なら変更しない
    if (_grid[row][column] == _selectedSymbol) {
      return;
    }

    setState(() {
      // この操作で最初に変更した時だけ、
      // 操作開始前の状態をUndo用として保存する
      if (!_gestureChanged && _gestureStartGrid != null) {
        _undoGrid = _copyGrid(_gestureStartGrid!);
        _gestureChanged = true;
      }

      _grid[row][column] = _selectedSymbol;
    });
  }

  // 直前のクリックまたはドラッグ操作を元に戻す
  void _undo() {
    if (_undoGrid == null) {
      return;
    }

    setState(() {
      _grid = _copyGrid(_undoGrid!);

      // シンプルUndoなので、戻せるのは1回だけ
      _undoGrid = null;
    });
  }

  // マス内に編み記号を表示する
  Widget _buildSymbolWidget(
    BuildContext context,
    StitchSymbol symbol,
  ) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final lineColor = Theme.of(context).colorScheme.onSurface;

    switch (symbol) {
      case StitchSymbol.empty:
        return const SizedBox.shrink();

      case StitchSymbol.singleCrochet:
        return Text('×', style: textStyle);

      case StitchSymbol.doubleCrochet:
        return Text('T', style: textStyle);

      case StitchSymbol.trebleCrochet:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 1.5,
              color: lineColor,
            ),
            const SizedBox(height: 1),
            Container(
              width: 12,
              height: 1.5,
              color: lineColor,
            ),
            const SizedBox(height: 1),
            Text(
              'T',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );

      case StitchSymbol.slipStitch:
        return Text('●', style: textStyle);
    }
  }

  // 画面下部の記号選択ボタン
  Widget _buildSymbolButton(
    StitchSymbol symbol,
    String label,
  ) {
    final isSelected = _selectedSymbol == symbol;

    if (isSelected) {
      return FilledButton(
        onPressed: () {
          setState(() {
            _selectedSymbol = symbol;
          });
        },
        child: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedSymbol = symbol;
        });
      },
      child: Text(label),
    );
  }

  // グリッド上部の列番号
  Widget _buildColumnNumbers(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: PatternEditorPage.rowNumberWidth,
          height: PatternEditorPage.columnNumberHeight,
        ),
        ...List.generate(
          PatternEditorPage.gridColumns,
          (column) {
            return SizedBox(
              width: PatternEditorPage.cellSize,
              height: PatternEditorPage.columnNumberHeight,
              child: Center(
                child: Text(
                  '${column + 1}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // グリッドの1行
  Widget _buildGridRow(
    BuildContext context,
    int displayIndex,
    Color borderColor,
  ) {
    // 内部の0行目を画面一番下の1段目として表示
    final row =
        PatternEditorPage.gridRows - 1 - displayIndex;

    final rowNumber = row + 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 左側の段番号
        SizedBox(
          width: PatternEditorPage.rowNumberWidth,
          height: PatternEditorPage.cellSize,
          child: Center(
            child: Text(
              '$rowNumber',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),

        // 編み図の各マス
        ...List.generate(
          PatternEditorPage.gridColumns,
          (column) {
            return Container(
              width: PatternEditorPage.cellSize,
              height: PatternEditorPage.cellSize,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
              ),
              alignment: Alignment.center,
              child: _buildSymbolWidget(
                context,
                _grid[row][column],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        Theme.of(context).colorScheme.outline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('編み図エディタ'),

        // 右上の「元に戻す」ボタン
        actions: [
          IconButton(
            onPressed: _undoGrid == null ? null : _undo,
            icon: const Icon(Icons.undo),
            tooltip: '元に戻す',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Listener(
                        behavior: HitTestBehavior.opaque,

                        // 操作開始
                        onPointerDown: (event) {
                          _startEditing();
                          _editCellFromPosition(
                            event.localPosition,
                          );
                        },

                        // 押したまま移動したマスへ連続入力
                        onPointerMove: (event) {
                          _editCellFromPosition(
                            event.localPosition,
                          );
                        },

                        // 操作終了
                        onPointerUp: (_) {
                          _finishEditing();
                        },

                        onPointerCancel: (_) {
                          _finishEditing();
                        },

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildColumnNumbers(context),

                            ...List.generate(
                              PatternEditorPage.gridRows,
                              (displayIndex) {
                                return _buildGridRow(
                                  context,
                                  displayIndex,
                                  borderColor,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 記号選択ツールバー
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSymbolButton(
                      StitchSymbol.empty,
                      '空白',
                    ),
                    const SizedBox(width: 8),
                    _buildSymbolButton(
                      StitchSymbol.singleCrochet,
                      '細編み',
                    ),
                    const SizedBox(width: 8),
                    _buildSymbolButton(
                      StitchSymbol.doubleCrochet,
                      '長編み',
                    ),
                    const SizedBox(width: 8),
                    _buildSymbolButton(
                      StitchSymbol.trebleCrochet,
                      '長々編み',
                    ),
                    const SizedBox(width: 8),
                    _buildSymbolButton(
                      StitchSymbol.slipStitch,
                      '引き抜き編み',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}