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

String? _optionalNullableString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw ValidationException('$fieldKey must be a String or null');
  }
  return value;
}

int _optionalInt(
  Map<String, Object?> json,
  String key,
  String fieldKey,
  int defaultValue,
) {
  if (!json.containsKey(key)) {
    return defaultValue;
  }
  final value = json[key];
  if (value is! int) {
    throw ValidationException('$fieldKey must be an int');
  }
  return value;
}

/// Encodes a parametric projected building shadow preset.
Map<String, dynamic> encodeProjectBuildingShadowPreset(
  ProjectBuildingShadowPreset preset,
) {
  return <String, dynamic>{
    'id': preset.id,
    'name': preset.name,
    'direction': encodeProjectedShadowDirection(preset.direction),
    'shape': encodeProjectedShadowShapeTuning(preset.shape),
    'appearance': encodeProjectedShadowAppearance(preset.appearance),
    'timeOfDayMode': encodeProjectedShadowTimeOfDayMode(
      preset.timeOfDayMode,
    ),
    if (preset.categoryId != null) 'categoryId': preset.categoryId,
    'sortOrder': preset.sortOrder,
  };
}

/// Decodes a parametric projected building shadow preset.
///
/// Unknown keys are ignored. Nested atomic objects are decoded by their own
/// ShadowV2 value-object codecs.
ProjectBuildingShadowPreset decodeProjectBuildingShadowPreset(Object? json) {
  final map = _requiredObject(json, 'ProjectBuildingShadowPreset');
  return ProjectBuildingShadowPreset(
    id: _requiredString(map, 'id', 'ProjectBuildingShadowPreset.id'),
    name: _requiredString(map, 'name', 'ProjectBuildingShadowPreset.name'),
    direction: decodeProjectedShadowDirection(
      _valueForRequiredKey(
        map,
        'direction',
        'ProjectBuildingShadowPreset.direction',
      ),
    ),
    shape: decodeProjectedShadowShapeTuning(
      _valueForRequiredKey(map, 'shape', 'ProjectBuildingShadowPreset.shape'),
    ),
    appearance: decodeProjectedShadowAppearance(
      _valueForRequiredKey(
        map,
        'appearance',
        'ProjectBuildingShadowPreset.appearance',
      ),
    ),
    timeOfDayMode: decodeProjectedShadowTimeOfDayMode(
      _valueForRequiredKey(
        map,
        'timeOfDayMode',
        'ProjectBuildingShadowPreset.timeOfDayMode',
      ),
    ),
    categoryId: _optionalNullableString(
      map,
      'categoryId',
      'ProjectBuildingShadowPreset.categoryId',
    ),
    sortOrder: _optionalInt(
      map,
      'sortOrder',
      'ProjectBuildingShadowPreset.sortOrder',
      0,
    ),
  );
}
