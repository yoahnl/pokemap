import 'dart:io';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

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

Future<Map<String, ui.Image>> loadTilesetImagesById(
  Map<String, String> absolutePathByTilesetId,
) async {
  final out = <String, ui.Image>{};
  for (final e in absolutePathByTilesetId.entries) {
    out[e.key] = await loadImageFromFilePath(e.value);
  }
  return out;
}
