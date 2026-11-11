import 'dart:math' as math;
import 'dart:ui';

import 'package:map_core/map_core_domain.dart';

import 'presentation_gesture_projection.dart';
import 'presentation_pose_projection.dart';

enum PresentationCanvasGesture { move, rotate, scale }

const presentationCanvasHandleRadius = 14.0;
const presentationCanvasRotateHandleLift = 22.0;
const presentationCanvasMinimumScaleFactor = .01;
const presentationCanvasMaximumScaleFactor = 100.0;

typedef PresentationCanvasGestureUpdate = ({
  Map<String, Object?>? patch,
  PresentationCinematicAsset? projection,
  String? error,
});

PresentationCanvasGesture presentationCanvasGestureAt(
  Offset anchor, {
  Rect? bounds,
  Iterable<Offset> corners = const [],
}) {
  if (bounds != null &&
      (anchor -
                  (bounds.topCenter -
                      const Offset(0, presentationCanvasRotateHandleLift)))
              .distance <
          presentationCanvasHandleRadius) {
    return PresentationCanvasGesture.rotate;
  }
  if (bounds != null &&
      corners.any(
        (corner) => (corner - anchor).distance < presentationCanvasHandleRadius,
      )) {
    return PresentationCanvasGesture.scale;
  }
  return PresentationCanvasGesture.move;
}

Map<String, double> presentationCanvasPoseChanges({
  required PresentationCanvasGesture gesture,
  required PresentationVisualComposition pose,
  required Offset start,
  required Offset point,
  required Rect? initialBounds,
  required Size canvasSize,
}) {
  if (gesture == PresentationCanvasGesture.rotate && initialBounds != null) {
    final center = initialBounds.center;
    return {
      'rotationTurns':
          pose.rotationTurns +
          ((point - center).direction - (start - center).direction) /
              (2 * math.pi),
    };
  }
  if (gesture == PresentationCanvasGesture.scale && initialBounds != null) {
    final center = initialBounds.center;
    final original = (start - center).distance;
    final factor = original == 0
        ? 1.0
        : ((point - center).distance / original).clamp(
            presentationCanvasMinimumScaleFactor,
            presentationCanvasMaximumScaleFactor,
          );
    return {'scaleX': pose.scaleX * factor, 'scaleY': pose.scaleY * factor};
  }
  final delta = point - start;
  return {
    'translateX': pose.translateX + delta.dx / canvasSize.width,
    'translateY': pose.translateY + delta.dy / canvasSize.height,
  };
}

PresentationCanvasGestureUpdate presentationCanvasGestureUpdate(
  PresentationCinematicAsset asset,
  PresentationClip clip, {
  required PresentationCanvasGesture gesture,
  required Offset start,
  required Offset point,
  required Rect? initialBounds,
  required Size canvasSize,
  required PresentationPose pose,
  required bool orientationOverride,
  required bool portrait,
}) {
  final changes = presentationCanvasPoseChanges(
    gesture: gesture,
    pose: presentationPose(
      clip,
      presentationPoseKey(
        pose: pose,
        orientationOverride: orientationOverride,
        portrait: portrait,
      ),
    ),
    start: start,
    point: point,
    initialBounds: initialBounds,
    canvasSize: canvasSize,
  );
  final patch = presentationPosePatch(
    clip,
    changes,
    pose: pose,
    orientationOverride: orientationOverride,
    portrait: portrait,
    preserveTrajectoryDelta: true,
  );
  try {
    return (
      patch: patch,
      projection: projectPresentationGesture(asset, clip, patch),
      error: null,
    );
  } catch (error) {
    return (patch: null, projection: null, error: 'Transformation refusée : $error');
  }
}

Map<String, Object?>? presentationCanvasCommittedPatch(
  Map<String, Object?>? pendingPatch,
  Offset delta,
) => pendingPatch != null && delta != Offset.zero ? pendingPatch : null;
