import 'dart:ui' show Rect;

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';

import 'spatial_weather_profile.dart';

final class SpatialWeatherMaterial extends Material {
  SpatialWeatherMaterial()
    : super(
        vertexShader: VertexShader.fromAsset(
          _bundle,
          entryPoint: 'WeatherVertex',
          slots: ['Weather', 'JointMatrices'],
        ),
        fragmentShader: FragmentShader.fromAsset(
          _bundle,
          entryPoint: 'WeatherFragment',
        ),
      );

  static const _bundle =
      'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle';
  static final _identity = Matrix4.identity();
  final _anchorTime = Vector4.zero();
  final _motion = Vector4.zero();
  final _particle = Vector4.zero();
  final _tint = Vector4.zero();
  final _bounds = Vector4.zero();
  final _volume = Vector4.zero();
  double _cameraDistance = 40;
  bool visible = false;

  void configure({
    required SpatialWeatherFrame frame,
    required Vector3 anchor,
    required Rect bounds,
    required double seconds,
    required double weight,
    required int count,
    double cameraDistance = 40,
  }) {
    _cameraDistance = cameraDistance;
    visible = count > 0 && frame.opacity * weight > .001;
    _anchorTime.setValues(anchor.x, anchor.y, anchor.z, seconds);
    _motion.setValues(
      frame.windX,
      frame.fallSpeed,
      frame.windZ,
      frame.shape.toDouble(),
    );
    _particle.setValues(
      count.toDouble(),
      frame.size,
      frame.streakLength,
      frame.opacity,
    );
    _tint.setValues(frame.color.r, frame.color.g, frame.color.b, weight);
    _bounds.setValues(bounds.left, bounds.top, bounds.right, bounds.bottom);
  }

  @override
  void apply(covariant RenderContext3D context) {
    final projectionScale =
        context.projection[0].abs() < context.projection[5].abs()
        ? context.projection[0].abs()
        : context.projection[5].abs();
    final span = (2 * _cameraDistance / projectionScale.clamp(.1, 100) + 8)
        .clamp(16.0, 80.0);
    _volume.setValues(span, 10, 0, 0);
    vertexShader
      ..setMatrix4('Weather.view', context.view)
      ..setMatrix4('Weather.projection', context.projection)
      ..setVector4('Weather.anchorTime', _anchorTime)
      ..setVector4('Weather.motion', _motion)
      ..setVector4('Weather.particle', _particle)
      ..setVector4('Weather.tint', _tint)
      ..setVector4('Weather.bounds', _bounds)
      ..setVector4('Weather.volume', _volume)
      ..setMatrix4('JointMatrices.joints[0]', _identity);
  }
}

final class SpatialWeatherBatch extends MeshComponent {
  factory SpatialWeatherBatch() {
    final material = SpatialWeatherMaterial();
    final vertices = <Vertex>[];
    final indices = <int>[];
    const corners = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)];
    var state = 0x736f6e;
    double random() {
      state = (state * 1664525 + 1013904223) & 0xffffffff;
      return state / 4294967296;
    }

    for (var index = 0; index < spatialWeatherMaximumParticles; index++) {
      final seed = Vector3(index.toDouble(), random(), random());
      final variation = Vector3(random(), random(), random());
      final base = vertices.length;
      for (final corner in corners) {
        vertices.add(
          Vertex(
            position: seed,
            normal: variation,
            texCoord: Vector2(corner.$1, corner.$2),
          ),
        );
      }
      indices.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
    }
    final mesh = Mesh()
      ..addSurface(
        Surface(
          vertices: vertices,
          indices: indices,
          material: material,
          calculateNormals: false,
        ),
      );
    return SpatialWeatherBatch._(material, mesh);
  }

  SpatialWeatherBatch._(this.material, Mesh mesh) : super(mesh: mesh);
  final SpatialWeatherMaterial material;

  @override
  Aabb3 computeLocalAabb() =>
      Aabb3.minMax(Vector3(-30, -2, -30), Vector3(30, 16, 30));

  void prepare() {
    material.resource;
    for (final surface in mesh.surfaces) {
      surface.resource;
    }
  }

  @override
  bool isVisible(CameraComponent3D camera) => material.visible;

  @override
  void draw(covariant RenderContext3D context) {
    if (material.visible) super.draw(context);
  }
}
