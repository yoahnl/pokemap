import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  test('pause bag item use commits one effect and consumes exactly one item',
      () async {
    var state = const GameState(
      saveId: 'bag-use',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'lead',
            natureId: 'hardy',
            abilityId: 'steadfast',
            currentHp: 5,
          ),
        ],
      ),
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'potion',
            categoryId: 'medicine',
            quantity: 2,
          ),
          BagEntry(
            itemId: 'harbor-pass',
            categoryId: 'key-items',
            quantity: 1,
          ),
        ],
      ),
    );
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{0: 30},
      ),
    );
    addTearDown(controller.dispose);

    final used = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'potion',
        partyTargetId: 'party.0',
      ),
    );

    expect(used.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(commits, hasLength(1));
    expect(state.party.members.single.currentHp, 25);
    expect(
      state.bag.entries
          .firstWhere((entry) => entry.itemId == 'potion')
          .quantity,
      1,
    );

    final refused = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'harbor-pass',
        partyTargetId: 'party.0',
      ),
    );

    expect(refused.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(commits, hasLength(1));
    expect(
      state.bag.entries
          .firstWhere((entry) => entry.itemId == 'harbor-pass')
          .quantity,
      1,
    );
  });

  test('pause bag does not consume an item when it would have no effect',
      () async {
    const state = GameState(
      saveId: 'bag-no-effect',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'lead',
            natureId: 'hardy',
            abilityId: 'steadfast',
            currentHp: 30,
          ),
        ],
      ),
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'potion',
            categoryId: 'medicine',
            quantity: 1,
          ),
        ],
      ),
    );
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (_) async => fail('No mutation should be committed.'),
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{0: 30},
      ),
    );
    addTearDown(controller.dispose);

    final result = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'potion',
        partyTargetId: 'party.0',
      ),
    );

    expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(result.safeMessage, contains('aucun effet'));
    expect(state.bag.entries.single.quantity, 1);
  });

  test('pause bag applies an authored item evolution and saves atomically',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-pause-item-evolution-',
    );
    addTearDown(() => root.delete(recursive: true));
    await _writeEvolutionFixture(root);
    var state = const GameState(
      saveId: 'bag-evolution',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 20,
            currentHp: 20,
            nickname: 'Pousse',
            friendship: 180,
          ),
        ],
      ),
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'leaf-stone',
            categoryId: 'evolution-items',
            quantity: 1,
          ),
        ],
      ),
    );
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{0: 20},
      ),
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(
        evolutionsDir: 'custom/evolutions',
        speciesDir: 'custom/species',
      ),
    );
    addTearDown(controller.dispose);

    final result = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'leaf-stone',
        partyTargetId: 'party.0',
      ),
    );

    expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(commits, hasLength(1));
    expect(state.party.members.single.speciesId, 'bloomon');
    expect(state.party.members.single.nickname, 'Pousse');
    expect(state.party.members.single.friendship, 180);
    expect(state.bag.entries, isEmpty);
  });

  test('pause bag teaches a compatible TM with an exact replacement', () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-pause-move-machine-',
    );
    addTearDown(() => root.delete(recursive: true));
    await _writeMoveMachineFixture(root);
    var state = const GameState(
      saveId: 'bag-tm',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 20,
            currentHp: 20,
            knownMoveIds: <String>[
              'tackle',
              'growl',
              'vine-whip',
              'sleep-powder',
            ],
            currentPpByMoveId: <String, int>{
              'tackle': 30,
              'growl': 40,
              'vine-whip': 25,
              'sleep-powder': 15,
            },
          ),
        ],
      ),
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'tm-protect',
            categoryId: 'machines',
            quantity: 1,
          ),
        ],
      ),
    );
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{0: 20},
      ),
      projectRootDirectory: root.path,
      pokemonConfig: _machineConfig,
    );
    addTearDown(controller.dispose);

    final result = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'tm-protect',
        partyTargetId: 'party.0',
        moveTargetId: 'growl',
      ),
    );

    expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(commits, hasLength(1));
    expect(
      state.party.members.single.knownMoveIds,
      <String>['tackle', 'protect', 'vine-whip', 'sleep-powder'],
    );
    expect(state.party.members.single.currentPpByMoveId!['protect'], 10);
    expect(state.bag.entries, isEmpty);
  });
}

Future<void> _writeEvolutionFixture(Directory root) async {
  final evolutionFile =
      File(p.join(root.path, 'custom', 'evolutions', 'sproutle.json'));
  await evolutionFile.parent.create(recursive: true);
  await evolutionFile.writeAsString(
    jsonEncode(<String, Object?>{
      'speciesId': 'sproutle',
      'evolutions': <Object?>[
        <String, Object?>{
          'targetSpeciesId': 'bloomon',
          'method': 'use_item',
          'itemId': 'leaf-stone',
        },
      ],
    }),
  );
  final speciesFile =
      File(p.join(root.path, 'custom', 'species', 'bloomon.json'));
  await speciesFile.parent.create(recursive: true);
  await speciesFile.writeAsString(
    jsonEncode(<String, Object?>{
      'id': 'bloomon',
      'typing': <String, Object?>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 80,
        'atk': 82,
        'def': 83,
        'spa': 100,
        'spd': 100,
        'spe': 80,
      },
      'abilities': <String, Object?>{
        'primary': 'overgrow',
        'secondary': null,
        'hidden': null,
      },
      'progression': <String, Object?>{
        'growthRateId': 'medium',
        'baseExp': 100,
        'catchRate': 45,
      },
      'refs': <String, String>{'learnset': 'bloomon'},
    }),
  );
}

const _machineConfig = ProjectPokemonConfig(
  speciesDir: 'machine/species',
  learnsetsDir: 'machine/learnsets',
  catalogFiles: <String, String>{
    'items': 'machine/catalogs/items.json',
    'moves': 'machine/catalogs/moves.json',
  },
);

Future<void> _writeMoveMachineFixture(Directory root) async {
  Future<void> write(String relativePath, Map<String, Object?> json) async {
    final file = File(p.join(root.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(json));
  }

  await write('machine/catalogs/items.json', <String, Object?>{
    'catalog': 'items',
    'entries': <Object?>[
      <String, Object?>{
        'id': 'tm-protect',
        'machine': <String, Object?>{
          'kind': 'tm',
          'moveId': 'protect',
          'consumable': true,
        },
      },
    ],
  });
  await write('machine/catalogs/moves.json', <String, Object?>{
    'catalog': 'moves',
    'entries': <Object?>[
      const PokemonMove(
        id: 'protect',
        name: 'Protect',
        source: 'machine-test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      ).toJson(),
    ],
  });
  await write('machine/learnsets/sproutle.json', <String, Object?>{
    'speciesId': 'sproutle',
    'startingMoves': <String>[],
    'relearnMoves': <String>[],
    'levelUp': <Object?>[],
    'tm': <Object?>[
      <String, String>{'moveId': 'protect'},
    ],
    'hm': <Object?>[],
  });
  await write('machine/species/sproutle.json', <String, Object?>{
    'id': 'sproutle',
    'typing': <String, Object?>{
      'types': <String>['grass'],
    },
    'baseStats': <String, int>{
      'hp': 45,
      'atk': 49,
      'def': 49,
      'spa': 65,
      'spd': 65,
      'spe': 45,
    },
    'abilities': <String, Object?>{
      'primary': 'overgrow',
      'secondary': null,
      'hidden': null,
    },
    'progression': <String, Object?>{
      'growthRateId': 'medium',
      'baseExp': 64,
      'catchRate': 45,
    },
    'refs': <String, String>{'learnset': 'sproutle'},
  });
}
