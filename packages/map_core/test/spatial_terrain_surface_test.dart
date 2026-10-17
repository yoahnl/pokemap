import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('clipped terrain planes replace quantized cell heights locally', () {
    final scene = MapSpatialScene.fromJson(sceneJson([surfaceJson()]));
    expect(scene.worldHeightAt(2.5, 1.5), closeTo(2.375, 1e-12));
    expect(scene.worldHeightAt(1.5, 1.5), 1);
    expect(scene.worldHeightAt(4.5, 1.5), 1);
    expect(scene.heightAt(2, 1), 1);
  });

  test(
    'surface layers keep the upper physical envelope, including lower ground',
    () {
      final low = surfaceJson(
        id: 'lower',
        height: .5,
        gradientX: 0,
        gradientZ: 0,
      );
      final scene = MapSpatialScene.fromJson(sceneJson([low]));
      expect(scene.worldHeightAt(2.5, 1.5), .5);
      final overlap = MapSpatialScene.fromJson(sceneJson([surfaceJson(), low]));
      expect(overlap.worldHeightAt(2.5, 1.5), closeTo(2.375, 1e-12));
    },
  );

  test('terrain geometry survives scene JSON and copy operations', () {
    final scene = MapSpatialScene.fromJson(sceneJson([surfaceJson()]));
    final encoded =
        jsonDecode(jsonEncode(scene.toJson())) as Map<String, dynamic>;
    expect(
      encoded['terrainSurfaces'],
      sceneJson([surfaceJson()])['terrainSurfaces'],
    );
    final copy = scene.copyWith(heightLevels: List.filled(48, 8));
    expect(copy.worldHeightAt(2.5, 1.5), closeTo(2.375, 1e-12));
    expect(copy.worldHeightAt(1.5, 1.5), 2);
    expect(MapSpatialScene.fromJson(encoded), scene);
  });

  test('terrain component versions and duplicate identities are rejected', () {
    final unsupported = sceneJson([surfaceJson()]);
    (unsupported['terrainSurfaces'] as Map)['schemaVersion'] = 2;
    expect(() => MapSpatialScene.fromJson(unsupported), throwsFormatException);
    expect(
      () => MapSpatialScene.fromJson(sceneJson([surfaceJson(), surfaceJson()])),
      throwsA(anyOf(isA<FormatException>(), isA<ValidationException>())),
    );
  });

  test('terrain surfaces must remain inside the spatial map', () {
    final outside = surfaceJson()..['x'] = 7;
    expect(
      () => MapSpatialScene.fromJson(sceneJson([outside])),
      throwsA(anyOf(isA<FormatException>(), isA<ValidationException>())),
    );
  });

  test('moving a terrain surface preserves its local slope and shape', () {
    final scene = MapSpatialScene.fromJson(sceneJson([surfaceJson()]));
    final surface = scene.terrainSurfaces.surfaces.single;
    final moved = surface.copyWith(x: 4, z: 3);
    expect(moved.heightAt(4.5, 3.5), closeTo(2.375, 1e-12));
    expect(moved.contains(4.5, 3.5), isTrue);
    expect(moved.contains(2.5, 1.5), isFalse);
    expect(surface.contains(2.5, 1.5), isTrue);
    expect(
      scene
          .copyWith(
            terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: [moved]),
          )
          .worldHeightAt(2.5, 1.5),
      1,
    );
  });

  test('surface geometry is immutable and participates in scene equality', () {
    final scene = MapSpatialScene.fromJson(sceneJson([surfaceJson()]));
    expect(
      () => scene.terrainSurfaces.surfaces.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => scene.terrainSurfaces.surfaces.single.footprints.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => scene.terrainSurfaces.surfaces.single.footprints.single.points
          .clear(),
      throwsUnsupportedError,
    );
    final changed = MapSpatialScene.fromJson(
      sceneJson([surfaceJson(height: 3)]),
    );
    expect(changed, isNot(scene));
    expect(MapSpatialScene.fromJson(scene.toJson()).hashCode, scene.hashCode);
  });

  test('invalid numbers and shapes fail before entering a spatial scene', () {
    final invalid = <Map<String, dynamic>>[
      for (final key in ['x', 'z', 'height', 'gradientX', 'gradientZ'])
        for (final value in [double.nan, double.infinity, '1', null])
          surfaceJson()..[key] = value,
      surfaceJson(height: -1),
      surfaceJson(height: 1025),
      surfaceJson()..['id'] = 'invalid/id',
      surfaceJson()..['unused'] = true,
      surfaceJson()..['footprints'] = [],
      surfaceJson()
        ..['footprints'] = List.filled(33, surfaceJson()['footprints'][0]),
      surfaceJson()
        ..['footprints'] = [
          [
            {'x': 0, 'z': 0},
            {'x': 1, 'z': 0},
          ],
        ],
      surfaceJson()
        ..['footprints'] = [
          [
            {'x': 0, 'z': 0},
            {'x': 1, 'z': 0},
            {'x': 2, 'z': 0},
          ],
        ],
    ];
    for (final surface in invalid) {
      expect(
        () => MapSpatialScene.fromJson(sceneJson([surface])),
        throwsA(anyOf(isA<FormatException>(), isA<ValidationException>())),
      );
    }
  });

  test('ordinary grid scenes do not acquire a terrain component', () {
    final scene = MapSpatialScene(width: 3, depth: 2);
    expect(scene.toJson()['schemaVersion'], 1);
    expect(scene.toJson().containsKey('terrainSurfaces'), isFalse);
    expect(MapSpatialScene.fromJson(scene.toJson()), scene);
  });

  test(
    'cached physical bounds include continuous vertices and refresh on copy',
    () {
      final scene = MapSpatialScene.fromJson(sceneJson([surfaceJson()]));
      expect(scene.maximumWorldHeight, 3.5);
      expect(scene.maximumWorldHeight, 3.5);
      final raised = scene.copyWith(heightLevels: List.filled(48, 64));
      expect(raised.maximumWorldHeight, 16);
      expect(scene.maximumWorldHeight, 3.5);
    },
  );

  test('continuous geometry requires its explicit scene version', () {
    final encoded = sceneJson([surfaceJson()]);
    expect(MapSpatialScene.fromJson(encoded).toJson()['schemaVersion'], 2);
    expect(
      () => MapSpatialScene.fromJson({...encoded, 'schemaVersion': 1}),
      throwsFormatException,
    );
    expect(
      () => MapSpatialScene.fromJson({...encoded, 'schemaVersion': 2.0}),
      throwsFormatException,
    );
    expect(
      () => MapSpatialScene.fromJson({
        ...MapSpatialScene(width: 3, depth: 2).toJson(),
        'schemaVersion': 2,
      }),
      throwsFormatException,
    );
    expect(
      () => MapSpatialScene.fromJson(sceneJson([])),
      throwsFormatException,
    );
  });

  test(
    'surface edits preserve instance offsets and restore them on deletion',
    () {
      const operations = SpatialMapOperations();
      final scene = MapSpatialScene.fromJson(sceneJson([surfaceJson()]));
      final surface = scene.terrainSurfaces.surfaces.single;
      final map = MapData(
        id: 'map',
        name: 'Terrain',
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 6),
        spatialScene: scene.copyWith(
          instances: [
            SpatialModelInstance(
              id: 'tree',
              modelId: 'oak',
              position: Model3dVector3(x: 2.5, y: 2.625, z: 1.5),
            ),
            SpatialModelInstance(
              id: 'outside',
              modelId: 'oak',
              position: Model3dVector3(x: .5, y: 1.25, z: .5),
            ),
          ],
        ),
      );
      final raised = operations.upsertTerrainSurfaces(map, [
        surface.copyWith(height: 3),
      ]);
      expect(raised.spatialScene!.instances.first.position.y, 3.625);
      expect(
        raised.spatialScene!.instances.last,
        map.spatialScene!.instances.last,
      );
      final deleted = operations.deleteTerrainSurfaces(raised, ['plateau']);
      expect(deleted.spatialScene!.instances.first.position.y, 1.25);
      expect(map.spatialScene!.instances.first.position.y, 2.625);
      expect(deleted.spatialScene!.heightLevels, scene.heightLevels);
    },
  );

  test(
    'grid edits refuse continuous terrain coverage instead of silently changing hidden levels',
    () {
      const operations = SpatialMapOperations();
      final scene = MapSpatialScene.fromJson(sceneJson([surfaceJson()]));
      final map = MapData(
        id: 'map',
        name: 'Terrain',
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 6),
        spatialScene: scene,
      );
      expect(
        () => operations.setLevels(map, [
          const SpatialCellLevel(x: 0, z: 0, level: 8),
          const SpatialCellLevel(x: 2, z: 1, level: 8),
        ]),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'spatial.terrain.surface_grid_conflict',
          ),
        ),
      );
      final outside = operations.setLevels(map, [
        const SpatialCellLevel(x: 1, z: 1, level: 8),
      ]);
      expect(outside.spatialScene!.heightAt(1, 1), 2);
      expect(scene.heightAt(0, 0), 1);
    },
  );

  test(
    'continuous surfaces can change without moving placed model geometry',
    () {
      const operations = SpatialMapOperations();
      final scene = MapSpatialScene.fromJson(sceneJson([surfaceJson()]));
      final map = MapData(
        id: 'map',
        name: 'Terrain',
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 6),
        spatialScene: scene.copyWith(
          instances: [
            SpatialModelInstance(
              id: 'cliff',
              modelId: 'rock',
              position: Model3dVector3(x: 2.5, y: 2.625, z: 1.5),
            ),
          ],
        ),
      );
      final changed = operations.upsertTerrainSurfaces(map, [
        scene.terrainSurfaces.surfaces.single.copyWith(height: 3),
      ], reanchorInstances: false);
      expect(changed.spatialScene!.worldHeightAt(2.5, 1.5), 3.375);
      expect(changed.spatialScene!.instances, map.spatialScene!.instances);
      final deleted = operations.deleteTerrainSurfaces(changed, [
        'plateau',
      ], reanchorInstances: false);
      expect(deleted.spatialScene!.worldHeightAt(2.5, 1.5), 1);
      expect(deleted.spatialScene!.instances, map.spatialScene!.instances);
      expect(deleted.spatialScene!.navigation, map.spatialScene!.navigation);
      expect(
        deleted.spatialScene!.heightLevels,
        map.spatialScene!.heightLevels,
      );
    },
  );
}

Map<String, dynamic> sceneJson(List<Map<String, dynamic>> surfaces) => {
  ...MapSpatialScene(
    width: 8,
    depth: 6,
    levelHeight: .25,
    heightLevels: List.filled(48, 4),
  ).toJson(),
  'schemaVersion': 2,
  'terrainSurfaces': {'schemaVersion': 1, 'surfaces': surfaces},
};

Map<String, dynamic> surfaceJson({
  String id = 'plateau',
  double height = 2,
  double gradientX = .25,
  double gradientZ = .5,
}) => {
  'id': id,
  'x': 2.0,
  'z': 1.0,
  'height': height,
  'gradientX': gradientX,
  'gradientZ': gradientZ,
  'footprints': [
    [
      {'x': 0.0, 'z': 0.0},
      {'x': 2.0, 'z': 0.0},
      {'x': 2.0, 'z': 2.0},
      {'x': 0.0, 'z': 2.0},
    ],
  ],
};
