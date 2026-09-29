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
import 'border_creation_dialog.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import '../characters/character_studio_page.dart';
import 'resource_character_portrait_import.dart';
import 'resource_character_animation_import.dart';

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

  Future<void> importCharacterSheet(BuildContext context) async {
    final image = await picker();
    if (image == null || !context.mounted) return;
    final n = navigation;
    if (image.width % 3 != 0 || image.height % 4 != 0) {
      n.setImportError(
        'La planche doit contenir 3 colonnes et 4 rangées de même taille.',
      );
      return;
    }
    final settings = n.workspace.project!.settings;
    final poseWidth = image.width ~/ 3;
    final poseHeight = image.height ~/ 4;
    if (poseWidth % settings.tileWidth != 0 ||
        poseHeight % settings.tileHeight != 0 ||
        poseWidth < settings.tileWidth * 2 ||
        poseHeight < settings.tileHeight * 2) {
      n.setImportError(
        'Chaque pose doit occuper au moins deux cases par axe et un nombre entier de cases '
        '(${settings.tileWidth} × ${settings.tileHeight} px).',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer une planche de personnage'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: Image.memory(
                  image.bytes,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${image.width} × ${image.height} px · '
                '3 poses × 4 directions · '
                '${image.width ~/ 3} × ${image.height ~/ 4} px par pose',
              ),
              const SizedBox(height: 8),
              const Text(
                'Un nouveau personnage sera créé. '
                'Les personnages et brouillons existants restent intacts.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    n.error = null;
    n.setImportBusy(true);
    try {
      final receipt = await n.port.importImage(
        ResourceImageImport(
          sourcePath: image.path,
          name: image.name,
          tileWidth: image.width ~/ 3,
          tileHeight: image.height ~/ 4,
        ),
      );
      await n.accept(receipt);
      final tilesetId = receipt.createdTilesetId!;
      if (!await n.characters.create(
        image.name,
        tilesetId,
        frameWidth: poseWidth ~/ settings.tileWidth,
        frameHeight: poseHeight ~/ settings.tileHeight,
      )) {
        n.error =
            'La planche est dans Images, mais le personnage n’a pas été '
            'créé : ${n.characters.error}';
      } else {
        final source = n.workspace.project!.tilesets
            .firstWhere((entry) => entry.id == tilesetId)
            .source;
        if (source is ProjectRegularAtlasTilesetSource) {
          n.characters.assignClassicSheet(source);
        }
        n.openCharacters();
      }
    } catch (failure) {
      n.error = '$failure';
    } finally {
      n.setImportBusy(false);
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
    } else if (n.page == ResourcePage.characters) {
      content = CharacterStudioPage(
        project: project,
        visuals: visuals,
        controller: n.characters,
        onBack: n.showLibrary,
        onImport: () => importCharacterSheet(context),
        port: n.port,
        onImportPortrait: (stateId) =>
            importCharacterPortrait(context, n, picker, stateId),
        onImportAnimation: (state, direction) =>
            importCharacterAnimation(context, n, picker, state, direction),
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
              onCreateBorder: () => showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => BorderCreationDialog(
                  navigation: n,
                  project: n.workspace.project!,
                  visuals: visuals,
                ),
              ),
              onResumeBorder: (record) => showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => BorderCreationDialog(
                  navigation: n,
                  project: n.workspace.project!,
                  visuals: visuals,
                  initialRecord: record,
                ),
              ),
              terrainDrafts: n.pendingTerrainDrafts,
              onResumeTerrain: n.resumeTerrain,
              canEditTerrain: n.canEditTerrain,
              onImport: () => import(context),
              onCharacters: n.openCharacters,
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
