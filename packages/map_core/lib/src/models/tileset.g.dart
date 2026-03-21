// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tileset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TilesetConfigImpl _$$TilesetConfigImplFromJson(Map<String, dynamic> json) =>
    _$TilesetConfigImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      tileSize: (json['tileSize'] as num).toInt(),
      tileProperties: (json['tileProperties'] as List<dynamic>?)
              ?.map((e) => TileProperties.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TilesetConfigImplToJson(_$TilesetConfigImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
      'tileSize': instance.tileSize,
      'tileProperties': instance.tileProperties,
    };

_$TilePropertiesImpl _$$TilePropertiesImplFromJson(Map<String, dynamic> json) =>
    _$TilePropertiesImpl(
      id: (json['id'] as num).toInt(),
      customProperties:
          json['customProperties'] as Map<String, dynamic>? ?? const {},
      isPassable: json['isPassable'] as bool? ?? false,
    );

Map<String, dynamic> _$$TilePropertiesImplToJson(
        _$TilePropertiesImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customProperties': instance.customProperties,
      'isPassable': instance.isPassable,
    };
