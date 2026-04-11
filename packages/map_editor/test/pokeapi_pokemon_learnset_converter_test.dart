import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_learnset_converter.dart';

void main() {
  const converter = PokeApiPokemonLearnsetConverter();

  group('PokeApiPokemonLearnsetConverter', () {
    test('converts a representative PokeAPI learnset payload', () {
      final payload =
          jsonDecode(_bulbasaurLearnsetPayload) as Map<String, dynamic>;

      final learnset = converter.convert(
        speciesId: 'bulbasaur',
        payload: payload,
      );

      expect(learnset.speciesId, 'bulbasaur');
      expect(learnset.startingMoves, containsAll(<String>['tackle', 'growl']));
      expect(learnset.relearnMoves, containsAll(<String>['tackle', 'growl']));
      expect(
        learnset.levelUp.map((entry) => entry.moveId),
        containsAll(<String>['tackle', 'growl', 'vine-whip']),
      );
      expect(learnset.tm.single.moveId, 'solar-beam');
      expect(learnset.tutor.single.moveId, 'seed-bomb');
      expect(learnset.egg.single.moveId, 'petal-dance');
      expect(learnset.event.single.moveId, 'celebrate');
      expect(learnset.transfer.single.moveId, 'cut');
    });

    test('fails clearly when speciesId is empty', () {
      final payload =
          jsonDecode(_bulbasaurLearnsetPayload) as Map<String, dynamic>;

      expect(
        () => converter.convert(
          speciesId: '   ',
          payload: payload,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'PokeAPI learnset speciesId cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when moves are missing', () {
      expect(
        () => converter.convert(
          speciesId: 'bulbasaur',
          payload: const <String, dynamic>{},
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'PokeAPI learnset payload must contain a moves list',
          ),
        ),
      );
    });

    test('fails clearly when no usable move data is produced', () {
      expect(
        () => converter.convert(
          speciesId: 'bulbasaur',
          payload: const <String, dynamic>{'moves': <Object?>[]},
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'PokeAPI learnset payload produced no usable move data',
          ),
        ),
      );
    });
  });
}

const String _bulbasaurLearnsetPayload = '''
{
  "name": "bulbasaur",
  "moves": [
    {
      "move": {"name": "tackle"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "growl"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "vine-whip"},
      "version_group_details": [
        {
          "level_learned_at": 7,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "solar-beam"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "seed-bomb"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "tutor"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "petal-dance"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "egg"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "celebrate"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "form-change"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "cut"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "unknown-method"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';
