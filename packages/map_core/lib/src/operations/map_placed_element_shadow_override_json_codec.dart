import 'package:json_annotation/json_annotation.dart';

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

ShadowOverrideMode _decodeShadowOverrideMode(Map<String, Object?> json) {
  if (!json.containsKey('mode')) {
    return ShadowOverrideMode.inherit;
  }

  final value = json['mode'];
  if (value is! String) {
    throw const ValidationException(
      'MapPlacedElementShadowOverride.mode must be a String',
    );
  }

  for (final mode in ShadowOverrideMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }

  throw ValidationException(
    'Unknown MapPlacedElementShadowOverride.mode "$value"',
  );
}

/// Encodes a [MapPlacedElementShadowOverride] using the external Shadow V0
/// JSON shape.
Map<String, Object?> encodeMapPlacedElementShadowOverride(
  MapPlacedElementShadowOverride override,
) {
  return <String, Object?>{
    'mode': override.mode.name,
    if (override.shadowProfileId != null)
      'shadowProfileId': override.shadowProfileId,
    if (override.offsetX != null) 'offsetX': override.offsetX,
    if (override.offsetY != null) 'offsetY': override.offsetY,
    if (override.scaleX != null) 'scaleX': override.scaleX,
    if (override.scaleY != null) 'scaleY': override.scaleY,
    if (override.opacity != null) 'opacity': override.opacity,
  };
}

/// Decodes an optional [MapPlacedElementShadowOverride] from its external
/// Shadow V0 JSON shape.
///
/// `null` means no per-instance override, which is equivalent to inherit.
/// Unknown keys are ignored.
MapPlacedElementShadowOverride? decodeMapPlacedElementShadowOverride(
  Object? json,
) {
  if (json == null) {
    return null;
  }
  if (json is! Map) {
    throw ValidationException(
      'MapPlacedElementShadowOverride JSON must be an Object or null, got ${json.runtimeType}',
    );
  }

  final map = _stringKeyMapFrom(json);
  return MapPlacedElementShadowOverride(
    mode: _decodeShadowOverrideMode(map),
    shadowProfileId: _optionalNullableString(
      map,
      'shadowProfileId',
      'MapPlacedElementShadowOverride.shadowProfileId',
    ),
    offsetX: _optionalNullableDouble(
      map,
      'offsetX',
      'MapPlacedElementShadowOverride.offsetX',
    ),
    offsetY: _optionalNullableDouble(
      map,
      'offsetY',
      'MapPlacedElementShadowOverride.offsetY',
    ),
    scaleX: _optionalNullableDouble(
      map,
      'scaleX',
      'MapPlacedElementShadowOverride.scaleX',
    ),
    scaleY: _optionalNullableDouble(
      map,
      'scaleY',
      'MapPlacedElementShadowOverride.scaleY',
    ),
    opacity: _optionalNullableDouble(
      map,
      'opacity',
      'MapPlacedElementShadowOverride.opacity',
    ),
  );
}

class MapPlacedElementShadowOverrideJsonConverter
    implements JsonConverter<MapPlacedElementShadowOverride?, Object?> {
  const MapPlacedElementShadowOverrideJsonConverter();

  @override
  MapPlacedElementShadowOverride? fromJson(Object? json) {
    return decodeMapPlacedElementShadowOverride(json);
  }

  @override
  Object? toJson(MapPlacedElementShadowOverride? override) {
    return override == null
        ? null
        : encodeMapPlacedElementShadowOverride(override);
  }
}
