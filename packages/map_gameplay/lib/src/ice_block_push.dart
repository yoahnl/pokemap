import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'field_action.dart';
import 'field_obstacle_action.dart';
import 'cut_obstacle_action.dart';
import 'gameplay_movement_effect.dart';
import 'gameplay_world_state.dart';

FieldObstacleSlideResult startIceBlockPush({
  required GameplayWorldState world,
  required GameState gameState,
  required String entityId,
  required Direction direction,
  MapData? authoringMap,
  ProjectManifest? project,
  Iterable<PixelRect> characterReservations = const [],
}) {
  final map = world.map;
  final instance = gameState.mapInstanceWorldState.instanceRef(map.id);
  final source = GridPos(
    x: world.player.pos.x + direction.dx,
    y: world.player.pos.y + direction.dy,
  );
  final targets =
      map.entities.where((entity) => entity.id == entityId).toList();
  if (map.spatialScene != null ||
      map.version == ProjectVersion.v9 ||
      instance == null ||
      map.id != gameState.currentMapId ||
      entityId.isEmpty ||
      entityId.trim() != entityId ||
      targets.length != 1 ||
      targets.single.pos != source ||
      targets.single.fieldObstacle?.kind != FieldObstacleKind.iceBlock ||
      targets.single.kind != MapEntityKind.custom ||
      !targets.single.blocksMovement ||
      targets.single.size != const GridSize(width: 1, height: 1) ||
      map.entities
              .where((entity) =>
                  resolveEntityCollisionCells(entity).contains(source))
              .length !=
          1 ||
      world.entityAt(source.x, source.y)?.id != entityId ||
      world.player.pos != gameState.playerPosition ||
      world.player.facing != direction ||
      gameState.playerFacing != direction.asFacing ||
      world.player.movementMode != MovementMode.walk ||
      gameState.playerMovementMode != MovementMode.walk ||
      (gameState.playerPixelPosition != null &&
          gameState.playerPixelPosition !=
              PixelOffset(
                x: world.player.playerPositionPx.leftPx,
                y: world.player.playerPositionPx.topPx,
              ))) {
    return const FieldObstacleSlideRefused(FieldActionRefusal.targetChanged);
  }
  try {
    applyFieldObstacleWorldStateToMap(
      map: map,
      authoringMap: authoringMap,
      instances: gameState.mapInstanceWorldState,
      instance: instance,
      project: project,
      movingPlatformWorldState: gameState.movingPlatformWorldState,
      movingPropWorldState: gameState.movingPropWorldState,
      npcMapPresencePredicate: world.npcMapPresencePredicate,
      mapEntityPresencePredicate: world.mapEntityPresencePredicate,
    );
  } on Object {
    return const FieldObstacleSlideRefused(
        FieldActionRefusal.noLongerAvailable);
  }
  if (gameState.mapInstanceWorldState
      .isFieldObstacleCleared(instance, entityId)) {
    return const FieldObstacleSlideRefused(
        FieldActionRefusal.noLongerAvailable);
  }
  final target =
      GridPos(x: source.x + direction.dx, y: source.y + direction.dy);
  final rect = PixelRect(
    leftPx: target.x * world.tileWidthPx,
    topPx: target.y * world.tileHeightPx,
    widthPx: world.tileWidthPx,
    heightPx: world.tileHeightPx,
  );
  bool overlaps(PixelRect other) =>
      rect.leftPx < other.leftPx + other.widthPx &&
      rect.leftPx + rect.widthPx > other.leftPx &&
      rect.topPx < other.topPx + other.heightPx &&
      rect.topPx + rect.heightPx > other.topPx;
  if (target.x < 0 ||
      target.y < 0 ||
      target.x >= map.size.width ||
      target.y >= map.size.height ||
      world.isWaterCell(target.x, target.y) ||
      world.worldStaticObstaclesCollidePixelRect(rect) ||
      overlaps(world.player.playerCollisionRectPx) ||
      characterReservations.any(overlaps)) {
    return const FieldObstacleSlideStopped(
      reason: FieldObstacleBlockReason.blockedDestination,
    );
  }
  return FieldObstacleSlideMoved(
    gameState: gameState.copyWith(
      mapInstanceWorldState: gameState.mapInstanceWorldState.moveFieldObstacle(
        instance,
        entityId,
        target,
      ),
    ),
    world: world.withEntityPosition(entityId, target),
    from: source,
    to: target,
    slide: resolveGameplaySlideEffectAt(map, target, direction) == null
        ? null
        : FieldObstacleSlide(
            instance: instance,
            entityId: entityId,
            direction: direction,
            expectedPosition: target,
            remainingSteps:
                (direction.dx == 0 ? map.size.height : map.size.width) - 1,
          ),
  );
}
