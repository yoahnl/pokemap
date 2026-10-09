import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/glb_fixture.dart';

void main() {
  test('verified model paths retain immutable shared blob buffers', () async {
    final f = _Fixture.create();
    addTearDown(f.dispose);
    final snapshot = await f.load();
    final shared = snapshot.resourceBytes(f.blobIdentities.first);

    expect(snapshot.resourceBytes('assetLogical:model3d_house'), same(shared));
    expect(snapshot.resourceBytes('assetLogical:model3d_tree'), same(shared));
    expect(snapshot.resourceBytes('assetLogical:model3d_other'),
        isNot(same(shared)));
    expect(() => shared[0] = 0, throwsUnsupportedError);
    expect(() => snapshot.resourceBytes('assetLogical:model3d_house')[0] = 0,
        throwsUnsupportedError);
    expect(snapshot.resourceBytes('assetLogical:model3d_house'), f.modelBytes);
    expect(
        snapshot.resourceFingerprints.keys, hasLength(f.reader.files.length));
    for (final entry in snapshot.resourceStorageKeys.entries) {
      expect(
          snapshot.resourceFingerprints[entry.key],
          computeNarrativeProjectFingerprint([
            NarrativeProjectFingerprintEntry(
                relativePath: entry.value, bytes: f.reader.files[entry.value]!)
          ]));
      expect(snapshot.resourceBytes(entry.key), f.reader.files[entry.value]);
      expect(f.reader.reads[entry.value], 2);
    }
    expect(snapshot.resourceFingerprints['assetLogical:model3d_house'],
        isNot(snapshot.resourceFingerprints[f.blobIdentities.first]));
    final ordered = snapshot.resourceStorageKeys.entries.toList()
      ..sort((left, right) => left.value.compareTo(right.value));
    expect(
        snapshot.revision,
        computeNarrativeProjectFingerprint([
          for (final entry in ordered)
            NarrativeProjectFingerprintEntry(
                relativePath: entry.value,
                bytes: utf8.encode(snapshot.resourceFingerprints[entry.key]!))
        ]));
  });

  test('cache counts shared model buffers once without raising either budget',
      () async {
    final f = _Fixture.create(boundedCache: true);
    addTearDown(f.dispose);
    final first = await f.load();

    expect(f.cache.projectCount, 1);
    expect(f.cache.storedAuthoringBytes, f.authoringBytes);
    expect(f.cache.storedAssetBlobBytes, f.blobBytes);
    expect(f.cache.authoringBudgetRejections, 0);
    f.reader.resetCounts();
    final second = await f.load();
    expect(second.revision, first.revision);
    expect(f.cache.canonicalHits, 1);
    expect(f.reader.reads, isEmpty);
    expect(f.reader.identityReads, greaterThan(0));
  });

  for (final path in ['assets/models3d/house.glb', 'blob']) {
    for (final changeLength in [false, true]) {
      test('rejects corrupt $path with changed length $changeLength', () async {
        final f = _Fixture.create();
        addTearDown(f.dispose);
        final target = path == 'blob' ? f.blobPaths.first : path;
        final bytes = [...f.reader.files[target]!];
        if (changeLength) {
          bytes.add(0);
        } else {
          bytes[bytes.length - 1] ^= 1;
        }
        f.reader.replace(target, bytes);
        await expectLater(
            f.load(),
            throwsA(isA<ProjectSnapshotException>().having(
                (error) => error.code,
                'code',
                path == 'blob'
                    ? 'project.asset_blob_mismatch'
                    : 'project.model3d_source_mismatch')));
        expect(f.cache.projectCount, 0);
      });
    }
  }

  for (final path in ['assets/models3d/house.glb', 'blob']) {
    test('rejects a concurrent change at the second $path observation',
        () async {
      final f = _Fixture.create();
      addTearDown(f.dispose);
      final target = path == 'blob' ? f.blobPaths.first : path;
      f.reader.onRead = (relativePath, count, bytes) =>
          relativePath == target && count == 2
              ? ([...bytes]..[bytes.length - 1] ^= 1)
              : bytes;
      await expectLater(
          f.load(),
          throwsA(isA<ProjectSnapshotException>().having((error) => error.code,
              'code', 'project.changed_during_snapshot')));
      expect(f.cache.projectCount, 0);
    });
  }

  test('a changed logical path invalidates canonical reuse before validation',
      () async {
    final f = _Fixture.create();
    addTearDown(f.dispose);
    await f.load();
    f.reader.replace('assets/models3d/house.glb',
        [...f.modelBytes]..[f.modelBytes.length - 1] ^= 1);
    await expectLater(
        f.load(),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.model3d_source_mismatch')));
    expect(f.cache.invalidations, 1);
    expect(f.cache.canonicalHits, 0);
    expect(f.cache.projectCount, 0);
  });

  test('map adoption retains aliases, exact budgets and the canonical revision',
      () async {
    final f = _Fixture.create(boundedCache: true);
    addTearDown(f.dispose);
    final before = await f.load();
    final afterBytes = utf8.encode(jsonEncode(
        before.mapById('alpha')!.copyWith(name: 'Renamed').toJson()));
    f.reader.replace('maps/alpha.json', afterBytes);
    final adopted = await f.loader.adoptAppliedChanges(f.project,
        baseRevision: before.revision,
        changes: [
          AuthoringResourceChange(
              resource: AuthoringResourceRef(kind: 'map', id: 'alpha'),
              storageKey: 'maps/alpha.json',
              beforeBytes: before.resourceBytes('map:alpha'),
              afterBytes: afterBytes)
        ]);

    expect(adopted, isNotNull);
    expect(f.cache.adoptions, 1);
    expect(
        f.cache.storedAuthoringBytes,
        f.authoringBytes -
            before.resourceBytes('map:alpha').length +
            afterBytes.length);
    expect(f.cache.storedAssetBlobBytes, f.blobBytes);
    expect(adopted!.resourceBytes('assetLogical:model3d_house'),
        same(before.resourceBytes(f.blobIdentities.first)));
    f.reader.resetCounts();
    final warm = await f.load();
    expect(f.reader.reads, isEmpty);
    final fresh =
        await ProjectSnapshotLoader(handles: f.handles).load(f.project);
    expect(adopted.revision, fresh.revision);
    expect(warm.resourceFingerprints, fresh.resourceFingerprints);
  });

  test('map adoption refuses a concurrently replaced logical model source',
      () async {
    final f = _Fixture.create();
    addTearDown(f.dispose);
    final before = await f.load();
    final afterBytes = utf8.encode(jsonEncode(
        before.mapById('alpha')!.copyWith(name: 'Renamed').toJson()));
    f.reader.replace('maps/alpha.json', afterBytes);
    f.reader.replace('assets/models3d/house.glb',
        [...f.modelBytes]..[f.modelBytes.length - 1] ^= 1);
    final adopted = await f.loader.adoptAppliedChanges(f.project,
        baseRevision: before.revision,
        changes: [
          AuthoringResourceChange(
              resource: AuthoringResourceRef(kind: 'map', id: 'alpha'),
              storageKey: 'maps/alpha.json',
              beforeBytes: before.resourceBytes('map:alpha'),
              afterBytes: afterBytes)
        ]);
    expect(adopted, isNull);
    expect(f.cache.invalidations, 1);
    expect(f.cache.projectCount, 0);
  });
}

final class _Fixture {
  _Fixture(
      this.reader,
      this.handles,
      this.project,
      this.workspace,
      this.loader,
      this.cache,
      this.modelBytes,
      this.blobPaths,
      this.blobIdentities,
      this.authoringBytes,
      this.blobBytes);

  final _Reader reader;
  final WorkspaceHandleStore handles;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  final ProjectSnapshotLoader loader;
  final ProjectSnapshotCache cache;
  final List<int> modelBytes;
  final List<String> blobPaths;
  final List<String> blobIdentities;
  final int authoringBytes;
  final int blobBytes;

  static _Fixture create({bool boundedCache = false}) {
    final modelBytes = triangleGlb();
    final otherBytes =
        triangleGlb(edit: (json) => json['asset']['generator'] = 'Other');
    final models = <ProjectModel3dEntry>[];
    final records = <AssetRecord>[];
    final blobs = <ContentArtifactRef, List<int>>{};
    final files = <String, List<int>>{};
    for (final (id, bytes) in [
      ('house', modelBytes),
      ('tree', modelBytes),
      ('other', otherBytes)
    ]) {
      final artifact =
          ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
      final path = 'assets/models3d/$id.glb';
      models.add(ProjectModel3dEntry(
          id: id,
          name: id,
          sourceAssetId: 'model3d_$id',
          relativePath: path,
          inspection: const GlbModel3dInspector().inspect(bytes)));
      records.add(AssetRecord(
          id: 'model3d_$id', logicalPath: path, artifact: artifact));
      files[path] = bytes;
      blobs[artifact] = bytes;
      files[assetBlobStorageKey(artifact)] = bytes;
    }
    files['project.json'] = utf8.encode(jsonEncode(ProjectManifest(
            name: 'Model buffers',
            version: ProjectVersion.v9,
            settings: const ProjectSettings(dimension: ProjectDimension.threeD),
            maps: const [
              ProjectMapEntry(
                  id: 'alpha', name: 'Alpha', relativePath: 'maps/alpha.json')
            ],
            tilesets: const [],
            models3d: models)
        .toJson()));
    files['maps/alpha.json'] = utf8.encode(jsonEncode(MapData(
        id: 'alpha',
        name: 'Alpha',
        version: ProjectVersion.v9,
        size: const GridSize(width: 2, height: 2),
        spatialScene: MapSpatialScene(width: 2, depth: 2),
        layers: const []).toJson()));
    files[assetCatalogStorageKey] =
        utf8.encode(jsonEncode(AssetCatalog(records: records).toJson()));
    final reader = _Reader(files);
    final handles = WorkspaceHandleStore();
    final registered = handles.registerProject(
        projectName: 'Model buffers',
        initialFingerprint: 'fixture',
        readBytes: reader.read,
        readIdentity: reader.identity,
        canReuseSnapshots: true);
    final authoringBytes = files['project.json']!.length +
        files['maps/alpha.json']!.length +
        files[assetCatalogStorageKey]!.length;
    final blobBytes =
        blobs.values.fold<int>(0, (sum, bytes) => sum + bytes.length);
    final cache = ProjectSnapshotCache(
        maximumBytes: boundedCache ? authoringBytes + 2 : 64 << 20,
        maximumAssetBlobBytes: boundedCache ? blobBytes : 256 << 20);
    return _Fixture(
        reader,
        handles,
        registered.projectHandle,
        registered.workspaceHandle,
        ProjectSnapshotLoader(handles: handles, snapshotCache: cache),
        cache,
        modelBytes,
        blobs.keys.map(assetBlobStorageKey).toList(),
        blobs.keys
            .map((artifact) => assetBlobResourceIdentity(artifact.digest))
            .toList(),
        authoringBytes,
        blobBytes);
  }

  Future<ProjectSnapshot> load() => loader.load(project);

  void dispose() => handles.closeWorkspace(workspace);
}

final class _Reader {
  _Reader(this.files);

  final Map<String, List<int>> files;
  final Map<String, int> reads = {};
  final Map<String, int> generations = {};
  var identityReads = 0;
  List<int> Function(String, int, List<int>)? onRead;

  Future<List<int>> read(String path) async {
    final bytes = files[path];
    if (bytes == null) {
      throw const WorkspaceAccessException(
          'workspace.file_unavailable', 'Missing fixture resource.');
    }
    final count = (reads[path] ?? 0) + 1;
    reads[path] = count;
    return onRead?.call(path, count, bytes) ?? bytes;
  }

  Future<ProjectResourceIdentity?> identity(String path) async {
    identityReads++;
    final bytes = files[path];
    return bytes == null
        ? null
        : ProjectResourceIdentity(
            scope: '/model-buffer-fixture',
            relativePath: path,
            byteLength: bytes.length,
            modifiedAtMicros: generations[path] ?? 1);
  }

  void replace(String path, List<int> bytes) {
    files[path] = bytes;
    generations[path] = (generations[path] ?? 1) + 1;
  }

  void resetCounts() {
    reads.clear();
    identityReads = 0;
  }
}
