import 'dart:io';
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
import 'package:map_runtime/src/presentation/flame/player_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final playerOnly in [false, true]) {
    testWidgets('real daily cinematic keeps transaction facts and prior poses playerOnly=$playerOnly', (tester) async {
      await tester.runAsync(() async {
        var now = DateTime(2026, 10, 30, 23, 59);
        final instances = retainMapInstance(
          state: const MapInstanceWorldState.empty(), mapId: 'room', allocateId: (_) => 'daily-pose-instance',
        );
        final initial = GameState(
          saveId: 'daily-cinematic-fixture', currentMapId: 'room', playerPosition: const GridPos(x: 1, y: 1),
          gameplayCalendarState: GameplayCalendarState(observedLocalDay: '2026-10-30', dayRevision: 0),
          periodicRewardState: playerOnly
              ? PeriodicRewardState(claimsById: {'daily': PeriodicRewardClaim(revision: 1, lastClaimDayRevision: 0, lastClaimLocalDay: '2026-10-30')})
              : const PeriodicRewardState.empty(),
          mapInstanceWorldState: instances.setNpcPoses(instances.instanceRef('room')!, {
            'other': MapInstanceNpcPose(position: const GridPos(x: 5, y: 5), facing: EntityFacing.west),
          }),
        );
        final game = await _mount(tester, save: saveDataFromGameState(initial), conditional: true,
          explicitSaveRestore: true, civilNow: () => now, admitCatalog: true,
          transformBundle: (bundle) => _dailyPoseBundle(bundle, playerOnly: playerOnly));
        Future<GameState> play() async {
          game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.primary));
          game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.primary));
          await _until(game, () => game.debugIsCinematicPlaying);
          game.update(.1);
          expect(game.debugCinematicDialogueLine, 'Ready');
          game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.primary));
          game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.primary));
          await _until(game, () => !game.debugIsCinematicPlaying && !game.debugIsGameplayInputLocked &&
              game.gameStateSnapshot.narrativeFactRuntimeState.valueFor('oak_present')?.boolValue == true);
          return game.gameStateSnapshot;
        }
        if (playerOnly) {
          final first = await play();
          expect(first.narrativeFactRuntimeState.valueFor('oak_present')?.boolValue, isTrue);
          expect(game.world.children.whereType<OverworldActorComponent>()
              .where((actor) => actor.character.id == 'guide-character').every((actor) => !actor.isGameplayPresent), isTrue);
          now = DateTime(2026, 10, 31, 0, 1);
          game.refreshPeriodicRewardAvailability();
          await _until(game, () => game.world.children.whereType<OverworldActorComponent>()
              .any((actor) => actor.character.id == 'guide-character' && actor.isGameplayPresent));
          expect(_npc(game).isGameplayPresent, isTrue);
        }
        final committed = await play();
        final poses = committed.mapInstanceWorldState.instancesByMapId['room']!.npcPoses;
        expect(committed.narrativeFactRuntimeState.valueFor('oak_present')?.boolValue, isTrue);
        expect(committed.gameplayCalendarState, initial.gameplayCalendarState);
        expect(committed.periodicRewardState, initial.periodicRewardState);
        expect(poses['other']!.position, const GridPos(x: 5, y: 5));
        expect(poses['other']!.facing, EntityFacing.west);
        expect(poses['guide']!.position, playerOnly ? const GridPos(x: 3, y: 3) : const GridPos(x: 4, y: 3));
        await _until(game, () => game.world.children.whereType<OverworldActorComponent>()
            .any((actor) => actor.character.id == 'guide-character' && actor.isGameplayPresent));
        expect(_npc(game).isGameplayPresent, isTrue);
        expect(_npc(game).gridPos, poses['guide']!.position);
        final saved = SaveData.fromJson(jsonDecode(jsonEncode(saveDataFromGameState(committed))));
        expect(saved.gameplayCalendarState, initial.gameplayCalendarState);
        expect(saved.periodicRewardState, initial.periodicRewardState);
        expect(saved.mapInstanceWorldState, committed.mapInstanceWorldState);
        expect(game.debugIsGameplayInputLocked, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    });
  }

  testWidgets('real player, NPC and camera advance together before one final save', (tester) async {
    await tester.runAsync(() async {
      final game = await _mount(tester, parallel: true);
      final player = game.world.children.whereType<PlayerComponent>().single;
      final start = player.cinematicVisualFocusPoint.clone();
      final initialCamera = game.debugCameraWorldTopLeft.clone();
      final initialPlayerState = game.gameStateSnapshot.playerPixelPosition;
      final completion = game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(eventId: 'test', sceneId: 'scene',
            executionId: 'parallel', gameState: game.gameStateSnapshot),
      );
      await _until(game, () => game.debugIsCinematicPlaying);
      game.update(.5);
      expect(player.cinematicVisualFocusPoint.x, closeTo((start.x + 64) / 2, .000001));
      expect(_npc(game).position.x + _npc(game).size.x / 2, 64);
      expect(game.debugCameraWorldTopLeft, isNot(initialCamera));
      expect(game.gameStateSnapshot.playerPixelPosition, initialPlayerState);
      game.update(.5);
      expect(game.debugIsCinematicPlaying, isTrue);
      expect(game.debugCinematicDialogueLine, isNull);
      game.update(.5);
      expect(game.debugCinematicDialogueLine, 'Ready');
      game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.primary));
      expect(await completion, isA<NarrativeSceneExecutionCompleted>());
      expect(_npc(game).gridPos, const GridPos(x: 4, y: 3));
      expect(game.gameStateSnapshot.playerPixelPosition, isNot(initialPlayerState));
      final saved = SaveData.fromJson(jsonDecode(jsonEncode(saveDataFromGameState(game.gameStateSnapshot))));
      expect(saved.mapInstanceWorldState.instancesByMapId['room']!.npcPoses['guide']!.position,
          const GridPos(x: 4, y: 3));
      expect(game.debugIsGameplayInputLocked, isFalse);
    });
  });

  for(final rollback in [false,true]) {
    testWidgets('conditional actor keepFinal uses typed Scene facts and rollback=$rollback', (tester) async {
      await tester.runAsync(() async {
        final game=await _mount(tester,conditional:true,failAfter:rollback);
        final before=game.gameStateSnapshot.toJson();
        final completion=game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(eventId:'test',sceneId:'scene',executionId:'conditional',
            gameState:game.gameStateSnapshot));
        await _until(game,()=>game.debugIsCinematicPlaying);
        expect(_npc(game).isGameplayPresent,isTrue);
        game.update(.1);
        expect(game.debugCinematicDialogueLine,'Ready');
        game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.primary));
        final result=await completion;
        if(rollback) {
          expect(result,isNot(isA<NarrativeSceneExecutionCompleted>()));
          expect(game.gameStateSnapshot.toJson(),before);
          expect(game.world.children.whereType<OverworldActorComponent>()
            .where((a)=>a.character.id=='guide-character').every((a)=>!a.isGameplayPresent),isTrue);
          expect(game.gameStateSnapshot.mapInstanceWorldState.instancesByMapId['room']?.npcPoses['guide'],isNull);
        } else {
          expect(result,isA<NarrativeSceneExecutionCompleted>());
          final committed=(result as NarrativeSceneExecutionCompleted).updatedGameState;
          expect(committed.narrativeFactRuntimeState.valueFor('oak_present')?.boolValue,isTrue);
          expect(committed.mapInstanceWorldState.instancesByMapId['room']!.npcPoses['guide']!.position,const GridPos(x:4,y:3));
          expect(committed.mapInstanceWorldState.instancesByMapId['room']!.npcPoses['guide']!.facing,EntityFacing.west);
          final saved=SaveData.fromJson(jsonDecode(jsonEncode(saveDataFromGameState(committed))));
          await tester.pumpWidget(const SizedBox.shrink());
          final restored=await _mount(tester,save:saved,conditional:true,explicitSaveRestore:true);
          expect(_npc(restored).isGameplayPresent,isTrue);
          expect(_npc(restored).gridPos,const GridPos(x:4,y:3));
          expect(_npc(restored).facing,EntityFacing.west);
        }
        expect(game.debugIsGameplayInputLocked,isFalse);
      });
    });
  }

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

Future<PlayableMapGame> _mount(WidgetTester tester, {SaveData? save, double targetX = 4.5,
    bool jump = false, bool parallel = false, bool conditional = false, bool failAfter = false, bool explicitSaveRestore = false, DateTime Function()? civilNow,
    bool admitCatalog = false, RuntimeMapBundle Function(RuntimeMapBundle)? transformBundle}) async {
  var bundle = _bundle(targetX, jump: jump, parallel: parallel, conditional: conditional, failAfter: failAfter);
  bundle = transformBundle?.call(bundle) ?? bundle;
  var projectFilePath = '/tmp/cinematic-pose/project.json';
  if (admitCatalog) {
    final qa = Directory('/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-availability-runtime');
    await qa.create(recursive: true);
    final root = await qa.createTemp('cinematic-');
    projectFilePath = '${root.path}/project.json';
    await File(projectFilePath).writeAsString(jsonEncode(bundle.manifest.toJson()));
    final mapFile = File('${root.path}/maps/room.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(bundle.map.toJson()));
    final catalog = await RuntimeProjectCatalog.open(projectFilePath);
    addTearDown(() async { catalog.dispose(); await root.delete(recursive: true); });
    final hydrated = await catalog.manifestForMap(bundle.map);
    bundle = RuntimeMapBundle(manifest: hydrated, projectCatalog: catalog, map: bundle.map,
      projectRootDirectory: root.path, tilesetAbsolutePathsById: {'actors': '${root.path}/actors.png'});
  }
  final game = PlayableMapGame(
    bundle: bundle, projectFilePath: projectFilePath, encounterClock: civilNow,
    saveData: save,
    initialMapActivationReason: explicitSaveRestore ? MapActivationReason.saveRestore : MapActivationReason.initialBoot,
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

RuntimeMapBundle _bundle(double targetX, {bool jump = false, bool parallel = false, bool conditional = false, bool failAfter = false}) => RuntimeMapBundle(
  projectRootDirectory: '/tmp/cinematic-pose',
  tilesetAbsolutePathsById: const {'actors': '/tmp/cinematic-pose/actors.png'},
  map: MapData(
    id: 'room', name: 'Room', size: const GridSize(width: 8, height: 8),
    entities: [
      MapEntity(id: 'spawn', kind: MapEntityKind.spawn, pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart)),
      MapEntity(id: 'guide', kind: conditional ? MapEntityKind.custom : MapEntityKind.npc, pos: GridPos(x: 3, y: 3), blocksMovement: true,
          npc: conditional ? null : MapEntityNpcData(displayName: 'Guide', characterId: 'guide-character'),
          presentation:conditional ? MapEntityPresentation(variants:[
            MapEntityPresentationVariant(id:'active',condition:NarrativeEventConditionExpression.leaf(
              NarrativeEventCondition.fact('oak_present',true)),characterId:'guide-character',blocksMovement:true),
            MapEntityPresentationVariant(id:'inactive',condition:NarrativeEventConditionExpression.leaf(
              NarrativeEventCondition.fact('oak_present',false)),blocksMovement:false),
          ]) : null),
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
    facts:[if(conditional) NarrativeFactDefinition(id:'oak_present',label:'Oak present')],
    dialogues:[if(failAfter) ProjectDialogueEntry(id:'missing-file',name:'Missing file',relativePath:'dialogues/missing.yarn',
      declaredOutcomes:[DialogueDeclaredOutcome(id:'done',label:'Done')])],
    cinematics: [CinematicAsset(
      id: 'cinematic', title: 'Move guide', mapId: 'room',
      requiredActors: [CinematicActorRef(actorId: 'guide'),
        if (parallel) CinematicActorRef(actorId: 'hero')],
      movementTargets: [CinematicMovementTargetRef(targetId: 'end', label: 'End'),
        if (parallel) CinematicMovementTargetRef(targetId: 'hero-end', label: 'Hero end')],
      stageContext: CinematicStageContext(
        actorBindings: [CinematicActorBinding(actorId: 'guide',
            kind: CinematicActorBindingKind.mapEntity, mapEntityId: 'guide'),
          if (parallel) CinematicActorBinding(actorId: 'hero', kind: CinematicActorBindingKind.player)],
        stagePoints: [CinematicStagePoint(id: 'end', label: 'End', x: targetX, y: 3),
          if (parallel) CinematicStagePoint(id: 'hero-end', label: 'Hero end', x: 4, y: 2)],
        movementTargetBindings: [CinematicMovementTargetBinding(targetId: 'end',
            kind: CinematicMovementTargetBindingKind.stagePoint, sourceId: 'end'),
          if (parallel) CinematicMovementTargetBinding(targetId: 'hero-end',
              kind: CinematicMovementTargetBindingKind.stagePoint, sourceId: 'hero-end')],
      ),
      timeline: CinematicTimeline(steps: [
        CinematicTimelineStep(id: 'move', kind: jump
            ? CinematicTimelineStepKind.actorJump : CinematicTimelineStepKind.actorMove,
            actorId: 'guide', targetId: 'end', durationMs: jump || parallel ? 1000 : 100,
            parallelGroupId: parallel ? 'pair' : null,
            metadata: jump ? const {'actor.jumpHeightCells': '0.5'}
                : const {'actor.movementMode': 'walk', 'actor.pathMode': 'direct'}),
        if (parallel) CinematicTimelineStep(id: 'hero-move', kind: CinematicTimelineStepKind.actorMove,
            actorId: 'hero', targetId: 'hero-end', durationMs: 1000, parallelGroupId: 'pair',
            metadata: const {'actor.movementMode': 'walk', 'actor.pathMode': 'direct'}),
        if (parallel) CinematicTimelineStep(id: 'camera', kind: CinematicTimelineStepKind.camera,
            durationMs: 1500, parallelGroupId: 'pair', metadata: const {
              'camera.mode': 'focus', 'camera.targetKind': 'stagePoint',
              'camera.targetStagePointId': 'end', 'camera.zoomPreset': 'close'}),
        CinematicTimelineStep(id: 'face', kind: CinematicTimelineStepKind.actorFace,
            actorId: 'guide', metadata: const {'actor.direction': 'left'}),
        CinematicTimelineStep(id: 'line', kind: CinematicTimelineStepKind.dialogueLine,
            dialogueText: 'Ready'),
      ]),
    )],
    scenes: [SceneAsset(id: 'scene', name: 'Move', graph: SceneGraph(
      startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        if(conditional) SceneNode(id:'set-present',kind:SceneNodeKind.action,
          payload:SceneActionPayload.consequence(SceneConsequence.setFact(factId:'oak_present',value:true))),
        if(failAfter) SceneNode(id:'failure',kind:SceneNodeKind.yarnDialogue,
          payload:SceneYarnDialoguePayload(dialogueId:'missing-file',yarnNodeName:'Start',expectedOutcomes:['done'])),
        SceneNode(id: 'cinematic', kind: SceneNodeKind.cinematic,
            payload: SceneCinematicPayload(cinematicId: 'cinematic')),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(id: 'begin', fromNodeId: 'start', fromPortId: 'completed',
            toNodeId: conditional ? 'set-present' : 'cinematic', kind: SceneEdgeKind.defaultFlow),
        if(conditional) SceneEdge(id:'present-cinematic',fromNodeId:'set-present',fromPortId:'completed',
          toNodeId:'cinematic',kind:SceneEdgeKind.actionCompleted),
        if(failAfter) SceneEdge(id:'failure-completed',fromNodeId:'failure',fromPortId:'completed',
          toNodeId:'end',kind:SceneEdgeKind.defaultFlow),
        if(failAfter) SceneEdge(id:'failure-outcome',fromNodeId:'failure',fromPortId:'done',
          toNodeId:'end',kind:SceneEdgeKind.dialogueOutcome),
        SceneEdge(id: 'finish', fromNodeId: 'cinematic', fromPortId: 'completed',
            toNodeId: failAfter ? 'failure' : 'end', kind: SceneEdgeKind.cinematicCompleted),
      ],
    ))],
  ),
);

RuntimeMapBundle _dailyPoseBundle(RuntimeMapBundle bundle, {required bool playerOnly}) {
  final reference = PeriodicRewardReference(sceneId: 'daily-source', nodeId: 'claim', rewardId: 'daily');
  final available = NarrativeEventConditionExpression.leaf(
    NarrativeEventCondition.periodicRewardAvailable(reference: reference, expectedValue: true),
  );
  final claim = SceneInteractiveCommand.claimPeriodicReward(definition: PeriodicItemRewardDefinition(
    rewardId: 'daily', label: 'Daily', itemId: 'fruit', quantity: 1,
  ));
  final source = SceneAsset(id: 'daily-source', name: 'Daily source', graph: SceneGraph(
    startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'claim', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(claim)),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(id: 'start-claim', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'claim', kind: SceneEdgeKind.defaultFlow),
      for (final port in claim.outputPortIds) SceneEdge(id: 'claim-$port', fromNodeId: 'claim', fromPortId: port, toNodeId: 'end', kind: SceneEdgeKind.actionCompleted),
    ],
  ));
  final movie = playerOnly ? CinematicAsset(id: 'cinematic', title: 'Player only', mapId: 'room',
    actorCompletionPolicy: CinematicActorCompletionPolicy.keepFinal,
    requiredActors: [CinematicActorRef(actorId: 'hero')],
    stageContext: CinematicStageContext(
      actorBindings: [CinematicActorBinding(actorId: 'hero', kind: CinematicActorBindingKind.player)],
    ), timeline: CinematicTimeline(steps: [
      CinematicTimelineStep(id: 'face', kind: CinematicTimelineStepKind.actorFace, actorId: 'hero',
        metadata: const {'actor.direction': 'down'}),
      CinematicTimelineStep(id: 'line', kind: CinematicTimelineStepKind.dialogueLine, dialogueText: 'Ready'),
    ])) : bundle.manifest.cinematics.single;
  return bundle.copyWith(map: bundle.map.copyWith(
    layers: [const MapLayer.object(id: 'events', name: 'Events')],
    entities: [
    for (final entity in bundle.map.entities)
      if (entity.id != 'guide') entity else entity.copyWith(presentation: MapEntityPresentation(variants: [
        MapEntityPresentationVariant(id: 'active', condition: NarrativeEventConditionExpression.all([
          NarrativeEventConditionExpression.leaf(NarrativeEventCondition.fact('oak_present', true)), available,
        ]), characterId: 'guide-character', blocksMovement: true),
        MapEntityPresentationVariant(id: 'inactive', condition: NarrativeEventConditionExpression.any([
          NarrativeEventConditionExpression.leaf(NarrativeEventCondition.fact('oak_present', false)),
          NarrativeEventConditionExpression.not(available),
        ]), blocksMovement: false),
      ])),
    const MapEntity(id: 'cinematic-trigger', kind: MapEntityKind.custom, pos: GridPos(x: 1, y: 2), blocksMovement: true),
    const MapEntity(id: 'other', kind: MapEntityKind.npc, pos: GridPos(x: 5, y: 5),
      npc: MapEntityNpcData(characterId: 'other-character', facing: EntityFacing.east)),
  ]), manifest: bundle.manifest.copyWith(scenes: [...bundle.manifest.scenes, source], cinematics: [movie],
    eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only, legacyClaims: const [], records: [
      NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
        id: 'evt_019abcde-0000-7000-8000-000000000001', name: 'Cinematic trigger',
        source: NarrativeEventSourceRef.entityInteract('room', 'cinematic-trigger'), conditions: const [],
        sceneId: 'scene', reusePolicy: NarrativeEventReusePolicy.reusable, priority: 0, order: 0,
      ), enabled: true),
    ]),
    characters: [...bundle.manifest.characters, const ProjectCharacterEntry(id: 'other-character', name: 'Other', tilesetId: 'actors')]));
}
