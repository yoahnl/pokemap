import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../ports/project_file_reader.dart';
import 'project_snapshot.dart';
import 'workspace_handle_store.dart';

/// Loads every manifest-declared map twice to reject mixed disk revisions.
///
/// The double read cannot make unrelated filesystem operations atomic, but it
/// ensures this API never claims a coherent snapshot after observing a change
/// in any resource that contributes to the returned revision.
final class ProjectSnapshotLoader {
  const ProjectSnapshotLoader({
    required WorkspaceHandleStore handles,
  }) : _handles = handles;

  final WorkspaceHandleStore _handles;

  Future<ProjectSnapshot> load(ProjectHandle projectHandle) async {
    final access = _handles.resolveProject(projectHandle);
    final manifestBytes = await access.readBytes('project.json');
    final manifest = _decodeManifest(manifestBytes);
    final entries = _validatedMapEntries(manifest.maps);
    final resources = <_LoadedProjectResource>[
      _LoadedProjectResource(
        relativePath: 'project.json',
        identity: 'project',
        bytes: manifestBytes,
      ),
    ];
    final maps = <MapData>[];
    for (final entry in entries) {
      final bytes = await access.readBytes(entry.relativePath);
      final map = _decodeMap(bytes);
      if (map.id != entry.id) {
        throw const ProjectSnapshotException(
          'project.map_identity_mismatch',
          'A map document identity differs from its manifest entry.',
        );
      }
      maps.add(map);
      resources.add(
        _LoadedProjectResource(
          relativePath: entry.relativePath,
          identity: 'map:${entry.id}',
          bytes: bytes,
        ),
      );
    }
    resources.sort(
      (left, right) => left.relativePath.compareTo(right.relativePath),
    );
    for (final resource in resources) {
      final reread = await access.readBytes(resource.relativePath);
      if (!_bytesEqual(resource.bytes, reread)) {
        throw const ProjectSnapshotException(
          'project.changed_during_snapshot',
          'A project resource changed while the snapshot was loading.',
        );
      }
    }
    final revision = computeNarrativeProjectFingerprint([
      for (final resource in resources)
        NarrativeProjectFingerprintEntry(
          relativePath: resource.relativePath,
          bytes: resource.bytes,
        ),
    ]);
    final resourceFingerprints = <String, String>{
      for (final resource in resources)
        resource.identity: computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(
            relativePath: resource.relativePath,
            bytes: resource.bytes,
          ),
        ]),
    };
    return ProjectSnapshot(
      projectHandle: projectHandle,
      revision: revision,
      manifest: manifest,
      maps: maps,
      resourceFingerprints: resourceFingerprints,
    );
  }
}

List<ProjectMapEntry> _validatedMapEntries(List<ProjectMapEntry> entries) {
  final seenIds = <String>{};
  final seenPaths = <String>{};
  final validated = <ProjectMapEntry>[];
  for (final entry in entries) {
    final id = entry.id.trim();
    if (id.isEmpty) {
      throw const ProjectSnapshotException(
        'project.map_id_required',
        'Every manifest map entry requires an identity.',
      );
    }
    if (!seenIds.add(id)) {
      throw const ProjectSnapshotException(
        'project.duplicate_map_id',
        'Manifest map identities must be unique.',
      );
    }
    final normalizedPath =
        validateProjectRelativePath(entry.relativePath).join('/');
    if (!seenPaths.add(normalizedPath)) {
      throw const ProjectSnapshotException(
        'project.duplicate_map_path',
        'Manifest map resource paths must be unique.',
      );
    }
    validated.add(entry.copyWith(id: id, relativePath: normalizedPath));
  }
  validated.sort((left, right) {
    final pathOrder = left.relativePath.compareTo(right.relativePath);
    return pathOrder != 0 ? pathOrder : left.id.compareTo(right.id);
  });
  return List.unmodifiable(validated);
}

ProjectManifest _decodeManifest(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Expected an object.');
    }
    return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded));
  } on ProjectSnapshotException {
    rethrow;
  } on Object {
    throw const ProjectSnapshotException(
      'project.manifest_invalid',
      'The project manifest is not valid PokeMap JSON.',
    );
  }
}

MapData _decodeMap(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Expected an object.');
    }
    return MapData.fromJson(Map<String, dynamic>.from(decoded));
  } on ProjectSnapshotException {
    rethrow;
  } on Object {
    throw const ProjectSnapshotException(
      'project.map_invalid',
      'A declared map is not valid PokeMap JSON.',
    );
  }
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _LoadedProjectResource {
  _LoadedProjectResource({
    required this.relativePath,
    required this.identity,
    required List<int> bytes,
  }) : bytes = List.unmodifiable(bytes);

  final String relativePath;
  final String identity;
  final List<int> bytes;
}
