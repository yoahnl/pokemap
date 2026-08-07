import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';

/// Resolves a launchable context for an installed game, or refuses to.
abstract interface class SessionLaunchRepositoryInterface {
  Future<InstalledGameLaunchContext> resolve(InstalledGame game);
}
