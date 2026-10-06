import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_visual_asset_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final isPlayerSide in [true, false]) {
    test(
        'combatant $isPlayerSide retains sprite and platform without a ground shadow',
        () async {
      final spriteRecorder = ui.PictureRecorder();
      Canvas(spriteRecorder)
        ..drawRect(const Rect.fromLTWH(0, 0, 20, 10),
            Paint()..color = const Color(0xffff0000))
        ..drawRect(const Rect.fromLTWH(0, 10, 20, 10),
            Paint()..color = const Color(0xff0000ff));
      final spritePicture = spriteRecorder.endRecording();
      final sprite = await spritePicture.toImage(20, 20);
      spritePicture.dispose();
      final cache = BattleVisualAssetCache(imageLoader: (_) async => sprite);
      addTearDown(cache.dispose);
      final component = BattleSceneCombatantComponent(
        sceneSpriteRect: const Rect.fromLTWH(30, 0, 20, 20),
        scenePlatformRect: const Rect.fromLTWH(0, 40, 80, 16),
        sceneFootAnchor: const Offset(40, 20),
        spriteFootXRatio: 0.5,
        isPlayerSide: isPlayerSide,
        speciesLabel: 'fixture',
        visualAssetCache: cache,
      );
      await component.sync(
        speciesLabel: 'fixture',
        spriteSpec: BattleCombatantSpriteSpec(
          facing: isPlayerSide
              ? BattleCombatantSpriteFacing.back
              : BattleCombatantSpriteFacing.front,
          explicitImageAbsolutePath: '/fixture/combatant.png',
        ),
      );

      expect(component.hasResolvedExplicitSprite, isTrue);
      expect(component.currentRenderedSpriteRect,
          const Rect.fromLTWH(30, 0, 20, 20));
      expect(component.currentPlatformRect, const Rect.fromLTWH(0, 40, 80, 16));
      final actual = await _pixels(component.renderTree);
      for (var y = 24; y < 40; y++) {
        for (var x = 0; x < 80; x++) {
          expect(actual[((y * 80) + x) * 4 + 3], 0,
              reason: 'No generated ground shadow at ($x, $y)');
        }
      }
      final expected = await _pixels((canvas) {
        canvas.drawOval(
          const Rect.fromLTWH(0, 40, 80, 16),
          Paint()
            ..color = isPlayerSide
                ? const Color(0x4431261a)
                : const Color(0x8b5e4e34),
        );
        canvas.drawOval(
          const Rect.fromLTWH(0, 40, 80, 16).deflate(isPlayerSide ? 4 : 5),
          Paint()
            ..color = isPlayerSide
                ? const Color(0x7a8e7b61)
                : const Color(0xffd8c59e),
        );
        canvas.drawImage(sprite, const Offset(30, 0), Paint());
      });
      expect(actual, orderedEquals(expected));
    });
  }
}

Future<Uint8List> _pixels(void Function(Canvas) render) async {
  final recorder = ui.PictureRecorder();
  render(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(80, 56);
  picture.dispose();
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
