import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real NPC jumps over a wall with visual lift and grounded save', (tester) async {
    await tester.runAsync(() async {
      final game = await _mount(tester, targetX: 5.5, jump: true);
      final completion = game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(eventId: 'test', sceneId: 'scene',
            executionId: 'jump', gameState: game.gameStateSnapshot),
      );
      await _until(game, () => game.debugIsCinematicPlaying);
      game.update(.5);
      expect(_npc(game).cinematicJumpLift, 8);
      expect(_npc(game).gridPos, const GridPos(x: 3, y: 3));
      game.update(.5);
      expect(_npc(game).cinematicJumpLift, 0);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      expect(await completion, isA<NarrativeSceneExecutionCompleted>());
      expect(_npc(game).gridPos, const GridPos(x: 5, y: 3));
      final saved = SaveData.fromJson(jsonDecode(jsonEncode(
        saveDataFromGameState(game.gameStateSnapshot),
      )));
      expect(saved.mapInstanceWorldState.instancesByMapId['room']!.npcPoses['guide']!.position,
          const GridPos(x: 5, y: 3));
    });
  });

  testWidgets('fractional final NPC pose is rejected before playback mutation', (tester) async {
    await tester.runAsync(() async {
      final game = await _mount(tester, targetX: 4.25);
      final initial = _npc(game).position.clone();
      final result = await game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(eventId: 'test', sceneId: 'scene',
            executionId: 'invalid', gameState: game.gameStateSnapshot),
      );
      expect(result, isNot(isA<NarrativeSceneExecutionCompleted>()));
      expect(game.debugIsCinematicPlaying, isFalse);
      expect(_npc(game).position, initial);
      expect(game.gameStateSnapshot.mapInstanceWorldState.instancesByMapId, isEmpty);
    });
  });

  testWidgets('ordinary NPC final pose survives unlock, save and reload', (tester) async {
    await tester.runAsync(() async {
      final game = await _mount(tester);
      final completion = game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(
          eventId: 'test', sceneId: 'scene', executionId: 'run',
          gameState: game.gameStateSnapshot,
        ),
      );
      await _until(game, () => game.debugIsCinematicPlaying);
      game.update(.1);
      expect(game.debugCinematicDialogueLine, 'Ready');
      expect(_npc(game).facing, EntityFacing.west);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      expect(await completion, isA<NarrativeSceneExecutionCompleted>());
      await _until(game, () => !game.debugIsGameplayInputLocked);
      game.update(.1);
      expect(_npc(game).gridPos, const GridPos(x: 4, y: 3));
      expect(_npc(game).facing, EntityFacing.west);
      final saved = SaveData.fromJson(jsonDecode(jsonEncode(
        saveDataFromGameState(game.gameStateSnapshot),
      )));
      expect(saved.mapInstanceWorldState.instancesByMapId['room']!.npcPoses['guide']!.facing,
          EntityFacing.west);
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = await _mount(tester, save: saved);
      expect(_npc(restored).gridPos, const GridPos(x: 4, y: 3));
      expect(_npc(restored).facing, EntityFacing.west);
    });
  });
}

OverworldActorComponent _npc(PlayableMapGame game) =>
    game.world.children.whereType<OverworldActorComponent>()
        .singleWhere((actor) => actor.character.id == 'guide-character');

Future<void> _until(PlayableMapGame game, bool Function() ready) async {
  for (var i = 0; i < 400; i++) {
    if (ready()) return;
    game.update(0);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Runtime condition did not settle.');
}

Future<PlayableMapGame> _mount(WidgetTester tester, {SaveData? save, double targetX = 4.5, bool jump = false}) async {
  final game = PlayableMapGame(
    bundle: _bundle(targetX, jump: jump), projectFilePath: '/tmp/cinematic-pose/project.json',
    saveData: save,
    runtimeTilesetImageLoader: (paths, {transparentColorByTilesetId = const {}}) async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 128, 128),
          ui.Paint()..color = const ui.Color(0xFF4060FF));
      final picture = recorder.endRecording();
      final image = await picture.toImage(128, 128);
      picture.dispose();
      return {'actors': RuntimeTilesetImage(images: [image],
          chunks: const [RuntimeTilesetChunk(top: 0, height: 128, width: 128)],
          width: 128, height: 128)};
    },
  );
  game.onGameResize(Vector2(320, 240));
  await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr,
      child: GameWidget(game: game)));
  await game.loaded;
  await tester.pump();
  addTearDown(game.onRemove);
  await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
  return game;
}

RuntimeMapBundle _bundle(double targetX, {bool jump = false}) => RuntimeMapBundle(
  projectRootDirectory: '/tmp/cinematic-pose',
  tilesetAbsolutePathsById: const {'actors': '/tmp/cinematic-pose/actors.png'},
  map: MapData(
    id: 'room', name: 'Room', size: const GridSize(width: 8, height: 8),
    entities: [
      MapEntity(id: 'spawn', kind: MapEntityKind.spawn, pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart)),
      MapEntity(id: 'guide', kind: MapEntityKind.npc, pos: GridPos(x: 3, y: 3), blocksMovement: true,
          npc: MapEntityNpcData(displayName: 'Guide', characterId: 'guide-character')),
      if (jump) const MapEntity(id: 'wall', kind: MapEntityKind.custom,
          pos: GridPos(x: 4, y: 3),
          properties: {'collision.width': '1', 'collision.height': '1'}),
    ],
  ),
  manifest: ProjectManifest(
    name: 'Cinematic pose',
    maps: const [ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json')],
    tilesets: const [ProjectTilesetEntry(id: 'actors', name: 'Actors', relativePath: 'actors.png')],
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16, displayScale: 1),
    characters: [ProjectCharacterEntry(id: 'guide-character', name: 'Guide', tilesetId: 'actors')],
    cinematics: [CinematicAsset(
      id: 'cinematic', title: 'Move guide', mapId: 'room',
      requiredActors: [CinematicActorRef(actorId: 'guide')],
      movementTargets: [CinematicMovementTargetRef(targetId: 'end', label: 'End')],
      stageContext: CinematicStageContext(
        actorBindings: [CinematicActorBinding(actorId: 'guide',
            kind: CinematicActorBindingKind.mapEntity, mapEntityId: 'guide')],
        stagePoints: [CinematicStagePoint(id: 'end', label: 'End', x: targetX, y: 3)],
        movementTargetBindings: [CinematicMovementTargetBinding(targetId: 'end',
            kind: CinematicMovementTargetBindingKind.stagePoint, sourceId: 'end')],
      ),
      timeline: CinematicTimeline(steps: [
        CinematicTimelineStep(id: 'move', kind: jump
            ? CinematicTimelineStepKind.actorJump : CinematicTimelineStepKind.actorMove,
            actorId: 'guide', targetId: 'end', durationMs: jump ? 1000 : 100,
            metadata: jump ? const {'actor.jumpHeightCells': '0.5'}
                : const {'actor.movementMode': 'walk', 'actor.pathMode': 'direct'}),
        CinematicTimelineStep(id: 'face', kind: CinematicTimelineStepKind.actorFace,
            actorId: 'guide', metadata: const {'actor.direction': 'left'}),
        CinematicTimelineStep(id: 'line', kind: CinematicTimelineStepKind.dialogueLine,
            dialogueText: 'Ready'),
      ]),
    )],
    scenes: [SceneAsset(id: 'scene', name: 'Move', graph: SceneGraph(
      startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'cinematic', kind: SceneNodeKind.cinematic,
            payload: SceneCinematicPayload(cinematicId: 'cinematic')),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(id: 'begin', fromNodeId: 'start', fromPortId: 'completed',
            toNodeId: 'cinematic', kind: SceneEdgeKind.defaultFlow),
        SceneEdge(id: 'finish', fromNodeId: 'cinematic', fromPortId: 'completed',
            toNodeId: 'end', kind: SceneEdgeKind.cinematicCompleted),
      ],
    ))],
  ),
);
