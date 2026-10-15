import 'package:map_core/map_core.dart';
import 'map_catalog_fixture.dart';

MapData healingMap() => catalogMap('route').copyWith(entities: [
      const MapEntity(
          id: 'balls',
          name: 'Balls',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 2, y: 1),
          blocksMovement: false,
          properties: {'preserved': 'yes'})
    ]);
MapEntityHealingDisplayData healingPayload() => MapEntityHealingDisplayData(
    variantElementIds: [for (var n = 1; n <= 6; n++) 'healing-$n']);

ProjectManifest healingProject() => ProjectManifest(
      name: 'Centre',
      maps: const [
        ProjectMapEntry(
          id: 'route',
          name: 'Centre',
          relativePath: 'maps/route.json',
        ),
      ],
      tilesets: [
        for (var sheet = 1; sheet <= 2; sheet++)
          ProjectTilesetEntry(
            id: 'healing-sheet-$sheet',
            name: 'Boules $sheet',
            relativePath: 'tilesets/healing-$sheet.png',
            source: ProjectRegularAtlasTilesetSource(
              assetId: 'healing-sheet-$sheet',
              pixelWidth: 256,
              pixelHeight: 192,
              tileWidth: 64,
              tileHeight: 48,
            ),
          ),
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'healing', name: 'Healing')
      ],
      elements: [
        for (var i = 1; i <= 6; i++)
          ProjectElementEntry(
            id: 'healing-$i',
            name: 'Boules $i',
            tilesetId: 'healing-sheet-${i <= 3 ? 1 : 2}',
            categoryId: 'healing',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: (i - 1) % 3 + 1),
                durationMs: 200,
              ),
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 1, y: (i - 1) % 3 + 1),
                durationMs: 200,
              ),
            ],
          ),
      ],
    );
