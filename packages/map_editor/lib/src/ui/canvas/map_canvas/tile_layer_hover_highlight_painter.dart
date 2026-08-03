part of 'package:map_editor/src/ui/canvas/map_canvas.dart';

final class TileLayerHoverHighlightPainter extends CustomPainter {
  const TileLayerHoverHighlightPainter({
    required this.layer,
    required this.mapSize,
    required this.zoom,
    required this.offset,
    required this.tileWidth,
    required this.tileHeight,
    required this.color,
  });

  final TileLayer layer;
  final GridSize mapSize;
  final double zoom;
  final Offset offset;
  final double tileWidth;
  final double tileHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final visibleBounds = resolveEditorMapVisibleCellBounds(
      viewportSize: size,
      mapSize: mapSize,
      zoom: zoom,
      offset: offset,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    final fill = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / zoom;

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(zoom);
    for (var y = visibleBounds.top; y < visibleBounds.bottom; y++) {
      final rowStart = y * mapSize.width;
      for (var x = visibleBounds.left; x < visibleBounds.right; x++) {
        final tileIndex = rowStart + x;
        if (tileIndex < 0 ||
            tileIndex >= layer.tiles.length ||
            layer.tiles[tileIndex] <= 0) {
          continue;
        }
        final rect = Rect.fromLTWH(
          x * tileWidth,
          y * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect.deflate(1 / zoom), outline);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TileLayerHoverHighlightPainter oldDelegate) {
    return oldDelegate.layer != layer ||
        oldDelegate.mapSize != mapSize ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.color != color;
  }
}
