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
