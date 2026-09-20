import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'resource_navigation.dart';
import 'resource_library_screen.dart';
import 'resource_image_import.dart';
import 'decor_editor_screen.dart';

class ResourceWorkspacePane extends StatelessWidget {
  const ResourceWorkspacePane({
    super.key,
    required this.navigation,
    required this.picker,
    required this.onBack,
  });
  final ResourceNavigation navigation;
  final PickResourceImage picker;
  final VoidCallback onBack;
  Future<void> import(BuildContext context) async {
    try {
      final image = await picker();
      if (image == null || !context.mounted) return;
      final settings = navigation.workspace.project!.settings;
      final request = await confirmImageImport(
        context,
        image,
        settings.tileWidth,
        settings.tileHeight,
      );
      if (request != null) await navigation.import(request);
    } catch (e) {
      navigation.error = e.toString();
      navigation.showLibrary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = navigation;
    final project = n.workspace.project!;
    final visuals = n.visuals;
    Widget content;
    if (n.page == ResourcePage.decor && n.decor != null) {
      content = DecorEditorScreen(
        key: ValueKey(n.decor),
        draft: n.decor!,
        project: project,
        visuals: visuals,
        onSave: n.saveDecor,
        onClose: n.showLibrary,
      );
    } else if (n.page == ResourcePage.terrain &&
        n.terrain != null &&
        visuals is ResourceWorkspaceVisuals) {
      final model = n.terrain!;
      final tileset = project.tilesets.firstWhere(
        (t) => t.id == model.atlas.tilesetId,
      );
      final source = tileset.source as ProjectRegularAtlasTilesetSource;
      content = TerrainEditorScreen(
        key: ValueKey(model),
        controller: model,
        image: (visuals as ResourceWorkspaceVisuals).atlasPreview(tileset.id),
        frameBuilder: (frame, size) => n.visuals.tileThumbnail(
          TileLayerPaletteEntry(
            tilesetId: tileset.id,
            localTileId: frame.row * source.columns + frame.column,
          ),
          size: size,
        ),
        onMutate: n.mutate,
        canPaint: project.maps.isNotEmpty,
        onUse: n.completeTerrainPublication,
        onClose: n.showLibrary,
      );
    } else {
      content = Column(
        children: [
          if (n.decor != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (n.decor != null)
                    StudioButton(
                      label: 'Reprendre le décor',
                      secondary: true,
                      onPressed: () {
                        n.openPage(ResourcePage.decor);
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: ResourceLibraryScreen(
              project: project,
              openMaps: n.workspace.documents.values
                  .map((d) => d.current)
                  .toList(),
              visuals: visuals,
              state: n.library,
              targetMapName: n.workspace.active?.current.name,
              canUse: !n.busy,
              onUse: n.onUse,
              onEdit: n.edit,
              onTerrain: n.prepareTerrain,
              terrainDrafts: n.pendingTerrainDrafts,
              onResumeTerrain: n.resumeTerrain,
              canEditTerrain: n.canEditTerrain,
              onImport: () => import(context),
              onBack: onBack,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (n.error != null) StudioNotice(n.error!, isError: true, maxLines: 2),
        if (n.busy) const LinearProgressIndicator(),
        Expanded(
          child: AbsorbPointer(absorbing: n.busy, child: content),
        ),
      ],
    );
  }
}
