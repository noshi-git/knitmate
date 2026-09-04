import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/stitch_shortcut_key.dart';

/// ショートカットキー設定ダイアログの結果。
sealed class StitchShortcutKeyPickerResult {
  const StitchShortcutKeyPickerResult();
}

class StitchShortcutKeyPickerCancelled extends StitchShortcutKeyPickerResult {
  const StitchShortcutKeyPickerCancelled();
}

class StitchShortcutKeyPickerSelected extends StitchShortcutKeyPickerResult {
  const StitchShortcutKeyPickerSelected(this.shortcutKey);

  /// null の場合は設定解除
  final String? shortcutKey;
}

Future<StitchShortcutKeyPickerResult?> showStitchShortcutKeyPickerDialog({
  required BuildContext context,
  required String? initialShortcutKey,
}) {
  return showDialog<StitchShortcutKeyPickerResult>(
    context: context,
    builder: (dialogContext) => _StitchShortcutKeyPickerDialog(
      initialShortcutKey: initialShortcutKey,
    ),
  );
}

class _StitchShortcutKeyPickerDialog extends StatefulWidget {
  const _StitchShortcutKeyPickerDialog({
    required this.initialShortcutKey,
  });

  final String? initialShortcutKey;

  @override
  State<_StitchShortcutKeyPickerDialog> createState() =>
      _StitchShortcutKeyPickerDialogState();
}

class _StitchShortcutKeyPickerDialogState
    extends State<_StitchShortcutKeyPickerDialog> {
  final FocusNode _focusNode = FocusNode();
  String? _pendingKey;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return;
    }

    final normalized = StitchShortcutKey.fromKeyEvent(event);
    if (normalized == null) {
      setState(() {
        _errorMessage = 'このキーは登録できません';
        _pendingKey = null;
      });
      return;
    }

    setState(() {
      _pendingKey = normalized;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = widget.initialShortcutKey;

    return AlertDialog(
      title: const Text('ショートカットキー'),
      content: Focus(
        autofocus: true,
        focusNode: _focusNode,
        onKeyEvent: (_, event) {
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('現在の割り当て', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                current ?? '未設定',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text('キー入力', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  _pendingKey ?? '次に押したキーを登録してください',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'A〜Z / 0〜9 / F1〜F12 / テンキー0〜9',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const StitchShortcutKeyPickerSelected(null),
          ),
          child: const Text('設定解除'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const StitchShortcutKeyPickerCancelled(),
          ),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _pendingKey == null
              ? null
              : () => Navigator.of(context).pop(
                    StitchShortcutKeyPickerSelected(_pendingKey),
                  ),
          child: const Text('決定'),
        ),
      ],
    );
  }
}
