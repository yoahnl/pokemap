part of 'map_workspace_controller.dart';

bool _historyHasMissingMapDestination(MapData map, ProjectManifest manifest) {
  final mapIds = manifest.maps.map((entry) => entry.id).toSet();
  return map.warps.any((warp) => !mapIds.contains(warp.targetMapId)) ||
      map.connections.any(
        (connection) => !mapIds.contains(connection.targetMapId),
      ) ||
      map.placedElements.any(
        (element) => element.behaviors.any(
          (behavior) =>
              behavior.effect.type == MapPlacedElementEffectType.traverseWarp &&
              !mapIds.contains(behavior.effect.targetMapId),
        ),
      );
}
