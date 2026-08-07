import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hub mounts the canonical runtime-owned player view exactly once',
      () async {
    final installedPlayer = await File(
      'lib/presentation/features/player/pages/hub_installed_game_player.dart',
    ).readAsString();
    final uiBarrel = await File('lib/pokemap_hub_ui.dart').readAsString();
    final playerBarrel =
        await File('lib/pokemap_hub_player.dart').readAsString();

    expect(installedPlayer, contains('GameWidget('));
    expect(installedPlayer, contains('RuntimePlayerCoordinator('));
    expect(installedPlayer, contains('PokeMapPlayerSessionView('));
    expect(
      installedPlayer,
      contains('gameplayInputRoute: _sessions?.handleInput'),
    );
    expect(
      installedPlayer,
      contains('autofocus: false'),
      reason: 'Hosted GameWidget input must enter through the player router.',
    );
    expect(
      installedPlayer,
      isNot(contains('_routeMenuKey')),
      reason: 'The Hub must not own a second keyboard Menu route.',
    );
    expect(
      'PokeMapPlayerSessionView('.allMatches(installedPlayer),
      hasLength(1),
    );
    expect(installedPlayer, contains('HubRuntimeGameSource('));
    expect(installedPlayer, contains('HubPlayerSaveGateway('));
    expect(installedPlayer, contains('HubPlayerPreferencesGateway('));
    expect(installedPlayer, contains('HubRuntimeExternalExit('));
    expect(installedPlayer, contains('PopScope<Object?>('));
    expect(installedPlayer, contains('pauseForLifecycle()'));
    expect(installedPlayer, contains('resumeFromLifecycle()'));
    expect(
      installedPlayer,
      isNot(contains('PlayableMapGamePresentationController')),
    );
    expect(installedPlayer, isNot(contains('PlayerShellController')));
    expect(installedPlayer, isNot(contains('HubPlayerShellView')));
    expect(installedPlayer, isNot(contains('HubRuntimePresentation')));
    expect(uiBarrel, isNot(contains('hub_runtime_presentation.dart')));
    expect(playerBarrel, isNot(contains('hub_runtime_presentation.dart')));
  });
}
