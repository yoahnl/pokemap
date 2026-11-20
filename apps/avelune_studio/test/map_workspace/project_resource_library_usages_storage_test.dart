import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/exterior_decoration_fixture.dart';
import '../../../../packages/map_authoring/test/support/resource_index_fixture.dart';

void main() {
  test(
    'library usages follow saved exterior Borders without reading base maps',
    () async {
      final base = Directory(
        '/Users/karim/Library/Caches/AveluneQA/resource-library-map-usages',
      );
      await base.create(recursive: true);
      final root = await base.createTemp('fixture_');
      addTearDown(() => root.delete(recursive: true));
      final decoration = await createExteriorDecorationFixture(root.path);
      final fixture = await ResourceIndexFixture.openExisting(root);
      addTearDown(fixture.close);
      final reader = ResourceIndexReader()
        ..forbiddenPaths.add('maps/route.json');
      final adapter = LocalMapWorkspaceAdapter(reader: reader);
      final session = ProjectSession(
        sessionId: 'library-usages',
        name: 'Bibliothèque des décors',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );

      Future<Map<String, Set<String>>?> read([String? revision]) async {
        final library = await adapter.readResourceLibrary(session);
        return adapter.readResourceLibraryMapUsages(
          session,
          revision: revision ?? library.revision!,
          identities: const [
            'model3d:unit',
            'borderBlueprint:fence',
            'model3d:oak',
          ],
        );
      }

      expect(await read(), isNull);
      Future<ProjectLibraryRelations?> relations(String kind, String id) async {
        return adapter.readResourceLibraryRelations(
          session,
          kind,
          id,
          revision: await adapter.resourceRevision(session),
        );
      }

      final unprepared = await relations('borderBlueprint', 'fence');
      expect(unprepared?.sources, contains('model3d:unit'));
      expect(unprepared?.consumers, isNull);
      await fixture.prepare();
      final model = await relations('model3d', 'unit');
      expect(model?.consumers, {'borderBlueprint:fence'});
      final border = await relations('borderBlueprint', 'fence');
      expect(border?.sources, contains('model3d:unit'));
      expect(border?.consumers, isEmpty);
      expect(
        await adapter.readResourceLibraryRelations(
          session,
          'model3d',
          'unit',
          revision: 'stale',
        ),
        isNull,
      );
      expect(await read('stale'), isNull);
      expect(await read(), isEmpty);

      final service = LocalMapExteriorDecorationAuthoring(
        policy: await WorkspacePolicy.create(
          allowedRootPaths: [root.path],
          fileReader: const LocalProjectFileReader(),
        ),
      );
      final placed = await service.setBorder(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: decoration['revision'] as String,
        operationId: 'library-usage-border',
        border: ExteriorDecorationBorder(
          id: 'fence-west',
          layerId: 'exterior-border',
          originX: -16,
          originZ: 0,
          width: 16,
          depth: 16,
          feature: BorderFeature(
            id: 'fence-west',
            name: 'Clôture extérieure',
            blueprintId: 'fence',
            seed: BorderSignedInt64.fromInt(42),
            geometry: BorderStrokeGeometry(
              strokes: [
                BorderStroke(
                  id: 'straight',
                  points: const [GridPos(x: 1, y: 1), GridPos(x: 1, y: 2)],
                  closed: false,
                ),
              ],
            ),
            overrides: const [],
            keepOutRegions: const [],
          ),
        ),
      );
      expect(await read(), {
        'model3d:unit': {'route'},
        'borderBlueprint:fence': {'route'},
      });
      await service.removeBorder(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: placed.afterRevision,
        borderId: 'fence-west',
        operationId: 'library-usage-remove-border',
      );
      expect(await read(), isEmpty);
      expect(reader.paths, isNot(contains('maps/route.json')));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
