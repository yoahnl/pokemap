import '../models/cinematic_asset.dart';
import '../authoring/cinematic_authoring_operations.dart';
import '../runtime/cinematic_visual_math.dart';
import 'cinematic_preview_playback_plan.dart';

final class CinematicViewportCamera {
  const CinematicViewportCamera({
    required this.centerX,
    required this.centerY,
    required this.visibleWidth,
    required this.visibleHeight,
  });

  final double centerX, centerY, visibleWidth, visibleHeight;

  CinematicViewportCamera interpolate(CinematicViewportCamera to, double t) =>
      CinematicViewportCamera(
        centerX: cinematicVisualLerp(centerX, to.centerX, t),
        centerY: cinematicVisualLerp(centerY, to.centerY, t),
        visibleWidth: cinematicVisualLerp(visibleWidth, to.visibleWidth, t),
        visibleHeight: cinematicVisualLerp(visibleHeight, to.visibleHeight, t),
      );
}

final class CinematicViewportFrame {
  const CinematicViewportFrame({
    required this.camera,
    required this.shakeOffsetX,
    required this.fadeOpacity,
  });

  final CinematicViewportCamera camera;
  final double shakeOffsetX;
  final double? fadeOpacity;
}

final class CinematicViewportProjection {
  CinematicViewportProjection({
    required CinematicPreviewPlaybackPlan plan,
    required this.initialCamera,
    required double cellWidth,
    required double cellHeight,
  }) : _plan = plan {
    var camera = initialCamera;
    for (final item in plan.timelineItems) {
      if (item.kind == CinematicTimelineStepKind.fade) {
        _fades[item.stepId] = plan.frameAt(item.startMs).fadeState?.mode;
      }
      if (item.kind != CinematicTimelineStepKind.camera) continue;
      final pose = plan.cameraPoseForStep(item.stepId);
      var target = camera;
      if (pose.mode == CinematicTimelineCameraMode.reset) {
        target = initialCamera;
      } else if (pose.mode == CinematicTimelineCameraMode.focus) {
        final geometry = pose.geometry;
        if (geometry.isAvailable &&
            geometry.centerX != null &&
            geometry.centerY != null &&
            geometry.zoomPreset != null) {
          final factor = cinematicCameraZoomFactor(geometry.zoomPreset!);
          target = CinematicViewportCamera(
            centerX: geometry.centerX! * cellWidth,
            centerY: geometry.centerY! * cellHeight,
            visibleWidth: initialCamera.visibleWidth * factor,
            visibleHeight: initialCamera.visibleHeight * factor,
          );
        }
      }
      _cameras[item.stepId] = (from: camera, to: target);
      camera = target;
    }
  }

  final CinematicViewportCamera initialCamera;
  final CinematicPreviewPlaybackPlan _plan;
  final _cameras =
      <String, ({CinematicViewportCamera from, CinematicViewportCamera to})>{};
  final _fades = <String, CinematicFadePlaybackMode?>{};

  CinematicViewportFrame frameAt(int timeMs) {
    final time = timeMs.clamp(0, _plan.totalDurationMs);
    var camera = initialCamera;
    var shake = 0.0;
    double? fade;
    for (final item in _plan.timelineItems) {
      if (time < item.startMs) break;
      final duration = item.durationMs;
      final progress = duration == null || duration <= 0
          ? 1.0
          : ((time - item.startMs) / duration).clamp(0.0, 1.0);
      switch (item.kind) {
        case CinematicTimelineStepKind.camera:
          final transition = _cameras[item.stepId]!;
          camera = transition.from.interpolate(transition.to, progress);
        case CinematicTimelineStepKind.shake:
          if (item.containsTime(time)) shake = cinematicShakeOffset(progress);
        case CinematicTimelineStepKind.fade:
          final mode = _fades[item.stepId];
          if (mode != null && mode != CinematicFadePlaybackMode.unknown) {
            fade = cinematicFadeOpacity(
              fadeOut: mode == CinematicFadePlaybackMode.fadeOut,
              progress: progress,
            );
          }
        default:
          break;
      }
    }
    return CinematicViewportFrame(
      camera: camera,
      shakeOffsetX: shake,
      fadeOpacity: fade,
    );
  }
}
