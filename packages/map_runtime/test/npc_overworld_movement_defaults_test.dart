import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('resolveNpcDefaultPatrolRoute', () {
    test('returns null for idle mode', () {
      const entity = MapEntity(
        id: 'npc_1',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(
          movement: MapEntityNpcMovementConfig(
            mode: MapEntityNpcMovementMode.idle,
          ),
        ),
      );
      expect(resolveNpcDefaultPatrolRoute(entity), isNull);
    });

    test('returns null for scriptedOnly mode', () {
      const entity = MapEntity(
        id: 'npc_1',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(
          movement: MapEntityNpcMovementConfig(
            mode: MapEntityNpcMovementMode.scriptedOnly,
          ),
        ),
      );
      expect(resolveNpcDefaultPatrolRoute(entity), isNull);
    });

    test('returns null when patrol has less than 2 waypoints', () {
      const entity = MapEntity(
        id: 'npc_1',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(
          movement: MapEntityNpcMovementConfig(
            mode: MapEntityNpcMovementMode.patrol,
            waypoints: <GridPos>[GridPos(x: 2, y: 3)],
          ),
        ),
      );
      expect(resolveNpcDefaultPatrolRoute(entity), isNull);
    });

    test('builds route for patrol mode with valid waypoints', () {
      const entity = MapEntity(
        id: 'npc_1',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(
          movement: MapEntityNpcMovementConfig(
            mode: MapEntityNpcMovementMode.patrol,
            waypoints: <GridPos>[
              GridPos(x: 2, y: 3),
              GridPos(x: 6, y: 3),
            ],
            loop: false,
            pauseDurationMs: 500,
            stepDurationMs: 320,
          ),
        ),
      );
      final route = resolveNpcDefaultPatrolRoute(entity);
      expect(route, isNotNull);
      expect(route!.entityId, 'npc_1');
      expect(route.waypoints, hasLength(2));
      expect(route.loop, isFalse);
      expect(route.pauseDurationMs, 500);
      expect(route.stepDurationMs, 320);
    });
  });
}
