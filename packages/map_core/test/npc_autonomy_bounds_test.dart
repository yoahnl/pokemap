import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  MapEntityNpcMovementConfig decode({
    List<int> pauses = const [533, 1067],
    int width = 3,
  }) => MapEntityNpcMovementConfig.fromJson({
    'mode': 'fixedRoute',
    'routeSteps': [
      {'kind': 'randomMove'},
    ],
    'pauseDurationsMs': pauses,
    'movementArea': {
      'pos': {'x': 10, 'y': 20},
      'size': {'width': width, 'height': 3},
    },
  });

  test('preserves fixed movement area and selectable pause durations', () {
    final value = decode();
    expect(value.toJson()['pauseDurationsMs'], [533, 1067]);
    expect(jsonDecode(jsonEncode(value.toJson()))['movementArea'], {
      'pos': {'x': 10, 'y': 20},
      'size': {'width': 3, 'height': 3},
    });
  });

  test('rejects negative or excessive pauses and empty movement areas', () {
    expect(
      () => assertValidMapEntityNpcMovementConfig(decode(pauses: [-1])),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => assertValidMapEntityNpcMovementConfig(decode(pauses: [3600001])),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => assertValidMapEntityNpcMovementConfig(decode(width: 0)),
      throwsA(isA<ValidationException>()),
    );
  });
}
