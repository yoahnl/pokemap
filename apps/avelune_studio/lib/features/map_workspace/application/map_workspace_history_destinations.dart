part of 'map_workspace_controller.dart';

String? _historyResourceProblem(
  MapData before,
  MapData next,
  ProjectManifest manifest,
) {
  final availableModels = manifest.models3d.map((model) => model.id).toSet();
  if (next.spatialScene?.instances.any(
        (instance) => !availableModels.contains(instance.modelId),
      ) ??
      false) {
    return 'Cette annulation restaurerait un modèle 3D supprimé.';
  }
  final retainedElements = before.placedElements
      .map((e) => e.elementId)
      .toSet();
  final retainedCharacters = before.entities
      .map((entity) => entity.npc?.characterId)
      .whereType<String>()
      .toSet();
  final availableCharacters = manifest.characters.map((c) => c.id).toSet();
  if (next.entities.any((entity) {
    final id = entity.npc?.characterId;
    return id != null &&
        !retainedCharacters.contains(id) &&
        !availableCharacters.contains(id);
  })) {
    return 'Cette annulation restaurerait un personnage supprimé.';
  }
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
  Set<String> presets(MapData map) => {
    for (final layer in map.layers.whereType<SmartTileLayer>()) layer.presetId,
  };
  final retainedPresets = presets(before);
  final availablePresets = manifest.smartTileCatalog.presets
      .map((preset) => preset.id)
      .toSet();
  if (presets(next).any(
    (id) => !retainedPresets.contains(id) && !availablePresets.contains(id),
  )) {
    return 'Cette annulation restaurerait un terrain supprimé.';
  }
  Set<String> environments(MapData map) => {
    for (final layer in map.layers.whereType<EnvironmentLayer>())
      for (final area in layer.content.areas) area.presetId,
  };
  final retainedEnvironments = environments(before);
  final availableEnvironments = manifest.environmentPresets
      .map((preset) => preset.id)
      .toSet();
  if (environments(next).any(
    (id) =>
        !retainedEnvironments.contains(id) &&
        !availableEnvironments.contains(id),
  )) {
    return 'Cette annulation restaurerait un environnement supprimé.';
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
