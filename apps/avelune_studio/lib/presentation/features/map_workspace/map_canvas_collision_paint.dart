part of 'map_canvas_overlay.dart';

extension _MapCanvasCollisionPaint on MapCanvasOverlay {
  void _paintCollisionCells(Canvas canvas) {
    final tint = collisionColor;
    if (tint == null) return;
    final clip = canvas.getLocalClipBounds();
    final fill = Paint()..color = tint.withValues(alpha: .3);
    final outline = Paint()
      ..color = tint.withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final layer in map.layers.whereType<CollisionLayer>()) {
      if (!layer.isVisible) continue;
      for (var index = 0; index < layer.collisions.length; index++) {
        if (!layer.collisions[index]) continue;
        final rect = Rect.fromLTWH(
          index.remainder(map.size.width) * cellWidth,
          (index ~/ map.size.width) * cellHeight,
          cellWidth,
          cellHeight,
        );
        if (!clip.overlaps(rect)) continue;
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect.deflate(.75), outline);
      }
    }
  }
}
