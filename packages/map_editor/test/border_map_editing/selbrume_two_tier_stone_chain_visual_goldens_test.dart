import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../fixtures/border/two_tier_stone_chain_visual_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'published Selbrume blueprint-4 passes structural gates before ten goldens',
    () async {
      final fixture = await TwoTierStoneChainVisualFixture.load();
      addTearDown(fixture.dispose);

      expect(fixture.blueprintId, 'border-blueprint-4');
      expect(fixture.publishedRevision.revision, greaterThanOrEqualTo(1));
      expect(
        fixture.publishedRevision.definition.template,
        BorderBlueprintTemplate.stoneChainLine,
      );
      expect(fixture.publishedRevision.definition.defaults.depthRows, 2);
      expect(fixture.publishedRevision.definition.defaults.gapTolerancePx, 0);
      expect(fixture.publishedRevision.definition.defaults.maxOverlapPx, 8);
      expect(fixture.publishedRevision.definition.primitives, hasLength(24));
      expect(fixture.publishedSnapshotRelativePaths, hasLength(24));
      expect(fixture.publishedSnapshotRelativePaths.toSet(), hasLength(24));
      expect(
        fixture.cases.map((item) => item.id),
        orderedEquals(const <String>[
          'horizontal_primary',
          'vertical_primary',
          'l_convex_primary',
          'l_concave_inverted',
          's_primary',
          's_inverted',
          'closed_loop',
          'one_cell_zigzag',
          'rotation_off',
          'rotation_on',
        ]),
      );
      _expectPublishedPrimitiveContract(fixture);
      _expectCanonicalCoreMetrics(fixture.resolveCanonicalGallery());

      final resolutions = <TwoTierStoneChainVisualCaseResolution>[
        for (final visualCase in fixture.cases) fixture.resolve(visualCase),
      ];

      // Every structural and metric gate deliberately precedes every golden
      // comparison. --update-goldens cannot bless a gap, detached face, shallow
      // face, invalid corner recipe, or broken transform identity.
      for (final resolution in resolutions) {
        _expectMeasurableStructure(fixture, resolution);
      }
      _expectSameSlots(
        resolutions,
        firstId: 'l_convex_primary',
        secondId: 'l_concave_inverted',
      );
      _expectSameSlots(
        resolutions,
        firstId: 's_primary',
        secondId: 's_inverted',
      );
      _expectSameSlots(
        resolutions,
        firstId: 'rotation_off',
        secondId: 'rotation_on',
      );
      expect(await fixture.projectBytesAreUnchanged(), isTrue);

      for (final resolution in resolutions) {
        final image = await fixture.render(resolution);
        try {
          await expectLater(
            image,
            matchesGoldenFile(resolution.visualCase.goldenFile),
          );
        } finally {
          image.dispose();
        }
      }

      expect(await fixture.projectBytesAreUnchanged(), isTrue);
    },
  );
}

void _expectPublishedPrimitiveContract(
  TwoTierStoneChainVisualFixture fixture,
) {
  final primitives = fixture.publishedRevision.definition.primitives;
  final roles = <BorderPrimitiveRole, List<BorderPublishedPrimitive>>{};
  for (final primitive in primitives) {
    (roles[primitive.role] ??= <BorderPublishedPrimitive>[]).add(primitive);
    expect(primitive.weight, 1000, reason: primitive.id);
    expect(primitive.transforms.allowFlipX, isFalse, reason: primitive.id);
    expect(
      primitive.transforms.allowedQuarterTurns,
      const <int>[0, 1, 2, 3],
      reason: primitive.id,
    );
    expect(
      primitive.authoredOrientation,
      isNot(BorderPrimitiveOrientation.legacyAxis),
      reason: primitive.id,
    );
  }
  expect(
    roles.keys,
    <BorderPrimitiveRole>{
      BorderPrimitiveRole.structureLarge,
      BorderPrimitiveRole.structureMedium,
    },
  );
  expect(roles[BorderPrimitiveRole.structureLarge], hasLength(12));
  expect(roles[BorderPrimitiveRole.structureMedium], hasLength(12));
  for (final role in roles.keys) {
    for (final orientation in const <BorderPrimitiveOrientation>[
      BorderPrimitiveOrientation.north,
      BorderPrimitiveOrientation.east,
      BorderPrimitiveOrientation.south,
      BorderPrimitiveOrientation.west,
    ]) {
      expect(
        roles[role]!.where(
          (primitive) => primitive.authoredOrientation == orientation,
        ),
        hasLength(3),
        reason: '${role.name}/${orientation.name}',
      );
    }
  }
}

void _expectCanonicalCoreMetrics(BorderCanonicalGalleryResult gallery) {
  expect(gallery.allCasesResolved, isTrue);
  expect(
    gallery.cases,
    hasLength(
      borderCanonicalGalleryCasesForTemplate(
        BorderBlueprintTemplate.stoneChainLine,
      ).length,
    ),
  );
  for (final caseResult in gallery.cases) {
    final sample = caseResult.publicationSample;
    expect(
      sample.coverageChecks.map((check) => check.component).toSet(),
      <BorderCanonicalCoverageComponent>{
        BorderCanonicalCoverageComponent.lip,
        BorderCanonicalCoverageComponent.face,
      },
      reason: caseResult.galleryCase.name,
    );
    for (final check in sample.coverageChecks) {
      expect(
        check.longestContiguousGapPx,
        0,
        reason: '${caseResult.galleryCase.name}/${check.component.name}',
      );
      expect(
        check.maximumPairwiseOverlapPx,
        lessThanOrEqualTo(8),
        reason: '${caseResult.galleryCase.name}/${check.component.name}',
      );
    }
    for (final side in <(String, BorderPublicationStoneChainEvidence?)>[
      ('primary', sample.primaryStoneChainEvidence),
      ('inverted', sample.invertedStoneChainEvidence),
    ]) {
      final evidence = side.$2;
      final reason = '${caseResult.galleryCase.name}/${side.$1}';
      expect(evidence, isNotNull, reason: reason);
      expect(evidence!.lipPlacementCount, greaterThan(0), reason: reason);
      expect(evidence.facePlacementCount, greaterThan(0), reason: reason);
      expect(
        evidence.minimumCrossRowInterlockPixels,
        greaterThanOrEqualTo(8),
        reason: reason,
      );
      expect(
        evidence.minimumVisibleFaceDepthPx,
        greaterThanOrEqualTo(12),
        reason: reason,
      );
      expect(
        evidence.medianVisibleFaceDepthPx,
        inInclusiveRange(22, 27),
        reason: reason,
      );
      expect(
        evidence.alignedJointRatioPermille,
        lessThanOrEqualTo(250),
        reason: reason,
      );
      expect(evidence.lipConnectedComponentCount, 1, reason: reason);
      expect(evidence.faceConnectedComponentCount, 1, reason: reason);
      expect(evidence.combinedConnectedComponentCount, 1, reason: reason);
    }
  }
}

void _expectMeasurableStructure(
  TwoTierStoneChainVisualFixture fixture,
  TwoTierStoneChainVisualCaseResolution resolution,
) {
  final visualCase = resolution.visualCase;
  final result = resolution.evidence.result;
  final reason = '${visualCase.id}: ${resolution.diagnostics}';
  expect(result.canApply, isTrue, reason: reason);
  expect(result.materialization, isNotNull, reason: reason);
  expect(resolution.placements, isNotEmpty, reason: reason);
  expect(
    resolution.placements.map((item) => item.slotKey).toSet(),
    hasLength(resolution.placements.length),
    reason: '${visualCase.id}: slot keys must be unique.',
  );
  expect(
    resolution.placements.map((item) => item.id).toSet(),
    hasLength(resolution.placements.length),
    reason: '${visualCase.id}: placement ids must be unique.',
  );
  expect(resolution.lipPlacements, isNotEmpty, reason: reason);
  expect(resolution.facePlacements, isNotEmpty, reason: reason);

  final inspection = fixture.inspect(resolution);
  expect(inspection['ok'], isTrue, reason: reason);
  expect(
    inspection['lipCount'],
    resolution.lipPlacements.length,
    reason: '$reason raw lip count',
  );
  expect(
    inspection['faceCount'],
    resolution.facePlacements.length,
    reason: '$reason raw face count',
  );
  final completeTurnFacePairCount =
      inspection['completeTurnFacePairCount']! as int;
  final logicalFaceCount = inspection['logicalFaceCount']! as int;
  expect(
    completeTurnFacePairCount,
    inInclusiveRange(0, resolution.facePlacements.length ~/ 2),
    reason: '$reason complete turn face pairs',
  );
  expect(
    logicalFaceCount,
    resolution.facePlacements.length - completeTurnFacePairCount,
    reason: '$reason logical face count',
  );
  expect(
    inspection['topologyNormalizedFaceLipRatioPermille'],
    logicalFaceCount * 1000 ~/ resolution.lipPlacements.length,
    reason: '$reason normalized face/lip count ratio',
  );
  expect(
    inspection['topologyNormalizedFaceLipRatioPermille'],
    inInclusiveRange(800, 1150),
    reason: '$reason normalized face/lip count ratio',
  );
  expect(inspection['lipMaximumGapPx'], 0, reason: '$reason lip gap');
  expect(inspection['faceMaximumGapPx'], 0, reason: '$reason face gap');
  expect(
    inspection['minimumCrossRowInterlockPixels'],
    greaterThanOrEqualTo(8),
    reason: '$reason detached face',
  );
  expect(
    inspection['medianVisibleFaceDepthPx'],
    inInclusiveRange(22, 27),
    reason: '$reason visible face depth',
  );
  expect(
    inspection['alignedJointRatioPermille'],
    lessThanOrEqualTo(250),
    reason: '$reason aligned joints',
  );

  expect(
    _opaqueComponentCount(resolution, resolution.lipPlacements),
    1,
    reason: '${visualCase.id}: lip row must be one opaque component.',
  );
  expect(
    _opaqueComponentCount(resolution, resolution.facePlacements),
    1,
    reason: '${visualCase.id}: face row must be one opaque component.',
  );
  expect(
    _opaqueComponentCount(
      resolution,
      <BorderResolvedPlacement>[
        ...resolution.lipPlacements,
        ...resolution.facePlacements,
      ],
    ),
    1,
    reason: '${visualCase.id}: both rows must interlock into one component.',
  );

  final faceIndices = <int>[
    for (var index = 0; index < resolution.placements.length; index += 1)
      if (resolution
              .primitivesById[resolution.placements[index].primitiveId]!.role ==
          BorderPrimitiveRole.structureMedium)
        index,
  ];
  final lipIndices = <int>[
    for (var index = 0; index < resolution.placements.length; index += 1)
      if (resolution
              .primitivesById[resolution.placements[index].primitiveId]!.role ==
          BorderPrimitiveRole.structureLarge)
        index,
  ];
  expect(faceIndices.reduce(math.max), lessThan(lipIndices.reduce(math.min)));
  for (final placement in resolution.placements) {
    final primitive = resolution.primitivesById[placement.primitiveId]!;
    expect(placement.transform.flipX, isFalse, reason: placement.id);
    expect(
      primitive.transforms.allowedQuarterTurns,
      contains(placement.transform.quarterTurns),
      reason: placement.id,
    );
    if (primitive.role == BorderPrimitiveRole.structureMedium) {
      expect(placement.stableOrderKey.passIndex, 1, reason: placement.id);
      expect(placement.drawBand, BorderDrawBand.outerAccent);
    } else {
      expect(placement.stableOrderKey.passIndex, 0, reason: placement.id);
      expect(placement.drawBand, BorderDrawBand.structure);
    }
  }
  if (visualCase.rotationEnabled) {
    expect(
      resolution.placements.map((item) => item.transform.quarterTurns),
      contains(isNot(0)),
      reason: '${visualCase.id}: rotation ON must exercise a transform.',
    );
  } else {
    expect(
      resolution.placements.map((item) => item.transform.quarterTurns),
      everyElement(0),
      reason: '${visualCase.id}: rotation OFF must keep native rasters.',
    );
  }

  for (final turn in visualCase.turnVertices) {
    _expectTurnRecipe(resolution, turn);
  }
  if (visualCase.closed) {
    _expectClosedLoopHasNoCaps(resolution);
  } else {
    _expectOpenEndpointsHaveBothCaps(resolution);
  }

  if (!visualCase.closed &&
      visualCase.turnVertices.isEmpty &&
      visualCase.edgeCount >= 8) {
    _expectStraightCoreMetrics(resolution, inspection);
  }
}

void _expectStraightCoreMetrics(
  TwoTierStoneChainVisualCaseResolution resolution,
  Map<String, Object?> inspection,
) {
  final points = resolution.visualCase.points;
  final horizontal = points.first.y == points.last.y;
  final tangent =
      horizontal ? StoneChainAxis(dx: 1, dy: 0) : StoneChainAxis(dx: 0, dy: 1);
  final normal =
      horizontal ? StoneChainAxis(dx: 0, dy: 1) : StoneChainAxis(dx: 1, dy: 0);
  for (final row in <(String, List<BorderResolvedPlacement>)>[
    ('lip', resolution.lipPlacements),
    ('face', resolution.facePlacements),
  ]) {
    final continuity = _rowContinuity(
      resolution,
      row.$2,
      tangent: tangent,
      normal: normal,
    );
    final reason = '${resolution.visualCase.id}/${row.$1}';
    expect(continuity.maximumGapPx, 0, reason: reason);
    expect(continuity.minimumOverlapPx, greaterThanOrEqualTo(2),
        reason: reason);
    // Compact face stones have a ten-pixel minimum tangent span. Their strict
    // planner intentionally permits a two-pixel overlap floor, while the
    // broader lip row keeps the historical four-pixel median floor.
    expect(
      continuity.medianOverlapPx,
      inInclusiveRange(row.$1 == 'face' ? 2 : 4, 8),
      reason: reason,
    );
    expect(continuity.maximumOverlapPx, lessThanOrEqualTo(8), reason: reason);
    expect(continuity.connectedComponentCount, 1, reason: reason);
  }

  for (final face in resolution.facePlacements) {
    final contacts = <StoneChainContactMetrics>[
      for (final lip in resolution.lipPlacements)
        measureStoneChainContact(
          first: _placedMask(resolution, face),
          second: _placedMask(resolution, lip),
          tangent: tangent,
          normal: normal,
        ),
    ]..sort(
        (left, right) => right.opaqueIntersectionPixels.compareTo(
          left.opaqueIntersectionPixels,
        ),
      );
    final best = contacts.first;
    expect(
      best.opaqueIntersectionPixels,
      greaterThanOrEqualTo(8),
      reason: '${resolution.visualCase.id}/${face.slotKey}',
    );
    expect(
      best.normalOverlapPx,
      inInclusiveRange(2, 5),
      reason: '${resolution.visualCase.id}/${face.slotKey}',
    );
  }

  final lipThicknesses = <int>[
    for (final lip in resolution.lipPlacements)
      horizontal
          ? lip.opaqueWorldBoundsPx.height
          : lip.opaqueWorldBoundsPx.width,
  ]..sort();
  final medianLipThickness = _median(lipThicknesses);
  final medianVisibleDepth = inspection['medianVisibleFaceDepthPx']! as int;
  expect(
    medianVisibleDepth * 10,
    greaterThanOrEqualTo(medianLipThickness * 17),
    reason: '${resolution.visualCase.id}: face/lip visible-depth ratio.',
  );
}

void _expectTurnRecipe(
  TwoTierStoneChainVisualCaseResolution resolution,
  GridPos vertex,
) {
  final lipSlot = resolution.nodeSlotKey(
    vertex: vertex,
    passIndex: 0,
    role: BorderPrimitiveRole.lineCorner,
    rank: 0,
  );
  final incomingFaceSlot = resolution.nodeSlotKey(
    vertex: vertex,
    passIndex: 1,
    role: BorderPrimitiveRole.structureMedium,
    rank: 0,
  );
  final outgoingFaceSlot = resolution.nodeSlotKey(
    vertex: vertex,
    passIndex: 1,
    role: BorderPrimitiveRole.structureMedium,
    rank: 1,
  );
  final thirdFaceSlot = resolution.nodeSlotKey(
    vertex: vertex,
    passIndex: 1,
    role: BorderPrimitiveRole.structureMedium,
    rank: 2,
  );
  final bySlot = <String, BorderResolvedPlacement>{
    for (final placement in resolution.placements) placement.slotKey: placement,
  };
  expect(
    bySlot.keys,
    containsAll(<String>[lipSlot, incomingFaceSlot, outgoingFaceSlot]),
    reason: '${resolution.visualCase.id}/$vertex turn recipe',
  );
  expect(bySlot.containsKey(thirdFaceSlot), isFalse);
  expect(
    resolution.primitivesById[bySlot[lipSlot]!.primitiveId]!.role,
    BorderPrimitiveRole.structureLarge,
  );
  for (final slot in <String>[incomingFaceSlot, outgoingFaceSlot]) {
    expect(
      resolution.primitivesById[bySlot[slot]!.primitiveId]!.role,
      BorderPrimitiveRole.structureMedium,
    );
  }
}

void _expectClosedLoopHasNoCaps(
  TwoTierStoneChainVisualCaseResolution resolution,
) {
  final slots = resolution.placements.map((item) => item.slotKey).toSet();
  for (final vertex in resolution.visualCase.points) {
    for (final rank in const <int>[0, 1]) {
      expect(
        slots,
        isNot(
          contains(
            resolution.nodeSlotKey(
              vertex: vertex,
              passIndex: 0,
              role: BorderPrimitiveRole.lineCap,
              rank: rank,
            ),
          ),
        ),
      );
    }
    expect(
      slots,
      isNot(
        contains(
          resolution.nodeSlotKey(
            vertex: vertex,
            passIndex: 1,
            role: BorderPrimitiveRole.structureMedium,
            rank: 2,
          ),
        ),
      ),
    );
  }
}

void _expectOpenEndpointsHaveBothCaps(
  TwoTierStoneChainVisualCaseResolution resolution,
) {
  final bySlot = <String, BorderResolvedPlacement>{
    for (final placement in resolution.placements) placement.slotKey: placement,
  };
  for (final endpoint in <GridPos>[
    resolution.visualCase.points.first,
    resolution.visualCase.points.last,
  ]) {
    final lipSlot = resolution.nodeSlotKey(
      vertex: endpoint,
      passIndex: 0,
      role: BorderPrimitiveRole.lineCap,
      rank: 0,
    );
    final faceSlot = resolution.nodeSlotKey(
      vertex: endpoint,
      passIndex: 1,
      role: BorderPrimitiveRole.structureMedium,
      rank: 2,
    );
    expect(bySlot.containsKey(lipSlot), isTrue, reason: '$endpoint lip cap');
    expect(bySlot.containsKey(faceSlot), isTrue, reason: '$endpoint face cap');
  }
}

void _expectSameSlots(
  List<TwoTierStoneChainVisualCaseResolution> resolutions, {
  required String firstId,
  required String secondId,
}) {
  final first = resolutions.singleWhere(
    (resolution) => resolution.visualCase.id == firstId,
  );
  final second = resolutions.singleWhere(
    (resolution) => resolution.visualCase.id == secondId,
  );
  expect(
    second.placements.map((item) => item.slotKey).toSet(),
    first.placements.map((item) => item.slotKey).toSet(),
    reason: '$firstId/$secondId must preserve slot identity.',
  );
}

int _opaqueComponentCount(
  TwoTierStoneChainVisualCaseResolution resolution,
  List<BorderResolvedPlacement> placements,
) {
  if (placements.isEmpty) return 0;
  return measureStoneChainRowContinuity(
    samples: <StoneChainRowSample>[
      for (var index = 0; index < placements.length; index += 1)
        StoneChainRowSample(
          strokeId: 'component:$index',
          slotKey: placements[index].slotKey,
          pathDistancePx: 0,
          closed: false,
          mask: _placedMask(resolution, placements[index]),
        ),
    ],
    tangent: StoneChainAxis(dx: 1, dy: 0),
    normal: StoneChainAxis(dx: 0, dy: 1),
  ).connectedComponentCount;
}

StoneChainRowContinuity _rowContinuity(
  TwoTierStoneChainVisualCaseResolution resolution,
  List<BorderResolvedPlacement> placements, {
  required StoneChainAxis tangent,
  required StoneChainAxis normal,
}) {
  final ordered = placements.toList(growable: false)
    ..sort((left, right) {
      final byProjection = _minimumProjection(left, tangent).compareTo(
        _minimumProjection(right, tangent),
      );
      return byProjection != 0
          ? byProjection
          : left.slotKey.compareTo(right.slotKey);
    });
  return measureStoneChainRowContinuity(
    samples: <StoneChainRowSample>[
      for (var index = 0; index < ordered.length; index += 1)
        StoneChainRowSample(
          strokeId: 'straight-row',
          slotKey: ordered[index].slotKey,
          pathDistancePx: index,
          closed: false,
          mask: _placedMask(resolution, ordered[index]),
        ),
    ],
    tangent: tangent,
    normal: normal,
  );
}

StoneChainPlacedMask _placedMask(
  TwoTierStoneChainVisualCaseResolution resolution,
  BorderResolvedPlacement placement,
) =>
    StoneChainPlacedMask(
      metrics:
          resolution.primitivesById[placement.primitiveId]!.publishedMetrics,
      transform: placement.transform,
      topLeftWorldPx: placement.topLeftWorldPx,
    );

int _minimumProjection(
  BorderResolvedPlacement placement,
  StoneChainAxis axis,
) {
  final bounds = placement.opaqueWorldBoundsPx;
  return <(int, int)>[
    (bounds.x, bounds.y),
    (bounds.right - 1, bounds.y),
    (bounds.x, bounds.bottom - 1),
    (bounds.right - 1, bounds.bottom - 1),
  ].map((point) => point.$1 * axis.dx + point.$2 * axis.dy).reduce(math.min);
}

int _median(List<int> sorted) {
  if (sorted.isEmpty) return 0;
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) ~/ 2;
}
