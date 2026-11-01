import 'dart:typed_data';

import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/battle_stage_textured_quad.dart';

void main() {
  test('texture replacement also replaces the reset default without rebuilding geometry', () {
    final first = Texture(ByteData(16), width: 2, height: 2);
    final next = Texture(ByteData(16), width: 2, height: 2);
    final quad = BattleStageTexturedQuad(first);
    final firstMaterial = quad.material;
    final mesh = quad.mesh;
    final surface = mesh.mesh.surfaces.single;
    quad.setTexture(next);
    expect(quad.material, isNot(same(firstMaterial)));
    expect(quad.mesh, same(mesh));
    expect(quad.mesh.mesh.surfaces.single, same(surface));
    expect(surface.material, same(quad.material));
    expect(quad.material.albedoTexture, same(next));
    quad.material.resetAnimation();
    expect(quad.material.albedoTexture, same(next));
    expect(quad.material.alphaMode, Model3dAlphaMode.blend);
    expect(quad.material.preserveUnlitColor, isTrue);
  });

  test('stable frames keep the same material, surface and mesh', () {
    final texture = Texture(ByteData(16), width: 2, height: 2);
    final quad = BattleStageTexturedQuad(texture);
    final material = quad.material;
    final mesh = quad.mesh;
    final surface = mesh.mesh.surfaces.single;
    for (var frame = 0; frame < 120; frame++) {
      quad.setTexture(texture);
      expect(quad.material, same(material));
      expect(quad.mesh, same(mesh));
      expect(quad.mesh.mesh.surfaces.single, same(surface));
    }
  });
}
