import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_lighting_preview.dart';
import 'spatial_shadow_profile.dart';
import 'spatial_point_shadow.dart';
import 'spatial_atmosphere.dart';
import 'spatial_presentation_effects.dart';

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
    this.preserveUnlitColor = false,
    this.emissive = false,
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
      _shadowUniformsBound = false;
      _environmentUniformsBound = false;
      _pointShadowUniformsBound = false;
      _atmosphereUniformsBound = false;
      _presentationUniformsBound = false;
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
  final bool preserveUnlitColor;
  final bool emissive;
  Vector3? shadowSamplePosition;
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
  bool _shadowUniformsBound = false;
  SpatialShadowFrame? _boundShadowFrame;
  Shader? _shadowShader;
  GpuShader? _shadowResource;
  final _shadowOptions = Vector4.zero(), _shadowHeight = Vector4.zero();
  final _shadowSample = Vector4.zero();
  final _shadowOrigin = Vector4.zero();
  final _shadowCoverage = Vector4.zero();
  final _boundShadowSample = Vector3.zero();
  bool _boundUsesShadowSample = false;
  final _fireflyPositionRadius = List.generate(2, (_) => Vector4.zero());
  final _fireflyColorIntensity = List.generate(2, (_) => Vector4.zero());
  bool _environmentUniformsBound = false;
  SpatialLightingProfile? _boundEnvironmentLighting;
  Shader? _environmentShader;
  GpuShader? _environmentResource;
  final _environmentTint = Vector4.zero(), _environmentOptions = Vector4.zero();
  final _environmentSample = Vector4.zero();
  final _boundEnvironmentSample = Vector4.zero();
  final _pointPositionRadius = List.generate(4, (_) => Vector4.zero());
  final _pointColorIntensity = List.generate(4, (_) => Vector4.zero());
  bool _pointShadowUniformsBound = false;
  SpatialPointShadowFrame? _boundPointShadowFrame;
  Shader? _pointShadowShader;
  GpuShader? _pointShadowResource;
  final _pointShadowOptions = Vector4.zero();
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
        lighting.surfaceStrength > 0 &&
        !groundDepthOnly &&
        lightingRole == SpatialPixelLightingRole.surface;
    prepareLighting(lighting);
    super.apply(context);
    _applyLighting(lighting, enabled: enabled, normalLighting: normalLighting);
    _applyEnvironment(lighting);
    _applyAtmosphere(context);
    _applyPresentation(context);
    _applyPointShadow(
      context is SpatialLightingContext
          ? (context as SpatialLightingContext).pointShadowFrame
          : null,
    );
    final frame = context is SpatialLightingContext
        ? (context as SpatialLightingContext).shadowFrame
        : null;
    _applyShadow(
      enabled &&
              (lightingRole == SpatialPixelLightingRole.ground ||
                  lightingRole == SpatialPixelLightingRole.actor &&
                      frame?.profile.actorReceivers == true &&
                      shadowSamplePosition != null)
          ? frame
          : null,
    );
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
    fragmentShader.setFloat(
      'Material.alphaMode',
      preserveUnlitColor
          ? 4
          : switch (alphaMode) {
              null => 0,
              Model3dAlphaMode.opaque => 1,
              Model3dAlphaMode.mask => 2,
              Model3dAlphaMode.blend => 3,
            },
    );
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

  bool _atmosphereUniformsBound = false;
  final _fogColor = Vector4.zero(), _fogDepth = Vector4.zero();
  final _boundFogColor = Vector4.zero(), _boundFogDepth = Vector4.zero();
  bool _presentationUniformsBound = false;
  Shader? _presentationShader;
  GpuShader? _presentationResource;
  void _applyPresentation(RenderContext3D context) {
    final presentation = context is SpatialPresentationContext
        ? context as SpatialPresentationContext
        : null;
    final profile = presentation?.presentationProfile;
    final color = presentation?.depthFogColor;
    _fogColor.setValues(
      color?.r ?? 0,
      color?.g ?? 0,
      color?.b ?? 0,
      presentation?.depthFogEnabled == true ? profile!.fogOpacity : 0,
    );
    _fogDepth.setValues(profile?.fogStart ?? 0, profile?.fogEnd ?? 1, 0, 0);
    final shader = fragmentShader, resource = shader.resource;
    if (_presentationUniformsBound &&
        identical(_presentationShader, shader) &&
        identical(_presentationResource, resource) &&
        _boundFogColor == _fogColor &&
        _boundFogDepth == _fogDepth)
      return;
    shader
      ..setVector4('Presentation.fogColor', _fogColor)
      ..setVector4('Presentation.depthRange', _fogDepth);
    _presentationUniformsBound = true;
    _presentationShader = shader;
    _presentationResource = resource;
    _boundFogColor.setFrom(_fogColor);
    _boundFogDepth.setFrom(_fogDepth);
  }

  Shader? _atmosphereShader;
  GpuShader? _atmosphereResource;
  SpatialWindowGlow? _boundWindow;
  final _boundAtmosphereOptions = Vector4.zero();
  final _boundAtmosphereColor = Vector4.zero();
  final _atmosphereOptions = Vector4.zero();
  final _atmosphereColor = Vector4.zero();
  final _atmosphereMask = List.generate(8, (_) => Vector4.zero());
  void _applyAtmosphere(RenderContext3D context) {
    final atmosphere = context is SpatialAtmosphereContext
        ? context as SpatialAtmosphereContext
        : null;
    final profile = atmosphere?.atmosphereProfile;
    final instance = atmosphere?.sourceInstanceId;
    final water =
        atmosphere?.waterAnimated == true &&
        profile?.isWater(instance, sourceMaterialName) == true;
    final window = atmosphere?.windowsLit == true
        ? profile?.window(instance, sourceMaterialName)
        : null;
    _atmosphereOptions.setValues(
      water ? profile!.waterStrength : 0,
      water ? atmosphere!.atmosphereElapsedSeconds * profile!.waterSpeed : 0,
      emissive ? 1 : 0,
      window?.uvRects.length.toDouble() ?? 0,
    );
    final color = window?.color;
    _atmosphereColor.setValues(
      color?.r ?? 0,
      color?.g ?? 0,
      color?.b ?? 0,
      (window?.strength ?? 0) *
          (profile?.windowStrength ?? 1) *
          (atmosphere?.atmosphereNight ?? 0),
    );
    final shader = fragmentShader, resource = shader.resource;
    if (_atmosphereUniformsBound &&
        identical(_atmosphereShader, shader) &&
        identical(_atmosphereResource, resource) &&
        identical(_boundWindow, window) &&
        _boundAtmosphereOptions == _atmosphereOptions &&
        _boundAtmosphereColor == _atmosphereColor)
      return;
    final masksChanged =
        !_atmosphereUniformsBound ||
        !identical(_atmosphereShader, shader) ||
        !identical(_atmosphereResource, resource) ||
        !identical(_boundWindow, window);
    fragmentShader
      ..setVector4('Atmosphere.options', _atmosphereOptions)
      ..setVector4('Atmosphere.windowColor', _atmosphereColor);
    for (var i = 0; masksChanged && i < 8; i++) {
      final rect = window != null && i < window.uvRects.length
          ? window.uvRects[i]
          : null;
      _atmosphereMask[i].setValues(
        rect?.left ?? 0,
        rect?.top ?? 0,
        rect?.right ?? 0,
        rect?.bottom ?? 0,
      );
      fragmentShader.setVector4(
        'Atmosphere.windowRects[$i]',
        _atmosphereMask[i],
      );
    }
    _atmosphereUniformsBound = true;
    _atmosphereShader = shader;
    _atmosphereResource = resource;
    _boundWindow = window;
    _boundAtmosphereOptions.setFrom(_atmosphereOptions);
    _boundAtmosphereColor.setFrom(_atmosphereColor);
  }

  void prepareLighting(SpatialLightingProfile lighting) {
    final normalLighting =
        lighting.enabled &&
        lighting.surfaceStrength > 0 &&
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
        : lighting.surfaceStrength;
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

  void _applyPointShadow(SpatialPointShadowFrame? frame) {
    final shader = fragmentShader, resource = shader.resource;
    if (_pointShadowUniformsBound &&
        identical(_boundPointShadowFrame, frame) &&
        identical(_pointShadowShader, shader) &&
        identical(_pointShadowResource, resource))
      return;
    _pointShadowOptions.setValues(
      frame == null
          ? 0
          : (frame.supersampled
                ? 3
                : frame.samples > 1
                ? 2
                : 1),
      frame?.faceResolution.toDouble() ?? 1,
      frame?.lightCount.toDouble() ?? 1,
      .02,
    );
    shader
      ..setTexture('pointShadowTexture', frame?.texture ?? Texture.standard)
      ..setVector4('PointShadows.options', _pointShadowOptions);
    _boundPointShadowFrame = frame;
    _pointShadowShader = shader;
    _pointShadowResource = resource;
    _pointShadowUniformsBound = true;
  }

  void _applyEnvironment(SpatialLightingProfile lighting) {
    final shader = fragmentShader, resource = shader.resource;
    final sample = lightingRole == SpatialPixelLightingRole.actor
        ? shadowSamplePosition
        : null;
    _environmentSample.setValues(
      sample?.x ?? 0,
      sample?.y ?? 0,
      sample?.z ?? 0,
      sample == null ? 0 : 1,
    );
    if (_environmentUniformsBound &&
        identical(_boundEnvironmentLighting, lighting) &&
        _boundEnvironmentSample == _environmentSample &&
        identical(_environmentShader, shader) &&
        identical(_environmentResource, resource))
      return;
    final tint = lighting.sceneTint;
    _environmentTint.setValues(tint.r, tint.g, tint.b, 1);
    _environmentOptions.setValues(
      lighting.enabled ? 1 : 0,
      lighting.pointLights.length.toDouble(),
      lighting.fireflyLights.length.toDouble(),
      0,
    );
    shader
      ..setVector4('Environment.tint', _environmentTint)
      ..setVector4('Environment.options', _environmentOptions)
      ..setVector4('Environment.samplePosition', _environmentSample);
    for (var index = 0; index < 4; index++) {
      final light = index < lighting.pointLights.length
          ? lighting.pointLights[index]
          : null;
      final position = light?.position;
      _pointPositionRadius[index].setValues(
        position?.x ?? 0,
        position?.y ?? 0,
        position?.z ?? 0,
        light?.radius ?? 1,
      );
      final color = light?.color;
      _pointColorIntensity[index].setValues(
        color?.r ?? 0,
        color?.g ?? 0,
        color?.b ?? 0,
        light?.intensity ?? 0,
      );
      shader
        ..setVector4(
          'Environment.pointPositionRadius[$index]',
          _pointPositionRadius[index],
        )
        ..setVector4(
          'Environment.pointColorIntensity[$index]',
          _pointColorIntensity[index],
        );
    }
    for (var index = 0; index < 2; index++) {
      final light = index < lighting.fireflyLights.length
          ? lighting.fireflyLights[index]
          : null;
      final position = light?.position, color = light?.color;
      _fireflyPositionRadius[index].setValues(
        position?.x ?? 0,
        position?.y ?? 0,
        position?.z ?? 0,
        light?.radius ?? 1,
      );
      _fireflyColorIntensity[index].setValues(
        color?.r ?? 0,
        color?.g ?? 0,
        color?.b ?? 0,
        light?.intensity ?? 0,
      );
      shader
        ..setVector4(
          'Environment.fireflyPositionRadius[$index]',
          _fireflyPositionRadius[index],
        )
        ..setVector4(
          'Environment.fireflyColorIntensity[$index]',
          _fireflyColorIntensity[index],
        );
    }
    _boundEnvironmentLighting = lighting;
    _boundEnvironmentSample.setFrom(_environmentSample);
    _environmentShader = shader;
    _environmentResource = resource;
    _environmentUniformsBound = true;
  }

  void _applyShadow(SpatialShadowFrame? frame) {
    final shader = fragmentShader, resource = fragmentShader.resource;
    final sample =
        frame != null && lightingRole == SpatialPixelLightingRole.actor
        ? shadowSamplePosition
        : null;
    final usesSample = sample != null;
    if (_shadowUniformsBound &&
        identical(_boundShadowFrame, frame) &&
        _boundUsesShadowSample == usesSample &&
        (sample == null || _boundShadowSample == sample) &&
        identical(_shadowShader, shader) &&
        identical(_shadowResource, resource))
      return;
    final profile = frame?.profile;
    _shadowOptions.setValues(
      frame == null
          ? 0
          : (frame.supersampled
                ? 3
                : frame.samples > 1
                ? 2
                : 1),
      profile?.bias ?? 0,
      profile?.resolution.toDouble() ?? 1,
      profile?.opacity ?? 0,
    );
    _shadowHeight.setValues(
      profile?.receiverMinY ?? 0,
      profile?.receiverMaxY ?? 0,
      profile?.filterRadius ?? 1,
      0,
    );
    _shadowSample.setValues(
      sample?.x ?? 0,
      sample?.y ?? 0,
      sample?.z ?? 0,
      usesSample ? 1 : 0,
    );
    shader
      ..setTexture('shadowTexture', frame?.texture ?? Texture.standard)
      ..setMatrix4(
        'Shadow.worldToLight',
        frame?.relativeWorldToLight ?? frame?.worldToLight ?? _identityJoint,
      )
      ..setVector4('Shadow.options', _shadowOptions)
      ..setVector4('Shadow.receiverHeight', _shadowHeight)
      ..setVector4('Shadow.samplePosition', _shadowSample)
      ..setVector4(
        'Shadow.coverage',
        _shadowCoverage..setValues(
          frame?.coverage.a.toDouble() ?? 65535,
          frame?.coverage.b.toDouble() ?? 65535,
          frame?.coverage.c.toDouble() ?? 65535,
          frame?.coverage.d.toDouble() ?? 65535,
        ),
      )
      ..setVector4(
        'Shadow.origin',
        _shadowOrigin..setValues(
          frame?.origin.x ?? 0,
          frame?.origin.y ?? 0,
          frame?.origin.z ?? 0,
          0,
        ),
      );
    _boundShadowFrame = frame;
    _shadowShader = shader;
    _shadowResource = resource;
    _boundUsesShadowSample = usesSample;
    if (sample != null) _boundShadowSample.setFrom(sample);
    _shadowUniformsBound = true;
  }
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
        slots: [
          'albedoTexture',
          'Material',
          'shadowTexture',
          'Shadow',
          'Environment',
          'pointShadowTexture',
          'PointShadows',
          'Atmosphere',
          'Presentation',
        ],
      );

  final void Function() _onCreate;

  @override
  GpuShader createResource() {
    _onCreate();
    return super.createResource();
  }
}
