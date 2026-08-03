// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TileLayerImpl _$$TileLayerImplFromJson(Map<String, dynamic> json) =>
    _$TileLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      tilesetId: json['tilesetId'] as String?,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      tiles: (json['tiles'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TileLayerImplToJson(_$TileLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tilesetId': instance.tilesetId,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'tiles': instance.tiles,
      'runtimeType': instance.$type,
    };

_$CollisionLayerImpl _$$CollisionLayerImplFromJson(Map<String, dynamic> json) =>
    _$CollisionLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      collisions: (json['collisions'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$CollisionLayerImplToJson(
        _$CollisionLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'collisions': instance.collisions,
      'runtimeType': instance.$type,
    };

_$SmartTileLayerImpl _$$SmartTileLayerImplFromJson(Map<String, dynamic> json) =>
    _$SmartTileLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      presetId: json['presetId'] as String,
      usage: $enumDecode(_$SmartTileUsageEnumMap, json['usage']),
      materialPalette: (json['materialPalette'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[''],
      field: SmartTileField.fromJson(json['field'] as Map<String, dynamic>),
      layerSeed: (json['layerSeed'] as num?)?.toInt() ?? 0,
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$SmartTileLayerImplToJson(
        _$SmartTileLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'presetId': instance.presetId,
      'usage': _$SmartTileUsageEnumMap[instance.usage]!,
      'materialPalette': instance.materialPalette,
      'field': instance.field.toJson(),
      'layerSeed': instance.layerSeed,
      'properties': instance.properties,
      'runtimeType': instance.$type,
    };

const _$SmartTileUsageEnumMap = {
  SmartTileUsage.terrain: 'terrain',
  SmartTileUsage.path: 'path',
  SmartTileUsage.forestSurface: 'forest_surface',
};

_$ObjectLayerImpl _$$ObjectLayerImplFromJson(Map<String, dynamic> json) =>
    _$ObjectLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ObjectLayerImplToJson(_$ObjectLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'runtimeType': instance.$type,
    };

_$EnvironmentLayerImpl _$$EnvironmentLayerImplFromJson(
        Map<String, dynamic> json) =>
    _$EnvironmentLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      content: json['content'] == null
          ? EnvironmentLayerContent.emptyContent
          : decodeEnvironmentLayerContent(json['content']),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$EnvironmentLayerImplToJson(
        _$EnvironmentLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'content': encodeEnvironmentLayerContent(instance.content),
      'properties': instance.properties,
      'runtimeType': instance.$type,
    };

_$BorderLayerImpl _$$BorderLayerImplFromJson(Map<String, dynamic> json) =>
    _$BorderLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      content: _readBorderLayerContent(json, 'content') == null
          ? BorderLayerContent.emptyContent
          : _borderLayerContentFromJson(
              _readBorderLayerContent(json, 'content')),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$BorderLayerImplToJson(_$BorderLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'content': _borderLayerContentToJson(instance.content),
      'properties': instance.properties,
      'runtimeType': instance.$type,
    };
