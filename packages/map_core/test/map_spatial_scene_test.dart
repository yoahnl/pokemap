import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  MapData map() => MapData(
    id: 'garden',
    name: 'Jardin',
    version: ProjectVersion.v9,
    size: const GridSize(width: 4, height: 3),
    spatialScene: MapSpatialScene(width: 4, depth: 3),
  );
  test(
    'spatial scene persists height levels and fixed camera independently',
    () {
      final original = map();
      final levels = List<int>.of(original.spatialScene!.heightLevels)..[5] = 2;
      final edited = original.copyWith(
        spatialScene: original.spatialScene!.copyWith(heightLevels: levels),
      );
      final reopened = MapData.fromJson(edited.toJson());
      expect(reopened.spatialScene!.heightAt(1, 1), 2);
      expect(reopened.spatialScene!.camera.mode, SpatialCameraMode.fixed);
      expect(original.spatialScene!.heightAt(1, 1), 0);
    },
  );
  test('3D project rejects 2D maps and 2D project rejects 3D maps', () {
    final twoD = ProjectManifest(name: '2D', maps: [], tilesets: []);
    final threeD = twoD.copyWith(
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
    );
    ProjectValidator.validate(threeD, maps: [map()]);
    expect(
      () => ProjectValidator.validate(twoD, maps: [map()]),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => ProjectValidator.validate(
        threeD,
        maps: [map().copyWith(version: ProjectVersion.v8, spatialScene: null)],
      ),
      throwsA(isA<ValidationException>()),
    );
  });
  test('3D map rejects mixed 2D geometry and unsupported versions', () {
    expect(
      () => MapData.fromJson(map().copyWith(tilesetId: '2d').toJson()),
      throwsFormatException,
    );
    expect(
      () =>
          MapData.fromJson(map().copyWith(version: ProjectVersion.v8).toJson()),
      throwsFormatException,
    );
  });
  test(
    'terrain bounds, fractional levels and huge allocations are rejected',
    () {
      expect(
        () => MapSpatialScene(width: 100000, depth: 100000),
        throwsFormatException,
      );
      expect(
        () => MapSpatialScene(width: 1, depth: 1, heightLevels: [33]),
        throwsFormatException,
      );
      expect(
        () => SpatialCameraProfile(pitchDegrees: 90),
        throwsFormatException,
      );
    },
  );
  test(
    'spatial maps persist Smart Tile ground and paths on blocks and ramps',
    () {
      final original = map().copyWith(
        layers: [
          const MapLayer.smartTile(
            id: 'ground',
            name: 'Ground',
            presetId: 'grass',
            usage: SmartTileUsage.terrain,
            materialPalette: ['', 'grass'],
            field: SmartTileField.cell(
              semanticCells: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            ),
          ),
          const MapLayer.smartTile(
            id: 'path',
            name: 'Path',
            presetId: 'dirt',
            usage: SmartTileUsage.path,
            materialPalette: ['', 'dirt'],
            field: SmartTileField.cell(
              semanticCells: [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
            ),
          ),
        ],
      );
      final reopened = MapData.fromJson(original.toJson());
      expect(reopened, original);
      MapValidator.validate(reopened);
      final relief = original.copyWith(
        spatialScene: MapSpatialScene(
          width: 4,
          depth: 3,
          heightLevels: [0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          navigation: SpatialNavigationProfile(
            ramps: [
              SpatialRamp(
                id: 'ramp',
                x: 1,
                z: 1,
                width: 2,
                depth: 1,
                lowLevel: 0,
                highLevel: 2,
                direction: SpatialRampDirection.north,
              ),
            ],
          ),
        ),
      );
      final reopenedRelief = MapData.fromJson(relief.toJson());
      expect(reopenedRelief, relief);
      expect(reopenedRelief.spatialScene!.worldHeightAt(1.5, 1.5), 1);
      MapValidator.validate(reopenedRelief);
    },
  );
  test('spatial terrain accepts relief and rejects non-surface layers', () {
    final ground = const MapLayer.smartTile(
      id: 'ground',
      name: 'Ground',
      presetId: 'grass',
      usage: SmartTileUsage.terrain,
      materialPalette: ['', 'grass'],
      field: SmartTileField.cell(
        semanticCells: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      ),
    );
    expect(
      () => MapData.fromJson(
        map()
            .copyWith(
              layers: [ground],
              spatialScene: map().spatialScene!.copyWith(
                heightLevels: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
              ),
            )
            .toJson(),
      ),
      returnsNormally,
    );
    expect(
      () => MapData.fromJson(
        map()
            .copyWith(
              layers: [
                const MapLayer.collision(
                  id: 'collision',
                  name: 'Collision',
                  collisions: [],
                ),
              ],
            )
            .toJson(),
      ),
      throwsFormatException,
    );
  });

  test('spatial appearance roundtrips a cliff atlas frame', () {
    final json = map().toJson();
    final scene = json['spatialScene'] as Map<String, dynamic>;
    scene['cliffFrame'] = const SmartTileFrameRef(
      atlasId: 'cliffs',
      column: 2,
      row: 1,
      columnSpan: 2,
      rowSpan: 1,
    ).toJson();
    final reopened = MapData.fromJson(json);
    expect(reopened.spatialScene!.toJson()['cliffFrame'], scene['cliffFrame']);
    expect(MapData.fromJson(reopened.toJson()), reopened);
  });
  test('spatial Smart Tiles reject obsolete semantic payloads', () {
    final json = map().toJson();
    json['layers'] = [
      const MapLayer.smartTile(
        id: 'ground',
        name: 'Ground',
        presetId: 'grass',
        usage: SmartTileUsage.terrain,
        materialPalette: ['', 'grass'],
        field: SmartTileField.cell(
          semanticCells: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        ),
      ).toJson()..['materialCells'] = [1],
    ];
    expect(() => MapData.fromJson(json), throwsFormatException);
  });
  test('3D collision layers persist on relief without adding 2D geometry', () {
    final original = map().copyWith(
      spatialScene: map().spatialScene!.copyWith(
        heightLevels: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      layers: [
        const MapLayer.collision(
          id: 'blocked',
          name: 'Collisions',
          collisions: [
            false,
            false,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
          ],
        ),
      ],
    );
    final reopened = MapData.fromJson(original.toJson());
    expect(reopened, original);
    MapValidator.validate(reopened);
    expect((reopened.layers.single as CollisionLayer).collisions[5], isTrue);
  });
}
