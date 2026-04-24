import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_camera_rig.dart';

void main() {
  group('BattleCameraRig', () {
    test('moveTo interpolates offset and scale then holds final state', () {
      final rig = BattleCameraRig();

      rig.moveTo(
        offset: Vector2(30, -12),
        scale: 1.12,
        durationSeconds: 0.50,
        curve: BattleFxMotionCurve.linear,
      );

      rig.update(0.25);
      expect(rig.isActive, isTrue);
      expect(rig.offset.x, closeTo(15, 0.001));
      expect(rig.offset.y, closeTo(-6, 0.001));
      expect(rig.scale, closeTo(1.06, 0.001));

      rig.update(0.25);
      expect(rig.isActive, isFalse);
      expect(rig.offset, equals(Vector2(30, -12)));
      expect(rig.scale, closeTo(1.12, 0.001));
    });

    test('focus presets and reset return exactly to battle pose', () {
      final rig = BattleCameraRig();

      rig.focusTarget(durationSeconds: 0.10);
      rig.update(0.10);
      expect(rig.offset.length, greaterThan(0));
      expect(rig.scale, greaterThan(1));

      rig.reset(durationSeconds: 0.20);
      rig.update(0.10);
      expect(rig.offset.length, greaterThan(0));
      expect(rig.scale, greaterThan(1));

      rig.update(0.10);
      expect(rig.isActive, isFalse);
      expect(rig.offset, equals(Vector2.zero()));
      expect(rig.scale, equals(1));
    });

    test('cancel snaps back to neutral state', () {
      final rig = BattleCameraRig();

      rig.focusUser(durationSeconds: 0.40);
      rig.update(0.20);
      rig.cancel();

      expect(rig.isActive, isFalse);
      expect(rig.offset, equals(Vector2.zero()));
      expect(rig.scale, equals(1));
    });
  });
}
