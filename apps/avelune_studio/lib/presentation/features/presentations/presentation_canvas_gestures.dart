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
    gesture = presentationCanvasGestureAt(
      anchor,
      bounds: selected?.bounds,
      corners: selected?.corners ?? const [],
    );
    if (gesture == PresentationCanvasGesture.move) select(anchor);
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
    final update = presentationCanvasGestureUpdate(
      widget.asset,
      clip,
      gesture: gesture,
      start: start!,
      point: point,
      initialBounds: initialBounds,
      canvasSize: size,
      pose: widget.view.pose,
      orientationOverride: widget.view.orientationOverride,
      portrait: widget.view.portrait,
    );
    if (update.error == null) {
      projection = update.projection;
      pendingPatch = update.patch;
      widget.view.actionError = null;
    } else {
      pendingPatch = null;
      widget.view.actionError = update.error;
    }
    repaint();
  }

  void end() {
    final committed = presentationCanvasCommittedPatch(pendingPatch, delta);
    if (committed != null) widget.onPatch(committed);
    cancel();
  }
}
