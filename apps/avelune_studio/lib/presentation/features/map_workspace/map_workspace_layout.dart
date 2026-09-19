import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/layout/studio_application_frame.dart';
import 'map_creation_tools.dart';
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
    required this.homeSearch,
    this.onSearch,
    this.onCharacters,
    this.resourceContent,
    this.onStory,
    this.onEditInteraction,
    this.onZoneDrawn,
    this.deletionBlocked,
    this.activeSpace = 'map',
    this.onHome,
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
  final TextEditingController homeSearch;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onCharacters;
  final Widget? resourceContent;
  final VoidCallback? onStory;
  final ValueChanged<MapEntity>? onEditInteraction;
  final ValueChanged<MapRect>? onZoneDrawn;
  final bool Function(String)? deletionBlocked;
  final String activeSpace;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final doc = controller.active;
      final project = controller.project;
      final ready =
          doc != null && project != null && visuals != null && view != null;
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final availableWidth = c.maxWidth - (c.maxWidth < 1200 ? 72 : 184);
      final compactInspector = availableWidth < 1000 || largeText;
      final compactPalette = availableWidth < 650 || largeText;
      final showInspector = inspector ?? (!compactInspector);
      final showPalette = palette && !compactPalette;
      final paletteWidth = c.maxWidth >= 1400 ? 240.0 : 220.0;
      final inspectorWidth = c.maxWidth >= 1400 ? 300.0 : 280.0;
      Widget paletteContent(VoidCallback refresh, [VoidCallback? close]) {
        if (!ready) return const SizedBox();
        return SizedBox(
          width: close == null ? paletteWidth : 360,
          child: Column(
            children: [
              MapCreationTools(
                view: view!,
                onChanged: () {
                  onToolChanged();
                  refresh();
                },
                storyAvailable: onZoneDrawn != null,
              ),
              Expanded(
                child: MapWorkspacePalette(
                  width: close == null ? paletteWidth : 360,
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
                ),
              ),
            ],
          ),
        );
      }

      Widget inspectorContent(VoidCallback refresh, [VoidCallback? close]) {
        if (!ready) return const SizedBox();
        return MapSelectionInspector(
          width: inspectorWidth,
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

      return StudioApplicationFrame(
        projectName: controller.session.name,
        search: homeSearch,
        onSearch: onSearch ?? (_) {},
        canTest: onTest != null,
        onClose: onClose,
        active: activeSpace == 'interaction' ? 'story' : activeSpace,
        onDestination: (destination) {
          switch (destination) {
            case 'home':
              onHome?.call();
            case 'map':
              onMap();
            case 'resources':
              onResources();
            case 'characters':
              onCharacters?.call();
            case 'story':
              onStory?.call();
            case 'test':
              onTest?.call();
          }
        },
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
            if (error != null) StudioNotice(error!, isError: true, maxLines: 2),
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
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
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
                                ),
                              ),
                            ),
                            if (showInspector && !compactInspector)
                              inspectorContent(() {}),
                          ],
                        )),
            ),
            if (visuals != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (doc?.current.layers.any(
                          (layer) => layer is BorderLayer && layer.isVisible,
                        ) ==
                        true)
                      const Tooltip(
                        message:
                            'Les bordures restent conservées et rendues dans le test du jeu.',
                        child: Text(
                          'Bordures non prévisualisées · visibles dans le test du jeu',
                          key: ValueKey('map-border-notice'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    WorkspaceResourceDiagnostics(visuals: visuals!),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}
