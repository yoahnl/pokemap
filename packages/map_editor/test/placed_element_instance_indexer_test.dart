import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_instance_indexer.dart';

void main() {
  group('PlacedElementInstanceIndexer', () {
    test(
        'préserve les placements générés par environnement quand le TileLayer cible est vide',
        () {
      final mask = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: const [true, true, true, true],
      );
      final map = MapData(
        id: 'forest',
        name: 'Forest',
        size: const GridSize(width: 2, height: 2),
        layers: [
          MapLayer.environment(
            id: 'environment',
            name: 'Environment',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: [
                EnvironmentArea(
                  id: 'area1',
                  name: 'Area',
                  presetId: 'forest',
                  mask: mask,
                  seed: 1,
                  generatedPlacementIds: const ['generated_tree_1'],
                ),
              ],
            ),
          ),
          MapLayer.tile(
            id: 'decor',
            name: 'Decor',
            tilesetId: 'nature',
            tiles: List<int>.filled(4, 0),
          ),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'generated_tree_1',
            layerId: 'decor',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'nature',
            name: 'Nature',
            relativePath: 'tilesets/nature.png',
          ),
        ],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'nature',
            categoryId: 'nature',
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
        ],
      );

      final synced = const PlacedElementInstanceIndexer().syncAllTileLayers(
        map: map,
        project: manifest,
      );

      expect(synced.placedElements.map((entry) => entry.id),
          contains('generated_tree_1'));
      final area =
          (synced.layers.first as EnvironmentLayer).content.areas.single;
      expect(area.generatedPlacementIds, ['generated_tree_1']);
    });
  });
}
