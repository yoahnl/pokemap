// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectManifestImpl _$$ProjectManifestImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectManifestImpl(
      name: json['name'] as String,
      version: $enumDecodeNullable(_$ProjectVersionEnumMap, json['version']) ??
          ProjectVersion.v1,
      maps: (json['maps'] as List<dynamic>)
          .map((e) => ProjectMapEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => ProjectMapGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tilesetFolders: (json['tilesetFolders'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectTilesetFolder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tilesets: (json['tilesets'] as List<dynamic>)
          .map((e) => ProjectTilesetEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      elementCategories: (json['elementCategories'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectElementCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectElementEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      terrainCategories: (json['terrainCategories'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectPresetCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pathCategories: (json['pathCategories'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectPresetCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      terrainPresets: (json['terrainPresets'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectTerrainPreset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pathPresets: (json['pathPresets'] as List<dynamic>?)
              ?.map(
                  (e) => ProjectPathPreset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      encounterTables: (json['encounterTables'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectEncounterTable.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dialogueFolders: (json['dialogueFolders'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectDialogueFolder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dialogues: (json['dialogues'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectDialogueEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      trainers: (json['trainers'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectTrainerEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectCharacterEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      settings: json['settings'] == null
          ? const ProjectSettings()
          : ProjectSettings.fromJson(json['settings'] as Map<String, dynamic>),
      globalProperties:
          json['globalProperties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ProjectManifestImplToJson(
        _$ProjectManifestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': _$ProjectVersionEnumMap[instance.version]!,
      'maps': instance.maps.map((e) => e.toJson()).toList(),
      'groups': instance.groups.map((e) => e.toJson()).toList(),
      'tilesetFolders': instance.tilesetFolders.map((e) => e.toJson()).toList(),
      'tilesets': instance.tilesets.map((e) => e.toJson()).toList(),
      'elementCategories':
          instance.elementCategories.map((e) => e.toJson()).toList(),
      'elements': instance.elements.map((e) => e.toJson()).toList(),
      'terrainCategories':
          instance.terrainCategories.map((e) => e.toJson()).toList(),
      'pathCategories': instance.pathCategories.map((e) => e.toJson()).toList(),
      'terrainPresets': instance.terrainPresets.map((e) => e.toJson()).toList(),
      'pathPresets': instance.pathPresets.map((e) => e.toJson()).toList(),
      'encounterTables':
          instance.encounterTables.map((e) => e.toJson()).toList(),
      'dialogueFolders':
          instance.dialogueFolders.map((e) => e.toJson()).toList(),
      'dialogues': instance.dialogues.map((e) => e.toJson()).toList(),
      'trainers': instance.trainers.map((e) => e.toJson()).toList(),
      'characters': instance.characters.map((e) => e.toJson()).toList(),
      'settings': instance.settings.toJson(),
      'globalProperties': instance.globalProperties,
    };

const _$ProjectVersionEnumMap = {
  ProjectVersion.v1: 'v1',
};

_$ProjectSettingsImpl _$$ProjectSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectSettingsImpl(
      tileWidth: (json['tileWidth'] as num?)?.toInt() ?? 16,
      tileHeight: (json['tileHeight'] as num?)?.toInt() ?? 16,
      displayScale: (json['displayScale'] as num?)?.toDouble() ?? 2.0,
      defaultMapWidth: (json['defaultMapWidth'] as num?)?.toInt() ?? 20,
      defaultMapHeight: (json['defaultMapHeight'] as num?)?.toInt() ?? 15,
      defaultPlayerCharacterId:
          _readDefaultPlayerCharacterId(json, 'defaultPlayerCharacterId')
              as String?,
    );

Map<String, dynamic> _$$ProjectSettingsImplToJson(
        _$ProjectSettingsImpl instance) =>
    <String, dynamic>{
      'tileWidth': instance.tileWidth,
      'tileHeight': instance.tileHeight,
      'displayScale': instance.displayScale,
      'defaultMapWidth': instance.defaultMapWidth,
      'defaultMapHeight': instance.defaultMapHeight,
      'defaultPlayerCharacterId': instance.defaultPlayerCharacterId,
    };

_$ProjectMapGroupImpl _$$ProjectMapGroupImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectMapGroupImpl(
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

Map<String, dynamic> _$$ProjectMapGroupImplToJson(
        _$ProjectMapGroupImpl instance) =>
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

_$ProjectMapEntryImpl _$$ProjectMapEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectMapEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      groupId: json['groupId'] as String?,
      role: $enumDecodeNullable(_$MapRoleEnumMap, json['role']) ??
          MapRole.exterior,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectMapEntryImplToJson(
        _$ProjectMapEntryImpl instance) =>
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

_$ProjectDialogueFolderImpl _$$ProjectDialogueFolderImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectDialogueFolderImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentFolderId: json['parentFolderId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectDialogueFolderImplToJson(
        _$ProjectDialogueFolderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentFolderId': instance.parentFolderId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectDialogueEntryImpl _$$ProjectDialogueEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectDialogueEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      description: json['description'] as String? ?? '',
      defaultStartNode: json['defaultStartNode'] as String?,
      folderId: json['folderId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectDialogueEntryImplToJson(
        _$ProjectDialogueEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
      'tags': instance.tags,
      'description': instance.description,
      'defaultStartNode': instance.defaultStartNode,
      'folderId': instance.folderId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectTilesetFolderImpl _$$ProjectTilesetFolderImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTilesetFolderImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentFolderId: json['parentFolderId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectTilesetFolderImplToJson(
        _$ProjectTilesetFolderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentFolderId': instance.parentFolderId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectTilesetEntryImpl _$$ProjectTilesetEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTilesetEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      scope: $enumDecodeNullable(_$TilesetScopeEnumMap, json['scope']) ??
          TilesetScope.global,
      groupId: json['groupId'] as String?,
      folderId: json['folderId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isWorldTileset: json['isWorldTileset'] as bool? ?? false,
      elementGroups: (json['elementGroups'] as List<dynamic>?)
              ?.map((e) =>
                  TilesetElementGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      paletteEntries: (json['paletteEntries'] as List<dynamic>?)
              ?.map((e) =>
                  TilesetPaletteEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ProjectTilesetEntryImplToJson(
        _$ProjectTilesetEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
      'scope': _$TilesetScopeEnumMap[instance.scope]!,
      'groupId': instance.groupId,
      'folderId': instance.folderId,
      'sortOrder': instance.sortOrder,
      'isWorldTileset': instance.isWorldTileset,
      'elementGroups': instance.elementGroups,
      'paletteEntries': instance.paletteEntries,
    };

const _$TilesetScopeEnumMap = {
  TilesetScope.global: 'global',
  TilesetScope.group: 'group',
};

_$TilesetPaletteEntryImpl _$$TilesetPaletteEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$TilesetPaletteEntryImpl(
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

Map<String, dynamic> _$$TilesetPaletteEntryImplToJson(
        _$TilesetPaletteEntryImpl instance) =>
    <String, dynamic>{
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

_$TilesetSourceRectImpl _$$TilesetSourceRectImplFromJson(
        Map<String, dynamic> json) =>
    _$TilesetSourceRectImpl(
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      width: (json['width'] as num?)?.toInt() ?? 1,
      height: (json['height'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$TilesetSourceRectImplToJson(
        _$TilesetSourceRectImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
    };

_$TilesetVisualFrameImpl _$$TilesetVisualFrameImplFromJson(
        Map<String, dynamic> json) =>
    _$TilesetVisualFrameImpl(
      tilesetId: json['tilesetId'] as String? ?? '',
      source:
          TilesetSourceRect.fromJson(json['source'] as Map<String, dynamic>),
      durationMs: (json['durationMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$TilesetVisualFrameImplToJson(
        _$TilesetVisualFrameImpl instance) =>
    <String, dynamic>{
      'tilesetId': instance.tilesetId,
      'source': instance.source.toJson(),
      'durationMs': instance.durationMs,
    };

_$TilesetElementGroupImpl _$$TilesetElementGroupImplFromJson(
        Map<String, dynamic> json) =>
    _$TilesetElementGroupImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentGroupId: json['parentGroupId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TilesetElementGroupImplToJson(
        _$TilesetElementGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentGroupId': instance.parentGroupId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectElementCategoryImpl _$$ProjectElementCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectElementCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentCategoryId: json['parentCategoryId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectElementCategoryImplToJson(
        _$ProjectElementCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentCategoryId': instance.parentCategoryId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectElementEntryImpl _$$ProjectElementEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectElementEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      tilesetId: json['tilesetId'] as String,
      categoryId: json['categoryId'] as String,
      tilesetGroupId: json['tilesetGroupId'] as String?,
      frames: (json['frames'] as List<dynamic>)
          .map((e) => TilesetVisualFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupId: json['groupId'] as String?,
      recommendedLayerId: json['recommendedLayerId'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectElementEntryImplToJson(
        _$ProjectElementEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tilesetId': instance.tilesetId,
      'categoryId': instance.categoryId,
      'tilesetGroupId': instance.tilesetGroupId,
      'frames': instance.frames.map((e) => e.toJson()).toList(),
      'groupId': instance.groupId,
      'recommendedLayerId': instance.recommendedLayerId,
      'tags': instance.tags,
      'sortOrder': instance.sortOrder,
    };

_$ProjectTerrainPresetImpl _$$ProjectTerrainPresetImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTerrainPresetImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      terrainType: $enumDecode(_$TerrainTypeEnumMap, json['terrainType']),
      categoryId: json['categoryId'] as String?,
      tilesetId: json['tilesetId'] as String? ?? '',
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) =>
                  TerrainPresetVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectTerrainPresetImplToJson(
        _$ProjectTerrainPresetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'terrainType': _$TerrainTypeEnumMap[instance.terrainType]!,
      'categoryId': instance.categoryId,
      'tilesetId': instance.tilesetId,
      'variants': instance.variants,
      'sortOrder': instance.sortOrder,
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

_$TerrainPresetVariantImpl _$$TerrainPresetVariantImplFromJson(
        Map<String, dynamic> json) =>
    _$TerrainPresetVariantImpl(
      frames: (json['frames'] as List<dynamic>)
          .map((e) => TilesetVisualFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      weight: (json['weight'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$TerrainPresetVariantImplToJson(
        _$TerrainPresetVariantImpl instance) =>
    <String, dynamic>{
      'frames': instance.frames.map((e) => e.toJson()).toList(),
      'weight': instance.weight,
    };

_$ProjectPathPresetImpl _$$ProjectPathPresetImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectPathPresetImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      surfaceKind:
          $enumDecodeNullable(_$PathSurfaceKindEnumMap, json['surfaceKind']) ??
              PathSurfaceKind.path,
      categoryId: json['categoryId'] as String?,
      tilesetId: json['tilesetId'] as String? ?? '',
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) =>
                  PathPresetVariantMapping.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectPathPresetImplToJson(
        _$ProjectPathPresetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'surfaceKind': _$PathSurfaceKindEnumMap[instance.surfaceKind]!,
      'categoryId': instance.categoryId,
      'tilesetId': instance.tilesetId,
      'variants': instance.variants,
      'sortOrder': instance.sortOrder,
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

_$PathPresetVariantMappingImpl _$$PathPresetVariantMappingImplFromJson(
        Map<String, dynamic> json) =>
    _$PathPresetVariantMappingImpl(
      variant: $enumDecode(_$TerrainPathVariantEnumMap, json['variant']),
      frames: (json['frames'] as List<dynamic>)
          .map((e) => TilesetVisualFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PathPresetVariantMappingImplToJson(
        _$PathPresetVariantMappingImpl instance) =>
    <String, dynamic>{
      'variant': _$TerrainPathVariantEnumMap[instance.variant]!,
      'frames': instance.frames.map((e) => e.toJson()).toList(),
    };

const _$TerrainPathVariantEnumMap = {
  TerrainPathVariant.isolated: 'isolated',
  TerrainPathVariant.endNorth: 'endNorth',
  TerrainPathVariant.endEast: 'endEast',
  TerrainPathVariant.endSouth: 'endSouth',
  TerrainPathVariant.endWest: 'endWest',
  TerrainPathVariant.horizontal: 'horizontal',
  TerrainPathVariant.vertical: 'vertical',
  TerrainPathVariant.cornerNE: 'cornerNE',
  TerrainPathVariant.cornerSE: 'cornerSE',
  TerrainPathVariant.cornerSW: 'cornerSW',
  TerrainPathVariant.cornerNW: 'cornerNW',
  TerrainPathVariant.innerCornerNE: 'innerCornerNE',
  TerrainPathVariant.innerCornerSE: 'innerCornerSE',
  TerrainPathVariant.innerCornerSW: 'innerCornerSW',
  TerrainPathVariant.innerCornerNW: 'innerCornerNW',
  TerrainPathVariant.teeNorth: 'teeNorth',
  TerrainPathVariant.teeEast: 'teeEast',
  TerrainPathVariant.teeSouth: 'teeSouth',
  TerrainPathVariant.teeWest: 'teeWest',
  TerrainPathVariant.cross: 'cross',
};

_$ProjectPresetCategoryImpl _$$ProjectPresetCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectPresetCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentCategoryId: json['parentCategoryId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectPresetCategoryImplToJson(
        _$ProjectPresetCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentCategoryId': instance.parentCategoryId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectEncounterEntryImpl _$$ProjectEncounterEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectEncounterEntryImpl(
      speciesId: json['speciesId'] as String,
      minLevel: (json['minLevel'] as num).toInt(),
      maxLevel: (json['maxLevel'] as num).toInt(),
      weight: (json['weight'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$ProjectEncounterEntryImplToJson(
        _$ProjectEncounterEntryImpl instance) =>
    <String, dynamic>{
      'speciesId': instance.speciesId,
      'minLevel': instance.minLevel,
      'maxLevel': instance.maxLevel,
      'weight': instance.weight,
    };

_$ProjectEncounterTableImpl _$$ProjectEncounterTableImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectEncounterTableImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      encounterKind: $enumDecode(_$EncounterKindEnumMap, json['encounterKind']),
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectEncounterEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$ProjectEncounterTableImplToJson(
        _$ProjectEncounterTableImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'encounterKind': _$EncounterKindEnumMap[instance.encounterKind]!,
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

_$ProjectCharacterEntryImpl _$$ProjectCharacterEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectCharacterEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      tilesetId: json['tilesetId'] as String,
      frameWidth: (json['frameWidth'] as num?)?.toInt() ?? 1,
      frameHeight: (json['frameHeight'] as num?)?.toInt() ?? 2,
      animations: (json['animations'] as List<dynamic>?)
              ?.map(
                  (e) => CharacterAnimation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectCharacterEntryImplToJson(
        _$ProjectCharacterEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tilesetId': instance.tilesetId,
      'frameWidth': instance.frameWidth,
      'frameHeight': instance.frameHeight,
      'animations': instance.animations.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
      'sortOrder': instance.sortOrder,
    };

_$CharacterAnimationImpl _$$CharacterAnimationImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterAnimationImpl(
      state: $enumDecode(_$CharacterAnimationStateEnumMap, json['state']),
      direction: $enumDecode(_$EntityFacingEnumMap, json['direction']),
      frames: (json['frames'] as List<dynamic>?)
              ?.map((e) =>
                  CharacterAnimationFrame.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CharacterAnimationImplToJson(
        _$CharacterAnimationImpl instance) =>
    <String, dynamic>{
      'state': _$CharacterAnimationStateEnumMap[instance.state]!,
      'direction': _$EntityFacingEnumMap[instance.direction]!,
      'frames': instance.frames.map((e) => e.toJson()).toList(),
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

_$CharacterAnimationFrameImpl _$$CharacterAnimationFrameImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterAnimationFrameImpl(
      source:
          TilesetSourceRect.fromJson(json['source'] as Map<String, dynamic>),
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 150,
    );

Map<String, dynamic> _$$CharacterAnimationFrameImplToJson(
        _$CharacterAnimationFrameImpl instance) =>
    <String, dynamic>{
      'source': instance.source.toJson(),
      'durationMs': instance.durationMs,
    };
