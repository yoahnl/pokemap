import 'dart:async';

import '../presentation/flame/runtime_input_authority.dart';
import '../presentation/flame/runtime_input_event.dart';
import '../player/runtime_world_service_models.dart';
import 'game_session_contract.dart';

typedef GameSessionProgressReporter = void Function(
  GameSessionLoadingProgress progress,
);

/// One disposable runtime graph hosted inside the Hub process.
///
/// A concrete graph may own a `PlayableMapGame`, overlays, audio and asset
/// caches. Its [dispose] implementation is the hard boundary before the next
/// game can start.
abstract interface class InProcessGameSessionRuntime {
  Stream<GameSessionAdapterEvent> get events;

  Future<void> load(GameSessionProgressReporter reportProgress);
  Future<void> pause();
  Future<void> resume();
  Future<GameSessionCheckpoint?> captureCheckpoint();
  Future<void> lockGameplayForCompletion();
  Future<void> acknowledgeCompletion({required bool accepted});
  Future<void> stop(GameSessionExitReason reason);
  Future<void> dispose();
  bool handleInput(RuntimeInputEvent event);
}

typedef InProcessGameSessionRuntimeFactory = InProcessGameSessionRuntime
    Function(GameSessionDescriptor descriptor);

/// V0/mobile adapter selected by ADR-0002.
///
/// It intentionally mirrors the future child-process adapter: only the
/// topology changes, never the controller or player-facing snapshots.
final class InProcessGameSessionAdapter
    implements
        GameSessionAdapter,
        GameSessionInputLockPort,
        RuntimeWorldServicePort {
  InProcessGameSessionAdapter({
    required InProcessGameSessionRuntimeFactory runtimeFactory,
  }) : _runtimeFactory = runtimeFactory;

  final InProcessGameSessionRuntimeFactory _runtimeFactory;
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();
  final _worldServiceSnapshots =
      StreamController<RuntimeWorldServiceSnapshot?>.broadcast();
  InProcessGameSessionRuntime? _runtime;
  StreamSubscription<GameSessionAdapterEvent>? _runtimeEvents;
  StreamSubscription<RuntimeWorldServiceSnapshot?>? _runtimeWorldServices;
  RuntimeWorldServicePort? _worldServicePort;
  RuntimeWorldServiceSnapshot? _worldServiceSnapshot;
  GameSessionDescriptor? _descriptor;
  bool _disposed = false;

  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;

  @override
  Future<void> prepare(GameSessionDescriptor descriptor) async {
    if (_descriptor != null || _runtime != null || _disposed) {
      throw StateError('The in-process session adapter is single-use.');
    }
    _descriptor = descriptor;
    final runtime = _runtimeFactory(descriptor);
    _runtime = runtime;
    _runtimeEvents = runtime.events.listen(
      _emit,
      onError: (Object error, StackTrace stackTrace) {
        _emit(
          GameSessionFatal(
            descriptor.sessionId,
            const GameSessionFailure(
              code: GameSessionFailureCode.runtime,
              recoverability: GameSessionFailureRecoverability.titleOrHub,
              safeMessage: 'The in-process runtime event stream failed.',
            ),
          ),
        );
      },
    );
    if (runtime case final RuntimeWorldServicePort port) {
      _worldServicePort = port;
      _worldServiceSnapshot = port.worldServiceSnapshot;
      _runtimeWorldServices = port.worldServiceSnapshots.listen(
        _publishWorldService,
      );
    }
  }

  @override
  RuntimeWorldServiceSnapshot? get worldServiceSnapshot =>
      _worldServiceSnapshot;

  @override
  Stream<RuntimeWorldServiceSnapshot?> get worldServiceSnapshots =>
      _worldServiceSnapshots.stream;

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) {
    final port = _worldServicePort;
    if (port == null || _disposed) {
      return Future<RuntimeWorldServiceCommandResult>.value(
        const RuntimeWorldServiceCommandResult(
          status: RuntimeWorldServiceCommandStatus.unavailable,
          safeMessage: 'The active runtime exposes no contextual service.',
        ),
      );
    }
    return port.dispatchWorldService(command);
  }

  @override
  Future<void> start() async {
    final descriptor = _requirePrepared();
    _emit(GameSessionReady(descriptor.sessionId));
    _emit(
      GameSessionLoading(
        descriptor.sessionId,
        const GameSessionLoadingProgress(
          stage: 'runtime',
          current: 0,
        ),
      ),
    );
    await _runtime!.load(
      (progress) => _emit(
        GameSessionLoading(descriptor.sessionId, progress),
      ),
    );
    _emit(GameSessionRunning(descriptor.sessionId));
  }

  @override
  Future<void> pause() async {
    final descriptor = _requirePrepared();
    await _runtime!.pause();
    _emit(GameSessionPaused(descriptor.sessionId));
  }

  @override
  Future<void> resume() async {
    final descriptor = _requirePrepared();
    await _runtime!.resume();
    _emit(GameSessionRunning(descriptor.sessionId));
  }

  @override
  Future<void> setInputLock(
    RuntimeExternalInputLock owner, {
    required bool locked,
  }) async {
    final runtime = _requireRuntime();
    if (runtime case final GameSessionInputLockPort port) {
      await port.setInputLock(owner, locked: locked);
    }
  }

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() =>
      _requireRuntime().captureCheckpoint();

  @override
  Future<void> lockGameplayForCompletion() =>
      _requireRuntime().lockGameplayForCompletion();

  @override
  Future<void> acknowledgeCompletion({required bool accepted}) =>
      _requireRuntime().acknowledgeCompletion(accepted: accepted);

  @override
  Future<void> stop(GameSessionExitReason reason) =>
      _requireRuntime().stop(reason);

  @override
  bool handleInput(RuntimeInputEvent event) =>
      _requireRuntime().handleInput(event);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _runtimeEvents?.cancel();
    _runtimeEvents = null;
    await _runtimeWorldServices?.cancel();
    _runtimeWorldServices = null;
    _worldServicePort = null;
    _publishWorldService(null);
    final runtime = _runtime;
    _runtime = null;
    await runtime?.dispose();
    await _events.close();
    await _worldServiceSnapshots.close();
  }

  GameSessionDescriptor _requirePrepared() {
    final descriptor = _descriptor;
    if (descriptor == null || _runtime == null || _disposed) {
      throw StateError('The in-process session adapter is not prepared.');
    }
    return descriptor;
  }

  InProcessGameSessionRuntime _requireRuntime() {
    _requirePrepared();
    return _runtime!;
  }

  void _emit(GameSessionAdapterEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  void _publishWorldService(RuntimeWorldServiceSnapshot? snapshot) {
    _worldServiceSnapshot = snapshot;
    if (!_worldServiceSnapshots.isClosed) {
      _worldServiceSnapshots.add(snapshot);
    }
  }
}
