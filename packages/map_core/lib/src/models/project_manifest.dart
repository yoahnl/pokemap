import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'project_manifest.freezed.dart';
part 'project_manifest.g.dart';

@freezed
class ProjectManifest with _$ProjectManifest {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectManifest({
    required String name,
    @Default(ProjectVersion.v1) ProjectVersion version,
    required List<ProjectMapEntry> maps,
    @Default([]) List<ProjectMapGroup> groups,
    required List<ProjectTilesetEntry> tilesets,
    @Default([]) List<ProjectElementCategory> elementCategories,
    @Default([]) List<ProjectElementEntry> elements,
    @Default([]) List<ProjectTerrainPresetCategory> terrainPresetCategories,
    @Default([]) List<ProjectTerrainPreset> terrainPresets,
    @Default([]) List<ProjectPathPreset> pathPresets,
    @Default(ProjectSettings()) ProjectSettings settings,
    @Default({}) Map<String, dynamic> globalProperties,
  }) = _ProjectManifest;

  factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
      _$ProjectManifestFromJson(json);
}

@freezed
class ProjectSettings with _$ProjectSettings {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSettings({
    @Default(16) int tileWidth,
    @Default(16) int tileHeight,
    @Default(2.0) double displayScale,
    @Default(20) int defaultMapWidth,
    @Default(15) int defaultMapHeight,
  }) = _ProjectSettings;

  factory ProjectSettings.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsFromJson(json);
}

@freezed
class ProjectMapGroup with _$ProjectMapGroup {
  const factory ProjectMapGroup({
    required String id,
    required String name,
    required MapGroupType type,
    String? parentGroupId,
    @Default(0) int sortOrder,
    @Default([]) List<String> tags,
    @Default({}) Map<String, dynamic> properties,
  }) = _ProjectMapGroup;

  factory ProjectMapGroup.fromJson(Map<String, dynamic> json) =>
      _$ProjectMapGroupFromJson(json);
}

@freezed
class ProjectMapEntry with _$ProjectMapEntry {
  const factory ProjectMapEntry({
    required String id,
    required String name,
    required String relativePath,
    String? groupId,
    @Default(MapRole.exterior) MapRole role,
    @Default(0) int sortOrder,
  }) = _ProjectMapEntry;

  factory ProjectMapEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectMapEntryFromJson(json);
}

@freezed
class ProjectTilesetEntry with _$ProjectTilesetEntry {
  const factory ProjectTilesetEntry({
    required String id,
    required String name,
    required String relativePath,
    @Default(TilesetScope.global) TilesetScope scope,
    String? groupId,
    @Default(0) int sortOrder,
    @Default(false) bool isWorldTileset,
    @Default([]) List<TilesetElementGroup> elementGroups,
    @Default([]) List<TilesetPaletteEntry> paletteEntries,
  }) = _ProjectTilesetEntry;

  factory ProjectTilesetEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetEntryFromJson(json);
}

@freezed
class TilesetPaletteEntry with _$TilesetPaletteEntry {
  const factory TilesetPaletteEntry({
    required String id,
    @Default('') String name,
    @Default(PaletteCategory.uncategorized) PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) = _TilesetPaletteEntry;

  factory TilesetPaletteEntry.fromJson(Map<String, dynamic> json) =>
      _$TilesetPaletteEntryFromJson(json);
}

@freezed
class TilesetSourceRect with _$TilesetSourceRect {
  const factory TilesetSourceRect({
    required int x,
    required int y,
    @Default(1) int width,
    @Default(1) int height,
  }) = _TilesetSourceRect;

  factory TilesetSourceRect.fromJson(Map<String, dynamic> json) =>
      _$TilesetSourceRectFromJson(json);
}

@freezed
class TilesetElementGroup with _$TilesetElementGroup {
  const factory TilesetElementGroup({
    required String id,
    required String name,
    String? parentGroupId,
    @Default(0) int sortOrder,
  }) = _TilesetElementGroup;

  factory TilesetElementGroup.fromJson(Map<String, dynamic> json) =>
      _$TilesetElementGroupFromJson(json);
}

@freezed
class ProjectElementCategory with _$ProjectElementCategory {
  const factory ProjectElementCategory({
    required String id,
    required String name,
    String? parentCategoryId,
    @Default(0) int sortOrder,
  }) = _ProjectElementCategory;

  factory ProjectElementCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectElementCategoryFromJson(json);
}

@freezed
class ProjectElementEntry with _$ProjectElementEntry {
  const factory ProjectElementEntry({
    required String id,
    required String name,
    required String tilesetId,
    required String categoryId,
    String? tilesetGroupId,
    required TilesetSourceRect source,
    String? groupId,
    String? recommendedLayerId,
    @Default([]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectElementEntry;

  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectElementEntryFromJson(json);
}

@freezed
class ProjectTerrainPreset with _$ProjectTerrainPreset {
  const factory ProjectTerrainPreset({
    required String id,
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    @Default('') String tilesetId,
    @Default([]) List<TerrainPresetVariant> variants,
    @Default(0) int sortOrder,
  }) = _ProjectTerrainPreset;

  factory ProjectTerrainPreset.fromJson(Map<String, dynamic> json) =>
      _$ProjectTerrainPresetFromJson(json);
}

@freezed
class TerrainPresetVariant with _$TerrainPresetVariant {
  const factory TerrainPresetVariant({
    required TilesetSourceRect source,
    @Default(1) int weight,
  }) = _TerrainPresetVariant;

  factory TerrainPresetVariant.fromJson(Map<String, dynamic> json) =>
      _$TerrainPresetVariantFromJson(json);
}

@freezed
class ProjectPathPreset with _$ProjectPathPreset {
  const factory ProjectPathPreset({
    required String id,
    required String name,
    @Default(PathSurfaceKind.path) PathSurfaceKind surfaceKind,
    String? categoryId,
    @Default('') String tilesetId,
    @Default([]) List<PathPresetVariantMapping> variants,
    @Default(0) int sortOrder,
  }) = _ProjectPathPreset;

  factory ProjectPathPreset.fromJson(Map<String, dynamic> json) =>
      _$ProjectPathPresetFromJson(json);
}

@freezed
class PathPresetVariantMapping with _$PathPresetVariantMapping {
  const factory PathPresetVariantMapping({
    required TerrainPathVariant variant,
    required TilesetSourceRect source,
  }) = _PathPresetVariantMapping;

  factory PathPresetVariantMapping.fromJson(Map<String, dynamic> json) =>
      _$PathPresetVariantMappingFromJson(json);
}

@freezed
class ProjectTerrainPresetCategory with _$ProjectTerrainPresetCategory {
  const factory ProjectTerrainPresetCategory({
    required String id,
    required String name,
    required TerrainPresetCategoryKind kind,
    String? parentCategoryId,
    @Default(0) int sortOrder,
  }) = _ProjectTerrainPresetCategory;

  factory ProjectTerrainPresetCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectTerrainPresetCategoryFromJson(json);
}
