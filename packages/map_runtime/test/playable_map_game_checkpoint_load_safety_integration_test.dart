import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show
        RuntimeDialogueSessionLoader,
        RuntimeMapBundleLoader,
        RuntimeTilesetImageLoader;

import 'surface/surface_runtime_test_support.dart' show runtimeTilesetImage;

const _sourceMapId = 'checkpoint_source';
const _restoredMapId = 'checkpoint_restored';
const _followScenarioId = 'legacy_follow_before_load';
const _trainerId = 'checkpoint_trainer';

const _battleStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame checkpoint/load safety', () {
    test('Event V2 whiteOut checkpoint follows the coordinator commit and lease release', () async {
      final source = _whiteOutBundle();
      final gate = NarrativeRuntimeActivityGate();
      final repository = _GateMemoryRepository(gate);
      final registry = NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
        records: [NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
          id: 'evt_019abcde-1000-7000-8000-000000000024', name: 'Boot recovery',
          source: NarrativeEventSourceRef.mapEnter(_sourceMapId), conditions: const [],
          sceneId: 'dialogue_battle_scene', reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 0,
        ), enabled: true)], legacyClaims: const []);
      var checkpoints = 0;
      var checkpointFinished = false;
      late PlayableMapGame game;
      game = _game(bundle: source.copyWith(manifest: source.manifest.copyWith(eventRegistry: registry)),
        initialState: _battleReadyState().copyWith(trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
        narrativeRuntimeActivityGate: gate, saveRepository: repository,
        defeatRecoveryCapsLoader: (_) async => const RuntimePlayerServiceRecoveryCaps(
          maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}}),
        defeatRecoveryCheckpointEmitter: () async {
          expect(gate.activity, NarrativeRuntimeActivity.idle);
          expect(game.debugIsMapActivationDispatchInFlight, isFalse);
          checkpoints++;
          expect(await game.saveGame(), isTrue);
          checkpointFinished = true;
        });
      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      for (var tick = 0; tick < 1800 && !checkpointFinished; tick++) {
        game.update(.016);
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(checkpoints, 1);
      expect(checkpointFinished, isTrue);
      expect(repository.saveCount, 1);
      expect(repository.storedState!.metadata[playerDefeatCountMetadataKey], '1');
      expect(repository.storedState!.trainerProfile.money, 900);
      expect(game.gameStateSnapshot.trainerProfile.money, 900);
    });

    test('Event V2 chained recoveries retain both receipts before the gate becomes idle', () async {
      final source = _whiteOutBundle();
      final first = _whiteOutBundle(sceneId: 'receipt_a', outcomeId: 'recovered').manifest.scenes.single;
      final second = _whiteOutBundle(sceneId: 'receipt_b', finishGame: true).manifest.scenes.single;
      final registry = NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
            id: 'evt_019abcde-1000-7000-8000-000000000025', name: 'First recovery',
            source: NarrativeEventSourceRef.mapEnter(_sourceMapId), conditions: const [],
            sceneId: first.id, reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 0), enabled: true),
          NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
            id: 'evt_019abcde-1000-7000-8000-000000000026', name: 'Second recovery',
            source: NarrativeEventSourceRef.outcomeReceived(NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene, producerId: first.id, outcomeId: 'recovered')),
            conditions: const [], sceneId: second.id,
            reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 1), enabled: true),
        ], legacyClaims: const []);
      final gate = NarrativeRuntimeActivityGate();
      final emissions = <String>[];
      final notifications = <String>[];
      var recoveryLoads = 0;
      late PlayableMapGame game;
      game = _game(bundle: source.copyWith(manifest: source.manifest.copyWith(
        scenes: [first, second], eventRegistry: registry)),
        initialState: _battleReadyState().copyWith(trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
        narrativeRuntimeActivityGate: gate,
        defeatRecoveryCapsLoader: (_) async {
          recoveryLoads++;
          return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}});
        },
        defeatRecoveryCheckpointEmitter: () async {
          expect(gate.activity, NarrativeRuntimeActivity.idle);
          expect(game.debugIsMapActivationDispatchInFlight, isFalse);
          expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], '2');
          emissions.add('checkpoint');
        },
        gameCompletionEmitter: (request) async {
          expect(gate.activity, NarrativeRuntimeActivity.idle);
          emissions.add(request.endingId);
        });
      game.runtimeNotificationListenable.addListener(() {
        final text = game.runtimeNotificationListenable.value?.text;
        if (text != null && text.startsWith('Défaite')) notifications.add(text);
      });
      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      for (var tick = 0; tick < 1800 && emissions.length < 3; tick++) {
        game.update(.016);
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(recoveryLoads, 2);
      expect(game.gameStateSnapshot.trainerProfile.money, 810);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], '2');
      expect(emissions, ['checkpoint', 'checkpoint', 'ending.recovery']);
      expect(notifications, ['Défaite… retour au Centre Pokémon. 100 ₽ perdus.',
        'Défaite… retour au Centre Pokémon. 90 ₽ perdus.']);
    });

    test('a second Scene committed during a checkpoint retains the first completion and both receipts', () async {
      final checkpointEntered = Completer<void>();
      final checkpointRelease = Completer<void>();
      addTearDown(() {
        if (!checkpointRelease.isCompleted) checkpointRelease.complete();
      });
      final source = _whiteOutBundle();
      final first = _whiteOutBundle(sceneId: 'receipt_a', finishGame: true, endingId: 'ending.a').manifest.scenes.single;
      final second = _whiteOutBundle(sceneId: 'receipt_b').manifest.scenes.single;
      final registry = NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
            id: 'evt_019abcde-1000-7000-8000-000000000027', name: 'First recovery',
            source: NarrativeEventSourceRef.mapEnter(_sourceMapId), conditions: const [],
            sceneId: first.id, reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 0), enabled: true),
          NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
            id: 'evt_019abcde-1000-7000-8000-000000000028', name: 'Second recovery',
            source: NarrativeEventSourceRef.entityInteract(_sourceMapId, 'receipt_npc'), conditions: const [],
            sceneId: second.id, reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 1), enabled: true),
        ], legacyClaims: const []);
      final map = source.map.copyWith(events: const [], entities: [
        source.map.entities.first,
        const MapEntity(id: 'receipt_npc', name: 'Recovery NPC', kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 0), npc: MapEntityNpcData(displayName: 'Recovery NPC')),
      ]);
      final gate = NarrativeRuntimeActivityGate();
      final emissions = <String>[];
      final notifications = <String>[];
      var recoveryLoads = 0;
      var checkpoints = 0;
      late PlayableMapGame game;
      game = _game(bundle: source.copyWith(map: map, manifest: source.manifest.copyWith(
        scenes: [first, second], eventRegistry: registry)),
        initialState: _battleReadyState().copyWith(trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
        narrativeRuntimeActivityGate: gate,
        defeatRecoveryCapsLoader: (_) async {
          recoveryLoads++;
          return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}});
        },
        defeatRecoveryCheckpointEmitter: () async {
          expect(gate.activity, NarrativeRuntimeActivity.idle);
          emissions.add('checkpoint${++checkpoints}');
          if (checkpoints == 1) {
            checkpointEntered.complete();
            await checkpointRelease.future;
          }
        },
        gameCompletionEmitter: (request) async {
          expect(gate.activity, NarrativeRuntimeActivity.idle);
          emissions.add(request.endingId);
        });
      game.runtimeNotificationListenable.addListener(() {
        final text = game.runtimeNotificationListenable.value?.text;
        if (text != null && text.startsWith('Défaite')) notifications.add(text);
      });
      await _load(game);
      await checkpointEntered.future.timeout(const Duration(seconds: 2));
      expect(emissions, ['checkpoint1']);
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntil(game, () => game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey] == '2' &&
        gate.activity == NarrativeRuntimeActivity.idle);
      expect(recoveryLoads, 2);
      expect(game.gameStateSnapshot.trainerProfile.money, 810);
      expect(game.gameStateSnapshot.metadata[sceneGameCompletionEndingMetadataKey], 'ending.a');
      expect(emissions, ['checkpoint1']);
      checkpointRelease.complete();
      for (var tick = 0; tick < 1800 && emissions.length < 3; tick++) {
        game.update(.016);
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(emissions, ['checkpoint1', 'ending.a', 'checkpoint2']);
      expect(notifications, ['Défaite… retour au Centre Pokémon. 100 ₽ perdus.',
        'Défaite… retour au Centre Pokémon. 90 ₽ perdus.']);
    });

    test('a failed recovery completion retries only after the next Scene rolls back safely', () async {
      final capsEntered = Completer<void>();
      final capsRelease = Completer<void>();
      addTearDown(() {
        if (!capsRelease.isCompleted) capsRelease.complete();
      });
      final source = _whiteOutBundle();
      final first = _whiteOutBundle(sceneId: 'retry_a', finishGame: true, endingId: 'ending.retry').manifest.scenes.single;
      final second = _whiteOutBundle(sceneId: 'retry_b').manifest.scenes.single;
      final registry = NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
            id: 'evt_019abcde-1000-7000-8000-000000000029', name: 'First recovery',
            source: NarrativeEventSourceRef.mapEnter(_sourceMapId), conditions: const [],
            sceneId: first.id, reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 0), enabled: true),
          NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(
            id: 'evt_019abcde-1000-7000-8000-000000000030', name: 'Failed second recovery',
            source: NarrativeEventSourceRef.entityInteract(_sourceMapId, 'retry_npc'), conditions: const [],
            sceneId: second.id, reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 1), enabled: true),
        ], legacyClaims: const []);
      final map = source.map.copyWith(events: const [], entities: [
        source.map.entities.first,
        const MapEntity(id: 'retry_npc', name: 'Recovery NPC', kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 0), npc: MapEntityNpcData(displayName: 'Recovery NPC')),
      ]);
      final gate = NarrativeRuntimeActivityGate();
      final completionActivities = <NarrativeRuntimeActivity>[];
      final completionStates = <GameState>[];
      var recoveryLoads = 0;
      var checkpoints = 0;
      late PlayableMapGame game;
      game = _game(bundle: source.copyWith(map: map, manifest: source.manifest.copyWith(
        scenes: [first, second], eventRegistry: registry)),
        initialState: _battleReadyState().copyWith(trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
        narrativeRuntimeActivityGate: gate,
        defeatRecoveryCapsLoader: (_) async {
          if (++recoveryLoads == 2) {
            capsEntered.complete();
            await capsRelease.future;
            throw StateError('Second recovery caps unavailable');
          }
          return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}});
        },
        defeatRecoveryCheckpointEmitter: () async { checkpoints++; },
        gameCompletionEmitter: (_) async {
          completionActivities.add(gate.activity);
          completionStates.add(game.gameStateSnapshot);
          if (completionActivities.length == 1) throw StateError('First completion emission unavailable');
        });
      game.onGameResize(Vector2(320, 240));
      await game.onLoad();
      for (var tick = 0; tick < 1800 && (game.runtimeNotificationListenable.value?.text != 'Fin de partie impossible.' ||
        game.debugIsMapActivationDispatchInFlight || gate.activity != NarrativeRuntimeActivity.idle); tick++) {
        game.update(.016);
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(game.runtimeNotificationListenable.value?.text, 'Fin de partie impossible.');
      expect(completionActivities, [NarrativeRuntimeActivity.idle]);
      final before = await game.debugReadNarrativeGameStateForTest();
      for (var tick = 0; tick < 8; tick++) {
        game.update(.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(completionActivities, [NarrativeRuntimeActivity.idle]);
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await capsEntered.future.timeout(const Duration(seconds: 2));
      expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
      for (var tick = 0; tick < 8; tick++) {
        game.update(.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(completionActivities, [NarrativeRuntimeActivity.idle]);
      capsRelease.complete();
      await _waitUntil(game, () => gate.activity == NarrativeRuntimeActivity.idle && completionActivities.length == 2);
      expect(completionActivities, [NarrativeRuntimeActivity.idle, NarrativeRuntimeActivity.idle]);
      expect(completionStates.last, before);
      expect(await game.debugReadNarrativeGameStateForTest(), before);
      expect(checkpoints, 1);
      expect(recoveryLoads, 2);
      expect(game.gameStateSnapshot.trainerProfile.money, 900);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], '1');
      for (var tick = 0; tick < 8; tick++) {
        game.update(.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(completionActivities, hasLength(2));
    });

    for (final failLoad in [false, true]) {
      test('autonomous whiteOut uses the project fallback atomically loadFailure=$failLoad', () async {
        final source = _whiteOutBundle();
        final manifest = source.manifest.copyWith(maps: [
          ...source.manifest.maps,
          const ProjectMapEntry(id: _restoredMapId, name: 'Recovery', relativePath: 'maps/recovery.json'),
        ], newGame: const ProjectNewGameConfig(startMapId: _restoredMapId));
        final gate = NarrativeRuntimeActivityGate();
        var checkpoints = 0;
        var recoveryLoads = 0;
        final game = _game(bundle: source.copyWith(manifest: manifest),
          initialState: _battleReadyState().copyWith(trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
          narrativeRuntimeActivityGate: gate,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) async {
            recoveryLoads++;
            if (failLoad) throw StateError('Fallback map unavailable');
            return _bundle(map: _plainMap(_restoredMapId)).copyWith(manifest: manifest);
          },
          defeatRecoveryCapsLoader: (_) async => const RuntimePlayerServiceRecoveryCaps(
            maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}}),
          defeatRecoveryCheckpointEmitter: () async {
            expect(gate.activity, NarrativeRuntimeActivity.idle);
            checkpoints++;
          });
        await _load(game);
        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntil(game, () => gate.activity == NarrativeRuntimeActivity.idle &&
          !game.debugIsMapActivationDispatchInFlight && (failLoad || checkpoints == 1));
        expect(recoveryLoads, greaterThan(0));
        expect(checkpoints, failLoad ? 0 : 1);
        final state = game.gameStateSnapshot;
        expect(state.currentMapId, failLoad ? _sourceMapId : _restoredMapId);
        expect(state.trainerProfile.money, failLoad ? 1000 : 900);
        expect(state.metadata[playerDefeatCountMetadataKey], failLoad ? null : '1');
      });
    }
    test('real Scene battle defeat and whiteOut coalesce after the defeat branch', () async {
      final fixtureRoot = Directory('../../examples/playable_runtime_host/golden_battle_slice').absolute;
      final fixture = ProjectManifest.fromJson(jsonDecode(await File('${fixtureRoot.path}/project.json').readAsString()) as Map<String, dynamic>);
      final source = _sceneBundle(recovery: SceneBattleDefeatRecovery.returnToRecoveryPoint);
      final original = source.manifest.scenes.single;
      final scene = SceneAsset(id: original.id, name: original.name, graph: SceneGraph(
        startNodeId: original.graph.startNodeId,
        nodes: [
          ...original.graph.nodes,
          SceneNode(id: 'whiteOut', kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(SceneInteractiveCommand.whiteOut())),
          SceneNode(id: 'defeat_mark', kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(SceneConsequence.setFact(factId: 'defeat_seen', value: true))),
        ],
        edges: [
          for (final edge in original.graph.edges)
            if (edge.id == 'battle_defeat') SceneEdge(id: edge.id, fromNodeId: edge.fromNodeId,
              fromPortId: edge.fromPortId, toNodeId: 'whiteOut', kind: edge.kind) else edge,
          SceneEdge(id: 'whiteout_mark', fromNodeId: 'whiteOut', fromPortId: 'completed', toNodeId: 'defeat_mark', kind: SceneEdgeKind.defaultFlow),
          SceneEdge(id: 'mark_end', fromNodeId: 'defeat_mark', fromPortId: 'completed', toNodeId: 'defeat_end', kind: SceneEdgeKind.defaultFlow),
        ],
      ));
      final manifest = source.manifest.copyWith(pokemon: fixture.pokemon, scenes: [scene],
        facts: [NarrativeFactDefinition(id: 'defeat_seen', label: 'Défaite vécue')], trainers: const [
          ProjectTrainerEntry(id: _trainerId, name: 'Rival', trainerClass: 'Rival',
            moneyReward: 500, rewardFlagIds: ['victory_reward'],
            team: [ProjectTrainerPokemonEntry(speciesId: 'sparkitten', level: 50, moves: ['tackle'])]),
        ]);
      final gate = NarrativeRuntimeActivityGate();
      var checkpoints = 0;
      var recoveryLoads = 0;
      final game = _game(bundle: source.copyWith(manifest: manifest, projectRootDirectory: fixtureRoot.path),
        initialState: _battleReadyState().copyWith(
          trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000),
          party: const PlayerParty(members: [PlayerPokemon(speciesId: 'sproutle', natureId: 'hardy', abilityId: 'overgrow',
            level: 5, currentHp: 1, knownMoveIds: ['tackle'], currentPpByMoveId: {'tackle': 2}, statusId: 'psn')]),
          metadata: {playerRecoveryMapIdMetadataKey: _sourceMapId, playerRecoveryPositionXMetadataKey: '3',
            playerRecoveryPositionYMetadataKey: '3', playerRecoveryFacingMetadataKey: 'north'},
        ), narrativeRuntimeActivityGate: gate,
        dialogueSessionLoader: (_) async => _singleLineDialogue(),
        defeatRecoveryCapsLoader: (_) async {
          recoveryLoads++;
          return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}});
        }, defeatRecoveryCheckpointEmitter: () async {
          expect(gate.activity, NarrativeRuntimeActivity.idle);
          checkpoints++;
        });
      await _load(game);
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntilWithoutUpdate(() => game.debugFlowPhaseName == 'dialogue');
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      var sawBattle = false;
      for (var tick = 0; tick < 4000 && checkpoints == 0; tick++) {
        game.update(0.1);
        await Future<void>.delayed(const Duration(milliseconds: 1));
        final snapshot = game.battleCommandOverlayListenable.value;
        if (snapshot != null) sawBattle = true;
        if (snapshot != null && snapshot.interactionsEnabled && snapshot.entries.isNotEmpty) {
          game.dispatchBattlePresentationCommand(BattleSelectEntryCommand(snapshotRevision: snapshot.revision,
            expectedMode: snapshot.mode, entryIndex: 0));
        }
      }
      expect(sawBattle, isTrue);
      expect(checkpoints, 1);
      expect(recoveryLoads, 1);
      final state = game.gameStateSnapshot;
      expect(state.metadata[playerDefeatCountMetadataKey], '1');
      expect(state.storyFlags.activeFlags, contains('defeat_seen'));
      expect(state.storyFlags.activeFlags, isNot(contains('trainer_defeated:$_trainerId')));
      expect(state.storyFlags.activeFlags, isNot(contains('victory_reward')));
      expect(state.trainerProfile.money, 900);
      expect(state.party.members.single.currentHp, 20);
      expect(state.party.members.single.currentPpByMoveId!['tackle'], 35);
      expect(state.party.members.single.statusId, '');
      expect(state.playerPosition, const GridPos(x: 3, y: 3));
    });
    for (final repeated in [false, true]) {
      test('autonomous whiteOut repeated=$repeated commits one recovery and checkpoint after Scene', () async {
        final gate = NarrativeRuntimeActivityGate();
        final checkpoints = <GameState>[];
        final notificationActivities = <NarrativeRuntimeActivity>[];
        final initial = _battleReadyState().copyWith(
          trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000),
          metadata: {
            playerRecoveryMapIdMetadataKey: _sourceMapId,
            playerRecoveryPositionXMetadataKey: '3',
            playerRecoveryPositionYMetadataKey: '3',
            playerRecoveryFacingMetadataKey: 'north',
          },
        );
        late PlayableMapGame game;
        var recoveryLoads = 0;
        game = _game(bundle: _whiteOutBundle(repeated: repeated), initialState: initial,
          narrativeRuntimeActivityGate: gate,
          defeatRecoveryCapsLoader: (_) async {
            recoveryLoads++;
            expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
            expect(checkpoints, isEmpty);
            return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}});
          },
          defeatRecoveryCheckpointEmitter: () async {
            expect(gate.activity, NarrativeRuntimeActivity.idle);
            checkpoints.add(game.gameStateSnapshot);
          });
        game.runtimeNotificationListenable.addListener(() {
          if (game.runtimeNotificationListenable.value?.text.startsWith('Défaite') ?? false) {
            notificationActivities.add(gate.activity);
          }
        });
        await _load(game);
        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(() => checkpoints.isNotEmpty);
        expect(recoveryLoads, 1);
        expect(checkpoints, hasLength(1));
        expect(notificationActivities, [NarrativeRuntimeActivity.idle]);
        final state = checkpoints.single;
        expect(state.metadata[playerDefeatCountMetadataKey], '1');
        expect(state.trainerProfile.money, 900);
        expect(state.playerPosition, const GridPos(x: 3, y: 3));
        expect(state.party.members.single.currentHp, 20);
        final reloaded = _game(bundle: _whiteOutBundle(repeated: repeated), initialState: state,
          initialMapActivationReason: MapActivationReason.saveRestore);
        await _load(reloaded);
        expect(reloaded.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], '1');
        expect(reloaded.gameStateSnapshot.trainerProfile.money, 900);
        expect(reloaded.gameStateSnapshot.playerPosition, state.playerPosition);
      });
    }

    test('checkpoint failure preserves committed recovery and does not retry the penalty', () async {
      final gate = NarrativeRuntimeActivityGate();
      final directory = await Directory.systemTemp.createTemp('whiteout-checkpoint-retry-');
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/checkpoint.json';
      final repository = _WhiteOutFileRepository(path, gate);
      var emissions = 0;
      final game = _game(bundle: _whiteOutBundle(), initialState: _battleReadyState().copyWith(
        trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
        narrativeRuntimeActivityGate: gate, saveRepository: repository,
        defeatRecoveryCapsLoader: (_) async => const RuntimePlayerServiceRecoveryCaps(
          maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}}),
        defeatRecoveryCheckpointEmitter: () async {
          expect(gate.activity, NarrativeRuntimeActivity.idle);
          emissions++;
          throw StateError('Checkpoint store unavailable');
        });
      await _load(game);
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntilWithoutUpdate(() => emissions == 1);
      for (var tick = 0; tick < 10; tick++) {
        game.update(.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(emissions, 1);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], '1');
      expect(game.gameStateSnapshot.trainerProfile.money, 900);
      expect(game.runtimeNotificationListenable.value?.text, contains('la sauvegarde a échoué'));
      expect(await game.saveGame(), isTrue);
      final restored = await _WhiteOutFileRepository(path, NarrativeRuntimeActivityGate()).load();
      expect(restored!.metadata[playerDefeatCountMetadataKey], '1');
      expect(restored.trainerProfile.money, 900);
      final reloaded = _game(bundle: _whiteOutBundle(), initialState: restored,
        initialMapActivationReason: MapActivationReason.saveRestore);
      await _load(reloaded);
      expect(reloaded.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], '1');
      expect(reloaded.gameStateSnapshot.trainerProfile.money, 900);
      expect(emissions, 1);
    });

    test('cancelling the suspended follow-up discards the armed whiteOut recovery', () async {
      final directory = await Directory.systemTemp.createTemp('whiteout-cancel-');
      addTearDown(() => directory.delete(recursive: true));
      final gate = NarrativeRuntimeActivityGate();
      final path = '${directory.path}/checkpoint.json';
      final repository = _WhiteOutFileRepository(path, gate);
      final initial = _battleReadyState().copyWith(
        trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000));
      await repository.save(initial);
      var recoveryLoads = 0;
      var checkpoints = 0;
      final game = _game(bundle: _whiteOutBundle(followup: true), initialState: initial,
        narrativeRuntimeActivityGate: gate, saveRepository: repository,
        dialogueSessionLoader: (_) async => _singleLineDialogue(),
        defeatRecoveryCapsLoader: (_) async {
          recoveryLoads++;
          return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {});
        }, defeatRecoveryCheckpointEmitter: () async { checkpoints++; });
      await _load(game);
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntilWithoutUpdate(() => game.debugFlowPhaseName == 'dialogue');
      expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
      expect(await game.saveGame(), isFalse);
      game.debugResetBattleForTest();
      await _waitUntilWithoutUpdate(() => gate.activity == NarrativeRuntimeActivity.idle);
      expect(recoveryLoads, 0);
      expect(checkpoints, 0);
      expect(game.gameStateSnapshot.trainerProfile.money, 1000);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], isNull);
      expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
      expect(game.gameStateSnapshot.playerPosition, initial.playerPosition);
      expect(await game.saveGame(), isTrue);
      final restored = await _WhiteOutFileRepository(path, NarrativeRuntimeActivityGate()).load();
      expect(restored!.trainerProfile.money, 1000);
      expect(restored.metadata[playerDefeatCountMetadataKey], isNull);
      expect(restored.playerPosition, initial.playerPosition);
    });

    test('successful whiteOut notifies after commit without a checkpoint emitter', () async {
      final gate = NarrativeRuntimeActivityGate();
      final notifications = <NarrativeRuntimeActivity>[];
      final game = _game(bundle: _whiteOutBundle(), initialState: _battleReadyState().copyWith(
        trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
        narrativeRuntimeActivityGate: gate,
        defeatRecoveryCapsLoader: (_) async => const RuntimePlayerServiceRecoveryCaps(
          maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}}));
      game.runtimeNotificationListenable.addListener(() {
        if (game.runtimeNotificationListenable.value?.text.startsWith('Défaite') ?? false) {
          notifications.add(gate.activity);
        }
      });
      await _load(game);
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntilWithoutUpdate(() => notifications.isNotEmpty);
      expect(notifications, [NarrativeRuntimeActivity.idle]);
      expect(game.gameStateSnapshot.trainerProfile.money, 900);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], '1');
    });

    test('V1 outcome retry restores canonical recovery state and the existing outbox', () async {
      final source = _whiteOutBundle();
      final original = source.manifest.scenes.single;
      final scene = SceneAsset(id: original.id, name: original.name,
        declaredOutcomes: [SceneOutcome(id: 'recovered', label: 'Recovered')],
        graph: SceneGraph(startNodeId: original.graph.startNodeId,
          nodes: [for (final node in original.graph.nodes)
            if (node.kind == SceneNodeKind.end) SceneNode(id: node.id, kind: node.kind,
              payload: SceneEndPayload(sceneOutcomeId: 'recovered')) else node],
          edges: original.graph.edges));
      final existingDelivery = NarrativeOutcomeDelivery(
        deliveryId: 'outd_019abcde-1000-7000-8000-000000000001',
        outcome: NarrativeOutcomeRef(producerKind: NarrativeOutcomeProducerKind.scene, producerId: 'older_scene', outcomeId: 'ready'),
        rootCorrelationId: 'corr_019abcde-1000-7000-8000-000000000001', depth: 0, attemptCount: 0);
      final initial = _battleReadyState().copyWith(
        trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000),
        narrativeEventProgress: NarrativeEventProgress(pendingNarrativeOutcomeDeliveries: [existingDelivery]),
        metadata: {playerRecoveryMapIdMetadataKey: _sourceMapId, playerRecoveryPositionXMetadataKey: '3',
          playerRecoveryPositionYMetadataKey: '3', playerRecoveryFacingMetadataKey: 'north'});
      final gate = NarrativeRuntimeActivityGate();
      final repository = _GateMemoryRepository(gate);
      var outcomeAttempts = 0;
      var checkpoints = 0;
      var recoveryLoads = 0;
      final notifications = <String>[];
      final game = _game(bundle: source.copyWith(manifest: source.manifest.copyWith(scenes: [scene])),
        initialState: initial, narrativeRuntimeActivityGate: gate, saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind == NarrativeEventSourceKind.outcomeReceived) {
            outcomeAttempts++;
            throw StateError('Outcome planning unavailable');
          }
        },
        defeatRecoveryCapsLoader: (_) async {
          recoveryLoads++;
          return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}});
        }, defeatRecoveryCheckpointEmitter: () async { checkpoints++; });
      game.runtimeNotificationListenable.addListener(() {
        final text = game.runtimeNotificationListenable.value?.text;
        if (text != null) notifications.add(text);
      });
      await _load(game);
      final before = await game.debugReadNarrativeGameStateForTest();
      final attemptsBefore = outcomeAttempts;
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntilWithoutUpdate(() => gate.activity == NarrativeRuntimeActivity.idle);
      expect(outcomeAttempts, attemptsBefore + 1);
      expect(recoveryLoads, 1);
      expect(checkpoints, 0);
      expect(notifications.where((text) => text.startsWith('Défaite')), isEmpty);
      expect(game.gameStateSnapshot.trainerProfile.money, 1000);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], isNull);
      expect(game.gameStateSnapshot.playerPosition, initial.playerPosition);
      final canonical = await game.debugReadNarrativeGameStateForTest();
      expect(canonical.trainerProfile.money, 1000);
      expect(canonical.metadata[playerDefeatCountMetadataKey], isNull);
      expect(canonical, before);
      expect(canonical.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        before.narrativeEventProgress.pendingNarrativeOutcomeDeliveries);
      expect(await game.saveGame(), isTrue);
      expect(repository.storedState!.trainerProfile.money, 1000);
      expect(repository.storedState!.metadata[playerDefeatCountMetadataKey], isNull);
    });

    for (final failOutcome in [false, true]) {
      test('FinishGame after recovery outcomeFailure=$failOutcome emits only after a safe commit', () async {
        final source = _whiteOutBundle(finishGame: true);
        final original = source.manifest.scenes.single;
        final scene = SceneAsset(id: original.id, name: original.name,
          declaredOutcomes: [SceneOutcome(id: 'recovered', label: 'Recovered')],
          graph: SceneGraph(startNodeId: original.graph.startNodeId,
            nodes: [for (final node in original.graph.nodes)
              if (node.kind == SceneNodeKind.end) SceneNode(id: node.id, kind: node.kind,
                payload: SceneEndPayload(sceneOutcomeId: 'recovered')) else node],
            edges: original.graph.edges));
        final gate = NarrativeRuntimeActivityGate();
        final completionActivities = <NarrativeRuntimeActivity>[];
        final completionStates = <GameState>[];
        var recoveryLoads = 0;
        late PlayableMapGame game;
        game = _game(bundle: source.copyWith(manifest: source.manifest.copyWith(scenes: [scene])),
          initialState: _battleReadyState().copyWith(
            trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
          narrativeRuntimeActivityGate: gate,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (failOutcome && occurrence.source.kind == NarrativeEventSourceKind.outcomeReceived) {
              throw StateError('Completion outcome planning unavailable');
            }
          },
          gameCompletionEmitter: (_) async {
            completionActivities.add(gate.activity);
            completionStates.add(game.gameStateSnapshot);
          },
          defeatRecoveryCapsLoader: (_) async {
            recoveryLoads++;
            return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}});
          });
        await _load(game);
        final before = await game.debugReadNarrativeGameStateForTest();
        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(() => gate.activity == NarrativeRuntimeActivity.idle);
        if (!failOutcome) {
          await _waitUntilWithoutUpdate(() => completionStates.isNotEmpty);
        }
        await Future<void>.delayed(Duration.zero);
        expect(recoveryLoads, 1);
        expect(completionActivities, failOutcome ? isEmpty : [NarrativeRuntimeActivity.idle]);
        final state = game.gameStateSnapshot;
        final canonical = await game.debugReadNarrativeGameStateForTest();
        expect(state.trainerProfile.money, failOutcome ? 1000 : 900);
        expect(state.metadata[playerDefeatCountMetadataKey], failOutcome ? null : '1');
        expect(state.metadata[sceneGameCompletionEndingMetadataKey], failOutcome ? null : 'ending.recovery');
        if (failOutcome) {
          expect(canonical, before);
          expect(completionStates, isEmpty);
        } else {
          expect(completionStates, hasLength(1));
          expect(completionStates.single.metadata[playerDefeatCountMetadataKey], '1');
          expect(completionStates.single.trainerProfile.money, 900);
          expect(canonical.metadata[sceneGameCompletionEndingMetadataKey], 'ending.recovery');
        }
      });
    }

    test('FinishGame waits for an in-flight recovery checkpoint before completion', () async {
      final gate = NarrativeRuntimeActivityGate();
      final initial = _battleReadyState().copyWith(
        trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000));
      final repository = _GateMemoryRepository(gate)..storedState = initial;
      final bundle = _whiteOutBundle(finishGame: true);
      final checkpointEntered = Completer<void>();
      final checkpointRelease = Completer<void>();
      final completionActivities = <NarrativeRuntimeActivity>[];
      var checkpoints = 0;
      addTearDown(() {
        if (!checkpointRelease.isCompleted) checkpointRelease.complete();
      });
      final game = _game(bundle: bundle, initialState: initial,
        narrativeRuntimeActivityGate: gate,
        saveRepository: repository,
        runtimeMapBundleLoader: ({required projectFilePath, required mapId}) async => bundle,
        defeatRecoveryCapsLoader: (_) async => const RuntimePlayerServiceRecoveryCaps(
          maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}}),
        defeatRecoveryCheckpointEmitter: () async {
          checkpoints++;
          checkpointEntered.complete();
          await checkpointRelease.future;
        },
        gameCompletionEmitter: (_) async {
          completionActivities.add(gate.activity);
        });
      await _load(game);
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await checkpointEntered.future.timeout(const Duration(seconds: 2));
      expect(gate.activity, NarrativeRuntimeActivity.idle);
      expect(completionActivities, isEmpty);
      expect(await game.loadGame(), isFalse);
      expect(repository.loadCount, 0);
      expect(game.gameStateSnapshot.trainerProfile.money, 900);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], '1');
      for (var tick = 0; tick < 8; tick++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(checkpoints, 1);
      expect(completionActivities, isEmpty);
      checkpointRelease.complete();
      await _waitUntilWithoutUpdate(() => completionActivities.isNotEmpty);
      expect(completionActivities, [NarrativeRuntimeActivity.idle]);
      for (var tick = 0; tick < 8; tick++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(checkpoints, 1);
      expect(completionActivities, [NarrativeRuntimeActivity.idle]);
      expect(game.gameStateSnapshot.trainerProfile.money, 900);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], '1');
      expect(await game.loadGame(), isTrue);
      expect(repository.loadCount, 1);
      expect(game.gameStateSnapshot.trainerProfile.money, 1000);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], isNull);
      expect(game.gameStateSnapshot.metadata[sceneGameCompletionEndingMetadataKey], isNull);
    });

    test('failure after prepared recovery compensates state without a success notification', () async {
      final directory = await Directory.systemTemp.createTemp('whiteout-compensation-');
      addTearDown(() => directory.delete(recursive: true));
      final gate = NarrativeRuntimeActivityGate();
      final path = '${directory.path}/checkpoint.json';
      final repository = _WhiteOutFileRepository(path, gate);
      final initial = _battleReadyState().copyWith(
        trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000),
        metadata: {playerRecoveryMapIdMetadataKey: _sourceMapId, playerRecoveryPositionXMetadataKey: '3',
          playerRecoveryPositionYMetadataKey: '3', playerRecoveryFacingMetadataKey: 'north'});
      await repository.save(initial);
      var recoveryLoads = 0;
      var checkpoints = 0;
      final notifications = <String>[];
      final game = _game(bundle: _whiteOutBundle(finishGame: true), initialState: initial,
        narrativeRuntimeActivityGate: gate, saveRepository: repository,
        defeatRecoveryCapsLoader: (_) async {
          recoveryLoads++;
          return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}});
        }, defeatRecoveryCheckpointEmitter: () async { checkpoints++; });
      game.runtimeNotificationListenable.addListener(() {
        final text = game.runtimeNotificationListenable.value?.text;
        if (text != null) notifications.add(text);
      });
      await _load(game);
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntilWithoutUpdate(() => gate.activity == NarrativeRuntimeActivity.idle);
      expect(recoveryLoads, 1);
      expect(checkpoints, 0);
      expect(notifications.where((text) => text.startsWith('Défaite')), isEmpty);
      expect(game.gameStateSnapshot.metadata[sceneGameCompletionEndingMetadataKey], isNull);
      expect(game.gameStateSnapshot.trainerProfile.money, 1000);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], isNull);
      expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
      expect(game.gameStateSnapshot.playerPosition, initial.playerPosition);
      expect(await game.saveGame(), isTrue);
      final restored = await _WhiteOutFileRepository(path, NarrativeRuntimeActivityGate()).load();
      expect(restored!.trainerProfile.money, 1000);
      expect(restored.metadata[playerDefeatCountMetadataKey], isNull);
      expect(restored.metadata[sceneGameCompletionEndingMetadataKey], isNull);
      expect(restored.playerPosition, initial.playerPosition);
    });

    for (final failure in ['followup', 'caps']) {
      test('autonomous whiteOut $failure failure publishes no partial recovery', () async {
        final gate = NarrativeRuntimeActivityGate();
        var checkpointCount = 0;
        var recoveryLoads = 0;
        final game = _game(bundle: _whiteOutBundle(followup: failure == 'followup'),
          initialState: _battleReadyState().copyWith(trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
          narrativeRuntimeActivityGate: gate,
          dialogueSessionLoader: (_) async => throw StateError('Follow-up unavailable'),
          defeatRecoveryCapsLoader: (_) async {
            recoveryLoads++;
            throw StateError('Recovery caps unavailable');
          },
          defeatRecoveryCheckpointEmitter: () async { checkpointCount++; });
        await _load(game);
        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(() => gate.activity == NarrativeRuntimeActivity.idle);
        await Future<void>.delayed(Duration.zero);
        expect(recoveryLoads, failure == 'followup' ? 0 : 1);
        expect(checkpointCount, 0);
        expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], isNull);
        expect(game.gameStateSnapshot.trainerProfile.money, 1000);
        expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
        expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 0));
      });
    }
    for (final recovery in SceneBattleDefeatRecovery.values) {
      for (final defeat in [false, true]) {
        test('scripted battle $recovery defeat=$defeat recovers only when selected', () async {
          final gate = NarrativeRuntimeActivityGate();
          final repository = _GateMemoryRepository(gate);
          final initial = _battleReadyState().copyWith(
            trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000),
            metadata: {
              playerRecoveryMapIdMetadataKey: _sourceMapId,
              playerRecoveryPositionXMetadataKey: '3',
              playerRecoveryPositionYMetadataKey: '3',
              playerRecoveryFacingMetadataKey: 'north',
            },
          );
          final game = _game(
            bundle: _sceneBundle(recovery: recovery),
            initialState: initial,
            narrativeRuntimeActivityGate: gate,
            saveRepository: repository,
            dialogueSessionLoader: (_) async => _singleLineDialogue(),
            defeatRecoveryCapsLoader: (_) async => const RuntimePlayerServiceRecoveryCaps(
              maxHpByPartyIndex: {0: 20},
              maxPpByPartyIndex: {0: {'tackle': 35}},
            ),
          );
          await _load(game);
          expect(_press(game, RuntimeInputControl.primary), isTrue);
          await _waitUntilWithoutUpdate(() => game.debugFlowPhaseName == 'dialogue');
          expect(_press(game, RuntimeInputControl.primary), isTrue);
          await _waitUntilWithoutUpdate(() => game.debugHasPendingSceneBattle);
          game.debugApplyBattleOutcomeForTest(
            context: _trainerContext(),
            outcome: defeat ? _defeatOutcome() : _victoryOutcome(),
          );
          await _waitUntilWithoutUpdate(() => gate.activity == NarrativeRuntimeActivity.idle);
          final state = game.gameStateSnapshot;
          final shouldRecover = defeat && recovery == SceneBattleDefeatRecovery.returnToRecoveryPoint;
          expect(state.metadata[playerDefeatCountMetadataKey], shouldRecover ? '1' : null);
          expect(state.playerPosition, shouldRecover ? const GridPos(x: 3, y: 3) : const GridPos(x: 0, y: 0));
          expect(state.party.members.single.currentHp, shouldRecover ? 20 : defeat ? 1 : 12);
          expect(state.trainerProfile.money, shouldRecover ? 900 : 1000);
          expect(await game.saveGame(), isTrue);
          expect(repository.storedState?.metadata[playerDefeatCountMetadataKey], shouldRecover ? '1' : null);
          expect(repository.storedState?.playerPosition, state.playerPosition);
        });
      }
    }
    test('Event V2 Scene returns the recovered state to its coordinator', () async {
      final initial = _battleReadyState().copyWith(
        trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000),
        metadata: {
          playerRecoveryMapIdMetadataKey: _sourceMapId,
          playerRecoveryPositionXMetadataKey: '3',
          playerRecoveryPositionYMetadataKey: '3',
          playerRecoveryFacingMetadataKey: 'north',
        },
      );
      final game = _game(bundle: _sceneBundle(recovery: SceneBattleDefeatRecovery.returnToRecoveryPoint),
        initialState: initial,
        dialogueSessionLoader: (_) async => _singleLineDialogue(),
        defeatRecoveryCapsLoader: (_) async => const RuntimePlayerServiceRecoveryCaps(
          maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}}));
      await _load(game);
      final execution = game.debugExecuteNarrativeSceneForTest(NarrativeSceneExecutionRequest(
        eventId: 'recovery_test', sceneId: 'dialogue_battle_scene',
        executionId: 'recovery_test_execution', gameState: game.gameStateSnapshot));
      await _waitUntilWithoutUpdate(() => game.debugFlowPhaseName == 'dialogue');
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntilWithoutUpdate(() => game.debugHasPendingSceneBattle);
      game.debugApplyBattleOutcomeForTest(context: _trainerContext(), outcome: _defeatOutcome());
      final result = await execution;
      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final state = (result as NarrativeSceneExecutionCompleted).updatedGameState;
      expect(state.metadata[playerDefeatCountMetadataKey], '1');
      expect(state.playerPosition, const GridPos(x: 3, y: 3));
      expect(state.trainerProfile.money, 900);
      expect(state.party.members.single.currentHp, 20);
    });
    test('a failed follow-up after defeat does not commit recovery', () async {
      final source = _sceneBundle(recovery: SceneBattleDefeatRecovery.returnToRecoveryPoint);
      final sceneJson = source.manifest.scenes.single.toJson();
      final graph = Map<String, dynamic>.from(sceneJson['graph'] as Map);
      graph['nodes'] = [
        ...graph['nodes'] as List,
        SceneNode(id: 'followup', kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'scene_dialogue')).toJson(),
      ];
      graph['edges'] = [
        for (final edge in graph['edges'] as List)
          if ((edge as Map)['id'] == 'battle_defeat') {...edge, 'toNodeId': 'followup'} else edge,
        SceneEdge(id: 'followup_end', fromNodeId: 'followup', fromPortId: 'completed',
          toNodeId: 'defeat_end', kind: SceneEdgeKind.defaultFlow).toJson(),
      ];
      sceneJson['graph'] = graph;
      final gate = NarrativeRuntimeActivityGate();
      var dialogueLoads = 0;
      var recoveryLoads = 0;
      final game = _game(bundle: source.copyWith(manifest: source.manifest.copyWith(
          scenes: [SceneAsset.fromJson(sceneJson)])),
        initialState: _battleReadyState().copyWith(
          trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000)),
        narrativeRuntimeActivityGate: gate,
        dialogueSessionLoader: (_) async {
          if (++dialogueLoads > 1) throw StateError('Follow-up unavailable');
          return _singleLineDialogue();
        },
        defeatRecoveryCapsLoader: (_) async {
          recoveryLoads++;
          return const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {});
        },
      );
      await _load(game);
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntilWithoutUpdate(() => game.debugFlowPhaseName == 'dialogue');
      expect(_press(game, RuntimeInputControl.primary), isTrue);
      await _waitUntilWithoutUpdate(() => game.debugHasPendingSceneBattle);
      game.debugApplyBattleOutcomeForTest(context: _trainerContext(), outcome: _defeatOutcome());
      await _waitUntilWithoutUpdate(() => gate.activity == NarrativeRuntimeActivity.idle);
      expect(dialogueLoads, 2);
      expect(recoveryLoads, 0);
      expect(game.gameStateSnapshot.metadata[playerDefeatCountMetadataKey], isNull);
      expect(game.gameStateSnapshot.trainerProfile.money, 1000);
    });
    for (final failRecoveryLoad in [false, true]) {
      test('scripted defeat across maps loadFailure=$failRecoveryLoad is atomic', () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate);
        final source = _sceneBundle(recovery: SceneBattleDefeatRecovery.returnToRecoveryPoint);
        final manifest = source.manifest.copyWith(maps: [
          ...source.manifest.maps,
          const ProjectMapEntry(id: _restoredMapId, name: 'Recovery', relativePath: 'maps/recovery.json'),
        ]);
        final initial = _battleReadyState().copyWith(
          trainerProfile: const TrainerProfile(name: 'Joueur', money: 1000),
          metadata: {
            playerRecoveryMapIdMetadataKey: _restoredMapId,
            playerRecoveryPositionXMetadataKey: '3',
            playerRecoveryPositionYMetadataKey: '3',
            playerRecoveryFacingMetadataKey: 'north',
          },
        );
        var recoveryLoads = 0;
        final game = _game(bundle: source.copyWith(manifest: manifest),
          initialState: initial, narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          dialogueSessionLoader: (_) async => _singleLineDialogue(),
          defeatRecoveryCapsLoader: (_) async => const RuntimePlayerServiceRecoveryCaps(
            maxHpByPartyIndex: {0: 20}, maxPpByPartyIndex: {0: {'tackle': 35}}),
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) async {
            expect(mapId, _restoredMapId);
            recoveryLoads++;
            if (failRecoveryLoad) throw StateError('Recovery map unavailable');
            return _bundle(map: _plainMap(_restoredMapId)).copyWith(manifest: manifest);
          },
        );
        await _load(game);
        final sourceState = game.gameStateSnapshot;
        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(() => game.debugFlowPhaseName == 'dialogue');
        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(() => game.debugHasPendingSceneBattle);
        game.debugApplyBattleOutcomeForTest(context: _trainerContext(), outcome: _defeatOutcome());
        await _waitUntil(game, () => gate.activity == NarrativeRuntimeActivity.idle
            && !game.debugIsMapActivationDispatchInFlight, maxTicks: 1800);
        final state = game.gameStateSnapshot;
        expect(recoveryLoads, greaterThan(0));
        expect(state.currentMapId, failRecoveryLoad ? _sourceMapId : _restoredMapId);
        expect(state.playerPosition, failRecoveryLoad ? initial.playerPosition : const GridPos(x: 3, y: 3));
        expect(state.metadata[playerDefeatCountMetadataKey], failRecoveryLoad ? null : '1');
        expect(state.trainerProfile.money, failRecoveryLoad ? 1000 : 900);
        if (failRecoveryLoad) {
          expect(state.party, sourceState.party);
          expect(state.metadata, sourceState.metadata);
          expect(state.narrativeEventProgress, sourceState.narrativeEventProgress);
        } else {
          expect(state.party.members.single.currentHp, 20);
        }
        expect(await game.saveGame(), isTrue);
        expect(repository.storedState?.currentMapId, state.currentMapId);
        expect(repository.storedState?.trainerProfile.money, state.trainerProfile.money);
      });
    }
    test(
      'battle handoff blocks load until async setup terminates',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _state(
            mapId: _sourceMapId,
            position: const GridPos(x: 3, y: 3),
          );
        final setupStarted = Completer<void>();
        final releaseSetup = Completer<void>();
        final game = _game(
          bundle: _sceneBundle(),
          initialState: _battleReadyState(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          beforeBattleHandoffPreparation: () async {
            setupStarted.complete();
            await releaseSetup.future;
          },
        );
        await _load(game);

        final handoff = game.debugOpenBattleForTest(_trainerContext().request);
        await setupStarted.future;

        expect(game.debugFlowPhaseName, 'battleTransition');
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);

        releaseSetup.complete();
        await handoff;
        expect(game.debugFlowPhaseName, isNot('battleTransition'));
        expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
        expect(
          game.gameStateSnapshot.playerPosition,
          isNot(const GridPos(x: 3, y: 3)),
        );
      },
    );

    test(
      'successful load discards queued Scenario completion and follow work '
      'before the restored state can be mutated',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final restoredState = _state(
          mapId: _restoredMapId,
          position: const GridPos(x: 1, y: 1),
        );
        final repository = _GateMemoryRepository(gate)
          ..storedState = restoredState;
        final restoredBundle = _bundle(map: _plainMap(_restoredMapId));
        final game = _game(
          bundle: _bundle(
            map: _followMap(),
            scenarios: <ScenarioAsset>[_mapEnterFollowScenario()],
          ),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
            expect(mapId, _restoredMapId);
            return Future<RuntimeMapBundle>.value(restoredBundle);
          },
        );
        await _load(game);
        expect(game.debugHasActiveScenarioFollow, isTrue);

        expect(await game.loadGame(), isTrue);
        expect(
          game.debugHasActiveScenarioFollow,
          isFalse,
          reason: 'A successful load must purge the old map follow owner.',
        );
        for (var i = 0; i < 80; i++) {
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }

        final state = game.gameStateSnapshot;
        expect(state.currentMapId, _restoredMapId);
        expect(state.progression.completedCutsceneIds, isEmpty);
        expect(
          state.storyFlags.activeFlags,
          isNot(contains(scenarioOutcomeFlagName(_followScenarioId))),
        );
        expect(game.debugHasActiveScenarioFollow, isFalse);
        expect(game.debugHasPendingLeaderWarpHandoff, isFalse);
      },
    );

    test(
      'successful load purges an old-map Scenario NPC warp entry',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _state(mapId: _restoredMapId);
        final restoredBundle = _bundle(map: _plainMap(_restoredMapId));
        final game = _game(
          bundle: _leaderWarpBundle(),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeTilesetImageLoader: _leaderTilesetLoader,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
            expect(mapId, _restoredMapId);
            return Future<RuntimeMapBundle>.value(restoredBundle);
          },
        );
        await _load(game);

        expect(
          game.debugRunScenarioMoveCharacterToWarp(
            entityId: 'leader',
            warpId: 'leader_exit',
          ),
          isTrue,
        );
        expect(game.debugPendingScenarioNpcWarpEntryCount, 1);

        expect(await game.loadGame(), isTrue);

        expect(game.debugPendingScenarioNpcWarpEntryCount, 0);
        expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
      },
    );

    test(
      'successful load purges a leader warp handoff and its active follow',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _state(mapId: _restoredMapId);
        final restoredBundle = _bundle(map: _plainMap(_restoredMapId));
        final game = _game(
          bundle: _leaderWarpBundle(),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeTilesetImageLoader: _leaderTilesetLoader,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
            expect(mapId, _restoredMapId);
            return Future<RuntimeMapBundle>.value(restoredBundle);
          },
        );
        await _load(game);

        expect(game.debugStartScenarioFollow('leader'), isTrue);
        expect(
          game.debugRunScenarioMoveCharacterToWarp(
            entityId: 'leader',
            warpId: 'leader_exit',
          ),
          isTrue,
        );
        await _waitUntil(game, () => game.debugHasPendingLeaderWarpHandoff);
        expect(game.debugHasActiveScenarioFollow, isTrue);

        expect(await game.loadGame(), isTrue);

        expect(game.debugHasPendingLeaderWarpHandoff, isFalse);
        expect(game.debugHasActiveScenarioFollow, isFalse);
        expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
      },
    );

    test(
      'direct MapEvent Scene holds sceneActive through dialogue and hosted '
      'Battle then releases it terminally',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _battleReadyState();
        final game = _game(
          bundle: _sceneBundle(),
          initialState: _battleReadyState(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          dialogueSessionLoader: (_) async => _singleLineDialogue(),
        );
        await _load(game);

        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(
          () => game.debugFlowPhaseName == 'dialogue',
        );

        expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);

        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(() => game.debugHasPendingSceneBattle);

        expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(),
        );
        await _waitUntilWithoutUpdate(
          () => gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
      },
    );
  });
}

PlayableMapGame _game({
  required RuntimeMapBundle bundle,
  required GameState initialState,
  NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
  GameSaveRepository? saveRepository,
  RuntimeDialogueSessionLoader? dialogueSessionLoader,
  RuntimeMapBundleLoader? runtimeMapBundleLoader,
  RuntimeTilesetImageLoader? runtimeTilesetImageLoader,
  Future<void> Function()? beforeBattleHandoffPreparation,
  Future<RuntimePlayerServiceRecoveryCaps> Function(GameState)? defeatRecoveryCapsLoader,
  Future<void> Function()? defeatRecoveryCheckpointEmitter,
  MapActivationReason initialMapActivationReason = MapActivationReason.initialBoot,
  Future<void> Function(NarrativeEventOccurrence)? beforeNarrativeAuthorityPreparation,
  GameCompletionRequestEmitter? gameCompletionEmitter,
}) {
  final game = _TestPlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/checkpoint_load_safety/project.json',
    saveData: saveDataFromGameState(initialState),
    narrativeRuntimeActivityGate: narrativeRuntimeActivityGate,
    saveRepository: saveRepository,
    dialogueSessionLoader: dialogueSessionLoader,
    runtimeMapBundleLoader: runtimeMapBundleLoader,
    runtimeTilesetImageLoader: runtimeTilesetImageLoader,
    runtimePlayerPokemonProgressionCatalogLoader:
        _loadCheckpointProgressionCatalogs,
    beforeBattleHandoffPreparation: beforeBattleHandoffPreparation,
    defeatRecoveryCapsLoader: defeatRecoveryCapsLoader,
    defeatRecoveryCheckpointEmitter: defeatRecoveryCheckpointEmitter,
    initialMapActivationReason: initialMapActivationReason,
    beforeNarrativeAuthorityPreparation: beforeNarrativeAuthorityPreparation,
    gameCompletionEmitter: gameCompletionEmitter,
  );
  addTearDown(game.onRemove);
  return game;
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
    super.dialogueSessionLoader,
    super.runtimeMapBundleLoader,
    super.runtimeTilesetImageLoader,
    super.runtimePlayerPokemonProgressionCatalogLoader,
    super.beforeBattleHandoffPreparation,
    super.defeatRecoveryCapsLoader,
    super.defeatRecoveryCheckpointEmitter,
    super.initialMapActivationReason,
    super.beforeNarrativeAuthorityPreparation,
    super.gameCompletionEmitter,
  });

  @override
  bool get isLoaded => true;
}

Future<RuntimePlayerPokemonProgressionCatalogs>
    _loadCheckpointProgressionCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  return const RuntimePlayerPokemonProgressionCatalogs(
    speciesById: <String, PlayerPokemonHydrationSpecies>{
      'aquafi': PlayerPokemonHydrationSpecies(
        id: 'aquafi',
        baseStats: PokemonBaseStats(
          hp: 44,
          attack: 48,
          defense: 65,
          specialAttack: 50,
          specialDefense: 64,
          speed: 43,
        ),
        primaryAbilityId: 'torrent',
        abilityIds: <String>['torrent'],
        growthRateId: 'medium_slow',
      ),
      'sproutle': PlayerPokemonHydrationSpecies(
        id: 'sproutle',
        baseStats: PokemonBaseStats(
          hp: 45,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ),
        primaryAbilityId: 'overgrow',
        abilityIds: <String>['overgrow'],
        growthRateId: 'medium_slow',
      ),
    },
    maxPpByMoveId: <String, int>{
      'surf': 15,
      'tackle': 35,
    },
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _waitUntilWithoutUpdate(
    () => !game.debugIsMapActivationDispatchInFlight,
  );
}

bool _press(PlayableMapGame game, RuntimeInputControl control) {
  return game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Timed out: flow=${game.debugFlowPhaseName} '
    'activation=${game.debugIsMapActivationDispatchInFlight}.',
  );
}

Future<void> _waitUntilWithoutUpdate(
  bool Function() done, {
  int maxTurns = 360,
}) async {
  for (var i = 0; i < maxTurns; i++) {
    if (done()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for an asynchronous runtime condition.');
}

RuntimeMapBundle _bundle({
  required MapData map,
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<ProjectScriptEntry> scripts = const <ProjectScriptEntry>[],
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Checkpoint Load Safety',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      dialogues: dialogues,
      scripts: scripts,
      trainers: trainers,
      scenarios: scenarios,
      scenes: scenes,
    ),
    map: map,
    projectRootDirectory: '/tmp/checkpoint_load_safety',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _plainMap(String id) {
  return MapData(
    id: id,
    name: id,
    size: const GridSize(width: 6, height: 6),
    layers: const <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_$id',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: const GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: const MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_$id'),
  );
}

MapData _followMap() {
  return const MapData(
    id: _sourceMapId,
    name: 'Follow source',
    size: GridSize(width: 6, height: 6),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_follow',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'leader',
        name: 'Leader',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 4, y: 4),
        npc: MapEntityNpcData(displayName: 'Leader'),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_follow'),
  );
}

MapData _leaderWarpMap() {
  return const MapData(
    id: _sourceMapId,
    name: 'Leader warp source',
    size: GridSize(width: 6, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    warps: <MapWarp>[
      MapWarp(
        id: 'leader_exit',
        pos: GridPos(x: 4, y: 1),
        targetMapId: _restoredMapId,
        targetPos: GridPos(x: 1, y: 1),
      ),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_leader_warp',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'leader',
        name: 'Leader',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 1),
        npc: MapEntityNpcData(
          displayName: 'Leader',
          characterId: 'leader_character',
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_leader_warp'),
  );
}

RuntimeMapBundle _leaderWarpBundle() {
  final map = _leaderWarpMap();
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Leader warp checkpoint fixture',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: _sourceMapId,
          name: 'Leader warp source',
          relativePath: 'maps/$_sourceMapId.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'leader_tiles',
          name: 'Leader tiles',
          relativePath: 'tilesets/leader.png',
        ),
      ],
      characters: <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'leader_character',
          name: 'Leader character',
          tilesetId: 'leader_tiles',
          frameWidth: 8,
          frameHeight: 8,
        ),
      ],
    ),
    map: map,
    projectRootDirectory: '/tmp/checkpoint_load_safety',
    tilesetAbsolutePathsById: const <String, String>{
      'leader_tiles': '/tmp/checkpoint_load_safety/tilesets/leader.png',
    },
  );
}

Future<Map<String, RuntimeTilesetImage>> _leaderTilesetLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return <String, RuntimeTilesetImage>{
    for (final id in absolutePathByTilesetId.keys)
      id: await runtimeTilesetImage(
        List<Color>.filled(4, const Color(0xFF4060A0)),
      ),
  };
}

ScenarioAsset _mapEnterFollowScenario() {
  return const ScenarioAsset(
    id: _followScenarioId,
    name: 'Follow before load',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _sourceMapId),
      ),
      ScenarioNode(
        id: 'follow',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionFollowCharacter,
          params: <String, String>{'leaderId': 'leader'},
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_follow',
        fromNodeId: 'source',
        toNodeId: 'follow',
      ),
      ScenarioEdge(
        id: 'follow_to_end',
        fromNodeId: 'follow',
        toNodeId: 'end',
      ),
    ],
  );
}

RuntimeMapBundle _sceneBundle({SceneBattleDefeatRecovery recovery = SceneBattleDefeatRecovery.continueScene}) {
  return _bundle(
    map: _sceneMap(),
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'scene_dialogue',
        name: 'Scene dialogue',
        relativePath: 'dialogues/scene_dialogue.yarn',
      ),
    ],
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'Checkpoint Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    scenes: <SceneAsset>[_dialogueBattleScene(recovery: recovery)],
  );
}

RuntimeMapBundle _whiteOutBundle({bool repeated = false, bool followup = false, bool finishGame = false,
  String sceneId = 'dialogue_battle_scene', String endingId = 'ending.recovery', String? outcomeId}) {
  final source = _sceneBundle();
  final ids = ['start', 'whiteOut', if (repeated) 'whiteOutAgain', if (followup) 'followup', if (finishGame) 'finishGame', 'end'];
  return source.copyWith(manifest: source.manifest.copyWith(scenes: [
    SceneAsset(id: sceneId, name: 'Défaite scénarisée',
      declaredOutcomes: [if (outcomeId != null) SceneOutcome(id: outcomeId, label: outcomeId)], graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (final id in ids.where((id) => id.startsWith('whiteOut')))
          SceneNode(id: id, kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(SceneInteractiveCommand.fromJson({'kind': 'whiteOut'}))),
        if (followup) SceneNode(id: 'followup', kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'scene_dialogue')),
        if (finishGame) SceneNode(id: 'finishGame', kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(SceneConsequence.finishGame(
            endingId: endingId, outcome: SceneGameCompletionOutcome.completed,
            result: SceneFinishGameResult(title: SceneLocalizedText(fallback: 'Fin'), summary: SceneLocalizedText(fallback: 'Terminée')),
            postGamePolicy: ScenePostGamePolicy.returnToTitle))),
        if (outcomeId == null) SceneNode(id: 'end', kind: SceneNodeKind.end)
        else SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload(sceneOutcomeId: outcomeId)),
      ],
      edges: [for (var i = 0; i < ids.length - 1; i++)
        SceneEdge(id: 'link_$i', fromNodeId: ids[i], fromPortId: 'completed',
          toNodeId: ids[i + 1], kind: SceneEdgeKind.defaultFlow)],
    )),
  ]));
}

MapData _sceneMap() {
  return const MapData(
    id: _sourceMapId,
    name: 'Scene map',
    size: GridSize(width: 4, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_scene',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'trainer_npc',
        name: 'Trainer NPC',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 2),
        npc: MapEntityNpcData(
          displayName: 'Trainer NPC',
          trainerId: _trainerId,
        ),
      ),
    ],
    events: <MapEventDefinition>[
      MapEventDefinition(
        id: 'scene_event',
        title: 'Scene event',
        position: EventPosition(layerId: 'objects', x: 1, y: 0),
        pages: <MapEventPage>[
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'dialogue_battle_scene'),
          ),
        ],
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_scene'),
  );
}

SceneAsset _dialogueBattleScene({SceneBattleDefeatRecovery recovery = SceneBattleDefeatRecovery.continueScene}) {
  return SceneAsset(
    id: 'dialogue_battle_scene',
    name: 'Dialogue and hosted battle',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'scene_dialogue'),
        ),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: _trainerId,
            npcEntityId: 'trainer_npc',
            defeatRecovery: recovery,
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'victory_end', kind: SceneNodeKind.end),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_dialogue',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'dialogue_to_battle',
          fromNodeId: 'dialogue',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

GameState _state({
  required String mapId,
  GridPos position = const GridPos(x: 0, y: 0),
}) {
  return GameState(
    saveId: 'checkpoint-load-safety',
    currentMapId: mapId,
    playerPosition: position,
    playerFacing: EntityFacing.east,
  );
}

GameState _battleReadyState() {
  return const GameState(
    saveId: 'checkpoint-scene',
    currentMapId: _sourceMapId,
    playerPosition: GridPos(x: 0, y: 0),
    playerFacing: EntityFacing.east,
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          knownMoveIds: <String>['tackle'],
          currentHp: 20,
        ),
      ],
    ),
  );
}

DialogueSession _singleLineDialogue() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Checkpoint dialogue')],
      ),
    ],
    'Start',
  )!;
}

RuntimeActiveBattleContext _trainerContext() {
  return const RuntimeActiveBattleContext(
    request: TrainerBattleStartRequest(
      requestId: 'checkpoint-scene-battle',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: _sourceMapId,
        playerPos: GridPos(x: 0, y: 0),
        playerFacing: Direction.east,
      ),
      trainerId: _trainerId,
      npcEntityId: 'trainer_npc',
      mapId: _sourceMapId,
      playerPos: GridPos(x: 0, y: 0),
    ),
    playerPartyIndex: 0,
  );
}

BattleOutcome _defeatOutcome() {
  return BattleOutcome(
    type: BattleOutcomeType.defeat,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: const BattleCombatant(speciesId: 'sproutle', level: 5, currentHp: 0, maxHp: 20, stats: _battleStats,
        moves: [BattleMove(id: 'tackle', name: 'Tackle', power: 10)]),
      enemy: const BattleCombatant(speciesId: 'embercub', level: 5, currentHp: 10, maxHp: 18, stats: _battleStats,
        moves: [BattleMove(id: 'scratch', name: 'Scratch', power: 10)]),
      currentTurn: null,
      outcome: null,
    ),
  );
}

BattleOutcome _victoryOutcome() {
  return BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: const BattleCombatant(
        speciesId: 'sproutle',
        level: 5,
        currentHp: 12,
        maxHp: 20,
        stats: _battleStats,
        moves: <BattleMove>[
          BattleMove(id: 'tackle', name: 'Tackle', power: 10),
        ],
      ),
      enemy: const BattleCombatant(
        speciesId: 'embercub',
        level: 5,
        currentHp: 0,
        maxHp: 18,
        stats: _battleStats,
        moves: <BattleMove>[
          BattleMove(id: 'scratch', name: 'Scratch', power: 10),
        ],
      ),
      currentTurn: null,
      outcome: null,
    ),
  );
}

final class _GateMemoryRepository implements GameSaveRepository {
  _GateMemoryRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.load,
      () async {
        loadCount++;
        return storedState;
      },
    );
  }

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}

final class _WhiteOutFileRepository extends FileGameSaveRepository {
  _WhiteOutFileRepository(this.path, NarrativeRuntimeActivityGate gate)
      : super(activityGate: gate);

  final String path;

  @override
  Future<String> getSaveFilePath() async => path;
}
