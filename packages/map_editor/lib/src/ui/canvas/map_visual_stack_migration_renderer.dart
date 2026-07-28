import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/services/tileset_transparent_color_processor.dart';
import '../../application/shadow/editor_shadow_light_preview.dart';
import '../../application/use_cases/map_visual_stack_migration_use_case.dart';
import '../../features/border_map_editing/presentation/border_preview_painter.dart';
import '../../features/surface_painter/surface_tile_preview_resolver.dart';
import 'entity_editor_element_visual.dart';
import 'map_canvas.dart';

const int defaultMapVisualStackMigrationMaxRenderedPixelCount = 16777216;
const int _comparisonYieldStride = 262144;

typedef MapVisualStackMigrationImageLoader = Future<Map<String, ui.Image?>>
    Function(
  Map<String, String> pathsById,
  Map<String, TilesetTransparentColor> transparentColorsById,
);

/// Real RGBA comparison seam used by the explicit visual-stack migration.
///
/// It invokes [MapGridPainter] with the same project assets and render inputs
/// as the editor canvas. Grid, collision, selection and authoring overlays are
/// deliberately excluded because they are outside the visual-stack contract.
final class MapGridPainterVisualStackMigrationComparator {
  MapGridPainterVisualStackMigrationComparator({
    required this.inputs,
    this.maxRenderedPixelCount =
        defaultMapVisualStackMigrationMaxRenderedPixelCount,
    MapVisualStackMigrationImageLoader? imageLoader,
  }) : _imageLoader = imageLoader ?? _loadImagesFromDisk;

  final MapVisualStackMigrationRenderInputs inputs;
  final int maxRenderedPixelCount;
  final MapVisualStackMigrationImageLoader _imageLoader;

  Future<MapVisualStackPixelComparison> compare({
    required MapData before,
    required MapData after,
  }) async {
    // Let the dialog mount its loading state before any synchronous painter
    // traversal starts.
    await Future<void>.delayed(Duration.zero);

    if (before.size != after.size) {
      throw StateError(
        'la migration ne peut pas comparer deux dimensions différentes',
      );
    }
    final dimensions = _resolveRenderDimensions(before);
    final renderedPixelCount = dimensions.width * dimensions.height;
    if (maxRenderedPixelCount <= 0 ||
        renderedPixelCount > maxRenderedPixelCount) {
      throw StateError(
        'le rendu réel contient $renderedPixelCount pixels, au-delà de la '
        'limite sûre de $maxRenderedPixelCount',
      );
    }

    final pathsById = _collectAssetPaths(inputs);
    final requiredAssetIds = <String>{
      ..._collectRequiredAssetIds(before, inputs),
      ..._collectRequiredAssetIds(after, inputs),
    };
    final missingPaths = requiredAssetIds
        .where((id) => !pathsById.containsKey(id))
        .toList(growable: false)
      ..sort();
    if (missingPaths.isNotEmpty) {
      throw StateError(
        'asset(s) de rendu sans chemin : ${missingPaths.join(', ')}',
      );
    }

    final requiredPathsById = <String, String>{
      for (final id in requiredAssetIds) id: pathsById[id]!,
    };
    final allTransparentColors = _collectTransparentColors(inputs.project);
    final requiredTransparentColors = <String, TilesetTransparentColor>{
      for (final id in requiredAssetIds)
        if (allTransparentColors[id] case final color?) id: color,
    };
    final loaded = await _imageLoader(
      requiredPathsById,
      requiredTransparentColors,
    );
    final missingImages = requiredAssetIds
        .where((id) => loaded[id] == null)
        .toList(growable: false)
      ..sort();
    if (missingImages.isNotEmpty) {
      _disposeImages(loaded.values);
      throw StateError(
        'asset(s) de rendu illisible(s) : ${missingImages.join(', ')}',
      );
    }

    ui.Image? beforeImage;
    ui.Image? afterImage;
    try {
      _validateTileSources(
        map: before,
        imagesById: loaded,
        settings: inputs.settings,
      );
      _validateTileSources(
        map: after,
        imagesById: loaded,
        settings: inputs.settings,
      );
      beforeImage = await _render(
        map: before,
        imagesById: loaded,
        dimensions: dimensions,
      );
      afterImage = await _render(
        map: after,
        imagesById: loaded,
        dimensions: dimensions,
      );
      return await _compareImages(
        before: beforeImage,
        after: afterImage,
        limitations: _comparisonLimitations(before, after),
      );
    } finally {
      beforeImage?.dispose();
      afterImage?.dispose();
      _disposeImages(loaded.values);
    }
  }

  ({int width, int height, double tileWidth, double tileHeight})
      _resolveRenderDimensions(MapData map) {
    final settings = inputs.settings;
    final tileWidth = settings.tileWidth * settings.displayScale;
    final tileHeight = settings.tileHeight * settings.displayScale;
    if (settings.tileWidth <= 0 ||
        settings.tileHeight <= 0 ||
        !tileWidth.isFinite ||
        !tileHeight.isFinite ||
        tileWidth <= 0 ||
        tileHeight <= 0) {
      throw StateError('les dimensions de tuile du projet sont invalides');
    }
    final width = (map.size.width * tileWidth).ceil();
    final height = (map.size.height * tileHeight).ceil();
    if (width <= 0 || height <= 0) {
      throw StateError('les dimensions du rendu réel sont invalides');
    }
    return (
      width: width,
      height: height,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
  }

  Future<ui.Image> _render({
    required MapData map,
    required Map<String, ui.Image?> imagesById,
    required ({
      int width,
      int height,
      double tileWidth,
      double tileHeight,
    }) dimensions,
  }) async {
    final settings = inputs.settings;
    final tilesPerRowById = <String, int>{};
    for (final entry in imagesById.entries) {
      final image = entry.value;
      if (image == null) continue;
      final columns = image.width ~/ settings.tileWidth;
      if (columns > 0) {
        tilesPerRowById[entry.key] = columns;
      }
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    MapGridPainter(
      map: _withoutNonVisualStackOverlays(map),
      zoom: 1,
      offset: ui.Offset.zero,
      tileWidth: dimensions.tileWidth,
      tileHeight: dimensions.tileHeight,
      tilesetImagesById: imagesById,
      sourceTileWidth: settings.tileWidth,
      sourceTileHeight: settings.tileHeight,
      tilesPerRowById: tilesPerRowById,
      warps: const <MapWarp>[],
      gameplayZones: const <MapGameplayZone>[],
      connectionLabelsByDirection: const <MapConnectionDirection, String>{},
      pathAutotileSetsByPresetId: inputs.pathAutotileSetsByPresetId,
      terrainPresetsByType: inputs.terrainPresetsByType,
      project: inputs.project,
      shadowLightPreviewPreset: neutralEditorShadowLightPreviewPreset,
      editorEntityAnimationMs: 0,
      showGrid: false,
      showEntityEditorChrome: false,
      showEditorOverlays: false,
    ).paint(
      canvas,
      ui.Size(dimensions.width.toDouble(), dimensions.height.toDouble()),
    );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(dimensions.width, dimensions.height);
    } finally {
      picture.dispose();
    }
  }
}

MapData _withoutNonVisualStackOverlays(MapData map) => map.copyWith(
      layers: <MapLayer>[
        for (final layer in map.layers)
          if (layer case final CollisionLayer collision)
            collision.copyWith(isVisible: false)
          else
            layer,
      ],
    );

Set<String> _collectRequiredAssetIds(
  MapData map,
  MapVisualStackMigrationRenderInputs inputs,
) {
  final result = <String>{};
  for (final layer in map.layers) {
    if (!layer.isVisible || layer.opacity <= 0) continue;
    switch (layer) {
      case TileLayer(:final tilesetId, :final tiles):
        if (!tiles.any((tile) => tile > 0)) continue;
        final id = tilesetId?.trim() ?? '';
        if (id.isEmpty) {
          throw StateError(
            'asset de rendu absent pour le calque Tile "${layer.id}"',
          );
        }
        result.add(id);
      case PathLayer(:final cells, :final presetId):
        if (!cells.any((cell) => cell)) continue;
        final normalizedPresetId = presetId.trim();
        final set = inputs.pathAutotileSetsByPresetId[normalizedPresetId];
        if (set != null) {
          final baseId = set.tilesetId.trim();
          if (baseId.isNotEmpty) result.add(baseId);
          for (final frames in set.variants.values) {
            for (final frame in frames) {
              final frameId = frame.tilesetId.trim();
              if (frameId.isNotEmpty) result.add(frameId);
            }
          }
        }
        for (final pattern in inputs.project?.pathPatternPresets ??
            const <ProjectPathPatternPreset>[]) {
          if (pattern.basePathPresetId.trim() != normalizedPresetId) continue;
          for (final cell in pattern.centerPattern.cells) {
            for (final frame in cell.frames) {
              final frameId = frame.tilesetId.trim();
              if (frameId.isNotEmpty) result.add(frameId);
            }
          }
        }
      case TerrainLayer(:final terrains):
        for (final type in terrains.toSet()) {
          if (type == TerrainType.none) continue;
          final preset = inputs.terrainPresetsByType[type];
          if (preset == null) continue;
          final baseId = preset.tilesetId.trim();
          if (baseId.isNotEmpty) result.add(baseId);
          for (final variant in preset.variants) {
            for (final frame in variant.frames) {
              final frameId = frame.tilesetId.trim();
              if (frameId.isNotEmpty) result.add(frameId);
            }
          }
        }
      case SurfaceLayer():
        final catalog = inputs.project?.surfaceCatalog;
        if (catalog != null) {
          result.addAll(
            collectSurfaceTilePreviewTilesetIds(map: map, catalog: catalog),
          );
        }
      case BorderLayer(:final content):
        final catalog = inputs.project?.borderCatalog;
        if (catalog == null) continue;
        final snapshotIds = <String>{};
        for (final feature in content.features) {
          final materialization = feature.materialization;
          if (materialization == null) continue;
          snapshotIds.addAll(
            materialization.ground.map((cell) => cell.visualSnapshotId),
          );
          snapshotIds.addAll(
            materialization.placements
                .map((placement) => placement.visualSnapshotId),
          );
        }
        for (final snapshotId in snapshotIds) {
          final snapshot = catalog.visualSnapshotById(snapshotId);
          if (snapshot == null) {
            throw StateError(
              'asset Border absent du catalogue : $snapshotId',
            );
          }
          for (var index = 0; index < snapshot.frames.length; index += 1) {
            result.add(editorBorderFrameImageKey(snapshotId, index));
          }
        }
      case ObjectLayer():
      case EnvironmentLayer():
      case CollisionLayer():
        break;
    }
  }
  collectTilesetIdsForEntityEditorVisuals(
    map: map,
    project: inputs.project,
    onTilesetId: result.add,
  );
  return result;
}

Map<String, String> _collectAssetPaths(
  MapVisualStackMigrationRenderInputs inputs,
) {
  final result = <String, String>{...inputs.assetPathsById};
  final project = inputs.project;
  if (project == null) return result;
  final root = inputs.projectRootPath?.trim();
  for (final snapshot in project.borderCatalog.visualSnapshots) {
    for (var index = 0; index < snapshot.frames.length; index += 1) {
      final relativePath = snapshot.frames[index].relativeAssetPath;
      final absolutePath = p.isAbsolute(relativePath)
          ? p.normalize(relativePath)
          : root == null || root.isEmpty
              ? null
              : p.normalize(p.join(root, relativePath));
      if (absolutePath != null) {
        result[editorBorderFrameImageKey(snapshot.id, index)] = absolutePath;
      }
    }
  }
  return result;
}

Map<String, TilesetTransparentColor> _collectTransparentColors(
  ProjectManifest? project,
) {
  if (project == null) return const {};
  return <String, TilesetTransparentColor>{
    for (final tileset in project.tilesets)
      if (tileset.transparentColor != null)
        tileset.id: tileset.transparentColor!,
    for (final snapshot in project.borderCatalog.visualSnapshots)
      for (var index = 0; index < snapshot.frames.length; index += 1)
        if (snapshot.frames[index].transparentColorArgb != null)
          editorBorderFrameImageKey(snapshot.id, index):
              TilesetTransparentColor(
            red: (snapshot.frames[index].transparentColorArgb! >> 16) & 0xff,
            green: (snapshot.frames[index].transparentColorArgb! >> 8) & 0xff,
            blue: snapshot.frames[index].transparentColorArgb! & 0xff,
          ),
  };
}

void _validateTileSources({
  required MapData map,
  required Map<String, ui.Image?> imagesById,
  required ProjectSettings settings,
}) {
  for (final layer in map.layers.whereType<TileLayer>()) {
    if (!layer.isVisible || layer.opacity <= 0) continue;
    final positiveTiles = layer.tiles.where((tile) => tile > 0);
    if (positiveTiles.isEmpty) continue;
    final tilesetId = layer.tilesetId?.trim() ?? '';
    final image = imagesById[tilesetId];
    if (image == null) continue;
    final columns = image.width ~/ settings.tileWidth;
    final rows = image.height ~/ settings.tileHeight;
    final tileCapacity = columns * rows;
    final invalidTile = positiveTiles.where((tile) => tile > tileCapacity);
    if (columns <= 0 || rows <= 0 || invalidTile.isNotEmpty) {
      throw StateError(
        'asset "$tilesetId" trop petit pour les tuiles du calque '
        '"${layer.id}"',
      );
    }
  }
}

List<String> _comparisonLimitations(MapData before, MapData after) {
  final limitations = <String>{
    'Comparaison RGBA du rendu statique de l’éditeur à t=0 ; les animations '
        'ne sont pas échantillonnées.',
    'La grille, les collisions, les sélections et les autres surcouches '
        'd’édition sont exclues de la pile visuelle.',
  };
  final hasUnmaterializedBorder = <MapData>[before, after]
      .expand((map) => map.layers.whereType<BorderLayer>())
      .expand((layer) => layer.content.features)
      .any((feature) => feature.materialization == null);
  if (hasUnmaterializedBorder) {
    limitations.add(
      'Les bordures non matérialisées n’ont pas encore de pixels : leur '
      'impact reste couvert uniquement par le diagnostic structurel.',
    );
  }
  return limitations.toList(growable: false)..sort();
}

Future<MapVisualStackPixelComparison> _compareImages({
  required ui.Image before,
  required ui.Image after,
  required List<String> limitations,
}) async {
  if (before.width != after.width || before.height != after.height) {
    throw StateError('les images avant/après ont des dimensions différentes');
  }
  final beforeData =
      await before.toByteData(format: ui.ImageByteFormat.rawRgba);
  final afterData = await after.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (beforeData == null || afterData == null) {
    throw StateError('lecture RGBA du rendu impossible');
  }
  final beforeBytes = beforeData.buffer.asUint8List(
    beforeData.offsetInBytes,
    beforeData.lengthInBytes,
  );
  final afterBytes = afterData.buffer.asUint8List(
    afterData.offsetInBytes,
    afterData.lengthInBytes,
  );
  if (beforeBytes.length != afterBytes.length) {
    throw StateError('les tampons RGBA avant/après sont incompatibles');
  }

  var beforeHash = 0x811c9dc5;
  var afterHash = 0x811c9dc5;
  var changed = 0;
  int? left;
  int? top;
  int? right;
  int? bottom;
  final pixelCount = before.width * before.height;
  for (var pixel = 0; pixel < pixelCount; pixel += 1) {
    final offset = pixel * 4;
    var differs = false;
    for (var channel = 0; channel < 4; channel += 1) {
      final beforeValue = beforeBytes[offset + channel];
      final afterValue = afterBytes[offset + channel];
      beforeHash = _fnv1a32Byte(beforeHash, beforeValue);
      afterHash = _fnv1a32Byte(afterHash, afterValue);
      differs = differs || beforeValue != afterValue;
    }
    if (differs) {
      changed += 1;
      final x = pixel % before.width;
      final y = pixel ~/ before.width;
      left = left == null || x < left ? x : left;
      right = right == null || x > right ? x : right;
      top = top == null || y < top ? y : top;
      bottom = bottom == null || y > bottom ? y : bottom;
    }
    if (pixel > 0 && pixel % _comparisonYieldStride == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }
  return MapVisualStackPixelComparison(
    width: before.width,
    height: before.height,
    changedPixelCount: changed,
    changedBounds: left == null
        ? null
        : MapVisualStackPixelBounds(
            left: left,
            top: top!,
            right: right!,
            bottom: bottom!,
          ),
    beforeFingerprint: _formatFingerprint(beforeHash),
    afterFingerprint: _formatFingerprint(afterHash),
    limitations: limitations,
  );
}

int _fnv1a32Byte(int hash, int byte) =>
    ((hash ^ byte) * 0x01000193) & 0xffffffff;

String _formatFingerprint(int hash) =>
    'fnv1a32:${hash.toRadixString(16).padLeft(8, '0')}';

Future<Map<String, ui.Image?>> _loadImagesFromDisk(
  Map<String, String> pathsById,
  Map<String, TilesetTransparentColor> transparentColorsById,
) async {
  final entries = await Future.wait(
    pathsById.entries.map((entry) async {
      ui.Codec? codec;
      try {
        final file = File(entry.value);
        if (!await file.exists()) {
          return MapEntry<String, ui.Image?>(entry.key, null);
        }
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          return MapEntry<String, ui.Image?>(entry.key, null);
        }
        Uint8List displayBytes = bytes;
        final transparentColor = transparentColorsById[entry.key];
        if (transparentColor != null) {
          try {
            displayBytes = applyTilesetTransparentColorToPngBytes(
              imageBytes: bytes,
              transparentColor: transparentColor,
            );
          } on Object {
            displayBytes = bytes;
          }
        }
        codec = await ui.instantiateImageCodec(displayBytes);
        final frame = await codec.getNextFrame();
        return MapEntry<String, ui.Image?>(entry.key, frame.image);
      } on Object {
        return MapEntry<String, ui.Image?>(entry.key, null);
      } finally {
        codec?.dispose();
      }
    }),
  );
  return <String, ui.Image?>{
    for (final entry in entries) entry.key: entry.value
  };
}

void _disposeImages(Iterable<ui.Image?> images) {
  final unique = HashSet<ui.Image>.identity();
  for (final image in images.whereType<ui.Image>()) {
    if (unique.add(image)) image.dispose();
  }
}
