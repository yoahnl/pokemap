import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _pos = GridPos(x: 1, y: 1);
const _next = GridPos(x: 2, y: 1);
const _point = MapWarp(
  id: 'point',
  pos: _pos,
  targetMapId: 'alpha',
  targetPos: _pos,
  triggerMode: MapWarpTriggerMode.sceneOnly,
);
const _portal = MapWarp(
  id: 'point',
  pos: _pos,
  targetMapId: 'beta',
  targetPos: _next,
  triggerMode: MapWarpTriggerMode.onBump,
);
MapData _map(MapWarp warp) => MapData(
  id: 'alpha',
  name: 'Alpha',
  size: const GridSize(width: 4, height: 4),
  warps: [warp],
);

void main() {
  test('the point builder needs only identity and position', () {
    final empty = _map(_point).copyWith(warps: const []);
    final point = createMapWarp(
      empty,
      id: 'point',
      pos: _pos,
      triggerMode: MapWarpTriggerMode.sceneOnly,
      allowedApproachFacings: const [EntityFacing.north],
      triggerPadding: const WarpTriggerPadding(bottom: 1),
    );
    expect(point.targetMapId, 'alpha');
    expect(point.targetPos, _pos);
    expect(point.allowedApproachFacings, [EntityFacing.north]);
    expect(point.triggerPadding.bottom, 1);
    expect(addWarpToMap(empty, warp: point).warps.single, point);
    MapValidator.validate(_map(point));
  });
  test(
    'the builder refuses active destinations omitted or passive conflicts',
    () {
      final empty = _map(_point).copyWith(warps: const []);
      expect(
        () => createMapWarp(empty, id: 'active', pos: _pos),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => createMapWarp(
          empty,
          id: 'point',
          pos: _pos,
          triggerMode: MapWarpTriggerMode.sceneOnly,
          targetMapId: 'beta',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => createMapWarp(
          empty,
          id: 'point',
          pos: _pos,
          triggerMode: MapWarpTriggerMode.sceneOnly,
          targetPos: _next,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => createMapWarp(
          _map(_point),
          id: 'point',
          pos: _pos,
          triggerMode: MapWarpTriggerMode.sceneOnly,
        ),
        throwsA(isA<ValidationException>()),
      );
      final active = createMapWarp(
        empty,
        id: 'active',
        pos: _pos,
        targetMapId: 'beta',
        targetPos: _next,
      );
      expect(active.triggerMode, MapWarpTriggerMode.onEnter);
      expect(active.targetMapId, 'beta');
      expect(active.targetPos, _next);
    },
  );
  test('moving an inert point synchronizes its canonical local target', () {
    final map = updateWarpOnMap(_map(_point), warpId: 'point', pos: _next);
    expect(map.warps.single.pos, _next);
    expect(map.warps.single.targetPos, _next);
    expect(map.warps.single.targetMapId, 'alpha');
  });
  test(
    'an active portal becomes a passive local point without a fake destination',
    () {
      final map = updateWarpOnMap(
        _map(_portal),
        warpId: 'point',
        triggerMode: MapWarpTriggerMode.sceneOnly,
      );
      expect(map.warps.single.targetMapId, 'alpha');
      expect(map.warps.single.targetPos, _pos);
    },
  );
  test(
    'converting an inert point to active requires an explicit destination',
    () {
      for (final mode in [
        MapWarpTriggerMode.onEnter,
        MapWarpTriggerMode.onBump,
      ]) {
        expect(
          () =>
              updateWarpOnMap(_map(_point), warpId: 'point', triggerMode: mode),
          throwsA(isA<ValidationException>()),
        );
        final map = updateWarpOnMap(
          _map(_point),
          warpId: 'point',
          triggerMode: mode,
          targetMapId: 'beta',
          targetPos: _next,
        );
        expect(map.warps.single.targetMapId, 'beta');
        expect(map.warps.single.targetPos, _next);
      }
    },
  );
  test('typed inert points refuse explicit incompatible internal targets', () {
    final empty = _map(_point).copyWith(warps: const []);
    for (final warp in [
      _point.copyWith(targetMapId: 'beta'),
      _point.copyWith(targetPos: _next),
    ]) {
      expect(
        () => addWarpToMap(empty, warp: warp),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapValidator.validate(_map(warp)),
        throwsA(isA<ValidationException>()),
      );
    }
  });
  test('inert updates reject explicit conflicts before changing the map', () {
    final map = _map(_point);
    expect(
      () => updateWarpOnMap(map, warpId: 'point', targetMapId: 'beta'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => updateWarpOnMap(map, warpId: 'point', pos: _next, targetPos: _pos),
      throwsA(isA<ValidationException>()),
    );
    expect(map.warps.single, _point);
  });
}
