import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:map_render_3d/map_render_3d.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/domain/map_exterior_decoration_port.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import 'map_library_navigator.dart';
import '../resources/resource_catalog.dart';
import 'map_workspace_compact_navigator.dart';
import 'map_workspace_canvas.dart';
import 'map_workspace_palette_dock.dart';
import 'map_workspace_tool_strip.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'spatial_map_editor.dart';
import 'map_exterior_decoration_controls.dart';
import 'map_border_tool_panel.dart';
import 'map_environment_tool_panel.dart';
import 'map_terrain_tool_panel.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'map_catalogue_workspace_actions.dart';
import 'map_lifecycle_workspace_actions.dart';

part 'map_workspace_spatial_neighbors.dart';

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
    required this.onZoneDrawn,
    required this.onContextMenu,
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
  final VoidCallback? onEnvironments, onBorders;
  final ValueChanged<MapRect>? onZoneDrawn;
  final void Function(GridPos, Offset)? onContextMenu;

  @override
  State<MapWorkspaceEditorPane> createState() => _MapWorkspaceEditorPaneState();
}

class _MapWorkspaceEditorPaneState extends State<MapWorkspaceEditorPane> {
  final _neighborSources = <Object, Future<_EditorNeighborSource>>{};
  List<SpatialSceneNeighbor> _neighbors = const [];
  List<SpatialSceneDecoration> _neighborDecorations = const [];
  List<Object?>? _neighborRequest;
  int _neighborGeneration = 0;
  Object? _neighborFailure;
  bool _neighborLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSpatialNeighbors();
  }

  @override
  void didUpdateWidget(MapWorkspaceEditorPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSpatialNeighbors();
  }

  @override
  void dispose() {
    _neighborGeneration++;
    _neighborSources.clear();
    super.dispose();
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
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final compact = bounds.maxWidth < 1000 || largeText;
      final collapsed = widget.view.navigatorCollapsed || compact;
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
                            : _navigator(context),
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
                            if (_neighborFailure != null)
                              StudioNotice(
                                'Les cartes voisines ne peuvent pas être affichées : $_neighborFailure',
                              ),
                            Expanded(
                              child:
                                  widget.document.current.spatialScene != null
                                  ? SpatialMapEditor(
                                      key: ValueKey(widget.document.base.mapId),
                                      document: widget.document,
                                      neighbors: _neighbors,
                                      exteriorContextReady:
                                          !_neighborLoading &&
                                          _neighborFailure == null,
                                      neighborDecorations: _neighborDecorations,
                                      controller: widget.controller,
                                      project: widget.project,
                                      visuals: widget.visuals,
                                      view: widget.view,
                                      onChanged: widget.onChanged,
                                      onContextMenu: widget.onContextMenu,
                                    )
                                  : MapWorkspaceCanvas(
                                      key: ValueKey(widget.document.base.mapId),
                                      document: widget.document,
                                      project: widget.project,
                                      visuals: widget.visuals,
                                      view: widget.view,
                                      onChanged: widget.onChanged,
                                      gestureGeneration: widget.generation,
                                      onZoneDrawn: widget.onZoneDrawn,
                                      onContextMenu: widget.onContextMenu,
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
                    project: widget.project,
                    document: widget.document,
                    visuals: widget.visuals,
                    view: widget.view,
                    search: widget.search,
                    onChanged: widget.onToolChanged,
                    onResources: widget.onResources,
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

  Widget _navigator(BuildContext context) => MapLibraryNavigator(
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
        : (groupId) =>
              createWorkspaceMap(context, widget.controller, groupId: groupId),
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
    width: 252,
  );
}
