import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;
import '../operations/border_feature_json_codec.dart';
import 'border_feature.dart';
import 'border_geometry.dart';
import 'border_value_objects.dart';
import 'map_spatial_scene.dart';

final class ExteriorDecorationBorder {
  static const schemaVersion = 1;
  static const maximumDimension = 384;
  static const maximumContourPoints = 16384;

  ExteriorDecorationBorder({
    required this.id,
    required this.layerId,
    required this.originX,
    required this.originZ,
    required this.width,
    required this.depth,
    required this.feature,
    Iterable<SpatialModelInstance> instances = const [],
  }) : instances = List.unmodifiable(instances) {
    final safeId = RegExp(r'^[a-zA-Z0-9_-]{1,128}$');
    if (!safeId.hasMatch(id) ||
        !safeId.hasMatch(layerId) ||
        feature.id != id ||
        width < 1 ||
        depth < 1 ||
        width > maximumDimension ||
        depth > maximumDimension ||
        this.instances.length > 10000) {
      throw const FormatException(
        'Invalid logical exterior Border identity, bounds or quota.',
      );
    }
    switch (feature.geometry) {
      case BorderRegionGeometry geometry:
        if (geometry.width != width || geometry.height != depth) {
          throw const FormatException(
            'Logical exterior Border mask dimensions must match its bounds.',
          );
        }
      case BorderStrokeGeometry geometry:
        final edge = geometry.alignment == BorderStrokeAlignment.gridEdges
            ? 0
            : 1;
        if (geometry.strokes.fold<int>(
                  0,
                  (count, stroke) => count + stroke.points.length,
                ) >
                maximumContourPoints ||
            geometry.strokes.any(
              (stroke) => stroke.points.any(
                (point) =>
                    point.x < 0 ||
                    point.y < 0 ||
                    point.x > width - edge ||
                    point.y > depth - edge,
              ),
            )) {
          throw const FormatException(
            'Logical exterior Border contours must be bounded.',
          );
        }
    }
    if (feature.keepOutRegions.any(
          (keepOut) =>
              keepOut.region.width != width || keepOut.region.height != depth,
        ) ||
        (feature.materialization != null &&
            !feature.materialization!.targetsSpatialScene)) {
      throw const FormatException(
        'Logical exterior Borders require native spatial materialization.',
      );
    }
    final ids = <String>{};
    for (final instance in this.instances) {
      final support = instance.supportPosition;
      if (!ids.add(instance.id) ||
          instance.entityId != null ||
          support.x < 0 ||
          support.z < 0 ||
          support.x >= width ||
          support.z >= depth) {
        throw const FormatException(
          'Logical exterior Border instances require unique bounded visual ownership.',
        );
      }
    }
    final owned = feature.generatedPlacementIds;
    if (owned.length != ids.length ||
        owned.toSet().length != owned.length ||
        !ids.containsAll(owned)) {
      throw const FormatException(
        'One logical Border must own every materialized instance exactly once.',
      );
    }
  }

  final String id, layerId;
  final int originX, originZ, width, depth;
  final BorderFeature feature;
  final List<SpatialModelInstance> instances;
  late final Set<String> resourceReferenceIds = Set.unmodifiable({
    feature.blueprintId,
    for (final instance in instances) instance.modelId,
  });

  factory ExteriorDecorationBorder.fromJson(Map<String, dynamic> json) {
    try {
      const keys = {
        'schemaVersion',
        'id',
        'layerId',
        'originX',
        'originZ',
        'width',
        'depth',
        'feature',
        'instances',
      };
      if (json.length != keys.length ||
          !json.keys.every(keys.contains) ||
          json['schemaVersion'] is! int ||
          json['schemaVersion'] != schemaVersion) {
        throw const FormatException(
          'Unsupported logical exterior Border document.',
        );
      }
      final rawInstances = json['instances'] as List;
      if (rawInstances.length > 10000 ||
          ['width', 'depth'].any(
            (key) =>
                json[key] is! int ||
                (json[key] as int) < 1 ||
                (json[key] as int) > maximumDimension,
          )) {
        throw const FormatException(
          'Logical exterior Border instance quota exceeded.',
        );
      }
      const instanceKeys = {
        'id',
        'modelId',
        'position',
        'rotationDegrees',
        'scale',
        'animationIndex',
        'animationLoop',
        'animationSpeed',
        'blocksMovement',
        'castsShadows',
        'entityId',
        'clip',
      };
      for (final raw in rawInstances) {
        if (raw is! Map || raw.keys.any((key) => !instanceKeys.contains(key))) {
          throw const FormatException(
            'Unknown logical exterior Border instance fields.',
          );
        }
      }
      return ExteriorDecorationBorder(
        id: json['id'] as String,
        layerId: json['layerId'] as String,
        originX: json['originX'] as int,
        originZ: json['originZ'] as int,
        width: json['width'] as int,
        depth: json['depth'] as int,
        feature: decodeBorderFeatureJson(json['feature'], formatVersion: 4),
        instances: rawInstances.map(
          (value) => SpatialModelInstance.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid logical exterior Border: $error');
    }
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'layerId': layerId,
    'originX': originX,
    'originZ': originZ,
    'width': width,
    'depth': depth,
    'feature': encodeBorderFeatureJson(feature, formatVersion: 4),
    'instances': instances.map((instance) => instance.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is ExteriorDecorationBorder &&
      id == other.id &&
      layerId == other.layerId &&
      originX == other.originX &&
      originZ == other.originZ &&
      width == other.width &&
      depth == other.depth &&
      feature == other.feature &&
      const DeepCollectionEquality().equals(instances, other.instances);
  @override
  int get hashCode => Object.hash(
    id,
    layerId,
    originX,
    originZ,
    width,
    depth,
    feature,
    const DeepCollectionEquality().hash(instances),
  );
}
