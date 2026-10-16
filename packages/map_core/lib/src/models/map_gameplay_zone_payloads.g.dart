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
  MovementMode.bicycle: 'bicycle',
  MovementMode.dive: 'dive',
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

_FieldActionZonePayload _$FieldActionZonePayloadFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    allowedKeys: const ['actionKind', 'darkness', 'waterfall', 'dive'],
  );
  return _FieldActionZonePayload(
    actionKind: $enumDecode(_$FieldActionZoneKindEnumMap, json['actionKind']),
    darkness: json['darkness'] == null
        ? null
        : DarknessZonePayload.fromJson(
            json['darkness'] as Map<String, dynamic>,
          ),
    waterfall: json['waterfall'] == null
        ? null
        : WaterfallZonePayload.fromJson(
            json['waterfall'] as Map<String, dynamic>,
          ),
    dive: json['dive'] == null
        ? null
        : DiveZonePayload.fromJson(json['dive'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FieldActionZonePayloadToJson(
  _FieldActionZonePayload instance,
) => <String, dynamic>{
  'actionKind': _$FieldActionZoneKindEnumMap[instance.actionKind]!,
  'darkness': ?instance.darkness?.toJson(),
  'waterfall': ?instance.waterfall?.toJson(),
  'dive': ?instance.dive?.toJson(),
};

const _$FieldActionZoneKindEnumMap = {
  FieldActionZoneKind.dive: 'dive',
  FieldActionZoneKind.waterfall: 'waterfall',
  FieldActionZoneKind.darkness: 'darkness',
};

_DarknessZonePayload _$DarknessZonePayloadFromJson(Map<String, dynamic> json) {
  $checkKeys(json, allowedKeys: const ['opacity']);
  return _DarknessZonePayload(opacity: (json['opacity'] as num).toDouble());
}

Map<String, dynamic> _$DarknessZonePayloadToJson(
  _DarknessZonePayload instance,
) => <String, dynamic>{'opacity': instance.opacity};

_WaterfallZonePayload _$WaterfallZonePayloadFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    allowedKeys: const ['entry', 'path', 'exit', 'direction', 'requiresSurf'],
  );
  return _WaterfallZonePayload(
    entry: GridPos.fromJson(json['entry'] as Map<String, dynamic>),
    path: (json['path'] as List<dynamic>)
        .map((e) => GridPos.fromJson(e as Map<String, dynamic>))
        .toList(),
    exit: GridPos.fromJson(json['exit'] as Map<String, dynamic>),
    direction: $enumDecode(_$MapConnectionDirectionEnumMap, json['direction']),
    requiresSurf: json['requiresSurf'] as bool? ?? true,
  );
}

Map<String, dynamic> _$WaterfallZonePayloadToJson(
  _WaterfallZonePayload instance,
) => <String, dynamic>{
  'entry': instance.entry.toJson(),
  'path': instance.path.map((e) => e.toJson()).toList(),
  'exit': instance.exit.toJson(),
  'direction': _$MapConnectionDirectionEnumMap[instance.direction]!,
  'requiresSurf': instance.requiresSurf,
};

const _$MapConnectionDirectionEnumMap = {
  MapConnectionDirection.north: 'north',
  MapConnectionDirection.south: 'south',
  MapConnectionDirection.east: 'east',
  MapConnectionDirection.west: 'west',
};

_DiveZonePayload _$DiveZonePayloadFromJson(Map<String, dynamic> json) {
  $checkKeys(json, allowedKeys: const ['role', 'arrivalSpawnId', 'link']);
  return _DiveZonePayload(
    role: $enumDecode(_$DiveZoneRoleEnumMap, json['role']),
    arrivalSpawnId: json['arrivalSpawnId'] as String?,
    link: json['link'] == null
        ? null
        : DiveZoneLink.fromJson(json['link'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$DiveZonePayloadToJson(_DiveZonePayload instance) =>
    <String, dynamic>{
      'role': _$DiveZoneRoleEnumMap[instance.role]!,
      'arrivalSpawnId': ?instance.arrivalSpawnId,
      'link': ?instance.link?.toJson(),
    };

const _$DiveZoneRoleEnumMap = {
  DiveZoneRole.surface: 'surface',
  DiveZoneRole.underwater: 'underwater',
};

_DiveZoneLink _$DiveZoneLinkFromJson(Map<String, dynamic> json) {
  $checkKeys(json, allowedKeys: const ['mapId', 'zoneId']);
  return _DiveZoneLink(
    mapId: json['mapId'] as String,
    zoneId: json['zoneId'] as String,
  );
}

Map<String, dynamic> _$DiveZoneLinkToJson(_DiveZoneLink instance) =>
    <String, dynamic>{'mapId': instance.mapId, 'zoneId': instance.zoneId};
