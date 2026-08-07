import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/project.dart';
import '../services/project_storage_service.dart';
import 'pattern_editor_page.dart';

// 新しい作品作成ダイアログで入力されたサイズ
class PatternSize {
  const PatternSize({required this.rows, required this.columns});

  final int rows;
  final int columns;
}

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  final ProjectStorageService _storage = ProjectStorageService();

  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  // 保存済み作品一覧を読み込む
  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await _storage.loadProjects();
      if (!mounted) {
        return;
      }
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _projects = [];
        _isLoading = false;
      });
    }
  }

  // 更新日時を「2026/08/07 11:30」形式で表示する
  String _formatUpdatedAt(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year/$month/$day $hour:$minute';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // 保存済み作品を編集画面で開く
  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatternEditorPage(
          initialRows: project.rows,
          initialColumns: project.columns,
          project: project,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    // 編集画面から戻ったら一覧を最新状態に更新
    await _loadProjects();
  }

  // 削除確認ダイアログを表示する
  Future<void> _confirmDeleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('作品を削除'),
        content: Text('『${project.name}』を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await _deleteProject(project);
  }

  // 作品を削除して一覧を更新する
  Future<void> _deleteProject(Project project) async {
    try {
      await _storage.deleteProject(project.id);
      if (!mounted) {
        return;
      }
      await _loadProjects();
      if (!mounted) {
        return;
      }
      _showMessage('作品を削除しました');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('作品の削除に失敗しました');
    }
  }

  // 「新しい作品」ボタン：横（目数）と縦（段数）を入力するダイアログ
  Future<void> _showNewPatternDialog() async {
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

    if (!mounted || result == null) {
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

    if (!mounted) {
      return;
    }

    // 新規作品を保存して戻った後も一覧を更新
    await _loadProjects();
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

  // 作品がないときの空状態
  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
    );
  }

  // 保存済み作品の一覧
  Widget _buildProjectList() {
    return ListView.builder(
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(project.name),
            subtitle: Text(
              '${project.columns} × ${project.rows}\n'
              '更新: ${_formatUpdatedAt(project.updatedAt)}',
            ),
            isThreeLine: true,
            onTap: () => _openProject(project),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDeleteProject(project);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      const Text('削除'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  onPressed: _showNewPatternDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('新しい作品'),
                ),
              ),
              const SizedBox(height: 16),
              // 読み込み中 / 空状態 / 作品一覧
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _projects.isEmpty
                        ? _buildEmptyState(context)
                        : _buildProjectList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
