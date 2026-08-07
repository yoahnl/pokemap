import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Hub cannot define a second player state machine or shell', () async {
    const removedFiles = <String>[
      'lib/features/session/application/services/player_shell_controller.dart',
      'lib/features/session/domain/entities/player_shell_models.dart',
      'lib/presentation/features/player/pages/hub_player_shell_view.dart',
    ];
    for (final path in removedFiles) {
      expect(
        File(path).existsSync(),
        isFalse,
        reason: '$path duplicates runtime/player-ui ownership',
      );
    }

    final violations = <String>[];
    await for (final entity
        in Directory('lib').list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = await entity.readAsString();
      for (final forbidden in <String>[
        'class PlayerShellController',
        'enum PlayerShellState',
        'class PlayerShellSnapshot',
        'class HubPlayerShellView',
        'class HubPlayerShellSurface',
      ]) {
        if (source.contains(forbidden)) {
          violations.add('${p.relative(entity.path)} defines $forbidden');
        }
      }
    }

    final playerBarrel =
        await File('lib/pokemap_hub_player.dart').readAsString();
    final uiBarrel = await File('lib/pokemap_hub_ui.dart').readAsString();
    for (final forbidden in <String>[
      'player_shell_controller.dart',
      'player_shell_models.dart',
      'hub_player_shell_view.dart',
    ]) {
      if (playerBarrel.contains(forbidden)) {
        violations.add('pokemap_hub_player.dart exports $forbidden');
      }
      if (uiBarrel.contains(forbidden)) {
        violations.add('pokemap_hub_ui.dart exports $forbidden');
      }
    }

    expect(violations, isEmpty);
  });
}
