import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/terrains/application/terrain_draft_controller.dart';
import '../../../features/terrains/domain/terrain_connections.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../resources/atlas_selection_view.dart';

class TerrainSourcePanel extends StatelessWidget {
  const TerrainSourcePanel({
    super.key,
    required this.model,
    required this.name,
    required this.image,
    required this.transform,
    required this.onChanged,
    required this.onAssign,
  });
  final TerrainDraftController model;
  final TextEditingController name;
  final Widget image;
  final TransformationController transform;
  final VoidCallback onChanged;
  final ValueChanged<TilesetSourceRect> onAssign;

  @override
  Widget build(BuildContext context) {
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
