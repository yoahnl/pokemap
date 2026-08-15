import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// The fingerprint cache may only ever skip work that would have produced the
/// same answer. These pin the three properties that make it safe to ship:
/// unchanged resources are not re-hashed, a changed file invalidates, and the
/// double-read consistency check still rejects a mid-load write.
void main() {
  group('snapshot fingerprint cache', () {
    test('reuses fingerprints while nothing on disk changed', () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);

      final first = await harness.load();
      final hitsAfterFirst = harness.cache.hits;
      final second = await harness.load();

      expect(first.revision, second.revision);
      expect(
        harness.cache.hits,
        greaterThan(hitsAfterFirst),
        reason: 'the second load must reuse fingerprints, not recompute them',
      );
      expect(
        second.resourceFingerprints,
        equals(first.resourceFingerprints),
        reason: 'reused fingerprints must equal the computed ones',
      );
    });

    test('warm load reuses the complete snapshot without reading payloads',
        () async {
      final harness = await _Harness.create(enableSnapshotCache: true);
      addTearDown(harness.dispose);

      final first = await harness.load();
      harness.reader.resetCounts();

      final second = await harness.load();

      expect(second.revision, first.revision);
      expect(harness.reader.byteReads, 0);
      expect(harness.reader.identityReads, greaterThan(0));
      expect(harness.snapshotCache!.hits, 1);
    });

    test('session reuse performs no filesystem identity observations',
        () async {
      final harness = await _Harness.create(enableSnapshotCache: true);
      addTearDown(harness.dispose);
      final first = await harness.load();
      harness.reader.resetCounts();

      final second = await harness.loader.load(
        harness.projectHandle,
        cacheValidation: ProjectSnapshotCacheValidation.session,
      );

      expect(second.revision, first.revision);
      expect(harness.reader.byteReads, 0);
      expect(harness.reader.identityReads, 0);
      expect(harness.snapshotCache!.sessionHits, 1);
      expect(harness.snapshotCache!.identityReads, greaterThan(0));
    });

    test('canonical lookup detects changes hidden from the session snapshot',
        () async {
      final harness = await _Harness.create(enableSnapshotCache: true);
      addTearDown(harness.dispose);
      final before = await harness.load();
      final firstSessionRevision = harness.snapshotCache!.sessionRevisionFor(
        harness.projectHandle,
      );
      await harness.rewriteMap(name: 'External');
      harness.reader.resetCounts();

      final session = await harness.loader.load(
        harness.projectHandle,
        cacheValidation: ProjectSnapshotCacheValidation.session,
      );
      expect(session.revision, before.revision);
      expect(harness.reader.identityReads, 0);

      final canonical = await harness.load();
      expect(canonical.revision, isNot(before.revision));
      expect(canonical.mapById('alpha')!.name, 'External');
      expect(harness.snapshotCache!.invalidations, greaterThan(0));
      expect(
        harness.snapshotCache!.sessionRevisionFor(harness.projectHandle),
        greaterThan(firstSessionRevision!),
      );
    });

    test('canonical reuse binds the cache to the renewed project handle',
        () async {
      final harness = await _Harness.create(enableSnapshotCache: true);
      addTearDown(harness.dispose);
      final before = await harness.load();
      final renewedHandle = await harness.registerAdditionalHandle();

      final rebound = await harness.loader.load(renewedHandle);
      expect(rebound.revision, before.revision);
      harness.reader.resetCounts();

      final session = await harness.loader.load(
        renewedHandle,
        cacheValidation: ProjectSnapshotCacheValidation.session,
      );
      expect(session.revision, before.revision);
      expect(harness.reader.byteReads, 0);
      expect(harness.reader.identityReads, 0);

      final originalSession = await harness.loader.load(
        harness.projectHandle,
        cacheValidation: ProjectSnapshotCacheValidation.session,
      );
      expect(originalSession.revision, before.revision);
      expect(harness.reader.byteReads, 0);
      expect(harness.reader.identityReads, 0);
    });

    test('adopts a committed map post-image without a strict reload', () async {
      final harness = await _Harness.create(enableSnapshotCache: true);
      addTearDown(harness.dispose);
      final before = await harness.load();
      final beforeSessionRevision = harness.snapshotCache!.sessionRevisionFor(
        harness.projectHandle,
      );
      final beforeBytes = before.resourceBytes('map:alpha');
      final afterBytes = _mapJson('Committed').codeUnits;
      await harness.rewriteMap(name: 'Committed');
      harness.reader.resetCounts();

      final projected = await harness.loader.adoptAppliedChanges(
        harness.projectHandle,
        baseRevision: before.revision,
        changes: [
          AuthoringResourceChange(
            resource: AuthoringResourceRef(
              kind: 'map',
              id: 'alpha',
              revision: before.resourceFingerprints['map:alpha'],
            ),
            storageKey: 'maps/alpha.json',
            beforeBytes: beforeBytes,
            afterBytes: afterBytes,
          ),
        ],
      );

      expect(projected, isNotNull);
      expect(projected!.mapById('alpha')!.name, 'Committed');
      expect(harness.reader.byteReads, 1);
      harness.reader.resetCounts();
      final warm = await harness.load();
      expect(warm.revision, projected.revision);
      expect(harness.reader.byteReads, 0);
      final strict = await harness.loadStrictFresh();
      expect(projected.revision, strict.revision);
      expect(projected.resourceFingerprints, strict.resourceFingerprints);
      expect(harness.snapshotCache!.canonicalHits, greaterThan(0));
      expect(
        harness.snapshotCache!.sessionRevisionFor(harness.projectHandle),
        greaterThan(beforeSessionRevision!),
      );
    });

    test('refuses projection when committed bytes were replaced externally',
        () async {
      final harness = await _Harness.create(enableSnapshotCache: true);
      addTearDown(harness.dispose);
      final before = await harness.load();
      final beforeBytes = before.resourceBytes('map:alpha');
      final committedBytes = _mapJson('Committed').codeUnits;
      await harness.rewriteMap(name: 'External replacement');

      final projected = await harness.loader.adoptAppliedChanges(
        harness.projectHandle,
        baseRevision: before.revision,
        changes: [
          AuthoringResourceChange(
            resource: AuthoringResourceRef(
              kind: 'map',
              id: 'alpha',
              revision: before.resourceFingerprints['map:alpha'],
            ),
            storageKey: 'maps/alpha.json',
            beforeBytes: beforeBytes,
            afterBytes: committedBytes,
          ),
        ],
      );

      expect(projected, isNull);
      final strict = await harness.load();
      expect(strict.mapById('alpha')!.name, 'External replacement');
    });

    test('recomputes after a resource changes on disk', () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);

      final before = await harness.load();
      await harness.rewriteMap(name: 'Renamed');
      final after = await harness.load();

      expect(
        after.revision,
        isNot(before.revision),
        reason: 'a changed file must produce a new revision',
      );
      final identity = 'map:alpha';
      expect(
        after.resourceFingerprints[identity],
        isNot(before.resourceFingerprints[identity]),
      );
    });

    test('complete cache falls back to strict bytes after an external change',
        () async {
      final harness = await _Harness.create(enableSnapshotCache: true);
      addTearDown(harness.dispose);
      final before = await harness.load();
      await harness.rewriteMap(name: 'External');
      harness.reader.resetCounts();

      final after = await harness.load();

      expect(after.revision, isNot(before.revision));
      expect(after.mapById('alpha')!.name, 'External');
      expect(harness.reader.byteReads, greaterThan(0));
    });

    test('appearance of the optional asset catalog invalidates warm reuse',
        () async {
      final harness = await _Harness.create(enableSnapshotCache: true);
      addTearDown(harness.dispose);
      final before = await harness.load();
      await harness.writeEmptyAssetCatalog();
      harness.reader.resetCounts();

      final after = await harness.load();

      expect(after.revision, isNot(before.revision));
      expect(
        after.resourceFingerprints,
        contains(assetCatalogResourceIdentity),
      );
      expect(harness.reader.byteReads, greaterThan(0));
    });

    test('still rejects a mid-load change even when identity looks stable',
        () async {
      // Worst case for the cache: the reader swears the file never changed
      // while its bytes flip between the two observations. The double read,
      // not the identity, is what guarantees a coherent snapshot.
      final reader = _LyingIdentityReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: const <String>['/project'],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final loader = ProjectSnapshotLoader(
        handles: handles,
        fingerprintCache: ProjectSnapshotFingerprintCache(),
      );
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject('/project');

      await expectLater(
        loader.load(opened.projectHandle),
        throwsA(
          isA<ProjectSnapshotException>().having(
            (error) => error.code,
            'code',
            'project.changed_during_snapshot',
          ),
        ),
      );
    });
  });
}

final class _Harness {
  _Harness._({
    required this.root,
    required this.cache,
    required this.loader,
    required this.projectHandle,
    required this.workspaceHandle,
    required this.handles,
    required this.reader,
    required this.snapshotCache,
  });

  static Future<_Harness> create({bool enableSnapshotCache = false}) async {
    final root = await Directory.systemTemp.createTemp('pokemap_fp_cache_');
    await Directory('${root.path}/maps').create(recursive: true);
    await File('${root.path}/project.json').writeAsString(_manifestJson);
    await File('${root.path}/maps/alpha.json').writeAsString(_mapJson('Alpha'));

    final reader = _CountingIdentityReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final cache = ProjectSnapshotFingerprintCache();
    final snapshotCache = enableSnapshotCache ? ProjectSnapshotCache() : null;
    final loader = ProjectSnapshotLoader(
      handles: handles,
      fingerprintCache: cache,
      snapshotCache: snapshotCache,
    );
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(root.path);

    return _Harness._(
      root: root,
      cache: cache,
      loader: loader,
      projectHandle: opened.projectHandle,
      workspaceHandle: opened.workspaceHandle,
      handles: handles,
      reader: reader,
      snapshotCache: snapshotCache,
    );
  }

  final Directory root;
  final ProjectSnapshotFingerprintCache cache;
  final ProjectSnapshotLoader loader;
  final ProjectHandle projectHandle;
  final WorkspaceHandle workspaceHandle;
  final WorkspaceHandleStore handles;
  final _CountingIdentityReader reader;
  final ProjectSnapshotCache? snapshotCache;
  final List<WorkspaceHandle> _additionalWorkspaces = [];
  Future<void> Function()? onSecondObservation;

  Future<ProjectSnapshot> load() async {
    final pending = onSecondObservation;
    onSecondObservation = null;
    if (pending != null) {
      // Fire the rewrite while the load is in flight.
      final future = loader.load(projectHandle);
      await pending();
      return future;
    }
    return loader.load(projectHandle);
  }

  Future<void> rewriteMap({required String name}) async {
    final file = File('${root.path}/maps/alpha.json');
    await file.writeAsString(_mapJson(name));
    // Guarantee a distinct mtime even on a coarse clock.
    await file.setLastModified(DateTime.now().add(const Duration(seconds: 2)));
  }

  Future<void> writeEmptyAssetCatalog() async {
    final file = File('${root.path}/$assetCatalogStorageKey');
    await file.parent.create(recursive: true);
    await file.writeAsString('{"schemaVersion":1,"records":[]}');
  }

  Future<ProjectSnapshot> loadStrictFresh() async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final freshHandles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: freshHandles,
    ).openProject(root.path);
    try {
      return await ProjectSnapshotLoader(handles: freshHandles).load(
        opened.projectHandle,
      );
    } finally {
      freshHandles.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<ProjectHandle> registerAdditionalHandle() async {
    final canonicalRoot = await reader.canonicalizeDirectory(root.path);
    final registered = handles.registerProject(
      projectName: 'Fingerprint cache',
      initialFingerprint: 'renewed',
      readBytes: (relativePath) => reader.readBytes(
        projectRoot: canonicalRoot,
        relativePath: relativePath,
      ),
      readIdentity: (relativePath) => reader.readIdentity(
        projectRoot: canonicalRoot,
        relativePath: relativePath,
      ),
      canReuseSnapshots: true,
    );
    _additionalWorkspaces.add(registered.workspaceHandle);
    return registered.projectHandle;
  }

  void dispose() {
    for (final workspace in _additionalWorkspaces) {
      handles.closeWorkspace(workspace);
    }
    handles.closeWorkspace(workspaceHandle);
    if (root.existsSync()) root.deleteSync(recursive: true);
  }
}

final class _CountingIdentityReader
    implements
        ProjectFileReader,
        ProjectResourceIdentityReader,
        ProjectSnapshotCacheIdentityReader {
  final LocalProjectFileReader _delegate = const LocalProjectFileReader();
  var byteReads = 0;
  var identityReads = 0;

  void resetCounts() {
    byteReads = 0;
    identityReads = 0;
  }

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  }) {
    identityReads += 1;
    return _delegate.readIdentity(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    byteReads += 1;
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

/// Reports one unchanging identity while serving different bytes on the second
/// read of the map, so the cache is fully armed when the change happens.
final class _LyingIdentityReader
    implements ProjectFileReader, ProjectResourceIdentityReader {
  int _mapReads = 0;

  @override
  Future<String> canonicalizeDirectory(String path) async => path;

  @override
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  }) async =>
      ProjectResourceIdentity(
        scope: projectRoot,
        relativePath: relativePath,
        byteLength: 1,
        modifiedAtMicros: 1,
      );

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    if (relativePath == 'project.json') return _manifestJson.codeUnits;
    if (relativePath != 'maps/alpha.json') {
      throw const WorkspaceAccessException(
        'workspace.file_unavailable',
        'Only the manifest and the single map exist in this fixture.',
      );
    }
    _mapReads += 1;
    return _mapJson(_mapReads > 1 ? 'Changed mid-load' : 'Alpha').codeUnits;
  }
}

final String _manifestJson = jsonEncode({
  'name': 'Fingerprint cache',
  'version': 'v6',
  'pokemon': ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
  ).toJson(),
  'maps': [
    {'id': 'alpha', 'name': 'Alpha', 'relativePath': 'maps/alpha.json'},
  ],
  'tilesets': <Object?>[],
});

String _mapJson(String name) => '''
{
  "id": "alpha",
  "name": "$name",
  "version": "v6",
  "size": {"width": 1, "height": 1},
  "layers": []
}
''';
