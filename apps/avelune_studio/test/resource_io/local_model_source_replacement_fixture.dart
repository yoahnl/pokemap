import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';

final class ModelSourceReplacementFixture {
  ModelSourceReplacementFixture(
    this.root,
    this.session,
    this.maps,
    this.resources,
    this.input,
    this.foreignPaths,
  );

  final Directory root;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final LocalResourceAdapter resources;
  final File input;
  final Set<String> foreignPaths;
  File get mapFile => File('${root.path}/maps/room.json');

  static Future<ModelSourceReplacementFixture> create(
    int unrelated, {
    Future<void> Function()? beforeReconciliation,
    bool loadModels = true,
  }) async {
    final temporary = await Directory.systemTemp.createTemp(
      'studio_model_source_',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    final bytes = volumeGlb();
    final artifact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: 'model/gltf-binary',
    );
    final model = ProjectModel3dEntry(
      id: 'house',
      name: 'House',
      sourceAssetId: 'house-source',
      relativePath: 'assets/models3d/house.glb',
      scale: 1.25,
      pivot: Model3dVector3(x: .25, y: 0, z: 0),
      inspection: const GlbModel3dInspector().inspect(bytes),
    );
    final manifest = ProjectManifest(
      name: 'Scoped source replacement',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      maps: [
        const ProjectMapEntry(
          id: 'room',
          name: 'Room',
          relativePath: 'maps/room.json',
        ),
        for (var i = 0; i < unrelated; i++)
          ProjectMapEntry(
            id: 'foreign-$i',
            name: 'Foreign $i',
            relativePath: 'maps/foreign-$i.json',
          ),
      ],
      tilesets: const [],
      models3d: [
        model,
        for (var i = 0; i < unrelated; i++)
          ProjectModel3dEntry.fromJson({
            ...model.toJson(),
            'id': 'foreign-$i',
            'name': 'Foreign $i',
            'sourceAssetId': 'foreign-source-$i',
            'relativePath': 'assets/models3d/foreign-$i.glb',
          }),
      ],
    );
    final working = await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'studio-source-replacement',
      project: manifest,
    );
    final assetFile = File('${root.path}/$assetCatalogStorageKey');
    await assetFile.parent.create(recursive: true);
    await assetFile.writeAsString(
      jsonEncode(
        AssetCatalog(
          records: [
            AssetRecord(
              id: 'house-source',
              logicalPath: model.relativePath,
              artifact: artifact,
            ),
            for (var i = 0; i < unrelated; i++)
              AssetRecord(
                id: 'foreign-source-$i',
                logicalPath: 'assets/models3d/foreign-$i.glb',
                artifact: artifact,
              ),
          ],
        ).toJson(),
      ),
    );
    final source = File('${root.path}/${model.relativePath}');
    await source.parent.create(recursive: true);
    await source.writeAsBytes(bytes);
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    final foreignPaths = <String>{};
    for (var i = 0; i < manifest.maps.length; i++) {
      final entry = (await working.catalog.snapshot.indexEntry(
        CatalogDefinitionKey(
          CatalogDefinitionKind.catalogMetadata,
          jsonEncode(['projectDefinition', 'maps', i]),
        ),
      ))!;
      foreignPaths.add(
        '${root.path}/catalog/objects/${entry.reference.sha256}.json',
      );
    }
    for (var i = 0; i < unrelated; i++) {
      final entry = (await working.catalog.snapshot.indexEntry(
        CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'foreign-$i'),
      ))!;
      foreignPaths.add(
        '${root.path}/catalog/objects/${entry.reference.sha256}.json',
      );
    }
    for (final entry in manifest.maps) {
      final file = File('${root.path}/${entry.relativePath}');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        entry.id == 'room'
            ? jsonEncode(
                MapData(
                  id: 'room',
                  name: 'Room',
                  version: ProjectVersion.v9,
                  size: const GridSize(width: 8, height: 8),
                  spatialScene: MapSpatialScene(
                    width: 8,
                    depth: 8,
                    instances: [
                      SpatialModelInstance(
                        id: 'house-placed',
                        modelId: 'house',
                        position: Model3dVector3(x: 2, y: 0, z: 2),
                        rotationDegrees: 90,
                        scale: .8,
                        blocksMovement: true,
                      ),
                    ],
                  ),
                ).toJson(),
              )
            : 'unrelated map must not be decoded',
      );
      foreignPaths.add(file.path);
    }
    final session = ProjectSession(
      sessionId: root.path,
      name: manifest.name,
      directoryPath: root.path,
      storage: ProjectSessionStorage.workingCatalog,
    );
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadCatalog(session);
    if (loadModels) await maps.loadResourceKind(session, 'model3d');
    final resources = LocalResourceAdapter(
      session: session,
      mapAdapter: maps,
      beforeReconciliation: beforeReconciliation,
    );
    final input = File('${root.path}/replacement.glb');
    return ModelSourceReplacementFixture(
      root,
      session,
      maps,
      resources,
      input,
      foreignPaths,
    );
  }

  Future<void> dispose() async {
    await resources.dispose();
    await root.delete(recursive: true);
  }
}

final class UnreadableFile implements File {
  UnreadableFile(this.delegate, this.attempts);
  final File delegate;
  final List<String> attempts;
  Never deny() {
    attempts.add(path);
    throw StateError('Unrelated read: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<Uint8List> readAsBytes() async => deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      deny();
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<int> volumeGlb({void Function(Map<String, dynamic>)? edit}) => triangleGlb(
  edit: (json) {
    json['nodes'][0]['rotation'] = [0, .3826834323650898, 0, .9238795325112867];
    edit?.call(json);
  },
);
