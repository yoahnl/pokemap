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
    Map<String, List<int>> resourceBytes = const {},
  })  : maps = List.unmodifiable(
          maps.toList()..sort((left, right) => left.id.compareTo(right.id)),
        ),
        resourceFingerprints = Map.unmodifiable(
          Map.fromEntries(
            (resourceFingerprints.entries.toList()
                  ..sort((left, right) => left.key.compareTo(right.key)))
                .map((entry) => MapEntry(entry.key, entry.value)),
          ),
        ),
        _resourceBytes = Map.unmodifiable(
          Map.fromEntries(
            (resourceBytes.entries.toList()
                  ..sort((left, right) => left.key.compareTo(right.key)))
                .map(
              (entry) => MapEntry(
                entry.key,
                List<int>.unmodifiable(entry.value),
              ),
            ),
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
    for (final entry in _resourceBytes.entries) {
      if (!this.resourceFingerprints.containsKey(entry.key) ||
          entry.value.any((byte) => byte < 0 || byte > 255)) {
        throw ArgumentError.value(
          entry.key,
          'resourceBytes',
          'keys must identify fingerprinted resources and values must be bytes',
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
  final Map<String, List<int>> _resourceBytes;
  late final Map<String, MapData> _mapsById;

  MapData? mapById(String id) => _mapsById[id];

  /// Exact snapshot pre-image for one path-free resource identity.
  ///
  /// Payloads are intentionally excluded from JSON projections. They exist so
  /// mutation planners can freeze the real disk bytes used by compare-and-swap
  /// instead of manufacturing authority from a re-encoded model.
  List<int> resourceBytes(String identity) {
    final bytes = _resourceBytes[identity];
    if (bytes == null) {
      throw const ProjectSnapshotException(
        'project.resource_bytes_unavailable',
        'The exact resource pre-image is unavailable in this snapshot.',
      );
    }
    return List<int>.unmodifiable(bytes);
  }
}
