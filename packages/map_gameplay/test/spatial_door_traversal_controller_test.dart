import 'dart:math' as math;
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const sourcePos = GridPos(x: 3, y: 4);
const exitPos = GridPos(x: 3, y: 5);
SpatialDoorTraversalBinding binding(String mapId, {double duration = 7 / 30}) =>
    SpatialDoorTraversalBinding(
      mapId: mapId,
      instance: SpatialModelInstance(
          id: 'door', modelId: 'model', position: Model3dVector3.zero),
      openAnimationIndex: 0,
      closeAnimationIndex: 1,
      openDurationSeconds: duration,
      closeDurationSeconds: duration,
      exitPos: exitPos,
    );

void advance(SpatialDoorTraversalController controller, int ticks) {
  for (var tick = 0; tick < ticks; tick++) {
    controller.update(1 / 30);
  }
}

void main() {
  group('HGSS native door optical camera', () {
    const hgss = MapWarpTransition(type: MapWarpTransitionType.hgss);
    const start = (x: 3.5, z: 5.75);

    test('arrival starts at its origin after an asynchronous loading hitch',
        () async {
      final controller = SpatialDoorTraversalController();
      controller.start(
        arrival: binding('outside'),
        arrivalPos: sourcePos,
        transition: hgss,
      );
      advance(controller, 6);
      expect(await controller.readyToTransfer, isTrue);
      controller.transferCompleted();
      controller.update(.108333);
      expect(controller.blackoutOpacity, 1);
      expect(controller.poseFor('outside', 'door')!.normalizedTime, 0);
      expect(controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(96), 1e-10));
      controller.update(1 / 120);
      expect(controller.blackoutOpacity, closeTo(1 - (1 / 120) / .2, 1e-10));
      expect(controller.poseFor('outside', 'door')!.normalizedTime,
          closeTo((1 / 120) / (7 / 30), 1e-10));
    });

    for (final hz in [60, 120]) {
      test('zoom stays smooth through the complete door approach at $hz Hz',
          () {
        final controller = SpatialDoorTraversalController();
        controller.start(
          departure: binding('outside'),
          departurePos: sourcePos,
          departureStart: start,
          transition: hgss,
        );
        final values = [controller.cameraMagnification];
        while (controller.phase == SpatialDoorTraversalPhase.openingDeparture ||
            controller.phase == SpatialDoorTraversalPhase.steppingDeparture) {
          controller.update(1 / hz);
          values.add(controller.cameraMagnification);
        }
        expect(values.last,
            closeTo(_hgssMagnificationFromAngleOffset(108), 1e-10));
        for (var i = 1; i < values.length; i++) {
          expect(values[i], greaterThan(values[i - 1]));
        }
        final firstIncrement = values[1] - values[0];
        final lastIncrement = values.last - values[values.length - 2];
        final middleIncrement =
            values[values.length ~/ 2] - values[values.length ~/ 2 - 1];
        expect(firstIncrement, lessThan(middleIncrement / 4));
        expect(lastIncrement, lessThan(middleIncrement / 4));
        expect(controller.playerPose!.z, 4.5);
        expect(controller.cameraAnchor, start);
        expect(controller.phase, SpatialDoorTraversalPhase.fadingOut);
      });
    }

    test('camera ownership follows only the native map across transfer',
        () async {
      final controller = SpatialDoorTraversalController();
      expect(controller.cameraMapId, isNull);
      controller.start(
          departure: binding('inside'),
          departurePos: sourcePos,
          departureStart: start,
          arrival: binding('outside'),
          arrivalPos: sourcePos,
          transition: hgss);
      expect(controller.cameraMapId, 'inside');
      advance(controller, 21);
      expect(await controller.readyToTransfer, isTrue);
      expect(controller.cameraMapId, 'inside');
      expect(controller.cameraAnchor, start);
      controller.transferCompleted();
      controller.update(1 / 120);
      expect(controller.cameraMapId, 'outside');
      expect(controller.cameraAnchor, isNull);
      controller.cancel();
      expect(controller.cameraMapId, isNull);
      controller.clear();
      expect(controller.cameraMapId, isNull);
    });

    test('departure preserves source amplitude with an eased full approach',
        () {
      final controller = SpatialDoorTraversalController();
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
      controller.start(
          departure: binding('outside'),
          departurePos: sourcePos,
          departureStart: start,
          transition: hgss);
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, start);
      advance(controller, 3);
      expect(
          controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(_departureOffset(3 / 30)),
              1e-10));
      advance(controller, 4);
      expect(controller.phase, SpatialDoorTraversalPhase.steppingDeparture);
      expect(
          controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(_departureOffset(7 / 30)),
              1e-10));
      advance(controller, 2);
      expect(
          controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(_departureOffset(9 / 30)),
              1e-10));
    });

    test(
        'departure anchor stays frozen while the physical hero approaches and black holds the maximum',
        () async {
      final controller = SpatialDoorTraversalController();
      controller.start(
          departure: binding('outside'),
          departurePos: sourcePos,
          departureStart: start,
          transition: hgss);
      advance(controller, 11);
      expect(controller.playerPose!.z, closeTo(5.125, 1e-10));
      expect(controller.cameraAnchor, start);
      expect(
          controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(_departureOffset(11 / 30)),
              1e-10));
      advance(controller, 10);
      expect(await controller.readyToTransfer, isTrue);
      expect(controller.blackoutOpacity, 1);
      expect(controller.playerPose!.z, 4.5);
      expect(controller.cameraAnchor, start);
      controller.update(100);
      expect(controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(108), 1e-10));
      expect(controller.cameraAnchor, start);
      controller.transferCompleted();
      controller.update(1 / 120);
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
      expect(controller.cameraMapId, isNull);
    });

    test(
        'arrival releases ninety six source angle units over two tenths of a second',
        () async {
      final controller = SpatialDoorTraversalController();
      controller.start(
          arrival: binding('outside'), arrivalPos: sourcePos, transition: hgss);
      advance(controller, 6);
      expect(await controller.readyToTransfer, isTrue);
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
      controller.transferCompleted();
      controller.update(1 / 120);
      expect(controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(96), 1e-10));
      expect(controller.cameraAnchor, isNull);
      expect(controller.playerPose!.z, 4.5);
      controller.update(.1);
      expect(controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(48), 1e-10));
      expect(controller.playerPose!.z, 4.5);
      controller.update(.1);
      expect(controller.cameraMagnification, closeTo(1, 1e-10));
      advance(controller, 16);
      expect(await controller.finished, isTrue);
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
      expect(controller.playerPose!.z, 5.5);
    });

    for (final type in [
      MapWarpTransitionType.fade,
      MapWarpTransitionType.none
    ]) {
      test('$type never applies HGSS camera changes to physical doors',
          () async {
        final controller = SpatialDoorTraversalController();
        controller.start(
            departure: binding('inside'),
            departurePos: sourcePos,
            departureStart: start,
            arrival: binding('outside'),
            arrivalPos: sourcePos,
            transition: MapWarpTransition(type: type));
        for (var frame = 0;
            frame < 100 &&
                controller.phase != SpatialDoorTraversalPhase.waitingTransfer;
            frame++) {
          controller.update(1 / 30);
          expect(controller.cameraMagnification, 1);
          expect(controller.cameraAnchor, isNull);
        }
        expect(await controller.readyToTransfer, isTrue);
        controller.transferCompleted();
        controller.update(1 / 120);
        for (var frame = 0; frame < 100 && controller.isActive; frame++) {
          controller.update(1 / 30);
          expect(controller.cameraMagnification, 1);
          expect(controller.cameraAnchor, isNull);
        }
        expect(await controller.finished, isTrue);
      });
    }

    test('a doorless HGSS passage keeps its ordinary camera', () async {
      final controller = SpatialDoorTraversalController();
      controller.start(transition: hgss);
      advance(controller, 3);
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
      advance(controller, 3);
      expect(await controller.readyToTransfer, isTrue);
      controller.transferCompleted();
      controller.update(1 / 120);
      advance(controller, 3);
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
      expect(controller.playerPose, isNull);
    });

    test(
        'pause and invalid deltas freeze optical progress and cancellation clears ownership',
        () {
      final controller = SpatialDoorTraversalController();
      controller.start(
          departure: binding('outside'),
          departurePos: sourcePos,
          departureStart: start,
          transition: hgss);
      advance(controller, 3);
      final magnification = controller.cameraMagnification;
      controller.update(100, paused: true);
      for (final dt in [double.nan, double.infinity, -1.0, 0.0]) {
        controller.update(dt);
      }
      expect(controller.cameraMagnification, magnification);
      expect(controller.cameraAnchor, start);
      controller.cancel();
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
      controller.clear();
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
      controller.start(transition: const MapWarpTransition());
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
    });

    test(
        'a hitch advances the optical clock by admitted phase time rather than raw delta',
        () {
      final controller = SpatialDoorTraversalController();
      controller.start(
          departure: binding('outside'),
          departurePos: sourcePos,
          departureStart: start,
          transition: hgss);
      controller.update(.8);
      expect(controller.poseFor('outside', 'door')!.normalizedTime,
          closeTo(.5, 1e-10));
      expect(
          controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(_departureOffset(7 / 60)),
              1e-10));
      expect(controller.playerPose!.z, start.z);
      controller.update(.8);
      expect(controller.phase, SpatialDoorTraversalPhase.steppingDeparture);
      expect(
          controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(_departureOffset(7 / 30)),
              1e-10));
      controller.update(.8);
      expect(
          controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(_departureOffset(11 / 30)),
              1e-10));
      expect(controller.playerPose!.z, closeTo(5.125, 1e-10));
      expect(controller.cameraAnchor, start);
    });

    test('discarded phase overshoot never inflates the source optical clock',
        () {
      final controller = SpatialDoorTraversalController();
      controller.start(
          departure: binding('outside'),
          departurePos: sourcePos,
          departureStart: start,
          transition: hgss);
      for (var tick = 0; tick < 3; tick++) {
        controller.update(.1);
      }
      expect(controller.phase, SpatialDoorTraversalPhase.steppingDeparture);
      expect(
          controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(_departureOffset(7 / 30)),
              1e-10));
      expect(controller.playerPose!.z, start.z);
      controller.update(1 / 30);
      expect(
          controller.cameraMagnification,
          closeTo(_hgssMagnificationFromAngleOffset(_departureOffset(8 / 30)),
              1e-10));
    });

    test(
        'arrival pause and cancellation never leak magnification into a new passage',
        () async {
      final controller = SpatialDoorTraversalController();
      controller.start(
          arrival: binding('outside'), arrivalPos: sourcePos, transition: hgss);
      advance(controller, 6);
      expect(await controller.readyToTransfer, isTrue);
      controller.transferCompleted();
      controller.update(1 / 120);
      controller.update(.1);
      final magnification = controller.cameraMagnification;
      controller.update(100, paused: true);
      expect(controller.cameraMagnification, magnification);
      controller.cancel();
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
      controller.clear();
      controller.start(
          transition:
              const MapWarpTransition(type: MapWarpTransitionType.none));
      expect(controller.cameraMagnification, 1);
      expect(controller.cameraAnchor, isNull);
    });
  });

  test('explicit screen transition animates a plain passage with its duration',
      () async {
    final controller = SpatialDoorTraversalController();
    controller.start(
        transition: const MapWarpTransition(
            type: MapWarpTransitionType.hgss, durationSeconds: .6));
    expect(controller.phase, SpatialDoorTraversalPhase.fadingOut);
    controller.update(.15);
    expect(controller.blackoutOpacity, closeTo(.25, 1e-9));
    expect(controller.heroVisible, isTrue);
    controller.update(.15, paused: true);
    expect(controller.blackoutOpacity, closeTo(.25, 1e-9));
    for (var i = 0; i < 3; i++) {
      controller.update(.15);
    }
    expect(await controller.readyToTransfer, isTrue);
    expect(controller.blackoutOpacity, 1);
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(controller.revealing, isTrue);
    controller.update(.15);
    expect(controller.blackoutOpacity, closeTo(.75, 1e-9));
    for (var i = 0; i < 3; i++) {
      controller.update(.15);
    }
    expect(await controller.finished, isTrue);
    expect(controller.blackoutOpacity, 0);
  });

  test('none skips screen effects while preserving the physical door steps',
      () async {
    final controller = SpatialDoorTraversalController();
    controller.start(
        departure: binding('outside'),
        departurePos: sourcePos,
        arrival: binding('inside'),
        arrivalPos: sourcePos,
        transition: const MapWarpTransition(type: MapWarpTransitionType.none));
    advance(controller, 15);
    controller.update(1 / 30);
    expect(await controller.readyToTransfer, isTrue);
    expect(controller.blackoutOpacity, 0);
    expect(controller.playerPose!.z, 4.5);
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(controller.heroVisible, isFalse);
    advance(controller, 7);
    expect(controller.heroVisible, isTrue);
    advance(controller, 15);
    expect(await controller.finished, isTrue);
    expect(controller.playerPose!.z, 5.5);
    expect(controller.blackoutOpacity, 0);
  });

  test(
      'native player pose identifies its map across the physical transfer barrier',
      () async {
    final controller = SpatialDoorTraversalController();
    expect(controller.playerPoseMapId, isNull);
    controller.start(
        departure: binding('inside'),
        departurePos: sourcePos,
        arrival: binding('outside'),
        arrivalPos: sourcePos);
    expect(controller.playerPoseMapId, 'inside');
    advance(controller, 7);
    expect(controller.phase, SpatialDoorTraversalPhase.steppingDeparture);
    expect(controller.playerPoseMapId, 'inside');
    advance(controller, 8);
    expect(controller.phase, SpatialDoorTraversalPhase.fadingOut);
    expect(controller.playerPoseMapId, 'inside');
    advance(controller, 6);
    expect(await controller.readyToTransfer, isTrue);
    expect(controller.phase, SpatialDoorTraversalPhase.waitingTransfer);
    expect(controller.playerPoseMapId, 'inside');
    controller.update(100);
    expect(controller.playerPoseMapId, 'inside');
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(controller.playerPoseMapId, 'outside');
    advance(controller, 22);
    expect(await controller.finished, isTrue);
    expect(controller.playerPoseMapId, 'outside');
    controller.clear();
    expect(controller.playerPoseMapId, isNull);
  });

  test(
      'native player pose map is absent after cancellation or arrival without a door',
      () async {
    final controller = SpatialDoorTraversalController();
    controller.start(departure: binding('inside'), departurePos: sourcePos);
    expect(controller.playerPoseMapId, 'inside');
    controller.cancel();
    expect(controller.playerPoseMapId, isNull);
    controller.start(departure: binding('inside'), departurePos: sourcePos);
    advance(controller, 21);
    expect(await controller.readyToTransfer, isTrue);
    expect(controller.playerPoseMapId, 'inside');
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(controller.playerPose, isNull);
    expect(controller.playerPoseMapId, isNull);
    controller.clear();
    controller.start(arrival: binding('outside'), arrivalPos: sourcePos);
    expect(controller.playerPoseMapId, isNull);
    advance(controller, 6);
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(controller.playerPoseMapId, 'outside');
    controller.cancel();
    expect(controller.playerPoseMapId, isNull);
    controller.start();
    expect(controller.playerPoseMapId, isNull);
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(controller.playerPoseMapId, isNull);
  });

  test('ten FPS preserves elapsed opening time and a half-fade pose', () {
    final controller = SpatialDoorTraversalController();
    controller.start(departure: binding('outside'), departurePos: sourcePos);
    controller.update(.1);
    expect(controller.poseFor('outside', 'door')!.normalizedTime,
        closeTo(3 / 7, 1e-12));
    controller.update(.1);
    controller.update(.1);
    expect(controller.phase, SpatialDoorTraversalPhase.steppingDeparture);
    controller.update(.1);
    controller.update(.1);
    controller.update(.1);
    expect(controller.phase, SpatialDoorTraversalPhase.fadingOut);
    controller.update(.1);
    expect(controller.blackoutOpacity, closeTo(.5, 1e-12));
  });

  for (final dt in [1 / 3, .8]) {
    test('a hitch presents opening midpoint before completing at dt=$dt', () {
      final controller = SpatialDoorTraversalController();
      controller.start(departure: binding('outside'), departurePos: sourcePos);
      controller.update(dt);
      expect(controller.phase, SpatialDoorTraversalPhase.openingDeparture);
      expect(controller.poseFor('outside', 'door')!.normalizedTime,
          closeTo(.5, 1e-12));
      controller.update(dt);
      expect(controller.phase, SpatialDoorTraversalPhase.steppingDeparture);
      expect(controller.playerPose!.z, 5.5);
    });
  }

  for (final targetPhase in [
    SpatialDoorTraversalPhase.openingDeparture,
    SpatialDoorTraversalPhase.steppingDeparture,
    SpatialDoorTraversalPhase.fadingOut
  ]) {
    test(
        'ten FPS phase duration stays within one update of sixty FPS for $targetPhase',
        () {
      double measuredDuration(double dt) {
        final controller = SpatialDoorTraversalController();
        controller.start(
            departure: binding('outside'), departurePos: sourcePos);
        for (var tick = 0;
            tick < 60 && controller.phase != targetPhase;
            tick++) {
          controller.update(1 / 30);
        }
        expect(controller.phase, targetPhase);
        var elapsed = 0.0;
        for (var tick = 0;
            tick < 60 && controller.phase == targetPhase;
            tick++) {
          controller.update(dt);
          elapsed += dt;
        }
        expect(controller.phase, isNot(targetPhase));
        return elapsed;
      }

      expect((measuredDuration(.1) - measuredDuration(1 / 60)).abs(),
          lessThanOrEqualTo(.1 + 1e-12));
    });
  }

  test('source opening completion does not authorize immediate teleport',
      () async {
    final controller = SpatialDoorTraversalController();
    controller.start(departure: binding('outside'), departurePos: sourcePos);
    var transferable = false;
    controller.readyToTransfer.then((value) => transferable = value);
    advance(controller, 7);
    await Future<void>.delayed(Duration.zero);
    expect(transferable, isFalse);
    expect(controller.phase, SpatialDoorTraversalPhase.steppingDeparture);
    expect(controller.playerPose!.z, 5.5);
    expect(controller.heroVisible, isTrue);
    advance(controller, 4);
    expect(controller.playerPose!.z, closeTo(5, 1e-12));
    expect(controller.playerPose!.facing, EntityFacing.north);
    advance(controller, 4);
    expect(controller.phase, SpatialDoorTraversalPhase.fadingOut);
    expect(controller.playerPose!.z, 4.5);
    expect(controller.heroVisible, isFalse);
    expect(controller.blackoutOpacity, closeTo(0, 1e-12));
    advance(controller, 3);
    expect(controller.blackoutOpacity, closeTo(.5, 1e-12));
    advance(controller, 3);
    expect(await controller.readyToTransfer, isTrue);
    expect(controller.phase, SpatialDoorTraversalPhase.waitingTransfer);
    expect(controller.blackoutOpacity, 1);
    expect(controller.heroVisible, isFalse);
    controller.update(100);
    expect(controller.blackoutOpacity, 1);
  });

  test('float32 source opening ends after seven nominal ticks before step', () {
    final controller = SpatialDoorTraversalController();
    controller.start(
        departure:
            binding('outside', duration: Float32List.fromList([7 / 30]).single),
        departurePos: sourcePos);
    advance(controller, 7);
    expect(controller.phase, SpatialDoorTraversalPhase.steppingDeparture);
    expect(controller.poseFor('outside', 'door')!.normalizedTime, 1);
  });

  test('arrival fades and opens in parallel while hero remains hidden',
      () async {
    final controller = SpatialDoorTraversalController();
    controller.start(arrival: binding('outside'), arrivalPos: sourcePos);
    expect(controller.phase, SpatialDoorTraversalPhase.fadingOut);
    advance(controller, 6);
    expect(await controller.readyToTransfer, isTrue);
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(controller.phase, SpatialDoorTraversalPhase.fadingInArrival);
    expect(controller.blackoutOpacity, 1);
    expect(controller.heroVisible, isFalse);
    advance(controller, 3);
    expect(controller.blackoutOpacity, closeTo(.5, 1e-12));
    expect(controller.poseFor('outside', 'door')!.normalizedTime,
        closeTo(3 / 7, 1e-12));
    advance(controller, 3);
    expect(controller.blackoutOpacity, closeTo(0, 1e-12));
    expect(controller.heroVisible, isFalse);
    advance(controller, 1);
    expect(controller.phase, SpatialDoorTraversalPhase.steppingArrival);
    expect(controller.heroVisible, isTrue);
    advance(controller, 4);
    expect(controller.playerPose!.z, closeTo(5, 1e-12));
    advance(controller, 4);
    expect(controller.phase, SpatialDoorTraversalPhase.closingArrival);
    expect(controller.playerPose!.z, 5.5);
    expect(controller.playerPose!.facing, EntityFacing.south);
    expect(controller.poseFor('outside', 'door')!.animationIndex, 1);
    advance(controller, 7);
    expect(await controller.finished, isTrue);
    expect(controller.phase, SpatialDoorTraversalPhase.completed);
    expect(controller.poseFor('outside', 'door')!.normalizedTime, 1);
    expect(controller.blackoutOpacity, closeTo(0, 1e-12));
  });

  for (final dt in [1 / 60, 1 / 30, 1 / 3, .8]) {
    test('presentation retains source, fade and arrival poses at dt=$dt',
        () async {
      final controller = SpatialDoorTraversalController();
      controller.start(
          departure: binding('inside'),
          departurePos: sourcePos,
          departureStart: (x: 3.5, z: 5.75),
          arrival: binding('outside'),
          arrivalPos: sourcePos);
      final observed = <SpatialDoorTraversalPhase>{controller.phase};
      final sourcePositions = <double>{};
      final arrivalPositions = <double>{};
      final sourceFade = <double>{};
      final arrivalFade = <double>{};
      for (var frame = 0;
          frame < 500 &&
              controller.phase != SpatialDoorTraversalPhase.waitingTransfer;
          frame++) {
        controller.update(dt);
        observed.add(controller.phase);
        if (controller.phase == SpatialDoorTraversalPhase.steppingDeparture) {
          sourcePositions.add(controller.playerPose!.z);
        }
        if (controller.phase == SpatialDoorTraversalPhase.fadingOut) {
          sourceFade.add(controller.blackoutOpacity);
        }
      }
      expect(await controller.readyToTransfer, isTrue);
      controller.transferCompleted();
      controller.update(1 / 120);
      observed.add(controller.phase);
      arrivalFade.add(controller.blackoutOpacity);
      for (var frame = 0; frame < 500 && controller.isActive; frame++) {
        controller.update(dt);
        observed.add(controller.phase);
        if (controller.phase == SpatialDoorTraversalPhase.steppingArrival) {
          arrivalPositions.add(controller.playerPose!.z);
        }
        if (controller.phase == SpatialDoorTraversalPhase.fadingInArrival) {
          arrivalFade.add(controller.blackoutOpacity);
        }
      }
      expect(await controller.finished, isTrue);
      expect(
          observed,
          containsAll([
            SpatialDoorTraversalPhase.openingDeparture,
            SpatialDoorTraversalPhase.steppingDeparture,
            SpatialDoorTraversalPhase.fadingOut,
            SpatialDoorTraversalPhase.waitingTransfer,
            SpatialDoorTraversalPhase.fadingInArrival,
            SpatialDoorTraversalPhase.steppingArrival,
            SpatialDoorTraversalPhase.closingArrival,
            SpatialDoorTraversalPhase.completed
          ]));
      expect(sourcePositions.length, greaterThanOrEqualTo(2));
      expect(arrivalPositions.length, greaterThanOrEqualTo(2));
      expect(sourceFade.length, greaterThanOrEqualTo(2));
      expect(arrivalFade.length, greaterThanOrEqualTo(2));
    });
  }

  test('user pause freezes both visibility and presentation clocks', () {
    final controller = SpatialDoorTraversalController();
    controller.start(arrival: binding('outside'), arrivalPos: sourcePos);
    advance(controller, 3);
    final opacity = controller.blackoutOpacity;
    final phase = controller.phase;
    controller.update(100, paused: true);
    expect(controller.blackoutOpacity, opacity);
    expect(controller.phase, phase);
    expect(controller.heroVisible, isFalse);
    advance(controller, 3);
    controller.transferCompleted();
    controller.update(1 / 120);
    advance(controller, 2);
    final pose = controller.poseFor('outside', 'door');
    controller.update(100, paused: true);
    expect(controller.poseFor('outside', 'door'), pose);
  });

  test('cancellation settles futures and restores a visible unshaded hero',
      () async {
    final controller = SpatialDoorTraversalController();
    controller.start(departure: binding('outside'), departurePos: sourcePos);
    final ready = controller.readyToTransfer, finished = controller.finished;
    advance(controller, 17);
    expect(controller.blackoutOpacity, greaterThan(0));
    controller.cancel();
    expect(await ready, isFalse);
    expect(await finished, isFalse);
    expect(controller.heroVisible, isTrue);
    expect(controller.blackoutOpacity, closeTo(0, 1e-12));
    expect(controller.playerPose, isNull);
    expect(controller.poseFor('outside', 'door'), isNull);
    controller.clear();
    expect(controller.phase, SpatialDoorTraversalPhase.idle);
  });

  test('departure-only passage fades into a normal destination without a step',
      () async {
    final controller = SpatialDoorTraversalController();
    controller.start(departure: binding('outside'), departurePos: sourcePos);
    advance(controller, 21);
    expect(await controller.readyToTransfer, isTrue);
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(controller.heroVisible, isTrue);
    expect(controller.blackoutOpacity, 1);
    advance(controller, 6);
    expect(await controller.finished, isTrue);
    expect(controller.playerPose, isNull);
  });

  test(
      'a controller without a door keeps immediate ordinary transfer semantics',
      () async {
    final controller = SpatialDoorTraversalController();
    controller.start();
    expect(await controller.readyToTransfer, isTrue);
    expect(controller.heroVisible, isTrue);
    expect(controller.blackoutOpacity, closeTo(0, 1e-12));
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(await controller.finished, isTrue);
    expect(controller.phase, SpatialDoorTraversalPhase.completed);
  });

  test('one shared instance preserves departure pose until physical transfer',
      () {
    final controller = SpatialDoorTraversalController();
    final door = binding('outside');
    controller.start(
        departure: door,
        departurePos: sourcePos,
        arrival: door,
        arrivalPos: sourcePos);
    advance(controller, 3);
    expect(controller.poseFor('outside', 'door')!.normalizedTime,
        closeTo(3 / 7, 1e-12));
    advance(controller, 18);
    controller.transferCompleted();
    controller.update(1 / 120);
    expect(controller.poseFor('outside', 'door')!.normalizedTime, 0);
  });

  test('invalid deltas never move presentation', () {
    final controller = SpatialDoorTraversalController();
    controller.start(departure: binding('outside'), departurePos: sourcePos);
    for (final dt in [double.nan, double.infinity, -1.0, 0.0]) {
      controller.update(dt);
    }
    expect(controller.poseFor('outside', 'door')!.normalizedTime, 0);
    expect(controller.blackoutOpacity, closeTo(0, 1e-12));
  });

  test('source binding requires a cardinal threshold and finite adjacent start',
      () {
    final controller = SpatialDoorTraversalController();
    expect(() => controller.start(departure: binding('outside')),
        throwsArgumentError);
    expect(
        () => controller.start(
            departure: binding('outside'), departurePos: exitPos),
        throwsArgumentError);
    expect(
        () => controller.start(
            departure: binding('outside'),
            departurePos: sourcePos,
            departureStart: (x: double.nan, z: 5.5)),
        throwsArgumentError);
    expect(
        () => controller.start(
            departure: binding('outside'),
            departurePos: sourcePos,
            departureStart: (x: 2.5, z: 5.5)),
        throwsArgumentError);
    expect(
        () =>
            controller.start(arrival: binding('outside'), arrivalPos: exitPos),
        throwsArgumentError);
  });
}

double _hgssMagnificationFromAngleOffset(double offset) =>
    math.tan(1473 * 2 * math.pi / 65536) /
    math.tan((1473 - offset) * 2 * math.pi / 65536);

double _departureOffset(double seconds) {
  final progress = (seconds / (15 / 30)).clamp(0.0, 1.0);
  return 108 * progress * progress * (3 - 2 * progress);
}
