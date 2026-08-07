import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pattern_editor_page.dart';

// 新しい作品作成ダイアログで入力されたサイズ
class PatternSize {
  const PatternSize({required this.rows, required this.columns});

  final int rows;
  final int columns;
}

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  // 「新しい作品」ボタン：横（目数）と縦（段数）を入力するダイアログ
  Future<void> _showNewPatternDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    var columnsText = '10';
    var rowsText = '10';

    // Controllerを使わないため、ダイアログ終了時の破棄エラーが起きない。
    final result = await showDialog<PatternSize>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新しい編み図'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: columnsText,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '横（目数）',
                  hintText: '例：20',
                  border: OutlineInputBorder(),
                ),
                validator: _validateSize,
                onChanged: (value) => columnsText = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: rowsText,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '縦（段数）',
                  hintText: '例：30',
                  border: OutlineInputBorder(),
                ),
                validator: _validateSize,
                onChanged: (value) => rowsText = value,
                onFieldSubmitted: (_) => _finishDialog(
                  dialogContext,
                  formKey,
                  rowsText,
                  columnsText,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => _finishDialog(
              dialogContext,
              formKey,
              rowsText,
              columnsText,
            ),
            child: const Text('作成'),
          ),
        ],
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatternEditorPage(
          initialRows: result.rows,
          initialColumns: result.columns,
        ),
      ),
    );
  }

  static String? _validateSize(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null) return '数字を入力してください';
    if (number < 1 || number > 50) return '現在は1～50で入力してください';
    return null;
  }

  void _finishDialog(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    String rowsText,
    String columnsText,
  ) {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(dialogContext).pop(
      PatternSize(
        rows: int.parse(rowsText),
        columns: int.parse(columnsText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作品一覧'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 画面上部：新しい作品を作成するボタン
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showNewPatternDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('新しい作品'),
                ),
              ),
              // 作品一覧データがないときの空状態
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '作品がありません',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '上の［新しい作品］から作成してください',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
