import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import '../../shared/widgets/layout/studio_application_frame.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'map_workspace_toolbar.dart';
import 'map_workspace_palette_column.dart';
import 'map_library_navigator.dart';
import 'map_workspace_compact_navigator.dart';
import 'map_workspace_editor_pane.dart';
import 'workspace_map_footer.dart';
import 'map_selection_inspector.dart';
import 'workspace_compact_panel.dart';
import 'map_catalogue_empty_view.dart';
import 'map_catalogue_workspace_actions.dart';

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
    this.onEnvironments,
    this.onBorders,
    required this.onMap,
    required this.onExport,
    required this.onPokemon,
    required this.onOpenElement,
    required this.onEditElement,
    required this.homeSearch,
    this.onSearch,
    this.resourceContent,
    this.onStory,
    this.onEditInteraction,
    this.onZoneDrawn,
    this.referenceGuard,
    this.onContextMenu,
    this.movingHint,
    this.activeSpace = 'map',
    this.exportActive = false,
    this.onHome,
    this.onOrganizeMaps,
    this.onLinkMaps,
    this.onUnlinkMaps,
  });
  final MapWorkspaceController controller;
  final MapWorkspaceViewState? view;
  final MapWorkspaceVisuals? visuals;
  final TextEditingController search, homeSearch;
  final String? error, movingHint;
  final bool palette;
  final bool? inspector;
  final int generation;
  final VoidCallback onPalette, onInspector, onChanged, onToolChanged;
  final VoidCallback onClose, onResources, onMap, onExport, onPokemon;
  final ValueChanged<ProjectMapEntry> onActivate;
  final VoidCallback? onSave, onTest;
  final bool exportActive;
  final ValueChanged<ProjectElementEntry> onOpenElement, onEditElement;
  final ValueChanged<String>? onSearch;
  final Widget? resourceContent;
  final VoidCallback? onStory, onHome, onEnvironments, onBorders;
  final ValueChanged<MapEntity>? onEditInteraction;
  final ValueChanged<MapRect>? onZoneDrawn;
  final MapReferenceGuard? referenceGuard;
  final void Function(GridPos, Offset)? onContextMenu;
  final String activeSpace;
  final OrganizeMapLibrary? onOrganizeMaps;
  final Future<void> Function(MapConnectionDirection, String, int)? onLinkMaps;
  final Future<void> Function(MapConnectionDirection)? onUnlinkMaps;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final doc = controller.active;
      final project = controller.project;
      final ready =
          doc != null && project != null && visuals != null && view != null;
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
      final availableWidth = c.maxWidth - (c.maxWidth < 1200 ? 72 : 184);
      final compactInspector = availableWidth < 1200 || largeText;
      final compactPalette = availableWidth < 650;
      final showInspector = inspector ?? (!compactInspector);
      final showNavigator = activeSpace == 'map';
      final showPaletteDock = palette;
      final paletteWidth = c.maxWidth >= 1400 ? 240.0 : 220.0;
      final inspectorWidth = c.maxWidth >= 1400 ? 340.0 : 280.0;
      Widget paletteContent(VoidCallback refresh, [VoidCallback? close]) {
        if (!ready) return const SizedBox();
        return MapWorkspacePaletteColumn(
          width: close == null ? paletteWidth : 360,
          project: project,
          document: doc,
          visuals: visuals!,
          view: view!,
          search: search,
          storyAvailable: onZoneDrawn != null,
          onToolChanged: onToolChanged,
          onRefresh: refresh,
          onResources: onResources,
          onClose: close,
        );
      }

      void openPalette() => showWorkspaceCompactPanel(
        context,
        title: 'Palette',
        builder: (context, refresh, close) => paletteContent(refresh, close),
      );
      void openNavigator() => showMapLibraryCompactPanel(
        context,
        controller: controller,
        onActivate: onActivate,
        onOrganize: onOrganizeMaps,
        visuals: visuals,
      );
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
          onRenameMap: mapCatalogueRenameAction(context, controller),
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
          onOpenMap: mapLibraryOpenAction(project, onActivate, close),
          onLinkMaps: onLinkMaps,
          onUnlinkMaps: onUnlinkMaps,
          referenceGuard: referenceGuard,
        );
      }

      if (ready && activeSpace == 'map' && view!.revealInspector) {
        view!.revealInspector = false;
        if (compactInspector) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            showWorkspaceCompactPanel(
              context,
              title: 'Inspecteur',
              builder: (context, refresh, close) =>
                  inspectorContent(refresh, close),
            );
          });
        }
      }
      if (ready && activeSpace == 'map' && view!.revealPalette) {
        view!.revealPalette = false;
        if (compactPalette) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            openPalette();
          });
        }
      }
      final headerBar =
          c.maxWidth >= 1400 && !largeText && activeSpace == 'map';
      final toolbar = resourceContent == null
          ? MapWorkspaceToolbar(
              controller: controller,
              view: view,
              onChanged: onToolChanged,
              paletteVisible: showPaletteDock,
              inspectorVisible: showInspector && !compactInspector,
              navigatorVisible: showNavigator,
              showUndoRedo: activeSpace != 'map',
              onNavigator: openNavigator,
              onPalette: compactPalette && ready ? openPalette : onPalette,
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
            )
          : null;
      return StudioApplicationFrame(
        projectName: controller.session.name,
        search: homeSearch,
        onSearch: onSearch ?? (_) {},
        canTest: onTest != null,
        busy: exportActive,
        onClose: onClose,
        headerActions: headerBar ? toolbar : null,
        active: activeSpace == 'interaction' ? 'story' : activeSpace,
        onDestination: (destination) {
          switch (destination) {
            case 'home':
              onHome?.call();
            case 'map':
              onMap();
            case 'resources':
              onResources();
            case 'story':
              onStory?.call();
            case 'pokemon':
              onPokemon();
            case 'test':
              onTest?.call();
            case 'gameExport':
              onExport();
          }
        },
        child: Column(
          children: [
            if (!headerBar && toolbar != null) toolbar,
            if (error != null) StudioNotice(error!, isError: true, maxLines: 2),
            if (error == null && movingHint != null)
              StudioNotice(movingHint!, maxLines: 2),
            Expanded(
              child:
                  resourceContent ??
                  (controller.loading ||
                          (project == null && error == null) ||
                          (project != null && visuals == null && error == null)
                      ? const Center(child: CircularProgressIndicator())
                      : !ready
                      ? MapCatalogueEmptyView(
                          controller: controller,
                          onActivate: onActivate,
                          onOrganize: onOrganizeMaps,
                        )
                      : MapWorkspaceEditorPane(
                          controller: controller,
                          document: doc,
                          project: project,
                          visuals: visuals!,
                          view: view!,
                          search: search,
                          generation: generation,
                          showNavigator: showNavigator,
                          showToolStrip: true,
                          showPaletteDock: showPaletteDock,
                          inspector: showInspector && !compactInspector
                              ? inspectorContent(() {})
                              : null,
                          onActivate: onActivate,
                          onOrganizeMaps: onOrganizeMaps,
                          onToolChanged: onToolChanged,
                          onChanged: onChanged,
                          onMoreTools: openPalette,
                          onResources: onResources,
                          onEnvironments: onEnvironments,
                          onBorders: onBorders,
                          onZoneDrawn: onZoneDrawn,
                          onContextMenu: onContextMenu,
                        )),
            ),
            if (visuals != null && activeSpace != 'gameExport')
              WorkspaceMapFooter(
                visuals: visuals!,
                map: doc?.current,
                showMapNotice: activeSpace == 'map',
              ),
          ],
        ),
      );
    },
  );
}
