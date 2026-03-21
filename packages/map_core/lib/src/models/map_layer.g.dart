// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TileLayerImpl _$$TileLayerImplFromJson(Map<String, dynamic> json) =>
    _$TileLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
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
