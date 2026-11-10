import 'package:map_core/map_core_domain.dart';

final class MapGeneratedOwner {
  const MapGeneratedOwner({
    required this.layerId,
    required this.areaId,
    required this.areaName,
    required this.presetName,
  });

  final String layerId, areaId, areaName, presetName;
}

MapGeneratedOwner? mapGeneratedOwner(
  MapData map,
  ProjectManifest project,
  String elementId,
) {
  for (final layer in map.layers.whereType<EnvironmentLayer>()) {
    for (final area in layer.content.areas) {
      if (!area.generatedPlacementIds.contains(elementId)) continue;
      final preset = project.environmentPresets
          .where((preset) => preset.id == area.presetId)
          .firstOrNull;
      return MapGeneratedOwner(
        layerId: layer.id,
        areaId: area.id,
        areaName: area.name,
        presetName: preset?.name ?? 'environnement introuvable',
      );
    }
  }
  return null;
}
