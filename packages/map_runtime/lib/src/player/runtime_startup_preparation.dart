import 'dart:async';

import 'runtime_startup_models.dart';

const Map<RuntimeStartupPreparationStage, double>
    runtimeStartupPreparationWeights = <RuntimeStartupPreparationStage, double>{
  RuntimeStartupPreparationStage.manifestAndIdentity: 0.15,
  RuntimeStartupPreparationStage.playerPreferences: 0.08,
  RuntimeStartupPreparationStage.saveDiscovery: 0.12,
  RuntimeStartupPreparationStage.initialMap: 0.35,
  RuntimeStartupPreparationStage.presentationProfile: 0.07,
  RuntimeStartupPreparationStage.splashBranding: 0.06,
  RuntimeStartupPreparationStage.introAndPoster: 0.08,
  RuntimeStartupPreparationStage.titleMenuAndMusic: 0.09,
};

abstract interface class RuntimeStartupClock {
  Future<void> delay(Duration duration);
}

abstract interface class RuntimeStartupScheduledDelay {
  Future<void> get future;

  void cancel();
}

abstract interface class RuntimeStartupSchedulingClock
    implements RuntimeStartupClock {
  RuntimeStartupScheduledDelay schedule(Duration duration);
}

final class SystemRuntimeStartupClock
    implements RuntimeStartupClock, RuntimeStartupSchedulingClock {
  const SystemRuntimeStartupClock();

  @override
  Future<void> delay(Duration duration) => schedule(duration).future;

  @override
  RuntimeStartupScheduledDelay schedule(Duration duration) =>
      _SystemRuntimeStartupScheduledDelay(duration);
}

final class _SystemRuntimeStartupScheduledDelay
    implements RuntimeStartupScheduledDelay {
  _SystemRuntimeStartupScheduledDelay(Duration duration) {
    _timer = Timer(duration, _complete);
  }

  final Completer<void> _completer = Completer<void>();
  late final Timer _timer;

  @override
  Future<void> get future => _completer.future;

  @override
  void cancel() {
    _timer.cancel();
    _complete();
  }

  void _complete() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

final class RuntimeStartupTimelineGate {
  const RuntimeStartupTimelineGate({
    required this.minimumDisplayElapsed,
    required this.splashHoldElapsed,
  });

  final Future<void> minimumDisplayElapsed;
  final Future<void> splashHoldElapsed;
}

enum RuntimeStartupPreparationStepStatus {
  completed,
  absent,
  nonBlockingFailure,
  blockingFailure,
}

final class RuntimeStartupPreparationStepResult {
  const RuntimeStartupPreparationStepResult.completed()
      : status = RuntimeStartupPreparationStepStatus.completed,
        diagnostic = null,
        additionalDiagnostics = const <RuntimeStartupDiagnostic>[],
        failure = null;

  const RuntimeStartupPreparationStepResult.absent()
      : status = RuntimeStartupPreparationStepStatus.absent,
        diagnostic = null,
        additionalDiagnostics = const <RuntimeStartupDiagnostic>[],
        failure = null;

  const RuntimeStartupPreparationStepResult.nonBlockingFailure(
    RuntimeStartupDiagnostic this.diagnostic,
  )   : status = RuntimeStartupPreparationStepStatus.nonBlockingFailure,
        additionalDiagnostics = const <RuntimeStartupDiagnostic>[],
        failure = null;

  RuntimeStartupPreparationStepResult.nonBlockingFailures(
    Iterable<RuntimeStartupDiagnostic> diagnostics,
  )   : status = RuntimeStartupPreparationStepStatus.nonBlockingFailure,
        diagnostic = null,
        additionalDiagnostics =
            List<RuntimeStartupDiagnostic>.unmodifiable(diagnostics),
        failure = null {
    if (additionalDiagnostics.isEmpty) {
      throw ArgumentError.value(
        diagnostics,
        'diagnostics',
        'must contain at least one diagnostic',
      );
    }
  }

  const RuntimeStartupPreparationStepResult.blockingFailure(
    RuntimeStartupFailure this.failure,
  )   : status = RuntimeStartupPreparationStepStatus.blockingFailure,
        diagnostic = null,
        additionalDiagnostics = const <RuntimeStartupDiagnostic>[];

  final RuntimeStartupPreparationStepStatus status;
  final RuntimeStartupDiagnostic? diagnostic;
  final List<RuntimeStartupDiagnostic> additionalDiagnostics;
  final RuntimeStartupFailure? failure;

  Iterable<RuntimeStartupDiagnostic> get diagnostics sync* {
    if (diagnostic case final item?) yield item;
    yield* additionalDiagnostics;
  }
}

typedef RuntimeStartupPreparationOperation
    = Future<RuntimeStartupPreparationStepResult> Function();

final class RuntimeStartupPreparationSnapshot {
  RuntimeStartupPreparationSnapshot({
    required this.revision,
    required this.progress,
    required this.currentStage,
    required this.isPreparationReady,
    required this.isMinimumElapsed,
    this.failure,
    List<RuntimeStartupDiagnostic> diagnostics =
        const <RuntimeStartupDiagnostic>[],
  }) : diagnostics = List<RuntimeStartupDiagnostic>.unmodifiable(diagnostics) {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must be non-negative');
    }
    if (progress < 0 || progress > 1) {
      throw ArgumentError.value(
          progress, 'progress', 'must be between 0 and 1');
    }
  }

  final int revision;
  final double progress;
  final RuntimeStartupPreparationStage currentStage;
  final bool isPreparationReady;
  final bool isMinimumElapsed;
  final List<RuntimeStartupDiagnostic> diagnostics;
  final RuntimeStartupFailure? failure;

  RuntimeStartupPreparationSnapshot next({
    double? progress,
    RuntimeStartupPreparationStage? currentStage,
    bool? isPreparationReady,
    bool? isMinimumElapsed,
    List<RuntimeStartupDiagnostic>? diagnostics,
    RuntimeStartupFailure? failure,
  }) {
    return RuntimeStartupPreparationSnapshot(
      revision: revision + 1,
      progress: progress ?? this.progress,
      currentStage: currentStage ?? this.currentStage,
      isPreparationReady: isPreparationReady ?? this.isPreparationReady,
      isMinimumElapsed: isMinimumElapsed ?? this.isMinimumElapsed,
      diagnostics: diagnostics ?? this.diagnostics,
      failure: failure ?? this.failure,
    );
  }
}

enum RuntimeStartupPreparationStatus { ready, blocked, cancelled }

final class RuntimeStartupPreparationResult {
  const RuntimeStartupPreparationResult({
    required this.status,
    required this.snapshot,
  });

  final RuntimeStartupPreparationStatus status;
  final RuntimeStartupPreparationSnapshot snapshot;
}

/// Runs the eight signed startup units concurrently with the splash minimum.
///
/// Progress only moves when real work completes. The clock never fabricates a
/// percentage: it is a separate success gate that prevents a short flash.
final class RuntimeStartupPreparation {
  RuntimeStartupPreparation({
    required RuntimeStartupClock clock,
    required this.minimumDisplayDuration,
    Future<void>? minimumDisplayElapsed,
  })  : _clock = clock,
        _minimumDisplayElapsed = minimumDisplayElapsed,
        _snapshot = RuntimeStartupPreparationSnapshot(
          revision: 0,
          progress: 0,
          currentStage: RuntimeStartupPreparationStage.manifestAndIdentity,
          isPreparationReady: false,
          isMinimumElapsed: false,
        ) {
    if (minimumDisplayDuration.isNegative) {
      throw ArgumentError.value(
        minimumDisplayDuration,
        'minimumDisplayDuration',
        'must not be negative',
      );
    }
  }

  final RuntimeStartupClock _clock;
  final Future<void>? _minimumDisplayElapsed;
  final Duration minimumDisplayDuration;
  final Set<RuntimeStartupPreparationStage> _completed =
      <RuntimeStartupPreparationStage>{};
  final Map<RuntimeStartupPreparationStage, double> _stageProgress =
      <RuntimeStartupPreparationStage, double>{};
  final List<RuntimeStartupDiagnostic> _diagnostics =
      <RuntimeStartupDiagnostic>[];

  RuntimeStartupPreparationSnapshot _snapshot;
  Completer<RuntimeStartupPreparationResult>? _resultCompleter;
  void Function(RuntimeStartupPreparationSnapshot)? _onChanged;
  bool _started = false;
  bool _terminated = false;

  RuntimeStartupPreparationSnapshot get snapshot => _snapshot;

  void reportStageProgress(
    RuntimeStartupPreparationStage stage,
    double progress,
  ) {
    if (!_started || _terminated || _completed.contains(stage)) return;
    if (!progress.isFinite) {
      throw ArgumentError.value(progress, 'progress', 'must be finite');
    }
    final bounded = progress.clamp(0.0, 1.0);
    if (bounded <= (_stageProgress[stage] ?? 0)) return;
    _stageProgress[stage] = bounded;
    _publish(
      _snapshot.next(
        progress: _progressValue(),
        currentStage: _currentStage(),
      ),
    );
  }

  Future<RuntimeStartupPreparationResult> run({
    required Map<RuntimeStartupPreparationStage,
            RuntimeStartupPreparationOperation>
        operations,
    void Function(RuntimeStartupPreparationSnapshot)? onChanged,
  }) {
    if (_started) {
      throw StateError('A startup preparation instance can only run once.');
    }
    if (operations.length != RuntimeStartupPreparationStage.values.length ||
        !RuntimeStartupPreparationStage.values.every(operations.containsKey)) {
      throw ArgumentError(
        'Startup preparation must provide each of the eight signed stages.',
      );
    }
    _started = true;
    _onChanged = onChanged;
    _resultCompleter = Completer<RuntimeStartupPreparationResult>();

    // These futures intentionally start together. Awaiting the delay before
    // the operations would turn the splash into decorative fake loading.
    (_minimumDisplayElapsed ?? _clock.delay(minimumDisplayDuration)).then(
      (_) => _minimumElapsed(),
      onError: (_, __) => _minimumElapsed(),
    );
    for (final stage in RuntimeStartupPreparationStage.values) {
      Future<RuntimeStartupPreparationStepResult>.sync(operations[stage]!).then(
        (result) => _completeStage(stage, result),
        onError: (Object error, StackTrace stackTrace) => _completeStage(
          stage,
          RuntimeStartupPreparationStepResult.blockingFailure(
            RuntimeStartupFailure(
              code: '${stage.name}Failed',
              safeMessage: 'The game could not finish preparing.',
            ),
          ),
        ),
      );
    }
    return _resultCompleter!.future;
  }

  /// Logical cancellation is immediate; operation futures may finish later,
  /// but their callbacks are ignored and cannot publish another snapshot.
  void cancel() {
    if (!_started || _terminated) return;
    _terminated = true;
    _resultCompleter!.complete(
      RuntimeStartupPreparationResult(
        status: RuntimeStartupPreparationStatus.cancelled,
        snapshot: _snapshot,
      ),
    );
  }

  void _minimumElapsed() {
    if (_terminated) return;
    _publish(_snapshot.next(isMinimumElapsed: true));
    _finishIfReady();
  }

  void _completeStage(
    RuntimeStartupPreparationStage stage,
    RuntimeStartupPreparationStepResult result,
  ) {
    if (_terminated || _completed.contains(stage)) return;
    if (result.status == RuntimeStartupPreparationStepStatus.blockingFailure) {
      _terminated = true;
      final blocked = _snapshot.next(failure: result.failure);
      _publish(blocked);
      _resultCompleter!.complete(
        RuntimeStartupPreparationResult(
          status: RuntimeStartupPreparationStatus.blocked,
          snapshot: blocked,
        ),
      );
      return;
    }
    _diagnostics.addAll(result.diagnostics);
    _completed.add(stage);
    final preparationReady =
        _completed.length == RuntimeStartupPreparationStage.values.length;
    _publish(
      _snapshot.next(
        progress: _progressValue(),
        currentStage: _currentStage(),
        isPreparationReady: preparationReady,
        diagnostics: _diagnostics,
      ),
    );
    _finishIfReady();
  }

  void _finishIfReady() {
    if (_terminated ||
        !_snapshot.isPreparationReady ||
        !_snapshot.isMinimumElapsed) {
      return;
    }
    _terminated = true;
    _resultCompleter!.complete(
      RuntimeStartupPreparationResult(
        status: RuntimeStartupPreparationStatus.ready,
        snapshot: _snapshot,
      ),
    );
  }

  double _progressValue() => RuntimeStartupPreparationStage.values
      .fold<double>(
        0,
        (value, stage) =>
            value +
            runtimeStartupPreparationWeights[stage]! *
                (_completed.contains(stage) ? 1 : _stageProgress[stage] ?? 0),
      )
      .clamp(0.0, 1.0);

  RuntimeStartupPreparationStage _currentStage() {
    if (_completed.length == RuntimeStartupPreparationStage.values.length) {
      return RuntimeStartupPreparationStage.titleMenuAndMusic;
    }
    return RuntimeStartupPreparationStage.values.firstWhere(
      (candidate) => !_completed.contains(candidate),
    );
  }

  void _publish(RuntimeStartupPreparationSnapshot next) {
    _snapshot = next;
    _onChanged?.call(next);
  }
}
