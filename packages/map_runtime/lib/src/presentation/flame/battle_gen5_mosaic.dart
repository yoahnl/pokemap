import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

void drawBattleGen5Mosaic(
  ui.Canvas canvas,
  ui.Image image,
  ui.Rect source,
  ui.Rect destination,
  ui.Paint paint,
  int level,
) {
  if (level < 0 || level > 15) {
    throw RangeError.range(level, 0, 15, 'level');
  }
  if (source.isEmpty || destination.isEmpty) return;
  if (level == 0) {
    canvas.drawImageRect(image, source, destination, paint);
    return;
  }

  final width = math.min(source.width, 128.0);
  final height = math.min(source.height, 128.0);
  final block = (level + 1).toDouble();
  final columns = (width / block).ceil();
  final rows = (height / block).ceil();
  final transforms = Float32List(columns * rows * 4);
  final rectangles = Float32List(columns * rows * 4);
  var index = 0;
  for (var row = 0; row < rows; row++) {
    final y = row * block;
    for (var column = 0; column < columns; column++) {
      final x = column * block;
      final sourceX = source.left + x * source.width / width;
      final sourceY = source.top + y * source.height / height;
      transforms[index] = block;
      transforms[index + 1] = 0;
      transforms[index + 2] = x;
      transforms[index + 3] = y;
      rectangles[index] = sourceX;
      rectangles[index + 1] = sourceY;
      rectangles[index + 2] = sourceX + 1;
      rectangles[index + 3] = sourceY + 1;
      index += 4;
    }
  }

  canvas.save();
  canvas.translate(destination.left, destination.top);
  canvas.scale(destination.width / width, destination.height / height);
  canvas.clipRect(ui.Rect.fromLTWH(0, 0, width, height));
  canvas.drawRawAtlas(image, transforms, rectangles, null, null, null, paint);
  canvas.restore();
}
