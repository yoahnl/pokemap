import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

class SpatialPixelMaterial extends UnlitMaterial {
  SpatialPixelMaterial(
    Texture texture, {
    this.alphaMode,
    this.alphaCutoff = .1,
    this.wrapS = 10497,
    this.wrapT = 10497,
    this.groundDepthOnly = false,
  }) : _defaultAlbedoTexture = texture,
       _activeWrapS = wrapS,
       _activeWrapT = wrapT,
       super(albedoTexture: texture) {
    if (![10497, 33648, 33071].contains(wrapS) ||
        ![10497, 33648, 33071].contains(wrapT) ||
        (alphaMode == Model3dAlphaMode.mask && alphaCutoff != .5)) {
      throw const FormatException('Unsupported pixel material profile.');
    }
    vertexShader = _PixelVertexShader(
      () => _identityJointBound = false,
      groundDepthOnly: groundDepthOnly,
    );
    fragmentShader = _PixelFragmentShader(() => _uniformsBound = false);
  }

  final uvRect = Vector4(0, 0, 1, 1);
  final uvTransformU = Vector4(1, 0, 0, 0);
  final uvTransformV = Vector4(0, 1, 0, 0);
  final Texture _defaultAlbedoTexture;
  final Model3dAlphaMode? alphaMode;
  final double alphaCutoff;
  final int wrapS, wrapT;
  final bool groundDepthOnly;
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
    super.apply(context);
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

  static final _identityJoint = Matrix4.identity();
}

class _PixelVertexShader extends VertexShader {
  _PixelVertexShader(this._onCreate, {required bool groundDepthOnly})
    : super.fromAsset(
        'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle',
        entryPoint: groundDepthOnly ? 'GroundVertex' : 'TextureVertex',
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
