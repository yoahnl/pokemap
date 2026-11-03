import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_camera_motion.dart';

const home = (
  position: (x: 27443, y: 27443, z: 70861),
  target: (x: 0, y: 10650, z: 0),
);
const player = (
  position: (x: 0x5ca6, y: 24371, z: 0x13cc3),
  target: (x: -0xe8d, y: 7578, z: 0x27f6),
);
const enemy = (
  position: (x: 0x6994, y: 28467, z: 0x6e79),
  target: (x: -0x19f, y: 11674, z: -0xa654),
);

Gen5CameraPresetEffect start(
  Gen5CameraMotion camera, {
  int preset = 8,
  Gen5CameraSlot attacker = Gen5CameraSlot.player,
  Gen5CameraSlot defender = Gen5CameraSlot.enemy,
  int frames = 16,
  int wait = 0,
  int brake = 0,
  Gen5CameraMoveType moveType = Gen5CameraMoveType.step,
}) => camera.applyPreset(
  preset: preset,
  attacker: attacker,
  defender: defender,
  frames: frames,
  wait: wait,
  brake: brake,
  moveType: moveType,
);

void main() {
  test('BW2 pinned source default and solo poses use exact fx32 values', () {
    final camera = Gen5CameraMotion();
    expect(camera.pose, home);
    expect(camera.isMoving, isFalse);

    expect(
      start(camera, preset: 9, moveType: Gen5CameraMoveType.immediate),
      Gen5CameraPresetEffect.camera,
    );
    expect(camera.pose, player);
    start(camera, preset: 11, moveType: Gen5CameraMoveType.immediate);
    expect(camera.pose, enemy);
    start(camera, moveType: Gen5CameraMoveType.immediate);
    expect(camera.pose, home);
  });

  test('presets 9 and 11 resolve the supplied attacker and target slots', () {
    final camera = Gen5CameraMotion();
    start(
      camera,
      preset: 9,
      attacker: Gen5CameraSlot.enemy,
      defender: Gen5CameraSlot.player,
      moveType: Gen5CameraMoveType.immediate,
    );
    expect(camera.pose, enemy);
    start(
      camera,
      preset: 11,
      attacker: Gen5CameraSlot.enemy,
      defender: Gen5CameraSlot.player,
      moveType: Gen5CameraMoveType.immediate,
    );
    expect(camera.pose, player);
  });

  test('Charge camera follows the pinned BW2 fx32 tick trace', () {
    final camera = Gen5CameraMotion();
    start(camera, preset: 11, frames: 16, brake: 8);
    const expected = {
      1: (
        position: (x: 27417, y: 27507, z: 68200),
        target: (x: -26, y: 10714, z: -2661),
      ),
      7: (
        position: (x: 27261, y: 27891, z: 52234),
        target: (x: -182, y: 11098, z: -18627),
      ),
      8: (
        position: (x: 27248, y: 27923, z: 50903),
        target: (x: -195, y: 11130, z: -19958),
      ),
      16: (
        position: (x: 27144, y: 28179, z: 40255),
        target: (x: -299, y: 11386, z: -30606),
      ),
      24: (
        position: (x: 27040, y: 28435, z: 29607),
        target: (x: -403, y: 11642, z: -41254),
      ),
      25: enemy,
    };
    for (var tick = 1; tick <= 25; tick++) {
      final pose = camera.tick();
      if (expected.containsKey(tick)) expect(pose, expected[tick]);
      expect(camera.isMoving, tick < 25);
    }
  });

  test('source division rounds signed half steps and clamps independently', () {
    final camera = Gen5CameraMotion(
      initialPose: (
        position: (
          x: home.position.x - 6,
          y: home.position.y,
          z: home.position.z,
        ),
        target: (x: home.target.x + 6, y: home.target.y, z: home.target.z),
      ),
    );
    start(camera, frames: 4);
    expect(camera.tick().position.x, home.position.x - 4);
    expect(camera.pose.target.x, home.target.x + 5);
    camera.tick();
    camera.tick();
    expect(camera.pose.position.x, home.position.x);
    expect(camera.pose.target.x, home.target.x + 3);
    expect(camera.isMoving, isTrue);
    camera.tick();
    camera.tick();
    expect(camera.tick(), home);
    expect(camera.isMoving, isFalse);
  });

  test('wait delays steps and braking halves the step before its step', () {
    final camera = Gen5CameraMotion(
      initialPose: (
        position: (
          x: home.position.x - 12,
          y: home.position.y,
          z: home.position.z,
        ),
        target: home.target,
      ),
    );
    start(camera, frames: 4, wait: 1, brake: 2);
    expect(camera.tick().position.x, home.position.x - 12);
    expect(camera.tick().position.x, home.position.x - 9);
    expect(camera.tick().position.x, home.position.x - 9);
    expect(camera.tick().position.x, home.position.x - 8);
    for (var i = 0; i < 16; i++) {
      camera.tick();
    }
    expect(camera.pose, home);
    expect(camera.isMoving, isFalse);
  });

  test('retarget starts at the current pose with a new step', () {
    final camera = Gen5CameraMotion();
    start(camera, preset: 11, frames: 4);
    expect(camera.tick(), (
      position: (x: 27339, y: 27699, z: 60216),
      target: (x: -104, y: 10906, z: -10645),
    ));
    final before = camera.pose;
    start(camera, preset: 9, frames: 4);
    expect(camera.pose, before);
    expect(camera.tick(), (
      position: (x: 26434, y: 26867, z: 65435),
      target: (x: -1009, y: 10074, z: -5426),
    ));
  });

  test('same-goal move completes on the next eligible tick', () {
    final camera = Gen5CameraMotion();
    start(camera, frames: 40);
    expect(camera.isMoving, isTrue);
    expect(camera.tick(), home);
    expect(camera.isMoving, isFalse);
  });

  test('zero frames reach the goal on the next eligible tick', () {
    final camera = Gen5CameraMotion();
    start(camera, preset: 11, frames: 0, wait: 1);
    expect(camera.tick(), home);
    expect(camera.isMoving, isTrue);
    expect(camera.tick(), enemy);
    expect(camera.isMoving, isFalse);
  });

  test('preset 20 signals flat actors without cancelling active movement', () {
    final camera = Gen5CameraMotion();
    final control = Gen5CameraMotion();
    start(camera, preset: 11);
    start(control, preset: 11);
    expect(camera.tick(), control.tick());
    final before = camera.pose;
    expect(start(camera, preset: 20), Gen5CameraPresetEffect.setFlatActors);
    expect(camera.pose, before);
    expect(camera.isMoving, isTrue);
    expect(camera.tick(), control.tick());
  });

  test('immediate positioning preserves a previously active source move', () {
    final camera = Gen5CameraMotion();
    start(camera, preset: 9, frames: 4);
    camera.tick();
    start(camera, preset: 11, moveType: Gen5CameraMoveType.immediate);
    expect(camera.pose, enemy);
    expect(camera.isMoving, isTrue);
    expect(camera.tick(), isNot(enemy));
  });

  test('invalid parameters fail before changing the camera', () {
    final camera = Gen5CameraMotion();
    for (final call in <void Function()>[
      () => start(camera, preset: 7),
      () => start(camera, frames: -1),
      () => start(camera, frames: 0x80000),
      () => start(camera, wait: -1),
      () => start(camera, brake: -1),
      () => start(camera, wait: 0x80000000),
      () => start(camera, brake: 0x80000000),
    ]) {
      expect(call, throwsArgumentError);
      expect(camera.pose, home);
      expect(camera.isMoving, isFalse);
    }
    expect(
      () => Gen5CameraMotion(
        initialPose: (
          position: (x: 0x80000000, y: 0, z: 0),
          target: home.target,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('invalid retarget leaves an active source movement untouched', () {
    final camera = Gen5CameraMotion();
    final control = Gen5CameraMotion();
    start(camera, preset: 11);
    start(control, preset: 11);
    expect(camera.tick(), control.tick());
    expect(() => start(camera, preset: 9, frames: -1), throwsArgumentError);
    expect(camera.isMoving, isTrue);
    expect(camera.tick(), control.tick());
  });

  test('Surf shake follows the BW2 source ticks and returns to zero', () {
    final camera = Gen5CameraMotion();
    camera.shakeVertical(amplitude: 410, wait: 1, count: 14);
    final offsets = <int>[];
    for (var tick = 1; tick <= 111; tick++) {
      final pose = camera.tick();
      offsets.add(pose.position.y - home.position.y);
      expect(pose.target.y - home.target.y, offsets.last);
      expect(camera.isMoving, tick < 111);
    }
    expect(offsets.take(8), [410, 410, 0, 0, -410, -410, 0, 0]);
    expect(offsets.last, 0);
    expect(camera.pose, home);
  });

  test(
    'Surf shake composes with a moving camera without changing its path',
    () {
      final camera = Gen5CameraMotion();
      final control = Gen5CameraMotion();
      start(camera, preset: 11, frames: 4);
      start(control, preset: 11, frames: 4);
      camera.shakeVertical(amplitude: 410, wait: 1, count: 1);
      final offsets = <int>[];
      for (var tick = 0; tick < 8; tick++) {
        final actual = camera.tick();
        final base = control.tick();
        offsets.add(actual.position.y - base.position.y);
        expect(actual.target.y - base.target.y, offsets.last);
        expect(actual.position.x, base.position.x);
        expect(actual.position.z, base.position.z);
      }
      expect(offsets, [410, 410, 0, 0, -410, -410, 0, 0]);
      expect(camera.pose, control.pose);
    },
  );
}
