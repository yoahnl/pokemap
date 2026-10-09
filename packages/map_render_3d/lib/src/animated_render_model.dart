import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';

class AnimatedRenderModel extends Model {
  AnimatedRenderModel({
    required super.nodes,
    required super.animations,
    required this.materialAnimations,
    this.materialBindings = const {},
    this.textures = const [],
    this.textureWrapModes = const [],
  });

  final Model3dMaterialAnimations materialAnimations;
  final Map<int, List<SpatialPixelMaterial>> materialBindings;
  final List<Texture> textures;
  final List<({int wrapS, int wrapT})> textureWrapModes;

  int get animationCount => animations.length + materialAnimations.clips.length;

  String? animationName(int index) => index < animations.length
      ? animations[index].name
      : materialAnimations.clips[index - animations.length].name;

  void applyMaterialPose(
    Model3dMaterialAnimationClip? clip,
    double seconds, {
    required bool loop,
  }) {
    resetMaterialPose();
    if (clip == null) return;
    for (final track in clip.tracks) {
      final sample = track.sample(seconds, loop: loop);
      final textureIndex = sample.textureIndex;
      final texture = textureIndex == null ? null : textures[textureIndex];
      final wrapModes = textureIndex == null || textureWrapModes.isEmpty
          ? null
          : textureWrapModes[textureIndex];
      for (final material
          in materialBindings[track.materialIndex] ??
              const <SpatialPixelMaterial>[]) {
        material.applyAnimation(
          sample.transform,
          texture: texture,
          wrapModes: wrapModes,
        );
      }
    }
  }

  void resetMaterialPose() {
    for (final binding in materialBindings.values) {
      for (final material in binding) {
        material.resetAnimation();
      }
    }
  }
}
