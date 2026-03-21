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
      'source': instance.source,
      'groupId': instance.groupId,
      'recommendedLayerId': instance.recommendedLayerId,
      'tags': instance.tags,
      'sortOrder': instance.sortOrder,
    };
