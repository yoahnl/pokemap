import 'package:map_core/map_core.dart';

final class MasonryLineFixture {
  MasonryLineFixture({
    List<BorderStroke>? strokes,
    List<BorderPublishedPrimitive>? primitives,
    BorderGenerationParams? parameters,
    bool reverseInputs = false,
    List<BorderSlotOverride> overrides = const <BorderSlotOverride>[],
    List<BorderKeepOutRegion> keepOutRegions = const <BorderKeepOutRegion>[],
    BorderPublishedGround? ground,
    BorderBlueprintTemplate template = BorderBlueprintTemplate.masonryLine,
    int featureSeed = 41,
    BorderLineSide lineSide = BorderLineSide.primary,
  }) {
    final sourcePrimitives = primitives ??
        <BorderPublishedPrimitive>[
          masonryPrimitive(
            id: 'stone-a',
            fingerprintCharacter: 'a',
          ),
          masonryPrimitive(
            id: 'stone-b',
            fingerprintCharacter: 'b',
          ),
        ];
    final sourceSnapshots = <BorderVisualSnapshot>[
      for (final primitive in sourcePrimitives) masonrySnapshotFor(primitive),
    ];
    final orderedPrimitives = reverseInputs
        ? sourcePrimitives.reversed.toList(growable: false)
        : sourcePrimitives;
    final orderedSnapshots = reverseInputs
        ? sourceSnapshots.reversed.toList(growable: false)
        : sourceSnapshots;
    final definition = BorderBlueprintPublishedDefinition(
      name: 'Muret test',
      previewSeed: BorderSignedInt64.fromInt(19),
      template: template,
      primitives: orderedPrimitives,
      defaults: parameters ?? masonryParameters(),
      ground: ground,
      sortOrder: 0,
    );
    request = BorderResolutionRequest(
      mapSize: const GridSize(width: 8, height: 8),
      tileSizePx: const GridSize(width: 16, height: 16),
      blueprintId: 'masonry-test',
      blueprintRevision: BorderBlueprintRevision(
        revision: 3,
        definition: definition,
      ),
      feature: BorderFeature(
        id: 'masonry-feature',
        name: 'Muret',
        blueprintId: 'masonry-test',
        seed: BorderSignedInt64.fromInt(featureSeed),
        geometry: BorderStrokeGeometry(
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
                    GridPos(x: 6, y: 3),
                  ],
                  closed: false,
                ),
              ],
        ),
        paramsOverride: parameters,
        overrides: overrides,
        keepOutRegions: keepOutRegions,
        lineSide: lineSide,
      ),
      visualSnapshots: orderedSnapshots,
      resolverVersion: 1,
    );
  }

  late final BorderResolutionRequest request;
}

BorderGenerationParams masonryParameters({
  int irregularityPermille = 0,
  int detailDensityPermille = 0,
  int variationPermille = 1000,
  int maxOverlapPx = 2,
  int gapTolerancePx = 0,
  int depthRows = 1,
  bool allowAutoRotation = true,
}) =>
    BorderGenerationParams(
      irregularityPermille: irregularityPermille,
      detailDensityPermille: detailDensityPermille,
      variationPermille: variationPermille,
      maxOverlapPx: maxOverlapPx,
      gapTolerancePx: gapTolerancePx,
      depthRows: depthRows,
      allowAutoRotation: allowAutoRotation,
    );

BorderPublishedPrimitive masonryPrimitive({
  required String id,
  required String fingerprintCharacter,
  BorderPrimitiveRole role = BorderPrimitiveRole.structureLarge,
  int width = 12,
  int height = 10,
  int weight = 1,
  List<int> allowedQuarterTurns = const <int>[0, 1, 2, 3],
  bool allowFlipX = false,
  BorderPixelPos? anchorPx,
  BorderPixelRect? opaqueBounds,
  List<bool>? occupancy,
}) {
  final resolvedAnchor =
      anchorPx ?? BorderPixelPos(x: width ~/ 2, y: height ~/ 2);
  return BorderPublishedPrimitive(
    id: id,
    sourceElementId: 'element-$id',
    visualSnapshotId: masonrySnapshotId(fingerprintCharacter),
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
      occupancyMaskRle: encodeBorderRleMask(
        occupancy ?? List<bool>.filled(width * height, true),
      ),
    ),
  );
}

BorderVisualSnapshot masonrySnapshotFor(BorderPublishedPrimitive primitive) {
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

String masonrySnapshotId(String character) =>
    'border-snapshot-sha256:${character * 64}';
