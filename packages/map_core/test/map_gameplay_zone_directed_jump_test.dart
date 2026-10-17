import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _payload({String direction = 'south'}) => {
  'effectKind': 'directedJump',
  'movementCost': 1,
  'directedJump': <String, dynamic>{
    'direction': direction,
    'distanceCells': 2,
    'durationMs': 500,
    'peakHeightPx': 24,
  },
};

MapGameplayZone _zone({
  String id = 'ledge',
  String direction = 'south',
  int priority = 0,
  GridPos position = const GridPos(x: 1, y: 1),
}) => MapGameplayZone(
  id: id,
  kind: GameplayZoneKind.movementEffect,
  area: MapRect(pos: position, size: const GridSize(width: 1, height: 1)),
  priority: priority,
  movementEffect: MovementEffectZonePayload.fromJson(
    _payload(direction: direction),
  ),
);

MapData _map(List<MapGameplayZone> zones) => MapData(
  id: 'jump',
  name: 'Jump',
  size: const GridSize(width: 4, height: 4),
  gameplayZones: zones,
);

void main() {
  test('directed jump roundtrips every cardinal direction and value', () {
    for (final direction in ['north', 'south', 'east', 'west']) {
      final raw = _payload(direction: direction);
      final value = MovementEffectZonePayload.fromJson(raw);
      expect(value.effectKind.name, 'directedJump');
      expect(value.toJson(), raw);
      expect(MovementEffectZonePayload.fromJson(value.toJson()), value);
      final map = _map([_zone(direction: direction)]);
      MapValidator.validate(map);
      final reopened = MapData.fromJson(jsonDecode(jsonEncode(map.toJson())));
      expect(reopened, map);
    }
  });

  test('closed directed jump rejects missing malformed and unknown fields', () {
    for (final field in [
      'direction',
      'distanceCells',
      'durationMs',
      'peakHeightPx',
    ]) {
      final raw = _payload();
      (raw['directedJump'] as Map).remove(field);
      expect(
        () => MovementEffectZonePayload.fromJson(raw),
        throwsA(anyOf(isA<Exception>(), isA<ArgumentError>())),
      );
    }
    for (final change in [
      {'direction': 'diagonal'},
      {'direction': null},
      {'distanceCells': 3},
      {'distanceCells': 2.5},
      {'durationMs': 0},
      {'durationMs': 60001},
      {'durationMs': 5.5},
      {'peakHeightPx': 0},
      {'peakHeightPx': 1025},
      {'peakHeightPx': 2.5},
      {'unknown': true},
    ]) {
      final raw = _payload();
      (raw['directedJump'] as Map).addAll(change);
      expect(
        () => MovementEffectZonePayload.fromJson(raw),
        throwsA(anyOf(isA<Exception>(), isA<ArgumentError>())),
        reason: '$change',
      );
    }
    for (final raw in [
      _payload()..remove('directedJump'),
      _payload()..['directedJump'] = null,
      _payload()..['effectKind'] = 'slide',
      _payload()..['unknown'] = true,
    ]) {
      expect(
        () => MovementEffectZonePayload.fromJson(raw),
        throwsA(anyOf(isA<Exception>(), isA<ArgumentError>())),
      );
    }
  });

  test('directed jump zone codec refuses unknown top-level fields', () {
    final raw =
        (jsonDecode(jsonEncode(_zone().toJson())) as Map<String, dynamic>)
          ..['unknown'] = true;
    expect(
      () => MapGameplayZone.fromJson(raw),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'jump rejects wrong kind conflicting payload mask and missing endpoints',
    () {
      final zone = _zone();
      for (final invalid in [
        zone.copyWith(kind: GameplayZoneKind.hazard),
        zone.copyWith(hazard: const HazardZonePayload()),
        zone.copyWith(cellMask: const [GridPos(x: 0, y: 0)]),
        _zone(direction: 'north', position: const GridPos(x: 1, y: 0)),
        _zone(direction: 'south', position: const GridPos(x: 1, y: 3)),
      ]) {
        expect(
          () => MapValidator.validate(_map([invalid])),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => addGameplayZoneToMap(_map([]), zone: invalid),
          throwsA(isA<ValidationException>()),
        );
      }
    },
  );

  test(
    'equal priority overlapping same direction is refused by pure operations and validator',
    () {
      final first = _zone();
      final second = _zone(id: 'second');
      expect(
        () => MapValidator.validate(_map([first, second])),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => addGameplayZoneToMap(_map([first]), zone: second),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => updateGameplayZoneOnMap(
          _map([first, second.copyWith(priority: 1)]),
          zoneId: 'second',
          priority: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapValidator.validate(
          _map([first, _zone(id: 'other', direction: 'east')]),
        ),
        returnsNormally,
      );
      expect(
        () =>
            MapValidator.validate(_map([first, second.copyWith(priority: 1)])),
        returnsNormally,
      );
    },
  );

  test(
    'move and metadata edits preserve typed jump while invalid move rejects',
    () {
      var map = addGameplayZoneToMap(_map([]), zone: _zone());
      map = updateGameplayZoneOnMap(
        map,
        zoneId: 'ledge',
        name: 'South ledge',
        priority: 2,
      );
      map = moveGameplayZoneOnMap(
        map,
        zoneId: 'ledge',
        pos: const GridPos(x: 2, y: 2),
      );
      expect(map.gameplayZones.single.movementEffect!.toJson(), _payload());
      expect(
        () => moveGameplayZoneOnMap(
          map,
          zoneId: 'ledge',
          pos: const GridPos(x: 2, y: 3),
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('slide and movement cost stay unchanged', () {
    expect(const MovementEffectZonePayload().toJson(), {
      'effectKind': 'slide',
      'movementCost': 1,
    });
    expect(
      MovementEffectZonePayload.fromJson({
        'effectKind': 'movementCost',
        'movementCost': 3,
      }).movementCost,
      3,
    );
    expect(
      MovementEffectZonePayload.fromJson({'effectKind': 'slide'}),
      const MovementEffectZonePayload(),
    );
  });

  test(
    'validator refuses invalid typed constructors without relying on JSON',
    () {
      for (final jump in [
        const DirectedJumpZonePayload(
          direction: MapConnectionDirection.south,
          distanceCells: 3,
        ),
        const DirectedJumpZonePayload(
          direction: MapConnectionDirection.south,
          durationMs: 0,
        ),
        const DirectedJumpZonePayload(
          direction: MapConnectionDirection.south,
          peakHeightPx: 1025,
        ),
      ]) {
        final zone = _zone().copyWith(
          movementEffect: MovementEffectZonePayload(
            effectKind: MovementEffectZoneKind.directedJump,
            directedJump: jump,
          ),
        );
        expect(
          () => MapValidator.validate(_map([zone])),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => addGameplayZoneToMap(_map([]), zone: zone),
          throwsA(isA<ValidationException>()),
        );
      }
    },
  );

  test(
    'complete rectangles cover their exact departure and landing strips',
    () {
      final zone = _zone().copyWith(
        area: const MapRect(
          pos: GridPos(x: 0, y: 1),
          size: GridSize(width: 4, height: 2),
        ),
      );
      MapValidator.validate(_map([zone]));
      expect(
        () => resizeGameplayZoneOnMap(
          _map([zone]),
          zoneId: 'ledge',
          size: const GridSize(width: 4, height: 3),
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );
}
