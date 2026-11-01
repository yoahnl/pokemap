import 'dart:ui';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:flame/components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'framing geometry stays stable during idle, lunge and compression',
    () async {
      final actor = BattleSceneCombatantComponent(
        sceneSpriteRect: const Rect.fromLTWH(40, 30, 120, 120),
        scenePlatformRect: const Rect.fromLTWH(52, 136, 110, 18),
        sceneFootAnchor: const Offset(102, 140),
        spriteFootXRatio: .5,
        isPlayerSide: true,
        speciesLabel: 'actor',
      );
      final bounds = actor.stableCameraGeometry.bounds;
      actor.setIdleLateralOffset(8);
      await actor.playLunge(
        towardOpponent: true,
        distancePx: 24,
        durationSeconds: .3,
      );
      actor.update(.15);
      expect(actor.stableCameraGeometry.bounds, bounds);
      final foot = actor.stableCameraGeometry.foot;
      final focusAnchor = actor.stableCameraGeometry.focusAnchor;
      await actor.playCompress(scaleX: .2, scaleY: -.3, durationSeconds: .4);
      actor.update(.1);
      actor.applyBattleCameraTransform(offset: Vector2(36, -18), scale: 1.12);
      expect(actor.stableCameraGeometry.bounds, bounds);
      expect(actor.stableCameraGeometry.foot, foot);
      expect(actor.stableCameraGeometry.focusAnchor, focusAnchor);
      await actor.playFaint(durationSeconds: .2);
      actor.update(.2);
      expect(actor.stableCameraGeometry.bounds, bounds);
    },
  );
  test(
    'stable geometry uses cached opaque containment and authored foot ratio',
    () async {
      final directory = Directory(
        Platform.isMacOS
            ? '${Platform.environment['HOME']!}/Library/Caches/AveluneQA/battle-camera-consolidation/c2-sprite'
            : '${Directory.systemTemp.path}/avelune-battle-camera-consolidation/c2-sprite',
      );
      await directory.create(recursive: true);
      final file = File('${directory.path}/opaque.png');
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final recorder = PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(8, 0, 4, 20),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(20, 20);
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      final actor = BattleSceneCombatantComponent(
        sceneSpriteRect: const Rect.fromLTWH(40, 30, 120, 120),
        scenePlatformRect: const Rect.fromLTWH(52, 136, 110, 18),
        sceneFootAnchor: const Offset(102, 140),
        spriteFootXRatio: .68,
        isPlayerSide: true,
        speciesLabel: 'opaque',
        initialSpriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.front,
          explicitImageAbsolutePath: file.path,
        ),
      );
      await actor.onLoad();
      final geometry = actor.stableCameraGeometry;
      expect(geometry.bounds.width, closeTo(24, .001));
      expect(geometry.bounds.height, closeTo(120, .001));
      expect(geometry.foot, const Offset(102, 140));
      expect(geometry.bounds.left, closeTo(102 - 24 * .68, .001));
      expect(geometry.bounds.bottom, 140);
      actor.setIdleLateralOffset(12);
      await actor.playLunge(
        towardOpponent: true,
        distancePx: 54,
        durationSeconds: .3,
      );
      actor.update(.15);
      expect(actor.stableCameraGeometry.bounds, geometry.bounds);
    },
  );
  test('reducing a disappearing decorative dash restores its actor', () async {
    final actor = BattleSceneCombatantComponent(
      sceneSpriteRect: const Rect.fromLTWH(40, 30, 120, 120),
      scenePlatformRect: const Rect.fromLTWH(52, 136, 110, 18),
      sceneFootAnchor: const Offset(102, 140),
      spriteFootXRatio: .5,
      isPlayerSide: true,
      speciesLabel: 'actor',
    );
    await actor.playFastDash(
      towardOpponent: true,
      distancePx: 42,
      durationSeconds: .3,
    );
    actor.update(.14);
    expect(actor.currentVisualOpacity, lessThan(1));
    actor.reduceCurrentMotion();
    expect(actor.currentVisualOpacity, 1);
    expect(actor.currentVisualOffset, Offset.zero);
    actor.update(.1);
    expect(actor.currentVisualOpacity, 1);
    await actor.playFaint(durationSeconds: .2);
    actor.update(.2);
    expect(actor.currentVisualOpacity, 0);
    actor.reduceCurrentMotion();
    expect(actor.currentVisualOpacity, 0);
  });
}
