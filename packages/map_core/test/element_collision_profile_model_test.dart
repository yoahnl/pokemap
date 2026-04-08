import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ElementCollisionProfile model', () {
    test('serializes manual overrides while keeping final cells', () {
      const profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        padding: WarpTriggerPadding(left: 4, right: 2),
        cells: <GridPos>[GridPos(x: 0, y: 1)],
        manualAddedCells: <GridPos>[GridPos(x: 0, y: 1)],
        manualRemovedCells: <GridPos>[GridPos(x: 1, y: 1)],
      );

      final roundtrip = ElementCollisionProfile.fromJson(profile.toJson());

      expect(roundtrip, profile);
    });

    test('defaults override lists to empty for legacy payloads', () {
      final profile = ElementCollisionProfile.fromJson(<String, dynamic>{
        'source': 'generated',
        'padding': <String, dynamic>{
          'top': 0,
          'right': 0,
          'bottom': 0,
          'left': 0,
        },
        'cells': <Map<String, dynamic>>[
          <String, dynamic>{'x': 0, 'y': 0},
        ],
      });

      expect(profile.manualAddedCells, isEmpty);
      expect(profile.manualRemovedCells, isEmpty);
      expect(profile.cells, const <GridPos>[GridPos(x: 0, y: 0)]);
    });
  });
}
