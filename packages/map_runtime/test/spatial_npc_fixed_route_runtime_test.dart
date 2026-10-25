import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/spatial/spatial_npc_fixed_route_runtime.dart';

void main() {
  test('mid-step obstruction resumes the same destination inside fixed bounds', () {
    final host = _Host();
    final runtime = host.runtime();
    runtime.update(.001);
    runtime.update(.04);
    host.blocked = true;
    runtime.update(.04);
    expect(host.saved['actor']!.x, closeTo(2.9, .0001));
    expect(runtime.poseFor('actor')!.motion, CharacterAnimationState.idle);
    runtime.update(3);
    expect(host.saved['actor']!.x, closeTo(2.9, .0001));
    host.blocked = false;
    runtime.update(.06);
    expect(host.saved['actor']!.x, 3.5);
    expect(runtime.poseFor('actor'), isNull);
    runtime.dispose();
  });

  test('an external displacement while paused is never overwritten by the pending route', () {
    final host = _Host();
    final runtime = host.runtime();
    runtime.update(.001);
    runtime.update(.04);
    runtime.update(0, paused: true);
    host.saved['actor'] = SpatialActorRuntimeState(
      x: 1.5,
      z: 1.5,
      facing: EntityFacing.north,
    );
    runtime.update(1, paused: true);
    expect(runtime.poseFor('actor'), isNull);
    expect(host.saved['actor']!.x, 1.5);
    runtime.update(.001);
    expect(runtime.poseFor('actor')!.x, 1.5);
  });
  test('fixed bounds survive repeated moves and a reload away from the initial position', () {
    final host = _Host();
    final runtime = host.runtime();
    runtime.update(.001);
    runtime.update(.1);
    expect(host.saved['actor']!.x, 3.5);
    for (var i = 0; i < 4; i++) {
      runtime.update(.001);
      runtime.update(.1);
    }
    expect(host.saved['actor']!.x, 3.5);
    runtime.dispose();
    final reloaded = host.runtime();
    reloaded.update(.001);
    reloaded.update(.1);
    expect(host.saved['actor']!.x, 3.5);
  });

  test('pause freezes and flushes the visible pose before resuming the pending step', () {
    final host = _Host();
    final runtime = host.runtime();
    runtime.update(.001);
    runtime.update(.04);
    expect(runtime.poseFor('actor')!.x, closeTo(2.9, .0001));
    runtime.update(3, paused: true);
    expect(runtime.poseFor('actor')!.x, closeTo(2.9, .0001));
    expect(host.saved['actor']!.x, closeTo(2.9, .0001));
    runtime.update(.06);
    expect(host.saved['actor']!.x, 3.5);
  });

  test('collision rechecks stop newly blocked movement and variant hiding clears transient poses', () {
    final host = _Host();
    final runtime = host.runtime();
    runtime.update(.001);
    host.blocked = true;
    runtime.update(.04);
    expect(runtime.poseFor('actor'), isNull);
    expect(host.saved['actor']!.x, 2.5);
    host.blocked = false;
    runtime.update(.001);
    expect(runtime.poseFor('actor'), isNotNull);
    host.present = false;
    runtime.update(.1);
    expect(runtime.poseFor('actor'), isNull);
    expect(host.saved['actor']!.x, 2.5);
  });
}

final class _Host {
  bool blocked = false, present = true;
  final saved = <String, SpatialActorRuntimeState>{};
  final map = MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 8, height: 8),
    spatialScene: MapSpatialScene(width: 8, depth: 8),
    entities: [
      MapEntity(
        id: 'actor',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 2, y: 2),
        npc: const MapEntityNpcData(
          movement: MapEntityNpcMovementConfig(
            mode: MapEntityNpcMovementMode.fixedRoute,
            routeSteps: [
              MapEntityNpcRouteStep.move(direction: EntityFacing.east),
            ],
            pauseDurationMs: 1,
            stepDurationMs: 100,
            movementArea: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 3, height: 3),
            ),
          ),
        ),
      ),
    ],
  );

  SpatialNpcFixedRouteRuntime runtime() => SpatialNpcFixedRouteRuntime(
    readMap: () => map,
    readActor: (entity) => saved[entity.id],
    isPresent: (_) => present,
    canTraverse: (entity, x, z, nx, nz, reservations) => !blocked,
    commitActor: (id, value) => saved[id] = value,
    random: Random(3),
  );
}
