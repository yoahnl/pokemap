import 'dart:ui' as ui;
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_sprite_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_sprite_sheet_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_particle_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_layer_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_bundle_cache.dart';
import 'package:map_runtime/src/presentation/flame/battle_rmxp_animation_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_ball_throw_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_ball_capture_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_ball_flash_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

import 'support/load_flame_component.dart';

Future<ui.Image> _image({int width = 12, int height = 12}) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawPaint(ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

void _expectRect(ui.Rect actual, ui.Rect expected) {
  expect((actual.topLeft - expected.topLeft).distance, lessThan(.001));
  expect((actual.bottomRight - expected.bottomRight).distance, lessThan(.001));
}

Future<BattleOverlayComponent> _overlay(BattleFxBundleCache cache) async {
  const pokemon = BattleCombatantData(speciesId: 'totodile', level: 7,
    maxHp: 25, currentHp: 25,
    stats: BattleStatsSnapshot(attack: 20, defense: 20, specialAttack: 20,
      specialDefense: 20, speed: 20),
    moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)]);
  const reserve = BattleCombatantData(speciesId: 'cyndaquil', lineupIndex: 1, level: 7,
    maxHp: 25, currentHp: 25,
    stats: BattleStatsSnapshot(attack: 20, defense: 20, specialAttack: 20,
      specialDefense: 20, speed: 20),
    moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)]);
  final overlay = BattleOverlayComponent(
    session: createBattleSession(BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: pokemon, enemyPokemon: pokemon,
      playerReservePokemon: [reserve],
      isTrainerBattle: false, trainerId: null)),
    viewportSize: Vector2(390, 844), onPlayerChoice: (_) {}, fxBundleCache: cache);
  await loadFlameComponent(overlay);
  await overlay.waitForPendingVisualSync();
  addTearDown(overlay.onRemove);
  return overlay;
}

PlayRmxpAnimationStep _rmxpStep(int animationId, RmxpPlacementPolicy policy) =>
  PlayRmxpAnimationStep(animationId: animationId, subjectSide: BattleSideId.player,
    attackerSide: BattleSideId.player, defenderSide: BattleSideId.enemy,
    phase: RmxpPlacementPhase.user, placementSpec: RmxpPlacementSpec(policy: policy));

BattleFxRuntimeContext _rmxpContext(Set<BattleSideId> missing) => BattleFxRuntimeContext(
  sceneSize: Vector2(320, 240),
  resolveAnchor: ({required anchor, required attackerSide, required defenderSide}) => Vector2(100, 100),
  bindSlotAnchor: ({required anchor, required attackerSlot, required defenderSlot}) => () {
    final side = switch (anchor) {
      BattleVisualAnchor.attackerBody || BattleVisualAnchor.attackerCenter ||
      BattleVisualAnchor.attackerMouth => attackerSlot.side,
      BattleVisualAnchor.defenderImpact || BattleVisualAnchor.defenderCenter => defenderSlot.side,
      _ => null,
    };
    return side != null && missing.contains(side) ? null : Vector2(100, 100);
  });

Future<bool> _rmxpHasPixels(BattleRmxpAnimationComponent fx) async {
  final recorder = ui.PictureRecorder();
  fx.render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(320, 240);
  picture.dispose();
  try {
    final bytes = (await image.toByteData())!.buffer.asUint8List();
    for (var index = 3; index < bytes.length; index += 4) {
      if (bytes[index] > 0) return true;
    }
    return false;
  } finally {
    image.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final policy in [RmxpPlacementPolicy.screenGlobal, RmxpPlacementPolicy.sdkStage]) {
    test('RMXP $policy does not require unrelated actor identities', () async {
      await BattleSdkRmxpAnimationCatalog.ensureLoaded();
      final animation = BattleSdkRmxpAnimationCatalog.byAnimationId.values.first;
      final cache = BattleFxBundleCache(imageLoader: (_) => _image(width: 960, height: 192));
      addTearDown(cache.dispose);
      final layer = BattleFxLayerComponent(size: Vector2(320, 240), fxBundleCache: cache);
      addTearDown(layer.onRemove);
      await layer.playRmxpAnimation(_rmxpStep(animation.id, policy),
        _rmxpContext({BattleSideId.player, BattleSideId.enemy}));
      expect(layer.activeRmxpFxCount, 1);
      expect(layer.children.whereType<BattleRmxpAnimationComponent>().single.refreshAttachment(), isTrue);
    });
  }

  for (final policy in [RmxpPlacementPolicy.subjectAttached, RmxpPlacementPolicy.attackerCast,
    RmxpPlacementPolicy.targetImpact]) {
    test('RMXP $policy only follows its placement actor', () async {
      await BattleSdkRmxpAnimationCatalog.ensureLoaded();
      final animation = BattleSdkRmxpAnimationCatalog.byAnimationId.values.first;
      final cache = BattleFxBundleCache(imageLoader: (_) => _image(width: 960, height: 192));
      addTearDown(cache.dispose);
      final layer = BattleFxLayerComponent(size: Vector2(320, 240), fxBundleCache: cache);
      addTearDown(layer.onRemove);
      final subject = policy == RmxpPlacementPolicy.targetImpact ? BattleSideId.enemy : BattleSideId.player;
      final missing = {subject == BattleSideId.player ? BattleSideId.enemy : BattleSideId.player};
      await layer.playRmxpAnimation(_rmxpStep(animation.id, policy), _rmxpContext(missing));
      expect(layer.activeRmxpFxCount, 1);
      final fx = layer.children.whereType<BattleRmxpAnimationComponent>().single;
      expect(fx.refreshAttachment(), isTrue);
      missing.add(subject);
      expect(fx.refreshAttachment(), isFalse);
    });
  }

  for (final missingSide in BattleSideId.values) {
    test('RMXP projectile cancels when $missingSide endpoint identity changes', () async {
      await BattleSdkRmxpAnimationCatalog.ensureLoaded();
      final animation = BattleSdkRmxpAnimationCatalog.byAnimationId.values.first;
      final cache = BattleFxBundleCache(imageLoader: (_) => _image(width: 960, height: 192));
      addTearDown(cache.dispose);
      final layer = BattleFxLayerComponent(size: Vector2(320, 240), fxBundleCache: cache);
      addTearDown(layer.onRemove);
      final missing = <BattleSideId>{};
      await layer.playRmxpAnimation(_rmxpStep(animation.id, RmxpPlacementPolicy.projectileLine), _rmxpContext(missing));
      final fx = layer.children.whereType<BattleRmxpAnimationComponent>().single;
      missing.add(missingSide);
      expect(fx.refreshAttachment(), isFalse);
    });
  }

  for (final callback in ['transform', 'flash', 'visibility']) {
    test('RMXP screen placement keeps the subject only for effective $callback callbacks', () async {
      await BattleSdkRmxpAnimationCatalog.ensureLoaded();
      final animation = BattleSdkRmxpAnimationCatalog.byAnimationId.values.firstWhere((animation) =>
        callback == 'transform' ? animation.frames.any((frame) => frame.cells.any((cell) => cell.index == 15)) :
        animation.timings.any((timing) => timing.flashScope == (callback == 'flash' ? 1 : 3)));
      final cache = BattleFxBundleCache(imageLoader: (_) => _image(width: 960, height: 192));
      addTearDown(cache.dispose);
      final layer = BattleFxLayerComponent(size: Vector2(320, 240), fxBundleCache: cache);
      addTearDown(layer.onRemove);
      final missing = <BattleSideId>{};
      await layer.playRmxpAnimation(_rmxpStep(animation.id, RmxpPlacementPolicy.screenGlobal), _rmxpContext(missing),
        onCombatantTransform: callback == 'transform' ? (_) {} : null,
        onPokemonFlash: callback == 'flash' ? (_) {} : null,
        onVisibilityChanged: callback == 'visibility' ? (_) {} : null);
      final fx = layer.children.whereType<BattleRmxpAnimationComponent>().single;
      missing.add(BattleSideId.enemy);
      expect(fx.refreshAttachment(), isTrue);
      missing.add(BattleSideId.player);
      expect(fx.refreshAttachment(), isFalse);
    });
  }

  test('RMXP callbacks without matching animation data do not require a subject', () async {
    await BattleSdkRmxpAnimationCatalog.ensureLoaded();
    final animation = BattleSdkRmxpAnimationCatalog.byAnimationId.values.firstWhere((animation) =>
      !animation.frames.any((frame) => frame.cells.any((cell) => cell.index == 15)) &&
      !animation.timings.any((timing) => timing.flashScope == 1 || timing.flashScope == 3));
    final cache = BattleFxBundleCache(imageLoader: (_) => _image(width: 960, height: 192));
    addTearDown(cache.dispose);
    final layer = BattleFxLayerComponent(size: Vector2(320, 240), fxBundleCache: cache);
    addTearDown(layer.onRemove);
    await layer.playRmxpAnimation(_rmxpStep(animation.id, RmxpPlacementPolicy.screenGlobal),
      _rmxpContext({BattleSideId.player, BattleSideId.enemy}),
      onCombatantTransform: (_) {}, onPokemonFlash: (_) {}, onVisibilityChanged: (_) {});
    expect(layer.activeRmxpFxCount, 1);
  });

  test('RMXP invalid attachment paints nothing immediately and legacy completion retains its final frame', () async {
    final image = await _image(width: 960, height: 192);
    addTearDown(image.dispose);
    const frame = RmxpAnimationFrameSpec(cellMax: 1, cells: [
      RmxpAnimationCellSpec(index: 0, pattern: 0, x: 0, y: 0, zoom: 100,
        angle: 0, mirror: false, opacity: 255, blendType: 0),
    ]);
    const animation = RmxpAnimationSpec(id: 999, name: 'QA', animationName: 'QA',
      assetId: 'anim001', animationHue: 0, position: 1, frameMax: 2,
      option: RmxpAnimationOption.normal, forceNoReverse: true,
      frames: [frame, frame], timings: []);
    final fx = BattleRmxpAnimationComponent(image: image, animation: animation,
      sourceAnchorPosition: Vector2(100, 100), sceneSize: Vector2(320, 240), reverse: false,
      resolvePlacement: () => null);
    expect(await _rmxpHasPixels(fx), isTrue);
    expect(fx.refreshAttachment(), isFalse);
    expect(await _rmxpHasPixels(fx), isFalse);
    final legacy = BattleRmxpAnimationComponent(image: image, animation: animation,
      sourceAnchorPosition: Vector2(100, 100), sceneSize: Vector2(320, 240), reverse: false);
    legacy.update(animation.durationSeconds);
    expect(legacy.isAnimationComplete, isTrue);
    expect(await _rmxpHasPixels(legacy), isTrue);
  });

  final families = <String, Future<void> Function(BattleFxLayerComponent, BattleFxRuntimeContext)>{
    'spritesheet': (layer, context) => layer.playSpriteSheetFx(const PlaySpriteSheetFxStep(
      assetId: 'fireball', attackerSide: BattleSideId.player, defenderSide: BattleSideId.enemy,
      anchor: BattleVisualAnchor.defenderBody, frameWidth: 6, frameHeight: 6,
      frameCount: 4, frameDurationSeconds: .1, columns: 2, originX: 3, originY: 3), context),
    'burst': (layer, context) => layer.playParticleBurst(const ParticleBurstStep(
      assetId: 'fireball', side: BattleSideId.enemy, anchor: BattleVisualAnchor.defenderBody,
      particleCount: 1, durationSeconds: .4), context),
    'SDK sequence': (layer, context) => layer.playSdkParticleSequence(const PlaySdkParticleSequenceStep(
      attackerSide: BattleSideId.player, defenderSide: BattleSideId.enemy, durationSeconds: .4,
      particles: [SdkParticleSpec(assetId: 'fireball', anchor: BattleVisualAnchor.defenderBody,
        startOffsetX: 10, startOffsetY: 20, endOffsetX: 30, endOffsetY: 40,
        startScaleX: .5, startScaleY: .5, endScaleX: 1, endScaleY: 1,
        startOpacity: 1, endOpacity: 0, delaySeconds: 0, durationSeconds: .4)]), context),
    'falling': (layer, context) => layer.playSdkFallingParticles(const SdkFallingParticlesStep(
      assetId: 'fireball', attackerSide: BattleSideId.player, defenderSide: BattleSideId.enemy,
      anchor: BattleVisualAnchor.defenderBody, particleCount: 1, durationSeconds: .4), context),
    'radial': (layer, context) => layer.playSdkRadiusParticles(const SdkRadiusParticleStep(
      assetId: 'fireball', attackerSide: BattleSideId.player, defenderSide: BattleSideId.enemy,
      anchor: BattleVisualAnchor.defenderBody, particleCount: 1,
      startRadiusPx: 5, endRadiusPx: 40, durationSeconds: .4), context),
    'scalar': (layer, context) => layer.playSdkScalarParticle(const SdkScalarParticleStep(
      assetId: 'fireball', attackerSide: BattleSideId.player, defenderSide: BattleSideId.enemy,
      anchor: BattleVisualAnchor.defenderBody, startScaleX: .5, startScaleY: .5,
      endScaleX: 1, endScaleY: 1, durationSeconds: .4), context),
    'zoom': (layer, context) => layer.playSdkParticleZoom(const SdkParticleZoomStep(
      assetId: 'fireball', attackerSide: BattleSideId.player, defenderSide: BattleSideId.enemy,
      anchor: BattleVisualAnchor.defenderBody, startScale: .5, endScale: 1, durationSeconds: .4), context),
  };
  for (final family in families.entries) {
    test('${family.key} reattaches after reflow without restarting its visual state', () async {
      final cache = BattleFxBundleCache(imageLoader: (_) => _image());
      addTearDown(cache.dispose);
      final layer = BattleFxLayerComponent(size: Vector2(320, 240), fxBundleCache: cache);
      var point = Vector2(100, 120);
      await family.value(layer, BattleFxRuntimeContext(sceneSize: Vector2(320, 240),
        resolveAnchor: ({required anchor, required attackerSide, required defenderSide}) =>
          Vector2(100, 120),
        bindSlotAnchor: ({required anchor, required attackerSlot, required defenderSlot}) => () => point));
      layer.updateTree(.1);
      final effect = layer.children.whereType<PositionComponent>().single;
      final before = effect.position.clone();
      final frame = effect is BattleFxSpriteSheetComponent ? effect.currentSourceFrameIndex : null;
      final opacity = switch (effect) {
        BattleFxSpriteComponent sprite => sprite.currentOpacityMultiplier,
        BattleSdkParticleComponent particle => particle.currentOpacity,
        _ => null,
      };
      point = Vector2(200, 170);
      layer.refreshAttachment();
      expect(effect.position.x - before.x, closeTo(100, .001));
      expect(effect.position.y - before.y, closeTo(50, .001));
      if (effect is BattleFxSpriteSheetComponent) expect(effect.currentSourceFrameIndex, frame);
      if (effect is BattleFxSpriteComponent) expect(effect.currentOpacityMultiplier, opacity);
      if (effect is BattleSdkParticleComponent) expect(effect.currentOpacity, opacity);
      layer.onRemove();
    });
  }

  test('an effect does not transfer to a replacement within the same plan', () async {
    final cache = BattleFxBundleCache(imageLoader: (_) => _image());
    addTearDown(cache.dispose);
    final overlay = await _overlay(cache);
    final choice = overlay.debugSession.decisionRequest.allowedChoices
        .whereType<PlayerBattleChoiceSwitch>().first;
    overlay.updateState(overlay.debugSession.applyChoice(choice));
    await overlay.waitForPendingVisualSync();
    expect(overlay.debugSession.state.player.speciesId, 'cyndaquil');
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.speciesLabel.toLowerCase(), contains('totodile'));
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      AnimationGroupStep(mode: BattleAnimationGroupMode.parallel, steps: [
        SpawnFxStep(effectId: 'fireball', attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy, from: BattleVisualAnchor.attackerBody,
          to: BattleVisualAnchor.attackerBody, durationSeconds: 1,
          playAsAccent: true, afterEffect: BattleFxAfterEffect.none),
        AnimationGroupStep(mode: BattleAnimationGroupMode.sequence, steps: [
          CombatantShakeStep(side: BattleSideId.enemy, amplitudePx: 1, durationSeconds: .2),
          SwapCombatantVisualStep(side: BattleSideId.player),
        ]),
      ]),
    ]));
    await Future<void>.delayed(Duration.zero);
    final layer = overlay.children.whereType<BattleFxLayerComponent>().single;
    expect(layer.activeFxCount, 1);
    overlay.updateTree(.3);
    await overlay.waitForPendingVisualSync();
    await Future<void>.delayed(Duration.zero);
    overlay.updateTree(0);
    expect(overlay.currentCommandOverlaySnapshot!.playerHud.speciesLabel.toLowerCase(), contains('cyndaquil'));
    expect(layer.activeFxCount, 0);
    expect(overlay.isTurnPresentationActive, isTrue);
  });

  test('overlay projectiles follow camera and immediate rotation at the same progress', () async {
    final cache = BattleFxBundleCache(imageLoader: (_) => _image());
    addTearDown(cache.dispose);
    final overlay = await _overlay(cache);
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      AnimationGroupStep(mode: BattleAnimationGroupMode.parallel, steps: [
        BattleCameraMoveStep(offsetX: 12, offsetY: 4, scale: 1.05,
          durationSeconds: .8, curve: BattleFxMotionCurve.linear),
        SpawnFxStep(effectId: 'fireball', attackerSide: BattleSideId.player,
          defenderSide: BattleSideId.enemy, from: BattleVisualAnchor.attackerCenter,
          to: BattleVisualAnchor.defenderCenter, durationSeconds: .8,
          playAsAccent: true, curve: BattleFxMotionCurve.linear,
          startScale: 1, endScale: 2, afterEffect: BattleFxAfterEffect.none),
      ]),
      WaitStep(durationSeconds: .1),
    ]));
    await Future<void>.delayed(Duration.zero);
    overlay.updateTree(.2);
    final layer = overlay.children.whereType<BattleFxLayerComponent>().single;
    final effect = layer.children.whereType<BattleFxSpriteComponent>().single;
    ui.Offset expected() => ui.Offset.lerp(
      overlay.debugPlayerCombatant!.currentRenderedSpriteRect.center,
      overlay.debugEnemyCombatant!.currentRenderedSpriteRect.center, .25)!;
    expect((effect.position.toOffset() - expected()).distance, lessThan(.001));
    expect(effect.currentScaleMultiplier, closeTo(1.25, .001));
    overlay.onGameResize(Vector2(844, 390));
    expect((effect.position.toOffset() - expected()).distance, lessThan(.001));
    expect(effect.currentScaleMultiplier, closeTo(1.25, .001));
    expect(layer.activeFxCount, 1);
    overlay.updateTree(.6);
    overlay.updateTree(0);
    expect(layer.activeFxCount, 0);
  });

  test('replacing an overlay plan invalidates its outstanding effect load', () async {
    final pending = Completer<ui.Image>();
    final cache = BattleFxBundleCache(imageLoader: (_) => pending.future);
    addTearDown(cache.dispose);
    final overlay = await _overlay(cache);
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      SpawnFxStep(effectId: 'fireball', attackerSide: BattleSideId.player,
        defenderSide: BattleSideId.enemy, from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.defenderCenter, durationSeconds: .4),
    ]));
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [WaitStep(durationSeconds: .4)]));
    pending.complete(await _image());
    await pending.future;
    await Future<void>.delayed(Duration.zero);
    final layer = overlay.children.whereType<BattleFxLayerComponent>().single;
    expect(layer.children.whereType<BattleFxSpriteComponent>(), isEmpty);
  });

  test('ball throw and flash reflow without reopening or resetting time', () async {
    final image = await _image();
    addTearDown(image.dispose);
    var target = Vector2(110, 100);
    var start = -30.0;
    var cellSize = 26.0;
    var alive = true;
    var opens = 0;
    final ball = BattleBallThrowComponent(sheet: image,
      kind: BattleBallSequenceKind.sendOutThrown,
      targetCenter: const ui.Offset(110, 100), throwStartX: start,
      onOpen: () => opens++, resolvePlacement: () => alive ?
        (targetCenter: target, throwStartX: start, cellSize: cellSize) : null);
    ball.update(.25);
    final before = ball.position.clone();
    target = Vector2(210, 150);
    start += 100;
    cellSize = 40;
    ball.refreshAttachment();
    expect(ball.position.x - before.x, closeTo(100, .001));
    expect(ball.position.y - before.y, closeTo(50, .001));
    expect(ball.cellSize, 40);
    expect(opens, 0);
    ball.update(.25);
    expect(opens, 1);
    ball.refreshAttachment();
    ball.update(0);
    expect(opens, 1);
    final flash = BattleBallFlashComponent(center: const ui.Offset(210, 150),
      radiusPx: 30, resolveCenter: () => alive ? target : null);
    flash.update(.1);
    final progress = flash.debugProgress;
    target = Vector2(250, 180);
    flash.refreshAttachment();
    expect(flash.position, target);
    expect(flash.debugProgress, progress);
    alive = false;
    expect(ball.refreshAttachment(), isFalse);
    expect(flash.refreshAttachment(), isFalse);
    ball.update(1);
    expect(opens, 1);
  });

  test('capture reflow preserves every cue and the locked ball attachment', () async {
    final image = await _image();
    addTearDown(image.dispose);
    var target = Vector2(100, 120);
    var alive = true;
    final cues = <BattleBallCaptureCue>[];
    final ball = BattleBallCaptureComponent(sheet: image, shakes: 1, caught: true,
      targetCenter: const ui.Offset(100, 120), throwStartX: -32,
      onCue: cues.add, resolvePlacement: () => alive ?
        (targetCenter: target, throwStartX: -32.0, cellSize: 26.0) : null);
    ball.update(.4);
    ball.update(.2);
    final before = ball.position.clone();
    target = Vector2(200, 170);
    ball.refreshAttachment();
    expect(ball.position.x - before.x, closeTo(100, .001));
    expect(ball.position.y - before.y, closeTo(50, .001));
    expect(cues.where((cue) => cue == BattleBallCaptureCue.absorb), hasLength(1));
    for (var frame = 0; frame < 60; frame++) {
      ball.refreshAttachment();
      ball.update(.1);
    }
    expect(cues.where((cue) => cue == BattleBallCaptureCue.absorb), hasLength(1));
    expect(cues.where((cue) => cue == BattleBallCaptureCue.close), hasLength(1));
    expect(cues.where((cue) => cue == BattleBallCaptureCue.bounce), hasLength(3));
    expect(cues.where((cue) => cue == BattleBallCaptureCue.shake), hasLength(1));
    expect(cues.where((cue) => cue == BattleBallCaptureCue.verdict), hasLength(1));
    expect(cues, isNot(contains(BattleBallCaptureCue.release)));
    final count = cues.length;
    alive = false;
    ball.update(1);
    expect(cues, hasLength(count));
  });

  test('RMXP attachment geometry excludes its own transform and respects visual ownership', () async {
    final actor = BattleSceneCombatantComponent(
      sceneSpriteRect: const ui.Rect.fromLTWH(30, 40, 120, 140),
      scenePlatformRect: const ui.Rect.fromLTWH(30, 170, 120, 20),
      sceneFootAnchor: const ui.Offset(90, 180), spriteFootXRatio: .5,
      isPlayerSide: true, speciesLabel: 'QA');
    actor.applyBattleCameraTransform(offset: Vector2(10, 20), scale: 1.2);
    final neutral = actor.currentEffectAttachmentSpriteRect;
    final foot = actor.currentEffectAttachmentFootAnchor;
    final oldOwner = Object();
    final newOwner = Object();
    actor.applyRmxpTransform(offset: const ui.Offset(20, -10), scale: 1.5, owner: oldOwner);
    expect(actor.currentRenderedSpriteRect, isNot(neutral));
    _expectRect(actor.currentEffectAttachmentSpriteRect, neutral);
    expect((actor.currentEffectAttachmentFootAnchor - foot).distance, lessThan(.001));
    actor.applyRmxpTransform(offset: const ui.Offset(40, -20), scale: 1.1, owner: newOwner);
    actor.setRmxpHidden(true, owner: newOwner);
    final transformed = actor.currentRenderedSpriteRect;
    actor.clearRmxpTransform(owner: oldOwner);
    actor.setRmxpHidden(false, owner: oldOwner);
    expect(actor.currentRenderedSpriteRect, transformed);
    expect(actor.currentVisualOpacity, 0);
    actor.clearRmxpTransform(owner: newOwner);
    actor.setRmxpHidden(false, owner: newOwner);
    _expectRect(actor.currentRenderedSpriteRect, neutral);
    expect(actor.currentVisualOpacity, 1);
    actor.applyRmxpTransform(offset: const ui.Offset(10, -10), scale: 1, owner: oldOwner);
    actor.setRmxpHidden(true, owner: oldOwner);
    await actor.playFaint(durationSeconds: .4);
    actor.update(.1);
    final faintOpacity = actor.currentVisualOpacity;
    final faintRect = actor.currentRenderedSpriteRect;
    actor.clearRmxpTransform(owner: oldOwner);
    actor.setRmxpHidden(false, owner: oldOwner);
    expect(actor.currentVisualOpacity, faintOpacity);
    expect(actor.currentRenderedSpriteRect, faintRect);
  });

  test('RMXP reflow retains source frame and never replays timing cues', () async {
    final image = await _image(width: 960, height: 192);
    addTearDown(image.dispose);
    final cues = <String?>[];
    var anchor = Vector2(30, 40);
    var alive = true;
    const frame = RmxpAnimationFrameSpec(cellMax: 1, cells: [
      RmxpAnimationCellSpec(index: 0, pattern: 0, x: 0, y: 0, zoom: 100,
        angle: 0, mirror: false, opacity: 255, blendType: 0),
    ]);
    final fx = BattleRmxpAnimationComponent(image: image,
      animation: const RmxpAnimationSpec(id: 999, name: 'QA', animationName: 'QA',
        assetId: 'anim001', animationHue: 0, position: 1, frameMax: 4,
        option: RmxpAnimationOption.normal, forceNoReverse: true,
        frames: [frame, frame, frame, frame], timings: [
          RmxpAnimationTimingSpec(frame: 0, condition: 0, flashScope: 0,
            flashDuration: 0, flashRed: 0, flashGreen: 0, flashBlue: 0, flashAlpha: 0,
            seName: 'cue_0', seVolume: 100, sePitch: 100),
          RmxpAnimationTimingSpec(frame: 1, condition: 0, flashScope: 0,
            flashDuration: 0, flashRed: 0, flashGreen: 0, flashBlue: 0, flashAlpha: 0,
            seName: 'cue_1', seVolume: 100, sePitch: 100),
        ]),
      sourceAnchorPosition: anchor, sceneSize: Vector2(320, 240), reverse: false,
      onSeTiming: (timing) => cues.add(timing.seName),
      resolvePlacement: () => alive ? (source: anchor, placement: anchor,
        attacker: anchor, defender: anchor, projectileSource: anchor,
        projectileTarget: anchor, stageRect: const ui.Rect.fromLTWH(0, 0, 640, 480),
        sceneSize: Vector2(640, 480)) : null);
    fx.update(.075);
    final frameIndex = fx.currentFrameIndex;
    final before = fx.visibleCellsForTesting.single.destinationRect.center;
    anchor = Vector2(130, 140);
    fx.update(0);
    final after = fx.visibleCellsForTesting.single.destinationRect.center;
    expect(after.dx - before.dx, closeTo(100, .001));
    expect(after.dy - before.dy, closeTo(100, .001));
    expect(fx.currentFrameIndex, frameIndex);
    expect(fx.sceneSize, Vector2(640, 480));
    expect(cues, ['cue_0', 'cue_1']);
    alive = false;
    fx.update(0);
    expect(fx.isAnimationComplete, isTrue);
    expect(cues, ['cue_0', 'cue_1']);
  });

  for (final failed in [false, true]) {
    test('clearing FX invalidates an outstanding ${failed ? 'failed' : 'successful'} load', () async {
      final pending = Completer<ui.Image>();
      final cache = BattleFxBundleCache(imageLoader: (_) => pending.future);
      addTearDown(cache.dispose);
      final layer = BattleFxLayerComponent(size: Vector2(320, 180), fxBundleCache: cache);
      await layer.onLoad();
      final loading = layer.playFx(const SpawnFxStep(effectId: 'fireball',
        attackerSide: BattleSideId.player, defenderSide: BattleSideId.enemy,
        from: BattleVisualAnchor.attackerCenter, to: BattleVisualAnchor.defenderCenter,
        durationSeconds: .4), BattleFxRuntimeContext(sceneSize: Vector2(320, 180),
          resolveAnchor: ({required anchor, required attackerSide, required defenderSide}) => Vector2(20, 30)));
      layer.clearAll();
      if (failed) {
        pending.completeError(StateError('obsolete load'));
      } else {
        pending.complete(await _image());
      }
      await loading;
      expect(layer.children.whereType<BattleFxSpriteComponent>(), isEmpty);
      if (!failed) {
        final image = await cache.loadImage('fireball');
        expect(await image.toByteData(), isNotNull);
      }
      layer.onRemove();
    });
  }

  test('sprite endpoints reflow without resetting progress or after effect', () async {
    final image = await _image();
    addTearDown(image.dispose);
    var start = Vector2(10, 20);
    Vector2? end = Vector2(110, 20);
    final fx = BattleFxSpriteComponent(sprite: Sprite(image),
      startPosition: start, endPosition: end,
      resolveStartPosition: () => start, resolveEndPosition: () => end,
      durationSeconds: .4, curve: BattleFxMotionCurve.linear,
      afterEffect: BattleFxAfterEffect.fade,
      startScale: 1, endScale: 2, startOpacity: 1, endOpacity: 1);
    fx.update(.2);
    start = Vector2(30, 40);
    end = Vector2(230, 80);
    fx.update(0);
    expect(fx.position.x, closeTo(130, .001));
    expect(fx.position.y, closeTo(60, .001));
    expect(fx.currentScaleMultiplier, 1.5);
    fx.update(.2);
    fx.update(.03);
    end = Vector2(280, 90);
    fx.update(0);
    expect(fx.position, end);
    expect(fx.currentOpacityMultiplier, closeTo(.75, .001));
    end = null;
    fx.update(0);
    expect(fx.isAnimationComplete, isTrue);
    expect(fx.currentOpacityMultiplier, 0);
  });

  test('SDK particle keeps delayed timeline and local offsets after reflow', () async {
    final image = await _image();
    addTearDown(image.dispose);
    var anchor = Vector2(10, 20);
    final fx = BattleSdkParticleComponent(sprite: Sprite(image),
      startPosition: anchor, endPosition: anchor + Vector2(40, 20),
      resolveStartPosition: () => anchor,
      resolveEndPosition: () => anchor + Vector2(40, 20),
      startScaleX: .5, startScaleY: .5, endScaleX: 1, endScaleY: 1,
      startOpacity: 1, endOpacity: 0, delaySeconds: .1,
      durationSeconds: .4, rotationTurns: .5);
    fx.update(.2);
    anchor = Vector2(50, 70);
    fx.update(0);
    expect(fx.position.x, closeTo(60, .001));
    expect(fx.position.y, closeTo(75, .001));
    expect(fx.currentOpacity, closeTo(.75, .001));
    expect(fx.currentScaleX, closeTo(.625, .001));
  });

  test('spritesheet reattaches while retaining its current source frame', () async {
    final image = await _image();
    addTearDown(image.dispose);
    Vector2? anchor = Vector2(20, 30);
    final fx = BattleFxSpriteSheetComponent(image: image,
      anchorPosition: anchor, resolveAnchorPosition: () => anchor,
      frameWidth: 6, frameHeight: 6, frameCount: 4,
      frameDurationSeconds: .1, columns: 2,
      originX: 3, originY: 3, displayScale: 2, opacity: 1);
    fx.update(.15);
    anchor = Vector2(100, 120);
    fx.update(0);
    expect(fx.position, Vector2(94, 114));
    expect(fx.currentSourceFrameIndex, 1);
    anchor = null;
    fx.update(0);
    expect(fx.isAnimationComplete, isTrue);
  });
}
