import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/selbrume_two_tier_stone_chain_v4_fixture.dart';

void main() {
  group('strict canonical two-tier run plan', () {
    for (final topologyCase in _canonicalPlanCases()) {
      test(
        '${topologyCase.name} keeps identical slots for side and rotation profiles',
        () {
          final results = <String, BorderResolutionResult>{};
          for (final profile in _canonicalPlanProfiles()) {
            final result = resolveStoneChainLineBorder(
              selbrumeTwoTierNeckRequest(
                featureId: 'neck-plan-${topologyCase.name}',
                geometry: BorderStrokeGeometry(
                  strokes: <BorderStroke>[topologyCase.stroke],
                  alignment: BorderStrokeAlignment.gridEdges,
                ),
                lineSide: profile.lineSide,
                allowAutoRotation: profile.allowAutoRotation,
              ),
            );
            expect(
              result.canApply,
              isTrue,
              reason: '${topologyCase.name}/${profile.name}: '
                  '${_diagnostics(result.diagnosticReport)}',
            );
            results[profile.name] = result;
          }

          final expectedSlots = _slotKeys(results['primary-off']!);
          for (final entry in results.entries) {
            expect(
              _slotKeys(entry.value),
              expectedSlots,
              reason: '${topologyCase.name}/${entry.key}',
            );
          }

          expect(
            results['primary-on']!.materialization!.placements.any(
                  (placement) => placement.transform.quarterTurns != 0,
                ),
            isTrue,
            reason: '${topologyCase.name} rotation-on must exercise a real '
                'profile-specific transform while preserving slots.',
          );
        },
      );

      test('${topologyCase.name} never emits an adaptive rank-one lineage key',
          () {
        final adaptiveKeys = _rankOneLineageKeys(
          featureId: 'neck-plan-${topologyCase.name}',
          stroke: topologyCase.stroke,
        );
        for (final profile in _canonicalPlanProfiles()) {
          final result = resolveStoneChainLineBorder(
            selbrumeTwoTierNeckRequest(
              featureId: 'neck-plan-${topologyCase.name}',
              geometry: BorderStrokeGeometry(
                strokes: <BorderStroke>[topologyCase.stroke],
                alignment: BorderStrokeAlignment.gridEdges,
              ),
              lineSide: profile.lineSide,
              allowAutoRotation: profile.allowAutoRotation,
            ),
          );
          expect(result.canApply, isTrue, reason: profile.name);
          expect(
            _slotKeys(result).intersection(adaptiveKeys),
            isEmpty,
            reason: '${topologyCase.name}/${profile.name}: topology closure '
                'must not invent a rank-one midpoint slot.',
          );
        }
      });

      test('${topologyCase.name} keeps ordinary stations on lineage rank zero',
          () {
        final bridgeKeys = _lineageKeysForRanks(
          featureId: 'neck-plan-${topologyCase.name}',
          stroke: topologyCase.stroke,
          ranks: const <int>[2, 3],
        );
        for (final profile in _canonicalPlanProfiles()) {
          final result = resolveStoneChainLineBorder(
            selbrumeTwoTierNeckRequest(
              featureId: 'neck-plan-${topologyCase.name}',
              geometry: BorderStrokeGeometry(
                strokes: <BorderStroke>[topologyCase.stroke],
                alignment: BorderStrokeAlignment.gridEdges,
              ),
              lineSide: profile.lineSide,
              allowAutoRotation: profile.allowAutoRotation,
            ),
          );
          expect(result.canApply, isTrue, reason: profile.name);
          expect(
            _slotKeys(result).intersection(bridgeKeys),
            isEmpty,
            reason: '${topologyCase.name}/${profile.name}: uniform ordinary '
                'stations must keep the canonical rank-zero lineage.',
          );
        }
      });
    }

    test('rejects an excessive topology overlap budget before planning', () {
      final topologyCase = _canonicalPlanCases().first;
      final result = resolveStoneChainLineBorder(
        selbrumeTwoTierNeckRequest(
          featureId: 'neck-plan-overlap-budget',
          geometry: BorderStrokeGeometry(
            strokes: <BorderStroke>[topologyCase.stroke],
            alignment: BorderStrokeAlignment.gridEdges,
          ),
          lineSide: BorderLineSide.primary,
          allowAutoRotation: false,
          maxOverlapPx: 10,
        ),
      );

      expect(result.canApply, isFalse);
      final diagnostic = result.diagnostics.singleWhere(
        (item) =>
            item.code ==
            'border.resolution.stone_chain_planner_budget_exceeded',
      );
      expect(diagnostic.parameters['observedMaximumOverlapPx'], 10);
      expect(diagnostic.parameters['expectedMaximumOverlapPx'], 8);
      expect(diagnostic.parameters['minimumStructuralTangentSpanPx'], 10);
    });

    test('one-cell zigzag keeps one canonical midpoint and stable slots', () {
      final stroke = _oneCellZigzag();
      final results = <String, BorderResolutionResult>{};
      for (final profile in _canonicalPlanProfiles()) {
        final request = selbrumeTwoTierNeckRequest(
          featureId: 'neck-plan-one-cell',
          geometry: BorderStrokeGeometry(
            strokes: <BorderStroke>[stroke],
            alignment: BorderStrokeAlignment.gridEdges,
          ),
          lineSide: profile.lineSide,
          allowAutoRotation: profile.allowAutoRotation,
        );
        final result = resolveStoneChainLineBorder(request);
        expect(
          result.canApply,
          isTrue,
          reason: '${profile.name}: ${_diagnostics(result.diagnosticReport)}',
        );
        _expectTurnShoulderInterlock(
          request: request,
          result: result,
          stroke: stroke,
          turnVertexIndexes: const <int>[4, 5, 6, 7],
          minimumPixels: 8,
          label: profile.name,
        );
        results[profile.name] = result;
      }

      final expectedSlots = _slotKeys(results['primary-off']!);
      final midpointSlots = _oneCellMidpointKeys(
        featureId: 'neck-plan-one-cell',
        stroke: stroke,
      );
      final rankOneSlots = _rankOneLineageKeys(
        featureId: 'neck-plan-one-cell',
        stroke: stroke,
      );
      for (final entry in results.entries) {
        final slots = _slotKeys(entry.value);
        expect(slots, expectedSlots, reason: entry.key);
        expect(slots, containsAll(midpointSlots), reason: entry.key);
        expect(slots.intersection(rankOneSlots), isEmpty, reason: entry.key);
      }
    });

    test('two-edge turn run keeps one bounded plan across profiles', () {
      final stroke = _shortSBend();
      final results = <String, BorderResolutionResult>{};
      for (final profile in _canonicalPlanProfiles()) {
        final request = selbrumeTwoTierNeckRequest(
          featureId: 'neck-plan-two-edge-turn',
          geometry: BorderStrokeGeometry(
            strokes: <BorderStroke>[stroke],
            alignment: BorderStrokeAlignment.gridEdges,
          ),
          lineSide: profile.lineSide,
          allowAutoRotation: profile.allowAutoRotation,
        );
        final result = resolveStoneChainLineBorder(request);
        expect(
          result.canApply,
          isTrue,
          reason: '${profile.name}: ${_diagnostics(result.diagnosticReport)}',
        );
        _expectTopologyNormalizedFaceLipRatio(
          request: request,
          result: result,
          stroke: stroke,
          label: profile.name,
          expectCompleteTurnPairs: true,
        );
        results[profile.name] = result;
      }

      final expectedSlots = _slotKeys(results['primary-off']!);
      final nonCanonicalSlots = _lineageKeysForRanks(
        featureId: 'neck-plan-two-edge-turn',
        stroke: stroke,
        ranks: const <int>[1, 2, 3],
      );
      for (final entry in results.entries) {
        final slots = _slotKeys(entry.value);
        expect(slots, expectedSlots, reason: entry.key);
        expect(slots.intersection(nonCanonicalSlots), isEmpty,
            reason: entry.key);
      }
    });
  });

  test('real V4 alpha masks connect turn shoulders and open caps', () {
    for (final topologyCase in _openTopologyCases()) {
      for (final side in BorderLineSide.values) {
        final request = selbrumeTwoTierV4Request(
          featureId: 'real-v4-${topologyCase.name}-${side.name}',
          geometry: BorderStrokeGeometry(
            strokes: <BorderStroke>[topologyCase.stroke],
            alignment: BorderStrokeAlignment.gridEdges,
          ),
          lineSide: side,
        );
        final result = resolveStoneChainLineBorder(request);

        expect(
          result.canApply,
          isTrue,
          reason: '${topologyCase.name} ${side.name}: '
              '${_diagnostics(result.diagnosticReport)}',
        );
        expect(result.materialization!.placements, isNotEmpty);
        _expectEveryFaceHasAlphaContact(
          request,
          result,
          '${topologyCase.name} ${side.name}',
        );
        _expectTopologyNormalizedFaceLipRatio(
          request: request,
          result: result,
          stroke: topologyCase.stroke,
          label: '${topologyCase.name} ${side.name}',
          expectCompleteTurnPairs: true,
        );
      }
    }
  });

  test('real V4 alpha masks close both loop rows on both sides', () {
    for (final side in BorderLineSide.values) {
      final request = selbrumeTwoTierV4Request(
        featureId: 'real-v4-loop-${side.name}',
        geometry: BorderStrokeGeometry(
          strokes: <BorderStroke>[_closedLoop()],
          alignment: BorderStrokeAlignment.gridEdges,
        ),
        lineSide: side,
      );
      final result = resolveStoneChainLineBorder(request);

      expect(
        result.canApply,
        isTrue,
        reason: '${side.name}: ${_diagnostics(result.diagnosticReport)}',
      );
      expect(result.materialization!.placements, isNotEmpty);
      _expectEveryFaceHasAlphaContact(request, result, 'loop ${side.name}');
      _expectTopologyNormalizedFaceLipRatio(
        request: request,
        result: result,
        stroke: _closedLoop(),
        label: 'loop ${side.name}',
        expectCompleteTurnPairs: true,
      );
    }
  });

  test('real V4 straight cap materializations remain byte-for-byte stable', () {
    final fingerprints = <String, String>{};
    for (final straightCase in _straightCases()) {
      for (final side in BorderLineSide.values) {
        final key = '${straightCase.name}:${side.name}';
        final result = resolveStoneChainLineBorder(
          selbrumeTwoTierV4Request(
            featureId: 'real-v4-straight-$key',
            geometry: BorderStrokeGeometry(
              strokes: <BorderStroke>[straightCase.stroke],
              alignment: BorderStrokeAlignment.gridEdges,
            ),
            lineSide: side,
          ),
        );
        expect(result.canApply, isTrue, reason: key);
        fingerprints[key] = result.materialization!.receipt.outputFingerprint;
      }
    }

    expect(fingerprints, const <String, String>{
      'horizontal:primary':
          'sha256:b28757bcb9574a49c111b92c199c41e65718378ee8caee929ca7aa67f0d779e9',
      'horizontal:inverted':
          'sha256:69b9cdcfbc0333818bea04d7956270be7a2174793428e9af85c3facc3d8c1d88',
      'vertical:primary':
          'sha256:c34dea16818528d69bc56ed4df7bc40a45b5e7c8ba3335cf9ba3139350b69a47',
      'vertical:inverted':
          'sha256:c6cdacb97f43bb1c5afae94883f4fd4986e6f3a22925fb9ff5bfbde20dc13fd0',
    });
  });
}

List<({String name, BorderStroke stroke})> _canonicalPlanCases() =>
    <({String name, BorderStroke stroke})>[
      (
        name: 'l-shape',
        stroke: _stroke('canonical-plan-l', <GridPos>[
          for (var x = 2; x <= 10; x += 1) GridPos(x: x, y: 2),
          for (var y = 3; y <= 9; y += 1) GridPos(x: 10, y: y),
        ]),
      ),
      (
        name: 's-shape',
        stroke: _stroke('canonical-plan-s', <GridPos>[
          for (var x = 2; x <= 7; x += 1) GridPos(x: x, y: 2),
          for (var y = 3; y <= 7; y += 1) GridPos(x: 7, y: y),
          for (var x = 8; x <= 13; x += 1) GridPos(x: x, y: 7),
        ]),
      ),
    ];

List<
    ({
      String name,
      BorderLineSide lineSide,
      bool allowAutoRotation,
    })> _canonicalPlanProfiles() => <({
      String name,
      BorderLineSide lineSide,
      bool allowAutoRotation,
    })>[
      (
        name: 'primary-off',
        lineSide: BorderLineSide.primary,
        allowAutoRotation: false,
      ),
      (
        name: 'inverted-off',
        lineSide: BorderLineSide.inverted,
        allowAutoRotation: false,
      ),
      (
        name: 'primary-on',
        lineSide: BorderLineSide.primary,
        allowAutoRotation: true,
      ),
      (
        name: 'inverted-on',
        lineSide: BorderLineSide.inverted,
        allowAutoRotation: true,
      ),
    ];

Set<String> _slotKeys(BorderResolutionResult result) =>
    result.materialization!.placements
        .map((placement) => placement.slotKey)
        .toSet();

Set<String> _rankOneLineageKeys({
  required String featureId,
  required BorderStroke stroke,
}) =>
    _lineageKeysForRanks(
      featureId: featureId,
      stroke: stroke,
      ranks: const <int>[1],
    );

Set<String> _lineageKeysForRanks({
  required String featureId,
  required BorderStroke stroke,
  required List<int> ranks,
}) {
  final result = <String>{};
  final strokeId = borderStrokeLineageNamespaceV1(stroke.id);
  for (var edgeIndex = 0;
      edgeIndex < stroke.points.length - 1;
      edgeIndex += 1) {
    final start = stroke.points[edgeIndex];
    final end = stroke.points[edgeIndex + 1];
    for (var offset = 0; offset <= 32; offset += 1) {
      for (final rank in ranks) {
        result.add(
          buildBorderStoneChainLineageStationSlotKey(
            featureId: featureId,
            strokeId: strokeId,
            edgeStart: start,
            edgeEnd: end,
            generationEdgeIndex: edgeIndex,
            canonicalEdgeOffsetPx: offset,
            passIndex: 0,
            role: BorderPrimitiveRole.structureLarge,
            rank: rank,
          ),
        );
        result.add(
          buildBorderStoneChainLineageStationSlotKey(
            featureId: featureId,
            strokeId: strokeId,
            edgeStart: start,
            edgeEnd: end,
            generationEdgeIndex: edgeIndex,
            canonicalEdgeOffsetPx: offset,
            passIndex: 1,
            role: BorderPrimitiveRole.structureMedium,
            rank: rank,
          ),
        );
      }
    }
  }
  return result;
}

Set<String> _oneCellMidpointKeys({
  required String featureId,
  required BorderStroke stroke,
}) {
  final result = <String>{};
  final strokeId = borderStrokeLineageNamespaceV1(stroke.id);
  for (final edgeIndex in const <int>[4, 5, 6]) {
    for (final pass in const <({
      int index,
      BorderPrimitiveRole role,
    })>[
      (index: 0, role: BorderPrimitiveRole.structureLarge),
      (index: 1, role: BorderPrimitiveRole.structureMedium),
    ]) {
      result.add(
        buildBorderStoneChainLineageStationSlotKey(
          featureId: featureId,
          strokeId: strokeId,
          edgeStart: stroke.points[edgeIndex],
          edgeEnd: stroke.points[edgeIndex + 1],
          generationEdgeIndex: edgeIndex,
          canonicalEdgeOffsetPx: 16,
          passIndex: pass.index,
          role: pass.role,
          rank: 0,
        ),
      );
    }
  }
  return result;
}

List<({String name, BorderStroke stroke})> _openTopologyCases() =>
    <({String name, BorderStroke stroke})>[
      (
        name: 'convex-l',
        stroke: _stroke('convex-l', const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 4, y: 2),
          GridPos(x: 4, y: 3),
          GridPos(x: 4, y: 4),
          GridPos(x: 4, y: 5),
        ]),
      ),
      (
        name: 'concave-l',
        stroke: _stroke('concave-l', const <GridPos>[
          GridPos(x: 10, y: 4),
          GridPos(x: 10, y: 5),
          GridPos(x: 10, y: 6),
          GridPos(x: 10, y: 7),
          GridPos(x: 9, y: 7),
          GridPos(x: 8, y: 7),
          GridPos(x: 7, y: 7),
        ]),
      ),
      (
        name: 's-bend',
        stroke: _stroke('s-bend', const <GridPos>[
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
        ]),
      ),
    ];

List<({String name, BorderStroke stroke})> _straightCases() =>
    <({String name, BorderStroke stroke})>[
      (
        name: 'horizontal',
        stroke: _stroke('horizontal', <GridPos>[
          for (var x = 1; x <= 10; x += 1) GridPos(x: x, y: 3),
        ]),
      ),
      (
        name: 'vertical',
        stroke: _stroke('vertical', <GridPos>[
          for (var y = 1; y <= 8; y += 1) GridPos(x: 11, y: y),
        ]),
      ),
    ];

BorderStroke _closedLoop() => BorderStroke(
      id: 'closed-loop',
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
    );

BorderStroke _oneCellZigzag() => _stroke(
      'one-cell-zigzag',
      <GridPos>[
        for (var x = 3; x <= 7; x += 1) GridPos(x: x, y: 5),
        const GridPos(x: 7, y: 6),
        const GridPos(x: 8, y: 6),
        const GridPos(x: 8, y: 7),
        for (var x = 9; x <= 13; x += 1) GridPos(x: x, y: 7),
      ],
    );

BorderStroke _shortSBend() => _stroke(
      'short-s-bend',
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

BorderStroke _stroke(String id, List<GridPos> points) => BorderStroke(
      id: id,
      points: points,
      closed: false,
    );

int _completeTurnFacePairCount({
  required String featureId,
  required BorderStroke stroke,
  required Set<String> placementSlotKeys,
}) {
  var count = 0;
  final firstTurnIndex = stroke.closed ? 0 : 1;
  final endTurnIndex =
      stroke.closed ? stroke.points.length : stroke.points.length - 1;
  final strokeId = borderStrokeLineageNamespaceV1(stroke.id);
  for (var index = firstTurnIndex; index < endTurnIndex; index += 1) {
    final previous = stroke
        .points[(index - 1 + stroke.points.length) % stroke.points.length];
    final vertex = stroke.points[index];
    final next = stroke.points[(index + 1) % stroke.points.length];
    final incomingX = vertex.x - previous.x;
    final incomingY = vertex.y - previous.y;
    final outgoingX = next.x - vertex.x;
    final outgoingY = next.y - vertex.y;
    if (incomingX == outgoingX && incomingY == outgoingY) continue;

    bool hasShoulder(int rank) => placementSlotKeys.contains(
          buildBorderStoneChainNodeSlotKey(
            featureId: featureId,
            strokeId: strokeId,
            vertex: vertex,
            passIndex: 1,
            role: BorderPrimitiveRole.structureMedium,
            rank: rank,
          ),
        );
    if (hasShoulder(0) && hasShoulder(1)) count += 1;
  }
  return count;
}

void _expectTopologyNormalizedFaceLipRatio({
  required BorderResolutionRequest request,
  required BorderResolutionResult result,
  required BorderStroke stroke,
  required String label,
  required bool expectCompleteTurnPairs,
}) {
  final primitives = <String, BorderPublishedPrimitive>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive,
  };
  final placements = result.materialization!.placements;
  final lipCount = placements
      .where(
        (placement) =>
            primitives[placement.primitiveId]!.role ==
            BorderPrimitiveRole.structureLarge,
      )
      .length;
  final faceCount = placements
      .where(
        (placement) =>
            primitives[placement.primitiveId]!.role ==
            BorderPrimitiveRole.structureMedium,
      )
      .length;
  final completeTurnFacePairCount = _completeTurnFacePairCount(
    featureId: request.feature.id,
    stroke: stroke,
    placementSlotKeys: placements.map((placement) => placement.slotKey).toSet(),
  );
  final logicalFaceCount = faceCount - completeTurnFacePairCount;

  expect(lipCount, greaterThan(0), reason: '$label raw lip count');
  expect(faceCount, greaterThan(0), reason: '$label raw face count');
  expect(
    completeTurnFacePairCount,
    expectCompleteTurnPairs ? greaterThan(0) : 0,
    reason: '$label complete turn face pairs',
  );
  expect(
    logicalFaceCount,
    greaterThanOrEqualTo(0),
    reason: '$label logical face count',
  );
  expect(
    logicalFaceCount * 1000 ~/ lipCount,
    inInclusiveRange(800, 1150),
    reason: '$label topology-normalized face/lip ratio.',
  );
}

void _expectTurnShoulderInterlock({
  required BorderResolutionRequest request,
  required BorderResolutionResult result,
  required BorderStroke stroke,
  required List<int> turnVertexIndexes,
  required int minimumPixels,
  required String label,
}) {
  final primitives = <String, BorderPublishedPrimitive>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive,
  };
  final placements = <String, BorderResolvedPlacement>{
    for (final placement in result.materialization!.placements)
      placement.slotKey: placement,
  };
  final strokeId = borderStrokeLineageNamespaceV1(stroke.id);
  for (final vertexIndex in turnVertexIndexes) {
    final vertex = stroke.points[vertexIndex];
    final lip = placements[buildBorderStoneChainNodeSlotKey(
      featureId: request.feature.id,
      strokeId: strokeId,
      vertex: vertex,
      passIndex: 0,
      role: BorderPrimitiveRole.lineCorner,
      rank: 0,
    )]!;
    for (final rank in const <int>[0, 1]) {
      final shoulder = placements[buildBorderStoneChainNodeSlotKey(
        featureId: request.feature.id,
        strokeId: strokeId,
        vertex: vertex,
        passIndex: 1,
        role: BorderPrimitiveRole.structureMedium,
        rank: rank,
      )]!;
      expect(
        _alphaInterlock(lip, shoulder, primitives),
        greaterThanOrEqualTo(minimumPixels),
        reason: '$label $vertex shoulder rank $rank',
      );
    }
  }
}

void _expectEveryFaceHasAlphaContact(
  BorderResolutionRequest request,
  BorderResolutionResult result,
  String label,
) {
  final primitives = <String, BorderPublishedPrimitive>{
    for (final primitive in request.blueprintRevision!.definition.primitives)
      primitive.id: primitive,
  };
  final placements = result.materialization!.placements;
  final faces = placements
      .where(
        (placement) =>
            primitives[placement.primitiveId]!.role ==
            BorderPrimitiveRole.structureMedium,
      )
      .toList(growable: false);
  final lips = placements
      .where(
        (placement) =>
            primitives[placement.primitiveId]!.role !=
            BorderPrimitiveRole.structureMedium,
      )
      .toList(growable: false);
  expect(faces, isNotEmpty, reason: '$label must materialize a face row.');
  for (final face in faces) {
    final contactsLip = lips.any(
      (lip) => _alphaInterlock(face, lip, primitives) > 0,
    );
    final contactsShoulder = faces.any(
      (other) =>
          other.slotKey != face.slotKey &&
          _alphaInterlock(face, other, primitives) > 0,
    );
    expect(
      contactsLip || contactsShoulder,
      isTrue,
      reason: '$label ${face.slotKey} must touch a lip or face shoulder.',
    );
  }
}

int _alphaInterlock(
  BorderResolvedPlacement first,
  BorderResolvedPlacement second,
  Map<String, BorderPublishedPrimitive> primitives,
) =>
    measureStoneChainContact(
      first: _placedMask(first, primitives[first.primitiveId]!),
      second: _placedMask(second, primitives[second.primitiveId]!),
      tangent: StoneChainAxis(dx: 1, dy: 0),
      normal: StoneChainAxis(dx: 0, dy: 1),
    ).opaqueIntersectionPixels;

StoneChainPlacedMask _placedMask(
  BorderResolvedPlacement placement,
  BorderPublishedPrimitive primitive,
) =>
    StoneChainPlacedMask(
      metrics: primitive.publishedMetrics,
      transform: placement.transform,
      topLeftWorldPx: placement.topLeftWorldPx,
    );

String _diagnostics(BorderDiagnosticsReport report) => report.diagnostics
    .map(
      (diagnostic) => '${diagnostic.severity.name}: ${diagnostic.code} '
          '${diagnostic.parameters}',
    )
    .join('\n');
