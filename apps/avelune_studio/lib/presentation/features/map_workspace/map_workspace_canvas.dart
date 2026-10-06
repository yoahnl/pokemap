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
import 'map_decor_transform_draft.dart';
import 'map_decor_transform_overlay.dart';
import '../../../features/map_workspace/application/environment_editing_commands.dart';
import 'map_environment_overlay.dart';

part 'map_workspace_canvas_gestures.dart';
part 'map_workspace_canvas_border.dart';
part 'map_workspace_canvas_decor.dart';
part 'map_workspace_canvas_render.dart';

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
  MapEncounterCellStroke? _environmentStroke;
  MapEnvironmentSession? _environmentOwner;
  EnvironmentPaintTool? _environmentTool;
  ProjectManifest? _environmentProject;
  MapData? _gestureSource;
  MapCharacterGesture? _characterGesture;
  MapDecorTransformDraft? _decorDraft;
  int? _decorPointer;
  final Set<LogicalKeyboardKey> _nudgeKeys = {};
  bool _previewScheduled = false;
  StudioMapTool? _gestureTool;
  MapData? _ownershipMap;
  Set<String> _environmentOwnedIds = {};
  bool get _ownsEnvironmentGesture =>
      identical(_environmentOwner, widget.view.environment) &&
      _environmentTool == _environmentOwner?.tool &&
      identical(_environmentProject, widget.project) &&
      widget.view.tool == StudioMapTool.environment;
  double get _displayScale => widget.project.settings.displayScale.toDouble();
  Offset _pixelOffset(Offset local) => local / _displayScale;
  PixelPosition _pixel(Offset local) => PixelPosition(
    leftPx: (local.dx / _displayScale).floor(),
    topPx: (local.dy / _displayScale).floor(),
  );
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
    if (widget.view.borderDraft?.mapId != null &&
        widget.view.borderDraft!.mapId != widget.document.current.id) {
      widget.view.borderDraft = null;
    }
  }

  @override
  void didUpdateWidget(MapWorkspaceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document ||
        oldWidget.gestureGeneration != widget.gestureGeneration ||
        (_environmentOwner != null && !_ownsEnvironmentGesture) ||
        (_decorDraft != null &&
            (!identical(_decorDraft!.source, widget.document.current) ||
                !identical(_decorDraft!.project, widget.project) ||
                _gestureTool != widget.view.tool ||
                _decorDraft!.original.id != widget.document.selectedId))) {
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
    if (_environmentOwner != null && !_ownsEnvironmentGesture) {
      setState(_cancel);
      return;
    }
    final moving = _moving;
    final preview = _preview;
    if (moving != null && preview != null) _commands.move(moving.id, preview);
    if (_armed) widget.view.pendingMove = null;
    final encounterStroke = _encounterStroke;
    final environment = _environmentOwner;
    if (widget.view.tool == StudioMapTool.environment &&
        environment != null &&
        _start != null) {
      try {
        final commands = EnvironmentEditingCommands(
          widget.document,
          widget.project,
        );
        if (environment.tool == EnvironmentPaintTool.rectangle) {
          commands.paintRectangle(
            environment,
            _start!,
            _cell(event.localPosition),
          );
        } else if (_environmentStroke != null) {
          _environmentStroke!.paint(_cell(event.localPosition));
          commands.paint(
            environment,
            _environmentStroke!.cells,
            erase: environment.tool == EnvironmentPaintTool.erase,
          );
        }
      } on Object catch (failure) {
        widget.document.error = environmentEditingMessage(failure);
      }
    }
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
  Widget build(BuildContext context) => _buildCanvas(context);
}
