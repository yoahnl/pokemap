import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import 'map_decor_selection_summary.dart';
import 'map_workspace_inspector.dart';
import 'map_workspace_view_state.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

class MapDecorInspectorTabs extends StatefulWidget {
  const MapDecorInspectorTabs({
    super.key,
    required this.project,
    required this.document,
    required this.visuals,
    required this.view,
    required this.onChanged,
    required this.onOpenResource,
    required this.onEditResource,
    required this.width,
    this.onRenameMap,
    this.onEscapeSettings,
    this.onEventSource,
  });

  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final ValueChanged<ProjectElementEntry> onOpenResource, onEditResource;
  final double width;
  final VoidCallback? onRenameMap;
  final VoidCallback? onEscapeSettings;
  final ValueChanged<NarrativeEventSourceRef>? onEventSource;

  @override
  State<MapDecorInspectorTabs> createState() => _MapDecorInspectorTabsState();
}

class _MapDecorInspectorTabsState extends State<MapDecorInspectorTabs> {
  @override
  Widget build(BuildContext context) {
    final selected = widget.document.selected;
    return Column(
      children: [
        if (selected != null)
          StudioSidebar(
            width: widget.width,
            child: MapDecorSelectionSummary(
              document: widget.document,
              project: widget.project,
              visuals: widget.visuals,
            ),
          ),
        Expanded(
          child: MapWorkspaceInspector(
            project: widget.project,
            document: widget.document,
            visuals: widget.visuals,
            view: widget.view,
            onChanged: widget.onChanged,
            onOpenResource: widget.onOpenResource,
            onEditResource: widget.onEditResource,
            onRenameMap: widget.onRenameMap,
            onEscapeSettings: widget.onEscapeSettings,
            onEventSource: widget.onEventSource,
            width: widget.width,
            tool: widget.view.tool,
            showSelectionSummary: selected == null,
          ),
        ),
      ],
    );
  }
}
