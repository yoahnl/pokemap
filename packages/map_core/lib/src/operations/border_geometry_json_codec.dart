import '../models/border_geometry.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_json_codec_helpers.dart';
import 'border_rle_codec.dart';

const Set<String> _regionKeys = <String>{
  'kind',
  'width',
  'height',
  'cellsRle',
};
const Set<String> _strokeGeometryKeys = <String>{'kind', 'strokes'};
const Set<String> _strokeGeometryOptionalKeysV3 = <String>{'alignment'};
const Set<String> _strokeKeys = <String>{'id', 'points', 'closed'};
const Set<String> _pointKeys = <String>{'x', 'y'};
const Set<String> _keepOutKeys = <String>{'id', 'region'};

/// Encodes a persisted Border geometry using its strict V1 discriminated form.
///
/// Authored stroke and point order is preserved. This codec deliberately does
/// not canonicalize strokes or validate geometry against a map size.
Map<String, Object?> encodeBorderFeatureGeometryJson(
  BorderFeatureGeometry geometry, {
  String path = r'$',
  int formatVersion = 1,
}) {
  _requireSupportedGeometryFormatVersion(formatVersion, path);
  return switch (geometry) {
    BorderRegionGeometry() => _encodeRegionGeometry(geometry, path),
    BorderStrokeGeometry() =>
      _encodeStrokeGeometry(geometry, path, formatVersion),
  };
}

/// Decodes a strict V1 Border geometry without canonicalizing authored data.
BorderFeatureGeometry decodeBorderFeatureGeometryJson(
  Object? json, {
  String path = r'$',
  int formatVersion = 1,
}) {
  _requireSupportedGeometryFormatVersion(formatVersion, path);
  final value = borderJsonRequireObject(json, path);
  final kindPath = borderJsonPropertyPath(path, 'kind');
  final kind = borderJsonRequireString(
    borderJsonRequireField(value, 'kind', path),
    kindPath,
  );

  return switch (kind) {
    'region' => _decodeRegionGeometry(value, path),
    'stroke' => _decodeStrokeGeometry(value, path, formatVersion),
    _ => throw FormatException(
        '$kindPath: unsupported Border geometry kind: $kind',
      ),
  };
}

/// Encodes a keep-out with a stable ID and a discriminated nested region.
Map<String, Object?> encodeBorderKeepOutRegionJson(
  BorderKeepOutRegion keepOut, {
  String path = r'$',
}) {
  final idPath = borderJsonPropertyPath(path, 'id');
  _validateStableId(keepOut.id, idPath);
  return <String, Object?>{
    'id': keepOut.id,
    'region': _encodeRegionGeometry(
      keepOut.region,
      borderJsonPropertyPath(path, 'region'),
    ),
  };
}

/// Decodes a keep-out whose nested geometry must be a V1 region.
BorderKeepOutRegion decodeBorderKeepOutRegionJson(
  Object? json, {
  String path = r'$',
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _keepOutKeys,
  );

  final idPath = borderJsonPropertyPath(path, 'id');
  final id = borderJsonRequireString(
    borderJsonRequireField(value, 'id', path),
    idPath,
  );
  _validateStableId(id, idPath);

  final regionPath = borderJsonPropertyPath(path, 'region');
  final regionValue = borderJsonRequireObject(
    borderJsonRequireField(value, 'region', path),
    regionPath,
  );
  final region = _decodeRegionGeometry(regionValue, regionPath);

  return borderJsonConstructAtPath(
    path,
    () => BorderKeepOutRegion(id: id, region: region),
  );
}

Map<String, Object?> _encodeRegionGeometry(
  BorderRegionGeometry geometry,
  String path,
) {
  final expectedLength = checkedBorderRleCellCount(
    width: geometry.width,
    height: geometry.height,
    path: path,
  );
  if (geometry.cells.length != expectedLength) {
    throw FormatException(
      '${borderJsonPropertyPath(path, 'cellsRle')}: '
      'cell count does not match width and height',
    );
  }

  return <String, Object?>{
    'kind': 'region',
    'width': geometry.width,
    'height': geometry.height,
    'cellsRle': encodeBorderRleMask(geometry.cells),
  };
}

BorderRegionGeometry _decodeRegionGeometry(
  BorderJsonObject value,
  String path,
) {
  final kindPath = borderJsonPropertyPath(path, 'kind');
  final kind = borderJsonRequireString(
    borderJsonRequireField(value, 'kind', path),
    kindPath,
  );
  if (kind != 'region') {
    throw FormatException('$kindPath: expected region geometry');
  }
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _regionKeys,
  );

  final width = borderJsonRequireInt(
    borderJsonRequireField(value, 'width', path),
    borderJsonPropertyPath(path, 'width'),
  );
  final height = borderJsonRequireInt(
    borderJsonRequireField(value, 'height', path),
    borderJsonPropertyPath(path, 'height'),
  );
  final expectedLength = checkedBorderRleCellCount(
    width: width,
    height: height,
    path: path,
  );
  final cellsPath = borderJsonPropertyPath(path, 'cellsRle');
  final cells = decodeBorderRleMask(
    borderJsonRequireField(value, 'cellsRle', path),
    expectedLength: expectedLength,
    path: cellsPath,
  );

  return borderJsonConstructAtPath(
    path,
    () => BorderRegionGeometry(
      width: width,
      height: height,
      cells: cells,
    ),
  );
}

Map<String, Object?> _encodeStrokeGeometry(
  BorderStrokeGeometry geometry,
  String path,
  int formatVersion,
) {
  final alignmentPath = borderJsonPropertyPath(path, 'alignment');
  if (geometry.alignment == BorderStrokeAlignment.gridEdges &&
      formatVersion < 3) {
    throw FormatException(
      '$alignmentPath: requires Border layer format version 3',
    );
  }
  final strokesPath = borderJsonPropertyPath(path, 'strokes');
  return <String, Object?>{
    'kind': 'stroke',
    if (geometry.alignment != BorderStrokeAlignment.cellCenters)
      'alignment': borderStrokeAlignmentV1WireName(geometry.alignment),
    'strokes': <Object?>[
      for (var index = 0; index < geometry.strokes.length; index += 1)
        _encodeStroke(
          geometry.strokes[index],
          borderJsonIndexPath(strokesPath, index),
        ),
    ],
  };
}

Map<String, Object?> _encodeStroke(BorderStroke stroke, String path) {
  _validateStableId(stroke.id, borderJsonPropertyPath(path, 'id'));
  return <String, Object?>{
    'id': stroke.id,
    'points': <Object?>[
      for (final point in stroke.points)
        <String, Object?>{'x': point.x, 'y': point.y},
    ],
    'closed': stroke.closed,
  };
}

BorderStrokeGeometry _decodeStrokeGeometry(
  BorderJsonObject value,
  String path,
  int formatVersion,
) {
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _strokeGeometryKeys,
    optionalKeys:
        formatVersion >= 3 ? _strokeGeometryOptionalKeysV3 : const <String>{},
  );
  final alignmentPath = borderJsonPropertyPath(path, 'alignment');
  final alignmentValue = value['alignment'];
  final alignment = alignmentValue == null
      ? BorderStrokeAlignment.cellCenters
      : switch (borderJsonRequireString(alignmentValue, alignmentPath)) {
          'cellCenters' => BorderStrokeAlignment.cellCenters,
          'gridEdges' => BorderStrokeAlignment.gridEdges,
          _ => throw FormatException(
              '$alignmentPath: unknown Border stroke alignment',
            ),
        };
  final strokesPath = borderJsonPropertyPath(path, 'strokes');
  final strokeValues = borderJsonRequireList(
    borderJsonRequireField(value, 'strokes', path),
    strokesPath,
  );

  final strokes = <BorderStroke>[];
  final seenIds = <String>{};
  for (var index = 0; index < strokeValues.length; index += 1) {
    final strokePath = borderJsonIndexPath(strokesPath, index);
    final stroke = _decodeStroke(strokeValues[index], strokePath);
    if (!seenIds.add(stroke.id)) {
      throw FormatException(
        '${borderJsonPropertyPath(strokePath, 'id')}: duplicate stroke id',
      );
    }
    strokes.add(stroke);
  }

  return borderJsonConstructAtPath(
    strokesPath,
    () => BorderStrokeGeometry(strokes: strokes, alignment: alignment),
  );
}

void _requireSupportedGeometryFormatVersion(int value, String path) {
  if (value < 1 || value > 3) {
    throw FormatException('$path: unsupported Border geometry format version');
  }
}

BorderStroke _decodeStroke(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _strokeKeys,
  );

  final idPath = borderJsonPropertyPath(path, 'id');
  final id = borderJsonRequireString(
    borderJsonRequireField(value, 'id', path),
    idPath,
  );
  _validateStableId(id, idPath);

  final pointsPath = borderJsonPropertyPath(path, 'points');
  final pointValues = borderJsonRequireList(
    borderJsonRequireField(value, 'points', path),
    pointsPath,
  );
  final points = <GridPos>[];
  for (var index = 0; index < pointValues.length; index += 1) {
    points.add(
      _decodePoint(
        pointValues[index],
        borderJsonIndexPath(pointsPath, index),
      ),
    );
  }

  final closed = borderJsonRequireBool(
    borderJsonRequireField(value, 'closed', path),
    borderJsonPropertyPath(path, 'closed'),
  );

  return borderJsonConstructAtPath(
    path,
    () => BorderStroke(id: id, points: points, closed: closed),
  );
}

GridPos _decodePoint(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _pointKeys,
  );
  return GridPos(
    x: borderJsonRequireInt(
      borderJsonRequireField(value, 'x', path),
      borderJsonPropertyPath(path, 'x'),
    ),
    y: borderJsonRequireInt(
      borderJsonRequireField(value, 'y', path),
      borderJsonPropertyPath(path, 'y'),
    ),
  );
}

void _validateStableId(String value, String path) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw FormatException('$path: must be nonblank and already trimmed');
  }
}
