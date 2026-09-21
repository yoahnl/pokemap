import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_frame_geometry.dart';
import '../../../features/presentations/application/presentation_preview_transport.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../theme/studio_tokens.dart';
import 'presentation_workspace_visuals.dart';
import 'presentation_view_state.dart';
import 'presentation_transport_listenable.dart';
import 'presentation_pose_projection.dart';
import 'presentation_gesture_projection.dart';

part 'presentation_canvas_gestures.dart';

class PresentationCanvas extends StatefulWidget {
  const PresentationCanvas({
    super.key,
    required this.asset,
    required this.view,
    required this.transport,
    required this.visuals,
    required this.onPatch,
    required this.changed,
    this.beforeSelection,
  });
  final PresentationCinematicAsset asset;
  final PresentationViewState view;
  final PresentationPreviewTransport transport;
  final PresentationWorkspaceVisuals visuals;
  final bool Function(Map<String, Object?>) onPatch;
  final VoidCallback changed;
  final bool Function()? beforeSelection;
  @override
  State<PresentationCanvas> createState() => _PresentationCanvasState();
}

class _PresentationCanvasState extends State<PresentationCanvas> {
  final geometry = PresentationFrameGeometryController();
  Offset? pointerDown;
  Offset? start;
  Offset delta = Offset.zero;
  PresentationClip? dragging;
  String gesture = 'move';
  Rect? initialBounds;
  PresentationCinematicAsset? projection;
  Map<String, Object?>? pendingPatch;
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(handleKey);
    super.dispose();
  }

  bool handleKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        start == null) {
      return false;
    }
    cancel();
    return true;
  }

  void repaint() => setState(() {});
  void cancel() => setState(() {
    start = null;
    delta = Offset.zero;
    dragging = null;
    projection = null;
    pendingPatch = null;
  });
  void select(Offset position) {
    if (widget.beforeSelection?.call() == false) return;
    final hit = geometry.hitTest(position);
    if (hit == null) {
      widget.view.editing.clearSelection();
    } else {
      widget.view.editing.selectClip(
        hit.clipId,
        additive: HardwareKeyboard.instance.isShiftPressed,
      );
    }
    widget.changed();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): cancel},
    child: AnimatedBuilder(
      animation: Listenable.merge([
        PresentationTransportListenable(widget.transport),
        widget.visuals,
      ]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final portrait = widget.view.portrait;
          final ratio = portrait ? 9 / 16 : 16 / 9;
          final frame = projection == null
              ? widget.transport.frame
              : const PresentationCinematicEvaluator().evaluate(
                  projection!,
                  timeUs: widget.transport.timeUs,
                );
          return Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: widget.view.canvasTransform,
                  panEnabled: widget.view.pan,
                  scaleEnabled: widget.view.pan,
                  minScale: .25,
                  maxScale: 8,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: Listener(
                        onPointerDown: (event) =>
                            pointerDown = event.localPosition,
                        child: GestureDetector(
                          key: const ValueKey('presentation-canvas'),
                          onTapUp: (event) => select(event.localPosition),
                          onPanStart: widget.view.pan
                              ? null
                              : (event) => begin(event.localPosition),
                          onPanUpdate: widget.view.pan
                              ? null
                              : (event) {
                                  updateGesture(event.localPosition);
                                },
                          onPanEnd: widget.view.pan ? null : (_) => end(),
                          onPanCancel: cancel,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (frame != null)
                                widget.visuals.frame(
                                  asset: projection ?? widget.asset,
                                  frame: frame,
                                  portrait: portrait,
                                  geometry: geometry,
                                  reduceMotion: widget.view.reduceMotion,
                                  reduceFlashes: widget.view.reduceFlashes,
                                  showCaptions: widget.view.captions,
                                ),
                              IgnorePointer(
                                child: CustomPaint(
                                  painter: _SelectionPainter(
                                    geometry,
                                    widget.view.editing.selectedClipIds,
                                    StudioColors.of(context).canvasSelection,
                                    Offset.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Column(
                  children: [
                    StudioTool(
                      label: 'Sélectionner',
                      icon: Icons.near_me_outlined,
                      selected: !widget.view.pan,
                      onPressed: () {
                        widget.view.pan = false;
                        widget.changed();
                      },
                    ),
                    const SizedBox(height: 6),
                    StudioTool(
                      label: 'Déplacer la vue',
                      icon: Icons.pan_tool_outlined,
                      selected: widget.view.pan,
                      onPressed: () {
                        widget.view.pan = true;
                        widget.changed();
                      },
                    ),
                    const SizedBox(height: 6),
                    StudioTool(
                      label: 'Ajuster le canevas',
                      icon: Icons.fit_screen,
                      onPressed: () {
                        widget.view.canvasTransform.value = Matrix4.identity();
                      },
                    ),
                  ],
                ),
              ),
              if (widget.visuals.loading)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
    ),
  );
}

class _SelectionPainter extends CustomPainter {
  _SelectionPainter(this.geometry, this.ids, this.color, this.delta);
  final PresentationFrameGeometryController geometry;
  final Set<String> ids;
  final Color color;
  final Offset delta;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final item in geometry.snapshot()) {
      if (!ids.contains(item.clipId)) continue;
      canvas.save();
      canvas.translate(delta.dx, delta.dy);
      canvas.drawPath(item.visiblePath, paint);
      for (final corner in item.corners) {
        canvas.drawRect(
          Rect.fromCenter(center: corner, width: 7, height: 7),
          paint,
        );
      }
      final rotation = item.bounds.topCenter - const Offset(0, 22);
      canvas.drawLine(item.bounds.topCenter, rotation, paint);
      canvas.drawCircle(rotation, 5, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter old) => true;
}
