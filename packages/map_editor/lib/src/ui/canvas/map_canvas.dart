import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'
    show
        PointerScrollEvent,
        PointerSignalEvent,
        kSecondaryButton,
        kTertiaryButton;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/map_tool_preview.dart';
import '../../application/models/path_autotile_set.dart';
import '../../application/models/narrative_event_map_bridge_models.dart';
import '../../application/models/narrative_event_spatial_source_creation_models.dart';
import '../../application/shadow/editor_projected_building_shadow_preview.dart';
import '../../application/shadow/editor_shadow_light_preview.dart';
import '../../application/shadow/editor_static_shadow_preview.dart';
import '../../application/services/environment_generated_placement_hover_resolver.dart';
import '../../application/services/environment_mask_brush_footprint_resolver.dart';
import '../../application/services/environment_mask_paint_target_resolver.dart';
import '../../application/services/map_focus_viewport_resolver.dart';
import '../../application/services/tileset_transparent_color_processor.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/state/environment_generated_placement_add_element_provider.dart';
import '../../features/editor/state/environment_mask_brush_size_provider.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../features/border_map_editing/application/border_feature_hit_test.dart';
import '../../features/border_map_editing/application/border_region_editing.dart';
import '../../features/border_map_editing/application/border_tool_availability.dart';
import '../../features/border_map_editing/application/border_preview_transaction.dart';
import '../../features/border_map_editing/presentation/border_diagnostic_presentation.dart';
import '../../features/border_map_editing/presentation/editor_map_layer_paint_order.dart';
import '../../features/border_map_editing/presentation/border_preview_painter.dart';
import '../../features/border_map_editing/state/border_map_editing_providers.dart';
import '../../features/border_map_editing/state/border_preview_providers.dart';
import '../../features/path_pattern/path_pattern_editor_render_resolution.dart';
import '../../features/surface_painter/surface_layer_static_preview.dart';
import '../../features/surface_painter/surface_tile_preview_resolver.dart';
import 'entity_editor_element_visual.dart';
import 'map_canvas/narrative_event_map_banner.dart';
import 'narrative_studio/narrative_studio_navigation.dart';
import 'shadow/editor_static_shadow_preview_painter.dart';
import '../shared/map_workspace_empty_state.dart';
import '../../theme/theme.dart';

// Le shell du canvas garde uniquement le widget, l'interaction et la
// synchronisation des ressources. Le painter et le cache d'images vivent dans
// des part files dédiés pour rendre cette surface re-reviewable.
part 'map_canvas/map_canvas_assets.dart';
part 'map_canvas/map_grid_painter.dart';

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
    if (_mapRectContains(
      MapRect(pos: entity.pos, size: entity.size),
      pos,
    )) {
      matches.add(
        NarrativeEventSourceRef.entityInteract(map.id, entity.id),
      );
    }
  }
  for (final trigger in map.triggers) {
    if (trigger.type != TriggerType.event &&
        trigger.type != TriggerType.custom) {
      continue;
    }
    if (_mapRectContains(trigger.area, pos)) {
      matches.add(
        NarrativeEventSourceRef.triggerEnter(map.id, trigger.id),
      );
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
  });

  /// Scoped Event Builder bridge: when supplied, a primary map tap selects a
  /// position for the Event Builder instead of applying the global map tool.
  final ValueChanged<GridPos>? onEventBuilderPositionChosen;

  @override
  ConsumerState<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends ConsumerState<MapCanvas> {
  final GlobalKey _mapViewportKey = GlobalKey();
  String? _scheduledNarrativeEventCameraRequestId;
  Map<String, String> _lastTilesetPathsById = const {};
  Map<String, TilesetTransparentColor> _lastTilesetTransparentColorById =
      const {};
  Future<Map<String, ui.Image?>>? _tilesetImagesFuture;
  GridPos? _hoveredTile;

  /// Clic droit + glisser (souris Apple / macOS) ou clic molette + glisser : panoramique.
  int? _rightPanPointerId;
  int? _middlePanPointerId;

  /// Cellule de départ pour le tracé d'une zone par clic+glisser.
  GridPos? _zoneDragStart;

  /// Lot Environment-22 : évite de repeindre la même cellule masque pendant un drag.
  GridPos? _lastEnvironmentMaskPaintCell;

  /// Dedicated Border drag de-duplication; never enters map/collision strokes.
  GridPos? _lastBorderPaintCell;

  Timer? _entityEditorAnimTimer;
  bool _entityEditorAnimTimerRunning = false;
  int _editorEntityAnimationMs = 0;
  String _shadowLightPreviewPresetId = 'neutral';

  void _syncEditorEntityAnimationTimer(bool needsAnimation) {
    if (needsAnimation == _entityEditorAnimTimerRunning) {
      return;
    }
    _entityEditorAnimTimerRunning = needsAnimation;
    if (needsAnimation) {
      _entityEditorAnimTimer?.cancel();
      _entityEditorAnimTimer =
          Timer.periodic(const Duration(milliseconds: 110), (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _editorEntityAnimationMs += 110;
          if (_editorEntityAnimationMs > 2000000000) {
            _editorEntityAnimationMs = 0;
          }
        });
      });
    } else {
      _entityEditorAnimTimer?.cancel();
      _entityEditorAnimTimer = null;
    }
  }

  @override
  void dispose() {
    _entityEditorAnimTimer?.cancel();
    super.dispose();
  }

  void _updateTilesetImagesFuture(
    Map<String, String> nextTilesetPathsById,
    Map<String, TilesetTransparentColor> nextTransparentColorByTilesetId,
  ) {
    if (_tilesetImagesFuture != null &&
        mapEquals(_lastTilesetPathsById, nextTilesetPathsById) &&
        mapEquals(
          _lastTilesetTransparentColorById,
          nextTransparentColorByTilesetId,
        )) {
      return;
    }
    _lastTilesetPathsById = Map<String, String>.from(nextTilesetPathsById);
    _lastTilesetTransparentColorById =
        Map<String, TilesetTransparentColor>.from(
      nextTransparentColorByTilesetId,
    );
    _tilesetImagesFuture = _TilesetImageCache.loadMany(
      _lastTilesetPathsById,
      transparentColorByTilesetId: _lastTilesetTransparentColorById,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final state = ref.watch(editorNotifierProvider);
    final bridgeState = ref.watch(narrativeEventMapBridgeControllerProvider);
    final narrativeNavigation =
        ref.watch(narrativeStudioNavigationControllerProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final environmentMaskBrushSize =
        ref.watch(environmentMaskBrushSizeProvider);
    final selectedGeneratedPlacementElementId =
        ref.watch(environmentGeneratedPlacementAddElementProvider);
    final activeBorderFeature =
        ref.watch(activeBorderFeatureControllerProvider);
    final borderPreviewState = ref.watch(borderPreviewControllerProvider);
    final borderPreviewController =
        ref.read(borderPreviewControllerProvider.notifier);
    final activeMap = state.activeMap;
    final settings = state.project?.settings ?? const ProjectSettings();
    final connectionLabelsByDirection =
        _resolveConnectionLabels(activeMap, state.project);
    final selectedPathAutotileSet = notifier.getSelectedPathAutotileSet();
    final pathAutotileSetsByPresetId = notifier.getPathAutotileSetsByPresetId();
    final terrainPresetsByType = notifier.getTerrainPresetByType();
    final tilesetPathsById = _collectLayerTilesetPaths(
      activeMap,
      notifier,
      project: state.project,
      selectedPathAutotileSet: selectedPathAutotileSet,
      pathAutotileSetsByPresetId: pathAutotileSetsByPresetId,
      terrainPresetsByType: terrainPresetsByType,
      projectRootPath: state.projectRootPath,
      borderPreview: borderPreviewState.transaction,
    );
    final transparentColorByTilesetId = _collectTilesetTransparentColors(
      state.project,
    );
    _updateTilesetImagesFuture(
      tilesetPathsById,
      transparentColorByTilesetId,
    );

    if (activeMap == null) {
      _rightPanPointerId = null;
      _middlePanPointerId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncEditorEntityAnimationTimer(false);
        }
      });
      return const MapWorkspaceEmptyState();
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

    return FutureBuilder<Map<String, ui.Image?>>(
      future: _tilesetImagesFuture,
      builder: (context, snapshot) {
        final tilesetImagesById = snapshot.data ?? const <String, ui.Image?>{};
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
        final needsEntityAnim = mapEntitiesNeedEditorFrameAnimation(
          activeMap,
          state.project,
        );
        final needsSurfaceAnim = _surfacePresetsNeedEditorFrameAnimation(
          map: activeMap,
          project: state.project,
          pathAutotileSetsByPresetId: pathAutotileSetsByPresetId,
          terrainPresetsByType: terrainPresetsByType,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _syncEditorEntityAnimationTimer(needsEntityAnim || needsSurfaceAnim);
        });

        final toolPreview = notifier.resolveMapToolPreview(
          hoveredTile: _hoveredTile,
          tilesetColumnsById: tilesPerRowById,
        );
        final shadowLightPreviewPreset =
            editorShadowLightPreviewPresetById(_shadowLightPreviewPresetId) ??
                neutralEditorShadowLightPreviewPreset;
        final hoveredTile = _hoveredTile;
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
        final isEnvironmentMaskEditing =
            _isEnvironmentMaskEditing(state, activeMap);
        final borderToolAvailability = assessBorderToolAvailability(
          manifest: state.project,
          map: activeMap,
          activeLayerId: state.activeLayerId,
          activeFeatureId: activeBorderFeature.activeFeatureId,
        );
        final isBorderRegionEditing = borderToolAvailability.isEnabled &&
            (state.activeTool == EditorToolType.borderPaint ||
                state.activeTool == EditorToolType.borderErase) &&
            (borderPreviewState.phase == BorderPreviewPhase.idle ||
                borderPreviewState.phase == BorderPreviewPhase.drawing);
        final isLegacyStrokeEditingTool =
            state.activeTool == EditorToolType.tilePaint ||
                state.activeTool == EditorToolType.terrainPaint ||
                state.activeTool == EditorToolType.surfacePaint ||
                state.activeTool == EditorToolType.collisionPaint ||
                state.activeTool == EditorToolType.eraser ||
                isEnvironmentMaskEditing;
        final isStrokeEditingTool =
            isLegacyStrokeEditingTool || isBorderRegionEditing;
        final isNpcWaypointPlacementActive =
            (state.npcWaypointPlacementEntityId?.trim().isNotEmpty ?? false);
        final isTapEditingTool = isStrokeEditingTool ||
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

        void previewBorderGeometry(BorderRegionGeometry geometry) {
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
          if (isBorderRegionEditing) {
            if (borderPreviewController.current.phase ==
                BorderPreviewPhase.idle) {
              final previewContext =
                  _borderPreviewContextForCanvas(state, activeMap);
              if (previewContext == null) return;
              borderPreviewController.begin(
                map: activeMap,
                layerId: state.activeLayerId!,
                featureId: activeBorderFeature.activeFeatureId!,
                context: previewContext,
              );
            }
            final transaction = borderPreviewController.current.transaction;
            final geometry = transaction?.proposedFeature.geometry;
            if (borderPreviewController.current.phase !=
                    BorderPreviewPhase.drawing ||
                geometry is! BorderRegionGeometry) {
              return;
            }
            final previousCell =
                partOfStroke ? _lastBorderPaintCell ?? gridPos : gridPos;
            final updated = editBorderRegionSegment(
              geometry,
              previousCell,
              gridPos,
              filled: state.activeTool == EditorToolType.borderPaint,
            );
            previewBorderGeometry(updated);
            return;
          }
          if (isEnvironmentMaskEditing) {
            notifier.paintEnvironmentAreaMaskAt(
              gridPos,
              partOfStroke: partOfStroke,
            );
            return;
          }
          if (state.activeTool == EditorToolType.tilePaint) {
            notifier.paintSelectedBrushAt(
              gridPos,
              tilesetColumnsById: tilesPerRowById,
            );
            return;
          }
          if (state.activeTool == EditorToolType.terrainPaint) {
            notifier.paintTerrainAt(gridPos);
            return;
          }
          if (state.activeTool == EditorToolType.surfacePaint) {
            notifier.paintSurfaceAt(gridPos);
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
          if (!isBorderRegionEditing ||
              borderPreviewController.current.phase !=
                  BorderPreviewPhase.drawing) {
            return;
          }
          final transaction = borderPreviewController.current.transaction!;
          if (transaction.result == null) {
            final geometry = transaction.proposedFeature.geometry;
            if (geometry is BorderRegionGeometry) {
              previewBorderGeometry(geometry);
            }
          }
          borderPreviewController.finishDrawing();
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onMapPointerDown,
          onPointerMove: _onMapPointerMove,
          onPointerUp: _onMapPointerUp,
          onPointerCancel: _onMapPointerCancel,
          onPointerSignal: _onMapPointerSignal,
          onPointerHover: (event) => _onMapPointerHover(event.localPosition),
          child: GestureDetector(
            onTapUp: (details) {
              final gridPos = _screenToGrid(
                details.localPosition,
                state.panOffset,
                state.zoom,
                activeMap.size,
                tileWidth,
                tileHeight,
              );
              if (gridPos == null) return;

              if (bridgeState.pendingReturn != null &&
                  bridgeState.navigationMode ==
                      NarrativeEventMapNavigationMode.create) {
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
                eventBuilderPositionChosen(gridPos);
                return;
              }

              if (bridgeState.pendingReturn != null &&
                  bridgeState.navigationMode ==
                      NarrativeEventMapNavigationMode.choose) {
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

              if (state.activeTool == EditorToolType.selection) {
                MapLayer? activeLayer;
                for (final layer in activeMap.layers) {
                  if (layer.id == state.activeLayerId) {
                    activeLayer = layer;
                    break;
                  }
                }
                if (activeLayer is BorderLayer) {
                  final hit = hitTestBorderFeature(
                    layer: activeLayer,
                    position: gridPos,
                  );
                  if (hit != null) {
                    notifier.selectBorderFeature(
                      layerId: activeLayer.id,
                      featureId: hit.id,
                    );
                  }
                }
                return;
              }

              if (!isTapEditingTool) return;
              if (isLegacyStrokeEditingTool) {
                notifier.beginMapStroke();
              }
              applyToolAt(gridPos, partOfStroke: isStrokeEditingTool);
              if (isBorderRegionEditing) {
                finishBorderPreview();
              } else if (isLegacyStrokeEditingTool) {
                notifier.endMapStroke();
              }
            },
            onPanStart: (details) {
              if (isNarrativeEventGuidedNavigation) return;
              if (state.activeTool == EditorToolType.gameplayZonePlacement) {
                final gridPos = _screenToGrid(
                  details.localPosition,
                  state.panOffset,
                  state.zoom,
                  activeMap.size,
                  tileWidth,
                  tileHeight,
                );
                if (gridPos == null) return;
                setState(() => _zoneDragStart = gridPos);
                notifier.setGameplayZoneDraftArea(
                  MapRect(
                    pos: gridPos,
                    size: const GridSize(width: 1, height: 1),
                  ),
                );
                return;
              }
              if (!isStrokeEditingTool) return;
              final gridPos = _screenToGrid(
                details.localPosition,
                state.panOffset,
                state.zoom,
                activeMap.size,
                tileWidth,
                tileHeight,
              );
              if (gridPos == null) return;
              if (isEnvironmentMaskEditing) {
                _lastEnvironmentMaskPaintCell = null;
              }
              if (isBorderRegionEditing) {
                _lastBorderPaintCell = null;
              } else {
                notifier.beginMapStroke();
              }
              applyToolAt(gridPos, partOfStroke: true);
              if (isEnvironmentMaskEditing) {
                _lastEnvironmentMaskPaintCell = gridPos;
              }
              if (isBorderRegionEditing) {
                _lastBorderPaintCell = gridPos;
              }
            },
            onPanUpdate: (details) {
              if (isNarrativeEventGuidedNavigation) return;
              if (state.activeTool == EditorToolType.gameplayZonePlacement &&
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
              if (!isStrokeEditingTool) return;
              final gridPos = _screenToGrid(
                details.localPosition,
                state.panOffset,
                state.zoom,
                activeMap.size,
                tileWidth,
                tileHeight,
              );
              if (gridPos != null) {
                if (isEnvironmentMaskEditing &&
                    _lastEnvironmentMaskPaintCell == gridPos) {
                  return;
                }
                if (isBorderRegionEditing && _lastBorderPaintCell == gridPos) {
                  return;
                }
                applyToolAt(gridPos, partOfStroke: true);
                if (isEnvironmentMaskEditing) {
                  _lastEnvironmentMaskPaintCell = gridPos;
                }
                if (isBorderRegionEditing) {
                  _lastBorderPaintCell = gridPos;
                }
              }
            },
            onPanEnd: (_) {
              if (isNarrativeEventGuidedNavigation) return;
              if (state.activeTool == EditorToolType.gameplayZonePlacement &&
                  _zoneDragStart != null) {
                setState(() => _zoneDragStart = null);
                notifier.commitGameplayZoneDraft();
                return;
              }
              if (isStrokeEditingTool) {
                if (isEnvironmentMaskEditing) {
                  _lastEnvironmentMaskPaintCell = null;
                }
                if (isBorderRegionEditing) {
                  _lastBorderPaintCell = null;
                  finishBorderPreview();
                } else {
                  notifier.endMapStroke();
                }
              }
            },
            onPanCancel: () {
              if (isNarrativeEventGuidedNavigation) return;
              if (state.activeTool == EditorToolType.gameplayZonePlacement &&
                  _zoneDragStart != null) {
                setState(() => _zoneDragStart = null);
                notifier.cancelGameplayZoneDraft();
                return;
              }
              if (isStrokeEditingTool) {
                if (isEnvironmentMaskEditing) {
                  _lastEnvironmentMaskPaintCell = null;
                }
                if (isBorderRegionEditing) {
                  _lastBorderPaintCell = null;
                  borderPreviewController.cancel();
                } else {
                  notifier.endMapStroke();
                }
              }
            },
            child: MouseRegion(
              onExit: (_) {
                if (_hoveredTile != null) {
                  setState(() {
                    _hoveredTile = null;
                  });
                }
              },
              child: ClipRect(
                key: _mapViewportKey,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: MapGridPainter(
                          map: activeMap,
                          zoom: state.zoom,
                          offset: state.panOffset,
                          hoveredTile: environmentBrushCursorOverlay == null &&
                                  state.environmentMaskEditMode !=
                                      EnvironmentMaskEditMode.generatedAdd
                              ? _hoveredTile
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
                          gameplayZoneDraftArea: state.gameplayZoneDraftArea,
                          selectedEntityId: state.selectedEntityId,
                          selectedMapEventId: state.selectedMapEventId,
                          selectedWarpId: state.selectedWarpId,
                          selectedTriggerId: state.selectedTriggerId,
                          selectedGameplayZoneId: state.selectedGameplayZoneId,
                          selectedPlacedElementInstanceId:
                              state.selectedPlacedElementInstanceId,
                          narrativeEventFocusTarget:
                              bridgeState.focusRequest?.focusTarget,
                          narrativeEventSourceProposal:
                              bridgeState.sourceCreationProposal,
                          narrativeEventHighlightColor: colors.narrative,
                          connectionLabelsByDirection:
                              connectionLabelsByDirection,
                          selectedPathAutotileSet: selectedPathAutotileSet,
                          pathAutotileSetsByPresetId:
                              pathAutotileSetsByPresetId,
                          terrainPresetsByType: terrainPresetsByType,
                          project: state.project,
                          shadowLightPreviewPreset: shadowLightPreviewPreset,
                          editorEntityAnimationMs: _editorEntityAnimationMs,
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
                            warningFill:
                                colors.warningSoft.withValues(alpha: 0.72),
                            warningStroke: colors.warningBorder,
                            errorFill: colors.errorSoft.withValues(alpha: 0.72),
                            errorStroke: colors.errorBorder,
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
                    if (state.project != null)
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
              ),
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.borderSubtle,
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
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
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
            const SizedBox(width: 4),
            for (final preset in presets) ...[
              _shadowLightPreviewPresetButton(
                colors: colors,
                preset: preset,
                selected: preset.id == selectedPreset.id,
              ),
              if (preset.id != presets.last.id) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shadowLightPreviewPresetButton({
    required PokeMapColorTokens colors,
    required EditorShadowLightPreviewPreset preset,
    required bool selected,
  }) {
    return GestureDetector(
      key: ValueKey('shadow-light-preview-${preset.id}-button'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_shadowLightPreviewPresetId == preset.id) {
          return;
        }
        setState(() {
          _shadowLightPreviewPresetId = preset.id;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected ? colors.brandPrimary : colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? colors.brandPrimaryBorder : colors.borderSubtle,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            preset.label,
            style: TextStyle(
              color: selected ? colors.textInverse : colors.textSecondary,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  void _onMapPointerDown(PointerDownEvent event) {
    final kind = event.kind;
    if (kind != ui.PointerDeviceKind.mouse &&
        kind != ui.PointerDeviceKind.trackpad) {
      return;
    }
    // Molette / bouton milieu (souris classique).
    if ((event.buttons & kTertiaryButton) != 0) {
      if (_middlePanPointerId != null) return;
      _middlePanPointerId = event.pointer;
      return;
    }
    // Clic droit + glisser : panoramique (comportement attendu macOS / souris Apple).
    if ((event.buttons & kSecondaryButton) != 0) {
      if (_rightPanPointerId != null) return;
      _rightPanPointerId = event.pointer;
    }
  }

  void _onMapPointerMove(PointerMoveEvent event) {
    if (event.pointer != _middlePanPointerId &&
        event.pointer != _rightPanPointerId) {
      return;
    }
    ref.read(editorNotifierProvider.notifier).pan(event.delta);
  }

  void _onMapPointerUp(PointerUpEvent event) {
    if (event.pointer == _middlePanPointerId) {
      _middlePanPointerId = null;
    }
    if (event.pointer == _rightPanPointerId) {
      _rightPanPointerId = null;
    }
  }

  void _onMapPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _middlePanPointerId) {
      _middlePanPointerId = null;
    }
    if (event.pointer == _rightPanPointerId) {
      _rightPanPointerId = null;
    }
  }

  void _onMapPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final kind = event.kind;
    if (kind != ui.PointerDeviceKind.mouse &&
        kind != ui.PointerDeviceKind.trackpad) {
      return;
    }
    if (event.scrollDelta == Offset.zero) return;
    ref.read(editorNotifierProvider.notifier).pan(-event.scrollDelta);
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
    if (_hoveredTile != gridPos) {
      setState(() {
        _hoveredTile = gridPos;
      });
    }
  }

  Map<String, String> _collectLayerTilesetPaths(
    MapData? map,
    EditorNotifier notifier, {
    ProjectManifest? project,
    PathAutotileSet? selectedPathAutotileSet,
    required Map<String, PathAutotileSet> pathAutotileSetsByPresetId,
    required Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType,
    required String? projectRootPath,
    required BorderPreviewTransaction? borderPreview,
  }) {
    final result = <String, String>{};
    if (map != null) {
      collectTilesetIdsForEntityEditorVisuals(
        map: map,
        project: project,
        onTilesetId: (tilesetId) {
          if (result.containsKey(tilesetId)) {
            return;
          }
          final p = notifier.getTilesetAbsolutePathById(tilesetId);
          if (p != null && p.isNotEmpty) {
            result[tilesetId] = p;
          }
        },
      );
      for (final layer in map.layers) {
        if (layer is! TileLayer) continue;
        final tilesetId = layer.tilesetId?.trim();
        if (tilesetId == null || tilesetId.isEmpty) continue;
        final path = notifier.getTilesetAbsolutePathById(tilesetId);
        if (path == null || path.isEmpty) continue;
        result[tilesetId] = path;
      }
      final surfaceCatalog = project?.surfaceCatalog;
      if (surfaceCatalog != null) {
        for (final tilesetId in collectSurfaceTilePreviewTilesetIds(
          map: map,
          catalog: surfaceCatalog,
        )) {
          if (result.containsKey(tilesetId)) {
            continue;
          }
          final path = notifier.getTilesetAbsolutePathById(tilesetId);
          if (path != null && path.isNotEmpty) {
            result[tilesetId] = path;
          }
        }
      }
    }
    final brushTilesetId = notifier.getActiveBrushTilesetId();
    if (brushTilesetId != null && !result.containsKey(brushTilesetId)) {
      final brushPath = notifier.getTilesetAbsolutePathById(brushTilesetId);
      if (brushPath != null && brushPath.isNotEmpty) {
        result[brushTilesetId] = brushPath;
      }
    }
    final pathTilesetId = selectedPathAutotileSet?.tilesetId.trim();
    if (pathTilesetId != null &&
        pathTilesetId.isNotEmpty &&
        !result.containsKey(pathTilesetId)) {
      final pathTilesetPath =
          notifier.getTilesetAbsolutePathById(pathTilesetId);
      if (pathTilesetPath != null && pathTilesetPath.isNotEmpty) {
        result[pathTilesetId] = pathTilesetPath;
      }
    }
    if (selectedPathAutotileSet != null) {
      for (final frames in selectedPathAutotileSet.variants.values) {
        for (final frame in frames) {
          final frameTilesetId = frame.tilesetId.trim();
          if (frameTilesetId.isEmpty || result.containsKey(frameTilesetId)) {
            continue;
          }
          final frameTilesetPath =
              notifier.getTilesetAbsolutePathById(frameTilesetId);
          if (frameTilesetPath != null && frameTilesetPath.isNotEmpty) {
            result[frameTilesetId] = frameTilesetPath;
          }
        }
      }
    }
    for (final preset in terrainPresetsByType.values) {
      final terrainTilesetId = preset.tilesetId.trim();
      if (terrainTilesetId.isNotEmpty &&
          !result.containsKey(terrainTilesetId)) {
        final terrainTilesetPath =
            notifier.getTilesetAbsolutePathById(terrainTilesetId);
        if (terrainTilesetPath != null && terrainTilesetPath.isNotEmpty) {
          result[terrainTilesetId] = terrainTilesetPath;
        }
      }
      for (final variant in preset.variants) {
        for (final frame in variant.frames) {
          final frameTilesetId = frame.tilesetId.trim();
          if (frameTilesetId.isEmpty || result.containsKey(frameTilesetId)) {
            continue;
          }
          final frameTilesetPath =
              notifier.getTilesetAbsolutePathById(frameTilesetId);
          if (frameTilesetPath != null && frameTilesetPath.isNotEmpty) {
            result[frameTilesetId] = frameTilesetPath;
          }
        }
      }
    }
    for (final autotileSet in pathAutotileSetsByPresetId.values) {
      final tilesetId = autotileSet.tilesetId.trim();
      if (tilesetId.isNotEmpty && !result.containsKey(tilesetId)) {
        final pathTilesetPath = notifier.getTilesetAbsolutePathById(tilesetId);
        if (pathTilesetPath != null && pathTilesetPath.isNotEmpty) {
          result[tilesetId] = pathTilesetPath;
        }
      }
      for (final frames in autotileSet.variants.values) {
        for (final frame in frames) {
          final frameTilesetId = frame.tilesetId.trim();
          if (frameTilesetId.isEmpty || result.containsKey(frameTilesetId)) {
            continue;
          }
          final frameTilesetPath =
              notifier.getTilesetAbsolutePathById(frameTilesetId);
          if (frameTilesetPath != null && frameTilesetPath.isNotEmpty) {
            result[frameTilesetId] = frameTilesetPath;
          }
        }
      }
    }
    if (project != null) {
      for (final preset in project.pathPatternPresets) {
        for (final cell in preset.centerPattern.cells) {
          for (final frame in cell.frames) {
            final frameTilesetId = frame.tilesetId.trim();
            if (frameTilesetId.isEmpty || result.containsKey(frameTilesetId)) {
              continue;
            }
            final frameTilesetPath =
                notifier.getTilesetAbsolutePathById(frameTilesetId);
            if (frameTilesetPath != null && frameTilesetPath.isNotEmpty) {
              result[frameTilesetId] = frameTilesetPath;
            }
          }
        }
      }
    }
    final borderSnapshotIds = <String>{};
    if (map != null) {
      for (final layer in map.layers.whereType<BorderLayer>()) {
        for (final feature in layer.content.features) {
          final materialization = feature.materialization;
          if (materialization == null) continue;
          borderSnapshotIds.addAll(
            materialization.ground.map((cell) => cell.visualSnapshotId),
          );
          borderSnapshotIds.addAll(
            materialization.placements
                .map((placement) => placement.visualSnapshotId),
          );
        }
      }
    }
    final previewMaterialization = map == null
        ? null
        : editorBorderPreviewMaterializationForMap(
            map: map,
            preview: borderPreview,
          );
    if (previewMaterialization != null) {
      borderSnapshotIds.addAll(
        previewMaterialization.ground.map((cell) => cell.visualSnapshotId),
      );
      borderSnapshotIds.addAll(
        previewMaterialization.placements
            .map((placement) => placement.visualSnapshotId),
      );
    }
    final borderCatalog = project?.borderCatalog;
    if (borderCatalog != null) {
      for (final snapshotId in borderSnapshotIds) {
        final snapshot = borderCatalog.visualSnapshotById(snapshotId);
        if (snapshot == null) continue;
        for (var index = 0; index < snapshot.frames.length; index += 1) {
          final relativePath = snapshot.frames[index].relativeAssetPath;
          final absolutePath = p.isAbsolute(relativePath)
              ? p.normalize(relativePath)
              : projectRootPath == null || projectRootPath.trim().isEmpty
                  ? null
                  : p.normalize(p.join(projectRootPath, relativePath));
          if (absolutePath != null) {
            result[editorBorderFrameImageKey(snapshot.id, index)] =
                absolutePath;
          }
        }
      }
    }
    return result;
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
            editorBorderFrameImageKey(snapshot.id, index):
                TilesetTransparentColor(
              red: (snapshot.frames[index].transparentColorArgb! >> 16) & 0xff,
              green: (snapshot.frames[index].transparentColorArgb! >> 8) & 0xff,
              blue: snapshot.frames[index].transparentColorArgb! & 0xff,
            ),
    };
  }

  bool _surfacePresetsNeedEditorFrameAnimation({
    required MapData? map,
    required ProjectManifest? project,
    required Map<String, PathAutotileSet> pathAutotileSetsByPresetId,
    required Map<TerrainType, ProjectTerrainPreset> terrainPresetsByType,
  }) {
    final surfaceCatalog = project?.surfaceCatalog;
    if (map != null &&
        surfaceCatalog != null &&
        surfaceTilePreviewNeedsAnimation(
          map: map,
          catalog: surfaceCatalog,
        )) {
      return true;
    }
    for (final autotileSet in pathAutotileSetsByPresetId.values) {
      for (final frames in autotileSet.variants.values) {
        if (frames.length > 1) {
          return true;
        }
      }
    }
    for (final preset in terrainPresetsByType.values) {
      for (final variant in preset.variants) {
        if (variant.frames.length > 1) {
          return true;
        }
      }
    }
    if (project != null) {
      if (project.borderCatalog.visualSnapshots.any(
        (snapshot) => snapshot.frames.length > 1,
      )) {
        return true;
      }
      for (final preset in project.pathPatternPresets) {
        for (final cell in preset.centerPattern.cells) {
          if (cell.frames.length > 1) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Map<MapConnectionDirection, String> _resolveConnectionLabels(
    MapData? map,
    ProjectManifest? project,
  ) {
    final result = <MapConnectionDirection, String>{};
    if (map == null || project == null) {
      return result;
    }
    final projectMapById = <String, ProjectMapEntry>{
      for (final mapEntry in project.maps) mapEntry.id: mapEntry,
    };
    for (final connection in map.connections) {
      final mapEntry = projectMapById[connection.targetMapId];
      result[connection.direction] = mapEntry?.name ?? connection.targetMapId;
    }
    return result;
  }

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
    final adjustedX = (screenPos.dx - pan.dx) / zoom;
    final adjustedY = (screenPos.dy - pan.dy) / zoom;

    final tileX = (adjustedX / tileWidth).floor();
    final tileY = (adjustedY / tileHeight).floor();

    if (tileX >= 0 && tileX < size.width && tileY >= 0 && tileY < size.height) {
      return GridPos(x: tileX, y: tileY);
    }
    return null;
  }
}
