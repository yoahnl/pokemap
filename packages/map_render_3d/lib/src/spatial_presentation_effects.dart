import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';

final class SpatialHaloSource {
  SpatialHaloSource({
    this.instanceId,
    required this.position,
    this.radiusX = .55,
    this.radiusY = .55,
    this.opacity = .22,
    this.color = const Color(0xffffcf83),
    this.window = false,
  }) {
    if (![
          position.x,
          position.y,
          position.z,
          radiusX,
          radiusY,
          opacity,
        ].every((v) => v.isFinite) ||
        radiusX <= 0 ||
        radiusX > 3 ||
        radiusY <= 0 ||
        radiusY > 3 ||
        opacity < 0 ||
        opacity > .5) {
      throw ArgumentError('Invalid local halo source.');
    }
  }

  final Model3dVector3 position;
  final String? instanceId;
  final double radiusX, radiusY, opacity;
  final Color color;
  final bool window;
}

final class SpatialPresentationProfile {
  SpatialPresentationProfile({
    this.haloStrength = 1,
    this.haloSpread = 1,
    this.fogStart = 14,
    this.fogEnd = 35,
    this.fogOpacity = .2,
    List<SpatialHaloSource> halos = const [],
  }) : halos = List.unmodifiable(halos) {
    if (![
          fogStart,
          fogEnd,
          fogOpacity,
          haloStrength,
          haloSpread,
        ].every((v) => v.isFinite) ||
        haloStrength < 0 ||
        haloStrength > 2 ||
        haloSpread < .1 ||
        haloSpread > 3 ||
        fogStart < 0 ||
        fogEnd <= fogStart ||
        fogOpacity < 0 ||
        fogOpacity > .5 ||
        halos.length > 32) {
      throw ArgumentError('Invalid presentation preview profile.');
    }
  }

  static final disabled = SpatialPresentationProfile(fogOpacity: 0);
  factory SpatialPresentationProfile.fromSettings(
    SpatialAtmosphereSettings settings,
  ) => SpatialPresentationProfile(
    haloStrength: settings.haloStrength,
    haloSpread: settings.haloSpread,
    fogStart: settings.fogStart,
    fogEnd: settings.fogEnd,
    fogOpacity: settings.fogOpacity,
    halos: [
      for (final halo in settings.halos)
        SpatialHaloSource(
          instanceId: halo.instanceId,
          position: halo.localPosition,
          radiusX: halo.radiusX,
          radiusY: halo.radiusY,
          opacity: halo.opacity,
          color: Color(0xff000000 | halo.colorRgb),
          window: halo.window,
        ),
    ],
  );
  double fogStart, fogEnd, fogOpacity, haloStrength, haloSpread;
  final List<SpatialHaloSource> halos;

  double fogAtDepth(double depth) {
    final t = ((depth - fogStart) / (fogEnd - fogStart)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t) * fogOpacity;
  }
}

abstract interface class SpatialPresentationContext {
  SpatialPresentationProfile get presentationProfile;
  bool get depthFogEnabled;
  Color get depthFogColor;
}

Color spatialDepthFogColor(double night) => Color.lerp(
  const Color(0xffc5d8dc),
  const Color(0xff6b7da1),
  night.clamp(0.0, 1.0),
)!;

final class SpatialPresentationEffects {
  SpatialPresentationEffects(this.world);
  final World3D world;
  SpatialPresentationProfile? _profile;
  final _halos = <_Halo>[];
  int allocations = 0;
  int get visibleCount => _halos.where((halo) => halo.visible).length;
  Iterable<MeshComponent> get components => _halos;

  void sync({
    required SpatialPresentationProfile profile,
    required bool enabled,
    required bool windowsLit,
    required double night,
    required double cameraPitch,
    required double cameraYaw,
    double windowStrength = 1,
    Model3dVector3? Function(SpatialHaloSource source)? locate,
    Color? Function(String instanceId)? colorForInstance,
    double Function(String instanceId)? strengthForInstance,
  }) {
    if (!identical(_profile, profile)) {
      clear();
      _profile = profile;
      for (final source in profile.halos) {
        final halo = _Halo(source);
        _halos.add(halo);
        world.add(halo);
        allocations++;
      }
    }
    for (final halo in _halos) {
      final id = halo.source.instanceId;
      final strength = id == null ? 1.0 : strengthForInstance?.call(id) ?? 1;
      final position = halo.source.instanceId == null
          ? halo.source.position
          : locate?.call(halo.source);
      halo.visible =
          enabled &&
          strength > .001 &&
          position != null &&
          night > .001 &&
          (!halo.source.window || windowsLit);
      if (!halo.visible) continue;
      halo.position.setValues(position!.x, position.y, position.z);
      halo.scale.setValues(
        profile.haloSpread,
        profile.haloSpread,
        profile.haloSpread,
      );
      halo.rotation.setEuler(cameraYaw, -cameraPitch, 0);
      halo.material.albedoColor =
          (id == null
                  ? halo.source.color
                  : colorForInstance?.call(id) ?? halo.source.color)
              .withValues(
                alpha:
                    (strength *
                            halo.source.opacity *
                            profile.haloStrength *
                            (halo.source.window ? windowStrength : 1) *
                            night.clamp(0.0, 1.0))
                        .clamp(0.0, 1.0),
              );
    }
  }

  void clear() {
    for (final halo in _halos) {
      halo.removeFromParent();
    }
    _halos.clear();
    _profile = null;
  }
}

final class _Halo extends MeshComponent {
  factory _Halo(SpatialHaloSource source) {
    final material = SpatialPixelMaterial(
      Texture.standard,
      alphaMode: Model3dAlphaMode.blend,
      emissive: true,
    )..cullMode = CullMode.none;
    final vertices = [
      Vertex(position: Vector3.zero(), texCoord: Vector2.zero()),
    ];
    final indices = <int>[];
    const segments = 32, rings = 8;
    for (var ring = 1; ring <= rings; ring++) {
      final radius = ring / rings;
      final opacity = math.pow(1 - radius * radius, 3).toDouble();
      for (var i = 0; i < segments; i++) {
        final angle = i * math.pi * 2 / segments;
        vertices.add(
          Vertex(
            position: Vector3(
              math.cos(angle) * radius * source.radiusX,
              math.sin(angle) * radius * source.radiusY,
              0,
            ),
            texCoord: Vector2.zero(),
            color: Color.fromRGBO(255, 255, 255, opacity),
          ),
        );
        final current = 1 + (ring - 1) * segments + i;
        final next = 1 + (ring - 1) * segments + (i + 1) % segments;
        if (ring == 1) {
          indices.addAll([0, current, next]);
        } else {
          indices.addAll([
            current - segments,
            current,
            next,
            current - segments,
            next,
            next - segments,
          ]);
        }
      }
    }
    final mesh = Mesh()
      ..addSurface(
        Surface(vertices: vertices, indices: indices, material: material),
      );
    return _Halo._(source, mesh, material);
  }

  _Halo._(this.source, Mesh mesh, this.material) : super(mesh: mesh) {
    position.setValues(source.position.x, source.position.y, source.position.z);
  }
  final SpatialHaloSource source;
  final SpatialPixelMaterial material;
  bool visible = false;
  @override
  void draw(RenderContext3D context) {
    if (visible) super.draw(context);
  }
}
