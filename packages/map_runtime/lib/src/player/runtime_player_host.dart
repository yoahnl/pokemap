import 'package:map_core/map_core.dart';

import '../session/game_session_contract.dart';

/// Host-provided source for one game selected by the player.
///
/// Installation paths and package-library concepts stay behind this port so
/// the same runtime player can be embedded by the Hub or a future standalone
/// host.
abstract interface class RuntimeGameSource {
  GameIdentity get identity;

  String get displayTitle;

  Future<GameSessionDescriptor> createSessionDescriptor({
    required GameSessionLaunchMode launchMode,
    required String profileId,
    required String slotId,
    String? saveReadHandle,
  });
}

/// Player-safe metadata for one save slot.
///
/// The actual save payload and filesystem location never cross this boundary.
final class PlayerSaveSummary {
  PlayerSaveSummary({
    required this.address,
    required this.updatedAt,
    required this.playTimeSeconds,
    required this.status,
    required this.canContinue,
    this.safeUnavailableReason,
  }) {
    if (playTimeSeconds < 0) {
      throw ArgumentError.value(
        playTimeSeconds,
        'playTimeSeconds',
        'must be non-negative',
      );
    }
  }

  final SaveSlotAddress address;
  final DateTime updatedAt;
  final int playTimeSeconds;
  final SaveStatus status;
  final bool canContinue;
  final String? safeUnavailableReason;
}

/// Host-owned save operations exposed to the runtime player.
abstract interface class PlayerSaveGateway {
  GameIdentity get identity;

  Future<PlayerSaveSummary?> readLatestSummary();

  Future<PlayerSaveSummary?> readSummary(SaveSlotAddress address);

  Future<String?> openReadHandle(SaveSlotAddress address);

  Future<void> commit(GameSessionCheckpointCommit request);
}

/// Global player preferences transported as data.
final class PlayerPreferencesSnapshot {
  const PlayerPreferencesSnapshot({
    required this.locale,
    required this.accessibility,
    this.touchControlsOpacity = 0.82,
  })  : assert(locale != ''),
        assert(
          touchControlsOpacity >= 0.3 && touchControlsOpacity <= 1,
          'touchControlsOpacity must be between 0.3 and 1',
        );

  final String locale;
  final GameSessionAccessibilityOptions accessibility;
  final double touchControlsOpacity;

  PlayerPreferencesSnapshot copyWith({
    String? locale,
    GameSessionAccessibilityOptions? accessibility,
    double? touchControlsOpacity,
  }) =>
      PlayerPreferencesSnapshot(
        locale: locale ?? this.locale,
        accessibility: accessibility ?? this.accessibility,
        touchControlsOpacity: touchControlsOpacity ?? this.touchControlsOpacity,
      );
}

/// Host-owned persistence for global player preferences.
abstract interface class PlayerPreferencesGateway {
  Future<PlayerPreferencesSnapshot> load();

  Future<void> save(PlayerPreferencesSnapshot preferences);
}

/// Exit boundary implemented by the embedding application.
abstract interface class RuntimeExternalExit {
  Future<void> returnToHost();
}
