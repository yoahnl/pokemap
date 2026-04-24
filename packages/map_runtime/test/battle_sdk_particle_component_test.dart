import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_particle_component.dart';

Future<ui.Image> _fakeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 12, 12),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImage(12, 12);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleSdkParticleComponent', () {
    test('waits for delay then interpolates position, scale and opacity',
        () async {
      final image = await _fakeImage();
      final component = BattleSdkParticleComponent(
        sprite: Sprite(image),
        startPosition: Vector2(10, 20),
        endPosition: Vector2(30, 60),
        startScaleX: 0.2,
        startScaleY: 0.4,
        endScaleX: 1.0,
        endScaleY: 0.6,
        startOpacity: 1,
        endOpacity: 0,
        delaySeconds: 0.10,
        durationSeconds: 0.40,
        rotationTurns: 0.5,
        tintColor: const ui.Color(0xCCB942F4),
      );

      component.update(0.05);

      expect(component.position, equals(Vector2(10, 20)));
      expect(component.currentOpacity, equals(0));

      component.update(0.25);

      expect(component.position.x, closeTo(20, 0.001));
      expect(component.position.y, closeTo(40, 0.001));
      expect(component.currentScaleX, closeTo(0.6, 0.001));
      expect(component.currentScaleY, closeTo(0.5, 0.001));
      expect(component.currentOpacity, closeTo(0.5, 0.001));
      expect(component.currentRotationRadians, closeTo(1.5708, 0.001));
      expect(component.tintColor, equals(const ui.Color(0xCCB942F4)));
      expect(component.isAnimationComplete, isFalse);
    });

    test('marks itself complete after duration', () async {
      final image = await _fakeImage();
      final component = BattleSdkParticleComponent(
        sprite: Sprite(image),
        startPosition: Vector2.zero(),
        endPosition: Vector2(8, 8),
        startScaleX: 1,
        startScaleY: 1,
        endScaleX: 2,
        endScaleY: 0.5,
        startOpacity: 1,
        endOpacity: 0,
        delaySeconds: 0,
        durationSeconds: 0.20,
      );

      component.update(0.21);

      expect(component.isAnimationComplete, isTrue);
      expect(component.currentOpacity, equals(0));
    });
  });
}
