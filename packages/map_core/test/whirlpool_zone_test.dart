import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final raw =
      jsonDecode(
            File('test/fixtures/whirlpool_field_zone.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final map = MapData(
    id: 'whirls',
    name: 'Whirls',
    size: const GridSize(width: 8, height: 8),
  );
  test(
    'the canonical Whirlpool route survives a strict cold JSON roundtrip',
    () {
      final zone = MapGameplayZone.fromJson(raw);
      final result = addGameplayZoneToMap(map, zone: zone);
      expect(
        MapData.fromJson(
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>,
        ),
        result,
      );
      expect(zone.fieldAction!.actionKind.name, 'whirlpool');
      expect(
        zone.fieldAction!.toJson()['whirlpool'],
        raw['fieldAction']['whirlpool'],
      );
    },
  );

  for (final mutation in [
    'requiresSurf',
    'unknown',
    'mixed',
    'fractional',
    'direction',
    'empty',
    'unbounded',
  ]) {
    test(
      'Whirlpool refuses $mutation payload before accepting project data',
      () {
        final field =
            jsonDecode(jsonEncode(raw['fieldAction'])) as Map<String, dynamic>;
        final payload = field['whirlpool'] as Map<String, dynamic>;
        switch (mutation) {
          case 'requiresSurf':
            payload['requiresSurf'] = false;
          case 'unknown':
            payload['speed'] = 2;
          case 'mixed':
            field['waterfall'] = payload;
          case 'fractional':
            payload['entry'] = {'x': .5, 'y': 3};
          case 'direction':
            payload['direction'] = 'diagonal';
          case 'empty':
            payload['path'] = [];
          case 'unbounded':
            payload['path'] = List.filled(257, {'x': 0, 'y': 2});
        }
        expect(
          () => MapGameplayZone.fromJson({...raw, 'fieldAction': field}),
          throwsFormatException,
        );
      },
    );
  }

  test('Whirlpool rejects a skipped cell and a route outside its zone', () {
    for (final path in [
      [
        {'x': 0, 'y': 1},
      ],
      [
        {'x': 0, 'y': 4},
      ],
    ]) {
      final field =
          jsonDecode(jsonEncode(raw['fieldAction'])) as Map<String, dynamic>;
      (field['whirlpool'] as Map<String, dynamic>)['path'] = path;
      final zone = MapGameplayZone.fromJson({...raw, 'fieldAction': field});
      expect(
        () => addGameplayZoneToMap(map, zone: zone),
        throwsA(isA<ValidationException>()),
      );
    }
  });
}
