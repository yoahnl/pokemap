import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

SpatialTerrainSurface _flat(
        String id, double height, int x, int z, int w, int d) =>
    SpatialTerrainSurface(
      id: id,
      x: x.toDouble(),
      z: z.toDouble(),
      height: height,
      footprints: [
        BorderGroundFootprint(points: [
          BorderGroundPoint(x: 0, z: 0),
          BorderGroundPoint(x: w.toDouble(), z: 0),
          BorderGroundPoint(x: w.toDouble(), z: d.toDouble()),
          BorderGroundPoint(x: 0, z: d.toDouble()),
        ]),
      ],
    );

MapData _plateau() {
  final map = MapData(
    version: ProjectVersion.v9,
    id: 'walk',
    name: 'Walk',
    size: const GridSize(width: 14, height: 14),
    spatialScene: MapSpatialScene(width: 14, depth: 14),
    layers: const [],
  );
  return const SpatialMapOperations().upsertTerrainSurfaces(map, [
    _flat('base', 1, 0, 0, 14, 14),
    _flat('plateau', 2, 4, 2, 6, 5),
  ]);
}

final _manifest = ProjectManifest(
  name: 'Walk',
  maps: [],
  tilesets: [],
  models3d: [
    ProjectModel3dEntry(
      id: 'stair',
      name: 'Escalier — largeur 3 cases — montée 1 niveau',
      sourceAssetId: 'stair-source',
      relativePath: 'assets/models3d/stair.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -1.69, y: 0, z: -.5),
          max: Model3dVector3(x: 1.69, y: 1.19, z: .5),
        ),
        meshCount: 1,
        triangleCount: 2,
      ),
    ),
  ],
);

SpatialMovementController _player(MapData map, double x, double z) =>
    SpatialMovementController(
      scene: map.spatialScene!.copyWith(
        navigation: map.spatialScene!.navigation
            .copyWith(spawn: SpatialSpawn(x: x, z: z)),
      ),
      models: _manifest.models3d,
    );

void _walk(SpatialMovementController player, int x, int z, double seconds) {
  player.setInput(x: x, z: z);
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    player.update(1 / 60);
  }
  player.setInput(x: 0, z: 0);
  player.update(1 / 60);
}

void main() {
  test('the player climbs a painted slope onto the plateau and back', () {
    final map = paintTerrainSlope(
      manifest: _manifest,
      map: _plateau(),
      from: const GridPos(x: 6, y: 10),
      to: const GridPos(x: 7, y: 5),
    ).map;
    final player = _player(map, 7, 11.5);
    _walk(player, 0, -1, 3);
    expect(player.z, lessThan(6.5));
    expect(player.y, closeTo(2, 1e-6));
    _walk(player, 0, 1, 3);
    expect(player.z, greaterThan(10));
    expect(player.y, closeTo(1, 1e-6));
  });

  test('the player cannot step onto a slope from its side', () {
    final painted = paintTerrainSlope(
      manifest: _manifest,
      map: _plateau(),
      from: const GridPos(x: 6, y: 10),
      to: const GridPos(x: 7, y: 5),
    );
    final scene = painted.map.spatialScene!;
    final slope = scene.terrainSurfaces.surfaces
        .singleWhere((surface) => surface.id == painted.surfaceId);
    final open = painted.map.copyWith(
      spatialScene: scene.copyWith(
        terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: [
          for (final surface in scene.terrainSurfaces.surfaces)
            surface.id == slope.id
                ? surface.copyWith(closedFlanks: false)
                : surface,
        ]),
      ),
    );
    for (final z in [10.75, 10.5]) {
      for (final (start, dx) in [(9.5, -1), (4.5, 1)]) {
        final closed = _player(painted.map, start, z);
        _walk(closed, dx, 0, 2);
        expect(slope.contains(closed.x, closed.z), isFalse, reason: '$z $dx');
        expect((closed.x - 7).sign, (start - 7).sign, reason: '$z $dx');
        expect(closed.y, 1, reason: '$z $dx');
        final legacy = _player(open, start, z);
        _walk(legacy, dx, 0, 2);
        expect((legacy.x - 7).sign, -(start - 7).sign, reason: '$z $dx');
      }
    }
  });

  test('a snapped stair lets the player climb the cliff it cuts', () {
    final placed = placeTerrainStair(
      manifest: _manifest,
      map: _plateau(),
      cell: const GridPos(x: 7, y: 7),
      modelId: 'stair',
    );
    final player = _player(placed.map, 7.5, 10.5);
    _walk(player, 0, -1, 3);
    expect(player.z, lessThan(6.5));
    expect(player.y, closeTo(2, 1e-6));
    final stair = placed.map.spatialScene!.terrainSurfaces.surfaces
        .singleWhere((surface) => surface.id == placed.slope.surfaceId);
    final beside = _player(placed.map, 4.5, 7.875);
    _walk(beside, 1, 0, 2);
    expect(stair.contains(beside.x, beside.z), isFalse);
    expect(beside.y, 1);
  });
}
