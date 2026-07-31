// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

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
  @JsonValue('legacy_20')
  legacy20,
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

enum SmartTilePresetStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
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
/// drawn for the resolved cell. The other modes exist so legacy terrain
/// textures can migrate without being squashed into one map cell.
enum SmartTileFrameSampling {
  @JsonValue('full_frame')
  fullFrame,
  @JsonValue('tessellated')
  tessellated,
  @JsonValue('stable_random')
  stableRandom,
}

@freezed
class SmartTileSourceRect with _$SmartTileSourceRect {
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
      _$SmartTileSourceRectFromJson(json);
}

@freezed
class SmartTileFrameRef with _$SmartTileFrameRef {
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
      _$SmartTileFrameRefFromJson(json);
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
    final materialId = json['materialId'] as String?;
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
class SmartTileSignature with _$SmartTileSignature {
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
class SmartTileVisualPart with _$SmartTileVisualPart {
  @Assert('footprintWidth > 0', 'footprintWidth must be positive')
  @Assert('footprintHeight > 0', 'footprintHeight must be positive')
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileVisualPart({
    required SmartTileVisualSource source,
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
      _$SmartTileVisualPartFromJson(json);
}

@freezed
class SmartTileCandidate with _$SmartTileCandidate {
  @Assert('id != ""', 'id must not be blank')
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileCandidate({
    required String id,
    @Default(1) int weight,
    @Default(<SmartTileVisualPart>[]) List<SmartTileVisualPart> parts,
  }) = _SmartTileCandidate;

  factory SmartTileCandidate.fromJson(Map<String, dynamic> json) =>
      _$SmartTileCandidateFromJson(json);
}

@freezed
class SmartTileRule with _$SmartTileRule {
  @Assert('id != ""', 'id must not be blank')
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileRule({
    required String id,
    @Default(SmartTileSignature()) SmartTileSignature signature,
    @Default(<SmartTileCandidate>[]) List<SmartTileCandidate> candidates,
  }) = _SmartTileRule;

  factory SmartTileRule.fromJson(Map<String, dynamic> json) =>
      _$SmartTileRuleFromJson(json);
}

@freezed
class ProjectSmartTileCategory with _$ProjectSmartTileCategory {
  @Assert('id != ""', 'id must not be blank')
  @Assert('name != ""', 'name must not be blank')
  const factory ProjectSmartTileCategory({
    required String id,
    required String name,
    @Default(0) int sortOrder,
  }) = _ProjectSmartTileCategory;

  factory ProjectSmartTileCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectSmartTileCategoryFromJson(json);
}

@freezed
class ProjectSmartTileAtlas with _$ProjectSmartTileAtlas {
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
      _$ProjectSmartTileAtlasFromJson(json);

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

@freezed
class ProjectSmartTileMaterial with _$ProjectSmartTileMaterial {
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
    @Default(false) bool isEmpty,
    @Default(0) int sortOrder,
    int? editorColorArgb,
  }) = _ProjectSmartTileMaterial;

  factory ProjectSmartTileMaterial.fromJson(Map<String, dynamic> json) =>
      _$ProjectSmartTileMaterialFromJson(json);
}

@freezed
class ProjectSmartTileAnimationFrame with _$ProjectSmartTileAnimationFrame {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSmartTileAnimationFrame({
    required SmartTileFrameRef frame,
    required int durationMs,
  }) = _ProjectSmartTileAnimationFrame;

  factory ProjectSmartTileAnimationFrame.fromJson(Map<String, dynamic> json) =>
      _$ProjectSmartTileAnimationFrameFromJson(json);
}

@freezed
class ProjectSmartTileAnimation with _$ProjectSmartTileAnimation {
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
class ProjectSmartTilePreset with _$ProjectSmartTilePreset {
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
    required String defaultMaterialId,
    required List<String> allowedMaterialIds,
    @Default(<SmartTileRule>[]) List<SmartTileRule> rules,
    @Default(<String>[]) List<String> tags,
    @Default(0) int sortOrder,
    @Default(0) int seedSalt,
    String? fallbackRuleId,
  }) = _ProjectSmartTilePreset;

  factory ProjectSmartTilePreset.fromJson(Map<String, dynamic> json) =>
      _$ProjectSmartTilePresetFromJson(json);
}

@immutable
final class ProjectSmartTileCatalog {
  static const int currentFormatVersion = 1;

  const ProjectSmartTileCatalog.empty()
      : formatVersion = currentFormatVersion,
        _categories = const <ProjectSmartTileCategory>[],
        _atlases = const <ProjectSmartTileAtlas>[],
        _materials = const <ProjectSmartTileMaterial>[],
        _animations = const <ProjectSmartTileAnimation>[],
        _presets = const <ProjectSmartTilePreset>[];

  ProjectSmartTileCatalog({
    this.formatVersion = currentFormatVersion,
    List<ProjectSmartTileCategory> categories =
        const <ProjectSmartTileCategory>[],
    List<ProjectSmartTileAtlas> atlases = const <ProjectSmartTileAtlas>[],
    List<ProjectSmartTileMaterial> materials =
        const <ProjectSmartTileMaterial>[],
    List<ProjectSmartTileAnimation> animations =
        const <ProjectSmartTileAnimation>[],
    List<ProjectSmartTilePreset> presets = const <ProjectSmartTilePreset>[],
  })  : assert(formatVersion > 0, 'formatVersion must be positive'),
        _categories = List<ProjectSmartTileCategory>.unmodifiable(categories),
        _atlases = List<ProjectSmartTileAtlas>.unmodifiable(atlases),
        _materials = List<ProjectSmartTileMaterial>.unmodifiable(materials),
        _animations = List<ProjectSmartTileAnimation>.unmodifiable(animations),
        _presets = List<ProjectSmartTilePreset>.unmodifiable(presets);

  factory ProjectSmartTileCatalog.fromJson(Map<String, dynamic> json) {
    return ProjectSmartTileCatalog(
      formatVersion:
          (json['formatVersion'] as num?)?.toInt() ?? currentFormatVersion,
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
    );
  }

  final int formatVersion;
  final List<ProjectSmartTileCategory> _categories;
  final List<ProjectSmartTileAtlas> _atlases;
  final List<ProjectSmartTileMaterial> _materials;
  final List<ProjectSmartTileAnimation> _animations;
  final List<ProjectSmartTilePreset> _presets;

  List<ProjectSmartTileCategory> get categories => _categories;
  List<ProjectSmartTileAtlas> get atlases => _atlases;
  List<ProjectSmartTileMaterial> get materials => _materials;
  List<ProjectSmartTileAnimation> get animations => _animations;
  List<ProjectSmartTilePreset> get presets => _presets;

  bool get isEmpty =>
      categories.isEmpty &&
      atlases.isEmpty &&
      materials.isEmpty &&
      animations.isEmpty &&
      presets.isEmpty;

  bool get isNotEmpty => !isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'formatVersion': formatVersion,
        'categories': categories.map((item) => item.toJson()).toList(),
        'atlases': atlases.map((item) => item.toJson()).toList(),
        'materials': materials.map((item) => item.toJson()).toList(),
        'animations': animations.map((item) => item.toJson()).toList(),
        'presets': presets.map((item) => item.toJson()).toList(),
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
          _listsEqual(other.presets, presets);

  @override
  int get hashCode => Object.hash(
        formatVersion,
        Object.hashAll(categories),
        Object.hashAll(atlases),
        Object.hashAll(materials),
        Object.hashAll(animations),
        Object.hashAll(presets),
      );
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
