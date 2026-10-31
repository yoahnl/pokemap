import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';

class InstallProgressRelay {
  InstallProgressRelay({
    required this.channel,
    Duration Function()? elapsed,
    this.minimumInterval = const Duration(milliseconds: 100),
  }) : _elapsed = elapsed ?? _stopwatchClock();

  final MethodChannel channel;
  final Duration Function() _elapsed;
  final Duration minimumInterval;
  GameInstallStage? _lastStage;
  Duration? _lastSentAt;

  void call(GameInstallProgress progress) {
    final now = _elapsed();
    final lastSentAt = _lastSentAt;
    final sameStage = progress.stage == _lastStage;
    if (sameStage && lastSentAt != null && now - lastSentAt < minimumInterval) {
      return;
    }
    _lastStage = progress.stage;
    _lastSentAt = now;
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
