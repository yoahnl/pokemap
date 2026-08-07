import 'package:map_player_ui/map_player_ui.dart';

import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';

/// Reads and writes player preferences, with corruption fallback.
abstract interface class PlayerPreferencesRepositoryInterface {
  Future<HubPreferencesRead> load();

  Future<void> save(PlayerPreferences preferences);
}
