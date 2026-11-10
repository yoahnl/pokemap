part of 'presentation_canvas.dart';

extension _PresentationCanvasGestures on _PresentationCanvasState {
  void begin(Offset point) {
    if (widget.beforeSelection?.call() == false) return;
    if (widget.view.pan) return;
    final selected = geometry
        .snapshot()
        .where((item) => item.clipId == widget.view.selectedId)
        .firstOrNull;
    final anchor = pointerDown ?? point;
    gesture = 'move';
    if (selected != null &&
        (anchor - (selected.bounds.topCenter - const Offset(0, 22))).distance <
            14) {
      gesture = 'rotate';
    } else if (selected != null &&
        selected.corners.any((corner) => (corner - anchor).distance < 14)) {
      gesture = 'scale';
    } else {
      select(anchor);
    }
    final clip = widget.view.selected;
    if (clip == null || !widget.view.editing.isClipEditable(clip.id)) return;
    initialBounds = geometry
        .snapshot()
        .where((item) => item.clipId == clip.id)
        .firstOrNull
        ?.bounds;
    widget.transport.pause();
    start = point;
    dragging = clip;
    delta = Offset.zero;
    repaint();
  }

  void updateGesture(Offset point) {
    final clip = dragging, size = geometry.canvasSize;
    if (start == null || clip == null || size == null) return;
    delta = point - start!;
    final pose = presentationPose(
      clip,
      presentationPoseKey(
        pose: widget.view.pose,
        orientationOverride: widget.view.orientationOverride,
        portrait: widget.view.portrait,
      ),
    );
    final changes = <String, double>{};
    if (gesture == 'rotate' && initialBounds != null) {
      final center = initialBounds!.center;
      changes['rotationTurns'] =
          pose.rotationTurns +
          ((point - center).direction - (start! - center).direction) /
              (2 * 3.141592653589793);
    } else if (gesture == 'scale' && initialBounds != null) {
      final center = initialBounds!.center;
      final original = (start! - center).distance;
      final factor = original == 0
          ? 1.0
          : ((point - center).distance / original).clamp(.01, 100.0);
      changes['scaleX'] = pose.scaleX * factor;
      changes['scaleY'] = pose.scaleY * factor;
    } else {
      changes['translateX'] = pose.translateX + delta.dx / size.width;
      changes['translateY'] = pose.translateY + delta.dy / size.height;
    }
    final patch = presentationPosePatch(
      clip,
      changes,
      pose: widget.view.pose,
      orientationOverride: widget.view.orientationOverride,
      portrait: widget.view.portrait,
      preserveTrajectoryDelta: true,
    );
    try {
      projection = projectPresentationGesture(widget.asset, clip, patch);
      pendingPatch = patch;
      widget.view.actionError = null;
    } catch (error) {
      pendingPatch = null;
      widget.view.actionError = 'Transformation refusée : $error';
    }
    repaint();
  }

  void end() {
    if (pendingPatch != null && delta != Offset.zero) {
      widget.onPatch(pendingPatch!);
    }
    cancel();
  }
}
