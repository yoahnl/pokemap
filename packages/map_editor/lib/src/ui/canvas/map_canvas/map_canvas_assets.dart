part of 'package:map_editor/src/ui/canvas/map_canvas.dart';

/// Helpers I/O et cache déplacés hors du shell principal du canvas pour garder
/// le fichier centré sur le widget et le flux d'interaction.
class _ResolvedTerrainFrame {
  const _ResolvedTerrainFrame({
    required this.tilesetId,
    required this.source,
  });

  final String tilesetId;
  final TilesetSourceRect source;
}

/// Cache image volontairement local au canvas éditeur.
///
/// On ne change pas son comportement ici : le but du lot est seulement de
/// sortir le détail de chargement du gros fichier UI principal.
class _TilesetImageCache {
  static final Map<String, Future<ui.Image?>> _cache = {};

  static Future<ui.Image?> load(
    String? path, {
    TilesetTransparentColor? transparentColor,
  }) {
    if (path == null || path.isEmpty) return Future.value(null);
    final cacheKey = '$path#${transparentColor?.toHexRgb() ?? ''}';
    return _cache.putIfAbsent(cacheKey, () async {
      try {
        final file = File(path);
        if (!await file.exists()) return null;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) return null;
        var displayBytes = bytes;
        if (transparentColor != null) {
          try {
            displayBytes = applyTilesetTransparentColorToPngBytes(
              imageBytes: bytes,
              transparentColor: transparentColor,
            );
          } catch (_) {
            displayBytes = bytes;
          }
        }
        final codec = await ui.instantiateImageCodec(displayBytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (_) {
        return null;
      }
    });
  }

  static Future<Map<String, ui.Image?>> loadMany(
    Map<String, String> paths, {
    Map<String, TilesetTransparentColor> transparentColorByTilesetId = const {},
  }) {
    final futures = <Future<MapEntry<String, ui.Image?>>>[];
    paths.forEach((tilesetId, path) {
      futures.add(
        load(
          path,
          transparentColor: transparentColorByTilesetId[tilesetId],
        ).then((image) => MapEntry(tilesetId, image)),
      );
    });
    return Future.wait(futures).then((entries) {
      final result = <String, ui.Image?>{};
      for (final entry in entries) {
        result[entry.key] = entry.value;
      }
      return result;
    });
  }
}
