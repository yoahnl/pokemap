import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_visual_asset_cache.dart';

Future<Directory> _directory() async {
  final root = Directory(
    Platform.environment['AVELUNE_QA_ROOT'] ?? Directory.systemTemp.path,
  );
  final directory = await root.createTemp('battle-gif-');
  addTearDown(() => directory.delete(recursive: true));
  return directory;
}

Future<String> _writeGif(Directory directory) async {
  final red = img.Image(width: 2, height: 2);
  final blue = img.Image(width: 2, height: 2);
  img.fill(red, color: img.ColorRgb8(255, 0, 0));
  img.fill(blue, color: img.ColorRgb8(0, 0, 255));
  final encoder = img.GifEncoder(
    repeat: 0,
    dither: img.DitherKernel.none,
    quantizerType: img.QuantizerType.octree,
  );
  encoder.addFrame(red, duration: 10);
  encoder.addFrame(blue, duration: 20);
  final file = File('${directory.path}/animated.gif');
  await file.writeAsBytes(encoder.finish()!);
  return file.path;
}

RuntimeResourceBudget _budget(int resident) => RuntimeResourceBudget(
  profile: RuntimeResourceProfile(
    maximumResidentBytes: resident,
    maximumTransientBytes: 65536,
    maximumEncodedBytes: 65536,
    maximumConcurrentDecodes: 1,
  ),
);

BattleSceneCombatantComponent _component({
  required RuntimeResourceBudget budget,
  required BattleCombatantSpriteSpec sprite,
  BattleVisualAssetCache? cache,
}) => BattleSceneCombatantComponent(
  sceneSpriteRect: const ui.Rect.fromLTWH(0, 0, 40, 40),
  scenePlatformRect: const ui.Rect.fromLTWH(0, 40, 40, 10),
  sceneFootAnchor: const ui.Offset(20, 40),
  spriteFootXRatio: 0.5,
  isPlayerSide: false,
  speciesLabel: 'test',
  resourceBudget: budget,
  visualAssetCache: cache,
  initialSpriteSpec: sprite,
);

Future<void> _loadMounted(
  BattleSceneCombatantComponent component,
  BattleCombatantSpriteSpec sprite,
) async {
  await component.onLoad();
  component.onMount();
  await component.sync(speciesLabel: 'test', spriteSpec: sprite);
}

Future<List<int>> _pixel(ui.Image image, int x, int y) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return bytes!.buffer.asUint8List().sublist(offset, offset + 4);
}

Future<List<int>> _renderedPixel(
  BattleSceneCombatantComponent component,
) async {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(50, 60);
  try {
    return await _pixel(image, 20, 20);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('advances a stable GIF atlas and releases it on removal', () async {
    final directory = await _directory();
    final gif = await _writeGif(directory);
    final budget = _budget(1024);
    final sprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitAnimatedImageAbsolutePath: gif,
    );
    final component = _component(budget: budget, sprite: sprite);
    addTearDown(component.onRemove);
    await _loadMounted(component, sprite);
    final image = component.stageImage!;
    final first = component.stageSourceRect;
    expect(await _pixel(image, first.left.toInt(), first.top.toInt()), [
      255,
      0,
      0,
      255,
    ]);
    component.update(0.1);
    final second = component.stageSourceRect;
    expect(identical(component.stageImage, image), isTrue);
    expect(second, isNot(first));
    expect(await _pixel(image, second.left.toInt(), second.top.toInt()), [
      0,
      0,
      255,
      255,
    ]);
    await component.sync(speciesLabel: 'test', spriteSpec: sprite);
    expect(identical(component.stageImage, image), isTrue);
    expect(component.stageSourceRect, second);
    component.onRemove();
    expect(image.debugDisposed, isTrue);
    expect(budget.residentBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('plays in 2D without presenting per-frame images to 3D', () async {
    final directory = await _directory();
    final gif = await _writeGif(directory);
    final budget = _budget(64);
    final sprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitAnimatedImageAbsolutePath: gif,
    );
    final component = _component(budget: budget, sprite: sprite);
    addTearDown(component.onRemove);
    await _loadMounted(component, sprite);
    expect(component.stageImage, isNull);
    expect(await _renderedPixel(component), [255, 0, 0, 255]);
    component.update(0.1);
    expect(component.stageImage, isNull);
    expect(await _renderedPixel(component), [0, 0, 255, 255]);
    component.onRemove();
    expect(budget.residentBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('falls back to the static sprite when the GIF is invalid', () async {
    final directory = await _directory();
    final gif = File('${directory.path}/invalid.gif');
    await gif.writeAsBytes([1, 2, 3]);
    final green = img.Image(width: 2, height: 2);
    img.fill(green, color: img.ColorRgb8(0, 255, 0));
    final png = File('${directory.path}/static.png');
    await png.writeAsBytes(img.encodePng(green));
    final budget = _budget(1024);
    final cache = BattleVisualAssetCache(resourceBudget: budget);
    final sprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitImageAbsolutePath: png.path,
      explicitAnimatedImageAbsolutePath: gif.path,
    );
    final component = _component(budget: budget, cache: cache, sprite: sprite);
    addTearDown(() {
      component.onRemove();
      cache.dispose();
    });
    await _loadMounted(component, sprite);
    expect(component.currentSpriteSourcePath, png.path);
    expect(await _pixel(component.stageImage!, 0, 0), [0, 255, 0, 255]);
    expect(component.didExplicitSpriteLoadFail, isFalse);
  });

  test('cancels an in-flight GIF when the component is removed', () async {
    final directory = await _directory();
    final gif = await _writeGif(directory);
    final budget = _budget(1024);
    final component = _component(
      budget: budget,
      sprite: const BattleCombatantSpriteSpec(
        facing: BattleCombatantSpriteFacing.front,
      ),
    );
    await component.onLoad();
    component.onMount();
    final pending = component.sync(
      speciesLabel: 'test',
      spriteSpec: BattleCombatantSpriteSpec(
        facing: BattleCombatantSpriteFacing.front,
        explicitAnimatedImageAbsolutePath: gif,
      ),
    );
    component.onRemove();
    await pending;
    expect(component.stageImage, isNull);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('retries a static sprite that becomes available later', () async {
    final directory = await _directory();
    final png = File('${directory.path}/static.png');
    final budget = _budget(1024);
    final cache = BattleVisualAssetCache(resourceBudget: budget);
    final sprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitImageAbsolutePath: png.path,
    );
    final component = _component(budget: budget, cache: cache, sprite: sprite);
    addTearDown(() {
      component.onRemove();
      cache.dispose();
    });
    await component.onLoad();
    expect(component.didExplicitSpriteLoadFail, isTrue);
    final green = img.Image(width: 2, height: 2);
    img.fill(green, color: img.ColorRgb8(0, 255, 0));
    await png.writeAsBytes(img.encodePng(green));
    await component.sync(speciesLabel: 'test', spriteSpec: sprite);
    expect(component.didExplicitSpriteLoadFail, isFalse);
    expect(await _pixel(component.stageImage!, 0, 0), [0, 255, 0, 255]);
  });

  test('reloads an animated sprite after removal and remount', () async {
    final directory = await _directory();
    final gif = await _writeGif(directory);
    final sprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitAnimatedImageAbsolutePath: gif,
    );
    final component = BattleSceneCombatantComponent(
      sceneSpriteRect: const ui.Rect.fromLTWH(0, 0, 40, 40),
      scenePlatformRect: const ui.Rect.fromLTWH(0, 40, 40, 10),
      sceneFootAnchor: const ui.Offset(20, 40),
      spriteFootXRatio: 0.5,
      isPlayerSide: false,
      speciesLabel: 'test',
      initialSpriteSpec: sprite,
    );
    addTearDown(component.onRemove);
    await _loadMounted(component, sprite);
    final firstImage = component.stageImage!;
    component.onRemove();
    expect(firstImage.debugDisposed, isTrue);
    component.onMount();
    await component.sync(speciesLabel: 'test', spriteSpec: sprite);
    final secondImage = component.stageImage!;
    expect(identical(secondImage, firstImage), isFalse);
    expect(secondImage.debugDisposed, isFalse);
  });

  test('does not install a GIF superseded during loading', () async {
    final directory = await _directory();
    final gif = await _writeGif(directory);
    final budget = _budget(1024);
    const emptySprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
    );
    final component = _component(budget: budget, sprite: emptySprite);
    addTearDown(component.onRemove);
    await component.onLoad();
    component.onMount();
    final pending = component.sync(
      speciesLabel: 'animated',
      spriteSpec: BattleCombatantSpriteSpec(
        facing: BattleCombatantSpriteFacing.front,
        explicitAnimatedImageAbsolutePath: gif,
      ),
    );
    await component.sync(speciesLabel: 'replacement', spriteSpec: emptySprite);
    await pending;
    expect(component.stageImage, isNull);
    expect(component.currentSpeciesLabel, 'replacement');
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test(
    'updates fallback labels when the same empty sprite is reused',
    () async {
      final budget = _budget(1024);
      const sprite = BattleCombatantSpriteSpec(
        facing: BattleCombatantSpriteFacing.front,
      );
      final component = _component(budget: budget, sprite: sprite);
      addTearDown(component.onRemove);
      await component.onLoad();
      await component.sync(speciesLabel: 'replacement', spriteSpec: sprite);
      final labels = component.children.whereType<TextComponent>().map(
        (text) => text.text,
      );
      expect(labels, contains('replacement'));
      expect(labels, contains('R'));
    },
  );

  test('releases an owned static image when a GIF replaces it', () async {
    final directory = await _directory();
    final gif = await _writeGif(directory);
    final green = img.Image(width: 2, height: 2);
    img.fill(green, color: img.ColorRgb8(0, 255, 0));
    final png = File('${directory.path}/static.png');
    await png.writeAsBytes(img.encodePng(green));
    final budget = _budget(1024);
    final component = _component(
      budget: budget,
      sprite: BattleCombatantSpriteSpec(
        facing: BattleCombatantSpriteFacing.front,
        explicitImageAbsolutePath: png.path,
      ),
    );
    addTearDown(component.onRemove);
    await component.onLoad();
    component.onMount();
    final staticImage = component.stageImage!;
    await component.sync(
      speciesLabel: 'test',
      spriteSpec: BattleCombatantSpriteSpec(
        facing: BattleCombatantSpriteFacing.front,
        explicitImageAbsolutePath: png.path,
        explicitAnimatedImageAbsolutePath: gif,
      ),
    );
    expect(staticImage.debugDisposed, isTrue);
    expect(component.stageImage, isNotNull);
  });

  test('defers GIF resources until an attached component mounts', () async {
    final directory = await _directory();
    final gif = await _writeGif(directory);
    final budget = _budget(1024);
    final sprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitAnimatedImageAbsolutePath: gif,
    );
    final component = _component(budget: budget, sprite: sprite);
    final parent = Component()..add(component);
    await component.onLoad();
    expect(component.stageImage, isNull);
    expect(budget.residentBytes, 0);
    component.onMount();
    await component.sync(speciesLabel: 'test', spriteSpec: sprite);
    expect(component.stageImage, isNotNull);
    component.onRemove();
    parent.remove(component);
    expect(budget.residentBytes, 0);
  });

  test('does not decode a GIF for a component that never mounts', () async {
    final directory = await _directory();
    final gif = await _writeGif(directory);
    final budget = _budget(1024);
    final sprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitAnimatedImageAbsolutePath: gif,
    );
    final component = _component(budget: budget, sprite: sprite);
    await component.onLoad();
    await component.sync(speciesLabel: 'test', spriteSpec: sprite);
    expect(component.stageImage, isNull);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('dash trails sample the current GIF atlas frame', () async {
    final directory = await _directory();
    final gif = await _writeGif(directory);
    final budget = _budget(1024);
    final sprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitAnimatedImageAbsolutePath: gif,
    );
    final component = _component(budget: budget, sprite: sprite);
    addTearDown(component.onRemove);
    await _loadMounted(component, sprite);
    await component.playFastDash(
      towardOpponent: true,
      distancePx: 42,
      durationSeconds: 0.3,
    );
    component.update(0.1);
    final trail = component.currentCameraNeutralDashTrails.last.rect;
    final sample =
        ui.Offset(trail.left + 14, trail.center.dy) -
        ui.Offset(component.position.x, component.position.y) +
        const ui.Offset(40, 40);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..translate(40, 40);
    component.render(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(130, 130);
    try {
      final pixel = await _pixel(image, sample.dx.floor(), sample.dy.floor());
      expect(pixel[0], 0);
      expect(pixel[2], greaterThan(0));
    } finally {
      image.dispose();
      picture.dispose();
    }
  });

  testWidgets('loads and disposes a GIF through the Flame game lifecycle', (
    tester,
  ) async {
    final directory = await tester.runAsync(_directory);
    final gif = await tester.runAsync(() => _writeGif(directory!));
    final budget = _budget(1024);
    final sprite = BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
      explicitAnimatedImageAbsolutePath: gif,
    );
    final component = _component(budget: budget, sprite: sprite);
    final game = FlameGame();
    game.world.add(component);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 200, height: 200, child: GameWidget(game: game)),
      ),
    );
    for (var i = 0; i < 20 && !component.isMounted; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(component.isMounted, isTrue);
    for (var i = 0; i < 50 && component.stageImage == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    final image = component.stageImage!;
    game.world.remove(component);
    await tester.pump(const Duration(milliseconds: 16));
    expect(image.debugDisposed, isTrue);
    expect(budget.residentBytes, 0);
    expect(budget.activeDecodes, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
