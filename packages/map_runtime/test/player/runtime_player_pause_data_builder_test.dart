import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/player/runtime_player_pause_data.dart';
import 'package:map_runtime/src/player/runtime_player_pause_data_builder.dart';
import 'package:map_runtime/src/player/runtime_regional_map.dart';

ItemCatalogSnapshot _catalogWith(List<ProjectItemDefinition> entries) {
  return ItemCatalogSnapshot.fromCatalog(
    ProjectItemCatalog(
      schemaVersion: 1,
      entries: <ProjectItemDefinition>[...mvpItemCatalog.entries, ...entries],
    ),
  );
}

void main() {
  test('builds party bag and Pokedex details from the live game state',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'pokemap-runtime-pause-data-',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    final speciesDirectory = Directory(
      '${projectRoot.path}/data/pokemon/species',
    );
    await speciesDirectory.create(recursive: true);
    await _writeSpecies(
      speciesDirectory,
      fileName: '001-bulbasaur.json',
      id: 'bulbasaur',
      nationalDex: 1,
      names: const <String, String>{
        'en': 'Bulbasaur',
        'fr': 'Bulbizarre',
      },
      types: const <String>['grass', 'poison'],
      baseHp: 45,
    );
    await _writeSpecies(
      speciesDirectory,
      fileName: '004-charmander.json',
      id: 'charmander',
      nationalDex: 4,
      names: const <String, String>{
        'en': 'Charmander',
        'fr': 'Salamèche',
      },
      types: const <String>['fire'],
      baseHp: 39,
    );
    final state = GameState(
      saveId: 'save-1',
      currentMapId: 'route',
      party: const PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'charmander',
            natureId: 'hardy',
            abilityId: 'blaze',
            level: 16,
            currentHp: 38,
            knownMoveIds: <String>['scratch', 'ember'],
            nickname: 'Flamme',
            friendship: 92,
            provenance: PlayerPokemonProvenance(
              kind: PlayerPokemonOriginKind.gift,
              mapId: 'town',
              sourceId: 'professor',
              metLevel: 5,
            ),
          ),
        ],
      ),
      bag: const Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'potion',
            quantity: 3,
          ),
          BagEntry(
            itemId: 'harbor-pass',
            quantity: 1,
          ),
        ],
      ),
      progression: const PlayerProgression(
        seenSpeciesIds: <String>['bulbasaur'],
      ),
      narrativeEventProgress: NarrativeEventProgress(
        visitedNarrativeMapIds: const <String>['town'],
      ),
    );

    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: state,
      projectRootDirectory: projectRoot.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
      locale: 'fr',
      mapEnabled: true,
      projectMaps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'town',
          name: 'Bourg Selbrume',
          relativePath: 'maps/town.json',
          sortOrder: 10,
        ),
        ProjectMapEntry(
          id: 'route',
          name: 'Route des Brumes',
          relativePath: 'maps/route.json',
          sortOrder: 20,
        ),
        ProjectMapEntry(
          id: 'cave',
          name: 'Grotte du Phare',
          relativePath: 'maps/cave.json',
          sortOrder: 30,
        ),
      ],
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

    final party = details[RuntimePlayerPauseSection.party]!;
    expect(party.entries, hasLength(1));
    expect(party.entries.single.title, 'Flamme');
    expect(party.entries.single.subtitle, contains('Salamèche'));
    expect(party.entries.single.subtitle, contains('Niv. 16'));
    expect(party.entries.single.subtitle, contains('PV 38/38'));
    expect(party.entries.single.subtitle, contains('Amitié 92/255'));
    expect(party.entries.single.subtitle, contains('Cadeau'));
    expect(party.entries.single.subtitle, contains('Town'));
    expect(party.entries.single.progress, 1);

    final bag = details[RuntimePlayerPauseSection.bag]!;
    expect(bag.entries, hasLength(2));
    final potion = bag.entries.firstWhere((entry) => entry.title == 'Potion');
    expect(potion.trailingLabel, '×3');
    expect(potion.bagAction?.isEnabled, isTrue);
    expect(
      potion.bagAction?.targetKind,
      RuntimePlayerBagUseTargetKind.partyMember,
    );
    expect(bag.bagTargets.single.targetId, 'party.0');
    expect(bag.bagTargets.single.label, 'Flamme');
    expect(bag.bagTargets.single.pokemonSummary,
        same(party.entries.single.pokemonSummary));
    expect(
      bag.bagTargets.single.moves.map((move) => move.targetId),
      <String>['scratch', 'ember'],
    );
    final keyItem =
        bag.entries.firstWhere((entry) => entry.title == 'Harbor Pass');
    expect(keyItem.bagAction?.isEnabled, isFalse);
    expect(keyItem.bagAction?.unavailableReason, contains('pas consommé'));

    final pokedex = details[RuntimePlayerPauseSection.pokedex]!;
    expect(pokedex.entries, hasLength(2));
    expect(
      pokedex.entries.firstWhere((entry) => entry.id == 'bulbasaur').subtitle,
      contains('Vu'),
    );
    expect(
      pokedex.entries.firstWhere((entry) => entry.id == 'charmander').subtitle,
      contains('Capturé'),
    );

    final map = details[RuntimePlayerPauseSection.map]!;
    expect(map.title, 'Carte');
    expect(map.entries.map((entry) => entry.title), <String>[
      'Route des Brumes',
      'Bourg Selbrume',
      '???',
    ]);
    expect(map.regionalMap!.regions.single.points.first.status,
        RuntimePlayerMapPointStatus.current);
    expect(
        map.regionalMap!.regions.single.points
            .every((point) => !point.isLocated),
        isTrue);
    expect(map.entries.last.subtitle, 'Lieu non découvert');
    expect(map.message, isNull);
  });

  test('projects empty catalog pockets, inventory order, balance and icon',
      () async {
    final projectRoot =
        await Directory.systemTemp.createTemp('pause-bag-data-');
    addTearDown(() => projectRoot.delete(recursive: true));
    final image = File('${projectRoot.path}/assets/supply.png');
    await image.parent.create(recursive: true);
    await image.writeAsString('image');
    await _writeJson(projectRoot, 'data/pokemon/catalogs/items.json', {
      'entries': [
        {'id': 'supply', 'localSpritePath': 'assets/supply.png'},
      ],
    });
    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: const GameState(
        saveId: 'bag-pockets',
        trainerProfile: TrainerProfile(name: 'Yoahn', money: 12345),
        bag: Bag(entries: [
          BagEntry(itemId: 'supply', quantity: 2),
          BagEntry(itemId: 'unknown', quantity: 1),
          BagEntry(itemId: 'z-key', quantity: 1),
        ]),
      ),
      projectRootDirectory: projectRoot.path,
      pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1),
      locale: 'fr',
      currencyLabel: 'crédits',
      itemCatalog: ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
              id: 'z-key', displayName: 'Clé', pocketId: 'Outils'),
          ProjectItemDefinition(
              id: 'unused', displayName: 'Graine', pocketId: 'Graines'),
          ProjectItemDefinition(
              id: 'supply',
              displayName: 'Trousse',
              pocketId: 'Secours',
              description: 'Une description\nsur deux lignes.'),
        ],
      )),
    );
    final bag = details[RuntimePlayerPauseSection.bag]!;
    expect(bag.bagPockets.map((pocket) => pocket.id),
        ['Outils', 'Graines', 'Secours']);
    expect(bag.bagPockets.map((pocket) => pocket.label),
        ['Outils', 'Graines', 'Secours']);
    expect(bag.entries.map((entry) => entry.bagItem!.itemId),
        ['supply', 'unknown', 'z-key']);
    expect(bag.bagMoney, 12345);
    expect(bag.bagCurrencyLabel, 'crédits');
    expect(bag.entries.first.bagItem!.iconFilePath,
        await image.resolveSymbolicLinks());
    expect(bag.entries.first.bagItem!.description,
        'Une description\nsur deux lignes.');
    expect(bag.entries[1].bagItem!.iconFilePath, isNull);
    expect(bag.entries[1].bagAction!.isEnabled, isFalse);
    final refreshed = bag.withMessage('Actualisé');
    expect(refreshed.bagPockets, bag.bagPockets);
    expect(refreshed.bagMoney, bag.bagMoney);
    expect(refreshed.bagCurrencyLabel, bag.bagCurrencyLabel);
    expect(() => bag.bagPockets.clear(), throwsUnsupportedError);
  });

  test('localizes existing pocket labels without changing project order',
      () async {
    final root = await Directory.systemTemp.createTemp('pause-pocket-labels-');
    addTearDown(() => root.delete(recursive: true));
    const pocketIds = [
      'held-items',
      'medicine',
      'key-items',
      'machines',
      'evolution-items',
      'battle-items',
      'items',
      'balls',
      'camp-supplies',
    ];
    final catalog = ItemCatalogSnapshot.fromCatalog(ProjectItemCatalog(
      schemaVersion: 1,
      entries: [
        for (final pocketId in pocketIds)
          ProjectItemDefinition(
              id: 'item-$pocketId', displayName: pocketId, pocketId: pocketId),
      ],
    ));
    const labelsByLocale = {
      'fr': [
        'Objets tenus',
        'Soins',
        'Objets clés',
        'CT/CS',
        'Objets d’évolution',
        'Objets de combat',
        'Objets',
        'Balls',
        'Camp Supplies'
      ],
      'en': [
        'Held items',
        'Medicine',
        'Key items',
        'TMs/HMs',
        'Evolution items',
        'Battle items',
        'Items',
        'Balls',
        'Camp Supplies'
      ],
    };
    for (final locale in labelsByLocale.keys) {
      final details = await const RuntimePlayerPauseDataBuilder().build(
        gameState: const GameState(saveId: 'pocket-labels'),
        projectRootDirectory: root.path,
        pokemonConfig: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1),
        locale: locale,
        itemCatalog: catalog,
      );
      final bag = details[RuntimePlayerPauseSection.bag]!;
      expect(bag.bagPockets.map((pocket) => pocket.id), pocketIds);
      expect(
          bag.bagPockets.map((pocket) => pocket.label), labelsByLocale[locale]);
      expect(bag.entries, isEmpty);
    }
  });

  for (final knownMoves in const [
    ['scratch'],
    ['scratch', 'growl', 'ember', 'leer'],
  ]) {
    test('projects TM availability with ${knownMoves.length} known moves',
        () async {
      final projectRoot = await Directory.systemTemp.createTemp(
        'pokemap-runtime-machine-pause-',
      );
      addTearDown(() => projectRoot.delete(recursive: true));
      final speciesDirectory =
          Directory('${projectRoot.path}/data/pokemon/species');
      await speciesDirectory.create(recursive: true);
      await _writeSpecies(
        speciesDirectory,
        fileName: '004-charmander.json',
        id: 'charmander',
        nationalDex: 4,
        names: const <String, String>{'fr': 'Salamèche'},
        types: const <String>['fire'],
        baseHp: 39,
      );
      await _writeSpecies(
        speciesDirectory,
        fileName: '007-squirtle.json',
        id: 'squirtle',
        nationalDex: 7,
        names: const <String, String>{'fr': 'Carapuce'},
        types: const <String>['water'],
        baseHp: 44,
      );
      await _writeJson(
        projectRoot,
        'data/pokemon/catalogs/items.json',
        <String, Object?>{
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
        },
      );
      await _writeJson(
        projectRoot,
        'data/pokemon/catalogs/moves.json',
        <String, Object?>{
          'catalog': 'moves',
          'entries': <Object?>[
            const PokemonMove(
              id: 'protect',
              name: 'Protect',
              source: 'pause-test',
              type: 'normal',
              category: PokemonMoveCategory.status,
              basePower: 0,
              accuracy: PokemonMoveAccuracy.alwaysHits(),
              pp: 10,
              engineSupportLevel:
                  PokemonMoveEngineSupportLevel.structuredSupported,
            ).toJson(),
          ],
        },
      );
      await _writeJson(
        projectRoot,
        'data/pokemon/learnsets/charmander.json',
        <String, Object?>{
          'speciesId': 'charmander',
          'startingMoves': <String>[],
          'relearnMoves': <String>[],
          'levelUp': <Object?>[],
          'tm': <Object?>[
            <String, String>{'moveId': 'protect'},
          ],
        },
      );

      final details = await const RuntimePlayerPauseDataBuilder().build(
        gameState: GameState(
          saveId: 'machine-pause',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'charmander',
                individualId: 'starter-1',
                natureId: 'hardy',
                abilityId: 'blaze',
                currentHp: 20,
                knownMoveIds: knownMoves,
              ),
              const PlayerPokemon(
                speciesId: 'charmander',
                individualId: 'already-learned',
                natureId: 'hardy',
                abilityId: 'blaze',
                currentHp: 20,
                knownMoveIds: ['protect'],
              ),
              PlayerPokemon(
                speciesId: 'squirtle',
                natureId: 'hardy',
                abilityId: 'torrent',
                currentHp: 20,
                knownMoveIds: <String>['tackle'],
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
        ),
        projectRootDirectory: projectRoot.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
        locale: 'fr',
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

      final action =
          details[RuntimePlayerPauseSection.bag]!.entries.single.bagAction!;
      expect(action.isEnabled, isTrue);
      expect(
        action.targetKind,
        RuntimePlayerBagUseTargetKind.partyMoveReplacement,
      );
      expect(
          action.eligiblePartyTargetIds, const <String>{'pokemon.starter-1'});
      expect(action.learnedMoveLabel, 'Protect');
      final target = details[RuntimePlayerPauseSection.bag]!.bagTargets.first;
      expect(target.moves.map((move) => move.targetId), knownMoves);
      expect(target.requiresMoveReplacement, knownMoves.length == 4);
      expect(action.allowsPartyTarget('pokemon.already-learned'), isFalse);
      expect(action.unavailablePartyTargetReasons['pokemon.already-learned'],
          isNotEmpty);
      expect(action.allowsPartyTarget('pokemon.starter-1'), isTrue);
      expect(action.allowsPartyTarget('party.2'), isFalse);
      expect(action.unavailablePartyTargetReasons['party.2'],
          contains('Incompatible'));
    });
  }

  test('projects only supported held items with player-facing labels',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'pokemap-runtime-held-item-pause-',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: const GameState(
        saveId: 'held-item-pause',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              individualId: 'pkm_sproutle',
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              heldItemId: 'oran-charm',
            ),
          ],
        ),
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'leftovers-charm', quantity: 1),
            BagEntry(itemId: 'pretty-ribbon', quantity: 1),
            BagEntry(itemId: 'future-charm', quantity: 1),
          ],
        ),
      ),
      projectRootDirectory: projectRoot.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
      locale: 'fr',
      itemCatalog: _catalogWith(
        const <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'leftovers-charm',
            displayName: 'Restes',
            pocketId: 'held-items',
            heldEffectId: 'leftovers',
          ),
          ProjectItemDefinition(
            id: 'oran-charm',
            displayName: 'Baie Oran',
            pocketId: 'held-items',
            heldEffectId: 'oran_berry',
          ),
          ProjectItemDefinition(
            id: 'pretty-ribbon',
            displayName: 'Joli Ruban',
            pocketId: 'treasures',
          ),
          ProjectItemDefinition(
            id: 'future-charm',
            displayName: 'Charme futur',
            pocketId: 'held-items',
            heldEffectId: 'future-effect',
          ),
        ],
      ),
    );

    final action = details[RuntimePlayerPauseSection.party]!
        .entries
        .single
        .heldItemAction!;
    expect(action.partyTargetId, 'pokemon.pkm_sproutle');
    expect(action.currentItemLabel, 'Baie Oran');
    expect(
      action.options.map((option) => (option.itemTargetId, option.label)),
      <(String, String)>[('leftovers-charm', 'Restes')],
    );
  });

  test('previews HP, status and PP target compatibility without mutations',
      () async {
    final root = await Directory.systemTemp.createTemp('pause-bag-preview-');
    addTearDown(() => root.delete(recursive: true));
    final species = Directory('${root.path}/data/pokemon/species');
    await species.create(recursive: true);
    await _writeSpecies(species,
        fileName: 'sproutle.json',
        id: 'sproutle',
        nationalDex: 1,
        names: {'fr': 'Pousse'},
        types: ['grass'],
        baseHp: 50);
    await _writeJson(root, 'data/pokemon/catalogs/moves.json', {
      'catalog': 'moves',
      'entries': [
        const PokemonMove(
          id: 'tackle',
          name: 'Charge',
          source: 'test',
          type: 'normal',
          category: PokemonMoveCategory.physical,
          basePower: 40,
          accuracy: PokemonMoveAccuracy.alwaysHits(),
          pp: 35,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
        ).toJson(),
      ],
    });
    final state = GameState(
      saveId: 'preview',
      party: const PlayerParty(members: [
        PlayerPokemon(
            individualId: 'hurt',
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 10,
            currentHp: 10,
            statusId: 'poison',
            knownMoveIds: ['tackle'],
            currentPpByMoveId: {'tackle': 5}),
        PlayerPokemon(
            individualId: 'healthy',
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 10,
            currentHp: 100,
            knownMoveIds: ['tackle'],
            currentPpByMoveId: {'tackle': 35}),
        PlayerPokemon(
            individualId: 'burned',
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 10,
            currentHp: 10,
            statusId: 'burn',
            knownMoveIds: ['tackle'],
            currentPpByMoveId: {'tackle': 5}),
        PlayerPokemon(
            individualId: 'missing-pp',
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 10,
            currentHp: 10,
            knownMoveIds: ['tackle']),
        PlayerPokemon(
            individualId: 'no-moves',
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 10,
            currentHp: 10),
      ]),
      bag: Bag(entries: [
        for (final item in [
          'potion',
          'antidote',
          'ether',
          'poke-ball',
          'key-item'
        ])
          BagEntry(itemId: item, quantity: 1),
      ]),
    );
    final before = state.toJson();
    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: state,
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1),
      locale: 'fr',
      itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
    );
    final bag = details[RuntimePlayerPauseSection.bag]!;
    for (final itemId in ['potion', 'antidote', 'ether']) {
      final action = bag.entries
          .firstWhere((entry) => entry.bagItem!.itemId == itemId)
          .bagAction!;
      expect(action.allowsPartyTarget('pokemon.hurt'), isTrue, reason: itemId);
      expect(action.allowsPartyTarget('pokemon.healthy'), isFalse,
          reason: itemId);
      expect(action.unavailablePartyTargetReasons['pokemon.healthy'],
          contains('aucun effet'));
    }
    expect(
        bag.entries
            .firstWhere((entry) => entry.bagItem!.itemId == 'poke-ball')
            .bagAction!
            .isEnabled,
        isFalse);
    expect(
        bag.entries
            .firstWhere((entry) => entry.bagItem!.itemId == 'key-item')
            .bagAction!
            .isEnabled,
        isFalse);
    final antidote = bag.entries
        .firstWhere((entry) => entry.bagItem!.itemId == 'antidote')
        .bagAction!;
    final ether = bag.entries
        .firstWhere((entry) => entry.bagItem!.itemId == 'ether')
        .bagAction!;
    expect(antidote.targetKind, RuntimePlayerBagUseTargetKind.partyMember);
    expect(antidote.allowsPartyTarget('pokemon.burned'), isFalse);
    expect(antidote.unavailablePartyTargetReasons['pokemon.burned'],
        contains('ne convient pas'));
    expect(ether.targetKind, RuntimePlayerBagUseTargetKind.partyMove);
    expect(ether.allowsPartyTarget('pokemon.burned'), isTrue);
    for (final targetId in ['pokemon.missing-pp', 'pokemon.no-moves']) {
      expect(ether.allowsPartyTarget(targetId), isFalse);
      expect(ether.unavailablePartyTargetReasons[targetId],
          contains('ne convient pas'));
    }
    expect(bag.bagTargets.first.moves.single.label, 'Charge');
    expect(bag.bagTargets.first.moves.single.subtitle, 'PP 5/35');
    expect(state.toJson(), before);
  });

  test('reports the five canonical item usability states', () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'pokemap-runtime-item-diagnostics-',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    final catalog = ItemCatalogSnapshot.fromCatalog(
      const ProjectItemCatalog(
        schemaVersion: 1,
        entries: <ProjectItemDefinition>[
          ProjectItemDefinition(
            id: 'field-tonic',
            displayName: 'Field Tonic',
            pocketId: 'custom-medicine',
            uses: <ProjectItemUseDefinition>[
              ProjectItemUseDefinition(
                contexts: <ProjectItemUseContext>{
                  ProjectItemUseContext.overworld,
                },
                target: ProjectItemTargetKind.partyMember,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.healHp(
                  mode: ProjectItemAmountMode.flat,
                  amount: 12,
                ),
              ),
            ],
          ),
          ProjectItemDefinition(
            id: 'lucky-charm',
            displayName: 'Lucky Charm',
            pocketId: 'charms',
            tags: <String>{'passive'},
          ),
          ProjectItemDefinition(
            id: 'battle-tonic',
            displayName: 'Battle Tonic',
            pocketId: 'custom-medicine',
            uses: <ProjectItemUseDefinition>[
              ProjectItemUseDefinition(
                contexts: <ProjectItemUseContext>{
                  ProjectItemUseContext.battle,
                },
                target: ProjectItemTargetKind.partyMember,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: ProjectItemEffectDefinition.healHp(
                  mode: ProjectItemAmountMode.flat,
                  amount: 24,
                ),
              ),
            ],
          ),
          ProjectItemDefinition(
            id: 'camp-whistle',
            displayName: 'Camp Whistle',
            pocketId: 'tools',
            uses: <ProjectItemUseDefinition>[
              ProjectItemUseDefinition(
                contexts: <ProjectItemUseContext>{
                  ProjectItemUseContext.overworld,
                },
                target: ProjectItemTargetKind.none,
                consumption: ProjectItemConsumptionPolicy.never,
                effect: ProjectItemEffectDefinition.semanticAction(
                  actionId: 'camp_whistle',
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: const GameState(
        saveId: 'diagnostics',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 10,
            ),
          ],
        ),
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'field-tonic', quantity: 1),
            BagEntry(itemId: 'lucky-charm', quantity: 1),
            BagEntry(itemId: 'battle-tonic', quantity: 1),
            BagEntry(itemId: 'camp-whistle', quantity: 1),
            BagEntry(itemId: 'missing-item', quantity: 1),
          ],
        ),
      ),
      projectRootDirectory: projectRoot.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
      locale: 'fr',
      itemCatalog: catalog,
    );

    final actions = <String, RuntimePlayerBagItemActionSnapshot>{
      for (final entry in details[RuntimePlayerPauseSection.bag]!.entries)
        entry.bagAction!.itemTargetId: entry.bagAction!,
    };
    expect(actions['field-tonic']!.usability, ItemUsabilityState.usable);
    expect(actions['lucky-charm']!.usability, ItemUsabilityState.passive);
    expect(
      actions['battle-tonic']!.usability,
      ItemUsabilityState.unavailableInContext,
    );
    expect(
      actions['missing-item']!.usability,
      ItemUsabilityState.invalidDefinition,
    );
    expect(
      actions['camp-whistle']!.usability,
      ItemUsabilityState.unsupportedCapability,
    );
    expect(actions['field-tonic']!.isEnabled, isTrue);
    expect(actions['lucky-charm']!.unavailableReason, contains('passif'));
  });
}

Future<void> _writeSpecies(
  Directory directory, {
  required String fileName,
  required String id,
  required int nationalDex,
  required Map<String, String> names,
  required List<String> types,
  required int baseHp,
}) {
  return File('${directory.path}/$fileName').writeAsString(
    jsonEncode(
      <String, Object?>{
        'id': id,
        'nationalDex': nationalDex,
        'names': names,
        'typing': <String, Object?>{'types': types},
        'baseStats': <String, int>{
          'hp': baseHp,
          'atk': 50,
          'def': 50,
          'spa': 50,
          'spd': 50,
          'spe': 50,
        },
        'classification': <String, bool>{'isEnabledInProject': true},
      },
    ),
  );
}

Future<void> _writeJson(
  Directory root,
  String relativePath,
  Map<String, Object?> json,
) async {
  final file = File('${root.path}/$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}
