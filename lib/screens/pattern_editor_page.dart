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

  // 最初に選択される記号
  StitchSymbol _selectedSymbol = StitchSymbol.singleCrochet;

  // ドラッグ中に最後に変更したマス
  // 同じマスを何度も更新しないために使用する
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

  // 指またはマウスの位置から、対象のマスを求めて編集する
  void _editCellFromPosition(Offset localPosition) {
    // 段番号と列番号の部分を除いた、グリッド内の座標
    final gridX =
        localPosition.dx - PatternEditorPage.rowNumberWidth;
    final gridY =
        localPosition.dy - PatternEditorPage.columnNumberHeight;

    // 番号部分やグリッド外を操作した場合は何もしない
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

    // 画面上は10段目から1段目の順なので、
    // 表示位置を内部データの行番号へ変換する
    final row =
        PatternEditorPage.gridRows - 1 - displayRow;

    // ドラッグ中に同じマスへ何度も入った場合は更新しない
    if (_lastEditedRow == row &&
        _lastEditedColumn == column) {
      return;
    }

    setState(() {
      _grid[row][column] = _selectedSymbol;
    });

    _lastEditedRow = row;
    _lastEditedColumn = column;
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
    // 内部の0行目を、画面一番下の1段目として表示する
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
                border: Border.all(
                  color: borderColor,
                ),
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

                      // Pointerの位置を取得して、
                      // クリック入力とドラッグ入力の両方に対応する
                      child: Listener(
                        behavior: HitTestBehavior.opaque,

                        // 押し始めた位置のマスへ入力
                        onPointerDown: (event) {
                          _lastEditedRow = null;
                          _lastEditedColumn = null;

                          _editCellFromPosition(
                            event.localPosition,
                          );
                        },

                        // 押したまま移動した先のマスへ連続入力
                        onPointerMove: (event) {
                          _editCellFromPosition(
                            event.localPosition,
                          );
                        },

                        // 操作終了時に記録をリセット
                        onPointerUp: (_) {
                          _lastEditedRow = null;
                          _lastEditedColumn = null;
                        },

                        onPointerCancel: (_) {
                          _lastEditedRow = null;
                          _lastEditedColumn = null;
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