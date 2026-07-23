import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_event_v2_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonical no-save boot gives the selected starter exactly once',
    () async {
      final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
      final source = await loadRuntimeMapBundle(
        projectFilePath: fixture.projectPath,
        mapId: 'map_bourg_selbrume',
      );
      final bundle = _starterHarnessBundle(source);
      final repository = _MemoryGameSaveRepository();
      final maelEvent = bundle.manifest.eventRegistry!.records
          .map((record) => record.definitionOrNull)
          .whereType<NarrativeEventDefinition>()
          .singleWhere(
            (event) =>
                event.sceneId == 'scene_mael_intro' &&
                event.source ==
                    NarrativeEventSourceRef.entityInteract(
                      'map_bourg_selbrume',
                      'npc_mael',
                    ),
          );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: fixture.projectPath,
        saveRepository: repository,
        runtimeMapBundleLoader: ({
          required String projectFilePath,
          required String mapId,
        }) async {
          expect(projectFilePath, fixture.projectPath);
          if (mapId == 'map_bourg_selbrume') return bundle;
          return loadRuntimeMapBundle(
            projectFilePath: projectFilePath,
            mapId: mapId,
          );
        },
      );

      expect(game.gameStateSnapshot.party.members, isEmpty);
      expect(_bagQuantity(game.gameStateSnapshot, 'poke-ball'), 0);
      expect(game.gameStateSnapshot.currentMapId, 'map_bourg_selbrume');

      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');
      await _completeOpenDialogue(game);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.narrativeEventProgress
                .consumedNarrativeEventIds
                .contains(maelEvent.id) &&
            !game.debugIsNarrativeSpatialDispatchInFlight,
      );

      final completed = game.gameStateSnapshot;
      expect(completed.party.members, hasLength(1));
      expect(_bagQuantity(completed, 'poke-ball'), 5);
      final starter = completed.party.members.single;
      expect(starter.speciesId, 'bulbasaur');
      expect(starter.level, 16);
      expect(starter.experience, 2535);
      expect(
        starter.currentPpByMoveId,
        <String, int>{'tackle': 35, 'growl': 40, 'vine_whip': 25},
      );
      expect(
        completed.narrativeFactRuntimeState
            .overridesByFactId['fact_starter_received'],
        isTrue,
      );
      expect(
        completed.narrativeFactRuntimeState
            .overridesByFactId['fact_mael_mission_given'],
        isTrue,
      );
      expect(
        completed.progression.completedStepIds,
        containsAll(<String>['step_intro_selbrume', 'step_receive_mission']),
      );

      expect(await game.saveGame(), isTrue);
      final savedStarter = repository.storedState!.party.members.single;
      expect(savedStarter.experience, 2535);
      expect(savedStarter.currentPpByMoveId, isNotNull);
      expect(await game.loadGame(), isTrue);
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );
      await _pumpUntil(
        game,
        () => game.debugFlowPhaseName == 'dialogue',
      );
      await _completeOpenDialogue(game);
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'overworld');

      expect(game.gameStateSnapshot.party.members, hasLength(1));
      final reloadedStarter = game.gameStateSnapshot.party.members.single;
      expect(reloadedStarter.experience, 2535);
      expect(
        reloadedStarter.currentPpByMoveId,
        <String, int>{'tackle': 35, 'growl': 40, 'vine_whip': 25},
      );
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(maelEvent.id),
      );
      expect(_bagQuantity(game.gameStateSnapshot, 'poke-ball'), 5);
    },
  );

  test('canonical existing-party path skips starter and converges', () async {
    final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
    final source = await loadRuntimeMapBundle(
      projectFilePath: fixture.projectPath,
      mapId: 'map_bourg_selbrume',
    );
    final bundle = _starterHarnessBundle(source);
    final game = _TestPlayableMapGame(
      bundle: bundle,
      projectFilePath: fixture.projectPath,
      saveData: saveDataFromGameState(
        GameState(
          saveId: 'existing_party',
          currentMapId: 'map_bourg_selbrume',
          playerPosition: const GridPos(x: 17, y: 24),
          playerFacing: EntityFacing.north,
          party: const PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'eevee',
                natureId: 'hardy',
                abilityId: 'run-away',
                level: 5,
                currentHp: 20,
              ),
            ],
          ),
          narrativeFactRuntimeState: NarrativeFactRuntimeState(
            overridesByFactId: const <String, bool>{
              'fact_player_started_with_existing_pokemon': true,
            },
          ),
        ),
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
      runtimeMapBundleLoader: ({
        required String projectFilePath,
        required String mapId,
      }) async {
        if (mapId == 'map_bourg_selbrume') return bundle;
        return loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: mapId,
        );
      },
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _pumpUntil(
      game,
      () => !game.debugIsMapActivationDispatchInFlight,
    );
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');
    await _completeOpenDialogue(game);
    await _pumpUntil(
      game,
      () =>
          game.gameStateSnapshot.narrativeFactRuntimeState
              .overridesByFactId['fact_mael_mission_given'] ==
          true,
    );

    final completed = game.gameStateSnapshot;
    expect(completed.party.members, hasLength(1));
    expect(completed.party.members.single.speciesId, 'eevee');
    expect(_bagQuantity(completed, 'poke-ball'), 5);
    expect(
      completed
          .narrativeFactRuntimeState.overridesByFactId['fact_starter_received'],
      isNot(isTrue),
    );
    expect(
      completed.progression.completedStepIds,
      containsAll(<String>['step_intro_selbrume', 'step_receive_mission']),
    );
  });
}

int _bagQuantity(GameState state, String itemId) => state.bag.entries
    .where((entry) => entry.itemId == itemId)
    .fold(0, (total, entry) => total + entry.quantity);

RuntimeMapBundle _starterHarnessBundle(RuntimeMapBundle source) {
  final map = source.map.copyWith(
    entities: <MapEntity>[
      for (final entity in source.map.entities)
        if (entity.id == 'spawn')
          entity.copyWith(
            pos: const GridPos(x: 17, y: 24),
            spawn: entity.spawn?.copyWith(facing: EntityFacing.north),
          )
        else if (entity.id == 'npc_mael')
          entity.copyWith(pos: const GridPos(x: 17, y: 23))
        else
          entity,
    ],
  );
  return RuntimeMapBundle(
    manifest: source.manifest,
    map: map,
    projectRootDirectory: source.projectRootDirectory,
    tilesetAbsolutePathsById: source.tilesetAbsolutePathsById,
  );
}

Future<void> _completeOpenDialogue(PlayableMapGame game) async {
  for (var advanceCount = 0; advanceCount < 20; advanceCount++) {
    if (game.debugFlowPhaseName != 'dialogue') return;
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('The canonical Maël Yarn stayed open after 20 explicit inputs.');
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 2000,
}) async {
  for (var tick = 0; tick < maxTicks; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Timed out in canonical starter integration: '
    'phase=${game.debugFlowPhaseName}.',
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.saveRepository,
    super.runtimeMapBundleLoader,
    super.initialMapActivationReason,
  });

  bool _loadedForTest = false;

  @override
  bool get isLoaded => _loadedForTest;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadedForTest = true;
  }
}

final class _MemoryGameSaveRepository implements GameSaveRepository {
  GameState? storedState;

  @override
  Future<void> save(GameState state) async => storedState = state;

  @override
  Future<GameState?> load() async => storedState;

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async => storedState = null;
}
