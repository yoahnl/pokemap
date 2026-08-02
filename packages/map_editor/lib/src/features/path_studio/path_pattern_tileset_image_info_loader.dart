import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../ui/assets/editor_image_cache.dart';
import 'path_pattern_asset_diagnostics.dart';

/// Charge les dimensions et statuts d’image pour chaque [ProjectTilesetEntry] du manifest.
///
Future<Map<String, PathPatternTilesetImageInfo>>
    loadPathPatternTilesetImageInfoMap({
  required String projectRootPath,
  required ProjectManifest manifest,
  EditorImageCache? imageCache,
}) async {
  final root = projectRootPath.trim();
  if (root.isEmpty) {
    return {};
  }

  final ownsCache = imageCache == null;
  final cache = imageCache ??
      EditorImageCache(
        sessionKey: root,
        retirementScheduler: (disposeImage) => disposeImage(),
      );
  try {
    final infos = await Future.wait(
      manifest.tilesets.map((entry) async {
        final id = entry.id.trim();
        if (id.isEmpty) return null;
        final absolutePath = p.normalize(p.join(root, entry.relativePath));
        final loaded = await cache.load(
          absolutePath,
          variantKey: 'path-pattern:image-info',
        );
        try {
          final image = loaded.image;
          if (image != null) {
            return MapEntry(
              id,
              PathPatternTilesetImageInfo(
                tilesetId: id,
                status: PathPatternTilesetImageStatus.ok,
                widthPx: image.width,
                heightPx: image.height,
              ),
            );
          }
          final missing =
              loaded.failure?.kind == EditorImageFailureKind.missingFile;
          return MapEntry(
            id,
            PathPatternTilesetImageInfo(
              tilesetId: id,
              status: missing
                  ? PathPatternTilesetImageStatus.missingFile
                  : PathPatternTilesetImageStatus.unreadable,
              message: missing ? 'missing' : 'decode',
            ),
          );
        } finally {
          loaded.dispose();
        }
      }),
    );
    return Map.fromEntries(
        infos.whereType<MapEntry<String, PathPatternTilesetImageInfo>>());
  } finally {
    if (ownsCache) cache.dispose();
  }
}
