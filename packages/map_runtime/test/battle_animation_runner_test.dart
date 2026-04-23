import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';

void main() {
  group('BattleAnimationRunner', () {
    test('executes steps in order and keeps the latest message active', () {
      final events = <String>[];
      late BattleAnimationRunner runner;
      runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (step) => events.add('fx:${step.effectId}'),
        onScreenFlash: (step) => events.add('flash:${step.colorArgb}'),
        onCombatantMotion: (step) =>
            events.add('motion:${step.motionKind.name}'),
        onCombatantFlash: (step) => events.add('hitflash:${step.side.name}'),
        onCombatantShake: (step) => events.add('shake:${step.side.name}'),
        onFaintCombatant: (step) => events.add('faint:${step.side.name}'),
        onHudHpTween: (step) =>
            events.add('hp:${step.side.name}:${step.fromHp}->${step.toHp}'),
        onBarrierPulse: (step) => events.add('barrier:${step.side.name}'),
        onSwapCombatantVisual: (side) => events.add('swap:${side.name}'),
      );

      final plan = BattleAnimationPlan(
        steps: const <BattleAnimationStep>[
          ShowMessageStep(message: 'Sparkitten utilise Tackle !'),
          CombatantMotionStep(
            side: BattleSideId.player,
            motionKind: BattleCombatantMotionKind.lunge,
            durationSeconds: 0.14,
            distancePx: 24,
          ),
          SpawnFxStep(
            effectId: 'impact',
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            from: BattleVisualAnchor.defenderCenter,
            to: BattleVisualAnchor.defenderCenter,
            durationSeconds: 0.12,
          ),
          CombatantFlashStep(
            side: BattleSideId.enemy,
            durationSeconds: 0.10,
          ),
          HudHpTweenStep(
            side: BattleSideId.enemy,
            fromHp: 30,
            toHp: 18,
            durationMs: 320,
          ),
        ],
      );

      runner.start(plan);

      expect(runner.isActive, isTrue);
      expect(runner.currentMessage, equals('Sparkitten utilise Tackle !'));
      expect(events, isEmpty);

      runner.update(0.42);

      expect(events, equals(<String>['motion:lunge']));
      expect(runner.currentMessage, equals('Sparkitten utilise Tackle !'));

      runner.update(0.14);

      expect(
        events,
        equals(<String>[
          'motion:lunge',
          'fx:impact',
          'hitflash:enemy',
        ]),
      );

      runner.update(0.12);

      expect(
        events,
        equals(<String>[
          'motion:lunge',
          'fx:impact',
          'hitflash:enemy',
          'hp:enemy:30->18',
        ]),
      );
      expect(runner.currentHpTweenStep?.toHp, equals(18));

      runner.update(0.32);

      expect(runner.isActive, isFalse);
      expect(runner.currentMessage, isNull);
      expect(runner.currentHpTweenStep, isNull);
    });

    test('treats projectile travel as a blocking phase before impact accents',
        () {
      final events = <String>[];
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (step) => events.add('fx:${step.effectId}'),
        onScreenFlash: (_) {},
        onCombatantMotion: (_) {},
        onCombatantFlash: (step) => events.add('hitflash:${step.side.name}'),
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (_) {},
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
      );

      runner.start(
        const BattleAnimationPlan(
          steps: <BattleAnimationStep>[
            ShowMessageStep(message: 'Shadow Ball !'),
            SpawnFxStep(
              effectId: 'shadowball',
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              from: BattleVisualAnchor.attackerCenter,
              to: BattleVisualAnchor.defenderCenter,
              durationSeconds: 0.26,
            ),
            SpawnFxStep(
              effectId: 'impact',
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              from: BattleVisualAnchor.defenderCenter,
              to: BattleVisualAnchor.defenderCenter,
              durationSeconds: 0.12,
            ),
            CombatantFlashStep(
              side: BattleSideId.enemy,
              durationSeconds: 0.10,
            ),
          ],
        ),
      );

      runner.update(0.42);
      expect(events, equals(<String>['fx:shadowball']));

      runner.update(0.20);
      expect(events, equals(<String>['fx:shadowball']));

      runner.update(0.06);
      expect(
        events,
        equals(<String>[
          'fx:shadowball',
          'fx:impact',
          'hitflash:enemy',
        ]),
      );
    });

    test(
        'can group delayed moving fx into a single accent phase when requested',
        () {
      final events = <String>[];
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (step) =>
            events.add('fx:${step.effectId}:${step.startDelaySeconds}'),
        onScreenFlash: (_) {},
        onCombatantMotion: (_) {},
        onCombatantFlash: (step) => events.add('hitflash:${step.side.name}'),
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (_) {},
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
      );

      runner.start(
        const BattleAnimationPlan(
          steps: <BattleAnimationStep>[
            ShowMessageStep(message: 'Skill Swap !'),
            SpawnFxStep(
              effectId: 'wisp',
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              from: BattleVisualAnchor.attackerCenter,
              to: BattleVisualAnchor.defenderCenter,
              durationSeconds: 0.40,
              playAsAccent: true,
            ),
            SpawnFxStep(
              effectId: 'wisp',
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              from: BattleVisualAnchor.defenderCenter,
              to: BattleVisualAnchor.attackerCenter,
              durationSeconds: 0.40,
              startDelaySeconds: 0.20,
              playAsAccent: true,
            ),
            CombatantFlashStep(
              side: BattleSideId.enemy,
              durationSeconds: 0.10,
            ),
          ],
        ),
      );

      runner.update(0.42);
      expect(
        events,
        equals(<String>[
          'fx:wisp:0.0',
          'fx:wisp:0.2',
          'hitflash:enemy',
        ]),
      );

      runner.update(0.55);
      expect(runner.isActive, isTrue);

      runner.update(0.06);
      expect(runner.isActive, isFalse);
    });

    test('consumes leftover dt across consecutive phases', () {
      final events = <String>[];
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (_) {},
        onScreenFlash: (_) {},
        onCombatantMotion: (step) =>
            events.add('motion:${step.motionKind.name}'),
        onCombatantFlash: (_) {},
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (_) {},
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
      );

      runner.start(
        const BattleAnimationPlan(
          steps: <BattleAnimationStep>[
            ShowMessageStep(message: 'Overflow'),
            WaitStep(durationSeconds: 0.10),
            CombatantMotionStep(
              side: BattleSideId.player,
              motionKind: BattleCombatantMotionKind.lunge,
              durationSeconds: 0.10,
              distancePx: 24,
            ),
          ],
        ),
      );

      runner.update(0.60);

      expect(events, equals(<String>['motion:lunge']));
      expect(runner.isActive, isTrue);

      runner.update(0.03);

      expect(runner.isActive, isFalse);
    });

    test('cancel clears active presentation state', () {
      final runner = BattleAnimationRunner(
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
      );

      runner.start(
        const BattleAnimationPlan(
          steps: <BattleAnimationStep>[
            ShowMessageStep(message: 'Test'),
            WaitStep(durationSeconds: 1),
          ],
        ),
      );

      expect(runner.isActive, isTrue);

      runner.cancel();

      expect(runner.isActive, isFalse);
      expect(runner.currentMessage, isNull);
      expect(runner.currentHpTweenStep, isNull);
    });
  });
}
