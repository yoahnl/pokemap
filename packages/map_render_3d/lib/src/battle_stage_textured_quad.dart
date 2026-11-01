import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';

final class BattleStageTexturedQuad {
  BattleStageTexturedQuad(Texture texture) : _texture = texture {
    material = _material(texture);
    mesh = MeshComponent(
      mesh: Mesh()
        ..addSurface(
          Surface(
            vertices: [
              Vertex(position: Vector3(-.5, 0, 0), texCoord: Vector2(0, 1)),
              Vertex(position: Vector3(.5, 0, 0), texCoord: Vector2(1, 1)),
              Vertex(position: Vector3(.5, 1, 0), texCoord: Vector2(1, 0)),
              Vertex(position: Vector3(-.5, 1, 0), texCoord: Vector2(0, 0)),
            ],
            indices: [0, 1, 2, 2, 3, 0],
            material: material,
          ),
        ),
    );
  }

  Texture _texture;
  late final MeshComponent mesh;
  late SpatialPixelMaterial material;

  void setTexture(Texture texture) {
    if (identical(_texture, texture)) return;
    _texture = texture;
    material = _material(texture);
    mesh.mesh.surfaces.single.material = material;
  }

  static SpatialPixelMaterial _material(Texture texture) =>
      SpatialPixelMaterial(
        texture,
        lightingRole: SpatialPixelLightingRole.actor,
        alphaMode: Model3dAlphaMode.blend,
        preserveUnlitColor: true,
      );
}
