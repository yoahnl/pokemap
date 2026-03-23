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

_$TerrainLayerImpl _$$TerrainLayerImplFromJson(Map<String, dynamic> json) =>
    _$TerrainLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      terrains: (json['terrains'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$TerrainTypeEnumMap, e))
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TerrainLayerImplToJson(_$TerrainLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'terrains':
          instance.terrains.map((e) => _$TerrainTypeEnumMap[e]!).toList(),
      'runtimeType': instance.$type,
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

_$PathLayerImpl _$$PathLayerImplFromJson(Map<String, dynamic> json) =>
    _$PathLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      presetId: json['presetId'] as String? ?? '',
      cells:
          (json['cells'] as List<dynamic>?)?.map((e) => e as bool).toList() ??
              const [],
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PathLayerImplToJson(_$PathLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isVisible': instance.isVisible,
      'opacity': instance.opacity,
      'presetId': instance.presetId,
      'cells': instance.cells,
      'properties': instance.properties,
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
