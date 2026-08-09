import 'dart:async';

import 'runtime_initial_map_preloader.dart';
import 'runtime_intro_sequence_controller.dart';
import 'runtime_player_coordinator.dart';
import 'runtime_player_models.dart';
import 'runtime_presentation_media_selection.dart';
import 'runtime_splash_jingle_controller.dart';
import 'runtime_startup_coordinator.dart';
import 'runtime_startup_models.dart';
import 'runtime_startup_preparation.dart';
import 'runtime_title_music_controller.dart';

enum RuntimeStartupBootstrapStage {
  projectResolution,
  playerPreferences,
  controlProfile,
  hostStorage,
  presentationBinding,
  runtimeGraph,
}

const Map<RuntimeStartupBootstrapStage, double> runtimeStartupBootstrapWeights =
    <RuntimeStartupBootstrapStage, double>{
  RuntimeStartupBootstrapStage.projectResolution: 0.08,
  RuntimeStartupBootstrapStage.playerPreferences: 0.06,
  RuntimeStartupBootstrapStage.controlProfile: 0.04,
  RuntimeStartupBootstrapStage.hostStorage: 0.10,
  RuntimeStartupBootstrapStage.presentationBinding: 0.04,
  RuntimeStartupBootstrapStage.runtimeGraph: 0.03,
};

typedef RuntimeStartupBootstrapStageSink = void Function(
  RuntimeStartupBootstrapStage stage,
);

abstract interface class RuntimeStartupBootstrapPort<T> {
  Future<RuntimeStartupBootstrapResult<T>> prepare({
    required RuntimeStartupBootstrapStageSink onStageCompleted,
  });
}

final class RuntimeStartupBootstrapResult<T> {
  const RuntimeStartupBootstrapResult({
    required this.graph,
    required this.value,
  });

  final RuntimeStartupPreparedGraph graph;
  final T value;
}

final class RuntimeStartupBootstrapException implements Exception {
  const RuntimeStartupBootstrapException(this.failure);

  final RuntimeStartupFailure failure;
}

final class RuntimeStartupPreparedGraph {
  RuntimeStartupPreparedGraph({
    required this.playerCoordinator,
    required this.preparationPort,
    required this.initialMapPreloadPort,
    required this.assetResolver,
    required this.introController,
    required this.splashJingleController,
    required this.titleMusicController,
    this.reducedMotion = false,
    Future<void> Function()? stopIntroPlayback,
  }) : stopIntroPlayback = stopIntroPlayback ?? _noOp;

  final RuntimePlayerCoordinator playerCoordinator;
  final RuntimeStartupPreparationPort preparationPort;
  final RuntimeInitialMapPreloadPort initialMapPreloadPort;
  final RuntimePresentationAssetResolver assetResolver;
  final RuntimeIntroSequenceController introController;
  final RuntimeSplashJingleController splashJingleController;
  final RuntimeTitleMusicController titleMusicController;
  final bool reducedMotion;
  final Future<void> Function() stopIntroPlayback;
  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    initialMapPreloadPort.clear();
    await _safely(stopIntroPlayback);
    introController.skip();
    await Future.wait<void>(<Future<void>>[
      _safely(splashJingleController.dispose),
      _safely(titleMusicController.dispose),
      _safely(playerCoordinator.dispose),
    ]);
  }

  static Future<void> _noOp() => Future<void>.value();

  static Future<void> _safely(FutureOr<void> Function() operation) async {
    try {
      await operation();
    } on Object {
      return;
    }
  }
}

final class RuntimeStartupBootstrapCoordinator<T> {
  RuntimeStartupBootstrapCoordinator({
    required RuntimeStartupBootstrapPort<T> bootstrapPort,
    RuntimeStartupClock clock = const SystemRuntimeStartupClock(),
    RuntimeHostSplashBranding? hostBranding,
    Duration? minimumSplashDuration,
    RuntimePresentationOrientation presentationOrientation =
        RuntimePresentationOrientation.landscape,
    void Function(T value)? onPrepared,
  })  : _bootstrapPort = bootstrapPort,
        _clock = clock,
        _hostBranding = hostBranding,
        _minimumSplashDuration = minimumSplashDuration ??
            hostBranding?.minimumDisplayDuration ??
            const Duration(milliseconds: 7200),
        _splashExitDuration = hostBranding?.exitTransitionDuration ??
            const Duration(milliseconds: 1296),
        _presentationOrientation = presentationOrientation,
        _onPrepared = onPrepared,
        _snapshot = RuntimeStartupSnapshot(
          revision: 0,
          phase: RuntimeStartupPhase.splash,
          progress: 0,
          currentStage: RuntimeStartupPreparationStage.manifestAndIdentity,
          isPreparationReady: false,
          isMinimumElapsed: false,
          isLifecycleActive: true,
        ) {
    if (_minimumSplashDuration.isNegative) {
      throw ArgumentError.value(
        _minimumSplashDuration,
        'minimumSplashDuration',
        'must not be negative',
      );
    }
    if (_splashExitDuration.isNegative) {
      throw ArgumentError.value(
        _splashExitDuration,
        'exitTransitionDuration',
        'must not be negative',
      );
    }
  }

  static const double _bootstrapShare = 0.35;
  static const double _preparedShare = 0.65;

  final RuntimeStartupBootstrapPort<T> _bootstrapPort;
  final RuntimeStartupClock _clock;
  final RuntimeHostSplashBranding? _hostBranding;
  final Duration _minimumSplashDuration;
  final Duration _splashExitDuration;
  final void Function(T value)? _onPrepared;
  final StreamController<RuntimeStartupSnapshot> _snapshots =
      StreamController<RuntimeStartupSnapshot>.broadcast();
  final Set<RuntimeStartupBootstrapStage> _completedStages =
      <RuntimeStartupBootstrapStage>{};
  final List<RuntimeStartupScheduledDelay> _scheduledDelays =
      <RuntimeStartupScheduledDelay>[];

  RuntimePresentationOrientation _presentationOrientation;
  RuntimeStartupSnapshot _snapshot;
  RuntimeStartupCoordinator? _delegate;
  StreamSubscription<RuntimeStartupSnapshot>? _delegateSubscription;
  RuntimeStartupTimelineGate? _timelineGate;
  RuntimeStartupPhase? _resumePhase;
  int _generation = 0;
  bool _started = false;
  bool _disposed = false;
  bool _lifecycleActive = true;

  RuntimeStartupSnapshot get snapshot => _snapshot;
  Stream<RuntimeStartupSnapshot> get snapshots => _snapshots.stream;
  bool get isDisposed => _disposed;

  void start() {
    _ensureOpen();
    if (_started) {
      throw StateError(
        'The runtime startup bootstrap coordinator has already started.',
      );
    }
    _started = true;
    final holdDuration = _minimumSplashDuration > _splashExitDuration
        ? _minimumSplashDuration - _splashExitDuration
        : Duration.zero;
    _timelineGate = RuntimeStartupTimelineGate(
      minimumDisplayElapsed: _delay(_minimumSplashDuration),
      splashHoldElapsed: _delay(holdDuration),
    );
    _startBootstrapAttempt();
  }

  Future<RuntimeStartupCommandResult> dispatch(
    RuntimeStartupCommand command,
  ) async {
    if (_disposed) {
      return const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.cancelled,
      );
    }
    if (command.snapshotRevision != _snapshot.revision) {
      return const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.stale,
        safeMessage: 'The startup screen changed before this action arrived.',
      );
    }
    final delegate = _delegate;
    if (delegate != null) {
      return delegate.dispatch(
        RuntimeStartupCommand(
          action: command.action,
          snapshotRevision: delegate.snapshot.revision,
        ),
      );
    }
    if (command.action != RuntimeStartupAction.retryPreparation ||
        !_snapshot.canRetry) {
      return const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.unavailable,
      );
    }
    _startBootstrapAttempt();
    return const RuntimeStartupCommandResult(
      status: RuntimeStartupCommandStatus.accepted,
    );
  }

  Future<RuntimeStartupCommandResult> introPlaybackCompleted({
    required int snapshotRevision,
  }) {
    final delegate = _delegate;
    if (delegate == null || snapshotRevision != _snapshot.revision) {
      return Future<RuntimeStartupCommandResult>.value(
        const RuntimeStartupCommandResult(
          status: RuntimeStartupCommandStatus.stale,
        ),
      );
    }
    return delegate.introPlaybackCompleted(
      snapshotRevision: delegate.snapshot.revision,
    );
  }

  Future<RuntimeStartupCommandResult> introPlaybackFailed({
    required int snapshotRevision,
    required String reason,
  }) {
    final delegate = _delegate;
    if (delegate == null || snapshotRevision != _snapshot.revision) {
      return Future<RuntimeStartupCommandResult>.value(
        const RuntimeStartupCommandResult(
          status: RuntimeStartupCommandStatus.stale,
        ),
      );
    }
    return delegate.introPlaybackFailed(
      snapshotRevision: delegate.snapshot.revision,
      reason: reason,
    );
  }

  Future<RuntimePlayerCommandResult> dispatchPlayerCommand({
    required int startupSnapshotRevision,
    required RuntimePlayerCommand command,
  }) {
    final delegate = _delegate;
    if (delegate == null || startupSnapshotRevision != _snapshot.revision) {
      return Future<RuntimePlayerCommandResult>.value(
        const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.stale,
          safeMessage: 'The title menu changed before this action arrived.',
        ),
      );
    }
    return delegate.dispatchPlayerCommand(
      startupSnapshotRevision: delegate.snapshot.revision,
      command: command,
    );
  }

  Future<void> pauseForLifecycle() async {
    _ensureOpen();
    if (!_lifecycleActive) return;
    _lifecycleActive = false;
    _resumePhase = _snapshot.phase == RuntimeStartupPhase.lifecyclePaused
        ? _snapshot.suspendedPhase
        : _snapshot.phase;
    _publish(
      _copySnapshot(
        phase: RuntimeStartupPhase.lifecyclePaused,
        isLifecycleActive: false,
        suspendedPhase: _resumePhase ?? RuntimeStartupPhase.splash,
      ),
    );
    await _delegate?.pauseForLifecycle();
  }

  Future<void> resumeFromLifecycle() async {
    _ensureOpen();
    if (_lifecycleActive) return;
    _lifecycleActive = true;
    final delegate = _delegate;
    if (delegate != null) {
      await delegate.resumeFromLifecycle();
      if (_disposed) return;
      _publishDelegate(delegate.snapshot);
      return;
    }
    final resumePhase = _resumePhase ?? RuntimeStartupPhase.splash;
    _resumePhase = null;
    _publish(
      _copySnapshot(
        phase: resumePhase,
        isLifecycleActive: true,
        clearSuspendedPhase: true,
      ),
    );
  }

  Future<void> updatePresentationOrientation(
    RuntimePresentationOrientation orientation,
  ) async {
    _ensureOpen();
    _presentationOrientation = orientation;
    await _delegate?.updatePresentationOrientation(orientation);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    for (final delay in _scheduledDelays) {
      delay.cancel();
    }
    _scheduledDelays.clear();
    await _delegateSubscription?.cancel();
    await _delegate?.dispose();
    await _snapshots.close();
  }

  void _startBootstrapAttempt() {
    final generation = ++_generation;
    _completedStages.clear();
    _publishPhase(
      RuntimeStartupPhase.splash,
      currentStage: RuntimeStartupPreparationStage.manifestAndIdentity,
      clearFailure: true,
    );
    Future<RuntimeStartupBootstrapResult<T>>.sync(
      () => _bootstrapPort.prepare(
        onStageCompleted: (stage) => _completeStage(generation, stage),
      ),
    ).then(
      (result) => _acceptBootstrapResult(generation, result),
      onError: (Object error, StackTrace stackTrace) {
        _handleBootstrapFailure(generation, error);
      },
    );
  }

  void _completeStage(
    int generation,
    RuntimeStartupBootstrapStage stage,
  ) {
    if (!_isCurrent(generation) || !_completedStages.add(stage)) return;
    final completedProgress = _completedStages.fold<double>(
      0,
      (total, completed) => total + runtimeStartupBootstrapWeights[completed]!,
    );
    final progress = completedProgress > _snapshot.progress
        ? completedProgress
        : _snapshot.progress;
    _publish(
      _copySnapshot(
        progress: progress,
        currentStage: _currentPreparationStage,
      ),
    );
  }

  Future<void> _acceptBootstrapResult(
    int generation,
    RuntimeStartupBootstrapResult<T> result,
  ) async {
    if (!_isCurrent(generation)) {
      await result.graph.dispose();
      return;
    }
    for (final stage in RuntimeStartupBootstrapStage.values) {
      _completeStage(generation, stage);
    }
    RuntimeStartupCoordinator? delegate;
    try {
      delegate = RuntimeStartupCoordinator(
        playerCoordinator: result.graph.playerCoordinator,
        preparationPort: result.graph.preparationPort,
        initialMapPreloadPort: result.graph.initialMapPreloadPort,
        assetResolver: result.graph.assetResolver,
        introController: result.graph.introController,
        splashJingleController: result.graph.splashJingleController,
        titleMusicController: result.graph.titleMusicController,
        clock: _clock,
        hostBranding: _hostBranding,
        minimumSplashDuration: _minimumSplashDuration,
        reducedMotion: result.graph.reducedMotion,
        presentationOrientation: _presentationOrientation,
        stopIntroPlayback: result.graph.stopIntroPlayback,
        initialTimelineGate: _timelineGate,
      );
      _delegate = delegate;
      _delegateSubscription = delegate.snapshots.listen(_publishDelegate);
      _onPrepared?.call(result.value);
      delegate.start();
      if (!_lifecycleActive) {
        await delegate.pauseForLifecycle();
      }
    } on Object {
      await _delegateSubscription?.cancel();
      _delegateSubscription = null;
      _delegate = null;
      if (delegate == null) {
        await result.graph.dispose();
      } else {
        await delegate.dispose();
      }
      _handleBootstrapFailure(
        generation,
        const RuntimeStartupBootstrapException(
          RuntimeStartupFailure(
            code: 'runtimeGraphActivationFailed',
            safeMessage: 'The game runtime could not be prepared.',
          ),
        ),
      );
    }
  }

  void _handleBootstrapFailure(int generation, Object error) {
    if (!_isCurrent(generation)) return;
    final failure = error is RuntimeStartupBootstrapException
        ? error.failure
        : const RuntimeStartupFailure(
            code: 'runtimeBootstrapFailed',
            safeMessage: 'The game could not begin preparing.',
          );
    _publishPhase(RuntimeStartupPhase.recoverableError, failure: failure);
  }

  void _publishDelegate(RuntimeStartupSnapshot delegateSnapshot) {
    if (_disposed) return;
    final mappedProgress =
        _bootstrapShare + (delegateSnapshot.progress * _preparedShare);
    final progress = mappedProgress > _snapshot.progress
        ? mappedProgress
        : _snapshot.progress;
    final lifecyclePaused = !_lifecycleActive ||
        delegateSnapshot.phase == RuntimeStartupPhase.lifecyclePaused;
    final suspendedPhase =
        delegateSnapshot.phase == RuntimeStartupPhase.lifecyclePaused
            ? delegateSnapshot.suspendedPhase ?? RuntimeStartupPhase.splash
            : delegateSnapshot.phase;
    _publish(
      RuntimeStartupSnapshot(
        revision: _snapshot.revision + 1,
        phase: lifecyclePaused
            ? RuntimeStartupPhase.lifecyclePaused
            : delegateSnapshot.phase,
        progress: progress,
        currentStage: delegateSnapshot.currentStage,
        isPreparationReady: delegateSnapshot.isPreparationReady,
        isMinimumElapsed: delegateSnapshot.isMinimumElapsed,
        isLifecycleActive:
            lifecyclePaused ? false : delegateSnapshot.isLifecycleActive,
        suspendedPhase: lifecyclePaused ? suspendedPhase : null,
        introPhase: delegateSnapshot.introPhase,
        isTransitioning: delegateSnapshot.isTransitioning,
        presentation: delegateSnapshot.presentation,
        failure: delegateSnapshot.failure,
        playerSnapshot: delegateSnapshot.playerSnapshot,
        diagnostics: delegateSnapshot.diagnostics,
        introCanReplay: delegateSnapshot.introCanReplay,
      ),
    );
  }

  RuntimeStartupPreparationStage get _currentPreparationStage {
    for (final stage in RuntimeStartupBootstrapStage.values) {
      if (_completedStages.contains(stage)) continue;
      return switch (stage) {
        RuntimeStartupBootstrapStage.projectResolution =>
          RuntimeStartupPreparationStage.manifestAndIdentity,
        RuntimeStartupBootstrapStage.playerPreferences ||
        RuntimeStartupBootstrapStage.controlProfile =>
          RuntimeStartupPreparationStage.playerPreferences,
        RuntimeStartupBootstrapStage.hostStorage =>
          RuntimeStartupPreparationStage.saveDiscovery,
        RuntimeStartupBootstrapStage.presentationBinding =>
          RuntimeStartupPreparationStage.presentationProfile,
        RuntimeStartupBootstrapStage.runtimeGraph =>
          RuntimeStartupPreparationStage.splashBranding,
      };
    }
    return RuntimeStartupPreparationStage.splashBranding;
  }

  void _publishPhase(
    RuntimeStartupPhase desiredPhase, {
    RuntimeStartupPreparationStage? currentStage,
    RuntimeStartupFailure? failure,
    bool clearFailure = false,
  }) {
    if (!_lifecycleActive) {
      _resumePhase = desiredPhase;
      _publish(
        _copySnapshot(
          phase: RuntimeStartupPhase.lifecyclePaused,
          currentStage: currentStage,
          isLifecycleActive: false,
          suspendedPhase: desiredPhase,
          failure: failure,
          clearFailure: clearFailure,
        ),
      );
      return;
    }
    _publish(
      _copySnapshot(
        phase: desiredPhase,
        currentStage: currentStage,
        isLifecycleActive: true,
        clearSuspendedPhase: true,
        failure: failure,
        clearFailure: clearFailure,
      ),
    );
  }

  RuntimeStartupSnapshot _copySnapshot({
    RuntimeStartupPhase? phase,
    double? progress,
    RuntimeStartupPreparationStage? currentStage,
    bool? isLifecycleActive,
    RuntimeStartupPhase? suspendedPhase,
    bool clearSuspendedPhase = false,
    RuntimeStartupFailure? failure,
    bool clearFailure = false,
  }) =>
      RuntimeStartupSnapshot(
        revision: _snapshot.revision + 1,
        phase: phase ?? _snapshot.phase,
        progress: progress ?? _snapshot.progress,
        currentStage: currentStage ?? _snapshot.currentStage,
        isPreparationReady: _snapshot.isPreparationReady,
        isMinimumElapsed: _snapshot.isMinimumElapsed,
        isLifecycleActive: isLifecycleActive ?? _snapshot.isLifecycleActive,
        suspendedPhase: clearSuspendedPhase
            ? null
            : suspendedPhase ?? _snapshot.suspendedPhase,
        introPhase: _snapshot.introPhase,
        isTransitioning: _snapshot.isTransitioning,
        presentation: _snapshot.presentation,
        failure: clearFailure ? null : failure ?? _snapshot.failure,
        playerSnapshot: _snapshot.playerSnapshot,
        diagnostics: _snapshot.diagnostics,
        introCanReplay: _snapshot.introCanReplay,
      );

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  Future<void> _delay(Duration duration) {
    final clock = _clock;
    if (clock is RuntimeStartupSchedulingClock) {
      final delay = clock.schedule(duration);
      _scheduledDelays.add(delay);
      return delay.future;
    }
    return clock.delay(duration);
  }

  void _publish(RuntimeStartupSnapshot snapshot) {
    if (_disposed) return;
    _snapshot = snapshot;
    if (!_snapshots.isClosed) _snapshots.add(snapshot);
  }

  void _ensureOpen() {
    if (_disposed) {
      throw StateError(
        'The runtime startup bootstrap coordinator is disposed.',
      );
    }
  }
}
