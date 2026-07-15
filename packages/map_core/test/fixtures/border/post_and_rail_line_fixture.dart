import 'package:map_core/map_core.dart';

final class PostAndRailLineFixture {
  PostAndRailLineFixture({
    List<BorderStroke>? strokes,
    List<BorderPublishedPrimitive>? primitives,
    List<BorderVisualSnapshot>? visualSnapshots,
    BorderGenerationParams? parameters,
    bool reverseInputs = false,
    List<BorderSlotOverride> overrides = const <BorderSlotOverride>[],
    List<BorderKeepOutRegion> keepOutRegions = const <BorderKeepOutRegion>[],
    BorderPublishedGround? ground,
    BorderBlueprintTemplate template = BorderBlueprintTemplate.postAndRailLine,
    BorderFeatureGeometry? geometry,
    GridSize mapSize = const GridSize(width: 10, height: 10),
    GridSize tileSizePx = const GridSize(width: 16, height: 16),
    bool published = true,
    int featureSeed = 53,
  }) {
    final sourcePrimitives = primitives ??
        <BorderPublishedPrimitive>[
          fencePrimitive(
            id: 'post-a',
            fingerprintCharacter: 'd',
            role: BorderPrimitiveRole.post,
            width: 8,
            height: 12,
          ),
          fencePrimitive(
            id: 'span-a',
            fingerprintCharacter: 'e',
            role: BorderPrimitiveRole.span,
            width: 16,
            height: 6,
          ),
        ];
    final sourceSnapshots = visualSnapshots ??
        <BorderVisualSnapshot>[
          for (final primitive in sourcePrimitives) fenceSnapshotFor(primitive),
        ];
    final orderedPrimitives = reverseInputs
        ? sourcePrimitives.reversed.toList(growable: false)
        : sourcePrimitives;
    final orderedSnapshots = reverseInputs
        ? sourceSnapshots.reversed.toList(growable: false)
        : sourceSnapshots;
    final definition = BorderBlueprintPublishedDefinition(
      name: 'Cloture test',
      previewSeed: BorderSignedInt64.fromInt(23),
      template: template,
      primitives: orderedPrimitives,
      defaults: parameters ?? fenceParameters(),
      ground: ground,
      sortOrder: 0,
    );
    request = BorderResolutionRequest(
      mapSize: mapSize,
      tileSizePx: tileSizePx,
      blueprintId: 'fence-test',
      blueprintRevision: published
          ? BorderBlueprintRevision(
              revision: 2,
              definition: definition,
            )
          : null,
      feature: BorderFeature(
        id: 'fence-feature',
        name: 'Cloture',
        blueprintId: 'fence-test',
        seed: BorderSignedInt64.fromInt(featureSeed),
        geometry: geometry ??
            BorderStrokeGeometry(
              strokes: strokes ??
                  <BorderStroke>[
                    BorderStroke(
                      id: 'main',
                      points: const <GridPos>[
                        GridPos(x: 1, y: 3),
                        GridPos(x: 2, y: 3),
                        GridPos(x: 3, y: 3),
                        GridPos(x: 4, y: 3),
                        GridPos(x: 5, y: 3),
                      ],
                      closed: false,
                    ),
                  ],
            ),
        paramsOverride: parameters,
        overrides: overrides,
        keepOutRegions: keepOutRegions,
      ),
      visualSnapshots: orderedSnapshots,
      resolverVersion: borderResolverVersion,
    );
  }

  late final BorderResolutionRequest request;
}

BorderGenerationParams fenceParameters({
  int irregularityPermille = 0,
  int detailDensityPermille = 0,
  int variationPermille = 1000,
  int maxOverlapPx = 0,
  int gapTolerancePx = 0,
  int depthRows = 1,
}) =>
    BorderGenerationParams(
      irregularityPermille: irregularityPermille,
      detailDensityPermille: detailDensityPermille,
      variationPermille: variationPermille,
      maxOverlapPx: maxOverlapPx,
      gapTolerancePx: gapTolerancePx,
      depthRows: depthRows,
    );

BorderPublishedPrimitive fencePrimitive({
  required String id,
  required String fingerprintCharacter,
  required BorderPrimitiveRole role,
  int width = 16,
  int height = 8,
  int weight = 1,
  List<int> allowedQuarterTurns = const <int>[0, 1, 2, 3],
  bool allowFlipX = false,
  BorderPixelPos? anchorPx,
  BorderPixelRect? opaqueBounds,
  List<bool>? occupancy,
  String? occupancyMaskRle,
}) {
  final resolvedAnchor =
      anchorPx ?? BorderPixelPos(x: width ~/ 2, y: height ~/ 2);
  return BorderPublishedPrimitive(
    id: id,
    sourceElementId: 'element-$id',
    visualSnapshotId: fenceSnapshotId(fingerprintCharacter),
    role: role,
    weight: weight,
    anchorPx: resolvedAnchor,
    transforms: BorderTransformPolicy(
      allowFlipX: allowFlipX,
      allowedQuarterTurns: allowedQuarterTurns,
    ),
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset-$id',
      pixelSize: GridSize(width: width, height: height),
      opaqueBounds: opaqueBounds ??
          BorderPixelRect(x: 0, y: 0, width: width, height: height),
      defaultAnchorPx: resolvedAnchor,
      occupancyMaskRle: occupancyMaskRle ??
          encodeBorderRleMask(
            occupancy ?? List<bool>.filled(width * height, true),
          ),
    ),
  );
}

BorderVisualSnapshot fenceSnapshotFor(BorderPublishedPrimitive primitive) {
  final fingerprint = primitive.visualSnapshotId.substring(
    'border-snapshot-sha256:'.length,
  );
  final size = primitive.publishedMetrics.pixelSize;
  return BorderVisualSnapshot(
    id: primitive.visualSnapshotId,
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/$fingerprint.png',
        sourceRectPx: BorderPixelRect(
          x: 0,
          y: 0,
          width: size.width,
          height: size.height,
        ),
        durationMs: 100,
      ),
    ],
  );
}

String fenceSnapshotId(String character) =>
    'border-snapshot-sha256:${character * 64}';
