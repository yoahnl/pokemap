import '../models/border_materialization.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import '../models/border_ground_variant_role.dart';
import 'border_json_codec_helpers.dart';

final BigInt _minimumSignedInt64 = BigInt.parse('-9223372036854775808');
final BigInt _maximumSignedInt64 = BigInt.parse('9223372036854775807');

final RegExp _snapshotIdPattern = RegExp(
  r'^border-snapshot-sha256:[0-9a-f]{64}$',
);
final RegExp _fingerprintPattern = RegExp(r'^sha256:[0-9a-f]{64}$');

const Set<String> _transformKeys = <String>{'quarterTurns', 'flipX'};
const Set<String> _pointKeys = <String>{'x', 'y'};
const Set<String> _rectKeys = <String>{'x', 'y', 'width', 'height'};
const Set<String> _orderKeyKeys = <String>{
  'drawBandIndex',
  'anchorRowMajor',
  'passIndex',
  'rank',
  'ordinalLocal',
  'slotKey',
};
const Set<String> _placementKeys = <String>{
  'id',
  'slotKey',
  'primitiveId',
  'visualSnapshotId',
  'anchorCell',
  'topLeftWorldPx',
  'opaqueWorldBoundsPx',
  'transform',
  'drawBand',
  'stableOrderKey',
};
const Set<String> _groundKeys = <String>{
  'x',
  'y',
  'visualSnapshotId',
  'resolvedRole',
};
const Set<String> _componentsKeys = <String>{
  'blueprint',
  'geometryAndSeed',
  'parameters',
  'overrides',
  'keepOutRegions',
  'mapContext',
  'visualSnapshots',
};
const Set<String> _receiptKeys = <String>{
  'resolverVersion',
  'blueprintRevision',
  'components',
  'inputFingerprint',
  'outputFingerprint',
};
const Set<String> _materializationKeys = <String>{
  'receipt',
  'ground',
  'placements',
};

/// Encodes a normalized pixel-art transform using strict JSON integers.
Map<String, Object?> encodeBorderSpriteTransformJson(
  BorderSpriteTransform transform, {
  String path = r'$',
}) {
  final turnsPath = borderJsonPropertyPath(path, 'quarterTurns');
  final quarterTurns = _encodeSignedInt64(transform.quarterTurns, turnsPath);
  if (quarterTurns < 0 || quarterTurns > 3) {
    throw FormatException('$turnsPath: must be between 0 and 3');
  }
  return <String, Object?>{
    'quarterTurns': quarterTurns,
    'flipX': transform.flipX,
  };
}

/// Decodes a strict normalized pixel-art transform.
BorderSpriteTransform decodeBorderSpriteTransformJson(
  Object? json, {
  String path = r'$',
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _transformKeys,
  );
  final turnsPath = borderJsonPropertyPath(path, 'quarterTurns');
  final quarterTurns = _decodeSignedInt64(
    borderJsonRequireField(value, 'quarterTurns', path),
    turnsPath,
  );
  if (quarterTurns < 0 || quarterTurns > 3) {
    throw FormatException('$turnsPath: must be between 0 and 3');
  }
  final flipX = borderJsonRequireBool(
    borderJsonRequireField(value, 'flipX', path),
    borderJsonPropertyPath(path, 'flipX'),
  );
  return borderJsonConstructAtPath(
    path,
    () => BorderSpriteTransform(quarterTurns: quarterTurns, flipX: flipX),
  );
}

/// Encodes one final persisted placement without resolving or reordering it.
Map<String, Object?> encodeBorderResolvedPlacementJson(
  BorderResolvedPlacement placement, {
  String path = r'$',
}) {
  final idPath = borderJsonPropertyPath(path, 'id');
  final slotKeyPath = borderJsonPropertyPath(path, 'slotKey');
  final primitiveIdPath = borderJsonPropertyPath(path, 'primitiveId');
  final snapshotPath = borderJsonPropertyPath(path, 'visualSnapshotId');
  _validateStableId(placement.id, idPath);
  _validateStableId(placement.slotKey, slotKeyPath);
  _validateStableId(placement.primitiveId, primitiveIdPath);
  _validateSnapshotId(placement.visualSnapshotId, snapshotPath);

  final drawBandName = _encodeDrawBand(placement.drawBand);
  final stableOrderPath = borderJsonPropertyPath(path, 'stableOrderKey');
  _validatePlacementConsistency(
    slotKey: placement.slotKey,
    drawBand: placement.drawBand,
    stableOrderKey: placement.stableOrderKey,
    stableOrderPath: stableOrderPath,
  );

  return <String, Object?>{
    'id': placement.id,
    'slotKey': placement.slotKey,
    'primitiveId': placement.primitiveId,
    'visualSnapshotId': placement.visualSnapshotId,
    'anchorCell': _encodeGridPos(
      placement.anchorCell,
      borderJsonPropertyPath(path, 'anchorCell'),
    ),
    'topLeftWorldPx': _encodePixelPos(
      placement.topLeftWorldPx,
      borderJsonPropertyPath(path, 'topLeftWorldPx'),
    ),
    'opaqueWorldBoundsPx': _encodePixelRect(
      placement.opaqueWorldBoundsPx,
      borderJsonPropertyPath(path, 'opaqueWorldBoundsPx'),
    ),
    'transform': encodeBorderSpriteTransformJson(
      placement.transform,
      path: borderJsonPropertyPath(path, 'transform'),
    ),
    'drawBand': drawBandName,
    'stableOrderKey': _encodeStableOrderKey(
      placement.stableOrderKey,
      stableOrderPath,
    ),
  };
}

/// Decodes one final persisted placement without catalog lookup.
BorderResolvedPlacement decodeBorderResolvedPlacementJson(
  Object? json, {
  String path = r'$',
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _placementKeys,
  );

  final idPath = borderJsonPropertyPath(path, 'id');
  final id = borderJsonRequireString(
    borderJsonRequireField(value, 'id', path),
    idPath,
  );
  _validateStableId(id, idPath);

  final slotKeyPath = borderJsonPropertyPath(path, 'slotKey');
  final slotKey = borderJsonRequireString(
    borderJsonRequireField(value, 'slotKey', path),
    slotKeyPath,
  );
  _validateStableId(slotKey, slotKeyPath);

  final primitiveIdPath = borderJsonPropertyPath(path, 'primitiveId');
  final primitiveId = borderJsonRequireString(
    borderJsonRequireField(value, 'primitiveId', path),
    primitiveIdPath,
  );
  _validateStableId(primitiveId, primitiveIdPath);

  final snapshotPath = borderJsonPropertyPath(path, 'visualSnapshotId');
  final visualSnapshotId = borderJsonRequireString(
    borderJsonRequireField(value, 'visualSnapshotId', path),
    snapshotPath,
  );
  _validateSnapshotId(visualSnapshotId, snapshotPath);

  final anchorPath = borderJsonPropertyPath(path, 'anchorCell');
  final anchorCell = _decodeGridPos(
    borderJsonRequireField(value, 'anchorCell', path),
    anchorPath,
  );
  final topLeftPath = borderJsonPropertyPath(path, 'topLeftWorldPx');
  final topLeftWorldPx = _decodePixelPos(
    borderJsonRequireField(value, 'topLeftWorldPx', path),
    topLeftPath,
  );
  final opaqueBoundsPath = borderJsonPropertyPath(path, 'opaqueWorldBoundsPx');
  final opaqueWorldBoundsPx = _decodePixelRect(
    borderJsonRequireField(value, 'opaqueWorldBoundsPx', path),
    opaqueBoundsPath,
  );
  final transformPath = borderJsonPropertyPath(path, 'transform');
  final transform = decodeBorderSpriteTransformJson(
    borderJsonRequireField(value, 'transform', path),
    path: transformPath,
  );
  final drawBandPath = borderJsonPropertyPath(path, 'drawBand');
  final drawBandName = borderJsonRequireString(
    borderJsonRequireField(value, 'drawBand', path),
    drawBandPath,
  );
  final drawBand = _decodeDrawBand(drawBandName, drawBandPath);
  final stableOrderPath = borderJsonPropertyPath(path, 'stableOrderKey');
  final stableOrderKey = _decodeStableOrderKey(
    borderJsonRequireField(value, 'stableOrderKey', path),
    stableOrderPath,
  );
  _validatePlacementConsistency(
    slotKey: slotKey,
    drawBand: drawBand,
    stableOrderKey: stableOrderKey,
    stableOrderPath: stableOrderPath,
  );

  return borderJsonConstructAtPath(
    path,
    () => BorderResolvedPlacement(
      id: id,
      slotKey: slotKey,
      primitiveId: primitiveId,
      visualSnapshotId: visualSnapshotId,
      anchorCell: anchorCell,
      topLeftWorldPx: topLeftWorldPx,
      opaqueWorldBoundsPx: opaqueWorldBoundsPx,
      transform: transform,
      drawBand: drawBand,
      stableOrderKey: stableOrderKey,
    ),
  );
}

/// Encodes final resolved output and its persisted receipt exactly as stored.
///
/// No fingerprint is recomputed and no catalog or snapshot is resolved here.
Map<String, Object?> encodeBorderMaterializationJson(
  BorderMaterialization materialization, {
  String path = r'$',
}) {
  final groundPath = borderJsonPropertyPath(path, 'ground');
  final placementPath = borderJsonPropertyPath(path, 'placements');
  if (materialization.ground.isEmpty && materialization.placements.isEmpty) {
    throw FormatException('$path: must contain ground or placements');
  }

  final ground = <Object?>[];
  final coordinates = <(int, int)>{};
  BorderResolvedGroundCell? previousGround;
  for (var index = 0; index < materialization.ground.length; index += 1) {
    final cell = materialization.ground[index];
    final cellPath = borderJsonIndexPath(groundPath, index);
    if (!coordinates.add((cell.x, cell.y))) {
      throw FormatException('$cellPath: duplicate ground coordinate');
    }
    final previous = previousGround;
    if (previous != null && _compareGround(previous, cell) > 0) {
      throw FormatException('$cellPath: ground must be ordered row-major');
    }
    ground.add(_encodeGroundCell(cell, cellPath));
    previousGround = cell;
  }

  final placements = <Object?>[];
  final placementIds = <String>{};
  final slotKeys = <String>{};
  BorderStableOrderKey? previousOrder;
  for (var index = 0; index < materialization.placements.length; index += 1) {
    final placement = materialization.placements[index];
    final itemPath = borderJsonIndexPath(placementPath, index);
    if (!placementIds.add(placement.id)) {
      throw FormatException(
        '${borderJsonPropertyPath(itemPath, 'id')}: duplicate placement id',
      );
    }
    if (!slotKeys.add(placement.slotKey)) {
      throw FormatException(
        '${borderJsonPropertyPath(itemPath, 'slotKey')}: '
        'duplicate placement slotKey',
      );
    }
    final previous = previousOrder;
    if (previous != null && previous.compareTo(placement.stableOrderKey) > 0) {
      throw FormatException(
        '${borderJsonPropertyPath(itemPath, 'stableOrderKey')}: '
        'placements must be ordered by stableOrderKey',
      );
    }
    placements.add(
      encodeBorderResolvedPlacementJson(placement, path: itemPath),
    );
    previousOrder = placement.stableOrderKey;
  }

  return <String, Object?>{
    'receipt': _encodeReceipt(
      materialization.receipt,
      borderJsonPropertyPath(path, 'receipt'),
    ),
    'ground': ground,
    'placements': placements,
  };
}

/// Decodes final resolved output while preserving persisted runtime order.
BorderMaterialization decodeBorderMaterializationJson(
  Object? json, {
  String path = r'$',
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _materializationKeys,
  );

  final receiptPath = borderJsonPropertyPath(path, 'receipt');
  final receipt = _decodeReceipt(
    borderJsonRequireField(value, 'receipt', path),
    receiptPath,
  );

  final groundPath = borderJsonPropertyPath(path, 'ground');
  final groundValues = borderJsonRequireList(
    borderJsonRequireField(value, 'ground', path),
    groundPath,
  );
  final ground = <BorderResolvedGroundCell>[];
  final coordinates = <(int, int)>{};
  BorderResolvedGroundCell? previousGround;
  for (var index = 0; index < groundValues.length; index += 1) {
    final cellPath = borderJsonIndexPath(groundPath, index);
    final cell = _decodeGroundCell(groundValues[index], cellPath);
    if (!coordinates.add((cell.x, cell.y))) {
      throw FormatException('$cellPath: duplicate ground coordinate');
    }
    final previous = previousGround;
    if (previous != null && _compareGround(previous, cell) > 0) {
      throw FormatException('$cellPath: ground must be ordered row-major');
    }
    ground.add(cell);
    previousGround = cell;
  }

  final placementsPath = borderJsonPropertyPath(path, 'placements');
  final placementValues = borderJsonRequireList(
    borderJsonRequireField(value, 'placements', path),
    placementsPath,
  );
  final placements = <BorderResolvedPlacement>[];
  final placementIds = <String>{};
  final slotKeys = <String>{};
  BorderStableOrderKey? previousOrder;
  for (var index = 0; index < placementValues.length; index += 1) {
    final placementPath = borderJsonIndexPath(placementsPath, index);
    final placement = decodeBorderResolvedPlacementJson(
      placementValues[index],
      path: placementPath,
    );
    if (!placementIds.add(placement.id)) {
      throw FormatException(
        '${borderJsonPropertyPath(placementPath, 'id')}: '
        'duplicate placement id',
      );
    }
    if (!slotKeys.add(placement.slotKey)) {
      throw FormatException(
        '${borderJsonPropertyPath(placementPath, 'slotKey')}: '
        'duplicate placement slotKey',
      );
    }
    final previous = previousOrder;
    if (previous != null && previous.compareTo(placement.stableOrderKey) > 0) {
      throw FormatException(
        '${borderJsonPropertyPath(placementPath, 'stableOrderKey')}: '
        'placements must be ordered by stableOrderKey',
      );
    }
    placements.add(placement);
    previousOrder = placement.stableOrderKey;
  }

  if (ground.isEmpty && placements.isEmpty) {
    throw FormatException('$path: must contain ground or placements');
  }
  return borderJsonConstructAtPath(
    path,
    () => BorderMaterialization(
      receipt: receipt,
      ground: ground,
      placements: placements,
    ),
  );
}

Map<String, Object?> _encodeReceipt(
  BorderResolutionReceipt receipt,
  String path,
) {
  final resolverPath = borderJsonPropertyPath(path, 'resolverVersion');
  final resolverVersion = _encodeSignedInt64(
    receipt.resolverVersion,
    resolverPath,
  );
  if (resolverVersion < 1) {
    throw FormatException('$resolverPath: must be >= 1');
  }
  final revisionPath = borderJsonPropertyPath(path, 'blueprintRevision');
  final blueprintRevision = _encodeSignedInt64(
    receipt.blueprintRevision,
    revisionPath,
  );
  if (blueprintRevision < 1) {
    throw FormatException('$revisionPath: must be >= 1');
  }
  final inputPath = borderJsonPropertyPath(path, 'inputFingerprint');
  final outputPath = borderJsonPropertyPath(path, 'outputFingerprint');
  _validateFingerprint(receipt.inputFingerprint, inputPath);
  _validateFingerprint(receipt.outputFingerprint, outputPath);

  return <String, Object?>{
    'resolverVersion': resolverVersion,
    'blueprintRevision': blueprintRevision,
    'components': _encodeComponents(
      receipt.components,
      borderJsonPropertyPath(path, 'components'),
    ),
    'inputFingerprint': receipt.inputFingerprint,
    'outputFingerprint': receipt.outputFingerprint,
  };
}

BorderResolutionReceipt _decodeReceipt(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _receiptKeys,
  );
  final resolverPath = borderJsonPropertyPath(path, 'resolverVersion');
  final resolverVersion = _decodeSignedInt64(
    borderJsonRequireField(value, 'resolverVersion', path),
    resolverPath,
  );
  if (resolverVersion < 1) {
    throw FormatException('$resolverPath: must be >= 1');
  }
  final revisionPath = borderJsonPropertyPath(path, 'blueprintRevision');
  final blueprintRevision = _decodeSignedInt64(
    borderJsonRequireField(value, 'blueprintRevision', path),
    revisionPath,
  );
  if (blueprintRevision < 1) {
    throw FormatException('$revisionPath: must be >= 1');
  }
  final componentsPath = borderJsonPropertyPath(path, 'components');
  final components = _decodeComponents(
    borderJsonRequireField(value, 'components', path),
    componentsPath,
  );
  final inputPath = borderJsonPropertyPath(path, 'inputFingerprint');
  final inputFingerprint = borderJsonRequireString(
    borderJsonRequireField(value, 'inputFingerprint', path),
    inputPath,
  );
  _validateFingerprint(inputFingerprint, inputPath);
  final outputPath = borderJsonPropertyPath(path, 'outputFingerprint');
  final outputFingerprint = borderJsonRequireString(
    borderJsonRequireField(value, 'outputFingerprint', path),
    outputPath,
  );
  _validateFingerprint(outputFingerprint, outputPath);

  return borderJsonConstructAtPath(
    path,
    () => BorderResolutionReceipt(
      resolverVersion: resolverVersion,
      blueprintRevision: blueprintRevision,
      components: components,
      inputFingerprint: inputFingerprint,
      outputFingerprint: outputFingerprint,
    ),
  );
}

Map<String, Object?> _encodeComponents(
  BorderInputFingerprints components,
  String path,
) {
  final entries = <(String, String)>[
    ('blueprint', components.blueprint),
    ('geometryAndSeed', components.geometryAndSeed),
    ('parameters', components.parameters),
    ('overrides', components.overrides),
    ('keepOutRegions', components.keepOutRegions),
    ('mapContext', components.mapContext),
    ('visualSnapshots', components.visualSnapshots),
  ];
  for (final (key, fingerprint) in entries) {
    _validateFingerprint(fingerprint, borderJsonPropertyPath(path, key));
  }
  return <String, Object?>{
    for (final (key, fingerprint) in entries) key: fingerprint,
  };
}

BorderInputFingerprints _decodeComponents(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _componentsKeys,
  );
  String decodeFingerprint(String key) {
    final fieldPath = borderJsonPropertyPath(path, key);
    final fingerprint = borderJsonRequireString(
      borderJsonRequireField(value, key, path),
      fieldPath,
    );
    _validateFingerprint(fingerprint, fieldPath);
    return fingerprint;
  }

  return borderJsonConstructAtPath(
    path,
    () => BorderInputFingerprints(
      blueprint: decodeFingerprint('blueprint'),
      geometryAndSeed: decodeFingerprint('geometryAndSeed'),
      parameters: decodeFingerprint('parameters'),
      overrides: decodeFingerprint('overrides'),
      keepOutRegions: decodeFingerprint('keepOutRegions'),
      mapContext: decodeFingerprint('mapContext'),
      visualSnapshots: decodeFingerprint('visualSnapshots'),
    ),
  );
}

Map<String, Object?> _encodeGroundCell(
  BorderResolvedGroundCell cell,
  String path,
) {
  final snapshotPath = borderJsonPropertyPath(path, 'visualSnapshotId');
  _validateSnapshotId(cell.visualSnapshotId, snapshotPath);
  return <String, Object?>{
    'x': _encodeSignedInt64(cell.x, borderJsonPropertyPath(path, 'x')),
    'y': _encodeSignedInt64(cell.y, borderJsonPropertyPath(path, 'y')),
    'visualSnapshotId': cell.visualSnapshotId,
    'resolvedRole': _encodeBorderGroundRole(cell.resolvedRole),
  };
}

BorderResolvedGroundCell _decodeGroundCell(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _groundKeys,
  );
  final x = _decodeSignedInt64(
    borderJsonRequireField(value, 'x', path),
    borderJsonPropertyPath(path, 'x'),
  );
  final y = _decodeSignedInt64(
    borderJsonRequireField(value, 'y', path),
    borderJsonPropertyPath(path, 'y'),
  );
  final snapshotPath = borderJsonPropertyPath(path, 'visualSnapshotId');
  final visualSnapshotId = borderJsonRequireString(
    borderJsonRequireField(value, 'visualSnapshotId', path),
    snapshotPath,
  );
  _validateSnapshotId(visualSnapshotId, snapshotPath);
  final rolePath = borderJsonPropertyPath(path, 'resolvedRole');
  final roleName = borderJsonRequireString(
    borderJsonRequireField(value, 'resolvedRole', path),
    rolePath,
  );
  final resolvedRole = _decodeBorderGroundRole(roleName, rolePath);

  return borderJsonConstructAtPath(
    path,
    () => BorderResolvedGroundCell(
      x: x,
      y: y,
      visualSnapshotId: visualSnapshotId,
      resolvedRole: resolvedRole,
    ),
  );
}

Map<String, Object?> _encodeStableOrderKey(
  BorderStableOrderKey key,
  String path,
) {
  _validateStableId(key.slotKey, borderJsonPropertyPath(path, 'slotKey'));
  final fields = <(String, int)>[
    ('drawBandIndex', key.drawBandIndex),
    ('anchorRowMajor', key.anchorRowMajor),
    ('passIndex', key.passIndex),
    ('rank', key.rank),
    ('ordinalLocal', key.ordinalLocal),
  ];
  final encoded = <String, Object?>{};
  for (final (name, raw) in fields) {
    final fieldPath = borderJsonPropertyPath(path, name);
    final value = _encodeSignedInt64(raw, fieldPath);
    if (value < 0) {
      throw FormatException('$fieldPath: must be >= 0');
    }
    encoded[name] = value;
  }
  encoded['slotKey'] = key.slotKey;
  return encoded;
}

BorderStableOrderKey _decodeStableOrderKey(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _orderKeyKeys,
  );
  int decodeNonNegative(String name) {
    final fieldPath = borderJsonPropertyPath(path, name);
    final decoded = _decodeSignedInt64(
      borderJsonRequireField(value, name, path),
      fieldPath,
    );
    if (decoded < 0) {
      throw FormatException('$fieldPath: must be >= 0');
    }
    return decoded;
  }

  final slotKeyPath = borderJsonPropertyPath(path, 'slotKey');
  final slotKey = borderJsonRequireString(
    borderJsonRequireField(value, 'slotKey', path),
    slotKeyPath,
  );
  _validateStableId(slotKey, slotKeyPath);
  return borderJsonConstructAtPath(
    path,
    () => BorderStableOrderKey(
      drawBandIndex: decodeNonNegative('drawBandIndex'),
      anchorRowMajor: decodeNonNegative('anchorRowMajor'),
      passIndex: decodeNonNegative('passIndex'),
      rank: decodeNonNegative('rank'),
      ordinalLocal: decodeNonNegative('ordinalLocal'),
      slotKey: slotKey,
    ),
  );
}

Map<String, Object?> _encodeGridPos(GridPos pos, String path) =>
    <String, Object?>{
      'x': _encodeSignedInt64(pos.x, borderJsonPropertyPath(path, 'x')),
      'y': _encodeSignedInt64(pos.y, borderJsonPropertyPath(path, 'y')),
    };

GridPos _decodeGridPos(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _pointKeys,
  );
  return GridPos(
    x: _decodeSignedInt64(
      borderJsonRequireField(value, 'x', path),
      borderJsonPropertyPath(path, 'x'),
    ),
    y: _decodeSignedInt64(
      borderJsonRequireField(value, 'y', path),
      borderJsonPropertyPath(path, 'y'),
    ),
  );
}

Map<String, Object?> _encodePixelPos(BorderPixelPos pos, String path) =>
    <String, Object?>{
      'x': _encodeSignedInt64(pos.x, borderJsonPropertyPath(path, 'x')),
      'y': _encodeSignedInt64(pos.y, borderJsonPropertyPath(path, 'y')),
    };

BorderPixelPos _decodePixelPos(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _pointKeys,
  );
  return BorderPixelPos(
    x: _decodeSignedInt64(
      borderJsonRequireField(value, 'x', path),
      borderJsonPropertyPath(path, 'x'),
    ),
    y: _decodeSignedInt64(
      borderJsonRequireField(value, 'y', path),
      borderJsonPropertyPath(path, 'y'),
    ),
  );
}

Map<String, Object?> _encodePixelRect(BorderPixelRect rect, String path) {
  final widthPath = borderJsonPropertyPath(path, 'width');
  final heightPath = borderJsonPropertyPath(path, 'height');
  final width = _encodeSignedInt64(rect.width, widthPath);
  final height = _encodeSignedInt64(rect.height, heightPath);
  if (width <= 0) {
    throw FormatException('$widthPath: must be > 0');
  }
  if (height <= 0) {
    throw FormatException('$heightPath: must be > 0');
  }
  return <String, Object?>{
    'x': _encodeSignedInt64(rect.x, borderJsonPropertyPath(path, 'x')),
    'y': _encodeSignedInt64(rect.y, borderJsonPropertyPath(path, 'y')),
    'width': width,
    'height': height,
  };
}

BorderPixelRect _decodePixelRect(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _rectKeys,
  );
  final x = _decodeSignedInt64(
    borderJsonRequireField(value, 'x', path),
    borderJsonPropertyPath(path, 'x'),
  );
  final y = _decodeSignedInt64(
    borderJsonRequireField(value, 'y', path),
    borderJsonPropertyPath(path, 'y'),
  );
  final widthPath = borderJsonPropertyPath(path, 'width');
  final width = _decodeSignedInt64(
    borderJsonRequireField(value, 'width', path),
    widthPath,
  );
  if (width <= 0) {
    throw FormatException('$widthPath: must be > 0');
  }
  final heightPath = borderJsonPropertyPath(path, 'height');
  final height = _decodeSignedInt64(
    borderJsonRequireField(value, 'height', path),
    heightPath,
  );
  if (height <= 0) {
    throw FormatException('$heightPath: must be > 0');
  }
  return borderJsonConstructAtPath(
    path,
    () => BorderPixelRect(
      x: x,
      y: y,
      width: width,
      height: height,
    ),
  );
}

void _validatePlacementConsistency({
  required String slotKey,
  required BorderDrawBand drawBand,
  required BorderStableOrderKey stableOrderKey,
  required String stableOrderPath,
}) {
  if (slotKey != stableOrderKey.slotKey) {
    throw FormatException(
      '${borderJsonPropertyPath(stableOrderPath, 'slotKey')}: '
      'must match placement slotKey',
    );
  }
  if (borderDrawBandV1Index(drawBand) != stableOrderKey.drawBandIndex) {
    throw FormatException(
      '${borderJsonPropertyPath(stableOrderPath, 'drawBandIndex')}: '
      'must match placement drawBand',
    );
  }
}

int _compareGround(
  BorderResolvedGroundCell first,
  BorderResolvedGroundCell second,
) {
  final row = first.y.compareTo(second.y);
  return row != 0 ? row : first.x.compareTo(second.x);
}

int _decodeSignedInt64(Object? value, String path) {
  final decoded = borderJsonRequireInt(value, path);
  _validateSignedInt64(decoded, path);
  return decoded;
}

int _encodeSignedInt64(int value, String path) {
  _validateSignedInt64(value, path);
  return value;
}

void _validateSignedInt64(int value, String path) {
  final exactValue = BigInt.from(value);
  if (exactValue < _minimumSignedInt64 || exactValue > _maximumSignedInt64) {
    throw FormatException('$path: must fit signed 64-bit range');
  }
}

void _validateStableId(String value, String path) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw FormatException('$path: must be nonblank and already trimmed');
  }
}

void _validateSnapshotId(String value, String path) {
  if (!_snapshotIdPattern.hasMatch(value)) {
    throw FormatException(
      '$path: must use border-snapshot-sha256:<64 lowercase hex>',
    );
  }
}

void _validateFingerprint(String value, String path) {
  if (!_fingerprintPattern.hasMatch(value)) {
    throw FormatException('$path: must use sha256:<64 lowercase hex>');
  }
}

String _encodeDrawBand(BorderDrawBand band) => switch (band) {
      BorderDrawBand.outerAccent => 'outerAccent',
      BorderDrawBand.structure => 'structure',
      BorderDrawBand.innerFinish => 'innerFinish',
      BorderDrawBand.accent => 'accent',
    };

BorderDrawBand _decodeDrawBand(String value, String path) => switch (value) {
      'outerAccent' => BorderDrawBand.outerAccent,
      'structure' => BorderDrawBand.structure,
      'innerFinish' => BorderDrawBand.innerFinish,
      'accent' => BorderDrawBand.accent,
      _ => throw FormatException('$path: unsupported Border draw band: $value'),
    };

String _encodeBorderGroundRole(BorderGroundVariantRole role) => switch (role) {
      BorderGroundVariantRole.isolated => 'isolated',
      BorderGroundVariantRole.endNorth => 'endNorth',
      BorderGroundVariantRole.endEast => 'endEast',
      BorderGroundVariantRole.endSouth => 'endSouth',
      BorderGroundVariantRole.endWest => 'endWest',
      BorderGroundVariantRole.horizontal => 'horizontal',
      BorderGroundVariantRole.vertical => 'vertical',
      BorderGroundVariantRole.cornerNE => 'cornerNE',
      BorderGroundVariantRole.cornerSE => 'cornerSE',
      BorderGroundVariantRole.cornerSW => 'cornerSW',
      BorderGroundVariantRole.cornerNW => 'cornerNW',
      BorderGroundVariantRole.innerCornerNE => 'innerCornerNE',
      BorderGroundVariantRole.innerCornerSE => 'innerCornerSE',
      BorderGroundVariantRole.innerCornerSW => 'innerCornerSW',
      BorderGroundVariantRole.innerCornerNW => 'innerCornerNW',
      BorderGroundVariantRole.teeNorth => 'teeNorth',
      BorderGroundVariantRole.teeEast => 'teeEast',
      BorderGroundVariantRole.teeSouth => 'teeSouth',
      BorderGroundVariantRole.teeWest => 'teeWest',
      BorderGroundVariantRole.cross => 'cross',
    };

BorderGroundVariantRole _decodeBorderGroundRole(String value, String path) =>
    switch (value) {
      'isolated' => BorderGroundVariantRole.isolated,
      'endNorth' => BorderGroundVariantRole.endNorth,
      'endEast' => BorderGroundVariantRole.endEast,
      'endSouth' => BorderGroundVariantRole.endSouth,
      'endWest' => BorderGroundVariantRole.endWest,
      'horizontal' => BorderGroundVariantRole.horizontal,
      'vertical' => BorderGroundVariantRole.vertical,
      'cornerNE' => BorderGroundVariantRole.cornerNE,
      'cornerSE' => BorderGroundVariantRole.cornerSE,
      'cornerSW' => BorderGroundVariantRole.cornerSW,
      'cornerNW' => BorderGroundVariantRole.cornerNW,
      'innerCornerNE' => BorderGroundVariantRole.innerCornerNE,
      'innerCornerSE' => BorderGroundVariantRole.innerCornerSE,
      'innerCornerSW' => BorderGroundVariantRole.innerCornerSW,
      'innerCornerNW' => BorderGroundVariantRole.innerCornerNW,
      'teeNorth' => BorderGroundVariantRole.teeNorth,
      'teeEast' => BorderGroundVariantRole.teeEast,
      'teeSouth' => BorderGroundVariantRole.teeSouth,
      'teeWest' => BorderGroundVariantRole.teeWest,
      'cross' => BorderGroundVariantRole.cross,
      _ => throw FormatException(
          '$path: unsupported Border ground role: $value',
        ),
    };
