import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import 'map_library_navigator.dart';
import 'map_workspace_canvas.dart';
import 'map_workspace_palette_dock.dart';
import 'map_workspace_tool_strip.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import '../../shared/widgets/buttons/studio_tool.dart';

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
  final ValueChanged<MapRect>? onZoneDrawn;
  final void Function(GridPos, Offset)? onContextMenu;

  @override
  State<MapWorkspaceEditorPane> createState() => _MapWorkspaceEditorPaneState();
}

class _MapWorkspaceEditorPaneState extends State<MapWorkspaceEditorPane> {
  bool _navigatorCollapsed = false;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (widget.showToolStrip)
                        Padding(
                          padding: EdgeInsets.only(
                            left: widget.showNavigator && !_navigatorCollapsed
                                ? 252
                                : 0,
                          ),
                          child: MapWorkspaceToolStrip(
                            view: widget.view,
                            storyAvailable: widget.onZoneDrawn != null,
                            onChanged: widget.onToolChanged,
                            onMoreTools: widget.onMoreTools,
                            onResources: widget.onResources,
                          ),
                        ),
                      Expanded(
                        child: MapWorkspaceCanvas(
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
                  if (widget.showNavigator)
                    Positioned(
                      top: 0,
                      left: 0,
                      height: 320,
                      child: Offstage(
                        offstage: _navigatorCollapsed,
                        child: MapLibraryNavigator(
                          project: widget.project,
                          activeMapId: widget.document.base.mapId,
                          dirtyMapIds: {
                            for (final entry
                                in widget.controller.documents.entries)
                              if (entry.value.dirty) entry.key,
                          },
                          onActivate: widget.onActivate,
                          onOrganize: widget.onOrganizeMaps,
                          onCollapse: () =>
                              setState(() => _navigatorCollapsed = true),
                          width: 252,
                        ),
                      ),
                    ),
                  if (widget.showNavigator && _navigatorCollapsed)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: StudioTool(
                        label: 'Afficher les cartes',
                        icon: Icons.keyboard_double_arrow_right,
                        onPressed: () =>
                            setState(() => _navigatorCollapsed = false),
                      ),
                    ),
                ],
              ),
            ),
            ?widget.inspector,
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
        ),
    ],
  );
}
