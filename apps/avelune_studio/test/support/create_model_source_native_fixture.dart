import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

const qa = '/Users/karim/Library/Caches/AveluneQA/bg3d-02-replacement/native';
const root = '$qa/project';
Uint8List source(
  int color, {
  bool animated = true,
  int columns = 32,
  int rows = 16,
  double widthScale = 1,
  double heightScale = 1,
}) {
  final vertices = <double>[], normals = <double>[], uvs = <double>[];
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < columns; x++) {
      for (final p in [
        [x, y],
        [x + 1, y],
        [x, y + 1],
        [x + 1, y],
        [x + 1, y + 1],
        [x, y + 1],
      ]) {
        vertices.addAll([
          (p[0] / columns - .5) * widthScale,
          p[1] / rows * 2 * heightScale,
          0,
        ]);
        normals.addAll([0, 0, 1]);
        uvs.addAll([p[0] / columns, p[1] / rows]);
      }
    }
  }
  final binary = BytesBuilder(),
      views = <Map<String, Object?>>[],
      accessors = <Map<String, Object?>>[];
  int floats(
    List<double> values,
    String type,
    int count, {
    List<double>? min,
    List<double>? max,
  }) {
    final data = ByteData(values.length * 4);
    for (var i = 0; i < values.length; i++) {
      data.setFloat32(i * 4, values[i], Endian.little);
    }
    views.add({
      'buffer': 0,
      'byteOffset': binary.length,
      'byteLength': data.lengthInBytes,
    });
    binary.add(data.buffer.asUint8List());
    accessors.add({
      'bufferView': views.length - 1,
      'componentType': 5126,
      'count': count,
      'type': type,
      'min': ?min,
      'max': ?max,
    });
    return accessors.length - 1;
  }

  final position = floats(
    vertices,
    'VEC3',
    vertices.length ~/ 3,
    min: [-.5 * widthScale, 0, 0],
    max: [.5 * widthScale, 2 * heightScale, 0],
  );
  final normal = floats(normals, 'VEC3', normals.length ~/ 3),
      uv = floats(uvs, 'VEC2', uvs.length ~/ 2);
  int? time, translation;
  if (animated) {
    time = floats([0, 2], 'SCALAR', 2, min: [0], max: [2]);
    translation = floats([0, 0, 0, 0, .15, 0], 'VEC3', 2);
  }
  final bitmap = image.Image(width: 256, height: 256);
  for (var y = 0; y < 256; y++) {
    for (var x = 0; x < 256; x++) {
      bitmap.setPixelRgb(
        x,
        y,
        (color + x ~/ 16 * 7) % 256,
        (80 + y ~/ 16 * 5) % 256,
        90,
      );
    }
  }
  final png = image.encodePng(bitmap);
  views.add({
    'buffer': 0,
    'byteOffset': binary.length,
    'byteLength': png.length,
  });
  binary.add(png);
  final document = {
    'asset': {'version': '2.0'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [0],
      },
    ],
    'nodes': [
      {'mesh': 0},
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {
              'POSITION': position,
              'NORMAL': normal,
              'TEXCOORD_0': uv,
            },
            'material': 0,
          },
        ],
      },
    ],
    'materials': [
      {
        'doubleSided': true,
        'pbrMetallicRoughness': {
          'baseColorTexture': {'index': 0},
        },
      },
    ],
    'textures': [
      {'source': 0, 'sampler': 0},
    ],
    'samplers': [
      {'magFilter': 9728, 'minFilter': 9728},
    ],
    'images': [
      {'bufferView': views.length - 1, 'mimeType': 'image/png'},
    ],
    'buffers': [
      {'byteLength': binary.length},
    ],
    'bufferViews': views,
    'accessors': accessors,
    if (animated)
      'animations': [
        for (final name in ['Open', 'Close'])
          {
            'name': name,
            'samplers': [
              {'input': time, 'output': translation, 'interpolation': 'LINEAR'},
            ],
            'channels': [
              {
                'sampler': 0,
                'target': {'node': 0, 'path': 'translation'},
              },
            ],
          },
      ],
  };
  final json = utf8.encode(jsonEncode(document)), bin = binary.takeBytes();
  final jl = (json.length + 3) & ~3, bl = (bin.length + 3) & ~3;
  final bytes = Uint8List(28 + jl + bl), header = ByteData.sublistView(bytes);
  header.setUint32(0, 0x46546c67, Endian.little);
  header.setUint32(4, 2, Endian.little);
  header.setUint32(8, bytes.length, Endian.little);
  header.setUint32(12, jl, Endian.little);
  header.setUint32(16, 0x4e4f534a, Endian.little);
  bytes.fillRange(20, 20 + jl, 32);
  bytes.setRange(20, 20 + json.length, json);
  header.setUint32(20 + jl, bl, Endian.little);
  header.setUint32(24 + jl, 0x004e4942, Endian.little);
  bytes.setRange(28 + jl, 28 + jl + bin.length, bin);
  return bytes;
}

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
