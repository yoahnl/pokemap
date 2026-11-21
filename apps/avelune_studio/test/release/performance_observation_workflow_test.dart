@Tags(['product-certification'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('performance workflow references existing Dart entrypoints', () {
    final repositoryRoot = Directory.current.parent.parent;
    final workflow = File(
      '${repositoryRoot.path}/.github/workflows/'
      'pokemap_product_certification.yml',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    final performanceJob = workflow.substring(
      workflow.indexOf('  performance-observation:'),
    );
    final dartEntrypoints = <File>{};
    var shellDirectory = repositoryRoot.uri;
    var stepDirectory = repositoryRoot.uri;

    for (final rawLine in performanceJob.split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith('- name:') || line.startsWith('- uses:')) {
        stepDirectory = repositoryRoot.uri;
      } else if (line.startsWith('working-directory:')) {
        final path = line.substring('working-directory:'.length).trim();
        stepDirectory = repositoryRoot.uri.resolve('$path/');
      } else if (line == 'run: |') {
        shellDirectory = stepDirectory;
      }
      if (line.startsWith('cd ')) {
        final path = line.substring(3).split(RegExp(r'\s')).first;
        final base =
            path.startsWith('packages/') ||
                path.startsWith('apps/') ||
                path.startsWith('tools/')
            ? repositoryRoot.uri
            : shellDirectory;
        shellDirectory = base.resolve('$path/');
      }
      for (final match in RegExp(
        r'([a-z0-9_./-]+\.dart)(?=\s|\\|$)',
      ).allMatches(line)) {
        dartEntrypoints.add(
          File.fromUri(shellDirectory.resolve(match.group(1)!)),
        );
      }
    }

    expect(dartEntrypoints, isNotEmpty);
    final missing = dartEntrypoints
        .where((entrypoint) => !entrypoint.existsSync())
        .map((entrypoint) => entrypoint.path)
        .toList();
    expect(
      missing,
      isEmpty,
      reason:
          'Missing performance workflow entrypoints:\n${missing.join('\n')}',
    );
  });

  test('manual performance observations retain the maintained benchmarks', () {
    final repositoryRoot = Directory.current.parent.parent;
    final workflow = File(
      '${repositoryRoot.path}/.github/workflows/'
      'pokemap_product_certification.yml',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    final performanceJob = workflow.substring(
      workflow.indexOf('  performance-observation:'),
    );

    expect(performanceJob, contains('continue-on-error: true'));
    expect(
      RegExp(r'--extents 128,256,512,1024').allMatches(performanceJob),
      hasLength(2),
    );
    expect(performanceJob, contains('pokemap-performance-observation-'));
    expect(performanceJob, isNot(contains('packages/map_editor')));
  });
}
