import 'package:flutter/foundation.dart';

@immutable
class CinematicTimelineZoomState {
  const CinematicTimelineZoomState({this.scale = defaultScale})
      : assert(scale >= minScale),
        assert(scale <= maxScale);

  factory CinematicTimelineZoomState.clamped(double scale) {
    if (!scale.isFinite) {
      return const CinematicTimelineZoomState();
    }
    return CinematicTimelineZoomState(
      scale: clampScale(scale),
    );
  }

  static const double defaultScale = 1.0;
  static const double minScale = 0.25;
  static const double maxScale = 4.0;
  static const double step = 0.25;

  final double scale;

  int get percentage => (scale * 100).round();

  bool get canZoomIn => scale < maxScale;

  bool get canZoomOut => scale > minScale;

  bool get canReset => scale != defaultScale;

  CinematicTimelineZoomState copyWithScale(double nextScale) {
    return CinematicTimelineZoomState.clamped(nextScale);
  }

  static double clampScale(double scale) {
    return scale.clamp(minScale, maxScale).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is CinematicTimelineZoomState && other.scale == scale;
  }

  @override
  int get hashCode => scale.hashCode;
}
