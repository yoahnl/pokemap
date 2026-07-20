import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _entryCount = 10000;
const _warmupIterations = 5;
const _measuredIterations = 20;

// Frozen from the first accepted sequential NSC-74 baseline (p95: 19,468 µs).
const _buildP95BudgetMicroseconds = 80000;

void main() {
  test('10k dependency index stays deterministic within its frozen budget', () {
    final project = _project();

    NarrativeDependencyIndex run() =>
        buildNarrativeDependencyIndex(project: project);

    for (var index = 0; index < _warmupIterations; index++) {
      run();
    }
    final samples = <int>[];
    NarrativeDependencyIndex? last;
    for (var index = 0; index < _measuredIterations; index++) {
      final stopwatch = Stopwatch()..start();
      last = run();
      stopwatch.stop();
      samples.add(stopwatch.elapsedMicroseconds);
    }

    final measurement = _measurement(samples);
    final result = last!;
    final checksum = _checksum(result);
    stdout.writeln(
      'NSC_74_DEPENDENCY_INDEX '
      'os=${Platform.operatingSystem} '
      'os_version=${_singleLine(Platform.operatingSystemVersion)} '
      'dart=${Platform.version.split(' ').first} '
      'processors=${Platform.numberOfProcessors} mode=jit '
      'execution=sequential entries=$_entryCount '
      'warmups=$_warmupIterations iterations=$_measuredIterations '
      'p50_us=${measurement.p50} p95_us=${measurement.p95} '
      'checksum=$checksum budget_p95_us=$_buildP95BudgetMicroseconds '
      'threshold=frozen',
    );

    expect(result.definitions, hasLength(_entryCount));
    expect(result.usages, isEmpty);
    expect(result.issues, isEmpty);
    expect(
      result
          .definitionsFor(
            const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.fact,
              'fact_00000',
            ),
          )
          .single
          .label,
      'Fact 00000',
    );
    expect(
      result
          .definitionsFor(
            const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.fact,
              'fact_09999',
            ),
          )
          .single
          .label,
      'Fact 09999',
    );
    expect(checksum, 49995000);
    expect(measurement.p95, lessThanOrEqualTo(_buildP95BudgetMicroseconds));
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('one local mutation preserves unrelated dependency readings', () {
    final before = buildNarrativeDependencyIndex(project: _project());
    final after = buildNarrativeDependencyIndex(
      project: _project(renamedIndex: 5000),
    );

    const changed = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.fact,
      'fact_05000',
    );
    const untouched = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.fact,
      'fact_07500',
    );

    expect(before.definitionsFor(changed).single.label, 'Fact 05000');
    expect(after.definitionsFor(changed).single.label, 'Renamed Fact 05000');
    expect(
      _definitionSignature(before.definitionsFor(untouched).single),
      _definitionSignature(after.definitionsFor(untouched).single),
    );
    expect(after.usagesFor(untouched), isEmpty);
    expect(_checksum(before), _checksum(after));
  });
}

ProjectManifest _project({int? renamedIndex}) => ProjectManifest(
      name: 'NSC-74 dependency fixture',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      facts: <NarrativeFactDefinition>[
        for (var index = 0; index < _entryCount; index++)
          NarrativeFactDefinition(
            id: 'fact_${index.toString().padLeft(5, '0')}',
            label: index == renamedIndex
                ? 'Renamed Fact ${index.toString().padLeft(5, '0')}'
                : 'Fact ${index.toString().padLeft(5, '0')}',
          ),
      ],
    );

int _checksum(NarrativeDependencyIndex index) => index.definitions.fold<int>(
      0,
      (sum, definition) =>
          sum + int.parse(definition.key.id.substring('fact_'.length)),
    );

String _definitionSignature(NarrativeDependencyDefinition definition) =>
    '${definition.key}|${definition.label}|${definition.path}';

({int p50, int p95}) _measurement(List<int> samples) {
  final sorted = [...samples]..sort();
  return (
    p50: sorted[(sorted.length * .50).ceil() - 1],
    p95: sorted[(sorted.length * .95).ceil() - 1],
  );
}

String _singleLine(String value) => value.replaceAll(RegExp(r'\s+'), '_');
