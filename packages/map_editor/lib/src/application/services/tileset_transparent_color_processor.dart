import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

Uint8List applyTilesetTransparentColorToPngBytes({
  required Uint8List imageBytes,
  required TilesetTransparentColor? transparentColor,
}) {
  if (transparentColor == null) {
    return imageBytes;
  }

  final image = img.decodePng(imageBytes);
  if (image == null) {
    throw ArgumentError.value(
      imageBytes,
      'imageBytes',
      'Tileset transparent color processor expected valid PNG bytes.',
    );
  }

  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      final pixel = image.getPixel(x, y);
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();

      if (transparentColor.matchesRgb(red: red, green: green, blue: blue)) {
        image.setPixelRgba(x, y, red, green, blue, 0);
      }
    }
  }

  return img.encodePng(image);
}
