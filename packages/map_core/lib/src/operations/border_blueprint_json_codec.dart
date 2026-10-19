import '../models/border_catalog.dart';
import '../models/border_blueprint.dart';
import '../models/border_ground_footprint.dart';
import '../models/border_ground_surface.dart';
import '../models/border_jump_behavior.dart';
import '../models/border_signed_int64.dart';
import '../models/border_value_objects.dart';
import '../models/border_ground_variant_role.dart';
import '../models/project_model3d.dart';
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
  'jumpBehavior',
  'ground',
  'categoryId',
  'straightOnly',
  'sequenceLength',
  'followContourDirection',
  'replacesGround',
  'masksGroundCells',
  'groundBaseOffset',
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
const Set<String> _primitiveOptionalKeysV4 = <String>{'authoredOrientation'};
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
const Set<String> _borderGroundRoleKeys = <String>{
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
    optionalKeys: formatVersion >= 2
        ? _generationParamOptionalKeysV2
        : const <String>{},
  );

  final irregularityPath = borderJsonPropertyPath(path, 'irregularityPermille');
  final detailDensityPath = borderJsonPropertyPath(
    path,
    'detailDensityPermille',
  );
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
  borderJsonRequireExactKeys(value, path: path, requiredKeys: _draftKeys);
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

Map<String, Object?> encodeBorderBlueprintRevisionJson(
  BorderBlueprintRevision value, {
  String path = r'$',
  int formatVersion = 1,
}) => _encodeRevision(value, path, formatVersion);

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
  borderJsonRequireExactKeys(value, path: path, requiredKeys: _revisionKeys);
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
  if (value.sequenceLength != 1 && formatVersion < 12) {
    throw FormatException(
      '$path.sequenceLength: requires catalog format version 12',
    );
  }
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
    if (value.straightOnly) 'straightOnly': true,
    if (value.sequenceLength != 1) 'sequenceLength': value.sequenceLength,
    if (value.followContourDirection) 'followContourDirection': true,
    if (value.replacesGround) 'replacesGround': true,
    if (value.masksGroundCells) 'masksGroundCells': true,
    if (value.groundBaseOffset != 0) 'groundBaseOffset': value.groundBaseOffset,
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
    if (value.jumpBehavior != null)
      'jumpBehavior': _encodeJumpBehavior(
        value.jumpBehavior!,
        path,
        formatVersion,
      ),
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
      straightOnly: _decodeStraightOnly(value, path),
      sequenceLength: _decodeSequenceInteger(
        value,
        'sequenceLength',
        1,
        path,
        formatVersion,
      ),
      followContourDirection: _decodeFollowContourDirection(value, path),
      replacesGround: _decodeReplacesGround(value, path),
      masksGroundCells: _decodeMasksGroundCells(value, path),
      groundBaseOffset: _decodeGroundBaseOffset(value, path),
      primitives: primitives,
      defaults: decodeBorderGenerationParamsJson(
        borderJsonRequireField(value, 'defaults', path),
        path: borderJsonPropertyPath(path, 'defaults'),
        formatVersion: formatVersion,
      ),
      ground: _decodeOptionalDraftGround(value, path),
      categoryId: _decodeOptionalCategoryId(value, path),
      sortOrder: _decodeSortOrder(value, path),
      jumpBehavior: _decodeJumpBehavior(value, path, formatVersion),
    ),
  );
}

Map<String, Object?> _encodePublishedDefinition(
  BorderBlueprintPublishedDefinition value,
  String path,
  int formatVersion,
) {
  if (value.sequenceLength != 1 && formatVersion < 12) {
    throw FormatException(
      '$path.sequenceLength: requires catalog format version 12',
    );
  }
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
    if (value.straightOnly) 'straightOnly': true,
    if (value.sequenceLength != 1) 'sequenceLength': value.sequenceLength,
    if (value.followContourDirection) 'followContourDirection': true,
    if (value.replacesGround) 'replacesGround': true,
    if (value.masksGroundCells) 'masksGroundCells': true,
    if (value.groundBaseOffset != 0) 'groundBaseOffset': value.groundBaseOffset,
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
    if (value.jumpBehavior != null)
      'jumpBehavior': _encodeJumpBehavior(
        value.jumpBehavior!,
        path,
        formatVersion,
      ),
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
      straightOnly: _decodeStraightOnly(value, path),
      sequenceLength: _decodeSequenceInteger(
        value,
        'sequenceLength',
        1,
        path,
        formatVersion,
      ),
      followContourDirection: _decodeFollowContourDirection(value, path),
      replacesGround: _decodeReplacesGround(value, path),
      masksGroundCells: _decodeMasksGroundCells(value, path),
      groundBaseOffset: _decodeGroundBaseOffset(value, path),
      primitives: primitives,
      defaults: decodeBorderGenerationParamsJson(
        borderJsonRequireField(value, 'defaults', path),
        path: borderJsonPropertyPath(path, 'defaults'),
        formatVersion: formatVersion,
      ),
      ground: _decodeOptionalPublishedGround(value, path),
      categoryId: _decodeOptionalCategoryId(value, path),
      sortOrder: _decodeSortOrder(value, path),
      jumpBehavior: _decodeJumpBehavior(value, path, formatVersion),
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

bool _decodeStraightOnly(BorderJsonObject value, String path) =>
    value.containsKey('straightOnly')
    ? borderJsonRequireBool(
        value['straightOnly'],
        borderJsonPropertyPath(path, 'straightOnly'),
      )
    : false;

int _decodeSequenceInteger(
  BorderJsonObject value,
  String field,
  int fallback,
  String path,
  int formatVersion,
) {
  if (!value.containsKey(field)) return fallback;
  if (formatVersion < 12) {
    throw FormatException('$path.$field: requires catalog format version 12');
  }
  return borderJsonRequireInt(value[field], '$path.$field');
}

bool _decodeFollowContourDirection(BorderJsonObject value, String path) =>
    value.containsKey('followContourDirection')
    ? borderJsonRequireBool(
        value['followContourDirection'],
        '$path.followContourDirection',
      )
    : false;

bool _decodeReplacesGround(BorderJsonObject value, String path) =>
    value.containsKey('replacesGround')
    ? borderJsonRequireBool(value['replacesGround'], '$path.replacesGround')
    : false;

bool _decodeMasksGroundCells(BorderJsonObject value, String path) =>
    value.containsKey('masksGroundCells')
    ? borderJsonRequireBool(value['masksGroundCells'], '$path.masksGroundCells')
    : false;

double _decodeGroundBaseOffset(BorderJsonObject value, String path) {
  if (!value.containsKey('groundBaseOffset')) return 0;
  final offset = value['groundBaseOffset'];
  if (offset is! num) {
    throw FormatException('$path.groundBaseOffset: expected a number');
  }
  return offset.toDouble();
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
  if (value.isSpatial) {
    return _encodeSpatialPrimitive(
      path: path,
      formatVersion: formatVersion,
      id: value.id,
      sourceModelId: value.sourceModelId!,
      role: value.role,
      authoredOrientation: value.authoredOrientation,
      sequenceIndex: value.sequenceIndex,
      cornerTurn: value.cornerTurn,
      weight: value.weight,
      transforms: value.transforms,
      anchorWorld: value.anchorWorld,
      animationIndex: value.animationIndex,
      animationLoop: value.animationLoop,
      animationSpeed: value.animationSpeed,
      blocksMovement: value.blocksMovement,
      groundFootprints: value.groundFootprints,
      groundSurfaces: value.groundSurfaces,
    );
  }
  _validatePrimitiveIdentityAndWeight(
    id: value.id,
    sourceElementId: value.sourceElementId!,
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
  if (value.containsKey('sourceModelId')) {
    _validateSpatialPrimitiveJson(value, path, formatVersion);
    return borderJsonConstructAtPath(
      path,
      () => BorderPrimitiveDraft(
        id: borderJsonRequireString(value['id'], '$path.id'),
        sourceModelId: borderJsonRequireString(
          value['sourceModelId'],
          '$path.sourceModelId',
        ),
        role: _decodePrimitiveRoleField(value, path, formatVersion),
        authoredOrientation: _decodeAuthoredOrientationField(value, path),
        sequenceIndex: _decodeSequenceInteger(
          value,
          'sequenceIndex',
          0,
          path,
          formatVersion,
        ),
        cornerTurn: _decodeCornerTurn(value, path),
        weight: borderJsonRequireInt(value['weight'], '$path.weight'),
        animationIndex: value['animationIndex'] == null
            ? null
            : borderJsonRequireInt(
                value['animationIndex'],
                '$path.animationIndex',
              ),
        animationLoop: value.containsKey('animationLoop')
            ? borderJsonRequireBool(
                value['animationLoop'],
                '$path.animationLoop',
              )
            : true,
        animationSpeed: _decodeSpatialAnimationSpeed(value, path),
        groundFootprints: _decodeGroundFootprints(value, path, formatVersion),
        groundSurfaces: _decodeGroundSurfaces(value, path, formatVersion),
        blocksMovement: value.containsKey('blocksMovement')
            ? borderJsonRequireBool(
                value['blocksMovement'],
                '$path.blocksMovement',
              )
            : true,
        transforms: _decodeTransformPolicy(
          value['transforms'],
          '$path.transforms',
        ),
        anchorWorld: value['anchorWorld'] == null
            ? null
            : Model3dVector3.fromJson(
                Map<String, dynamic>.from(
                  borderJsonRequireObject(
                    value['anchorWorld'],
                    '$path.anchorWorld',
                  ),
                ),
              ),
      ),
    );
  }
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _draftPrimitiveKeys,
    optionalKeys: formatVersion >= 4
        ? _primitiveOptionalKeysV4
        : const <String>{},
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
  if (value.isSpatial) {
    return _encodeSpatialPrimitive(
      path: path,
      formatVersion: formatVersion,
      id: value.id,
      sourceModelId: value.sourceModelId!,
      role: value.role,
      authoredOrientation: value.authoredOrientation,
      sequenceIndex: value.sequenceIndex,
      cornerTurn: value.cornerTurn,
      weight: value.weight,
      transforms: value.transforms,
      anchorWorld: value.anchorWorld,
      animationIndex: value.animationIndex,
      animationLoop: value.animationLoop,
      animationSpeed: value.animationSpeed,
      blocksMovement: value.blocksMovement,
      groundFootprints: value.groundFootprints,
      groundSurfaces: value.groundSurfaces,
    );
  }
  _validatePrimitiveIdentityAndWeight(
    id: value.id,
    sourceElementId: value.sourceElementId!,
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
  if (value.containsKey('sourceModelId')) {
    _validateSpatialPrimitiveJson(value, path, formatVersion);
    return borderJsonConstructAtPath(
      path,
      () => BorderPublishedPrimitive(
        id: borderJsonRequireString(value['id'], '$path.id'),
        sourceModelId: borderJsonRequireString(
          value['sourceModelId'],
          '$path.sourceModelId',
        ),
        role: _decodePrimitiveRoleField(value, path, formatVersion),
        authoredOrientation: _decodeAuthoredOrientationField(value, path),
        sequenceIndex: _decodeSequenceInteger(
          value,
          'sequenceIndex',
          0,
          path,
          formatVersion,
        ),
        cornerTurn: _decodeCornerTurn(value, path),
        weight: borderJsonRequireInt(value['weight'], '$path.weight'),
        animationIndex: value['animationIndex'] == null
            ? null
            : borderJsonRequireInt(
                value['animationIndex'],
                '$path.animationIndex',
              ),
        animationLoop: value.containsKey('animationLoop')
            ? borderJsonRequireBool(
                value['animationLoop'],
                '$path.animationLoop',
              )
            : true,
        animationSpeed: _decodeSpatialAnimationSpeed(value, path),
        groundFootprints: _decodeGroundFootprints(value, path, formatVersion),
        groundSurfaces: _decodeGroundSurfaces(value, path, formatVersion),
        blocksMovement: value.containsKey('blocksMovement')
            ? borderJsonRequireBool(
                value['blocksMovement'],
                '$path.blocksMovement',
              )
            : true,
        transforms: _decodeTransformPolicy(
          value['transforms'],
          '$path.transforms',
        ),
        anchorWorld: value['anchorWorld'] == null
            ? null
            : Model3dVector3.fromJson(
                Map<String, dynamic>.from(
                  borderJsonRequireObject(
                    value['anchorWorld'],
                    '$path.anchorWorld',
                  ),
                ),
              ),
      ),
    );
  }
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _publishedPrimitiveKeys,
    optionalKeys: formatVersion >= 4
        ? _primitiveOptionalKeysV4
        : const <String>{},
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

Map<String, Object?> _encodeSpatialPrimitive({
  required String path,
  required int formatVersion,
  required String id,
  required String sourceModelId,
  required BorderPrimitiveRole role,
  required BorderPrimitiveOrientation authoredOrientation,
  required int sequenceIndex,
  required BorderCornerTurn? cornerTurn,
  required int weight,
  required BorderTransformPolicy transforms,
  Model3dVector3? anchorWorld,
  required int? animationIndex,
  required bool animationLoop,
  required double animationSpeed,
  required bool blocksMovement,
  required List<BorderGroundFootprint> groundFootprints,
  required List<BorderGroundSurface> groundSurfaces,
}) {
  if (sequenceIndex != 0 && formatVersion < 12) {
    throw FormatException(
      '$path.sequenceIndex: requires catalog format version 12',
    );
  }
  if (formatVersion < 5) {
    throw FormatException(
      '$path: spatial primitives require catalog format version 5',
    );
  }
  if (groundFootprints.isNotEmpty && formatVersion < 8) {
    throw FormatException(
      '$path.groundFootprints: requires catalog format version 8',
    );
  }
  if (groundSurfaces.isNotEmpty && formatVersion < 9) {
    throw FormatException(
      '$path.groundSurfaces: requires catalog format version 9',
    );
  }
  if (formatVersion < 10 &&
      groundSurfaces.any(
        (surface) => surface.gradientX != 0 || surface.gradientZ != 0,
      )) {
    throw FormatException(
      '$path.groundSurfaces: inclined surfaces require catalog format version 10',
    );
  }
  return <String, Object?>{
    'id': id,
    'sourceModelId': sourceModelId,
    'role': _encodePrimitiveRole(role, formatVersion, '$path.role'),
    'authoredOrientation': authoredOrientation.name,
    if (sequenceIndex != 0) 'sequenceIndex': sequenceIndex,
    if (cornerTurn != null) 'cornerTurn': cornerTurn.name,
    'weight': weight,
    'transforms': _encodeTransformPolicy(transforms, '$path.transforms'),
    if (anchorWorld != null) 'anchorWorld': anchorWorld.toJson(),
    'animationIndex': animationIndex,
    'animationLoop': animationLoop,
    'animationSpeed': animationSpeed,
    'blocksMovement': blocksMovement,
    if (groundSurfaces.isNotEmpty)
      'groundSurfaces': [
        for (final surface in groundSurfaces)
          {
            'sourceSmartTilePresetId': surface.sourceSmartTilePresetId,
            'materialId': surface.materialId,
            'height': surface.height,
            if (surface.gradientX != 0 || surface.gradientZ != 0) ...{
              'gradientX': surface.gradientX,
              'gradientZ': surface.gradientZ,
            },
            'footprints': [
              for (final footprint in surface.footprints)
                [
                  for (final point in footprint.points)
                    {'x': point.x, 'z': point.z},
                ],
            ],
          },
      ],
    if (groundFootprints.isNotEmpty)
      'groundFootprints': [
        for (final footprint in groundFootprints)
          [
            for (final point in footprint.points) {'x': point.x, 'z': point.z},
          ],
      ],
  };
}

void _validateSpatialPrimitiveJson(
  BorderJsonObject value,
  String path,
  int formatVersion,
) {
  if (formatVersion < 5) {
    throw FormatException(
      '$path: spatial primitives require catalog format version 5',
    );
  }
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: const {'id', 'sourceModelId', 'role', 'weight', 'transforms'},
    optionalKeys: const {
      'authoredOrientation',
      'sequenceIndex',
      'cornerTurn',
      'anchorWorld',
      'animationIndex',
      'animationLoop',
      'animationSpeed',
      'blocksMovement',
      'groundFootprints',
      'groundSurfaces',
    },
  );
}

List<BorderGroundFootprint> _decodeGroundFootprints(
  BorderJsonObject value,
  String path,
  int formatVersion,
) {
  if (!value.containsKey('groundFootprints')) return const [];
  if (formatVersion < 8) {
    throw FormatException(
      '$path.groundFootprints: requires catalog format version 8',
    );
  }
  return _decodeGroundPolygons(
    value['groundFootprints'],
    '$path.groundFootprints',
  );
}

List<BorderGroundFootprint> _decodeGroundPolygons(Object? raw, String path) {
  if (raw is! List || raw.length > 8) {
    throw FormatException('$path: expected at most 8 polygons');
  }
  return [
    for (var index = 0; index < raw.length; index++)
      borderJsonConstructAtPath('$path[$index]', () {
        final points = raw[index];
        if (points is! List) {
          throw FormatException('$path[$index]: expected vertices');
        }
        return BorderGroundFootprint(
          points: [
            for (final item in points)
              (() {
                final point = borderJsonRequireObject(item, '$path[$index]');
                borderJsonRequireExactKeys(
                  point,
                  path: '$path[$index]',
                  requiredKeys: const {'x', 'z'},
                );
                final x = point['x'], z = point['z'];
                if (x is! num || z is! num) {
                  throw FormatException(
                    '$path[$index]: expected numeric coordinates',
                  );
                }
                return BorderGroundPoint(x: x.toDouble(), z: z.toDouble());
              })(),
          ],
        );
      }),
  ];
}

List<BorderGroundSurface> _decodeGroundSurfaces(
  BorderJsonObject value,
  String path,
  int formatVersion,
) {
  if (!value.containsKey('groundSurfaces')) return const [];
  final surfacePath = '$path.groundSurfaces';
  if (formatVersion < 9) {
    throw FormatException('$surfacePath: requires catalog format version 9');
  }
  final raw = value['groundSurfaces'];
  if (raw is! List || raw.length > 8) {
    throw FormatException('$surfacePath: expected at most 8 ground surfaces');
  }
  return [
    for (var index = 0; index < raw.length; index++)
      borderJsonConstructAtPath('$surfacePath[$index]', () {
        final itemPath = '$surfacePath[$index]';
        final item = borderJsonRequireObject(raw[index], itemPath);
        borderJsonRequireExactKeys(
          item,
          path: itemPath,
          requiredKeys: const {
            'sourceSmartTilePresetId',
            'materialId',
            'height',
            'footprints',
          },
          optionalKeys: const {'gradientX', 'gradientZ'},
        );
        final hasGradient =
            item.containsKey('gradientX') || item.containsKey('gradientZ');
        final gradientX = hasGradient ? item['gradientX'] : 0;
        final gradientZ = hasGradient ? item['gradientZ'] : 0;
        if (hasGradient && formatVersion < 10) {
          throw FormatException(
            '$itemPath: inclined surfaces require catalog format version 10',
          );
        }
        if (gradientX is! num ||
            !gradientX.isFinite ||
            gradientZ is! num ||
            !gradientZ.isFinite) {
          throw FormatException('$itemPath: expected two finite gradients');
        }
        final height = item['height'];
        if (height is! num || !height.isFinite) {
          throw FormatException('$itemPath.height: expected a finite number');
        }
        return BorderGroundSurface(
          sourceSmartTilePresetId: borderJsonRequireString(
            item['sourceSmartTilePresetId'],
            '$itemPath.sourceSmartTilePresetId',
          ),
          materialId: borderJsonRequireString(
            item['materialId'],
            '$itemPath.materialId',
          ),
          height: height.toDouble(),
          gradientX: gradientX.toDouble(),
          gradientZ: gradientZ.toDouble(),
          footprints: _decodeGroundPolygons(
            item['footprints'],
            '$itemPath.footprints',
          ),
        );
      }),
  ];
}

BorderCornerTurn? _decodeCornerTurn(BorderJsonObject value, String path) {
  if (!value.containsKey('cornerTurn')) return null;
  final name = borderJsonRequireString(value['cornerTurn'], '$path.cornerTurn');
  return BorderCornerTurn.values
          .where((turn) => turn.name == name)
          .firstOrNull ??
      (throw FormatException('$path.cornerTurn: unsupported corner turn'));
}

double _decodeSpatialAnimationSpeed(BorderJsonObject value, String path) {
  if (!value.containsKey('animationSpeed')) return 1;
  final speed = value['animationSpeed'];
  if (speed is! num) {
    throw FormatException('$path.animationSpeed: expected a number');
  }
  return speed.toDouble();
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
  borderJsonRequireExactKeys(value, path: path, requiredKeys: _transformKeys);
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

Map<String, Object?> _encodePixelPos(BorderPixelPos value) => <String, Object?>{
  'x': value.x,
  'y': value.y,
};

BorderPixelPos _decodePixelPos(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(value, path: path, requiredKeys: _pixelPosKeys);
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

Map<String, Object?> _encodeDraftGround(BorderGroundDraft value, String path) {
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
  borderJsonRequireExactKeys(value, path: path, requiredKeys: _draftGroundKeys);
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
  _validatePublishedGroundRoleMap(value.visualSnapshotIdsByRole, snapshotsPath);
  final snapshots = <String, Object?>{};
  for (final role in standardBorderGroundVariantRoleOrder) {
    snapshots[_encodeBorderGroundRole(role)] =
        value.visualSnapshotIdsByRole[role]!;
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
    requiredKeys: _borderGroundRoleKeys,
  );
  final snapshots = <BorderGroundVariantRole, String>{};
  for (final entry in snapshotValues.entries) {
    final entryPath = borderJsonPropertyPath(snapshotsPath, entry.key);
    final snapshotId = borderJsonRequireString(entry.value, entryPath);
    _requireNonEmpty(snapshotId, entryPath);
    snapshots[_decodeBorderGroundRole(entry.key, entryPath)] = snapshotId;
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
  Map<BorderGroundVariantRole, String> values,
  String path,
) {
  if (values.length != _borderGroundRoleKeys.length) {
    throw FormatException(
      '$path: must contain exactly all 20 Border ground roles',
    );
  }
  for (final role in standardBorderGroundVariantRoleOrder) {
    final roleName = _encodeBorderGroundRole(role);
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
    BorderBlueprintTemplate.horizontalFacade => 11,
    BorderBlueprintTemplate.ledgeLine => 7,
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
    'horizontalFacade' => BorderBlueprintTemplate.horizontalFacade,
    'stoneChainLine' => BorderBlueprintTemplate.stoneChainLine,
    'ledgeLine' => BorderBlueprintTemplate.ledgeLine,
    _ => throw FormatException('$path: unknown Border blueprint template'),
  };
  final minimumVersion = switch (template) {
    BorderBlueprintTemplate.horizontalFacade => 11,
    BorderBlueprintTemplate.ledgeLine => 7,
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
  BorderPrimitiveRole.lineCorner => true,
  _ => false,
};

void _requireBlueprintFormatVersion(int value, String path) {
  if (value < 1 || value > ProjectBorderCatalog.latestSupportedFormatVersion) {
    throw FormatException('$path: unsupported Border blueprint format version');
  }
}

String _encodeBorderGroundRole(BorderGroundVariantRole value) =>
    switch (value) {
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
      _ => throw FormatException('$path: unknown Border ground role'),
    };

Map<String, Object?> _encodeJumpBehavior(
  BorderJumpBehavior behavior,
  String path,
  int formatVersion,
) {
  if (formatVersion < 6) {
    throw FormatException(
      '$path.jumpBehavior: requires Border format version 6',
    );
  }
  return behavior.toJson();
}

BorderJumpBehavior? _decodeJumpBehavior(
  BorderJsonObject value,
  String path,
  int formatVersion,
) {
  if (!value.containsKey('jumpBehavior')) {
    return null;
  }
  if (formatVersion < 6) {
    throw FormatException(
      '$path.jumpBehavior: requires Border format version 6',
    );
  }
  return BorderJumpBehavior.fromJson(
    value['jumpBehavior'],
    path: '$path.jumpBehavior',
  );
}
