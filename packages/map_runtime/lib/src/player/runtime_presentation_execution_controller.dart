import 'runtime_presentation_media_playback_controller.dart';

enum RuntimePresentationExecutionPhase {
  idle,
  running,
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

final class RuntimePresentationExecutionController {
  RuntimePresentationExecutionController({
    required this.mediaController,
    this.onTerminal,
  });

  final RuntimePresentationMediaPlaybackController mediaController;
  final RuntimePresentationExecutionTerminalSink? onTerminal;

  Future<void> _pending = Future<void>.value();
  RuntimePresentationExecutionSnapshot _snapshot =
      RuntimePresentationExecutionSnapshot.idle;
  var _nextRunToken = 1;
  var _disposed = false;

  RuntimePresentationExecutionSnapshot get snapshot => _snapshot;

  RuntimePresentationRunToken start() {
    if (_disposed) {
      throw StateError('Presentation execution controller is disposed.');
    }
    if (_snapshot.phase != RuntimePresentationExecutionPhase.idle &&
        _snapshot.phase != RuntimePresentationExecutionPhase.terminated) {
      throw StateError('A Presentation execution is already active.');
    }
    final token = RuntimePresentationRunToken(_nextRunToken++);
    _snapshot = RuntimePresentationExecutionSnapshot(
      phase: RuntimePresentationExecutionPhase.running,
      runToken: token,
    );
    return token;
  }

  Future<RuntimePresentationExecutionSnapshot> pause(
    RuntimePresentationRunToken token,
  ) {
    if (!_isCurrent(token, RuntimePresentationExecutionPhase.running)) {
      return Future.value(_snapshot);
    }
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
    _snapshot = RuntimePresentationExecutionSnapshot(
      phase: RuntimePresentationExecutionPhase.running,
      runToken: token,
    );
    final result = _pending.then((_) async {
      if (!_isCurrent(token, RuntimePresentationExecutionPhase.running)) {
        return _snapshot;
      }
      RuntimePresentationMediaPlaybackSnapshot mediaSnapshot;
      try {
        mediaSnapshot = await mediaController.resumeAfterLifecycle();
      } on Object {
        if (_isCurrent(token, RuntimePresentationExecutionPhase.running)) {
          await _terminalize(
            token,
            RuntimePresentationExecutionResult.failed,
            diagnosticCode:
                RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
          );
        }
        return _snapshot;
      }
      if (!_isCurrent(token, RuntimePresentationExecutionPhase.running)) {
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
  ) =>
      _finish(token, RuntimePresentationExecutionResult.skipped);

  Future<RuntimePresentationExecutionTerminal?> cancel(
    RuntimePresentationRunToken token, {
    RuntimePresentationCancellationReason reason =
        RuntimePresentationCancellationReason.requested,
  }) =>
      _finish(
        token,
        RuntimePresentationExecutionResult.cancelled,
        cancellationReason: reason,
      );

  Future<RuntimePresentationExecutionTerminal?> fail(
    RuntimePresentationRunToken token, {
    required String diagnosticCode,
  }) =>
      _finish(
        token,
        RuntimePresentationExecutionResult.failed,
        diagnosticCode: diagnosticCode,
      );

  Future<void> dispose() {
    if (_disposed) return _pending;
    _disposed = true;
    final token = _snapshot.runToken;
    final termination = token != null &&
            (_snapshot.phase == RuntimePresentationExecutionPhase.running ||
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
    onTerminal?.call(terminal);
    return terminal;
  }

  bool _isCurrent(
    RuntimePresentationRunToken token,
    RuntimePresentationExecutionPhase phase,
  ) =>
      _snapshot.runToken == token && _snapshot.phase == phase;
}
