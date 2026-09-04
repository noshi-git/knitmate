import 'package:flutter/material.dart';

import '../models/stitch_definition.dart';
import '../models/stitch_label_display_mode.dart';
import '../services/stitch_display_settings_service.dart';
import '../utils/stitch_display_name.dart';
import 'stitch_symbol_label.dart';

/// ボタン内側全周に沿った設定色の太い色帯を描画する。
class StitchSelectorColorBandPainter extends CustomPainter {
  StitchSelectorColorBandPainter({
    required this.ringColor,
    required this.surfaceColor,
    required this.ringWidth,
    required this.edgeInset,
    required this.isCircular,
  });

  final Color ringColor;
  final Color surfaceColor;
  final double ringWidth;
  final double edgeInset;
  final bool isCircular;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    if (isCircular) {
      _paintCircular(canvas, size);
      return;
    }
    _paintStadium(canvas, size);
  }

  void _paintCircular(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - edgeInset;
    if (outerRadius <= ringWidth) {
      return;
    }
    final innerRadius = outerRadius - ringWidth;

    canvas.drawCircle(center, innerRadius, Paint()..color = surfaceColor);

    final ringPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
      ..addOval(Rect.fromCircle(center: center, radius: innerRadius));
    canvas.drawPath(ringPath, Paint()..color = ringColor);
  }

  void _paintStadium(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      edgeInset,
      edgeInset,
      size.width - edgeInset * 2,
      size.height - edgeInset * 2,
    );
    if (rect.width <= 0 || rect.height <= 0) {
      return;
    }

    final cornerRadius = Radius.circular(rect.height / 2);
    final outerRRect = RRect.fromRectAndRadius(rect, cornerRadius);
    final innerRRect = outerRRect.deflate(ringWidth);
    if (innerRRect.width <= 0 || innerRRect.height <= 0) {
      return;
    }

    canvas.drawRRect(innerRRect, Paint()..color = surfaceColor);

    final ringPath = Path.combine(
      PathOperation.difference,
      Path()..addRRect(outerRRect),
      Path()..addRRect(innerRRect),
    );
    canvas.drawPath(ringPath, Paint()..color = ringColor);
  }

  @override
  bool shouldRepaint(covariant StitchSelectorColorBandPainter oldDelegate) {
    return ringColor != oldDelegate.ringColor ||
        surfaceColor != oldDelegate.surfaceColor ||
        ringWidth != oldDelegate.ringWidth ||
        edgeInset != oldDelegate.edgeInset ||
        isCircular != oldDelegate.isCircular;
  }
}

/// 編み図下部の編み記号選択ボタン。
class StitchSelectorButton extends StatelessWidget {
  const StitchSelectorButton({
    super.key,
    required this.definition,
    required this.selected,
    required this.displayMode,
    required this.onPressed,
  });

  final StitchDefinition definition;
  final bool selected;
  final StitchLabelDisplayMode displayMode;
  final VoidCallback onPressed;

  static const double ringWidth = 5;
  static const double ringEdgeInset = 1.5;

  /// 短い名称向けの円形判定（名称文字数）。
  static const int circularNameMaxLength = 6;

  /// 長い名称ボタンの名称折り返し上限。
  static const double longNameMaxWidth = 280;

  bool get _hasCellColor =>
      definition.cellBackgroundColor != null &&
      definition.storageIndex != StitchDefinition.emptyStorageIndex;

  /// 短い名称は円形、長い名称は横長スタジアム形。
  bool get usesCircularShape => _isCircularShape(displayMode, definition.name);

  static bool _isCircularShape(
    StitchLabelDisplayMode displayMode,
    String name,
  ) {
    if (displayMode == StitchLabelDisplayMode.symbolOnly) {
      return true;
    }
    final parts = StitchDisplayName.split(name);
    if (parts.annotation != null) {
      return false;
    }
    return parts.mainName.characters.length <= circularNameMaxLength;
  }

  static OutlinedBorder buttonShapeFor({required bool circular}) {
    return circular ? const CircleBorder() : const StadiumBorder();
  }

  EdgeInsets _contentPadding({required bool compactLabel}) {
    return EdgeInsets.symmetric(
      horizontal: compactLabel ? 10 : 12,
      vertical: compactLabel ? 8 : 10,
    );
  }

  ButtonStyle _sharedStyle({
    required bool compactLabel,
    required bool circular,
  }) {
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      shape: WidgetStatePropertyAll(buttonShapeFor(circular: circular)),
      alignment: Alignment.center,
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const WidgetStatePropertyAll(Size.zero),
    );
  }

  ButtonStyle _coloredStyle({
    required ButtonStyle base,
    required ColorScheme colorScheme,
    required bool selected,
  }) {
    return base.copyWith(
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: selected
          ? WidgetStatePropertyAll(
              colorScheme.primary.withValues(alpha: 0.28),
            )
          : null,
      elevation: selected ? const WidgetStatePropertyAll(2) : null,
      side: WidgetStatePropertyAll(
        BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outline,
          width: selected ? 2.5 : 1,
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, Color foreground) {
    final compactLabel = displayMode == StitchLabelDisplayMode.symbolOnly;
    final circular = usesCircularShape;

    return StitchSymbolLabel(
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
      maxNameWidth: circular ? null : longNameMaxWidth,
      wrapName: !circular,
    );
  }

  double _circularContentSide({required bool compactLabel}) {
    final padding = _contentPadding(compactLabel: compactLabel);
    final symbolSize = compactLabel ? 32.0 : 34.0;
    if (compactLabel) {
      return symbolSize + padding.vertical;
    }
    const nameLineHeight = 18.0;
    const spacing = 5.0;
    return symbolSize + spacing + nameLineHeight + padding.vertical;
  }

  /// ラベルに padding を付け、短い名称は 1:1 の正方形に揃える。
  Widget _buildSizedContent({
    required Widget label,
    required bool circular,
    required EdgeInsets contentPadding,
  }) {
    if (!circular) {
      return IntrinsicWidth(
        child: Padding(
          padding: contentPadding,
          child: label,
        ),
      );
    }

    final side = _circularContentSide(
      compactLabel: displayMode == StitchLabelDisplayMode.symbolOnly,
    );
    return SizedBox(
      width: side,
      height: side,
      child: Padding(
        padding: contentPadding,
        child: Center(child: label),
      ),
    );
  }

  Widget _buildSelectedBadge(ColorScheme colorScheme, bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          Icons.check,
          size: 12,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildShortcutKeyBadge(
    String shortcutKey,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
            blurRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          shortcutKey,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _wrapWithShortcutBadge(
    Widget button,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final shortcutKey = definition.shortcutKey;
    if (shortcutKey == null) {
      return button;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: 2,
          left: 2,
          child: KeyedSubtree(
            key: const Key('stitch_selector_shortcut_badge'),
            child: _buildShortcutKeyBadge(shortcutKey, colorScheme, isDark),
          ),
        ),
      ],
    );
  }

  Widget _wrapWithColorBand({
    required ColorScheme colorScheme,
    required bool circular,
    required EdgeInsets contentPadding,
    required Widget content,
    required bool isDark,
  }) {
    final settingColor = Color(definition.cellBackgroundColor!);

    final bandStack = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: CustomPaint(
            key: const Key('stitch_selector_color_ring'),
            painter: StitchSelectorColorBandPainter(
              ringColor: settingColor,
              surfaceColor: colorScheme.surface,
              ringWidth: ringWidth,
              edgeInset: ringEdgeInset,
              isCircular: circular,
            ),
          ),
        ),
        content,
      ],
    );

    if (!selected) {
      return bandStack;
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        bandStack,
        Positioned(
          top: 2,
          right: 2,
          child: _buildSelectedBadge(colorScheme, isDark),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final compactLabel = displayMode == StitchLabelDisplayMode.symbolOnly;
    final circular = usesCircularShape;
    final contentPadding = _contentPadding(compactLabel: compactLabel);
    final style = _sharedStyle(compactLabel: compactLabel, circular: circular);
    final key = ValueKey('stitch_selector_${definition.storageIndex}');

    final labelForeground = (!_hasCellColor && selected)
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final label = _buildLabel(context, labelForeground);

    var child = _buildSizedContent(
      label: label,
      circular: circular,
      contentPadding: contentPadding,
    );

    if (_hasCellColor) {
      child = _wrapWithColorBand(
        colorScheme: colorScheme,
        circular: circular,
        contentPadding: contentPadding,
        content: child,
        isDark: isDark,
      );

      return _wrapWithShortcutBadge(
        _shrinkWrap(
          OutlinedButton(
            key: key,
            onPressed: onPressed,
            style: _coloredStyle(
              base: style,
              colorScheme: colorScheme,
              selected: selected,
            ),
            child: child,
          ),
        ),
        colorScheme,
        isDark,
      );
    }

    if (selected) {
      return _wrapWithShortcutBadge(
        _shrinkWrap(
          FilledButton(
            key: key,
            onPressed: onPressed,
            style: style,
            child: child,
          ),
        ),
        colorScheme,
        isDark,
      );
    }

    return _wrapWithShortcutBadge(
      _shrinkWrap(
        OutlinedButton(
          key: key,
          onPressed: onPressed,
          style: style,
          child: child,
        ),
      ),
      colorScheme,
      isDark,
    );
  }

  /// Wrap 内で親の最大幅まで広がらないよう intrinsic サイズに収める。
  Widget _shrinkWrap(Widget button) {
    return Align(
      alignment: Alignment.center,
      widthFactor: 1,
      heightFactor: 1,
      child: button,
    );
  }
}
