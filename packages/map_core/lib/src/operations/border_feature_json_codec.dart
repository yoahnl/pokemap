import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_value_objects.dart';
import 'border_blueprint_json_codec.dart';
import 'border_geometry_json_codec.dart';
import 'border_json_codec_helpers.dart';
import 'border_materialization_json_codec.dart';

final BigInt _minimumSignedInt64 = BigInt.parse('-9223372036854775808');
final BigInt _maximumSignedInt64 = BigInt.parse('9223372036854775807');

const Set<String> _featureRequiredKeys = <String>{
  'id',
  'name',
  'blueprintId',
  'seed',
  'geometry',
  'overrides',
  'keepOutRegions',
};
const Set<String> _featureOptionalKeys = <String>{
  'paramsOverride',
  'materialization',
};
const Set<String> _overrideRequiredKeys = <String>{
  'slotKey',
  'variationSalt',
  'suppressed',
  'locked',
};
const Set<String> _overrideOptionalKeys = <String>{
  'lockedPlacement',
  'replacementPrimitiveId',
  'offsetDeltaPx',
  'transformOverride',
};
const Set<String> _offsetKeys = <String>{'x', 'y'};

/// Encodes one persisted Border feature without resolving any references.
///
/// Null optional fields are omitted. Geometry, overrides, keep-outs, and the
/// already-resolved materialization retain their authored list order.
Map<String, Object?> encodeBorderFeatureJson(
  BorderFeature feature, {
  String path = r'$',
}) {
  _validateStableText(feature.id, borderJsonPropertyPath(path, 'id'));
  _validateStableText(feature.name, borderJsonPropertyPath(path, 'name'));
  _validateStableText(
    feature.blueprintId,
    borderJsonPropertyPath(path, 'blueprintId'),
  );

  final overridesPath = borderJsonPropertyPath(path, 'overrides');
  final encodedOverrides = <Object?>[];
  final overrideSlots = <String>{};
  for (var index = 0; index < feature.overrides.length; index += 1) {
    final override = feature.overrides[index];
    final overridePath = borderJsonIndexPath(overridesPath, index);
    if (!overrideSlots.add(override.slotKey)) {
      throw FormatException(
        '${borderJsonPropertyPath(overridePath, 'slotKey')}: '
        'duplicate override slotKey',
      );
    }
    encodedOverrides.add(_encodeOverride(override, overridePath));
  }

  final keepOutsPath = borderJsonPropertyPath(path, 'keepOutRegions');
  final encodedKeepOuts = <Object?>[];
  final keepOutIds = <String>{};
  for (var index = 0; index < feature.keepOutRegions.length; index += 1) {
    final keepOut = feature.keepOutRegions[index];
    final keepOutPath = borderJsonIndexPath(keepOutsPath, index);
    if (!keepOutIds.add(keepOut.id)) {
      throw FormatException(
        '${borderJsonPropertyPath(keepOutPath, 'id')}: '
        'duplicate keep-out id',
      );
    }
    encodedKeepOuts.add(
      encodeBorderKeepOutRegionJson(keepOut, path: keepOutPath),
    );
  }

  final params = feature.paramsOverride;
  final materialization = feature.materialization;
  return <String, Object?>{
    'id': feature.id,
    'name': feature.name,
    'blueprintId': feature.blueprintId,
    'seed': borderJsonEncodeSignedInt64(feature.seed),
    'geometry': encodeBorderFeatureGeometryJson(
      feature.geometry,
      path: borderJsonPropertyPath(path, 'geometry'),
    ),
    if (params != null)
      'paramsOverride': encodeBorderGenerationParamsJson(
        params,
        path: borderJsonPropertyPath(path, 'paramsOverride'),
      ),
    'overrides': encodedOverrides,
    'keepOutRegions': encodedKeepOuts,
    if (materialization != null)
      'materialization': encodeBorderMaterializationJson(
        materialization,
        path: borderJsonPropertyPath(path, 'materialization'),
      ),
  };
}

/// Decodes one strict Border feature while keeping dangling references valid.
///
/// This operation does not resolve a blueprint, validate map dimensions,
/// canonicalize geometry, regenerate output, or recalculate fingerprints.
BorderFeature decodeBorderFeatureJson(
  Object? json, {
  String path = r'$',
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _featureRequiredKeys,
    optionalKeys: _featureOptionalKeys,
  );

  final id = _decodeStableText(value, 'id', path);
  final name = _decodeStableText(value, 'name', path);
  final blueprintId = _decodeStableText(value, 'blueprintId', path);
  final seedPath = borderJsonPropertyPath(path, 'seed');
  final seed = borderJsonDecodeSignedInt64(
    borderJsonRequireField(value, 'seed', path),
    seedPath,
  );
  final geometryPath = borderJsonPropertyPath(path, 'geometry');
  final geometry = decodeBorderFeatureGeometryJson(
    borderJsonRequireField(value, 'geometry', path),
    path: geometryPath,
  );

  BorderGenerationParams? paramsOverride;
  if (value['paramsOverride'] != null) {
    final paramsPath = borderJsonPropertyPath(path, 'paramsOverride');
    paramsOverride = decodeBorderGenerationParamsJson(
      value['paramsOverride'],
      path: paramsPath,
    );
  }

  final overridesPath = borderJsonPropertyPath(path, 'overrides');
  final overrideValues = borderJsonRequireList(
    borderJsonRequireField(value, 'overrides', path),
    overridesPath,
  );
  final overrides = <BorderSlotOverride>[];
  final overrideSlots = <String>{};
  for (var index = 0; index < overrideValues.length; index += 1) {
    final overridePath = borderJsonIndexPath(overridesPath, index);
    final override = _decodeOverride(overrideValues[index], overridePath);
    if (!overrideSlots.add(override.slotKey)) {
      throw FormatException(
        '${borderJsonPropertyPath(overridePath, 'slotKey')}: '
        'duplicate override slotKey',
      );
    }
    overrides.add(override);
  }

  final keepOutsPath = borderJsonPropertyPath(path, 'keepOutRegions');
  final keepOutValues = borderJsonRequireList(
    borderJsonRequireField(value, 'keepOutRegions', path),
    keepOutsPath,
  );
  final keepOutRegions = <BorderKeepOutRegion>[];
  final keepOutIds = <String>{};
  for (var index = 0; index < keepOutValues.length; index += 1) {
    final keepOutPath = borderJsonIndexPath(keepOutsPath, index);
    final keepOut = decodeBorderKeepOutRegionJson(
      keepOutValues[index],
      path: keepOutPath,
    );
    if (!keepOutIds.add(keepOut.id)) {
      throw FormatException(
        '${borderJsonPropertyPath(keepOutPath, 'id')}: '
        'duplicate keep-out id',
      );
    }
    keepOutRegions.add(keepOut);
  }

  BorderMaterialization? materialization;
  if (value['materialization'] != null) {
    final materializationPath = borderJsonPropertyPath(path, 'materialization');
    materialization = decodeBorderMaterializationJson(
      value['materialization'],
      path: materializationPath,
    );
  }

  return borderJsonConstructAtPath(
    path,
    () => BorderFeature(
      id: id,
      name: name,
      blueprintId: blueprintId,
      seed: seed,
      geometry: geometry,
      paramsOverride: paramsOverride,
      overrides: overrides,
      keepOutRegions: keepOutRegions,
      materialization: materialization,
    ),
  );
}

Map<String, Object?> _encodeOverride(
  BorderSlotOverride override,
  String path,
) {
  final slotKeyPath = borderJsonPropertyPath(path, 'slotKey');
  _validateStableText(override.slotKey, slotKeyPath);
  final replacement = override.replacementPrimitiveId;
  if (replacement != null) {
    _validateStableText(
      replacement,
      borderJsonPropertyPath(path, 'replacementPrimitiveId'),
    );
  }
  _validateOverrideInvariants(
    slotKey: override.slotKey,
    suppressed: override.suppressed,
    locked: override.locked,
    lockedPlacement: override.lockedPlacement,
    replacementPrimitiveId: replacement,
    offsetDeltaPx: override.offsetDeltaPx,
    transformOverride: override.transformOverride,
    path: path,
  );

  final placement = override.lockedPlacement;
  final offset = override.offsetDeltaPx;
  final transform = override.transformOverride;
  return <String, Object?>{
    'slotKey': override.slotKey,
    'variationSalt': borderJsonEncodeSignedInt64(override.variationSalt),
    'suppressed': override.suppressed,
    'locked': override.locked,
    if (placement != null)
      'lockedPlacement': encodeBorderResolvedPlacementJson(
        placement,
        path: borderJsonPropertyPath(path, 'lockedPlacement'),
      ),
    if (replacement != null) 'replacementPrimitiveId': replacement,
    if (offset != null)
      'offsetDeltaPx': _encodeOffset(
        offset,
        borderJsonPropertyPath(path, 'offsetDeltaPx'),
      ),
    if (transform != null)
      'transformOverride': encodeBorderSpriteTransformJson(
        transform,
        path: borderJsonPropertyPath(path, 'transformOverride'),
      ),
  };
}

BorderSlotOverride _decodeOverride(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _overrideRequiredKeys,
    optionalKeys: _overrideOptionalKeys,
  );

  final slotKey = _decodeStableText(value, 'slotKey', path);
  final saltPath = borderJsonPropertyPath(path, 'variationSalt');
  final variationSalt = borderJsonDecodeSignedInt64(
    borderJsonRequireField(value, 'variationSalt', path),
    saltPath,
  );
  final suppressed = borderJsonRequireBool(
    borderJsonRequireField(value, 'suppressed', path),
    borderJsonPropertyPath(path, 'suppressed'),
  );
  final locked = borderJsonRequireBool(
    borderJsonRequireField(value, 'locked', path),
    borderJsonPropertyPath(path, 'locked'),
  );

  BorderResolvedPlacement? lockedPlacement;
  if (value['lockedPlacement'] != null) {
    final placementPath = borderJsonPropertyPath(path, 'lockedPlacement');
    lockedPlacement = decodeBorderResolvedPlacementJson(
      value['lockedPlacement'],
      path: placementPath,
    );
  }

  String? replacementPrimitiveId;
  if (value['replacementPrimitiveId'] != null) {
    replacementPrimitiveId = _decodeStableText(
      value,
      'replacementPrimitiveId',
      path,
    );
  }

  BorderPixelOffset? offsetDeltaPx;
  if (value['offsetDeltaPx'] != null) {
    final offsetPath = borderJsonPropertyPath(path, 'offsetDeltaPx');
    offsetDeltaPx = _decodeOffset(value['offsetDeltaPx'], offsetPath);
  }

  BorderSpriteTransform? transformOverride;
  if (value['transformOverride'] != null) {
    final transformPath = borderJsonPropertyPath(path, 'transformOverride');
    transformOverride = decodeBorderSpriteTransformJson(
      value['transformOverride'],
      path: transformPath,
    );
  }

  _validateOverrideInvariants(
    slotKey: slotKey,
    suppressed: suppressed,
    locked: locked,
    lockedPlacement: lockedPlacement,
    replacementPrimitiveId: replacementPrimitiveId,
    offsetDeltaPx: offsetDeltaPx,
    transformOverride: transformOverride,
    path: path,
  );
  return borderJsonConstructAtPath(
    path,
    () => BorderSlotOverride(
      slotKey: slotKey,
      variationSalt: variationSalt,
      suppressed: suppressed,
      locked: locked,
      lockedPlacement: lockedPlacement,
      replacementPrimitiveId: replacementPrimitiveId,
      offsetDeltaPx: offsetDeltaPx,
      transformOverride: transformOverride,
    ),
  );
}

void _validateOverrideInvariants({
  required String slotKey,
  required bool suppressed,
  required bool locked,
  required BorderResolvedPlacement? lockedPlacement,
  required String? replacementPrimitiveId,
  required BorderPixelOffset? offsetDeltaPx,
  required BorderSpriteTransform? transformOverride,
  required String path,
}) {
  if (suppressed) {
    if (locked) {
      throw FormatException(
        '${borderJsonPropertyPath(path, 'locked')}: '
        'a suppressed override cannot be locked',
      );
    }
    if (lockedPlacement != null) {
      throw FormatException(
        '${borderJsonPropertyPath(path, 'lockedPlacement')}: '
        'a suppressed override cannot have a locked placement',
      );
    }
    if (replacementPrimitiveId != null) {
      throw FormatException(
        '${borderJsonPropertyPath(path, 'replacementPrimitiveId')}: '
        'a suppressed override cannot replace its primitive',
      );
    }
    if (offsetDeltaPx != null) {
      throw FormatException(
        '${borderJsonPropertyPath(path, 'offsetDeltaPx')}: '
        'a suppressed override cannot move its slot',
      );
    }
    if (transformOverride != null) {
      throw FormatException(
        '${borderJsonPropertyPath(path, 'transformOverride')}: '
        'a suppressed override cannot transform its slot',
      );
    }
  }

  if (locked && lockedPlacement == null) {
    throw FormatException(
      '${borderJsonPropertyPath(path, 'lockedPlacement')}: '
      'is required when locked is true',
    );
  }
  if (!locked && lockedPlacement != null) {
    throw FormatException(
      '${borderJsonPropertyPath(path, 'locked')}: '
      'must be true when lockedPlacement is present',
    );
  }
  if (lockedPlacement != null && lockedPlacement.slotKey != slotKey) {
    throw FormatException(
      '${borderJsonPropertyPath(
        borderJsonPropertyPath(path, 'lockedPlacement'),
        'slotKey',
      )}: must match override slotKey',
    );
  }
}

Map<String, Object?> _encodeOffset(BorderPixelOffset offset, String path) =>
    <String, Object?>{
      'x': _encodeSignedNumeric(offset.x, borderJsonPropertyPath(path, 'x')),
      'y': _encodeSignedNumeric(offset.y, borderJsonPropertyPath(path, 'y')),
    };

BorderPixelOffset _decodeOffset(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _offsetKeys,
  );
  return BorderPixelOffset(
    x: _decodeSignedNumeric(
      borderJsonRequireField(value, 'x', path),
      borderJsonPropertyPath(path, 'x'),
    ),
    y: _decodeSignedNumeric(
      borderJsonRequireField(value, 'y', path),
      borderJsonPropertyPath(path, 'y'),
    ),
  );
}

String _decodeStableText(
  BorderJsonObject value,
  String key,
  String path,
) {
  final fieldPath = borderJsonPropertyPath(path, key);
  final decoded = borderJsonRequireString(
    borderJsonRequireField(value, key, path),
    fieldPath,
  );
  _validateStableText(decoded, fieldPath);
  return decoded;
}

void _validateStableText(String value, String path) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw FormatException('$path: must be nonblank and already trimmed');
  }
}

int _decodeSignedNumeric(Object? value, String path) {
  final decoded = borderJsonRequireInt(value, path);
  _validateSignedNumeric(decoded, path);
  return decoded;
}

int _encodeSignedNumeric(int value, String path) {
  _validateSignedNumeric(value, path);
  return value;
}

void _validateSignedNumeric(int value, String path) {
  final exactValue = BigInt.from(value);
  if (exactValue < _minimumSignedInt64 || exactValue > _maximumSignedInt64) {
    throw FormatException('$path: must fit signed 64-bit range');
  }
}
