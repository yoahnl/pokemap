import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart' show Direction;
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

const _day = MapEntityRuntimePredicate(
  kind: MapEntityRuntimePredicateKind.localTimeWindow,
  timeWindow: LocalTimeWindow(startMinute: 240, endMinute: 1200),
);
const _night = MapEntityRuntimePredicate(
  kind: MapEntityRuntimePredicateKind.localTimeWindow,
  timeWindow: LocalTimeWindow(startMinute: 1200, endMinute: 240),
);

MapEntity _cow() => const MapEntity(
  id: 'cow',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 1, y: 1),
  npc: MapEntityNpcData(
    displayName: 'Cow',
    dialogue: DialogueRef(dialogueId: 'day_talk'),
    visibilityRule: MapEntityNpcVisibilityRule(
      mode: MapEntityNpcVisibilityMode.visibleWhen,
      predicate: _day,
    ),
  ),
);
MapEntity _guard({int range = 0}) => MapEntity(
  id: 'guard',
  kind: MapEntityKind.npc,
  pos: const GridPos(x: 1, y: 1),
  npc: MapEntityNpcData(
    displayName: 'Guard',
    facing: EntityFacing.west,
    lineOfSightRange: range,
    trainerId: 'guard',
    dialogue: const DialogueRef(dialogueId: 'day_talk'),
    trainerBattleWhen: _night,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'idle hour boundaries update presence, interaction and collision together',
    () async {
      var minute = 1199;
      final game = await _load(_cow(), () => _date(minute));
      expect(
        game.overworldInteractionSnapshot.primaryAction?.request.targetId,
        'cow',
      );
      await _stepRight(game);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 1));
      minute = 1200;
      game.update(.016);
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
      await _stepRight(game);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 0, y: 1),
        facing: Direction.east,
      );
      minute = 240;
      game.update(.016);
      expect(
        game.overworldInteractionSnapshot.primaryAction?.request.targetId,
        'cow',
      );
      await _stepRight(game);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 1));
    },
  );

  test('manual guard talk becomes a battle interaction and stale day requests are rejected', () async {
    var minute = 1199;
    final game = await _load(_guard(), () => _date(minute));
    final day = game.overworldInteractionSnapshot.primaryAction!;
    expect(day.verb, RuntimeOverworldInteractionVerb.talk);
    minute = 1200;
    game.update(.016);
    final night = game.overworldInteractionSnapshot.primaryAction!;
    expect(night.verb, RuntimeOverworldInteractionVerb.interact);
    expect(game.dispatchOverworldInteraction(day.request), isFalse);
    expect(game.dispatchOverworldInteraction(night.request), isTrue);
    await _until(game, () => game.debugFlowPhaseName == 'dialogue');
    expect(
      game.dialoguePresentationListenable.value?.fullText,
      'Night challenge.',
    );
    minute = 240;
    game.update(.016);
    await _closeDialogue(game);
    expect(game.debugPendingBattleRequest, isNull);
    expect(game.debugActiveBattleRequest, isNull);
    expect(game.debugIsGameplayInputLocked, isFalse);
    expect(
      game.overworldInteractionSnapshot.primaryAction?.verb,
      RuntimeOverworldInteractionVerb.talk,
    );
  });

  test('stationary line of sight starts at night and aborts cleanly at the day boundary', () async {
    var minute = 1199;
    final game = await _load(_guard(range: 3), () => _date(minute));
    bool locked() => game.debugInputLockSnapshot.activeTokens.any(
      (t) => t.owner == RuntimeInputLockOwner.trainerEncounter,
    );
    expect(locked(), isFalse);
    minute = 1200;
    game.update(.016);
    expect(locked(), isTrue);
    minute = 240;
    game.update(.016);
    expect(locked(), isFalse);
    expect(game.debugPendingBattleRequest, isNull);
    expect(game.debugActiveBattleRequest, isNull);
  });

  test('a disappearing NPC does not interrupt its open dialogue', () async {
    var minute = 1199;
    final game = await _load(_cow(), () => _date(minute));
    expect(
      game.dispatchOverworldInteraction(
        game.overworldInteractionSnapshot.primaryAction!.request,
      ),
      isTrue,
    );
    await _until(game, () => game.debugFlowPhaseName == 'dialogue');
    minute = 1200;
    game.update(.016);
    expect(game.debugFlowPhaseName, 'dialogue');
    expect(
      game.dialoguePresentationListenable.value?.fullText,
      'Day conversation.',
    );
    await _closeDialogue(game);
    expect(game.debugIsGameplayInputLocked, isFalse);
    expect(game.overworldInteractionSnapshot.primaryAction, isNull);
    await _stepRight(game);
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
  });

  test('one injected clock snapshot is shared for each update and reload uses current time', () async {
    var minute = 600, calls = 0;
    final game = await _load(
      _cow(),
      () {
        calls++;
        return _date(minute);
      },
      initial: const GameState(
        saveId: 'hours-progress',
        currentMapId: 'route',
        playerPosition: GridPos(x: 0, y: 1),
        playerFacing: EntityFacing.east,
        storyFlags: StoryFlags(activeFlags: {'hours-progress'}),
      ),
    );
    final before = calls;
    game.update(.016);
    for (var i = 0; i < 20; i++) {
      expect(game.overworldInteractionSnapshot.primaryAction, isNotNull);
    }
    expect(calls, before + 1);
    final saved = gameStateFromStrictSaveJson(
      strictGameStateSaveJson(game.gameStateSnapshot),
    );
    minute = 1200;
    final restored = await _load(_cow(), () => _date(minute), initial: saved);
    expect(restored.overworldInteractionSnapshot.primaryAction, isNull);
    expect(restored.gameStateSnapshot.storyFlags, saved.storyFlags);
    expect(
      restored.gameStateSnapshot.storyFlags.activeFlags,
      contains('hours-progress'),
    );
    await _stepRight(restored);
    expect(
      restored.gameStateSnapshot.playerPosition,
      const GridPos(x: 1, y: 1),
    );
  });

  test(
    'a guard becoming absent during dialogue cannot start a battle afterwards',
    () async {
      var minute = 239;
      final guard = _guard();
      final game = await _load(
        guard.copyWith(
          npc: guard.npc!.copyWith(
            trainerBattleWhen: null,
            visibilityRule: const MapEntityNpcVisibilityRule(
              mode: MapEntityNpcVisibilityMode.visibleWhen,
              predicate: _night,
            ),
          ),
        ),
        () => _date(minute),
      );
      expect(
        game.dispatchOverworldInteraction(
          game.overworldInteractionSnapshot.primaryAction!.request,
        ),
        isTrue,
      );
      await _until(game, () => game.debugFlowPhaseName == 'dialogue');
      minute = 240;
      game.update(.016);
      await _closeDialogue(game);
      expect(game.debugPendingBattleRequest, isNull);
      expect(game.debugActiveBattleRequest, isNull);
      expect(game.debugIsGameplayInputLocked, isFalse);
    },
  );

  test(
    'a queued native trainer battle is rechecked at its handoff boundary',
    () async {
      var minute = 239;
      final game = await _load(_guard(), () => _date(minute));
      expect(
        game.debugTryEnqueueBattleRequestForTest(
          const TrainerBattleStartRequest(
            requestId: 'queued-night',
            createdAtEpochMs: 0,
            trainerId: 'guard',
            npcEntityId: 'guard',
            mapId: 'route',
            playerPos: GridPos(x: 0, y: 1),
            returnContext: OverworldReturnContext(
              mapId: 'route',
              playerPos: GridPos(x: 0, y: 1),
              playerFacing: Direction.east,
            ),
          ),
        ),
        isTrue,
      );
      minute = 240;
      game.update(.016);
      expect(game.debugPendingBattleRequest, isNull);
      expect(game.debugActiveBattleRequest, isNull);
      expect(game.debugIsGameplayInputLocked, isFalse);
    },
  );
  test(
    'a scheduled disappearance waits for its active Scene actor route',
    () async {
      var minute = 1199;
      final game = await _load(_cow(), () => _date(minute), withActor: true);
      String? outcome;
      final route = game
          .debugExecuteSceneInteractiveCommand(
            SceneInteractiveCommand.actorRoute(
              target: SceneActorTarget.entity(mapId: 'route', entityId: 'cow'),
              steps: [
                SceneActorRouteStep.wait(durationMs: 100),
                SceneActorRouteStep.move(
                  direction: EntityFacing.east,
                  durationMs: 100,
                ),
              ],
            ),
          )
          .then((value) => outcome = value);
      await _until(game, () => game.debugIsGameplayInputLocked);
      minute = 1200;
      game.update(.016);
      expect(game.debugIsNpcActorVisible('cow'), isTrue);
      await _until(game, () => outcome != null);
      await route;
      expect(outcome, 'completed');
      game.update(.016);
      expect(game.debugIsNpcActorVisible('cow'), isNot(isTrue));
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
    },
  );

  test('a chosen player hour replaces the device clock for NPC hours', () async {
    final game = await _load(_cow(), () => _date(1410));
    expect(game.overworldInteractionSnapshot.primaryAction, isNull);
    const preferences = PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(),
    );
    game.applyPlayerPreferences(
      preferences.copyWith(
        worldTime: const RuntimeWorldTimePreferences(chosenMinuteOfDay: 720),
      ),
    );
    game.update(.016);
    expect(
      game.overworldInteractionSnapshot.primaryAction?.request.targetId,
      'cow',
    );
    game.applyPlayerPreferences(preferences);
    game.update(.016);
    expect(game.overworldInteractionSnapshot.primaryAction, isNull);
  });
}

DateTime _date(int minute) => DateTime(2026, 10, 24, minute ~/ 60, minute % 60);

Future<_Game> _load(
  MapEntity npc,
  DateTime Function() clock, {
  GameState? initial,
  bool withActor = false,
}) async {
  final root = await Directory.systemTemp.createTemp('npc-hours-player-');
  addTearDown(() => root.delete(recursive: true));
  if (withActor) {
    npc = npc.copyWith(npc: npc.npc!.copyWith(characterId: 'actor'));
  }
  const spawn = MapEntity(
    id: 'start',
    kind: MapEntityKind.spawn,
    pos: GridPos(x: 0, y: 1),
    blocksMovement: false,
    spawn: MapEntitySpawnData(
      role: EntitySpawnRole.playerStart,
      facing: EntityFacing.east,
    ),
  );
  final map = MapData(
    id: 'route',
    name: 'Route',
    size: const GridSize(width: 5, height: 3),
    entities: [spawn, npc],
    mapMetadata: const MapMetadata(defaultSpawnId: 'start'),
  );
  final manifest = ProjectManifest(
    name: 'Hours',
    maps: const [
      ProjectMapEntry(
        id: 'route',
        name: 'Route',
        relativePath: 'maps/route.json',
      ),
    ],
    tilesets: [
      if (withActor)
        const ProjectTilesetEntry(
          id: 'actors',
          name: 'Actors',
          relativePath: 'actors.png',
        ),
    ],
    characters: [
      if (withActor)
        const ProjectCharacterEntry(
          id: 'actor',
          name: 'Actor',
          tilesetId: 'actors',
        ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'guard',
        name: 'Guard',
        trainerClass: 'Police',
        preBattleDialogueId: 'night_challenge',
      ),
    ],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'day_talk',
        name: 'Day',
        relativePath: 'dialogues/day.yarn',
      ),
      ProjectDialogueEntry(
        id: 'night_challenge',
        name: 'Night',
        relativePath: 'dialogues/night.yarn',
      ),
    ],
  );
  await Directory('${root.path}/dialogues').create();
  await Directory('${root.path}/maps').create();
  await File('${root.path}/dialogues/day.yarn')
      .writeAsString('title: Start\n---\nDay conversation.\n===\n');
  await File('${root.path}/dialogues/night.yarn')
      .writeAsString('title: Start\n---\nNight challenge.\n===\n');
  await File('${root.path}/maps/route.json')
      .writeAsString(jsonEncode(map.toJson()));
  final project = File('${root.path}/project.json');
  await project.writeAsString(jsonEncode(manifest.toJson()));
  final game = _Game(
    bundle: RuntimeMapBundle(
      manifest: manifest,
      map: map,
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: {
        if (withActor) 'actors': '${root.path}/actors.png',
      },
    ),
    projectFilePath: project.path,
    encounterClock: clock,
    initialGameState: initial,
    runtimeTilesetImageLoader:
        (paths, {transparentColorByTilesetId = const {}}) async {
          if (!withActor) return {};
          final recorder = ui.PictureRecorder();
          ui.Canvas(recorder)
              .drawRect(const ui.Rect.fromLTWH(0, 0, 128, 128), ui.Paint());
          final picture = recorder.endRecording();
          final image = await picture.toImage(128, 128);
          picture.dispose();
          return {
            'actors': RuntimeTilesetImage(
              images: [image],
              chunks: const [
                RuntimeTilesetChunk(top: 0, height: 128, width: 128),
              ],
              width: 128,
              height: 128,
            ),
          };
        },
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
  return game;
}

Future<void> _stepRight(PlayableMapGame game) async {
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.right),
  );
  game.update(.016);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.right),
  );
  await _until(game, () => !game.debugIsPlayerStepping);
}

Future<void> _closeDialogue(PlayableMapGame game) async {
  for (var i = 0; i < 8 && game.debugFlowPhaseName == 'dialogue'; i++) {
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    );
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.primary),
    );
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  await _until(
    game,
    () =>
        game.debugFlowPhaseName == 'overworld' &&
        !game.debugHasPendingDialogueLoad,
  );
}

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var i = 0; i < 240; i++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('The NPC hours fixture did not settle');
}

final class _Game extends PlayableMapGame {
  _Game({
    required super.bundle,
    required super.projectFilePath,
    super.encounterClock,
    super.initialGameState,
    super.runtimeTilesetImageLoader,
  });
  @override
  bool get isLoaded => true;
}
