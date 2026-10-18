import 'dart:typed_data';

import 'package:image/image.dart' as image;

Uint8List syntheticPokemonMediaPng({int seed = 1}) {
  final pixels = image.Image(width: 32, height: 32, numChannels: 4);
  for (var y = 4; y < 28; y += 1) {
    for (var x = 4; x < 28; x += 1) {
      pixels.setPixelRgba(
        x,
        y,
        (x * 7 + seed) % 256,
        (y * 9 + seed) % 256,
        (x + y + seed * 17) % 256,
        255,
      );
    }
  }
  return image.encodePng(pixels);
}
