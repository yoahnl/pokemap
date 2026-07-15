import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/masonry_line_fixture.dart';
import '../fixtures/border/post_and_rail_line_fixture.dart';

void main() {
  group('Border blueprint relink preview', () {
    test('linear-to-linear preserves authored data and applies atomically', () {
      final sourceRequest = MasonryLineFixture(
        parameters: masonryParameters(),
      ).request;
      final sourceResult = resolveBorderFeature(sourceRequest);
      expect(sourceResult.canApply, isTrue);
      final sourceFeature = _copyFeature(
        sourceRequest.feature,
        materialization: sourceResult.materialization,
      );
      final map = _mapWith(sourceFeature);
      final targetFixture = PostAndRailLineFixture(
        mapSize: map.size,
        geometry: sourceFeature.geometry,
      );

      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: sourceFeature.id,
        targetBlueprintId: 'fence-target',
        targetBlueprintRevision: targetFixture.request.blueprintRevision!,
        visualSnapshots: targetFixture.request.visualSnapshots,
        tileSizePx: targetFixture.request.tileSizePx,
        resolverVersion: targetFixture.request.resolverVersion,
      );

      expect(preview.kind, BorderRelinkKind.sameFamily);
      expect(preview.losses, isEmpty);
      expect(preview.canApplyResolvedRelink, isTrue);
      expect(preview.proposedRequest, isNotNull);
      expect(preview.proposedResult?.canApply, isTrue);
      expect(_featureOf(map), same(sourceFeature),
          reason: 'preview must not mutate the source map');

      final updated = applyBorderFeatureRelinkPreview(map, preview: preview);
      final applied = _featureOf(updated);

      expect(applied.blueprintId, 'fence-target');
      expect(applied.id, sourceFeature.id);
      expect(applied.name, sourceFeature.name);
      expect(applied.seed, sourceFeature.seed);
      expect(applied.geometry, same(sourceFeature.geometry));
      expect(applied.paramsOverride, same(sourceFeature.paramsOverride));
      expect(applied.overrides, sourceFeature.overrides);
      expect(applied.keepOutRegions, sourceFeature.keepOutRegions);
      expect(applied.materialization,
          same(preview.proposedResult!.materialization));
      expect(updated.layers[1], same(map.layers[1]),
          reason: 'unrelated layers, including collision, stay untouched');
    });

    test('missing source blueprint still infers the family from geometry', () {
      final sourceRequest = MasonryLineFixture().request;
      final missingSourceFeature = _copyFeature(
        sourceRequest.feature,
        blueprintId: 'removed-blueprint',
      );
      final map = _mapWith(missingSourceFeature);
      final targetFixture = PostAndRailLineFixture(
        mapSize: map.size,
        geometry: missingSourceFeature.geometry,
      );

      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: missingSourceFeature.id,
        targetBlueprintId: 'replacement-fence',
        targetBlueprintRevision: targetFixture.request.blueprintRevision!,
        visualSnapshots: targetFixture.request.visualSnapshots,
        tileSizePx: targetFixture.request.tileSizePx,
        resolverVersion: targetFixture.request.resolverVersion,
      );

      expect(preview.kind, BorderRelinkKind.sameFamily);
      expect(preview.sourceFamily, BorderGeometryFamily.linear);
      expect(preview.targetFamily, BorderGeometryFamily.linear);
      expect(preview.canApplyResolvedRelink, isTrue);
      expect(_featureOf(map).blueprintId, 'removed-blueprint');
    });

    test('cross-family change requires explicit reset with an exact loss list',
        () {
      final sourceRequest = MasonryLineFixture(
        parameters: masonryParameters(),
      ).request;
      final sourceResult = resolveBorderFeature(sourceRequest);
      final sourceFeature = BorderFeature(
        id: sourceRequest.feature.id,
        name: sourceRequest.feature.name,
        blueprintId: sourceRequest.feature.blueprintId,
        seed: sourceRequest.feature.seed,
        geometry: sourceRequest.feature.geometry,
        paramsOverride: sourceRequest.feature.paramsOverride,
        overrides: <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: 'old-orphan-slot',
            variationSalt: BorderSignedInt64.fromInt(9),
            suppressed: true,
            locked: false,
          ),
        ],
        keepOutRegions: <BorderKeepOutRegion>[
          BorderKeepOutRegion(
            id: 'old-keep-out',
            region: BorderRegionGeometry(
              width: 8,
              height: 8,
              cells: <bool>[
                true,
                ...List<bool>.filled(63, false),
              ],
            ),
          ),
        ],
        materialization: sourceResult.materialization,
      );
      final map = _mapWith(sourceFeature);

      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: sourceFeature.id,
        targetBlueprintId: 'organic-target',
        targetBlueprintRevision: _organicRevision(),
        visualSnapshots: const <BorderVisualSnapshot>[],
        tileSizePx: const GridSize(width: 16, height: 16),
        resolverVersion: borderResolverVersion,
      );

      expect(preview.kind, BorderRelinkKind.requiresFamilyReset);
      expect(preview.canApplyResolvedRelink, isFalse);
      expect(preview.proposedRequest, isNull);
      expect(preview.proposedResult, isNull);
      expect(
        preview.losses,
        <BorderRelinkLoss>[
          BorderRelinkLoss.geometry,
          BorderRelinkLoss.parameters,
          BorderRelinkLoss.overrides,
          BorderRelinkLoss.keepOutRegions,
          BorderRelinkLoss.materialization,
        ],
      );
      expect(
        () => applyBorderFeatureRelinkPreview(map, preview: preview),
        throwsStateError,
      );

      final reset = applyBorderFeatureFamilyReset(map, preview: preview);
      final applied = _featureOf(reset);
      expect(applied.id, sourceFeature.id);
      expect(applied.name, sourceFeature.name);
      expect(applied.seed, sourceFeature.seed);
      expect(applied.blueprintId, 'organic-target');
      expect(applied.geometry, isA<BorderRegionGeometry>());
      final region = applied.geometry as BorderRegionGeometry;
      expect((region.width, region.height), (8, 8));
      expect(region.cells, everyElement(isFalse));
      expect(applied.paramsOverride, isNull);
      expect(applied.overrides, isEmpty);
      expect(applied.keepOutRegions, isEmpty);
      expect(applied.materialization, isNull);
      expect(reset.layers[1], same(map.layers[1]));
    });

    test('optimistic fingerprint conflict leaves the map unchanged', () {
      final sourceRequest = MasonryLineFixture().request;
      final map = _mapWith(sourceRequest.feature);
      final targetFixture = PostAndRailLineFixture(
        mapSize: map.size,
        geometry: sourceRequest.feature.geometry,
      );
      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: sourceRequest.feature.id,
        targetBlueprintId: 'fence-target',
        targetBlueprintRevision: targetFixture.request.blueprintRevision!,
        visualSnapshots: targetFixture.request.visualSnapshots,
        tileSizePx: targetFixture.request.tileSizePx,
        resolverVersion: targetFixture.request.resolverVersion,
      );
      final changed = updateBorderFeatureSeed(
        map,
        layerId: 'border',
        featureId: sourceRequest.feature.id,
        seed: BorderSignedInt64.fromInt(999),
      );

      expect(
        applyBorderFeatureRelinkPreview(changed, preview: preview),
        same(changed),
      );
    });

    test('region-to-line reset is explicit and fingerprint protected', () {
      final regionFeature = BorderFeature(
        id: 'region-feature',
        name: 'Coast',
        blueprintId: 'old-organic',
        seed: BorderSignedInt64.fromInt(77),
        geometry: BorderRegionGeometry(
          width: 8,
          height: 8,
          cells: <bool>[true, ...List<bool>.filled(63, false)],
        ),
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      );
      final map = _mapWith(regionFeature);
      final target = MasonryLineFixture().request;
      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: regionFeature.id,
        targetBlueprintId: 'new-masonry',
        targetBlueprintRevision: target.blueprintRevision!,
        visualSnapshots: target.visualSnapshots,
        tileSizePx: target.tileSizePx,
        resolverVersion: target.resolverVersion,
      );

      expect(preview.kind, BorderRelinkKind.requiresFamilyReset);
      expect(preview.losses, <BorderRelinkLoss>[BorderRelinkLoss.geometry]);
      final applied = applyBorderFeatureFamilyReset(map, preview: preview);
      final geometry = _featureOf(applied).geometry as BorderStrokeGeometry;
      expect(geometry.strokes, isEmpty);

      final conflicted = updateBorderFeatureSeed(
        map,
        layerId: 'border',
        featureId: regionFeature.id,
        seed: BorderSignedInt64.fromInt(78),
      );
      expect(
        applyBorderFeatureFamilyReset(conflicted, preview: preview),
        same(conflicted),
      );
    });

    test('same blueprint is rejected before a misleading preview is built', () {
      final sourceRequest = MasonryLineFixture().request;
      final map = _mapWith(sourceRequest.feature);

      expect(
        () => prepareBorderFeatureRelink(
          map: map,
          layerId: 'border',
          featureId: sourceRequest.feature.id,
          targetBlueprintId: sourceRequest.feature.blueprintId,
          targetBlueprintRevision: sourceRequest.blueprintRevision!,
          visualSnapshots: sourceRequest.visualSnapshots,
          tileSizePx: sourceRequest.tileSizePx,
          resolverVersion: sourceRequest.resolverVersion,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapData _mapWith(BorderFeature feature) => MapData(
      id: 'relink-map',
      name: 'Relink map',
      size: const GridSize(width: 8, height: 8),
      version: ProjectVersion.v2,
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Borders',
          content: BorderLayerContent(features: <BorderFeature>[feature]),
        ),
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(64, false),
        ),
      ],
    );

BorderFeature _copyFeature(
  BorderFeature source, {
  String? blueprintId,
  BorderMaterialization? materialization,
}) =>
    BorderFeature(
      id: source.id,
      name: source.name,
      blueprintId: blueprintId ?? source.blueprintId,
      seed: source.seed,
      geometry: source.geometry,
      paramsOverride: source.paramsOverride,
      overrides: source.overrides,
      keepOutRegions: source.keepOutRegions,
      materialization: materialization ?? source.materialization,
    );

BorderFeature _featureOf(MapData map) =>
    (map.layers.first as BorderLayer).content.features.single;

BorderBlueprintRevision _organicRevision() => BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Organic target',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.organicEdge,
        primitives: const <BorderPublishedPrimitive>[],
        defaults: masonryParameters(),
        sortOrder: 0,
      ),
    );
