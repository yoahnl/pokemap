// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_item_effect_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectItemHealHpEffectDefinition _$ProjectItemHealHpEffectDefinitionFromJson(
  Map<String, dynamic> json,
) => ProjectItemHealHpEffectDefinition(
  mode: $enumDecode(_$ProjectItemAmountModeEnumMap, json['mode']),
  amount: (json['amount'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$ProjectItemHealHpEffectDefinitionToJson(
  ProjectItemHealHpEffectDefinition instance,
) => <String, dynamic>{
  'mode': _$ProjectItemAmountModeEnumMap[instance.mode]!,
  'amount': instance.amount,
  'kind': instance.$type,
};

const _$ProjectItemAmountModeEnumMap = {
  ProjectItemAmountMode.flat: 'flat',
  ProjectItemAmountMode.full: 'full',
};

ProjectItemFullRestoreEffectDefinition
_$ProjectItemFullRestoreEffectDefinitionFromJson(Map<String, dynamic> json) {
  $checkKeys(json, allowedKeys: const ['kind']);
  return ProjectItemFullRestoreEffectDefinition($type: json['kind'] as String?);
}

Map<String, dynamic> _$ProjectItemFullRestoreEffectDefinitionToJson(
  ProjectItemFullRestoreEffectDefinition instance,
) => <String, dynamic>{'kind': instance.$type};

ProjectItemVitaminEffectDefinition _$ProjectItemVitaminEffectDefinitionFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    allowedKeys: const [
      'stat',
      'amount',
      'maximumPerStat',
      'maximumTotal',
      'friendshipGainLow',
      'friendshipGainMedium',
      'friendshipGainHigh',
      'kind',
    ],
  );
  return ProjectItemVitaminEffectDefinition(
    stat: $enumDecode(_$ProjectItemVitaminStatEnumMap, json['stat']),
    amount: _itemEffectInteger(json['amount']),
    maximumPerStat: _itemEffectInteger(json['maximumPerStat']),
    maximumTotal: json['maximumTotal'] == null
        ? 510
        : _itemEffectInteger(json['maximumTotal']),
    friendshipGainLow: json['friendshipGainLow'] == null
        ? 0
        : _itemEffectInteger(json['friendshipGainLow']),
    friendshipGainMedium: json['friendshipGainMedium'] == null
        ? 0
        : _itemEffectInteger(json['friendshipGainMedium']),
    friendshipGainHigh: json['friendshipGainHigh'] == null
        ? 0
        : _itemEffectInteger(json['friendshipGainHigh']),
    $type: json['kind'] as String?,
  );
}

Map<String, dynamic> _$ProjectItemVitaminEffectDefinitionToJson(
  ProjectItemVitaminEffectDefinition instance,
) => <String, dynamic>{
  'stat': _$ProjectItemVitaminStatEnumMap[instance.stat]!,
  'amount': instance.amount,
  'maximumPerStat': instance.maximumPerStat,
  'maximumTotal': instance.maximumTotal,
  'friendshipGainLow': instance.friendshipGainLow,
  'friendshipGainMedium': instance.friendshipGainMedium,
  'friendshipGainHigh': instance.friendshipGainHigh,
  'kind': instance.$type,
};

const _$ProjectItemVitaminStatEnumMap = {
  ProjectItemVitaminStat.hp: 'hp',
  ProjectItemVitaminStat.attack: 'attack',
  ProjectItemVitaminStat.defense: 'defense',
  ProjectItemVitaminStat.specialAttack: 'specialAttack',
  ProjectItemVitaminStat.specialDefense: 'specialDefense',
  ProjectItemVitaminStat.speed: 'speed',
};

ProjectItemBattleBoostEffectDefinition
_$ProjectItemBattleBoostEffectDefinitionFromJson(Map<String, dynamic> json) {
  $checkKeys(json, allowedKeys: const ['stat', 'stages', 'kind']);
  return ProjectItemBattleBoostEffectDefinition(
    stat: $enumDecode(_$ProjectItemBattleStatEnumMap, json['stat']),
    stages: _itemEffectInteger(json['stages']),
    $type: json['kind'] as String?,
  );
}

Map<String, dynamic> _$ProjectItemBattleBoostEffectDefinitionToJson(
  ProjectItemBattleBoostEffectDefinition instance,
) => <String, dynamic>{
  'stat': _$ProjectItemBattleStatEnumMap[instance.stat]!,
  'stages': instance.stages,
  'kind': instance.$type,
};

const _$ProjectItemBattleStatEnumMap = {
  ProjectItemBattleStat.attack: 'attack',
  ProjectItemBattleStat.defense: 'defense',
  ProjectItemBattleStat.specialAttack: 'specialAttack',
  ProjectItemBattleStat.specialDefense: 'specialDefense',
  ProjectItemBattleStat.speed: 'speed',
  ProjectItemBattleStat.accuracy: 'accuracy',
};

ProjectItemBattlePreparationEffectDefinition
_$ProjectItemBattlePreparationEffectDefinitionFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(json, allowedKeys: const ['effect', 'turns', 'kind']);
  return ProjectItemBattlePreparationEffectDefinition(
    effect: $enumDecode(
      _$ProjectItemBattlePreparationKindEnumMap,
      json['effect'],
    ),
    turns: _itemEffectNullableInteger(json['turns']),
    $type: json['kind'] as String?,
  );
}

Map<String, dynamic> _$ProjectItemBattlePreparationEffectDefinitionToJson(
  ProjectItemBattlePreparationEffectDefinition instance,
) => <String, dynamic>{
  'effect': _$ProjectItemBattlePreparationKindEnumMap[instance.effect]!,
  'turns': instance.turns,
  'kind': instance.$type,
};

const _$ProjectItemBattlePreparationKindEnumMap = {
  ProjectItemBattlePreparationKind.focusEnergy: 'focusEnergy',
  ProjectItemBattlePreparationKind.mist: 'mist',
};

ProjectItemCureStatusEffectDefinition
_$ProjectItemCureStatusEffectDefinitionFromJson(Map<String, dynamic> json) =>
    ProjectItemCureStatusEffectDefinition(
      mode: $enumDecode(_$ProjectItemStatusCureModeEnumMap, json['mode']),
      statusIds:
          (json['statusIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$ProjectItemCureStatusEffectDefinitionToJson(
  ProjectItemCureStatusEffectDefinition instance,
) => <String, dynamic>{
  'mode': _$ProjectItemStatusCureModeEnumMap[instance.mode]!,
  'statusIds': instance.statusIds.toList(),
  'kind': instance.$type,
};

const _$ProjectItemStatusCureModeEnumMap = {
  ProjectItemStatusCureMode.listed: 'listed',
  ProjectItemStatusCureMode.all: 'all',
};

ProjectItemReviveEffectDefinition _$ProjectItemReviveEffectDefinitionFromJson(
  Map<String, dynamic> json,
) => ProjectItemReviveEffectDefinition(
  rateNumerator: (json['rateNumerator'] as num).toInt(),
  rateDenominator: (json['rateDenominator'] as num).toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$ProjectItemReviveEffectDefinitionToJson(
  ProjectItemReviveEffectDefinition instance,
) => <String, dynamic>{
  'rateNumerator': instance.rateNumerator,
  'rateDenominator': instance.rateDenominator,
  'kind': instance.$type,
};

ProjectItemRestorePpEffectDefinition
_$ProjectItemRestorePpEffectDefinitionFromJson(Map<String, dynamic> json) =>
    ProjectItemRestorePpEffectDefinition(
      mode: $enumDecode(_$ProjectItemAmountModeEnumMap, json['mode']),
      amount: (json['amount'] as num?)?.toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$ProjectItemRestorePpEffectDefinitionToJson(
  ProjectItemRestorePpEffectDefinition instance,
) => <String, dynamic>{
  'mode': _$ProjectItemAmountModeEnumMap[instance.mode]!,
  'amount': instance.amount,
  'kind': instance.$type,
};

ProjectItemRepelEffectDefinition _$ProjectItemRepelEffectDefinitionFromJson(
  Map<String, dynamic> json,
) => ProjectItemRepelEffectDefinition(
  steps: (json['steps'] as num).toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$ProjectItemRepelEffectDefinitionToJson(
  ProjectItemRepelEffectDefinition instance,
) => <String, dynamic>{'steps': instance.steps, 'kind': instance.$type};

ProjectItemFishingEffectDefinition _$ProjectItemFishingEffectDefinitionFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(json, allowedKeys: const ['rodKind', 'kind']);
  return ProjectItemFishingEffectDefinition(
    rodKind: $enumDecode(_$ProjectFishingRodKindEnumMap, json['rodKind']),
    $type: json['kind'] as String?,
  );
}

Map<String, dynamic> _$ProjectItemFishingEffectDefinitionToJson(
  ProjectItemFishingEffectDefinition instance,
) => <String, dynamic>{
  'rodKind': _$ProjectFishingRodKindEnumMap[instance.rodKind]!,
  'kind': instance.$type,
};

const _$ProjectFishingRodKindEnumMap = {
  ProjectFishingRodKind.oldRod: 'old_rod',
  ProjectFishingRodKind.goodRod: 'good_rod',
  ProjectFishingRodKind.superRod: 'super_rod',
};

ProjectItemBicycleEffectDefinition _$ProjectItemBicycleEffectDefinitionFromJson(
  Map<String, dynamic> json,
) => ProjectItemBicycleEffectDefinition($type: json['kind'] as String?);

Map<String, dynamic> _$ProjectItemBicycleEffectDefinitionToJson(
  ProjectItemBicycleEffectDefinition instance,
) => <String, dynamic>{'kind': instance.$type};

ProjectItemEscapeRopeEffectDefinition
_$ProjectItemEscapeRopeEffectDefinitionFromJson(Map<String, dynamic> json) =>
    ProjectItemEscapeRopeEffectDefinition($type: json['kind'] as String?);

Map<String, dynamic> _$ProjectItemEscapeRopeEffectDefinitionToJson(
  ProjectItemEscapeRopeEffectDefinition instance,
) => <String, dynamic>{'kind': instance.$type};

ProjectItemSemanticActionEffectDefinition
_$ProjectItemSemanticActionEffectDefinitionFromJson(
  Map<String, dynamic> json,
) => ProjectItemSemanticActionEffectDefinition(
  actionId: json['actionId'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$ProjectItemSemanticActionEffectDefinitionToJson(
  ProjectItemSemanticActionEffectDefinition instance,
) => <String, dynamic>{'actionId': instance.actionId, 'kind': instance.$type};
