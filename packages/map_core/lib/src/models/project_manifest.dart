// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'element_collision_profile.dart';
import 'environment.dart';
import 'enums.dart';
import 'project_trainer.dart';
import 'project_path_pattern_preset.dart';
import 'scenario_asset.dart';
import 'script_asset.dart';
import 'surface_catalog.dart';
import 'tileset_transparent_color.dart';
import 'visual_frame_json.dart';

import '../exceptions/map_exceptions.dart';
import '../operations/environment_preset_json_codec.dart';
import '../operations/project_path_pattern_preset_json_codec.dart';
import '../operations/project_surface_catalog_json_codec.dart';

part 'project_manifest.freezed.dart';
part 'project_manifest.g.dart';

/// JSON → [ProjectSurfaceCatalog] pour [ProjectManifest.surfaceCatalog] (Lot 49).
/// Clé absente ou `null` : catalogue vide. Non-map : [ValidationException].
ProjectSurfaceCatalog _projectSurfaceCatalogFromJson(Object? json) {
  if (json == null) {
    return ProjectSurfaceCatalog();
  }
  if (json is! Map) {
    throw const ValidationException('surfaceCatalog must be a JSON object');
  }
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(json),
  );
}

Map<String, Object?> _projectSurfaceCatalogToJson(
  ProjectSurfaceCatalog catalog,
) {
  return encodeProjectSurfaceCatalog(catalog);
}

Object? _readDefaultPlayerCharacterId(Map json, String _) {
  return json['defaultPlayerCharacterId'] ?? json['playerCharacterId'];
}

TilesetTransparentColor? _tilesetTransparentColorFromJson(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is String) {
    final value = json.trim();
    if (value.isEmpty) {
      return null;
    }
    return TilesetTransparentColor.fromHexRgb(value);
  }
  throw ArgumentError.value(
    json,
    'transparentColor',
    'Expected a hex RGB string',
  );
}

String? _tilesetTransparentColorToJson(TilesetTransparentColor? color) {
  return color?.toHexRgb();
}

const Map<String, String> _defaultPokemonCatalogFiles = <String, String>{
  'moves': 'data/pokemon/catalogs/moves.json',
  'abilities': 'data/pokemon/catalogs/abilities.json',
  'items': 'data/pokemon/catalogs/items.json',
  'types': 'data/pokemon/catalogs/types.json',
  'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
  'natures': 'data/pokemon/catalogs/natures.json',
  'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
  'habitats': 'data/pokemon/catalogs/habitats.json',
  'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
  'generations': 'data/pokemon/catalogs/generations.json',
  'version_groups': 'data/pokemon/catalogs/version_groups.json',
};

@freezed
class ProjectManifest with _$ProjectManifest {
  @JsonSerializable(explicitToJson: true)
  factory ProjectManifest({
    required String name,
    @Default(ProjectVersion.v1) ProjectVersion version,
    required List<ProjectMapEntry> maps,
    @Default([]) List<ProjectMapGroup> groups,
    @Default([]) List<ProjectTilesetFolder> tilesetFolders,
    required List<ProjectTilesetEntry> tilesets,
    @Default([]) List<ProjectElementCategory> elementCategories,
    @Default([]) List<ProjectElementEntry> elements,
    @Default([]) List<ProjectPresetCategory> terrainCategories,
    @Default([]) List<ProjectPresetCategory> pathCategories,
    @Default([]) List<ProjectTerrainPreset> terrainPresets,
    @Default([]) List<ProjectPathPreset> pathPresets,
    @Default([])
    @JsonKey(
      name: 'pathPatternPresets',
      fromJson: decodeProjectPathPatternPresets,
      toJson: encodeProjectPathPatternPresets,
    )
    List<ProjectPathPatternPreset> pathPatternPresets,
    @Default([])
    @JsonKey(
      name: 'environmentPresets',
      fromJson: decodeEnvironmentPresets,
      toJson: encodeEnvironmentPresets,
    )
    List<EnvironmentPreset> environmentPresets,
    @Default([]) List<ProjectEncounterTable> encounterTables,
    @Default([]) List<ProjectDialogueFolder> dialogueFolders,
    @Default([]) List<ProjectDialogueEntry> dialogues,
    @Default([]) List<ProjectScriptEntry> scripts,
    @Default([]) List<ScenarioAsset> scenarios,
    @Default([]) List<ProjectTrainerEntry> trainers,
    @Default([]) List<ProjectCharacterEntry> characters,
    @Default(ProjectSettings()) ProjectSettings settings,
    @Default(ProjectPokemonConfig()) ProjectPokemonConfig pokemon,
    @Default({}) Map<String, dynamic> globalProperties,
    @JsonKey(
      name: 'surfaceCatalog',
      fromJson: _projectSurfaceCatalogFromJson,
      toJson: _projectSurfaceCatalogToJson,
    )
    required ProjectSurfaceCatalog surfaceCatalog,
  }) = _ProjectManifest;

  factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
      _$ProjectManifestFromJson(json);
}

@freezed
class ProjectPokemonConfig with _$ProjectPokemonConfig {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectPokemonConfig({
    @Default(true) bool enabled,
    @Default('data/pokemon') String dataRoot,
    @Default('data/pokemon/species') String speciesDir,
    @Default('data/pokemon/learnsets') String learnsetsDir,
    @Default('data/pokemon/evolutions') String evolutionsDir,
    @Default('data/pokemon/media') String mediaDir,
    @Default(_defaultPokemonCatalogFiles) Map<String, String> catalogFiles,
  }) = _ProjectPokemonConfig;

  factory ProjectPokemonConfig.fromJson(Map<String, dynamic> json) =>
      _$ProjectPokemonConfigFromJson(json);
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
    @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId,
    )
    String? defaultPlayerCharacterId,

    /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
    ///
    /// Stockée dans `project.json` : penser au risque de fuite si le dépôt est public ;
    /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
    @JsonKey(name: 'mistralApiKey', includeIfNull: false) String? mistralApiKey,
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
class ProjectDialogueFolder with _$ProjectDialogueFolder {
  const factory ProjectDialogueFolder({
    required String id,
    required String name,
    String? parentFolderId,
    @Default(0) int sortOrder,
  }) = _ProjectDialogueFolder;

  factory ProjectDialogueFolder.fromJson(Map<String, dynamic> json) =>
      _$ProjectDialogueFolderFromJson(json);
}

@freezed
class ProjectDialogueEntry with _$ProjectDialogueEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectDialogueEntry({
    required String id,
    required String name,

    /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
    required String relativePath,
    @Default([]) List<String> tags,
    @Default('') String description,

    /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
    String? defaultStartNode,

    /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
    String? folderId,
    @Default(0) int sortOrder,
  }) = _ProjectDialogueEntry;

  factory ProjectDialogueEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectDialogueEntryFromJson(json);
}

@freezed
class ProjectTilesetFolder with _$ProjectTilesetFolder {
  const factory ProjectTilesetFolder({
    required String id,
    required String name,
    String? parentFolderId,
    @Default(0) int sortOrder,
  }) = _ProjectTilesetFolder;

  factory ProjectTilesetFolder.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetFolderFromJson(json);
}

@freezed
class ProjectTilesetEntry with _$ProjectTilesetEntry {
  const factory ProjectTilesetEntry({
    required String id,
    required String name,
    required String relativePath,
    @Default(TilesetScope.global) TilesetScope scope,
    String? groupId,

    /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
    String? folderId,
    @Default(0) int sortOrder,
    @Default(false) bool isWorldTileset,
    @JsonKey(
      fromJson: _tilesetTransparentColorFromJson,
      toJson: _tilesetTransparentColorToJson,
      includeIfNull: false,
    )
    TilesetTransparentColor? transparentColor,
    @Default([]) List<TilesetElementGroup> elementGroups,
    @Default([]) List<TilesetPaletteEntry> paletteEntries,
  }) = _ProjectTilesetEntry;

  factory ProjectTilesetEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetEntryFromJson(json);
}

@freezed
class TilesetPaletteEntry with _$TilesetPaletteEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TilesetPaletteEntry({
    required String id,
    @Default('') String name,
    @Default(PaletteCategory.uncategorized) PaletteCategory category,

    /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
    required List<TilesetVisualFrame> frames,
    String? recommendedLayerId,
  }) = _TilesetPaletteEntry;

  factory TilesetPaletteEntry.fromJson(Map<String, dynamic> json) =>
      _$TilesetPaletteEntryFromJson(jsonCoerceLegacySourceToFrames(json));
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

/// Une frame d'animation ou l'unique frame d'un visuel statique dans un tileset.
///
/// [tilesetId] vide = utiliser le tileset du contexte parent (élément, preset, entrée palette).
@freezed
class TilesetVisualFrame with _$TilesetVisualFrame {
  @JsonSerializable(explicitToJson: true)
  const factory TilesetVisualFrame({
    @Default('') String tilesetId,
    required TilesetSourceRect source,

    /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
    int? durationMs,
  }) = _TilesetVisualFrame;

  factory TilesetVisualFrame.fromJson(Map<String, dynamic> json) =>
      _$TilesetVisualFrameFromJson(json);
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
  @JsonSerializable(explicitToJson: true)
  const factory ProjectElementEntry({
    required String id,
    required String name,
    required String tilesetId,
    required String categoryId,
    String? tilesetGroupId,

    /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
    required List<TilesetVisualFrame> frames,
    @Default(ElementPresetKind.generic) ElementPresetKind presetKind,
    ElementCollisionProfile? collisionProfile,
    String? groupId,
    String? recommendedLayerId,
    @Default([]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectElementEntry;

  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectElementEntryFromJson(jsonCoerceLegacySourceToFrames(json));
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
  @JsonSerializable(explicitToJson: true)
  const factory TerrainPresetVariant({
    /// Au moins une frame ; rendu éditeur = première frame.
    required List<TilesetVisualFrame> frames,
    @Default(1) int weight,

    /// When [frames] primary source spans W×H tiles (>1), controls sub-tile
    /// choice per map cell (see [terrainPresetSubtileOffsetsForMapCell]).
    @Default(TerrainVariantMultiTileLayout.tessellated)
    TerrainVariantMultiTileLayout multiTileLayout,
  }) = _TerrainPresetVariant;

  factory TerrainPresetVariant.fromJson(Map<String, dynamic> json) =>
      _$TerrainPresetVariantFromJson(jsonCoerceLegacySourceToFrames(json));
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
  @JsonSerializable(explicitToJson: true)
  const factory PathPresetVariantMapping({
    required TerrainPathVariant variant,

    /// Au moins une frame ; rendu éditeur / autotile = première frame.
    required List<TilesetVisualFrame> frames,
  }) = _PathPresetVariantMapping;

  factory PathPresetVariantMapping.fromJson(Map<String, dynamic> json) =>
      _$PathPresetVariantMappingFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class PathAnimationTriggerRule with _$PathAnimationTriggerRule {
  @JsonSerializable(explicitToJson: true)
  const factory PathAnimationTriggerRule({
    @Default('') String id,
    @Default(true) bool enabled,
    @Default(PathAnimationTriggerType.onStep) PathAnimationTriggerType trigger,
    @Default(PathAnimationPlaybackMode.restartOnTrigger)
    PathAnimationPlaybackMode mode,
    @Default(PathAnimationActivationScope.wholeLayer)
    PathAnimationActivationScope scope,
  }) = _PathAnimationTriggerRule;

  factory PathAnimationTriggerRule.fromJson(Map<String, dynamic> json) =>
      _$PathAnimationTriggerRuleFromJson(json);
}

@freezed
class ProjectPresetCategory with _$ProjectPresetCategory {
  const factory ProjectPresetCategory({
    required String id,
    required String name,
    String? parentCategoryId,
    @Default(0) int sortOrder,
  }) = _ProjectPresetCategory;

  factory ProjectPresetCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectPresetCategoryFromJson(json);
}

// ---------------------------------------------------------------------------
// ProjectEncounterEntry / ProjectEncounterTable
// ---------------------------------------------------------------------------

/// Entrée pondérée dans une table de rencontres.
@freezed
class ProjectEncounterEntry with _$ProjectEncounterEntry {
  const factory ProjectEncounterEntry({
    /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
    required String speciesId,
    required int minLevel,
    required int maxLevel,

    /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
    @Default(1) int weight,
  }) = _ProjectEncounterEntry;

  factory ProjectEncounterEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectEncounterEntryFromJson(json);
}

/// Table de rencontres réutilisable au niveau projet.
///
/// Une [MapGameplayZone] peut y faire référence via [MapGameplayZone.encounterTableId].
/// Le runtime choisit une entrée au tirage pondéré et déclenche le système de combat.
@freezed
class ProjectEncounterTable with _$ProjectEncounterTable {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectEncounterTable({
    required String id,
    required String name,
    required EncounterKind encounterKind,
    @Default([]) List<ProjectEncounterEntry> entries,
    @Default([]) List<String> tags,
  }) = _ProjectEncounterTable;

  factory ProjectEncounterTable.fromJson(Map<String, dynamic> json) =>
      _$ProjectEncounterTableFromJson(json);
}

extension TilesetVisualFrameListX on List<TilesetVisualFrame> {
  TilesetVisualFrame get primaryFrame {
    if (isEmpty) {
      throw StateError('At least one TilesetVisualFrame is required');
    }
    return first;
  }

  TilesetSourceRect get primarySource => primaryFrame.source;
}

@freezed
class ProjectScriptEntry with _$ProjectScriptEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectScriptEntry({
    required String id,
    required String name,
    required ScriptAsset asset,
    @Default([]) List<String> tags,
  }) = _ProjectScriptEntry;

  factory ProjectScriptEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectScriptEntryFromJson(json);
}

@freezed
class ProjectCharacterEntry with _$ProjectCharacterEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectCharacterEntry({
    required String id,
    required String name,
    required String tilesetId,
    @Default(1) int frameWidth,
    @Default(2) int frameHeight,
    @Default([]) List<CharacterAnimation> animations,
    @Default([]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectCharacterEntry;

  factory ProjectCharacterEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectCharacterEntryFromJson(json);
}

@freezed
class CharacterAnimation with _$CharacterAnimation {
  @JsonSerializable(explicitToJson: true)
  const factory CharacterAnimation({
    required CharacterAnimationState state,
    required EntityFacing direction,
    @Default([]) List<CharacterAnimationFrame> frames,
  }) = _CharacterAnimation;

  factory CharacterAnimation.fromJson(Map<String, dynamic> json) =>
      _$CharacterAnimationFromJson(json);
}

@freezed
class CharacterAnimationFrame with _$CharacterAnimationFrame {
  @JsonSerializable(explicitToJson: true)
  const factory CharacterAnimationFrame({
    required TilesetSourceRect source,
    @Default(150) int durationMs,
  }) = _CharacterAnimationFrame;

  factory CharacterAnimationFrame.fromJson(Map<String, dynamic> json) =>
      _$CharacterAnimationFrameFromJson(json);
}
