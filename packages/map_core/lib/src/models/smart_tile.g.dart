// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_tile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SmartTileSourceRect _$SmartTileSourceRectFromJson(Map<String, dynamic> json) =>
    _SmartTileSourceRect(
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$SmartTileSourceRectToJson(
  _SmartTileSourceRect instance,
) => <String, dynamic>{
  'x': instance.x,
  'y': instance.y,
  'width': instance.width,
  'height': instance.height,
};

_SmartTileFrameRef _$SmartTileFrameRefFromJson(Map<String, dynamic> json) =>
    _SmartTileFrameRef(
      atlasId: json['atlasId'] as String,
      column: (json['column'] as num).toInt(),
      row: (json['row'] as num).toInt(),
      columnSpan: (json['columnSpan'] as num?)?.toInt() ?? 1,
      rowSpan: (json['rowSpan'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$SmartTileFrameRefToJson(_SmartTileFrameRef instance) =>
    <String, dynamic>{
      'atlasId': instance.atlasId,
      'column': instance.column,
      'row': instance.row,
      'columnSpan': instance.columnSpan,
      'rowSpan': instance.rowSpan,
    };

_SmartTileSignature _$SmartTileSignatureFromJson(
  Map<String, dynamic> json,
) => _SmartTileSignature(
  northWestCorner: json['northWestCorner'] == null
      ? const SmartTileSlotMatch.any()
      : SmartTileSlotMatch.fromJson(
          json['northWestCorner'] as Map<String, dynamic>,
        ),
  northEdge: json['northEdge'] == null
      ? const SmartTileSlotMatch.any()
      : SmartTileSlotMatch.fromJson(json['northEdge'] as Map<String, dynamic>),
  northEastCorner: json['northEastCorner'] == null
      ? const SmartTileSlotMatch.any()
      : SmartTileSlotMatch.fromJson(
          json['northEastCorner'] as Map<String, dynamic>,
        ),
  eastEdge: json['eastEdge'] == null
      ? const SmartTileSlotMatch.any()
      : SmartTileSlotMatch.fromJson(json['eastEdge'] as Map<String, dynamic>),
  southEastCorner: json['southEastCorner'] == null
      ? const SmartTileSlotMatch.any()
      : SmartTileSlotMatch.fromJson(
          json['southEastCorner'] as Map<String, dynamic>,
        ),
  southEdge: json['southEdge'] == null
      ? const SmartTileSlotMatch.any()
      : SmartTileSlotMatch.fromJson(json['southEdge'] as Map<String, dynamic>),
  southWestCorner: json['southWestCorner'] == null
      ? const SmartTileSlotMatch.any()
      : SmartTileSlotMatch.fromJson(
          json['southWestCorner'] as Map<String, dynamic>,
        ),
  westEdge: json['westEdge'] == null
      ? const SmartTileSlotMatch.any()
      : SmartTileSlotMatch.fromJson(json['westEdge'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SmartTileSignatureToJson(_SmartTileSignature instance) =>
    <String, dynamic>{
      'northWestCorner': instance.northWestCorner.toJson(),
      'northEdge': instance.northEdge.toJson(),
      'northEastCorner': instance.northEastCorner.toJson(),
      'eastEdge': instance.eastEdge.toJson(),
      'southEastCorner': instance.southEastCorner.toJson(),
      'southEdge': instance.southEdge.toJson(),
      'southWestCorner': instance.southWestCorner.toJson(),
      'westEdge': instance.westEdge.toJson(),
    };

_SmartTileExactSignature _$SmartTileExactSignatureFromJson(
  Map<String, dynamic> json,
) => _SmartTileExactSignature(
  northEdge: json['northEdge'] as String?,
  northEastCorner: json['northEastCorner'] as String?,
  eastEdge: json['eastEdge'] as String?,
  southEastCorner: json['southEastCorner'] as String?,
  southEdge: json['southEdge'] as String?,
  southWestCorner: json['southWestCorner'] as String?,
  westEdge: json['westEdge'] as String?,
  northWestCorner: json['northWestCorner'] as String?,
);

Map<String, dynamic> _$SmartTileExactSignatureToJson(
  _SmartTileExactSignature instance,
) => <String, dynamic>{
  'northEdge': instance.northEdge,
  'northEastCorner': instance.northEastCorner,
  'eastEdge': instance.eastEdge,
  'southEastCorner': instance.southEastCorner,
  'southEdge': instance.southEdge,
  'southWestCorner': instance.southWestCorner,
  'westEdge': instance.westEdge,
  'northWestCorner': instance.northWestCorner,
};

_SmartTileCoverageScenario _$SmartTileCoverageScenarioFromJson(
  Map<String, dynamic> json,
) => _SmartTileCoverageScenario(
  id: json['id'] as String,
  centerMaterialId: json['centerMaterialId'] as String?,
  signature: json['signature'] == null
      ? const SmartTileExactSignature()
      : SmartTileExactSignature.fromJson(
          json['signature'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SmartTileCoverageScenarioToJson(
  _SmartTileCoverageScenario instance,
) => <String, dynamic>{
  'id': instance.id,
  'centerMaterialId': instance.centerMaterialId,
  'signature': instance.signature.toJson(),
};

_SmartTileCoverageProfile _$SmartTileCoverageProfileFromJson(
  Map<String, dynamic> json,
) => _SmartTileCoverageProfile(
  mode: $enumDecode(_$SmartTileCoverageModeEnumMap, json['mode']),
  requiredScenarios:
      (json['requiredScenarios'] as List<dynamic>?)
          ?.map(
            (e) =>
                SmartTileCoverageScenario.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <SmartTileCoverageScenario>[],
  allowFallback: json['allowFallback'] as bool? ?? false,
);

Map<String, dynamic> _$SmartTileCoverageProfileToJson(
  _SmartTileCoverageProfile instance,
) => <String, dynamic>{
  'mode': _$SmartTileCoverageModeEnumMap[instance.mode]!,
  'requiredScenarios': instance.requiredScenarios
      .map((e) => e.toJson())
      .toList(),
  'allowFallback': instance.allowFallback,
};

const _$SmartTileCoverageModeEnumMap = {
  SmartTileCoverageMode.template: 'template',
  SmartTileCoverageMode.explicit: 'explicit',
  SmartTileCoverageMode.templateAndExplicit: 'template_and_explicit',
};

_SmartTileTransformPolicy _$SmartTileTransformPolicyFromJson(
  Map<String, dynamic> json,
) => _SmartTileTransformPolicy(
  allowHFlip: json['allowHFlip'] as bool? ?? false,
  allowVFlip: json['allowVFlip'] as bool? ?? false,
  allowQuarterTurns: json['allowQuarterTurns'] as bool? ?? false,
  preferUntransformed: json['preferUntransformed'] as bool? ?? true,
);

Map<String, dynamic> _$SmartTileTransformPolicyToJson(
  _SmartTileTransformPolicy instance,
) => <String, dynamic>{
  'allowHFlip': instance.allowHFlip,
  'allowVFlip': instance.allowVFlip,
  'allowQuarterTurns': instance.allowQuarterTurns,
  'preferUntransformed': instance.preferUntransformed,
};

_SmartTileSpriteTransform _$SmartTileSpriteTransformFromJson(
  Map<String, dynamic> json,
) => _SmartTileSpriteTransform(
  quarterTurns: (json['quarterTurns'] as num?)?.toInt() ?? 0,
  flipX: json['flipX'] as bool? ?? false,
);

Map<String, dynamic> _$SmartTileSpriteTransformToJson(
  _SmartTileSpriteTransform instance,
) => <String, dynamic>{
  'quarterTurns': instance.quarterTurns,
  'flipX': instance.flipX,
};

SmartTileFrameSource _$SmartTileFrameSourceFromJson(
  Map<String, dynamic> json,
) => SmartTileFrameSource(
  frame: SmartTileFrameRef.fromJson(json['frame'] as Map<String, dynamic>),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$SmartTileFrameSourceToJson(
  SmartTileFrameSource instance,
) => <String, dynamic>{
  'frame': instance.frame.toJson(),
  'kind': instance.$type,
};

SmartTileAnimationSource _$SmartTileAnimationSourceFromJson(
  Map<String, dynamic> json,
) => SmartTileAnimationSource(
  animationId: json['animationId'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$SmartTileAnimationSourceToJson(
  SmartTileAnimationSource instance,
) => <String, dynamic>{
  'animationId': instance.animationId,
  'kind': instance.$type,
};

_SmartTileVisualPart _$SmartTileVisualPartFromJson(
  Map<String, dynamic> json,
) => _SmartTileVisualPart(
  source: SmartTileVisualSource.fromJson(
    json['source'] as Map<String, dynamic>,
  ),
  transform: json['transform'] == null
      ? const SmartTileSpriteTransform()
      : SmartTileSpriteTransform.fromJson(
          json['transform'] as Map<String, dynamic>,
        ),
  channel:
      $enumDecodeNullable(_$SmartTileRenderChannelEnumMap, json['channel']) ??
      SmartTileRenderChannel.ground,
  frameSampling:
      $enumDecodeNullable(
        _$SmartTileFrameSamplingEnumMap,
        json['frameSampling'],
      ) ??
      SmartTileFrameSampling.fullFrame,
  offsetUnit:
      $enumDecodeNullable(_$SmartTileOffsetUnitEnumMap, json['offsetUnit']) ??
      SmartTileOffsetUnit.pixel,
  offsetX: (json['offsetX'] as num?)?.toInt() ?? 0,
  offsetY: (json['offsetY'] as num?)?.toInt() ?? 0,
  footprintWidth: (json['footprintWidth'] as num?)?.toInt() ?? 1,
  footprintHeight: (json['footprintHeight'] as num?)?.toInt() ?? 1,
  anchorX: (json['anchorX'] as num?)?.toInt() ?? 0,
  anchorY: (json['anchorY'] as num?)?.toInt() ?? 0,
  drawOrder: (json['drawOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SmartTileVisualPartToJson(
  _SmartTileVisualPart instance,
) => <String, dynamic>{
  'source': instance.source.toJson(),
  'transform': instance.transform.toJson(),
  'channel': _$SmartTileRenderChannelEnumMap[instance.channel]!,
  'frameSampling': _$SmartTileFrameSamplingEnumMap[instance.frameSampling]!,
  'offsetUnit': _$SmartTileOffsetUnitEnumMap[instance.offsetUnit]!,
  'offsetX': instance.offsetX,
  'offsetY': instance.offsetY,
  'footprintWidth': instance.footprintWidth,
  'footprintHeight': instance.footprintHeight,
  'anchorX': instance.anchorX,
  'anchorY': instance.anchorY,
  'drawOrder': instance.drawOrder,
};

const _$SmartTileRenderChannelEnumMap = {
  SmartTileRenderChannel.ground: 'ground',
  SmartTileRenderChannel.understory: 'understory',
  SmartTileRenderChannel.canopy: 'canopy',
  SmartTileRenderChannel.foreground: 'foreground',
  SmartTileRenderChannel.actorOcclusion: 'actor_occlusion',
  SmartTileRenderChannel.shadow: 'shadow',
};

const _$SmartTileFrameSamplingEnumMap = {
  SmartTileFrameSampling.fullFrame: 'full_frame',
  SmartTileFrameSampling.tessellated: 'tessellated',
  SmartTileFrameSampling.stableRandom: 'stable_random',
};

const _$SmartTileOffsetUnitEnumMap = {
  SmartTileOffsetUnit.pixel: 'pixel',
  SmartTileOffsetUnit.cell: 'cell',
};

_SmartTilePatternCell _$SmartTilePatternCellFromJson(
  Map<String, dynamic> json,
) => _SmartTilePatternCell(
  x: (json['x'] as num).toInt(),
  y: (json['y'] as num).toInt(),
  parts:
      (json['parts'] as List<dynamic>?)
          ?.map((e) => SmartTileVisualPart.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SmartTileVisualPart>[],
  eraseMaterial: json['eraseMaterial'] as bool? ?? false,
  collision:
      $enumDecodeNullable(
        _$SmartTilePatternCollisionEnumMap,
        json['collision'],
      ) ??
      SmartTilePatternCollision.inherit,
);

Map<String, dynamic> _$SmartTilePatternCellToJson(
  _SmartTilePatternCell instance,
) => <String, dynamic>{
  'x': instance.x,
  'y': instance.y,
  'parts': instance.parts.map((e) => e.toJson()).toList(),
  'eraseMaterial': instance.eraseMaterial,
  'collision': _$SmartTilePatternCollisionEnumMap[instance.collision]!,
};

const _$SmartTilePatternCollisionEnumMap = {
  SmartTilePatternCollision.inherit: 'inherit',
  SmartTilePatternCollision.passable: 'passable',
  SmartTilePatternCollision.blocked: 'blocked',
};

_ProjectSmartTilePattern _$ProjectSmartTilePatternFromJson(
  Map<String, dynamic> json,
) => _ProjectSmartTilePattern(
  id: json['id'] as String,
  name: json['name'] as String,
  categoryId: json['categoryId'] as String? ?? '',
  usage: $enumDecode(_$SmartTileUsageEnumMap, json['usage']),
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  anchorX: (json['anchorX'] as num?)?.toInt() ?? 0,
  anchorY: (json['anchorY'] as num?)?.toInt() ?? 0,
  repeatMode:
      $enumDecodeNullable(
        _$SmartTilePatternRepeatModeEnumMap,
        json['repeatMode'],
      ) ??
      SmartTilePatternRepeatMode.tiled,
  cells:
      (json['cells'] as List<dynamic>?)
          ?.map((e) => SmartTilePatternCell.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SmartTilePatternCell>[],
  drawOrder: (json['drawOrder'] as num?)?.toInt() ?? 0,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectSmartTilePatternToJson(
  _ProjectSmartTilePattern instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'categoryId': instance.categoryId,
  'usage': _$SmartTileUsageEnumMap[instance.usage]!,
  'width': instance.width,
  'height': instance.height,
  'anchorX': instance.anchorX,
  'anchorY': instance.anchorY,
  'repeatMode': _$SmartTilePatternRepeatModeEnumMap[instance.repeatMode]!,
  'cells': instance.cells.map((e) => e.toJson()).toList(),
  'drawOrder': instance.drawOrder,
  'tags': instance.tags,
  'sortOrder': instance.sortOrder,
};

const _$SmartTileUsageEnumMap = {
  SmartTileUsage.terrain: 'terrain',
  SmartTileUsage.path: 'path',
  SmartTileUsage.forestSurface: 'forest_surface',
};

const _$SmartTilePatternRepeatModeEnumMap = {
  SmartTilePatternRepeatMode.tiled: 'tiled',
  SmartTilePatternRepeatMode.stamp: 'stamp',
};

_SmartTilePatternStroke _$SmartTilePatternStrokeFromJson(
  Map<String, dynamic> json,
) => _SmartTilePatternStroke(
  id: json['id'] as String,
  patternId: json['patternId'] as String,
  cells: (json['cells'] as List<dynamic>)
      .map((e) => GridPos.fromJson(e as Map<String, dynamic>))
      .toList(),
  phaseX: (json['phaseX'] as num?)?.toInt() ?? 0,
  phaseY: (json['phaseY'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SmartTilePatternStrokeToJson(
  _SmartTilePatternStroke instance,
) => <String, dynamic>{
  'id': instance.id,
  'patternId': instance.patternId,
  'cells': instance.cells.map((e) => e.toJson()).toList(),
  'phaseX': instance.phaseX,
  'phaseY': instance.phaseY,
};

_SmartTileCandidate _$SmartTileCandidateFromJson(Map<String, dynamic> json) =>
    _SmartTileCandidate(
      id: json['id'] as String,
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      parts:
          (json['parts'] as List<dynamic>?)
              ?.map(
                (e) => SmartTileVisualPart.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <SmartTileVisualPart>[],
    );

Map<String, dynamic> _$SmartTileCandidateToJson(_SmartTileCandidate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weight': instance.weight,
      'parts': instance.parts.map((e) => e.toJson()).toList(),
    };

_SmartTileRule _$SmartTileRuleFromJson(
  Map<String, dynamic> json,
) => _SmartTileRule(
  id: json['id'] as String,
  centerMatch: SmartTileSlotMatch.fromJson(
    json['centerMatch'] as Map<String, dynamic>,
  ),
  signature: json['signature'] == null
      ? const SmartTileSignature()
      : SmartTileSignature.fromJson(json['signature'] as Map<String, dynamic>),
  candidates:
      (json['candidates'] as List<dynamic>?)
          ?.map((e) => SmartTileCandidate.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SmartTileCandidate>[],
);

Map<String, dynamic> _$SmartTileRuleToJson(_SmartTileRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'centerMatch': instance.centerMatch.toJson(),
      'signature': instance.signature.toJson(),
      'candidates': instance.candidates.map((e) => e.toJson()).toList(),
    };

_ProjectSmartTileCategory _$ProjectSmartTileCategoryFromJson(
  Map<String, dynamic> json,
) => _ProjectSmartTileCategory(
  id: json['id'] as String,
  name: json['name'] as String,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectSmartTileCategoryToJson(
  _ProjectSmartTileCategory instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sortOrder': instance.sortOrder,
};

_ProjectSmartTileAtlas _$ProjectSmartTileAtlasFromJson(
  Map<String, dynamic> json,
) => _ProjectSmartTileAtlas(
  id: json['id'] as String,
  name: json['name'] as String,
  tilesetId: json['tilesetId'] as String,
  cellWidth: (json['cellWidth'] as num?)?.toInt() ?? 32,
  cellHeight: (json['cellHeight'] as num?)?.toInt() ?? 32,
  originX: (json['originX'] as num?)?.toInt() ?? 0,
  originY: (json['originY'] as num?)?.toInt() ?? 0,
  marginX: (json['marginX'] as num?)?.toInt() ?? 0,
  marginY: (json['marginY'] as num?)?.toInt() ?? 0,
  spacingX: (json['spacingX'] as num?)?.toInt() ?? 0,
  spacingY: (json['spacingY'] as num?)?.toInt() ?? 0,
  columns: (json['columns'] as num).toInt(),
  rows: (json['rows'] as num).toInt(),
  pixelOffsetX: (json['pixelOffsetX'] as num?)?.toInt() ?? 0,
  pixelOffsetY: (json['pixelOffsetY'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectSmartTileAtlasToJson(
  _ProjectSmartTileAtlas instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'tilesetId': instance.tilesetId,
  'cellWidth': instance.cellWidth,
  'cellHeight': instance.cellHeight,
  'originX': instance.originX,
  'originY': instance.originY,
  'marginX': instance.marginX,
  'marginY': instance.marginY,
  'spacingX': instance.spacingX,
  'spacingY': instance.spacingY,
  'columns': instance.columns,
  'rows': instance.rows,
  'pixelOffsetX': instance.pixelOffsetX,
  'pixelOffsetY': instance.pixelOffsetY,
};

_ProjectSmartTileMaterial _$ProjectSmartTileMaterialFromJson(
  Map<String, dynamic> json,
) => _ProjectSmartTileMaterial(
  id: json['id'] as String,
  name: json['name'] as String,
  connectionGroupId: json['connectionGroupId'] as String,
  categoryId: json['categoryId'] as String? ?? '',
  terrainType: $enumDecodeNullable(_$TerrainTypeEnumMap, json['terrainType']),
  pathSurfaceKind: $enumDecodeNullable(
    _$PathSurfaceKindEnumMap,
    json['pathSurfaceKind'],
  ),
  isEmpty: json['isEmpty'] as bool? ?? false,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  editorColorArgb: (json['editorColorArgb'] as num?)?.toInt(),
);

Map<String, dynamic> _$ProjectSmartTileMaterialToJson(
  _ProjectSmartTileMaterial instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'connectionGroupId': instance.connectionGroupId,
  'categoryId': instance.categoryId,
  'terrainType': _$TerrainTypeEnumMap[instance.terrainType],
  'pathSurfaceKind': _$PathSurfaceKindEnumMap[instance.pathSurfaceKind],
  'isEmpty': instance.isEmpty,
  'sortOrder': instance.sortOrder,
  'editorColorArgb': instance.editorColorArgb,
};

const _$TerrainTypeEnumMap = {
  TerrainType.none: 'none',
  TerrainType.grass: 'grass',
  TerrainType.dirt: 'dirt',
  TerrainType.sand: 'sand',
  TerrainType.rock: 'rock',
  TerrainType.stone: 'stone',
  TerrainType.indoor: 'indoor',
};

const _$PathSurfaceKindEnumMap = {
  PathSurfaceKind.path: 'path',
  PathSurfaceKind.road: 'road',
  PathSurfaceKind.water: 'water',
  PathSurfaceKind.tallGrass: 'tall_grass',
  PathSurfaceKind.ice: 'ice',
  PathSurfaceKind.lava: 'lava',
  PathSurfaceKind.swamp: 'swamp',
  PathSurfaceKind.rails: 'rails',
  PathSurfaceKind.bridge: 'bridge',
  PathSurfaceKind.special: 'special',
  PathSurfaceKind.custom: 'custom',
};

_ProjectSmartTileAnimationFrame _$ProjectSmartTileAnimationFrameFromJson(
  Map<String, dynamic> json,
) => _ProjectSmartTileAnimationFrame(
  frame: SmartTileFrameRef.fromJson(json['frame'] as Map<String, dynamic>),
  durationMs: (json['durationMs'] as num).toInt(),
);

Map<String, dynamic> _$ProjectSmartTileAnimationFrameToJson(
  _ProjectSmartTileAnimationFrame instance,
) => <String, dynamic>{
  'frame': instance.frame.toJson(),
  'durationMs': instance.durationMs,
};

_ProjectSmartTileAnimation _$ProjectSmartTileAnimationFromJson(
  Map<String, dynamic> json,
) => _ProjectSmartTileAnimation(
  id: json['id'] as String,
  name: json['name'] as String,
  frames: (json['frames'] as List<dynamic>)
      .map(
        (e) =>
            ProjectSmartTileAnimationFrame.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  sync:
      $enumDecodeNullable(_$SmartTileAnimationSyncEnumMap, json['sync']) ??
      SmartTileAnimationSync.global,
  loop:
      $enumDecodeNullable(_$SmartTileAnimationLoopEnumMap, json['loop']) ??
      SmartTileAnimationLoop.repeat,
);

Map<String, dynamic> _$ProjectSmartTileAnimationToJson(
  _ProjectSmartTileAnimation instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'frames': instance.frames.map((e) => e.toJson()).toList(),
  'sync': _$SmartTileAnimationSyncEnumMap[instance.sync]!,
  'loop': _$SmartTileAnimationLoopEnumMap[instance.loop]!,
};

const _$SmartTileAnimationSyncEnumMap = {
  SmartTileAnimationSync.global: 'global',
  SmartTileAnimationSync.perCell: 'per_cell',
};

const _$SmartTileAnimationLoopEnumMap = {
  SmartTileAnimationLoop.repeat: 'repeat',
  SmartTileAnimationLoop.pingPong: 'ping_pong',
  SmartTileAnimationLoop.once: 'once',
};

_ProjectSmartTilePreset _$ProjectSmartTilePresetFromJson(
  Map<String, dynamic> json,
) => _ProjectSmartTilePreset(
  id: json['id'] as String,
  name: json['name'] as String,
  categoryId: json['categoryId'] as String? ?? '',
  usage: $enumDecode(_$SmartTileUsageEnumMap, json['usage']),
  topology: $enumDecode(_$SmartTileTopologyEnumMap, json['topology']),
  templateHint:
      $enumDecodeNullable(
        _$SmartTileTemplateHintEnumMap,
        json['templateHint'],
      ) ??
      SmartTileTemplateHint.free,
  boundaryPolicy:
      $enumDecodeNullable(
        _$SmartTileBoundaryPolicyEnumMap,
        json['boundaryPolicy'],
      ) ??
      SmartTileBoundaryPolicy.empty,
  status:
      $enumDecodeNullable(_$SmartTilePresetStatusEnumMap, json['status']) ??
      SmartTilePresetStatus.draft,
  coveragePolicy: $enumDecode(
    _$SmartTileCoveragePolicyEnumMap,
    json['coveragePolicy'],
  ),
  coverageProfile: SmartTileCoverageProfile.fromJson(
    json['coverageProfile'] as Map<String, dynamic>,
  ),
  transformPolicy: SmartTileTransformPolicy.fromJson(
    json['transformPolicy'] as Map<String, dynamic>,
  ),
  defaultMaterialId: json['defaultMaterialId'] as String,
  allowedMaterialIds: (json['allowedMaterialIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  rules:
      (json['rules'] as List<dynamic>?)
          ?.map((e) => SmartTileRule.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SmartTileRule>[],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  seedSalt: (json['seedSalt'] as num?)?.toInt() ?? 0,
  fallbackRuleId: json['fallbackRuleId'] as String?,
);

Map<String, dynamic> _$ProjectSmartTilePresetToJson(
  _ProjectSmartTilePreset instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'categoryId': instance.categoryId,
  'usage': _$SmartTileUsageEnumMap[instance.usage]!,
  'topology': _$SmartTileTopologyEnumMap[instance.topology]!,
  'templateHint': _$SmartTileTemplateHintEnumMap[instance.templateHint]!,
  'boundaryPolicy': _$SmartTileBoundaryPolicyEnumMap[instance.boundaryPolicy]!,
  'status': _$SmartTilePresetStatusEnumMap[instance.status]!,
  'coveragePolicy': _$SmartTileCoveragePolicyEnumMap[instance.coveragePolicy]!,
  'coverageProfile': instance.coverageProfile.toJson(),
  'transformPolicy': instance.transformPolicy.toJson(),
  'defaultMaterialId': instance.defaultMaterialId,
  'allowedMaterialIds': instance.allowedMaterialIds,
  'rules': instance.rules.map((e) => e.toJson()).toList(),
  'tags': instance.tags,
  'sortOrder': instance.sortOrder,
  'seedSalt': instance.seedSalt,
  'fallbackRuleId': instance.fallbackRuleId,
};

const _$SmartTileTopologyEnumMap = {
  SmartTileTopology.uniform: 'uniform',
  SmartTileTopology.cardinal4: 'cardinal_4',
  SmartTileTopology.blob8: 'blob_8',
  SmartTileTopology.wangEdge4: 'wang_edge_4',
  SmartTileTopology.wangCorner4: 'wang_corner_4',
  SmartTileTopology.wang8: 'wang_8',
};

const _$SmartTileTemplateHintEnumMap = {
  SmartTileTemplateHint.simple: 'simple',
  SmartTileTemplateHint.edge16: 'edge_16',
  SmartTileTemplateHint.corner16: 'corner_16',
  SmartTileTemplateHint.corner12: 'corner_12',
  SmartTileTemplateHint.blob47: 'blob_47',
  SmartTileTemplateHint.mixed256: 'mixed_256',
  SmartTileTemplateHint.free: 'free',
};

const _$SmartTileBoundaryPolicyEnumMap = {
  SmartTileBoundaryPolicy.empty: 'empty',
  SmartTileBoundaryPolicy.connected: 'connected',
};

const _$SmartTilePresetStatusEnumMap = {
  SmartTilePresetStatus.draft: 'draft',
  SmartTilePresetStatus.published: 'published',
};

const _$SmartTileCoveragePolicyEnumMap = {
  SmartTileCoveragePolicy.complete: 'complete',
  SmartTileCoveragePolicy.sparse: 'sparse',
};

_ProjectSmartTileAuthoringDraft _$ProjectSmartTileAuthoringDraftFromJson(
  Map<String, dynamic> json,
) => _ProjectSmartTileAuthoringDraft(
  id: json['id'] as String,
  targetPresetId: json['targetPresetId'] as String,
  sourcePresetId: json['sourcePresetId'] as String?,
  name: json['name'] as String,
  categoryId: json['categoryId'] as String? ?? '',
  usage: $enumDecode(_$SmartTileUsageEnumMap, json['usage']),
  lastStage: $enumDecode(_$SmartTileAuthoringStageEnumMap, json['lastStage']),
  guideId: json['guideId'] as String?,
  sourceTilesetIds:
      (json['sourceTilesetIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  atlases:
      (json['atlases'] as List<dynamic>?)
          ?.map(
            (e) => ProjectSmartTileAtlas.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ProjectSmartTileAtlas>[],
  primaryAtlasId: json['primaryAtlasId'] as String?,
  materials:
      (json['materials'] as List<dynamic>?)
          ?.map(
            (e) => ProjectSmartTileMaterial.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ProjectSmartTileMaterial>[],
  animations:
      (json['animations'] as List<dynamic>?)
          ?.map(
            (e) =>
                ProjectSmartTileAnimation.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ProjectSmartTileAnimation>[],
  defaultMaterialId: json['defaultMaterialId'] as String?,
  allowedMaterialIds:
      (json['allowedMaterialIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  topology:
      $enumDecodeNullable(_$SmartTileTopologyEnumMap, json['topology']) ??
      SmartTileTopology.uniform,
  templateHint:
      $enumDecodeNullable(
        _$SmartTileTemplateHintEnumMap,
        json['templateHint'],
      ) ??
      SmartTileTemplateHint.simple,
  boundaryPolicy:
      $enumDecodeNullable(
        _$SmartTileBoundaryPolicyEnumMap,
        json['boundaryPolicy'],
      ) ??
      SmartTileBoundaryPolicy.empty,
  coveragePolicy:
      $enumDecodeNullable(
        _$SmartTileCoveragePolicyEnumMap,
        json['coveragePolicy'],
      ) ??
      SmartTileCoveragePolicy.complete,
  coverageProfile: json['coverageProfile'] == null
      ? const SmartTileCoverageProfile(mode: SmartTileCoverageMode.template)
      : SmartTileCoverageProfile.fromJson(
          json['coverageProfile'] as Map<String, dynamic>,
        ),
  transformPolicy: json['transformPolicy'] == null
      ? const SmartTileTransformPolicy()
      : SmartTileTransformPolicy.fromJson(
          json['transformPolicy'] as Map<String, dynamic>,
        ),
  rules:
      (json['rules'] as List<dynamic>?)
          ?.map((e) => SmartTileRule.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SmartTileRule>[],
  fallbackRuleId: json['fallbackRuleId'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  seedSalt: (json['seedSalt'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectSmartTileAuthoringDraftToJson(
  _ProjectSmartTileAuthoringDraft instance,
) => <String, dynamic>{
  'id': instance.id,
  'targetPresetId': instance.targetPresetId,
  'sourcePresetId': instance.sourcePresetId,
  'name': instance.name,
  'categoryId': instance.categoryId,
  'usage': _$SmartTileUsageEnumMap[instance.usage]!,
  'lastStage': _$SmartTileAuthoringStageEnumMap[instance.lastStage]!,
  'guideId': instance.guideId,
  'sourceTilesetIds': instance.sourceTilesetIds,
  'atlases': instance.atlases.map((e) => e.toJson()).toList(),
  'primaryAtlasId': instance.primaryAtlasId,
  'materials': instance.materials.map((e) => e.toJson()).toList(),
  'animations': instance.animations.map((e) => e.toJson()).toList(),
  'defaultMaterialId': instance.defaultMaterialId,
  'allowedMaterialIds': instance.allowedMaterialIds,
  'topology': _$SmartTileTopologyEnumMap[instance.topology]!,
  'templateHint': _$SmartTileTemplateHintEnumMap[instance.templateHint]!,
  'boundaryPolicy': _$SmartTileBoundaryPolicyEnumMap[instance.boundaryPolicy]!,
  'coveragePolicy': _$SmartTileCoveragePolicyEnumMap[instance.coveragePolicy]!,
  'coverageProfile': instance.coverageProfile.toJson(),
  'transformPolicy': instance.transformPolicy.toJson(),
  'rules': instance.rules.map((e) => e.toJson()).toList(),
  'fallbackRuleId': instance.fallbackRuleId,
  'tags': instance.tags,
  'sortOrder': instance.sortOrder,
  'seedSalt': instance.seedSalt,
};

const _$SmartTileAuthoringStageEnumMap = {
  SmartTileAuthoringStage.usage: 'usage',
  SmartTileAuthoringStage.image: 'image',
  SmartTileAuthoringStage.grid: 'grid',
  SmartTileAuthoringStage.materials: 'materials',
  SmartTileAuthoringStage.connections: 'connections',
  SmartTileAuthoringStage.variants: 'variants',
  SmartTileAuthoringStage.forms: 'forms',
  SmartTileAuthoringStage.test: 'test',
  SmartTileAuthoringStage.publish: 'publish',
};
