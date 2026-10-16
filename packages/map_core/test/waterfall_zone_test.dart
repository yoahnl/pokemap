import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final map = MapData(
    id: 'falls',
    name: 'Falls',
    size: const GridSize(width: 8, height: 8),
  );
  final raw = <String, dynamic>{
    'id': 'cascade',
    'kind': 'fieldAction',
    'area': {
      'pos': {'x': 2, 'y': 1},
      'size': {'width': 1, 'height': 4},
    },
    'fieldAction': {
      'actionKind': 'waterfall',
      'waterfall': {
        'entry': {'x': 0, 'y': 3},
        'path': [
          {'x': 0, 'y': 2},
          {'x': 0, 'y': 1},
        ],
        'exit': {'x': 0, 'y': 0},
        'direction': 'north',
        'requiresSurf': true,
      },
    },
  };
  test('typed waterfall survives a cold map JSON roundtrip', () {
    final zone = MapGameplayZone.fromJson(raw);
    final result = addGameplayZoneToMap(map, zone: zone);
    expect(
      MapData.fromJson(
        jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>,
      ),
      result,
    );
    expect(
      zone.fieldAction!.toJson()['waterfall'],
      raw['fieldAction']['waterfall'],
    );
  });
  test('rejects unknown fields, mixed payloads and noncontiguous route', () {
    expect(
      () => MapGameplayZone.fromJson({
        ...raw,
        'fieldAction': {
          ...raw['fieldAction'] as Map<String, dynamic>,
          'darkness': {'opacity': .7},
        },
      }),
      throwsA(isA<FormatException>()),
    );
    final bad = MapGameplayZone.fromJson({
      ...raw,
      'fieldAction': {
        'actionKind': 'waterfall',
        'waterfall': {
          ...raw['fieldAction']['waterfall'] as Map<String, dynamic>,
          'path': [
            {'x': 0, 'y': 1},
          ],
        },
      },
    });
    expect(
      () => addGameplayZoneToMap(map, zone: bad),
      throwsA(isA<ValidationException>()),
    );
  });
  test(
    'waterfall rejects fractional coordinates instead of silently rounding',
    () {
      final payload = {
        ...raw['fieldAction']['waterfall'] as Map<String, dynamic>,
        'entry': {'x': .5, 'y': 3},
      };
      expect(
        () => FieldActionZonePayload.fromJson({
          'actionKind': 'waterfall',
          'waterfall': payload,
        }),
        throwsA(isA<FormatException>()),
      );
    },
  );
}
