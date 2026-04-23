import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_fx_sprite_component.dart';

Future<ui.Image> _fakeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 12, 12),
    ui.Paint()..color = const ui.Color(0xFFCCEEFF),
  );
  return recorder.endRecording().toImage(12, 12);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleFxSpriteComponent', () {
    test('honors startDelaySeconds before beginning the visible animation',
        () async {
      final image = await _fakeImage();
      final component = BattleFxSpriteComponent(
        sprite: Sprite(image),
        startPosition: Vector2(10, 20),
        endPosition: Vector2(110, 20),
        durationSeconds: 0.40,
        startDelaySeconds: 0.20,
        curve: BattleFxMotionCurve.linear,
        afterEffect: BattleFxAfterEffect.none,
        startScale: 1.0,
        endScale: 1.0,
        startOpacity: 1.0,
        endOpacity: 0.0,
      );

      expect(component.currentOpacityMultiplier, equals(0.0));
      expect(component.position.x, closeTo(10, 0.01));

      component.update(0.10);
      expect(component.currentOpacityMultiplier, equals(0.0));
      expect(component.position.x, closeTo(10, 0.01));

      component.update(0.10);
      expect(component.currentOpacityMultiplier, greaterThan(0.0));
      expect(component.position.x, closeTo(10, 0.01));

      component.update(0.40);
      expect(component.isAnimationComplete, isTrue);
    });
  });
}
