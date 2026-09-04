import 'package:flutter/material.dart';

import '../models/stitch_definition.dart';
import '../models/stitch_label_display_mode.dart';
import '../models/stitch_symbol_type.dart';
import '../utils/stitch_display_name.dart';
import '../painters/stitch_symbol/stitch_symbol_display_scale.dart';
import 'stitch_symbol_preview.dart';

// シンボル / 名前を表示モードに応じて並べる共通ラベル
// Step2〜の全公式ベクター記号でも同じレイアウトで利用できる
class StitchSymbolLabel extends StatelessWidget {
  const StitchSymbolLabel({
    super.key,
    required this.definition,
    required this.displayMode,
    this.color,
    this.symbolExtent = 38,
    this.symbolDisplayScale = StitchSymbolDisplayScale.preview,
    this.nameStyle,
    this.spacing = 6,
    this.maxNameWidth,
    this.wrapName = false,
  });

  final StitchDefinition definition;
  final StitchLabelDisplayMode displayMode;
  final Color? color;
  final double symbolExtent;
  final double symbolDisplayScale;
  final TextStyle? nameStyle;
  final double spacing;

  /// 名前の折り返し上限。null のときは画面幅の約28%を使う
  final double? maxNameWidth;

  /// true のとき maxNameWidth 内で複数行折り返し（編み記号選択ボタン向け）
  final bool wrapName;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;
    final resolvedNameStyle = (nameStyle ??
            Theme.of(context).textTheme.labelMedium ??
            const TextStyle(fontSize: 12))
        .copyWith(
          color: foreground,
          height: 1.15,
        );

    final showSymbol = displayMode.showsSymbol;
    final showName = displayMode.showsName;

    final children = <Widget>[
      if (showSymbol) _buildSymbol(context, foreground),
      if (showSymbol && showName) SizedBox(height: spacing),
      if (showName) _buildName(context, resolvedNameStyle),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  Widget _buildSymbol(BuildContext context, Color foreground) {
    final type = StitchSymbolTypeMapper.fromId(definition.id);

    if (type == StitchSymbolType.empty) {
      return SizedBox(
        width: symbolExtent,
        height: symbolExtent,
        child: Center(
          child: Text(
            '—',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.55),
                  height: 1.0,
                ),
          ),
        ),
      );
    }

    return StitchSymbolPreview(
      definition: definition,
      size: Size(symbolExtent, symbolExtent),
      color: foreground,
      displayScale: symbolDisplayScale,
    );
  }

  Widget _buildName(BuildContext context, TextStyle style) {
    final width = maxNameWidth ?? MediaQuery.sizeOf(context).width * 0.28;
    final parts = StitchDisplayName.split(definition.name);
    final annotationStyle = style.copyWith(
      fontSize: (style.fontSize ?? 12) * 0.92,
    );

    if (wrapName) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              parts.mainName,
              textAlign: TextAlign.center,
              style: style,
              maxLines: 3,
              softWrap: true,
            ),
            if (parts.annotation != null) ...[
              const SizedBox(height: 1),
              Text(
                parts.annotation!,
                textAlign: TextAlign.center,
                style: annotationStyle,
                maxLines: 2,
                softWrap: true,
              ),
            ],
          ],
        ),
      );
    }

    // Always: mainName on one line, annotation on the next. No mid-word wrap.
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              parts.mainName,
              textAlign: TextAlign.center,
              style: style,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          if (parts.annotation != null) ...[
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                parts.annotation!,
                textAlign: TextAlign.center,
                style: annotationStyle,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
