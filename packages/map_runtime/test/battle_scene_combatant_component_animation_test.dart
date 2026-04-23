import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test('fast dash drops opacity mid-run and returns to battle pose', () async {
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
  });
}
