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

  final output = image.hasAlpha
      ? img.Image.from(image)
      : image.convert(
          numChannels: 4,
          alpha: 255,
        );

  for (var y = 0; y < output.height; y += 1) {
    for (var x = 0; x < output.width; x += 1) {
      final pixel = output.getPixel(x, y);
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();

      if (transparentColor.matchesRgb(red: red, green: green, blue: blue)) {
        output.setPixelRgba(x, y, red, green, blue, 0);
      }
    }
  }

  return img.encodePng(output);
}
