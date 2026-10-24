import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart'
    show
        Direction,
        NarrativeSceneExecutionRequest,
        NarrativeSceneExecutionCompleted,
        PlayerPokemonHydrationSpecies,
        PokemonBaseStats;
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

const _ready = MapEntityRuntimePredicate(
  kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast,
  minimumCount: 2,
);
MapEntity _pair({int range = 0}) => MapEntity(
  id: 'guard',
  kind: MapEntityKind.npc,
  pos: const GridPos(x: 1, y: 1),
  npc: MapEntityNpcData(
    trainerId: 'guard',
    facing: EntityFacing.west,
    lineOfSightRange: range,
    dialogue: const DialogueRef(dialogueId: 'night_challenge'),
    defeatDialogueRef: const DialogueRef(dialogueId: 'after'),
    trainerBattleReadyWhen: _ready,
    trainerBattleNotReadyDialogue: const DialogueRef(dialogueId: 'day_talk'),
  ),
);
GameState _state(List<int> hp) => GameState(
  saveId: 'ready',
  currentMapId: 'route',
  playerPosition: const GridPos(x: 0, y: 1),
  playerFacing: EntityFacing.east,
  party: PlayerParty(
    members: [
      for (var i = 0; i < hp.length; i++)
        PlayerPokemon(
          individualId: 'mon-$i',
          speciesId: 'rattata',
          natureId: 'hardy',
          abilityId: 'run_away',
          currentHp: hp[i],
        ),
    ],
  ),
);
const _request = TrainerBattleStartRequest(
  requestId: 'queued-readiness',
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
);
SceneAsset _holdScene() => SceneAsset(
  id: 'hold',
  name: 'Hold',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'wait',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.wait(durationMs: 200),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'wait',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'done',
        fromNodeId: 'wait',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);
Future<void> _talk(_Game game) async {
  expect(
    game.dispatchOverworldInteraction(
      game.overworldInteractionSnapshot.primaryAction!.request,
    ),
    isTrue,
  );
  await _until(game, () => game.debugFlowPhaseName == 'dialogue');
}

Future<void> _changePartyDuringPresentation(_Game game, List<int> hp) async {
  final scene = game.debugExecuteNarrativeSceneForTest(
    NarrativeSceneExecutionRequest(
      eventId: 'private-race',
      sceneId: 'hold',
      executionId: 'race',
      gameState: game.gameStateSnapshot,
    ),
  );
  var replaced = false;
  for (var i = 0; i < 500 && !replaced; i++) {
    try {
      game.debugReplaceNarrativePresentationStateForTest(
        game.gameStateSnapshot.copyWith(party: _state(hp).party),
      );
      replaced = true;
    } on StateError {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }
  expect(replaced, isTrue);
  var sceneComplete = false;
  scene.whenComplete(() => sceneComplete = true);
  await _until(game, () => sceneComplete);
  expect(await scene, isA<NarrativeSceneExecutionCompleted>());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'manual refusal and defeated dialogue use separate lifecycle scopes',
    () async {
      final game = await _load(
        _pair(),
        () => _date(600),
        initial: _state([1, 0]),
      );
      await _talk(game);
      expect(
        game.dialoguePresentationListenable.value?.fullText,
        'Two healthy Pokemon required.',
      );
      await _closeDialogue(game);
      game.debugMarkTrainerAsDefeated('guard');
      await _talk(game);
      expect(
        game.dialoguePresentationListenable.value?.fullText,
        'After fight.',
      );
      expect(game.debugActiveBattleRequest, isNull);
    },
  );
  test(
    'queued handoff rejects newly ineligible and defeated one shot trainers',
    () async {
      for (final defeated in [false, true]) {
        final game = await _load(
          _pair(),
          () => _date(600),
          initial: _state([1, 1]),
        );
        expect(game.debugTryEnqueueBattleRequestForTest(_request), isTrue);
        if (defeated) {
          game.debugMarkTrainerAsDefeated('guard');
        } else {
          await _changePartyDuringPresentation(game, [1, 0]);
        }
        game.update(.016);
        expect(game.debugPendingBattleRequest, isNull);
        expect(game.debugActiveBattleRequest, isNull);
        expect(game.debugIsGameplayInputLocked, isFalse);
      }
    },
  );
  test('defeat recorded during the intro wins over a second battle', () async {
    final game = await _load(
      _pair(),
      () => _date(600),
      initial: _state([1, 1]),
    );
    await _talk(game);
    game.debugMarkTrainerAsDefeated('guard');
    for (
      var i = 0;
      i < 6 &&
          game.dialoguePresentationListenable.value?.fullText != 'After fight.';
      i++
    ) {
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
          game.dialoguePresentationListenable.value?.fullText == 'After fight.',
    );
    expect(game.debugActiveBattleRequest, isNull);
  });
  for (final defeatedDuringIntro in [false, true]) {
    test(
      'party loss during intro is rechecked, defeated=$defeatedDuringIntro',
      () async {
        final game = await _load(
          _pair(),
          () => _date(600),
          initial: _state([1, 1]),
        );
        await _talk(game);
        if (defeatedDuringIntro) game.debugMarkTrainerAsDefeated('guard');
        final expected = defeatedDuringIntro
            ? 'After fight.'
            : 'Two healthy Pokemon required.';
        await _changePartyDuringPresentation(game, [1, 0]);
        for (
          var i = 0;
          i < 6 &&
              game.dialoguePresentationListenable.value?.fullText != expected;
          i++
        ) {
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
          () => game.dialoguePresentationListenable.value?.fullText == expected,
        );
        expect(game.debugPendingBattleRequest, isNull);
        expect(game.debugActiveBattleRequest, isNull);
      },
    );
  }
  test(
    'line of sight remains idle for a fainted second party member',
    () async {
      final game = await _load(
        _pair(range: 3),
        () => _date(600),
        initial: _state([1, 0]),
      );
      game.update(.016);
      expect(
        game.debugInputLockSnapshot.activeTokens.any(
          (token) => token.owner == RuntimeInputLockOwner.trainerEncounter,
        ),
        isFalse,
      );
    },
  );
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
    name: 'Readiness',
    scenes: [_holdScene()],
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
        id: 'after',
        name: 'After',
        relativePath: 'dialogues/after.yarn',
      ),
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
  await File('${root.path}/dialogues/after.yarn')
      .writeAsString('title: Start\n---\nAfter fight.\n===\n');
  await File('${root.path}/dialogues/day.yarn')
      .writeAsString('title: Start\n---\nTwo healthy Pokemon required.\n===\n');
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
    runtimePlayerPokemonProgressionCatalogLoader:
        ({
          required gameState,
          required projectRootDirectory,
          required pokemonConfig,
        }) async => const RuntimePlayerPokemonProgressionCatalogs(
          speciesById: {
            'rattata': PlayerPokemonHydrationSpecies(
              id: 'rattata',
              baseStats: PokemonBaseStats(
                hp: 30,
                attack: 56,
                defense: 35,
                specialAttack: 25,
                specialDefense: 35,
                speed: 72,
              ),
              primaryAbilityId: 'run_away',
              abilityIds: ['run_away'],
              growthRateId: 'medium_fast',
            ),
          },
          maxPpByMoveId: {},
        ),
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
    super.runtimePlayerPokemonProgressionCatalogLoader,
    super.runtimeTilesetImageLoader,
  });
  @override
  bool get isLoaded => true;
}
