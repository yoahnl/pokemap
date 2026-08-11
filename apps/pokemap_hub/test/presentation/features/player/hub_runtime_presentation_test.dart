import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Hub mounts the canonical runtime-owned player view exactly once',
    () async {
      final installedPlayer =
          await File(
            'lib/presentation/features/player/pages/hub_installed_game_player.dart',
          ).readAsString();
      final startupBootstrap =
          await File(
            'lib/features/session/application/services/hub_runtime_startup_bootstrap.dart',
          ).readAsString();
      final uiBarrel = await File('lib/pokemap_hub_ui.dart').readAsString();
      final playerBarrel =
          await File('lib/pokemap_hub_player.dart').readAsString();
      final composition =
          await File('lib/app/di/hub_composition.dart').readAsString();

      expect(installedPlayer, contains('GameWidget('));
      expect(installedPlayer, contains('RuntimeStartupBootstrapCoordinator'));
      expect(startupBootstrap, contains('RuntimePlayerCoordinator('));
      expect(startupBootstrap, contains('HubRuntimeStartupAdapter('));
      expect(startupBootstrap, contains('RuntimeInitialMapPreloader('));
      expect(startupBootstrap, contains('initialMapPreloadPort:'));
      expect(startupBootstrap, contains('preloadedInitialMap:'));
      expect(installedPlayer, contains('PlayerRuntimeStartupShell('));
      expect(installedPlayer, isNot(contains('runtimeStartupShellEnabled')));
      expect(installedPlayer, isNot(contains('PlayerLoadingSurface(')));
      expect(installedPlayer, contains('stopIntroPlayback'));
      expect(
        installedPlayer,
        contains('game.setBattleFlutterCommandOverlayPreferred(true)'),
      );
      expect(installedPlayer, contains('PokeMapPlayerSessionView('));
      expect(
        installedPlayer,
        contains(
          'battlePresentation: _mountedGame?.battleCommandOverlayListenable',
        ),
      );
      expect(
        installedPlayer,
        contains(
          'onBattleCommand: _mountedGame?.dispatchBattlePresentationCommand',
        ),
      );
      expect(installedPlayer, contains('RuntimePlayerPresentation.fromRuntime'));
      expect(installedPlayer, contains('branding: widget.hostBranding'));
      expect(installedPlayer, contains('splashLogo: widget.splashLogo'));
      expect(installedPlayer, isNot(contains('AVELUNE')));
      expect(installedPlayer, isNot(contains('assets/avelune/')));
      expect(startupBootstrap, contains('RuntimeStartupPresentationMetadata('));
      expect(startupBootstrap, isNot(contains('HubTitlePresentationLoader')));
      expect(composition, contains('_aveluneRuntimeSplashBranding'));
      expect(composition, contains('_aveluneRuntimeSplashLogo'));
      expect(installedPlayer, contains('Localizations.override('));
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
      expect(
        'PlayerRuntimeStartupShell('.allMatches(installedPlayer),
        hasLength(1),
      );
      expect(
        installedPlayer,
        isNot(contains('HubIntroVideoPlayer(')),
        reason: 'Concrete intro playback must now live in map_player_ui.',
      );
      expect(startupBootstrap, contains('HubRuntimeGameSource('));
      expect(startupBootstrap, contains('HubPlayerSaveGateway('));
      expect(startupBootstrap, contains('HubPlayerPreferencesGateway('));
      expect(startupBootstrap, contains('HubRuntimeExternalExit('));
      expect(installedPlayer, isNot(contains('PopScope<Object?>(')));
      expect(installedPlayer, isNot(contains('_handleSystemBack')));
      expect(installedPlayer, isNot(contains('_payloadForAction')));
      expect(startupBootstrap, contains('defaultSaveSlot:'));
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
    },
  );
}
