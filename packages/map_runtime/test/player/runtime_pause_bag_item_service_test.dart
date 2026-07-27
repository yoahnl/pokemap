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
