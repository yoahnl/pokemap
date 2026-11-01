import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_motion_policy.dart';
import 'package:map_runtime/src/presentation/flame/battle_camera_motion_envelope.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';

import 'support/load_flame_component.dart';

Future<BattleOverlayComponent> scene({
  bool intro = false,
  BattlePokemonSpriteResolver? spriteResolver,
}) async {
  const pokemon = BattleCombatantData(
    speciesId: 'actor',
    level: 7,
    maxHp: 25,
    currentHp: 25,
    stats: BattleStatsSnapshot(
      attack: 20,
      defense: 20,
      specialAttack: 20,
      specialDefense: 20,
      speed: 20,
    ),
    moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)],
  );
  final overlay = BattleOverlayComponent(
    session: createBattleSession(
      BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: pokemon,
        enemyPokemon: pokemon,
        isTrainerBattle: false,
        trainerId: null,
      ),
    ),
    viewportSize: Vector2(390, 844),
    onPlayerChoice: (_) {},
    introEnabled: intro,
    spriteResolver: spriteResolver,
  );
  await loadFlameComponent(overlay);
  await overlay.waitForPendingVisualSync();
  addTearDown(overlay.onRemove);
  return overlay;
}

BattlePerspectiveCamera camera(BattleOverlayComponent overlay) =>
    overlay.children.whereType<BattleStage3DComponent>().single.camera;

void samePose(
  BattlePerspectiveCamera actual,
  BattlePerspectiveCamera expected,
) {
  expect(actual.eye.distanceTo(expected.eye), lessThan(.000001));
  expect(actual.aim.distanceTo(expected.aim), lessThan(.000001));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('late opaque geometry invalidates framing without a menu layout change', () async {
    final actual = await scene();
    final reference = await scene();
    final directory = Directory(
      Platform.isMacOS
          ? '${Platform.environment['HOME']!}/Library/Caches/AveluneQA/battle-camera-consolidation/c2-invalidation'
          : '${Directory.systemTemp.path}/avelune-battle-camera-consolidation/c2-invalidation',
    );
    await directory.create(recursive: true);
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 4, 20),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(20, 20);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    final file = File('${directory.path}/tall.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
    final beforeRevision = actual.battleCameraFramingRevision;
    for (final overlay in [actual, reference]) {
      await overlay.debugPlayerCombatant!.sync(
        speciesLabel: 'actor',
        spriteSpec: BattleCombatantSpriteSpec(
          facing: BattleCombatantSpriteFacing.back,
          explicitImageAbsolutePath: file.path,
        ),
      );
    }
    reference.onGameResize(Vector2(391, 844));
    reference.onGameResize(Vector2(390, 844));

    final mode = actual.currentSceneLayout.commandPanelMode;
    actual.moveSelectionRight();
    expect(actual.currentSceneLayout.commandPanelMode, mode);
    expect(actual.battleCameraFramingRevision, greaterThan(beforeRevision));
    samePose(camera(actual), camera(reference));
    final stableRevision = actual.battleCameraFramingRevision;
    for (var frame = 0; frame < 60; frame++) {
      actual.updateTree(1 / 60);
      actual.moveSelectionRight();
    }
    expect(actual.battleCameraFramingRevision, stableRevision);
  });

  test(
    'HUD reveal after a rotated focus recomputes overview in the same mode',
    () async {
      final actual = await scene();
      final reference = await scene();
      actual.presentPostBattlePlan(
        const BattleAnimationPlan(
          steps: [
            CameraFocusStep(
              target: BattleCameraFocusTarget.user,
              durationSeconds: .4,
            ),
            WaitStep(durationSeconds: .1),
            BattleCameraResetStep(durationSeconds: .4),
            WaitStep(durationSeconds: .1),
          ],
        ),
      );
      actual.updateTree(.4);
      actual.onGameResize(Vector2(844, 390));
      actual.onGameResize(Vector2(390, 844));
      final mode = actual.currentSceneLayout.commandPanelMode;
      final hiddenRevision = actual.battleCameraFramingRevision;
      actual.updateTree(.7);
      await actual.waitForPendingVisualSync();
      expect(actual.currentSceneLayout.commandPanelMode, mode);
      expect(actual.battleCameraFramingRevision, greaterThan(hiddenRevision));
      samePose(camera(actual), camera(reference));
    },
  );
  test(
    'reset samples the real held focus pose and keeps its original arrival',
    () async {
      final overlay = await scene();
      overlay.presentPostBattlePlan(
        const BattleAnimationPlan(
          steps: [
            CameraFocusStep(
              target: BattleCameraFocusTarget.user,
              durationSeconds: .4,
            ),
            WaitStep(durationSeconds: .1),
            BattleCameraResetStep(durationSeconds: .4),
            WaitStep(durationSeconds: 10),
          ],
        ),
      );
      overlay.updateTree(.4);
      final actualEye = camera(overlay).eye;
      final actualAim = camera(overlay).aim;
      expect(
        actualEye.distanceTo(BattlePerspectiveCamera.homeEye),
        greaterThan(.01),
      );
      overlay.updateTree(.1);
      final shot = overlay.battleCameraReturnShot!;
      expect(shot.startPose.eye.distanceTo(actualEye), lessThan(.000001));
      expect(shot.startPose.aim.distanceTo(actualAim), lessThan(.000001));
      overlay.updateTree(.39);
      expect(camera(overlay).isMoving, isTrue);
      overlay.updateTree(.01);
      expect(camera(overlay).isMoving, isFalse);
      expect(camera(overlay).isHome, isTrue);
    },
  );
  test('initial asynchronous explicit sprite load invalidates fallback geometry before any UI action', () async {
    final directory = Directory(
      Platform.isMacOS
          ? '${Platform.environment['HOME']!}/Library/Caches/AveluneQA/battle-camera-consolidation/c2-invalidation'
          : '${Directory.systemTemp.path}/avelune-battle-camera-consolidation/c2-invalidation',
    );
    await directory.create(recursive: true);
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 4, 20),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(20, 20);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    await File('${directory.path}/tall.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
    final media = File('${directory.path}/data/pokemon/media/actor.json');
    await media.parent.create(recursive: true);
    await media.writeAsString(
      jsonEncode({
        'defaultFormId': 'base',
        'variants': {
          'base': {'frontStatic': 'tall.png', 'backStatic': 'tall.png'},
        },
      }),
    );
    final fallback = await scene();
    final overlay = await scene(
      spriteResolver: BattlePokemonSpriteResolver(
        manifest: const ProjectManifest(
          name: 'framing',
          maps: [],
          tilesets: [],
        ),
        projectRootDirectory: directory.path,
      ),
    );
    expect(overlay.debugPlayerCombatant!.hasResolvedExplicitSprite, isTrue);
    expect(
      overlay.debugPlayerCombatant!.stableCameraGeometry.bounds.width /
          overlay.debugPlayerCombatant!.stableCameraGeometry.bounds.height,
      closeTo(.2, .00001),
    );
    expect(
      overlay.battleCameraFramingRevision,
      greaterThan(fallback.battleCameraFramingRevision),
    );
    final revision = overlay.battleCameraFramingRevision;
    for (var frame = 0; frame < 60; frame++) {
      overlay.updateTree(1 / 60);
    }
    expect(overlay.battleCameraFramingRevision, revision);
  });
  test('an immobile portrait focus retains the approved ideal 1.08 instead of the universal halo', () async {
    final overlay = await scene();
    final actor = overlay.debugPlayerCombatant!;
    final expected = camera(overlay)
        .idealFocusPose(actor.stableCameraGeometry.foot, playerSide: true);
    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: [
          CameraFocusStep(
            target: BattleCameraFocusTarget.user,
            side: BattleSideId.player,
            durationSeconds: .4,
          ),
          WaitStep(durationSeconds: 10),
        ],
      ),
    );
    overlay.updateTree(.4);
    expect(camera(overlay).eye.distanceTo(expected.eye), lessThan(.000001));
    expect(camera(overlay).aim.distanceTo(expected.aim), lessThan(.000001));
    expect(
      camera(overlay).billboardAt(actor.stableCameraGeometry.foot).scale,
      closeTo(1.08, .000001),
    );
  });
  test('directed lunge envelope is compiled once and survives focus rotation and effective settings', () async {
    final overlay = await scene();
    const slot = BattleSlotRef.active(BattleSideId.player);
    final actor = overlay.debugPlayerCombatant!;
    final bounds = actor.stableCameraGeometry.bounds;
    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: [
          CameraFocusStep(
            target: BattleCameraFocusTarget.user,
            side: BattleSideId.player,
            durationSeconds: .4,
          ),
          WaitStep(durationSeconds: 10),
          CombatantMotionStep(
            side: BattleSideId.player,
            motionKind: BattleCombatantMotionKind.lunge,
            distancePx: 30,
            durationSeconds: .22,
          ),
        ],
      ),
    );
    final revision = overlay.battleCameraMotionEnvelopeRevision;
    final envelope = overlay.battleCameraMotionEnvelope(slot)!;
    expect(envelope.left, bounds.left);
    expect(envelope.right, closeTo(bounds.right + 30, .000001));
    expect(envelope.top, closeTo(bounds.top - 4.8, .000001));
    expect(envelope.bottom, bounds.bottom);
    final identity = overlay.battleCameraFocusSubject;
    overlay.updateTree(.1);
    final eye = camera(overlay).eye;
    overlay.onGameResize(Vector2(844, 390));
    expect(camera(overlay).eye.distanceTo(eye), lessThan(.000001));
    expect(overlay.battleCameraFocusSubject, identity);
    overlay.updateTree(.29);
    expect(camera(overlay).isMoving, isTrue);
    overlay.updateTree(.01);
    expect(camera(overlay).isMoving, isFalse);
    for (var i = 0; i < 60; i++) {
      overlay.updateTree(1 / 60);
    }
    expect(overlay.battleCameraMotionEnvelopeRevision, revision);
    overlay.applyMotionPolicy(BattleMotionPolicy(reducedMotion: true));
    expect(
      overlay.battleCameraMotionEnvelope(slot),
      actor.stableCameraGeometry.framingBounds,
    );
    expect(overlay.debugPlayerCombatant, same(actor));
    overlay.applyMotionPolicy(BattleMotionPolicy());
    expect(
      overlay.battleCameraMotionEnvelope(slot)!.width,
      closeTo(actor.stableCameraGeometry.bounds.width + 30, .000001),
    );
    expect(overlay.battleCameraMotionEnvelopeRevision, revision);
  });

  test('actual tackle RMXP cell15 source and target frames stay inside their compiled slot envelope after reflow', () async {
    final overlay = await scene();
    const placement = RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.subjectAttached,
    );
    const steps = [
      PlayRmxpAnimationStep(
        animationId: 440,
        subjectSide: BattleSideId.enemy,
        attackerSide: BattleSideId.enemy,
        defenderSide: BattleSideId.player,
        phase: RmxpPlacementPhase.user,
        placementSpec: placement,
        reverse: true,
      ),
      PlayRmxpAnimationStep(
        animationId: 33,
        subjectSide: BattleSideId.player,
        attackerSide: BattleSideId.enemy,
        defenderSide: BattleSideId.player,
        phase: RmxpPlacementPhase.target,
        placementSpec: placement,
        reverse: true,
      ),
    ];
    expect(
      BattleSdkRmxpAnimationCatalog.moveTargetAnimationIdBySdkMoveId[33],
      33,
    );
    expect(
      BattleSdkRmxpAnimationCatalog.moveUserAnimationIdBySdkMoveId[33],
      440,
    );
    overlay.presentPostBattlePlan(
      const BattleAnimationPlan(
        steps: [WaitStep(durationSeconds: 10), ...steps],
      ),
    );
    final revision = overlay.battleCameraMotionEnvelopeRevision;
    var testedCells = 0;
    for (final viewport in [Vector2(390, 844), Vector2(844, 390)]) {
      overlay.onGameResize(viewport);
      final stage = overlay.currentSceneLayout.stageRect;
      final sceneScale = math.min(stage.width / 320, stage.height / 240);
      for (final step in steps) {
        final actor = step.subjectSide == BattleSideId.player
            ? overlay.debugPlayerCombatant!
            : overlay.debugEnemyCombatant!;
        final envelope = overlay.battleCameraMotionEnvelope(step.subjectSlot)!;
        final animation = BattleSdkRmxpAnimationCatalog.require(
          step.animationId,
        );
        final direction = step.reverse && !animation.forceNoReverse ? -1 : 1;
        for (final frame in animation.frames) {
          for (final cell in frame.cells.where((cell) => cell.index == 15)) {
            actor.applyRmxpTransform(
              offset: Offset(
                direction * cell.x / 2 * sceneScale,
                direction * cell.y / 2 * sceneScale,
              ),
              scale: (cell.zoom <= 0 ? 100 : cell.zoom) / 100,
            );
            final actual = actor.currentCameraNeutralRenderedSpriteRect;
            expect(actual.left, greaterThanOrEqualTo(envelope.left - .000001));
            expect(actual.top, greaterThanOrEqualTo(envelope.top - .000001));
            expect(actual.right, lessThanOrEqualTo(envelope.right + .000001));
            expect(actual.bottom, lessThanOrEqualTo(envelope.bottom + .000001));
            testedCells += 1;
          }
        }
        actor.clearRmxpTransform();
      }
    }
    expect(testedCells, greaterThan(0));
    expect(overlay.battleCameraMotionEnvelopeRevision, revision);
  });

  test('a real tackle turn uses its actual RMXP envelope and keeps a moderate target focus', () async {
    final overlay = await scene();
    final revision = overlay.battleCameraMotionEnvelopeRevision;
    overlay.updateState(
      overlay.debugSession.applyChoice(const PlayerBattleChoiceFight(0)),
    );
    await overlay.waitForPendingVisualSync();
    expect(overlay.battleCameraMotionEnvelopeRevision, revision + 1);
    for (final slot in [
      const BattleSlotRef.active(BattleSideId.player),
      const BattleSlotRef.active(BattleSideId.enemy),
    ]) {
      final actor = slot.side == BattleSideId.player
          ? overlay.debugPlayerCombatant!
          : overlay.debugEnemyCombatant!;
      final envelope = overlay.battleCameraMotionEnvelope(slot)!;
      expect(
        envelope.width,
        lessThan(actor.stableCameraGeometry.bounds.width + 100),
      );
    }
    var sawHeldFocus = false;
    for (var frame = 0; frame < 600; frame++) {
      overlay.updateTree(1 / 60);
      final subject = overlay.battleCameraFocusSubject;
      if (subject != null && !camera(overlay).isMoving) {
        final actor = subject.slot.side == BattleSideId.player
            ? overlay.debugPlayerCombatant!
            : overlay.debugEnemyCombatant!;
        expect(
          camera(overlay).billboardAt(actor.stableCameraGeometry.foot).scale,
          inInclusiveRange(.95, 1.15),
        );
        sawHeldFocus = true;
        break;
      }
      await Future<void>.delayed(Duration.zero);
    }
    expect(sawHeldFocus, isTrue);
    expect(overlay.battleCameraMotionEnvelopeRevision, revision + 1);
  });
  for (final side in BattleSideId.values) {
    test(
      'compiled native families contain rendered frames for $side and RMXP replaces native motion',
      () async {
        final overlay = await scene();
        final actor = side == BattleSideId.player
            ? overlay.debugPlayerCombatant!
            : overlay.debugEnemyCombatant!;
        final slot = BattleSlotRef.active(side);
        final native = <BattleAnimationStep>[
          CombatantMotionStep(
            side: side,
            motionKind: BattleCombatantMotionKind.lunge,
            distancePx: 30,
            durationSeconds: 1,
          ),
          CombatantMotionStep(
            side: side,
            motionKind: BattleCombatantMotionKind.fastDash,
            distancePx: 90,
            durationSeconds: 1,
          ),
          CombatantShakeStep(side: side, amplitudePx: 12, durationSeconds: 1),
          CombatantEllipseStep(
            side: side,
            radiusX: 18,
            radiusY: 12,
            turns: 2,
            durationSeconds: 1,
          ),
          CombatantCompressStep(
            side: side,
            scaleX: .2,
            scaleY: -.3,
            durationSeconds: 1,
          ),
        ];
        for (final step in native) {
          overlay.presentPostBattlePlan(
            BattleAnimationPlan(
              steps: [const WaitStep(durationSeconds: 10), step],
            ),
          );
          final envelope = overlay.battleCameraMotionEnvelope(slot)!;
          switch (step) {
            case CombatantMotionStep():
              if (step.motionKind == BattleCombatantMotionKind.lunge) {
                await actor.playLunge(
                  towardOpponent: true,
                  distancePx: step.distancePx,
                  durationSeconds: 1,
                );
              } else {
                await actor.playFastDash(
                  towardOpponent: true,
                  distancePx: step.distancePx,
                  durationSeconds: 1,
                );
              }
            case CombatantShakeStep():
              await actor.playShake(
                amplitudePx: step.amplitudePx,
                durationSeconds: 1,
              );
            case CombatantEllipseStep():
              await actor.playEllipse(
                radiusX: step.radiusX,
                radiusY: step.radiusY,
                turns: step.turns,
                durationSeconds: 1,
              );
            case CombatantCompressStep():
              await actor.playCompress(
                scaleX: step.scaleX,
                scaleY: step.scaleY,
                durationSeconds: 1,
              );
            default:
              fail('Unexpected native motion');
          }
          for (var frame = 0; frame <= 60; frame++) {
            final actual = actor.currentCameraNeutralRenderedSpriteRect;
            expect(actual.left, greaterThanOrEqualTo(envelope.left - .000001));
            expect(actual.top, greaterThanOrEqualTo(envelope.top - .000001));
            expect(actual.right, lessThanOrEqualTo(envelope.right + .000001));
            expect(actual.bottom, lessThanOrEqualTo(envelope.bottom + .000001));
            actor.update(1 / 60);
          }
        }
        await actor.playLunge(
          towardOpponent: true,
          distancePx: 30,
          durationSeconds: 1,
        );
        actor.update(.25);
        expect(actor.currentVisualOffset.distance, greaterThan(1));
        final cell = BattleSdkRmxpAnimationCatalog.require(440).frames
            .expand((frame) => frame.cells)
            .firstWhere((cell) => cell.index == 15);
        final stage = overlay.currentSceneLayout.stageRect;
        final scale = math.min(stage.width / 320, stage.height / 240);
        final offset = Offset(cell.x / 2 * scale, cell.y / 2 * scale);
        actor.applyRmxpTransform(
          offset: offset,
          scale: (cell.zoom <= 0 ? 100 : cell.zoom) / 100,
        );
        actor.update(.25);
        expect(actor.currentVisualOffset, offset);
        actor.clearRmxpTransform();
      },
    );
  }

  test('a native lunge keeps the preceding declared RMXP zoom inside the compiled envelope', () async {
    final overlay = await scene();
    final actor = overlay.debugPlayerCombatant!;
    final geometry = actor.stableCameraGeometry;
    const declared = BattleCameraMotionEnvelope(
      nativeOffsets: Rect.fromLTRB(0, -4.8, 30, 0),
      rmxpOffsets: Rect.fromLTRB(0, 0, 5, 2),
      rmxpScale: 1.5,
    );
    final envelope = declared.resolve(geometry, rmxpSceneScale: 1);
    actor.applyRmxpTransform(offset: const Offset(5, 2), scale: 1.5);
    await actor.playLunge(
      towardOpponent: true,
      distancePx: 30,
      durationSeconds: 1,
    );
    actor.update(.5);
    expect(actor.currentVisualScaleX, 1.5);
    expect(
      actor.currentCameraNeutralRenderedSpriteRect.right,
      lessThanOrEqualTo(envelope.right + .000001),
    );
    expect(
      actor.currentCameraNeutralRenderedSpriteRect.top,
      greaterThanOrEqualTo(envelope.top - .000001),
    );
  });
  test('four native-sized opaque actors keep readable overview around dispersed HUDs in portrait', () async {
    final directory = Directory(
      Platform.isMacOS
          ? '${Platform.environment['HOME']!}/Library/Caches/AveluneQA/battle-camera-consolidation/c2-invalidation'
          : '${Directory.systemTemp.path}/avelune-battle-camera-consolidation/c2-invalidation',
    );
    await directory.create(recursive: true);
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    for (final entry in {
      'totodile': const Rect.fromLTRB(6, 13, 73, 68),
      'rattata': const Rect.fromLTRB(22, 21, 59, 60),
    }.entries) {
      final recorder = PictureRecorder();
      Canvas(recorder)
          .drawRect(entry.value, Paint()..color = const Color(0xFFFFFFFF));
      final picture = recorder.endRecording();
      final image = await picture.toImage(80, 80);
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await File('${directory.path}/${entry.key}.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      final media = File(
        '${directory.path}/data/pokemon/media/${entry.key}.json',
      );
      await media.parent.create(recursive: true);
      await media.writeAsString(
        jsonEncode({
          'defaultFormId': 'base',
          'variants': {
            'base': {
              'frontStatic': '${entry.key}.png',
              'backStatic': '${entry.key}.png',
            },
          },
        }),
      );
    }
    PsdkBattleCombatantSetup combatant(String id, String species) =>
        PsdkBattleCombatantSetup(
          id: id,
          speciesId: species,
          displayName: id,
          level: 7,
          maxHp: 50,
          currentHp: 50,
          types: const PsdkBattleTypes(primary: 'normal'),
          stats: const PsdkBattleStats(
            attack: 20,
            defense: 20,
            specialAttack: 20,
            specialDefense: 20,
            speed: 20,
          ),
          moves: [
            PsdkBattleMoveData(
              id: 'tackle',
              dbSymbol: 'tackle',
              name: 'Charge',
              type: 'normal',
              category: PsdkBattleMoveCategory.physical,
              power: 40,
              accuracy: 100,
              pp: 35,
              currentPp: 35,
              priority: 0,
              battleEngineMethod: 's_basic',
              target: PsdkBattleMoveTarget.adjacentFoe,
            ),
          ],
        );
    final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
      PsdkBattleSetup.doubles(
        ruleset: PokemonRulesetProfile.standardV1,
        player: [
          combatant('player_0', 'totodile'),
          combatant('player_1', 'totodile'),
        ],
        opponent: [
          combatant('opponent_0', 'rattata'),
          combatant('opponent_1', 'rattata'),
        ],
        rngSeeds: const PsdkBattleRngSeeds(
          moveDamage: 1,
          moveCritical: 2,
          moveAccuracy: 3,
          generic: 4,
        ),
      ),
    );
    final overlay = BattleOverlayComponent(
      session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
      presentation: adapter.presentation,
      viewportSize: Vector2(393, 852),
      onPlayerChoice: (_) {},
      onPlayerDecision: (_, _) {},
      spriteResolver: BattlePokemonSpriteResolver(
        manifest: const ProjectManifest(
          name: 'four actors',
          maps: [],
          tilesets: [],
        ),
        projectRootDirectory: directory.path,
      ),
    );
    await loadFlameComponent(overlay);
    await overlay.waitForPendingVisualSync();
    addTearDown(overlay.onRemove);
    overlay.setCommandPanelPlacement(
      BattleCommandPanelPlacement.bottom,
      controllerLayout: true,
      portraitTouchLayout: true,
    );
    final actors = [
      overlay.debugEnemyCombatant!,
      overlay.debugPlayerCombatant!,
      ...overlay.children.whereType<BattleSceneCombatantComponent>().where(
        (actor) =>
            !identical(actor, overlay.debugEnemyCombatant) &&
            !identical(actor, overlay.debugPlayerCombatant),
      ),
    ];
    expect(actors.length, 4);
    final ratios = [
      for (final actor in actors)
        camera(overlay).billboardAt(actor.stableCameraGeometry.foot).scale,
    ];
    final layout = overlay.currentSceneLayout;
    final huds = [
      for (final side in BattleSideId.values)
        for (var index = 0; index < 2; index++)
          layout
              .combatantGeometry(
                BattleSlotRef(side: side, slotIndex: index),
                doubles: true,
              )
              .hudRect,
    ];
    final detail =
        'stage=${layout.stageRect} arena=${layout.arenaRect} huds=$huds subjects=${actors.map((a) => (a.stableCameraGeometry.foot, a.stableCameraGeometry.bounds)).toList()} eye=${camera(overlay).eye.x},${camera(overlay).eye.y},${camera(overlay).eye.z} aim=${camera(overlay).aim.x},${camera(overlay).aim.y},${camera(overlay).aim.z} scales=$ratios';
    expect(ratios.reduce(math.min), greaterThanOrEqualTo(.85), reason: detail);
    for (final actor in actors) {
      final actual = actor.currentRenderedSpriteRect;
      for (final hud in huds) {
        expect(actual.inflate(8).overlaps(hud), isFalse);
      }
      expect(layout.stageRect.deflate(8).contains(actual.topLeft), isTrue);
      expect(layout.stageRect.deflate(8).contains(actual.bottomRight), isTrue);
    }
  });
}
