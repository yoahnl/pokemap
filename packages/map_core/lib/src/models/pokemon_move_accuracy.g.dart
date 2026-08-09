// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_move_accuracy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PokemonMoveAccuracyPercent _$PokemonMoveAccuracyPercentFromJson(
  Map<String, dynamic> json,
) => PokemonMoveAccuracyPercent(
  value: (json['value'] as num).toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveAccuracyPercentToJson(
  PokemonMoveAccuracyPercent instance,
) => <String, dynamic>{'value': instance.value, 'kind': instance.$type};

PokemonMoveAccuracyAlwaysHits _$PokemonMoveAccuracyAlwaysHitsFromJson(
  Map<String, dynamic> json,
) => PokemonMoveAccuracyAlwaysHits($type: json['kind'] as String?);

Map<String, dynamic> _$PokemonMoveAccuracyAlwaysHitsToJson(
  PokemonMoveAccuracyAlwaysHits instance,
) => <String, dynamic>{'kind': instance.$type};
