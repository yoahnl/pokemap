import 'dart:io';

import 'package:pokemap_hub/core/diagnostics/hub_diagnostic.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_hub/features/saves/domain/repositories/save_repository_interface.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';

/// Builds the save repository scoped to one installed game.
///
/// A factory rather than a repository, because the save store is per-game: its
/// identity is only known once the launch context resolves. Injected so this
/// application service never names an implementation (rule 3).
typedef SaveRepositoryFactory = SaveRepositoryInterface Function(
  Directory supportRoot,
  GameIdentity identity,
);

/// Reads save activity and branding only after the installed release verifies.
final class InstalledHubGameActivityReader {
  const InstalledHubGameActivityReader({
    required this.supportRoot,
    required this.launchResolver,
    required this.saveRepositoryFactory,
  });

  final Directory supportRoot;
  final SessionLaunchRepositoryInterface launchResolver;
  final SaveRepositoryFactory saveRepositoryFactory;

  Future<HubGameActivity> call(InstalledGame game) async {
    try {
      final launch = await launchResolver.resolve(game);
      final save = await saveRepositoryFactory(
        supportRoot,
        launch.identity,
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
