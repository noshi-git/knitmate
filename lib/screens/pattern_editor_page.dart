import 'package:flutter/material.dart';

import '../models/cell_change.dart';
import '../models/project.dart';
import '../models/stitch_definition.dart';
import '../services/project_storage_service.dart';
import '../services/stitch_settings_service.dart';
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
  final StitchSettingsService _stitchSettingsService = StitchSettingsService();

  int _rows = 1;
  int _columns = 1;
  List<List<int>> _grid = [[StitchDefinition.emptyStorageIndex]];
  Project? _currentProject;

  List<StitchDefinition> _definitions = [];
  Map<int, StitchDefinition> _definitionsByStorageIndex = {};
  int _selectedStorageIndex = StitchDefinition.singleCrochetStorageIndex;
  bool _isDefinitionsLoading = true;

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

  // 選択ボタン用：有効な空白以外の編み記号
  List<StitchDefinition> get _selectableDefinitions => _definitions
      .where((definition) => definition.enabled && !definition.system)
      .toList();

  StitchDefinition? get _emptyDefinition =>
      _definitionsByStorageIndex[StitchDefinition.emptyStorageIndex];

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
    // グリッドは widget から同期的に決められるため、build 前に必ず初期化する
    _initializeGridSync();
    _loadDefinitions();
  }

  // 作品サイズとグリッドを同期的に初期化する
  void _initializeGridSync() {
    if (widget.project != null) {
      // 既存作品は storageIndex をそのまま利用する
      _currentProject = widget.project;
      _rows = widget.project!.rows;
      _columns = widget.project!.columns;
      _grid = widget.project!.grid
          .map((row) => List<int>.from(row))
          .toList();
      return;
    }

    _rows = widget.initialRows;
    _columns = widget.initialColumns;
    _grid = _createEmptyGrid(_rows, _columns);
  }

  // 編み記号設定だけ非同期で読み込む
  Future<void> _loadDefinitions() async {
    try {
      final definitions = await _stitchSettingsService.loadDefinitions();
      if (!mounted) {
        return;
      }

      setState(() {
        _definitions = definitions;
        _definitionsByStorageIndex = {
          for (final definition in definitions)
            definition.storageIndex: definition,
        };
        _selectedStorageIndex = _resolveInitialSelection();
        _isDefinitionsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isDefinitionsLoading = false;
      });
      _showMessage('編み記号設定の読み込みに失敗しました');
    }
  }

  // 初期選択：細編み(1) → 最初の有効記号 → 空白(0)
  int _resolveInitialSelection() {
    const defaultIndex = StitchDefinition.singleCrochetStorageIndex;
    final defaultDefinition = _definitionsByStorageIndex[defaultIndex];
    if (defaultDefinition != null && defaultDefinition.enabled) {
      return defaultIndex;
    }

    for (final definition in _definitions) {
      if (definition.enabled && !definition.system) {
        return definition.storageIndex;
      }
    }

    return StitchDefinition.emptyStorageIndex;
  }

  List<List<int>> _createEmptyGrid(int rows, int columns) {
    return List.generate(
      rows,
      (_) => List.generate(columns, (_) => StitchDefinition.emptyStorageIndex),
    );
  }

  List<List<int>> _gridToInts() {
    return _grid.map((row) => List<int>.from(row)).toList();
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
    if (_grid[row][column] == _selectedStorageIndex) {
      return;
    }

    setState(() {
      if (!_isCellRecorded(row, column)) {
        _gestureChanges?.add(
          CellChange(
            row: row,
            column: column,
            previousStorageIndex: _grid[row][column],
          ),
        );
      }

      // 最初の変更から Undo 対象として保持（1回だけ Undo）
      if (_gestureChanges != null && _gestureChanges!.isNotEmpty) {
        _undoChanges = _gestureChanges;
      }

      _grid[row][column] = _selectedStorageIndex;
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
        _grid[change.row][change.column] = change.previousStorageIndex;
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

  Widget _buildStorageIndexButton(int storageIndex, String label) {
    void onPressed() {
      setState(() {
        _selectedStorageIndex = storageIndex;
      });
    }

    return _selectedStorageIndex == storageIndex
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
  }

  Widget _buildSymbolSelector() {
    final emptyDefinition = _emptyDefinition;
    final emptyLabel = emptyDefinition?.name ?? '空白';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStorageIndexButton(
            StitchDefinition.emptyStorageIndex,
            emptyLabel,
          ),
          const SizedBox(width: 8),
          for (final definition in _selectableDefinitions) ...[
            _buildStorageIndexButton(
              definition.storageIndex,
              '${definition.symbol} ${definition.name}',
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildSymbolSelectorArea() {
    if (_isDefinitionsLoading) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return _buildSymbolSelector();
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
                  definitionsByStorageIndex: _definitionsByStorageIndex,
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
                  _buildSymbolSelectorArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
