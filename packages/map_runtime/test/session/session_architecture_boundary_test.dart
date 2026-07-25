import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime never depends on Hub, distribution or player UI', () async {
    final violations = <String>[];
    await for (final entity
        in Directory('lib').list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      for (final forbidden in <String>[
        'package:pokemap_hub/',
        'package:map_distribution/',
        'package:map_player_ui/',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${entity.path} imports $forbidden');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('transport and controller contracts contain no Flutter or Flame types',
      () async {
    final violations = <String>[];
    for (final path in <String>[
      'lib/src/session/game_session_contract.dart',
      'lib/src/session/game_session_controller.dart',
      'lib/src/session/in_process_game_session_adapter.dart',
      'lib/src/session/player_input.dart',
    ]) {
      final source = await File(path).readAsString();
      for (final forbidden in <String>[
        'package:flutter/',
        'package:flame/',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('$path imports $forbidden');
        }
      }
    }

    expect(violations, isEmpty);
  });
}
