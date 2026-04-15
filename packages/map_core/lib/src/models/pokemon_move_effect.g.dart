// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_move_effect.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PokemonMoveStatStageChangeImpl _$$PokemonMoveStatStageChangeImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveStatStageChangeImpl(
      stat: $enumDecode(_$PokemonMoveStatIdEnumMap, json['stat']),
      stages: (json['stages'] as num).toInt(),
    );

Map<String, dynamic> _$$PokemonMoveStatStageChangeImplToJson(
        _$PokemonMoveStatStageChangeImpl instance) =>
    <String, dynamic>{
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

_$PokemonMoveEffectDealDamageImpl _$$PokemonMoveEffectDealDamageImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectDealDamageImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectDealDamageImplToJson(
        _$PokemonMoveEffectDealDamageImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
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

_$PokemonMoveEffectFixedDamageImpl _$$PokemonMoveEffectFixedDamageImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectFixedDamageImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      value: (json['value'] as num?)?.toInt(),
      usesUserLevel: json['usesUserLevel'] as bool? ?? false,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectFixedDamageImplToJson(
        _$PokemonMoveEffectFixedDamageImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'value': instance.value,
      'usesUserLevel': instance.usesUserLevel,
      'kind': instance.$type,
    };

_$PokemonMoveEffectMultiHitImpl _$$PokemonMoveEffectMultiHitImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectMultiHitImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      minHits: (json['minHits'] as num).toInt(),
      maxHits: (json['maxHits'] as num).toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectMultiHitImplToJson(
        _$PokemonMoveEffectMultiHitImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'minHits': instance.minHits,
      'maxHits': instance.maxHits,
      'kind': instance.$type,
    };

_$PokemonMoveEffectApplyStatusImpl _$$PokemonMoveEffectApplyStatusImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectApplyStatusImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      statusId: json['statusId'] as String,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectApplyStatusImplToJson(
        _$PokemonMoveEffectApplyStatusImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'statusId': instance.statusId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectApplyVolatileStatusImpl
    _$$PokemonMoveEffectApplyVolatileStatusImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectApplyVolatileStatusImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.target,
          chance: (json['chance'] as num?)?.toInt(),
          volatileStatusId: json['volatileStatusId'] as String,
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectApplyVolatileStatusImplToJson(
        _$PokemonMoveEffectApplyVolatileStatusImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'volatileStatusId': instance.volatileStatusId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectModifyStatsImpl _$$PokemonMoveEffectModifyStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectModifyStatsImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      stageChanges: (json['stageChanges'] as List<dynamic>?)
              ?.map((e) => PokemonMoveStatStageChange.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const <PokemonMoveStatStageChange>[],
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectModifyStatsImplToJson(
        _$PokemonMoveEffectModifyStatsImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'stageChanges': instance.stageChanges.map((e) => e.toJson()).toList(),
      'kind': instance.$type,
    };

_$PokemonMoveEffectHealImpl _$$PokemonMoveEffectHealImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectHealImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.self,
      chance: (json['chance'] as num?)?.toInt(),
      numerator: (json['numerator'] as num).toInt(),
      denominator: (json['denominator'] as num).toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectHealImplToJson(
        _$PokemonMoveEffectHealImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'numerator': instance.numerator,
      'denominator': instance.denominator,
      'kind': instance.$type,
    };

_$PokemonMoveEffectDrainImpl _$$PokemonMoveEffectDrainImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectDrainImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.self,
      chance: (json['chance'] as num?)?.toInt(),
      numerator: (json['numerator'] as num).toInt(),
      denominator: (json['denominator'] as num).toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectDrainImplToJson(
        _$PokemonMoveEffectDrainImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'numerator': instance.numerator,
      'denominator': instance.denominator,
      'kind': instance.$type,
    };

_$PokemonMoveEffectRecoilImpl _$$PokemonMoveEffectRecoilImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectRecoilImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.self,
      chance: (json['chance'] as num?)?.toInt(),
      numerator: (json['numerator'] as num).toInt(),
      denominator: (json['denominator'] as num).toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectRecoilImplToJson(
        _$PokemonMoveEffectRecoilImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'numerator': instance.numerator,
      'denominator': instance.denominator,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSetWeatherImpl _$$PokemonMoveEffectSetWeatherImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectSetWeatherImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.field,
      chance: (json['chance'] as num?)?.toInt(),
      weatherId: json['weatherId'] as String,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectSetWeatherImplToJson(
        _$PokemonMoveEffectSetWeatherImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'weatherId': instance.weatherId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSetTerrainImpl _$$PokemonMoveEffectSetTerrainImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectSetTerrainImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.field,
      chance: (json['chance'] as num?)?.toInt(),
      terrainId: json['terrainId'] as String,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectSetTerrainImplToJson(
        _$PokemonMoveEffectSetTerrainImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'terrainId': instance.terrainId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSelfSwitchImpl _$$PokemonMoveEffectSelfSwitchImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectSelfSwitchImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.self,
      chance: (json['chance'] as num?)?.toInt(),
      mode: json['mode'] as String?,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectSelfSwitchImplToJson(
        _$PokemonMoveEffectSelfSwitchImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'mode': instance.mode,
      'kind': instance.$type,
    };

_$PokemonMoveEffectForceSwitchImpl _$$PokemonMoveEffectForceSwitchImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveEffectForceSwitchImpl(
      targetScope: $enumDecodeNullable(
              _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
          PokemonMoveEffectTargetScope.target,
      chance: (json['chance'] as num?)?.toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$$PokemonMoveEffectForceSwitchImplToJson(
        _$PokemonMoveEffectForceSwitchImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'kind': instance.$type,
    };

_$PokemonMoveEffectBreakProtectImpl
    _$$PokemonMoveEffectBreakProtectImplFromJson(Map<String, dynamic> json) =>
        _$PokemonMoveEffectBreakProtectImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.target,
          chance: (json['chance'] as num?)?.toInt(),
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectBreakProtectImplToJson(
        _$PokemonMoveEffectBreakProtectImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'kind': instance.$type,
    };

_$PokemonMoveEffectRequireRechargeImpl
    _$$PokemonMoveEffectRequireRechargeImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectRequireRechargeImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.self,
          chance: (json['chance'] as num?)?.toInt(),
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectRequireRechargeImplToJson(
        _$PokemonMoveEffectRequireRechargeImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'kind': instance.$type,
    };

_$PokemonMoveEffectChargeThenStrikeImpl
    _$$PokemonMoveEffectChargeThenStrikeImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectChargeThenStrikeImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.self,
          chance: (json['chance'] as num?)?.toInt(),
          chargeStateId: json['chargeStateId'] as String?,
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectChargeThenStrikeImplToJson(
        _$PokemonMoveEffectChargeThenStrikeImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'chargeStateId': instance.chargeStateId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSetSideConditionImpl
    _$$PokemonMoveEffectSetSideConditionImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectSetSideConditionImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.foeSide,
          chance: (json['chance'] as num?)?.toInt(),
          conditionId: json['conditionId'] as String,
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectSetSideConditionImplToJson(
        _$PokemonMoveEffectSetSideConditionImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'conditionId': instance.conditionId,
      'kind': instance.$type,
    };

_$PokemonMoveEffectSetSlotConditionImpl
    _$$PokemonMoveEffectSetSlotConditionImplFromJson(
            Map<String, dynamic> json) =>
        _$PokemonMoveEffectSetSlotConditionImpl(
          targetScope: $enumDecodeNullable(
                  _$PokemonMoveEffectTargetScopeEnumMap, json['targetScope']) ??
              PokemonMoveEffectTargetScope.slot,
          chance: (json['chance'] as num?)?.toInt(),
          conditionId: json['conditionId'] as String,
          $type: json['kind'] as String?,
        );

Map<String, dynamic> _$$PokemonMoveEffectSetSlotConditionImplToJson(
        _$PokemonMoveEffectSetSlotConditionImpl instance) =>
    <String, dynamic>{
      'targetScope':
          _$PokemonMoveEffectTargetScopeEnumMap[instance.targetScope]!,
      'chance': instance.chance,
      'conditionId': instance.conditionId,
      'kind': instance.$type,
    };
