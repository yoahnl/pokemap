// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_trainer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectTrainerItemGrant _$ProjectTrainerItemGrantFromJson(
  Map<String, dynamic> json,
) => _ProjectTrainerItemGrant(
  itemId: json['itemId'] as String,
  quantity: json['quantity'] == null
      ? 1
      : _projectTrainerItemQuantityFromJson(json['quantity']),
);

Map<String, dynamic> _$ProjectTrainerItemGrantToJson(
  _ProjectTrainerItemGrant instance,
) => <String, dynamic>{
  'itemId': instance.itemId,
  'quantity': instance.quantity,
};

_ProjectTrainerPokemonEntry _$ProjectTrainerPokemonEntryFromJson(
  Map<String, dynamic> json,
) => _ProjectTrainerPokemonEntry(
  speciesId: json['speciesId'] as String,
  level: (json['level'] as num).toInt(),
  moves:
      (json['moves'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  heldItemId: json['heldItemId'] as String?,
  abilityId: json['abilityId'] as String?,
  formId: json['formId'] as String?,
  gender: json['gender'] as String?,
  shiny: json['shiny'] as bool? ?? false,
);

Map<String, dynamic> _$ProjectTrainerPokemonEntryToJson(
  _ProjectTrainerPokemonEntry instance,
) => <String, dynamic>{
  'speciesId': instance.speciesId,
  'level': instance.level,
  'moves': instance.moves,
  'heldItemId': instance.heldItemId,
  'abilityId': instance.abilityId,
  'formId': instance.formId,
  'gender': instance.gender,
  'shiny': instance.shiny,
};

_ProjectTrainerEntry _$ProjectTrainerEntryFromJson(
  Map<String, dynamic> json,
) => _ProjectTrainerEntry(
  id: json['id'] as String,
  name: json['name'] as String,
  trainerClass: json['trainerClass'] as String,
  battleDifficulty: (json['battleDifficulty'] as num?)?.toInt(),
  battleBackgroundRelativePath: json['battleBackgroundRelativePath'] as String?,
  battleSpriteRelativePath: json['battleSpriteRelativePath'] as String?,
  battleTransitionId: json['battleTransitionId'] as String?,
  characterId: json['characterId'] as String?,
  portraitElementId: json['portraitElementId'] as String?,
  battleMusicPath: json['battleMusicPath'] as String?,
  victoryMusicPath: json['victoryMusicPath'] as String?,
  moneyReward: json['moneyReward'] == null
      ? 0
      : _projectTrainerMoneyRewardFromJson(json['moneyReward']),
  rewardItemGrants:
      (json['rewardItemGrants'] as List<dynamic>?)
          ?.map(
            (e) => ProjectTrainerItemGrant.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  rewardFlagIds:
      (json['rewardFlagIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  rewardBadgeId: json['rewardBadgeId'] as String?,
  rewardFieldAbilityUnlock: $enumDecodeNullable(
    _$FieldAbilityEnumMap,
    json['rewardFieldAbilityUnlock'],
  ),
  templateKind: $enumDecodeNullable(
    _$ProjectTrainerTemplateKindEnumMap,
    json['templateKind'],
  ),
  rematchPolicy: $enumDecodeNullable(
    _$ProjectTrainerRematchPolicyEnumMap,
    json['rematchPolicy'],
  ),
  preBattleDialogueId: json['preBattleDialogueId'] as String?,
  victoryDialogueId: json['victoryDialogueId'] as String?,
  defeatDialogueId: json['defeatDialogueId'] as String?,
  team:
      (json['team'] as List<dynamic>?)
          ?.map(
            (e) =>
                ProjectTrainerPokemonEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ProjectTrainerEntryToJson(
  _ProjectTrainerEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'trainerClass': instance.trainerClass,
  'battleDifficulty': instance.battleDifficulty,
  'battleBackgroundRelativePath': instance.battleBackgroundRelativePath,
  'battleSpriteRelativePath': ?instance.battleSpriteRelativePath,
  'battleTransitionId': ?instance.battleTransitionId,
  'characterId': instance.characterId,
  'portraitElementId': instance.portraitElementId,
  'battleMusicPath': instance.battleMusicPath,
  'victoryMusicPath': instance.victoryMusicPath,
  'moneyReward': instance.moneyReward,
  'rewardItemGrants': instance.rewardItemGrants.map((e) => e.toJson()).toList(),
  'rewardFlagIds': instance.rewardFlagIds,
  'rewardBadgeId': ?instance.rewardBadgeId,
  'rewardFieldAbilityUnlock':
      ?_$FieldAbilityEnumMap[instance.rewardFieldAbilityUnlock],
  'templateKind': ?_$ProjectTrainerTemplateKindEnumMap[instance.templateKind],
  'rematchPolicy':
      ?_$ProjectTrainerRematchPolicyEnumMap[instance.rematchPolicy],
  'preBattleDialogueId': ?instance.preBattleDialogueId,
  'victoryDialogueId': ?instance.victoryDialogueId,
  'defeatDialogueId': ?instance.defeatDialogueId,
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

const _$ProjectTrainerTemplateKindEnumMap = {
  ProjectTrainerTemplateKind.gymLeader: 'gym_leader',
  ProjectTrainerTemplateKind.rival: 'rival',
};

const _$ProjectTrainerRematchPolicyEnumMap = {
  ProjectTrainerRematchPolicy.allowed: 'allowed',
};
