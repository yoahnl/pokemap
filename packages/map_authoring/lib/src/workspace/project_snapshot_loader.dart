import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/artifact_ref.dart';
import '../ports/project_file_reader.dart';
import '../domains/assets/asset_store.dart';
import '../domains/narrative/dialogue_source_store.dart';
import 'project_snapshot.dart';
import 'workspace_handle_store.dart';

enum ProjectSnapshotLoadPolicy {
  strict,
  editorReadProjection,
}

/// Loads every manifest-declared map and external dialogue source twice to
/// reject mixed disk revisions.
///
/// The double read cannot make unrelated filesystem operations atomic, but it
/// ensures this API never claims a coherent snapshot after observing a change
/// in any resource that contributes to the returned revision.
final class ProjectSnapshotLoader {
  const ProjectSnapshotLoader({
    required WorkspaceHandleStore handles,
  }) : _handles = handles;

  final WorkspaceHandleStore _handles;

  Future<ProjectSnapshot> load(
    ProjectHandle projectHandle, {
    ProjectSnapshotLoadPolicy policy = ProjectSnapshotLoadPolicy.strict,
  }) async {
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
    final loadDiagnostics = <ProjectSnapshotLoadDiagnostic>[];
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
    final occupiedPaths = <String>{
      for (final resource in resources) resource.relativePath,
    };
    for (final entry in _validatedDialogueEntries(manifest.dialogues)) {
      if (!occupiedPaths.add(entry.relativePath)) {
        throw const ProjectSnapshotException(
          'project.resource_path_conflict',
          'Two project resources resolve to the same storage path.',
        );
      }
      late final List<int> bytes;
      try {
        bytes = await _readRequiredDialogueSource(
          access,
          entry.relativePath,
        );
      } on ProjectSnapshotException catch (error) {
        if (policy != ProjectSnapshotLoadPolicy.editorReadProjection ||
            error.code != 'project.dialogue_source_missing') {
          rethrow;
        }
        loadDiagnostics.add(
          ProjectSnapshotLoadDiagnostic(
            code: error.code,
            resourceKind: 'dialogueSource',
            resourceId: entry.id,
          ),
        );
        continue;
      }
      resources.add(
        _LoadedProjectResource(
          relativePath: entry.relativePath,
          identity: dialogueSourceResourceIdentity(entry.id),
          bytes: bytes,
        ),
      );
    }
    final assetCatalogBytes = await _readOptional(
      access,
      assetCatalogStorageKey,
    );
    if (assetCatalogBytes != null) {
      final catalog = _decodeAssetCatalog(assetCatalogBytes);
      resources.add(
        _LoadedProjectResource(
          relativePath: assetCatalogStorageKey,
          identity: assetCatalogResourceIdentity,
          bytes: assetCatalogBytes,
        ),
      );
      final digests = catalog.records
          .map((record) => record.artifact)
          .toSet()
          .toList()
        ..sort((left, right) => left.digest.compareTo(right.digest));
      for (final artifact in digests) {
        final storageKey = assetBlobStorageKey(artifact);
        final bytes = await _readRequiredAssetBlob(access, storageKey);
        final inspected = ContentArtifactRef.fromBytes(
          bytes,
          mediaType: artifact.mediaType,
        );
        if (inspected.digest != artifact.digest ||
            inspected.byteLength != artifact.byteLength) {
          throw const ProjectSnapshotException(
            'project.asset_blob_mismatch',
            'An asset blob does not match its content-addressed catalog entry.',
          );
        }
        resources.add(
          _LoadedProjectResource(
            relativePath: storageKey,
            identity: assetBlobResourceIdentity(artifact.digest),
            bytes: bytes,
          ),
        );
      }
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
      resourceBytes: {
        for (final resource in resources) resource.identity: resource.bytes,
      },
      resourceStorageKeys: {
        for (final resource in resources)
          resource.identity: resource.relativePath,
      },
      loadDiagnostics: loadDiagnostics,
    );
  }
}

Future<List<int>> _readRequiredDialogueSource(
  ProjectWorkspaceAccess access,
  String relativePath,
) async {
  try {
    return await access.readBytes(relativePath);
  } on WorkspaceAccessException catch (error) {
    if (error.code == 'workspace.file_unavailable') {
      throw const ProjectSnapshotException(
        'project.dialogue_source_missing',
        'A dialogue manifest entry points to a missing source file.',
      );
    }
    rethrow;
  }
}

Future<List<int>?> _readOptional(
  ProjectWorkspaceAccess access,
  String relativePath,
) async {
  try {
    return await access.readBytes(relativePath);
  } on WorkspaceAccessException catch (error) {
    if (error.code == 'workspace.file_unavailable') return null;
    rethrow;
  }
}

Future<List<int>> _readRequiredAssetBlob(
  ProjectWorkspaceAccess access,
  String relativePath,
) async {
  try {
    return await access.readBytes(relativePath);
  } on WorkspaceAccessException catch (error) {
    if (error.code == 'workspace.file_unavailable') {
      throw const ProjectSnapshotException(
        'project.asset_blob_missing',
        'An asset catalog entry points to a missing blob.',
      );
    }
    rethrow;
  }
}

AssetCatalog _decodeAssetCatalog(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw const ProjectSnapshotException(
      'project.asset_catalog_invalid',
      'The project asset catalog is invalid.',
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

List<ProjectDialogueEntry> _validatedDialogueEntries(
  List<ProjectDialogueEntry> entries,
) {
  final seenIds = <String>{};
  final seenPaths = <String>{};
  final validated = <ProjectDialogueEntry>[];
  for (final entry in entries) {
    final id = entry.id.trim();
    if (id.isEmpty || id != entry.id) {
      throw const ProjectSnapshotException(
        'project.dialogue_id_invalid',
        'Every dialogue entry requires a trimmed identity.',
      );
    }
    if (!seenIds.add(id)) {
      throw const ProjectSnapshotException(
        'project.duplicate_dialogue_id',
        'Manifest dialogue identities must be unique.',
      );
    }
    final normalizedPath =
        validateProjectRelativePath(entry.relativePath).join('/');
    if (!seenPaths.add(normalizedPath)) {
      throw const ProjectSnapshotException(
        'project.duplicate_dialogue_path',
        'Manifest dialogue source paths must be unique.',
      );
    }
    validated.add(entry.copyWith(id: id, relativePath: normalizedPath));
  }
  validated.sort((left, right) {
    final path = left.relativePath.compareTo(right.relativePath);
    return path != 0 ? path : left.id.compareTo(right.id);
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
