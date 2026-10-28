import 'dart:ui';
import 'dart:math' as math;

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_light_behavior.dart';
import 'spatial_pixel_material.dart';

final class SpatialFlameSource {
  const SpatialFlameSource({
    required this.key,
    required this.light,
    required this.transform,
    this.visible = true,
    this.strength = 1,
  });

  final Object key;
  final Model3dPointLight light;
  final Matrix4 transform;
  final bool visible;
  final double strength;
}

final class SpatialFlameEffects {
  SpatialFlameEffects(this.world);

  final World3D world;
  final _flames = <Object, _Flame>{};
  int allocations = 0;
  double soundGain = 0;
  int get visibleCount => _flames.values.where((v) => v.visible).length;
  int get emberCount =>
      _flames.values.fold(0, (count, flame) => count + flame.embers.length);
  Iterable<MeshComponent> get components => _flames.values;

  void sync({
    required Iterable<SpatialFlameSource> sources,
    required double elapsedSeconds,
    required double daylight,
    required double cameraPitch,
    required double cameraYaw,
    bool indoors = false,
    Vector3? listenerPosition,
  }) {
    soundGain = 0;
    final retained = <Object>{};
    for (final source in sources) {
      final definition = source.light.flame;
      if (definition == null) continue;
      retained.add(source.key);
      var flame = _flames[source.key];
      if (flame == null || flame.style != definition.style) {
        flame?.removeEffects();
        flame = _Flame(definition.style);
        world.add(flame);
        _flames[source.key] = flame;
        allocations++;
      }
      final count = (definition.embers * 8).round();
      while (flame.embers.length < count) {
        final ember = _Ember();
        world.add(ember);
        flame.embers.add(ember);
      }
      while (flame.embers.length > count)
        flame.embers.removeLast().removeFromParent();
      final strength =
          source.strength *
          source.light.intensity.clamp(0.0, 1.0) *
          (source.light.nightOnly && !indoors ? 1 - daylight : 1);
      flame.visible = source.visible && strength > .001;
      for (final ember in flame.embers) ember.visible = flame.visible;
      if (!flame.visible) continue;
      final local = source.light.localPosition;
      final position = source.transform.transform3(
        Vector3(local.x, local.y, local.z),
      );
      if (listenerPosition != null && definition.crackleVolume > 0) {
        final distance = position.distanceTo(listenerPosition);
        final falloff = (1 - distance / (source.light.radius * 2)).clamp(
          0.0,
          1.0,
        );
        soundGain = math.max(
          soundGain,
          definition.crackleVolume * strength * falloff * falloff,
        );
      }
      final origin = source.transform.transform3(Vector3.zero());
      final up = source.transform.transform3(Vector3(0, 1, 0));
      final size = definition.height * (up - origin).length;
      final motion = spatialFlameMotion(
        elapsedSeconds,
        phase: spatialFlamePhase(position.x, position.y, position.z),
        flicker: definition.flicker,
      );
      flame.position.setFrom(position);
      flame.material.flameElapsedSeconds =
          elapsedSeconds +
          spatialFlamePhase(position.x, position.y, position.z) * 7;
      flame.scale.setValues(size * motion.width, size * motion.height, size);
      flame.rotation.setEuler(cameraYaw, 0, motion.lean);
      final color =
          source.light.colorCycle?.sample(elapsedSeconds) ??
          source.light.colorRgb;
      flame.material.albedoColor = Color(0xff000000 | color)
          .withValues(alpha: strength.clamp(0.0, 1.0));
      for (final (index, ember) in flame.embers.indexed) {
        final phase =
            (elapsedSeconds / (1.4 + index * .21) +
                spatialFlamePhase(position.x, position.y, position.z) +
                index * .23) %
            1;
        ember.position.setValues(
          position.x +
              size *
                  (.1 * math.sin(phase * 6 + index) +
                      phase * .1 * (index.isEven ? 1 : -1)),
          position.y + size * (.25 + phase * .9),
          position.z + size * .04 * math.sin(phase * 4 + index),
        );
        ember.rotation.setEuler(cameraYaw, -cameraPitch, phase * 2);
        final radius = size * (.035 - phase * .02);
        ember.scale.setValues(radius, radius * 1.5, radius);
        ember.material.albedoColor = Color(0xff000000 | color).withValues(
          alpha: (strength * math.min(1, phase * 12) * math.pow(1 - phase, 1.3))
              .clamp(0.0, 1.0),
        );
      }
    }
    for (final key
        in _flames.keys.where((key) => !retained.contains(key)).toList()) {
      _flames.remove(key)!.removeEffects();
    }
  }

  void clear() {
    soundGain = 0;
    for (final flame in _flames.values) {
      flame.removeEffects();
    }
    _flames.clear();
  }
}

final class _Flame extends MeshComponent {
  factory _Flame(ModelLightFlameStyle style) {
    final material = SpatialPixelMaterial(
      Texture.standard,
      alphaMode: Model3dAlphaMode.blend,
      emissive: true,
      proceduralFlame: style == ModelLightFlameStyle.brazier,
    )..cullMode = CullMode.none;
    if (style == ModelLightFlameStyle.brazier) {
      final mesh = Mesh()
        ..addSurface(
          Surface(
            vertices: [
              Vertex(position: Vector3(-.55, 0, 0), texCoord: Vector2(0, 0)),
              Vertex(position: Vector3(.55, 0, 0), texCoord: Vector2(1, 0)),
              Vertex(position: Vector3(.55, 1, 0), texCoord: Vector2(1, 1)),
              Vertex(position: Vector3(-.55, 1, 0), texCoord: Vector2(0, 1)),
            ],
            indices: [0, 1, 2, 0, 2, 3],
            material: material,
          ),
        );
      return _Flame._(mesh, material, style);
    }
    final vertices = <Vertex>[];
    final indices = <int>[];
    void lobe(
      List<(double, double)> outline,
      Color edge,
      Color center,
      double centerY,
      double depth,
    ) {
      final start = vertices.length;
      vertices.add(
        Vertex(
          position: Vector3(0, centerY, depth),
          texCoord: Vector2.zero(),
          color: center,
        ),
      );
      for (final (x, y) in outline) {
        vertices.add(
          Vertex(
            position: Vector3(x, y, depth),
            texCoord: Vector2.zero(),
            color: edge,
          ),
        );
      }
      for (var i = 0; i < outline.length; i++) {
        indices.addAll([
          start,
          start + 1 + i,
          start + 1 + (i + 1) % outline.length,
        ]);
      }
    }

    lobe(
      const [
        (0, 0),
        (-.16, .05),
        (-.24, .2),
        (-.22, .38),
        (-.1, .59),
        (-.04, .8),
        (.04, 1),
        (.14, .75),
        (.13, .57),
        (.24, .4),
        (.22, .19),
        (.14, .05),
      ],
      const Color(0x55ff8020),
      const Color(0xffffdf8c),
      .28,
      0,
    );
    if (style == ModelLightFlameStyle.brazier) {
      lobe(
        const [
          (-.4, .04),
          (-.48, .25),
          (-.32, .49),
          (-.35, .78),
          (-.13, .58),
          (.02, .22),
          (-.08, .04),
        ],
        const Color(0x88ff7020),
        const Color(0xffffdb80),
        .23,
        .0005,
      );
      lobe(
        const [
          (.08, .04),
          (.02, .22),
          (.17, .53),
          (.27, .82),
          (.29, .59),
          (.47, .31),
          (.39, .08),
        ],
        const Color(0x88ff7020),
        const Color(0xffffdb80),
        .25,
        .0007,
      );
    }
    lobe(
      const [
        (0, .015),
        (-.075, .05),
        (-.11, .16),
        (-.06, .32),
        (.015, .57),
        (.075, .34),
        (.1, .17),
        (.07, .06),
      ],
      const Color(0xaaffdf8c),
      const Color(0xfffffff0),
      .15,
      .001,
    );
    return _Flame._(
      Mesh()..addSurface(
        Surface(vertices: vertices, indices: indices, material: material),
      ),
      material,
      style,
    );
  }

  _Flame._(Mesh mesh, this.material, this.style) : super(mesh: mesh);
  final SpatialPixelMaterial material;
  final ModelLightFlameStyle style;
  final embers = <_Ember>[];
  bool visible = false;

  @override
  bool isVisible(CameraComponent3D camera) =>
      visible && super.isVisible(camera);

  @override
  void renderTree(Canvas canvas) {
    if (visible) super.renderTree(canvas);
  }

  void removeEffects() {
    for (final ember in embers) ember.removeFromParent();
    embers.clear();
    removeFromParent();
  }
}

final class _Ember extends MeshComponent {
  factory _Ember() {
    final material = SpatialPixelMaterial(
      Texture.standard,
      alphaMode: Model3dAlphaMode.blend,
      emissive: true,
    )..cullMode = CullMode.none;
    final mesh = Mesh()
      ..addSurface(
        Surface(
          vertices: [
            for (final point in const [
              (-.5, -.5),
              (.5, -.5),
              (.5, .5),
              (-.5, .5),
            ])
              Vertex(
                position: Vector3(point.$1, point.$2, 0),
                texCoord: Vector2.zero(),
                color: const Color(0xfffffff0),
              ),
          ],
          indices: [0, 1, 2, 0, 2, 3],
          material: material,
        ),
      );
    return _Ember._(mesh, material);
  }
  _Ember._(Mesh mesh, this.material) : super(mesh: mesh);
  final SpatialPixelMaterial material;
  bool visible = false;
  @override
  void renderTree(Canvas canvas) {
    if (visible) super.renderTree(canvas);
  }
}
