import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../application/warp_presentation_controller.dart';
import 'warp_presentation_renderer.dart';
import 'warp_transition_overlay_component.dart';

final class WarpPresentationOverlayComponent
    extends WarpTransitionOverlayComponent {
  WarpPresentationOverlayComponent({
    required Vector2 viewportSize,
    required this.controller,
    required this.renderer,
  }) : super(viewportSize: viewportSize) {
    if (renderer.presentation != controller.presentation ||
        !viewportSize.x.isFinite ||
        !viewportSize.y.isFinite ||
        viewportSize.x <= 0 ||
        viewportSize.y <= 0) {
      throw ArgumentError(
        'Warp presentation renderer and controller must share one valid viewport and contract.',
      );
    }
  }
  final RuntimeWarpPresentationController controller;
  final RuntimeWarpPresentationRenderer renderer;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(controller.start());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!dt.isFinite || dt < 0) throw ArgumentError.value(dt, 'dt');
    controller.advance(
      Duration(microseconds: (dt * Duration.microsecondsPerSecond).round()),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    renderer.render(canvas, Size(size.x, size.y), controller.frame);
  }

  @override
  void close() {
    controller.cancel();
    super.close();
  }

  @override
  void onRemove() {
    controller.cancel();
    super.onRemove();
  }
}
