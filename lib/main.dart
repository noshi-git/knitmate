import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/counter_page.dart';
import 'screens/pattern_editor_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KnitMate',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

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

  void _openSavedPattern(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PatternEditorPage(
          initialRows: 10,
          initialColumns: 10,
          loadSavedPatternOnStart: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KnitMate')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ようこそ KnitMateへ',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '編み物をもっと楽しく。',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CounterPage(),
                    ),
                  ),
                  child: const Text('編み始める'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => _showNewPatternDialog(context),
                  child: const Text('新しい編み図'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openSavedPattern(context),
                  child: const Text('編み図を開く'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatternSize {
  const PatternSize({required this.rows, required this.columns});

  final int rows;
  final int columns;
}
