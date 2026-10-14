import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/post_process.dart';

import '../../application/scene_runtime/scene_world_tone_controller.dart';

final class FlameWorldTonePostProcess extends PostProcess {
  FlameWorldTonePostProcess({required this.controller});

  final SceneWorldToneController controller;
  final _paint = Paint();
  SceneWorldToneValue? _filteredTone;

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    final tone = controller.value;
    if (tone == SceneWorldToneValue.neutral) {
      renderSubtree(canvas);
      return;
    }
    if (_filteredTone != tone) {
      final gray = tone.gray / 255;
      final source = 1 - gray;
      final redLuma = gray * .299;
      final greenLuma = gray * .587;
      final blueLuma = gray * .114;
      _paint.colorFilter = ColorFilter.matrix([
        source + redLuma,
        greenLuma,
        blueLuma,
        0,
        tone.red,
        redLuma,
        source + greenLuma,
        blueLuma,
        0,
        tone.green,
        redLuma,
        greenLuma,
        source + blueLuma,
        0,
        tone.blue,
        0,
        0,
        0,
        1,
        0,
      ]);
      _filteredTone = tone;
    }
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
    try {
      renderSubtree(canvas);
    } finally {
      canvas.restore();
    }
  }
}
