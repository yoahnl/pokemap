import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_event_v2_test_fixture.dart';

const _bossEventId = 'evt_019abcde-5000-7000-8000-000000000028';
const _bossTriggerId = 'tr_sommet_confrontation';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonical lighthouse boss uses the PlayableMapGame static battle pipeline',
    () async {
      final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
      final source = await loadRuntimeMapBundle(
        projectFilePath: fixture.projectPath,
        mapId: 'map_sommet_phare',
      );
      final bundle = _bossHarnessBundle(source);
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: fixture.projectPath,
        saveData: saveDataFromGameState(
          GameState(
            saveId: 'selbrume_static_boss_pipeline',
            currentMapId: 'map_sommet_phare',
            playerPosition: const GridPos(x: 12, y: 11),
            playerFacing: EntityFacing.north,
            party: const PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'bulbasaur',
                  natureId: 'hardy',
                  abilityId: 'overgrow',
                  level: 100,
                  knownMoveIds: <String>['tackle'],
                  currentHp: 999,
                ),
              ],
            ),
            narrativeFactRuntimeState: NarrativeFactRuntimeState(
              overridesByFactId: const <String, bool>{
                'fact_lighthouse_top_unlocked': true,
                'fact_lighthouse_guardian_2_defeated': true,
              },
            ),
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      await _load(game);
      await _move(game, RuntimeInputControl.up);
      await _pumpUntil(
        game,
        () => game.debugFlowPhaseName == 'dialogue',
      );
      await _completeOpenDialogue(game);
      await _pumpUntil(
        game,
        () => game.debugFlowPhaseName == 'battleTransition',
      );

      await _pumpUntil(game, () => game.debugFlowPhaseName == 'battle');
      await game.debugWaitForBattleOverlaySync();

      final battle = game.debugBattleSessionSnapshot;
      expect(battle, isNotNull);
      expect(battle!.setup.isTrainerBattle, isFalse);
      expect(battle.setup.allowCapture, isFalse);
      expect(battle.setup.allowFlee, isFalse);
      expect(battle.setup.trainerId, isNull);
      expect(battle.state.enemy.speciesId, 'lanturn');
      expect(
        battle.decisionRequest.allowedChoices
            .whereType<PlayerBattleChoiceRun>(),
        isEmpty,
      );
      expect(
        () => battle.applyChoice(const PlayerBattleChoiceRun()),
        throwsA(isA<StateError>()),
      );

      await _chooseFirstMoveUntilBattleEnds(game);
      await _pumpUntil(
        game,
        () =>
            game.debugFlowPhaseName == 'overworld' &&
            game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId['fact_mist_source_resolved'] ==
                true,
      );

      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_bossEventId),
      );
      expect(
        game.gameStateSnapshot.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:trainer_boss_phare_pokemon')),
        reason: 'A static boss must not be written back as a defeated trainer.',
      );
    },
  );
}

RuntimeMapBundle _bossHarnessBundle(RuntimeMapBundle source) {
  const spawnId = 'selbrume_static_boss_test_spawn';
  final map = source.map.copyWith(
    entities: <MapEntity>[
      for (final entity in source.map.entities)
        if (entity.kind != MapEntityKind.spawn) entity,
      const MapEntity(
        id: spawnId,
        name: 'Static boss integration spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 12, y: 11),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.north,
        ),
      ),
    ],
    mapMetadata: source.map.mapMetadata.copyWith(defaultSpawnId: spawnId),
  );
  expect(
    map.triggers.where((trigger) => trigger.id == _bossTriggerId),
    hasLength(1),
  );
  return RuntimeMapBundle(
    manifest: source.manifest,
    map: map,
    projectRootDirectory: source.projectRootDirectory,
    tilesetAbsolutePathsById: source.tilesetAbsolutePathsById,
  );
}

Future<void> _load(_TestPlayableMapGame game) async {
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

Future<void> _move(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  await _pumpUntil(game, () => !game.debugIsPlayerStepping);
}

Future<void> _completeOpenDialogue(PlayableMapGame game) async {
  for (var inputCount = 0; inputCount < 20; inputCount++) {
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
  fail('The canonical boss Yarn stayed open after 20 explicit inputs.');
}

Future<void> _chooseFirstMoveUntilBattleEnds(PlayableMapGame game) async {
  for (var turn = 0; turn < 80; turn++) {
    if (game.debugFlowPhaseName != 'battle') return;
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await game.debugWaitForBattleOverlaySync();
    if (game.debugFlowPhaseName != 'battle') return;
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await game.debugWaitForBattleOverlaySync();
    await _pumpUntil(
      game,
      () {
        if (game.debugFlowPhaseName != 'battle') return true;
        final overlay = game.debugBattleOverlayComponent;
        return overlay != null && !overlay.isTurnPresentationActive;
      },
    );
  }
  fail('The canonical static boss battle exceeded 80 real turns.');
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 3000,
}) async {
  for (var tick = 0; tick < maxTicks; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Timed out in static boss PlayableMapGame integration '
    '(phase=${game.debugFlowPhaseName}).',
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveData,
    required super.initialMapActivationReason,
  });

  @override
  bool get isLoaded => true;
}
