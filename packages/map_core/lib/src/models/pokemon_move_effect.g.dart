// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_move_effect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PokemonMoveStatStageChange _$PokemonMoveStatStageChangeFromJson(
  Map<String, dynamic> json,
) => _PokemonMoveStatStageChange(
  stat: $enumDecode(_$PokemonMoveStatIdEnumMap, json['stat']),
  stages: (json['stages'] as num).toInt(),
);

Map<String, dynamic> _$PokemonMoveStatStageChangeToJson(
  _PokemonMoveStatStageChange instance,
) => <String, dynamic>{
  'stat': _$PokemonMoveStatIdEnumMap[instance.stat]!,
  'stages': instance.stages,
};

const _$PokemonMoveStatIdEnumMap = {
  PokemonMoveStatId.attack: 'attack',
  PokemonMoveStatId.defense: 'defense',
  PokemonMoveStatId.specialAttack: 'special_attack',
  PokemonMoveStatId.specialDefense: 'special_defense',
  PokemonMoveStatId.speed: 'speed',
  PokemonMoveStatId.accuracy: 'accuracy',
  PokemonMoveStatId.evasion: 'evasion',
};

PokemonMoveEffectFixedDamage _$PokemonMoveEffectFixedDamageFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectFixedDamage(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.target,
  chance: (json['chance'] as num?)?.toInt(),
  value: (json['value'] as num?)?.toInt(),
  usesUserLevel: json['usesUserLevel'] as bool? ?? false,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectFixedDamageToJson(
  PokemonMoveEffectFixedDamage instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'value': instance.value,
  'usesUserLevel': instance.usesUserLevel,
  'kind': instance.$type,
};

const _$PokemonMoveEffectTargetScopeEnumMap = {
  PokemonMoveEffectTargetScope.self: 'self',
  PokemonMoveEffectTargetScope.target: 'target',
  PokemonMoveEffectTargetScope.field: 'field',
  PokemonMoveEffectTargetScope.allySide: 'ally_side',
  PokemonMoveEffectTargetScope.foeSide: 'foe_side',
  PokemonMoveEffectTargetScope.slot: 'slot',
};

PokemonMoveEffectMultiHit _$PokemonMoveEffectMultiHitFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectMultiHit(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.target,
  chance: (json['chance'] as num?)?.toInt(),
  minHits: (json['minHits'] as num).toInt(),
  maxHits: (json['maxHits'] as num).toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectMultiHitToJson(
  PokemonMoveEffectMultiHit instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'minHits': instance.minHits,
  'maxHits': instance.maxHits,
  'kind': instance.$type,
};

PokemonMoveEffectApplyStatus _$PokemonMoveEffectApplyStatusFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectApplyStatus(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.target,
  chance: (json['chance'] as num?)?.toInt(),
  statusId: json['statusId'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectApplyStatusToJson(
  PokemonMoveEffectApplyStatus instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'statusId': instance.statusId,
  'kind': instance.$type,
};

PokemonMoveEffectApplyVolatileStatus
_$PokemonMoveEffectApplyVolatileStatusFromJson(Map<String, dynamic> json) =>
    PokemonMoveEffectApplyVolatileStatus(
      targetScope:
          $enumDecodeNullable(
            _$PokemonMoveEffectTargetScopeEnumMap,
            json['targetScope'],
          ) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      volatileStatusId: json['volatileStatusId'] as String,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$PokemonMoveEffectApplyVolatileStatusToJson(
  PokemonMoveEffectApplyVolatileStatus instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'volatileStatusId': instance.volatileStatusId,
  'kind': instance.$type,
};

PokemonMoveEffectModifyStats _$PokemonMoveEffectModifyStatsFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectModifyStats(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.target,
  chance: (json['chance'] as num?)?.toInt(),
  stageChanges:
      (json['stageChanges'] as List<dynamic>?)
          ?.map(
            (e) =>
                PokemonMoveStatStageChange.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <PokemonMoveStatStageChange>[],
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectModifyStatsToJson(
  PokemonMoveEffectModifyStats instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'stageChanges': instance.stageChanges.map((e) => e.toJson()).toList(),
  'kind': instance.$type,
};

PokemonMoveEffectHeal _$PokemonMoveEffectHealFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectHeal(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.self,
  chance: (json['chance'] as num?)?.toInt(),
  numerator: (json['numerator'] as num).toInt(),
  denominator: (json['denominator'] as num).toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectHealToJson(
  PokemonMoveEffectHeal instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'numerator': instance.numerator,
  'denominator': instance.denominator,
  'kind': instance.$type,
};

PokemonMoveEffectDrain _$PokemonMoveEffectDrainFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectDrain(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.self,
  chance: (json['chance'] as num?)?.toInt(),
  numerator: (json['numerator'] as num).toInt(),
  denominator: (json['denominator'] as num).toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectDrainToJson(
  PokemonMoveEffectDrain instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'numerator': instance.numerator,
  'denominator': instance.denominator,
  'kind': instance.$type,
};

PokemonMoveEffectRecoil _$PokemonMoveEffectRecoilFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectRecoil(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.self,
  chance: (json['chance'] as num?)?.toInt(),
  numerator: (json['numerator'] as num).toInt(),
  denominator: (json['denominator'] as num).toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectRecoilToJson(
  PokemonMoveEffectRecoil instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'numerator': instance.numerator,
  'denominator': instance.denominator,
  'kind': instance.$type,
};

PokemonMoveEffectSetWeather _$PokemonMoveEffectSetWeatherFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectSetWeather(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.field,
  chance: (json['chance'] as num?)?.toInt(),
  weatherId: json['weatherId'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectSetWeatherToJson(
  PokemonMoveEffectSetWeather instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'weatherId': instance.weatherId,
  'kind': instance.$type,
};

PokemonMoveEffectSetTerrain _$PokemonMoveEffectSetTerrainFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectSetTerrain(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.field,
  chance: (json['chance'] as num?)?.toInt(),
  terrainId: json['terrainId'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectSetTerrainToJson(
  PokemonMoveEffectSetTerrain instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'terrainId': instance.terrainId,
  'kind': instance.$type,
};

PokemonMoveEffectSetPseudoWeather _$PokemonMoveEffectSetPseudoWeatherFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectSetPseudoWeather(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.field,
  chance: (json['chance'] as num?)?.toInt(),
  pseudoWeatherId: json['pseudoWeatherId'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectSetPseudoWeatherToJson(
  PokemonMoveEffectSetPseudoWeather instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'pseudoWeatherId': instance.pseudoWeatherId,
  'kind': instance.$type,
};

PokemonMoveEffectSelfSwitch _$PokemonMoveEffectSelfSwitchFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectSelfSwitch(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.self,
  chance: (json['chance'] as num?)?.toInt(),
  mode: json['mode'] as String?,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectSelfSwitchToJson(
  PokemonMoveEffectSelfSwitch instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'mode': instance.mode,
  'kind': instance.$type,
};

PokemonMoveEffectForceSwitch _$PokemonMoveEffectForceSwitchFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectForceSwitch(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.target,
  chance: (json['chance'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectForceSwitchToJson(
  PokemonMoveEffectForceSwitch instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'kind': instance.$type,
};

PokemonMoveEffectBreakProtect _$PokemonMoveEffectBreakProtectFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectBreakProtect(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.target,
  chance: (json['chance'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectBreakProtectToJson(
  PokemonMoveEffectBreakProtect instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'kind': instance.$type,
};

PokemonMoveEffectRequireRecharge _$PokemonMoveEffectRequireRechargeFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectRequireRecharge(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.self,
  chance: (json['chance'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectRequireRechargeToJson(
  PokemonMoveEffectRequireRecharge instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'kind': instance.$type,
};

PokemonMoveEffectChargeThenStrike _$PokemonMoveEffectChargeThenStrikeFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectChargeThenStrike(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.self,
  chance: (json['chance'] as num?)?.toInt(),
  chargeStateId: json['chargeStateId'] as String?,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectChargeThenStrikeToJson(
  PokemonMoveEffectChargeThenStrike instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'chargeStateId': instance.chargeStateId,
  'kind': instance.$type,
};

PokemonMoveEffectSetSideCondition _$PokemonMoveEffectSetSideConditionFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectSetSideCondition(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.foeSide,
  chance: (json['chance'] as num?)?.toInt(),
  conditionId: json['conditionId'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectSetSideConditionToJson(
  PokemonMoveEffectSetSideCondition instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'conditionId': instance.conditionId,
  'kind': instance.$type,
};

PokemonMoveEffectSetSlotCondition _$PokemonMoveEffectSetSlotConditionFromJson(
  Map<String, dynamic> json,
) => PokemonMoveEffectSetSlotCondition(
  targetScope:
      $enumDecodeNullable(
        _$PokemonMoveEffectTargetScopeEnumMap,
        json['targetScope'],
      ) ??
      PokemonMoveEffectTargetScope.slot,
  chance: (json['chance'] as num?)?.toInt(),
  conditionId: json['conditionId'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PokemonMoveEffectSetSlotConditionToJson(
  PokemonMoveEffectSetSlotCondition instance,
) => <String, dynamic>{
  'targetScope': _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
  'chance': instance.chance,
  'conditionId': instance.conditionId,
  'kind': instance.$type,
};
