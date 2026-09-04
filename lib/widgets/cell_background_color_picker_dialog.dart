import 'package:flutter/material.dart';

/// 色選択ダイアログの結果。
sealed class CellBackgroundColorPickerResult {
  const CellBackgroundColorPickerResult();
}

class CellBackgroundColorPickerCancelled
    extends CellBackgroundColorPickerResult {
  const CellBackgroundColorPickerCancelled();
}

class CellBackgroundColorPickerSelected
    extends CellBackgroundColorPickerResult {
  const CellBackgroundColorPickerSelected(this.colorArgb);

  /// null の場合は色なし（デフォルト背景へ戻す）
  final int? colorArgb;
}

/// 編み記号のセル背景色を選択するダイアログ（Material のみ）。
Future<CellBackgroundColorPickerResult?> showCellBackgroundColorPickerDialog({
  required BuildContext context,
  required int? initialColor,
}) {
  return showDialog<CellBackgroundColorPickerResult>(
    context: context,
    builder: (dialogContext) => _CellBackgroundColorPickerDialog(
      initialColor: initialColor,
    ),
  );
}

class _CellBackgroundColorPickerDialog extends StatefulWidget {
  const _CellBackgroundColorPickerDialog({
    required this.initialColor,
  });

  final int? initialColor;

  @override
  State<_CellBackgroundColorPickerDialog> createState() =>
      _CellBackgroundColorPickerDialogState();
}

class _CellBackgroundColorPickerDialogState
    extends State<_CellBackgroundColorPickerDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    if (widget.initialColor != null) {
      _hsv = HSVColor.fromColor(Color(widget.initialColor!));
    } else {
      _hsv = HSVColor.fromColor(Colors.yellow);
    }
  }

  Color get _selectedColor => _hsv.toColor();

  int get _selectedArgb {
    final color = _selectedColor;
    return 0xFF000000 |
        ((color.r * 255.0).round().clamp(0, 255) << 16) |
        ((color.g * 255.0).round().clamp(0, 255) << 8) |
        (color.b * 255.0).round().clamp(0, 255);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('セル背景色'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('プレビュー', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline),
              ),
            ),
            const SizedBox(height: 16),
            Text('色相', style: theme.textTheme.labelLarge),
            Slider(
              value: _hsv.hue,
              min: 0,
              max: 360,
              divisions: 360,
              label: _hsv.hue.round().toString(),
              onChanged: (value) {
                setState(() {
                  _hsv = _hsv.withHue(value);
                });
              },
            ),
            Text('彩度', style: theme.textTheme.labelLarge),
            Slider(
              value: _hsv.saturation,
              min: 0.05,
              max: 1,
              divisions: 95,
              label: (_hsv.saturation * 100).round().toString(),
              onChanged: (value) {
                setState(() {
                  _hsv = _hsv.withSaturation(value);
                });
              },
            ),
            Text('明度', style: theme.textTheme.labelLarge),
            Slider(
              value: _hsv.value,
              min: 0.05,
              max: 1,
              divisions: 95,
              label: (_hsv.value * 100).round().toString(),
              onChanged: (value) {
                setState(() {
                  _hsv = _hsv.withValue(value);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const CellBackgroundColorPickerSelected(null),
          ),
          child: const Text('色なし'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const CellBackgroundColorPickerCancelled(),
          ),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            CellBackgroundColorPickerSelected(_selectedArgb),
          ),
          child: const Text('決定'),
        ),
      ],
    );
  }
}
