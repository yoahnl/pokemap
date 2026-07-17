import 'dart:async';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/f1_runtime_catalog_fixture.dart';

const _fingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _correlationId = 'corr_019abcde-0000-7000-8000-000000000001';

void main() {
  test(
    'prints Phase F1 planner progress and outbox performance evidence',
    () async {
      _emit(
        'PERF_ENV machine=${Platform.localHostname} '
        'os=${Platform.operatingSystem}-${Platform.operatingSystemVersion} '
        'dart=${Platform.version.replaceAll('\n', ' ')} '
        'flutter=not-loaded(pure-dart-package) runtime_mode=JIT',
      );

      for (final volume in [1, 100, 1000, 10000]) {
        _measurePlannerCase(
          caseName: 'one_source',
          volume: volume,
          fixture: _plannerFixture(volume, _PlannerCase.oneSource),
          complexity: 'O(1)-indexed-first-eligible',
          mode: 'v2Only',
        );
        _measurePlannerCase(
          caseName: 'multiple_sources',
          volume: volume,
          fixture: _plannerFixture(volume, _PlannerCase.multipleSources),
          complexity: 'O(1)-indexed-source-bucket-first-eligible',
          mode: 'v2Only',
        );
        _measurePlannerCase(
          caseName: 'conditions_all_true',
          volume: volume,
          fixture: _plannerFixture(volume, _PlannerCase.conditionsAllTrue),
          complexity: 'O(c)-first-candidate-conditions',
          mode: 'v2Only',
        );
        _measurePlannerCase(
          caseName: 'first_condition_false',
          volume: volume,
          fixture: _plannerFixture(volume, _PlannerCase.firstConditionFalse),
          complexity: 'O(n*c)-eligible-scan',
          mode: 'v2Only',
        );
        _measurePlannerCase(
          caseName: 'one_shot_consumed',
          volume: volume,
          fixture: _plannerFixture(volume, _PlannerCase.oneShotConsumed),
          complexity: 'O(n)-eligible-scan',
          mode: 'v2Only',
        );
        _measurePlannerCase(
          caseName: 'claim_valid',
          volume: volume,
          fixture: _plannerFixture(volume, _PlannerCase.claimValid),
          complexity: 'O(1)-claim-lookup-and-first-eligible',
          mode: 'dualRead-valid-claim',
        );
        _measurePlannerCase(
          caseName: 'tombstone_local',
          volume: volume,
          fixture: _plannerFixture(volume, _PlannerCase.tombstoneLocal),
          complexity: 'O(1)-local-claim-lookup',
          mode: 'dualRead-local-tombstone',
        );
      }

      for (final volume in [0, 100, 10000]) {
        _measureProgressCodec(
          dimension: 'consumed',
          volume: volume,
          progress: NarrativeEventProgress(
            consumedNarrativeEventIds: [
              for (var index = 0; index < volume; index++) _eventId(index),
            ],
          ),
          approximateBytes: volume * 80,
        );
        _measureProgressCodec(
          dimension: 'pending',
          volume: volume,
          progress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: [
              for (var index = 0; index < volume; index++) _delivery(index),
            ],
          ),
          approximateBytes: volume * 256,
        );
      }

      for (final volume in [1, 100, 10000]) {
        final stats = await _benchmarkAsync(
          () async {
            final pending = [
              for (var index = 0; index < volume; index++) _delivery(index),
            ];
            final transactions = NarrativeEventStateTransactions(
              GameState(
                saveId: 'performance',
                narrativeEventProgress: NarrativeEventProgress(
                  pendingNarrativeOutcomeDeliveries: pending,
                ),
              ),
            );
            final processor = NarrativeOutcomeOutboxProcessor(
              activityPort: NoopNarrativeEventActivityPort(),
              stateTransactions: transactions,
              dispatcher: (request) async =>
                  NarrativeOutcomeDispatchResult.delivered(
                updatedGameState: request.gameState,
              ),
              deliveryIdFactory: () => _deliveryId(volume + 1),
            );
            final result = await processor.processNext();
            expect(result, isA<NarrativeOutcomeOutboxDelivered>());
          },
          warmup: 1,
          iterations: 7,
        );
        _emitStats(
          component: 'outbox_processor',
          caseName: 'one_fifo_head',
          volume: volume,
          stats: stats,
          mode: 'JIT-shared-transaction-noop-activity',
          complexity: 'O(n)-immutable-queue-replacement',
          approximateBytes: volume * 256,
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

enum _PlannerCase {
  oneSource,
  multipleSources,
  conditionsAllTrue,
  firstConditionFalse,
  oneShotConsumed,
  claimValid,
  tombstoneLocal,
}

final class _PlannerFixture {
  const _PlannerFixture({
    required this.authority,
    required this.gameState,
    required this.expectedType,
  });

  final NarrativeEventDispatchAuthorityReady authority;
  final GameState gameState;
  final Type expectedType;
}

_PlannerFixture _plannerFixture(int volume, _PlannerCase plannerCase) {
  final source = NarrativeEventSourceRef.mapEnter('performance');
  final otherSource = NarrativeEventSourceRef.mapEnter('other');
  final conditions = switch (plannerCase) {
    _PlannerCase.conditionsAllTrue => [
        NarrativeEventCondition.fact('fact_gate', true)
      ],
    _PlannerCase.firstConditionFalse => [
        NarrativeEventCondition.fact('fact_gate', false)
      ],
    _ => const <NarrativeEventCondition>[],
  };
  final records = [
    for (var index = 0; index < volume; index++)
      _record(
        _eventId(index),
        plannerCase == _PlannerCase.multipleSources && index.isOdd
            ? otherSource
            : source,
        conditions: conditions,
      ),
  ];
  final mode = plannerCase == _PlannerCase.claimValid ||
          plannerCase == _PlannerCase.tombstoneLocal
      ? EventSystemMode.dualRead
      : EventSystemMode.v2Only;
  LegacySourceRef? provenance;
  ValidatedLegacyClaimIndex? claimIndex;
  final claims = <LegacySourceClaim>[];
  if (mode == EventSystemMode.dualRead) {
    provenance = LegacySourceRef.mapEvent('performance', 'legacy');
    final targetId = plannerCase == _PlannerCase.claimValid
        ? _eventId(0)
        : _eventId(volume + 10);
    claims.add(_claim(source, provenance, targetId));
  }
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records,
    legacyClaims: claims,
  );
  if (mode == EventSystemMode.dualRead) {
    claimIndex = buildRuntimeValidatedLegacyClaimIndex(
      registry,
      runtimeEvidence: LegacyClaimRuntimeEvidence(
        entries: [
          LegacyClaimRuntimeEvidenceEntry(
            provenance: provenance!,
            source: source,
            sourceFingerprint: _fingerprint,
          ),
        ],
      ),
    );
  }
  final consumed = plannerCase == _PlannerCase.oneShotConsumed
      ? {for (var index = 0; index < volume; index++) _eventId(index)}
      : const <String>{};
  final gameState = GameState(
    saveId: 'performance',
    narrativeEventProgress: NarrativeEventProgress(
      consumedNarrativeEventIds: consumed,
    ),
  );
  final preparation = NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: NarrativeEventOccurrence(
      source: source,
      provenance: provenance,
    ),
    factResolver: NarrativeFactRuntimeResolver.fromFacts([
      NarrativeFactDefinition(
        id: 'fact_gate',
        label: 'Gate',
        defaultValue: true,
      ),
    ]),
    legacyClaimIndex: claimIndex,
    projectCatalog: f1ProjectCatalogForRegistry(registry),
  );
  expect(preparation, isA<NarrativeEventDispatchAuthorityReady>());
  final expectedType = switch (plannerCase) {
    _PlannerCase.firstConditionFalse ||
    _PlannerCase.oneShotConsumed =>
      NarrativeEventDispatchNoMatch,
    _PlannerCase.tombstoneLocal => NarrativeEventDispatchClaimedButIneligible,
    _ => NarrativeEventDispatchHandled,
  };
  return _PlannerFixture(
    authority: preparation as NarrativeEventDispatchAuthorityReady,
    gameState: gameState,
    expectedType: expectedType,
  );
}

void _measurePlannerCase({
  required String caseName,
  required int volume,
  required _PlannerFixture fixture,
  required String complexity,
  required String mode,
}) {
  final planner = NarrativeEventDispatchPlanner();
  final first = planner.plan(
    authority: fixture.authority,
    gameState: fixture.gameState,
  );
  expect(first.runtimeType, fixture.expectedType);
  final operationsPerSample = volume <= 100 ? 20 : 1;
  final stats = _benchmarkSync(
    () {
      for (var operation = 0; operation < operationsPerSample; operation++) {
        planner.plan(
          authority: fixture.authority,
          gameState: fixture.gameState,
        );
      }
    },
    warmup: 2,
    iterations: 9,
    operationsPerSample: operationsPerSample,
  );
  _emitStats(
    component: 'planner',
    caseName: caseName,
    volume: volume,
    stats: stats,
    mode: mode,
    complexity: complexity,
    approximateBytes: volume * 256,
  );
}

void _measureProgressCodec({
  required String dimension,
  required int volume,
  required NarrativeEventProgress progress,
  required int approximateBytes,
}) {
  final stats = _benchmarkSync(
    () {
      final decoded = NarrativeEventProgress.fromJson(progress.toJson());
      expect(decoded, progress);
    },
    warmup: 1,
    iterations: 7,
  );
  _emitStats(
    component: 'progress_codec',
    caseName: dimension,
    volume: volume,
    stats: stats,
    mode: 'JIT-strict-round-trip',
    complexity: 'O(n)-encode-decode-validation',
    approximateBytes: approximateBytes,
  );
}

NarrativeEventRecord _record(
  String id,
  NarrativeEventSourceRef source, {
  List<NarrativeEventCondition> conditions = const [],
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: conditions,
      sceneId: 'scene',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: true,
  );
}

LegacySourceClaim _claim(
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
  String targetId,
) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _fingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: [targetId],
    migrationReceiptId: 'performance',
  );
}

NarrativeOutcomeDelivery _delivery(int index) {
  return NarrativeOutcomeDelivery(
    deliveryId: _deliveryId(index),
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'scene',
      outcomeId: 'complete',
    ),
    rootCorrelationId: _correlationId,
    depth: 0,
    attemptCount: 0,
  );
}

String _eventId(int index) {
  return 'evt_019abcde-0000-7000-8000-'
      '${(index + 1).toRadixString(16).padLeft(12, '0')}';
}

String _deliveryId(int index) {
  return 'outd_019abcde-0000-7000-8000-'
      '${(index + 1).toRadixString(16).padLeft(12, '0')}';
}

final class _TimingStats {
  const _TimingStats({
    required this.meanMicroseconds,
    required this.medianMicroseconds,
    required this.p95Microseconds,
    required this.iterations,
    required this.warmup,
  });

  final double meanMicroseconds;
  final double medianMicroseconds;
  final double p95Microseconds;
  final int iterations;
  final int warmup;
}

_TimingStats _benchmarkSync(
  void Function() action, {
  required int warmup,
  required int iterations,
  int operationsPerSample = 1,
}) {
  for (var index = 0; index < warmup; index++) {
    action();
  }
  final samples = <double>[];
  for (var index = 0; index < iterations; index++) {
    final stopwatch = Stopwatch()..start();
    action();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds / operationsPerSample);
  }
  return _stats(samples, warmup);
}

Future<_TimingStats> _benchmarkAsync(
  Future<void> Function() action, {
  required int warmup,
  required int iterations,
}) async {
  for (var index = 0; index < warmup; index++) {
    await action();
  }
  final samples = <double>[];
  for (var index = 0; index < iterations; index++) {
    final stopwatch = Stopwatch()..start();
    await action();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds.toDouble());
  }
  return _stats(samples, warmup);
}

_TimingStats _stats(List<double> samples, int warmup) {
  final sorted = [...samples]..sort();
  final mean = samples.reduce((left, right) => left + right) / samples.length;
  final median = sorted.length.isOdd
      ? sorted[sorted.length ~/ 2]
      : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
  final p95Index = (sorted.length * 0.95).ceil() - 1;
  return _TimingStats(
    meanMicroseconds: mean,
    medianMicroseconds: median,
    p95Microseconds: sorted[p95Index],
    iterations: samples.length,
    warmup: warmup,
  );
}

void _emitStats({
  required String component,
  required String caseName,
  required int volume,
  required _TimingStats stats,
  required String mode,
  required String complexity,
  required int approximateBytes,
}) {
  _emit(
    'PERF component=$component case=$caseName volume=$volume '
    'mean_us=${stats.meanMicroseconds.toStringAsFixed(2)} '
    'median_us=${stats.medianMicroseconds.toStringAsFixed(2)} '
    'p50_us=${stats.medianMicroseconds.toStringAsFixed(2)} '
    'p95_us=${stats.p95Microseconds.toStringAsFixed(2)} '
    'iterations=${stats.iterations} warmup=${stats.warmup} mode=$mode '
    'complexity=$complexity approx_memory=estimated:${approximateBytes}B',
  );
}

void _emit(String value) {
  Zone.current.print(value);
}
