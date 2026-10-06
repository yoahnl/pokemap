part of 'decor_collision_mask.dart';

class _CollisionOverlay extends CustomPainter {
  const _CollisionOverlay(this.mask, this.cursor, this.colors);
  final DecorCollisionMask mask;
  final GridPos? cursor;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = colors.error.withValues(alpha: .48);
    final pixels = mask.pixels;
    if (pixels != null && mask.maskWidth > 0) {
      for (var y = 0; y < size.height; y++) {
        var x = 0;
        while (x < size.width) {
          final index = y * mask.maskWidth + x;
          if (index >= pixels.length || !pixels[index]) {
            x++;
            continue;
          }
          final start = x++;
          while (x < size.width &&
              y * mask.maskWidth + x < pixels.length &&
              pixels[y * mask.maskWidth + x]) {
            x++;
          }
          canvas.drawRect(
            Rect.fromLTWH(
              start.toDouble(),
              y.toDouble(),
              (x - start).toDouble(),
              1,
            ),
            fill,
          );
        }
      }
    } else {
      for (final cell in mask.blocked) {
        canvas.drawRect(
          Rect.fromLTWH(
            (cell.x * mask.tileWidth).toDouble(),
            (cell.y * mask.tileHeight).toDouble(),
            mask.tileWidth.toDouble(),
            mask.tileHeight.toDouble(),
          ),
          fill,
        );
      }
    }
    final stroke = Paint()
      ..color = colors.primary.withValues(alpha: .55)
      ..strokeWidth = .25;
    for (var x = 0; x <= mask.width; x++) {
      canvas.drawLine(
        Offset((x * mask.tileWidth).toDouble(), 0),
        Offset((x * mask.tileWidth).toDouble(), size.height),
        stroke,
      );
    }
    for (var y = 0; y <= mask.height; y++) {
      canvas.drawLine(
        Offset(0, (y * mask.tileHeight).toDouble()),
        Offset(size.width, (y * mask.tileHeight).toDouble()),
        stroke,
      );
    }
    final target = cursor;
    if (target == null) return;
    final unitWidth = mask.fine ? 1 : mask.tileWidth;
    final unitHeight = mask.fine ? 1 : mask.tileHeight;
    final brush = mask.fine ? mask.brushSize : 1;
    final half = (brush - 1) ~/ 2;
    canvas.drawRect(
      Rect.fromLTWH(
        ((target.x - half) * unitWidth).toDouble(),
        ((target.y - half) * unitHeight).toDouble(),
        (brush * unitWidth).toDouble(),
        (brush * unitHeight).toDouble(),
      ),
      Paint()
        ..color = colors.primary
        ..strokeWidth = .35
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CollisionOverlay old) =>
      old.mask.revision != mask.revision ||
      old.mask.fine != mask.fine ||
      old.cursor != cursor ||
      old.mask.blocked != mask.blocked ||
      old.mask.erase != mask.erase ||
      old.mask.brushSize != mask.brushSize ||
      old.colors != colors;
}
