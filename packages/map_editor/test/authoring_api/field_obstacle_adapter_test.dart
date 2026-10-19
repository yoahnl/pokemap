import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/application/use_cases/entity_use_cases.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  for (final kind in [
    FieldObstacleKind.cutTree,
    FieldObstacleKind.strengthBoulder,
  ]) {
    test(
      'editor adapter consumes ${kind.name} beside slide with requery, undo and cold reopen',
      () async {
        final temporary = await Directory.systemTemp.createTemp(
          'legacy-cut-adapter-',
        );
        final root = Directory(await temporary.resolveSymbolicLinks());
        addTearDown(() => root.delete(recursive: true));
        const project = ProjectManifest(
          name: 'Cut adapter',
          maps: [
            ProjectMapEntry(
              id: 'route',
              name: 'Route',
              relativePath: 'maps/route.json',
            ),
          ],
          tilesets: [
            ProjectTilesetEntry(
              id: 'trees',
              name: 'Trees',
              relativePath: 'trees.png',
            ),
          ],
          elementCategories: [
            ProjectElementCategory(id: 'props', name: 'Props'),
          ],
          elements: [
            ProjectElementEntry(
              id: 'tree',
              name: 'Tree',
              tilesetId: 'trees',
              categoryId: 'props',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                ),
              ],
            ),
          ],
        );
        final map = MapData(
          id: 'route',
          name: 'Route',
          size: const GridSize(width: 6, height: 5),
          visualStack: MapVisualStackConfig.canonicalV1,
          layers: [
            MapLayer.tile(id: 'base', name: 'Sol', cells: List.filled(30, 0)),
            MapLayer.collision(
              id: 'collision',
              name: 'Collision',
              collisions: List.generate(30, (index) => index == 11),
            ),
          ],
          gameplayZones: const [
            MapGameplayZone(
              id: 'ice',
              name: 'Glace',
              kind: GameplayZoneKind.movementEffect,
              area: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 4, height: 2),
              ),
              movementEffect: MovementEffectZonePayload(),
            ),
          ],
          entities: const [
            MapEntity(
              id: 'tree',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 2, y: 1),
              editorVisual: MapEntityEditorVisual(elementId: 'tree'),
              properties: {'preserved': 'yes'},
            ),
          ],
        );
        final projectFile = File('${root.path}/project.json');
        final mapFile = File('${root.path}/maps/route.json');
        await FileProjectRepository().saveProject(project, projectFile.path);
        await FileMapRepository().saveMap(
          map,
          mapFile.path,
          projectDialogueContext: project,
        );
        final projectBefore = await projectFile.readAsBytes();
        const reader = EditorProjectFileReader();
        final queries = AuthoringQueryAdapter(fileReader: reader);
        final mutations = AuthoringMutationAdapter(
          fileReader: reader,
          queries: queries,
          projectRoots: reader,
        );
        addTearDown(() async {
          await mutations.closeProject(root.path);
          await queries.closeProject(root.path);
        });
        Future<MapData> read() async => MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
        );
        final before = await mapFile.readAsBytes();
        final plan = await mutations.plan(
          root.path,
          actionId: 'entity.set_field_obstacle',
          parameters: {
            'mapId': 'route',
            'entityId': 'tree',
            'fieldObstacle': {'kind': kind.name, 'resetPolicy': 'mapInstance'},
          },
          idempotencyKey: 'legacy-set-cut',
        );
        expect(await mapFile.readAsBytes(), before);
        final applied = await mutations.apply(
          plan,
          operationId: 'legacy-set-cut',
        );
        expect(applied.receipt.status, AuthoringReceiptStatus.applied);
        final typed = await read();
        expect(
          typed.entities.single.fieldObstacle,
          MapEntityFieldObstacleData(kind: kind),
        );
        final queried = (await queries.open(root.path)).query(
          AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: ['route'],
          ),
        );
        expect(
          MapData.fromJson(
            Map<String, dynamic>.from((queried['items'] as List).single as Map),
          ),
          typed,
        );
        final beforeRefusal = await mapFile.readAsBytes();
        await expectLater(
          mutations.plan(
            root.path,
            actionId: 'entity.set_field_obstacle',
            parameters: {
              'mapId': 'route',
              'entityId': 'tree',
              'fieldObstacle': {
                'kind': kind.name,
                'resetPolicy': 'mapInstance',
                'movementPolicy': 'untilBlocked',
              },
            },
            idempotencyKey: 'invalid-policy',
          ),
          throwsA(isA<EditorAuthoringMutationFailure>()),
        );
        expect(await mapFile.readAsBytes(), beforeRefusal);
        final renamed = UpdateEntityOnMapUseCase().execute(
          typed,
          manifest: project,
          entityId: 'tree',
          name: 'Renamed',
        );
        await FileMapRepository().saveMap(
          renamed,
          mapFile.path,
          projectDialogueContext: project,
        );
        expect(
          (await read()).entities.single.fieldObstacle,
          MapEntityFieldObstacleData(kind: kind),
        );
        await mutations.closeProject(root.path);
        await queries.closeProject(root.path);
        final cleared = await mutations.plan(
          root.path,
          actionId: 'entity.set_field_obstacle',
          parameters: const {
            'mapId': 'route',
            'entityId': 'tree',
            'fieldObstacle': null,
          },
          idempotencyKey: 'legacy-clear-cut',
        );
        final removed = await mutations.apply(
          cleared,
          operationId: 'legacy-clear-cut',
        );
        expect(
          (await read()).entities.single,
          renamed.entities.single.copyWith(fieldObstacle: null),
        );
        await mutations.undo(
          root.path,
          entryId: removed.receipt.receiptId,
          idempotencyKey: 'undo-clear',
        );
        expect(await read(), renamed);
        await mutations.closeProject(root.path);
        await queries.closeProject(root.path);
        final coldQueries = AuthoringQueryAdapter(fileReader: reader);
        final coldSession = await coldQueries.open(root.path);
        expect(coldSession.maps.single, renamed);
        await coldQueries.closeProject(root.path);
        expect(await projectFile.readAsBytes(), projectBefore);
      },
    );
  }
}
