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

String mapEnvironmentAreaSummary(
  EnvironmentArea area,
  ProjectManifest project,
) {
  final preset = project.environmentPresets
      .where((preset) => preset.id == area.presetId)
      .firstOrNull;
  if (preset == null) {
    return 'Ressource introuvable : la zone est conservée telle quelle.';
  }
  final params = area.paramsOverride ?? preset.defaultParams;
  final resources = preset.palette.length;
  final generated = area.generatedPlacementIds.length;
  final manual = area.manualPlacementIds.length;
  return 'Ressource : ${preset.name} · $resources ${resources > 1 ? 'décors' : 'décor'} en répartition · '
      'densité ${(params.density * 100).round()} % · espacement ${params.minSpacingCells} ${params.minSpacingCells > 1 ? 'cases' : 'case'} · '
      '$generated ${generated > 1 ? 'décors générés appartiennent' : 'décor généré appartient'} à cette zone'
      '${manual == 0 ? '' : ' · $manual posé${manual > 1 ? 's' : ''} à la main conservé${manual > 1 ? 's' : ''}'}.';
}
