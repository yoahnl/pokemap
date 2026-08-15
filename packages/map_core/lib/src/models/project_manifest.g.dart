// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectManifest _$ProjectManifestFromJson(
  Map<String, dynamic> json,
) => _ProjectManifest(
  name: json['name'] as String,
  version:
      $enumDecodeNullable(_$ProjectVersionEnumMap, json['version']) ??
      ProjectVersion.v6,
  maps: (json['maps'] as List<dynamic>)
      .map((e) => ProjectMapEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  groups:
      (json['groups'] as List<dynamic>?)
          ?.map((e) => ProjectMapGroup.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  tilesetFolders:
      (json['tilesetFolders'] as List<dynamic>?)
          ?.map((e) => ProjectTilesetFolder.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  tilesets: (json['tilesets'] as List<dynamic>)
      .map((e) => ProjectTilesetEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  elementCategories:
      (json['elementCategories'] as List<dynamic>?)
          ?.map(
            (e) => ProjectElementCategory.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  elements:
      (json['elements'] as List<dynamic>?)
          ?.map((e) => ProjectElementEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  environmentPresets: json['environmentPresets'] == null
      ? const []
      : decodeEnvironmentPresets(json['environmentPresets']),
  encounterTables:
      (json['encounterTables'] as List<dynamic>?)
          ?.map(
            (e) => ProjectEncounterTable.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  dialogueFolders:
      (json['dialogueFolders'] as List<dynamic>?)
          ?.map(
            (e) => ProjectDialogueFolder.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  dialogues:
      (json['dialogues'] as List<dynamic>?)
          ?.map((e) => ProjectDialogueEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  scripts:
      (json['scripts'] as List<dynamic>?)
          ?.map((e) => ProjectScriptEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  scenarios:
      (json['scenarios'] as List<dynamic>?)
          ?.map((e) => ScenarioAsset.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  cinematics: json['cinematics'] == null
      ? const []
      : _cinematicsFromJson(json['cinematics']),
  cinematicLibraryCatalog: json['cinematicLibraryCatalog'] == null
      ? const CinematicLibraryCatalog.empty()
      : _cinematicLibraryCatalogFromJson(json['cinematicLibraryCatalog']),
  presentationCinematics: json['presentationCinematics'] == null
      ? const []
      : _presentationCinematicsFromJson(json['presentationCinematics']),
  cinematicMediaAssets: json['cinematicMediaAssets'] == null
      ? const []
      : _cinematicMediaAssetsFromJson(json['cinematicMediaAssets']),
  facts: json['facts'] == null ? const [] : _factsFromJson(json['facts']),
  worldRules: json['worldRules'] == null
      ? const []
      : _worldRulesFromJson(json['worldRules']),
  narrativeDiagnosticSuppressions:
      (json['narrativeDiagnosticSuppressions'] as List<dynamic>?)
          ?.map(
            (e) => NarrativeDiagnosticSuppression.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const [],
  eventRegistry: json['eventRegistry'] == null
      ? null
      : NarrativeEventRegistry.fromJson(json['eventRegistry']),
  scenes: json['scenes'] == null ? const [] : _scenesFromJson(json['scenes']),
  storylines: json['storylines'] == null
      ? const []
      : _storylinesFromJson(json['storylines']),
  shops:
      (json['shops'] as List<dynamic>?)
          ?.map((e) => ShopDefinition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  badges:
      (json['badges'] as List<dynamic>?)
          ?.map((e) => BadgeDefinition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  trainers:
      (json['trainers'] as List<dynamic>?)
          ?.map((e) => ProjectTrainerEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  characters:
      (json['characters'] as List<dynamic>?)
          ?.map(
            (e) => ProjectCharacterEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  characterStudioCatalog: json['characterStudioCatalog'] == null
      ? const ProjectCharacterStudioCatalog()
      : ProjectCharacterStudioCatalog.fromJson(
          json['characterStudioCatalog'] as Map<String, dynamic>,
        ),
  settings: json['settings'] == null
      ? const ProjectSettings()
      : ProjectSettings.fromJson(json['settings'] as Map<String, dynamic>),
  pokemon: json['pokemon'] == null
      ? const ProjectPokemonConfig(ruleset: PokemonRulesetProfile.pokeMapBetaV1)
      : ProjectPokemonConfig.fromJson(json['pokemon'] as Map<String, dynamic>),
  newGame: json['newGame'] == null
      ? const ProjectNewGameConfig()
      : ProjectNewGameConfig.fromJson(json['newGame'] as Map<String, dynamic>),
  presentation: json['presentation'] == null
      ? null
      : ProjectPresentationProfile.fromJson(
          json['presentation'] as Map<String, dynamic>,
        ),
  presentationPresets:
      (json['presentationPresets'] as List<dynamic>?)
          ?.map(
            (e) => ProjectPresentationPresetRecord.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const [],
  globalProperties:
      json['globalProperties'] as Map<String, dynamic>? ?? const {},
  smartTileCatalog: json['smartTileCatalog'] == null
      ? const ProjectSmartTileCatalog.empty()
      : _projectSmartTileCatalogFromJson(json['smartTileCatalog']),
  borderCatalog: _readProjectBorderCatalog(json, 'borderCatalog') == null
      ? const ProjectBorderCatalog.empty()
      : _projectBorderCatalogFromJson(
          _readProjectBorderCatalog(json, 'borderCatalog'),
        ),
  shadowCatalog: json['shadowCatalog'] == null
      ? const ProjectShadowCatalog.empty()
      : const ProjectShadowCatalogJsonConverter().fromJson(
          json['shadowCatalog'],
        ),
  projectedBuildingShadowCatalog: json['projectedBuildingShadowCatalog'] == null
      ? const ProjectBuildingShadowPresetCatalog.empty()
      : _projectedBuildingShadowCatalogFromJson(
          json['projectedBuildingShadowCatalog'],
        ),
);

Map<String, dynamic> _$ProjectManifestToJson(
  _ProjectManifest instance,
) => <String, dynamic>{
  'name': instance.name,
  'version': _$ProjectVersionEnumMap[instance.version]!,
  'maps': instance.maps.map((e) => e.toJson()).toList(),
  'groups': instance.groups.map((e) => e.toJson()).toList(),
  'tilesetFolders': instance.tilesetFolders.map((e) => e.toJson()).toList(),
  'tilesets': instance.tilesets.map((e) => e.toJson()).toList(),
  'elementCategories': instance.elementCategories
      .map((e) => e.toJson())
      .toList(),
  'elements': instance.elements.map((e) => e.toJson()).toList(),
  'environmentPresets': encodeEnvironmentPresets(instance.environmentPresets),
  'encounterTables': instance.encounterTables.map((e) => e.toJson()).toList(),
  'dialogueFolders': instance.dialogueFolders.map((e) => e.toJson()).toList(),
  'dialogues': instance.dialogues.map((e) => e.toJson()).toList(),
  'scripts': instance.scripts.map((e) => e.toJson()).toList(),
  'scenarios': instance.scenarios.map((e) => e.toJson()).toList(),
  'cinematics': _cinematicsToJson(instance.cinematics),
  'cinematicLibraryCatalog': ?_cinematicLibraryCatalogToJson(
    instance.cinematicLibraryCatalog,
  ),
  'presentationCinematics': ?_presentationCinematicsToJson(
    instance.presentationCinematics,
  ),
  'cinematicMediaAssets': _cinematicMediaAssetsToJson(
    instance.cinematicMediaAssets,
  ),
  'facts': _factsToJson(instance.facts),
  'worldRules': _worldRulesToJson(instance.worldRules),
  'narrativeDiagnosticSuppressions': instance.narrativeDiagnosticSuppressions
      .map((e) => e.toJson())
      .toList(),
  'eventRegistry': ?instance.eventRegistry?.toJson(),
  'scenes': _scenesToJson(instance.scenes),
  'storylines': _storylinesToJson(instance.storylines),
  'shops': instance.shops.map((e) => e.toJson()).toList(),
  'badges': instance.badges.map((e) => e.toJson()).toList(),
  'trainers': instance.trainers.map((e) => e.toJson()).toList(),
  'characters': instance.characters.map((e) => e.toJson()).toList(),
  'characterStudioCatalog': ?_projectCharacterStudioCatalogToJson(
    instance.characterStudioCatalog,
  ),
  'settings': instance.settings.toJson(),
  'pokemon': instance.pokemon.toJson(),
  'newGame': instance.newGame.toJson(),
  'presentation': ?instance.presentation?.toJson(),
  'presentationPresets': instance.presentationPresets
      .map((e) => e.toJson())
      .toList(),
  'globalProperties': instance.globalProperties,
  'smartTileCatalog': ?_projectSmartTileCatalogToJson(
    instance.smartTileCatalog,
  ),
  'borderCatalog': ?_projectBorderCatalogToJson(instance.borderCatalog),
  'shadowCatalog': const ProjectShadowCatalogJsonConverter().toJson(
    instance.shadowCatalog,
  ),
  'projectedBuildingShadowCatalog': ?_projectedBuildingShadowCatalogToJson(
    instance.projectedBuildingShadowCatalog,
  ),
};

const _$ProjectVersionEnumMap = {
  ProjectVersion.v1: 'v1',
  ProjectVersion.v2: 'v2',
  ProjectVersion.v3: 'v3',
  ProjectVersion.v4: 'v4',
  ProjectVersion.v5: 'v5',
  ProjectVersion.v6: 'v6',
  ProjectVersion.v7: 'v7',
};

_ProjectPokemonConfig _$ProjectPokemonConfigFromJson(
  Map<String, dynamic> json,
) => _ProjectPokemonConfig(
  enabled: json['enabled'] as bool? ?? true,
  ruleset: PokemonRulesetProfile.fromJson(
    json['ruleset'] as Map<String, dynamic>,
  ),
  dataRoot: json['dataRoot'] as String? ?? 'data/pokemon',
  speciesDir: json['speciesDir'] as String? ?? 'data/pokemon/species',
  learnsetsDir: json['learnsetsDir'] as String? ?? 'data/pokemon/learnsets',
  evolutionsDir: json['evolutionsDir'] as String? ?? 'data/pokemon/evolutions',
  mediaDir: json['mediaDir'] as String? ?? 'data/pokemon/media',
  catalogFiles:
      (json['catalogFiles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      _defaultPokemonCatalogFiles,
);

Map<String, dynamic> _$ProjectPokemonConfigToJson(
  _ProjectPokemonConfig instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'ruleset': instance.ruleset.toJson(),
  'dataRoot': instance.dataRoot,
  'speciesDir': instance.speciesDir,
  'learnsetsDir': instance.learnsetsDir,
  'evolutionsDir': instance.evolutionsDir,
  'mediaDir': instance.mediaDir,
  'catalogFiles': instance.catalogFiles,
};

_ProjectSettings _$ProjectSettingsFromJson(Map<String, dynamic> json) =>
    _ProjectSettings(
      tileWidth: (json['tileWidth'] as num?)?.toInt() ?? 16,
      tileHeight: (json['tileHeight'] as num?)?.toInt() ?? 16,
      displayScale: (json['displayScale'] as num?)?.toDouble() ?? 2.0,
      defaultMapWidth: (json['defaultMapWidth'] as num?)?.toInt() ?? 20,
      defaultMapHeight: (json['defaultMapHeight'] as num?)?.toInt() ?? 15,
      defaultPlayerCharacterId:
          _readDefaultPlayerCharacterId(json, 'defaultPlayerCharacterId')
              as String?,
      mistralApiKey: json['mistralApiKey'] as String?,
    );

Map<String, dynamic> _$ProjectSettingsToJson(_ProjectSettings instance) =>
    <String, dynamic>{
      'tileWidth': instance.tileWidth,
      'tileHeight': instance.tileHeight,
      'displayScale': instance.displayScale,
      'defaultMapWidth': instance.defaultMapWidth,
      'defaultMapHeight': instance.defaultMapHeight,
      'defaultPlayerCharacterId': instance.defaultPlayerCharacterId,
      'mistralApiKey': ?instance.mistralApiKey,
    };

_ProjectMapGroup _$ProjectMapGroupFromJson(Map<String, dynamic> json) =>
    _ProjectMapGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$MapGroupTypeEnumMap, json['type']),
      parentGroupId: json['parentGroupId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ProjectMapGroupToJson(_ProjectMapGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$MapGroupTypeEnumMap[instance.type]!,
      'parentGroupId': instance.parentGroupId,
      'sortOrder': instance.sortOrder,
      'tags': instance.tags,
      'properties': instance.properties,
    };

const _$MapGroupTypeEnumMap = {
  MapGroupType.city: 'city',
  MapGroupType.village: 'village',
  MapGroupType.route: 'route',
  MapGroupType.dungeon: 'dungeon',
  MapGroupType.cave: 'cave',
  MapGroupType.forest: 'forest',
  MapGroupType.tower: 'tower',
  MapGroupType.facility: 'facility',
  MapGroupType.special: 'special',
};

_ProjectMapEntry _$ProjectMapEntryFromJson(
  Map<String, dynamic> json,
) => _ProjectMapEntry(
  id: json['id'] as String,
  name: json['name'] as String,
  relativePath: json['relativePath'] as String,
  groupId: json['groupId'] as String?,
  role: $enumDecodeNullable(_$MapRoleEnumMap, json['role']) ?? MapRole.exterior,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectMapEntryToJson(_ProjectMapEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
      'groupId': instance.groupId,
      'role': _$MapRoleEnumMap[instance.role]!,
      'sortOrder': instance.sortOrder,
    };

const _$MapRoleEnumMap = {
  MapRole.exterior: 'exterior',
  MapRole.interior: 'interior',
  MapRole.basement: 'basement',
  MapRole.upper_floor: 'upper_floor',
  MapRole.connector: 'connector',
  MapRole.gate: 'gate',
  MapRole.room: 'room',
  MapRole.section: 'section',
  MapRole.sub_area: 'sub_area',
};

_ProjectDialogueFolder _$ProjectDialogueFolderFromJson(
  Map<String, dynamic> json,
) => _ProjectDialogueFolder(
  id: json['id'] as String,
  name: json['name'] as String,
  parentFolderId: json['parentFolderId'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectDialogueFolderToJson(
  _ProjectDialogueFolder instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'parentFolderId': instance.parentFolderId,
  'sortOrder': instance.sortOrder,
};

_DialogueDeclaredOutcome _$DialogueDeclaredOutcomeFromJson(
  Map<String, dynamic> json,
) => _DialogueDeclaredOutcome(
  id: json['id'] as String,
  label: json['label'] as String,
);

Map<String, dynamic> _$DialogueDeclaredOutcomeToJson(
  _DialogueDeclaredOutcome instance,
) => <String, dynamic>{'id': instance.id, 'label': instance.label};

_ProjectDialogueEntry _$ProjectDialogueEntryFromJson(
  Map<String, dynamic> json,
) => _ProjectDialogueEntry(
  id: json['id'] as String,
  name: json['name'] as String,
  relativePath: json['relativePath'] as String,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  description: json['description'] as String? ?? '',
  declaredOutcomes:
      (json['declaredOutcomes'] as List<dynamic>?)
          ?.map(
            (e) => DialogueDeclaredOutcome.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  defaultStartNode: json['defaultStartNode'] as String?,
  folderId: json['folderId'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectDialogueEntryToJson(
  _ProjectDialogueEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'relativePath': instance.relativePath,
  'tags': instance.tags,
  'description': instance.description,
  'declaredOutcomes': instance.declaredOutcomes.map((e) => e.toJson()).toList(),
  'defaultStartNode': instance.defaultStartNode,
  'folderId': instance.folderId,
  'sortOrder': instance.sortOrder,
};

_ProjectTilesetFolder _$ProjectTilesetFolderFromJson(
  Map<String, dynamic> json,
) => _ProjectTilesetFolder(
  id: json['id'] as String,
  name: json['name'] as String,
  parentFolderId: json['parentFolderId'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectTilesetFolderToJson(
  _ProjectTilesetFolder instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'parentFolderId': instance.parentFolderId,
  'sortOrder': instance.sortOrder,
};

_ProjectTilesetEntry _$ProjectTilesetEntryFromJson(
  Map<String, dynamic> json,
) => _ProjectTilesetEntry(
  id: json['id'] as String,
  name: json['name'] as String,
  relativePath: json['relativePath'] as String,
  source: json['source'] == null
      ? null
      : ProjectTilesetSource.fromJson(json['source'] as Map<String, dynamic>),
  scope:
      $enumDecodeNullable(_$TilesetScopeEnumMap, json['scope']) ??
      TilesetScope.global,
  groupId: json['groupId'] as String?,
  folderId: json['folderId'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  isWorldTileset: json['isWorldTileset'] as bool? ?? false,
  transparentColor: _tilesetTransparentColorFromJson(json['transparentColor']),
  elementGroups:
      (json['elementGroups'] as List<dynamic>?)
          ?.map((e) => TilesetElementGroup.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  paletteEntries:
      (json['paletteEntries'] as List<dynamic>?)
          ?.map((e) => TilesetPaletteEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ProjectTilesetEntryToJson(
  _ProjectTilesetEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'relativePath': instance.relativePath,
  'source': ?instance.source?.toJson(),
  'scope': _$TilesetScopeEnumMap[instance.scope]!,
  'groupId': instance.groupId,
  'folderId': instance.folderId,
  'sortOrder': instance.sortOrder,
  'isWorldTileset': instance.isWorldTileset,
  'transparentColor': ?_tilesetTransparentColorToJson(
    instance.transparentColor,
  ),
  'elementGroups': instance.elementGroups.map((e) => e.toJson()).toList(),
  'paletteEntries': instance.paletteEntries.map((e) => e.toJson()).toList(),
};

const _$TilesetScopeEnumMap = {
  TilesetScope.global: 'global',
  TilesetScope.group: 'group',
};

_TilesetPaletteEntry _$TilesetPaletteEntryFromJson(Map<String, dynamic> json) =>
    _TilesetPaletteEntry(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category:
          $enumDecodeNullable(_$PaletteCategoryEnumMap, json['category']) ??
          PaletteCategory.uncategorized,
      frames: (json['frames'] as List<dynamic>)
          .map((e) => TilesetVisualFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedLayerId: json['recommendedLayerId'] as String?,
    );

Map<String, dynamic> _$TilesetPaletteEntryToJson(
  _TilesetPaletteEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category': _$PaletteCategoryEnumMap[instance.category]!,
  'frames': instance.frames.map((e) => e.toJson()).toList(),
  'recommendedLayerId': instance.recommendedLayerId,
};

const _$PaletteCategoryEnumMap = {
  PaletteCategory.floors: 'floors',
  PaletteCategory.paths: 'paths',
  PaletteCategory.water: 'water',
  PaletteCategory.buildings: 'buildings',
  PaletteCategory.roofs: 'roofs',
  PaletteCategory.plants: 'plants',
  PaletteCategory.trees: 'trees',
  PaletteCategory.cliffs: 'cliffs',
  PaletteCategory.decorations: 'decorations',
  PaletteCategory.interiors: 'interiors',
  PaletteCategory.objects: 'objects',
  PaletteCategory.uncategorized: 'uncategorized',
};

_TilesetSourceRect _$TilesetSourceRectFromJson(Map<String, dynamic> json) =>
    _TilesetSourceRect(
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      width: (json['width'] as num?)?.toInt() ?? 1,
      height: (json['height'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$TilesetSourceRectToJson(_TilesetSourceRect instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
    };

_TilesetVisualFrame _$TilesetVisualFrameFromJson(Map<String, dynamic> json) =>
    _TilesetVisualFrame(
      tilesetId: json['tilesetId'] as String? ?? '',
      source: TilesetSourceRect.fromJson(
        json['source'] as Map<String, dynamic>,
      ),
      durationMs: (json['durationMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TilesetVisualFrameToJson(_TilesetVisualFrame instance) =>
    <String, dynamic>{
      'tilesetId': instance.tilesetId,
      'source': instance.source.toJson(),
      'durationMs': instance.durationMs,
    };

_TilesetElementGroup _$TilesetElementGroupFromJson(Map<String, dynamic> json) =>
    _TilesetElementGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      parentGroupId: json['parentGroupId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TilesetElementGroupToJson(
  _TilesetElementGroup instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'parentGroupId': instance.parentGroupId,
  'sortOrder': instance.sortOrder,
};

_ProjectElementCategory _$ProjectElementCategoryFromJson(
  Map<String, dynamic> json,
) => _ProjectElementCategory(
  id: json['id'] as String,
  name: json['name'] as String,
  parentCategoryId: json['parentCategoryId'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectElementCategoryToJson(
  _ProjectElementCategory instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'parentCategoryId': instance.parentCategoryId,
  'sortOrder': instance.sortOrder,
};

_ProjectElementEntry _$ProjectElementEntryFromJson(Map<String, dynamic> json) =>
    _ProjectElementEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      tilesetId: json['tilesetId'] as String,
      categoryId: json['categoryId'] as String,
      tilesetGroupId: json['tilesetGroupId'] as String?,
      frames: (json['frames'] as List<dynamic>)
          .map((e) => TilesetVisualFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      presetKind:
          $enumDecodeNullable(_$ElementPresetKindEnumMap, json['presetKind']) ??
          ElementPresetKind.generic,
      collisionProfile: json['collisionProfile'] == null
          ? null
          : ElementCollisionProfile.fromJson(
              json['collisionProfile'] as Map<String, dynamic>,
            ),
      shadow: const ProjectElementShadowConfigJsonConverter().fromJson(
        json['shadow'],
      ),
      projectedBuildingShadow: _projectedBuildingShadowConfigFromJson(
        json['projectedBuildingShadow'],
      ),
      groupId: json['groupId'] as String?,
      recommendedLayerId: json['recommendedLayerId'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ProjectElementEntryToJson(
  _ProjectElementEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'tilesetId': instance.tilesetId,
  'categoryId': instance.categoryId,
  'tilesetGroupId': instance.tilesetGroupId,
  'frames': instance.frames.map((e) => e.toJson()).toList(),
  'presetKind': _$ElementPresetKindEnumMap[instance.presetKind]!,
  'collisionProfile': instance.collisionProfile?.toJson(),
  'shadow': const ProjectElementShadowConfigJsonConverter().toJson(
    instance.shadow,
  ),
  'projectedBuildingShadow': ?_projectedBuildingShadowConfigToJson(
    instance.projectedBuildingShadow,
  ),
  'groupId': instance.groupId,
  'recommendedLayerId': instance.recommendedLayerId,
  'tags': instance.tags,
  'sortOrder': instance.sortOrder,
};

const _$ElementPresetKindEnumMap = {
  ElementPresetKind.generic: 'generic',
  ElementPresetKind.tree: 'tree',
  ElementPresetKind.building: 'building',
  ElementPresetKind.rock: 'rock',
  ElementPresetKind.cliff: 'cliff',
  ElementPresetKind.tallDecoration: 'tall_decoration',
};

_ProjectEncounterPokemonOverrides _$ProjectEncounterPokemonOverridesFromJson(
  Map<String, dynamic> json,
) => _ProjectEncounterPokemonOverrides(
  natureId: json['natureId'] as String?,
  abilityId: json['abilityId'] as String?,
  gender: json['gender'] as String?,
  ivs: json['ivs'] == null
      ? null
      : PokemonStatSpread.fromJson(json['ivs'] as Map<String, dynamic>),
  shinyPolicy:
      $enumDecodeNullable(
        _$ProjectEncounterShinyPolicyEnumMap,
        json['shinyPolicy'],
      ) ??
      ProjectEncounterShinyPolicy.random,
  knownMoveIds:
      (json['knownMoveIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$ProjectEncounterPokemonOverridesToJson(
  _ProjectEncounterPokemonOverrides instance,
) => <String, dynamic>{
  'natureId': instance.natureId,
  'abilityId': instance.abilityId,
  'gender': instance.gender,
  'ivs': instance.ivs?.toJson(),
  'shinyPolicy': _$ProjectEncounterShinyPolicyEnumMap[instance.shinyPolicy]!,
  'knownMoveIds': instance.knownMoveIds,
};

const _$ProjectEncounterShinyPolicyEnumMap = {
  ProjectEncounterShinyPolicy.random: 'random',
  ProjectEncounterShinyPolicy.never: 'never',
  ProjectEncounterShinyPolicy.always: 'always',
};

_ProjectEncounterEntry _$ProjectEncounterEntryFromJson(
  Map<String, dynamic> json,
) => _ProjectEncounterEntry(
  speciesId: json['speciesId'] as String,
  minLevel: (json['minLevel'] as num).toInt(),
  maxLevel: (json['maxLevel'] as num).toInt(),
  weight: (json['weight'] as num?)?.toInt() ?? 1,
  pokemonOverrides: json['pokemonOverrides'] == null
      ? null
      : ProjectEncounterPokemonOverrides.fromJson(
          json['pokemonOverrides'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProjectEncounterEntryToJson(
  _ProjectEncounterEntry instance,
) => <String, dynamic>{
  'speciesId': instance.speciesId,
  'minLevel': instance.minLevel,
  'maxLevel': instance.maxLevel,
  'weight': instance.weight,
  'pokemonOverrides': ?instance.pokemonOverrides?.toJson(),
};

_ProjectEncounterTable _$ProjectEncounterTableFromJson(
  Map<String, dynamic> json,
) => _ProjectEncounterTable(
  id: json['id'] as String,
  name: json['name'] as String,
  encounterKind: $enumDecode(_$EncounterKindEnumMap, json['encounterKind']),
  chancePerStep:
      (json['chancePerStep'] as num?)?.toDouble() ??
      defaultEncounterChancePerStep,
  conditions:
      (json['conditions'] as List<dynamic>?)
          ?.map((e) => ScriptCondition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map(
            (e) => ProjectEncounterEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ProjectEncounterTableToJson(
  _ProjectEncounterTable instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'encounterKind': _$EncounterKindEnumMap[instance.encounterKind]!,
  'chancePerStep': instance.chancePerStep,
  'conditions': instance.conditions.map((e) => e.toJson()).toList(),
  'entries': instance.entries.map((e) => e.toJson()).toList(),
  'tags': instance.tags,
};

const _$EncounterKindEnumMap = {
  EncounterKind.walk: 'walk',
  EncounterKind.surf: 'surf',
  EncounterKind.headbutt: 'headbutt',
  EncounterKind.oldRod: 'old_rod',
  EncounterKind.goodRod: 'good_rod',
  EncounterKind.superRod: 'super_rod',
  EncounterKind.gift: 'gift',
  EncounterKind.special: 'special',
};

_ProjectScriptEntry _$ProjectScriptEntryFromJson(Map<String, dynamic> json) =>
    _ProjectScriptEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      asset: ScriptAsset.fromJson(json['asset'] as Map<String, dynamic>),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );

Map<String, dynamic> _$ProjectScriptEntryToJson(_ProjectScriptEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'asset': instance.asset.toJson(),
      'tags': instance.tags,
    };

_ProjectCharacterStudioCatalog _$ProjectCharacterStudioCatalogFromJson(
  Map<String, dynamic> json,
) => _ProjectCharacterStudioCatalog(
  portraitStates:
      (json['portraitStates'] as List<dynamic>?)
          ?.map(
            (e) => CharacterPortraitStateDefinition.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const [],
  customAnimationDefinitions:
      (json['customAnimationDefinitions'] as List<dynamic>?)
          ?.map(
            (e) => CharacterCustomAnimationDefinition.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$ProjectCharacterStudioCatalogToJson(
  _ProjectCharacterStudioCatalog instance,
) => <String, dynamic>{
  'portraitStates': instance.portraitStates.map((e) => e.toJson()).toList(),
  'customAnimationDefinitions': instance.customAnimationDefinitions
      .map((e) => e.toJson())
      .toList(),
};

_CharacterPortraitStateDefinition _$CharacterPortraitStateDefinitionFromJson(
  Map<String, dynamic> json,
) => _CharacterPortraitStateDefinition(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CharacterPortraitStateDefinitionToJson(
  _CharacterPortraitStateDefinition instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'sortOrder': instance.sortOrder,
};

_CharacterCustomAnimationDefinition
_$CharacterCustomAnimationDefinitionFromJson(Map<String, dynamic> json) =>
    _CharacterCustomAnimationDefinition(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      mode: $enumDecode(_$CharacterCustomAnimationModeEnumMap, json['mode']),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CharacterCustomAnimationDefinitionToJson(
  _CharacterCustomAnimationDefinition instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'mode': _$CharacterCustomAnimationModeEnumMap[instance.mode]!,
  'sortOrder': instance.sortOrder,
};

const _$CharacterCustomAnimationModeEnumMap = {
  CharacterCustomAnimationMode.single: 'single',
  CharacterCustomAnimationMode.directional: 'directional',
};

_CharacterPortraitVariant _$CharacterPortraitVariantFromJson(
  Map<String, dynamic> json,
) => _CharacterPortraitVariant(
  portraitStateId: json['portraitStateId'] as String,
  assetId: json['assetId'] as String,
  fitMode:
      $enumDecodeNullable(_$CharacterPortraitFitModeEnumMap, json['fitMode']) ??
      CharacterPortraitFitMode.contain,
);

Map<String, dynamic> _$CharacterPortraitVariantToJson(
  _CharacterPortraitVariant instance,
) => <String, dynamic>{
  'portraitStateId': instance.portraitStateId,
  'assetId': instance.assetId,
  'fitMode': _$CharacterPortraitFitModeEnumMap[instance.fitMode]!,
};

const _$CharacterPortraitFitModeEnumMap = {
  CharacterPortraitFitMode.contain: 'contain',
  CharacterPortraitFitMode.cover: 'cover',
};

_ProjectCharacterEntry _$ProjectCharacterEntryFromJson(
  Map<String, dynamic> json,
) => _ProjectCharacterEntry(
  id: json['id'] as String,
  name: json['name'] as String,
  tilesetId: json['tilesetId'] as String,
  frameWidth: (json['frameWidth'] as num?)?.toInt() ?? 1,
  frameHeight: (json['frameHeight'] as num?)?.toInt() ?? 2,
  portraits:
      (json['portraits'] as List<dynamic>?)
          ?.map(
            (e) => CharacterPortraitVariant.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  animations:
      (json['animations'] as List<dynamic>?)
          ?.map((e) => CharacterAnimation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  customAnimations:
      (json['customAnimations'] as List<dynamic>?)
          ?.map(
            (e) => CharacterCustomAnimationClip.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectCharacterEntryToJson(
  _ProjectCharacterEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'tilesetId': instance.tilesetId,
  'frameWidth': instance.frameWidth,
  'frameHeight': instance.frameHeight,
  'portraits': ?_characterPortraitsToJson(instance.portraits),
  'animations': instance.animations.map((e) => e.toJson()).toList(),
  'customAnimations': ?_characterCustomAnimationsToJson(
    instance.customAnimations,
  ),
  'tags': instance.tags,
  'sortOrder': instance.sortOrder,
};

_CharacterAnimation _$CharacterAnimationFromJson(Map<String, dynamic> json) =>
    _CharacterAnimation(
      state: $enumDecode(_$CharacterAnimationStateEnumMap, json['state']),
      direction: $enumDecode(_$EntityFacingEnumMap, json['direction']),
      sourceAssetId: json['sourceAssetId'] as String?,
      frames:
          (json['frames'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CharacterAnimationFrame.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      loop: json['loop'] as bool? ?? true,
    );

Map<String, dynamic> _$CharacterAnimationToJson(_CharacterAnimation instance) =>
    <String, dynamic>{
      'state': _$CharacterAnimationStateEnumMap[instance.state]!,
      'direction': _$EntityFacingEnumMap[instance.direction]!,
      'sourceAssetId': ?instance.sourceAssetId,
      'frames': instance.frames.map((e) => e.toJson()).toList(),
      'loop': ?_characterAnimationLoopToJson(instance.loop),
    };

const _$CharacterAnimationStateEnumMap = {
  CharacterAnimationState.idle: 'idle',
  CharacterAnimationState.walk: 'walk',
  CharacterAnimationState.run: 'run',
};

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

_CharacterCustomAnimationClip _$CharacterCustomAnimationClipFromJson(
  Map<String, dynamic> json,
) => _CharacterCustomAnimationClip(
  definitionId: json['definitionId'] as String,
  direction: $enumDecodeNullable(_$EntityFacingEnumMap, json['direction']),
  sourceAssetId: json['sourceAssetId'] as String,
  frames:
      (json['frames'] as List<dynamic>?)
          ?.map(
            (e) => CharacterAnimationFrame.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  loop: json['loop'] as bool? ?? true,
);

Map<String, dynamic> _$CharacterCustomAnimationClipToJson(
  _CharacterCustomAnimationClip instance,
) => <String, dynamic>{
  'definitionId': instance.definitionId,
  'direction': ?_$EntityFacingEnumMap[instance.direction],
  'sourceAssetId': instance.sourceAssetId,
  'frames': instance.frames.map((e) => e.toJson()).toList(),
  'loop': instance.loop,
};

_CharacterAnimationFrame _$CharacterAnimationFrameFromJson(
  Map<String, dynamic> json,
) => _CharacterAnimationFrame(
  source: TilesetSourceRect.fromJson(json['source'] as Map<String, dynamic>),
  durationMs: (json['durationMs'] as num?)?.toInt() ?? 150,
);

Map<String, dynamic> _$CharacterAnimationFrameToJson(
  _CharacterAnimationFrame instance,
) => <String, dynamic>{
  'source': instance.source.toJson(),
  'durationMs': instance.durationMs,
};
