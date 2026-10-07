import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';

class SpatialPixelMaterial extends UnlitMaterial {
  SpatialPixelMaterial(Texture texture) : super(albedoTexture: texture) {
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

  @override
  void apply(covariant RenderContext3D context) {
    super.apply(context);
    fragmentShader.setVector4('Material.uvRect', uvRect);
    fragmentShader.setVector2(
      'Material.textureDimensions',
      Vector2(albedoTexture.width.toDouble(), albedoTexture.height.toDouble()),
    );
  }
}
