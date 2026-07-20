import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/border_slot_key_golden.dart';

void main() {
  group('Border slot keys V1', () {
    test('matches the literal ASCII region preimage and digest', () {
      _expectFixtureDigest(borderAsciiRegionSlotKeyGolden);

      expect(
        buildBorderRegionSlotKey(
          featureId: 'feature-a',
          interiorCell: const GridPos(x: 2, y: 3),
          side: BorderCardinalDirection.east,
          passIndex: 0,
          role: BorderPrimitiveRole.structureLarge,
          rank: 1,
          ordinalLocal: 0,
        ),
        borderAsciiRegionSlotKeyGolden.key,
      );
    });

    test('matches the literal UTF-8 region preimage and digest', () {
      _expectFixtureDigest(borderRegionSlotKeyGolden);

      expect(
        buildBorderRegionSlotKey(
          featureId: 'feature-côte',
          interiorCell: const GridPos(x: 3, y: 5),
          side: BorderCardinalDirection.west,
          passIndex: 2,
          role: BorderPrimitiveRole.structureMedium,
          rank: 1,
          ordinalLocal: 4,
        ),
        borderRegionSlotKeyGolden.key,
      );
    });

    test('matches the literal UTF-8 line preimage and canonicalizes direction',
        () {
      _expectFixtureDigest(borderLineSlotKeyGolden);

      final forward = buildBorderLineSlotKey(
        featureId: 'feature-port',
        strokeId: 'stroke-🌊',
        edgeStart: const GridPos(x: 3, y: 2),
        edgeEnd: const GridPos(x: 4, y: 2),
        passIndex: 0,
        role: BorderPrimitiveRole.span,
        rank: 2,
        ordinalLocal: 1,
      );
      final reverse = buildBorderLineSlotKey(
        featureId: 'feature-port',
        strokeId: 'stroke-🌊',
        edgeStart: const GridPos(x: 4, y: 2),
        edgeEnd: const GridPos(x: 3, y: 2),
        passIndex: 0,
        role: BorderPrimitiveRole.span,
        rank: 2,
        ordinalLocal: 1,
      );

      expect(forward, borderLineSlotKeyGolden.key);
      expect(reverse, forward);
    });

    test('publishes explicit cardinal rank and wire mappings', () {
      expect(
        BorderCardinalDirection.values
            .map(borderCardinalDirectionV1Rank)
            .toList(),
        <int>[0, 1, 2, 3],
      );
      expect(
        BorderCardinalDirection.values
            .map(borderCardinalDirectionV1WireName)
            .toList(),
        <String>['east', 'south', 'west', 'north'],
      );
      expect(
        BorderPrimitiveRole.values.map(borderPrimitiveRoleV1WireName).toList(),
        <String>[
          'structureLarge',
          'structureMedium',
          'filler',
          'accent',
          'post',
          'span',
          'surfacePatch',
          'outerAccent',
          'lineCap',
          'lineStraight',
          'lineCorner',
        ],
      );
    });

    test('connected node identity ignores side and topology transitions', () {
      String keyFor({
        required BorderLineSide side,
        required BorderPrimitiveRole topologyRole,
      }) {
        // The public key intentionally has no side input. Keeping [side] in
        // this test helper makes the inversion compatibility contract explicit.
        expect(BorderLineSide.values, contains(side));
        return buildBorderConnectedLineNodeSlotKey(
          featureId: 'feature-cliff',
          strokeId: 'stroke-lineage',
          cell: const GridPos(x: 4, y: 7),
          passIndex: 0,
          role: topologyRole,
          rank: 0,
          ordinalLocal: 0,
        );
      }

      final primaryCap = keyFor(
        side: BorderLineSide.primary,
        topologyRole: BorderPrimitiveRole.lineCap,
      );
      final invertedStraight = keyFor(
        side: BorderLineSide.inverted,
        topologyRole: BorderPrimitiveRole.lineStraight,
      );
      final primaryCorner = keyFor(
        side: BorderLineSide.primary,
        topologyRole: BorderPrimitiveRole.lineCorner,
      );

      expect(invertedStraight, primaryCap);
      expect(primaryCorner, primaryCap);
      expect(
        buildBorderConnectedLineNodeSlotKey(
          featureId: 'feature-cliff',
          strokeId: 'stroke-lineage',
          cell: const GridPos(x: 5, y: 7),
          passIndex: 0,
          role: BorderPrimitiveRole.lineCap,
          rank: 0,
          ordinalLocal: 0,
        ),
        isNot(primaryCap),
      );
    });

    test('stone-chain station canonicalizes run direction', () {
      final forward = buildBorderStoneChainStationSlotKey(
        featureId: 'feature-cliff',
        strokeId: 'stroke-lineage',
        runStart: const GridPos(x: 2, y: 4),
        runEnd: const GridPos(x: 8, y: 4),
        stationOrdinal: 3,
        passIndex: 0,
        role: BorderPrimitiveRole.structureLarge,
        rank: 0,
      );
      final reverse = buildBorderStoneChainStationSlotKey(
        featureId: 'feature-cliff',
        strokeId: 'stroke-lineage',
        runStart: const GridPos(x: 8, y: 4),
        runEnd: const GridPos(x: 2, y: 4),
        stationOrdinal: 3,
        passIndex: 0,
        role: BorderPrimitiveRole.structureLarge,
        rank: 0,
      );

      expect(reverse, forward);
      expect(
        buildBorderStoneChainNodeSlotKey(
          featureId: 'feature-cliff',
          strokeId: 'stroke-lineage',
          vertex: const GridPos(x: 4, y: 4),
          passIndex: 0,
          role: BorderPrimitiveRole.lineCorner,
          rank: 1,
        ),
        isNot(forward),
      );
    });

    test('stone-chain distance slots canonicalize run endpoints', () {
      final forward = buildBorderStoneChainDistanceSlotKey(
        featureId: 'feature-cliff',
        strokeId: 'stroke-lineage',
        runStart: const GridPos(x: 2, y: 4),
        runEnd: const GridPos(x: 8, y: 4),
        canonicalDistancePx: 37,
        passIndex: 1,
        role: BorderPrimitiveRole.structureMedium,
        rank: 0,
      );
      final reverse = buildBorderStoneChainDistanceSlotKey(
        featureId: 'feature-cliff',
        strokeId: 'stroke-lineage',
        runStart: const GridPos(x: 8, y: 4),
        runEnd: const GridPos(x: 2, y: 4),
        canonicalDistancePx: 37,
        passIndex: 1,
        role: BorderPrimitiveRole.structureMedium,
        rank: 0,
      );

      expect(reverse, forward);
    });

    test('stone-chain distance slots include canonical distance', () {
      String keyAt(int distance) => buildBorderStoneChainDistanceSlotKey(
            featureId: 'feature-cliff',
            strokeId: 'stroke-lineage',
            runStart: const GridPos(x: 2, y: 4),
            runEnd: const GridPos(x: 8, y: 4),
            canonicalDistancePx: distance,
            passIndex: 1,
            role: BorderPrimitiveRole.structureMedium,
            rank: 0,
          );

      expect(keyAt(38), isNot(keyAt(37)));
    });

    test('stone-chain lineage stations survive split run endpoints', () {
      String station({
        GridPos edgeStart = const GridPos(x: 7, y: 4),
        GridPos edgeEnd = const GridPos(x: 8, y: 4),
        int passIndex = 1,
        BorderPrimitiveRole role = BorderPrimitiveRole.structureMedium,
      }) =>
          buildBorderStoneChainLineageStationSlotKey(
            featureId: 'feature-two-tier-cliff',
            strokeId: 'stroke-lineage',
            edgeStart: edgeStart,
            edgeEnd: edgeEnd,
            generationEdgeIndex: 17,
            canonicalEdgeOffsetPx: 9,
            passIndex: passIndex,
            role: role,
            rank: 0,
          );

      final beforeSplit = station();
      final afterSplit = station();
      final reversedTraversal = station(
        edgeStart: const GridPos(x: 8, y: 4),
        edgeEnd: const GridPos(x: 7, y: 4),
      );

      expect(afterSplit, beforeSplit);
      expect(reversedTraversal, beforeSplit);
      expect(
        station(
          passIndex: 0,
          role: BorderPrimitiveRole.structureLarge,
        ),
        isNot(beforeSplit),
      );
    });

    test('stone-chain distance slots reject invalid tuple fields', () {
      String build({
        String featureId = 'feature-cliff',
        int canonicalDistancePx = 37,
        int passIndex = 1,
        BorderPrimitiveRole role = BorderPrimitiveRole.structureMedium,
        int rank = 0,
      }) =>
          buildBorderStoneChainDistanceSlotKey(
            featureId: featureId,
            strokeId: 'stroke-lineage',
            runStart: const GridPos(x: 2, y: 4),
            runEnd: const GridPos(x: 8, y: 4),
            canonicalDistancePx: canonicalDistancePx,
            passIndex: passIndex,
            role: role,
            rank: rank,
          );

      for (final invocation in <void Function()>[
        () => build(featureId: ' feature-cliff'),
        () => build(canonicalDistancePx: -1),
        () => build(passIndex: -1),
        () => build(role: BorderPrimitiveRole.accent),
        () => build(rank: -1),
      ]) {
        expect(invocation, throwsA(isA<ValidationException>()));
      }
    });

    test('publishes resolver contract version 3', () {
      expect(borderResolverVersion, 3);
    });

    test('stone-chain row identities distinguish lip and face passes', () {
      String stationKey({
        required int passIndex,
        required BorderPrimitiveRole role,
      }) =>
          buildBorderStoneChainStationSlotKey(
            featureId: 'feature-two-tier-cliff',
            strokeId: 'stroke-lineage',
            runStart: const GridPos(x: 2, y: 4),
            runEnd: const GridPos(x: 8, y: 4),
            stationOrdinal: 64,
            passIndex: passIndex,
            role: role,
            rank: 0,
          );

      final lip = stationKey(
        passIndex: 0,
        role: BorderPrimitiveRole.structureLarge,
      );
      final face = stationKey(
        passIndex: 1,
        role: BorderPrimitiveRole.structureMedium,
      );

      expect(face, isNot(lip));
      expect(
        stationKey(
          passIndex: 0,
          role: BorderPrimitiveRole.structureLarge,
        ),
        lip,
      );
    });

    test('stone-chain keys reject roles outside the template matrix', () {
      expect(
        () => buildBorderStoneChainNodeSlotKey(
          featureId: 'feature-cliff',
          strokeId: 'stroke-lineage',
          vertex: const GridPos(x: 4, y: 4),
          passIndex: 0,
          role: BorderPrimitiveRole.accent,
          rank: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects unstable text, negative tuple values, and non-unit edges',
        () {
      expect(
        () => buildBorderRegionSlotKey(
          featureId: ' feature',
          interiorCell: const GridPos(x: 0, y: 0),
          side: BorderCardinalDirection.east,
          passIndex: 0,
          role: BorderPrimitiveRole.filler,
          rank: 0,
          ordinalLocal: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => buildBorderRegionSlotKey(
          featureId: 'feature',
          interiorCell: const GridPos(x: -1, y: 0),
          side: BorderCardinalDirection.east,
          passIndex: 0,
          role: BorderPrimitiveRole.filler,
          rank: 0,
          ordinalLocal: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => buildBorderRegionSlotKey(
          featureId: 'feature-${String.fromCharCode(0xd800)}',
          interiorCell: const GridPos(x: 0, y: 0),
          side: BorderCardinalDirection.east,
          passIndex: 0,
          role: BorderPrimitiveRole.filler,
          rank: 0,
          ordinalLocal: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => buildBorderLineSlotKey(
          featureId: 'feature',
          strokeId: 'stroke',
          edgeStart: const GridPos(x: 0, y: 0),
          edgeEnd: const GridPos(x: 1, y: 1),
          passIndex: 0,
          role: BorderPrimitiveRole.span,
          rank: 0,
          ordinalLocal: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => buildBorderLineSlotKey(
          featureId: 'feature',
          strokeId: 'stroke',
          edgeStart: const GridPos(x: 0, y: 0),
          edgeEnd: const GridPos(x: 0, y: 2),
          passIndex: 0,
          role: BorderPrimitiveRole.span,
          rank: 0,
          ordinalLocal: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects integers outside the exact cross-platform int domain', () {
      expect(
        () => buildBorderRegionSlotKey(
          featureId: 'feature',
          interiorCell: const GridPos(x: 9007199254740992, y: 0),
          side: BorderCardinalDirection.east,
          passIndex: 0,
          role: BorderPrimitiveRole.filler,
          rank: 0,
          ordinalLocal: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('builds and compares the full stable order tuple', () {
      final base = buildBorderStableOrderKey(
        drawBand: BorderDrawBand.structure,
        mapWidth: 10,
        anchorCell: const GridPos(x: 3, y: 2),
        passIndex: 4,
        rank: 5,
        ordinalLocal: 6,
        slotKey: 'slot-a',
      );

      expect(base.drawBandIndex, 1);
      expect(base.anchorRowMajor, 23);
      expect(base.passIndex, 4);
      expect(base.rank, 5);
      expect(base.ordinalLocal, 6);
      expect(base.slotKey, 'slot-a');

      final variants = <BorderStableOrderKey>[
        BorderStableOrderKey(
          drawBandIndex: 2,
          anchorRowMajor: 0,
          passIndex: 0,
          rank: 0,
          ordinalLocal: 0,
          slotKey: 'slot-a',
        ),
        BorderStableOrderKey(
          drawBandIndex: 1,
          anchorRowMajor: 24,
          passIndex: 0,
          rank: 0,
          ordinalLocal: 0,
          slotKey: 'slot-a',
        ),
        BorderStableOrderKey(
          drawBandIndex: 1,
          anchorRowMajor: 23,
          passIndex: 5,
          rank: 0,
          ordinalLocal: 0,
          slotKey: 'slot-a',
        ),
        BorderStableOrderKey(
          drawBandIndex: 1,
          anchorRowMajor: 23,
          passIndex: 4,
          rank: 6,
          ordinalLocal: 0,
          slotKey: 'slot-a',
        ),
        BorderStableOrderKey(
          drawBandIndex: 1,
          anchorRowMajor: 23,
          passIndex: 4,
          rank: 5,
          ordinalLocal: 7,
          slotKey: 'slot-a',
        ),
        BorderStableOrderKey(
          drawBandIndex: 1,
          anchorRowMajor: 23,
          passIndex: 4,
          rank: 5,
          ordinalLocal: 6,
          slotKey: 'slot-b',
        ),
      ];

      for (final variant in variants) {
        expect(base.compareTo(variant), lessThan(0));
        expect(variant.compareTo(base), greaterThan(0));
      }
    });

    test('validates stable order map width and anchor', () {
      for (final invocation in <void Function()>[
        () => buildBorderStableOrderKey(
              drawBand: BorderDrawBand.structure,
              mapWidth: 0,
              anchorCell: const GridPos(x: 0, y: 0),
              passIndex: 0,
              rank: 0,
              ordinalLocal: 0,
              slotKey: 'slot',
            ),
        () => buildBorderStableOrderKey(
              drawBand: BorderDrawBand.structure,
              mapWidth: 10,
              anchorCell: const GridPos(x: 10, y: 0),
              passIndex: 0,
              rank: 0,
              ordinalLocal: 0,
              slotKey: 'slot',
            ),
      ]) {
        expect(invocation, throwsA(isA<ValidationException>()));
      }
    });
  });
}

void _expectFixtureDigest(BorderSlotKeyGolden fixture) {
  final bytes = _decodeHex(fixture.preimageHex);
  final digest = sha256.convert(bytes).toString();
  expect('border-slot-v1:$digest', fixture.key);
}

Uint8List _decodeHex(String value) {
  final output = Uint8List(value.length ~/ 2);
  for (var index = 0; index < output.length; index += 1) {
    output[index] = int.parse(
      value.substring(index * 2, index * 2 + 2),
      radix: 16,
    );
  }
  return output;
}
