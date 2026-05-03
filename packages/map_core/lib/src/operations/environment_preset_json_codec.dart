// JSON codec manuel (Lot Environment-5) — [EnvironmentPreset] / [EnvironmentPaletteItem] /
// [EnvironmentGenerationParams] pour [ProjectManifest.environmentPresets].
// Aucun toJson/fromJson sur les modèles Environment (classes finales hors Freezed).

import '../models/environment.dart';

Map<String, dynamic> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, dynamic>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value,
      ),
    ),
  );
}

void _assertNoDuplicatePresetIds(List<EnvironmentPreset> presets) {
  final seen = <String>{};
  for (final p in presets) {
    if (!seen.add(p.id)) {
      throw FormatException(
        'environmentPresets contains duplicate EnvironmentPreset id: ${p.id}',
      );
    }
  }
}

/// Décodage manifeste : clé absente ou `null` => liste vide.
List<EnvironmentPreset> decodeEnvironmentPresets(Object? json) {
  if (json == null) {
    return const [];
  }
  if (json is! List) {
    throw FormatException(
      'environmentPresets must be a List, got ${json.runtimeType}',
    );
  }
  final out = <EnvironmentPreset>[];
  for (var i = 0; i < json.length; i++) {
    final item = json[i];
    if (item is! Map) {
      throw FormatException(
        'environmentPresets[$i] must be a JSON object, got ${item.runtimeType}',
      );
    }
    out.add(decodeEnvironmentPreset(_stringKeyMapFrom(item)));
  }
  _assertNoDuplicatePresetIds(out);
  return out;
}

/// Encodage manifeste : liste de presets prête pour `project.json`.
List<Map<String, dynamic>> encodeEnvironmentPresets(
  List<EnvironmentPreset> presets,
) {
  return [
    for (final p in presets) encodeEnvironmentPreset(p),
  ];
}

/// JSON objet unique ; `null` est refusé (utiliser [decodeEnvironmentPresets] pour liste).
EnvironmentPreset decodeEnvironmentPreset(Object? json) {
  if (json == null || json is! Map) {
    throw FormatException(
      'EnvironmentPreset JSON must be a Map, got ${json.runtimeType}',
    );
  }
  final map = _stringKeyMapFrom(json);

  void requireKeys() {
    for (final key in <String>[
      'id',
      'name',
      'templateId',
      'palette',
      'defaultParams',
      'sortOrder',
    ]) {
      if (!map.containsKey(key)) {
        throw FormatException(
            'EnvironmentPreset JSON missing required key "$key"');
      }
    }
  }

  requireKeys();

  final id = map['id'];
  final name = map['name'];
  final templateId = map['templateId'];
  if (id is! String || name is! String || templateId is! String) {
    throw FormatException(
      'EnvironmentPreset id, name, templateId must be non-null Strings',
    );
  }

  final rawPalette = map['palette'];
  if (rawPalette is! List) {
    throw FormatException(
      'EnvironmentPreset.palette must be a List, got ${rawPalette.runtimeType}',
    );
  }
  final palette = <EnvironmentPaletteItem>[];
  for (var i = 0; i < rawPalette.length; i++) {
    final e = rawPalette[i];
    palette.add(decodeEnvironmentPaletteItem(e));
  }

  final rawDefault = map['defaultParams'];
  if (rawDefault is! Map) {
    throw FormatException(
      'EnvironmentPreset.defaultParams must be a Map, got ${rawDefault.runtimeType}',
    );
  }
  final defaultParams = decodeEnvironmentGenerationParamsJson(rawDefault);

  final rawCategory = map['categoryId'];
  final String? categoryId;
  if (rawCategory == null) {
    categoryId = null;
  } else if (rawCategory is String) {
    categoryId = rawCategory;
  } else {
    throw FormatException(
      'EnvironmentPreset.categoryId must be a String or null, got ${rawCategory.runtimeType}',
    );
  }

  final sortOrder = _requireIntStrict(
    Map<String, dynamic>.from(map),
    'sortOrder',
    fieldLabel: 'EnvironmentPreset.sortOrder',
  );

  try {
    return EnvironmentPreset(
      id: id,
      name: name,
      templateId: templateId,
      palette: palette,
      defaultParams: defaultParams,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentPreset: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentPreset(EnvironmentPreset preset) {
  final out = <String, dynamic>{
    'id': preset.id,
    'name': preset.name,
    'templateId': preset.templateId,
    'palette': [
      for (final item in preset.palette) encodeEnvironmentPaletteItem(item),
    ],
    'defaultParams':
        encodeEnvironmentGenerationParamsJson(preset.defaultParams),
    'sortOrder': preset.sortOrder,
  };
  if (preset.categoryId != null) {
    out['categoryId'] = preset.categoryId;
  }
  return out;
}

EnvironmentPaletteItem decodeEnvironmentPaletteItem(Object? json) {
  if (json == null || json is! Map) {
    throw FormatException(
      'EnvironmentPaletteItem JSON must be a Map, got ${json.runtimeType}',
    );
  }
  final map = _stringKeyMapFrom(json);
  if (!map.containsKey('elementId') || !map.containsKey('weight')) {
    throw FormatException(
      'EnvironmentPaletteItem JSON missing elementId or weight',
    );
  }
  final elementId = map['elementId'];
  final weightRaw = map['weight'];
  if (elementId is! String) {
    throw FormatException('EnvironmentPaletteItem.elementId must be a String');
  }
  if (weightRaw is! int) {
    throw FormatException(
      'EnvironmentPaletteItem.weight must be a strict int (got ${weightRaw.runtimeType})',
    );
  }

  final rawMode = map['collisionMode'];
  final EnvironmentCollisionMode collisionMode;
  if (rawMode == null) {
    collisionMode = EnvironmentCollisionMode.useElementDefault;
  } else if (rawMode is String) {
    collisionMode = _decodeCollisionMode(rawMode);
  } else {
    throw FormatException(
      'EnvironmentPaletteItem.collisionMode must be a String or null',
    );
  }

  final rawTags = map['tags'];
  final Set<String>? tags;
  if (rawTags == null) {
    tags = null;
  } else if (rawTags is List) {
    tags = <String>{};
    for (var i = 0; i < rawTags.length; i++) {
      final t = rawTags[i];
      if (t is! String) {
        throw FormatException(
          'EnvironmentPaletteItem.tags[$i] must be a String',
        );
      }
      tags.add(t);
    }
  } else {
    throw FormatException(
      'EnvironmentPaletteItem.tags must be a List or null, got ${rawTags.runtimeType}',
    );
  }

  try {
    return EnvironmentPaletteItem(
      elementId: elementId,
      weight: weightRaw,
      collisionMode: collisionMode,
      tags: tags,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentPaletteItem: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentPaletteItem(EnvironmentPaletteItem item) {
  final tagsList = item.tags.toList()..sort();
  return <String, dynamic>{
    'elementId': item.elementId,
    'weight': item.weight,
    'collisionMode': _collisionModeToJson(item.collisionMode),
    'tags': tagsList,
  };
}

EnvironmentCollisionMode _decodeCollisionMode(String value) {
  switch (value) {
    case 'useElementDefault':
      return EnvironmentCollisionMode.useElementDefault;
    case 'forceEnabled':
      return EnvironmentCollisionMode.forceEnabled;
    case 'forceDisabled':
      return EnvironmentCollisionMode.forceDisabled;
    default:
      throw FormatException(
          'Unknown EnvironmentPaletteItem.collisionMode: $value');
  }
}

String _collisionModeToJson(EnvironmentCollisionMode mode) {
  switch (mode) {
    case EnvironmentCollisionMode.useElementDefault:
      return 'useElementDefault';
    case EnvironmentCollisionMode.forceEnabled:
      return 'forceEnabled';
    case EnvironmentCollisionMode.forceDisabled:
      return 'forceDisabled';
  }
}

/// Même contrat strict que le codec Environment Layer (Ent. 4-review) :
/// densités : `int` ou `double` JSON ; `minSpacingCells` : littéral `int` uniquement.
EnvironmentGenerationParams decodeEnvironmentGenerationParamsJson(
    Object? json) {
  if (json == null || json is! Map) {
    throw FormatException(
      'EnvironmentGenerationParams JSON must be a Map, got ${json.runtimeType}',
    );
  }
  final map = _stringKeyMapFrom(json);
  try {
    return EnvironmentGenerationParams(
      density: _requireDoubleUnit(map, 'density'),
      variation: _requireDoubleUnit(map, 'variation'),
      edgeDensity: _requireDoubleUnit(map, 'edgeDensity'),
      minSpacingCells: _requireIntStrict(
        map,
        'minSpacingCells',
        fieldLabel: 'EnvironmentGenerationParams.minSpacingCells',
      ),
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentGenerationParams: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentGenerationParamsJson(
  EnvironmentGenerationParams params,
) {
  return <String, dynamic>{
    'density': params.density,
    'variation': params.variation,
    'edgeDensity': params.edgeDensity,
    'minSpacingCells': params.minSpacingCells,
  };
}

double _requireDoubleUnit(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is double) {
    return v;
  }
  if (v is int) {
    return v.toDouble();
  }
  throw FormatException(
    'Missing or invalid num for key "$key" (expected int or double, got ${v.runtimeType})',
  );
}

int _requireIntStrict(
  Map<String, dynamic> json,
  String key, {
  required String fieldLabel,
}) {
  final v = json[key];
  if (v is int) {
    return v;
  }
  throw FormatException(
    'Missing or invalid strict int for $fieldLabel (got ${v.runtimeType})',
  );
}
