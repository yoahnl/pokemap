import 'dart:ui' show Color;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';

class SpatialRenderContext extends RenderContext3D {
  SpatialRenderContext(super.device);

  final _transparent = <_TransparentSurface>[];

  @override
  void drawSurface(Surface surface) {
    final material = surface.material;
    if (material is! SpatialPixelMaterial ||
        material.alphaMode != Model3dAlphaMode.blend) {
      super.drawSurface(surface);
      return;
    }
    final center = surface.aabb.center.clone();
    model.transform3(center);
    view.transform3(center);
    _transparent.add(
      _TransparentSurface(
        surface: surface,
        material: material,
        pose: _MaterialPose(material),
        model: model.clone(),
        joints: [for (final joint in jointsInfo.jointTransforms) joint.clone()],
        depth: -center.z,
        sequence: _transparent.length,
      ),
    );
  }

  @override
  void flush() {
    try {
      super.flush();
      if (_transparent.isEmpty) return;
      final previousModel = model.clone();
      final previousJoints = jointsInfo.jointTransforms;
      try {
        _transparent.sort((a, b) {
          final depth = b.depth.compareTo(a.depth);
          return depth == 0 ? a.sequence.compareTo(b.sequence) : depth;
        });
        for (final entry in _transparent) {
          final previousPose = _MaterialPose(entry.material);
          final previousMaterial = entry.surface.material;
          try {
            model.setFrom(entry.model);
            jointsInfo.jointTransforms = entry.joints;
            entry.surface.material = entry.material;
            entry.pose.apply(entry.material);
            super.drawSurface(entry.surface);
          } finally {
            entry.surface.material = previousMaterial;
            previousPose.apply(entry.material);
          }
        }
      } finally {
        model.setFrom(previousModel);
        jointsInfo.jointTransforms = previousJoints;
      }
    } finally {
      _transparent.clear();
    }
  }
}

final class _TransparentSurface {
  _TransparentSurface({
    required this.surface,
    required this.material,
    required this.pose,
    required this.model,
    required this.joints,
    required this.depth,
    required this.sequence,
  });

  final Surface surface;
  final SpatialPixelMaterial material;
  final _MaterialPose pose;
  final Matrix4 model;
  final List<Matrix4> joints;
  final double depth;
  final int sequence;
}

final class _MaterialPose {
  _MaterialPose(SpatialPixelMaterial material)
    : texture = material.albedoTexture,
      color = material.albedoColor,
      rect = material.uvRect.clone(),
      u = material.uvTransformU.clone(),
      v = material.uvTransformV.clone(),
      wrapS = material.activeWrapS,
      wrapT = material.activeWrapT,
      cullMode = material.cullMode;

  final Texture texture;
  final Color color;
  final Vector4 rect, u, v;
  final int wrapS, wrapT;
  final CullMode cullMode;

  void apply(SpatialPixelMaterial material) {
    material
      ..albedoColor = color
      ..cullMode = cullMode
      ..applyAnimation(
        [u.x, v.x, u.y, v.y, u.z, v.z],
        texture: texture,
        wrapModes: (wrapS: wrapS, wrapT: wrapT),
      );
    material.uvRect.setFrom(rect);
    material.uvTransformU.setFrom(u);
    material.uvTransformV.setFrom(v);
  }
}
