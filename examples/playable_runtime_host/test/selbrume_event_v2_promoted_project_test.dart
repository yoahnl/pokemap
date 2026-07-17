import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:path/path.dart' as p;

const _portMapId = 'map_port_brisants';
const _marshMapId = 'map_marais_salants';
const _lysaEntityId = 'npc_lysa';
const _clueEntityId = 'clue_glass_object';
const _portTriggerId = 'zone_port_entry';
const _lysaEventId = 'evt_019abcde-4000-7000-8000-000000000001';
const _lysaFactId = 'fact_lysa_port_resolved';
const _lysaStepId = 'step_rival_battle';
const _lysaTrainerId = 'trainer_lysa_port';
const _lysaWorldRuleId = 'world_rule_lysa_port_resolved';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('J5 promoted Selbrume bytes load and play the Lysa Golden Slice',
      () async {
    final repositoryRoot = _findRepositoryRoot();
    final selbrumeRoot = Directory(p.join(repositoryRoot.path, 'selbrume'));
    final fixtureRoot = Directory(
      p.join(
        repositoryRoot.path,
        'examples',
        'playable_runtime_host',
        'event_builder_v2_selbrume_slice',
      ),
    );
    final promotion = _jsonObject(
      jsonDecode(
        await File(p.join(fixtureRoot.path, 'promotion_manifest.json'))
            .readAsString(),
      ),
    );
    final orderedFiles = _jsonObjects(promotion['orderedFiles']);
    expect(promotion['state'], 'frozenForJ5');
    expect(orderedFiles, hasLength(4));
    for (final entry in orderedFiles) {
      final promoted = File(
        p.join(repositoryRoot.path, entry['destination']! as String),
      );
      expect(await promoted.exists(), isTrue, reason: promoted.path);
      expect(
        narrativeEventBytesFingerprint(await promoted.readAsBytes()),
        entry['afterSha256'],
        reason: 'J5 must run on the promoted bytes, not fixture bytes.',
      );
    }

    final projectPath = p.join(selbrumeRoot.path, 'project.json');
    final bundles = <String, RuntimeMapBundle>{};
    Future<RuntimeMapBundle> load(String mapId) async {
      return bundles[mapId] ??= await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: mapId,
      );
    }

    final portBundle = await load(_portMapId);
    final marshBundle = await load(_marshMapId);
    final project = portBundle.manifest;
    expect(project.maps, hasLength(10));
    expect(project.scenarios.map((entry) => entry.id),
        contains('p6_03_first_interaction'));
    expect(portBundle.map.connections, hasLength(1));
    expect(marshBundle.map.connections, hasLength(2));
    expect(
      portBundle.map.entities.map((entry) => entry.id),
      contains(_lysaEntityId),
    );
    expect(
      marshBundle.map.entities.map((entry) => entry.id),
      contains(_clueEntityId),
    );
    expect(
      portBundle.map.triggers.map((entry) => entry.id),
      contains(_portTriggerId),
    );
    expect(project.eventRegistry?.mode, EventSystemMode.dualRead);
    expect(project.eventRegistry?.records, hasLength(3));
    expect(
      project.worldRules.map((entry) => entry.id),
      contains(_lysaWorldRuleId),
    );
    expect(
      await File(p.join(selbrumeRoot.path, 'dialogues', 'lysa_port.yarn'))
          .readAsString(),
      allOf(contains('title: LysaPort'), contains('Port des Brisants')),
    );

    final snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: project,
      loadMap: (mapId) async {
        final bundle = await load(mapId);
        return (project: bundle.manifest, map: bundle.map);
      },
    );
    var state = const GameState(
      saveId: 'phase_j_promoted_lysa',
      currentMapId: _portMapId,
      playerPosition: GridPos(x: 26, y: 17),
    );
    final transactions = NarrativeEventStateTransactions(state);
    final source = NarrativeEventSourceRef.entityInteract(
      _portMapId,
      _lysaEntityId,
    );
    var dialogueCalls = 0;
    var cinematicCalls = 0;
    var battleCalls = 0;
    var sequence = 0;
    final bridge = NarrativeSpatialProductionDispatchBridge(
      stateTransactions: transactions,
      currentGameState: () => state,
      onGameStateCommitted: (next) => state = next,
      prepareAuthority: (_, occurrence) async {
        return NarrativeEventDispatchAuthority.prepare(
          registryResult: snapshot.registryResult,
          occurrence: occurrence,
          factResolver: snapshot.factResolver,
          legacyClaimIndex: snapshot.legacyClaimIndex,
          projectCatalog: snapshot.projectCatalog,
        );
      },
      executeScene: (request) async {
        final battleOutcomes = <NarrativeOutcomeRef>[];
        return executeNarrativeEventScene(
          request: request,
          project: snapshot.project,
          mapsById: snapshot.mapsById,
          currentGameState: () => state,
          hostedBattleOutcomes: battleOutcomes,
          callbacks: SceneRuntimeHostCallbacks(
            evaluateCondition: (_) =>
                throw StateError('No condition is expected.'),
            showDialogue: (intent) {
              dialogueCalls++;
              expect(intent.dialogueId, 'dialogue_lysa_port');
              expect(intent.yarnNodeName, 'LysaPort');
              return 'completed';
            },
            playCinematic: (intent) {
              cinematicCalls++;
              expect(intent.cinematicId, 'cinematic_lysa_port');
              return 'completed';
            },
            startBattle: (intent) {
              battleCalls++;
              expect(intent.trainerId, _lysaTrainerId);
              battleOutcomes.add(
                NarrativeOutcomeRef(
                  producerKind: NarrativeOutcomeProducerKind.battle,
                  producerId: 'trainer:trainer_lysa_port',
                  outcomeId: 'victory',
                ),
              );
              return 'victory';
            },
          ),
        );
      },
      legacyFallback: (_, __, ___) async {},
      activityPort: NoopNarrativeEventActivityPort(),
      isCurrentOccurrence: (_) => true,
      executionIdFactory: () => _runtimeId('evx', ++sequence),
      correlationIdFactory: () => _runtimeId('corr', ++sequence),
      deliveryIdFactory: () => _runtimeId('outd', ++sequence),
    );

    final dispatched = await bridge.dispatch(
      occurrenceId: 'phase-j-promoted-lysa',
      occurrence: NarrativeEventOccurrence(source: source),
    );
    expect(dispatched, isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(
      (dispatched as NarrativeSpatialProductionDispatchV2Handled)
          .execution
          .eventId,
      _lysaEventId,
    );
    expect((dialogueCalls, cinematicCalls, battleCalls), (1, 1, 1));
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_lysaEventId),
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId[_lysaFactId],
      isTrue,
    );
    expect(state.progression.completedStepIds, contains(_lysaStepId));
    expect(
      const RuntimeWorldRuleProjectionHook()
          .resolve(
            project: project,
            gameState: state,
            map: portBundle.map,
          )
          .hiddenEntityIds,
      contains(_lysaEntityId),
    );

    final reloaded = gameStateFromSaveData(
      SaveData.fromJson(
        jsonDecode(jsonEncode(saveDataFromGameState(state).toJson()))
            as Map<String, dynamic>,
      ),
    );
    expect(
      reloaded.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_lysaEventId),
    );
    expect(
      reloaded.narrativeFactRuntimeState.overridesByFactId[_lysaFactId],
      isTrue,
    );
    expect(reloaded.progression.completedStepIds, contains(_lysaStepId));
  });
}

String _runtimeId(String prefix, int sequence) {
  final suffix = sequence.toString().padLeft(12, '0');
  return '${prefix}_019abcde-6000-7000-8000-$suffix';
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = parent;
  }
}

Map<String, Object?> _jsonObject(Object? value) =>
    (value! as Map).cast<String, Object?>();

List<Map<String, Object?>> _jsonObjects(Object? value) => (value! as List)
    .map((entry) => (entry! as Map).cast<String, Object?>())
    .toList(growable: false);
