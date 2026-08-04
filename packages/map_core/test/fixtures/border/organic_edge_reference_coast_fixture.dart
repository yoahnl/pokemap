import 'package:map_core/map_core.dart';

const String organicEdgeReferenceBlueprintId = 'reference-coast';
const GridSize organicEdgeReferenceTileSizePx = GridSize(
  width: 16,
  height: 16,
);

final class OrganicEdgeReferenceCoastFixture {
  OrganicEdgeReferenceCoastFixture({
    bool sparseStructure = false,
    bool reverseInputs = false,
  }) {
    final sourcePrimitives = <BorderPublishedPrimitive>[
      _primitive('rock-a', 'a', sparse: sparseStructure),
      _primitive('rock-b', 'b', sparse: sparseStructure),
      _primitive('rock-c', 'c', sparse: sparseStructure),
    ];
    final sourceSnapshots = <BorderVisualSnapshot>[
      for (final primitive in sourcePrimitives)
        _snapshotForPrimitive(primitive),
      _snapshot(_groundSnapshotId, width: 16, height: 16),
    ];
    primitives = List<BorderPublishedPrimitive>.unmodifiable(
      reverseInputs ? sourcePrimitives.reversed : sourcePrimitives,
    );
    snapshots = List<BorderVisualSnapshot>.unmodifiable(
      reverseInputs ? sourceSnapshots.reversed : sourceSnapshots,
    );
    definition = BorderBlueprintPublishedDefinition(
      name: 'Côte organique de référence',
      previewSeed: BorderSignedInt64.fromInt(271828),
      template: BorderBlueprintTemplate.organicEdge,
      primitives: primitives,
      defaults: BorderGenerationParams(
        irregularityPermille: 350,
        detailDensityPermille: 0,
        variationPermille: 1000,
        maxOverlapPx: 0,
        gapTolerancePx: 0,
        depthRows: 1,
      ),
      ground: BorderPublishedGround(
        sourceSmartTilePresetId: 'reference-grass',
        edgeBandCells: 2,
        visualSnapshotIdsByRole: <BorderGroundVariantRole, String>{
          for (final role in standardBorderGroundVariantRoleOrder)
            role: _groundSnapshotId,
        },
      ),
      sortOrder: 0,
    );
    revision = BorderBlueprintRevision(revision: 7, definition: definition);
  }

  late final List<BorderPublishedPrimitive> primitives;
  late final List<BorderVisualSnapshot> snapshots;
  late final BorderBlueprintPublishedDefinition definition;
  late final BorderBlueprintRevision revision;

  BorderRegionGeometry get referenceCoastGeometry {
    const mainLandStartByRow = <int>[
      8,
      7,
      7,
      8,
      9,
      8,
      10,
      11,
      9,
      8,
      7,
      8,
      9,
      7,
      6,
      7,
      8,
      9,
    ];
    const island = <(int, int)>{
      (2, 4),
      (3, 4),
      (2, 5),
      (3, 5),
      (2, 6),
    };
    return BorderRegionGeometry(
      width: 24,
      height: 18,
      cells: <bool>[
        for (var y = 0; y < 18; y += 1)
          for (var x = 0; x < 24; x += 1)
            x >= mainLandStartByRow[y] || island.contains((x, y)),
      ],
    );
  }

  BorderResolutionRequest referenceCoastRequest({int resolverVersion = 1}) =>
      BorderResolutionRequest(
        mapSize: const GridSize(width: 24, height: 18),
        tileSizePx: organicEdgeReferenceTileSizePx,
        blueprintId: organicEdgeReferenceBlueprintId,
        blueprintRevision: revision,
        feature: BorderFeature(
          id: 'border-reference-coast',
          name: 'Côte de référence',
          blueprintId: organicEdgeReferenceBlueprintId,
          seed: definition.previewSeed,
          geometry: referenceCoastGeometry,
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
        ),
        visualSnapshots: snapshots,
        resolverVersion: resolverVersion,
      );
}

BorderPublishedPrimitive _primitive(
  String id,
  String fingerprintCharacter, {
  required bool sparse,
}) {
  final occupancy = List<bool>.filled(16 * 16, !sparse);
  if (sparse) {
    occupancy[8 * 16 + 8] = true;
  }
  return BorderPublishedPrimitive(
    id: id,
    sourceElementId: 'element-$id',
    visualSnapshotId: _snapshotId(fingerprintCharacter),
    role: BorderPrimitiveRole.structureLarge,
    weight: 1,
    anchorPx: const BorderPixelPos(x: 8, y: 8),
    transforms: BorderTransformPolicy(
      allowFlipX: true,
      allowedQuarterTurns: const <int>[0, 1, 2, 3],
    ),
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset-$id',
      pixelSize: const GridSize(width: 16, height: 16),
      opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
      defaultAnchorPx: const BorderPixelPos(x: 8, y: 8),
      occupancyMaskRle: encodeBorderRleMask(occupancy),
    ),
  );
}

BorderVisualSnapshot _snapshotForPrimitive(BorderPublishedPrimitive primitive) {
  final size = primitive.publishedMetrics.pixelSize;
  return _snapshot(
    primitive.visualSnapshotId,
    width: size.width,
    height: size.height,
  );
}

BorderVisualSnapshot _snapshot(
  String id, {
  required int width,
  required int height,
}) {
  final fingerprint = id.substring('border-snapshot-sha256:'.length);
  return BorderVisualSnapshot(
    id: id,
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath: 'assets/borders/snapshots/$fingerprint.png',
        sourceRectPx: BorderPixelRect(
          x: 0,
          y: 0,
          width: width,
          height: height,
        ),
        durationMs: 100,
      ),
    ],
  );
}

String _snapshotId(String character) =>
    'border-snapshot-sha256:${character * 64}';

final String _groundSnapshotId = _snapshotId('d');
