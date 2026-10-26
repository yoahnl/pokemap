import '../models/cinematic_asset.dart';
import '../models/spatial_visual_profile.dart';
import '../runtime/cinematic_timeline_schedule.dart';

SpatialVisualPatch sampleCinematicVisualProfile({
  required CinematicAsset cinematic,
  required SpatialVisualPatch base,
  required int elapsedMs,
}) {
  var result = base;
  for (final group in buildCinematicTimelineSchedule(
    cinematic,
    timing: CinematicTimelineScheduleTiming.runtime,
  ).groups) {
    for (final member in group.members) {
      final step = member.step;
      if (step.kind != CinematicTimelineStepKind.atmosphere) continue;
      if (elapsedMs < group.startMs) continue;
      final target = result.overriddenBy(step.visualSettings!);
      final duration = step.durationMs ?? 0;
      final progress = duration == 0
          ? 1.0
          : ((elapsedMs - group.startMs) / duration).clamp(0.0, 1.0);
      result = SpatialVisualPatch.interpolate(result, target, progress);
    }
  }
  return result;
}
