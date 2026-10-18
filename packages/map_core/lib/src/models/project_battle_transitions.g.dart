// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_battle_transitions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectBattleTransitionConfig _$ProjectBattleTransitionConfigFromJson(
  Map<String, dynamic> json,
) => _ProjectBattleTransitionConfig(
  wildTransitionId: json['wildTransitionId'] as String?,
  trainerTransitionId: json['trainerTransitionId'] as String?,
  definitions:
      (json['definitions'] as List<dynamic>?)
          ?.map(BattleTransitionDefinition.fromJson)
          .toList() ??
      const <BattleTransitionDefinition>[],
);

Map<String, dynamic> _$ProjectBattleTransitionConfigToJson(
  _ProjectBattleTransitionConfig instance,
) => <String, dynamic>{
  'wildTransitionId': ?instance.wildTransitionId,
  'trainerTransitionId': ?instance.trainerTransitionId,
  'definitions': instance.definitions.map((e) => e.toJson()).toList(),
};
