import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/encounter_table_persistence_gateway.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'authors, persists, previews and executes one encounter truth',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'beta_enc_001_editor_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      const project = ProjectManifest(
        name: 'BETA-ENC-001 editor fixture',
        version: ProjectVersion.v6,
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'forest',
            name: 'Forest',
            relativePath: 'maps/forest.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[],
      );
      const map = MapData(
        id: 'forest',
        name: 'Forest',
        version: ProjectVersion.v6,
        size: GridSize(width: 8, height: 8),
      );
      final projectPath = p.join(root.path, 'project.json');
      final mapPath = p.join(root.path, 'maps', 'forest.json');
      await FileProjectRepository().saveProject(project, projectPath);
      await FileMapRepository().saveMap(
        map,
        mapPath,
        projectDialogueContext: project,
      );
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(mutations.closeAll);
      addTearDown(queries.closeAll);
      final gateway = CanonicalEncounterTablePersistenceGateway(
        mutations: mutations,
        queries: queries,
      );
      final walk = ProjectEncounterTable(
        id: 'forest_walk',
        name: 'Forest walk',
        encounterKind: EncounterKind.walk,
        chancePerStep: 1,
        conditions: <ScriptCondition>[
          ScriptConditionFactory.flagIsSet('forest_open'),
          ScriptConditionFactory.factEquals(
            'fact_weather',
            const NarrativeValue.string('rain'),
          ),
        ],
        entries: const <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'zubat',
            minLevel: 5,
            maxLevel: 8,
            weight: 4,
          ),
          ProjectEncounterEntry(
            speciesId: 'abra',
            minLevel: 7,
            maxLevel: 7,
            weight: 1,
          ),
          ProjectEncounterEntry(
            speciesId: 'geodude',
            minLevel: 2,
            maxLevel: 4,
            weight: 5,
          ),
        ],
        tags: const <String>['synthetic', 'beta-enc-001'],
      );
      const surf = ProjectEncounterTable(
        id: 'lake_surf',
        name: 'Lake surf',
        encounterKind: EncounterKind.surf,
        chancePerStep: 0.35,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'tentacool',
            minLevel: 8,
            maxLevel: 12,
            weight: 7,
          ),
          ProjectEncounterEntry(
            speciesId: 'psyduck',
            minLevel: 10,
            maxLevel: 14,
            weight: 3,
          ),
        ],
      );
      final withWalk = await gateway.upsert(
        projectRootPath: root.path,
        expectedProject: project,
        table: walk,
      );
      await gateway.upsert(
        projectRootPath: root.path,
        expectedProject: withWalk,
        table: surf,
      );
      const zones = <MapGameplayZone>[
        MapGameplayZone(
          id: 'forest-zone-low',
          name: 'Forest zone low',
          kind: GameplayZoneKind.encounter,
          area: MapRect(
            pos: GridPos(x: 0, y: 0),
            size: GridSize(width: 4, height: 4),
          ),
          encounter: EncounterZonePayload(
            encounterTableId: 'forest_walk',
            encounterKind: EncounterKind.walk,
          ),
        ),
        MapGameplayZone(
          id: 'forest-zone-high',
          name: 'Forest zone high',
          kind: GameplayZoneKind.encounter,
          area: MapRect(
            pos: GridPos(x: 1, y: 1),
            size: GridSize(width: 4, height: 4),
          ),
          priority: 2,
          encounter: EncounterZonePayload(
            encounterTableId: 'forest_walk',
            encounterKind: EncounterKind.walk,
          ),
        ),
      ];
      for (final zone in zones) {
        final operationId = 'beta_enc_001_editor_${zone.id}';
        final zonePlan = await mutations.plan(
          root.path,
          actionId: 'gameplay_zone.create',
          parameters: <String, Object?>{
            'mapId': map.id,
            'zone': jsonDecode(jsonEncode(zone.toJson())),
          },
          idempotencyKey: operationId,
        );
        await mutations.apply(zonePlan, operationId: operationId);
      }

      final restoredProject = await FileProjectRepository().loadProject(
        projectPath,
      );
      final restoredMap = await FileMapRepository().loadMap(mapPath);
      final restoredWalk = restoredProject.encounterTables.singleWhere(
        (table) => table.id == walk.id,
      );
      final projection = projectEncounterProbabilities(
        chancePerStep: restoredWalk.chancePerStep,
        weights: canonicalEncounterEntries(
          restoredWalk.entries,
        ).map((entry) => entry.weight),
      );
      final result = checkEncounterAtPlayerPosition(
        world: GameplayWorldState.initial(
          map: restoredMap,
          playerPos: const GridPos(x: 1, y: 1),
          project: restoredProject,
        ),
        project: restoredProject,
        encounterKind: EncounterKind.walk,
        gameState: GameState(
          saveId: 'beta-enc-001',
          storyFlags: const StoryFlags(activeFlags: <String>{'forest_open'}),
          narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
            valuesByFactId: const <String, NarrativeValue>{
              'fact_weather': NarrativeValue.string('rain'),
            },
          ),
        ),
        conditionContext: ScriptEvaluationContext(
          narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts([
            NarrativeFactDefinition(
              id: 'fact_weather',
              label: 'Weather',
              initialValue: const NarrativeValue.string('sun'),
            ),
          ]),
        ),
        random: Random(8122026),
      );

      expect(restoredProject.encounterTables, <ProjectEncounterTable>[
        walk,
        surf,
      ]);
      expect(restoredMap.gameplayZones, zones);
      expect(projection.totalWeight, 10);
      expect(
        projection.entries.map((entry) => entry.relativeShare),
        orderedEquals(<double>[0.1, 0.5, 0.4]),
      );
      expect(result.status, GameplayEncounterCheckStatus.triggered);
      expect(result.sourceId, 'forest-zone-high');
      expect(result.sourceKind, EncounterSourceKind.gameplayZone);
      expect(result.tableId, 'forest_walk');
      expect(result.encounterKind, EncounterKind.walk);
      expect(result.encounter?.speciesId, isNotEmpty);
      expect(result.encounter?.level, inInclusiveRange(2, 8));
    },
  );
}
