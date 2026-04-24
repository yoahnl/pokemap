import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';

void main() {
  group('BattleAnimationPlan', () {
    test('plan aggregates requiredFxIds from steps', () {
      const plan = BattleAnimationPlan(
        steps: <BattleAnimationStep>[
          ShowMessageStep(message: 'Test'),
          SpawnFxStep(
            effectId: 'fireball',
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            from: BattleVisualAnchor.attackerCenter,
            to: BattleVisualAnchor.defenderCenter,
            durationSeconds: 0.3,
          ),
          SpawnFxStep(
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

    test('plan aggregates required SDK animation asset ids from new steps', () {
      const plan = BattleAnimationPlan(
        steps: <BattleAnimationStep>[
          AnimationGroupStep(
            mode: BattleAnimationGroupMode.parallel,
            steps: <BattleAnimationStep>[
              PlaySpriteSheetFxStep(
                assetId: 'aerial_ace',
                attackerSide: BattleSideId.player,
                defenderSide: BattleSideId.enemy,
                anchor: BattleVisualAnchor.defenderCenter,
                frameWidth: 208,
                frameHeight: 192,
                frameCount: 13,
                frameDurationSeconds: 0.055,
              ),
            ],
          ),
          ParticleBurstStep(
            assetId: 'circle_blurry_m_2',
            side: BattleSideId.enemy,
            anchor: BattleVisualAnchor.defenderHead,
            particleCount: 8,
            durationSeconds: 0.8,
          ),
          PlaySdkParticleSequenceStep(
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            durationSeconds: 0.45,
            particles: <SdkParticleSpec>[
              SdkParticleSpec(
                assetId: 'seed',
                anchor: BattleVisualAnchor.defenderCenter,
                startOffsetX: -18,
                startOffsetY: -36,
                endOffsetX: 8,
                endOffsetY: 22,
                startScaleX: 0.2,
                startScaleY: 0.2,
                endScaleX: 1.1,
                endScaleY: 0.8,
                startOpacity: 1,
                endOpacity: 0,
                delaySeconds: 0.05,
                durationSeconds: 0.4,
                rotationTurns: 0.25,
              ),
            ],
          ),
          SdkFallingParticlesStep(
            assetId: 'circle_blurry_m_2',
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            anchor: BattleVisualAnchor.defenderHead,
            particleCount: 6,
            durationSeconds: 0.5,
          ),
          SdkRadiusParticleStep(
            assetId: 'star_4_ring_l',
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            anchor: BattleVisualAnchor.attackerCenter,
            particleCount: 8,
            startRadiusPx: 12,
            endRadiusPx: 54,
            durationSeconds: 0.6,
          ),
          SdkScalarParticleStep(
            assetId: 'hand_front_left',
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            anchor: BattleVisualAnchor.defenderHead,
            startScaleX: 1,
            startScaleY: 0.35,
            endScaleX: 0.35,
            endScaleY: 1,
            durationSeconds: 0.35,
          ),
          SdkParticleZoomStep(
            assetId: 'seed_growth',
            attackerSide: BattleSideId.player,
            defenderSide: BattleSideId.enemy,
            anchor: BattleVisualAnchor.defenderCenter,
            startScale: 0.2,
            endScale: 1.2,
            durationSeconds: 0.45,
          ),
          WeatherParticleStep(
            assetId: 'weather_rain_drop',
            particleCount: 24,
            durationSeconds: 1.5,
          ),
          SceneTintStep(
            colorArgb: 0x663EA8FF,
            durationSeconds: 0.2,
          ),
          BattleCameraMoveStep(
            offsetX: 24,
            offsetY: -12,
            scale: 1.08,
            durationSeconds: 0.25,
          ),
          BattleCameraResetStep(durationSeconds: 0.15),
        ],
      );

      expect(
        plan.requiredFxIds,
        equals(
          <String>{
            'aerial_ace',
            'circle_blurry_m_2',
            'hand_front_left',
            'seed',
            'seed_growth',
            'star_4_ring_l',
            'weather_rain_drop',
          },
        ),
      );
    });

    test('sprite-sheet steps can preserve SDK frame sequences and durations',
        () {
      const step = PlaySpriteSheetFxStep(
        assetId: 'thunder_02',
        attackerSide: BattleSideId.player,
        defenderSide: BattleSideId.enemy,
        anchor: BattleVisualAnchor.defenderCenter,
        frameWidth: 192,
        frameHeight: 192,
        frameCount: 10,
        frameDurationSeconds: 0.05,
        columns: 2,
        frameSequence: <int>[1, 0, 1, 0],
        frameDurationsSeconds: <double>[0.05, 0.05, 0.05, 0.05],
      );

      expect(step.effectiveFrameCount, equals(4));
      expect(step.durationSeconds, closeTo(0.20, 0.0001));
    });

    test('hp tween steps are preserved as dedicated steps', () {
      const plan = BattleAnimationPlan(
        steps: <BattleAnimationStep>[
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
      const first = ShowMessageStep(message: 'first');
      const second = WaitStep(durationSeconds: 0.2);
      const third = CombatantFlashStep(
        side: BattleSideId.enemy,
        durationSeconds: 0.1,
      );
      const plan = BattleAnimationPlan(
        steps: <BattleAnimationStep>[first, second, third],
      );

      expect(identical(plan.steps[0], first), isTrue);
      expect(identical(plan.steps[1], second), isTrue);
      expect(identical(plan.steps[2], third), isTrue);
    });
  });
}
