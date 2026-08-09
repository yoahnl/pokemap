import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composed Flutter source stays on Riverpod 3 non-legacy APIs', () {
    // Riverpod 3 still ships these symbols through legacy.dart. Scanning the
    // source prevents a future dependency bump from silently restoring the
    // Riverpod 2 provider model after this migration.
    final forbiddenApi = RegExp(
      r'\b(?:StateNotifierProvider|StateNotifier|StateProvider|'
      r'ChangeNotifierProvider|ProviderRef)\b',
    );
    final offenders = <String>[];
    final sourceRoots = <Directory>[
      Directory('lib'),
      Directory('test'),
      Directory('dev'),
      Directory('integration_test'),
      Directory('../../apps/pokemap_hub/lib'),
      Directory('../../apps/pokemap_hub/test'),
      Directory('../../examples/playable_runtime_host/lib'),
      Directory('../../examples/playable_runtime_host/test'),
      Directory('../../tools/pokemap_product_certification/lib'),
      Directory('../../tools/pokemap_product_certification/test'),
    ];

    for (final root in sourceRoots.where((root) => root.existsSync())) {
      for (final entry in root.listSync(recursive: true)) {
        if (entry is! File || !entry.path.endsWith('.dart')) continue;
        if (entry.path.endsWith('riverpod3_migration_guard_test.dart')) {
          continue;
        }
        final lines = entry.readAsLinesSync();
        for (var index = 0; index < lines.length; index++) {
          final line = lines[index];
          if (forbiddenApi.hasMatch(line) || line.contains('legacy.dart')) {
            offenders.add('${entry.path}:${index + 1}: ${line.trim()}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Riverpod 2/legacy APIs remain:\n${offenders.join('\n')}',
    );
  });

  test('composed manifests do not request Riverpod 2', () {
    final manifestPaths = <String>[
      'pubspec.yaml',
      '../../apps/pokemap_hub/pubspec.yaml',
      '../../examples/playable_runtime_host/pubspec.yaml',
      '../../tools/pokemap_product_certification/pubspec.yaml',
    ];
    final offenders = <String>[];

    for (final path in manifestPaths) {
      final manifest = File(path).readAsStringSync();
      if (RegExp(
        r'^\s+(?:flutter_riverpod|riverpod|riverpod_annotation|'
        r'riverpod_generator):\s*[\^<>=~]*2\.',
        multiLine: true,
      ).hasMatch(manifest)) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Riverpod 2 constraints remain in: ${offenders.join(', ')}',
    );
  });

  test('editor entrypoints disable Riverpod 3 automatic retries', () {
    for (final path in <String>[
      'lib/main.dart',
      'dev/marionette_main.dart',
      'integration_test/editor_project_journey_test.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('retry: disableAutomaticProviderRetry'),
        reason: '$path must preserve Riverpod 2 failure semantics',
      );
    }
  });
}
