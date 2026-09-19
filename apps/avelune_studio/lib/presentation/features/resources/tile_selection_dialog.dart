import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'atlas_selection_view.dart';

Future<TileLayerPaletteEntry?> chooseResourceTile(
  BuildContext context,
  ProjectTilesetEntry tileset,
  MapWorkspaceVisuals visuals,
) async {
  final source = tileset.source;
  if (source is! ProjectRegularAtlasTilesetSource ||
      visuals is! ResourceWorkspaceVisuals) {
    final tiles = source is ProjectImageCollectionTilesetSource
        ? source.tileDefinitions.map((t) => t.tileId).toList()
        : [0];
    return showDialog<TileLayerPaletteEntry>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 550,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 90,
            ),
            itemCount: tiles.length,
            itemBuilder: (context, i) {
              final tile = TileLayerPaletteEntry(
                tilesetId: tileset.id,
                localTileId: tiles[i],
              );
              return InkWell(
                onTap: () => Navigator.pop(context, tile),
                child: visuals.tileThumbnail(tile, size: 64),
              );
            },
          ),
        ),
      ),
    );
  }
  var rect = const TilesetSourceRect(x: 0, y: 0);
  return showDialog<TileLayerPaletteEntry>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => Dialog(
        child: SizedBox(
          width: 800,
          height: 580,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Choisir une tuile · ${tileset.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Expanded(
                  child: AtlasSelectionView(
                    source: source,
                    selected: rect,
                    image: (visuals as ResourceWorkspaceVisuals).atlasPreview(
                      tileset.id,
                    ),
                    singleCell: true,
                    onSelected: (r) => set(() => rect = r),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    StudioButton(
                      label: 'Annuler',
                      secondary: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    StudioButton(
                      label: 'Utiliser sur la carte',
                      onPressed: () => Navigator.pop(
                        context,
                        TileLayerPaletteEntry(
                          tilesetId: tileset.id,
                          localTileId: rect.y * source.columns + rect.x,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
