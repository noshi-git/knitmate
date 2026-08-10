import 'dart:async';

import 'package:flutter/material.dart';

import '../models/stitch_definition.dart';
import '../models/stitch_symbol_type.dart';
import '../painters/stitch_symbol/stitch_symbol_display_scale.dart';
import '../painters/stitch_symbol/stitch_symbol_image_cache.dart';
import '../painters/stitch_symbol/stitch_symbol_painter.dart';

// 設定画面などで使う編み記号プレビュー（公式は PNG、unknown のみ文字）
class StitchSymbolPreview extends StatefulWidget {
  const StitchSymbolPreview({
    super.key,
    required this.definition,
    this.size = const Size(32, 32),
    this.color,
    this.displayScale = StitchSymbolDisplayScale.preview,
  });

  final StitchDefinition definition;
  final Size size;
  final Color? color;
  final double displayScale;

  @override
  State<StitchSymbolPreview> createState() => _StitchSymbolPreviewState();
}

class _StitchSymbolPreviewState extends State<StitchSymbolPreview> {
  @override
  void initState() {
    super.initState();
    final type = StitchSymbolTypeMapper.fromId(widget.definition.id);
    if (StitchSymbolTypeMapper.hasOfficialImageAsset(type)) {
      StitchSymbolImageCache.addOnLoadedListener(_onSymbolImageLoaded);
      if (!StitchSymbolImageCache.isLoaded(type)) {
        unawaited(StitchSymbolImageCache.ensureLoaded(type));
      }
    }
  }

  void _onSymbolImageLoaded() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.color ?? Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: CustomPaint(
        painter: _StitchSymbolPreviewPainter(
          definition: widget.definition,
          color: foreground,
          displayScale: widget.displayScale,
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                height: 1.0,
              ),
        ),
      ),
    );
  }
}

class _StitchSymbolPreviewPainter extends CustomPainter {
  _StitchSymbolPreviewPainter({
    required this.definition,
    required this.color,
    required this.displayScale,
    required this.textStyle,
  });

  final StitchDefinition definition;
  final Color color;
  final double displayScale;
  final TextStyle? textStyle;

  static const _symbolPainter = StitchSymbolPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cellRect = Offset.zero & size;
    final type = StitchSymbolTypeMapper.fromId(definition.id);

    if (type == StitchSymbolType.empty) {
      return;
    }

    if (type != StitchSymbolType.unknown) {
      _symbolPainter.paint(
        canvas: canvas,
        cellRect: cellRect,
        type: type,
        color: color,
        displayScale: displayScale,
      );
      return;
    }

    if (definition.symbol.isEmpty) {
      return;
    }

    final style = (textStyle ?? const TextStyle()).copyWith(
      fontSize: size.shortestSide * 0.45,
      color: color,
      height: 1.0,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: definition.symbol, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _StitchSymbolPreviewPainter oldDelegate) {
    return oldDelegate.definition.id != definition.id ||
        oldDelegate.definition.symbol != definition.symbol ||
        oldDelegate.color != color ||
        oldDelegate.displayScale != displayScale ||
        oldDelegate.textStyle != textStyle;
  }
}
