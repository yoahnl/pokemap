import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final raw = <String, dynamic>{
    'actionKind': 'dive',
    'dive': {
      'role': 'surface',
      'arrivalSpawnId': 'surface-spawn',
      'link': {'mapId': 'deep', 'zoneId': 'return'},
    },
  };
  test('Dive endpoint has an exclusive closed typed cold JSON contract', () {
    final payload = FieldActionZonePayload.fromJson(raw);
    expect(jsonDecode(jsonEncode(payload.toJson())), raw);
  });
  test('an unlinked Dive preparation can be saved', () {
    final payload = FieldActionZonePayload.fromJson({
      'actionKind': 'dive',
      'dive': {'role': 'underwater'},
    });
    expect(payload.toJson()['dive'], {'role': 'underwater'});
  });
  test(
    'Dive pair rejects coincident points while preparations remain saveable',
    () {
      MapData endpoint(String id, DiveZoneRole role, String target) => MapData(
        id: id,
        name: id,
        size: const GridSize(width: 4, height: 4),
        entities: [
          MapEntity(
            id: '$id-spawn',
            kind: MapEntityKind.spawn,
            pos: const GridPos(x: 1, y: 1),
            spawn: const MapEntitySpawnData(),
          ),
        ],
        gameplayZones: [
          MapGameplayZone(
            id: 'point',
            kind: GameplayZoneKind.fieldAction,
            area: const MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 1, height: 1),
            ),
            fieldAction: FieldActionZonePayload(
              actionKind: FieldActionZoneKind.dive,
              dive: DiveZonePayload(
                role: role,
                arrivalSpawnId: '$id-spawn',
                link: DiveZoneLink(mapId: target, zoneId: 'point'),
              ),
            ),
          ),
        ],
      );
      final sea = endpoint('sea', DiveZoneRole.surface, 'deep');
      final deep = endpoint('deep', DiveZoneRole.underwater, 'sea');
      for (final duplicateSource in [true, false]) {
        final original = duplicateSource ? sea : deep;
        final duplicate = original.copyWith(
          gameplayZones: [
            ...original.gameplayZones,
            original.gameplayZones.single.copyWith(id: 'second', priority: 10),
          ],
        );
        final source = duplicateSource ? duplicate : sea;
        final target = duplicateSource ? deep : duplicate;
        expect(
          () => validateDiveZonePair(
            sourceMap: source,
            sourceZoneId: 'point',
            targetMap: target,
            targetZoneId: 'point',
          ),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.toString(),
              'message',
              contains('Plusieurs points de Plongée'),
            ),
          ),
        );
        final diagnostics = diveZonePairDiagnostics([source, target]);
        expect(diagnostics, hasLength(3));
        expect(
          diagnostics.every(
            (diagnostic) =>
                diagnostic.message.contains('Plusieurs points de Plongée'),
          ),
          isTrue,
        );
        final preparation = original.gameplayZones.single.copyWith(
          fieldAction: original.gameplayZones.single.fieldAction!.copyWith(
            dive: original.gameplayZones.single.fieldAction!.dive!.copyWith(
              link: null,
            ),
          ),
        );
        final saved = addGameplayZoneToMap(
          original.copyWith(gameplayZones: [preparation]),
          zone: preparation.copyWith(id: 'second', priority: 10),
        );
        expect(
          MapData.fromJson(
            jsonDecode(jsonEncode(saved.toJson())) as Map<String, dynamic>,
          ).gameplayZones,
          hasLength(2),
        );
      }
    },
  );
  test('Dive is a 1x1 2D point with one exact local spawn ID', () {
    final zone = MapGameplayZone(
      id: 'point',
      kind: GameplayZoneKind.fieldAction,
      area: const MapRect(
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 1, height: 1),
      ),
      fieldAction: FieldActionZonePayload.fromJson(raw),
    );
    final map = MapData(
      id: 'surface',
      name: 'Surface',
      size: const GridSize(width: 4, height: 4),
    );
    expect(
      () => addGameplayZoneToMap(map, zone: zone),
      throwsA(isA<ValidationException>()),
    );
    final spawn = MapEntity(
      id: 'surface-spawn',
      kind: MapEntityKind.spawn,
      pos: const GridPos(x: 1, y: 1),
      spawn: const MapEntitySpawnData(spawnKey: 'other'),
    );
    final valid = map.copyWith(entities: [spawn]);
    expect(addGameplayZoneToMap(valid, zone: zone).gameplayZones, [zone]);
    expect(
      () => addGameplayZoneToMap(
        valid.copyWith(entities: [spawn, spawn]),
        zone: zone,
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => addGameplayZoneToMap(
        valid,
        zone: zone.copyWith(
          area: zone.area.copyWith(size: const GridSize(width: 2, height: 1)),
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });
  test('Dive terrain rejects additional-mode aliases, overlap and 3D', () {
    final map = MapData(
      id: 'm',
      name: 'm',
      size: const GridSize(width: 4, height: 4),
    );
    const terrain = MapGameplayZone(
      id: 'dive',
      kind: GameplayZoneKind.movement,
      area: MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 4, height: 4),
      ),
      movement: MovementZonePayload(requiredMode: MovementMode.dive),
    );
    expect(
      () => addGameplayZoneToMap(
        map,
        zone: terrain.copyWith(
          movement: const MovementZonePayload(
            allowedModes: [MovementMode.dive],
          ),
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    final submerged = addGameplayZoneToMap(map, zone: terrain);
    expect(
      () => addGameplayZoneToMap(
        submerged,
        zone: terrain.copyWith(
          id: 'surf',
          movement: const MovementZonePayload(requiredMode: MovementMode.surf),
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => addGameplayZoneToMap(
        map.copyWith(version: ProjectVersion.v9),
        zone: terrain,
      ),
      throwsA(isA<ValidationException>()),
    );
  });
  test('Dive rejects mixed, unknown, malformed links and unknown roles', () {
    for (final dive in <Map<String, dynamic>>[
      {'role': 'other'},
      {'role': 'surface', 'x': 1},
      {
        'role': 'surface',
        'link': {'mapId': 'deep'},
      },
      {'role': 'surface', 'arrivalSpawnId': ''},
      {
        'role': 'surface',
        'link': {'mapId': 'deep', 'zoneId': 'return', 'x': 1},
      },
    ]) {
      expect(
        () => FieldActionZonePayload.fromJson({
          'actionKind': 'dive',
          'dive': dive,
        }),
        throwsA(isA<FormatException>()),
      );
    }
    expect(
      () => FieldActionZonePayload.fromJson({
        ...raw,
        'darkness': {'opacity': .7},
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
