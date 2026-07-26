// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_trainer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectTrainerItemGrantImpl _$$ProjectTrainerItemGrantImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTrainerItemGrantImpl(
      itemId: json['itemId'] as String,
      quantity: json['quantity'] == null
          ? 1
          : _projectTrainerItemQuantityFromJson(json['quantity']),
    );

Map<String, dynamic> _$$ProjectTrainerItemGrantImplToJson(
        _$ProjectTrainerItemGrantImpl instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'quantity': instance.quantity,
    };

_$ProjectTrainerPokemonEntryImpl _$$ProjectTrainerPokemonEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTrainerPokemonEntryImpl(
      speciesId: json['speciesId'] as String,
      level: (json['level'] as num).toInt(),
      moves:
          (json['moves'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      heldItemId: json['heldItemId'] as String?,
      formId: json['formId'] as String?,
      gender: json['gender'] as String?,
      shiny: json['shiny'] as bool? ?? false,
    );

Map<String, dynamic> _$$ProjectTrainerPokemonEntryImplToJson(
        _$ProjectTrainerPokemonEntryImpl instance) =>
    <String, dynamic>{
      'speciesId': instance.speciesId,
      'level': instance.level,
      'moves': instance.moves,
      'heldItemId': instance.heldItemId,
      'formId': instance.formId,
      'gender': instance.gender,
      'shiny': instance.shiny,
    };

_$ProjectTrainerEntryImpl _$$ProjectTrainerEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTrainerEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      trainerClass: json['trainerClass'] as String,
      battleDifficulty: (json['battleDifficulty'] as num?)?.toInt(),
      battleBackgroundRelativePath:
          json['battleBackgroundRelativePath'] as String?,
      characterId: json['characterId'] as String?,
      portraitElementId: json['portraitElementId'] as String?,
      battleThemeId: json['battleThemeId'] as String?,
      victoryThemeId: json['victoryThemeId'] as String?,
      moneyReward: json['moneyReward'] == null
          ? 0
          : _projectTrainerMoneyRewardFromJson(json['moneyReward']),
      rewardItemGrants: (json['rewardItemGrants'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectTrainerItemGrant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      rewardFlagIds: (json['rewardFlagIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rewardBadgeId: json['rewardBadgeId'] as String?,
      rewardFieldAbilityUnlock: $enumDecodeNullable(
          _$FieldAbilityEnumMap, json['rewardFieldAbilityUnlock']),
      team: (json['team'] as List<dynamic>?)
              ?.map((e) => ProjectTrainerPokemonEntry.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$ProjectTrainerEntryImplToJson(
        _$ProjectTrainerEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'trainerClass': instance.trainerClass,
      'battleDifficulty': instance.battleDifficulty,
      'battleBackgroundRelativePath': instance.battleBackgroundRelativePath,
      'characterId': instance.characterId,
      'portraitElementId': instance.portraitElementId,
      'battleThemeId': instance.battleThemeId,
      'victoryThemeId': instance.victoryThemeId,
      'moneyReward': instance.moneyReward,
      'rewardItemGrants':
          instance.rewardItemGrants.map((e) => e.toJson()).toList(),
      'rewardFlagIds': instance.rewardFlagIds,
      if (instance.rewardBadgeId case final value?) 'rewardBadgeId': value,
      if (_$FieldAbilityEnumMap[instance.rewardFieldAbilityUnlock]
          case final value?)
        'rewardFieldAbilityUnlock': value,
      'team': instance.team.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
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
