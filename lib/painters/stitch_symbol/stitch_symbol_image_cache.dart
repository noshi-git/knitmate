import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/stitch_symbol_type.dart';
import 'stitch_symbol_assets.dart';
import 'stitch_symbol_metrics.dart';

/// 公式36記号 PNG の読み込みと描画。
class StitchSymbolImageCache {
  StitchSymbolImageCache._();

  static final Map<String, ui.Image> _images = {};
  static final Map<String, Future<void>> _loadFutures = {};
  static final List<VoidCallback> _onLoadedCallbacks = [];

  static Future<void> ensureLoaded(StitchSymbolType type) {
    final assetPath = StitchSymbolAssets.assetPathFor(type);
    if (assetPath == null) {
      return Future<void>.value();
    }
    if (_images.containsKey(assetPath)) {
      return Future<void>.value();
    }
    return _loadFutures[assetPath] ??= _loadImage(assetPath);
  }

  static void addOnLoadedListener(VoidCallback callback) {
    _onLoadedCallbacks.add(callback);
  }

  static bool isLoaded(StitchSymbolType type) {
    final assetPath = StitchSymbolAssets.assetPathFor(type);
    return assetPath != null && _images.containsKey(assetPath);
  }

  static Future<void> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _images[assetPath] = frame.image;
    _loadFutures.remove(assetPath);
    _notifyLoaded();
  }

  static void _notifyLoaded() {
    final callbacks = List<VoidCallback>.from(_onLoadedCallbacks);
    _onLoadedCallbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }

  static bool paint({
    required Canvas canvas,
    required Rect cellRect,
    required StitchSymbolType type,
    required Color color,
    double displayScale = 1.0,
    FilterQuality filterQuality = FilterQuality.medium,
  }) {
    final assetPath = StitchSymbolAssets.assetPathFor(type);
    if (assetPath == null) {
      return false;
    }

    final image = _images[assetPath];
    if (image == null) {
      return false;
    }

    final metrics = StitchSymbolMetrics.forCell(cellRect.shortestSide);
    final pad = cellRect.shortestSide * metrics.padding;
    final contentRect = Rect.fromLTRB(
      cellRect.left + pad,
      cellRect.top + pad,
      cellRect.right - pad,
      cellRect.bottom - pad,
    );

    final imageW = image.width.toDouble();
    final imageH = image.height.toDouble();
    if (imageW <= 0 || imageH <= 0 || contentRect.isEmpty) {
      return false;
    }

    final scale = _containScale(contentRect, imageW, imageH) * displayScale;
    final dstW = imageW * scale;
    final dstH = imageH * scale;
    final dstRect = Rect.fromCenter(
      center: contentRect.center,
      width: dstW,
      height: dstH,
    );

    final paint = Paint()
      ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn)
      ..filterQuality = filterQuality;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imageW, imageH),
      dstRect,
      paint,
    );
    return true;
  }

  static double _containScale(Rect contentRect, double imageW, double imageH) {
    if (contentRect.width <= 0 || contentRect.height <= 0) {
      return 0;
    }
    return (contentRect.width / imageW) < (contentRect.height / imageH)
        ? contentRect.width / imageW
        : contentRect.height / imageH;
  }
}
