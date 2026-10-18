import 'package:map_core/map_core.dart';

import 'gameplay_player_state.dart';
import 'gameplay_world_state.dart';
import 'movement_terrain_policy.dart';
import 'npc_instance_pose_projection.dart';

final class CinematicActorPoseCommit {
  const CinematicActorPoseCommit({required this.world, required this.instances});

  final GameplayWorldState world;
  final MapInstanceWorldState instances;
}

CinematicActorPoseCommit prepareCinematicActorPoseCommit({
  required GameplayWorldState world,
  required MapData authoringMap,
  required MapInstanceWorldState instances,
  required MapInstanceRef instance,
  required ProjectManifest project,
  GameplayPlayerState? player,
  Map<String, MapInstanceNpcPose> npcPoses = const {},
}) {
  if (instances.instanceRef(world.map.id) != instance) {
    throw StateError('The cinematic requires its current map instance.');
  }
  final nextInstances = instances.setNpcPoses(instance, {
    ...instances.instancesByMapId[world.map.id]!.npcPoses,
    ...npcPoses,
  });
  final map = applyNpcInstancePosesToMap(
    map: world.map,
    authoringMap: authoringMap,
    instances: nextInstances,
    instance: instance,
    project: project,
    movingPlatformWorldState: world.movingPlatformWorldState,
    npcMapPresencePredicate: world.npcMapPresencePredicate,
    mapEntityPresencePredicate: world.mapEntityPresencePredicate,
  );
  final nextPlayer = player ?? world.player;
  final nextWorld = GameplayWorldState.initial(
    map: map,
    playerPos: nextPlayer.pos,
    project: project,
    tileWidth: world.tileWidthPx,
    tileHeight: world.tileHeightPx,
    movingPlatformWorldState: world.movingPlatformWorldState,
    npcMapPresencePredicate: world.npcMapPresencePredicate,
    mapEntityPresencePredicate: world.mapEntityPresencePredicate,
  ).withPlayer(nextPlayer);
  final rect = nextPlayer.playerCollisionRectPx;
  final cell = PlayerCollisionConventionsV1.projectFeetAnchorToCell(
    playerCollisionRectPx: rect,
    tileWidthPx: world.tileWidthPx,
    tileHeightPx: world.tileHeightPx,
    mapWidthCells: map.size.width,
    mapHeightCells: map.size.height,
  );
  if (cell != nextPlayer.pos || rect.leftPx < 0 || rect.topPx < 0 ||
      rect.leftPx + rect.widthPx > map.size.width * world.tileWidthPx ||
      rect.topPx + rect.heightPx > map.size.height * world.tileHeightPx ||
      nextWorld.worldStaticObstaclesCollidePlayerCollisionRect() ||
      ![rect, nextWorld.playerCharacterContactRect(rect)].every((area) => movementTerrainAllowsRect(
        map: map, rect: area, tileWidth: world.tileWidthPx,
        tileHeight: world.tileHeightPx, mode: nextPlayer.movementMode,
      ))) {
    throw StateError('The cinematic final player pose is not traversable.');
  }
  return CinematicActorPoseCommit(world: nextWorld, instances: nextInstances);
}
