import 'dart:ui' show Color;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/components.dart' show Object3D;
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';
import 'spatial_lighting_preview.dart';
import 'spatial_shadow_profile.dart';
import 'spatial_shadow_map.dart';
import 'spatial_point_shadow.dart';
import 'spatial_atmosphere.dart';

class SpatialRenderContext extends RenderContext3D
    implements SpatialLightingContext, SpatialAtmosphereContext {
  SpatialRenderContext(super.device);

  @override
  SpatialLightingProfile lighting = SpatialLightingProfile.disabled;
  @override
  SpatialShadowFrame? shadowFrame;
  @override
  SpatialPointShadowFrame? pointShadowFrame;
  @override
  SpatialAtmosphereProfile atmosphereProfile =
      SpatialAtmosphereProfile.disabled;
  @override
  bool waterAnimated = false;
  @override
  bool windowsLit = false;
  @override
  double atmosphereElapsedSeconds = 0;
  @override
  double atmosphereNight = 0;
  bool pointLightShadowsEnabled = true;
  Iterable<Object3D> pointShadowCasters = const [];
  String? sourceInstanceId;
  String? sourceShadowId;
  SpatialShadowStats shadowStats = const SpatialShadowStats();
  SpatialShadowMap? _shadowMap;
  bool _collecting = false;
  int _hiddenDrawCount = 0;
  final _captured = <_TransparentSurface>[];
  final _pointCaptured = <_TransparentSurface>[];
  bool _capturingPointCasters = false;

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
        if (!_capturingPointCasters) _hiddenDrawCount++;
        return;
      }
      if (_capturingPointCasters) {
        _pointCaptured.add(_snapshot(surface, material, _pointCaptured.length));
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
      shadowId: sourceShadowId,
      worldBounds: Aabb3.copy(surface.aabb)..transform(model),
    );
  }

  @override
  void flush() {
    final shadow = lighting.enabled ? lighting.shadow : null;
    final hasPointShadows =
        lighting.enabled &&
        pointLightShadowsEnabled &&
        lighting.pointShadowCasterInstanceIds.isNotEmpty &&
        lighting.pointLights.any((light) => light.intensity > 0);
    shadowFrame = null;
    pointShadowFrame = null;
    _hiddenDrawCount = 0;
    try {
      _collecting = shadow != null || hasPointShadows;
      super.flush();
      _collecting = false;
      var casterDrawCount = 0;
      var pointCasterDrawCount = 0;
      if (shadow != null) {
        final map = _shadowMap ??= SpatialShadowMap(
          device.backend,
          ownsFrame: false,
        );
        shadowFrame = map.render(shadow, lighting.sunDirection, (
          context,
          depthMaterial,
        ) {
          for (final entry in _captured) {
            if (!(shadow.casterInstanceIds.contains(entry.instanceId) ||
                    shadow.casterInstanceIds.contains(entry.shadowId)) ||
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
      }
      if (hasPointShadows) {
        final previousModel = model.clone();
        final previousJoints = jointsInfo.jointTransforms;
        try {
          _capturingPointCasters = true;
          for (final caster in pointShadowCasters) {
            caster.draw(this);
          }
        } finally {
          _capturingPointCasters = false;
          model.setFrom(previousModel);
          jointsInfo.jointTransforms = previousJoints;
        }
        final candidates =
            (pointShadowCasters.isEmpty ? _captured : _pointCaptured)
                .where(
                  (entry) =>
                      (lighting.pointShadowCasterInstanceIds.contains(
                            entry.instanceId,
                          ) ||
                          lighting.pointShadowCasterInstanceIds.contains(
                            entry.shadowId,
                          )) &&
                      entry.material.alphaMode != Model3dAlphaMode.blend &&
                      entry.material.lightingRole ==
                          SpatialPixelLightingRole.surface,
                )
                .toList();
        if (candidates.any(
          (entry) => lighting.pointLights.any(
            (light) => spatialPointShadowIntersects(light, entry.worldBounds),
          ),
        )) {
          final map = _shadowMap ??= SpatialShadowMap(
            device.backend,
            ownsFrame: false,
          );
          pointShadowFrame = map.renderPointLights(lighting.pointLights, (
            context,
            depthMaterial,
            light,
          ) {
            for (final entry in candidates) {
              if (!spatialPointShadowIntersects(light, entry.worldBounds))
                continue;
              _withPose(entry, () {
                context.model.setFrom(entry.model);
                context.jointsInfo.jointTransforms = entry.joints;
                final material = depthMaterial(entry.material)
                  ..cullMode = entry.pose.cullMode;
                context.device.clearBindings();
                context.applyMaterial(material);
                context.device.bindGeometry(entry.surface);
                pointCasterDrawCount++;
              });
            }
          });
        }
      }
      for (final entry in _captured) {
        _withPose(entry, () => drawSurface(entry.surface));
      }
      shadowStats = SpatialShadowStats(
        casterDrawCount: casterDrawCount,
        receiverDrawCount: shadow == null
            ? 0
            : _captured
                  .where(
                    (entry) =>
                        entry.material.lightingRole ==
                            SpatialPixelLightingRole.ground ||
                        shadow.actorReceivers &&
                            entry.material.lightingRole ==
                                SpatialPixelLightingRole.actor &&
                            entry.pose.shadowSamplePosition != null,
                  )
                  .length,
        targetAllocations: _shadowMap?.targetAllocations ?? 0,
        hiddenDrawCount: _hiddenDrawCount,
        pointCasterDrawCount: pointCasterDrawCount,
        pointReceiverDrawCount: pointShadowFrame == null ? 0 : _captured.length,
        pointTargetAllocations: _shadowMap?.pointTargetAllocations ?? 0,
        pointShadowLightCount: pointShadowFrame?.lightCount ?? 0,
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
            final previousInstance = sourceInstanceId;
            try {
              sourceInstanceId = entry.instanceId;
              super.drawSurface(entry.surface);
            } finally {
              sourceInstanceId = previousInstance;
            }
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
      _capturingPointCasters = false;
      _captured.clear();
      _pointCaptured.clear();
      _transparent.clear();
    }
  }

  void _withPose(_TransparentSurface entry, void Function() draw) {
    final previousPose = _MaterialPose(entry.material);
    final previousMaterial = entry.surface.material;
    final previousModel = model.clone();
    final previousJoints = jointsInfo.jointTransforms;
    final previousInstance = sourceInstanceId;
    final previousShadow = sourceShadowId;
    try {
      entry.pose.apply(entry.material);
      entry.surface.material = entry.material;
      model.setFrom(entry.model);
      jointsInfo.jointTransforms = entry.joints;
      sourceInstanceId = entry.instanceId;
      sourceShadowId = entry.shadowId;
      draw();
    } finally {
      previousPose.apply(entry.material);
      entry.surface.material = previousMaterial;
      model.setFrom(previousModel);
      jointsInfo.jointTransforms = previousJoints;
      sourceInstanceId = previousInstance;
      sourceShadowId = previousShadow;
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
    required this.shadowId,
    required this.worldBounds,
  });

  final Surface surface;
  final SpatialPixelMaterial material;
  final _MaterialPose pose;
  final Matrix4 model;
  final List<Matrix4> joints;
  final double depth;
  final int sequence;
  final String? instanceId;
  final String? shadowId;
  final Aabb3 worldBounds;
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
      shadowSamplePosition = material.shadowSamplePosition?.clone(),
      cullMode = material.cullMode;

  final Texture texture;
  final Color color;
  final Vector4 rect, u, v;
  final int wrapS, wrapT;
  final CullMode cullMode;
  final Vector3? shadowSamplePosition;

  void apply(SpatialPixelMaterial material) {
    final sample = shadowSamplePosition;
    if (sample == null) {
      material.shadowSamplePosition = null;
    } else {
      (material.shadowSamplePosition ??= Vector3.zero()).setFrom(sample);
    }
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
