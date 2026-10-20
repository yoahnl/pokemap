import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('binary descriptor metadata is bounded and clearable', () {
    final cache = ProjectSnapshotFingerprintCache(maximumIdentityEntries: 2);
    const descriptor = ProjectStoredResource(
        byteLength: 16,
        rawSha256: 'raw',
        resourceRevision: 'revision',
        contentDigest: 'digest');
    final identities = List.generate(
        3,
        (i) => ProjectResourceIdentity(
            scope: 'scope',
            relativePath: '$i',
            byteLength: 16,
            modifiedAtMicros: 1,
            changedAtMicros: 1));
    for (final identity in identities) {
      cache.storeBinaryResource(identity, descriptor);
    }
    expect(cache.storedBinaryResource(identities.first), isNull);
    expect(cache.storedBinaryResource(identities[1]), same(descriptor));
    expect(cache.storedBinaryResource(identities.last), same(descriptor));
    const noChangeTime = ProjectResourceIdentity(
        scope: 'scope',
        relativePath: 'none',
        byteLength: 16,
        modifiedAtMicros: 1);
    cache.storeBinaryResource(noChangeTime, descriptor);
    expect(cache.storedBinaryResource(noChangeTime), isNull);
    cache.clear();
    expect(cache.storedBinaryResource(identities.last), isNull);
  });

  test('JSON artifact descriptors never skip their byte observations',
      () async {
    final h = await _Harness.create();
    addTearDown(h.close);
    final bytes = utf8.encode('{"kind":"retainedJson"}');
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'application/json');
    await h.write('assets/document.json', bytes);
    await h.write(assetBlobStorageKey(artifact), bytes);
    await h.write(
        assetCatalogStorageKey,
        utf8.encode(jsonEncode(AssetCatalog(records: [
          AssetRecord(
              id: 'document',
              logicalPath: 'assets/document.json',
              artifact: artifact)
        ]).toJson())));
    await h.load();
    h.streams.clear();
    await h.load();
    expect(h.streams['assets/document.json'], 2);
    expect(h.streams[assetBlobStorageKey(artifact)], 2);
  });

  test('cold map creation and mutation never reread certified unchanged PNGs',
      () async {
    final h = await _Harness.create();
    addTearDown(h.close);
    final first = await h.load();
    h.streams.clear();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [h.root], fileReader: const LocalProjectFileReader());
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: h.loader);
    await api.attachProject(
        projectRootPath: h.root,
        workspaceHandle: h.workspace,
        projectHandle: h.project);
    addTearDown(() => api.detachWorkspace(h.workspace));
    final creation = await api.planMutation(
        h.project,
        AuthoringRequest(
            requestId: 'create',
            actionId: 'map.create',
            actionVersion: 1,
            workspaceHandle: h.workspace.value,
            expectedRevision: first.revision,
            idempotencyKey: 'create',
            parameters: {
              'mapId': 'second',
              'name': 'Second',
              'width': 2,
              'height': 2
            }));
    final created = await api.applyMutation(h.project,
        planId: creation.planId, operationId: 'create');
    expect(created.diagnostic, isNull);
    final afterCreate = await h.load();
    final update = await api.planMutation(
        h.project,
        AuthoringRequest(
            requestId: 'edit',
            actionId: 'map.save',
            actionVersion: 1,
            workspaceHandle: h.workspace.value,
            expectedRevision: afterCreate.revision,
            idempotencyKey: 'edit',
            parameters: {
              'map': afterCreate
                  .mapById('second')!
                  .copyWith(name: 'Edited')
                  .toJson()
            }));
    final edited = await api.applyMutation(h.project,
        planId: update.planId, operationId: 'edit');
    expect(edited.diagnostic, isNull);
    final warm = await h.load();
    expect(warm.mapById('second')!.name, 'Edited');
    expect(h.streams, isEmpty);
    expect(h.profiles.last.assetBlobVerifications, 0);
    final strict =
        await ProjectSnapshotLoader(handles: h.handles).load(h.project);
    expect(warm.revision, strict.revision);
    expect(warm.resourceFingerprints, strict.resourceFingerprints);
  }, skip: Platform.isWindows);

  test(
      'a binary rewrite preserving length and mtime but changing ctime is rejected',
      () async {
    final h = await _Harness.create();
    addTearDown(h.close);
    await h.load();
    h.streams.clear();
    await h.corrupt();
    await expectLater(
        h.load(),
        throwsA(isA<ProjectSnapshotException>()
            .having((e) => e.code, 'code', 'project.asset_source_mismatch')));
    expect(h.streams['assets/source.png'], greaterThan(0));
  }, skip: Platform.isWindows);

  for (final capability in [false, true]) {
    test(
        'virtual reader with real scope rehashes when ${capability ? 'ctime' : 'capability'} is absent',
        () async {
      final h = await _Harness.create(
          capability: capability, changeTime: !capability);
      addTearDown(h.close);
      await h.load();
      h.streams.clear();
      await h.load();
      expect(h.streams['assets/source.png'], 2);
      expect(h.streams[h.blob], 2);
    });
  }

  for (final observation in [2, 3, 4]) {
    test('cached binary change at observation $observation is refused',
        () async {
      final h = await _Harness.create();
      addTearDown(h.close);
      await h.load();
      var count = 0;
      h.beforeIdentity = (path) async {
        if (path == 'assets/source.png' && ++count == observation) {
          await h.corrupt();
        }
      };
      await expectLater(h.load(), throwsA(isA<ProjectSnapshotException>()));
    }, skip: Platform.isWindows);
  }

  test('cached descriptor still verifies changed artifact digest', () async {
    final h = await _Harness.create();
    addTearDown(h.close);
    await h.load();
    final changed = ContentArtifactRef.fromBytes([...h.png]..[20] ^= 1,
        mediaType: 'image/png');
    await h.write(
        assetCatalogStorageKey,
        utf8.encode(jsonEncode(AssetCatalog(records: [
          AssetRecord(
              id: 'source', logicalPath: 'assets/source.png', artifact: changed)
        ]).toJson())));
    await expectLater(
        h.load(),
        throwsA(isA<ProjectSnapshotException>()
            .having((e) => e.code, 'code', 'project.asset_source_mismatch')));
  }, skip: Platform.isWindows);

  test('descriptor generations never cross project scopes', () async {
    final cache = ProjectSnapshotFingerprintCache();
    final first = await _Harness.create(fingerprints: cache);
    final second = await _Harness.create(fingerprints: cache);
    addTearDown(first.close);
    addTearDown(second.close);
    await first.load();
    await second.load();
    expect(second.streams['assets/source.png'], 2);
    expect(second.streams[second.blob], 2);
  }, skip: Platform.isWindows);

  test('a symlink keeps strict binary reads even with a certified generation',
      () async {
    final h = await _Harness.create();
    addTearDown(h.close);
    await h.load();
    await File('${h.root}/assets/source.png')
        .rename('${h.root}/assets/retained.png');
    await Link('${h.root}/assets/source.png').create('retained.png');
    h.streams.clear();
    await h.load();
    expect(h.streams['assets/source.png'], 2);
    h.streams.clear();
    await h.load();
    expect(h.streams['assets/source.png'], 2);
  }, skip: Platform.isWindows);
}

final class _Harness {
  _Harness(this.root, this.png, this.blob);
  final String root;
  final List<int> png;
  final String blob;
  final handles = WorkspaceHandleStore();
  final streams = <String, int>{};
  final profiles = <ProjectSnapshotLoadProfile>[];
  Future<void> Function(String)? beforeIdentity;
  late final ProjectHandle project;
  late final WorkspaceHandle workspace;
  late final ProjectSnapshotLoader loader;

  static Future<_Harness> create(
      {bool capability = true,
      bool changeTime = true,
      ProjectSnapshotFingerprintCache? fingerprints}) async {
    final dir = await Directory.systemTemp.createTemp('cold-descriptor-');
    final root = await dir.resolveSymbolicLinks();
    final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWZkAAAAASUVORK5CYII=');
    final artifact = ContentArtifactRef.fromBytes(png, mediaType: 'image/png');
    final h = _Harness(root, png, assetBlobStorageKey(artifact));
    await h.write(
        'project.json',
        utf8.encode(jsonEncode(const ProjectManifest(
            name: 'Cold descriptor',
            maps: [
              ProjectMapEntry(
                  id: 'first', name: 'First', relativePath: 'maps/first.json')
            ],
            tilesets: []).toJson())));
    await h.write(
        'maps/first.json',
        utf8.encode(jsonEncode(const MapData(
                id: 'first',
                name: 'First',
                version: ProjectVersion.v8,
                size: GridSize(width: 2, height: 2))
            .toJson())));
    await h.write(
        assetCatalogStorageKey,
        utf8.encode(jsonEncode(AssetCatalog(records: [
          AssetRecord(
              id: 'source',
              logicalPath: 'assets/source.png',
              artifact: artifact)
        ]).toJson())));
    await h.write('assets/source.png', png);
    await h.write(h.blob, png);
    const reader = LocalProjectFileReader();
    final opened = h.handles.registerProject(
        projectName: 'Cold descriptor',
        initialFingerprint: 'initial',
        readBytes: (path) =>
            reader.readBytes(projectRoot: root, relativePath: path),
        openRead: (path) {
          h.streams.update(path, (value) => value + 1, ifAbsent: () => 1);
          return reader.openRead(projectRoot: root, relativePath: path);
        },
        readIdentity: (path) async {
          await h.beforeIdentity?.call(path);
          final identity =
              await reader.readIdentity(projectRoot: root, relativePath: path);
          if (identity == null || changeTime) return identity;
          return ProjectResourceIdentity(
              scope: identity.scope,
              relativePath: identity.relativePath,
              byteLength: identity.byteLength,
              modifiedAtMicros: identity.modifiedAtMicros);
        },
        canReuseSnapshots: capability);
    h.project = opened.projectHandle;
    h.workspace = opened.workspaceHandle;
    h.loader = ProjectSnapshotLoader(
        handles: h.handles,
        fingerprintCache: fingerprints ?? ProjectSnapshotFingerprintCache(),
        profileSink: h.profiles.add);
    return h;
  }

  Future<ProjectSnapshot> load() => loader.load(project);
  Future<void> write(String path, List<int> bytes) async {
    final file = File('$root/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  Future<void> corrupt() async {
    final file = File('$root/assets/source.png');
    final modified = await file.lastModified();
    await file.writeAsBytes([...png]..[20] ^= 1);
    await file.setLastModified(modified);
  }

  Future<void> close() async {
    handles.closeWorkspace(workspace);
    await Directory(root).delete(recursive: true);
  }
}
