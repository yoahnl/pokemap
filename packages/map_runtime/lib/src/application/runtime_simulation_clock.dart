import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

final class RuntimeSimulationClock {
  static const stepSeconds = 1 / 60;
  static const maxFrameSeconds = 1.0;

  final speed = ValueNotifier(PlaytestSpeed.normal);

  int advanceFrame(double realSeconds, void Function(double) update) {
    if (!realSeconds.isFinite || realSeconds < 0) {
      throw ArgumentError.value(realSeconds, 'realSeconds');
    }
    final simulationSeconds =
        realSeconds.clamp(0, maxFrameSeconds) * speed.value.multiplier;
    if (simulationSeconds == 0) return 0;
    final count = (simulationSeconds / stepSeconds - 1e-10).ceil().clamp(
      1,
      600,
    );
    final step = simulationSeconds / count;
    for (var index = 0; index < count; index++) {
      update(step);
    }
    return count;
  }

  void dispose() => speed.dispose();
}
