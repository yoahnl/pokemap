import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_combatant_gender_resolver.dart';

void main() {
  group('BattleCombatantGenderResolver', () {
    test('maps known gender ids to battle symbols', () {
      const resolver = BattleCombatantGenderResolver(
        playerLineupGenderIdsByIndex: <int, String>{0: 'female'},
        enemyLineupGenderIdsByIndex: <int, String>{0: 'male', 1: 'genderless'},
      );

      expect(
        resolver.resolveGenderSymbol(isPlayerSide: true, lineupIndex: 0),
        equals('♀'),
      );
      expect(
        resolver.resolveGenderSymbol(isPlayerSide: false, lineupIndex: 0),
        equals('♂'),
      );
      expect(
        resolver.resolveGenderSymbol(isPlayerSide: false, lineupIndex: 1),
        equals('∅'),
      );
    });

    test('returns null when no honest gender is known for that lineup slot', () {
      const resolver = BattleCombatantGenderResolver();

      expect(
        resolver.resolveGenderSymbol(isPlayerSide: true, lineupIndex: 0),
        isNull,
      );
      expect(
        resolver.resolveGenderSymbol(isPlayerSide: false, lineupIndex: 0),
        isNull,
      );
    });

    test('resolves a deterministic wild gender from a mixed ratio when seeded',
        () {
      final first = resolveBattleGenderIdFromRatios(
        maleRatio: 0.875,
        femaleRatio: 0.125,
        stableSeed: 'wild|sparkitten|7',
      );
      final second = resolveBattleGenderIdFromRatios(
        maleRatio: 0.875,
        femaleRatio: 0.125,
        stableSeed: 'wild|sparkitten|7',
      );

      expect(first, anyOf(equals('male'), equals('female')));
      expect(second, equals(first));
    });
  });
}
