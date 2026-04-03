import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapEntityNpcMovementConfig', () {
    test('defaults to idle with safe values', () {
      const npc = MapEntityNpcData();
      expect(npc.movement.mode, MapEntityNpcMovementMode.idle);
      expect(npc.movement.waypoints, isEmpty);
      expect(npc.movement.loop, isTrue);
      expect(npc.movement.pauseDurationMs, 0);
      expect(npc.movement.stepDurationMs, 200);
    });

    test('serializes and deserializes patrol configuration', () {
      const npc = MapEntityNpcData(
        movement: MapEntityNpcMovementConfig(
          mode: MapEntityNpcMovementMode.patrol,
          waypoints: <GridPos>[
            GridPos(x: 3, y: 4),
            GridPos(x: 7, y: 4),
          ],
          loop: false,
          pauseDurationMs: 450,
          stepDurationMs: 260,
        ),
      );
      final json = npc.toJson();
      final decoded = MapEntityNpcData.fromJson(json);

      expect(decoded.movement.mode, MapEntityNpcMovementMode.patrol);
      expect(decoded.movement.waypoints, hasLength(2));
      expect(decoded.movement.waypoints[0], const GridPos(x: 3, y: 4));
      expect(decoded.movement.waypoints[1], const GridPos(x: 7, y: 4));
      expect(decoded.movement.loop, isFalse);
      expect(decoded.movement.pauseDurationMs, 450);
      expect(decoded.movement.stepDurationMs, 260);
    });

    test('backward compatibility keeps idle defaults when movement is absent',
        () {
      final decoded = MapEntityNpcData.fromJson(<String, dynamic>{
        'displayName': 'Professor',
        'facing': 'south',
      });

      expect(decoded.displayName, 'Professor');
      expect(decoded.movement.mode, MapEntityNpcMovementMode.idle);
      expect(decoded.movement.waypoints, isEmpty);
      expect(decoded.movement.loop, isTrue);
      expect(decoded.movement.pauseDurationMs, 0);
      expect(decoded.movement.stepDurationMs, 200);
    });
  });
}
