part of '../map_canvas.dart';

/// Collects every visual asset needed by the active map and its first-level
/// connection previews without loading the same resource twice.
Map<String, String> collectMapCanvasTilesetPaths({
  required Iterable<MapData> maps,
  required String? Function(String tilesetId) resolveTilesetAbsolutePath,
  required String? activeBrushTilesetId,
  required ProjectManifest? project,
  required String? projectRootPath,
  required MapData? activeMap,
  required BorderPreviewTransaction? borderPreview,
}) {
  final mapList = maps.toList(growable: false);
  final result = <String, String>{};
  for (final map in mapList) {
    collectTilesetIdsForEntityEditorVisuals(
      map: map,
      project: project,
      onTilesetId: (tilesetId) {
        if (result.containsKey(tilesetId)) return;
        final assetPath = resolveTilesetAbsolutePath(tilesetId);
        if (assetPath != null && assetPath.isNotEmpty) {
          result[tilesetId] = assetPath;
        }
      },
    );
    final literalVisualTilesetIds = <String>{
      for (final layer in map.layers.whereType<TileLayer>())
        for (final entry in layer.palette) entry.tilesetId,
      for (final layer in map.layers.whereType<ObjectLayer>())
        for (final object in layer.tileObjects) object.tile.tilesetId,
    };
    for (final tilesetId in literalVisualTilesetIds) {
      if (result.containsKey(tilesetId)) continue;
      ProjectTilesetEntry? tileset;
      for (final candidate
          in project?.tilesets ?? const <ProjectTilesetEntry>[]) {
        if (candidate.id == tilesetId) {
          tileset = candidate;
          break;
        }
      }
      final source = tileset?.source;
      if (source is ProjectImageCollectionTilesetSource &&
          projectRootPath != null &&
          projectRootPath.trim().isNotEmpty) {
        for (final page in source.pages) {
          result[page.assetId] = p.normalize(
            p.join(
              projectRootPath,
              tileset!.relativePath,
              '${page.id}.png',
            ),
          );
        }
        continue;
      }
      final assetPath = resolveTilesetAbsolutePath(tilesetId);
      if (assetPath != null && assetPath.isNotEmpty) {
        result[tilesetId] = assetPath;
      }
    }
  }

  if (mapList.isNotEmpty) {
    for (final atlas in project?.smartTileCatalog.atlases ??
        const <ProjectSmartTileAtlas>[]) {
      final tilesetId = atlas.tilesetId.trim();
      if (tilesetId.isEmpty || result.containsKey(tilesetId)) continue;
      final assetPath = resolveTilesetAbsolutePath(tilesetId);
      if (assetPath != null && assetPath.isNotEmpty) {
        result[tilesetId] = assetPath;
      }
    }
  }

  if (activeBrushTilesetId != null &&
      !result.containsKey(activeBrushTilesetId)) {
    final brushPath = resolveTilesetAbsolutePath(activeBrushTilesetId);
    if (brushPath != null && brushPath.isNotEmpty) {
      result[activeBrushTilesetId] = brushPath;
    }
  }

  final borderSnapshotIds = <String>{};
  for (final map in mapList) {
    for (final layer in map.layers.whereType<BorderLayer>()) {
      for (final feature in layer.content.features) {
        final materialization = feature.materialization;
        if (materialization == null) continue;
        borderSnapshotIds.addAll(
          materialization.ground.map((cell) => cell.visualSnapshotId),
        );
        borderSnapshotIds.addAll(
          materialization.placements
              .map((placement) => placement.visualSnapshotId),
        );
      }
    }
  }
  final previewMaterialization = activeMap == null
      ? null
      : editorBorderPreviewMaterializationForMap(
          map: activeMap,
          preview: borderPreview,
        );
  if (previewMaterialization != null) {
    borderSnapshotIds.addAll(
      previewMaterialization.ground.map((cell) => cell.visualSnapshotId),
    );
    borderSnapshotIds.addAll(
      previewMaterialization.placements
          .map((placement) => placement.visualSnapshotId),
    );
  }
  final borderCatalog = project?.borderCatalog;
  if (borderCatalog != null) {
    for (final snapshotId in borderSnapshotIds) {
      final snapshot = borderCatalog.visualSnapshotById(snapshotId);
      if (snapshot == null) continue;
      for (var index = 0; index < snapshot.frames.length; index += 1) {
        final relativePath = snapshot.frames[index].relativeAssetPath;
        final absolutePath = p.isAbsolute(relativePath)
            ? p.normalize(relativePath)
            : projectRootPath == null || projectRootPath.trim().isEmpty
                ? null
                : p.normalize(p.join(projectRootPath, relativePath));
        if (absolutePath != null) {
          result[editorBorderFrameImageKey(snapshot.id, index)] = absolutePath;
        }
      }
    }
  }
  return result;
}
