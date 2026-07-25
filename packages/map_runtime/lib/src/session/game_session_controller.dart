import 'dart:async';

import 'package:map_core/map_core.dart';

import '../presentation/flame/runtime_input_event.dart';
import 'game_session_contract.dart';

/// Authoritative session state machine shared by in-process and child adapters.
///
/// The controller never reads package paths and never persists saves itself.
/// Both authorities are injected by the Hub, which keeps this facade usable by
/// the developer host without creating a dependency on the Hub application.
final class GameSessionController {
  GameSessionController({
    required GameSessionAdapterFactory adapterFactory,
    required GameSessionCheckpointCommitter commitCheckpoint,
    this.prepareTimeout = const Duration(seconds: 30),
    this.startTimeout = const Duration(seconds: 30),
    this.stopTimeout = const Duration(seconds: 5),
  })  : _adapterFactory = adapterFactory,
        _commitCheckpoint = commitCheckpoint {
    if (prepareTimeout <= Duration.zero ||
        startTimeout <= Duration.zero ||
        stopTimeout <= Duration.zero) {
      throw ArgumentError('Session timeouts must be positive.');
    }
  }

  final GameSessionAdapterFactory _adapterFactory;
  final GameSessionCheckpointCommitter _commitCheckpoint;
  final Duration prepareTimeout;
  final Duration startTimeout;
  final Duration stopTimeout;

  final _snapshots = StreamController<GameSessionSnapshot>.broadcast();
  Future<void> _tail = Future<void>.value();
  GameSessionSnapshot _snapshot = const GameSessionSnapshot.idle();
  GameSessionDescriptor? _descriptor;
  GameSessionAdapter? _adapter;
  StreamSubscription<GameSessionAdapterEvent>? _adapterEvents;
  bool _controllerDisposed = false;
  final Set<String> _completionKeys = <String>{};
  GameCompletionEvent? _pendingCompletion;
  GameCompletionEvent? _committedCompletion;

  GameSessionSnapshot get snapshot => _snapshot;
  Stream<GameSessionSnapshot> get snapshots => _snapshots.stream;
  GameCompletionEvent? get committedCompletion => _committedCompletion;

  Future<void> prepare(GameSessionDescriptor descriptor) {
    return _serialize(() async {
      _ensureControllerOpen();
      if (_adapter != null ||
          (_snapshot.state != GameSessionState.idle &&
              _snapshot.state != GameSessionState.disposed)) {
        throw const GameSessionException(
          GameSessionErrorCode.sessionAlreadyActive,
          'A session must be fully disposed before another launch.',
        );
      }
      _completionKeys.clear();
      _pendingCompletion = null;
      _committedCompletion = null;
      _descriptor = descriptor;
      _publish(
        GameSessionSnapshot(
          state: GameSessionState.preparing,
          descriptor: descriptor.publicContext,
        ),
      );

      try {
        final adapter = _adapterFactory(descriptor);
        _adapter = adapter;
        _adapterEvents = adapter.events.listen(
          (event) {
            if (_handleLoadingSignal(event)) return;
            unawaited(_serialize(() => _handleAdapterEvent(event)));
          },
          onError: (Object error, StackTrace stackTrace) {
            unawaited(
              _serialize(
                () => _fail(
                  const GameSessionFailure(
                    code: GameSessionFailureCode.runtime,
                    recoverability: GameSessionFailureRecoverability.titleOrHub,
                    safeMessage: 'The runtime event channel failed.',
                  ),
                ),
              ),
            );
          },
        );
        await adapter.prepare(descriptor).timeout(prepareTimeout);
        _publish(_snapshot.copyWith(state: GameSessionState.prepared));
      } on TimeoutException catch (error) {
        await _failAndDispose(
          const GameSessionFailure(
            code: GameSessionFailureCode.timeout,
            recoverability: GameSessionFailureRecoverability.retry,
            safeMessage: 'The player session did not prepare in time.',
          ),
          cause: error,
        );
        rethrow;
      } catch (error) {
        await _failAndDispose(
          const GameSessionFailure(
            code: GameSessionFailureCode.runtime,
            recoverability: GameSessionFailureRecoverability.retry,
            safeMessage: 'The player session could not be prepared.',
          ),
          cause: error,
        );
        rethrow;
      }
    });
  }

  Future<void> start() {
    return _serialize(() async {
      _requireState(<GameSessionState>{GameSessionState.prepared}, 'start');
      _publish(_snapshot.copyWith(state: GameSessionState.starting));
      try {
        await _adapter!.start().timeout(startTimeout);
      } on TimeoutException catch (error) {
        await _fail(
          const GameSessionFailure(
            code: GameSessionFailureCode.timeout,
            recoverability: GameSessionFailureRecoverability.retry,
            safeMessage: 'The player session did not start in time.',
          ),
        );
        throw GameSessionException(
          GameSessionErrorCode.timeout,
          'Session start timed out.',
          cause: error,
        );
      } catch (error) {
        await _fail(
          const GameSessionFailure(
            code: GameSessionFailureCode.runtime,
            recoverability: GameSessionFailureRecoverability.retry,
            safeMessage: 'The player session could not be started.',
          ),
        );
        throw GameSessionException(
          GameSessionErrorCode.runtime,
          'Session start failed.',
          cause: error,
        );
      }
    });
  }

  Future<void> pause() {
    return _serialize(() async {
      _requireState(<GameSessionState>{GameSessionState.running}, 'pause');
      await _adapter!.pause();
      _publish(_snapshot.copyWith(state: GameSessionState.paused));
    });
  }

  Future<void> resume() {
    return _serialize(() async {
      _requireState(<GameSessionState>{GameSessionState.paused}, 'resume');
      await _adapter!.resume();
      _publish(_snapshot.copyWith(state: GameSessionState.running));
    });
  }

  Future<void> pauseForLifecycle() {
    return _serialize(() async {
      const allowed = <GameSessionState>{
        GameSessionState.starting,
        GameSessionState.loading,
        GameSessionState.running,
        GameSessionState.paused,
      };
      _requireState(allowed, 'pauseForLifecycle');
      final resumeState = _snapshot.state;
      if (resumeState != GameSessionState.paused) {
        await _adapter!.pause();
      }
      _publish(
        _snapshot.copyWith(
          state: GameSessionState.lifecyclePaused,
          lifecycleResumeState: resumeState,
        ),
      );
    });
  }

  Future<void> resumeFromLifecycle() {
    return _serialize(() async {
      _requireState(
        <GameSessionState>{GameSessionState.lifecyclePaused},
        'resumeFromLifecycle',
      );
      final target = _snapshot.lifecycleResumeState;
      if (target == null) {
        throw const GameSessionException(
          GameSessionErrorCode.invalidState,
          'Lifecycle resume state is missing.',
        );
      }
      if (target != GameSessionState.paused) {
        await _adapter!.resume();
      }
      _publish(
        _snapshot.copyWith(
          state: target,
          clearLifecycleResumeState: true,
        ),
      );
    });
  }

  Future<bool> requestCheckpoint() {
    return _serialize(() async {
      _requireState(
        const <GameSessionState>{
          GameSessionState.running,
          GameSessionState.paused,
          GameSessionState.completing,
        },
        'requestCheckpoint',
      );
      return _captureAndCommit(SaveStatus.active);
    });
  }

  Future<void> retryCompletion() {
    return _serialize(() async {
      _requireState(
        <GameSessionState>{GameSessionState.completing},
        'retryCompletion',
      );
      final completion = _pendingCompletion;
      if (completion == null || !_snapshot.completionCommitFailed) {
        throw const GameSessionException(
          GameSessionErrorCode.invalidState,
          'No failed completion checkpoint is available for retry.',
        );
      }
      await _commitCompletion(completion);
    });
  }

  Future<void> returnToTitle({
    bool checkpoint = true,
    bool abandonCheckpointFailure = false,
  }) {
    return _serialize(
      () => _stopSession(
        GameSessionExitReason.title,
        checkpoint: checkpoint,
        abandonCheckpointFailure: abandonCheckpointFailure,
      ),
    );
  }

  Future<void> returnToHub({
    bool checkpoint = true,
    bool abandonCheckpointFailure = false,
  }) {
    return _serialize(
      () => _stopSession(
        GameSessionExitReason.hub,
        checkpoint: checkpoint,
        abandonCheckpointFailure: abandonCheckpointFailure,
      ),
    );
  }

  Future<void> cancelLoading() {
    return _serialize(() async {
      _requireState(
        const <GameSessionState>{
          GameSessionState.starting,
          GameSessionState.loading,
        },
        'cancelLoading',
      );
      await _stopSession(
        GameSessionExitReason.cancelled,
        checkpoint: false,
        abandonCheckpointFailure: true,
      );
    });
  }

  Future<void> terminate() {
    return _serialize(() async {
      if (_adapter == null) return;
      await _stopSession(
        GameSessionExitReason.terminated,
        checkpoint: false,
        abandonCheckpointFailure: true,
      );
    });
  }

  bool handleInput(RuntimeInputEvent event) {
    if (_snapshot.state != GameSessionState.running || _adapter == null) {
      return false;
    }
    return _adapter!.handleInput(event);
  }

  /// Waits for stream callbacks already delivered to the controller queue.
  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await _tail;
    await Future<void>.delayed(Duration.zero);
    await _tail;
  }

  Future<void> dispose() async {
    if (_controllerDisposed) return;
    await terminate();
    _controllerDisposed = true;
    await _snapshots.close();
  }

  /// Loading signals are presentation-only and may arrive while [start] owns
  /// the serialized command queue. Publishing them immediately keeps progress
  /// visible without allowing terminal events to race lifecycle operations.
  bool _handleLoadingSignal(GameSessionAdapterEvent event) {
    if (event is! GameSessionReady && event is! GameSessionLoading) {
      return false;
    }
    final descriptor = _descriptor;
    if (descriptor == null || event.sessionId != descriptor.sessionId) {
      _publish(
        _snapshot.copyWith(
          lastDiagnostic: const GameSessionDiagnosticData(
            code: 'session.event.stale',
            severity: GameSessionDiagnosticSeverity.warning,
          ),
        ),
      );
      return true;
    }
    if (event case GameSessionLoading(:final progress)) {
      if (_snapshot.state == GameSessionState.starting ||
          _snapshot.state == GameSessionState.loading) {
        _publish(
          _snapshot.copyWith(
            state: GameSessionState.loading,
            loadingProgress: progress,
          ),
        );
      }
      return true;
    }
    if (_snapshot.state == GameSessionState.starting) {
      _publish(_snapshot.copyWith(state: GameSessionState.loading));
    }
    return true;
  }

  Future<void> _handleAdapterEvent(GameSessionAdapterEvent event) async {
    final descriptor = _descriptor;
    if (descriptor == null || event.sessionId != descriptor.sessionId) {
      _publish(
        _snapshot.copyWith(
          lastDiagnostic: const GameSessionDiagnosticData(
            code: 'session.event.stale',
            severity: GameSessionDiagnosticSeverity.warning,
          ),
        ),
      );
      return;
    }
    switch (event) {
      case GameSessionReady():
        if (_snapshot.state == GameSessionState.starting) {
          _publish(_snapshot.copyWith(state: GameSessionState.loading));
        }
      case GameSessionLoading():
        if (_snapshot.state == GameSessionState.starting ||
            _snapshot.state == GameSessionState.loading) {
          _publish(
            _snapshot.copyWith(
              state: GameSessionState.loading,
              loadingProgress: event.progress,
            ),
          );
        }
      case GameSessionRunning():
        if (_snapshot.state == GameSessionState.starting ||
            _snapshot.state == GameSessionState.loading) {
          _publish(_snapshot.copyWith(state: GameSessionState.running));
        }
      case GameSessionPaused():
        if (_snapshot.state == GameSessionState.running) {
          _publish(_snapshot.copyWith(state: GameSessionState.paused));
        }
      case GameSessionCompleted():
        await _receiveCompletion(event.completion);
      case GameSessionReturnRequested():
        _publish(
          _snapshot.copyWith(
            lastDiagnostic: GameSessionDiagnosticData(
              code: 'session.return.${event.reason.name}',
              severity: GameSessionDiagnosticSeverity.info,
            ),
          ),
        );
      case GameSessionHeartbeat():
        if (event.monotonicMillis < 0) {
          await _fail(
            const GameSessionFailure(
              code: GameSessionFailureCode.protocol,
              recoverability: GameSessionFailureRecoverability.hubOnly,
              safeMessage: 'The session heartbeat was invalid.',
            ),
          );
        }
      case GameSessionDiagnostic():
        _publish(
          _snapshot.copyWith(lastDiagnostic: event.diagnostic),
        );
      case GameSessionFatal():
        await _fail(event.failure);
    }
  }

  Future<void> _receiveCompletion(GameCompletionEvent completion) async {
    final descriptor = _descriptor!;
    if (_completionKeys.contains(completion.idempotencyKey)) return;
    _completionKeys.add(completion.idempotencyKey);
    await _adapter!.lockGameplayForCompletion();
    if (completion.sessionId != descriptor.sessionId ||
        completion.gameId != descriptor.identity.gameId) {
      await _fail(
        const GameSessionFailure(
          code: GameSessionFailureCode.contractViolation,
          recoverability: GameSessionFailureRecoverability.hubOnly,
          safeMessage: 'The completion event did not match this session.',
        ),
      );
      return;
    }
    if (_snapshot.state != GameSessionState.running &&
        _snapshot.state != GameSessionState.paused) {
      await _fail(
        const GameSessionFailure(
          code: GameSessionFailureCode.contractViolation,
          recoverability: GameSessionFailureRecoverability.hubOnly,
          safeMessage: 'The completion event arrived in an invalid state.',
        ),
      );
      return;
    }
    _pendingCompletion = completion;
    _publish(
      _snapshot.copyWith(
        state: GameSessionState.completing,
        pendingCompletion: completion,
        completionCommitFailed: false,
      ),
    );
    await _commitCompletion(completion);
  }

  Future<void> _commitCompletion(GameCompletionEvent completion) async {
    try {
      await _commitCheckpoint(
        GameSessionCheckpointCommit(
          descriptor: _snapshot.descriptor!,
          checkpoint: completion.finalCheckpoint,
          status: SaveStatus.completed,
          completedAt: completion.completedAt,
        ),
      );
      await _adapter!.acknowledgeCompletion(accepted: true);
      _committedCompletion = completion;
      _pendingCompletion = null;
      _publish(
        _snapshot.copyWith(
          state: GameSessionState.completed,
          clearPendingCompletion: true,
          completionCommitFailed: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      try {
        await _adapter!.acknowledgeCompletion(accepted: false);
      } on Object {
        // The storage error remains the actionable failure for the player.
      }
      _publish(
        _snapshot.copyWith(
          state: GameSessionState.completing,
          pendingCompletion: completion,
          completionCommitFailed: true,
          failure: const GameSessionFailure(
            code: GameSessionFailureCode.storage,
            recoverability: GameSessionFailureRecoverability.retry,
            safeMessage: 'The final checkpoint could not be saved.',
          ),
        ),
      );
    }
  }

  Future<bool> _captureAndCommit(SaveStatus status) async {
    final checkpoint = await _adapter!.captureCheckpoint();
    if (checkpoint == null) return true;
    try {
      await _commitCheckpoint(
        GameSessionCheckpointCommit(
          descriptor: _snapshot.descriptor!,
          checkpoint: checkpoint,
          status: status,
        ),
      );
      return true;
    } catch (error) {
      _publish(
        _snapshot.copyWith(
          failure: const GameSessionFailure(
            code: GameSessionFailureCode.storage,
            recoverability: GameSessionFailureRecoverability.retry,
            safeMessage: 'The checkpoint could not be saved.',
          ),
        ),
      );
      return false;
    }
  }

  Future<void> _stopSession(
    GameSessionExitReason reason, {
    required bool checkpoint,
    required bool abandonCheckpointFailure,
  }) async {
    if (_adapter == null) {
      throw const GameSessionException(
        GameSessionErrorCode.invalidState,
        'No active session exists.',
      );
    }
    const stoppable = <GameSessionState>{
      GameSessionState.starting,
      GameSessionState.loading,
      GameSessionState.running,
      GameSessionState.paused,
      GameSessionState.lifecyclePaused,
      GameSessionState.completing,
      GameSessionState.completed,
      GameSessionState.failed,
      GameSessionState.prepared,
    };
    _requireState(stoppable, 'stop');
    if (checkpoint &&
        (_snapshot.state == GameSessionState.running ||
            _snapshot.state == GameSessionState.paused)) {
      final saved = await _captureAndCommit(SaveStatus.active);
      if (!saved && !abandonCheckpointFailure) {
        throw const GameSessionException(
          GameSessionErrorCode.checkpointRejected,
          'The last checkpoint failed; explicit abandon is required.',
        );
      }
    }
    _publish(_snapshot.copyWith(state: GameSessionState.stopping));
    final adapter = _adapter!;
    try {
      await adapter.stop(reason).timeout(stopTimeout);
    } on Object {
      // Dispose is still mandatory; the exit reason records the requested
      // product destination while diagnostics retain the adapter failure.
      _publish(
        _snapshot.copyWith(
          lastDiagnostic: const GameSessionDiagnosticData(
            code: 'session.stop.failed',
            severity: GameSessionDiagnosticSeverity.warning,
          ),
        ),
      );
    }
    await _disposeAdapter();
    _publish(
      _snapshot.copyWith(
        state: GameSessionState.disposed,
        exitReason: reason,
        clearLifecycleResumeState: true,
        clearPendingCompletion: true,
      ),
    );
  }

  Future<void> _fail(GameSessionFailure failure) async {
    _publish(
      _snapshot.copyWith(
        state: GameSessionState.failed,
        failure: failure,
      ),
    );
  }

  Future<void> _failAndDispose(
    GameSessionFailure failure, {
    Object? cause,
  }) async {
    await _fail(failure);
    await _disposeAdapter();
    _publish(
      _snapshot.copyWith(
        state: GameSessionState.disposed,
        exitReason: GameSessionExitReason.failed,
      ),
    );
  }

  Future<void> _disposeAdapter() async {
    final subscription = _adapterEvents;
    _adapterEvents = null;
    await subscription?.cancel();
    final adapter = _adapter;
    _adapter = null;
    await adapter?.dispose();
    _descriptor = null;
  }

  void _requireState(Set<GameSessionState> allowed, String operation) {
    if (!allowed.contains(_snapshot.state)) {
      throw GameSessionException(
        GameSessionErrorCode.invalidState,
        'Cannot $operation while session is ${_snapshot.state.name}.',
      );
    }
  }

  void _ensureControllerOpen() {
    if (_controllerDisposed) {
      throw const GameSessionException(
        GameSessionErrorCode.disposed,
        'The session controller is disposed.',
      );
    }
  }

  void _publish(GameSessionSnapshot next) {
    _snapshot = next;
    if (!_snapshots.isClosed) _snapshots.add(next);
  }

  Future<T> _serialize<T>(FutureOr<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
