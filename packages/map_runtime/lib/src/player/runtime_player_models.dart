import 'dart:collection';

import '../session/game_session_contract.dart';
import '../session/player_input.dart';
import 'runtime_player_host.dart';
import 'runtime_player_pause_data.dart';
import 'runtime_world_service_models.dart';

enum RuntimePlayerPhase {
  boot,
  title,
  preparingSession,
  loadingSession,
  playing,
  paused,
  saving,
  lifecyclePaused,
  completing,
  result,
  credits,
  disposingSession,
  externalExit,
  error,
}

enum RuntimePlayerAction {
  continueGame,
  newGame,
  load,
  openMenu,
  resume,
  openParty,
  openBag,
  useBagItem,
  openPokedex,
  openMap,
  save,
  openOptions,
  updatePreferences,
  returnToPauseRoot,
  returnToTitle,
  showCredits,
  finishCredits,
  returnToHost,
  retry,
  cancel,
}

final class RuntimePlayerSaveAddress {
  const RuntimePlayerSaveAddress({
    required this.gameId,
    required this.profileId,
    required this.slotId,
  });

  final String gameId;
  final String profileId;
  final String slotId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimePlayerSaveAddress &&
          gameId == other.gameId &&
          profileId == other.profileId &&
          slotId == other.slotId;

  @override
  int get hashCode => Object.hash(gameId, profileId, slotId);
}

final class RuntimePlayerSaveReceipt {
  const RuntimePlayerSaveReceipt({
    required this.address,
    required this.trigger,
  });

  final RuntimePlayerSaveAddress address;
  final GameSessionCheckpointTrigger trigger;
}

/// Explicit UI availability for one runtime-owned player action.
final class RuntimePlayerActionAvailability {
  const RuntimePlayerActionAvailability.enabled(this.action)
      : isEnabled = true,
        unavailableReason = null;

  RuntimePlayerActionAvailability.disabled(
    this.action, {
    required String reason,
  })  : isEnabled = false,
        unavailableReason = reason {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'must contain a player-safe explanation',
      );
    }
  }

  final RuntimePlayerAction action;
  final bool isEnabled;
  final String? unavailableReason;
}

/// Typed payload for the title screen's explicit slot selection.
final class RuntimePlayerLoadSlot {
  const RuntimePlayerLoadSlot({
    required this.profileId,
    required this.slotId,
  });

  final String profileId;
  final String slotId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimePlayerLoadSlot &&
          profileId == other.profileId &&
          slotId == other.slotId;

  @override
  int get hashCode => Object.hash(profileId, slotId);
}

/// Guided New Game payload combining the selected save boundary and identity.
final class RuntimePlayerNewGameSetup {
  const RuntimePlayerNewGameSetup({
    required this.slot,
    required this.identity,
  });

  final RuntimePlayerLoadSlot slot;
  final GameSessionPlayerIdentity identity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimePlayerNewGameSetup &&
          other.slot == slot &&
          other.identity == identity;

  @override
  int get hashCode => Object.hash(slot, identity);
}

/// Command emitted by a player surface from one exact snapshot revision.
final class RuntimePlayerCommand {
  const RuntimePlayerCommand({
    required this.action,
    required this.snapshotRevision,
    this.payload,
  }) : assert(snapshotRevision >= 0);

  final RuntimePlayerAction action;
  final int snapshotRevision;
  final Object? payload;
}

enum RuntimePlayerCommandStatus {
  accepted,
  stale,
  unavailable,
  cancelled,
  failed,
}

final class RuntimePlayerCommandResult {
  const RuntimePlayerCommandResult({
    required this.status,
    this.safeMessage,
  });

  final RuntimePlayerCommandStatus status;
  final String? safeMessage;
}

/// Immutable presentation state owned by the runtime player coordinator.
final class RuntimePlayerSnapshot {
  RuntimePlayerSnapshot({
    required this.revision,
    required this.phase,
    required this.gameTitle,
    this.pauseSection,
    List<RuntimePlayerActionAvailability> actions =
        const <RuntimePlayerActionAvailability>[],
    this.loadingProgress,
    this.result,
    this.credits,
    this.failure,
    this.logicalSelectionId,
    this.activeInputSource,
    this.worldService,
    this.preferences,
    this.hasDiscoveredSave = false,
    this.activeSaveAddress,
    this.saveReceipt,
    Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot> pauseDetails =
        const <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{},
  })  : actions = List<RuntimePlayerActionAvailability>.unmodifiable(actions),
        pauseDetails = UnmodifiableMapView<RuntimePlayerPauseSection,
            RuntimePlayerPauseDetailSnapshot>(
          Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>.from(
              pauseDetails),
        ) {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must be non-negative');
    }
    if (gameTitle.trim().isEmpty) {
      throw ArgumentError.value(gameTitle, 'gameTitle', 'must not be empty');
    }
    final actionStates =
        <RuntimePlayerAction, RuntimePlayerActionAvailability>{};
    for (final availability in this.actions) {
      if (actionStates.containsKey(availability.action)) {
        throw ArgumentError.value(
          availability.action,
          'actions',
          'contains duplicate action declarations',
        );
      }
      actionStates[availability.action] = availability;
    }
    for (final entry in this.pauseDetails.entries) {
      if (entry.key == RuntimePlayerPauseSection.root ||
          entry.key != entry.value.section) {
        throw ArgumentError.value(
          entry.key,
          'pauseDetails',
          'keys must match their non-root detail section',
        );
      }
    }
    _actionStates = UnmodifiableMapView<RuntimePlayerAction,
        RuntimePlayerActionAvailability>(actionStates);
  }

  final int revision;
  final RuntimePlayerPhase phase;
  final String gameTitle;
  final RuntimePlayerPauseSection? pauseSection;
  final List<RuntimePlayerActionAvailability> actions;
  final GameSessionLoadingProgress? loadingProgress;
  final GameResultSnapshot? result;
  final GameCreditsSnapshot? credits;
  final GameSessionFailure? failure;
  final String? logicalSelectionId;
  final PlayerInputSource? activeInputSource;
  final RuntimeWorldServiceSnapshot? worldService;
  final PlayerPreferencesSnapshot? preferences;
  final bool hasDiscoveredSave;
  final RuntimePlayerSaveAddress? activeSaveAddress;
  final RuntimePlayerSaveReceipt? saveReceipt;
  final Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>
      pauseDetails;

  late final Map<RuntimePlayerAction, RuntimePlayerActionAvailability>
      _actionStates;

  bool isActionEnabled(RuntimePlayerAction action) =>
      _actionStates[action]?.isEnabled ?? false;

  String? unavailableReasonFor(RuntimePlayerAction action) =>
      _actionStates[action]?.unavailableReason;

  RuntimePlayerPauseDetailSnapshot? pauseDetailFor(
    RuntimePlayerPauseSection section,
  ) =>
      pauseDetails[section];

  RuntimePlayerSnapshot next({
    RuntimePlayerPhase? phase,
    String? gameTitle,
    RuntimePlayerPauseSection? pauseSection,
    bool clearPauseSection = false,
    List<RuntimePlayerActionAvailability>? actions,
    GameSessionLoadingProgress? loadingProgress,
    bool clearLoadingProgress = false,
    GameResultSnapshot? result,
    bool clearResult = false,
    GameCreditsSnapshot? credits,
    bool clearCredits = false,
    GameSessionFailure? failure,
    bool clearFailure = false,
    String? logicalSelectionId,
    bool clearLogicalSelection = false,
    PlayerInputSource? activeInputSource,
    bool clearActiveInputSource = false,
    RuntimeWorldServiceSnapshot? worldService,
    bool clearWorldService = false,
    PlayerPreferencesSnapshot? preferences,
    bool? hasDiscoveredSave,
    RuntimePlayerSaveAddress? activeSaveAddress,
    bool clearActiveSaveAddress = false,
    RuntimePlayerSaveReceipt? saveReceipt,
    bool clearSaveReceipt = false,
    Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>?
        pauseDetails,
    bool clearPauseDetails = false,
  }) {
    return RuntimePlayerSnapshot(
      revision: revision + 1,
      phase: phase ?? this.phase,
      gameTitle: gameTitle ?? this.gameTitle,
      pauseSection:
          clearPauseSection ? null : pauseSection ?? this.pauseSection,
      actions: actions ?? this.actions,
      loadingProgress:
          clearLoadingProgress ? null : loadingProgress ?? this.loadingProgress,
      result: clearResult ? null : result ?? this.result,
      credits: clearCredits ? null : credits ?? this.credits,
      failure: clearFailure ? null : failure ?? this.failure,
      logicalSelectionId: clearLogicalSelection
          ? null
          : logicalSelectionId ?? this.logicalSelectionId,
      activeInputSource: clearActiveInputSource
          ? null
          : activeInputSource ?? this.activeInputSource,
      worldService:
          clearWorldService ? null : worldService ?? this.worldService,
      preferences: preferences ?? this.preferences,
      hasDiscoveredSave: hasDiscoveredSave ?? this.hasDiscoveredSave,
      activeSaveAddress: clearActiveSaveAddress
          ? null
          : activeSaveAddress ?? this.activeSaveAddress,
      saveReceipt: clearSaveReceipt ? null : saveReceipt ?? this.saveReceipt,
      pauseDetails: clearPauseDetails
          ? const <RuntimePlayerPauseSection,
              RuntimePlayerPauseDetailSnapshot>{}
          : pauseDetails ?? this.pauseDetails,
    );
  }
}
