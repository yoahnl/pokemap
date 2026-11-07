import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _route = ProjectEncounterTable(
  id: 'route_grass',
  name: 'Herbes de la route',
  encounterKind: EncounterKind.walk,
  entries: [
    ProjectEncounterEntry(
      speciesId: 'pidgey',
      minLevel: 2,
      maxLevel: 4,
      weight: 30,
    ),
    ProjectEncounterEntry(
      speciesId: 'rattata',
      minLevel: 3,
      maxLevel: 3,
      weight: 10,
    ),
  ],
);

const _guide = MapEntity(
  id: 'guide',
  name: 'Guide',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 1, y: 0),
  npc: MapEntityNpcData(trainerId: 'youngster'),
);

const _map = MapData(
  id: 'route',
  name: 'Route',
  size: GridSize(width: 2, height: 1),
  entities: [_guide],
);

ProjectManifest _project() => ProjectManifest(
  name: 'Combat borné',
  maps: const [],
  tilesets: const [],
  encounterTables: const [_route],
  trainers: [
    ProjectTrainerEntry(
      id: 'youngster',
      name: 'Gamin Joey',
      trainerClass: 'Gamin',
      team: const [ProjectTrainerPokemonEntry(speciesId: 'rattata', level: 4)],
    ),
  ],
);

List<(String, int)> _encounters(ProjectManifest project) => [
  for (var seed = 0; seed < 200; seed++)
    switch (checkEncounterFromSource(
      world: GameplayWorldState.initial(
        map: _map,
        project: project,
        playerPos: const GridPos(x: 0, y: 0),
      ),
      project: project,
      source: const EncounterSource(
        kind: EncounterSourceKind.gameplayZone,
        id: 'grass',
        priority: 0,
        encounter: EncounterZonePayload(encounterTableId: 'route_grass'),
      ),
      encounterKind: EncounterKind.walk,
      random: Random(seed),
      policy: const GameplayEncounterPolicy(chancePerStep: 1),
    ).encounter) {
      final encounter? => (encounter.speciesId, encounter.level),
      null => ('', 0),
    },
];

void main() {
  test('an authored table rolls within its species, levels and weights, unchanged by a save', () {
    final project = _project();
    final rolls = _encounters(project);
    expect(rolls.where((roll) => roll.$1.isEmpty), isEmpty);
    for (final (species, level) in rolls) {
      expect(species, anyOf('pidgey', 'rattata'));
      if (species == 'pidgey') expect(level, inInclusiveRange(2, 4));
      if (species == 'rattata') expect(level, 3);
    }
    final pidgeys = rolls.where((roll) => roll.$1 == 'pidgey').length;
    expect(pidgeys, greaterThan(rolls.length - pidgeys));
    expect(rolls.length - pidgeys, greaterThan(0));

    final saved = ProjectManifest.fromJson(
      jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
    );
    expect(saved.encounterTables.single, _route);
    expect(_encounters(saved), rolls);
  });

  test('a trainer bound to a character starts its own battle only', () {
    final project = _project();
    final world = GameplayWorldState.initial(
      map: _map,
      project: project,
      playerPos: const GridPos(x: 0, y: 0),
    );
    final request = buildTrainerBattleRequestFromNpc(
      entity: _guide,
      manifest: project,
      world: world,
      createdAtEpochMs: 1,
    );
    expect(request, isNotNull);
    expect(request!.trainerId, 'youngster');
    expect(request.npcEntityId, 'guide');
    expect(request.mapId, 'route');
    expect(
      project.trainers.single.team.single,
      const ProjectTrainerPokemonEntry(speciesId: 'rattata', level: 4),
    );
    expect(
      buildTrainerBattleRequestFromNpc(
        entity: _guide,
        manifest: project.copyWith(trainers: const []),
        world: world,
        createdAtEpochMs: 1,
      ),
      isNull,
    );
  });
}
