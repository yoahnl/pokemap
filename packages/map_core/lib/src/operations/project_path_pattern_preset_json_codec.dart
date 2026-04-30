// JSON codec manuel — [ProjectPathPatternPreset].
//
// Persistance PathPattern externe au modèle : aucune méthode toJson/fromJson
// sur [ProjectPathPatternPreset]. Le codec réutilise le format généré existant
// de TilesetVisualFrame pour éviter un second schéma de frame.

import '../exceptions/map_exceptions.dart';
import '../models/path_center_pattern.dart';
import '../models/project_manifest.dart';
import '../models/project_path_pattern_preset.dart';
import '../models/tileset_transparent_color.dart';

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

Object? _valueForRequiredKey(
  Map<String, dynamic> json,
  String key,
  String errorPrefix,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$errorPrefix is required');
  }
  return json[key];
}

String _requiredString(
  Map<String, dynamic> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

int _requiredInt(
  Map<String, dynamic> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! int) {
    throw ValidationException('$fieldKey must be an int');
  }
  return value;
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! Map) {
    throw ValidationException('$fieldKey must be an Object');
  }
  return _stringKeyMapFrom(value);
}

List<dynamic> _requiredList(
  Map<String, dynamic> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! List) {
    throw ValidationException('$fieldKey must be a List');
  }
  return value;
}

String? _optionalString(
  Map<String, dynamic> json,
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

/// Encodes a [ProjectPathPatternPreset] using the external PathPattern V0 JSON.
Map<String, dynamic> encodeProjectPathPatternPreset(
  ProjectPathPatternPreset preset,
) {
  final out = <String, dynamic>{
    'id': preset.id,
    'name': preset.name,
    'basePathPresetId': preset.basePathPresetId,
    'centerPattern': _encodePathCenterPattern(preset.centerPattern),
    'sortOrder': preset.sortOrder,
  };
  if (preset.transparentColor != null) {
    out['transparentColor'] = preset.transparentColor!.toHexRgb();
  }
  if (preset.categoryId != null) {
    out['categoryId'] = preset.categoryId;
  }
  return out;
}

/// Decodes a [ProjectPathPatternPreset] from the external PathPattern V0 JSON.
ProjectPathPatternPreset decodeProjectPathPatternPreset(
  Map<String, dynamic> json,
) {
  final transparentColorHex = _optionalString(
    json,
    'transparentColor',
    'ProjectPathPatternPreset.transparentColor',
  );

  return ProjectPathPatternPreset(
    id: _requiredString(json, 'id', 'ProjectPathPatternPreset.id'),
    name: _requiredString(json, 'name', 'ProjectPathPatternPreset.name'),
    basePathPresetId: _requiredString(
      json,
      'basePathPresetId',
      'ProjectPathPatternPreset.basePathPresetId',
    ),
    centerPattern: _decodePathCenterPattern(
      _requiredMap(
        json,
        'centerPattern',
        'ProjectPathPatternPreset.centerPattern',
      ),
    ),
    transparentColor: transparentColorHex == null
        ? null
        : _decodeTransparentColor(transparentColorHex),
    categoryId: _optionalString(
      json,
      'categoryId',
      'ProjectPathPatternPreset.categoryId',
    ),
    sortOrder: _requiredInt(
      json,
      'sortOrder',
      'ProjectPathPatternPreset.sortOrder',
    ),
  );
}

/// Encodes a manifest-level list of PathPattern presets.
List<Map<String, dynamic>> encodeProjectPathPatternPresets(
  List<ProjectPathPatternPreset> presets,
) {
  return [
    for (final preset in presets) encodeProjectPathPatternPreset(preset),
  ];
}

/// Decodes a manifest-level list of PathPattern presets.
///
/// Missing or `null` manifest fields are interpreted as an empty list so old
/// project manifests stay compatible.
List<ProjectPathPatternPreset> decodeProjectPathPatternPresets(Object? json) {
  if (json == null) {
    return const [];
  }
  if (json is! List) {
    throw const ValidationException('pathPatternPresets must be a List');
  }

  final presets = <ProjectPathPatternPreset>[];
  for (var index = 0; index < json.length; index += 1) {
    final item = json[index];
    if (item is! Map) {
      throw ValidationException('pathPatternPresets[$index] must be an Object');
    }
    presets.add(decodeProjectPathPatternPreset(_stringKeyMapFrom(item)));
  }
  return presets;
}

Map<String, dynamic> _encodePathCenterPattern(PathCenterPattern pattern) {
  return <String, dynamic>{
    'size': _encodePathCenterPatternSize(pattern.size),
    'cells': <Object?>[
      for (final cell in pattern.cells) _encodePathCenterPatternCell(cell),
    ],
  };
}

PathCenterPattern _decodePathCenterPattern(Map<String, dynamic> json) {
  final cellsRaw = _requiredList(
    json,
    'cells',
    'PathCenterPattern.cells',
  );

  final cells = <PathCenterPatternCell>[];
  for (var index = 0; index < cellsRaw.length; index += 1) {
    final item = cellsRaw[index];
    if (item is! Map) {
      throw ValidationException(
          'PathCenterPattern.cells[$index] must be an Object');
    }
    cells.add(
      _decodePathCenterPatternCell(_stringKeyMapFrom(item), index),
    );
  }

  return PathCenterPattern(
    size: _decodePathCenterPatternSize(
      _requiredMap(json, 'size', 'PathCenterPattern.size'),
    ),
    cells: cells,
  );
}

Map<String, dynamic> _encodePathCenterPatternSize(
  PathCenterPatternSize size,
) {
  return <String, dynamic>{
    'width': size.width,
    'height': size.height,
  };
}

PathCenterPatternSize _decodePathCenterPatternSize(
  Map<String, dynamic> json,
) {
  return PathCenterPatternSize(
    width: _requiredInt(json, 'width', 'PathCenterPattern.size.width'),
    height: _requiredInt(json, 'height', 'PathCenterPattern.size.height'),
  );
}

Map<String, dynamic> _encodePathCenterPatternCell(
  PathCenterPatternCell cell,
) {
  return <String, dynamic>{
    'localX': cell.localX,
    'localY': cell.localY,
    'frames': <Object?>[
      for (final frame in cell.frames) _encodeTilesetVisualFrame(frame),
    ],
  };
}

PathCenterPatternCell _decodePathCenterPatternCell(
  Map<String, dynamic> json,
  int cellIndex,
) {
  final framesRaw = _requiredList(
    json,
    'frames',
    'PathCenterPattern.cells[$cellIndex].frames',
  );
  final frames = <TilesetVisualFrame>[];
  for (var index = 0; index < framesRaw.length; index += 1) {
    final item = framesRaw[index];
    if (item is! Map) {
      throw ValidationException(
        'PathCenterPattern.cells[$cellIndex].frames[$index] must be an Object',
      );
    }
    frames.add(
      _decodeTilesetVisualFrame(_stringKeyMapFrom(item), cellIndex, index),
    );
  }

  return PathCenterPatternCell(
    localX: _requiredInt(
      json,
      'localX',
      'PathCenterPattern.cells[$cellIndex].localX',
    ),
    localY: _requiredInt(
      json,
      'localY',
      'PathCenterPattern.cells[$cellIndex].localY',
    ),
    frames: frames,
  );
}

Map<String, dynamic> _encodeTilesetVisualFrame(TilesetVisualFrame frame) {
  return frame.toJson();
}

TilesetVisualFrame _decodeTilesetVisualFrame(
  Map<String, dynamic> json,
  int cellIndex,
  int frameIndex,
) {
  final source = _valueForRequiredKey(
    json,
    'source',
    'PathCenterPattern.cells[$cellIndex].frames[$frameIndex].source',
  );
  if (source is! Map) {
    throw ValidationException(
      'PathCenterPattern.cells[$cellIndex].frames[$frameIndex].source '
      'must be an Object',
    );
  }

  final normalized = Map<String, dynamic>.from(json);
  normalized['source'] = _stringKeyMapFrom(source);

  try {
    return TilesetVisualFrame.fromJson(normalized);
  } on Object catch (error) {
    throw ValidationException(
      'PathCenterPattern.cells[$cellIndex].frames[$frameIndex] '
      'must be a TilesetVisualFrame JSON object: $error',
    );
  }
}

TilesetTransparentColor _decodeTransparentColor(String value) {
  try {
    return TilesetTransparentColor.fromHexRgb(value);
  } on ArgumentError catch (error) {
    throw ValidationException(
      'ProjectPathPatternPreset.transparentColor must be an RGB hex string: '
      '$error',
    );
  }
}
