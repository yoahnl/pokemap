import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../resources/atlas_selection_view.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';

class MapTilePalette extends StatelessWidget {
  const MapTilePalette({
    super.key,
    required this.sources,
    required this.knownTiles,
    required this.visuals,
    required this.view,
    required this.onChanged,
    required this.onAtlasChanged,
  });
  final List<ProjectTilesetEntry> sources;
  final List<TileLayerPaletteEntry> knownTiles;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final VoidCallback onAtlasChanged;

  void pick(TileLayerPaletteEntry tile) {
    view.tile = tile;
    view.brush = null;
    view.terrain = null;
    view.character = null;
    view.tool = StudioMapTool.paint;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const Text('Aucun atlas ne correspond à la recherche.');
    }
    final atlas =
        sources.where((s) => s.id == view.paletteAtlasId).firstOrNull ??
        sources.where((s) => s.id == view.tile?.tilesetId).firstOrNull ??
        sources
            .where((s) => knownTiles.any((tile) => tile.tilesetId == s.id))
            .firstOrNull ??
        sources.first;
    final source = atlas.source;
    final selected = view.tile?.tilesetId == atlas.id
        ? view.tile!.localTileId
        : 0;
    final ids = source is ProjectImageCollectionTilesetSource
        ? source.tileDefinitions.map((t) => t.tileId).toList()
        : knownTiles
              .where((t) => t.tilesetId == atlas.id)
              .map((t) => t.localTileId)
              .toSet()
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('palette-atlas-${atlas.id}'),
          initialValue: atlas.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Atlas'),
          items: [
            for (final s in sources)
              DropdownMenuItem(
                value: s.id,
                child: Text(
                  s.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) {
            view.paletteAtlasId = id;
            onAtlasChanged();
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              source is ProjectRegularAtlasTilesetSource &&
                  source.columns > 0 &&
                  source.rows > 0 &&
                  visuals is ResourceWorkspaceVisuals
              ? AtlasSelectionView(
                  compact: true,
                  key: ValueKey('palette-atlas-view-${atlas.id}'),
                  transformationController: view.paletteAtlasTransforms
                      .putIfAbsent(atlas.id, TransformationController.new),
                  initiallyFitted: view.fittedPaletteAtlases.contains(atlas.id),
                  onFitted: () => view.fittedPaletteAtlases.add(atlas.id),
                  source: source,
                  selected: TilesetSourceRect(
                    x: selected % source.columns,
                    y: selected ~/ source.columns,
                  ),
                  image: (visuals as ResourceWorkspaceVisuals).atlasPreview(
                    atlas.id,
                  ),
                  singleCell: true,
                  onSelected: (r) => pick(
                    TileLayerPaletteEntry(
                      tilesetId: atlas.id,
                      localTileId: r.y * source.columns + r.x,
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (source is! ProjectImageCollectionTilesetSource)
                      const Text(
                        'Source incomplète : tuiles déjà utilisées sur cette carte.',
                      ),
                    Expanded(
                      child: GridView.builder(
                        key: const ValueKey('tile-palette'),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemCount: ids.length,
                        itemBuilder: (context, i) {
                          final tile = TileLayerPaletteEntry(
                            tilesetId: atlas.id,
                            localTileId: ids[i],
                          );
                          return StudioPaletteCard(
                            name: 'Tuile ${ids[i] + 1}',
                            preview: visuals.tileThumbnail(tile, size: 72),
                            selected: view.tile == tile,
                            onTap: () => pick(tile),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
