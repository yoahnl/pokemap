import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('performance workflow references existing Dart entrypoints', () {
    final repositoryRoot = Directory.current.parent.parent;
    final workflow = File(
      '${repositoryRoot.path}/.github/workflows/'
      'pokemap_hub_product_certification.yml',
    ).readAsStringSync();
    final performanceJob = workflow.substring(
      workflow.indexOf('  performance-observation:'),
      workflow.indexOf('\n  windows-desktop-certification:'),
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
        final base = path.startsWith('packages/') ||
                path.startsWith('apps/') ||
                path.startsWith('examples/') ||
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
      reason: 'Missing performance workflow entrypoints:\n${missing.join('\n')}',
    );
  });
}
