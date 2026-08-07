import 'package:flutter/material.dart';

import '../models/stitch_definition.dart';
import '../services/stitch_settings_service.dart';

// 編み記号の名称・表示記号を編集する画面
class StitchSettingsPage extends StatefulWidget {
  const StitchSettingsPage({super.key});

  static const int maxEnabledNonSystemCount = 15;
  static const int nameMaxLength = 20;
  static const int symbolMaxLength = 3;

  @override
  State<StitchSettingsPage> createState() => _StitchSettingsPageState();
}

class _StitchSettingsPageState extends State<StitchSettingsPage> {
  final StitchSettingsService _service = StitchSettingsService();

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

  Widget _buildDefinitionCard(StitchDefinition definition) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = definition.enabled
        ? null
        : colorScheme.onSurface.withValues(alpha: 0.5);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // 左：記号
            SizedBox(
              width: 48,
              child: Center(
                child: Text(
                  definition.symbol.isEmpty ? '—' : definition.symbol,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 中央：名称
            Expanded(
              child: Text(
                definition.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                    ),
              ),
            ),
            if (!definition.system) ...[
              // 編集ボタン
              IconButton(
                onPressed: () => _showEditDialog(definition),
                icon: const Icon(Icons.edit_outlined),
                tooltip: '編集',
              ),
              // 使用する Switch
              Switch(
                value: definition.enabled,
                onChanged: (value) => _setEnabled(definition, value),
              ),
              const SizedBox(width: 4),
              Text(
                '使用する',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
              ),
            ],
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
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final definition in _definitions)
                        _buildDefinitionCard(definition),
                    ],
                  ),
                ),
                _buildFooterNotes(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _canAddMore ? _showAddDialog : null,
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
    );
  }
}
