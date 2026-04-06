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

_$MapEntityRuntimePredicateImpl _$$MapEntityRuntimePredicateImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEntityRuntimePredicateImpl(
      kind: $enumDecode(_$MapEntityRuntimePredicateKindEnumMap, json['kind']),
      refId: json['refId'] as String? ?? '',
    );

Map<String, dynamic> _$$MapEntityRuntimePredicateImplToJson(
        _$MapEntityRuntimePredicateImpl instance) =>
    <String, dynamic>{
      'kind': _$MapEntityRuntimePredicateKindEnumMap[instance.kind]!,
      'refId': instance.refId,
    };

const _$MapEntityRuntimePredicateKindEnumMap = {
  MapEntityRuntimePredicateKind.storyFlagSet: 'storyFlagSet',
  MapEntityRuntimePredicateKind.storyFlagUnset: 'storyFlagUnset',
  MapEntityRuntimePredicateKind.stepCompleted: 'stepCompleted',
  MapEntityRuntimePredicateKind.stepNotCompleted: 'stepNotCompleted',
  MapEntityRuntimePredicateKind.chapterCompleted: 'chapterCompleted',
  MapEntityRuntimePredicateKind.chapterNotCompleted: 'chapterNotCompleted',
  MapEntityRuntimePredicateKind.cutsceneCompleted: 'cutsceneCompleted',
  MapEntityRuntimePredicateKind.cutsceneNotCompleted: 'cutsceneNotCompleted',
};

_$MapEntityNpcVisibilityRuleImpl _$$MapEntityNpcVisibilityRuleImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEntityNpcVisibilityRuleImpl(
      mode: $enumDecode(_$MapEntityNpcVisibilityModeEnumMap, json['mode']),
      predicate: json['predicate'] == null
          ? null
          : MapEntityRuntimePredicate.fromJson(
              json['predicate'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapEntityNpcVisibilityRuleImplToJson(
        _$MapEntityNpcVisibilityRuleImpl instance) =>
    <String, dynamic>{
      'mode': _$MapEntityNpcVisibilityModeEnumMap[instance.mode]!,
      'predicate': instance.predicate?.toJson(),
    };

const _$MapEntityNpcVisibilityModeEnumMap = {
  MapEntityNpcVisibilityMode.always: 'always',
  MapEntityNpcVisibilityMode.visibleWhen: 'visibleWhen',
  MapEntityNpcVisibilityMode.hiddenWhen: 'hiddenWhen',
};

_$MapEntityConditionalDialogueImpl _$$MapEntityConditionalDialogueImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEntityConditionalDialogueImpl(
      when: MapEntityRuntimePredicate.fromJson(
          json['when'] as Map<String, dynamic>),
      dialogue: DialogueRef.fromJson(json['dialogue'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapEntityConditionalDialogueImplToJson(
        _$MapEntityConditionalDialogueImpl instance) =>
    <String, dynamic>{
      'when': instance.when.toJson(),
      'dialogue': instance.dialogue.toJson(),
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
      trainerId: json['trainerId'] as String?,
      lineOfSightRange: (json['lineOfSightRange'] as num?)?.toInt() ?? 0,
      defeatDialogueRef: json['defeatDialogueRef'] == null
          ? null
          : DialogueRef.fromJson(
              json['defeatDialogueRef'] as Map<String, dynamic>),
      characterId: json['characterId'] as String?,
      movement: json['movement'] == null
          ? const MapEntityNpcMovementConfig()
          : MapEntityNpcMovementConfig.fromJson(
              json['movement'] as Map<String, dynamic>),
      visibilityRule: json['visibilityRule'] == null
          ? null
          : MapEntityNpcVisibilityRule.fromJson(
              json['visibilityRule'] as Map<String, dynamic>),
      conditionalDialogues: (json['conditionalDialogues'] as List<dynamic>?)
              ?.map((e) => MapEntityConditionalDialogue.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const <MapEntityConditionalDialogue>[],
    );

Map<String, dynamic> _$$MapEntityNpcDataImplToJson(
        _$MapEntityNpcDataImpl instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'dialogue': instance.dialogue?.toJson(),
      'facing': _$EntityFacingEnumMap[instance.facing]!,
      'visualElementId': instance.visualElementId,
      'trainerId': instance.trainerId,
      'lineOfSightRange': instance.lineOfSightRange,
      'defeatDialogueRef': instance.defeatDialogueRef?.toJson(),
      'characterId': instance.characterId,
      'movement': instance.movement.toJson(),
      'visibilityRule': instance.visibilityRule?.toJson(),
      'conditionalDialogues':
          instance.conditionalDialogues.map((e) => e.toJson()).toList(),
    };

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

_$MapEntityNpcMovementConfigImpl _$$MapEntityNpcMovementConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$MapEntityNpcMovementConfigImpl(
      mode: $enumDecodeNullable(
              _$MapEntityNpcMovementModeEnumMap, json['mode']) ??
          MapEntityNpcMovementMode.idle,
      waypoints: (json['waypoints'] as List<dynamic>?)
              ?.map((e) => GridPos.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <GridPos>[],
      loop: json['loop'] as bool? ?? true,
      pauseDurationMs: (json['pauseDurationMs'] as num?)?.toInt() ?? 0,
      stepDurationMs: (json['stepDurationMs'] as num?)?.toInt() ?? 200,
    );

Map<String, dynamic> _$$MapEntityNpcMovementConfigImplToJson(
        _$MapEntityNpcMovementConfigImpl instance) =>
    <String, dynamic>{
      'mode': _$MapEntityNpcMovementModeEnumMap[instance.mode]!,
      'waypoints': instance.waypoints.map((e) => e.toJson()).toList(),
      'loop': instance.loop,
      'pauseDurationMs': instance.pauseDurationMs,
      'stepDurationMs': instance.stepDurationMs,
    };

const _$MapEntityNpcMovementModeEnumMap = {
  MapEntityNpcMovementMode.idle: 'idle',
  MapEntityNpcMovementMode.patrol: 'patrol',
  MapEntityNpcMovementMode.scriptedOnly: 'scriptedOnly',
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
