// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MapDataImpl _$$MapDataImplFromJson(Map<String, dynamic> json) =>
    _$MapDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      size: GridSize.fromJson(json['size'] as Map<String, dynamic>),
      version: $enumDecodeNullable(_$ProjectVersionEnumMap, json['version']) ??
          ProjectVersion.v1,
      tilesetId: json['tilesetId'] as String? ?? '',
      layers: (json['layers'] as List<dynamic>?)
              ?.map((e) => MapLayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      entities: (json['entities'] as List<dynamic>?)
              ?.map((e) => MapEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      connections: (json['connections'] as List<dynamic>?)
              ?.map((e) => MapConnection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      warps: (json['warps'] as List<dynamic>?)
              ?.map((e) => MapWarp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => MapTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$MapDataImplToJson(_$MapDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size.toJson(),
      'version': _$ProjectVersionEnumMap[instance.version]!,
      'tilesetId': instance.tilesetId,
      'layers': instance.layers.map((e) => e.toJson()).toList(),
      'entities': instance.entities.map((e) => e.toJson()).toList(),
      'connections': instance.connections.map((e) => e.toJson()).toList(),
      'warps': instance.warps.map((e) => e.toJson()).toList(),
      'triggers': instance.triggers.map((e) => e.toJson()).toList(),
      'properties': instance.properties,
    };

const _$ProjectVersionEnumMap = {
  ProjectVersion.v1: 'v1',
};

_$MapEntityImpl _$$MapEntityImplFromJson(Map<String, dynamic> json) =>
    _$MapEntityImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      kind: $enumDecode(_$MapEntityKindEnumMap, json['kind']),
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      size: json['size'] == null
          ? const GridSize(width: 1, height: 1)
          : GridSize.fromJson(json['size'] as Map<String, dynamic>),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapEntityImplToJson(_$MapEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': _$MapEntityKindEnumMap[instance.kind]!,
      'pos': instance.pos.toJson(),
      'size': instance.size.toJson(),
      'properties': instance.properties,
    };

const _$MapEntityKindEnumMap = {
  MapEntityKind.npc: 'npc',
  MapEntityKind.sign: 'sign',
  MapEntityKind.item: 'item',
  MapEntityKind.spawn: 'spawn',
  MapEntityKind.custom: 'custom',
};

_$MapWarpImpl _$$MapWarpImplFromJson(Map<String, dynamic> json) =>
    _$MapWarpImpl(
      id: json['id'] as String,
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      targetMapId: json['targetMapId'] as String,
      targetPos: GridPos.fromJson(json['targetPos'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapWarpImplToJson(_$MapWarpImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pos': instance.pos.toJson(),
      'targetMapId': instance.targetMapId,
      'targetPos': instance.targetPos.toJson(),
    };

_$MapConnectionImpl _$$MapConnectionImplFromJson(Map<String, dynamic> json) =>
    _$MapConnectionImpl(
      direction:
          $enumDecode(_$MapConnectionDirectionEnumMap, json['direction']),
      targetMapId: json['targetMapId'] as String,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MapConnectionImplToJson(_$MapConnectionImpl instance) =>
    <String, dynamic>{
      'direction': _$MapConnectionDirectionEnumMap[instance.direction]!,
      'targetMapId': instance.targetMapId,
      'offset': instance.offset,
    };

const _$MapConnectionDirectionEnumMap = {
  MapConnectionDirection.north: 'north',
  MapConnectionDirection.south: 'south',
  MapConnectionDirection.east: 'east',
  MapConnectionDirection.west: 'west',
};

_$MapTriggerImpl _$$MapTriggerImplFromJson(Map<String, dynamic> json) =>
    _$MapTriggerImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: $enumDecode(_$TriggerTypeEnumMap, json['type']),
      area: MapRect.fromJson(json['area'] as Map<String, dynamic>),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapTriggerImplToJson(_$MapTriggerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$TriggerTypeEnumMap[instance.type]!,
      'area': instance.area.toJson(),
      'properties': instance.properties,
    };

const _$TriggerTypeEnumMap = {
  TriggerType.warp: 'warp',
  TriggerType.message: 'message',
  TriggerType.interaction: 'interaction',
  TriggerType.event: 'event',
  TriggerType.spawn: 'spawn',
  TriggerType.camera: 'camera',
  TriggerType.custom: 'custom',
};
