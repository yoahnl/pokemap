// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_gameplay_zone_payloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EncounterZonePayloadImpl _$$EncounterZonePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$EncounterZonePayloadImpl(
      encounterTableId: json['encounterTableId'] as String?,
      encounterKind:
          $enumDecodeNullable(_$EncounterKindEnumMap, json['encounterKind']) ??
              EncounterKind.walk,
      battleBackgroundRelativePath:
          json['battleBackgroundRelativePath'] as String?,
    );

Map<String, dynamic> _$$EncounterZonePayloadImplToJson(
        _$EncounterZonePayloadImpl instance) =>
    <String, dynamic>{
      'encounterTableId': instance.encounterTableId,
      'encounterKind': _$EncounterKindEnumMap[instance.encounterKind]!,
      'battleBackgroundRelativePath': instance.battleBackgroundRelativePath,
    };

const _$EncounterKindEnumMap = {
  EncounterKind.walk: 'walk',
  EncounterKind.surf: 'surf',
  EncounterKind.headbutt: 'headbutt',
  EncounterKind.oldRod: 'old_rod',
  EncounterKind.goodRod: 'good_rod',
  EncounterKind.superRod: 'super_rod',
  EncounterKind.gift: 'gift',
  EncounterKind.special: 'special',
};

_$MovementZonePayloadImpl _$$MovementZonePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$MovementZonePayloadImpl(
      requiredMode:
          $enumDecodeNullable(_$MovementModeEnumMap, json['requiredMode']) ??
              MovementMode.walk,
      allowedModes: (json['allowedModes'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$MovementModeEnumMap, e))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MovementZonePayloadImplToJson(
        _$MovementZonePayloadImpl instance) =>
    <String, dynamic>{
      'requiredMode': _$MovementModeEnumMap[instance.requiredMode]!,
      'allowedModes':
          instance.allowedModes.map((e) => _$MovementModeEnumMap[e]!).toList(),
    };

const _$MovementModeEnumMap = {
  MovementMode.walk: 'walk',
  MovementMode.surf: 'surf',
  MovementMode.fly: 'fly',
  MovementMode.cut: 'cut',
  MovementMode.strength: 'strength',
  MovementMode.rockSmash: 'rock_smash',
};

_$HazardZonePayloadImpl _$$HazardZonePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$HazardZonePayloadImpl(
      hazardKind:
          $enumDecodeNullable(_$HazardKindEnumMap, json['hazardKind']) ??
              HazardKind.other,
      damagePerStep: (json['damagePerStep'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$HazardZonePayloadImplToJson(
        _$HazardZonePayloadImpl instance) =>
    <String, dynamic>{
      'hazardKind': _$HazardKindEnumMap[instance.hazardKind]!,
      'damagePerStep': instance.damagePerStep,
    };

const _$HazardKindEnumMap = {
  HazardKind.lava: 'lava',
  HazardKind.poison: 'poison',
  HazardKind.swamp: 'swamp',
  HazardKind.pitfall: 'pitfall',
  HazardKind.other: 'other',
};

_$SpecialZonePayloadImpl _$$SpecialZonePayloadImplFromJson(
        Map<String, dynamic> json) =>
    _$SpecialZonePayloadImpl(
      scriptKey: json['scriptKey'] as String?,
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$SpecialZonePayloadImplToJson(
        _$SpecialZonePayloadImpl instance) =>
    <String, dynamic>{
      'scriptKey': instance.scriptKey,
      'properties': instance.properties,
    };
