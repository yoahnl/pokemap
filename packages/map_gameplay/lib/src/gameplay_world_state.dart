import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_exceptions.dart';
import 'movement_block_reason.dart';
import 'gameplay_player_state.dart';
import 'player_spawn_resolver.dart';

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

class GameplayWorldState {
  GameplayWorldState._({
    required this.map,
    required this.player,
    required List<bool> tileCollisionCellCache,
    required List<bool> pixelCollisionCache,
    required Map<int, MapEntity> blockingEntityByPos,
    required Map<int, List<MapWarp>> warpCandidatesByPos,
    required Map<int, MapEntity> entityByPos,
    required Map<int, PlacedElementBehaviorActivation> actionBehaviorByPos,
    required Map<int, PlacedElementBehaviorActivation> enterBehaviorByPos,
    required Map<int, PlacedElementBehaviorActivation> bumpBehaviorByPos,
    required Map<int, PlacedElementBehaviorActivation> exitBehaviorByPos,
    required Map<int, PlacedElementBehaviorActivation> nearBehaviorByPos,
    required Map<int, Set<String>> placedElementCoverageByPos,
    required Map<int, PathAnimationRuleActivation> pathRuleOnEnterByPos,
    required Map<int, PathAnimationRuleActivation> pathRuleOnStepByPos,
    required Map<int, PathAnimationRuleActivation> pathRuleOnActionByPos,
    required Map<int, PathAnimationRuleActivation> pathRuleOnBumpByPos,
    required Map<int, PathAnimationRuleActivation> pathRuleOnNearByPos,
    required Map<int, PathAnimationRuleActivation> pathRuleWhileInsideByPos,
    required List<bool> waterCellCache,
    required int tileWidth,
    required int tileHeight,
    this.npcMapPresencePredicate,
    required ProjectManifest? projectManifest,
  })  : _tileCollisionCellCache = tileCollisionCellCache,
        _pixelCollisionCache = pixelCollisionCache,
        _blockingEntityByPos = blockingEntityByPos,
        _projectManifest = projectManifest,
        _warpCandidatesByPos = warpCandidatesByPos,
        _entityByPos = entityByPos,
        _actionBehaviorByPos = actionBehaviorByPos,
        _enterBehaviorByPos = enterBehaviorByPos,
        _bumpBehaviorByPos = bumpBehaviorByPos,
        _exitBehaviorByPos = exitBehaviorByPos,
        _nearBehaviorByPos = nearBehaviorByPos,
        _placedElementCoverageByPos = placedElementCoverageByPos,
        _pathRuleOnEnterByPos = pathRuleOnEnterByPos,
        _pathRuleOnStepByPos = pathRuleOnStepByPos,
        _pathRuleOnActionByPos = pathRuleOnActionByPos,
        _pathRuleOnBumpByPos = pathRuleOnBumpByPos,
        _pathRuleOnNearByPos = pathRuleOnNearByPos,
        _pathRuleWhileInsideByPos = pathRuleWhileInsideByPos,
        _waterCellCache = waterCellCache,
        _tileWidth = tileWidth <= 0 ? 16 : tileWidth,
        _tileHeight = tileHeight <= 0 ? 16 : tileHeight;

  factory GameplayWorldState.initial({
    required MapData map,
    required GridPos playerPos,
    Direction playerFacing = Direction.south,
    MovementMode playerMovementMode = MovementMode.walk,
    ProjectManifest? project,
    int tileWidth = 16,
    int tileHeight = 16,
    NpcMapPresencePredicate? npcMapPresencePredicate,
  }) {
    final blockingEntities = _buildBlockingEntityByPos(
      map,
      npcPresence: npcMapPresencePredicate,
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
        tileCollisionCellCache: _buildTileCollisionCellCache(map),
        blockingEntityByPos: blockingEntities,
        pixelCollisionCache: _buildPixelCollisionCache(
          map,
          project: project,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          blockingEntityByPos: blockingEntities,
        ),
        warpCandidatesByPos:
            _buildWarpCandidatesByPos(map, tileWidth, tileHeight),
        entityByPos: _buildEntityByPos(
          map,
          npcPresence: npcMapPresencePredicate,
        ),
        actionBehaviorByPos: _buildPlacedElementBehaviorByPos(
          map,
          project: project,
          trigger: MapPlacedElementTriggerType.onAction,
        ),
        enterBehaviorByPos: _buildPlacedElementBehaviorByPos(
          map,
          project: project,
          trigger: MapPlacedElementTriggerType.onEnter,
        ),
        bumpBehaviorByPos: _buildPlacedElementBehaviorByPos(
          map,
          project: project,
          trigger: MapPlacedElementTriggerType.onBump,
        ),
        exitBehaviorByPos: _buildPlacedElementBehaviorByPos(
          map,
          project: project,
          trigger: MapPlacedElementTriggerType.onExit,
        ),
        nearBehaviorByPos: _buildPlacedElementNearBehaviorByPos(
          map,
          project: project,
        ),
        placedElementCoverageByPos: _buildPlacedElementCoverageByPos(
          map,
          project: project,
        ),
        pathRuleOnEnterByPos: _buildPathAnimationRuleByPos(
          map,
          trigger: PathAnimationTriggerType.onEnter,
        ),
        pathRuleOnStepByPos: _buildPathAnimationRuleByPos(
          map,
          trigger: PathAnimationTriggerType.onStep,
        ),
        pathRuleOnActionByPos: _buildPathAnimationRuleByPos(
          map,
          trigger: PathAnimationTriggerType.onAction,
        ),
        pathRuleOnBumpByPos: _buildPathAnimationRuleByPos(
          map,
          trigger: PathAnimationTriggerType.onBump,
        ),
        pathRuleOnNearByPos: _buildPathAnimationNearRuleByPos(
          map,
        ),
        pathRuleWhileInsideByPos: _buildPathAnimationRuleByPos(
          map,
          trigger: PathAnimationTriggerType.whileInside,
        ),
        waterCellCache: _buildWaterCellCache(map, project: project),
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        npcMapPresencePredicate: npcMapPresencePredicate,
        projectManifest: project,
      );
  }

  factory GameplayWorldState.fromMap(
    MapData map, {
    ProjectManifest? project,
    int tileWidth = 16,
    int tileHeight = 16,
    NpcMapPresencePredicate? npcMapPresencePredicate,
  }) {
    final player = resolveInitialPlayerSpawn(
      map,
      tileWidthPx: tileWidth,
      tileHeightPx: tileHeight,
    );
    final cache = _buildTileCollisionCellCache(map);
    final blockingEntities = _buildBlockingEntityByPos(
      map,
      npcPresence: npcMapPresencePredicate,
    );
    final pixelCache = _buildPixelCollisionCache(
      map,
      project: project,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      blockingEntityByPos: blockingEntities,
    );
    final warps = _buildWarpCandidatesByPos(map, tileWidth, tileHeight);
    final entities = _buildEntityByPos(
      map,
      npcPresence: npcMapPresencePredicate,
    );
    final world = GameplayWorldState._(
      map: map,
      player: player,
      tileCollisionCellCache: cache,
      pixelCollisionCache: pixelCache,
      blockingEntityByPos: blockingEntities,
      warpCandidatesByPos: warps,
      entityByPos: entities,
      actionBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        trigger: MapPlacedElementTriggerType.onAction,
      ),
      enterBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        trigger: MapPlacedElementTriggerType.onEnter,
      ),
      bumpBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        trigger: MapPlacedElementTriggerType.onBump,
      ),
      exitBehaviorByPos: _buildPlacedElementBehaviorByPos(
        map,
        project: project,
        trigger: MapPlacedElementTriggerType.onExit,
      ),
      nearBehaviorByPos: _buildPlacedElementNearBehaviorByPos(
        map,
        project: project,
      ),
      placedElementCoverageByPos: _buildPlacedElementCoverageByPos(
        map,
        project: project,
      ),
      pathRuleOnEnterByPos: _buildPathAnimationRuleByPos(
        map,
        trigger: PathAnimationTriggerType.onEnter,
      ),
      pathRuleOnStepByPos: _buildPathAnimationRuleByPos(
        map,
        trigger: PathAnimationTriggerType.onStep,
      ),
      pathRuleOnActionByPos: _buildPathAnimationRuleByPos(
        map,
        trigger: PathAnimationTriggerType.onAction,
      ),
      pathRuleOnBumpByPos: _buildPathAnimationRuleByPos(
        map,
        trigger: PathAnimationTriggerType.onBump,
      ),
      pathRuleOnNearByPos: _buildPathAnimationNearRuleByPos(
        map,
      ),
      pathRuleWhileInsideByPos: _buildPathAnimationRuleByPos(
        map,
        trigger: PathAnimationTriggerType.whileInside,
      ),
      waterCellCache: _buildWaterCellCache(map, project: project),
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      npcMapPresencePredicate: npcMapPresencePredicate,
      projectManifest: project,
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

  /// Filtre optionnel de présence des PNJ sur la grille (voir [NpcMapPresencePredicate]).
  final NpcMapPresencePredicate? npcMapPresencePredicate;
  /// Calque collision **tuiles** uniquement (grille auteur). Pas les éléments placés.
  final List<bool> _tileCollisionCellCache;
  final List<bool> _pixelCollisionCache;
  final Map<int, MapEntity> _blockingEntityByPos;
  final Map<int, List<MapWarp>> _warpCandidatesByPos;
  final Map<int, MapEntity> _entityByPos;
  final Map<int, PlacedElementBehaviorActivation> _actionBehaviorByPos;
  final Map<int, PlacedElementBehaviorActivation> _enterBehaviorByPos;
  final Map<int, PlacedElementBehaviorActivation> _bumpBehaviorByPos;
  final Map<int, PlacedElementBehaviorActivation> _exitBehaviorByPos;
  final Map<int, PlacedElementBehaviorActivation> _nearBehaviorByPos;
  final Map<int, Set<String>> _placedElementCoverageByPos;
  final Map<int, PathAnimationRuleActivation> _pathRuleOnEnterByPos;
  final Map<int, PathAnimationRuleActivation> _pathRuleOnStepByPos;
  final Map<int, PathAnimationRuleActivation> _pathRuleOnActionByPos;
  final Map<int, PathAnimationRuleActivation> _pathRuleOnBumpByPos;
  final Map<int, PathAnimationRuleActivation> _pathRuleOnNearByPos;
  final Map<int, PathAnimationRuleActivation> _pathRuleWhileInsideByPos;
  final List<bool> _waterCellCache;
  final int _tileWidth;
  final int _tileHeight;

  /// Manifeste projet conservé pour **reconstruire** [_pixelCollisionCache] quand
  /// [blockingEntityByPos] change (PNJ déplacé, prédicat de présence, etc.).
  /// Peut être `null` : dans ce cas un rebuild ne peut pas ré-appliquer les
  /// `pixelMask` d’éléments placés (même comportement qu’à la construction).
  final ProjectManifest? _projectManifest;

  /// Taille tuile projet (pixels) — nécessaire pour projection pieds / rendu.
  int get tileWidthPx => _tileWidth;
  int get tileHeightPx => _tileHeight;

  /// Collision **déplacement** : hitbox joueur vs bitmap statique monde.
  bool worldStaticObstaclesCollidePlayerCollisionRect() {
    return worldStaticObstaclesCollidePixelRect(player.playerCollisionRectPx);
  }

  /// Test pixel-level contre l’union des obstacles statiques (bitmap monde).
  bool worldStaticObstaclesCollidePixelRect(PixelRect rect) {
    final widthPx = map.size.width * _tileWidth;
    final heightPx = map.size.height * _tileHeight;
    for (var py = 0; py < rect.heightPx; py++) {
      final y = rect.topPx + py;
      for (var px = 0; px < rect.widthPx; px++) {
        final x = rect.leftPx + px;
        if (x < 0 || y < 0 || x >= widthPx || y >= heightPx) {
          return true;
        }
        final idx = y * widthPx + x;
        if (idx < 0 || idx >= _pixelCollisionCache.length) {
          continue;
        }
        if (_pixelCollisionCache[idx]) {
          return true;
        }
      }
    }
    return false;
  }

  /// PNJ scripté / pathfinding : centre de case → bitmap (pas une primitive joueur).
  bool isCellCenterBlockedLegacyForGridIndexedSystems(int cellX, int cellY) {
    if (cellX < 0 ||
        cellY < 0 ||
        cellX >= map.size.width ||
        cellY >= map.size.height) {
      return true;
    }
    final cx = cellX * _tileWidth + _tileWidth ~/ 2;
    final cy = cellY * _tileHeight + _tileHeight ~/ 2;
    final widthPx = map.size.width * _tileWidth;
    final heightPx = map.size.height * _tileHeight;
    if (cx < 0 || cy < 0 || cx >= widthPx || cy >= heightPx) {
      return true;
    }
    final idx = cy * widthPx + cx;
    if (idx < 0 || idx >= _pixelCollisionCache.length) {
      return false;
    }
    return _pixelCollisionCache[idx];
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

  PathAnimationRuleActivation? pathAnimationRuleOnEnterAt(
    int x,
    int y,
  ) =>
      _pathRuleOnEnterByPos[y * map.size.width + x];

  PathAnimationRuleActivation? pathAnimationRuleOnStepAt(
    int x,
    int y,
  ) =>
      _pathRuleOnStepByPos[y * map.size.width + x];

  PathAnimationRuleActivation? pathAnimationRuleOnActionAt(
    int x,
    int y,
  ) =>
      _pathRuleOnActionByPos[y * map.size.width + x];

  PathAnimationRuleActivation? pathAnimationRuleOnBumpAt(
    int x,
    int y,
  ) =>
      _pathRuleOnBumpByPos[y * map.size.width + x];

  PathAnimationRuleActivation? pathAnimationRuleOnNearAt(
    int x,
    int y,
  ) =>
      _pathRuleOnNearByPos[y * map.size.width + x];

  PathAnimationRuleActivation? pathAnimationRuleWhileInsideAt(
    int x,
    int y,
  ) =>
      _pathRuleWhileInsideByPos[y * map.size.width + x];

  PathAnimationRuleActivation? pathAnimationRuleOnNearTransition({
    required GridPos from,
    required GridPos to,
  }) {
    final toActivation = pathAnimationRuleOnNearAt(to.x, to.y);
    if (toActivation == null) {
      return null;
    }
    final fromActivation = pathAnimationRuleOnNearAt(from.x, from.y);
    if (_isSamePathAnimationRuleActivation(fromActivation, toActivation)) {
      return null;
    }
    return toActivation;
  }

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
        pixelCollisionCache: _pixelCollisionCache,
        blockingEntityByPos: _blockingEntityByPos,
        warpCandidatesByPos: _warpCandidatesByPos,
        entityByPos: _entityByPos,
        actionBehaviorByPos: _actionBehaviorByPos,
        enterBehaviorByPos: _enterBehaviorByPos,
        bumpBehaviorByPos: _bumpBehaviorByPos,
        exitBehaviorByPos: _exitBehaviorByPos,
        nearBehaviorByPos: _nearBehaviorByPos,
        placedElementCoverageByPos: _placedElementCoverageByPos,
        pathRuleOnEnterByPos: _pathRuleOnEnterByPos,
        pathRuleOnStepByPos: _pathRuleOnStepByPos,
        pathRuleOnActionByPos: _pathRuleOnActionByPos,
        pathRuleOnBumpByPos: _pathRuleOnBumpByPos,
        pathRuleOnNearByPos: _pathRuleOnNearByPos,
        pathRuleWhileInsideByPos: _pathRuleWhileInsideByPos,
        waterCellCache: _waterCellCache,
        tileWidth: _tileWidth,
        tileHeight: _tileHeight,
        npcMapPresencePredicate: npcMapPresencePredicate,
        projectManifest: _projectManifest,
      );

  /// Reconstruit les caches spatiaux PNJ après changement de progression (visibilité).
  GameplayWorldState withNpcMapPresencePredicate(
    NpcMapPresencePredicate? predicate,
  ) {
    final newBlocking = _buildBlockingEntityByPos(
      map,
      npcPresence: predicate,
    );
    return GameplayWorldState._(
      map: map,
      player: player,
      tileCollisionCellCache: _tileCollisionCellCache,
      pixelCollisionCache: _buildPixelCollisionCache(
        map,
        project: _projectManifest,
        tileWidth: _tileWidth,
        tileHeight: _tileHeight,
        blockingEntityByPos: newBlocking,
      ),
      blockingEntityByPos: newBlocking,
      entityByPos: _buildEntityByPos(map, npcPresence: predicate),
      warpCandidatesByPos: _warpCandidatesByPos,
      actionBehaviorByPos: _actionBehaviorByPos,
      enterBehaviorByPos: _enterBehaviorByPos,
      bumpBehaviorByPos: _bumpBehaviorByPos,
      exitBehaviorByPos: _exitBehaviorByPos,
      nearBehaviorByPos: _nearBehaviorByPos,
      placedElementCoverageByPos: _placedElementCoverageByPos,
      pathRuleOnEnterByPos: _pathRuleOnEnterByPos,
      pathRuleOnStepByPos: _pathRuleOnStepByPos,
      pathRuleOnActionByPos: _pathRuleOnActionByPos,
      pathRuleOnBumpByPos: _pathRuleOnBumpByPos,
      pathRuleOnNearByPos: _pathRuleOnNearByPos,
      pathRuleWhileInsideByPos: _pathRuleWhileInsideByPos,
      waterCellCache: _waterCellCache,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
      npcMapPresencePredicate: predicate,
      projectManifest: _projectManifest,
    );
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
  /// - on ne modifie pas les layers auteur ; en revanche [_pixelCollisionCache]
  ///   est **reconstruit** pour refléter le nouveau [blockingEntityByPos].
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

    final updatedEntities = List<MapEntity>.from(map.entities);
    updatedEntities[index] = entity.copyWith(pos: newPos);
    final updatedMap = map.copyWith(entities: updatedEntities);

    final newBlocking = _buildBlockingEntityByPos(
      updatedMap,
      npcPresence: npcMapPresencePredicate,
    );
    return GameplayWorldState._(
      map: updatedMap,
      player: player,
      tileCollisionCellCache: _tileCollisionCellCache,
      pixelCollisionCache: _buildPixelCollisionCache(
        updatedMap,
        project: _projectManifest,
        tileWidth: _tileWidth,
        tileHeight: _tileHeight,
        blockingEntityByPos: newBlocking,
      ),
      // Les entités bloquantes et interactives doivent refléter la nouvelle map.
      blockingEntityByPos: newBlocking,
      entityByPos: _buildEntityByPos(
        updatedMap,
        npcPresence: npcMapPresencePredicate,
      ),
      // Les warps/behaviors/path rules restent valides: ils ne dépendent pas
      // de la position des entités map dans le modèle actuel.
      warpCandidatesByPos: _warpCandidatesByPos,
      actionBehaviorByPos: _actionBehaviorByPos,
      enterBehaviorByPos: _enterBehaviorByPos,
      bumpBehaviorByPos: _bumpBehaviorByPos,
      exitBehaviorByPos: _exitBehaviorByPos,
      nearBehaviorByPos: _nearBehaviorByPos,
      placedElementCoverageByPos: _placedElementCoverageByPos,
      pathRuleOnEnterByPos: _pathRuleOnEnterByPos,
      pathRuleOnStepByPos: _pathRuleOnStepByPos,
      pathRuleOnActionByPos: _pathRuleOnActionByPos,
      pathRuleOnBumpByPos: _pathRuleOnBumpByPos,
      pathRuleOnNearByPos: _pathRuleOnNearByPos,
      pathRuleWhileInsideByPos: _pathRuleWhileInsideByPos,
      waterCellCache: _waterCellCache,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
      npcMapPresencePredicate: npcMapPresencePredicate,
      projectManifest: _projectManifest,
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

bool _isSamePathAnimationRuleActivation(
  PathAnimationRuleActivation? a,
  PathAnimationRuleActivation? b,
) {
  if (a == null || b == null) {
    return false;
  }
  return a.layerId == b.layerId && a.ruleId == b.ruleId;
}

/// Calque collision **éditeur** uniquement (bool par cellule carte).
List<bool> _buildTileCollisionCellCache(MapData map) {
  final size = map.size.width * map.size.height;
  final cache = List<bool>.filled(size, false);
  for (final layer in map.layers) {
    layer.whenOrNull(
      collision: (id, name, isVisible, opacity, collisions) {
        for (var i = 0; i < collisions.length && i < size; i++) {
          if (collisions[i]) {
            cache[i] = true;
          }
        }
      },
    );
  }
  return cache;
}

List<bool> _buildPixelCollisionCache(
  MapData map, {
  required ProjectManifest? project,
  required int tileWidth,
  required int tileHeight,
  required Map<int, MapEntity> blockingEntityByPos,
}) {
  final safeTileWidth = tileWidth <= 0 ? 16 : tileWidth;
  final safeTileHeight = tileHeight <= 0 ? 16 : tileHeight;
  final widthPx = map.size.width * safeTileWidth;
  final heightPx = map.size.height * safeTileHeight;
  final cache = List<bool>.filled(widthPx * heightPx, false);
  if (widthPx <= 0 || heightPx <= 0) {
    return cache;
  }

  void stampSolidRect({
    required int leftPx,
    required int topPx,
    required int rectWidthPx,
    required int rectHeightPx,
  }) {
    for (var py = 0; py < rectHeightPx; py++) {
      final y = topPx + py;
      if (y < 0 || y >= heightPx) {
        continue;
      }
      for (var px = 0; px < rectWidthPx; px++) {
        final x = leftPx + px;
        if (x < 0 || x >= widthPx) {
          continue;
        }
        cache[y * widthPx + x] = true;
      }
    }
  }

  bool stampPackedMask({
    required int leftPx,
    required int topPx,
    required ElementCollisionPixelMask mask,
  }) {
    List<bool> decoded;
    try {
      decoded = ElementCollisionMaskCodec.decodePackedBits(
        widthPx: mask.widthPx,
        heightPx: mask.heightPx,
        dataBase64: mask.dataBase64,
      );
    } catch (_) {
      return false;
    }
    for (var py = 0; py < mask.heightPx; py++) {
      final y = topPx + py;
      if (y < 0 || y >= heightPx) {
        continue;
      }
      for (var px = 0; px < mask.widthPx; px++) {
        final x = leftPx + px;
        if (x < 0 || x >= widthPx) {
          continue;
        }
        final idx = py * mask.widthPx + px;
        if (idx < 0 || idx >= decoded.length || !decoded[idx]) {
          continue;
        }
        cache[y * widthPx + x] = true;
      }
    }
    return true;
  }

  // 1) Calque collision carte: toute cellule true => tile plein.
  for (final layer in map.layers) {
    layer.whenOrNull(
      collision: (id, name, isVisible, opacity, collisions) {
        for (var i = 0; i < collisions.length; i++) {
          if (!collisions[i]) {
            continue;
          }
          final x = i % map.size.width;
          final y = i ~/ map.size.width;
          if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
            continue;
          }
          stampSolidRect(
            leftPx: x * safeTileWidth,
            topPx: y * safeTileHeight,
            rectWidthPx: safeTileWidth,
            rectHeightPx: safeTileHeight,
          );
        }
      },
    );
  }

  // 2) Éléments placés : **uniquement** [ElementCollisionPixelMask] (pas `cells`).
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
    // Masque **collision** uniquement (JSON historique : `pixelMask`).
    final mask = profile?.collisionMask;
    if (mask == null) {
      continue;
    }
    final worldLeftPx = instance.pos.x * safeTileWidth;
    final worldTopPx = instance.pos.y * safeTileHeight;
    stampPackedMask(
      leftPx: worldLeftPx,
      topPx: worldTopPx,
      mask: mask,
    );
  }

  // 3) Entités bloquantes (PNJ / objets) : tuile pleine par cellule footprint.
  final w = map.size.width;
  for (final entry in blockingEntityByPos.entries) {
    final e = entry.value;
    if (!e.blocksMovement) {
      continue;
    }
    final idx = entry.key;
    final cx = idx % w;
    final cy = idx ~/ w;
    stampSolidRect(
      leftPx: cx * safeTileWidth,
      topPx: cy * safeTileHeight,
      rectWidthPx: safeTileWidth,
      rectHeightPx: safeTileHeight,
    );
  }

  return cache;
}

List<bool> _buildWaterCellCache(
  MapData map, {
  required ProjectManifest? project,
}) {
  final size = map.size.width * map.size.height;
  final cache = List<bool>.filled(size, false);
  if (size <= 0 || map.size.width <= 0 || map.size.height <= 0) {
    return cache;
  }

  final pathPresetById = project == null
      ? const <String, ProjectPathPreset>{}
      : {
          for (final preset in project.pathPresets) preset.id: preset,
        };

  for (final layer in map.layers.whereType<PathLayer>()) {
    final presetId = layer.presetId.trim();
    if (presetId.isEmpty) {
      continue;
    }
    final preset = pathPresetById[presetId];
    if (preset == null || preset.surfaceKind != PathSurfaceKind.water) {
      continue;
    }
    for (var i = 0; i < layer.cells.length && i < size; i++) {
      if (layer.cells[i]) {
        cache[i] = true;
      }
    }
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
) {
  if (entity.kind != MapEntityKind.npc) return true;
  if (npcPresence == null) return true;
  return npcPresence(map.id, entity);
}

Map<int, MapEntity> _buildBlockingEntityByPos(
  MapData map, {
  NpcMapPresencePredicate? npcPresence,
}) {
  final w = map.size.width;
  final result = <int, MapEntity>{};
  for (final entity in map.entities) {
    if (!_includeMapEntityInSpatialCaches(map, entity, npcPresence)) continue;
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

Map<int, MapEntity> _buildEntityByPos(
  MapData map, {
  NpcMapPresencePredicate? npcPresence,
}) {
  final w = map.size.width;
  final result = <int, MapEntity>{};
  for (final entity in map.entities) {
    if (!_includeMapEntityInSpatialCaches(map, entity, npcPresence)) continue;
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
    final footprint = _resolvePlacedElementFootprintSize(instance, elementById);
    final width = footprint.width;
    final height = footprint.height;
    for (final behavior in behaviors) {
      if (!behavior.enabled) {
        continue;
      }
      if (behavior.trigger != trigger) {
        continue;
      }
      for (var localY = 0; localY < height; localY++) {
        for (var localX = 0; localX < width; localX++) {
          final x = instance.pos.x + localX;
          final y = instance.pos.y + localY;
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
    final footprint = _resolvePlacedElementFootprintSize(instance, elementById);
    final width = footprint.width;
    final height = footprint.height;
    final minX = instance.pos.x;
    final minY = instance.pos.y;
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
          final x = instance.pos.x + localX;
          final y = instance.pos.y + localY;
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
    final footprint = _resolvePlacedElementFootprintSize(instance, elementById);
    final width = footprint.width;
    final height = footprint.height;
    for (var localY = 0; localY < height; localY++) {
      for (var localX = 0; localX < width; localX++) {
        final x = instance.pos.x + localX;
        final y = instance.pos.y + localY;
        if (x < 0 || y < 0 || x >= w || y >= h) {
          continue;
        }
        final index = y * w + x;
        result.putIfAbsent(index, () => <String>{}).add(instance.id);
      }
    }
  }
  return result;
}

Map<int, PathAnimationRuleActivation> _buildPathAnimationRuleByPos(
  MapData map, {
  required PathAnimationTriggerType trigger,
}) {
  final size = map.size.width * map.size.height;
  if (size <= 0 || map.size.width <= 0 || map.size.height <= 0) {
    return const <int, PathAnimationRuleActivation>{};
  }
  final result = <int, PathAnimationRuleActivation>{};
  for (final layer in map.layers.whereType<PathLayer>()) {
    if (layer.animationTriggers.isEmpty) {
      continue;
    }
    for (var ruleIndex = 0;
        ruleIndex < layer.animationTriggers.length;
        ruleIndex++) {
      final rule = layer.animationTriggers[ruleIndex];
      if (!rule.enabled) {
        continue;
      }
      if (rule.trigger != trigger) {
        continue;
      }
      final activation = PathAnimationRuleActivation(
        layerId: layer.id,
        presetId: layer.presetId,
        ruleId: resolvePathAnimationTriggerRuleId(
          rule,
          index: ruleIndex,
        ),
        rule: rule,
      );
      for (var index = 0; index < layer.cells.length && index < size; index++) {
        if (!layer.cells[index]) {
          continue;
        }
        result.putIfAbsent(index, () => activation);
      }
    }
  }
  return result;
}

Map<int, PathAnimationRuleActivation> _buildPathAnimationNearRuleByPos(
  MapData map,
) {
  final width = map.size.width;
  final height = map.size.height;
  final size = width * height;
  if (size <= 0 || width <= 0 || height <= 0) {
    return const <int, PathAnimationRuleActivation>{};
  }
  final result = <int, PathAnimationRuleActivation>{};
  for (final layer in map.layers.whereType<PathLayer>()) {
    if (layer.animationTriggers.isEmpty) {
      continue;
    }
    for (var ruleIndex = 0;
        ruleIndex < layer.animationTriggers.length;
        ruleIndex++) {
      final rule = layer.animationTriggers[ruleIndex];
      if (!rule.enabled || rule.trigger != PathAnimationTriggerType.onNear) {
        continue;
      }
      final activation = PathAnimationRuleActivation(
        layerId: layer.id,
        presetId: layer.presetId,
        ruleId: resolvePathAnimationTriggerRuleId(
          rule,
          index: ruleIndex,
        ),
        rule: rule,
      );
      for (var index = 0; index < layer.cells.length && index < size; index++) {
        if (!layer.cells[index]) {
          continue;
        }
        final x = index % width;
        final y = index ~/ width;
        final neighbors = <(int, int)>[
          (x - 1, y),
          (x + 1, y),
          (x, y - 1),
          (x, y + 1),
        ];
        for (final (nx, ny) in neighbors) {
          if (nx < 0 || ny < 0 || nx >= width || ny >= height) {
            continue;
          }
          final nearIndex = ny * width + nx;
          if (nearIndex < layer.cells.length && layer.cells[nearIndex]) {
            continue;
          }
          result.putIfAbsent(nearIndex, () => activation);
        }
      }
    }
  }
  return result;
}

GridSize _resolvePlacedElementFootprintSize(
  MapPlacedElement instance,
  Map<String, ProjectElementEntry> elementById,
) {
  final entry = elementById[instance.elementId];
  final source = entry?.frames.primarySource;
  final width = source == null || source.width <= 0 ? 1 : source.width;
  final height = source == null || source.height <= 0 ? 1 : source.height;
  return GridSize(width: width, height: height);
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

class PlacedElementBehaviorActivation {
  const PlacedElementBehaviorActivation({
    required this.element,
    required this.behavior,
  });

  final MapPlacedElement element;
  final MapPlacedElementBehavior behavior;
}

class PathAnimationRuleActivation {
  const PathAnimationRuleActivation({
    required this.layerId,
    required this.presetId,
    required this.ruleId,
    required this.rule,
  });

  final String layerId;
  final String presetId;
  final String ruleId;
  final PathAnimationTriggerRule rule;
}
