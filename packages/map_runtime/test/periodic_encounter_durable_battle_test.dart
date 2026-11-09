import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'session/spatial_exploration_game_session_runtime_test.dart' as session;
import 'source_converted_gym_reward_journey_test.dart'
    show installConvertedQaHeadlessAudio;
import 'spatial_battle_runtime_test.dart' as battle;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    installConvertedQaHeadlessAudio(completePlayback: true);
    await AudioPlayer.global.ensureInitialized();
  });

  testWidgets(
    '3D ordinary Scene battles retain their existing zero-checkpoint cadence',
    (tester) async {
      final fixture = (await tester.runAsync(() => _fixture(periodic: false)))!;
      final writer = _Writer(fixture.root);
      final runtime = _spatial(fixture, writer);
      addTearDown(runtime.dispose);
      await tester.runAsync(() => runtime.load((_) {}));
      await _until(
        tester,
        () => runtime.battle?.isActive == true,
        () => '${runtime.session?.interactionError.value}',
      );
      await _readySpatial(tester, runtime.battle!);
      await battle.submitFriendContextualCapture(tester, runtime.battle!);
      await battle.acknowledgeContextualCaptureBattle(tester, runtime.battle!);
      await _gameplaySettled(tester, runtime);
      expect(writer.attempts, 0);
      expect(runtime.gameStateSnapshot.party.members, hasLength(2));
      expect(runtime.gameStateSnapshot.bag.entries.single.quantity, 49);
      expect(runtime.gameStateSnapshot.periodicRewardState.claimsById, isEmpty);
      expect(runtime.gameStateSnapshot.completedBattleRequestIds, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    '3D periodic battle without a durable writer fails before launch',
    (tester) async {
      final fixture = (await tester.runAsync(_fixture))!;
      final writer = _Writer(fixture.root);
      final runtime = _spatial(fixture, writer, durable: false);
      addTearDown(runtime.dispose);
      await tester.runAsync(() => runtime.load((_) {}));
      await _gameplaySettled(tester, runtime);
      expect(runtime.battle!.isActive, isFalse);
      expect(
        runtime.session!.interactionError.value.toString(),
        contains('durable Scene checkpoint'),
      );
      expect(writer.attempts, 0);
      expect(runtime.gameStateSnapshot.party, fixture.state.party);
      expect(runtime.gameStateSnapshot.bag, fixture.state.bag);
    },
  );

  for (final fullParty in [false, true]) {
    testWidgets(
      '3D periodic capture persists full ${fullParty ? 'PC' : 'party'} result before Scene completion',
      (tester) async {
        final fixture = (await tester.runAsync(
          () => _fixture(fullParty: fullParty),
        ))!;
        final writer = _Writer(fixture.root);
        final runtime = _spatial(fixture, writer);
        addTearDown(runtime.dispose);
        await tester.runAsync(() => runtime.load((_) {}));
        await _until(
          tester,
          () => runtime.battle?.isActive == true,
          () => '${runtime.session?.interactionError.value}',
        );
        final engine = runtime.battle!;
        await _readySpatial(tester, engine);
        expect(
          await battle.submitFriendContextualCapture(tester, engine),
          isTrue,
        );
        expect(engine.displaySession!.state.outcome!.isCaptured, isTrue);
        writer.now = DateTime(2026, 11, 7, 0, 1);
        expect(writer.writes, 0);
        await battle.acknowledgeContextualCaptureBattle(tester, engine);
        await _gameplaySettled(tester, runtime);
        expect(writer.writes, 1);
        final saved = (await tester.runAsync(writer.read))!;
        expect(
          saved.periodicRewardState
              .claimFor('weekly-target')!
              .lastClaimLocalDay,
          '2026-11-06',
        );
        expect(saved.completedBattleRequestIds, hasLength(1));
        expect(saved.bag.entries.single.quantity, 49);
        expect(
          saved.playerSpatialPosition,
          fixture.state.playerSpatialPosition,
        );
        expect(saved.party.members.length, fullParty ? 6 : 2);
        expect(saved.pokemonStorage.storedPokemon.length, fullParty ? 1 : 0);
        final captured = fullParty
            ? saved.pokemonStorage.storedPokemon.single
            : saved.party.members.last;
        expect(captured.speciesId, 'sparkitten');
        expect(captured.friendship, 200);
        expect(captured.individualId, isNotEmpty);
        expect(captured.currentPpByMoveId, isNotEmpty);
        expect(
          runtime.gameStateSnapshot.trainerProfile.money,
          saved.trainerProfile.money + 5,
        );
        expect(runtime.gameStateSnapshot.party, saved.party);
        expect(runtime.gameStateSnapshot.pokemonStorage, saved.pokemonStorage);
        expect(runtime.session!.interactionError.value, isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final recover in [false, true]) {
    testWidgets(
      '3D later Scene failure retains the entire durable ${recover ? 'recovery' : 'capture'} checkpoint on cold Continue',
      (tester) async {
        final fixture = (await tester.runAsync(
          () => _fixture(failLater: true, defeat: recover, recover: recover),
        ))!;
        final writer = _Writer(fixture.root);
        var runtime = _spatial(fixture, writer);
        addTearDown(() => runtime.dispose());
        await tester.runAsync(() => runtime.load((_) {}));
        await _until(
          tester,
          () => runtime.battle?.isActive == true,
          () => '${runtime.session?.interactionError.value}',
        );
        await _readySpatial(tester, runtime.battle!);
        if (recover) {
          await battle.submitSpatialBattleChoice(
            tester,
            runtime.battle!,
            runtime.battle!.displaySession!.decisionRequest.allowedChoices
                .whereType<PlayerBattleChoiceFight>()
                .first,
          );
        } else {
          await battle.submitFriendContextualCapture(tester, runtime.battle!);
        }
        await battle.acknowledgeContextualCaptureBattle(
          tester,
          runtime.battle!,
        );
        await _gameplaySettled(tester, runtime);
        final saved = (await tester.runAsync(writer.read))!;
        expect(runtime.session!.interactionError.value, isNotNull);
        await tester.pump(const Duration(milliseconds: 100));
        expect(runtime.gameStateSnapshot.playerPosition, saved.playerPosition);
        expect(runtime.session!.movement.x.floor(), saved.playerPosition.x);
        expect(runtime.session!.movement.z.floor(), saved.playerPosition.y);
        expect(runtime.gameStateSnapshot.party, saved.party);
        expect(runtime.gameStateSnapshot.pokemonStorage, saved.pokemonStorage);
        expect(runtime.gameStateSnapshot.bag, saved.bag);
        expect(
          runtime.gameStateSnapshot.trainerProfile.money,
          saved.trainerProfile.money,
        );
        expect(
          runtime.gameStateSnapshot.periodicRewardState,
          saved.periodicRewardState,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(runtime.dispose);
        runtime = _spatial(fixture, writer, continueGame: true);
        addTearDown(runtime.dispose);
        await tester.runAsync(() => runtime.load((_) {}));
        if (recover) {
          await _until(
            tester,
            () => runtime.battle!.isActive,
            () => '${runtime.session?.interactionError.value}',
          );
        } else {
          await _gameplaySettled(tester, runtime);
          expect(runtime.battle!.isActive, isFalse);
        }
        expect(runtime.gameStateSnapshot.playerPosition, saved.playerPosition);
        expect(runtime.gameStateSnapshot.party, saved.party);
        expect(runtime.gameStateSnapshot.bag, saved.bag);
        expect(
          runtime.gameStateSnapshot.completedBattleRequestIds,
          saved.completedBattleRequestIds,
        );
        expect(
          runtime.gameStateSnapshot.periodicRewardState,
          saved.periodicRewardState,
        );
        expect(writer.writes, 1);
      },
    );
  }

  for (final outcome in ['victory', 'fled', 'defeat']) {
    testWidgets(
      '3D periodic $outcome persists the complete result with the configured claim',
      (tester) async {
        final fixture = (await tester.runAsync(
          () => _fixture(defeat: outcome == 'defeat'),
        ))!;
        final writer = _Writer(fixture.root);
        final runtime = _spatial(fixture, writer);
        addTearDown(runtime.dispose);
        await tester.runAsync(() => runtime.load((_) {}));
        await _until(
          tester,
          () => runtime.battle?.isActive == true,
          () => '${runtime.session?.interactionError.value}',
        );
        final engine = runtime.battle!;
        await _readySpatial(tester, engine);
        for (var i = 0; i < 40 && engine.postBattleOverlay == null; i++) {
          final choice = outcome == 'fled'
              ? const PlayerBattleChoiceRun()
              : engine.displaySession!.decisionRequest.allowedChoices
                    .whereType<PlayerBattleChoiceFight>()
                    .first;
          expect(
            await battle.submitSpatialBattleChoice(tester, engine, choice),
            isTrue,
          );
        }
        expect(
          engine.displaySession!.state.outcome!.type.name,
          outcome == 'fled' ? 'runaway' : outcome,
        );
        final beforeExperience = engine
            .postBattleOverlay!
            .currentTransaction!
            .originalState
            .party
            .members
            .first
            .experience;
        await battle.acknowledgeContextualCaptureBattle(tester, engine);
        await _gameplaySettled(tester, runtime);
        expect(writer.writes, 1);
        final saved = (await tester.runAsync(writer.read))!;
        expect(saved.completedBattleRequestIds, hasLength(1));
        expect(
          saved.periodicRewardState.claimFor('weekly-target') != null,
          outcome != 'defeat',
        );
        expect(saved.party.members, hasLength(1));
        expect(saved.bag, fixture.state.bag);
        if (outcome == 'victory') {
          expect(
            saved.party.members.first.experience,
            greaterThan(beforeExperience!),
          );
          expect(
            saved.party.members.first.currentPpByMoveId!['tackle'],
            lessThan(35),
          );
        }
        if (outcome == 'defeat') expect(saved.party.members.first.currentHp, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    '3D periodic defeat saves the complete return-to-recovery result without a claim',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => _fixture(defeat: true, recover: true),
      ))!;
      final writer = _Writer(fixture.root);
      final runtime = _spatial(fixture, writer);
      addTearDown(runtime.dispose);
      await tester.runAsync(() => runtime.load((_) {}));
      await _until(
        tester,
        () => runtime.battle?.isActive == true,
        () => '${runtime.session?.interactionError.value}',
      );
      final engine = runtime.battle!;
      await _readySpatial(tester, engine);
      expect(
        await battle.submitSpatialBattleChoice(
          tester,
          engine,
          engine.displaySession!.decisionRequest.allowedChoices
              .whereType<PlayerBattleChoiceFight>()
              .first,
        ),
        isTrue,
      );
      expect(engine.displaySession!.state.outcome!.isDefeat, isTrue);
      await battle.acknowledgeContextualCaptureBattle(tester, engine);
      await _gameplaySettled(tester, runtime);
      final saved = (await tester.runAsync(writer.read))!;
      expect(writer.writes, 1);
      expect(saved.currentMapId, fixture.state.currentMapId);
      expect(saved.playerPosition, const GridPos(x: 2, y: 1));
      expect(saved.playerSpatialPosition, PlayerSpatialPosition(x: 2.5, z: 1.5));
      expect(saved.trainerProfile.money, 90);
      expect(saved.party.members.single.currentHp, greaterThan(1));
      expect(saved.party.members.single.currentPpByMoveId!['tackle'], 35);
      expect(saved.periodicRewardState.claimsById, isEmpty);
      expect(saved.completedBattleRequestIds, hasLength(1));
      expect(saved.metadata[playerDefeatCountMetadataKey], '1');
      expect(
        runtime.session!.interactionError.value,
        isNull,
        reason: '${runtime.session!.interactionError.value}',
      );
      expect(runtime.gameStateSnapshot.playerPosition, saved.playerPosition);
      expect(runtime.gameStateSnapshot.trainerProfile.money, 95);
      expect(runtime.session!.interactionError.value, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    '3D failed periodic capture write preserves state and fresh replay commits once',
    (tester) async {
      final fixture = (await tester.runAsync(_fixture))!;
      final writer = _Writer(fixture.root)..fail = true;
      var runtime = _spatial(fixture, writer);
      await tester.runAsync(() => runtime.load((_) {}));
      await _until(
        tester,
        () => runtime.battle?.isActive == true,
        () => '${runtime.session?.interactionError.value}',
      );
      await _readySpatial(tester, runtime.battle!);
      await battle.submitFriendContextualCapture(tester, runtime.battle!);
      await battle.acknowledgeContextualCaptureBattle(tester, runtime.battle!);
      await _gameplaySettled(tester, runtime);
      expect(runtime.gameStateSnapshot.party, fixture.state.party);
      expect(runtime.gameStateSnapshot.bag, fixture.state.bag);
      expect(runtime.gameStateSnapshot.periodicRewardState.claimsById, isEmpty);
      expect(runtime.gameStateSnapshot.completedBattleRequestIds, isEmpty);
      expect(await tester.runAsync(writer.file.exists), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(runtime.dispose);
      writer.fail = false;
      runtime = _spatial(fixture, writer);
      addTearDown(runtime.dispose);
      await tester.runAsync(() => runtime.load((_) {}));
      await _until(
        tester,
        () => runtime.battle?.isActive == true,
        () => '${runtime.session?.interactionError.value}',
      );
      await _readySpatial(tester, runtime.battle!);
      await battle.submitFriendContextualCapture(tester, runtime.battle!);
      await battle.acknowledgeContextualCaptureBattle(tester, runtime.battle!);
      await _gameplaySettled(tester, runtime);
      final saved = (await tester.runAsync(writer.read))!;
      expect(saved.party.members, hasLength(2));
      expect(saved.periodicRewardState.claimFor('weekly-target')!.revision, 1);
      expect(saved.bag.entries.single.quantity, 49);
      expect(writer.writes, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    '3D pending periodic checkpoint blocks completion and disposal waits for its durable result',
    (tester) async {
      final fixture = (await tester.runAsync(_fixture))!;
      final gate = Completer<void>();
      final writer = _Writer(fixture.root)..gate = gate.future;
      final runtime = _spatial(fixture, writer);
      addTearDown(runtime.dispose);
      await tester.runAsync(() => runtime.load((_) {}));
      await _until(
        tester,
        () => runtime.battle?.isActive == true,
        () => '${runtime.session?.interactionError.value}',
      );
      final engine = runtime.battle!;
      await _readySpatial(tester, engine);
      await battle.submitFriendContextualCapture(tester, engine);
      await _until(tester, () {
        engine.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        );
        return writer.attempts != 0;
      }, () => 'checkpoint=${engine.phase} ${engine.error}');
      expect(writer.writes, 0);
      expect(runtime.gameStateSnapshot.party, fixture.state.party);
      expect(runtime.gameStateSnapshot.bag, fixture.state.bag);
      expect(runtime.gameStateSnapshot.periodicRewardState.claimsById, isEmpty);
      expect(engine.isActive, isTrue);
      var disposed = false;
      final closing = runtime.dispose().then((_) => disposed = true);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      expect(disposed, isFalse);
      gate.complete();
      await _until(
        tester,
        () => disposed,
        () => 'dispose attempts=${writer.attempts} writes=${writer.writes}',
      );
      await tester.runAsync(() => closing);
      expect(writer.writes, 1);
      final saved = (await tester.runAsync(writer.read))!;
      expect(saved.party.members, hasLength(2));
      expect(saved.periodicRewardState.claimFor('weekly-target')!.revision, 1);
      expect(saved.completedBattleRequestIds, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

void periodicEncounter2dTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    installConvertedQaHeadlessAudio(completePlayback: true);
    await AudioPlayer.global.ensureInitialized();
  });
  for (final (failWrite, failLater, defeat, recover) in [
    (false, false, false, false),
    (true, false, false, false),
    (false, true, false, false),
    (false, false, true, false),
    (false, false, true, true),
    (true, false, true, true),
  ]) {
    testWidgets(
      '2D real Scene periodic ${recover
          ? 'return-to-recovery'
          : defeat
          ? 'defeat'
          : 'capture'} ${failWrite
          ? 'rolls back a failed write'
          : failLater
          ? 'survives a later Scene failure'
          : 'persists before later consequences'}',
      (tester) async {
        final fixture = (await tester.runAsync(
          () =>
              _fixture(failLater: failLater, defeat: defeat, recover: recover),
        ))!;
        final writer = _Writer(fixture.root)..fail = failWrite;
        final map = MapData(
          id: fixture.bundle.map.id,
          name: 'Field',
          size: const GridSize(width: 8, height: 8),
          layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
        );
        final state = fixture.state.copyWith(
          playerSpatialPosition: null,
          playerPosition: const GridPos(x: 1, y: 1),
        );
        final game = PlayableMapGame(
          bundle: fixture.bundle.copyWith(
            map: map,
            manifest: fixture.bundle.manifest.copyWith(
              eventRegistry: null,
              settings: fixture.bundle.manifest.settings.copyWith(
                dimension: ProjectDimension.twoD,
              ),
            ),
          ),
          projectFilePath: '${fixture.root.path}/project.json',
          saveData: saveDataFromGameState(state),
          encounterClock: () => DateTime(2026, 11, 6, 23, 59),
          initialMapActivationReason: MapActivationReason.saveRestore,
          overworldCheckpointWriter: writer.commitState,
        );
        addTearDown(game.dispose);
        await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
        await _until(tester, () => game.isLoaded, () => '2D game load');
        NarrativeSceneExecutionResult? result;
        final scene = game
            .debugExecuteNarrativeSceneForTest(
              NarrativeSceneExecutionRequest(
                eventId: 'periodic',
                sceneId: 'periodic',
                executionId: 'periodic-test',
                gameState: game.playerServiceGameStateSnapshot,
              ),
            )
            .then((value) => result = value);
        await _until(
          tester,
          () => game.debugBattleOverlayMounted,
          () => 'battle=${game.debugFlowPhaseName} result=$result',
        );
        game.debugBattleOverlayComponent!.applyMotionPolicy(
          BattleMotionPolicy(playbackSpeed: 20, reducedMotion: true),
        );
        await _until(
          tester,
          () =>
              game.battleCommandOverlayListenable.value?.interactionsEnabled ==
              true,
          () => 'root=${game.battleCommandOverlayListenable.value?.mode}',
        );
        expect(
          game.debugBattleOverlayComponent!.selectRootEntry(defeat ? 0 : 1),
          isTrue,
        );
        expect(
          defeat
              ? game.debugBattleOverlayComponent!.selectChoiceEntry(0)
              : game.debugBattleOverlayComponent!.selectBagEntry(0),
          isTrue,
        );
        await _until(tester, () {
          if (game.debugBattleSessionSnapshot?.state.outcome == null) {
            _primary2d(game);
          }
          return defeat
              ? game.debugBattleSessionSnapshot?.state.outcome?.isDefeat == true
              : game.debugBattleSessionSnapshot?.state.outcome?.isCaptured ==
                    true;
        }, () => 'capture=${game.debugBattleSessionSnapshot?.state.outcome}');
        expect(writer.writes, 0);
        await _until(tester, () {
          _primary2d(game);
          return result != null;
        }, () => 'finish=${game.debugFlowPhaseName}');
        await tester.runAsync(() => scene);
        if (failWrite) {
          expect(result, isA<NarrativeSceneExecutionFailed>());
          expect(game.gameStateSnapshot.party.members, hasLength(1));
          expect(game.gameStateSnapshot.bag, state.bag);
          expect(
            game.gameStateSnapshot.periodicRewardState.claimsById,
            isEmpty,
          );
          expect(game.gameStateSnapshot.completedBattleRequestIds, isEmpty);
          expect(game.debugFlowPhaseName, 'overworld');
          expect(game.gameStateSnapshot.playerPosition, state.playerPosition);
          expect(
            game.gameStateSnapshot.trainerProfile.money,
            state.trainerProfile.money,
          );
          expect(
            game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey],
            isNull,
          );
          expect(await tester.runAsync(writer.file.exists), isFalse);
        } else {
          expect(
            result,
            failLater
                ? isA<NarrativeSceneExecutionFailed>()
                : isA<NarrativeSceneExecutionCompleted>(),
          );
          final saved = (await tester.runAsync(writer.read))!;
          expect(saved.party.members, hasLength(defeat ? 1 : 2));
          expect(saved.bag.entries.single.quantity, defeat ? 50 : 49);
          if (defeat) {
            expect(saved.periodicRewardState.claimFor('weekly-target'), isNull);
            expect(
              saved.party.members.single.currentHp,
              recover ? greaterThan(1) : 1,
            );
            if (recover) {
              expect(saved.playerPosition, const GridPos(x: 2, y: 1));
              expect(saved.trainerProfile.money, 90);
              expect(
                saved.party.members.single.currentPpByMoveId!['tackle'],
                35,
              );
              expect(saved.metadata[playerDefeatCountMetadataKey], '1');
            }
          } else {
            expect(
              saved.periodicRewardState.claimFor('weekly-target')!.revision,
              1,
            );
          }
          expect(saved.completedBattleRequestIds, hasLength(1));
          if (failLater) {
            expect(game.gameStateSnapshot.party, saved.party);
            expect(game.gameStateSnapshot.bag, saved.bag);
            expect(
              game.gameStateSnapshot.trainerProfile.money,
              saved.trainerProfile.money,
            );
            expect(
              game.gameStateSnapshot.completedBattleRequestIds,
              saved.completedBattleRequestIds,
            );
            expect(
              game.gameStateSnapshot.periodicRewardState,
              saved.periodicRewardState,
            );
          } else {
            expect(
              (result as NarrativeSceneExecutionCompleted)
                  .updatedGameState
                  .trainerProfile
                  .money,
              saved.trainerProfile.money + 5,
            );
            expect(
              (result as NarrativeSceneExecutionCompleted)
                  .updatedGameState
                  .party,
              saved.party,
            );
          }
        }
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

Future<void> _readySpatial(
  WidgetTester tester,
  SpatialBattleRuntime runtime,
) async {
  runtime.applyMotionPolicy(
    BattleMotionPolicy(playbackSpeed: 20, reducedMotion: true),
  );
  await battle.readyContextualCaptureBattle(tester, runtime);
}

void _primary2d(PlayableMapGame game) {
  if (game.debugFlowPhaseName != 'battle') return;
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.primary),
  );
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.primary),
  );
}

Future<void> _until(
  WidgetTester tester,
  bool Function() ready,
  String Function() diagnostic,
) async {
  for (var i = 0; i < 1000 && !ready(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
  expect(ready(), isTrue, reason: diagnostic());
}

Future<void> _gameplaySettled(
  WidgetTester tester,
  SpatialExplorationGameSessionRuntime runtime,
) async {
  var done = false;
  runtime.gameplayReady.then((_) => done = true);
  await _until(
    tester,
    () => done,
    () => 'gameplay=${runtime.session?.interactionError.value}',
  );
}

typedef _Fixture = ({RuntimeMapBundle bundle, GameState state, Directory root});

Future<_Fixture> _fixture({
  bool fullParty = false,
  bool defeat = false,
  bool failLater = false,
  bool periodic = true,
  bool recover = false,
}) async {
  final base = await battle.contextualCaptureSpatialFixture();
  var state = base.state.copyWith(
    saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
    party: base.state.party.copyWith(members: [base.state.party.members.first]),
  );
  if (fullParty) {
    state = state.copyWith(
      party: state.party.copyWith(
        members: [
          for (var i = 0; i < 6; i++)
            state.party.members.first.copyWith(
              individualId:
                  'pkm_019abcde-0000-7000-8000-${(i + 1).toString().padLeft(12, '0')}',
            ),
        ],
      ),
    );
  }
  if (defeat) {
    state = state.copyWith(
      party: state.party.copyWith(
        members: [state.party.members.first.copyWith(currentHp: 1)],
      ),
    );
  }
  if (recover) {
    final recovery = recordPlayerRecoveryPoint(
      state.copyWith(
        playerPosition: const GridPos(x: 2, y: 1),
        trainerProfile: state.trainerProfile.copyWith(money: 100),
      ),
    );
    state = recovery.copyWith(
      playerPosition: state.playerPosition,
      playerSpatialPosition: state.playerSpatialPosition,
    );
  }
  final scene = SceneAsset(
    id: 'periodic',
    name: 'Periodic',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'wild',
            battleTemplateId: 'periodic-table',
            npcEntityId: 'target',
            defeatRecovery: recover
                ? SceneBattleDefeatRecovery.returnToRecoveryPoint
                : SceneBattleDefeatRecovery.continueScene,
            periodicEncounter: periodic
                ? PeriodicEncounterDefinition(
                    rewardId: 'weekly-target',
                    label: 'Weekly target',
                    consumeOnOutcomes: PeriodicEncounterOutcome.values.toSet(),
                  )
                : null,
            declaredOutcomes: const [
              'victory',
              'captured',
              'runaway',
              'defeat',
            ],
          ),
        ),
        SceneNode(
          id: 'money',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.giveMoney(amount: 5),
          ),
        ),
        if (failLater)
          SceneNode(
            id: 'fail',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.takeItem(itemId: 'poke-ball', quantity: 100),
            ),
          ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (final port in ['victory', 'captured', 'runaway', 'defeat'])
          SceneEdge(
            id: port,
            fromNodeId: 'battle',
            fromPortId: port,
            toNodeId: 'money',
            kind: port == 'victory'
                ? SceneEdgeKind.battleVictory
                : port == 'defeat'
                ? SceneEdgeKind.battleDefeat
                : SceneEdgeKind.branchOutcome,
          ),
        SceneEdge(
          id: 'money',
          fromNodeId: 'money',
          fromPortId: 'completed',
          toNodeId: failLater ? 'fail' : 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        if (failLater)
          SceneEdge(
            id: 'fail',
            fromNodeId: 'fail',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
  final manifest = base.bundle.manifest.copyWith(
    scenes: [scene],
    encounterTables: [
      ProjectEncounterTable(
        id: 'periodic-table',
        name: 'Periodic',
        encounterKind: EncounterKind.walk,
        entries: [
          ProjectEncounterEntry(
            speciesId: 'sparkitten',
            minLevel: defeat ? 50 : 2,
            maxLevel: defeat ? 50 : 2,
          ),
        ],
      ),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      legacyClaims: const [],
      records: [
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: 'evt_019abcde-0000-7000-8000-000000000001',
            name: 'Periodic',
            source: NarrativeEventSourceRef.mapEnter(base.bundle.map.id),
            conditions: [
              if (periodic)
                NarrativeEventCondition.periodicRewardAvailable(
                  reference: PeriodicRewardReference(
                    sceneId: scene.id,
                    nodeId: 'battle',
                    rewardId: 'weekly-target',
                  ),
                  expectedValue: true,
                ),
            ],
            sceneId: scene.id,
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
    ),
  );
  return (
    bundle: base.bundle.copyWith(manifest: manifest),
    state: state,
    root: Directory(base.bundle.projectRootDirectory),
  );
}

SpatialExplorationGameSessionRuntime _spatial(
  _Fixture fixture,
  _Writer writer, {
  bool continueGame = false,
  bool durable = true,
}) => SpatialExplorationGameSessionRuntime(
  descriptor: session.descriptor(
    initialState: fixture.state,
    continueGame: continueGame,
    additionalCapabilities: {
      'gameplay.periodic-encounter@1',
      'gameplay.periodic-reward-condition@1',
      'map3d.gameplay@1',
    },
  ),
  now: () => writer.now,
  initialSave: continueGame
      ? () async => session.spatialSave(await writer.read())
      : null,
  projectFilePath: () async => '${fixture.root.path}/project.json',
  preloadedInitialMap: ({
    required projectFilePath,
    required descriptor,
    required initialSave,
  }) async => RuntimeInitialMapPreloadResult(bundle: fixture.bundle),
  commitCheckpoint: durable ? writer.commit : null,
  mountSession: (_) async {},
  unmountSession: (_) async {},
);

class _Writer {
  _Writer(this.root);
  final Directory root;
  File get file => File('${root.path}/periodic-save.json');
  int writes = 0;
  int attempts = 0;
  bool fail = false;
  DateTime now = DateTime(2026, 11, 6, 23, 59);
  Future<void>? gate;
  Future<void> commit(GameSessionCheckpointCommit request) async {
    attempts++;
    await gate;
    if (fail) throw const FileSystemException('disk unavailable');
    await file.writeAsString(jsonEncode(request.checkpoint.state), flush: true);
    writes++;
  }

  Future<GameState> read() async => gameStateFromStrictSaveJson(
    Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map),
  );
  Future<void> commitState(GameState state) async {
    await gate;
    if (fail) throw const FileSystemException('disk unavailable');
    await file.writeAsString(
      jsonEncode(strictGameStateSaveJson(state)),
      flush: true,
    );
    writes++;
  }
}
