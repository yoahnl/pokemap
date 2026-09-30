import 'package:image/image.dart' as image;

List<int> createProjectStarterAtlas(int tileSize) {
  final atlas = image.Image(width: 256, height: 64, numChannels: 4);
  void rect(int x, int y, int w, int h, int r, int g, int b) {
    image.fillRect(atlas,
        x1: x,
        y1: y,
        x2: x + w - 1,
        y2: y + h - 1,
        color: image.ColorRgba8(r, g, b, 255));
  }

  rect(0, 0, 16, 16, 82, 132, 89);
  for (var y = 1; y < 16; y += 4) {
    for (var x = 1; x < 16; x += 5) {
      rect(x, y, 2, 1, 116, 164, 107);
    }
  }
  rect(16, 0, 16, 16, 194, 173, 126);
  rect(19, 5, 2, 1, 222, 202, 158);
  rect(27, 11, 3, 1, 168, 149, 106);
  for (var direction = 0; direction < 4; direction++) {
    for (var step = 0; step < 2; step++) {
      final x = (direction * 2 + step) * 32 + 8;
      rect(x + 4, 35, 8, 5, 40, 54, 75);
      rect(x + 5, 39, 6, 6, 222, 175, 138);
      rect(x + 4, 45, 8, 9, 43, 123, 148);
      rect(x + 3, 46, 2, 7, 222, 175, 138);
      rect(x + 11, 46, 2, 7, 222, 175, 138);
      rect(x + 5, 54, 3, 7 - step, 37, 49, 69);
      rect(x + 8, 54, 3, 6 + step, 37, 49, 69);
      if (direction != 1) {
        rect(x + (direction == 2 ? 5 : 9), 41, 1, 1, 28, 39, 53);
      }
    }
  }
  final scaled = tileSize == 16
      ? atlas
      : image.copyResize(atlas,
          width: atlas.width * tileSize ~/ 16,
          height: atlas.height * tileSize ~/ 16,
          interpolation: image.Interpolation.nearest);
  return image.encodePng(scaled);
}
