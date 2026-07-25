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

    const state = GameState(
      saveId: 'save-1',
      party: PlayerParty(
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
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'potion',
            categoryId: 'medicine',
            quantity: 3,
          ),
        ],
      ),
      progression: PlayerProgression(
        seenSpeciesIds: <String>['bulbasaur'],
      ),
    );

    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: state,
      projectRootDirectory: projectRoot.path,
      pokemonConfig: const ProjectPokemonConfig(),
      locale: 'fr',
    );

    final party = details[RuntimePlayerPauseSection.party]!;
    expect(party.entries, hasLength(1));
    expect(party.entries.single.title, 'Salamèche');
    expect(party.entries.single.subtitle, contains('Niv. 16'));
    expect(party.entries.single.subtitle, contains('PV 38/38'));
    expect(party.entries.single.progress, 1);

    final bag = details[RuntimePlayerPauseSection.bag]!;
    expect(bag.entries, hasLength(1));
    expect(bag.entries.single.title, 'Potion');
    expect(bag.entries.single.trailingLabel, '×3');

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
