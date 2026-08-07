import 'dart:async';

import 'package:map_core/map_core.dart';

enum HubLifecycleResultCode {
  checkpointSaved,
  checkpointNotNeeded,
  checkpointTimedOut,
  checkpointFailed,
  sessionResumed,
  sessionInvalid,
  resumeFailed,
  exitAllowed,
  exitAllowedAfterAbandon,
  exitBlocked,
}

final class HubLifecycleResult {
  const HubLifecycleResult({
    required this.code,
    required this.acknowledged,
    this.cause,
  });

  final HubLifecycleResultCode code;
  final bool acknowledged;
  final Object? cause;
}

typedef SuspendGameSession = Future<void> Function();
typedef CaptureSaveCheckpoint = Future<SaveEnvelope?> Function();
typedef PersistSaveCheckpoint = Future<void> Function(SaveEnvelope envelope);
typedef ValidateGameSession = Future<bool> Function();
typedef ResumeGameSession = Future<void> Function();

/// Serializes app lifecycle transitions around a bounded, atomic checkpoint.
final class HubSaveLifecycleCoordinator {
  HubSaveLifecycleCoordinator({
    required SuspendGameSession suspendSession,
    required CaptureSaveCheckpoint captureCheckpoint,
    required PersistSaveCheckpoint persistCheckpoint,
    required ValidateGameSession validateSession,
    required ResumeGameSession resumeSession,
    required this.checkpointTimeout,
  })  : _suspendSession = suspendSession,
        _captureCheckpoint = captureCheckpoint,
        _persistCheckpoint = persistCheckpoint,
        _validateSession = validateSession,
        _resumeSession = resumeSession {
    if (checkpointTimeout <= Duration.zero) {
      throw ArgumentError.value(
        checkpointTimeout,
        'checkpointTimeout',
        'Checkpoint timeout must be positive.',
      );
    }
  }

  final SuspendGameSession _suspendSession;
  final CaptureSaveCheckpoint _captureCheckpoint;
  final PersistSaveCheckpoint _persistCheckpoint;
  final ValidateGameSession _validateSession;
  final ResumeGameSession _resumeSession;
  final Duration checkpointTimeout;

  Future<HubLifecycleResult>? _backgroundTransition;

  Future<HubLifecycleResult> onBackgrounded() {
    final existing = _backgroundTransition;
    if (existing != null) return existing;
    final transition = _runBackgroundTransition();
    _backgroundTransition = transition;
    unawaited(
      transition.whenComplete(() {
        if (identical(_backgroundTransition, transition)) {
          _backgroundTransition = null;
        }
      }),
    );
    return transition;
  }

  Future<HubLifecycleResult> _runBackgroundTransition() async {
    final stopwatch = Stopwatch()..start();
    try {
      await _suspendSession();
      final checkpoint = await _captureCheckpoint().timeout(
        _remaining(stopwatch),
      );
      if (checkpoint == null) {
        return const HubLifecycleResult(
          code: HubLifecycleResultCode.checkpointNotNeeded,
          acknowledged: true,
        );
      }
      await _persistCheckpoint(checkpoint).timeout(_remaining(stopwatch));
      return const HubLifecycleResult(
        code: HubLifecycleResultCode.checkpointSaved,
        acknowledged: true,
      );
    } on TimeoutException catch (error) {
      return HubLifecycleResult(
        code: HubLifecycleResultCode.checkpointTimedOut,
        acknowledged: true,
        cause: error,
      );
    } catch (error) {
      return HubLifecycleResult(
        code: HubLifecycleResultCode.checkpointFailed,
        acknowledged: true,
        cause: error,
      );
    } finally {
      stopwatch.stop();
    }
  }

  Future<HubLifecycleResult> onForegrounded() async {
    final background = _backgroundTransition;
    if (background != null) await background;
    try {
      if (!await _validateSession()) {
        return const HubLifecycleResult(
          code: HubLifecycleResultCode.sessionInvalid,
          acknowledged: true,
        );
      }
      await _resumeSession();
      return const HubLifecycleResult(
        code: HubLifecycleResultCode.sessionResumed,
        acknowledged: true,
      );
    } catch (error) {
      return HubLifecycleResult(
        code: HubLifecycleResultCode.resumeFailed,
        acknowledged: true,
        cause: error,
      );
    }
  }

  Future<HubLifecycleResult> requestExit({
    required bool abandonUnsavedChanges,
  }) async {
    final checkpoint = await onBackgrounded();
    if (checkpoint.code == HubLifecycleResultCode.checkpointSaved ||
        checkpoint.code == HubLifecycleResultCode.checkpointNotNeeded) {
      return const HubLifecycleResult(
        code: HubLifecycleResultCode.exitAllowed,
        acknowledged: true,
      );
    }
    if (abandonUnsavedChanges) {
      return HubLifecycleResult(
        code: HubLifecycleResultCode.exitAllowedAfterAbandon,
        acknowledged: true,
        cause: checkpoint.cause,
      );
    }
    return HubLifecycleResult(
      code: HubLifecycleResultCode.exitBlocked,
      acknowledged: false,
      cause: checkpoint.cause,
    );
  }

  Duration _remaining(Stopwatch stopwatch) {
    final remaining = checkpointTimeout - stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException(
        'Lifecycle checkpoint exceeded $checkpointTimeout.',
        checkpointTimeout,
      );
    }
    return remaining;
  }
}
