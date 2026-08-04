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
  if (!layer.isVisible || layer.opacity == 0) {
    return const <MapPlacedTileVisualInstruction>[];
  }
  final output = <MapPlacedTileVisualInstruction>[];
  const resolver = ProjectTilesetVisualResolver();
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
    final ProjectTilesetVisualResolution visual;
    try {
      visual = resolver.resolve(
        source: source,
        selection: selection,
        cellWidth: sourceCellWidth,
        cellHeight: sourceCellHeight,
        anchor: ProjectTilesetVisualAnchor.bottomLeft,
      );
    } on ProjectTilesetVisualResolutionException catch (error) {
      throw MapPlacedTileVisualResolutionException(
        'map.placed_tile.tileset_visual_invalid',
        error.message,
      );
    }
    final frame = visual.frameAt(elapsedMs);
    if (frame.slices.length != 1) {
      throw const MapPlacedTileVisualResolutionException(
        'map.placed_tile.visual_slice_invalid',
        'A placed tile must resolve to exactly one visual slice per frame.',
      );
    }
    final slice = frame.slices.single;
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
    final anchor = SmartTileGeometryPoint(
      x: object.anchorX * destinationCellWidth,
      y: object.anchorY * destinationCellHeight,
    );
    final destination = _rotateBounds(
      unrotated,
      anchor: anchor,
      quarterTurns: object.quarterTurns,
    );
    if (viewport != null && !_intersects(destination, viewport)) continue;
    final rotation = SmartTileSpriteTransform(
      quarterTurns: object.quarterTurns,
    );
    output.add(
      MapPlacedTileVisualInstruction(
        objectId: object.id,
        tilesetId: object.tile.tilesetId,
        assetId: slice.assetId,
        sourceRect: sourceRect,
        destinationRect: destination,
        transform: composeSmartTileSpriteTransforms(
          first: object.tile.transform,
          second: rotation,
        ),
        opacity: (layer.opacity * object.opacity).clamp(0.0, 1.0),
      ),
    );
  }
  return List<MapPlacedTileVisualInstruction>.unmodifiable(output);
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
