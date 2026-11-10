import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/coordination/spatial_map_neighbor_session.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import 'map_library_navigator.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'map_workspace_compact_navigator.dart';

import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';

import 'map_workspace_palette_dock.dart';
import 'map_elements_panel.dart';
import 'map_intent_status_chip.dart';
import 'map_palette_intent.dart';
import 'map_workspace_left_column.dart';
import 'map_workspace_tool_strip.dart';
import 'map_workspace_view_state.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';

import 'map_exterior_decoration_controls.dart';
import 'map_border_tool_panel.dart';
import 'map_environment_tool_panel.dart';
import 'map_terrain_tool_panel.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'map_catalogue_workspace_actions.dart';
import 'map_lifecycle_workspace_actions.dart';

class MapWorkspaceEditorPane extends StatefulWidget {
  const MapWorkspaceEditorPane({
    super.key,
    required this.controller,
    required this.document,
    required this.project,
    required this.visuals,
    required this.view,
    required this.search,
    required this.generation,
    required this.showNavigator,
    required this.showToolStrip,
    required this.showPaletteDock,
    required this.inspector,
    required this.onActivate,
    required this.onOrganizeMaps,
    required this.onToolChanged,
    required this.onChanged,
    required this.onMoreTools,
    required this.onResources,
    this.onPickResource,
    this.onEnvironments,
    this.onBorders,
    this.onTerrains,
    required this.onZoneDrawn,
    required this.onContextMenu,
    this.connectionsAvailable = true,
  });

  final MapWorkspaceController controller;
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final TextEditingController search;
  final int generation;
  final bool showNavigator, showToolStrip, showPaletteDock;
  final Widget? inspector;
  final ValueChanged<ProjectMapEntry> onActivate;
  final OrganizeMapLibrary? onOrganizeMaps;
  final VoidCallback onToolChanged, onChanged, onMoreTools, onResources;
  final ValueChanged<ResourceItem>? onPickResource;
  final VoidCallback? onEnvironments, onBorders, onTerrains;
  final ValueChanged<MapRect>? onZoneDrawn;
  final void Function(GridPos, Offset)? onContextMenu;
  final bool connectionsAvailable;

  @override
  State<MapWorkspaceEditorPane> createState() => _MapWorkspaceEditorPaneState();
}

class _MapWorkspaceEditorPaneState extends State<MapWorkspaceEditorPane> {
  final _neighbors = SpatialMapNeighborSession();

  void _neighborsChanged() => setState(() {});

  void _loadSpatialNeighbors() => _neighbors.refresh(
    map: widget.document.current,
    controller: widget.controller,
    project: widget.project,
    visuals: widget.visuals,
  );

  @override
  void initState() {
    super.initState();
    _neighbors.addListener(_neighborsChanged);
    _loadSpatialNeighbors();
  }

  @override
  void didUpdateWidget(MapWorkspaceEditorPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSpatialNeighbors();
  }

  @override
  void dispose() {
    _neighbors.removeListener(_neighborsChanged);
    _neighbors.dispose();
    super.dispose();
  }

  var _borderModelsLoading = false;
  String? _borderPiecesLoading, _borderPiecesFailed;

  void _prepareSelectedBorder() {
    final id = widget.view.tool == StudioMapTool.border
        ? widget.view.borderBlueprintId
        : null;
    if (id == null ||
        id == _borderPiecesLoading ||
        id == _borderPiecesFailed ||
        widget.controller.hasBorderBlueprint(id)) {
      return;
    }
    _borderPiecesLoading = id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String? failure;
      try {
        await widget.controller.ensureBorderBlueprint(id);
      } on Object catch (error) {
        failure = '$error';
      }
      if (!mounted) return;
      setState(() {
        if (_borderPiecesLoading == id) _borderPiecesLoading = null;
        _borderPiecesFailed = failure == null ? null : id;
      });
      if (failure != null) _toolDocument.error = failure;
      widget.onChanged();
    });
  }

  bool get _exteriorActive =>
      widget.document.exteriorDecoration?.editingExterior == true;
  EditableMapDocument get _toolDocument => _exteriorActive
      ? widget.document.exteriorDecoration!.editingDocument ?? widget.document
      : widget.document;
  bool get _nativeReady =>
      !_exteriorActive ||
      widget.document.exteriorDecoration!.editingDocument != null;
  Widget _nativePanel(Widget child) =>
      IgnorePointer(ignoring: !_nativeReady, child: child);
  Widget _canvas() => widget.document.current.spatialScene != null
      ? SpatialMapEditingViewport(
          key: ValueKey(widget.document.base.mapId),
          document: widget.document,
          neighbors: _neighbors.neighbors,
          exteriorContextReady: _neighbors.ready,
          neighborDecorations: _neighbors.decorations,
          controller: widget.controller,
          project: widget.project,
          visuals: widget.visuals,
          view: widget.view,
          onChanged: widget.onChanged,
          onContextMenu: widget.onContextMenu,
        )
      : MapEditingViewport2D(
          key: ValueKey(widget.document.base.mapId),
          document: widget.document,
          project: widget.project,
          visuals: widget.visuals,
          view: widget.view,
          onChanged: widget.onChanged,
          gestureGeneration: widget.generation,
          onZoneDrawn: widget.onZoneDrawn,
          onContextMenu: widget.onContextMenu,
        );

  @override
  Widget build(BuildContext context) {
    final exterior = widget.document.exteriorDecoration;
    return exterior == null
        ? _buildPane(context)
        : ListenableBuilder(
            listenable: exterior,
            builder: (context, _) => _buildPane(context),
          );
  }

  Widget _buildPane(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      _prepareSelectedBorder();
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final compact = bounds.maxWidth < 1000 || largeText;
      final collapsed =
          widget.view.navigatorCollapsed || widget.view.mapOnly || compact;
      final contentInLeftColumn = widget.showNavigator && !collapsed;
      if (widget.view.contentInLeftColumn != contentInLeftColumn) {
        widget.view.contentInLeftColumn = contentInLeftColumn;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onToolChanged();
        });
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.showNavigator)
                        collapsed
                            ? _navigatorRail(context)
                            : MapWorkspaceLeftColumn(
                                width: mapLeftColumnWidth(bounds.maxWidth),
                                contentSelected: widget.view.elementsVisible,
                                onContentSelected: (value) {
                                  widget.view.elementsVisible = value;
                                  widget.onToolChanged();
                                },
                                maps: _navigator(
                                  context,
                                  width: mapLeftColumnWidth(bounds.maxWidth),
                                ),
                                content: MapElementsPanel(
                                  document: widget.document,
                                  project: widget.project,
                                  view: widget.view,
                                  onChanged: widget.onToolChanged,
                                  onReorder:
                                      widget.controller.canReorderElements
                                      ? widget.controller.reorderElements
                                      : null,
                                ),
                              ),
                      Expanded(
                        child: Column(
                          children: [
                            if (widget.document.exteriorDecoration
                                case final exterior?)
                              MapExteriorDecorationControls(
                                controller: exterior,
                                view: widget.view,
                                onChanged: widget.onChanged,
                              ),
                            if (widget.showToolStrip)
                              MapWorkspaceToolStrip(
                                exterior: _exteriorActive,
                                elements: widget.project.elements,
                                spatial:
                                    widget.document.current.spatialScene !=
                                    null,
                                view: widget.view,
                                storyAvailable: widget.onZoneDrawn != null,
                                paletteVisible: widget.showPaletteDock,
                                onChanged: widget.onToolChanged,
                                onMoreTools: widget.onMoreTools,
                                onResources: widget.onResources,
                                onUndo:
                                    (_exteriorActive
                                        ? widget
                                              .document
                                              .exteriorDecoration!
                                              .canUndo
                                        : widget.document.canUndo)
                                    ? () {
                                        widget.controller.restore(redo: false);
                                        widget.onChanged();
                                      }
                                    : null,
                                onRedo:
                                    (_exteriorActive
                                        ? widget
                                              .document
                                              .exteriorDecoration!
                                              .canRedo
                                        : widget.document.canRedo)
                                    ? () {
                                        widget.controller.restore(redo: true);
                                        widget.onChanged();
                                      }
                                    : null,
                              ),
                            if (widget.view.tool == StudioMapTool.terrain ||
                                (widget.view.tool == StudioMapTool.erase &&
                                    (widget.view.terrain != null ||
                                        widget.document.current.spatialScene !=
                                            null)))
                              _nativePanel(
                                MapTerrainToolPanel(
                                  document: _toolDocument,
                                  project: widget.project,
                                  visuals: widget.visuals,
                                  view: widget.view,
                                  onChanged: widget.onChanged,
                                ),
                              ),
                            if (widget.view.tool == StudioMapTool.border)
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: bounds.maxHeight * .3,
                                ),
                                child: SingleChildScrollView(
                                  child: _nativePanel(
                                    MapBorderToolPanel(
                                      document: _toolDocument,
                                      project: widget.project,
                                      view: widget.view,
                                      onChanged: widget.onChanged,
                                      onCreateModel:
                                          widget.onBorders ??
                                          widget.onResources,
                                      modelsLoaded:
                                          widget.controller.hasBorderProfiles,
                                      modelsLoading: _borderModelsLoading,
                                      piecesLoading:
                                          _borderPiecesLoading != null &&
                                          _borderPiecesLoading ==
                                              widget.view.borderBlueprintId,
                                      onLoadModels: () async {
                                        setState(
                                          () => _borderModelsLoading = true,
                                        );
                                        try {
                                          await widget.controller
                                              .ensureBorderProfiles();
                                        } on Object catch (failure) {
                                          _toolDocument.error = '$failure';
                                        }
                                        if (mounted) {
                                          setState(
                                            () => _borderModelsLoading = false,
                                          );
                                        }
                                        widget.onChanged();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.view.tool == StudioMapTool.environment)
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: bounds.maxHeight * .3,
                                ),
                                child: SingleChildScrollView(
                                  child: _nativePanel(
                                    MapEnvironmentToolPanel(
                                      document: _toolDocument,
                                      project: widget.project,
                                      view: widget.view,
                                      onChanged: widget.onChanged,
                                      onResources:
                                          widget.onEnvironments ??
                                          widget.onResources,
                                    ),
                                  ),
                                ),
                              ),
                            if (_neighbors.failure != null)
                              StudioNotice(
                                'Les cartes voisines ne peuvent pas être affichées : ${_neighbors.failure}',
                              ),
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(child: _canvas()),
                                  Positioned(
                                    left: 8,
                                    top: 8,
                                    right: 8,
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: MapIntentStatusChip(
                                        intent: mapPaletteIntent(
                                          widget.view,
                                          project: widget.project,
                                          spatial:
                                              widget
                                                  .document
                                                  .current
                                                  .spatialScene !=
                                              null,
                                          connectionsAvailable:
                                              widget.connectionsAvailable,
                                          editingExterior:
                                              widget
                                                      .document
                                                      .exteriorDecoration ==
                                                  null
                                              ? null
                                              : _exteriorActive,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.showPaletteDock)
                  MapWorkspacePaletteDock(
                    onPickResource: widget.onPickResource,
                    connectionsAvailable: widget.connectionsAvailable,
                    project: widget.project,
                    document: widget.document,
                    visuals: widget.visuals,
                    view: widget.view,
                    search: widget.search,
                    onChanged: widget.onToolChanged,
                    onResources: widget.onResources,
                    onPrepare: switch (widget.view.paletteTab) {
                      'Bordures' => widget.onBorders,
                      'Environnements' => widget.onEnvironments,
                      'Terrains' => widget.onTerrains,
                      _ => null,
                    },
                    onOpenFullPalette: widget.onMoreTools,
                    maxHeight: bounds.maxHeight * (largeText ? .34 : .38),
                    compact: bounds.maxHeight < 600 || compact,
                  ),
              ],
            ),
          ),
          if (widget.inspector != null) widget.inspector!,
        ],
      );
    },
  );

  Widget _navigatorRail(BuildContext context) => SizedBox(
    key: const ValueKey('map-navigator-rail'),
    width: 48,
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: StudioTool(
          label: 'Afficher les cartes',
          icon: Icons.folder_outlined,
          onPressed: () {
            if (MediaQuery.textScalerOf(context).scale(14) > 20 ||
                MediaQuery.sizeOf(context).width < 1200) {
              showMapLibraryCompactPanel(
                context,
                controller: widget.controller,
                onActivate: widget.onActivate,
                onOrganize: widget.onOrganizeMaps,
                visuals: widget.visuals,
              );
            } else {
              setState(() => widget.view.navigatorCollapsed = false);
            }
          },
        ),
      ),
    ),
  );

  Widget _navigator(BuildContext context, {double width = 252}) =>
      MapLibraryNavigator(
        width: width,
        project: widget.project,
        activeMapId: widget.document.base.mapId,
        dirtyMapIds: {
          for (final entry in widget.controller.documents.entries)
            if (entry.value.dirty) entry.key,
        },
        onActivate: widget.onActivate,
        onOrganize: widget.onOrganizeMaps,
        onRetryCatalogue: widget.controller.pendingCatalogReceipt == null
            ? null
            : () => widget.controller.retryCatalogRefresh(),
        onCreateMap: widget.controller.catalogPort == null
            ? null
            : (groupId) => createWorkspaceMap(
                context,
                widget.controller,
                groupId: groupId,
              ),
        onRenameMap: widget.controller.catalogPort == null
            ? null
            : (entry) => renameWorkspaceMap(context, widget.controller, entry),
        onLifecycleMap: widget.controller.catalogPort == null
            ? null
            : (entry, action) => manageWorkspaceMap(
                context,
                widget.controller,
                entry,
                action,
                visuals: widget.visuals,
              ),
        onCollapse: () => setState(() => widget.view.navigatorCollapsed = true),
      );
}
