import 'package:meta/meta.dart' show immutable;

import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/project_tileset_source.dart';
import '../models/smart_tile.dart';
import 'project_tileset_visual_resolver.dart';
import 'smart_tile_sprite_geometry.dart';

@immutable
final class MapPlacedTileVisualInstruction {
  const MapPlacedTileVisualInstruction({
    required this.objectId,
    required this.tilesetId,
    required this.assetId,
    required this.sourceRect,
    required this.destinationRect,
    required this.transform,
    required this.opacity,
  });

  final String objectId;
  final String tilesetId;
  final String assetId;
  final ProjectTilesetPixelRect sourceRect;
  final SmartTileGeometryRect destinationRect;
  final SmartTileSpriteTransform transform;
  final double opacity;
}

@immutable
final class MapPlacedTileVisualWorkCounts {
  const MapPlacedTileVisualWorkCounts({
    required this.sourceObjectCount,
    required this.candidateObjectVisits,
    required this.resolvedVisualCount,
    required this.spatialBucketCount,
    required this.cachedVisualDefinitionCount,
  });

  final int sourceObjectCount;
  final int candidateObjectVisits;
  final int resolvedVisualCount;
  final int spatialBucketCount;
  final int cachedVisualDefinitionCount;
}

@immutable
final class MapPlacedTileVisualBatch {
  MapPlacedTileVisualBatch({
    required Iterable<MapPlacedTileVisualInstruction> visuals,
    required this.work,
  }) : visuals = List<MapPlacedTileVisualInstruction>.unmodifiable(visuals);

  final List<MapPlacedTileVisualInstruction> visuals;
  final MapPlacedTileVisualWorkCounts work;
}

@immutable
final class MapPlacedTileVisualResolutionException implements Exception {
  const MapPlacedTileVisualResolutionException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'MapPlacedTileVisualResolutionException($code): $message';
}

/// Resolves visual-only object-layer tiles into platform-neutral draw calls.
///
/// Coordinates are expressed in destination pixels only at this boundary.
/// The persisted object geometry remains fractional cell space, so editor and
/// runtime scaling cannot drift. No collision or gameplay instruction is ever
/// produced by this resolver.
List<MapPlacedTileVisualInstruction> resolveMapPlacedTileVisuals({
  required ObjectLayer layer,
  required Map<String, ProjectTilesetSource> tilesetsById,
  required int sourceCellWidth,
  required int sourceCellHeight,
  required double destinationCellWidth,
  required double destinationCellHeight,
  required int elapsedMs,
  SmartTileGeometryRect? viewport,
}) =>
    MapPlacedTileVisualIndex.build(
      layer: layer,
      tilesetsById: tilesetsById,
      sourceCellWidth: sourceCellWidth,
      sourceCellHeight: sourceCellHeight,
      destinationCellWidth: destinationCellWidth,
      destinationCellHeight: destinationCellHeight,
    ).resolve(elapsedMs: elapsedMs, viewport: viewport).visuals;

/// Immutable spatial projection for one object layer.
///
/// Visual definitions and conservative animation bounds are computed once at
/// map/component load. Subsequent pan and frame resolution only visits buckets
/// intersecting the viewport. Oversized objects are retained in a bounded
/// global candidate list instead of exploding the bucket cache.
final class MapPlacedTileVisualIndex {
  MapPlacedTileVisualIndex._({
    required this.sourceObjectCount,
    required this.cachedVisualDefinitionCount,
    required this.spatialBucketCount,
    required this.bucketReferenceCount,
    required this.layerOpacity,
    required this.bucketWidth,
    required this.bucketHeight,
    required List<_IndexedMapPlacedTile> entries,
    required Map<(int, int), List<int>> buckets,
    required List<int> globalEntryIndices,
  })  : _entries = List<_IndexedMapPlacedTile>.unmodifiable(entries),
        _buckets = Map<(int, int), List<int>>.unmodifiable(
          buckets.map(
            (key, value) => MapEntry(key, List<int>.unmodifiable(value)),
          ),
        ),
        _globalEntryIndices = List<int>.unmodifiable(globalEntryIndices);

  factory MapPlacedTileVisualIndex.build({
    required ObjectLayer layer,
    required Map<String, ProjectTilesetSource> tilesetsById,
    required int sourceCellWidth,
    required int sourceCellHeight,
    required double destinationCellWidth,
    required double destinationCellHeight,
  }) {
    _validateContext(
      layer: layer,
      sourceCellWidth: sourceCellWidth,
      sourceCellHeight: sourceCellHeight,
      destinationCellWidth: destinationCellWidth,
      destinationCellHeight: destinationCellHeight,
    );
    final bucketWidth = destinationCellWidth * 8;
    final bucketHeight = destinationCellHeight * 8;
    if (!layer.isVisible || layer.opacity == 0) {
      return MapPlacedTileVisualIndex._(
        sourceObjectCount: layer.tileObjects.length,
        cachedVisualDefinitionCount: 0,
        spatialBucketCount: 0,
        bucketReferenceCount: 0,
        layerOpacity: layer.opacity,
        bucketWidth: bucketWidth,
        bucketHeight: bucketHeight,
        entries: const <_IndexedMapPlacedTile>[],
        buckets: const <(int, int), List<int>>{},
        globalEntryIndices: const <int>[],
      );
    }

    const resolver = ProjectTilesetVisualResolver();
    final visualDefinitions = <(String, int), ProjectTilesetVisualResolution>{};
    final entries = <_IndexedMapPlacedTile>[];
    for (final object in layer.tileObjects) {
      _validateObject(object);
      if (!object.isVisible || object.opacity == 0) continue;
      final source = tilesetsById[object.tile.tilesetId];
      if (source == null) {
        throw const MapPlacedTileVisualResolutionException(
          'map.placed_tile.tileset_missing',
          'A placed tile references an unavailable project tileset.',
        );
      }
      final selection = _selectionFor(object.tile, source);
      if (selection == null) {
        throw const MapPlacedTileVisualResolutionException(
          'map.placed_tile.tile_missing',
          'A placed tile references an unavailable local tile identity.',
        );
      }
      final key = (object.tile.tilesetId, object.tile.localTileId);
      late final ProjectTilesetVisualResolution visual;
      try {
        visual = visualDefinitions.putIfAbsent(
          key,
          () => resolver.resolve(
            source: source,
            selection: selection,
            cellWidth: sourceCellWidth,
            cellHeight: sourceCellHeight,
            anchor: ProjectTilesetVisualAnchor.bottomLeft,
          ),
        );
      } on ProjectTilesetVisualResolutionException catch (error) {
        throw MapPlacedTileVisualResolutionException(
          'map.placed_tile.tileset_visual_invalid',
          error.message,
        );
      }
      final destinations = <SmartTileGeometryRect>[];
      for (final frame in visual.frames) {
        if (frame.slices.length != 1) {
          throw const MapPlacedTileVisualResolutionException(
            'map.placed_tile.visual_slice_invalid',
            'A placed tile must resolve to exactly one visual slice per frame.',
          );
        }
        destinations.add(
          _destinationForSlice(
            object: object,
            slice: frame.slices.single,
            sourceCellHeight: sourceCellHeight,
            destinationCellWidth: destinationCellWidth,
            destinationCellHeight: destinationCellHeight,
          ),
        );
      }
      entries.add(
        _IndexedMapPlacedTile(
          object: object,
          visual: visual,
          animationBounds: _unionBounds(destinations),
          sourceCellHeight: sourceCellHeight,
          destinationCellWidth: destinationCellWidth,
          destinationCellHeight: destinationCellHeight,
        ),
      );
    }

    final buckets = <(int, int), List<int>>{};
    final globalEntryIndices = <int>[];
    var bucketReferenceCount = 0;
    for (var index = 0; index < entries.length; index += 1) {
      final bounds = entries[index].animationBounds;
      final left = (bounds.left / bucketWidth).floor();
      final top = (bounds.top / bucketHeight).floor();
      final right = (bounds.right / bucketWidth).ceil() - 1;
      final bottom = (bounds.bottom / bucketHeight).ceil() - 1;
      final bucketCount = (right - left + 1) * (bottom - top + 1);
      if (bucketCount > 256) {
        globalEntryIndices.add(index);
        continue;
      }
      for (var y = top; y <= bottom; y += 1) {
        for (var x = left; x <= right; x += 1) {
          buckets.putIfAbsent((x, y), () => <int>[]).add(index);
          bucketReferenceCount += 1;
        }
      }
    }
    return MapPlacedTileVisualIndex._(
      sourceObjectCount: layer.tileObjects.length,
      cachedVisualDefinitionCount: visualDefinitions.length,
      spatialBucketCount: buckets.length,
      bucketReferenceCount: bucketReferenceCount,
      layerOpacity: layer.opacity,
      bucketWidth: bucketWidth,
      bucketHeight: bucketHeight,
      entries: entries,
      buckets: buckets,
      globalEntryIndices: globalEntryIndices,
    );
  }

  final int sourceObjectCount;
  final int cachedVisualDefinitionCount;
  final int spatialBucketCount;
  final int bucketReferenceCount;
  final double layerOpacity;
  final double bucketWidth;
  final double bucketHeight;
  final List<_IndexedMapPlacedTile> _entries;
  final Map<(int, int), List<int>> _buckets;
  final List<int> _globalEntryIndices;

  MapPlacedTileVisualBatch resolve({
    required int elapsedMs,
    SmartTileGeometryRect? viewport,
  }) {
    final candidateIndices = viewport == null
        ? <int>[for (var index = 0; index < _entries.length; index += 1) index]
        : _candidateIndices(viewport);
    final output = <MapPlacedTileVisualInstruction>[];
    for (final index in candidateIndices) {
      final entry = _entries[index];
      final frame = entry.visual.frameAt(elapsedMs);
      final slice = frame.slices.single;
      final destination = _destinationForSlice(
        object: entry.object,
        slice: slice,
        sourceCellHeight: entry.sourceCellHeight,
        destinationCellWidth: entry.destinationCellWidth,
        destinationCellHeight: entry.destinationCellHeight,
      );
      if (viewport != null && !_intersects(destination, viewport)) continue;
      output.add(
        MapPlacedTileVisualInstruction(
          objectId: entry.object.id,
          tilesetId: entry.object.tile.tilesetId,
          assetId: slice.assetId,
          sourceRect: slice.sourceRect,
          destinationRect: destination,
          transform: composeSmartTileSpriteTransforms(
            first: entry.object.tile.transform,
            second: SmartTileSpriteTransform(
              quarterTurns: entry.object.quarterTurns,
            ),
          ),
          opacity:
              (layerOpacity * entry.object.opacity).clamp(0.0, 1.0).toDouble(),
        ),
      );
    }
    return MapPlacedTileVisualBatch(
      visuals: output,
      work: MapPlacedTileVisualWorkCounts(
        sourceObjectCount: sourceObjectCount,
        candidateObjectVisits: candidateIndices.length,
        resolvedVisualCount: output.length,
        spatialBucketCount: spatialBucketCount,
        cachedVisualDefinitionCount: cachedVisualDefinitionCount,
      ),
    );
  }

  List<int> _candidateIndices(SmartTileGeometryRect viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) {
      return const <int>[];
    }
    final indices = <int>{..._globalEntryIndices};
    final left = (viewport.left / bucketWidth).floor();
    final top = (viewport.top / bucketHeight).floor();
    final right = (viewport.right / bucketWidth).ceil() - 1;
    final bottom = (viewport.bottom / bucketHeight).ceil() - 1;
    for (var y = top; y <= bottom; y += 1) {
      for (var x = left; x <= right; x += 1) {
        indices.addAll(_buckets[(x, y)] ?? const <int>[]);
      }
    }
    final sorted = indices.toList()..sort();
    return sorted;
  }
}

void _validateContext({
  required ObjectLayer layer,
  required int sourceCellWidth,
  required int sourceCellHeight,
  required double destinationCellWidth,
  required double destinationCellHeight,
}) {
  if (sourceCellWidth <= 0 ||
      sourceCellHeight <= 0 ||
      !destinationCellWidth.isFinite ||
      !destinationCellHeight.isFinite ||
      destinationCellWidth <= 0 ||
      destinationCellHeight <= 0 ||
      !layer.opacity.isFinite ||
      layer.opacity < 0 ||
      layer.opacity > 1) {
    throw const MapPlacedTileVisualResolutionException(
      'map.placed_tile.context_invalid',
      'Placed-tile visual dimensions and layer opacity must be valid.',
    );
  }
}

final class _IndexedMapPlacedTile {
  const _IndexedMapPlacedTile({
    required this.object,
    required this.visual,
    required this.animationBounds,
    required this.sourceCellHeight,
    required this.destinationCellWidth,
    required this.destinationCellHeight,
  });

  final MapPlacedTile object;
  final ProjectTilesetVisualResolution visual;
  final SmartTileGeometryRect animationBounds;
  final int sourceCellHeight;
  final double destinationCellWidth;
  final double destinationCellHeight;
}

SmartTileGeometryRect _destinationForSlice({
  required MapPlacedTile object,
  required ProjectTilesetVisualSlice slice,
  required int sourceCellHeight,
  required double destinationCellWidth,
  required double destinationCellHeight,
}) {
  final sourceRect = slice.sourceRect;
  final destinationRect = slice.destinationRect;
  final sourceOffsetX = destinationRect.x;
  final sourceOffsetY =
      destinationRect.y - (sourceCellHeight - sourceRect.height);
  final objectPixelWidth = object.width * destinationCellWidth;
  final objectPixelHeight = object.height * destinationCellHeight;
  final unrotated = SmartTileGeometryRect(
    left: object.anchorX * destinationCellWidth +
        sourceOffsetX * objectPixelWidth / sourceRect.width,
    top: (object.anchorY - object.height) * destinationCellHeight +
        sourceOffsetY * objectPixelHeight / sourceRect.height,
    width: objectPixelWidth,
    height: objectPixelHeight,
  );
  return _rotateBounds(
    unrotated,
    anchor: SmartTileGeometryPoint(
      x: object.anchorX * destinationCellWidth,
      y: object.anchorY * destinationCellHeight,
    ),
    quarterTurns: object.quarterTurns,
  );
}

SmartTileGeometryRect _unionBounds(List<SmartTileGeometryRect> bounds) {
  var left = bounds.first.left;
  var top = bounds.first.top;
  var right = bounds.first.right;
  var bottom = bounds.first.bottom;
  for (final rect in bounds.skip(1)) {
    if (rect.left < left) left = rect.left;
    if (rect.top < top) top = rect.top;
    if (rect.right > right) right = rect.right;
    if (rect.bottom > bottom) bottom = rect.bottom;
  }
  return SmartTileGeometryRect(
    left: left,
    top: top,
    width: right - left,
    height: bottom - top,
  );
}

void _validateObject(MapPlacedTile object) {
  if (object.id.trim().isEmpty ||
      object.id != object.id.trim() ||
      object.tile.tilesetId.trim().isEmpty ||
      object.tile.tilesetId != object.tile.tilesetId.trim() ||
      object.tile.localTileId < 0 ||
      object.tile.transform.quarterTurns < 0 ||
      object.tile.transform.quarterTurns > 3 ||
      !object.anchorX.isFinite ||
      !object.anchorY.isFinite ||
      !object.width.isFinite ||
      !object.height.isFinite ||
      object.width <= 0 ||
      object.height <= 0 ||
      object.quarterTurns < 0 ||
      object.quarterTurns > 3 ||
      !object.opacity.isFinite ||
      object.opacity < 0 ||
      object.opacity > 1) {
    throw const MapPlacedTileVisualResolutionException(
      'map.placed_tile.geometry_invalid',
      'A placed tile has invalid identity, geometry, transform or opacity.',
    );
  }
}

ProjectTilesetVisualSelection? _selectionFor(
  TileLayerPaletteEntry tile,
  ProjectTilesetSource source,
) =>
    switch (source) {
      ProjectRegularAtlasTilesetSource atlas =>
        tile.localTileId < atlas.tileCount
            ? ProjectTilesetVisualSelection.regularAtlas(
                source: TilesetSourceRect(
                  x: tile.localTileId % atlas.columns,
                  y: tile.localTileId ~/ atlas.columns,
                ),
              )
            : null,
      ProjectImageCollectionTilesetSource() =>
        ProjectTilesetVisualSelection.imageCollection(
          tileId: tile.localTileId,
        ),
    };

SmartTileGeometryRect _rotateBounds(
  SmartTileGeometryRect rect, {
  required SmartTileGeometryPoint anchor,
  required int quarterTurns,
}) {
  if (quarterTurns == 0) return rect;
  final rotation = SmartTileSpriteTransform(quarterTurns: quarterTurns);
  final corners = <SmartTileGeometryPoint>[
    SmartTileGeometryPoint(x: rect.left, y: rect.top),
    SmartTileGeometryPoint(x: rect.right, y: rect.top),
    SmartTileGeometryPoint(x: rect.right, y: rect.bottom),
    SmartTileGeometryPoint(x: rect.left, y: rect.bottom),
  ].map((point) {
    final transformed = transformSmartTileVector(
      SmartTileGeometryPoint(
        x: point.x - anchor.x,
        y: point.y - anchor.y,
      ),
      rotation,
    );
    return SmartTileGeometryPoint(
      x: anchor.x + transformed.x,
      y: anchor.y + transformed.y,
    );
  }).toList(growable: false);
  var left = corners.first.x;
  var top = corners.first.y;
  var right = corners.first.x;
  var bottom = corners.first.y;
  for (final point in corners.skip(1)) {
    if (point.x < left) left = point.x;
    if (point.y < top) top = point.y;
    if (point.x > right) right = point.x;
    if (point.y > bottom) bottom = point.y;
  }
  return SmartTileGeometryRect(
    left: left,
    top: top,
    width: right - left,
    height: bottom - top,
  );
}

bool _intersects(
  SmartTileGeometryRect left,
  SmartTileGeometryRect right,
) =>
    left.left < right.right &&
    right.left < left.right &&
    left.top < right.bottom &&
    right.top < left.bottom;
