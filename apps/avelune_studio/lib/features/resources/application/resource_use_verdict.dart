import 'package:map_core/map_core_domain.dart';

import 'resource_catalog.dart';

enum ResourceUseVerdict {
  usable,
  noMaps,
  incompatibleDimension,
  reservedToOtherMap,
  borderUnavailable,
  unavailable,
}

ResourceUseVerdict resourceUseVerdict(
  ResourceItem item,
  ProjectManifest project, {
  required bool canUse,
  String? activeMapId,
}) {
  if (project.maps.isEmpty) return ResourceUseVerdict.noMaps;
  if (!item.compatibleWith(project.settings.dimension)) {
    return ResourceUseVerdict.incompatibleDimension;
  }
  final mapId = item.metadata(project)?.mapId;
  if (activeMapId != null && mapId != null && mapId != activeMapId) {
    return ResourceUseVerdict.reservedToOtherMap;
  }
  final border = item.border;
  if (border != null &&
      (border.latestPublished == null || border.isDeprecated)) {
    return ResourceUseVerdict.borderUnavailable;
  }
  return canUse && item.usableIn(project, activeMapId: activeMapId)
      ? ResourceUseVerdict.usable
      : ResourceUseVerdict.unavailable;
}

String? resourceUseRefusalMessage(
  ResourceUseVerdict verdict,
  ResourceItem item,
  ProjectManifest project,
) => switch (verdict) {
  ResourceUseVerdict.usable => null,
  ResourceUseVerdict.noMaps =>
    'Ce projet ne contient aucune carte. Les ressources restent consultables.',
  ResourceUseVerdict.incompatibleDimension =>
    'Cette ressource ne se place pas dans un projet ${project.settings.dimension == ProjectDimension.threeD ? "3D" : "2D"}.',
  ResourceUseVerdict.reservedToOtherMap =>
    'Cette ressource est réservée à « ${project.maps.where((map) => map.id == item.metadata(project)?.mapId).firstOrNull?.name ?? "sa carte"} ».',
  ResourceUseVerdict.borderUnavailable =>
    'Cette bordure n’est pas disponible pour le tracé : elle n’est pas publiée ou elle est dépréciée.',
  ResourceUseVerdict.unavailable =>
    'L’utilisation sur la carte est momentanément indisponible.',
};
