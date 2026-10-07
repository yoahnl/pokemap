import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'project_model3d.dart';
import 'spatial_navigation.dart';
import 'smart_tile.dart';

enum ProjectDimension { twoD, threeD }

enum SpatialCameraMode { fixed }

final class SpatialCameraProfile {
  SpatialCameraProfile({
    this.mode = SpatialCameraMode.fixed,
    this.pitchDegrees = 48.7,
    this.yawDegrees = 0,
    this.fieldOfViewDegrees = 16.2,
    this.distance = 42,
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
        distance > 10000) {
      throw const FormatException('Invalid spatial camera.');
    }
  }
  final SpatialCameraMode mode;
  final double pitchDegrees, yawDegrees, fieldOfViewDegrees, distance;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialCameraProfile &&
          other.mode == mode &&
          other.pitchDegrees == pitchDegrees &&
          other.yawDegrees == yawDegrees &&
          other.fieldOfViewDegrees == fieldOfViewDegrees &&
          other.distance == distance;
  @override
  int get hashCode =>
      Object.hash(mode, pitchDegrees, yawDegrees, fieldOfViewDegrees, distance);

  factory SpatialCameraProfile.fromJson(Map<String, dynamic> json) =>
      SpatialCameraProfile(
        mode: SpatialCameraMode.values.byName(json['mode'] as String),
        pitchDegrees: (json['pitchDegrees'] as num).toDouble(),
        yawDegrees: (json['yawDegrees'] as num).toDouble(),
        fieldOfViewDegrees: (json['fieldOfViewDegrees'] as num).toDouble(),
        distance: (json['distance'] as num).toDouble(),
      );
  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'pitchDegrees': pitchDegrees,
    'yawDegrees': yawDegrees,
    'fieldOfViewDegrees': fieldOfViewDegrees,
    'distance': distance,
  };
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
        animationSpeed > 16) {
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
  SpatialModelInstance copyWith({
    Model3dVector3? position,
    double? rotationDegrees,
    double? scale,
    bool? blocksMovement,
    int? animationIndex,
    bool clearAnimation = false,
    bool? animationLoop,
    double? animationSpeed,
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
          other.blocksMovement == blocksMovement;
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
  );

  factory SpatialModelInstance.fromJson(Map<String, dynamic> json) =>
      SpatialModelInstance(
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
      );
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
  };
}

final class MapSpatialScene {
  MapSpatialScene({
    required this.width,
    required this.depth,
    Iterable<int>? heightLevels,
    this.levelHeight = 1,
    this.cliffFrame,
    Iterable<SpatialModelInstance> instances = const [],
    SpatialCameraProfile? camera,
    SpatialNavigationProfile? navigation,
  }) : heightLevels = List.unmodifiable(heightLevels ?? _flat(width, depth)),
       instances = List.unmodifiable(instances),
       camera = camera ?? SpatialCameraProfile(),
       navigation = navigation ?? SpatialNavigationProfile() {
    if (width <= 0 ||
        depth <= 0 ||
        width > 256 ||
        depth > 256 ||
        this.heightLevels.length != width * depth ||
        this.heightLevels.any((v) => v < 0 || v > 32) ||
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
    _validateRampContacts();
    for (final instance in this.instances) {
      if (instance.position.x < 0 ||
          instance.position.z < 0 ||
          instance.position.x >= width ||
          instance.position.z >= depth) {
        throw const FormatException('A spatial placement is outside the map.');
      }
    }
  }
  final int width, depth;
  final List<int> heightLevels;
  final double levelHeight;
  final SmartTileFrameRef? cliffFrame;
  final List<SpatialModelInstance> instances;
  final SpatialCameraProfile camera;
  final SpatialNavigationProfile navigation;
  double worldHeightAt(double x, double z) {
    for (final ramp in navigation.ramps) {
      if (ramp.contains(x, z)) return ramp.levelAt(x, z) * levelHeight;
    }
    return heightAt(
      x.floor().clamp(0, width - 1),
      z.floor().clamp(0, depth - 1),
    );
  }

  double heightAt(int x, int z) => heightLevels[z * width + x] * levelHeight;
  void _validateRampContacts() {
    const epsilon = 0.000001;
    for (final ramp in navigation.ramps) {
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
          throw const FormatException(
            'A ramp must contact its low and high terrain levels.',
          );
        }
      }
    }
  }

  MapSpatialScene copyWith({
    Iterable<int>? heightLevels,
    Iterable<SpatialModelInstance>? instances,
    SpatialCameraProfile? camera,
    SpatialNavigationProfile? navigation,
    Object? cliffFrame = _unsetCliffFrame,
  }) => MapSpatialScene(
    width: width,
    depth: depth,
    heightLevels: heightLevels ?? this.heightLevels,
    levelHeight: levelHeight,
    cliffFrame: identical(cliffFrame, _unsetCliffFrame)
        ? this.cliffFrame
        : cliffFrame as SmartTileFrameRef?,
    instances: instances ?? this.instances,
    camera: camera ?? this.camera,
    navigation: navigation ?? this.navigation,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapSpatialScene &&
          other.width == width &&
          other.depth == depth &&
          other.levelHeight == levelHeight &&
          other.cliffFrame == cliffFrame &&
          other.camera == camera &&
          other.navigation == navigation &&
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
    camera,
    navigation,
    const DeepCollectionEquality().hash(heightLevels),
    const DeepCollectionEquality().hash(instances),
  );

  factory MapSpatialScene.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported spatial scene version.');
    }
    return MapSpatialScene(
      width: json['width'] as int,
      depth: json['depth'] as int,
      heightLevels: (json['heightLevels'] as List).cast<int>(),
      levelHeight: (json['levelHeight'] as num).toDouble(),
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
      camera: SpatialCameraProfile.fromJson(
        Map<String, dynamic>.from(json['camera'] as Map),
      ),
    );
  }
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'width': width,
    'depth': depth,
    'heightLevels': heightLevels,
    'levelHeight': levelHeight,
    if (cliffFrame != null) 'cliffFrame': cliffFrame!.toJson(),
    'instances': instances.map((v) => v.toJson()).toList(),
    'camera': camera.toJson(),
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
