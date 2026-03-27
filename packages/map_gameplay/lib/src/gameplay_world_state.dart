import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_exceptions.dart';
import 'gameplay_player_state.dart';
import 'player_spawn_resolver.dart';

class GameplayWorldState {
  GameplayWorldState._({
    required this.map,
    required this.player,
    required List<bool> collisionCache,
    required Map<int, MapWarp> warpByPos,
    required Map<int, MapEntity> entityByPos,
  })  : _collisionCache = collisionCache,
        _warpByPos = warpByPos,
        _entityByPos = entityByPos;

  factory GameplayWorldState.initial({
    required MapData map,
    required GridPos playerPos,
    Direction playerFacing = Direction.south,
  }) =>
      GameplayWorldState._(
        map: map,
        player: GameplayPlayerState(pos: playerPos, facing: playerFacing),
        collisionCache: _buildCollisionCache(map),
        warpByPos: _buildWarpByPos(map),
        entityByPos: _buildEntityByPos(map),
      );

  factory GameplayWorldState.fromMap(MapData map) {
    final player = resolveInitialPlayerSpawn(map);
    final cache = _buildCollisionCache(map);
    final warps = _buildWarpByPos(map);
    final entities = _buildEntityByPos(map);
    final world = GameplayWorldState._(
      map: map,
      player: player,
      collisionCache: cache,
      warpByPos: warps,
      entityByPos: entities,
    );
    if (world.isBlocked(player.pos.x, player.pos.y)) {
      throw GameplaySpawnResolutionException(
        'Player spawn at (${player.pos.x}, ${player.pos.y}) is on a blocked cell',
      );
    }
    return world;
  }

  final MapData map;
  final GameplayPlayerState player;
  final List<bool> _collisionCache;
  final Map<int, MapWarp> _warpByPos;
  final Map<int, MapEntity> _entityByPos;

  bool isBlocked(int x, int y) {
    if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
      return true;
    }
    final idx = y * map.size.width + x;
    if (idx >= _collisionCache.length) return false;
    return _collisionCache[idx];
  }

  MapWarp? warpAt(int x, int y) => _warpByPos[y * map.size.width + x];

  MapEntity? entityAt(int x, int y) => _entityByPos[y * map.size.width + x];

  GameplayWorldState withPlayer(GameplayPlayerState player) =>
      GameplayWorldState._(
        map: map,
        player: player,
        collisionCache: _collisionCache,
        warpByPos: _warpByPos,
        entityByPos: _entityByPos,
      );
}

List<bool> _buildCollisionCache(MapData map) {
  final size = map.size.width * map.size.height;
  final cache = List<bool>.filled(size, false);
  for (final layer in map.layers) {
    layer.whenOrNull(
      collision: (id, name, isVisible, opacity, collisions) {
        for (var i = 0; i < collisions.length && i < size; i++) {
          if (collisions[i]) cache[i] = true;
        }
      },
    );
  }
  return cache;
}

Map<int, MapWarp> _buildWarpByPos(MapData map) {
  final w = map.size.width;
  return {
    for (final warp in map.warps) warp.pos.y * w + warp.pos.x: warp,
  };
}

Map<int, MapEntity> _buildEntityByPos(MapData map) {
  final w = map.size.width;
  return {
    for (final entity in map.entities)
      if (entity.kind != MapEntityKind.spawn)
        entity.pos.y * w + entity.pos.x: entity,
  };
}
