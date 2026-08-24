import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/pokemon_move_local_id.dart';

void main() {
  group('normalizePokemonMoveLocalId', () {
    test('lowercases a simple name', () {
      expect(normalizePokemonMoveLocalId('Thunderbolt'), 'thunderbolt');
    });

    test('turns hyphens into underscores', () {
      expect(normalizePokemonMoveLocalId('U-turn'), 'u_turn');
    });

    test('drops apostrophes without leaving a separator', () {
      expect(normalizePokemonMoveLocalId("King's Shield"), 'kings_shield');
    });

    test('drops commas inside numbers', () {
      expect(
        normalizePokemonMoveLocalId('10,000,000 Volt Thunderbolt'),
        '10000000_volt_thunderbolt',
      );
    });

    test('handles repeated hyphens as a single separator', () {
      expect(normalizePokemonMoveLocalId('Will-O-Wisp'), 'will_o_wisp');
    });

    test('collapses consecutive separators', () {
      expect(normalizePokemonMoveLocalId('Double  -  Edge'), 'double_edge');
    });

    test('trims leading and trailing separators', () {
      expect(normalizePokemonMoveLocalId(' -Tackle- '), 'tackle');
    });

    test('returns an empty string for blank input', () {
      expect(normalizePokemonMoveLocalId('   '), '');
    });
  });
}
