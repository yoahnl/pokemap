import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_context.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_overlay_projection.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';

import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_encounter_cell_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_character_gesture.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_decor_transform_draft.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_transform_gizmo.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_environment_mask.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_terrain_overlay.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_viewport_bounds.dart';

part 'map_editing_viewport_2d_gestures.dart';
part 'map_editing_viewport_2d_border.dart';
part 'map_editing_viewport_2d_decor.dart';
part 'map_editing_viewport_2d_pointer_down.dart';
part 'map_editing_viewport_2d_pointer_up.dart';
part 'map_editing_viewport_2d_render.dart';

class MapEditingViewport2D extends StatefulWidget {
  const MapEditingViewport2D({
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
  final MapEditingViewportSession view;
  final VoidCallback onChanged;
  final int gestureGeneration;
  final ValueChanged<MapRect>? onZoneDrawn;
  final void Function(GridPos cell, Offset globalPosition)? onContextMenu;
  @override
  State<MapEditingViewport2D> createState() => _MapEditingViewport2DState();
}

class _MapEditingViewport2DState extends State<MapEditingViewport2D>
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
  MapBorderEraseDraft? _borderErase;
  MapData? _borderErasePreview;
  Matrix4? _borderEraseTransform;
  bool get _ownsBorderEraseGesture =>
      _borderErase != null &&
      _borderErase!.validFor(widget.document.current, widget.project) &&
      widget.view.tool == StudioMapTool.border &&
      widget.view.borderEditingMode == BorderStrokeEditingMode.erase &&
      widget.view.borderFeature ==
          (
            layerId: _borderErase!.layerId,
            featureId: _borderErase!.featureId,
          ) &&
      _borderEraseTransform == widget.view.transform.value;
  int? _panPointer;
  Offset? _panPosition;
  PointerDownEvent? _secondaryPanStart;
  bool _secondaryPan = false;
  MapEncounterCellStroke? _encounterStroke;
  MapEncounterCellStroke? _environmentStroke;
  MapEnvironmentSession? _environmentOwner;
  EnvironmentPaintTool? _environmentTool;
  ProjectManifest? _environmentProject;
  MapData? _gestureSource;
  MapCharacterGesture? _characterGesture;
  MapDecorTransformDraft? _decorDraft;
  int? _decorPointer;
  ({
    int pointer,
    MapPlacedElement decor,
    Offset origin,
    PointerDeviceKind kind,
  })?
  _modifierPress;
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
    widget.view.focusBorderDraftOn(widget.document.current.id);
  }

  @override
  void didUpdateWidget(MapEditingViewport2D oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.view.reconcileLocks(widget.document);
    if (oldWidget.document != widget.document ||
        oldWidget.gestureGeneration != widget.gestureGeneration ||
        (_stroke != null &&
            (!identical(_stroke!.project, widget.project) ||
                !_stroke!.matches(widget.view))) ||
        (_characterGesture?.isLocked == true) ||
        (_moving != null &&
            widget.view.isUnavailable(
              widget.document,
              MapSelectionFamily.decor,
              _moving!.id,
            )) ||
        (_environmentOwner != null && !_ownsEnvironmentGesture) ||
        (_borderErase != null && !_ownsBorderEraseGesture) ||
        (_decorDraft != null &&
            (!_canTransform(_decorDraft!.original) ||
                !identical(_decorDraft!.source, widget.document.current) ||
                !identical(_decorDraft!.project, widget.project) ||
                _gestureTool != widget.view.tool ||
                _decorDraft!.original.id != widget.document.selectedId))) {
      _cancel();
    }
    widget.view.focusBorderDraftOn(widget.document.current.id);
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
