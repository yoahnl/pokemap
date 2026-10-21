import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a cinematic dialogue asset accepts primary while parallel movement stays locked', (tester) async {
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('cinematic-dialogue-input-');
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}/dialogue.yarn').writeAsString('title: Start\n---\nRadio: First page.\nRadio: Second page.\n===\n');
      final movie = CinematicAsset(id: 'cinematic_lighthouse', title: 'Dialogue asset', mapId: 'map_port',
          timeline: CinematicTimeline(steps: [
            CinematicTimelineStep(id: 'talk', kind: CinematicTimelineStepKind.dialogueLine,
                assetRef: 'radio', parallelGroupId: 'interview'),
            CinematicTimelineStep(id: 'wait', kind: CinematicTimelineStepKind.wait,
                durationMs: 2000, parallelGroupId: 'interview'),
          ]));
      final base = _bundle(cinematic: movie);
      final bundle = base.copyWith(projectRootDirectory: root.path,
          manifest: base.manifest.copyWith(dialogues: [
            ProjectDialogueEntry(id: 'radio', name: 'Radio', relativePath: 'dialogue.yarn', defaultStartNode: 'Start'),
          ]));
      final game = PlayableMapGame(bundle: bundle, projectFilePath: '${root.path}/project.json');
      Future<void> settleUntil(bool Function() condition) async {
        for (var i = 0; i < 2000; i++) {
          if (condition()) return;
          game.update(.02);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        fail('Cinematic dialogue did not settle.');
      }
      game.onGameResize(Vector2(320, 240));
      await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: GameWidget(game: game)));
      await game.loaded; await tester.pump();
      addTearDown(game.onRemove);
      await _waitForInitialMapActivation(game);
      game.setDialogueFlutterOverlayPreferred(false);
      final completion = game.debugExecuteNarrativeSceneForTest(NarrativeSceneExecutionRequest(
          eventId: 'event', sceneId: 'scene_cinematic_runtime', executionId: 'dialogue-run', gameState: game.gameStateSnapshot));
      await settleUntil(() => game.dialoguePresentationListenable.value?.isCurrentLineFullyRevealed == true);
      final position = game.debugPlayerGridPosition;
      expect(game.dialoguePresentationListenable.value!.fullText, 'First page.');
      expect(game.inputAuthoritySnapshot.context, RuntimeInputContext.dialogue);
      expect(game.debugIsGameplayInputLocked, isTrue);
      game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: true);
      game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.primary));
      game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.primary));
      game.update(.1);
      expect(game.dialoguePresentationListenable.value!.fullText, 'First page.');
      game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: false);
      game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.right));
      game.update(.1);
      game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.right));
      expect(game.debugPlayerGridPosition, position);
      game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.primary));
      game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.primary));
      for (var i = 0; i < 50; i++) { game.update(.02); await Future<void>.delayed(const Duration(milliseconds: 1)); }
      expect(game.dialoguePresentationListenable.value!.fullText, 'Second page.');
      await settleUntil(() => game.dialoguePresentationListenable.value?.isCurrentLineFullyRevealed == true);
      game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.primary));
      game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.primary));
      await settleUntil(() => !game.debugIsCinematicPlaying);
      expect(await completion, isA<NarrativeSceneExecutionCompleted>());
      expect(game.dialoguePresentationListenable.value, isNull);
      expect(game.debugIsGameplayInputLocked, isFalse);
    });
  });

  for (final movementKind in [CinematicTimelineStepKind.actorMove, CinematicTimelineStepKind.actorJump]) {
  testWidgets('real player preserves facing during ${movementKind.name}', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final cinematic = CinematicAsset(
        id: 'cinematic_lighthouse',
        title: 'Actor movement',
        mapId: 'map_port',
        requiredActors: [CinematicActorRef(actorId: 'hero')],
        movementTargets: [
          CinematicMovementTargetRef(targetId: 'end', label: 'End'),
        ],
        stageContext: CinematicStageContext(
          actorBindings: [
            CinematicActorBinding(
              actorId: 'hero',
              kind: CinematicActorBindingKind.player,
            ),
          ],
          movementTargetBindings: [
            CinematicMovementTargetBinding(
              targetId: 'end',
              kind: CinematicMovementTargetBindingKind.stagePoint,
              sourceId: 'end',
            ),
          ],
          stagePoints: [
            CinematicStagePoint(id: 'end', label: 'End', x: 4, y: 2),
          ],
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'face',
              kind: CinematicTimelineStepKind.actorFace,
              actorId: 'hero',
              metadata: const {'actor.direction': 'left'},
            ),
            CinematicTimelineStep(
              id: 'move',
              kind: movementKind,
              actorId: 'hero',
              targetId: 'end',
              durationMs: 1000,
              metadata: {
                if (movementKind == CinematicTimelineStepKind.actorJump) 'actor.jumpHeightCells': '0.5',
                if (movementKind == CinematicTimelineStepKind.actorMove)
                'actor.movementMode': 'walk',
                if (movementKind == CinematicTimelineStepKind.actorMove)
                'actor.pathMode': 'direct',
                'actor.facingMode': 'preserve',
              },
            ),
            CinematicTimelineStep(
              id: 'line',
              kind: CinematicTimelineStepKind.dialogueLine,
              dialogueText: 'Finished',
            ),
          ],
        ),
      );
      final game = PlayableMapGame(
        bundle: _bundle(cinematic: cinematic),
        projectFilePath: '/tmp/cinematic_runtime/project.json',
      );
      game.onGameResize(Vector2(320, 240));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: GameWidget(game: game),
        ),
      );
      await game.loaded;
      await tester.pump();
      addTearDown(game.onRemove);
      await _waitForInitialMapActivation(game);
      final player = game.world.children.whereType<PlayerComponent>().single;
      final initialPosition = player.position.clone();
      final completion = game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(
          eventId: 'event',
          sceneId: 'scene_cinematic_runtime',
          executionId: 'run',
          gameState: game.gameStateSnapshot,
        ),
      );
      await _waitUntil(game, () => game.debugIsCinematicPlaying);
      game.update(.5);
      expect(player.position.x, greaterThan(initialPosition.x));
      expect(player.cinematicFacing, EntityFacing.west);
      expect(player.cinematicJumpLift, movementKind == CinematicTimelineStepKind.actorJump
          ? greaterThan(0) : 0);
      game.update(.5);
      expect(player.cinematicJumpLift, 0);
      expect(player.cinematicFacing, EntityFacing.west);
      expect(game.debugCinematicDialogueLine, 'Finished');
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      expect(await completion, isA<NarrativeSceneExecutionCompleted>());
      expect(game.debugIsCinematicPlaying, isFalse);
      expect(game.debugIsGameplayInputLocked, isFalse);
    });
  });
  }

  test('PlayableMapGame renders and awaits a cinematic before restoring input and camera', () async {
    final game = _LifecycleTestPlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/cinematic_runtime/project.json',
      devicePixelRatioProvider: () => 2,
    );
    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForInitialMapActivation(game);
    final originalCameraTopLeft = game.debugCameraWorldTopLeft.clone();
    final originalPlayerPosition = game.debugPlayerGridPosition;

    final completion = game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'event_cinematic_runtime',
        sceneId: 'scene_cinematic_runtime',
        executionId: 'execution_cinematic_runtime',
        gameState: game.gameStateSnapshot,
      ),
    );
    await _waitUntil(game, () => game.debugIsCinematicPlaying);

    expect(game.debugIsCinematicPlaying, isTrue);
    expect(game.debugIsGameplayInputLocked, isTrue);
    expect(await game.saveGame(), isFalse);
    expect(await game.loadGame(), isFalse);
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      ),
      isTrue,
    );

    game.update(0.05);
    expect(game.debugCameraWorldTopLeft, isNot(originalCameraTopLeft));
    expect(game.debugPlayerGridPosition, originalPlayerPosition);

    game.update(0.05);
    expect(game.debugCinematicDialogueLine, 'Le phare nous attend.');
    expect(game.debugIsCinematicPlaying, isTrue);

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    expect(game.debugCinematicDialogueLine, isNull);
    expect(game.debugCinematicFadeOpacity, 0);

    game.update(0.05);
    expect(game.debugCinematicFadeOpacity, closeTo(0.5, 0.001));
    game.update(0.05);
    final result = await completion;

    expect(result, isA<NarrativeSceneExecutionCompleted>());
    expect(game.debugIsCinematicPlaying, isFalse);
    expect(game.debugIsGameplayInputLocked, isFalse);
    expect(game.debugCinematicFadeOpacity, isNull);
    expect(game.debugCameraWorldTopLeft, originalCameraTopLeft);
    expect(game.debugPlayerGridPosition, originalPlayerPosition);
  });
}

final class _LifecycleTestPlayableMapGame extends PlayableMapGame {
  _LifecycleTestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.devicePixelRatioProvider,
  });

  @override
  bool get isLoaded => true;
}

Future<void> _waitForInitialMapActivation(PlayableMapGame game) async {
  for (var i = 0; i < 100; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) return;
    game.update(0);
    await Future<void>.value();
  }
  fail('Initial map activation did not settle.');
}

Future<void> _waitUntil(PlayableMapGame game, bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    game.update(0);
    await Future<void>.value();
  }
  fail('Runtime condition did not settle.');
}

RuntimeMapBundle _bundle({CinematicAsset? cinematic}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Cinematic runtime integration',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      cinematics: <CinematicAsset>[cinematic ?? _cinematic()],
      scenes: <SceneAsset>[_scene()],
    ),
    map: const MapData(
      id: 'map_port',
      name: 'Port',
      size: GridSize(width: 20, height: 15),
      layers: <MapLayer>[MapLayer.object(id: 'objects', name: 'Objects')],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/cinematic_runtime',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_lighthouse',
    title: 'Lighthouse reveal',
    mapId: 'map_port',
    stageContext: CinematicStageContext(
      stagePoints: <CinematicStagePoint>[
        CinematicStagePoint(id: 'lighthouse', label: 'Phare', x: 15, y: 10),
      ],
    ),
    timeline: CinematicTimeline(
      steps: <CinematicTimelineStep>[
        CinematicTimelineStep(
          id: 'focus_lighthouse',
          kind: CinematicTimelineStepKind.camera,
          durationMs: 100,
          metadata: const <String, String>{
            cinematicTimelineCameraModeMetadataKey: 'focus',
            cinematicTimelineCameraTargetKindMetadataKey: 'stagePoint',
            cinematicTimelineCameraTargetStagePointIdMetadataKey: 'lighthouse',
            cinematicTimelineCameraZoomPresetMetadataKey: 'close',
          },
        ),
        CinematicTimelineStep(
          id: 'line',
          kind: CinematicTimelineStepKind.dialogueLine,
          dialogueText: 'Le phare nous attend.',
        ),
        CinematicTimelineStep(
          id: 'fade_out',
          kind: CinematicTimelineStepKind.fade,
          durationMs: 100,
          metadata: const <String, String>{
            cinematicTimelineFadeModeMetadataKey: 'fadeOut',
          },
        ),
      ],
    ),
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_cinematic_runtime',
    name: 'Cinematic runtime Scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'cinematic_lighthouse'),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_cinematic',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'cinematic',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'cinematic_to_end',
          fromNodeId: 'cinematic',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    ),
  );
}
