import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'projected_shadow_value_object_json_codecs.dart';

Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value as Object?,
      ),
    ),
  );
}

Map<String, Object?> _requiredObject(Object? json, String label) {
  if (json is! Map) {
    throw ValidationException(
      '$label JSON must be an Object, got ${json.runtimeType}',
    );
  }
  return _stringKeyMapFrom(json);
}

Object? _valueForRequiredKey(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$fieldKey is required');
  }
  return json[key];
}

bool _requiredBool(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! bool) {
    throw ValidationException('$fieldKey must be a bool');
  }
  return value;
}

String _requiredString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

/// Encodes an element-level authored projected building shadow config.
Map<String, dynamic> encodeProjectElementProjectedBuildingShadowConfig(
  ProjectElementProjectedBuildingShadowConfig config,
) {
  final casterKind = config.casterKind;
  return <String, dynamic>{
    'enabled': config.enabled,
    'presetId': config.presetId,
    'anchor': encodeProjectedShadowAnchor(config.anchor),
    'localOffset': encodeProjectedShadowOffset(config.localOffset),
    if (casterKind != null)
      'casterKind': encodeProjectedBuildingShadowCasterKind(casterKind),
  };
}

/// Decodes an element-level authored projected building shadow config.
///
/// All fields are required, including `presetId` when `enabled` is false.
/// Unknown keys are ignored; anchor and offset are delegated to the ShadowV2
/// atomic value-object codecs.
ProjectElementProjectedBuildingShadowConfig
    decodeProjectElementProjectedBuildingShadowConfig(Object? json) {
  final map = _requiredObject(
    json,
    'ProjectElementProjectedBuildingShadowConfig',
  );
  final casterKindJson = map['casterKind'];
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: _requiredBool(
      map,
      'enabled',
      'ProjectElementProjectedBuildingShadowConfig.enabled',
    ),
    presetId: _requiredString(
      map,
      'presetId',
      'ProjectElementProjectedBuildingShadowConfig.presetId',
    ),
    anchor: decodeProjectedShadowAnchor(
      _valueForRequiredKey(
        map,
        'anchor',
        'ProjectElementProjectedBuildingShadowConfig.anchor',
      ),
    ),
    localOffset: decodeProjectedShadowOffset(
      _valueForRequiredKey(
        map,
        'localOffset',
        'ProjectElementProjectedBuildingShadowConfig.localOffset',
      ),
    ),
    casterKind: casterKindJson == null
        ? null
        : decodeProjectedBuildingShadowCasterKind(casterKindJson),
  );
}
