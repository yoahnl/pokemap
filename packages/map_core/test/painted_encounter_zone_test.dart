import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'painted encounter resolves only its authored cells after JSON reload',
    () {
      final zone = MapGameplayZone.fromJson({
        'id': 'patch',
        'kind': 'encounter',
        'area': {
          'pos': {'x': 2, 'y': 2},
          'size': {'width': 3, 'height': 3},
        },
        'cellMask': [
          const GridPos(x: 0, y: 0).toJson(),
          const GridPos(x: 1, y: 0).toJson(),
          const GridPos(x: 0, y: 1).toJson(),
          const GridPos(x: 2, y: 2).toJson(),
        ],
        'encounter': {'encounterTableId': 'grass', 'encounterKind': 'walk'},
      });
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 8, height: 8),
        gameplayZones: [zone],
      );
      final restored = MapData.fromJson(
        jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>,
      );

      expect(
        resolveEncounterSourceAtPosition(
          restored,
          position: const GridPos(x: 2, y: 2),
          encounterKind: EncounterKind.walk,
        ).status,
        EncounterSourceResolutionStatus.resolved,
      );
      expect(
        resolveEncounterSourceAtPosition(
          restored,
          position: const GridPos(x: 3, y: 3),
          encounterKind: EncounterKind.walk,
        ).status,
        EncounterSourceResolutionStatus.noSource,
      );
      expect(
        resolveEncounterSourceAtPosition(
          restored,
          position: const GridPos(x: 4, y: 4),
          encounterKind: EncounterKind.walk,
        ).status,
        EncounterSourceResolutionStatus.resolved,
      );
      expect(restored.gameplayZones.single.cellMask, hasLength(4));
    },
  );

  test('painting and erasing preserve holes and reject an empty zone', () {
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      gameplayZones: [
        MapGameplayZone(
          id: 'patch',
          kind: GameplayZoneKind.encounter,
          area: const MapRect(
            pos: GridPos(x: 2, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
          cellMask: const [GridPos(x: 0, y: 0)],
          encounter: const EncounterZonePayload(encounterTableId: 'grass'),
        ),
      ],
    );
    final painted = paintEncounterZoneCells(
      map,
      zoneId: 'patch',
      cells: const [GridPos(x: 4, y: 4)],
      erase: false,
    );
    expect(painted.gameplayZones.single.area.size.width, 3);
    expect(
      gameplayZoneContainsPosition(
        painted.gameplayZones.single,
        const GridPos(x: 3, y: 3),
      ),
      isFalse,
    );
    final erased = paintEncounterZoneCells(
      painted,
      zoneId: 'patch',
      cells: const [GridPos(x: 4, y: 4)],
      erase: true,
    );
    expect(erased.gameplayZones.single.area.size.width, 1);
    expect(
      () => paintEncounterZoneCells(
        erased,
        zoneId: 'patch',
        cells: const [GridPos(x: 2, y: 2)],
        erase: true,
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}
