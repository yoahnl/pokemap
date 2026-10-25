import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_visual_asset_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('missing sprite keeps the procedural platform fallback', () async {
    final component = BattleSceneCombatantComponent(
      sceneSpriteRect: const Rect.fromLTWH(30, 0, 20, 20),
      scenePlatformRect: const Rect.fromLTWH(0, 40, 80, 16),
      sceneFootAnchor: const Offset(40, 20),
      spriteFootXRatio: .5,
      isPlayerSide: false,
      speciesLabel: 'fixture',
    );
    final pixels = await _pixels(component.renderTree);
    final center = (48 * 80 + 40) * 4;
    expect(pixels.sublist(center, center + 4), [0xD8, 0xC5, 0x9E, 0xFF]);
  });

  for (final isPlayerSide in [true, false]) {
    test(
      'asset combatant $isPlayerSide has only a discreet shadow and no platform or aura',
      () async {
        final spriteRecorder = ui.PictureRecorder();
        Canvas(spriteRecorder)
          ..drawRect(
            const Rect.fromLTWH(0, 0, 20, 10),
            Paint()..color = const Color(0xffff0000),
          )
          ..drawRect(
            const Rect.fromLTWH(0, 10, 20, 10),
            Paint()..color = const Color(0xff0000ff),
          );
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
        expect(
          component.currentRenderedSpriteRect,
          const Rect.fromLTWH(30, 0, 20, 20),
        );
        expect(
          component.currentPlatformRect,
          const Rect.fromLTWH(0, 40, 80, 16),
        );
        final actual = await _pixels(component.renderTree);
        for (var y = 32; y < 56; y++) {
          for (var x = 0; x < 80; x++) {
            expect(
              actual[((y * 80) + x) * 4 + 3],
              0,
              reason: 'No generated platform at ($x, $y)',
            );
          }
        }
        final expected = await _pixels((canvas) {
          canvas.drawOval(
            Rect.fromCenter(center: const Offset(40, 22), width: 11, height: 2),
            Paint()
              ..color = const Color(0x26000000)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
          );
          canvas.drawImage(sprite, const Offset(30, 0), Paint());
        });
        expect(actual, orderedEquals(expected));
      },
    );
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
