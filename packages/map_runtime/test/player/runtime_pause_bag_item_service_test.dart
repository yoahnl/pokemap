import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

ItemCatalogSnapshot _catalogWith(List<ProjectItemDefinition> entries) {
  return ItemCatalogSnapshot.fromCatalog(
    ProjectItemCatalog(
      schemaVersion: 1,
      entries: <ProjectItemDefinition>[...mvpItemCatalog.entries, ...entries],
    ),
  );
}

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
            quantity: 2,
          ),
          BagEntry(
            itemId: 'harbor-pass',
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
      itemCatalog: _catalogWith(
        const <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'harbor-pass',
            displayName: 'Harbor Pass',
            pocketId: 'key-items',
            tags: <String>{'key-item', 'passive'},
          ),
        ],
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

  test('pause bag refuses a scene that becomes active before commit', () async {
    var state = const GameState(
      saveId: 'bag-scene-interlock',
      party: PlayerParty(members: [
        PlayerPokemon(
            speciesId: 'lead',
            individualId: 'lead',
            natureId: 'hardy',
            abilityId: 'steadfast',
            currentHp: 11),
      ]),
      bag: Bag(entries: [BagEntry(itemId: 'potion', quantity: 3)]),
    );
    final original = state;
    var sceneActive = false;
    var activateSceneDuringCaps = true;
    var commits = 0;
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits++;
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async {
        if (activateSceneDuringCaps) sceneActive = true;
        return const RuntimePlayerServiceRecoveryCaps(
            maxHpByPartyIndex: {0: 34});
      },
      itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
    );
    controller.setPauseMutationGuard(() => sceneActive
        ? 'Terminez la scène en cours avant de modifier le sac.'
        : null);
    addTearDown(controller.dispose);
    const command = RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'potion', partyTargetId: 'pokemon.lead');
    final refused = await controller.useBagItemOutsideBattle(command);
    expect(refused.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(refused.safeMessage, contains('scène'));
    expect(commits, 0);
    expect(state, same(original));
    expect((await controller.useBagItemOutsideBattle(command)).status,
        RuntimePlayerPauseCommandStatus.unavailable);
    sceneActive = false;
    activateSceneDuringCaps = false;
    final accepted = await controller.useBagItemOutsideBattle(command);
    expect(accepted.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(commits, 1);
    expect(state.party.members.single.currentHp, 31);
    expect(state.bag.entries.single.quantity, 2);
  });

  test('replaying the same bag command heals again or refuses, never doubles',
      () async {
    // BETA-ITM-004 « fermeture/rebuild ne rejoue pas la commande » : un
    // double dispatch (double-clic, rebuild de dialogue) est soit un
    // DEUXIÈME soin légitime sur une cible encore blessée — consommant un
    // DEUXIÈME objet, jamais le même — soit un refus sans effet quand la
    // cible est au maximum. Aucun chemin ne consomme sans soigner.
    var state = const GameState(
      saveId: 'bag-replay',
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
          BagEntry(itemId: 'potion', quantity: 3),
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
      itemCatalog: _catalogWith(const <ProjectItemDefinition>[]),
    );
    addTearDown(controller.dispose);

    const command = RuntimePlayerPauseCommand.useBagItem(
      itemTargetId: 'potion',
      partyTargetId: 'party.0',
    );

    final first = await controller.useBagItemOutsideBattle(command);
    expect(first.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(state.party.members.single.currentHp, 25);

    final second = await controller.useBagItemOutsideBattle(command);
    expect(second.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(state.party.members.single.currentHp, 30,
        reason: 'the second heal caps at max HP');
    expect(commits, hasLength(2));
    expect(state.bag.entries.single.quantity, 1,
        reason: 'each accepted heal consumes exactly one potion');

    final third = await controller.useBagItemOutsideBattle(command);
    expect(third.status, RuntimePlayerPauseCommandStatus.unavailable,
        reason: 'a full-HP target refuses the heal');
    expect(commits, hasLength(2));
    expect(state.bag.entries.single.quantity, 1,
        reason: 'a refused replay never consumes');
  });

  test('pause bag command resolves its individual after a party reorder',
      () async {
    var state = const GameState(
      saveId: 'bag-stable-target',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            individualId: 'pkm_other',
            speciesId: 'other',
            natureId: 'hardy',
            abilityId: 'steadfast',
            currentHp: 20,
          ),
          PlayerPokemon(
            individualId: 'pkm_target',
            speciesId: 'target',
            natureId: 'hardy',
            abilityId: 'steadfast',
            currentHp: 5,
          ),
        ],
      ),
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(itemId: 'potion', quantity: 1),
        ],
      ),
    );
    const staleTargetId = 'pokemon.pkm_target';
    state = state.copyWith(
      party: PlayerParty(
        members: <PlayerPokemon>[
          state.party.members[1],
          state.party.members[0],
        ],
      ),
    );
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async => state = next,
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{0: 30, 1: 30},
      ),
      itemCatalog: _catalogWith(const <ProjectItemDefinition>[]),
    );
    addTearDown(controller.dispose);

    final used = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'potion',
        partyTargetId: staleTargetId,
      ),
    );

    expect(used.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(state.party.members[0].individualId, 'pkm_target');
    expect(state.party.members[0].currentHp, 25);
    expect(state.party.members[1].currentHp, 20);
  });

  test('pause bag uses a custom pocket item through its authored capability',
      () async {
    var state = const GameState(
      saveId: 'custom-pocket-use',
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
          BagEntry(itemId: 'field-tonic', quantity: 1),
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
      itemCatalog: _catalogWith(
        const <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'field-tonic',
            displayName: 'Field Tonic',
            pocketId: 'expedition-supplies',
            uses: <ProjectItemUseDefinition>[
              ProjectItemUseDefinition(
                contexts: <ProjectItemUseContext>{
                  ProjectItemUseContext.overworld,
                },
                target: ProjectItemTargetKind.partyMember,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.healHp(
                  mode: ProjectItemAmountMode.flat,
                  amount: 17,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    final refused = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'field-tonic',
        partyTargetId: 'party.9',
      ),
    );

    expect(refused.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(commits, isEmpty);
    expect(state.bag.entries.single.quantity, 1);

    final used = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'field-tonic',
        partyTargetId: 'party.0',
      ),
    );

    expect(used.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(commits, hasLength(1));
    expect(state.party.members.single.currentHp, 22);
    expect(state.bag.entries, isEmpty);
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
      itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
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
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        evolutionsDir: 'custom/evolutions',
        speciesDir: 'custom/species',
      ),
      itemCatalog: _catalogWith(
        const <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'leaf-stone',
            displayName: 'Leaf Stone',
            pocketId: 'evolution-items',
            tags: <String>{'evolution'},
          ),
        ],
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

  test('passive custom item is not guessed to be an evolution item', () async {
    final root = await Directory.systemTemp.createTemp(
      'runtime-pause-passive-item-',
    );
    addTearDown(() => root.delete(recursive: true));
    const state = GameState(
      saveId: 'bag-passive',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            currentHp: 20,
          ),
        ],
      ),
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(itemId: 'lucky-charm', quantity: 1),
        ],
      ),
    );
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (_) async {},
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{0: 20},
      ),
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        evolutionsDir: 'custom/evolutions',
      ),
      itemCatalog: _catalogWith(
        const <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'lucky-charm',
            displayName: 'Lucky Charm',
            pocketId: 'charms',
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    final result = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'lucky-charm',
        partyTargetId: 'party.0',
      ),
    );

    expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(state.bag.entries.single.quantity, 1);
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
      itemCatalog: _catalogWith(
        const <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'tm-protect',
            displayName: 'TM Protect',
            pocketId: 'machines',
            machine: ProjectMoveMachineItemDefinition(
              moveId: 'protect',
              kind: ProjectMoveMachineKind.tm,
              consumable: true,
            ),
          ),
        ],
      ),
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
      'schemaVersion': 1,
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
      'schemaVersion': 1,
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
  ruleset: PokemonRulesetProfile.pokeMapBetaV1,
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
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
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
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
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
    'schemaVersion': 1,
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
    'schemaVersion': 1,
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
