import 'dart:io';
import 'dart:async';

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
    expect(session.frames(0).keys, containsAll(['hero', 'npc:npc']));
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
    expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
    session.frame(.05);
    expect(session.movement.moving, isFalse);
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
    }
    await File('${root.path}/hello.json').delete();
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary));
    await waitForValue(session.interactionError, (value) => value != null);
    expect(session.interactionError.value, isNotNull);
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
    runtime
        .handleInput(const RuntimeInputEvent.release(RuntimeInputControl.up));
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.right));
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
    session.frame(.05);
    expect(session.movement.x, greaterThan(4));
    expect(session.movement.running, isTrue);
    runtime.handleInput(
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    runtime.handleInput(
        const RuntimeInputEvent.release(RuntimeInputControl.sprint));
    session.frame(.05);
    expect(session.movement.moving, isFalse);
    expect(await runtime.captureCheckpoint(), isNull);
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

  test('companion exposes only exploration menus and no save', () async {
    await runtime.load((_) {});
    final menu = await runtime.readCompanionMenuData();
    expect(menu.pauseDetails, isEmpty);
    expect(
        menu.pauseMenuState.isActionVisible(ProjectPauseActionId.save,
            projectDefaultVisibility: true),
        isFalse);
    expect(
        menu.pauseMenuState.isActionVisible(ProjectPauseActionId.options,
            projectDefaultVisibility: false),
        isTrue);
    expect(
        menu.pauseMenuState.isActionVisible(ProjectPauseActionId.party,
            projectDefaultVisibility: true),
        isFalse);
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

  test('rejects continue instead of restoring a 2D save', () async {
    final continued = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(continueGame: true),
        projectFilePath: () async => '${root.path}/project.json',
        mountSession: (_) async {},
        unmountSession: (_) async {});
    addTearDown(continued.dispose);
    await expectLater(continued.load((_) {}), throwsStateError);
    expect(continued.session, isNull);
  });
}

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

GameSessionDescriptor descriptor({bool continueGame = false}) =>
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
        installedVersionHandle: 'installed',
        runtimeApiVersion: '1.4.0',
        grantedCapabilities: const {'map3d@1'},
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions());
