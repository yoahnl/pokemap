import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/glb_fixture.dart';

void main() {
  test('managed aliases use exact source pairs with one pass over definitions',
      () async {
    final root = await Directory.systemTemp.createTemp('snapshot-aliases-');
    addTearDown(() => root.delete(recursive: true));
    final image = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/Z1sAAAAASUVORK5CYII=');
    final glb = triangleGlb();
    final imageArtifact =
        ContentArtifactRef.fromBytes(image, mediaType: 'image/png');
    final modelArtifact =
        ContentArtifactRef.fromBytes(glb, mediaType: 'model/gltf-binary');
    ProjectTilesetEntry atlas(String id, String assetId, String path) =>
        ProjectTilesetEntry(
          id: id,
          name: id,
          relativePath: path,
          source: ProjectTilesetSource.regularAtlas(
            assetId: assetId,
            pixelWidth: 1,
            pixelHeight: 1,
            tileWidth: 1,
            tileHeight: 1,
          ),
        );
    final manifest = ProjectManifest(
      name: 'Exact asset aliases',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      maps: const [],
      tilesets: [
        atlas('regular', 'atlas-source', 'assets/atlas.png'),
        atlas('crossed-a', 'source-b', 'assets/a.png'),
        atlas('crossed-b', 'source-a', 'assets/b.png'),
      ],
      models3d: [
        ProjectModel3dEntry(
          id: 'model',
          name: 'Model',
          relativePath: 'assets/models3d/model.glb',
          sourceAssetId: 'model-source',
          inspection: const GlbModel3dInspector().inspect(glb),
        ),
      ],
    );
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final aliases = [
      AssetRecord(
          id: 'model-source',
          logicalPath: 'assets/models3d/model.glb',
          artifact: modelArtifact),
      for (final (id, name) in [
        ('atlas-source', 'atlas'),
        ('source-a', 'a'),
        ('source-b', 'b'),
      ])
        AssetRecord(
            id: id, logicalPath: 'assets/$name.png', artifact: imageArtifact),
    ];
    Future<void> writeAsset(String path, List<int> bytes) async {
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }

    await writeAsset(assetBlobStorageKey(imageArtifact), image);
    await writeAsset(assetBlobStorageKey(modelArtifact), glb);
    for (final alias in aliases) {
      await writeAsset(
          alias.logicalPath, alias.artifact == modelArtifact ? glb : image);
    }
    final assetCatalog = File('${root.path}/$assetCatalogStorageKey');
    Future<void> writeCatalog() => assetCatalog
        .writeAsString(jsonEncode(AssetCatalog(records: aliases).toJson()));
    await writeCatalog();

    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final open = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final project = await open.openProject(root.path);
    addTearDown(() => open.closeWorkspace(project.workspaceHandle));
    late _ReadCountingList<ProjectTilesetEntry> tilesets;
    late _ReadCountingList<ProjectModel3dEntry> models;
    final loader = ProjectSnapshotLoader(
      handles: handles,
      decodeExecutor: ProjectSnapshotDecodeExecutor(
        offloadThresholdBytes: 0,
        workerRunner: <T>(T Function() decode) async {
          final value = decode();
          if (value is! ProjectManifest) return value;
          tilesets = _ReadCountingList(value.tilesets);
          models = _ReadCountingList(value.models3d);
          return value.copyWith(tilesets: tilesets, models3d: models) as T;
        },
      ),
    );
    final first = await loader.load(project.projectHandle);
    final originalReads = (tilesets: tilesets.reads, models: models.reads);
    expect(first.resourceStorageKeys,
        containsPair('assetLogical:atlas-source', 'assets/atlas.png'));
    expect(first.resourceStorageKeys,
        containsPair('assetLogical:model-source', 'assets/models3d/model.glb'));
    expect(first.resourceStorageKeys,
        containsPair('asset:source-a', 'assets/a.png'));
    expect(first.resourceStorageKeys,
        containsPair('asset:source-b', 'assets/b.png'));
    expect(
        first.resourceFingerprints['assetLogical:model-source'],
        computeAuthoringBytesFingerprint(glb,
            logicalName: 'assets/models3d/model.glb'));

    for (var index = 0; index < 32; index++) {
      final path = 'assets/unrelated-$index.png';
      await writeAsset(path, image);
      aliases.add(AssetRecord(
          id: 'unrelated-$index', logicalPath: path, artifact: imageArtifact));
    }
    await writeCatalog();
    final expanded = await loader.load(project.projectHandle);
    expect(expanded.revision, isNot(first.revision));
    expect(expanded.resourceFingerprints['assetLogical:model-source'],
        first.resourceFingerprints['assetLogical:model-source']);
    expect(expanded.resourceStorageKeys,
        containsPair('asset:unrelated-31', 'assets/unrelated-31.png'));
    expect(
      (tilesets: tilesets.reads, models: models.reads),
      originalReads,
      reason:
          'Adding unrelated aliases must not iterate the definitions again.',
    );
  });
}

final class _ReadCountingList<T> extends ListBase<T> {
  _ReadCountingList(this._values);

  final List<T> _values;
  int reads = 0;

  @override
  int get length => _values.length;

  @override
  set length(int value) => throw UnsupportedError('read only');

  @override
  T operator [](int index) {
    reads++;
    return _values[index];
  }

  @override
  void operator []=(int index, T value) => throw UnsupportedError('read only');
}
