import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/warp_transition_overlay_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Player owns one presentation through transfer and reveal', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester);
      var done = false;
      final execution = game
          .debugExecuteSceneInteractiveCommand(_command())
          .whenComplete(() => done = true);
      await _until(game, () => _overlay(game) != null);
      final overlay = _overlay(game)!;
      expect(game.gameStateSnapshot.currentMapId, 'source');
      expect(game.debugFlowPhaseName, 'mapTransition');
      expect(game.debugIsGameplayInputLocked, isTrue);
      final position = game.debugPlayerGridPosition;
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      expect(game.debugPlayerGridPosition, position);
      final opacityBefore = overlay.controller.frame.worldOpacity;
      game.update(.2);
      await _flush();
      expect(game.gameStateSnapshot.currentMapId, 'source');
      expect(
        overlay.controller.frame.worldOpacity,
        closeTo(opacityBefore + 2 / 3, .01),
      );
      await _until(
        game,
        () =>
            overlay.controller.phase ==
            RuntimeWarpPresentationPhase.afterTransfer,
      );
      expect(game.gameStateSnapshot.currentMapId, 'target');
      expect(_overlay(game), same(overlay));
      expect(done, isFalse);
      expect(game.debugIsGameplayInputLocked, isTrue);
      expect(
        game.camera.viewport.children
            .whereType<WarpTransitionOverlayComponent>()
            .length,
        1,
      );
      await _until(game, () => done);
      expect(await execution, 'completed');
      expect(_overlay(game), isNull);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(game.debugLastCompletedMapActivation?.mapId, 'target');
    });
  });

  testWidgets('Player cancels before transfer without replacing the map', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester);
      final before = game.gameStateSnapshot;
      var done = false;
      final execution = game
          .debugExecuteSceneInteractiveCommand(_command())
          .whenComplete(() => done = true);
      await _until(game, () => _overlay(game) != null);
      _overlay(game)!.close();
      await _until(game, () => done);
      expect(await execution, 'blocked');
      expect(game.gameStateSnapshot.toJson(), before.toJson());
      expect(_overlay(game), isNull);
      expect(game.debugIsGameplayInputLocked, isFalse);
    });
  });

  testWidgets('Player cancellation after swap restores the source checkpoint', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester);
      final before = game.gameStateSnapshot;
      final activations = game.debugCompletedMapActivationDispatchCount;
      var done = false;
      final execution = game
          .debugExecuteSceneInteractiveCommand(_command())
          .whenComplete(() => done = true);
      await _until(
        game,
        () =>
            _overlay(game)?.controller.phase ==
            RuntimeWarpPresentationPhase.afterTransfer,
      );
      expect(game.gameStateSnapshot.currentMapId, 'target');
      _overlay(game)!.close();
      for (var i = 0; i < 20 && !done; i++) {
        await Future<void>.value();
        if (!done && !game.debugIsMapLoaded('source')) {
          expect(
            game.debugIsGameplayInputLocked,
            isTrue,
            reason: 'Rollback must retain the presentation lock until the source is remounted.',
          );
        }
      }
      await _until(game, () => done);
      expect(await execution, 'blocked');
      expect(game.gameStateSnapshot.toJson(), before.toJson());
      expect(game.debugCompletedMapActivationDispatchCount, activations);
      expect(game.debugIsGameplayInputLocked, isFalse);
    });
  });

  testWidgets('Player illustrated presentation uses the real authored atlas', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester, illustrated: true);
      var done = false;
      final execution = game
          .debugExecuteSceneInteractiveCommand(_command(illustrated: true))
          .whenComplete(() => done = true);
      await _until(
        game,
        () =>
            _overlay(game)?.controller.phase ==
            RuntimeWarpPresentationPhase.afterTransfer,
      );
      final overlay = _overlay(game)!;
      expect(overlay.controller.frame.illustrationOpacity, 1);
      final recorder = ui.PictureRecorder();
      overlay.renderer.render(
        ui.Canvas(recorder),
        const ui.Size(4, 3),
        overlay.controller.frame,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(4, 3);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      expect(
        [for (var i = 0; i < 4; i++) pixels.getUint8(i)],
        [0, 0, 255, 255],
      );
      image.dispose();
      picture.dispose();
      game.update(.5);
      await _flush();
      expect(done, isFalse);
      expect(game.debugIsGameplayInputLocked, isTrue);
      await _until(game, () => done);
      expect(await execution, 'completed');
      expect(_overlay(game), isNull);
    });
  });

  for (final removeRuntime in [false, true]) {
    testWidgets(
      'Player ${removeRuntime ? 'disposal' : 'cancellation'} waits for a pending transfer without a late swap',
      (tester) async {
        await tester.runAsync(() async {
          final gate = Completer<void>();
          final entered = Completer<void>();
          addTearDown(() {
            if (!gate.isCompleted) gate.complete();
          });
          final game = await _mount(
            tester,
            transferGate: gate,
            transferEntered: entered,
          );
          final before = game.gameStateSnapshot;
          final activations = game.debugCompletedMapActivationDispatchCount;
          var done = false;
          final execution = game
              .debugExecuteSceneInteractiveCommand(_command())
              .whenComplete(() => done = true);
          await _until(game, () => entered.isCompleted);
          final overlay = _overlay(game)!;
          expect(
            overlay.controller.phase,
            RuntimeWarpPresentationPhase.transferring,
          );
          if (removeRuntime) {
            game.onRemove();
          } else {
            overlay.close();
          }
          await _flush();
          expect(done, isFalse);
          expect(
            overlay.controller.phase,
            RuntimeWarpPresentationPhase.cancelled,
          );
          expect(game.gameStateSnapshot.currentMapId, 'source');
          gate.complete();
          if (removeRuntime) {
            await execution;
            await _flush();
          } else {
            await _until(game, () => done);
          }
          expect(await execution, 'blocked');
          expect(game.gameStateSnapshot.toJson(), before.toJson());
          expect(game.debugCompletedMapActivationDispatchCount, activations);
          expect(game.debugIsMapLoaded('target'), isFalse);
        });
      },
    );
  }

  testWidgets(
    'Player refuses a second warp and checkpoints throughout the presentation',
    (tester) async {
      await tester.runAsync(() async {
        final game = await _mount(tester);
        var done = false;
        final execution = game
            .debugExecuteSceneInteractiveCommand(_command())
            .whenComplete(() => done = true);
        await _until(game, () => _overlay(game) != null);
        final overlay = _overlay(game)!;
        expect(
          await game.debugExecuteSceneInteractiveCommand(
            SceneInteractiveCommand.warp(
              destinationMapId: 'source',
              warpId: 'arrival',
              transition: SceneWarpTransition.none,
            ),
          ),
          'blocked',
        );
        expect(_overlay(game), same(overlay));
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        await _until(
          game,
          () =>
              overlay.controller.phase ==
              RuntimeWarpPresentationPhase.afterTransfer,
        );
        final activationCount = game.debugCompletedMapActivationDispatchCount;
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        game.update(.15);
        await _flush();
        expect(game.debugCompletedMapActivationDispatchCount, activationCount);
        await _until(game, () => done);
        expect(await execution, 'completed');
        expect(
          game.debugCompletedMapActivationDispatchCount,
          activationCount + 1,
        );
      });
    },
  );

  testWidgets(
    'Player blocks a failed target visual load and restores all state',
    (tester) async {
      await tester.runAsync(() async {
        final entered = Completer<void>();
        final game = await _mount(
          tester,
          failTransfer: true,
          transferEntered: entered,
        );
        final before = game.gameStateSnapshot;
        var done = false;
        final execution = game
            .debugExecuteSceneInteractiveCommand(_command())
            .whenComplete(() => done = true);
        await _until(game, () => done);
        expect(await execution, 'blocked');
        expect(entered.isCompleted, isTrue);
        expect(game.gameStateSnapshot.toJson(), before.toJson());
        expect(game.debugIsMapLoaded('target'), isFalse);
        expect(_overlay(game), isNull);
        expect(game.debugIsGameplayInputLocked, isFalse);
      });
    },
  );

  testWidgets('Player rejects an unregistered illustration before transition', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester);
      final before = game.gameStateSnapshot;
      expect(
        await game.debugExecuteSceneInteractiveCommand(
          _command(illustrated: true),
        ),
        'blocked',
      );
      expect(game.gameStateSnapshot.toJson(), before.toJson());
      expect(_overlay(game), isNull);
      expect(game.debugIsGameplayInputLocked, isFalse);
    });
  });

  testWidgets('Player cave exit waits through its bands before one transfer', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final game = await _mount(tester);
      var done = false;
      final execution = game
          .debugExecuteSceneInteractiveCommand(
            SceneInteractiveCommand.warp(
              destinationMapId: 'target',
              warpId: 'arrival',
              presentation: SceneWarpPresentation(
                mode: SceneWarpPresentationMode.caveExit,
              ),
            ),
          )
          .whenComplete(() => done = true);
      await _until(game, () => _overlay(game) != null);
      final overlay = _overlay(game)!;
      game.update(.8);
      await _flush();
      expect(game.gameStateSnapshot.currentMapId, 'source');
      expect(overlay.controller.frame.caveElapsedMs, greaterThanOrEqualTo(400));
      expect(game.debugIsGameplayInputLocked, isTrue);
      await _until(game, () => done);
      expect(await execution, 'completed');
      expect(game.gameStateSnapshot.currentMapId, 'target');
      expect(_overlay(game), isNull);
    });
  });

  testWidgets(
    'Scene blocked to end commits the restored source after cancellation',
    (tester) async {
      await tester.runAsync(() async {
        final game = await _mount(tester);
        final before = game.gameStateSnapshot;
        var done = false;
        final execution = game
            .debugExecuteNarrativeSceneForTest(
              NarrativeSceneExecutionRequest(
                eventId: 'travel-event',
                sceneId: 'travel',
                executionId: 'cancel-scene',
                gameState: before,
              ),
            )
            .whenComplete(() => done = true);
        await _until(
          game,
          () =>
              _overlay(game)?.controller.phase ==
              RuntimeWarpPresentationPhase.afterTransfer,
        );
        _overlay(game)!.close();
        await _until(game, () => done);
        final result = await execution;
        expect(result, isA<NarrativeSceneExecutionCompleted>());
        expect(
          (result as NarrativeSceneExecutionCompleted).updatedGameState
              .toJson(),
          before.toJson(),
        );
        expect(game.gameStateSnapshot.toJson(), before.toJson());
        expect(game.debugIsGameplayInputLocked, isFalse);
      });
    },
  );

  testWidgets(
    'Scene failure after presentation restores its spatial owner checkpoint',
    (tester) async {
      await tester.runAsync(() async {
        final game = await _mount(tester, failingScene: true);
        final before = game.gameStateSnapshot;
        final activationCount = game.debugCompletedMapActivationDispatchCount;
        var done = false;
        var sawTarget = false;
        final execution = game
            .debugExecuteNarrativeSceneForTest(
              NarrativeSceneExecutionRequest(
                eventId: 'travel-event',
                sceneId: 'travel',
                executionId: 'failing-scene',
                gameState: before,
              ),
            )
            .whenComplete(() => done = true);
        for (var i = 0; i < 400 && !done; i++) {
          game.update(.025);
          sawTarget |= game.gameStateSnapshot.currentMapId == 'target';
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(done, isTrue);
        expect(await execution, isA<NarrativeSceneExecutionFailed>());
        expect(sawTarget, isTrue);
        expect(game.gameStateSnapshot.toJson(), before.toJson());
        expect(game.debugPlayerGridPosition, before.playerPosition);
        expect(game.debugCompletedMapActivationDispatchCount, activationCount);
        expect(game.debugIsGameplayInputLocked, isFalse);
      });
    },
  );

  testWidgets(
    'Scene executes two presentation owners in order without stealing cleanup',
    (tester) async {
      await tester.runAsync(() async {
        final game = await _mount(tester, returnWarp: true);
        final before = game.gameStateSnapshot;
        var done = false;
        var sawTarget = false;
        final owners = <WarpPresentationOverlayComponent>{};
        final execution = game
            .debugExecuteNarrativeSceneForTest(
              NarrativeSceneExecutionRequest(
                eventId: 'travel-event',
                sceneId: 'travel',
                executionId: 'round-trip',
                gameState: before,
              ),
            )
            .whenComplete(() => done = true);
        for (var i = 0; i < 400 && !done; i++) {
          game.update(.025);
          if (_overlay(game) case final overlay?) owners.add(overlay);
          sawTarget |= game.gameStateSnapshot.currentMapId == 'target';
          expect(
            game.camera.viewport.children
                .whereType<WarpPresentationOverlayComponent>()
                .where((overlay) => !overlay.isRemoving)
                .length,
            lessThanOrEqualTo(1),
          );
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        game.update(0);
        expect(done, isTrue);
        expect(await execution, isA<NarrativeSceneExecutionCompleted>());
        expect(sawTarget, isTrue);
        expect(owners.length, 2);
        expect(game.gameStateSnapshot.currentMapId, 'source');
        expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
        expect(_overlay(game), isNull);
        expect(game.debugIsGameplayInputLocked, isFalse);
      });
    },
  );

  testWidgets(
    'Player disposal during destination preparation leaves no late notification',
    (tester) async {
      await tester.runAsync(() async {
        final gate = Completer<void>();
        final entered = Completer<void>();
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });
        final game = await _mount(
          tester,
          preparationGate: gate,
          preparationEntered: entered,
        );
        final before = game.gameStateSnapshot;
        final execution = game.debugExecuteSceneInteractiveCommand(_command());
        await _until(game, () => entered.isCompleted);
        game.onRemove();
        gate.complete();
        expect(await execution, 'blocked');
        expect(game.gameStateSnapshot.toJson(), before.toJson());
        expect(_overlay(game), isNull);
        expect(game.runtimeNotificationListenable.value, isNull);
        expect(game.debugIsMapLoaded('target'), isFalse);
      });
    },
  );
}

SceneInteractiveCommand _command({bool illustrated = false}) =>
    SceneInteractiveCommand.warp(
      destinationMapId: 'target',
      warpId: 'arrival',
      arrivalFacing: EntityFacing.south,
      presentation: SceneWarpPresentation(
        mode: illustrated
            ? SceneWarpPresentationMode.illustrated
            : SceneWarpPresentationMode.fade,
        illustrationElementId: illustrated ? 'picture' : null,
      ),
    );

WarpPresentationOverlayComponent? _overlay(PlayableMapGame game) => game
    .camera
    .viewport
    .children
    .whereType<WarpPresentationOverlayComponent>()
    .firstOrNull;

Future<void> _flush() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _until(PlayableMapGame game, bool Function() condition) async {
  for (var i = 0; i < 400 && !condition(); i++) {
    game.update(.025);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  game.update(0);
  await _flush();
  expect(
    condition(),
    isTrue,
    reason: 'The Player presentation did not reach the expected phase.',
  );
}

Future<PlayableMapGame> _mount(
  WidgetTester tester, {
  bool illustrated = false,
  Completer<void>? transferGate,
  Completer<void>? transferEntered,
  bool failTransfer = false,
  bool failingScene = false,
  bool returnWarp = false,
  Completer<void>? preparationGate,
  Completer<void>? preparationEntered,
}) async {
  final targetImage = transferGate != null || failTransfer;
  final dir = await Directory.systemTemp.createTemp(
    'player-warp-presentation-',
  );
  addTearDown(() => dir.delete(recursive: true));
  final maps = [
    for (final id in ['source', 'target'])
      MapData(
        id: id,
        name: id,
        size: const GridSize(width: 5, height: 5),
        layers: [
          TileLayer(id: 'objects', name: 'Objects', cells: List.filled(25, 0)),
        ],
        entities: const [
          MapEntity(
            id: 'spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            blocksMovement: false,
            spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
          ),
        ],
        placedElements: [
          if (id == 'target' && targetImage)
            const MapPlacedElement(
              id: 'target-art',
              elementId: 'target-picture',
              layerId: 'objects',
              pos: GridPos(x: 3, y: 3),
              applyCollision: false,
            ),
        ],
        mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
        warps: [
          MapWarp(
            id: 'arrival',
            pos: const GridPos(x: 2, y: 2),
            targetMapId: id,
            targetPos: const GridPos(x: 2, y: 2),
            triggerMode: MapWarpTriggerMode.sceneOnly,
          ),
        ],
      ),
  ];
  final command = _command(illustrated: illustrated);
  final manifest = ProjectManifest(
    name: 'Player presentation',
    settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
    maps: [
      for (final map in maps)
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    tilesets: [
      if (targetImage)
        const ProjectTilesetEntry(
          id: 'target-sheet',
          name: 'Target',
          relativePath: 'tilesets/target.png',
          source: ProjectRegularAtlasTilesetSource(
            assetId: 'target-sheet',
            pixelWidth: 4,
            pixelHeight: 3,
            tileWidth: 4,
            tileHeight: 3,
          ),
        ),
      if (illustrated)
        const ProjectTilesetEntry(
          id: 'sheet',
          name: 'Picture',
          relativePath: 'tilesets/picture.png',
          source: ProjectRegularAtlasTilesetSource(
            assetId: 'sheet',
            pixelWidth: 4,
            pixelHeight: 3,
            tileWidth: 4,
            tileHeight: 3,
          ),
        ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'pictures', name: 'Pictures'),
    ],
    elements: [
      if (targetImage)
        const ProjectElementEntry(
          id: 'target-picture',
          name: 'Target',
          tilesetId: 'target-sheet',
          categoryId: 'pictures',
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
        ),
      if (illustrated)
        const ProjectElementEntry(
          id: 'picture',
          name: 'Picture',
          tilesetId: 'sheet',
          categoryId: 'pictures',
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
        ),
    ],
    dialogues: [
      if (failingScene)
        const ProjectDialogueEntry(
          id: 'after',
          name: 'After',
          relativePath: 'dialogues/after.yarn',
          declaredOutcomes: [
            DialogueDeclaredOutcome(id: 'done', label: 'Done'),
          ],
        ),
    ],
    scenes: [
      SceneAsset(
        id: 'travel',
        name: 'Travel',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'warp',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(command),
            ),
            if (failingScene)
              SceneNode(
                id: 'after',
                kind: SceneNodeKind.yarnDialogue,
                payload: SceneYarnDialoguePayload(
                  dialogueId: 'after',
                  yarnNodeName: 'Start',
                  expectedOutcomes: ['done'],
                ),
              ),
            if (returnWarp)
              SceneNode(
                id: 'return',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.warp(
                    destinationMapId: 'source',
                    warpId: 'arrival',
                    presentation: SceneWarpPresentation(
                      mode: SceneWarpPresentationMode.fade,
                    ),
                  ),
                ),
              ),
            SceneNode(
              id: 'end',
              kind: SceneNodeKind.end,
              payload: SceneEndPayload(),
            ),
          ],
          edges: [
            SceneEdge(
              id: 'begin',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'warp',
              kind: SceneEdgeKind.defaultFlow,
            ),
            for (final port in ['completed', 'blocked'])
              SceneEdge(
                id: port,
                fromNodeId: 'warp',
                fromPortId: port,
                toNodeId: failingScene
                    ? 'after'
                    : returnWarp
                    ? 'return'
                    : 'end',
                kind: SceneEdgeKind.actionCompleted,
              ),
            if (failingScene) ...[
              SceneEdge(
                id: 'after-done',
                fromNodeId: 'after',
                fromPortId: 'done',
                toNodeId: 'end',
                kind: SceneEdgeKind.dialogueOutcome,
              ),
              SceneEdge(
                id: 'after-completed',
                fromNodeId: 'after',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow,
              ),
            ],
            if (returnWarp)
              for (final port in ['completed', 'blocked'])
                SceneEdge(
                  id: 'return-$port',
                  fromNodeId: 'return',
                  fromPortId: port,
                  toNodeId: 'end',
                  kind: SceneEdgeKind.actionCompleted,
                ),
          ],
        ),
      ),
    ],
  );
  ProjectValidator.validate(manifest, maps: maps);
  for (final map in maps) {
    MapValidator.validate(map, projectDialogueContext: manifest);
  }
  for (final scene in manifest.scenes) {
    final diagnostics = diagnoseSceneAgainstProject(
      scene,
      manifest,
      mapsById: {for (final map in maps) map.id: map},
    );
    expect(
      diagnostics.hasErrors,
      isFalse,
      reason: diagnostics.diagnostics.toString(),
    );
  }
  await Directory('${dir.path}/maps').create();
  for (final map in maps) {
    await File('${dir.path}/maps/${map.id}.json')
        .writeAsString(jsonEncode(map.toJson()));
  }
  await File('${dir.path}/project.json')
      .writeAsString(jsonEncode(manifest.toJson()));
  if (failingScene) {
    await Directory('${dir.path}/dialogues').create();
    await File('${dir.path}/dialogues/after.yarn')
        .writeAsString('title: Start\n---\nAfter.\n===\n');
  }
  if (illustrated || targetImage) {
    await Directory('${dir.path}/tilesets').create();
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xFF0000FF), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(4, 3);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    if (illustrated) {
      await File('${dir.path}/tilesets/picture.png').writeAsBytes(bytes);
    }
    if (targetImage) {
      await File('${dir.path}/tilesets/target.png').writeAsBytes(bytes);
    }
    image.dispose();
    picture.dispose();
  }
  final projectPath = '${dir.path}/project.json';
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectPath,
    mapId: 'source',
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectPath,
    runtimeMapBundleLoader: ({required projectFilePath, required mapId}) async {
      if (mapId == 'target' && preparationGate != null) {
        if (!preparationEntered!.isCompleted) preparationEntered.complete();
        await preparationGate.future;
      }
      return loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
    },
    dialogueSessionLoader: (_) async =>
        throw StateError('Dialogue failed after Warp.'),
    runtimeTilesetImageLoader:
        (paths, {transparentColorByTilesetId = const {}}) async {
          if (paths.containsKey('target-sheet')) {
            if (transferEntered != null && !transferEntered.isCompleted) {
              transferEntered.complete();
            }
            await transferGate?.future;
            if (failTransfer) throw StateError('Target image load failed.');
          }
          return loadTilesetImagesById(
            paths,
            transparentColorByTilesetId: transparentColorByTilesetId,
          );
        },
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await game.loaded;
  await tester.pump();
  addTearDown(game.onRemove);
  await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
  game.pauseEngine();
  return game;
}
