import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _entryCount = 10000;
const _warmupIterations = 5;
const _measuredIterations = 20;

// Frozen from the first accepted sequential NSC-74 baseline: build p95 79 µs,
// slowest search p95 51,825 µs. Floors preserve cross-machine headroom.
const _buildP95BudgetMicroseconds = 20000;
const _searchP95BudgetMicroseconds = 220000;

void main() {
  test('10k global search entries keep stable exact accent and fuzzy results',
      () {
    final entries = _entries();

    NarrativeGlobalSearchIndex build() =>
        NarrativeGlobalSearchIndex.fromEntries(
          revision: 74,
          entries: entries,
        );

    for (var index = 0; index < _warmupIterations; index++) {
      build();
    }
    final buildSamples = <int>[];
    NarrativeGlobalSearchIndex? built;
    for (var index = 0; index < _measuredIterations; index++) {
      final stopwatch = Stopwatch()..start();
      built = build();
      stopwatch.stop();
      buildSamples.add(stopwatch.elapsedMicroseconds);
    }
    final searchIndex = built!;

    final queries = <String, NarrativeGlobalSearchQuery>{
      'exact': const NarrativeGlobalSearchQuery(
        text: 'scene_05000',
        limit: 10,
      ),
      'accent': const NarrativeGlobalSearchQuery(
        text: 'selbrume 05000',
        limit: 10,
      ),
      'fuzzy': const NarrativeGlobalSearchQuery(
        text: 'rvl 05000',
        limit: 10,
      ),
    };
    final measurements = <String, ({int p50, int p95})>{};
    final responses = <String, NarrativeGlobalSearchResponse>{};
    for (final entry in queries.entries) {
      for (var index = 0; index < _warmupIterations; index++) {
        searchIndex.search(entry.value);
      }
      final samples = <int>[];
      for (var index = 0; index < _measuredIterations; index++) {
        final stopwatch = Stopwatch()..start();
        responses[entry.key] = searchIndex.search(entry.value);
        stopwatch.stop();
        samples.add(stopwatch.elapsedMicroseconds);
      }
      measurements[entry.key] = _measurement(samples);
    }

    final buildMeasurement = _measurement(buildSamples);
    final checksum = responses.values.fold<int>(
      0,
      (sum, response) =>
          sum +
          int.parse(response.results.single.entry.technicalId.substring(6)),
    );
    stdout.writeln(
      'NSC_74_GLOBAL_SEARCH '
      'os=${Platform.operatingSystem} '
      'os_version=${_singleLine(Platform.operatingSystemVersion)} '
      'dart=${Platform.version.split(' ').first} '
      'processors=${Platform.numberOfProcessors} mode=flutter_test_debug_jit '
      'execution=sequential entries=$_entryCount '
      'warmups=$_warmupIterations iterations=$_measuredIterations '
      'build_p50_us=${buildMeasurement.p50} '
      'build_p95_us=${buildMeasurement.p95} '
      'exact_p50_us=${measurements['exact']!.p50} '
      'exact_p95_us=${measurements['exact']!.p95} '
      'accent_p50_us=${measurements['accent']!.p50} '
      'accent_p95_us=${measurements['accent']!.p95} '
      'fuzzy_p50_us=${measurements['fuzzy']!.p50} '
      'fuzzy_p95_us=${measurements['fuzzy']!.p95} '
      'checksum=$checksum '
      'build_budget_p95_us=$_buildP95BudgetMicroseconds '
      'search_budget_p95_us=$_searchP95BudgetMicroseconds '
      'threshold=frozen',
    );

    expect(searchIndex.entries, hasLength(_entryCount));
    for (final response in responses.values) {
      expect(response.results, hasLength(1));
      expect(response.results.single.entry.technicalId, 'scene_05000');
    }
    expect(checksum, 15000);

    final filtered = searchIndex.search(
      NarrativeGlobalSearchQuery(
        text: '',
        limit: 50,
        filter: NarrativeGlobalSearchFilter(
          kinds: const {NarrativeGlobalSearchKind.scene},
        ),
      ),
    );
    expect(filtered.results, hasLength(50));
    expect(
      filtered.results,
      everyElement(
        isA<NarrativeGlobalSearchResult>().having(
          (result) => result.entry.kind,
          'kind',
          NarrativeGlobalSearchKind.scene,
        ),
      ),
    );
    expect(
      responses['exact']!.isStaleComparedTo(
        NarrativeGlobalSearchIndex.fromEntries(
          revision: 75,
          entries: entries,
        ),
      ),
      isTrue,
    );
    expect(
      buildMeasurement.p95,
      lessThanOrEqualTo(_buildP95BudgetMicroseconds),
    );
    for (final measurement in measurements.values) {
      expect(
        measurement.p95,
        lessThanOrEqualTo(_searchP95BudgetMicroseconds),
      );
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}

List<NarrativeGlobalSearchEntry> _entries() => <NarrativeGlobalSearchEntry>[
      for (var index = 0; index < _entryCount; index++)
        NarrativeGlobalSearchEntry(
          kind: NarrativeGlobalSearchKind
              .values[index % NarrativeGlobalSearchKind.values.length],
          technicalId: 'scene_${index.toString().padLeft(5, '0')}',
          label: 'Port Selbrumé rival ${index.toString().padLeft(5, '0')}',
          description: 'Entrée narrative ${index.toString().padLeft(5, '0')}',
          tags: const <String>['harbor', 'brume'],
          keywords: const <String>['rival', 'port'],
        ),
    ];

({int p50, int p95}) _measurement(List<int> samples) {
  final sorted = [...samples]..sort();
  return (
    p50: sorted[(sorted.length * .50).ceil() - 1],
    p95: sorted[(sorted.length * .95).ceil() - 1],
  );
}

String _singleLine(String value) => value.replaceAll(RegExp(r'\s+'), '_');
