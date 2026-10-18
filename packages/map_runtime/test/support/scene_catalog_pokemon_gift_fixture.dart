import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

Future<ProjectPokemonConfig> writeSceneCatalogPokemonGiftFixture(
  Directory root,
) async {
  Future<void> write(String path, Map<String, Object?> value) async {
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(value));
  }

  await write('custom/species/not-a-builtin.json', {
    'schemaVersion': currentPokemonDataSchemaVersion,
    'id': 'clockbird',
    'forms': {'formId': 'bronze'},
    'typing': {
      'types': ['steel'],
    },
    'baseStats': {
      'hp': 81,
      'atk': 72,
      'def': 63,
      'spa': 54,
      'spd': 45,
      'spe': 36,
    },
    'abilities': {'primary': 'clockwork', 'secondary': 'solid'},
    'breeding': {
      'genderRatio': {'male': 1.0, 'female': 1.0},
    },
    'progression': {
      'growthRateId': 'medium_fast',
      'baseExp': 91,
      'catchRate': 120,
      'baseFriendship': 42,
    },
    'refs': {'learnset': 'clockbird'},
  });
  await write('custom/learnsets/clockbird.json', {
    'startingMoves': ['tick'],
    'levelUp': [
      {'moveId': 'tock', 'level': 6},
    ],
  });
  await write('custom/moves.json', {
    'catalog': 'moves',
    'entries': [
      for (final entry in {'tick': 13, 'tock': 19}.entries)
        PokemonMove(
          id: entry.key,
          name: entry.key,
          generation: 1,
          source: 'fixture',
          type: 'steel',
          category: PokemonMoveCategory.physical,
          target: PokemonMoveTarget.normal,
          basePower: 30,
          accuracy: const PokemonMoveAccuracy.percent(value: 100),
          pp: entry.value,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
        ).toJson(),
    ],
  });
  return const ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    speciesDir: 'custom/species',
    learnsetsDir: 'custom/learnsets',
    catalogFiles: {'moves': 'custom/moves.json'},
  );
}
