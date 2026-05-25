// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScriptVariableValueBoolImpl _$$ScriptVariableValueBoolImplFromJson(
        Map<String, dynamic> json) =>
    _$ScriptVariableValueBoolImpl(
      json['value'] as bool,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ScriptVariableValueBoolImplToJson(
        _$ScriptVariableValueBoolImpl instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$ScriptVariableValueIntImpl _$$ScriptVariableValueIntImplFromJson(
        Map<String, dynamic> json) =>
    _$ScriptVariableValueIntImpl(
      (json['value'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ScriptVariableValueIntImplToJson(
        _$ScriptVariableValueIntImpl instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$ScriptVariableValueStringImpl _$$ScriptVariableValueStringImplFromJson(
        Map<String, dynamic> json) =>
    _$ScriptVariableValueStringImpl(
      json['value'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ScriptVariableValueStringImplToJson(
        _$ScriptVariableValueStringImpl instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$ScriptVariablesImpl _$$ScriptVariablesImplFromJson(
        Map<String, dynamic> json) =>
    _$ScriptVariablesImpl(
      values: (json['values'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, ScriptVariableValue.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ScriptVariablesImplToJson(
        _$ScriptVariablesImpl instance) =>
    <String, dynamic>{
      'values': instance.values.map((k, e) => MapEntry(k, e.toJson())),
    };

_$StoryFlagsImpl _$$StoryFlagsImplFromJson(Map<String, dynamic> json) =>
    _$StoryFlagsImpl(
      activeFlags: (json['activeFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
    );

Map<String, dynamic> _$$StoryFlagsImplToJson(_$StoryFlagsImpl instance) =>
    <String, dynamic>{
      'activeFlags': instance.activeFlags.toList(),
    };

_$GameStateImpl _$$GameStateImplFromJson(Map<String, dynamic> json) =>
    _$GameStateImpl(
      saveId: json['saveId'] as String,
      currentMapId: json['currentMapId'] as String? ?? '',
      playerPosition: json['playerPosition'] == null
          ? const GridPos(x: 0, y: 0)
          : GridPos.fromJson(json['playerPosition'] as Map<String, dynamic>),
      playerFacing:
          $enumDecodeNullable(_$EntityFacingEnumMap, json['playerFacing']) ??
              EntityFacing.south,
      playerMovementMode: $enumDecodeNullable(
              _$MovementModeEnumMap, json['playerMovementMode']) ??
          MovementMode.walk,
      party: json['party'] == null
          ? const PlayerParty()
          : PlayerParty.fromJson(json['party'] as Map<String, dynamic>),
      pokemonStorage: json['pokemonStorage'] == null
          ? const PokemonStorage()
          : PokemonStorage.fromJson(
              json['pokemonStorage'] as Map<String, dynamic>),
      trainerProfile: json['trainerProfile'] == null
          ? const TrainerProfile(name: 'Player')
          : TrainerProfile.fromJson(
              json['trainerProfile'] as Map<String, dynamic>),
      bag: json['bag'] == null
          ? const Bag()
          : Bag.fromJson(json['bag'] as Map<String, dynamic>),
      progression: json['progression'] == null
          ? const PlayerProgression()
          : PlayerProgression.fromJson(
              json['progression'] as Map<String, dynamic>),
      scriptVariables: json['scriptVariables'] == null
          ? const ScriptVariables()
          : ScriptVariables.fromJson(
              json['scriptVariables'] as Map<String, dynamic>),
      storyFlags: json['storyFlags'] == null
          ? const StoryFlags()
          : StoryFlags.fromJson(json['storyFlags'] as Map<String, dynamic>),
      consumedEventIds: (json['consumedEventIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$GameStateImplToJson(_$GameStateImpl instance) =>
    <String, dynamic>{
      'saveId': instance.saveId,
      'currentMapId': instance.currentMapId,
      'playerPosition': instance.playerPosition.toJson(),
      'playerFacing': _$EntityFacingEnumMap[instance.playerFacing]!,
      'playerMovementMode': _$MovementModeEnumMap[instance.playerMovementMode]!,
      'party': instance.party.toJson(),
      'pokemonStorage': instance.pokemonStorage.toJson(),
      'trainerProfile': instance.trainerProfile.toJson(),
      'bag': instance.bag.toJson(),
      'progression': instance.progression.toJson(),
      'scriptVariables': instance.scriptVariables.toJson(),
      'storyFlags': instance.storyFlags.toJson(),
      'consumedEventIds': instance.consumedEventIds.toList(),
      'metadata': instance.metadata,
    };

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

const _$MovementModeEnumMap = {
  MovementMode.walk: 'walk',
  MovementMode.surf: 'surf',
  MovementMode.fly: 'fly',
  MovementMode.cut: 'cut',
  MovementMode.strength: 'strength',
  MovementMode.rockSmash: 'rock_smash',
};
