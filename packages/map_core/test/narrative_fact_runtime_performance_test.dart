import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Object? _benchmarkSink;

void main() {
  test('NS-EVENT-V2 F1-PREREQ performance measurements', () {
    stdout.writeln(
      'NS_EVENT_V2_F1_PREREQ_PERF_ENV os=${Platform.operatingSystem} '
      'os_version=${Platform.operatingSystemVersion.replaceAll(' ', '_')} '
      'dart=${Platform.version.split(' ').first} mode=jit aot=not_measured '
      'processors=${Platform.numberOfProcessors}',
    );
    _measureResolver();
    _measureSaveCodec();
    _measureClaimIndex();
  });
}

void _measureResolver() {
  for (final volume in const [1, 100, 1000, 10000]) {
    final facts = [
      for (var index = 0; index < volume; index++)
        NarrativeFactDefinition(
          id: _factId(index),
          label: 'Fact $index',
          defaultValue: index.isEven,
          legacyFlagName: _legacyFlag(index),
        ),
    ];
    final target = facts.last;
    final resolver = NarrativeFactRuntimeResolver.fromFacts(facts);
    final overrideState = NarrativeFactRuntimeState(
      overridesByFactId: {target.id: false},
    );
    final aliasFlags = StoryFlags(activeFlags: {_legacyFlag(volume - 1)});

    _measure(
      operation: 'resolver_override_hit',
      volume: volume,
      iterations: 30,
      batchSize: 1000,
      complexity: 'O(1)_lookup_after_O(n)_index',
      run: () {
        _benchmarkSink = resolver.resolve(
          factId: target.id,
          runtimeState: overrideState,
          storyFlags: aliasFlags,
        );
      },
    );
    expect(
      (_benchmarkSink as NarrativeFactRuntimeResolved).source,
      NarrativeFactRuntimeValueSource.explicitOverride,
    );

    _measure(
      operation: 'resolver_alias_hit',
      volume: volume,
      iterations: 30,
      batchSize: 1000,
      complexity: 'O(1)_lookup_after_O(n)_index',
      run: () {
        _benchmarkSink = resolver.resolve(
          factId: target.id,
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: aliasFlags,
        );
      },
    );
    expect(
      (_benchmarkSink as NarrativeFactRuntimeResolved).source,
      NarrativeFactRuntimeValueSource.legacyStoryFlag,
    );

    _measure(
      operation: 'resolver_default_fallback',
      volume: volume,
      iterations: 30,
      batchSize: 1000,
      complexity: 'O(1)_lookup_after_O(n)_index',
      run: () {
        _benchmarkSink = resolver.resolve(
          factId: target.id,
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        );
      },
    );
    expect(
      (_benchmarkSink as NarrativeFactRuntimeResolved).source,
      NarrativeFactRuntimeValueSource.defaultValue,
    );

    _measure(
      operation: 'resolver_absent',
      volume: volume,
      iterations: 30,
      batchSize: 1000,
      complexity: 'O(1)_lookup_after_O(n)_index',
      run: () {
        _benchmarkSink = resolver.resolve(
          factId: 'fact_absent',
          runtimeState: const NarrativeFactRuntimeState.empty(),
          storyFlags: const StoryFlags(),
        );
      },
    );
    expect(_benchmarkSink, isA<NarrativeFactRuntimeUnknownFact>());
  }
}

void _measureSaveCodec() {
  for (final volume in const [0, 100, 10000]) {
    final state = NarrativeFactRuntimeState(
      overridesByFactId: {
        for (var index = 0; index < volume; index++)
          _factId(index): index.isEven,
      },
    );
    final iterations = switch (volume) {
      0 => 30,
      100 => 20,
      _ => 7,
    };
    final batchSize = switch (volume) {
      0 => 100,
      100 => 10,
      _ => 1,
    };
    _measure(
      operation: 'save_codec_roundtrip',
      volume: volume,
      iterations: iterations,
      batchSize: batchSize,
      complexity: 'O(k_log_k)_decode_plus_O(k)_encode',
      run: () {
        _benchmarkSink = NarrativeFactRuntimeState.fromJson(state.toJson());
      },
    );
    expect(_benchmarkSink, state);
  }
}

void _measureClaimIndex() {
  for (final volume in const [0, 100, 10000]) {
    final corpus = _claimCorpus(volume);
    ValidatedLegacyClaimIndex? index;
    _measure(
      operation: 'claim_index_valid',
      volume: volume,
      iterations: volume == 10000 ? 7 : 20,
      batchSize: volume == 0 ? 20 : 1,
      complexity: 'O(records_plus_claims_plus_targets)',
      run: () {
        index = buildRuntimeValidatedLegacyClaimIndex(
          corpus.registry,
          runtimeEvidence: corpus.runtimeEvidence,
        );
        _benchmarkSink = index;
      },
    );
    expect(index?.canEnterDualRead, isTrue);
    expect(index?.canRunDualRead, isTrue);

    if (volume != 10000) {
      continue;
    }

    final tombstoneRegistry = NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: corpus.registry.records.take(volume - 1).toList(),
      legacyClaims: corpus.registry.legacyClaims,
    );
    _measure(
      operation: 'claim_index_local_tombstone',
      volume: volume,
      iterations: 7,
      batchSize: 1,
      complexity: 'O(records_plus_claims_plus_targets)',
      run: () {
        index = buildRuntimeValidatedLegacyClaimIndex(
          tombstoneRegistry,
          runtimeEvidence: corpus.runtimeEvidence,
        );
        _benchmarkSink = index;
      },
    );
    expect(index?.canEnterDualRead, isFalse);
    expect(index?.canRunDualRead, isTrue);
    expect(
      index?.resolveSource(corpus.lastSource),
      isA<LegacyClaimSourceTombstone>(),
    );

    final collisionRegistry = NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: corpus.registry.records,
      legacyClaims: [
        ...corpus.registry.legacyClaims,
        corpus.registry.legacyClaims.last,
      ],
    );
    _measure(
      operation: 'claim_index_global_collision',
      volume: volume,
      iterations: 7,
      batchSize: 1,
      complexity: 'O(records_plus_claims_plus_targets_plus_conflict_sort)',
      run: () {
        index = buildRuntimeValidatedLegacyClaimIndex(
          collisionRegistry,
          runtimeEvidence: corpus.runtimeEvidence,
        );
        _benchmarkSink = index;
      },
    );
    expect(index?.canEnterDualRead, isFalse);
    expect(index?.canRunDualRead, isFalse);
  }
}

({
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef lastSource,
  LegacyClaimRuntimeEvidence runtimeEvidence,
}) _claimCorpus(int volume) {
  final records = <NarrativeEventRecord>[];
  final claims = <LegacySourceClaim>[];
  final evidenceEntries = <LegacyClaimRuntimeEvidenceEntry>[];
  NarrativeEventSourceRef lastSource =
      NarrativeEventSourceRef.mapEnter('map_empty');
  for (var index = 0; index < volume; index++) {
    final source = NarrativeEventSourceRef.mapEnter(_mapId(index));
    final provenance = LegacySourceRef.mapEvent(
      _mapId(index),
      'legacy_${index.toString().padLeft(5, '0')}',
    );
    final member = LegacySourceClaimMember(
      provenance: provenance,
      sourceFingerprint:
          'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    final cohortId = computeLegacySourceCohortId(source, [provenance]);
    final eventId = _eventId(index);
    records.add(
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: eventId,
          name: eventId,
          source: source,
          conditions: const [],
          sceneId: 'scene',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: index,
        ),
        enabled: true,
      ),
    );
    claims.add(
      LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: [member],
        cohortFingerprint: computeLegacySourceCohortFingerprint(
          cohortId,
          [member],
        ),
        targetEventIds: [eventId],
        migrationReceiptId: 'receipt_$index',
      ),
    );
    evidenceEntries.add(
      LegacyClaimRuntimeEvidenceEntry(
        provenance: provenance,
        source: source,
        sourceFingerprint: member.sourceFingerprint,
      ),
    );
    lastSource = source;
  }
  return (
    registry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: records,
      legacyClaims: claims,
    ),
    lastSource: lastSource,
    runtimeEvidence: LegacyClaimRuntimeEvidence(entries: evidenceEntries),
  );
}

String _factId(int index) => 'fact_${index.toString().padLeft(5, '0')}';

String _legacyFlag(int index) =>
    'legacy_fact_${index.toString().padLeft(5, '0')}';

String _mapId(int index) => 'map_${index.toString().padLeft(5, '0')}';

String _eventId(int index) {
  return 'evt_019abcde-0000-7000-8000-${index.toString().padLeft(12, '0')}';
}

void _measure({
  required String operation,
  required int volume,
  required int iterations,
  required int batchSize,
  required String complexity,
  required void Function() run,
}) {
  for (var index = 0; index < batchSize; index++) {
    run();
  }
  final samples = <double>[];
  for (var iteration = 0; iteration < iterations; iteration++) {
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < batchSize; index++) {
      run();
    }
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds / batchSize);
  }
  samples.sort();
  final mean =
      samples.fold<double>(0, (sum, value) => sum + value) / samples.length;
  final median = samples.length.isOdd
      ? samples[samples.length ~/ 2]
      : (samples[samples.length ~/ 2 - 1] + samples[samples.length ~/ 2]) / 2;
  final p95Index =
      ((samples.length * 0.95).ceil() - 1).clamp(0, samples.length - 1);
  stdout.writeln(
    'NS_EVENT_V2_F1_PREREQ_PERF operation=$operation volume=$volume '
    'iterations=$iterations batch=$batchSize '
    'mean_us=${mean.toStringAsFixed(3)} '
    'median_us=${median.toStringAsFixed(3)} '
    'p95_us=${samples[p95Index].toStringAsFixed(3)} mode=jit '
    'complexity=$complexity aot=not_measured',
  );
}
