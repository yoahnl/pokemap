import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_bundle_cache.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_layer_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_sprite_component.dart';

Future<ui.Image> _fakeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 12, 12),
    ui.Paint()..color = const ui.Color(0xFF66CCFF),
  );
  return recorder.endRecording().toImage(12, 12);
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

    test('supports styled barrier pulses and clears them after completion', () async {
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
