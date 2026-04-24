import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_bundle_cache.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_layer_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_sprite_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_sprite_sheet_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_rmxp_animation_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_particle_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';

Future<ui.Image> _fakeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 12, 12),
    ui.Paint()..color = const ui.Color(0xFF66CCFF),
  );
  return recorder.endRecording().toImage(12, 12);
}

Future<ui.Image> _fakeSpriteSheetImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 384, 384),
    ui.Paint()..color = const ui.Color(0xFF88CCFF),
  );
  return recorder.endRecording().toImage(384, 384);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleFxLayerComponent', () {
    test('spawns a sprite for a SpawnFxStep and removes it after completion',
        () async {
      final cache = BattleFxBundleCache(
        imageLoader: (_) => _fakeImage(),
      );
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: cache,
      );

      await layer.onLoad();
      await layer.playFx(
        const SpawnFxStep(
          effectId: 'fireball',
          attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy,
          from: BattleVisualAnchor.attackerCenter,
          to: BattleVisualAnchor.defenderCenter,
          durationSeconds: 0.20,
        ),
        BattleFxRuntimeContext(
          sceneSize: Vector2(320, 180),
          resolveAnchor: ({
            required BattleVisualAnchor anchor,
            required BattleSideId attackerSide,
            required BattleSideId defenderSide,
          }) {
            return switch (anchor) {
              BattleVisualAnchor.attackerCenter => Vector2(48, 124),
              BattleVisualAnchor.attackerHead => Vector2(48, 96),
              BattleVisualAnchor.defenderCenter => Vector2(248, 56),
              BattleVisualAnchor.defenderHead => Vector2(248, 34),
              BattleVisualAnchor.screenCenter => Vector2(160, 90),
              _ => Vector2(160, 90),
            };
          },
        ),
      );

      expect(layer.activeFxCount, equals(1));

      layer.updateTree(0.10);
      expect(layer.activeFxCount, equals(1));

      layer.updateTree(0.20);
      expect(layer.activeFxCount, equals(0));
    });

    test('screen flash appears and disappears', () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: BattleFxBundleCache(imageLoader: (_) => _fakeImage()),
      );

      await layer.onLoad();
      layer.playScreenFlash(
        const ScreenFlashStep(
          colorArgb: 0x88FFFFFF,
          durationSeconds: 0.18,
        ),
      );

      expect(layer.activeScreenFlashCount, equals(1));

      layer.updateTree(0.20);

      expect(layer.activeScreenFlashCount, equals(0));
    });

    test('plays SDK sprite sheets frame by frame and removes them', () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: BattleFxBundleCache(
          imageLoader: (_) => _fakeSpriteSheetImage(),
        ),
      );

      await layer.onLoad();
      await layer.playSpriteSheetFx(
        const PlaySpriteSheetFxStep(
          assetId: 'aerial_ace',
          attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy,
          anchor: BattleVisualAnchor.defenderCenter,
          frameWidth: 96,
          frameHeight: 96,
          frameCount: 13,
          frameDurationSeconds: 0.05,
          columns: 4,
        ),
        BattleFxRuntimeContext(
          sceneSize: Vector2(320, 180),
          resolveAnchor: ({
            required BattleVisualAnchor anchor,
            required BattleSideId attackerSide,
            required BattleSideId defenderSide,
          }) {
            return Vector2(248, 56);
          },
        ),
      );

      expect(layer.activeSpriteSheetFxCount, equals(1));

      layer.updateTree(0.20);
      expect(layer.activeSpriteSheetFxCount, equals(1));

      layer.updateTree(0.50);
      expect(layer.activeSpriteSheetFxCount, equals(0));
    });

    test('sprite sheets on combatants respect the real attacker context',
        () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: BattleFxBundleCache(
          imageLoader: (_) => _fakeSpriteSheetImage(),
        ),
      );
      final attackerAnchor = Vector2(248, 56);
      final defenderAnchor = Vector2(72, 124);

      await layer.onLoad();
      await layer.playSpriteSheetOnCombatant(
        const SpriteSheetOnCombatantStep(
          assetId: 'stat_up',
          side: BattleSideId.enemy,
          attackerSide: BattleSideId.enemy,
          defenderSide: BattleSideId.player,
          frameWidth: 192,
          frameHeight: 192,
          frameCount: 5,
          frameDurationSeconds: 0.05,
          columns: 5,
          originX: 96,
          originY: 96,
        ),
        BattleFxRuntimeContext(
          sceneSize: Vector2(320, 180),
          resolveAnchor: ({
            required BattleVisualAnchor anchor,
            required BattleSideId attackerSide,
            required BattleSideId defenderSide,
          }) {
            expect(attackerSide, equals(BattleSideId.enemy));
            expect(defenderSide, equals(BattleSideId.player));
            return switch (anchor) {
              BattleVisualAnchor.attackerCenter => attackerAnchor.clone(),
              BattleVisualAnchor.defenderCenter => defenderAnchor.clone(),
              _ => Vector2(160, 90),
            };
          },
        ),
      );

      final sheet =
          layer.children.whereType<BattleFxSpriteSheetComponent>().single;
      final defaultScale = BattleFxCatalog.require('stat_up').defaultScale;
      expect(sheet.position.x,
          closeTo(attackerAnchor.x - (96 * defaultScale), 0.01));
      expect(sheet.position.y,
          closeTo(attackerAnchor.y - (96 * defaultScale), 0.01));
    });

    test('sprite sheet component follows explicit SDK frame sequences',
        () async {
      final image = await _fakeSpriteSheetImage();
      final component = BattleFxSpriteSheetComponent(
        image: image,
        anchorPosition: Vector2.zero(),
        frameWidth: 96,
        frameHeight: 96,
        frameCount: 4,
        frameDurationSeconds: 0.10,
        columns: 4,
        originX: 0,
        originY: 0,
        displayScale: 1,
        opacity: 1,
        frameSequence: const <int>[1, 0, 1, 0],
        frameDurationsSeconds: const <double>[0.05, 0.15, 0.05, 0.05],
      );

      expect(component.currentSourceFrameIndex, equals(1));
      component.update(0.06);
      expect(component.currentSourceFrameIndex, equals(0));
      expect(component.currentSourceRect.left, equals(0));
      expect(component.currentSourceRect.top, equals(0));
      component.update(0.16);
      expect(component.currentSourceFrameIndex, equals(1));
      expect(component.isAnimationComplete, isFalse);
      component.update(0.10);
      expect(component.isAnimationComplete, isTrue);
    });

    test('particle burst applies SDK particle tint', () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: BattleFxBundleCache(imageLoader: (_) => _fakeImage()),
      );

      await layer.onLoad();
      await layer.playParticleBurst(
        const ParticleBurstStep(
          assetId: 'circle_blurry_m_2',
          side: BattleSideId.enemy,
          anchor: BattleVisualAnchor.defenderHead,
          particleCount: 1,
          durationSeconds: 0.40,
          colorArgb: 0xCCB942F4,
        ),
        BattleFxRuntimeContext(
          sceneSize: Vector2(320, 180),
          resolveAnchor: ({
            required BattleVisualAnchor anchor,
            required BattleSideId attackerSide,
            required BattleSideId defenderSide,
          }) {
            return Vector2(248, 56);
          },
        ),
      );

      final particle =
          layer.children.whereType<BattleFxSpriteComponent>().single;
      expect(particle.tintColor, equals(const ui.Color(0xCCB942F4)));
    });

    test('plays SDK particle sequences with per-particle paths and cleanup',
        () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: BattleFxBundleCache(imageLoader: (_) => _fakeImage()),
      );

      await layer.onLoad();
      await layer.playSdkParticleSequence(
        const PlaySdkParticleSequenceStep(
          attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy,
          durationSeconds: 0.42,
          particles: <SdkParticleSpec>[
            SdkParticleSpec(
              assetId: 'circle_blurry_m_2',
              anchor: BattleVisualAnchor.defenderHead,
              startOffsetX: -12,
              startOffsetY: -44,
              endOffsetX: 8,
              endOffsetY: 20,
              startScaleX: 0.2,
              startScaleY: 0.4,
              endScaleX: 0.8,
              endScaleY: 1.1,
              startOpacity: 1,
              endOpacity: 0,
              delaySeconds: 0.05,
              durationSeconds: 0.32,
              colorArgb: 0xCCB942F4,
              rotationTurns: 0.5,
            ),
          ],
        ),
        BattleFxRuntimeContext(
          sceneSize: Vector2(320, 180),
          resolveAnchor: ({
            required BattleVisualAnchor anchor,
            required BattleSideId attackerSide,
            required BattleSideId defenderSide,
          }) {
            return Vector2(248, 56);
          },
        ),
      );

      expect(layer.activeSdkParticleCount, equals(1));
      final particle =
          layer.children.whereType<BattleSdkParticleComponent>().single;
      expect(particle.tintColor, equals(const ui.Color(0xCCB942F4)));
      expect(particle.currentScaleX, closeTo(0.2, 0.001));
      expect(particle.currentScaleY, closeTo(0.4, 0.001));

      layer.updateTree(0.22);
      expect(layer.activeSdkParticleCount, equals(1));
      expect(particle.currentScaleX, isNot(equals(particle.currentScaleY)));

      layer.updateTree(0.40);
      expect(layer.activeSdkParticleCount, equals(0));
    });

    test('plays SDK exact particle primitives as individual particles',
        () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: BattleFxBundleCache(imageLoader: (_) => _fakeImage()),
      );
      final ctx = BattleFxRuntimeContext(
        sceneSize: Vector2(320, 180),
        resolveAnchor: ({
          required BattleVisualAnchor anchor,
          required BattleSideId attackerSide,
          required BattleSideId defenderSide,
        }) {
          return switch (anchor) {
            BattleVisualAnchor.attackerCenter => Vector2(80, 112),
            BattleVisualAnchor.attackerHead => Vector2(80, 72),
            BattleVisualAnchor.defenderCenter => Vector2(240, 76),
            BattleVisualAnchor.defenderHead => Vector2(240, 40),
            BattleVisualAnchor.screenCenter => Vector2(160, 90),
            _ => Vector2(160, 90),
          };
        },
      );

      await layer.playSdkFallingParticles(
        const SdkFallingParticlesStep(
          assetId: 'circle_blurry_m_2',
          attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy,
          anchor: BattleVisualAnchor.defenderHead,
          particleCount: 5,
          durationSeconds: 0.30,
          colorArgb: 0xCCB942F4,
        ),
        ctx,
      );
      await layer.playSdkRadiusParticles(
        const SdkRadiusParticleStep(
          assetId: 'star_4_ring_l',
          attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy,
          anchor: BattleVisualAnchor.attackerCenter,
          particleCount: 4,
          startRadiusPx: 8,
          endRadiusPx: 36,
          durationSeconds: 0.30,
        ),
        ctx,
      );
      await layer.playSdkScalarParticle(
        const SdkScalarParticleStep(
          assetId: 'hand_front_left',
          attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy,
          anchor: BattleVisualAnchor.defenderHead,
          startScaleX: 1,
          startScaleY: 0.35,
          endScaleX: 0.35,
          endScaleY: 1,
          durationSeconds: 0.30,
        ),
        ctx,
      );
      await layer.playSdkParticleZoom(
        const SdkParticleZoomStep(
          assetId: 'seed_growth',
          attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy,
          anchor: BattleVisualAnchor.defenderCenter,
          startScale: 0.2,
          endScale: 1.2,
          durationSeconds: 0.30,
        ),
        ctx,
      );

      expect(layer.activeSdkParticleCount, equals(11));

      layer.updateTree(0.65);

      expect(layer.activeSdkParticleCount, equals(0));
    });

    test('plays RMXP animations and removes them after completion', () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: BattleFxBundleCache(
          imageLoader: (_) => _fakeSpriteSheetImage(),
        ),
      );

      await layer.onLoad();
      await layer.playRmxpAnimation(
        const PlayRmxpAnimationStep(
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
        BattleFxRuntimeContext(
          sceneSize: Vector2(320, 180),
          resolveAnchor: ({
            required BattleVisualAnchor anchor,
            required BattleSideId attackerSide,
            required BattleSideId defenderSide,
          }) {
            return Vector2(248, 56);
          },
        ),
      );

      expect(layer.activeRmxpFxCount, equals(1));

      layer.updateTree(0.50);
      expect(layer.activeRmxpFxCount, equals(1));

      layer.updateTree(1.0);
      expect(layer.activeRmxpFxCount, equals(0));
    });

    test('anchors RMXP screen animations near the attacker in the battle scene',
        () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(760, 674),
        fxBundleCache: BattleFxBundleCache(
          imageLoader: (_) => _fakeSpriteSheetImage(),
        ),
      );
      final attackerAnchor = Vector2(520, 360);
      final defenderAnchor = Vector2(160, 500);

      await layer.onLoad();
      await layer.playRmxpAnimation(
        const PlayRmxpAnimationStep(
          animationId: 81,
          subjectSide: BattleSideId.player,
          attackerSide: BattleSideId.enemy,
          defenderSide: BattleSideId.player,
          phase: RmxpPlacementPhase.target,
          placementSpec: RmxpPlacementSpec(
            policy: RmxpPlacementPolicy.projectileLine,
            sourceAnchor: BattleVisualAnchor.attackerMouth,
            targetAnchor: BattleVisualAnchor.defenderImpact,
          ),
          reverse: true,
        ),
        BattleFxRuntimeContext(
          sceneSize: Vector2(760, 674),
          resolveAnchor: ({
            required BattleVisualAnchor anchor,
            required BattleSideId attackerSide,
            required BattleSideId defenderSide,
          }) {
            return switch (anchor) {
              BattleVisualAnchor.attackerCenter => attackerAnchor.clone(),
              BattleVisualAnchor.attackerHead => attackerAnchor.clone()
                ..add(Vector2(0, -48)),
              BattleVisualAnchor.attackerMouth => attackerAnchor.clone()
                ..add(Vector2(-16, -36)),
              BattleVisualAnchor.attackerHand => attackerAnchor.clone()
                ..add(Vector2(-12, -8)),
              BattleVisualAnchor.defenderCenter => defenderAnchor.clone(),
              BattleVisualAnchor.defenderHead => defenderAnchor.clone()
                ..add(Vector2(0, -48)),
              BattleVisualAnchor.defenderImpact => defenderAnchor.clone()
                ..add(Vector2(0, -30)),
              BattleVisualAnchor.screenCenter => Vector2(380, 337),
              _ => Vector2(380, 337),
            };
          },
        ),
      );

      final rmxp =
          layer.children.whereType<BattleRmxpAnimationComponent>().single;
      layer.updateTree(RmxpAnimationSpec.frameDurationSeconds * 2);

      final firstCell = rmxp.visibleCellsForTesting.first;
      expect(
        (firstCell.destinationRect.center -
                Offset(attackerAnchor.x, attackerAnchor.y))
            .distance,
        lessThan(120),
      );
    });

    test('applies anchor offsets to spawned fx positions', () async {
      final cache = BattleFxBundleCache(
        imageLoader: (_) => _fakeImage(),
      );
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: cache,
      );

      await layer.onLoad();
      await layer.playFx(
        const SpawnFxStep(
          effectId: 'fireball',
          attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy,
          from: BattleVisualAnchor.attackerCenter,
          to: BattleVisualAnchor.attackerCenter,
          durationSeconds: 0.20,
          fromOffsetX: 12,
          fromOffsetY: -18,
          toOffsetX: 12,
          toOffsetY: -18,
        ),
        BattleFxRuntimeContext(
          sceneSize: Vector2(320, 180),
          resolveAnchor: ({
            required BattleVisualAnchor anchor,
            required BattleSideId attackerSide,
            required BattleSideId defenderSide,
          }) {
            return Vector2(48, 124);
          },
        ),
      );

      final sprite = layer.children.whereType<BattleFxSpriteComponent>().single;
      expect(sprite.position.x, closeTo(60, 0.01));
      expect(sprite.position.y, closeTo(106, 0.01));
    });

    test('supports styled barrier pulses and clears them after completion',
        () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: BattleFxBundleCache(imageLoader: (_) => _fakeImage()),
      );

      await layer.onLoad();
      layer.playBarrierPulse(
        const BarrierPulseStep(
          side: BattleSideId.player,
          colorArgb: 0x99A7F4FF,
          durationSeconds: 0.20,
          style: BattleBarrierStyle.lightScreen,
        ),
        targetRect: const ui.Rect.fromLTWH(40, 40, 80, 80),
      );

      expect(layer.activeBarrierCount, equals(1));

      layer.updateTree(0.25);

      expect(layer.activeBarrierCount, equals(0));
    });

    test('syncs persistent weather and pseudo-weather ambience', () async {
      final layer = BattleFxLayerComponent(
        size: Vector2(320, 180),
        fxBundleCache: BattleFxBundleCache(imageLoader: (_) => _fakeImage()),
      );

      await layer.onLoad();
      layer.syncFieldAmbient(
        weather: BattleWeatherId.rain,
        pseudoWeather: BattlePseudoWeatherId.trickRoom,
      );

      expect(layer.hasWeatherAmbient, isTrue);
      expect(layer.hasPseudoWeatherAmbient, isTrue);

      layer.syncFieldAmbient(
        weather: null,
        pseudoWeather: null,
      );

      expect(layer.hasWeatherAmbient, isFalse);
      expect(layer.hasPseudoWeatherAmbient, isFalse);
    });
  });
}
