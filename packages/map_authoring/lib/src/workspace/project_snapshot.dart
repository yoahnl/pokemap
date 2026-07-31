import 'package:map_core/map_core.dart';

import 'workspace_handle_store.dart';

final class ProjectSnapshotException implements Exception {
  const ProjectSnapshotException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ProjectSnapshotException($code): $message';
}

/// Immutable, path-free view of one coherently read PokeMap project revision.
final class ProjectSnapshot {
  ProjectSnapshot({
    required this.projectHandle,
    required this.revision,
    required this.manifest,
    required Iterable<MapData> maps,
    required Map<String, String> resourceFingerprints,
  })  : maps = List.unmodifiable(
          maps.toList()..sort((left, right) => left.id.compareTo(right.id)),
        ),
        resourceFingerprints = Map.unmodifiable(
          Map.fromEntries(
            (resourceFingerprints.entries.toList()
                  ..sort((left, right) => left.key.compareTo(right.key)))
                .map((entry) => MapEntry(entry.key, entry.value)),
          ),
        ) {
    if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(revision)) {
      throw ArgumentError.value(
        revision,
        'revision',
        'must be a lowercase SHA-256 fingerprint',
      );
    }
    final mapIds = <String>{};
    for (final map in this.maps) {
      if (map.id.trim().isEmpty || !mapIds.add(map.id)) {
        throw ArgumentError.value(
          map.id,
          'maps',
          'map identities must be nonblank and unique',
        );
      }
    }
    for (final entry in this.resourceFingerprints.entries) {
      if (entry.key.trim().isEmpty ||
          !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(entry.value)) {
        throw ArgumentError.value(
          entry,
          'resourceFingerprints',
          'keys must be nonblank and values must be SHA-256 fingerprints',
        );
      }
    }
    _mapsById = Map.unmodifiable({
      for (final map in this.maps) map.id: map,
    });
  }

  final ProjectHandle projectHandle;
  final String revision;
  final ProjectManifest manifest;
  final List<MapData> maps;
  final Map<String, String> resourceFingerprints;
  late final Map<String, MapData> _mapsById;

  MapData? mapById(String id) => _mapsById[id];
}
