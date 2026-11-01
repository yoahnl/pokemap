import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/application/runtime_battle_presentation.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';
import 'package:map_runtime/src/presentation/flame/battle_stage_3d_component.dart';

import 'support/load_flame_component.dart';

Future<BattleOverlayComponent> _scene(
  Vector2 size, {
  bool doubles = false,
  RuntimePsdkBattleSessionAdapter? battleAdapter,
}) async {
  const pokemon = BattleCombatantData(
    speciesId: 'totodile',
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
  final adapter = battleAdapter ?? (doubles ? _doubles() : null);
  final overlay = BattleOverlayComponent(
    session:
        adapter?.createLegacyDisplaySession(isTrainerBattle: true) ??
        createBattleSession(
          BattleSetup.pokeMapBetaV1ForTest(
            playerPokemon: pokemon,
            enemyPokemon: pokemon,
            isTrainerBattle: false,
            trainerId: null,
          ),
        ),
    presentation: adapter?.presentation,
    viewportSize: size,
    onPlayerChoice: (_) {},
  );
  await loadFlameComponent(overlay);
  await overlay.waitForPendingVisualSync();
  addTearDown(overlay.onRemove);
  return overlay;
}

RuntimePsdkBattleSessionAdapter _doubles({bool reserve = false}) {
  PsdkBattleCombatantSetup actor(String id) => PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 7,
    maxHp: 25,
    currentHp: 25,
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
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 10,
        currentPp: 10,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.doubles(
      ruleset: PokemonRulesetProfile.standardV1,
      player: [actor('player_0'), actor('player_1')],
      playerReserves: [if (reserve) actor('player_2')],
      opponent: [actor('enemy_0'), actor('enemy_1')],
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}

BattlePerspectiveCamera _camera(BattleOverlayComponent overlay) =>
    overlay.children.whereType<BattleStage3DComponent>().single.camera;

void _focus(BattleOverlayComponent overlay, BattleSideId side, {int slot = 0}) {
  overlay.presentPostBattlePlan(
    BattleAnimationPlan(
      steps: [
        AnimationGroupStep(
          mode: BattleAnimationGroupMode.parallel,
          steps: [
            CameraFocusStep(
              target: BattleCameraFocusTarget.user,
              side: side,
              slotIndex: slot,
              durationSeconds: .4,
            ),
          ],
        ),
        const WaitStep(durationSeconds: 10),
      ],
    ),
  );
}

void _expectPose(
  BattlePerspectiveCamera actual,
  BattleCameraPoint eye,
  BattleCameraPoint aim,
) {
  expect(actual.eye.distanceTo(eye), lessThan(.000001));
  expect(actual.aim.distanceTo(aim), lessThan(.000001));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'switch focus retains the displayed occupant identity until visual swap',
    () async {
      final adapter = _doubles(reserve: true);
      const slot = BattleSlotRef(side: BattleSideId.player, slotIndex: 1);
      final before = adapter.presentation.combatantAt(slot)!;
      final scene = await _scene(Vector2(390, 844), battleAdapter: adapter);
      adapter.submitDecision(
        const BattleDecision.fight(
          moveSlot: 0,
          target: PsdkBattleSlotRef(bank: 1, position: 1),
        ),
        request: adapter.decisionRequest,
      );
      adapter.submitDecision(
        const BattleDecision.switchPokemon(partyIndex: 2),
        request: adapter.decisionRequest,
      );
      final incoming = adapter.presentation.combatantAt(slot)!;
      expect(incoming.combatantId, isNot(before.combatantId));
      scene.updateState(
        adapter.createLegacyDisplaySession(isTrainerBattle: true),
        presentation: adapter.presentation,
      );
      await scene.waitForPendingVisualSync();
      expect(
        scene.currentCommandOverlaySnapshot!.additionalHuds
            .singleWhere((hud) => hud.slot == slot)
            .combatantId,
        before.combatantId,
      );
      scene.presentPostBattlePlan(
        const BattleAnimationPlan(
          steps: [
            AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [
                CameraFocusStep(
                  target: BattleCameraFocusTarget.user,
                  side: BattleSideId.player,
                  slotIndex: 1,
                  durationSeconds: .4,
                ),
              ],
            ),
            WaitStep(durationSeconds: .1),
            SwapCombatantVisualStep(side: BattleSideId.player, slotIndex: 1),
            WaitStep(durationSeconds: 10),
          ],
        ),
      );
      expect(scene.battleCameraFocusSubject, (
        slot: slot,
        lineupIndex: before.lineupIndex,
        combatantId: before.combatantId,
      ));
      scene.updateTree(.1);
      final camera = _camera(scene);
      final eye = camera.eye;
      final aim = camera.aim;
      scene.onGameResize(Vector2(844, 390));
      _expectPose(camera, eye, aim);
      expect(scene.battleCameraFocusSubject?.combatantId, before.combatantId);
      scene.updateTree(.29);
      expect(camera.isMoving, isTrue);
      scene.updateTree(.01);
      expect(camera.isMoving, isFalse);
      expect(camera.isHome, isFalse);
      scene.updateTree(.11);
      await Future<void>.delayed(Duration.zero);
      expect(scene.battleCameraFocusSubject, isNull);
      expect(camera.isHome, isTrue);
      expect(
        scene.currentCommandOverlaySnapshot!.additionalHuds
            .singleWhere((hud) => hud.slot == slot)
            .combatantId,
        incoming.combatantId,
      );
      scene.onGameResize(Vector2(390, 844));
      expect(camera.isHome, isTrue);
    },
  );

  test('a focused displayed occupant disappearing cancels and cannot be reacquired', () async {
    final adapter = _doubles();
    const slot = BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1);
    final scene = await _scene(Vector2(390, 844), battleAdapter: adapter);
    _focus(scene, slot.side, slot: slot.slotIndex);
    scene.updateTree(.1);
    expect(_camera(scene).isHome, isFalse);
    final before = adapter.presentation;
    final missing = RuntimeBattlePresentation(
      activeCombatants: before.activeCombatants.where(
        (actor) => actor.slot != slot,
      ),
      playerParty: before.playerParty,
      request: before.request,
      isDoubles: true,
    );
    scene.updateState(
      adapter.createLegacyDisplaySession(isTrainerBattle: true),
      presentation: missing,
    );
    await scene.waitForPendingVisualSync();
    expect(scene.battleCameraFocusSubject, isNull);
    expect(_camera(scene).isHome, isTrue);
    _focus(scene, slot.side, slot: slot.slotIndex);
    scene.onGameResize(Vector2(844, 390));
    expect(scene.battleCameraFocusSubject, isNull);
    expect(_camera(scene).isHome, isTrue);
    expect(_camera(scene).isMoving, isFalse);
  });

  for (final doubles in [false, true]) {
    for (final side in BattleSideId.values) {
      for (final portrait in [true, false]) {
        for (final elapsed in [0.0, .1, .4]) {
          test(
            'reflow $side doubles=$doubles portrait=$portrait elapsed=$elapsed',
            () async {
              final start = portrait ? Vector2(390, 844) : Vector2(844, 390);
              final finish = portrait ? Vector2(844, 390) : Vector2(390, 844);
              final scene = await _scene(start, doubles: doubles);
              final reference = await _scene(finish, doubles: doubles);
              final slot = doubles ? 1 : 0;
              _focus(scene, side, slot: slot);
              _focus(reference, side, slot: slot);
              reference.updateTree(.4);
              scene.updateTree(elapsed);
              final camera = _camera(scene);
              final beforeEye = camera.eye;
              final beforeAim = camera.aim;
              scene.onGameResize(finish);
              if (elapsed < .4) {
                _expectPose(camera, beforeEye, beforeAim);
                const step = .1;
                scene.updateTree(step);
                final from = BattleCameraEasing.legacyTwoSlope.transform(
                  elapsed / .4,
                );
                final to = BattleCameraEasing.legacyTwoSlope.transform(
                  (elapsed + step) / .4,
                );
                final progress = (to - from) / (1 - from);
                _expectPose(
                  camera,
                  beforeEye + (_camera(reference).eye - beforeEye) * progress,
                  beforeAim + (_camera(reference).aim - beforeAim) * progress,
                );
                expect(camera.isMoving, isTrue);
                scene.updateTree(.4 - elapsed - step);
              }
              _expectPose(
                camera,
                _camera(reference).eye,
                _camera(reference).aim,
              );
              expect(camera.isMoving, isFalse);
            },
          );
        }
      }
    }
  }

  for (final side in BattleSideId.values) {
    for (final panel in [false, true]) {
      test(
        'held $side resolves a new ${panel ? 'panel' : 'safe area'} layout',
        () async {
          final scene = await _scene(Vector2(844, 390));
          final reference = await _scene(Vector2(844, 390));
          void layout(BattleOverlayComponent overlay) {
            if (panel) {
              overlay.setCommandPanelPlacement(BattleCommandPanelPlacement.end);
            } else {
              overlay.setSafeAreaPadding(
                const EdgeInsets.fromLTRB(40, 20, 30, 10),
              );
            }
          }

          _focus(scene, side);
          scene.updateTree(.4);
          layout(scene);
          layout(reference);
          _focus(reference, side);
          reference.updateTree(.4);
          _expectPose(
            _camera(scene),
            _camera(reference).eye,
            _camera(reference).aim,
          );
          expect(_camera(scene).isMoving, isFalse);
        },
      );
    }
    test(
      'return $side keeps the home goal and original arrival through reflow',
      () async {
        final scene = await _scene(Vector2(390, 844));
        scene.presentPostBattlePlan(
          BattleAnimationPlan(
            steps: [
              AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [
                  CameraFocusStep(
                    target: BattleCameraFocusTarget.user,
                    side: side,
                    durationSeconds: .4,
                  ),
                ],
              ),
              const AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [BattleCameraResetStep(durationSeconds: .4)],
              ),
              const WaitStep(durationSeconds: 10),
            ],
          ),
        );
        scene.updateTree(.4);
        scene.updateTree(.1);
        final camera = _camera(scene);
        expect(camera.isHome, isFalse);
        final eye = camera.eye;
        final aim = camera.aim;
        scene.onGameResize(Vector2(844, 390));
        _expectPose(camera, eye, aim);
        scene.updateTree(.29);
        expect(camera.isMoving, isTrue);
        scene.updateTree(.01);
        expect(camera.isMoving, isFalse);
        expect(camera.isHome, isTrue);
        scene.onGameResize(Vector2(390, 844));
        expect(camera.isHome, isTrue);
      },
    );
    for (final faint in [true, false]) {
      test(
        '$side ${faint ? 'faint' : 'swap'} clears the focus intention',
        () async {
          final scene = await _scene(Vector2(390, 844));
          scene.presentPostBattlePlan(
            BattleAnimationPlan(
              steps: [
                CameraFocusStep(
                  target: BattleCameraFocusTarget.user,
                  side: side,
                  durationSeconds: .4,
                ),
                const WaitStep(durationSeconds: .1),
                if (faint)
                  FaintCombatantStep(side: side, durationSeconds: .1)
                else
                  SwapCombatantVisualStep(side: side),
                const WaitStep(durationSeconds: 10),
              ],
            ),
          );
          scene.updateTree(.4);
          expect(_camera(scene).isHome, isFalse);
          scene.updateTree(.11);
          expect(_camera(scene).isHome, isTrue);
          scene.onGameResize(Vector2(844, 390));
          expect(_camera(scene).isHome, isTrue);
          expect(_camera(scene).isMoving, isFalse);
        },
      );
    }
    test(
      '$side multiple reflows preserve the remaining curve and arrival',
      () async {
        final scene = await _scene(Vector2(390, 844));
        final reference = await _scene(Vector2(390, 844));
        _focus(scene, side);
        scene.updateTree(.1);
        scene.onGameResize(Vector2(844, 390));
        scene.updateTree(.1);
        final camera = _camera(scene);
        final eye = camera.eye;
        final aim = camera.aim;
        scene.onGameResize(Vector2(390, 844));
        _expectPose(camera, eye, aim);
        scene.setSafeAreaPadding(const EdgeInsets.only(top: 44, bottom: 34));
        reference.setSafeAreaPadding(
          const EdgeInsets.only(top: 44, bottom: 34),
        );
        scene.setCommandPanelPlacement(BattleCommandPanelPlacement.detached);
        reference.setCommandPanelPlacement(
          BattleCommandPanelPlacement.detached,
        );
        _focus(reference, side);
        reference.updateTree(.4);
        _expectPose(camera, eye, aim);
        scene.updateTree(.1);
        _expectPose(
          camera,
          eye + (_camera(reference).eye - eye) * .5,
          aim + (_camera(reference).aim - aim) * .5,
        );
        expect(camera.isMoving, isTrue);
        scene.updateTree(.1);
        _expectPose(camera, _camera(reference).eye, _camera(reference).aim);
        expect(camera.isMoving, isFalse);
      },
    );
    test(
      'missing $side occupant cancels focus without following a fallback',
      () async {
        final scene = await _scene(Vector2(390, 844));
        _focus(scene, side, slot: 1);
        expect(_camera(scene).isHome, isTrue);
        expect(_camera(scene).isMoving, isFalse);
        scene.onGameResize(Vector2(844, 390));
        expect(_camera(scene).isHome, isTrue);
      },
    );
  }
}
