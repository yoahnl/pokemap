import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

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
          ),
        ],
      ),
      bag: const Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'potion',
            categoryId: 'medicine',
            quantity: 3,
          ),
          BagEntry(
            itemId: 'harbor-pass',
            categoryId: 'key-items',
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
      pokemonConfig: const ProjectPokemonConfig(),
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
    );

    final party = details[RuntimePlayerPauseSection.party]!;
    expect(party.entries, hasLength(1));
    expect(party.entries.single.title, 'Salamèche');
    expect(party.entries.single.subtitle, contains('Niv. 16'));
    expect(party.entries.single.subtitle, contains('PV 38/38'));
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
    expect(bag.bagTargets.single.label, 'Salamèche');
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
    expect(map.entries.first.trailingLabel, 'Ici');
    expect(map.entries.last.subtitle, 'Zone non découverte');
    expect(map.message, contains('voyage rapide'));
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
