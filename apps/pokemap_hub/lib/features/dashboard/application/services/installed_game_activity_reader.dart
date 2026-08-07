import 'dart:io';

import 'package:pokemap_hub/core/diagnostics/hub_diagnostic.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/saves/data/repositories/hub_save_repository_impl.dart';
import 'package:pokemap_hub/features/session/data/repositories/installed_game_launch_resolver.dart';

/// Reads save activity and branding only after the installed release verifies.
final class InstalledHubGameActivityReader {
  const InstalledHubGameActivityReader({
    required this.supportRoot,
    required this.launchResolver,
  });

  final Directory supportRoot;
  final InstalledGameLaunchResolver launchResolver;

  Future<HubGameActivity> call(InstalledGame game) async {
    try {
      final launch = await launchResolver.resolve(game);
      final save = await HubSaveStore(
        supportRoot: supportRoot,
        identity: launch.identity,
      ).findContinue();
      Future<String?> resolve(String? path) async {
        if (path == null) return null;
        try {
          return (await launch.assets.resolveFile(path)).path;
        } on Object {
          return null;
        }
      }

      final branding = launch.manifest.branding;
      return HubGameActivity(
        canContinue: save?.canContinue ?? false,
        lastSaveAt: save?.envelope?.updatedAt,
        playTimeSeconds: save?.envelope?.playTimeSeconds ?? 0,
        iconPath: await resolve(branding?.icon),
        coverPath: await resolve(branding?.cover),
        heroPath: await resolve(branding?.hero),
      );
    } on InstalledGameLaunchException catch (error) {
      return HubGameActivity(
        installationHealthy: false,
        diagnostic: HubDiagnostic(
          code: 'launch.${error.code.name}',
          severity: HubDiagnosticSeverity.error,
          message: '${game.title} ne peut pas être lancé.',
          recommendation: 'Réparez l’installation avant de jouer.',
          gameId: game.gameId,
        ),
      );
    }
  }
}
