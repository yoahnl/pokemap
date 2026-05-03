import '../models/environment.dart';

/// Codec JSON pour [EnvironmentLayerContent] et sous-structures (Lot Environment-4).
/// Les [EnvironmentPreset] restent hors périmètre manifest / carte.
///
/// Lot Environment-4-review : JSON strict (`targetTileLayerId` non vide si présent,
/// entiers JSON typés `int` uniquement pour les champs entiers, placements typés et uniques).
EnvironmentLayerContent decodeEnvironmentLayerContent(Object? json) {
  if (json == null) {
    return EnvironmentLayerContent.emptyContent;
  }
  if (json is! Map) {
    throw FormatException(
      'EnvironmentLayerContent JSON must be a Map or null, got ${json.runtimeType}',
    );
  }
  final map = Map<String, dynamic>.from(json);

  final rawTarget = map['targetTileLayerId'];
  final String? targetTileLayerId;
  if (rawTarget == null) {
    targetTileLayerId = null;
  } else if (rawTarget is String) {
    final t = rawTarget.trim();
    if (t.isEmpty) {
      throw FormatException(
        'EnvironmentLayerContent targetTileLayerId cannot be empty or whitespace-only when provided',
      );
    }
    targetTileLayerId = t;
  } else {
    throw FormatException(
      'EnvironmentLayerContent targetTileLayerId must be a String or null',
    );
  }

  final rawAreas = map['areas'];
  final List<EnvironmentArea> areas;
  if (rawAreas == null) {
    areas = const [];
  } else if (rawAreas is List) {
    areas = <EnvironmentArea>[];
    for (var i = 0; i < rawAreas.length; i++) {
      final e = rawAreas[i];
      areas.add(
        decodeEnvironmentArea(_requireMap(e, 'areas[$i]')),
      );
    }
  } else {
    throw FormatException(
      'EnvironmentLayerContent areas must be a List or null, got ${rawAreas.runtimeType}',
    );
  }

  try {
    return EnvironmentLayerContent(
      targetTileLayerId: targetTileLayerId,
      areas: areas,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentLayerContent: ${e.message}');
  }
}

/// JSON compatible `json_serializable` / persistance carte.
Map<String, dynamic> encodeEnvironmentLayerContent(
  EnvironmentLayerContent content,
) {
  return <String, dynamic>{
    if (content.targetTileLayerId != null)
      'targetTileLayerId': content.targetTileLayerId,
    'areas': content.areas.map(encodeEnvironmentArea).toList(growable: false),
  };
}

EnvironmentArea decodeEnvironmentArea(Map<String, dynamic> json) {
  try {
    final id = _requireString(json, 'id');
    final name = _requireString(json, 'name');
    final presetId = _requireString(json, 'presetId');
    final mask = decodeEnvironmentAreaMask(
      _requireMap(json['mask'], 'mask'),
    );
    final seed = _requireIntStrict(json, 'seed');

    final rawOverride = json['paramsOverride'];
    final EnvironmentGenerationParams? paramsOverride;
    if (rawOverride == null) {
      paramsOverride = null;
    } else {
      paramsOverride = decodeEnvironmentGenerationParams(
        _requireMap(rawOverride, 'paramsOverride'),
      );
    }

    final rawPlacementIds = json['generatedPlacementIds'];
    final List<String>? generatedPlacementIds =
        _decodeGeneratedPlacementIdsField(rawPlacementIds);

    return EnvironmentArea(
      id: id,
      name: name,
      presetId: presetId,
      mask: mask,
      seed: seed,
      paramsOverride: paramsOverride,
      generatedPlacementIds: generatedPlacementIds,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentArea: ${e.message}');
  }
}

/// `null` ou liste ; IDs trimés, non vides, sans doublon (aligné sur [EnvironmentArea]).
List<String>? _decodeGeneratedPlacementIdsField(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is! List) {
    throw FormatException(
      'generatedPlacementIds must be a List or null, got ${raw.runtimeType}',
    );
  }
  final seen = <String>{};
  final out = <String>[];
  for (var i = 0; i < raw.length; i++) {
    final e = raw[i];
    if (e is! String) {
      throw FormatException(
        'generatedPlacementIds[$i] must be a String, got ${e.runtimeType}',
      );
    }
    final t = e.trim();
    if (t.isEmpty) {
      throw FormatException(
        'generatedPlacementIds[$i] cannot be empty or whitespace-only',
      );
    }
    if (!seen.add(t)) {
      throw FormatException(
        'generatedPlacementIds contains duplicate placement id: $t',
      );
    }
    out.add(t);
  }
  return out;
}

Map<String, dynamic> encodeEnvironmentArea(EnvironmentArea area) {
  return <String, dynamic>{
    'id': area.id,
    'name': area.name,
    'presetId': area.presetId,
    'mask': encodeEnvironmentAreaMask(area.mask),
    'seed': area.seed,
    if (area.paramsOverride != null)
      'paramsOverride': encodeEnvironmentGenerationParams(area.paramsOverride!),
    'generatedPlacementIds': area.generatedPlacementIds.toList(growable: false),
  };
}

EnvironmentAreaMask decodeEnvironmentAreaMask(Map<String, dynamic> json) {
  try {
    final width = _requireIntStrict(json, 'width');
    final height = _requireIntStrict(json, 'height');
    final rawCells = json['cells'];
    if (rawCells is! List) {
      throw FormatException(
        'EnvironmentAreaMask cells must be a List, got ${rawCells.runtimeType}',
      );
    }
    final cells = rawCells.map((e) {
      if (e is! bool) {
        throw FormatException(
          'EnvironmentAreaMask cells must be List<bool>, got element ${e.runtimeType}',
        );
      }
      return e;
    }).toList(growable: false);

    return EnvironmentAreaMask(
      width: width,
      height: height,
      cells: cells,
    );
  } on ArgumentError catch (e) {
    throw FormatException('Invalid EnvironmentAreaMask: ${e.message}');
  }
}

Map<String, dynamic> encodeEnvironmentAreaMask(EnvironmentAreaMask mask) {
  return <String, dynamic>{
    'width': mask.width,
    'height': mask.height,
    'cells': mask.cells.toList(growable: false),
  };
}

EnvironmentGenerationParams decodeEnvironmentGenerationParams(
  Map<String, dynamic> json,
) {
  try {
    return EnvironmentGenerationParams(
      density: _requireDoubleUnit(json, 'density'),
      variation: _requireDoubleUnit(json, 'variation'),
      edgeDensity: _requireDoubleUnit(json, 'edgeDensity'),
      minSpacingCells: _requireIntStrict(json, 'minSpacingCells'),
    );
  } on ArgumentError catch (e) {
    throw FormatException(
      'Invalid EnvironmentGenerationParams: ${e.message}',
    );
  }
}

/// Double ou entier JSON pour les paramètres \[0,1\] ; rejette les doubles non entiers
/// ambigus pour les champs qui doivent être entiers (voir [_requireIntStrict]).
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

Map<String, dynamic> encodeEnvironmentGenerationParams(
  EnvironmentGenerationParams params,
) {
  return <String, dynamic>{
    'density': params.density,
    'variation': params.variation,
    'edgeDensity': params.edgeDensity,
    'minSpacingCells': params.minSpacingCells,
  };
}

Map<String, dynamic> _requireMap(Object? value, String field) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  throw FormatException('$field must be a Map, got ${value.runtimeType}');
}

String _requireString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String) {
    return v;
  }
  throw FormatException('Missing or invalid String for key "$key"');
}

/// JSON strict : seuls les littéraux entiers Dart (`int`) sont acceptés — pas de `double`,
/// pour éviter une troncature silencieuse (ex. 1.9 → 1).
int _requireIntStrict(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is int) {
    return v;
  }
  throw FormatException(
    'Missing or invalid strict int for key "$key" (got ${v.runtimeType})',
  );
}
