import 'dart:async';

import 'package:map_core/map_core.dart';

import 'runtime_presentation_media_playback_controller.dart';

enum RuntimePresentationExecutionPhase {
  idle,
  running,

  /// The narrative timeline is suspended by an interaction cue: distinct
  /// from [paused], which is the user or lifecycle engine pause. Authored
  /// ambient tracks may keep playing during a hold; a real pause silences
  /// everything (BETA-CIN-077).
  interactionHold,
  paused,
  terminating,
  terminated,
}

enum RuntimePresentationExecutionResult {
  completed,
  skipped,
  cancelled,
  failed,
}

enum RuntimePresentationCancellationReason { requested, disposed }

final class RuntimePresentationRunToken {
  const RuntimePresentationRunToken(this.value);

  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimePresentationRunToken && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class RuntimePresentationExecutionTerminal {
  const RuntimePresentationExecutionTerminal({
    required this.runToken,
    required this.result,
    this.cancellationReason,
    this.diagnosticCode,
  });

  final RuntimePresentationRunToken runToken;
  final RuntimePresentationExecutionResult result;
  final RuntimePresentationCancellationReason? cancellationReason;
  final String? diagnosticCode;
}

final class RuntimePresentationExecutionSnapshot {
  const RuntimePresentationExecutionSnapshot({
    required this.phase,
    this.runToken,
    this.terminal,
  });

  static const idle = RuntimePresentationExecutionSnapshot(
    phase: RuntimePresentationExecutionPhase.idle,
  );

  final RuntimePresentationExecutionPhase phase;
  final RuntimePresentationRunToken? runToken;
  final RuntimePresentationExecutionTerminal? terminal;
}

typedef RuntimePresentationExecutionTerminalSink = void Function(
  RuntimePresentationExecutionTerminal terminal,
);

typedef RuntimePresentationExecutionReceiptSink = void Function(
  PresentationExecutionReceipt receipt,
);

final class RuntimePresentationExecutionController {
  RuntimePresentationExecutionController({
    required this.mediaController,
    this.onTerminal,
    this.onReceipt,
  });

  final RuntimePresentationMediaPlaybackController mediaController;
  final RuntimePresentationExecutionTerminalSink? onTerminal;
  final RuntimePresentationExecutionReceiptSink? onReceipt;

  Future<void> _pending = Future<void>.value();
  RuntimePresentationExecutionSnapshot _snapshot =
      RuntimePresentationExecutionSnapshot.idle;
  Completer<RuntimePresentationExecutionTerminal>? _terminalCompleter;
  PresentationExecutionRecorder? _observabilityRecorder;
  PresentationExecutionReceipt? _lastReceipt;
  var _nextRunToken = 1;
  var _disposed = false;

  RuntimePresentationExecutionSnapshot get snapshot => _snapshot;

  PresentationExecutionReceipt? get lastReceipt => _lastReceipt;

  RuntimePresentationRunToken start({
    PresentationExecutionCorrelation? observability,
  }) {
    if (_disposed) {
      throw StateError('Presentation execution controller is disposed.');
    }
    if (_snapshot.phase != RuntimePresentationExecutionPhase.idle &&
        _snapshot.phase != RuntimePresentationExecutionPhase.terminated) {
      throw StateError('A Presentation execution is already active.');
    }
    final token = RuntimePresentationRunToken(_nextRunToken++);
    _terminalCompleter = Completer<RuntimePresentationExecutionTerminal>();
    _observabilityRecorder = observability == null
        ? null
        : PresentationExecutionRecorder(
            correlation: observability,
            platform: mediaController.targetPlatform,
          );
    _lastReceipt = null;
    _snapshot = RuntimePresentationExecutionSnapshot(
      phase: RuntimePresentationExecutionPhase.running,
      runToken: token,
    );
    _record(
      token,
      PresentationExecutionEventKind.prepare,
    );
    _record(
      token,
      PresentationExecutionEventKind.start,
    );
    return token;
  }

  void observeMediaPlaybackSnapshot(
    RuntimePresentationRunToken token,
    RuntimePresentationMediaPlaybackSnapshot mediaSnapshot,
  ) {
    if (mediaSnapshot.usedFallback) {
      _record(token, PresentationExecutionEventKind.fallback);
    }
    if (mediaSnapshot.status == RuntimePresentationMediaPlaybackStatus.failed) {
      _recordFailure(
        token,
        mediaSnapshot.diagnosticCode ??
            RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
      );
    }
  }

  Future<RuntimePresentationExecutionTerminal> waitForTerminal(
    RuntimePresentationRunToken token,
  ) {
    final terminal = _snapshot.terminal;
    if (_snapshot.runToken == token && terminal != null) {
      return Future.value(terminal);
    }
    if (_snapshot.runToken != token || _terminalCompleter == null) {
      return Future.error(
        StateError('Presentation execution token is stale.'),
      );
    }
    return _terminalCompleter!.future;
  }

  var _holdSuspendedByPause = false;

  /// Marks the explicit interactionHold state: running → interactionHold.
  /// The transition never touches the media — per-track hold policies decide
  /// what keeps playing.
  RuntimePresentationExecutionSnapshot enterInteractionHold(
    RuntimePresentationRunToken token,
  ) {
    if (!_isCurrent(token, RuntimePresentationExecutionPhase.running)) {
      return _snapshot;
    }
    _snapshot = RuntimePresentationExecutionSnapshot(
      phase: RuntimePresentationExecutionPhase.interactionHold,
      runToken: token,
    );
    return _snapshot;
  }

  RuntimePresentationExecutionSnapshot exitInteractionHold(
    RuntimePresentationRunToken token,
  ) {
    if (_isCurrent(token, RuntimePresentationExecutionPhase.paused) &&
        _holdSuspendedByPause) {
      // Answering while backgrounded: the hold ends, but the engine pause
      // keeps priority — resuming the lifecycle returns to running.
      _holdSuspendedByPause = false;
      return _snapshot;
    }
    if (!_isCurrent(token, RuntimePresentationExecutionPhase.interactionHold)) {
      return _snapshot;
    }
    _snapshot = RuntimePresentationExecutionSnapshot(
      phase: RuntimePresentationExecutionPhase.running,
      runToken: token,
    );
    return _snapshot;
  }

  Future<RuntimePresentationExecutionSnapshot> pause(
    RuntimePresentationRunToken token,
  ) {
    final holdActive =
        _isCurrent(token, RuntimePresentationExecutionPhase.interactionHold);
    if (!holdActive &&
        !_isCurrent(token, RuntimePresentationExecutionPhase.running)) {
      return Future.value(_snapshot);
    }
    _holdSuspendedByPause = holdActive;
    _snapshot = RuntimePresentationExecutionSnapshot(
      phase: RuntimePresentationExecutionPhase.paused,
      runToken: token,
    );
    final result = _pending.then((_) async {
      if (!_isCurrent(token, RuntimePresentationExecutionPhase.paused)) {
        return _snapshot;
      }
      RuntimePresentationMediaPlaybackSnapshot mediaSnapshot;
      try {
        mediaSnapshot = await mediaController.pauseForLifecycle();
      } on Object {
        if (_isCurrent(token, RuntimePresentationExecutionPhase.paused)) {
          await _terminalize(
            token,
            RuntimePresentationExecutionResult.failed,
            diagnosticCode:
                RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
          );
        }
        return _snapshot;
      }
      if (!_isCurrent(token, RuntimePresentationExecutionPhase.paused)) {
        return _snapshot;
      }
      if (mediaSnapshot.status ==
          RuntimePresentationMediaPlaybackStatus.failed) {
        await _terminalize(
          token,
          RuntimePresentationExecutionResult.failed,
          diagnosticCode: mediaSnapshot.diagnosticCode,
        );
      }
      return _snapshot;
    });
    _pending = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  Future<RuntimePresentationExecutionSnapshot> resume(
    RuntimePresentationRunToken token,
  ) {
    if (!_isCurrent(token, RuntimePresentationExecutionPhase.paused)) {
      return Future.value(_snapshot);
    }
    final restoredPhase = _holdSuspendedByPause
        ? RuntimePresentationExecutionPhase.interactionHold
        : RuntimePresentationExecutionPhase.running;
    _holdSuspendedByPause = false;
    _snapshot = RuntimePresentationExecutionSnapshot(
      phase: restoredPhase,
      runToken: token,
    );
    final result = _pending.then((_) async {
      if (!_isCurrent(token, restoredPhase)) {
        return _snapshot;
      }
      RuntimePresentationMediaPlaybackSnapshot mediaSnapshot;
      try {
        mediaSnapshot = await mediaController.resumeAfterLifecycle();
      } on Object {
        if (_isCurrent(token, restoredPhase)) {
          await _terminalize(
            token,
            RuntimePresentationExecutionResult.failed,
            diagnosticCode:
                RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
          );
        }
        return _snapshot;
      }
      if (!_isCurrent(token, restoredPhase)) {
        return _snapshot;
      }
      if (mediaSnapshot.status ==
          RuntimePresentationMediaPlaybackStatus.failed) {
        await _terminalize(
          token,
          RuntimePresentationExecutionResult.failed,
          diagnosticCode: mediaSnapshot.diagnosticCode,
        );
      }
      return _snapshot;
    });
    _pending = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  Future<RuntimePresentationExecutionSnapshot> pauseForLifecycle(
    RuntimePresentationRunToken token,
  ) =>
      pause(token);

  Future<RuntimePresentationExecutionSnapshot> resumeAfterLifecycle(
    RuntimePresentationRunToken token,
  ) =>
      resume(token);

  Future<RuntimePresentationExecutionTerminal?> complete(
    RuntimePresentationRunToken token,
  ) =>
      _finish(token, RuntimePresentationExecutionResult.completed);

  Future<RuntimePresentationExecutionTerminal?> skip(
    RuntimePresentationRunToken token,
  ) {
    _record(token, PresentationExecutionEventKind.skip);
    return _finish(token, RuntimePresentationExecutionResult.skipped);
  }

  Future<RuntimePresentationExecutionTerminal?> cancel(
    RuntimePresentationRunToken token, {
    RuntimePresentationCancellationReason reason =
        RuntimePresentationCancellationReason.requested,
  }) {
    return _finish(
      token,
      RuntimePresentationExecutionResult.cancelled,
      cancellationReason: reason,
    );
  }

  Future<RuntimePresentationExecutionTerminal?> fail(
    RuntimePresentationRunToken token, {
    required String diagnosticCode,
  }) {
    _recordFailure(token, diagnosticCode);
    return _finish(
      token,
      RuntimePresentationExecutionResult.failed,
      diagnosticCode: diagnosticCode,
    );
  }

  Future<void> dispose() {
    if (_disposed) return _pending;
    final token = _snapshot.runToken;
    if (token != null) {
      _record(token, PresentationExecutionEventKind.dispose);
    }
    _disposed = true;
    final termination = token != null &&
            (_snapshot.phase == RuntimePresentationExecutionPhase.running ||
                _snapshot.phase ==
                    RuntimePresentationExecutionPhase.interactionHold ||
                _snapshot.phase == RuntimePresentationExecutionPhase.paused ||
                _snapshot.phase ==
                    RuntimePresentationExecutionPhase.terminating)
        ? cancel(
            token,
            reason: RuntimePresentationCancellationReason.disposed,
          )
        : Future<RuntimePresentationExecutionTerminal?>.value(
            _snapshot.terminal,
          );
    final result = termination.then((_) => mediaController.dispose());
    _pending = result.onError((_, __) {});
    return result;
  }

  Future<RuntimePresentationExecutionTerminal?> _finish(
    RuntimePresentationRunToken token,
    RuntimePresentationExecutionResult result, {
    RuntimePresentationCancellationReason? cancellationReason,
    String? diagnosticCode,
  }) {
    if (_snapshot.runToken != token) return Future.value(null);
    if (_snapshot.phase == RuntimePresentationExecutionPhase.terminated) {
      return Future.value(_snapshot.terminal);
    }
    if (_snapshot.phase == RuntimePresentationExecutionPhase.terminating) {
      return _pending.then((_) => _snapshot.terminal);
    }
    _snapshot = RuntimePresentationExecutionSnapshot(
      phase: RuntimePresentationExecutionPhase.terminating,
      runToken: token,
    );
    final terminal = _pending.then(
      (_) => _terminalize(
        token,
        result,
        cancellationReason: cancellationReason,
        diagnosticCode: diagnosticCode,
      ),
    );
    _pending = terminal.then<void>((_) {}, onError: (_, __) {});
    return terminal;
  }

  Future<RuntimePresentationExecutionTerminal> _terminalize(
    RuntimePresentationRunToken token,
    RuntimePresentationExecutionResult result, {
    RuntimePresentationCancellationReason? cancellationReason,
    String? diagnosticCode,
  }) async {
    final existing = _snapshot.terminal;
    if (_snapshot.runToken != token || existing != null) {
      if (existing != null) return existing;
      throw StateError('Presentation execution token is stale.');
    }
    var resolvedResult = result;
    var resolvedDiagnosticCode = diagnosticCode;
    try {
      await mediaController.release();
    } on Object {
      resolvedResult = RuntimePresentationExecutionResult.failed;
      resolvedDiagnosticCode =
          RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed;
    }
    if (resolvedResult == RuntimePresentationExecutionResult.failed) {
      resolvedDiagnosticCode ??=
          RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed;
      _recordFailure(token, resolvedDiagnosticCode);
    }
    final terminal = RuntimePresentationExecutionTerminal(
      runToken: token,
      result: resolvedResult,
      cancellationReason:
          resolvedResult == RuntimePresentationExecutionResult.cancelled
              ? cancellationReason
              : null,
      diagnosticCode: resolvedDiagnosticCode,
    );
    _snapshot = RuntimePresentationExecutionSnapshot(
      phase: RuntimePresentationExecutionPhase.terminated,
      runToken: token,
      terminal: terminal,
    );
    final terminalCompleter = _terminalCompleter;
    if (terminalCompleter != null && !terminalCompleter.isCompleted) {
      terminalCompleter.complete(terminal);
    }
    _finishObservability(
      resolvedResult,
      diagnosticCode: resolvedDiagnosticCode,
    );
    onTerminal?.call(terminal);
    return terminal;
  }

  void _finishObservability(
    RuntimePresentationExecutionResult result, {
    String? diagnosticCode,
  }) {
    final recorder = _observabilityRecorder;
    if (recorder == null) return;
    try {
      recorder.finish(
        switch (result) {
          RuntimePresentationExecutionResult.completed =>
            PresentationExecutionOutcome.completed,
          RuntimePresentationExecutionResult.skipped =>
            PresentationExecutionOutcome.skipped,
          RuntimePresentationExecutionResult.cancelled =>
            PresentationExecutionOutcome.cancelled,
          RuntimePresentationExecutionResult.failed =>
            PresentationExecutionOutcome.failed,
        },
        source: PresentationExecutionSource.player,
        stableErrorCode: result == RuntimePresentationExecutionResult.failed
            ? diagnosticCode
            : null,
      );
      final receipt = recorder.receipt;
      if (receipt == null) return;
      _lastReceipt = receipt;
      onReceipt?.call(receipt);
    } on Object {
      return;
    }
  }

  void _record(
    RuntimePresentationRunToken token,
    PresentationExecutionEventKind kind,
  ) {
    if (!_canObserve(token)) return;
    try {
      _observabilityRecorder?.record(
        kind,
        source: PresentationExecutionSource.player,
      );
    } on Object {
      return;
    }
  }

  void _recordFailure(
    RuntimePresentationRunToken token,
    String diagnosticCode,
  ) {
    if (!_canObserve(token)) return;
    final recorder = _observabilityRecorder;
    if (recorder == null) return;
    final last = recorder.lastEvent;
    if (last?.kind == PresentationExecutionEventKind.failure &&
        last?.stableErrorCode == diagnosticCode) {
      return;
    }
    try {
      recorder.record(
        PresentationExecutionEventKind.failure,
        source: PresentationExecutionSource.player,
        stableErrorCode: diagnosticCode,
      );
    } on Object {
      return;
    }
  }

  bool _canObserve(RuntimePresentationRunToken token) =>
      _snapshot.runToken == token &&
      (_snapshot.phase == RuntimePresentationExecutionPhase.running ||
          _snapshot.phase ==
              RuntimePresentationExecutionPhase.interactionHold ||
          _snapshot.phase == RuntimePresentationExecutionPhase.paused ||
          _snapshot.phase == RuntimePresentationExecutionPhase.terminating);

  bool _isCurrent(
    RuntimePresentationRunToken token,
    RuntimePresentationExecutionPhase phase,
  ) =>
      _snapshot.runToken == token && _snapshot.phase == phase;
}
