import 'package:map_core/map_core.dart';

final class MaterializedBorderCollisionFixture {
  MaterializedBorderCollisionFixture({
    ElementCollisionProfile? profile,
    BorderSpriteTransform? transform,
    BorderPixelOffset offset = const BorderPixelOffset(x: 0, y: 0),
    bool suppressed = false,
    int segments = 1,
  }) {
    final metrics = BorderPrimitiveAssetMetrics(
      assetFingerprint: 'source-asset',
      pixelSize: const GridSize(width: 32, height: 64),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 32, height: 64),
      defaultAnchorPx: const BorderPixelPos(x: 0, y: 48),
      occupancyMaskRle: encodeBorderRleMask(List<bool>.filled(32 * 64, true)),
    );
    final transforms = BorderTransformPolicy(
      allowFlipX: true,
      allowedQuarterTurns: [0, 1, 2, 3],
    );
    final params = BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 32,
      gapTolerancePx: 32,
      depthRows: 1,
      allowAutoRotation: false,
    );
    final primitive = BorderPublishedPrimitive(
      id: 'panel',
      sourceElementId: 'wall',
      visualSnapshotId: snapshotId,
      role: BorderPrimitiveRole.structureLarge,
      weight: 100,
      anchorPx: const BorderPixelPos(x: 0, y: 48),
      transforms: transforms,
      publishedMetrics: metrics,
    );
    revision = BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Wall',
        previewSeed: BorderSignedInt64.fromInt(0),
        template: BorderBlueprintTemplate.masonryLine,
        primitives: [primitive],
        defaults: params,
        sortOrder: 0,
      ),
    );
    final snapshot = BorderVisualSnapshot(
      id: snapshotId,
      contentFingerprint: fingerprint,
      frames: [
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/$fingerprint.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 64),
          durationMs: 120,
        ),
      ],
    );
    final base = BorderFeature(
      id: 'wall-feature',
      name: 'Wall',
      blueprintId: 'wall-border',
      seed: BorderSignedInt64.fromInt(0),
      geometry: BorderStrokeGeometry(
        strokes: [
          BorderStroke(
            id: 'line',
            points: [
              for (var i = 0; i <= segments; i++) GridPos(x: 2 + i, y: 4)
            ],
            closed: false,
          ),
        ],
      ),
      overrides: const [],
      keepOutRegions: const [],
      paramsOverride: params,
    );
    BorderResolutionRequest requestFor(BorderFeature value) =>
        BorderResolutionRequest(
          mapSize: const GridSize(width: 10, height: 10),
          tileSizePx: const GridSize(width: 32, height: 32),
          blueprintId: base.blueprintId,
          blueprintRevision: revision,
          feature: value,
          visualSnapshots: [snapshot],
          resolverVersion: borderResolverVersion,
        );
    final baseResult = resolveBorderFeature(requestFor(base));
    if (!baseResult.canApply ||
        baseResult.materialization!.placements.length != segments) {
      throw StateError(
          'Expected one canonical wall panel: ${baseResult.diagnostics.map((d) => d.code).toList()}');
    }
    final corrected = BorderFeature(
      id: base.id,
      name: base.name,
      blueprintId: base.blueprintId,
      seed: base.seed,
      geometry: base.geometry,
      paramsOverride: params,
      keepOutRegions: const [],
      overrides: [
        BorderSlotOverride(
          slotKey: baseResult.materialization!.placements.first.slotKey,
          variationSalt: BorderSignedInt64.fromInt(0),
          suppressed: suppressed,
          locked: false,
          offsetDeltaPx: suppressed ? null : offset,
          transformOverride: suppressed ? null : transform,
        ),
      ],
    );
    final result = resolveBorderFeature(requestFor(corrected));
    if (!result.canApply) {
      throw StateError(
          'Canonical wall resolution failed: ${result.diagnostics.map((d) => d.code).toList()}');
    }
    feature = BorderFeature(
      id: corrected.id,
      name: corrected.name,
      blueprintId: corrected.blueprintId,
      seed: corrected.seed,
      geometry: corrected.geometry,
      paramsOverride: corrected.paramsOverride,
      overrides: corrected.overrides,
      keepOutRegions: corrected.keepOutRegions,
      materialization: result.materialization,
    );
    map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 10, height: 10),
      layers: [
        MapLayer.border(
          id: 'borders',
          name: 'Borders',
          content: BorderLayerContent(formatVersion: 3, features: [feature]),
        ),
      ],
    );
    project = ProjectManifest(
      name: 'Project',
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      elements: [
        ProjectElementEntry(
          id: 'wall',
          name: 'Wall',
          tilesetId: 'tiles',
          categoryId: 'architecture',
          frames: const [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2)),
          ],
          collisionProfile: profile,
        ),
      ],
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 5,
        records: [
          BorderBlueprintRecord(
            id: 'wall-border',
            latestPublished: revision,
            draft: BorderBlueprintDraft(
              baseRevision: 1,
              definition: BorderBlueprintDraftDefinition(
                name: 'Wall',
                previewSeed: BorderSignedInt64.fromInt(0),
                template: BorderBlueprintTemplate.masonryLine,
                primitives: [
                  BorderPrimitiveDraft(
                    id: primitive.id,
                    sourceElementId: primitive.sourceElementId,
                    role: primitive.role,
                    weight: primitive.weight,
                    anchorPx: primitive.anchorPx,
                    transforms: transforms,
                    currentMetrics: metrics,
                  ),
                ],
                defaults: params,
                sortOrder: 0,
              ),
            ),
          ),
        ],
        visualSnapshots: [snapshot],
      ),
    );
  }

  static const fingerprint =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  static const snapshotId = 'border-snapshot-sha256:$fingerprint';
  late final MapData map;
  late final ProjectManifest project;
  late final BorderFeature feature;
  late final BorderBlueprintRevision revision;

  MapData withFeature(BorderFeature value) => map.copyWith(layers: [
        (map.layers.single as BorderLayer).copyWith(
          content: BorderLayerContent(formatVersion: 3, features: [value]),
        ),
      ]);
}
