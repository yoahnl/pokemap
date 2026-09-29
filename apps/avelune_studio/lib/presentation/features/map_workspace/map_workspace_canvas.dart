import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_overlay_editing.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'map_canvas_stroke.dart';
import 'map_encounter_cell_stroke.dart';
import 'map_character_gesture.dart';

part 'map_workspace_canvas_gestures.dart';
part 'map_workspace_canvas_border.dart';

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
    this.onContextMenu,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final int gestureGeneration;
  final ValueChanged<MapRect>? onZoneDrawn;
  final void Function(GridPos cell, Offset globalPosition)? onContextMenu;
  @override
  State<MapWorkspaceCanvas> createState() => _MapWorkspaceCanvasState();
}

class _MapWorkspaceCanvasState extends State<MapWorkspaceCanvas> {
  void _refreshGesture() => setState(() {});
  void _mutateGesture(VoidCallback action) => setState(action);
  final _focus = FocusNode();
  final _surface = GlobalKey();
  GridPos? _start;
  GridPos? _preview;
  GridPos? _hoverCell;
  MapPlacedElement? _moving;
  bool _armed = false;
  MapCanvasStroke? _stroke;
  int? _panPointer;
  Offset? _panPosition;
  MapEncounterCellStroke? _encounterStroke;
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
  void initState() {
    super.initState();
    if (widget.view.borderDraft?.mapId != null &&
        widget.view.borderDraft!.mapId != widget.document.current.id) {
      widget.view.borderDraft = null;
    }
  }

  @override
  void didUpdateWidget(MapWorkspaceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document ||
        oldWidget.gestureGeneration != widget.gestureGeneration) {
      _cancel();
    }
    if (widget.view.borderDraft?.mapId != null &&
        widget.view.borderDraft!.mapId != widget.document.current.id) {
      widget.view.borderDraft = null;
    }
  }

  void _paint(GridPos cell) {
    _stroke?.paint(cell);
    setState(() {});
  }

  void _up(PointerUpEvent event) {
    if (_panPointer == event.pointer) {
      _panPointer = null;
      _panPosition = null;
      return;
    }
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
    if (_armed) widget.view.pendingMove = null;
    final encounterStroke = _encounterStroke;
    if (encounterStroke != null) {
      try {
        final zone =
            GameplayZoneEditingCommands(
              widget.document,
              widget.project,
            ).paintEncounterCells(
              encounterStroke.cells,
              erase: encounterStroke.erase,
              selectedZoneId: widget.view.selectedFor(
                widget.document.current.id,
                MapSelectionFamily.zone,
              ),
            );
        if (zone != null) {
          widget.view.select(widget.document, MapSelectionFamily.zone, zone.id);
        }
      } catch (error) {
        widget.document.error = error.toString();
      }
    }
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

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.document.current;
    final brush = widget.view.tool == StudioMapTool.place
        ? widget.view.brush
        : null;
    final hover = brush == null ? null : _hoverCell;
    final footprint = brush == null
        ? null
        : resolveMapPlacedElementFootprint(
            instance: MapPlacedElement(
              id: 'preview',
              layerId: '',
              elementId: brush.id,
              pos: hover ?? const GridPos(x: 0, y: 0),
            ),
            element: brush,
          ).destinationSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        widget.view.attachViewport(
          constraints.biggest,
          Size(map.size.width * _width, map.size.height * _height),
          Size(_width, _height),
          mounted: () => mounted,
          surface: _surface,
        );
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
              onKeyEvent: (node, event) {
                if (widget.view.tool == StudioMapTool.border &&
                    event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  _finishBorder();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: MouseRegion(
                onExit: (_) {
                  final draft = widget.view.borderDraft;
                  if (_hoverCell != null || draft?.hover != null) {
                    setState(() {
                      _hoverCell = null;
                      if (draft != null) {
                        widget.view.borderDraft = draft.pointAt(null);
                      }
                    });
                  }
                },
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  key: const ValueKey('map-canvas'),
                  onPointerDown: _down,
                  onPointerHover: _hover,
                  onPointerMove: _move,
                  onPointerSignal: _pointerSignal,
                  onPointerUp: _up,
                  onPointerCancel: (_) => setState(_cancel),
                  child: SizedBox(
                    key: _surface,
                    width: map.size.width * _width,
                    height: map.size.height * _height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: widget.visuals.canvas(
                            _characterGesture?.preview ??
                                _stroke?.preview ??
                                map,
                          ),
                        ),
                        if (hover != null && footprint != null)
                          Positioned(
                            left: hover.x * _width,
                            top: hover.y * _height,
                            child: IgnorePointer(
                              child: Opacity(
                                key: const ValueKey('decor-placement-preview'),
                                opacity: .72,
                                child: widget.visuals.placementPreview(
                                  brush!,
                                  Size(
                                    footprint.width * _width,
                                    footprint.height * _height,
                                  ),
                                ),
                              ),
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
                                encounterStroke: _encounterStroke,
                                borderDraft:
                                    widget.view.tool == StudioMapTool.border
                                    ? widget.view.borderDraft
                                    : null,
                                borderCursor:
                                    widget.view.tool == StudioMapTool.border
                                    ? _hoverCell
                                    : null,
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
          ),
        );
      },
    );
  }
}
