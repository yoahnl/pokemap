import 'package:map_core/map_core.dart';

const GridSize twoTierStoneChainCanvasSize = GridSize(
  width: 32,
  height: 32,
);

const List<BorderPrimitiveOrientation> twoTierStoneChainCardinalOrientations =
    <BorderPrimitiveOrientation>[
  BorderPrimitiveOrientation.north,
  BorderPrimitiveOrientation.east,
  BorderPrimitiveOrientation.south,
  BorderPrimitiveOrientation.west,
];

/// Synthetic all-cardinal catalogue for the two-tier stone-chain RED tests.
///
/// Every role/orientation pair owns three connected rectangular masks. The
/// authored anchors deliberately expose a deep face beyond a shallower lip
/// when both placements target the same grid-edge station.
final class TwoTierStoneChainFixture {
  TwoTierStoneChainFixture({
    this.normal = BorderCardinalDirection.south,
    this.lineSide = BorderLineSide.primary,
    this.depthRows = 2,
    this.detailDensityPermille = 1000,
    this.irregularityPermille = 0,
    this.allowAutoRotation = false,
    this.featureSeed = 907,
    List<BorderPublishedPrimitive>? publishedPrimitives,
  }) {
    primitives = publishedPrimitives ?? twoTierStoneChainPublishedPrimitives();
    snapshots = twoTierStoneChainSnapshots(primitives);
    parameters = twoTierStoneChainParameters(
      depthRows: depthRows,
      detailDensityPermille: detailDensityPermille,
      irregularityPermille: irregularityPermille,
      allowAutoRotation: allowAutoRotation,
    );
    blueprintRevision = BorderBlueprintRevision(
      revision: 4,
      definition: twoTierStoneChainPublishedBlueprint(
        primitives: primitives,
        parameters: parameters,
      ),
    );
    request = BorderResolutionRequest(
      mapSize: const GridSize(width: 30, height: 30),
      tileSizePx: twoTierStoneChainCanvasSize,
      blueprintId: 'two-tier-stone-chain',
      blueprintRevision: blueprintRevision,
      feature: BorderFeature(
        id: 'two-tier-stone-chain-feature',
        name: 'Two-tier stone-chain fixture',
        blueprintId: 'two-tier-stone-chain',
        seed: BorderSignedInt64.fromInt(featureSeed),
        geometry: BorderStrokeGeometry(
          strokes: <BorderStroke>[
            twoTierStoneChainStraightStroke(normal: normal),
          ],
          alignment: BorderStrokeAlignment.gridEdges,
        ),
        lineSide: lineSide,
        paramsOverride: parameters,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      ),
      visualSnapshots: snapshots,
      resolverVersion: borderResolverVersion,
    );
  }

  final BorderCardinalDirection normal;
  final BorderLineSide lineSide;
  final int depthRows;
  final int detailDensityPermille;
  final int irregularityPermille;
  final bool allowAutoRotation;
  final int featureSeed;

  late final List<BorderPublishedPrimitive> primitives;
  late final List<BorderVisualSnapshot> snapshots;
  late final BorderGenerationParams parameters;
  late final BorderBlueprintRevision blueprintRevision;
  late final BorderResolutionRequest request;
}

BorderBlueprintPublishedDefinition twoTierStoneChainPublishedBlueprint({
  required List<BorderPublishedPrimitive> primitives,
  required BorderGenerationParams parameters,
}) =>
    BorderBlueprintPublishedDefinition(
      name: 'Two-tier stone chain',
      previewSeed: BorderSignedInt64.fromInt(41),
      template: BorderBlueprintTemplate.stoneChainLine,
      primitives: primitives,
      defaults: parameters,
      sortOrder: 0,
    );

BorderGenerationParams twoTierStoneChainParameters({
  required int depthRows,
  required int detailDensityPermille,
  int irregularityPermille = 0,
  required bool allowAutoRotation,
}) =>
    BorderGenerationParams(
      irregularityPermille: irregularityPermille,
      detailDensityPermille: detailDensityPermille,
      variationPermille: 1000,
      maxOverlapPx: 8,
      gapTolerancePx: 0,
      depthRows: depthRows,
      allowAutoRotation: allowAutoRotation,
    );

BorderStroke twoTierStoneChainStraightStroke({
  required BorderCardinalDirection normal,
}) {
  const start = 4;
  const end = 24;
  const center = 15;
  final points = switch (normal) {
    BorderCardinalDirection.north => <GridPos>[
        for (var x = end; x >= start; x -= 1) GridPos(x: x, y: center),
      ],
    BorderCardinalDirection.east => <GridPos>[
        for (var y = end; y >= start; y -= 1) GridPos(x: center, y: y),
      ],
    BorderCardinalDirection.south => <GridPos>[
        for (var x = start; x <= end; x += 1) GridPos(x: x, y: center),
      ],
    BorderCardinalDirection.west => <GridPos>[
        for (var y = start; y <= end; y += 1) GridPos(x: center, y: y),
      ],
  };
  return BorderStroke(
    id: buildBorderPreservedStrokeIdV1(
      authoredStrokeId: 'two-tier-straight',
      sourceEdgeOffset: 0,
      wrapLength: null,
      orderedPoints: points,
    ),
    points: points,
    closed: false,
  );
}

List<BorderPublishedPrimitive> twoTierStoneChainPublishedPrimitives({
  int? uniformTangentSpan,
  int faceTangentShiftPx = 0,
  int variantsPerOrientation = 3,
}) {
  const lipTangentSpans = <int>[12, 14, 16];
  const lipNormalSpans = <int>[10, 12, 14];
  const faceTangentSpans = <int>[10, 12, 14];
  // The production contract exposes 22 px of face below a 5 px neck hidden
  // behind the lip. Tangent spans still provide the three visual variants.
  const faceNormalSpans = <int>[27, 27, 27];
  final primitives = <BorderPublishedPrimitive>[];
  var snapshotOrdinal = 1;
  for (final orientation in twoTierStoneChainCardinalOrientations) {
    for (var variant = 0; variant < variantsPerOrientation; variant += 1) {
      final profileIndex = variant < 3 ? variant : 1;
      primitives.add(
        _twoTierPrimitive(
          snapshotOrdinal: snapshotOrdinal++,
          orientation: orientation,
          role: BorderPrimitiveRole.structureLarge,
          variant: variant,
          tangentSpan: uniformTangentSpan ?? lipTangentSpans[profileIndex],
          normalSpan: lipNormalSpans[profileIndex],
        ),
      );
    }
    for (var variant = 0; variant < variantsPerOrientation; variant += 1) {
      final profileIndex = variant < 3 ? variant : 1;
      primitives.add(
        _twoTierPrimitive(
          snapshotOrdinal: snapshotOrdinal++,
          orientation: orientation,
          role: BorderPrimitiveRole.structureMedium,
          variant: variant,
          tangentSpan: uniformTangentSpan ?? faceTangentSpans[profileIndex],
          normalSpan: faceNormalSpans[profileIndex],
          tangentShiftPx: faceTangentShiftPx,
        ),
      );
    }
  }
  return List<BorderPublishedPrimitive>.unmodifiable(primitives);
}

List<BorderVisualSnapshot> twoTierStoneChainSnapshots(
  List<BorderPublishedPrimitive> primitives,
) =>
    List<BorderVisualSnapshot>.unmodifiable(
      primitives.map(twoTierStoneChainSnapshotFor),
    );

BorderVisualSnapshot twoTierStoneChainSnapshotFor(
  BorderPublishedPrimitive primitive,
) {
  final fingerprint = primitive.visualSnapshotId.substring(
    'border-snapshot-sha256:'.length,
  );
  return BorderVisualSnapshot(
    id: primitive.visualSnapshotId,
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/two-tier-$fingerprint.png',
        sourceRectPx: BorderPixelRect(
          x: 0,
          y: 0,
          width: twoTierStoneChainCanvasSize.width,
          height: twoTierStoneChainCanvasSize.height,
        ),
        durationMs: 100,
      ),
    ],
  );
}

BorderPrimitiveOrientation twoTierOrientationForNormal(
  BorderCardinalDirection normal,
) =>
    switch (normal) {
      BorderCardinalDirection.north => BorderPrimitiveOrientation.north,
      BorderCardinalDirection.east => BorderPrimitiveOrientation.east,
      BorderCardinalDirection.south => BorderPrimitiveOrientation.south,
      BorderCardinalDirection.west => BorderPrimitiveOrientation.west,
    };

BorderCardinalDirection oppositeTwoTierNormal(
  BorderCardinalDirection normal,
) =>
    switch (normal) {
      BorderCardinalDirection.north => BorderCardinalDirection.south,
      BorderCardinalDirection.east => BorderCardinalDirection.west,
      BorderCardinalDirection.south => BorderCardinalDirection.north,
      BorderCardinalDirection.west => BorderCardinalDirection.east,
    };

BorderPublishedPrimitive _twoTierPrimitive({
  required int snapshotOrdinal,
  required BorderPrimitiveOrientation orientation,
  required BorderPrimitiveRole role,
  required int variant,
  required int tangentSpan,
  required int normalSpan,
  int tangentShiftPx = 0,
}) {
  final anchor = _twoTierAnchor(
    orientation: orientation,
    role: role,
    tangentShiftPx: tangentShiftPx,
  );
  final opaqueBounds = _twoTierOpaqueBounds(
    orientation: orientation,
    tangentSpan: tangentSpan,
    normalSpan: normalSpan,
  );
  final id = 'two-tier-${role.name}-${orientation.name}-${variant + 1}';
  final fingerprint = snapshotOrdinal.toRadixString(16).padLeft(64, '0');
  final metrics = BorderPrimitiveAssetMetrics(
    assetFingerprint: 'asset-$id',
    pixelSize: twoTierStoneChainCanvasSize,
    opaqueBounds: opaqueBounds,
    defaultAnchorPx: anchor,
    occupancyMaskRle: encodeBorderRleMask(
      _connectedRectangleMask(opaqueBounds),
    ),
  );
  return BorderPublishedPrimitive(
    id: id,
    sourceElementId: 'element-$id',
    visualSnapshotId: 'border-snapshot-sha256:$fingerprint',
    role: role,
    authoredOrientation: orientation,
    weight: 1,
    anchorPx: anchor,
    transforms: BorderTransformPolicy(
      allowFlipX: false,
      allowedQuarterTurns: const <int>[0, 1, 2, 3],
    ),
    publishedMetrics: metrics,
  );
}

BorderPixelPos _twoTierAnchor({
  required BorderPrimitiveOrientation orientation,
  required BorderPrimitiveRole role,
  required int tangentShiftPx,
}) {
  final face = role == BorderPrimitiveRole.structureMedium;
  final shift = face ? tangentShiftPx : 0;
  return switch (orientation) {
    BorderPrimitiveOrientation.north =>
      BorderPixelPos(x: 16 + shift, y: face ? 31 : 9),
    BorderPrimitiveOrientation.east =>
      BorderPixelPos(x: face ? 0 : 22, y: 16 + shift),
    BorderPrimitiveOrientation.south =>
      BorderPixelPos(x: 16 - shift, y: face ? 0 : 22),
    BorderPrimitiveOrientation.west =>
      BorderPixelPos(x: face ? 31 : 9, y: 16 - shift),
    BorderPrimitiveOrientation.legacyAxis => throw ArgumentError.value(
        orientation,
        'orientation',
        'two-tier primitives require an explicit cardinal orientation',
      ),
  };
}

BorderPixelRect _twoTierOpaqueBounds({
  required BorderPrimitiveOrientation orientation,
  required int tangentSpan,
  required int normalSpan,
}) {
  const canvas = 32;
  final tangentStart = (canvas - tangentSpan) ~/ 2;
  return switch (orientation) {
    BorderPrimitiveOrientation.north => BorderPixelRect(
        x: tangentStart,
        y: 0,
        width: tangentSpan,
        height: normalSpan,
      ),
    BorderPrimitiveOrientation.east => BorderPixelRect(
        x: canvas - normalSpan,
        y: tangentStart,
        width: normalSpan,
        height: tangentSpan,
      ),
    BorderPrimitiveOrientation.south => BorderPixelRect(
        x: tangentStart,
        y: canvas - normalSpan,
        width: tangentSpan,
        height: normalSpan,
      ),
    BorderPrimitiveOrientation.west => BorderPixelRect(
        x: 0,
        y: tangentStart,
        width: normalSpan,
        height: tangentSpan,
      ),
    BorderPrimitiveOrientation.legacyAxis => throw ArgumentError.value(
        orientation,
        'orientation',
        'two-tier primitives require an explicit cardinal orientation',
      ),
  };
}

List<bool> _connectedRectangleMask(BorderPixelRect opaqueBounds) {
  final mask = List<bool>.filled(
    twoTierStoneChainCanvasSize.width * twoTierStoneChainCanvasSize.height,
    false,
  );
  for (var y = opaqueBounds.y; y < opaqueBounds.bottom; y += 1) {
    for (var x = opaqueBounds.x; x < opaqueBounds.right; x += 1) {
      mask[y * twoTierStoneChainCanvasSize.width + x] = true;
    }
  }
  return mask;
}
