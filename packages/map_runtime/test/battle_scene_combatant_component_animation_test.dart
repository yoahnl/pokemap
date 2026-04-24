import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';

BattleSceneCombatantComponent _component() {
  return BattleSceneCombatantComponent(
    sceneSpriteRect: const Rect.fromLTWH(40, 30, 120, 120),
    scenePlatformRect: const Rect.fromLTWH(52, 136, 110, 18),
    sceneFootAnchor: const Offset(102, 140),
    spriteFootXRatio: 0.5,
    isPlayerSide: true,
    speciesLabel: 'sparkitten',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleSceneCombatantComponent animations', () {
    test('lunge changes position and then returns to battle pose', () async {
      final component = _component();
      await component.onLoad();

      final initialRect = component.currentRenderedSpriteRect;

      await component.playLunge(
        towardOpponent: true,
        distancePx: 24,
        durationSeconds: 0.30,
      );

      component.update(0.15);

      expect(
        component.currentRenderedSpriteRect.left,
        greaterThan(initialRect.left),
      );

      component.update(0.20);

      expect(
        component.currentRenderedSpriteRect.left,
        closeTo(initialRect.left, 0.01),
      );
      expect(component.currentVisualOpacity, closeTo(1.0, 0.001));
    });

    test('switch out hides the battler and switch in restores it', () async {
      final component = _component();
      await component.onLoad();

      await component.playSwitchOut(durationSeconds: 0.24);
      component.update(0.30);

      expect(component.currentVisualOpacity, lessThan(0.05));

      await component.playSwitchIn(durationSeconds: 0.24);
      component.update(0.12);

      expect(component.currentVisualOpacity, greaterThan(0.2));

      component.update(0.20);

      expect(component.currentVisualOpacity, closeTo(1.0, 0.001));
      expect(component.currentVisualOffset.dx, closeTo(0.0, 0.01));
      expect(component.currentVisualOffset.dy, closeTo(0.0, 0.01));
    });

    test('fast dash drops opacity mid-run and returns to battle pose',
        () async {
      final component = _component();
      await component.onLoad();

      final initialRect = component.currentRenderedSpriteRect;

      await component.playFastDash(
        towardOpponent: true,
        distancePx: 42,
        durationSeconds: 0.30,
      );

      component.update(0.14);

      expect(
        component.currentRenderedSpriteRect.left,
        greaterThan(initialRect.left),
      );
      expect(component.currentVisualOpacity, lessThan(1.0));

      component.update(0.20);

      expect(
        component.currentRenderedSpriteRect.left,
        closeTo(initialRect.left, 0.01),
      );
      expect(component.currentVisualOpacity, closeTo(1.0, 0.001));
    });

    test('snapToBattlePose resets faint offset and opacity', () async {
      final component = _component();
      await component.onLoad();

      await component.playFaint(durationSeconds: 0.18);
      component.update(0.30);

      expect(component.currentVisualOpacity, lessThan(0.05));

      component.snapToBattlePose();

      expect(component.currentVisualOpacity, closeTo(1.0, 0.001));
      expect(component.currentVisualOffset.dx, closeTo(0.0, 0.01));
      expect(component.currentVisualOffset.dy, closeTo(0.0, 0.01));
    });

    test('camera-neutral rects do not include battle camera transforms',
        () async {
      final component = _component();
      await component.onLoad();

      final neutralBefore = component.currentCameraNeutralRenderedSpriteRect;
      component.applyBattleCameraTransform(
        offset: Vector2(36, -18),
        scale: 1.12,
      );

      expect(
        component.currentRenderedSpriteRect.left,
        closeTo(neutralBefore.left + 36, 0.01),
      );
      expect(component.currentCameraNeutralRenderedSpriteRect.left,
          closeTo(neutralBefore.left, 0.01));
      expect(component.currentCameraNeutralRenderedSpriteRect.top,
          closeTo(neutralBefore.top, 0.01));
    });

    test('camera-neutral rect uses explicit sprite opaque aspect ratio',
        () async {
      final spritePath = await _writeTallOpaqueSpritePng();
      final component = BattleSceneCombatantComponent(
        sceneSpriteRect: const Rect.fromLTWH(40, 30, 120, 120),
        scenePlatformRect: const Rect.fromLTWH(52, 136, 110, 18),
        sceneFootAnchor: const Offset(102, 140),
        spriteFootXRatio: 0.5,
        isPlayerSide: false,
        speciesLabel: 'riolu',
        initialSpriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.front,
          explicitImageAbsolutePath: spritePath,
        ),
      );

      await component.onLoad();

      final renderedRect = component.currentCameraNeutralRenderedSpriteRect;
      expect(renderedRect.width, closeTo(24, 0.01));
      expect(renderedRect.height, closeTo(120, 0.01));
      expect(renderedRect.bottom,
          closeTo(component.currentCameraNeutralFootAnchor.dy, 0.01));
    });

    test('target impact anchor is biased toward the attacking side', () async {
      final component = BattleSceneCombatantComponent(
        sceneSpriteRect: const Rect.fromLTWH(40, 30, 120, 120),
        scenePlatformRect: const Rect.fromLTWH(52, 136, 110, 18),
        sceneFootAnchor: const Offset(102, 140),
        spriteFootXRatio: 0.5,
        isPlayerSide: false,
        speciesLabel: 'riolu',
      );

      await component.onLoad();

      final renderedRect = component.currentCameraNeutralRenderedSpriteRect;
      final impact = component.currentCameraNeutralImpactAnchorToward(
        opponentCenter: Offset(renderedRect.left - 160, renderedRect.center.dy),
      );

      expect(impact.dx, lessThan(renderedRect.center.dx));
      expect(
        impact.dy,
        closeTo(renderedRect.top + (renderedRect.height * 0.42), 0.01),
      );
    });
  });
}

Future<String> _writeTallOpaqueSpritePng() async {
  final image = await _tallOpaqueSpriteImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final directory = await Directory.systemTemp.createTemp(
    'battle_target_anchor_',
  );
  final file = File('${directory.path}/riolu_front.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  return file.path;
}

Future<ui.Image> _tallOpaqueSpriteImage() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 20),
    ui.Paint()..color = const ui.Color(0xFF2D7BFF),
  );
  return recorder.endRecording().toImage(20, 20);
}
