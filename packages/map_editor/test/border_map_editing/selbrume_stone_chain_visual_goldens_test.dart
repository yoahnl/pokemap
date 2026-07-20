import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../fixtures/border/stone_chain_visual_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'published Selbrume stone chain passes structural gates before eight goldens',
    () async {
      final fixture = await StoneChainVisualFixture.load();
      addTearDown(fixture.dispose);

      expect(fixture.publishedRevision.revision, greaterThanOrEqualTo(1));
      expect(fixture.publishedRevision.definition.primitives, isNotEmpty);
      expect(
        fixture.cases.map((item) => item.id),
        orderedEquals(const <String>[
          'horizontal',
          'vertical',
          'l_primary',
          'l_inverted',
          's_primary',
          'closed_loop',
          's_inverted',
          'l_auto_rotation',
        ]),
      );

      final resolutions = <StoneChainVisualCaseResolution>[
        for (final visualCase in fixture.cases) fixture.resolve(visualCase),
      ];
      final lCase = fixture.cases.singleWhere((item) => item.id == 'l_primary');
      StoneChainVisualCase rotationProbe(bool enabled) => StoneChainVisualCase(
            id: 'l_rotation_slot_probe',
            goldenFile: lCase.goldenFile,
            points: lCase.points,
            turnVertices: lCase.turnVertices,
            closed: lCase.closed,
            lineSide: lCase.lineSide,
            rotationEnabled: enabled,
          );
      final rotationOff = fixture.resolve(rotationProbe(false));
      final rotationOn = fixture.resolve(rotationProbe(true));
      expect(rotationOff.evidence.result.canApply, isTrue);
      expect(rotationOn.evidence.result.canApply, isTrue);
      _expectMeasurableStructure(fixture, rotationOff);
      _expectMeasurableStructure(fixture, rotationOn);
      final offPlacements =
          rotationOff.evidence.result.materialization!.placements;
      final onPlacements =
          rotationOn.evidence.result.materialization!.placements;
      final offSlots =
          offPlacements.map((placement) => placement.slotKey).toSet();
      final onSlots =
          onPlacements.map((placement) => placement.slotKey).toSet();
      final onlyOffPlacements = offPlacements
          .where((item) => offSlots.difference(onSlots).contains(item.slotKey))
          .toList(growable: false);
      final onlyOffBounds = onlyOffPlacements
          .map((placement) => placement.opaqueWorldBoundsPx)
          .toList(growable: false);
      expect(
        onSlots,
        offSlots,
        reason: 'Selbrume slots must survive auto-rotation ON/OFF. '
            'Only OFF: ${offSlots.difference(onSlots)}; '
            'only ON: ${onSlots.difference(offSlots)}. '
            'OFF placements: ${_placementSummary(onlyOffPlacements)}; '
            'ON placements: ${_placementSummary(onPlacements.where((item) => onSlots.difference(offSlots).contains(item.slotKey)).toList(growable: false))}. '
            'OFF nearby: ${_placementSummary(_placementsNearBounds(offPlacements, onlyOffBounds, radiusPx: 32))}. '
            'ON nearby: ${_placementSummary(_placementsNearBounds(onPlacements, onlyOffBounds, radiusPx: 32))}. '
            'OFF depth: ${_placementSummary(offPlacements.where((item) => item.stableOrderKey.passIndex == 1).toList(growable: false))}. '
            'ON depth: ${_placementSummary(onPlacements.where((item) => item.stableOrderKey.passIndex == 1).toList(growable: false))}.',
      );
      expect(
        offPlacements
            .every((placement) => placement.transform.quarterTurns == 0),
        isTrue,
      );
      expect(
        onPlacements.any((placement) => placement.transform.quarterTurns == 1),
        isTrue,
      );
      final commonSlot = (offSlots.toList(growable: false)..sort()).first;
      final suppressedOverride = BorderSlotOverride(
        slotKey: commonSlot,
        variationSalt: BorderSignedInt64.zero,
        suppressed: true,
        locked: false,
      );
      for (final overridden in <StoneChainVisualCaseResolution>[
        fixture.resolve(
          rotationProbe(false),
          overrides: <BorderSlotOverride>[suppressedOverride],
        ),
        fixture.resolve(
          rotationProbe(true),
          overrides: <BorderSlotOverride>[suppressedOverride],
        ),
      ]) {
        expect(overridden.evidence.result.canApply, isTrue);
        expect(
          overridden.evidence.result.materialization!.placements
              .map((placement) => placement.slotKey),
          isNot(contains(commonSlot)),
        );
      }

      // Structural gates deliberately precede every pixel comparison. When
      // one fails, --update-goldens cannot bless a visually invalid layout.
      for (final resolution in resolutions) {
        _expectMeasurableStructure(fixture, resolution);
      }

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

void _expectMeasurableStructure(
  StoneChainVisualFixture fixture,
  StoneChainVisualCaseResolution resolution,
) {
  final visualCase = resolution.visualCase;
  final evidence = resolution.evidence;
  final result = evidence.result;
  final reason = '${visualCase.id}: ${resolution.diagnostics}';

  expect(result.canApply, isTrue, reason: reason);
  expect(result.materialization, isNotNull, reason: reason);
  final placements = result.materialization!.placements;
  expect(placements, isNotEmpty, reason: reason);
  expect(
    placements.map((item) => item.slotKey).toSet(),
    hasLength(placements.length),
    reason: '${visualCase.id}: every placement needs a unique stable slot.',
  );
  expect(
    placements.map((item) => item.id).toSet(),
    hasLength(placements.length),
    reason: '${visualCase.id}: placement ids must be unique.',
  );

  expect(
    evidence.placementsPerSegmentPermille,
    inInclusiveRange(1500, 2250),
    reason: '${visualCase.id}: expected 1.5–2.25 chain stones per 32 px.',
  );
  // A placement is indivisible. Round the 2.6-per-edge budget upward once,
  // otherwise the 20% secondary minimum and the total-density maximum are
  // mathematically incompatible on the 16-edge S fixtures (41.6 placements).
  final maximumQuantizedPlacementCount =
      (resolution.edgeCount * 2600 + 999) ~/ 1000;
  expect(
    placements.length,
    lessThanOrEqualTo(maximumQuantizedPlacementCount),
    reason: '${visualCase.id}: total density must stay at or below 2.6/edge.',
  );
  final secondaryRatioPermille =
      evidence.secondaryPlacementCount * 1000 ~/ evidence.primaryPlacementCount;
  expect(
    secondaryRatioPermille,
    inInclusiveRange(200, 350),
    reason: '${visualCase.id}: secondary stones must be 20–35% of primaries '
        '(secondary=${evidence.secondaryPlacementCount}, '
        'primary=${evidence.primaryPlacementCount}).',
  );
  expect(
    evidence.maximumGapPx,
    lessThanOrEqualTo(resolution.parameters.gapTolerancePx),
    reason: '${visualCase.id}: primary coverage contains a detached gap. '
        '${_placementSummary(resolution.primaryPlacements)}; connectors='
        '${_placementSummary(resolution.turnConnectorPlacements)}',
  );
  expect(
    evidence.maximumTangentOverlapPx,
    lessThanOrEqualTo(resolution.parameters.maxOverlapPx),
    reason: '${visualCase.id}: tangent overlap exceeded maxOverlapPx.',
  );
  expect(
    evidence.maximumCornerThicknessRatioPermille,
    lessThanOrEqualTo(1250),
    reason: '${visualCase.id}: corner thickness exceeds the 25% budget.',
  );
  expect(
    evidence.maximumRepeatedPrimitiveRunLength,
    lessThanOrEqualTo(2),
    reason: '${visualCase.id}: three identical primary stones repeat. '
        '${_placementSummary(resolution.primaryPlacements)}',
  );

  final primary = resolution.primaryPlacements;
  for (var start = 0; start + 8 <= primary.length; start += 1) {
    expect(
      primary
          .skip(start)
          .take(8)
          .map((item) => item.primitiveId)
          .toSet()
          .length,
      greaterThanOrEqualTo(3),
      reason: '${visualCase.id}: every eight-primary window needs 3 ids.',
    );
  }

  for (final placement in placements) {
    final allowed =
        fixture.allowedQuarterTurnsByPrimitiveId[placement.primitiveId]!;
    expect(
      allowed,
      contains(placement.transform.quarterTurns),
      reason: '${visualCase.id}: disallowed rotation on ${placement.id}.',
    );
    expect(
      placement.transform.flipX,
      isFalse,
      reason: '${visualCase.id}: stone pixels must never be flipped.',
    );
    expect(
      math.min(
        placement.opaqueWorldBoundsPx.width,
        placement.opaqueWorldBoundsPx.height,
      ),
      lessThanOrEqualTo(28),
      reason: '${visualCase.id}: opaque stone thickness exceeds 28 px.',
    );
  }
  if (visualCase.rotationEnabled) {
    expect(
      placements.map((item) => item.transform.quarterTurns),
      contains(1),
      reason: '${visualCase.id}: the vertical leg must exercise rotation.',
    );
  } else {
    expect(
      placements.map((item) => item.transform.quarterTurns),
      everyElement(0),
      reason: '${visualCase.id}: rotation-off must keep native pixels.',
    );
  }

  for (final turn in visualCase.turnVertices) {
    for (final incoming in <bool>[true, false]) {
      final expectedSlotKey = resolution.turnConnectorSlotKey(
        turn,
        incoming: incoming,
      );
      expect(
        resolution.turnConnectorPlacements
            .where((placement) => placement.slotKey == expectedSlotKey),
        hasLength(1),
        reason: '${visualCase.id}: every turn needs one small '
            '${incoming ? 'incoming' : 'outgoing'} connector stone at $turn. '
            '${_placementSummary(_placementsWithinRadius(placements, turn, radiusPx: 40))}',
      );
    }
    expect(
      _placementsWithinRadius(placements, turn, radiusPx: 16),
      hasLength(lessThanOrEqualTo(3)),
      reason: '${visualCase.id}: too many stones around turn $turn. '
          '${_placementSummary(_placementsWithinRadius(placements, turn, radiusPx: 16))}',
    );
  }

  if (visualCase.closed) {
    expect(resolution.capPlacements, isEmpty, reason: reason);
    expect(
      resolution.cornerPlacements,
      hasLength(visualCase.turnVertices.length),
      reason: '${visualCase.id}: one corner stone is required per turn.',
    );
    final seam = visualCase.points.first;
    final seamPlacements =
        _placementsWithinRadius(placements, seam, radiusPx: 16);
    expect(
      seamPlacements.map((item) => item.slotKey).toSet(),
      hasLength(seamPlacements.length),
      reason: '${visualCase.id}: loop seam contains a duplicate stone.',
    );
    expect(
      _maximumPairwiseOpaqueOverlap(seamPlacements),
      lessThanOrEqualTo(resolution.parameters.maxOverlapPx),
      reason: '${visualCase.id}: loop seam exceeds the overlap budget.',
    );
  } else {
    expect(
      resolution.capPlacements,
      hasLength(2),
      reason: '${visualCase.id}: both open endpoints need one cap.',
    );
    expect(
      resolution.cornerPlacements,
      hasLength(visualCase.turnVertices.length),
      reason: '${visualCase.id}: one corner stone is required per turn.',
    );
    for (final endpoint in <GridPos>[
      visualCase.points.first,
      visualCase.points.last,
    ]) {
      expect(
        _placementsWithinRadius(placements, endpoint, radiusPx: 16),
        hasLength(lessThanOrEqualTo(2)),
        reason: '${visualCase.id}: too many stones around endpoint $endpoint.',
      );
    }
    for (final cap in resolution.capPlacements) {
      final body = resolution.primaryPlacements
          .where((placement) => !resolution.capPlacements.contains(placement))
          .toList(growable: false);
      expect(
        body
            .map(
              (placement) => _opaqueRectGap(
                cap.opaqueWorldBoundsPx,
                placement.opaqueWorldBoundsPx,
              ),
            )
            .reduce(math.min),
        lessThanOrEqualTo(resolution.parameters.gapTolerancePx),
        reason:
            '${visualCase.id}: endpoint cap ${cap.primitiveId} is detached.',
      );
    }
  }
}

List<BorderResolvedPlacement> _placementsNearBounds(
  List<BorderResolvedPlacement> placements,
  List<BorderPixelRect> targets, {
  required int radiusPx,
}) =>
    placements.where((placement) {
      final bounds = placement.opaqueWorldBoundsPx;
      return targets.any(
        (target) => _opaqueRectGap(bounds, target) <= radiusPx,
      );
    }).toList(growable: false);

String _placementSummary(List<BorderResolvedPlacement> placements) => placements
    .map(
      (placement) => '${placement.primitiveId}@'
          '${placement.opaqueWorldBoundsPx.x},'
          '${placement.opaqueWorldBoundsPx.y},'
          '${placement.opaqueWorldBoundsPx.width}x'
          '${placement.opaqueWorldBoundsPx.height}'
          '[pass=${placement.stableOrderKey.passIndex}]',
    )
    .join(' | ');

int _opaqueRectGap(BorderPixelRect first, BorderPixelRect second) {
  final gapX = math.max<int>(
    0,
    math.max(first.x, second.x) - math.min(first.right, second.right),
  );
  final gapY = math.max<int>(
    0,
    math.max(first.y, second.y) - math.min(first.bottom, second.bottom),
  );
  return math.max(gapX, gapY);
}

List<BorderResolvedPlacement> _placementsWithinRadius(
  List<BorderResolvedPlacement> placements,
  GridPos vertex, {
  required int radiusPx,
}) {
  final x = vertex.x * stoneChainVisualTileSizePx;
  final y = vertex.y * stoneChainVisualTileSizePx;
  final radiusSquared = radiusPx * radiusPx;
  return placements.where((placement) {
    final bounds = placement.opaqueWorldBoundsPx;
    final centerX = bounds.x + bounds.width / 2;
    final centerY = bounds.y + bounds.height / 2;
    final dx = centerX - x;
    final dy = centerY - y;
    return dx * dx + dy * dy <= radiusSquared;
  }).toList(growable: false);
}

int _maximumPairwiseOpaqueOverlap(List<BorderResolvedPlacement> placements) {
  var maximum = 0;
  for (var leftIndex = 0; leftIndex < placements.length; leftIndex += 1) {
    final left = placements[leftIndex].opaqueWorldBoundsPx;
    for (var rightIndex = leftIndex + 1;
        rightIndex < placements.length;
        rightIndex += 1) {
      final right = placements[rightIndex].opaqueWorldBoundsPx;
      final overlapX = math.max<int>(
        0,
        math.min(left.right, right.right) - math.max(left.x, right.x),
      );
      final overlapY = math.max<int>(
        0,
        math.min(left.bottom, right.bottom) - math.max(left.y, right.y),
      );
      maximum = math.max(maximum, math.min(overlapX, overlapY));
    }
  }
  return maximum;
}
