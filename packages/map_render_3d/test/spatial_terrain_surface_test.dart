import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_terrain_geometry.dart';

void main() {
  test('continuous terrain replaces the base only inside its footprints', () {
    final scene = terrainScene();
    final patches = spatialSurfacePatches(scene).toList();
    expect(heightAt(patches, 1.2, 1.2), closeTo(2.15, 1e-12));
    expect(heightAt(patches, 1.8, 1.8), 1);
    expect(heightAt(patches, .5, .5), 1);
    expect(heightAt(patches, 1.2, 1.2), scene.worldHeightAt(1.2, 1.2));
  });

  test('lower terrain cannot be covered by the quantized base', () {
    final scene = terrainScene(height: .5, gradientX: 0, gradientZ: 0);
    final patches = spatialSurfacePatches(scene).toList();
    expect(heightAt(patches, 1.2, 1.2), .5);
    expect(heightAt(patches, 1.8, 1.8), 1);
  });

  test(
    'raster geometry follows the surface and retains its UV coordinates',
    () {
      final vertices = spatialGroundVertices(geometry(), scene: terrainScene());
      expect(vertices.any((v) => v.position.y > 2), isTrue);
      expect(vertices.any((v) => v.position.y == 1), isTrue);
      for (final vertex in vertices) {
        final p = vertex.position;
        final plane = 2 + .25 * (p.x - 1) + .5 * (p.z - 1);
        expect((p.y - 1).abs() < 1e-6 || (p.y - plane).abs() < 1e-6, isTrue);
        expect(vertex.texCoord.x, closeTo(p.x - 1, 1e-6));
        expect(vertex.texCoord.y, closeTo(p.z - 1, 1e-6));
      }
    },
  );
  test(
    'a continuous surface has no generated cliff at an interior cell edge',
    () {
      final scene = MapSpatialScene(
        width: 2,
        depth: 1,
        terrainSurfaces: SpatialTerrainSurfaceSet(
          surfaces: [
            SpatialTerrainSurface(
              id: 'slope',
              x: 0,
              z: 0,
              height: 1,
              gradientX: .25,
              footprints: [
                BorderGroundFootprint(
                  points: [
                    BorderGroundPoint(x: 0, z: 0),
                    BorderGroundPoint(x: 2, z: 0),
                    BorderGroundPoint(x: 2, z: 1),
                    BorderGroundPoint(x: 0, z: 1),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      final faces = spatialTerrainFaces(scene).toList();
      expect(faces.where((f) => f.isTop), hasLength(2));
      expect(faces.where((f) => !f.isTop), isNotEmpty);
      expect(
        faces.where(
          (f) => !f.isTop && f.positions.every((p) => (p.x - 1).abs() < 1e-6),
        ),
        isEmpty,
      );
    },
  );

  test('a ramp remains authoritative over terrain surfaces underneath it', () {
    final scene = MapSpatialScene(
      width: 4,
      depth: 3,
      heightLevels: [for (var i = 0; i < 12; i++) i % 4 >= 2 ? 1 : 0],
      navigation: SpatialNavigationProfile(
        ramps: [
          SpatialRamp(
            id: 'ramp',
            x: 1,
            z: 1,
            width: 1,
            depth: 1,
            lowLevel: 0,
            highLevel: 1,
            direction: SpatialRampDirection.east,
          ),
        ],
      ),
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: [
          SpatialTerrainSurface(
            id: 'under-ramp',
            x: 1,
            z: 1,
            height: 5,
            footprints: [
              BorderGroundFootprint(
                points: [
                  BorderGroundPoint(x: 0, z: 0),
                  BorderGroundPoint(x: 1, z: 0),
                  BorderGroundPoint(x: 1, z: 1),
                  BorderGroundPoint(x: 0, z: 1),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    expect(scene.worldHeightAt(1.5, 1.5), .5);
    final patches = spatialSurfacePatches(scene).toList();
    expect(heightAt(patches, 1.5, 1.5), .5);
    final vertices = spatialGroundVertices(geometry(), scene: scene);
    expect(
      vertices.map((v) => v.position.y),
      everyElement(inInclusiveRange(0, 1)),
    );
  });
}

MapSpatialScene terrainScene({
  double height = 2,
  double gradientX = .25,
  double gradientZ = .5,
}) => MapSpatialScene(
  width: 3,
  depth: 3,
  heightLevels: List.filled(9, 1),
  terrainSurfaces: SpatialTerrainSurfaceSet(
    surfaces: [
      SpatialTerrainSurface(
        id: 'plateau',
        x: 1,
        z: 1,
        height: height,
        gradientX: gradientX,
        gradientZ: gradientZ,
        footprints: [
          BorderGroundFootprint(
            points: [
              BorderGroundPoint(x: 0, z: 0),
              BorderGroundPoint(x: 1, z: 0),
              BorderGroundPoint(x: 0, z: 1),
            ],
          ),
        ],
      ),
    ],
  ),
);

double heightAt(List<SpatialSurfacePatch> patches, double x, double z) =>
    patches
        .where((p) {
          if (x < p.left || x > p.right || z < p.top || z > p.bottom)
            return false;
          if (p.footprint == null) return true;
          final points = <BorderGroundPoint>[];
          for (final point in p.footprint!) {
            if (points.isEmpty || points.last != point) points.add(point);
          }
          if (points.first == points.last) points.removeLast();
          return BorderGroundFootprint(points: points).contains(x, z);
        })
        .map((p) => p.heightAt(x, z))
        .reduce((a, b) => a > b ? a : b);

SmartTileSpriteGeometry geometry() => resolveSmartTileSpriteGeometry(
  cellX: 1,
  cellY: 1,
  destinationCellWidth: 1,
  destinationCellHeight: 1,
  sourceCellWidth: 16,
  sourceCellHeight: 16,
  offsetUnit: SmartTileOffsetUnit.pixel,
  offsetX: 0,
  offsetY: 0,
  atlasPixelOffsetX: 0,
  atlasPixelOffsetY: 0,
  footprintWidth: 1,
  footprintHeight: 1,
  anchorX: 0,
  anchorY: 0,
  transform: const SmartTileSpriteTransform(),
);
