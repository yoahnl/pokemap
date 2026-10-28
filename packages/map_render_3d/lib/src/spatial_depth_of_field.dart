import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/graphics.dart';

final class SpatialDepthOfFieldProfile {
  SpatialDepthOfFieldProfile({
    this.enabled = false,
    this.strength = .35,
    this.focusRange = 12,
  }) {
    if (!strength.isFinite ||
        strength < 0 ||
        strength > 1 ||
        !focusRange.isFinite ||
        focusRange < 2 ||
        focusRange > 40) {
      throw ArgumentError('Invalid depth of field profile.');
    }
  }

  final bool enabled;
  final double strength, focusRange;
  bool get active => enabled && strength > 0;

  double blurAtDepth(double depth, {required double focusDepth}) {
    if (!active) return 0;
    final half = focusRange / 2;
    final t = ((depth - focusDepth).abs() - half) / math.max(2, half);
    final clamped = t.clamp(0.0, 1.0);
    return clamped * clamped * (3 - 2 * clamped) * strength;
  }
}

final class SpatialDepthOfField {
  SpatialDepthOfField(this.backend);

  static const depthClearValue = Color(0xffffffff);
  static const _bundle =
      'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle';
  final GpuBackend backend;
  SpatialDepthOfFieldProfile profile = SpatialDepthOfFieldProfile();
  double focusDepth = 1;
  GpuRenderTarget? _outputTarget;
  (int, int)? _size;
  GpuPipeline? _pipeline;
  GpuShader? _fragment;
  GpuBuffer? _vertices;
  final _uniforms = Float32List(8);
  int targetAllocations = 0, compositePasses = 0;

  GpuTexture compositeTexture(GpuRenderTarget color, Size size) {
    final depth = color.secondaryColorTexture;
    final dimensions = (size.width.toInt(), size.height.toInt());
    if (!profile.active ||
        depth == null ||
        dimensions.$1 <= 0 ||
        dimensions.$2 <= 0) {
      return color.colorTexture;
    }
    if (_size != dimensions) {
      _outputTarget = backend.createRenderTarget(
        width: dimensions.$1,
        height: dimensions.$2,
        clearValue: const Color(0x00000000),
      );
      _size = dimensions;
      targetAllocations++;
    }
    if (_pipeline == null) {
      final library = backend.loadShaderLibrary(_bundle);
      final fragment = library['DepthOfFieldFragment'];
      final pipeline = backend.createPipeline(
        vertexShader: library['DepthOfFieldVertex'],
        fragmentShader: fragment,
      );
      final vertices = Float32List.fromList([-1, -1, 3, -1, -1, 3]);
      final buffer = backend.createBuffer(
        storageMode: GpuStorageMode.hostVisible,
        sizeInBytes: vertices.lengthInBytes,
      )..write(vertices.buffer.asByteData());
      _fragment = fragment;
      _pipeline = pipeline;
      _vertices = buffer;
    }
    _uniforms
      ..[0] = focusDepth
      ..[1] = profile.focusRange / 2
      ..[2] = 12 * profile.strength * size.width / 960
      ..[3] = math.max(100, focusDepth + profile.focusRange * 8)
      ..[4] = size.width
      ..[5] = size.height
      ..[6] = math.max(2, profile.focusRange / 2)
      ..[7] = 0;
    final pass = backend.beginFrame().beginRenderPass(
      _outputTarget!,
      blend: BlendState.opaque,
      depthStencil: DepthStencilState.none,
    );
    pass
      ..bindPipeline(_pipeline!, CullMode.none)
      ..bindVertexBuffer(
        GpuBufferView(_vertices!, offsetInBytes: 0, lengthInBytes: 24),
        3,
      )
      ..bindUniform(
        _fragment!.getUniformSlot('DepthOfField'),
        _uniforms.buffer.asByteData(),
      )
      ..bindTexture(
        _fragment!.getUniformSlot('sceneTexture'),
        color.colorTexture,
      )
      ..bindTexture(_fragment!.getUniformSlot('depthTexture'), depth)
      ..draw()
      ..submit();
    compositePasses++;
    return _outputTarget!.colorTexture;
  }

  Image composite(GpuRenderTarget color, Size size) =>
      compositeTexture(color, size).asImage();
}
