import '../models/border_blueprint.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_catalog.dart';
import '../models/border_layer.dart';
import '../models/border_value_objects.dart';
import 'border_template_capabilities.dart';

/// Whether one feature contains authored values that V1 cannot represent.
bool borderFeatureRequiresFormatV2(BorderFeature feature) =>
    feature.lineSide != BorderLineSide.primary ||
    feature.paramsOverride?.allowAutoRotation == false;

int minimumBorderLayerFormatVersionForFeature(BorderFeature feature) {
  if (feature.geometry case final BorderStrokeGeometry geometry
      when geometry.alignment == BorderStrokeAlignment.gridEdges) {
    return BorderLayerContent.formatVersionV3;
  }
  return borderFeatureRequiresFormatV2(feature)
      ? BorderLayerContent.formatVersionV2
      : BorderLayerContent.formatVersionV1;
}

int minimumBorderLayerFormatVersionForFeatures(
  Iterable<BorderFeature> features,
) {
  var result = BorderLayerContent.formatVersionV1;
  for (final feature in features) {
    final minimum = minimumBorderLayerFormatVersionForFeature(feature);
    if (minimum > result) result = minimum;
  }
  return result;
}

/// Whether any feature in one layer contains authored V2-only values.
bool borderFeaturesRequireFormatV2(Iterable<BorderFeature> features) =>
    features.any(borderFeatureRequiresFormatV2);

/// Whether one blueprint record contains authored values that V1 cannot
/// represent without loss.
bool borderBlueprintRecordRequiresFormatV2(BorderBlueprintRecord record) {
  final draft = record.draft.definition;
  if (draft.template == BorderBlueprintTemplate.connectedLine ||
      !draft.defaults.allowAutoRotation ||
      draft.primitives
          .any((primitive) => _isConnectedLineRole(primitive.role))) {
    return true;
  }

  final published = record.latestPublished?.definition;
  return published != null &&
      (published.template == BorderBlueprintTemplate.connectedLine ||
          !published.defaults.allowAutoRotation ||
          published.primitives
              .any((primitive) => _isConnectedLineRole(primitive.role)));
}

int minimumBorderCatalogFormatVersionForRecord(BorderBlueprintRecord record) {
  var result = ProjectBorderCatalog.formatVersionV1;
  for (final definition in <BorderBlueprintDefinition>[
    record.draft.definition,
    if (record.latestPublished != null) record.latestPublished!.definition,
  ]) {
    final minimum = minimumBorderCatalogFormatVersionForTemplate(
      definition.template,
    );
    if (minimum > result) result = minimum;
    if (definition.primitives.any(
      (primitive) =>
          primitive.authoredOrientation !=
          BorderPrimitiveOrientation.legacyAxis,
    )) {
      result = ProjectBorderCatalog.formatVersionV4;
    }
    if (!definition.defaults.allowAutoRotation ||
        definition.primitives.any(
          (primitive) => _isConnectedLineRole(primitive.role),
        )) {
      if (ProjectBorderCatalog.formatVersionV2 > result) {
        result = ProjectBorderCatalog.formatVersionV2;
      }
    }
  }
  return result;
}

int minimumBorderCatalogFormatVersionForRecords(
  Iterable<BorderBlueprintRecord> records,
) {
  var result = ProjectBorderCatalog.formatVersionV1;
  for (final record in records) {
    final minimum = minimumBorderCatalogFormatVersionForRecord(record);
    if (minimum > result) result = minimum;
  }
  return result;
}

bool _isConnectedLineRole(BorderPrimitiveRole role) =>
    role == BorderPrimitiveRole.lineCap ||
    role == BorderPrimitiveRole.lineStraight ||
    role == BorderPrimitiveRole.lineCorner;
