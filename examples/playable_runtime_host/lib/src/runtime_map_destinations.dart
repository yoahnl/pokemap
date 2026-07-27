import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

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
  final authoredNames = <String, String>{};
  for (final map in maps) {
    final mapId = map.id.trim();
    if (mapId.isEmpty) continue;
    authoredNames.putIfAbsent(
      mapId,
      () => map.name.trim().isEmpty ? mapId : map.name.trim(),
    );
  }
  return List<RuntimeMapDestination>.unmodifiable(
    projectRuntimeMapLocations(maps: maps, gameState: gameState)
        .map((location) {
      final authoredName = authoredNames[location.mapId] ?? location.mapId;
      final status = switch (location.status) {
        RuntimeMapLocationStatus.current => RuntimeMapDestinationStatus.current,
        RuntimeMapLocationStatus.discovered =>
          RuntimeMapDestinationStatus.known,
        RuntimeMapLocationStatus.unknown => RuntimeMapDestinationStatus.locked,
      };
      return RuntimeMapDestination(
        mapId: location.mapId,
        authoredName: authoredName,
        displayName:
            location.displayName.isEmpty ? authoredName : location.displayName,
        status: status,
      );
    }),
  );
}
