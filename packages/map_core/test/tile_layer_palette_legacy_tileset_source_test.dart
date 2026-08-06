import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// A project authored before tilesets declared a `source` must stay paintable.
///
/// The canonical multi-tileset palette validation verifies a palette entry's
/// local tile id against its tileset extent. When the tileset declares no
/// source that extent is simply unknown, which is not the same as the tile
/// being invalid — rejecting it strands every pre-existing project.
void main() {
  group('tile layer palette against a source-less tileset', () {
    test('accepts a palette entry when the tileset declares no source', () {
      expect(
        () => MapValidator.validate(_map, projectDialogueContext: _manifest),
        returnsNormally,
      );
    });

    test('still rejects a tile id outside a declared atlas extent', () {
      const manifest = ProjectManifest(
        name: 'Declared extent',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'furniture',
            name: 'Furniture',
            relativePath: 'assets/furniture.png',
            source: ProjectTilesetSource.regularAtlas(
              assetId: 'asset_furniture',
              pixelWidth: 64,
              pixelHeight: 64,
              tileWidth: 32,
              tileHeight: 32,
            ),
          ),
        ],
      );

      expect(
        () => MapValidator.validate(_map, projectDialogueContext: manifest),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

/// One 2x2 tile layer whose only palette entry points at local tile 174 —
/// the same shape as `l_tile_tuiles_6` in the Hanazuki guesthouse room.
const _map = MapData(
  id: 'room',
  name: 'Room',
  version: ProjectVersion.v6,
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[
    TileLayer(
      id: 'l_tile_tuiles_6',
      name: 'Tuiles',
      palette: <TileLayerPaletteEntry>[
        TileLayerPaletteEntry(tilesetId: 'furniture', localTileId: 174),
      ],
      cells: <int>[1, 0, 0, 1],
    ),
  ],
);

const _manifest = ProjectManifest(
  name: 'Legacy project',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'furniture',
      name: 'Furniture',
      relativePath: 'assets/furniture.png',
    ),
  ],
);
