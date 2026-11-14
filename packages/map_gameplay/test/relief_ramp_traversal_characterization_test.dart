import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/spatial_terrain_navigation.dart';
import 'package:test/test.dart';

SpatialTerrainSurface _surface(
  String id,
  double height,
  double left,
  double top,
  double right,
  double bottom, {
  double gradientZ = 0,
}) =>
    SpatialTerrainSurface(
      id: id,
      x: 0,
      z: top,
      height: height,
      gradientZ: gradientZ,
      footprints: [
        BorderGroundFootprint(
          points: [
            BorderGroundPoint(x: left, z: 0),
            BorderGroundPoint(x: right, z: 0),
            BorderGroundPoint(x: right, z: bottom - top),
            BorderGroundPoint(x: left, z: bottom - top),
          ],
        ),
      ],
    );

MapSpatialScene _scene({required double rampDepth}) => MapSpatialScene(
      width: 12,
      depth: 12,
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: [
          _surface('base', 1, 0, 0, 12, 12),
          _surface('plateau', 2, 4, 3, 8, 7),
          _surface(
            'ramp',
            2,
            5,
            7,
            7,
            7 + rampDepth,
            gradientZ: -1 / rampDepth,
          ),
        ],
      ),
    );

bool _walk(MapSpatialScene scene, double x0, double z0, double x1, double z1) {
  const step = 1 / 16;
  final count = ((x1 - x0).abs() + (z1 - z0).abs()) ~/ step;
  final dx = (x1 - x0).sign * step, dz = (z1 - z0).sign * step;
  for (var i = 0; i < count; i++) {
    if (!canTraverseSpatialTerrainStep(
      scene,
      x0 + dx * i,
      z0 + dz * i,
      x0 + dx * (i + 1),
      z0 + dz * (i + 1),
    )) {
      return false;
    }
  }
  return true;
}

void main() {
  test('a gradient surface between two levels is walkable at pixel steps', () {
    for (final depth in [1.0, 2.0]) {
      final scene = _scene(rampDepth: depth);
      expect(_walk(scene, 6, 7 + depth + 1.5, 6, 5.5), isTrue);
    }
  });

  test('the plateau edge and the ramp flanks block movement', () {
    final scene = _scene(rampDepth: 2);
    expect(_walk(scene, 4.5, 8.5, 4.5, 5.5), isFalse);
    expect(_walk(scene, 4.5, 7.5, 5.5, 7.5), isFalse);
    expect(_walk(scene, 7.5, 7.5, 6.5, 7.5), isFalse);
  });

  test('the lowest quarter level of a ramp flank can be entered sideways', () {
    final scene = _scene(rampDepth: 2);
    expect(_walk(scene, 7.5, 8.75, 6.5, 8.75), isTrue);
  });
}
