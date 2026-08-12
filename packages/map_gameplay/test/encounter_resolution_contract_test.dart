import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('BETA-ENC-001 runtime encounter resolution', () {
    test('returns a typed ambiguity instead of using zone list order', () {
      final project = _project();
      final firstOrder = _world(<MapGameplayZone>[
        _zone(id: 'alpha', tableId: 'alpha'),
        _zone(id: 'beta', tableId: 'beta'),
      ]);
      final reversedOrder = _world(firstOrder.map.gameplayZones.reversed);

      final first = _check(firstOrder, project, seed: 41);
      final reversed = _check(reversedOrder, project, seed: 41);

      expect(first.status, GameplayEncounterCheckStatus.ambiguousZone);
      expect(reversed.status, GameplayEncounterCheckStatus.ambiguousZone);
      expect(first.ambiguousZoneIds, <String>['alpha', 'beta']);
      expect(reversed.ambiguousZoneIds, <String>['alpha', 'beta']);
      expect(first.encounter, isNull);
      expect(reversed.encounter, isNull);
    });

    test('selects the higher-priority zone independently from list order', () {
      final project = _project();
      final zones = <MapGameplayZone>[
        _zone(id: 'low', tableId: 'alpha'),
        _zone(id: 'high', tableId: 'beta', priority: 4),
      ];

      final first = _check(_world(zones), project, seed: 91);
      final reversed = _check(_world(zones.reversed), project, seed: 91);

      expect(first.status, GameplayEncounterCheckStatus.triggered);
      expect(first.zoneId, 'high');
      expect(first.tableId, 'beta');
      expect(first.encounterKind, EncounterKind.walk);
      expect(first.encounter?.toJson(), reversed.encounter?.toJson());
    });

    test('selects a canonical zone when equal-priority payloads are identical',
        () {
      final project = _project();
      final zones = <MapGameplayZone>[
        _zone(id: 'zeta', tableId: 'alpha'),
        _zone(id: 'alpha', tableId: 'alpha'),
      ];

      final first = _check(_world(zones), project, seed: 91);
      final reversed = _check(_world(zones.reversed), project, seed: 91);

      expect(first.status, GameplayEncounterCheckStatus.triggered);
      expect(first.zoneId, 'alpha');
      expect(first.tableId, 'alpha');
      expect(reversed.zoneId, first.zoneId);
      expect(reversed.encounter?.toJson(), first.encounter?.toJson());
    });

    test('same seed is stable across entry order and different seeds can vary',
        () {
      final project = _project();
      final reordered = project.copyWith(
        encounterTables: <ProjectEncounterTable>[
          for (final table in project.encounterTables)
            table.copyWith(entries: table.entries.reversed.toList()),
        ],
      );
      final world = _world(<MapGameplayZone>[
        _zone(id: 'only', tableId: 'alpha'),
      ]);

      final original = _check(world, project, seed: 8122026);
      final repeated = _check(world, project, seed: 8122026);
      final reorderedResult = _check(world, reordered, seed: 8122026);

      expect(original.status, GameplayEncounterCheckStatus.triggered);
      expect(original.zoneId, 'only');
      expect(original.tableId, 'alpha');
      expect(original.encounterKind, EncounterKind.walk);
      expect(original.encounter?.speciesId, 'zubat');
      expect(original.encounter?.level, 7);
      expect(repeated.encounter?.toJson(), original.encounter?.toJson());
      expect(reorderedResult.encounter?.toJson(), original.encounter?.toJson());

      final outcomes = <String>{
        for (var seed = 0; seed < 64; seed++)
          _check(world, project, seed: seed).encounter!.toJson().toString(),
      };
      expect(outcomes.length, greaterThan(1));
    });

    test('evaluates authored flag and typed fact conditions before selection',
        () {
      final conditioned = _project().copyWith(
        encounterTables: <ProjectEncounterTable>[
          _project().encounterTables.first.copyWith(
            conditions: <ScriptCondition>[
              ScriptConditionFactory.flagIsSet('forest_open'),
              ScriptConditionFactory.factEquals(
                'fact_weather',
                const NarrativeValue.string('rain'),
              ),
            ],
          ),
          _project().encounterTables.last,
        ],
      );
      final world = _world(<MapGameplayZone>[
        _zone(id: 'conditioned', tableId: 'alpha'),
      ]);
      final context = ScriptEvaluationContext(
        narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts([
          NarrativeFactDefinition(
            id: 'fact_weather',
            label: 'Weather',
            initialValue: NarrativeValue.string('sun'),
          ),
        ]),
      );

      final blocked = checkEncounterAtPlayerPosition(
        world: world,
        project: conditioned,
        encounterKind: EncounterKind.walk,
        gameState: const GameState(saveId: 'blocked'),
        conditionContext: context,
        random: Random(7),
      );
      final active = checkEncounterAtPlayerPosition(
        world: world,
        project: conditioned,
        encounterKind: EncounterKind.walk,
        gameState: GameState(
          saveId: 'active',
          storyFlags: StoryFlags(activeFlags: <String>{'forest_open'}),
          narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
            valuesByFactId: <String, NarrativeValue>{
              'fact_weather': NarrativeValue.string('rain'),
            },
          ),
        ),
        conditionContext: context,
        random: Random(7),
      );

      expect(blocked.status, GameplayEncounterCheckStatus.conditionsNotMet);
      expect(active.status, GameplayEncounterCheckStatus.triggered);
      expect(active.zoneId, 'conditioned');
      expect(active.tableId, 'alpha');
      expect(active.encounter?.speciesId, isNotEmpty);
      expect(active.encounter?.level, inInclusiveRange(2, 8));
    });
  });
}

GameplayEncounterCheckResult _check(
  GameplayWorldState world,
  ProjectManifest project, {
  required int seed,
}) {
  return checkEncounterAtPlayerPosition(
    world: world,
    project: project,
    encounterKind: EncounterKind.walk,
    gameState: const GameState(saveId: 'deterministic'),
    random: Random(seed),
  );
}

ProjectManifest _project() {
  return const ProjectManifest(
    name: 'BETA-ENC-001 runtime fixture',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'alpha',
        name: 'Alpha',
        encounterKind: EncounterKind.walk,
        chancePerStep: 1,
        entries: <ProjectEncounterEntry>[
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
      ),
      ProjectEncounterTable(
        id: 'beta',
        name: 'Beta',
        encounterKind: EncounterKind.walk,
        chancePerStep: 1,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'pikachu',
            minLevel: 6,
            maxLevel: 9,
            weight: 2,
          ),
          ProjectEncounterEntry(
            speciesId: 'oddish',
            minLevel: 4,
            maxLevel: 5,
            weight: 3,
          ),
        ],
      ),
    ],
  );
}

GameplayWorldState _world(Iterable<MapGameplayZone> zones) {
  final project = _project();
  return GameplayWorldState.initial(
    map: MapData(
      id: 'runtime_encounter_map',
      name: 'Runtime encounter map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 10, height: 10),
      gameplayZones: zones.toList(growable: false),
    ),
    playerPos: const GridPos(x: 2, y: 2),
    project: project,
  );
}

MapGameplayZone _zone({
  required String id,
  required String tableId,
  int priority = 0,
}) {
  return MapGameplayZone(
    id: id,
    name: id,
    kind: GameplayZoneKind.encounter,
    area: const MapRect(
      pos: GridPos(x: 1, y: 1),
      size: GridSize(width: 4, height: 4),
    ),
    priority: priority,
    encounter: EncounterZonePayload(
      encounterTableId: tableId,
      encounterKind: EncounterKind.walk,
    ),
  );
}
