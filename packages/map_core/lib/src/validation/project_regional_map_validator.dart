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
    final map = loadedMaps[destination.mapId];
    if (map != null &&
        destination.spawnId != null &&
        !map.entities.any(
          (entity) =>
              entity.kind == MapEntityKind.spawn &&
              (entity.id == destination.spawnId ||
                  entity.spawn?.spawnKey == destination.spawnId),
        )) {
      add(
        'regional_map.destination_spawn_missing',
        '$path.destination.spawnId',
        'Choose an existing destination spawn.',
      );
    }
  }
  return List.unmodifiable(diagnostics);
}
