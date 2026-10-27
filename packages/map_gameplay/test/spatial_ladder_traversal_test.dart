import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final direction in MapWarpLadderDirection.values) {
    test('ladder $direction climbs before fade and keeps real source position',
        () async {
      final controller = SpatialDoorTraversalController();
      expect(
          controller.start(
              ladder: MapWarpLadder(direction: direction, durationSeconds: .5),
              departureMapId: 'lower',
              departureStart: (x: 2.4375, z: 3.5),
              transition: const MapWarpTransition(durationSeconds: .2)),
          isTrue);
      expect(controller.isClimbing, isTrue);
      controller.update(.25);
      final pose = controller.playerPose!;
      expect(pose.x, 2.4375);
      expect(pose.z, 3.5);
      expect(pose.liftCells,
          closeTo(direction == MapWarpLadderDirection.up ? 1 : -1, 1e-6));
      expect(controller.blackoutOpacity, 0);
      controller.update(.1, paused: true);
      expect(controller.playerPose!.liftCells, pose.liftCells);
      controller.update(.25);
      expect(controller.phase, SpatialDoorTraversalPhase.fadingOut);
      controller.update(.1);
      controller.update(.1);
      expect(await controller.readyToTransfer, isTrue);
      controller.transferCompleted();
      controller.update(.1);
      controller.update(.1);
      controller.update(.1);
      expect(await controller.finished, isTrue);
      expect(controller.isClimbing, isFalse);
      expect(controller.playerPose, isNull);
    });
  }
  test('cancelled ladder releases the transfer lease without persisting a pose',
      () async {
    final controller = SpatialDoorTraversalController();
    controller.start(
        ladder: MapWarpLadder(),
        departureMapId: 'room',
        departureStart: (x: 1.5, z: 1.5));
    controller.update(.1);
    controller.cancel();
    expect(await controller.readyToTransfer, isFalse);
    expect(await controller.finished, isFalse);
    expect(controller.playerPose, isNull);
    controller.clear();
    expect(controller.isActive, isFalse);
  });
}
