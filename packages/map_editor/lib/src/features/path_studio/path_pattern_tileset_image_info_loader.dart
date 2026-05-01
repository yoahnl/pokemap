import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'path_pattern_asset_diagnostics.dart';

/// Charge les dimensions et statuts d’image pour chaque [ProjectTilesetEntry] du manifest.
///
/// Lot PathPattern-41 : adapter local synchrone, sans provider ni service global.
Map<String, PathPatternTilesetImageInfo> loadPathPatternTilesetImageInfoMap({
  required String projectRootPath,
  required ProjectManifest manifest,
}) {
  final root = projectRootPath.trim();
  if (root.isEmpty) {
    return {};
  }

  final result = <String, PathPatternTilesetImageInfo>{};
  for (final entry in manifest.tilesets) {
    final id = entry.id.trim();
    if (id.isEmpty) {
      continue;
    }
    final absolutePath = p.normalize(p.join(root, entry.relativePath));
    final file = File(absolutePath);
    if (!file.existsSync()) {
      result[id] = PathPatternTilesetImageInfo(
        tilesetId: id,
        status: PathPatternTilesetImageStatus.missingFile,
        message: 'missing',
      );
      continue;
    }
    try {
      final bytes = file.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        result[id] = PathPatternTilesetImageInfo(
          tilesetId: id,
          status: PathPatternTilesetImageStatus.unreadable,
          message: 'decode',
        );
      } else {
        result[id] = PathPatternTilesetImageInfo(
          tilesetId: id,
          status: PathPatternTilesetImageStatus.ok,
          widthPx: decoded.width,
          heightPx: decoded.height,
        );
      }
    } catch (_) {
      result[id] = PathPatternTilesetImageInfo(
        tilesetId: id,
        status: PathPatternTilesetImageStatus.unreadable,
        message: 'io',
      );
    }
  }
  return result;
}
