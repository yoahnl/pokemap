// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_gameplay_zone_payloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EncounterZonePayload _$EncounterZonePayloadFromJson(
  Map<String, dynamic> json,
) => _EncounterZonePayload(
  encounterTableId: json['encounterTableId'] as String?,
  encounterKind:
      $enumDecodeNullable(_$EncounterKindEnumMap, json['encounterKind']) ??
      EncounterKind.walk,
  battleBackgroundRelativePath: json['battleBackgroundRelativePath'] as String?,
  battleMusicPath: json['battleMusicPath'] as String?,
  encounterMusicPath: json['encounterMusicPath'] as String?,
  battleTransitionIds:
      (json['battleTransitionIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$EncounterZonePayloadToJson(
  _EncounterZonePayload instance,
) => <String, dynamic>{
  'encounterTableId': instance.encounterTableId,
  'encounterKind': _$EncounterKindEnumMap[instance.encounterKind]!,
  'battleBackgroundRelativePath': instance.battleBackgroundRelativePath,
  'battleMusicPath': instance.battleMusicPath,
  'encounterMusicPath': instance.encounterMusicPath,
  'battleTransitionIds': instance.battleTransitionIds,
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

_MovementZonePayload _$MovementZonePayloadFromJson(Map<String, dynamic> json) =>
    _MovementZonePayload(
      requiredMode:
          $enumDecodeNullable(_$MovementModeEnumMap, json['requiredMode']) ??
          MovementMode.walk,
      allowedModes:
          (json['allowedModes'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$MovementModeEnumMap, e))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MovementZonePayloadToJson(
  _MovementZonePayload instance,
) => <String, dynamic>{
  'requiredMode': _$MovementModeEnumMap[instance.requiredMode]!,
  'allowedModes': instance.allowedModes
      .map((e) => _$MovementModeEnumMap[e]!)
      .toList(),
};

const _$MovementModeEnumMap = {
  MovementMode.walk: 'walk',
  MovementMode.surf: 'surf',
  MovementMode.fly: 'fly',
  MovementMode.cut: 'cut',
  MovementMode.strength: 'strength',
  MovementMode.rockSmash: 'rock_smash',
};

_MovementEffectZonePayload _$MovementEffectZonePayloadFromJson(
  Map<String, dynamic> json,
) => _MovementEffectZonePayload(
  effectKind:
      $enumDecodeNullable(
        _$MovementEffectZoneKindEnumMap,
        json['effectKind'],
      ) ??
      MovementEffectZoneKind.slide,
  movementCost: (json['movementCost'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$MovementEffectZonePayloadToJson(
  _MovementEffectZonePayload instance,
) => <String, dynamic>{
  'effectKind': _$MovementEffectZoneKindEnumMap[instance.effectKind]!,
  'movementCost': instance.movementCost,
};

const _$MovementEffectZoneKindEnumMap = {
  MovementEffectZoneKind.slide: 'slide',
  MovementEffectZoneKind.movementCost: 'movementCost',
};

_HazardZonePayload _$HazardZonePayloadFromJson(Map<String, dynamic> json) =>
    _HazardZonePayload(
      hazardKind:
          $enumDecodeNullable(_$HazardKindEnumMap, json['hazardKind']) ??
          HazardKind.other,
      damagePerStep: (json['damagePerStep'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$HazardZonePayloadToJson(_HazardZonePayload instance) =>
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

_SpecialZonePayload _$SpecialZonePayloadFromJson(Map<String, dynamic> json) =>
    _SpecialZonePayload(
      scriptKey: json['scriptKey'] as String?,
      properties:
          (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$SpecialZonePayloadToJson(_SpecialZonePayload instance) =>
    <String, dynamic>{
      'scriptKey': instance.scriptKey,
      'properties': instance.properties,
    };
