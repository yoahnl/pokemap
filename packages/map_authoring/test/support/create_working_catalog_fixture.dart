import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  final root = arguments.first;
  final project = ProjectManifest(
      name: 'Transport catalog',
      version: ProjectVersion.v8,
      maps: const [],
      models3d: [
        if (arguments.contains('--light-workshop'))
          ProjectModel3dEntry(
              id: 'lamp',
              name: 'Lamp',
              sourceAssetId: 'model3d_lamp',
              relativePath: 'assets/models3d/lamp.glb',
              inspection: Model3dInspection(
                  bounds: Model3dBounds(
                      min: Model3dVector3.zero,
                      max: Model3dVector3(x: 1, y: 3, z: 1)),
                  meshCount: 1,
                  triangleCount: 4))
      ],
      tilesets: [
        for (var i = 0; i < 205; i++)
          ProjectTilesetEntry(
              id: 'tile-${i.toString().padLeft(3, '0')}',
              name: 'Object $i',
              relativePath: 'assets/object.png')
      ]);
  if (arguments.contains('--monolithic')) {
    await File('$root/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    return;
  }
  final store = await CatalogStorageStore.open(projectRoot: root);
  final built = PortableCatalogPublication.encodeProject(project);
  await store.publish(built.storage, expectedRootRevision: null);
  await File('$root/project.json').writeAsString(jsonEncode(
      WorkingProjectCatalogDescriptor(projectId: 'transport-fixture')
          .toJson()));
}
