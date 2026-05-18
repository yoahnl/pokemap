import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/battle_effect_registry.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK move marker effects', () {
    test('Focus Punch mirrors PSDK preparing_attack marker', () {
      const effect = FocusPunchEffect(
        scope: BattlerBattleEffectScope(psdkPlayerSlot),
      );

      expect(effect.id, 'focus_punch');
      expect(effect.preparingAttack, isTrue);
      expect(effect.remainingTurns, 0);
      expect(
        const PsdkBattleEffectStack.empty()
            .addEffect(effect)
            .clearTurnScopedEffects()
            .contains('focus_punch'),
        isFalse,
      );
    });

    test('Happy Hour hydrates as the passive PSDK effect', () {
      const effect = HappyHourEffect(scope: LocalBattleEffectScope());

      expect(effect.id, 'happy_hour');
      expect(effect.preparingAttack, isFalse);
      expect(
        const PsdkBattleEffectStack.empty()
            .addEffect(effect)
            .clearTurnScopedEffects()
            .contains('happy_hour'),
        isTrue,
      );
    });

    test('registry exposes Focus Punch and Happy Hour effects', () {
      const registry = BattleEffectRegistry();

      expect(registry.fromId('focus_punch'), isA<FocusPunchEffect>());
      expect(registry.fromId('happy_hour'), isA<HappyHourEffect>());
      expect(
        PsdkBattleEffectStack(values: const <String>[
          'focus_punch',
          'happy_hour',
        ]).effects,
        containsAll(<Matcher>[
          isA<FocusPunchEffect>(),
          isA<HappyHourEffect>(),
        ]),
      );
    });
  });
}
