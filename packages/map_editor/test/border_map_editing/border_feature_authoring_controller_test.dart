import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_authoring_controller.dart';

void main() {
  group('BorderFeatureAuthoringController', () {
    const controller = BorderFeatureAuthoringController();

    test('creates unique region features from a published blueprint', () {
      final map = _map();
      final blueprint = _record(
        id: 'coast',
        template: BorderBlueprintTemplate.organicEdge,
      );

      final first = controller.createFeature(
        map: map,
        layerId: 'borders',
        blueprint: blueprint,
        name: 'Côte principale',
      );
      final second = controller.createFeature(
        map: first.map,
        layerId: 'borders',
        blueprint: blueprint,
        name: 'Îlot',
      );

      expect(first.feature.id, 'border_feature');
      expect(second.feature.id, 'border_feature_2');
      expect(first.feature.geometry, isA<BorderRegionGeometry>());
      final geometry = first.feature.geometry as BorderRegionGeometry;
      expect(geometry.width, map.size.width);
      expect(geometry.height, map.size.height);
      expect(geometry.cells, everyElement(isFalse));
      expect(first.feature.blueprintId, 'coast');
      expect(
        (second.map.layers.last as BorderLayer)
            .content
            .features
            .map((feature) => feature.id),
        <String>['border_feature', 'border_feature_2'],
      );
    });

    test('rejects unpublished or deprecated blueprints for new features', () {
      expect(
        () => controller.createFeature(
          map: _map(),
          layerId: 'borders',
          blueprint: _record(
            id: 'draft',
            template: BorderBlueprintTemplate.organicEdge,
            published: false,
          ),
          name: 'Draft',
        ),
        throwsStateError,
      );
      expect(
        () => controller.createFeature(
          map: _map(),
          layerId: 'borders',
          blueprint: _record(
            id: 'deprecated',
            template: BorderBlueprintTemplate.organicEdge,
            isDeprecated: true,
          ),
          name: 'Deprecated',
        ),
        throwsStateError,
      );
    });

    test('renames, reorders and deletes without touching collision layers', () {
      const collision = MapLayer.collision(
        id: 'collision',
        name: 'Collision',
      );
      final blueprint = _record(
        id: 'coast',
        template: BorderBlueprintTemplate.organicEdge,
      );
      var map = _map(collision: collision);
      map = controller
          .createFeature(
            map: map,
            layerId: 'borders',
            blueprint: blueprint,
            name: 'First',
          )
          .map;
      map = controller
          .createFeature(
            map: map,
            layerId: 'borders',
            blueprint: blueprint,
            name: 'Second',
          )
          .map;
      final collisionJson = collision.toJson();

      map = controller.renameFeature(
        map: map,
        layerId: 'borders',
        featureId: 'border_feature',
        name: 'Renamed',
      );
      map = controller.reorderFeature(
        map: map,
        layerId: 'borders',
        featureId: 'border_feature',
        newIndex: 1,
      );
      map = controller.deleteFeature(
        map: map,
        layerId: 'borders',
        featureId: 'border_feature_2',
      );

      final border = map.layers.whereType<BorderLayer>().single;
      expect(border.content.features.single.id, 'border_feature');
      expect(border.content.features.single.name, 'Renamed');
      final afterCollision = map.layers.whereType<CollisionLayer>().single;
      expect(afterCollision, same(collision));
      expect(afterCollision.toJson(), collisionJson);
    });

    test(
        'previews a complete compatible state and drops stale materialization on apply',
        () {
      const collision = MapLayer.collision(
        id: 'collision',
        name: 'Collision',
      );
      final created = controller
          .createFeature(
            map: _map(collision: collision),
            layerId: 'borders',
            blueprint: _record(
              id: 'coast-a',
              template: BorderBlueprintTemplate.organicEdge,
            ),
            name: 'Côte',
          )
          .map;
      final initialFeature = created.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single;
      final source = upsertBorderFeature(
        created,
        layerId: 'borders',
        feature: _featureWithAuthoredOutput(initialFeature),
      );
      final beforeFeature =
          source.layers.whereType<BorderLayer>().single.content.features.single;
      final beforeJson = source.toJson();

      final preview = controller.previewBlueprintChange(
        map: source,
        layerId: 'borders',
        featureId: beforeFeature.id,
        sourceBlueprint: _record(
          id: 'coast-a',
          template: BorderBlueprintTemplate.organicEdge,
        ),
        targetBlueprint: _record(
          id: 'coast-b',
          template: BorderBlueprintTemplate.organicEdge,
        ),
      );

      expect(preview.canApply, isTrue);
      expect(preview.canReset, isFalse);
      expect(preview.before.feature, beforeFeature);
      expect(preview.before.template, BorderBlueprintTemplate.organicEdge);
      expect(preview.before.isMaterialized, isTrue);
      expect(preview.after.feature.blueprintId, 'coast-b');
      expect(preview.after.template, BorderBlueprintTemplate.organicEdge);
      expect(preview.after.feature.geometry, same(beforeFeature.geometry));
      expect(preview.after.feature.overrides, beforeFeature.overrides);
      expect(
          preview.after.feature.keepOutRegions, beforeFeature.keepOutRegions);
      expect(preview.after.feature.materialization, isNull);
      expect(preview.after.isMaterialized, isFalse);
      expect(preview.consequence, contains('matérialisation'));
      expect(source.toJson(), beforeJson, reason: 'preview must be read-only');

      final changed = controller.applyBlueprintChange(
        map: source,
        preview: preview,
      );
      final afterFeature = changed.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single;
      expect(afterFeature.blueprintId, 'coast-b');
      expect(afterFeature.geometry, same(beforeFeature.geometry));
      expect(afterFeature.overrides, beforeFeature.overrides);
      expect(afterFeature.keepOutRegions, beforeFeature.keepOutRegions);
      expect(afterFeature.materialization, isNull);
      expect(afterFeature, preview.after.feature);
      expect(
        changed.layers.whereType<CollisionLayer>().single,
        same(collision),
      );
    });

    test('region-to-line preview offers complete reset or separate creation',
        () {
      final created = controller
          .createFeature(
            map: _map(),
            layerId: 'borders',
            blueprint: _record(
              id: 'coast',
              template: BorderBlueprintTemplate.organicEdge,
            ),
            name: 'Côte',
          )
          .map;
      final initialFeature = created.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single;
      final source = upsertBorderFeature(
        created,
        layerId: 'borders',
        feature: _featureWithAuthoredOutput(initialFeature),
      );
      final beforeJson = source.toJson();
      final wall = _record(
        id: 'wall',
        template: BorderBlueprintTemplate.masonryLine,
      );

      final preview = controller.previewBlueprintChange(
        map: source,
        layerId: 'borders',
        featureId: 'border_feature',
        sourceBlueprint: _record(
          id: 'coast',
          template: BorderBlueprintTemplate.organicEdge,
        ),
        targetBlueprint: wall,
      );

      expect(preview.canApply, isFalse);
      expect(preview.canReset, isTrue);
      expect(preview.canCreateNewFeature, isTrue);
      expect(preview.blockedReason, contains('région'));
      expect(preview.blockedReason, contains('ligne'));
      expect(preview.before.feature.materialization, isNotNull);
      expect(preview.after.template, BorderBlueprintTemplate.masonryLine);
      expect(preview.after.feature.geometry, isA<BorderStrokeGeometry>());
      expect(
        (preview.after.feature.geometry as BorderStrokeGeometry).strokes,
        isEmpty,
      );
      expect(preview.after.feature.overrides, isEmpty);
      expect(preview.after.feature.keepOutRegions, isEmpty);
      expect(preview.after.feature.materialization, isNull);
      expect(preview.consequence, contains('remise à zéro'));
      expect(source.toJson(), beforeJson, reason: 'preview must be read-only');
      expect(
        () => controller.applyBlueprintChange(map: source, preview: preview),
        throwsStateError,
      );

      final reset = controller.resetFeatureForBlueprintChange(
        map: source,
        preview: preview,
      );
      final resetFeatures =
          reset.layers.whereType<BorderLayer>().single.content.features;
      expect(resetFeatures, hasLength(1));
      expect(resetFeatures.single, preview.after.feature);

      final separate = controller.createFeatureFromBlueprintChange(
        map: source,
        preview: preview,
        targetBlueprint: wall,
        name: 'Muret séparé',
      );
      final separateFeatures =
          separate.map.layers.whereType<BorderLayer>().single.content.features;
      expect(separateFeatures, hasLength(2));
      expect(separateFeatures.first, preview.before.feature);
      expect(separate.feature.id, isNot(preview.before.feature.id));
      expect(separate.feature.blueprintId, 'wall');
      expect(separate.feature.geometry, isA<BorderStrokeGeometry>());
      expect(separate.feature.materialization, isNull);
      expect(source.toJson(), beforeJson,
          reason: 'separate creation must not mutate the source map');
    });
  });
}

MapData _map({MapLayer? collision}) => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 5, height: 4),
      layers: <MapLayer>[
        if (collision != null) collision,
        const MapLayer.border(id: 'borders', name: 'Bordures'),
      ],
    );

BorderBlueprintRecord _record({
  required String id,
  required BorderBlueprintTemplate template,
  bool published = true,
  bool isDeprecated = false,
}) {
  final draftDefinition = BorderBlueprintDraftDefinition(
    name: id,
    previewSeed: BorderSignedInt64.zero,
    template: template,
    primitives: const <BorderPrimitiveDraft>[],
    defaults: _params(),
    sortOrder: 0,
  );
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(
      baseRevision: published ? 1 : 0,
      definition: draftDefinition,
    ),
    latestPublished: published
        ? BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: id,
              previewSeed: BorderSignedInt64.zero,
              template: template,
              primitives: const <BorderPublishedPrimitive>[],
              defaults: _params(),
              sortOrder: 0,
            ),
          )
        : null,
    isDeprecated: isDeprecated,
  );
}

BorderGenerationParams _params() => BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    );

BorderFeature _featureWithAuthoredOutput(BorderFeature feature) =>
    BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: <BorderSlotOverride>[
        BorderSlotOverride(
          slotKey: 'slot-a',
          variationSalt: BorderSignedInt64.zero,
          suppressed: true,
          locked: false,
        ),
      ],
      keepOutRegions: <BorderKeepOutRegion>[
        BorderKeepOutRegion(
          id: 'keep-out-a',
          region: BorderRegionGeometry(
            width: 5,
            height: 4,
            cells: <bool>[
              true,
              ...List<bool>.filled(19, false),
            ],
          ),
        ),
      ],
      materialization: _materialization(),
    );

BorderMaterialization _materialization() => BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: 1,
        blueprintRevision: 1,
        components: BorderInputFingerprints(
          blueprint:
              'sha256:0000000000000000000000000000000000000000000000000000000000000000',
          geometryAndSeed:
              'sha256:1111111111111111111111111111111111111111111111111111111111111111',
          parameters:
              'sha256:2222222222222222222222222222222222222222222222222222222222222222',
          overrides:
              'sha256:3333333333333333333333333333333333333333333333333333333333333333',
          keepOutRegions:
              'sha256:4444444444444444444444444444444444444444444444444444444444444444',
          mapContext:
              'sha256:5555555555555555555555555555555555555555555555555555555555555555',
          visualSnapshots:
              'sha256:6666666666666666666666666666666666666666666666666666666666666666',
        ),
        inputFingerprint:
            'sha256:7777777777777777777777777777777777777777777777777777777777777777',
        outputFingerprint:
            'sha256:8888888888888888888888888888888888888888888888888888888888888888',
      ),
      ground: <BorderResolvedGroundCell>[
        BorderResolvedGroundCell(
          x: 0,
          y: 0,
          visualSnapshotId:
              'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          resolvedRole: SurfaceVariantRole.isolated,
        ),
      ],
      placements: const <BorderResolvedPlacement>[],
    );
