import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('certified stored assets are not streamed again on canonical cache hits',
      () async {
    final harness = await _StoredAssetHarness.create();
    addTearDown(harness.dispose);
    final first = await harness.load();
    expect(first.storedResources.length, 2);
    harness.streamReads = 0;
    final second = await harness.load();
    expect(second.revision, first.revision);
    expect(second.resourceFingerprints, first.resourceFingerprints);
    expect(harness.cache.canonicalHits, 1);
    expect(harness.streamReads, 0);
    expect(await second.readResourceBytes('asset:source'), harness.bytes);
  }, skip: Platform.isWindows);

  test('map adoption preserves certified assets without streaming them',
      () async {
    final harness = await _StoredAssetHarness.create();
    addTearDown(harness.dispose);
    final first = await harness.load();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [harness.root],
        fileReader: const LocalProjectFileReader());
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: harness.loader);
    await mutations.attachProject(
        projectRootPath: harness.root,
        workspaceHandle: harness.workspace,
        projectHandle: harness.project);
    addTearDown(() => mutations.detachWorkspace(harness.workspace));
    harness.streamReads = 0;
    final plan = await mutations.planMutation(
        harness.project,
        AuthoringRequest(
            requestId: 'rename-map',
            actionId: 'map.save',
            actionVersion: 1,
            workspaceHandle: harness.workspace.value,
            expectedRevision: first.revision,
            idempotencyKey: 'rename-map',
            parameters: {
              'map': first.maps.single.copyWith(name: 'Edited').toJson()
            }));
    final applied = await mutations.applyMutation(harness.project,
        planId: plan.planId, operationId: 'rename-map');
    expect(applied.diagnostic, isNull);
    expect(harness.cache.adoptions, 1);
    expect(harness.streamReads, 0);
    final warm = await harness.load();
    expect(warm.maps.single.name, 'Edited');
    expect(harness.streamReads, 0);
    final cold = await ProjectSnapshotLoader(handles: harness.handles)
        .load(harness.project);
    expect(warm.revision, cold.revision);
    expect(warm.resourceFingerprints, cold.resourceFingerprints);
  }, skip: Platform.isWindows);

  test('stored asset changes between identity passes invalidate the cache',
      () async {
    final harness = await _StoredAssetHarness.create();
    addTearDown(harness.dispose);
    await harness.load();
    var observations = 0;
    harness.beforeIdentityRead = (path) async {
      if (path != 'assets/source.bin' || ++observations != 2) return;
      final file = File('${harness.root}/$path');
      final modified = await file.lastModified();
      await file.writeAsBytes([...harness.bytes]..[19] ^= 1);
      await file.setLastModified(modified);
    };
    await expectLater(harness.load(), throwsA(isA<ProjectSnapshotException>()));
    expect(harness.cache.canonicalHits, 0);
    expect(harness.cache.invalidations, greaterThan(0));
  }, skip: Platform.isWindows);

  test('cold certification cannot be stored under a later file generation',
      () async {
    final harness = await _StoredAssetHarness.create();
    addTearDown(harness.dispose);
    var observations = 0;
    harness.beforeIdentityRead = (path) async {
      if (path != 'assets/source.bin' || ++observations != 3) return;
      final file = File('${harness.root}/$path');
      final modified = await file.lastModified();
      await file.writeAsBytes([...harness.bytes]..[23] ^= 1);
      await file.setLastModified(modified);
    };
    await expectLater(harness.load(), throwsA(isA<ProjectSnapshotException>()));
    expect(harness.cache.projectCount, 0);
  }, skip: Platform.isWindows);

  test('stored assets without change time retain strict streaming checks',
      () async {
    final harness = await _StoredAssetHarness.create(includeChangedAt: false);
    addTearDown(harness.dispose);
    await harness.load();
    harness.streamReads = 0;
    await harness.load();
    expect(harness.streamReads, 4);
    final file = File('${harness.root}/assets/source.bin');
    final modified = await file.lastModified();
    await file.writeAsBytes([...harness.bytes]..[29] ^= 1);
    await file.setLastModified(modified);
    await expectLater(harness.load(), throwsA(isA<ProjectSnapshotException>()));
  });

  for (final blob in [false, true]) {
    for (final remove in [false, true]) {
      test(
          'canonical cache rejects ${remove ? 'missing' : 'rewritten with restored mtime'} ${blob ? 'blob' : 'logical source'}',
          () async {
        final harness = await _StoredAssetHarness.create();
        addTearDown(harness.dispose);
        await harness.load();
        final file = File(
            '${harness.root}/${blob ? harness.blobPath : 'assets/source.bin'}');
        final modified = await file.lastModified();
        if (remove) {
          await file.delete();
        } else {
          await file.writeAsBytes([...harness.bytes]..[17] ^= 1);
          await file.setLastModified(modified);
        }
        if (remove && !blob) {
          final snapshot = await harness.load();
          expect(snapshot.hasResource('asset:source'), isFalse);
          expect(harness.cache.invalidations, greaterThan(0));
        } else {
          await expectLater(
              harness.load(), throwsA(isA<ProjectSnapshotException>()));
        }
        expect(harness.cache.canonicalHits, 0);
      });
    }
  }
}

final class _StoredAssetHarness {
  _StoredAssetHarness(this.root, this.bytes, this.blobPath);

  final String root;
  final List<int> bytes;
  final String blobPath;
  final handles = WorkspaceHandleStore();
  final cache = ProjectSnapshotCache();
  late final ProjectSnapshotLoader loader;
  late final ProjectHandle project;
  late final WorkspaceHandle workspace;
  var streamReads = 0;
  Future<void> Function(String)? beforeIdentityRead;

  static Future<_StoredAssetHarness> create(
      {bool includeChangedAt = true}) async {
    final directory = await Directory.systemTemp.createTemp('stored-cache-');
    final root = await directory.resolveSymbolicLinks();
    final bytes = List<int>.generate(128 * 1024 + 7, (i) => i % 251);
    final artifact = ContentArtifactRef.fromBytes(bytes,
        mediaType: 'application/octet-stream');
    final blobPath = assetBlobStorageKey(artifact);
    for (final entry in {
      'project.json': utf8.encode(jsonEncode(
          const ProjectManifest(name: 'Stored cache', maps: [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ], tilesets: []).toJson())),
      'maps/map.json': utf8.encode(jsonEncode(const MapData(
              id: 'map',
              name: 'Map',
              version: ProjectVersion.v8,
              size: GridSize(width: 2, height: 2))
          .toJson())),
      assetCatalogStorageKey: utf8.encode(jsonEncode(AssetCatalog(records: [
        AssetRecord(
            id: 'source', logicalPath: 'assets/source.bin', artifact: artifact)
      ]).toJson())),
      blobPath: bytes,
      'assets/source.bin': bytes,
    }.entries) {
      final file = File('$root/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final harness = _StoredAssetHarness(root, bytes, blobPath);
    const reader = LocalProjectFileReader();
    final opened = harness.handles.registerProject(
        projectName: 'Stored cache',
        initialFingerprint: 'initial',
        readBytes: (path) =>
            reader.readBytes(projectRoot: root, relativePath: path),
        openRead: (path) {
          harness.streamReads++;
          return reader.openRead(projectRoot: root, relativePath: path);
        },
        readIdentity: (path) async {
          await harness.beforeIdentityRead?.call(path);
          final identity =
              await reader.readIdentity(projectRoot: root, relativePath: path);
          if (identity == null || includeChangedAt) return identity;
          return ProjectResourceIdentity(
              scope: identity.scope,
              relativePath: identity.relativePath,
              byteLength: identity.byteLength,
              modifiedAtMicros: identity.modifiedAtMicros);
        },
        canReuseSnapshots: true);
    harness.project = opened.projectHandle;
    harness.workspace = opened.workspaceHandle;
    harness.loader = ProjectSnapshotLoader(
        handles: harness.handles, snapshotCache: harness.cache);
    return harness;
  }

  Future<ProjectSnapshot> load() => loader.load(project);

  Future<void> dispose() async {
    handles.closeWorkspace(workspace);
    await Directory(root).delete(recursive: true);
  }
}
