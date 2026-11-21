import 'package:avelune_player_host/features/library/domain/entities/game_library.dart';
import 'package:avelune_player_host/features/session/domain/entities/installed_game_launch_context.dart';

/// Resolves a launchable context for an installed game, or refuses to.
abstract interface class SessionLaunchRepositoryInterface {
  Future<InstalledGameLaunchContext> resolve(InstalledGame game);
}
