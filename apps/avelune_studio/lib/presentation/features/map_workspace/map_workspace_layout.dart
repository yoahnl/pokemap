import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_app_shell.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'map_workspace_toolbar.dart';
import 'map_workspace_canvas.dart';
import 'map_workspace_panels.dart';
import 'workspace_resource_diagnostics.dart';
import 'map_selection_inspector.dart';
import 'workspace_compact_panel.dart';

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
    this.onStory,
    this.onEditInteraction,
    this.onZoneDrawn,
    this.deletionBlocked,
    this.activeSpace = 'map',
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
  final VoidCallback? onStory;
  final ValueChanged<MapEntity>? onEditInteraction;
  final ValueChanged<MapRect>? onZoneDrawn;
  final bool Function(String)? deletionBlocked;
  final String activeSpace;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final doc = controller.active;
      final project = controller.project;
      final ready =
          doc != null && project != null && visuals != null && view != null;
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final compactInspector = c.maxWidth < 900 || largeText;
      final compactPalette = c.maxWidth < 620 || largeText;
      final showInspector = inspector ?? (c.maxWidth >= 1150 && !largeText);
      final showPalette = palette && !compactPalette;
      Widget paletteContent(VoidCallback refresh, [VoidCallback? close]) {
        if (!ready) return const SizedBox();
        return MapWorkspacePalette(
          project: project,
          document: doc,
          visuals: visuals!,
          view: view!,
          search: search,
          onChanged: () {
            onToolChanged();
            refresh();
            close?.call();
          },
          onResources: () {
            close?.call();
            onResources();
          },
          onTileset: (tileset) {
            close?.call();
            onTileset(tileset);
          },
        );
      }

      Widget inspectorContent(VoidCallback refresh, [VoidCallback? close]) {
        if (!ready) return const SizedBox();
        return MapSelectionInspector(
          document: doc,
          project: project,
          visuals: visuals!,
          view: view!,
          onChanged: () {
            onToolChanged();
            refresh();
          },
          onOpenElement: (element) {
            close?.call();
            onOpenElement(element);
          },
          onEditElement: (element) {
            close?.call();
            onEditElement(element);
          },
          onEditInteraction: (entity) {
            close?.call();
            onEditInteraction?.call(entity);
          },
          deletionBlocked: deletionBlocked,
        );
      }

      return StudioAppShell(
        projectName: controller.session.name,
        destinations: [
          StudioDestination(
            label: 'Carte',
            icon: Icons.map_outlined,
            onTap: onMap,
            selected: activeSpace == 'map',
          ),
          StudioDestination(
            label: 'Ressources',
            icon: Icons.grid_view_outlined,
            onTap: visuals == null ? null : onResources,
            selected: activeSpace == 'resources',
          ),
          if (onStory != null)
            StudioDestination(
              label: 'Histoire',
              icon: Icons.menu_book_outlined,
              onTap: onStory,
              selected: activeSpace == 'story' || activeSpace == 'interaction',
            ),
        ],
        actions: [
          if (resourceContent != null)
            IconButton(
              tooltip: 'Fermer le projet',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
        ],
        child: Column(
          children: [
            if (resourceContent == null)
              MapWorkspaceToolbar(
                controller: controller,
                view: view,
                onChanged: onToolChanged,
                paletteVisible: showPalette,
                inspectorVisible: showInspector && !compactInspector,
                onPalette: compactPalette && ready
                    ? () => showWorkspaceCompactPanel(
                        context,
                        title: 'Palette',
                        builder: (context, refresh, close) =>
                            paletteContent(refresh, close),
                      )
                    : onPalette,
                onInspector: compactInspector && ready
                    ? () => showWorkspaceCompactPanel(
                        context,
                        title: 'Inspecteur',
                        builder: (context, refresh, close) =>
                            inspectorContent(refresh, close),
                      )
                    : onInspector,
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
                            if (showPalette) paletteContent(() {}),
                            Expanded(
                              child: MapWorkspaceCanvas(
                                key: ValueKey(doc.base.mapId),
                                document: doc,
                                project: project,
                                visuals: visuals!,
                                view: view!,
                                onChanged: onChanged,
                                gestureGeneration: generation,
                                onZoneDrawn: onZoneDrawn,
                              ),
                            ),
                            if (showInspector && !compactInspector)
                              inspectorContent(() {}),
                          ],
                        )),
            ),
            if (visuals != null)
              WorkspaceResourceDiagnostics(visuals: visuals!),
          ],
        ),
      );
    },
  );
}
