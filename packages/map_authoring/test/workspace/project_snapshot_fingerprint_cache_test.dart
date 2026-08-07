import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
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
  });

  static Future<_Harness> create() async {
    final root = await Directory.systemTemp.createTemp('pokemap_fp_cache_');
    await Directory('${root.path}/maps').create(recursive: true);
    await File('${root.path}/project.json').writeAsString(_manifestJson);
    await File('${root.path}/maps/alpha.json').writeAsString(_mapJson('Alpha'));

    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final cache = ProjectSnapshotFingerprintCache();
    final loader = ProjectSnapshotLoader(
      handles: handles,
      fingerprintCache: cache,
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
    );
  }

  final Directory root;
  final ProjectSnapshotFingerprintCache cache;
  final ProjectSnapshotLoader loader;
  final ProjectHandle projectHandle;
  final WorkspaceHandle workspaceHandle;
  final WorkspaceHandleStore handles;
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

  void dispose() {
    handles.closeWorkspace(workspaceHandle);
    if (root.existsSync()) root.deleteSync(recursive: true);
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

const String _manifestJson = '''
{
  "name": "Fingerprint cache",
  "version": "v6",
  "maps": [{"id": "alpha", "name": "Alpha", "relativePath": "maps/alpha.json"}],
  "tilesets": []
}
''';

String _mapJson(String name) => '''
{
  "id": "alpha",
  "name": "$name",
  "version": "v6",
  "size": {"width": 1, "height": 1},
  "layers": []
}
''';
