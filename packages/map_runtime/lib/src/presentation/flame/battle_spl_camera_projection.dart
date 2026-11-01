import 'dart:ui' as ui;

import 'battle_live_attachment.dart';
import 'battle_perspective_camera.dart';

typedef BattleSplWorldAnchor = ({double x, double y, double z, double unit});
typedef BattleSplProjectedAnchor = ({ui.Offset anchor, double scale});

final class BattleSplCameraBinding {
  const BattleSplCameraBinding({
    required this.resolveAnchor,
    required this.resolveNeutralFoot,
  });

  final BattleLivePointResolver resolveAnchor;
  final ui.Offset? Function() resolveNeutralFoot;
}

final class BattleSplCameraProjection {
  BattleSplCameraProjection({
    required this.camera,
    required List<BattleSplCameraBinding> bindings,
  }) : bindings = List.unmodifiable(bindings) {
    if (bindings.isEmpty || bindings.length > 32) {
      throw const FormatException('Invalid SPL camera bindings');
    }
  }

  final BattlePerspectiveCamera camera;
  final List<BattleSplCameraBinding> bindings;

  List<BattleSplWorldAnchor>? capture() {
    final values = <BattleSplWorldAnchor>[];
    for (final binding in bindings) {
      final foot = binding.resolveNeutralFoot();
      final anchor = binding.resolveAnchor();
      if (foot == null ||
          anchor == null ||
          !_finite(foot) ||
          !anchor.x.isFinite ||
          !anchor.y.isFinite) {
        return null;
      }
      final billboard = camera.tryBillboardAt(foot);
      if (billboard == null ||
          !billboard.scale.isFinite ||
          billboard.scale <= 0) {
        return null;
      }
      final screen = ui.Offset(anchor.x, anchor.y);
      final neutral = foot + (screen - billboard.position) / billboard.scale;
      final geometry = camera.tryBillboardWorldGeometry(
        foot,
        ui.Rect.fromLTWH(neutral.dx - .5, neutral.dy - 1, 1, 1),
      );
      if (!_finite(neutral) ||
          geometry == null ||
          !geometry.width.isFinite ||
          geometry.width <= 0) {
        return null;
      }
      values.add((
        x: geometry.position.x,
        y: geometry.position.y,
        z: geometry.position.z,
        unit: geometry.width,
      ));
    }
    return List.unmodifiable(values);
  }

  BattleSplProjectedAnchor? project(BattleSplWorldAnchor value) {
    final projected = camera.tryProject(
      BattleCameraPoint(value.x, value.y, value.z),
    );
    if (projected == null) return null;
    final scale = camera.focal * value.unit / projected.depth;
    if (!_finite(projected.position) || !scale.isFinite || scale <= 0) {
      return null;
    }
    return (anchor: projected.position, scale: scale);
  }
}

bool _finite(ui.Offset value) => value.dx.isFinite && value.dy.isFinite;
