import 'package:map_core/map_core.dart';

import 'workspace_handle_store.dart';

final class ProjectSnapshotException implements Exception {
  const ProjectSnapshotException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ProjectSnapshotException($code): $message';
}

/// Path-free problem encountered while building a non-mutating editor view.
///
/// Strict API and mutation sessions still throw immediately. The editor-only
/// projection may retain primary project/map data so a creator can repair a
/// missing supplemental source without losing access to the project.
final class ProjectSnapshotLoadDiagnostic {
  ProjectSnapshotLoadDiagnostic({
    required String code,
    required String resourceKind,
    required String resourceId,
    this.blocking = true,
  })  : code = _requiredDiagnosticValue(code, 'code'),
        resourceKind = _requiredDiagnosticValue(
          resourceKind,
          'resourceKind',
        ),
        resourceId = _requiredDiagnosticValue(resourceId, 'resourceId');

  final String code;
  final String resourceKind;
  final String resourceId;
  final bool blocking;

  Map<String, Object?> toJson() => {
        'code': code,
        'resourceKind': resourceKind,
        'resourceId': resourceId,
        'blocking': blocking,
      };
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
    Map<String, String> resourceStorageKeys = const {},
    Iterable<ProjectSnapshotLoadDiagnostic> loadDiagnostics = const [],
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
        ),
        resourceStorageKeys = Map.unmodifiable(
          Map.fromEntries(
            (resourceStorageKeys.entries.toList()
                  ..sort((left, right) => left.key.compareTo(right.key)))
                .map((entry) => MapEntry(entry.key, entry.value)),
          ),
        ),
        loadDiagnostics = List.unmodifiable(loadDiagnostics) {
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
    for (final entry in this.resourceStorageKeys.entries) {
      if (!this.resourceFingerprints.containsKey(entry.key) ||
          entry.value.trim().isEmpty ||
          entry.value != entry.value.trim()) {
        throw ArgumentError.value(
          entry,
          'resourceStorageKeys',
          'keys must identify fingerprinted resources and paths must be stable',
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
  final Map<String, String> resourceStorageKeys;
  final List<ProjectSnapshotLoadDiagnostic> loadDiagnostics;
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

  /// Optional exact pre-image for supplemental project resources.
  List<int>? findResourceBytes(String identity) {
    final bytes = _resourceBytes[identity];
    return bytes == null ? null : List<int>.unmodifiable(bytes);
  }
}

String _requiredDiagnosticValue(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized != value) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return normalized;
}
