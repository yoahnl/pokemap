import 'package:map_editor/src/application/seeds/pokemon_move_localized_names.dart';
import 'package:map_editor/src/application/services/pokemon_move_local_id.dart';
import 'package:test/test.dart';

void main() {
  group('pokemonMoveLocalizedNames', () {
    test('is not empty', () {
      expect(pokemonMoveLocalizedNames, isNotEmpty);
    });

    test('every key is already a normalized local id', () {
      for (final key in pokemonMoveLocalizedNames.keys) {
        expect(
          normalizePokemonMoveLocalId(key),
          key,
          reason: 'Key "$key" is not a normalized local id.',
        );
      }
    });

    test('every entry exposes a non-empty french name', () {
      for (final entry in pokemonMoveLocalizedNames.entries) {
        final french = entry.value['fr'];
        expect(
          french,
          isNotNull,
          reason: 'Entry "${entry.key}" has no french name.',
        );
        expect(
          french!.trim(),
          isNotEmpty,
          reason: 'Entry "${entry.key}" has a blank french name.',
        );
      }
    });

    test('covers a few well-known moves', () {
      expect(pokemonMoveLocalizedNames['thunderbolt']?['fr'], 'Tonnerre');
      expect(pokemonMoveLocalizedNames['u_turn']?['fr'], isNotNull);
      expect(pokemonMoveLocalizedNames['kings_shield']?['fr'], isNotNull);
    });
  });

  group('localizedNamesForMove', () {
    test('returns the translations of a known move', () {
      expect(localizedNamesForMove('thunderbolt')['fr'], 'Tonnerre');
    });

    test('returns an empty map for an unknown move', () {
      expect(localizedNamesForMove('definitely_not_a_move'), isEmpty);
    });
  });
}
