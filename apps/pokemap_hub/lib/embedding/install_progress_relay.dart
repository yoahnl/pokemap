import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';

typedef InstallProgressTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

class InstallProgressRelay {
  InstallProgressRelay({
    required this.channel,
    Duration Function()? elapsed,
    this.minimumInterval = const Duration(milliseconds: 100),
    InstallProgressTimerFactory? timerFactory,
  }) : _elapsed = elapsed ?? _stopwatchClock(),
       _timerFactory = timerFactory ?? Timer.new;

  final MethodChannel channel;
  final Duration Function() _elapsed;
  final Duration minimumInterval;
  final InstallProgressTimerFactory _timerFactory;
  GameInstallStage? _lastStage;
  Duration? _lastSentAt;
  GameInstallProgress? _pending;
  Timer? _trailingTimer;

  void call(GameInstallProgress progress) {
    final lastSentAt = _lastSentAt;
    if (lastSentAt == null || progress.stage != _lastStage) {
      flush();
      _send(progress);
      return;
    }
    final sinceLastSend = _elapsed() - lastSentAt;
    if (sinceLastSend >= minimumInterval) {
      _discardPending();
      _send(progress);
      return;
    }
    _pending = progress;
    _trailingTimer ??= _timerFactory(minimumInterval - sinceLastSend, flush);
  }

  void flush() {
    final pending = _pending;
    _discardPending();
    if (pending != null) {
      _send(pending);
    }
  }

  void dispose() => flush();

  void _discardPending() {
    _trailingTimer?.cancel();
    _trailingTimer = null;
    _pending = null;
  }

  void _send(GameInstallProgress progress) {
    _lastStage = progress.stage;
    _lastSentAt = _elapsed();
    final measured = progress.totalBytes > 0;
    unawaited(
      channel
          .invokeMethod<void>('installProgress', <String, Object?>{
            'stage': progress.stage.name,
            'completedBytes': measured ? progress.completedBytes : null,
            'totalBytes': measured ? progress.totalBytes : null,
          })
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }

  static Duration Function() _stopwatchClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }
}
