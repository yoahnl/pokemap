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
