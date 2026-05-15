import 'package:json_annotation/json_annotation.dart';

import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';
import 'static_shadow_footprint_config_json_codec.dart';

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

bool _optionalBool(
  Map<String, Object?> json,
  String key,
  String fieldKey,
  bool defaultValue,
) {
  if (!json.containsKey(key)) {
    return defaultValue;
  }
  final value = json[key];
  if (value is! bool) {
    throw ValidationException('$fieldKey must be a bool');
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
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

double? _optionalNullableDouble(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final value = json[key];
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  return value.toDouble();
}

/// Encodes a [ProjectElementShadowConfig] using the external Shadow V0 JSON
/// shape.
Map<String, Object?> encodeProjectElementShadowConfig(
  ProjectElementShadowConfig config,
) {
  final footprintJson = encodeStaticShadowFootprintConfig(config.footprint);
  return <String, Object?>{
    'castsShadow': config.castsShadow,
    if (config.shadowProfileId != null)
      'shadowProfileId': config.shadowProfileId,
    if (config.offsetX != null) 'offsetX': config.offsetX,
    if (config.offsetY != null) 'offsetY': config.offsetY,
    if (config.scaleX != null) 'scaleX': config.scaleX,
    if (config.scaleY != null) 'scaleY': config.scaleY,
    if (config.opacity != null) 'opacity': config.opacity,
    if (footprintJson != null) 'footprint': footprintJson,
  };
}

/// Decodes an optional [ProjectElementShadowConfig] from its external Shadow V0
/// JSON shape.
///
/// `null` means no shadow config on the element. Unknown keys are ignored.
ProjectElementShadowConfig? decodeProjectElementShadowConfig(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is! Map) {
    throw ValidationException(
      'ProjectElementShadowConfig JSON must be an Object or null, got ${json.runtimeType}',
    );
  }

  final map = _stringKeyMapFrom(json);
  return ProjectElementShadowConfig(
    castsShadow: _optionalBool(
      map,
      'castsShadow',
      'ProjectElementShadowConfig.castsShadow',
      false,
    ),
    shadowProfileId: _optionalNullableString(
      map,
      'shadowProfileId',
      'ProjectElementShadowConfig.shadowProfileId',
    ),
    offsetX: _optionalNullableDouble(
      map,
      'offsetX',
      'ProjectElementShadowConfig.offsetX',
    ),
    offsetY: _optionalNullableDouble(
      map,
      'offsetY',
      'ProjectElementShadowConfig.offsetY',
    ),
    scaleX: _optionalNullableDouble(
      map,
      'scaleX',
      'ProjectElementShadowConfig.scaleX',
    ),
    scaleY: _optionalNullableDouble(
      map,
      'scaleY',
      'ProjectElementShadowConfig.scaleY',
    ),
    opacity: _optionalNullableDouble(
      map,
      'opacity',
      'ProjectElementShadowConfig.opacity',
    ),
    footprint: decodeStaticShadowFootprintConfig(map['footprint']),
  );
}

class ProjectElementShadowConfigJsonConverter
    implements JsonConverter<ProjectElementShadowConfig?, Object?> {
  const ProjectElementShadowConfigJsonConverter();

  @override
  ProjectElementShadowConfig? fromJson(Object? json) {
    return decodeProjectElementShadowConfig(json);
  }

  @override
  Object? toJson(ProjectElementShadowConfig? config) {
    return config == null ? null : encodeProjectElementShadowConfig(config);
  }
}
