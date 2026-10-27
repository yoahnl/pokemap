import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';

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
  SpatialDepthOfField(this.backend) : _depthDevice = _DepthDevice(backend);

  static const _bundle =
      'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle';
  final GpuBackend backend;
  final _DepthDevice _depthDevice;
  final _materials = Expando<_DepthMaterial>();
  SpatialDepthOfFieldProfile profile = SpatialDepthOfFieldProfile();
  double focusDepth = 1;
  double _depthScale = 100;
  GpuRenderTarget? _depthTarget, _outputTarget;
  (int, int)? _size;
  GpuPipeline? _pipeline;
  GpuShader? _fragment;
  GpuBuffer? _vertices;
  final _uniforms = Float32List(8);
  int targetAllocations = 0, depthPasses = 0, compositePasses = 0;

  void renderDepth({
    required Size size,
    required Matrix4 view,
    required Matrix4 projection,
    required void Function(
      RenderContext3D,
      Material Function(SpatialPixelMaterial),
    )
    draw,
  }) {
    if (!profile.active) return;
    final dimensions = (size.width.toInt(), size.height.toInt());
    if (dimensions.$1 <= 0 || dimensions.$2 <= 0) return;
    if (_size != dimensions) {
      final depthTarget = backend.createRenderTarget(
        width: dimensions.$1,
        height: dimensions.$2,
        clearValue: const Color(0xffffffff),
      );
      final outputTarget = backend.createRenderTarget(
        width: dimensions.$1,
        height: dimensions.$2,
        clearValue: const Color(0x00000000),
      );
      _depthTarget = depthTarget;
      _outputTarget = outputTarget;
      _size = dimensions;
      targetAllocations += 2;
    }
    _depthScale = math.max(100, focusDepth + profile.focusRange * 8);
    final context = RenderContext3D(_depthDevice)..setCamera(view, projection);
    _depthDevice.beginDepth(_depthTarget!);
    try {
      draw(
        context,
        (source) => (_materials[source] ??= _DepthMaterial(source))
          ..depthScale = _depthScale
          ..cullMode = source.cullMode,
      );
    } finally {
      _depthDevice.endDepth();
    }
    depthPasses++;
  }

  GpuTexture compositeTexture(GpuRenderTarget color, Size size) {
    if (!profile.active || _depthTarget == null) return color.colorTexture;
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
      ..[3] = _depthScale
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
      ..bindTexture(
        _fragment!.getUniformSlot('depthTexture'),
        _depthTarget!.colorTexture,
      )
      ..draw()
      ..submit();
    compositePasses++;
    return _outputTarget!.colorTexture;
  }

  Image composite(GpuRenderTarget color, Size size) =>
      compositeTexture(color, size).asImage();
}

final class _DepthDevice extends GraphicsDevice {
  _DepthDevice(GpuBackend backend) : super(backend: backend);
  late GpuRenderPass _pass;
  void beginDepth(GpuRenderTarget target) {
    _pass = backend.beginFrame().beginRenderPass(
      target,
      blend: BlendState.opaque,
      depthStencil: DepthStencilState.standard,
    );
  }

  void endDepth() => _pass.submit();
  @override
  void clearBindings() => _pass.clearBindings();
  @override
  void bindPipeline(GpuPipeline pipeline, CullMode cullMode) =>
      _pass.bindPipeline(pipeline, cullMode);
  @override
  void bindUniform(GpuUniformSlot slot, ByteData data) =>
      _pass.bindUniform(slot, data);
  @override
  void bindTexture(GpuUniformSlot slot, Texture texture) =>
      _pass.bindTexture(slot, texture.resource);
  @override
  void bindGeometry(Surface surface) {
    _pass
      ..bindVertexBuffer(
        GpuBufferView(
          surface.resource,
          offsetInBytes: 0,
          lengthInBytes: surface.verticesBytes,
        ),
        surface.vertexCount,
      )
      ..bindIndexBuffer(
        GpuBufferView(
          surface.resource,
          offsetInBytes: surface.verticesBytes,
          lengthInBytes: surface.indicesBytes,
        ),
        GpuIndexType.uint16,
        surface.indexCount,
      )
      ..draw();
  }
}

final class _DepthMaterial extends UnlitMaterial {
  _DepthMaterial(this.source) {
    vertexShader = VertexShader.fromAsset(
      SpatialDepthOfField._bundle,
      entryPoint: source.groundDepthOnly ? 'GroundVertex' : 'TextureVertex',
      slots: ['VertexInfo', 'JointMatrices'],
    );
    fragmentShader = FragmentShader.fromAsset(
      SpatialDepthOfField._bundle,
      entryPoint: 'CameraDepthFragment',
      slots: ['albedoTexture', 'Material', 'CameraDepth'],
    );
  }
  final SpatialPixelMaterial source;
  double depthScale = 100;
  static final _identity = Matrix4.identity();
  final _depth = Vector4.zero();
  final _dimensions = Vector2.zero(), _wrap = Vector2.zero();
  @override
  void apply(covariant RenderContext3D context) {
    albedoTexture = source.albedoTexture;
    albedoColor = source.albedoColor;
    cullMode = source.cullMode;
    super.apply(context);
    if (context.jointsInfo.jointTransforms.isEmpty) {
      vertexShader.setMatrix4('JointMatrices.joints[0]', _identity);
    }
    _depth.setValues(depthScale, 0, 0, 0);
    _dimensions.setValues(
      albedoTexture.width.toDouble(),
      albedoTexture.height.toDouble(),
    );
    _wrap.setValues(
      source.activeWrapS.toDouble(),
      source.activeWrapT.toDouble(),
    );
    fragmentShader
      ..setVector4('Material.uvRect', source.uvRect)
      ..setVector4('Material.uvTransformU', source.uvTransformU)
      ..setVector4('Material.uvTransformV', source.uvTransformV)
      ..setVector2('Material.textureDimensions', _dimensions)
      ..setVector2('Material.wrapModes', _wrap)
      ..setFloat('Material.alphaMode', switch (source.alphaMode) {
        null => 0,
        Model3dAlphaMode.opaque => 1,
        Model3dAlphaMode.mask => 2,
        Model3dAlphaMode.blend => 3,
      })
      ..setFloat('Material.alphaCutoff', source.alphaCutoff)
      ..setVector4('CameraDepth.options', _depth);
  }
}
