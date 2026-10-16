import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/post_process.dart';

final class FlameDarknessPostProcess extends PostProcess {
  FlameDarknessPostProcess({required this.readOpacity});
  final double Function() readOpacity;
  final _paint = Paint();

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    renderSubtree(canvas);
    final opacity = readOpacity();
    if (!opacity.isFinite || opacity <= 0) return;
    _paint.color = Color.fromARGB(
      (opacity.clamp(0, .95) * 255).round(),
      0,
      0,
      0,
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
  }
}
