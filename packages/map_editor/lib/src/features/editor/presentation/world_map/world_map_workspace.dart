import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/canvas/map_canvas.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/map_canvas_object_hit_test.dart';
import '../../application/map_context_command.dart';
import '../../application/map_context_target.dart';
import '../../application/map_context_target_resolver.dart';
import '../../application/world_map_target_editor_intent.dart';
import '../../application/world_map_rejection_message.dart';
import '../../application/world_map_tool_activation.dart';
import '../../state/editor_notifier.dart';
import '../../state/editor_state.dart';
import '../../../narrative/state/narrative_event_builder_v2_providers.dart';
import 'adaptive_map_inspector.dart';
import 'map_context_menu_controller.dart';
import 'map_context_menu_host.dart';
import 'map_placed_element_rotation_preview_controller.dart';
import 'world_map_context_action_dialogs.dart';
import 'world_map_layer_mutation_dialogs.dart';
import 'world_map_layers_inspector.dart';
import 'world_map_workspace_session.dart';

typedef WorldMapExplorerBuilder = Widget Function(
  BuildContext context,
  VoidCallback onCollapse,
);

typedef WorldMapExplorerRailBuilder = Widget Function(
  BuildContext context,
  VoidCallback onReopen,
);

/// Structural, map-only workspace composition.
///
/// The shell owns transient chrome layout and the existing canvas/explorer
/// boundaries. The map inspector remains adaptive to the current session.
class WorldMapWorkspace extends ConsumerStatefulWidget {
  const WorldMapWorkspace({
    Key? key,
    required this.toolSlot,
    required this.stageHeaderSlot,
    required this.explorerBuilder,
    required this.explorerRailBuilder,
    required this.onTargetEditorRequested,
    this.onDeleteConfirmationRequested = showWorldMapContextDeleteConfirmation,
    this.onLayerRenameRequested = showWorldMapLayerRenameDialog,
    this.onLayerDeleteRequested = showWorldMapLayerDeleteDialog,
    this.onCommandRejected,
    this.inspectorFocusNode,
    this.compactInspectorReturnFocusNode,
  }) : super(
          key: key ?? const ValueKey<String>('world-map-workspace'),
        );

  static const minInspectorWidth = 280.0;
  static const maxInspectorWidth = 560.0;

  final Widget toolSlot;
  final Widget stageHeaderSlot;
  final WorldMapExplorerBuilder explorerBuilder;
  final WorldMapExplorerRailBuilder explorerRailBuilder;
  final WorldMapTargetEditorRequested onTargetEditorRequested;
  final WorldMapContextDeleteConfirmationRequested
      onDeleteConfirmationRequested;
  final WorldMapLayerRenameRequested onLayerRenameRequested;
  final WorldMapLayerDeleteRequested onLayerDeleteRequested;
  final ValueChanged<String>? onCommandRejected;
  final FocusNode? inspectorFocusNode;
  final FocusNode? compactInspectorReturnFocusNode;

  @override
  ConsumerState<WorldMapWorkspace> createState() => _WorldMapWorkspaceState();
}

class _WorldMapWorkspaceState extends ConsumerState<WorldMapWorkspace> {
  bool? _previousInspectorVisible;
  FocusNode? _compactInspectorInvokerFocusNode;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(worldMapWorkspaceSessionProvider);
    final placedElementRotationPreview =
        ref.watch(mapPlacedElementRotationPreviewProvider);
    final controller = ref.read(worldMapWorkspaceSessionProvider.notifier);
    final editorNotifier = ref.read(editorNotifierProvider.notifier);
    final menuController = ref.read(mapContextMenuControllerProvider.notifier);
    final appWindow = MediaQuery.sizeOf(context);

    void selectCell(GridPos? cell) {
      menuController.close();
      final mapId = ref.read(editorNotifierProvider).activeMap?.id;
      if (mapId == null || cell == null) {
        controller.clearSelectedCell();
        return;
      }
      controller.selectCell(mapId: mapId, cell: cell);
    }

    void openCanvasContextMenu(MapCanvasContextMenuRequest request) {
      final editor = ref.read(editorNotifierProvider);
      final map = editor.activeMap;
      if (map == null) return;
      final invokerFocusNode = FocusManager.instance.primaryFocus;
      const targetResolver = MapContextTargetResolver();
      final target = request.invocation == MapContextMenuInvocation.keyboard
          ? targetResolver.resolveSelectedObject(
                map: map,
                project: editor.project,
                editor: editor,
              ) ??
              targetResolver.resolveCanvasTarget(
                map: map,
                project: editor.project,
                position: request.gridPosition,
                activeLayerId: editor.activeLayerId,
              )
          : targetResolver.resolveCanvasTarget(
              map: map,
              project: editor.project,
              position: request.gridPosition,
              activeLayerId: editor.activeLayerId,
            );
      switch (target) {
        case MapObjectContextTarget(:final target):
          controller.clearSelectedCell();
          editorNotifier.selectCanvasObjectTarget(target);
        case MapCellContextTarget(:final position):
          editorNotifier.selectCanvasObjectTarget(null);
          controller.selectCell(mapId: map.id, cell: position);
        case MapLayerContextTarget():
          throw StateError('Canvas target resolution cannot return a layer.');
      }
      final selectedEditor = ref.read(editorNotifierProvider);
      final selectedMap = selectedEditor.activeMap;
      if (selectedMap == null || selectedMap.id != map.id) return;
      final openRequestRevision = menuController.beginOpenRequest();

      void publish(
        NarrativeEventBuilderProjectReadModel? eventBuilderReadModel,
      ) {
        menuController.open(
          target: target,
          anchor: request.globalPosition,
          invocation: request.invocation,
          map: selectedMap,
          project: selectedEditor.project,
          eventBuilderReadModel: eventBuilderReadModel,
          activeLayerId: selectedEditor.activeLayerId,
          invokerFocusNode: invokerFocusNode,
          requestRevision: openRequestRevision,
        );
      }

      final eventBuilderRequest = _eventBuilderRequestFor(
        target: target,
        editor: selectedEditor,
      );
      if (eventBuilderRequest == null) {
        publish(null);
        return;
      }
      unawaited(
        () async {
          NarrativeEventBuilderProjectReadModel? eventBuilderReadModel;
          try {
            eventBuilderReadModel = await ref.read(
              narrativeEventBuilderV2ReadModelProvider(
                eventBuilderRequest,
              ).future,
            );
          } on Object {
            eventBuilderReadModel = null;
          }
          if (!context.mounted) return;
          final currentEditor = ref.read(editorNotifierProvider);
          if (!identical(currentEditor.activeMap, selectedMap) ||
              !identical(currentEditor.project, selectedEditor.project)) {
            return;
          }
          publish(eventBuilderReadModel);
        }(),
      );
    }

    void openLayerContextMenu(WorldMapLayerContextMenuRequest request) {
      final editor = ref.read(editorNotifierProvider);
      final map = editor.activeMap;
      if (map == null) return;
      menuController.open(
        target: request.target,
        anchor: request.globalPosition,
        invocation: request.invocation,
        map: map,
        project: editor.project,
        eventBuilderReadModel: null,
        activeLayerId: editor.activeLayerId,
        invokerFocusNode: request.invokerFocusNode,
      );
    }

    void reject(String message) {
      final userMessage = projectWorldMapRejectionMessageFr(message);
      if (userMessage == null) return;
      ref
          .read(worldMapAccessibilityErrorProvider.notifier)
          .announce(userMessage);
      widget.onCommandRejected?.call(userMessage);
    }

    Future<void> deleteObject(MapObjectContextTarget contextTarget) async {
      final sourceMap = ref.read(editorNotifierProvider).activeMap;
      if (sourceMap == null ||
          !_mapContainsContextObject(sourceMap, contextTarget.target)) {
        reject('La cible n’existe plus sur la carte active.');
        return;
      }
      final copy = _objectDeleteCopy(contextTarget.target.kind);
      final confirmed = await widget.onDeleteConfirmationRequested(
        context: context,
        target: contextTarget,
        title: copy.title,
        message: copy.message,
      );
      if (!confirmed || !context.mounted) return;
      final currentMap = ref.read(editorNotifierProvider).activeMap;
      if (!identical(currentMap, sourceMap) ||
          currentMap == null ||
          !_mapContainsContextObject(currentMap, contextTarget.target)) {
        reject('Suppression annulée : la carte ou la cible a changé.');
        return;
      }
      final target = contextTarget.target;
      editorNotifier.selectCanvasObjectTarget(target);
      switch (target.kind) {
        case MapCanvasObjectKind.placedElement:
          editorNotifier.deletePlacedElementInstance(instanceId: target.id);
        case MapCanvasObjectKind.entity:
          editorNotifier.deleteSelectedEntity();
        case MapCanvasObjectKind.mapEvent:
          editorNotifier.deleteSelectedMapEvent();
        case MapCanvasObjectKind.gameplayZone:
          editorNotifier.deleteSelectedGameplayZone();
        case MapCanvasObjectKind.trigger:
          editorNotifier.deleteSelectedTrigger();
        case MapCanvasObjectKind.warp:
          editorNotifier.deleteSelectedWarp();
      }
    }

    Future<void> executeContextCommand(
      MapContextCommand command,
      MapContextMenuOpen menu,
    ) async {
      switch (command) {
        case MapContextCommand.move:
          final target = menu.target;
          if (target is! MapObjectContextTarget) return;
          editorNotifier.selectCanvasObjectTarget(target.target);
          final result = controller.activateTool(
            editorNotifier,
            const ActivateWorldMapSelection(),
          );
          if (!result.accepted) {
            reject(result.rejectionReason ?? 'Déplacement indisponible.');
          }
        case MapContextCommand.rotateClockwise:
          final target = menu.target;
          if (target is! MapObjectContextTarget) return;
          editorNotifier.selectCanvasObjectTarget(target.target);
          editorNotifier.rotateSelectedPlacedElement(deltaQuarterTurns: 1);
        case MapContextCommand.rotateCounterClockwise:
          final target = menu.target;
          if (target is! MapObjectContextTarget) return;
          editorNotifier.selectCanvasObjectTarget(target.target);
          editorNotifier.rotateSelectedPlacedElement(deltaQuarterTurns: -1);
        case MapContextCommand.rotateHalfTurn:
          final target = menu.target;
          if (target is! MapObjectContextTarget) return;
          editorNotifier.selectCanvasObjectTarget(target.target);
          editorNotifier.rotateSelectedPlacedElement(deltaQuarterTurns: 2);
        case MapContextCommand.resetRotation:
          final target = menu.target;
          if (target is! MapObjectContextTarget) return;
          editorNotifier.selectCanvasObjectTarget(target.target);
          editorNotifier.setPlacedElementInstanceQuarterTurns(
            instanceId: target.target.id,
            quarterTurns: 0,
          );
        case MapContextCommand.openTargetEditor:
          final resolution = menu.targetEditorResolution;
          if (resolution is WorldMapTargetEditorReady) {
            await widget.onTargetEditorRequested(resolution.intent);
          } else if (resolution is WorldMapTargetEditorBlocked) {
            reject(resolution.reason);
          }
        case MapContextCommand.delete:
          final target = menu.target;
          if (target is MapObjectContextTarget) await deleteObject(target);
        case MapContextCommand.eraseCell:
          final target = menu.target;
          if (target is! MapCellContextTarget || target.layerId == null) return;
          editorNotifier.eraseCellAt(
            layerId: target.layerId!,
            pos: target.position,
          );
        case MapContextCommand.activateLayer:
          final layerId = switch (menu.target) {
            MapCellContextTarget(:final layerId) => layerId,
            MapLayerContextTarget(:final layerId) => layerId,
            MapObjectContextTarget() => null,
          };
          if (layerId != null) {
            controller.setActiveLayer(editorNotifier, layerId);
          }
        case MapContextCommand.copyCoordinates:
          final target = menu.target;
          if (target is! MapCellContextTarget) return;
          await Clipboard.setData(
            ClipboardData(
              text: '${target.position.x}, ${target.position.y}',
            ),
          );
        case MapContextCommand.renameLayer:
          final target = menu.target;
          if (target is! MapLayerContextTarget) return;
          await runWorldMapLayerRenameFlow(
            context: context,
            layerId: target.layerId,
            readActiveMap: () => ref.read(editorNotifierProvider).activeMap,
            onRenameRequested: widget.onLayerRenameRequested,
            renameLayer: editorNotifier.renameMapLayer,
          );
        case MapContextCommand.moveLayerUp:
          final target = menu.target;
          if (target is MapLayerContextTarget) {
            editorNotifier.moveMapLayerGroupUp(target.layerId);
          }
        case MapContextCommand.moveLayerDown:
          final target = menu.target;
          if (target is MapLayerContextTarget) {
            editorNotifier.moveMapLayerGroupDown(target.layerId);
          }
        case MapContextCommand.deleteLayer:
          final target = menu.target;
          if (target is! MapLayerContextTarget) return;
          await runWorldMapLayerDeleteFlow(
            context: context,
            layerId: target.layerId,
            readActiveMap: () => ref.read(editorNotifierProvider).activeMap,
            onDeleteRequested: widget.onLayerDeleteRequested,
            deleteLayer: editorNotifier.deleteMapLayer,
          );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final budget = PokeMapDesktopLayout.resolve(
          Size(constraints.maxWidth, appWindow.height),
          explorerExpanded: session.explorerExpanded,
          inspectorVisible: session.inspectorVisible,
        );
        final compactExplorerOverlay =
            budget.windowClass == PokeMapDesktopWindowClass.compact &&
                session.explorerExpanded &&
                !session.inspectorVisible;
        final explorerIsExpanded =
            budget.explorerIsExpanded || compactExplorerOverlay;
        final explorerWidth = explorerIsExpanded
            ? PokeMapDesktopLayoutTokens.explorerExpandedWidth
            : PokeMapDesktopLayoutTokens.explorerRailWidth;
        final inspectorIsOverlay =
            session.inspectorVisible && budget.inspectorIsOverlay;
        final inspectorIsDocked =
            session.inspectorVisible && !budget.inspectorIsOverlay;

        double inspectorMaxWidthFor(double targetExplorerWidth) {
          return math.max(
            WorldMapWorkspace.minInspectorWidth,
            math.min(
              WorldMapWorkspace.maxInspectorWidth,
              constraints.maxWidth -
                  targetExplorerWidth -
                  PokeMapDesktopLayoutTokens.inspectorResizeHandleWidth -
                  PokeMapDesktopLayoutTokens.minCanvasWidth -
                  36,
            ),
          );
        }

        double inspectorWidthFor(double targetExplorerWidth) {
          return session.inspectorWidth
              .clamp(
                WorldMapWorkspace.minInspectorWidth,
                inspectorMaxWidthFor(targetExplorerWidth),
              )
              .toDouble();
        }

        final inspectorMaxWidth = inspectorMaxWidthFor(explorerWidth);
        final inspectorWidth = inspectorWidthFor(explorerWidth);
        if (_previousInspectorVisible == false && inspectorIsOverlay) {
          _compactInspectorInvokerFocusNode =
              FocusManager.instance.primaryFocus;
        }
        _previousInspectorVisible = session.inspectorVisible;

        void collapseExplorer() {
          controller
            ..setExplorerExpanded(false)
            ..setInspectorWidth(WorldMapWorkspace.maxInspectorWidth);
        }

        void reopenExplorer() {
          final prospectiveBudget = PokeMapDesktopLayout.resolve(
            Size(constraints.maxWidth, appWindow.height),
            explorerExpanded: true,
            inspectorVisible: session.inspectorVisible,
          );
          const prospectiveExplorerWidth =
              PokeMapDesktopLayoutTokens.explorerExpandedWidth;
          final prospectiveInspectorWidth =
              inspectorWidthFor(prospectiveExplorerWidth);
          final prospectiveCanvasWidth = constraints.maxWidth -
              prospectiveExplorerWidth -
              prospectiveBudget.resizeHandleWidth -
              prospectiveInspectorWidth -
              36;
          final inspectorCanRemainVisible =
              prospectiveBudget.explorerIsExpanded &&
                  prospectiveCanvasWidth >=
                      PokeMapDesktopLayoutTokens.minCanvasWidth;
          if (!inspectorCanRemainVisible && session.inspectorVisible) {
            controller.setInspectorVisible(false);
          }
          controller.setExplorerExpanded(true);
        }

        void resizeInspector(double delta) {
          controller.setInspectorWidth(
            (inspectorWidth - delta)
                .clamp(WorldMapWorkspace.minInspectorWidth, inspectorMaxWidth)
                .toDouble(),
          );
        }

        final explorer = FocusTraversalOrder(
          order: const NumericFocusOrder(4),
          child: _WorldMapExplorerRegion(
            width: explorerWidth,
            expanded: explorerIsExpanded,
            expandedChild: widget.explorerBuilder(context, collapseExplorer),
            reducedChild: widget.explorerRailBuilder(context, reopenExplorer),
          ),
        );
        final canvas = Expanded(
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.stageHeaderSlot,
                  const SizedBox(height: 18),
                  Expanded(
                    child: PokeMapPanel(
                      key: const ValueKey<String>('world-map-canvas-region'),
                      padding: const EdgeInsets.all(14),
                      expandChild: true,
                      borderRadius: 20,
                      child: MapCanvas(
                        placedElementRotationPreview:
                            placedElementRotationPreview,
                        keyboardContextCell: session.selectedCellMapId ==
                                ref.read(editorNotifierProvider).activeMap?.id
                            ? session.selectedCell
                            : null,
                        onCellSelected: selectCell,
                        onContextMenuRequested: openCanvasContextMenu,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        void closeInspector() {
          if (!session.inspectorVisible) return;
          final capturedFocus = _compactInspectorInvokerFocusNode;
          final fallbackFocus = capturedFocus == null
              ? widget.compactInspectorReturnFocusNode
              : null;
          _compactInspectorInvokerFocusNode = null;
          controller.setInspectorVisible(false);
          if (!inspectorIsOverlay) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final returnFocus = capturedFocus ?? fallbackFocus;
            if (returnFocus?.context != null && returnFocus!.canRequestFocus) {
              returnFocus.requestFocus();
            } else {
              FocusScope.of(context).previousFocus();
            }
          });
        }

        void closeCompactInspector() {
          if (inspectorIsOverlay) closeInspector();
        }

        void handleEscape() {
          // Stepping out of a layer sub-page is what Escape means while one is
          // open; only then does it fall through to closing and cancelling.
          if (returnWorldMapInspectorToLayers(ref)) return;
          closeCompactInspector();
          editorNotifier.cancelProjectElementPlacement();
        }

        final inspector = FocusTraversalOrder(
          order: const NumericFocusOrder(3),
          child: _WorldMapInspectorRegion(
            width: inspectorWidth,
            child: AdaptiveMapInspector(
              onLayerContextMenuRequested: openLayerContextMenu,
              onClose: closeInspector,
              focusNode: widget.inspectorFocusNode,
            ),
          ),
        );

        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): handleEscape,
          },
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: KeyedSubtree(
                    key: const ValueKey<String>('world-map-tool-slot'),
                    child: widget.toolSlot,
                  ),
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          explorer,
                          canvas,
                          if (inspectorIsDocked) ...[
                            PokeMapHorizontalResizeHandle(
                              key: const ValueKey<String>(
                                'right-inspector-resize-handle',
                              ),
                              tooltip: 'Redimensionner le panneau droit',
                              width: PokeMapDesktopLayoutTokens
                                  .inspectorResizeHandleWidth,
                              onDrag: resizeInspector,
                            ),
                            KeyedSubtree(
                              key: const ValueKey<String>(
                                'world-map-inspector-dock',
                              ),
                              child: inspector,
                            ),
                          ],
                        ],
                      ),
                      if (inspectorIsOverlay)
                        Positioned(
                          key: const ValueKey<String>(
                            'world-map-inspector-overlay',
                          ),
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: inspector,
                        ),
                      MapContextMenuHost(
                        onCommandSelected: executeContextCommand,
                        onCommandRejected: reject,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

typedef _ObjectDeleteCopy = ({String title, String message});

NarrativeEventBuilderV2SnapshotRequest? _eventBuilderRequestFor({
  required MapContextTarget target,
  required EditorState editor,
}) {
  if (target is! MapObjectContextTarget ||
      target.target.kind != MapCanvasObjectKind.mapEvent) {
    return null;
  }
  final project = editor.project;
  final mode = project?.eventRegistry?.mode ?? EventSystemMode.legacyOnly;
  final projectRootPath = editor.projectRootPath?.trim();
  if (mode == EventSystemMode.legacyOnly ||
      project == null ||
      projectRootPath == null ||
      projectRootPath.isEmpty) {
    return null;
  }
  return NarrativeEventBuilderV2SnapshotRequest.fromProject(
    projectRootPath: projectRootPath,
    project: project,
  );
}

_ObjectDeleteCopy _objectDeleteCopy(MapCanvasObjectKind kind) {
  return switch (kind) {
    MapCanvasObjectKind.placedElement => (
        title: 'Supprimer l’élément',
        message: 'Cet élément placé sera supprimé définitivement.',
      ),
    MapCanvasObjectKind.entity => (
        title: 'Supprimer l’entité',
        message: 'Cette entité sera supprimée définitivement.',
      ),
    MapCanvasObjectKind.mapEvent => (
        title: 'Supprimer l’événement',
        message: 'Cet événement de map sera supprimé définitivement.',
      ),
    MapCanvasObjectKind.gameplayZone => (
        title: 'Supprimer la zone',
        message: 'Cette zone de gameplay sera supprimée définitivement.',
      ),
    MapCanvasObjectKind.trigger => (
        title: 'Supprimer le déclencheur',
        message: 'Ce déclencheur sera supprimé définitivement.',
      ),
    MapCanvasObjectKind.warp => (
        title: 'Supprimer le téléporteur',
        message: 'Ce téléporteur sera supprimé définitivement.',
      ),
  };
}

bool _mapContainsContextObject(
  MapData map,
  MapCanvasObjectTarget target,
) {
  return switch (target.kind) {
    MapCanvasObjectKind.placedElement =>
      map.placedElements.any((entry) => entry.id == target.id),
    MapCanvasObjectKind.entity =>
      map.entities.any((entry) => entry.id == target.id),
    MapCanvasObjectKind.mapEvent =>
      map.events.any((entry) => entry.id == target.id),
    MapCanvasObjectKind.gameplayZone =>
      map.gameplayZones.any((entry) => entry.id == target.id),
    MapCanvasObjectKind.trigger =>
      map.triggers.any((entry) => entry.id == target.id),
    MapCanvasObjectKind.warp => map.warps.any((entry) => entry.id == target.id),
  };
}

class _WorldMapExplorerRegion extends StatelessWidget {
  const _WorldMapExplorerRegion({
    required this.width,
    required this.expanded,
    required this.expandedChild,
    required this.reducedChild,
  });

  final double width;
  final bool expanded;
  final Widget expandedChild;
  final Widget reducedChild;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: KeyedSubtree(
        key: const ValueKey<String>('project-explorer-region'),
        child: OverflowBox(
          minWidth: PokeMapDesktopLayoutTokens.explorerRailWidth,
          maxWidth: 520,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: PokeMapDesktopLayoutTokens.explorerExpandedWidth,
                  child: AnimatedOpacity(
                    key: const ValueKey<String>(
                      'project-explorer-expanded-state',
                    ),
                    duration: const Duration(milliseconds: 100),
                    opacity: expanded ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !expanded,
                      child: ExcludeFocus(
                        excluding: !expanded,
                        child: KeyedSubtree(
                          key: const ValueKey<String>(
                            'project-explorer-expanded',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
                            child: expandedChild,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 14,
                  child: AnimatedOpacity(
                    key: const ValueKey<String>(
                      'project-explorer-reduced-state',
                    ),
                    duration: const Duration(milliseconds: 100),
                    opacity: expanded ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: expanded,
                      child: ExcludeFocus(
                        excluding: expanded,
                        child: KeyedSubtree(
                          key: const ValueKey<String>(
                            'project-explorer-reduced',
                          ),
                          child: Center(child: reducedChild),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldMapInspectorRegion extends StatelessWidget {
  const _WorldMapInspectorRegion({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        key: const ValueKey<String>('right-inspector-region'),
        width: width,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 18, 16, 18),
          child: KeyedSubtree(
            key: const ValueKey<String>('world-map-inspector-slot'),
            child: child,
          ),
        ),
      ),
    );
  }
}
