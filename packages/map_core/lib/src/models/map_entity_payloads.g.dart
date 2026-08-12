// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_entity_payloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DialogueRef _$DialogueRefFromJson(Map<String, dynamic> json) => _DialogueRef(
  dialogueId: json['dialogueId'] as String,
  scriptPathRelative: json['scriptPathRelative'] as String? ?? '',
  startNode: json['startNode'] as String?,
);

Map<String, dynamic> _$DialogueRefToJson(_DialogueRef instance) =>
    <String, dynamic>{
      'dialogueId': instance.dialogueId,
      'scriptPathRelative': instance.scriptPathRelative,
      'startNode': instance.startNode,
    };

_MapEntityRuntimePredicate _$MapEntityRuntimePredicateFromJson(
  Map<String, dynamic> json,
) => _MapEntityRuntimePredicate(
  kind: $enumDecode(_$MapEntityRuntimePredicateKindEnumMap, json['kind']),
  refId: json['refId'] as String? ?? '',
);

Map<String, dynamic> _$MapEntityRuntimePredicateToJson(
  _MapEntityRuntimePredicate instance,
) => <String, dynamic>{
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

_MapEntityNpcVisibilityRule _$MapEntityNpcVisibilityRuleFromJson(
  Map<String, dynamic> json,
) => _MapEntityNpcVisibilityRule(
  mode: $enumDecode(_$MapEntityNpcVisibilityModeEnumMap, json['mode']),
  predicate: json['predicate'] == null
      ? null
      : MapEntityRuntimePredicate.fromJson(
          json['predicate'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MapEntityNpcVisibilityRuleToJson(
  _MapEntityNpcVisibilityRule instance,
) => <String, dynamic>{
  'mode': _$MapEntityNpcVisibilityModeEnumMap[instance.mode]!,
  'predicate': instance.predicate?.toJson(),
};

const _$MapEntityNpcVisibilityModeEnumMap = {
  MapEntityNpcVisibilityMode.always: 'always',
  MapEntityNpcVisibilityMode.visibleWhen: 'visibleWhen',
  MapEntityNpcVisibilityMode.hiddenWhen: 'hiddenWhen',
};

_MapEntityConditionalDialogue _$MapEntityConditionalDialogueFromJson(
  Map<String, dynamic> json,
) => _MapEntityConditionalDialogue(
  when: MapEntityRuntimePredicate.fromJson(
    json['when'] as Map<String, dynamic>,
  ),
  dialogue: DialogueRef.fromJson(json['dialogue'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MapEntityConditionalDialogueToJson(
  _MapEntityConditionalDialogue instance,
) => <String, dynamic>{
  'when': instance.when.toJson(),
  'dialogue': instance.dialogue.toJson(),
};

_MapEntityNpcData _$MapEntityNpcDataFromJson(Map<String, dynamic> json) =>
    _MapEntityNpcData(
      displayName: json['displayName'] as String? ?? '',
      dialogue: json['dialogue'] == null
          ? null
          : DialogueRef.fromJson(json['dialogue'] as Map<String, dynamic>),
      facing:
          $enumDecodeNullable(_$EntityFacingEnumMap, json['facing']) ??
          EntityFacing.south,
      visualElementId: json['visualElementId'] as String? ?? '',
      trainerId: json['trainerId'] as String?,
      lineOfSightRange: (json['lineOfSightRange'] as num?)?.toInt() ?? 0,
      defeatDialogueRef: json['defeatDialogueRef'] == null
          ? null
          : DialogueRef.fromJson(
              json['defeatDialogueRef'] as Map<String, dynamic>,
            ),
      characterId: json['characterId'] as String?,
      movement: json['movement'] == null
          ? const MapEntityNpcMovementConfig()
          : MapEntityNpcMovementConfig.fromJson(
              json['movement'] as Map<String, dynamic>,
            ),
      visibilityRule: json['visibilityRule'] == null
          ? null
          : MapEntityNpcVisibilityRule.fromJson(
              json['visibilityRule'] as Map<String, dynamic>,
            ),
      conditionalDialogues:
          (json['conditionalDialogues'] as List<dynamic>?)
              ?.map(
                (e) => MapEntityConditionalDialogue.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <MapEntityConditionalDialogue>[],
    );

Map<String, dynamic> _$MapEntityNpcDataToJson(_MapEntityNpcData instance) =>
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
      'conditionalDialogues': instance.conditionalDialogues
          .map((e) => e.toJson())
          .toList(),
    };

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

_MapEntityNpcMovementConfig _$MapEntityNpcMovementConfigFromJson(
  Map<String, dynamic> json,
) => _MapEntityNpcMovementConfig(
  mode:
      $enumDecodeNullable(_$MapEntityNpcMovementModeEnumMap, json['mode']) ??
      MapEntityNpcMovementMode.idle,
  waypoints:
      (json['waypoints'] as List<dynamic>?)
          ?.map((e) => GridPos.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GridPos>[],
  loop: json['loop'] as bool? ?? true,
  pauseDurationMs: (json['pauseDurationMs'] as num?)?.toInt() ?? 0,
  stepDurationMs: (json['stepDurationMs'] as num?)?.toInt() ?? 200,
);

Map<String, dynamic> _$MapEntityNpcMovementConfigToJson(
  _MapEntityNpcMovementConfig instance,
) => <String, dynamic>{
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

_MapEntitySignData _$MapEntitySignDataFromJson(Map<String, dynamic> json) =>
    _MapEntitySignData(
      title: json['title'] as String? ?? '',
      dialogue: json['dialogue'] == null
          ? null
          : DialogueRef.fromJson(json['dialogue'] as Map<String, dynamic>),
      plainText: json['plainText'] as String? ?? '',
    );

Map<String, dynamic> _$MapEntitySignDataToJson(_MapEntitySignData instance) =>
    <String, dynamic>{
      'title': instance.title,
      'dialogue': instance.dialogue?.toJson(),
      'plainText': instance.plainText,
    };

_MapEntityItemData _$MapEntityItemDataFromJson(Map<String, dynamic> json) =>
    _MapEntityItemData(
      gameItemId: json['gameItemId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      pickupMode:
          $enumDecodeNullable(_$ItemPickupModeEnumMap, json['pickupMode']) ??
          ItemPickupMode.once,
      respawnPolicy:
          $enumDecodeNullable(
            _$ItemRespawnPolicyEnumMap,
            json['respawnPolicy'],
          ) ??
          ItemRespawnPolicy.none,
      visibility:
          $enumDecodeNullable(
            _$MapEntityItemVisibilityEnumMap,
            json['visibility'],
          ) ??
          MapEntityItemVisibility.visible,
    );

Map<String, dynamic> _$MapEntityItemDataToJson(_MapEntityItemData instance) =>
    <String, dynamic>{
      'gameItemId': instance.gameItemId,
      'quantity': instance.quantity,
      'pickupMode': _$ItemPickupModeEnumMap[instance.pickupMode]!,
      'respawnPolicy': _$ItemRespawnPolicyEnumMap[instance.respawnPolicy]!,
      'visibility': _$MapEntityItemVisibilityEnumMap[instance.visibility]!,
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

const _$MapEntityItemVisibilityEnumMap = {
  MapEntityItemVisibility.visible: 'visible',
  MapEntityItemVisibility.hidden: 'hidden',
};

_MapEntitySpawnData _$MapEntitySpawnDataFromJson(Map<String, dynamic> json) =>
    _MapEntitySpawnData(
      spawnKey: json['spawnKey'] as String? ?? '',
      role:
          $enumDecodeNullable(_$EntitySpawnRoleEnumMap, json['role']) ??
          EntitySpawnRole.playerStart,
      facing:
          $enumDecodeNullable(_$EntityFacingEnumMap, json['facing']) ??
          EntityFacing.south,
      categoryTag: json['categoryTag'] as String? ?? '',
    );

Map<String, dynamic> _$MapEntitySpawnDataToJson(_MapEntitySpawnData instance) =>
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
