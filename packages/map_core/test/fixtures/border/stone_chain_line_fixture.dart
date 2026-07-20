import 'package:map_core/map_core.dart';

final class StoneChainLineFixture {
  StoneChainLineFixture({
    List<BorderStroke>? strokes,
    List<BorderPublishedPrimitive>? primitives,
    BorderGenerationParams? parameters,
    bool reverseInputs = false,
    List<BorderSlotOverride> overrides = const <BorderSlotOverride>[],
    List<BorderKeepOutRegion> keepOutRegions = const <BorderKeepOutRegion>[],
    BorderPublishedGround? ground,
    BorderFeatureGeometry? geometry,
    GridSize mapSize = const GridSize(width: 12, height: 12),
    BorderLineSide lineSide = BorderLineSide.primary,
    int featureSeed = 71,
    String blueprintId = 'stone-chain-test',
    int blueprintRevision = 1,
    int previewSeed = 29,
    String featureId = 'stone-chain-feature',
  }) {
    final sourcePrimitives = primitives ?? stoneChainPrimitives();
    final sourceSnapshots = <BorderVisualSnapshot>[
      for (final primitive in sourcePrimitives)
        stoneChainSnapshotFor(primitive),
    ];
    final orderedPrimitives = reverseInputs
        ? sourcePrimitives.reversed.toList(growable: false)
        : sourcePrimitives;
    final orderedSnapshots = reverseInputs
        ? sourceSnapshots.reversed.toList(growable: false)
        : sourceSnapshots;
    final definition = BorderBlueprintPublishedDefinition(
      name: 'Falaises Selbrume — pierres',
      previewSeed: BorderSignedInt64.fromInt(previewSeed),
      template: BorderBlueprintTemplate.stoneChainLine,
      primitives: orderedPrimitives,
      defaults: parameters ?? stoneChainParameters(),
      ground: ground,
      sortOrder: 0,
    );
    request = BorderResolutionRequest(
      mapSize: mapSize,
      tileSizePx: const GridSize(width: 32, height: 32),
      blueprintId: blueprintId,
      blueprintRevision: BorderBlueprintRevision(
        revision: blueprintRevision,
        definition: definition,
      ),
      feature: BorderFeature(
        id: featureId,
        name: 'Falaise',
        blueprintId: blueprintId,
        seed: BorderSignedInt64.fromInt(featureSeed),
        geometry: geometry ??
            BorderStrokeGeometry(
              strokes: strokes ?? <BorderStroke>[stoneChainLongStroke()],
              alignment: BorderStrokeAlignment.gridEdges,
            ),
        lineSide: lineSide,
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

BorderStroke stoneChainLongStroke() => BorderStroke(
      id: 'main',
      points: const <GridPos>[
        GridPos(x: 1, y: 4),
        GridPos(x: 2, y: 4),
        GridPos(x: 3, y: 4),
        GridPos(x: 4, y: 4),
        GridPos(x: 5, y: 4),
        GridPos(x: 6, y: 4),
        GridPos(x: 7, y: 4),
        GridPos(x: 8, y: 4),
        GridPos(x: 9, y: 4),
        GridPos(x: 10, y: 4),
      ],
      closed: false,
    );

/// The two authored grid-edge strokes used by Bourg de Selbrume's coast.
///
/// This stays in the test fixture so resolver regressions can exercise the
/// production-scale turn sequence without coupling `map_core` tests to an
/// editor project file.
List<BorderStroke> stoneChainSelbrumeCoastStrokes() => <BorderStroke>[
      BorderStroke(
        id: 'stroke',
        points: const <GridPos>[
          GridPos(x: 6, y: 12),
          GridPos(x: 6, y: 13),
          GridPos(x: 6, y: 14),
          GridPos(x: 7, y: 14),
          GridPos(x: 7, y: 15),
          GridPos(x: 8, y: 15),
          GridPos(x: 8, y: 16),
          GridPos(x: 9, y: 16),
          GridPos(x: 9, y: 17),
          GridPos(x: 9, y: 18),
          GridPos(x: 9, y: 19),
          GridPos(x: 9, y: 20),
          GridPos(x: 9, y: 21),
          GridPos(x: 8, y: 21),
          GridPos(x: 8, y: 22),
          GridPos(x: 7, y: 22),
          GridPos(x: 7, y: 23),
          GridPos(x: 7, y: 24),
          GridPos(x: 7, y: 25),
          GridPos(x: 7, y: 26),
          GridPos(x: 7, y: 27),
          GridPos(x: 8, y: 27),
          GridPos(x: 8, y: 28),
          GridPos(x: 8, y: 29),
          GridPos(x: 8, y: 30),
          GridPos(x: 9, y: 30),
          GridPos(x: 9, y: 31),
          GridPos(x: 10, y: 31),
          GridPos(x: 10, y: 32),
          GridPos(x: 10, y: 33),
          GridPos(x: 11, y: 33),
          GridPos(x: 11, y: 34),
          GridPos(x: 11, y: 35),
          GridPos(x: 11, y: 36),
          GridPos(x: 11, y: 37),
          GridPos(x: 12, y: 37),
          GridPos(x: 12, y: 38),
          GridPos(x: 13, y: 38),
          GridPos(x: 13, y: 39),
          GridPos(x: 13, y: 40),
          GridPos(x: 14, y: 40),
          GridPos(x: 14, y: 41),
          GridPos(x: 14, y: 42),
          GridPos(x: 15, y: 42),
          GridPos(x: 16, y: 42),
          GridPos(x: 16, y: 43),
          GridPos(x: 17, y: 43),
          GridPos(x: 18, y: 43),
          GridPos(x: 19, y: 43),
          GridPos(x: 19, y: 44),
          GridPos(x: 20, y: 44),
          GridPos(x: 21, y: 44),
          GridPos(x: 22, y: 44),
        ],
        closed: false,
      ),
      BorderStroke(
        id: 'stroke_2',
        points: const <GridPos>[
          GridPos(x: 32, y: 44),
          GridPos(x: 32, y: 43),
          GridPos(x: 33, y: 43),
          GridPos(x: 34, y: 43),
          GridPos(x: 34, y: 42),
          GridPos(x: 35, y: 42),
          GridPos(x: 36, y: 42),
          GridPos(x: 37, y: 42),
          GridPos(x: 38, y: 42),
          GridPos(x: 39, y: 42),
          GridPos(x: 40, y: 42),
          GridPos(x: 40, y: 43),
          GridPos(x: 41, y: 43),
          GridPos(x: 42, y: 43),
          GridPos(x: 42, y: 44),
        ],
        closed: false,
      ),
    ];

BorderStroke stoneChainRectangularLoop({
  String id = 'loop',
  int left = 2,
  int top = 2,
  int right = 8,
  int bottom = 8,
}) =>
    BorderStroke(
      id: id,
      points: <GridPos>[
        for (var x = left; x <= right; x += 1) GridPos(x: x, y: top),
        for (var y = top + 1; y <= bottom; y += 1) GridPos(x: right, y: y),
        for (var x = right - 1; x >= left; x -= 1) GridPos(x: x, y: bottom),
        for (var y = bottom - 1; y > top; y -= 1) GridPos(x: left, y: y),
      ],
      closed: true,
    );

String stoneChainLoopSeamCornerSlotKey(BorderStroke stroke) =>
    buildBorderStoneChainNodeSlotKey(
      featureId: 'stone-chain-feature',
      strokeId: stroke.id,
      vertex: stroke.points.first,
      passIndex: 0,
      role: BorderPrimitiveRole.lineCorner,
      rank: 0,
    );

BorderStroke stoneChainHorizontalStroke({
  required String id,
  required int startX,
  required int edgeCount,
  required int y,
}) =>
    BorderStroke(
      id: id,
      points: <GridPos>[
        for (var offset = 0; offset <= edgeCount; offset += 1)
          GridPos(x: startX + offset, y: y),
      ],
      closed: false,
    );

BorderGenerationParams stoneChainParameters({
  int irregularityPermille = 0,
  int detailDensityPermille = 250,
  int variationPermille = 1000,
  int maxOverlapPx = 3,
  int gapTolerancePx = 2,
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

List<BorderPublishedPrimitive> stoneChainPrimitives() =>
    <BorderPublishedPrimitive>[
      stoneChainPrimitive(id: 'large-a', character: '1', width: 15, height: 18),
      stoneChainPrimitive(id: 'large-b', character: '2', width: 17, height: 20),
      stoneChainPrimitive(id: 'large-c', character: '3', width: 13, height: 17),
      stoneChainPrimitive(
        id: 'medium-a',
        character: '4',
        role: BorderPrimitiveRole.structureMedium,
        width: 10,
        height: 13,
      ),
      stoneChainPrimitive(
        id: 'medium-b',
        character: '5',
        role: BorderPrimitiveRole.structureMedium,
        width: 9,
        height: 12,
      ),
      stoneChainPrimitive(
        id: 'filler-a',
        character: '6',
        role: BorderPrimitiveRole.filler,
        width: 7,
        height: 8,
      ),
      stoneChainPrimitive(
        id: 'corner-a',
        character: '7',
        role: BorderPrimitiveRole.lineCorner,
        width: 16,
        height: 18,
      ),
      stoneChainPrimitive(
        id: 'cap-a',
        character: '8',
        role: BorderPrimitiveRole.lineCap,
        width: 10,
        height: 13,
      ),
    ];

/// Published geometry of the 16 small-stone primitives used by Selbrume.
///
/// Pixel content is intentionally abstracted by the fixture; the resolver's
/// continuity and collision contracts depend on these published opaque bounds
/// and the bottom-centred anchor, not on PNG bytes.
List<BorderPublishedPrimitive> stoneChainSelbrumePrimitives() =>
    <BorderPublishedPrimitive>[
      _selbrumeStone(
        id: 'primary-01',
        character: '0',
        role: BorderPrimitiveRole.structureLarge,
        opaqueBounds: BorderPixelRect(x: 7, y: 16, width: 19, height: 14),
      ),
      _selbrumeStone(
        id: 'primary-02',
        character: '1',
        role: BorderPrimitiveRole.structureLarge,
        opaqueBounds: BorderPixelRect(x: 8, y: 13, width: 18, height: 17),
      ),
      _selbrumeStone(
        id: 'primary-03',
        character: '2',
        role: BorderPrimitiveRole.structureLarge,
        opaqueBounds: BorderPixelRect(x: 8, y: 13, width: 18, height: 17),
      ),
      _selbrumeStone(
        id: 'primary-04',
        character: '3',
        role: BorderPrimitiveRole.structureLarge,
        opaqueBounds: BorderPixelRect(x: 7, y: 16, width: 19, height: 14),
      ),
      _selbrumeStone(
        id: 'primary-05',
        character: '4',
        role: BorderPrimitiveRole.structureLarge,
        opaqueBounds: BorderPixelRect(x: 8, y: 13, width: 17, height: 17),
      ),
      _selbrumeStone(
        id: 'secondary-01',
        character: '5',
        role: BorderPrimitiveRole.structureMedium,
        opaqueBounds: BorderPixelRect(x: 10, y: 16, width: 14, height: 14),
      ),
      _selbrumeStone(
        id: 'secondary-02',
        character: '6',
        role: BorderPrimitiveRole.structureMedium,
        opaqueBounds: BorderPixelRect(x: 10, y: 16, width: 14, height: 14),
      ),
      _selbrumeStone(
        id: 'secondary-03',
        character: '7',
        role: BorderPrimitiveRole.structureMedium,
        opaqueBounds: BorderPixelRect(x: 10, y: 17, width: 14, height: 13),
      ),
      _selbrumeStone(
        id: 'secondary-04',
        character: '8',
        role: BorderPrimitiveRole.structureMedium,
        opaqueBounds: BorderPixelRect(x: 10, y: 20, width: 14, height: 10),
      ),
      _selbrumeStone(
        id: 'filler-01',
        character: '9',
        role: BorderPrimitiveRole.filler,
        opaqueBounds: BorderPixelRect(x: 14, y: 24, width: 6, height: 6),
      ),
      _selbrumeStone(
        id: 'filler-02',
        character: 'a',
        role: BorderPrimitiveRole.filler,
        opaqueBounds: BorderPixelRect(x: 13, y: 24, width: 7, height: 6),
      ),
      _selbrumeStone(
        id: 'filler-03',
        character: 'b',
        role: BorderPrimitiveRole.filler,
        opaqueBounds: BorderPixelRect(x: 14, y: 25, width: 6, height: 5),
      ),
      _selbrumeStone(
        id: 'corner-01',
        character: 'c',
        role: BorderPrimitiveRole.lineCorner,
        opaqueBounds: BorderPixelRect(x: 8, y: 15, width: 17, height: 15),
      ),
      _selbrumeStone(
        id: 'corner-02',
        character: 'd',
        role: BorderPrimitiveRole.lineCorner,
        opaqueBounds: BorderPixelRect(x: 8, y: 16, width: 17, height: 14),
      ),
      _selbrumeStone(
        id: 'cap-01',
        character: 'e',
        role: BorderPrimitiveRole.lineCap,
        opaqueBounds: BorderPixelRect(x: 13, y: 22, width: 8, height: 8),
      ),
      _selbrumeStone(
        id: 'cap-02',
        character: 'f',
        role: BorderPrimitiveRole.lineCap,
        opaqueBounds: BorderPixelRect(x: 13, y: 24, width: 7, height: 6),
      ),
    ];

BorderPublishedPrimitive _selbrumeStone({
  required String id,
  required String character,
  required BorderPrimitiveRole role,
  required BorderPixelRect opaqueBounds,
}) =>
    stoneChainPrimitive(
      id: id,
      character: character,
      role: role,
      width: 32,
      height: 32,
      opaqueBounds: opaqueBounds,
      anchorPx: const BorderPixelPos(x: 16, y: 29),
    );

BorderPublishedPrimitive stoneChainPrimitive({
  required String id,
  required String character,
  BorderPrimitiveRole role = BorderPrimitiveRole.structureLarge,
  required int width,
  required int height,
  int weight = 1,
  List<int> allowedQuarterTurns = const <int>[0, 1, 2, 3],
  BorderPixelRect? opaqueBounds,
  BorderPixelPos? anchorPx,
}) {
  final anchor = anchorPx ?? BorderPixelPos(x: width ~/ 2, y: height ~/ 2);
  final resolvedOpaqueBounds = opaqueBounds ??
      BorderPixelRect(
        x: 0,
        y: 0,
        width: width,
        height: height,
      );
  return BorderPublishedPrimitive(
    id: id,
    sourceElementId: 'element-$id',
    visualSnapshotId: stoneChainSnapshotId(character),
    role: role,
    weight: weight,
    anchorPx: anchor,
    transforms: BorderTransformPolicy(
      allowFlipX: false,
      allowedQuarterTurns: allowedQuarterTurns,
    ),
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset-$id',
      pixelSize: GridSize(width: width, height: height),
      opaqueBounds: resolvedOpaqueBounds,
      defaultAnchorPx: anchor,
      occupancyMaskRle: encodeBorderRleMask(
        List<bool>.filled(width * height, true),
      ),
    ),
  );
}

BorderVisualSnapshot stoneChainSnapshotFor(BorderPublishedPrimitive primitive) {
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

String stoneChainSnapshotId(String character) =>
    'border-snapshot-sha256:${character * 64}';
