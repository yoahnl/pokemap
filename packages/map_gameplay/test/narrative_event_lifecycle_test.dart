import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _executionA = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationA = 'corr_019abcde-0000-7000-8000-000000000003';
const _deliveryA = 'outd_019abcde-0000-7000-8000-000000000004';

void main() {
  test('wraps planning and Scene callback in ordered activities', () async {
    final activity = _RecordingActivityPort();
    final coordinator = _coordinator(
      activityPort: activity,
      executeScene: (request) async {
        expect(activity.active, [
          NarrativeEventActivity.dispatching,
          NarrativeEventActivity.sceneActive,
        ]);
        return NarrativeSceneExecutionResult.completed(
          updatedGameState: request.gameState,
          qualifiedOutcomes: const [],
        );
      },
    );

    await coordinator.execute(authority: _authority());

    expect(activity.entries, [
      NarrativeEventActivity.dispatching,
      NarrativeEventActivity.sceneActive,
    ]);
    expect(activity.active, isEmpty);
  });

  test('noMatch and claimedButIneligible never execute Scene callback',
      () async {
    for (final authority in [_emptyAuthority(false), _emptyAuthority(true)]) {
      var callbacks = 0;
      final coordinator = _coordinator(
        executeScene: (_) async {
          callbacks++;
          throw StateError('must not run');
        },
      );

      final result = await coordinator.execute(authority: authority);

      expect(callbacks, 0);
      expect(
        result,
        authority.mode == EventSystemMode.v2Only
            ? isA<NarrativeEventExecutionNoMatch>()
            : isA<NarrativeEventExecutionClaimedButIneligible>(),
      );
    }
  });

  test('callback exception becomes typed failure and runs exactly once',
      () async {
    var callbacks = 0;
    final coordinator = _coordinator(
      executeScene: (_) async {
        callbacks++;
        throw StateError('scene exploded');
      },
    );

    final result = await coordinator.execute(authority: _authority());

    expect(callbacks, 1);
    expect(result, isA<NarrativeEventExecutionFailed>());
    expect(
      (result as NarrativeEventExecutionFailed).failure.kind,
      NarrativeEventExecutionFailureKind.sceneCallbackException,
    );
  });

  test('no-op activity port supports every activity without dependencies',
      () async {
    final port = NoopNarrativeEventActivityPort();

    for (final activity in NarrativeEventActivity.values) {
      expect(
          await port.runWithActivity(activity, () async => activity), activity);
    }
  });
}

NarrativeEventExecutionCoordinator _coordinator({
  required NarrativeSceneExecutionCallback executeScene,
  NarrativeEventActivityPort? activityPort,
}) {
  return NarrativeEventExecutionCoordinator(
    stateTransactions:
        NarrativeEventStateTransactions(const GameState(saveId: 'save')),
    planner: NarrativeEventDispatchPlanner(),
    executeScene: executeScene,
    activityPort: activityPort ?? NoopNarrativeEventActivityPort(),
    executionIdFactory: () => _executionA,
    correlationIdFactory: () => _correlationA,
    deliveryIdFactory: () => _deliveryA,
  );
}

NarrativeEventDispatchAuthorityReady _authority() {
  final source = NarrativeEventSourceRef.mapEnter('map');
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _eventA,
          name: _eventA,
          source: source,
          conditions: const [],
          sceneId: 'scene',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const [],
  );
  return _prepare(registry, source);
}

NarrativeEventDispatchAuthorityReady _emptyAuthority(bool claimed) {
  final source = NarrativeEventSourceRef.mapEnter('map');
  if (!claimed) {
    return _prepare(
      NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: const [],
        legacyClaims: const [],
      ),
      source,
    );
  }
  const fingerprint =
      'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  final provenance = LegacySourceRef.mapEvent('map', 'legacy');
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: fingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: const [],
    legacyClaims: [
      LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: [member],
        cohortFingerprint:
            computeLegacySourceCohortFingerprint(cohortId, [member]),
        targetEventIds: const [_eventA],
        migrationReceiptId: 'receipt',
      ),
    ],
  );
  final index = buildRuntimeValidatedLegacyClaimIndex(
    registry,
    runtimeEvidence: LegacyClaimRuntimeEvidence(
      entries: [
        LegacyClaimRuntimeEvidenceEntry(
          provenance: provenance,
          source: source,
          sourceFingerprint: fingerprint,
        ),
      ],
    ),
  );
  return _prepare(
    registry,
    source,
    provenance: provenance,
    claimIndex: index,
  );
}

NarrativeEventDispatchAuthorityReady _prepare(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source, {
  LegacySourceRef? provenance,
  ValidatedLegacyClaimIndex? claimIndex,
}) {
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence:
        NarrativeEventOccurrence(source: source, provenance: provenance),
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: claimIndex,
    projectCatalog: f1ProjectCatalogForRegistry(registry),
  ) as NarrativeEventDispatchAuthorityReady;
}

final class _RecordingActivityPort implements NarrativeEventActivityPort {
  final List<NarrativeEventActivity> entries = [];
  final List<NarrativeEventActivity> active = [];

  @override
  Future<T> runWithActivity<T>(
    NarrativeEventActivity activity,
    Future<T> Function() action,
  ) async {
    entries.add(activity);
    active.add(activity);
    try {
      return await action();
    } finally {
      active.removeLast();
    }
  }
}
