import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List applyTiledTsxTransparentColorToPngBytes({
  required Uint8List imageBytes,
  required String? transparentColor,
}) {
  final rgb = parseTiledTsxTransparentColor(transparentColor);
  if (rgb == null) {
    return imageBytes;
  }
  try {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return imageBytes;
    }
    final output = decoded.convert(numChannels: 4);
    for (var y = 0; y < output.height; y++) {
      for (var x = 0; x < output.width; x++) {
        final pixel = output.getPixel(x, y);
        if (pixel.r.toInt() == rgb.red &&
            pixel.g.toInt() == rgb.green &&
            pixel.b.toInt() == rgb.blue) {
          output.setPixelRgba(x, y, rgb.red, rgb.green, rgb.blue, 0);
        }
      }
    }
    return Uint8List.fromList(img.encodePng(output));
  } catch (_) {
    return imageBytes;
  }
}

TiledTsxRgbColor? parseTiledTsxTransparentColor(String? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.trim();
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(normalized)) {
    return null;
  }
  return TiledTsxRgbColor(
    red: int.parse(normalized.substring(0, 2), radix: 16),
    green: int.parse(normalized.substring(2, 4), radix: 16),
    blue: int.parse(normalized.substring(4, 6), radix: 16),
  );
}

bool isValidTiledTsxTransparentColor(String? value) =>
    value == null || parseTiledTsxTransparentColor(value) != null;

String formatTiledTsxTransparentColor(String? value) {
  final rgb = parseTiledTsxTransparentColor(value);
  if (rgb == null) {
    return 'aucune';
  }
  return '#${rgb.hex}';
}

final class TiledTsxRgbColor {
  const TiledTsxRgbColor({
    required this.red,
    required this.green,
    required this.blue,
  });

  final int red;
  final int green;
  final int blue;

  String get hex => '${_twoDigit(red)}${_twoDigit(green)}${_twoDigit(blue)}';
}

String _twoDigit(int value) =>
    value.toRadixString(16).padLeft(2, '0').toUpperCase();
