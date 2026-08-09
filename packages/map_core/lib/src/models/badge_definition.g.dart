// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BadgeDefinition _$BadgeDefinitionFromJson(Map<String, dynamic> json) =>
    _BadgeDefinition(
      id: json['id'] as String,
      label: json['label'] as String,
      iconRelativePath: json['iconRelativePath'] as String?,
      fieldAbilityUnlock: $enumDecodeNullable(
        _$FieldAbilityEnumMap,
        json['fieldAbilityUnlock'],
      ),
    );

Map<String, dynamic> _$BadgeDefinitionToJson(_BadgeDefinition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'iconRelativePath': instance.iconRelativePath,
      'fieldAbilityUnlock': _$FieldAbilityEnumMap[instance.fieldAbilityUnlock],
    };

const _$FieldAbilityEnumMap = {
  FieldAbility.surf: 'surf',
  FieldAbility.cut: 'cut',
  FieldAbility.strength: 'strength',
  FieldAbility.flash: 'flash',
  FieldAbility.rockSmash: 'rock_smash',
  FieldAbility.waterfall: 'waterfall',
  FieldAbility.dive: 'dive',
};
