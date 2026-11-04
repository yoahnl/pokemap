import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_mosaic.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_visual_asset_cache.dart';

Future<ui.Image> _sourceImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint();
  canvas.drawRect(const ui.Rect.fromLTWH(4, 1, 1, 4),
      paint..color = const ui.Color(0xffff0000));
  canvas.drawRect(const ui.Rect.fromLTWH(5, 1, 1, 4),
      paint..color = const ui.Color(0xff0000ff));
  canvas.drawRect(const ui.Rect.fromLTWH(8, 1, 1, 4),
      paint..color = const ui.Color(0xff00ff00));
  canvas.drawRect(const ui.Rect.fromLTWH(4, 5, 1, 4),
      paint..color = const ui.Color(0xffffff00));
  final picture = recorder.endRecording();
  final image = await picture.toImage(12, 10);
  picture.dispose();
  return image;
}

Future<Uint8List> _render(ui.Image source, int level, {int alpha = 255}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  drawBattleGen5Mosaic(
    canvas,
    source,
    const ui.Rect.fromLTWH(4, 1, 8, 8),
    const ui.Rect.fromLTWH(2, 3, 16, 8),
    ui.Paint()..color = ui.Color.fromARGB(alpha, 255, 255, 255),
    level,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(20, 14);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  picture.dispose();
  return data.buffer.asUint8List();
}

List<int> _pixel(Uint8List bytes, int x, int y) {
  final offset = (y * 20 + x) * 4;
  return bytes.sublist(offset, offset + 4);
}

Future<int> _bluePixels(BattleSceneCombatantComponent actor) async {
  final recorder = ui.PictureRecorder();
  actor.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(100, 100);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
      .buffer.asUint8List();
  var count = 0;
  for (var index = 0; index < bytes.length; index += 4) {
    if (bytes[index] < 30 && bytes[index + 2] > 200 && bytes[index + 3] > 200) {
      count++;
    }
  }
  image.dispose();
  picture.dispose();
  return count;
}

void main() {
  test('the actor restores only the mosaic owned by the active effect', () {
    final actor = BattleSceneCombatantComponent(
      sceneSpriteRect: const ui.Rect.fromLTWH(0, 0, 80, 80),
      scenePlatformRect: const ui.Rect.fromLTWH(0, 70, 80, 10),
      sceneFootAnchor: const ui.Offset(40, 75),
      spriteFootXRatio: .5,
      isPlayerSide: true,
      speciesLabel: 'test',
    );
    final first = Object();
    final second = Object();
    actor.setBattleScriptMosaic(8, owner: first);
    expect(actor.debugBattleScriptMosaicLevel, 8);
    expect(() => actor.setBattleScriptMosaic(2, owner: second), throwsStateError);
    actor.clearBattleScriptMosaic(owner: second);
    expect(actor.debugBattleScriptMosaicLevel, 8);
    actor.clearBattleScriptMosaic(owner: first);
    expect(actor.debugBattleScriptMosaicLevel, 0);
  });

  testWidgets('mosaic samples a cropped sprite in blocks and preserves transparency',
      (tester) async {
    await tester.runAsync(() async {
      final source = await _sourceImage();
      addTearDown(source.dispose);
      final pixels = await _render(source, 3);
      expect(_pixel(pixels, 3, 4), [255, 0, 0, 255]);
      expect(_pixel(pixels, 8, 4), [255, 0, 0, 255]);
      expect(_pixel(pixels, 12, 4), [0, 255, 0, 255]);
      expect(_pixel(pixels, 3, 8), [255, 255, 0, 255]);
      expect(_pixel(pixels, 12, 8), [0, 0, 0, 0]);
      expect(_pixel(pixels, 1, 4), [0, 0, 0, 0]);
      expect(_pixel(pixels, 18, 4), [0, 0, 0, 0]);
    });
  });

  testWidgets('level zero retains the original pixels and paint opacity',
      (tester) async {
    await tester.runAsync(() async {
      final source = await _sourceImage();
      addTearDown(source.dispose);
      final pixels = await _render(source, 0, alpha: 128);
      expect(_pixel(pixels, 3, 4)[3], 128);
      expect(_pixel(pixels, 5, 4)[2], greaterThan(0));
      expect(_pixel(pixels, 7, 4)[3], 0);
    });
  });

  testWidgets('the battle actor actually renders mosaic and restores its sprite',
      (tester) async {
    await tester.runAsync(() async {
      final source = await _sourceImage();
      final cache = BattleVisualAssetCache(imageLoader: (_) async => source.clone());
      final actor = BattleSceneCombatantComponent(
        sceneSpriteRect: const ui.Rect.fromLTWH(0, 0, 80, 80),
        scenePlatformRect: const ui.Rect.fromLTWH(0, 70, 80, 10),
        sceneFootAnchor: const ui.Offset(40, 75),
        spriteFootXRatio: .5,
        isPlayerSide: true,
        speciesLabel: 'test',
        visualAssetCache: cache,
        initialSpriteSpec: const BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
          explicitImageAbsolutePath: '/fixture/mosaic.png',
        ),
      );
      addTearDown(() {
        actor.onRemove();
        cache.dispose();
        source.dispose();
      });
      await actor.onLoad();
      final owner = Object();
      final original = await _bluePixels(actor);
      actor.setBattleScriptMosaic(3, owner: owner);
      final pixelated = await _bluePixels(actor);
      actor.clearBattleScriptMosaic(owner: owner);
      final restored = await _bluePixels(actor);
      expect(original, greaterThan(0));
      expect(pixelated, 0);
      expect(restored, original);
    });
  });
}
