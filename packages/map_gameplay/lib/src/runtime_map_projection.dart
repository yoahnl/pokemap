import 'package:map_core/map_core.dart';

enum RuntimeMapLocationStatus {
  current,
  discovered,
  unknown,
}

/// Data-only projection of one authored map for a player-facing world map.
final class RuntimeMapLocation {
  const RuntimeMapLocation({
    required this.mapId,
    required this.displayName,
    required this.status,
  });

  final String mapId;
  final String displayName;
  final RuntimeMapLocationStatus status;
}

/// Resolves the consultable world map from authored maps and persisted visits.
///
/// The current map is always visible. Undiscovered authored names are hidden,
/// and travel is deliberately absent from this read-only projection.
List<RuntimeMapLocation> projectRuntimeMapLocations({
  required List<ProjectMapEntry> maps,
  required GameState gameState,
}) {
  final currentMapId = gameState.currentMapId.trim();
  final discoveredMapIds = <String>{
    ...gameState.narrativeEventProgress.visitedNarrativeMapIds.map(
      (mapId) => mapId.trim(),
    ),
    if (currentMapId.isNotEmpty) currentMapId,
  }..remove('');
  final authoredMaps = <String, ProjectMapEntry>{};
  for (final map in maps) {
    final mapId = map.id.trim();
    if (mapId.isNotEmpty) authoredMaps.putIfAbsent(mapId, () => map);
  }

  final locations = authoredMaps.entries.map((entry) {
    final status = entry.key == currentMapId
        ? RuntimeMapLocationStatus.current
        : discoveredMapIds.contains(entry.key)
            ? RuntimeMapLocationStatus.discovered
            : RuntimeMapLocationStatus.unknown;
    final authoredName = entry.value.name.trim();
    return (
      location: RuntimeMapLocation(
        mapId: entry.key,
        displayName:
            status == RuntimeMapLocationStatus.unknown ? '???' : authoredName,
        status: status,
      ),
      sortOrder: entry.value.sortOrder,
    );
  }).toList();

  if (currentMapId.isNotEmpty && !authoredMaps.containsKey(currentMapId)) {
    locations.add(
      (
        location: RuntimeMapLocation(
          mapId: currentMapId,
          displayName: '',
          status: RuntimeMapLocationStatus.current,
        ),
        sortOrder: -1,
      ),
    );
  }

  locations.sort((left, right) {
    final byStatus = left.location.status.index.compareTo(
      right.location.status.index,
    );
    if (byStatus != 0) return byStatus;
    final byOrder = left.sortOrder.compareTo(right.sortOrder);
    if (byOrder != 0) return byOrder;
    final byName =
        left.location.displayName.compareTo(right.location.displayName);
    return byName != 0
        ? byName
        : left.location.mapId.compareTo(right.location.mapId);
  });
  return List<RuntimeMapLocation>.unmodifiable(
    locations.map((entry) => entry.location),
  );
}

final class RuntimeRegionalMapRegion {
  RuntimeRegionalMapRegion(
      {required this.id,
      required this.displayName,
      this.imagePath,
      required this.sampling,
      required List<RuntimeRegionalMapPoint> points})
      : points = List.unmodifiable(points);
  final String id;
  final String displayName;
  final String? imagePath;
  final ProjectMenuImageSampling sampling;
  final List<RuntimeRegionalMapPoint> points;
}

final class RuntimeRegionalMapPoint {
  const RuntimeRegionalMapPoint(
      {required this.id,
      required this.regionId,
      required this.u,
      required this.v,
      required this.displayName,
      required this.status,
      this.description,
      this.thumbnailPath,
      this.destination});
  final String id;
  final String regionId;
  final double u;
  final double v;
  final String displayName;
  final RuntimeMapLocationStatus status;
  final String? description;
  final String? thumbnailPath;
  final ProjectRegionDestination? destination;
}

List<RuntimeRegionalMapRegion> projectRuntimeRegionalMap(
    {required ProjectRegionalMapCatalog catalog,
    required GameState gameState,
    required String locale}) {
  final visited = {
    ...gameState.narrativeEventProgress.visitedNarrativeMapIds,
    gameState.currentMapId
  };
  final visible = <String, List<RuntimeRegionalMapPoint>>{};
  final points = catalog.pointsOfInterest.toList()
    ..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
  for (final point in points) {
    if (point.visibility == ProjectRegionPointVisibility.hidden) continue;
    final known = point.discovery == ProjectRegionPointDiscovery.always ||
        point.mapIds.any(visited.contains);
    if (!known &&
        point.visibility == ProjectRegionPointVisibility.discoveredOnly) {
      continue;
    }
    final current = point.mapIds.contains(gameState.currentMapId);
    visible.putIfAbsent(point.regionId, () => []).add(RuntimeRegionalMapPoint(
          id: point.id,
          regionId: point.regionId,
          u: point.u,
          v: point.v,
          displayName: known ? point.labelFor(locale) : '???',
          status: current
              ? RuntimeMapLocationStatus.current
              : known
                  ? RuntimeMapLocationStatus.discovered
                  : RuntimeMapLocationStatus.unknown,
          description: known ? point.descriptionFor(locale) : null,
          thumbnailPath: known ? point.thumbnailPath : null,
          destination: known ? point.destination : null,
        ));
  }
  final regions = catalog.regions.toList()
    ..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
  return List.unmodifiable([
    for (final region in regions)
      if (visible[region.id]?.isNotEmpty ?? false)
        RuntimeRegionalMapRegion(
            id: region.id,
            displayName: region.labelFor(locale),
            imagePath: region.imagePath,
            sampling: region.sampling,
            points: visible[region.id]!),
  ]);
}
