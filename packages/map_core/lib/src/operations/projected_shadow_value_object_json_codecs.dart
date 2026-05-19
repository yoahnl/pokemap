import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';

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

double _requiredDouble(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  final result = value.toDouble();
  if (!result.isFinite) {
    throw ValidationException('$fieldKey must be finite');
  }
  return result;
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

/// Encodes the authored direction of a projected building shadow.
Map<String, dynamic> encodeProjectedShadowDirection(
  ProjectedShadowDirection direction,
) {
  return <String, dynamic>{
    'x': direction.x,
    'y': direction.y,
  };
}

/// Decodes the authored direction of a projected building shadow.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowDirection decodeProjectedShadowDirection(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowDirection');
  return ProjectedShadowDirection(
    x: _requiredDouble(map, 'x', 'ProjectedShadowDirection.x'),
    y: _requiredDouble(map, 'y', 'ProjectedShadowDirection.y'),
  );
}

/// Encodes the local asset anchor for a projected building shadow.
Map<String, dynamic> encodeProjectedShadowAnchor(
  ProjectedShadowAnchor anchor,
) {
  return <String, dynamic>{
    'xRatio': anchor.xRatio,
    'yRatio': anchor.yRatio,
  };
}

/// Decodes the local asset anchor for a projected building shadow.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowAnchor decodeProjectedShadowAnchor(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowAnchor');
  return ProjectedShadowAnchor(
    xRatio: _requiredDouble(map, 'xRatio', 'ProjectedShadowAnchor.xRatio'),
    yRatio: _requiredDouble(map, 'yRatio', 'ProjectedShadowAnchor.yRatio'),
  );
}

/// Encodes the local offset applied after anchor resolution.
Map<String, dynamic> encodeProjectedShadowOffset(
  ProjectedShadowOffset offset,
) {
  return <String, dynamic>{
    'x': offset.x,
    'y': offset.y,
  };
}

/// Decodes the local offset applied after anchor resolution.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowOffset decodeProjectedShadowOffset(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowOffset');
  return ProjectedShadowOffset(
    x: _requiredDouble(map, 'x', 'ProjectedShadowOffset.x'),
    y: _requiredDouble(map, 'y', 'ProjectedShadowOffset.y'),
  );
}

/// Encodes the parametric shape tuning for a projected building shadow.
Map<String, dynamic> encodeProjectedShadowShapeTuning(
  ProjectedShadowShapeTuning shape,
) {
  return <String, dynamic>{
    'lengthRatio': shape.lengthRatio,
    'nearWidthRatio': shape.nearWidthRatio,
    'farWidthRatio': shape.farWidthRatio,
  };
}

/// Decodes the parametric shape tuning for a projected building shadow.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowShapeTuning decodeProjectedShadowShapeTuning(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowShapeTuning');
  return ProjectedShadowShapeTuning(
    lengthRatio: _requiredDouble(
      map,
      'lengthRatio',
      'ProjectedShadowShapeTuning.lengthRatio',
    ),
    nearWidthRatio: _requiredDouble(
      map,
      'nearWidthRatio',
      'ProjectedShadowShapeTuning.nearWidthRatio',
    ),
    farWidthRatio: _requiredDouble(
      map,
      'farWidthRatio',
      'ProjectedShadowShapeTuning.farWidthRatio',
    ),
  );
}

/// Encodes the simple visual appearance of a projected building shadow.
Map<String, dynamic> encodeProjectedShadowAppearance(
  ProjectedShadowAppearance appearance,
) {
  return <String, dynamic>{
    'opacity': appearance.opacity,
    'colorHexRgb': appearance.colorHexRgb,
  };
}

/// Decodes the simple visual appearance of a projected building shadow.
///
/// Unknown keys are ignored. The value object normalizes color to uppercase.
ProjectedShadowAppearance decodeProjectedShadowAppearance(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowAppearance');
  return ProjectedShadowAppearance(
    opacity: _requiredDouble(
      map,
      'opacity',
      'ProjectedShadowAppearance.opacity',
    ),
    colorHexRgb: _requiredString(
      map,
      'colorHexRgb',
      'ProjectedShadowAppearance.colorHexRgb',
    ),
  );
}

/// Encodes the future time-of-day behavior flag.
String encodeProjectedShadowTimeOfDayMode(
  ProjectedShadowTimeOfDayMode mode,
) {
  return switch (mode) {
    ProjectedShadowTimeOfDayMode.fixed => 'fixed',
    ProjectedShadowTimeOfDayMode.followsSun => 'followsSun',
  };
}

/// Decodes the future time-of-day behavior flag.
///
/// Values are intentionally strict: no silent fallback and no case folding.
ProjectedShadowTimeOfDayMode decodeProjectedShadowTimeOfDayMode(Object? json) {
  if (json is! String) {
    throw ValidationException(
      'ProjectedShadowTimeOfDayMode must be a String, got ${json.runtimeType}',
    );
  }
  return switch (json) {
    'fixed' => ProjectedShadowTimeOfDayMode.fixed,
    'followsSun' => ProjectedShadowTimeOfDayMode.followsSun,
    _ => throw ValidationException(
        'ProjectedShadowTimeOfDayMode has unknown value "$json"',
      ),
  };
}
