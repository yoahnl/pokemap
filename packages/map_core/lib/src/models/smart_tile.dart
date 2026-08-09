// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';

part 'smart_tile.freezed.dart';
part 'smart_tile.g.dart';

enum SmartTileUsage {
  @JsonValue('terrain')
  terrain,
  @JsonValue('path')
  path,
  @JsonValue('forest_surface')
  forestSurface,
}

enum SmartTileTopology {
  @JsonValue('uniform')
  uniform,
  @JsonValue('cardinal_4')
  cardinal4,
  @JsonValue('blob_8')
  blob8,
  @JsonValue('wang_edge_4')
  wangEdge4,
  @JsonValue('wang_corner_4')
  wangCorner4,
  @JsonValue('wang_8')
  wang8,
}

enum SmartTileTemplateHint {
  @JsonValue('simple')
  simple,
  @JsonValue('edge_16')
  edge16,
  @JsonValue('corner_16')
  corner16,
  @JsonValue('corner_12')
  corner12,
  @JsonValue('blob_47')
  blob47,
  @JsonValue('mixed_256')
  mixed256,
  @JsonValue('free')
  free,
}

enum SmartTileBoundaryPolicy {
  @JsonValue('empty')
  empty,
  @JsonValue('connected')
  connected,
}

enum SmartTileCoveragePolicy {
  @JsonValue('complete')
  complete,
  @JsonValue('sparse')
  sparse,
}

enum SmartTileCoverageMode {
  @JsonValue('template')
  template,
  @JsonValue('explicit')
  explicit,
  @JsonValue('template_and_explicit')
  templateAndExplicit,
}

enum SmartTilePresetStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
}

enum SmartTileAuthoringStage {
  @JsonValue('usage')
  usage,
  @JsonValue('image')
  image,
  @JsonValue('grid')
  grid,
  @JsonValue('materials')
  materials,
  @JsonValue('connections')
  connections,
  @JsonValue('variants')
  variants,
  @JsonValue('forms')
  forms,
  @JsonValue('test')
  test,
  @JsonValue('publish')
  publish,
}

enum SmartTileRenderChannel {
  @JsonValue('ground')
  ground,
  @JsonValue('understory')
  understory,
  @JsonValue('canopy')
  canopy,
  @JsonValue('foreground')
  foreground,
  @JsonValue('actor_occlusion')
  actorOcclusion,
  @JsonValue('shadow')
  shadow,
}

enum SmartTileAnimationSync {
  @JsonValue('global')
  global,
  @JsonValue('per_cell')
  perCell,
}

enum SmartTileAnimationLoop {
  @JsonValue('repeat')
  repeat,
  @JsonValue('ping_pong')
  pingPong,
  @JsonValue('once')
  once,
}

enum SmartTileMatchKind {
  @JsonValue('any')
  any,
  @JsonValue('same')
  same,
  @JsonValue('different')
  different,
  @JsonValue('empty')
  empty,
  @JsonValue('material')
  material,
}

enum SmartTileOffsetUnit {
  @JsonValue('pixel')
  pixel,
  @JsonValue('cell')
  cell,
}

/// Controls how a visual part samples a frame larger than one atlas cell.
///
/// [fullFrame] preserves the native Smart Tile behavior: the complete frame is
/// drawn for the resolved cell. The other modes support authored textures
/// larger than one map cell without squashing them.
enum SmartTileFrameSampling {
  @JsonValue('full_frame')
  fullFrame,
  @JsonValue('tessellated')
  tessellated,
  @JsonValue('stable_random')
  stableRandom,
}

enum SmartTilePatternRepeatMode {
  @JsonValue('tiled')
  tiled,
  @JsonValue('stamp')
  stamp,
}

enum SmartTilePatternCollision {
  @JsonValue('inherit')
  inherit,
  @JsonValue('passable')
  passable,
  @JsonValue('blocked')
  blocked,
}

void _requireStrictJsonIntegers(
  Map<String, dynamic> json,
  Iterable<String> fields, {
  Set<String> nullableFields = const <String>{},
}) {
  for (final field in fields) {
    if (!json.containsKey(field)) continue;
    final value = json[field];
    if (value == null && nullableFields.contains(field)) continue;
    if (value is! int) {
      throw FormatException(
        'smart_tile_integer_invalid: $field must be an exact JSON integer',
      );
    }
  }
}

@freezed
abstract class SmartTileSourceRect with _$SmartTileSourceRect {
  @Assert('x >= 0', 'x must not be negative')
  @Assert('y >= 0', 'y must not be negative')
  @Assert('width > 0', 'width must be positive')
  @Assert('height > 0', 'height must be positive')
  const factory SmartTileSourceRect({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _SmartTileSourceRect;

  factory SmartTileSourceRect.fromJson(Map<String, dynamic> json) =>
      _smartTileSourceRectFromJson(json);
}

SmartTileSourceRect _smartTileSourceRectFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>[
    'x',
    'y',
    'width',
    'height',
  ]);
  return _$SmartTileSourceRectFromJson(json);
}

@freezed
abstract class SmartTileFrameRef with _$SmartTileFrameRef {
  @Assert('atlasId != ""', 'atlasId must not be blank')
  @Assert('column >= 0', 'column must not be negative')
  @Assert('row >= 0', 'row must not be negative')
  @Assert('columnSpan > 0', 'columnSpan must be positive')
  @Assert('rowSpan > 0', 'rowSpan must be positive')
  const factory SmartTileFrameRef({
    required String atlasId,
    required int column,
    required int row,
    @Default(1) int columnSpan,
    @Default(1) int rowSpan,
  }) = _SmartTileFrameRef;

  factory SmartTileFrameRef.fromJson(Map<String, dynamic> json) =>
      _smartTileFrameRefFromJson(json);
}

SmartTileFrameRef _smartTileFrameRefFromJson(Map<String, dynamic> json) {
  final atlasId = json['atlasId'];
  final column = json['column'];
  final row = json['row'];
  final columnSpan = json['columnSpan'] ?? 1;
  final rowSpan = json['rowSpan'] ?? 1;
  if (atlasId is! String ||
      atlasId.trim().isEmpty ||
      atlasId != atlasId.trim() ||
      column is! int ||
      column < 0 ||
      row is! int ||
      row < 0 ||
      columnSpan is! int ||
      columnSpan <= 0 ||
      rowSpan is! int ||
      rowSpan <= 0) {
    throw const FormatException(
      'smart_tile_frame_ref_invalid: frame reference identifiers and '
      'lower bounds must be canonical',
    );
  }
  return _$SmartTileFrameRefFromJson(json);
}

@immutable
final class SmartTileSlotMatch {
  const SmartTileSlotMatch({
    this.kind = SmartTileMatchKind.any,
    this.materialId,
  }) : assert(
          kind == SmartTileMatchKind.material
              ? materialId != null && materialId != ''
              : materialId == null,
          'materialId is required only for a material match',
        );

  const SmartTileSlotMatch.any()
      : kind = SmartTileMatchKind.any,
        materialId = null;

  const SmartTileSlotMatch.same()
      : kind = SmartTileMatchKind.same,
        materialId = null;

  const SmartTileSlotMatch.different()
      : kind = SmartTileMatchKind.different,
        materialId = null;

  const SmartTileSlotMatch.empty()
      : kind = SmartTileMatchKind.empty,
        materialId = null;

  const SmartTileSlotMatch.material(String id)
      : assert(id != '', 'materialId must not be blank'),
        kind = SmartTileMatchKind.material,
        materialId = id;

  factory SmartTileSlotMatch.fromJson(Map<String, dynamic> json) {
    final kind = _smartTileMatchKindFromJson(json['kind']);
    final hasMaterialId = json.containsKey('materialId');
    final rawMaterialId = json['materialId'];
    final materialId = rawMaterialId is String ? rawMaterialId : null;
    final validMaterial = kind == SmartTileMatchKind.material &&
        materialId != null &&
        materialId.isNotEmpty &&
        materialId == materialId.trim();
    final validNonMaterial =
        kind != SmartTileMatchKind.material && !hasMaterialId;
    if (!validMaterial && !validNonMaterial) {
      throw const FormatException(
        'smart_tile_slot_match_invalid: materialId is required only for a '
        'canonical material match',
      );
    }
    return SmartTileSlotMatch(kind: kind, materialId: materialId);
  }

  final SmartTileMatchKind kind;
  final String? materialId;

  Map<String, Object?> toJson() => <String, Object?>{
        'kind': _smartTileMatchKindToJson(kind),
        if (materialId != null) 'materialId': materialId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartTileSlotMatch &&
          other.kind == kind &&
          other.materialId == materialId;

  @override
  int get hashCode => Object.hash(kind, materialId);
}

SmartTileMatchKind _smartTileMatchKindFromJson(Object? json) {
  return switch (json) {
    'any' => SmartTileMatchKind.any,
    'same' => SmartTileMatchKind.same,
    'different' => SmartTileMatchKind.different,
    'empty' => SmartTileMatchKind.empty,
    'material' => SmartTileMatchKind.material,
    _ => throw FormatException(
        'Unknown Smart Tile match kind: $json',
      ),
  };
}

String _smartTileMatchKindToJson(SmartTileMatchKind kind) {
  return switch (kind) {
    SmartTileMatchKind.any => 'any',
    SmartTileMatchKind.same => 'same',
    SmartTileMatchKind.different => 'different',
    SmartTileMatchKind.empty => 'empty',
    SmartTileMatchKind.material => 'material',
  };
}

@freezed
abstract class SmartTileSignature with _$SmartTileSignature {
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileSignature({
    @Default(SmartTileSlotMatch.any()) SmartTileSlotMatch northWestCorner,
    @Default(SmartTileSlotMatch.any()) SmartTileSlotMatch northEdge,
    @Default(SmartTileSlotMatch.any()) SmartTileSlotMatch northEastCorner,
    @Default(SmartTileSlotMatch.any()) SmartTileSlotMatch eastEdge,
    @Default(SmartTileSlotMatch.any()) SmartTileSlotMatch southEastCorner,
    @Default(SmartTileSlotMatch.any()) SmartTileSlotMatch southEdge,
    @Default(SmartTileSlotMatch.any()) SmartTileSlotMatch southWestCorner,
    @Default(SmartTileSlotMatch.any()) SmartTileSlotMatch westEdge,
  }) = _SmartTileSignature;

  factory SmartTileSignature.fromJson(Map<String, dynamic> json) =>
      _$SmartTileSignatureFromJson(json);
}

@freezed
abstract class SmartTileExactSignature with _$SmartTileExactSignature {
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileExactSignature({
    String? northEdge,
    String? northEastCorner,
    String? eastEdge,
    String? southEastCorner,
    String? southEdge,
    String? southWestCorner,
    String? westEdge,
    String? northWestCorner,
  }) = _SmartTileExactSignature;

  factory SmartTileExactSignature.fromJson(Map<String, dynamic> json) =>
      _$SmartTileExactSignatureFromJson(json);
}

@freezed
abstract class SmartTileCoverageScenario with _$SmartTileCoverageScenario {
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileCoverageScenario({
    required String id,
    String? centerMaterialId,
    @Default(SmartTileExactSignature()) SmartTileExactSignature signature,
  }) = _SmartTileCoverageScenario;

  factory SmartTileCoverageScenario.fromJson(Map<String, dynamic> json) =>
      _$SmartTileCoverageScenarioFromJson(json);
}

@freezed
abstract class SmartTileCoverageProfile with _$SmartTileCoverageProfile {
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileCoverageProfile({
    required SmartTileCoverageMode mode,
    @Default(<SmartTileCoverageScenario>[])
    List<SmartTileCoverageScenario> requiredScenarios,
    @Default(false) bool allowFallback,
  }) = _SmartTileCoverageProfile;

  factory SmartTileCoverageProfile.fromJson(Map<String, dynamic> json) =>
      _$SmartTileCoverageProfileFromJson(json);
}

@freezed
abstract class SmartTileTransformPolicy with _$SmartTileTransformPolicy {
  const factory SmartTileTransformPolicy({
    @Default(false) bool allowHFlip,
    @Default(false) bool allowVFlip,
    @Default(false) bool allowQuarterTurns,
    @Default(true) bool preferUntransformed,
  }) = _SmartTileTransformPolicy;

  factory SmartTileTransformPolicy.fromJson(Map<String, dynamic> json) =>
      _$SmartTileTransformPolicyFromJson(json);
}

@freezed
abstract class SmartTileSpriteTransform with _$SmartTileSpriteTransform {
  @Assert(
    'quarterTurns >= 0 && quarterTurns <= 3',
    'quarterTurns must be between 0 and 3',
  )
  const factory SmartTileSpriteTransform({
    @Default(0) int quarterTurns,
    @Default(false) bool flipX,
  }) = _SmartTileSpriteTransform;

  factory SmartTileSpriteTransform.fromJson(Map<String, dynamic> json) =>
      _smartTileSpriteTransformFromJson(json);
}

SmartTileSpriteTransform _smartTileSpriteTransformFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>['quarterTurns']);
  return _$SmartTileSpriteTransformFromJson(json);
}

@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
sealed class SmartTileVisualSource with _$SmartTileVisualSource {
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileVisualSource.frame({
    required SmartTileFrameRef frame,
  }) = SmartTileFrameSource;

  const factory SmartTileVisualSource.animation({
    required String animationId,
  }) = SmartTileAnimationSource;

  factory SmartTileVisualSource.fromJson(Map<String, dynamic> json) =>
      _$SmartTileVisualSourceFromJson(json);
}

@freezed
abstract class SmartTileVisualPart with _$SmartTileVisualPart {
  @Assert('footprintWidth > 0', 'footprintWidth must be positive')
  @Assert('footprintHeight > 0', 'footprintHeight must be positive')
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileVisualPart({
    required SmartTileVisualSource source,
    @Default(SmartTileSpriteTransform()) SmartTileSpriteTransform transform,
    @Default(SmartTileRenderChannel.ground) SmartTileRenderChannel channel,
    @Default(SmartTileFrameSampling.fullFrame)
    SmartTileFrameSampling frameSampling,
    @Default(SmartTileOffsetUnit.pixel) SmartTileOffsetUnit offsetUnit,
    @Default(0) int offsetX,
    @Default(0) int offsetY,
    @Default(1) int footprintWidth,
    @Default(1) int footprintHeight,
    @Default(0) int anchorX,
    @Default(0) int anchorY,
    @Default(0) int drawOrder,
  }) = _SmartTileVisualPart;

  factory SmartTileVisualPart.fromJson(Map<String, dynamic> json) =>
      _smartTileVisualPartFromJson(json);
}

SmartTileVisualPart _smartTileVisualPartFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>[
    'offsetX',
    'offsetY',
    'footprintWidth',
    'footprintHeight',
    'anchorX',
    'anchorY',
    'drawOrder',
  ]);
  return _$SmartTileVisualPartFromJson(json);
}

@freezed
abstract class SmartTilePatternCell with _$SmartTilePatternCell {
  @Assert('x >= 0', 'x must not be negative')
  @Assert('y >= 0', 'y must not be negative')
  @JsonSerializable(explicitToJson: true)
  const factory SmartTilePatternCell({
    required int x,
    required int y,
    @Default(<SmartTileVisualPart>[]) List<SmartTileVisualPart> parts,
    @Default(false) bool eraseMaterial,
    @Default(SmartTilePatternCollision.inherit)
    SmartTilePatternCollision collision,
  }) = _SmartTilePatternCell;

  factory SmartTilePatternCell.fromJson(Map<String, dynamic> json) =>
      _smartTilePatternCellFromJson(json);
}

SmartTilePatternCell _smartTilePatternCellFromJson(Map<String, dynamic> json) {
  _requireStrictJsonIntegers(json, const <String>['x', 'y']);
  return _$SmartTilePatternCellFromJson(json);
}

@freezed
abstract class ProjectSmartTilePattern with _$ProjectSmartTilePattern {
  @Assert('id != ""', 'id must not be blank')
  @Assert('name != ""', 'name must not be blank')
  @Assert('width > 0 && width <= 64', 'width must be between 1 and 64')
  @Assert('height > 0 && height <= 64', 'height must be between 1 and 64')
  @Assert('anchorX >= 0 && anchorX < width', 'anchorX must be in bounds')
  @Assert('anchorY >= 0 && anchorY < height', 'anchorY must be in bounds')
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSmartTilePattern({
    required String id,
    required String name,
    @Default('') String categoryId,
    required SmartTileUsage usage,
    required int width,
    required int height,
    @Default(0) int anchorX,
    @Default(0) int anchorY,
    @Default(SmartTilePatternRepeatMode.tiled)
    SmartTilePatternRepeatMode repeatMode,
    @Default(<SmartTilePatternCell>[]) List<SmartTilePatternCell> cells,
    @Default(0) int drawOrder,
    @Default(<String>[]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectSmartTilePattern;

  factory ProjectSmartTilePattern.fromJson(Map<String, dynamic> json) =>
      _projectSmartTilePatternFromJson(json);
}

ProjectSmartTilePattern _projectSmartTilePatternFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>[
    'width',
    'height',
    'anchorX',
    'anchorY',
    'drawOrder',
    'sortOrder',
  ]);
  return _$ProjectSmartTilePatternFromJson(json);
}

@freezed
abstract class SmartTilePatternStroke with _$SmartTilePatternStroke {
  @Assert('id != ""', 'id must not be blank')
  @Assert('patternId != ""', 'patternId must not be blank')
  @JsonSerializable(explicitToJson: true)
  const factory SmartTilePatternStroke({
    required String id,
    required String patternId,
    required List<GridPos> cells,
    @Default(0) int phaseX,
    @Default(0) int phaseY,
  }) = _SmartTilePatternStroke;

  factory SmartTilePatternStroke.fromJson(Map<String, dynamic> json) =>
      _smartTilePatternStrokeFromJson(json);
}

SmartTilePatternStroke _smartTilePatternStrokeFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>['phaseX', 'phaseY']);
  return _$SmartTilePatternStrokeFromJson(json);
}

@freezed
abstract class SmartTileCandidate with _$SmartTileCandidate {
  @Assert('id != ""', 'id must not be blank')
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileCandidate({
    required String id,
    @Default(1) int weight,
    @Default(<SmartTileVisualPart>[]) List<SmartTileVisualPart> parts,
  }) = _SmartTileCandidate;

  factory SmartTileCandidate.fromJson(Map<String, dynamic> json) =>
      _smartTileCandidateFromJson(json);
}

SmartTileCandidate _smartTileCandidateFromJson(Map<String, dynamic> json) {
  _requireStrictJsonIntegers(json, const <String>['weight']);
  return _$SmartTileCandidateFromJson(json);
}

@freezed
abstract class SmartTileRule with _$SmartTileRule {
  @Assert('id != ""', 'id must not be blank')
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileRule({
    required String id,
    required SmartTileSlotMatch centerMatch,
    @Default(SmartTileSignature()) SmartTileSignature signature,
    @Default(<SmartTileCandidate>[]) List<SmartTileCandidate> candidates,
  }) = _SmartTileRule;

  factory SmartTileRule.fromJson(Map<String, dynamic> json) =>
      _$SmartTileRuleFromJson(json);
}

@freezed
abstract class ProjectSmartTileCategory with _$ProjectSmartTileCategory {
  @Assert('id != ""', 'id must not be blank')
  @Assert('name != ""', 'name must not be blank')
  const factory ProjectSmartTileCategory({
    required String id,
    required String name,
    @Default(0) int sortOrder,
  }) = _ProjectSmartTileCategory;

  factory ProjectSmartTileCategory.fromJson(Map<String, dynamic> json) =>
      _projectSmartTileCategoryFromJson(json);
}

ProjectSmartTileCategory _projectSmartTileCategoryFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>['sortOrder']);
  return _$ProjectSmartTileCategoryFromJson(json);
}

@freezed
abstract class ProjectSmartTileAtlas with _$ProjectSmartTileAtlas {
  @Assert('id != ""', 'id must not be blank')
  @Assert('name != ""', 'name must not be blank')
  @Assert('tilesetId != ""', 'tilesetId must not be blank')
  @Assert('cellWidth > 0', 'cellWidth must be positive')
  @Assert('cellHeight > 0', 'cellHeight must be positive')
  @Assert('originX >= 0', 'originX must not be negative')
  @Assert('originY >= 0', 'originY must not be negative')
  @Assert('marginX >= 0', 'marginX must not be negative')
  @Assert('marginY >= 0', 'marginY must not be negative')
  @Assert('spacingX >= 0', 'spacingX must not be negative')
  @Assert('spacingY >= 0', 'spacingY must not be negative')
  @Assert('columns > 0', 'columns must be positive')
  @Assert('rows > 0', 'rows must be positive')
  const factory ProjectSmartTileAtlas({
    required String id,
    required String name,
    required String tilesetId,
    @Default(32) int cellWidth,
    @Default(32) int cellHeight,
    @Default(0) int originX,
    @Default(0) int originY,
    @Default(0) int marginX,
    @Default(0) int marginY,
    @Default(0) int spacingX,
    @Default(0) int spacingY,
    required int columns,
    required int rows,
    @Default(0) int pixelOffsetX,
    @Default(0) int pixelOffsetY,
  }) = _ProjectSmartTileAtlas;

  const ProjectSmartTileAtlas._();

  factory ProjectSmartTileAtlas.fromJson(Map<String, dynamic> json) =>
      _projectSmartTileAtlasFromJson(json);

  SmartTileSourceRect sourceRectFor({
    required int column,
    required int row,
    int columnSpan = 1,
    int rowSpan = 1,
  }) {
    if (column < 0 ||
        row < 0 ||
        columnSpan <= 0 ||
        rowSpan <= 0 ||
        column + columnSpan > columns ||
        row + rowSpan > rows) {
      throw RangeError('Smart Tile frame is outside atlas "$id"');
    }
    return SmartTileSourceRect(
      x: originX + marginX + column * (cellWidth + spacingX),
      y: originY + marginY + row * (cellHeight + spacingY),
      width: columnSpan * cellWidth + (columnSpan - 1) * spacingX,
      height: rowSpan * cellHeight + (rowSpan - 1) * spacingY,
    );
  }
}

ProjectSmartTileAtlas _projectSmartTileAtlasFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>[
    'cellWidth',
    'cellHeight',
    'originX',
    'originY',
    'marginX',
    'marginY',
    'spacingX',
    'spacingY',
    'columns',
    'rows',
    'pixelOffsetX',
    'pixelOffsetY',
  ]);
  return _$ProjectSmartTileAtlasFromJson(json);
}

@freezed
abstract class ProjectSmartTileMaterial with _$ProjectSmartTileMaterial {
  @Assert('id != ""', 'id must not be blank')
  @Assert('name != ""', 'name must not be blank')
  @Assert(
    'connectionGroupId != ""',
    'connectionGroupId must not be blank',
  )
  const factory ProjectSmartTileMaterial({
    required String id,
    required String name,
    required String connectionGroupId,
    @Default('') String categoryId,
    TerrainType? terrainType,
    PathSurfaceKind? pathSurfaceKind,
    @Default(false) bool isEmpty,
    @Default(0) int sortOrder,
    int? editorColorArgb,
  }) = _ProjectSmartTileMaterial;

  factory ProjectSmartTileMaterial.fromJson(Map<String, dynamic> json) =>
      _projectSmartTileMaterialFromJson(json);
}

ProjectSmartTileMaterial _projectSmartTileMaterialFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(
    json,
    const <String>['sortOrder', 'editorColorArgb'],
    nullableFields: const <String>{'editorColorArgb'},
  );
  return _$ProjectSmartTileMaterialFromJson(json);
}

@freezed
abstract class ProjectSmartTileAnimationFrame with _$ProjectSmartTileAnimationFrame {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSmartTileAnimationFrame({
    required SmartTileFrameRef frame,
    required int durationMs,
  }) = _ProjectSmartTileAnimationFrame;

  factory ProjectSmartTileAnimationFrame.fromJson(
    Map<String, dynamic> json,
  ) =>
      _projectSmartTileAnimationFrameFromJson(json);
}

ProjectSmartTileAnimationFrame _projectSmartTileAnimationFrameFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>['durationMs']);
  return _$ProjectSmartTileAnimationFrameFromJson(json);
}

@freezed
abstract class ProjectSmartTileAnimation with _$ProjectSmartTileAnimation {
  @Assert('id != ""', 'id must not be blank')
  @Assert('name != ""', 'name must not be blank')
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSmartTileAnimation({
    required String id,
    required String name,
    required List<ProjectSmartTileAnimationFrame> frames,
    @Default(SmartTileAnimationSync.global) SmartTileAnimationSync sync,
    @Default(SmartTileAnimationLoop.repeat) SmartTileAnimationLoop loop,
  }) = _ProjectSmartTileAnimation;

  factory ProjectSmartTileAnimation.fromJson(Map<String, dynamic> json) =>
      _$ProjectSmartTileAnimationFromJson(json);
}

@freezed
abstract class ProjectSmartTilePreset with _$ProjectSmartTilePreset {
  @Assert('id != ""', 'id must not be blank')
  @Assert('name != ""', 'name must not be blank')
  @Assert(
    'defaultMaterialId != ""',
    'defaultMaterialId must not be blank',
  )
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSmartTilePreset({
    required String id,
    required String name,
    @Default('') String categoryId,
    required SmartTileUsage usage,
    required SmartTileTopology topology,
    @Default(SmartTileTemplateHint.free) SmartTileTemplateHint templateHint,
    @Default(SmartTileBoundaryPolicy.empty)
    SmartTileBoundaryPolicy boundaryPolicy,
    @Default(SmartTilePresetStatus.draft) SmartTilePresetStatus status,
    required SmartTileCoveragePolicy coveragePolicy,
    required SmartTileCoverageProfile coverageProfile,
    required SmartTileTransformPolicy transformPolicy,
    required String defaultMaterialId,
    required List<String> allowedMaterialIds,
    @Default(<SmartTileRule>[]) List<SmartTileRule> rules,
    @Default(<String>[]) List<String> tags,
    @Default(0) int sortOrder,
    @Default(0) int seedSalt,
    String? fallbackRuleId,
  }) = _ProjectSmartTilePreset;

  factory ProjectSmartTilePreset.fromJson(Map<String, dynamic> json) =>
      _projectSmartTilePresetFromJson(json);
}

ProjectSmartTilePreset _projectSmartTilePresetFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>['sortOrder', 'seedSalt']);
  return _$ProjectSmartTilePresetFromJson(json);
}

/// Durable, isolated work-in-progress owned by Smart Tiles Studio.
///
/// Draft resources remain private until the publication compiler projects
/// them into the canonical catalog. Runtime resolution never reads this type.
@freezed
abstract class ProjectSmartTileAuthoringDraft with _$ProjectSmartTileAuthoringDraft {
  @Assert('id != ""', 'id must not be blank')
  @Assert('targetPresetId != ""', 'targetPresetId must not be blank')
  @Assert('name != ""', 'name must not be blank')
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSmartTileAuthoringDraft({
    required String id,
    required String targetPresetId,
    String? sourcePresetId,
    required String name,
    @Default('') String categoryId,
    required SmartTileUsage usage,
    required SmartTileAuthoringStage lastStage,
    String? guideId,
    @Default(<String>[]) List<String> sourceTilesetIds,
    @Default(<ProjectSmartTileAtlas>[]) List<ProjectSmartTileAtlas> atlases,
    String? primaryAtlasId,
    @Default(<ProjectSmartTileMaterial>[])
    List<ProjectSmartTileMaterial> materials,
    @Default(<ProjectSmartTileAnimation>[])
    List<ProjectSmartTileAnimation> animations,
    String? defaultMaterialId,
    @Default(<String>[]) List<String> allowedMaterialIds,
    @Default(SmartTileTopology.uniform) SmartTileTopology topology,
    @Default(SmartTileTemplateHint.simple) SmartTileTemplateHint templateHint,
    @Default(SmartTileBoundaryPolicy.empty)
    SmartTileBoundaryPolicy boundaryPolicy,
    @Default(SmartTileCoveragePolicy.complete)
    SmartTileCoveragePolicy coveragePolicy,
    @Default(SmartTileCoverageProfile(mode: SmartTileCoverageMode.template))
    SmartTileCoverageProfile coverageProfile,
    @Default(SmartTileTransformPolicy())
    SmartTileTransformPolicy transformPolicy,
    @Default(<SmartTileRule>[]) List<SmartTileRule> rules,
    String? fallbackRuleId,
    @Default(<String>[]) List<String> tags,
    @Default(0) int sortOrder,
    @Default(0) int seedSalt,
  }) = _ProjectSmartTileAuthoringDraft;

  factory ProjectSmartTileAuthoringDraft.fromJson(Map<String, dynamic> json) =>
      _projectSmartTileAuthoringDraftFromJson(json);
}

ProjectSmartTileAuthoringDraft _projectSmartTileAuthoringDraftFromJson(
  Map<String, dynamic> json,
) {
  _requireStrictJsonIntegers(json, const <String>['sortOrder', 'seedSalt']);
  return _$ProjectSmartTileAuthoringDraftFromJson(json);
}

@immutable
final class ProjectSmartTileCatalog {
  static const int currentFormatVersion = 4;

  const ProjectSmartTileCatalog.empty()
      : formatVersion = currentFormatVersion,
        _categories = const <ProjectSmartTileCategory>[],
        _atlases = const <ProjectSmartTileAtlas>[],
        _materials = const <ProjectSmartTileMaterial>[],
        _animations = const <ProjectSmartTileAnimation>[],
        _presets = const <ProjectSmartTilePreset>[],
        _patterns = const <ProjectSmartTilePattern>[],
        _drafts = const <ProjectSmartTileAuthoringDraft>[];

  factory ProjectSmartTileCatalog({
    int formatVersion = currentFormatVersion,
    List<ProjectSmartTileCategory> categories =
        const <ProjectSmartTileCategory>[],
    List<ProjectSmartTileAtlas> atlases = const <ProjectSmartTileAtlas>[],
    List<ProjectSmartTileMaterial> materials =
        const <ProjectSmartTileMaterial>[],
    List<ProjectSmartTileAnimation> animations =
        const <ProjectSmartTileAnimation>[],
    List<ProjectSmartTilePreset> presets = const <ProjectSmartTilePreset>[],
    List<ProjectSmartTilePattern> patterns = const <ProjectSmartTilePattern>[],
    List<ProjectSmartTileAuthoringDraft> drafts =
        const <ProjectSmartTileAuthoringDraft>[],
  }) {
    if (formatVersion != currentFormatVersion) {
      throw ArgumentError.value(
        formatVersion,
        'formatVersion',
        'must equal current Smart Tile catalog format '
            '$currentFormatVersion',
      );
    }
    return ProjectSmartTileCatalog._(
      formatVersion: formatVersion,
      categories: categories,
      atlases: atlases,
      materials: materials,
      animations: animations,
      presets: presets,
      patterns: patterns,
      drafts: drafts,
    );
  }

  ProjectSmartTileCatalog._({
    required this.formatVersion,
    required List<ProjectSmartTileCategory> categories,
    required List<ProjectSmartTileAtlas> atlases,
    required List<ProjectSmartTileMaterial> materials,
    required List<ProjectSmartTileAnimation> animations,
    required List<ProjectSmartTilePreset> presets,
    required List<ProjectSmartTilePattern> patterns,
    required List<ProjectSmartTileAuthoringDraft> drafts,
  })  : _categories = List<ProjectSmartTileCategory>.unmodifiable(categories),
        _atlases = List<ProjectSmartTileAtlas>.unmodifiable(atlases),
        _materials = List<ProjectSmartTileMaterial>.unmodifiable(materials),
        _animations = List<ProjectSmartTileAnimation>.unmodifiable(animations),
        _presets = List<ProjectSmartTilePreset>.unmodifiable(presets),
        _patterns = List<ProjectSmartTilePattern>.unmodifiable(patterns),
        _drafts = List<ProjectSmartTileAuthoringDraft>.unmodifiable(drafts);

  factory ProjectSmartTileCatalog.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['formatVersion'];
    final hasVersion = json.containsKey('formatVersion');
    if (hasVersion && (rawVersion is! int || rawVersion <= 0)) {
      throw FormatException(
        r'$.smartTileCatalog.formatVersion: '
        'smart_tile_catalog_version_invalid ($rawVersion)',
      );
    }
    final version = hasVersion ? rawVersion! as int : 1;
    if (version > currentFormatVersion) {
      throw FormatException(
        r'$.smartTileCatalog.formatVersion: '
        'smart_tile_catalog_version_unsupported ($version)',
      );
    }
    if (version == 1) {
      if (_catalogJsonIsStrictlyEmpty(json)) {
        return const ProjectSmartTileCatalog.empty();
      }
      throw FormatException(
        r'$.smartTileCatalog.formatVersion: '
        'smart_tile_catalog_v1_unsupported ($version)',
      );
    }
    return ProjectSmartTileCatalog(
      categories: _decodeList(
        json['categories'],
        ProjectSmartTileCategory.fromJson,
      ),
      atlases: _decodeList(json['atlases'], ProjectSmartTileAtlas.fromJson),
      materials:
          _decodeList(json['materials'], ProjectSmartTileMaterial.fromJson),
      animations:
          _decodeList(json['animations'], ProjectSmartTileAnimation.fromJson),
      presets: _decodeList(json['presets'], ProjectSmartTilePreset.fromJson),
      patterns: version >= 4
          ? _decodeList(json['patterns'], ProjectSmartTilePattern.fromJson)
          : const <ProjectSmartTilePattern>[],
      drafts: version >= 3
          ? _decodeList(
              json['drafts'],
              ProjectSmartTileAuthoringDraft.fromJson,
            )
          : const <ProjectSmartTileAuthoringDraft>[],
    );
  }

  final int formatVersion;
  final List<ProjectSmartTileCategory> _categories;
  final List<ProjectSmartTileAtlas> _atlases;
  final List<ProjectSmartTileMaterial> _materials;
  final List<ProjectSmartTileAnimation> _animations;
  final List<ProjectSmartTilePreset> _presets;
  final List<ProjectSmartTilePattern> _patterns;
  final List<ProjectSmartTileAuthoringDraft> _drafts;

  List<ProjectSmartTileCategory> get categories => _categories;
  List<ProjectSmartTileAtlas> get atlases => _atlases;
  List<ProjectSmartTileMaterial> get materials => _materials;
  List<ProjectSmartTileAnimation> get animations => _animations;
  List<ProjectSmartTilePreset> get presets => _presets;
  List<ProjectSmartTilePattern> get patterns => _patterns;
  List<ProjectSmartTileAuthoringDraft> get drafts => _drafts;

  bool get isEmpty =>
      categories.isEmpty &&
      atlases.isEmpty &&
      materials.isEmpty &&
      animations.isEmpty &&
      presets.isEmpty &&
      patterns.isEmpty &&
      drafts.isEmpty;

  bool get isNotEmpty => !isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'formatVersion': formatVersion,
        'categories': categories.map((item) => item.toJson()).toList(),
        'atlases': atlases.map((item) => item.toJson()).toList(),
        'materials': materials.map((item) => item.toJson()).toList(),
        'animations': animations.map((item) => item.toJson()).toList(),
        'presets': presets.map((item) => item.toJson()).toList(),
        'patterns': patterns.map((item) => item.toJson()).toList(),
        'drafts': drafts.map((item) => item.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSmartTileCatalog &&
          other.formatVersion == formatVersion &&
          _listsEqual(other.categories, categories) &&
          _listsEqual(other.atlases, atlases) &&
          _listsEqual(other.materials, materials) &&
          _listsEqual(other.animations, animations) &&
          _listsEqual(other.presets, presets) &&
          _listsEqual(other.patterns, patterns) &&
          _listsEqual(other.drafts, drafts);

  @override
  int get hashCode => Object.hash(
        formatVersion,
        Object.hashAll(categories),
        Object.hashAll(atlases),
        Object.hashAll(materials),
        Object.hashAll(animations),
        Object.hashAll(presets),
        Object.hashAll(patterns),
        Object.hashAll(drafts),
      );
}

bool _catalogJsonIsStrictlyEmpty(Map<String, dynamic> json) {
  const supportedKeys = <String>{
    'formatVersion',
    'categories',
    'atlases',
    'materials',
    'animations',
    'presets',
    'patterns',
    'drafts',
  };
  // Unknown v1 keys may carry semantics from another catalog dialect. Treat
  // them as data instead of silently erasing them during empty normalization.
  if (json.keys.any((key) => !supportedKeys.contains(key))) {
    return false;
  }
  for (final key in supportedKeys.where((key) => key != 'formatVersion')) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is! List || value.isNotEmpty) {
      return false;
    }
  }
  return true;
}

List<T> _decodeList<T>(
  Object? json,
  T Function(Map<String, dynamic>) decode,
) {
  if (json == null) {
    return <T>[];
  }
  if (json is! List) {
    throw const FormatException('Smart Tile catalog field must be a list');
  }
  return json
      .map(
        (item) => decode(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList(growable: false);
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
