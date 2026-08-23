// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_battle_audio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectBattleAudioConfig _$ProjectBattleAudioConfigFromJson(
  Map<String, dynamic> json,
) => _ProjectBattleAudioConfig(
  wildBattleMusicPath: json['wildBattleMusicPath'] as String?,
  trainerBattleMusicPath: json['trainerBattleMusicPath'] as String?,
  wildVictoryMusicPath: json['wildVictoryMusicPath'] as String?,
  trainerVictoryMusicPath: json['trainerVictoryMusicPath'] as String?,
  encounterMusicPath: json['encounterMusicPath'] as String?,
  battleStartSePath: json['battleStartSePath'] as String?,
);

Map<String, dynamic> _$ProjectBattleAudioConfigToJson(
  _ProjectBattleAudioConfig instance,
) => <String, dynamic>{
  'wildBattleMusicPath': ?instance.wildBattleMusicPath,
  'trainerBattleMusicPath': ?instance.trainerBattleMusicPath,
  'wildVictoryMusicPath': ?instance.wildVictoryMusicPath,
  'trainerVictoryMusicPath': ?instance.trainerVictoryMusicPath,
  'encounterMusicPath': ?instance.encounterMusicPath,
  'battleStartSePath': ?instance.battleStartSePath,
};
