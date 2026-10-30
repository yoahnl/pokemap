import 'package:map_runtime/src/player/real_weather_service.dart';
import 'package:map_runtime/src/player/real_weather_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../support/spatial_smart_tile_fixture.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';
import '../support/scene_catalog_pokemon_gift_fixture.dart';
import '../playable_map_game_fishing_test.dart' show fishingTool;

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

  Future<void> configureFishing({double chance = 0, MovementMode mode = MovementMode.walk,
      bool battleData = false, FlameCinematicAudioDriver? musicDriver,
      GameSessionCheckpointCommitter? commitCheckpoint}) async {
    var state = descriptor().initialGameState!;
    if (battleData) {
      final reference = Directory('../../examples/playable_runtime_host/golden_battle_slice');
      for (final file in reference.listSync(recursive: true).whereType<File>()) {
        final target = File('${root.path}/${file.path.substring(reference.path.length + 1)}');
        await target.parent.create(recursive: true);
        await file.copy(target.path);
      }
      final manifest = ProjectManifest.fromJson(jsonDecode(
          await File('${root.path}/project.json').readAsString()) as Map<String, dynamic>);
      bundle = bundle.copyWith(manifest: bundle.manifest.copyWith(pokemon: manifest.pokemon));
      final saved = gameStateFromSaveData(SaveData.fromJson(jsonDecode(
          await File('${root.path}/runtime_host_launch_save.json').readAsString()) as Map<String, dynamic>));
      state = state.copyWith(party: saved.party);
    }
    await File('${root.path}/items.json').writeAsString(jsonEncode(
        const ProjectItemCatalog(schemaVersion: 1, entries: [fishingTool]).toJson()));
    bundle = bundle.copyWith(
      manifest: bundle.manifest.copyWith(
        battleAudio: musicDriver == null ? bundle.manifest.battleAudio : const ProjectBattleAudioConfig(wildBattleMusicPath: 'fishing-battle.ogg'),
        pokemon: bundle.manifest.pokemon.copyWith(catalogFiles: {
          ...bundle.manifest.pokemon.catalogFiles, 'items': 'items.json'}),
        encounterTables: [ProjectEncounterTable(id: 'rod', name: 'Rod',
          encounterKind: EncounterKind.oldRod, chancePerStep: chance,
          entries: const [ProjectEncounterEntry(speciesId: 'sparkitten', minLevel: 5, maxLevel: 5)])]),
      map: bundle.map.copyWith(entities: [], gameplayZones: const [
        MapGameplayZone(id: 'water', kind: GameplayZoneKind.movement,
          area: MapRect(pos: GridPos(x: 4, y: 3), size: GridSize(width: 1, height: 1)),
          movement: MovementZonePayload(requiredMode: MovementMode.surf)),
        MapGameplayZone(id: 'fish', kind: GameplayZoneKind.encounter,
          area: MapRect(pos: GridPos(x: 4, y: 3), size: GridSize(width: 1, height: 1)),
          encounter: EncounterZonePayload(encounterKind: EncounterKind.oldRod, encounterTableId: 'rod')),
      ]));
    await runtime.dispose();
    runtime = SpatialExplorationGameSessionRuntime(
      descriptor: descriptor(initialState: state.copyWith(
        playerFacing: EntityFacing.north, playerMovementMode: mode,
        bag: const Bag(entries: [BagEntry(itemId: 'tool', quantity: 1)]))),
      projectFilePath: () async => '${root.path}/project.json',
      preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      commitCheckpoint: commitCheckpoint,
      musicServiceFactory: musicDriver == null ? null : (mixer) => RuntimeMusicService(mixer: mixer, driver: musicDriver, fadeDelay: (_) async {}),
      mountSession: (_) async {}, unmountSession: (_) async {});
    await runtime.load((_) {});
    await runtime.gameplayReady;
  }

  Future<RuntimePlayerPauseCommandResult> useFishingRod() async {
    await runtime.pause();
    return runtime.dispatchPauseCommand(const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'tool'));
  }

  test('spatial fishing is usable from the real companion bag action', () async {
    await configureFishing();
    await runtime.pause();
    final data = await runtime.readCompanionMenuData();
    final entry = data.pauseDetails[RuntimePlayerPauseSection.bag]!.entries.single;
    final action = entry.bagAction!;
    expect(entry.title, 'Outil');
    expect(action.isEnabled, isTrue);
    expect(action.unavailableReason, isNull);
    expect(action.targetKind, RuntimePlayerBagUseTargetKind.world);
    final result = await runtime.dispatchPauseCommand(
        RuntimePlayerPauseCommand.useBagItem(itemTargetId: action.itemTargetId));
    expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(result.resumeGameplay, isTrue);
    await runtime.resume();
    runtime.session!.frames(.4);
    expect(runtime.dialoguePresentationListenable.value?.text, contains('ligne'));
    runtime.session!.frames(1.1);
    expect(runtime.dialoguePresentationListenable.value?.text, 'Pas de touche…');
    runtime.session!.frames(.7);
    expect(runtime.inputAuthority.value.acceptsOverworldInput, isTrue);
  });

  test('spatial fishing reserves, blocks saves, presents no bite and releases movement', () async {
    await configureFishing();
    final initial = runtime.gameStateSnapshot;
    final result = await useFishingRod();
    expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(result.resumeGameplay, isTrue);
    await expectLater(runtime.captureCheckpoint(), throwsStateError);
    runtime.session!.frames(5);
    expect(runtime.dialoguePresentationListenable.value?.text, contains('Lancer'));
    await runtime.resume();
    expect(runtime.inputAuthority.value.acceptsOverworldInput, isFalse);
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.right));
    runtime.session!.frames(.4);
    expect(runtime.dialoguePresentationListenable.value?.text, contains('ligne'));
    runtime.session!.frames(1.1);
    expect(runtime.dialoguePresentationListenable.value?.text, 'Pas de touche…');
    runtime.session!.frames(.7);
    expect(runtime.dialoguePresentationListenable.value, isNull);
    expect(runtime.inputAuthority.value.acceptsOverworldInput, isTrue);
    expect(runtime.gameStateSnapshot, initial);
    expect((await runtime.captureCheckpoint())!.state['playerSpatialPosition'], initial.playerSpatialPosition!.toJson());
  });

  test('spatial fishing cancellation and lifecycle cannot launch a late battle', () async {
    await configureFishing(chance: 1);
    expect((await useFishingRod()).status, RuntimePlayerPauseCommandStatus.accepted);
    await runtime.resume();
    runtime.session!.frames(.4);
    expect(runtime.inputAuthority.value.canCancelWorldAction, isTrue);
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    runtime.session!.frames(5);
    expect(runtime.battle!.isActive, isFalse);
    expect(runtime.inputAuthority.value.acceptsOverworldInput, isTrue);
    expect((await useFishingRod()).status, RuntimePlayerPauseCommandStatus.accepted);
    await runtime.resume();
    await runtime.setInputLock(RuntimeExternalInputLock.lifecycle, locked: true);
    runtime.session!.frames(5);
    await runtime.setInputLock(RuntimeExternalInputLock.lifecycle, locked: false);
    runtime.session!.frames(5);
    expect(runtime.battle!.isActive, isFalse);
    expect(runtime.dialoguePresentationListenable.value, isNull);
    expect(runtime.inputAuthority.value.acceptsOverworldInput, isTrue);
    expect(await runtime.captureCheckpoint(), isNotNull);
  });

  test('spatial fishing hands one generated wild encounter to the actual 3D battle runtime', () async {
    await configureFishing(chance: 1, battleData: true);
    final initial = runtime.gameStateSnapshot;
    expect((await useFishingRod()).status, RuntimePlayerPauseCommandStatus.accepted);
    await runtime.resume();
    runtime.session!.frames(.4);
    runtime.session!.frames(1.1);
    expect(runtime.dialoguePresentationListenable.value?.text, 'Ça mord !');
    runtime.session!.frames(.7);
    for (var i = 0; i < 500 && runtime.battle!.context == null && runtime.session!.interactionError.value == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(runtime.battle!.error, isNull);
    expect(runtime.session!.interactionError.value, isNull);
    final request = runtime.battle!.context!.request as WildBattleStartRequest;
    expect(request.encounterKind, EncounterKind.oldRod);
    expect(request.tableId, 'rod');
    expect(request.speciesId, 'sparkitten');
    expect(request.generatedPokemon, isNotNull);
    expect(request.returnContext.playerPos, initial.playerPosition);
    expect(runtime.gameStateSnapshot.playerSpatialPosition, initial.playerSpatialPosition);
    expect(runtime.gameStateSnapshot.bag, initial.bag);
    expect(runtime.dialoguePresentationListenable.value, isNull);
    final context = runtime.battle!.context;
    runtime.session!.frames(5);
    expect(runtime.battle!.context, same(context));
    await expectLater(runtime.captureCheckpoint(), throwsStateError);
  });

  for (final fail in [false, true]) {
    test('spatial fishing dismounts only after durable persistence, failure=$fail', () async {
      final commits = <GameSessionCheckpointCommit>[];
      await configureFishing(mode: MovementMode.bicycle, commitCheckpoint: (commit) async {
        if (fail) throw StateError('disk full');
        commits.add(commit);
      });
      final result = await useFishingRod();
      expect(result.status, fail ? RuntimePlayerPauseCommandStatus.unavailable : RuntimePlayerPauseCommandStatus.accepted);
      expect(runtime.gameStateSnapshot.playerMovementMode, fail ? MovementMode.bicycle : MovementMode.walk);
      if (!fail) {
        expect(commits.single.checkpoint.state['playerMovementMode'], 'walk');
        await runtime.resume();
        runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
        expect(runtime.gameStateSnapshot.playerMovementMode, MovementMode.walk);
      }
      expect(runtime.gameStateSnapshot.bag.entries.single.quantity, 1);
    });
  }

  test('spatial fishing lifecycle interruption during durable dismount does not resurrect the attempt', () async {
    final entered = Completer<void>(), release = Completer<void>();
    await configureFishing(mode: MovementMode.bicycle, commitCheckpoint: (_) async {
      entered.complete();
      await release.future;
    });
    final use = useFishingRod();
    await entered.future;
    await expectLater(runtime.captureCheckpoint(), throwsStateError);
    await runtime.setInputLock(RuntimeExternalInputLock.lifecycle, locked: true);
    release.complete();
    expect((await use).status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(runtime.gameStateSnapshot.playerMovementMode, MovementMode.walk);
    expect(runtime.inputAuthority.value.externalLocks, contains(RuntimeExternalInputLock.lifecycle));
    await runtime.setInputLock(RuntimeExternalInputLock.lifecycle, locked: false);
    await runtime.resume();
    runtime.session!.frames(5);
    expect(runtime.dialoguePresentationListenable.value, isNull);
    expect(runtime.battle!.isActive, isFalse);
    expect(await runtime.captureCheckpoint(), isNotNull);
  });

  test('spatial fishing refuses reservation under lifecycle and completion locks', () async {
    await configureFishing();
    for (final owner in [RuntimeExternalInputLock.lifecycle, RuntimeExternalInputLock.gameCompletion]) {
      await runtime.setInputLock(owner, locked: true);
      expect((await useFishingRod()).status, RuntimePlayerPauseCommandStatus.unavailable);
      expect(runtime.dialoguePresentationListenable.value, isNull);
      await runtime.setInputLock(owner, locked: false);
    }
  });

  for (final owner in [RuntimeExternalInputLock.lifecycle, RuntimeExternalInputLock.gameCompletion]) {
    test('spatial fishing cancels delayed battle music handoff under $owner', () async {
      final driver = _DelayedFishingMusicDriver();
      addTearDown(() { if (!driver.release.isCompleted) driver.release.complete(); });
      await configureFishing(chance: 1, battleData: true, musicDriver: driver);
      final initial = runtime.gameStateSnapshot;
      var battleStarted = false;
      runtime.battle!.addListener(() { if (runtime.battle!.isActive) battleStarted = true; });
      expect((await useFishingRod()).status, RuntimePlayerPauseCommandStatus.accepted);
      await runtime.resume();
      runtime.session!.frames(.4);
      runtime.session!.frames(1.1);
      runtime.session!.frames(.7);
      await driver.entered.future.timeout(const Duration(seconds: 3));
      expect(runtime.battle!.isActive, isFalse);
      expect(runtime.inputAuthority.value.acceptsOverworldInput, isFalse);
      await expectLater(runtime.captureCheckpoint(), throwsStateError);
      runtime.session!.frames(5);
      expect(runtime.battle!.isActive, isFalse);
      await runtime.setInputLock(owner, locked: true);
      await runtime.setInputLock(owner, locked: false);
      driver.release.complete();
      GameSessionCheckpoint? checkpoint;
      for (var i = 0; i < 500 && !battleStarted && checkpoint == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
        try {
          checkpoint = await runtime.captureCheckpoint();
        } on StateError {
          continue;
        }
      }
      expect(battleStarted, isFalse);
      expect(runtime.battle!.isActive, isFalse);
      expect(checkpoint, isNotNull);
      expect(runtime.session!.interactionError.value, isNull);
      expect(runtime.gameStateSnapshot, initial);
      expect(runtime.dialoguePresentationListenable.value, isNull);
      expect(runtime.inputAuthority.value.acceptsOverworldInput, isTrue);
    });
  }

  void configureTrainer({MapEntityNpcData? npcData, bool authoredEvent = true}) {
    final npc = bundle.map.entities.single.copyWith(
      pos: const GridPos(x: 4, y: 1),
      npc: (npcData ?? bundle.map.entities.single.npc!).copyWith(trainerId: 'guard',
        facing: EntityFacing.south, lineOfSightRange: 4));
    final scene = SceneAsset(id: 'challenge', name: 'Challenge',
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'talk', kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'hello')),
        SceneNode(id: 'battle', kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(battleKind: 'trainer', trainerId: 'guard', npcEntityId: 'npc', declaredOutcomes: const ['victory', 'defeat'])),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(id: 'open', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'talk', kind: SceneEdgeKind.defaultFlow),
        SceneEdge(id: 'fight', fromNodeId: 'talk', fromPortId: 'completed', toNodeId: 'battle', kind: SceneEdgeKind.defaultFlow),
        SceneEdge(id: 'won', fromNodeId: 'battle', fromPortId: 'victory', toNodeId: 'end', kind: SceneEdgeKind.battleVictory),
        SceneEdge(id: 'lost', fromNodeId: 'battle', fromPortId: 'defeat', toNodeId: 'end', kind: SceneEdgeKind.battleDefeat),
      ]));
    bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [npc]),
      manifest: bundle.manifest.copyWith(scenes: [scene],
        trainers: [ProjectTrainerEntry(id: 'guard', name: 'Guard', trainerClass: 'Scout',
          team: [ProjectTrainerPokemonEntry(speciesId: 'rattata', level: 4)])],
        eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
          records: [if (authoredEvent) spatialEvent(NarrativeEventSourceRef.entityInteract('field', 'npc'), 'challenge')], legacyClaims: [])));
  }

  test('spatial trainer spotting approaches without teleporting the player and opens its authored scene', () async {
    configureTrainer();
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final initial = runtime.gameStateSnapshot.playerSpatialPosition;
    for (var i = 0; i < 500 && runtime.dialoguePresentationListenable.value == null; i++) {
      runtime.session!.frames(.016);
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    expect(runtime.session!.interactionError.value, isNull);
    expect(runtime.dialoguePresentationListenable.value?.fullText, 'Salut !', reason: jsonEncode({
      'story': runtime.session!.storyActive.value, 'locked': runtime.session!.storyInputLocked,
      'actor': runtime.gameStateSnapshot.spatialWorldState.actorState('field', 'npc')?.toJson(),
      'hero': runtime.gameStateSnapshot.playerSpatialPosition?.toJson(),
      'input': runtime.inputAuthority.value.context.name}));
    expect(runtime.gameStateSnapshot.playerSpatialPosition, initial);
    final pose = runtime.gameStateSnapshot.spatialWorldState.actorState('field', 'npc');
    expect(pose?.x, initial!.x);
    expect(pose?.z, initial.z - 1);
    expect(runtime.session!.storyActive.value, isFalse);
  });

  test('spatial trainer spotting cancellation unlocks input without committing actor motion', () async {
    configureTrainer();
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final initial = runtime.gameStateSnapshot.playerSpatialPosition;
    for (var i = 0; i < 10; i++) {
      runtime.session!.frames(.016);
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    expect(runtime.session!.storyActive.value, true);
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    runtime.handleInput(const RuntimeInputEvent.release(RuntimeInputControl.secondary));
    for (var i = 0; i < 100; i++) {
      runtime.session!.frames(.016);
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    expect(runtime.session!.storyActive.value, false);
    expect(runtime.inputAuthority.value.acceptsOverworldInput, true);
    expect(runtime.gameStateSnapshot.playerSpatialPosition, initial);
    expect(runtime.gameStateSnapshot.spatialWorldState.actorState('field', 'npc'), isNull);
    expect(runtime.dialoguePresentationListenable.value, isNull);
    expect(runtime.session!.interactionError.value, isNull);
  });

  test('trainer encounter music starts on spotting and restores on cancellation', () async {
    configureTrainer();
    await runtime.dispose();
    final driver = _SceneAudioDriver();
    late RuntimeMusicService music;
    bundle = bundle.copyWith(
      map: bundle.map.copyWith(mapMetadata: bundle.map.mapMetadata.copyWith(musicPath: 'map.ogg')),
      manifest: bundle.manifest.copyWith(battleAudio: const ProjectBattleAudioConfig(encounterMusicPath: 'eye.ogg')),
    );
    runtime = SpatialExplorationGameSessionRuntime(
      descriptor: descriptor(), projectFilePath: () async => '${root.path}/project.json',
      preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      musicServiceFactory: (mixer) => music = RuntimeMusicService(mixer: mixer, driver: driver, fadeDelay: (_) async {}),
      mountSession: (_) async {}, unmountSession: (_) async {},
    );
    await runtime.load((_) {});
    await runtime.gameplayReady;
    expect(music.playingPath, '${root.path}/map.ogg');
    for (var i = 0; i < 10; i++) {
      runtime.session!.frames(.016);
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    expect(music.playingPath, '${root.path}/eye.ogg');
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    runtime.handleInput(const RuntimeInputEvent.release(RuntimeInputControl.secondary));
    for (var i = 0; i < 100; i++) {
      runtime.session!.frames(.016);
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    expect(music.playingPath, '${root.path}/map.ogg');
    expect(runtime.session!.interactionError.value, isNull);
  });

  for (final reason in ['missing-event', 'unavailable-time', 'unready-party']) {
    test('spatial trainer spotting respects $reason', () async {
      configureTrainer(authoredEvent: reason != 'missing-event',
        npcData: bundle.map.entities.single.npc!.copyWith(
          trainerBattleWhen: reason == 'unavailable-time'
            ? const MapEntityRuntimePredicate(kind: MapEntityRuntimePredicateKind.localTimeWindow,
              timeWindow: LocalTimeWindow(startMinute: 0, endMinute: 1)) : null,
          trainerBattleReadyWhen: reason == 'unready-party'
            ? const MapEntityRuntimePredicate(kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast,
              minimumCount: 2) : null));
      await runtime.load((_) {});
      await runtime.gameplayReady;
      final initial = runtime.gameStateSnapshot.playerSpatialPosition;
      for (var i = 0; i < 100; i++) {
        runtime.session!.frames(.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(runtime.session!.storyActive.value, isFalse);
      expect(runtime.dialoguePresentationListenable.value, isNull);
      expect(runtime.gameStateSnapshot.playerSpatialPosition, initial);
      expect(runtime.session!.interactionError.value, isNull);
    });
  }

  test('real weather waits for player consent and never requests from simulation frames', () async {
    await runtime.dispose();
    final provider = _WeatherProvider();
    final cache = _WeatherCache();
    final service = RealWeatherService(provider: provider, cache: cache, now: () => DateTime.utc(2026));
    addTearDown(service.dispose);
    bundle = bundle.copyWith(projectVisualProfile: SpatialVisualPatch.fromJson({'weatherMode': 'real'}));
    runtime = SpatialExplorationGameSessionRuntime(descriptor: descriptor(), projectFilePath: () async => '${root.path}/project.json',
      realWeatherService: service,
      preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async {}, unmountSession: (_) async {});
    await runtime.load((_) {});
    await runtime.gameplayReady;
    expect(provider.requests, 0);
    final preferences = const PlayerPreferencesSnapshot(locale: 'fr', accessibility: GameSessionAccessibilityOptions(), realWeather: RealWeatherPreferences(enabled: true));
    await runtime.pause();
    runtime.applyPlayerPreferences(preferences);
    await Future<void>.delayed(Duration.zero);
    expect(provider.requests, 0);
    await runtime.resume();
    await Future<void>.delayed(Duration.zero);
    expect(provider.requests, 1);
    await service.refresh(preferences.realWeather);
    expect(provider.requests, 1);
    expect(runtime.session!.realWeatherAllowed, isTrue);
    for (var i = 0; i < 30; i++) { runtime.session!.frames(.5); }
    expect(provider.requests, 1);
    runtime.applyPlayerPreferences(preferences.copyWith(realWeather: const RealWeatherPreferences()));
    expect(runtime.session!.realWeatherAllowed, isFalse);
    expect(service.value.snapshot, isNull);
    expect(provider.requests, 1);
  });
  test('a chosen player hour reaches the mounted session and follows later changes', () async {
    const real = PlayerPreferencesSnapshot(locale: 'fr', accessibility: GameSessionAccessibilityOptions());
    final noon = real.copyWith(worldTime: const RuntimeWorldTimePreferences(chosenMinuteOfDay: 720));
    runtime.applyPlayerPreferences(noon);
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final session = runtime.session!;
    expect(session.worldTimeOverrides, const RuntimeWorldTimePreferences(chosenMinuteOfDay: 720).visualOverrides);
    final profile = SpatialVisualPatch.fromJson({'timeMode': 'real'});
    expect(session.environmentClock.resolve(profile.overriddenBy(session.worldTimeOverrides), overrides: session.worldTimeOverrides).minuteOfDay, 720);
    runtime.applyPlayerPreferences(real);
    expect(session.worldTimeOverrides.isEmpty, isTrue);
  });
  test('graphics preferences reach the mounted session and follow later changes', () async {
    const defaults = PlayerPreferencesSnapshot(locale: 'fr', accessibility: GameSessionAccessibilityOptions());
    const graphics = RuntimeGraphicsPreferences(renderScalePercent: 75, shadows: false, depthOfField: false);
    runtime.applyPlayerPreferences(defaults.copyWith(graphics: graphics));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final session = runtime.session!;
    expect(session.graphics.value, graphics);
    runtime.applyPlayerPreferences(defaults);
    expect(session.graphics.value, const RuntimeGraphicsPreferences());
  });
  test('session frames checkpoint and Continue share one environment timeline', () async {
    bundle = bundle.copyWith(projectVisualProfile: SpatialVisualPatch.fromJson({
      'timeMode': 'cycle', 'dayDurationSeconds': 1200, 'minuteOfDay': 360,
      'weatherMode': 'automatic', 'weatherIntervalSeconds': 10, 'weatherSequence': ['clear', 'rain'],
    }));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final session = runtime.session!;
    for (var i = 0; i < 30; i++) { session.frames(.5); }
    expect(session.environmentClock.elapsedSeconds, 15);
    final frame = session.environmentClock.resolve(bundle.visualProfile);
    expect(frame.minuteOfDay, 378);
    expect(frame.weatherKind, SpatialWeatherKind.rain);
    final saved = gameStateFromStrictSaveJson(Map<String, dynamic>.from((await runtime.captureCheckpoint())!.state));
    expect(saved.environmentState!.elapsedSeconds, 15);
    await runtime.dispose();
    runtime = SpatialExplorationGameSessionRuntime(
      descriptor: descriptor(continueGame: true),
      projectFilePath: () async => '${root.path}/project.json',
      initialSave: () async => spatialSave(saved),
      preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async {}, unmountSession: (_) async {},
    );
    await runtime.load((_) {});
    await runtime.gameplayReady;
    expect(runtime.session!.environmentClock.elapsedSeconds, 15);
    expect(runtime.session!.environmentClock.resolve(bundle.visualProfile).weatherKind, SpatialWeatherKind.rain);
  });

  for (final partitioned in [false, true]) {
    test(
      'current map Border definitions survive passage and Continue ${partitioned ? 'partitioned' : 'native'}',
      () async {
        await runtime.dispose();
        await spatialWarpBundle(root, bundle);
        final fixture = spatialBorderPassageFixture(bundle);
        final manifest = fixture.manifest;
        final maps = [fixture.source, fixture.destination];
        for (final map in maps) {
          await File('${root.path}/maps/${map.id}.json')
              .writeAsString(jsonEncode(map.toJson()));
        }
        final publication = partitioned
            ? PortableCatalogPublication.encodeProject(manifest)
            : null;
        await File('${root.path}/project.json').writeAsString(
          jsonEncode(publication?.descriptor ?? manifest.toJson()),
        );
        for (final object
            in publication?.storage.objects.entries ??
                <MapEntry<String, List<int>>>[]) {
          final file = File('${root.path}/catalog/objects/${object.key}.json');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(object.value);
        }
        runtime = SpatialExplorationGameSessionRuntime(
          descriptor: descriptor(
            initialState: descriptor().initialGameState!.copyWith(
              playerSpatialPosition: PlayerSpatialPosition(x: 4.5, z: 4.5),
            ),
          ),
          projectFilePath: () async => '${root.path}/project.json',
          mountSession: (_) async {},
          unmountSession: (_) async {},
        );
        await runtime.load((_) {});
        await runtime.gameplayReady;
        expect(runtime.session!.bundle.manifest.borderCatalog.records, isEmpty);

        Future<void> moveUntil(
          RuntimeInputControl control,
          bool Function() reached,
        ) async {
          runtime.handleInput(RuntimeInputEvent.press(control));
          try {
            for (var frame = 0; frame < 160 && !reached(); frame++) {
              runtime.session!.frame(.05);
              await Future<void>.delayed(const Duration(milliseconds: 2));
            }
          } finally {
            runtime.handleInput(RuntimeInputEvent.release(control));
          }
          expect(reached(), isTrue);
          for (var frame = 0; frame < 30; frame++) {
            runtime.session!.frame(0);
            await Future<void>.delayed(const Duration(milliseconds: 2));
          }
          await runtime.gameplayReady;
          expect(runtime.session!.interactionError.value, isNull);
        }

        await moveUntil(
          RuntimeInputControl.down,
          () => runtime.session!.bundle.map.id == 'other',
        );
        expect(
          runtime.session!.bundle.manifest.borderCatalog.records.single.id,
          'fence',
        );
        await moveUntil(
          RuntimeInputControl.down,
          () => runtime.gameStateSnapshot.trainerProfile.money == 7,
        );
        await moveUntil(
          RuntimeInputControl.up,
          () => runtime.session!.bundle.map.id == 'field',
        );
        await moveUntil(
          RuntimeInputControl.down,
          () => runtime.session!.bundle.map.id == 'other',
        );
        await moveUntil(
          RuntimeInputControl.down,
          () => runtime.gameStateSnapshot.trainerProfile.money == 14,
        );
        final checkpoint = (await runtime.captureCheckpoint())!;
        final saved = gameStateFromStrictSaveJson(
          Map<String, dynamic>.from(checkpoint.state),
        );
        await runtime.dispose();
        runtime = SpatialExplorationGameSessionRuntime(
          descriptor: descriptor(continueGame: true),
          projectFilePath: () async => '${root.path}/project.json',
          initialSave: () async => spatialSave(saved),
          mountSession: (_) async {},
          unmountSession: (_) async {},
        );
        await runtime.load((_) {});
        await runtime.gameplayReady;
        expect(runtime.gameStateSnapshot.trainerProfile.money, 14);
        await moveUntil(
          RuntimeInputControl.up,
          () => runtime.gameStateSnapshot.playerPosition.y == 4,
        );
        await moveUntil(
          RuntimeInputControl.down,
          () => runtime.gameStateSnapshot.trainerProfile.money == 21,
        );
      },
    );
  }

  test('ledge does not dispatch a trigger on its airborne barrier cell', () async {
    await runtime.dispose();
    final scene = SceneAsset(id: 'airborne', name: 'Airborne', graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'talk', kind: SceneNodeKind.yarnDialogue, payload: SceneYarnDialoguePayload(dialogueId: 'hello')),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(id: 'a', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'talk', kind: SceneEdgeKind.defaultFlow),
      SceneEdge(id: 'b', fromNodeId: 'talk', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.defaultFlow),
    ]));
    bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [], triggers: const [
      MapTrigger(id: 'barrier', type: TriggerType.event, area: MapRect(pos: GridPos(x: 4, y: 5), size: GridSize(width: 1, height: 1)))
    ], spatialScene: bundle.map.spatialScene!.copyWith(navigation: SpatialNavigationProfile(
      spawn: SpatialSpawn(x: 4.5, z: 4.5), ledges: [SpatialLedge(id: 'drop', x: 4, z: 4, direction: SpatialRampDirection.south)]))),
      manifest: bundle.manifest.copyWith(scenes: [scene], eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
        records: [spatialEvent(NarrativeEventSourceRef.triggerEnter('field', 'barrier'), scene.id)], legacyClaims: const [])));
    runtime = SpatialExplorationGameSessionRuntime(descriptor: descriptor(initialState: descriptor().initialGameState!.copyWith(playerSpatialPosition: PlayerSpatialPosition(x: 4.5, z: 4.5))),
      projectFilePath: () async => '${root.path}/project.json',
      preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async {}, unmountSession: (_) async {});
    await runtime.load((_) {});
    await runtime.gameplayReady;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.down));
    for (var i = 0; i < 6; i++) {
      runtime.session!.frame(.05);
      for (var j = 0; j < 50; j++) { await Future<void>.delayed(Duration.zero); }
      if (runtime.dialoguePresentationListenable.value != null) break;
    }
    expect(runtime.dialoguePresentationListenable.value, isNull, reason: 'Airborne at z=${runtime.session!.movement.z}; jumping=${runtime.session!.movement.isJumping}');
  });

  test('ledge publishes its landing once after ignoring all airborne cells', () async {
    await runtime.dispose();
    final scene = spatialScene('landed', [SceneConsequence.giveMoney(amount: 25)]);
    final event = NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
      id: 'evt_019abcde-0000-7000-8000-000000000002', name: 'Landing',
      source: NarrativeEventSourceRef.triggerEnter('field', 'landing'), conditions: const [],
      sceneId: scene.id, reusePolicy: NarrativeEventReusePolicy.reusable, priority: 0, order: 0,
      resetPolicy: const NarrativeEventResetPolicy.never()), enabled: true);
    bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [], triggers: const [
      MapTrigger(id: 'landing', type: TriggerType.event, area: MapRect(pos: GridPos(x: 4, y: 6), size: GridSize(width: 1, height: 1)))
    ], spatialScene: bundle.map.spatialScene!.copyWith(navigation: SpatialNavigationProfile(
      spawn: SpatialSpawn(x: 4.5, z: 4.5), ledges: [SpatialLedge(id: 'drop', x: 4, z: 4, direction: SpatialRampDirection.south)]))),
      manifest: bundle.manifest.copyWith(scenes: [scene], eventRegistry: NarrativeEventRegistry(schemaVersion: 1,
        mode: EventSystemMode.v2Only, records: [event], legacyClaims: const [])));
    runtime = SpatialExplorationGameSessionRuntime(descriptor: descriptor(initialState: descriptor().initialGameState!.copyWith(playerSpatialPosition: PlayerSpatialPosition(x: 4.5, z: 4.5))),
      projectFilePath: () async => '${root.path}/project.json',
      preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async {}, unmountSession: (_) async {});
    await runtime.load((_) {});
    await runtime.gameplayReady;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.down));
    for (var frame = 0; frame < 7; frame++) {
      runtime.session!.frame(.05);
      runtime.handleInput(const RuntimeInputEvent.release(RuntimeInputControl.down));
      for (var j = 0; j < 10; j++) { await Future<void>.delayed(Duration.zero); }
      expect(runtime.session!.movement.isJumping, isTrue);
      expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
    }
    for (var frame = 0; frame < 12; frame++) {
      runtime.session!.frame(.05);
      for (var j = 0; j < 10; j++) { await Future<void>.delayed(Duration.zero); }
    }
    expect(runtime.session!.movement.isJumping, isFalse);
    expect(runtime.session!.movement.z, 6.5);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
    expect(runtime.session!.interactionError.value, isNull);
  });

  for (final fail in [false, true]) {
    test('native item model pickup ${fail ? 'rolls back failed save' : 'persists then opens feedback'} in a real spatial session', () async {
      await runtime.dispose();
      final item = MapEntity(id: 'native-orb', kind: MapEntityKind.item, pos: const GridPos(x: 4, y: 3), blocksMovement: false,
        item: const MapEntityItemData(gameItemId: 'supply'));
      final instance = SpatialModelInstance(id: 'orb', modelId: 'orb-model', entityId: item.id, blocksMovement: false,
        position: Model3dVector3(x: 4.5, y: 0, z: 3.5));
      bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [item], spatialScene: bundle.map.spatialScene!.copyWith(instances: [instance])));
      final catalog = File('${root.path}/data/pokemon/catalogs/items.json');
      await catalog.parent.create(recursive: true);
      await catalog.writeAsString(jsonEncode(const ProjectItemCatalog(schemaVersion: 1, entries: [
        ProjectItemDefinition(id: 'supply', displayName: 'Ressource', pocketId: 'supplies')]).toJson()));
      final commits = <GameSessionCheckpointCommit>[];
      runtime = SpatialExplorationGameSessionRuntime(descriptor: descriptor(initialState: descriptor().initialGameState!.copyWith(playerFacing: EntityFacing.north)),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
        commitCheckpoint: (commit) async {
          if (fail) throw const FileSystemException('disk unavailable');
          commits.add(commit);
        }, mountSession: (_) async {}, unmountSession: (_) async {});
      await runtime.load((_) {});
      await runtime.gameplayReady;
      final session = runtime.session!;
      expect(session.modelIsPresent('field', 'orb'), isTrue);
      final action = runtime.overworldInteractionSnapshot!.primaryAction;
      expect(action?.request.targetId, item.id);
      expect(runtime.dispatchOverworldInteraction(action!.request), isTrue);
      if (fail) {
        await waitForValue(session.interactionError, (value) => value != null);
        expect(session.interactionError.value, isA<StateError>().having((error) => error.message, 'message', contains('disk unavailable')));
        expect(runtime.gameStateSnapshot.bag.entries, isEmpty);
        expect(session.modelIsPresent('field', 'orb'), isTrue);
        expect(runtime.gameStateSnapshot.consumedEventIds, isEmpty);
      } else {
        final modal = await runtime.worldServiceSnapshots.firstWhere((value) => value?.content is SceneMessageInteractionRequest).timeout(const Duration(seconds: 3));
        final message = modal!.content! as SceneMessageInteractionRequest;
        expect(message.prompt.fallbackText, contains('Ressource'));
        expect(commits, hasLength(1));
        expect(session.modelIsPresent('field', 'orb'), isFalse);
        final saved = gameStateFromStrictSaveJson(Map<String, dynamic>.from(commits.single.checkpoint.state));
        expect(saved.bag.entries.single.quantity, 1);
        expect(saved.consumedEventIds, isNotEmpty);
        await expectLater(runtime.captureCheckpoint(), throwsStateError);
        await runtime.dispatchWorldService(RuntimeWorldServiceCommand(action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: modal.revision, interactionResult: SceneInteractionResult.acknowledged(requestId: message.requestId, revision: message.revision)));
        await waitForValue(runtime.inputAuthority, (value) => value.acceptsOverworldInput);
        final afterPickup = runtime.overworldInteractionSnapshot!.primaryAction;
        expect(afterPickup, isNull);
        expect(commits, hasLength(1));
        expect(runtime.gameStateSnapshot.bag.entries.single.quantity, 1);
        await runtime.dispose();
        runtime = SpatialExplorationGameSessionRuntime(descriptor: descriptor(continueGame: true),
          projectFilePath: () async => '${root.path}/project.json', initialSave: () async => spatialSave(saved),
          preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
          commitCheckpoint: (commit) async => commits.add(commit), mountSession: (_) async {}, unmountSession: (_) async {});
        await runtime.load((_) {});
        await runtime.gameplayReady;
        expect(runtime.session!.modelIsPresent('field', 'orb'), isFalse);
        expect(runtime.overworldInteractionSnapshot!.primaryAction, isNull);
        expect(runtime.gameStateSnapshot.bag.entries.single.quantity, 1);
        expect(commits, hasLength(1));
      }
    });
  }

  for (final cancel in [false, true]) {
    test('3D scene music restores after ${cancel ? 'cancellation' : 'completion'}', () async {
      await runtime.dispose();
      final driver = _SceneAudioDriver();
      late RuntimeMusicService music;
      final nodes = [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'music', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(
          SceneMusicInteractiveCommand(operation: SceneMusicOperation.play, mediaAssetId: 'theme', volume: .7))),
        SceneNode(id: 'dialogue', kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'hello')),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ];
      final scene = SceneAsset(id: 'music-arrival', name: 'Music arrival', graph: SceneGraph(
        startNodeId: 'start', nodes: nodes, edges: [
          for (var i = 0; i < nodes.length - 1; i++) SceneEdge(id: 'edge_$i',
            fromNodeId: nodes[i].id, fromPortId: 'completed', toNodeId: nodes[i + 1].id,
            kind: nodes[i].kind == SceneNodeKind.action ? SceneEdgeKind.actionCompleted : SceneEdgeKind.defaultFlow),
          SceneEdge(id: 'blocked', fromNodeId: 'music', fromPortId: 'blocked', toNodeId: 'end', kind: SceneEdgeKind.actionCompleted),
        ]));
      bundle = bundle.copyWith(map: bundle.map.copyWith(mapMetadata: bundle.map.mapMetadata.copyWith(musicPath: 'map.ogg')),
        manifest: bundle.manifest.copyWith(cinematicMediaAssets: [CinematicMediaAsset(
          id: 'theme', label: 'Theme', kind: CinematicMediaAssetKind.music, relativePath: 'theme.ogg')],
          scenes: [scene], eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
            records: [spatialEvent(NarrativeEventSourceRef.mapEnter('field'), scene.id)], legacyClaims: const [])));
      runtime = SpatialExplorationGameSessionRuntime(descriptor: descriptor(additionalCapabilities: {
          SpatialGameplayCapabilities.sceneMusicCapabilityId}), projectFilePath: () async => '${root.path}/project.json',
        musicServiceFactory: (mixer) => music = RuntimeMusicService(mixer: mixer, driver: driver),
        preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async {}, unmountSession: (_) async {});
      await runtime.load((_) {});
      await waitForValue(runtime.dialoguePresentationListenable, (value) => value != null);
      expect(music.playingPath, '${root.path}/theme.ogg');
      await runtime.setInputLock(RuntimeExternalInputLock.lifecycle, locked: true);
      await Future<void>.delayed(Duration.zero);
      expect(driver.paused, isNotEmpty);
      await runtime.setInputLock(RuntimeExternalInputLock.lifecycle, locked: false);
      await Future<void>.delayed(Duration.zero);
      expect(driver.resumed, isNotEmpty);
      expect(music.playingPath, '${root.path}/theme.ogg');
      if (cancel) {
        runtime.session!.cancelDialogue();
      } else {
        runtime.session!.confirmDialogue();
        runtime.session!.confirmDialogue();
      }
      await runtime.gameplayReady;
      expect(music.playingPath, '${root.path}/map.ogg');
      await runtime.dispose();
      await driver.complete.close();
    });
  }

  for (final stopBeforeCompletion in [false, true]) {
    test('spatial scene audio ${stopBeforeCompletion ? 'shutdown releases pending sound' : 'waits before applying reward'}', () async {
      await runtime.dispose();
      final audio = _SceneAudioDriver();
      final sound = SceneAsset(id:'arrival-sound',name:'Arrival',graph:SceneGraph(startNodeId:'start',nodes:[
        SceneNode(id:'start',kind:SceneNodeKind.start),
        SceneNode(id:'sound',kind:SceneNodeKind.action,payload:SceneActionPayload.interactive(ScenePlaySoundEffectInteractiveCommand(mediaAssetId:'cue',volume:.8,waitForCompletion:true))),
        SceneNode(id:'reward',kind:SceneNodeKind.action,payload:SceneActionPayload.consequence(SceneConsequence.giveMoney(amount:25))),
        SceneNode(id:'end',kind:SceneNodeKind.end),
      ],edges:[
        SceneEdge(id:'start-sound',fromNodeId:'start',fromPortId:'completed',toNodeId:'sound',kind:SceneEdgeKind.defaultFlow),
        SceneEdge(id:'sound-reward',fromNodeId:'sound',fromPortId:'completed',toNodeId:'reward',kind:SceneEdgeKind.actionCompleted),
        SceneEdge(id:'sound-blocked',fromNodeId:'sound',fromPortId:'blocked',toNodeId:'end',kind:SceneEdgeKind.actionCompleted),
        SceneEdge(id:'reward-end',fromNodeId:'reward',fromPortId:'completed',toNodeId:'end',kind:SceneEdgeKind.actionCompleted),
      ]));
      expect(buildSceneRuntimePlan(sound).canBuild,true,reason:buildSceneRuntimePlan(sound).diagnostics.map((d)=>d.message).join('; '));
      bundle = bundle.copyWith(manifest:bundle.manifest.copyWith(
        cinematicMediaAssets:[CinematicMediaAsset(id:'cue',label:'Cue',kind:CinematicMediaAssetKind.sound,relativePath:'assets/cue.wav')],
        scenes:[sound],eventRegistry:NarrativeEventRegistry(schemaVersion:1,mode:EventSystemMode.v2Only,records:[spatialEvent(NarrativeEventSourceRef.mapEnter('field'),sound.id)],legacyClaims:const[]),
      ));
      final diagnostics = SceneProjectDiagnosticsContext(bundle.manifest,mapsById:{bundle.map.id:bundle.map}).diagnose(sound);
      expect(diagnostics.errorCount,0,reason:diagnostics.diagnostics.map((d)=>d.message).join('; '));
      runtime = SpatialExplorationGameSessionRuntime(descriptor:descriptor(additionalCapabilities:{SpatialGameplayCapabilities.audioCapabilityId}),
        sceneAudioDriverFactory:()=>audio,projectFilePath:()async=>'${root.path}/project.json',
        preloadedInitialMap:({required projectFilePath,required descriptor,required initialSave})async=>RuntimeInitialMapPreloadResult(bundle:bundle),
        mountSession:(_)async{},unmountSession:(_)async{});
      await runtime.load((_){});
      await Future.any([audio.started.future,runtime.gameplayReady.then((_) => throw StateError('Scene finished without audio: ${runtime.session!.interactionError.value}'))]).timeout(const Duration(seconds:3));
      expect(runtime.gameStateSnapshot.trainerProfile.money,0);
      if(stopBeforeCompletion) {
        await runtime.stop(GameSessionExitReason.hub);
        await runtime.gameplayReady;
        expect(runtime.gameStateSnapshot.trainerProfile.money,0);
      } else {
        audio.complete.add(null);
        await runtime.gameplayReady;
        expect(runtime.gameStateSnapshot.trainerProfile.money,25);
      }
      await runtime.dispose();
      await audio.complete.close();
    });
  }

  for (final facing in EntityFacing.values) {
    test('scene interaction faces moved NPC ${facing.name} and restores after cancellation', () async {
      await runtime.dispose();
      final directions = EntityFacing.values;
      await File('${root.path}/hero.png').writeAsBytes(img.encodePng(img.Image(width: 128, height: 32)));
      final character = bundle.manifest.characters.single.copyWith(animations: [
        for (var index = 0; index < directions.length; index++)
          CharacterAnimation(state: CharacterAnimationState.walk, direction: directions[index],
              sourceAssetId: 'hero-sheet', frames: [CharacterAnimationFrame(
                  source: TilesetSourceRect(x: index * 32, y: 0, width: 32, height: 32), durationMs: 100)])
      ]);
      final npc = bundle.map.entities.single.copyWith(npc: bundle.map.entities.single.npc!.copyWith(facing: EntityFacing.west));
      final scene = SceneAsset(id: 'facing-scene', name: 'Facing', graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'talk', kind: SceneNodeKind.yarnDialogue, payload: SceneYarnDialoguePayload(dialogueId: 'hello')),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(id: 'open', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'talk', kind: SceneEdgeKind.defaultFlow),
        SceneEdge(id: 'close', fromNodeId: 'talk', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.defaultFlow),
      ]));
      bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [npc]), manifest: bundle.manifest.copyWith(
        characters: [character], scenes: [scene], eventRegistry: NarrativeEventRegistry(schemaVersion: 1,
            mode: EventSystemMode.v2Only, records: [spatialEvent(NarrativeEventSourceRef.entityInteract('field', 'npc'), scene.id)], legacyClaims: const [])));
      final (x, z, expected) = switch (facing) {
        EntityFacing.north => (4.5, 5.5, EntityFacing.south),
        EntityFacing.south => (4.5, 3.5, EntityFacing.north),
        EntityFacing.east => (3.5, 4.5, EntityFacing.west),
        EntityFacing.west => (5.5, 4.5, EntityFacing.east),
      };
      final world = const SpatialWorldState.empty().setActorState('field', 'npc',
          SpatialActorRuntimeState(x: 4.5, z: 4.5, facing: EntityFacing.west));
      final state = descriptor().initialGameState!.copyWith(playerPosition: GridPos(x: x.floor(), y: z.floor()),
          playerSpatialPosition: PlayerSpatialPosition(x: x, z: z), playerFacing: facing, spatialWorldState: world);
      runtime = SpatialExplorationGameSessionRuntime(descriptor: descriptor(initialState: state),
          projectFilePath: () async => '${root.path}/project.json',
          preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
          mountSession: (_) async {}, unmountSession: (_) async {});
      await runtime.load((_) {});
      await runtime.gameplayReady;
      expect(runtime.overworldInteractionSnapshot!.primaryAction!.request.targetId, 'npc');
      runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.primary));
      runtime.handleInput(const RuntimeInputEvent.release(RuntimeInputControl.primary));
      await waitForValue(runtime.dialoguePresentationListenable, (value) => value != null);
      expect(runtime.session!.npcFrame(npc).frame.left, directions.indexOf(expected) * 32);
      await runtime.setInputLock(RuntimeExternalInputLock.lifecycle, locked: true);
      expect(runtime.session!.npcFrame(npc).frame.left, directions.indexOf(expected) * 32);
      await runtime.setInputLock(RuntimeExternalInputLock.lifecycle, locked: false);
      runtime.session!.cancelDialogue();
      for (var i = 0; i < 300 && runtime.session!.interactionEntity != null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(runtime.session!.interactionEntity, isNull);
      expect(runtime.session!.npcFrame(npc).frame.left, directions.indexOf(EntityFacing.west) * 32);
      expect(runtime.gameStateSnapshot.spatialWorldState.actorState('field', 'npc'), world.actorState('field', 'npc'));
    });
  }

  test('spatial counter dispatches its V2 dialogue while preserving the barrier', () async {
    await runtime.dispose();
    final npc = bundle.map.entities.single.copyWith(npc: bundle.map.entities.single.npc!.copyWith(counterInteractionSides: [EntityFacing.south]));
    final scene = SceneAsset(id: 'counter-scene', name: 'Counter', graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'talk', kind: SceneNodeKind.yarnDialogue, payload: SceneYarnDialoguePayload(dialogueId: 'hello')),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(id: 'open', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'talk', kind: SceneEdgeKind.defaultFlow),
      SceneEdge(id: 'close', fromNodeId: 'talk', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.defaultFlow),
    ]));
    bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [npc], spatialScene: bundle.map.spatialScene!.copyWith(navigation: SpatialNavigationProfile(blockedAreas: [SpatialBlockedArea(x: 4, z: 3, width: 1, depth: 1)]))), manifest: bundle.manifest.copyWith(scenes: [scene], eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only, records: [spatialEvent(NarrativeEventSourceRef.entityInteract('field', 'npc'), scene.id)], legacyClaims: const [])));
    runtime = SpatialExplorationGameSessionRuntime(descriptor: descriptor(initialState: descriptor().initialGameState!.copyWith(playerSpatialPosition: PlayerSpatialPosition(x: 4.5, z: 4.5), playerFacing: EntityFacing.north)), projectFilePath: () async => '${root.path}/project.json', preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle), mountSession: (_) async {}, unmountSession: (_) async {});
    await runtime.load((_) {});
    await runtime.gameplayReady;
    expect(runtime.session!.movement.canTraverseActor(4.5, 4.5, 4.5, 3.5), false);
    expect(runtime.overworldInteractionSnapshot!.primaryAction!.request.targetId, 'npc');
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.primary));
    runtime.handleInput(const RuntimeInputEvent.release(RuntimeInputControl.primary));
    for (var i=0;i<100 && runtime.dialoguePresentationListenable.value==null;i++) { await Future<void>.delayed(const Duration(milliseconds: 1)); }
    expect(runtime.dialoguePresentationListenable.value!.fullText, 'Salut !');
    expect(runtime.session!.interactionError.value, isNull);
    expect(runtime.session!.movement.canTraverseActor(4.5, 4.5, 4.5, 3.5), false);
  });

  test('autonomous spatial poses persist mid-step without a Scene transaction', () async {
    final npc = bundle.map.entities.single;
    bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [npc.copyWith(
      npc: npc.npc!.copyWith(movement: const MapEntityNpcMovementConfig(
        mode: MapEntityNpcMovementMode.fixedRoute,
        routeSteps: [MapEntityNpcRouteStep.move(direction: EntityFacing.east)],
        pauseDurationMs: 1, stepDurationMs: 1000,
      )),
    )]));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final session = runtime.session!;
    session.frames(.001);
    final visible = session.frames(.05)['field:npc:npc']!;
    expect(visible.x, greaterThan(4.5));
    final checkpoint = (await runtime.captureCheckpoint())!;
    final saved = gameStateFromStrictSaveJson(Map<String, dynamic>.from(checkpoint.state));
    expect(saved.spatialWorldState.actorState('field', 'npc')!.x, visible.x);
    await runtime.pause();
    expect(session.frames(1)['field:npc:npc']!.x, visible.x);
    await runtime.resume();
    expect(session.frames(.05)['field:npc:npc']!.x, greaterThan(visible.x));
  });

  test('overworld movement pause freezes autonomous NPCs without pausing presentation', () async {
    final npc = bundle.map.entities.single;
    bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [npc.copyWith(
      npc: npc.npc!.copyWith(movement: const MapEntityNpcMovementConfig(
        mode: MapEntityNpcMovementMode.fixedRoute,
        routeSteps: [MapEntityNpcRouteStep.move(direction: EntityFacing.east)],
        pauseDurationMs: 1, stepDurationMs: 1000,
      )),
    )]));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final session = runtime.session!;
    session.frames(.001);
    final visible = session.frames(.05)['field:npc:npc']!;
    expect(visible.x, greaterThan(4.5));
    session.movement.setPaused(true);
    expect(session.presentationPaused, false);
    expect(session.frames(1)['field:npc:npc']!.x, visible.x);
    expect(runtime.gameStateSnapshot.spatialWorldState.actorState('field', 'npc')!.x, visible.x);
    session.movement.setPaused(false);
    expect(session.frames(.05)['field:npc:npc']!.x, greaterThan(visible.x));
  });

  for (final continueGame in [false, true]) {
    test('capacity rejects spatial boot before mount, continue=$continueGame',
        () async {
      await runtime.dispose();
      bundle = bundle.copyWith(
        manifest: bundle.manifest.copyWith(
          bagCapacity: const ProjectBagCapacity(
            pockets: {'supplies': BagPocketCapacity(maxQuantityPerItem: 2)},
          ),
        ),
      );
      final catalog = File('${root.path}/data/pokemon/catalogs/items.json');
      await catalog.parent.create(recursive: true);
      await catalog.writeAsString(jsonEncode(
        const ProjectItemCatalog(schemaVersion: 1, entries: [
          ProjectItemDefinition(
            id: 'supply',
            displayName: 'Supply',
            pocketId: 'supplies',
          ),
        ]).toJson(),
      ));
      final state = descriptor().initialGameState!.copyWith(
        bag: const Bag(entries: [BagEntry(itemId: 'supply', quantity: 3)]),
      );
      final save = spatialSave(state);
      runtime = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(continueGame: continueGame, initialState: state),
        projectFilePath: () async => '${root.path}/project.json',
        initialSave: () async => continueGame ? save : null,
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async => mounts++,
        unmountSession: (_) async => unmounts++,
      );
      await expectLater(
        runtime.load((_) {}),
        throwsA(isA<StateError>().having(
            (error) => error.message, 'message', contains('sac'))),
      );
      expect(mounts, 0);
      expect(runtime.session, isNull);
      expect(save.state['bag'], state.bag.toJson());
    });
  }

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

  for (final lifecycleLocked in [false, true]) {
    test(
      'contact call waits for controller pause locks, lifecycle=$lifecycleLocked',
      () async {
        await runtime.dispose();
        final nodes = [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'talk',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: 'hello'),
          ),
          SceneNode(
            id: 'reward',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.giveMoney(amount: 7),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ];
        bundle = bundle.copyWith(
          manifest: bundle.manifest.copyWith(
            facts: [
              for (final id in ['device-owned', 'mentor-known'])
                NarrativeFactDefinition(id: id, label: id),
            ],
            contactDevice: ProjectContactDeviceConfig(
              id: 'journal',
              label: 'Journal',
              acquiredFactId: 'device-owned',
              emptyMessage: 'No contacts',
              contacts: [
                ProjectContactEntryConfig(
                  id: 'mentor',
                  label: 'Mentor',
                  registeredFactId: 'mentor-known',
                  sceneId: 'mentor-call',
                  unavailableSceneId: 'mentor-call',
                ),
              ],
            ),
            scenes: [
              SceneAsset(
                id: 'mentor-call',
                name: 'Mentor call',
                graph: SceneGraph(
                  startNodeId: 'start',
                  nodes: nodes,
                  edges: [
                    for (var i = 0; i < nodes.length - 1; i++)
                      SceneEdge(
                        id: 'call-$i',
                        fromNodeId: nodes[i].id,
                        fromPortId: 'completed',
                        toNodeId: nodes[i + 1].id,
                        kind: nodes[i].kind == SceneNodeKind.action
                            ? SceneEdgeKind.actionCompleted
                            : SceneEdgeKind.defaultFlow,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
        final initial = descriptor().initialGameState!.copyWith(
          narrativeFactRuntimeState: NarrativeFactRuntimeState(
            overridesByFactId: {'device-owned': true, 'mentor-known': true},
          ),
        );
        final launch = descriptor(
          initialState: initial,
          additionalCapabilities: {ProjectContactDeviceConfig.capabilityId},
        );
        final controller = GameSessionController(
          adapterFactory: (_) => InProcessGameSessionAdapter(
            runtimeFactory: (descriptor) =>
                runtime = SpatialExplorationGameSessionRuntime(
                  descriptor: descriptor,
                  projectFilePath: () async => '${root.path}/project.json',
                  preloadedInitialMap: ({
                    required projectFilePath,
                    required descriptor,
                    required initialSave,
                  }) async => RuntimeInitialMapPreloadResult(bundle: bundle),
                  mountSession: (_) async {},
                  unmountSession: (_) async {},
                ),
          ),
          commitCheckpoint: (_) async {},
        );
        addTearDown(controller.dispose);
        await controller.prepare(launch);
        await controller.start();
        await runtime.gameplayReady;
        await controller.pause();
        final result = await controller.dispatchPauseCommand(
          const RuntimePlayerPauseCommand.callContact(contactId: 'mentor'),
        );
        expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
        expect(result.resumeGameplay, isTrue);
        if (lifecycleLocked) {
          await runtime.setInputLock(
            RuntimeExternalInputLock.lifecycle,
            locked: true,
          );
        }
        await controller.resume();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(runtime.session!.interactionError.value, isNull);
        if (lifecycleLocked) {
          expect(runtime.dialoguePresentationListenable.value, isNull);
          await runtime.setInputLock(
            RuntimeExternalInputLock.lifecycle,
            locked: false,
          );
        }
        await waitForValue(
          runtime.dialoguePresentationListenable,
          (value) => value != null,
        );
        expect(
          runtime.dialoguePresentationListenable.value!.fullText,
          'Salut !',
        );
        for (
          var i = 0;
          i < 8 && runtime.dialoguePresentationListenable.value != null;
          i++
        ) {
          runtime.session!.confirmDialogue();
          await Future<void>.delayed(Duration.zero);
        }
        expect(runtime.dialoguePresentationListenable.value, isNull);
        await waitForValue(
          runtime.inputAuthority,
          (_) =>
              runtime.gameStateSnapshot.trainerProfile.money ==
                  initial.trainerProfile.money + 7 ||
              runtime.session!.interactionError.value != null,
        );
        expect(runtime.session!.interactionError.value, isNull);
        expect(
          runtime.gameStateSnapshot.trainerProfile.money,
          initial.trainerProfile.money + 7,
        );
        expect(runtime.inputAuthority.value.acceptsOverworldInput, isTrue);
        await runtime.setInputLock(
          RuntimeExternalInputLock.pauseMenu,
          locked: false,
        );
        expect(runtime.dialoguePresentationListenable.value, isNull);
        expect(
          runtime.gameStateSnapshot.trainerProfile.money,
          initial.trainerProfile.money + 7,
        );
      },
    );
  }

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

  for (final audio in [false, true]) {
    test('spatial startup refuses undeclared ${audio ? 'audio' : 'CS'} capability before mounting', () async {
      bundle = bundle.copyWith(manifest: bundle.manifest.copyWith(settings: bundle.manifest.settings.copyWith(
        fieldAbilities: audio ? null : ProjectFieldAbilitiesSettings(disabledAbilities: [FieldAbility.dive]),
        audio: audio ? ProjectAudioSettings(cues: {ProjectSoundCue.uiConfirm: const ProjectSoundBinding(source: ProjectSoundSource.silent)}) : null,
      )));
      final id = audio ? ProjectAudioCapabilities.capabilityId : FieldAbilityActivationCapabilities.capabilityId;
      await expectLater(runtime.load((_) {}), throwsA(isA<StateError>().having((e) => e.message, 'capability', contains(id))));
      expect(mounts, 0);
      expect(runtime.session, isNull);
    });
  }

  for (final audio in [false, true]) {
    test('spatial startup accepts declared ${audio ? 'audio' : 'CS'} capability', () async {
      final id = audio ? ProjectAudioCapabilities.capabilityId : FieldAbilityActivationCapabilities.capabilityId;
      bundle = bundle.copyWith(manifest: bundle.manifest.copyWith(settings: bundle.manifest.settings.copyWith(
        fieldAbilities: audio ? null : ProjectFieldAbilitiesSettings(disabledAbilities: [FieldAbility.dive]),
        audio: audio ? ProjectAudioSettings(cues: {ProjectSoundCue.uiConfirm: const ProjectSoundBinding(source: ProjectSoundSource.silent)}) : null,
      )));
      await runtime.dispose();
      runtime = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(additionalCapabilities: {id}),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async => mounts++, unmountSession: (_) async => unmounts++);
      await runtime.load((_) {});
      await runtime.gameplayReady;
      expect(mounts, 1);
      expect(runtime.session, isNotNull);
    });
  }

  for (final id in ['rock_climb', 'defog']) {
    for (final granted in [false, true]) {
      test('activation-only $id startup requires v2 granted=$granted', () async {
        bundle = bundle.copyWith(manifest: bundle.manifest.copyWith(settings: bundle.manifest.settings.copyWith(
          fieldAbilities: ProjectFieldAbilitiesSettings.fromIds([id]))));
        await runtime.dispose();
        runtime = SpatialExplorationGameSessionRuntime(
          descriptor: descriptor(additionalCapabilities: {FieldAbilityActivationCapabilities.capabilityId,
            if (granted) FieldAbilityActivationCapabilities.extendedCapabilityId}),
          projectFilePath: () async => '${root.path}/project.json',
          preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
          mountSession: (_) async => mounts++, unmountSession: (_) async => unmounts++);
        if (granted) {
          await runtime.load((_) {});
          await runtime.gameplayReady;
          expect(mounts, 1);
        } else {
          await expectLater(runtime.load((_) {}), throwsA(isA<StateError>().having((e) => e.message, 'capability', contains(FieldAbilityActivationCapabilities.extendedCapabilityId))));
          expect(mounts, 0);
        }
      });
    }
  }

  test('Surf action confirms, persists its mode and exits at the shore', () async {
    bundle = bundle.copyWith(
      manifest: bundle.manifest.copyWith(settings: bundle.manifest.settings.copyWith(
        surf: const ProjectSurfSettings(requiresKnownMove: false, accessMode: ProjectSurfAccessMode.always))),
      map: bundle.map.copyWith(entities: [], gameplayZones: [MapGameplayZone(
        id: 'water', kind: GameplayZoneKind.movement,
        area: const MapRect(pos: GridPos(x: 2, y: 1), size: GridSize(width: 4, height: 3)),
        movement: const MovementZonePayload(requiredMode: MovementMode.surf))]));
    await runtime.dispose();
    runtime = SpatialExplorationGameSessionRuntime(
      descriptor: descriptor(additionalCapabilities: {SurfGameplayCapabilities.capabilityId}),
      projectFilePath: () async => '${root.path}/project.json',
      preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async => mounts++, unmountSession: (_) async => unmounts++);
    await runtime.load((_) {});
    await runtime.gameplayReady;
    runtime.session!.movement.setInput(x: 0, z: -1);
    runtime.session!.frame(.01);
    runtime.session!.movement.setInput(x: 0, z: 0);
    runtime.session!.frame(0);
    final request = runtime.overworldInteractions.value.primaryAction!.request;
    expect(request.actionId, 'surf');
    expect(runtime.dispatchOverworldInteraction(request), isTrue);
    await waitForValue(runtime.dialoguePresentationListenable, (value) => value != null);
    for (var i = 0; i < 20 && runtime.dialoguePresentationListenable.value!.choices.isEmpty; i++) {
      runtime.session!.confirmDialogue();
      runtime.session!.frame(.05);
    }
    final snapshot = runtime.dialoguePresentationListenable.value!;
    expect(snapshot.choices.map((choice) => choice.label), ['Oui', 'Non']);
    runtime.session!.dispatchDialogueCommand(DialogueSelectChoiceCommand(
      snapshotRevision: snapshot.revision, choiceIndex: 0));
    expect(runtime.gameStateSnapshot.playerMovementMode, MovementMode.surf);
    await expectLater(runtime.captureCheckpoint(), throwsStateError);
    runtime.session!.movement.setInput(x: 0, z: 1);
    for (var i = 0; i < 10; i++) {
      runtime.session!.frame(.05);
      await Future<void>.delayed(Duration.zero);
    }
    expect(runtime.gameStateSnapshot.playerPosition.y, lessThan(4));
    expect(runtime.gameStateSnapshot.playerMovementMode, MovementMode.surf);
    final save = spatialSave(runtime.gameStateSnapshot);
    final checkpoint = await runtime.captureCheckpoint();
    expect(checkpoint!.state['playerMovementMode'], 'surf');
    final saveFile = File('${root.path}/surf-save.json');
    final originalSaveBytes = const SaveEnvelopeCodec().encodeUtf8(save);
    await saveFile.writeAsBytes(originalSaveBytes, flush: true);
    final saved = const GameStateSaveEnvelopeMapper().restore(save);
    expect(saved.playerMovementMode, MovementMode.surf);
    final continued = SpatialExplorationGameSessionRuntime(
      descriptor: descriptor(continueGame: true, additionalCapabilities: {SurfGameplayCapabilities.capabilityId}),
      projectFilePath: () async => '${root.path}/project.json',
      initialSave: () async => const SaveEnvelopeCodec().decodeUtf8(
        await saveFile.readAsBytes(), acceptedSaveFormats: {1}),
      preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async {}, unmountSession: (_) async {});
    addTearDown(continued.dispose);
    await continued.load((_) {});
    expect(continued.gameStateSnapshot.playerMovementMode, MovementMode.surf);
    expect(continued.session!.movement.isPositionTraversable, isTrue);
    expect(continued.gameStateSnapshot.playerSpatialPosition, saved.playerSpatialPosition);
    expect(await saveFile.readAsBytes(), orderedEquals(originalSaveBytes));
    runtime.session!.movement.setInput(x: 0, z: 1);
    for (var i = 0; i < 14; i++) {
      runtime.session!.frame(.05);
      await Future<void>.delayed(Duration.zero);
    }
    expect(runtime.gameStateSnapshot.playerMovementMode, MovementMode.walk);
    expect(runtime.dispatchOverworldInteraction(request), isFalse);
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

  test('spatial scene factory preloads a native catalog Pokemon gift', () async {
    final config = await writeSceneCatalogPokemonGiftFixture(root);
    bundle = bundle.copyWith(manifest: bundle.manifest.copyWith(
      pokemon: config,
      eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
        records: [spatialEvent(NarrativeEventSourceRef.mapEnter('field'), 'arrival')], legacyClaims: const []),
      scenes: [spatialScene('arrival', [SceneConsequence.givePokemonFromCatalog(speciesId: 'clockbird', formId: 'bronze', level: 7)])],
    ));
    await runtime.load((_) {});
    await runtime.gameplayReady;
    final pokemon = runtime.gameStateSnapshot.party.members.single;
    expect(pokemon.speciesId, 'clockbird');
    expect(pokemon.formId, 'bronze');
    expect(pokemon.currentPpByMoveId, {'tick': 13, 'tock': 19});
    expect(pokemon.experience, 343);
    expect(runtime.gameStateSnapshot.progression.caughtSpeciesIds, ['clockbird']);
    expect(runtime.gameStateSnapshot.appliedPokemonGrantOperationIds, hasLength(1));
  });

  for (final disposeModal in [false, true]) {
    test('spatial production host numeric modal ${disposeModal ? 'disposal rolls back RNG' : 'commits typed result and RNG'}', () async {
      await runtime.dispose();
      final checkpoints = <GameSessionCheckpointCommit>[];
      bundle = bundle.copyWith(manifest: bundle.manifest.copyWith(
        facts: [NarrativeFactDefinition(id: 'number', label: 'Nombre', initialValue: NarrativeValue.integer(0))],
        eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
          records: [spatialEvent(NarrativeEventSourceRef.mapEnter('field'), 'number-input')], legacyClaims: const []),
        scenes: [SceneAsset(id: 'number-input', name: 'Nombre', graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'random', kind: SceneNodeKind.action, payload: SceneActionPayload.consequence(
            SceneConsequence.calculateIntegerFacts(factIds: ['number'], operation: SceneIntegerOperation.assign,
              operand: SceneIntegerOperand.random(minimum: 1, maximum: 4), minimum: 0, maximum: 999))),
          SceneNode(id: 'input', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.inputIntegerToFact(factId: 'number', prompt: SceneInteractionPrompt(localizationKey: 'number'),
              digits: 3, minimum: 0, maximum: 999, cancellationPolicy: SceneIntegerCancellationPolicy.restoreInitialAndComplete))),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [
          SceneEdge(id: 'enter', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'random', kind: SceneEdgeKind.defaultFlow),
          SceneEdge(id: 'random-input', fromNodeId: 'random', fromPortId: 'completed', toNodeId: 'input', kind: SceneEdgeKind.actionCompleted),
          for (final port in ['completed', 'cancelled']) SceneEdge(id: port, fromNodeId: 'input', fromPortId: port, toNodeId: 'end', kind: SceneEdgeKind.actionCompleted),
        ]))],
      ));
      runtime = SpatialExplorationGameSessionRuntime(descriptor: descriptor(),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
        commitCheckpoint: (value) async => checkpoints.add(value),
        mountSession: (_) async => mounts++, unmountSession: (_) async => unmounts++);
      final modal = runtime.worldServiceSnapshots.firstWhere((value) => value?.content is SceneIntegerInteractionRequest)
        .timeout(const Duration(seconds: 5));
      await runtime.load((_) {});
      final snapshot = (await Future.any([
        modal,
        runtime.gameplayReady.then<RuntimeWorldServiceSnapshot?>((_) => throw StateError(
          'Numeric scene finished before opening its modal: ${runtime.session?.interactionError.value}')),
      ]))!;
      final request = snapshot.content! as SceneIntegerInteractionRequest;
      expect(request.initialValue, inInclusiveRange(1, 4));
      expect(runtime.gameStateSnapshot.sceneRandomState, const SceneRandomState.unseeded());
      expect(runtime.gameStateSnapshot.narrativeFactRuntimeState.valuesByFactId, isEmpty);
      if (disposeModal) {
        await runtime.dispose();
        await runtime.gameplayReady;
        expect(checkpoints, isEmpty);
        expect(runtime.session, isNull);
        expect(runtime.worldServiceSnapshot, isNull);
      } else {
        final response = await runtime.dispatchWorldService(RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm, snapshotRevision: snapshot.revision,
          interactionResult: SceneIntegerSubmittedInteractionResult(requestId: request.requestId, revision: request.revision, value: 23)));
        expect(response.status, RuntimeWorldServiceCommandStatus.accepted);
        await runtime.gameplayReady;
        expect(runtime.gameStateSnapshot.narrativeFactRuntimeState.valueFor('number'), NarrativeValue.integer(23));
        expect(runtime.gameStateSnapshot.sceneRandomState, isNot(const SceneRandomState.unseeded()));
        final checkpoint = (await runtime.captureCheckpoint())!;
        final saved = gameStateFromStrictSaveJson(Map<String, dynamic>.from(checkpoint.state));
        expect(saved.narrativeFactRuntimeState, runtime.gameStateSnapshot.narrativeFactRuntimeState);
        expect(saved.sceneRandomState, runtime.gameStateSnapshot.sceneRandomState);
      }
    });
  }

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

  for (final bindPlayer in [true, false]) {
    test('consecutive cinematics retain the projected player pose with ${bindPlayer ? 'player' : 'guide-only'} binding', () async {
      bundle = playerContinuityBundle(bundle, bindPlayer: bindPlayer);
      await runtime.load((_) {});
      await waitForStory(runtime);
      runtime.session!.frames(.25);
      await waitForValue(runtime.dialoguePresentationListenable, (value) => value != null);
      final between = runtime.session!.frames(0)['hero']!;
      expect(between.x, 3);
      expect(between.z, 4);
      expect(runtime.gameStateSnapshot.playerSpatialPosition, PlayerSpatialPosition(x: 4, z: 4));
      for (var i = 0; i < 4 && runtime.dialoguePresentationListenable.value != null; i++) {
        final line = runtime.dialoguePresentationListenable.value!;
        runtime.dispatchDialoguePresentationCommand(DialogueAdvanceCommand(snapshotRevision: line.revision));
        await Future<void>.delayed(Duration.zero);
      }
      await waitForStory(runtime);
      expect(runtime.session!.frames(.1)['hero']!.x, 3);
      runtime.session!.frames(.15);
      var completed = false;
      unawaited(runtime.gameplayReady.then((_) => completed = true));
      final terminalFrames = <double>[];
      for (var frame = 0; frame < 100 && !completed; frame++) {
        terminalFrames.add(runtime.session!.frames(0)['hero']!.x);
        await Future<void>.delayed(Duration.zero);
      }
      await runtime.gameplayReady;
      expect(terminalFrames, everyElement(3));
      expect(runtime.session!.interactionError.value, isNull);
      expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
      expect(runtime.gameStateSnapshot.playerSpatialPosition, PlayerSpatialPosition(x: 3, z: bindPlayer ? 5 : 4));
      expect(runtime.session!.frames(0)['hero']!.x, 3);
    });
  }

  test('cancelling a later cinematic restores the original player pose', () async {
    bundle = playerContinuityBundle(bundle, bindPlayer: true);
    await runtime.load((_) {});
    await waitForStory(runtime);
    runtime.session!.frames(.25);
    await waitForValue(runtime.dialoguePresentationListenable, (value) => value != null);
    for (var i = 0; i < 4 && runtime.dialoguePresentationListenable.value != null; i++) {
      final line = runtime.dialoguePresentationListenable.value!;
      runtime.dispatchDialoguePresentationCommand(DialogueAdvanceCommand(snapshotRevision: line.revision));
      await Future<void>.delayed(Duration.zero);
    }
    await waitForStory(runtime);
    runtime.session!.frames(.1);
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.secondary));
    await runtime.gameplayReady;
    expect(runtime.session!.frames(0)['hero']!.x, 4);
    expect(runtime.session!.frames(0)['hero']!.z, 4);
    expect(runtime.gameStateSnapshot.playerSpatialPosition, PlayerSpatialPosition(x: 4, z: 4));
    expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
    expect(runtime.session!.interactionError.value, isNull);
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
        transition: MapWarpTransition(type: MapWarpTransitionType.none),
        id: 'out',
        pos: GridPos(x: 5, y: 4),
        targetMapId: 'other',
        targetPos: GridPos(x: 2, y: 3));
    const back = MapWarp(
        transition: MapWarpTransition(type: MapWarpTransitionType.none),
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

  for (final facing in EntityFacing.values) {
    test(
      'native spatial scene warp materializes ${facing.name} facing',
      () async {
        bundle = await spatialWarpBundle(
          root,
          bundle,
          arrivalFacing: facing,
          transition: SceneWarpTransition.none,
        );
        await runtime.dispose();
        runtime = newSpatialWarpRuntime(
          bundle,
          root,
          facing: facing == EntityFacing.east
              ? EntityFacing.west
              : EntityFacing.east,
        );

        await runtime.load((_) {});
        await runtime.gameplayReady;

        expectSpatialWarpArrival(runtime, facing);
        expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
        expect(
          runtime
              .gameStateSnapshot
              .narrativeEventProgress
              .consumedNarrativeEventIds,
          {'evt_019abcde-0000-7000-8000-000000000001'},
        );
      },
    );
  }

  test('native spatial scene warp preserves omitted arrival facing', () async {
    bundle = await spatialWarpBundle(root, bundle);
    await runtime.dispose();
    runtime = newSpatialWarpRuntime(bundle, root, facing: EntityFacing.west);

    await runtime.load((_) {});
    await runtime.gameplayReady;

    expectSpatialWarpArrival(runtime, EntityFacing.west);
  });

  for (final transition in SceneWarpTransition.values) {
    test(
      'native spatial ${transition.name} warp uses its instant transfer',
      () async {
        bundle = await spatialWarpBundle(
          root,
          bundle,
          transition: transition,
          arrivalFacing: EntityFacing.north,
        );
        final phases = <bool>[];
        await runtime.load((_) {});
        final session = runtime.session!;
        session.transitioning.addListener(
          () => phases.add(session.transitioning.value),
        );

        await runtime.gameplayReady;

        expectSpatialWarpArrival(runtime, EntityFacing.north);
        expect(phases, [true, false]);
        expect(session.storyActive.value, isFalse);
      },
    );
  }

  test(
    'native spatial warp is physical before its completed dialogue begins',
    () async {
      bundle = await spatialWarpBundle(
        root,
        bundle,
        arrivalFacing: EntityFacing.west,
        dialogue: true,
      );
      await runtime.load((_) {});
      final session = runtime.session!;
      await waitForValue(
        runtime.dialoguePresentationListenable,
        (value) => value != null,
      );

      expect(session.bundle.map.id, 'other');
      expect(session.movement.x, 2.5);
      expect(session.movement.z, 3.5);
      expect(session.movement.facing, EntityFacing.west);
      expect(runtime.gameStateSnapshot.currentMapId, 'field');
      expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
      expect(
        runtime
            .gameStateSnapshot
            .narrativeEventProgress
            .consumedNarrativeEventIds,
        isEmpty,
      );
      await expectLater(runtime.captureCheckpoint(), throwsStateError);
      session.confirmDialogue();
      session.confirmDialogue();
      await runtime.gameplayReady;

      expectSpatialWarpArrival(runtime, EntityFacing.west);
      expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
    },
  );

  test(
    'native spatial target activation follows the parent commit once',
    () async {
      bundle = await spatialWarpBundle(
        root,
        bundle,
        arrivalFacing: EntityFacing.north,
        dialogue: true,
        arrivalEvent: true,
      );
      await runtime.load((_) {});
      final session = runtime.session!;
      await waitForValue(
        runtime.dialoguePresentationListenable,
        (value) => value != null,
      );
      expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
      expect(
        runtime
            .gameStateSnapshot
            .narrativeEventProgress
            .consumedNarrativeEventIds,
        isEmpty,
      );
      session.confirmDialogue();
      session.confirmDialogue();

      await runtime.gameplayReady;

      expectSpatialWarpArrival(runtime, EntityFacing.north);
      expect(runtime.gameStateSnapshot.trainerProfile.money, 30);
      expect(
        runtime
            .gameStateSnapshot
            .narrativeEventProgress
            .consumedNarrativeEventIds,
        {
          'evt_019abcde-0000-7000-8000-000000000001',
          'evt_019abcde-0000-7000-8000-000000000002',
        },
      );
      expect(session.mapRevision.value, 1);
      for (var i = 0; i < 5; i++) {
        session.frame(.05);
        await Future<void>.delayed(Duration.zero);
      }
      expect(runtime.gameStateSnapshot.trainerProfile.money, 30);
    },
  );

  test(
    'native spatial blocked warp rolls back rewards and event consumption',
    () async {
      bundle = await spatialWarpBundle(
        root,
        bundle,
        arrivalFacing: EntityFacing.north,
        blocked: true,
        rewardBefore: true,
        arrivalEvent: true,
      );
      await runtime.load((_) {});
      final session = runtime.session!;
      final before = runtime.gameStateSnapshot;
      final movement = session.movement;

      await runtime.gameplayReady;

      expect(session.bundle.map.id, 'field');
      expect(session.movement, same(movement));
      expect(session.movement.x, 4);
      expect(session.movement.z, 4);
      expect(session.mapRevision.value, 0);
      expect(session.transitioning.value, isFalse);
      expect(session.interactionError.value, isNotNull);
      expect(runtime.gameStateSnapshot, before);
      final checkpoint = (await runtime.captureCheckpoint())!;
      expect(
        gameStateFromStrictSaveJson(
          Map<String, dynamic>.from(checkpoint.state),
        ),
        before,
      );
    },
  );

  test(
    'cancelled spatial scene restores a materialized warp without activation',
    () async {
      bundle = await spatialWarpBundle(
        root,
        bundle,
        arrivalFacing: EntityFacing.west,
        dialogue: true,
        rewardBefore: true,
        arrivalEvent: true,
      );
      await runtime.load((_) {});
      final session = runtime.session!;
      final before = runtime.gameStateSnapshot;
      await waitForValue(
        runtime.dialoguePresentationListenable,
        (value) => value != null,
      );

      session.closeDialogue();
      await runtime.gameplayReady;

      expect(session.bundle.map.id, 'field');
      expect(session.movement.x, 4);
      expect(session.movement.z, 4);
      expect(session.movement.facing, before.playerFacing);
      expect(runtime.gameStateSnapshot, before);
      expect(
        runtime
            .gameStateSnapshot
            .narrativeEventProgress
            .consumedNarrativeEventIds,
        isEmpty,
      );
      expect(session.transitioning.value, isFalse);
      expect(
        runtime.inputAuthority.value.context,
        RuntimeInputContext.overworld,
      );
    },
  );

  test(
    'stop during spatial warp dialogue retains the committed source state',
    () async {
      bundle = await spatialWarpBundle(
        root,
        bundle,
        arrivalFacing: EntityFacing.west,
        dialogue: true,
        rewardBefore: true,
        arrivalEvent: true,
      );
      await runtime.load((_) {});
      final before = runtime.gameStateSnapshot;
      await waitForValue(
        runtime.dialoguePresentationListenable,
        (value) => value != null,
      );

      await runtime.stop(GameSessionExitReason.hub);
      await runtime.gameplayReady;

      expect(runtime.session!.bundle.map.id, 'field');
      expect(runtime.session!.movement.x, 4);
      expect(runtime.session!.movement.z, 4);
      expect(runtime.gameStateSnapshot, before);
      expect(runtime.inputAuthority.value.context, RuntimeInputContext.blocked);
    },
  );

  for (final interruption in ['pause', 'external lock']) {
    test('cancelled spatial warp compensates under $interruption', () async {
      bundle = await spatialWarpBundle(root, bundle,
          arrivalFacing: EntityFacing.west,
          dialogue: true,
          rewardBefore: true,
          arrivalEvent: true);
      await runtime.load((_) {});
      final session = runtime.session!;
      final before = runtime.gameStateSnapshot;
      await waitForValue(
          runtime.dialoguePresentationListenable, (value) => value != null);
      if (interruption == 'pause') {
        await runtime.pause();
      } else {
        await runtime.setInputLock(
            RuntimeExternalInputLock.lifecycle, locked: true);
      }

      session.closeDialogue();
      await runtime.gameplayReady;

      expect(session.bundle.map.id, 'field');
      expect(session.movement.x, 4);
      expect(session.movement.z, 4);
      expect(runtime.gameStateSnapshot, before);
      expect(runtime.inputAuthority.value.context, RuntimeInputContext.blocked);
      await expectLater(
          session.restoreGameState(before.copyWith(
              currentMapId: 'other',
              playerPosition: const GridPos(x: 2, y: 3),
              playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 3.5))),
          throwsStateError);
      expect(session.bundle.map.id, 'field');
      if (interruption == 'pause') {
        await runtime.resume();
      } else {
        await runtime.setInputLock(
            RuntimeExternalInputLock.lifecycle, locked: false);
      }
      expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
    });
  }

  test('cancelled spatial warp within one map restores its committed pose',
      () async {
    bundle = await spatialWarpBundle(root, bundle,
        arrivalMapId: 'field',
        arrivalFacing: EntityFacing.west,
        dialogue: true,
        rewardBefore: true);
    await runtime.load((_) {});
    final session = runtime.session!;
    final before = runtime.gameStateSnapshot;
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    expect(session.movement.x, 2.5);
    expect(session.movement.z, 3.5);

    session.closeDialogue();
    await runtime.gameplayReady;

    expect(session.bundle.map.id, 'field');
    expect(session.movement.x, 4);
    expect(session.movement.z, 4);
    expect(session.movement.facing, before.playerFacing);
    expect(runtime.gameStateSnapshot, before);
    expect(runtime.gameStateSnapshot.narrativeEventProgress
        .consumedNarrativeEventIds, isEmpty);
  });

  test('dispose compensates the spatial scene warp before unmounting', () async {
    bundle = await spatialWarpBundle(root, bundle,
        arrivalFacing: EntityFacing.west,
        dialogue: true,
        rewardBefore: true,
        arrivalEvent: true);
    await runtime.dispose();
    String? mapAtUnmount;
    PlayerSpatialPosition? positionAtUnmount;
    runtime = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async {},
        unmountSession: (value) async {
          mapAtUnmount = value.session!.bundle.map.id;
          positionAtUnmount = value.session!.movement.spatialPosition;
        });
    await runtime.load((_) {});
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);

    await runtime.dispose();
    await runtime.gameplayReady;

    expect(mapAtUnmount, 'field');
    expect(positionAtUnmount, PlayerSpatialPosition(x: 4, z: 4));
    expect(runtime.session, isNull);
  });

  test(
    'fresh spatial warp checkpoint restores pose and consumed events',
    () async {
      bundle = await spatialWarpBundle(
        root,
        bundle,
        arrivalFacing: EntityFacing.north,
        transition: SceneWarpTransition.none,
        arrivalEvent: true,
      );
      await runtime.load((_) {});
      await runtime.gameplayReady;
      final checkpoint = (await runtime.captureCheckpoint())!;
      final saved = gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(checkpoint.state),
      );
      expect(saved.currentMapId, 'other');
      expect(saved.playerFacing, EntityFacing.north);
      expect(
        saved.playerSpatialPosition,
        PlayerSpatialPosition(x: 2.5, z: 3.5),
      );
      expect(saved.trainerProfile.money, 30);
      final target = await loadRuntimeMapBundle(
        projectFilePath: '${root.path}/project.json',
        mapId: 'other',
        preloadedManifest: bundle.manifest,
      );
      final continued = restoredRuntime(target, root, saved);
      addTearDown(continued.dispose);

      await continued.load((_) {});
      await continued.gameplayReady;

      expectSpatialWarpArrival(continued, EntityFacing.north);
      expect(continued.gameStateSnapshot.trainerProfile.money, 30);
      expect(
        continued
            .gameStateSnapshot
            .narrativeEventProgress
            .consumedNarrativeEventIds,
        saved.narrativeEventProgress.consumedNarrativeEventIds,
      );
    },
  );

  test('spatial pre-warp fact makes an arrival NPC block before commit',
      () async {
    bundle = await spatialWarpBundle(root, bundle,
        hiddenWhenFactSet: false, rewardBefore: true);
    await runtime.load((_) {});
    final before = runtime.gameStateSnapshot;

    await runtime.gameplayReady;

    expect(runtime.session!.bundle.map.id, 'field');
    expect(runtime.session!.movement.x, 4);
    expect(runtime.session!.movement.z, 4);
    expect(runtime.gameStateSnapshot, before);
    expect(runtime.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        isEmpty);
    expect(runtime.gameStateSnapshot.narrativeEventProgress
        .consumedNarrativeEventIds, isEmpty);
    final checkpoint = (await runtime.captureCheckpoint())!;
    expect(
        gameStateFromStrictSaveJson(Map<String, dynamic>.from(checkpoint.state)),
        before);
  });

  test('spatial pre-warp fact hides an arrival NPC for physical validation',
      () async {
    bundle = await spatialWarpBundle(root, bundle,
        hiddenWhenFactSet: true,
        rewardBefore: true,
        arrivalFacing: EntityFacing.west);
    await runtime.load((_) {});

    await runtime.gameplayReady;

    expectSpatialWarpArrival(runtime, EntityFacing.west);
    expect(runtime.gameStateSnapshot.narrativeFactRuntimeState
        .overridesByFactId['arrival-presence'], isTrue);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
    final checkpoint = (await runtime.captureCheckpoint())!;
    final saved = gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(checkpoint.state));
    expect(saved.playerSpatialPosition, PlayerSpatialPosition(x: 2.5, z: 3.5));
    expect(saved.narrativeFactRuntimeState
        .overridesByFactId['arrival-presence'], isTrue);
  });

  test('spatial readonly projection remains physical through pending dialogue',
      () async {
    bundle = await spatialWarpBundle(root, bundle,
        hiddenWhenFactSet: true,
        rewardBefore: true,
        dialogue: true,
        arrivalFacing: EntityFacing.west);
    await runtime.load((_) {});
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    final session = runtime.session!;
    expect(session.bundle.map.id, 'other');
    expect(session.movement.isPositionTraversable, isTrue);
    expect(runtime.gameStateSnapshot.currentMapId, 'field');
    expect(runtime.gameStateSnapshot.trainerProfile.money, 0);
    expect(runtime.gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId,
        isEmpty);
    await expectLater(runtime.captureCheckpoint(), throwsStateError);

    session.confirmDialogue();
    session.confirmDialogue();
    await runtime.gameplayReady;

    expectSpatialWarpArrival(runtime, EntityFacing.west);
    expect(runtime.gameStateSnapshot.trainerProfile.money, 25);
  });

  test('spatial checkpoint rejects a pose blocked by a post-warp world rule',
      () async {
    bundle = await spatialWarpBundle(root, bundle,
        hiddenWhenFactSet: false, factAfterWarp: true);
    await runtime.load((_) {});
    await runtime.gameplayReady;
    expect(runtime.session!.bundle.map.id, 'other');
    expect(runtime.session!.movement.isPositionTraversable, isFalse);

    await expectLater(runtime.captureCheckpoint(), throwsStateError);
  });

  test('dispose restores the committed spatial open door before clearing story',
      () async {
    bundle = await spatialWarpBundle(root, animatedDoorBundle(bundle),
        dialogue: true);
    final open = descriptor().initialGameState!.copyWith(
        playerPosition: const GridPos(x: 4, y: 5),
        playerSpatialPosition: PlayerSpatialPosition(x: 4, z: 5),
        spatialWorldState: const SpatialWorldState.empty().setModelState(
            'field', 'door', SpatialModelRuntimeState(
                modelId: 'door-model',
                animationIndex: 0,
                normalizedTime: 1,
                blocksMovement: false)));
    await runtime.dispose();
    var unmounted = 0;
    String? mapAtUnmount;
    bool? traversableAtUnmount;
    runtime = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(initialState: open),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async {},
        unmountSession: (value) async {
          unmounted++;
          mapAtUnmount = value.session!.bundle.map.id;
          traversableAtUnmount = value.session!.movement.isPositionTraversable;
        });
    await runtime.load((_) {});
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    expect(runtime.session!.bundle.map.id, 'other');

    await runtime.dispose();
    await runtime.gameplayReady;

    expect(unmounted, 1);
    expect(mapAtUnmount, 'field');
    expect(traversableAtUnmount, isTrue);
    expect(runtime.session, isNull);
  });

  test('dispose unmounts the spatial host even when compensation fails',
      () async {
    bundle = await spatialWarpBundle(root, bundle,
        arrivalMapId: 'field', dialogue: true);
    await runtime.dispose();
    var unmounted = 0;
    runtime = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async {},
        unmountSession: (_) async => unmounted++);
    await runtime.load((_) {});
    await waitForValue(
        runtime.dialoguePresentationListenable, (value) => value != null);
    final session = runtime.session!;
    expect(session.movement.spatialPosition, PlayerSpatialPosition(x: 2.5, z: 3.5));
    session.bundle = session.bundle.copyWith(
        map: session.bundle.map.copyWith(layers: [
      CollisionLayer(id: 'rollback-wall', name: 'Rollback wall',
          collisions: List<bool>.filled(64, false)..[36] = true)
    ]));

    await expectLater(runtime.dispose(), throwsStateError);
    await runtime.gameplayReady;

    expect(unmounted, 1);
    expect(runtime.session, isNull);
  });

  test('blocked arrival preserves the source map and restores controls',
      () async {
    const warp = MapWarp(
        transition: MapWarpTransition(type: MapWarpTransitionType.none),
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
        transition: MapWarpTransition(type: MapWarpTransitionType.none),
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
        transition: MapWarpTransition(type: MapWarpTransitionType.none),
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
        transition: MapWarpTransition(type: MapWarpTransitionType.none),
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
    test('spatial grass reacts locally to movement: running $running', () async {
      final grass = spatialGrassFixture();
      bundle = bundle.copyWith(
          manifest: bundle.manifest.copyWith(
              models3d: grass.project.models3d,
              smartTileCatalog: grass.project.smartTileCatalog),
          map: grass.map);
      final models = resolveSpatialSmartTileInstances(
          map: bundle.map, catalog: bundle.manifest.smartTileCatalog);
      await runtime.load((_) {});
      await runtime.gameplayReady;
      final session = runtime.session!;
      expect(session.modelRuntimeState('field', models.first.id)!.normalizedTime, 0);
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.down));
      if (running) {
        runtime.handleInput(
            const RuntimeInputEvent.press(RuntimeInputControl.sprint));
      }
      for (var i = 0; i < 40 && session.movement.z < 5; i++) {
        session.frame(.05);
        await Future<void>.delayed(Duration.zero);
      }
      expect(session.movement.z.floor(), 5);
      session.frame(.1);
      expect(session.modelRuntimeState('field', models.first.id)!.normalizedTime,
          closeTo(.25, 1e-9));
      expect(session.modelRuntimeState('field', models.last.id)!.normalizedTime, 0);
      session.frame(0);
      expect(session.modelRuntimeState('field', models.first.id)!.normalizedTime,
          closeTo(.25, 1e-9));
      await runtime.pause();
      session.frame(10);
      expect(session.modelRuntimeState('field', models.first.id)!.normalizedTime,
          closeTo(.25, 1e-9));
      await runtime.resume();
      session.frame(.3);
      expect(session.modelRuntimeState('field', models.first.id)!.normalizedTime, 0);
      final override = SpatialModelRuntimeState(
          modelId: 'grass-model', animationIndex: 0,
          normalizedTime: .8, blocksMovement: false);
      session.worldStateProvider = () => const SpatialWorldState.empty()
          .setModelState('field', models.first.id, override);
      expect(session.modelRuntimeState('field', models.first.id), same(override));
      expect(session.modelRuntimeState('missing', models.first.id), isNull);
    });
  }

  for (final minute in [239, 240, 599, 600, 1199, 1200]) {
    test('session passes injected clock to encounter check at minute $minute', () async {
      await runtime.dispose();
      bundle = bundle.copyWith(
          manifest: bundle.manifest.copyWith(encounterTables: const [
            ProjectEncounterTable(
                id: 'grass-table',
                name: 'Grass',
                encounterKind: EncounterKind.walk,
                chancePerStep: 0,
                entries: [
                  ProjectEncounterEntry(
                      speciesId: 'zubat', minLevel: 5, maxLevel: 5)
                ])
          ]),
          map: bundle.map.copyWith(layers: [
            SmartTileLayer(
                id: 'grass',
                name: 'Grass',
                presetId: 'grass-preset',
                usage: SmartTileUsage.path,
                materialPalette: const ['', 'grass-material'],
                field: SmartTileField.cell(
                    semanticCells: List.filled(64, 1)),
                encounterBehavior: const SmartTileEncounterBehavior(
                    materialId: 'grass-material',
                    encounter: EncounterZonePayload(
                        encounterTableId: 'grass-table',
                        encounterKind: EncounterKind.walk)))
          ]));
      var calls = 0;
      runtime = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async {}, unmountSession: (_) async {},
        now: () { calls++; return DateTime(2026, 10, 24, minute ~/ 60, minute % 60); },
      );
      await runtime.load((_) {});
      await runtime.gameplayReady;
      final before = calls;
      runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.down));
      for (var i = 0; i < 30 && runtime.session!.movement.z < 5.01; i++) {
        runtime.session!.frame(.05);
        for (var j = 0; j < 30; j++) { await Future<void>.delayed(Duration.zero); }
      }
      runtime.handleInput(const RuntimeInputEvent.release(RuntimeInputControl.down));
      await runtime.gameplayReady;
      expect(runtime.session!.movement.z, greaterThanOrEqualTo(5));
      expect(calls, before + 1);
      expect(runtime.session!.interactionError.value, isNull);
    });
  }

  for (final running in [false, true]) {
    test('native encounter paths receive cell entries: running $running',
        () async {
      bundle = bundle.copyWith(
          manifest: bundle.manifest.copyWith(encounterTables: const [
            ProjectEncounterTable(
                id: 'grass-table',
                name: 'Grass',
                encounterKind: EncounterKind.walk,
                chancePerStep: 0,
                entries: [
                  ProjectEncounterEntry(
                      speciesId: 'zubat', minLevel: 5, maxLevel: 5)
                ])
          ]),
          map: bundle.map.copyWith(layers: [
            SmartTileLayer(
                id: 'grass',
                name: 'Grass',
                presetId: 'grass-preset',
                usage: SmartTileUsage.path,
                materialPalette: const ['', 'grass-material'],
                field: SmartTileField.cell(
                    semanticCells: List.filled(64, 1)),
                encounterBehavior: const SmartTileEncounterBehavior(
                    materialId: 'grass-material',
                    encounter: EncounterZonePayload(
                        encounterTableId: 'grass-table',
                        encounterKind: EncounterKind.walk)))
          ]));
      expect(bundle.map.triggers, isEmpty);
      expect(bundle.map.gameplayZones, isEmpty);
      await runtime.load((_) {});
      await runtime.gameplayReady;
      final session = runtime.session!;
      expect(session.movement.paused, isFalse);
      final checkedCells = <int>{};
      final inputEpoch = session.movement.inputEpoch;
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.down));
      if (running) {
        runtime.handleInput(
            const RuntimeInputEvent.press(RuntimeInputControl.sprint));
      }
      for (var frame = 0; frame < 80 && session.movement.z < 7.1; frame++) {
        session.frame(.05);
        if (session.movement.paused) {
          checkedCells.add(session.movement.z.floor());
        }
        for (var tick = 0; tick < 100 && session.movement.paused; tick++) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(session.interactionError.value, isNull);
        expect(session.movement.paused, isFalse);
        expect(session.movement.inputEpoch, inputEpoch);
      }
      expect(checkedCells, containsAll([5, 6, 7]));
      expect(session.movement.z, greaterThanOrEqualTo(7.1));
    });
  }

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

  test(
    'session reuses item and move catalogs across companion menu reads',
    () async {
      final items = File('${root.path}/data/pokemon/catalogs/items.json');
      final moves = File('${root.path}/data/pokemon/catalogs/moves.json');
      await items.parent.create(recursive: true);
      await items.writeAsString(
        jsonEncode(
          const ProjectItemCatalog(
            schemaVersion: 1,
            entries: [
              ProjectItemDefinition(
                id: 'potion',
                displayName: 'Potion initiale',
                pocketId: 'medicine',
              ),
            ],
          ).toJson(),
        ),
      );
      await moves.writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'catalog': 'moves',
          'entries': [
            PokemonMove(
              id: 'tackle',
              name: 'Tackle',
              names: const {'fr': 'Charge'},
              generation: 1,
              source: 'test',
              type: 'normal',
              category: PokemonMoveCategory.physical,
              target: PokemonMoveTarget.normal,
              basePower: 40,
              accuracy: const PokemonMoveAccuracy.percent(value: 100),
              pp: 35,
            ).toJson(),
          ],
        }),
      );
      bundle = bundle.copyWith(
        manifest: bundle.manifest.copyWith(
          pokemon: bundle.manifest.pokemon.copyWith(
            catalogFiles: {
              'items': 'data/pokemon/catalogs/items.json',
              'moves': 'data/pokemon/catalogs/moves.json',
            },
          ),
        ),
      );
      SpatialExplorationGameSessionRuntime newRuntime() =>
          SpatialExplorationGameSessionRuntime(
            descriptor: descriptor(
              initialState: descriptor().initialGameState!.copyWith(
                bag: const Bag(
                  entries: [BagEntry(itemId: 'potion', quantity: 1)],
                ),
              ),
            ),
            projectFilePath: () async => '${root.path}/project.json',
            preloadedInitialMap: ({
              required projectFilePath,
              required descriptor,
              required initialSave,
            }) async => RuntimeInitialMapPreloadResult(bundle: bundle),
            mountSession: (_) async => mounts++,
            unmountSession: (_) async => unmounts++,
          );
      await runtime.dispose();
      runtime = newRuntime();
      final trackedItems = _TrackedMenuCatalogFile(items);
      final trackedMoves = _TrackedMenuCatalogFile(moves);
      final createFile = Zone.current.bindUnaryCallback(File.new);
      await IOOverrides.runZoned(
        () async {
          await runtime.load((_) {});
          final first = await runtime.readCompanionMenuData();
          final second = await runtime.readCompanionMenuData();
          expect(
            first
                .pauseDetails[RuntimePlayerPauseSection.bag]!
                .entries
                .single
                .title,
            'Potion initiale',
          );
          expect(
            second
                .pauseDetails[RuntimePlayerPauseSection.bag]!
                .entries
                .single
                .title,
            'Potion initiale',
          );
          expect(
            {'items': trackedItems.reads, 'moves': trackedMoves.reads},
            {'items': 1, 'moves': 1},
          );
          await runtime.dispose();
          await items.writeAsString(
            jsonEncode(
              const ProjectItemCatalog(
                schemaVersion: 1,
                entries: [
                  ProjectItemDefinition(
                    id: 'potion',
                    displayName: 'Potion nouvelle',
                    pocketId: 'medicine',
                  ),
                ],
              ).toJson(),
            ),
          );
          runtime = newRuntime();
          await runtime.load((_) {});
          final fresh = await runtime.readCompanionMenuData();
          expect(
            fresh
                .pauseDetails[RuntimePlayerPauseSection.bag]!
                .entries
                .single
                .title,
            'Potion nouvelle',
          );
          expect(
            {'items': trackedItems.reads, 'moves': trackedMoves.reads},
            {'items': 2, 'moves': 2},
          );
        },
        createFile: (path) => path == items.path
            ? trackedItems
            : path == moves.path
            ? trackedMoves
            : createFile(path),
      );
    },
  );

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
    expect(healed.worldServiceSnapshot, isNull);
  });

  test('failed healer checkpoint rolls back the party and releases input',
      () async {
    var attempts = 0;
    late final SpatialExplorationGameSessionRuntime healed;
    healed = serviceRuntime(commitCheckpoint: (_) async {
      expect(healed.worldServiceSnapshot?.stage, RuntimeWorldServiceStage.applying);
      if (++attempts == 1) throw FileSystemException('disk full');
    });
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
    final retry = await healed.openHealCenter(
        request: const OpenHealService(
            interactionId: 'valbois-heal-retry', requiresConfirmation: false));
    expect(retry.status, PlayerServiceRuntimeStatus.completed);
    expect(attempts, 2);
    expect(healed.gameStateSnapshot.party.members.first.currentHp, 30);
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

  for (final obstacle in ['free', 'enclosed', 'wide', 'static', 'sealed']) {
    test('Continue near an explicit NPC $obstacle preserves original save bytes', () async {
      final blocked = obstacle == 'static';
      final sealed = obstacle == 'sealed';
      final enclosed = obstacle == 'enclosed';
      final wide = obstacle == 'wide';
      final npc = bundle.map.entities.single.copyWith(pos: GridPos(x: sealed ? 0 : wide ? 3 : 4, y: sealed ? 0 : wide ? 3 : 4),
          size: GridSize(width: sealed ? 8 : wide ? 4 : 1, height: sealed ? 8 : wide ? 4 : 1),
          properties: {'collision.width': sealed ? '8' : wide ? '4' : '1', 'collision.height': sealed ? '8' : wide ? '4' : '1'});
      bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [npc],
          spatialScene: bundle.map.spatialScene!.copyWith(navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: 1.5, z: 1.5), blockedAreas: [
              if (blocked) SpatialBlockedArea(x: 4, z: 4, width: 1, depth: 2),
              if (wide) SpatialBlockedArea(x: 0, z: 7.125, width: 8, depth: .875),
              if (enclosed) ...[
                SpatialBlockedArea(x: 0, z: 5.125, width: 8, depth: 1),
                SpatialBlockedArea(x: 3.9375, z: 3, width: .0625, depth: 2.125),
                SpatialBlockedArea(x: 5, z: 3, width: .0625, depth: 2.125),
              ],
            ]))));
      final state = descriptor().initialGameState!.copyWith(playerPosition: GridPos(x: wide ? 5 : 4, y: wide ? 7 : 5),
          playerSpatialPosition: PlayerSpatialPosition(x: wide ? 5 : 4.5, z: wide ? 7 : 5), playerFacing: EntityFacing.east,
          trainerProfile: const TrainerProfile(name: 'Yoahn', avatarCharacterId: 'hero', money: 123),
          party: const PlayerParty(members: [PlayerPokemon(individualId: 'starter', speciesId: 'bulbasaur',
              natureId: 'hardy', abilityId: 'overgrow', currentHp: 2)]),
          storyFlags: const StoryFlags(activeFlags: {'started'}),
          bag: const Bag(entries: [BagEntry(itemId: 'poke-ball', quantity: 7)]));
      final save = spatialSave(state);
      final savedState = const GameStateSaveEnvelopeMapper().restore(save);
      final original = const SaveEnvelopeCodec().encodeUtf8(save);
      final file = File('${root.path}/saved-playthrough.json');
      await file.writeAsBytes(original);
      var writes = 0;
      GameState? mountedState;
      late final SpatialExplorationGameSessionRuntime continued;
      continued = SpatialExplorationGameSessionRuntime(descriptor: descriptor(continueGame: true),
          projectFilePath: () async => '${root.path}/project.json',
          initialSave: () async => const SaveEnvelopeCodec().decodeUtf8(await file.readAsBytes(), acceptedSaveFormats: {1}),
          preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
          commitCheckpoint: (_) async => writes++,
          mountSession: (_) async { mounts++; mountedState = continued.gameStateSnapshot; },
          unmountSession: (_) async => unmounts++);
      addTearDown(continued.dispose);
      if (blocked || sealed) {
        await expectLater(continued.load((_) {}), throwsA(isA<StateError>().having(
            (error) => error.message, 'message', contains('sauvegarde d’origine est conservée'))));
        expect(continued.session, isNull);
        expect(mounts, 0);
      } else {
        await continued.load((_) {});
        final position = wide ? PlayerSpatialPosition(x: 2.625, z: 7) :
            enclosed ? PlayerSpatialPosition(x: 4.5, z: 3.9375) : PlayerSpatialPosition(x: 4.5, z: 5.4375);
        expect(continued.session!.movement.spatialPosition, position);
        expect(continued.session!.movement.isPositionTraversable, isTrue);
        expect(mountedState!.toJson(), savedState.copyWith(playerPosition: GridPos(x: position.x.floor(), y: position.z.floor()),
            playerSpatialPosition: position).toJson());
        expect(continued.gameStateSnapshot.party, savedState.party);
        expect(continued.gameStateSnapshot.trainerProfile, savedState.trainerProfile);
        expect(continued.gameStateSnapshot.storyFlags, savedState.storyFlags);
        expect(mounts, 1);
      }
      expect(writes, 0);
      expect(await file.readAsBytes(), orderedEquals(original));
    });
  }

  test('New Game keeps rejecting an authored NPC overlap', () async {
    final npc = bundle.map.entities.single.copyWith(pos: const GridPos(x: 4, y: 4),
        properties: const {'collision.width': '1', 'collision.height': '1'});
    bundle = bundle.copyWith(map: bundle.map.copyWith(entities: [npc]));
    final state = descriptor().initialGameState!.copyWith(playerPosition: const GridPos(x: 4, y: 5),
        playerSpatialPosition: PlayerSpatialPosition(x: 4.5, z: 5));
    final started = SpatialExplorationGameSessionRuntime(descriptor: descriptor(initialState: state),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async => mounts++, unmountSession: (_) async => unmounts++);
    addTearDown(started.dispose);
    await expectLater(started.load((_) {}), throwsStateError);
    expect(started.session, isNull);
    expect(mounts, 0);
  });

  test('rejects a 2D save and a statically blocked spatial save before mounting',
      () async {
    bundle = bundle.copyWith(map: bundle.map.copyWith(spatialScene: bundle.map.spatialScene!.copyWith(
        navigation: bundle.map.spatialScene!.navigation.copyWith(blockedAreas: [
          SpatialBlockedArea(x: 4, z: 2, width: 1, depth: 1),
        ]))));
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
        {bool continueGame = false, GameState? initialState, Set<String> additionalCapabilities = const {}}) =>
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
        grantedCapabilities: {'map3d@1', 'map3d.story@1', SpatialGameplayCapabilities.trainerSpottingCapabilityId, ...additionalCapabilities},
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
        NarrativeEventSourceRef source, String sceneId,
        {String id = 'evt_019abcde-0000-7000-8000-000000000001'}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: id,
            name: sceneId,
            source: source,
            conditions: const [],
            sceneId: sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
            resetPolicy: const NarrativeEventResetPolicy.never()),
        enabled: true);

SpatialExplorationGameSessionRuntime newSpatialWarpRuntime(
  RuntimeMapBundle bundle,
  Directory root, {
  required EntityFacing facing,
}) => SpatialExplorationGameSessionRuntime(
  descriptor: descriptor(
    initialState: descriptor().initialGameState!.copyWith(playerFacing: facing),
  ),
  projectFilePath: () async => '${root.path}/project.json',
  preloadedInitialMap: ({
    required projectFilePath,
    required descriptor,
    required initialSave,
  }) async => RuntimeInitialMapPreloadResult(bundle: bundle),
  mountSession: (_) async {},
  unmountSession: (_) async {},
);

void expectSpatialWarpArrival(
  SpatialExplorationGameSessionRuntime runtime,
  EntityFacing facing,
) {
  final session = runtime.session!;
  expect(session.bundle.map.id, 'other');
  expect(session.movement.x, 2.5);
  expect(session.movement.z, 3.5);
  expect(session.movement.facing, facing);
  expect(session.movement.isPositionTraversable, isTrue);
  expect(session.transitioning.value, isFalse);
  expect(session.interactionError.value, isNull);
  expect(runtime.gameStateSnapshot.currentMapId, 'other');
  expect(runtime.gameStateSnapshot.playerPosition, const GridPos(x: 2, y: 3));
  expect(runtime.gameStateSnapshot.playerFacing, facing);
  expect(
    runtime.gameStateSnapshot.playerSpatialPosition,
    PlayerSpatialPosition(x: 2.5, z: 3.5),
  );
  expect(runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
}

Future<RuntimeMapBundle> spatialWarpBundle(
  Directory root,
  RuntimeMapBundle bundle, {
  EntityFacing? arrivalFacing,
  String arrivalMapId = 'other',
  SceneWarpTransition transition = SceneWarpTransition.mapDefault,
  bool blocked = false,
  bool dialogue = false,
  bool rewardBefore = false,
  bool arrivalEvent = false,
  bool? hiddenWhenFactSet,
  bool factAfterWarp = false,
}) async {
  final reward = spatialScene('warp-parent', [
    SceneConsequence.giveMoney(amount: 25),
  ], dialogue: dialogue);
  final nodes = [
    reward.graph.nodes.first,
    if (rewardBefore) reward.graph.nodes[1],
    if (hiddenWhenFactSet != null && !factAfterWarp)
      SceneNode(
          id: 'presence',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(SceneConsequence.setFact(
              factId: 'arrival-presence', value: true))),
    SceneNode(
      id: 'warp',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.interactive(
        SceneInteractiveCommand.warp(
          destinationMapId: arrivalMapId,
          warpId: 'arrival',
          arrivalFacing: arrivalFacing,
          transition: transition,
        ),
      ),
    ),
    if (hiddenWhenFactSet != null && factAfterWarp)
      SceneNode(
          id: 'presence',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(SceneConsequence.setFact(
              factId: 'arrival-presence', value: true))),
    if (dialogue) reward.graph.nodes[2],
    if (!rewardBefore) reward.graph.nodes[1],
    reward.graph.nodes.last,
  ];
  final parent = SceneAsset(
    id: reward.id,
    name: reward.name,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var index = 0; index < nodes.length - 1; index++)
          SceneEdge(
            id: 'edge_$index',
            fromNodeId: nodes[index].id,
            fromPortId: 'completed',
            toNodeId: nodes[index + 1].id,
            kind: nodes[index].kind == SceneNodeKind.action
                ? SceneEdgeKind.actionCompleted
                : SceneEdgeKind.defaultFlow,
          ),
      ],
    ),
  );
  const arrival = MapWarp(
      transition: MapWarpTransition(type: MapWarpTransitionType.none),
      id: 'arrival',
      pos: GridPos(x: 2, y: 3),
      targetMapId: 'field',
      targetPos: GridPos(x: 4, y: 4),
      triggerMode: MapWarpTriggerMode.onBump);
  final source = bundle.map.copyWith(
      entities: [],
      warps: arrivalMapId == 'field' ? [arrival] : bundle.map.warps);
  final target = source.copyWith(
    id: 'other',
    name: 'Other',
    entities: [
      if (hiddenWhenFactSet != null)
        const MapEntity(
            id: 'arrival-npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 3),
            blocksMovement: true,
            npc: MapEntityNpcData(displayName: 'Arrival', characterId: 'hero'))
    ],
    layers: [
      if (blocked)
        CollisionLayer(
          id: 'solid',
          name: 'Solid',
          collisions: List<bool>.filled(64, false)..[26] = true,
        ),
    ],
    warps: const [
      MapWarp(
        transition: MapWarpTransition(type: MapWarpTransitionType.none),
        id: 'arrival',
        pos: GridPos(x: 2, y: 3),
        targetMapId: 'field',
        targetPos: GridPos(x: 4, y: 4),
        triggerMode: MapWarpTriggerMode.onBump,
      ),
    ],
  );
  final manifest = bundle.manifest.copyWith(
    facts: [
      ...bundle.manifest.facts,
      if (hiddenWhenFactSet != null)
        NarrativeFactDefinition(id: 'arrival-presence', label: 'Arrival presence')
    ],
    worldRules: [
      ...bundle.manifest.worldRules,
      if (hiddenWhenFactSet != null)
        WorldRuleDefinition(
            id: 'arrival-npc-presence',
            label: 'Arrival NPC presence',
            source: WorldRuleSource(
                kind: WorldRuleSourceKind.fact,
                sourceId: 'arrival-presence',
                predicate: hiddenWhenFactSet
                    ? WorldRuleSourcePredicate.isTrue
                    : WorldRuleSourcePredicate.isFalse),
            target: const WorldRuleTarget(
                kind: WorldRuleTargetKind.mapEntity,
                mapId: 'other',
                entityId: 'arrival-npc'),
            effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden))
    ],
      tilesets: const [ProjectTilesetEntry(id: 'unused', name: 'Unused', relativePath: 'hero.png')],
    maps: const [
      ProjectMapEntry(
        id: 'field',
        name: 'Field',
        relativePath: 'maps/field.json',
      ),
      ProjectMapEntry(
        id: 'other',
        name: 'Other',
        relativePath: 'maps/other.json',
      ),
    ],
    scenes: [
      parent,
      if (arrivalEvent)
        spatialScene('warp-arrival', [SceneConsequence.giveMoney(amount: 5)]),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        spatialEvent(NarrativeEventSourceRef.mapEnter('field'), parent.id),
        if (arrivalEvent)
          spatialEvent(
            NarrativeEventSourceRef.mapEnter('other'),
            'warp-arrival',
            id: 'evt_019abcde-0000-7000-8000-000000000002',
          ),
      ],
      legacyClaims: const [],
    ),
  );
  await Directory('${root.path}/maps').create();
  for (final map in [source, target]) {
    await File('${root.path}/maps/${map.id}.json')
        .writeAsString(jsonEncode(map.toJson()));
  }
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(manifest.toJson()));
  final png = await File('${root.path}/hero.png').readAsBytes();
  final artifact = ContentArtifactRef.fromBytes(png, mediaType: 'image/png');
  final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
  await blob.parent.create(recursive: true);
  await blob.writeAsBytes(png);
  final catalogFile = File('${root.path}/$assetCatalogStorageKey');
  await catalogFile.parent.create(recursive: true);
  await catalogFile.writeAsString(
    jsonEncode(
      AssetCatalog(
        records: [
          AssetRecord(
            id: 'hero-sheet',
            logicalPath: 'hero.png',
            artifact: artifact,
          ),
        ],
      ).toJson(),
    ),
  );
  return bundle.copyWith(map: source, manifest: manifest);
}

RuntimeMapBundle playerContinuityBundle(RuntimeMapBundle bundle, {required bool bindPlayer}) {
  CinematicAsset clip(String id, String actor, double x, double z, {bool relative = false}) => CinematicAsset.fromJson({
    'id': id, 'title': id, 'mapId': 'field', 'actorCompletionPolicy': 'keepFinal',
    'requiredActors': [{'actorId': actor}],
    'movementTargets': [{'targetId': 'end', 'label': 'End'}],
    'stageContext': {
      'actorBindings': [{'actorId': actor, 'kind': actor == 'hero' ? 'player' : 'mapEntity', if (actor != 'hero') 'mapEntityId': 'npc'}],
      'stagePoints': [{'id': 'end', 'label': 'End', 'x': x, 'y': z, if (relative) 'relativeToActorId': actor}],
      'movementTargetBindings': [{'targetId': 'end', 'kind': 'stagePoint', 'sourceId': 'end'}],
    },
    'timeline': {'steps': [{'id': 'move', 'kind': 'actorMove', 'actorId': actor, 'targetId': 'end', 'durationMs': 250,
      'metadata': {'actor.movementMode': 'walk', 'actor.pathMode': 'direct'}}]},
  });
  final first = clip('align', 'hero', 3, 4);
  final second = bindPlayer ? clip('follow', 'hero', 0, 1, relative: true) : clip('follow', 'guide', 4, 4);
  final reward = spatialScene('continuity', [SceneConsequence.giveMoney(amount: 25)]);
  final graph = SceneGraph(startNodeId: 'start', nodes: [
    reward.graph.nodes.first,
    SceneNode(id: 'align', kind: SceneNodeKind.cinematic, payload: SceneCinematicPayload(cinematicId: first.id)),
    SceneNode(id: 'talk', kind: SceneNodeKind.yarnDialogue, payload: SceneYarnDialoguePayload(dialogueId: 'hello')),
    SceneNode(id: 'follow', kind: SceneNodeKind.cinematic, payload: SceneCinematicPayload(cinematicId: second.id)),
    ...reward.graph.nodes.skip(1),
  ], edges: [
    SceneEdge(id: 'a', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'align', kind: SceneEdgeKind.defaultFlow),
    SceneEdge(id: 'b', fromNodeId: 'align', fromPortId: 'completed', toNodeId: 'talk', kind: SceneEdgeKind.cinematicCompleted),
    SceneEdge(id: 'c', fromNodeId: 'talk', fromPortId: 'completed', toNodeId: 'follow', kind: SceneEdgeKind.defaultFlow),
    SceneEdge(id: 'd', fromNodeId: 'follow', fromPortId: 'completed', toNodeId: 'action_0', kind: SceneEdgeKind.cinematicCompleted),
    ...reward.graph.edges.skip(1),
  ]);
  return bundle.copyWith(manifest: bundle.manifest.copyWith(cinematics: [first, second],
    scenes: [SceneAsset(id: reward.id, name: reward.name, graph: graph)],
    eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
      records: [spatialEvent(NarrativeEventSourceRef.mapEnter('field'), reward.id)], legacyClaims: const [])));
}

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

final class _DelayedFishingMusicDriver implements FlameCinematicAudioDriver, FlameCinematicAudioPausableDriver {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<Object> play(String path, {required double volume, required bool loop}) async {
    if (path.endsWith('fishing-battle.ogg')) {
      if (!entered.isCompleted) entered.complete();
      await release.future;
    }
    return Object();
  }
  @override
  Future<void> pause(Object handle) async {}
  @override
  Future<void> resume(Object handle) async {}
  @override
  Future<void> stop(Object handle) async {}
  @override
  Future<void> setVolume(Object handle, double volume) async {}
}

final class _SceneAudioDriver implements FlameCinematicAudioDriver, FlameCinematicAudioLoopDriver, FlameCinematicAudioPausableDriver {
  final paused = <Object>[];
  final resumed = <Object>[];
  @override
  Future<void> pause(Object handle) async { paused.add(handle); }
  @override
  Future<void> resume(Object handle) async { resumed.add(handle); }
  final complete = StreamController<void>.broadcast(sync:true);
  final started = Completer<void>();
  final handle = Object();
  @override
  Future<Object> play(String path,{required double volume,required bool loop}) async => handle;
  @override
  Future<void> stop(Object handle)async{}
  @override
  Future<void> setVolume(Object handle,double volume)async{}
  @override
  Stream<void> onComplete(Object handle) { if(!started.isCompleted) started.complete(); return complete.stream; }
  @override
  Future<void> seekAndResume(Object handle,Duration position)async{}
}

({ProjectManifest manifest, MapData source, MapData destination})
spatialBorderPassageFixture(RuntimeMapBundle bundle) {
  final defaults = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  final transforms = BorderTransformPolicy(
    allowFlipX: false,
    allowedQuarterTurns: const [0, 1, 2, 3],
  );
  const roles = [
    BorderPrimitiveRole.lineCap,
    BorderPrimitiveRole.lineStraight,
    BorderPrimitiveRole.lineCorner,
  ];
  final draft = BorderBlueprintDraftDefinition(
    name: 'Fence',
    previewSeed: BorderSignedInt64.zero,
    template: BorderBlueprintTemplate.connectedLine,
    primitives: [
      for (final role in roles)
        BorderPrimitiveDraft(
          id: role.name,
          sourceModelId: 'fence-unit',
          role: role,
          weight: 1,
          transforms: transforms,
        ),
    ],
    defaults: defaults,
    sortOrder: 0,
  );
  final revision = BorderBlueprintRevision(
    revision: 1,
    definition: BorderBlueprintPublishedDefinition(
      name: draft.name,
      previewSeed: draft.previewSeed,
      template: draft.template,
      primitives: [
        for (final role in roles)
          BorderPublishedPrimitive(
            id: role.name,
            sourceModelId: 'fence-unit',
            role: role,
            weight: 1,
            transforms: transforms,
          ),
      ],
      defaults: defaults,
      sortOrder: 0,
    ),
  );
  final source = bundle.map.copyWith(
    entities: [],
    warps: const [
      MapWarp(
        id: 'out',
        pos: GridPos(x: 4, y: 5),
        targetMapId: 'other',
        targetPos: GridPos(x: 4, y: 4),
        transition: MapWarpTransition(type: MapWarpTransitionType.none),
      ),
    ],
  );
  final raw = source.copyWith(
    id: 'other',
    warps: const [
      MapWarp(
        id: 'back',
        pos: GridPos(x: 4, y: 3),
        targetMapId: 'field',
        targetPos: GridPos(x: 4, y: 4),
        transition: MapWarpTransition(type: MapWarpTransitionType.none),
      ),
    ],
    triggers: const [
      MapTrigger(
        id: 'reward',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 4, y: 5),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ],
    layers: [
      MapLayer.border(
        id: 'border',
        name: 'Border',
        content: BorderLayerContent(
          formatVersion: 4,
          features: [
            BorderFeature(
              id: 'fence',
              name: 'Fence',
              blueprintId: 'fence',
              overrides: const [],
              keepOutRegions: const [],
              seed: BorderSignedInt64.zero,
              geometry: BorderStrokeGeometry(
                strokes: [
                  BorderStroke(
                    id: 'line',
                    points: const [GridPos(x: 1, y: 1), GridPos(x: 2, y: 1)],
                    closed: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
  final reward = spatialScene('border-reward', [
    SceneConsequence.giveMoney(amount: 7),
  ]);
  final manifest = bundle.manifest.copyWith(
    settings: bundle.manifest.settings.copyWith(
      spatialCamera: SpatialCameraProfile(),
    ),
    dialogues: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'unused',
        name: 'Unused',
        relativePath: 'hero.png',
      ),
    ],
    maps: const [
      ProjectMapEntry(
        id: 'field',
        name: 'Field',
        relativePath: 'maps/field.json',
      ),
      ProjectMapEntry(
        id: 'other',
        name: 'Other',
        relativePath: 'maps/other.json',
      ),
    ],
    models3d: [
      ProjectModel3dEntry(
        id: 'fence-unit',
        name: 'Fence unit',
        sourceAssetId: 'fence-source',
        relativePath: 'assets/models3d/fence-unit.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3.zero,
            max: Model3dVector3(x: 1, y: 1, z: 1),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      ),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 5,
      records: [
        BorderBlueprintRecord(
          id: 'fence',
          latestPublished: revision,
          draft: BorderBlueprintDraft(baseRevision: 1, definition: draft),
        ),
      ],
    ),
    scenes: [reward],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      legacyClaims: const [],
      records: [
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: 'evt_019abcde-0000-7000-8000-000000000001',
            name: 'Reward',
            source: NarrativeEventSourceRef.triggerEnter('other', 'reward'),
            conditions: const [],
            sceneId: reward.id,
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 0,
            resetPolicy: const NarrativeEventResetPolicy.never(),
          ),
          enabled: true,
        ),
      ],
    ),
  );
  final resolved = resolveSpatialBorderFeature(
    manifest: manifest,
    map: raw,
    layerId: 'border',
    featureId: 'fence',
  );
  expect(resolved.result.canApply, isTrue);
  final destination = applySpatialBorderFeaturePreview(
    raw,
    manifest: manifest,
    proposedResult: resolved,
  );
  return (manifest: manifest, source: source, destination: destination);
}

class _WeatherProvider implements RealWeatherProvider {
  int requests = 0;
  @override
  Future<RealWeatherLocation> locate() async => RealWeatherLocation(latitude: 48, longitude: 2, label: 'Test city');
  @override
  Future<List<RealWeatherLocation>> search(String query) async => [];
  @override
  Future<RealWeatherSnapshot> fetch(RealWeatherLocation location, DateTime now) async {
    requests++;
    return RealWeatherSnapshot(location: location, conditions: SpatialVisualPatch.fromJson({'weatherKind': 'rain'}), fetchedAt: now);
  }
}
class _WeatherCache implements RealWeatherCache {
  RealWeatherSnapshot? saved;
  @override
  Future<RealWeatherSnapshot?> read() async => saved;
  @override
  Future<void> write(RealWeatherSnapshot snapshot) async { saved = snapshot; }
}

final class _TrackedMenuCatalogFile implements File {
  _TrackedMenuCatalogFile(this.file);

  final File file;
  int reads = 0;

  @override
  String get path => file.path;

  @override
  Future<bool> exists() => file.exists();

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    reads++;
    return file.readAsString(encoding: encoding);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
