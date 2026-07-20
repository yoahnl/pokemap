import '../models/border_feature.dart';
import '../models/border_layer.dart';
import 'border_feature_json_codec.dart';
import 'border_json_codec_helpers.dart';

const Set<String> _layerContentKeys = <String>{
  'formatVersion',
  'features',
};

/// Encodes one strict versioned payload stored by a dedicated Border layer.
///
/// Feature order is authored data and is preserved exactly. Encoding does not
/// resolve blueprints or regenerate materialization.
Map<String, Object?> encodeBorderLayerContentJson(
  BorderLayerContent content, {
  String path = r'$',
}) {
  final versionPath = borderJsonPropertyPath(path, 'formatVersion');
  _requireSupportedVersion(content.formatVersion, versionPath);

  final featuresPath = borderJsonPropertyPath(path, 'features');
  final features = <Object?>[];
  final firstIdPaths = <String, String>{};
  for (var index = 0; index < content.features.length; index += 1) {
    final feature = content.features[index];
    final featurePath = borderJsonIndexPath(featuresPath, index);
    _rejectDuplicateFeatureId(
      feature: feature,
      featurePath: featurePath,
      firstIdPaths: firstIdPaths,
    );
    features.add(
      encodeBorderFeatureJson(
        feature,
        path: featurePath,
        formatVersion: content.formatVersion,
      ),
    );
  }

  return <String, Object?>{
    'formatVersion': content.formatVersion,
    'features': features,
  };
}

/// Decodes one standalone strict V1 or V2 Border layer payload.
///
/// Null, missing, malformed, legacy, and future payloads are rejected here.
/// Migration tolerance belongs to the future map schema boundary.
BorderLayerContent decodeBorderLayerContentJson(
  Object? json, {
  String path = r'$',
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _layerContentKeys,
  );

  final versionPath = borderJsonPropertyPath(path, 'formatVersion');
  final formatVersion = borderJsonRequireInt(
    borderJsonRequireField(value, 'formatVersion', path),
    versionPath,
  );
  _requireSupportedVersion(formatVersion, versionPath);

  final featuresPath = borderJsonPropertyPath(path, 'features');
  final featureValues = borderJsonRequireList(
    borderJsonRequireField(value, 'features', path),
    featuresPath,
  );
  final features = <BorderFeature>[];
  final firstIdPaths = <String, String>{};
  for (var index = 0; index < featureValues.length; index += 1) {
    final featurePath = borderJsonIndexPath(featuresPath, index);
    final feature = decodeBorderFeatureJson(
      featureValues[index],
      path: featurePath,
      formatVersion: formatVersion,
    );
    _rejectDuplicateFeatureId(
      feature: feature,
      featurePath: featurePath,
      firstIdPaths: firstIdPaths,
    );
    features.add(feature);
  }

  return borderJsonConstructAtPath(
    path,
    () => BorderLayerContent(
      formatVersion: formatVersion,
      features: features,
    ),
  );
}

void _requireSupportedVersion(int value, String path) {
  if (value != BorderLayerContent.formatVersionV1 &&
      value != BorderLayerContent.formatVersionV2 &&
      value != BorderLayerContent.formatVersionV3) {
    throw FormatException(
      '$path: expected BorderLayerContent format version 1, 2, or 3',
    );
  }
}

void _rejectDuplicateFeatureId({
  required BorderFeature feature,
  required String featurePath,
  required Map<String, String> firstIdPaths,
}) {
  final idPath = borderJsonPropertyPath(featurePath, 'id');
  final firstPath = firstIdPaths[feature.id];
  if (firstPath != null) {
    throw FormatException(
      '$idPath: duplicate id "${feature.id}"; first declared at $firstPath',
    );
  }
  firstIdPaths[feature.id] = idPath;
}
