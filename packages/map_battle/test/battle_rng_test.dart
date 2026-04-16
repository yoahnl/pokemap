import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleRng mini-fix BE6', () {
    test('BattleSeededRng rejects a negative numerator explicitly', () {
      expect(
        () => const BattleSeededRng().nextChance(
          numerator: -1,
          denominator: 24,
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

    test('BattleSeededRng keeps numerator 0 as a valid impossible chance', () {
      final result = const BattleSeededRng(state: 12345).nextChance(
        numerator: 0,
        denominator: 24,
      );

      // Mini-fix BE6-2 :
      // - `0/x` n'est pas un contrat invalide ;
      // - c'est une chance impossible, donc le résultat doit rester
      //   explicitement faux ;
      // - ce test ferme un trou de couverture utile sans inventer une
      //   nouvelle abstraction RNG.
      expect(result.didOccur, isFalse);
      expect(result.next, isA<BattleSeededRng>());
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

    test('BattleScriptedRng rejects a negative numerator explicitly', () {
      expect(
        () => const BattleScriptedRng(<int>[1]).nextChance(
          numerator: -1,
          denominator: 24,
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

    test('BattleScriptedRng rejects a zero denominator explicitly', () {
      expect(
        () => const BattleScriptedRng(<int>[1]).nextChance(
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

    test('BattleScriptedRng rejects a numerator greater than denominator', () {
      expect(
        () => const BattleScriptedRng(<int>[1]).nextChance(
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

    test('BattleScriptedRng keeps numerator 0 as a valid impossible chance',
        () {
      final result = const BattleScriptedRng(<int>[1]).nextChance(
        numerator: 0,
        denominator: 24,
      );

      // On aligne explicitement les deux implémentations du seam :
      // - même contrat invalide => même rejet ;
      // - même contrat valide impossible (`0/x`) => même sémantique fausse.
      expect(result.didOccur, isFalse);
      expect(result.next, isA<BattleScriptedRng>());
    });
  });
}
