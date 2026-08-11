// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_item_capabilities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectItemUseDefinition _$ProjectItemUseDefinitionFromJson(
  Map<String, dynamic> json,
) => _ProjectItemUseDefinition(
  contexts: (json['contexts'] as List<dynamic>)
      .map((e) => $enumDecode(_$ProjectItemUseContextEnumMap, e))
      .toSet(),
  target: $enumDecode(_$ProjectItemTargetKindEnumMap, json['target']),
  consumption: $enumDecode(
    _$ProjectItemConsumptionPolicyEnumMap,
    json['consumption'],
  ),
  effect: ProjectItemEffectDefinition.fromJson(
    json['effect'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProjectItemUseDefinitionToJson(
  _ProjectItemUseDefinition instance,
) => <String, dynamic>{
  'contexts': instance.contexts
      .map((e) => _$ProjectItemUseContextEnumMap[e]!)
      .toList(),
  'target': _$ProjectItemTargetKindEnumMap[instance.target]!,
  'consumption': _$ProjectItemConsumptionPolicyEnumMap[instance.consumption]!,
  'effect': instance.effect.toJson(),
};

const _$ProjectItemUseContextEnumMap = {
  ProjectItemUseContext.overworld: 'overworld',
  ProjectItemUseContext.battle: 'battle',
};

const _$ProjectItemTargetKindEnumMap = {
  ProjectItemTargetKind.partyMember: 'party_member',
  ProjectItemTargetKind.partyMove: 'party_move',
  ProjectItemTargetKind.world: 'world',
  ProjectItemTargetKind.none: 'none',
};

const _$ProjectItemConsumptionPolicyEnumMap = {
  ProjectItemConsumptionPolicy.onApplied: 'on_applied',
  ProjectItemConsumptionPolicy.never: 'never',
};

_ProjectCaptureItemDefinition _$ProjectCaptureItemDefinitionFromJson(
  Map<String, dynamic> json,
) => _ProjectCaptureItemDefinition(
  rateNumerator: (json['rateNumerator'] as num).toInt(),
  rateDenominator: (json['rateDenominator'] as num).toInt(),
  allowedEncounterKinds: (json['allowedEncounterKinds'] as List<dynamic>)
      .map((e) => $enumDecode(_$EncounterKindEnumMap, e))
      .toSet(),
);

Map<String, dynamic> _$ProjectCaptureItemDefinitionToJson(
  _ProjectCaptureItemDefinition instance,
) => <String, dynamic>{
  'rateNumerator': instance.rateNumerator,
  'rateDenominator': instance.rateDenominator,
  'allowedEncounterKinds': instance.allowedEncounterKinds
      .map((e) => _$EncounterKindEnumMap[e]!)
      .toList(),
};

const _$EncounterKindEnumMap = {
  EncounterKind.walk: 'walk',
  EncounterKind.surf: 'surf',
  EncounterKind.headbutt: 'headbutt',
  EncounterKind.oldRod: 'old_rod',
  EncounterKind.goodRod: 'good_rod',
  EncounterKind.superRod: 'super_rod',
  EncounterKind.gift: 'gift',
  EncounterKind.special: 'special',
};

_ProjectMoveMachineItemDefinition _$ProjectMoveMachineItemDefinitionFromJson(
  Map<String, dynamic> json,
) => _ProjectMoveMachineItemDefinition(
  moveId: json['moveId'] as String,
  kind: $enumDecode(_$ProjectMoveMachineKindEnumMap, json['kind']),
  consumable: json['consumable'] as bool,
);

Map<String, dynamic> _$ProjectMoveMachineItemDefinitionToJson(
  _ProjectMoveMachineItemDefinition instance,
) => <String, dynamic>{
  'moveId': instance.moveId,
  'kind': _$ProjectMoveMachineKindEnumMap[instance.kind]!,
  'consumable': instance.consumable,
};

const _$ProjectMoveMachineKindEnumMap = {
  ProjectMoveMachineKind.tm: 'tm',
  ProjectMoveMachineKind.hm: 'hm',
};
