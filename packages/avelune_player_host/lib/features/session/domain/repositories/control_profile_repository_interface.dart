import 'package:map_player_ui/map_player_ui.dart';

/// Persists control remapping separately from general preferences, so malformed
/// remapping data can fall back without invalidating accessibility or audio.
abstract interface class ControlProfileRepositoryInterface {
  Future<PlayerControlProfile> load();

  Future<void> save(PlayerControlProfile profile);
}
