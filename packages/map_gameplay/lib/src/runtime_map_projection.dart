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
