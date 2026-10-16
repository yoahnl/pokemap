import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

import 'map_creation_tools.dart';
import '../resources/resource_catalog.dart';
import 'map_workspace_panels.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';

class MapWorkspacePaletteColumn extends StatelessWidget {
  const MapWorkspacePaletteColumn({
    super.key,
    required this.width,
    required this.project,
    required this.document,
    required this.visuals,
    required this.view,
    required this.search,
    required this.storyAvailable,
    required this.onToolChanged,
    required this.onRefresh,
    required this.onResources,
    this.onClose,
    this.onPickResource,
  });
  final double width;
  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final TextEditingController search;
  final bool storyAvailable;
  final VoidCallback onToolChanged;
  final VoidCallback onRefresh;
  final VoidCallback onResources;
  final VoidCallback? onClose;
  final ValueChanged<ResourceItem>? onPickResource;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight.isFinite
                  ? constraints.maxHeight *
                        (constraints.maxHeight < 700 ||
                                MediaQuery.textScalerOf(context).scale(14) > 18
                            ? .15
                            : .32)
                  : double.infinity,
            ),
            child: SingleChildScrollView(
              child: MapCreationTools(
                spatial: document.current.spatialScene != null ||
                    project.settings.dimension != ProjectDimension.twoD,
                view: view,
                onChanged: () {
                  onToolChanged();
                  onRefresh();
                },
                storyAvailable: storyAvailable,
              ),
            ),
          ),
          Expanded(
            child: MapWorkspacePalette(
              width: width,
              project: project,
              document: document,
              visuals: visuals,
              view: view,
              search: search,
              onChanged: () {
                onToolChanged();
                onRefresh();
                onClose?.call();
              },
              onResources: () {
                onClose?.call();
                onResources();
              },
              onPickResource: onPickResource == null
                  ? null
                  : (item) {
                      onPickResource!(item);
                      onClose?.call();
                    },
            ),
          ),
        ],
      ),
    ),
  );
}
