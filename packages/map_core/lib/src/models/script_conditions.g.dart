// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'script_conditions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScriptConditionImpl _$$ScriptConditionImplFromJson(
        Map<String, dynamic> json) =>
    _$ScriptConditionImpl(
      type: $enumDecode(_$ScriptConditionTypeEnumMap, json['type']),
      params: (json['params'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => ScriptCondition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ScriptConditionImplToJson(
        _$ScriptConditionImpl instance) =>
    <String, dynamic>{
      'type': _$ScriptConditionTypeEnumMap[instance.type]!,
      'params': instance.params,
      'children': instance.children.map((e) => e.toJson()).toList(),
    };

const _$ScriptConditionTypeEnumMap = {
  ScriptConditionType.allOf: 'allOf',
  ScriptConditionType.anyOf: 'anyOf',
  ScriptConditionType.not: 'not',
  ScriptConditionType.flagIsSet: 'flagIsSet',
  ScriptConditionType.flagIsUnset: 'flagIsUnset',
  ScriptConditionType.variableEquals: 'variableEquals',
  ScriptConditionType.variableGreaterThan: 'variableGreaterThan',
  ScriptConditionType.variableLessThan: 'variableLessThan',
  ScriptConditionType.fieldAbilityUnlocked: 'fieldAbilityUnlocked',
  ScriptConditionType.partyHasMove: 'partyHasMove',
  ScriptConditionType.partyHasUsableMove: 'partyHasUsableMove',
  ScriptConditionType.eventIsConsumed: 'eventIsConsumed',
  ScriptConditionType.playerOnMap: 'playerOnMap',
};
