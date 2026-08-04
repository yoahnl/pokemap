// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_tileset_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VisualTilePropertyImpl _$$VisualTilePropertyImplFromJson(
        Map<String, dynamic> json) =>
    _$VisualTilePropertyImpl(
      tileId: (json['tileId'] as num).toInt(),
      passable: json['passable'] as bool? ?? true,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
    );

Map<String, dynamic> _$$VisualTilePropertyImplToJson(
        _$VisualTilePropertyImpl instance) =>
    <String, dynamic>{
      'tileId': instance.tileId,
      'passable': instance.passable,
      'tags': instance.tags,
    };
