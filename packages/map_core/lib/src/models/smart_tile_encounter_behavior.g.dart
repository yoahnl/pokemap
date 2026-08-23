// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_tile_encounter_behavior.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SmartTileEncounterBehavior _$SmartTileEncounterBehaviorFromJson(
  Map<String, dynamic> json,
) => _SmartTileEncounterBehavior(
  materialId: json['materialId'] as String,
  priority: (json['priority'] as num?)?.toInt() ?? 0,
  encounter: EncounterZonePayload.fromJson(
    json['encounter'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$SmartTileEncounterBehaviorToJson(
  _SmartTileEncounterBehavior instance,
) => <String, dynamic>{
  'materialId': instance.materialId,
  'priority': instance.priority,
  'encounter': instance.encounter.toJson(),
};
