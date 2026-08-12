import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('item benchmark exposes the 5000 definitions and 500 stacks workload',
      () async {
    final help = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'benchmark/item_catalog_bag_scaling.dart', '--help'],
      workingDirectory: Directory.current.path,
    );

    expect(help.exitCode, 0, reason: '${help.stdout}\n${help.stderr}');
    expect(help.stdout, contains('--definitions'));
    expect(help.stdout, contains('--stacks'));
    expect(help.stdout, contains('--warmup'));
    expect(help.stdout, contains('--iterations'));

    final run = await Process.run(
      Platform.resolvedExecutable,
      <String>[
        'run',
        'benchmark/item_catalog_bag_scaling.dart',
        '--definitions=5000',
        '--stacks=500',
        '--warmup=2',
        '--iterations=7',
      ],
      workingDirectory: Directory.current.path,
    );

    expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
    expect(run.stdout, contains('definitions=5000'));
    expect(run.stdout, contains('stacks=500'));
    expect(run.stdout, contains('warmup=2'));
    expect(run.stdout, contains('iterations=7'));
    expect(run.stdout, contains('median_us='));
    expect(run.stdout, contains('p95_us='));
    expect(run.stdout, contains('catalog_lookups=4'));
    expect(run.stdout, contains('capability_resolutions=4'));
    expect(run.stdout, contains('bag_operations=4'));
  });

  test('item benchmark is hermetic and avoids fragile time thresholds', () {
    final source = File(
      'benchmark/item_catalog_bag_scaling.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("import 'dart:io'")));
    expect(source, isNot(contains('HttpClient')));
    expect(source, isNot(contains('File(')));
    expect(source, isNot(contains('Directory(')));
    expect(source, isNot(contains('threshold')));
  });
}
