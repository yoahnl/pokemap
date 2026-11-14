import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'create_model_source_native_glb.dart';

const qa = '/Users/karim/Library/Caches/AveluneQA/bg3d-02-replacement/native';
const root = '$qa/project';

Future<void> main(List<String> args) async {
  if (args.length > 2) {
    throw ArgumentError('Expected unrelated count and history count.');
  }
  final unrelated = args.isEmpty ? 80 : int.parse(args[0]);
  final historyCount = args.length < 2 ? 120 : int.parse(args[1]);
  if (unrelated < 0 ||
      historyCount < 0 ||
      (historyCount > 0 && unrelated == 0)) {
    throw ArgumentError(
      'Counts must be nonnegative, with a foreign model for history.',
    );
  }
  const base = '/Users/karim/Library/Caches/AveluneQA';
  if (await Directory(base).resolveSymbolicLinks() != base) {
    throw StateError('The canonical QA base is required.');
  }
  for (final path in ['$base/bg3d-02-replacement', qa]) {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) await Directory(path).create();
    if (await Directory(path).resolveSymbolicLinks() != path) {
      throw StateError('QA output directories must be canonical.');
    }
  }
  for (final path in [
    root,
    '$qa/candidate-1.glb',
    '$qa/candidate-2.glb',
    '$qa/fixture.json',
  ]) {
    if (await FileSystemEntity.type(path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw StateError('Refusing to overwrite existing fixture output: $path');
    }
  }
  await Directory(root).create();
  final original = source(50),
      foreign = source(130, animated: false, columns: 8, rows: 4);
  final models = <ProjectModel3dEntry>[],
      assets = <AssetRecord>[],
      foreignPaths = <String>[];
  for (var i = -1; i < unrelated; i++) {
    final id = i < 0 ? 'door' : 'foreign-$i',
        bytes = i < 0 ? original : foreign;
    var model = ProjectModel3dEntry(
      id: id,
      name: i < 0 ? 'A QA Door' : 'Foreign $i',
      sourceAssetId: 'source-$id',
      relativePath: 'assets/models3d/$id.glb',
      scale: 1.25,
      pivot: Model3dVector3(x: .1, y: 0, z: 0),
      inspection: const GlbModel3dInspector().inspect(bytes),
    );
    model = ProjectModel3dEntry.fromJson({
      ...model.toJson(),
      'collisionBounds': {
        'min': {'x': -.3, 'y': 0.0, 'z': -.15},
        'max': {'x': .3, 'y': 1.8, 'z': .15},
      },
    });
    models.add(model);
    final artifact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: 'model/gltf-binary',
    );
    assets.add(
      AssetRecord(
        id: model.sourceAssetId,
        logicalPath: model.relativePath,
        artifact: artifact,
      ),
    );
    for (final path in [model.relativePath, assetBlobStorageKey(artifact)]) {
      final f = File('$root/$path');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes);
      if (i >= 0) foreignPaths.add(path);
    }
  }
  final maps = <MapData>[];
  for (var i = -1; i < unrelated; i++) {
    final id = i < 0 ? 'room' : 'foreign-map-$i';
    maps.add(
      MapData(
        id: id,
        name: i < 0 ? 'A QA Room' : 'Foreign room $i',
        version: ProjectVersion.v9,
        size: const GridSize(width: 32, height: 24),
        spatialScene: MapSpatialScene(
          width: 32,
          depth: 24,
          instances: i < 0
              ? [
                  SpatialModelInstance(
                    id: 'placed-door',
                    modelId: 'door',
                    position: Model3dVector3(x: 3, y: 0, z: 3),
                    blocksMovement: true,
                  ),
                  for (var j = 0; j < (unrelated < 24 ? unrelated : 24); j++)
                    SpatialModelInstance(
                      id: 'foreign-instance-$j',
                      modelId: 'foreign-$j',
                      position: Model3dVector3(
                        x: 6 + (j % 8) * 2.0,
                        y: 0,
                        z: 3 + (j ~/ 8) * 3.0,
                      ),
                      blocksMovement: false,
                    ),
                ]
              : [],
        ),
        warps: i < 0
            ? const [
                MapWarp(
                  id: 'entrance',
                  pos: GridPos(x: 3, y: 3),
                  targetMapId: 'room',
                  targetPos: GridPos(x: 4, y: 3),
                  door: MapWarpDoor(
                    instanceId: 'placed-door',
                    openAnimationIndex: 0,
                    closeAnimationIndex: 1,
                    exitPos: GridPos(x: 3, y: 4),
                  ),
                ),
              ]
            : [],
      ),
    );
  }
  final project = ProjectManifest(
    name: 'BG3D-02 Native QA',
    version: ProjectVersion.v9,
    settings: ProjectSettings(
      dimension: ProjectDimension.threeD,
      spatialCamera: SpatialCameraProfile(),
    ),
    maps: [
      for (final map in maps)
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    tilesets: [],
    models3d: models,
  );
  ProjectValidator.validate(project, maps: maps);
  for (final map in maps) {
    MapValidator.validate(map, projectDialogueContext: project);
  }
  final working = await WorkingProjectCatalog.create(
    store: await CatalogStorageStore.open(projectRoot: root),
    projectId: 'bg3d-native',
    project: project,
  );
  for (final map in maps) {
    final path = 'maps/${map.id}.json';
    final f = File('$root/$path');
    await f.parent.create(recursive: true);
    await f.writeAsString(jsonEncode(map.toJson()));
    if (map.id != 'room') foreignPaths.add(path);
  }
  await File('$root/$assetCatalogStorageKey')
      .writeAsString(jsonEncode(AssetCatalog(records: assets).toJson()));
  for (var i = 0; i < unrelated; i++) {
    final entry = await working.catalog.snapshot.indexEntry(
      CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'foreign-$i'),
    );
    foreignPaths.add('catalog/objects/${entry!.reference.sha256}.json');
  }
  final pose = const SpatialWorldState.empty().setModelState(
    'room',
    'placed-door',
    SpatialModelRuntimeState(
      modelId: 'door',
      animationIndex: 1,
      normalizedTime: .75,
      blocksMovement: true,
    ),
  );
  validateSpatialWorldState(state: pose, project: project, maps: maps);
  await File('$root/existing-pose.json')
      .writeAsString(jsonEncode(pose.toJson()));
  await File('$qa/candidate-1.glb')
      .writeAsBytes(source(170, widthScale: 1.25, heightScale: 1.05));
  await File('$qa/candidate-2.glb')
      .writeAsBytes(source(230, widthScale: .9, heightScale: 1.15));
  if (historyCount > 0) {
    final handles = WorkspaceHandleStore(),
        policy = await WorkspacePolicy.create(
          allowedRootPaths: [root],
          fileReader: const LocalProjectFileReader(),
        );
    final opened = await ProjectOpenService(
      policy: policy,
      handles: handles,
      fileReader: const LocalProjectFileReader(),
      catalogMetadataFields: {},
    ).openProject(root);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      authorizationLimits: const AuthoringSecurityLimits(
        maxOperationsPerWindow: null,
      ),
    );
    await api.attachProject(
      projectRootPath: root,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    for (var i = 0; i < historyCount; i++) {
      final bytes = source(5 + i, animated: false, columns: 8, rows: 4),
          artifact = await api.artifacts.put(
            bytes,
            declaredMediaType: 'model/gltf-binary',
          );
      final parameters = {
        'modelId': 'foreign-0',
        'artifactHandle': artifact.reference.handle,
      };
      final snapshot = await api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: 'model3d.source.replace',
        parameters: parameters,
      );
      final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'seed-$i',
          actionId: 'model3d.source.replace',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'seed-$i',
          parameters: parameters,
        ),
      );
      await api.applyMutation(
        opened.projectHandle,
        planId: plan.planId,
        operationId: 'seed-$i',
      );
    }
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
  final fingerprints = <String, String>{};
  await for (final entity in Directory(root).list(recursive: true)) {
    if (entity is File) {
      final path = entity.path.substring(root.length + 1);
      fingerprints[path] = ContentArtifactRef.fromBytes(
        await entity.readAsBytes(),
        mediaType: "application/octet-stream",
      ).digest;
    }
  }
  await File('$qa/fixture.json').writeAsString(
    jsonEncode({
      'unrelatedModels': unrelated,
      'unrelatedMaps': unrelated,
      'canonicalHistoryEntries': historyCount,
      'primaryTriangles': 1024,
      'primaryTexture': [256, 256],
      'primaryByteLength': original.length,
      'modelConfig': models.first.toJson(),
      'foreignPaths': foreignPaths.toSet().toList(),
      'fingerprints': fingerprints,
    }),
  );
  stdout.writeln(
    jsonEncode({
      'ready': true,
      'models': models.length,
      'maps': maps.length,
      'history': historyCount,
      'primaryBytes': original.length,
    }),
  );
}
