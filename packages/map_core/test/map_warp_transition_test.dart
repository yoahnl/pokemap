import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> warpJson() => {
  'id': 'passage',
  'pos': {'x': 1, 'y': 1},
  'targetMapId': 'next',
  'targetPos': {'x': 2, 'y': 2},
};

void main() {
  test('warp serialization declares its default native screen transition', () {
    final warp = MapWarp.fromJson(warpJson());
    expect(warp.toJson()['transition'], {
      'type': 'fade',
      'durationSeconds': .2,
    });
  });

  for (final type in MapWarpTransitionType.values) {
    test('typed ${type.name} transition roundtrips with value equality', () {
      final transition = MapWarpTransition(type: type, durationSeconds: .45);
      final warp = MapWarp.fromJson({
        ...warpJson(),
        'transition': transition.toJson(),
      });
      expect(warp.transition, transition);
      expect(warp.transition.hashCode, transition.hashCode);
      expect(MapWarp.fromJson(warp.toJson()), warp);
      expect(
        warp
            .copyWith(transition: transition.copyWith(durationSeconds: 5))
            .transition
            .durationSeconds,
        5,
      );
    });
  }

  test('typed warp operations retain independent per-warp transitions', () {
    final map = MapData(
      id: 'room',
      name: 'Room',
      size: const GridSize(width: 4, height: 4),
    );
    final first = createMapWarp(
      map,
      id: 'first',
      pos: const GridPos(x: 1, y: 1),
      targetMapId: 'next',
      targetPos: const GridPos(x: 1, y: 1),
      transition: const MapWarpTransition(
        type: MapWarpTransitionType.hgss,
        durationSeconds: .4,
      ),
    );
    final second = createMapWarp(
      map,
      id: 'second',
      pos: const GridPos(x: 2, y: 1),
      targetMapId: 'next',
      targetPos: const GridPos(x: 1, y: 1),
    );
    final original = map.copyWith(warps: [first, second]);
    final changed = updateWarpOnMap(
      original,
      warpId: 'second',
      transition: const MapWarpTransition(type: MapWarpTransitionType.none),
    );
    expect(changed.warps.first, first);
    expect(changed.warps.last.transition.type, MapWarpTransitionType.none);
    expect(
      updateWarpOnMap(
        changed,
        warpId: 'first',
        pos: const GridPos(x: 0, y: 1),
      ).warps.first.transition,
      first.transition,
    );
    MapValidator.validate(changed);
  });

  for (final bad in [
    null,
    'fade',
    [],
    {},
    {'type': 'fade'},
    {'durationSeconds': .2},
    {'type': 'fade', 'durationSeconds': 0},
    {'type': 'none', 'durationSeconds': -1},
    {'type': 'hgss', 'durationSeconds': 5.01},
    {'type': 'fade', 'durationSeconds': double.nan},
    {'type': 'fade', 'durationSeconds': double.infinity},
    {'type': 'fade', 'durationSeconds': '.2'},
    {'type': 'fade', 'durationSeconds': .2, 'hidden': true},
  ]) {
    test('invalid transition JSON is rejected: $bad', () {
      expect(
        () => MapWarp.fromJson({...warpJson(), 'transition': bad}),
        throwsA(anyOf(isA<FormatException>(), isA<TypeError>())),
      );
    });
  }

  test(
    'an unknown screen transition is rejected instead of silently ignored',
    () {
      expect(
        () => MapWarp.fromJson({
          ...warpJson(),
          'transition': {'type': 'unknown', 'durationSeconds': .2},
        }),
        throwsFormatException,
      );
    },
  );
}
