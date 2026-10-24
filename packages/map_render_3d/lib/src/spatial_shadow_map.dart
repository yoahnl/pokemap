import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';
import 'spatial_shadow_profile.dart';
import 'spatial_point_light.dart';
import 'spatial_point_shadow.dart';

final class SpatialShadowMap {
  SpatialShadowMap(GpuBackend backend, {bool ownsFrame = true})
    : _device = _ShadowGraphicsDevice(backend, ownsFrame: ownsFrame);

  final _ShadowGraphicsDevice _device;
  final _materials = Expando<_ShadowDepthMaterial>();
  GpuRenderTarget? _target;
  Texture? _texture;
  int _resolution = 0;
  int targetAllocations = 0;
  final _pointMaterials = Expando<_PointShadowDepthMaterial>();
  GpuRenderTarget? _pointTarget;
  Texture? _pointTexture;
  int _pointLightCount = 0;
  int pointTargetAllocations = 0;

  SpatialPointShadowFrame? renderPointLights(
    List<SpatialPointLight> lights,
    void Function(
      RenderContext3D context,
      Material Function(SpatialPixelMaterial) depthMaterial,
      SpatialPointLight light,
    )
    draw,
  ) {
    if (lights.isEmpty) return null;
    if (lights.length > 4)
      throw ArgumentError('At most four point shadow lights are supported.');
    if (_pointTarget == null || _pointLightCount != lights.length) {
      _pointLightCount = lights.length;
      _pointTarget = _device.backend.createRenderTarget(
        width: spatialPointShadowFaceResolution * 3,
        height: spatialPointShadowFaceResolution * 2 * lights.length,
        clearValue: const Color(0xffffffff),
      );
      _pointTexture = _ShadowTexture(
        _pointTarget!.colorTexture,
        spatialPointShadowFaceResolution * 3,
        height: spatialPointShadowFaceResolution * 2 * lights.length,
      );
      pointTargetAllocations++;
    }
    final context = RenderContext3D(_device);
    _device.beginShadow(_pointTarget!);
    try {
      for (var lightIndex = 0; lightIndex < lights.length; lightIndex++) {
        final light = lights[lightIndex];
        for (var face = 0; face < 6; face++) {
          final projection = spatialPointShadowProjection(light, face);
          context.setCamera(projection.view, projection.projection);
          draw(context, (source) {
            final material = _pointMaterials[source] ??=
                _PointShadowDepthMaterial(source);
            material
              ..light = light
              ..face = face
              ..lightIndex = lightIndex
              ..lightCount = lights.length;
            return material;
          }, light);
        }
      }
    } finally {
      _device.endShadow();
    }
    return SpatialPointShadowFrame(_pointTexture!, lights.length);
  }

  SpatialShadowFrame render(
    SpatialShadowProfile profile,
    ({double x, double y, double z}) direction,
    void Function(
      RenderContext3D context,
      Material Function(SpatialPixelMaterial) depthMaterial,
    )
    draw,
  ) {
    if (_target == null || _resolution != profile.resolution) {
      _resolution = profile.resolution;
      _target = _device.backend.createRenderTarget(
        width: _resolution,
        height: _resolution,
        clearValue: const Color(0xffffffff),
      );
      _texture = _ShadowTexture(_target!.colorTexture, _resolution);
      targetAllocations++;
    }
    final projection = spatialShadowProjection(profile, direction);
    final context = RenderContext3D(_device)
      ..setCamera(projection.view, projection.projection);
    _device.beginShadow(_target!);
    try {
      draw(
        context,
        (source) => _materials[source] ??= _ShadowDepthMaterial(source),
      );
    } finally {
      _device.endShadow();
    }
    return SpatialShadowFrame(_texture!, projection.viewProjection, profile);
  }
}

final class _ShadowTexture extends Texture {
  _ShadowTexture(this.handle, int size, {int? height})
    : super(ByteData(0), width: size, height: height ?? size);
  final GpuTexture handle;
  @override
  GpuTexture createResource() => handle;
}

final class _ShadowGraphicsDevice extends GraphicsDevice {
  _ShadowGraphicsDevice(GpuBackend backend, {required this.ownsFrame})
    : super(backend: backend);
  final bool ownsFrame;
  late GpuFrame _frame;
  late GpuRenderPass _pass;

  void beginShadow(GpuRenderTarget target) {
    _frame = backend.beginFrame();
    _pass = _frame.beginRenderPass(
      target,
      blend: BlendState.opaque,
      depthStencil: DepthStencilState.standard,
    );
  }

  void endShadow() {
    _pass.submit();
    if (ownsFrame) _frame.end();
  }

  @override
  void clearBindings() => _pass.clearBindings();
  @override
  void bindPipeline(GpuPipeline pipeline, CullMode cullMode) =>
      _pass.bindPipeline(pipeline, cullMode);
  @override
  void bindUniform(GpuUniformSlot slot, ByteBuffer buffer) =>
      _pass.bindUniform(slot, buffer.asByteData());
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

final class _ShadowDepthMaterial extends UnlitMaterial {
  _ShadowDepthMaterial(this.source) {
    vertexShader = VertexShader.fromAsset(
      _bundle,
      entryPoint: 'TextureVertex',
      slots: ['VertexInfo', 'JointMatrices'],
    );
    fragmentShader = FragmentShader.fromAsset(
      _bundle,
      entryPoint: 'ShadowDepthFragment',
      slots: ['albedoTexture', 'Material'],
    );
  }
  static const _bundle =
      'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle';
  static final _identity = Matrix4.identity();
  final SpatialPixelMaterial source;

  @override
  void apply(covariant RenderContext3D context) {
    albedoColor = source.albedoColor;
    albedoTexture = source.albedoTexture;
    cullMode = source.cullMode;
    super.apply(context);
    if (context.jointsInfo.jointTransforms.isEmpty) {
      vertexShader.setMatrix4('JointMatrices.joints[0]', _identity);
    }
    fragmentShader
      ..setVector4('Material.uvRect', source.uvRect)
      ..setVector4('Material.uvTransformU', source.uvTransformU)
      ..setVector4('Material.uvTransformV', source.uvTransformV)
      ..setVector2(
        'Material.textureDimensions',
        Vector2(
          albedoTexture.width.toDouble(),
          albedoTexture.height.toDouble(),
        ),
      )
      ..setVector2(
        'Material.wrapModes',
        Vector2(source.activeWrapS.toDouble(), source.activeWrapT.toDouble()),
      )
      ..setFloat('Material.alphaMode', switch (source.alphaMode) {
        null => 0,
        Model3dAlphaMode.opaque => 1,
        Model3dAlphaMode.mask => 2,
        Model3dAlphaMode.blend => 3,
      })
      ..setFloat('Material.alphaCutoff', source.alphaCutoff);
  }
}

final class _PointShadowDepthMaterial extends _ShadowDepthMaterial {
  _PointShadowDepthMaterial(super.source) {
    vertexShader = VertexShader.fromAsset(
      _ShadowDepthMaterial._bundle,
      entryPoint: 'PointShadowVertex',
      slots: ['VertexInfo', 'JointMatrices', 'PointDepth'],
    );
    fragmentShader = FragmentShader.fromAsset(
      _ShadowDepthMaterial._bundle,
      entryPoint: 'PointShadowDepthFragment',
      slots: ['albedoTexture', 'Material', 'PointDepth'],
    );
  }
  late SpatialPointLight light;
  int face = 0, lightIndex = 0, lightCount = 1;
  final _positionRadius = Vector4.zero(), _tile = Vector4.zero();

  @override
  void apply(covariant RenderContext3D context) {
    super.apply(context);
    _positionRadius.setValues(
      light.position.x,
      light.position.y,
      light.position.z,
      light.radius,
    );
    _tile.setValues(
      (face % 3).toDouble(),
      (face ~/ 3 + lightIndex * 2).toDouble(),
      face.toDouble(),
      (lightCount * 2).toDouble(),
    );
    vertexShader.setVector4('PointDepth.tile', _tile);
    fragmentShader
      ..setVector4('PointDepth.positionRadius', _positionRadius)
      ..setVector4('PointDepth.tile', _tile);
  }
}
