import 'package:flutter/material.dart';

import '../models/stitch_definition.dart';
import '../models/stitch_label_display_mode.dart';
import '../models/stitch_symbol_type.dart';
import '../services/stitch_display_settings_service.dart';
import '../services/stitch_settings_service.dart';
import '../painters/stitch_symbol/stitch_symbol_display_scale.dart';
import '../utils/stitch_shortcut_key.dart';
import '../widgets/cell_background_color_picker_dialog.dart';
import '../widgets/stitch_shortcut_key_picker_dialog.dart';
import '../widgets/stitch_symbol_label.dart';
// 編み記号の名称・表示記号を編集する画面
class StitchSettingsPage extends StatefulWidget {
  const StitchSettingsPage({super.key});

  // 公式記号増加に備え、ユーザー追加分の余裕を確保する
  static const int maxEnabledNonSystemCount = 40;
  static const int nameMaxLength = 20;
  static const int symbolMaxLength = 3;

  /// V4.1 で選択可能な表示方法（nameOnly は将来追加）
  static const List<StitchLabelDisplayMode> selectableDisplayModes = [
    StitchLabelDisplayMode.symbolAndName,
    StitchLabelDisplayMode.symbolOnly,
  ];

  @override
  State<StitchSettingsPage> createState() => _StitchSettingsPageState();
}

class _StitchSettingsPageState extends State<StitchSettingsPage> {
  final StitchSettingsService _service = StitchSettingsService();
  final StitchDisplaySettingsService _displaySettings =
      StitchDisplaySettingsService.instance;

  List<StitchDefinition> _definitions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefinitions();
  }

  // 編み記号一覧を読み込む
  Future<void> _loadDefinitions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final definitions = await _service.loadDefinitions();
      if (!mounted) {
        return;
      }
      setState(() {
        _definitions = definitions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _definitions = [];
        _isLoading = false;
      });
      _showMessage('編み記号の読み込みに失敗しました');
    }
  }

  // 空白以外の登録数
  int get _nonSystemCount =>
      _definitions.where((definition) => !definition.system).length;

  // 有効な空白以外の登録数
  int get _enabledNonSystemCount => _definitions
      .where((definition) => !definition.system && definition.enabled)
      .length;

  bool get _canAddMore => _nonSystemCount < StitchSettingsPage.maxEnabledNonSystemCount;

  bool get _isAtRegistrationLimit =>
      _nonSystemCount >= StitchSettingsPage.maxEnabledNonSystemCount;

  Future<void> _saveDefinitions() async {
    try {
      await _service.saveDefinitions(_definitions);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('保存に失敗しました');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // 改行・タブなどの制御文字を含むか
  static bool _containsControlCharacter(String value) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit < 0x20 || codeUnit == 0x7F) {
        return true;
      }
    }
    return false;
  }

  static String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '名称を入力してください';
    }
    if (trimmed.length > StitchSettingsPage.nameMaxLength) {
      return '名称は${StitchSettingsPage.nameMaxLength}文字以内で入力してください';
    }
    if (_containsControlCharacter(trimmed)) {
      return '改行・タブなどの制御文字は使用できません';
    }
    return null;
  }

  static String? _validateSymbol(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '記号を入力してください';
    }
    if (trimmed.length > StitchSettingsPage.symbolMaxLength) {
      return '記号は${StitchSettingsPage.symbolMaxLength}文字以内で入力してください';
    }
    if (_containsControlCharacter(trimmed)) {
      return '改行・タブなどの制御文字は使用できません';
    }
    return null;
  }

  // 使用する Switch の ON/OFF（削除ではなく無効化）
  Future<void> _setEnabled(StitchDefinition definition, bool enabled) async {
    if (definition.system) {
      return;
    }

    if (enabled &&
        !definition.enabled &&
        _enabledNonSystemCount >= StitchSettingsPage.maxEnabledNonSystemCount) {
      _showMessage('有効にできる編み記号は最大${StitchSettingsPage.maxEnabledNonSystemCount}種類までです');
      return;
    }

    setState(() {
      final index = _definitions.indexWhere((item) => item.id == definition.id);
      if (index >= 0) {
        _definitions[index] = definition.copyWith(enabled: enabled);
      }
    });

    await _saveDefinitions();
  }

  Future<void> _pickCellBackgroundColor(StitchDefinition definition) async {
    if (definition.system) {
      return;
    }

    final result = await showCellBackgroundColorPickerDialog(
      context: context,
      initialColor: definition.cellBackgroundColor,
    );

    if (!mounted ||
        result == null ||
        result is CellBackgroundColorPickerCancelled) {
      return;
    }

    final selected = (result as CellBackgroundColorPickerSelected).colorArgb;
    if (selected == definition.cellBackgroundColor) {
      return;
    }
    setState(() {
      final index = _definitions.indexWhere((item) => item.id == definition.id);
      if (index >= 0) {
        _definitions[index] = definition.copyWith(
          cellBackgroundColor: selected,
        );
      }
    });

    await _saveDefinitions();
  }

  Future<void> _pickShortcutKey(StitchDefinition definition) async {
    if (definition.system) {
      return;
    }

    final result = await showStitchShortcutKeyPickerDialog(
      context: context,
      initialShortcutKey: definition.shortcutKey,
    );

    if (!mounted ||
        result == null ||
        result is StitchShortcutKeyPickerCancelled) {
      return;
    }

    final selected =
        (result as StitchShortcutKeyPickerSelected).shortcutKey;
    final normalized = StitchShortcutKey.normalize(selected);
    if (normalized != null) {
      final duplicate = StitchShortcutKey.findDuplicateOwner(
        definitions: _definitions,
        shortcutKey: normalized,
        excludeDefinitionId: definition.id,
      );
      if (duplicate != null) {
        _showMessage('キー $normalized は『${duplicate.name}』で使用されています');
        return;
      }
    }

    if (normalized == definition.shortcutKey) {
      return;
    }

    setState(() {
      final index = _definitions.indexWhere((item) => item.id == definition.id);
      if (index >= 0) {
        _definitions[index] = definition.copyWith(shortcutKey: normalized);
      }
    });

    await _saveDefinitions();
  }

  Widget _buildShortcutControl(
    StitchDefinition definition,
    Color foreground,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final display = definition.shortcutKey ?? '－';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'キー',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
              ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _pickShortcutKey(definition),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                display,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorControl(
    StitchDefinition definition,
    Color foreground,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasColor = definition.cellBackgroundColor != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '色',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
              ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _pickCellBackgroundColor(definition),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hasColor
                    ? Color(definition.cellBackgroundColor!)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasColor
                      ? colorScheme.outline
                      : colorScheme.outlineVariant,
                ),
              ),
              child: hasColor
                  ? null
                  : Icon(
                      Icons.format_color_reset_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // 新しい編み記号を追加する
  Future<void> _addDefinition(String name, String symbol) async {
    if (!_canAddMore) {
      _showMessage('最大${StitchSettingsPage.maxEnabledNonSystemCount}種類まで登録できます');
      return;
    }

    final newDefinition = StitchDefinition(
      id: StitchDefinition.generateId(),
      name: name.trim(),
      symbol: symbol.trim(),
      enabled: true,
      system: false,
      storageIndex: StitchSettingsService.nextStorageIndex(_definitions),
    );

    setState(() {
      _definitions.add(newDefinition);
    });

    await _saveDefinitions();
    if (mounted) {
      _showMessage('編み記号を追加しました');
    }
  }

  // 既存の編み記号を更新する
  Future<void> _updateDefinition(
    StitchDefinition definition,
    String name,
    String symbol,
  ) async {
    setState(() {
      final index = _definitions.indexWhere((item) => item.id == definition.id);
      if (index >= 0) {
        _definitions[index] = definition.copyWith(
          name: name.trim(),
          symbol: symbol.trim(),
        );
      }
    });

    await _saveDefinitions();
    if (mounted) {
      _showMessage('編み記号を更新しました');
    }
  }

  Future<void> _showAddDialog() async {
    if (!_canAddMore) {
      _showMessage('最大${StitchSettingsPage.maxEnabledNonSystemCount}種類まで登録できます');
      return;
    }

    final formKey = GlobalKey<FormState>();
    var nameText = '';
    var symbolText = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('編み記号を追加'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
                maxLength: StitchSettingsPage.nameMaxLength,
                validator: _validateName,
                onChanged: (value) => nameText = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: '記号',
                  border: OutlineInputBorder(),
                ),
                maxLength: StitchSettingsPage.symbolMaxLength,
                validator: _validateSymbol,
                onChanged: (value) => symbolText = value,
              ),
              const SizedBox(height: 12),
              Text(
                '絵文字や特殊文字は端末によって表示が異なる場合があります',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (!mounted || result != true) {
      return;
    }

    await _addDefinition(nameText, symbolText);
  }

  Future<void> _showEditDialog(StitchDefinition definition) async {
    if (definition.system) {
      return;
    }

    final formKey = GlobalKey<FormState>();
    var nameText = definition.name;
    var symbolText = definition.symbol;
    final isOfficialVector =
        StitchSymbolTypeMapper.fromId(definition.id) != StitchSymbolType.unknown;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('編み記号を編集'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: definition.name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
                maxLength: StitchSettingsPage.nameMaxLength,
                validator: _validateName,
                onChanged: (value) => nameText = value,
              ),
              if (!isOfficialVector) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: definition.symbol,
                  decoration: const InputDecoration(
                    labelText: '記号',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: StitchSettingsPage.symbolMaxLength,
                  validator: _validateSymbol,
                  onChanged: (value) => symbolText = value,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (!mounted || result != true) {
      return;
    }

    await _updateDefinition(definition, nameText, symbolText);
  }

  Future<void> _setDisplayMode(StitchLabelDisplayMode mode) async {
    try {
      await _displaySettings.setDisplayMode(mode);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('表示方法の保存に失敗しました');
    }
  }

  Widget _buildDisplayModeSection(StitchLabelDisplayMode displayMode) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '表示方法',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '設定一覧と編み図エディタの選択ボタンに共通で適用されます',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final segmented = SegmentedButton<StitchLabelDisplayMode>(
                  segments: [
                    for (final mode
                        in StitchSettingsPage.selectableDisplayModes)
                      ButtonSegment<StitchLabelDisplayMode>(
                        value: mode,
                        label: Text(mode.label),
                      ),
                  ],
                  selected: {displayMode},
                  onSelectionChanged: (selected) {
                    if (selected.isEmpty) {
                      return;
                    }
                    _setDisplayMode(selected.first);
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    textStyle: WidgetStatePropertyAll(
                      Theme.of(context).textTheme.labelLarge,
                    ),
                    visualDensity: VisualDensity.comfortable,
                  ),
                );

                if (constraints.maxWidth < 360) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 360),
                      child: segmented,
                    ),
                  );
                }

                return segmented;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefinitionCard(
    StitchDefinition definition,
    StitchLabelDisplayMode displayMode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = !definition.enabled;
    final foreground = muted
        ? colorScheme.onSurface.withValues(alpha: 0.5)
        : colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 24, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左：共通ラベル（表示方法に追従、公式ベクター対応）
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: StitchSymbolLabel(
                  definition: definition,
                  displayMode: displayMode,
                  color: foreground,
                  symbolExtent: 42,
                  symbolDisplayScale: StitchSymbolDisplayScale.settingsList,
                  spacing: 7,
                  maxNameWidth: 140,
                  nameStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            // 右端：編集 / 使用する（ウィンドウ幅に追従して常に右寄せ）
            if (!definition.system)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showEditDialog(definition),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: '編集',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildColorControl(definition, foreground),
                  const SizedBox(width: 8),
                  _buildShortcutControl(definition, foreground),
                  const SizedBox(width: 8),
                  Switch(
                    value: definition.enabled,
                    onChanged: (value) => _setEnabled(definition, value),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '使用する',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: foreground,
                        ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNotes() {
    final noteStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isAtRegistrationLimit)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '最大${StitchSettingsPage.maxEnabledNonSystemCount}種類まで登録できます',
                style: noteStyle,
              ),
            ),
          Text('名称：${StitchSettingsPage.nameMaxLength}文字まで', style: noteStyle),
          Text('記号：${StitchSettingsPage.symbolMaxLength}文字まで', style: noteStyle),
          Text('改行・タブは使用できません', style: noteStyle),
          Text('絵文字や特殊文字は端末によって表示が異なる場合があります', style: noteStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編み記号設定'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _displaySettings,
              builder: (context, _) {
                final displayMode = _displaySettings.displayMode;
                final effectiveMode =
                    StitchSettingsPage.selectableDisplayModes.contains(
                          displayMode,
                        )
                        ? displayMode
                        : StitchLabelDisplayMode.symbolAndName;

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        children: [
                          _buildDisplayModeSection(effectiveMode),
                          for (final definition in _definitions)
                            _buildDefinitionCard(definition, effectiveMode),
                        ],
                      ),
                    ),
                    _buildFooterNotes(),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _canAddMore ? _showAddDialog : null,
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
    );
  }
}
