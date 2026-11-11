import 'package:map_core/map_core.dart';

import 'regional_map_summary.dart';

const regionalPlaceFinderLimit = 12;
const regionalLinkCandidateLimit = 20;

String regionalMapChoiceLabel(
  ProjectMapEntry map,
  Map<String, String> folders,
) {
  final folder = folders[map.groupId];
  return map.groupId == null || folder == null
      ? map.name
      : '${map.name} · $folder';
}

typedef RegionalMapLink = ({String name, String mapId});

RegionalMapLink? regionalMapLinkConfirmation({
  required String name,
  required String? mapId,
  required bool asksName,
}) => mapId == null || (asksName && name.trim().isEmpty)
    ? null
    : (name: name.trim(), mapId: mapId);

String? regionalSuggestedMapId(ProjectManifest project, String? suggested) =>
    project.maps.any((map) => map.id == suggested) ? suggested : null;

List<ProjectRegionPointOfInterest> regionalPlaceMatches({
  required List<ProjectRegionPointOfInterest> points,
  required ProjectManifest project,
  required String query,
}) {
  final needle = query.trim().toLowerCase();
  return [
    if (needle.isNotEmpty)
      for (final point in points)
        if ('${point.label} ${point.id} ${regionalPlaceFlight(point, project)}'
            .toLowerCase()
            .contains(needle))
          point,
  ];
}

List<ProjectMapEntry> regionalLinkCandidates({
  required ProjectManifest project,
  required List<String> linked,
  required Map<String, String> folders,
  required String query,
}) {
  final needle = query.trim().toLowerCase();
  return [
    if (needle.isNotEmpty)
      for (final map in project.maps)
        if (!linked.contains(map.id) &&
            '${regionalMapChoiceLabel(map, folders)} ${map.id}'
                .toLowerCase()
                .contains(needle))
          map,
  ];
}

bool regionalLastLinkedLocked(
  List<String> linked,
  ProjectRegionPointDiscovery discovery,
) => linked.length == 1 && discovery == ProjectRegionPointDiscovery.onMapVisit;

Map<String, String> regionalSpawnOptions(MapData? map) => {
  for (final spawn
      in map?.entities.where(
            (entity) =>
                entity.kind == MapEntityKind.spawn && entity.spawn != null,
          ) ??
          const <MapEntity>[])
    spawn.id:
        '${spawn.name.isEmpty ? 'Arrivée' : spawn.name} · (${spawn.pos.x}, ${spawn.pos.y}) · ${_facing(spawn.spawn!.facing)}',
};

String _facing(EntityFacing facing) => switch (facing) {
  EntityFacing.north => 'Nord',
  EntityFacing.east => 'Est',
  EntityFacing.south => 'Sud',
  EntityFacing.west => 'Ouest',
};
