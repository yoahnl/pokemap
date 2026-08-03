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

    test('creates connected lines and previews side inversion without writes',
        () {
      final map = _map();
      final created = controller.createFeature(
        map: map,
        layerId: 'borders',
        blueprint: _record(
          id: 'cliff',
          template: BorderBlueprintTemplate.connectedLine,
        ),
        name: 'Falaise',
      );

      expect(created.feature.geometry, isA<BorderStrokeGeometry>());
      expect(
        (created.feature.geometry as BorderStrokeGeometry).strokes,
        isEmpty,
      );
      expect(created.feature.lineSide, BorderLineSide.primary);

      final source = _featureWithAuthoredOutput(created.feature);
      final preview = controller.previewLineSideToggle(source);

      expect(preview.lineSide, BorderLineSide.inverted);
      expect(preview.id, source.id);
      expect(preview.name, source.name);
      expect(preview.blueprintId, source.blueprintId);
      expect(preview.seed, source.seed);
      expect(preview.geometry, source.geometry);
      expect(preview.paramsOverride, source.paramsOverride);
      expect(preview.overrides, source.overrides);
      expect(preview.keepOutRegions, source.keepOutRegions);
      expect(preview.materialization, isNull);
      expect(
        (created.map.layers.whereType<BorderLayer>().single)
            .content
            .features
            .single
            .lineSide,
        BorderLineSide.primary,
      );
    });

    test('creates stone chains on inclusive grid edges', () {
      final created = controller.createFeature(
        map: _map(),
        layerId: 'borders',
        blueprint: _record(
          id: 'stone-chain',
          template: BorderBlueprintTemplate.stoneChainLine,
        ),
        name: 'Falaise de pierres',
      );

      final geometry = created.feature.geometry as BorderStrokeGeometry;
      expect(geometry.alignment, BorderStrokeAlignment.gridEdges);
      expect(geometry.strokes, isEmpty);
      expect(
        created.map.layers
            .whereType<BorderLayer>()
            .single
            .content
            .formatVersion,
        BorderLayerContent.formatVersionV3,
      );
    });

    test('promotes an empty V1 layer when creating a primary connected line',
        () {
      final map = _map();
      final before = map.layers.whereType<BorderLayer>().single.content;
      expect(before.formatVersion, BorderLayerContent.formatVersionV1);
      expect(before.features, isEmpty);

      final created = controller.createFeature(
        map: map,
        layerId: 'borders',
        blueprint: _record(
          id: 'cliff',
          template: BorderBlueprintTemplate.connectedLine,
        ),
        name: 'Falaise',
      );

      expect(created.feature.lineSide, BorderLineSide.primary);
      expect(
        created.map.layers
            .whereType<BorderLayer>()
            .single
            .content
            .formatVersion,
        BorderLayerContent.formatVersionV2,
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

    test('same-family blueprint change resolves then applies atomically', () {
      const collision = MapLayer.collision(
        id: 'collision',
        name: 'Collision',
      );
      final sourceBlueprint = _record(
        id: 'coast-a',
        template: BorderBlueprintTemplate.organicEdge,
        primitives: <BorderPublishedPrimitive>[_primitive()],
      );
      final targetBlueprint = _record(
        id: 'coast-b',
        template: BorderBlueprintTemplate.organicEdge,
        primitives: <BorderPublishedPrimitive>[_primitive()],
      );
      final feature = BorderFeature(
        id: 'feature',
        name: 'Côte',
        blueprintId: sourceBlueprint.id,
        seed: BorderSignedInt64.fromInt(7),
        geometry: BorderRegionGeometry(
          width: 5,
          height: 4,
          cells: const <bool>[
            true,
            true,
            false,
            false,
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
          ],
        ),
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      );
      final sourceResult = resolveBorderFeature(
        BorderResolutionRequest(
          mapSize: const GridSize(width: 5, height: 4),
          tileSizePx: const GridSize(width: 16, height: 16),
          blueprintId: sourceBlueprint.id,
          blueprintRevision: sourceBlueprint.latestPublished,
          feature: feature,
          visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
          resolverVersion: borderResolverVersion,
        ),
      );
      expect(sourceResult.canApply, isTrue);
      final materialized = BorderFeature(
        id: feature.id,
        name: feature.name,
        blueprintId: feature.blueprintId,
        seed: feature.seed,
        geometry: feature.geometry,
        paramsOverride: feature.paramsOverride,
        overrides: feature.overrides,
        keepOutRegions: feature.keepOutRegions,
        materialization: sourceResult.materialization,
      );
      final source = upsertBorderFeature(
        _map(collision: collision),
        layerId: 'borders',
        feature: materialized,
      );
      final beforeJson = source.toJson();

      final preview = controller.previewBlueprintChange(
        map: source,
        layerId: 'borders',
        featureId: materialized.id,
        sourceBlueprint: sourceBlueprint,
        targetBlueprint: targetBlueprint,
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        tileSizePx: const GridSize(width: 16, height: 16),
        resolverVersion: borderResolverVersion,
      );

      expect(preview.canApply, isTrue);
      expect(preview.canReset, isFalse);
      expect(preview.before.feature, materialized);
      expect(preview.before.template, BorderBlueprintTemplate.organicEdge);
      expect(preview.before.isMaterialized, isTrue);
      expect(preview.after.feature.blueprintId, 'coast-b');
      expect(preview.after.template, BorderBlueprintTemplate.organicEdge);
      expect(preview.after.feature.geometry, same(materialized.geometry));
      expect(preview.after.feature.overrides, materialized.overrides);
      expect(preview.after.feature.keepOutRegions, materialized.keepOutRegions);
      expect(preview.after.feature.materialization, isNotNull);
      expect(preview.after.isMaterialized, isTrue);
      expect(preview.relink.proposedResult?.canApply, isTrue);
      expect(preview.consequence, contains('résolu'));
      expect(source.toJson(), beforeJson, reason: 'preview must be read-only');

      final indistinguishableClone = MapData.fromJson(source.toJson());
      expect(indistinguishableClone.toJson(), source.toJson());
      expect(indistinguishableClone, isNot(same(source)));
      expect(
        () => controller.applyBlueprintChange(
          map: indistinguishableClone,
          preview: preview,
        ),
        throwsStateError,
        reason: 'an async confirmation cannot cross editor documents',
      );

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
      expect(afterFeature.geometry, same(materialized.geometry));
      expect(afterFeature.overrides, materialized.overrides);
      expect(afterFeature.keepOutRegions, materialized.keepOutRegions);
      expect(afterFeature.materialization,
          same(preview.relink.proposedResult!.materialization));
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
        visualSnapshots: const <BorderVisualSnapshot>[],
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      expect(preview.canApply, isFalse);
      expect(preview.canReset, isTrue);
      expect(preview.canCreateNewFeature, isTrue);
      expect(
        preview.losses,
        <BorderRelinkLoss>[
          BorderRelinkLoss.geometry,
          BorderRelinkLoss.overrides,
          BorderRelinkLoss.keepOutRegions,
          BorderRelinkLoss.materialization,
        ],
      );
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
      expect(preview.consequence, isNot(contains('paramètres personnalisés')));
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

    test('local variation, replacement and move produce preview-only drafts',
        () {
      final feature = BorderFeature(
        id: 'feature',
        name: 'Bordure',
        blueprintId: 'coast',
        seed: BorderSignedInt64.fromInt(7),
        geometry: BorderRegionGeometry(
          width: 5,
          height: 4,
          cells: List<bool>.filled(20, false),
        ),
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
        materialization: _materialization(),
      );

      final varied = controller.previewLocalVariation(
        feature: feature,
        slotKey: 'slot-a',
      );
      final variation = varied.overrides.single;
      expect(variation.slotKey, 'slot-a');
      expect(variation.variationSalt, isNot(BorderSignedInt64.zero));
      expect(varied.materialization, isNull);

      final replaced = controller.previewReplacement(
        feature: varied,
        slotKey: 'slot-a',
        primitiveId: 'alternate-primitive',
      );
      expect(replaced.overrides.single.replacementPrimitiveId,
          'alternate-primitive');
      expect(replaced.overrides.single.variationSalt, variation.variationSalt);

      final moved = controller.previewMove(
        feature: replaced,
        slotKey: 'slot-a',
        offset: const BorderPixelOffset(x: 4, y: -2),
      );
      expect(
        moved.overrides.single.offsetDeltaPx,
        const BorderPixelOffset(x: 4, y: -2),
      );
      expect(feature.overrides, isEmpty);
      expect(feature.materialization, isNotNull);
    });

    test('remove and lock create valid mutually exclusive slot corrections',
        () {
      final feature = BorderFeature(
        id: 'feature',
        name: 'Bordure',
        blueprintId: 'coast',
        seed: BorderSignedInt64.fromInt(7),
        geometry: BorderRegionGeometry(
          width: 5,
          height: 4,
          cells: List<bool>.filled(20, false),
        ),
        overrides: <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: 'slot-a',
            variationSalt: BorderSignedInt64.fromInt(4),
            suppressed: false,
            locked: false,
            replacementPrimitiveId: 'alternate-primitive',
            offsetDeltaPx: const BorderPixelOffset(x: 2, y: -1),
          ),
        ],
        keepOutRegions: const <BorderKeepOutRegion>[],
        materialization: _materialization(),
      );

      final removed = controller.previewRemoval(
        feature: feature,
        slotKey: 'slot-a',
      );
      final suppression = removed.overrides.single;
      expect(suppression.suppressed, isTrue);
      expect(suppression.variationSalt, BorderSignedInt64.zero);
      expect(suppression.locked, isFalse);
      expect(suppression.lockedPlacement, isNull);
      expect(suppression.replacementPrimitiveId, isNull);
      expect(suppression.offsetDeltaPx, isNull);

      final placement = _placement();
      final locked = controller.previewLock(
        feature: feature,
        placement: placement,
      );
      final lock = locked.overrides.single;
      expect(lock.suppressed, isFalse);
      expect(lock.variationSalt, BorderSignedInt64.zero);
      expect(lock.locked, isTrue);
      expect(lock.lockedPlacement, same(placement));
      expect(lock.replacementPrimitiveId, isNull);
      expect(lock.offsetDeltaPx, isNull);
      expect(feature.materialization, isNotNull);
    });

    test('keep-out preview creates a clipped stable mask around the slot', () {
      final existing = BorderKeepOutRegion(
        id: 'border_keep_out',
        region: BorderRegionGeometry(
          width: 5,
          height: 4,
          cells: <bool>[true, ...List<bool>.filled(19, false)],
        ),
      );
      final feature = BorderFeature(
        id: 'feature',
        name: 'Bordure',
        blueprintId: 'coast',
        seed: BorderSignedInt64.fromInt(7),
        geometry: BorderRegionGeometry(
          width: 5,
          height: 4,
          cells: List<bool>.filled(20, false),
        ),
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: <BorderKeepOutRegion>[existing],
        materialization: _materialization(),
      );

      final draft = controller.previewKeepOut(
        feature: feature,
        placement: _placement(),
        mapSize: const GridSize(width: 5, height: 4),
        radiusCells: 1,
      );

      expect(draft.keepOutRegions, hasLength(2));
      expect(draft.keepOutRegions.first, same(existing));
      expect(draft.keepOutRegions.last.id, 'border_keep_out_2');
      expect(
        draft.keepOutRegions.last.region.cells,
        <bool>[
          true,
          true,
          false,
          false,
          false,
          true,
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      );
      expect(draft.materialization, isNull);
      expect(feature.keepOutRegions, <BorderKeepOutRegion>[existing]);
    });
  });
}

MapData _map({MapLayer? collision}) => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
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
  List<BorderPublishedPrimitive> primitives =
      const <BorderPublishedPrimitive>[],
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
              primitives: primitives,
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

BorderPublishedPrimitive _primitive() => BorderPublishedPrimitive(
      id: 'structure',
      sourceElementId: 'structure-source',
      visualSnapshotId: _snapshotId,
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 8, y: 8),
      transforms: BorderTransformPolicy(
        allowFlipX: true,
        allowedQuarterTurns: const <int>[0, 1, 2, 3],
      ),
      publishedMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'asset-structure',
        pixelSize: const GridSize(width: 16, height: 16),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
        defaultAnchorPx: const BorderPixelPos(x: 8, y: 8),
        occupancyMaskRle: encodeBorderRleMask(
          List<bool>.filled(16 * 16, true),
        ),
      ),
    );

BorderVisualSnapshot _snapshot() => BorderVisualSnapshot(
      id: _snapshotId,
      contentFingerprint: 'a' * 64,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/a.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
          durationMs: 100,
        ),
      ],
    );

const _snapshotId =
    'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

BorderFeature _featureWithAuthoredOutput(BorderFeature feature) =>
    BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      lineSide: feature.lineSide,
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

BorderResolvedPlacement _placement() => BorderResolvedPlacement(
      id: 'placement-a',
      slotKey: 'slot-a',
      primitiveId: 'primitive-a',
      visualSnapshotId:
          'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      anchorCell: const GridPos(x: 0, y: 0),
      topLeftWorldPx: const BorderPixelPos(x: 0, y: 0),
      opaqueWorldBoundsPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
      transform: BorderSpriteTransform(quarterTurns: 0, flipX: false),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: borderDrawBandV1Index(BorderDrawBand.structure),
        anchorRowMajor: 0,
        passIndex: 0,
        rank: 0,
        ordinalLocal: 0,
        slotKey: 'slot-a',
      ),
    );
