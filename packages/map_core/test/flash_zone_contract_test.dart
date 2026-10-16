import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> flashZoneJson() => {
  'id': 'cave-darkness',
  'name': 'Grotte sombre',
  'kind': 'fieldAction',
  'area': {
    'pos': {'x': 1, 'y': 1},
    'size': {'width': 3, 'height': 2},
  },
  'fieldAction': {
    'actionKind': 'darkness',
    'darkness': {'opacity': 0.85},
  },
};

void main() {
  test('native darkness zone survives a cold JSON round trip', () {
    final zone = MapGameplayZone.fromJson(flashZoneJson());
    final restored = MapGameplayZone.fromJson(
      jsonDecode(jsonEncode(zone.toJson())) as Map<String, dynamic>,
    );
    expect(restored, zone);
    expect(restored.toJson()['fieldAction'], flashZoneJson()['fieldAction']);
    final map = MapData(
      id: 'cave',
      name: 'Cave',
      size: const GridSize(width: 6, height: 5),
    );
    expect(addGameplayZoneToMap(map, zone: zone).gameplayZones.single, zone);
  });

  for (final mode in [
    'missing',
    'unknown',
    'extra',
    'nan',
    'bounds',
    'mixed',
  ]) {
    test('darkness rejects $mode payloads', () {
      final json = flashZoneJson();
      final payload = json['fieldAction'] as Map<String, dynamic>;
      if (mode == 'missing') json.remove('fieldAction');
      if (mode == 'unknown') payload['actionKind'] = 'waterfall';
      if (mode == 'extra') payload['timer'] = 10;
      if (mode == 'nan') payload['darkness'] = {'opacity': double.nan};
      if (mode == 'bounds') payload['darkness'] = {'opacity': 1.0};
      if (mode == 'mixed') json['special'] = {'properties': {}};
      expect(() => MapGameplayZone.fromJson(json), throwsFormatException);
    });
  }

  test('illumination is strict instance state rather than a global flag', () {
    final json = MapInstanceWorldState(
      instancesByMapId: {
        'cave': MapInstanceRuntimeState(instanceId: 'cave-one'),
      },
    ).toJson();
    final instances = json['instancesByMapId'] as Map<String, dynamic>;
    (instances['cave'] as Map<String, dynamic>)['illuminatedZoneIds'] = [
      'dark',
    ];
    expect(MapInstanceWorldState.fromJson(json).toJson(), json);
  });
}
