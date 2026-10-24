import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_lighting_preview.dart';

enum SpatialPixelLightingRole { surface, actor, ground }

class SpatialPixelMaterial extends UnlitMaterial {
  SpatialPixelMaterial(
    Texture texture, {
    this.alphaMode,
    this.alphaCutoff = .1,
    this.wrapS = 10497,
    this.wrapT = 10497,
    this.groundDepthOnly = false,
    this.lightingRole = SpatialPixelLightingRole.surface,
    this.sourceMaterialName,
  }) : _defaultAlbedoTexture = texture,
       _activeWrapS = wrapS,
       _activeWrapT = wrapT,
       super(albedoTexture: texture) {
    if (![10497, 33648, 33071].contains(wrapS) ||
        ![10497, 33648, 33071].contains(wrapT) ||
        (alphaMode == Model3dAlphaMode.mask && alphaCutoff != .5)) {
      throw const FormatException('Unsupported pixel material profile.');
    }
    vertexShader = _unlitVertexShader = _PixelVertexShader(
      () => _identityJointBound = false,
      groundDepthOnly: groundDepthOnly,
    );
    fragmentShader = _PixelFragmentShader(() {
      _uniformsBound = false;
      _lightingUniformsBound = false;
    });
  }

  final uvRect = Vector4(0, 0, 1, 1);
  final uvTransformU = Vector4(1, 0, 0, 0);
  final uvTransformV = Vector4(0, 1, 0, 0);
  final Texture _defaultAlbedoTexture;
  final Model3dAlphaMode? alphaMode;
  final double alphaCutoff;
  final int wrapS, wrapT;
  final bool groundDepthOnly;
  final SpatialPixelLightingRole lightingRole;
  final String? sourceMaterialName;
  late final VertexShader _unlitVertexShader;
  late final VertexShader _litVertexShader = _PixelVertexShader(
    () => _identityJointBound = false,
    groundDepthOnly: false,
    lit: true,
  );
  bool _normalLightingEnabled = false;
  bool _lightingUniformsBound = false;
  SpatialLightingProfile? _boundLighting;
  Shader? _lightingShader;
  GpuShader? _lightingResource;
  final _lightingAmbient = Vector4.zero();
  final _lightingSun = Vector4.zero();
  final _lightingDirection = Vector4.zero();
  final _lightingOptions = Vector4.zero();
  int _activeWrapS, _activeWrapT;
  int get activeWrapS => _activeWrapS;
  int get activeWrapT => _activeWrapT;
  bool _uniformsBound = false;
  bool _identityJointBound = false;
  Shader? _identityJointShader;
  GpuShader? _identityJointResource;
  Shader? _boundShader;
  GpuShader? _boundResource;
  final _boundUvRect = Vector4.zero();
  final _boundTransformU = Vector4.zero();
  final _boundTransformV = Vector4.zero();
  int _boundWidth = 0, _boundHeight = 0, _boundWrapS = 0, _boundWrapT = 0;

  void applyAnimation(
    List<double> transform, {
    Texture? texture,
    ({int wrapS, int wrapT})? wrapModes,
  }) {
    uvTransformU.setValues(transform[0], transform[2], transform[4], 0);
    uvTransformV.setValues(transform[1], transform[3], transform[5], 0);
    if (texture != null) albedoTexture = texture;
    _activeWrapS = wrapModes?.wrapS ?? wrapS;
    _activeWrapT = wrapModes?.wrapT ?? wrapT;
  }

  void resetAnimation() {
    uvTransformU.setValues(1, 0, 0, 0);
    uvTransformV.setValues(0, 1, 0, 0);
    albedoTexture = _defaultAlbedoTexture;
    _activeWrapS = wrapS;
    _activeWrapT = wrapT;
  }

  @override
  void apply(covariant RenderContext3D context) {
    final lighting = context is SpatialLightingContext
        ? (context as SpatialLightingContext).lighting
        : SpatialLightingProfile.disabled;
    final enabled =
        lighting.enabled &&
        !lighting.unlitMaterialNames.contains(sourceMaterialName);
    final normalLighting =
        enabled &&
        !groundDepthOnly &&
        lightingRole == SpatialPixelLightingRole.surface;
    prepareLighting(lighting);
    super.apply(context);
    _applyLighting(lighting, enabled: enabled, normalLighting: normalLighting);
    if (context.jointsInfo.jointTransforms.isEmpty) {
      final shader = vertexShader;
      final resource = shader.resource;
      if (!_identityJointBound ||
          !identical(_identityJointShader, shader) ||
          !identical(_identityJointResource, resource)) {
        shader.setMatrix4('JointMatrices.joints[0]', _identityJoint);
        _identityJointShader = shader;
        _identityJointResource = resource;
        _identityJointBound = true;
      }
    } else {
      _identityJointBound = false;
    }
    final shader = fragmentShader;
    final resource = shader.resource;
    if (_uniformsBound &&
        identical(_boundShader, shader) &&
        identical(_boundResource, resource) &&
        _boundUvRect == uvRect &&
        _boundTransformU == uvTransformU &&
        _boundTransformV == uvTransformV &&
        _boundWidth == albedoTexture.width &&
        _boundHeight == albedoTexture.height &&
        _boundWrapS == _activeWrapS &&
        _boundWrapT == _activeWrapT) {
      return;
    }
    fragmentShader.setVector4('Material.uvRect', uvRect);
    fragmentShader.setVector4('Material.uvTransformU', uvTransformU);
    fragmentShader.setVector4('Material.uvTransformV', uvTransformV);
    fragmentShader.setVector2(
      'Material.textureDimensions',
      Vector2(albedoTexture.width.toDouble(), albedoTexture.height.toDouble()),
    );
    fragmentShader.setVector2(
      'Material.wrapModes',
      Vector2(_activeWrapS.toDouble(), _activeWrapT.toDouble()),
    );
    fragmentShader.setFloat('Material.alphaMode', switch (alphaMode) {
      null => 0,
      Model3dAlphaMode.opaque => 1,
      Model3dAlphaMode.mask => 2,
      Model3dAlphaMode.blend => 3,
    });
    fragmentShader.setFloat('Material.alphaCutoff', alphaCutoff);
    _boundShader = shader;
    _boundResource = resource;
    _boundUvRect.setFrom(uvRect);
    _boundTransformU.setFrom(uvTransformU);
    _boundTransformV.setFrom(uvTransformV);
    _boundWidth = albedoTexture.width;
    _boundHeight = albedoTexture.height;
    _boundWrapS = _activeWrapS;
    _boundWrapT = _activeWrapT;
    _uniformsBound = true;
  }

  void prepareLighting(SpatialLightingProfile lighting) {
    final normalLighting =
        lighting.enabled &&
        !lighting.unlitMaterialNames.contains(sourceMaterialName) &&
        !groundDepthOnly &&
        lightingRole == SpatialPixelLightingRole.surface;
    if (normalLighting != _normalLightingEnabled) {
      vertexShader = normalLighting ? _litVertexShader : _unlitVertexShader;
      vertexShader.resource;
      _normalLightingEnabled = normalLighting;
    }
  }

  void _applyLighting(
    SpatialLightingProfile lighting, {
    required bool enabled,
    required bool normalLighting,
  }) {
    final shader = fragmentShader;
    final resource = shader.resource;
    if (_lightingUniformsBound &&
        identical(_boundLighting, lighting) &&
        identical(_lightingShader, shader) &&
        identical(_lightingResource, resource))
      return;
    final ambient = lighting.ambientColor, sun = lighting.sunColor;
    _lightingAmbient.setValues(
      ambient.r * lighting.ambientStrength,
      ambient.g * lighting.ambientStrength,
      ambient.b * lighting.ambientStrength,
      0,
    );
    _lightingSun.setValues(
      sun.r * lighting.sunStrength,
      sun.g * lighting.sunStrength,
      sun.b * lighting.sunStrength,
      0,
    );
    final direction = lighting.sunDirection;
    _lightingDirection.setValues(direction.x, direction.y, direction.z, 0);
    final strength =
        groundDepthOnly || lightingRole == SpatialPixelLightingRole.ground
        ? lighting.groundStrength
        : lightingRole == SpatialPixelLightingRole.actor
        ? lighting.actorStrength
        : 1.0;
    _lightingOptions.setValues(
      enabled ? 1 : 0,
      normalLighting ? 1 : 0,
      strength,
      0,
    );
    shader
      ..setVector4('Material.lightingAmbient', _lightingAmbient)
      ..setVector4('Material.lightingSun', _lightingSun)
      ..setVector4('Material.lightingDirection', _lightingDirection)
      ..setVector4('Material.lightingOptions', _lightingOptions);
    _boundLighting = lighting;
    _lightingShader = shader;
    _lightingResource = resource;
    _lightingUniformsBound = true;
  }

  static final _identityJoint = Matrix4.identity();
}

class _PixelVertexShader extends VertexShader {
  _PixelVertexShader(
    this._onCreate, {
    required bool groundDepthOnly,
    bool lit = false,
  }) : super.fromAsset(
         'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle',
         entryPoint: groundDepthOnly
             ? 'GroundVertex'
             : lit
             ? 'LitTextureVertex'
             : 'TextureVertex',
         slots: ['VertexInfo', 'JointMatrices'],
       );

  final void Function() _onCreate;

  @override
  GpuShader createResource() {
    _onCreate();
    return super.createResource();
  }
}

class _PixelFragmentShader extends FragmentShader {
  _PixelFragmentShader(this._onCreate)
    : super.fromAsset(
        'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle',
        slots: ['albedoTexture', 'Material'],
      );

  final void Function() _onCreate;

  @override
  GpuShader createResource() {
    _onCreate();
    return super.createResource();
  }
}
