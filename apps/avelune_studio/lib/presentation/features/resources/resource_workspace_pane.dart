import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';

import 'model_resource_library.dart';
import 'resource_library_screen.dart';
import 'resource_image_import.dart';
import 'decor_editor_screen.dart';
import 'environment_editor_screen.dart';
import 'environment_library.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'resource_border_lifecycle.dart';

import 'resource_management_bindings.dart';
import 'resource_pack_transfer_dialog.dart';
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
        openZones: {
          for (final document in n.workspace.documents.values)
            if (document.current.layers
                    .whereType<EnvironmentLayer>()
                    .expand((layer) => layer.content.areas)
                    .where((area) => area.presetId == n.environment!.id)
                    .length
                case final count when count > 0)
              document.current.name: count,
        },
        onClose: () {
          n.library.selectFamily(ResourceLibraryFamily.environments);
          n.showLibrary();
        },
      );
    } else if (n.page == ResourcePage.characters) {
      content = const SizedBox();
    } else if (n.page == ResourcePage.terrain &&
        n.terrain != null &&
        (n.terrain!.spatial || visuals is ResourceWorkspaceVisuals)) {
      final model = n.terrain!;
      final tileset = model.spatial
          ? null
          : project.tilesets.firstWhere((t) => t.id == model.atlas.tilesetId);
      final source = tileset?.source as ProjectRegularAtlasTilesetSource?;
      content = TerrainEditorScreen(
        key: ValueKey(model),
        controller: model,
        visuals: visuals,
        image: tileset == null
            ? const SizedBox.shrink()
            : (visuals as ResourceWorkspaceVisuals).atlasPreview(tileset.id),
        frameBuilder: (frame, size) => n.visuals.tileThumbnail(
          TileLayerPaletteEntry(
            tilesetId: tileset!.id,
            localTileId: frame.row * source!.columns + frame.column,
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
          if (n.importedSource case final source?)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: ResourceImportResult(
                source: source,
                canCreateDecor:
                    project.settings.dimension == ProjectDimension.twoD,
                onCreateDecor: () {
                  n.importedSource = null;
                  n.edit(source);
                },
                onPrepareTerrain: () {
                  n.importedSource = null;
                  n.prepareTerrain(source);
                },
                onDismiss: () {
                  n.importedSource = null;
                  n.showLibrary();
                },
              ),
            ),
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
              modelLibrary: (items) =>
                  ModelResourceLibrary(navigation: n, items: items),
              onImportModel: n.busy ? null : () => importStudioModel(n),
              onModelLightChanged: n.busy
                  ? null
                  : (model, light) async {
                      await n.mutate('model3d.configure', {
                        'modelId': model.id,
                        'light': light?.toJson(),
                      });
                    },
              onModelShadowsChanged: n.busy
                  ? null
                  : (model, enabled) => n.mutate('model3d.configure', {
                      'modelId': model.id,
                      'castsShadowsByDefault': enabled,
                    }),
              onExportPack: n.packTransfer?.exportAvailable != true || n.busy
                  ? null
                  : () => exportPack(context),
              onImportPack: n.packTransfer == null || n.busy
                  ? null
                  : () => importPack(context),
              project: project,
              openMaps: n.workspace.documents.values
                  .map((d) => d.current)
                  .toList(),
              visuals: visuals,
              state: n.library,
              targetMapName: n.workspace.active?.current.name,
              activeMapId: n.workspace.active?.current.id,
              onExportMarked: n.packTransfer?.exportAvailable != true || n.busy
                  ? null
                  : (items) => exportPack(context, selection: items),
              canUse: !n.busy,
              onUse: n.onUse,
              onEdit: n.edit,
              onUsages: (item) => openResourceUsages(context, n, item),
              onRemove: (item) => removeResourceOrTerrain(context, n, item),
              onDuplicate: (item) =>
                  duplicateResourceOrTerrain(context, n, item),
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
              onImportFor: (intent) => import(context, intent: intent),
              onCharacters: n.openCharacters,
              onBack: onBack,
              onCreateEnvironment: n.openEnvironment,
              environmentLibrary: (items) => EnvironmentLibrary(
                items: items,
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
        if (n.busy) const LinearProgressIndicator(),
        Expanded(
          child: AbsorbPointer(absorbing: n.busy, child: content),
        ),
      ],
    );
  }
}
