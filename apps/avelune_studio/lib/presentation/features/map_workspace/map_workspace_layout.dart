import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'map_workspace_toolbar.dart';
import 'map_workspace_canvas.dart';
import 'map_workspace_panels.dart';
import 'map_workspace_inspector.dart';
import 'workspace_resource_diagnostics.dart';

class MapWorkspaceLayout extends StatelessWidget {
  const MapWorkspaceLayout({
    super.key,
    required this.controller,
    required this.view,
    required this.visuals,
    required this.search,
    required this.error,
    required this.palette,
    required this.inspector,
    required this.generation,
    required this.onPalette,
    required this.onInspector,
    required this.onChanged,
    required this.onToolChanged,
    required this.onActivate,
    required this.onSave,
    required this.onTest,
    required this.onClose,
    required this.onResources,
    required this.onMap,
    required this.onOpenElement,
    required this.onEditElement,
    required this.onTileset,
    this.resourceContent,
  });
  final MapWorkspaceController controller;
  final MapWorkspaceViewState? view;
  final MapWorkspaceVisuals? visuals;
  final TextEditingController search;
  final String? error;
  final bool palette;
  final bool? inspector;
  final int generation;
  final VoidCallback onPalette,
      onInspector,
      onChanged,
      onToolChanged,
      onClose,
      onResources,
      onMap;
  final ValueChanged<ProjectMapEntry> onActivate;
  final VoidCallback? onSave, onTest;
  final ValueChanged<ProjectElementEntry> onOpenElement, onEditElement;
  final ValueChanged<ProjectTilesetEntry> onTileset;
  final Widget? resourceContent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final doc = controller.active;
      final project = controller.project;
      final ready =
          doc != null && project != null && visuals != null && view != null;
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final showInspector = inspector ?? (c.maxWidth >= 1150 && !largeText);
      final showPalette = palette && c.maxWidth >= 620 && !largeText;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Avelune Studio',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      StudioButton(
                        label: 'Carte',
                        secondary: resourceContent != null,
                        onPressed: onMap,
                      ),
                      const SizedBox(width: 6),
                      StudioButton(
                        label: 'Ressources',
                        secondary: resourceContent == null,
                        onPressed: visuals == null ? null : onResources,
                      ),
                    ],
                  ),
                ),
                if (resourceContent != null)
                  IconButton(
                    tooltip: 'Fermer le projet',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          if (resourceContent == null)
            MapWorkspaceToolbar(
              controller: controller,
              view: view,
              onChanged: onToolChanged,
              paletteVisible: showPalette,
              inspectorVisible: showInspector,
              onPalette: onPalette,
              onInspector: onInspector,
              onActivate: onActivate,
              onSave: onSave,
              onTest: onTest,
              onClose: onClose,
            ),
          if (error != null) StudioNotice(error!, isError: true),
          Expanded(
            child:
                resourceContent ??
                (controller.loading ||
                        (project == null && error == null) ||
                        (project != null && visuals == null && error == null)
                    ? const Center(child: CircularProgressIndicator())
                    : !ready
                    ? const Center(
                        child: Text(
                          'Choisissez une carte disponible dans ce projet.',
                        ),
                      )
                    : Row(
                        children: [
                          if (showPalette)
                            MapWorkspacePalette(
                              project: project,
                              document: doc,
                              visuals: visuals!,
                              view: view!,
                              search: search,
                              onChanged: onToolChanged,
                              onResources: onResources,
                              onTileset: onTileset,
                            ),
                          Expanded(
                            child: MapWorkspaceCanvas(
                              key: ValueKey(doc.base.mapId),
                              document: doc,
                              project: project,
                              visuals: visuals!,
                              view: view!,
                              onChanged: onChanged,
                              gestureGeneration: generation,
                            ),
                          ),
                          if (showInspector && c.maxWidth >= 900 && !largeText)
                            MapWorkspaceInspector(
                              project: project,
                              document: doc,
                              visuals: visuals!,
                              onChanged: onToolChanged,
                              onOpenResource: onOpenElement,
                              onEditResource: onEditElement,
                            ),
                        ],
                      )),
          ),
          if (visuals != null) WorkspaceResourceDiagnostics(visuals: visuals!),
        ],
      );
    },
  );
}
