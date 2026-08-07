import 'package:flutter/material.dart';

import '../models/cell_change.dart';
import '../models/project.dart';
import '../models/stitch_symbol.dart';
import '../services/project_storage_service.dart';
import '../widgets/pattern_canvas.dart';

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
  static const double columnNumberHeight = 30;

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
  List<CellChange>? _undoChanges;
  List<CellChange>? _gestureChanges;
  bool _isSaving = false;

  // ズーム倍率（6段階）
  static const List<double> _zoomLevels = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
  ];
  double _zoom = 1.0;

  String get _zoomLabel => '${(_zoom * 100).round()}%';

  bool get _canZoomOut => _zoomLevels.indexOf(_zoom) > 0;

  bool get _canZoomIn =>
      _zoomLevels.indexOf(_zoom) < _zoomLevels.length - 1;

  void _zoomOut() {
    final index = _zoomLevels.indexOf(_zoom);
    if (index <= 0) {
      return;
    }
    setState(() {
      _zoom = _zoomLevels[index - 1];
    });
  }

  void _zoomIn() {
    final index = _zoomLevels.indexOf(_zoom);
    if (index < 0 || index >= _zoomLevels.length - 1) {
      return;
    }
    setState(() {
      _zoom = _zoomLevels[index + 1];
    });
  }

  void _resetZoom() {
    setState(() {
      _zoom = 1.0;
    });
  }

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

  void _startEditing() {
    // 1回のドラッグ操作分の変更を記録する空リストを用意
    _gestureChanges = [];
  }

  void _finishEditing() {
    _gestureChanges = null;
  }

  // 同じ row+column が既に記録済みか
  bool _isCellRecorded(int row, int column) {
    return _gestureChanges?.any(
          (change) => change.row == row && change.column == column,
        ) ??
        false;
  }

  // PatternCanvas からのセル編集通知を受け取る
  void _onCellEdit(int row, int column) {
    if (_grid[row][column] == _selectedSymbol) {
      return;
    }

    setState(() {
      if (!_isCellRecorded(row, column)) {
        _gestureChanges?.add(
          CellChange(
            row: row,
            column: column,
            previousSymbol: _grid[row][column],
          ),
        );
      }

      // 最初の変更から Undo 対象として保持（1回だけ Undo）
      if (_gestureChanges != null && _gestureChanges!.isNotEmpty) {
        _undoChanges = _gestureChanges;
      }

      _grid[row][column] = _selectedSymbol;
    });
  }

  void _undo() {
    final changes = _undoChanges;
    if (changes == null || changes.isEmpty) {
      return;
    }

    setState(() {
      for (var i = changes.length - 1; i >= 0; i--) {
        final change = changes[i];
        _grid[change.row][change.column] = change.previousSymbol;
      }
      _undoChanges = null;
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
          IconButton(
            onPressed: _canZoomOut ? _zoomOut : null,
            icon: const Text('－'),
            tooltip: '縮小',
          ),
          TextButton(
            onPressed: _resetZoom,
            child: Text(_zoomLabel),
          ),
          IconButton(
            onPressed: _canZoomIn ? _zoomIn : null,
            icon: const Text('＋'),
            tooltip: '拡大',
          ),
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
            onPressed: _undoChanges == null ? null : _undo,
            icon: const Icon(Icons.undo),
            tooltip: '元に戻す',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PatternCanvas(
                  rows: _rows,
                  columns: _columns,
                  grid: _grid,
                  cellSize: PatternEditorPage.cellSize,
                  rowNumberWidth: PatternEditorPage.rowNumberWidth,
                  columnNumberHeight: PatternEditorPage.columnNumberHeight,
                  theme: Theme.of(context),
                  zoom: _zoom,
                  onCellEdit: _onCellEdit,
                  onEditStart: _startEditing,
                  onEditEnd: _finishEditing,
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
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
