import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/driver/runtime_evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_command_dispatcher.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_scenario_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('battle item scenario accepts numeric lineup and move slots', () {
    final scenario = const EvaluationScenarioParser().parseString(
      _scenario(1, 1),
    );
    final step = scenario.steps.single as EvaluationCommandStep;
    expect(step.arguments['targetLineupIndex'], 1);
    expect(step.arguments['targetMoveIndex'], 1);
    for (final invalid in [-1, 1.5, '1']) {
      expect(
        () =>
            const EvaluationScenarioParser().parseString(_scenario(1, invalid)),
        throwsA(isA<EvaluationScenarioFormatException>()),
      );
    }
  });

  test(
    'playtest selects requested item and reserve move without phantom turns',
    () async {
      final owner = await _driver();
      addTearDown(owner.dispose);
      final driver = RuntimeEvaluationDriver.attach(
        game: owner.game,
        project: owner.project,
        projectRoot: owner.projectRoot,
        services: _UnusedServices(),
      );
      addTearDown(driver.dispose);
      final game = driver.game;
      final map = MapData.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            await File('${driver.projectRoot.path}/arena.json').readAsString(),
          ) as Map,
        ),
      );
      await game.debugOpenBattleForTest(
        buildBattleStartRequestFromEncounter(
          encounter: const GameplayEncounter(
            mapId: 'arena',
            sourceId: 'encounter',
            sourceKind: EncounterSourceKind.gameplayZone,
            tableId: 'encounters',
            encounterKind: EncounterKind.walk,
            speciesId: 'unit',
            level: 2,
            minLevel: 2,
            maxLevel: 2,
            weight: 1,
            playerPos: GridPos(x: 1, y: 1),
          ),
          world: GameplayWorldState.fromMap(
            map,
            project: driver.project,
            tileWidth: 16,
            tileHeight: 16,
          ),
          createdAtEpochMs: 1,
        ),
      );
      await game.debugWaitForBattleOverlaySync();
      await _ready(game);
      expect(game.debugPsdkBattleSessionActive, isTrue);
      final before = game.debugBattleSessionSnapshot;
      expect(driver.state.party.members[1].knownMoveIds, ['strike', 'guard']);
      expect(before!.state.playerReserve.single.moves.map((move) => move.id), [
        'strike',
        'guard',
      ]);
      final beforeBag = driver.state.bag;
      for (final args in [
        <String, Object?>{'itemId': 'z-pp-tool', 'targetLineupIndex': 1},
        <String, Object?>{
          'itemId': 'z-pp-tool',
          'targetLineupIndex': 1,
          'targetMoveIndex': 2,
        },
        <String, Object?>{
          'itemId': 'z-pp-tool',
          'targetLineupIndex': 9,
          'targetMoveIndex': 1,
        },
      ]) {
        await expectLater(
          _item(driver, args),
          throwsA(isA<EvaluationDriverFailure>()),
        );
        expect(game.debugBattleSessionSnapshot, same(before));
        expect(driver.state.bag, beforeBag);
      }
      await _item(driver, {
        'itemId': 'z-pp-tool',
        'targetLineupIndex': 1,
        'targetMoveIndex': 1,
      });
      expect(driver.state.party.members[1].currentPpByMoveId, {
        'strike': 20,
        'guard': 7,
      });
      expect(driver.state.party.members[0].currentPpByMoveId!['strike'], 5);
      expect(_quantity(driver, 'z-pp-tool'), 1);
      expect(_quantity(driver, 'a-hp-tool'), 2);
      expect(
        game.debugBattleSessionSnapshot!.state.enemy.moves.first.currentPp,
        before.state.enemy.moves.first.currentPp - 1,
      );
      await _ready(game);
      _select(game, 2);
      game.update(0.05);
      await Future<void>.delayed(Duration.zero);
      _select(game, 1);
      await _ready(game);
      expect(game.debugBattleSessionSnapshot!.state.player.lineupIndex, 1);
      await _item(driver, {
        'itemId': 'z-pp-tool',
        'targetLineupIndex': 0,
        'targetMoveIndex': 0,
      });
      expect(driver.state.party.members[0].currentPpByMoveId!['strike'], 12);
      expect(driver.state.party.members[1].currentPpByMoveId!['guard'], 7);
      expect(_quantity(driver, 'z-pp-tool'), 0);
      final reserveHp = driver.state.party.members[0].currentHp;
      await _item(driver, {'itemId': 'a-hp-tool'});
      expect(_quantity(driver, 'a-hp-tool'), 1);
      expect(driver.state.party.members[0].currentHp, reserveHp);
      expect(driver.state.party.members[1].currentPpByMoveId!['guard'], 7);
    },
  );
}

Future<void> _item(
  RuntimeEvaluationDriver driver,
  Map<String, Object?> arguments,
) => const EvaluationCommandDispatcher().execute(
  driver: driver,
  commandId: 'recharge',
  operation: 'battle.useItem',
  arguments: arguments,
);

int _quantity(RuntimeEvaluationDriver driver, String id) => driver
    .state
    .bag
    .entries
    .where((entry) => entry.itemId == id)
    .fold(0, (sum, entry) => sum + entry.quantity);

void _select(PlayableMapGame game, int index) {
  final snapshot = game.battleCommandOverlayListenable.value!;
  expect(game.dispatchBattlePresentationCommand(BattleSelectEntryCommand(
    snapshotRevision: snapshot.revision, expectedMode: snapshot.mode, entryIndex: index,
  )), isTrue);
}

String _scenario(Object lineup, Object move) => jsonEncode({
  'schemaVersion': 1,
  'id': 'pp.slots',
  'title': 'PP slots',
  'projectId': 'generic',
  'policy': 'certify',
  'start': {'newGame': true},
  'steps': [
    {
      'id': 'restore',
      'command': 'battle.useItem',
      'itemId': 'z-pp-tool',
      'targetLineupIndex': lineup,
      'targetMoveIndex': move,
    },
  ],
});

Future<void> _ready(PlayableMapGame game) async {
  for (var i = 0; i < 1000; i++) {
    game.update(0.05);
    await Future<void>.delayed(Duration.zero);
    final snapshot = game.battleCommandOverlayListenable.value;
    if (snapshot?.interactionsEnabled == true &&
        snapshot!.mode == BattleCommandOverlayMode.root) {
      return;
    }
    if (snapshot?.interactionsEnabled == true && snapshot!.canGoBack) {
      game.dispatchBattlePresentationCommand(
        BattleBackCommand(
          snapshotRevision: snapshot.revision,
          expectedMode: snapshot.mode,
        ),
      );
    }
  }
  throw StateError('The initial battle menu is not ready.');
}

Future<RuntimeEvaluationDriver> _driver() async {
  final root = await Directory.systemTemp.createTemp('generic-pp-playtest-');
  addTearDown(() => root.delete(recursive: true));
  final project = ProjectManifest(
    name: 'Generic PP',
    maps: const [
      ProjectMapEntry(id: 'arena', name: 'Arena', relativePath: 'arena.json'),
    ],
    tilesets: const [],
    pokemon: const ProjectPokemonConfig(
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      catalogFiles: {
        'moves': 'data/pokemon/catalogs/moves.json',
        'items': 'data/pokemon/catalogs/items.json',
      },
    ),
    newGame: ProjectNewGameConfig(
      enabled: true,
      startMapId: 'arena',
      startSpawnId: 'start',
      initialBag: const [
        BagEntry(itemId: 'z-pp-tool', quantity: 2),
        BagEntry(itemId: 'a-hp-tool', quantity: 2),
      ],
      initialParty: const [
        PlayerPokemon(
          speciesId: 'unit',
          natureId: 'hardy',
          abilityId: 'sturdy',
          level: 50,
          currentHp: 100,
          knownMoveIds: ['strike'],
          currentPpByMoveId: {'strike': 5},
        ),
        PlayerPokemon(
          speciesId: 'unit',
          natureId: 'hardy',
          abilityId: 'sturdy',
          level: 50,
          currentHp: 80,
          knownMoveIds: ['strike', 'guard'],
          currentPpByMoveId: {'strike': 20, 'guard': 0},
        ),
      ],
    ),
  );
  await _json(root, 'project.json', project.toJson());
  await _json(
    root,
    'arena.json',
    MapData(
      id: 'arena',
      name: 'Arena',
      size: const GridSize(width: 4, height: 4),
      entities: const [
        MapEntity(
          id: 'start',
          name: 'Start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
        ),
      ],
    ).toJson(),
  );
  await _json(root, 'data/pokemon/species/unit.json', {
    'schemaVersion': 1,
    'id': 'unit',
    'typing': {
      'types': ['normal'],
    },
    'baseStats': {
      'hp': 45,
      'atk': 49,
      'def': 49,
      'spa': 65,
      'spd': 65,
      'spe': 45,
    },
    'abilities': {'primary': 'sturdy'},
    'progression': {
      'growthRateId': 'medium_slow',
      'baseExp': 64,
      'catchRate': 45,
    },
  });
  await _json(root, 'data/pokemon/learnsets/unit.json', {
    'schemaVersion': 1,
    'speciesId': 'unit',
    'startingMoves': ['strike'],
    'levelUp': [],
  });
  await _json(root, 'data/pokemon/catalogs/moves.json', {
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
    'catalog': 'moves',
    'entries': [
      const PokemonMove(
        id: 'strike',
        name: 'Strike',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        basePower: 5,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      ).toJson(),
      const PokemonMove(
        id: 'guard',
        name: 'Guard',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        basePower: 5,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 35,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      ).toJson(),
    ],
  });
  await _json(
    root,
    'data/pokemon/catalogs/items.json',
    ProjectItemCatalog(
      schemaVersion: 1,
      entries: [
        ProjectItemDefinition(
          id: 'z-pp-tool',
          displayName: 'Recharge',
          pocketId: 'medicine',
          uses: [
            ProjectItemUseDefinition(
              contexts: {ProjectItemUseContext.battle},
              target: ProjectItemTargetKind.partyMove,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.restorePp(
                mode: ProjectItemAmountMode.flat,
                amount: 7,
              ),
            ),
          ],
        ),
        ProjectItemDefinition(
          id: 'a-hp-tool',
          displayName: 'Care',
          pocketId: 'medicine',
          uses: [
            ProjectItemUseDefinition(
              contexts: {ProjectItemUseContext.battle},
              target: ProjectItemTargetKind.partyMember,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.healHp(
                mode: ProjectItemAmountMode.flat,
                amount: 20,
              ),
            ),
          ],
        ),
      ],
    ).toJson(),
  );
  return RuntimeEvaluationDriver.start(projectRoot: root);
}

Future<void> _json(Directory root, String path, Object value) async {
  final file = File('${root.path}/$path');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(value));
}

final class _UnusedServices implements EvaluationPlayerServiceAutomation {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
