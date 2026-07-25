import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

enum PlayerShellState {
  title,
  preparingSession,
  loadingSession,
  playing,
  paused,
  lifecyclePaused,
  completing,
  result,
  credits,
  disposingSession,
  hub,
  error,
}

enum PlayerTitleState {
  titleIdle,
  selectingProfile,
  selectingSlot,
  confirmingOverwrite,
  options,
  creditsAbout,
  titleError,
}

enum PlayerTitleAction {
  continueGame,
  newGame,
  load,
  options,
  creditsAbout,
  returnToHub,
}

enum PlayerLaunchResult {
  started,
  unavailable,
  overwriteConfirmationRequired,
  incompatibleSave,
}

final class PlayerTitleSnapshot {
  PlayerTitleSnapshot({
    required this.state,
    required this.gameTitle,
    required this.author,
    this.description,
    required Set<PlayerTitleAction> enabledActions,
    this.continueAddress,
    this.continueUpdatedAt,
  }) : enabledActions = Set<PlayerTitleAction>.unmodifiable(enabledActions);

  final PlayerTitleState state;
  final String gameTitle;
  final String author;
  final String? description;
  final Set<PlayerTitleAction> enabledActions;
  final SaveSlotAddress? continueAddress;
  final DateTime? continueUpdatedAt;

  PlayerTitleSnapshot copyWith({
    PlayerTitleState? state,
    Set<PlayerTitleAction>? enabledActions,
    SaveSlotAddress? continueAddress,
    bool clearContinue = false,
    DateTime? continueUpdatedAt,
  }) {
    return PlayerTitleSnapshot(
      state: state ?? this.state,
      gameTitle: gameTitle,
      author: author,
      description: description,
      enabledActions: enabledActions ?? this.enabledActions,
      continueAddress:
          clearContinue ? null : continueAddress ?? this.continueAddress,
      continueUpdatedAt:
          clearContinue ? null : continueUpdatedAt ?? this.continueUpdatedAt,
    );
  }
}

final class PlayerShellSnapshot {
  const PlayerShellSnapshot({
    required this.state,
    required this.title,
    this.loadingProgress,
    this.result,
    this.credits,
    this.completionDestination,
    this.failure,
  });

  final PlayerShellState state;
  final PlayerTitleSnapshot title;
  final GameSessionLoadingProgress? loadingProgress;
  final GameResultSnapshot? result;
  final GameCreditsSnapshot? credits;
  final GameCompletionDestination? completionDestination;
  final GameSessionFailure? failure;

  PlayerShellSnapshot copyWith({
    PlayerShellState? state,
    PlayerTitleSnapshot? title,
    GameSessionLoadingProgress? loadingProgress,
    bool clearLoadingProgress = false,
    GameResultSnapshot? result,
    bool clearResult = false,
    GameCreditsSnapshot? credits,
    bool clearCredits = false,
    GameCompletionDestination? completionDestination,
    bool clearCompletionDestination = false,
    GameSessionFailure? failure,
    bool clearFailure = false,
  }) {
    return PlayerShellSnapshot(
      state: state ?? this.state,
      title: title ?? this.title,
      loadingProgress:
          clearLoadingProgress ? null : loadingProgress ?? this.loadingProgress,
      result: clearResult ? null : result ?? this.result,
      credits: clearCredits ? null : credits ?? this.credits,
      completionDestination: clearCompletionDestination
          ? null
          : completionDestination ?? this.completionDestination,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
