import 'package:map_core/map_core.dart';

/// Resolves the editor preview frame for a Surface animation timeline.
///
/// Surface timelines are authored as cyclic loops. The editor preview only
/// needs a deterministic frame at a given elapsed time; it does not own runtime
/// clocks or persist any calculated animation state.
SurfaceAnimationFrame resolveSurfaceAnimationFrameAtElapsedMs({
  required SurfaceAnimationTimeline timeline,
  required int elapsedMs,
}) {
  if (timeline.frames.length == 1) {
    return timeline.frames.single;
  }

  final normalizedElapsedMs = elapsedMs < 0 ? 0 : elapsedMs;
  final totalDurationMs = timeline.totalDurationMs;
  if (totalDurationMs <= 0) {
    return timeline.frames.first;
  }

  var t = normalizedElapsedMs % totalDurationMs;
  for (final frame in timeline.frames) {
    if (t < frame.durationMs) {
      return frame;
    }
    t -= frame.durationMs;
  }
  return timeline.frames.first;
}
