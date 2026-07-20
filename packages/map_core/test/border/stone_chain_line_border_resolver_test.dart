import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/stone_chain_line_fixture.dart';
import '../fixtures/border/two_tier_stone_chain_fixture.dart';

void main() {
  test('resolves one sparse primary chain deterministically', () {
    final request = StoneChainLineFixture().request;
    final first = resolveStoneChainLineBorderWithEvidence(request);
    final second = resolveStoneChainLineBorderWithEvidence(request);

    expect(first, second);
    expect(first.result.canApply, isTrue);
    expect(first.result.materialization!.ground, isEmpty);
    expect(first.primaryPlacementCount, inInclusiveRange(3, 30));
    expect(first.placementsPerSegmentPermille, inInclusiveRange(1500, 2250));
  });

  test('samples continuously across adjacent edges', () {
    final evidence = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture().request,
    );

    expect(
      evidence.result.canApply,
      isTrue,
      reason: evidence.result.diagnostics
          .map((item) => '${item.code}:${item.parameters}')
          .join(', '),
    );
    expect(evidence.maximumGapPx, lessThanOrEqualTo(2));
  });

  test('does not repeat one straight primary variant three times', () {
    final evidence = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        featureSeed: 0,
        primitives: <BorderPublishedPrimitive>[
          stoneChainPrimitive(
            id: 'large-a',
            character: 'a',
            width: 16,
            height: 16,
          ),
          stoneChainPrimitive(
            id: 'large-b',
            character: 'b',
            width: 16,
            height: 16,
          ),
          stoneChainPrimitive(
            id: 'large-c',
            character: 'c',
            width: 16,
            height: 16,
          ),
          stoneChainPrimitive(
            id: 'cap',
            character: 'd',
            role: BorderPrimitiveRole.lineCap,
            width: 8,
            height: 8,
          ),
        ],
      ).request,
    );

    expect(evidence.maximumRepeatedPrimitiveRunLength, lessThanOrEqualTo(2));
  });

  test('applies bounded deterministic irregularity without changing slots', () {
    StoneChainLineBorderResolutionEvidence resolve(int irregularityPermille) =>
        resolveStoneChainLineBorderWithEvidence(
          StoneChainLineFixture(
            featureSeed: 884,
            parameters: stoneChainParameters(
              irregularityPermille: irregularityPermille,
              depthRows: 1,
              allowAutoRotation: false,
            ),
          ).request,
        );

    final regular = resolve(0);
    final irregular = resolve(1000);
    final repeated = resolve(1000);
    expect(
      regular.result.canApply,
      isTrue,
      reason: regular.result.diagnostics
          .map((item) => '${item.code}:${item.cell}:${item.parameters}')
          .join(', '),
    );
    expect(
      irregular.result.canApply,
      isTrue,
      reason: irregular.result.diagnostics.map((item) => item.code).join(', '),
    );
    final regularBySlot = <String, BorderResolvedPlacement>{
      for (final placement in regular.result.materialization!.placements)
        placement.slotKey: placement,
    };
    final irregularBySlot = <String, BorderResolvedPlacement>{
      for (final placement in irregular.result.materialization!.placements)
        placement.slotKey: placement,
    };
    final movedDeltas = <(int, int)>[
      for (final slotKey in regularBySlot.keys)
        if (irregularBySlot[slotKey] case final irregularPlacement?)
          (
            irregularPlacement.topLeftWorldPx.x -
                regularBySlot[slotKey]!.topLeftWorldPx.x,
            irregularPlacement.topLeftWorldPx.y -
                regularBySlot[slotKey]!.topLeftWorldPx.y,
          ),
    ];

    expect(irregular.result.canApply, isTrue);
    expect(irregular.result.materialization, repeated.result.materialization);
    expect(irregularBySlot.keys.toSet(), regularBySlot.keys.toSet());
    expect(movedDeltas, contains(isNot((0, 0))));
    expect(
      movedDeltas,
      everyElement(
        predicate<(int, int)>(
          (delta) => delta.$1.abs() <= 4 && delta.$2.abs() <= 4,
          'combined normal/tangent fitting stays within four pixels per axis',
        ),
      ),
    );
    expect(
      irregular.maximumGapPx,
      lessThanOrEqualTo(2),
      reason: irregular.result.materialization!.placements
          .map(
            (placement) => '${placement.primitiveId}@'
                '${placement.opaqueWorldBoundsPx.x},'
                '${placement.opaqueWorldBoundsPx.y},'
                '${placement.opaqueWorldBoundsPx.width}x'
                '${placement.opaqueWorldBoundsPx.height}',
          )
          .join(' | '),
    );
    expect(irregular.maximumTangentOverlapPx, lessThanOrEqualTo(3));
  });

  test('breaks the straight primary cadence within the continuity budgets', () {
    final primitives = <BorderPublishedPrimitive>[
      for (final id in <String>['large-a', 'large-b', 'large-c'])
        stoneChainPrimitive(
          id: id,
          character: id.substring(id.length - 1),
          width: 16,
          height: 14,
          allowedQuarterTurns: const <int>[0],
        ),
      stoneChainPrimitive(
        id: 'cap',
        character: 'd',
        role: BorderPrimitiveRole.lineCap,
        width: 8,
        height: 8,
        allowedQuarterTurns: const <int>[0],
      ),
    ];
    StoneChainLineBorderResolutionEvidence resolve(int irregularityPermille) =>
        resolveStoneChainLineBorderWithEvidence(
          StoneChainLineFixture(
            mapSize: const GridSize(width: 22, height: 8),
            strokes: <BorderStroke>[
              stoneChainHorizontalStroke(
                id: 'organic-cadence',
                startX: 2,
                edgeCount: 16,
                y: 4,
              ),
            ],
            primitives: primitives,
            featureSeed: 884,
            parameters: stoneChainParameters(
              irregularityPermille: irregularityPermille,
              detailDensityPermille: 0,
              variationPermille: 900,
              maxOverlapPx: 2,
              gapTolerancePx: 2,
              depthRows: 1,
              allowAutoRotation: false,
            ),
          ).request,
        );

    final regular = resolve(0);
    final irregular = resolve(280);
    final repeated = resolve(280);
    expect(regular.result.canApply, isTrue);
    expect(
      irregular.result.canApply,
      isTrue,
      reason: irregular.result.diagnostics
          .map((item) => '${item.code}:${item.parameters}')
          .join(', '),
    );
    final primaryIds = <String>{'large-a', 'large-b', 'large-c'};
    List<BorderResolvedPlacement> primaries(
      StoneChainLineBorderResolutionEvidence evidence,
    ) =>
        evidence.result.materialization!.placements
            .where((placement) => primaryIds.contains(placement.primitiveId))
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.topLeftWorldPx.x.compareTo(right.topLeftWorldPx.x),
          );

    final regularPrimaries = primaries(regular);
    final irregularPrimaries = primaries(irregular);
    final interiorAnchors = irregularPrimaries
        .skip(2)
        .take(irregularPrimaries.length - 4)
        .map((placement) => placement.topLeftWorldPx.x + 8)
        .toList(growable: false);
    final spacings = <int>[
      for (var index = 1; index < interiorAnchors.length; index += 1)
        interiorAnchors[index] - interiorAnchors[index - 1],
    ];
    final regularBySlot = <String, BorderResolvedPlacement>{
      for (final placement in regularPrimaries) placement.slotKey: placement,
    };
    final irregularBySlot = <String, BorderResolvedPlacement>{
      for (final placement in irregularPrimaries) placement.slotKey: placement,
    };
    final tangentDeltas = irregularBySlot.entries
        .map(
          (entry) =>
              entry.value.topLeftWorldPx.x -
              regularBySlot[entry.key]!.topLeftWorldPx.x,
        )
        .toList(growable: false);

    expect(spacings.toSet(), hasLength(greaterThan(1)));
    expect(irregular.result.materialization, repeated.result.materialization);
    expect(irregularBySlot.keys.toSet(), regularBySlot.keys.toSet());
    expect(irregular.primaryPlacementCount, regular.primaryPlacementCount);
    expect(irregular.secondaryPlacementCount, regular.secondaryPlacementCount);
    expect(tangentDeltas, contains(isNot(0)));
    expect(
      tangentDeltas.map((delta) => delta.abs()),
      contains(2),
      reason: 'The Selbrume irregularity profile must visibly break the '
          'one-stone-per-station cadence.',
    );
    expect(
      tangentDeltas,
      everyElement(inInclusiveRange(-2, 2)),
    );
    expect(irregular.maximumGapPx, lessThanOrEqualTo(2));
    expect(irregular.maximumTangentOverlapPx, lessThanOrEqualTo(2));
  });

  test('keeps medium stones out of the primary body cadence', () {
    final primitives = <BorderPublishedPrimitive>[
      for (final id in <String>['large-a', 'large-b', 'large-c'])
        stoneChainPrimitive(
          id: id,
          character: id.substring(id.length - 1),
          width: 16,
          height: 14,
          allowedQuarterTurns: const <int>[0],
        ),
      for (final entry in <(String, String)>[
        ('medium-a', 'e'),
        ('medium-b', 'f'),
        ('medium-c', '0'),
      ])
        stoneChainPrimitive(
          id: entry.$1,
          character: entry.$2,
          role: BorderPrimitiveRole.structureMedium,
          width: 16,
          height: 10,
          allowedQuarterTurns: const <int>[0],
        ),
      stoneChainPrimitive(
        id: 'cap',
        character: 'd',
        role: BorderPrimitiveRole.lineCap,
        width: 8,
        height: 8,
        allowedQuarterTurns: const <int>[0],
      ),
    ];
    StoneChainLineBorderResolutionEvidence resolve() =>
        resolveStoneChainLineBorderWithEvidence(
          StoneChainLineFixture(
            mapSize: const GridSize(width: 26, height: 8),
            strokes: <BorderStroke>[
              stoneChainHorizontalStroke(
                id: 'mixed-scale-cadence',
                startX: 2,
                edgeCount: 20,
                y: 4,
              ),
            ],
            primitives: primitives,
            featureSeed: 71,
            parameters: stoneChainParameters(
              irregularityPermille: 0,
              detailDensityPermille: 0,
              variationPermille: 1000,
              maxOverlapPx: 2,
              gapTolerancePx: 2,
              depthRows: 1,
              allowAutoRotation: false,
            ),
          ).request,
        );

    final first = resolve();
    final repeated = resolve();
    expect(first.result.canApply, isTrue);
    expect(first.result.materialization, repeated.result.materialization);
    final body = first.result.materialization!.placements
        .where((placement) => placement.primitiveId != 'cap')
        .toList(growable: false);
    final mediumCount = body
        .where((placement) => placement.primitiveId.startsWith('medium-'))
        .length;
    expect(
      mediumCount,
      0,
      reason: 'Medium stones are depth details and turn connectors. Mixing '
          'them into a straight primary run creates abrupt scale jumps.',
    );
    expect(
      body,
      everyElement(
        isA<BorderResolvedPlacement>().having(
          (placement) => placement.primitiveId,
          'primitiveId',
          startsWith('large-'),
        ),
      ),
    );
    expect(first.maximumGapPx, lessThanOrEqualTo(2));
    expect(first.maximumTangentOverlapPx, lessThanOrEqualTo(2));
    expect(first.maximumRepeatedPrimitiveRunLength, lessThanOrEqualTo(2));
  });

  test('samples from the selected transformed opaque tangent extent', () {
    final primitives = <BorderPublishedPrimitive>[
      stoneChainPrimitive(
        id: 'large-wide',
        character: 'd',
        width: 24,
        height: 8,
      ),
      stoneChainPrimitive(
        id: 'cap-small',
        character: 'e',
        role: BorderPrimitiveRole.lineCap,
        width: 16,
        height: 8,
      ),
    ];
    final fixture = StoneChainLineFixture(
      primitives: primitives,
      parameters: stoneChainParameters(
        maxOverlapPx: 3,
        gapTolerancePx: 0,
        depthRows: 1,
        allowAutoRotation: false,
      ),
    );
    final result = resolveStoneChainLineBorder(fixture.request);
    expect(
      result.canApply,
      isTrue,
      reason: result.diagnostics
          .map((item) => '${item.code}: ${item.parameters}')
          .join(', '),
    );
    final placements = _placementsWithRole(
      fixture.request,
      result,
      BorderPrimitiveRole.structureLarge,
    )..sort((left, right) =>
        left.opaqueWorldBoundsPx.x.compareTo(right.opaqueWorldBoundsPx.x));

    expect(placements.length, greaterThan(2));
    for (var index = 1; index < placements.length; index += 1) {
      final previous = placements[index - 1].opaqueWorldBoundsPx;
      final current = placements[index].opaqueWorldBoundsPx;
      final previousCenterX = previous.x + previous.width ~/ 2;
      final currentCenterX = current.x + current.width ~/ 2;
      expect(
        currentCenterX - previousCenterX,
        21,
        reason: placements
            .map((placement) =>
                '${placement.primitiveId}@${placement.opaqueWorldBoundsPx.x}')
            .join(', '),
      );
    }
  });

  test('reports the maximum opaque gap measured from visible placements', () {
    final evidence = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        parameters: stoneChainParameters(
          gapTolerancePx: 8,
          depthRows: 1,
          allowAutoRotation: false,
        ),
      ).request,
    );
    final measured = _maximumHorizontalOpaqueGap(
      evidence.result.materialization!.placements,
    );

    expect(measured, greaterThan(1));
    expect(evidence.maximumGapPx, measured);
  });

  test('places exactly one corner recipe', () {
    final fixture = StoneChainLineFixture(
      strokes: <BorderStroke>[
        _stroke('corner', const <GridPos>[
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 4, y: 2),
          GridPos(x: 4, y: 3),
          GridPos(x: 4, y: 4),
        ]),
      ],
    );
    final result = resolveStoneChainLineBorder(fixture.request);

    expect(
      result.canApply,
      isTrue,
      reason: result.diagnostics
          .map((item) => '${item.code}:${item.cell}:${item.parameters}')
          .join(', '),
    );
    expect(
        _placementsWithRole(
            fixture.request, result, BorderPrimitiveRole.lineCorner),
        hasLength(1));
  });

  test('shares one connector across each one-cell zigzag leg', () {
    final stroke = _stroke('tight-zigzag', const <GridPos>[
      GridPos(x: 1, y: 2),
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
      GridPos(x: 3, y: 3),
      GridPos(x: 4, y: 3),
      GridPos(x: 4, y: 4),
      GridPos(x: 4, y: 5),
      GridPos(x: 4, y: 6),
    ]);
    final fixture = StoneChainLineFixture(
      parameters: stoneChainParameters(
        detailDensityPermille: 0,
        gapTolerancePx: 4,
        depthRows: 1,
      ),
      strokes: <BorderStroke>[stroke],
    );

    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);

    expect(
      evidence.result.canApply,
      isTrue,
      reason: evidence.result.diagnostics
          .map((item) => '${item.code}:${item.cell}:${item.parameters}')
          .join(', '),
    );
    final placements = evidence.result.materialization!.placements;
    final rolesById = <String, BorderPrimitiveRole>{
      for (final primitive
          in fixture.request.blueprintRevision!.definition.primitives)
        primitive.id: primitive.role,
    };
    final placementSummary = placements
        .map((item) =>
            '${rolesById[item.primitiveId]?.name}:${item.slotKey}@${item.opaqueWorldBoundsPx}')
        .join(', ');
    String connectorSlot(int vertexIndex, {required bool incoming}) =>
        buildBorderStoneChainNodeSlotKey(
          featureId: fixture.request.feature.id,
          strokeId: borderStrokeLineageNamespaceV1(stroke.id),
          vertex: stroke.points[vertexIndex],
          passIndex: 0,
          role: BorderPrimitiveRole.structureMedium,
          rank: vertexIndex * 2 + (incoming ? 0 : 1),
        );
    final connectorSlots = placements.map((item) => item.slotKey).toSet();
    final placementsBySlot = <String, BorderResolvedPlacement>{
      for (final placement in placements) placement.slotKey: placement,
    };
    final expectedOutgoingSlots = <String>{};
    for (final pair in <(int, int)>[(2, 3), (3, 4)]) {
      final outgoing = connectorSlot(pair.$1, incoming: false);
      final incoming = connectorSlot(pair.$2, incoming: true);
      expectedOutgoingSlots.add(outgoing);
      expect(
        connectorSlots.intersection(<String>{outgoing, incoming}),
        <String>{outgoing},
        reason: 'A one-cell leg must be owned once, by its preceding turn. '
            'outgoing=$outgoing incoming=$incoming; '
            '$placementSummary',
      );
    }
    BorderPixelPos targetAnchor(String slotKey) {
      final placement = placementsBySlot[slotKey]!;
      final primitive = fixture.request.blueprintRevision!.definition.primitives
          .singleWhere((item) => item.id == placement.primitiveId);
      expect(placement.transform.quarterTurns, 0);
      return BorderPixelPos(
        x: placement.topLeftWorldPx.x + primitive.anchorPx.x,
        y: placement.topLeftWorldPx.y + primitive.anchorPx.y,
      );
    }

    final verticalArcX = targetAnchor(connectorSlot(2, incoming: false)).x;
    expect(
      verticalArcX,
      allOf(lessThan(92), greaterThanOrEqualTo(90)),
      reason: 'The vertical short-leg connector should form a shallow '
          'attached arc, not a rigid branch or an isolated low stone.',
    );
    final horizontalArcY = targetAnchor(connectorSlot(3, incoming: false)).y;
    expect(
      horizontalArcY,
      allOf(greaterThan(100), lessThanOrEqualTo(102)),
      reason: 'The horizontal short-leg connector should form a shallow '
          'attached arc, not a rigid branch or an isolated low stone.',
    );
    expect(
      placements
          .where((item) => expectedOutgoingSlots.contains(item.slotKey))
          .map((item) => rolesById[item.primitiveId]),
      everyElement(
        isIn(const <BorderPrimitiveRole>[
          BorderPrimitiveRole.structureMedium,
          BorderPrimitiveRole.filler,
        ]),
      ),
      reason: 'A connector slot must never expand into a large cliff block. '
          '$placementSummary',
    );
    expect(evidence.maximumGapPx, lessThanOrEqualTo(4));
    expect(evidence.maximumTangentOverlapPx, lessThanOrEqualTo(3));
  });

  test('keeps inner and outer corners within the overlap budget', () {
    final stroke = _stroke('corner', const <GridPos>[
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
      GridPos(x: 4, y: 2),
      GridPos(x: 4, y: 3),
      GridPos(x: 4, y: 4),
    ]);
    for (final side in BorderLineSide.values) {
      final evidence = resolveStoneChainLineBorderWithEvidence(
        StoneChainLineFixture(strokes: <BorderStroke>[stroke], lineSide: side)
            .request,
      );
      expect(evidence.result.canApply, isTrue, reason: side.name);
      final measuredOverlap = _maximumPairwiseOpaqueOverlap(
        evidence.result.materialization!.placements,
      );
      expect(measuredOverlap, lessThanOrEqualTo(3), reason: side.name);
      expect(evidence.maximumTangentOverlapPx, measuredOverlap,
          reason: side.name);
      expect(evidence.maximumTangentOverlapPx, lessThanOrEqualTo(3));
      expect(evidence.maximumCornerThicknessRatioPermille,
          lessThanOrEqualTo(1250));
    }
  });

  test('reports corner thickness against the measured straight median', () {
    final primitives = <BorderPublishedPrimitive>[
      for (final primitive in stoneChainPrimitives())
        if (primitive.role != BorderPrimitiveRole.lineCorner) primitive,
      stoneChainPrimitive(
        id: 'corner-thin',
        character: 'a',
        role: BorderPrimitiveRole.lineCorner,
        width: 6,
        height: 6,
      ),
    ];
    final fixture = StoneChainLineFixture(
      primitives: primitives,
      strokes: <BorderStroke>[
        _stroke('corner-thickness', const <GridPos>[
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 4, y: 2),
          GridPos(x: 4, y: 3),
          GridPos(x: 4, y: 4),
        ]),
      ],
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);
    final measured = _measuredCornerThicknessRatio(
      fixture.request,
      evidence.result.materialization!.placements,
    );

    expect(measured, lessThan(1000));
    expect(evidence.maximumCornerThicknessRatioPermille, measured);
  });

  test('prevents and measures perpendicular opaque overlap at corners', () {
    final primitives = <BorderPublishedPrimitive>[
      for (final primitive in stoneChainPrimitives())
        if (primitive.role != BorderPrimitiveRole.lineCorner) primitive,
      stoneChainPrimitive(
        id: 'corner-wide',
        character: 'b',
        role: BorderPrimitiveRole.lineCorner,
        width: 50,
        height: 50,
      ),
    ];
    final fixture = StoneChainLineFixture(
      primitives: primitives,
      parameters: stoneChainParameters(maxOverlapPx: 3),
      strokes: <BorderStroke>[
        _stroke('corner-overlap', const <GridPos>[
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 4, y: 2),
          GridPos(x: 4, y: 3),
          GridPos(x: 4, y: 4),
        ]),
      ],
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);
    final measured = _maximumPairwiseOpaqueOverlap(
      evidence.result.materialization!.placements,
    );

    expect(measured, lessThanOrEqualTo(3));
    expect(evidence.maximumTangentOverlapPx, measured);
  });

  test('tapers both open endpoints without a circular cap', () {
    final fixture = StoneChainLineFixture();
    final result = resolveStoneChainLineBorder(fixture.request);

    expect(result.canApply, isTrue);
    final caps = _placementsWithRole(
      fixture.request,
      result,
      BorderPrimitiveRole.lineCap,
    );
    expect(caps, hasLength(2));
    expect(caps.map((value) => value.anchorCell).toSet(), hasLength(2));
  });

  test('cap fallback always chooses the smallest primary stone', () {
    final primitives = <BorderPublishedPrimitive>[
      stoneChainPrimitive(
        id: 'large-smallest',
        character: 'f',
        width: 8,
        height: 8,
      ),
      stoneChainPrimitive(
        id: 'large-big',
        character: '0',
        width: 24,
        height: 24,
      ),
    ];
    final capSlotKeys = <String>{
      buildBorderStoneChainNodeSlotKey(
        featureId: 'stone-chain-feature',
        strokeId: 'main',
        vertex: const GridPos(x: 1, y: 4),
        passIndex: 0,
        role: BorderPrimitiveRole.lineCap,
        rank: 0,
      ),
      buildBorderStoneChainNodeSlotKey(
        featureId: 'stone-chain-feature',
        strokeId: 'main',
        vertex: const GridPos(x: 10, y: 4),
        passIndex: 0,
        role: BorderPrimitiveRole.lineCap,
        rank: 1,
      ),
    };
    for (var featureSeed = 0; featureSeed < 16; featureSeed += 1) {
      final result = resolveStoneChainLineBorder(
        StoneChainLineFixture(
          primitives: primitives,
          featureSeed: featureSeed,
        ).request,
      );
      final caps = result.materialization!.placements
          .where((placement) => capSlotKeys.contains(placement.slotKey))
          .toList(growable: false);

      expect(caps, hasLength(2), reason: 'featureSeed=$featureSeed');
      expect(
        caps.map((placement) => placement.primitiveId),
        everyElement('large-smallest'),
        reason: 'featureSeed=$featureSeed',
      );
    }
  });

  test('closes a loop without a seam collision', () {
    final fixture = StoneChainLineFixture(
      strokes: <BorderStroke>[
        BorderStroke(
          id: 'loop',
          points: const <GridPos>[
            GridPos(x: 2, y: 2),
            GridPos(x: 3, y: 2),
            GridPos(x: 4, y: 2),
            GridPos(x: 4, y: 3),
            GridPos(x: 4, y: 4),
            GridPos(x: 3, y: 4),
            GridPos(x: 2, y: 4),
            GridPos(x: 2, y: 3),
          ],
          closed: true,
        ),
      ],
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);

    expect(
      evidence.result.canApply,
      isTrue,
      reason: evidence.result.diagnostics
          .map((item) => '${item.code}:${item.parameters}')
          .join(', '),
    );
    expect(
        _placementsWithRole(
            fixture.request, evidence.result, BorderPrimitiveRole.lineCap),
        isEmpty);
    expect(evidence.maximumTangentOverlapPx, lessThanOrEqualTo(3));
  });

  test('keeps flat unrotated Selbrume stones continuous around a loop', () {
    final fixture = StoneChainLineFixture(
      strokes: <BorderStroke>[
        BorderStroke(
          id: 'flat-loop',
          points: const <GridPos>[
            GridPos(x: 3, y: 2),
            GridPos(x: 4, y: 2),
            GridPos(x: 5, y: 2),
            GridPos(x: 6, y: 2),
            GridPos(x: 6, y: 3),
            GridPos(x: 6, y: 4),
            GridPos(x: 6, y: 5),
            GridPos(x: 5, y: 5),
            GridPos(x: 4, y: 5),
            GridPos(x: 3, y: 5),
            GridPos(x: 3, y: 4),
            GridPos(x: 3, y: 3),
          ],
          closed: true,
        ),
      ],
      primitives: stoneChainSelbrumePrimitives(),
      parameters: stoneChainParameters(
        irregularityPermille: 280,
        detailDensityPermille: 170,
        variationPermille: 900,
        maxOverlapPx: 2,
        gapTolerancePx: 2,
        depthRows: 2,
        allowAutoRotation: false,
      ),
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);

    expect(
      evidence.result.canApply,
      isTrue,
      reason: evidence.result.diagnostics
          .map((item) => '${item.code}: ${item.parameters}')
          .join(', '),
    );
    expect(evidence.maximumGapPx, lessThanOrEqualTo(2));
    expect(evidence.maximumTangentOverlapPx, lessThanOrEqualTo(2));
  });

  test('bounds the final body against the wrapped first corner fallback', () {
    final fixture = StoneChainLineFixture(
      strokes: <BorderStroke>[
        stoneChainRectangularLoop(id: 'fallback-seam-loop'),
      ],
      parameters: stoneChainParameters(
        irregularityPermille: 0,
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 3,
        gapTolerancePx: 0,
        depthRows: 1,
        allowAutoRotation: false,
      ),
      primitives: <BorderPublishedPrimitive>[
        stoneChainPrimitive(
          id: 'large-corner-fallback',
          character: 'a',
          width: 16,
          height: 16,
        ),
      ],
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);

    expect(
      evidence.result.canApply,
      isTrue,
      reason: evidence.result.diagnostics
          .map((item) => '${item.code}: ${item.parameters}')
          .join(', '),
    );
    expect(evidence.maximumGapPx, 0);
  });

  test('includes the closed-loop seam in maximum opaque gap evidence', () {
    final stroke = stoneChainRectangularLoop(id: 'gap-loop');
    final baseFixture = StoneChainLineFixture(strokes: <BorderStroke>[stroke]);
    final baseline = resolveStoneChainLineBorder(baseFixture.request);
    final baselineOrdered = _placementsOrderedAroundLoop(
      baseline.materialization!.placements,
      stroke,
      baseFixture.request.tileSizePx,
    );
    final suppressedAroundSeam = <BorderResolvedPlacement>{
      ...baselineOrdered.take(2),
      ...baselineOrdered.reversed.take(2),
    };
    final evidence = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        strokes: <BorderStroke>[stroke],
        overrides: <BorderSlotOverride>[
          for (final placement in suppressedAroundSeam)
            BorderSlotOverride(
              slotKey: placement.slotKey,
              variationSalt: BorderSignedInt64.zero,
              suppressed: true,
              locked: false,
            ),
        ],
      ).request,
    );
    final ordered = _placementsOrderedAroundLoop(
      evidence.result.materialization!.placements,
      stroke,
      const GridSize(width: 32, height: 32),
    );
    final withoutSeam = _maximumOrderedOpaqueGap(
      ordered,
      includeClosingPair: false,
    );
    final withSeam = _maximumOrderedOpaqueGap(
      ordered,
      includeClosingPair: true,
    );

    expect(evidence.result.canApply, isTrue);
    expect(withSeam, greaterThan(withoutSeam));
    expect(evidence.maximumGapPx, withSeam);
  });

  test('blocks a closed seam when a required corner cannot be resolved', () {
    final fixture = StoneChainLineFixture(
      primitives: <BorderPublishedPrimitive>[
        stoneChainPrimitive(
          id: 'large-impossible',
          character: 'a',
          width: 50,
          height: 50,
        ),
        stoneChainPrimitive(
          id: 'corner-impossible',
          character: 'b',
          role: BorderPrimitiveRole.lineCorner,
          width: 50,
          height: 50,
        ),
      ],
      parameters: stoneChainParameters(maxOverlapPx: 3),
      strokes: <BorderStroke>[
        BorderStroke(
          id: 'tight-loop',
          points: const <GridPos>[
            GridPos(x: 2, y: 2),
            GridPos(x: 3, y: 2),
            GridPos(x: 3, y: 3),
            GridPos(x: 2, y: 3),
          ],
          closed: true,
        ),
      ],
    );
    final result = resolveStoneChainLineBorder(fixture.request);

    expect(result.canApply, isFalse);
    expect(
      _codes(result),
      contains('border.resolution.stone_chain_required_node_unresolved'),
    );
  });

  test('tries another cap primitive when the preferred one is off-canvas', () {
    final stroke = stoneChainHorizontalStroke(
      id: 'top-edge-alternative',
      startX: 1,
      edgeCount: 7,
      y: 0,
    );
    final fixture = StoneChainLineFixture(
      mapSize: const GridSize(width: 10, height: 4),
      strokes: <BorderStroke>[stroke],
      lineSide: BorderLineSide.inverted,
      parameters: stoneChainParameters(
        variationPermille: 0,
        depthRows: 1,
        allowAutoRotation: false,
      ),
      primitives: <BorderPublishedPrimitive>[
        stoneChainPrimitive(
          id: 'large-visible',
          character: 'a',
          width: 16,
          height: 16,
        ),
        stoneChainPrimitive(
          id: 'cap-a-outside',
          character: 'b',
          role: BorderPrimitiveRole.lineCap,
          width: 4,
          height: 4,
        ),
        stoneChainPrimitive(
          id: 'cap-b-visible',
          character: 'c',
          role: BorderPrimitiveRole.lineCap,
          width: 16,
          height: 16,
        ),
        stoneChainPrimitive(
          id: 'filler-bridge',
          character: 'd',
          role: BorderPrimitiveRole.filler,
          width: 8,
          height: 16,
        ),
      ],
    );
    final result = resolveStoneChainLineBorder(fixture.request);
    final capSlotKeys = <String>{
      for (final rank in <int>[0, 1])
        buildBorderStoneChainNodeSlotKey(
          featureId: 'stone-chain-feature',
          strokeId: stroke.id,
          vertex: rank == 0 ? stroke.points.first : stroke.points.last,
          passIndex: 0,
          role: BorderPrimitiveRole.lineCap,
          rank: rank,
        ),
    };

    expect(result.canApply, isTrue);
    expect(
      result.materialization!.placements
          .where((placement) => capSlotKeys.contains(placement.slotKey))
          .map((placement) => placement.primitiveId),
      everyElement('cap-b-visible'),
    );
  });

  test('uses the primary fallback when every cap primitive is off-canvas', () {
    final stroke = stoneChainHorizontalStroke(
      id: 'top-edge-fallback',
      startX: 1,
      edgeCount: 7,
      y: 0,
    );
    final fixture = StoneChainLineFixture(
      mapSize: const GridSize(width: 10, height: 4),
      strokes: <BorderStroke>[stroke],
      lineSide: BorderLineSide.inverted,
      parameters: stoneChainParameters(
        variationPermille: 0,
        depthRows: 1,
        allowAutoRotation: false,
      ),
      primitives: <BorderPublishedPrimitive>[
        stoneChainPrimitive(
          id: 'large-visible',
          character: 'a',
          width: 16,
          height: 16,
        ),
        stoneChainPrimitive(
          id: 'cap-outside',
          character: 'b',
          role: BorderPrimitiveRole.lineCap,
          width: 4,
          height: 4,
        ),
        stoneChainPrimitive(
          id: 'filler-bridge',
          character: 'c',
          role: BorderPrimitiveRole.filler,
          width: 8,
          height: 16,
        ),
      ],
    );
    final result = resolveStoneChainLineBorder(fixture.request);
    final capSlotKeys = <String>{
      for (final rank in <int>[0, 1])
        buildBorderStoneChainNodeSlotKey(
          featureId: 'stone-chain-feature',
          strokeId: stroke.id,
          vertex: rank == 0 ? stroke.points.first : stroke.points.last,
          passIndex: 0,
          role: BorderPrimitiveRole.lineCap,
          rank: rank,
        ),
    };

    expect(result.canApply, isTrue);
    expect(
      result.materialization!.placements
          .where((placement) => capSlotKeys.contains(placement.slotKey))
          .map((placement) => placement.primitiveId),
      everyElement('large-visible'),
    );
  });

  test('resolves an S bend without duplicated corner stones', () {
    final fixture = StoneChainLineFixture(
      strokes: <BorderStroke>[
        _stroke('s', const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 3, y: 3),
          GridPos(x: 3, y: 4),
          GridPos(x: 4, y: 4),
          GridPos(x: 5, y: 4),
          GridPos(x: 5, y: 3),
          GridPos(x: 5, y: 2),
          GridPos(x: 6, y: 2),
        ]),
      ],
    );
    final result = resolveStoneChainLineBorder(fixture.request);
    expect(
      result.canApply,
      isTrue,
      reason: result.diagnostics
          .map((item) => '${item.code}:${item.cell}:${item.parameters}')
          .join(', '),
    );
    final corners = _placementsWithRole(
      fixture.request,
      result,
      BorderPrimitiveRole.lineCorner,
    );

    expect(corners, hasLength(4));
    expect(corners.map((value) => value.slotKey).toSet(), hasLength(4));
  });

  test('keeps the published Selbrume S-bend lower face above 20 percent', () {
    final evidence = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        mapSize: const GridSize(width: 16, height: 12),
        blueprintId: 'border-blueprint-3',
        blueprintRevision: 11,
        previewSeed: 851231784,
        featureId: 'stone-chain-visual-s_inverted',
        featureSeed: 851231784,
        lineSide: BorderLineSide.inverted,
        strokes: <BorderStroke>[
          _stroke(
            's_inverted',
            <GridPos>[
              for (var x = 2; x <= 7; x += 1) GridPos(x: x, y: 2),
              for (var y = 3; y <= 7; y += 1) GridPos(x: 7, y: y),
              for (var x = 8; x <= 13; x += 1) GridPos(x: x, y: 7),
            ],
          ),
        ],
        primitives: stoneChainSelbrumePrimitives()
            .where((primitive) => primitive.role != BorderPrimitiveRole.filler)
            .toList(growable: false),
        parameters: stoneChainParameters(
          irregularityPermille: 80,
          detailDensityPermille: 300,
          variationPermille: 900,
          maxOverlapPx: 3,
          gapTolerancePx: 4,
          depthRows: 2,
          allowAutoRotation: false,
        ),
      ).request,
    );

    expect(
      evidence.result.canApply,
      isTrue,
      reason: evidence.result.diagnostics
          .map((item) => '${item.code}:${item.parameters}')
          .join(', '),
    );
    expect(
      evidence.secondaryPlacementCount * 1000 ~/ evidence.primaryPlacementCount,
      inInclusiveRange(200, 350),
      reason: 'A short, turn-rich coast still needs a readable lower face: '
          'primary=${evidence.primaryPlacementCount}, '
          'secondary=${evidence.secondaryPlacementCount}.',
    );
  });

  test('adds sparse secondary stones only at depth two', () {
    final shallow = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        parameters: stoneChainParameters(
          depthRows: 1,
          detailDensityPermille: 1000,
        ),
      ).request,
    );
    final deepFixture = StoneChainLineFixture(
      parameters: stoneChainParameters(
        depthRows: 2,
        detailDensityPermille: 1000,
      ),
    );
    final deep = resolveStoneChainLineBorderWithEvidence(deepFixture.request);

    expect(shallow.secondaryPlacementCount, 0);
    expect(deep.secondaryPlacementCount, greaterThan(0));
    expect(deep.secondaryPlacementCount, lessThan(deep.primaryPlacementCount));
    final secondaries = deep.result.materialization!.placements
        .where((placement) => placement.stableOrderKey.passIndex == 1)
        .toList(growable: false);
    final roleByPrimitiveId = <String, BorderPrimitiveRole>{
      for (final primitive
          in deepFixture.request.blueprintRevision!.definition.primitives)
        primitive.id: primitive.role,
    };
    expect(secondaries, hasLength(deep.secondaryPlacementCount));
    expect(
      secondaries.map((placement) => roleByPrimitiveId[placement.primitiveId]),
      everyElement(BorderPrimitiveRole.filler),
    );
  });

  test('honors zero and full secondary density', () {
    final zero = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        parameters: stoneChainParameters(
          depthRows: 2,
          detailDensityPermille: 0,
        ),
      ).request,
    );
    final full = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        parameters: stoneChainParameters(
          depthRows: 2,
          detailDensityPermille: 1000,
        ),
      ).request,
    );

    expect(zero.secondaryPlacementCount, 0);
    expect(
      full.secondaryPlacementCount,
      full.primaryPlacementCount - 3,
      reason: 'At full density, every interval between the 18 straight '
          'stations must receive at most one secondary candidate.',
    );
  });

  test('keeps the secondary density quota stable across feature seeds', () {
    for (final featureSeed in <int>[1, 2, 3, 4, 5, 6, 7, 8]) {
      final evidence = resolveStoneChainLineBorderWithEvidence(
        StoneChainLineFixture(
          featureSeed: featureSeed,
          parameters: stoneChainParameters(
            depthRows: 2,
            detailDensityPermille: 260,
          ),
        ).request,
      );

      expect(
        evidence.secondaryPlacementCount,
        evidence.primaryPlacementCount * 260 ~/ 1000,
        reason: 'The seed may choose which intervals are decorated, but must '
            'not change the 260 permille quota of the primary chain.',
      );
    }
  });

  test('keeps sparse fillers visually attached to the primary row', () {
    for (var featureSeed = 1; featureSeed <= 12; featureSeed += 1) {
      final fixture = StoneChainLineFixture(
        mapSize: const GridSize(width: 10, height: 22),
        strokes: <BorderStroke>[
          _stroke(
            'attached-fillers-$featureSeed',
            <GridPos>[
              for (var y = 2; y <= 19; y += 1) GridPos(x: 5, y: y),
            ],
          ),
        ],
        primitives: stoneChainSelbrumePrimitives(),
        featureSeed: featureSeed,
        parameters: stoneChainParameters(
          irregularityPermille: 280,
          detailDensityPermille: 260,
          variationPermille: 900,
          maxOverlapPx: 2,
          gapTolerancePx: 2,
          depthRows: 2,
          allowAutoRotation: false,
        ),
      );
      final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);
      expect(
        evidence.result.canApply,
        isTrue,
        reason: evidence.result.diagnostics
            .map((item) => '${item.code}:${item.parameters}')
            .join(', '),
      );
      final rolesById = <String, BorderPrimitiveRole>{
        for (final primitive
            in fixture.request.blueprintRevision!.definition.primitives)
          primitive.id: primitive.role,
      };
      final placements = evidence.result.materialization!.placements;
      final primaryRow = placements
          .where((placement) => placement.stableOrderKey.passIndex == 0)
          .toList(growable: false);
      final fillers = placements
          .where(
            (placement) =>
                placement.stableOrderKey.passIndex == 1 &&
                rolesById[placement.primitiveId] == BorderPrimitiveRole.filler,
          )
          .toList(growable: false);

      expect(fillers, isNotEmpty, reason: 'featureSeed=$featureSeed');
      for (final filler in fillers) {
        final nearestGap = primaryRow
            .map(
              (primary) => _opaqueRectGapForTest(
                filler.opaqueWorldBoundsPx,
                primary.opaqueWorldBoundsPx,
              ),
            )
            .reduce(_minInt);
        expect(
          nearestGap,
          lessThanOrEqualTo(2),
          reason: 'featureSeed=$featureSeed; filler=${filler.slotKey}; '
              'bounds=${filler.opaqueWorldBoundsPx}',
        );
      }
    }
  });

  test('builds medium fallback details as an attached lower face', () {
    final fixture = StoneChainLineFixture(
      mapSize: const GridSize(width: 24, height: 12),
      strokes: <BorderStroke>[
        stoneChainHorizontalStroke(
          id: 'medium-fallback-details',
          startX: 2,
          edgeCount: 19,
          y: 5,
        ),
      ],
      primitives: stoneChainSelbrumePrimitives()
          .where(
            (primitive) => primitive.role != BorderPrimitiveRole.filler,
          )
          .toList(growable: false),
      parameters: stoneChainParameters(
        detailDensityPermille: 1000,
        maxOverlapPx: 3,
        gapTolerancePx: 2,
        depthRows: 2,
        allowAutoRotation: false,
      ),
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);

    expect(
      evidence.result.canApply,
      isTrue,
      reason: evidence.result.diagnostics
          .map((item) => '${item.code}:${item.parameters}')
          .join(', '),
    );
    final placements = evidence.result.materialization!.placements;
    final primaries = placements
        .where((placement) => placement.stableOrderKey.passIndex == 0)
        .toList(growable: false);
    final details = placements
        .where((placement) => placement.stableOrderKey.passIndex == 1)
        .toList(growable: false);
    expect(details, isNotEmpty);
    var maximumExposedDepth = 0;
    for (final detail in details) {
      final nearestGap = primaries
          .map(
            (primary) => _opaqueRectGapForTest(
              detail.opaqueWorldBoundsPx,
              primary.opaqueWorldBoundsPx,
            ),
          )
          .reduce(_minInt);
      expect(
        nearestGap,
        0,
        reason: 'Medium fallback details must stay attached to the primary '
            'lip instead of forming a detached parallel row. '
            'detail=${detail.slotKey}; bounds=${detail.opaqueWorldBoundsPx}',
      );
      final maximumNormalOverlap = primaries
          .map(
            (primary) => _positiveMinimum(
              _minInt(
                detail.opaqueWorldBoundsPx.bottom,
                primary.opaqueWorldBoundsPx.bottom,
              ),
              _maxInt(
                detail.opaqueWorldBoundsPx.y,
                primary.opaqueWorldBoundsPx.y,
              ),
            ),
          )
          .reduce(_maxInt);
      expect(
        maximumNormalOverlap,
        greaterThanOrEqualTo(2),
        reason: 'The depth stone must interlock with the lip while remaining '
            'exposed as a distinct lower stratum. '
            'detail=${detail.slotKey}; bounds=${detail.opaqueWorldBoundsPx}',
      );
      final maximumPrimaryBottom = primaries
          .where(
            (primary) =>
                primary.opaqueWorldBoundsPx.x <
                    detail.opaqueWorldBoundsPx.right &&
                detail.opaqueWorldBoundsPx.x <
                    primary.opaqueWorldBoundsPx.right,
          )
          .map((primary) => primary.opaqueWorldBoundsPx.bottom)
          .reduce(_maxInt);
      maximumExposedDepth = _maxInt(
        maximumExposedDepth,
        detail.opaqueWorldBoundsPx.bottom - maximumPrimaryBottom,
      );
    }
    expect(
      maximumExposedDepth,
      greaterThanOrEqualTo(8),
      reason: 'Small individual stones still need to expose a lower face '
          'deep enough to read as a cliff rather than a one-pixel fringe.',
    );
  });

  test('deepens the attached lower face on long straight runs', () {
    final primitives = stoneChainSelbrumePrimitives()
        .where((primitive) => primitive.role != BorderPrimitiveRole.filler)
        .toList(growable: false);
    final parameters = stoneChainParameters(
      irregularityPermille: 0,
      detailDensityPermille: 1000,
      variationPermille: 900,
      maxOverlapPx: 3,
      gapTolerancePx: 2,
      depthRows: 2,
      allowAutoRotation: false,
    );
    StoneChainLineBorderResolutionEvidence resolve(List<GridPos> points) =>
        resolveStoneChainLineBorderWithEvidence(
          StoneChainLineFixture(
            mapSize: const GridSize(width: 24, height: 24),
            strokes: <BorderStroke>[
              _stroke('orientation-depth', points),
            ],
            primitives: primitives,
            parameters: parameters,
          ).request,
        );

    final horizontal = resolve(<GridPos>[
      for (var x = 2; x <= 21; x += 1) GridPos(x: x, y: 5),
    ]);
    final vertical = resolve(<GridPos>[
      for (var y = 2; y <= 21; y += 1) GridPos(x: 18, y: y),
    ]);

    expect(horizontal.result.canApply, isTrue);
    expect(vertical.result.canApply, isTrue);
    expect(
        horizontal.secondaryPlacementCount, vertical.secondaryPlacementCount);
    expect(horizontal.maximumTangentOverlapPx, lessThanOrEqualTo(3));
    expect(vertical.maximumTangentOverlapPx, lessThanOrEqualTo(3));
    for (final evidence in <StoneChainLineBorderResolutionEvidence>[
      horizontal,
      vertical,
    ]) {
      expect(
        evidence.result.materialization!.placements.every(
          (placement) =>
              placement.transform.quarterTurns == 0 &&
              !placement.transform.flipX,
        ),
        isTrue,
        reason: 'Deepening a straight run must not rotate or mirror the '
            'authored stones when auto-rotation is disabled.',
      );
    }

    List<int> exposedDepths(
      StoneChainLineBorderResolutionEvidence evidence, {
      required bool horizontalRun,
    }) {
      final placements = evidence.result.materialization!.placements;
      final primaries = placements
          .where((placement) => placement.stableOrderKey.passIndex == 0)
          .toList(growable: false);
      final details = placements
          .where((placement) => placement.stableOrderKey.passIndex == 1)
          .toList(growable: false);
      return <int>[
        for (final detail in details)
          if (horizontalRun)
            detail.opaqueWorldBoundsPx.bottom -
                primaries
                    .where(
                      (primary) =>
                          primary.opaqueWorldBoundsPx.x <
                              detail.opaqueWorldBoundsPx.right &&
                          detail.opaqueWorldBoundsPx.x <
                              primary.opaqueWorldBoundsPx.right,
                    )
                    .map((primary) => primary.opaqueWorldBoundsPx.bottom)
                    .reduce(_maxInt)
          else
            primaries
                    .where(
                      (primary) =>
                          primary.opaqueWorldBoundsPx.y <
                              detail.opaqueWorldBoundsPx.bottom &&
                          detail.opaqueWorldBoundsPx.y <
                              primary.opaqueWorldBoundsPx.bottom,
                    )
                    .map((primary) => primary.opaqueWorldBoundsPx.x)
                    .reduce(_minInt) -
                detail.opaqueWorldBoundsPx.x,
      ];
    }

    int median(List<int> values) {
      final ordered = values.toList(growable: false)..sort();
      return ordered[ordered.length ~/ 2];
    }

    final horizontalDepths = exposedDepths(
      horizontal,
      horizontalRun: true,
    );
    final verticalDepths = exposedDepths(
      vertical,
      horizontalRun: false,
    );
    expect(horizontalDepths, isNotEmpty);
    expect(verticalDepths, isNotEmpty);
    expect(
      median(horizontalDepths),
      greaterThanOrEqualTo(8),
      reason: 'A long horizontal coast needs a visibly deep lower stratum, '
          'not a flat shelf: $horizontalDepths',
    );
    expect(
      median(verticalDepths),
      greaterThanOrEqualTo(8),
      reason: 'A long vertical coast needs the same readable second stratum '
          'without rotating the authored stones: '
          '$verticalDepths',
    );
  });

  test('phases attached lower-face stones along the tangent deterministically',
      () {
    final primitives = stoneChainSelbrumePrimitives()
        .where((primitive) => primitive.role != BorderPrimitiveRole.filler)
        .toList(growable: false);
    final parameters = stoneChainParameters(
      irregularityPermille: 80,
      detailDensityPermille: 1000,
      variationPermille: 900,
      maxOverlapPx: 3,
      gapTolerancePx: 4,
      depthRows: 2,
      allowAutoRotation: false,
    );
    final fixture = StoneChainLineFixture(
      primitives: primitives,
      parameters: parameters,
      strokes: <BorderStroke>[
        stoneChainHorizontalStroke(
          id: 'lower-face-phase',
          startX: 1,
          edgeCount: 10,
          y: 4,
        ),
      ],
    );

    final first = resolveStoneChainLineBorder(fixture.request);
    final second = resolveStoneChainLineBorder(fixture.request);

    expect(first.canApply, isTrue);
    expect(second.materialization, first.materialization);
    final primitivesById = <String, BorderPublishedPrimitive>{
      for (final primitive in primitives) primitive.id: primitive,
    };
    BorderPixelPos targetAnchor(BorderResolvedPlacement placement) {
      final primitive = primitivesById[placement.primitiveId]!;
      expect(placement.transform.quarterTurns, 0);
      return BorderPixelPos(
        x: placement.topLeftWorldPx.x + primitive.anchorPx.x,
        y: placement.topLeftWorldPx.y + primitive.anchorPx.y,
      );
    }

    final placements = first.materialization!.placements;
    final primaryAnchors = placements
        .where((placement) =>
            placement.stableOrderKey.passIndex == 0 &&
            !const <BorderPrimitiveRole>{
              BorderPrimitiveRole.lineCap,
              BorderPrimitiveRole.lineCorner,
            }.contains(primitivesById[placement.primitiveId]!.role))
        .map(targetAnchor)
        .toList(growable: false)
      ..sort((left, right) => left.x.compareTo(right.x));
    final secondaryAnchors = placements
        .where((placement) => placement.stableOrderKey.passIndex == 1)
        .map(targetAnchor)
        .toList(growable: false);
    expect(secondaryAnchors.length, greaterThan(2));

    final tangentOffsets = <int>[];
    for (final secondary in secondaryAnchors) {
      final candidateOffsets = <int>[
        for (var index = 0; index + 1 < primaryAnchors.length; index += 1)
          secondary.x -
              (primaryAnchors[index].x + primaryAnchors[index + 1].x) ~/ 2,
      ]..sort((left, right) => left.abs().compareTo(right.abs()));
      tangentOffsets.add(candidateOffsets.first);
    }
    expect(tangentOffsets, everyElement(inInclusiveRange(-5, 5)));
    expect(
      tangentOffsets.toSet().length,
      greaterThanOrEqualTo(2),
      reason: 'The lower face must not repeat the exact midpoint cadence: '
          '$tangentOffsets',
    );
    expect(tangentOffsets, contains(isNot(0)));
    expect(
      tangentOffsets.map((offset) => offset.abs()),
      contains(greaterThan(2)),
      reason: 'A two-pixel phase is not visible enough to break the dark '
          'lower-face cadence at editor zoom levels: $tangentOffsets',
    );
  });

  test('scatters sparse fillers into the contour instead of one parallel lane',
      () {
    final fixture = StoneChainLineFixture(
      mapSize: const GridSize(width: 12, height: 50),
      strokes: <BorderStroke>[
        _stroke(
          'organic-filler-depth',
          <GridPos>[
            for (var y = 2; y <= 47; y += 1) GridPos(x: 5, y: y),
          ],
        ),
      ],
      primitives: stoneChainSelbrumePrimitives(),
      featureSeed: 71,
      parameters: stoneChainParameters(
        irregularityPermille: 280,
        detailDensityPermille: 260,
        variationPermille: 900,
        maxOverlapPx: 2,
        gapTolerancePx: 2,
        depthRows: 2,
        allowAutoRotation: false,
      ),
    );
    final first = resolveStoneChainLineBorderWithEvidence(fixture.request);
    final repeated = resolveStoneChainLineBorderWithEvidence(fixture.request);
    expect(first.result.canApply, isTrue);
    expect(first.result.materialization, repeated.result.materialization);

    final primitivesById = <String, BorderPublishedPrimitive>{
      for (final primitive
          in fixture.request.blueprintRevision!.definition.primitives)
        primitive.id: primitive,
    };
    final fillerAnchorXs = first.result.materialization!.placements
        .where(
          (placement) =>
              placement.stableOrderKey.passIndex == 1 &&
              primitivesById[placement.primitiveId]!.role ==
                  BorderPrimitiveRole.filler,
        )
        .map(
          (placement) =>
              placement.topLeftWorldPx.x +
              primitivesById[placement.primitiveId]!.anchorPx.x,
        )
        .toList(growable: false);
    expect(fillerAnchorXs, hasLength(greaterThanOrEqualTo(8)));
    final anchorRange =
        fillerAnchorXs.reduce(_maxInt) - fillerAnchorXs.reduce(_minInt);
    expect(
      anchorRange,
      greaterThanOrEqualTo(5),
      reason: 'Sparse stones must tuck into the primary silhouette at several '
          'depths instead of drawing a detached parallel dotted row. '
          'anchors=$fillerAnchorXs',
    );
  });

  test('limits overlap inside each depth row while keeping rows attached', () {
    final primitives = stoneChainPrimitives()
        .where((primitive) => primitive.role != BorderPrimitiveRole.filler)
        .toList(growable: false);
    final evidence = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        primitives: primitives,
        parameters: stoneChainParameters(
          depthRows: 2,
          detailDensityPermille: 1000,
          maxOverlapPx: 3,
        ),
      ).request,
    );
    final placements = evidence.result.materialization!.placements;
    final primaryRow = placements
        .where((placement) => placement.stableOrderKey.passIndex == 0)
        .toList(growable: false);
    final detailRow = placements
        .where((placement) => placement.stableOrderKey.passIndex == 1)
        .toList(growable: false);
    final primaryOverlap = _maximumPairwiseOpaqueOverlap(primaryRow);
    final detailOverlap = _maximumPairwiseOpaqueOverlap(detailRow);

    expect(primaryOverlap, lessThanOrEqualTo(3));
    expect(detailOverlap, lessThanOrEqualTo(3));
    expect(
      evidence.maximumTangentOverlapPx,
      _maxInt(primaryOverlap, detailOverlap),
    );
    final minimumCrossRowGap = detailRow
        .expand(
          (detail) => primaryRow.map(
            (primary) => _opaqueRectGapForTest(
              detail.opaqueWorldBoundsPx,
              primary.opaqueWorldBoundsPx,
            ),
          ),
        )
        .reduce(_minInt);
    expect(
      minimumCrossRowGap,
      lessThanOrEqualTo(4),
      reason: 'A deeper second stratum must still stay attached to the '
          'primary lip.',
    );
  });

  test('moves placements to the inverted line side without flipping pixels',
      () {
    final primary = resolveStoneChainLineBorder(
      StoneChainLineFixture(lineSide: BorderLineSide.primary).request,
    );
    final inverted = resolveStoneChainLineBorder(
      StoneChainLineFixture(lineSide: BorderLineSide.inverted).request,
    );

    expect(primary.canApply, isTrue);
    expect(inverted.canApply, isTrue);
    expect(
      primary.materialization!.placements.map((value) => value.slotKey),
      inverted.materialization!.placements.map((value) => value.slotKey),
    );
    expect(
      primary.materialization!.placements
          .map((value) => value.topLeftWorldPx)
          .toList(),
      isNot(inverted.materialization!.placements
          .map((value) => value.topLeftWorldPx)
          .toList()),
    );
    expect(
        inverted.materialization!.placements,
        everyElement(predicate<BorderResolvedPlacement>(
            (value) => !value.transform.flipX)));
  });

  test('resolves the two-stroke Selbrume coast on either line side', () {
    BorderResolutionRequest request(BorderLineSide lineSide) =>
        StoneChainLineFixture(
          mapSize: const GridSize(width: 55, height: 55),
          strokes: stoneChainSelbrumeCoastStrokes(),
          primitives: stoneChainSelbrumePrimitives(),
          lineSide: lineSide,
          parameters: stoneChainParameters(
            irregularityPermille: 280,
            detailDensityPermille: 260,
            variationPermille: 900,
            maxOverlapPx: 2,
            gapTolerancePx: 2,
            depthRows: 2,
            allowAutoRotation: false,
          ),
        ).request;

    for (final lineSide in BorderLineSide.values) {
      final first = resolveStoneChainLineBorderWithEvidence(request(lineSide));
      final second = resolveStoneChainLineBorderWithEvidence(request(lineSide));

      expect(first, second, reason: '$lineSide must remain deterministic');
      expect(
        first.result.canApply,
        isTrue,
        reason: first.result.diagnostics
            .map((item) => '${item.code}: ${item.parameters}')
            .join(', '),
      );
      expect(first.maximumGapPx, lessThanOrEqualTo(2));
      expect(first.maximumTangentOverlapPx, lessThanOrEqualTo(2));
      expect(first.primaryPlacementCount, greaterThan(0));
      expect(first.result.materialization!.placements, isNotEmpty);
    }
  });

  group('two-tier stone-chain RED contract', () {
    test(
        'rejects incomplete cardinal two-tier catalogues instead of using legacy',
        () {
      final complete = twoTierStoneChainPublishedPrimitives();
      final incompleteCatalogues = <List<BorderPublishedPrimitive>>[
        complete
            .where(
              (primitive) =>
                  primitive.role != BorderPrimitiveRole.structureMedium,
            )
            .toList(growable: false),
        <BorderPublishedPrimitive>[
          for (var index = 0; index < complete.length; index += 1)
            index == 0
                ? _copyTwoTierPrimitive(
                    complete[index],
                    authoredOrientation: BorderPrimitiveOrientation.legacyAxis,
                  )
                : complete[index],
        ],
      ];

      for (final primitives in incompleteCatalogues) {
        final fixture = TwoTierStoneChainFixture(
          publishedPrimitives: primitives,
        );

        final result = resolveStoneChainLineBorder(fixture.request);

        expect(result.canApply, isFalse);
        expect(result.materialization, isNull);
        expect(
          result.diagnostics.map((diagnostic) => diagnostic.code),
          contains(
            'border.resolution.stone_chain_two_tier_catalog_incomplete',
          ),
        );
      }
    });

    test('rejects cardinal depth-one catalogues instead of misusing legacy',
        () {
      final fixture = TwoTierStoneChainFixture(depthRows: 1);

      final result = resolveStoneChainLineBorder(fixture.request);

      expect(result.canApply, isFalse);
      expect(result.materialization, isNull);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          'border.resolution.stone_chain_cardinal_depth_one_unsupported',
        ),
      );
    });

    test('rejects a positive cardinal filler at depth one', () {
      final legacyStructural = <BorderPublishedPrimitive>[
        for (final primitive in twoTierStoneChainPublishedPrimitives())
          _copyTwoTierPrimitive(
            primitive,
            authoredOrientation: BorderPrimitiveOrientation.legacyAxis,
          ),
      ];
      final cardinalFiller = _twoTierFillerPrimitives(weight: 1).first;
      final fixture = TwoTierStoneChainFixture(
        depthRows: 1,
        publishedPrimitives: <BorderPublishedPrimitive>[
          ...legacyStructural,
          cardinalFiller,
        ],
      );

      final result = resolveStoneChainLineBorder(fixture.request);

      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          'border.resolution.stone_chain_cardinal_depth_one_unsupported',
        ),
      );
    });

    test(
      'samples six variants within the 95 candidate bound deterministically',
      () {
        final primitives = twoTierStoneChainPublishedPrimitives(
          variantsPerOrientation: 6,
        );
        final topologyStroke = _twoTierStroke(
          'candidate-budget-l',
          <GridPos>[
            for (var x = 4; x <= 8; x += 1) GridPos(x: x, y: 6),
            for (var y = 7; y <= 10; y += 1) GridPos(x: 8, y: y),
          ],
        );
        for (final profile in <({bool rotation, int candidateCount})>[
          (rotation: false, candidateCount: 68),
          (rotation: true, candidateCount: 85),
        ]) {
          final fixture = TwoTierStoneChainFixture(
            allowAutoRotation: profile.rotation,
            publishedPrimitives: primitives,
          );
          final request = _twoTierTopologyRequest(
            topologyStroke,
            fixture: fixture,
          );
          final stopwatch = Stopwatch()..start();
          final first = resolveStoneChainLineBorder(request);
          final repeated = resolveStoneChainLineBorder(request);
          stopwatch.stop();

          expect(
            first.canApply,
            isTrue,
            reason: 'rotation=${profile.rotation}, '
                'candidates=${profile.candidateCount}: '
                '${_diagnosticSummary(first)}',
          );
          expect(repeated, first, reason: 'rotation=${profile.rotation}');
          expect(
            first.diagnostics.map((item) => item.code),
            isNot(contains(
              'border.resolution.stone_chain_planner_candidate_budget_exceeded',
            )),
          );
          expect(stopwatch.elapsed, lessThan(const Duration(seconds: 8)));
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('bounds seven rotated variants to four native planner candidates', () {
      final fixture = TwoTierStoneChainFixture(
        allowAutoRotation: true,
        publishedPrimitives: twoTierStoneChainPublishedPrimitives(
          variantsPerOrientation: 7,
        ),
      );
      final topologyStroke = _twoTierStroke(
        'candidate-budget-overflow-l',
        <GridPos>[
          for (var x = 4; x <= 8; x += 1) GridPos(x: x, y: 6),
          for (var y = 7; y <= 10; y += 1) GridPos(x: 8, y: y),
        ],
      );
      final request = _twoTierTopologyRequest(
        topologyStroke,
        fixture: fixture,
      );
      final stopwatch = Stopwatch()..start();
      final topology = resolveStoneChainLineBorder(request);
      final repeated = resolveStoneChainLineBorder(request);
      stopwatch.stop();

      expect(topology.canApply, isTrue, reason: _diagnosticSummary(topology));
      expect(repeated, topology);
      expect(
        topology.diagnostics.map((item) => item.code),
        isNot(
          contains(
            'border.resolution.stone_chain_planner_candidate_budget_exceeded',
          ),
        ),
      );
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 12)));
    });

    test('applies the overlap preflight to straight and topology rows', () {
      final fixture = TwoTierStoneChainFixture();
      final sourceParameters = fixture.parameters;
      final oversizedOverlap = BorderGenerationParams(
        irregularityPermille: sourceParameters.irregularityPermille,
        detailDensityPermille: sourceParameters.detailDensityPermille,
        variationPermille: sourceParameters.variationPermille,
        maxOverlapPx: 10,
        gapTolerancePx: sourceParameters.gapTolerancePx,
        depthRows: sourceParameters.depthRows,
        allowAutoRotation: sourceParameters.allowAutoRotation,
      );
      final topologyStroke = _twoTierStroke(
        'overlap-budget-l',
        <GridPos>[
          for (var x = 4; x <= 14; x += 1) GridPos(x: x, y: 6),
          for (var y = 7; y <= 14; y += 1) GridPos(x: 14, y: y),
        ],
      );
      final straight = resolveStoneChainLineBorder(
        _twoTierRequestWithParameters(
          fixture.request,
          oversizedOverlap,
        ),
      );
      final topology = resolveStoneChainLineBorder(
        _twoTierRequestWithParameters(
          _twoTierTopologyRequest(topologyStroke, fixture: fixture),
          oversizedOverlap,
        ),
      );

      for (final result in <BorderResolutionResult>[straight, topology]) {
        expect(result.canApply, isFalse);
        expect(result.materialization, isNull);
        final diagnostic = result.diagnostics.singleWhere(
          (item) =>
              item.code ==
              'border.resolution.stone_chain_planner_budget_exceeded',
        );
        expect(diagnostic.parameters['observedMaximumOverlapPx'], 10);
        expect(diagnostic.parameters['expectedMaximumOverlapPx'], 8);
      }
    });

    test('depthRows 2 builds a complete face when detail density is zero', () {
      for (final normal in BorderCardinalDirection.values) {
        final outcome = _resolveTwoTier(
          normal: normal,
          detailDensityPermille: 0,
        );
        final lips = lipPlacements(outcome.fixture.request, outcome.result);
        final faces = facePlacements(outcome.fixture.request, outcome.result);

        expect(
          faces,
          isNotEmpty,
          reason: '$normal must build a structural face at zero detail density',
        );
        expect(
          faces.length,
          greaterThanOrEqualTo(lips.length - 1),
          reason: '$normal must cover the complete lip rather than decorate it',
        );
      }
    });

    test('avoids visible short cadence reuse in long two-tier rows', () {
      for (final normal in BorderCardinalDirection.values) {
        final fixture = TwoTierStoneChainFixture(
          normal: normal,
          featureSeed: 19072026,
          publishedPrimitives: twoTierStoneChainPublishedPrimitives(
            variantsPerOrientation: 4,
          ),
        );
        final result = resolveStoneChainLineBorder(fixture.request);

        expect(
          result.canApply,
          isTrue,
          reason: '$normal: ${_diagnosticSummary(result)}',
        );
        for (final row in <List<BorderResolvedPlacement>>[
          lipPlacements(fixture.request, result),
          facePlacements(fixture.request, result),
        ]) {
          final tangent = switch (normal) {
            BorderCardinalDirection.north => StoneChainAxis(dx: -1, dy: 0),
            BorderCardinalDirection.east => StoneChainAxis(dx: 0, dy: -1),
            BorderCardinalDirection.south => StoneChainAxis(dx: 1, dy: 0),
            BorderCardinalDirection.west => StoneChainAxis(dx: 0, dy: 1),
          };
          final orderedRow = _twoTierOrderedAlong(row, tangent);
          final primitiveIds = orderedRow
              .map((placement) => placement.primitiveId)
              .toList(growable: false);
          expect(primitiveIds.length, greaterThanOrEqualTo(6));
          expect(primitiveIds.toSet().length, greaterThanOrEqualTo(3));
          _expectNoShortRepeatingPrimitiveBlocks(
            primitiveIds,
            reasonPrefix: '$normal',
            debugLabels: <String>[
              for (final placement in orderedRow)
                '${placement.primitiveId}@${placement.topLeftWorldPx}'
                    '@${placement.slotKey}',
            ],
          );
        }
      }
    });

    test(
        'uses irregularity to break planned two-tier spacing without opening gaps',
        () {
      final stroke = _twoTierStroke(
        'two-tier-planned-irregularity',
        <GridPos>[
          for (var x = 4; x <= 16; x += 1) GridPos(x: x, y: 6),
          for (var y = 7; y <= 22; y += 1) GridPos(x: 16, y: y),
        ],
      );
      StoneChainLineBorderResolutionEvidence resolve(int irregularity) =>
          resolveStoneChainLineBorderWithEvidence(
            _twoTierTopologyRequest(
              stroke,
              fixture: TwoTierStoneChainFixture(
                featureSeed: 19072026,
                irregularityPermille: irregularity,
                publishedPrimitives: twoTierStoneChainPublishedPrimitives(
                  variantsPerOrientation: 6,
                ),
              ),
            ),
          );

      final regular = resolve(0);
      final irregular = resolve(280);
      final repeated = resolve(280);
      expect(regular.result.canApply, isTrue);
      expect(
        irregular.result.canApply,
        isTrue,
        reason: _diagnosticSummary(irregular.result),
      );
      expect(irregular.result.materialization, repeated.result.materialization);

      final regularBySlot = <String, BorderResolvedPlacement>{
        for (final placement in regular.result.materialization!.placements)
          placement.slotKey: placement,
      };
      final irregularBySlot = <String, BorderResolvedPlacement>{
        for (final placement in irregular.result.materialization!.placements)
          placement.slotKey: placement,
      };
      expect(irregularBySlot.keys.toSet(), regularBySlot.keys.toSet());
      final stablePrimitiveTangentDeltas = <int>[
        for (final entry in regularBySlot.entries)
          if (irregularBySlot[entry.key] case final shifted?)
            if (shifted.primitiveId == entry.value.primitiveId)
              shifted.primitiveId.contains('-east-') ||
                      shifted.primitiveId.contains('-west-')
                  ? shifted.topLeftWorldPx.y - entry.value.topLeftWorldPx.y
                  : shifted.topLeftWorldPx.x - entry.value.topLeftWorldPx.x,
      ];
      expect(stablePrimitiveTangentDeltas, isNotEmpty);
      expect(
        stablePrimitiveTangentDeltas,
        contains(isNot(0)),
        reason: 'the planned row must express the authored organic spacing',
      );
      expect(
        stablePrimitiveTangentDeltas,
        everyElement(inInclusiveRange(-16, 16)),
        reason: 'both plans remain inside the authored eight-pixel fitting '
            'budget even when their valid global branches differ',
      );
      expect(irregular.maximumGapPx, 0);
    });

    test(
        'reports the rank-one midpoint lip backfill when real-mask closure is impossible',
        () {
      final primitives = <BorderPublishedPrimitive>[
        for (final primitive in twoTierStoneChainPublishedPrimitives())
          primitive.role == BorderPrimitiveRole.structureLarge
              ? _withNarrowTwoTierTangentMask(primitive, tangentSpanPx: 1)
              : primitive,
      ];
      final fixture = TwoTierStoneChainFixture(
        normal: BorderCardinalDirection.south,
        publishedPrimitives: primitives,
      );

      final result = resolveStoneChainLineBorder(fixture.request);
      final repeated = resolveStoneChainLineBorder(fixture.request);

      expect(result.canApply, isFalse);
      expect(repeated, result);
      expect(result.materialization, isNull);
      final lipGap = result.diagnostics.singleWhere(
        (diagnostic) =>
            diagnostic.code == 'border.resolution.stone_chain_lip_gap',
      );
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains(
          'border.resolution.stone_chain_orientation_unavailable',
        )),
      );
      final jointStart =
          lipGap.parameters['jointStartCanonicalDistancePx']! as int;
      final jointEnd = lipGap.parameters['jointEndCanonicalDistancePx']! as int;
      final midpoint = lipGap.parameters['midpointCanonicalDistancePx']! as int;
      expect(midpoint, (jointStart + jointEnd) ~/ 2);
      expect(midpoint, 4);
      expect(
        _twoTierRankOneDistancesForSlotKeys(
          fixture.request,
          <String>{lipGap.parameters['slotKey']! as String},
        ),
        <int>[midpoint],
      );
      expect(lipGap.parameters['observedGapPx'], 0);
      expect(lipGap.parameters['observedMinimumOverlapPx'], 0);
      expect(lipGap.parameters['observedMaximumOverlapPx'], 0);
      expect(lipGap.parameters['expectedMinimumOverlapPx'], 2);
      expect(lipGap.parameters['expectedMaximumOverlapPx'], 8);
      expect(lipGap.parameters['backfillBudget'], 320);
    });

    test('materializes a rank-one midpoint backfill that closes a real gap',
        () {
      final fixture = TwoTierStoneChainFixture(
        normal: BorderCardinalDirection.south,
        featureSeed: 2,
        publishedPrimitives: _twoTierSuccessfulBackfillPrimitives(),
      );
      final request = _twoTierShortStraightRequest(fixture);
      final reversedRequest = _twoTierShortStraightRequest(
        fixture,
        reverseAuthoredTraversal: true,
      );
      final result = resolveStoneChainLineBorder(request);
      final repeated = resolveStoneChainLineBorder(request);
      final reversed = resolveStoneChainLineBorder(reversedRequest);
      expect(
        result.canApply,
        isTrue,
        reason: result.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join(', '),
      );
      expect(repeated, result);
      expect(
        reversed.canApply,
        isTrue,
        reason: reversed.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join(', '),
      );
      final rankOneDistances = _twoTierRankOneDistancesForSlotKeys(
        request,
        result.materialization!.placements
            .map((placement) => placement.slotKey)
            .toSet(),
      );
      expect(_twoTierSlotKeys(reversed), _twoTierSlotKeys(result));
      expect(
        _twoTierRankOneDistancesForSlotKeys(
          reversedRequest,
          reversed.materialization!.placements
              .map((placement) => placement.slotKey)
              .toSet(),
        ),
        rankOneDistances,
      );
      expect(
        rankOneDistances,
        <int>[
          13,
          14,
          20,
          21,
          22,
          28,
          29,
          30,
          36,
          37,
          38,
          44,
          45,
          46,
          52,
          53,
          54,
        ],
      );
      assertGaplessRow(
        request: request,
        placements: lipPlacements(request, result),
        tangent: _twoTierTangentAxis(BorderCardinalDirection.south),
        normal: _twoTierNormalAxis(BorderCardinalDirection.south),
        label: 'successful rank-one lip backfill',
      );
    });

    test('uses real masks after bounds broad phase for the overlap budget', () {
      final baseline = _resolveTwoTier(
        normal: BorderCardinalDirection.south,
      );
      final fixture = TwoTierStoneChainFixture(
        normal: BorderCardinalDirection.south,
        publishedPrimitives: _twoTierBroadBoundsNarrowMaskPrimitives(),
      );

      final result = resolveStoneChainLineBorder(fixture.request);

      expect(
        result.canApply,
        isTrue,
        reason: result.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join(', '),
      );
      expect(
        lipPlacements(fixture.request, result)
            .map((placement) => placement.slotKey)
            .toList(growable: false),
        lipPlacements(baseline.fixture.request, baseline.result)
            .map((placement) => placement.slotKey)
            .toList(growable: false),
        reason: 'True two-pixel mask contact must not create an unnecessary '
            'rank-one backfill merely because broad bounds overlap by ten.',
      );
    });

    test('preflights oversized two-tier station rows without throwing', () {
      final request = _twoTierLongStraightRequest(edgeCount: 1800);
      BorderResolutionResult? result;

      expect(
        () => result = resolveStoneChainLineBorder(request),
        returnsNormally,
      );

      expect(result!.canApply, isFalse);
      expect(result!.materialization, isNull);
      final diagnostic = result!.diagnostics.singleWhere(
        (item) => item.code == 'border.resolution.stone_chain_lip_gap',
      );
      expect(diagnostic.parameters['observedStationCount'], greaterThan(4096));
      expect(diagnostic.parameters['expectedMaximumStationCount'], 4096);
      expect(diagnostic.parameters['preflight'], isTrue);
    });

    test('preflights oversized two-tier opaque-pixel rows without throwing',
        () {
      final request = _twoTierLongStraightRequest(
        edgeCount: 225,
        publishedPrimitives: _twoTierFullMaskLipPrimitives(),
      );
      BorderResolutionResult? result;

      expect(
        () => result = resolveStoneChainLineBorder(request),
        returnsNormally,
      );

      expect(result!.canApply, isFalse);
      expect(result!.materialization, isNull);
      final diagnostic = result!.diagnostics.singleWhere(
        (item) => item.code == 'border.resolution.stone_chain_lip_gap',
      );
      expect(
        diagnostic.parameters['observedMinimumOpaquePixels'],
        greaterThan(262144),
      );
      expect(diagnostic.parameters['expectedMaximumOpaquePixels'], 262144);
      expect(diagnostic.parameters['preflight'], isTrue);
    });

    test('materializes positive fillers without changing either structural row',
        () {
      final structural = twoTierStoneChainPublishedPrimitives();
      final fillers = _twoTierFillerPrimitives(weight: 1);
      final baseline = _resolveTwoTier(
        normal: BorderCardinalDirection.south,
        publishedPrimitives: structural,
      );
      final decorated = _resolveTwoTier(
        normal: BorderCardinalDirection.south,
        publishedPrimitives: <BorderPublishedPrimitive>[
          ...structural,
          ...fillers,
        ],
      );

      List<BorderResolvedPlacement> structuralPlacements(
        ({
          TwoTierStoneChainFixture fixture,
          BorderResolutionResult result,
        }) outcome,
      ) =>
          outcome.result.materialization!.placements.where((placement) {
            final role = outcome.fixture.primitives
                .singleWhere(
                  (primitive) => primitive.id == placement.primitiveId,
                )
                .role;
            return role == BorderPrimitiveRole.structureLarge ||
                role == BorderPrimitiveRole.structureMedium;
          }).toList(growable: false);

      expect(
        structuralPlacements(decorated),
        structuralPlacements(baseline),
      );
      final fillerIds = fillers.map((primitive) => primitive.id).toSet();
      expect(
        decorated.result.materialization!.placements.where(
          (placement) => fillerIds.contains(placement.primitiveId),
        ),
        isNotEmpty,
      );

      expect(
        baseline.result.materialization!.placements.where(
          (placement) =>
              baseline.fixture.primitives
                  .singleWhere(
                    (primitive) => primitive.id == placement.primitiveId,
                  )
                  .role ==
              BorderPrimitiveRole.filler,
        ),
        isEmpty,
      );
    });

    test('keeps lip and face independently gapless on all four normals', () {
      for (final normal in BorderCardinalDirection.values) {
        final outcome = _resolveTwoTier(normal: normal);
        assertGaplessRow(
          request: outcome.fixture.request,
          placements: lipPlacements(outcome.fixture.request, outcome.result),
          tangent: _twoTierTangentAxis(normal),
          normal: _twoTierNormalAxis(normal),
          label: '$normal lip',
        );
        assertGaplessRow(
          request: outcome.fixture.request,
          placements: facePlacements(outcome.fixture.request, outcome.result),
          tangent: _twoTierTangentAxis(normal),
          normal: _twoTierNormalAxis(normal),
          label: '$normal face',
        );
      }
    });

    test('keeps two to eight pixels of same-row interlock', () {
      for (final normal in BorderCardinalDirection.values) {
        final outcome = _resolveTwoTier(normal: normal);
        for (final row
            in <({String label, List<BorderResolvedPlacement> items})>[
          (
            label: '$normal lip',
            items: lipPlacements(outcome.fixture.request, outcome.result),
          ),
          (
            label: '$normal face',
            items: facePlacements(outcome.fixture.request, outcome.result),
          ),
        ]) {
          final continuity = _twoTierRowContinuity(
            request: outcome.fixture.request,
            placements: row.items,
            tangent: _twoTierTangentAxis(normal),
            normal: _twoTierNormalAxis(normal),
          );
          expect(
            continuity.minimumOverlapPx,
            greaterThanOrEqualTo(2),
            reason: row.label,
          );
          expect(
            continuity.maximumOverlapPx,
            lessThanOrEqualTo(8),
            reason: row.label,
          );
        }
      }
    });

    test('staggered face joints do not align with lip joints', () {
      for (final normal in BorderCardinalDirection.values) {
        final outcome = _resolveTwoTier(normal: normal);
        final tangent = _twoTierTangentAxis(normal);
        final lipJoints = _twoTierJointCoordinates(
          lipPlacements(outcome.fixture.request, outcome.result),
          tangent,
        );
        final faceJoints = _twoTierJointCoordinates(
          facePlacements(outcome.fixture.request, outcome.result),
          tangent,
        );

        expect(lipJoints, isNotEmpty, reason: '$normal lip joints');
        expect(faceJoints, isNotEmpty, reason: '$normal face joints');
        expect(
          faceJoints.every(
            (faceJoint) => lipJoints.every(
              (lipJoint) => (faceJoint - lipJoint).abs() > 2,
            ),
          ),
          isTrue,
          reason: '$normal face joints must remain staggered from the lip '
              'by more than the two-pixel publication tolerance',
        );
      }
    });

    test('four variants avoid long repeated lip runs on a long straight', () {
      final primitives = twoTierStoneChainPublishedPrimitives(
        variantsPerOrientation: 4,
      );
      final fixture = TwoTierStoneChainFixture(
        normal: BorderCardinalDirection.south,
        publishedPrimitives: primitives,
      );

      final first = resolveStoneChainLineBorder(fixture.request);
      final repeated = resolveStoneChainLineBorder(fixture.request);

      expect(first.canApply, isTrue, reason: _diagnosticSummary(first));
      expect(repeated, first);
      final lips = lipPlacements(fixture.request, first);
      expect(
        lips.map((placement) => placement.primitiveId).toSet(),
        hasLength(greaterThanOrEqualTo(3)),
      );
      expect(_maximumPrimitiveRunLength(lips), lessThanOrEqualTo(2));
      assertGaplessRow(
        request: fixture.request,
        placements: lips,
        tangent: _twoTierTangentAxis(BorderCardinalDirection.south),
        normal: _twoTierNormalAxis(BorderCardinalDirection.south),
        label: 'four-variant lip',
      );
    });

    test('every face stone interlocks with a lip stone', () {
      for (final normal in BorderCardinalDirection.values) {
        final outcome = _resolveTwoTier(normal: normal);
        assertCrossRowInterlock(
          request: outcome.fixture.request,
          lips: lipPlacements(outcome.fixture.request, outcome.result),
          faces: facePlacements(outcome.fixture.request, outcome.result),
          tangent: _twoTierTangentAxis(normal),
          normal: _twoTierNormalAxis(normal),
          label: '$normal',
        );
      }
    });

    test('face remains at least twelve pixels visible beyond the lip', () {
      for (final normal in BorderCardinalDirection.values) {
        final outcome = _resolveTwoTier(normal: normal);
        final lips = lipPlacements(outcome.fixture.request, outcome.result);
        final faces = facePlacements(outcome.fixture.request, outcome.result);
        final tangent = _twoTierTangentAxis(normal);
        final normalAxis = _twoTierNormalAxis(normal);
        final primitiveById = _twoTierPrimitiveById(outcome.fixture.request);

        expect(faces, isNotEmpty, reason: '$normal face');
        for (final face in faces) {
          final faceMask = _twoTierPlacedMask(face, primitiveById);
          final attachedLips = lips.where((lip) {
            final contact = measureStoneChainContact(
              first: faceMask,
              second: _twoTierPlacedMask(lip, primitiveById),
              tangent: tangent,
              normal: normalAxis,
            );
            return contact.opaqueIntersectionPixels > 0;
          }).toList(growable: false);
          expect(attachedLips, isNotEmpty, reason: '$normal ${face.slotKey}');
          final lipFront = attachedLips
              .map((lip) => _twoTierMaximumProjection(lip, normalAxis))
              .reduce(_maxInt);
          expect(
            _twoTierMaximumProjection(face, normalAxis) - lipFront,
            greaterThanOrEqualTo(12),
            reason: '$normal ${face.slotKey}',
          );
        }
      }
    });

    test('renders every face placement before every lip placement', () {
      for (final normal in BorderCardinalDirection.values) {
        final outcome = _resolveTwoTier(normal: normal);
        assertFaceBeforeLip(
          request: outcome.fixture.request,
          placements: outcome.result.materialization!.placements,
          label: '$normal',
        );
      }
    });

    test('rotation off selects only the exact authored orientation', () {
      for (final normal in BorderCardinalDirection.values) {
        final outcome = _resolveTwoTier(
          normal: normal,
          allowAutoRotation: false,
        );
        final expected = twoTierOrientationForNormal(normal);
        final primitiveById = _twoTierPrimitiveById(outcome.fixture.request);

        for (final placement in outcome.result.materialization!.placements) {
          expect(
            primitiveById[placement.primitiveId]!.authoredOrientation,
            expected,
            reason: '$normal ${placement.slotKey}',
          );
          expect(
            placement.transform.quarterTurns,
            0,
            reason: '$normal ${placement.slotKey}',
          );
        }
      }
    });

    test('rotation on maps source orientation with one allowed transform', () {
      final northAuthored = twoTierStoneChainPublishedPrimitives()
          .where(
            (primitive) =>
                primitive.authoredOrientation ==
                BorderPrimitiveOrientation.north,
          )
          .toList(growable: false);
      for (final normal in BorderCardinalDirection.values) {
        final outcome = _resolveTwoTier(
          normal: normal,
          allowAutoRotation: true,
          publishedPrimitives: northAuthored,
        );
        final expected = twoTierOrientationForNormal(normal);
        final primitiveById = _twoTierPrimitiveById(outcome.fixture.request);

        for (final placement in outcome.result.materialization!.placements) {
          final primitive = primitiveById[placement.primitiveId]!;
          expect(
            primitive.transforms.allowedQuarterTurns,
            contains(placement.transform.quarterTurns),
          );
          expect(
            _rotateTwoTierOrientation(
              primitive.authoredOrientation,
              placement.transform.quarterTurns,
            ),
            expected,
            reason: '$normal ${placement.slotKey}',
          );
        }
      }
    });

    test('rotation toggle preserves all slot identities', () {
      for (final normal in BorderCardinalDirection.values) {
        final rotationOff = _resolveTwoTier(
          normal: normal,
          allowAutoRotation: false,
        );
        final rotationOn = _resolveTwoTier(
          normal: normal,
          allowAutoRotation: true,
        );

        expect(
          _twoTierSlotKeys(rotationOn.result),
          _twoTierSlotKeys(rotationOff.result),
          reason: '$normal',
        );
      }
    });

    test('inverted side preserves slots and selects the opposite orientation',
        () {
      for (final normal in BorderCardinalDirection.values) {
        final primary = _resolveTwoTier(
          normal: normal,
          lineSide: BorderLineSide.primary,
        );
        final inverted = _resolveTwoTier(
          normal: normal,
          lineSide: BorderLineSide.inverted,
        );
        final expected = twoTierOrientationForNormal(
          oppositeTwoTierNormal(normal),
        );
        final primitiveById = _twoTierPrimitiveById(inverted.fixture.request);

        expect(
          _twoTierSlotKeys(inverted.result),
          _twoTierSlotKeys(primary.result),
          reason: '$normal slots',
        );
        for (final placement in inverted.result.materialization!.placements) {
          expect(
            primitiveById[placement.primitiveId]!.authoredOrientation,
            expected,
            reason: '$normal ${placement.slotKey}',
          );
        }
      }
    });

    test('depthRows 1 preserves the historical placement golden', () {
      final result = resolveStoneChainLineBorder(
        StoneChainLineFixture(
          parameters: stoneChainParameters(depthRows: 1),
        ).request,
      );

      expect(result.canApply, isTrue);
      expect(
        result.materialization!.receipt.outputFingerprint,
        _historicalDepthRowsOneOutputFingerprint,
      );
    });

    test('tapers both rows once at straight open endpoints', () {
      final fixture = TwoTierStoneChainFixture();
      final geometry = fixture.request.feature.geometry as BorderStrokeGeometry;
      final stroke = geometry.strokes.single;

      final result = resolveStoneChainLineBorder(fixture.request);

      expect(result.canApply, isTrue, reason: _diagnosticSummary(result));
      final slots = result.materialization!.placements
          .map((placement) => placement.slotKey)
          .toSet();
      for (final endpoint in <GridPos>[
        stroke.points.first,
        stroke.points.last,
      ]) {
        expect(
          slots,
          contains(
            buildBorderStoneChainNodeSlotKey(
              featureId: fixture.request.feature.id,
              strokeId: borderStrokeLineageNamespaceV1(stroke.id),
              vertex: endpoint,
              passIndex: 0,
              role: BorderPrimitiveRole.lineCap,
              rank: 0,
            ),
          ),
          reason: '$endpoint lip cap',
        );
        expect(
          slots,
          contains(
            buildBorderStoneChainNodeSlotKey(
              featureId: fixture.request.feature.id,
              strokeId: borderStrokeLineageNamespaceV1(stroke.id),
              vertex: endpoint,
              passIndex: 1,
              role: BorderPrimitiveRole.structureMedium,
              rank: 2,
            ),
          ),
          reason: '$endpoint face cap',
        );
      }
    });
  });

  group('two-tier stone-chain topology RED contract', () {
    test('keeps one lip stone and two face shoulders at a convex corner', () {
      final stroke = _twoTierStroke(
        'two-tier-convex',
        <GridPos>[
          for (var x = 4; x <= 10; x += 1) GridPos(x: x, y: 6),
          for (var y = 7; y <= 13; y += 1) GridPos(x: 10, y: y),
        ],
      );
      final request = _twoTierTopologyRequest(stroke);
      final result = resolveStoneChainLineBorder(request);

      expect(
        result.canApply,
        isTrue,
        reason: _diagnosticSummary(result),
      );
      _expectTwoTierTurnRecipe(
        request: request,
        result: result,
        stroke: stroke,
        vertex: const GridPos(x: 10, y: 6),
      );
    });

    test('keeps one lip stone and two face shoulders at a concave corner', () {
      final stroke = _twoTierStroke(
        'two-tier-concave',
        <GridPos>[
          for (var x = 4; x <= 10; x += 1) GridPos(x: x, y: 6),
          for (var y = 7; y <= 13; y += 1) GridPos(x: 10, y: y),
        ],
      );
      final request = _twoTierTopologyRequest(
        stroke,
        lineSide: BorderLineSide.inverted,
      );
      final result = resolveStoneChainLineBorder(request);

      expect(
        result.canApply,
        isTrue,
        reason: _diagnosticSummary(result),
      );
      _expectTwoTierTurnRecipe(
        request: request,
        result: result,
        stroke: stroke,
        vertex: const GridPos(x: 10, y: 6),
      );
    });

    test('resolves a one-cell zigzag without T branches', () {
      final stroke = _twoTierStroke(
        'two-tier-one-cell-zigzag',
        <GridPos>[
          for (var x = 4; x <= 8; x += 1) GridPos(x: x, y: 6),
          const GridPos(x: 8, y: 7),
          const GridPos(x: 9, y: 7),
          const GridPos(x: 9, y: 8),
          for (var x = 10; x <= 14; x += 1) GridPos(x: x, y: 8),
        ],
      );
      final request = _twoTierTopologyRequest(stroke);
      final result = resolveStoneChainLineBorder(request);

      expect(
        result.canApply,
        isTrue,
        reason: _diagnosticSummary(result),
      );
      for (final vertex in const <GridPos>[
        GridPos(x: 8, y: 6),
        GridPos(x: 8, y: 7),
        GridPos(x: 9, y: 7),
        GridPos(x: 9, y: 8),
      ]) {
        _expectTwoTierTurnRecipe(
          request: request,
          result: result,
          stroke: stroke,
          vertex: vertex,
        );
        expect(
          result.materialization!.placements.map((item) => item.slotKey),
          isNot(
            contains(
              buildBorderStoneChainNodeSlotKey(
                featureId: request.feature.id,
                strokeId: borderStrokeLineageNamespaceV1(stroke.id),
                vertex: vertex,
                passIndex: 1,
                role: BorderPrimitiveRole.structureMedium,
                rank: 2,
              ),
            ),
          ),
          reason: '$vertex must own exactly two face shoulders, never a T',
        );
      }
    });

    test('keeps both rows continuous through an S bend', () {
      final stroke = _twoTierSStroke('two-tier-s-continuity');
      final request = _twoTierTopologyRequest(stroke);
      final result = resolveStoneChainLineBorder(request);

      expect(
        result.canApply,
        isTrue,
        reason: _diagnosticSummary(result),
      );
      final lips = lipPlacements(request, result);
      final faces = facePlacements(request, result);
      expect(_twoTierOpaqueComponentCount(lips), 1, reason: 'lip S row');
      expect(_twoTierOpaqueComponentCount(faces), 1, reason: 'face S row');
      for (final vertex in const <GridPos>[
        GridPos(x: 10, y: 6),
        GridPos(x: 10, y: 10),
      ]) {
        _expectTwoTierTurnRecipe(
          request: request,
          result: result,
          stroke: stroke,
          vertex: vertex,
        );
      }
    });

    test('avoids visible short cadence reuse inside long topology runs', () {
      final stroke = _twoTierStroke(
        'two-tier-s-diversity',
        <GridPos>[
          for (var x = 4; x <= 10; x += 1) GridPos(x: x, y: 6),
          for (var y = 7; y <= 16; y += 1) GridPos(x: 10, y: y),
          for (var x = 11; x <= 20; x += 1) GridPos(x: x, y: 16),
        ],
      );
      for (final featureSeed in <int>[7, 19072026]) {
        final fixture = TwoTierStoneChainFixture(
          featureSeed: featureSeed,
          publishedPrimitives: twoTierStoneChainPublishedPrimitives(
            variantsPerOrientation: 4,
          ),
        );
        final request = _twoTierTopologyRequest(stroke, fixture: fixture);
        final result = resolveStoneChainLineBorder(request);

        expect(result.canApply, isTrue, reason: _diagnosticSummary(result));
        for (final row in <List<BorderResolvedPlacement>>[
          lipPlacements(request, result),
          facePlacements(request, result),
        ]) {
          final verticalRun = row
              .where(
                (placement) =>
                    placement.primitiveId.contains('-east-') ||
                    placement.primitiveId.contains('-west-'),
              )
              .toList(growable: false)
            ..sort(
              (left, right) =>
                  left.topLeftWorldPx.y.compareTo(right.topLeftWorldPx.y),
            );
          final primitiveIds = verticalRun
              .map((placement) => placement.primitiveId)
              .toList(growable: false);
          expect(primitiveIds.length, greaterThanOrEqualTo(6));
          _expectNoShortRepeatingPrimitiveBlocks(
            primitiveIds,
            reasonPrefix: 'topology run seed $featureSeed',
            debugLabels: <String>[
              for (final placement in verticalRun)
                '${placement.primitiveId}@${placement.topLeftWorldPx}'
                    '@${placement.slotKey}',
            ],
          );
        }
      }
    });

    test('keeps both rows continuous through the inverted canonical S', () {
      final stroke = _twoTierStroke(
        'primary',
        const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 3, y: 3),
          GridPos(x: 3, y: 4),
          GridPos(x: 4, y: 4),
          GridPos(x: 5, y: 4),
          GridPos(x: 5, y: 3),
          GridPos(x: 5, y: 2),
          GridPos(x: 6, y: 2),
          GridPos(x: 7, y: 2),
        ],
      );
      final request = _twoTierTopologyRequest(
        stroke,
        lineSide: BorderLineSide.inverted,
        featureId: 'border-gallery-v1:sBend',
        featureSeed: BorderSignedInt64.fromInt(41),
        mapSize: const GridSize(width: 12, height: 10),
      );
      final result = resolveStoneChainLineBorder(request);

      expect(result.canApply, isTrue, reason: _diagnosticSummary(result));
      expect(
        _twoTierTrueMaskComponentCount(
          request,
          lipPlacements(request, result),
        ),
        1,
        reason: 'inverted canonical S lip row',
      );
      expect(
        _twoTierTrueMaskComponentCount(
          request,
          facePlacements(request, result),
        ),
        1,
        reason: 'inverted canonical S face row',
      );
    });

    test(
        'plans topology joints from true alpha contact instead of projected bounds',
        () {
      final primitives = _twoTierProjectionOnlyLipFallbackPrimitives();
      final stroke = _twoTierStroke(
        'alpha-contact-l',
        <GridPos>[
          for (var x = 4; x <= 12; x += 1) GridPos(x: x, y: 6),
          for (var y = 7; y <= 13; y += 1) GridPos(x: 12, y: y),
        ],
      );
      final fixture = TwoTierStoneChainFixture(
        featureSeed: 1,
        publishedPrimitives: primitives,
      );
      final request = _twoTierTopologyRequest(stroke, fixture: fixture);

      final result = resolveStoneChainLineBorder(request);

      expect(result.canApply, isTrue, reason: _diagnosticSummary(result));
      expect(
        _twoTierTrueMaskComponentCount(
          request,
          result.materialization!.placements,
        ),
        1,
      );
    });

    test('keeps a straight lineage stable beside an independent L path', () {
      final straight = _twoTierStroke(
        'mixed-straight',
        <GridPos>[
          for (var x = 4; x <= 14; x += 1) GridPos(x: x, y: 20),
        ],
      );
      final turn = _twoTierStroke(
        'mixed-turn',
        <GridPos>[
          for (var x = 4; x <= 10; x += 1) GridPos(x: x, y: 6),
          for (var y = 7; y <= 13; y += 1) GridPos(x: 10, y: y),
        ],
      );
      final straightRequest = _twoTierTopologyRequest(straight);
      final mixedRequest = _twoTierTopologyRequest(
        straight,
        additionalStrokes: <BorderStroke>[turn],
      );

      final straightResult = resolveStoneChainLineBorder(straightRequest);
      final mixedResult = resolveStoneChainLineBorder(mixedRequest);

      expect(
        straightResult.canApply,
        isTrue,
        reason: _diagnosticSummary(straightResult),
      );
      expect(
        mixedResult.canApply,
        isTrue,
        reason: _diagnosticSummary(mixedResult),
      );
      final straightAlonePlacements = _twoTierPlacementsForStrokeLineage(
        request: straightRequest,
        result: straightResult,
        stroke: straight,
      );
      final straightMixedPlacements = _twoTierPlacementsForStrokeLineage(
        request: mixedRequest,
        result: mixedResult,
        stroke: straight,
      );
      expect(
        straightAlonePlacements,
        straightResult.materialization!.placements,
        reason: 'The lineage filter must own every straight-only placement.',
      );
      expect(
        straightMixedPlacements.map((placement) => placement.slotKey),
        straightAlonePlacements.map((placement) => placement.slotKey),
      );
      expect(straightMixedPlacements, straightAlonePlacements);

      final suppressedSlot =
          straightAlonePlacements[straightAlonePlacements.length ~/ 2].slotKey;
      final suppression = BorderSlotOverride(
        slotKey: suppressedSlot,
        variationSalt: BorderSignedInt64.zero,
        suppressed: true,
        locked: false,
      );
      final suppressedStraightRequest = _twoTierTopologyRequest(
        straight,
        overrides: <BorderSlotOverride>[suppression],
      );
      final suppressedMixedRequest = _twoTierTopologyRequest(
        straight,
        additionalStrokes: <BorderStroke>[turn],
        overrides: <BorderSlotOverride>[suppression],
      );
      final suppressedStraightResult =
          resolveStoneChainLineBorder(suppressedStraightRequest);
      final suppressedMixedResult =
          resolveStoneChainLineBorder(suppressedMixedRequest);
      expect(
        suppressedStraightResult.canApply,
        isTrue,
        reason: _diagnosticSummary(suppressedStraightResult),
      );
      expect(
        suppressedMixedResult.canApply,
        isTrue,
        reason: _diagnosticSummary(suppressedMixedResult),
      );
      final suppressedStraightPlacements = _twoTierPlacementsForStrokeLineage(
        request: suppressedStraightRequest,
        result: suppressedStraightResult,
        stroke: straight,
      );
      final suppressedMixedPlacements = _twoTierPlacementsForStrokeLineage(
        request: suppressedMixedRequest,
        result: suppressedMixedResult,
        stroke: straight,
      );
      expect(
        suppressedMixedPlacements,
        suppressedStraightPlacements,
        reason: 'The same override must stay attached to the straight slot.',
      );
      expect(
        suppressedMixedPlacements.map((placement) => placement.slotKey),
        isNot(contains(suppressedSlot)),
      );

      final baseline = resolveBorderFeatureLocalBaseline(straightRequest);
      final local = resolveBorderFeatureLocally(
        request: mixedRequest,
        previousState: baseline,
        edits: <BorderLocalEdit>[
          BorderLocalEdit.forCells(
            cells: turn.points,
            tileSizePx: mixedRequest.tileSizePx,
          ),
        ],
      );
      expect(local.result, mixedResult);
      expect(
        local.reusedDistantPlacementSlotKeys,
        containsAll(
          straightAlonePlacements.map((placement) => placement.slotKey),
        ),
        reason: 'Adding a distant L must reuse the straight lineage locally.',
      );
    });

    test('closes both rows without duplicate seam stones', () {
      final stroke = _twoTierLoopStroke('two-tier-loop-seam');
      final request = _twoTierTopologyRequest(stroke);
      final result = resolveStoneChainLineBorder(request);

      expect(
        result.canApply,
        isTrue,
        reason: _diagnosticSummary(result),
      );
      final placements = result.materialization!.placements;
      expect(
        placements.map((placement) => placement.slotKey).toSet(),
        hasLength(placements.length),
      );
      expect(
        _twoTierOpaqueComponentCount(lipPlacements(request, result)),
        1,
        reason: 'lip loop including its canonical seam',
      );
      expect(
        _twoTierOpaqueComponentCount(facePlacements(request, result)),
        1,
        reason: 'face loop including its canonical seam',
      );
      _expectTwoTierTurnRecipe(
        request: request,
        result: result,
        stroke: stroke,
        vertex: stroke.points.first,
      );
    });

    test('places no caps on a loop', () {
      final stroke = _twoTierLoopStroke('two-tier-loop-no-caps');
      final request = _twoTierTopologyRequest(stroke);
      final result = resolveStoneChainLineBorder(request);

      expect(
        result.canApply,
        isTrue,
        reason: _diagnosticSummary(result),
      );
      final slots = result.materialization!.placements
          .map((placement) => placement.slotKey)
          .toSet();
      for (final vertex in stroke.points) {
        for (final rank in const <int>[0, 1]) {
          expect(
            slots,
            isNot(
              contains(
                buildBorderStoneChainNodeSlotKey(
                  featureId: request.feature.id,
                  strokeId: borderStrokeLineageNamespaceV1(stroke.id),
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
              buildBorderStoneChainNodeSlotKey(
                featureId: request.feature.id,
                strokeId: borderStrokeLineageNamespaceV1(stroke.id),
                vertex: vertex,
                passIndex: 1,
                role: BorderPrimitiveRole.structureMedium,
                rank: 2,
              ),
            ),
          ),
        );
      }
    });

    test('tapers both rows once at open endpoints', () {
      final stroke = _twoTierSStroke('two-tier-open-caps');
      final request = _twoTierTopologyRequest(stroke);
      final result = resolveStoneChainLineBorder(request);

      expect(
        result.canApply,
        isTrue,
        reason: _diagnosticSummary(result),
      );
      final placementsBySlot = <String, BorderResolvedPlacement>{
        for (final placement in result.materialization!.placements)
          placement.slotKey: placement,
      };
      for (final endpoint in <GridPos>[
        stroke.points.first,
        stroke.points.last
      ]) {
        final lipCap = buildBorderStoneChainNodeSlotKey(
          featureId: request.feature.id,
          strokeId: borderStrokeLineageNamespaceV1(stroke.id),
          vertex: endpoint,
          passIndex: 0,
          role: BorderPrimitiveRole.lineCap,
          rank: 0,
        );
        final faceCap = buildBorderStoneChainNodeSlotKey(
          featureId: request.feature.id,
          strokeId: borderStrokeLineageNamespaceV1(stroke.id),
          vertex: endpoint,
          passIndex: 1,
          role: BorderPrimitiveRole.structureMedium,
          rank: 2,
        );
        expect(placementsBySlot, contains(lipCap), reason: '$endpoint lip');
        expect(placementsBySlot, contains(faceCap), reason: '$endpoint face');
        expect(placementsBySlot[lipCap]!.stableOrderKey.passIndex, 0);
        expect(placementsBySlot[faceCap]!.stableOrderKey.passIndex, 1);
        expect(placementsBySlot[faceCap]!.drawBand, BorderDrawBand.outerAccent);
      }
    });

    test('reversing authored point order keeps canonical slots', () {
      final forwardStroke = _twoTierSStroke('two-tier-reversed-authored');
      final reverseStroke = BorderStroke(
        id: forwardStroke.id,
        points: forwardStroke.points.reversed.toList(growable: false),
        closed: false,
      );
      final forward = resolveStoneChainLineBorder(
        _twoTierTopologyRequest(forwardStroke),
      );
      final reverse = resolveStoneChainLineBorder(
        _twoTierTopologyRequest(reverseStroke),
      );

      expect(forward.canApply, isTrue, reason: _diagnosticSummary(forward));
      expect(reverse.canApply, isTrue, reason: _diagnosticSummary(reverse));
      expect(reverse.materialization!.placements,
          forward.materialization!.placements);
    });

    test('cyclically rotating a loop keeps canonical slots', () {
      final canonical = _twoTierLoopStroke('two-tier-rotated-loop');
      const offset = 7;
      final rotated = BorderStroke(
        id: canonical.id,
        points: <GridPos>[
          ...canonical.points.skip(offset),
          ...canonical.points.take(offset),
        ],
        closed: true,
      );
      final canonicalResult = resolveStoneChainLineBorder(
        _twoTierTopologyRequest(canonical),
      );
      final rotatedResult = resolveStoneChainLineBorder(
        _twoTierTopologyRequest(rotated),
      );

      expect(
        canonicalResult.canApply,
        isTrue,
        reason: _diagnosticSummary(canonicalResult),
      );
      expect(
        rotatedResult.canApply,
        isTrue,
        reason: _diagnosticSummary(rotatedResult),
      );
      expect(
        rotatedResult.materialization!.placements,
        canonicalResult.materialization!.placements,
      );
    });
  });

  test(
      'resolves the first Selbrume coast stroke at the published detail density',
      () {
    final unsignedSeed = BorderDeterministicRng.fromComponents(
      const <BorderRngKeyComponent>[
        BorderRngKeyComponent.text('border-feature-seed-v1'),
        BorderRngKeyComponent.text('map_bourg_selbrume'),
        BorderRngKeyComponent.text('l_border_bordures_qa_pierre_unique'),
        BorderRngKeyComponent.text('border_feature'),
        BorderRngKeyComponent.text('border-blueprint-3'),
        BorderRngKeyComponent.text('3'),
      ],
    ).nextUint64();
    final featureSeed = unsignedSeed >= (BigInt.one << 63)
        ? unsignedSeed - (BigInt.one << 64)
        : unsignedSeed;
    final result = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        mapSize: const GridSize(width: 55, height: 55),
        strokes: <BorderStroke>[stoneChainSelbrumeCoastStrokes().first],
        primitives: stoneChainSelbrumePrimitives(),
        featureSeed: featureSeed.toInt(),
        blueprintId: 'border-blueprint-3',
        blueprintRevision: 3,
        previewSeed: 851231784,
        featureId: 'border_feature',
        parameters: stoneChainParameters(
          irregularityPermille: 280,
          detailDensityPermille: 170,
          variationPermille: 900,
          maxOverlapPx: 2,
          gapTolerancePx: 2,
          depthRows: 2,
          allowAutoRotation: false,
        ),
      ).request,
    );

    expect(
      result.result.canApply,
      isTrue,
      reason: result.result.diagnostics
          .map((item) => '${item.code}: ${item.parameters}')
          .join(', '),
    );
    expect(result.maximumGapPx, lessThanOrEqualTo(2));
    expect(result.maximumTangentOverlapPx, lessThanOrEqualTo(2));
  });

  test('keeps every quarter turn at zero when rotation is disabled', () {
    final result = resolveStoneChainLineBorder(
      StoneChainLineFixture(
        parameters: stoneChainParameters(allowAutoRotation: false),
        strokes: <BorderStroke>[
          _stroke('vertical', const <GridPos>[
            GridPos(x: 4, y: 1),
            GridPos(x: 4, y: 2),
            GridPos(x: 4, y: 3),
            GridPos(x: 4, y: 4),
          ]),
        ],
      ).request,
    );

    expect(
      result.canApply,
      isTrue,
      reason: result.diagnostics
          .map((item) => '${item.code}:${item.cell}:${item.parameters}')
          .join(', '),
    );
    expect(
        result.materialization!.placements,
        everyElement(predicate<BorderResolvedPlacement>((value) =>
            value.transform.quarterTurns == 0 && !value.transform.flipX)));
  });

  test('uses only explicitly allowed transforms when rotation is enabled', () {
    final fixture = StoneChainLineFixture(
      strokes: <BorderStroke>[
        _stroke('vertical', const <GridPos>[
          GridPos(x: 4, y: 1),
          GridPos(x: 4, y: 2),
          GridPos(x: 4, y: 3),
          GridPos(x: 4, y: 4),
          GridPos(x: 4, y: 5),
        ]),
      ],
    );
    final result = resolveStoneChainLineBorder(fixture.request);
    final allowed = <String, List<int>>{
      for (final primitive
          in fixture.request.blueprintRevision!.definition.primitives)
        primitive.id: primitive.transforms.allowedQuarterTurns,
    };

    expect(result.canApply, isTrue);
    for (final placement in result.materialization!.placements) {
      expect(allowed[placement.primitiveId],
          contains(placement.transform.quarterTurns));
      expect(placement.transform.flipX, isFalse);
    }
  });

  test('accepts boundary vertices at map width and height', () {
    final result = resolveStoneChainLineBorder(
      StoneChainLineFixture(
        strokes: <BorderStroke>[
          _stroke('boundary', const <GridPos>[
            GridPos(x: 10, y: 12),
            GridPos(x: 11, y: 12),
            GridPos(x: 12, y: 12),
          ]),
        ],
      ).request,
    );

    expect(result.canApply, isTrue);
  });

  test('rejects cell-centered geometry ground and incompatible roles', () {
    final cellCentered = StoneChainLineFixture(
      geometry:
          BorderStrokeGeometry(strokes: <BorderStroke>[stoneChainLongStroke()]),
    ).request;
    final ground = StoneChainLineFixture(
      ground: BorderPublishedGround(
        sourceSurfacePresetId: 'ground',
        edgeBandCells: 1,
        visualSnapshotIdsByRole: <SurfaceVariantRole, String>{
          for (final role in standardSurfaceVariantRoleOrder)
            role: stoneChainSnapshotId('1'),
        },
      ),
    ).request;
    final incompatible = StoneChainLineFixture(
      primitives: <BorderPublishedPrimitive>[
        ...stoneChainPrimitives(),
        stoneChainPrimitive(
          id: 'accent',
          character: '9',
          role: BorderPrimitiveRole.accent,
          width: 8,
          height: 8,
        ),
      ],
    ).request;

    expect(_codes(resolveStoneChainLineBorder(cellCentered)),
        contains('border.resolution.grid_edge_geometry_required'));
    expect(_codes(resolveStoneChainLineBorder(ground)),
        contains('border.resolution.linear_ground_not_supported'));
    expect(_codes(resolveStoneChainLineBorder(incompatible)),
        contains('border.resolution.role_not_supported_by_template'));
  });

  test('is independent from primitive and snapshot input order', () {
    final normal = resolveStoneChainLineBorder(StoneChainLineFixture().request);
    final reversed = resolveStoneChainLineBorder(
      StoneChainLineFixture(reverseInputs: true).request,
    );

    expect(normal, reversed);
  });

  test('keeps slot keys stable across side and rotation changes', () {
    Set<String> keys(BorderResolutionRequest request) =>
        resolveStoneChainLineBorder(request)
            .materialization!
            .placements
            .map((value) => value.slotKey)
            .toSet();

    final primary = keys(StoneChainLineFixture().request);
    final inverted = keys(
      StoneChainLineFixture(lineSide: BorderLineSide.inverted).request,
    );
    final rotationOff = keys(
      StoneChainLineFixture(
        parameters: stoneChainParameters(allowAutoRotation: false),
      ).request,
    );

    expect(inverted, primary);
    expect(rotationOff, primary);
  });

  test('supports overrides keep-outs and local regeneration', () {
    final baseRequest = StoneChainLineFixture().request;
    final base = resolveStoneChainLineBorder(baseRequest);
    expect(base.canApply, isTrue);
    final first = base.materialization!.placements.first;
    final overrideRequest = StoneChainLineFixture(
      overrides: <BorderSlotOverride>[
        BorderSlotOverride(
          slotKey: first.slotKey,
          variationSalt: BorderSignedInt64.zero,
          suppressed: true,
          locked: false,
        ),
      ],
    ).request;
    final overridden = resolveStoneChainLineBorder(overrideRequest);
    expect(overridden.canApply, isTrue);
    expect(overridden.materialization!.placements,
        hasLength(base.materialization!.placements.length - 1));

    final baseline = resolveBorderFeatureLocalBaseline(baseRequest);
    final local = resolveBorderFeatureLocally(
      request: overrideRequest,
      previousState: baseline,
      edits: <BorderLocalEdit>[
        BorderLocalEdit.forCells(
          cells: <GridPos>[first.anchorCell],
          tileSizePx: baseRequest.tileSizePx,
        ),
      ],
    );
    expect(local.result.canApply, isTrue);
    expect(local.result.materialization, overridden.materialization);
    expect(local.reusedDistantPlacementSlotKeys, isNotEmpty);
  });

  test('preserves split lineage slots and isolates secondary fragments', () {
    final parameters = stoneChainParameters(
      detailDensityPermille: 1000,
      variationPermille: 0,
      gapTolerancePx: 0,
      depthRows: 2,
      allowAutoRotation: false,
    );
    final sourceStroke = stoneChainHorizontalStroke(
      id: 'split-wall',
      startX: 2,
      edgeCount: 32,
      y: 4,
    );
    final beforeRequest = StoneChainLineFixture(
      mapSize: const GridSize(width: 40, height: 8),
      strokes: <BorderStroke>[sourceStroke],
      parameters: parameters,
    ).request;
    final beforeState = resolveBorderFeatureLocalBaseline(beforeRequest);
    expect(beforeState.result.canApply, isTrue);
    final erasedGeometry = BorderStrokeEditingDraft.begin(
      baseGeometry: beforeRequest.feature.geometry as BorderStrokeGeometry,
      mode: BorderStrokeEditingMode.erase,
      pointerDown: const GridPos(x: 18, y: 4),
    ).previewGeometry!;
    final identities = erasedGeometry.strokes
        .map(resolveBorderStrokeLineageIdentityV1)
        .toList(growable: false);
    expect(
      identities.map((identity) => identity.sourceEdgeOffset),
      <int>[0, 17],
    );
    expect(
      identities.map((identity) => identity.wrapLength),
      everyElement(isNull),
    );

    final erasedRequest = StoneChainLineFixture(
      mapSize: const GridSize(width: 40, height: 8),
      strokes: erasedGeometry.strokes,
      parameters: parameters,
    ).request;
    final full = resolveStoneChainLineBorderWithEvidence(erasedRequest);
    expect(full.result.canApply, isTrue);
    final isolatedSecondaryCount = erasedGeometry.strokes
        .map(
          (stroke) => resolveStoneChainLineBorderWithEvidence(
            StoneChainLineFixture(
              mapSize: const GridSize(width: 40, height: 8),
              strokes: <BorderStroke>[stroke],
              parameters: parameters,
            ).request,
          ).secondaryPlacementCount,
        )
        .fold(0, (total, count) => total + count);
    expect(full.secondaryPlacementCount, isolatedSecondaryCount);

    final distantBefore = beforeState.result.materialization!.placements
        .where((placement) => placement.anchorCell.x >= 25)
        .toList(growable: false);
    expect(distantBefore, isNotEmpty);
    final fullBySlot = <String, BorderResolvedPlacement>{
      for (final placement in full.result.materialization!.placements)
        placement.slotKey: placement,
    };
    expect(
      fullBySlot.keys,
      containsAll(distantBefore.map((placement) => placement.slotKey)),
    );

    final local = resolveBorderFeatureLocally(
      request: erasedRequest,
      previousState: beforeState,
      edits: <BorderLocalEdit>[
        BorderLocalEdit.forCells(
          cells: const <GridPos>[GridPos(x: 18, y: 4)],
          tileSizePx: erasedRequest.tileSizePx,
        ),
      ],
    );
    expect(local.result, full.result);
    expect(
      local.reusedDistantPlacementSlotKeys,
      containsAll(distantBefore.map((placement) => placement.slotKey)),
    );
  });

  test('preserves wrapped lineage slots after opening a closed loop', () {
    final parameters = stoneChainParameters(
      detailDensityPermille: 1000,
      variationPermille: 0,
      gapTolerancePx: 0,
      depthRows: 2,
      allowAutoRotation: false,
    );
    final sourceStroke = stoneChainRectangularLoop(
      id: 'wrapped-wall',
      left: 2,
      top: 2,
      right: 10,
      bottom: 10,
    );
    final beforeRequest = StoneChainLineFixture(
      mapSize: const GridSize(width: 14, height: 14),
      strokes: <BorderStroke>[sourceStroke],
      parameters: parameters,
    ).request;
    final beforeState = resolveBorderFeatureLocalBaseline(beforeRequest);
    expect(beforeState.result.canApply, isTrue);

    const erasedCell = GridPos(x: 6, y: 2);
    final openedGeometry = BorderStrokeEditingDraft.begin(
      baseGeometry: beforeRequest.feature.geometry as BorderStrokeGeometry,
      mode: BorderStrokeEditingMode.erase,
      pointerDown: erasedCell,
    ).previewGeometry!;
    expect(openedGeometry.strokes, hasLength(1));
    final identity = resolveBorderStrokeLineageIdentityV1(
      openedGeometry.strokes.single,
    );
    expect(identity.sourceEdgeOffset, 5);
    expect(identity.wrapLength, 32);
    expect(openedGeometry.strokes.single.closed, isFalse);

    final openedRequest = StoneChainLineFixture(
      mapSize: const GridSize(width: 14, height: 14),
      strokes: openedGeometry.strokes,
      parameters: parameters,
    ).request;
    final full = resolveStoneChainLineBorder(openedRequest);
    expect(full.canApply, isTrue);
    final cornerPrimitiveIds = <String>{
      for (final primitive
          in beforeRequest.blueprintRevision!.definition.primitives)
        if (primitive.role == BorderPrimitiveRole.lineCorner) primitive.id,
    };
    final distantCornerBefore =
        beforeState.result.materialization!.placements.singleWhere(
      (placement) =>
          placement.anchorCell == const GridPos(x: 9, y: 9) &&
          cornerPrimitiveIds.contains(placement.primitiveId),
    );
    final distantBefore = beforeState.result.materialization!.placements
        .where(
          (placement) =>
              placement.anchorCell.y >= 9 &&
              placement.anchorCell.x >= 4 &&
              placement.anchorCell.x <= 8,
        )
        .toList(growable: false);
    expect(distantBefore, isNotEmpty);
    final fullBySlot = <String, BorderResolvedPlacement>{
      for (final placement in full.materialization!.placements)
        placement.slotKey: placement,
    };
    expect(
      fullBySlot.keys,
      containsAll(distantBefore.map((placement) => placement.slotKey)),
    );
    expect(fullBySlot, contains(distantCornerBefore.slotKey));

    final local = resolveBorderFeatureLocally(
      request: openedRequest,
      previousState: beforeState,
      edits: <BorderLocalEdit>[
        BorderLocalEdit.forCells(
          cells: const <GridPos>[erasedCell],
          tileSizePx: openedRequest.tileSizePx,
        ),
      ],
    );
    expect(local.result, full);
    expect(
      local.reusedDistantPlacementSlotKeys,
      containsAll(distantBefore.map((placement) => placement.slotKey)),
    );
    expect(
      local.reusedDistantPlacementSlotKeys,
      contains(distantCornerBefore.slotKey),
    );

    final suppressedCorner = resolveStoneChainLineBorder(
      StoneChainLineFixture(
        mapSize: const GridSize(width: 14, height: 14),
        strokes: openedGeometry.strokes,
        parameters: parameters,
        overrides: <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: distantCornerBefore.slotKey,
            variationSalt: BorderSignedInt64.zero,
            suppressed: true,
            locked: false,
          ),
        ],
      ).request,
    );
    expect(suppressedCorner.canApply, isTrue);
    expect(
      suppressedCorner.materialization!.placements
          .map((placement) => placement.slotKey),
      isNot(contains(distantCornerBefore.slotKey)),
    );
  });

  test('measures evidence from placements after overrides', () {
    final baseFixture = StoneChainLineFixture();
    final base = resolveStoneChainLineBorder(baseFixture.request);
    final largeIds = <String>{
      for (final primitive
          in baseFixture.request.blueprintRevision!.definition.primitives)
        if (primitive.role == BorderPrimitiveRole.structureLarge) primitive.id,
    };
    final shiftedSlot = base.materialization!.placements
        .where((placement) => largeIds.contains(placement.primitiveId))
        .skip(2)
        .first
        .slotKey;
    final evidence = resolveStoneChainLineBorderWithEvidence(
      StoneChainLineFixture(
        overrides: <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: shiftedSlot,
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
            offsetDeltaPx: const BorderPixelOffset(x: 10, y: 0),
          ),
        ],
      ).request,
    );
    final measured = _maximumPairwiseOpaqueOverlap(
      evidence.result.materialization!.placements,
    );

    expect(measured, greaterThan(3));
    expect(evidence.maximumTangentOverlapPx, measured);
  });

  test('enforces the overlap budget across adjacent strokes', () {
    final fixture = StoneChainLineFixture(
      mapSize: const GridSize(width: 12, height: 10),
      strokes: <BorderStroke>[
        stoneChainHorizontalStroke(
          id: 'upper',
          startX: 2,
          edgeCount: 7,
          y: 4,
        ),
        stoneChainHorizontalStroke(
          id: 'lower',
          startX: 2,
          edgeCount: 7,
          y: 5,
        ),
      ],
      parameters: stoneChainParameters(
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 3,
        gapTolerancePx: 0,
        depthRows: 1,
        allowAutoRotation: false,
      ),
      primitives: <BorderPublishedPrimitive>[
        stoneChainPrimitive(
          id: 'large-a-wide',
          character: 'a',
          width: 16,
          height: 48,
        ),
        stoneChainPrimitive(
          id: 'large-b-narrow',
          character: 'b',
          width: 16,
          height: 3,
        ),
        stoneChainPrimitive(
          id: 'cap-narrow',
          character: 'c',
          role: BorderPrimitiveRole.lineCap,
          width: 12,
          height: 3,
        ),
      ],
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);

    expect(
      evidence.result.canApply,
      isTrue,
      reason: evidence.result.diagnostics
          .map((item) => '${item.code}: ${item.parameters}')
          .join(', '),
    );
    final measured = _maximumPairwiseOpaqueOverlap(
      evidence.result.materialization!.placements,
    );
    expect(measured, lessThanOrEqualTo(3));
    expect(evidence.maximumTangentOverlapPx, measured);
  });

  test('tries a smaller primitive of the same role after a collision', () {
    final fixture = StoneChainLineFixture(
      strokes: <BorderStroke>[
        stoneChainHorizontalStroke(
          id: 'same-role-fallback',
          startX: 2,
          edgeCount: 7,
          y: 4,
        ),
      ],
      parameters: stoneChainParameters(
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 3,
        gapTolerancePx: 0,
        depthRows: 1,
        allowAutoRotation: false,
      ),
      primitives: <BorderPublishedPrimitive>[
        stoneChainPrimitive(
          id: 'large-a-colliding',
          character: 'a',
          width: 24,
          height: 16,
        ),
        stoneChainPrimitive(
          id: 'large-b-fitting',
          character: 'b',
          width: 4,
          height: 16,
        ),
        stoneChainPrimitive(
          id: 'cap',
          character: 'c',
          role: BorderPrimitiveRole.lineCap,
          width: 8,
          height: 8,
        ),
      ],
    );
    final result = resolveStoneChainLineBorder(fixture.request);

    expect(result.canApply, isTrue);
    expect(
      result.materialization!.placements.map((item) => item.primitiveId),
      contains('large-b-fitting'),
    );
  });

  test('keeps anisotropic vertical slots stable across rotation changes', () {
    final stroke = _stroke('anisotropic-vertical', <GridPos>[
      for (var y = 1; y <= 10; y += 1) GridPos(x: 4, y: y),
    ]);
    final primitives = <BorderPublishedPrimitive>[
      stoneChainPrimitive(
        id: 'large-anisotropic',
        character: 'a',
        width: 8,
        height: 24,
      ),
      stoneChainPrimitive(
        id: 'cap',
        character: 'b',
        role: BorderPrimitiveRole.lineCap,
        width: 2,
        height: 2,
      ),
    ];
    BorderResolutionRequest request({
      required bool allowAutoRotation,
      List<BorderSlotOverride> overrides = const <BorderSlotOverride>[],
    }) =>
        StoneChainLineFixture(
          mapSize: const GridSize(width: 10, height: 12),
          strokes: <BorderStroke>[stroke],
          primitives: primitives,
          overrides: overrides,
          parameters: stoneChainParameters(
            detailDensityPermille: 0,
            variationPermille: 0,
            maxOverlapPx: 3,
            gapTolerancePx: 0,
            depthRows: 1,
            allowAutoRotation: allowAutoRotation,
          ),
        ).request;

    final rotationOn = resolveStoneChainLineBorder(
      request(allowAutoRotation: true),
    );
    final rotationOff = resolveStoneChainLineBorder(
      request(allowAutoRotation: false),
    );
    expect(rotationOn.canApply, isTrue);
    expect(rotationOff.canApply, isTrue);
    expect(
      rotationOn.materialization!.placements,
      everyElement(
        predicate<BorderResolvedPlacement>(
          (placement) => placement.transform.quarterTurns == 0,
        ),
      ),
    );
    final onSlots = rotationOn.materialization!.placements
        .map((placement) => placement.slotKey)
        .toSet();
    final offSlots = rotationOff.materialization!.placements
        .map((placement) => placement.slotKey)
        .toSet();
    expect(offSlots, onSlots);

    final structuralIds = <String>{'large-anisotropic'};
    final suppressedSlot = rotationOn.materialization!.placements
        .firstWhere(
          (placement) => structuralIds.contains(placement.primitiveId),
        )
        .slotKey;
    final overriddenOff = resolveStoneChainLineBorder(
      request(
        allowAutoRotation: false,
        overrides: <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: suppressedSlot,
            variationSalt: BorderSignedInt64.zero,
            suppressed: true,
            locked: false,
          ),
        ],
      ),
    );
    expect(overriddenOff.canApply, isTrue);
    expect(
      overriddenOff.materialization!.placements
          .map((placement) => placement.slotKey),
      isNot(contains(suppressedSlot)),
    );
  });

  test('uses a required quarter turn for a horizontal-only vertical stone', () {
    final fixture = StoneChainLineFixture(
      mapSize: const GridSize(width: 10, height: 12),
      strokes: <BorderStroke>[
        _stroke('required-quarter-turn', <GridPos>[
          for (var y = 1; y <= 10; y += 1) GridPos(x: 4, y: y),
        ]),
      ],
      primitives: <BorderPublishedPrimitive>[
        stoneChainPrimitive(
          id: 'horizontal-only',
          character: 'a',
          width: 24,
          height: 8,
          allowedQuarterTurns: const <int>[1],
        ),
        stoneChainPrimitive(
          id: 'cap',
          character: 'b',
          role: BorderPrimitiveRole.lineCap,
          width: 8,
          height: 60,
          allowedQuarterTurns: const <int>[0],
        ),
      ],
      parameters: stoneChainParameters(
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 3,
        gapTolerancePx: 2,
        depthRows: 1,
        allowAutoRotation: true,
      ),
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);

    expect(
      evidence.result.canApply,
      isTrue,
      reason: evidence.result.diagnostics.map((item) => item.code).join(', '),
    );
    final structural = evidence.result.materialization!.placements.where(
      (placement) => placement.primitiveId == 'horizontal-only',
    );
    expect(structural, isNotEmpty);
    expect(
      structural.map((placement) => placement.transform.quarterTurns),
      everyElement(1),
    );
    expect(evidence.maximumGapPx, lessThanOrEqualTo(2));
  });

  test('rejects a detached primary chain before applying overrides', () {
    final fixture = StoneChainLineFixture(
      strokes: <BorderStroke>[
        stoneChainHorizontalStroke(
          id: 'detached-chain',
          startX: 2,
          edgeCount: 7,
          y: 4,
        ),
      ],
      primitives: <BorderPublishedPrimitive>[
        stoneChainPrimitive(
          id: 'too-small',
          character: 'a',
          width: 4,
          height: 8,
          allowedQuarterTurns: const <int>[0],
        ),
        stoneChainPrimitive(
          id: 'cap',
          character: 'b',
          role: BorderPrimitiveRole.lineCap,
          width: 4,
          height: 8,
          allowedQuarterTurns: const <int>[0],
        ),
      ],
      parameters: stoneChainParameters(
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 3,
        gapTolerancePx: 2,
        depthRows: 1,
        allowAutoRotation: false,
      ),
    );
    final evidence = resolveStoneChainLineBorderWithEvidence(fixture.request);

    expect(evidence.result.canApply, isFalse);
    final diagnostic = evidence.result.diagnostics.singleWhere(
      (item) =>
          item.code == 'border.resolution.stone_chain_primary_gap_exceeded',
    );
    expect(diagnostic.parameters['gapPx'], greaterThan(2));
    expect(diagnostic.parameters['gapTolerancePx'], 2);
  });

  test(
    'resolves many independent strokes within the regression budget',
    () {
      const strokeCount = 6000;
      final fixture = StoneChainLineFixture(
        mapSize: const GridSize(width: 6, height: strokeCount * 2 + 2),
        strokes: <BorderStroke>[
          for (var index = 0; index < strokeCount; index += 1)
            stoneChainHorizontalStroke(
              id: 'multi-$index',
              startX: 1,
              edgeCount: 3,
              y: index * 2 + 1,
            ),
        ],
        parameters: stoneChainParameters(
          detailDensityPermille: 0,
          variationPermille: 0,
          gapTolerancePx: 0,
          depthRows: 1,
          allowAutoRotation: false,
        ),
      );
      final stopwatch = Stopwatch()..start();
      final result = resolveStoneChainLineBorder(fixture.request);
      stopwatch.stop();

      expect(result.canApply, isTrue);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 4)));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'resolves a long stroke deterministically within the regression budget',
    () {
      const edgeCount = 8000;
      final fixture = StoneChainLineFixture(
        mapSize: const GridSize(width: edgeCount + 2, height: 6),
        strokes: <BorderStroke>[
          stoneChainHorizontalStroke(
            id: 'long-performance-stroke',
            startX: 1,
            edgeCount: edgeCount,
            y: 3,
          ),
        ],
        parameters: stoneChainParameters(
          detailDensityPermille: 0,
          variationPermille: 0,
          gapTolerancePx: 0,
          depthRows: 1,
          allowAutoRotation: false,
        ),
      );
      final stopwatch = Stopwatch()..start();
      final first = resolveStoneChainLineBorder(fixture.request);
      stopwatch.stop();
      final repeated = resolveStoneChainLineBorder(fixture.request);

      expect(first.canApply, isTrue);
      expect(repeated.materialization, first.materialization);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 4)));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

BorderStroke _twoTierStroke(
  String id,
  List<GridPos> points, {
  bool closed = false,
}) =>
    BorderStroke(id: id, points: points, closed: closed);

BorderStroke _twoTierSStroke(String id) => _twoTierStroke(
      id,
      <GridPos>[
        for (var x = 4; x <= 10; x += 1) GridPos(x: x, y: 6),
        for (var y = 7; y <= 10; y += 1) GridPos(x: 10, y: y),
        for (var x = 11; x <= 17; x += 1) GridPos(x: x, y: 10),
      ],
    );

BorderStroke _twoTierLoopStroke(String id) => _twoTierStroke(
      id,
      <GridPos>[
        for (var x = 5; x <= 17; x += 1) GridPos(x: x, y: 5),
        for (var y = 6; y <= 17; y += 1) GridPos(x: 17, y: y),
        for (var x = 16; x >= 5; x -= 1) GridPos(x: x, y: 17),
        for (var y = 16; y > 5; y -= 1) GridPos(x: 5, y: y),
      ],
      closed: true,
    );

BorderResolutionRequest _twoTierTopologyRequest(
  BorderStroke stroke, {
  TwoTierStoneChainFixture? fixture,
  List<BorderStroke> additionalStrokes = const <BorderStroke>[],
  List<BorderSlotOverride> overrides = const <BorderSlotOverride>[],
  BorderLineSide lineSide = BorderLineSide.primary,
  String? featureId,
  BorderSignedInt64? featureSeed,
  GridSize? mapSize,
}) {
  final source =
      (fixture ?? TwoTierStoneChainFixture(lineSide: lineSide)).request;
  return BorderResolutionRequest(
    mapSize: mapSize ?? source.mapSize,
    tileSizePx: source.tileSizePx,
    blueprintId: source.blueprintId,
    blueprintRevision: source.blueprintRevision,
    feature: BorderFeature(
      id: featureId ?? source.feature.id,
      name: source.feature.name,
      blueprintId: source.feature.blueprintId,
      seed: featureSeed ?? source.feature.seed,
      geometry: BorderStrokeGeometry(
        strokes: <BorderStroke>[stroke, ...additionalStrokes],
        alignment: BorderStrokeAlignment.gridEdges,
      ),
      lineSide: lineSide,
      paramsOverride: source.feature.paramsOverride,
      overrides: overrides,
      keepOutRegions: const <BorderKeepOutRegion>[],
    ),
    visualSnapshots: source.visualSnapshots,
    resolverVersion: source.resolverVersion,
  );
}

BorderResolutionRequest _twoTierRequestWithParameters(
  BorderResolutionRequest source,
  BorderGenerationParams parameters,
) =>
    BorderResolutionRequest(
      mapSize: source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: source.feature.seed,
        geometry: source.feature.geometry,
        lineSide: source.feature.lineSide,
        paramsOverride: parameters,
        overrides: source.feature.overrides,
        keepOutRegions: source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

List<BorderResolvedPlacement> _twoTierPlacementsForStrokeLineage({
  required BorderResolutionRequest request,
  required BorderResolutionResult result,
  required BorderStroke stroke,
}) {
  final lineage = borderStrokeLineageNamespaceV1(stroke.id);
  var totalLengthPx = 0;
  for (var index = 1; index < stroke.points.length; index += 1) {
    final previous = stroke.points[index - 1];
    final current = stroke.points[index];
    totalLengthPx += (current.x - previous.x).abs() * request.tileSizePx.width +
        (current.y - previous.y).abs() * request.tileSizePx.height;
  }
  final possibleSlots = <String>{
    for (var distance = 0; distance <= totalLengthPx; distance += 1)
      for (final passAndRole in const <(int, BorderPrimitiveRole)>[
        (0, BorderPrimitiveRole.structureLarge),
        (1, BorderPrimitiveRole.structureMedium),
      ])
        for (final rank in const <int>[0, 1])
          buildBorderStoneChainDistanceSlotKey(
            featureId: request.feature.id,
            strokeId: lineage,
            runStart: stroke.points.first,
            runEnd: stroke.points.last,
            canonicalDistancePx: distance,
            passIndex: passAndRole.$1,
            role: passAndRole.$2,
            rank: rank,
          ),
    for (final vertex in stroke.points)
      for (final passAndRole in const <(int, BorderPrimitiveRole)>[
        (0, BorderPrimitiveRole.structureLarge),
        (0, BorderPrimitiveRole.lineCorner),
        (0, BorderPrimitiveRole.lineCap),
        (1, BorderPrimitiveRole.structureMedium),
      ])
        for (final rank in const <int>[0, 1, 2, 3])
          buildBorderStoneChainNodeSlotKey(
            featureId: request.feature.id,
            strokeId: lineage,
            vertex: vertex,
            passIndex: passAndRole.$1,
            role: passAndRole.$2,
            rank: rank,
          ),
  };
  return result.materialization!.placements
      .where((placement) => possibleSlots.contains(placement.slotKey))
      .toList(growable: false);
}

void _expectTwoTierTurnRecipe({
  required BorderResolutionRequest request,
  required BorderResolutionResult result,
  required BorderStroke stroke,
  required GridPos vertex,
}) {
  final lineage = borderStrokeLineageNamespaceV1(stroke.id);
  final lipSlot = buildBorderStoneChainNodeSlotKey(
    featureId: request.feature.id,
    strokeId: lineage,
    vertex: vertex,
    passIndex: 0,
    role: BorderPrimitiveRole.lineCorner,
    rank: 0,
  );
  final incomingFaceSlot = buildBorderStoneChainNodeSlotKey(
    featureId: request.feature.id,
    strokeId: lineage,
    vertex: vertex,
    passIndex: 1,
    role: BorderPrimitiveRole.structureMedium,
    rank: 0,
  );
  final outgoingFaceSlot = buildBorderStoneChainNodeSlotKey(
    featureId: request.feature.id,
    strokeId: lineage,
    vertex: vertex,
    passIndex: 1,
    role: BorderPrimitiveRole.structureMedium,
    rank: 1,
  );
  final placementsBySlot = <String, BorderResolvedPlacement>{
    for (final placement in result.materialization!.placements)
      placement.slotKey: placement,
  };
  expect(
    placementsBySlot.keys,
    containsAll(<String>[lipSlot, incomingFaceSlot, outgoingFaceSlot]),
    reason: '$vertex must reserve one lip corner and both face shoulders',
  );
  final primitiveRoles = <String, BorderPrimitiveRole>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive.role,
  };
  expect(
    primitiveRoles[placementsBySlot[lipSlot]!.primitiveId],
    anyOf(BorderPrimitiveRole.lineCorner, BorderPrimitiveRole.structureLarge),
  );
  for (final slot in <String>[incomingFaceSlot, outgoingFaceSlot]) {
    final shoulder = placementsBySlot[slot]!;
    expect(
      primitiveRoles[shoulder.primitiveId],
      BorderPrimitiveRole.structureMedium,
    );
    expect(shoulder.stableOrderKey.passIndex, 1);
    expect(shoulder.drawBand, BorderDrawBand.outerAccent);
  }
  expect(placementsBySlot[lipSlot]!.stableOrderKey.passIndex, 0);
  expect(placementsBySlot[lipSlot]!.drawBand, BorderDrawBand.structure);
}

int _twoTierOpaqueComponentCount(List<BorderResolvedPlacement> placements) {
  if (placements.isEmpty) return 0;
  final unseen = <int>{
    for (var index = 0; index < placements.length; index++) index
  };
  var components = 0;
  while (unseen.isNotEmpty) {
    components += 1;
    final pending = <int>[unseen.first];
    unseen.remove(pending.single);
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      final attached = <int>[
        for (final candidate in unseen)
          if (_opaqueRectGapForTest(
                placements[current].opaqueWorldBoundsPx,
                placements[candidate].opaqueWorldBoundsPx,
              ) ==
              0)
            candidate,
      ];
      unseen.removeAll(attached);
      pending.addAll(attached);
    }
  }
  return components;
}

int _twoTierTrueMaskComponentCount(
  BorderResolutionRequest request,
  List<BorderResolvedPlacement> placements,
) {
  if (placements.isEmpty) return 0;
  final primitiveById = <String, BorderPublishedPrimitive>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive,
  };
  return measureStoneChainRowContinuity(
    samples: <StoneChainRowSample>[
      for (var index = 0; index < placements.length; index += 1)
        StoneChainRowSample(
          strokeId: 'component:$index',
          slotKey: placements[index].slotKey,
          pathDistancePx: 0,
          closed: false,
          mask: StoneChainPlacedMask(
            metrics:
                primitiveById[placements[index].primitiveId]!.publishedMetrics,
            transform: placements[index].transform,
            topLeftWorldPx: placements[index].topLeftWorldPx,
          ),
        ),
    ],
    tangent: StoneChainAxis(dx: 1, dy: 0),
    normal: StoneChainAxis(dx: 0, dy: 1),
  ).connectedComponentCount;
}

String _diagnosticSummary(BorderResolutionResult result) => result.diagnostics
    .map((item) => '${item.code}:${item.cell}:${item.parameters}')
    .join(', ');

const String _historicalDepthRowsOneOutputFingerprint =
    'sha256:4dd23dc294dec88a432a897109d970075f2c072d6d47e2fb30c17cd1177cb5b9';

BorderPublishedPrimitive _withNarrowTwoTierTangentMask(
  BorderPublishedPrimitive primitive, {
  required int tangentSpanPx,
}) {
  final metrics = primitive.publishedMetrics;
  final bounds = metrics.opaqueBounds;
  final narrowBounds = switch (primitive.authoredOrientation) {
    BorderPrimitiveOrientation.north ||
    BorderPrimitiveOrientation.south =>
      BorderPixelRect(
        x: bounds.x + (bounds.width - tangentSpanPx) ~/ 2,
        y: bounds.y,
        width: tangentSpanPx,
        height: bounds.height,
      ),
    BorderPrimitiveOrientation.east ||
    BorderPrimitiveOrientation.west =>
      BorderPixelRect(
        x: bounds.x,
        y: bounds.y + (bounds.height - tangentSpanPx) ~/ 2,
        width: bounds.width,
        height: tangentSpanPx,
      ),
    BorderPrimitiveOrientation.legacyAxis => throw StateError(
        'The two-tier fixture never publishes legacy structural axes.',
      ),
  };
  final mask = List<bool>.filled(
    metrics.pixelSize.width * metrics.pixelSize.height,
    false,
  );
  for (var y = narrowBounds.y; y < narrowBounds.bottom; y += 1) {
    for (var x = narrowBounds.x; x < narrowBounds.right; x += 1) {
      mask[y * metrics.pixelSize.width + x] = true;
    }
  }
  return _copyTwoTierPrimitive(
    primitive,
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: metrics.assetFingerprint,
      pixelSize: metrics.pixelSize,
      opaqueBounds: metrics.opaqueBounds,
      defaultAnchorPx: metrics.defaultAnchorPx,
      occupancyMaskRle: encodeBorderRleMask(mask),
    ),
  );
}

List<int> _twoTierRankOneDistancesForSlotKeys(
  BorderResolutionRequest request,
  Set<String> slotKeys,
) {
  final stroke =
      (request.feature.geometry as BorderStrokeGeometry).strokes.single;
  final lineage = resolveBorderStrokeLineageIdentityV1(stroke);
  var totalLengthPx = 0;
  for (var index = 1; index < stroke.points.length; index += 1) {
    final previous = stroke.points[index - 1];
    final current = stroke.points[index];
    totalLengthPx += (current.x - previous.x).abs() * request.tileSizePx.width +
        (current.y - previous.y).abs() * request.tileSizePx.height;
  }
  return <int>[
    for (var distance = 0; distance <= totalLengthPx; distance += 1)
      if (slotKeys.contains(
        buildBorderStoneChainDistanceSlotKey(
          featureId: request.feature.id,
          strokeId: lineage.lineageNamespace,
          runStart: stroke.points.first,
          runEnd: stroke.points.last,
          canonicalDistancePx: distance,
          passIndex: 0,
          role: BorderPrimitiveRole.structureLarge,
          rank: 1,
        ),
      ))
        distance,
  ];
}

BorderResolutionRequest _twoTierShortStraightRequest(
  TwoTierStoneChainFixture fixture, {
  bool reverseAuthoredTraversal = false,
}) {
  final points = <GridPos>[
    const GridPos(x: 4, y: 15),
    const GridPos(x: 5, y: 15),
    const GridPos(x: 6, y: 15),
  ];
  final authoredPoints = reverseAuthoredTraversal
      ? points.reversed.toList(growable: false)
      : points;
  final stroke = BorderStroke(
    id: buildBorderPreservedStrokeIdV1(
      authoredStrokeId: 'two-tier-short-backfill',
      sourceEdgeOffset: 0,
      wrapLength: null,
      orderedPoints: authoredPoints,
    ),
    points: authoredPoints,
    closed: false,
  );
  return BorderResolutionRequest(
    mapSize: fixture.request.mapSize,
    tileSizePx: fixture.request.tileSizePx,
    blueprintId: fixture.request.blueprintId,
    blueprintRevision: fixture.blueprintRevision,
    feature: BorderFeature(
      id: fixture.request.feature.id,
      name: fixture.request.feature.name,
      blueprintId: fixture.request.feature.blueprintId,
      seed: fixture.request.feature.seed,
      geometry: BorderStrokeGeometry(
        strokes: <BorderStroke>[stroke],
        alignment: BorderStrokeAlignment.gridEdges,
      ),
      lineSide: reverseAuthoredTraversal
          ? BorderLineSide.inverted
          : fixture.request.feature.lineSide,
      paramsOverride: fixture.parameters,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    ),
    visualSnapshots: fixture.snapshots,
    resolverVersion: borderResolverVersion,
  );
}

List<BorderPublishedPrimitive> _twoTierFillerPrimitives({
  required int weight,
}) {
  final structural = twoTierStoneChainPublishedPrimitives();
  final result = <BorderPublishedPrimitive>[];
  var ordinal = 900;
  for (final orientation in twoTierStoneChainCardinalOrientations) {
    final fingerprint = ordinal.toRadixString(16).padLeft(64, '0');
    ordinal += 1;
    result.add(
      _copyTwoTierPrimitive(
        structural.firstWhere(
          (primitive) =>
              primitive.role == BorderPrimitiveRole.structureLarge &&
              primitive.authoredOrientation == orientation,
        ),
        id: 'two-tier-filler-${orientation.name}',
        role: BorderPrimitiveRole.filler,
        weight: weight,
        visualSnapshotId: 'border-snapshot-sha256:$fingerprint',
      ),
    );
  }
  return result;
}

List<BorderPublishedPrimitive> _twoTierSuccessfulBackfillPrimitives() {
  final primitives = twoTierStoneChainPublishedPrimitives();
  return <BorderPublishedPrimitive>[
    for (final primitive in primitives)
      if (primitive.role == BorderPrimitiveRole.structureLarge &&
          primitive.authoredOrientation == BorderPrimitiveOrientation.south)
        _withTwoTierTangentProfile(
          primitive,
          opaqueTangentSpanPx: primitive.publishedMetrics.opaqueBounds.width,
          occupiedTangentSpanPx: 4,
        )
      else
        primitive,
  ];
}

List<BorderPublishedPrimitive> _twoTierBroadBoundsNarrowMaskPrimitives() {
  return <BorderPublishedPrimitive>[
    for (final primitive in twoTierStoneChainPublishedPrimitives())
      if (primitive.role == BorderPrimitiveRole.structureLarge &&
          primitive.authoredOrientation == BorderPrimitiveOrientation.south)
        _withTwoTierTangentProfile(
          primitive,
          opaqueTangentSpanPx: 24,
          occupiedTangentSpanPx: 16,
        )
      else
        primitive,
  ];
}

List<BorderPublishedPrimitive> _twoTierProjectionOnlyLipFallbackPrimitives() {
  final source = twoTierStoneChainPublishedPrimitives();
  final result = <BorderPublishedPrimitive>[
    for (final primitive in source)
      if (primitive.role == BorderPrimitiveRole.structureLarge &&
          primitive.id.endsWith('-1'))
        _withTwoTierDiagonalTangentMask(primitive)
      else
        primitive,
  ];
  var snapshotOrdinal = 500;
  for (final orientation in twoTierStoneChainCardinalOrientations) {
    final structural = source.firstWhere(
      (primitive) =>
          primitive.role == BorderPrimitiveRole.structureLarge &&
          primitive.authoredOrientation == orientation,
    );
    for (final role in const <BorderPrimitiveRole>[
      BorderPrimitiveRole.lineCorner,
      BorderPrimitiveRole.lineCap,
    ]) {
      final fingerprint = snapshotOrdinal.toRadixString(16).padLeft(64, '0');
      snapshotOrdinal += 1;
      result.add(
        _copyTwoTierPrimitive(
          structural,
          id: 'alpha-${role.name}-${orientation.name}',
          role: role,
          visualSnapshotId: 'border-snapshot-sha256:$fingerprint',
        ),
      );
    }
  }
  return result;
}

BorderPublishedPrimitive _withTwoTierDiagonalTangentMask(
  BorderPublishedPrimitive primitive,
) {
  final metrics = primitive.publishedMetrics;
  final bounds = metrics.opaqueBounds;
  final horizontalTangent =
      primitive.authoredOrientation == BorderPrimitiveOrientation.north ||
          primitive.authoredOrientation == BorderPrimitiveOrientation.south;
  final tangentSpan = horizontalTangent ? bounds.width : bounds.height;
  final normalSpan = horizontalTangent ? bounds.height : bounds.width;
  final mask = List<bool>.filled(
    metrics.pixelSize.width * metrics.pixelSize.height,
    false,
  );
  var previousNormal = 0;
  for (var tangent = 0; tangent < tangentSpan; tangent += 1) {
    final normal = tangent * (normalSpan - 1) ~/ (tangentSpan - 1);
    final start = normal < previousNormal ? normal : previousNormal;
    final end = normal > previousNormal ? normal : previousNormal;
    for (var step = start; step <= end; step += 1) {
      final x = horizontalTangent ? bounds.x + tangent : bounds.x + step;
      final y = horizontalTangent ? bounds.y + step : bounds.y + tangent;
      mask[y * metrics.pixelSize.width + x] = true;
    }
    previousNormal = normal;
  }
  return _copyTwoTierPrimitive(
    primitive,
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: metrics.assetFingerprint,
      pixelSize: metrics.pixelSize,
      opaqueBounds: bounds,
      defaultAnchorPx: metrics.defaultAnchorPx,
      occupancyMaskRle: encodeBorderRleMask(mask),
    ),
  );
}

List<BorderPublishedPrimitive> _twoTierFullMaskLipPrimitives() {
  return <BorderPublishedPrimitive>[
    for (final primitive in twoTierStoneChainPublishedPrimitives())
      if (primitive.role == BorderPrimitiveRole.structureLarge)
        _copyTwoTierPrimitive(
          primitive,
          publishedMetrics: BorderPrimitiveAssetMetrics(
            assetFingerprint: primitive.publishedMetrics.assetFingerprint,
            pixelSize: twoTierStoneChainCanvasSize,
            opaqueBounds: BorderPixelRect(
              x: 0,
              y: 0,
              width: 32,
              height: 32,
            ),
            defaultAnchorPx: primitive.publishedMetrics.defaultAnchorPx,
            occupancyMaskRle: encodeBorderRleMask(
              List<bool>.filled(32 * 32, true),
            ),
          ),
        )
      else
        primitive,
  ];
}

BorderResolutionRequest _twoTierLongStraightRequest({
  required int edgeCount,
  List<BorderPublishedPrimitive>? publishedPrimitives,
}) {
  final fixture = TwoTierStoneChainFixture(
    normal: BorderCardinalDirection.south,
    detailDensityPermille: 0,
    publishedPrimitives: publishedPrimitives,
  );
  final points = <GridPos>[
    for (var x = 1; x <= edgeCount + 1; x += 1) GridPos(x: x, y: 15),
  ];
  final stroke = BorderStroke(
    id: buildBorderPreservedStrokeIdV1(
      authoredStrokeId: 'two-tier-long-preflight',
      sourceEdgeOffset: 0,
      wrapLength: null,
      orderedPoints: points,
    ),
    points: points,
    closed: false,
  );
  return BorderResolutionRequest(
    mapSize: GridSize(width: edgeCount + 3, height: 30),
    tileSizePx: twoTierStoneChainCanvasSize,
    blueprintId: fixture.request.blueprintId,
    blueprintRevision: fixture.blueprintRevision,
    feature: BorderFeature(
      id: fixture.request.feature.id,
      name: fixture.request.feature.name,
      blueprintId: fixture.request.feature.blueprintId,
      seed: fixture.request.feature.seed,
      geometry: BorderStrokeGeometry(
        strokes: <BorderStroke>[stroke],
        alignment: BorderStrokeAlignment.gridEdges,
      ),
      lineSide: fixture.request.feature.lineSide,
      paramsOverride: fixture.parameters,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    ),
    visualSnapshots: fixture.snapshots,
    resolverVersion: borderResolverVersion,
  );
}

BorderPublishedPrimitive _withTwoTierTangentProfile(
  BorderPublishedPrimitive primitive, {
  required int opaqueTangentSpanPx,
  required int occupiedTangentSpanPx,
}) {
  final metrics = primitive.publishedMetrics;
  final sourceBounds = metrics.opaqueBounds;
  final opaqueBounds = BorderPixelRect(
    x: sourceBounds.x + (sourceBounds.width - opaqueTangentSpanPx) ~/ 2,
    y: sourceBounds.y,
    width: opaqueTangentSpanPx,
    height: sourceBounds.height,
  );
  final occupiedBounds = BorderPixelRect(
    x: opaqueBounds.x + (opaqueBounds.width - occupiedTangentSpanPx) ~/ 2,
    y: opaqueBounds.y,
    width: occupiedTangentSpanPx,
    height: opaqueBounds.height,
  );
  final mask = List<bool>.filled(
    metrics.pixelSize.width * metrics.pixelSize.height,
    false,
  );
  for (var y = occupiedBounds.y; y < occupiedBounds.bottom; y += 1) {
    for (var x = occupiedBounds.x; x < occupiedBounds.right; x += 1) {
      mask[y * metrics.pixelSize.width + x] = true;
    }
  }
  return _copyTwoTierPrimitive(
    primitive,
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: metrics.assetFingerprint,
      pixelSize: metrics.pixelSize,
      opaqueBounds: opaqueBounds,
      defaultAnchorPx: metrics.defaultAnchorPx,
      occupancyMaskRle: encodeBorderRleMask(mask),
    ),
  );
}

BorderPublishedPrimitive _copyTwoTierPrimitive(
  BorderPublishedPrimitive primitive, {
  String? id,
  String? visualSnapshotId,
  BorderPrimitiveRole? role,
  BorderPrimitiveOrientation? authoredOrientation,
  int? weight,
  BorderPrimitiveAssetMetrics? publishedMetrics,
}) {
  final resolvedId = id ?? primitive.id;
  final metrics = publishedMetrics ?? primitive.publishedMetrics;
  return BorderPublishedPrimitive(
    id: resolvedId,
    sourceElementId: 'element-$resolvedId',
    visualSnapshotId: visualSnapshotId ?? primitive.visualSnapshotId,
    role: role ?? primitive.role,
    authoredOrientation: authoredOrientation ?? primitive.authoredOrientation,
    weight: weight ?? primitive.weight,
    anchorPx: primitive.anchorPx,
    transforms: primitive.transforms,
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: 'asset-$resolvedId',
      pixelSize: metrics.pixelSize,
      opaqueBounds: metrics.opaqueBounds,
      defaultAnchorPx: metrics.defaultAnchorPx,
      occupancyMaskRle: metrics.occupancyMaskRle,
    ),
  );
}

({TwoTierStoneChainFixture fixture, BorderResolutionResult result})
    _resolveTwoTier({
  required BorderCardinalDirection normal,
  BorderLineSide lineSide = BorderLineSide.primary,
  bool allowAutoRotation = false,
  int detailDensityPermille = 1000,
  List<BorderPublishedPrimitive>? publishedPrimitives,
}) {
  final fixture = TwoTierStoneChainFixture(
    normal: normal,
    lineSide: lineSide,
    allowAutoRotation: allowAutoRotation,
    detailDensityPermille: detailDensityPermille,
    publishedPrimitives: publishedPrimitives,
  );
  final result = resolveStoneChainLineBorder(fixture.request);
  expect(
    result.canApply,
    isTrue,
    reason: '$normal/$lineSide/rotation=$allowAutoRotation: '
        '${result.diagnostics.map((item) => '${item.code}:${item.parameters}').join(', ')}',
  );
  return (fixture: fixture, result: result);
}

List<BorderResolvedPlacement> lipPlacements(
  BorderResolutionRequest request,
  BorderResolutionResult result,
) =>
    _twoTierPlacementsWithRole(
      request,
      result,
      BorderPrimitiveRole.structureLarge,
    );

List<BorderResolvedPlacement> facePlacements(
  BorderResolutionRequest request,
  BorderResolutionResult result,
) =>
    _twoTierPlacementsWithRole(
      request,
      result,
      BorderPrimitiveRole.structureMedium,
    );

int _maximumPrimitiveRunLength(List<BorderResolvedPlacement> placements) {
  var maximumRunLength = 0;
  var currentRunLength = 0;
  String? previousPrimitiveId;
  for (final placement in placements) {
    if (placement.primitiveId == previousPrimitiveId) {
      currentRunLength += 1;
    } else {
      previousPrimitiveId = placement.primitiveId;
      currentRunLength = 1;
    }
    if (currentRunLength > maximumRunLength) {
      maximumRunLength = currentRunLength;
    }
  }
  return maximumRunLength;
}

void assertGaplessRow({
  required BorderResolutionRequest request,
  required List<BorderResolvedPlacement> placements,
  required StoneChainAxis tangent,
  required StoneChainAxis normal,
  required String label,
}) {
  expect(placements, isNotEmpty, reason: '$label placements');
  final continuity = _twoTierRowContinuity(
    request: request,
    placements: placements,
    tangent: tangent,
    normal: normal,
  );
  expect(continuity.maximumGapPx, 0, reason: label);
  expect(continuity.connectedComponentCount, 1, reason: label);
}

void assertCrossRowInterlock({
  required BorderResolutionRequest request,
  required List<BorderResolvedPlacement> lips,
  required List<BorderResolvedPlacement> faces,
  required StoneChainAxis tangent,
  required StoneChainAxis normal,
  required String label,
}) {
  expect(lips, isNotEmpty, reason: '$label lips');
  expect(faces, isNotEmpty, reason: '$label faces');
  final primitiveById = _twoTierPrimitiveById(request);
  for (final face in faces) {
    final faceMask = _twoTierPlacedMask(face, primitiveById);
    final maximumIntersection = lips
        .map(
          (lip) => measureStoneChainContact(
            first: faceMask,
            second: _twoTierPlacedMask(lip, primitiveById),
            tangent: tangent,
            normal: normal,
          ).opaqueIntersectionPixels,
        )
        .reduce(_maxInt);
    expect(
      maximumIntersection,
      greaterThan(0),
      reason: '$label ${face.slotKey}',
    );
  }
}

void assertFaceBeforeLip({
  required BorderResolutionRequest request,
  required List<BorderResolvedPlacement> placements,
  required String label,
}) {
  final roleById = <String, BorderPrimitiveRole>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive.role,
  };
  final faceIndices = <int>[
    for (var index = 0; index < placements.length; index += 1)
      if (roleById[placements[index].primitiveId] ==
          BorderPrimitiveRole.structureMedium)
        index,
  ];
  final lipIndices = <int>[
    for (var index = 0; index < placements.length; index += 1)
      if (roleById[placements[index].primitiveId] ==
          BorderPrimitiveRole.structureLarge)
        index,
  ];
  expect(faceIndices, isNotEmpty, reason: '$label faces');
  expect(lipIndices, isNotEmpty, reason: '$label lips');
  expect(
    faceIndices.reduce(_maxInt),
    lessThan(lipIndices.reduce(_minInt)),
    reason: '$label materialization draw order',
  );
}

List<BorderResolvedPlacement> _twoTierPlacementsWithRole(
  BorderResolutionRequest request,
  BorderResolutionResult result,
  BorderPrimitiveRole role,
) {
  final primitiveIds = <String>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      if (primitive.role == role) primitive.id,
  };
  return result.materialization!.placements
      .where((placement) => primitiveIds.contains(placement.primitiveId))
      .toList(growable: false);
}

Map<String, BorderPublishedPrimitive> _twoTierPrimitiveById(
  BorderResolutionRequest request,
) =>
    <String, BorderPublishedPrimitive>{
      for (final primitive in request.blueprintRevision!.definition.primitives)
        primitive.id: primitive,
    };

StoneChainPlacedMask _twoTierPlacedMask(
  BorderResolvedPlacement placement,
  Map<String, BorderPublishedPrimitive> primitiveById,
) {
  final primitive = primitiveById[placement.primitiveId]!;
  return StoneChainPlacedMask(
    metrics: primitive.publishedMetrics,
    transform: placement.transform,
    topLeftWorldPx: placement.topLeftWorldPx,
  );
}

StoneChainRowContinuity _twoTierRowContinuity({
  required BorderResolutionRequest request,
  required List<BorderResolvedPlacement> placements,
  required StoneChainAxis tangent,
  required StoneChainAxis normal,
}) {
  final primitiveById = _twoTierPrimitiveById(request);
  final ordered = _twoTierOrderedAlong(placements, tangent);
  return measureStoneChainRowContinuity(
    samples: <StoneChainRowSample>[
      for (var index = 0; index < ordered.length; index += 1)
        StoneChainRowSample(
          strokeId: 'two-tier-row',
          slotKey: ordered[index].slotKey,
          pathDistancePx: index,
          closed: false,
          mask: _twoTierPlacedMask(ordered[index], primitiveById),
        ),
    ],
    tangent: tangent,
    normal: normal,
  );
}

List<BorderResolvedPlacement> _twoTierOrderedAlong(
  List<BorderResolvedPlacement> placements,
  StoneChainAxis tangent,
) =>
    placements.toList(growable: false)
      ..sort((left, right) {
        final byProjection = _twoTierMinimumProjection(left, tangent)
            .compareTo(_twoTierMinimumProjection(right, tangent));
        return byProjection != 0
            ? byProjection
            : left.slotKey.compareTo(right.slotKey);
      });

Set<int> _twoTierJointCoordinates(
  List<BorderResolvedPlacement> placements,
  StoneChainAxis tangent,
) {
  final ordered = _twoTierOrderedAlong(placements, tangent);
  return <int>{
    for (var index = 1; index < ordered.length; index += 1)
      (_twoTierMaximumProjection(ordered[index - 1], tangent) +
              _twoTierMinimumProjection(ordered[index], tangent)) ~/
          2,
  };
}

int _twoTierMinimumProjection(
  BorderResolvedPlacement placement,
  StoneChainAxis axis,
) =>
    _twoTierBoundsProjections(placement.opaqueWorldBoundsPx, axis)
        .reduce(_minInt);

int _twoTierMaximumProjection(
  BorderResolvedPlacement placement,
  StoneChainAxis axis,
) =>
    _twoTierBoundsProjections(placement.opaqueWorldBoundsPx, axis)
        .reduce(_maxInt);

List<int> _twoTierBoundsProjections(
  BorderPixelRect bounds,
  StoneChainAxis axis,
) =>
    <int>[
      for (final point in <(int, int)>[
        (bounds.x, bounds.y),
        (bounds.right - 1, bounds.y),
        (bounds.x, bounds.bottom - 1),
        (bounds.right - 1, bounds.bottom - 1),
      ])
        point.$1 * axis.dx + point.$2 * axis.dy,
    ];

StoneChainAxis _twoTierNormalAxis(BorderCardinalDirection normal) =>
    switch (normal) {
      BorderCardinalDirection.north => StoneChainAxis(dx: 0, dy: -1),
      BorderCardinalDirection.east => StoneChainAxis(dx: 1, dy: 0),
      BorderCardinalDirection.south => StoneChainAxis(dx: 0, dy: 1),
      BorderCardinalDirection.west => StoneChainAxis(dx: -1, dy: 0),
    };

StoneChainAxis _twoTierTangentAxis(BorderCardinalDirection normal) =>
    switch (normal) {
      BorderCardinalDirection.north => StoneChainAxis(dx: -1, dy: 0),
      BorderCardinalDirection.east => StoneChainAxis(dx: 0, dy: -1),
      BorderCardinalDirection.south => StoneChainAxis(dx: 1, dy: 0),
      BorderCardinalDirection.west => StoneChainAxis(dx: 0, dy: 1),
    };

BorderPrimitiveOrientation _rotateTwoTierOrientation(
  BorderPrimitiveOrientation source,
  int quarterTurns,
) {
  final index = twoTierStoneChainCardinalOrientations.indexOf(source);
  if (index < 0) return source;
  return twoTierStoneChainCardinalOrientations[
      (index + quarterTurns) % twoTierStoneChainCardinalOrientations.length];
}

Set<String> _twoTierSlotKeys(BorderResolutionResult result) =>
    result.materialization!.placements
        .map((placement) => placement.slotKey)
        .toSet();

BorderStroke _stroke(String id, List<GridPos> points) =>
    BorderStroke(id: id, points: points, closed: false);

List<BorderResolvedPlacement> _placementsWithRole(
  BorderResolutionRequest request,
  BorderResolutionResult result,
  BorderPrimitiveRole role,
) {
  final ids = <String>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      if (primitive.role == role) primitive.id,
  };
  return result.materialization!.placements
      .where((placement) => ids.contains(placement.primitiveId))
      .toList(growable: false);
}

Set<String> _codes(BorderResolutionResult result) =>
    result.diagnostics.map((value) => value.code).toSet();

int _maximumHorizontalOpaqueGap(List<BorderResolvedPlacement> placements) {
  final ordered = placements.toList(growable: false)
    ..sort((left, right) => left.opaqueWorldBoundsPx.x.compareTo(
          right.opaqueWorldBoundsPx.x,
        ));
  var maximum = 0;
  for (var index = 1; index < ordered.length; index += 1) {
    final gap = ordered[index].opaqueWorldBoundsPx.x -
        ordered[index - 1].opaqueWorldBoundsPx.right;
    if (gap > maximum) maximum = gap;
  }
  return maximum;
}

List<BorderResolvedPlacement> _placementsOrderedAroundLoop(
  List<BorderResolvedPlacement> placements,
  BorderStroke stroke,
  GridSize tileSizePx,
) {
  final distances = <BorderResolvedPlacement, double>{};
  var cumulative = 0.0;
  final edges = <({GridPos start, GridPos end, double startDistance})>[];
  for (var index = 0; index < stroke.points.length; index += 1) {
    final start = stroke.points[index];
    final end = stroke.points[(index + 1) % stroke.points.length];
    edges.add((start: start, end: end, startDistance: cumulative));
    cumulative += start.x == end.x ? tileSizePx.height : tileSizePx.width;
  }
  for (final placement in placements) {
    final bounds = placement.opaqueWorldBoundsPx;
    final centerX = bounds.x + bounds.width / 2;
    final centerY = bounds.y + bounds.height / 2;
    var bestSquaredDistance = double.infinity;
    var bestPathDistance = 0.0;
    for (final edge in edges) {
      final startX = edge.start.x * tileSizePx.width.toDouble();
      final startY = edge.start.y * tileSizePx.height.toDouble();
      final endX = edge.end.x * tileSizePx.width.toDouble();
      final endY = edge.end.y * tileSizePx.height.toDouble();
      final horizontal = startY == endY;
      final projectedX = horizontal
          ? centerX.clamp(
              startX < endX ? startX : endX,
              startX < endX ? endX : startX,
            )
          : startX;
      final projectedY = horizontal
          ? startY
          : centerY.clamp(
              startY < endY ? startY : endY,
              startY < endY ? endY : startY,
            );
      final dx = centerX - projectedX;
      final dy = centerY - projectedY;
      final squaredDistance = dx * dx + dy * dy;
      if (squaredDistance >= bestSquaredDistance) continue;
      bestSquaredDistance = squaredDistance;
      final along = horizontal
          ? (projectedX - startX).abs()
          : (projectedY - startY).abs();
      bestPathDistance = edge.startDistance + along;
    }
    distances[placement] = bestPathDistance;
  }
  return placements.toList(growable: false)
    ..sort((left, right) {
      final byDistance = distances[left]!.compareTo(distances[right]!);
      return byDistance != 0
          ? byDistance
          : left.slotKey.compareTo(right.slotKey);
    });
}

int _maximumOrderedOpaqueGap(
  List<BorderResolvedPlacement> placements, {
  required bool includeClosingPair,
}) {
  var maximum = 0;
  final pairCount =
      includeClosingPair ? placements.length : placements.length - 1;
  for (var index = 0; index < pairCount; index += 1) {
    final next = (index + 1) % placements.length;
    final gap = _opaqueRectGapForTest(
      placements[index].opaqueWorldBoundsPx,
      placements[next].opaqueWorldBoundsPx,
    );
    if (gap > maximum) maximum = gap;
  }
  return maximum;
}

int _opaqueRectGapForTest(BorderPixelRect first, BorderPixelRect second) {
  final gapX = _maxInt(
    0,
    _maxInt(first.x, second.x) - _minInt(first.right, second.right),
  );
  final gapY = _maxInt(
    0,
    _maxInt(first.y, second.y) - _minInt(first.bottom, second.bottom),
  );
  return _maxInt(gapX, gapY);
}

void _expectNoShortRepeatingPrimitiveBlocks(
  List<String> primitiveIds, {
  required String reasonPrefix,
  required List<String> debugLabels,
}) {
  bool sameBlock(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index += 1) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  for (var index = 1; index < primitiveIds.length; index += 1) {
    expect(
      primitiveIds[index],
      isNot(primitiveIds[index - 1]),
      reason: '$reasonPrefix repeats ${primitiveIds[index]} adjacently at '
          'row index $index: '
          '${debugLabels.sublist(_maxInt(0, index - 3), _minInt(debugLabels.length, index + 4))}',
    );
  }
  for (var blockLength = 2; blockLength <= 4; blockLength += 1) {
    for (var end = blockLength * 2; end <= primitiveIds.length; end += 1) {
      final first = primitiveIds.sublist(
        end - blockLength * 2,
        end - blockLength,
      );
      final second = primitiveIds.sublist(end - blockLength, end);
      expect(
        sameBlock(first, second),
        isFalse,
        reason: '$reasonPrefix repeats the $blockLength-stone block $first '
            'twice at row index $end: '
            '${debugLabels.sublist(_maxInt(0, end - blockLength * 2 - 1), _minInt(debugLabels.length, end + 1))}',
      );
    }
  }
}

int _minInt(int left, int right) => left < right ? left : right;
int _maxInt(int left, int right) => left > right ? left : right;

int _measuredCornerThicknessRatio(
  BorderResolutionRequest request,
  List<BorderResolvedPlacement> placements,
) {
  final rolesById = <String, BorderPrimitiveRole>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive.role,
  };
  int thickness(BorderResolvedPlacement placement) {
    final bounds = placement.opaqueWorldBoundsPx;
    return bounds.width < bounds.height ? bounds.width : bounds.height;
  }

  final straight = placements
      .where((placement) {
        final role = rolesById[placement.primitiveId];
        return role == BorderPrimitiveRole.structureLarge;
      })
      .map(thickness)
      .toList(growable: false)
    ..sort();
  final corners = placements
      .where(
        (placement) =>
            rolesById[placement.primitiveId] == BorderPrimitiveRole.lineCorner,
      )
      .map(thickness)
      .toList(growable: false);
  if (straight.isEmpty || corners.isEmpty) return 0;
  final middle = straight.length ~/ 2;
  final median = straight.length.isOdd
      ? straight[middle]
      : (straight[middle - 1] + straight[middle]) ~/ 2;
  final maximumCorner =
      corners.reduce((left, right) => left > right ? left : right);
  return maximumCorner * 1000 ~/ median;
}

int _maximumPairwiseOpaqueOverlap(
  List<BorderResolvedPlacement> placements,
) {
  var maximum = 0;
  for (var leftIndex = 0; leftIndex < placements.length; leftIndex += 1) {
    final left = placements[leftIndex].opaqueWorldBoundsPx;
    for (var rightIndex = leftIndex + 1;
        rightIndex < placements.length;
        rightIndex += 1) {
      final right = placements[rightIndex].opaqueWorldBoundsPx;
      final overlapX = _positiveMinimum(
        left.right < right.right ? left.right : right.right,
        left.x > right.x ? left.x : right.x,
      );
      final overlapY = _positiveMinimum(
        left.bottom < right.bottom ? left.bottom : right.bottom,
        left.y > right.y ? left.y : right.y,
      );
      final overlap = overlapX < overlapY ? overlapX : overlapY;
      if (overlap > maximum) maximum = overlap;
    }
  }
  return maximum;
}

int _positiveMinimum(int upper, int lower) {
  final value = upper - lower;
  return value > 0 ? value : 0;
}
