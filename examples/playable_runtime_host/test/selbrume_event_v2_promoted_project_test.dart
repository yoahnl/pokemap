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
const _portEntryEventId = 'evt_019abcde-4000-7000-8000-000000000002';
const _clueEventId = 'evt_019abcde-4000-7000-8000-000000000003';
const _lysaTrainerId = 'trainer_lysa_port';
const _lysaWorldRuleId = 'world_rule_lysa_port_resolved';
const _canonicalSeededProjectManifestSha256 =
    'sha256:0b067579828fbe1c780011c8fcc412b01bca16586d2148f51923e70ff46f18c8';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SEL-FIN-00 canonical Selbrume loads and plays the Lysa Golden Slice',
      () async {
    final repositoryRoot = _findRepositoryRoot();
    final selbrumeRoot = Directory(p.join(repositoryRoot.path, 'selbrume'));
    final historicalFixtureRoot = Directory(
      p.join(
        repositoryRoot.path,
        'examples',
        'playable_runtime_host',
        'event_builder_v2_selbrume_slice',
      ),
    );
    final historicalPromotion = _jsonObject(
      jsonDecode(
        await File(
          p.join(historicalFixtureRoot.path, 'promotion_manifest.json'),
        ).readAsString(),
      ),
    );
    final historicalSources = _jsonObjects(
      historicalPromotion['orderedFiles'],
    );
    expect(historicalPromotion['state'], 'frozenForJ5');
    expect(historicalSources, hasLength(4));
    expect(
      historicalSources.map((entry) => entry['order']),
      <int>[1, 2, 3, 4],
    );
    expect(
      historicalSources.map((entry) => entry['source']),
      <String>[
        'promotion_payload/project.json',
        'promotion_payload/maps/map_port_brisants.json',
        'promotion_payload/maps/map_marais_salants.json',
        'promotion_payload/dialogues/lysa_port.yarn',
      ],
    );
    for (final entry in historicalSources) {
      final source = entry['source']! as String;
      expect(
        p.posix.isWithin('promotion_payload', source),
        isTrue,
        reason: 'Historical J5 proof must read promotion_payload sources.',
      );
      final sourceFile = File(p.join(historicalFixtureRoot.path, source));
      expect(await sourceFile.exists(), isTrue, reason: sourceFile.path);
      expect(
        narrativeEventBytesFingerprint(await sourceFile.readAsBytes()),
        entry['sha256'],
        reason: 'The immutable J5 source must retain its recorded SHA-256.',
      );
    }

    final projectPath = p.join(selbrumeRoot.path, 'project.json');
    // This fingerprint covers only the seeded project.json manifest. The
    // separate seeder idempotence test/check gate all authored maps and Yarn
    // bytes without pretending current destinations still equal J5 payloads.
    expect(
      narrativeEventBytesFingerprint(await File(projectPath).readAsBytes()),
      _canonicalSeededProjectManifestSha256,
      reason: 'The canonical seeded project manifest must stay stable.',
    );
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
    expect(
      project.eventRegistry?.records
          .map((record) => record.definitionOrNull?.id),
      containsAll(<String>[_lysaEventId, _portEntryEventId, _clueEventId]),
      reason: 'The seeded campaign may add Events without dropping the '
          'three promoted runtime sources.',
    );
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
    var state = GameState(
      saveId: 'phase_j_promoted_lysa',
      currentMapId: _portMapId,
      playerPosition: const GridPos(x: 26, y: 17),
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: const <String, bool>{
          'fact_port_alert_seen': true,
        },
      ),
    );
    final transactions = NarrativeEventStateTransactions(state);
    final source = NarrativeEventSourceRef.entityInteract(
      _portMapId,
      _lysaEntityId,
    );
    var dialogueCalls = 0;
    var cinematicCalls = 0;
    var battleCalls = 0;
    var dualReadLegacyCalls = 0;
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
              return 'confident';
            },
            playCinematic: (intent) {
              cinematicCalls++;
              expect(intent.cinematicId, 'cinematic_rival_smiles');
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
      legacyFallback: (_, __, ___) async => dualReadLegacyCalls++,
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
    if (dispatched
        case NarrativeSpatialProductionDispatchFailed(
          :final failure,
          :final stackTrace,
        )) {
      final details = failure is NarrativeEventExecutionFailure
          ? '${failure.kind}: ${failure.cause}\n${failure.stackTrace}'
          : '$failure\n$stackTrace';
      fail('Lysa production dispatch failed: $details');
    }
    expect(dispatched, isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(
      (dispatched as NarrativeSpatialProductionDispatchV2Handled)
          .execution
          .eventId,
      _lysaEventId,
    );
    expect((dialogueCalls, cinematicCalls, battleCalls), (1, 1, 1));
    expect(dualReadLegacyCalls, 0);
    final duplicate = await bridge.dispatch(
      occurrenceId: 'phase-j-promoted-lysa',
      occurrence: NarrativeEventOccurrence(source: source),
    );
    expect(duplicate, isA<NarrativeSpatialProductionDispatchDuplicate>());
    expect((dialogueCalls, cinematicCalls, battleCalls), (1, 1, 1));
    expect(dualReadLegacyCalls, 0);
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_lysaEventId),
    );
    expect(
      state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries
          .map((delivery) => delivery.outcome),
      contains(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'scene_lysa_port',
          outcomeId: 'lysa.victory',
        ),
      ),
      reason: 'The production Scene must publish the qualified outcome that '
          'the runtime outbox will deliver to scene_rival_after_win.',
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
      reloaded.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
      state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
    );

    // The same promoted records remain single-authority after the explicit
    // v2Only transition. We keep all project content identical and change only
    // the runtime mode, so this comparison catches mode-specific fallback.
    final registry = project.eventRegistry!;
    final v2Project = ProjectManifest.fromJson(
      <String, dynamic>{
        ...project.toJson(),
        'eventRegistry': NarrativeEventRegistry(
          schemaVersion: registry.schemaVersion,
          mode: EventSystemMode.v2Only,
          records: registry.records,
          legacyClaims: registry.legacyClaims,
        ).toJson(),
      },
    );
    final v2Snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: v2Project,
      loadMap: (mapId) async {
        final loaded = await load(mapId);
        return (project: v2Project, map: loaded.map);
      },
    );
    var v2State = GameState(
      saveId: 'nsc_45_promoted_v2_only',
      currentMapId: _portMapId,
      playerPosition: const GridPos(x: 26, y: 17),
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: const {'fact_port_alert_seen': true},
      ),
    );
    final v2Transactions = NarrativeEventStateTransactions(v2State);
    var v2SceneCalls = 0;
    var v2LegacyCalls = 0;
    final v2Bridge = NarrativeSpatialProductionDispatchBridge(
      stateTransactions: v2Transactions,
      currentGameState: () => v2State,
      onGameStateCommitted: (next) => v2State = next,
      prepareAuthority: (_, occurrence) async {
        return NarrativeEventDispatchAuthority.prepare(
          registryResult: v2Snapshot.registryResult,
          occurrence: occurrence,
          factResolver: v2Snapshot.factResolver,
          legacyClaimIndex: v2Snapshot.legacyClaimIndex,
          projectCatalog: v2Snapshot.projectCatalog,
        );
      },
      executeScene: (request) async {
        v2SceneCalls++;
        expect(request.eventId, _lysaEventId);
        return NarrativeSceneExecutionResult.completed(
          updatedGameState: request.gameState,
          qualifiedOutcomes: const [],
        );
      },
      legacyFallback: (_, __, ___) async => v2LegacyCalls++,
      activityPort: NoopNarrativeEventActivityPort(),
      isCurrentOccurrence: (_) => true,
      executionIdFactory: () => _runtimeId('evx', ++sequence),
      correlationIdFactory: () => _runtimeId('corr', ++sequence),
      deliveryIdFactory: () => _runtimeId('outd', ++sequence),
    );
    final v2Dispatch = await v2Bridge.dispatch(
      occurrenceId: 'nsc-45-v2-only-lysa',
      occurrence: NarrativeEventOccurrence(source: source),
    );
    expect(v2Dispatch, isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(v2SceneCalls, 1);
    expect(v2LegacyCalls, 0);
    final v2Duplicate = await v2Bridge.dispatch(
      occurrenceId: 'nsc-45-v2-only-lysa',
      occurrence: NarrativeEventOccurrence(source: source),
    );
    expect(v2Duplicate, isA<NarrativeSpatialProductionDispatchDuplicate>());
    expect(v2SceneCalls, 1);
    expect(v2LegacyCalls, 0);
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
