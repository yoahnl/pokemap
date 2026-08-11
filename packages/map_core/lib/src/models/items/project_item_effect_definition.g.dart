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
