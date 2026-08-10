import 'package:flutter/material.dart';

import '../models/cell_change.dart';
import '../models/project.dart';
import '../models/stitch_definition.dart';
import '../models/stitch_label_display_mode.dart';
import '../services/project_storage_service.dart';
import '../services/stitch_display_settings_service.dart';
import '../services/stitch_settings_service.dart';
import '../widgets/pattern_canvas.dart';
import '../widgets/stitch_symbol_label.dart';

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

  // 狭い画面では保存済み設定を変えず、表示だけシンボルのみへ寄せる
  static const double _selectorNameMinWidth = 640;
  static const double _selectorNameMinHeight = 560;

  StitchLabelDisplayMode _effectiveSelectorMode({
    required StitchLabelDisplayMode preferred,
    required double width,
    required double height,
  }) {
    if (preferred == StitchLabelDisplayMode.symbolOnly) {
      return preferred;
    }
    if (width < _selectorNameMinWidth || height < _selectorNameMinHeight) {
      return StitchLabelDisplayMode.symbolOnly;
    }
    return preferred;
  }

  Widget _buildStorageIndexButton({
    required StitchDefinition definition,
    required StitchLabelDisplayMode displayMode,
    required ColorScheme colorScheme,
  }) {
    final selected = _selectedStorageIndex == definition.storageIndex;

    void onPressed() {
      setState(() {
        _selectedStorageIndex = definition.storageIndex;
      });
    }

    final foreground =
        selected ? colorScheme.onPrimary : colorScheme.onSurface;
    final compactLabel = displayMode == StitchLabelDisplayMode.symbolOnly;

    final label = StitchSymbolLabel(
      definition: definition,
      displayMode: displayMode,
      color: foreground,
      symbolExtent: compactLabel ? 32 : 34,
      symbolDisplayScale:
          StitchDisplaySettingsService.instance.buttonSymbolScaleValue,
      spacing: 5,
      nameStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
    );

    final style = ButtonStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: compactLabel ? 10 : 12,
          vertical: compactLabel ? 8 : 10,
        ),
      ),
      alignment: Alignment.center,
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (selected) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: label,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: label,
    );
  }

  Widget _buildSymbolSelector(StitchLabelDisplayMode displayMode) {
    final colorScheme = Theme.of(context).colorScheme;
    final emptyDefinition = _emptyDefinition ??
        const StitchDefinition(
          id: 'empty',
          name: '空白',
          symbol: '',
          enabled: true,
          system: true,
          storageIndex: StitchDefinition.emptyStorageIndex,
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildStorageIndexButton(
          definition: emptyDefinition,
          displayMode: displayMode,
          colorScheme: colorScheme,
        ),
        for (final definition in _selectableDefinitions)
          _buildStorageIndexButton(
            definition: definition,
            displayMode: displayMode,
            colorScheme: colorScheme,
          ),
      ],
    );
  }

  Widget _buildSymbolSelectorArea({
    required double maxHeight,
    required StitchLabelDisplayMode displayMode,
  }) {
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

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: _buildSymbolSelector(displayMode),
      ),
    );
  }

  List<Widget> _buildAppBarActions({required bool compact}) {
    final zoomOut = IconButton(
      onPressed: _canZoomOut ? _zoomOut : null,
      icon: const Text('－'),
      tooltip: '縮小',
    );
    final zoomLabel = TextButton(
      onPressed: _resetZoom,
      child: Text(_zoomLabel),
    );
    final zoomIn = IconButton(
      onPressed: _canZoomIn ? _zoomIn : null,
      icon: const Text('＋'),
      tooltip: '拡大',
    );
    final undo = IconButton(
      onPressed: _undoChanges == null ? null : _undo,
      icon: const Icon(Icons.undo),
      tooltip: '元に戻す',
    );

    final saveIcon = _isSaving
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.save_outlined);

    if (compact) {
      return [
        IconButton(
          onPressed: _canZoomOut ? _zoomOut : null,
          icon: const Icon(Icons.remove),
          tooltip: '縮小',
        ),
        IconButton(
          onPressed: _resetZoom,
          icon: Text(
            _zoomLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          tooltip: 'ズームをリセット',
        ),
        IconButton(
          onPressed: _canZoomIn ? _zoomIn : null,
          icon: const Icon(Icons.add),
          tooltip: '拡大',
        ),
        IconButton(
          onPressed: _isSaving ? null : _savePattern,
          icon: saveIcon,
          tooltip: _isSaving ? '保存中' : '保存',
        ),
        undo,
      ];
    }

    return [
      zoomOut,
      zoomLabel,
      zoomIn,
      TextButton.icon(
        onPressed: _isSaving ? null : _savePattern,
        icon: saveIcon,
        label: Text(_isSaving ? '保存中' : '保存'),
      ),
      undo,
    ];
  }

  PreferredSizeWidget _buildEditorAppBar(double width) {
    final compact = width < 720;
    final veryCompact = width < 560;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: _goBack,
        icon: const Icon(Icons.arrow_back),
        tooltip: '戻る',
      ),
      title: Text(
        '$_columns × $_rows',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      titleSpacing: compact ? 0 : NavigationToolbar.kMiddleSpacing,
      actions: veryCompact
          ? [
              PopupMenuButton<_EditorAppBarAction>(
                tooltip: 'メニュー',
                onSelected: (action) {
                  switch (action) {
                    case _EditorAppBarAction.zoomOut:
                      _zoomOut();
                    case _EditorAppBarAction.zoomReset:
                      _resetZoom();
                    case _EditorAppBarAction.zoomIn:
                      _zoomIn();
                    case _EditorAppBarAction.save:
                      _savePattern();
                    case _EditorAppBarAction.undo:
                      _undo();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _EditorAppBarAction.zoomOut,
                    enabled: _canZoomOut,
                    child: Text('縮小'),
                  ),
                  PopupMenuItem(
                    value: _EditorAppBarAction.zoomReset,
                    child: Text('ズーム $_zoomLabel'),
                  ),
                  PopupMenuItem(
                    value: _EditorAppBarAction.zoomIn,
                    enabled: _canZoomIn,
                    child: Text('拡大'),
                  ),
                  PopupMenuItem(
                    value: _EditorAppBarAction.save,
                    enabled: !_isSaving,
                    child: Text(_isSaving ? '保存中' : '保存'),
                  ),
                  PopupMenuItem(
                    value: _EditorAppBarAction.undo,
                    enabled: _undoChanges != null,
                    child: const Text('元に戻す'),
                  ),
                ],
              ),
            ]
          : _buildAppBarActions(compact: compact),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final width = media.width;
    final height = media.height;
    final selectorMaxHeight = (height * 0.34).clamp(72.0, 220.0);

    return Scaffold(
      appBar: _buildEditorAppBar(width),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            width < 480 ? 8 : 16,
            width < 480 ? 8 : 16,
            width < 480 ? 8 : 16,
            0,
          ),
          child: ListenableBuilder(
            listenable: StitchDisplaySettingsService.instance,
            builder: (context, _) {
              final displaySettings = StitchDisplaySettingsService.instance;
              final preferred = displaySettings.displayMode;
              final effectiveMode = _effectiveSelectorMode(
                preferred: preferred,
                width: width,
                height: height,
              );

              return Column(
                children: [
                  Expanded(
                    child: PatternCanvas(
                      rows: _rows,
                      columns: _columns,
                      grid: _grid,
                      definitionsByStorageIndex: _definitionsByStorageIndex,
                      cellSize: PatternEditorPage.cellSize,
                      rowNumberWidth: PatternEditorPage.rowNumberWidth,
                      columnNumberHeight: PatternEditorPage.columnNumberHeight,
                      theme: Theme.of(context),
                      cellSymbolScale: displaySettings.cellSymbolScaleValue,
                      zoom: _zoom,
                      onCellEdit: _onCellEdit,
                      onEditStart: _startEditing,
                      onEditEnd: _finishEditing,
                      onZoomIn: _zoomIn,
                      onZoomOut: _zoomOut,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      width < 480 ? 8 : 12,
                      0,
                      width < 480 ? 8 : 16,
                    ),
                    child: _buildSymbolSelectorArea(
                      maxHeight: selectorMaxHeight,
                      displayMode: effectiveMode,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _EditorAppBarAction {
  zoomOut,
  zoomReset,
  zoomIn,
  save,
  undo,
}
