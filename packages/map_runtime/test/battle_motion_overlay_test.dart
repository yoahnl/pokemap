import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_motion_policy.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_layer_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_bundle_cache.dart';

import 'support/load_flame_component.dart';

Future<BattleOverlayComponent> _scene({BattleMotionPolicy? policy,
    double legacySpeed = 1}) async {
  const pokemon = BattleCombatantData(
    speciesId: 'totodile', level: 7, maxHp: 25, currentHp: 25,
    stats: BattleStatsSnapshot(attack: 20, defense: 20, specialAttack: 20,
      specialDefense: 20, speed: 20),
    moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)],
  );
  final overlay = BattleOverlayComponent(
    session: createBattleSession(BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: pokemon, enemyPokemon: pokemon,
      isTrainerBattle: false, trainerId: null)),
    viewportSize: Vector2(390, 844), onPlayerChoice: (_) {},
    motionScale: legacySpeed, motionPolicy: policy,
  );
  await loadFlameComponent(overlay);
  await overlay.waitForPendingVisualSync();
  addTearDown(overlay.onRemove);
  return overlay;
}

const _plan = BattleAnimationPlan(steps: [
  CameraFocusStep(target: BattleCameraFocusTarget.user,
    side: BattleSideId.player, durationSeconds: .4),
  WaitStep(durationSeconds: .6),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tone intensity changes colour without hiding the actor and updates live', () async {
    final overlay = await _scene(policy: BattleMotionPolicy(effectIntensity: 0));
    final actor = overlay.children.whereType<BattleSceneCombatantComponent>()
        .singleWhere((actor) => actor.isPlayerSide);
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      CombatantToneStep(side: BattleSideId.player,
        colorArgb: 0xFFFF0000, durationSeconds: .4),
    ]));
    expect(actor.stageTint, const ui.Color(0xFFFFFFFF));
    overlay.applyMotionPolicy(BattleMotionPolicy(effectIntensity: .35));
    expect(actor.stageTint.a, 1);
    expect(actor.stageTint.g, closeTo(.65, .01));
    overlay.applyMotionPolicy(BattleMotionPolicy(effectIntensity: 1));
    expect(actor.stageTint, const ui.Color(0xFFFF0000));
    overlay.applyMotionPolicy(BattleMotionPolicy(effectIntensity: 0));
    expect(actor.stageTint, const ui.Color(0xFFFFFFFF));
    overlay.updateTree(.4);
    expect(overlay.isTurnPresentationActive, isFalse);
  });

  test('zero effect intensity preserves semantic silhouettes and materialization', () async {
    final overlay = await _scene(policy: BattleMotionPolicy(effectIntensity: 0));
    final actor = overlay.children.whereType<BattleSceneCombatantComponent>()
        .singleWhere((actor) => !actor.isPlayerSide);
    actor.setEffectIntensity(0);
    actor.holdIntroSlideOffscreen(distancePx: 30);
    expect(actor.stageTint, const ui.Color(0xFF000000));
    await actor.playMaterializeIn(durationSeconds: 1);
    actor.update(.1);
    final tint = actor.stageTint;
    actor.setEffectIntensity(1);
    expect(actor.stageTint, tint);
    actor.setEffectIntensity(0);
    expect(actor.stageTint, tint);
  });

  testWidgets('reduced compression keeps neutral scale for user and system', (tester) async {
    for (final system in [false, true]) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: system);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final overlay = await _scene(policy: BattleMotionPolicy(reducedMotion: !system));
      overlay.updateTree(0);
      overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
        CombatantCompressStep(side: BattleSideId.player,
          scaleX: .3, scaleY: -.3, durationSeconds: .4),
      ]));
      overlay.updateTree(.1);
      final actor = overlay.children.whereType<BattleSceneCombatantComponent>()
          .singleWhere((actor) => actor.isPlayerSide);
      expect(actor.currentVisualScaleX, 1);
      expect(actor.currentVisualScaleY, 1);
      expect(overlay.isTurnPresentationActive, isTrue);
    }
  });

  test('legacy fast callers keep attack displacement until explicitly changed', () async {
    final legacy = await _scene(legacySpeed: 2.5);
    final reduced = await _scene(policy: BattleMotionPolicy(
      playbackSpeed: 2.5, reducedMotion: true));
    const plan = BattleAnimationPlan(steps: [
      CombatantMotionStep(side: BattleSideId.player,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: .4, distancePx: 40),
    ]);
    legacy.presentPostBattlePlan(plan);
    reduced.presentPostBattlePlan(plan);
    legacy.updateTree(.04);
    reduced.updateTree(.04);
    BattleSceneCombatantComponent actor(BattleOverlayComponent overlay) =>
        overlay.children.whereType<BattleSceneCombatantComponent>()
            .singleWhere((actor) => actor.isPlayerSide);
    expect(actor(legacy).currentVisualOffset.distance, greaterThan(1));
    expect(actor(reduced).currentVisualOffset.distance, 0);
    legacy.applyMotionPolicy(BattleMotionPolicy(reducedMotion: true));
    expect(actor(legacy).currentVisualOffset.distance, 0);
    expect(legacy.isTurnPresentationActive, isTrue);
  });

  test('hit flash intensity scales tint independently of its duration', () async {
    final overlay = await _scene();
    final actor = overlay.children.whereType<BattleSceneCombatantComponent>()
        .singleWhere((actor) => actor.isPlayerSide);
    await actor.playTone(color: const ui.Color(0xFFFF0000), durationSeconds: 1);
    actor.update(.1);
    actor.triggerHitFlash(duration: .24, intensity: 0);
    final none = actor.stageTint;
    actor.triggerHitFlash(duration: .24, intensity: .35);
    final dim = actor.stageTint;
    actor.triggerHitFlash(duration: .24, intensity: 1);
    final full = actor.stageTint;
    expect(dim.g, greaterThan(none.g));
    expect(dim.g, lessThan(full.g));
    expect(actor.isHitFlashActive, isTrue);
    actor.update(.1);
    overlay.applyMotionPolicy(BattleMotionPolicy(effectIntensity: 0));
    expect(actor.isHitFlashActive, isFalse);
    overlay.applyMotionPolicy(BattleMotionPolicy(effectIntensity: 1));
    expect(actor.isHitFlashActive, isTrue);
    actor.update(.15);
    expect(actor.isHitFlashActive, isFalse);
  });

  test('effect intensity changes raster opacity while its timeline advances', () async {
    final cache = BattleFxBundleCache();
    addTearDown(cache.dispose);
    final layer = BattleFxLayerComponent(size: Vector2.all(10), fxBundleCache: cache);
    final probe = _EffectProbe();
    layer.add(probe);
    await loadFlameComponent(layer);
    addTearDown(layer.onRemove);
    for (final intensity in [0.0, .35, 1.0]) {
      layer.effectIntensity = intensity;
      layer.updateTree(.1);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      layer.renderTree(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(10, 10);
      final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      expect(pixels.getUint8((5 * 10 + 5) * 4 + 3),
        closeTo(255 * intensity, 1));
      image.dispose();
      picture.dispose();
    }
    expect(probe.seconds, closeTo(.3, .000001));
  });

  testWidgets('system reduction stops camera without changing speed or stored policy', (tester) async {
    final policy = BattleMotionPolicy(playbackSpeed: 2);
    final overlay = await _scene(policy: policy);
    overlay.presentPostBattlePlan(_plan);
    overlay.updateTree(.1);
    expect(overlay.isBattleCameraActive, isTrue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    overlay.updateTree(0);
    expect(overlay.isBattleCameraActive, isFalse);
    expect(overlay.motionPolicy, policy);
    expect(overlay.motionPolicy.playbackSpeed, 2);
    expect(overlay.motionPolicy.reducedMotion, isFalse);
    for (var frame = 0; frame < 26; frame++) {
      overlay.updateTree(1 / 60);
    }
    expect(overlay.isTurnPresentationActive, isFalse);
  });

  test('fast playback keeps the same camera pose at the same scene time', () async {
    final normal = await _scene(policy: BattleMotionPolicy());
    final fast = await _scene(policy: BattleMotionPolicy(playbackSpeed: 2));
    normal.presentPostBattlePlan(_plan);
    fast.presentPostBattlePlan(_plan);
    normal.updateTree(.2);
    fast.updateTree(.1);
    final camera = normal.children.whereType<BattleStage3DComponent>().single.camera;
    final fastCamera = fast.children.whereType<BattleStage3DComponent>().single.camera;
    expect(camera.isHome, isFalse);
    expect(fastCamera.eye.distanceTo(camera.eye), lessThan(.000001));
    expect(fastCamera.aim.distanceTo(camera.aim), lessThan(.000001));
  });

  test('reduced motion preserves the normal combat duration', () async {
    final normal = await _scene(policy: BattleMotionPolicy());
    final reduced = await _scene(policy: BattleMotionPolicy(reducedMotion: true));
    normal.presentPostBattlePlan(_plan);
    reduced.presentPostBattlePlan(_plan);
    for (var frame = 0; frame < 50; frame++) {
      normal.updateTree(1 / 60);
      reduced.updateTree(1 / 60);
      expect(reduced.isTurnPresentationActive, normal.isTurnPresentationActive);
      expect(reduced.isBattleCameraActive, isFalse);
    }
  });

  test('legacy callers retain speed and camera reduction until explicit policy', () async {
    final legacy = await _scene(legacySpeed: 2.5);
    legacy.presentPostBattlePlan(_plan);
    legacy.updateTree(.1);
    expect(legacy.isBattleCameraActive, isFalse);
    legacy.applyMotionPolicy(BattleMotionPolicy(playbackSpeed: 2.5));
    legacy.presentPostBattlePlan(_plan);
    legacy.updateTree(.1);
    expect(legacy.isBattleCameraActive, isTrue);
    legacy.applyMotionPolicy(BattleMotionPolicy(reducedMotion: true));
    expect(legacy.isBattleCameraActive, isFalse);
  });
}

class _EffectProbe extends RectangleComponent {
  _EffectProbe() : super(size: Vector2.all(10),
    paint: ui.Paint()..color = const ui.Color(0xFFFF0000));

  double seconds = 0;

  @override
  void update(double dt) {
    super.update(dt);
    seconds += dt;
  }
}
