import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

final class MovingPropFixture {
  MovingPropFixture(
      {List<MovingPropDefinition>? props,
      List<MapEntity> entities = const [],
      Set<int> walls = const {}}) {
    final definitions = props ?? [prop('gate', 64, 64, 128, 64)];
    map = MapData(
        id: 'room',
        name: 'Room',
        size: const GridSize(width: 10, height: 10),
        layers: [
          MapLayer.tile(id: 'art', name: 'Art', cells: List.filled(100, 0)),
          MapLayer.collision(
              id: 'walls',
              name: 'Walls',
              collisions: [for (var i = 0; i < 100; i++) walls.contains(i)]),
        ],
        movingProps: definitions,
        entities: entities,
        placedElements: [
          for (final prop in definitions)
            MapPlacedElement(
                id: prop.placedElementId,
                layerId: 'art',
                elementId: 'gate',
                pos: const GridPos(x: 0, y: 0),
                applyCollision: false,
                properties: const {
                  pokemapPlacementOriginProperty:
                      pokemapPlacementOriginAuthored,
                }),
        ]);
  }

  late final MapData map;
  final project = const ProjectManifest(
      name: 'Props',
      maps: [],
      tilesets: [],
      settings: ProjectSettings(tileWidth: 32, tileHeight: 32),
      elements: [
        ProjectElementEntry(
            id: 'gate',
            name: 'Gate',
            tilesetId: 'tiles',
            categoryId: 'props',
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
            ]),
      ]);

  GameplayWorldState world(
          {GridPos player = const GridPos(x: 0, y: 0),
          MovingPropWorldState? state,
          Map<String, PixelOffset> positions = const {}}) =>
      GameplayWorldState.initial(
          map: map,
          project: project,
          playerPos: player,
          movingPropWorldState: state,
          movingPropPositions: positions,
          tileWidth: 32,
          tileHeight: 32);

  static MovingPropDefinition prop(String id, int x, int y, int toX, int toY,
          {int width = 32, int height = 32}) =>
      MovingPropDefinition(
          id: id,
          placedElementId: '$id-art',
          closedPositionPx: PixelOffset(x: x, y: y),
          openPositionPx: PixelOffset(x: toX, y: toY),
          collisionRect:
              PixelRect(leftPx: 0, topPx: 0, widthPx: width, heightPx: height));
}
