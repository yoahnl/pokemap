import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import 'map_library_navigator.dart';
import 'map_workspace_compact_navigator.dart';
import 'map_workspace_canvas.dart';
import 'map_workspace_palette_dock.dart';
import 'map_workspace_tool_strip.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'spatial_map_editor.dart';
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
  final VoidCallback? onEnvironments, onBorders;
  final ValueChanged<MapRect>? onZoneDrawn;
  final void Function(GridPos, Offset)? onContextMenu;

  @override
  State<MapWorkspaceEditorPane> createState() => _MapWorkspaceEditorPaneState();
}

class _MapWorkspaceEditorPaneState extends State<MapWorkspaceEditorPane> {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
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
                            if (widget.showToolStrip)
                              MapWorkspaceToolStrip(
                                spatial:
                                    widget.document.current.spatialScene !=
                                    null,
                                view: widget.view,
                                storyAvailable: widget.onZoneDrawn != null,
                                paletteVisible: widget.showPaletteDock,
                                onChanged: widget.onToolChanged,
                                onMoreTools: widget.onMoreTools,
                                onResources: widget.onResources,
                                onUndo: widget.document.canUndo
                                    ? () {
                                        widget.controller.restore(redo: false);
                                        widget.onChanged();
                                      }
                                    : null,
                                onRedo: widget.document.canRedo
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
                              MapTerrainToolPanel(
                                document: widget.document,
                                project: widget.project,
                                visuals: widget.visuals,
                                view: widget.view,
                                onChanged: widget.onChanged,
                              ),
                            if (widget.view.tool == StudioMapTool.border)
                              MapBorderToolPanel(
                                document: widget.document,
                                project: widget.project,
                                view: widget.view,
                                onChanged: widget.onChanged,
                                onCreateModel:
                                    widget.onBorders ?? widget.onResources,
                              ),
                            if (widget.view.tool == StudioMapTool.environment)
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: bounds.maxHeight * .3,
                                ),
                                child: SingleChildScrollView(
                                  child: MapEnvironmentToolPanel(
                                    document: widget.document,
                                    project: widget.project,
                                    view: widget.view,
                                    onChanged: widget.onChanged,
                                    onResources:
                                        widget.onEnvironments ??
                                        widget.onResources,
                                  ),
                                ),
                              ),
                            Expanded(
                              child:
                                  widget.document.current.spatialScene != null
                                  ? SpatialMapEditor(
                                      key: ValueKey(widget.document.base.mapId),
                                      document: widget.document,
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
          ?widget.inspector,
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
