import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('Hub production code never imports editor or developer host', () async {
    final violations = <String>[];
    await for (final entity
        in Directory('lib').list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      for (final forbidden in <String>[
        'package:map_editor/',
        'examples/playable_runtime_host',
        'package:playable_runtime_host/',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${p.relative(entity.path)} imports $forbidden');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
