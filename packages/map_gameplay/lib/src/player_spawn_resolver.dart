import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_exceptions.dart';
import 'gameplay_player_state.dart';

const Direction _kDefaultFacing = Direction.south;

/// Résout le joueur initial + [playerPositionPx] à partir du spawn carte.
///
/// [tileWidthPx] / [tileHeightPx] : taille tuile projet (même repère que le bitmap monde).
GameplayPlayerState resolveInitialPlayerSpawn(
  MapData map, {
  int tileWidthPx = 16,
  int tileHeightPx = 16,
}) {
  final spawnId = map.mapMetadata.defaultSpawnId?.trim();
  if (spawnId != null && spawnId.isNotEmpty) {
    return _resolveBySpawnId(map, spawnId,
        tileWidthPx: tileWidthPx, tileHeightPx: tileHeightPx);
  }
  return _resolveByPlayerStartRole(map,
      tileWidthPx: tileWidthPx, tileHeightPx: tileHeightPx);
}

GameplayPlayerState _resolveBySpawnId(
  MapData map,
  String spawnId, {
  required int tileWidthPx,
  required int tileHeightPx,
}) {
  final entity = map.entities.where((e) => e.id == spawnId).firstOrNull;
  if (entity == null) {
    throw GameplaySpawnResolutionException(
      'defaultSpawnId "$spawnId" not found in map entities',
    );
  }
  if (entity.kind != MapEntityKind.spawn) {
    throw GameplaySpawnResolutionException(
      'defaultSpawnId "$spawnId" refers to an entity of kind ${entity.kind}, expected spawn',
    );
  }
  return _stateFromSpawnEntity(
    entity,
    map,
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
  );
}

GameplayPlayerState _resolveByPlayerStartRole(
  MapData map, {
  required int tileWidthPx,
  required int tileHeightPx,
}) {
  final candidates = map.entities
      .where(
        (e) =>
            e.kind == MapEntityKind.spawn &&
            e.spawn?.role == EntitySpawnRole.playerStart,
      )
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  if (candidates.isEmpty) {
    throw const GameplaySpawnResolutionException(
      'No player spawn found: set defaultSpawnId on the map metadata, '
      'or add a spawn entity with role playerStart',
    );
  }

  final entity = candidates.first;
  return _stateFromSpawnEntity(
    entity,
    map,
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
  );
}

GameplayPlayerState _stateFromSpawnEntity(
  MapEntity entity,
  MapData map, {
  required int tileWidthPx,
  required int tileHeightPx,
}) {
  final facing = _directionFromEntityFacing(entity.spawn?.facing);
  final tw = tileWidthPx <= 0 ? 16 : tileWidthPx;
  final th = tileHeightPx <= 0 ? 16 : tileHeightPx;
  final spriteW = PlayerCollisionConventionsV1.defaultSpriteWidthPx;
  final spriteH = PlayerCollisionConventionsV1.defaultSpriteHeightPx;

  final topLeft = PlayerCollisionConventionsV1.playerSpriteTopLeftFromSpawnCell(
    cellX: entity.pos.x,
    cellY: entity.pos.y,
    tileWidthPx: tw,
    tileHeightPx: th,
    spriteWidthPx: spriteW,
    spriteHeightPx: spriteH,
  );
  final hitbox = PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
    spriteTopLeftPx: topLeft,
    spriteWidthPx: spriteW,
    spriteHeightPx: spriteH,
  );
  final gridPos = PlayerCollisionConventionsV1.projectFeetAnchorToCell(
    playerCollisionRectPx: hitbox,
    tileWidthPx: tw,
    tileHeightPx: th,
    mapWidthCells: map.size.width,
    mapHeightCells: map.size.height,
  );

  return GameplayPlayerState(
    pos: gridPos,
    playerPositionPx: topLeft,
    facing: facing,
    playerSpriteWidthPx: spriteW,
    playerSpriteHeightPx: spriteH,
  );
}

Direction _directionFromEntityFacing(EntityFacing? facing) {
  if (facing == null) return _kDefaultFacing;
  return facing.asDirection;
}
