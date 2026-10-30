import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';

void main() {
  BattleAnimationRunner runner(void Function(bool hidden) hp) {
    late BattleAnimationRunner result;
    result = BattleAnimationRunner(
      onPresentationChanged: () {},
      onSpawnFx: (_) {},
      onScreenFlash: (_) {},
      onCombatantMotion: (_) {},
      onCombatantFlash: (_) {},
      onCombatantShake: (_) {},
      onFaintCombatant: (_) {},
      onHudHpTween: (_) => hp(result.areGaugesHidden),
      onBarrierPulse: (_) {},
      onSwapCombatantVisual: (_) {},
    );
    return result;
  }

  const plan = BattleAnimationPlan(
    steps: [
      AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [
          CameraFocusStep(
            target: BattleCameraFocusTarget.target,
            durationSeconds: .3,
          ),
        ],
      ),
      WaitStep(durationSeconds: .5),
      AnimationGroupStep(
        mode: BattleAnimationGroupMode.parallel,
        steps: [BattleCameraResetStep(durationSeconds: .3)],
      ),
      HudHpTweenStep(
        side: BattleSideId.enemy,
        fromHp: 40,
        toHp: 10,
        durationMs: 400,
      ),
    ],
  );

  test('HUD stays hidden through effect and whole return, visible before HP callback', () {
    final hpVisibility = <bool>[];
    final animation = runner(hpVisibility.add)..start(plan);
    expect(animation.areGaugesHidden, isTrue);
    animation.update(.79);
    expect(animation.areGaugesHidden, isTrue);
    expect(hpVisibility, isEmpty);
    animation.update(.30);
    expect(animation.areGaugesHidden, isTrue);
    expect(hpVisibility, isEmpty);
    animation.update(.02);
    expect(hpVisibility, [false]);
    expect(animation.areGaugesHidden, isFalse);
  });

  test(
    'cancel and replacement plan restore visibility without consuming HP',
    () {
      final hpVisibility = <bool>[];
      final animation = runner(hpVisibility.add)..start(plan);
      animation.update(.4);
      animation.cancel();
      expect(animation.areGaugesHidden, isFalse);
      expect(hpVisibility, isEmpty);
      animation.start(
        const BattleAnimationPlan(steps: [ShowMessageStep(message: 'Suivant')]),
      );
      expect(animation.areGaugesHidden, isFalse);
      animation.update(10);
      expect(hpVisibility, isEmpty);
    },
  );
}
