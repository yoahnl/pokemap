import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';

BattleAnimationRunner _runner({
  void Function(PlaySeStep)? sound,
  void Function()? changed,
  void Function(HudHpTweenStep)? hp,
}) => BattleAnimationRunner(
  onPresentationChanged: changed ?? () {},
  onSpawnFx: (_) {},
  onScreenFlash: (_) {},
  onCombatantMotion: (_) {},
  onCombatantFlash: (_) {},
  onCombatantShake: (_) {},
  onFaintCombatant: (_) {},
  onHudHpTween: hp ?? (_) {},
  onBarrierPulse: (_) {},
  onSwapCombatantVisual: (_) {},
  onPlaySe: sound,
);

List<BattleAnimationStep> _sounds(int count) => [
  for (var index = 0; index < count; index++) PlaySeStep(seName: 'cue_$index'),
];

void main() {
  test(
    'a large accent phase dispatches bounded work and preserves cue order',
    () {
      final sounds = <String>[];
      final runner = _runner(sound: (step) => sounds.add(step.seName));
      runner.start(BattleAnimationPlan(steps: _sounds(1024)));
      expect(sounds.length, inInclusiveRange(1, 256));
      for (var frame = 0; frame < 40 && runner.isActive; frame++) {
        final before = sounds.length;
        runner.update(0);
        expect(sounds.length - before, lessThanOrEqualTo(256));
      }
      expect(runner.isActive, isFalse);
      expect(sounds, [for (var index = 0; index < 1024; index++) 'cue_$index']);
    },
  );

  test(
    'accent dispatch backlog retains elapsed time across phase boundaries',
    () {
      final sounds = <String>[];
      final runner = _runner(sound: (step) => sounds.add(step.seName));
      runner.start(
        BattleAnimationPlan(
          steps: [
            const WaitStep(durationSeconds: .1),
            ..._sounds(1024),
            const WaitStep(durationSeconds: .2),
          ],
        ),
      );
      runner.update(.3);
      expect(sounds.length, inInclusiveRange(1, 256));
      expect(runner.isActive, isTrue);
      for (var frame = 0; frame < 40 && runner.isActive; frame++) {
        runner.update(0);
      }
      expect(runner.isActive, isFalse);
      expect(sounds.toSet(), hasLength(1024));
      expect(sounds, hasLength(1024));
    },
  );

  test('cancellation from an accent callback invalidates the old dispatch', () {
    final sounds = <String>[];
    late BattleAnimationRunner runner;
    runner = _runner(
      sound: (step) {
        sounds.add(step.seName);
        runner.cancel();
      },
    );
    expect(
      () => runner.start(BattleAnimationPlan(steps: _sounds(1024))),
      returnsNormally,
    );
    runner.update(1);
    expect(sounds, ['cue_0']);
    expect(runner.isActive, isFalse);
  });
  test('zero waits yield without consuming logical time', () {
    var changes = 0;
    final runner = _runner(changed: () => changes++);
    runner.start(
      BattleAnimationPlan(
        steps: [
          for (var index = 0; index < 1024; index++)
            const WaitStep(durationSeconds: 0),
          const ShowMessageStep(message: 'ready'),
        ],
      ),
    );
    expect(changes, lessThanOrEqualTo(256));
    expect(runner.currentMessage, isNull);
    for (var frame = 0; frame < 40 && runner.currentMessage == null; frame++) {
      final before = changes;
      runner.update(0);
      expect(changes - before, lessThanOrEqualTo(256));
    }
    expect(runner.currentMessage, 'ready');
    runner.update(.42);
    expect(runner.isActive, isFalse);
  });

  test('replacement from a cue cannot resume the cancelled plan', () {
    final sounds = <String>[];
    late BattleAnimationRunner runner;
    runner = _runner(
      sound: (step) {
        sounds.add(step.seName);
        if (step.seName == 'cue_0') {
          runner.start(
            const BattleAnimationPlan(
              steps: [
                PlaySeStep(seName: 'replacement'),
                WaitStep(durationSeconds: .5),
              ],
            ),
          );
        }
      },
    );
    expect(
      () => runner.start(BattleAnimationPlan(steps: _sounds(1024))),
      returnsNormally,
    );
    runner.update(0);
    expect(sounds, ['cue_0', 'replacement']);
    expect(runner.isActive, isTrue);
    runner.update(.5);
    expect(runner.isActive, isFalse);
  });

  test('replacement discards the previous elapsed time debt', () {
    final sounds = <String>[];
    late BattleAnimationRunner runner;
    runner = _runner(
      sound: (step) {
        sounds.add(step.seName);
        if (step.seName == 'cue_0') {
          runner.start(
            const BattleAnimationPlan(
              steps: [
                WaitStep(durationSeconds: .5),
                PlaySeStep(seName: 'replacement'),
              ],
            ),
          );
        }
      },
    );
    runner.start(
      BattleAnimationPlan(
        steps: [const WaitStep(durationSeconds: .1), ..._sounds(1024)],
      ),
    );
    runner.update(10);
    runner.update(0);
    expect(sounds, ['cue_0']);
    runner.update(.5);
    expect(sounds, ['cue_0', 'replacement']);
  });

  test('invalid deltas preserve phase state and cue order', () {
    final sounds = <String>[];
    final runner = _runner(sound: (step) => sounds.add(step.seName));
    runner.start(
      const BattleAnimationPlan(
        steps: [
          WaitStep(durationSeconds: .5),
          PlaySeStep(seName: 'after'),
        ],
      ),
    );
    for (final dt in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      runner.update(dt);
      expect(sounds, isEmpty);
      expect(runner.isActive, isTrue);
      expect(runner.secondsUntilNextPhase, .5);
    }
    runner.update(.5);
    expect(sounds, ['after']);
    expect(runner.isActive, isFalse);
  });

  test('delayed parallel cues preserve HP and sound ordering after yield', () {
    final events = <String>[];
    final runner = _runner(
      sound: (step) => events.add(step.seName),
      hp: (_) => events.add('hp'),
    );
    runner.start(
      BattleAnimationPlan(
        steps: [
          AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: [
              AnimationGroupStep(
                mode: BattleAnimationGroupMode.sequence,
                steps: [
                  const ScreenFlashStep(colorArgb: 0, durationSeconds: .1),
                  ..._sounds(1024),
                  const HudHpTweenStep(
                    side: BattleSideId.enemy,
                    fromHp: 10,
                    toHp: 5,
                    durationMs: 200,
                  ),
                ],
              ),
              const PlaySeStep(seName: 'parallel'),
            ],
          ),
          const PlaySeStep(seName: 'after'),
        ],
      ),
    );
    expect(events, ['parallel']);
    runner.update(.3);
    expect(events.length, lessThanOrEqualTo(257));
    for (var frame = 0; frame < 40 && runner.isActive; frame++) {
      final before = events.length;
      runner.update(0);
      expect(events.length - before, lessThanOrEqualTo(256));
    }
    expect(events, [
      'parallel',
      for (var index = 0; index < 1024; index++) 'cue_$index',
      'hp',
      'after',
    ]);
    expect(runner.isActive, isFalse);
  });
  test('recursive replacements share the outer dispatch budget', () {
    final sounds = <String>[];
    late BattleAnimationRunner runner;
    runner = _runner(
      sound: (step) {
        sounds.add(step.seName);
        if (sounds.length < 1024) {
          runner.start(
            BattleAnimationPlan(
              steps: [PlaySeStep(seName: 'replacement_${sounds.length}')],
            ),
          );
        }
      },
    );
    runner.start(
      const BattleAnimationPlan(steps: [PlaySeStep(seName: 'first')]),
    );
    expect(sounds.length, inInclusiveRange(1, 256));
    for (var frame = 0; frame < 40 && runner.isActive; frame++) {
      final before = sounds.length;
      runner.update(0);
      expect(sounds.length - before, lessThanOrEqualTo(256));
    }
    expect(sounds, hasLength(1024));
    expect(sounds.toSet(), hasLength(1024));
    expect(runner.isActive, isFalse);
  });

  test('HP callback replacement cannot overwrite the new phase duration', () {
    late BattleAnimationRunner runner;
    final sounds = <String>[];
    runner = _runner(
      sound: (step) => sounds.add(step.seName),
      hp: (_) => runner.start(
        const BattleAnimationPlan(
          steps: [
            WaitStep(durationSeconds: .5),
            PlaySeStep(seName: 'replacement'),
          ],
        ),
      ),
    );
    runner.start(
      const BattleAnimationPlan(
        steps: [
          HudHpTweenStep(
            side: BattleSideId.enemy,
            fromHp: 10,
            toHp: 5,
            durationMs: 200,
          ),
          PlaySeStep(seName: 'obsolete'),
        ],
      ),
    );
    expect(runner.currentHpTweenStep, isNull);
    expect(runner.secondsUntilNextPhase, .5);
    runner.update(.2);
    expect(sounds, isEmpty);
    runner.update(.3);
    expect(sounds, ['replacement']);
    expect(runner.isActive, isFalse);
  });

  test(
    'presentation callback replacement cannot clear the new phase state',
    () {
      late BattleAnimationRunner runner;
      var replaced = false;
      final sounds = <String>[];
      runner = _runner(
        sound: (step) => sounds.add(step.seName),
        changed: () {
          if (!replaced) {
            replaced = true;
            runner.start(
              const BattleAnimationPlan(
                steps: [
                  WaitStep(durationSeconds: .5),
                  PlaySeStep(seName: 'replacement'),
                ],
              ),
            );
          }
        },
      );
      runner.start(
        const BattleAnimationPlan(
          steps: [
            WaitStep(durationSeconds: 0),
            PlaySeStep(seName: 'obsolete'),
          ],
        ),
      );
      expect(runner.secondsUntilNextPhase, .5);
      runner.update(.5);
      expect(sounds, ['replacement']);
      expect(runner.isActive, isFalse);
    },
  );

  test('backlog exposes zero next phase time until the pending cues drain', () {
    final runner = _runner();
    runner.start(
      BattleAnimationPlan(
        steps: [..._sounds(1024), const WaitStep(durationSeconds: .5)],
      ),
    );
    expect(runner.hasImmediateWork, isTrue);
    expect(runner.secondsUntilNextPhase, 0);
    for (var frame = 0; frame < 40 && runner.hasImmediateWork; frame++) {
      runner.update(0);
    }
    expect(runner.hasImmediateWork, isFalse);
    expect(runner.secondsUntilNextPhase, .5);
    runner.update(.5);
    expect(runner.secondsUntilNextPhase, double.infinity);
  });
}
