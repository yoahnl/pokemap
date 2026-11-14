import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'relief_height_step_characterization_test.dart' show reliefMap;

ProjectModel3dEntry _model(
  String id,
  String name,
  double sizeX,
  double sizeY,
  double sizeZ,
) => ProjectModel3dEntry(
  id: id,
  name: name,
  sourceAssetId: '$id-source',
  relativePath: 'assets/models3d/$id.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3(x: -sizeX / 2, y: .0625, z: -sizeZ / 2),
      max: Model3dVector3(x: sizeX / 2, y: sizeY + .0625, z: sizeZ / 2),
    ),
    meshCount: 1,
    triangleCount: 2,
  ),
);

final _manifest = ProjectManifest(
  name: 'Stairs',
  maps: [],
  tilesets: [],
  models3d: [
    _model(
      'wide',
      'Escalier — largeur 3 cases — montée 1 niveau',
      3.38,
      1.19,
      1,
    ),
    _model(
      'side',
      'Escalier — largeur 1 case — montée 1 niveau',
      1,
      1.19,
      2.38,
    ),
    _model('tall', 'Escalier — montée 2 niveaux', 3.38, 2.19, 2),
    _model('decal', 'Escalier peint au sol', 1, 0, 1),
  ],
);

MapData _plateau() => reliefMap(
  [
    (id: 'plateau', height: 2, rectangles: [(x: 4, y: 3, width: 6, height: 4)]),
  ],
  width: 14,
  depth: 12,
);

Matcher _refused(String code) =>
    throwsA(isA<ValidationException>().having((e) => e.code, 'code', code));

void main() {
  test('stair models are read from their names and bounds', () {
    final map = _plateau();
    final candidates = terrainStairCandidates(_manifest, map);
    expect(candidates.map((c) => c.model.id), ['side', 'wide', 'tall']);
    final side = candidates.first;
    expect(
      (side.acrossCells, side.alongCells, side.levels, side.nativeDirection),
      (2, 1, 1, SpatialRampDirection.west),
    );
    final tall = candidates.last;
    expect(
      (tall.acrossCells, tall.alongCells, tall.levels, tall.nativeDirection),
      (3, 2, 2, SpatialRampDirection.north),
    );
  });

  test('clicking a cliff edge snaps a walkable stair in front of it', () {
    for (final cell in const [GridPos(x: 6, y: 6), GridPos(x: 6, y: 7)]) {
      final placed = placeTerrainStair(
        manifest: _manifest,
        map: _plateau(),
        cell: cell,
        modelId: 'wide',
      );
      final plan = placed.slope.plan;
      expect(plan.direction, SpatialRampDirection.north);
      expect(plan.cells, {for (var x = 5; x <= 7; x++) GridPos(x: x, y: 7)});
      expect((plan.lowerHeight, plan.upperHeight), (1.0, 2.0));
      final scene = placed.map.spatialScene!;
      expect(scene.worldHeightAt(6.5, 7.5), closeTo(1.5, 1e-9));
      final instance = placed.instance;
      expect(scene.instances.last, instance);
      expect(instance.modelId, 'wide');
      expect(instance.blocksMovement, isFalse);
      expect(instance.rotationDegrees, 0);
      expect(instance.position.x, closeTo(6.5, 1e-9));
      expect(instance.position.z, closeTo(7.5, 1e-9));
      expect(instance.position.y, closeTo(1 - .0625, 1e-9));
    }
  });

  test('the stair turns to climb toward the plateau on every side', () {
    final map = _plateau();
    for (final (cell, direction, degrees, x, z) in [
      (const GridPos(x: 6, y: 2), SpatialRampDirection.south, 180.0, 6.5, 2.5),
      (const GridPos(x: 10, y: 4), SpatialRampDirection.west, 90.0, 10.5, 4.5),
      (const GridPos(x: 3, y: 4), SpatialRampDirection.east, 270.0, 3.5, 4.5),
    ]) {
      final placed = placeTerrainStair(
        manifest: _manifest,
        map: map,
        cell: cell,
        modelId: 'wide',
      );
      expect(placed.slope.plan.direction, direction);
      expect(placed.instance.rotationDegrees, degrees);
      expect(placed.instance.position.x, closeTo(x, 1e-9));
      expect(placed.instance.position.z, closeTo(z, 1e-9));
    }
  });

  test('a side-facing model keeps its own climbing axis', () {
    final placed = placeTerrainStair(
      manifest: _manifest,
      map: _plateau(),
      cell: const GridPos(x: 10, y: 4),
      modelId: 'side',
    );
    expect(placed.slope.plan.direction, SpatialRampDirection.west);
    expect(placed.instance.rotationDegrees, 0);
    expect(placed.slope.plan.cells, {
      const GridPos(x: 10, y: 4),
      const GridPos(x: 10, y: 5),
    });
  });

  test('clicks that cannot hold a stair are refused', () {
    final map = _plateau();
    for (final (cell, model, code) in [
      (const GridPos(x: 1, y: 10), 'wide', 'spatial.stair.no_cliff'),
      (const GridPos(x: 4, y: 3), 'wide', 'spatial.stair.edge_ambiguous'),
      (const GridPos(x: 6, y: 7), 'tall', 'spatial.stair.height_mismatch'),
      (const GridPos(x: 4, y: 7), 'wide', 'spatial.stair.no_room'),
      (const GridPos(x: 6, y: 7), 'decal', 'spatial.stair.model_unavailable'),
      (const GridPos(x: 6, y: 7), 'missing', 'spatial.stair.model_unavailable'),
    ]) {
      expect(
        () => placeTerrainStair(
          manifest: _manifest,
          map: map,
          cell: cell,
          modelId: model,
        ),
        _refused(code),
        reason: '$cell $model',
      );
    }
  });
}
