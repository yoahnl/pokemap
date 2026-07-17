import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  test('NS-EVENT-V2 Phase E authoring performance measurements', () {
    stdout.writeln(
      'NS_EVENT_V2_PHASE_E_PERF_ENV os=${Platform.operatingSystem} '
      'os_version=${Platform.operatingSystemVersion.replaceAll(' ', '_')} '
      'dart=${Platform.version.split(' ').first} mode=jit aot=not_measured '
      'catalog_build=excluded warmup=1 hashing=operation_internal',
    );
    for (final volume in [10, 1000, 10000]) {
      final iterations = switch (volume) {
        10 => 15,
        1000 => 7,
        _ => 3,
      };
      final ids = [
        for (var index = 0; index < volume; index++) _eventId(index)
      ];
      final configuredRecords = [
        for (var index = 0; index < volume; index++)
          configuredRecord(id: ids[index], order: index),
      ];
      final configuredRegistry = registryWithRecords(configuredRecords);
      final draftCreationContext = configuredAuthoringContext(
        registry: configuredRegistry,
      );
      NarrativeEventAuthoringResult? draftResult;
      _measure(
        'draft_create',
        volume,
        iterations,
        () {
          draftResult = createNarrativeEventDraft(
            context: draftCreationContext,
            expectedRevision: authoringRevision,
            name: 'Benchmark draft',
            idGenerator: deterministicGenerator(_eventId(volume)),
          );
        },
      );
      expect(draftResult?.status, NarrativeEventAuthoringStatus.applied);

      final sourceRecords = <NarrativeEventRecord>[
        draftRecord(id: ids.first, source: triggerSource),
        ...configuredRecords.skip(1),
      ];
      final sourceContext = configuredAuthoringContext(
        registry: registryWithRecords(sourceRecords),
      );
      NarrativeEventAuthoringResult? sourceResult;
      _measure(
        'source_replace',
        volume,
        iterations,
        () {
          sourceResult = replaceNarrativeEventSource(
            context: sourceContext,
            expectedRevision: authoringRevision,
            eventId: ids.first,
            source: entitySource,
          );
        },
      );
      expect(sourceResult?.status, NarrativeEventAuthoringStatus.applied);

      final graphRecords = <NarrativeEventRecord>[
        configuredRecord(id: ids.first),
        for (var index = 1; index < volume; index++)
          configuredRecord(
            id: ids[index],
            conditions: [
              NarrativeEventCondition.narrativeEventConsumed(
                ids[index - 1],
                true,
              ),
            ],
          ),
      ];
      final graphContext = configuredAuthoringContext(
        registry: registryWithRecords(graphRecords),
      );
      NarrativeEventAuthoringResult? graphResult;
      _measure(
        'condition_graph_cycle_validation',
        volume,
        iterations,
        () {
          graphResult = setNarrativeEventConditions(
            context: graphContext,
            expectedRevision: authoringRevision,
            eventId: ids.first,
            conditions: [
              NarrativeEventCondition.narrativeEventConsumed(ids.last, true),
            ],
          );
        },
      );
      expect(graphResult?.rejectionCode, 'eventDependencyCycle');

      final publishRecords = <NarrativeEventRecord>[
        draftRecord(
          id: ids.first,
          source: entitySource,
          conditions: [NarrativeEventCondition.fact('fact_a', true)],
          sceneId: 'scene_a',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
        ),
        ...configuredRecords.skip(1),
      ];
      final publishContext = configuredAuthoringContext(
        registry: registryWithRecords(publishRecords),
      );
      NarrativeEventAuthoringResult? publicationResult;
      _measure(
        'publication',
        volume,
        iterations,
        () {
          publicationResult = publishNarrativeEvent(
            context: publishContext,
            expectedRevision: authoringRevision,
            eventId: ids.first,
          );
        },
      );
      expect(publicationResult?.status, NarrativeEventAuthoringStatus.applied);

      final activationRecords = <NarrativeEventRecord>[
        configuredRecord(id: ids.first),
        for (var index = 1; index < volume; index++)
          configuredRecord(
            id: ids[index],
            order: index,
            enabled: true,
          ),
      ];
      final activationContext = configuredAuthoringContext(
        registry: registryWithRecords(activationRecords),
      );
      NarrativeEventAuthoringResult? activationResult;
      _measure(
        'activation_conflict_lookup',
        volume,
        iterations,
        () {
          activationResult = activateNarrativeEvent(
            context: activationContext,
            expectedRevision: authoringRevision,
            eventId: ids.first,
          );
        },
      );
      expect(activationResult?.status, NarrativeEventAuthoringStatus.applied);

      final rawRoot = <String, Object?>{
        'name': 'Benchmark',
        'eventRegistry': configuredRegistry.toJson(),
        'futureRoot': {
          'preserve': true,
          'values': [1, 2, 3],
        },
      };
      List<int>? patchedBytes;
      _measure(
        'registry_json_patch',
        volume,
        iterations,
        () {
          final patchedRoot = Map<String, Object?>.from(rawRoot)
            ..['eventRegistry'] = sourceResult!.nextRegistry!.toJson();
          patchedBytes = canonicalizeNarrativeEventJsonUtf8(patchedRoot);
        },
      );
      expect(patchedBytes, isNotEmpty);
    }
  });
}

String _eventId(int index) {
  return 'evt_019abcde-0000-7000-8000-${index.toString().padLeft(12, '0')}';
}

void _measure(
  String operation,
  int volume,
  int iterations,
  void Function() run,
) {
  run();
  final samples = <int>[];
  for (var iteration = 0; iteration < iterations; iteration++) {
    final stopwatch = Stopwatch()..start();
    run();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  final total = samples.fold<int>(0, (sum, value) => sum + value);
  final mean = total / samples.length;
  final median = samples.length.isOdd
      ? samples[samples.length ~/ 2].toDouble()
      : (samples[samples.length ~/ 2 - 1] + samples[samples.length ~/ 2]) / 2;
  final p50 = median;
  final p95Index = (samples.length * 0.95).ceil() - 1;
  final p95 = samples[p95Index];
  stdout.writeln(
    'NS_EVENT_V2_PHASE_E_PERF operation=$operation records=$volume '
    'iterations=$iterations mean_us=${mean.toStringAsFixed(1)} '
    'median_us=${median.toStringAsFixed(1)} '
    'p50_us=${p50.toStringAsFixed(1)} '
    'p95_us=${p95.toStringAsFixed(1)} mode=jit '
    'catalog_build=excluded hashing=operation_internal '
    'complexity=operation_specific aot=not_measured',
  );
}
