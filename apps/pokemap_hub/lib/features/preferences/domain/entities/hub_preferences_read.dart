import 'package:map_player_ui/map_player_ui.dart';

enum HubPreferencesSource { current, backup, defaults }

final class HubPreferencesRead {
  const HubPreferencesRead({
    required this.preferences,
    required this.source,
    required this.currentCorrupt,
    required this.backupCorrupt,
  });

  final PlayerPreferences preferences;
  final HubPreferencesSource source;
  final bool currentCorrupt;
  final bool backupCorrupt;
}

final class HubPreferencesStorageException implements Exception {
  const HubPreferencesStorageException(this.message);

  final String message;

  @override
  String toString() => 'HubPreferencesStorageException: $message';
}

/// Atomic player preference storage under the Hub application-support root.
