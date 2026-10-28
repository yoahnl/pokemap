import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/camera.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';
import 'spatial_point_light.dart';
import 'spatial_firefly_lighting.dart';

final class SpatialAtmosphereTarget {
  const SpatialAtmosphereTarget({
    required this.instanceId,
    required this.materialName,
  });
  const SpatialAtmosphereTarget.groundTileset(String tilesetId)
    : instanceId = null,
      materialName = 'ground:$tilesetId';
  final String? instanceId;
  final String materialName;
  bool matches(String? instance, String? material) =>
      instanceId == instance && materialName == material;
  String get key => '${instanceId ?? ''}\u0000$materialName';
}

final class SpatialWindowGlow {
  SpatialWindowGlow({
    required this.target,
    required List<Rect> uvRects,
    this.color = const Color(0xffffcf73),
    this.strength = .8,
  }) : uvRects = List.unmodifiable(uvRects) {
    if (uvRects.isEmpty ||
        uvRects.length > 8 ||
        uvRects.any(
          (r) =>
              ![r.left, r.top, r.right, r.bottom].every((v) => v.isFinite) ||
              r.left < 0 ||
              r.top < 0 ||
              r.right > 1 ||
              r.bottom > 1 ||
              r.isEmpty,
        ) ||
        !strength.isFinite ||
        strength < 0 ||
        strength > 2) {
      throw ArgumentError('Invalid window glow mask or strength.');
    }
  }
  final SpatialAtmosphereTarget target;
  final List<Rect> uvRects;
  final Color color;
  final double strength;
}

final class SpatialFireflyZone {
  SpatialFireflyZone({required this.bounds, this.count = 12, this.seed = 1}) {
    final min = bounds.min, max = bounds.max;
    if (count < 1 ||
        count > 64 ||
        ![min.x, min.y, min.z, max.x, max.y, max.z].every((v) => v.isFinite) ||
        max.x <= min.x ||
        max.y <= min.y ||
        max.z <= min.z) {
      throw ArgumentError('Invalid firefly zone.');
    }
  }
  final Model3dBounds bounds;
  final int count;
  final int seed;
}

final class SpatialAtmosphereProfile {
  SpatialAtmosphereProfile({
    this.waterStrength = 1,
    this.waterSpeed = 1,
    this.windowStrength = 1,
    this.fireflyDensity = 1,
    this.fireflyCapacityScale = 1,
    this.fireflyLighting = false,
    this.fireflyYellowAmount = 1,
    this.fireflyGreenAmount = 0,
    this.fireflyBlueAmount = 0,
    this.fireflyPinkAmount = 0,
    this.fireflyLightStrength = 0.18,
    this.fireflyLightRadius = 1.2,

    List<SpatialAtmosphereTarget> waterTargets = const [],
    List<SpatialWindowGlow> windows = const [],
    List<SpatialFireflyZone> fireflyZones = const [],
  }) : waterTargets = List.unmodifiable(waterTargets),
       windows = List.unmodifiable(windows),
       fireflyZones = List.unmodifiable(fireflyZones),
       _water = _waterIndex(waterTargets),
       _windows = _windowIndex(windows) {
    if (fireflyCapacityScale < 1 ||
        fireflyCapacityScale > 2 ||
        fireflyZones.fold<int>(0, (sum, zone) => sum + zone.count) *
                fireflyCapacityScale >
            128 ||
        ![
          waterStrength,
          waterSpeed,
          windowStrength,
          fireflyDensity,
        ].every((v) => v.isFinite) ||
        waterStrength < 0 ||
        waterStrength > 2 ||
        waterSpeed < 0 ||
        waterSpeed > 3 ||
        windowStrength < 0 ||
        windowStrength > 2 ||
        fireflyDensity < 0 ||
        fireflyDensity > 2) {
      throw ArgumentError('Invalid atmosphere presentation limits.');
    }
  }
  factory SpatialAtmosphereProfile.fromSettings(
    SpatialAtmosphereSettings settings,
  ) => SpatialAtmosphereProfile(
    waterStrength: settings.waterStrength,
    waterSpeed: settings.waterSpeed,
    windowStrength: settings.windowStrength,
    fireflyDensity: settings.fireflyDensity,
    fireflyLighting: settings.fireflyLighting,
    fireflyYellowAmount: settings.fireflyYellowAmount,
    fireflyGreenAmount: settings.fireflyGreenAmount,
    fireflyBlueAmount: settings.fireflyBlueAmount,
    fireflyPinkAmount: settings.fireflyPinkAmount,
    fireflyLightStrength: settings.fireflyLightStrength,
    fireflyLightRadius: settings.fireflyLightRadius,

    fireflyCapacityScale: 2,
    waterTargets: [
      for (final t in settings.waterTargets)
        SpatialAtmosphereTarget(
          instanceId: t.instanceId,
          materialName: t.materialName,
        ),
    ],
    windows: [
      for (final w in settings.windows)
        SpatialWindowGlow(
          target: SpatialAtmosphereTarget(
            instanceId: w.target.instanceId,
            materialName: w.target.materialName,
          ),
          uvRects: [
            for (final r in w.uvRects)
              Rect.fromLTRB(r.left, r.top, r.right, r.bottom),
          ],
          color: Color(0xff000000 | w.colorRgb),
          strength: w.strength,
        ),
    ],
    fireflyZones: [
      for (final z in settings.fireflyZones)
        SpatialFireflyZone(bounds: z.bounds, count: z.count, seed: z.seed),
    ],
  );
  static final disabled = SpatialAtmosphereProfile();
  double waterStrength, waterSpeed, windowStrength, fireflyDensity;
  bool fireflyLighting;
  double fireflyYellowAmount,
      fireflyGreenAmount,
      fireflyBlueAmount,
      fireflyPinkAmount,
      fireflyLightStrength,
      fireflyLightRadius;
  final int fireflyCapacityScale;
  final List<SpatialAtmosphereTarget> waterTargets;
  final List<SpatialWindowGlow> windows;
  final List<SpatialFireflyZone> fireflyZones;
  final Map<String, Set<String>> _water;
  final Map<String, Map<String, SpatialWindowGlow>> _windows;
  bool isWater(String? instance, String? material) =>
      _water[instance ?? '']?.contains(material ?? '') ?? false;
  SpatialWindowGlow? window(String? instance, String? material) =>
      _windows[instance ?? '']?[material ?? ''];

  late final Set<String> _targetedMaterials = {
    for (final target in waterTargets) target.materialName,
    for (final window in windows) window.target.materialName,
  };

  bool targetsMaterial(String? material) =>
      _targetedMaterials.contains(material ?? '');

  static Map<String, Set<String>> _waterIndex(
    List<SpatialAtmosphereTarget> targets,
  ) {
    final index = <String, Set<String>>{};
    for (final target in targets) {
      (index[target.instanceId ?? ''] ??= {}).add(target.materialName);
    }
    return index;
  }

  static Map<String, Map<String, SpatialWindowGlow>> _windowIndex(
    List<SpatialWindowGlow> windows,
  ) {
    final index = <String, Map<String, SpatialWindowGlow>>{};
    for (final window in windows) {
      (index[window.target.instanceId ?? ''] ??=
              {})[window.target.materialName] =
          window;
    }
    return index;
  }
}

abstract interface class SpatialAtmosphereContext {
  SpatialAtmosphereProfile get atmosphereProfile;
  bool get waterAnimated;
  bool get windowsLit;
  double get atmosphereElapsedSeconds;
  double get atmosphereNight;
  String? get sourceInstanceId;
}

({Model3dVector3 position, double opacity}) spatialFireflySample(
  SpatialFireflyZone zone,
  int index, {
  required double elapsedSeconds,
  required double night,
}) {
  final seed = zone.seed * .61803398875 + index * 2.3999632297;
  double fraction(double value) => value - value.floorToDouble();
  final t = elapsedSeconds.isFinite ? elapsedSeconds : 0.0;
  final min = zone.bounds.min, max = zone.bounds.max;
  final x =
      .14 +
      .72 * fraction(math.sin(seed * 12.9898) * 43758.5453) +
      .09 * math.sin(t * .47 + seed);
  final y =
      .2 +
      .6 * fraction(math.sin(seed * 7.233) * 17931.423) +
      .14 * math.sin(t * .71 + seed * 2);
  final z =
      .14 +
      .72 * fraction(math.sin(seed * 3.734) * 29132.731) +
      .09 * math.cos(t * .39 + seed);
  return (
    position: Model3dVector3(
      x: min.x + x * (max.x - min.x),
      y: min.y + y * (max.y - min.y),
      z: min.z + z * (max.z - min.z),
    ),
    opacity:
        night.clamp(0.0, 1.0) *
        (.4 + .6 * math.pow(.5 + .5 * math.sin(t * 1.8 + seed * 3), 2)),
  );
}

final class SpatialAtmosphereEffects {
  SpatialAtmosphereEffects(this.world);
  final World3D world;
  SpatialAtmosphereProfile? _profile;
  final List<_Firefly> _components = [];
  final _lightBudget = SpatialFireflyLightBudget();
  double _elapsed = 0;
  (double, double, double, double)? _paletteKey;
  List<SpatialPointLight> lights(Vector3 anchor) {
    final profile = _profile;
    return _lightBudget.sample(
      profile?.fireflyLighting != true
          ? []
          : [
              for (final (i, particle) in _components.indexed)
                if (particle.visible)
                  (
                    i,
                    SpatialPointLight(
                      position: (
                        x: particle.position.x,
                        y: particle.position.y,
                        z: particle.position.z,
                      ),
                      radius: profile!.fireflyLightRadius,
                      color: particle.lightColor,
                      intensity:
                          particle.lightStrength * profile.fireflyLightStrength,
                    ),
                  ),
            ],
      anchor,
      _elapsed,
    );
  }

  Iterable<MeshComponent> get components => _components;
  int get visibleCount =>
      _components.where((particle) => particle.visible).length;
  void sync({
    required SpatialAtmosphereProfile profile,
    required bool enabled,
    required double elapsedSeconds,
    required double night,
    required double cameraPitch,
    required double cameraYaw,
  }) {
    _elapsed = elapsedSeconds;
    if (!identical(_profile, profile)) {
      clear();
      _profile = profile;
      for (final zone in profile.fireflyZones) {
        for (
          var index = 0;
          index < zone.count * profile.fireflyCapacityScale;
          index++
        ) {
          final particle = _Firefly(zone, index);
          _components.add(particle);
          world.add(particle);
        }
      }
    }
    final key = (
      profile.fireflyYellowAmount,
      profile.fireflyGreenAmount,
      profile.fireflyBlueAmount,
      profile.fireflyPinkAmount,
    );
    final changedPalette = key != _paletteKey;
    _paletteKey = key;
    for (final particle in _components) {
      if (changedPalette) {
        particle.paletteColor = spatialFireflyColor(
          seed: particle.zone.seed,
          index: particle.index,
          yellow: key.$1,
          green: key.$2,
          blue: key.$3,
          pink: key.$4,
        );
        if (particle.paletteColor case final color?) {
          particle.lightColor = Color(0xff000000 | color.rgb);
        }
      }
      final color = particle.paletteColor;
      particle.visible =
          color != null &&
          enabled &&
          night > .001 &&
          particle.index <
              (particle.zone.count * profile.fireflyDensity).round();
      if (!particle.visible) continue;
      final sample = spatialFireflySample(
        particle.zone,
        particle.index,
        elapsedSeconds: elapsedSeconds,
        night: night,
      );
      particle.position.setValues(
        sample.position.x,
        sample.position.y,
        sample.position.z,
      );
      particle.rotation.setEuler(cameraYaw, -cameraPitch, 0);
      particle.lightStrength = sample.opacity;
      particle.material.albedoColor = particle.lightColor.withValues(
        alpha: sample.opacity,
      );
    }
  }

  void clear() {
    for (final particle in _components) {
      particle.removeFromParent();
    }
    _components.clear();
    _lightBudget.reset();
    _paletteKey = null;
    _profile = null;
  }
}

final class _Firefly extends MeshComponent {
  factory _Firefly(SpatialFireflyZone zone, int index) {
    final material = SpatialPixelMaterial(
      Texture.standard,
      alphaMode: Model3dAlphaMode.blend,
      emissive: true,
    )..cullMode = CullMode.none;
    final vertices = [
      Vertex(position: Vector3.zero(), texCoord: Vector2.zero()),
    ];
    final indices = <int>[];
    const segments = 12;
    for (var ring = 0; ring < 2; ring++) {
      final radius = ring == 0 ? .016 : .085;
      final alpha = ring == 0 ? .9 : 0.0;
      for (var i = 0; i < segments; i++) {
        final angle = i * math.pi * 2 / segments;
        vertices.add(
          Vertex(
            position: Vector3(
              math.cos(angle) * radius,
              math.sin(angle) * radius,
              0,
            ),
            texCoord: Vector2.zero(),
            color: Color.fromRGBO(255, 255, 255, alpha),
          ),
        );
        final current = 1 + ring * segments + i,
            next = 1 + ring * segments + (i + 1) % segments;
        if (ring == 0) {
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
    return _Firefly._(zone, index, mesh, material);
  }
  _Firefly._(this.zone, this.index, Mesh mesh, this.material)
    : super(mesh: mesh);
  final SpatialFireflyZone zone;
  final int index;
  final SpatialPixelMaterial material;
  bool visible = false;
  SpatialFireflyColor? paletteColor;
  Color lightColor = const Color(0xffffef96);
  double lightStrength = 0;
  @override
  void draw(RenderContext3D context) {
    if (visible) super.draw(context);
  }
}
