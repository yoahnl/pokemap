import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_exceptions.dart';
import 'gameplay_player_state.dart';

const Direction _kDefaultFacing = Direction.south;

GameplayPlayerState resolveInitialPlayerSpawn(MapData map) {
  final spawnId = map.mapMetadata.defaultSpawnId?.trim();
  if (spawnId != null && spawnId.isNotEmpty) {
    return _resolveBySpawnId(map, spawnId);
  }
  return _resolveByPlayerStartRole(map);
}

GameplayPlayerState _resolveBySpawnId(MapData map, String spawnId) {
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
  return GameplayPlayerState(
    pos: entity.pos,
    facing: _directionFromEntityFacing(entity.spawn?.facing),
  );
}

GameplayPlayerState _resolveByPlayerStartRole(MapData map) {
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
  return GameplayPlayerState(
    pos: entity.pos,
    facing: _directionFromEntityFacing(entity.spawn?.facing),
  );
}

Direction _directionFromEntityFacing(EntityFacing? facing) {
  if (facing == null) return _kDefaultFacing;
  return facing.asDirection;
}
