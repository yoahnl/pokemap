import 'dart:async';

import 'package:map_core/map_core.dart';

enum RuntimeWarpPresentationPhase {
  idle,
  beforeTransfer,
  transferring,
  afterTransfer,
  completed,
  blocked,
  cancelled,
}

enum RuntimeWarpPresentationOutcome { completed, blocked, cancelled }

final class RuntimeWarpPresentationFrame {
  const RuntimeWarpPresentationFrame({
    this.worldOpacity = 0,
    this.illustrationOpacity = 0,
    this.caveElapsedMs,
    this.caveRecoveryOpacity = 0,
  });
  final double worldOpacity;
  final double illustrationOpacity;
  final int? caveElapsedMs;
  final double caveRecoveryOpacity;
}

final class RuntimeWarpPresentationController {
  RuntimeWarpPresentationController({
    required this.presentation,
    required this.transfer,
  });
  final SceneWarpPresentation presentation;
  final Future<bool> Function() transfer;
  final _completion = Completer<RuntimeWarpPresentationOutcome>();
  var _phase = RuntimeWarpPresentationPhase.idle;
  var _elapsedUs = 0;
  var _transferPending = false;

  RuntimeWarpPresentationPhase get phase => _phase;
  Future<RuntimeWarpPresentationOutcome> get outcome => _completion.future;
  int get _elapsedMs => _elapsedUs ~/ Duration.microsecondsPerMillisecond;
  int get _beforeTransferMs =>
      presentation.transferDelayMs +
      (presentation.hasCaveEffect
          ? SceneWarpPresentation.caveBandsMs +
                SceneWarpPresentation.caveFillMs +
                SceneWarpPresentation.cavePauseMs
          : 0);
  int get _afterTransferMs => presentation.illustrationElementId == null
      ? presentation.revealMs
      : presentation.illustrationHoldMs! +
            (presentation.illustrationFadeMs! > presentation.revealMs
                ? presentation.illustrationFadeMs!
                : presentation.revealMs);

  RuntimeWarpPresentationFrame get frame {
    if (_phase == RuntimeWarpPresentationPhase.beforeTransfer ||
        _phase == RuntimeWarpPresentationPhase.transferring) {
      final elapsed = _phase == RuntimeWarpPresentationPhase.transferring
          ? _beforeTransferMs
          : _elapsedMs;
      final caveElapsed =
          presentation.hasCaveEffect && elapsed >= presentation.transferDelayMs
          ? elapsed - presentation.transferDelayMs
          : null;
      return RuntimeWarpPresentationFrame(
        worldOpacity: (elapsed / presentation.fadeOutMs).clamp(0.0, 1.0),
        illustrationOpacity:
            presentation.mode == SceneWarpPresentationMode.caveEntrance &&
                elapsed >= presentation.transferDelayMs
            ? 1
            : 0,
        caveElapsedMs: caveElapsed,
      );
    }
    if (_phase != RuntimeWarpPresentationPhase.afterTransfer) {
      return const RuntimeWarpPresentationFrame();
    }
    final revealElapsed = _elapsedMs - (presentation.illustrationHoldMs ?? 0);
    return RuntimeWarpPresentationFrame(
      worldOpacity: presentation.hasCaveEffect
          ? 0
          : (1 - revealElapsed / presentation.revealMs).clamp(0.0, 1.0),
      illustrationOpacity: presentation.illustrationElementId == null
          ? 0
          : (1 - revealElapsed / presentation.illustrationFadeMs!).clamp(
              0.0,
              1.0,
            ),
      caveRecoveryOpacity: presentation.hasCaveEffect
          ? (1 -
                    SceneWarpPresentation.cavePauseMs /
                        SceneWarpPresentation.caveFillMs) *
                (1 - _elapsedMs / presentation.revealMs).clamp(0.0, 1.0)
          : 0,
    );
  }

  Future<RuntimeWarpPresentationOutcome> start() {
    if (_phase == RuntimeWarpPresentationPhase.idle) {
      _phase = RuntimeWarpPresentationPhase.beforeTransfer;
    }
    return outcome;
  }

  void advance(Duration duration) {
    if (duration.isNegative) throw ArgumentError.value(duration, 'duration');
    if (_phase != RuntimeWarpPresentationPhase.beforeTransfer &&
        _phase != RuntimeWarpPresentationPhase.afterTransfer) {
      return;
    }
    _elapsedUs += duration.inMicroseconds;
    if (_phase == RuntimeWarpPresentationPhase.beforeTransfer &&
        _elapsedMs >= _beforeTransferMs) {
      _phase = RuntimeWarpPresentationPhase.transferring;
      unawaited(_transfer());
    } else if (_phase == RuntimeWarpPresentationPhase.afterTransfer &&
        _elapsedMs >= _afterTransferMs) {
      _finish(RuntimeWarpPresentationOutcome.completed);
    }
  }

  Future<void> _transfer() async {
    _transferPending = true;
    try {
      final transferred = await transfer();
      if (_phase != RuntimeWarpPresentationPhase.transferring) return;
      if (!transferred) {
        _finish(RuntimeWarpPresentationOutcome.blocked);
        return;
      }
      _elapsedUs = 0;
      _phase = RuntimeWarpPresentationPhase.afterTransfer;
    } catch (_) {
      if (_phase == RuntimeWarpPresentationPhase.transferring) {
        _finish(RuntimeWarpPresentationOutcome.blocked);
      }
    } finally {
      _transferPending = false;
      if (_phase == RuntimeWarpPresentationPhase.cancelled) {
        _finish(RuntimeWarpPresentationOutcome.cancelled);
      }
    }
  }

  void cancel() {
    if (_completion.isCompleted) return;
    if (_transferPending) {
      _phase = RuntimeWarpPresentationPhase.cancelled;
    } else {
      _finish(RuntimeWarpPresentationOutcome.cancelled);
    }
  }

  void _finish(RuntimeWarpPresentationOutcome result) {
    if (_completion.isCompleted) return;
    _phase = switch (result) {
      RuntimeWarpPresentationOutcome.completed =>
        RuntimeWarpPresentationPhase.completed,
      RuntimeWarpPresentationOutcome.blocked =>
        RuntimeWarpPresentationPhase.blocked,
      RuntimeWarpPresentationOutcome.cancelled =>
        RuntimeWarpPresentationPhase.cancelled,
    };
    _completion.complete(result);
  }
}
