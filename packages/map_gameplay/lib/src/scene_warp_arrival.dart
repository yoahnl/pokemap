import 'package:map_core/map_core.dart';

import 'gameplay_world_state.dart';

bool isSceneWarpArrivalAllowed({
  required GameplayWorldState world,
  required ProjectManifest project,
  String? arrivalCollisionOwnerEntityId,
}) {
  if (world.map.spatialScene != null) {
    throw StateError('Scene warp arrival requires a 2D map.');
  }
  final rect = world.player.playerCollisionRectPx;
  final contact = world.playerCharacterContactRect(rect);
  final width = world.map.size.width * world.tileWidthPx;
  final height = world.map.size.height * world.tileHeightPx;
  for (final footprint in [rect, contact]) {
    if (footprint.widthPx <= 0 ||
        footprint.heightPx <= 0 ||
        footprint.leftPx < 0 ||
        footprint.topPx < 0 ||
        footprint.leftPx + footprint.widthPx > width ||
        footprint.topPx + footprint.heightPx > height) {
      return false;
    }
  }
  final anchor = PlayerCollisionConventionsV1.projectFeetAnchorToCell(
    playerCollisionRectPx: rect,
    tileWidthPx: world.tileWidthPx,
    tileHeightPx: world.tileHeightPx,
    mapWidthCells: world.map.size.width,
    mapHeightCells: world.map.size.height,
  );
  if (anchor != world.player.pos) {
    throw StateError('Scene warp arrival has an incoherent player anchor.');
  }
  var collisionWorld = world;
  final ownerId = arrivalCollisionOwnerEntityId;
  if (ownerId != null) {
    if (ownerId.isEmpty || ownerId.trim() != ownerId) {
      throw StateError('Scene warp arrival owner must have a canonical ID.');
    }
    final owners = world.map.entities.where((entity) => entity.id == ownerId);
    if (owners.length != 1 ||
        !isSceneActorEntityReferenceAvailable(project, owners.single)) {
      throw StateError(
          'Scene warp arrival owner must identify one NPC Character.');
    }
    if (owners.single.pos != anchor) {
      throw StateError('Scene warp arrival owner must match the exact anchor.');
    }
    final previousPresence = world.npcMapPresencePredicate;
    collisionWorld = world.withNpcMapPresencePredicate((mapId, entity) =>
        !(mapId == world.map.id && entity.id == ownerId) &&
        (previousPresence?.call(mapId, entity) ?? true));
  }
  return !collisionWorld.worldStaticObstaclesCollidePlayerCollisionRect() &&
      (!world.isWaterCell(anchor.x, anchor.y) ||
          world.player.movementMode == MovementMode.surf);
}
