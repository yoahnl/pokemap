import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BETA-ENC-001 encounter contract', () {
    test('preserves rich encounter tables and zones through stable JSON', () {
      final project = _project();
      final map = _map();

      final projectJson = jsonEncode(project.toJson());
      final mapJson = jsonEncode(map.toJson());
      final restoredProject = ProjectManifest.fromJsonPokeMapBetaV1ForTest(
        jsonDecode(projectJson) as Map<String, dynamic>,
      );
      final restoredMap = MapData.fromJson(
        jsonDecode(mapJson) as Map<String, dynamic>,
      );

      expect(jsonEncode(restoredProject.toJson()), projectJson);
      expect(jsonEncode(restoredMap.toJson()), mapJson);
      expect(restoredProject.encounterTables, project.encounterTables);
      expect(restoredMap.gameplayZones, map.gameplayZones);
      ProjectValidator.validate(restoredProject);
      MapValidator.validate(
        restoredMap,
        projectDialogueContext: restoredProject,
      );
    });

    test('round-trips canonical wild Pokemon generation overrides', () {
      const entry = ProjectEncounterEntry(
        speciesId: 'eevee',
        minLevel: 12,
        maxLevel: 12,
        pokemonOverrides: ProjectEncounterPokemonOverrides(
          natureId: 'jolly',
          abilityId: 'adaptability',
          gender: 'female',
          ivs: PokemonStatSpread(
            hp: 31,
            attack: 30,
            defense: 29,
            specialAttack: 28,
            specialDefense: 27,
            speed: 26,
          ),
          shinyPolicy: ProjectEncounterShinyPolicy.never,
          knownMoveIds: <String>['tackle', 'quick_attack'],
        ),
      );

      final json = entry.toJson();
      final restored = ProjectEncounterEntry.fromJson(json);

      expect(restored, entry);
      expect(json['pokemonOverrides'], <String, Object?>{
        'natureId': 'jolly',
        'abilityId': 'adaptability',
        'gender': 'female',
        'ivs': <String, Object?>{
          'hp': 31,
          'attack': 30,
          'defense': 29,
          'specialAttack': 28,
          'specialDefense': 27,
          'speed': 26,
        },
        'shinyPolicy': 'never',
        'knownMoveIds': <String>['tackle', 'quick_attack'],
      });
    });

    test('rejects malformed wild Pokemon generation overrides before save', () {
      final project = _project(
        encounterTables: const <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'invalid_overrides',
            name: 'Invalid overrides',
            encounterKind: EncounterKind.walk,
            entries: <ProjectEncounterEntry>[
              ProjectEncounterEntry(
                speciesId: 'eevee',
                minLevel: 5,
                maxLevel: 5,
                pokemonOverrides: ProjectEncounterPokemonOverrides(
                  ivs: PokemonStatSpread(speed: 32),
                ),
              ),
            ],
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(project),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'encounter.pokemon_override_invalid',
          ),
        ),
      );
    });

    test('projects one canonical encounter weight distribution', () {
      final entries = <ProjectEncounterEntry>[
        const ProjectEncounterEntry(
          speciesId: 'zubat',
          minLevel: 5,
          maxLevel: 8,
          weight: 20,
        ),
        const ProjectEncounterEntry(
          speciesId: 'abra',
          minLevel: 7,
          maxLevel: 7,
          weight: 5,
        ),
        const ProjectEncounterEntry(
          speciesId: 'geodude',
          minLevel: 4,
          maxLevel: 6,
          weight: 25,
        ),
      ];

      final ordered = canonicalEncounterEntries(entries);
      final projection = projectEncounterProbabilities(
        chancePerStep: 0.2,
        weights: ordered.map((entry) => entry.weight),
      );

      expect(
        ordered.map((entry) => entry.speciesId),
        orderedEquals(<String>['abra', 'geodude', 'zubat']),
      );
      expect(projection.totalWeight, 50);
      expect(
        projection.entries.map((entry) => entry.relativeShare),
        orderedEquals(<double>[0.1, 0.5, 0.4]),
      );
      expect(
        projection.entries[0].resolvedChancePerStep,
        closeTo(0.02, 0.0000001),
      );
      expect(
        projection.entries[1].resolvedChancePerStep,
        closeTo(0.1, 0.0000001),
      );
      expect(
        projection.entries[2].resolvedChancePerStep,
        closeTo(0.08, 0.0000001),
      );
    });

    test('rejects every malformed encounter value with a stable code', () {
      final cases = <({String code, ProjectEncounterTable table})>[
        (
          code: 'encounter.chance_not_finite',
          table: _table(chancePerStep: double.nan),
        ),
        (code: 'encounter.chance_negative', table: _table(chancePerStep: -0.1)),
        (code: 'encounter.chance_above_one', table: _table(chancePerStep: 1.1)),
        (
          code: 'encounter.species_empty',
          table: _table(
            entries: const <ProjectEncounterEntry>[
              ProjectEncounterEntry(speciesId: ' ', minLevel: 2, maxLevel: 3),
            ],
          ),
        ),
        (
          code: 'encounter.level_non_positive',
          table: _table(
            entries: const <ProjectEncounterEntry>[
              ProjectEncounterEntry(
                speciesId: 'zubat',
                minLevel: 0,
                maxLevel: 3,
              ),
            ],
          ),
        ),
        (
          code: 'encounter.level_range_invalid',
          table: _table(
            entries: const <ProjectEncounterEntry>[
              ProjectEncounterEntry(
                speciesId: 'zubat',
                minLevel: 4,
                maxLevel: 3,
              ),
            ],
          ),
        ),
        (
          code: 'encounter.weight_non_positive',
          table: _table(
            entries: const <ProjectEncounterEntry>[
              ProjectEncounterEntry(
                speciesId: 'zubat',
                minLevel: 2,
                maxLevel: 3,
                weight: 0,
              ),
            ],
          ),
        ),
        (
          code: 'encounter.condition_invalid',
          table: _table(
            conditions: const <ScriptCondition>[
              ScriptCondition(type: ScriptConditionType.allOf),
            ],
          ),
        ),
      ];

      for (final testCase in cases) {
        expect(
          () => ProjectValidator.validate(
            _project(encounterTables: <ProjectEncounterTable>[testCase.table]),
          ),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.code,
              'code',
              testCase.code,
            ),
          ),
          reason: testCase.code,
        );
      }
    });

    test('rejects unknown and kind-incoherent zone table references', () {
      final project = _project();
      final unknown = _map(
        zones: <MapGameplayZone>[_zone(id: 'unknown', tableId: 'missing')],
      );
      final mismatch = _map(
        zones: <MapGameplayZone>[
          _zone(
            id: 'mismatch',
            tableId: 'cave_surf',
            encounterKind: EncounterKind.walk,
          ),
        ],
      );

      expect(
        () => MapValidator.validate(unknown, projectDialogueContext: project),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'encounter.table_unknown',
          ),
        ),
      );
      expect(
        () => MapValidator.validate(mismatch, projectDialogueContext: project),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'encounter.kind_mismatch',
          ),
        ),
      );
    });

    test('blocks same-kind same-priority overlaps conservatively', () {
      final project = _project(
        encounterTables: <ProjectEncounterTable>[
          _table(
            id: 'day',
            conditions: <ScriptCondition>[
              ScriptConditionFactory.flagIsSet('is_day'),
            ],
          ),
          _table(
            id: 'night',
            conditions: <ScriptCondition>[
              ScriptConditionFactory.flagIsUnset('is_day'),
            ],
          ),
        ],
      );
      final ambiguous = _map(
        zones: <MapGameplayZone>[
          _zone(id: 'day-zone', tableId: 'day'),
          _zone(
            id: 'night-zone',
            tableId: 'night',
            area: const MapRect(
              pos: GridPos(x: 2, y: 2),
              size: GridSize(width: 4, height: 4),
            ),
          ),
        ],
      );

      final restored = MapData.fromJson(
        jsonDecode(jsonEncode(ambiguous.toJson())) as Map<String, dynamic>,
      );
      for (final candidate in <MapData>[ambiguous, restored]) {
        expect(
          () =>
              MapValidator.validate(candidate, projectDialogueContext: project),
          throwsA(
            isA<ValidationException>()
                .having(
                  (error) => error.code,
                  'code',
                  'encounter.zone_ambiguous',
                )
                .having(
                  (error) => error.details['zoneIds'],
                  'zoneIds',
                  orderedEquals(<String>['day-zone', 'night-zone']),
                ),
          ),
        );
      }
    });

    test('allows overlap when encounter priorities differ', () {
      final project = _project();
      final map = _map(
        zones: <MapGameplayZone>[
          _zone(id: 'low', tableId: 'forest_walk'),
          _zone(id: 'high', tableId: 'forest_walk', priority: 1),
        ],
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: project),
        returnsNormally,
      );
    });

    test('allows equal-priority overlap for the same encounter payload', () {
      final project = _project();
      final map = _map(
        zones: <MapGameplayZone>[
          _zone(id: 'right', tableId: 'forest_walk'),
          _zone(id: 'left', tableId: 'forest_walk'),
        ],
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: project),
        returnsNormally,
      );
    });

    test('reports duplicate zone identity before overlap ambiguity', () {
      final project = _project(
        encounterTables: <ProjectEncounterTable>[
          _table(),
          _table(id: 'forest_walk_2'),
        ],
      );
      final map = _map(
        zones: <MapGameplayZone>[
          _zone(id: 'duplicate', tableId: 'forest_walk'),
          _zone(id: 'duplicate', tableId: 'forest_walk_2'),
        ],
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: project),
        throwsA(
          isA<ValidationException>()
              .having(
                (error) => error.toString(),
                'message',
                contains('Duplicate gameplay zone ID'),
              )
              .having(
                (error) => error.code,
                'code',
                isNot('encounter.zone_ambiguous'),
              ),
        ),
      );
    });
  });
}

ProjectManifest _project({List<ProjectEncounterTable>? encounterTables}) {
  return ProjectManifest(
    name: 'BETA-ENC-001 fixture',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    encounterTables:
        encounterTables ??
        <ProjectEncounterTable>[
          _table(),
          _table(
            id: 'cave_surf',
            encounterKind: EncounterKind.surf,
            chancePerStep: 0.4,
            entries: const <ProjectEncounterEntry>[
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
          ),
        ],
  );
}

ProjectEncounterTable _table({
  String id = 'forest_walk',
  EncounterKind encounterKind = EncounterKind.walk,
  double chancePerStep = 0.25,
  List<ScriptCondition> conditions = const <ScriptCondition>[],
  List<ProjectEncounterEntry> entries = const <ProjectEncounterEntry>[
    ProjectEncounterEntry(
      speciesId: 'zubat',
      minLevel: 5,
      maxLevel: 8,
      weight: 4,
    ),
    ProjectEncounterEntry(
      speciesId: 'geodude',
      minLevel: 4,
      maxLevel: 6,
      weight: 6,
    ),
  ],
}) {
  return ProjectEncounterTable(
    id: id,
    name: id,
    encounterKind: encounterKind,
    chancePerStep: chancePerStep,
    conditions: conditions,
    entries: entries,
    tags: const <String>['synthetic', 'beta-enc-001'],
  );
}

MapData _map({List<MapGameplayZone>? zones}) {
  return MapData(
    id: 'encounter_contract_map',
    name: 'Encounter contract map',
    version: ProjectVersion.v6,
    size: const GridSize(width: 12, height: 12),
    gameplayZones:
        zones ??
        <MapGameplayZone>[
          _zone(id: 'forest', tableId: 'forest_walk'),
          _zone(
            id: 'lake',
            tableId: 'cave_surf',
            encounterKind: EncounterKind.surf,
            area: const MapRect(
              pos: GridPos(x: 6, y: 6),
              size: GridSize(width: 4, height: 4),
            ),
          ),
        ],
  );
}

MapGameplayZone _zone({
  required String id,
  required String tableId,
  EncounterKind encounterKind = EncounterKind.walk,
  int priority = 0,
  MapRect area = const MapRect(
    pos: GridPos(x: 1, y: 1),
    size: GridSize(width: 4, height: 4),
  ),
}) {
  return MapGameplayZone(
    id: id,
    name: id,
    kind: GameplayZoneKind.encounter,
    area: area,
    priority: priority,
    encounter: EncounterZonePayload(
      encounterTableId: tableId,
      encounterKind: encounterKind,
    ),
  );
}
