import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

final class MovingPlatformFixture {
  MovingPlatformFixture(
      {int distance = 1,
      int quarterTurns = 0,
      MovingPlatformLattice? lattice}) {
    definition = MovingPlatformDefinition(
        id: 'bridge',
        placedElementId: 'bridge-art',
        initialPose: MovingPlatformPose(
            leftPx: 64, topPx: 64, quarterTurns: quarterTurns),
        translationDistanceCells: distance,
        lattice: lattice ??
            MovingPlatformLattice(
                widthPx: 32,
                heightPx: 32,
                originLeftPx: 0,
                originTopPx: 0,
                cellOffsetLeftPx: 0,
                cellOffsetTopPx: 0),
        terrainLayerIds: {
          'magma'
        },
        variants: [
          for (var index = 0; index < 4; index++)
            MovingPlatformVariant(
              elementId: 'platform-$index',
              anchorOffsetPx: GridPos(x: index * 2, y: index * 3),
              supportCells: const [GridPos(x: 0, y: 0)],
              clearanceCells: const [GridPos(x: 0, y: 0)],
              rotationClearanceCells: const [GridPos(x: 0, y: 0)],
              forwardClearanceCells: const [GridPos(x: 0, y: 0)],
              backwardClearanceCells: const [GridPos(x: 0, y: 0)],
            )
        ],
        travelCells: [
          for (var y = 0; y < 10; y++)
            for (var x = 0; x < 10; x++) GridPos(x: x, y: y)
        ]);
    map = MapData(
        id: 'gym',
        name: 'Gym',
        size: const GridSize(width: 10, height: 10),
        layers: [
          terrain('magma')
        ],
        movingPlatforms: [
          definition
        ],
        placedElements: const [
          MapPlacedElement(
              id: 'bridge-art',
              layerId: 'magma',
              elementId: 'platform-0',
              pos: GridPos(x: 2, y: 2),
              applyCollision: false,
              properties: {
                pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
              }),
        ]);
    project = ProjectManifest(
        name: 'Platforms',
        maps: const [],
        settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
        tilesets: const [
          ProjectTilesetEntry(
              id: 'tiles',
              name: 'Tiles',
              relativePath: 'tiles.png',
              source: ProjectRegularAtlasTilesetSource(
                  assetId: 'tiles',
                  pixelWidth: 32,
                  pixelHeight: 32,
                  tileWidth: 32,
                  tileHeight: 32,
                  tileProperties: [
                    VisualTileProperty(tileId: 0, passable: false)
                  ]))
        ],
        elements: [
          for (var index = 0; index < 4; index++)
            ProjectElementEntry(
                id: 'platform-$index',
                name: 'Platform',
                tilesetId: 'tiles',
                categoryId: 'platform',
                frames: const [
                  TilesetVisualFrame(
                      source:
                          TilesetSourceRect(x: 0, y: 0, width: 1, height: 2))
                ])
        ]);
    state = initializeMovingPlatformWorldState(
        map: map, worldState: const MovingPlatformWorldState.empty());
  }

  late final MovingPlatformDefinition definition;
  late final MapData map;
  late final ProjectManifest project;
  late final MovingPlatformWorldState state;

  static TileLayer terrain(String id, {int? blockedIndex}) =>
      MapLayer.tile(id: id, name: id, palette: const [
        TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 0)
      ], cells: [
        for (var index = 0; index < 100; index++)
          blockedIndex == null || index == blockedIndex ? 1 : 0
      ]) as TileLayer;

  GameplayWorldState world(
      {MapData? map,
      MovingPlatformWorldState? state,
      GridPos player = const GridPos(x: 2, y: 2)}) {
    final selectedMap = map ?? this.map;
    final selectedState = state ?? this.state;
    return GameplayWorldState.initial(
        map: applyMovingPlatformWorldStateToMap(
            map: selectedMap,
            worldState: selectedState,
            tileSize: const PixelSize(width: 32, height: 32)),
        project: project,
        movingPlatformWorldState: selectedState,
        playerPos: player,
        tileWidth: 32,
        tileHeight: 32);
  }
}
