import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'project_building_shadow_preset_json_codec.dart';

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

/// Encodes an ordered ShadowV2 projected building shadow preset catalog.
Map<String, dynamic> encodeProjectBuildingShadowPresetCatalog(
  ProjectBuildingShadowPresetCatalog catalog,
) {
  return <String, dynamic>{
    'presets': <Object?>[
      for (final preset in catalog.presets)
        encodeProjectBuildingShadowPreset(preset),
    ],
  };
}

/// Decodes an ordered ShadowV2 projected building shadow preset catalog.
///
/// The catalog object must explicitly contain `presets`. Unknown catalog-level
/// keys are ignored; individual preset objects are delegated to the preset
/// codec so the preset contract remains centralized.
ProjectBuildingShadowPresetCatalog decodeProjectBuildingShadowPresetCatalog(
  Object? json,
) {
  final map = _requiredObject(json, 'ProjectBuildingShadowPresetCatalog');
  final rawPresets = _valueForRequiredKey(
    map,
    'presets',
    'ProjectBuildingShadowPresetCatalog.presets',
  );
  if (rawPresets is! List) {
    throw const ValidationException(
      'ProjectBuildingShadowPresetCatalog.presets must be a List',
    );
  }

  final presets = <ProjectBuildingShadowPreset>[];
  for (var index = 0; index < rawPresets.length; index += 1) {
    final item = rawPresets[index];
    if (item is! Map) {
      throw ValidationException(
        'ProjectBuildingShadowPresetCatalog.presets[$index] must be an Object',
      );
    }
    presets.add(decodeProjectBuildingShadowPreset(item));
  }

  return ProjectBuildingShadowPresetCatalog(presets: presets);
}
