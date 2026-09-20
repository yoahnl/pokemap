import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'dialogue_graph_controls.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'dialogue_view_state.dart';
import 'dialogue_graph_geometry.dart';
import 'dialogue_graph_node.dart';
import 'dialogue_graph_painter.dart';

class DialogueGraphCanvas extends StatefulWidget {
  const DialogueGraphCanvas({
    super.key,
    required this.document,
    required this.view,
    required this.changed,
    required this.onConnect,
    required this.onDelete,
    required this.onUndo,
    required this.onRedo,
    required this.onSave,
    this.portrait,
    this.outcomes = const {},
  });
  final DialogueEditorDocument document;
  final DialogueViewState view;
  final VoidCallback changed, onDelete, onUndo, onRedo, onSave;
  final void Function(String portId, String targetId) onConnect;
  final Widget Function(String?, String?, double)? portrait;
  final Map<String, String> outcomes;
  @override
  State<DialogueGraphCanvas> createState() => _DialogueGraphCanvasState();
}

class _DialogueGraphCanvasState extends State<DialogueGraphCanvas> {
  final key = GlobalKey();
  final focus = FocusNode();
  String? source, target;
  int? port;
  Offset? end;
  late DialogueGraphGeometry geometry;
  @override
  void initState() {
    super.initState();
    widget.view.viewport.addListener(refresh);
  }

  @override
  void didUpdateWidget(DialogueGraphCanvas old) {
    super.didUpdateWidget(old);
    if (old.document != widget.document) cancel();
    if (old.view != widget.view) {
      old.view.viewport.removeListener(refresh);
      widget.view.viewport.addListener(refresh);
      cancel();
    }
  }

  @override
  void dispose() {
    widget.view.viewport.removeListener(refresh);
    focus.dispose();
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void cancel() {
    source = null;
    port = null;
    target = null;
    end = null;
  }

  void select(String id, {String? step, String? branch}) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    focus.requestFocus();
    widget.view.select(id, step: step, branch: branch);
    widget.changed();
  }

  void wireMove(Offset global) {
    final box = key.currentContext!.findRenderObject() as RenderBox;
    end = box.globalToLocal(global);
    target = null;
    for (final node in widget.document.nodes) {
      final position = widget.view.viewport.worldToLocal(
        geometry.input(node.id),
      );
      if ((position - end!).distance < 32) {
        target = node.id;
        end = position;
        break;
      }
    }
    refresh();
  }

  void wireEnd() {
    final from = source, to = target, index = port;
    if (from != null && to != null && index != null) {
      widget.onConnect(geometry.rows[from]![index].id, to);
    }
    cancel();
    refresh();
  }

  KeyEventResult onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final modifier =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (key == LogicalKeyboardKey.escape) {
      cancel();
      refresh();
      return KeyEventResult.handled;
    }
    if (modifier && key == LogicalKeyboardKey.keyS) {
      widget.onSave();
      return KeyEventResult.handled;
    }
    if (modifier && key == LogicalKeyboardKey.keyZ) {
      (HardwareKeyboard.instance.isShiftPressed
          ? widget.onRedo
          : widget.onUndo)();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      widget.onDelete();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    geometry = DialogueGraphGeometry(
      widget.document,
      widget.view,
      MediaQuery.textScalerOf(context).scale(14) / 14,
    );
    final view = widget.view.viewport;
    final colors = Theme.of(context).colorScheme;
    final painter = DialogueGraphPainter(
      geometry: geometry,
      grid: colors.outlineVariant,
      wire: StudioTone.info.color(context),
      accent: StudioTone.success.color(context),
      pendingStart: source == null
          ? null
          : view.worldToLocal(geometry.output(source!, port!)),
      pendingEnd: end,
    );
    return Focus(
      focusNode: focus,
      onKeyEvent: onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          view.size = constraints.biggest;
          if (!view.initialized) {
            view.initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) view.fit(geometry.bounds);
            });
          }
          return ClipRect(
            child: ColoredBox(
              color: colors.surfaceContainerLowest,
              child: Stack(
                key: key,
                children: [
                  Positioned.fill(
                    child: Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          if (HardwareKeyboard.instance.isControlPressed ||
                              HardwareKeyboard.instance.isMetaPressed) {
                            view.zoomAt(
                              view.zoom * (event.scrollDelta.dy > 0 ? .9 : 1.1),
                              event.localPosition,
                            );
                          } else {
                            view.translate(-event.scrollDelta);
                          }
                        }
                      },
                      onPointerPanZoomStart: (event) =>
                          view.startTrackpad(event.localPosition),
                      onPointerPanZoomUpdate: (event) => view.updateTrackpad(
                        event.scale,
                        event.pan,
                        event.localPosition,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (event) {
                          focus.requestFocus();
                          widget.view.wireId = painter.hit(event.localPosition);
                          widget.changed();
                        },
                        onPanUpdate: (event) => view.translate(event.delta),
                        child: CustomPaint(painter: painter),
                      ),
                    ),
                  ),
                  for (final node in widget.document.nodes)
                    Positioned(
                      left: view
                          .worldToLocal(geometry.rect(node.id).topLeft)
                          .dx,
                      top: view.worldToLocal(geometry.rect(node.id).topLeft).dy,
                      width: geometry.width * view.zoom,
                      height: geometry.rect(node.id).height * view.zoom,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: geometry.width,
                          height: geometry.rect(node.id).height,
                          child: DialogueGraphNode(
                            portrait: widget.portrait,
                            outcomes: widget.outcomes,
                            node: node,
                            geometry: geometry,
                            target: target == node.id,
                            onSelect: ({step, branch}) =>
                                select(node.id, step: step, branch: branch),
                            onMove: (delta) {
                              widget.view.positions[node.id] =
                                  widget.view.positions[node.id]! + delta;
                              refresh();
                            },
                            onWireStart: (index) {
                              select(node.id);
                              source = node.id;
                              port = index;
                              end = view.worldToLocal(
                                geometry.output(node.id, index),
                              );
                              refresh();
                            },
                            onWireMove: wireMove,
                            onWireEnd: wireEnd,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: DialogueGraphControls(geometry: geometry),
                  ),
                  if (view.size.width > 600 && source == null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: DialogueMinimap(geometry: geometry),
                    ),
                  if (source != null)
                    const Positioned(
                      left: 12,
                      bottom: 12,
                      child: StudioBadge(
                        'Relier à une entrée · Échap pour annuler',
                        tone: StudioTone.info,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
