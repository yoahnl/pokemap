import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  final root = arguments.single;
  final models = <ProjectModel3dEntry>[];
  final assets = <AssetRecord>[];
  for (final id in ['door', 'static']) {
    final bytes = await File('$root/$id.glb').readAsBytes();
    final artifact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: 'model/gltf-binary',
    );
    final model = ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: 'model3d_$id',
      relativePath: 'assets/models3d/$id.glb',
      collisionBounds: Model3dBounds(
        min: Model3dVector3.zero,
        max: Model3dVector3(x: 1, y: 1, z: .1),
      ),
      inspection: const GlbModel3dInspector().inspect(bytes),
    );
    models.add(model);
    assets.add(AssetRecord(
      id: model.sourceAssetId,
      logicalPath: model.relativePath,
      artifact: artifact,
    ));
    for (final path in [model.relativePath, assetBlobStorageKey(artifact)]) {
      final file = File('$root/$path');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }
  }
  final map = MapData(
    id: 'room',
    name: 'Room',
    version: ProjectVersion.v9,
    size: const GridSize(width: 8, height: 6),
    spatialScene: MapSpatialScene(width: 8, depth: 6, instances: [
      SpatialModelInstance(
        id: 'placed-door',
        modelId: 'door',
        position: Model3dVector3(x: 1, y: 0, z: 1),
        blocksMovement: false,
      ),
    ]),
    warps: const [
      MapWarp(
        id: 'entrance',
        pos: GridPos(x: 1, y: 1),
        targetMapId: 'room',
        targetPos: GridPos(x: 2, y: 1),
        door: MapWarpDoor(
          instanceId: 'placed-door',
          openAnimationIndex: 0,
          closeAnimationIndex: 1,
          exitPos: GridPos(x: 1, y: 2),
        ),
      ),
    ],
  );
  final project = ProjectManifest(
    name: 'Catalog model replacement transport',
    version: ProjectVersion.v9,
    settings: ProjectSettings(
      dimension: ProjectDimension.threeD,
      spatialCamera: SpatialCameraProfile(),
    ),
    maps: const [
      ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json')
    ],
    tilesets: const [],
    models3d: models,
  );
  ProjectValidator.validate(project, maps: [map]);
  MapValidator.validate(map, projectDialogueContext: project);
  final store = await CatalogStorageStore.open(projectRoot: root);
  await WorkingProjectCatalog.create(
    store: store,
    projectId: 'model-source-transport',
    project: project,
  );
  final mapFile = File('$root/maps/room.json');
  await mapFile.parent.create(recursive: true);
  await mapFile.writeAsString(jsonEncode(map.toJson()));
  await File('$root/$assetCatalogStorageKey').writeAsString(
    jsonEncode(AssetCatalog(records: assets).toJson()),
  );
}
