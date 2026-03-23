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
      'tilesets': instance.tilesets.map((e) => e.toJson()).toList(),
      'elementCategories':
          instance.elementCategories.map((e) => e.toJson()).toList(),
      'elements': instance.elements.map((e) => e.toJson()).toList(),
      'terrainCategories':
          instance.terrainCategories.map((e) => e.toJson()).toList(),
      'pathCategories': instance.pathCategories.map((e) => e.toJson()).toList(),
      'terrainPresets': instance.terrainPresets.map((e) => e.toJson()).toList(),
      'pathPresets': instance.pathPresets.map((e) => e.toJson()).toList(),
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
    );

Map<String, dynamic> _$$ProjectSettingsImplToJson(
        _$ProjectSettingsImpl instance) =>
    <String, dynamic>{
      'tileWidth': instance.tileWidth,
      'tileHeight': instance.tileHeight,
      'displayScale': instance.displayScale,
      'defaultMapWidth': instance.defaultMapWidth,
      'defaultMapHeight': instance.defaultMapHeight,
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

_$ProjectTilesetEntryImpl _$$ProjectTilesetEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTilesetEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      scope: $enumDecodeNullable(_$TilesetScopeEnumMap, json['scope']) ??
          TilesetScope.global,
      groupId: json['groupId'] as String?,
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
      source:
          TilesetSourceRect.fromJson(json['source'] as Map<String, dynamic>),
      recommendedLayerId: json['recommendedLayerId'] as String?,
    );

Map<String, dynamic> _$$TilesetPaletteEntryImplToJson(
        _$TilesetPaletteEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': _$PaletteCategoryEnumMap[instance.category]!,
      'source': instance.source,
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
      source:
          TilesetSourceRect.fromJson(json['source'] as Map<String, dynamic>),
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
      'source': instance.source,
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
      source:
          TilesetSourceRect.fromJson(json['source'] as Map<String, dynamic>),
      weight: (json['weight'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$TerrainPresetVariantImplToJson(
        _$TerrainPresetVariantImpl instance) =>
    <String, dynamic>{
      'source': instance.source,
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
      source:
          TilesetSourceRect.fromJson(json['source'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PathPresetVariantMappingImplToJson(
        _$PathPresetVariantMappingImpl instance) =>
    <String, dynamic>{
      'variant': _$TerrainPathVariantEnumMap[instance.variant]!,
      'source': instance.source,
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
