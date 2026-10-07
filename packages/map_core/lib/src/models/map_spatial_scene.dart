import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

import 'project_model3d.dart';

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
    this.blocksMovement = true,
  }) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
        modelId.isEmpty ||
        !rotationDegrees.isFinite ||
        !scale.isFinite ||
        scale <= 0 ||
        scale > 1000 ||
        (animationIndex != null && animationIndex! < 0)) {
      throw const FormatException('Invalid spatial model placement.');
    }
  }
  final String id, modelId;
  final Model3dVector3 position;
  final double rotationDegrees, scale;
  final int? animationIndex;
  final bool blocksMovement;
  SpatialModelInstance copyWith({
    Model3dVector3? position,
    double? rotationDegrees,
    double? scale,
    bool? blocksMovement,
  }) => SpatialModelInstance(
    id: id,
    modelId: modelId,
    position: position ?? this.position,
    rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    scale: scale ?? this.scale,
    animationIndex: animationIndex,
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
          other.blocksMovement == blocksMovement;
  @override
  int get hashCode => Object.hash(
    id,
    modelId,
    position,
    rotationDegrees,
    scale,
    animationIndex,
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
        blocksMovement: json['blocksMovement'] as bool,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'modelId': modelId,
    'position': position.toJson(),
    'rotationDegrees': rotationDegrees,
    'scale': scale,
    'animationIndex': animationIndex,
    'blocksMovement': blocksMovement,
  };
}

final class MapSpatialScene {
  MapSpatialScene({
    required this.width,
    required this.depth,
    Iterable<int>? heightLevels,
    this.levelHeight = 1,
    Iterable<SpatialModelInstance> instances = const [],
    SpatialCameraProfile? camera,
  }) : heightLevels = List.unmodifiable(heightLevels ?? _flat(width, depth)),
       instances = List.unmodifiable(instances),
       camera = camera ?? SpatialCameraProfile() {
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
  final List<SpatialModelInstance> instances;
  final SpatialCameraProfile camera;
  double heightAt(int x, int z) => heightLevels[z * width + x] * levelHeight;
  MapSpatialScene copyWith({
    Iterable<int>? heightLevels,
    Iterable<SpatialModelInstance>? instances,
    SpatialCameraProfile? camera,
  }) => MapSpatialScene(
    width: width,
    depth: depth,
    heightLevels: heightLevels ?? this.heightLevels,
    levelHeight: levelHeight,
    instances: instances ?? this.instances,
    camera: camera ?? this.camera,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapSpatialScene &&
          other.width == width &&
          other.depth == depth &&
          other.levelHeight == levelHeight &&
          other.camera == camera &&
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
    camera,
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
      instances: (json['instances'] as List).map(
        (v) =>
            SpatialModelInstance.fromJson(Map<String, dynamic>.from(v as Map)),
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
    'instances': instances.map((v) => v.toJson()).toList(),
    'camera': camera.toJson(),
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
