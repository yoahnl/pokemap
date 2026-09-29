import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_overlay_editing.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'map_canvas_stroke.dart';
import 'map_encounter_cell_stroke.dart';
import 'map_character_gesture.dart';
import 'map_decor_transform_draft.dart';
import 'map_decor_transform_overlay.dart';

part 'map_workspace_canvas_gestures.dart';

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

class _MapWorkspaceCanvasState extends State<MapWorkspaceCanvas>
    with WidgetsBindingObserver {
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
  MapDecorTransformDraft? _decorDraft;
  int? _decorPointer;
  final Set<LogicalKeyboardKey> _nudgeKeys = {};
  bool _previewScheduled = false;
  StudioMapTool? _gestureTool;
  MapData? _ownershipMap;
  Set<String> _environmentOwnedIds = {};
  double get _displayScale => widget.project.settings.displayScale.toDouble();
  Offset _pixelOffset(Offset local) => local / _displayScale;
  PixelPosition _pixel(Offset local) => PixelPosition(
    leftPx: (local.dx / _displayScale).floor(),
    topPx: (local.dy / _displayScale).floor(),
  );
  bool _canTransform(MapPlacedElement instance) {
    if (!identical(_ownershipMap, widget.document.current)) {
      _ownershipMap = widget.document.current;
      _environmentOwnedIds = environmentOwnedMapPlacedElementIds(
        widget.document.current,
      );
    }
    return isAuthoredMapPlacedElement(instance) &&
        !_environmentOwnedIds.contains(instance.id) &&
        widget.project.elements.any(
          (element) => element.id == instance.elementId,
        );
  }

  void _beginDecor(
    MapPlacedElement instance,
    Offset pointer, {
    DecorResizeHandle? handle,
  }) {
    _decorDraft = MapDecorTransformDraft(
      source: widget.document.current,
      project: widget.project,
      original: instance,
      pointer: _pixelOffset(pointer),
      precise: HardwareKeyboard.instance.isShiftPressed,
      handle: handle,
      lockRatio: widget.view.lockDecorProportions,
    );
    _gestureTool = widget.view.tool;
    _gestureSource = widget.document.current;
  }

  void _refreshDecor() {
    if (_previewScheduled) return;
    _previewScheduled = true;
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      _previewScheduled = false;
      if (mounted) setState(() {});
    });
  }

  void _commitDecor() {
    final draft = _decorDraft;
    if (draft != null &&
        identical(draft.source, widget.document.current) &&
        identical(draft.project, widget.project) &&
        draft.original.id == widget.document.selectedId) {
      if (draft.error != null) {
        widget.document.error = draft.error;
      } else if (draft.candidate != draft.original) {
        final rect = draft.geometry.logicalRect;
        _commands.setGeometry(
          draft.original.id,
          x: rect.leftPx,
          y: rect.topPx,
          size: draft.candidate.pixelSize,
        );
      }
    }
    if (_armed) widget.view.pendingMove = null;
    setState(_cancel);
    widget.onChanged();
  }

  KeyEventResult _decorKey(KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && _decorDraft != null) {
      setState(_cancel);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      _decorDraft?.rebasePrecision(HardwareKeyboard.instance.isShiftPressed);
    }
    if (event is KeyUpEvent && _nudgeKeys.remove(key)) {
      if (_nudgeKeys.isEmpty) _commitDecor();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        !HardwareKeyboard.instance.isShiftPressed ||
        widget.view.tool != StudioMapTool.select ||
        _decorPointer != null) {
      return KeyEventResult.ignored;
    }
    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => const Offset(-1, 0),
      LogicalKeyboardKey.arrowRight => const Offset(1, 0),
      LogicalKeyboardKey.arrowUp => const Offset(0, -1),
      LogicalKeyboardKey.arrowDown => const Offset(0, 1),
      _ => null,
    };
    final selected = widget.document.selected;
    if (delta == null || selected == null || !_canTransform(selected)) {
      return KeyEventResult.ignored;
    }
    if (_decorDraft == null) _beginDecor(selected, Offset.zero);
    _nudgeKeys.add(key);
    _decorDraft!.nudge(delta.dx.toInt(), delta.dy.toInt());
    _refreshDecor();
    return KeyEventResult.handled;
  }

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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(MapWorkspaceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document ||
        oldWidget.gestureGeneration != widget.gestureGeneration ||
        (_decorDraft != null &&
            (!identical(_decorDraft!.source, widget.document.current) ||
                !identical(_decorDraft!.project, widget.project) ||
                _gestureTool != widget.view.tool ||
                _decorDraft!.original.id != widget.document.selectedId))) {
      _cancel();
    }
  }

  void _paint(GridPos cell) {
    _stroke?.paint(cell);
    setState(() {});
  }

  void _up(PointerUpEvent event) {
    if (_decorPointer == event.pointer && _decorDraft != null) {
      _decorDraft!.move(
        _pixelOffset(event.localPosition),
        precise: HardwareKeyboard.instance.isShiftPressed,
      );
      _commitDecor();
      return;
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _gestureSource != null) {
      setState(_cancel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.document.current;
    final selected =
        _decorDraft?.candidate ??
        (_preview == null
            ? widget.document.selected
            : widget.document.selected?.copyWith(pos: _preview!));
    final selectedElement = widget.project.elements
        .where((e) => e.id == selected?.elementId)
        .firstOrNull;
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
              onFocusChange: (focused) {
                if (!focused && _gestureSource != null) setState(_cancel);
              },
              onKeyEvent: (node, event) {
                return _decorKey(event);
              },
              child: MouseRegion(
                onExit: (_) {
                  if (_hoverCell != null) setState(() => _hoverCell = null);
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
                            placedElementPreview: _decorDraft?.candidate,
                            collisionColor:
                                widget.view.tool == StudioMapTool.select &&
                                    widget.view.showDecorCollision
                                ? Theme.of(context).colorScheme.error
                                : null,
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
                                preview: _preview,
                                cellWidth: _width,
                                cellHeight: _height,
                              ),
                            ),
                          ),
                        ),
                        if (selected != null &&
                            selectedElement != null &&
                            widget.view.tool == StudioMapTool.select)
                          Positioned.fill(
                            child: MapDecorTransformOverlay(
                              instance: selected,
                              element: selectedElement,
                              project: widget.project,
                              transform: widget.view.transform,
                              resizable: _canTransform(selected),
                              invalid: _decorDraft?.error != null,
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
