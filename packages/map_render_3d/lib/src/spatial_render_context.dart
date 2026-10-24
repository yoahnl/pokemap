import 'dart:ui' show Color;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';
import 'spatial_lighting_preview.dart';
import 'spatial_shadow_profile.dart';
import 'spatial_shadow_map.dart';

class SpatialRenderContext extends RenderContext3D
    implements SpatialLightingContext {
  SpatialRenderContext(super.device);

  @override
  SpatialLightingProfile lighting = SpatialLightingProfile.disabled;
  @override
  SpatialShadowFrame? shadowFrame;
  String? sourceInstanceId;
  SpatialShadowStats shadowStats = const SpatialShadowStats();
  SpatialShadowMap? _shadowMap;
  bool _collecting = false;
  int _hiddenDrawCount = 0;
  final _captured = <_TransparentSurface>[];

  final _transparent = <_TransparentSurface>[];

  @override
  void applyMaterial(Material material) {
    if (material is SpatialPixelMaterial) material.prepareLighting(lighting);
    super.applyMaterial(material);
  }

  @override
  void drawSurface(Surface surface) {
    final material = surface.material;
    if (material is SpatialPixelMaterial) {
      if (lighting.hiddenMaterialsByInstance[sourceInstanceId]?.contains(
            material.sourceMaterialName,
          ) ==
          true) {
        _hiddenDrawCount++;
        return;
      }
      if (_collecting) {
        _captured.add(_snapshot(surface, material, _captured.length));
        return;
      }
    }
    if (material is! SpatialPixelMaterial ||
        material.alphaMode != Model3dAlphaMode.blend) {
      super.drawSurface(surface);
      return;
    }
    _transparent.add(_snapshot(surface, material, _transparent.length));
  }

  _TransparentSurface _snapshot(
    Surface surface,
    SpatialPixelMaterial material,
    int sequence,
  ) {
    final center = surface.aabb.center.clone();
    model.transform3(center);
    view.transform3(center);
    return _TransparentSurface(
      surface: surface,
      material: material,
      pose: _MaterialPose(material),
      model: model.clone(),
      joints: [for (final joint in jointsInfo.jointTransforms) joint.clone()],
      depth: -center.z,
      sequence: sequence,
      instanceId: sourceInstanceId,
    );
  }

  @override
  void flush() {
    final shadow = lighting.enabled ? lighting.shadow : null;
    shadowFrame = null;
    _hiddenDrawCount = 0;
    try {
      _collecting = shadow != null;
      super.flush();
      _collecting = false;
      var casterDrawCount = 0;
      if (shadow != null) {
        final map = _shadowMap ??= SpatialShadowMap(device.backend);
        shadowFrame = map.render(shadow, lighting.sunDirection, (
          context,
          depthMaterial,
        ) {
          for (final entry in _captured) {
            if (!shadow.casterInstanceIds.contains(entry.instanceId) ||
                entry.material.alphaMode == Model3dAlphaMode.blend ||
                entry.material.lightingRole != SpatialPixelLightingRole.surface)
              continue;
            _withPose(entry, () {
              context.model.setFrom(entry.model);
              context.jointsInfo.jointTransforms = entry.joints;
              final material = depthMaterial(entry.material)
                ..cullMode = entry.pose.cullMode;
              context.device.clearBindings();
              context.applyMaterial(material);
              context.device.bindGeometry(entry.surface);
              casterDrawCount++;
            });
          }
        });
        for (final entry in _captured) {
          _withPose(entry, () => drawSurface(entry.surface));
        }
      }
      shadowStats = SpatialShadowStats(
        casterDrawCount: casterDrawCount,
        receiverDrawCount: shadow == null
            ? 0
            : _captured
                  .where(
                    (entry) =>
                        entry.material.lightingRole ==
                        SpatialPixelLightingRole.ground,
                  )
                  .length,
        targetAllocations: _shadowMap?.targetAllocations ?? 0,
        hiddenDrawCount: _hiddenDrawCount,
      );
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
      _collecting = false;
      _captured.clear();
      _transparent.clear();
    }
  }

  void _withPose(_TransparentSurface entry, void Function() draw) {
    final previousPose = _MaterialPose(entry.material);
    final previousMaterial = entry.surface.material;
    final previousModel = model.clone();
    final previousJoints = jointsInfo.jointTransforms;
    final previousInstance = sourceInstanceId;
    try {
      entry.pose.apply(entry.material);
      entry.surface.material = entry.material;
      model.setFrom(entry.model);
      jointsInfo.jointTransforms = entry.joints;
      sourceInstanceId = entry.instanceId;
      draw();
    } finally {
      previousPose.apply(entry.material);
      entry.surface.material = previousMaterial;
      model.setFrom(previousModel);
      jointsInfo.jointTransforms = previousJoints;
      sourceInstanceId = previousInstance;
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
    required this.instanceId,
  });

  final Surface surface;
  final SpatialPixelMaterial material;
  final _MaterialPose pose;
  final Matrix4 model;
  final List<Matrix4> joints;
  final double depth;
  final int sequence;
  final String? instanceId;
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
