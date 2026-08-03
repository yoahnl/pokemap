import '../models/border_blueprint.dart';
import '../models/border_signed_int64.dart';
import '../models/border_value_objects.dart';
import '../models/surface.dart';
import 'border_json_codec_helpers.dart';
import 'border_visual_snapshot_json_codec.dart';

const Set<String> _recordRequiredKeys = <String>{'id', 'draft'};
const Set<String> _recordOptionalKeys = <String>{
  'latestPublished',
  'isDeprecated',
};
const Set<String> _draftKeys = <String>{'baseRevision', 'definition'};
const Set<String> _revisionKeys = <String>{'revision', 'definition'};
const Set<String> _definitionRequiredKeys = <String>{
  'name',
  'previewSeed',
  'template',
  'primitives',
  'defaults',
  'sortOrder',
};
const Set<String> _definitionOptionalKeys = <String>{
  'ground',
  'categoryId',
};
const Set<String> _draftPrimitiveKeys = <String>{
  'id',
  'sourceElementId',
  'role',
  'weight',
  'anchorPx',
  'transforms',
  'currentMetrics',
};
const Set<String> _publishedPrimitiveKeys = <String>{
  'id',
  'sourceElementId',
  'visualSnapshotId',
  'role',
  'weight',
  'anchorPx',
  'transforms',
  'publishedMetrics',
};
const Set<String> _primitiveOptionalKeysV4 = <String>{
  'authoredOrientation',
};
const Set<String> _transformKeys = <String>{
  'allowFlipX',
  'allowedQuarterTurns',
};
const Set<String> _pixelPosKeys = <String>{'x', 'y'};
const Set<String> _draftGroundKeys = <String>{
  'sourceSmartTilePresetId',
  'edgeBandCells',
};
const Set<String> _publishedGroundKeys = <String>{
  'sourceSmartTilePresetId',
  'edgeBandCells',
  'visualSnapshotIdsByRole',
};
const Set<String> _generationParamKeys = <String>{
  'irregularityPermille',
  'detailDensityPermille',
  'variationPermille',
  'maxOverlapPx',
  'gapTolerancePx',
  'depthRows',
};
const Set<String> _generationParamOptionalKeysV2 = <String>{
  'allowAutoRotation',
};
const Set<String> _surfaceRoleKeys = <String>{
  'isolated',
  'endNorth',
  'endEast',
  'endSouth',
  'endWest',
  'horizontal',
  'vertical',
  'cornerNE',
  'cornerSE',
  'cornerSW',
  'cornerNW',
  'innerCornerNE',
  'innerCornerSE',
  'innerCornerSW',
  'innerCornerNW',
  'teeNorth',
  'teeEast',
  'teeSouth',
  'teeWest',
  'cross',
};

/// Encodes a complete Border blueprint record using the strict V1 wire shape.
///
/// Null optional values are omitted from the canonical output. Primitive order
/// is authored order and is never normalized by the codec.
Map<String, Object?> encodeBorderBlueprintRecordJson(
  BorderBlueprintRecord value, {
  String path = r'$',
  int formatVersion = 1,
}) {
  _requireBlueprintFormatVersion(formatVersion, path);
  final idPath = borderJsonPropertyPath(path, 'id');
  _requireStableRecordId(value.id, idPath);

  final draftPath = borderJsonPropertyPath(path, 'draft');
  final latestPublished = value.latestPublished;
  return <String, Object?>{
    'id': value.id,
    'draft': _encodeDraft(value.draft, draftPath, formatVersion),
    if (latestPublished != null)
      'latestPublished': _encodeRevision(
        latestPublished,
        borderJsonPropertyPath(path, 'latestPublished'),
        formatVersion,
      ),
    if (value.isDeprecated) 'isDeprecated': true,
  };
}

/// Decodes a complete Border blueprint record using the strict V1 wire shape.
BorderBlueprintRecord decodeBorderBlueprintRecordJson(
  Object? json, {
  String path = r'$',
  int formatVersion = 1,
}) {
  _requireBlueprintFormatVersion(formatVersion, path);
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _recordRequiredKeys,
    optionalKeys: _recordOptionalKeys,
  );

  final idPath = borderJsonPropertyPath(path, 'id');
  final id = borderJsonRequireString(
    borderJsonRequireField(value, 'id', path),
    idPath,
  );
  _requireStableRecordId(id, idPath);

  final draftPath = borderJsonPropertyPath(path, 'draft');
  final draft = _decodeDraft(
    borderJsonRequireField(value, 'draft', path),
    draftPath,
    formatVersion,
  );

  BorderBlueprintRevision? latestPublished;
  if (value.containsKey('latestPublished') &&
      value['latestPublished'] != null) {
    final latestPublishedPath = borderJsonPropertyPath(path, 'latestPublished');
    latestPublished = _decodeRevision(
      value['latestPublished'],
      latestPublishedPath,
      formatVersion,
    );
  }

  final isDeprecated = value.containsKey('isDeprecated')
      ? borderJsonRequireBool(
          value['isDeprecated'],
          borderJsonPropertyPath(path, 'isDeprecated'),
        )
      : false;

  return borderJsonConstructAtPath(
    path,
    () => BorderBlueprintRecord(
      id: id,
      draft: draft,
      latestPublished: latestPublished,
      isDeprecated: isDeprecated,
    ),
  );
}

/// Encodes deterministic Border generation controls using exact integer keys.
Map<String, Object?> encodeBorderGenerationParamsJson(
  BorderGenerationParams value, {
  String path = r'$',
  int formatVersion = 1,
}) {
  _requireBlueprintFormatVersion(formatVersion, path);
  if (formatVersion == 1 && !value.allowAutoRotation) {
    throw FormatException(
      '${borderJsonPropertyPath(path, 'allowAutoRotation')}: '
      'requires Border format version 2',
    );
  }
  _validatePermille(
    value.irregularityPermille,
    borderJsonPropertyPath(path, 'irregularityPermille'),
  );
  _validatePermille(
    value.detailDensityPermille,
    borderJsonPropertyPath(path, 'detailDensityPermille'),
  );
  _validatePermille(
    value.variationPermille,
    borderJsonPropertyPath(path, 'variationPermille'),
  );
  _validateNonNegative(
    value.maxOverlapPx,
    borderJsonPropertyPath(path, 'maxOverlapPx'),
  );
  _validateNonNegative(
    value.gapTolerancePx,
    borderJsonPropertyPath(path, 'gapTolerancePx'),
  );
  if (value.depthRows < 1) {
    throw FormatException(
      '${borderJsonPropertyPath(path, 'depthRows')}: must be >= 1',
    );
  }

  return <String, Object?>{
    'irregularityPermille': value.irregularityPermille,
    'detailDensityPermille': value.detailDensityPermille,
    'variationPermille': value.variationPermille,
    'maxOverlapPx': value.maxOverlapPx,
    'gapTolerancePx': value.gapTolerancePx,
    'depthRows': value.depthRows,
    if (formatVersion >= 2 && !value.allowAutoRotation)
      'allowAutoRotation': false,
  };
}

/// Decodes deterministic Border generation controls using strict integer JSON.
BorderGenerationParams decodeBorderGenerationParamsJson(
  Object? json, {
  String path = r'$',
  int formatVersion = 1,
}) {
  _requireBlueprintFormatVersion(formatVersion, path);
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _generationParamKeys,
    optionalKeys:
        formatVersion >= 2 ? _generationParamOptionalKeysV2 : const <String>{},
  );

  final irregularityPath = borderJsonPropertyPath(path, 'irregularityPermille');
  final detailDensityPath =
      borderJsonPropertyPath(path, 'detailDensityPermille');
  final variationPath = borderJsonPropertyPath(path, 'variationPermille');
  final maxOverlapPath = borderJsonPropertyPath(path, 'maxOverlapPx');
  final gapTolerancePath = borderJsonPropertyPath(path, 'gapTolerancePx');
  final depthRowsPath = borderJsonPropertyPath(path, 'depthRows');

  final irregularityPermille = borderJsonRequireInt(
    borderJsonRequireField(value, 'irregularityPermille', path),
    irregularityPath,
  );
  final detailDensityPermille = borderJsonRequireInt(
    borderJsonRequireField(value, 'detailDensityPermille', path),
    detailDensityPath,
  );
  final variationPermille = borderJsonRequireInt(
    borderJsonRequireField(value, 'variationPermille', path),
    variationPath,
  );
  final maxOverlapPx = borderJsonRequireInt(
    borderJsonRequireField(value, 'maxOverlapPx', path),
    maxOverlapPath,
  );
  final gapTolerancePx = borderJsonRequireInt(
    borderJsonRequireField(value, 'gapTolerancePx', path),
    gapTolerancePath,
  );
  final depthRows = borderJsonRequireInt(
    borderJsonRequireField(value, 'depthRows', path),
    depthRowsPath,
  );
  final allowAutoRotation = value.containsKey('allowAutoRotation')
      ? borderJsonRequireBool(
          value['allowAutoRotation'],
          borderJsonPropertyPath(path, 'allowAutoRotation'),
        )
      : true;

  _validatePermille(irregularityPermille, irregularityPath);
  _validatePermille(detailDensityPermille, detailDensityPath);
  _validatePermille(variationPermille, variationPath);
  _validateNonNegative(maxOverlapPx, maxOverlapPath);
  _validateNonNegative(gapTolerancePx, gapTolerancePath);
  if (depthRows < 1) {
    throw FormatException('$depthRowsPath: must be >= 1');
  }

  return borderJsonConstructAtPath(
    path,
    () => BorderGenerationParams(
      irregularityPermille: irregularityPermille,
      detailDensityPermille: detailDensityPermille,
      variationPermille: variationPermille,
      maxOverlapPx: maxOverlapPx,
      gapTolerancePx: gapTolerancePx,
      depthRows: depthRows,
      allowAutoRotation: allowAutoRotation,
    ),
  );
}

Map<String, Object?> _encodeDraft(
  BorderBlueprintDraft value,
  String path,
  int formatVersion,
) {
  final baseRevisionPath = borderJsonPropertyPath(path, 'baseRevision');
  if (value.baseRevision < 0) {
    throw FormatException('$baseRevisionPath: must be >= 0');
  }
  return <String, Object?>{
    'baseRevision': value.baseRevision,
    'definition': _encodeDraftDefinition(
      value.definition,
      borderJsonPropertyPath(path, 'definition'),
      formatVersion,
    ),
  };
}

BorderBlueprintDraft _decodeDraft(
  Object? json,
  String path,
  int formatVersion,
) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _draftKeys,
  );
  final baseRevisionPath = borderJsonPropertyPath(path, 'baseRevision');
  final baseRevision = borderJsonRequireInt(
    borderJsonRequireField(value, 'baseRevision', path),
    baseRevisionPath,
  );
  if (baseRevision < 0) {
    throw FormatException('$baseRevisionPath: must be >= 0');
  }
  return borderJsonConstructAtPath(
    path,
    () => BorderBlueprintDraft(
      baseRevision: baseRevision,
      definition: _decodeDraftDefinition(
        borderJsonRequireField(value, 'definition', path),
        borderJsonPropertyPath(path, 'definition'),
        formatVersion,
      ),
    ),
  );
}

Map<String, Object?> _encodeRevision(
  BorderBlueprintRevision value,
  String path,
  int formatVersion,
) {
  final revisionPath = borderJsonPropertyPath(path, 'revision');
  if (value.revision < 1) {
    throw FormatException('$revisionPath: must be >= 1');
  }
  return <String, Object?>{
    'revision': value.revision,
    'definition': _encodePublishedDefinition(
      value.definition,
      borderJsonPropertyPath(path, 'definition'),
      formatVersion,
    ),
  };
}

BorderBlueprintRevision _decodeRevision(
  Object? json,
  String path,
  int formatVersion,
) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _revisionKeys,
  );
  final revisionPath = borderJsonPropertyPath(path, 'revision');
  final revision = borderJsonRequireInt(
    borderJsonRequireField(value, 'revision', path),
    revisionPath,
  );
  if (revision < 1) {
    throw FormatException('$revisionPath: must be >= 1');
  }
  return borderJsonConstructAtPath(
    path,
    () => BorderBlueprintRevision(
      revision: revision,
      definition: _decodePublishedDefinition(
        borderJsonRequireField(value, 'definition', path),
        borderJsonPropertyPath(path, 'definition'),
        formatVersion,
      ),
    ),
  );
}

Map<String, Object?> _encodeDraftDefinition(
  BorderBlueprintDraftDefinition value,
  String path,
  int formatVersion,
) {
  _validateDefinitionFields(value, path);
  final template = _encodeTemplate(
    value.template,
    formatVersion,
    borderJsonPropertyPath(path, 'template'),
  );
  final primitivesPath = borderJsonPropertyPath(path, 'primitives');
  final primitives = <Object?>[];
  for (var index = 0; index < value.primitives.length; index += 1) {
    primitives.add(
      _encodeDraftPrimitive(
        value.primitives[index],
        borderJsonIndexPath(primitivesPath, index),
        formatVersion,
      ),
    );
  }
  final ground = value.ground;
  final categoryId = value.categoryId;
  return <String, Object?>{
    'name': value.name,
    'previewSeed': _encodeSignedInt64AtPath(
      value.previewSeed,
      borderJsonPropertyPath(path, 'previewSeed'),
    ),
    'template': template,
    'primitives': primitives,
    'defaults': encodeBorderGenerationParamsJson(
      value.defaults,
      path: borderJsonPropertyPath(path, 'defaults'),
      formatVersion: formatVersion,
    ),
    if (ground != null)
      'ground': _encodeDraftGround(
        ground,
        borderJsonPropertyPath(path, 'ground'),
      ),
    if (categoryId != null) 'categoryId': categoryId,
    'sortOrder': value.sortOrder,
  };
}

BorderBlueprintDraftDefinition _decodeDraftDefinition(
  Object? json,
  String path,
  int formatVersion,
) {
  final value = _decodeDefinitionObject(json, path);
  final name = _decodeDefinitionName(value, path);
  final previewSeed = _decodePreviewSeed(value, path);
  final template = _decodeDefinitionTemplate(value, path, formatVersion);
  final primitivesPath = borderJsonPropertyPath(path, 'primitives');
  final primitiveValues = borderJsonRequireList(
    borderJsonRequireField(value, 'primitives', path),
    primitivesPath,
  );
  final primitives = <BorderPrimitiveDraft>[];
  for (var index = 0; index < primitiveValues.length; index += 1) {
    primitives.add(
      _decodeDraftPrimitive(
        primitiveValues[index],
        borderJsonIndexPath(primitivesPath, index),
        formatVersion,
      ),
    );
  }
  return borderJsonConstructAtPath(
    path,
    () => BorderBlueprintDraftDefinition(
      name: name,
      previewSeed: previewSeed,
      template: template,
      primitives: primitives,
      defaults: decodeBorderGenerationParamsJson(
        borderJsonRequireField(value, 'defaults', path),
        path: borderJsonPropertyPath(path, 'defaults'),
        formatVersion: formatVersion,
      ),
      ground: _decodeOptionalDraftGround(value, path),
      categoryId: _decodeOptionalCategoryId(value, path),
      sortOrder: _decodeSortOrder(value, path),
    ),
  );
}

Map<String, Object?> _encodePublishedDefinition(
  BorderBlueprintPublishedDefinition value,
  String path,
  int formatVersion,
) {
  _validateDefinitionFields(value, path);
  final template = _encodeTemplate(
    value.template,
    formatVersion,
    borderJsonPropertyPath(path, 'template'),
  );
  final primitivesPath = borderJsonPropertyPath(path, 'primitives');
  final primitives = <Object?>[];
  for (var index = 0; index < value.primitives.length; index += 1) {
    primitives.add(
      _encodePublishedPrimitive(
        value.primitives[index],
        borderJsonIndexPath(primitivesPath, index),
        formatVersion,
      ),
    );
  }
  final ground = value.ground;
  final categoryId = value.categoryId;
  return <String, Object?>{
    'name': value.name,
    'previewSeed': _encodeSignedInt64AtPath(
      value.previewSeed,
      borderJsonPropertyPath(path, 'previewSeed'),
    ),
    'template': template,
    'primitives': primitives,
    'defaults': encodeBorderGenerationParamsJson(
      value.defaults,
      path: borderJsonPropertyPath(path, 'defaults'),
      formatVersion: formatVersion,
    ),
    if (ground != null)
      'ground': _encodePublishedGround(
        ground,
        borderJsonPropertyPath(path, 'ground'),
      ),
    if (categoryId != null) 'categoryId': categoryId,
    'sortOrder': value.sortOrder,
  };
}

BorderBlueprintPublishedDefinition _decodePublishedDefinition(
  Object? json,
  String path,
  int formatVersion,
) {
  final value = _decodeDefinitionObject(json, path);
  final name = _decodeDefinitionName(value, path);
  final previewSeed = _decodePreviewSeed(value, path);
  final template = _decodeDefinitionTemplate(value, path, formatVersion);
  final primitivesPath = borderJsonPropertyPath(path, 'primitives');
  final primitiveValues = borderJsonRequireList(
    borderJsonRequireField(value, 'primitives', path),
    primitivesPath,
  );
  final primitives = <BorderPublishedPrimitive>[];
  for (var index = 0; index < primitiveValues.length; index += 1) {
    primitives.add(
      _decodePublishedPrimitive(
        primitiveValues[index],
        borderJsonIndexPath(primitivesPath, index),
        formatVersion,
      ),
    );
  }
  return borderJsonConstructAtPath(
    path,
    () => BorderBlueprintPublishedDefinition(
      name: name,
      previewSeed: previewSeed,
      template: template,
      primitives: primitives,
      defaults: decodeBorderGenerationParamsJson(
        borderJsonRequireField(value, 'defaults', path),
        path: borderJsonPropertyPath(path, 'defaults'),
        formatVersion: formatVersion,
      ),
      ground: _decodeOptionalPublishedGround(value, path),
      categoryId: _decodeOptionalCategoryId(value, path),
      sortOrder: _decodeSortOrder(value, path),
    ),
  );
}

BorderJsonObject _decodeDefinitionObject(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _definitionRequiredKeys,
    optionalKeys: _definitionOptionalKeys,
  );
  return value;
}

String _decodeDefinitionName(BorderJsonObject value, String path) {
  final namePath = borderJsonPropertyPath(path, 'name');
  final name = borderJsonRequireString(
    borderJsonRequireField(value, 'name', path),
    namePath,
  );
  _requireNonEmpty(name, namePath);
  return name;
}

BorderSignedInt64 _decodePreviewSeed(BorderJsonObject value, String path) {
  final seedPath = borderJsonPropertyPath(path, 'previewSeed');
  return borderJsonDecodeSignedInt64(
    borderJsonRequireField(value, 'previewSeed', path),
    seedPath,
  );
}

BorderBlueprintTemplate _decodeDefinitionTemplate(
  BorderJsonObject value,
  String path,
  int formatVersion,
) {
  final templatePath = borderJsonPropertyPath(path, 'template');
  return _decodeTemplate(
    borderJsonRequireString(
      borderJsonRequireField(value, 'template', path),
      templatePath,
    ),
    templatePath,
    formatVersion,
  );
}

int _decodeSortOrder(BorderJsonObject value, String path) =>
    borderJsonRequireInt(
      borderJsonRequireField(value, 'sortOrder', path),
      borderJsonPropertyPath(path, 'sortOrder'),
    );

String? _decodeOptionalCategoryId(BorderJsonObject value, String path) {
  if (!value.containsKey('categoryId') || value['categoryId'] == null) {
    return null;
  }
  final categoryPath = borderJsonPropertyPath(path, 'categoryId');
  final categoryId = borderJsonRequireString(value['categoryId'], categoryPath);
  _requireNonEmpty(categoryId, categoryPath);
  return categoryId;
}

BorderGroundDraft? _decodeOptionalDraftGround(
  BorderJsonObject value,
  String path,
) {
  if (!value.containsKey('ground') || value['ground'] == null) {
    return null;
  }
  return _decodeDraftGround(
    value['ground'],
    borderJsonPropertyPath(path, 'ground'),
  );
}

BorderPublishedGround? _decodeOptionalPublishedGround(
  BorderJsonObject value,
  String path,
) {
  if (!value.containsKey('ground') || value['ground'] == null) {
    return null;
  }
  return _decodePublishedGround(
    value['ground'],
    borderJsonPropertyPath(path, 'ground'),
  );
}

Map<String, Object?> _encodeDraftPrimitive(
  BorderPrimitiveDraft value,
  String path,
  int formatVersion,
) {
  _validatePrimitiveIdentityAndWeight(
    id: value.id,
    sourceElementId: value.sourceElementId,
    weight: value.weight,
    minimumWeight: 0,
    path: path,
  );
  final authoredOrientation = _encodeAuthoredOrientation(
    value.authoredOrientation,
    formatVersion,
    borderJsonPropertyPath(path, 'authoredOrientation'),
  );
  return <String, Object?>{
    'id': value.id,
    'sourceElementId': value.sourceElementId,
    'role': _encodePrimitiveRole(
      value.role,
      formatVersion,
      borderJsonPropertyPath(path, 'role'),
    ),
    if (authoredOrientation != null) 'authoredOrientation': authoredOrientation,
    'weight': value.weight,
    'anchorPx': _encodePixelPos(value.anchorPx),
    'transforms': _encodeTransformPolicy(
      value.transforms,
      borderJsonPropertyPath(path, 'transforms'),
    ),
    'currentMetrics': encodeBorderPrimitiveAssetMetricsJson(
      value.currentMetrics,
      path: borderJsonPropertyPath(path, 'currentMetrics'),
    ),
  };
}

BorderPrimitiveDraft _decodeDraftPrimitive(
  Object? json,
  String path,
  int formatVersion,
) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _draftPrimitiveKeys,
    optionalKeys:
        formatVersion >= 4 ? _primitiveOptionalKeysV4 : const <String>{},
  );
  final identity = _decodePrimitiveIdentityAndWeight(
    value,
    path,
    minimumWeight: 0,
  );
  return borderJsonConstructAtPath(
    path,
    () => BorderPrimitiveDraft(
      id: identity.id,
      sourceElementId: identity.sourceElementId,
      role: _decodePrimitiveRoleField(value, path, formatVersion),
      authoredOrientation: _decodeAuthoredOrientationField(value, path),
      weight: identity.weight,
      anchorPx: _decodePixelPos(
        borderJsonRequireField(value, 'anchorPx', path),
        borderJsonPropertyPath(path, 'anchorPx'),
      ),
      transforms: _decodeTransformPolicy(
        borderJsonRequireField(value, 'transforms', path),
        borderJsonPropertyPath(path, 'transforms'),
      ),
      currentMetrics: decodeBorderPrimitiveAssetMetricsJson(
        borderJsonRequireField(value, 'currentMetrics', path),
        path: borderJsonPropertyPath(path, 'currentMetrics'),
      ),
    ),
  );
}

Map<String, Object?> _encodePublishedPrimitive(
  BorderPublishedPrimitive value,
  String path,
  int formatVersion,
) {
  _validatePrimitiveIdentityAndWeight(
    id: value.id,
    sourceElementId: value.sourceElementId,
    weight: value.weight,
    minimumWeight: 1,
    path: path,
  );
  _requireNonEmpty(
    value.visualSnapshotId,
    borderJsonPropertyPath(path, 'visualSnapshotId'),
  );
  final authoredOrientation = _encodeAuthoredOrientation(
    value.authoredOrientation,
    formatVersion,
    borderJsonPropertyPath(path, 'authoredOrientation'),
  );
  return <String, Object?>{
    'id': value.id,
    'sourceElementId': value.sourceElementId,
    'visualSnapshotId': value.visualSnapshotId,
    'role': _encodePrimitiveRole(
      value.role,
      formatVersion,
      borderJsonPropertyPath(path, 'role'),
    ),
    if (authoredOrientation != null) 'authoredOrientation': authoredOrientation,
    'weight': value.weight,
    'anchorPx': _encodePixelPos(value.anchorPx),
    'transforms': _encodeTransformPolicy(
      value.transforms,
      borderJsonPropertyPath(path, 'transforms'),
    ),
    'publishedMetrics': encodeBorderPrimitiveAssetMetricsJson(
      value.publishedMetrics,
      path: borderJsonPropertyPath(path, 'publishedMetrics'),
    ),
  };
}

BorderPublishedPrimitive _decodePublishedPrimitive(
  Object? json,
  String path,
  int formatVersion,
) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _publishedPrimitiveKeys,
    optionalKeys:
        formatVersion >= 4 ? _primitiveOptionalKeysV4 : const <String>{},
  );
  final identity = _decodePrimitiveIdentityAndWeight(
    value,
    path,
    minimumWeight: 1,
  );
  final snapshotPath = borderJsonPropertyPath(path, 'visualSnapshotId');
  final visualSnapshotId = borderJsonRequireString(
    borderJsonRequireField(value, 'visualSnapshotId', path),
    snapshotPath,
  );
  _requireNonEmpty(visualSnapshotId, snapshotPath);
  return borderJsonConstructAtPath(
    path,
    () => BorderPublishedPrimitive(
      id: identity.id,
      sourceElementId: identity.sourceElementId,
      visualSnapshotId: visualSnapshotId,
      role: _decodePrimitiveRoleField(value, path, formatVersion),
      authoredOrientation: _decodeAuthoredOrientationField(value, path),
      weight: identity.weight,
      anchorPx: _decodePixelPos(
        borderJsonRequireField(value, 'anchorPx', path),
        borderJsonPropertyPath(path, 'anchorPx'),
      ),
      transforms: _decodeTransformPolicy(
        borderJsonRequireField(value, 'transforms', path),
        borderJsonPropertyPath(path, 'transforms'),
      ),
      publishedMetrics: decodeBorderPrimitiveAssetMetricsJson(
        borderJsonRequireField(value, 'publishedMetrics', path),
        path: borderJsonPropertyPath(path, 'publishedMetrics'),
      ),
    ),
  );
}

({String id, String sourceElementId, int weight})
    _decodePrimitiveIdentityAndWeight(
  BorderJsonObject value,
  String path, {
  required int minimumWeight,
}) {
  final idPath = borderJsonPropertyPath(path, 'id');
  final sourcePath = borderJsonPropertyPath(path, 'sourceElementId');
  final weightPath = borderJsonPropertyPath(path, 'weight');
  final id = borderJsonRequireString(
    borderJsonRequireField(value, 'id', path),
    idPath,
  );
  final sourceElementId = borderJsonRequireString(
    borderJsonRequireField(value, 'sourceElementId', path),
    sourcePath,
  );
  final weight = borderJsonRequireInt(
    borderJsonRequireField(value, 'weight', path),
    weightPath,
  );
  _validatePrimitiveIdentityAndWeight(
    id: id,
    sourceElementId: sourceElementId,
    weight: weight,
    minimumWeight: minimumWeight,
    path: path,
  );
  return (id: id, sourceElementId: sourceElementId, weight: weight);
}

void _validatePrimitiveIdentityAndWeight({
  required String id,
  required String sourceElementId,
  required int weight,
  required int minimumWeight,
  required String path,
}) {
  _requireNonEmpty(id, borderJsonPropertyPath(path, 'id'));
  _requireNonEmpty(
    sourceElementId,
    borderJsonPropertyPath(path, 'sourceElementId'),
  );
  if (weight < minimumWeight || weight > 1000) {
    throw FormatException(
      '${borderJsonPropertyPath(path, 'weight')}: '
      'must be between $minimumWeight and 1000',
    );
  }
}

BorderPrimitiveRole _decodePrimitiveRoleField(
  BorderJsonObject value,
  String path,
  int formatVersion,
) {
  final rolePath = borderJsonPropertyPath(path, 'role');
  return _decodePrimitiveRole(
    borderJsonRequireString(
      borderJsonRequireField(value, 'role', path),
      rolePath,
    ),
    rolePath,
    formatVersion,
  );
}

String? _encodeAuthoredOrientation(
  BorderPrimitiveOrientation value,
  int formatVersion,
  String path,
) {
  if (value == BorderPrimitiveOrientation.legacyAxis) {
    return null;
  }
  if (formatVersion < 4) {
    throw FormatException('$path: requires catalog format version 4');
  }
  return borderPrimitiveOrientationV1WireName(value);
}

BorderPrimitiveOrientation _decodeAuthoredOrientationField(
  BorderJsonObject value,
  String path,
) {
  if (!value.containsKey('authoredOrientation')) {
    return BorderPrimitiveOrientation.legacyAxis;
  }
  final orientationPath = borderJsonPropertyPath(path, 'authoredOrientation');
  final orientation = borderJsonRequireString(
    value['authoredOrientation'],
    orientationPath,
  );
  return switch (orientation) {
    'legacyAxis' => BorderPrimitiveOrientation.legacyAxis,
    'east' => BorderPrimitiveOrientation.east,
    'south' => BorderPrimitiveOrientation.south,
    'west' => BorderPrimitiveOrientation.west,
    'north' => BorderPrimitiveOrientation.north,
    _ => throw FormatException(
        '$orientationPath: unknown Border primitive orientation',
      ),
  };
}

Map<String, Object?> _encodeTransformPolicy(
  BorderTransformPolicy value,
  String path,
) {
  _validateQuarterTurns(value.allowedQuarterTurns, path);
  return <String, Object?>{
    'allowFlipX': value.allowFlipX,
    'allowedQuarterTurns': List<int>.from(value.allowedQuarterTurns),
  };
}

BorderTransformPolicy _decodeTransformPolicy(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _transformKeys,
  );
  final turnsPath = borderJsonPropertyPath(path, 'allowedQuarterTurns');
  final rawTurns = borderJsonRequireList(
    borderJsonRequireField(value, 'allowedQuarterTurns', path),
    turnsPath,
  );
  final turns = <int>[];
  for (var index = 0; index < rawTurns.length; index += 1) {
    turns.add(
      borderJsonRequireInt(
        rawTurns[index],
        borderJsonIndexPath(turnsPath, index),
      ),
    );
  }
  _validateQuarterTurns(turns, path);
  return borderJsonConstructAtPath(
    path,
    () => BorderTransformPolicy(
      allowFlipX: borderJsonRequireBool(
        borderJsonRequireField(value, 'allowFlipX', path),
        borderJsonPropertyPath(path, 'allowFlipX'),
      ),
      allowedQuarterTurns: turns,
    ),
  );
}

void _validateQuarterTurns(List<int> turns, String transformPath) {
  final turnsPath = borderJsonPropertyPath(
    transformPath,
    'allowedQuarterTurns',
  );
  for (var index = 0; index < turns.length; index += 1) {
    final value = turns[index];
    final valuePath = borderJsonIndexPath(turnsPath, index);
    if (value < 0 || value > 3) {
      throw FormatException('$valuePath: must be between 0 and 3');
    }
    if (index > 0 && turns[index - 1] >= value) {
      throw FormatException(
        '$valuePath: allowedQuarterTurns must be strictly increasing',
      );
    }
  }
}

Map<String, Object?> _encodePixelPos(BorderPixelPos value) =>
    <String, Object?>{'x': value.x, 'y': value.y};

BorderPixelPos _decodePixelPos(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _pixelPosKeys,
  );
  return BorderPixelPos(
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

Map<String, Object?> _encodeDraftGround(
  BorderGroundDraft value,
  String path,
) {
  _validateGroundFields(
    value.sourceSmartTilePresetId,
    value.edgeBandCells,
    path,
  );
  return <String, Object?>{
    'sourceSmartTilePresetId': value.sourceSmartTilePresetId,
    'edgeBandCells': value.edgeBandCells,
  };
}

BorderGroundDraft _decodeDraftGround(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _draftGroundKeys,
  );
  final fields = _decodeGroundFields(value, path);
  return borderJsonConstructAtPath(
    path,
    () => BorderGroundDraft(
      sourceSmartTilePresetId: fields.sourceSmartTilePresetId,
      edgeBandCells: fields.edgeBandCells,
    ),
  );
}

Map<String, Object?> _encodePublishedGround(
  BorderPublishedGround value,
  String path,
) {
  _validateGroundFields(
    value.sourceSmartTilePresetId,
    value.edgeBandCells,
    path,
  );
  final snapshotsPath = borderJsonPropertyPath(path, 'visualSnapshotIdsByRole');
  _validatePublishedGroundRoleMap(
    value.visualSnapshotIdsByRole,
    snapshotsPath,
  );
  final snapshots = <String, Object?>{};
  for (final role in standardSurfaceVariantRoleOrder) {
    snapshots[_encodeSurfaceRole(role)] = value.visualSnapshotIdsByRole[role]!;
  }
  return <String, Object?>{
    'sourceSmartTilePresetId': value.sourceSmartTilePresetId,
    'edgeBandCells': value.edgeBandCells,
    'visualSnapshotIdsByRole': snapshots,
  };
}

BorderPublishedGround _decodePublishedGround(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _publishedGroundKeys,
  );
  final fields = _decodeGroundFields(value, path);
  final snapshotsPath = borderJsonPropertyPath(path, 'visualSnapshotIdsByRole');
  final snapshotValues = borderJsonRequireObject(
    borderJsonRequireField(value, 'visualSnapshotIdsByRole', path),
    snapshotsPath,
  );
  borderJsonRequireExactKeys(
    snapshotValues,
    path: snapshotsPath,
    requiredKeys: _surfaceRoleKeys,
  );
  final snapshots = <SurfaceVariantRole, String>{};
  for (final entry in snapshotValues.entries) {
    final entryPath = borderJsonPropertyPath(snapshotsPath, entry.key);
    final snapshotId = borderJsonRequireString(entry.value, entryPath);
    _requireNonEmpty(snapshotId, entryPath);
    snapshots[_decodeSurfaceRole(entry.key, entryPath)] = snapshotId;
  }
  _validatePublishedGroundRoleMap(snapshots, snapshotsPath);
  return borderJsonConstructAtPath(
    path,
    () => BorderPublishedGround(
      sourceSmartTilePresetId: fields.sourceSmartTilePresetId,
      edgeBandCells: fields.edgeBandCells,
      visualSnapshotIdsByRole: snapshots,
    ),
  );
}

({String sourceSmartTilePresetId, int edgeBandCells}) _decodeGroundFields(
  BorderJsonObject value,
  String path,
) {
  final sourcePath = borderJsonPropertyPath(path, 'sourceSmartTilePresetId');
  final edgeBandPath = borderJsonPropertyPath(path, 'edgeBandCells');
  final sourceSmartTilePresetId = borderJsonRequireString(
    borderJsonRequireField(value, 'sourceSmartTilePresetId', path),
    sourcePath,
  );
  final edgeBandCells = borderJsonRequireInt(
    borderJsonRequireField(value, 'edgeBandCells', path),
    edgeBandPath,
  );
  _validateGroundFields(sourceSmartTilePresetId, edgeBandCells, path);
  return (
    sourceSmartTilePresetId: sourceSmartTilePresetId,
    edgeBandCells: edgeBandCells,
  );
}

void _validateGroundFields(
  String sourceSmartTilePresetId,
  int edgeBandCells,
  String path,
) {
  _requireNonEmpty(
    sourceSmartTilePresetId,
    borderJsonPropertyPath(path, 'sourceSmartTilePresetId'),
  );
  if (edgeBandCells < 1) {
    throw FormatException(
      '${borderJsonPropertyPath(path, 'edgeBandCells')}: must be >= 1',
    );
  }
}

void _validatePublishedGroundRoleMap(
  Map<SurfaceVariantRole, String> values,
  String path,
) {
  if (values.length != _surfaceRoleKeys.length) {
    throw FormatException('$path: must contain exactly all 20 Surface roles');
  }
  for (final role in standardSurfaceVariantRoleOrder) {
    final roleName = _encodeSurfaceRole(role);
    final snapshotId = values[role];
    if (snapshotId == null) {
      throw FormatException(
        '${borderJsonPropertyPath(path, roleName)}: required field is missing',
      );
    }
    _requireNonEmpty(snapshotId, borderJsonPropertyPath(path, roleName));
  }
}

void _validateDefinitionFields(
  BorderBlueprintDefinition<Object?, Object?> value,
  String path,
) {
  _requireNonEmpty(value.name, borderJsonPropertyPath(path, 'name'));
  final categoryId = value.categoryId;
  if (categoryId != null) {
    _requireNonEmpty(categoryId, borderJsonPropertyPath(path, 'categoryId'));
  }
}

String _encodeSignedInt64AtPath(BorderSignedInt64 value, String path) {
  try {
    return borderJsonEncodeSignedInt64(value);
  } on ArgumentError {
    throw FormatException('$path: signed 64-bit integer is out of range');
  }
}

void _validatePermille(int value, String path) {
  if (value < 0 || value > 1000) {
    throw FormatException('$path: must be between 0 and 1000');
  }
}

void _validateNonNegative(int value, String path) {
  if (value < 0) {
    throw FormatException('$path: must be >= 0');
  }
}

void _requireNonEmpty(String value, String path) {
  if (value.isEmpty) {
    throw FormatException('$path: must be non-empty');
  }
}

void _requireStableRecordId(String value, String path) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw FormatException('$path: must be nonblank and already trimmed');
  }
}

String _encodeTemplate(
  BorderBlueprintTemplate value,
  int formatVersion,
  String path,
) {
  final minimumVersion = switch (value) {
    BorderBlueprintTemplate.stoneChainLine => 3,
    BorderBlueprintTemplate.connectedLine => 2,
    _ => 1,
  };
  if (formatVersion < minimumVersion) {
    throw FormatException(
      '$path: template requires catalog format version $minimumVersion',
    );
  }
  return borderBlueprintTemplateV1WireName(value);
}

BorderBlueprintTemplate _decodeTemplate(
  String value,
  String path,
  int formatVersion,
) {
  final template = switch (value) {
    'organicEdge' => BorderBlueprintTemplate.organicEdge,
    'masonryLine' => BorderBlueprintTemplate.masonryLine,
    'postAndRailLine' => BorderBlueprintTemplate.postAndRailLine,
    'connectedLine' => BorderBlueprintTemplate.connectedLine,
    'stoneChainLine' => BorderBlueprintTemplate.stoneChainLine,
    _ => throw FormatException('$path: unknown Border blueprint template'),
  };
  final minimumVersion = switch (template) {
    BorderBlueprintTemplate.stoneChainLine => 3,
    BorderBlueprintTemplate.connectedLine => 2,
    _ => 1,
  };
  if (formatVersion < minimumVersion) {
    throw FormatException(
      '$path: template requires catalog format version $minimumVersion',
    );
  }
  return template;
}

String _encodePrimitiveRole(
  BorderPrimitiveRole value,
  int formatVersion,
  String path,
) {
  if (formatVersion == 1 && _isConnectedLineRole(value)) {
    throw FormatException('$path: role requires catalog format version 2');
  }
  return borderPrimitiveRoleV1WireName(value);
}

BorderPrimitiveRole _decodePrimitiveRole(
  String value,
  String path,
  int formatVersion,
) {
  final role = switch (value) {
    'structureLarge' => BorderPrimitiveRole.structureLarge,
    'structureMedium' => BorderPrimitiveRole.structureMedium,
    'filler' => BorderPrimitiveRole.filler,
    'accent' => BorderPrimitiveRole.accent,
    'post' => BorderPrimitiveRole.post,
    'span' => BorderPrimitiveRole.span,
    'surfacePatch' => BorderPrimitiveRole.surfacePatch,
    'outerAccent' => BorderPrimitiveRole.outerAccent,
    'lineCap' => BorderPrimitiveRole.lineCap,
    'lineStraight' => BorderPrimitiveRole.lineStraight,
    'lineCorner' => BorderPrimitiveRole.lineCorner,
    _ => throw FormatException('$path: unknown Border primitive role'),
  };
  if (formatVersion == 1 && _isConnectedLineRole(role)) {
    throw FormatException('$path: role requires catalog format version 2');
  }
  return role;
}

bool _isConnectedLineRole(BorderPrimitiveRole role) => switch (role) {
      BorderPrimitiveRole.lineCap ||
      BorderPrimitiveRole.lineStraight ||
      BorderPrimitiveRole.lineCorner =>
        true,
      _ => false,
    };

void _requireBlueprintFormatVersion(int value, String path) {
  if (value < 1 || value > 4) {
    throw FormatException('$path: unsupported Border blueprint format version');
  }
}

String _encodeSurfaceRole(SurfaceVariantRole value) => switch (value) {
      SurfaceVariantRole.isolated => 'isolated',
      SurfaceVariantRole.endNorth => 'endNorth',
      SurfaceVariantRole.endEast => 'endEast',
      SurfaceVariantRole.endSouth => 'endSouth',
      SurfaceVariantRole.endWest => 'endWest',
      SurfaceVariantRole.horizontal => 'horizontal',
      SurfaceVariantRole.vertical => 'vertical',
      SurfaceVariantRole.cornerNE => 'cornerNE',
      SurfaceVariantRole.cornerSE => 'cornerSE',
      SurfaceVariantRole.cornerSW => 'cornerSW',
      SurfaceVariantRole.cornerNW => 'cornerNW',
      SurfaceVariantRole.innerCornerNE => 'innerCornerNE',
      SurfaceVariantRole.innerCornerSE => 'innerCornerSE',
      SurfaceVariantRole.innerCornerSW => 'innerCornerSW',
      SurfaceVariantRole.innerCornerNW => 'innerCornerNW',
      SurfaceVariantRole.teeNorth => 'teeNorth',
      SurfaceVariantRole.teeEast => 'teeEast',
      SurfaceVariantRole.teeSouth => 'teeSouth',
      SurfaceVariantRole.teeWest => 'teeWest',
      SurfaceVariantRole.cross => 'cross',
    };

SurfaceVariantRole _decodeSurfaceRole(String value, String path) =>
    switch (value) {
      'isolated' => SurfaceVariantRole.isolated,
      'endNorth' => SurfaceVariantRole.endNorth,
      'endEast' => SurfaceVariantRole.endEast,
      'endSouth' => SurfaceVariantRole.endSouth,
      'endWest' => SurfaceVariantRole.endWest,
      'horizontal' => SurfaceVariantRole.horizontal,
      'vertical' => SurfaceVariantRole.vertical,
      'cornerNE' => SurfaceVariantRole.cornerNE,
      'cornerSE' => SurfaceVariantRole.cornerSE,
      'cornerSW' => SurfaceVariantRole.cornerSW,
      'cornerNW' => SurfaceVariantRole.cornerNW,
      'innerCornerNE' => SurfaceVariantRole.innerCornerNE,
      'innerCornerSE' => SurfaceVariantRole.innerCornerSE,
      'innerCornerSW' => SurfaceVariantRole.innerCornerSW,
      'innerCornerNW' => SurfaceVariantRole.innerCornerNW,
      'teeNorth' => SurfaceVariantRole.teeNorth,
      'teeEast' => SurfaceVariantRole.teeEast,
      'teeSouth' => SurfaceVariantRole.teeSouth,
      'teeWest' => SurfaceVariantRole.teeWest,
      'cross' => SurfaceVariantRole.cross,
      _ => throw FormatException('$path: unknown Surface variant role'),
    };
