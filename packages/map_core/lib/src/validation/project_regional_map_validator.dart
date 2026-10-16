import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_regional_map.dart';

final class ProjectRegionalMapDiagnostic {
  const ProjectRegionalMapDiagnostic({
    required this.code,
    required this.path,
    required this.message,
  });
  final String code;
  final String path;
  final String message;

  Map<String, Object?> toJson() => {
    'code': code,
    'path': path,
    'message': message,
  };
}

List<ProjectRegionalMapDiagnostic> validateProjectRegionalMap({
  required ProjectRegionalMapCatalog? catalog,
  required Iterable<String> projectMapIds,
  Iterable<MapData>? maps,
}) {
  if (catalog == null) return const [];
  final regions = catalog.regions.map((region) => region.id).toSet();
  final mapIds = projectMapIds.toSet();
  final loadedMaps = {for (final map in maps ?? const <MapData>[]) map.id: map};
  final diagnostics = <ProjectRegionalMapDiagnostic>[];
  void add(String code, String path, String message) => diagnostics.add(
    ProjectRegionalMapDiagnostic(code: code, path: path, message: message),
  );
  for (final point in catalog.pointsOfInterest) {
    final path = '\$.regionalMap.pointsOfInterest[${point.id}]';
    if (!regions.contains(point.regionId)) {
      add(
        'regional_map.region_missing',
        '$path.regionId',
        'Choose an existing region.',
      );
    }
    for (final mapId in point.mapIds) {
      if (!mapIds.contains(mapId)) {
        add(
          'regional_map.discovery_map_missing',
          '$path.mapIds',
          'Choose an existing discovery map.',
        );
      }
    }
    final destination = point.destination;
    if (destination == null) continue;
    if (!mapIds.contains(destination.mapId)) {
      add(
        'regional_map.destination_map_missing',
        '$path.destination.mapId',
        'Choose an existing destination map.',
      );
      continue;
    }
    if (destination.spawnId == null) {
      add('regional_map.destination_spawn_missing', '$path.destination.spawnId',
        'Choose an explicit arrival spawn.');
      continue;
    }
    final map = loadedMaps[destination.mapId];
    if (map == null) continue;
    if (map.version != ProjectVersion.v8 || map.spatialScene != null) {
      add('regional_map.destination_map_unsupported', '$path.destination.mapId',
        'Choose a native 2D destination map.');
      continue;
    }
    final spawns = map.entities.where((entity) => entity.kind == MapEntityKind.spawn &&
      entity.spawn != null && (entity.id == destination.spawnId || entity.spawn!.spawnKey == destination.spawnId)).toList();
    if (spawns.isEmpty) {
      add('regional_map.destination_spawn_missing', '$path.destination.spawnId',
        'Choose an existing destination spawn.');
    } else if (spawns.length != 1) {
      add('regional_map.destination_spawn_ambiguous', '$path.destination.spawnId',
        'Choose a unique destination spawn.');
    } else if (spawns.single.pos.x < 0 || spawns.single.pos.y < 0 ||
        spawns.single.pos.x >= map.size.width || spawns.single.pos.y >= map.size.height) {
      add('regional_map.destination_spawn_outside_map', '$path.destination.spawnId',
        'Place the destination spawn inside its map.');
    }
  }
  return List.unmodifiable(diagnostics);
}
