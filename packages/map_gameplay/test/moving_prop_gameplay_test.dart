import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('an autonomous closed prop blocks its own footprint', () {
    final map = MapData.fromJson({
      ...const MapData(
        id: 'room',
        name: 'Room',
        size: GridSize(width: 10, height: 10),
        layers: [MapLayer.tile(id: 'art', name: 'Art', cells: [])],
        placedElements: [
          MapPlacedElement(
            id: 'gate-art',
            layerId: 'art',
            elementId: 'gate',
            pos: GridPos(x: 2, y: 2),
            applyCollision: false,
            properties: {
              pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
            },
          ),
        ],
      ).toJson(),
      'movingProps': [
        {
          'id': 'gate',
          'placedElementId': 'gate-art',
          'closedPositionPx': {'x': 64, 'y': 64},
          'openPositionPx': {'x': 128, 'y': 64},
          'collisionRect': {
            'leftPx': 0,
            'topPx': 0,
            'widthPx': 32,
            'heightPx': 32,
          },
          'initialState': 'closed',
        },
      ],
    });
    final project = ProjectManifest(
      name: 'Props',
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      elements: const [
        ProjectElementEntry(
          id: 'gate',
          name: 'Gate',
          tilesetId: 'tiles',
          categoryId: 'props',
          frames: [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            ),
          ],
        ),
      ],
    );
    final world = GameplayWorldState.initial(
      map: map,
      project: project,
      playerPos: const GridPos(x: 0, y: 0),
      tileWidth: 32,
      tileHeight: 32,
    );
    expect(
      world.worldStaticObstaclesCollidePixelRect(
        const PixelRect(leftPx: 65, topPx: 65, widthPx: 2, heightPx: 2),
      ),
      isTrue,
    );
  });
}
