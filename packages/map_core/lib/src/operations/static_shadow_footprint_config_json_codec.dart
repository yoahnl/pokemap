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

double? _optionalNullableDouble(
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
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  return value.toDouble();
}

Map<String, Object?>? encodeStaticShadowFootprintConfig(
  StaticShadowFootprintConfig? footprint,
) {
  if (footprint == null || footprint.isEmpty) {
    return null;
  }
  return <String, Object?>{
    if (footprint.anchorXRatio != null) 'anchorXRatio': footprint.anchorXRatio,
    if (footprint.anchorYRatio != null) 'anchorYRatio': footprint.anchorYRatio,
    if (footprint.footprintWidthRatio != null)
      'footprintWidthRatio': footprint.footprintWidthRatio,
    if (footprint.footprintHeightRatio != null)
      'footprintHeightRatio': footprint.footprintHeightRatio,
  };
}

StaticShadowFootprintConfig? decodeStaticShadowFootprintConfig(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is! Map) {
    throw ValidationException(
      'StaticShadowFootprintConfig JSON must be an Object or null, got ${json.runtimeType}',
    );
  }

  final map = _stringKeyMapFrom(json);
  final footprint = StaticShadowFootprintConfig(
    anchorXRatio: _optionalNullableDouble(
      map,
      'anchorXRatio',
      'StaticShadowFootprintConfig.anchorXRatio',
    ),
    anchorYRatio: _optionalNullableDouble(
      map,
      'anchorYRatio',
      'StaticShadowFootprintConfig.anchorYRatio',
    ),
    footprintWidthRatio: _optionalNullableDouble(
      map,
      'footprintWidthRatio',
      'StaticShadowFootprintConfig.footprintWidthRatio',
    ),
    footprintHeightRatio: _optionalNullableDouble(
      map,
      'footprintHeightRatio',
      'StaticShadowFootprintConfig.footprintHeightRatio',
    ),
  );

  return footprint.isEmpty ? null : footprint;
}
