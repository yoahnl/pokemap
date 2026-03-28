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
    required Map<int, MapEntity> blockingEntityByPos,
    required Map<int, List<MapWarp>> warpCandidatesByPos,
    required Map<int, MapEntity> entityByPos,
    required int tileWidth,
    required int tileHeight,
  })  : _collisionCache = collisionCache,
        _blockingEntityByPos = blockingEntityByPos,
        _warpCandidatesByPos = warpCandidatesByPos,
        _entityByPos = entityByPos,
        _tileWidth = tileWidth <= 0 ? 16 : tileWidth,
        _tileHeight = tileHeight <= 0 ? 16 : tileHeight;

  factory GameplayWorldState.initial({
    required MapData map,
    required GridPos playerPos,
    Direction playerFacing = Direction.south,
    ProjectManifest? project,
    int tileWidth = 16,
    int tileHeight = 16,
  }) =>
      GameplayWorldState._(
        map: map,
        player: GameplayPlayerState(pos: playerPos, facing: playerFacing),
        collisionCache: _buildCollisionCache(map, project: project),
        blockingEntityByPos: _buildBlockingEntityByPos(map),
        warpCandidatesByPos:
            _buildWarpCandidatesByPos(map, tileWidth, tileHeight),
        entityByPos: _buildEntityByPos(map),
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      );

  factory GameplayWorldState.fromMap(
    MapData map, {
    ProjectManifest? project,
    int tileWidth = 16,
    int tileHeight = 16,
  }) {
    final player = resolveInitialPlayerSpawn(map);
    final cache = _buildCollisionCache(map, project: project);
    final blockingEntities = _buildBlockingEntityByPos(map);
    final warps = _buildWarpCandidatesByPos(map, tileWidth, tileHeight);
    final entities = _buildEntityByPos(map);
    final world = GameplayWorldState._(
      map: map,
      player: player,
      collisionCache: cache,
      blockingEntityByPos: blockingEntities,
      warpCandidatesByPos: warps,
      entityByPos: entities,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
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
  final Map<int, MapEntity> _blockingEntityByPos;
  final Map<int, List<MapWarp>> _warpCandidatesByPos;
  final Map<int, MapEntity> _entityByPos;
  final int _tileWidth;
  final int _tileHeight;

  bool isBlocked(int x, int y) {
    if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
      return true;
    }
    final idx = y * map.size.width + x;
    if (idx < _collisionCache.length && _collisionCache[idx]) return true;
    final entity = _blockingEntityByPos[idx];
    return entity != null && entity.blocksMovement;
  }

  MapWarp? warpAt(int x, int y) {
    return _resolveWarpCandidate(
      x: x,
      y: y,
      mode: MapWarpTriggerMode.onEnter,
      approachFacing: null,
    );
  }

  MapWarp? warpOnEnterAt(
    int x,
    int y,
    Direction approachDirection,
  ) {
    return _resolveWarpCandidate(
      x: x,
      y: y,
      mode: MapWarpTriggerMode.onEnter,
      approachFacing: _approachSideFacing(approachDirection),
    );
  }

  MapWarp? warpOnBumpAt(
    int x,
    int y,
    Direction approachDirection,
  ) {
    return _resolveWarpCandidate(
      x: x,
      y: y,
      mode: MapWarpTriggerMode.onBump,
      approachFacing: _approachSideFacing(approachDirection),
    );
  }

  MapEntity? entityAt(int x, int y) => _entityByPos[y * map.size.width + x];

  GameplayWorldState withPlayer(GameplayPlayerState player) =>
      GameplayWorldState._(
        map: map,
        player: player,
        collisionCache: _collisionCache,
        blockingEntityByPos: _blockingEntityByPos,
        warpCandidatesByPos: _warpCandidatesByPos,
        entityByPos: _entityByPos,
        tileWidth: _tileWidth,
        tileHeight: _tileHeight,
      );

  MapWarp? _resolveWarpCandidate({
    required int x,
    required int y,
    required MapWarpTriggerMode mode,
    required EntityFacing? approachFacing,
  }) {
    if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
      return null;
    }
    final candidates = _warpCandidatesByPos[y * map.size.width + x];
    if (candidates == null || candidates.isEmpty) {
      return null;
    }
    for (final warp in candidates) {
      if (warp.triggerMode != mode) {
        continue;
      }
      if (approachFacing != null &&
          !_matchesApproachFacing(warp, approachFacing)) {
        continue;
      }
      return warp;
    }
    return null;
  }

  bool _matchesApproachFacing(
    MapWarp warp,
    EntityFacing approachFacing,
  ) {
    final allowed = warp.allowedApproachFacings;
    if (allowed.isEmpty) {
      return true;
    }
    return allowed.contains(approachFacing);
  }

  EntityFacing _approachSideFacing(Direction direction) {
    return switch (direction) {
      Direction.north => EntityFacing.south,
      Direction.south => EntityFacing.north,
      Direction.east => EntityFacing.west,
      Direction.west => EntityFacing.east,
    };
  }
}

List<bool> _buildCollisionCache(
  MapData map, {
  ProjectManifest? project,
}) {
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
  final elementById = project == null
      ? const <String, ProjectElementEntry>{}
      : {
          for (final entry in project.elements) entry.id: entry,
        };
  for (final instance in map.placedElements) {
    if (!instance.applyCollision) {
      continue;
    }
    final profile = elementById[instance.elementId]?.collisionProfile;
    if (profile == null || profile.cells.isEmpty) {
      continue;
    }
    for (final localCell in profile.cells) {
      final x = instance.pos.x + localCell.x;
      final y = instance.pos.y + localCell.y;
      if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
        continue;
      }
      cache[y * map.size.width + x] = true;
    }
  }
  return cache;
}

Map<int, List<MapWarp>> _buildWarpCandidatesByPos(
  MapData map,
  int tileWidth,
  int tileHeight,
) {
  final safeTileWidth = tileWidth <= 0 ? 16 : tileWidth;
  final safeTileHeight = tileHeight <= 0 ? 16 : tileHeight;
  final w = map.size.width;
  final h = map.size.height;
  final result = <int, List<MapWarp>>{};
  for (final warp in map.warps) {
    final padding = warp.triggerPadding;
    final leftPx = warp.pos.x * safeTileWidth - padding.left;
    final topPx = warp.pos.y * safeTileHeight - padding.top;
    final rightPx = (warp.pos.x + 1) * safeTileWidth + padding.right;
    final bottomPx = (warp.pos.y + 1) * safeTileHeight + padding.bottom;
    final minX = (leftPx / safeTileWidth).floor();
    final maxX = ((rightPx - 1) / safeTileWidth).floor();
    final minY = (topPx / safeTileHeight).floor();
    final maxY = ((bottomPx - 1) / safeTileHeight).floor();
    if (maxX < 0 || maxY < 0 || minX >= w || minY >= h) {
      continue;
    }
    final clampedMinX = minX < 0 ? 0 : minX;
    final clampedMinY = minY < 0 ? 0 : minY;
    final clampedMaxX = maxX >= w ? w - 1 : maxX;
    final clampedMaxY = maxY >= h ? h - 1 : maxY;
    for (var y = clampedMinY; y <= clampedMaxY; y++) {
      for (var x = clampedMinX; x <= clampedMaxX; x++) {
        final index = y * w + x;
        result.putIfAbsent(index, () => <MapWarp>[]).add(warp);
      }
    }
  }
  return result;
}

Map<int, MapEntity> _buildBlockingEntityByPos(MapData map) {
  final w = map.size.width;
  final result = <int, MapEntity>{};
  for (final entity in map.entities) {
    if (!_isEntityBlockingCandidate(entity)) continue;
    for (final cell in resolveEntityCollisionCells(entity)) {
      if (cell.x < 0 ||
          cell.y < 0 ||
          cell.x >= map.size.width ||
          cell.y >= map.size.height) {
        continue;
      }
      result[cell.y * w + cell.x] = entity;
    }
  }
  return result;
}

Map<int, MapEntity> _buildEntityByPos(MapData map) {
  final w = map.size.width;
  final result = <int, MapEntity>{};
  for (final entity in map.entities) {
    if (entity.kind == MapEntityKind.spawn) continue;
    for (final cell in resolveEntityCollisionCells(entity)) {
      if (cell.x < 0 ||
          cell.y < 0 ||
          cell.x >= map.size.width ||
          cell.y >= map.size.height) {
        continue;
      }
      result[cell.y * w + cell.x] = entity;
    }
  }
  return result;
}

bool _isEntityBlockingCandidate(MapEntity entity) {
  if (!entity.blocksMovement) return false;
  if (entity.kind == MapEntityKind.spawn) return false;
  if (entity.kind != MapEntityKind.custom) return true;
  return _hasExplicitCollisionOverride(entity);
}

bool _hasExplicitCollisionOverride(MapEntity entity) {
  const keys = <String>{
    mapEntityCollisionWidthProperty,
    mapEntityCollisionHeightProperty,
    mapEntityCollisionOffsetXProperty,
    mapEntityCollisionOffsetYProperty,
    'collisionWidth',
    'collisionHeight',
    'collisionOffsetX',
    'collisionOffsetY',
  };
  for (final key in keys) {
    final value = entity.properties[key];
    if (value == null) continue;
    if (value.trim().isEmpty) continue;
    return true;
  }
  return false;
}
