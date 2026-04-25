import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokemon_sdk_species_converter.dart';

void main() {
  const converter = PokemonSdkSpeciesConverter();

  group('PokemonSdkSpeciesConverter', () {
    test('converts a minimal Studio pokemon payload into a species file', () {
      final species = converter.convert(<String, Object?>{
        'id': 1,
        'dbSymbol': 'bulbasaur',
        'name': <String, Object?>{
          'en': 'Bulbasaur',
          'fr': 'Bulbizarre',
        },
        'generation': 1,
        'types': <Object?>['grass', 'poison'],
        'baseStats': <String, Object?>{
          'hp': 45,
          'atk': 49,
          'def': 49,
          'spa': 65,
          'spd': 65,
          'spe': 45,
        },
        'abilities': <Object?>['overgrow', 'chlorophyll'],
        'height': 0.7,
        'weight': 6.9,
      });

      expect(species.id, 'bulbasaur');
      expect(species.nationalDex, 1);
      expect(species.names['fr'], 'Bulbizarre');
      expect(species.typing.types, ['grass', 'poison']);
      expect(species.baseStats.bst, 318);
      expect(species.abilities.primary, 'overgrow');
      expect(species.abilities.hidden, 'chlorophyll');
      expect(species.refs.learnset, 'bulbasaur');
      expect(species.sourceMeta.seededBy, 'pokemon_sdk_studio');
    });

    test('fails clearly when a Studio pokemon has no dbSymbol', () {
      expect(
        () => converter.convert(const <String, Object?>{
          'name': 'MissingNo',
          'types': <Object?>['normal'],
        }),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('dbSymbol'),
          ),
        ),
      );
    });
  });
}
