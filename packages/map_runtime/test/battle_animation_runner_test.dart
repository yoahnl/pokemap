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

      const plan = BattleAnimationPlan(
        steps: <BattleAnimationStep>[
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

    test('parallel groups wait for their longest child duration', () {
      final events = <String>[];
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (step) => events.add('fx:${step.effectId}'),
        onScreenFlash: (step) => events.add('flash:${step.durationSeconds}'),
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
            AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: <BattleAnimationStep>[
                SpawnFxStep(
                  effectId: 'star',
                  attackerSide: BattleSideId.player,
                  defenderSide: BattleSideId.enemy,
                  from: BattleVisualAnchor.attackerCenter,
                  to: BattleVisualAnchor.defenderCenter,
                  durationSeconds: 0.40,
                  playAsAccent: true,
                ),
                ScreenFlashStep(
                  colorArgb: 0x22FFFFFF,
                  durationSeconds: 0.10,
                ),
              ],
            ),
            ShowMessageStep(message: 'after'),
          ],
        ),
      );

      expect(events, equals(<String>['fx:star', 'flash:0.1']));

      runner.update(0.39);
      expect(runner.currentMessage, isNull);
      runner.update(0.01);
      expect(runner.currentMessage, equals('after'));
    });

    test('sequence groups dispatch children one after another', () {
      final events = <String>[];
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (step) => events.add('fx:${step.effectId}'),
        onScreenFlash: (_) => events.add('flash'),
        onCombatantMotion: (_) {},
        onCombatantFlash: (step) => events.add('hit:${step.side.name}'),
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (_) {},
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
      );

      runner.start(
        const BattleAnimationPlan(
          steps: <BattleAnimationStep>[
            ShowMessageStep(message: 'nested'),
            AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: <BattleAnimationStep>[
                AnimationGroupStep(
                  mode: BattleAnimationGroupMode.sequence,
                  steps: <BattleAnimationStep>[
                    ScreenFlashStep(
                      colorArgb: 0x22FFFFFF,
                      durationSeconds: 0.10,
                    ),
                    CombatantFlashStep(
                      side: BattleSideId.enemy,
                      durationSeconds: 0.10,
                    ),
                  ],
                ),
                SpawnFxStep(
                  effectId: 'star',
                  attackerSide: BattleSideId.player,
                  defenderSide: BattleSideId.enemy,
                  from: BattleVisualAnchor.attackerCenter,
                  to: BattleVisualAnchor.defenderCenter,
                  durationSeconds: 0.25,
                  playAsAccent: true,
                ),
              ],
            ),
          ],
        ),
      );

      runner.update(0.42);
      expect(events, equals(<String>['flash', 'fx:star']));

      runner.update(0.099);
      expect(events, equals(<String>['flash', 'fx:star']));

      runner.update(0.001);
      expect(events, equals(<String>['flash', 'fx:star', 'hit:enemy']));
    });

    test('runner dispatches SDK combatant visual primitive steps', () {
      final events = <String>[];
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
        onCombatantTone: (step) => events.add('tone:${step.side.name}'),
        onCombatantCompress: (step) => events.add('compress:${step.side.name}'),
        onCombatantEllipse: (step) => events.add('ellipse:${step.side.name}'),
        onSdkParticleSequence: (step) =>
            events.add('sdkparticles:${step.particles.length}'),
        onCameraFocus: (step) => events.add('camera:${step.target.name}'),
        onBattleCameraMove: (step) => events.add('cameramove:${step.scale}'),
        onBattleCameraReset: (step) =>
            events.add('camerareset:${step.durationSeconds}'),
        onSdkFallingParticles: (step) =>
            events.add('falling:${step.assetId}:${step.particleCount}'),
        onSdkRadiusParticles: (step) =>
            events.add('radius:${step.assetId}:${step.particleCount}'),
        onSdkScalarParticle: (step) => events.add('scalar:${step.assetId}'),
        onSdkParticleZoom: (step) => events.add('zoom:${step.assetId}'),
      );

      runner.start(
        const BattleAnimationPlan(
          steps: <BattleAnimationStep>[
            CombatantToneStep(
              side: BattleSideId.enemy,
              colorArgb: 0xCCB942F4,
              durationSeconds: 0.2,
            ),
            CombatantCompressStep(
              side: BattleSideId.enemy,
              scaleX: -0.2,
              scaleY: 0.2,
              durationSeconds: 0.15,
              iteration: 5,
            ),
            CombatantEllipseStep(
              side: BattleSideId.player,
              radiusX: 18,
              radiusY: 9,
              turns: 2,
              durationSeconds: 1.5,
            ),
            PlaySdkParticleSequenceStep(
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              durationSeconds: 0.2,
              particles: <SdkParticleSpec>[
                SdkParticleSpec(
                  assetId: 'circle_blurry_m_2',
                  anchor: BattleVisualAnchor.defenderHead,
                  startOffsetX: 0,
                  startOffsetY: -16,
                  endOffsetX: 0,
                  endOffsetY: 24,
                  startScaleX: 0.2,
                  startScaleY: 0.4,
                  endScaleX: 0.9,
                  endScaleY: 0.9,
                  startOpacity: 1,
                  endOpacity: 0,
                  delaySeconds: 0,
                  durationSeconds: 0.2,
                  colorArgb: 0xCCB942F4,
                ),
              ],
            ),
            CameraFocusStep(
              target: BattleCameraFocusTarget.target,
              durationSeconds: 0.2,
            ),
            BattleCameraMoveStep(
              offsetX: 16,
              offsetY: -8,
              scale: 1.04,
              durationSeconds: 0.2,
            ),
            BattleCameraResetStep(durationSeconds: 0.1),
            SdkFallingParticlesStep(
              assetId: 'circle_blurry_m_2',
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              anchor: BattleVisualAnchor.defenderHead,
              particleCount: 4,
              durationSeconds: 0.2,
            ),
            SdkRadiusParticleStep(
              assetId: 'star_4_ring_l',
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              anchor: BattleVisualAnchor.attackerCenter,
              particleCount: 5,
              startRadiusPx: 8,
              endRadiusPx: 36,
              durationSeconds: 0.2,
            ),
            SdkScalarParticleStep(
              assetId: 'hand_front_left',
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              anchor: BattleVisualAnchor.defenderHead,
              startScaleX: 1,
              startScaleY: 0.4,
              endScaleX: 0.4,
              endScaleY: 1,
              durationSeconds: 0.2,
            ),
            SdkParticleZoomStep(
              assetId: 'seed_growth',
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              anchor: BattleVisualAnchor.defenderCenter,
              startScale: 0.2,
              endScale: 1.1,
              durationSeconds: 0.2,
            ),
          ],
        ),
      );

      expect(
        events,
        equals(<String>[
          'tone:enemy',
          'compress:enemy',
          'ellipse:player',
          'sdkparticles:1',
          'camera:target',
          'cameramove:1.04',
          'camerareset:0.1',
          'falling:circle_blurry_m_2:4',
          'radius:star_4_ring_l:5',
          'scalar:hand_front_left',
          'zoom:seed_growth',
        ]),
      );
    });

    test('runner dispatches RMXP animation steps as accent phases', () {
      final events = <String>[];
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
        onRmxpAnimation: (step) => events.add('rmxp:${step.animationId}'),
      );

      runner.start(
        const BattleAnimationPlan(
          steps: <BattleAnimationStep>[
            PlayRmxpAnimationStep(
              animationId: 84,
              subjectSide: BattleSideId.enemy,
              attackerSide: BattleSideId.player,
              defenderSide: BattleSideId.enemy,
              phase: RmxpPlacementPhase.target,
              placementSpec: RmxpPlacementSpec(
                policy: RmxpPlacementPolicy.targetImpact,
                anchor: BattleVisualAnchor.defenderImpact,
              ),
            ),
          ],
        ),
      );

      expect(events, equals(<String>['rmxp:84']));
      expect(runner.isActive, isTrue);
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
