import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'
    show
        DragStartBehavior,
        kSecondaryButton,
        PointerPanZoomEndEvent,
        PointerPanZoomStartEvent,
        PointerPanZoomUpdateEvent,
        PointerScrollEvent,
        PointerSignalEvent;
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart'
    show
        HardwareKeyboard,
        KeyDownEvent,
        KeyEvent,
        KeyUpEvent,
        LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../app/providers/editor/editor_asset_cache_providers.dart';
import '../../application/models/map_tool_preview.dart';
import '../../application/models/narrative_event_map_bridge_models.dart';
import '../../application/models/narrative_event_spatial_source_creation_models.dart';
import '../../application/shadow/editor_shadow_light_preview.dart';
import '../../application/shadow/editor_shadow_preview_projection_index.dart';
import '../../application/shadow/editor_static_shadow_preview.dart';
import '../../application/services/environment_generated_placement_hover_resolver.dart';
import '../../application/services/environment_mask_brush_footprint_resolver.dart';
import '../../application/services/environment_mask_paint_target_resolver.dart';
import '../../application/services/map_focus_viewport_resolver.dart';
import '../../application/services/map_viewport_navigation.dart';
import '../../application/services/tileset_transparent_color_processor.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/application/world_map_connection_context.dart';
import '../../features/editor/state/environment_generated_placement_add_element_provider.dart';
import '../../features/editor/state/environment_mask_brush_size_provider.dart';
import '../../features/editor/application/map_canvas_interaction_controller.dart';
import '../../features/editor/application/map_canvas_object_hit_test.dart';
import '../../features/editor/application/map_canvas_object_move_planner.dart';
import '../../features/editor/application/map_placed_element_rotation_planner.dart';
import '../../features/editor/application/project_element_frame_resolver.dart';
import '../../features/editor/presentation/world_map/map_placed_element_rotation_preview_controller.dart';
import '../../features/editor/presentation/world_map/world_map_connection_context_provider.dart';
import '../../features/editor/presentation/world_map/world_map_layer_hover_preview.dart';
import '../../features/editor/presentation/world_map/world_map_smart_tile_gesture_mode.dart';
import '../../features/editor/presentation/map_activation_guard.dart';
import '../../features/editor/application/world_map_inspector_projector.dart';
import '../../features/editor/application/world_map_tool_family.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../features/border_map_editing/application/border_feature_hit_test.dart';
import '../../features/border_map_editing/application/border_grid_edge_snapping.dart';
import '../../features/border_map_editing/application/border_region_editing.dart';
import '../../features/border_map_editing/application/border_tool_availability.dart';
import '../../features/border_map_editing/application/border_preview_transaction.dart';
import '../../features/border_map_editing/presentation/border_diagnostic_presentation.dart';
import '../../features/border_map_editing/presentation/editor_map_layer_paint_order.dart';
import '../../features/border_map_editing/presentation/border_preview_painter.dart';
import '../../features/border_map_editing/state/border_map_editing_providers.dart';
import '../../features/border_map_editing/state/border_preview_providers.dart';
import 'entity_editor_element_visual.dart';
import '../assets/editor_image_cache.dart';
import 'map_canvas/map_canvas_navigation_controls.dart';
import 'map_canvas/editor_canvas_animation_need_resolver.dart';
import 'map_canvas/editor_canvas_repaint_clock.dart';
import 'map_canvas/narrative_event_map_banner.dart';
import 'map_canvas/smart_tile_visual_painter.dart';
import 'narrative_studio/narrative_studio_navigation.dart';
import 'shadow/editor_static_shadow_preview_painter.dart';
import '../design_system/pokemap_badge.dart';
import '../design_system/pokemap_button.dart';
import '../design_system/pokemap_diagnostic_callout.dart';
import '../shared/map_workspace_empty_state.dart';
import '../../theme/theme.dart';

// Le shell du canvas garde uniquement le widget, l'interaction et la
// synchronisation des ressources. Le painter et le cache d'images vivent dans
// des part files dédiés pour rendre cette surface re-reviewable.
part 'map_canvas/map_grid_painter.dart';
part 'map_canvas/map_connection_context_layer.dart';
part 'map_canvas/map_canvas_tileset_path_collector.dart';
part 'map_canvas/tile_layer_hover_highlight_painter.dart';

const bool _showMapGrid = bool.fromEnvironment(
  'POKEMAP_MARIONETTE_SHOW_MAP_GRID',
  defaultValue: true,
);

bool _isEnvironmentMaskEditing(EditorState state, MapData map) {
  final mode = state.environmentMaskEditMode;
  if (mode != EnvironmentMaskEditMode.paint &&
      mode != EnvironmentMaskEditMode.erase) {
    return false;
  }
  return resolveEnvironmentMaskPaintTarget(
        map: map,
        activeLayerId: state.activeLayerId,
        selectedAreaId: state.selectedEnvironmentAreaId,
      ) !=
      null;
}

SmartTileGestureSelection _smartTileGestureSelection(
  WorldMapSmartTileGestureMode mode, {
  required GridPos start,
  required GridPos end,
}) => switch (mode) {
  WorldMapSmartTileGestureMode.line => SmartTileGestureSelection.line(
    start: start,
    end: end,
  ),
  WorldMapSmartTileGestureMode.rectangle => SmartTileGestureSelection.rectangle(
    start: start,
    end: end,
  ),
  WorldMapSmartTileGestureMode.floodFill => SmartTileGestureSelection.floodFill(
    seed: start,
  ),
  WorldMapSmartTileGestureMode.brush => throw StateError(
    'Brush gestures are sampled as normal strokes.',
  ),
};

SmartTilePatternSelection _smartTilePatternSelection(
  WorldMapSmartTileGestureMode mode, {
  required GridPos start,
  required GridPos end,
}) => switch (mode) {
  WorldMapSmartTileGestureMode.brush => SmartTilePatternSelection.stamp(
    anchor: start,
  ),
  WorldMapSmartTileGestureMode.line => SmartTilePatternSelection.line(
    start: start,
    end: end,
  ),
  WorldMapSmartTileGestureMode.rectangle => SmartTilePatternSelection.rectangle(
    start: start,
    end: end,
  ),
  WorldMapSmartTileGestureMode.floodFill => throw StateError(
    'Reusable patterns do not support flood fill.',
  ),
};

SmartTileGestureSelection _smartTilePatternEraseSelection(
  WorldMapSmartTileGestureMode mode, {
  required GridPos start,
  required GridPos end,
}) => mode == WorldMapSmartTileGestureMode.brush
    ? SmartTileGestureSelection.line(start: start, end: end)
    : _smartTileGestureSelection(mode, start: start, end: end);

bool _smartTilePatternSupportsGesture(
  ProjectSmartTilePattern pattern,
  WorldMapSmartTileGestureMode mode,
) {
  if (pattern.repeatMode == SmartTilePatternRepeatMode.stamp) {
    return mode == WorldMapSmartTileGestureMode.brush;
  }
  return mode != WorldMapSmartTileGestureMode.floodFill;
}

({GridPos origin, GridSize size}) _smartTileGestureBounds(List<GridPos> cells) {
  var left = cells.first.x;
  var right = cells.first.x;
  var top = cells.first.y;
  var bottom = cells.first.y;
  for (final cell in cells.skip(1)) {
    left = math.min(left, cell.x);
    right = math.max(right, cell.x);
    top = math.min(top, cell.y);
    bottom = math.max(bottom, cell.y);
  }
  return (
    origin: GridPos(x: left, y: top),
    size: GridSize(width: right - left + 1, height: bottom - top + 1),
  );
}

String _mapCanvasImageFailureMessage(
  Map<String, EditorImageFailure> failures,
  ProjectManifest? project,
) {
  String tilesetLabel(String id) {
    for (final tileset in project?.tilesets ?? const <ProjectTilesetEntry>[]) {
      if (tileset.id == id) return tileset.name;
    }
    return id;
  }

  String reason(EditorImageFailureKind kind) => switch (kind) {
    EditorImageFailureKind.invalidPath => 'aucun fichier associé',
    EditorImageFailureKind.missingFile => 'fichier introuvable',
    EditorImageFailureKind.emptyFile => 'fichier vide',
    EditorImageFailureKind.readFailed => 'lecture impossible',
    EditorImageFailureKind.decodeFailed => 'image illisible',
    EditorImageFailureKind.cacheDisposed => 'session projet fermée',
  };

  final visible = failures.entries
      .take(3)
      .map(
        (entry) => '${tilesetLabel(entry.key)} : ${reason(entry.value.kind)}',
      );
  final remaining = failures.length - 3;
  return [
    ...visible,
    if (remaining > 0) '$remaining autre${remaining > 1 ? 's' : ''}',
  ].join(' · ');
}

@visibleForTesting
String mapCanvasSelectionSemanticsLabel({
  required EditorState state,
  required MapData map,
  ProjectManifest? project,
  String? selectedBorderFeatureId,
  int editorAnimationTimeMs = 0,
}) {
  String boundsLabel(GridPos pos, GridSize size) {
    return 'x ${pos.x}, y ${pos.y}, ${size.width} par ${size.height}';
  }

  final placedId = state.selectedPlacedElementInstanceId;
  if (placedId != null) {
    for (final placed in map.placedElements) {
      if (placed.id == placedId) {
        var size = const GridSize(width: 1, height: 1);
        if (project != null) {
          for (final element in project.elements) {
            if (element.id == placed.elementId && element.frames.isNotEmpty) {
              final source = pickProjectElementFrame(
                element.frames,
                editorAnimationTimeMs,
              ).source;
              size = QuarterTurnGridTransform(
                sourceSize: GridSize(
                  width: source.width <= 0 ? 1 : source.width,
                  height: source.height <= 0 ? 1 : source.height,
                ),
                quarterTurns: placed.quarterTurns,
              ).destinationSize;
              break;
            }
          }
        }
        return 'Élément ${placed.elementId} sélectionné, '
            '${boundsLabel(placed.pos, size)}.';
      }
    }
  }
  final entityId = state.selectedEntityId;
  if (entityId != null) {
    for (final entity in map.entities) {
      if (entity.id == entityId) {
        final name = entity.name.trim().isEmpty
            ? entity.id
            : entity.name.trim();
        return 'Entité $name sélectionnée, '
            '${boundsLabel(entity.pos, entity.size)}.';
      }
    }
  }
  final eventId = state.selectedMapEventId;
  if (eventId != null) {
    for (final event in map.events) {
      if (event.id == eventId) {
        final title = event.title.trim().isEmpty
            ? event.id
            : event.title.trim();
        return 'Événement $title sélectionné, '
            'x ${event.position.x}, y ${event.position.y}.';
      }
    }
  }
  final zoneId = state.selectedGameplayZoneId;
  if (zoneId != null) {
    for (final zone in map.gameplayZones) {
      if (zone.id == zoneId) {
        final name = zone.name.trim().isEmpty ? zone.id : zone.name.trim();
        return 'Zone $name sélectionnée, '
            '${boundsLabel(zone.area.pos, zone.area.size)}.';
      }
    }
  }
  final triggerId = state.selectedTriggerId;
  if (triggerId != null) {
    for (final trigger in map.triggers) {
      if (trigger.id == triggerId) {
        final name = trigger.name.trim().isEmpty
            ? trigger.id
            : trigger.name.trim();
        return 'Déclencheur $name sélectionné, '
            '${boundsLabel(trigger.area.pos, trigger.area.size)}.';
      }
    }
  }
  final warpId = state.selectedWarpId;
  if (warpId != null) {
    for (final warp in map.warps) {
      if (warp.id == warpId) {
        return 'Téléporteur ${warp.id} sélectionné, '
            'x ${warp.pos.x}, y ${warp.pos.y}.';
      }
    }
  }
  final borderId = selectedBorderFeatureId?.trim();
  if (borderId != null && borderId.isNotEmpty) {
    return 'Bordure $borderId sélectionnée.';
  }
  return 'Carte ${map.name}. Aucun objet sélectionné.';
}

@visibleForTesting
bool isNarrativeEventBridgeEntityHighlighted({
  required String entityId,
  required NarrativeEditorFocusTarget? focus,
}) {
  return focus?.kind == NarrativeEditorFocusTargetKind.entity &&
      focus?.ownerId == entityId;
}

@visibleForTesting
bool isNarrativeEventBridgeTriggerHighlighted({
  required String triggerId,
  required NarrativeEditorFocusTarget? focus,
}) {
  return focus?.kind == NarrativeEditorFocusTargetKind.trigger &&
      focus?.ownerId == triggerId;
}

@visibleForTesting
bool isNarrativeEventBridgeMapHighlighted({
  required NarrativeEditorFocusTarget? focus,
}) {
  return focus?.kind == NarrativeEditorFocusTargetKind.map;
}

@visibleForTesting
NarrativeEventSourceRef? resolveNarrativeEventMapCandidateAt({
  required MapData map,
  required GridPos pos,
}) {
  final matches = <NarrativeEventSourceRef>[];
  for (final entity in map.entities) {
    if (entity.kind == MapEntityKind.spawn) continue;
    if (_mapRectContains(MapRect(pos: entity.pos, size: entity.size), pos)) {
      matches.add(NarrativeEventSourceRef.entityInteract(map.id, entity.id));
    }
  }
  for (final trigger in map.triggers) {
    if (trigger.type != TriggerType.event &&
        trigger.type != TriggerType.custom) {
      continue;
    }
    if (_mapRectContains(trigger.area, pos)) {
      matches.add(NarrativeEventSourceRef.triggerEnter(map.id, trigger.id));
    }
  }
  return matches.length == 1 ? matches.single : null;
}

bool _mapRectContains(MapRect rect, GridPos pos) {
  return pos.x >= rect.pos.x &&
      pos.y >= rect.pos.y &&
      pos.x < rect.pos.x + rect.size.width &&
      pos.y < rect.pos.y + rect.size.height;
}

BorderPreviewContext? _borderPreviewContextForCanvas(
  EditorState state,
  MapData map,
) {
  final projectRootPath = state.projectRootPath;
  final activeMapPath = state.activeMapPath;
  final project = state.project;
  if (projectRootPath == null ||
      projectRootPath.trim().isEmpty ||
      activeMapPath == null ||
      activeMapPath.trim().isEmpty ||
      project == null) {
    return null;
  }
  return createEditorBorderPreviewContext(
    projectRootPath: p.normalize(projectRootPath),
    activeMapPath: p.normalize(activeMapPath),
    project: project,
    map: map,
  );
}

class MapCanvas extends ConsumerStatefulWidget {
  const MapCanvas({
    super.key,
    this.onEventBuilderPositionChosen,
    this.placedElementRotationPreview,
    this.onContextMenuRequested,
    this.onCellSelected,
    this.keyboardContextCell,
    @visibleForTesting EditorCanvasRepaintClock? repaintClock,
    @visibleForTesting this.debugOnPaint,
    @visibleForTesting this.debugOnBuild,
    @visibleForTesting this.debugOnRepaintLifecycle,
  }) : repaintClockOverride = repaintClock;

  /// Scoped Event Builder bridge: when supplied, a primary map tap selects a
  /// position for the Event Builder instead of applying the global map tool.
  final ValueChanged<GridPos>? onEventBuilderPositionChosen;
  final MapPlacedElementRotationPreviewState? placedElementRotationPreview;
  final MapCanvasContextMenuRequested? onContextMenuRequested;
  final ValueChanged<GridPos?>? onCellSelected;
  final GridPos? keyboardContextCell;
  @visibleForTesting
  final EditorCanvasRepaintClock? repaintClockOverride;
  @visibleForTesting
  final MapGridPaintObserver? debugOnPaint;
  @visibleForTesting
  final VoidCallback? debugOnBuild;
  @visibleForTesting
  final ValueChanged<EditorCanvasRepaintLifecycleEvent>?
  debugOnRepaintLifecycle;

  @override
  ConsumerState<MapCanvas> createState() => _MapCanvasState();
}

enum MapContextMenuInvocation { pointer, keyboard }

@visibleForTesting
enum EditorCanvasRepaintLifecycleEvent {
  ownedClockCreated,
  ownedTickerCreated,
  ownedTickerStarted,
  ownedTickerStopped,
  ownedClockReset,
  ownedTickerDisposed,
  ownedClockDisposed,
}

@immutable
final class MapCanvasContextMenuRequest {
  const MapCanvasContextMenuRequest({
    required this.globalPosition,
    required this.gridPosition,
    required this.invocation,
  });

  final Offset globalPosition;
  final GridPos gridPosition;
  final MapContextMenuInvocation invocation;
}

typedef MapCanvasContextMenuRequested =
    ValueChanged<MapCanvasContextMenuRequest>;

typedef _TilesetImageBatch = ({
  int generation,
  Map<String, EditorImageLoadResult> results,
});

final class _MapCanvasObjectMovePreview {
  const _MapCanvasObjectMovePreview({
    required this.sourceMap,
    required this.target,
    required this.grabCell,
    required this.destinationAnchor,
    required this.plan,
    required this.contextAfterSelection,
  });

  final MapData sourceMap;
  final MapCanvasObjectTarget target;
  final GridPos grabCell;
  final GridPos destinationAnchor;
  final MapCanvasObjectMovePlan plan;
  final MapCanvasInteractionContext contextAfterSelection;

  MapCanvasObjectTarget get visualTarget =>
      plan.previewTarget ??
      MapCanvasObjectTarget(
        kind: target.kind,
        id: target.id,
        layerId: target.layerId,
        anchor: destinationAnchor,
        size: target.size,
      );

  bool get isRejected => plan.rejection != null;
}

String _mapCanvasObjectMovePreviewSemanticsLabel(
  _MapCanvasObjectMovePreview preview,
) {
  final objectLabel = switch (preview.target.kind) {
    MapCanvasObjectKind.placedElement => 'l’élément',
    MapCanvasObjectKind.entity => 'l’entité',
    MapCanvasObjectKind.mapEvent => 'l’événement',
    MapCanvasObjectKind.gameplayZone => 'la zone',
    MapCanvasObjectKind.trigger => 'le déclencheur',
    MapCanvasObjectKind.warp => 'le téléporteur',
  };
  final destination =
      'x ${preview.destinationAnchor.x}, '
      'y ${preview.destinationAnchor.y}';
  final rejectionReason = switch (preview.plan.rejection) {
    MapCanvasObjectMoveRejection.targetNotFound => 'l’objet est introuvable',
    MapCanvasObjectMoveRejection.boundsUnavailable =>
      'son empreinte est inconnue',
    MapCanvasObjectMoveRejection.sourceOutOfBounds =>
      'sa position actuelle dépasse la carte',
    MapCanvasObjectMoveRejection.destinationOutOfBounds =>
      'la destination dépasse la carte',
    MapCanvasObjectMoveRejection.environmentGeneratedPlacement =>
      'cet élément est généré par une zone Environment',
    MapCanvasObjectMoveRejection.tileIndexedSourceInvalid =>
      'les tuiles source ne correspondent plus à cet élément',
    MapCanvasObjectMoveRejection.tileIndexedDestinationOccupied =>
      'des tuiles occupent déjà la destination',
    MapCanvasObjectMoveRejection.tileIndexedProjectionInvalid =>
      'la projection de tuiles obtenue est invalide',
    null => null,
  };
  if (rejectionReason != null) {
    return 'Déplacement de $objectLabel ${preview.target.id} impossible vers '
        '$destination : $rejectionReason.';
  }
  return 'Aperçu du déplacement de $objectLabel ${preview.target.id} vers '
      '$destination.';
}

class _MapCanvasState extends ConsumerState<MapCanvas>
    with SingleTickerProviderStateMixin {
  final GlobalKey _mapViewportKey = GlobalKey();
  final FocusNode _mapFocusNode = FocusNode(debugLabel: 'Map canvas');
  final FocusNode _mapNavigationControlsFocusNode = FocusNode(
    debugLabel: 'Map navigation controls',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final MapCanvasInteractionController _interactionController =
      MapCanvasInteractionController();
  final EditorShadowPreviewProjectionOwner _shadowPreviewProjectionOwner =
      EditorShadowPreviewProjectionOwner();
  final Set<int> _pressedMapPointers = <int>{};
  final Set<LogicalKeyboardKey> _pressedContextMenuKeys =
      <LogicalKeyboardKey>{};
  final Map<int, Offset> _latestMapPointerLocalPositions = <int, Offset>{};
  int? _activeGestureInteractionId;
  int? _scheduledRollbackInteractionId;
  String? _scheduledNarrativeEventCameraRequestId;
  Map<String, String> _lastTilesetPathsById = const {};
  Map<String, TilesetTransparentColor> _lastTilesetTransparentColorById =
      const {};
  EditorImageCache? _lastTilesetImageCache;
  Future<_TilesetImageBatch>? _tilesetImagesFuture;
  int _tilesetImageRequestGeneration = 0;
  GridPos? _hoveredTile;
  GridPos? _hoveredBorderVertex;
  _MapCanvasObjectMovePreview? _objectMovePreview;
  ({int interactionId, int pointerId, MapViewport viewport, Offset focalPoint})?
  _trackpadGesture;

  bool _spacePressed = false;
  bool _spaceKeyboardActivationPending = false;
  String? _keyboardCursorMapId;
  GridPos? _keyboardCursor;
  ValueChanged<GridPos>? _keyboardCellActivation;

  /// Cellule de départ pour le tracé d'une zone par clic+glisser.
  GridPos? _zoneDragStart;

  /// Lot Environment-22 : évite de repeindre la même cellule masque pendant un drag.
  GridPos? _lastEnvironmentMaskPaintCell;

  /// Transient origin/current cell for one previewed Smart Tile shape.
  GridPos? _smartTileShapeStart;
  GridPos? _smartTileShapeEnd;

  /// Dedicated Border drag de-duplication; never enters map/collision strokes.
  GridPos? _lastBorderPaintCell;

  /// Pointer-down snapshot for one transient linear Border gesture.
  BorderStrokeEditingDraft? _borderStrokeEditingDraft;

  /// Keeps every suffix of an invalid linear Border drag rejected until the
  /// owning pointer ends; this transient guard never enters map/collision IO.
  bool _borderStrokeGestureRejected = false;

  Ticker? _entityEditorAnimTicker;
  EditorCanvasRepaintClock? _ownedRepaintClock;
  bool _entityEditorAnimationRunning = false;
  String _shadowLightPreviewPresetId = 'neutral';

  EditorCanvasRepaintClock get _repaintClock =>
      widget.repaintClockOverride ?? _ownedRepaintClock!;

  @override
  void initState() {
    super.initState();
    _createOwnedRepaintResourcesIfNeeded();
  }

  @override
  void didUpdateWidget(covariant MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyboardContextCell != widget.keyboardContextCell) {
      final nextCell = widget.keyboardContextCell;
      _keyboardCursor = nextCell;
      _keyboardCursorMapId = nextCell == null
          ? null
          : ref.read(editorNotifierProvider).activeMap?.id;
    }
    if (identical(
      oldWidget.repaintClockOverride,
      widget.repaintClockOverride,
    )) {
      return;
    }
    _disposeOwnedRepaintResources();
    _entityEditorAnimationRunning = false;
    _createOwnedRepaintResourcesIfNeeded();
  }

  void _createOwnedRepaintResourcesIfNeeded() {
    if (widget.repaintClockOverride != null) return;
    final clock = EditorCanvasRepaintClock();
    _ownedRepaintClock = clock;
    _reportRepaintLifecycle(
      EditorCanvasRepaintLifecycleEvent.ownedClockCreated,
    );
    _entityEditorAnimTicker = createTicker(clock.update);
    _reportRepaintLifecycle(
      EditorCanvasRepaintLifecycleEvent.ownedTickerCreated,
    );
  }

  void _disposeOwnedRepaintResources() {
    final ticker = _entityEditorAnimTicker;
    if (ticker != null) {
      ticker.dispose();
      _reportRepaintLifecycle(
        EditorCanvasRepaintLifecycleEvent.ownedTickerDisposed,
      );
    }
    _entityEditorAnimTicker = null;
    final clock = _ownedRepaintClock;
    if (clock != null) {
      clock.dispose();
      _reportRepaintLifecycle(
        EditorCanvasRepaintLifecycleEvent.ownedClockDisposed,
      );
    }
    _ownedRepaintClock = null;
  }

  void _reportRepaintLifecycle(EditorCanvasRepaintLifecycleEvent event) {
    assert(() {
      widget.debugOnRepaintLifecycle?.call(event);
      return true;
    }());
  }

  void _syncEditorEntityAnimationTicker(bool needsAnimation) {
    if (widget.repaintClockOverride != null ||
        needsAnimation == _entityEditorAnimationRunning) {
      return;
    }
    _entityEditorAnimationRunning = needsAnimation;
    final ticker = _entityEditorAnimTicker!;
    if (needsAnimation) {
      if (!ticker.isActive) {
        ticker.start();
        _reportRepaintLifecycle(
          EditorCanvasRepaintLifecycleEvent.ownedTickerStarted,
        );
      }
    } else {
      if (ticker.isActive) {
        ticker.stop();
        _reportRepaintLifecycle(
          EditorCanvasRepaintLifecycleEvent.ownedTickerStopped,
        );
      }
      _ownedRepaintClock!.reset();
      _reportRepaintLifecycle(
        EditorCanvasRepaintLifecycleEvent.ownedClockReset,
      );
    }
  }

  @override
  void deactivate() {
    final cancelled = _interactionController.cancelActive();
    _clearTrackpadGesture();
    if (cancelled != null) {
      _scheduleDetachedInteractionRollback(cancelled.session);
    } else if (ref.read(editorNotifierProvider).mapStrokeStart != null) {
      final notifier = ref.read(editorNotifierProvider.notifier);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.cancelMapStroke();
      });
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _disposeOwnedRepaintResources();
    _shadowPreviewProjectionOwner.clear();
    _releaseTilesetImagesFuture(_tilesetImagesFuture);
    _tilesetImagesFuture = null;
    _pressedMapPointers.clear();
    _pressedContextMenuKeys.clear();
    _latestMapPointerLocalPositions.clear();
    _clearTrackpadGesture();
    _mapFocusNode.dispose();
    _mapNavigationControlsFocusNode.dispose();
    super.dispose();
  }

  void _releaseTilesetImagesFuture(Future<_TilesetImageBatch>? future) {
    if (future == null) return;
    unawaited(
      future.then<void>((batch) {
        final binding = WidgetsBinding.instance;
        binding.addPostFrameCallback((_) {
          for (final result in batch.results.values) {
            result.dispose();
          }
        });
        binding.ensureVisualUpdate();
      }, onError: (Object _, StackTrace __) {}),
    );
  }

  void _updateTilesetImagesFuture(
    EditorImageCache? imageCache,
    Map<String, String> nextTilesetPathsById,
    Map<String, TilesetTransparentColor> nextTransparentColorByTilesetId,
  ) {
    if (_tilesetImagesFuture != null &&
        identical(_lastTilesetImageCache, imageCache) &&
        mapEquals(_lastTilesetPathsById, nextTilesetPathsById) &&
        mapEquals(
          _lastTilesetTransparentColorById,
          nextTransparentColorByTilesetId,
        )) {
      return;
    }
    final previousFuture = _tilesetImagesFuture;
    _lastTilesetImageCache = imageCache;
    _tilesetImageRequestGeneration += 1;
    final requestGeneration = _tilesetImageRequestGeneration;
    _lastTilesetPathsById = Map<String, String>.from(nextTilesetPathsById);
    _lastTilesetTransparentColorById =
        Map<String, TilesetTransparentColor>.from(
          nextTransparentColorByTilesetId,
        );
    final resultsFuture = imageCache?.loadMany(
      _lastTilesetPathsById,
      variantKeyForId: (tilesetId) =>
          'transparent:${_lastTilesetTransparentColorById[tilesetId]?.toHexRgb() ?? 'none'}',
      transformForId: (tilesetId) {
        final transparentColor = _lastTilesetTransparentColorById[tilesetId];
        if (transparentColor == null) return null;
        return (bytes) {
          try {
            return applyTilesetTransparentColorToPngBytes(
              imageBytes: bytes,
              transparentColor: transparentColor,
            );
          } on Object {
            return bytes;
          }
        };
      },
    );
    _tilesetImagesFuture =
        (resultsFuture ??
                Future<Map<String, EditorImageLoadResult>>.value(
                  const <String, EditorImageLoadResult>{},
                ))
            .then(
              (results) => (generation: requestGeneration, results: results),
            );
    _releaseTilesetImagesFuture(previousFuture);
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      widget.debugOnBuild?.call();
      return true;
    }());
    final colors = context.pokeMapColors;
    final document = ref.watch(editorMapDocumentSnapshotProvider);
    final viewport = ref.watch(editorMapViewportSnapshotProvider);
    final interaction = ref.watch(editorMapInteractionSnapshotProvider);
    final state = EditorState(
      projectRootPath: document.projectRootPath,
      project: document.project,
      activeMap: document.activeMap,
      activeMapPath: document.activeMapPath,
      activeTool: interaction.activeTool,
      activeLayerId: interaction.activeLayerId,
      activeBrush: interaction.activeBrush,
      selectedEntityKind: interaction.selectedEntityKind,
      eraserFootprint: interaction.eraserFootprint,
      collisionBrushSizeMode: interaction.collisionBrushSizeMode,
      selectedEntityId: interaction.selectedEntityId,
      npcWaypointPlacementEntityId: interaction.npcWaypointPlacementEntityId,
      selectedMapEventId: interaction.selectedMapEventId,
      selectedWarpId: interaction.selectedWarpId,
      selectedTriggerId: interaction.selectedTriggerId,
      selectedGameplayZoneId: interaction.selectedGameplayZoneId,
      selectedEnvironmentAreaId: interaction.selectedEnvironmentAreaId,
      environmentMaskEditMode: interaction.environmentMaskEditMode,
      gameplayZoneDraftArea: interaction.gameplayZoneDraftArea,
      selectedPlacedElementInstanceId:
          interaction.selectedPlacedElementInstanceId,
      zoom: viewport.zoom,
      panOffset: viewport.panOffset,
    );
    final imageCache = switch (state.projectRootPath?.trim()) {
      final root? when root.isNotEmpty => ref.watch(
        editorImageCacheProvider(root),
      ),
      _ => null,
    };
    final bridgeState = ref.watch(narrativeEventMapBridgeControllerProvider);
    final narrativeNavigation = ref.watch(
      narrativeStudioNavigationControllerProvider,
    );
    final notifier = ref.read(editorNotifierProvider.notifier);
    final environmentMaskBrushSize = ref.watch(
      environmentMaskBrushSizeProvider,
    );
    final selectedGeneratedPlacementElementId = ref.watch(
      environmentGeneratedPlacementAddElementProvider,
    );
    final activeBorderFeature = ref.watch(
      activeBorderFeatureControllerProvider,
    );
    final borderPreviewState = ref.watch(borderPreviewControllerProvider);
    final borderPreviewController = ref.read(
      borderPreviewControllerProvider.notifier,
    );
    final hoveredTileLayerId = ref.watch(worldMapHoveredTileLayerIdProvider);
    final activeMap = state.activeMap;
    final settings = state.project?.settings ?? const ProjectSettings();
    final inspectorKind = ref.watch(
      worldMapInspectorSnapshotProvider.select((snapshot) => snapshot.kind),
    );
    final connectionModeActive =
        inspectorKind == WorldMapInspectorKind.connections;
    WorldMapConnectionContextRequest? connectionContextRequest;
    final projectRootPath = state.projectRootPath?.trim();
    if (connectionModeActive &&
        projectRootPath != null &&
        projectRootPath.isNotEmpty &&
        state.project != null &&
        activeMap != null) {
      connectionContextRequest = WorldMapConnectionContextRequest(
        projectRootPath: projectRootPath,
        project: state.project!,
        sourceMap: activeMap,
      );
    }
    final connectionContextAsync = connectionContextRequest == null
        ? null
        : ref.watch(
            worldMapConnectionContextProvider(connectionContextRequest),
          );
    final connectionContext = connectionContextAsync?.value;
    final selectedConnectionDirection = connectionModeActive
        ? ref.watch(worldMapConnectionDirectionProvider)
        : MapConnectionDirection.north;
    final connectionLabelsByDirection = resolveMapConnectionLabels(
      activeMap,
      state.project,
    );
    final tilesetPathsById = collectMapCanvasTilesetPaths(
      maps: [
        if (activeMap != null) activeMap,
        ...?connectionContext?.neighbors.values.map((neighbor) => neighbor.map),
      ],
      resolveTilesetAbsolutePath: notifier.getTilesetAbsolutePathById,
      activeBrushTilesetId: notifier.getActiveBrushTilesetId(),
      project: state.project,
      projectRootPath: state.projectRootPath,
      activeMap: activeMap,
      borderPreview: borderPreviewState.transaction,
    );
    final transparentColorByTilesetId = _collectTilesetTransparentColors(
      state.project,
    );
    _updateTilesetImagesFuture(
      imageCache,
      tilesetPathsById,
      transparentColorByTilesetId,
    );

    if (activeMap == null) {
      final cancelled = _interactionController.cancelActive();
      if (cancelled != null) {
        _scheduleMapInteractionRollback(cancelled.session);
      } else if (interaction.hasActiveMapStroke) {
        _scheduleOrphanedMapStrokeRollback();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncEditorEntityAnimationTicker(false);
        }
      });
      return const MapWorkspaceEmptyState();
    }

    TileLayer? hoveredTileLayer;
    if (hoveredTileLayerId != null) {
      for (final layer in activeMap.layers) {
        if (layer.id == hoveredTileLayerId && layer is TileLayer) {
          hoveredTileLayer = layer;
          break;
        }
      }
    }

    final tileWidth = settings.tileWidth * settings.displayScale;
    final tileHeight = settings.tileHeight * settings.displayScale;
    _scheduleNarrativeEventCameraFocus(
      request: bridgeState.focusRequest,
      map: activeMap,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      zoom: state.zoom,
    );

    return FutureBuilder<_TilesetImageBatch>(
      future: _tilesetImagesFuture,
      builder: (context, snapshot) {
        final batch = snapshot.data;
        final tilesetImageResults =
            batch?.generation == _tilesetImageRequestGeneration
            ? batch!.results
            : const <String, EditorImageLoadResult>{};
        final tilesetImagesById = <String, ui.Image?>{
          for (final entry in tilesetImageResults.entries)
            entry.key: entry.value.image,
        };
        final tilesetImageFailures = <String, EditorImageFailure>{
          for (final entry in tilesetImageResults.entries)
            if (entry.value.failure case final failure?) entry.key: failure,
        };
        final tilesPerRowById = <String, int>{};
        if (settings.tileWidth > 0) {
          tilesetImagesById.forEach((tilesetId, image) {
            if (image == null) return;
            final columns = image.width ~/ settings.tileWidth;
            if (columns > 0) {
              tilesPerRowById[tilesetId] = columns;
            }
          });
        }
        final needsAnimation = _hasAnimatedCanvasContent(
          map: activeMap,
          project: state.project,
          borderPreview: borderPreviewState.transaction,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _syncEditorEntityAnimationTicker(needsAnimation);
        });

        final keyboardCursor = _resolveKeyboardCursor(state, activeMap);
        final hoveredTile =
            _hoveredTile ?? (_mapFocusNode.hasFocus ? keyboardCursor : null);
        final smartTileGestureMode = ref.watch(
          worldMapSmartTileGestureModeProvider,
        );
        final selectedSmartTileMaterialId = ref.watch(
          worldMapSmartTileMaterialIdProvider,
        );
        final selectedSmartTilePatternId = ref.watch(
          worldMapSmartTilePatternIdProvider,
        );
        SmartTileLayer? activeSmartTileLayer;
        for (final layer in activeMap.layers) {
          if (layer.id == state.activeLayerId && layer is SmartTileLayer) {
            activeSmartTileLayer = layer;
            break;
          }
        }
        ProjectSmartTilePreset? activeSmartTilePreset;
        if (activeSmartTileLayer != null) {
          for (final preset
              in state.project?.smartTileCatalog.presets ??
                  const <ProjectSmartTilePreset>[]) {
            if (preset.id == activeSmartTileLayer.presetId) {
              activeSmartTilePreset = preset;
              break;
            }
          }
        }
        ProjectSmartTilePattern? activeSmartTilePattern;
        if (activeSmartTileLayer != null) {
          for (final pattern
              in state.project?.smartTileCatalog.patterns ??
                  const <ProjectSmartTilePattern>[]) {
            if (pattern.id == selectedSmartTilePatternId &&
                pattern.usage == activeSmartTileLayer.usage) {
              activeSmartTilePattern = pattern;
              break;
            }
          }
        }
        final smartTileCollisionLayerId = activeSmartTilePattern == null
            ? null
            : activeMap.layers.whereType<CollisionLayer>().firstOrNull?.id;
        final isActiveSmartTilePatternGestureSupported =
            activeSmartTilePattern == null ||
            state.activeTool == EditorToolType.eraser ||
            _smartTilePatternSupportsGesture(
              activeSmartTilePattern,
              smartTileGestureMode,
            );
        final activeSmartTileMaterialId = activeSmartTilePreset == null
            ? null
            : activeSmartTilePreset.allowedMaterialIds.contains(
                selectedSmartTileMaterialId,
              )
            ? selectedSmartTileMaterialId
            : activeSmartTilePreset.defaultMaterialId;
        final isSmartTileShapeEditing =
            activeSmartTileLayer != null &&
            (state.activeTool == EditorToolType.terrainPaint ||
                state.activeTool == EditorToolType.eraser) &&
            (activeSmartTilePattern != null ||
                smartTileGestureMode != WorldMapSmartTileGestureMode.brush);
        var toolPreview = notifier.resolveMapToolPreview(
          hoveredTile: hoveredTile,
          tilesetColumnsById: tilesPerRowById,
        );
        if (isSmartTileShapeEditing && hoveredTile != null) {
          final start = _smartTileShapeStart ?? hoveredTile;
          final end = _smartTileShapeEnd ?? hoveredTile;
          try {
            final cells =
                activeSmartTilePattern != null &&
                    state.activeTool == EditorToolType.terrainPaint
                ? applySmartTilePatternGesture(
                    activeSmartTileLayer,
                    pattern: activeSmartTilePattern,
                    mapSize: activeMap.size,
                    selection: _smartTilePatternSelection(
                      smartTileGestureMode,
                      start: start,
                      end: end,
                    ),
                    strokeId: 'preview',
                  ).affectedCells
                : compileSmartTileGestureSelection(
                    activeSmartTileLayer,
                    mapSize: activeMap.size,
                    selection: activeSmartTilePattern == null
                        ? _smartTileGestureSelection(
                            smartTileGestureMode,
                            start: start,
                            end: end,
                          )
                        : _smartTilePatternEraseSelection(
                            smartTileGestureMode,
                            start: start,
                            end: end,
                          ),
                  );
            final bounds = _smartTileGestureBounds(cells);
            toolPreview = state.activeTool == EditorToolType.eraser
                ? MapToolPreview.pathErase(
                    origin: bounds.origin,
                    size: bounds.size,
                    cells: cells,
                    validity: MapToolPreviewValidity.valid,
                  )
                : MapToolPreview.pathPaint(
                    origin: bounds.origin,
                    size: bounds.size,
                    cells: cells,
                    validity: MapToolPreviewValidity.valid,
                  );
          } on SmartTileGestureLimitException catch (error) {
            toolPreview = state.activeTool == EditorToolType.eraser
                ? MapToolPreview.pathErase(
                    origin: hoveredTile,
                    size: const GridSize(width: 1, height: 1),
                    validity: MapToolPreviewValidity.invalid,
                    reason: 'Maximum ${error.maximumCellCount} cellules',
                  )
                : MapToolPreview.pathPaint(
                    origin: hoveredTile,
                    size: const GridSize(width: 1, height: 1),
                    validity: MapToolPreviewValidity.invalid,
                    reason: 'Maximum ${error.maximumCellCount} cellules',
                  );
          } on Object catch (error) {
            if (error is! ValidationException && error is! StateError) {
              rethrow;
            }
            toolPreview = state.activeTool == EditorToolType.eraser
                ? MapToolPreview.pathErase(
                    origin: hoveredTile,
                    size: const GridSize(width: 1, height: 1),
                    validity: MapToolPreviewValidity.invalid,
                    reason: 'Geste incompatible avec ce motif',
                  )
                : MapToolPreview.pathPaint(
                    origin: hoveredTile,
                    size: const GridSize(width: 1, height: 1),
                    validity: MapToolPreviewValidity.invalid,
                    reason: 'Geste incompatible avec ce motif',
                  );
          }
        }
        final eraserPreview = state.activeTool == EditorToolType.eraser
            ? toolPreview
            : null;
        final shadowLightPreviewPreset =
            editorShadowLightPreviewPresetById(_shadowLightPreviewPresetId) ??
            neutralEditorShadowLightPreviewPreset;
        final environmentGeneratedAddPreview =
            hoveredTile != null && state.project != null
            ? switch (state.environmentMaskEditMode) {
                EnvironmentMaskEditMode.generatedAdd =>
                  resolveEnvironmentGeneratedPlacementAddPreview(
                    map: activeMap,
                    manifest: state.project!,
                    activeLayerId: state.activeLayerId,
                    selectedAreaId: state.selectedEnvironmentAreaId,
                    selectedElementId: selectedGeneratedPlacementElementId,
                    pos: hoveredTile,
                  ),
                _ => null,
              }
            : null;
        final environmentGeneratedDeleteTarget =
            hoveredTile != null && state.project != null
            ? switch (state.environmentMaskEditMode) {
                EnvironmentMaskEditMode.generatedDelete =>
                  resolveEnvironmentGeneratedPlacementDeleteTarget(
                    map: activeMap,
                    manifest: state.project,
                    activeLayerId: state.activeLayerId,
                    selectedAreaId: state.selectedEnvironmentAreaId,
                    pos: hoveredTile,
                  ),
                _ => null,
              }
            : null;
        final isEnvironmentMaskEditing = _isEnvironmentMaskEditing(
          state,
          activeMap,
        );
        final borderToolAvailability = assessBorderToolAvailability(
          manifest: state.project,
          map: activeMap,
          activeLayerId: state.activeLayerId,
          activeFeatureId: activeBorderFeature.activeFeatureId,
        );
        final canResumeResolvedLinearBorder =
            borderPreviewState.phase == BorderPreviewPhase.resolved &&
            borderPreviewState.transaction?.layerId == state.activeLayerId &&
            borderPreviewState.transaction?.featureId ==
                activeBorderFeature.activeFeatureId &&
            borderPreviewState.transaction?.proposedFeature.geometry
                is BorderStrokeGeometry;
        final isBorderEditing =
            borderToolAvailability.isEnabled &&
            (state.activeTool == EditorToolType.borderPaint ||
                state.activeTool == EditorToolType.borderErase) &&
            (borderPreviewState.phase == BorderPreviewPhase.idle ||
                borderPreviewState.phase == BorderPreviewPhase.drawing ||
                canResumeResolvedLinearBorder);
        BorderLayer? activeBorderLayer;
        for (final layer in activeMap.layers) {
          if (layer.id == state.activeLayerId && layer is BorderLayer) {
            activeBorderLayer = layer;
            break;
          }
        }
        final persistedActiveBorderFeature = activeBorderLayer?.content
            .featureById(activeBorderFeature.activeFeatureId ?? '');
        final usesGridEdgeSnapping =
            switch (persistedActiveBorderFeature?.geometry) {
              BorderStrokeGeometry(:final alignment) =>
                alignment == BorderStrokeAlignment.gridEdges,
              _ => false,
            };

        GridPos? screenToActiveToolGrid(Offset localPosition) {
          if (isBorderEditing && usesGridEdgeSnapping) {
            return snapBorderGridVertex(
              localPosition: localPosition,
              pan: state.panOffset,
              zoom: state.zoom,
              mapSize: activeMap.size,
              tileWidth: tileWidth,
              tileHeight: tileHeight,
            );
          }
          return _screenToGrid(
            localPosition,
            state.panOffset,
            state.zoom,
            activeMap.size,
            tileWidth,
            tileHeight,
          );
        }

        final isInertTilePaint =
            state.activeTool == EditorToolType.tilePaint &&
            state.activeBrush is NoEditorBrush;
        final isSmartTileShapeTool = isSmartTileShapeEditing;
        final isDirectSmartTileStroke =
            (state.activeTool == EditorToolType.terrainPaint ||
                state.activeTool == EditorToolType.eraser) &&
            !isSmartTileShapeTool;
        final isDirectStrokeEditingTool =
            (state.activeTool == EditorToolType.tilePaint &&
                !isInertTilePaint) ||
            isDirectSmartTileStroke ||
            state.activeTool == EditorToolType.collisionPaint ||
            isEnvironmentMaskEditing;
        final isStrokeEditingTool =
            isDirectStrokeEditingTool ||
            isSmartTileShapeTool ||
            isBorderEditing;
        final isNpcWaypointPlacementActive =
            (state.npcWaypointPlacementEntityId?.trim().isNotEmpty ?? false);
        final isTapEditingTool =
            isStrokeEditingTool ||
            state.activeTool == EditorToolType.entityPlacement ||
            state.activeTool == EditorToolType.eventPlacement ||
            state.activeTool == EditorToolType.warpPlacement ||
            state.activeTool == EditorToolType.triggerPlacement ||
            state.activeTool == EditorToolType.gameplayZonePlacement;
        final isNarrativeEventGuidedNavigation =
            bridgeState.pendingReturn != null &&
            (bridgeState.navigationMode ==
                    NarrativeEventMapNavigationMode.create ||
                bridgeState.navigationMode ==
                    NarrativeEventMapNavigationMode.choose);

        final environmentMaskOverlay = isEnvironmentMaskEditing
            ? resolveEnvironmentMaskPaintTarget(
                map: activeMap,
                activeLayerId: state.activeLayerId,
                selectedAreaId: state.selectedEnvironmentAreaId,
              )?.area.mask
            : null;
        final environmentBrushCursorOverlay =
            isEnvironmentMaskEditing && hoveredTile != null
            ? EnvironmentMaskBrushCursorOverlay(
                center: hoveredTile,
                brushSize: environmentMaskBrushSize,
                mode: state.environmentMaskEditMode!,
              )
            : null;

        void previewBorderGeometry(BorderFeatureGeometry geometry) {
          final transaction = borderPreviewController.current.transaction;
          if (transaction == null) return;
          final catalog = state.project?.borderCatalog;
          final revision = catalog
              ?.recordById(transaction.proposedFeature.blueprintId)
              ?.latestPublished;
          borderPreviewController.previewGeometry(
            geometry,
            blueprintRevision: revision,
            tileSizePx: GridSize(
              width: settings.tileWidth,
              height: settings.tileHeight,
            ),
            visualSnapshots:
                catalog?.visualSnapshots ?? const <BorderVisualSnapshot>[],
            resolverVersion: borderResolverVersion,
          );
        }

        void applyToolAt(GridPos gridPos, {bool partOfStroke = false}) {
          if (isBorderEditing) {
            if (_borderStrokeGestureRejected) return;
            if (borderPreviewController.current.phase ==
                BorderPreviewPhase.idle) {
              final previewContext = _borderPreviewContextForCanvas(
                state,
                activeMap,
              );
              if (previewContext == null) return;
              borderPreviewController.begin(
                map: activeMap,
                layerId: state.activeLayerId!,
                featureId: activeBorderFeature.activeFeatureId!,
                context: previewContext,
              );
            } else if (borderPreviewController.current.phase ==
                BorderPreviewPhase.resolved) {
              final resumed = borderPreviewController.resumeDrawing(
                layerId: state.activeLayerId!,
                featureId: activeBorderFeature.activeFeatureId!,
              );
              if (!resumed) return;
            }
            final transaction = borderPreviewController.current.transaction;
            final geometry = transaction?.proposedFeature.geometry;
            if (borderPreviewController.current.phase !=
                BorderPreviewPhase.drawing) {
              return;
            }
            if (geometry is BorderRegionGeometry) {
              final previousCell = partOfStroke
                  ? _lastBorderPaintCell ?? gridPos
                  : gridPos;
              final updated = editBorderRegionSegment(
                geometry,
                previousCell,
                gridPos,
                filled: state.activeTool == EditorToolType.borderPaint,
              );
              previewBorderGeometry(updated);
              return;
            }
            if (geometry is BorderStrokeGeometry) {
              final mode = state.activeTool == EditorToolType.borderPaint
                  ? BorderStrokeEditingMode.draw
                  : BorderStrokeEditingMode.erase;
              final currentDraft =
                  _borderStrokeEditingDraft ??
                  BorderStrokeEditingDraft.begin(
                    baseGeometry: geometry,
                    mode: mode,
                    pointerDown: gridPos,
                  );
              final sampledDraft = currentDraft.sample(gridPos);
              try {
                final updated = sampledDraft.previewGeometry;
                if (updated != null) {
                  // Linear chains can contain hundreds of snapped vertices.
                  // Keep the authored draft live during the drag, then run the
                  // expensive deterministic resolver once on pointer release.
                  borderPreviewController.updateGeometry(updated);
                }
                _borderStrokeEditingDraft = sampledDraft;
              } on ValidationException {
                // Invalid input rejects this gesture. If it was extending a
                // resolved multi-stroke proposal, keep that exact checkpoint;
                // a malformed second stroke must not erase the first one.
                _borderStrokeEditingDraft = null;
                _borderStrokeGestureRejected = true;
                borderPreviewController.rollbackDrawingGesture();
              }
            }
            return;
          }
          if (isEnvironmentMaskEditing) {
            notifier.paintEnvironmentAreaMaskAt(
              gridPos,
              partOfStroke: partOfStroke,
            );
            return;
          }
          if (isSmartTileShapeTool) {
            if (activeSmartTilePattern != null) {
              if (!isActiveSmartTilePatternGestureSupported) return;
              if (state.activeTool == EditorToolType.eraser) {
                notifier.eraseActiveSmartTilePattern(
                  _smartTilePatternEraseSelection(
                    smartTileGestureMode,
                    start: gridPos,
                    end: gridPos,
                  ),
                );
              } else {
                notifier.paintActiveSmartTilePattern(
                  _smartTilePatternSelection(
                    smartTileGestureMode,
                    start: gridPos,
                    end: gridPos,
                  ),
                  patternId: activeSmartTilePattern.id,
                  collisionLayerId: smartTileCollisionLayerId,
                );
              }
            } else {
              notifier.applyActiveSmartTileSelection(
                _smartTileGestureSelection(
                  smartTileGestureMode,
                  start: gridPos,
                  end: gridPos,
                ),
                materialId: activeSmartTileMaterialId,
              );
            }
            return;
          }
          if (state.activeTool == EditorToolType.tilePaint) {
            unawaited(
              notifier.paintSelectedBrushAt(
                gridPos,
                tilesetColumnsById: tilesPerRowById,
                partOfStroke: partOfStroke,
              ),
            );
            return;
          }
          if (state.activeTool == EditorToolType.terrainPaint) {
            notifier.paintActiveSmartTileAt(
              gridPos,
              materialId: activeSmartTileMaterialId,
            );
            return;
          }
          if (state.activeTool == EditorToolType.collisionPaint) {
            notifier.paintCollisionAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.eraser) {
            notifier.eraseAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.entityPlacement) {
            notifier.placeOrSelectEntityAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.eventPlacement) {
            notifier.placeOrSelectMapEventAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.warpPlacement) {
            notifier.placeOrSelectWarpAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.triggerPlacement) {
            notifier.placeOrSelectTriggerAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.gameplayZonePlacement) {
            notifier.placeOrSelectGameplayZoneAt(gridPos);
          }
        }

        void finishBorderPreview() {
          if (!isBorderEditing ||
              borderPreviewController.current.phase !=
                  BorderPreviewPhase.drawing) {
            return;
          }
          final transaction = borderPreviewController.current.transaction!;
          if (transaction.result == null) {
            final geometry = transaction.proposedFeature.geometry;
            if (geometry is BorderRegionGeometry) {
              previewBorderGeometry(geometry);
            } else if (geometry is BorderStrokeGeometry) {
              final completedGeometry =
                  _borderStrokeEditingDraft?.previewGeometry;
              if (completedGeometry == null) {
                _borderStrokeEditingDraft = null;
                borderPreviewController.rollbackDrawingGesture();
                return;
              }
              previewBorderGeometry(completedGeometry);
            }
          }
          borderPreviewController.finishDrawing();
          _borderStrokeEditingDraft = null;
        }

        _keyboardCellActivation = (gridPos) {
          if (isNarrativeEventGuidedNavigation) return;
          if (state.activeTool == EditorToolType.selection &&
              !isEnvironmentMaskEditing) {
            widget.onCellSelected?.call(gridPos);
            notifier.selectCanvasObjectAt(
              gridPos,
              editorAnimationTimeMs: _repaintClock.elapsedMs,
            );
            return;
          }
          if (!isTapEditingTool) return;
          if (isDirectStrokeEditingTool) notifier.beginMapStroke();
          applyToolAt(gridPos, partOfStroke: isStrokeEditingTool);
          if (isBorderEditing) {
            finishBorderPreview();
          } else if (isDirectStrokeEditingTool) {
            notifier.endMapStroke();
          }
        };

        final interactiveCanvas = Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onMapPointerDown,
          onPointerMove: _onMapPointerMove,
          onPointerUp: _onMapPointerUp,
          onPointerCancel: _onMapPointerCancel,
          onPointerSignal: _onMapPointerSignal,
          onPointerPanZoomStart: _onMapPointerPanZoomStart,
          onPointerPanZoomUpdate: _onMapPointerPanZoomUpdate,
          onPointerPanZoomEnd: _onMapPointerPanZoomEnd,
          onPointerHover: (event) => _onMapPointerHover(event.localPosition),
          child: GestureDetector(
            key: const ValueKey<String>('map-canvas-gesture-detector'),
            supportedDevices: const <ui.PointerDeviceKind>{
              ui.PointerDeviceKind.mouse,
              ui.PointerDeviceKind.touch,
              ui.PointerDeviceKind.stylus,
              ui.PointerDeviceKind.invertedStylus,
            },
            dragStartBehavior: DragStartBehavior.down,
            onTapUp: (details) {
              final pendingSession = _interactionController.activeSession;
              if (pendingSession == null ||
                  pendingSession.kind !=
                      MapCanvasInteractionKind.pendingPrimary) {
                return;
              }
              if (!_ensureCurrentInteractionContext(pendingSession)) return;
              final interactionPointerId = pendingSession.pointerId;
              try {
                final gridPos = screenToActiveToolGrid(details.localPosition);

                if (bridgeState.pendingReturn != null &&
                    bridgeState.navigationMode ==
                        NarrativeEventMapNavigationMode.create) {
                  if (gridPos == null) return;
                  final kind = bridgeState.sourceCreationKind;
                  if (kind != null && !bridgeState.isSourceCreationBusy) {
                    final proposal = notifier.proposeNarrativeEventSourceAt(
                      position: gridPos,
                      kind: kind,
                    );
                    if (proposal != null) {
                      ref
                          .read(
                            narrativeEventMapBridgeControllerProvider.notifier,
                          )
                          .previewSourceCreationProposal(proposal);
                    }
                  }
                  return;
                }

                final eventBuilderPositionChosen =
                    widget.onEventBuilderPositionChosen;
                if (eventBuilderPositionChosen != null) {
                  final eventGridPos = _screenToGrid(
                    details.localPosition,
                    state.panOffset,
                    state.zoom,
                    activeMap.size,
                    tileWidth,
                    tileHeight,
                  );
                  if (eventGridPos == null) return;
                  eventBuilderPositionChosen(eventGridPos);
                  return;
                }

                if (bridgeState.pendingReturn != null &&
                    bridgeState.navigationMode ==
                        NarrativeEventMapNavigationMode.choose) {
                  if (gridPos == null) return;
                  final candidate = resolveNarrativeEventMapCandidateAt(
                    map: activeMap,
                    pos: gridPos,
                  );
                  final project = state.project;
                  if (candidate != null && project != null) {
                    final bridgeController = ref.read(
                      narrativeEventMapBridgeControllerProvider.notifier,
                    );
                    if (bridgeController.previewChosenSource(
                      project: project,
                      map: activeMap,
                      source: candidate,
                    )) {
                      final focus = ref
                          .read(narrativeEventMapBridgeControllerProvider)
                          .focusRequest
                          ?.focusTarget;
                      if (focus != null) {
                        notifier.focusNarrativeEventMapSource(focus);
                      }
                    }
                  }
                  return;
                }

                if (gridPos == null) return;

                // Mode secondaire explicite: placement visuel de waypoint NPC.
                // Tant qu'il est actif, le clic map est routé vers l'ajout d'un
                // waypoint, avant d'appliquer les outils classiques.
                if (isNpcWaypointPlacementActive) {
                  final handled = notifier.addNpcWaypointAt(gridPos);
                  if (handled) {
                    return;
                  }
                }

                if (state.environmentMaskEditMode ==
                    EnvironmentMaskEditMode.generatedAdd) {
                  notifier.addGeneratedEnvironmentPlacementAt(gridPos);
                  return;
                }

                if (state.environmentMaskEditMode ==
                    EnvironmentMaskEditMode.generatedDelete) {
                  notifier.deleteGeneratedEnvironmentPlacementAt(gridPos);
                  return;
                }

                if (state.activeTool == EditorToolType.selection &&
                    !isEnvironmentMaskEditing) {
                  widget.onCellSelected?.call(gridPos);
                  final objectTarget = notifier.selectCanvasObjectAt(
                    gridPos,
                    editorAnimationTimeMs: _repaintClock.elapsedMs,
                  );
                  if (objectTarget == null && activeBorderLayer != null) {
                    final borderHit = hitTestBorderFeatureAtScreenPosition(
                      layer: activeBorderLayer,
                      localPosition: details.localPosition,
                      pan: state.panOffset,
                      zoom: state.zoom,
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                    );
                    if (borderHit != null) {
                      notifier.selectBorderFeature(
                        layerId: activeBorderLayer.id,
                        featureId: borderHit.id,
                      );
                    }
                  }
                  return;
                }

                if (!isTapEditingTool) return;
                if (isDirectStrokeEditingTool || isSmartTileShapeTool) {
                  final promoted = _interactionController.promotePending(
                    pointerId: interactionPointerId,
                    kind: MapCanvasInteractionKind.paintingStroke,
                  );
                  if (promoted == null) return;
                  if (isDirectStrokeEditingTool) notifier.beginMapStroke();
                } else if (isBorderEditing) {
                  final promoted = _interactionController.promotePending(
                    pointerId: interactionPointerId,
                    kind: MapCanvasInteractionKind.borderGesture,
                  );
                  if (promoted == null) return;
                }
                applyToolAt(gridPos, partOfStroke: isStrokeEditingTool);
                if (isBorderEditing) {
                  finishBorderPreview();
                } else if (isDirectStrokeEditingTool) {
                  notifier.endMapStroke();
                }
              } finally {
                _interactionController.finishPointer(interactionPointerId);
              }
            },
            onPanStart: (details) {
              final pendingSession = _interactionController.activeSession;
              if (pendingSession == null ||
                  pendingSession.kind !=
                      MapCanvasInteractionKind.pendingPrimary) {
                return;
              }
              final interactionPointerId = pendingSession.pointerId;
              if (!_ensureCurrentInteractionContext(pendingSession)) return;
              if (isNarrativeEventGuidedNavigation) {
                _cancelAndRollbackPointer(interactionPointerId);
                return;
              }
              if (state.activeTool == EditorToolType.selection &&
                  !isEnvironmentMaskEditing) {
                final grabCell = _screenToGrid(
                  details.localPosition,
                  state.panOffset,
                  state.zoom,
                  activeMap.size,
                  tileWidth,
                  tileHeight,
                );
                if (grabCell == null) {
                  _cancelAndRollbackPointer(interactionPointerId);
                  return;
                }
                final target = notifier.selectCanvasObjectForDragAt(
                  grabCell,
                  editorAnimationTimeMs: _repaintClock.elapsedMs,
                );
                if (target == null) {
                  _cancelAndRollbackPointer(interactionPointerId);
                  return;
                }
                final promoted = _interactionController.promotePending(
                  pointerId: interactionPointerId,
                  kind: MapCanvasInteractionKind.draggingSelection,
                );
                if (promoted == null) return;
                final latestPointerCell = _screenToUnboundedGrid(
                  _latestMapPointerLocalPositions[interactionPointerId] ??
                      details.localPosition,
                  state.panOffset,
                  state.zoom,
                  tileWidth,
                  tileHeight,
                );
                final destinationAnchor = GridPos(
                  x: target.anchor.x + latestPointerCell.x - grabCell.x,
                  y: target.anchor.y + latestPointerCell.y - grabCell.y,
                );
                const planner = MapCanvasObjectMovePlanner();
                final plan = planner.plan(
                  map: activeMap,
                  project: state.project,
                  target: target,
                  destinationAnchor: destinationAnchor,
                );
                _activeGestureInteractionId = promoted.interactionId;
                setState(() {
                  _objectMovePreview = _MapCanvasObjectMovePreview(
                    sourceMap: activeMap,
                    target: target,
                    grabCell: grabCell,
                    destinationAnchor: destinationAnchor,
                    plan: plan,
                    contextAfterSelection: _currentMapInteractionContext(),
                  );
                });
                return;
              }
              if (state.activeTool == EditorToolType.gameplayZonePlacement) {
                final promoted = _interactionController.promotePending(
                  pointerId: interactionPointerId,
                  kind: MapCanvasInteractionKind.drawingZone,
                );
                if (promoted == null) return;
                _activeGestureInteractionId = promoted.interactionId;
                final gridPos = _screenToGrid(
                  details.localPosition,
                  state.panOffset,
                  state.zoom,
                  activeMap.size,
                  tileWidth,
                  tileHeight,
                );
                if (gridPos == null) {
                  _cancelAndRollbackPointer(interactionPointerId);
                  return;
                }
                setState(() => _zoneDragStart = gridPos);
                notifier.setGameplayZoneDraftArea(
                  MapRect(
                    pos: gridPos,
                    size: const GridSize(width: 1, height: 1),
                  ),
                );
                return;
              }
              if (!isStrokeEditingTool) {
                _cancelAndRollbackPointer(interactionPointerId);
                return;
              }
              final promoted = _interactionController.promotePending(
                pointerId: interactionPointerId,
                kind: isBorderEditing
                    ? MapCanvasInteractionKind.borderGesture
                    : MapCanvasInteractionKind.paintingStroke,
              );
              if (promoted == null) return;
              _activeGestureInteractionId = promoted.interactionId;
              final gridPos = screenToActiveToolGrid(details.localPosition);
              if (gridPos == null) {
                _cancelAndRollbackPointer(interactionPointerId);
                return;
              }
              if (isSmartTileShapeTool) {
                setState(() {
                  _smartTileShapeStart = gridPos;
                  _smartTileShapeEnd = gridPos;
                });
                return;
              }
              if (isEnvironmentMaskEditing) {
                _lastEnvironmentMaskPaintCell = null;
              }
              if (isBorderEditing) {
                _lastBorderPaintCell = null;
                _borderStrokeEditingDraft = null;
                _borderStrokeGestureRejected = false;
              } else {
                notifier.beginMapStroke();
              }
              applyToolAt(gridPos, partOfStroke: true);
              if (isEnvironmentMaskEditing) {
                _lastEnvironmentMaskPaintCell = gridPos;
              }
              if (isBorderEditing) {
                _lastBorderPaintCell = gridPos;
              }
            },
            onPanUpdate: (details) {
              final interaction = _activeGestureInteraction();
              if (interaction == null ||
                  !_ensureCurrentInteractionContext(interaction)) {
                return;
              }
              final interactionKind = interaction.kind;
              if (interactionKind ==
                  MapCanvasInteractionKind.draggingSelection) {
                _updateObjectMovePreview(details.localPosition);
                return;
              }
              if (interactionKind == MapCanvasInteractionKind.drawingZone &&
                  _zoneDragStart != null) {
                final gridPos = _screenToGrid(
                  details.localPosition,
                  state.panOffset,
                  state.zoom,
                  activeMap.size,
                  tileWidth,
                  tileHeight,
                );
                if (gridPos != null) {
                  notifier.setGameplayZoneDraftArea(
                    _rectFromCorners(_zoneDragStart!, gridPos),
                  );
                }
                return;
              }
              final isActiveStroke =
                  interactionKind == MapCanvasInteractionKind.paintingStroke ||
                  interactionKind == MapCanvasInteractionKind.borderGesture;
              if (!isActiveStroke || !isStrokeEditingTool) return;
              final gridPos = screenToActiveToolGrid(details.localPosition);
              if (gridPos != null) {
                if (isSmartTileShapeTool) {
                  if (_smartTileShapeEnd != gridPos) {
                    setState(() => _smartTileShapeEnd = gridPos);
                  }
                  return;
                }
                if (isEnvironmentMaskEditing &&
                    _lastEnvironmentMaskPaintCell == gridPos) {
                  return;
                }
                if (isBorderEditing && _lastBorderPaintCell == gridPos) {
                  return;
                }
                applyToolAt(gridPos, partOfStroke: true);
                if (isEnvironmentMaskEditing) {
                  _lastEnvironmentMaskPaintCell = gridPos;
                }
                if (isBorderEditing) {
                  _lastBorderPaintCell = gridPos;
                }
              }
            },
            onPanEnd: (_) {
              _borderStrokeGestureRejected = false;
              final interaction = _activeGestureInteraction();
              if (interaction == null ||
                  !_ensureCurrentInteractionContext(interaction)) {
                return;
              }
              if (interaction.kind == MapCanvasInteractionKind.drawingZone &&
                  _zoneDragStart != null) {
                setState(() => _zoneDragStart = null);
                notifier.commitGameplayZoneDraft();
              } else if (interaction.kind ==
                  MapCanvasInteractionKind.draggingSelection) {
                final preview = _objectMovePreview;
                if (preview != null &&
                    (preview.plan.canCommit ||
                        preview.plan.rejection != null)) {
                  notifier.commitCanvasObjectMove(
                    sourceMap: preview.sourceMap,
                    target: preview.target,
                    destinationAnchor: preview.destinationAnchor,
                  );
                }
                setState(() => _objectMovePreview = null);
              } else if (interaction.kind ==
                      MapCanvasInteractionKind.paintingStroke ||
                  interaction.kind == MapCanvasInteractionKind.borderGesture) {
                if (isEnvironmentMaskEditing) {
                  _lastEnvironmentMaskPaintCell = null;
                }
                if (interaction.kind ==
                    MapCanvasInteractionKind.borderGesture) {
                  _lastBorderPaintCell = null;
                  finishBorderPreview();
                } else if (isSmartTileShapeTool) {
                  final start = _smartTileShapeStart;
                  final end = _smartTileShapeEnd;
                  setState(() {
                    _smartTileShapeStart = null;
                    _smartTileShapeEnd = null;
                  });
                  if (start != null && end != null) {
                    if (activeSmartTilePattern != null) {
                      if (!isActiveSmartTilePatternGestureSupported) {
                        // A stale session can retain a gesture that the newly
                        // selected pattern cannot represent. The palette resets
                        // it, while this guard keeps canvas input fail-closed.
                      } else if (state.activeTool == EditorToolType.eraser) {
                        notifier.eraseActiveSmartTilePattern(
                          _smartTilePatternEraseSelection(
                            smartTileGestureMode,
                            start: start,
                            end: end,
                          ),
                        );
                      } else {
                        notifier.paintActiveSmartTilePattern(
                          _smartTilePatternSelection(
                            smartTileGestureMode,
                            start: start,
                            end: end,
                          ),
                          patternId: activeSmartTilePattern.id,
                          collisionLayerId: smartTileCollisionLayerId,
                        );
                      }
                    } else {
                      notifier.applyActiveSmartTileSelection(
                        _smartTileGestureSelection(
                          smartTileGestureMode,
                          start: start,
                          end: end,
                        ),
                        materialId: activeSmartTileMaterialId,
                      );
                    }
                  }
                } else {
                  notifier.endMapStroke();
                }
              }
              _interactionController.finishPointer(interaction.pointerId);
              _activeGestureInteractionId = null;
            },
            onPanCancel: () {
              _borderStrokeGestureRejected = false;
              if (_interactionController.activeSession?.kind ==
                  MapCanvasInteractionKind.pendingPrimary) {
                return;
              }
              final interaction = _activeGestureInteraction();
              if (interaction == null) return;
              final cancelled = _interactionController.cancelPointer(
                interaction.pointerId,
              );
              if (cancelled == null) return;
              _rollbackMapInteraction(cancelled.session);
              if (mounted) setState(() {});
            },
            child: MouseRegion(
              cursor:
                  (_interactionController.activeSession?.kind ==
                          MapCanvasInteractionKind.panning ||
                      _interactionController.activeSession?.kind ==
                          MapCanvasInteractionKind.draggingSelection)
                  ? SystemMouseCursors.grabbing
                  : _spacePressed && _interactionController.isIdle
                  ? SystemMouseCursors.grab
                  : state.activeTool == EditorToolType.eraser
                  ? SystemMouseCursors.precise
                  : SystemMouseCursors.basic,
              onExit: (_) {
                if (_hoveredTile != null || _hoveredBorderVertex != null) {
                  setState(() {
                    _hoveredTile = null;
                    _hoveredBorderVertex = null;
                  });
                }
              },
              child: ClipRect(
                key: _mapViewportKey,
                child: Stack(
                  children: [
                    if (connectionContext case final loadedContext?)
                      Positioned.fill(
                        child: MapConnectionContextLayer(
                          context: loadedContext,
                          selectedDirection: selectedConnectionDirection,
                          zoom: state.zoom,
                          offset: state.panOffset,
                          tileWidth: tileWidth,
                          tileHeight: tileHeight,
                          sourceTileWidth: settings.tileWidth,
                          sourceTileHeight: settings.tileHeight,
                          tilesetImagesById: tilesetImagesById,
                          tilesPerRowById: tilesPerRowById,
                          project: state.project,
                          shadowLightPreviewPreset: shadowLightPreviewPreset,
                          animationClock: _repaintClock,
                        ),
                      ),
                    Positioned.fill(
                      child: Focus(
                        key: const ValueKey<String>('map-canvas-focus'),
                        focusNode: _mapFocusNode,
                        skipTraversal: false,
                        includeSemantics: false,
                        onKeyEvent: _onMapKeyEvent,
                        onFocusChange: _onMapFocusChanged,
                        child: Semantics(
                          container: true,
                          liveRegion: true,
                          label:
                              '${mapCanvasSelectionSemanticsLabel(state: state, map: activeMap, project: state.project, selectedBorderFeatureId: activeBorderFeature.activeFeatureId, editorAnimationTimeMs: _repaintClock.elapsedMs)} Curseur cellule x ${keyboardCursor.x}, '
                              'y ${keyboardCursor.y}.',
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: MapGridPainter(
                              map: activeMap,
                              shadowProjectionOwner:
                                  _shadowPreviewProjectionOwner,
                              zoom: state.zoom,
                              offset: state.panOffset,
                              hoveredTile:
                                  environmentBrushCursorOverlay == null &&
                                      state.environmentMaskEditMode !=
                                          EnvironmentMaskEditMode
                                              .generatedAdd &&
                                      eraserPreview == null
                                  ? hoveredTile
                                  : null,
                              activeLayerId: state.activeLayerId,
                              tileWidth: tileWidth,
                              tileHeight: tileHeight,
                              tilesetImagesById: tilesetImagesById,
                              sourceTileWidth: settings.tileWidth,
                              sourceTileHeight: settings.tileHeight,
                              tilesPerRowById: tilesPerRowById,
                              toolPreview: toolPreview,
                              warps: activeMap.warps,
                              gameplayZones: activeMap.gameplayZones,
                              gameplayZoneDraftArea:
                                  state.gameplayZoneDraftArea,
                              selectedEntityId: state.selectedEntityId,
                              selectedMapEventId: state.selectedMapEventId,
                              selectedWarpId: state.selectedWarpId,
                              selectedTriggerId: state.selectedTriggerId,
                              selectedGameplayZoneId:
                                  state.selectedGameplayZoneId,
                              selectedPlacedElementInstanceId:
                                  state.selectedPlacedElementInstanceId,
                              placedElementRotationPreview:
                                  widget.placedElementRotationPreview?.plan,
                              narrativeEventFocusTarget:
                                  bridgeState.focusRequest?.focusTarget,
                              narrativeEventSourceProposal:
                                  bridgeState.sourceCreationProposal,
                              narrativeEventHighlightColor: colors.narrative,
                              rotationPreviewAcceptedColor: colors.info,
                              rotationPreviewRejectedColor: colors.error,
                              connectionLabelsByDirection:
                                  connectionLabelsByDirection,
                              project: state.project,
                              shadowLightPreviewPreset:
                                  shadowLightPreviewPreset,
                              animationClock: _repaintClock,
                              debugOnPaint: widget.debugOnPaint,
                              showGrid: _showMapGrid,
                              environmentMaskOverlay: environmentMaskOverlay,
                              environmentBrushCursorOverlay:
                                  environmentBrushCursorOverlay,
                              environmentGeneratedAddPreview:
                                  environmentGeneratedAddPreview,
                              environmentGeneratedDeletePreviewId:
                                  environmentGeneratedDeleteTarget?.placed.id,
                              borderPreview: borderPreviewState.transaction,
                              borderDiagnosticOverlayPalette:
                                  EditorBorderDiagnosticOverlayPalette(
                                    warningFill: colors.warningSoft.withValues(
                                      alpha: 0.72,
                                    ),
                                    warningStroke: colors.warningBorder,
                                    errorFill: colors.errorSoft.withValues(
                                      alpha: 0.72,
                                    ),
                                    errorStroke: colors.errorBorder,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (connectionContext case final loadedContext?)
                      Positioned.fill(
                        child: MapConnectionContextNavigationLayer(
                          context: loadedContext,
                          zoom: state.zoom,
                          offset: state.panOffset,
                          tileWidth: tileWidth,
                          tileHeight: tileHeight,
                          enabled: !state.isSaving,
                          onPressed: (direction) {
                            unawaited(
                              requestEditorConnectedMapSaveAndActivation(
                                context: context,
                                notifier: notifier,
                                direction: direction,
                              ),
                            );
                          },
                        ),
                      ),
                    if (hoveredTileLayer case final layer?)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            key: const ValueKey<String>(
                              'map-canvas-tile-layer-hover-highlight',
                            ),
                            painter: TileLayerHoverHighlightPainter(
                              layer: layer,
                              mapSize: activeMap.size,
                              zoom: state.zoom,
                              offset: state.panOffset,
                              tileWidth: tileWidth,
                              tileHeight: tileHeight,
                              color: colors.brandPrimary,
                            ),
                          ),
                        ),
                      ),
                    if (_objectMovePreview case final preview?)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Semantics(
                            liveRegion: true,
                            label: _mapCanvasObjectMovePreviewSemanticsLabel(
                              preview,
                            ),
                            child: CustomPaint(
                              key: const ValueKey<String>(
                                'map-canvas-object-move-preview',
                              ),
                              painter: _MapCanvasObjectMovePreviewPainter(
                                target: preview.visualTarget,
                                pan: state.panOffset,
                                zoom: state.zoom,
                                tileWidth: tileWidth,
                                tileHeight: tileHeight,
                                fillColor: preview.isRejected
                                    ? colors.errorSoft.withValues(alpha: 0.62)
                                    : colors.brandPrimarySoft.withValues(
                                        alpha: 0.62,
                                      ),
                                strokeColor: preview.isRejected
                                    ? colors.errorBorder
                                    : colors.brandPrimaryBorder,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isBorderEditing &&
                        usesGridEdgeSnapping &&
                        _hoveredBorderVertex != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            key: const ValueKey<String>(
                              'border-grid-edge-guide',
                            ),
                            painter: _BorderGridEdgeGuidePainter(
                              vertex: _hoveredBorderVertex!,
                              mapSize: activeMap.size,
                              pan: state.panOffset,
                              zoom: state.zoom,
                              tileWidth: tileWidth,
                              tileHeight: tileHeight,
                              color: colors.brandPrimary,
                            ),
                          ),
                        ),
                      ),
                    if (bridgeState.pendingReturn != null ||
                        narrativeNavigation.pendingReturn != null)
                      const Positioned(
                        left: 12,
                        top: 12,
                        child: NarrativeEventMapBanner(),
                      ),
                    if (isNpcWaypointPlacementActive)
                      Positioned(
                        left: 12,
                        top: bridgeState.pendingReturn == null ? 12 : 190,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.brandPrimaryBorder,
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'Placement de waypoint actif • Cliquez sur la carte pour ajouter',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_hoveredTile != null && eraserPreview != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          key: const ValueKey<String>(
                            'eraser-footprint-cursor-badge',
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const badgeMargin = 8.0;
                              const badgeMaxWidth = 160.0;
                              final desiredLeft =
                                  state.panOffset.dx +
                                  (_hoveredTile!.x + eraserPreview.size.width) *
                                      tileWidth *
                                      state.zoom +
                                  badgeMargin;
                              final desiredTop =
                                  state.panOffset.dy +
                                  _hoveredTile!.y * tileHeight * state.zoom -
                                  26;
                              final maxLeft = math.max(
                                badgeMargin,
                                constraints.maxWidth -
                                    badgeMaxWidth -
                                    badgeMargin,
                              );
                              final maxTop = math.max(
                                badgeMargin,
                                constraints.maxHeight - 28,
                              );
                              return Stack(
                                children: [
                                  Positioned(
                                    left: desiredLeft
                                        .clamp(badgeMargin, maxLeft)
                                        .toDouble(),
                                    top: desiredTop
                                        .clamp(badgeMargin, maxTop)
                                        .toDouble(),
                                    child: Semantics(
                                      label:
                                          'Empreinte de la gomme : ${eraserPreview.size.width} par ${eraserPreview.size.height} cases',
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: badgeMaxWidth,
                                        ),
                                        child: PokeMapBadge(
                                          label:
                                              'Gomme ${eraserPreview.size.width}×${eraserPreview.size.height}',
                                          variant:
                                              PokeMapBadgeVariant.mapAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerMove: _onMapPointerButtonsChanged,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        return FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              interactiveCanvas,
              if (tilesetImageFailures.isNotEmpty)
                Positioned(
                  left: 12,
                  top: 12,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: PokeMapDiagnosticCallout(
                      severity: PokeMapDiagnosticSeverity.warning,
                      title: 'Assets de carte indisponibles',
                      message: _mapCanvasImageFailureMessage(
                        tilesetImageFailures,
                        state.project,
                      ),
                      actionLabel:
                          state.projectRootPath?.trim().isEmpty == false
                          ? 'Actualiser'
                          : null,
                      onAction: state.projectRootPath?.trim().isEmpty == false
                          ? () => ref.invalidate(
                              editorImageCacheProvider(
                                state.projectRootPath!.trim(),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Focus.withExternalFocusNode(
                    focusNode: _mapNavigationControlsFocusNode,
                    includeSemantics: false,
                    child: MapCanvasNavigationControls(
                      zoom: state.zoom,
                      onZoomOut: _zoomOut,
                      onZoomIn: _zoomIn,
                      onFit: _fitActiveMap,
                      onActualSize: _showActiveMapAtActualSize,
                      onCenter: _centerActiveMap,
                    ),
                  ),
                ),
              ),
              if (state.project != null &&
                  widget.onEventBuilderPositionChosen == null)
                Positioned(
                  right: 12,
                  top: 12,
                  child: _shadowLightPreviewSelector(
                    context,
                    colors,
                    shadowLightPreviewPreset,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _scheduleNarrativeEventCameraFocus({
    required NarrativeEventMapFocusRequest? request,
    required MapData map,
    required double tileWidth,
    required double tileHeight,
    required double zoom,
  }) {
    if (request == null ||
        request.cameraApplied ||
        request.focusTarget.mapId != map.id ||
        _scheduledNarrativeEventCameraRequestId == request.requestId) {
      return;
    }
    _scheduledNarrativeEventCameraRequestId = request.requestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(narrativeEventMapBridgeControllerProvider);
      final currentRequest = current.focusRequest;
      if (currentRequest == null ||
          currentRequest.requestId != request.requestId ||
          currentRequest.cameraApplied) {
        return;
      }
      final renderObject = _mapViewportKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox ||
          !renderObject.hasSize ||
          renderObject.size.isEmpty) {
        _scheduledNarrativeEventCameraRequestId = null;
        if (mounted) setState(() {});
        return;
      }
      final activeMap = ref.read(editorNotifierProvider).activeMap;
      if (activeMap == null || activeMap.id != map.id) return;
      final bounds = resolveNarrativeEventMapFocusBounds(
        focus: currentRequest.focusTarget,
        map: activeMap,
      );
      final panOffset = resolveMapFocusPanOffset(
        bounds: bounds,
        viewportSize: renderObject.size,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        zoom: zoom,
      );
      ref
          .read(editorNotifierProvider.notifier)
          .setNarrativeEventMapPanOffset(panOffset);
      ref
          .read(narrativeEventMapBridgeControllerProvider.notifier)
          .markFocusCameraApplied(request.requestId);
    });
  }

  Widget _shadowLightPreviewSelector(
    BuildContext context,
    PokeMapColorTokens colors,
    EditorShadowLightPreviewPreset selectedPreset,
  ) {
    final presets = createEditorShadowLightPreviewPresets();
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceRaised.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderSubtle, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'Aperçu lumière',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              for (final preset in presets)
                _shadowLightPreviewPresetButton(
                  preset: preset,
                  selected: preset.id == selectedPreset.id,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shadowLightPreviewPresetButton({
    required EditorShadowLightPreviewPreset preset,
    required bool selected,
  }) {
    return PokeMapButton(
      key: ValueKey('shadow-light-preview-${preset.id}-button'),
      size: PokeMapButtonSize.small,
      variant: PokeMapButtonVariant.secondary,
      isSelected: selected,
      semanticLabel: 'Aperçu lumière : ${preset.label}',
      onPressed: () {
        if (_shadowLightPreviewPresetId == preset.id) {
          return;
        }
        setState(() {
          _shadowLightPreviewPresetId = preset.id;
        });
      },
      child: Text(
        preset.label,
        style: const TextStyle(fontSize: 10, decoration: TextDecoration.none),
      ),
    );
  }

  MapCanvasInteractionSession? _activeGestureInteraction() {
    final interaction = _interactionController.activeSession;
    if (interaction == null ||
        interaction.interactionId != _activeGestureInteractionId) {
      return null;
    }
    return interaction;
  }

  bool _ensureCurrentInteractionContext(
    MapCanvasInteractionSession interaction,
  ) {
    final objectMovePreview = _objectMovePreview;
    final expectedContext =
        interaction.kind == MapCanvasInteractionKind.draggingSelection
        ? objectMovePreview?.contextAfterSelection
        : interaction.contextAtStart;
    final currentState = ref.read(editorNotifierProvider);
    final sourceIsCurrent =
        interaction.kind != MapCanvasInteractionKind.draggingSelection ||
        (objectMovePreview != null &&
            identical(currentState.activeMap, objectMovePreview.sourceMap) &&
            _isCanvasObjectTargetSelected(
              currentState,
              objectMovePreview.target,
            ));
    if (expectedContext != null &&
        expectedContext == _currentMapInteractionContext() &&
        sourceIsCurrent) {
      return true;
    }
    _cancelAndRollbackPointer(interaction.pointerId);
    return false;
  }

  bool _isCanvasObjectTargetSelected(
    EditorState state,
    MapCanvasObjectTarget target,
  ) {
    return switch (target.kind) {
      MapCanvasObjectKind.placedElement =>
        state.selectedPlacedElementInstanceId == target.id,
      MapCanvasObjectKind.entity => state.selectedEntityId == target.id,
      MapCanvasObjectKind.mapEvent => state.selectedMapEventId == target.id,
      MapCanvasObjectKind.gameplayZone =>
        state.selectedGameplayZoneId == target.id,
      MapCanvasObjectKind.trigger => state.selectedTriggerId == target.id,
      MapCanvasObjectKind.warp => state.selectedWarpId == target.id,
    };
  }

  void _updateObjectMovePreview(Offset localPosition) {
    final preview = _objectMovePreview;
    if (preview == null) return;
    final currentState = ref.read(editorNotifierProvider);
    final settings = currentState.project?.settings ?? const ProjectSettings();
    final pointerCell = _screenToUnboundedGrid(
      localPosition,
      currentState.panOffset,
      currentState.zoom,
      settings.tileWidth * settings.displayScale,
      settings.tileHeight * settings.displayScale,
    );
    final destinationAnchor = GridPos(
      x: preview.target.anchor.x + pointerCell.x - preview.grabCell.x,
      y: preview.target.anchor.y + pointerCell.y - preview.grabCell.y,
    );
    if (destinationAnchor == preview.destinationAnchor) return;
    const planner = MapCanvasObjectMovePlanner();
    final plan = planner.plan(
      map: preview.sourceMap,
      project: currentState.project,
      target: preview.target,
      destinationAnchor: destinationAnchor,
    );
    setState(() {
      _objectMovePreview = _MapCanvasObjectMovePreview(
        sourceMap: preview.sourceMap,
        target: preview.target,
        grabCell: preview.grabCell,
        destinationAnchor: destinationAnchor,
        plan: plan,
        contextAfterSelection: preview.contextAfterSelection,
      );
    });
  }

  void _cancelAndRollbackPointer(int pointerId) {
    final cancelled = _interactionController.cancelPointer(pointerId);
    if (cancelled == null) return;
    if (cancelled.session.kind == MapCanvasInteractionKind.trackpadPanZoom) {
      _clearTrackpadGesture(cancelled.session.interactionId);
    }
    _rollbackMapInteraction(cancelled.session);
    if (mounted) setState(() {});
  }

  MapCanvasInteractionContext _currentMapInteractionContext() {
    final state = ref.read(editorNotifierProvider);
    final bridge = ref.read(narrativeEventMapBridgeControllerProvider);
    final borderFeatureId = ref
        .read(activeBorderFeatureControllerProvider)
        .activeFeatureId;
    final guidedNavigation =
        bridge.pendingReturn != null &&
        (bridge.navigationMode == NarrativeEventMapNavigationMode.create ||
            bridge.navigationMode == NarrativeEventMapNavigationMode.choose);
    final targetKey = <Object?>[
      state.activeBrush,
      state.collisionBrushSizeMode,
      state.eraserFootprint,
      state.selectedEnvironmentAreaId,
      state.environmentMaskEditMode,
      borderFeatureId,
      state.npcWaypointPlacementEntityId,
    ].join('|');
    return MapCanvasInteractionContext(
      projectRootPath: state.projectRootPath,
      mapId: state.activeMap?.id,
      activeMapPath: state.activeMapPath,
      layerId: state.activeLayerId,
      toolKey: state.activeTool.name,
      targetId: targetKey,
      guidedNavigation: guidedNavigation,
    );
  }

  void _onMapPointerDown(PointerDownEvent event) {
    if ((event.buttons & kSecondaryButton) != 0) {
      _requestPointerContextMenu(event);
      return;
    }
    if (_spacePressed) _spaceKeyboardActivationPending = false;
    _mapFocusNode.requestFocus();
    final anotherPointerIsPressed = _pressedMapPointers.isNotEmpty;
    _pressedMapPointers.add(event.pointer);
    _latestMapPointerLocalPositions[event.pointer] = event.localPosition;
    if (anotherPointerIsPressed) {
      final active = _interactionController.activeSession;
      if (active != null) {
        _cancelAndRollbackPointer(active.pointerId);
      }
      return;
    }
    final started = _interactionController.beginPointer(
      MapCanvasInteractionInput(
        pointerId: event.pointer,
        pointerKind: _mapCanvasPointerKind(event.kind),
        buttons: event.buttons,
        modifiers: _currentMapInteractionModifiers(),
        context: _currentMapInteractionContext(),
      ),
    );
    if (started.session?.kind == MapCanvasInteractionKind.panning) {
      setState(() {});
    }
  }

  void _onMapPointerMove(PointerMoveEvent event) {
    _latestMapPointerLocalPositions[event.pointer] = event.localPosition;
    final interaction = _interactionController.activeSession;
    if (interaction == null ||
        interaction.kind != MapCanvasInteractionKind.panning ||
        interaction.pointerId != event.pointer) {
      return;
    }
    ref.read(editorNotifierProvider.notifier).pan(event.delta);
  }

  void _onMapPointerButtonsChanged(PointerMoveEvent event) {
    final cancelled = _interactionController.cancelPointerIfButtonsChanged(
      pointerId: event.pointer,
      buttons: event.buttons,
    );
    if (cancelled == null) return;
    _rollbackMapInteraction(cancelled.session);
    if (mounted) setState(() {});
  }

  void _onMapPointerUp(PointerUpEvent event) {
    try {
      final interaction = _interactionController.activeSession;
      if (interaction == null || interaction.pointerId != event.pointer) {
        return;
      }
      if (interaction.kind == MapCanvasInteractionKind.panning) {
        _interactionController.finishPointer(event.pointer);
        setState(() {});
        return;
      }
      if (interaction.kind != MapCanvasInteractionKind.pendingPrimary) return;
      final interactionId = interaction.interactionId;
      scheduleMicrotask(() {
        final pending = _interactionController.activeSession;
        if (pending?.interactionId != interactionId ||
            pending?.kind != MapCanvasInteractionKind.pendingPrimary) {
          return;
        }
        _interactionController.cancelPointer(event.pointer);
      });
    } finally {
      _pressedMapPointers.remove(event.pointer);
      _latestMapPointerLocalPositions.remove(event.pointer);
    }
  }

  void _onMapPointerCancel(PointerCancelEvent event) {
    try {
      final cancelled = _interactionController.cancelPointer(event.pointer);
      if (cancelled == null) return;
      _rollbackMapInteraction(cancelled.session);
      setState(() {});
    } finally {
      _pressedMapPointers.remove(event.pointer);
      _latestMapPointerLocalPositions.remove(event.pointer);
    }
  }

  void _onMapPointerPanZoomStart(PointerPanZoomStartEvent event) {
    _mapFocusNode.requestFocus();
    if (_pressedMapPointers.isNotEmpty) return;

    final started = _interactionController.beginPanZoom(
      MapCanvasInteractionInput(
        pointerId: event.pointer,
        pointerKind: _mapCanvasPointerKind(event.kind),
        buttons: event.buttons,
        modifiers: _currentMapInteractionModifiers(),
        context: _currentMapInteractionContext(),
      ),
    );
    final session = started.session;
    if (session == null) return;
    final state = ref.read(editorNotifierProvider);
    _trackpadGesture = (
      interactionId: session.interactionId,
      pointerId: event.pointer,
      viewport: MapViewport(zoom: state.zoom, panOffset: state.panOffset),
      focalPoint: event.localPosition,
    );
    setState(() {});
  }

  void _onMapPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final interaction = _interactionController.activeSession;
    final snapshot = _trackpadGesture;
    if (interaction == null ||
        interaction.kind != MapCanvasInteractionKind.trackpadPanZoom ||
        interaction.pointerId != event.pointer ||
        snapshot == null ||
        snapshot.interactionId != interaction.interactionId ||
        snapshot.pointerId != event.pointer) {
      return;
    }
    if (!_ensureCurrentInteractionContext(interaction)) {
      _clearTrackpadGesture(interaction.interactionId);
      return;
    }
    final cumulativePan = PointerEvent.transformDeltaViaPositions(
      transform: event.transform,
      untransformedDelta: event.pan,
      untransformedEndPosition: event.position,
      transformedEndPosition: event.localPosition,
    );
    final viewport = MapViewportNavigation.panZoomFromStart(
      startViewport: snapshot.viewport,
      startFocalPoint: snapshot.focalPoint,
      cumulativePan: cumulativePan,
      scale: event.scale,
    );
    ref.read(editorNotifierProvider.notifier).setMapViewport(viewport);
  }

  void _onMapPointerPanZoomEnd(PointerPanZoomEndEvent event) {
    final interaction = _interactionController.activeSession;
    final snapshot = _trackpadGesture;
    if (interaction == null ||
        interaction.kind != MapCanvasInteractionKind.trackpadPanZoom ||
        interaction.pointerId != event.pointer ||
        snapshot == null ||
        snapshot.interactionId != interaction.interactionId ||
        snapshot.pointerId != event.pointer) {
      return;
    }
    _interactionController.finishPointer(event.pointer);
    _clearTrackpadGesture(interaction.interactionId);
    if (mounted) setState(() {});
  }

  void _onMapPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!_interactionController.acceptsScroll) return;
    if (event.buttons != 0 || _pressedMapPointers.isNotEmpty) return;
    final kind = event.kind;
    if (kind != ui.PointerDeviceKind.mouse &&
        kind != ui.PointerDeviceKind.trackpad) {
      return;
    }
    if (event.scrollDelta == Offset.zero) return;
    _mapFocusNode.requestFocus();
    final state = ref.read(editorNotifierProvider);
    final current = MapViewport(zoom: state.zoom, panOffset: state.panOffset);
    final keyboard = HardwareKeyboard.instance;
    final zoomRequested = keyboard.isMetaPressed || keyboard.isControlPressed;
    if (zoomRequested) {
      if (event.scrollDelta.dy == 0) return;
      final viewport = MapViewportNavigation.zoomFromScroll(
        viewport: current,
        focalPoint: event.localPosition,
        scrollDeltaY: event.scrollDelta.dy,
      );
      ref.read(editorNotifierProvider.notifier).setMapViewport(viewport);
      return;
    }
    final viewport = MapViewportNavigation.panBy(
      viewport: current,
      delta: -event.scrollDelta,
    );
    ref.read(editorNotifierProvider.notifier).setMapViewport(viewport);
  }

  KeyEventResult _onMapKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent &&
        _pressedContextMenuKeys.remove(event.logicalKey)) {
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && _isKeyboardContextMenuEvent(event)) {
      if (!_pressedContextMenuKeys.add(event.logicalKey)) {
        return KeyEventResult.handled;
      }
      final request = _keyboardContextMenuRequest();
      if (request == null || widget.onContextMenuRequested == null) {
        _pressedContextMenuKeys.remove(event.logicalKey);
        return KeyEventResult.ignored;
      }
      widget.onContextMenuRequested!(request);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent && _isUnmodifiedActivationKey(event.logicalKey)) {
      _activateKeyboardCursor();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent) {
      final delta = _keyboardArrowDelta(event.logicalKey);
      if (delta != null &&
          !HardwareKeyboard.instance.isAltPressed &&
          !HardwareKeyboard.instance.isControlPressed &&
          !HardwareKeyboard.instance.isMetaPressed) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          _moveSelectedPlacedElementBy(delta);
        } else {
          _moveKeyboardCursorBy(delta);
        }
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      final wasPressed = _spacePressed;
      final nextPressed = event is! KeyUpEvent;
      if (event is KeyDownEvent && !wasPressed) {
        _spaceKeyboardActivationPending = true;
      }
      if (_spacePressed != nextPressed) {
        setState(() => _spacePressed = nextPressed);
      }
      if (event is KeyUpEvent) {
        final activate =
            _spaceKeyboardActivationPending &&
            _pressedMapPointers.isEmpty &&
            _interactionController.isIdle;
        _spaceKeyboardActivationPending = false;
        if (activate) _activateKeyboardCursor();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyF &&
        !HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed) {
      if (_interactionController.isIdle) {
        _fitActiveMap();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyR &&
        !HardwareKeyboard.instance.isAltPressed &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed) {
      if (!_interactionController.isIdle) {
        return KeyEventResult.handled;
      }
      final editor = ref.read(editorNotifierProvider);
      final instanceId = editor.selectedPlacedElementInstanceId?.trim() ?? '';
      if (instanceId.isEmpty) {
        return KeyEventResult.handled;
      }
      final delta = HardwareKeyboard.instance.isShiftPressed ? -1 : 1;
      ref
          .read(editorNotifierProvider.notifier)
          .rotateSelectedPlacedElement(deltaQuarterTurns: delta);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      final cancelled = _interactionController.cancelActive();
      if (cancelled != null) {
        _rollbackMapInteraction(cancelled.session);
        setState(() {});
      } else if (ref.read(editorNotifierProvider).mapStrokeStart != null) {
        ref.read(editorNotifierProvider.notifier).cancelMapStroke();
      }
      ref.read(editorNotifierProvider.notifier).cancelProjectElementPlacement();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _isUnmodifiedActivationKey(LogicalKeyboardKey key) {
    return (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        !HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed;
  }

  GridPos? _keyboardArrowDelta(LogicalKeyboardKey key) => switch (key) {
    LogicalKeyboardKey.arrowLeft => const GridPos(x: -1, y: 0),
    LogicalKeyboardKey.arrowRight => const GridPos(x: 1, y: 0),
    LogicalKeyboardKey.arrowUp => const GridPos(x: 0, y: -1),
    LogicalKeyboardKey.arrowDown => const GridPos(x: 0, y: 1),
    _ => null,
  };

  GridPos _resolveKeyboardCursor(EditorState state, MapData map) {
    final local = _keyboardCursorMapId == map.id ? _keyboardCursor : null;
    if (_isInMap(local, map.size)) return local!;
    if (_isInMap(widget.keyboardContextCell, map.size)) {
      return widget.keyboardContextCell!;
    }
    final selected = resolveSelectedCanvasObjectTarget(
      map: map,
      project: state.project,
      selectedPlacedElementInstanceId: state.selectedPlacedElementInstanceId,
      selectedEntityId: state.selectedEntityId,
      selectedMapEventId: state.selectedMapEventId,
      selectedWarpId: state.selectedWarpId,
      selectedTriggerId: state.selectedTriggerId,
      selectedGameplayZoneId: state.selectedGameplayZoneId,
      editorAnimationTimeMs: _repaintClock.elapsedMs,
    );
    if (selected != null) return selected.anchor;
    return GridPos(x: map.size.width ~/ 2, y: map.size.height ~/ 2);
  }

  void _setKeyboardCursor(MapData map, GridPos cell) {
    _keyboardCursorMapId = map.id;
    _keyboardCursor = cell;
    widget.onCellSelected?.call(cell);
    if (mounted) setState(() {});
  }

  void _moveKeyboardCursorBy(GridPos delta) {
    final state = ref.read(editorNotifierProvider);
    final map = state.activeMap;
    if (map == null) return;
    final current = _resolveKeyboardCursor(state, map);
    _setKeyboardCursor(
      map,
      GridPos(
        x: (current.x + delta.x).clamp(0, map.size.width - 1),
        y: (current.y + delta.y).clamp(0, map.size.height - 1),
      ),
    );
  }

  void _activateKeyboardCursor() {
    if (!_interactionController.isIdle) return;
    final state = ref.read(editorNotifierProvider);
    final map = state.activeMap;
    if (map == null) return;
    final cursor = _resolveKeyboardCursor(state, map);
    _setKeyboardCursor(map, cursor);
    _keyboardCellActivation?.call(cursor);
  }

  void _moveSelectedPlacedElementBy(GridPos delta) {
    if (!_interactionController.isIdle) return;
    final state = ref.read(editorNotifierProvider);
    final map = state.activeMap;
    if (map == null) return;
    final target = resolveSelectedCanvasObjectTarget(
      map: map,
      project: state.project,
      selectedPlacedElementInstanceId: state.selectedPlacedElementInstanceId,
      selectedEntityId: null,
      selectedMapEventId: null,
      selectedWarpId: null,
      selectedTriggerId: null,
      selectedGameplayZoneId: null,
      editorAnimationTimeMs: _repaintClock.elapsedMs,
    );
    if (target == null || target.kind != MapCanvasObjectKind.placedElement) {
      return;
    }
    final destination = GridPos(
      x: target.anchor.x + delta.x,
      y: target.anchor.y + delta.y,
    );
    final moved = ref
        .read(editorNotifierProvider.notifier)
        .commitCanvasObjectMove(
          sourceMap: map,
          target: target,
          destinationAnchor: destination,
        );
    if (moved) _setKeyboardCursor(map, destination);
  }

  void _requestPointerContextMenu(PointerDownEvent event) {
    _mapFocusNode.requestFocus();
    final cancelled = _interactionController.cancelActive();
    if (cancelled != null) {
      _rollbackMapInteraction(cancelled.session);
      if (mounted) {
        setState(() {});
      }
    }
    final callback = widget.onContextMenuRequested;
    if (callback == null) {
      return;
    }
    final state = ref.read(editorNotifierProvider);
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final settings = state.project?.settings ?? const ProjectSettings();
    final position = _screenToGrid(
      event.localPosition,
      state.panOffset,
      state.zoom,
      map.size,
      settings.tileWidth * settings.displayScale,
      settings.tileHeight * settings.displayScale,
    );
    if (position == null) {
      return;
    }
    widget.onCellSelected?.call(position);
    callback(
      MapCanvasContextMenuRequest(
        globalPosition: event.position,
        gridPosition: position,
        invocation: MapContextMenuInvocation.pointer,
      ),
    );
  }

  bool _isKeyboardContextMenuEvent(KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.contextMenu) {
      return true;
    }
    final keyboard = HardwareKeyboard.instance;
    return event.logicalKey == LogicalKeyboardKey.f10 &&
        keyboard.isShiftPressed &&
        !keyboard.isAltPressed &&
        !keyboard.isControlPressed &&
        !keyboard.isMetaPressed;
  }

  MapCanvasContextMenuRequest? _keyboardContextMenuRequest() {
    final callback = widget.onContextMenuRequested;
    final state = ref.read(editorNotifierProvider);
    final map = state.activeMap;
    final viewportContext = _mapViewportKey.currentContext;
    if (callback == null || map == null || viewportContext == null) {
      return null;
    }
    final renderObject = viewportContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final settings = state.project?.settings ?? const ProjectSettings();
    final tileWidth = settings.tileWidth * settings.displayScale;
    final tileHeight = settings.tileHeight * settings.displayScale;
    final selectedObject = resolveSelectedCanvasObjectTarget(
      map: map,
      project: state.project,
      selectedPlacedElementInstanceId: state.selectedPlacedElementInstanceId,
      selectedEntityId: state.selectedEntityId,
      selectedMapEventId: state.selectedMapEventId,
      selectedWarpId: state.selectedWarpId,
      selectedTriggerId: state.selectedTriggerId,
      selectedGameplayZoneId: state.selectedGameplayZoneId,
      editorAnimationTimeMs: _repaintClock.elapsedMs,
    );

    late final GridPos gridPosition;
    late final Offset preferredLocalAnchor;
    if (selectedObject != null) {
      gridPosition = selectedObject.anchor;
      preferredLocalAnchor = _gridTargetCenterInViewport(
        anchor: selectedObject.anchor,
        size: selectedObject.size,
        pan: state.panOffset,
        zoom: state.zoom,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      );
    } else if (_isInMap(widget.keyboardContextCell, map.size)) {
      gridPosition = widget.keyboardContextCell!;
      preferredLocalAnchor = _gridTargetCenterInViewport(
        anchor: gridPosition,
        size: const GridSize(width: 1, height: 1),
        pan: state.panOffset,
        zoom: state.zoom,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      );
    } else {
      final center = renderObject.size.center(Offset.zero);
      final unbounded = _screenToUnboundedGrid(
        center,
        state.panOffset,
        state.zoom,
        tileWidth,
        tileHeight,
      );
      gridPosition = GridPos(
        x: unbounded.x.clamp(0, map.size.width - 1).toInt(),
        y: unbounded.y.clamp(0, map.size.height - 1).toInt(),
      );
      preferredLocalAnchor = center;
    }

    final localAnchor = Offset(
      _clampContextAnchor(preferredLocalAnchor.dx, renderObject.size.width),
      _clampContextAnchor(preferredLocalAnchor.dy, renderObject.size.height),
    );
    return MapCanvasContextMenuRequest(
      globalPosition: renderObject.localToGlobal(localAnchor),
      gridPosition: gridPosition,
      invocation: MapContextMenuInvocation.keyboard,
    );
  }

  Offset _gridTargetCenterInViewport({
    required GridPos anchor,
    required GridSize size,
    required Offset pan,
    required double zoom,
    required double tileWidth,
    required double tileHeight,
  }) {
    return Offset(
      pan.dx + (anchor.x + size.width / 2) * tileWidth * zoom,
      pan.dy + (anchor.y + size.height / 2) * tileHeight * zoom,
    );
  }

  bool _isInMap(GridPos? position, GridSize size) {
    return position != null &&
        position.x >= 0 &&
        position.y >= 0 &&
        position.x < size.width &&
        position.y < size.height;
  }

  double _clampContextAnchor(double value, double extent) {
    if (extent <= 0) {
      return 0;
    }
    final inset = math.min(8.0, extent / 2);
    return value.clamp(inset, extent - inset).toDouble();
  }

  void _onMapFocusChanged(bool hasFocus) {
    if (hasFocus) {
      if (mounted) setState(() {});
      return;
    }
    final cancelled = _interactionController.cancelActive();
    final needsRebuild = _spacePressed || cancelled != null;
    _spacePressed = false;
    _spaceKeyboardActivationPending = false;
    _pressedMapPointers.clear();
    _pressedContextMenuKeys.clear();
    _latestMapPointerLocalPositions.clear();
    _clearTrackpadGesture();
    if (cancelled != null) {
      _rollbackMapInteraction(cancelled.session);
    }
    if (needsRebuild && mounted) {
      setState(() {});
    }
  }

  void _zoomOut() => _zoomActiveMap(1 / 1.2);

  void _zoomIn() => _zoomActiveMap(1.2);

  void _zoomActiveMap(double factor) {
    final geometry = _readActiveMapViewportGeometry();
    if (geometry == null || !_interactionController.isIdle) return;
    final viewport = MapViewportNavigation.zoomAt(
      viewport: geometry.viewport,
      focalPoint: geometry.viewportSize.center(Offset.zero),
      targetZoom: geometry.viewport.zoom * factor,
    );
    ref.read(editorNotifierProvider.notifier).setMapViewport(viewport);
    _focusMapUnlessNavigationControlsHaveFocus();
  }

  void _fitActiveMap() {
    final geometry = _readActiveMapViewportGeometry();
    if (geometry == null || !_interactionController.isIdle) return;
    final editorState = ref.read(editorNotifierProvider);
    final inspectorKind = ref.read(worldMapInspectorSnapshotProvider).kind;
    final connectionContext = inspectorKind == WorldMapInspectorKind.connections
        ? _readLoadedConnectionContext(editorState)
        : null;
    final viewport = connectionContext == null
        ? MapViewportNavigation.fitMap(
            mapPixelSize: geometry.mapPixelSize,
            viewportSize: geometry.viewportSize,
          )
        : MapViewportNavigation.fitBounds(
            contentBounds: connectionContext.contentTileBounds,
            viewportSize: geometry.viewportSize,
            tileSize: geometry.tileSize,
          );
    ref.read(editorNotifierProvider.notifier).setMapViewport(viewport);
    _focusMapUnlessNavigationControlsHaveFocus();
  }

  void _showActiveMapAtActualSize() {
    final geometry = _readActiveMapViewportGeometry();
    if (geometry == null || !_interactionController.isIdle) return;
    final viewport = MapViewportNavigation.actualSize(
      viewport: geometry.viewport,
      viewportSize: geometry.viewportSize,
    );
    ref.read(editorNotifierProvider.notifier).setMapViewport(viewport);
    _focusMapUnlessNavigationControlsHaveFocus();
  }

  void _centerActiveMap() {
    final geometry = _readActiveMapViewportGeometry();
    if (geometry == null || !_interactionController.isIdle) return;
    final viewport = MapViewportNavigation.centerMap(
      mapPixelSize: geometry.mapPixelSize,
      viewportSize: geometry.viewportSize,
      zoom: geometry.viewport.zoom,
    );
    ref.read(editorNotifierProvider.notifier).setMapViewport(viewport);
    _focusMapUnlessNavigationControlsHaveFocus();
  }

  void _focusMapUnlessNavigationControlsHaveFocus() {
    if (!_mapNavigationControlsFocusNode.hasFocus) {
      _mapFocusNode.requestFocus();
    }
  }

  ({Size mapPixelSize, Size tileSize, Size viewportSize, MapViewport viewport})?
  _readActiveMapViewportGeometry() {
    final state = ref.read(editorNotifierProvider);
    final map = state.activeMap;
    if (map == null) return null;
    final renderObject = _mapViewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.hasSize ||
        renderObject.size.isEmpty) {
      return null;
    }
    final settings = state.project?.settings ?? const ProjectSettings();
    final tileWidth = settings.tileWidth * settings.displayScale;
    final tileHeight = settings.tileHeight * settings.displayScale;
    final mapPixelSize = Size(
      map.size.width * tileWidth,
      map.size.height * tileHeight,
    );
    if (mapPixelSize.width <= 0 || mapPixelSize.height <= 0) return null;
    return (
      mapPixelSize: mapPixelSize,
      tileSize: Size(tileWidth, tileHeight),
      viewportSize: renderObject.size,
      viewport: MapViewport(zoom: state.zoom, panOffset: state.panOffset),
    );
  }

  WorldMapConnectionContext? _readLoadedConnectionContext(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    final project = state.project;
    final activeMap = state.activeMap;
    if (projectRootPath == null ||
        projectRootPath.isEmpty ||
        project == null ||
        activeMap == null) {
      return null;
    }
    return ref
        .read(
          worldMapConnectionContextProvider(
            WorldMapConnectionContextRequest(
              projectRootPath: projectRootPath,
              project: project,
              sourceMap: activeMap,
            ),
          ),
        )
        .value;
  }

  void _clearTrackpadGesture([int? interactionId]) {
    if (interactionId != null &&
        _trackpadGesture?.interactionId != interactionId) {
      return;
    }
    _trackpadGesture = null;
  }

  void _scheduleDetachedInteractionRollback(
    MapCanvasInteractionSession interaction,
  ) {
    if (_activeGestureInteractionId == interaction.interactionId) {
      _activeGestureInteractionId = null;
    }
    _lastEnvironmentMaskPaintCell = null;
    _smartTileShapeStart = null;
    _smartTileShapeEnd = null;
    _lastBorderPaintCell = null;
    _borderStrokeEditingDraft = null;
    _borderStrokeGestureRejected = false;
    VoidCallback? rollback;
    switch (interaction.kind) {
      case MapCanvasInteractionKind.paintingStroke:
        final notifier = ref.read(editorNotifierProvider.notifier);
        rollback = notifier.cancelMapStroke;
      case MapCanvasInteractionKind.drawingZone:
        _zoneDragStart = null;
        final notifier = ref.read(editorNotifierProvider.notifier);
        rollback = notifier.cancelGameplayZoneDraft;
      case MapCanvasInteractionKind.borderGesture:
        final controller = ref.read(borderPreviewControllerProvider.notifier);
        rollback = controller.rollbackDrawingGesture;
      case MapCanvasInteractionKind.draggingSelection:
        _objectMovePreview = null;
      case MapCanvasInteractionKind.pendingPrimary:
      case MapCanvasInteractionKind.panning:
        break;
      case MapCanvasInteractionKind.trackpadPanZoom:
        _clearTrackpadGesture(interaction.interactionId);
        break;
    }
    if (rollback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rollback?.call();
    });
  }

  void _scheduleMapInteractionRollback(
    MapCanvasInteractionSession interaction,
  ) {
    if (_scheduledRollbackInteractionId == interaction.interactionId) return;
    _scheduledRollbackInteractionId = interaction.interactionId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _scheduledRollbackInteractionId != interaction.interactionId) {
        return;
      }
      _scheduledRollbackInteractionId = null;
      _rollbackMapInteraction(interaction);
    });
  }

  void _scheduleOrphanedMapStrokeRollback() {
    if (_scheduledRollbackInteractionId == 0) return;
    _scheduledRollbackInteractionId = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledRollbackInteractionId != 0) return;
      _scheduledRollbackInteractionId = null;
      _activeGestureInteractionId = null;
      if (ref.read(editorNotifierProvider).mapStrokeStart != null) {
        ref.read(editorNotifierProvider.notifier).cancelMapStroke();
      }
    });
  }

  void _rollbackMapInteraction(MapCanvasInteractionSession session) {
    if (_activeGestureInteractionId == session.interactionId) {
      _activeGestureInteractionId = null;
    }
    if (_scheduledRollbackInteractionId == session.interactionId) {
      _scheduledRollbackInteractionId = null;
    }
    _lastEnvironmentMaskPaintCell = null;
    _smartTileShapeStart = null;
    _smartTileShapeEnd = null;
    _lastBorderPaintCell = null;
    _borderStrokeEditingDraft = null;
    _borderStrokeGestureRejected = false;
    final notifier = ref.read(editorNotifierProvider.notifier);
    switch (session.kind) {
      case MapCanvasInteractionKind.paintingStroke:
        notifier.cancelMapStroke();
      case MapCanvasInteractionKind.drawingZone:
        _zoneDragStart = null;
        notifier.cancelGameplayZoneDraft();
      case MapCanvasInteractionKind.borderGesture:
        ref
            .read(borderPreviewControllerProvider.notifier)
            .rollbackDrawingGesture();
      case MapCanvasInteractionKind.draggingSelection:
        _objectMovePreview = null;
      case MapCanvasInteractionKind.pendingPrimary:
      case MapCanvasInteractionKind.panning:
        break;
      case MapCanvasInteractionKind.trackpadPanZoom:
        _clearTrackpadGesture(session.interactionId);
        break;
    }
  }

  MapCanvasInteractionModifiers _currentMapInteractionModifiers() {
    final keyboard = HardwareKeyboard.instance;
    return MapCanvasInteractionModifiers(
      shift: keyboard.isShiftPressed,
      alt: keyboard.isAltPressed,
      control: keyboard.isControlPressed,
      meta: keyboard.isMetaPressed,
      space:
          _spacePressed ||
          keyboard.logicalKeysPressed.contains(LogicalKeyboardKey.space),
    );
  }

  MapCanvasPointerKind _mapCanvasPointerKind(ui.PointerDeviceKind kind) {
    return switch (kind) {
      ui.PointerDeviceKind.mouse => MapCanvasPointerKind.mouse,
      ui.PointerDeviceKind.trackpad => MapCanvasPointerKind.trackpad,
      ui.PointerDeviceKind.touch => MapCanvasPointerKind.touch,
      ui.PointerDeviceKind.stylus => MapCanvasPointerKind.stylus,
      ui.PointerDeviceKind.invertedStylus =>
        MapCanvasPointerKind.invertedStylus,
      ui.PointerDeviceKind.unknown => MapCanvasPointerKind.unknown,
    };
  }

  void _onMapPointerHover(Offset localPosition) {
    final s = ref.read(editorNotifierProvider);
    final map = s.activeMap;
    final settings = s.project?.settings ?? const ProjectSettings();
    if (map == null) return;
    final tileW = settings.tileWidth * settings.displayScale;
    final tileH = settings.tileHeight * settings.displayScale;
    final gridPos = _screenToGrid(
      localPosition,
      s.panOffset,
      s.zoom,
      map.size,
      tileW,
      tileH,
    );
    final activeBorderSelection = ref.read(
      activeBorderFeatureControllerProvider,
    );
    BorderFeature? activeBorderFeature;
    if (s.activeTool == EditorToolType.borderPaint ||
        s.activeTool == EditorToolType.borderErase) {
      for (final layer in map.layers.whereType<BorderLayer>()) {
        if (layer.id != s.activeLayerId) continue;
        activeBorderFeature = layer.content.featureById(
          activeBorderSelection.activeFeatureId ?? '',
        );
        break;
      }
    }
    final borderVertex = switch (activeBorderFeature?.geometry) {
      BorderStrokeGeometry(alignment: BorderStrokeAlignment.gridEdges) =>
        snapBorderGridVertex(
          localPosition: localPosition,
          pan: s.panOffset,
          zoom: s.zoom,
          mapSize: map.size,
          tileWidth: tileW,
          tileHeight: tileH,
        ),
      _ => null,
    };
    if (_hoveredTile != gridPos || _hoveredBorderVertex != borderVertex) {
      setState(() {
        _hoveredTile = gridPos;
        _hoveredBorderVertex = borderVertex;
      });
    }
  }

  Map<String, TilesetTransparentColor> _collectTilesetTransparentColors(
    ProjectManifest? project,
  ) {
    if (project == null) {
      return const {};
    }
    return <String, TilesetTransparentColor>{
      for (final tileset in project.tilesets)
        if (tileset.transparentColor != null)
          tileset.id: tileset.transparentColor!,
      for (final snapshot in project.borderCatalog.visualSnapshots)
        for (var index = 0; index < snapshot.frames.length; index += 1)
          if (snapshot.frames[index].transparentColorArgb != null)
            editorBorderFrameImageKey(
              snapshot.id,
              index,
            ): TilesetTransparentColor(
              red: (snapshot.frames[index].transparentColorArgb! >> 16) & 0xff,
              green: (snapshot.frames[index].transparentColorArgb! >> 8) & 0xff,
              blue: snapshot.frames[index].transparentColorArgb! & 0xff,
            ),
    };
  }

  bool _hasAnimatedCanvasContent({
    required MapData map,
    required ProjectManifest? project,
    required BorderPreviewTransaction? borderPreview,
  }) => editorCanvasNeedsAnimation(
    map: map,
    project: project,
    borderPreview: borderPreview,
  );

  /// Construit un [MapRect] à partir de deux coins opposés (inclusif des deux).
  MapRect _rectFromCorners(GridPos a, GridPos b) {
    final x = math.min(a.x, b.x);
    final y = math.min(a.y, b.y);
    final w = (a.x - b.x).abs() + 1;
    final h = (a.y - b.y).abs() + 1;
    return MapRect(
      pos: GridPos(x: x, y: y),
      size: GridSize(width: w, height: h),
    );
  }

  GridPos? _screenToGrid(
    Offset screenPos,
    Offset pan,
    double zoom,
    GridSize size,
    double tileWidth,
    double tileHeight,
  ) {
    final gridPos = _screenToUnboundedGrid(
      screenPos,
      pan,
      zoom,
      tileWidth,
      tileHeight,
    );
    if (gridPos.x >= 0 &&
        gridPos.x < size.width &&
        gridPos.y >= 0 &&
        gridPos.y < size.height) {
      return gridPos;
    }
    return null;
  }

  GridPos _screenToUnboundedGrid(
    Offset screenPos,
    Offset pan,
    double zoom,
    double tileWidth,
    double tileHeight,
  ) {
    final adjustedX = (screenPos.dx - pan.dx) / zoom;
    final adjustedY = (screenPos.dy - pan.dy) / zoom;

    return GridPos(
      x: (adjustedX / tileWidth).floor(),
      y: (adjustedY / tileHeight).floor(),
    );
  }
}

final class _MapCanvasObjectMovePreviewPainter extends CustomPainter {
  const _MapCanvasObjectMovePreviewPainter({
    required this.target,
    required this.pan,
    required this.zoom,
    required this.tileWidth,
    required this.tileHeight,
    required this.fillColor,
    required this.strokeColor,
  });

  final MapCanvasObjectTarget target;
  final Offset pan;
  final double zoom;
  final double tileWidth;
  final double tileHeight;
  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      pan.dx + target.anchor.x * tileWidth * zoom,
      pan.dy + target.anchor.y * tileHeight * zoom,
      target.size.width * tileWidth * zoom,
      target.size.height * tileHeight * zoom,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect.deflate(1),
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_MapCanvasObjectMovePreviewPainter oldDelegate) =>
      target.kind != oldDelegate.target.kind ||
      target.id != oldDelegate.target.id ||
      target.anchor != oldDelegate.target.anchor ||
      target.size != oldDelegate.target.size ||
      pan != oldDelegate.pan ||
      zoom != oldDelegate.zoom ||
      tileWidth != oldDelegate.tileWidth ||
      tileHeight != oldDelegate.tileHeight ||
      fillColor != oldDelegate.fillColor ||
      strokeColor != oldDelegate.strokeColor;
}

final class _BorderGridEdgeGuidePainter extends CustomPainter {
  const _BorderGridEdgeGuidePainter({
    required this.vertex,
    required this.mapSize,
    required this.pan,
    required this.zoom,
    required this.tileWidth,
    required this.tileHeight,
    required this.color,
  });

  final GridPos vertex;
  final GridSize mapSize;
  final Offset pan;
  final double zoom;
  final double tileWidth;
  final double tileHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      pan.dx + vertex.x * tileWidth * zoom,
      pan.dy + vertex.y * tileHeight * zoom,
    );
    final edgePaint = Paint()
      ..color = color.withValues(alpha: 0.76)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final horizontalStep = tileWidth * zoom;
    final verticalStep = tileHeight * zoom;
    if (vertex.x > 0) {
      canvas.drawLine(center, center - Offset(horizontalStep, 0), edgePaint);
    }
    if (vertex.x < mapSize.width) {
      canvas.drawLine(center, center + Offset(horizontalStep, 0), edgePaint);
    }
    if (vertex.y > 0) {
      canvas.drawLine(center, center - Offset(0, verticalStep), edgePaint);
    }
    if (vertex.y < mapSize.height) {
      canvas.drawLine(center, center + Offset(0, verticalStep), edgePaint);
    }
    canvas.drawCircle(
      center,
      4,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_BorderGridEdgeGuidePainter oldDelegate) =>
      vertex != oldDelegate.vertex ||
      mapSize != oldDelegate.mapSize ||
      pan != oldDelegate.pan ||
      zoom != oldDelegate.zoom ||
      tileWidth != oldDelegate.tileWidth ||
      tileHeight != oldDelegate.tileHeight ||
      color != oldDelegate.color;
}
