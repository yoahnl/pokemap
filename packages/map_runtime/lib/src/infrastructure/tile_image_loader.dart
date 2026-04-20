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
  String absolutePath,
) async {
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

  final chunks = buildRuntimeTilesetChunks(
    totalWidth: decoded.width,
    totalHeight: decoded.height,
  );
  if (chunks.length <= 1) {
    final image = await _decodeUiImageFromBytes(bytes);
    return RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: chunks,
      width: decoded.width,
      height: decoded.height,
    );
  }

  final images = <ui.Image>[];
  for (final chunk in chunks) {
    final cropped = img.copyCrop(
      decoded,
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
    width: decoded.width,
    height: decoded.height,
  );
}

Future<ui.Image> _decodeUiImageFromBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

Future<Map<String, RuntimeTilesetImage>> loadTilesetImagesById(
  Map<String, String> absolutePathByTilesetId,
) async {
  final out = <String, RuntimeTilesetImage>{};
  for (final e in absolutePathByTilesetId.entries) {
    out[e.key] = await loadTilesetImageFromFilePath(e.value);
  }
  return out;
}
