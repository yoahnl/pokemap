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

class MapWorkspaceEditorPane extends StatelessWidget {
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
  Widget build(BuildContext context) => Row(
    children: [
      if (showNavigator)
        MapLibraryNavigator(
          project: project,
          activeMapId: document.base.mapId,
          dirtyMapIds: {
            for (final entry in controller.documents.entries)
              if (entry.value.dirty) entry.key,
          },
          onActivate: onActivate,
          onOrganize: onOrganizeMaps,
          width: 230,
        ),
      Expanded(
        child: Column(
          children: [
            if (showToolStrip)
              MapWorkspaceToolStrip(
                view: view,
                storyAvailable: onZoneDrawn != null,
                onChanged: onToolChanged,
                onMoreTools: onMoreTools,
                onResources: onResources,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: MapWorkspaceCanvas(
                      key: ValueKey(document.base.mapId),
                      document: document,
                      project: project,
                      visuals: visuals,
                      view: view,
                      onChanged: onChanged,
                      gestureGeneration: generation,
                      onZoneDrawn: onZoneDrawn,
                      onContextMenu: onContextMenu,
                    ),
                  ),
                ),
              ),
            ),
            if (showPaletteDock)
              MapWorkspacePaletteDock(
                project: project,
                document: document,
                visuals: visuals,
                view: view,
                search: search,
                onChanged: onToolChanged,
                onResources: onResources,
                onOpenFullPalette: onMoreTools,
              ),
          ],
        ),
      ),
      ?inspector,
    ],
  );
}
