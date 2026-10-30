import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('existing pair with a new slot or replacement module is introduced', () {
    final before = _report({'slot-a|stone': 1});
    for (final contacts in [
      {'slot-a|stone': 1.0, 'slot-b|stone': .2},
      {'slot-a|wood': .5},
      {'slot-c|stone': 1.0},
    ]) {
      expect(
        _report(contacts).introducedSince(before).borderObjectOverlaps,
        hasLength(1),
      );
    }
  });

  test('increased penetration in an existing slot is aggravated', () {
    expect(
      _report({
        'slot-a|stone': 1.1,
      }).introducedSince(_report({'slot-a|stone': 1})).borderObjectOverlaps,
      hasLength(1),
    );
  });

  test('unchanged and reduced overlap do not become new failures', () {
    final before = _report({'slot-a|stone': 1, 'slot-b|stone': 2});
    expect(
      _report({
        'slot-a|stone': 1,
        'slot-b|stone': 2,
      }).introducedSince(before).borderObjectOverlaps,
      isEmpty,
    );
    expect(
      _report({
        'slot-a|stone': .5,
      }).introducedSince(before).borderObjectOverlaps,
      isEmpty,
    );
  });

  test('new unproven gap reports while unproven to exposed worsens', () {
    const cell = GridPos(x: 1, y: 2);
    const unknown = SpatialMapIntegrityReport(
      groundGaps: [
        SpatialGroundGap(cell: cell, state: SpatialGroundGapState.unproven),
      ],
      borderObjectOverlaps: [],
    );
    const exposed = SpatialMapIntegrityReport(
      groundGaps: [
        SpatialGroundGap(cell: cell, state: SpatialGroundGapState.exposed),
      ],
      borderObjectOverlaps: [],
    );
    expect(
      unknown
          .introducedSince(SpatialMapIntegrityReport.empty)
          .unprovenCellCount,
      1,
    );
    expect(exposed.introducedSince(unknown).exposedCellCount, 1);
    expect(unknown.introducedSince(exposed).groundGaps, isEmpty);
  });
}

SpatialMapIntegrityReport _report(Map<String, double> contacts) =>
    SpatialMapIntegrityReport(
      groundGaps: [],
      borderObjectOverlaps: [
        SpatialBorderObjectOverlap(
          layerId: 'border',
          featureId: 'cliff',
          instanceId: 'dock',
          modelId: 'object',
          moduleCount: contacts.length,
          firstCell: const GridPos(x: 1, y: 1),
          lastCell: const GridPos(x: 2, y: 1),
          contacts: contacts,
        ),
      ],
    );
