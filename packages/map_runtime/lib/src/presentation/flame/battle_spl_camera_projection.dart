import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:map_render_3d/battle_projection_contract.dart';

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
typedef BattleSplProjectedPolygon = ({
  List<ui.Offset> positions,
  List<ui.Offset> textureCoordinates,
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
    List<BattleSplWorldTransform>? emitterTransforms,
  }) : bindings = List.unmodifiable(bindings),
       emitterTransforms = emitterTransforms == null
           ? null
           : List.unmodifiable(emitterTransforms) {
    if (bindings.isEmpty || bindings.length > 32) {
      throw const FormatException('Invalid SPL camera bindings');
    }
    if (worldTransform != null && !worldTransform!.isValid) {
      throw const FormatException('Invalid SPL world transform');
    }
    if (emitterTransforms != null &&
        (worldTransform == null ||
            emitterTransforms.length != bindings.length ||
            emitterTransforms.any((transform) => !transform.isValid))) {
      throw const FormatException('Invalid SPL emitter transforms');
    }
  }

  final BattlePerspectiveCamera camera;
  final List<BattleSplCameraBinding> bindings;
  final BattleSplWorldTransform? worldTransform;
  final List<BattleSplWorldTransform>? emitterTransforms;

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
    int emitterIndex = 0,
    BattleSplVector? relativeBasePosition,
  }) {
    if (emitterTransforms != null &&
        (emitterIndex < 0 || emitterIndex >= emitterTransforms!.length)) {
      return null;
    }
    final transform = emitterTransforms?[emitterIndex] ?? worldTransform;
    if (transform == null) return null;
    final world = _particleWorldPosition(
      anchor, particle, transform, relativeBasePosition,
    );
    final forward = (camera.aim - camera.eye).normalized;
    final right = forward.cross(const BattleCameraPoint(0, 1, 0)).normalized;
    final up = right.cross(forward);
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

  bool particleOutsideDepth(
    BattleSplWorldAnchor anchor,
    BattleSplPointParticle particle, {
    int emitterIndex = 0,
    BattleSplVector? relativeBasePosition,
  }) {
    if (emitterTransforms != null &&
        (emitterIndex < 0 || emitterIndex >= emitterTransforms!.length)) {
      return false;
    }
    final transform = emitterTransforms?[emitterIndex] ?? worldTransform;
    if (transform == null || !anchor.unit.isFinite || anchor.unit <= 0) {
      return false;
    }
    final world = _particleWorldPosition(
      anchor, particle, transform, relativeBasePosition,
    );
    if (!world.isFinite) return false;
    final depth = (world - camera.eye).dot((camera.aim - camera.eye).normalized);
    return depth.isFinite && !BattleProjectionContract.containsDepth(depth);
  }

  BattleCameraPoint _particleWorldPosition(
    BattleSplWorldAnchor anchor,
    BattleSplPointParticle particle,
    BattleSplWorldTransform transform,
    BattleSplVector? relativeBasePosition,
  ) {
    final position = particle.motion.position;
    final emitter = particle.emitterPosition;
    final relative = relativeBasePosition ?? (x: 0, y: 0, z: 0);
    final offset = transform.apply((
      x: position.x + emitter.x - relative.x,
      y: position.y + emitter.y - relative.y,
      z: position.z + emitter.z - relative.z,
    ));
    final forward = (camera.aim - camera.eye).normalized;
    final right = forward.cross(const BattleCameraPoint(0, 1, 0)).normalized;
    final up = right.cross(forward);
    final units = transform.worldUnitsPerUnit / 4096;
    return BattleCameraPoint(anchor.x, anchor.y, anchor.z) + offset +
        right * (relative.x * units) + up * (relative.y * units) -
        forward * (relative.z * units);
  }

  List<ui.Offset>? projectDirectionalPolygon(
    BattleSplWorldAnchor anchor,
    BattleSplPointParticle particle, {
    required int aspectRatio4096,
    required String scaleAxis,
    required double pixelsPerUnit,
    int emitterIndex = 0,
  }) {
    final corners = _directionalWorldCorners(anchor, particle,
      aspectRatio4096: aspectRatio4096, scaleAxis: scaleAxis,
      pixelsPerUnit: pixelsPerUnit, emitterIndex: emitterIndex);
    if (corners == null) return null;
    final projected = <ui.Offset>[];
    for (final corner in corners) {
      final value = camera.tryProject(corner);
      if (value == null || !_finite(value.position)) return null;
      projected.add(value.position);
    }
    return projected;
  }

  List<ui.Offset>? projectSourcePolygon(
    BattleSplWorldAnchor anchor,
    BattleSplPointParticle particle, {
    required int aspectRatio4096,
    required String scaleAxis,
    required double pixelsPerUnit,
    String rotationAxis = 'xyz',
    String referencePlane = 'xy',
    int emitterIndex = 0,
  }) {
    final corners = _sourceWorldCorners(
      anchor, particle,
      aspectRatio4096: aspectRatio4096, scaleAxis: scaleAxis,
      pixelsPerUnit: pixelsPerUnit, emitterIndex: emitterIndex,
      rotationAxis: rotationAxis, referencePlane: referencePlane,
    );
    if (corners == null) return null;
    final projected = <ui.Offset>[];
    for (final corner in corners) {
      final value = camera.tryProject(corner);
      if (value == null || !_finite(value.position)) return null;
      projected.add(value.position);
    }
    return projected;
  }

  BattleSplProjectedPolygon? projectClippedSourcePolygon(
    BattleSplWorldAnchor anchor,
    BattleSplPointParticle particle, {
    required int aspectRatio4096,
    required String scaleAxis,
    required double pixelsPerUnit,
    String rotationAxis = 'xyz',
    String referencePlane = 'xy',
    int emitterIndex = 0,
  }) => _projectClippedCorners(_sourceWorldCorners(
    anchor, particle,
    aspectRatio4096: aspectRatio4096, scaleAxis: scaleAxis,
    pixelsPerUnit: pixelsPerUnit, emitterIndex: emitterIndex,
    rotationAxis: rotationAxis, referencePlane: referencePlane,
  ));

  BattleSplProjectedPolygon? projectClippedDirectionalPolygon(
    BattleSplWorldAnchor anchor,
    BattleSplPointParticle particle, {
    required int aspectRatio4096,
    required String scaleAxis,
    required double pixelsPerUnit,
    int emitterIndex = 0,
  }) {
    final corners = _directionalWorldCorners(anchor, particle,
      aspectRatio4096: aspectRatio4096, scaleAxis: scaleAxis,
      pixelsPerUnit: pixelsPerUnit, emitterIndex: emitterIndex);
    return _projectClippedCorners(corners);
  }

  BattleSplProjectedPolygon? _projectClippedCorners(
    List<BattleCameraPoint>? corners,
  ) {
    if (corners == null) return null;
    if (corners.isEmpty) return (positions: [], textureCoordinates: []);
    final direction = (camera.aim - camera.eye).normalized;
    final input = <({BattleCameraPoint point, ui.Offset uv, double depth})>[];
    const uvs = [ui.Offset(0, 0), ui.Offset(1, 0), ui.Offset(1, 1), ui.Offset(0, 1)];
    for (var i = 0; i < corners.length; i++) {
      final depth = (corners[i] - camera.eye).dot(direction);
      if (!depth.isFinite) return null;
      input.add((point: corners[i], uv: uvs[i], depth: depth));
    }
    final output = <({BattleCameraPoint point, ui.Offset uv, double depth})>[];
    const near = BattleProjectionContract.near + .001;
    var previous = input.last;
    for (final current in input) {
      final previousInside = previous.depth >= near;
      final currentInside = current.depth >= near;
      if (previousInside != currentInside) {
        final t = (near - previous.depth) / (current.depth - previous.depth);
        output.add((
          point: previous.point + (current.point - previous.point) * t,
          uv: previous.uv + (current.uv - previous.uv) * t,
          depth: near,
        ));
      }
      if (currentInside) output.add(current);
      previous = current;
    }
    if (output.length < 3) return (positions: [], textureCoordinates: []);
    final positions = <ui.Offset>[];
    final coordinates = <ui.Offset>[];
    for (final vertex in output) {
      final projected = camera.tryProject(vertex.point);
      if (projected == null || !_finite(projected.position)) return null;
      positions.add(projected.position);
      coordinates.add(vertex.uv);
    }
    return (positions: positions, textureCoordinates: coordinates);
  }

  List<BattleCameraPoint>? _sourceWorldCorners(
    BattleSplWorldAnchor anchor,
    BattleSplPointParticle particle, {
    required int aspectRatio4096,
    required String scaleAxis,
    required double pixelsPerUnit,
    required int emitterIndex,
    required String rotationAxis,
    required String referencePlane,
  }) {
    if (emitterTransforms != null &&
        (emitterIndex < 0 || emitterIndex >= emitterTransforms!.length)) {
      return null;
    }
    final transform = emitterTransforms?[emitterIndex] ?? worldTransform;
    if (transform == null || !pixelsPerUnit.isFinite || pixelsPerUnit <= 0 ||
        !{'x', 'y', 'xy'}.contains(scaleAxis) ||
        !{'xyz', 'y'}.contains(rotationAxis) ||
        !{'xy', 'xz'}.contains(referencePlane)) {
      return null;
    }
    if (particle.alpha5 == 0 || particle.scale4096 == 0) return const [];
    final base = particle.baseScale4096 / 4096;
    final animated = particle.scale4096 / 4096;
    final scaleX = base * aspectRatio4096 / 4096 *
        (scaleAxis == 'y' ? 1 : animated);
    final scaleY = base * (scaleAxis == 'x' ? 1 : animated);
    final angle = (particle.motion.rotation & 65535) * 2 * math.pi / 65536;
    final cosine = math.cos(angle);
    final a = (1 - cosine) / 3;
    final b = math.sin(angle) / math.sqrt(3);
    final diagonal = a + cosine;
    final sum = a + b;
    final difference = a - b;
    final yawCosine = math.cos(transform.yawRadians);
    final yawSine = math.sin(transform.yawRadians);
    final center = _particleWorldPosition(anchor, particle, transform, null);
    final units = pixelsPerUnit * anchor.unit;
    final corners = <BattleCameraPoint>[];
    for (final sign in const [(-1, 1), (1, 1), (1, -1), (-1, -1)]) {
      final x = sign.$1 * scaleX;
      final y = referencePlane == 'xy' ? sign.$2 * scaleY : 0.0;
      final z = referencePlane == 'xz' ? sign.$2 * scaleY : 0.0;
      final rotated = rotationAxis == 'y'
          ? BattleCameraPoint(
              x * cosine + z * math.sin(angle),
              y,
              -x * math.sin(angle) + z * cosine,
            )
          : BattleCameraPoint(
              x * diagonal + y * sum + z * difference,
              x * difference + y * diagonal + z * sum,
              x * sum + y * difference + z * diagonal,
            );
      final world = center + BattleCameraPoint(
        (rotated.x * yawCosine - rotated.z * yawSine) * units,
        rotated.y * units,
        (rotated.x * yawSine + rotated.z * yawCosine) * units,
      );
      if (!world.isFinite) return null;
      corners.add(world);
    }
    return corners;
  }

  List<BattleCameraPoint>? _directionalWorldCorners(
    BattleSplWorldAnchor anchor,
    BattleSplPointParticle particle, {
    required int aspectRatio4096,
    required String scaleAxis,
    required double pixelsPerUnit,
    required int emitterIndex,
  }) {
    if (emitterTransforms != null &&
        (emitterIndex < 0 || emitterIndex >= emitterTransforms!.length)) {
      return null;
    }
    final transform = emitterTransforms?[emitterIndex] ?? worldTransform;
    if (transform == null || !pixelsPerUnit.isFinite || pixelsPerUnit <= 0 ||
        !{'x', 'y', 'xy'}.contains(scaleAxis)) {
      return null;
    }
    final position = particle.motion.position;
    final vector = BattleCameraPoint(-position.x.toDouble(),
        -position.y.toDouble(), -position.z.toDouble());
    if (vector.length == 0 || particle.alpha5 == 0 || particle.scale4096 == 0) {
      return const [];
    }
    final direction = vector.normalized;
    final up = direction.y.abs() > .8
        ? const BattleCameraPoint(1, 0, 0)
        : const BattleCameraPoint(0, 1, 0);
    final side = direction.cross(up);
    final base = particle.baseScale4096 / 4096;
    final animated = particle.scale4096 / 4096;
    final scaleX = base * aspectRatio4096 / 4096 *
        (scaleAxis == 'y' ? 1 : animated);
    final scaleY = base * (scaleAxis == 'x' ? 1 : animated);
    final emitter = particle.emitterPosition;
    final center = BattleCameraPoint(anchor.x, anchor.y, anchor.z) +
        transform.apply((x: position.x + emitter.x,
          y: position.y + emitter.y, z: position.z + emitter.z));
    final cosine = math.cos(transform.yawRadians);
    final sine = math.sin(transform.yawRadians);
    final units = pixelsPerUnit * anchor.unit;
    final corners = <BattleCameraPoint>[];
    for (final sign in const [(-1, 1), (1, 1), (1, -1), (-1, -1)]) {
      final local = side * (sign.$1 * scaleX) + direction * (sign.$2 * scaleY);
      final world = center + BattleCameraPoint(
        (local.x * cosine - local.z * sine) * units,
        local.y * units,
        (local.x * sine + local.z * cosine) * units,
      );
      if (!world.isFinite) return null;
      corners.add(world);
    }
    return corners;
  }
}

bool _finite(ui.Offset value) => value.dx.isFinite && value.dy.isFinite;
