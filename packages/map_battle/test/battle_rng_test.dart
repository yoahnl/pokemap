import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleRng mini-fix BE6', () {
    test('BattleSeededRng rejects a zero denominator explicitly', () {
      expect(
        () => const BattleSeededRng().nextChance(
          numerator: 1,
          denominator: 0,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('invalid chance contract'),
          ),
        ),
      );
    });

    test('BattleSeededRng rejects a numerator greater than denominator', () {
      expect(
        () => const BattleSeededRng().nextChance(
          numerator: 3,
          denominator: 2,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('invalid chance contract'),
          ),
        ),
      );
    });

    test('BattleSeededRng keeps a valid chance contract deterministic', () {
      final first = const BattleSeededRng(state: 12345).nextChance(
        numerator: 1,
        denominator: 24,
      );
      final second = const BattleSeededRng(state: 12345).nextChance(
        numerator: 1,
        denominator: 24,
      );

      // Ce test ne prétend pas valider un grand système RNG.
      // Il verrouille seulement le contrat minimal dont BE6 dépend :
      // - même seed + même chance => même résultat ;
      // - le seam garde un état suivant explicite.
      expect(first.didOccur, equals(second.didOccur));
      expect(first.next, isA<BattleSeededRng>());
    });
  });
}
