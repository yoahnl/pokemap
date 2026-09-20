import 'package:image/image.dart' as image;

List<int> ui04TerrainAtlas() {
  final atlas = image.Image(width: 96, height: 96);
  for (var mask = 0; mask < 16; mask++) {
    final index = mask * 5 % 16;
    final left = index % 4 * 24, top = index ~/ 4 * 24;
    for (var y = 0; y < 24; y++) {
      for (var x = 0; x < 24; x++) {
        final road =
            (x >= 7 && x < 17 && y >= 7 && y < 17) ||
            (mask & 1 != 0 && x >= 7 && x < 17 && y < 17) ||
            (mask & 2 != 0 && y >= 7 && y < 17 && x >= 7) ||
            (mask & 4 != 0 && x >= 7 && x < 17 && y >= 7) ||
            (mask & 8 != 0 && y >= 7 && y < 17 && x < 17);
        final grain = (x * 7 + y * 11) % 13 < 3 ? 12 : 0;
        atlas.setPixelRgb(
          left + x,
          top + y,
          (road ? 194 : 61) + grain,
          (road ? 169 : 119) + grain,
          (road ? 117 : 72) + grain,
        );
      }
    }
  }
  return image.encodePng(atlas);
}
