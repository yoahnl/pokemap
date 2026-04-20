import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Map gameplay zone battle background validation', () {
    test('rejects encounter zone backgrounds that escape the project', () {
      final map = MapData(
        id: 'field_map',
        name: 'Field Map',
        size: const GridSize(width: 10, height: 10),
        gameplayZones: const <MapGameplayZone>[
          MapGameplayZone(
            id: 'encounter_grass',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 2, height: 2),
            ),
            encounter: EncounterZonePayload(
              encounterTableId: 'grass',
              battleBackgroundRelativePath: '../outside.png',
            ),
          ),
        ],
      );

      expect(
        () => MapValidator.validate(map),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.toString(),
            'message',
            contains('battleBackgroundRelativePath'),
          ),
        ),
      );
    });
  });
}
