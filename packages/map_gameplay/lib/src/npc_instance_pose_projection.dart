import 'package:map_core/map_core.dart';

import 'gameplay_world_state.dart';
import 'movement_terrain_policy.dart';

MapData applyNpcInstancePosesToMap({
  required MapData map,
  required MapData authoringMap,
  required MapInstanceWorldState instances,
  required MapInstanceRef instance,
  ProjectManifest? project,
  MovingPlatformWorldState movingPlatformWorldState =
      const MovingPlatformWorldState.empty(),
  NpcMapPresencePredicate? npcMapPresencePredicate,
  MapEntityPresencePredicate? mapEntityPresencePredicate,
}) {
  if (map.id != instance.mapId ||
      instances.instanceRef(map.id) != instance ||
      authoringMap.id != map.id ||
      authoringMap.size != map.size ||
      authoringMap.version != map.version) {
    throw StateError(
        'NPC poses require matching geometry and the current map instance.');
  }
  final saved = instances.instancesByMapId[map.id]!.npcPoses;
  if (saved.isNotEmpty &&
      (map.spatialScene != null || map.version == ProjectVersion.v9)) {
    throw StateError('Map instance NPC poses require a two-dimensional map.');
  }
  final authored = <String, MapEntity>{};
  for (final entity in authoringMap.entities
      .where((entity) => entity.kind == MapEntityKind.npc)) {
    if (authored.containsKey(entity.id)) {
      throw StateError('NPC identity is ambiguous.');
    }
    authored[entity.id] = entity;
  }
  for (final entry in saved.entries) {
    final entity = authored[entry.key];
    final position = entry.value.position;
    if (entity?.npc == null ||
        position.x < 0 ||
        position.y < 0 ||
        position.x + entity!.size.width > map.size.width ||
        position.y + entity.size.height > map.size.height ||
        map.entities.where((entity) => entity.id == entry.key).length != 1) {
      throw StateError(
          'Saved NPC ${entry.key} has an incompatible identity or pose.');
    }
  }
  final projected = map.copyWith(entities: [
    for (final entity in map.entities)
      if (entity.kind == MapEntityKind.npc && authored[entity.id]?.npc != null)
        entity.copyWith(
          pos: saved[entity.id]?.position ?? authored[entity.id]!.pos,
          npc: entity.npc!.copyWith(
              facing:
                  saved[entity.id]?.facing ?? authored[entity.id]!.npc!.facing),
        )
      else
        entity,
  ]);
  for (final id in saved.keys) {
    final entity = projected.entities.singleWhere((entity) => entity.id == id);
    if (!(npcMapPresencePredicate?.call(map.id, entity) ?? true) ||
        !(mapEntityPresencePredicate?.call(map.id, entity) ?? true)) {
      continue;
    }
    final world = GameplayWorldState.initial(
      map: projected.copyWith(
          entities:
              projected.entities.where((entity) => entity.id != id).toList()),
      playerPos: const GridPos(x: 0, y: 0),
      project: project,
      movingPlatformWorldState: movingPlatformWorldState,
      tileWidth: project?.settings.tileWidth ?? 16,
      tileHeight: project?.settings.tileHeight ?? 16,
      npcMapPresencePredicate: npcMapPresencePredicate,
      mapEntityPresencePredicate: mapEntityPresencePredicate,
    );
    final rect = resolveEntityCollisionRectPx(entity,
        tileWidthPx: world.tileWidthPx, tileHeightPx: world.tileHeightPx);
    if (!movementTerrainAllowsRect(
          map: projected, rect: rect, tileWidth: world.tileWidthPx,
          tileHeight: world.tileHeightPx, mode: MovementMode.walk,
        ) ||
        world.worldStaticObstaclesCollidePixelRect(rect)) {
      throw StateError(
          'Saved NPC $id overlaps an occupied or impassable cell.');
    }
  }
  return projected == map ? map : projected;
}
