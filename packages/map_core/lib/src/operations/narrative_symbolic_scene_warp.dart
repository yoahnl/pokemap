part of 'narrative_symbolic_reachability_solver.dart';

enum _WarpTraversability { clear, blocked, indeterminate }

typedef _SymbolicSceneWarpArrival = ({
  MapData? map,
  GridPos? position,
  _WarpTraversability traversability,
});

_SymbolicSceneWarpArrival? _symbolicSceneWarpArrival(
  SceneNode node,
  Map<String, MapData> maps,
  ProjectManifest? project,
) {
  final payload = node.payload;
  if (payload is! SceneActionPayload) return null;
  final command = payload.interactiveCommand;
  if (command is! SceneWarpInteractiveCommand) return null;
  final map = maps[command.destinationMapId];
  final position = map?.warps
      .where((warp) => warp.id == command.warpId)
      .firstOrNull
      ?.pos;
  if (map == null || position == null || !_isCellInMap(map, position)) {
    return (
      map: null,
      position: null,
      traversability: _WarpTraversability.blocked,
    );
  }
  final traversability = map.spatialScene == null
      ? _symbolic2dWarpTraversability(map, position, project, command)
      : _WarpTraversability.indeterminate;
  return (map: map, position: position, traversability: traversability);
}

bool _isCellInMap(MapData map, GridPos position) =>
    position.x >= 0 &&
    position.x < map.size.width &&
    position.y >= 0 &&
    position.y < map.size.height;

_WarpTraversability _symbolic2dWarpTraversability(
  MapData map,
  GridPos position,
  ProjectManifest? project,
  SceneWarpInteractiveCommand command,
) {
  final settings = project?.settings ?? const ProjectSettings();
  final tileWidth = settings.tileWidth;
  final tileHeight = settings.tileHeight;
  if (tileWidth <= 0 || tileHeight <= 0) {
    return _WarpTraversability.indeterminate;
  }
  const spriteWidth = PlayerCollisionConventionsV1.defaultSpriteWidthPx;
  const spriteHeight = PlayerCollisionConventionsV1.defaultSpriteHeightPx;
  final sprite = PlayerCollisionConventionsV1.playerSpriteTopLeftFromSpawnCell(
    cellX: position.x,
    cellY: position.y,
    tileWidthPx: tileWidth,
    tileHeightPx: tileHeight,
    spriteWidthPx: spriteWidth,
    spriteHeightPx: spriteHeight,
  );
  final movement =
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
        spriteTopLeftPx: sprite,
        spriteWidthPx: spriteWidth,
        spriteHeightPx: spriteHeight,
      );
  final contact =
      PlayerCollisionConventionsV1.characterContactRectFromMovementRect(
        movementRect: movement,
        tileWidthPx: tileWidth,
        tileHeightPx: tileHeight,
      );
  for (final footprint in [movement, contact]) {
    if (footprint.leftPx < 0 ||
        footprint.topPx < 0 ||
        footprint.leftPx + footprint.widthPx > map.size.width * tileWidth ||
        footprint.topPx + footprint.heightPx > map.size.height * tileHeight) {
      return _WarpTraversability.blocked;
    }
  }

  final collisionLayers = map.layers.whereType<CollisionLayer>().toList();
  final tileLayers = map.layers
      .whereType<TileLayer>()
      .where(
        (layer) => layer.isVisible && layer.purpose == MapLayerPurpose.visual,
      )
      .toList();
  for (final cell in _coveredWarpCells(movement, tileWidth, tileHeight)) {
    final index = cell.y * map.size.width + cell.x;
    if (collisionLayers.any(
      (layer) => index < layer.collisions.length && layer.collisions[index],
    )) {
      return _WarpTraversability.blocked;
    }
    for (final layer in tileLayers) {
      if (index >= layer.cells.length) continue;
      final paletteIndex = layer.cells[index] - 1;
      if (paletteIndex < 0 || paletteIndex >= layer.palette.length) continue;
      final tile = layer.palette[paletteIndex];
      final source = project?.tilesets
          .where((tileset) => tileset.id == tile.tilesetId)
          .firstOrNull
          ?.source;
      if (source is ProjectRegularAtlasTilesetSource &&
          source.tileProperties.any(
            (property) =>
                property.tileId == tile.localTileId && !property.passable,
          )) {
        return _WarpTraversability.blocked;
      }
    }
  }

  final covered = {
    ..._coveredWarpCells(movement, tileWidth, tileHeight),
    ..._coveredWarpCells(contact, tileWidth, tileHeight),
  };
  if (map.movingPlatforms.isNotEmpty || map.movingProps.isNotEmpty) {
    return _WarpTraversability.indeterminate;
  }
  final placedElements = _symbolicPlacedElementCollision(
    map,
    project,
    movement,
    PixelSize(width: tileWidth, height: tileHeight),
  );
  if (placedElements == _WarpTraversability.blocked) return placedElements;
  if (placedElements == _WarpTraversability.indeterminate ||
      map.layers.whereType<BorderLayer>().any(
        (layer) => !layer.content.isEmpty,
      ) ||
      map.gameplayZones.any(
        (zone) =>
            (zone.kind == GameplayZoneKind.movement ||
                (zone.kind == GameplayZoneKind.fieldAction &&
                    const {
                      FieldActionZoneKind.waterfall,
                      FieldActionZoneKind.whirlpool,
                    }.contains(zone.fieldAction?.actionKind))) &&
            covered.any((cell) => gameplayZoneContainsPosition(zone, cell)),
      ) ||
      map.entities.any(
        (entity) =>
            entity.kind != MapEntityKind.spawn &&
            entity.blocksMovement &&
            entity.id != command.arrivalCollisionOwnerEntityId &&
            resolveEntityCollisionCells(entity).any(covered.contains),
      ) ||
      (project == null && tileLayers.isNotEmpty)) {
    return _WarpTraversability.indeterminate;
  }
  return _WarpTraversability.clear;
}

_WarpTraversability _symbolicPlacedElementCollision(
  MapData map,
  ProjectManifest? project,
  PixelRect movement,
  PixelSize tileSize,
) {
  if (map.placedElements.isEmpty) return _WarpTraversability.clear;
  final elementsById = {
    for (final element in project?.elements ?? const <ProjectElementEntry>[])
      element.id: element,
  };
  var unresolved = false;
  for (final instance in map.placedElements) {
    if (!instance.applyCollision) continue;
    final element = elementsById[instance.elementId];
    if (element == null) {
      unresolved = true;
      continue;
    }
    try {
      final rectangles = resolveMapPlacedElementCollisionRects(
        instance: instance,
        element: element,
        tileSize: tileSize,
      );
      if (rectangles.any(
        (rect) =>
            movement.leftPx < rect.leftPx + rect.widthPx &&
            movement.leftPx + movement.widthPx > rect.leftPx &&
            movement.topPx < rect.topPx + rect.heightPx &&
            movement.topPx + movement.heightPx > rect.topPx,
      )) {
        return _WarpTraversability.blocked;
      }
    } on FormatException {
      unresolved = true;
    } on ValidationException {
      unresolved = true;
    }
  }
  return unresolved
      ? _WarpTraversability.indeterminate
      : _WarpTraversability.clear;
}

Iterable<GridPos> _coveredWarpCells(
  PixelRect rect,
  int tileWidth,
  int tileHeight,
) sync* {
  final right = (rect.leftPx + rect.widthPx - 1) ~/ tileWidth;
  final bottom = (rect.topPx + rect.heightPx - 1) ~/ tileHeight;
  for (var y = rect.topPx ~/ tileHeight; y <= bottom; y++) {
    for (var x = rect.leftPx ~/ tileWidth; x <= right; x++) {
      yield GridPos(x: x, y: y);
    }
  }
}
