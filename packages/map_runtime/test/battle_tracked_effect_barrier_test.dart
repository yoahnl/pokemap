import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';

void main() {
  BattleAnimationRunner runner({
    required void Function(String, void Function()) start,
    required List<String> events,
    void Function(String)? cancel,
  }) => BattleAnimationRunner(
    onPresentationChanged: () {},
    onSpawnFx: (_) {},
    onScreenFlash: (_) {},
    onCombatantMotion: (_) {},
    onCombatantFlash: (_) {},
    onCombatantShake: (_) {},
    onFaintCombatant: (_) {},
    onHudHpTween: (_) {},
    onBarrierPulse: (_) {},
    onSwapCombatantVisual: (_) {},
    onPlaySe: (step) => events.add(step.seName),
    onStartTrackedEffect: (step, complete) {
      start(step.effectId, complete);
      return () => cancel?.call(step.effectId);
    },
  );

  test(
    'barrier waits for every completion and does not carry waiting time',
    () {
      final completions = <String, void Function()>{};
      final events = <String>[];
      final instance = runner(
        start: (id, done) => completions[id] = done,
        events: events,
      );
      instance.start(
        const BattleAnimationPlan(
          steps: [
            StartTrackedEffectStep(effectId: 'a'),
            StartTrackedEffectStep(effectId: 'b'),
            WaitTrackedEffectsStep(),
            WaitStep(durationSeconds: 1),
            PlaySeStep(seName: 'after'),
          ],
        ),
      );
      expect(completions.keys, containsAll(['a', 'b']));
      instance.update(20);
      completions['a']!();
      instance.update(20);
      expect(events, isEmpty);
      completions['b']!();
      instance.update(0);
      instance.update(.9);
      expect(events, isEmpty);
      instance.update(.1);
      expect(events, ['after']);
    },
  );

  test('cancellation retires pending effects and late completion cannot unblock a new plan', () {
    final completions = <String, void Function()>{};
    final cancelled = <String>[];
    final events = <String>[];
    final instance = runner(
      start: (id, done) => completions[id] = done,
      events: events,
      cancel: cancelled.add,
    );
    instance.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(effectId: 'old'),
          WaitTrackedEffectsStep(),
        ],
      ),
    );
    final old = completions['old']!;
    instance.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(effectId: 'new'),
          WaitTrackedEffectsStep(),
          PlaySeStep(seName: 'done'),
        ],
      ),
    );
    expect(cancelled, ['old']);
    old();
    instance.update(0);
    expect(events, isEmpty);
    completions['new']!();
    instance.update(0);
    expect(events, ['done']);
  });

  test(
    'an already completed effect does not discard remaining elapsed time',
    () {
      final events = <String>[];
      final instance = runner(start: (_, done) => done(), events: events);
      instance.start(
        const BattleAnimationPlan(
          steps: [
            WaitStep(durationSeconds: .1),
            StartTrackedEffectStep(effectId: 'instant'),
            WaitTrackedEffectsStep(),
            WaitStep(durationSeconds: .2),
            PlaySeStep(seName: 'done'),
          ],
        ),
      );
      instance.update(.3);
      expect(events, ['done']);
    },
  );

  test(
    'retires a still active effect when its plan ends without a barrier',
    () {
      final cancelled = <String>[];
      final instance = runner(
        start: (_, _) {},
        events: [],
        cancel: cancelled.add,
      );
      instance.start(
        const BattleAnimationPlan(
          steps: [StartTrackedEffectStep(effectId: 'orphan')],
        ),
      );
      expect(instance.isActive, isFalse);
      expect(cancelled, ['orphan']);
    },
  );

  test('rejects a barrier nested in a parallel group', () {
    final instance = runner(start: (_, _) {}, events: []);
    expect(
      () => instance.start(
        const BattleAnimationPlan(
          steps: [
            AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [WaitTrackedEffectsStep()],
            ),
          ],
        ),
      ),
      throwsStateError,
    );
  });

  test('a replacement started by cancellation is not overwritten', () {
    final events = <String>[];
    late BattleAnimationRunner instance;
    instance = runner(
      start: (_, _) {},
      events: events,
      cancel: (_) => instance.start(
        const BattleAnimationPlan(steps: [PlaySeStep(seName: 'nested')]),
      ),
    );
    instance.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(effectId: 'old'),
          WaitTrackedEffectsStep(),
        ],
      ),
    );
    instance.start(
      const BattleAnimationPlan(steps: [PlaySeStep(seName: 'outer')]),
    );
    expect(events, ['nested']);
  });

  test('a failed effect launch cancels the plan', () {
    final instance = runner(
      start: (_, _) => throw StateError('launch'),
      events: [],
    );
    expect(
      () => instance.start(
        const BattleAnimationPlan(
          steps: [StartTrackedEffectStep(effectId: 'bad')],
        ),
      ),
      throwsStateError,
    );
    expect(instance.isActive, isFalse);
  });

  test('one failing cancellation does not leave the other effects running', () {
    final cancelled = <String>[];
    final instance = runner(
      start: (_, _) {},
      events: [],
      cancel: (id) {
        cancelled.add(id);
        if (id == 'a') throw StateError('cancel');
      },
    );
    instance.start(
      const BattleAnimationPlan(
        steps: [
          StartTrackedEffectStep(effectId: 'a'),
          StartTrackedEffectStep(effectId: 'b'),
          WaitTrackedEffectsStep(),
        ],
      ),
    );
    expect(instance.cancel, throwsStateError);
    expect(cancelled, ['a', 'b']);
    expect(instance.isActive, isFalse);
  });

  test(
    'a wait inside a parallel branch delays the next cue in that branch',
    () {
      final events = <String>[];
      final instance = runner(start: (_, _) {}, events: events);
      instance.start(
        const BattleAnimationPlan(
          steps: [
            AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [
                AnimationGroupStep(
                  mode: BattleAnimationGroupMode.sequence,
                  steps: [
                    WaitStep(durationSeconds: .2),
                    PlaySeStep(seName: 'delayed'),
                  ],
                ),
                WaitStep(durationSeconds: .3),
              ],
            ),
            PlaySeStep(seName: 'after'),
          ],
        ),
      );
      expect(events, isEmpty);
      instance.update(.19);
      expect(events, isEmpty);
      instance.update(.01);
      expect(events, ['delayed']);
      instance.update(.1);
      expect(events, ['delayed', 'after']);
    },
  );
}
