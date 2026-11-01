import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_visual_asset_cache.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_ground_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an unavailable current frame clears stale actor submission flags', () {
    final actor = _actor()..renderedBy3DStage = true;
    final scene = _layout();
    final stage = BattleStage3DComponent(
      camera: BattlePerspectiveCamera(viewport: scene.stageRect),
      layout: () => scene,
      combatants: () => {_player: actor},
      platforms: () => const {},
      paintFloor: true,
    );
    final recorder = PictureRecorder();
    stage.render(Canvas(recorder));
    recorder.endRecording().dispose();
    expect(actor.renderedBy3DStage, isFalse);
  });

  test('software ground is decided after the current GPU frame attempt', () {
    final scene = _layout();
    final camera = BattlePerspectiveCamera(viewport: scene.stageRect);
    final stage = BattleStage3DComponent(
      camera: camera,
      layout: () => scene,
      combatants: () => const {},
      platforms: () => const {},
      paintFloor: true,
    );
    final ground = BattlePerspectiveGroundComponent(
      camera: camera,
      groundRects: () => const [],
    );
    expect(ground.priority, greaterThan(stage.priority));
  });
  testWidgets('loading preserves software actors and ground', (tester) async {
    final loading = Completer<BattleStageRenderer>();
    final fixture = await _mountFixture(tester, loading: loading.future);
    fixture.actors[_player]!.renderedBy3DStage = true;
    _render(fixture.stage.render);
    expect(fixture.stage.isReady, isFalse);
    expect(fixture.stage.currentFramePresented, isFalse);
    expect(fixture.actors[_player]!.renderedBy3DStage, isFalse);
    loading.complete(fixture.renderer);
    await fixture.stage.loaded;
    expect(fixture.stage.isReady, isTrue);
    expect(fixture.stage.currentFramePresented, isFalse);
  });

  testWidgets('passes animated atlas rectangles to the 3D stage', (
    tester,
  ) async {
    final fixture = await _mountFixture(tester);
    final actor = fixture.actors[_player]!;
    actor.onMount();
    final gif = await tester.runAsync(_writeGif);
    await tester.runAsync(
      () => actor.sync(
        speciesLabel: 'fixture',
        spriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
          explicitAnimatedImageAbsolutePath: gif,
        ),
      ),
    );
    _render(fixture.stage.render);
    final first = fixture.renderer.lastBillboards.firstWhere(
      (billboard) => billboard.id == _player,
    );
    actor.update(.1);
    _render(fixture.stage.render);
    final second = fixture.renderer.lastBillboards.firstWhere(
      (billboard) => billboard.id == _player,
    );
    expect(fixture.stage.currentFramePresented, isTrue);
    expect(identical(first.image, second.image), isTrue);
    expect(first.source, isNot(second.source));
  });

  testWidgets('keeps the whole scene in 2D when an atlas cannot fit', (
    tester,
  ) async {
    final fixture = await _mountFixture(tester);
    final gif = await tester.runAsync(_writeGif);
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(
        maximumResidentBytes: 64,
        maximumTransientBytes: 65536,
        maximumEncodedBytes: 65536,
        maximumConcurrentDecodes: 1,
      ),
    );
    final scene = _layout();
    final actor = BattleSceneCombatantComponent(
      sceneSpriteRect: scene.playerSpriteRect,
      scenePlatformRect: scene.playerPlatformRect,
      sceneFootAnchor: scene.playerFootAnchor,
      spriteFootXRatio: .5,
      isPlayerSide: true,
      speciesLabel: 'fixture',
      resourceBudget: budget,
    );
    addTearDown(actor.onRemove);
    actor.onMount();
    await tester.runAsync(
      () => actor.sync(
        speciesLabel: 'fixture',
        spriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
          explicitAnimatedImageAbsolutePath: gif,
        ),
      ),
    );
    fixture.actors[_player] = actor;
    _render(fixture.stage.render);
    expect(actor.stageImage, isNull);
    expect(fixture.stage.currentFramePresented, isFalse);
    expect(
      fixture.actors.values.every((entry) => !entry.renderedBy3DStage),
      isTrue,
    );
    actor.update(.1);
    final rendered = await tester.runAsync(() => _pixels(actor.renderTree));
    expect(_coloredPixels(rendered!), greaterThan(0));
  });

  testWidgets(
    'partial texture submission discards GPU paint and keeps all actors on Canvas',
    (tester) async {
      final fixture = await _mountFixture(tester, sprites: true);
      fixture.renderer.result = BattleStageFrameResult(
        presented: true,
        submittedActorIds: {_player},
      );
      final rejected = await tester.runAsync(
        () => _pixels(fixture.stage.render),
      );
      expect(rejected!.every((value) => value == 0), isTrue);
      expect(fixture.renderer.lastBillboards.map((entry) => entry.id), {
        _player,
        _enemy,
      });
      expect(fixture.stage.currentFramePresented, isFalse);
      expect(fixture.actors[_player]!.renderedBy3DStage, isFalse);
      expect(fixture.actors[_enemy]!.renderedBy3DStage, isFalse);
      final gpuActor = await tester.runAsync(
        () => _pixels(fixture.actors[_player]!.renderTree),
      );
      final softwareActor = await tester.runAsync(
        () => _pixels(fixture.actors[_enemy]!.renderTree),
      );
      expect(_coloredPixels(gpuActor!), greaterThan(0));
      expect(_coloredPixels(softwareActor!), greaterThan(0));
    },
  );

  testWidgets('complete GPU frame owns each actor, shadow and dash trails', (
    tester,
  ) async {
    final fixture = await _mountFixture(tester, sprites: true);
    fixture.renderer.result = BattleStageFrameResult(
      presented: true,
      submittedActorIds: fixture.actors.keys.toSet(),
    );
    for (final actor in fixture.actors.values) {
      await actor.playFastDash(
        towardOpponent: true,
        distancePx: 40,
        durationSeconds: .4,
      );
      actor.update(.1);
    }
    _render(fixture.stage.render);
    expect(fixture.stage.currentFramePresented, isTrue);
    for (final frame in fixture.renderer.lastBillboards) {
      expect(frame.shadow, isNotNull);
      expect(frame.trails, hasLength(2));
      expect(frame.trails.first.tint.a, closeTo(.195, .00001));
      expect(frame.trails.last.tint.a, closeTo(.195 * .58, .00001));
      final actor = fixture.actors[frame.id]!;
      expect(actor.renderedBy3DStage, isTrue);
      final software = await tester.runAsync(() => _pixels(actor.renderTree));
      expect(software!.every((value) => value == 0), isTrue);
    }
  });

  testWidgets(
    'a ground-only presentation suppresses duplicate software ground',
    (tester) async {
      final fixture = await _mountFixture(tester);
      fixture.actors.clear();
      _render(fixture.stage.render);
      expect(fixture.stage.currentFramePresented, isTrue);
      expect(
        fixture.actors.values.every((actor) => !actor.renderedBy3DStage),
        isTrue,
      );
      final pixels = await tester.runAsync(
        () => _pixels(fixture.ground.render),
      );
      expect(pixels!.every((value) => value == 0), isTrue);
    },
  );

  testWidgets('an unresolved actor prevents a mixed GPU and CPU frame', (
    tester,
  ) async {
    final fixture = await _mountFixture(tester, sprites: false);
    final rejected = await tester.runAsync(() => _pixels(fixture.stage.render));
    expect(rejected!.every((value) => value == 0), isTrue);
    expect(fixture.stage.currentFramePresented, isFalse);
    expect(
      fixture.actors.values.every((actor) => !actor.renderedBy3DStage),
      isTrue,
    );
  });

  testWidgets(
    'refusal after success restores actors and ground in the same frame',
    (tester) async {
      final fixture = await _mountFixture(tester);
      fixture.renderer.result = BattleStageFrameResult(
        presented: true,
        submittedActorIds: {_player, _enemy},
      );
      _render(fixture.stage.render);
      expect(fixture.actors[_player]!.renderedBy3DStage, isTrue);
      fixture.renderer.result = const BattleStageFrameResult(presented: false);
      final rejected = await tester.runAsync(
        () => _pixels(fixture.stage.render),
      );
      expect(rejected!.every((value) => value == 0), isTrue);
      expect(fixture.stage.currentFramePresented, isFalse);
      expect(fixture.actors[_player]!.renderedBy3DStage, isFalse);
      final fallback = await tester.runAsync(
        () => _pixels(fixture.ground.render),
      );
      expect(fallback!.any((value) => value != 0), isTrue);
    },
  );

  testWidgets(
    'throw after success discards partial GPU paint before fallback',
    (tester) async {
      final fixture = await _mountFixture(tester);
      fixture.renderer.result = BattleStageFrameResult(
        presented: true,
        submittedActorIds: {_player, _enemy},
      );
      _render(fixture.stage.render);
      fixture.renderer.failure = StateError(
        'GPU frame failed after partial paint',
      );
      final rejected = await tester.runAsync(
        () => _pixels(fixture.stage.render),
      );
      expect(rejected!.every((value) => value == 0), isTrue);
      expect(fixture.stage.currentFramePresented, isFalse);
      expect(fixture.actors[_player]!.renderedBy3DStage, isFalse);
      fixture.renderer.failure = null;
      _render(fixture.stage.render);
      expect(fixture.stage.currentFramePresented, isTrue);
      expect(fixture.actors[_player]!.renderedBy3DStage, isTrue);
    },
  );

  testWidgets('losing context after success restores every software actor', (
    tester,
  ) async {
    final fixture = await _mountFixture(tester);
    fixture.renderer.result = BattleStageFrameResult(
      presented: true,
      submittedActorIds: {_player, _enemy},
    );
    _render(fixture.stage.render);
    fixture.game.hostContext = null;
    _render(fixture.stage.render);
    expect(fixture.renderer.attempts, 1);
    expect(fixture.stage.currentFramePresented, isFalse);
    expect(
      fixture.actors.values.every((actor) => !actor.renderedBy3DStage),
      isTrue,
    );
  });

  testWidgets(
    'same-count geometry changes rebuild ground while stable frames reuse it',
    (tester) async {
      final fixture = await _mountFixture(tester);
      _render(fixture.stage.render);
      final first = fixture.renderer.lastGround;
      _render(fixture.stage.render);
      expect(identical(first, fixture.renderer.lastGround), isTrue);
      fixture.stage.camera.eye = const BattleCameraPoint(7, 7, 18);
      _render(fixture.stage.render);
      expect(identical(first, fixture.renderer.lastGround), isTrue);
      final old = fixture.geometry[_player]!;
      fixture.geometry[_player] = BattleCombatantSceneGeometry(
        spriteRect: old.spriteRect,
        platformRect: old.platformRect.inflate(12),
        footAnchor: old.footAnchor + const Offset(20, 0),
        hudRect: old.hudRect,
      );
      _render(fixture.stage.render);
      expect(identical(first, fixture.renderer.lastGround), isFalse);
      expect(
        fixture.renderer.lastGround[1].points.first.x,
        isNot(first[1].points.first.x),
      );
      final changed = fixture.renderer.lastGround;
      fixture.stage.camera.viewport = const Rect.fromLTWH(0, 0, 844, 390);
      _render(fixture.stage.render);
      expect(identical(changed, fixture.renderer.lastGround), isFalse);
    },
  );

  testWidgets('removal clears frame ownership and disposes the stage once', (
    tester,
  ) async {
    final fixture = await _mountFixture(tester);
    fixture.renderer.result = BattleStageFrameResult(
      presented: true,
      submittedActorIds: {_player, _enemy},
    );
    _render(fixture.stage.render);
    fixture.stage.onRemove();
    fixture.stage.onRemove();
    _render(fixture.stage.render);
    expect(fixture.renderer.disposals, 1);
    expect(fixture.stage.isReady, isFalse);
    expect(fixture.stage.currentFramePresented, isFalse);
    expect(fixture.actors[_player]!.renderedBy3DStage, isFalse);
  });

  testWidgets('removal while loading disposes a late stage exactly once', (
    tester,
  ) async {
    final loading = Completer<BattleStageRenderer>();
    final fixture = await _mountFixture(tester, loading: loading.future);
    fixture.stage.removeFromParent();
    loading.complete(fixture.renderer);
    await fixture.stage.loaded;
    expect(fixture.renderer.disposals, 1);
    expect(fixture.stage.isReady, isFalse);
    _render(fixture.stage.render);
    expect(fixture.renderer.attempts, 0);
    expect(fixture.stage.currentFramePresented, isFalse);
  });
}

const _player = BattleSlotRef.active(BattleSideId.player);

BattleSceneLayout _layout() =>
    BattleSceneLayout.forViewport(viewportSize: const Size(390, 844));

BattleSceneCombatantComponent _actor() => BattleSceneCombatantComponent(
  sceneSpriteRect: const Rect.fromLTWH(40, 30, 40, 40),
  scenePlatformRect: const Rect.fromLTWH(32, 66, 56, 12),
  sceneFootAnchor: const Offset(60, 70),
  spriteFootXRatio: .5,
  isPlayerSide: true,
  speciesLabel: 'fixture',
);

const _enemy = BattleSlotRef.active(BattleSideId.enemy);

Future<String> _writeGif() async {
  final root = Directory(
    Platform.environment['AVELUNE_QA_ROOT'] ?? Directory.systemTemp.path,
  );
  final directory = await root.createTemp('stage-gif-');
  addTearDown(() => directory.delete(recursive: true));
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

final class _Fixture {
  _Fixture(
    this.game,
    this.stage,
    this.ground,
    this.renderer,
    this.actors,
    this.geometry,
  );
  final _ContextGame game;
  final BattleStage3DComponent stage;
  final BattlePerspectiveGroundComponent ground;
  final _Renderer renderer;
  final Map<BattleSlotRef, BattleSceneCombatantComponent> actors;
  final Map<BattleSlotRef, BattleCombatantSceneGeometry> geometry;
}

Future<_Fixture> _mountFixture(
  WidgetTester tester, {
  Future<BattleStageRenderer>? loading,
  bool sprites = true,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Builder(
        builder: (value) {
          context = value;
          return const SizedBox();
        },
      ),
    ),
  );
  final game = _ContextGame(context);
  game.onGameResize(Vector2(390, 844));
  final scene = _layout();
  final camera = BattlePerspectiveCamera(viewport: scene.stageRect);
  final renderer = _Renderer();
  final actors = <BattleSlotRef, BattleSceneCombatantComponent>{
    _player: BattleSceneCombatantComponent(
      sceneSpriteRect: scene.playerSpriteRect,
      scenePlatformRect: scene.playerPlatformRect,
      sceneFootAnchor: scene.playerFootAnchor,
      spriteFootXRatio: .5,
      isPlayerSide: true,
      speciesLabel: 'fixture',
    ),
    _enemy: BattleSceneCombatantComponent(
      sceneSpriteRect: scene.enemySpriteRect,
      scenePlatformRect: scene.enemyPlatformRect,
      sceneFootAnchor: scene.enemyFootAnchor,
      spriteFootXRatio: .5,
      isPlayerSide: false,
      speciesLabel: 'fixture',
    ),
  };
  if (sprites) {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 8, 8),
      Paint()..color = const Color(0xff0000ff),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(8, 8);
    picture.dispose();
    final cache = BattleVisualAssetCache(
      imageLoader: (_) async => image.clone(),
    );
    addTearDown(() {
      cache.dispose();
      image.dispose();
    });
    for (final entry in actors.entries.toList()) {
      final old = entry.value;
      final actor = BattleSceneCombatantComponent(
        sceneSpriteRect: entry.key == _player
            ? scene.playerSpriteRect
            : scene.enemySpriteRect,
        scenePlatformRect: entry.key == _player
            ? scene.playerPlatformRect
            : scene.enemyPlatformRect,
        sceneFootAnchor: entry.key == _player
            ? scene.playerFootAnchor
            : scene.enemyFootAnchor,
        spriteFootXRatio: .5,
        isPlayerSide: old.isPlayerSide,
        speciesLabel: 'fixture',
        visualAssetCache: cache,
      );
      actors[entry.key] = actor;
      await tester.runAsync(
        () => actor.sync(
          speciesLabel: 'fixture',
          spriteSpec: const BattleCombatantSpriteSpec(
            facing: BattleCombatantSpriteFacing.front,
            explicitImageAbsolutePath: '/fixture/fallback.png',
          ),
        ),
      );
      addTearDown(actor.onRemove);
    }
  }
  renderer.result = BattleStageFrameResult(
    presented: true,
    submittedActorIds: actors.keys.toSet(),
  );
  final geometry = {
    _player: BattleCombatantSceneGeometry(
      spriteRect: scene.playerSpriteRect,
      platformRect: scene.playerPlatformRect,
      footAnchor: scene.playerFootAnchor,
      hudRect: Rect.zero,
    ),
    _enemy: BattleCombatantSceneGeometry(
      spriteRect: scene.enemySpriteRect,
      platformRect: scene.enemyPlatformRect,
      footAnchor: scene.enemyFootAnchor,
      hudRect: Rect.zero,
    ),
  };
  final stage = BattleStage3DComponent(
    camera: camera,
    layout: () => scene,
    combatants: () => actors,
    platforms: () => geometry,
    paintFloor: true,
    stageFactory: (_) => loading ?? Future.value(renderer),
  );
  final ground = BattlePerspectiveGroundComponent(
    camera: camera,
    groundRects: () => [scene.playerPlatformRect, scene.enemyPlatformRect],
    isVisible: () => !stage.currentFramePresented,
  );
  game.add(stage);
  if (loading == null) await stage.loaded;
  addTearDown(stage.onRemove);
  return _Fixture(game, stage, ground, renderer, actors, geometry);
}

final class _Renderer implements BattleStageRenderer {
  BattleStageFrameResult result = const BattleStageFrameResult(presented: true);
  Object? failure;
  int attempts = 0;
  int disposals = 0;
  List<BattleStageBillboard> lastBillboards = const [];
  List<BattleStageGround> lastGround = const [];

  @override
  BattleStageFrameResult render({
    required Canvas canvas,
    required BuildContext context,
    required Rect viewport,
    required Rect clip,
    required Model3dVector3 eye,
    required Model3dVector3 aim,
    required double focal,
    required Offset projectionCenter,
    required List<BattleStageBillboard> billboards,
    required List<BattleStageGround> ground,
  }) {
    expect(MediaQuery.devicePixelRatioOf(context), 1);
    attempts++;
    lastBillboards = billboards;
    lastGround = ground;
    canvas.drawRect(viewport, Paint()..color = const Color(0xffff0000));
    if (failure case final error?) throw error;
    return result;
  }

  @override
  void dispose() => disposals++;
}

void _render(void Function(Canvas) render) {
  final recorder = PictureRecorder();
  render(Canvas(recorder));
  recorder.endRecording().dispose();
}

Future<Uint8List> _pixels(void Function(Canvas) render) async {
  final recorder = PictureRecorder();
  render(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(390, 844);
  picture.dispose();
  try {
    final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

int _coloredPixels(Uint8List pixels) {
  var count = 0;
  for (var i = 0; i < pixels.length; i += 4) {
    if (pixels[i + 3] > 0 && pixels[i + 2] > pixels[i]) count++;
  }
  return count;
}

final class _ContextGame extends FlameGame {
  _ContextGame(this.hostContext);

  BuildContext? hostContext;

  @override
  BuildContext? get buildContext => hostContext;
}
