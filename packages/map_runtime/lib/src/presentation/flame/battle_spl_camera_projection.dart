import 'dart:math' as math;
import 'dart:ui' as ui;

import 'battle_live_attachment.dart';
import 'battle_perspective_camera.dart';
import 'battle_spl_particle_motion.dart';
import 'battle_spl_point_emitter_playback.dart';

typedef BattleSplWorldAnchor = ({double x, double y, double z, double unit});
typedef BattleSplProjectedAnchor = ({ui.Offset anchor, double scale});
typedef BattleSplProjectedParticle = ({
  ui.Offset position,
  double scale,
  ui.Offset direction,
});

final class BattleSplWorldTransform {
  const BattleSplWorldTransform({
    required this.worldUnitsPerUnit,
    required this.yawRadians,
  });

  final double worldUnitsPerUnit;
  final double yawRadians;

  bool get isValid =>
      worldUnitsPerUnit.isFinite &&
      worldUnitsPerUnit > 0 &&
      worldUnitsPerUnit <= 4096 &&
      yawRadians.isFinite;

  BattleCameraPoint apply(BattleSplVector value) {
    final cosine = math.cos(yawRadians);
    final sine = math.sin(yawRadians);
    final scale = worldUnitsPerUnit / 4096;
    return BattleCameraPoint(
      (value.x * cosine - value.z * sine) * scale,
      value.y * scale,
      (value.x * sine + value.z * cosine) * scale,
    );
  }
}

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
    this.worldTransform,
  }) : bindings = List.unmodifiable(bindings) {
    if (bindings.isEmpty || bindings.length > 32) {
      throw const FormatException('Invalid SPL camera bindings');
    }
    if (worldTransform != null && !worldTransform!.isValid) {
      throw const FormatException('Invalid SPL world transform');
    }
  }

  final BattlePerspectiveCamera camera;
  final List<BattleSplCameraBinding> bindings;
  final BattleSplWorldTransform? worldTransform;

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

  BattleSplProjectedParticle? projectParticle(
    BattleSplWorldAnchor anchor,
    BattleSplPointParticle particle, {
    bool includeDirection = true,
  }) {
    final transform = worldTransform;
    if (transform == null) return null;
    final position = particle.motion.position;
    final emitter = particle.emitterPosition;
    final offset = transform.apply((
      x: position.x + emitter.x,
      y: position.y + emitter.y,
      z: position.z + emitter.z,
    ));
    final world = BattleCameraPoint(anchor.x, anchor.y, anchor.z) + offset;
    final projected = camera.tryProject(world);
    if (projected == null) return null;
    final scale = camera.focal * anchor.unit / projected.depth;
    if (!scale.isFinite || scale <= 0) return null;
    if (!includeDirection) {
      return (
        position: projected.position,
        scale: scale,
        direction: ui.Offset.zero,
      );
    }

    final forward = (camera.aim - camera.eye).normalized;
    final right = forward.cross(const BattleCameraPoint(0, 1, 0)).normalized;
    final up = right.cross(forward);
    final delta = world - camera.eye;
    final velocity = transform.apply(particle.motion.velocity);
    final depthVelocity = velocity.dot(forward);
    final direction = ui.Offset(
      velocity.dot(right) * projected.depth - delta.dot(right) * depthVelocity,
      -velocity.dot(up) * projected.depth + delta.dot(up) * depthVelocity,
    );
    if (!_finite(direction)) return null;
    return (position: projected.position, scale: scale, direction: direction);
  }
}

bool _finite(ui.Offset value) => value.dx.isFinite && value.dy.isFinite;
