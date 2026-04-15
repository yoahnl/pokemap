// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_move_accuracy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PokemonMoveAccuracyPercentImpl _$$PokemonMoveAccuracyPercentImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveAccuracyPercentImpl(
      value: (json['value'] as num).toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveAccuracyPercentImplToJson(
        _$PokemonMoveAccuracyPercentImpl instance) =>
    <String, dynamic>{
      'value': instance.value,
      'kind': instance.$type,
    };

_$PokemonMoveAccuracyAlwaysHitsImpl
    _$$PokemonMoveAccuracyAlwaysHitsImplFromJson(Map<String, dynamic> json) =>
        _$PokemonMoveAccuracyAlwaysHitsImpl(
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveAccuracyAlwaysHitsImplToJson(
        _$PokemonMoveAccuracyAlwaysHitsImpl instance) =>
    <String, dynamic>{
      'kind': instance.$type,
    };
