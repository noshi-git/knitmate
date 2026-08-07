import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/stitch_symbol.dart';
import '../painters/pattern_grid_painter.dart';
import '../services/project_storage_service.dart';

class PatternEditorPage extends StatefulWidget {
  const PatternEditorPage({
    super.key,
    required this.initialRows,
    required this.initialColumns,
    this.project,
  })  : assert(initialRows > 0),
        assert(initialColumns > 0);

  final int initialRows;
  final int initialColumns;
  final Project? project;

  static const double cellSize = 36;
  static const double rowNumberWidth = 36;
  static const double columnNumberHeight = 28;

  @override
  State<PatternEditorPage> createState() => _PatternEditorPageState();
}

class _PatternEditorPageState extends State<PatternEditorPage> {
  final ProjectStorageService _storage = ProjectStorageService();

  late int _rows;
  late int _columns;
  late List<List<StitchSymbol>> _grid;
  Project? _currentProject;

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

    if (widget.project != null) {
      // 既存作品を開いた場合はProjectから読み込む
      _currentProject = widget.project;
      _rows = widget.project!.rows;
      _columns = widget.project!.columns;
      _grid = _gridFromInts(widget.project!.grid);
    } else {
      // 新規作品の場合は空のグリッドから開始
      _rows = widget.initialRows;
      _columns = widget.initialColumns;
      _grid = _createEmptyGrid(_rows, _columns);
    }
  }

  List<List<StitchSymbol>> _gridFromInts(List<List<int>> grid) {
    return grid
        .map(
          (row) => row.map((value) => StitchSymbol.values[value]).toList(),
        )
        .toList();
  }

  List<List<int>> _gridToInts() {
    return _grid
        .map((row) => row.map((symbol) => symbol.index).toList())
        .toList();
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

  Future<String?> _showProjectNameDialog() async {
    final formKey = GlobalKey<FormState>();
    var nameText = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('作品名'),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '例：「バッグ」',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '作品名を入力してください';
              }
              return null;
            },
            onChanged: (value) => nameText = value,
            onFieldSubmitted: (_) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(nameText.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(nameText.trim());
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePattern() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      Project projectToSave;

      if (_currentProject == null) {
        // 新規作品の初回保存：作品名を入力してもらう
        final name = await _showProjectNameDialog();
        if (!mounted) {
          return;
        }
        if (name == null) {
          return;
        }

        final now = DateTime.now();
        projectToSave = Project(
          id: Project.generateId(),
          name: name,
          rows: _rows,
          columns: _columns,
          grid: _gridToInts(),
          createdAt: now,
          updatedAt: now,
        );
      } else {
        // 2回目以降：同じIDのJSONファイルを上書き保存
        projectToSave = _currentProject!.copyWith(
          rows: _rows,
          columns: _columns,
          grid: _gridToInts(),
          updatedAt: DateTime.now(),
        );
      }

      await _storage.saveProject(projectToSave);
      if (!mounted) {
        return;
      }

      setState(() {
        _currentProject = projectToSave;
      });
      _showMessage('作品を保存しました');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('作品の保存に失敗しました');
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

  @override
  Widget build(BuildContext context) {
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
                        child: CustomPaint(
                          size: Size(
                            PatternEditorPage.rowNumberWidth +
                                _columns * PatternEditorPage.cellSize,
                            PatternEditorPage.columnNumberHeight +
                                _rows * PatternEditorPage.cellSize,
                          ),
                          painter: PatternGridPainter(
                            rows: _rows,
                            columns: _columns,
                            grid: _grid,
                            cellSize: PatternEditorPage.cellSize,
                            rowNumberWidth: PatternEditorPage.rowNumberWidth,
                            columnNumberHeight:
                                PatternEditorPage.columnNumberHeight,
                            theme: Theme.of(context),
                          ),
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
