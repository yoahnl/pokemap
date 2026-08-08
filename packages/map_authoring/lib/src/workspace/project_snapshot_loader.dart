import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import '../contracts/artifact_ref.dart';
import '../ports/project_file_reader.dart';
import '../domains/assets/asset_store.dart';
import '../domains/narrative/dialogue_source_store.dart';
import '../transactions/change_set.dart';
import 'project_snapshot.dart';
import 'project_snapshot_cache.dart';
import 'project_snapshot_fingerprint_cache.dart';
import 'workspace_handle_store.dart';

enum ProjectSnapshotLoadPolicy {
  strict,
  editorReadProjection,
}

typedef ProjectSnapshotLoadProfileSink = void Function(
  ProjectSnapshotLoadProfile profile,
);

typedef ProjectSnapshotDecodeWorkerRunner = Future<T> Function<T>(
  T Function() operation,
);

final class ProjectSnapshotDecodeDiagnostics {
  const ProjectSnapshotDecodeDiagnostics({
    required this.localOperations,
    required this.workerOperations,
    required this.workerFailures,
  });

  final int localOperations;
  final int workerOperations;
  final int workerFailures;
}

/// Thresholded executor for structured snapshot decoding.
///
/// Workspace authorization, file reads, double observation and snapshot
/// assembly remain on the caller isolate. Only pure UTF-8/JSON/model work is
/// eligible for an isolate worker.
final class ProjectSnapshotDecodeExecutor {
  ProjectSnapshotDecodeExecutor({
    this.offloadThresholdBytes = defaultOffloadThresholdBytes,
    ProjectSnapshotDecodeWorkerRunner? workerRunner,
  }) : _workerRunner = workerRunner ?? _runProjectSnapshotDecodeWorker {
    if (offloadThresholdBytes < 0) {
      throw ArgumentError.value(
        offloadThresholdBytes,
        'offloadThresholdBytes',
        'must not be negative',
      );
    }
  }

  static const int defaultOffloadThresholdBytes = 1024 * 1024;

  final int offloadThresholdBytes;
  final ProjectSnapshotDecodeWorkerRunner _workerRunner;

  var _localOperations = 0;
  var _workerOperations = 0;
  var _workerFailures = 0;

  ProjectSnapshotDecodeDiagnostics get diagnostics =>
      ProjectSnapshotDecodeDiagnostics(
        localOperations: _localOperations,
        workerOperations: _workerOperations,
        workerFailures: _workerFailures,
      );

  Future<ProjectManifest> decodeManifest(List<int> bytes) =>
      _execute(bytes, _decodeManifest);

  Future<MapData> decodeMap(List<int> bytes) => _execute(bytes, _decodeMap);

  Future<AssetCatalog> decodeAssetCatalog(List<int> bytes) =>
      _execute(bytes, _decodeAssetCatalog);

  Future<T> _execute<T>(
    List<int> bytes,
    T Function(List<int>) decode,
  ) async {
    if (bytes.length < offloadThresholdBytes) {
      _localOperations++;
      return decode(bytes);
    }
    final ownedBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    _workerOperations++;
    try {
      return await _workerRunner(() => decode(ownedBytes));
    } on Object {
      _workerFailures++;
      rethrow;
    }
  }
}

Future<T> _runProjectSnapshotDecodeWorker<T>(T Function() operation) =>
    Isolate.run(operation);

/// Timing and resource-volume observation for one successful snapshot load.
///
/// Profiling is opt-in through [ProjectSnapshotLoader.profileSink]. Without a
/// sink the loader does not create a profiler or any stage stopwatches.
final class ProjectSnapshotLoadProfile {
  const ProjectSnapshotLoadProfile({
    required this.initialReadMicroseconds,
    required this.decodeModelMicroseconds,
    required this.secondObservationMicroseconds,
    required this.fingerprintMicroseconds,
    required this.projectionMicroseconds,
    required this.totalMicroseconds,
    required this.resourceCount,
    required this.resourceBytes,
    this.cacheHit = false,
  });

  final int initialReadMicroseconds;
  final int decodeModelMicroseconds;
  final int secondObservationMicroseconds;
  final int fingerprintMicroseconds;
  final int projectionMicroseconds;
  final int totalMicroseconds;
  final int resourceCount;
  final int resourceBytes;
  final bool cacheHit;
}

/// Loads every manifest-declared map and external dialogue source twice to
/// reject mixed disk revisions.
///
/// The double read cannot make unrelated filesystem operations atomic, but it
/// ensures this API never claims a coherent snapshot after observing a change
/// in any resource that contributes to the returned revision.
final class ProjectSnapshotLoader {
  ProjectSnapshotLoader({
    required WorkspaceHandleStore handles,
    this.profileSink,
    this.maxConcurrentSecondObservations = 8,
    ProjectSnapshotDecodeExecutor? decodeExecutor,
    ProjectSnapshotFingerprintCache? fingerprintCache,
    ProjectSnapshotCache? snapshotCache,
  })  : assert(maxConcurrentSecondObservations > 0),
        _decodeExecutor = decodeExecutor ?? ProjectSnapshotDecodeExecutor(),
        _fingerprintCache = fingerprintCache,
        _snapshotCache = snapshotCache,
        _handles = handles;

  final WorkspaceHandleStore _handles;
  final ProjectSnapshotFingerprintCache? _fingerprintCache;
  final ProjectSnapshotCache? _snapshotCache;
  final ProjectSnapshotDecodeExecutor _decodeExecutor;
  final ProjectSnapshotLoadProfileSink? profileSink;
  final int maxConcurrentSecondObservations;

  void requireActiveProject(ProjectHandle projectHandle) {
    _handles.requireActiveProject(projectHandle);
  }

  Future<ProjectSnapshot?> adoptAppliedChanges(
    ProjectHandle projectHandle, {
    required String baseRevision,
    required Iterable<AuthoringResourceChange> changes,
  }) {
    final cache = _snapshotCache;
    if (cache == null) return Future.value();
    final access = _handles.resolveProject(projectHandle);
    return cache.adoptAppliedChanges(
      access,
      projectHandle,
      baseRevision: baseRevision,
      changes: changes,
    );
  }

  Future<ProjectSnapshot> load(
    ProjectHandle projectHandle, {
    ProjectSnapshotLoadPolicy policy = ProjectSnapshotLoadPolicy.strict,
  }) async {
    final profiler =
        profileSink == null ? null : _ProjectSnapshotLoadProfiler();
    final access = _handles.resolveProject(projectHandle);
    final cached = await _snapshotCache?.lookup(access, projectHandle);
    if (cached != null) {
      if (profiler != null) {
        profileSink!(
          profiler.finish(
            resourceCount: cached.resourceFingerprints.length,
            resourceBytes: cached.resourceByteLength,
            cacheHit: true,
          ),
        );
      }
      return cached;
    }
    final manifestReadTimer = profiler?.startStage();
    final manifestBytes = await access.readResourceBytes('project.json');
    profiler?.recordInitialRead(manifestReadTimer!);

    final manifestDecodeTimer = profiler?.startStage();
    final identityCachingEnabled =
        _fingerprintCache != null || _snapshotCache != null;
    final manifestIdentity = !identityCachingEnabled
        ? null
        : await access.readResourceIdentity('project.json');
    final manifest = (manifestIdentity == null
            ? null
            : _fingerprintCache?.decoded<ProjectManifest>(manifestIdentity)) ??
        await _decodeExecutor.decodeManifest(manifestBytes.bytes);
    if (manifestIdentity != null) {
      _fingerprintCache?.storeDecoded(manifestIdentity, manifest);
    }
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
    profiler?.recordDecodeModel(manifestDecodeTimer!);

    final identities = <String, ProjectResourceIdentity?>{
      'project.json': manifestIdentity,
    };
    final cache = _fingerprintCache;
    for (final entry in entries) {
      final mapReadTimer = profiler?.startStage();
      final bytes = await access.readResourceBytes(entry.relativePath);
      if (identityCachingEnabled) {
        identities[entry.relativePath] =
            await access.readResourceIdentity(entry.relativePath);
      }
      profiler?.recordInitialRead(mapReadTimer!);

      final mapDecodeTimer = profiler?.startStage();
      final mapIdentity = identities[entry.relativePath];
      final map =
          (mapIdentity == null ? null : cache?.decoded<MapData>(mapIdentity)) ??
              await _decodeExecutor.decodeMap(bytes.bytes);
      if (mapIdentity != null) cache?.storeDecoded(mapIdentity, map);
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
      profiler?.recordDecodeModel(mapDecodeTimer!);
    }

    final dialogueValidationTimer = profiler?.startStage();
    final occupiedPaths = <String>{
      for (final resource in resources) resource.relativePath,
    };
    final dialogueEntries = _validatedDialogueEntries(manifest.dialogues);
    profiler?.recordDecodeModel(dialogueValidationTimer!);

    for (final entry in dialogueEntries) {
      final dialoguePathTimer = profiler?.startStage();
      if (!occupiedPaths.add(entry.relativePath)) {
        throw const ProjectSnapshotException(
          'project.resource_path_conflict',
          'Two project resources resolve to the same storage path.',
        );
      }
      profiler?.recordDecodeModel(dialoguePathTimer!);

      late final ProjectResourceBytes bytes;
      try {
        final dialogueReadTimer = profiler?.startStage();
        try {
          bytes = await _readRequiredDialogueSource(
            access,
            entry.relativePath,
          );
        } finally {
          profiler?.recordInitialRead(dialogueReadTimer!);
        }
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

      final dialogueDecodeTimer = profiler?.startStage();
      resources.add(
        _LoadedProjectResource(
          relativePath: entry.relativePath,
          identity: dialogueSourceResourceIdentity(entry.id),
          bytes: bytes,
        ),
      );
      profiler?.recordDecodeModel(dialogueDecodeTimer!);
    }

    final assetCatalogReadTimer = profiler?.startStage();
    final assetCatalogBytes = await _readOptional(
      access,
      assetCatalogStorageKey,
    );
    profiler?.recordInitialRead(assetCatalogReadTimer!);
    if (assetCatalogBytes != null) {
      final assetCatalogDecodeTimer = profiler?.startStage();
      final catalog = await _decodeExecutor.decodeAssetCatalog(
        assetCatalogBytes.bytes,
      );
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
      profiler?.recordDecodeModel(assetCatalogDecodeTimer!);

      for (final artifact in digests) {
        final storageKey = assetBlobStorageKey(artifact);
        final assetBlobReadTimer = profiler?.startStage();
        final bytes = await _readRequiredAssetBlob(access, storageKey);
        profiler?.recordInitialRead(assetBlobReadTimer!);

        final assetBlobDecodeTimer = profiler?.startStage();
        final inspected = ContentArtifactRef.fromBytes(
          bytes.bytes,
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
        profiler?.recordDecodeModel(assetBlobDecodeTimer!);
      }
    }

    final resourceOrderingTimer = profiler?.startStage();
    resources.sort(
      (left, right) => left.relativePath.compareTo(right.relativePath),
    );
    profiler?.recordDecodeModel(resourceOrderingTimer!);

    final secondObservationTimer = profiler?.startStage();
    final matches = await _matchSecondObservations(
      access,
      resources,
    );
    for (var index = 0; index < resources.length; index += 1) {
      if (!matches[index]) {
        throw const ProjectSnapshotException(
          'project.changed_during_snapshot',
          'A project resource changed while the snapshot was loading.',
        );
      }
    }
    profiler?.recordSecondObservation(secondObservationTimer!);

    final fingerprintTimer = profiler?.startStage();
    // One stat() per resource is orders of magnitude cheaper than re-hashing
    // it. A null identity means the reader cannot report one, which simply
    // disables reuse for that resource. Map identities were already taken
    // while reading, so only the remaining resources are stat'ed here.
    if (identityCachingEnabled) {
      for (final resource in resources) {
        identities[resource.relativePath] ??=
            await access.readResourceIdentity(resource.relativePath);
      }
    }
    final identityKey = cache == null ||
            resources.any((r) => identities[r.relativePath] == null)
        ? null
        : resources
            .map(
              (r) => '${r.relativePath}:'
                  '${identities[r.relativePath]!.byteLength}:'
                  '${identities[r.relativePath]!.modifiedAtMicros}:'
                  '${identities[r.relativePath]!.changedAtMicros ?? -1}',
            )
            .join('|');

    String buildFingerprint(_LoadedProjectResource resource) =>
        (NarrativeProjectFingerprintBuilder()
              ..startEntry(
                relativePath: resource.relativePath,
                byteLength: resource.bytes.typedBytes.length,
              )
              ..addBytes(resource.bytes.typedBytes)
              ..endEntry())
            .close();

    var revision = identityKey == null ? null : cache!.revision(identityKey);
    if (revision == null) {
      final revisionBuilder = NarrativeProjectFingerprintBuilder();
      for (final resource in resources) {
        revisionBuilder
          ..startEntry(
            relativePath: resource.relativePath,
            byteLength: resource.bytes.typedBytes.length,
          )
          ..addBytes(resource.bytes.typedBytes)
          ..endEntry();
      }
      revision = revisionBuilder.close();
      if (identityKey != null) cache!.storeRevision(identityKey, revision);
    }

    final resourceFingerprints = <String, String>{};
    for (final resource in resources) {
      final identity = identities[resource.relativePath];
      final reused =
          identity == null ? null : cache?.resourceFingerprint(identity);
      final fingerprint = reused ?? buildFingerprint(resource);
      if (reused == null && identity != null) {
        cache?.storeResourceFingerprint(identity, fingerprint);
      }
      resourceFingerprints[resource.identity] = fingerprint;
    }
    profiler?.recordFingerprint(fingerprintTimer!);

    final projectionTimer = profiler?.startStage();
    final snapshot = ProjectSnapshot(
      projectHandle: projectHandle,
      revision: revision,
      manifest: manifest,
      maps: maps,
      resourceFingerprints: resourceFingerprints,
      ownedResourceBytes: {
        for (final resource in resources) resource.identity: resource.bytes,
      },
      resourceStorageKeys: {
        for (final resource in resources)
          resource.identity: resource.relativePath,
      },
      loadDiagnostics: loadDiagnostics,
    );
    final completeIdentities = <String, ProjectResourceIdentity>{};
    for (final resource in resources) {
      final identity = identities[resource.relativePath];
      if (identity == null) {
        completeIdentities.clear();
        break;
      }
      completeIdentities[resource.relativePath] = identity;
    }
    if (completeIdentities.isNotEmpty) {
      _snapshotCache?.store(
        snapshot: snapshot,
        identities: completeIdentities,
        absentResourcePaths: assetCatalogBytes == null
            ? const [assetCatalogStorageKey]
            : const [],
      );
    }
    profiler?.recordProjection(projectionTimer!);

    if (profiler != null) {
      profileSink!(
        profiler.finish(
          resourceCount: resources.length,
          resourceBytes: resources.fold<int>(
            0,
            (total, resource) => total + resource.bytes.typedBytes.length,
          ),
        ),
      );
    }
    return snapshot;
  }

  Future<List<bool>> _matchSecondObservations(
    ProjectWorkspaceAccess access,
    List<_LoadedProjectResource> resources,
  ) async {
    final matches = List<bool>.filled(resources.length, false);
    var nextIndex = 0;

    Future<void> observeNext() async {
      while (true) {
        final index = nextIndex;
        if (index >= resources.length) return;
        nextIndex = index + 1;
        final resource = resources[index];
        matches[index] = await access.matchesResourceBytes(
          resource.relativePath,
          resource.bytes.typedBytes,
        );
      }
    }

    final workerCount = resources.length < maxConcurrentSecondObservations
        ? resources.length
        : maxConcurrentSecondObservations;
    await Future.wait<void>(
      List<Future<void>>.generate(workerCount, (_) => observeNext()),
    );
    return matches;
  }
}

Future<ProjectResourceBytes> _readRequiredDialogueSource(
  ProjectWorkspaceAccess access,
  String relativePath,
) async {
  try {
    return await access.readResourceBytes(relativePath);
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

Future<ProjectResourceBytes?> _readOptional(
  ProjectWorkspaceAccess access,
  String relativePath,
) async {
  try {
    return await access.readResourceBytes(relativePath);
  } on WorkspaceAccessException catch (error) {
    if (error.code == 'workspace.file_unavailable') return null;
    rethrow;
  }
}

Future<ProjectResourceBytes> _readRequiredAssetBlob(
  ProjectWorkspaceAccess access,
  String relativePath,
) async {
  try {
    return await access.readResourceBytes(relativePath);
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

final class _LoadedProjectResource {
  const _LoadedProjectResource({
    required this.relativePath,
    required this.identity,
    required this.bytes,
  });

  final String relativePath;
  final String identity;
  final ProjectResourceBytes bytes;
}

final class _ProjectSnapshotLoadProfiler {
  _ProjectSnapshotLoadProfiler() : _total = Stopwatch()..start();

  final Stopwatch _total;
  var _initialReadMicroseconds = 0;
  var _decodeModelMicroseconds = 0;
  var _secondObservationMicroseconds = 0;
  var _fingerprintMicroseconds = 0;
  var _projectionMicroseconds = 0;

  Stopwatch startStage() => Stopwatch()..start();

  void recordInitialRead(Stopwatch stopwatch) {
    _initialReadMicroseconds += _stop(stopwatch);
  }

  void recordDecodeModel(Stopwatch stopwatch) {
    _decodeModelMicroseconds += _stop(stopwatch);
  }

  void recordSecondObservation(Stopwatch stopwatch) {
    _secondObservationMicroseconds += _stop(stopwatch);
  }

  void recordFingerprint(Stopwatch stopwatch) {
    _fingerprintMicroseconds += _stop(stopwatch);
  }

  void recordProjection(Stopwatch stopwatch) {
    _projectionMicroseconds += _stop(stopwatch);
  }

  ProjectSnapshotLoadProfile finish({
    required int resourceCount,
    required int resourceBytes,
    bool cacheHit = false,
  }) {
    _total.stop();
    return ProjectSnapshotLoadProfile(
      initialReadMicroseconds: _initialReadMicroseconds,
      decodeModelMicroseconds: _decodeModelMicroseconds,
      secondObservationMicroseconds: _secondObservationMicroseconds,
      fingerprintMicroseconds: _fingerprintMicroseconds,
      projectionMicroseconds: _projectionMicroseconds,
      totalMicroseconds: _total.elapsedMicroseconds,
      resourceCount: resourceCount,
      resourceBytes: resourceBytes,
      cacheHit: cacheHit,
    );
  }
}

int _stop(Stopwatch stopwatch) {
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds;
}
