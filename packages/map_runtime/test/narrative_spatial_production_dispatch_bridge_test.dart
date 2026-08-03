import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_spatial_production_dispatch_bridge.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';
const _executionId = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationId = 'corr_019abcde-0000-7000-8000-000000000003';
const _deliveryId = 'outd_019abcde-0000-7000-8000-000000000004';
const _legacyFingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('NS-EVENT-V2-20/21 spatial production dispatch bridge', () {
    test('executes one entityInteract occurrence through Event V2', () async {
      const runtimeState = GameState(
        saveId: 'save',
        metadata: {'origin': 'runtime'},
      );
      var currentState = runtimeState;
      final transactions = NarrativeEventStateTransactions(
        const GameState(saveId: 'save', metadata: {'origin': 'stale'}),
      );
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
      );
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(occurrence.source)],
      );
      var sceneCalls = 0;
      var legacyCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: registry,
          occurrence: value,
        ),
        executeScene: (request) async {
          sceneCalls++;
          expect(request.gameState.metadata, {'origin': 'runtime'});
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState.copyWith(
              metadata: const {'origin': 'scene'},
            ),
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
      );

      final result = await bridge.dispatch(
        occurrenceId: 'interaction-map-npc-1',
        occurrence: occurrence,
      );

      expect(result, isA<NarrativeSpatialProductionDispatchV2Handled>());
      expect(sceneCalls, 1);
      expect(legacyCalls, 0);
      expect(currentState.metadata, {'origin': 'scene'});
      expect(await transactions.read(), currentState);
    });

    test('supports triggerEnter and claims a concurrent occurrence once',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.triggerEnter('map', 'zone'),
      );
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(occurrence.source)],
      );
      final sceneStarted = Completer<void>();
      final releaseScene = Completer<void>();
      var sceneCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: registry,
          occurrence: value,
        ),
        executeScene: (request) async {
          sceneCalls++;
          sceneStarted.complete();
          await releaseScene.future;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async {},
      );

      final firstDispatch = bridge.dispatch(
        occurrenceId: 'trigger-map-zone-entry-1',
        occurrence: occurrence,
      );
      await sceneStarted.future;
      final duplicate = await bridge.dispatch(
        occurrenceId: 'trigger-map-zone-entry-1',
        occurrence: occurrence,
      );
      releaseScene.complete();
      final first = await firstDispatch;

      expect(first, isA<NarrativeSpatialProductionDispatchV2Handled>());
      expect(duplicate, isA<NarrativeSpatialProductionDispatchDuplicate>());
      expect(sceneCalls, 1);
    });

    test('falls back only for an authority-approved no-match', () async {
      for (final testCase in <({
        EventSystemMode mode,
        Type expectedResult,
        int expectedFallbackCalls,
      })>[
        (
          mode: EventSystemMode.legacyOnly,
          expectedResult: NarrativeSpatialProductionDispatchLegacyFallback,
          expectedFallbackCalls: 1,
        ),
        (
          mode: EventSystemMode.v2Only,
          expectedResult: NarrativeSpatialProductionDispatchNoFallback,
          expectedFallbackCalls: 0,
        ),
      ]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        final occurrence = NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
        );
        var fallbackCalls = 0;
        GameState? fallbackState;
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, value) async => _prepareAuthority(
            registry: _registry(testCase.mode),
            occurrence: value,
          ),
          legacyFallback: (_, value, gameState) async {
            expect(value, occurrence);
            fallbackCalls++;
            fallbackState = gameState;
          },
        );

        final result = await bridge.dispatch(
          occurrenceId: 'interaction-${testCase.mode.name}',
          occurrence: occurrence,
        );

        expect(result.runtimeType, testCase.expectedResult);
        expect(fallbackCalls, testCase.expectedFallbackCalls);
        if (testCase.expectedFallbackCalls == 1) {
          expect(fallbackState, currentState);
        }
      }
    });

    test('claimed-ineligible dualRead occurrence never falls back', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.entityInteract('map', 'npc');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy-npc-event');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source, enabled: false)],
        claims: [_claim(source, provenance)],
      );
      final occurrence = NarrativeEventOccurrence(
        source: source,
        provenance: provenance,
      );
      var sceneCalls = 0;
      var fallbackCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: registry,
          occurrence: value,
          legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
            registry,
            runtimeEvidence: LegacyClaimRuntimeEvidence(
              entries: [
                LegacyClaimRuntimeEvidenceEntry(
                  provenance: provenance,
                  source: source,
                  sourceFingerprint: _legacyFingerprint,
                ),
              ],
            ),
          ),
        ),
        executeScene: (request) async {
          sceneCalls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => fallbackCalls++,
      );

      final result = await bridge.dispatch(
        occurrenceId: 'interaction-claimed-ineligible',
        occurrence: occurrence,
      );

      expect(
        result,
        isA<NarrativeSpatialProductionDispatchClaimedIneligible>(),
      );
      expect(sceneCalls, 0);
      expect(fallbackCalls, 0);
    });

    test('blocked, failed, and cancelled dispatches stay fail-closed',
        () async {
      for (final testCase in <({
        String label,
        Future<NarrativeEventDispatchAuthorityPreparation> Function(
          NarrativeEventOccurrence occurrence,
        ) prepare,
        NarrativeSceneExecutionResult? sceneResult,
        Type expectedResult,
      })>[
        (
          label: 'blocked',
          prepare: (_) async => NarrativeEventDispatchAuthorityBlocked(
                reason:
                    NarrativeEventDispatchAuthorityBlockReason.invalidRegistry,
                diagnostics: const ['blocked fixture'],
              ),
          sceneResult: null,
          expectedResult: NarrativeSpatialProductionDispatchAuthorityBlocked,
        ),
        (
          label: 'failed',
          prepare: (occurrence) async => _prepareAuthority(
                registry: _registry(
                  EventSystemMode.v2Only,
                  records: [_record(occurrence.source)],
                ),
                occurrence: occurrence,
              ),
          sceneResult: NarrativeSceneExecutionResult.failed('scene failed'),
          expectedResult: NarrativeSpatialProductionDispatchFailed,
        ),
        (
          label: 'cancelled',
          prepare: (occurrence) async => _prepareAuthority(
                registry: _registry(
                  EventSystemMode.v2Only,
                  records: [_record(occurrence.source)],
                ),
                occurrence: occurrence,
              ),
          sceneResult:
              NarrativeSceneExecutionResult.cancelled('scene cancelled'),
          expectedResult: NarrativeSpatialProductionDispatchNoFallback,
        ),
      ]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        final occurrence = NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
        );
        var fallbackCalls = 0;
        var committedCalls = 0;
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) {
            committedCalls++;
            currentState = value;
          },
          prepareAuthority: (_, value) => testCase.prepare(value),
          executeScene: (_) async => testCase.sceneResult!,
          legacyFallback: (_, __, ___) async => fallbackCalls++,
        );

        final result = await bridge.dispatch(
          occurrenceId: 'interaction-${testCase.label}',
          occurrence: occurrence,
        );

        expect(result.runtimeType, testCase.expectedResult);
        expect(fallbackCalls, 0);
        expect(committedCalls, 0);
      }
    });

    test('stale occurrence during Scene rolls back and can be reclaimed',
        () async {
      const originalState = GameState(
        saveId: 'save',
        metadata: {'origin': 'runtime'},
      );
      var currentState = originalState;
      final transactions = NarrativeEventStateTransactions(currentState);
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.triggerEnter('map', 'zone'),
      );
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(occurrence.source)],
      );
      final sceneStarted = Completer<void>();
      final releaseScene = Completer<void>();
      var isCurrent = true;
      var sceneCalls = 0;
      var committedCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) {
          committedCalls++;
          currentState = value;
        },
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: registry,
          occurrence: value,
        ),
        executeScene: (request) async {
          sceneCalls++;
          if (sceneCalls == 1) {
            sceneStarted.complete();
            await releaseScene.future;
          }
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState.copyWith(
              metadata: {'sceneCall': '$sceneCalls'},
            ),
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async {},
        isCurrentOccurrence: (_) => isCurrent,
      );

      final staleDispatch = bridge.dispatch(
        occurrenceId: 'trigger-stale-reclaimable',
        occurrence: occurrence,
      );
      await sceneStarted.future;
      isCurrent = false;
      releaseScene.complete();
      final staleResult = await staleDispatch;

      expect(staleResult, isA<NarrativeSpatialProductionDispatchStale>());
      expect(await transactions.read(), originalState);
      expect(currentState, originalState);
      expect(committedCalls, 0);

      isCurrent = true;
      final retry = await bridge.dispatch(
        occurrenceId: 'trigger-stale-reclaimable',
        occurrence: occurrence,
      );

      expect(retry, isA<NarrativeSpatialProductionDispatchV2Handled>());
      expect(sceneCalls, 2);
      expect(committedCalls, 1);
    });

    test('stale legacy fallback does not open a second dispatch path',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
      );
      final fallbackStarted = Completer<void>();
      final releaseFallback = Completer<void>();
      var isCurrent = true;
      var fallbackCalls = 0;
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, value) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: value,
        ),
        legacyFallback: (_, __, ___) async {
          fallbackCalls++;
          fallbackStarted.complete();
          await releaseFallback.future;
        },
        isCurrentOccurrence: (_) => isCurrent,
      );

      final dispatch = bridge.dispatch(
        occurrenceId: 'interaction-stale-fallback',
        occurrence: occurrence,
      );
      await fallbackStarted.future;
      isCurrent = false;
      releaseFallback.complete();
      final result = await dispatch;

      expect(result, isA<NarrativeSpatialProductionDispatchStale>());
      expect(fallbackCalls, 1);
    });

    test('invalid ids and non-spatial sources fail before host callbacks',
        () async {
      var authorityCalls = 0;
      var fallbackCalls = 0;
      final bridge = _bridge(
        stateTransactions: NarrativeEventStateTransactions(
          const GameState(saveId: 'save'),
        ),
        currentGameState: () => const GameState(saveId: 'save'),
        onGameStateCommitted: (_) {},
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        legacyFallback: (_, __, ___) async => fallbackCalls++,
      );

      final invalidId = await bridge.dispatch(
        occurrenceId: '  ',
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
        ),
      );
      final invalidSource = await bridge.dispatch(
        occurrenceId: 'map-enter-is-not-spatial',
        occurrence: NarrativeEventOccurrence(
          source: NarrativeEventSourceRef.mapEnter('map'),
        ),
      );

      expect(invalidId, isA<NarrativeSpatialProductionDispatchFailed>());
      expect(invalidSource, isA<NarrativeSpatialProductionDispatchFailed>());
      expect(authorityCalls, 0);
      expect(fallbackCalls, 0);
    });
  });
}

NarrativeSpatialProductionDispatchBridge _bridge({
  required NarrativeEventStateTransactions stateTransactions,
  required GameState Function() currentGameState,
  required void Function(GameState gameState) onGameStateCommitted,
  required Future<NarrativeEventDispatchAuthorityPreparation> Function(
    String occurrenceId,
    NarrativeEventOccurrence occurrence,
  ) prepareAuthority,
  required Future<void> Function(
    String occurrenceId,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) legacyFallback,
  NarrativeSceneExecutionCallback? executeScene,
  bool Function(String occurrenceId)? isCurrentOccurrence,
}) {
  return NarrativeSpatialProductionDispatchBridge(
    stateTransactions: stateTransactions,
    currentGameState: currentGameState,
    onGameStateCommitted: onGameStateCommitted,
    prepareAuthority: prepareAuthority,
    executeScene: executeScene ??
        (request) async => NarrativeSceneExecutionResult.completed(
              updatedGameState: request.gameState,
              qualifiedOutcomes: const [],
            ),
    legacyFallback: legacyFallback,
    activityPort: NoopNarrativeEventActivityPort(),
    isCurrentOccurrence: isCurrentOccurrence ?? (_) => true,
    executionIdFactory: () => _executionId,
    correlationIdFactory: () => _correlationId,
    deliveryIdFactory: () => _deliveryId,
  );
}

NarrativeEventDispatchAuthorityPreparation _prepareAuthority({
  required NarrativeEventRegistry registry,
  required NarrativeEventOccurrence occurrence,
  ValidatedLegacyClaimIndex? legacyClaimIndex,
}) {
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: occurrence,
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: legacyClaimIndex,
    projectCatalog: _catalog(registry, occurrence.source),
  );
}

NarrativeEventRegistry _registry(
  EventSystemMode mode, {
  List<NarrativeEventRecord> records = const [],
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _record(
  NarrativeEventSourceRef source, {
  bool enabled = true,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Spatial event',
      source: source,
      conditions: const [],
      sceneId: 'scene_spatial',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

LegacySourceClaim _claim(
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _legacyFingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt',
  );
}

NarrativeEventProjectCatalog _catalog(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source,
) {
  final spatialOwner = source.when<
      ({
        String mapId,
        MapEntity? entity,
        MapTrigger? trigger,
      })>(
    entityInteract: (mapId, entityId) => (
      mapId: mapId,
      entity: MapEntity(
        id: entityId,
        name: entityId,
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 0, y: 0),
      ),
      trigger: null,
    ),
    triggerEnter: (mapId, triggerId) => (
      mapId: mapId,
      entity: null,
      trigger: MapTrigger(
        id: triggerId,
        name: triggerId,
        type: TriggerType.event,
        area: const MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ),
    mapEnter: (mapId) => (mapId: mapId, entity: null, trigger: null),
    outcomeReceived: (_) => (mapId: 'map', entity: null, trigger: null),
  );
  final sceneIds = {
    for (final record in registry.records)
      if (record.definitionOrNull case final definition?) definition.sceneId,
  };
  final project = ProjectManifest(
    name: 'Spatial bridge fixture',
    maps: [
      ProjectMapEntry(
        id: spatialOwner.mapId,
        name: spatialOwner.mapId,
        relativePath: 'maps/${spatialOwner.mapId}.json',
      ),
    ],
    tilesets: const [],
    eventRegistry: registry,
    scenes: [for (final sceneId in sceneIds) _scene(sceneId)],
  );
  return buildNarrativeEventProjectCatalog(
    project: project,
    maps: [
      MapData(
        id: spatialOwner.mapId,
        name: spatialOwner.mapId,
        size: const GridSize(width: 2, height: 2),
        layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
        entities: [if (spatialOwner.entity case final entity?) entity],
        triggers: [if (spatialOwner.trigger case final trigger?) trigger],
      ),
    ],
  );
}

SceneAsset _scene(String id) {
  return SceneAsset.fromJson({
    'id': id,
    'name': id,
    'graph': const {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}
