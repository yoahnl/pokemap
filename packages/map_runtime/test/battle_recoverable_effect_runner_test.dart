import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';

typedef _StartEffect = void Function() Function(
  StartTrackedEffectStep,
  void Function(),
  void Function(),
);

BattleAnimationRunner _runner({
  required List<String> events,
  required _StartEffect startEffect,
  void Function(CameraFocusStep)? focus,
  void Function(BattleCameraResetStep)? resetCamera,
  void Function() Function(StartTrackedEffectStep, void Function())?
  startOrdinary,
}) => BattleAnimationRunner(
  onPresentationChanged: () {},
  onSpawnFx: (step) => events.add('fx:${step.effectId}'),
  onScreenFlash: (_) {},
  onCombatantMotion: (_) {},
  onCombatantFlash: (_) {},
  onCombatantShake: (_) {},
  onFaintCombatant: (_) {},
  onHudHpTween: (step) => events.add('hp:${step.fromHp}->${step.toHp}'),
  onBarrierPulse: (_) {},
  onSwapCombatantVisual: (_) {},
  onPlaySe: (step) => events.add('sound:${step.seName}'),
  onCameraFocus: focus,
  onBattleCameraReset: resetCamera,
  onStartTrackedEffect: startOrdinary,
  onStartRecoverableTrackedEffect: startEffect,
  messageStepSeconds: 0,
);

void main() {
  test('fallback resources and motion remain visible to plan preparation', () {
    const motion = CombatantMotionStep(
      side: BattleSideId.player,
      motionKind: BattleCombatantMotionKind.lunge,
      durationSeconds: .1,
      distancePx: 12,
    );
    const plan = BattleAnimationPlan(
      steps: [
        StartTrackedEffectStep(
          effectId: 'bw2',
          fallbackSteps: [
            AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [
                SpawnFxStep(
                  effectId: 'fallback-fx',
                  attackerSide: BattleSideId.player,
                  defenderSide: BattleSideId.enemy,
                  from: BattleVisualAnchor.attackerCenter,
                  to: BattleVisualAnchor.defenderCenter,
                  durationSeconds: .1,
                ),
                motion,
              ],
            ),
          ],
        ),
        WaitTrackedEffectsStep(),
      ],
    );
    expect(plan.requiredFxIds, {'fallback-fx'});
    expect(plan.flattenedSteps, contains(motion));
  });

  test(
    'failure after playback restores the visual fallback and keeps the turn',
    () async {
      final events = <String>[];
      late void Function() finish;
      late void Function() failEffect;
      final runner = _runner(
        events: events,
        startEffect: (_, done, failed) {
          events.add('imported');
          finish = done;
          failEffect = failed;
          return () => events.add('cancel');
        },
      );
      runner.start(
        const BattleAnimationPlan(
          steps: [
            ShowMessageStep(message: 'attack'),
            StartTrackedEffectStep(
              effectId: 'bw2',
              fallbackSteps: [
                PlaySeStep(seName: 'fallback'),
                WaitStep(durationSeconds: .1),
              ],
            ),
            WaitStep(durationSeconds: .2),
            PlaySeStep(seName: 'imported-late'),
            WaitTrackedEffectsStep(),
            PlaySeStep(seName: 'impact'),
            HudHpTweenStep(
              side: BattleSideId.enemy,
              fromHp: 40,
              toHp: 20,
              durationMs: 1,
            ),
            PlaySeStep(seName: 'following-turn'),
          ],
        ),
      );
      expect(events, ['imported']);
      var completed = false;
      runner.completionFuture.then((_) => completed = true);
      runner.update(.05);
      failEffect();
      runner.update(0);
      await Future<void>.value();
      expect(completed, isFalse);
      expect(events, ['imported', 'cancel', 'sound:fallback']);

      finish();
      failEffect();
      runner.update(.2);
      await Future<void>.value();
      expect(events, [
        'imported',
        'cancel',
        'sound:fallback',
        'sound:impact',
        'hp:40->20',
        'sound:following-turn',
      ]);
      expect(completed, isTrue);
    },
  );

  test('successful playback skips the fallback', () {
    final events = <String>[];
    late void Function() finish;
    final runner = _runner(
      events: events,
      startEffect: (_, done, _) {
        events.add('imported');
        finish = done;
        return () => events.add('cancel');
      },
    );
    runner.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(
            effectId: 'bw2',
            fallbackSteps: [PlaySeStep(seName: 'fallback')],
          ),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'impact'),
          HudHpTweenStep(
            side: BattleSideId.enemy,
            fromHp: 40,
            toHp: 20,
            durationMs: 1,
          ),
        ],
      ),
    );
    expect(events, ['imported']);
    finish();
    runner.update(.01);
    expect(events, ['imported', 'sound:impact', 'hp:40->20']);
  });

  test('synchronous failure cancels the returned effect and plays the fallback once', () {
    final events = <String>[];
    final runner = _runner(
      events: events,
      startEffect: (_, _, failed) {
        events.add('imported');
        failed();
        return () => events.add('cancel');
      },
    );
    runner.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(
            effectId: 'bw2',
            fallbackSteps: [PlaySeStep(seName: 'fallback')],
          ),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'impact'),
        ],
      ),
    );
    runner.update(0);
    expect(events, ['imported', 'cancel', 'sound:fallback', 'sound:impact']);
  });

  test('rejects a recoverable effect without a barrier or with HP inside the branch', () {
    final events = <String>[];
    final runner = _runner(events: events, startEffect: (_, _, _) => () {});
    expect(
      () => runner.start(
        const BattleAnimationPlan(
          steps: [StartTrackedEffectStep(effectId: 'bw2', fallbackSteps: [])],
        ),
      ),
      throwsStateError,
    );
    expect(
      () => runner.start(
        const BattleAnimationPlan(
          steps: [
            StartTrackedEffectStep(effectId: 'bw2', fallbackSteps: []),
            HudHpTweenStep(side: BattleSideId.enemy, fromHp: 40, toHp: 20),
            WaitTrackedEffectsStep(),
          ],
        ),
      ),
      throwsStateError,
    );
    expect(events, isEmpty);
  });

  test('failure resets a camera started in the abandoned visual branch', () {
    final events = <String>[];
    late void Function() failEffect;
    final runner = _runner(
      events: events,
      startEffect: (_, _, failed) {
        failEffect = failed;
        return () {};
      },
      focus: (_) => events.add('focus'),
      resetCamera: (_) => events.add('reset'),
    );
    runner.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(effectId: 'bw2', fallbackSteps: []),
          CameraFocusStep(
            target: BattleCameraFocusTarget.target,
            durationSeconds: 1,
          ),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'impact'),
        ],
      ),
    );
    expect(events, ['focus']);
    expect(runner.areGaugesHidden, isTrue);
    failEffect();
    runner.update(0);
    expect(events, ['focus', 'reset', 'sound:impact']);
    expect(runner.areGaugesHidden, isFalse);
  });

  test('freezes fallback and visual groups before the effect starts', () {
    final events = <String>[];
    late void Function() failEffect;
    final fallback = <BattleAnimationStep>[
      const PlaySeStep(seName: 'fallback'),
    ];
    final body = <BattleAnimationStep>[const WaitStep(durationSeconds: .1)];
    final runner = _runner(
      events: events,
      startEffect: (_, _, failed) {
        failEffect = failed;
        return () {};
      },
    );
    runner.start(
      BattleAnimationPlan(
        steps: [
          const WaitStep(durationSeconds: .1),
          StartTrackedEffectStep(effectId: 'bw2', fallbackSteps: fallback),
          AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: body,
          ),
          const WaitTrackedEffectsStep(),
          const PlaySeStep(seName: 'impact'),
        ],
      ),
    );
    fallback.add(
      const HudHpTweenStep(side: BattleSideId.enemy, fromHp: 40, toHp: 10),
    );
    body.add(const PlaySeStep(seName: 'mutated'));
    runner.update(.1);
    failEffect();
    runner.update(0);
    expect(events, ['sound:fallback', 'sound:impact']);
  });

  test(
    'does not place a recoverable branch over an earlier tracked effect',
    () {
      final events = <String>[];
      final runner = _runner(
        events: events,
        startOrdinary: (_, _) {
          events.add('ordinary');
          return () {};
        },
        startEffect: (_, _, _) {
          events.add('recoverable');
          return () {};
        },
      );
      expect(
        () => runner.start(
          const BattleAnimationPlan(
            steps: [
              StartTrackedEffectStep(effectId: 'ordinary'),
              StartTrackedEffectStep(effectId: 'bw2', fallbackSteps: []),
              WaitTrackedEffectsStep(),
            ],
          ),
        ),
        throwsStateError,
      );
      expect(events, isEmpty);
    },
  );

  test('late failure after cancellation cannot restart the fallback', () {
    final events = <String>[];
    late void Function() failEffect;
    final runner = _runner(
      events: events,
      startEffect: (_, _, failed) {
        events.add('imported');
        failEffect = failed;
        return () => events.add('cancel');
      },
    );
    runner.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(
            effectId: 'bw2',
            fallbackSteps: [PlaySeStep(seName: 'fallback')],
          ),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'impact'),
        ],
      ),
    );
    runner.cancel();
    failEffect();
    runner.update(0);
    expect(runner.isActive, isFalse);
    expect(events, ['imported', 'cancel']);
  });

  test('a replacement started by cancellation wins over the fallback', () {
    final events = <String>[];
    late void Function() failEffect;
    late BattleAnimationRunner runner;
    runner = _runner(
      events: events,
      startEffect: (_, _, failed) {
        events.add('imported');
        failEffect = failed;
        return () => runner.start(
          const BattleAnimationPlan(steps: [PlaySeStep(seName: 'replacement')]),
        );
      },
    );
    runner.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(
            effectId: 'bw2',
            fallbackSteps: [PlaySeStep(seName: 'fallback')],
          ),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'impact'),
        ],
      ),
    );
    failEffect();
    runner.update(0);
    expect(events, ['imported', 'sound:replacement']);
  });
}
