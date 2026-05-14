import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';

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

String _optionalString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
  String defaultValue,
) {
  if (!json.containsKey(key)) {
    return defaultValue;
  }
  final value = json[key];
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

double _optionalDouble(
  Map<String, Object?> json,
  String key,
  String fieldKey,
  double defaultValue,
) {
  if (!json.containsKey(key)) {
    return defaultValue;
  }
  final value = json[key];
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  return value.toDouble();
}

ShadowCasterMode _decodeShadowCasterMode(String value) {
  for (final mode in ShadowCasterMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }
  throw ValidationException(
      'ProjectShadowProfile.mode has unknown value "$value"');
}

ShadowRenderPass _decodeShadowRenderPass(String value) {
  for (final renderPass in ShadowRenderPass.values) {
    if (renderPass.name == value) {
      return renderPass;
    }
  }
  throw ValidationException(
    'ProjectShadowProfile.renderPass has unknown value "$value"',
  );
}

ShadowSoftnessMode _decodeShadowSoftnessMode(String value) {
  for (final softnessMode in ShadowSoftnessMode.values) {
    if (softnessMode.name == value) {
      return softnessMode;
    }
  }
  throw ValidationException(
    'ProjectShadowProfile.softnessMode has unknown value "$value"',
  );
}

String _decodeColorHexRgb(Map<String, Object?> json) {
  final value = _optionalString(
    json,
    'colorHexRgb',
    'ProjectShadowProfile.colorHexRgb',
    '000000',
  );
  return value.startsWith('#') ? value.substring(1) : value;
}

/// Encodes a [ProjectShadowProfile] using the external Shadow V0 JSON shape.
///
/// All V0 fields are emitted, including values equal to model defaults.
Map<String, Object?> encodeProjectShadowProfile(ProjectShadowProfile profile) {
  return <String, Object?>{
    'id': profile.id,
    'name': profile.name,
    'mode': profile.mode.name,
    'renderPass': profile.renderPass.name,
    'offsetX': profile.offsetX,
    'offsetY': profile.offsetY,
    'scaleX': profile.scaleX,
    'scaleY': profile.scaleY,
    'opacity': profile.opacity,
    'colorHexRgb': profile.colorHexRgb,
    'softnessMode': profile.softnessMode.name,
  };
}

/// Decodes a [ProjectShadowProfile] from the external Shadow V0 JSON shape.
///
/// Unknown keys are ignored. Known keys keep strict types.
ProjectShadowProfile decodeProjectShadowProfile(Object? json) {
  if (json is! Map) {
    throw ValidationException(
      'ProjectShadowProfile JSON must be an Object, got ${json.runtimeType}',
    );
  }
  final map = _stringKeyMapFrom(json);

  return ProjectShadowProfile(
    id: _requiredString(map, 'id', 'ProjectShadowProfile.id'),
    name: _requiredString(map, 'name', 'ProjectShadowProfile.name'),
    mode: _decodeShadowCasterMode(
      _requiredString(map, 'mode', 'ProjectShadowProfile.mode'),
    ),
    renderPass: _decodeShadowRenderPass(
      _requiredString(map, 'renderPass', 'ProjectShadowProfile.renderPass'),
    ),
    offsetX: _optionalDouble(
      map,
      'offsetX',
      'ProjectShadowProfile.offsetX',
      0,
    ),
    offsetY: _optionalDouble(
      map,
      'offsetY',
      'ProjectShadowProfile.offsetY',
      0,
    ),
    scaleX: _optionalDouble(
      map,
      'scaleX',
      'ProjectShadowProfile.scaleX',
      1,
    ),
    scaleY: _optionalDouble(
      map,
      'scaleY',
      'ProjectShadowProfile.scaleY',
      1,
    ),
    opacity: _optionalDouble(
      map,
      'opacity',
      'ProjectShadowProfile.opacity',
      0.35,
    ),
    colorHexRgb: _decodeColorHexRgb(map),
    softnessMode: _decodeShadowSoftnessMode(
      _optionalString(
        map,
        'softnessMode',
        'ProjectShadowProfile.softnessMode',
        ShadowSoftnessMode.hardEdge.name,
      ),
    ),
  );
}
