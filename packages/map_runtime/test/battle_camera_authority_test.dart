import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';

import 'support/load_flame_component.dart';

Future<BattleOverlayComponent> _scene({Vector2? size}) async {
  const pokemon = BattleCombatantData(
    speciesId: 'totodile', level: 7, maxHp: 25, currentHp: 25,
    stats: BattleStatsSnapshot(attack: 20, defense: 20, specialAttack: 20,
      specialDefense: 20, speed: 20),
    moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)],
  );
  final overlay = BattleOverlayComponent(
    session: createBattleSession(BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: pokemon, enemyPokemon: pokemon,
      playerReservePokemon: [pokemon],
      isTrainerBattle: false, trainerId: null,
    )),
    viewportSize: size ?? Vector2(390, 844), onPlayerChoice: (_) {},
  );
  await loadFlameComponent(overlay);
  await overlay.waitForPendingVisualSync();
  addTearDown(overlay.onRemove);
  return overlay;
}

BattlePerspectiveCamera _camera(BattleOverlayComponent overlay) =>
    overlay.children.whereType<BattleStage3DComponent>().single.camera;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cancel during a return to the same home goal stops immediately', () {
    final camera = BattlePerspectiveCamera(viewport: const Rect.fromLTWH(0, 0, 390, 430));
    camera.focus(const Offset(120, 390), playerSide: true, durationSeconds: 0);
    camera.reset(durationSeconds: .4);
    camera.update(.1);
    expect(camera.isHome, isFalse);
    camera.cancel();
    expect(camera.isHome, isTrue);
    expect(camera.isMoving, isFalse);
    camera.update(.2);
    expect(camera.isHome, isTrue);
  });

  test('activity is true from command start and unavailable projection is culled', () async {
    final overlay = await _scene();
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      AnimationGroupStep(mode: BattleAnimationGroupMode.parallel, steps: [
        CameraFocusStep(target: BattleCameraFocusTarget.user,
          side: BattleSideId.player, durationSeconds: .4),
      ]),
      WaitStep(durationSeconds: 1),
    ]));
    expect(overlay.isBattleCameraFocusActive, isTrue);
    expect(overlay.isBattleCameraActive, isTrue);
    final camera = _camera(overlay);
    camera.moveTo(eye: BattlePerspectiveCamera.homeEye,
      aim: BattlePerspectiveCamera.homeEye +
        (BattlePerspectiveCamera.homeEye - BattlePerspectiveCamera.homeAim),
      durationSeconds: 0);
    overlay.onGameResize(Vector2(390, 844));
    expect(camera.tryBillboardAt(overlay.currentSceneLayout.playerFootAnchor), isNull);
    expect(overlay.battleCameraScale, 0);
  });

  test('camera timelines agree at intermediate times across refresh rates', () {
    BattlePerspectiveCamera run(List<double> deltas) {
      final camera = BattlePerspectiveCamera(viewport: const Rect.fromLTWH(0, 0, 390, 430));
      camera.moveTo(eye: const BattleCameraPoint(9.7, 6.7, 19.3),
        aim: BattlePerspectiveCamera.homeAim, durationSeconds: .4,
        easing: BattleCameraEasing.easeOut);
      for (final dt in deltas) { camera.update(dt); }
      return camera;
    }
    final reference = run([.1]);
    for (final deltas in [List.filled(3, 1 / 30), List.filled(6, 1 / 60),
      List.filled(12, 1 / 120), [.013, .031, .017, .039]]) {
      expect(run(deltas).eye.distanceTo(reference.eye), lessThan(.000001));
    }
    expect(reference.isMoving, isTrue);
    reference.cancel();
    expect(reference.isHome, isTrue);
    expect(reference.isMoving, isFalse);
  });

  for (final entry in [1, 2]) {
    test('landscape collection $entry can hide an actor outside the projection domain', () async {
      final overlay = await _scene(size: Vector2(844, 390));
      expect(() => overlay.selectRootEntry(entry), returnsNormally);
      expect(() => overlay.updateTree(.1), returnsNormally);
      expect(() => overlay.onGameResize(Vector2(390, 844)), returnsNormally);
      expect(() => overlay.handleEscape(), returnsNormally);
      expect(overlay.debugPlayerCombatant!.currentRenderedSpriteRect.width, greaterThan(0));
    });
  }

  for (final curve in [BattleFxMotionCurve.linear, BattleFxMotionCurve.easeOut]) {
    test('the effective camera honors the requested $curve at intermediate times', () async {
      final overlay = await _scene();
      overlay.presentPostBattlePlan(BattleAnimationPlan(steps: [
        AnimationGroupStep(mode: BattleAnimationGroupMode.parallel, steps: [
          BattleCameraMoveStep(offsetX: 36, offsetY: 0, scale: .9,
            durationSeconds: .4, curve: curve),
        ]),
        const WaitStep(durationSeconds: 1),
      ]));
      for (var sample = 1; sample <= 4; sample++) {
        overlay.updateTree(.1);
        final t = sample / 4;
        final progress = curve == BattleFxMotionCurve.linear ? t : 1 - (1 - t) * (1 - t);
        final expected = BattlePerspectiveCamera.homeEye +
            const BattleCameraPoint(3, 0, 2) * progress;
        expect(_camera(overlay).eye.distanceTo(expected), lessThan(.000001));
      }
    });
  }

  test('diagnostics describe the actual player projection rather than a second rig', () async {
    final overlay = await _scene();
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      AnimationGroupStep(mode: BattleAnimationGroupMode.parallel, steps: [
        CameraFocusStep(target: BattleCameraFocusTarget.target,
          side: BattleSideId.enemy, durationSeconds: .4),
      ]),
      WaitStep(durationSeconds: 1),
    ]));
    overlay.updateTree(.1);
    final foot = overlay.currentSceneLayout.playerFootAnchor;
    final actual = _camera(overlay).billboardAt(foot);
    expect(overlay.battleCameraScale, closeTo(actual.scale, .000001));
    expect(overlay.battleCameraOffset.x, closeTo(actual.position.dx - foot.dx * actual.scale, .0001));
    expect(overlay.battleCameraOffset.y, closeTo(actual.position.dy - foot.dy * actual.scale, .0001));
  });

  test('replacing a plan restores the effective camera and cancels its old motion', () async {
    final overlay = await _scene();
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      AnimationGroupStep(mode: BattleAnimationGroupMode.parallel, steps: [
        CameraFocusStep(target: BattleCameraFocusTarget.user,
          side: BattleSideId.player, durationSeconds: .4),
      ]),
      WaitStep(durationSeconds: 1),
    ]));
    overlay.updateTree(.1);
    expect(_camera(overlay).isHome, isFalse);
    overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: [
      WaitStep(durationSeconds: 1),
    ]));
    expect(_camera(overlay).isHome, isTrue);
    expect(_camera(overlay).isMoving, isFalse);
    overlay.updateTree(.2);
    expect(_camera(overlay).isHome, isTrue);
    expect(overlay.battleCameraOffset, Vector2.zero());
    expect(overlay.battleCameraScale, 1);
  });
}
