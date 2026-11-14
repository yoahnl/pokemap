import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/spatial_terrain_navigation.dart';
import 'package:test/test.dart';

SpatialTerrainSurface _rectangle(
  String id,
  double height,
  double left,
  double top,
  double right,
  double bottom, {
  double gradientX = 0,
  double gradientZ = 0,
  bool closedFlanks = false,
}) =>
    SpatialTerrainSurface(
      id: id,
      x: left,
      z: top,
      height: height,
      gradientX: gradientX,
      gradientZ: gradientZ,
      closedFlanks: closedFlanks,
      footprints: [
        BorderGroundFootprint(
          points: [
            BorderGroundPoint(x: 0, z: 0),
            BorderGroundPoint(x: right - left, z: 0),
            BorderGroundPoint(x: right - left, z: bottom - top),
            BorderGroundPoint(x: 0, z: bottom - top),
          ],
        ),
      ],
    );

MapSpatialScene _northSlope({bool closed = true}) => MapSpatialScene(
      width: 12,
      depth: 12,
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: [
          _rectangle('base', 1, 0, 0, 12, 12),
          _rectangle('plateau', 2, 4, 3, 8, 7),
          _rectangle('slope', 2, 5, 7, 7, 9,
              gradientZ: -.5, closedFlanks: closed),
        ],
      ),
    );

MapSpatialScene _eastSlope() => MapSpatialScene(
      width: 12,
      depth: 12,
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: [
          _rectangle('base', 1, 0, 0, 12, 12),
          _rectangle('plateau', 2, 7, 3, 11, 9),
          _rectangle('slope', 1, 5, 4, 7, 6,
              gradientX: .5, closedFlanks: true),
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
  test('a slope with closed flanks is walkable from its low end to the top',
      () {
    final scene = _northSlope();
    expect(_walk(scene, 6, 10.5, 6, 5.5), isTrue);
    expect(_walk(scene, 6, 5.5, 6, 10.5), isTrue);
    expect(_walk(scene, 5.0625, 10.5, 5.0625, 5.5), isTrue);
  });

  test('closed flanks refuse sideways entry and exit along the whole slope',
      () {
    final scene = _northSlope();
    for (final z in [7.25, 8.0, 8.75, 8.9375]) {
      expect(_walk(scene, 7.5, z, 6.5, z), isFalse, reason: 'enter at $z');
      expect(_walk(scene, 6.5, z, 7.5, z), isFalse, reason: 'leave at $z');
      expect(_walk(scene, 4.5, z, 5.5, z), isFalse, reason: 'west at $z');
    }
  });

  test('an open slope keeps today\'s low quarter flank entry', () {
    expect(_walk(_northSlope(closed: false), 7.5, 8.75, 6.5, 8.75), isTrue);
  });

  test('flanks along the other axis close the same way', () {
    final scene = _eastSlope();
    expect(_walk(scene, 3.5, 5, 8.5, 5), isTrue);
    expect(_walk(scene, 5.25, 7.5, 5.25, 5.5), isFalse);
    expect(_walk(scene, 5.25, 5.5, 5.25, 3.5), isFalse);
  });
}
