import 'package:map_core/map_core.dart';

import '../session/game_session_contract.dart';
import 'runtime_audio_mixer.dart';

/// Host-provided source for one game selected by the player.
///
/// Installation paths and package-library concepts stay behind this port so
/// the same runtime player can be embedded by the Hub or a future standalone
/// host.
abstract interface class RuntimeGameSource {
  GameIdentity get identity;

  String get displayTitle;

  Set<ProjectPauseActionId> get defaultVisiblePauseActions;

  Future<GameSessionDescriptor> createSessionDescriptor({
    required GameSessionLaunchMode launchMode,
    required String profileId,
    required String slotId,
    String? saveReadHandle,
    GameState? initialGameState,
  });
}

/// Pourquoi une sauvegarde ne peut pas être reprise, sous forme de code.
///
/// Le host connaît la cause typée ; il ne connaît pas la langue du joueur. Tant
/// qu'il renvoyait une phrase toute faite, elle finissait interpolée dans un
/// gabarit du runtime rédigé dans une autre langue, et le joueur lisait « Cette
/// sauvegarde ne peut pas être poursuivie : This ending does not allow post-game
/// continuation. » Le code traverse la frontière, la formulation reste du côté
/// qui sait ce que le joueur lit.
enum PlayerSaveUnavailableReason {
  postGameContinuationRefused,
  migrationRequired,
  incompatibleVersion,
  corrupt,
  missing,
  temporarilyUnavailable,
}

/// La formulation vue par le joueur pour chaque cause.
///
/// Un seul propriétaire de la langue : le host renvoie un code, le runtime le
/// rend. C'est ce qui empêche deux moitiés de la même phrase d'être écrites dans
/// deux langues par deux auteurs différents.
String playerSaveUnavailableReasonText(PlayerSaveUnavailableReason reason) =>
    switch (reason) {
      PlayerSaveUnavailableReason.postGameContinuationRefused =>
        'Cette fin n’autorise pas de reprise après la fin du jeu.',
      PlayerSaveUnavailableReason.migrationRequired =>
        'Cette sauvegarde doit être migrée avant de pouvoir être chargée.',
      PlayerSaveUnavailableReason.incompatibleVersion =>
        'Cette sauvegarde n’est pas compatible avec la version installée.',
      PlayerSaveUnavailableReason.corrupt =>
        'Cette sauvegarde est endommagée et n’a pas pu être récupérée depuis '
            'sa copie de secours.',
      PlayerSaveUnavailableReason.missing =>
        'Aucune sauvegarde n’existe dans cet emplacement.',
      PlayerSaveUnavailableReason.temporarilyUnavailable =>
        'Cette sauvegarde est temporairement indisponible.',
    };

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
    this.unavailableReason,
    String? locationLabel,
  }) : locationLabel = switch (locationLabel?.trim()) {
          '' => null,
          final label => label,
        } {
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
  final PlayerSaveUnavailableReason? unavailableReason;
  final String? locationLabel;
}

/// Host-owned save operations exposed to the runtime player.
abstract interface class PlayerSaveGateway {
  GameIdentity get identity;

  Future<PlayerSaveSummary?> readLatestSummary();

  Future<PlayerSaveSummary?> readSummary(SaveSlotAddress address);

  Future<String?> openReadHandle(SaveSlotAddress address);

  Future<void> deleteSave(SaveSlotAddress address);

  Future<void> commit(GameSessionCheckpointCommit request);
}

/// Global player preferences transported as data.
final class PlayerPreferencesSnapshot {
  const PlayerPreferencesSnapshot({
    required this.locale,
    required this.accessibility,
    this.touchControlsOpacity = 0.82,
    this.audioMix = const RuntimeAudioMix(),
    this.highContrast = false,
    this.showInputHints = true,
  })  : assert(locale != ''),
        assert(
          touchControlsOpacity >= 0.3 && touchControlsOpacity <= 1,
          'touchControlsOpacity must be between 0.3 and 1',
        );

  final String locale;
  final GameSessionAccessibilityOptions accessibility;
  final double touchControlsOpacity;
  final RuntimeAudioMix audioMix;
  final bool highContrast;
  final bool showInputHints;

  PlayerPreferencesSnapshot copyWith({
    String? locale,
    GameSessionAccessibilityOptions? accessibility,
    double? touchControlsOpacity,
    RuntimeAudioMix? audioMix,
    bool? highContrast,
    bool? showInputHints,
  }) =>
      PlayerPreferencesSnapshot(
        locale: locale ?? this.locale,
        accessibility: accessibility ?? this.accessibility,
        touchControlsOpacity: touchControlsOpacity ?? this.touchControlsOpacity,
        audioMix: audioMix ?? this.audioMix,
        highContrast: highContrast ?? this.highContrast,
        showInputHints: showInputHints ?? this.showInputHints,
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
