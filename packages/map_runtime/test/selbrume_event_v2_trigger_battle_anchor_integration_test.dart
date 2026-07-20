import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_event_v2_test_fixture.dart';

const _guardianEventId = 'evt_019abcde-5000-7000-8000-000000000026';
const _guardianTriggerId = 'tr_phare_guardian_1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Event V2 guardian returns to overworld and can retry after defeat',
    () async {
      final fixture = SelbrumeEventV2RuntimeFixture.locateCanonical();
      final source = await loadRuntimeMapBundle(
        projectFilePath: fixture.projectPath,
        mapId: 'map_phare_interieur',
      );
      final bundle = _guardianHarnessBundle(source);
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: fixture.projectPath,
        saveData: saveDataFromGameState(
          GameState(
            saveId: 'selbrume_event_v2_trigger_battle_anchor',
            currentMapId: 'map_phare_interieur',
            playerPosition: const GridPos(x: 8, y: 31),
            playerFacing: EntityFacing.south,
            party: const PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'charmander',
                  natureId: 'hardy',
                  abilityId: 'blaze',
                  level: 100,
                  knownMoveIds: <String>['ember', 'growl'],
                  currentHp: 1,
                ),
              ],
            ),
            narrativeFactRuntimeState: NarrativeFactRuntimeState(
              overridesByFactId: const <String, bool>{
                'fact_lighthouse_old_note_read': true,
              },
            ),
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      await _load(game);
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState
            .overridesByFactId['fact_lighthouse_old_note_read'],
        isTrue,
      );
      await _move(game, RuntimeInputControl.down);
      expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 32));
      await _pumpUntil(
        game,
        () =>
            game.debugFlowPhaseName != 'overworld' ||
            game.debugNotificationText != null,
      );
      expect(
        game.debugFlowPhaseName,
        'battleTransition',
        reason: game.debugNotificationText,
      );
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'battle');
      await game.debugWaitForBattleOverlaySync();

      final battle = game.debugBattleSessionSnapshot;
      expect(battle, isNotNull);
      expect(battle!.setup.isTrainerBattle, isTrue);
      expect(battle.setup.trainerId, 'trainer_phare_gardien_1');
      expect(battle.state.enemy.speciesId, 'magnemite');

      await _chooseMoveUntilBattleEnds(game, chooseStatusMove: true);
      await _pumpUntil(
        game,
        () => game.debugFlowPhaseName == 'overworld',
      );
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState
            .overridesByFactId['fact_lighthouse_guardian_1_defeated'],
        isNot(isTrue),
      );
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(_guardianEventId)),
      );
      await _pumpUntil(
        game,
        () =>
            !game.debugIsNarrativeSpatialDispatchInFlight &&
            !game.debugIsNarrativeOutcomeWorkInFlight &&
            !game.debugHasPendingSceneBattle,
      );
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(game.debugIsMapActivationDispatchInFlight, isFalse);

      // The runtime deliberately requires a fresh trigger entry. Leaving and
      // re-entering proves that battle/Scene locks are released after defeat.
      await _move(game, RuntimeInputControl.right);
      expect(game.debugPlayerGridPosition, const GridPos(x: 9, y: 32));
      await _move(game, RuntimeInputControl.left);
      expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 32));
      await _pumpUntil(
        game,
        () =>
            game.debugFlowPhaseName == 'battleTransition' ||
            game.debugFlowPhaseName == 'battle',
      );
      await _pumpUntil(game, () => game.debugFlowPhaseName == 'battle');
      await game.debugWaitForBattleOverlaySync();

      await _chooseMoveUntilBattleEnds(game);
      await _pumpUntil(
        game,
        () =>
            game.debugFlowPhaseName == 'overworld' &&
            game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId['fact_lighthouse_guardian_1_defeated'] ==
                true,
      );

      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(_guardianEventId)),
        reason: 'Victory closes this reusable trigger through its Fact, not '
            'through one-shot consumption.',
      );
    },
  );
}

RuntimeMapBundle _guardianHarnessBundle(RuntimeMapBundle source) {
  const spawnId = 'selbrume_guardian_anchor_test_spawn';
  final map = source.map.copyWith(
    entities: <MapEntity>[
      for (final entity in source.map.entities)
        if (entity.kind != MapEntityKind.spawn) entity,
      const MapEntity(
        id: spawnId,
        name: 'Guardian anchor integration spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 8, y: 31),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
    ],
    mapMetadata: source.map.mapMetadata.copyWith(defaultSpawnId: spawnId),
  );
  expect(
    map.triggers.where((trigger) => trigger.id == _guardianTriggerId),
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

Future<void> _chooseMoveUntilBattleEnds(
  PlayableMapGame game, {
  bool chooseStatusMove = false,
}) async {
  for (var turn = 0; turn < 20; turn++) {
    if (game.debugFlowPhaseName != 'battle') return;
    await _waitForBattleInputReady(game);
    if (game.debugFlowPhaseName != 'battle') return;
    final overlay = game.debugBattleOverlayComponent;
    expect(overlay, isNotNull);
    final activeOverlay = overlay!;
    if (activeOverlay.currentMenuMode.name == 'continueOnly') {
      _pressPrimary(game);
      await _waitForBattleInputReady(game);
      continue;
    }
    for (var back = 0;
        back < 3 && activeOverlay.currentMenuMode.name != 'root';
        back++) {
      expect(game.backFromBattleOverlay(), isTrue);
      await _microPump(game);
    }
    expect(activeOverlay.currentMenuMode.name, 'root');
    _pressPrimary(game);
    await _microPump(game);
    expect(activeOverlay.currentMenuMode.name, 'fight');

    final battle = game.debugBattleSessionSnapshot;
    expect(battle, isNotNull);
    final moveIndex = battle!.state.player.moves.indexWhere(
      (move) => chooseStatusMove ? move.power == 0 : move.power > 0,
    );
    expect(moveIndex, greaterThanOrEqualTo(0));
    if (moveIndex >= 2) {
      await _pressBattleDirection(game, RuntimeInputControl.down);
    }
    if (moveIndex.isOdd) {
      await _pressBattleDirection(game, RuntimeInputControl.right);
    }
    _pressPrimary(game);
    await _waitForBattleInputReady(game);
  }
  fail('The canonical guardian battle exceeded 20 real turns.');
}

Future<void> _waitForBattleInputReady(PlayableMapGame game) async {
  await game.debugWaitForBattleOverlaySync();
  await _pumpUntil(
    game,
    () =>
        game.debugFlowPhaseName != 'battle' ||
        !(game.debugBattleOverlayComponent?.isTurnPresentationActive ?? false),
  );
}

void _pressPrimary(PlayableMapGame game) {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    ),
    isTrue,
  );
}

Future<void> _pressBattleDirection(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  await _microPump(game);
}

Future<void> _microPump(PlayableMapGame game) async {
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
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
    'Timed out in Event V2 trigger battle anchor integration '
    '(phase=${game.debugFlowPhaseName}, '
    'notification=${game.debugNotificationText}, '
    'spatial=${game.debugIsNarrativeSpatialDispatchInFlight}, '
    'outcome=${game.debugIsNarrativeOutcomeWorkInFlight}, '
    'sceneBattle=${game.debugHasPendingSceneBattle}, '
    'pendingTrigger=${game.debugPendingNarrativeTriggerEntryCount}, '
    'position=${game.debugPlayerGridPosition}, '
    'party=${game.gameStateSnapshot.party.members.map((member) => member.currentHp).toList()}, '
    'pendingOutcomes=${game.gameStateSnapshot.narrativeEventProgress.pendingNarrativeOutcomeDeliveries}).',
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
