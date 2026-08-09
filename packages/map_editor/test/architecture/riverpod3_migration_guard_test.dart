import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editor source stays on Riverpod 3 non-legacy APIs', () {
    // Riverpod 3 still ships these symbols through legacy.dart. Scanning the
    // source prevents a future dependency bump from silently restoring the
    // Riverpod 2 provider model after this migration.
    final forbiddenApi = RegExp(
      r'\b(?:StateNotifierProvider|StateNotifier|StateProvider|'
      r'ChangeNotifierProvider)\b',
    );
    final offenders = <String>[];

    for (final entry in Directory('lib').listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.dart')) continue;
      final lines = entry.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (forbiddenApi.hasMatch(line) || line.contains('legacy.dart')) {
          offenders.add('${entry.path}:${index + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Riverpod 2/legacy APIs remain:\n${offenders.join('\n')}',
    );
  });

  test('editor manifest does not request Riverpod 2', () {
    final manifest = File('pubspec.yaml').readAsStringSync();

    expect(
      RegExp(
        r'^\s+(?:flutter_riverpod|riverpod|riverpod_annotation|'
        r'riverpod_generator):\s*[\^<>=~]*2\.',
        multiLine: true,
      ).hasMatch(manifest),
      isFalse,
    );
  });
}
