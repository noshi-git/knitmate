import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stitch_symbol.dart';

class PatternEditorPage extends StatefulWidget {
  const PatternEditorPage({
    super.key,
    required this.initialRows,
    required this.initialColumns,
    this.loadSavedPatternOnStart = false,
  })  : assert(initialRows > 0),
        assert(initialColumns > 0);

  final int initialRows;
  final int initialColumns;
  final bool loadSavedPatternOnStart;

  static const double cellSize = 36;
  static const double rowNumberWidth = 36;
  static const double columnNumberHeight = 28;

  @override
  State<PatternEditorPage> createState() => _PatternEditorPageState();
}

class _PatternEditorPageState extends State<PatternEditorPage> {
  static const String _saveKey = 'knitmate_pattern_grid';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  late int _rows;
  late int _columns;
  late List<List<StitchSymbol>> _grid;

  StitchSymbol _selectedSymbol = StitchSymbol.singleCrochet;
  List<List<StitchSymbol>>? _undoGrid;
  List<List<StitchSymbol>>? _gestureStartGrid;
  bool _gestureChanged = false;
  bool _isSaving = false;
  int? _lastEditedRow;
  int? _lastEditedColumn;

  @override
  void initState() {
    super.initState();
    _rows = widget.initialRows;
    _columns = widget.initialColumns;
    _grid = _createEmptyGrid(_rows, _columns);

    if (widget.loadSavedPatternOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPattern();
      });
    }
  }

  List<List<StitchSymbol>> _createEmptyGrid(int rows, int columns) {
    return List.generate(
      rows,
      (_) => List.generate(columns, (_) => StitchSymbol.empty),
    );
  }

  List<List<StitchSymbol>> _copyGrid(List<List<StitchSymbol>> source) {
    return source.map((row) => List<StitchSymbol>.from(row)).toList();
  }

  void _startEditing() {
    _lastEditedRow = null;
    _lastEditedColumn = null;
    _gestureStartGrid = _copyGrid(_grid);
    _gestureChanged = false;
  }

  void _finishEditing() {
    _lastEditedRow = null;
    _lastEditedColumn = null;
    _gestureStartGrid = null;
    _gestureChanged = false;
  }

  void _editCellFromPosition(Offset localPosition) {
    final gridX = localPosition.dx - PatternEditorPage.rowNumberWidth;
    final gridY = localPosition.dy - PatternEditorPage.columnNumberHeight;

    if (gridX < 0 || gridY < 0) {
      return;
    }

    final column = (gridX / PatternEditorPage.cellSize).floor();
    final displayRow = (gridY / PatternEditorPage.cellSize).floor();

    if (column < 0 ||
        column >= _columns ||
        displayRow < 0 ||
        displayRow >= _rows) {
      return;
    }

    // 内部では第1段をrow 0に保存し、画面では下から上へ表示する。
    final row = _rows - 1 - displayRow;

    if (_lastEditedRow == row && _lastEditedColumn == column) {
      return;
    }

    _lastEditedRow = row;
    _lastEditedColumn = column;

    if (_grid[row][column] == _selectedSymbol) {
      return;
    }

    setState(() {
      if (!_gestureChanged && _gestureStartGrid != null) {
        _undoGrid = _copyGrid(_gestureStartGrid!);
        _gestureChanged = true;
      }
      _grid[row][column] = _selectedSymbol;
    });
  }

  void _undo() {
    final undoGrid = _undoGrid;
    if (undoGrid == null) {
      return;
    }

    setState(() {
      _grid = _copyGrid(undoGrid);
      _undoGrid = null;
    });
  }

  Future<void> _savePattern() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final saveData = <String, Object>{
      'rows': _rows,
      'columns': _columns,
      'grid': _grid
          .map((row) => row.map((symbol) => symbol.index).toList())
          .toList(),
    };

    try {
      await _preferences.setString(_saveKey, jsonEncode(saveData));
      if (!mounted) return;
      _showMessage('編み図を保存しました');
    } catch (_) {
      if (!mounted) return;
      _showMessage('編み図の保存に失敗しました');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  Future<void> _loadPattern() async {
    try {
      final jsonText = await _preferences.getString(_saveKey);
      if (!mounted) return;

      if (jsonText == null) {
        _showMessage('保存されている編み図がありません');
        return;
      }

      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved pattern');
      }

      final rows = decoded['rows'];
      final columns = decoded['columns'];
      final gridData = decoded['grid'];

      if (rows is! int || rows <= 0 || columns is! int || columns <= 0) {
        throw const FormatException('Invalid grid size');
      }
      if (gridData is! List || gridData.length != rows) {
        throw const FormatException('Invalid row count');
      }

      final loadedGrid = <List<StitchSymbol>>[];
      for (final rowData in gridData) {
        if (rowData is! List || rowData.length != columns) {
          throw const FormatException('Invalid column count');
        }

        final loadedRow = <StitchSymbol>[];
        for (final value in rowData) {
          if (value is! int ||
              value < 0 ||
              value >= StitchSymbol.values.length) {
            throw const FormatException('Invalid stitch symbol');
          }
          loadedRow.add(StitchSymbol.values[value]);
        }
        loadedGrid.add(loadedRow);
      }

      setState(() {
        _rows = rows;
        _columns = columns;
        _grid = loadedGrid;
        _undoGrid = null;
        _gestureStartGrid = null;
        _gestureChanged = false;
        _lastEditedRow = null;
        _lastEditedColumn = null;
      });

      _showMessage('編み図を読み込みました');
    } catch (_) {
      if (!mounted) return;
      _showMessage('編み図の読み込みに失敗しました');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildSymbolWidget(BuildContext context, StitchSymbol symbol) {
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
            Container(width: 12, height: 1.5, color: lineColor),
            const SizedBox(height: 1),
            Container(width: 12, height: 1.5, color: lineColor),
            const SizedBox(height: 1),
            Text('T', style: Theme.of(context).textTheme.labelSmall),
          ],
        );
      case StitchSymbol.slipStitch:
        return Text('●', style: textStyle);
    }
  }

  Widget _buildSymbolButton(StitchSymbol symbol, String label) {
    final onPressed = () {
      setState(() {
        _selectedSymbol = symbol;
      });
    };

    return _selectedSymbol == symbol
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
  }

  Widget _buildColumnNumbers(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: PatternEditorPage.rowNumberWidth,
          height: PatternEditorPage.columnNumberHeight,
        ),
        ...List.generate(
          _columns,
          (column) => SizedBox(
            width: PatternEditorPage.cellSize,
            height: PatternEditorPage.columnNumberHeight,
            child: Center(
              child: Text(
                '${column + 1}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridRow(
    BuildContext context,
    int displayIndex,
    Color borderColor,
  ) {
    final row = _rows - 1 - displayIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: PatternEditorPage.rowNumberWidth,
          height: PatternEditorPage.cellSize,
          child: Center(
            child: Text(
              '${row + 1}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
        ...List.generate(
          _columns,
          (column) => Container(
            width: PatternEditorPage.cellSize,
            height: PatternEditorPage.cellSize,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: _buildSymbolWidget(context, _grid[row][column]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outline;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: '戻る',
        ),
        title: Text('$_columns × $_rows'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _savePattern,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? '保存中' : '保存'),
          ),
          IconButton(
            onPressed: _loadPattern,
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: '読み込み',
          ),
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
                        onPointerDown: (event) {
                          _startEditing();
                          _editCellFromPosition(event.localPosition);
                        },
                        onPointerMove: (event) {
                          _editCellFromPosition(event.localPosition);
                        },
                        onPointerUp: (_) => _finishEditing(),
                        onPointerCancel: (_) => _finishEditing(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildColumnNumbers(context),
                            ...List.generate(
                              _rows,
                              (displayIndex) => _buildGridRow(
                                context,
                                displayIndex,
                                borderColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSymbolButton(StitchSymbol.empty, '空白'),
                        const SizedBox(width: 8),
                        _buildSymbolButton(StitchSymbol.singleCrochet, '細編み'),
                        const SizedBox(width: 8),
                        _buildSymbolButton(StitchSymbol.doubleCrochet, '長編み'),
                        const SizedBox(width: 8),
                        _buildSymbolButton(StitchSymbol.trebleCrochet, '長々編み'),
                        const SizedBox(width: 8),
                        _buildSymbolButton(
                          StitchSymbol.slipStitch,
                          '引き抜き編み',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
