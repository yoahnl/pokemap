import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_overlay_editing.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'map_canvas_stroke.dart';
import 'map_character_gesture.dart';

class MapWorkspaceCanvas extends StatefulWidget {
  const MapWorkspaceCanvas({
    super.key,
    required this.document,
    required this.project,
    required this.visuals,
    required this.view,
    required this.onChanged,
    required this.gestureGeneration,
    this.onZoneDrawn,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final int gestureGeneration;
  final ValueChanged<MapRect>? onZoneDrawn;
  @override
  State<MapWorkspaceCanvas> createState() => _MapWorkspaceCanvasState();
}

class _MapWorkspaceCanvasState extends State<MapWorkspaceCanvas> {
  final _focus = FocusNode();
  GridPos? _start;
  GridPos? _preview;
  MapPlacedElement? _moving;
  MapCanvasStroke? _stroke;
  MapData? _gestureSource;
  MapCharacterGesture? _characterGesture;
  double get _width =>
      widget.project.settings.tileWidth *
      widget.project.settings.displayScale.toDouble();
  double get _height =>
      widget.project.settings.tileHeight *
      widget.project.settings.displayScale.toDouble();
  MapEditingCommands get _commands =>
      MapEditingCommands(widget.document, widget.project);
  GridPos _cell(Offset position) => GridPos(
    x: (position.dx / _width).floor(),
    y: (position.dy / _height).floor(),
  );

  @override
  void didUpdateWidget(MapWorkspaceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document ||
        oldWidget.gestureGeneration != widget.gestureGeneration) {
      _cancel();
    }
  }

  void _down(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton ||
        widget.view.tool == StudioMapTool.pan) {
      return;
    }
    _focus.requestFocus();
    final cell = _cell(event.localPosition);
    try {
      _characterGesture = MapCharacterGesture.start(
        document: widget.document,
        project: widget.project,
        view: widget.view,
        origin: cell,
      );
      if (_characterGesture != null) {
        widget.view.selectedTriggerId = null;
        widget.onChanged();
        return;
      }
    } catch (error) {
      widget.document.error = error.toString();
      widget.onChanged();
      return;
    }
    _start = cell;
    _gestureSource = widget.document.current;
    final tool = widget.view.tool;
    if (tool == StudioMapTool.place) {
      final brush = widget.view.brush;
      if (brush != null) _commands.place(brush, cell);
      _cancel();
      widget.onChanged();
    } else if (tool == StudioMapTool.select) {
      widget.view.selectedEntityId = null;
      widget.view.selectedTriggerId = null;
      widget.view.selectedWarpId = null;
      widget.view.selectedPlacementId = null;
      final hits = _commands.stack(cell);
      final selected = widget.document.selected;
      _moving = selected != null && hits.any((e) => e.id == selected.id)
          ? selected
          : hits.firstOrNull;
      widget.document.selectedId = _moving?.id;
      widget.document.stackPosition = cell;
      widget.onChanged();
    } else {
      try {
        _stroke = MapCanvasStroke.start(
          map: widget.document.current,
          project: widget.project,
          view: widget.view,
          commands: _commands,
          origin: cell,
        );
        setState(() {});
      } catch (error) {
        widget.document.error = error.toString();
        _cancel();
        widget.onChanged();
      }
    }
  }

  void _paint(GridPos cell) {
    _stroke?.paint(cell);
    setState(() {});
  }

  void _move(PointerMoveEvent event) {
    if (_characterGesture != null) {
      setState(() => _characterGesture!.move(_cell(event.localPosition)));
      return;
    }
    final start = _start;
    if (start == null) return;
    final cell = _cell(event.localPosition);
    if (_stroke != null) {
      _paint(cell);
      return;
    }
    final moving = _moving;
    if (moving != null) {
      setState(
        () => _preview = GridPos(
          x: moving.pos.x + cell.x - start.x,
          y: moving.pos.y + cell.y - start.y,
        ),
      );
    }
  }

  void _up(PointerUpEvent event) {
    if (_characterGesture != null) {
      final zone = _characterGesture!.commit();
      setState(_cancel);
      widget.onChanged();
      if (zone != null) widget.onZoneDrawn?.call(zone);
      return;
    }
    if (_gestureSource != widget.document.current) {
      _cancel();
      return;
    }
    final moving = _moving;
    final preview = _preview;
    if (moving != null && preview != null) _commands.move(moving.id, preview);
    final stroke = _stroke;
    if (stroke != null) {
      try {
        widget.document.commit(stroke.commit());
      } catch (_) {
        widget.document.error =
            'Ce trait ne peut pas être appliqué à cette carte.';
      }
    }
    setState(_cancel);
    widget.onChanged();
  }

  void _cancel() {
    _start = null;
    _preview = null;
    _moving = null;
    _stroke = null;
    _gestureSource = null;
    _characterGesture = null;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.document.current;
    return LayoutBuilder(
      builder: (context, constraints) {
        void recenter() => widget.view.fitViewport(
          constraints.biggest,
          Size(map.size.width * _width, map.size.height * _height),
        );
        widget.view.centerOn = (cell) => widget.view.centerCell(
          cell,
          constraints.biggest,
          Size(_width, _height),
        );

        widget.view.recenter = recenter;
        if (!widget.view.positioned) {
          widget.view.positioned = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) recenter();
          });
        }
        return ClipRect(
          child: InteractiveViewer(
            key: const ValueKey('map-viewport'),
            transformationController: widget.view.transform,
            constrained: false,
            alignment: Alignment.topLeft,
            boundaryMargin: const EdgeInsets.all(400),
            minScale: .15,
            maxScale: 8,
            panEnabled: widget.view.tool == StudioMapTool.pan,
            child: Focus(
              focusNode: _focus,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                key: const ValueKey('map-canvas'),
                onPointerDown: _down,
                onPointerMove: _move,
                onPointerUp: _up,
                onPointerCancel: (_) => setState(_cancel),
                child: SizedBox(
                  width: map.size.width * _width,
                  height: map.size.height * _height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: widget.visuals.canvas(
                          _characterGesture?.preview ??
                              (_stroke?.terrain == true
                                  ? _stroke!.preview
                                  : map),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: buildEditingOverlay(
                              context: context,
                              map: map,
                              project: widget.project,
                              document: widget.document,
                              view: widget.view,
                              gesture: _characterGesture,
                              stroke: _stroke,
                              preview: _preview,
                              cellWidth: _width,
                              cellHeight: _height,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
