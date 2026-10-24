import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'project_model3d.dart';
import 'spatial_day_night_cycle.dart';
import 'spatial_navigation.dart';
import 'smart_tile.dart';
import 'spatial_terrain_surface.dart';

enum ProjectDimension { twoD, threeD }

enum SpatialCameraMode { fixed }

enum SpatialCameraProjection { perspective, orthographic }

final class SpatialCameraProfile {
  SpatialCameraProfile({
    this.mode = SpatialCameraMode.fixed,
    this.projection = SpatialCameraProjection.perspective,
    this.pitchDegrees = 48.7,
    this.yawDegrees = 0,
    this.fieldOfViewDegrees = 16.2,
    this.distance = 42,
    this.orthographicHeight = 12,
  }) {
    if (!pitchDegrees.isFinite ||
        pitchDegrees <= 0 ||
        pitchDegrees >= 90 ||
        !yawDegrees.isFinite ||
        !fieldOfViewDegrees.isFinite ||
        fieldOfViewDegrees <= 1 ||
        fieldOfViewDegrees >= 120 ||
        !distance.isFinite ||
        distance <= 0 ||
        distance > 10000 ||
        !orthographicHeight.isFinite ||
        orthographicHeight <= 0 ||
        orthographicHeight > 10000) {
      throw const FormatException('Invalid spatial camera.');
    }
  }
  final SpatialCameraMode mode;
  final SpatialCameraProjection projection;
  final double pitchDegrees,
      yawDegrees,
      fieldOfViewDegrees,
      distance,
      orthographicHeight;
  static const orthographicCapabilityId = 'map3d.camera-orthographic@1';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialCameraProfile &&
          other.mode == mode &&
          other.projection == projection &&
          other.pitchDegrees == pitchDegrees &&
          other.yawDegrees == yawDegrees &&
          other.fieldOfViewDegrees == fieldOfViewDegrees &&
          other.distance == distance &&
          other.orthographicHeight == orthographicHeight;
  @override
  int get hashCode => Object.hash(
    mode,
    projection,
    pitchDegrees,
    yawDegrees,
    fieldOfViewDegrees,
    distance,
    orthographicHeight,
  );

  factory SpatialCameraProfile.fromJson(Map<String, dynamic> json) {
    final projectionName = json.containsKey('projection')
        ? json['projection']
        : SpatialCameraProjection.perspective.name;
    final projection = SpatialCameraProjection.values
        .where((value) => value.name == projectionName)
        .firstOrNull;
    if (projection == null) {
      throw const FormatException('Invalid spatial camera projection.');
    }
    if (projection == SpatialCameraProjection.orthographic &&
        !json.containsKey('orthographicHeight')) {
      throw const FormatException(
        'An orthographic camera requires its visible height.',
      );
    }
    final height = json.containsKey('orthographicHeight')
        ? json['orthographicHeight']
        : 12;
    if (height is! num) {
      throw const FormatException('Invalid spatial orthographic height.');
    }
    return SpatialCameraProfile(
      mode: SpatialCameraMode.values.byName(json['mode'] as String),
      projection: projection,
      pitchDegrees: (json['pitchDegrees'] as num).toDouble(),
      yawDegrees: (json['yawDegrees'] as num).toDouble(),
      fieldOfViewDegrees: (json['fieldOfViewDegrees'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      orthographicHeight: height.toDouble(),
    );
  }

  SpatialCameraProfile copyWith({
    SpatialCameraProjection? projection,
    double? pitchDegrees,
    double? yawDegrees,
    double? fieldOfViewDegrees,
    double? distance,
    double? orthographicHeight,
  }) => SpatialCameraProfile(
    mode: mode,
    projection: projection ?? this.projection,
    pitchDegrees: pitchDegrees ?? this.pitchDegrees,
    yawDegrees: yawDegrees ?? this.yawDegrees,
    fieldOfViewDegrees: fieldOfViewDegrees ?? this.fieldOfViewDegrees,
    distance: distance ?? this.distance,
    orthographicHeight: orthographicHeight ?? this.orthographicHeight,
  );
  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'projection': projection.name,
    'pitchDegrees': pitchDegrees,
    'yawDegrees': yawDegrees,
    'fieldOfViewDegrees': fieldOfViewDegrees,
    'distance': distance,
    'orthographicHeight': orthographicHeight,
  };
}

final class SpatialModelClip {
  SpatialModelClip({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  }) {
    if (![left, top, right, bottom].every((value) => value.isFinite) ||
        left >= right ||
        top >= bottom) {
      throw const FormatException(
        'Model clips require a finite non-empty XZ rectangle.',
      );
    }
  }

  factory SpatialModelClip.fromJson(Map<String, dynamic> json) {
    const fields = ['left', 'top', 'right', 'bottom'];
    if (json.length != fields.length ||
        fields.any((field) => json[field] is! num)) {
      throw const FormatException(
        'Model clips require exactly four numeric XZ coordinates.',
      );
    }
    return SpatialModelClip(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
    );
  }

  final double left, top, right, bottom;

  Map<String, dynamic> toJson() => {
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialModelClip &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}

final class SpatialModelInstance {
  SpatialModelInstance({
    required this.id,
    required this.modelId,
    required this.position,
    this.rotationDegrees = 0,
    this.scale = 1,
    this.animationIndex,
    this.animationLoop = true,
    this.animationSpeed = 1,
    this.blocksMovement = true,
    this.castsShadows,
    this.clip,
  }) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
        modelId.isEmpty ||
        !rotationDegrees.isFinite ||
        !scale.isFinite ||
        scale <= 0 ||
        scale > 1000 ||
        (animationIndex != null && animationIndex! < 0) ||
        !animationSpeed.isFinite ||
        animationSpeed <= 0 ||
        animationSpeed > 16 ||
        (clip != null && (animationIndex != null || blocksMovement))) {
      throw const FormatException('Invalid spatial model placement.');
    }
  }
  final String id, modelId;
  final Model3dVector3 position;
  final double rotationDegrees, scale;
  final int? animationIndex;
  final bool animationLoop;
  final double animationSpeed;
  final bool blocksMovement;
  final bool? castsShadows;
  final SpatialModelClip? clip;

  bool effectiveCastsShadows(ProjectModel3dEntry model) =>
      castsShadows ?? model.castsShadowsByDefault;
  Model3dVector3 get supportPosition {
    final clip = this.clip;
    if (clip == null) return position;
    final dx = clip.left / 2 + clip.right / 2;
    final dz = clip.top / 2 + clip.bottom / 2;
    final angle = rotationDegrees * math.pi / 180;
    return Model3dVector3(
      x: position.x + dx * math.cos(angle) + dz * math.sin(angle),
      y: position.y,
      z: position.z - dx * math.sin(angle) + dz * math.cos(angle),
    );
  }

  SpatialModelInstance copyWith({
    Model3dVector3? position,
    double? rotationDegrees,
    double? scale,
    bool? blocksMovement,
    bool? castsShadows,
    bool clearCastsShadows = false,
    int? animationIndex,
    bool clearAnimation = false,
    bool? animationLoop,
    double? animationSpeed,
    SpatialModelClip? clip,
    bool clearClip = false,
  }) => SpatialModelInstance(
    id: id,
    modelId: modelId,
    position: position ?? this.position,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    scale: scale ?? this.scale,
    animationIndex: clearAnimation
        ? null
        : animationIndex ?? this.animationIndex,
    animationLoop: animationLoop ?? this.animationLoop,
    animationSpeed: animationSpeed ?? this.animationSpeed,
    blocksMovement: blocksMovement ?? this.blocksMovement,
    castsShadows: clearCastsShadows ? null : castsShadows ?? this.castsShadows,
    clip: clearClip ? null : clip ?? this.clip,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialModelInstance &&
          other.id == id &&
          other.modelId == modelId &&
          other.position == position &&
          other.rotationDegrees == rotationDegrees &&
          other.scale == scale &&
          other.animationIndex == animationIndex &&
          other.animationLoop == animationLoop &&
          other.animationSpeed == animationSpeed &&
          other.blocksMovement == blocksMovement &&
          other.castsShadows == castsShadows &&
          other.clip == clip;
  @override
  int get hashCode => Object.hash(
    id,
    modelId,
    position,
    rotationDegrees,
    scale,
    animationIndex,
    animationLoop,
    animationSpeed,
    blocksMovement,
    castsShadows,
    clip,
  );

  factory SpatialModelInstance.fromJson(Map<String, dynamic> json) {
    if (json['castsShadows'] != null && json['castsShadows'] is! bool) {
      throw const FormatException(
        'Shadow casting override must be boolean or null.',
      );
    }
    return SpatialModelInstance(
      id: json['id'] as String,
      modelId: json['modelId'] as String,
      position: Model3dVector3.fromJson(
        Map<String, dynamic>.from(json['position'] as Map),
      ),
      rotationDegrees: (json['rotationDegrees'] as num).toDouble(),
      scale: (json['scale'] as num).toDouble(),
      animationIndex: json['animationIndex'] as int?,
      animationLoop: json['animationLoop'] as bool? ?? true,
      animationSpeed: (json['animationSpeed'] as num?)?.toDouble() ?? 1,
      blocksMovement: json['blocksMovement'] as bool,
      castsShadows: json['castsShadows'] as bool?,
      clip: switch (json['clip']) {
        null => null,
        Map<String, dynamic> value => SpatialModelClip.fromJson(value),
        _ => throw const FormatException(
          'Model clips require a rectangle object.',
        ),
      },
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'modelId': modelId,
    'position': position.toJson(),
    'rotationDegrees': rotationDegrees,
    'scale': scale,
    'animationIndex': animationIndex,
    'animationLoop': animationLoop,
    'animationSpeed': animationSpeed,
    'blocksMovement': blocksMovement,
    if (castsShadows != null) 'castsShadows': castsShadows,
    if (clip != null) 'clip': clip!.toJson(),
  };
}

final class MapSpatialScene {
  static const maximumTerrainLevel = maximumSpatialTerrainLevel;

  MapSpatialScene({
    required this.width,
    required this.depth,
    Iterable<int>? heightLevels,
    this.levelHeight = 1,
    this.cliffFrame,
    this.generateCliffs = true,
    Iterable<SpatialModelInstance> instances = const [],
    SpatialCameraProfile? camera,
    this.dayNightCycle,
    SpatialNavigationProfile? navigation,
    this.terrainSurfaces = const SpatialTerrainSurfaceSet.empty(),
  }) : heightLevels = List.unmodifiable(heightLevels ?? _flat(width, depth)),
       instances = List.unmodifiable(instances),
       camera = camera ?? SpatialCameraProfile(),
       navigation = navigation ?? SpatialNavigationProfile() {
    if (width <= 0 ||
        depth <= 0 ||
        width > 256 ||
        depth > 256 ||
        this.heightLevels.length != width * depth ||
        this.heightLevels.any((v) => v < 0 || v > maximumTerrainLevel) ||
        !levelHeight.isFinite ||
        levelHeight <= 0 ||
        levelHeight > 16 ||
        this.instances.length > 10000 ||
        this.instances.map((v) => v.id).toSet().length !=
            this.instances.length) {
      throw const FormatException(
        'Invalid spatial terrain dimensions, levels or instances.',
      );
    }
    if (this.navigation.spawn.x >= width ||
        this.navigation.spawn.z >= depth ||
        [
          ...this.navigation.ramps,
          ...this.navigation.blockedAreas,
        ].any((r) => r.x + r.width > width || r.z + r.depth > depth)) {
      throw const FormatException('Navigation must be inside the spatial map.');
    }
    if (terrainSurfaces.surfaces.any(
      (surface) => !surface.fits(width, depth),
    )) {
      throw const FormatException(
        'Continuous terrain surfaces must remain inside the spatial map.',
      );
    }
    for (final ledge in this.navigation.ledges) {
      if (ledge.x >= width ||
          ledge.z >= depth ||
          ledge.landingX < 0 ||
          ledge.landingZ < 0 ||
          ledge.landingX >= width ||
          ledge.landingZ >= depth ||
          worldHeightAt(ledge.landingX + .5, ledge.landingZ + .5) >
              worldHeightAt(ledge.x + .5, ledge.z + .5)) {
        throw const FormatException(
          'Ledge source and landing must be inside the map and descend.',
        );
      }
    }
    _validateRampContacts();
    final instancesById = {
      for (final instance in this.instances) instance.id: instance,
    };
    for (final ramp in this.navigation.ramps) {
      final surfaceId = ramp.surfaceInstanceId;
      if (surfaceId == null) continue;
      final surface = instancesById[surfaceId];
      if (surface == null) {
        throw const FormatException(
          'A ramp surface must reference an existing model instance.',
        );
      }
      if (surface.blocksMovement || surface.clip != null) {
        throw const FormatException('A ramp surface must allow movement.');
      }
    }
    for (final instance in this.instances) {
      final support = instance.supportPosition;
      if (support.x < 0 ||
          support.z < 0 ||
          support.x >= width ||
          support.z >= depth) {
        throw const FormatException('A spatial placement is outside the map.');
      }
    }
  }
  final int width, depth;
  final List<int> heightLevels;
  final double levelHeight;
  final SmartTileFrameRef? cliffFrame;
  final bool generateCliffs;
  final List<SpatialModelInstance> instances;
  final SpatialCameraProfile camera;
  final SpatialDayNightCycle? dayNightCycle;
  final SpatialNavigationProfile navigation;
  final SpatialTerrainSurfaceSet terrainSurfaces;
  late final double maximumWorldHeight = _maximumWorldHeight();

  double _maximumWorldHeight() {
    var maximum = 0.0;
    for (final level in heightLevels) {
      final height = level * levelHeight;
      if (height > maximum) maximum = height;
    }
    for (final ramp in navigation.ramps) {
      final height = ramp.highLevel * levelHeight;
      if (height > maximum) maximum = height;
    }
    for (final surface in terrainSurfaces.surfaces) {
      for (final footprint in surface.footprints) {
        for (final point in footprint.points) {
          final height =
              surface.height +
              surface.gradientX * point.x +
              surface.gradientZ * point.z;
          if (height > maximum) maximum = height;
        }
      }
    }
    return maximum;
  }

  double worldHeightAt(double x, double z, {String? excludingRampSurface}) {
    for (final ramp in navigation.ramps) {
      if (excludingRampSurface != null &&
          ramp.surfaceInstanceId == excludingRampSurface) {
        continue;
      }
      if (ramp.contains(x, z)) return ramp.levelAt(x, z) * levelHeight;
    }
    return terrainSurfaces.heightAt(x, z) ??
        heightAt(x.floor().clamp(0, width - 1), z.floor().clamp(0, depth - 1));
  }

  double heightAt(int x, int z) => heightLevels[z * width + x] * levelHeight;
  void _validateRampContacts() {
    for (final ramp in navigation.ramps) {
      if (ramp.surfaceInstanceId == null && !rampHasTerrainContacts(ramp)) {
        throw const FormatException(
          'A ramp must contact its low and high terrain levels.',
        );
      }
    }
  }

  bool rampHasTerrainContacts(SpatialRamp ramp) {
    const epsilon = 0.000001;
    final alongZ =
        ramp.direction == SpatialRampDirection.north ||
        ramp.direction == SpatialRampDirection.south;
    final negativeHigh =
        ramp.direction == SpatialRampDirection.north ||
        ramp.direction == SpatialRampDirection.west;
    for (final fraction in [epsilon, .5, 1 - epsilon]) {
      final negativeX = alongZ
          ? ramp.x + ramp.width * fraction
          : ramp.x - epsilon;
      final negativeZ = alongZ
          ? ramp.z - epsilon
          : ramp.z + ramp.depth * fraction;
      final positiveX = alongZ ? negativeX : ramp.x + ramp.width + epsilon;
      final positiveZ = alongZ ? ramp.z + ramp.depth + epsilon : negativeZ;
      if (negativeX < 0 ||
          negativeZ < 0 ||
          positiveX >= width ||
          positiveZ >= depth ||
          (worldHeightAt(negativeX, negativeZ) / levelHeight -
                      (negativeHigh ? ramp.highLevel : ramp.lowLevel))
                  .abs() >
              .0001 ||
          (worldHeightAt(positiveX, positiveZ) / levelHeight -
                      (negativeHigh ? ramp.lowLevel : ramp.highLevel))
                  .abs() >
              .0001) {
        return false;
      }
    }
    return true;
  }

  MapSpatialScene copyWith({
    Iterable<int>? heightLevels,
    Iterable<SpatialModelInstance>? instances,
    SpatialCameraProfile? camera,
    SpatialDayNightCycle? dayNightCycle,
    bool clearDayNightCycle = false,
    SpatialNavigationProfile? navigation,
    Object? cliffFrame = _unsetCliffFrame,
    bool? generateCliffs,
    SpatialTerrainSurfaceSet? terrainSurfaces,
  }) => MapSpatialScene(
    width: width,
    depth: depth,
    heightLevels: heightLevels ?? this.heightLevels,
    levelHeight: levelHeight,
    cliffFrame: identical(cliffFrame, _unsetCliffFrame)
        ? this.cliffFrame
        : cliffFrame as SmartTileFrameRef?,
    generateCliffs: generateCliffs ?? this.generateCliffs,
    instances: instances ?? this.instances,
    camera: camera ?? this.camera,
    dayNightCycle: clearDayNightCycle
        ? null
        : dayNightCycle ?? this.dayNightCycle,
    navigation: navigation ?? this.navigation,
    terrainSurfaces: terrainSurfaces ?? this.terrainSurfaces,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapSpatialScene &&
          other.width == width &&
          other.depth == depth &&
          other.levelHeight == levelHeight &&
          other.cliffFrame == cliffFrame &&
          other.generateCliffs == generateCliffs &&
          other.camera == camera &&
          other.dayNightCycle == dayNightCycle &&
          other.navigation == navigation &&
          other.terrainSurfaces == terrainSurfaces &&
          const DeepCollectionEquality().equals(
            other.heightLevels,
            heightLevels,
          ) &&
          const DeepCollectionEquality().equals(other.instances, instances);
  @override
  int get hashCode => Object.hash(
    width,
    depth,
    levelHeight,
    cliffFrame,
    generateCliffs,
    camera,
    dayNightCycle,
    navigation,
    terrainSurfaces,
    const DeepCollectionEquality().hash(heightLevels),
    const DeepCollectionEquality().hash(instances),
  );

  factory MapSpatialScene.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int || (version != 1 && version != 2)) {
      throw const FormatException('Unsupported spatial scene version.');
    }
    if (version == 1 && json.containsKey('terrainSurfaces')) {
      throw const FormatException(
        'Continuous terrain requires spatial scene version 2.',
      );
    }
    if (version == 2 && json['terrainSurfaces'] is! Map) {
      throw const FormatException(
        'Spatial scene version 2 requires continuous terrain surfaces.',
      );
    }
    final terrainSurfaces = version == 2
        ? SpatialTerrainSurfaceSet.fromJson(
            Map<String, dynamic>.from(json['terrainSurfaces'] as Map),
          )
        : const SpatialTerrainSurfaceSet.empty();
    if (version == 2 && terrainSurfaces.surfaces.isEmpty) {
      throw const FormatException(
        'Spatial scene version 2 requires at least one continuous surface.',
      );
    }
    return MapSpatialScene(
      width: json['width'] as int,
      depth: json['depth'] as int,
      heightLevels: (json['heightLevels'] as List).cast<int>(),
      terrainSurfaces: terrainSurfaces,
      levelHeight: (json['levelHeight'] as num).toDouble(),
      generateCliffs: json['generateCliffs'] as bool? ?? true,
      cliffFrame: json['cliffFrame'] == null
          ? null
          : SmartTileFrameRef.fromJson(
              Map<String, dynamic>.from(json['cliffFrame'] as Map),
            ),
      instances: (json['instances'] as List).map(
        (v) =>
            SpatialModelInstance.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
      navigation: json['navigation'] == null
          ? null
          : SpatialNavigationProfile.fromJson(
              Map<String, dynamic>.from(json['navigation'] as Map),
            ),
      dayNightCycle: switch (json['dayNightCycle']) {
        null => null,
        Map<String, dynamic> value => SpatialDayNightCycle.fromJson(value),
        _ => throw const FormatException('Day/night cycle requires an object.'),
      },
      camera: SpatialCameraProfile.fromJson(
        Map<String, dynamic>.from(json['camera'] as Map),
      ),
    );
  }
  Map<String, dynamic> toJson() => {
    'schemaVersion': terrainSurfaces.surfaces.isEmpty ? 1 : 2,
    'width': width,
    'depth': depth,
    'heightLevels': heightLevels,
    if (terrainSurfaces.surfaces.isNotEmpty)
      'terrainSurfaces': terrainSurfaces.toJson(),
    'levelHeight': levelHeight,
    if (cliffFrame != null) 'cliffFrame': cliffFrame!.toJson(),
    if (!generateCliffs) 'generateCliffs': false,
    'instances': instances.map((v) => v.toJson()).toList(),
    'camera': camera.toJson(),
    if (dayNightCycle != null) 'dayNightCycle': dayNightCycle!.toJson(),
    'navigation': navigation.toJson(),
  };
  static List<int> _flat(int width, int depth) {
    if (width <= 0 || depth <= 0 || width > 256 || depth > 256) {
      throw const FormatException(
        'Spatial maps support 1 to 256 cells per axis.',
      );
    }
    return List.filled(width * depth, 0);
  }
}

const _unsetCliffFrame = Object();
