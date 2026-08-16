import 'dart:collection';

import 'package:map_core/map_core.dart';

import '../presentation/flame/runtime_input_authority.dart';
import '../presentation/flame/runtime_input_event.dart';

const int gameSessionProtocolVersion = 1;

enum GameSessionLaunchMode { newGame, continueGame, load }

enum GameSessionState {
  idle,
  preparing,
  prepared,
  starting,
  loading,
  running,
  paused,
  lifecyclePaused,
  completing,
  completed,
  failed,
  stopping,
  disposed,
}

enum GameSessionExitReason { title, hub, cancelled, failed, terminated }

enum GameSessionErrorCode {
  invalidDescriptor,
  invalidState,
  sessionAlreadyActive,
  timeout,
  runtime,
  checkpointRejected,
  disposed,
}

enum GameSessionFailureCode {
  compatibility,
  integrity,
  storage,
  save,
  runtime,
  platform,
  protocol,
  contractViolation,
  timeout,
}

enum GameSessionFailureRecoverability { retry, titleOrHub, hubOnly, repair }

enum GameSessionDiagnosticSeverity { info, warning, error }

enum GameCompletionOutcome { completed, victory, alternateEnding }

enum GameCompletionDestination { title, hub, playerChoice }

/// Player options transported as data so the same descriptor can cross IPC.
final class GameSessionAccessibilityOptions {
  const GameSessionAccessibilityOptions({
    this.reducedMotion = false,
    this.textScale = 1,
    this.hapticsEnabled = true,
  }) : assert(textScale > 0);

  final bool reducedMotion;
  final double textScale;
  final bool hapticsEnabled;

  GameSessionAccessibilityOptions copyWith({
    bool? reducedMotion,
    double? textScale,
    bool? hapticsEnabled,
  }) =>
      GameSessionAccessibilityOptions(
        reducedMotion: reducedMotion ?? this.reducedMotion,
        textScale: textScale ?? this.textScale,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      );
}

final class GameSessionPlayerIdentity {
  GameSessionPlayerIdentity({
    required String name,
    String? avatarCharacterId,
    this.pronounSet = PlayerPronounSet.neutral,
  })  : name = name.trim(),
        avatarCharacterId = _normalizeOptional(avatarCharacterId) {
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
  }

  final String name;
  final String? avatarCharacterId;
  final PlayerPronounSet pronounSet;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSessionPlayerIdentity &&
          other.name == name &&
          other.avatarCharacterId == avatarCharacterId &&
          other.pronounSet == pronounSet;

  @override
  int get hashCode => Object.hash(name, avatarCharacterId, pronounSet);
}

/// Immutable launch authority created by the embedding host.
///
/// The installed version and save are opaque handles. Filesystem paths and
/// save payloads deliberately stay outside this transport contract.
final class GameSessionDescriptor {
  GameSessionDescriptor({
    this.protocolVersion = gameSessionProtocolVersion,
    required this.sessionId,
    required this.sessionToken,
    required this.identity,
    required this.profileId,
    required this.slotId,
    required this.launchMode,
    required this.installedVersionHandle,
    this.saveReadHandle,
    required this.runtimeApiVersion,
    required Set<String> grantedCapabilities,
    required this.locale,
    required this.accessibility,
    this.initialGameState,
  }) : grantedCapabilities = Set<String>.unmodifiable(grantedCapabilities) {
    if (protocolVersion != gameSessionProtocolVersion) {
      throw const GameSessionException(
        GameSessionErrorCode.invalidDescriptor,
        'Unsupported session protocol version.',
      );
    }
    _requireOpaque(sessionId, 'sessionId');
    _requireOpaque(sessionToken, 'sessionToken');
    _requireOpaque(installedVersionHandle, 'installedVersionHandle');
    _requireOpaque(runtimeApiVersion, 'runtimeApiVersion');
    _requireOpaque(locale, 'locale');
    GameIdentity.validateLocalId(profileId, path: r'$.profileId');
    GameIdentity.validateLocalId(slotId, path: r'$.slotId');
    if (launchMode == GameSessionLaunchMode.newGame && saveReadHandle != null) {
      throw const GameSessionException(
        GameSessionErrorCode.invalidDescriptor,
        'A new game descriptor cannot expose a save read handle.',
      );
    }
    if (launchMode != GameSessionLaunchMode.newGame &&
        (saveReadHandle == null || saveReadHandle!.trim().isEmpty)) {
      throw const GameSessionException(
        GameSessionErrorCode.invalidDescriptor,
        'Continue and Load descriptors require an opaque save read handle.',
      );
    }
    if (launchMode == GameSessionLaunchMode.newGame &&
        initialGameState == null) {
      throw const GameSessionException(
        GameSessionErrorCode.invalidDescriptor,
        'A new game descriptor requires its committed initial GameState.',
      );
    }
    if (launchMode != GameSessionLaunchMode.newGame &&
        initialGameState != null) {
      throw const GameSessionException(
        GameSessionErrorCode.invalidDescriptor,
        'Only a new game descriptor can provide an initial GameState.',
      );
    }
    if (initialGameState != null &&
        initialGameState!.currentMapId.trim().isEmpty) {
      throw const GameSessionException(
        GameSessionErrorCode.invalidDescriptor,
        'The initial GameState must target a map.',
      );
    }
  }

  final int protocolVersion;
  final String sessionId;

  /// Secret capability used only by the selected adapter.
  ///
  /// It is intentionally omitted from [toString] and every public snapshot.
  final String sessionToken;
  final GameIdentity identity;
  final String profileId;
  final String slotId;
  final GameSessionLaunchMode launchMode;
  final String installedVersionHandle;
  final String? saveReadHandle;
  final String runtimeApiVersion;
  final Set<String> grantedCapabilities;
  final String locale;
  final GameSessionAccessibilityOptions accessibility;
  final GameState? initialGameState;

  GameSessionPublicContext get publicContext => GameSessionPublicContext(
        protocolVersion: protocolVersion,
        sessionId: sessionId,
        identity: identity,
        profileId: profileId,
        slotId: slotId,
        launchMode: launchMode,
        runtimeApiVersion: runtimeApiVersion,
        grantedCapabilities: grantedCapabilities,
        locale: locale,
        accessibility: accessibility,
      );

  @override
  String toString() {
    return 'GameSessionDescriptor('
        'protocolVersion: $protocolVersion, '
        'sessionId: $sessionId, '
        'gameId: ${identity.gameId}, '
        'gameVersion: ${identity.gameVersion}, '
        'profileId: $profileId, '
        'slotId: $slotId, '
        'launchMode: ${launchMode.name})';
  }
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

/// Player-safe projection of a session descriptor.
///
/// Adapter-only capabilities and storage handles never cross into public
/// snapshots or save commit callbacks.
final class GameSessionPublicContext {
  GameSessionPublicContext({
    required this.protocolVersion,
    required this.sessionId,
    required this.identity,
    required this.profileId,
    required this.slotId,
    required this.launchMode,
    required this.runtimeApiVersion,
    required Set<String> grantedCapabilities,
    required this.locale,
    required this.accessibility,
  }) : grantedCapabilities = Set<String>.unmodifiable(grantedCapabilities);

  final int protocolVersion;
  final String sessionId;
  final GameIdentity identity;
  final String profileId;
  final String slotId;
  final GameSessionLaunchMode launchMode;
  final String runtimeApiVersion;
  final Set<String> grantedCapabilities;
  final String locale;
  final GameSessionAccessibilityOptions accessibility;

  @override
  String toString() {
    return 'GameSessionPublicContext('
        'protocolVersion: $protocolVersion, '
        'sessionId: $sessionId, '
        'gameId: ${identity.gameId}, '
        'gameVersion: ${identity.gameVersion}, '
        'profileId: $profileId, '
        'slotId: $slotId, '
        'launchMode: ${launchMode.name})';
  }
}

final class GameSessionLoadingProgress {
  const GameSessionLoadingProgress({
    required this.stage,
    required this.current,
    this.total,
  })  : assert(stage != ''),
        assert(current >= 0),
        assert(total == null || total >= current);

  final String stage;
  final int current;
  final int? total;
}

/// Runtime-owned state proposed to the Hub, never persisted by the runtime.
final class GameSessionCheckpoint {
  GameSessionCheckpoint({
    required this.saveId,
    required this.createdAt,
    required this.updatedAt,
    required this.playTimeSeconds,
    required Map<String, Object?> state,
  }) : state = UnmodifiableMapView<String, Object?>(
          Map<String, Object?>.from(state),
        ) {
    _requireOpaque(saveId, 'saveId');
    if (playTimeSeconds < 0 || updatedAt.isBefore(createdAt)) {
      throw const GameSessionException(
        GameSessionErrorCode.invalidDescriptor,
        'Invalid checkpoint timeline.',
      );
    }
  }

  final String saveId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int playTimeSeconds;
  final Map<String, Object?> state;
}

enum GameSessionCheckpointTrigger {
  manual,
  pauseMutation,
  defeatRecovery,
  lifecyclePause,
  sessionExit,
  completion,
}

extension GameSessionCheckpointTriggerPolicy on GameSessionCheckpointTrigger {
  bool get isAutosave =>
      this != GameSessionCheckpointTrigger.manual &&
      this != GameSessionCheckpointTrigger.completion;
}

final class GameSessionSavePolicy {
  const GameSessionSavePolicy({
    this.autosaveAfterPauseMutation = true,
    this.autosaveOnLifecyclePause = true,
    this.autosaveOnSessionExit = true,
  });

  final bool autosaveAfterPauseMutation;
  final bool autosaveOnLifecyclePause;
  final bool autosaveOnSessionExit;
}

final class GameResultSnapshot {
  const GameResultSnapshot({
    required this.title,
    required this.summary,
    this.details = const <String>[],
  });

  final String title;
  final String summary;
  final List<String> details;
}

final class GameCreditsSnapshot {
  const GameCreditsSnapshot({
    required this.title,
    required this.author,
    this.contributors = const <String>[],
    this.licenses = const <String>[],
    required this.endingLabel,
    this.skippable = true,
  });

  final String title;
  final String author;
  final List<String> contributors;
  final List<String> licenses;
  final String endingLabel;
  final bool skippable;
}

/// Runtime-facing request produced by a future no-code "Finish game" command.
///
/// The runtime adds identity, timing and the final checkpoint. Keeping this
/// request data-only prevents authored content from supplying executable UI.
final class GameCompletionRequest {
  const GameCompletionRequest({
    required this.endingId,
    required this.outcome,
    required this.result,
    required this.credits,
    required this.destination,
    required this.allowPostGameContinue,
  });

  final String endingId;
  final GameCompletionOutcome outcome;
  final GameResultSnapshot result;
  final GameCreditsSnapshot credits;
  final GameCompletionDestination destination;
  final bool allowPostGameContinue;
}

/// Canonical terminal runtime event. The Hub de-duplicates by session+ending.
final class GameCompletionEvent {
  GameCompletionEvent({
    this.eventVersion = 1,
    required this.sessionId,
    required this.gameId,
    required this.endingId,
    required this.outcome,
    required this.completedAt,
    required this.playTimeSeconds,
    required this.result,
    required this.credits,
    required this.destination,
    required this.allowPostGameContinue,
    required this.finalCheckpoint,
  }) {
    if (eventVersion != 1 ||
        sessionId.trim().isEmpty ||
        endingId.trim().isEmpty ||
        playTimeSeconds < 0 ||
        finalCheckpoint.playTimeSeconds != playTimeSeconds) {
      throw const GameSessionException(
        GameSessionErrorCode.invalidDescriptor,
        'Invalid GameCompleted event.',
      );
    }
    GameIdentity.validateGameId(gameId);
  }

  final int eventVersion;
  final String sessionId;
  final String gameId;
  final String endingId;
  final GameCompletionOutcome outcome;
  final DateTime completedAt;
  final int playTimeSeconds;
  final GameResultSnapshot result;
  final GameCreditsSnapshot credits;
  final GameCompletionDestination destination;
  final bool allowPostGameContinue;
  final GameSessionCheckpoint finalCheckpoint;

  String get idempotencyKey => '$sessionId::$endingId';
}

final class GameSessionCheckpointCommit {
  const GameSessionCheckpointCommit({
    required this.descriptor,
    required this.checkpoint,
    required this.status,
    this.trigger = GameSessionCheckpointTrigger.manual,
    this.completedAt,
  });

  final GameSessionPublicContext descriptor;
  final GameSessionCheckpoint checkpoint;
  final SaveStatus status;
  final GameSessionCheckpointTrigger trigger;
  final DateTime? completedAt;

  bool get isAutosave => trigger.isAutosave;
}

typedef GameSessionCheckpointCommitter = Future<void> Function(
  GameSessionCheckpointCommit request,
);

final class GameSessionFailure {
  const GameSessionFailure({
    required this.code,
    required this.recoverability,
    this.safeMessage,
  });

  final GameSessionFailureCode code;
  final GameSessionFailureRecoverability recoverability;
  final String? safeMessage;
}

final class GameSessionDiagnosticData {
  const GameSessionDiagnosticData({
    required this.code,
    required this.severity,
    this.safeDetails = const <String, String>{},
  });

  final String code;
  final GameSessionDiagnosticSeverity severity;
  final Map<String, String> safeDetails;
}

final class GameSessionSnapshot {
  const GameSessionSnapshot({
    required this.state,
    this.descriptor,
    this.loadingProgress,
    this.lifecycleResumeState,
    this.failure,
    this.exitReason,
    this.lastDiagnostic,
    this.pendingCompletion,
    this.completionCommitFailed = false,
  });

  const GameSessionSnapshot.idle() : this(state: GameSessionState.idle);

  final GameSessionState state;
  final GameSessionPublicContext? descriptor;
  final GameSessionLoadingProgress? loadingProgress;
  final GameSessionState? lifecycleResumeState;
  final GameSessionFailure? failure;
  final GameSessionExitReason? exitReason;
  final GameSessionDiagnosticData? lastDiagnostic;
  final GameCompletionEvent? pendingCompletion;
  final bool completionCommitFailed;

  GameSessionSnapshot copyWith({
    GameSessionState? state,
    GameSessionLoadingProgress? loadingProgress,
    bool clearLoadingProgress = false,
    GameSessionState? lifecycleResumeState,
    bool clearLifecycleResumeState = false,
    GameSessionFailure? failure,
    bool clearFailure = false,
    GameSessionExitReason? exitReason,
    bool clearExitReason = false,
    GameSessionDiagnosticData? lastDiagnostic,
    bool clearLastDiagnostic = false,
    GameCompletionEvent? pendingCompletion,
    bool clearPendingCompletion = false,
    bool? completionCommitFailed,
  }) {
    return GameSessionSnapshot(
      state: state ?? this.state,
      descriptor: descriptor,
      loadingProgress:
          clearLoadingProgress ? null : loadingProgress ?? this.loadingProgress,
      lifecycleResumeState: clearLifecycleResumeState
          ? null
          : lifecycleResumeState ?? this.lifecycleResumeState,
      failure: clearFailure ? null : failure ?? this.failure,
      exitReason: clearExitReason ? null : exitReason ?? this.exitReason,
      lastDiagnostic:
          clearLastDiagnostic ? null : lastDiagnostic ?? this.lastDiagnostic,
      pendingCompletion: clearPendingCompletion
          ? null
          : pendingCompletion ?? this.pendingCompletion,
      completionCommitFailed:
          completionCommitFailed ?? this.completionCommitFailed,
    );
  }
}

sealed class GameSessionAdapterEvent {
  const GameSessionAdapterEvent(this.sessionId);

  final String sessionId;
}

final class GameSessionReady extends GameSessionAdapterEvent {
  const GameSessionReady(super.sessionId);
}

final class GameSessionLoading extends GameSessionAdapterEvent {
  const GameSessionLoading(super.sessionId, this.progress);

  final GameSessionLoadingProgress progress;
}

final class GameSessionRunning extends GameSessionAdapterEvent {
  const GameSessionRunning(super.sessionId);
}

final class GameSessionPaused extends GameSessionAdapterEvent {
  const GameSessionPaused(super.sessionId);
}

final class GameSessionCheckpointRequested extends GameSessionAdapterEvent {
  const GameSessionCheckpointRequested(super.sessionId, this.trigger);

  final GameSessionCheckpointTrigger trigger;
}

final class GameSessionCompleted extends GameSessionAdapterEvent {
  GameSessionCompleted(this.completion) : super(completion.sessionId);

  final GameCompletionEvent completion;
}

final class GameSessionReturnRequested extends GameSessionAdapterEvent {
  const GameSessionReturnRequested(super.sessionId, this.reason);

  final GameSessionExitReason reason;
}

final class GameSessionHeartbeat extends GameSessionAdapterEvent {
  const GameSessionHeartbeat(super.sessionId, this.monotonicMillis);

  final int monotonicMillis;
}

final class GameSessionDiagnostic extends GameSessionAdapterEvent {
  const GameSessionDiagnostic(super.sessionId, this.diagnostic);

  final GameSessionDiagnosticData diagnostic;
}

final class GameSessionFatal extends GameSessionAdapterEvent {
  const GameSessionFatal(super.sessionId, this.failure);

  final GameSessionFailure failure;
}

abstract interface class GameSessionInputLockPort {
  Future<void> setInputLock(
    RuntimeExternalInputLock owner, {
    required bool locked,
  });
}

abstract interface class GameSessionAdapter {
  Stream<GameSessionAdapterEvent> get events;

  Future<void> prepare(GameSessionDescriptor descriptor);
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<GameSessionCheckpoint?> captureCheckpoint();
  Future<void> lockGameplayForCompletion();
  Future<void> acknowledgeCompletion({required bool accepted});
  Future<void> stop(GameSessionExitReason reason);
  Future<void> dispose();
  bool handleInput(RuntimeInputEvent event);
}

typedef GameSessionAdapterFactory = GameSessionAdapter Function(
  GameSessionDescriptor descriptor,
);

final class GameSessionException implements Exception {
  const GameSessionException(this.code, this.message, {this.cause});

  final GameSessionErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'GameSessionException(${code.name}): $message';
}

void _requireOpaque(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty ||
      normalized.length > 256 ||
      normalized.contains('\u0000') ||
      normalized.contains('\n') ||
      normalized.contains('\r')) {
    throw GameSessionException(
      GameSessionErrorCode.invalidDescriptor,
      'Invalid opaque $field.',
    );
  }
}
