import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

/// Where a single Smart Tile sprite lives on disk.
///
/// This is the seam between the canonical catalog and the editor image cache:
/// it joins a frame reference to its atlas geometry and to the tileset file,
/// without performing any I/O. Decoding stays the cache's responsibility.
final class SmartTileSpriteSource {
  const SmartTileSpriteSource({
    required this.absolutePath,
    required this.sourceRect,
  });

  final String absolutePath;
  final SmartTileSourceRect sourceRect;
}

/// Resolves the file and source rectangle backing [frame], or null when the
/// catalog, the tileset registry or the project root cannot satisfy it.
SmartTileSpriteSource? resolveSmartTileSpriteSource({
  required SmartTileFrameRef frame,
  required Iterable<ProjectSmartTileAtlas> atlases,
  required Iterable<ProjectTilesetEntry> tilesets,
  required String? projectRootPath,
}) {
  final root = projectRootPath?.trim();
  if (root == null || root.isEmpty) return null;

  final atlas = atlases.where((entry) => entry.id == frame.atlasId).firstOrNull;
  if (atlas == null) return null;

  final tileset =
      tilesets.where((entry) => entry.id == atlas.tilesetId).firstOrNull;
  if (tileset == null) return null;

  // Mirrors the containment policy of FileSmartTileAtlasImageLoader: a tileset
  // must stay inside the project. Without this, "../.." in a manifest would
  // resolve to an arbitrary file on the host.
  final relativePath = tileset.relativePath.trim();
  if (relativePath.isEmpty || p.isAbsolute(relativePath)) return null;
  final normalizedRoot = p.normalize(p.absolute(root));
  final absolutePath = p.normalize(p.join(normalizedRoot, relativePath));
  if (!p.isWithin(normalizedRoot, absolutePath)) return null;

  final SmartTileSourceRect sourceRect;
  try {
    sourceRect = atlas.sourceRectFor(
      column: frame.column,
      row: frame.row,
      columnSpan: frame.columnSpan,
      rowSpan: frame.rowSpan,
    );
  } on RangeError {
    return null;
  }

  return SmartTileSpriteSource(
    absolutePath: absolutePath,
    sourceRect: sourceRect,
  );
}
