import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/resources/application/model_resource_rules.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_example.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_empty_state.dart';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/coordination/resource_workspace_routing.dart';

import '../../../features/resources/coordination/resource_workspace_import_workflow.dart';

import 'model_resource_library.dart';
import 'resource_library_screen.dart';
import 'resource_image_import.dart';

import 'resource_management_bindings.dart';
import 'resource_terrain_lifecycle.dart';

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
    final transfer = n.packTransfer;
    final packResolution = resourcePackResolution(transfer);
    final view = resourceWorkspaceView(
      n.page,
      hasDecor: n.decor != null,
      hasEnvironment: n.environment != null,
      hasTerrain: n.terrain != null,
      terrainSpatial: n.terrain?.spatial ?? false,
      hasResourceVisuals: visuals is ResourceWorkspaceVisuals,
    );
    Widget content;
    if (view == ResourceWorkspaceView.decorUnavailable) {
      content = StudioEmptyState(
        key: const ValueKey('resource-decor-workshop-unavailable-state'),
        title: 'Atelier des décors indisponible',
        description: 'L’atelier est temporairement indisponible. Votre préparation et les sources sont conservées. Les décors existants restent accessibles dans le catalogue.',
        icon: Icons.edit_off_outlined,
        action: StudioButton(
          key: const ValueKey('resource-decor-return-to-catalog'),
          label: 'Retour au catalogue',
          secondary: true,
          onPressed: n.showLibrary,
        ),
      );
    } else if (view == ResourceWorkspaceView.environmentUnavailable) {
      content = StudioEmptyState(
        key: const ValueKey('resource-environment-workshop-unavailable-state'),
        title: 'Atelier des environnements indisponible',
        description: 'L’édition, la duplication et la suppression des environnements sont temporairement indisponibles. Votre préparation en cours est conservée. Les environnements publiés restent dans le catalogue.',
        icon: Icons.edit_off_outlined,
        action: StudioButton(
          key: const ValueKey('resource-environment-return-to-catalog'),
          label: 'Retour au catalogue',
          secondary: true,
          onPressed: () {
            n.library.atelierVisible = false;
            n.showLibrary();
          },
        ),
      );
    } else if (view == ResourceWorkspaceView.characters) {
      content = const SizedBox();
    } else if (view == ResourceWorkspaceView.terrainEditor) {
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
            localTileId: regularAtlasLocalTileId(
              row: frame.row,
              column: frame.column,
              source: source!,
            ),
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
                canCreateDecor: resourceImportCanCreateDecor(
                  project.settings.dimension,
                ),
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
                    const StudioNotice(
                      'La préparation du décor est conservée. L’atelier est temporairement indisponible.',
                      key: ValueKey('resource-decor-draft-preserved'),
                    ),
                  if (n.environment != null)
                    const StudioNotice(
                      'La préparation de l’environnement est conservée. L’atelier est temporairement indisponible.',
                      key: ValueKey('resource-environment-draft-preserved'),
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
                      await n.mutate(
                        'model3d.configure',
                        modelConfigurePayload(model.id, modelLightFields(light)),
                      );
                    },
              onModelShadowsChanged: n.busy
                  ? null
                  : (model, enabled) => n.mutate(
                      'model3d.configure',
                      modelConfigurePayload(model.id, modelShadowFields(enabled)),
                    ),
              project: project,
              openMaps: n.workspace.documents.values
                  .map((d) => d.current)
                  .toList(),
              visuals: visuals,
              state: n.library,
              targetMapName: n.workspace.active?.current.name,
              activeMapId: n.workspace.active?.current.id,
              canUse: !n.busy,
              onUse: n.onUse,
              onEdit: n.edit,
              onUsages: (item) => openResourceUsages(context, n, item),
              onRemove: (item) => removeResourceOrTerrain(context, n, item),
              onDuplicate: (item) =>
                  duplicateResourceOrTerrain(context, n, item),
              onTerrain: n.prepareTerrain,
              terrainDrafts: n.pendingTerrainDrafts,
              onResumeTerrain: n.resumeTerrain,
              canResumeTerrain: (draft) => terrainDraftResumable(project, draft),
              terrainDraftStatus: (draft) => terrainPreparationStatus(n, draft),
              onManageTerrainDraft: (draft, action) =>
                  manageTerrainPreparation(context, n, draft, action),
              canEditTerrain: n.canEditTerrain,
              onImport: () => import(context),
              onImportFor: (intent) => import(context, intent: intent),
              onCharacters: n.openCharacters,
              onBack: onBack,
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (transfer != null && packResolution != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioNotice(
                  packResolution.message,
                  key: ValueKey(packResolution.noticeKey),
                ),
                if (transfer.error != null)
                  StudioNotice(transfer.error!, isError: true),
                const SizedBox(height: 8),
                StudioButton(
                  key: ValueKey(packResolution.actionKey),
                  label: packResolution.label,
                  secondary: true,
                  onPressed: transfer.operationActive
                      ? null
                      : packResolution.resolve,
                ),
              ],
            ),
          ),
        if (n.error != null) StudioNotice(n.error!, isError: true, maxLines: 2),
        if (n.busy &&
            (packResolution == null || transfer?.operationActive == true))
          const LinearProgressIndicator(),
        Expanded(
          child: AbsorbPointer(absorbing: n.busy, child: content),
        ),
      ],
    );
  }
}
