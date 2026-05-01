import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'runtime_tileset_image.dart';

Future<ui.Image> loadImageFromFilePath(String absolutePath) async {
  final file = File(absolutePath);
  if (!await file.exists()) {
    throw AssetNotFoundException('Image not found: $absolutePath');
  }
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<RuntimeTilesetImage> loadTilesetImageFromFilePath(
  String absolutePath, {
  TilesetTransparentColor? transparentColor,
}) async {
  final file = File(absolutePath);
  if (!await file.exists()) {
    throw AssetNotFoundException('Image not found: $absolutePath');
  }
  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    final image = await loadImageFromFilePath(absolutePath);
    return RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: buildRuntimeTilesetChunks(
        totalWidth: image.width,
        totalHeight: image.height,
      ),
      width: image.width,
      height: image.height,
    );
  }

  final displayImage = _applyTransparentColor(
    decoded,
    transparentColor: transparentColor,
  );
  final displayBytes = transparentColor == null
      ? bytes
      : Uint8List.fromList(img.encodePng(displayImage, level: 0));

  final chunks = buildRuntimeTilesetChunks(
    totalWidth: displayImage.width,
    totalHeight: displayImage.height,
  );
  if (chunks.length <= 1) {
    final image = await _decodeUiImageFromBytes(displayBytes);
    return RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: chunks,
      width: displayImage.width,
      height: displayImage.height,
    );
  }

  final images = <ui.Image>[];
  for (final chunk in chunks) {
    final cropped = img.copyCrop(
      displayImage,
      x: 0,
      y: chunk.top,
      width: chunk.width,
      height: chunk.height,
    );
    final chunkBytes = Uint8List.fromList(img.encodePng(cropped, level: 0));
    images.add(await _decodeUiImageFromBytes(chunkBytes));
  }
  return RuntimeTilesetImage(
    images: images,
    chunks: chunks,
    width: displayImage.width,
    height: displayImage.height,
  );
}

img.Image _applyTransparentColor(
  img.Image source, {
  required TilesetTransparentColor? transparentColor,
}) {
  if (transparentColor == null) {
    return source;
  }
  final image = source.hasAlpha
      ? img.Image.from(source)
      : source.convert(
          numChannels: 4,
          alpha: 255,
        );
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
  return image;
}

Future<ui.Image> _decodeUiImageFromBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<Map<String, RuntimeTilesetImage>> loadTilesetImagesById(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId = const {},
}) async {
  final out = <String, RuntimeTilesetImage>{};
  for (final e in absolutePathByTilesetId.entries) {
    out[e.key] = await loadTilesetImageFromFilePath(
      e.value,
      transparentColor: transparentColorByTilesetId[e.key],
    );
  }
  return out;
}
