// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerPokemonImpl _$$PlayerPokemonImplFromJson(Map<String, dynamic> json) =>
    _$PlayerPokemonImpl(
      id: json['id'] as String,
      speciesId: json['speciesId'] as String,
      nickname: json['nickname'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      knownMoveIds: (json['knownMoveIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isFainted: json['isFainted'] as bool? ?? false,
    );

Map<String, dynamic> _$$PlayerPokemonImplToJson(_$PlayerPokemonImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'speciesId': instance.speciesId,
      'nickname': instance.nickname,
      'level': instance.level,
      'knownMoveIds': instance.knownMoveIds,
      'isFainted': instance.isFainted,
    };

_$PlayerPartyImpl _$$PlayerPartyImplFromJson(Map<String, dynamic> json) =>
    _$PlayerPartyImpl(
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => PlayerPokemon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PlayerPartyImplToJson(_$PlayerPartyImpl instance) =>
    <String, dynamic>{
      'members': instance.members.map((e) => e.toJson()).toList(),
    };

_$PlayerProgressionImpl _$$PlayerProgressionImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayerProgressionImpl(
      unlockedFieldAbilities: (json['unlockedFieldAbilities'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$FieldAbilityEnumMap, e))
              .toList() ??
          const [],
      storyFlags: (json['storyFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PlayerProgressionImplToJson(
        _$PlayerProgressionImpl instance) =>
    <String, dynamic>{
      'unlockedFieldAbilities': instance.unlockedFieldAbilities
          .map((e) => _$FieldAbilityEnumMap[e]!)
          .toList(),
      'storyFlags': instance.storyFlags,
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

_$SaveDataImpl _$$SaveDataImplFromJson(Map<String, dynamic> json) =>
    _$SaveDataImpl(
      saveId: json['saveId'] as String,
      currentMapId: json['currentMapId'] as String? ?? '',
      playerPosition: json['playerPosition'] == null
          ? const GridPos(x: 0, y: 0)
          : GridPos.fromJson(json['playerPosition'] as Map<String, dynamic>),
      playerFacing:
          $enumDecodeNullable(_$EntityFacingEnumMap, json['playerFacing']) ??
              EntityFacing.south,
      party: json['party'] == null
          ? const PlayerParty()
          : PlayerParty.fromJson(json['party'] as Map<String, dynamic>),
      progression: json['progression'] == null
          ? const PlayerProgression()
          : PlayerProgression.fromJson(
              json['progression'] as Map<String, dynamic>),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$SaveDataImplToJson(_$SaveDataImpl instance) =>
    <String, dynamic>{
      'saveId': instance.saveId,
      'currentMapId': instance.currentMapId,
      'playerPosition': instance.playerPosition.toJson(),
      'playerFacing': _$EntityFacingEnumMap[instance.playerFacing]!,
      'party': instance.party.toJson(),
      'progression': instance.progression.toJson(),
      'properties': instance.properties,
    };

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};
