import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/use_cases/entity_use_cases.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  test(
    'legacy editor adapter consumes healing display while ordinary entity edits preserve its payload',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'legacy-healing-display-adapter-',
      );
      final root = Directory(await temporary.resolveSymbolicLinks());
      addTearDown(() => root.delete(recursive: true));
      final project = _project();
      const map = MapData(
        id: 'route',
        name: 'Route',
        size: GridSize(width: 5, height: 4),
        visualStack: MapVisualStackConfig.canonicalV1,
        entities: [
          MapEntity(
            id: 'balls',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 2, y: 1),
            blocksMovement: false,
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
        actionId: 'entity.set_healing_display',
        parameters: {
          'mapId': 'route',
          'entityId': 'balls',
          'healingDisplay': _payload().toJson(),
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
      expect(typed.entities.single.healingDisplay, _payload());
      final renamed = UpdateEntityOnMapUseCase().execute(
        typed,
        manifest: project,
        entityId: 'balls',
        name: 'Renamed',
      );
      await FileMapRepository().saveMap(
        renamed,
        mapFile.path,
        projectDialogueContext: project,
      );
      expect((await read()).entities.single.healingDisplay, _payload());
      await mutations.closeProject(root.path);
      await queries.closeProject(root.path);
      final cleared = await mutations.plan(
        root.path,
        actionId: 'entity.set_healing_display',
        parameters: const {
          'mapId': 'route',
          'entityId': 'balls',
          'healingDisplay': null,
        },
        idempotencyKey: 'legacy-clear-cut',
      );
      await mutations.apply(cleared, operationId: 'legacy-clear-cut');
      expect(
        (await read()).entities.single,
        renamed.entities.single.copyWith(healingDisplay: null),
      );
      expect(await projectFile.readAsBytes(), projectBefore);
    },
  );
}

MapEntityHealingDisplayData _payload() => MapEntityHealingDisplayData(
  variantElementIds: [for (var n = 1; n <= 6; n++) 'healing-$n'],
);
ProjectManifest _project() => ProjectManifest(
  name: 'Centre',
  maps: const [
    ProjectMapEntry(
      id: 'route',
      name: 'Centre',
      relativePath: 'maps/route.json',
    ),
  ],
  tilesets: [
    for (var sheet = 1; sheet <= 2; sheet++)
      ProjectTilesetEntry(
        id: 'healing-sheet-$sheet',
        name: 'Boules $sheet',
        relativePath: 'tilesets/healing-$sheet.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'healing-sheet-$sheet',
          pixelWidth: 256,
          pixelHeight: 192,
          tileWidth: 64,
          tileHeight: 48,
        ),
      ),
  ],
  elementCategories: const [
    ProjectElementCategory(id: 'healing', name: 'Healing'),
  ],
  elements: [
    for (var i = 1; i <= 6; i++)
      ProjectElementEntry(
        id: 'healing-$i',
        name: 'Boules $i',
        tilesetId: 'healing-sheet-${i <= 3 ? 1 : 2}',
        categoryId: 'healing',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: (i - 1) % 3 + 1),
            durationMs: 200,
          ),
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: (i - 1) % 3 + 1),
            durationMs: 200,
          ),
        ],
      ),
  ],
);
