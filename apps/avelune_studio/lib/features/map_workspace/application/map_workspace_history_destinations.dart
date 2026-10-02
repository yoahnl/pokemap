part of 'map_workspace_controller.dart';

String? _historyResourceProblem(
  MapData before,
  MapData next,
  ProjectManifest manifest,
) {
  final retainedElements = before.placedElements
      .map((e) => e.elementId)
      .toSet();
  final availableElements = manifest.elements.map((e) => e.id).toSet();
  if (next.placedElements.any(
    (e) =>
        !retainedElements.contains(e.elementId) &&
        !availableElements.contains(e.elementId),
  )) {
    return 'Cette annulation restaurerait un décor supprimé.';
  }
  Set<String> tilesets(MapData map) => {
    if (map.tilesetId.isNotEmpty) map.tilesetId,
    for (final layer in map.layers.whereType<TileLayer>())
      for (final tile in layer.palette) tile.tilesetId,
    for (final layer in map.layers.whereType<ObjectLayer>())
      for (final tile in layer.tileObjects) tile.tile.tilesetId,
  };
  final retainedTilesets = tilesets(before);
  final availableTilesets = manifest.tilesets.map((t) => t.id).toSet();
  if (tilesets(next).any(
    (id) => !retainedTilesets.contains(id) && !availableTilesets.contains(id),
  )) {
    return 'Cette annulation restaurerait une planche supprimée.';
  }
  return null;
}

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
