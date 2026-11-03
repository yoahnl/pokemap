import 'dart:ui';

import 'package:flame/components.dart';

import 'battle_perspective_camera.dart';

final class BattlePerspectiveGroundComponent extends Component {
  BattlePerspectiveGroundComponent({
    required this.camera,
    required this.groundRects,
    this.paintFloor = true,
    this.clipRect,
    this.isVisible,
    this.isFloorVisible,
    this.arePlatformsVisible,
  }) : super(priority: 7);

  final BattlePerspectiveCamera camera;
  final Iterable<Rect> Function() groundRects;
  final bool paintFloor;
  final Rect Function()? clipRect;
  final bool Function()? isVisible;
  final bool Function()? isFloorVisible;
  final bool Function()? arePlatformsVisible;
  final Paint _rim = Paint()..color = const Color(0x70544232);
  final Paint _ground = Paint()..color = const Color(0x905F7950);

  @override
  void render(Canvas canvas) {
    if (!(isVisible?.call() ?? true)) return;
    canvas.save();
    canvas.clipRect(clipRect?.call() ?? camera.viewport);
    if (paintFloor && (isFloorVisible?.call() ?? true)) _paintFloor(canvas);
    for (final rect in (arePlatformsVisible?.call() ?? true)
        ? groundRects() : <Rect>[]) {
      canvas.drawPath(camera.groundEllipse(rect.center, rect.size), _rim);
      canvas.drawPath(
        camera.groundEllipse(
          rect.center - const Offset(0, 3),
          Size(rect.width * .96, rect.height * .82),
        ),
        _ground,
      );
    }
    canvas.restore();
  }

  void _paintFloor(Canvas canvas) {
    final viewport = camera.viewport;
    final ground = camera.tryGroundAt(
      Offset(viewport.center.dx, viewport.bottom),
    );
    if (ground == null) return;
    final near = camera.tryProject(ground)?.position;
    if (near == null) return;
    canvas.drawRect(
      clipRect?.call() ?? viewport,
      Paint()
        ..shader = Gradient.linear(
          Offset(viewport.center.dx, camera.groundHorizonY),
          near,
          const [Color(0x007C9B71), Color(0xAA749668), Color(0xFF5C8055)],
          const [0, .45, 1],
        ),
    );
  }
}
