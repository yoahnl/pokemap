import '../models/border_blueprint.dart';
import '../models/border_feature.dart';
import '../models/border_value_objects.dart';

/// Whether one feature contains authored values that V1 cannot represent.
bool borderFeatureRequiresFormatV2(BorderFeature feature) =>
    feature.lineSide != BorderLineSide.primary ||
    feature.paramsOverride?.allowAutoRotation == false;

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

bool _isConnectedLineRole(BorderPrimitiveRole role) =>
    role == BorderPrimitiveRole.lineCap ||
    role == BorderPrimitiveRole.lineStraight ||
    role == BorderPrimitiveRole.lineCorner;
