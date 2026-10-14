import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('a named Scene destination has an explicit inert trigger mode', () {
    final destination = MapWarp.fromJson(_destinationJson('scene_only'));
    expect(destination.id, 'door-arrival');
    expect(destination.pos, const GridPos(x: 1, y: 0));
    expect(destination.toJson()['triggerMode'], 'scene_only');
    expect(MapWarp.fromJson(destination.toJson()), destination);
  });

  test('existing automatic trigger modes keep their exact wire values', () {
    for (final mode in ['on_enter', 'on_bump']) {
      final warp = MapWarp.fromJson(_destinationJson(mode));
      expect(warp.toJson()['triggerMode'], mode);
    }
  });

  test('unknown destination modes remain rejected', () {
    expect(
      () => MapWarp.fromJson(_destinationJson('scene_only_from_script')),
      throwsArgumentError,
    );
  });
}

Map<String, dynamic> _destinationJson(String mode) => {
  'id': 'door-arrival',
  'pos': {'x': 1, 'y': 0},
  'targetMapId': 'map',
  'targetPos': {'x': 1, 'y': 0},
  'triggerMode': mode,
};
