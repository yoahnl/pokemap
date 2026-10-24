import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';

void main() {
  for (final partitioned in [false, true]) {
    test(
      'contact portraits survive map projection, partitioned=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'contact-projection-',
        );
        addTearDown(() => root.delete(recursive: true));
        final project = ProjectManifest(
          name: 'Contact projection',
          version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
          maps: [],
          facts: [
            NarrativeFactDefinition(id: 'has-journal', label: 'Has journal'),
            NarrativeFactDefinition(id: 'knows-mentor', label: 'Knows mentor'),
          ],
          scenes: [
            SceneAsset(
              id: 'mentor-call',
              name: 'Mentor call',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  SceneEdge(
                    id: 'finish',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                ],
              ),
            ),
          ],
          tilesets: [
            for (final id in ['mentor', 'unused'])
              ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
          ],
          characters: [
            for (final id in ['mentor', 'unused'])
              ProjectCharacterEntry(id: id, name: id, tilesetId: id),
          ],
          contactDevice: ProjectContactDeviceConfig(
            id: 'journal',
            label: 'Journal',
            acquiredFactId: 'has-journal',
            emptyMessage: 'No contacts',
            contacts: [
              ProjectContactEntryConfig(
                id: 'mentor',
                label: 'Mentor',
                registeredFactId: 'knows-mentor',
                sceneId: 'mentor-call',
                unavailableSceneId: 'mentor-call',
                characterId: 'mentor',
              ),
            ],
          ),
        );
        final file = File('${root.path}/project.json');
        if (partitioned) {
          final publication = PortableCatalogPublication.encodeProject(project);
          await file.writeAsString(jsonEncode(publication.descriptor));
          for (final object in publication.storage.objects.entries) {
            final target = File(
              '${root.path}/catalog/objects/${object.key}.json',
            );
            await target.parent.create(recursive: true);
            await target.writeAsBytes(object.value);
          }
        } else {
          await file.writeAsString(jsonEncode(project.toJson()));
        }
        final catalog = await RuntimeProjectCatalog.open(file.path);
        addTearDown(catalog.dispose);
        final view = await catalog.manifestForMap(
          const MapData(
            id: 'empty-room',
            name: 'Empty room',
            version: ProjectVersion.v9,
            size: GridSize(width: 2, height: 2),
          ),
        );
        expect(view.characters.map((c) => c.id), ['mentor']);
        expect(view.tilesets.map((t) => t.id), ['mentor']);
        expect(view.contactDevice, project.contactDevice);
        expect(catalog.projectMetadata.characters, isEmpty);
      },
    );
  }
}
