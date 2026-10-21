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
  MovingPropWorldState movingPropWorldState =
      const MovingPropWorldState.empty(),
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
  for (final entity in authoringMap.entities) {
    if (authored.containsKey(entity.id)) {
      throw StateError('NPC identity is ambiguous.');
    }
    authored[entity.id] = entity;
  }
  final variantOwners = <String, List<MapEntityPresentationVariant>>{};
  for (final entry in saved.entries) {
    final entity = authored[entry.key];
    final position = entry.value.position;
    final variants = entity?.presentation?.variants
            .where((variant) => variant.characterId != null)
            .toList() ??
        const <MapEntityPresentationVariant>[];
    final declaredVariantOwner = entity != null &&
        entity.npc == null &&
        variants.isNotEmpty &&
        project != null &&
        validateMapEntityPresentation(
                project: project, map: authoringMap, entity: entity)
            .isEmpty;
    if ((entity?.npc == null && !declaredVariantOwner) ||
        position.x < 0 ||
        position.y < 0 ||
        position.x + entity!.size.width > map.size.width ||
        position.y + entity.size.height > map.size.height ||
        (declaredVariantOwner &&
            variants.any((variant) =>
                position.x + variant.size.width > map.size.width ||
                position.y + variant.size.height > map.size.height)) ||
        map.entities.where((entity) => entity.id == entry.key).length != 1) {
      throw StateError(
          'Saved NPC ${entry.key} has an incompatible identity or pose.');
    }
    if (declaredVariantOwner) {
      final current =
          map.entities.singleWhere((value) => value.id == entry.key);
      final footprint = resolveEntityCollisionFootprint(current);
      if (current.presentation != entity.presentation ||
          (current.kind == MapEntityKind.custom && current.npc != null) ||
          (current.kind == MapEntityKind.npc &&
              !variants.any((variant) =>
                  current.npc?.characterId == variant.characterId &&
                  current.size == variant.size &&
                  current.blocksMovement == variant.blocksMovement &&
                  current.interactionMode == variant.interactionMode &&
                  footprint.pos == current.pos &&
                  footprint.size == variant.size)) ||
          !const {MapEntityKind.npc, MapEntityKind.custom}
              .contains(current.kind)) {
        throw StateError(
            'Saved NPC ${entry.key} has an undeclared presentation.');
      }
      variantOwners[entry.key] = variants;
    }
  }
  final projected = map.copyWith(entities: [
    for (final entity in map.entities)
      if (entity.kind == MapEntityKind.npc &&
          (authored[entity.id]?.npc != null ||
              variantOwners.containsKey(entity.id)))
        entity.copyWith(
          pos: saved[entity.id]?.position ?? authored[entity.id]!.pos,
          npc: entity.npc!.copyWith(
              facing: saved[entity.id]?.facing ??
                  authored[entity.id]!.npc?.facing ??
                  entity.npc!.facing),
        )
      else if (entity.kind == MapEntityKind.custom && variantOwners.containsKey(entity.id))
        entity.copyWith(pos: saved[entity.id]!.position)
      else
        entity,
  ]);
  for (final id in saved.keys) {
    final entity = projected.entities.singleWhere((entity) => entity.id == id);
    if (entity.kind != MapEntityKind.npc) continue;
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
      movingPropWorldState: movingPropWorldState,
      tileWidth: project?.settings.tileWidth ?? 16,
      tileHeight: project?.settings.tileHeight ?? 16,
      npcMapPresencePredicate: npcMapPresencePredicate,
      mapEntityPresencePredicate: mapEntityPresencePredicate,
    );
    final rect = resolveEntityCollisionRectPx(entity,
        tileWidthPx: world.tileWidthPx, tileHeightPx: world.tileHeightPx);
    if (!movementTerrainAllowsRect(
          map: projected,
          rect: rect,
          tileWidth: world.tileWidthPx,
          tileHeight: world.tileHeightPx,
          mode: MovementMode.walk,
        ) ||
        world.worldStaticObstaclesCollidePixelRect(rect)) {
      throw StateError(
          'Saved NPC $id overlaps an occupied or impassable cell.');
    }
  }
  return projected == map ? map : projected;
}
