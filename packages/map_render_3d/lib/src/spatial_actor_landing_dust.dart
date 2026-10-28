import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_actor_visual.dart';
import 'spatial_actor_contact_shadow.dart';
import 'spatial_pixel_material.dart';

final class SpatialActorLandingDust {
  SpatialActorLandingDust(this.world);

  final World3D world;
  final components = <String, SpatialLandingDustComponent>{};
  final _airborne = <String, bool>{};
  String? _mapId;

  void sync(
    Map<String, SpatialActorVisual> frames, {
    required String mapId,
    required double dt,
    bool paused = false,
    Offset sceneOffset = Offset.zero,
    double cameraPitch = math.pi / 4,
    double cameraYaw = 0,
    bool topView = false,
  }) {
    if (_mapId != mapId) {
      clear();
      _mapId = mapId;
    }
    bool eligible(String id) {
      final frame = frames[id];
      return frame != null &&
          frame.landingDust &&
          frame.contactShadowFootAnchor != null &&
          [
            frame.x,
            frame.y,
            frame.z,
            frame.groundY ?? frame.y,
          ].every((v) => v.isFinite);
    }

    for (final id in components.keys.where((id) => !eligible(id)).toList()) {
      components.remove(id)!.removeFromParent();
    }
    _airborne.removeWhere((id, _) => !eligible(id));
    if (paused || !dt.isFinite || dt < 0) return;
    final elapsed = dt.clamp(0.0, .05);
    for (final id in components.keys.toList()) {
      final component = components[id]!;
      component.elapsed += elapsed;
      if (component.elapsed >= SpatialLandingDustComponent.duration - 1e-9) {
        components.remove(id)!.removeFromParent();
      }
    }
    for (final entry in frames.entries) {
      if (!eligible(entry.key)) continue;
      final frame = entry.value;
      final groundY = frame.groundY ?? frame.y;
      if (_airborne[entry.key] == true &&
          !frame.airborne &&
          (frame.y - groundY).abs() <= 1e-6) {
        components.remove(entry.key)?.removeFromParent();
        final contact = spatialActorContactShadowOffset(
          frame.contactShadowFootAnchor!,
          width: frame.resolvedWidth,
          height: frame.height,
          pitch: cameraPitch,
          yaw: cameraYaw,
          topView: topView,
        );
        final component = SpatialLandingDustComponent(
          frame.x + contact.x,
          groundY,
          frame.z + contact.z,
        );
        components[entry.key] = component;
        world.add(component);
      }
      _airborne[entry.key] = frame.airborne;
    }
    for (final component in components.values) {
      component.sync(
        sceneOffset: sceneOffset,
        cameraPitch: cameraPitch,
        cameraYaw: cameraYaw,
        topView: topView,
      );
    }
  }

  void clear() {
    for (final component in components.values) {
      component.removeFromParent();
    }
    components.clear();
    _airborne.clear();
    _mapId = null;
  }
}

final class SpatialLandingDustComponent extends MeshComponent {
  factory SpatialLandingDustComponent(double x, double y, double z) {
    final material = SpatialPixelMaterial(
      Texture.standard,
      alphaMode: Model3dAlphaMode.blend,
      lightingRole: SpatialPixelLightingRole.actor,
    );
    final vertices = <Vertex>[];
    final indices = <int>[];
    const lobes = [
      (x: -.34, y: .06, radius: .12),
      (x: -.18, y: .11, radius: .14),
      (x: 0.0, y: .08, radius: .15),
      (x: .18, y: .11, radius: .14),
      (x: .34, y: .06, radius: .12),
    ];
    const segments = 12;
    for (final lobe in lobes) {
      final center = vertices.length;
      vertices.add(
        Vertex(position: Vector3(lobe.x, lobe.y, 0), texCoord: Vector2.zero()),
      );
      for (var i = 0; i < segments; i++) {
        final angle = i * math.pi * 2 / segments;
        vertices.add(
          Vertex(
            position: Vector3(
              lobe.x + math.cos(angle) * lobe.radius,
              lobe.y + math.sin(angle) * lobe.radius,
              0,
            ),
            texCoord: Vector2.zero(),
            color: const Color(0x00ffffff),
          ),
        );
        indices.addAll([
          center,
          center + 1 + i,
          center + 1 + (i + 1) % segments,
        ]);
      }
    }
    final mesh = Mesh()
      ..addSurface(
        Surface(vertices: vertices, indices: indices, material: material),
      );
    return SpatialLandingDustComponent._(mesh, material, x, y, z);
  }

  SpatialLandingDustComponent._(
    Mesh mesh,
    this.material,
    this.x,
    this.y,
    this.z,
  ) : super(mesh: mesh);

  static const duration = .25;
  final SpatialPixelMaterial material;
  final double x, y, z;
  double elapsed = 0;

  void sync({
    required Offset sceneOffset,
    required double cameraPitch,
    required double cameraYaw,
    required bool topView,
  }) {
    final progress = (elapsed / duration).clamp(0.0, 1.0);
    final growth = .9 + .55 * progress;
    final transform = spatialActorTransform(
      SpatialCameraProfile(
        pitchDegrees: cameraPitch * 180 / math.pi,
        yawDegrees: cameraYaw * 180 / math.pi,
      ),
    );
    rotation.setFrom(
      topView
          ? Quaternion.axisAngle(Vector3(1, 0, 0), -math.pi / 2)
          : transform.rotation,
    );
    scale.setValues(
      growth,
      topView ? growth : growth * transform.scale.y,
      growth,
    );
    position.setValues(
      x + sceneOffset.dx,
      y + .025 + .08 * progress,
      z + sceneOffset.dy,
    );
    material.albedoColor = Color.fromRGBO(224, 217, 199, .8 * (1 - progress));
  }
}
