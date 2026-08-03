import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_inspection.dart';

import '../../../map_core/test/fixtures/border/two_tier_stone_chain_fixture.dart';
import '../fixtures/border/stone_chain_visual_fixture.dart';
import '../fixtures/border/two_tier_stone_chain_visual_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reports the persisted stone-chain feature without mutating it',
      () async {
    final fixture = await StoneChainVisualFixture.load();
    final resolution = fixture.resolve(
      fixture.cases.firstWhere((candidate) => candidate.id == 'l_primary'),
    );
    final materialization = resolution.evidence.result.materialization!;
    final source = resolution.feature;
    final feature = BorderFeature(
      id: source.id,
      name: source.name,
      blueprintId: source.blueprintId,
      seed: source.seed,
      geometry: source.geometry,
      lineSide: source.lineSide,
      paramsOverride: source.paramsOverride,
      overrides: source.overrides,
      keepOutRegions: source.keepOutRegions,
      materialization: materialization,
    );
    final map = MapData(
      id: 'inspection-map',
      name: 'Inspection map',
      version: ProjectVersion.v6,
      size: stoneChainVisualMapSize,
      layers: <MapLayer>[
        MapLayer.border(
          id: 'inspection-layer',
          name: 'Inspection layer',
          content: BorderLayerContent(
            formatVersion: BorderLayerContent.formatVersionV3,
            features: <BorderFeature>[source],
          ),
        ),
      ],
    );
    final before = encodeBorderLayerContentJson(
      (map.layers.single as BorderLayer).content,
    );

    final result = inspectBorderFeature(
      map: map,
      project: fixture.manifest,
      layerId: 'inspection-layer',
      featureId: feature.id,
      preview: BorderFeatureInspectionPreview(
        layerId: 'inspection-layer',
        feature: feature,
        materialization: materialization,
      ),
    );

    expect(result['ok'], isTrue);
    expect(result['source'], 'preview');
    expect(result['template'], 'stoneChainLine');
    expect(result['alignment'], 'gridEdges');
    expect(result['side'], 'primary');
    expect(result['placementCount'], materialization.placements.length);
    expect(
      result['outputFingerprint'],
      materialization.receipt.outputFingerprint,
    );
    final strokes = result['points']! as List<Object?>;
    final inspectedStroke = strokes.single! as Map<String, Object?>;
    expect(inspectedStroke['closed'], isFalse);
    expect(
      (inspectedStroke['vertices']! as List<Object?>).length,
      resolution.visualCase.points.length,
    );
    final roles = result['roles']! as Map<String, Object?>;
    expect(
      roles.values.cast<int>().fold<int>(0, (sum, count) => sum + count),
      materialization.placements.length,
    );
    final transforms = result['transforms']! as List<Object?>;
    expect(transforms, hasLength(materialization.placements.length));
    expect(
      transforms.cast<Map<String, Object?>>(),
      everyElement(
        allOf(
          containsPair('quarterTurns', 0),
          containsPair('flipX', false),
        ),
      ),
    );
    expect(result, contains('lipCount'));
    expect(result, contains('faceCount'));
    expect(result, contains('lipMaximumGapPx'));
    expect(result, contains('faceMaximumGapPx'));
    expect(result, contains('minimumCrossRowInterlockPixels'));
    expect(result, contains('medianVisibleFaceDepthPx'));
    expect(result, contains('alignedJointRatioPermille'));
    expect(result, contains('completeTurnFacePairCount'));
    expect(result, contains('logicalFaceCount'));
    expect(result, contains('topologyNormalizedFaceLipRatioPermille'));
    expect(result['orientations'], isA<List<Object?>>());
    expect(
      encodeBorderLayerContentJson(
        (map.layers.single as BorderLayer).content,
      ),
      before,
    );
  });

  test('measures two staggered rows and exposes cardinal orientation', () {
    final fixture = TwoTierStoneChainFixture();
    final resolution = resolveStoneChainLineBorderWithEvidence(fixture.request);
    final materialization = resolution.result.materialization;
    expect(
      materialization,
      isNotNull,
      reason: resolution.result.diagnostics
          .map((diagnostic) => diagnostic.code)
          .join(', '),
    );
    final feature = _withMaterialization(
      fixture.request.feature,
      materialization!,
    );
    final map = MapData(
      id: 'two-tier-inspection-map',
      name: 'Two-tier inspection map',
      version: ProjectVersion.v6,
      size: fixture.request.mapSize,
      layers: <MapLayer>[
        MapLayer.border(
          id: 'two-tier-border-layer',
          name: 'Two-tier border layer',
          content: BorderLayerContent(
            formatVersion: BorderLayerContent.formatVersionV3,
            features: <BorderFeature>[feature],
          ),
        ),
      ],
    );
    final project = _projectForTwoTierFixture(fixture);
    final beforeMap = map.toJson();

    final result = inspectBorderFeature(
      map: map,
      project: project,
      layerId: 'two-tier-border-layer',
      featureId: feature.id,
    );

    expect(result['ok'], isTrue);
    final roles = result['roles']! as Map<String, Object?>;
    final expectedLipCount = (roles['structureLarge'] as int? ?? 0) +
        (roles['lineCorner'] as int? ?? 0) +
        (roles['lineCap'] as int? ?? 0);
    expect(result['lipCount'], expectedLipCount);
    expect(result['faceCount'], roles['structureMedium']);
    expect(result['completeTurnFacePairCount'], 0);
    expect(result['logicalFaceCount'], result['faceCount']);
    expect(
      result['topologyNormalizedFaceLipRatioPermille'],
      (result['faceCount'] as int) * 1000 ~/ (result['lipCount'] as int),
    );
    expect(result['lipMaximumGapPx'], 0);
    expect(result['faceMaximumGapPx'], 0);
    expect(result['minimumCrossRowInterlockPixels'], greaterThanOrEqualTo(8));
    expect(result['medianVisibleFaceDepthPx'], greaterThanOrEqualTo(12));
    // The row planner deliberately staggers every face joint beyond the
    // inspection tolerance instead of reproducing the old 423 permille
    // aligned cadence.
    expect(result['alignedJointRatioPermille'], 0);

    final orientations =
        (result['orientations']! as List<Object?>).cast<Map<String, Object?>>();
    expect(orientations, hasLength(fixture.primitives.length));
    expect(
      orientations.map((entry) => entry['authoredOrientation']).toSet(),
      <String>{'north', 'east', 'south', 'west'},
    );
    final transforms =
        (result['transforms']! as List<Object?>).cast<Map<String, Object?>>();
    expect(transforms, hasLength(materialization.placements.length));
    expect(
      transforms,
      everyElement(
        allOf(
          containsPair('authoredOrientation', 'south'),
          containsPair('effectiveOrientation', 'south'),
        ),
      ),
    );
    expect(map.toJson(), beforeMap);
  });

  test('measures a missing middle section inside one topological run', () {
    final fixture = TwoTierStoneChainFixture();
    final resolved = _resolvedTwoTierMaterialization(fixture);
    final materialization = BorderMaterialization(
      receipt: resolved.receipt,
      ground: resolved.ground,
      placements: <BorderResolvedPlacement>[
        for (final placement in resolved.placements)
          if (placement.anchorCell.x <= 6 || placement.anchorCell.x >= 22)
            placement,
      ],
    );

    final result = _inspectTwoTierMaterialization(fixture, materialization);

    expect(result['lipMaximumGapPx'], greaterThan(0));
    expect(result['faceMaximumGapPx'], greaterThan(0));
  });

  test('aligns face joints within two pixels but excludes three pixels', () {
    final fixture = TwoTierStoneChainFixture();
    final resolved = _resolvedTwoTierMaterialization(fixture);
    final roleByPrimitiveId = <String, BorderPrimitiveRole>{
      for (final primitive in fixture.primitives) primitive.id: primitive.role,
    };
    final lips = resolved.placements
        .where(
          (placement) =>
              roleByPrimitiveId[placement.primitiveId] ==
              BorderPrimitiveRole.structureLarge,
        )
        .toList(growable: false)
      ..sort(_comparePlacementAlongPositiveX);
    final faces = resolved.placements
        .where(
          (placement) =>
              roleByPrimitiveId[placement.primitiveId] ==
              BorderPrimitiveRole.structureMedium,
        )
        .toList(growable: false)
      ..sort(_comparePlacementAlongPositiveX);
    final lipPair = lips.take(2).toList(growable: false);
    final facePair = faces.take(2).toList(growable: false);
    final selectedSlotKeys = <String>{
      for (final placement in lipPair) placement.slotKey,
      for (final placement in facePair) placement.slotKey,
    };
    final faceSlotKeys = <String>{
      for (final placement in facePair) placement.slotKey,
    };
    final lipJoint = _jointAlongPositiveX(lipPair);
    final originalFaceJoint = _jointAlongPositiveX(facePair);

    for (final offsetAndExpected in <(int, int)>[
      (-3, 0),
      (-2, 1000),
      (2, 1000),
      (3, 0),
    ]) {
      final offset = offsetAndExpected.$1;
      final expected = offsetAndExpected.$2;
      final faceShift = lipJoint + offset - originalFaceJoint;
      final materialization = BorderMaterialization(
        receipt: resolved.receipt,
        ground: resolved.ground,
        placements: <BorderResolvedPlacement>[
          for (final placement in resolved.placements)
            if (selectedSlotKeys.contains(placement.slotKey))
              if (faceSlotKeys.contains(placement.slotKey))
                _shiftPlacementX(placement, faceShift)
              else
                placement,
        ],
      );

      final result = _inspectTwoTierMaterialization(fixture, materialization);

      expect(
        result['alignedJointRatioPermille'],
        expected,
        reason: 'joint offset: $offset px',
      );
    }
  });

  test(
    'keeps primary and inverted L/S turn faces in their physical stroke',
    () async {
      final fixture = await TwoTierStoneChainVisualFixture.load();
      addTearDown(fixture.dispose);

      for (final caseAndTurn in const <(String, GridPos)>[
        ('l_convex_primary', GridPos(x: 10, y: 2)),
        ('l_concave_inverted', GridPos(x: 10, y: 2)),
        ('s_primary', GridPos(x: 7, y: 2)),
        ('s_inverted', GridPos(x: 7, y: 2)),
      ]) {
        final caseId = caseAndTurn.$1;
        final turn = caseAndTurn.$2;
        final visualCase = fixture.cases.singleWhere(
          (candidate) => candidate.id == caseId,
        );
        final resolution = fixture.resolve(visualCase);
        expect(
          resolution.evidence.result.canApply,
          isTrue,
          reason: '$caseId: ${resolution.diagnostics}',
        );
        expect(
          fixture.inspect(resolution)['minimumCrossRowInterlockPixels'],
          greaterThanOrEqualTo(8),
          reason: '$caseId control must start physically interlocked.',
        );

        final materialization = resolution.evidence.result.materialization!;
        final turnFaceSlotKey = resolution.nodeSlotKey(
          vertex: turn,
          passIndex: 1,
          role: BorderPrimitiveRole.structureMedium,
          rank: 1,
        );
        final turnFace = materialization.placements.singleWhere(
          (placement) => placement.slotKey == turnFaceSlotKey,
        );
        final inspectedMaterialization =
            visualCase.lineSide == BorderLineSide.inverted
                ? BorderMaterialization(
                    receipt: materialization.receipt,
                    ground: materialization.ground,
                    placements: <BorderResolvedPlacement>[
                      for (final placement in materialization.placements)
                        if (placement.slotKey == turnFaceSlotKey)
                          _withAnchorCell(
                            placement,
                            GridPos(x: turnFace.anchorCell.x, y: turn.y - 1),
                          )
                        else
                          placement,
                    ],
                  )
                : materialization;
        final inspectedFeature = _withMaterialization(
          resolution.feature,
          inspectedMaterialization,
        );
        final inspectedMap = MapData(
          id: 'inspection-$caseId',
          name: caseId,
          version: ProjectVersion.v6,
          size: resolution.request.mapSize,
          layers: <MapLayer>[
            MapLayer.border(
              id: 'inspection-layer',
              name: 'Inspection layer',
              content: BorderLayerContent(
                formatVersion: BorderLayerContent.formatVersionV3,
                features: <BorderFeature>[inspectedFeature],
              ),
            ),
          ],
        );

        final result = inspectBorderFeature(
          map: inspectedMap,
          project: fixture.manifest,
          layerId: 'inspection-layer',
          featureId: inspectedFeature.id,
        );

        expect(
          result['minimumCrossRowInterlockPixels'],
          greaterThanOrEqualTo(8),
          reason: '$caseId has a physically interlocked turn face even when '
              'its canonical station is one tangent cell before the outgoing '
              'run.',
        );
      }
    },
  );

  test('binds an inverted S shoulder to its outgoing run beside a parallel run',
      () async {
    final fixture = await TwoTierStoneChainVisualFixture.load();
    addTearDown(fixture.dispose);
    final scenario = _inspectInvertedSShoulder(
      fixture,
      useKnownOutgoingSlot: true,
    );
    expect(
      scenario.physicalInterlockPixels,
      greaterThanOrEqualTo(8),
    );
    expect(
      scenario.inspection['minimumCrossRowInterlockPixels'],
      greaterThanOrEqualTo(8),
    );
  });

  test('leaves an unknown one-cell shoulder slot unassigned', () async {
    final fixture = await TwoTierStoneChainVisualFixture.load();
    addTearDown(fixture.dispose);
    final scenario = _inspectInvertedSShoulder(
      fixture,
      useKnownOutgoingSlot: false,
    );

    expect(scenario.physicalInterlockPixels, greaterThanOrEqualTo(8));
    expect(scenario.inspection['minimumCrossRowInterlockPixels'], 0);
  });

  test('reports a precise miss instead of falling back to another feature', () {
    const map = MapData(
      id: 'empty',
      name: 'Empty',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
    );
    const project = ProjectManifest(
      name: 'Inspection project',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );

    final result = inspectBorderFeature(
      map: map,
      project: project,
      layerId: 'missing-layer',
      featureId: 'missing-feature',
    );

    expect(result, <String, Object?>{
      'ok': false,
      'error': 'Border feature not found.',
      'layerId': 'missing-layer',
      'featureId': 'missing-feature',
    });
  });
}

BorderMaterialization _resolvedTwoTierMaterialization(
  TwoTierStoneChainFixture fixture,
) {
  final resolution = resolveStoneChainLineBorderWithEvidence(fixture.request);
  final materialization = resolution.result.materialization;
  expect(
    materialization,
    isNotNull,
    reason: resolution.result.diagnostics
        .map((diagnostic) => diagnostic.code)
        .join(', '),
  );
  return materialization!;
}

Map<String, Object?> _inspectTwoTierMaterialization(
  TwoTierStoneChainFixture fixture,
  BorderMaterialization materialization,
) {
  final feature = _withMaterialization(
    fixture.request.feature,
    materialization,
  );
  final map = MapData(
    id: 'two-tier-inspection-map',
    name: 'Two-tier inspection map',
    version: ProjectVersion.v6,
    size: fixture.request.mapSize,
    layers: <MapLayer>[
      MapLayer.border(
        id: 'two-tier-border-layer',
        name: 'Two-tier border layer',
        content: BorderLayerContent(
          formatVersion: BorderLayerContent.formatVersionV3,
          features: <BorderFeature>[feature],
        ),
      ),
    ],
  );
  return inspectBorderFeature(
    map: map,
    project: _projectForTwoTierFixture(fixture),
    layerId: 'two-tier-border-layer',
    featureId: feature.id,
  );
}

int _comparePlacementAlongPositiveX(
  BorderResolvedPlacement left,
  BorderResolvedPlacement right,
) {
  final byX = left.opaqueWorldBoundsPx.x.compareTo(
    right.opaqueWorldBoundsPx.x,
  );
  return byX != 0 ? byX : left.slotKey.compareTo(right.slotKey);
}

int _jointAlongPositiveX(List<BorderResolvedPlacement> pair) {
  assert(pair.length == 2);
  final ordered = pair.toList(growable: false)
    ..sort(_comparePlacementAlongPositiveX);
  return ((ordered.first.opaqueWorldBoundsPx.right - 1) +
          ordered.last.opaqueWorldBoundsPx.x) ~/
      2;
}

BorderResolvedPlacement _shiftPlacementX(
  BorderResolvedPlacement source,
  int delta,
) =>
    BorderResolvedPlacement(
      id: source.id,
      slotKey: source.slotKey,
      primitiveId: source.primitiveId,
      visualSnapshotId: source.visualSnapshotId,
      anchorCell: source.anchorCell,
      topLeftWorldPx: BorderPixelPos(
        x: source.topLeftWorldPx.x + delta,
        y: source.topLeftWorldPx.y,
      ),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: source.opaqueWorldBoundsPx.x + delta,
        y: source.opaqueWorldBoundsPx.y,
        width: source.opaqueWorldBoundsPx.width,
        height: source.opaqueWorldBoundsPx.height,
      ),
      transform: source.transform,
      drawBand: source.drawBand,
      stableOrderKey: source.stableOrderKey,
    );

BorderResolvedPlacement _withAnchorCell(
  BorderResolvedPlacement source,
  GridPos anchorCell,
) =>
    BorderResolvedPlacement(
      id: source.id,
      slotKey: source.slotKey,
      primitiveId: source.primitiveId,
      visualSnapshotId: source.visualSnapshotId,
      anchorCell: anchorCell,
      topLeftWorldPx: source.topLeftWorldPx,
      opaqueWorldBoundsPx: source.opaqueWorldBoundsPx,
      transform: source.transform,
      drawBand: source.drawBand,
      stableOrderKey: source.stableOrderKey,
    );

BorderResolvedPlacement _withSlotAndAnchorCell(
  BorderResolvedPlacement source, {
  required String slotKey,
  required GridPos anchorCell,
}) =>
    BorderResolvedPlacement(
      id: 'border-placement-v1:'
          '${slotKey.substring(borderSlotKeyV1Prefix.length)}',
      slotKey: slotKey,
      primitiveId: source.primitiveId,
      visualSnapshotId: source.visualSnapshotId,
      anchorCell: anchorCell,
      topLeftWorldPx: source.topLeftWorldPx,
      opaqueWorldBoundsPx: source.opaqueWorldBoundsPx,
      transform: source.transform,
      drawBand: source.drawBand,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: source.stableOrderKey.drawBandIndex,
        anchorRowMajor: source.stableOrderKey.anchorRowMajor,
        passIndex: source.stableOrderKey.passIndex,
        rank: source.stableOrderKey.rank,
        ordinalLocal: source.stableOrderKey.ordinalLocal,
        slotKey: slotKey,
      ),
    );

StoneChainPlacedMask _maskForPlacement(
  TwoTierStoneChainVisualFixture fixture,
  BorderResolvedPlacement placement,
) =>
    StoneChainPlacedMask(
      metrics: fixture.primitivesById[placement.primitiveId]!.publishedMetrics,
      transform: placement.transform,
      topLeftWorldPx: placement.topLeftWorldPx,
    );

({int physicalInterlockPixels, Map<String, Object?> inspection})
    _inspectInvertedSShoulder(
  TwoTierStoneChainVisualFixture fixture, {
  required bool useKnownOutgoingSlot,
}) {
  final visualCase = fixture.cases.singleWhere(
    (candidate) => candidate.id == 's_inverted',
  );
  final resolution = fixture.resolve(visualCase);
  final sourceMaterialization = resolution.evidence.result.materialization!;
  const sourceTurn = GridPos(x: 7, y: 2);
  final sourceTurnFaceSlotKey = resolution.nodeSlotKey(
    vertex: sourceTurn,
    passIndex: 1,
    role: BorderPrimitiveRole.structureMedium,
    rank: 1,
  );
  final sourceTurnFace = sourceMaterialization.placements.singleWhere(
    (placement) => placement.slotKey == sourceTurnFaceSlotKey,
  );
  const strokeId = 'inspection-inverted-s';
  const turn = GridPos(x: 7, y: 4);
  final inspectedSlotKey = buildBorderStoneChainNodeSlotKey(
    featureId: resolution.feature.id,
    strokeId: borderStrokeLineageNamespaceV1(strokeId),
    vertex: turn,
    passIndex: 1,
    role: BorderPrimitiveRole.structureMedium,
    rank: useKnownOutgoingSlot ? 1 : 2,
  );
  final inspectedTurnFace = _withSlotAndAnchorCell(
    sourceTurnFace,
    slotKey: inspectedSlotKey,
    anchorCell: const GridPos(x: 7, y: 3),
  );
  final faceMask = _maskForPlacement(fixture, inspectedTurnFace);
  final eastFacingLips = resolution.lipPlacements.where(
    (placement) => _hasEffectiveEastOrientation(fixture, placement),
  );
  final sourceLip = eastFacingLips.reduce((best, candidate) {
    final bestContact = measureStoneChainContact(
      first: _maskForPlacement(fixture, best),
      second: faceMask,
      tangent: StoneChainAxis(dx: 0, dy: -1),
      normal: StoneChainAxis(dx: 1, dy: 0),
    ).opaqueIntersectionPixels;
    final candidateContact = measureStoneChainContact(
      first: _maskForPlacement(fixture, candidate),
      second: faceMask,
      tangent: StoneChainAxis(dx: 0, dy: -1),
      normal: StoneChainAxis(dx: 1, dy: 0),
    ).opaqueIntersectionPixels;
    return candidateContact > bestContact ? candidate : best;
  });
  final inspectedLip = _withAnchorCell(
    sourceLip,
    const GridPos(x: 7, y: 4),
  );
  final physicalInterlockPixels = measureStoneChainContact(
    first: _maskForPlacement(fixture, inspectedLip),
    second: faceMask,
    tangent: StoneChainAxis(dx: 0, dy: -1),
    normal: StoneChainAxis(dx: 1, dy: 0),
  ).opaqueIntersectionPixels;
  final placements = <BorderResolvedPlacement>[
    inspectedTurnFace,
    inspectedLip,
  ]..sort(
      (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey),
    );
  final materialization = BorderMaterialization(
    receipt: sourceMaterialization.receipt,
    ground: sourceMaterialization.ground,
    placements: placements,
  );
  final source = resolution.feature;
  final feature = BorderFeature(
    id: source.id,
    name: source.name,
    blueprintId: source.blueprintId,
    seed: source.seed,
    geometry: BorderStrokeGeometry(
      strokes: <BorderStroke>[
        BorderStroke(
          id: strokeId,
          points: const <GridPos>[
            GridPos(x: 5, y: 4),
            GridPos(x: 6, y: 4),
            turn,
            GridPos(x: 7, y: 5),
            GridPos(x: 7, y: 6),
            GridPos(x: 8, y: 6),
            GridPos(x: 9, y: 6),
          ],
          closed: false,
        ),
        BorderStroke(
          id: 'nearby-parallel-run',
          points: const <GridPos>[
            GridPos(x: 7, y: 1),
            GridPos(x: 7, y: 2),
          ],
          closed: false,
        ),
      ],
      alignment: BorderStrokeAlignment.gridEdges,
    ),
    lineSide: BorderLineSide.inverted,
    paramsOverride: source.paramsOverride,
    overrides: source.overrides,
    keepOutRegions: source.keepOutRegions,
    materialization: materialization,
  );
  final inspection = inspectBorderFeature(
    map: fixture.mapFor(resolution),
    project: fixture.manifest,
    layerId: 'two-tier-stone-chain-visual-layer',
    featureId: source.id,
    preview: BorderFeatureInspectionPreview(
      layerId: 'two-tier-stone-chain-visual-layer',
      feature: feature,
      materialization: materialization,
    ),
  );
  return (
    physicalInterlockPixels: physicalInterlockPixels,
    inspection: inspection,
  );
}

bool _hasEffectiveEastOrientation(
  TwoTierStoneChainVisualFixture fixture,
  BorderResolvedPlacement placement,
) {
  final authored =
      fixture.primitivesById[placement.primitiveId]!.authoredOrientation;
  final authoredRank = switch (authored) {
    BorderPrimitiveOrientation.east => 0,
    BorderPrimitiveOrientation.south => 1,
    BorderPrimitiveOrientation.west => 2,
    BorderPrimitiveOrientation.north => 3,
    BorderPrimitiveOrientation.legacyAxis => -1,
  };
  return authoredRank >= 0 &&
      (authoredRank + placement.transform.quarterTurns) % 4 == 0;
}

BorderFeature _withMaterialization(
  BorderFeature source,
  BorderMaterialization materialization,
) =>
    BorderFeature(
      id: source.id,
      name: source.name,
      blueprintId: source.blueprintId,
      seed: source.seed,
      geometry: source.geometry,
      lineSide: source.lineSide,
      paramsOverride: source.paramsOverride,
      overrides: source.overrides,
      keepOutRegions: source.keepOutRegions,
      materialization: materialization,
    );

ProjectManifest _projectForTwoTierFixture(TwoTierStoneChainFixture fixture) {
  final published = fixture.blueprintRevision.definition;
  return ProjectManifest(
    name: 'Two-tier inspection project',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.formatVersionV4,
      records: <BorderBlueprintRecord>[
        BorderBlueprintRecord(
          id: fixture.request.blueprintId,
          draft: BorderBlueprintDraft(
            baseRevision: fixture.blueprintRevision.revision,
            definition: BorderBlueprintDraftDefinition(
              name: published.name,
              previewSeed: published.previewSeed,
              template: published.template,
              primitives: <BorderPrimitiveDraft>[
                for (final primitive in published.primitives)
                  BorderPrimitiveDraft(
                    id: primitive.id,
                    sourceElementId: primitive.sourceElementId,
                    role: primitive.role,
                    authoredOrientation: primitive.authoredOrientation,
                    weight: primitive.weight,
                    anchorPx: primitive.anchorPx,
                    transforms: primitive.transforms,
                    currentMetrics: primitive.publishedMetrics,
                  ),
              ],
              defaults: published.defaults,
              ground: null,
              categoryId: published.categoryId,
              sortOrder: published.sortOrder,
            ),
          ),
          latestPublished: fixture.blueprintRevision,
        ),
      ],
      visualSnapshots: fixture.snapshots,
    ),
  );
}
