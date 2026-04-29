import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MovementEffectZonePayload', () {
    test('exposes slide and movementCost effect kinds', () {
      expect(MovementEffectZoneKind.values,
          contains(MovementEffectZoneKind.slide));
      expect(
        MovementEffectZoneKind.values,
        contains(MovementEffectZoneKind.movementCost),
      );
    });

    test('slide defaults to a valid payload', () {
      const payload = MovementEffectZonePayload();

      expect(payload.effectKind, MovementEffectZoneKind.slide);
      expect(payload.movementCost, 1);
    });

    test('movementCost supports positive cost and value equality', () {
      const first = MovementEffectZonePayload(
        effectKind: MovementEffectZoneKind.movementCost,
        movementCost: 2,
      );
      const second = MovementEffectZonePayload(
        effectKind: MovementEffectZoneKind.movementCost,
        movementCost: 2,
      );
      const different = MovementEffectZonePayload();

      expect(first.effectKind, MovementEffectZoneKind.movementCost);
      expect(first.movementCost, 2);
      expect(first, second);
      expect(first, isNot(different));
    });

    test('encodes and decodes slide JSON', () {
      const payload = MovementEffectZonePayload();

      final json = payload.toJson();
      final decoded = MovementEffectZonePayload.fromJson(json);

      expect(json, {'effectKind': 'slide', 'movementCost': 1});
      expect(decoded, payload);
    });

    test('encodes and decodes movementCost JSON', () {
      const payload = MovementEffectZonePayload(
        effectKind: MovementEffectZoneKind.movementCost,
        movementCost: 3,
      );

      final json = payload.toJson();
      final decoded = MovementEffectZonePayload.fromJson(json);

      expect(json, {'effectKind': 'movementCost', 'movementCost': 3});
      expect(decoded, payload);
    });
  });

  group('MapGameplayZone movementEffect payload', () {
    test('can carry a movementEffect zone payload', () {
      const zone = MapGameplayZone(
        id: 'ice-slide',
        name: 'Ice Slide',
        kind: GameplayZoneKind.movementEffect,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 3, height: 2),
        ),
        priority: 4,
        movementEffect: MovementEffectZonePayload(),
      );

      expect(zone.movementEffect, const MovementEffectZonePayload());
      expect(zone.kind, GameplayZoneKind.movementEffect);
    });

    test('roundtrips movementEffect zone JSON', () {
      const zone = MapGameplayZone(
        id: 'ice-slide',
        name: 'Ice Slide',
        kind: GameplayZoneKind.movementEffect,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 3, height: 2),
        ),
        priority: 4,
        movementEffect: MovementEffectZonePayload(),
      );

      final json =
          jsonDecode(jsonEncode(zone.toJson())) as Map<String, dynamic>;
      final decoded = MapGameplayZone.fromJson(json);

      expect(json['kind'], 'movementEffect');
      expect(
          json['movementEffect'], {'effectKind': 'slide', 'movementCost': 1});
      expect(decoded, zone);
    });

    test('old encounter movement and hazard JSON remain compatible', () {
      final encounter = MapGameplayZone.fromJson({
        'id': 'encounter-zone',
        'kind': 'encounter',
        'area': _areaJson(),
        'encounter': {'encounterKind': 'walk'},
      });
      final movement = MapGameplayZone.fromJson({
        'id': 'movement-zone',
        'kind': 'movement',
        'area': _areaJson(),
        'movement': {'requiredMode': 'surf'},
      });
      final hazard = MapGameplayZone.fromJson({
        'id': 'hazard-zone',
        'kind': 'hazard',
        'area': _areaJson(),
        'hazard': {'hazardKind': 'lava', 'damagePerStep': 5},
      });

      expect(encounter.movementEffect, isNull);
      expect(movement.movementEffect, isNull);
      expect(hazard.movementEffect, isNull);
    });
  });

  group('movementEffect gameplay zone validation', () {
    test('addGameplayZoneToMap accepts a valid movementEffect zone', () {
      final updated = addGameplayZoneToMap(
        _map(),
        zone: _movementEffectZone(),
      );

      expect(
          updated.gameplayZones.single.kind, GameplayZoneKind.movementEffect);
      expect(
        updated.gameplayZones.single.movementEffect,
        const MovementEffectZonePayload(),
      );
    });

    test('updateGameplayZoneOnMap accepts a valid movementEffect zone', () {
      final updated = updateGameplayZoneOnMap(
        _map(gameplayZones: [_encounterZone()]),
        zoneId: 'zone',
        kind: GameplayZoneKind.movementEffect,
        encounter: null,
        movementEffect: const MovementEffectZonePayload(
          effectKind: MovementEffectZoneKind.movementCost,
          movementCost: 2,
        ),
      );

      expect(
          updated.gameplayZones.single.kind, GameplayZoneKind.movementEffect);
      expect(
        updated.gameplayZones.single.movementEffect,
        const MovementEffectZonePayload(
          effectKind: MovementEffectZoneKind.movementCost,
          movementCost: 2,
        ),
      );
    });

    test('MapValidator accepts a valid movementEffect zone', () {
      expect(
        () =>
            MapValidator.validate(_map(gameplayZones: [_movementEffectZone()])),
        returnsNormally,
      );
    });

    test('rejects movementEffect kind without payload', () {
      const zone = MapGameplayZone(
        id: 'ice-slide',
        kind: GameplayZoneKind.movementEffect,
        area: MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 1, height: 1),
        ),
      );

      expect(
        () => addGameplayZoneToMap(_map(), zone: zone),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapValidator.validate(_map(gameplayZones: [zone])),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive movementCost', () {
      const zone = MapGameplayZone(
        id: 'mud-cost',
        kind: GameplayZoneKind.movementEffect,
        area: MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 1, height: 1),
        ),
        movementEffect: MovementEffectZonePayload(
          effectKind: MovementEffectZoneKind.movementCost,
          movementCost: 0,
        ),
      );

      expect(
        () => addGameplayZoneToMap(_map(), zone: zone),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapValidator.validate(_map(gameplayZones: [zone])),
        throwsA(isA<ValidationException>()),
      );
    });

    test('keeps duplicate id and invalid area validation intact', () {
      expect(
        () => addGameplayZoneToMap(
          _map(gameplayZones: [_movementEffectZone()]),
          zone: _movementEffectZone(),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => addGameplayZoneToMap(
          _map(),
          zone: _movementEffectZone(
            area: const MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 0, height: 1),
            ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

Map<String, dynamic> _areaJson() {
  return {
    'pos': {'x': 1, 'y': 1},
    'size': {'width': 1, 'height': 1},
  };
}

MapData _map({
  List<MapGameplayZone> gameplayZones = const [],
}) {
  return MapData(
    id: 'movement_effect_model_map',
    name: 'Movement Effect Model Map',
    size: const GridSize(width: 4, height: 4),
    gameplayZones: gameplayZones,
  );
}

MapGameplayZone _encounterZone() {
  return const MapGameplayZone(
    id: 'zone',
    kind: GameplayZoneKind.encounter,
    area: MapRect(
      pos: GridPos(x: 1, y: 1),
      size: GridSize(width: 1, height: 1),
    ),
    encounter: EncounterZonePayload(),
  );
}

MapGameplayZone _movementEffectZone({
  MapRect area = const MapRect(
    pos: GridPos(x: 1, y: 1),
    size: GridSize(width: 1, height: 1),
  ),
}) {
  return MapGameplayZone(
    id: 'ice-slide',
    kind: GameplayZoneKind.movementEffect,
    area: area,
    movementEffect: const MovementEffectZonePayload(),
  );
}
