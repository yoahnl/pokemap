// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_trainer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      portraitElementId: json['portraitElementId'] as String?,
      battleThemeId: json['battleThemeId'] as String?,
      victoryThemeId: json['victoryThemeId'] as String?,
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
      'portraitElementId': instance.portraitElementId,
      'battleThemeId': instance.battleThemeId,
      'victoryThemeId': instance.victoryThemeId,
      'team': instance.team.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
    };
