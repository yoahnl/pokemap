import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'resource_navigation.dart';
import 'model_resource_library.dart';
import 'resource_library_screen.dart';
import 'resource_image_import.dart';
import 'decor_editor_screen.dart';
import 'environment_editor_screen.dart';
import 'environment_library.dart';
import 'resource_catalog.dart';
import 'resource_border_lifecycle.dart';
import 'resource_character_lifecycle.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import '../characters/character_studio_page.dart';
import 'resource_character_portrait_import.dart';
import 'resource_character_animation_import.dart';
import 'resource_management_bindings.dart';
import 'resource_reconciliation_notice.dart';
import 'resource_lifecycle_bindings.dart';
import 'resource_terrain_lifecycle.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
part 'resource_workspace_actions.dart';

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
    } else if (n.page == ResourcePage.environment && n.environment != null) {
      content = EnvironmentEditorScreen(
        key: ValueKey(n.environment),
        draft: n.environment!,
        project: project,
        visuals: visuals,
        onSave: n.saveEnvironment,
        onChanged: n.changed,
        onDiscard: n.discardEnvironment,
        onEditDecor: (element) => n.openElement(element, edit: true),
        onClose: () {
          n.library.selectFamily(ResourceLibraryFamily.environments);
          n.showLibrary();
        },
      );
    } else if (n.page == ResourcePage.characters) {
      content = CharacterStudioPage(
        project: project,
        visuals: visuals,
        controller: n.characters,
        onBack: n.showLibrary,
        onRemove: (character) => removeStudioCharacter(context, n, character),
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
          if (n.decor != null || n.environment != null)
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
                  if (n.environment != null)
                    StudioButton(
                      label: 'Reprendre l’environnement',
                      secondary: true,
                      onPressed: () => n.openPage(ResourcePage.environment),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ResourceLibraryScreen(
              modelLibrary: ModelResourceLibrary(navigation: n),
              onImportModel: n.busy ? null : () => importStudioModel(n),
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
              onInformation: (item) =>
                  renameResourceOrTerrain(context, n, item),
              onMove: (item) => moveResource(context, n, item),
              onUsages: (item) => openResourceUsages(context, n, item),
              onReplace: (item) =>
                  replaceResourceImage(context, n, item, picker),
              onRemove: (item) => removeResourceOrTerrain(context, n, item),
              onDuplicate: (item) =>
                  duplicateResourceOrTerrain(context, n, item),
              onManageContainers: (family) =>
                  manageResourceContainers(context, n, family),
              onTerrain: n.prepareTerrain,
              onCreateBorder: () => openBorderPreparation(context, n),
              onResumeBorder: (record) =>
                  openBorderPreparation(context, n, record),
              onManageBorder: (record, action) =>
                  manageBorderResource(context, n, record, action),
              terrainDrafts: n.pendingTerrainDrafts,
              onResumeTerrain: n.resumeTerrain,
              canResumeTerrain: (draft) =>
                  terrainDraftCompatibilityProblem(project, draft) == null,
              terrainDraftStatus: (draft) => terrainPreparationStatus(n, draft),
              onManageTerrainDraft: (draft, action) =>
                  manageTerrainPreparation(context, n, draft, action),
              canEditTerrain: n.canEditTerrain,
              onImport: () => import(context),
              onCharacters: n.openCharacters,
              onBack: onBack,
              onCreateEnvironment: n.openEnvironment,
              environmentLibrary: EnvironmentLibrary(
                project: project,
                visuals: visuals,
                onEdit: n.openEnvironment,
                onDuplicate: n.duplicateEnvironment,
                onRemove: (preset) => removeEnvironment(context, preset),
                onDraw: (preset) => n.drawEnvironment?.call(preset),
                canDraw: project.maps.isNotEmpty && n.drawEnvironment != null,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (n.error != null) StudioNotice(n.error!, isError: true, maxLines: 2),
        if (n.pendingReceipt != null)
          ResourceReconciliationNotice(navigation: n),
        if (n.busy) const LinearProgressIndicator(),
        Expanded(
          child: AbsorbPointer(absorbing: n.busy, child: content),
        ),
      ],
    );
  }
}
