import 'dart:ui';

/// Paints pre-authored vector glyphs into a cell [contentRect].
///
/// Paths are authored in a fixed [viewBox] and scaled uniformly to the cell.
/// Color and stroke width are applied at paint time (not baked into the path).
class StitchVectorPainter {
  const StitchVectorPainter();

  void paint({
    required Canvas canvas,
    required Rect contentRect,
    required Size viewBox,
    required List<StitchVectorLayer> layers,
    required Color color,
    required double strokeWidth,
  }) {
    if (viewBox.width <= 0 || viewBox.height <= 0) {
      return;
    }

    final scale = contentRect.shortestSide /
        (viewBox.width < viewBox.height ? viewBox.width : viewBox.height);
    final drawnW = viewBox.width * scale;
    final drawnH = viewBox.height * scale;
    final origin = Offset(
      contentRect.center.dx - drawnW / 2,
      contentRect.center.dy - drawnH / 2,
    );

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Stroke width is screen pixels; divide by scale inside the transform.
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale, scale);
    for (final layer in layers) {
      canvas.drawPath(layer.buildPath(), layer.filled ? fill : stroke);
    }
    canvas.restore();
  }
}

class StitchVectorLayer {
  const StitchVectorLayer.stroke(this.buildPath) : filled = false;
  const StitchVectorLayer.fill(this.buildPath) : filled = true;

  final Path Function() buildPath;
  final bool filled;
}
