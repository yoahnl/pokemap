import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';

void main() {
  group('BattleAnimationPlan', () {
    test('plan aggregates requiredFxIds from steps', () {
      final plan = BattleAnimationPlan(
        steps: <BattleAnimationStep>[
          const ShowMessageStep(message: 'Test'),
          const SpawnFxStep(
            effectId: 'fireball',
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            from: BattleVisualAnchor.attackerCenter,
            to: BattleVisualAnchor.defenderCenter,
            durationSeconds: 0.3,
          ),
          const SpawnFxStep(
            effectId: 'impact',
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            from: BattleVisualAnchor.defenderCenter,
            to: BattleVisualAnchor.defenderCenter,
            durationSeconds: 0.12,
          ),
        ],
      );

      expect(plan.requiredFxIds, equals(<String>{'fireball', 'impact'}));
    });

    test('hp tween steps are preserved as dedicated steps', () {
      final plan = BattleAnimationPlan(
        steps: const <BattleAnimationStep>[
          HudHpTweenStep(
            side: BattleSideId.enemy,
            fromHp: 42,
            toHp: 18,
            durationMs: 320,
          ),
        ],
      );

      expect(plan.steps.single, isA<HudHpTweenStep>());
    });

    test('empty plan reports isEmpty true', () {
      const plan = BattleAnimationPlan(steps: <BattleAnimationStep>[]);

      expect(plan.isEmpty, isTrue);
      expect(plan.requiredFxIds, isEmpty);
    });

    test('plan preserves step order exactly', () {
      final first = const ShowMessageStep(message: 'first');
      final second = const WaitStep(durationSeconds: 0.2);
      final third = const CombatantFlashStep(
        side: BattleSideId.enemy,
        durationSeconds: 0.1,
      );
      final plan = BattleAnimationPlan(
        steps: <BattleAnimationStep>[first, second, third],
      );

      expect(identical(plan.steps[0], first), isTrue);
      expect(identical(plan.steps[1], second), isTrue);
      expect(identical(plan.steps[2], third), isTrue);
    });
  });
}
