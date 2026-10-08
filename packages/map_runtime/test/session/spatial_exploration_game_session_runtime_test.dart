import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late RuntimeMapBundle bundle;
  late SpatialExplorationGameSessionRuntime runtime;
  var mounts = 0;
  var unmounts = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('spatial-session-');
    final image = img.Image(width: 32, height: 32);
    await File('${root.path}/hero.png').writeAsBytes(img.encodePng(image));
    final character = ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'unused',
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
              state: CharacterAnimationState.walk,
              direction: direction,
              sourceAssetId: 'hero-sheet',
              frames: const [
                CharacterAnimationFrame(
                    source:
                        TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                    durationMs: 100),
              ]),
      ],
    );
    await File('${root.path}/hello.json').writeAsBytes(
        const RuntimeDialogueDocumentCodec()
            .encodeUtf8(RuntimeDialogueDocument(nodes: [
      RuntimeDialogueNode(title: 'Start', steps: [
        RuntimeDialogueLine('Salut !'),
        RuntimeDialogueLine('À bientôt !')
      ])
    ])));
    final map = MapData(
        version: ProjectVersion.v9,
        id: 'field',
        name: 'Field',
        size: const GridSize(width: 8, height: 8),
        layers: const [],
        entities: [
          MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 4, y: 2),
              npc: MapEntityNpcData(
                  characterId: 'hero',
                  dialogue: DialogueRef(dialogueId: 'hello')))
        ],
        spatialScene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4))));
    bundle = RuntimeMapBundle(
        manifest: ProjectManifest(
            version: ProjectVersion.v9,
            name: 'Spatial',
            settings: const ProjectSettings(
                dimension: ProjectDimension.threeD,
                defaultPlayerCharacterId: 'hero'),
            newGame:
                const ProjectNewGameConfig(enabled: true, startMapId: 'field'),
            maps: const [
              ProjectMapEntry(
                  id: 'field', name: 'Field', relativePath: 'maps/field.json')
            ],
            dialogues: [
              ProjectDialogueEntry(
                  id: 'hello', name: 'Hello', relativePath: 'hello.json')
            ],
            tilesets: const [],
            characters: [
              character
            ]),
        map: map,
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: const {},
        characterAnimationAbsolutePathsByAssetId: {
          'hero-sheet': '${root.path}/hero.png'
        });
    mounts = unmounts = 0;
    runtime = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async => mounts++,
        unmountSession: (_) async => unmounts++);
  });

  tearDown(() async {
    await runtime.dispose();
    await root.delete(recursive: true);
  });

  test('primary opens one dialogue, locks sprint and rejects stale commands',
      () async {
    await runtime.load((_) {});
    final session = runtime.session!;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    for (var i = 0; i < 5; i++) {
      session.frame(.05);
      await Future<void>.delayed(Duration.zero);
    }
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    runtime.handleInput(const RuntimeInputEvent.press(
        RuntimeInputControl.primary,
        isRepeat: true));
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.dialogue);
    final line = runtime.dialoguePresentationListenable.value!;
    expect(line.text, 'Salut !');
    expect(session.frames(0).keys, containsAll(['hero', 'field:npc:npc']));
    expect(session.movement.running, isFalse);
    runtime.dispatchDialoguePresentationCommand(
        DialogueAdvanceCommand(snapshotRevision: line.revision));
    expect(runtime.dialoguePresentationListenable.value!.text, 'À bientôt !');
    runtime.dispatchDialoguePresentationCommand(
        DialogueAdvanceCommand(snapshotRevision: line.revision));
    expect(runtime.dialoguePresentationListenable.value!.text, 'À bientôt !');
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    expect(runtime.dialoguePresentationListenable.value, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
    session.frame(.05);
    expect(session.movement.moving, isFalse);
  });

  test('awaited dialogue completes only after its last line', () async {
    await runtime.load((_) {});
    var completed = false;
    final dialogue = runtime.session!
        .showDialogue(DialogueRef(dialogueId: 'hello'))
        .then((result) {
      completed = true;
      return result;
    });
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    expect(completed, isFalse);
    runtime.session!.confirmDialogue();
    expect(completed, isFalse);
    runtime.session!.confirmDialogue();
    final result = await dialogue;
    expect(result.success, isTrue);
    expect(result.scenePortId, 'completed');
    expect(runtime.dialoguePresentationListenable.value, isNull);
  });

  test('closing an awaited dialogue reports cancellation', () async {
    await runtime.load((_) {});
    final dialogue =
        runtime.session!.showDialogue(DialogueRef(dialogueId: 'hello'));
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    runtime.session!.closeDialogue();
    final result = await dialogue;
    expect(result.success, isFalse);
    expect(result.errorCode, SceneDialogueRuntimeAwaitableErrorCode.cancelled);
  });

  test('authored dialogue choices stay visible and resolve their output',
      () async {
    await File('${root.path}/hello.json').writeAsBytes(
        const RuntimeDialogueDocumentCodec()
            .encodeUtf8(RuntimeDialogueDocument(nodes: [
      RuntimeDialogueNode(title: 'Start', steps: [
        RuntimeDialogueChoiceBlock([
          RuntimeDialogueChoice(text: 'Oui', steps: [], outcomeId: 'accepted'),
          RuntimeDialogueChoice(text: 'Non', steps: [], outcomeId: 'declined')
        ])
      ])
    ])));
    await runtime.load((_) {});
    final dialogue =
        runtime.session!.showDialogue(DialogueRef(dialogueId: 'hello'));
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    final snapshot = runtime.dialoguePresentationListenable.value!;
    expect(snapshot.choices.map((choice) => choice.label), ['Oui', 'Non']);
    runtime.session!.dispatchDialogueCommand(DialogueSelectChoiceCommand(
        snapshotRevision: snapshot.revision, choiceIndex: 1));
    expect((await dialogue).outcomeId, 'declined');
    expect(runtime.dialoguePresentationListenable.value, isNull);
  });

  test('native map enter commits its Event V2 scene exactly once', () async {
    bundle = bundle.copyWith(
        manifest: bundle.manifest.copyWith(
            eventRegistry: NarrativeEventRegistry(
                schemaVersion: 1,
                mode: EventSystemMode.v2Only,
                records: [
                  spatialEvent(
                      NarrativeEventSourceRef.mapEnter('field'), 'arrival')
                ],
                legacyClaims: const []),
            scenes: [
          spatialScene('arrival', [SceneConsequence.giveMoney(amount: 25)])
        ]));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
    expect(
        runtime
            .gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        hasLength(1));
    runtime.session!.frame(.1);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
  });

  test(
      'prepared connection keeps running phase and never rewinds an empty activation',
      () async {
    const connection = MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'other',
        offset: 0);
    final hero = ProjectCharacterEntry(
        id: 'hero',
        name: 'Hero',
        tilesetId: 'hero',
        animations: [
          for (final state in [
            CharacterAnimationState.walk,
            CharacterAnimationState.run
          ])
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                  state: state,
                  direction: direction,
                  frames: const [
                    CharacterAnimationFrame(
                        source:
                            TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                        durationMs: 100)
                  ])
        ]);
    bundle = bundle.copyWith(
      map: bundle.map.copyWith(connections: [connection]),
      manifest: bundle.manifest.copyWith(
          settings:
              bundle.manifest.settings.copyWith(tileWidth: 16, tileHeight: 16),
          characters: [
            hero
          ],
          tilesets: const [
            ProjectTilesetEntry(
                id: 'hero', name: 'Hero', relativePath: 'hero.png')
          ],
          maps: [
            ...bundle.manifest.maps,
            const ProjectMapEntry(
                id: 'other', name: 'Other', relativePath: 'maps/other.json')
          ]),
      tilesetAbsolutePathsById: {'hero': '${root.path}/hero.png'},
      characterAnimationAbsolutePathsByAssetId: const {},
    );
    final destination =
        bundle.map.copyWith(id: 'other', entities: [], connections: []);
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/other.json')
        .writeAsString(jsonEncode(destination.toJson()));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(bundle.manifest.toJson()));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final session = runtime.session!;
    await session.loadConnectionNeighbor(connection);
    session.setVisibleMaps({'field', 'other'});
    final movementContinuity =
        runtime.overworldInteractionSnapshot!.movementContinuityId;
    final contexts = <RuntimeInputContext>[];
    runtime.inputAuthority
        .addListener(() => contexts.add(runtime.inputAuthority.value.context));
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.right));
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
    var phaseBefore = 0.0;
    for (var frame = 0;
        frame < 100 && session.bundle.map.id == 'field';
        frame++) {
      phaseBefore = session.movement.animationSeconds;
      session.frame(.016);
      await Future<void>.delayed(Duration.zero);
    }
    expect(session.bundle.map.id, 'other');
    expect(runtime.overworldInteractionSnapshot!.movementContinuityId,
        movementContinuity);
    expect(session.movement.running, isTrue);
    expect(
        session.movement.animationSeconds, greaterThanOrEqualTo(phaseBefore));
    expect(contexts, isNot(contains(RuntimeInputContext.blocked)));
    final x = session.movement.x;
    session.frame(.016);
    await Future<void>.delayed(Duration.zero);
    expect(session.movement.x, greaterThan(x));
    expect(runtime.gameStateSnapshot.playerSpatialPosition,
        session.movement.spatialPosition);
    expect(
        runtime.gameStateSnapshot.narrativeEventProgress.activeNarrativeMapId,
        'other');
  });

  test(
      'model interaction waits for visible frames, persists pose and rewards once',
      () async {
    bundle = animatedDoorBundle(bundle);
    await runtime.load((_) {});
    await runtime.gameplayReady;
    expect(
        runtime.overworldInteractionSnapshot!.primaryAction!.request.targetKind,
        RuntimeOverworldInteractionTargetKind.modelInstance);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await waitForValue(runtime.session!.storyActive, (value) => value);
    runtime.session!.frames(.5);
    final visible =
        runtime.session!.worldStateProvider!().modelState('field', 'door')!;
    expect(visible.normalizedTime, .25);
    expect(visible.blocksMovement, isTrue);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
    runtime.session!.frames(1.5);
    await waitForValue(runtime.session!.storyActive, (value) => !value);
    await Future<void>.delayed(Duration.zero);
    final state = runtime.gameStateSnapshot;
    expect(state.trainerProfile.money, 25);
    expect(state.spatialWorldState.modelState('field', 'door')!.blocksMovement,
        isFalse);
    expect(
        state.spatialWorldState.modelState('field', 'door')!.normalizedTime, 1);
    final restored =
        gameStateFromStrictSaveJson(strictGameStateSaveJson(state));
    expect(restored.spatialWorldState, state.spatialWorldState);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await Future<void>.delayed(Duration.zero);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
    final continued = restoredRuntime(
        bundle,
        root,
        restored.copyWith(
            playerPosition: const GridPos(x: 4, y: 5),
            playerSpatialPosition: PlayerSpatialPosition(x: 4.5, z: 5.5)));
    addTearDown(continued.dispose);
    await continued.load((_) {});
    await continued.gameplayReady;
    expect(continued.session!.movement.z, 5.5);
    expect(continued.session!.worldStateProvider!().modelState('field', 'door'),
        state.spatialWorldState.modelState('field', 'door'));
    expect(continued.gameStateSnapshot.trainerProfile.money, 25);
  });

  test('cancelling a model Scene restores private consequences and controls',
      () async {
    bundle = animatedDoorBundle(bundle, rewardBefore: true);
    await runtime.load((_) {});
    await runtime.gameplayReady;
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await waitForValue(runtime.session!.storyActive, (value) => value);
    runtime.session!.frames(.5);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    await waitForValue(runtime.session!.storyActive, (value) => !value);
    await Future<void>.delayed(Duration.zero);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
    expect(runtime.gameStateSnapshot.spatialWorldState,
        const SpatialWorldState.empty());
    expect(
        runtime
            .gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isEmpty);
    expect(runtime.session!.worldStateProvider!(),
        const SpatialWorldState.empty());
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
  });

  test('cinematic frames move and persist a NPC while pause freezes its clock',
      () async {
    bundle = npcCinematicBundle(bundle);
    await runtime.load((_) {});
    await waitForStory(runtime);
    runtime.session!.frames(.25);
    expect(runtime.session!.storyCamera!()!.zoom, closeTo(.8, .001));
    runtime.session!.frames(.75);
    expect(runtime.session!.frames(0)['field:npc:npc']!.x, closeTo(5.5, .001));
    expect(runtime.gameStateSnapshot.spatialWorldState.actorsByMap, isEmpty);
    await runtime.pause();
    runtime.session!.frames(10);
    expect(runtime.session!.frames(0)['field:npc:npc']!.x, closeTo(5.5, .001));
    await runtime.resume();
    runtime.session!.frames(1);
    await runtime.gameplayReady;
    expect(runtime.session!.frames(0)['field:npc:npc']!.x, 6.5);
    expect(
        runtime.gameStateSnapshot.spatialWorldState
            .actorState('field', 'npc')!
            .x,
        6.5);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
    expect(runtime.session!.storyCamera!(), isNull);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
    final continued = restoredRuntime(
        bundle,
        root,
        runtime.gameStateSnapshot.copyWith(
            playerPosition: const GridPos(x: 6, y: 3),
            playerSpatialPosition: PlayerSpatialPosition(x: 6.5, z: 3.5),
            playerFacing: EntityFacing.north));
    addTearDown(continued.dispose);
    await continued.load((_) {});
    await continued.gameplayReady;
    expect(continued.session!.frames(0)['field:npc:npc']!.x, 6.5);
    expect(continued.overworldInteractionSnapshot!.primaryAction!.targetCell,
        const GridPos(x: 6, y: 2));
    final bounds =
        continued.overworldInteractionSnapshot!.primaryAction!.targetBounds;
    expect(bounds.leftPx, 6 * bundle.manifest.settings.tileWidth);
    expect(bounds.topPx, 2 * bundle.manifest.settings.tileHeight);
    expect(bounds.widthPx, bundle.manifest.settings.tileWidth);
    expect(bounds.heightPx, bundle.manifest.settings.tileHeight);
  });

  test('cancelling a cinematic rolls back its NPC pose, camera and reward',
      () async {
    bundle = npcCinematicBundle(bundle);
    await runtime.load((_) {});
    await waitForStory(runtime);
    runtime.session!.frames(1);
    expect(runtime.session!.frames(0)['field:npc:npc']!.x, 5.5);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    await runtime.gameplayReady;
    expect(runtime.session!.frames(0)['field:npc:npc']!.x, 4.5);
    expect(runtime.gameStateSnapshot.spatialWorldState,
        const SpatialWorldState.empty());
    expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
    expect(runtime.session!.storyCamera!(), isNull);
    expect(runtime.session!.interactionError.value, isNull);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
  });

  test('skipping a cinematic commits its final pose once', () async {
    bundle = npcCinematicBundle(bundle);
    await runtime.load((_) {});
    await waitForStory(runtime);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await runtime.gameplayReady;
    expect(runtime.session!.frames(0)['field:npc:npc']!.x, 6.5);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
    expect(
        runtime
            .gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        hasLength(1));
  });

  test('cell checks preserve a held direction and accept release while busy',
      () async {
    await runtime.load((_) {});
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.right));
    for (var i = 0; i < 20; i++) {
      runtime.session!.frame(.05);
      await Future<void>.delayed(Duration.zero);
    }
    expect(runtime.session!.movement.x, greaterThan(6.5));
    runtime.handleInput(
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    final x = runtime.session!.movement.x;
    runtime.session!.frame(.05);
    expect(runtime.session!.movement.x, x);
  });

  test('entity Scene keeps reward private until its dialogue completes',
      () async {
    bundle = bundle.copyWith(
        manifest: bundle.manifest.copyWith(
            eventRegistry: NarrativeEventRegistry(
                schemaVersion: 1,
                mode: EventSystemMode.v2Only,
                records: [
                  spatialEvent(
                      NarrativeEventSourceRef.entityInteract('field', 'npc'),
                      'talk')
                ],
                legacyClaims: const []),
            scenes: [
          spatialScene('talk', [SceneConsequence.giveMoney(amount: 25)],
              dialogue: true)
        ]));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    for (var i = 0; i < 5; i++) {
      runtime.session!.frame(.05);
      await Future<void>.delayed(Duration.zero);
    }
    await waitForValue(runtime.inputAuthority,
        (value) => value.context == RuntimeInputContext.overworld);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.dialogue);
    await expectLater(runtime.captureCheckpoint(), throwsStateError);
    runtime.session!.confirmDialogue();
    runtime.session!.confirmDialogue();
    await waitForValue(
        runtime.overworldInteractions,
        (value) =>
            value.primaryAction != null &&
            runtime.gameStateSnapshot.trainerProfile.money == 25);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
    expect(runtime.session!.interactionError.value, isNull);
  });

  test('stop during an entity dialogue rolls back its pending reward',
      () async {
    bundle = bundle.copyWith(
        manifest: bundle.manifest.copyWith(
            eventRegistry: NarrativeEventRegistry(
                schemaVersion: 1,
                mode: EventSystemMode.v2Only,
                records: [
                  spatialEvent(
                      NarrativeEventSourceRef.entityInteract('field', 'npc'),
                      'talk')
                ],
                legacyClaims: const []),
            scenes: [
          spatialScene('talk', [SceneConsequence.giveMoney(amount: 25)],
              dialogue: true)
        ]));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    for (var i = 0; i < 5; i++) {
      runtime.session!.frame(.05);
      await Future<void>.delayed(Duration.zero);
    }
    await waitForValue(runtime.inputAuthority,
        (value) => value.context == RuntimeInputContext.overworld);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    await runtime.stop(GameSessionExitReason.hub);
    await Future<void>.delayed(Duration.zero);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
    expect(runtime.dialoguePresentationListenable.value, isNull);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.blocked);
  });

  test(
      'warps load a centered arrival, preserve the session and clear held input',
      () async {
    const warp = MapWarp(
        id: 'out',
        pos: GridPos(x: 5, y: 4),
        targetMapId: 'other',
        targetPos: GridPos(x: 2, y: 3));
    const back = MapWarp(
        id: 'back',
        pos: GridPos(x: 2, y: 3),
        targetMapId: 'field',
        targetPos: GridPos(x: 5, y: 4));
    final source = bundle.copyWith(map: bundle.map.copyWith(warps: [warp]));
    final destination = bundle.copyWith(
        map: bundle.map.copyWith(id: 'other', warps: [back], entities: []));
    var loads = 0;
    final session =
        await SpatialExplorationSession.load(source, loadMap: (id) async {
      loads++;
      return destination;
    });
    addTearDown(session.dispose);
    final dialogue = session.dialoguePresentation;
    session.movement.setInput(x: 1, z: 0, run: true);
    for (var i = 0; i < 10 && !session.transitioning.value; i++) {
      session.frame(.05);
    }
    await waitForValue(session.mapRevision, (value) => value == 1);
    expect(session.bundle.map.id, 'other');
    expect(session.dialoguePresentation, same(dialogue));
    expect(session.movement.x, 2.5);
    expect(session.movement.z, 3.5);
    expect(session.movement.facing, EntityFacing.east);
    for (var i = 0; i < 20; i++) {
      session.frame(.05);
    }
    expect(session.movement.x, 2.5);
    expect(loads, 1);
    expect(session.frames(0).keys, ['hero']);
  });

  test('blocked arrival preserves the source map and restores controls',
      () async {
    const warp = MapWarp(
        id: 'out',
        pos: GridPos(x: 5, y: 4),
        targetMapId: 'other',
        targetPos: GridPos(x: 2, y: 3));
    final cells = List<bool>.filled(64, false)..[26] = true;
    final source = bundle.copyWith(map: bundle.map.copyWith(warps: [warp]));
    final destination = bundle.copyWith(
        map: bundle.map.copyWith(id: 'other', entities: [], layers: [
      CollisionLayer(id: 'solid', name: 'Solid', collisions: cells)
    ]));
    final session = await SpatialExplorationSession.load(source,
        loadMap: (_) async => destination);
    addTearDown(session.dispose);
    final movement = session.movement;
    await session.enterWarp(warp);
    expect(session.bundle.map.id, 'field');
    expect(session.movement, same(movement));
    expect(session.interactionError.value, isNotNull);
    expect(session.transitioning.value, isFalse);
    expect(movement.paused, isFalse);
    expect(session.mapRevision.value, 0);
  });

  test('disposal discards a late destination load', () async {
    const warp = MapWarp(
        id: 'out',
        pos: GridPos(x: 5, y: 4),
        targetMapId: 'other',
        targetPos: GridPos(x: 2, y: 3));
    final pending = Completer<RuntimeMapBundle>();
    final source = bundle.copyWith(map: bundle.map.copyWith(warps: [warp]));
    final session = await SpatialExplorationSession.load(source,
        loadMap: (_) => pending.future);
    final transfer = session.enterWarp(warp);
    session.dispose();
    pending.complete(
        bundle.copyWith(map: bundle.map.copyWith(id: 'other', entities: [])));
    await transfer;
    expect(session.bundle.map.id, 'field');
  });

  test('reset cannot supersede a pending passage and stop cancels its arrival',
      () async {
    const warp = MapWarp(
        id: 'out',
        pos: GridPos(x: 5, y: 4),
        targetMapId: 'other',
        targetPos: GridPos(x: 2, y: 3));
    final pending = Completer<RuntimeMapBundle>();
    final session = await SpatialExplorationSession.load(
        bundle.copyWith(map: bundle.map.copyWith(warps: [warp])),
        loadMap: (_) => pending.future);
    addTearDown(session.dispose);
    session.movement.setInput(x: 1, z: 0);
    session.frame(.05);
    final before = session.movement.x;
    final transfer = session.enterWarp(warp);
    session.resetPosition();
    expect(session.movement.x, before);
    expect(session.movement.paused, isTrue);
    session.cancelPendingTransition();
    pending.complete(
        bundle.copyWith(map: bundle.map.copyWith(id: 'other', entities: [])));
    await transfer;
    expect(session.bundle.map.id, 'field');
    expect(session.mapRevision.value, 0);
    expect(session.movement.paused, isTrue);
  });

  test('unreadable destination preserves the source session', () async {
    const warp = MapWarp(
        id: 'out',
        pos: GridPos(x: 5, y: 4),
        targetMapId: 'other',
        targetPos: GridPos(x: 2, y: 3));
    final session = await SpatialExplorationSession.load(
        bundle.copyWith(map: bundle.map.copyWith(warps: [warp])),
        loadMap: (_) async =>
            throw const FileSystemException('destination missing'));
    addTearDown(session.dispose);
    await session.enterWarp(warp);
    expect(session.bundle.map.id, 'field');
    expect(session.interactionError.value, isA<FileSystemException>());
    expect(session.movement.paused, isFalse);
    expect(session.mapRevision.value, 0);
  });

  test(
      'shared text reveal freezes under pause and confirm reveals before advancing',
      () async {
    await runtime.load((_) {});
    runtime.applyPlayerPreferences(const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(),
        dialogueTextSpeed: RuntimeDialogueTextSpeed.normal));
    final session = runtime.session!;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    for (var i = 0; i < 5; i++) {
      session.frame(.05);
      await Future<void>.delayed(Duration.zero);
    }
    final request =
        runtime.overworldInteractionSnapshot!.primaryAction!.request;
    expect(
        runtime.dispatchOverworldInteraction(RuntimeOverworldInteractionRequest(
            sessionId: 'other',
            mapActivationId: request.mapActivationId,
            mapId: request.mapId,
            targetKind: request.targetKind,
            targetId: request.targetId,
            actionId: request.actionId)),
        isFalse);
    expect(runtime.dispatchOverworldInteraction(request), isTrue);
    expect(runtime.dispatchOverworldInteraction(request), isFalse);
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    expect(
        runtime
            .dialoguePresentationListenable.value!.isCurrentLineFullyRevealed,
        isFalse);
    session.frame(.05);
    final partial = runtime.dialoguePresentationListenable.value!.text;
    expect(partial.length, lessThan('Salut !'.length));
    await runtime.pause();
    session.frame(.05);
    expect(runtime.dialoguePresentationListenable.value!.text, partial);
    await runtime.resume();
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    expect(runtime.dialoguePresentationListenable.value!.text, 'Salut !');
    expect(
        runtime
            .dialoguePresentationListenable.value!.isCurrentLineFullyRevealed,
        isTrue);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    expect(
        runtime.dialoguePresentationListenable.value!.fullText, 'À bientôt !');
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    await Future<void>.delayed(Duration.zero);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
  });

  test(
      'stop invalidates pending dialogue and unreadable content restores control',
      () async {
    await runtime.load((_) {});
    final session = runtime.session!;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    for (var i = 0; i < 5; i++) {
      session.frame(.05);
      await Future<void>.delayed(Duration.zero);
    }
    await File('${root.path}/hello.json').delete();
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await waitForValue(session.interactionError, (value) => value != null);
    expect(session.interactionError.value, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
    final pending = session.interact();
    await runtime.stop(GameSessionExitReason.title);
    await pending;
    expect(runtime.dialoguePresentationListenable.value, isNull);
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.blocked);
  });

  test('direct Studio dialogue controls preserve pause authority', () async {
    final session = await SpatialExplorationSession.load(bundle);
    addTearDown(session.dispose);
    session.movement.setInput(x: 0, z: -1);
    for (var i = 0; i < 5; i++) {
      session.frame(.05);
    }
    session.dialoguePaused = true;
    session.movement.setPaused(true);
    session.closeDialogue();
    expect(session.movement.paused, isTrue);
    await session.interact();
    expect(session.interactionActive.value, isFalse);
    session.dialoguePaused = false;
    session.movement.setPaused(false);
    await session.interact();
    final snapshot = session.dialoguePresentation.value!;
    session.dialoguePaused = true;
    session.dispatchDialogueCommand(
        DialogueAdvanceCommand(snapshotRevision: snapshot.revision));
    session.frame(.05);
    expect(session.dialoguePresentation.value, snapshot);
    session.closeDialogue();
    expect(session.movement.paused, isTrue);
    expect(session.interactionActive.value, isFalse);
  });

  testWidgets('manual pause survives inactive and resumed lifecycle',
      (tester) async {
    final session =
        (await tester.runAsync(() => SpatialExplorationSession.load(bundle)))!;
    addTearDown(session.dispose);
    session.movement.setInput(x: 0, z: -1);
    for (var i = 0; i < 5; i++) {
      session.frame(.05);
    }
    await tester.runAsync(session.interact);
    final before = session.dialoguePresentation.value!;
    await tester.pumpWidget(
        MaterialApp(home: SpatialExplorationView(session: session)));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    session.dispatchDialogueCommand(
        DialogueAdvanceCommand(snapshotRevision: before.revision));
    expect(session.dialoguePresentation.value, before);
    session.dialoguePaused = true;
    session.movement.setPaused(true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    session.frame(.05);
    expect(session.dialoguePaused, isTrue);
    expect(session.presentationPaused, isTrue);
    expect(session.movement.paused, isTrue);
    expect(session.dialoguePresentation.value, before);
    session.dispatchDialogueCommand(
        DialogueAdvanceCommand(snapshotRevision: before.revision));
    expect(session.dialoguePresentation.value, before);
    await tester.pumpWidget(const SizedBox());
  });

  test('routes digital inputs and sprint through authored spatial movement',
      () async {
    await runtime.load((_) {});
    expect(mounts, 1);
    final session = runtime.session!;
    expect(session.movement.x, 4);
    expect(session.movement.z, 4);
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    session.frame(.05);
    expect(session.movement.z, lessThan(4));
    await Future<void>.delayed(Duration.zero);
    runtime
        .handleInput(const RuntimeInputEvent.release(RuntimeInputControl.up));
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.right));
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
    session.frame(.05);
    expect(session.movement.x, greaterThan(4));
    expect(session.movement.running, isTrue);
    await Future<void>.delayed(Duration.zero);
    runtime.handleInput(
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    runtime.handleInput(
        const RuntimeInputEvent.release(RuntimeInputControl.sprint));
    session.frame(.05);
    expect(session.movement.moving, isFalse);
    final checkpoint = (await runtime.captureCheckpoint())!;
    final state = gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(checkpoint.state));
    expect(state.playerSpatialPosition!.x, session.movement.x);
    expect(state.playerSpatialPosition!.z, session.movement.z);
  });

  for (final running in [false, true]) {
    test(
        'one held input continues through three asynchronous cell checks: '
        'running $running', () async {
      bundle = bundle.copyWith(
          map: bundle.map.copyWith(triggers: const [
        MapTrigger(
            id: 'passive-trigger',
            type: TriggerType.event,
            area: MapRect(
                pos: GridPos(x: 0, y: 0), size: GridSize(width: 1, height: 1))),
      ]));
      await runtime.load((_) {});
      await runtime.gameplayReady;
      final session = runtime.session!;
      final checkedCells = <int>{};
      final inputEpoch = session.movement.inputEpoch;
      final continuity =
          runtime.overworldInteractions.value.movementContinuityId;
      runtime
          .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.down));
      if (running) {
        runtime.handleInput(
            const RuntimeInputEvent.press(RuntimeInputControl.sprint));
      }
      for (var frame = 0; frame < 80 && session.movement.z < 7.1; frame++) {
        session.frame(.05);
        if (session.movement.paused) {
          checkedCells.add(session.movement.z.floor());
          expect(runtime.inputAuthority.value.context,
              RuntimeInputContext.overworld);
        }
        expect(session.movement.inputEpoch, inputEpoch);
        expect(runtime.overworldInteractions.value.movementContinuityId,
            continuity);
        expect(session.movement.animationSeconds, greaterThan(0));
        for (var tick = 0; tick < 100 && session.movement.paused; tick++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(session.movement.paused, isFalse);
        expect(session.movement.inputEpoch, inputEpoch);
      }
      expect(checkedCells, containsAll([5, 6, 7]));
      expect(session.movement.z, greaterThanOrEqualTo(7.1));
      runtime.handleInput(
          const RuntimeInputEvent.release(RuntimeInputControl.down));
      final releasedAt = session.movement.z;
      session.frame(.05);
      expect(session.movement.z, releasedAt);
    });
  }

  test('release during an asynchronous cell check prevents resumed movement',
      () async {
    bundle = bundle.copyWith(
        map: bundle.map.copyWith(triggers: const [
      MapTrigger(
          id: 'passive-trigger',
          type: TriggerType.event,
          area: MapRect(
              pos: GridPos(x: 0, y: 0), size: GridSize(width: 1, height: 1))),
    ]));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final session = runtime.session!;
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.down));
    for (var frame = 0; frame < 80 && !session.movement.paused; frame++) {
      session.frame(.05);
    }
    expect(session.movement.paused, isTrue);
    final releasedAt = session.movement.z;
    runtime
        .handleInput(const RuntimeInputEvent.release(RuntimeInputControl.down));
    for (var tick = 0; tick < 100 && session.movement.paused; tick++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(session.movement.paused, isFalse);
    for (var frame = 0; frame < 30; frame++) {
      session.frame(.05);
      await Future<void>.delayed(Duration.zero);
    }
    expect(session.movement.z, releasedAt);
    expect(session.movement.moving, isFalse);
  });

  test('locks remain independent and resume requires fresh input', () async {
    await runtime.load((_) {});
    final session = runtime.session!;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    await runtime.setInputLock(RuntimeExternalInputLock.pauseMenu,
        locked: true);
    await runtime.pause();
    await runtime.setInputLock(RuntimeExternalInputLock.lifecycle,
        locked: true);
    await runtime.resume();
    await runtime.setInputLock(RuntimeExternalInputLock.pauseMenu,
        locked: false);
    final before = session.movement.z;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    session.frame(.05);
    expect(session.movement.z, before);
    expect(runtime.inputAuthority.value.externalLocks,
        {RuntimeExternalInputLock.lifecycle});
    await runtime.setInputLock(RuntimeExternalInputLock.lifecycle,
        locked: false);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.up, isRepeat: true));
    session.frame(.05);
    expect(session.movement.z, before);
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    session.frame(.05);
    expect(session.movement.z, lessThan(before));
    await runtime.stop(GameSessionExitReason.hub);
    final stopped = session.movement.z;
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.down));
    session.frame(.05);
    expect(session.movement.z, stopped);
    await runtime.dispose();
    await runtime.dispose();
    expect(unmounts, 1);
  });

  test('companion exposes live gameplay menus including save and party',
      () async {
    await runtime.load((_) {});
    final menu = await runtime.readCompanionMenuData();
    expect(menu.pauseDetails, isNotEmpty);
    expect(
        menu.pauseMenuState.isActionVisible(ProjectPauseActionId.save,
            projectDefaultVisibility: true),
        isTrue);
    expect(
        menu.pauseMenuState.isActionVisible(ProjectPauseActionId.options,
            projectDefaultVisibility: true),
        isTrue);
    expect(
        menu.pauseMenuState.isActionVisible(ProjectPauseActionId.party,
            projectDefaultVisibility: true),
        isTrue);
  });

  SpatialExplorationGameSessionRuntime serviceRuntime({
    required GameSessionCheckpointCommitter commitCheckpoint,
    PlayerServiceRecoveryCapsLoader? recoveryCapsLoader,
  }) {
    final initial = descriptor().initialGameState!.copyWith(
            party: const PlayerParty(members: [
          PlayerPokemon(
              individualId: 'starter',
              speciesId: 'bulbasaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              knownMoveIds: ['tackle'],
              currentPpByMoveId: {'tackle': 2},
              currentHp: 2,
              statusId: 'poison'),
          PlayerPokemon(
              individualId: 'caught',
              speciesId: 'pidgey',
              natureId: 'hardy',
              abilityId: 'keen-eye',
              currentHp: 7),
        ]));
    return SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(initialState: initial),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        commitCheckpoint: commitCheckpoint,
        recoveryCapsLoader: recoveryCapsLoader ??
            (_) async =>
                const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {
                  0: 30,
                  1: 25
                }, maxPpByPartyIndex: {
                  0: {'tackle': 35}
                }),
        mountSession: (_) async => mounts++,
        unmountSession: (_) async => unmounts++);
  }

  test('healer restores HP and PP with an acknowledged host checkpoint',
      () async {
    final checkpoints = <GameSessionCheckpointCommit>[];
    final healed = serviceRuntime(
        commitCheckpoint: (request) async => checkpoints.add(request));
    addTearDown(healed.dispose);
    await healed.load((_) {});
    final before = healed.gameStateSnapshot;
    final result = await healed.openHealCenter(
        request: const OpenHealService(
            interactionId: 'valbois-heal', requiresConfirmation: false));
    expect(result.status, PlayerServiceRuntimeStatus.completed);
    expect(healed.gameStateSnapshot.party.members.first.currentHp, 30);
    expect(healed.gameStateSnapshot.party.members.first.currentPpByMoveId,
        {'tackle': 35});
    expect(healed.gameStateSnapshot.party.members.first.statusId, isEmpty);
    expect(healed.gameStateSnapshot.playerSpatialPosition,
        before.playerSpatialPosition);
    expect(checkpoints, hasLength(1));
    expect(
        checkpoints.single.descriptor.sessionId, healed.descriptor.sessionId);
    final saved = gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(checkpoints.single.checkpoint.state));
    expect(saved.party, healed.gameStateSnapshot.party);
    expect(saved.playerSpatialPosition, before.playerSpatialPosition);
    expect(healed.inputAuthority.value.acceptsOverworldInput, isTrue);
  });

  test('failed healer checkpoint rolls back the party and releases input',
      () async {
    final healed = serviceRuntime(
        commitCheckpoint: (_) async => throw FileSystemException('disk full'));
    addTearDown(healed.dispose);
    await healed.load((_) {});
    final before = healed.gameStateSnapshot;
    final result = await healed.openHealCenter(
        request: const OpenHealService(
            interactionId: 'valbois-heal', requiresConfirmation: false));
    expect(result.status, PlayerServiceRuntimeStatus.failed);
    expect(healed.gameStateSnapshot, before);
    expect(healed.inputAuthority.value.acceptsOverworldInput, isTrue);
    expect(healed.worldServiceSnapshot, isNull);
  });

  test('stop during healer hydration rejects late state and checkpoint',
      () async {
    final caps = Completer<RuntimePlayerServiceRecoveryCaps>();
    final requested = Completer<void>();
    var writes = 0;
    final healed = serviceRuntime(
        commitCheckpoint: (_) async => writes++,
        recoveryCapsLoader: (_) {
          requested.complete();
          return caps.future;
        });
    addTearDown(healed.dispose);
    await healed.load((_) {});
    final before = healed.gameStateSnapshot;
    final healing = healed.openHealCenter(
        request: const OpenHealService(
            interactionId: 'valbois-heal', requiresConfirmation: false));
    await requested.future;
    await healed.stop(GameSessionExitReason.hub);
    caps.complete(const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: {0: 30, 1: 25}));
    expect((await healing).status, PlayerServiceRuntimeStatus.failed);
    expect(healed.gameStateSnapshot, before);
    expect(writes, 0);
    expect(healed.inputAuthority.value.context, RuntimeInputContext.blocked);
  });

  test('party pause commands preserve spatial state for controller autosave',
      () async {
    var writes = 0;
    final edited = serviceRuntime(commitCheckpoint: (_) async => writes++);
    addTearDown(edited.dispose);
    await edited.load((_) {});
    await edited.pause();
    final before = edited.gameStateSnapshot;
    final result = await edited.dispatchPauseCommand(
        const RuntimePlayerPauseCommand.setPartyLead(
            partyTargetId: 'pokemon.caught'));
    expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(edited.gameStateSnapshot.party.members.first.individualId, 'caught');
    expect(edited.gameStateSnapshot.playerSpatialPosition,
        before.playerSpatialPosition);
    final checkpoint = (await edited.captureCheckpoint())!;
    final state = gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(checkpoint.state));
    expect(state.party, edited.gameStateSnapshot.party);
    expect(writes, 0);
  });

  test('failed mount is unmounted once during disposal', () async {
    final failed = SpatialExplorationGameSessionRuntime(
      descriptor: descriptor(),
      projectFilePath: () async => '${root.path}/project.json',
      preloadedInitialMap: (
              {required projectFilePath,
              required descriptor,
              required initialSave}) async =>
          RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async => throw StateError('GPU unavailable'),
      unmountSession: (_) async => unmounts++,
    );
    await expectLater(failed.load((_) {}), throwsStateError);
    await failed.dispose();
    await failed.dispose();
    expect(unmounts, 1);
    expect(failed.session, isNull);
  });

  test('stop while preload is pending never mounts the loaded world', () async {
    final preload = Completer<RuntimeInitialMapPreloadResult>();
    final requested = Completer<void>();
    final pending = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: (
            {required projectFilePath,
            required descriptor,
            required initialSave}) {
          requested.complete();
          return preload.future;
        },
        mountSession: (_) async => mounts++,
        unmountSession: (_) async => unmounts++);
    addTearDown(pending.dispose);
    final loading = pending.load((_) {});
    final rejected = expectLater(loading, throwsStateError);
    await requested.future;
    await pending.stop(GameSessionExitReason.hub);
    preload.complete(RuntimeInitialMapPreloadResult(bundle: bundle));
    await rejected;
    expect(pending.session, isNull);
    expect(mounts, 0);
  });

  test('pause during mount keeps play time and movement paused', () async {
    final mounted = Completer<void>();
    final requested = Completer<void>();
    final pending = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) {
          requested.complete();
          return mounted.future;
        },
        unmountSession: (_) async => unmounts++);
    addTearDown(pending.dispose);
    final loading = pending.load((_) {});
    await requested.future;
    await pending.pause();
    mounted.complete();
    await loading;
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect((await pending.captureCheckpoint())!.playTimeSeconds, 0);
    expect(pending.session!.movement.paused, isTrue);
    expect(pending.inputAuthority.value.context, RuntimeInputContext.blocked);
  });

  test('dispose waits for a pending mount before unmounting once', () async {
    final mounted = Completer<void>();
    final requested = Completer<void>();
    final pending = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) {
          requested.complete();
          return mounted.future;
        },
        unmountSession: (_) async => unmounts++);
    final loading = pending.load((_) {});
    final rejected = expectLater(loading, throwsStateError);
    await requested.future;
    final disposing = pending.dispose();
    await Future<void>.delayed(Duration.zero);
    final unmountsWhileMounting = unmounts;
    mounted.complete();
    await rejected;
    await disposing;
    await pending.dispose();
    expect(unmountsWhileMounting, 0);
    expect(unmounts, 1);
    expect(pending.session, isNull);
  });

  test('concurrent loads cannot create two world sessions', () async {
    final path = Completer<String>();
    final pending = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(),
        projectFilePath: () => path.future,
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async => mounts++,
        unmountSession: (_) async => unmounts++);
    addTearDown(pending.dispose);
    final loading = pending.load((_) {});
    final other = pending.load((_) {});
    final rejected = expectLater(other, throwsStateError);
    path.complete('${root.path}/project.json');
    await loading;
    await rejected;
    expect(mounts, 1);
  });

  test('rejects continue without its authorized save', () async {
    final continued = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(continueGame: true),
        projectFilePath: () async => '${root.path}/project.json',
        mountSession: (_) async {},
        unmountSession: (_) async {});
    addTearDown(continued.dispose);
    await expectLater(continued.load((_) {}), throwsStateError);
    expect(continued.session, isNull);
  });

  test('new game uses its authored map instead of the first map entry',
      () async {
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/other.json').writeAsString(
        jsonEncode(bundle.map.copyWith(id: 'other', entities: []).toJson()));
    bundle = bundle.copyWith(
        manifest: bundle.manifest.copyWith(maps: const [
      ProjectMapEntry(
          id: 'other', name: 'Other', relativePath: 'maps/other.json'),
      ProjectMapEntry(
          id: 'field', name: 'Field', relativePath: 'maps/field.json'),
    ]));
    await runtime.load((_) {});
    expect(runtime.session!.bundle.map.id, 'field');
    expect(runtime.gameStateSnapshot.currentMapId, 'field');
    expect(runtime.gameStateSnapshot.trainerProfile.name, 'Yoahn');
  });

  test('continue restores exact spatial position, progress and save authority',
      () async {
    bundle = bundle.copyWith(
        manifest: bundle.manifest.copyWith(
            settings: bundle.manifest.settings
                .copyWith(tileWidth: 32, tileHeight: 24)));
    final state = GameState(
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        currentMapId: 'field',
        playerPosition: const GridPos(x: 4, y: 5),
        playerSpatialPosition: PlayerSpatialPosition(x: 4.3125, z: 5.4375),
        playerFacing: EntityFacing.west,
        trainerProfile:
            const TrainerProfile(name: 'Yoahn', avatarCharacterId: 'hero'),
        bag: const Bag(entries: [BagEntry(itemId: 'poke-ball', quantity: 7)]),
        storyFlags: const StoryFlags(activeFlags: {'found-herb'}));
    final save = spatialSave(state);
    final continued = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(continueGame: true),
        projectFilePath: () async => '${root.path}/project.json',
        initialSave: () async => save,
        preloadedInitialMap: (
            {required projectFilePath,
            required descriptor,
            required initialSave}) async {
          expect(initialSave, same(save));
          return RuntimeInitialMapPreloadResult(bundle: bundle);
        },
        now: () => DateTime.utc(2026, 10, 8, 2),
        mountSession: (_) async => mounts++,
        unmountSession: (_) async => unmounts++);
    addTearDown(continued.dispose);
    await continued.load((_) {});
    expect(continued.session!.movement.x, 4.3125);
    expect(continued.session!.movement.z, 5.4375);
    expect(continued.session!.movement.facing, EntityFacing.west);
    expect(continued.gameStateSnapshot.storyFlags.activeFlags,
        contains('found-herb'));
    expect(continued.gameStateSnapshot.bag.entries.single.quantity, 7);
    final checkpoint = (await continued.captureCheckpoint())!;
    expect(checkpoint.createdAt, save.createdAt);
    expect(checkpoint.updatedAt, DateTime.utc(2026, 10, 8, 2));
    expect(checkpoint.playTimeSeconds, greaterThanOrEqualTo(60));
    final restored = gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(checkpoint.state));
    expect(restored.playerSpatialPosition, state.playerSpatialPosition);
    expect(restored.playerFacing, EntityFacing.west);
    expect(mounts, 1);
  });

  test('rejects a 2D save and a blocked spatial save before mounting',
      () async {
    for (final position in [null, PlayerSpatialPosition(x: 4.5, z: 2.5)]) {
      final state = GameState(
          saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
          currentMapId: 'field',
          playerPosition: const GridPos(x: 4, y: 2),
          playerSpatialPosition: position);
      final continued = SpatialExplorationGameSessionRuntime(
          descriptor: descriptor(continueGame: true),
          projectFilePath: () async => '${root.path}/project.json',
          initialSave: () async => spatialSave(state),
          preloadedInitialMap: (
                  {required projectFilePath,
                  required descriptor,
                  required initialSave}) async =>
              RuntimeInitialMapPreloadResult(bundle: bundle),
          mountSession: (_) async => mounts++,
          unmountSession: (_) async => unmounts++);
      await expectLater(continued.load((_) {}), throwsStateError);
      expect(continued.session, isNull);
      await continued.dispose();
    }
    expect(mounts, 0);
  });

  test('rejects save identity changes before requesting preload', () async {
    final state = GameState(
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        currentMapId: 'field',
        playerPosition: const GridPos(x: 4, y: 4),
        playerSpatialPosition: PlayerSpatialPosition(x: 4, z: 4));
    var preloads = 0;
    final continued = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(continueGame: true),
        projectFilePath: () async => '${root.path}/project.json',
        initialSave: () async => spatialSave(state, profileId: 'other-profile'),
        preloadedInitialMap: (
            {required projectFilePath,
            required descriptor,
            required initialSave}) async {
          preloads++;
          return RuntimeInitialMapPreloadResult(bundle: bundle);
        },
        mountSession: (_) async => mounts++,
        unmountSession: (_) async => unmounts++);
    addTearDown(continued.dispose);
    await expectLater(continued.load((_) {}), throwsStateError);
    expect(preloads, 0);
    expect(mounts, 0);
  });
}

SpatialExplorationGameSessionRuntime restoredRuntime(
        RuntimeMapBundle bundle, Directory root, GameState state) =>
    SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(continueGame: true),
        projectFilePath: () async => '${root.path}/project.json',
        initialSave: () async => spatialSave(state),
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async {},
        unmountSession: (_) async {});

Future<void> waitForStory(SpatialExplorationGameSessionRuntime runtime) =>
    Future.any([
      waitForValue(runtime.session!.storyActive, (value) => value),
      runtime.gameplayReady.then((_) {
        if (!runtime.session!.storyActive.value) {
          throw StateError(
              runtime.session!.interactionError.value?.toString() ??
                  'The scene completed without starting playback.');
        }
      }),
    ]);

Future<void> waitForValue<T>(
    ValueListenable<T> value, bool Function(T) matches) async {
  if (matches(value.value)) return;
  final ready = Completer<void>();
  void changed() {
    if (matches(value.value) && !ready.isCompleted) ready.complete();
  }

  value.addListener(changed);
  try {
    changed();
    await ready.future.timeout(const Duration(seconds: 3));
  } finally {
    value.removeListener(changed);
  }
}

GameSessionDescriptor descriptor(
        {bool continueGame = false, GameState? initialState}) =>
    GameSessionDescriptor(
        sessionId: 'session',
        sessionToken: 'token',
        identity: GameIdentity(
            gameId: 'org.example.spatial',
            gameVersion: '1.0.0',
            projectFormat: ProjectFormat.v9,
            saveFormat: 1,
            compatibilityId: 'spatial'),
        profileId: 'profile',
        slotId: 'slot',
        launchMode: continueGame
            ? GameSessionLaunchMode.continueGame
            : GameSessionLaunchMode.newGame,
        saveReadHandle: continueGame ? 'save' : null,
        initialGameState: continueGame
            ? null
            : initialState ??
                GameState(
                    saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
                    currentMapId: 'field',
                    playerPosition: const GridPos(x: 4, y: 4),
                    playerSpatialPosition: PlayerSpatialPosition(x: 4, z: 4),
                    trainerProfile: const TrainerProfile(
                        name: 'Yoahn', avatarCharacterId: 'hero')),
        installedVersionHandle: 'installed',
        runtimeApiVersion: '1.4.0',
        grantedCapabilities: const {'map3d@1', 'map3d.story@1'},
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions());

SaveEnvelope spatialSave(GameState state, {String profileId = 'profile'}) =>
    const GameStateSaveEnvelopeMapper().create(
        identity: descriptor().identity,
        profileId: profileId,
        slotId: 'slot',
        saveId: state.saveId,
        createdAt: DateTime.utc(2026, 10, 8),
        updatedAt: DateTime.utc(2026, 10, 8, 1),
        status: SaveStatus.active,
        playTimeSeconds: 60,
        gameState: state);

NarrativeEventRecord spatialEvent(
        NarrativeEventSourceRef source, String sceneId) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: 'evt_019abcde-0000-7000-8000-000000000001',
            name: sceneId,
            source: source,
            conditions: const [],
            sceneId: sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
            resetPolicy: const NarrativeEventResetPolicy.never()),
        enabled: true);

RuntimeMapBundle npcCinematicBundle(RuntimeMapBundle bundle) {
  final asset = CinematicAsset(
      id: 'guide-walk',
      title: 'Le guide marche',
      mapId: 'field',
      requiredActors: [CinematicActorRef(actorId: 'guide')],
      movementTargets: [
        CinematicMovementTargetRef(targetId: 'end', label: 'Arrivée')
      ],
      stageContext: CinematicStageContext(actorBindings: [
        CinematicActorBinding(
            actorId: 'guide',
            kind: CinematicActorBindingKind.mapEntity,
            mapEntityId: 'npc')
      ], stagePoints: [
        CinematicStagePoint(id: 'end', label: 'Arrivée', x: 6.5, y: 2.5)
      ], movementTargetBindings: [
        CinematicMovementTargetBinding(
            targetId: 'end',
            kind: CinematicMovementTargetBindingKind.stagePoint,
            sourceId: 'end')
      ]),
      timeline: CinematicTimeline(steps: [
        CinematicTimelineStep(
            id: 'camera',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 500,
            metadata: const {
              'camera.mode': 'focus',
              'camera.targetKind': 'stagePoint',
              'camera.targetStagePointId': 'end',
              'camera.zoomPreset': 'close'
            }),
        CinematicTimelineStep(
            id: 'walk',
            kind: CinematicTimelineStepKind.actorMove,
            actorId: 'guide',
            targetId: 'end',
            durationMs: 1000,
            metadata: const {
              'actor.movementMode': 'walk',
              'actor.pathMode': 'direct'
            }),
      ]));
  final reward =
      spatialScene('walk-scene', [SceneConsequence.giveMoney(amount: 25)]);
  final cinematic = SceneNode(
      id: 'cinematic',
      kind: SceneNodeKind.cinematic,
      payload: SceneCinematicPayload(cinematicId: asset.id));
  final graph = SceneGraph(startNodeId: reward.graph.startNodeId, nodes: [
    reward.graph.nodes.first,
    cinematic,
    ...reward.graph.nodes.skip(1)
  ], edges: [
    SceneEdge(
        id: 'to-cinematic',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: cinematic.id,
        kind: SceneEdgeKind.defaultFlow),
    SceneEdge(
        id: 'to-reward',
        fromNodeId: cinematic.id,
        fromPortId: 'completed',
        toNodeId: 'action_0',
        kind: SceneEdgeKind.cinematicCompleted),
    ...reward.graph.edges.skip(1)
  ]);
  return bundle.copyWith(
      manifest: bundle.manifest.copyWith(
          cinematics: [asset],
          scenes: [SceneAsset(id: reward.id, name: reward.name, graph: graph)],
          eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              records: [
                spatialEvent(
                    NarrativeEventSourceRef.mapEnter('field'), reward.id)
              ],
              legacyClaims: const [])));
}

RuntimeMapBundle animatedDoorBundle(RuntimeMapBundle bundle,
    {bool rewardBefore = false}) {
  final model = ProjectModel3dEntry(
    id: 'door-model',
    name: 'Porte',
    sourceAssetId: 'nb2-door',
    relativePath: 'assets/models3d/door-model.glb',
    inspection: Model3dInspection(
        bounds: Model3dBounds(
            min: Model3dVector3(x: -.5, y: 0, z: -.1),
            max: Model3dVector3(x: .5, y: 2, z: .1)),
        meshCount: 1,
        triangleCount: 2,
        animations: [
          Model3dAnimation(index: 0, name: 'Ouvrir', durationSeconds: 2)
        ]),
  );
  final map = bundle.map.copyWith(
      entities: [],
      spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          instances: [
            SpatialModelInstance(
                id: 'door',
                modelId: model.id,
                blocksMovement: true,
                position: Model3dVector3(x: 4, y: 0, z: 5))
          ],
          navigation:
              SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4))));
  final reward = SceneNode(
      id: 'reward',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.consequence(
          SceneConsequence.giveMoney(amount: 25)));
  final open = SceneNode(
      id: 'open',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.playModelAnimation(
              mapId: 'field',
              instanceId: 'door',
              animationIndex: 0,
              blocksMovementAfter: false)));
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    if (rewardBefore) reward,
    open,
    if (!rewardBefore) reward,
    SceneNode(id: 'end', kind: SceneNodeKind.end)
  ];
  final scene = SceneAsset(
      id: 'door-scene',
      name: 'Ouvrir la porte',
      graph: SceneGraph(startNodeId: 'start', nodes: nodes, edges: [
        for (var index = 0; index < nodes.length - 1; index++)
          SceneEdge(
              id: 'edge_$index',
              fromNodeId: nodes[index].id,
              fromPortId: 'completed',
              toNodeId: nodes[index + 1].id,
              kind: nodes[index].kind == SceneNodeKind.action
                  ? SceneEdgeKind.actionCompleted
                  : SceneEdgeKind.defaultFlow)
      ]));
  return bundle.copyWith(
      map: map,
      manifest: bundle.manifest.copyWith(
          models3d: [model],
          scenes: [scene],
          eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              records: [
                spatialEvent(
                    NarrativeEventSourceRef.modelInteract('field', 'door'),
                    scene.id)
              ],
              legacyClaims: const [])));
}

SceneAsset spatialScene(String id, List<SceneConsequence> consequences,
    {bool dialogue = false}) {
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (var index = 0; index < consequences.length; index++)
      SceneNode(
          id: 'action_$index',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(consequences[index])),
    if (dialogue)
      SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'hello')),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(startNodeId: 'start', nodes: nodes, edges: [
        for (var i = 0; i < nodes.length - 1; i++)
          SceneEdge(
              id: 'edge_$i',
              fromNodeId: nodes[i].id,
              fromPortId: 'completed',
              toNodeId: nodes[i + 1].id,
              kind: nodes[i].kind == SceneNodeKind.action
                  ? SceneEdgeKind.actionCompleted
                  : SceneEdgeKind.defaultFlow)
      ]));
}
