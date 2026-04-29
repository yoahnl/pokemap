import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui show Image, KeyEventDeviceType;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart'
    show
        Directionality,
        KeyEventResult,
        LayoutBuilder,
        Text,
        TextDirection,
        ValueListenableBuilder;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame runtime input seam', () {
    test('public runtime input API is safe before onLoad', () {
      final game = PlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      expect(
        () => game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        returnsNormally,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isFalse,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.up),
        ),
        isFalse,
      );
    });

    test('onKeyEvent forwards keyboard events to the runtime input seam', () {
      final game = _RecordingPlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      final result = game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        const <LogicalKeyboardKey>{},
      );

      expect(result, KeyEventResult.handled);
      expect(
        game.recordedEvents,
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.primary),
        ],
      );
    });

    test('onKeyEvent forwards gamepad buttons to the runtime input seam', () {
      final game = _RecordingPlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );

      final downResult = game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: ui.KeyEventDeviceType.gamepad,
        ),
        const <LogicalKeyboardKey>{},
      );
      final upResult = game.onKeyEvent(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.gameButtonA,
          timeStamp: Duration.zero,
          deviceType: ui.KeyEventDeviceType.gamepad,
        ),
        const <LogicalKeyboardKey>{},
      );

      expect(downResult, KeyEventResult.handled);
      expect(upResult, KeyEventResult.handled);
      expect(
        game.recordedEvents,
        const <RuntimeInputEvent>[
          RuntimeInputEvent.press(RuntimeInputControl.primary),
          RuntimeInputEvent.release(RuntimeInputControl.primary),
        ],
      );
    });

    test(
        'direct dialogue locks movement before dialogue content finishes loading',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_dialogue_pending_lock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _npcDialogueMap(),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'intro',
            name: 'Intro',
            relativePath: 'dialogues/intro.yarn',
          ),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'npc_dialogue_map',
      );
      final dialogueCompleter = Completer<DialogueSession?>();
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        dialogueSessionLoader: (_) => dialogueCompleter.future,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );

      expect(game.debugHasPendingDialogueLoad, isTrue);
      expect(game.debugIsGameplayInputLocked, isTrue);
      expect(game.debugFlowPhaseName, 'blockingInteraction');
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.down),
        ),
        isTrue,
      );
      game.update(0.016);
      await Future<void>.delayed(Duration.zero);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.down),
        ),
        isTrue,
      );

      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugFlowPhaseName, 'blockingInteraction');

      dialogueCompleter.complete(_singleLineDialogueSession('Bonjour.'));
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');

      expect(game.debugHasPendingDialogueLoad, isFalse);
      expect(game.debugIsGameplayInputLocked, isTrue);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsGameplayInputLocked, isFalse);
    });

    test('failed pending dialogue unlocks gameplay and shows fallback',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_dialogue_pending_failure_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _npcDialogueMap(),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'intro',
            name: 'Intro',
            relativePath: 'dialogues/intro.yarn',
          ),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'npc_dialogue_map',
      );
      final dialogueCompleter = Completer<DialogueSession?>();
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        dialogueSessionLoader: (_) => dialogueCompleter.future,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );

      expect(game.debugHasPendingDialogueLoad, isTrue);
      expect(game.debugFlowPhaseName, 'blockingInteraction');

      dialogueCompleter.complete(null);
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'overworld');

      expect(game.debugHasPendingDialogueLoad, isFalse);
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(game.debugNotificationText, 'Professor Oak');

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.down),
        ),
        isTrue,
      );
      game.update(0.016);
      await Future<void>.delayed(Duration.zero);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.down),
        ),
        isTrue,
      );
      await _pumpUntil(game, () => !game.debugIsPlayerStepping);

      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
    });

    test('script dialogue locks gameplay before dialogue overlay is mounted',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_script_dialogue_pending_lock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _eventScriptDialogueMap(),
        ],
        scripts: <ProjectScriptEntry>[
          const ProjectScriptEntry(
            id: 'intro_script',
            name: 'Intro Script',
            asset: ScriptAsset(
              id: 'intro_script',
              defaultStartNode: 'start',
              nodes: <ScriptNode>[
                ScriptNode(
                  id: 'start',
                  commands: <ScriptCommand>[
                    ScriptCommand(
                      type: ScriptCommandType.openDialogue,
                      params: <String, String>{
                        'filePath': 'dialogues/intro.yarn',
                        'startNode': 'Start',
                      },
                    ),
                    ScriptCommand(type: ScriptCommandType.end),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'event_script_dialogue_map',
      );
      final dialogueCompleter = Completer<DialogueSession?>();
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        dialogueSessionLoader: (_) => dialogueCompleter.future,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );

      expect(game.debugHasPendingDialogueLoad, isTrue);
      expect(game.debugIsGameplayInputLocked, isTrue);
      expect(game.debugFlowPhaseName, 'blockingInteraction');

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.down),
        ),
        isTrue,
      );
      game.update(0.016);
      await Future<void>.delayed(Duration.zero);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.down),
        ),
        isTrue,
      );

      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));

      dialogueCompleter.complete(_singleLineDialogueSession('Script hello.'));
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsGameplayInputLocked, isFalse);
    });

    test('pending dialogue prevents a second interaction from starting',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_dialogue_pending_second_interaction_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _npcDialogueMap(),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'intro',
            name: 'Intro',
            relativePath: 'dialogues/intro.yarn',
          ),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'npc_dialogue_map',
      );
      var loadCount = 0;
      final dialogueCompleter = Completer<DialogueSession?>();
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        dialogueSessionLoader: (_) {
          loadCount += 1;
          return dialogueCompleter.future;
        },
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      expect(loadCount, 1);
      expect(game.debugHasPendingDialogueLoad, isTrue);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      game.update(0.016);
      await Future<void>.delayed(Duration.zero);

      expect(loadCount, 1);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));

      dialogueCompleter.complete(_singleLineDialogueSession('Bonjour.'));
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');
    });

    test('pending scenario blocks overworld input affordances until resolved',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_pending_scenario_blocks_inputs_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _npcDialogueMap(),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'intro',
            name: 'Intro',
            relativePath: 'dialogues/intro.yarn',
          ),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'npc_dialogue_map',
      );
      final dialogueCompleter = Completer<DialogueSession?>();
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        dialogueSessionLoader: (_) => dialogueCompleter.future,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      expect(game.debugHasPendingDialogueLoad, isTrue);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.down),
        ),
        isTrue,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      game.update(0.016);
      await Future<void>.delayed(Duration.zero);

      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugFlowPhaseName, 'blockingInteraction');
      expect(game.debugIsGameplayInputLocked, isTrue);

      dialogueCompleter.complete(_singleLineDialogueSession('Bonjour.'));
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');
    });

    test('followCharacter player step uses full tile movement on 32px maps',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_follow_full_tile_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
        ),
        maps: <MapData>[
          _followLeaderMap32(),
        ],
        tilesets: _followScenarioTilesets,
        characters: _followScenarioCharacters,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'follow_leader_map_32',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));

      expect(game.debugStartScenarioFollow('emma'), isTrue);

      expect(game.debugHasActiveScenarioFollow, isTrue);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(game.debugIsPlayerStepping, isTrue);
      await _pumpUntil(game, () => !game.debugIsPlayerStepping);
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 1));
      expect(
        game.debugPlayerWorldTopLeft,
        game.debugExpectedPlayerWorldTopLeft,
      );
    });

    test('followCharacter follower keeps pace with a walking leader', () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_follow_pace_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
        ),
        maps: <MapData>[
          _followLeaderMap32(),
        ],
        tilesets: _followScenarioTilesets,
        characters: _followScenarioCharacters,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'follow_leader_map_32',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(game.debugStartScenarioFollow('emma'), isTrue);
      expect(
        game
            .startScriptedNpcMove(
              entityId: 'emma',
              destination: const GridPos(x: 7, y: 1),
            )
            .state,
        ScriptedEntityMovementState.moving,
      );

      var maxDistance = 0;
      await _pumpUntil(
        game,
        () {
          final leaderPos = game.debugNpcGridPosition('emma');
          if (leaderPos != null) {
            final playerPos = game.debugPlayerGridPosition;
            final distance = (leaderPos.x - playerPos.x).abs() +
                (leaderPos.y - playerPos.y).abs();
            if (distance > maxDistance) {
              maxDistance = distance;
            }
          }
          return !game.debugHasActiveScenarioFollow &&
              game.scriptedNpcMovementStatus('emma').state !=
                  ScriptedEntityMovementState.moving;
        },
        maxTicks: 480,
      );

      expect(maxDistance, lessThanOrEqualTo(2));
      expect(game.debugPlayerGridPosition, const GridPos(x: 6, y: 1));
    });

    test(
        'followCharacter pathfinding ignores the followed leader dynamic blocker',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_follow_ignore_leader_blocker_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
        ),
        maps: <MapData>[
          _followLeaderMap32(),
        ],
        tilesets: _followScenarioTilesets,
        characters: _followScenarioCharacters,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'follow_leader_map_32',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 1),
        facing: Direction.east,
      );

      expect(
        game
            .startScriptedNpcMove(
              entityId: 'emma',
              destination: const GridPos(x: 3, y: 1),
            )
            .state,
        ScriptedEntityMovementState.moving,
      );
      game.update(0.016);
      await Future<void>.delayed(Duration.zero);

      expect(game.debugStartScenarioFollow('emma'), isTrue);

      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
      expect(game.debugScenarioFollowConsecutiveBlockedSteps, 0);
      expect(game.debugLastFollowPathNodeCount, lessThanOrEqualTo(2));
    });

    test('followCharacter transfers player when followed leader enters a warp',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_follow_warp_handoff_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
        ),
        maps: <MapData>[
          _followLeaderWarpSourceMap32(),
          _followLeaderWarpTargetMap32(),
        ],
        tilesets: _followScenarioTilesets,
        characters: _followScenarioCharacters,
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'follow_warp_source_map_32',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(game.debugStartScenarioFollow('emma'), isTrue);
      expect(
        game.debugRunScenarioMoveCharacterToWarp(
          entityId: 'emma',
          warpId: 'to_lab',
        ),
        isTrue,
      );

      await _pumpUntil(game, () => game.debugHasPendingLeaderWarpHandoff);
      expect(game.debugHasActiveScenarioFollow, isTrue);
      expect(game.gameStateSnapshot.currentMapId, 'follow_warp_source_map_32');

      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId ==
                'follow_warp_target_map_32' &&
            game.debugFlowPhaseName == 'overworld',
        maxTicks: 480,
      );

      expect(game.gameStateSnapshot.currentMapId, 'follow_warp_target_map_32');
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(game.debugHasPendingLeaderWarpHandoff, isFalse);
      expect(game.debugHasActiveScenarioFollow, isFalse);
    });

    test('non-follow NPC dynamic collision still blocks the player', () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_non_follow_npc_collision_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _blockingNpcMap(),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'blocking_npc_map',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      await Future<void>.delayed(Duration.zero);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
      expect(game.debugHasActiveScenarioFollow, isFalse);
    });

    test('one cardinal step lands on the expected cell without a visual offset',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_step_regression_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _singleStepMap(),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'step_map',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _runSingleMove(game, RuntimeInputControl.right);

      expect(game.gameStateSnapshot.currentMapId, 'step_map');
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 0));
      expect(
          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
    });

    test('normal overworld walk step uses the full tile width on 32px maps',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_step_full_tile_32px_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
          displayScale: 1,
        ),
        maps: <MapData>[
          _singleStepMap(),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'step_map',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _runSingleMove(game, RuntimeInputControl.right);

      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 0));
      expect(
          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
      expect(game.debugPlayerWorldTopLeft.x, 32);
    });

    test('held directional input chains full-tile steps without an idle gap',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_step_chain_full_tile_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
          displayScale: 1,
        ),
        maps: <MapData>[
          _wideStepMap(),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'wide_step_map',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      for (var i = 0; i < 16; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );
      await _pumpUntil(
        game,
        () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
      );

      expect(game.gameStateSnapshot.playerPosition.x, greaterThanOrEqualTo(2));
      expect(game.debugPlayerWorldTopLeft.x, greaterThanOrEqualTo(64));
      expect(
          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
    });

    test('walk encounter check runs once per completed movement step',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_step_encounter_once_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        settings: const ProjectSettings(
          tileWidth: 64,
          tileHeight: 64,
          displayScale: 1,
        ),
        maps: <MapData>[
          _encounterStepMap(),
        ],
        encounterTables: const <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'field_grass',
            name: 'Field Grass',
            encounterKind: EncounterKind.walk,
            entries: <ProjectEncounterEntry>[
              ProjectEncounterEntry(
                speciesId: 'pidgey',
                minLevel: 2,
                maxLevel: 2,
                weight: 1,
              ),
            ],
          ),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'encounter_step_map',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _runSingleMove(game, RuntimeInputControl.right);

      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
      expect(game.debugEncounterCheckCount, 1);
    });

    test(
        'warp transition keeps the player visually aligned to the logical target',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_warp_regression_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _warpSourceMap(),
          _targetMap(id: 'warp_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'warp_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'warp_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping &&
            !game.debugHasPendingMapTransition,
      );

      expect(game.gameStateSnapshot.currentMapId, 'warp_target');
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 1));
      expect(
          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
    });

    test(
        'connection transition keeps the player visually aligned to the logical target',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_regression_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'connection_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping &&
            !game.debugHasPendingMapTransition,
      );

      expect(game.gameStateSnapshot.currentMapId, 'connection_target');
      expect(
        game.gameStateSnapshot.playerPosition,
        const GridPos(x: 0, y: 0),
      );
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 0, y: 0));
      expect(
          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
    });

    test(
        'connection transition animates one entry step in target map coordinates',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_trajectory_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      final firstTopLeftAfterSwap = await _captureFirstTopLeftOnMap(
        game,
        targetMapId: 'connection_target',
      );

      expect(firstTopLeftAfterSwap, isNotNull);
      expect(game.debugFlowPhaseName, 'mapTransition');
      expect(game.debugIsPlayerStepping, isTrue);
      expect(
        firstTopLeftAfterSwap,
        game.debugWorldTopLeftForSpawnCell(const GridPos(x: -1, y: 0)),
      );

      final samples = <double>[firstTopLeftAfterSwap!.x];
      for (var i = 0; i < 3; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
        samples.add(game.debugPlayerWorldTopLeft.x);
      }
      expect(samples[1], samples[0]);
      expect(samples[2], greaterThan(samples[1]));
      expect(samples[3], greaterThan(samples[2]));

      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'connection_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping,
      );
      expect(
        game.debugPlayerWorldTopLeft,
        game.debugWorldTopLeftForSpawnCell(const GridPos(x: 0, y: 0)),
      );
    });

    test(
        'warp transition snaps cleanly after fade and does not interpolate across maps',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_warp_trajectory_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _warpSourceMap(),
          _targetMap(id: 'warp_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'warp_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      final firstTopLeftAfterSwap = await _captureFirstTopLeftOnMap(
        game,
        targetMapId: 'warp_target',
      );

      expect(firstTopLeftAfterSwap, isNotNull);
      expect(game.debugIsPlayerStepping, isFalse);

      for (var i = 0; i < 5; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
        expect(game.debugPlayerWorldTopLeft.x, firstTopLeftAfterSwap!.x);
        expect(game.debugPlayerWorldTopLeft.y, firstTopLeftAfterSwap.y);
      }
    });

    test(
        'connection transition west and east use target-space entry start cells',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_directional_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
          _connectionTargetWestMap(),
          _connectionWestSourceMap(),
        ],
      );

      final eastBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final eastGame = _TestPlayableMapGame(
        bundle: eastBundle,
        projectFilePath: projectFilePath,
      );
      eastGame.onGameResize(_testViewportSize);
      await eastGame.onLoad();
      expect(
        eastGame.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      eastGame.update(0.016);
      expect(
        eastGame.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );
      final eastFirstTopLeft = await _captureFirstTopLeftOnMap(
        eastGame,
        targetMapId: 'connection_target',
      );
      expect(
        eastFirstTopLeft,
        eastGame.debugWorldTopLeftForSpawnCell(const GridPos(x: -1, y: 0)),
      );

      final westBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source_west',
      );
      final westGame = _TestPlayableMapGame(
        bundle: westBundle,
        projectFilePath: projectFilePath,
      );
      westGame.onGameResize(_testViewportSize);
      await westGame.onLoad();
      expect(
        westGame.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.left),
        ),
        isTrue,
      );
      westGame.update(0.016);
      expect(
        westGame.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.left),
        ),
        isTrue,
      );
      final westFirstTopLeft = await _captureFirstTopLeftOnMap(
        westGame,
        targetMapId: 'connection_target_west',
      );
      expect(
        westFirstTopLeft,
        westGame.debugWorldTopLeftForSpawnCell(const GridPos(x: 3, y: 0)),
      );
    });

    test(
        'connection transition keeps input locked until visual entry step completes',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_input_lock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      await _captureFirstTopLeftOnMap(
        game,
        targetMapId: 'connection_target',
      );

      expect(game.debugFlowPhaseName, 'mapTransition');
      expect(game.debugIsPlayerStepping, isTrue);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.left),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.left),
        ),
        isTrue,
      );

      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'connection_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping,
      );
      expect(
        game.gameStateSnapshot.playerPosition,
        const GridPos(x: 0, y: 0),
      );
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 0, y: 0));
    });

    test(
        'connection preserves player screen position on first target-map frame',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_screen_continuity_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      final continuity = await _captureConnectionContinuitySample(
        game,
        sourceMapId: 'connection_source',
        targetMapId: 'connection_target',
        postSwapFirstFrameDt: 0.080,
      );

      expect(continuity.sourceScreenTopLeft, isNotNull);
      expect(continuity.targetScreenTopLeft, isNotNull);
      expect(
        continuity.sourceScreenTopLeft!.distanceTo(
          continuity.targetScreenTopLeft!,
        ),
        lessThanOrEqualTo(1.0),
      );
    });

    test(
        'connection preserves tile-space camera continuity, not only player screen continuity',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_tile_continuity_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        settings: const ProjectSettings(
          tileWidth: 32,
          tileHeight: 32,
          displayScale: 1,
        ),
        maps: <MapData>[
          _connectionTwoStepEastSourceMap(),
          _targetMap(id: 'connection_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source_two_step',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _runSingleMove(game, RuntimeInputControl.right);
      expect(game.gameStateSnapshot.currentMapId, 'connection_source_two_step');
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      final continuity = await _captureConnectionTileContinuitySample(
        game,
        sourceMapId: 'connection_source_two_step',
        targetMapId: 'connection_target',
        sourceSeamCell: const GridPos(x: 1, y: 0),
        targetEntryStartCell: const GridPos(x: -1, y: 0),
        postSwapFirstFrameDt: 0.080,
      );

      expect(continuity.sourcePlayerScreenTopLeft, isNotNull);
      expect(continuity.targetPlayerScreenTopLeft, isNotNull);
      expect(continuity.sourceSeamScreenTopLeft, isNotNull);
      expect(continuity.targetSeamScreenTopLeft, isNotNull);

      expect(
        continuity.sourcePlayerScreenTopLeft!.distanceTo(
          continuity.targetPlayerScreenTopLeft!,
        ),
        lessThanOrEqualTo(1.0),
      );
      expect(
        continuity.sourceSeamScreenTopLeft!.distanceTo(
          continuity.targetSeamScreenTopLeft!,
        ),
        lessThanOrEqualTo(1.0),
      );
    });

    test('connection does not camera-snap before visual entry step starts',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_camera_continuity_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionSourceMap(),
          _targetMap(id: 'connection_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_source',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      final continuity = await _captureConnectionContinuitySample(
        game,
        sourceMapId: 'connection_source',
        targetMapId: 'connection_target',
        postSwapFirstFrameDt: 0.080,
      );

      expect(continuity.sourceCameraTopLeft, isNotNull);
      expect(continuity.targetCameraTopLeft, isNotNull);
      expect(
        continuity.sourceCameraTopLeft!.distanceTo(
          continuity.targetCameraTopLeft!,
        ),
        lessThanOrEqualTo(1.0),
      );
    });

    test('warp to already loaded map reuses cached map visuals', () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_warp_cache_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _warpSourceMapWithConnectionToTarget(),
          _targetMap(id: 'warp_target'),
        ],
      );
      final bundleLoadCounts = <String, int>{};
      final tilesetLoadCounts = <String, int>{};
      Future<RuntimeMapBundle> bundleLoader({
        required String projectFilePath,
        required String mapId,
      }) async {
        bundleLoadCounts[mapId] = (bundleLoadCounts[mapId] ?? 0) + 1;
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: mapId,
        );
        return RuntimeMapBundle(
          manifest: bundle.manifest,
          map: bundle.map,
          projectRootDirectory: bundle.projectRootDirectory,
          tilesetAbsolutePathsById: const <String, String>{
            'shared': '/tmp/shared_tileset.png',
          },
        );
      }

      Future<Map<String, RuntimeTilesetImage>> tilesetLoader(
        Map<String, String> absolutePathByTilesetId,
      ) async {
        for (final path in absolutePathByTilesetId.values) {
          tilesetLoadCounts[path] = (tilesetLoadCounts[path] ?? 0) + 1;
        }
        return <String, RuntimeTilesetImage>{
          for (final entry in absolutePathByTilesetId.entries)
            entry.key: RuntimeTilesetImage(
              images: const <ui.Image>[],
              chunks: const <RuntimeTilesetChunk>[],
              width: 0,
              height: 0,
            ),
        };
      }

      final initialBundle = await bundleLoader(
        projectFilePath: projectFilePath,
        mapId: 'warp_source',
      );
      final game = _TestPlayableMapGame(
        bundle: initialBundle,
        projectFilePath: projectFilePath,
        runtimeMapBundleLoader: bundleLoader,
        runtimeTilesetImageLoader: tilesetLoader,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();
      await _pumpUntil(game, () => game.debugIsMapLoaded('warp_target'));

      final bundleLoadsBeforeWarp = Map<String, int>.from(bundleLoadCounts);
      final tilesetLoadsBeforeWarp = Map<String, int>.from(tilesetLoadCounts);

      await _runSingleMove(game, RuntimeInputControl.right);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'warp_target' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping,
      );

      expect(bundleLoadCounts, equals(bundleLoadsBeforeWarp));
      expect(tilesetLoadCounts, equals(tilesetLoadsBeforeWarp));
    });

    test('active map prewarms visible warp target resources after load',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_warp_prewarm_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _warpSourceMap(),
          _targetMap(id: 'warp_target'),
        ],
      );
      final bundleLoadCounts = <String, int>{};
      Future<RuntimeMapBundle> bundleLoader({
        required String projectFilePath,
        required String mapId,
      }) async {
        bundleLoadCounts[mapId] = (bundleLoadCounts[mapId] ?? 0) + 1;
        return loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: mapId,
        );
      }

      final initialBundle = await bundleLoader(
        projectFilePath: projectFilePath,
        mapId: 'warp_source',
      );
      final game = _TestPlayableMapGame(
        bundle: initialBundle,
        projectFilePath: projectFilePath,
        runtimeMapBundleLoader: bundleLoader,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _pumpUntil(
        game,
        () => (bundleLoadCounts['warp_target'] ?? 0) >= 1,
        maxTicks: 120,
      );

      expect(bundleLoadCounts['warp_target'], 1);
    });

    test(
        'active map prewarms battle data for likely local combatants after load',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_battle_prewarm_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[_battleWarmMap()],
        encounterTables: const <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'field_grass',
            name: 'Field Grass',
            encounterKind: EncounterKind.walk,
            entries: <ProjectEncounterEntry>[
              ProjectEncounterEntry(
                speciesId: 'sparkitten',
                minLevel: 6,
                maxLevel: 6,
              ),
            ],
          ),
        ],
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_1',
            name: 'Trainer One',
            trainerClass: 'Pokémon Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 7,
                moves: <String>['tackle'],
              ),
            ],
          ),
        ],
      );
      await _writeBattleRuntimePokemonData(root);

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'battle_warm_map',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: _battleReadySaveData(mapId: 'battle_warm_map'),
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await _pumpUntil(
        game,
        () =>
            game.debugBattleMoveCatalogReadCount >= 1 &&
            game.debugBattleSpeciesReadCount >= 3 &&
            game.debugBattleLearnsetReadCount >= 3 &&
            game.debugBattleSpriteMediaReadCount >= 3 &&
            game.debugBattleVisualImageLoadCount >= 6 &&
            game.debugBattleVisualOpaqueRectComputeCount >= 6,
        maxTicks: 360,
      );

      expect(game.debugBattleMoveCatalogReadCount, 1);
      expect(game.debugBattleSpeciesReadCount, 3);
      expect(game.debugBattleLearnsetReadCount, 3);
      expect(game.debugBattleSpriteMediaReadCount, 3);
      expect(game.debugBattleVisualImageLoadCount, 6);
      expect(game.debugBattleVisualOpaqueRectComputeCount, 6);
    });

    test(
        'battle handoff second run reuses cached battle data and visual assets',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_battle_handoff_cache_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[_battleWarmMap()],
        encounterTables: const <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'field_grass',
            name: 'Field Grass',
            encounterKind: EncounterKind.walk,
            entries: <ProjectEncounterEntry>[
              ProjectEncounterEntry(
                speciesId: 'sparkitten',
                minLevel: 6,
                maxLevel: 6,
              ),
            ],
          ),
        ],
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_1',
            name: 'Trainer One',
            trainerClass: 'Pokémon Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 7,
                moves: <String>['tackle'],
              ),
            ],
          ),
        ],
      );
      await _writeBattleRuntimePokemonData(root);

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'battle_warm_map',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: _battleReadySaveData(mapId: 'battle_warm_map'),
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();
      await _pumpUntil(
        game,
        () =>
            game.debugBattleMoveCatalogReadCount >= 1 &&
            game.debugBattleSpeciesReadCount >= 3 &&
            game.debugBattleLearnsetReadCount >= 3 &&
            game.debugBattleSpriteMediaReadCount >= 3 &&
            game.debugBattleVisualImageLoadCount >= 6 &&
            game.debugBattleVisualOpaqueRectComputeCount >= 6,
        maxTicks: 360,
      );

      final request = _battleWarmWildRequest();

      await game.debugOpenBattleForTest(request);
      await _pumpUntil(game, () => game.debugBattleOverlayMounted);
      await game.debugWaitForBattleOverlaySync();

      final moveReadsAfterFirstBattle = game.debugBattleMoveCatalogReadCount;
      final speciesReadsAfterFirstBattle = game.debugBattleSpeciesReadCount;
      final learnsetReadsAfterFirstBattle = game.debugBattleLearnsetReadCount;
      final mediaReadsAfterFirstBattle = game.debugBattleSpriteMediaReadCount;
      final imageLoadsAfterFirstBattle = game.debugBattleVisualImageLoadCount;
      final opaqueLoadsAfterFirstBattle =
          game.debugBattleVisualOpaqueRectComputeCount;

      game.debugResetBattleForTest();

      await game.debugOpenBattleForTest(request);
      await _pumpUntil(game, () => game.debugBattleOverlayMounted);
      await game.debugWaitForBattleOverlaySync();

      expect(game.debugBattleMoveCatalogReadCount, moveReadsAfterFirstBattle);
      expect(game.debugBattleSpeciesReadCount, speciesReadsAfterFirstBattle);
      expect(game.debugBattleLearnsetReadCount, learnsetReadsAfterFirstBattle);
      expect(game.debugBattleSpriteMediaReadCount, mediaReadsAfterFirstBattle);
      expect(game.debugBattleVisualImageLoadCount, imageLoadsAfterFirstBattle);
      expect(
        game.debugBattleVisualOpaqueRectComputeCount,
        opaqueLoadsAfterFirstBattle,
      );
    });

    test(
        'battle command overlay listenable exposes a mobile snapshot and selection seams',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_battle_command_overlay_snapshot_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[_battleWarmMap()],
        encounterTables: const <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'field_grass',
            name: 'Field Grass',
            encounterKind: EncounterKind.walk,
            entries: <ProjectEncounterEntry>[
              ProjectEncounterEntry(
                speciesId: 'sparkitten',
                minLevel: 6,
                maxLevel: 6,
              ),
            ],
          ),
        ],
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_1',
            name: 'Trainer One',
            trainerClass: 'Pokémon Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 7,
                moves: <String>['tackle'],
              ),
            ],
          ),
        ],
      );
      await _writeBattleRuntimePokemonData(root);

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'battle_warm_map',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: _battleReadySaveData(mapId: 'battle_warm_map'),
      );

      game.setBattleFlutterCommandOverlayPreferred(true);
      game.onGameResize(_testViewportSize);
      await game.onLoad();

      await game.debugOpenBattleForTest(_battleWarmWildRequest());
      await _pumpUntil(game, () => game.debugBattleOverlayMounted);
      await _pumpUntil(
        game,
        () => game.battleCommandOverlayListenable.value != null,
      );

      final rootSnapshot = game.battleCommandOverlayListenable.value!;
      expect(rootSnapshot.mode, BattleCommandOverlayMode.root);

      expect(game.selectBattleRootEntry(0), isTrue);
      await _pumpUntil(
        game,
        () =>
            game.battleCommandOverlayListenable.value?.mode ==
            BattleCommandOverlayMode.fight,
      );

      final fightSnapshot = game.battleCommandOverlayListenable.value!;
      expect(fightSnapshot.entries, isNotEmpty);
    });

    testWidgets(
        'battle command overlay listenable defers build-time resize notifications',
        (tester) async {
      BattleCommandOverlaySnapshot snapshotForSize(Size viewportSize) {
        final layout =
            BattleSceneLayout.forViewport(viewportSize: viewportSize);
        return BattleCommandOverlaySnapshot(
          mode: BattleCommandOverlayMode.root,
          panelRect: layout.commandPanelRect,
          enemyHud: BattleCommandOverlayHudSnapshot(
            rect: layout.enemyHudRect,
            ownerLabel: 'ENNEMI',
            speciesLabel: 'charmander',
            level: 12,
            currentHp: 34,
            maxHp: 34,
            isPlayerSide: false,
          ),
          playerHud: BattleCommandOverlayHudSnapshot(
            rect: layout.playerHudRect,
            ownerLabel: 'JOUEUR',
            speciesLabel: 'squirtle',
            level: 25,
            currentHp: 57,
            maxHp: 57,
            isPlayerSide: true,
          ),
          battleLabel: 'COMBAT SAUVAGE',
          title: 'COMMANDS',
          prompt: 'Que doit faire le joueur ?',
          narrationLines: const <String>[],
          entries: const <BattleCommandOverlayEntry>[
            BattleCommandOverlayEntry(
              index: 0,
              kind: BattleCommandOverlayEntryKind.root,
              primaryLabel: 'FIGHT',
              secondaryLabel: 'Attaquer',
              enabled: true,
              selected: true,
              tone: BattleCommandOverlayEntryTone.attack,
            ),
            BattleCommandOverlayEntry(
              index: 1,
              kind: BattleCommandOverlayEntryKind.root,
              primaryLabel: 'BAG',
              secondaryLabel: 'Objets',
              enabled: true,
              selected: false,
              tone: BattleCommandOverlayEntryTone.medicine,
            ),
            BattleCommandOverlayEntry(
              index: 2,
              kind: BattleCommandOverlayEntryKind.root,
              primaryLabel: 'POKEMON',
              secondaryLabel: 'Équipe',
              enabled: true,
              selected: false,
              tone: BattleCommandOverlayEntryTone.switching,
            ),
            BattleCommandOverlayEntry(
              index: 3,
              kind: BattleCommandOverlayEntryKind.root,
              primaryLabel: 'RUN',
              secondaryLabel: 'Fuir',
              enabled: true,
              selected: false,
              tone: BattleCommandOverlayEntryTone.neutral,
            ),
          ],
          interactionsEnabled: true,
          canGoBack: false,
        );
      }

      final game = _TestPlayableMapGame(
        bundle: _baseBundle(),
        projectFilePath: '/tmp/project.json',
      );
      final initialSnapshot = snapshotForSize(const Size(640, 480));
      game.debugPublishBattleCommandOverlaySnapshotForTest(initialSnapshot);
      Size? publishedSize;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LayoutBuilder(
            builder: (context, constraints) {
              publishedSize = Size(constraints.maxWidth, constraints.maxHeight);
              game.debugPublishBattleCommandOverlaySnapshotForTest(
                snapshotForSize(publishedSize!),
              );
              return ValueListenableBuilder<BattleCommandOverlaySnapshot?>(
                valueListenable: game.battleCommandOverlayListenable,
                builder: (context, snapshot, child) {
                  return Text(snapshot?.title ?? 'Aucune chrome battle');
                },
              );
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);

      final updatedSnapshot = game.battleCommandOverlayListenable.value!;
      expect(publishedSize, isNotNull);
      final publishedSnapshot = snapshotForSize(publishedSize!);
      expect(updatedSnapshot.panelRect, equals(publishedSnapshot.panelRect));
      expect(
        updatedSnapshot.enemyHud.rect,
        equals(publishedSnapshot.enemyHud.rect),
      );
      expect(
        updatedSnapshot.playerHud.rect,
        equals(publishedSnapshot.playerHud.rect),
      );
      expect(updatedSnapshot.panelRect, isNot(initialSnapshot.panelRect));
      expect(
        updatedSnapshot.panelRect.height,
        greaterThan(initialSnapshot.panelRect.height),
      );
    });

    test(
        'connection transition rebases a preloaded target map before the entry step',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_connection_rebase_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: <MapData>[
          _connectionHubMap(),
          _connectionSouthSourceMap(),
          _targetMap(id: 'shared_target'),
        ],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'connection_hub',
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(_testViewportSize);
      await game.onLoad();
      await _pumpUntil(
        game,
        () =>
            game.debugIsMapLoaded('shared_target') &&
            game.debugIsMapLoaded('connection_source_south'),
      );

      await _runSingleMove(game, RuntimeInputControl.down);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'connection_source_south' &&
            game.debugFlowPhaseName == 'overworld' &&
            !game.debugIsPlayerStepping,
      );

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      game.update(0.016);
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      final firstTopLeftAfterSwap = await _captureFirstTopLeftOnMap(
        game,
        targetMapId: 'shared_target',
      );

      expect(firstTopLeftAfterSwap, isNotNull);
      expect(
        firstTopLeftAfterSwap,
        game.debugWorldTopLeftForSpawnCell(const GridPos(x: -1, y: 0)),
      );
    });
  });
}

class _RecordingPlayableMapGame extends PlayableMapGame {
  _RecordingPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
  });

  final List<RuntimeInputEvent> recordedEvents = <RuntimeInputEvent>[];

  @override
  bool handleRuntimeInputEvent(RuntimeInputEvent event) {
    recordedEvents.add(event);
    return true;
  }
}

class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.dialogueSessionLoader,
    super.runtimeMapBundleLoader,
    super.runtimeTilesetImageLoader,
  });

  @override
  bool get isLoaded => true;
}

RuntimeMapBundle _baseBundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Test Project',
      maps: [
        ProjectMapEntry(
          id: 'test_map',
          name: 'Test Map',
          relativePath: 'maps/test_map.json',
        ),
      ],
      tilesets: [],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'test_map',
      name: 'Test Map',
      size: GridSize(width: 8, height: 8),
      layers: [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: '/tmp/project',
    tilesetAbsolutePathsById: const {},
  );
}

DialogueSession _singleLineDialogueSession(String text) {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[
          YarnStepLine(text),
        ],
      ),
    ],
    'Start',
  )!;
}

final _testViewportSize = Vector2(640, 480);

Future<void> _runSingleMove(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  await _pumpUntil(
    game,
    () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
  );
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the runtime game to settle.');
}

Future<Vector2?> _captureFirstTopLeftOnMap(
  PlayableMapGame game, {
  required String targetMapId,
  int maxTicks = 240,
}) async {
  if (game.gameStateSnapshot.currentMapId == targetMapId) {
    return game.debugPlayerWorldTopLeft.clone();
  }
  for (var i = 0; i < maxTicks; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    if (game.gameStateSnapshot.currentMapId == targetMapId) {
      return game.debugPlayerWorldTopLeft.clone();
    }
  }
  return null;
}

Future<_ConnectionContinuitySample> _captureConnectionContinuitySample(
  PlayableMapGame game, {
  required String sourceMapId,
  required String targetMapId,
  required double postSwapFirstFrameDt,
  int maxTicks = 240,
}) async {
  Vector2? sourceScreenTopLeft;
  Vector2? sourceCameraTopLeft;
  Vector2? targetScreenTopLeft;
  Vector2? targetCameraTopLeft;
  var hasSeenTargetMap = false;

  for (var i = 0; i < maxTicks; i++) {
    if (game.gameStateSnapshot.currentMapId == sourceMapId) {
      sourceScreenTopLeft = game.debugPlayerScreenTopLeft.clone();
      sourceCameraTopLeft = game.debugCameraWorldTopLeft.clone();
    }
    final dt = hasSeenTargetMap ? 0.016 : postSwapFirstFrameDt;
    game.update(dt);
    await Future<void>.delayed(Duration.zero);
    if (game.gameStateSnapshot.currentMapId == targetMapId) {
      hasSeenTargetMap = true;
      targetScreenTopLeft ??= game.debugPlayerScreenTopLeft.clone();
      targetCameraTopLeft ??= game.debugCameraWorldTopLeft.clone();
      break;
    }
  }

  return _ConnectionContinuitySample(
    sourceScreenTopLeft: sourceScreenTopLeft,
    sourceCameraTopLeft: sourceCameraTopLeft,
    targetScreenTopLeft: targetScreenTopLeft,
    targetCameraTopLeft: targetCameraTopLeft,
  );
}

Future<_ConnectionTileContinuitySample> _captureConnectionTileContinuitySample(
  PlayableMapGame game, {
  required String sourceMapId,
  required String targetMapId,
  required GridPos sourceSeamCell,
  required GridPos targetEntryStartCell,
  required double postSwapFirstFrameDt,
  int maxTicks = 240,
}) async {
  Vector2? sourcePlayerScreenTopLeft;
  Vector2? targetPlayerScreenTopLeft;
  Vector2? sourceSeamScreenTopLeft;
  Vector2? targetSeamScreenTopLeft;
  var hasSeenTargetMap = false;

  for (var i = 0; i < maxTicks; i++) {
    if (game.gameStateSnapshot.currentMapId == sourceMapId) {
      sourcePlayerScreenTopLeft = game.debugPlayerScreenTopLeft.clone();
      sourceSeamScreenTopLeft = game.debugWorldToScreen(
        game.debugMapCellWorldTopLeft(sourceSeamCell),
      );
    }
    final dt = hasSeenTargetMap ? 0.016 : postSwapFirstFrameDt;
    game.update(dt);
    await Future<void>.delayed(Duration.zero);
    if (game.gameStateSnapshot.currentMapId == targetMapId) {
      hasSeenTargetMap = true;
      targetPlayerScreenTopLeft ??= game.debugPlayerScreenTopLeft.clone();
      targetSeamScreenTopLeft ??= game.debugWorldToScreen(
        game.debugMapCellWorldTopLeft(targetEntryStartCell),
      );
      break;
    }
  }

  return _ConnectionTileContinuitySample(
    sourcePlayerScreenTopLeft: sourcePlayerScreenTopLeft,
    targetPlayerScreenTopLeft: targetPlayerScreenTopLeft,
    sourceSeamScreenTopLeft: sourceSeamScreenTopLeft,
    targetSeamScreenTopLeft: targetSeamScreenTopLeft,
  );
}

class _ConnectionContinuitySample {
  const _ConnectionContinuitySample({
    required this.sourceScreenTopLeft,
    required this.sourceCameraTopLeft,
    required this.targetScreenTopLeft,
    required this.targetCameraTopLeft,
  });

  final Vector2? sourceScreenTopLeft;
  final Vector2? sourceCameraTopLeft;
  final Vector2? targetScreenTopLeft;
  final Vector2? targetCameraTopLeft;
}

class _ConnectionTileContinuitySample {
  const _ConnectionTileContinuitySample({
    required this.sourcePlayerScreenTopLeft,
    required this.targetPlayerScreenTopLeft,
    required this.sourceSeamScreenTopLeft,
    required this.targetSeamScreenTopLeft,
  });

  final Vector2? sourcePlayerScreenTopLeft;
  final Vector2? targetPlayerScreenTopLeft;
  final Vector2? sourceSeamScreenTopLeft;
  final Vector2? targetSeamScreenTopLeft;
}

Future<String> _writeRuntimeProject(
  Directory root, {
  ProjectSettings settings = const ProjectSettings(
    tileWidth: 16,
    tileHeight: 16,
  ),
  required List<MapData> maps,
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[],
  List<ProjectEncounterTable> encounterTables = const <ProjectEncounterTable>[],
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
  List<ProjectScriptEntry> scripts = const <ProjectScriptEntry>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<ProjectCharacterEntry> characters = const <ProjectCharacterEntry>[],
  ProjectPokemonConfig pokemonConfig = const ProjectPokemonConfig(),
}) async {
  final manifest = ProjectManifest(
    name: 'Runtime Movement Regression',
    settings: settings,
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: tilesets,
    encounterTables: encounterTables,
    trainers: trainers,
    scripts: scripts,
    dialogues: dialogues,
    characters: characters,
    pokemon: pokemonConfig,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
  final mapsDir = Directory(p.join(root.path, 'maps'));
  await mapsDir.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDir.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  for (final tileset in tilesets) {
    await _writeProjectRelativeBytes(
      root,
      tileset.relativePath,
      base64Decode(_tinyBattleSpritePngBase64),
    );
  }
  return projectFile.path;
}

MapData _npcDialogueMap() {
  return const MapData(
    id: 'npc_dialogue_map',
    name: 'NPC Dialogue Map',
    size: GridSize(width: 3, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_npc_dialogue',
        name: 'Spawn NPC Dialogue',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'npc_professor',
        name: 'Professor Oak',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 0),
        npc: MapEntityNpcData(
          displayName: 'Professor Oak',
          dialogue: DialogueRef(dialogueId: 'intro'),
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_npc_dialogue'),
  );
}

MapData _eventScriptDialogueMap() {
  return const MapData(
    id: 'event_script_dialogue_map',
    name: 'Event Script Dialogue Map',
    size: GridSize(width: 3, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_event_dialogue',
        name: 'Spawn Event Dialogue',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    events: <MapEventDefinition>[
      MapEventDefinition(
        id: 'intro_event',
        title: 'Intro Event',
        position: EventPosition(layerId: 'objects', x: 1, y: 0),
        pages: <MapEventPage>[
          MapEventPage(
            pageNumber: 0,
            script: ScriptRef(scriptId: 'intro_script', startNode: 'start'),
          ),
        ],
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_event_dialogue'),
  );
}

MapData _followLeaderMap32() {
  return const MapData(
    id: 'follow_leader_map_32',
    name: 'Follow Leader Map 32',
    size: GridSize(width: 10, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_follow_leader',
        name: 'Spawn Follow Leader',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'emma',
        name: 'Emma',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 1),
        npc: MapEntityNpcData(
          displayName: 'Emma',
          characterId: 'emma_char',
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_follow_leader'),
  );
}

MapData _followLeaderWarpSourceMap32() {
  return const MapData(
    id: 'follow_warp_source_map_32',
    name: 'Follow Warp Source Map 32',
    size: GridSize(width: 8, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    warps: <MapWarp>[
      MapWarp(
        id: 'to_lab',
        pos: GridPos(x: 4, y: 1),
        targetMapId: 'follow_warp_target_map_32',
        targetPos: GridPos(x: 1, y: 1),
      ),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_follow_warp_source',
        name: 'Spawn Follow Warp Source',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'emma',
        name: 'Emma',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 1),
        npc: MapEntityNpcData(
          displayName: 'Emma',
          characterId: 'emma_char',
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_follow_warp_source'),
  );
}

const List<ProjectCharacterEntry> _followScenarioCharacters =
    <ProjectCharacterEntry>[
  ProjectCharacterEntry(
    id: 'emma_char',
    name: 'Emma Character',
    tilesetId: 'npc-emma',
    frameWidth: 2,
    frameHeight: 2,
  ),
];

const List<ProjectTilesetEntry> _followScenarioTilesets = <ProjectTilesetEntry>[
  ProjectTilesetEntry(
    id: 'npc-emma',
    name: 'NPC Emma',
    relativePath: 'tilesets/npc-emma.png',
  ),
];

MapData _followLeaderWarpTargetMap32() {
  return const MapData(
    id: 'follow_warp_target_map_32',
    name: 'Follow Warp Target Map 32',
    size: GridSize(width: 6, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_follow_warp_target',
        name: 'Spawn Follow Warp Target',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_follow_warp_target'),
  );
}

MapData _blockingNpcMap() {
  return const MapData(
    id: 'blocking_npc_map',
    name: 'Blocking NPC Map',
    size: GridSize(width: 4, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_blocking_npc',
        name: 'Spawn Blocking NPC',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'npc_blocker',
        name: 'Blocker',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(
          displayName: 'Blocker',
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_blocking_npc'),
  );
}

Future<void> _writeBattleRuntimePokemonData(Directory root) async {
  await _writeProjectRelativeJson(
    root,
    'data/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'entries': <Map<String, dynamic>>[
        _runtimeMoveJson(
          id: 'tackle',
          name: 'Tackle',
          type: 'normal',
          category: PokemonMoveCategory.physical,
          basePower: 40,
        ),
      ],
    },
  );

  await _writeProjectRelativeJson(
    root,
    'data/pokemon/species/sproutle.json',
    _runtimeSpeciesJson(
      id: 'sproutle',
      type: 'grass',
      abilityId: 'overgrow',
    ),
  );
  await _writeProjectRelativeJson(
    root,
    'data/pokemon/species/sparkitten.json',
    _runtimeSpeciesJson(
      id: 'sparkitten',
      type: 'fire',
      abilityId: 'blaze',
    ),
  );
  await _writeProjectRelativeJson(
    root,
    'data/pokemon/species/aquafi.json',
    _runtimeSpeciesJson(
      id: 'aquafi',
      type: 'water',
      abilityId: 'torrent',
    ),
  );

  await _writeProjectRelativeJson(
    root,
    'data/pokemon/learnsets/sproutle.json',
    _runtimeLearnsetJson(),
  );
  await _writeProjectRelativeJson(
    root,
    'data/pokemon/learnsets/sparkitten.json',
    _runtimeLearnsetJson(),
  );
  await _writeProjectRelativeJson(
    root,
    'data/pokemon/learnsets/aquafi.json',
    _runtimeLearnsetJson(),
  );

  await _writeBattleMediaSet(root, speciesId: 'sproutle');
  await _writeBattleMediaSet(root, speciesId: 'sparkitten');
  await _writeBattleMediaSet(root, speciesId: 'aquafi');
}

Future<void> _writeBattleMediaSet(
  Directory root, {
  required String speciesId,
}) async {
  final frontRelativePath = 'data/pokemon/media/$speciesId-front.png';
  final backRelativePath = 'data/pokemon/media/$speciesId-back.png';
  await _writeProjectRelativeBytes(
    root,
    frontRelativePath,
    base64Decode(_tinyBattleSpritePngBase64),
  );
  await _writeProjectRelativeBytes(
    root,
    backRelativePath,
    base64Decode(_tinyBattleSpritePngBase64),
  );
  await _writeProjectRelativeJson(
    root,
    'data/pokemon/media/$speciesId.json',
    <String, dynamic>{
      'defaultFormId': 'base',
      'variants': <String, dynamic>{
        'base': <String, dynamic>{
          'frontStatic': frontRelativePath,
          'backStatic': backRelativePath,
        },
      },
    },
  );
}

Future<void> _writeProjectRelativeJson(
  Directory root,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(root.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(json),
  );
}

Future<void> _writeProjectRelativeBytes(
  Directory root,
  String relativePath,
  List<int> bytes,
) async {
  final file = File(p.join(root.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}

Map<String, dynamic> _runtimeMoveJson({
  required String id,
  required String name,
  required String type,
  required PokemonMoveCategory category,
  required int basePower,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'type': type,
    'category': category.name,
    'basePower': basePower,
    'accuracy': <String, dynamic>{
      'kind': 'percent',
      'value': 100,
    },
    'pp': 35,
    'target': 'normal',
    'priority': 0,
    'engineSupportLevel': 'structured_supported',
    'effects': const <Map<String, dynamic>>[],
    'unsupportedReasons': const <String>[],
  };
}

Map<String, dynamic> _runtimeSpeciesJson({
  required String id,
  required String type,
  required String abilityId,
}) {
  return <String, dynamic>{
    'id': id,
    'typing': <String, dynamic>{
      'types': <String>[type],
    },
    'baseStats': <String, dynamic>{
      'hp': 45,
      'atk': 49,
      'def': 49,
      'spa': 65,
      'spd': 65,
      'spe': 45,
    },
    'abilities': <String, dynamic>{
      'primary': abilityId,
    },
    'refs': <String, dynamic>{
      'learnset': id,
    },
  };
}

Map<String, dynamic> _runtimeLearnsetJson() {
  return <String, dynamic>{
    'startingMoves': const <String>['tackle'],
    'relearnMoves': const <String>[],
    'levelUp': const <Map<String, dynamic>>[],
  };
}

SaveData _battleReadySaveData({
  required String mapId,
}) {
  return SaveData(
    saveId: 'battle-warm-save',
    currentMapId: mapId,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 7,
          knownMoveIds: <String>['tackle'],
          currentHp: 18,
        ),
      ],
    ),
    bag: const Bag(
      entries: <BagEntry>[
        BagEntry(
          itemId: 'poke-ball',
          categoryId: 'items',
          quantity: 3,
        ),
      ],
    ),
    trainerProfile: const TrainerProfile(name: 'Runtime'),
  );
}

WildBattleStartRequest _battleWarmWildRequest() {
  return const WildBattleStartRequest(
    requestId: 'battle-warm-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'battle_warm_map',
      playerPos: GridPos(x: 0, y: 0),
      playerFacing: Direction.east,
    ),
    mapId: 'battle_warm_map',
    zoneId: 'encounter_grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'sparkitten',
    level: 6,
    minLevel: 6,
    maxLevel: 6,
    weight: 1,
    playerPos: GridPos(x: 0, y: 0),
  );
}

MapData _battleWarmMap() {
  return const MapData(
    id: 'battle_warm_map',
    name: 'Battle Warm Map',
    size: GridSize(width: 2, height: 1),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_battle_warm',
        name: 'Spawn Battle Warm',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'trainer_battle_warm',
        name: 'Trainer Battle Warm',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 0),
        npc: MapEntityNpcData(
          displayName: 'Trainer One',
          trainerId: 'trainer_1',
        ),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      MapGameplayZone(
        id: 'encounter_grass',
        name: 'Encounter Grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'field_grass',
          encounterKind: EncounterKind.walk,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_battle_warm'),
  );
}

const _tinyBattleSpritePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFUlEQVR4nGOMmnbnPwMDAwMTiABhACpmAs+3EdpKAAAAAElFTkSuQmCC';

MapData _singleStepMap() {
  return const MapData(
    id: 'step_map',
    name: 'Step Map',
    size: GridSize(width: 3, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_step',
        name: 'Spawn Step',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_step'),
  );
}

MapData _wideStepMap() {
  return const MapData(
    id: 'wide_step_map',
    name: 'Wide Step Map',
    size: GridSize(width: 6, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_wide_step',
        name: 'Spawn Wide Step',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_wide_step'),
  );
}

MapData _encounterStepMap() {
  return const MapData(
    id: 'encounter_step_map',
    name: 'Encounter Step Map',
    size: GridSize(width: 4, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    gameplayZones: <MapGameplayZone>[
      MapGameplayZone(
        id: 'encounter_grass',
        name: 'Encounter Grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 4, height: 1),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'field_grass',
          encounterKind: EncounterKind.walk,
        ),
      ),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_encounter_step',
        name: 'Spawn Encounter Step',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_encounter_step'),
  );
}

MapData _warpSourceMap() {
  return const MapData(
    id: 'warp_source',
    name: 'Warp Source',
    size: GridSize(width: 3, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_warp_source',
        name: 'Spawn Warp Source',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    warps: <MapWarp>[
      MapWarp(
        id: 'warp_to_target',
        pos: GridPos(x: 1, y: 0),
        targetMapId: 'warp_target',
        targetPos: GridPos(x: 1, y: 1),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_warp_source'),
  );
}

MapData _connectionSourceMap() {
  return const MapData(
    id: 'connection_source',
    name: 'Connection Source',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_source',
        name: 'Spawn Connection Source',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'connection_target',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_source'),
  );
}

MapData _connectionTwoStepEastSourceMap() {
  return const MapData(
    id: 'connection_source_two_step',
    name: 'Connection Source Two Step',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_two_step',
        name: 'Spawn Connection Two Step',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'connection_target',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_two_step'),
  );
}

MapData _connectionWestSourceMap() {
  return const MapData(
    id: 'connection_source_west',
    name: 'Connection Source West',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_source_west',
        name: 'Spawn Connection Source West',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.west,
        ),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'connection_target_west',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_source_west'),
  );
}

MapData _connectionHubMap() {
  return const MapData(
    id: 'connection_hub',
    name: 'Connection Hub',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_hub',
        name: 'Spawn Connection Hub',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'shared_target',
        offset: 0,
      ),
      MapConnection(
        direction: MapConnectionDirection.south,
        targetMapId: 'connection_source_south',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_hub'),
  );
}

MapData _connectionSouthSourceMap() {
  return const MapData(
    id: 'connection_source_south',
    name: 'Connection Source South',
    size: GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_source_south',
        name: 'Spawn Connection Source South',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'shared_target',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_source_south'),
  );
}

MapData _connectionTargetWestMap() {
  return const MapData(
    id: 'connection_target_west',
    name: 'Connection Target West',
    size: GridSize(width: 3, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_connection_target_west',
        name: 'Spawn Connection Target West',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.west,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_target_west'),
  );
}

MapData _targetMap({
  required String id,
}) {
  return MapData(
    id: id,
    name: 'Target Map',
    size: const GridSize(width: 3, height: 2),
    layers: const <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: const <MapEntity>[
      MapEntity(
        id: 'spawn_target',
        name: 'Spawn Target',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_target'),
  );
}

MapData _warpSourceMapWithConnectionToTarget() {
  return const MapData(
    id: 'warp_source',
    name: 'Warp Source',
    size: GridSize(width: 3, height: 2),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_warp_source',
        name: 'Spawn Warp Source',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    warps: <MapWarp>[
      MapWarp(
        id: 'warp_to_target',
        pos: GridPos(x: 1, y: 0),
        targetMapId: 'warp_target',
        targetPos: GridPos(x: 1, y: 1),
      ),
    ],
    connections: <MapConnection>[
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'warp_target',
        offset: 0,
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_warp_source'),
  );
}
