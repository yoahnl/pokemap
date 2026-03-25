// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_entity_payloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DialogueRefImpl _$$DialogueRefImplFromJson(Map<String, dynamic> json) =>
    _$DialogueRefImpl(
      dialogueId: json['dialogueId'] as String,
      scriptPathRelative: json['scriptPathRelative'] as String? ?? '',
      startNode: json['startNode'] as String?,
    );

Map<String, dynamic> _$$DialogueRefImplToJson(_$DialogueRefImpl instance) =>
    <String, dynamic>{
      'dialogueId': instance.dialogueId,
      'scriptPathRelative': instance.scriptPathRelative,
      'startNode': instance.startNode,
    };

_$MapEntityNpcDataImpl _$$MapEntityNpcDataImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEntityNpcDataImpl(
      displayName: json['displayName'] as String? ?? '',
      dialogue: json['dialogue'] == null
          ? null
          : DialogueRef.fromJson(json['dialogue'] as Map<String, dynamic>),
      facing: $enumDecodeNullable(_$EntityFacingEnumMap, json['facing']) ??
          EntityFacing.south,
      visualElementId: json['visualElementId'] as String? ?? '',
    );

Map<String, dynamic> _$$MapEntityNpcDataImplToJson(
        _$MapEntityNpcDataImpl instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'dialogue': instance.dialogue?.toJson(),
      'facing': _$EntityFacingEnumMap[instance.facing]!,
      'visualElementId': instance.visualElementId,
    };

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

_$MapEntitySignDataImpl _$$MapEntitySignDataImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEntitySignDataImpl(
      title: json['title'] as String? ?? '',
      dialogue: json['dialogue'] == null
          ? null
          : DialogueRef.fromJson(json['dialogue'] as Map<String, dynamic>),
      plainText: json['plainText'] as String? ?? '',
    );

Map<String, dynamic> _$$MapEntitySignDataImplToJson(
        _$MapEntitySignDataImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'dialogue': instance.dialogue?.toJson(),
      'plainText': instance.plainText,
    };

_$MapEntityItemDataImpl _$$MapEntityItemDataImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEntityItemDataImpl(
      gameItemId: json['gameItemId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      pickupMode:
          $enumDecodeNullable(_$ItemPickupModeEnumMap, json['pickupMode']) ??
              ItemPickupMode.once,
      respawnPolicy: $enumDecodeNullable(
              _$ItemRespawnPolicyEnumMap, json['respawnPolicy']) ??
          ItemRespawnPolicy.none,
    );

Map<String, dynamic> _$$MapEntityItemDataImplToJson(
        _$MapEntityItemDataImpl instance) =>
    <String, dynamic>{
      'gameItemId': instance.gameItemId,
      'quantity': instance.quantity,
      'pickupMode': _$ItemPickupModeEnumMap[instance.pickupMode]!,
      'respawnPolicy': _$ItemRespawnPolicyEnumMap[instance.respawnPolicy]!,
    };

const _$ItemPickupModeEnumMap = {
  ItemPickupMode.once: 'once',
  ItemPickupMode.always: 'always',
  ItemPickupMode.questGated: 'quest_gated',
};

const _$ItemRespawnPolicyEnumMap = {
  ItemRespawnPolicy.none: 'none',
  ItemRespawnPolicy.onMapReload: 'on_map_reload',
  ItemRespawnPolicy.timed: 'timed',
};

_$MapEntitySpawnDataImpl _$$MapEntitySpawnDataImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEntitySpawnDataImpl(
      spawnKey: json['spawnKey'] as String? ?? '',
      role: $enumDecodeNullable(_$EntitySpawnRoleEnumMap, json['role']) ??
          EntitySpawnRole.playerStart,
      facing: $enumDecodeNullable(_$EntityFacingEnumMap, json['facing']) ??
          EntityFacing.south,
      categoryTag: json['categoryTag'] as String? ?? '',
    );

Map<String, dynamic> _$$MapEntitySpawnDataImplToJson(
        _$MapEntitySpawnDataImpl instance) =>
    <String, dynamic>{
      'spawnKey': instance.spawnKey,
      'role': _$EntitySpawnRoleEnumMap[instance.role]!,
      'facing': _$EntityFacingEnumMap[instance.facing]!,
      'categoryTag': instance.categoryTag,
    };

const _$EntitySpawnRoleEnumMap = {
  EntitySpawnRole.playerStart: 'player_start',
  EntitySpawnRole.event: 'event',
  EntitySpawnRole.npcSpawn: 'npc_spawn',
  EntitySpawnRole.debug: 'debug',
  EntitySpawnRole.other: 'other',
};
