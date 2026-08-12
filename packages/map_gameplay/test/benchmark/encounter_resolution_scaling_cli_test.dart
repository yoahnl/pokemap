import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('encounter benchmark exposes reproducible workload and latency stats',
      () async {
    final help = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'benchmark/encounter_resolution_scaling.dart', '--help'],
      workingDirectory: Directory.current.path,
    );

    expect(help.exitCode, 0, reason: '${help.stdout}\n${help.stderr}');
    expect(help.stdout, contains('--entries'));
    expect(help.stdout, contains('--warmup'));
    expect(help.stdout, contains('--iterations'));
    expect(help.stdout, contains('--seed'));

    final run = await Process.run(
      Platform.resolvedExecutable,
      <String>[
        'run',
        'benchmark/encounter_resolution_scaling.dart',
        '--entries=480',
        '--zones=12',
        '--warmup=2',
        '--iterations=7',
        '--seed=8122026',
      ],
      workingDirectory: Directory.current.path,
    );

    expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
    expect(run.stdout, contains('entries=480'));
    expect(run.stdout, contains('zones=12'));
    expect(run.stdout, contains('warmup=2'));
    expect(run.stdout, contains('iterations=7'));
    expect(run.stdout, contains('seed=8122026'));
    expect(run.stdout, contains('median_us='));
    expect(run.stdout, contains('p95_us='));
    expect(run.stdout, contains('resolved='));
    expect(run.stdout, contains('candidates_per_position_min=3'));
  });

  test('encounter benchmark remains hermetic and avoids fragile thresholds',
      () {
    final source = File(
      'benchmark/encounter_resolution_scaling.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("import 'dart:io'")));
    expect(source, isNot(contains('HttpClient')));
    expect(source, isNot(contains('File(')));
    expect(source, isNot(contains('Directory(')));
    expect(source, isNot(contains('threshold')));
  });
}
