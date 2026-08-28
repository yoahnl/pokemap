import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/placed_element_warp_traversal_controller.dart';

void main() {
  group('PlacedElementWarpTraversalController', () {
    test('releases the warp exactly when the one-shot duration completes', () {
      final controller = PlacedElementWarpTraversalController();
      const warp = TriggeredWarp(
        warpId: 'placed:door:enter',
        targetMapId: 'station-interior',
        targetPos: GridPos(x: 4, y: 7),
        triggerMode: MapWarpTriggerMode.onBump,
      );

      expect(
        controller.tryStart(
          const PlacedElementWarpTraversalPlan(
            instanceId: 'door',
            warp: warp,
            animationDurationMs: 250,
          ),
          nowMs: 1000,
        ),
        isTrue,
      );
      expect(controller.takeCompleted(nowMs: 1249), isNull);
      expect(controller.takeCompleted(nowMs: 1250), warp);
      expect(controller.takeCompleted(nowMs: 2000), isNull);
    });

    test('rejects a second traversal until the current one completes', () {
      final controller = PlacedElementWarpTraversalController();
      const first = PlacedElementWarpTraversalPlan(
        instanceId: 'door-a',
        warp: TriggeredWarp(
          warpId: 'placed:door-a:enter',
          targetMapId: 'room-a',
          targetPos: GridPos(x: 1, y: 1),
          triggerMode: MapWarpTriggerMode.onBump,
        ),
        animationDurationMs: 100,
      );
      const second = PlacedElementWarpTraversalPlan(
        instanceId: 'door-b',
        warp: TriggeredWarp(
          warpId: 'placed:door-b:enter',
          targetMapId: 'room-b',
          targetPos: GridPos(x: 2, y: 2),
          triggerMode: MapWarpTriggerMode.onBump,
        ),
        animationDurationMs: 100,
      );

      expect(controller.tryStart(first, nowMs: 0), isTrue);
      expect(controller.tryStart(second, nowMs: 10), isFalse);
      expect(controller.takeCompleted(nowMs: 100), first.warp);
      expect(controller.tryStart(second, nowMs: 101), isTrue);
    });

    test('clear cancels a pending traversal', () {
      final controller = PlacedElementWarpTraversalController();
      const plan = PlacedElementWarpTraversalPlan(
        instanceId: 'door',
        warp: TriggeredWarp(
          warpId: 'placed:door:enter',
          targetMapId: 'room',
          targetPos: GridPos(x: 1, y: 1),
          triggerMode: MapWarpTriggerMode.onBump,
        ),
        animationDurationMs: 100,
      );

      controller.tryStart(plan, nowMs: 0);
      controller.clear();

      expect(controller.takeCompleted(nowMs: 100), isNull);
      expect(controller.isActive, isFalse);
    });
  });
}
