import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hub delegates installed intro playback to the generic player package',
      () async {
    final installedPlayer = await File(
      'lib/presentation/features/player/pages/hub_installed_game_player.dart',
    ).readAsString();
    final genericPlayer = await File(
      '../../packages/map_player_ui/lib/src/player/player_intro_video_player.dart',
    ).readAsString();

    expect(
      File(
        'lib/presentation/features/player/pages/hub_intro_video_player.dart',
      ).existsSync(),
      isFalse,
    );
    expect(installedPlayer, contains('PlayerRuntimeStartupShell('));
    expect(installedPlayer, isNot(contains('HubIntroVideoPlayer(')));
    expect(genericPlayer, contains('VideoPlayerIntroPlaybackDriver'));
  });

  test('Hub wires the awaited decoder stop into the startup coordinator',
      () async {
    final installedPlayer = await File(
      'lib/presentation/features/player/pages/hub_installed_game_player.dart',
    ).readAsString();
    final startupBootstrap = await File(
      'lib/features/session/application/services/hub_runtime_startup_bootstrap.dart',
    ).readAsString();

    expect(
      installedPlayer,
      contains('stopIntroPlayback: _startupShellController.stopIntroPlayback'),
    );
    expect(startupBootstrap, contains('RuntimeTitleMusicController('));
  });
}
