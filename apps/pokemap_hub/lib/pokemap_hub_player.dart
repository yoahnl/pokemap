/// PokeMap Hub player composition API.
///
/// The pure-Dart install, library, and save API remains available from
/// `pokemap_hub.dart` so recovery workers do not need to load Flutter or Flame.
library;

export 'package:pokemap_hub/pokemap_hub.dart';
export 'package:pokemap_hub/features/session/application/gateways/hub_player_preferences_gateway.dart';
export 'package:pokemap_hub/features/session/application/gateways/hub_player_save_gateway.dart';
export 'package:pokemap_hub/features/session/domain/entities/hub_runtime_external_exit.dart';
export 'package:pokemap_hub/features/session/application/services/hub_runtime_game_source.dart';
export 'package:pokemap_hub/features/session/application/services/hub_session_checkpoint_committer.dart';
export 'package:pokemap_hub/features/session/application/services/hub_in_process_session_factory.dart';
export 'package:pokemap_hub/features/session/data/repositories/installed_game_launch_resolver.dart';
export 'package:pokemap_hub/features/session/data/repositories/package_asset_resolver.dart';
export 'package:pokemap_hub/features/session/domain/entities/save_read_handle.dart';
