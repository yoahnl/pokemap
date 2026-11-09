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

final class ModelShadowFixture {
  ModelShadowFixture(
    this.root,
    this.session,
    this.maps,
    this.resources,
    this.foreignPaths,
  );

  final Directory root;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final LocalResourceAdapter resources;
  final Set<String> foreignPaths;

  static Future<ModelShadowFixture> create({
    int unrelated = 0,
    ProjectSessionStorage storage = ProjectSessionStorage.workingCatalog,
    void Function(String)? phaseObserver,
    Future<void> Function()? beforeTransaction,
    Future<void> Function()? beforeReconciliation,
  }) async {
    final base = Directory('/Users/karim/Library/Caches/AveluneQA/issue-16');
    await base.create(recursive: true);
    final temporary = await base.createTemp('project-');
    final root = Directory(await temporary.resolveSymbolicLinks());
    final bytes = triangleGlb();
    final model = ProjectModel3dEntry(
      id: 'house',
      name: 'House',
      sourceAssetId: 'house-source',
      relativePath: 'assets/models3d/house.glb',
      scale: 1.25,
      pivot: Model3dVector3(x: .25, y: 0, z: 0),
      inspection: const GlbModel3dInspector().inspect(bytes),
      light: Model3dPointLight(localPosition: Model3dVector3(x: 0, y: 2, z: 0)),
    );
    final project = ProjectManifest(
      name: 'Shadow mutation QA',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      maps: [
        for (var i = 0; i <= unrelated; i++)
          ProjectMapEntry(
            id: 'room-$i',
            name: 'Room $i',
            relativePath: 'maps/room-$i.json',
          ),
      ],
      tilesets: [],
      models3d: [
        model,
        for (var i = 0; i < unrelated; i++)
          ProjectModel3dEntry.fromJson({
            ...model.toJson(),
            'id': 'foreign-$i',
            'sourceAssetId': 'foreign-source-$i',
            'relativePath': 'assets/models3d/foreign-$i.glb',
          }),
      ],
    );
    final foreign = <String>{};
    for (final entry in project.maps) {
      final file = File('${root.path}/${entry.relativePath}');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode(
          MapData(
            id: entry.id,
            name: entry.name,
            version: ProjectVersion.v9,
            size: const GridSize(width: 16, height: 16),
            spatialScene: MapSpatialScene(
              width: 16,
              depth: 16,
              instances: [
                SpatialModelInstance(
                  id: 'placed',
                  modelId: 'house',
                  position: Model3dVector3(x: 2, y: 0, z: 2),
                ),
              ],
            ),
          ).toJson(),
        ),
      );
      foreign.add(file.path);
    }
    final assets = <AssetRecord>[];
    for (final entry in project.models3d) {
      final file = File('${root.path}/${entry.relativePath}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      foreign.add(file.path);
      assets.add(
        AssetRecord(
          id: entry.sourceAssetId,
          logicalPath: entry.relativePath,
          artifact: ContentArtifactRef.fromBytes(
            bytes,
            mediaType: 'model/gltf-binary',
          ),
        ),
      );
    }
    final assetFile = File('${root.path}/$assetCatalogStorageKey');
    await assetFile.writeAsString(
      jsonEncode(AssetCatalog(records: assets).toJson()),
    );
    foreign.add(assetFile.path);
    final blob = File(
      '${root.path}/${assetBlobStorageKey(assets.first.artifact)}',
    );
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    foreign.add(blob.path);
    if (storage == ProjectSessionStorage.manifest) {
      await File('${root.path}/project.json').writeAsString(
        jsonEncode({
          ...project.toJson(),
          'futureProjectField': {'preserve': true},
        }),
      );
    } else if (storage == ProjectSessionStorage.portableCatalog) {
      final publication = PortableCatalogPublication.encodeProject(project);
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      await store.publish(publication.storage, expectedRootRevision: null);
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(publication.descriptor));
    } else {
      final working = await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: root.path),
        projectId: 'shadow-qa',
        project: project,
      );
      for (var i = 0; i < unrelated; i++) {
        final entry = (await working.catalog.snapshot.indexEntry(
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'foreign-$i'),
        ))!;
        foreign.add(
          '${root.path}/catalog/objects/${entry.reference.sha256}.json',
        );
      }
    }
    final session = ProjectSession(
      sessionId: root.path,
      name: project.name,
      directoryPath: root.path,
      storage: storage,
    );
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadCatalog(session);
    if (storage == ProjectSessionStorage.workingCatalog) {
      await maps.loadResourceKind(session, 'model3d');
    }
    final resources = LocalResourceAdapter(
      session: session,
      mapAdapter: maps,
      mutationPhaseObserver: phaseObserver,
      beforeTransactionPrecondition: beforeTransaction,
      beforeReconciliation: beforeReconciliation,
    );
    return ModelShadowFixture(root, session, maps, resources, foreign);
  }

  Future<T> observe<T>(
    Future<T> Function() operation,
    List<String> reads, {
    bool denyForeign = false,
  }) {
    final outside = Zone.current;
    return IOOverrides.runZoned(
      operation,
      createFile: (path) {
        final file = outside.run(() => File(path));
        return foreignPaths.contains(path)
            ? _ObservedFile(file, reads, denyForeign)
            : file;
      },
    );
  }

  Future<void> dispose() async {
    await resources.dispose();
    await root.delete(recursive: true);
  }
}

final class _ObservedFile implements File {
  _ObservedFile(this.file, this.reads, this.deny);
  final File file;
  final List<String> reads;
  final bool deny;
  void read() {
    reads.add(path);
    if (deny) throw StateError('Unrelated read: $path');
  }

  @override
  String get path => file.path;
  @override
  Uri get uri => file.uri;
  @override
  bool get isAbsolute => file.isAbsolute;
  @override
  Directory get parent => file.parent;
  @override
  File get absolute => file.absolute;
  @override
  Future<bool> exists() => file.exists();
  @override
  Future<FileStat> stat() => file.stat();
  @override
  Future<String> resolveSymbolicLinks() => file.resolveSymbolicLinks();
  @override
  Future<Uint8List> readAsBytes() {
    read();
    return file.readAsBytes();
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    read();
    return file.readAsString(encoding: encoding);
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    read();
    return file.openRead(start, end);
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    read();
    return file.open(mode: mode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
