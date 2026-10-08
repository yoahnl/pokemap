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
  }) : super(albedoTexture: texture) {
    if (![10497, 33648, 33071].contains(wrapS) ||
        ![10497, 33648, 33071].contains(wrapT) ||
        (alphaMode == Model3dAlphaMode.mask && alphaCutoff != .5)) {
      throw const FormatException('Unsupported pixel material profile.');
    }
    vertexShader = VertexShader.fromAsset(
      'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle',
      slots: ['VertexInfo', 'JointMatrices'],
    );
    fragmentShader = FragmentShader.fromAsset(
      'packages/map_render_3d/assets/shaders/pixel_material.shaderbundle',
      slots: ['albedoTexture', 'Material'],
    );
  }

  final uvRect = Vector4(0, 0, 1, 1);
  final Model3dAlphaMode? alphaMode;
  final double alphaCutoff;
  final int wrapS, wrapT;

  @override
  void apply(covariant RenderContext3D context) {
    super.apply(context);
    fragmentShader.setVector4('Material.uvRect', uvRect);
    fragmentShader.setVector2(
      'Material.textureDimensions',
      Vector2(albedoTexture.width.toDouble(), albedoTexture.height.toDouble()),
    );
    fragmentShader.setVector2(
      'Material.wrapModes',
      Vector2(wrapS.toDouble(), wrapT.toDouble()),
    );
    fragmentShader.setFloat(
      'Material.alphaMode',
      alphaMode == null
          ? 0
          : alphaMode == Model3dAlphaMode.opaque
          ? 1
          : 2,
    );
    fragmentShader.setFloat('Material.alphaCutoff', alphaCutoff);
  }
}
