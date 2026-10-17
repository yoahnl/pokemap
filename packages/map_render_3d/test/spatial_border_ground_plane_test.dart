import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';

import '../../map_core/test/support/spatial_border_ground_surface_fixture.dart';

void main() {
  test('intersecting ground planes keep separate heights and native UVs', () {
    final own = surfaceFixture();
    final raw = jsonDecode(
      jsonEncode(
        encodeBorderBlueprintRecordJson(
          own.project.borderCatalog.records.single,
          formatVersion: 9,
        ),
      ),
    ) as Map<String, Object?>;
    for (final section in ['draft', 'latestPublished']) {
      for (final primitive
          in (raw[section] as Map)['definition']['primitives'] as List) {
        final surfaces = primitive['groundSurfaces'] as List;
        for (var i = 0; i < surfaces.length; i++) {
          surfaces[i]['height'] = 0.0;
          surfaces[i]['gradientX'] = i == 0 ? .5 : -.5;
          surfaces[i]['gradientZ'] = .25;
          surfaces[i]['footprints'] = [
            [
              {'x': -.1, 'z': -.1},
              {'x': .1, 'z': -.1},
              {'x': .1, 'z': .1},
              {'x': -.1, 'z': .1},
            ],
          ];
        }
      }
    }
    final project = own.project.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 10,
        records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 10)],
      ),
    );
    final applied = applySpatialBorderFeaturePreview(
      own.map,
      manifest: project,
      proposedResult: resolveSpatialBorderFeature(
        manifest: project,
        map: own.map,
        layerId: 'border',
        featureId: 'fence',
      ),
    );
    final map = applied.copyWith(
      spatialScene: applied.spatialScene!.copyWith(
        instances: [
          for (final instance in applied.spatialScene!.instances)
            instance.copyWith(
              position: Model3dVector3(x: 0, y: 0, z: 0),
              rotationDegrees: 0,
            ),
        ],
      ),
    );
    final surfaces = resolveSpatialBorderGroundSurfaces(
      manifest: project,
      map: map,
    );
    final plan = SpatialGroundPlan(map, project);
    final visuals = plan.resolve(0);
    expect(visuals, isNotEmpty);
    final gradients = <double>{};
    var verticesChecked = 0;
    for (final item in visuals) {
      final flat = plan.flatSurfaceFor(item.visual)!;
      gradients.add(flat.gradientX);
      final vertices = spatialGroundVertices(
        item.visual.geometry,
        scene: map.spatialScene,
        flatSurface: flat,
      );
      for (final vertex in vertices) {
        final x = vertex.position.x, z = vertex.position.z;
        expect(vertex.position.y, closeTo(flat.heightAt(x, z), 1e-6));
        expect(
          surfaces.any(
            (s) => (s.heightAt(x, z) - vertex.position.y).abs() < 1e-6,
          ),
          isTrue,
        );
        expect(vertex.texCoord.x, closeTo(x - item.visual.cellX, 1e-6));
        expect(vertex.texCoord.y, closeTo(z - item.visual.cellY, 1e-6));
        verticesChecked++;
      }
    }
    expect(gradients, {.5, -.5});
    expect(verticesChecked, greaterThan(0));
    expect(map.spatialScene!.navigation, own.map.spatialScene!.navigation);
    expect(map.spatialScene!.heightLevels, own.map.spatialScene!.heightLevels);
  });
}
