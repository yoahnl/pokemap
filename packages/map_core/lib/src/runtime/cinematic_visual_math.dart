import 'dart:math' as math;

import '../authoring/cinematic_authoring_operations.dart';

double cinematicCameraZoomFactor(CinematicCameraZoomPreset preset) =>
    switch (preset) {
      CinematicCameraZoomPreset.wide => 1,
      CinematicCameraZoomPreset.medium => .8,
      CinematicCameraZoomPreset.close => .6,
    };

double cinematicVisualLerp(double from, double to, double progress) =>
    from + (to - from) * progress.clamp(0.0, 1.0);

double cinematicShakeOffset(double progress) {
  final bounded = progress.clamp(0.0, 1.0);
  return math.sin(bounded * math.pi * 3) * 6 * math.sin(bounded * math.pi);
}

double cinematicFadeOpacity({required bool fadeOut, required double progress}) {
  final bounded = progress.clamp(0.0, 1.0);
  return fadeOut ? bounded : 1 - bounded;
}
