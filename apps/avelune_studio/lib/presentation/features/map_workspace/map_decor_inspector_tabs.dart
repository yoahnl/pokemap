import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import 'map_decor_order_panel.dart';
import 'map_workspace_inspector.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';

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
  });

  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final ValueChanged<ProjectElementEntry> onOpenResource, onEditResource;
  final double width;

  @override
  State<MapDecorInspectorTabs> createState() => _MapDecorInspectorTabsState();
}

class _MapDecorInspectorTabsState extends State<MapDecorInspectorTabs> {
  bool _showOrder = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.document.selected;
    return Column(
      children: [
        if (selected != null)
          StudioTabs<bool>(
            items: const {false: 'Propriétés', true: 'Ordre'},
            selected: _showOrder,
            onChanged: (value) => setState(() => _showOrder = value),
          ),
        Expanded(
          child: _showOrder && selected != null
              ? StudioSidebar(
                  width: widget.width,
                  child: MapDecorOrderPanel(
                    document: widget.document,
                    project: widget.project,
                    visuals: widget.visuals,
                    view: widget.view,
                    onChanged: widget.onChanged,
                  ),
                )
              : MapWorkspaceInspector(
                  project: widget.project,
                  document: widget.document,
                  visuals: widget.visuals,
                  view: widget.view,
                  onChanged: widget.onChanged,
                  onOpenResource: widget.onOpenResource,
                  onEditResource: widget.onEditResource,
                  width: widget.width,
                  tool: widget.view.tool,
                ),
        ),
      ],
    );
  }
}
