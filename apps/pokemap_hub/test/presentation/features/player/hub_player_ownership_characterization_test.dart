import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hub composition owns no player presentation state machine', () async {
    final installedPlayer = await File(
      'lib/presentation/features/player/pages/hub_installed_game_player.dart',
    ).readAsString();
    final app = await File('lib/app/ui/app_widget.dart').readAsString();

    for (final forbidden in <String>[
      'PlayerShellController',
      'PlayerShellSnapshot',
      'PlayerShellState',
      'HubPlayerShellSurface',
      'HubPlayerShellView',
    ]) {
      expect(
        installedPlayer,
        isNot(contains(forbidden)),
        reason: '$forbidden must remain runtime-owned',
      );
      expect(
        app,
        isNot(contains(forbidden)),
        reason: '$forbidden must not become Hub app state',
      );
    }
    expect(installedPlayer, contains('RuntimePlayerCoordinator('));
    expect(installedPlayer, contains('PokeMapPlayerSessionView('));
  });
}
