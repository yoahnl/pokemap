import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/showdown_pokemon_species_converter.dart';

void main() {
  const converter = ShowdownPokemonSpeciesConverter();

  group('ShowdownPokemonSpeciesConverter', () {
    test('converts a base species core payload', () {
      final payload =
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>;

      final species = converter.convert(payload);

      expect(species.id, 'bulbasaur');
      expect(species.slug, 'bulbasaur');
      expect(species.nationalDex, 1);
      expect(species.names['en'], 'Bulbasaur');
      expect(species.typing.types, <String>['Grass', 'Poison']);
      expect(species.baseStats.bst, 318);
      expect(species.abilities.primary, 'Overgrow');
      expect(species.abilities.hidden, 'Chlorophyll');
      expect(species.refs.learnset, 'bulbasaur');
      expect(species.forms.isBaseForm, isTrue);
      expect(species.forms.otherForms, contains('bulbasaurmega'));
      expect(species.classification.isLegendary, isFalse);
      expect(species.progression.growthRateId, 'mediumslow');
    });

    test('converts a non-base form with classification flags', () {
      final payload =
          jsonDecode(_lycanrocDuskShowdownPayload) as Map<String, dynamic>;

      final species = converter.convert(payload);

      expect(species.id, 'lycanroc-dusk');
      expect(species.forms.isBaseForm, isFalse);
      expect(species.forms.baseFormId, 'lycanroc');
      expect(species.forms.formId, 'dusk');
      expect(species.forms.formName, 'Dusk');
      expect(species.classification.isLegendary, isTrue);
      expect(species.classification.isMythical, isFalse);
      expect(species.classification.isObtainable, isFalse);
    });

    test('fails clearly when types are missing', () {
      final payload = jsonDecode(_bulbasaurShowdownPayload)
          as Map<String, dynamic>
        ..['types'] = <Object?>[];

      expect(
        () => converter.convert(payload),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Showdown species field "types" cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when baseStats is not an object', () {
      final payload = jsonDecode(_bulbasaurShowdownPayload)
          as Map<String, dynamic>
        ..['baseStats'] = <Object?>['not', 'a', 'map'];

      expect(
        () => converter.convert(payload),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'Showdown species field "baseStats" must be an object',
          ),
        ),
      );
    });
  });
}

const String _bulbasaurShowdownPayload = '''
{
  "name": "Bulbasaur",
  "num": 1,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "genderRatio": {
    "M": 0.875,
    "F": 0.125
  },
  "expType": "Medium Slow",
  "baseExp": 64,
  "catchRate": 45,
  "baseFriendship": 50,
  "color": "Green",
  "heightm": 0.7,
  "weightkg": 6.9,
  "otherFormes": ["bulbasaurmega"]
}
''';

const String _lycanrocDuskShowdownPayload = '''
{
  "name": "Lycanroc-Dusk",
  "species": "Lycanroc-Dusk",
  "baseSpecies": "Lycanroc",
  "forme": "Dusk",
  "num": 745,
  "gen": 7,
  "types": ["Rock"],
  "baseStats": {
    "hp": 75,
    "atk": 117,
    "def": 65,
    "spa": 55,
    "spd": 65,
    "spe": 110
  },
  "abilities": {
    "0": "Tough Claws"
  },
  "isNonstandard": "Unobtainable",
  "tags": ["Legendary"]
}
''';
