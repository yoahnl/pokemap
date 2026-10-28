import 'dart:typed_data';
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
import 'spatial_shadow_coverage.dart';
import 'spatial_point_shadow.dart';
import 'spatial_atmosphere.dart';
import 'spatial_presentation_effects.dart';
import 'spatial_weather_material.dart';

class SpatialRenderContext extends RenderContext3D
    implements
        SpatialLightingContext,
        SpatialAtmosphereContext,
        SpatialPresentationContext {
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
  bool shadowsEnabled = true;
  bool shadowAntialiasingEnabled = true;
  bool preferMultisampledShadows = true;
  bool shadowCoverageEnabled = true;
  @override
  SpatialPresentationProfile presentationProfile =
      SpatialPresentationProfile.disabled;
  @override
  bool depthFogEnabled = false;
  @override
  Color depthFogColor = spatialDepthFogColor(0);
  Iterable<Object3D> shadowCasters = const [];
  String? sourceInstanceId;
  String? sourceShadowId;
  Object? sourceModelOwner;
  SpatialShadowStats shadowStats = const SpatialShadowStats();
  SpatialShadowMap? _shadowMap;
  bool _collecting = false;
  int _hiddenDrawCount = 0;
  final _captured = <_TransparentSurface>[];
  final _casterSurfaces = <_TransparentSurface>[];
  bool _capturingShadowCasters = false;

  double weatherSkyFlash = 0;
  double weatherVeilOpacity = 0;
  int weatherDrawCount = 0;
  final _weather = <Surface>[];
  final _transparent = <_TransparentSurface>[];

  static final _staticJointTransform = Matrix4.identity();

  @override
  void applyMaterial(Material material) {
    if (material is UnlitMaterial &&
        material is! SpatialPixelMaterial &&
        jointsInfo.jointTransforms.isEmpty) {
      material.resource;
      material.vertexShader.setMatrix4(
        'JointMatrices.joints[0]',
        _staticJointTransform,
      );
    }
    if (material is SpatialPixelMaterial) material.prepareLighting(lighting);
    super.applyMaterial(material);
  }

  @override
  void drawSurface(Surface surface) {
    final material = surface.material;
    if (material is SpatialWeatherMaterial) {
      if (!_capturingShadowCasters) _weather.add(surface);
      return;
    }
    if (material is SpatialPixelMaterial) {
      if (lighting.hiddenMaterialsByInstance[sourceInstanceId]?.contains(
            material.sourceMaterialName,
          ) ==
          true) {
        if (!_capturingShadowCasters) _hiddenDrawCount++;
        return;
      }
      if (_capturingShadowCasters) {
        _casterSurfaces.add(
          _snapshot(surface, material, _casterSurfaces.length),
        );
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

  final _snapshots = <_TransparentSurface>[];
  int _snapshotCount = 0;
  final _snapshotCenter = Vector3.zero();

  _TransparentSurface _snapshot(
    Surface surface,
    SpatialPixelMaterial material,
    int sequence,
  ) {
    surface.aabb.copyCenter(_snapshotCenter);
    model.transform3(_snapshotCenter);
    view.transform3(_snapshotCenter);
    if (_snapshotCount == _snapshots.length) {
      _snapshots.add(_TransparentSurface());
    }
    final joints = jointsInfo.jointTransforms;
    final entry = _snapshots[_snapshotCount++]
      .._surface = surface
      .._material = material
      ..joints = joints.isEmpty
          ? const []
          : [for (final joint in joints) joint.clone()]
      ..depth = -_snapshotCenter.z
      ..sequence = sequence
      ..instanceId = sourceInstanceId
      ..shadowId = sourceShadowId
      ..owner = sourceModelOwner;
    entry.pose.capture(material);
    entry.model.setFrom(model);
    entry.worldBounds
      ..copyFrom(surface.aabb)
      ..transform(model);
    return entry;
  }

  void _releaseSnapshots() {
    for (var index = 0; index < _snapshotCount; index++) {
      _snapshots[index].release();
    }
    _snapshotCount = 0;
  }

  @override
  void flush() {
    final shadow = lighting.enabled && shadowsEnabled ? lighting.shadow : null;
    final hasPointShadows =
        lighting.enabled &&
        shadowsEnabled &&
        pointLightShadowsEnabled &&
        lighting.pointShadowCasterInstanceIds.isNotEmpty &&
        lighting.pointLights.any((light) => light.intensity > 0);
    shadowFrame = null;
    pointShadowFrame = null;
    _hiddenDrawCount = 0;
    weatherDrawCount = 0;
    try {
      _collecting = shadow != null || hasPointShadows;
      super.flush();
      _collecting = false;
      if ((shadow != null || hasPointShadows) && shadowCasters.isNotEmpty) {
        final previousModel = model.clone();
        final previousJoints = jointsInfo.jointTransforms;
        try {
          _capturingShadowCasters = true;
          for (final caster in shadowCasters) {
            caster.draw(this);
          }
        } finally {
          _capturingShadowCasters = false;
          model.setFrom(previousModel);
          jointsInfo.jointTransforms = previousJoints;
        }
      }
      final casterSurfaces = shadowCasters.isEmpty
          ? _captured
          : _casterSurfaces;
      var casterDrawCount = 0;
      var pointCasterDrawCount = 0;
      if (shadow != null) {
        final coverage = shadowCoverageEnabled
            ? SpatialShadowCoverage(
                resolution: shadow.resolution,
                filterRadius: shadow.filterRadius,
              )
            : null;
        final worldToLight = spatialShadowProjection(
          shadow,
          lighting.sunDirection,
        ).viewProjection;
        final map = _shadowMap ??= SpatialShadowMap(
          device.backend,
          ownsFrame: false,
        );
        shadowFrame = map.render(
          shadow,
          lighting.sunDirection,
          (context, depthMaterial) {
            for (final entry in casterSurfaces) {
              if (!(shadow.casterInstanceIds.contains(entry.instanceId) ||
                      shadow.casterInstanceIds.contains(entry.shadowId)) ||
                  entry.material.alphaMode == Model3dAlphaMode.blend ||
                  entry.material.lightingRole !=
                      SpatialPixelLightingRole.surface ||
                  !spatialShadowIntersectsBounds(
                    worldToLight,
                    entry.worldBounds,
                  ))
                continue;
              if (entry.joints.isEmpty) {
                coverage?.add(worldToLight, entry.worldBounds);
              } else {
                coverage?.fill();
              }
              _drawShadowCaster(entry, context, depthMaterial);
              casterDrawCount++;
            }
          },
          antialiasing: shadowAntialiasingEnabled,
          preferMultisampling: preferMultisampledShadows,
          coverage: coverage,
        );
      }
      if (hasPointShadows) {
        final candidates = casterSurfaces
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
          pointShadowFrame = map.renderPointLights(
            lighting.pointLights,
            (context, depthMaterial, light) {
              final worldToClip = context.projection * context.view;
              for (final entry in candidates) {
                if (!spatialPointShadowIntersects(light, entry.worldBounds) ||
                    entry.joints.isEmpty &&
                        !spatialPointShadowIntersectsFace(
                          worldToClip,
                          entry.worldBounds,
                        ))
                  continue;
                _drawShadowCaster(entry, context, depthMaterial);
                pointCasterDrawCount++;
              }
            },
            antialiasing: shadowAntialiasingEnabled,
            preferMultisampling: preferMultisampledShadows,
          );
        }
      }
      _replayCaptured();
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
      if (_transparent.isEmpty) {
        _drawWeather();
        return;
      }
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
      _drawWeather();
    } finally {
      _weather.clear();
      _collecting = false;
      _capturingShadowCasters = false;
      _captured.clear();
      _casterSurfaces.clear();
      _transparent.clear();
      _releaseSnapshots();
    }
  }

  int instancedDrawCount = 0;
  final _instanceGroups = <Surface, _InstanceGroup>{};
  final _instanceGroupPool = <_InstanceGroup>[];
  Float32List _instanceData = Float32List(1024);

  void _replayCaptured() {
    instancedDrawCount = 0;
    final instancing = device.supportsInstancing;
    for (final entry in _captured) {
      if (instancing && _instanceable(entry)) {
        final group = _instanceGroups[entry.surface] ??= _takeGroup();
        if (group.entries.isEmpty || group.accepts(entry)) {
          group.entries.add(entry);
          continue;
        }
      }
      _withPose(entry, () => drawSurface(entry.surface));
    }
    for (final group in _instanceGroups.values) {
      if (group.entries.length == 1) {
        final entry = group.entries.single;
        _withPose(entry, () => drawSurface(entry.surface));
      } else {
        _drawInstanced(group.entries);
      }
      group.entries.clear();
      _instanceGroupPool.add(group);
    }
    _instanceGroups.clear();
  }

  _InstanceGroup _takeGroup() => _instanceGroupPool.isEmpty
      ? _InstanceGroup()
      : _instanceGroupPool.removeLast();

  bool _instanceable(_TransparentSurface entry) {
    final material = entry.material;
    return material.instanceable &&
        entry.joints.isEmpty &&
        entry.surface.jointMap == null &&
        !atmosphereProfile.targetsMaterial(material.sourceMaterialName);
  }

  void _drawInstanced(List<_TransparentSurface> entries) {
    final first = entries.first;
    final material = first.material;
    material.prepareLighting(lighting);
    final pipeline = material.instancedPipeline();
    if (pipeline == null) {
      for (final entry in entries) {
        _withPose(entry, () => drawSurface(entry.surface));
      }
      return;
    }
    final floats = entries.length * 16;
    if (_instanceData.length < floats) _instanceData = Float32List(floats * 2);
    for (var index = 0; index < entries.length; index++) {
      _instanceData.setRange(
        index * 16,
        index * 16 + 16,
        entries[index].model.storage,
      );
    }
    _withPose(first, () {
      device
        ..clearBindings()
        ..bindPipeline(pipeline, material.cullMode);
      material.vertexShader.resource;
      material.apply(this);
      material.bindInstancedVertex(this);
      material.fragmentShader.bind(device);
      device.bindInstancedGeometry(
        first.surface,
        ByteData.sublistView(_instanceData, 0, floats),
        entries.length,
      );
      instancedDrawCount++;
    });
  }

  void _drawWeather() {
    for (final surface in _weather) {
      super.drawSurface(surface);
      weatherDrawCount++;
    }
  }

  void _drawShadowCaster(
    _TransparentSurface entry,
    RenderContext3D context,
    Material Function(SpatialPixelMaterial) depthMaterial,
  ) {
    final previousPose = entry.pose.matches(entry.material)
        ? null
        : _MaterialPose(entry.material);
    final previousMaterial = entry.surface.material;
    try {
      if (previousPose != null) entry.pose.apply(entry.material);
      entry.surface.material = entry.material;
      context.model.setFrom(entry.model);
      context.jointsInfo.jointTransforms = entry.joints;
      final material = depthMaterial(entry.material)
        ..cullMode = entry.pose.cullMode;
      context.device.clearBindings();
      context.applyMaterial(material);
      context.device.bindGeometry(entry.surface);
    } finally {
      previousPose?.apply(entry.material);
      entry.surface.material = previousMaterial;
    }
  }

  final _poseModels = <Matrix4>[];
  int _poseDepth = 0;

  void _withPose(_TransparentSurface entry, void Function() draw) {
    final previousPose = entry.pose.matches(entry.material)
        ? null
        : _MaterialPose(entry.material);
    final previousMaterial = entry.surface.material;
    if (_poseDepth == _poseModels.length) _poseModels.add(Matrix4.zero());
    final previousModel = _poseModels[_poseDepth++]..setFrom(model);
    final previousJoints = jointsInfo.jointTransforms;
    final previousInstance = sourceInstanceId;
    final previousShadow = sourceShadowId;
    final previousOwner = sourceModelOwner;
    try {
      if (previousPose != null) entry.pose.apply(entry.material);
      entry.surface.material = entry.material;
      model.setFrom(entry.model);
      jointsInfo.jointTransforms = entry.joints;
      sourceInstanceId = entry.instanceId;
      sourceShadowId = entry.shadowId;
      sourceModelOwner = entry.owner;
      draw();
    } finally {
      previousPose?.apply(entry.material);
      entry.surface.material = previousMaterial;
      model.setFrom(previousModel);
      _poseDepth--;
      jointsInfo.jointTransforms = previousJoints;
      sourceInstanceId = previousInstance;
      sourceShadowId = previousShadow;
      sourceModelOwner = previousOwner;
    }
  }
}

final class _InstanceGroup {
  final entries = <_TransparentSurface>[];

  bool accepts(_TransparentSurface entry) {
    final first = entries.first;
    return identical(first.material, entry.material) &&
        first.pose.sameAs(entry.pose);
  }
}

final class _TransparentSurface {
  Surface? _surface;
  SpatialPixelMaterial? _material;
  final pose = _MaterialPose.empty();
  final model = Matrix4.zero();
  List<Matrix4> joints = const [];
  double depth = 0;
  int sequence = 0;
  String? instanceId;
  String? shadowId;
  Object? owner;
  final worldBounds = Aabb3();

  Surface get surface => _surface!;
  SpatialPixelMaterial get material => _material!;

  void release() {
    _surface = null;
    _material = null;
    joints = const [];
    instanceId = null;
    shadowId = null;
    owner = null;
    pose.release();
  }
}

final class _MaterialPose {
  _MaterialPose(SpatialPixelMaterial material) {
    capture(material);
  }

  _MaterialPose.empty();

  Texture? _texture;
  Color color = const Color(0x00000000);
  final rect = Vector4.zero(), u = Vector4.zero(), v = Vector4.zero();
  int wrapS = 0, wrapT = 0;
  CullMode cullMode = CullMode.none;
  Vector3? shadowSamplePosition;
  Vector3? _sample;

  Texture get texture => _texture!;

  void capture(SpatialPixelMaterial material) {
    _texture = material.albedoTexture;
    color = material.albedoColor;
    rect.setFrom(material.uvRect);
    u.setFrom(material.uvTransformU);
    v.setFrom(material.uvTransformV);
    wrapS = material.activeWrapS;
    wrapT = material.activeWrapT;
    final sample = material.shadowSamplePosition;
    shadowSamplePosition = sample == null
        ? null
        : ((_sample ??= Vector3.zero())..setFrom(sample));
    cullMode = material.cullMode;
  }

  void release() {
    _texture = null;
    shadowSamplePosition = null;
  }

  bool sameAs(_MaterialPose other) {
    final sample = shadowSamplePosition,
        otherSample = other.shadowSamplePosition;
    return identical(_texture, other._texture) &&
        color == other.color &&
        cullMode == other.cullMode &&
        wrapS == other.wrapS &&
        wrapT == other.wrapT &&
        rect == other.rect &&
        u == other.u &&
        v == other.v &&
        (sample == null
            ? otherSample == null
            : otherSample != null && sample == otherSample);
  }

  bool matches(SpatialPixelMaterial material) {
    final sample = shadowSamplePosition,
        current = material.shadowSamplePosition;
    return identical(texture, material.albedoTexture) &&
        color == material.albedoColor &&
        cullMode == material.cullMode &&
        wrapS == material.activeWrapS &&
        wrapT == material.activeWrapT &&
        rect == material.uvRect &&
        u == material.uvTransformU &&
        v == material.uvTransformV &&
        (sample == null
            ? current == null
            : current != null && sample == current);
  }

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
        _uvIdentity,
        texture: texture,
        wrapModes: (wrapS: wrapS, wrapT: wrapT),
      );
    material.uvRect.setFrom(rect);
    material.uvTransformU.setFrom(u);
    material.uvTransformV.setFrom(v);
  }

  static const _uvIdentity = <double>[1, 0, 0, 1, 0, 0];
}
