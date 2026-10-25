import 'dart:typed_data';

import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';
import 'spatial_shadow_profile.dart';
import 'spatial_point_light.dart';
import 'spatial_point_shadow.dart';
import 'spatial_shadow_target.dart';
import 'spatial_shadow_coverage.dart';

final class SpatialShadowMap {
  SpatialShadowMap(GpuBackend backend, {bool ownsFrame = true})
    : _device = _ShadowGraphicsDevice(backend, ownsFrame: ownsFrame);

  final _ShadowGraphicsDevice _device;
  final _materials = Expando<_ShadowDepthMaterial>();
  final _sampledMaterials = Expando<_ShadowDepthMaterial>();
  SpatialShadowTarget? _target;
  Texture? _texture;
  int _resolution = 0;
  int targetAllocations = 0;
  bool _antialiasing = true, _pointAntialiasing = true;
  bool _preferMultisampling = true, _pointPreferMultisampling = true;
  final _pointMaterials = Expando<_PointShadowDepthMaterial>();
  final _sampledPointMaterials = Expando<_PointShadowDepthMaterial>();
  SpatialShadowTarget? _pointTarget;
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
    draw, {
    bool antialiasing = true,
    bool preferMultisampling = true,
  }) {
    if (lights.isEmpty) return null;
    if (lights.length > 4)
      throw ArgumentError('At most four point shadow lights are supported.');
    if (_pointTarget == null ||
        _pointLightCount != lights.length ||
        _pointAntialiasing != antialiasing ||
        _pointPreferMultisampling != preferMultisampling) {
      _pointAntialiasing = antialiasing;
      _pointPreferMultisampling = preferMultisampling;
      _pointLightCount = lights.length;
      _pointTarget = SpatialShadowTarget(
        _device.backend,
        width: spatialPointShadowFaceResolution * 3,
        height: spatialPointShadowFaceResolution * 2 * lights.length,
        antialiasing: antialiasing,
        preferMultisampling: preferMultisampling,
      );
      _pointTexture = _ShadowTexture(
        _pointTarget!.texture,
        spatialPointShadowFaceResolution *
            3 *
            (_pointTarget!.supersampled ? 2 : 1),
        height:
            spatialPointShadowFaceResolution *
            2 *
            lights.length *
            (_pointTarget!.supersampled ? 2 : 1),
      );
      pointTargetAllocations++;
    }
    final context = RenderContext3D(_device);
    _device.beginShadow(_pointTarget!.target);
    try {
      for (var lightIndex = 0; lightIndex < lights.length; lightIndex++) {
        final light = lights[lightIndex];
        for (var face = 0; face < 6; face++) {
          final projection = spatialPointShadowProjection(light, face);
          context.setCamera(projection.view, projection.projection);
          draw(context, (source) {
            final materials = _pointTarget!.multisampled
                ? _sampledPointMaterials
                : _pointMaterials;
            final material = materials[source] ??= _PointShadowDepthMaterial(
              source,
              multisampled: _pointTarget!.multisampled,
            );
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
    return SpatialPointShadowFrame(
      _pointTexture!,
      lights.length,
      samples: _pointTarget!.samples,
      supersampled: _pointTarget!.supersampled,
    );
  }

  SpatialShadowFrame render(
    SpatialShadowProfile profile,
    ({double x, double y, double z}) direction,
    void Function(
      RenderContext3D context,
      Material Function(SpatialPixelMaterial) depthMaterial,
    )
    draw, {
    bool antialiasing = true,
    bool preferMultisampling = true,
    SpatialShadowCoverage? coverage,
  }) {
    if (_target == null ||
        _resolution != profile.resolution ||
        _antialiasing != antialiasing ||
        _preferMultisampling != preferMultisampling) {
      _antialiasing = antialiasing;
      _preferMultisampling = preferMultisampling;
      _resolution = profile.resolution;
      _target = SpatialShadowTarget(
        _device.backend,
        width: _resolution,
        height: _resolution,
        antialiasing: antialiasing,
        preferMultisampling: preferMultisampling,
      );
      _texture = _ShadowTexture(
        _target!.texture,
        _resolution * (_target!.supersampled ? 2 : 1),
      );
      targetAllocations++;
    }
    final projection = spatialShadowProjection(profile, direction);
    final relativeProjection = spatialShadowProjection(
      profile,
      direction,
      origin: profile.center,
    );
    final context = RenderContext3D(_device)
      ..setCamera(relativeProjection.view, relativeProjection.projection);
    _device.beginShadow(_target!.target);
    try {
      draw(context, (source) {
        final material =
            (_target!.multisampled
            ? _sampledMaterials
            : _materials)[source] ??= _ShadowDepthMaterial(
              source,
              multisampled: _target!.multisampled,
            );
        material.origin.setValues(
          profile.center.x,
          profile.center.y,
          profile.center.z,
        );
        return material;
      });
    } finally {
      _device.endShadow();
    }
    return SpatialShadowFrame(
      _texture!,
      projection.viewProjection,
      profile,
      samples: _target!.samples,
      supersampled: _target!.supersampled,
      origin: profile.center,
      relativeWorldToLight: relativeProjection.viewProjection,
      coverage: coverage?.mask ?? spatialFullShadowCoverage,
    );
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
  _ShadowDepthMaterial(this.source, {this.multisampled = false}) {
    vertexShader = VertexShader.fromAsset(
      _bundle,
      entryPoint: 'TextureVertex',
      slots: ['VertexInfo', 'JointMatrices'],
    );
    fragmentShader = FragmentShader.fromAsset(
      _bundle,
      entryPoint: multisampled
          ? 'ShadowDepthMsaaFragment'
          : 'ShadowDepthFragment',
      slots: ['albedoTexture', 'Material', if (multisampled) 'DepthSamples'],
    );
  }
  static const _bundle =
      'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle';
  static final _identity = Matrix4.identity();
  final SpatialPixelMaterial source;
  final bool multisampled;
  final origin = Vector3.zero();
  final _relativeModel = Matrix4.identity();
  static final _sampleOptions = Vector4(1, 0, 0, 0);

  @override
  void apply(covariant RenderContext3D context) {
    if (multisampled)
      fragmentShader.setVector4('DepthSamples.options', _sampleOptions);
    albedoColor = source.albedoColor;
    albedoTexture = source.albedoTexture;
    cullMode = source.cullMode;
    super.apply(context);
    if (origin.length2 > 0) {
      _relativeModel.setFrom(context.model);
      for (var axis = 0; axis < 3; axis++) {
        _relativeModel.setEntry(
          axis,
          3,
          context.model.entry(axis, 3) - origin[axis],
        );
      }
      vertexShader.setMatrix4('VertexInfo.model', _relativeModel);
    }
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
  _PointShadowDepthMaterial(super.source, {bool multisampled = false})
    : super(multisampled: multisampled) {
    vertexShader = VertexShader.fromAsset(
      _ShadowDepthMaterial._bundle,
      entryPoint: 'PointShadowVertex',
      slots: ['VertexInfo', 'JointMatrices', 'PointDepth'],
    );
    fragmentShader = FragmentShader.fromAsset(
      _ShadowDepthMaterial._bundle,
      entryPoint: multisampled
          ? 'PointShadowDepthMsaaFragment'
          : 'PointShadowDepthFragment',
      slots: [
        'albedoTexture',
        'Material',
        'PointDepth',
        if (multisampled) 'DepthSamples',
      ],
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
