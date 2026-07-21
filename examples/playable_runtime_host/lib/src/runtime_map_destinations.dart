import 'package:map_core/map_core.dart';

enum RuntimeMapDestinationStatus {
  current,
  known,
  locked,
}

/// Read-only player projection of an authored project map.
final class RuntimeMapDestination {
  const RuntimeMapDestination({
    required this.mapId,
    required this.authoredName,
    required this.displayName,
    required this.status,
  });

  final String mapId;
  final String authoredName;
  final String displayName;
  final RuntimeMapDestinationStatus status;
}

/// Builds the Phase 9 map list from existing manifest and narrative progress.
///
/// Fast travel itself belongs to FG-125 and is not synthesized here. The
/// current map is always known; other names are revealed only after a recorded
/// visit. Duplicate or blank manifest IDs are ignored defensively.
List<RuntimeMapDestination> resolveRuntimeMapDestinations({
  required List<ProjectMapEntry> maps,
  required GameState gameState,
}) {
  final currentMapId = gameState.currentMapId.trim();
  final knownMapIds = <String>{
    currentMapId,
    ...gameState.narrativeEventProgress.visitedNarrativeMapIds.map(
      (id) => id.trim(),
    ),
  }..remove('');
  final normalizedMaps = <String, ProjectMapEntry>{};
  for (final map in maps) {
    final mapId = map.id.trim();
    if (mapId.isEmpty) {
      continue;
    }
    normalizedMaps.putIfAbsent(mapId, () => map);
  }
  final sortedMaps = normalizedMaps.entries.toList(growable: false)
    ..sort((left, right) {
      final sortOrder = left.value.sortOrder.compareTo(right.value.sortOrder);
      if (sortOrder != 0) {
        return sortOrder;
      }
      final name = left.value.name.compareTo(right.value.name);
      return name != 0 ? name : left.key.compareTo(right.key);
    });

  return List<RuntimeMapDestination>.unmodifiable(
    sortedMaps.map((entry) {
      final mapId = entry.key;
      final authoredName =
          entry.value.name.trim().isEmpty ? mapId : entry.value.name.trim();
      final status = mapId == currentMapId
          ? RuntimeMapDestinationStatus.current
          : knownMapIds.contains(mapId)
              ? RuntimeMapDestinationStatus.known
              : RuntimeMapDestinationStatus.locked;
      return RuntimeMapDestination(
        mapId: mapId,
        authoredName: authoredName,
        displayName:
            status == RuntimeMapDestinationStatus.locked ? '???' : authoredName,
        status: status,
      );
    }),
  );
}
