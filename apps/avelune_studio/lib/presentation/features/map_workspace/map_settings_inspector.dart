import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import 'map_catalogue_properties.dart';
import 'map_workspace_view_state.dart';

class MapSettingsInspector extends StatelessWidget {
  const MapSettingsInspector({
    super.key,
    required this.project,
    required this.document,
    required this.view,
    required this.onChanged,
    this.onRenameMap,
    this.onEscapeSettings,
    this.showTitle = true,
  });

  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final VoidCallback? onRenameMap, onEscapeSettings;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('map-settings-inspector'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'RÉGLAGES DE CETTE CARTE',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            document.current.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
        ],
        MapCatalogueProperties(
          map: document.current,
          onRename: onRenameMap,
          onEscapeSettings: onEscapeSettings,
        ),
      ],
    );
  }
}

class MapInspectorScope extends StatefulWidget {
  const MapInspectorScope({
    super.key,
    required this.document,
    required this.view,
    required this.width,
    required this.selection,
    required this.mapSettings,
  });

  final EditableMapDocument document;
  final MapWorkspaceViewState view;
  final double width;
  final Widget selection;
  final Widget Function() mapSettings;

  @override
  State<MapInspectorScope> createState() => _MapInspectorScopeState();
}

class _MapInspectorScopeState extends State<MapInspectorScope> {
  String? _mapFor;

  String? _signature() {
    final document = widget.document;
    final view = widget.view;
    final mapId = document.current.id;
    if (document.exteriorDecoration?.editingExterior == true ||
        !view.hasSelectionIn(mapId) ||
        switch (view.tool) {
          StudioMapTool.terrain ||
          StudioMapTool.erase ||
          StudioMapTool.connection => true,
          _ => false,
        }) {
      return null;
    }
    return [
      mapId,
      for (final family in MapSelectionFamily.values)
        view.selectedFor(mapId, family) ?? '',
      ...view.selectedDecorIds(mapId),
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    final signature = _signature();
    if (signature == null) return widget.selection;
    final showMap = _mapFor == signature;
    return Column(
      children: [
        StudioSidebar(
          width: widget.width,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StudioTabs<bool>(
              key: const ValueKey('map-inspector-scope'),
              items: const {false: 'Sélection', true: 'Carte'},
              selected: showMap,
              onChanged: (map) =>
                  setState(() => _mapFor = map ? signature : null),
            ),
          ),
        ),
        Expanded(
          child: showMap
              ? StudioSidebar(
                  width: widget.width,
                  child: ListView(children: [widget.mapSettings()]),
                )
              : widget.selection,
        ),
      ],
    );
  }
}
