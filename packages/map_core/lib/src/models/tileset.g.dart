// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tileset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TilesetConfig _$TilesetConfigFromJson(Map<String, dynamic> json) =>
    _TilesetConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      tileSize: (json['tileSize'] as num?)?.toInt() ?? 32,
      tileProperties:
          (json['tileProperties'] as List<dynamic>?)
              ?.map((e) => TileProperties.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      customProperties:
          json['customProperties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TilesetConfigToJson(_TilesetConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
      'tileSize': instance.tileSize,
      'tileProperties': instance.tileProperties.map((e) => e.toJson()).toList(),
      'customProperties': instance.customProperties,
    };

_TileProperties _$TilePropertiesFromJson(Map<String, dynamic> json) =>
    _TileProperties(
      tileId: (json['tileId'] as num).toInt(),
      isPassable: json['isPassable'] as bool? ?? true,
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TilePropertiesToJson(_TileProperties instance) =>
    <String, dynamic>{
      'tileId': instance.tileId,
      'isPassable': instance.isPassable,
      'properties': instance.properties,
    };
