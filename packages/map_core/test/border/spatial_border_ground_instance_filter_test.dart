import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/spatial_border_ground_surface_fixture.dart';
import 'spatial_border_ground_mask_test.dart' show maskFixture;

({ProjectManifest project, MapData map}) replacementFixture() {
  final fixture = surfaceFixture();
  final raw = fixture.project.toJson();
  final record = (raw['borderCatalog']['records'] as List).single as Map;
  for (final section in ['draft', 'latestPublished']) {
    (record[section] as Map)['definition']['replacesGround'] = true;
  }
  final project = ProjectManifest.fromJson(raw);
  final result = resolveSpatialBorderFeature(
    manifest: project,
    map: fixture.map,
    layerId: 'border',
    featureId: 'fence',
  );
  return (
    project: project,
    map: applySpatialBorderFeaturePreview(
      fixture.map,
      manifest: project,
      proposedResult: result,
    ),
  );
}

void main() {
  test('instance filter removes only its native ground mask', () {
    final fixture = maskFixture();
    final context = SpatialBorderResolutionContext.fromMap(fixture.map);
    final removed = fixture.map.spatialScene!.instances.first;
    final all = resolveSpatialBorderGroundMaskCellsByLayerInContext(
      manifest: fixture.project,
      context: context,
    );
    final filtered = resolveSpatialBorderGroundMaskCellsByLayerInContext(
      manifest: fixture.project,
      context: context,
      includeInstance: (id) => id != removed.id,
    );
    expect(all['border'], hasLength(5));
    expect(filtered['border'], hasLength(4));
    expect(
      filtered['border'],
      isNot(contains((removed.position.x.floor(), removed.position.z.floor()))),
    );
    expect(
      resolveSpatialBorderGroundMaskCellsByLayerInContext(
        manifest: fixture.project,
        context: context,
        includeInstance: (_) => true,
      ),
      all,
    );
  });

  test(
    'instance filter removes only its native replacement and ground surfaces',
    () {
      final fixture = replacementFixture();
      final context = SpatialBorderResolutionContext.fromMap(fixture.map);
      final removed = fixture.map.spatialScene!.instances.first.id;
      final replacements =
          resolveSpatialBorderGroundReplacementsByLayerInContext(
            manifest: fixture.project,
            context: context,
          );
      final surfaces = resolveSpatialBorderGroundSurfacesInContext(
        manifest: fixture.project,
        context: context,
      );
      final filteredReplacements =
          resolveSpatialBorderGroundReplacementsByLayerInContext(
            manifest: fixture.project,
            context: context,
            includeInstance: (id) => id != removed,
          );
      final filteredSurfaces = resolveSpatialBorderGroundSurfacesInContext(
        manifest: fixture.project,
        context: context,
        includeInstance: (id) => id != removed,
      );
      expect(replacements['border'], hasLength(5));
      expect(filteredReplacements['border'], hasLength(4));
      expect(surfaces, hasLength(10));
      expect(filteredSurfaces, hasLength(8));
      expect(
        resolveSpatialBorderGroundReplacementsByLayerInContext(
          manifest: fixture.project,
          context: context,
          includeInstance: (_) => true,
        ),
        replacements,
      );
    },
  );

  test('filtering every instance leaves no masks replacement or surfaces', () {
    final mask = maskFixture();
    final replacement = replacementFixture();
    expect(
      resolveSpatialBorderGroundMaskCellsByLayerInContext(
        manifest: mask.project,
        context: SpatialBorderResolutionContext.fromMap(mask.map),
        includeInstance: (_) => false,
      ),
      isEmpty,
    );
    expect(
      resolveSpatialBorderGroundReplacementsByLayerInContext(
        manifest: replacement.project,
        context: SpatialBorderResolutionContext.fromMap(replacement.map),
        includeInstance: (_) => false,
      ),
      isEmpty,
    );
    expect(
      resolveSpatialBorderGroundSurfacesInContext(
        manifest: replacement.project,
        context: SpatialBorderResolutionContext.fromMap(replacement.map),
        includeInstance: (_) => false,
      ),
      isEmpty,
    );
  });

  test(
    'a missing native instance invalidates its complete feature even if filtered out',
    () {
      final mask = maskFixture();
      final replacement = replacementFixture();
      MapData missing(MapData map) => map.copyWith(
        spatialScene: map.spatialScene!.copyWith(
          instances: map.spatialScene!.instances.skip(1),
        ),
      );
      final maskId = mask.map.spatialScene!.instances.first.id;
      final replacementId = replacement.map.spatialScene!.instances.first.id;
      expect(
        resolveSpatialBorderGroundMaskCellsByLayerInContext(
          manifest: mask.project,
          context: SpatialBorderResolutionContext.fromMap(missing(mask.map)),
          includeInstance: (id) => id != maskId,
        ),
        isEmpty,
      );
      expect(
        resolveSpatialBorderGroundReplacementsByLayerInContext(
          manifest: replacement.project,
          context: SpatialBorderResolutionContext.fromMap(
            missing(replacement.map),
          ),
          includeInstance: (id) => id != replacementId,
        ),
        isEmpty,
      );
      expect(
        resolveSpatialBorderGroundSurfacesInContext(
          manifest: replacement.project,
          context: SpatialBorderResolutionContext.fromMap(
            missing(replacement.map),
          ),
          includeInstance: (id) => id != replacementId,
        ),
        isEmpty,
      );
    },
  );
}
