import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('frames the visible pose without cropping the animation canvas', () {
    const visible = ui.Rect.fromLTWH(100, 200, 104, 120);
    const reference = ui.Rect.fromLTRB(38, 20, 90, 80);
    final canvas = gen5SpriteCanvasRectForReference(
      visible,
      reference,
      const ui.Size(128, 128),
    );

    expect(canvas, const ui.Rect.fromLTWH(24, 160, 256, 256));
    expect(canvas.left + reference.left * 2, visible.left);
    expect(canvas.top + reference.bottom * 2, visible.bottom);
    expect(canvas.right, greaterThan(visible.right));
    expect(canvas.bottom, greaterThan(visible.bottom));
  });

  test('tries the native source before falling back to the GIF', () async {
    final directory = await Directory.systemTemp.createTemp('gen5-fallback-');
    addTearDown(() => directory.delete(recursive: true));
    final staticFile = File('${directory.path}/front.png');
    await staticFile.writeAsBytes(image.encodePng(image.Image(width: 2, height: 2)));
    final animatedFile = File('${directory.path}/front.gif');
    final encoder = image.GifEncoder();
    encoder.addFrame(image.Image(width: 2, height: 2), duration: 10);
    encoder.addFrame(image.Image(width: 2, height: 2), duration: 10);
    await animatedFile.writeAsBytes(encoder.finish()!);
    var nativeAttempts = 0;
    final spec = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitImageAbsolutePath: staticFile.path,
      explicitAnimatedImageAbsolutePath: animatedFile.path,
      gen5Source: BattleGen5SpriteSource(
        speciesId: 'testmon', shiny: false,
        loader: (_) async { nativeAttempts++; return null; },
      ),
    );
    final component = BattleSceneCombatantComponent(
      sceneSpriteRect: const ui.Rect.fromLTWH(0, 0, 100, 100),
      scenePlatformRect: const ui.Rect.fromLTWH(0, 90, 100, 10),
      sceneFootAnchor: const ui.Offset(50, 100),
      spriteFootXRatio: 0.5,
      isPlayerSide: false,
      speciesLabel: 'Testmon',
      initialSpriteSpec: spec,
    );
    await component.onLoad();
    component.onMount();
    await component.sync(speciesLabel: 'Testmon', spriteSpec: spec);
    expect(nativeAttempts, 1);
    expect(component.currentSpriteSourcePath, animatedFile.path);
    component.onRemove();
  });

  test('uses the static image when the native source and GIF fail', () async {
    final directory = await Directory.systemTemp.createTemp('gen5-static-');
    addTearDown(() => directory.delete(recursive: true));
    final staticFile = File('${directory.path}/front.png');
    await staticFile.writeAsBytes(image.encodePng(image.Image(width: 2, height: 2)));
    final brokenGif = File('${directory.path}/front.gif');
    await brokenGif.writeAsBytes([0, 1, 2]);
    final spec = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitImageAbsolutePath: staticFile.path,
      explicitAnimatedImageAbsolutePath: brokenGif.path,
      gen5Source: BattleGen5SpriteSource(
        speciesId: 'testmon', shiny: false,
        loader: (_) async => throw const FormatException('Invalid source'),
      ),
    );
    final component = BattleSceneCombatantComponent(
      sceneSpriteRect: const ui.Rect.fromLTWH(0, 0, 100, 100),
      scenePlatformRect: const ui.Rect.fromLTWH(0, 90, 100, 10),
      sceneFootAnchor: const ui.Offset(50, 100),
      spriteFootXRatio: 0.5,
      isPlayerSide: false,
      speciesLabel: 'Testmon',
      initialSpriteSpec: spec,
    );
    await component.onLoad();
    component.onMount();
    await component.sync(speciesLabel: 'Testmon', spriteSpec: spec);
    expect(component.currentSpriteSourcePath, staticFile.path);
    expect(component.hasResolvedExplicitSprite, isTrue);
    component.onRemove();
  });
}
