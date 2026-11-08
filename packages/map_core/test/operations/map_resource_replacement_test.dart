import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const tile = PixelSize(width: 16, height: 16);

  group('replaceMapPlacedElementResource', () {
    test('repoints one occurrence and resets its visual overrides', () {
      final map = _map(placed: [
        _placed('a', x: 1, y: 1).copyWith(
          pixelSize: const PixelSize(width: 8, height: 8),
          opacity: 0.5,
        ),
        _placed('b', x: 2, y: 2),
      ]);
      final next = replaceMapPlacedElementResource(
        map,
        instanceId: 'a',
        element: _element('bush'),
        tileSize: tile,
      );
      final replaced = next.placedElements.firstWhere((e) => e.id == 'a');
      expect(replaced.elementId, 'bush');
      expect(replaced.pixelSize, isNull);
      expect(replaced.pos, const GridPos(x: 1, y: 1));
      expect(replaced.opacity, 0.5);
      expect(next.placedElements.firstWhere((e) => e.id == 'b').elementId,
          'lamp');
      expect(map.placedElements.first.elementId, 'lamp');
    });

    test('refuses missing, environment-owned and moving occurrences', () {
      final environment = _map(placed: [
        _placed('a', x: 1, y: 1).copyWith(properties: {
          pokemapPlacementOriginProperty: pokemapPlacementOriginEnvironment,
        }),
      ]);
      final moving = _map(placed: [_placed('a', x: 1, y: 1)]).copyWith(
        movingProps: [
          MovingPropDefinition(
            id: 'gate',
            placedElementId: 'a',
            closedPositionPx: const PixelOffset(x: 16, y: 16),
            openPositionPx: const PixelOffset(x: 32, y: 16),
            collisionRect:
                const PixelRect(leftPx: 0, topPx: 0, widthPx: 16, heightPx: 16),
          ),
        ],
      );
      for (final (map, reason) in [
        (_map(placed: const []), MapResourceReplacementRefusal.instanceMissing),
        (environment, MapResourceReplacementRefusal.environmentOwned),
        (moving, MapResourceReplacementRefusal.movingProp),
      ]) {
        expect(
          () => replaceMapPlacedElementResource(map,
              instanceId: 'a', element: _element('bush'), tileSize: tile),
          throwsA(isA<MapResourceReplacementException>()
              .having((e) => e.reason, 'reason', reason)),
        );
      }
    });

    test('refuses a replacement that leaves the map bounds', () {
      expect(
        () => replaceMapPlacedElementResource(
          _map(placed: [_placed('a', x: 3, y: 3)]),
          instanceId: 'a',
          element: _element('wide', width: 2),
          tileSize: tile,
        ),
        throwsA(isA<MapResourceReplacementException>().having((e) => e.reason,
            'reason', MapResourceReplacementRefusal.outOfBounds)),
      );
    });
  });

  group('replaceSpatialInstanceModel', () {
    test('keeps placement and drops model-specific animation and clip', () {
      final map = _spatial([
        SpatialModelInstance(
          id: 'rock',
          modelId: 'old',
          position: Model3dVector3(x: 1, y: 0, z: 2),
          rotationDegrees: 90,
          scale: 2,
          animationIndex: 1,
          blocksMovement: false,
          castsShadows: true,
        ),
      ]);
      final next = replaceSpatialInstanceModel(map,
          instanceId: 'rock', model: _model('new'));
      final instance = next.spatialScene!.instances.single;
      expect(instance.modelId, 'new');
      expect(instance.position, Model3dVector3(x: 1, y: 0, z: 2));
      expect(instance.rotationDegrees, 90);
      expect(instance.scale, 2);
      expect(instance.blocksMovement, isFalse);
      expect(instance.castsShadows, isTrue);
      expect(instance.animationIndex, isNull);
      expect(map.spatialScene!.instances.single.modelId, 'old');
    });

    test('refuses painted, missing and generated occurrences', () {
      final painted = _spatial([
        SpatialModelInstance(
            id: 'smt_cell',
            modelId: 'old',
            position: Model3dVector3(x: 1, y: 0, z: 1)),
      ]);
      expect(
        () => replaceSpatialInstanceModel(painted,
            instanceId: 'smt_cell', model: _model('new')),
        throwsA(isA<MapResourceReplacementException>().having((e) => e.reason,
            'reason', MapResourceReplacementRefusal.paintedTerrain)),
      );
      expect(
        () => replaceSpatialInstanceModel(_spatial(const []),
            instanceId: 'rock', model: _model('new')),
        throwsA(isA<MapResourceReplacementException>().having((e) => e.reason,
            'reason', MapResourceReplacementRefusal.instanceMissing)),
      );
    });
  });
}

MapData _map({required List<MapPlacedElement> placed}) => MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 4, height: 4),
      layers: const [
        MapLayer.tile(
          id: 'layer',
          name: 'Layer',
          cells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      ],
      placedElements: placed,
    );

MapPlacedElement _placed(String id, {required int x, required int y}) =>
    MapPlacedElement(
      id: id,
      layerId: 'layer',
      elementId: 'lamp',
      pos: GridPos(x: x, y: y),
    );

ProjectElementEntry _element(String id, {int width = 1}) => ProjectElementEntry(
      id: id,
      name: id,
      tilesetId: 'ts',
      categoryId: 'cat',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: width, height: 1),
        ),
      ],
    );

MapData _spatial(List<SpatialModelInstance> instances) => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(
        width: 4,
        depth: 4,
        levelHeight: .25,
        heightLevels: List.filled(16, 0),
        instances: instances,
      ),
    );

ProjectModel3dEntry _model(String id) => ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: '$id-source',
      relativePath: 'assets/models3d/$id.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.5, y: 0, z: -.5),
          max: Model3dVector3(x: .5, y: 1, z: .5),
        ),
        meshCount: 1,
        triangleCount: 4,
      ),
    );
