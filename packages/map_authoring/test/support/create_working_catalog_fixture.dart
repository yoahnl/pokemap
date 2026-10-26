import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../domains/maps/healing_display_fixture.dart';

Future<void> main(List<String> arguments) async {
  final root = arguments.first;
  final healing = arguments.contains('--story-map') ? healingProject() : null;
  final project = ProjectManifest(
      name: 'Transport catalog',
      version: ProjectVersion.v8,
      maps: arguments.contains('--story-map')
          ? const [
              ProjectMapEntry(
                  id: 'story', name: 'Story', relativePath: 'maps/story.json'),
              ProjectMapEntry(
                  id: 'foreign',
                  name: 'Foreign',
                  relativePath: 'maps/foreign.json'),
            ]
          : const [],
      eventRegistry: arguments.contains('--story-map')
          ? NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              legacyClaims: const [],
              records: [
                  NarrativeEventRecord.draft(NarrativeEventDraft(
                      id: 'evt_018f0f8c-7b8a-7def-8000-000000000001',
                      name: 'Consumed event',
                      conditions: const [],
                      priority: 0,
                      order: 0)),
                ])
          : null,
      elements: [
        ...?healing?.elements,
        for (final element
            in healing?.elements ?? const <ProjectElementEntry>[])
          element.copyWith(id: 'alternate-${element.id}')
      ],
      elementCategories: healing?.elementCategories ?? const [],
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
        ...?healing?.tilesets,
        for (var i = 0; i < 205; i++)
          ProjectTilesetEntry(
              id: 'tile-${i.toString().padLeft(3, '0')}',
              name: 'Object $i',
              relativePath: 'assets/object.png')
      ]);
  if (arguments.contains('--story-map')) {
    await Directory('$root/maps').create(recursive: true);
    await File('$root/maps/story.json').writeAsString(jsonEncode(const MapData(
      id: 'story',
      name: 'Story',
      size: GridSize(width: 8, height: 6),
      version: ProjectVersion.v8,
    ).toJson()));
    await File('$root/maps/foreign.json')
        .writeAsString('foreign map must remain unread');
  }
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
