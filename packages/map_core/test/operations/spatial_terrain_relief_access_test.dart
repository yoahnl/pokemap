import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'relief_height_step_characterization_test.dart' show reliefMap;

MapData _withRamp(MapData map, {required double x, required double z}) =>
    map.copyWith(
      spatialScene: map.spatialScene!.copyWith(
        instances: [
          SpatialModelInstance(
            id: 'stairs',
            modelId: 'stairs',
            position: Model3dVector3(x: x + .5, y: 1, z: z + .5),
            blocksMovement: false,
          ),
        ],
        navigation: SpatialNavigationProfile(
          ramps: [
            SpatialRamp(
              id: 'ramp',
              x: x,
              z: z,
              width: 1,
              depth: 1,
              lowLevel: 1,
              highLevel: 2,
              direction: SpatialRampDirection.north,
              surfaceInstanceId: 'stairs',
            ),
          ],
        ),
      ),
    );

void main() {
  final plateau = reliefMap([
    (id: 'plateau', height: 2, rectangles: [(x: 2, y: 2, width: 4, height: 4)]),
  ]);
  final painted = {const GridPos(x: 3, y: 3)};

  test('a ramp far from the painted plateau does not block its trace', () {
    final result = computeHeightStepEdges(
      _withRamp(plateau, x: 10, z: 8),
      lowerHeight: 1,
      upperHeight: 2,
      cells: painted,
      exactHeights: true,
    );
    expect(result.status, SpatialIntentResolutionState.resolved);
    expect(result.strokes.single, hasLength(17));
  });

  test('a ramp inside the traced plateau still asks for a contour', () {
    final result = computeHeightStepEdges(
      _withRamp(plateau, x: 3, z: 4),
      lowerHeight: 1,
      upperHeight: 2,
      cells: painted,
    );
    expect(result.reason, 'ramps_require_explicit_contour');
  });

  test('an enclosed plateau is unreachable until a ramp touches it', () {
    expect(terrainReliefUnreachable(plateau, painted, 2), isTrue);
    expect(
      terrainReliefUnreachable(_withRamp(plateau, x: 3, z: 6), painted, 2),
      isFalse,
    );
    expect(
      terrainReliefUnreachable(plateau, {const GridPos(x: 0, y: 0)}, 1),
      isFalse,
    );
  });

  test('a slope or a stair touching the plateau makes it reachable', () {
    final manifest = ProjectManifest(name: 'Access', maps: [], tilesets: []);
    final sloped = paintTerrainSlope(
      manifest: manifest,
      map: plateau,
      from: const GridPos(x: 3, y: 8),
      to: const GridPos(x: 3, y: 5),
    ).map;
    expect(terrainReliefUnreachable(sloped, painted, 2), isFalse);
  });
}
