import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_actor_visual.dart';
import 'spatial_lighting_preview.dart';
import 'spatial_pixel_material.dart';
import 'spatial_point_light.dart';

({double x, double z}) spatialActorContactShadowRadii(double width) {
  if (!width.isFinite || width <= 0) throw ArgumentError.value(width, 'width');
  final x = (width * (.3 / 1.92)).clamp(.12, .4);
  return (x: x, z: x * (2 / 3));
}

({double x, double z}) spatialActorContactShadowOffset(
  ({double x, double y}) anchor, {
  required double width,
  required double height,
  required double pitch,
  required double yaw,
  bool topView = false,
}) {
  if (![
        anchor.x,
        anchor.y,
        width,
        height,
        pitch,
        yaw,
      ].every((v) => v.isFinite) ||
      width <= 0 ||
      height <= 0 ||
      anchor.y < 0 ||
      anchor.y > 1 ||
      anchor.x < -.5 ||
      anchor.x > .5) {
    throw ArgumentError('Invalid actor contact anchor or camera.');
  }
  final horizontal = anchor.x * width;
  if (topView) return (x: horizontal, z: -anchor.y * height);
  final angle = pitch.clamp(.01, math.pi / 2);
  final depth = (anchor.y * height + .008 * math.cos(angle)) / math.sin(angle);
  return (
    x: horizontal * math.cos(yaw) - depth * math.sin(yaw),
    z: -horizontal * math.sin(yaw) - depth * math.cos(yaw),
  );
}

double spatialActorContactShadowOpacity(
  SpatialLightingProfile lighting,
  ({double x, double y, double z}) feet,
) {
  if (![feet.x, feet.y, feet.z].every((value) => value.isFinite)) return 0;
  if (!lighting.enabled) return .18;
  final tint = lighting.sceneTint;
  final ambient = lighting.ambientColor;
  final sunlight = lighting.sunColor;
  final tintLuminance = .2126 * tint.r + .7152 * tint.g + .0722 * tint.b;
  final global =
      tintLuminance *
      (lighting.ambientStrength *
              (.2126 * ambient.r + .7152 * ambient.g + .0722 * ambient.b) +
          lighting.sunStrength *
              lighting.sunDirection.y.clamp(0.0, 1.0) *
              (.2126 * sunlight.r + .7152 * sunlight.g + .0722 * sunlight.b));
  var local = 0.0;
  for (final light in lighting.pointLights) {
    final dx = light.position.x - feet.x;
    final dy = light.position.y - feet.y;
    final dz = light.position.z - feet.z;
    final color = light.color;
    local +=
        spatialPointLightAttenuation(
          dx * dx + dy * dy + dz * dz,
          light.radius,
        ) *
        light.intensity *
        (.2126 * color.r + .7152 * color.g + .0722 * color.b);
  }
  final opacity = .22 * global * global + .065 * local.clamp(0.0, 1.0);
  return opacity.isFinite ? opacity.clamp(0.0, .22) : 0;
}

final class SpatialActorContactShadow extends MeshComponent {
  factory SpatialActorContactShadow() {
    final material = SpatialPixelMaterial(
      Texture.standard,
      alphaMode: Model3dAlphaMode.blend,
      lightingRole: SpatialPixelLightingRole.actor,
    );
    final vertices = <Vertex>[
      Vertex(position: Vector3.zero(), texCoord: Vector2.zero()),
    ];
    final indices = <int>[];
    const segments = 32;
    const rings = [
      (radius: .4, alpha: .8),
      (radius: .7, alpha: .3),
      (radius: 1.0, alpha: 0.0),
    ];
    for (var ring = 0; ring < rings.length; ring++) {
      final radius = rings[ring].radius;
      final alpha = rings[ring].alpha;
      for (var segment = 0; segment < segments; segment++) {
        final angle = segment * math.pi * 2 / segments;
        vertices.add(
          Vertex(
            position: Vector3(
              math.cos(angle) * radius,
              0,
              math.sin(angle) * radius,
            ),
            texCoord: Vector2.zero(),
            color: Color.fromRGBO(255, 255, 255, alpha),
          ),
        );
        final current = 1 + ring * segments + segment;
        final next = 1 + ring * segments + (segment + 1) % segments;
        if (ring == 0) {
          indices.addAll([0, next, current]);
        } else {
          final inner = current - segments;
          final innerNext = next - segments;
          indices.addAll([inner, next, current, inner, innerNext, next]);
        }
      }
    }
    final mesh = Mesh()
      ..addSurface(
        Surface(vertices: vertices, indices: indices, material: material),
      );
    return SpatialActorContactShadow._(mesh, material);
  }

  SpatialActorContactShadow._(Mesh mesh, this.material) : super(mesh: mesh);

  final SpatialPixelMaterial material;
  static final _colors = List<Color>.generate(
    257,
    (index) => Color.fromRGBO(0, 0, 0, index / 256),
    growable: false,
  );

  void sync({
    required double x,
    required double groundY,
    required double z,
    required double width,
    required SpatialLightingProfile lighting,
  }) {
    final radii = spatialActorContactShadowRadii(width);
    position.setValues(x, groundY + .012, z);
    scale.setValues(radii.x, 1, radii.z);
    material.albedoColor =
        _colors[(spatialActorContactShadowOpacity(lighting, (
                  x: x,
                  y: groundY,
                  z: z,
                )) *
                256)
            .round()];
  }
}

final class SpatialActorContactShadows {
  SpatialActorContactShadows(this.world);

  final World3D world;
  final components = <String, SpatialActorContactShadow>{};

  void sync(
    Map<String, SpatialActorVisual> frames, {
    required Offset sceneOffset,
    required SpatialLightingProfile lighting,
    String? previewActorId,
    Model3dVector3? previewPosition,
    double cameraPitch = math.pi / 4,
    double cameraYaw = 0,
    bool topView = false,
  }) {
    for (final id in components.keys.toList()) {
      final frame = frames[id];
      if (frame?.contactShadow != true ||
          frame!.contactShadowFootAnchor == null) {
        components.remove(id)!.removeFromParent();
      }
    }
    for (final entry in frames.entries) {
      final frame = entry.value;
      if (!frame.contactShadow) continue;
      final anchor = frame.contactShadowFootAnchor;
      if (anchor == null) continue;
      final offset = spatialActorContactShadowOffset(
        anchor,
        width: frame.resolvedWidth,
        height: frame.height,
        pitch: cameraPitch,
        yaw: cameraYaw,
        topView: topView,
      );
      var shadow = components[entry.key];
      if (shadow == null) {
        shadow = SpatialActorContactShadow();
        components[entry.key] = shadow;
        world.add(shadow);
      }
      final position = previewActorId == entry.key ? previewPosition : null;
      shadow.sync(
        x: (position?.x ?? frame.x) + sceneOffset.dx + offset.x,
        groundY: position?.y ?? frame.groundY ?? frame.y,
        z: (position?.z ?? frame.z) + sceneOffset.dy + offset.z,
        width: frame.resolvedWidth,
        lighting: lighting,
      );
    }
  }

  void clear() {
    for (final component in components.values) {
      component.removeFromParent();
    }
    components.clear();
  }
}
