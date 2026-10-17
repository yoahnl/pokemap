import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/terrains/application/terrain_draft_controller.dart';
import '../../../features/terrains/domain/terrain_connections.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../resources/atlas_selection_view.dart';
import 'terrain_scratch_view.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_source_list.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'terrain_model_part_controls.dart';

class TerrainSourcePanel extends StatelessWidget {
  const TerrainSourcePanel({
    super.key,
    required this.model,
    required this.name,
    required this.image,
    required this.transform,
    required this.onChanged,
    required this.onAssign,
    required this.frameBuilder,
    this.selectedSource,
    this.visuals,
    this.onAssignModel,
  });
  final TerrainDraftController model;
  final TextEditingController name;
  final Widget image;
  final TransformationController transform;
  final VoidCallback onChanged;
  final ValueChanged<TilesetSourceRect> onAssign;
  final TerrainFrameBuilder frameBuilder;
  final TilesetSourceRect? selectedSource;
  final MapWorkspaceVisuals? visuals;
  final ValueChanged<ProjectModel3dEntry>? onAssignModel;

  @override
  Widget build(BuildContext context) {
    if (model.spatial) {
      final part = model.partFor(model.selectedRule);
      final source = part?.source;
      final selected = source is SmartTileModel3dSource ? source.modelId : null;
      final selectedModel = model.manifest.models3d
          .where((entry) => entry.id == selected)
          .firstOrNull;
      return StudioPanel(
        title: 'Ressource source',
        compact: true,
        children: [
          TextField(
            key: const ValueKey('terrain-name'),
            controller: name,
            decoration: const InputDecoration(labelText: 'Nom du terrain'),
            onChanged: (value) {
              model.rename(value);
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Raccord sélectionné : ${model.uniform ? 'Pièce unitaire' : terrainConnectionNames[model.selectedRule]}',
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisissez le modèle à placer dans chaque case peinte. Le sol reste indépendant.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visuals == null
                ? const StudioNotice('Aperçu indisponible')
                : ResourceSourceList(
                    project: model.manifest,
                    visuals: visuals!,
                    activeMapId: model.manifest.resourceLibraryCatalog
                        .entryFor('smartTilePreset', model.draft.targetPresetId)
                        ?.mapId,
                    selectedIdentity: selected == null
                        ? null
                        : 'model3d:$selected',
                    items: resourceCatalog(model.manifest)
                        .where((item) => item.model3d != null)
                        .toList(),
                    onPick: (item) {
                      if (onAssignModel != null) {
                        onAssignModel!(item.model3d!);
                      } else {
                        model.assignModel(item.model3d!);
                        onChanged();
                      }
                    },
                  ),
          ),
          if (source is SmartTileModel3dSource && part != null) ...[
            const SizedBox(height: 12),
            if (selectedModel != null) ...[
              StudioSelect(
                key: const ValueKey('terrain-model-animation'),
                label: 'Animation de la pièce',
                value: source.animationIndex?.toString() ?? '',
                options: {
                  '': 'Aucune',
                  for (final clip in selectedModel.inspection.animations)
                    '${clip.index}': clip.name,
                },
                onChanged: selectedModel.inspection.animations.isEmpty
                    ? null
                    : (value) {
                        model.assignModel(
                          selectedModel,
                          scale: source.scale,
                          offsetX: source.offsetX,
                          offsetY: source.offsetY,
                          offsetZ: source.offsetZ,
                          quarterTurns: part.transform.quarterTurns,
                          animationIndex: value.isEmpty
                              ? null
                              : int.parse(value),
                          changeAnimation: true,
                        );
                        onChanged();
                      },
              ),
              if (selectedModel.inspection.animations.isEmpty)
                const StudioNotice('Ce modèle ne contient aucune animation.'),
              const SizedBox(height: 8),
            ],
            TerrainModelPartControls(
              key: ValueKey('model-part-${model.selectedRule}'),
              part: part,
              onApply: (scale, offsetX, offsetY, offsetZ, turns) {
                model.assignModel(
                  model.manifest.models3d.firstWhere(
                    (model) => model.id == selected,
                  ),
                  scale: scale,
                  offsetX: offsetX,
                  offsetY: offsetY,
                  offsetZ: offsetZ,
                  quarterTurns: turns,
                );
                onChanged();
              },
            ),
            if (!model.uniform)
              StudioButton(
                label: 'Utiliser pour tous les raccords',
                secondary: true,
                onPressed: () {
                  model.assignModel(
                    model.manifest.models3d.firstWhere(
                      (model) => model.id == selected,
                    ),
                    all: true,
                    scale: source.scale,
                    offsetX: source.offsetX,
                    offsetY: source.offsetY,
                    offsetZ: source.offsetZ,
                    quarterTurns: part.transform.quarterTurns,
                  );
                  onChanged();
                },
              ),
          ],
        ],
      );
    }
    final tileset = model.manifest.tilesets
        .where((t) => t.id == model.atlas.tilesetId)
        .firstOrNull;
    final source = tileset?.source;
    final frame = model.frameFor(model.selectedRule);
    return StudioPanel(
      title: 'Image source',
      compact: true,
      children: [
        TextField(
          key: const ValueKey('terrain-name'),
          controller: name,
          decoration: const InputDecoration(labelText: 'Nom du terrain'),
          onChanged: (value) {
            model.rename(value);
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        Text(
          tileset?.name ?? 'Image source absente',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          'Raccord sélectionné : ${terrainConnectionNames[model.selectedRule]}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          frame == null
              ? 'Choisissez sa case dans l’image.'
              : 'Cliquez sur une autre case pour le remplacer.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (selectedSource case final selected?) ...[
          const SizedBox(height: 8),
          LongPressDraggable<TilesetSourceRect>(
            data: selected,
            feedback: Material(
              elevation: 5,
              child: frameBuilder(
                SmartTileFrameRef(
                  atlasId: model.atlas.id,
                  column: selected.x,
                  row: selected.y,
                ),
                56,
              ),
            ),
            child: ListTile(
              dense: true,
              leading: frameBuilder(
                SmartTileFrameRef(
                  atlasId: model.atlas.id,
                  column: selected.x,
                  row: selected.y,
                ),
                40,
              ),
              title: const Text('Pièce prête à poser'),
              subtitle: const Text('Glissez-la sur le patron'),
            ),
          ),
        ],
        Expanded(
          child: source is ProjectRegularAtlasTilesetSource
              ? AtlasSelectionView(
                  source: source,
                  selected: TilesetSourceRect(
                    x: frame?.column ?? 0,
                    y: frame?.row ?? 0,
                  ),
                  showSelection: frame != null,
                  alignTop: true,
                  transformationController: transform,
                  image: image,
                  singleCell: true,
                  onSelected: onAssign,
                )
              : const Center(
                  child: Text(
                    'Cette source ne propose pas de grille éditable.',
                  ),
                ),
        ),
      ],
    );
  }
}
