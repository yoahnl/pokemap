import '../exceptions/map_exceptions.dart';
import '../models/border_feature.dart';
import '../models/border_layer.dart';
import '../models/border_value_objects.dart';
import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import 'border_format_version.dart';
import 'map_layers.dart';

/// Adds one dedicated Border layer using the generic layer identity rules.
MapData addBorderLayer(
  MapData map, {
  required String id,
  required String name,
  int? insertIndex,
}) {
  if (insertIndex != null &&
      (insertIndex < 0 || insertIndex > map.layers.length)) {
    throw ValidationException(
      'Invalid Border layer insertIndex: $insertIndex',
    );
  }
  return addMapLayer(
    map,
    kind: MapLayerKind.border,
    id: id,
    name: name,
    insertIndex: insertIndex,
  );
}

/// Replaces the complete authored content of one Border layer.
MapData setBorderLayerContent(
  MapData map, {
  required String layerId,
  required BorderLayerContent content,
}) {
  return _updateBorderLayer(
    map,
    layerId: layerId,
    update: (layer) => layer.copyWith(
      content: _contentForCompleteWrite(content),
    ),
  );
}

BorderLayerContent _contentForCompleteWrite(BorderLayerContent content) {
  if (content.formatVersion == BorderLayerContent.formatVersionV2 ||
      !borderFeaturesRequireFormatV2(content.features)) {
    return content;
  }
  return BorderLayerContent(
    formatVersion: BorderLayerContent.formatVersionV2,
    features: content.features,
  );
}

/// Appends a new feature or replaces the matching feature at its authored
/// index.
MapData upsertBorderFeature(
  MapData map, {
  required String layerId,
  required BorderFeature feature,
  BorderBlueprintTemplate? template,
}) {
  return _updateBorderLayer(
    map,
    layerId: layerId,
    update: (layer) {
      final features = List<BorderFeature>.from(layer.content.features);
      final index =
          features.indexWhere((candidate) => candidate.id == feature.id);
      if (index < 0) {
        features.add(feature);
      } else {
        features[index] = feature;
      }
      return layer.copyWith(
        content: BorderLayerContent(
          formatVersion: _formatVersionForFeatureWrite(
            layer.content,
            features: features,
            template: template,
          ),
          features: features,
        ),
      );
    },
  );
}

int _formatVersionForFeatureWrite(
  BorderLayerContent content, {
  required List<BorderFeature> features,
  required BorderBlueprintTemplate? template,
}) {
  if (content.formatVersion == BorderLayerContent.formatVersionV2 ||
      template == BorderBlueprintTemplate.connectedLine ||
      borderFeaturesRequireFormatV2(features)) {
    return BorderLayerContent.formatVersionV2;
  }
  return BorderLayerContent.formatVersionV1;
}

/// Removes one feature while preserving every other feature in authored order.
MapData removeBorderFeature(
  MapData map, {
  required String layerId,
  required String featureId,
}) {
  return _updateBorderLayer(
    map,
    layerId: layerId,
    update: (layer) {
      final index = layer.content.features.indexWhere(
        (feature) => feature.id == featureId,
      );
      if (index < 0) {
        throw ValidationException(
          'Border feature not found in layer ${layer.id}: $featureId',
        );
      }
      final features = List<BorderFeature>.from(layer.content.features)
        ..removeAt(index);
      return layer.copyWith(
        content: BorderLayerContent(
          formatVersion: layer.content.formatVersion,
          features: features,
        ),
      );
    },
  );
}

/// Moves one feature to the strict final [newIndex].
MapData reorderBorderFeature(
  MapData map, {
  required String layerId,
  required String featureId,
  required int newIndex,
}) {
  return _updateBorderLayer(
    map,
    layerId: layerId,
    update: (layer) {
      final features = List<BorderFeature>.from(layer.content.features);
      final oldIndex = features.indexWhere(
        (feature) => feature.id == featureId,
      );
      if (oldIndex < 0) {
        throw ValidationException(
          'Border feature not found in layer ${layer.id}: $featureId',
        );
      }
      if (newIndex < 0 || newIndex >= features.length) {
        throw ValidationException(
          'Invalid Border feature newIndex: $newIndex',
        );
      }

      final feature = features.removeAt(oldIndex);
      features.insert(newIndex, feature);
      return layer.copyWith(
        content: BorderLayerContent(
          formatVersion: layer.content.formatVersion,
          features: features,
        ),
      );
    },
  );
}

MapData _updateBorderLayer(
  MapData map, {
  required String layerId,
  required BorderLayer Function(BorderLayer layer) update,
}) {
  final normalizedLayerId = layerId.trim();
  if (normalizedLayerId.isEmpty) {
    throw const ValidationException('Layer ID cannot be empty');
  }
  final index = map.layers.indexWhere(
    (layer) => layer.id == normalizedLayerId,
  );
  if (index < 0) {
    throw ValidationException('Layer not found: $normalizedLayerId');
  }
  final layer = map.layers[index];
  if (layer is! BorderLayer) {
    throw ValidationException(
      'Layer is not a border layer: $normalizedLayerId',
    );
  }

  final layers = List<MapLayer>.from(map.layers, growable: false);
  layers[index] = update(layer);
  return map.copyWith(version: ProjectVersion.v2, layers: layers);
}
