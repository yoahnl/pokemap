import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'border_directed_jump_binding.dart';
import 'gameplay_exceptions.dart';
import 'movement_block_reason.dart';
import 'gameplay_player_state.dart';
import 'player_spawn_resolver.dart';
import 'collision/world_collision_storage.dart';
import 'collision/border_collision_geometry.dart';

/// Indique si un PNJ doit exister sur la grille pour collision et interaction.
///
/// Si le callback retourne `false`, le moteur ignore ce PNJ dans les caches
/// spatiaux : il ne bloque plus le joueur et [GameplayWorldState.entityAt]
/// ne le voit pas. Les autres types d'entités (panneaux, objets, etc.) ne
/// passent jamais par ce filtre.
///
/// [mapId] doit être [MapData.id] de la carte qui contient [npcEntity], afin
/// que le runtime puisse appliquer des règles « par carte » (ex. worldChanges
/// Step Studio : `mapId` authoring).
///
/// Fourni par le runtime (visibilité PNJ + progression) sans que
/// [map_gameplay] ne connaisse les flags / steps.
typedef NpcMapPresencePredicate = bool Function(
  String mapId,
  MapEntity npcEntity,
);

/// Indique si une entité de map doit exister dans les caches spatiaux.
///
/// Contrairement à [NpcMapPresencePredicate], ce filtre s'applique aussi aux
/// objets et panneaux. Les deux prédicats sont combinés pour les PNJ afin de
/// préserver les règles historiques tout en permettant aux World Rules de
/// masquer un indice ou une barrière physique.
typedef MapEntityPresencePredicate = bool Function(
  String mapId,
  MapEntity entity,
);

class GameplayWorldState {
  GameplayWorldState._({
    required this.map,
    required this.player,
    required this.borderJumpBindings,
    required List<bool> tileCollisionCellCache,
    required List<bool> placedElementCellCollisionCache,
    required WorldCollisionStorage staticCollisionStorage,
    required Map<int, List<MapEntity>> blockingEntityByPos,
    required Map<int, List<MapWarp>> warpCandidatesByPos,
    required Map<int, MapEntity> entityByPos,
    required Map<int, PlacedElementBehaviorActivation> actionBehaviorByPos,
    required Map<int, PlacedElementBehaviorActivation> enterBehaviorByPos,
    required Map<int, PlacedElementBehaviorActivation> bumpBehaviorByPos,
    required Map<int, PlacedElementBehaviorActivation> exitBehaviorByPos,
    required Map<int, PlacedElementBehaviorActivation> nearBehaviorByPos,
    required Map<int, Set<String>> placedElementCoverageByPos,
    required List<bool> waterCellCache,
    required int tileWidth,
    required int tileHeight,
    this.npcMapPresencePredicate,
    this.mapEntityPresencePredicate,
  })  : _tileCollisionCellCache = tileCollisionCellCache,
        _placedElementCellCollisionCache = placedElementCellCollisionCache,
        _staticCollisionStorage = staticCollisionStorage,
        _blockingEntityByPos = blockingEntityByPos,
        _warpCandidatesByPos = warpCandidatesByPos,
        _entityByPos = entityByPos,
        _actionBehaviorByPos = actionBehaviorByPos,
        _enterBehaviorByPos = enterBehaviorByPos,
        _bumpBehaviorByPos = bumpBehaviorByPos,
        _exitBehaviorByPos = exitBehaviorByPos,
        _nearBehaviorByPos = nearBehaviorByPos,
        _placedElementCoverageByPos = placedElementCoverageByPos,
        _waterCellCache = waterCellCache,
        _tileWidth = tileWidth <= 0 ? 16 : tileWidth,
        _tileHeight = tileHeight <= 0 ? 16 : tileHeight;

  factory GameplayWorldState.initial({
    required MapData map,
    required GridPos playerPos,
    Direction playerFacing = Direction.south,
    MovementMode playerMovementMode = MovementMode.walk,
    ProjectManifest? project,
    MovingPlatformWorldState movingPlatformWorldState = const MovingPlatformWorldState.empty(),
    int tileWidth = 16,
    int tileHeight = 16,
    NpcMapPresencePredicate? npcMapPresencePredicate,
    MapEntityPresencePredicate? mapEntityPresencePredicate,
  }) {
    map = applyMovingPlatformWorldStateToMap(map: map,
        worldState: movingPlatformWorldState,
        tileSize: PixelSize(width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight));
    map = _captureBorderJumpMap(map, project);
    final borderBindings = _bindBorderJumps(map, project, tileWidth, tileHeight);
    final blockingEntities = _buildBlockingEntityByPos(
      map,
      npcPresence: npcMapPresencePredicate,
      entityPresence: mapEntityPresencePredicate,
    );
    final placedElementCellCollisionCache =
        _buildPlacedElementCellCollisionCache(
      map,
      project: project,
    );
    final tileCollisionCellCache = _buildTileCollisionCellCache(
      map,
      project: project,
    );
    return GameplayWorldState._(
      map: map,
      player: GameplayPlayerState.fromGridSpawn(
        cell: playerPos,
        facing: playerFacing,
        movementMode: playerMovementMode,
        tileWidthPx: tileWidth,
        tileHeightPx: tileHeight,
        mapWidthCells: map.size.width,
        mapHeightCells: map.size.height,
      ),
      borderJumpBindings: borderBindings,
      tileCollisionCellCache: tileCollisionCellCache,
      placedElementCellCollisionCache: placedElementCellCollisionCache,
      blockingEntityByPos: blockingEntities,
      staticCollisionStorage: _buildStaticCollisionStorage(
        map,
        project: project,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        tileCollisionCellCache: tileCollisionCellCache,
        movingPlatformWorldState: movingPlatformWorldState,
        placedElementCellCollisionCache: placedElementCellCollisionCache,
      ),
      warpCandidatesByPos:
          _buildWarpCandidatesByPos(map, tileWidth, tileHeight),
      entityByPos: _buildEntityByPos(
        map,
        npcPresence: npcMapPresencePredicate,
        entityPresence: mapEntityPresencePredicate,
      ),
      actionBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
        trigger: MapPlacedElementTriggerType.onAction,
      ),
      enterBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
        trigger: MapPlacedElementTriggerType.onEnter,
      ),
      bumpBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
        trigger: MapPlacedElementTriggerType.onBump,
      ),
      exitBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
        trigger: MapPlacedElementTriggerType.onExit,
      ),
      nearBehaviorByPos: _buildPlacedElementNearBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
      ),
      placedElementCoverageByPos: _buildPlacedElementCoverageByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
      ),
      waterCellCache: _buildWaterCellCache(map),
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      npcMapPresencePredicate: npcMapPresencePredicate,
      mapEntityPresencePredicate: mapEntityPresencePredicate,
    );
  }

  factory GameplayWorldState.fromMap(
    MapData map, {
    ProjectManifest? project,
    MovingPlatformWorldState movingPlatformWorldState = const MovingPlatformWorldState.empty(),
    int tileWidth = 16,
    int tileHeight = 16,
    NpcMapPresencePredicate? npcMapPresencePredicate,
    MapEntityPresencePredicate? mapEntityPresencePredicate,
  }) {
    map = applyMovingPlatformWorldStateToMap(map: map,
        worldState: movingPlatformWorldState,
        tileSize: PixelSize(width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight));
    map = _captureBorderJumpMap(map, project);
    final borderBindings = _bindBorderJumps(map, project, tileWidth, tileHeight);
    final player = resolveInitialPlayerSpawn(
      map,
      tileWidthPx: tileWidth,
      tileHeightPx: tileHeight,
    );
    final cache = _buildTileCollisionCellCache(
      map,
      project: project,
    );
    final placedElementCellCollisionCache =
        _buildPlacedElementCellCollisionCache(
      map,
      project: project,
    );
    final blockingEntities = _buildBlockingEntityByPos(
      map,
      npcPresence: npcMapPresencePredicate,
      entityPresence: mapEntityPresencePredicate,
    );
    final staticCollisionStorage = _buildStaticCollisionStorage(
      map,
      project: project,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      tileCollisionCellCache: cache,
      movingPlatformWorldState: movingPlatformWorldState,
      placedElementCellCollisionCache: placedElementCellCollisionCache,
    );
    final warps = _buildWarpCandidatesByPos(map, tileWidth, tileHeight);
    final entities = _buildEntityByPos(
      map,
      npcPresence: npcMapPresencePredicate,
      entityPresence: mapEntityPresencePredicate,
    );
    final world = GameplayWorldState._(
      map: map,
      player: player,
      borderJumpBindings: borderBindings,
      tileCollisionCellCache: cache,
      placedElementCellCollisionCache: placedElementCellCollisionCache,
      staticCollisionStorage: staticCollisionStorage,
      blockingEntityByPos: blockingEntities,
      warpCandidatesByPos: warps,
      entityByPos: entities,
      actionBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
        trigger: MapPlacedElementTriggerType.onAction,
      ),
      enterBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
        trigger: MapPlacedElementTriggerType.onEnter,
      ),
      bumpBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
        trigger: MapPlacedElementTriggerType.onBump,
      ),
      exitBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
        trigger: MapPlacedElementTriggerType.onExit,
      ),
      nearBehaviorByPos: _buildPlacedElementNearBehaviorByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
      ),
      placedElementCoverageByPos: _buildPlacedElementCoverageByPos(
        map,
        project: project,
        tileSize: PixelSize(
            width: tileWidth <= 0 ? 16 : tileWidth,
            height: tileHeight <= 0 ? 16 : tileHeight),
      ),
      waterCellCache: _buildWaterCellCache(map),
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      npcMapPresencePredicate: npcMapPresencePredicate,
      mapEntityPresencePredicate: mapEntityPresencePredicate,
    );
    if (world.worldStaticObstaclesCollidePlayerCollisionRect()) {
      throw GameplaySpawnResolutionException(
        'Player spawn collision rect overlaps static obstacles '
        'at (${player.pos.x}, ${player.pos.y})',
      );
    }
    return world;
  }

  final MapData map;
  final GameplayPlayerState player;
  final List<BorderDirectedJumpBinding> borderJumpBindings;

  /// Filtre optionnel de présence des PNJ sur la grille (voir [NpcMapPresencePredicate]).
  final NpcMapPresencePredicate? npcMapPresencePredicate;

  /// Filtre optionnel commun aux PNJ, objets et panneaux.
  final MapEntityPresencePredicate? mapEntityPresencePredicate;

  /// Calque collision **tuiles** uniquement (grille auteur). Pas les éléments placés.
  final List<bool> _tileCollisionCellCache;
  final List<bool> _placedElementCellCollisionCache;
  final WorldCollisionStorage _staticCollisionStorage;
  final Map<int, List<MapEntity>> _blockingEntityByPos;
  final Map<int, List<MapWarp>> _warpCandidatesByPos;
  final Map<int, MapEntity> _entityByPos;
  final Map<int, PlacedElementBehaviorActivation> _actionBehaviorByPos;
  final Map<int, PlacedElementBehaviorActivation> _enterBehaviorByPos;
  final Map<int, PlacedElementBehaviorActivation> _bumpBehaviorByPos;
  final Map<int, PlacedElementBehaviorActivation> _exitBehaviorByPos;
  final Map<int, PlacedElementBehaviorActivation> _nearBehaviorByPos;
  final Map<int, Set<String>> _placedElementCoverageByPos;
  final List<bool> _waterCellCache;
  final int _tileWidth;
  final int _tileHeight;

  /// Taille tuile projet (pixels) — nécessaire pour projection pieds / rendu.
  int get tileWidthPx => _tileWidth;
  int get tileHeightPx => _tileHeight;

  /// Collision **déplacement** : hitbox joueur vs bitmap statique monde.
  bool worldStaticObstaclesCollidePlayerCollisionRect() {
    return worldStaticObstaclesCollidePixelRect(player.playerCollisionRectPx,
        playerContact: true);
  }

  /// Test pixel-level contre l’union des obstacles statiques (bitmap monde).
  bool worldStaticObstaclesCollidePixelRect(PixelRect rect,
      {bool playerContact = false,
      BorderCollisionExclusion? borderExclusion,
      String? ignoredEntityId, String? permittedWaterfallZoneId}) {
    if (rect.widthPx <= 0 || rect.heightPx <= 0) return false;
    for (final zone in map.gameplayZones) {
      if (zone.kind != GameplayZoneKind.fieldAction ||
          zone.fieldAction?.actionKind != FieldActionZoneKind.waterfall ||
          zone.id == permittedWaterfallZoneId) {
        continue;
      }
      for (final cell in zone.fieldAction!.waterfall!.path) {
        final left = (zone.area.pos.x + cell.x) * _tileWidth;
        final top = (zone.area.pos.y + cell.y) * _tileHeight;
        if (rect.leftPx < left + _tileWidth &&
            rect.leftPx + rect.widthPx > left &&
            rect.topPx < top + _tileHeight &&
            rect.topPx + rect.heightPx > top) {
          return true;
        }
      }
    }
    if (_staticCollisionStorage.collidesPixelRect(
      rect,
      isDynamicCellBlocked: (_) => false,
      borderExclusion: borderExclusion,
    )) {
      return true;
    }
    return mapEntitiesCollidePixelRect(
      rect,
      playerContact: playerContact,
      ignoredEntityId: ignoredEntityId,
    );
  }

  bool mapEntitiesCollidePixelRect(
    PixelRect rect, {
    bool playerContact = false,
    String? ignoredEntityId,
  }) {
    if (rect.widthPx <= 0 || rect.heightPx <= 0) return false;
    final contact = playerContact ? playerCharacterContactRect(rect) : rect;
    final left = contact.leftPx < rect.leftPx ? contact.leftPx : rect.leftPx;
    final top = contact.topPx < rect.topPx ? contact.topPx : rect.topPx;
    final right = contact.leftPx + contact.widthPx > rect.leftPx + rect.widthPx
        ? contact.leftPx + contact.widthPx
        : rect.leftPx + rect.widthPx;
    final bottom = contact.topPx + contact.heightPx > rect.topPx + rect.heightPx
        ? contact.topPx + contact.heightPx
        : rect.topPx + rect.heightPx;
    for (var y = top ~/ _tileHeight; y <= (bottom - 1) ~/ _tileHeight; y++) {
      for (var x = left ~/ _tileWidth; x <= (right - 1) ~/ _tileWidth; x++) {
        final entities = _blockingEntityByPos[y * map.size.width + x];
        if (entities == null) continue;
        for (final entity in entities) {
          if (entity.kind == MapEntityKind.npc && entity.id == ignoredEntityId) {
            continue;
          }
          final obstacle = resolveEntityCollisionRectPx(
            entity,
            tileWidthPx: _tileWidth,
            tileHeightPx: _tileHeight,
          );
          final moving = entity.kind == MapEntityKind.npc ? contact : rect;
          if (moving.leftPx < obstacle.leftPx + obstacle.widthPx &&
              moving.leftPx + moving.widthPx > obstacle.leftPx &&
              moving.topPx < obstacle.topPx + obstacle.heightPx &&
              moving.topPx + moving.heightPx > obstacle.topPx) {
            return true;
          }
        }
      }
    }
    return false;
  }

  PixelRect playerCharacterContactRect(PixelRect movementRect) =>
      PlayerCollisionConventionsV1.characterContactRectFromMovementRect(
        movementRect: movementRect,
        tileWidthPx: _tileWidth,
        tileHeightPx: _tileHeight,
      );

  /// PNJ scripté / pathfinding : centre de case → bitmap (pas une primitive joueur).
  bool isCellCenterBlockedLegacyForGridIndexedSystems(
    int cellX,
    int cellY, {
    String? ignoredEntityId,
  }) {
    if (cellX < 0 ||
        cellY < 0 ||
        cellX >= map.size.width ||
        cellY >= map.size.height) {
      return true;
    }
    for (final zone in map.gameplayZones) {
      if (zone.fieldAction?.actionKind == FieldActionZoneKind.waterfall &&
          (zone.fieldAction?.waterfall?.path.any(
                (cell) =>
                    zone.area.pos.x + cell.x == cellX &&
                    zone.area.pos.y + cell.y == cellY,
              ) ??
              false)) {
        return true;
      }
    }
    return _staticCollisionStorage.isCellCenterBlocked(
      cellX,
      cellY,
      isDynamicCellBlocked: (index) {
        final entities = _blockingEntityByPos[index];
        return entities != null &&
            entities.any((entity) => entity.id != ignoredEntityId);
      },
    );
  }

  bool isWaterCell(int x, int y) {
    if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
      return false;
    }
    final idx = y * map.size.width + x;
    if (idx < 0 || idx >= _waterCellCache.length) {
      return false;
    }
    return _waterCellCache[idx];
  }

  /// Eau / surf sur une **cellule** (données grille — pas la collision pixel décor).
  GameplayMovementBlockReason?
      movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial({
    required int cellX,
    required int cellY,
    required MovementMode movementMode,
  }) {
    if (isWaterCell(cellX, cellY) && movementMode != MovementMode.surf) {
      return GameplayMovementBlockReason.waterRequiresSurf;
    }
    if (isCellCenterBlockedLegacyForGridIndexedSystems(cellX, cellY)) {
      return GameplayMovementBlockReason.solid;
    }
    return null;
  }

  GameplayMovementBlockReason? movementBlockReasonAt({
    required int x,
    required int y,
    required MovementMode movementMode,
  }) {
    if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
      return GameplayMovementBlockReason.outOfBounds;
    }
    if (isCellCenterBlockedLegacyForGridIndexedSystems(x, y)) {
      return GameplayMovementBlockReason.solid;
    }
    return movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial(
      cellX: x,
      cellY: y,
      movementMode: movementMode,
    );
  }

  bool isBlocked(
    int x,
    int y, {
    MovementMode? movementMode,
  }) {
    return movementBlockReasonAt(
          x: x,
          y: y,
          movementMode: movementMode ?? player.movementMode,
        ) !=
        null;
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

  PlacedElementBehaviorActivation? placedElementBehaviorOnActionAt(
    int x,
    int y,
  ) =>
      _actionBehaviorByPos[y * map.size.width + x];

  PlacedElementBehaviorActivation? placedElementBehaviorOnEnterAt(
    int x,
    int y,
  ) =>
      _enterBehaviorByPos[y * map.size.width + x];

  PlacedElementBehaviorActivation? placedElementBehaviorOnBumpAt(
    int x,
    int y,
  ) =>
      _bumpBehaviorByPos[y * map.size.width + x];

  PlacedElementBehaviorActivation? placedElementBehaviorOnExitAt(
    int x,
    int y,
  ) =>
      _exitBehaviorByPos[y * map.size.width + x];

  PlacedElementBehaviorActivation? placedElementBehaviorOnNearAt(
    int x,
    int y,
  ) =>
      _nearBehaviorByPos[y * map.size.width + x];

  bool isFacingPlacedElement({
    required GridPos playerPos,
    required Direction facing,
    required MapPlacedElement element,
  }) {
    final tx = playerPos.x + facing.dx;
    final ty = playerPos.y + facing.dy;
    if (tx < 0 || ty < 0 || tx >= map.size.width || ty >= map.size.height) {
      return false;
    }
    final index = ty * map.size.width + tx;
    final coveredInstances = _placedElementCoverageByPos[index];
    if (coveredInstances == null || coveredInstances.isEmpty) {
      return false;
    }
    return coveredInstances.contains(element.id);
  }

  PlacedElementBehaviorActivation? placedElementBehaviorOnExitTransition({
    required GridPos from,
    required GridPos to,
  }) {
    final fromActivation = placedElementBehaviorOnExitAt(from.x, from.y);
    if (fromActivation == null) {
      return null;
    }
    final toActivation = placedElementBehaviorOnExitAt(to.x, to.y);
    if (_isSameBehaviorActivation(fromActivation, toActivation)) {
      return null;
    }
    return fromActivation;
  }

  PlacedElementBehaviorActivation? placedElementBehaviorOnNearTransition({
    required GridPos from,
    required GridPos to,
  }) {
    final toActivation = placedElementBehaviorOnNearAt(to.x, to.y);
    if (toActivation == null) {
      return null;
    }
    final fromActivation = placedElementBehaviorOnNearAt(from.x, from.y);
    if (_isSameBehaviorActivation(fromActivation, toActivation)) {
      return null;
    }
    return toActivation;
  }

  GameplayWorldState withPlayer(GameplayPlayerState player) =>
      GameplayWorldState._(
        map: map,
        player: player,
        tileCollisionCellCache: _tileCollisionCellCache,
        placedElementCellCollisionCache: _placedElementCellCollisionCache,
        staticCollisionStorage: _staticCollisionStorage,
      borderJumpBindings: borderJumpBindings,
        blockingEntityByPos: _blockingEntityByPos,
        warpCandidatesByPos: _warpCandidatesByPos,
        entityByPos: _entityByPos,
        actionBehaviorByPos: _actionBehaviorByPos,
        enterBehaviorByPos: _enterBehaviorByPos,
        bumpBehaviorByPos: _bumpBehaviorByPos,
        exitBehaviorByPos: _exitBehaviorByPos,
        nearBehaviorByPos: _nearBehaviorByPos,
        placedElementCoverageByPos: _placedElementCoverageByPos,
        waterCellCache: _waterCellCache,
        tileWidth: _tileWidth,
        tileHeight: _tileHeight,
        npcMapPresencePredicate: npcMapPresencePredicate,
        mapEntityPresencePredicate: mapEntityPresencePredicate,
      );

  /// Reconstruit les caches spatiaux PNJ après changement de progression (visibilité).
  GameplayWorldState withNpcMapPresencePredicate(
    NpcMapPresencePredicate? predicate,
  ) {
    final newBlocking = _buildBlockingEntityByPos(
      map,
      npcPresence: predicate,
      entityPresence: mapEntityPresencePredicate,
    );
    return GameplayWorldState._(
      map: map,
      player: player,
      tileCollisionCellCache: _tileCollisionCellCache,
      placedElementCellCollisionCache: _placedElementCellCollisionCache,
      staticCollisionStorage: _staticCollisionStorage,
      borderJumpBindings: borderJumpBindings,
      blockingEntityByPos: newBlocking,
      entityByPos: _buildEntityByPos(
        map,
        npcPresence: predicate,
        entityPresence: mapEntityPresencePredicate,
      ),
      warpCandidatesByPos: _warpCandidatesByPos,
      actionBehaviorByPos: _actionBehaviorByPos,
      enterBehaviorByPos: _enterBehaviorByPos,
      bumpBehaviorByPos: _bumpBehaviorByPos,
      exitBehaviorByPos: _exitBehaviorByPos,
      nearBehaviorByPos: _nearBehaviorByPos,
      placedElementCoverageByPos: _placedElementCoverageByPos,
      waterCellCache: _waterCellCache,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
      npcMapPresencePredicate: predicate,
      mapEntityPresencePredicate: mapEntityPresencePredicate,
    );
  }

  /// Reconstruit les caches spatiaux de toutes les entités après projection
  /// d'un changement de monde (barrière, indice, objet consommé, etc.).
  GameplayWorldState withMapEntityPresencePredicate(
    MapEntityPresencePredicate? predicate,
  ) {
    final newBlocking = _buildBlockingEntityByPos(
      map,
      npcPresence: npcMapPresencePredicate,
      entityPresence: predicate,
    );
    return GameplayWorldState._(
      map: map,
      player: player,
      tileCollisionCellCache: _tileCollisionCellCache,
      placedElementCellCollisionCache: _placedElementCellCollisionCache,
      staticCollisionStorage: _staticCollisionStorage,
      borderJumpBindings: borderJumpBindings,
      blockingEntityByPos: newBlocking,
      entityByPos: _buildEntityByPos(
        map,
        npcPresence: npcMapPresencePredicate,
        entityPresence: predicate,
      ),
      warpCandidatesByPos: _warpCandidatesByPos,
      actionBehaviorByPos: _actionBehaviorByPos,
      enterBehaviorByPos: _enterBehaviorByPos,
      bumpBehaviorByPos: _bumpBehaviorByPos,
      exitBehaviorByPos: _exitBehaviorByPos,
      nearBehaviorByPos: _nearBehaviorByPos,
      placedElementCoverageByPos: _placedElementCoverageByPos,
      waterCellCache: _waterCellCache,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
      npcMapPresencePredicate: npcMapPresencePredicate,
      mapEntityPresencePredicate: predicate,
    );
  }

  GameplayWorldState withEntityFacing(String entityId, EntityFacing facing) {
    final matching = <int>[
      for (var index = 0; index < map.entities.length; index++)
        if (map.entities[index].id == entityId) index,
    ];
    if (matching.length != 1) {
      throw StateError('Actor facing requires one unambiguous NPC.');
    }
    final index = matching.single;
    final entity = map.entities[index];
    final npc = entity.npc;
    if (entity.kind != MapEntityKind.npc || npc == null) {
      throw StateError('Actor facing requires NPC data.');
    }
    if (npc.facing == facing) {
      return this;
    }
    return _withUpdatedEntity(index, entity.copyWith(npc: npc.copyWith(facing: facing)));
  }

  /// Retourne un nouvel état monde où la position d'une entité est mise à jour.
  ///
  /// Cette méthode est la brique clé pour les déplacements PNJ scriptés:
  /// - la map runtime reste la source de vérité des entités bloquantes;
  /// - les caches collision/entity sont reconstruits proprement;
  /// - le reste du runtime (interactions, LoS, blocage joueur) lit
  ///   automatiquement la nouvelle position sans logique ad hoc.
  ///
  /// IMPORTANT:
  /// - si l'entité n'existe pas, on retourne `this` (no-op sûr);
  /// - on ne modifie pas les layers auteur ; le stockage statique est partagé,
  ///   seule l'occupation dynamique des entités est reconstruite.
  GameplayWorldState withEntityPosition(
    String entityId,
    GridPos newPos,
  ) {
    final normalizedId = entityId.trim();
    if (normalizedId.isEmpty) {
      return this;
    }
    final index =
        map.entities.indexWhere((entity) => entity.id == normalizedId);
    if (index < 0) {
      return this;
    }

    final entity = map.entities[index];
    if (entity.pos.x == newPos.x && entity.pos.y == newPos.y) {
      return this;
    }

    return _withUpdatedEntity(index, entity.copyWith(pos: newPos));
  }

  GameplayWorldState _withUpdatedEntity(int index, MapEntity entity) {
    final updatedEntities = List<MapEntity>.from(map.entities);
    updatedEntities[index] = entity;
    final updatedMap = map.copyWith(entities: updatedEntities);

    final newBlocking = _buildBlockingEntityByPos(
      updatedMap,
      npcPresence: npcMapPresencePredicate,
      entityPresence: mapEntityPresencePredicate,
    );
    return GameplayWorldState._(
      map: updatedMap,
      player: player,
      tileCollisionCellCache: _tileCollisionCellCache,
      placedElementCellCollisionCache: _placedElementCellCollisionCache,
      staticCollisionStorage: _staticCollisionStorage,
      borderJumpBindings: borderJumpBindings,
      // Les entités bloquantes et interactives doivent refléter la nouvelle map.
      blockingEntityByPos: newBlocking,
      entityByPos: _buildEntityByPos(
        updatedMap,
        npcPresence: npcMapPresencePredicate,
        entityPresence: mapEntityPresencePredicate,
      ),
      // Les warps et behaviors restent valides : ils ne dépendent pas
      // de la position des entités map dans le modèle actuel.
      warpCandidatesByPos: _warpCandidatesByPos,
      actionBehaviorByPos: _actionBehaviorByPos,
      enterBehaviorByPos: _enterBehaviorByPos,
      bumpBehaviorByPos: _bumpBehaviorByPos,
      exitBehaviorByPos: _exitBehaviorByPos,
      nearBehaviorByPos: _nearBehaviorByPos,
      placedElementCoverageByPos: _placedElementCoverageByPos,
      waterCellCache: _waterCellCache,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
      npcMapPresencePredicate: npcMapPresencePredicate,
      mapEntityPresencePredicate: mapEntityPresencePredicate,
    );
  }

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

bool _isSameBehaviorActivation(
  PlacedElementBehaviorActivation? a,
  PlacedElementBehaviorActivation? b,
) {
  if (a == null || b == null) {
    return false;
  }
  return a.element.id == b.element.id &&
      _resolveBehaviorIdentity(a.behavior) ==
          _resolveBehaviorIdentity(b.behavior);
}

String _resolveBehaviorIdentity(MapPlacedElementBehavior behavior) {
  final behaviorId = behavior.id.trim();
  if (behaviorId.isNotEmpty) {
    return behaviorId;
  }
  return '${behavior.trigger.name}:${behavior.effect.type.name}';
}

/// Collision statique issue des calques de collision et des propriétés de tileset.
List<bool> _buildTileCollisionCellCache(
  MapData map, {
  ProjectManifest? project,
  Set<String> ignoredTileLayerIds = const {},
}) {
  final size = map.size.width * map.size.height;
  final cache = List<bool>.filled(size, false);
  if (size <= 0) {
    return List<bool>.unmodifiable(cache);
  }
  final blockedTileIdsByTileset = <String, Set<int>>{};
  if (project != null) {
    for (final tileset in project.tilesets) {
      final source = tileset.source;
      if (source is ProjectRegularAtlasTilesetSource) {
        blockedTileIdsByTileset[tileset.id] = {
          for (final property in source.tileProperties)
            if (!property.passable) property.tileId,
        };
      }
    }
  }
  for (final layer in map.layers) {
    layer.whenOrNull(
      collision: (id, name, isVisible, opacity, collisions) {
        for (var i = 0; i < collisions.length && i < size; i++) {
          if (collisions[i]) {
            cache[i] = true;
          }
        }
      },
      tile: (id, name, isVisible, opacity, purpose, palette, cells) {
        if (!isVisible || purpose != MapLayerPurpose.visual || ignoredTileLayerIds.contains(id)) {
          return;
        }
        for (var i = 0; i < cells.length && i < size; i++) {
          final rawPaletteIndex = cells[i];
          if (rawPaletteIndex <= 0 || rawPaletteIndex > palette.length) {
            continue;
          }
          final entry = palette[rawPaletteIndex - 1];
          final blockedTileIds = blockedTileIdsByTileset[entry.tilesetId];
          if (blockedTileIds?.contains(entry.localTileId) ?? false) {
            cache[i] = true;
          }
        }
      },
    );
  }
  return List<bool>.unmodifiable(cache);
}

WorldCollisionStorage _buildStaticCollisionStorage(
  MapData map, {
  required ProjectManifest? project,
  required int tileWidth,
  required int tileHeight,
  required List<bool> tileCollisionCellCache,
  required List<bool> placedElementCellCollisionCache,
  MovingPlatformWorldState movingPlatformWorldState = const MovingPlatformWorldState.empty(),
}) {
  final safeTileWidth = tileWidth <= 0 ? 16 : tileWidth;
  final safeTileHeight = tileHeight <= 0 ? 16 : tileHeight;
  final terrainIds = {for (final platform in map.movingPlatforms) ...platform.terrainLayerIds};
  if (terrainIds.isNotEmpty) {
    if (project == null) throw const FormatException('Moving platforms require a project catalog.');
    validateMovingPlatformMapState(map: map, project: project, worldState: movingPlatformWorldState,
        tileSize: PixelSize(width: safeTileWidth, height: safeTileHeight));
  }
  final storage = WorldCollisionStorageBuilder(
    widthCells: map.size.width,
    heightCells: map.size.height,
    tileWidthPx: safeTileWidth,
    tileHeightPx: safeTileHeight,
    tileCollisionCells: terrainIds.isEmpty ? tileCollisionCellCache : _buildTileCollisionCellCache(
      map, project: project, ignoredTileLayerIds: terrainIds),
    supportableTerrainCellsByLayer: {for (final id in terrainIds) id: _buildTileCollisionCellCache(
      map.copyWith(layers: map.layers.where((layer) => layer.id == id).toList()), project: project)},
    supportRectsByLayer: {for (final id in terrainIds) id: movingPlatformSupportRects(
      map: map, worldState: movingPlatformWorldState, terrainLayerId: id,
      tileSize: PixelSize(width: safeTileWidth, height: safeTileHeight)).toList()},
    placedElementCollisionCells: placedElementCellCollisionCache,
  );

  final elementById = project == null
      ? const <String, ProjectElementEntry>{}
      : {
          for (final entry in project.elements) entry.id: entry,
        };
  for (final instance in map.placedElements) {
    if (!instance.applyCollision) {
      continue;
    }
    final element = elementById[instance.elementId];
    final profile = element?.collisionProfile;
    if (element == null ||
        profile == null ||
        (profile.collisionMask == null && !_hasPixelGeometry(instance))) {
      continue;
    }
    try {
      for (final rect in resolveMapPlacedElementCollisionRects(
          instance: instance,
          element: element,
          tileSize: PixelSize(width: safeTileWidth, height: safeTileHeight))) {
        storage.stampRect(rect);
      }
    } on FormatException {
      continue;
    } on ValidationException {
      continue;
    }
  }

  if (project == null &&
      map.spatialScene == null &&
      map.layers.whereType<BorderLayer>().any((layer) => layer.content.features.isNotEmpty)) {
    throw const ValidationException('Border collision requires a project catalog');
  }
  if (project != null) {
    for (final contact in resolveMaterializedBorderCollisions(
      map: map,
      project: project,
      tileSize: PixelSize(width: safeTileWidth, height: safeTileHeight),
    )) {
      storage.stampBorderRect(contact);
    }
  }
  return storage.build();
}

List<bool> _buildPlacedElementCellCollisionCache(
  MapData map, {
  required ProjectManifest? project,
}) {
  final size = map.size.width * map.size.height;
  final cache = List<bool>.filled(size, false);
  if (size <= 0 || project == null) {
    return List<bool>.unmodifiable(cache);
  }
  final elementById = <String, ProjectElementEntry>{
    for (final entry in project.elements) entry.id: entry,
  };
  for (final instance in map.placedElements) {
    if (!instance.applyCollision) {
      continue;
    }
    final element = elementById[instance.elementId];
    final profile = element?.collisionProfile;
    // An unresolved element has never contributed collision cells. Keep that
    // branch ahead of the strict footprint resolver for legacy map safety.
    if (element == null ||
        profile == null ||
        profile.collisionMask != null ||
        _hasPixelGeometry(instance)) {
      continue;
    }
    final footprint = resolveMapPlacedElementFootprint(
      instance: instance,
      element: element,
    );
    for (final cell in profile.cells) {
      final destination = footprint.sourceToDestination(cell);
      final x = instance.pos.x + destination.x;
      final y = instance.pos.y + destination.y;
      if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
        continue;
      }
      cache[y * map.size.width + x] = true;
    }
  }
  return List<bool>.unmodifiable(cache);
}

bool _hasPixelGeometry(MapPlacedElement instance) =>
    instance.pixelOffset.x != 0 ||
    instance.pixelOffset.y != 0 ||
    instance.pixelSize != null;

List<bool> _buildWaterCellCache(MapData map) {
  final size = map.size.width * map.size.height;
  final cache = List<bool>.filled(size, false);
  if (size <= 0 || map.size.width <= 0 || map.size.height <= 0) {
    return cache;
  }

  for (final zone in map.gameplayZones) {
    if (zone.kind != GameplayZoneKind.movement) {
      continue;
    }
    final movement = zone.movement;
    if (movement == null) {
      continue;
    }
    if (!_movementZoneRequiresSurf(movement)) {
      continue;
    }
    final left = zone.area.pos.x;
    final top = zone.area.pos.y;
    final right = left + zone.area.size.width;
    final bottom = top + zone.area.size.height;
    for (var y = top; y < bottom; y++) {
      if (y < 0 || y >= map.size.height) {
        continue;
      }
      for (var x = left; x < right; x++) {
        if (x < 0 || x >= map.size.width) {
          continue;
        }
        cache[y * map.size.width + x] = true;
      }
    }
  }

  return cache;
}

bool _movementZoneRequiresSurf(MovementZonePayload movement) {
  if (movement.requiredMode == MovementMode.surf) {
    return true;
  }
  return movement.allowedModes.contains(MovementMode.surf);
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

bool _includeMapEntityInSpatialCaches(
  MapData map,
  MapEntity entity,
  NpcMapPresencePredicate? npcPresence,
  MapEntityPresencePredicate? entityPresence,
) {
  if (entityPresence != null && !entityPresence(map.id, entity)) {
    return false;
  }
  if (entity.kind != MapEntityKind.npc || npcPresence == null) {
    return true;
  }
  return npcPresence(map.id, entity);
}

Map<int, List<MapEntity>> _buildBlockingEntityByPos(
  MapData map, {
  NpcMapPresencePredicate? npcPresence,
  MapEntityPresencePredicate? entityPresence,
}) {
  final w = map.size.width;
  final result = <int, List<MapEntity>>{};
  for (final entity in map.entities) {
    if (!_includeMapEntityInSpatialCaches(
      map,
      entity,
      npcPresence,
      entityPresence,
    )) {
      continue;
    }
    if (!_isEntityBlockingCandidate(entity)) continue;
    for (final cell in resolveEntityCollisionCells(entity)) {
      if (cell.x < 0 ||
          cell.y < 0 ||
          cell.x >= map.size.width ||
          cell.y >= map.size.height) {
        continue;
      }
      (result[cell.y * w + cell.x] ??= []).add(entity);
    }
  }
  return Map.unmodifiable({
    for (final entry in result.entries)
      entry.key: List<MapEntity>.unmodifiable(entry.value),
  });
}

Map<int, MapEntity> _buildEntityByPos(
  MapData map, {
  NpcMapPresencePredicate? npcPresence,
  MapEntityPresencePredicate? entityPresence,
}) {
  final w = map.size.width;
  final result = <int, MapEntity>{};
  for (final entity in map.entities) {
    if (!_includeMapEntityInSpatialCaches(
      map,
      entity,
      npcPresence,
      entityPresence,
    )) {
      continue;
    }
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

/// Construit un cache de behavior par cellule pour un trigger donné.
///
/// **Politique de résolution « single winner »** :
/// Quand plusieurs behaviors sont valides sur la même cellule, un seul gagne.
/// Le winner est déterminé par l'ordre de parcours :
/// 1. ordre des instances dans `map.placedElements` (première instance gagne)
/// 2. ordre des behaviors dans `instance.behaviors` (premier behavior gagne)
///
/// Cette politique est déterministe car l'ordre de `map.placedElements` est stable.
/// Utilise `putIfAbsent` pour garantir que le premier behavior valide pour une cellule
/// est conservé.
///
/// Pour les triggers de mouvement (`onEnter`, `onExit`, `onNear`), une priorité
/// supplémentaire s'applique : `onEnter` > `onExit` > `onNear` (voir `_movementTriggerPriority`).
Map<int, PlacedElementBehaviorActivation> _buildPlacedElementBehaviorByPos(
  MapData map, {
  required ProjectManifest? project,
  required PixelSize tileSize,
  required MapPlacedElementTriggerType trigger,
}) {
  final w = map.size.width;
  final h = map.size.height;
  final result = <int, PlacedElementBehaviorActivation>{};
  final elementById = project == null
      ? const <String, ProjectElementEntry>{}
      : {
          for (final entry in project.elements) entry.id: entry,
        };
  for (final instance in map.placedElements) {
    final behaviors = instance.behaviors;
    if (behaviors.isEmpty) {
      continue;
    }
    final footprint =
        _resolvePlacedElementCellBounds(instance, elementById, tileSize);
    final width = footprint.size.width;
    final height = footprint.size.height;
    for (final behavior in behaviors) {
      if (!behavior.enabled) {
        continue;
      }
      if (behavior.trigger != trigger) {
        continue;
      }
      for (var localY = 0; localY < height; localY++) {
        for (var localX = 0; localX < width; localX++) {
          final x = footprint.pos.x + localX;
          final y = footprint.pos.y + localY;
          if (x < 0 || y < 0 || x >= w || y >= h) {
            continue;
          }
          final index = y * w + x;
          result.putIfAbsent(
            index,
            () => PlacedElementBehaviorActivation(
              element: instance,
              behavior: behavior,
            ),
          );
        }
      }
    }
  }
  return result;
}

Map<int, PlacedElementBehaviorActivation> _buildPlacedElementNearBehaviorByPos(
  MapData map, {
  required ProjectManifest? project,
  required PixelSize tileSize,
}) {
  final w = map.size.width;
  final h = map.size.height;
  final result = <int, PlacedElementBehaviorActivation>{};
  final elementById = project == null
      ? const <String, ProjectElementEntry>{}
      : {
          for (final entry in project.elements) entry.id: entry,
        };
  for (final instance in map.placedElements) {
    final behaviors = instance.behaviors;
    if (behaviors.isEmpty) {
      continue;
    }
    final footprint =
        _resolvePlacedElementCellBounds(instance, elementById, tileSize);
    final width = footprint.size.width;
    final height = footprint.size.height;
    final minX = footprint.pos.x;
    final minY = footprint.pos.y;
    final maxX = minX + width - 1;
    final maxY = minY + height - 1;
    for (final behavior in behaviors) {
      if (!behavior.enabled) {
        continue;
      }
      if (behavior.trigger != MapPlacedElementTriggerType.onNear) {
        continue;
      }
      for (var localY = 0; localY < height; localY++) {
        for (var localX = 0; localX < width; localX++) {
          final x = minX + localX;
          final y = minY + localY;
          final neighbors = <(int, int)>[
            (x - 1, y),
            (x + 1, y),
            (x, y - 1),
            (x, y + 1),
          ];
          for (final (nx, ny) in neighbors) {
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) {
              continue;
            }
            final insideFootprint =
                nx >= minX && nx <= maxX && ny >= minY && ny <= maxY;
            if (insideFootprint) {
              continue;
            }
            final index = ny * w + nx;
            result.putIfAbsent(
              index,
              () => PlacedElementBehaviorActivation(
                element: instance,
                behavior: behavior,
              ),
            );
          }
        }
      }
    }
  }
  return result;
}

Map<int, Set<String>> _buildPlacedElementCoverageByPos(
  MapData map, {
  required ProjectManifest? project,
  required PixelSize tileSize,
}) {
  final w = map.size.width;
  final h = map.size.height;
  final result = <int, Set<String>>{};
  final elementById = project == null
      ? const <String, ProjectElementEntry>{}
      : {
          for (final entry in project.elements) entry.id: entry,
        };
  for (final instance in map.placedElements) {
    final footprint =
        _resolvePlacedElementCellBounds(instance, elementById, tileSize);
    final width = footprint.size.width;
    final height = footprint.size.height;
    final startLocalX = footprint.pos.x < 0 ? -footprint.pos.x : 0;
    final startLocalY = footprint.pos.y < 0 ? -footprint.pos.y : 0;
    final visibleWidth = w - footprint.pos.x;
    final visibleHeight = h - footprint.pos.y;
    final endLocalX = width < visibleWidth ? width : visibleWidth;
    final endLocalY = height < visibleHeight ? height : visibleHeight;
    for (var localY = startLocalY; localY < endLocalY; localY++) {
      for (var localX = startLocalX; localX < endLocalX; localX++) {
        final x = footprint.pos.x + localX;
        final y = footprint.pos.y + localY;
        final index = y * w + x;
        result.putIfAbsent(index, () => <String>{}).add(instance.id);
      }
    }
  }
  return result;
}

MapRect _resolvePlacedElementCellBounds(
  MapPlacedElement instance,
  Map<String, ProjectElementEntry> elementById,
  PixelSize tileSize,
) {
  final element = elementById[instance.elementId];
  // Gameplay historically treats unresolved placed elements as one cell.
  // Preserve that branch before the strict shared transform so project-less
  // worlds cannot fail merely because quarterTurns contains unvalidated data.
  if (element == null) {
    return MapRect(
        pos: instance.pos, size: const GridSize(width: 1, height: 1));
  }
  if (!_hasPixelGeometry(instance)) {
    return MapRect(
        pos: instance.pos,
        size: resolveMapPlacedElementFootprint(
                instance: instance, element: element)
            .destinationSize);
  }
  return resolveMapPlacedElementGeometry(
          instance: instance, element: element, tileSize: tileSize)
      .cellBounds;
}

bool _isEntityBlockingCandidate(MapEntity entity) {
  if (!entity.blocksMovement) return false;
  if (entity.kind == MapEntityKind.spawn) return false;
  if (entity.fieldObstacle != null) return true;
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

class PlacedElementBehaviorActivation {
  const PlacedElementBehaviorActivation({
    required this.element,
    required this.behavior,
  });

  final MapPlacedElement element;
  final MapPlacedElementBehavior behavior;
}

/// Internal diagnostics imported explicitly by scaling tests and benchmarks.
///
/// The public map_gameplay.dart barrel exports only [GameplayWorldState] and
/// its predicates from this library, so these probes do not become gameplay
/// API for runtime consumers.
extension GameplayWorldStateCollisionStorageDiagnostics on GameplayWorldState {
  Object get debugStaticCollisionStorageToken => _staticCollisionStorage;
  int get debugAllocatedPixelMaskChunkCount =>
      _staticCollisionStorage.allocatedPixelMaskChunkCount;
  int get debugAllocatedPixelMaskWordCount =>
      _staticCollisionStorage.allocatedPixelMaskWordCount;
}

List<BorderDirectedJumpBinding> _bindBorderJumps(
  MapData map,
  ProjectManifest? project,
  int tileWidth,
  int tileHeight,
) {
  final features = map.layers.whereType<BorderLayer>()
      .expand((layer) => layer.content.features).toList(growable: false);
  if (features.isEmpty) return const [];
  if (project == null) {
    throw const ValidationException('Border world requires a project context');
  }
  var hasJump = false;
  for (final feature in features) {
    final revision = project.borderCatalog
        .recordById(feature.blueprintId)?.latestPublished;
    if (revision == null) {
      throw const ValidationException('Border world requires a published blueprint');
    }
    hasJump |= revision.definition.jumpBehavior != null;
  }
  if (!hasJump) return const [];
  return bindMaterializedBorderJumpFaces(
    map: map,
    project: project,
    tileSize: PixelSize(
      width: tileWidth <= 0 ? 16 : tileWidth,
      height: tileHeight <= 0 ? 16 : tileHeight,
    ),
  );
}

MapData _captureBorderJumpMap(MapData map, ProjectManifest? project) {
  if (project == null) return map;
  final hasJump = map.layers.whereType<BorderLayer>()
      .expand((layer) => layer.content.features)
      .any((feature) => project.borderCatalog
        .recordById(feature.blueprintId)?.latestPublished
        ?.definition.jumpBehavior != null);
  return hasJump
      ? MapData.fromJson(jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>)
      : map;
}
