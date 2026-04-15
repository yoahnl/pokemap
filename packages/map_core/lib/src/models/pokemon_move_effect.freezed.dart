// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pokemon_move_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PokemonMoveStatStageChange _$PokemonMoveStatStageChangeFromJson(
    Map<String, dynamic> json) {
  return _PokemonMoveStatStageChange.fromJson(json);
}

/// @nodoc
mixin _$PokemonMoveStatStageChange {
  PokemonMoveStatId get stat => throw _privateConstructorUsedError;
  int get stages => throw _privateConstructorUsedError;

  /// Serializes this PokemonMoveStatStageChange to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonMoveStatStageChangeCopyWith<PokemonMoveStatStageChange>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonMoveStatStageChangeCopyWith<$Res> {
  factory $PokemonMoveStatStageChangeCopyWith(PokemonMoveStatStageChange value,
          $Res Function(PokemonMoveStatStageChange) then) =
      _$PokemonMoveStatStageChangeCopyWithImpl<$Res,
          PokemonMoveStatStageChange>;
  @useResult
  $Res call({PokemonMoveStatId stat, int stages});
}

/// @nodoc
class _$PokemonMoveStatStageChangeCopyWithImpl<$Res,
        $Val extends PokemonMoveStatStageChange>
    implements $PokemonMoveStatStageChangeCopyWith<$Res> {
  _$PokemonMoveStatStageChangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stat = null,
    Object? stages = null,
  }) {
    return _then(_value.copyWith(
      stat: null == stat
          ? _value.stat
          : stat // ignore: cast_nullable_to_non_nullable
              as PokemonMoveStatId,
      stages: null == stages
          ? _value.stages
          : stages // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PokemonMoveStatStageChangeImplCopyWith<$Res>
    implements $PokemonMoveStatStageChangeCopyWith<$Res> {
  factory _$$PokemonMoveStatStageChangeImplCopyWith(
          _$PokemonMoveStatStageChangeImpl value,
          $Res Function(_$PokemonMoveStatStageChangeImpl) then) =
      __$$PokemonMoveStatStageChangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PokemonMoveStatId stat, int stages});
}

/// @nodoc
class __$$PokemonMoveStatStageChangeImplCopyWithImpl<$Res>
    extends _$PokemonMoveStatStageChangeCopyWithImpl<$Res,
        _$PokemonMoveStatStageChangeImpl>
    implements _$$PokemonMoveStatStageChangeImplCopyWith<$Res> {
  __$$PokemonMoveStatStageChangeImplCopyWithImpl(
      _$PokemonMoveStatStageChangeImpl _value,
      $Res Function(_$PokemonMoveStatStageChangeImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stat = null,
    Object? stages = null,
  }) {
    return _then(_$PokemonMoveStatStageChangeImpl(
      stat: null == stat
          ? _value.stat
          : stat // ignore: cast_nullable_to_non_nullable
              as PokemonMoveStatId,
      stages: null == stages
          ? _value.stages
          : stages // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveStatStageChangeImpl implements _PokemonMoveStatStageChange {
  const _$PokemonMoveStatStageChangeImpl(
      {required this.stat, required this.stages});

  factory _$PokemonMoveStatStageChangeImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveStatStageChangeImplFromJson(json);

  @override
  final PokemonMoveStatId stat;
  @override
  final int stages;

  @override
  String toString() {
    return 'PokemonMoveStatStageChange(stat: $stat, stages: $stages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveStatStageChangeImpl &&
            (identical(other.stat, stat) || other.stat == stat) &&
            (identical(other.stages, stages) || other.stages == stages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, stat, stages);

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveStatStageChangeImplCopyWith<_$PokemonMoveStatStageChangeImpl>
      get copyWith => __$$PokemonMoveStatStageChangeImplCopyWithImpl<
          _$PokemonMoveStatStageChangeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveStatStageChangeImplToJson(
      this,
    );
  }
}

abstract class _PokemonMoveStatStageChange
    implements PokemonMoveStatStageChange {
  const factory _PokemonMoveStatStageChange(
      {required final PokemonMoveStatId stat,
      required final int stages}) = _$PokemonMoveStatStageChangeImpl;

  factory _PokemonMoveStatStageChange.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveStatStageChangeImpl.fromJson;

  @override
  PokemonMoveStatId get stat;
  @override
  int get stages;

  /// Create a copy of PokemonMoveStatStageChange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveStatStageChangeImplCopyWith<_$PokemonMoveStatStageChangeImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PokemonMoveEffect _$PokemonMoveEffectFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'deal_damage':
      return PokemonMoveEffectDealDamage.fromJson(json);
    case 'fixed_damage':
      return PokemonMoveEffectFixedDamage.fromJson(json);
    case 'multi_hit':
      return PokemonMoveEffectMultiHit.fromJson(json);
    case 'apply_status':
      return PokemonMoveEffectApplyStatus.fromJson(json);
    case 'apply_volatile_status':
      return PokemonMoveEffectApplyVolatileStatus.fromJson(json);
    case 'modify_stats':
      return PokemonMoveEffectModifyStats.fromJson(json);
    case 'heal':
      return PokemonMoveEffectHeal.fromJson(json);
    case 'drain':
      return PokemonMoveEffectDrain.fromJson(json);
    case 'recoil':
      return PokemonMoveEffectRecoil.fromJson(json);
    case 'set_weather':
      return PokemonMoveEffectSetWeather.fromJson(json);
    case 'set_terrain':
      return PokemonMoveEffectSetTerrain.fromJson(json);
    case 'self_switch':
      return PokemonMoveEffectSelfSwitch.fromJson(json);
    case 'force_switch':
      return PokemonMoveEffectForceSwitch.fromJson(json);
    case 'break_protect':
      return PokemonMoveEffectBreakProtect.fromJson(json);
    case 'require_recharge':
      return PokemonMoveEffectRequireRecharge.fromJson(json);
    case 'charge_then_strike':
      return PokemonMoveEffectChargeThenStrike.fromJson(json);
    case 'set_side_condition':
      return PokemonMoveEffectSetSideCondition.fromJson(json);
    case 'set_slot_condition':
      return PokemonMoveEffectSetSlotCondition.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'kind', 'PokemonMoveEffect',
          'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$PokemonMoveEffect {
  PokemonMoveEffectTargetScope get targetScope =>
      throw _privateConstructorUsedError;
  int? get chance => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this PokemonMoveEffect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonMoveEffectCopyWith<PokemonMoveEffect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectCopyWith(
          PokemonMoveEffect value, $Res Function(PokemonMoveEffect) then) =
      _$PokemonMoveEffectCopyWithImpl<$Res, PokemonMoveEffect>;
  @useResult
  $Res call({PokemonMoveEffectTargetScope targetScope, int? chance});
}

/// @nodoc
class _$PokemonMoveEffectCopyWithImpl<$Res, $Val extends PokemonMoveEffect>
    implements $PokemonMoveEffectCopyWith<$Res> {
  _$PokemonMoveEffectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
  }) {
    return _then(_value.copyWith(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PokemonMoveEffectDealDamageImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectDealDamageImplCopyWith(
          _$PokemonMoveEffectDealDamageImpl value,
          $Res Function(_$PokemonMoveEffectDealDamageImpl) then) =
      __$$PokemonMoveEffectDealDamageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PokemonMoveEffectTargetScope targetScope, int? chance});
}

/// @nodoc
class __$$PokemonMoveEffectDealDamageImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectDealDamageImpl>
    implements _$$PokemonMoveEffectDealDamageImplCopyWith<$Res> {
  __$$PokemonMoveEffectDealDamageImplCopyWithImpl(
      _$PokemonMoveEffectDealDamageImpl _value,
      $Res Function(_$PokemonMoveEffectDealDamageImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
  }) {
    return _then(_$PokemonMoveEffectDealDamageImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectDealDamageImpl extends PokemonMoveEffectDealDamage {
  const _$PokemonMoveEffectDealDamageImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      final String? $type})
      : $type = $type ?? 'deal_damage',
        super._();

  factory _$PokemonMoveEffectDealDamageImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectDealDamageImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.dealDamage(targetScope: $targetScope, chance: $chance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectDealDamageImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectDealDamageImplCopyWith<_$PokemonMoveEffectDealDamageImpl>
      get copyWith => __$$PokemonMoveEffectDealDamageImplCopyWithImpl<
          _$PokemonMoveEffectDealDamageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return dealDamage(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return dealDamage?.call(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (dealDamage != null) {
      return dealDamage(targetScope, chance);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return dealDamage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return dealDamage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (dealDamage != null) {
      return dealDamage(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectDealDamageImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectDealDamage extends PokemonMoveEffect {
  const factory PokemonMoveEffectDealDamage(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance}) = _$PokemonMoveEffectDealDamageImpl;
  const PokemonMoveEffectDealDamage._() : super._();

  factory PokemonMoveEffectDealDamage.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectDealDamageImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectDealDamageImplCopyWith<_$PokemonMoveEffectDealDamageImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectFixedDamageImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectFixedDamageImplCopyWith(
          _$PokemonMoveEffectFixedDamageImpl value,
          $Res Function(_$PokemonMoveEffectFixedDamageImpl) then) =
      __$$PokemonMoveEffectFixedDamageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int? value,
      bool usesUserLevel});
}

/// @nodoc
class __$$PokemonMoveEffectFixedDamageImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectFixedDamageImpl>
    implements _$$PokemonMoveEffectFixedDamageImplCopyWith<$Res> {
  __$$PokemonMoveEffectFixedDamageImplCopyWithImpl(
      _$PokemonMoveEffectFixedDamageImpl _value,
      $Res Function(_$PokemonMoveEffectFixedDamageImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? value = freezed,
    Object? usesUserLevel = null,
  }) {
    return _then(_$PokemonMoveEffectFixedDamageImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int?,
      usesUserLevel: null == usesUserLevel
          ? _value.usesUserLevel
          : usesUserLevel // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectFixedDamageImpl extends PokemonMoveEffectFixedDamage {
  const _$PokemonMoveEffectFixedDamageImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      this.value,
      this.usesUserLevel = false,
      final String? $type})
      : $type = $type ?? 'fixed_damage',
        super._();

  factory _$PokemonMoveEffectFixedDamageImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectFixedDamageImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  /// Valeur fixe exacte quand le move inflige un montant constant.
  @override
  final int? value;

  /// Garde-fou minimal pour les cas "fixed damage = niveau du lanceur".
  @override
  @JsonKey()
  final bool usesUserLevel;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.fixedDamage(targetScope: $targetScope, chance: $chance, value: $value, usesUserLevel: $usesUserLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectFixedDamageImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.usesUserLevel, usesUserLevel) ||
                other.usesUserLevel == usesUserLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, value, usesUserLevel);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectFixedDamageImplCopyWith<
          _$PokemonMoveEffectFixedDamageImpl>
      get copyWith => __$$PokemonMoveEffectFixedDamageImplCopyWithImpl<
          _$PokemonMoveEffectFixedDamageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return fixedDamage(targetScope, chance, value, usesUserLevel);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return fixedDamage?.call(targetScope, chance, value, usesUserLevel);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (fixedDamage != null) {
      return fixedDamage(targetScope, chance, value, usesUserLevel);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return fixedDamage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return fixedDamage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (fixedDamage != null) {
      return fixedDamage(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectFixedDamageImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectFixedDamage extends PokemonMoveEffect {
  const factory PokemonMoveEffectFixedDamage(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      final int? value,
      final bool usesUserLevel}) = _$PokemonMoveEffectFixedDamageImpl;
  const PokemonMoveEffectFixedDamage._() : super._();

  factory PokemonMoveEffectFixedDamage.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectFixedDamageImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Valeur fixe exacte quand le move inflige un montant constant.
  int? get value;

  /// Garde-fou minimal pour les cas "fixed damage = niveau du lanceur".
  bool get usesUserLevel;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectFixedDamageImplCopyWith<
          _$PokemonMoveEffectFixedDamageImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectMultiHitImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectMultiHitImplCopyWith(
          _$PokemonMoveEffectMultiHitImpl value,
          $Res Function(_$PokemonMoveEffectMultiHitImpl) then) =
      __$$PokemonMoveEffectMultiHitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int minHits,
      int maxHits});
}

/// @nodoc
class __$$PokemonMoveEffectMultiHitImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectMultiHitImpl>
    implements _$$PokemonMoveEffectMultiHitImplCopyWith<$Res> {
  __$$PokemonMoveEffectMultiHitImplCopyWithImpl(
      _$PokemonMoveEffectMultiHitImpl _value,
      $Res Function(_$PokemonMoveEffectMultiHitImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? minHits = null,
    Object? maxHits = null,
  }) {
    return _then(_$PokemonMoveEffectMultiHitImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      minHits: null == minHits
          ? _value.minHits
          : minHits // ignore: cast_nullable_to_non_nullable
              as int,
      maxHits: null == maxHits
          ? _value.maxHits
          : maxHits // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectMultiHitImpl extends PokemonMoveEffectMultiHit {
  const _$PokemonMoveEffectMultiHitImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      required this.minHits,
      required this.maxHits,
      final String? $type})
      : $type = $type ?? 'multi_hit',
        super._();

  factory _$PokemonMoveEffectMultiHitImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveEffectMultiHitImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final int minHits;
  @override
  final int maxHits;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.multiHit(targetScope: $targetScope, chance: $chance, minHits: $minHits, maxHits: $maxHits)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectMultiHitImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.minHits, minHits) || other.minHits == minHits) &&
            (identical(other.maxHits, maxHits) || other.maxHits == maxHits));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, minHits, maxHits);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectMultiHitImplCopyWith<_$PokemonMoveEffectMultiHitImpl>
      get copyWith => __$$PokemonMoveEffectMultiHitImplCopyWithImpl<
          _$PokemonMoveEffectMultiHitImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return multiHit(targetScope, chance, minHits, maxHits);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return multiHit?.call(targetScope, chance, minHits, maxHits);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (multiHit != null) {
      return multiHit(targetScope, chance, minHits, maxHits);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return multiHit(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return multiHit?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (multiHit != null) {
      return multiHit(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectMultiHitImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectMultiHit extends PokemonMoveEffect {
  const factory PokemonMoveEffectMultiHit(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final int minHits,
      required final int maxHits}) = _$PokemonMoveEffectMultiHitImpl;
  const PokemonMoveEffectMultiHit._() : super._();

  factory PokemonMoveEffectMultiHit.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectMultiHitImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  int get minHits;
  int get maxHits;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectMultiHitImplCopyWith<_$PokemonMoveEffectMultiHitImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectApplyStatusImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectApplyStatusImplCopyWith(
          _$PokemonMoveEffectApplyStatusImpl value,
          $Res Function(_$PokemonMoveEffectApplyStatusImpl) then) =
      __$$PokemonMoveEffectApplyStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope, int? chance, String statusId});
}

/// @nodoc
class __$$PokemonMoveEffectApplyStatusImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectApplyStatusImpl>
    implements _$$PokemonMoveEffectApplyStatusImplCopyWith<$Res> {
  __$$PokemonMoveEffectApplyStatusImplCopyWithImpl(
      _$PokemonMoveEffectApplyStatusImpl _value,
      $Res Function(_$PokemonMoveEffectApplyStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? statusId = null,
  }) {
    return _then(_$PokemonMoveEffectApplyStatusImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      statusId: null == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectApplyStatusImpl extends PokemonMoveEffectApplyStatus {
  const _$PokemonMoveEffectApplyStatusImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      required this.statusId,
      final String? $type})
      : $type = $type ?? 'apply_status',
        super._();

  factory _$PokemonMoveEffectApplyStatusImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectApplyStatusImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String statusId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.applyStatus(targetScope: $targetScope, chance: $chance, statusId: $statusId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectApplyStatusImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.statusId, statusId) ||
                other.statusId == statusId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance, statusId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectApplyStatusImplCopyWith<
          _$PokemonMoveEffectApplyStatusImpl>
      get copyWith => __$$PokemonMoveEffectApplyStatusImplCopyWithImpl<
          _$PokemonMoveEffectApplyStatusImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return applyStatus(targetScope, chance, statusId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return applyStatus?.call(targetScope, chance, statusId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (applyStatus != null) {
      return applyStatus(targetScope, chance, statusId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return applyStatus(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return applyStatus?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (applyStatus != null) {
      return applyStatus(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectApplyStatusImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectApplyStatus extends PokemonMoveEffect {
  const factory PokemonMoveEffectApplyStatus(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final String statusId}) = _$PokemonMoveEffectApplyStatusImpl;
  const PokemonMoveEffectApplyStatus._() : super._();

  factory PokemonMoveEffectApplyStatus.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectApplyStatusImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get statusId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectApplyStatusImplCopyWith<
          _$PokemonMoveEffectApplyStatusImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith(
          _$PokemonMoveEffectApplyVolatileStatusImpl value,
          $Res Function(_$PokemonMoveEffectApplyVolatileStatusImpl) then) =
      __$$PokemonMoveEffectApplyVolatileStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String volatileStatusId});
}

/// @nodoc
class __$$PokemonMoveEffectApplyVolatileStatusImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectApplyVolatileStatusImpl>
    implements _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith<$Res> {
  __$$PokemonMoveEffectApplyVolatileStatusImplCopyWithImpl(
      _$PokemonMoveEffectApplyVolatileStatusImpl _value,
      $Res Function(_$PokemonMoveEffectApplyVolatileStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? volatileStatusId = null,
  }) {
    return _then(_$PokemonMoveEffectApplyVolatileStatusImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      volatileStatusId: null == volatileStatusId
          ? _value.volatileStatusId
          : volatileStatusId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectApplyVolatileStatusImpl
    extends PokemonMoveEffectApplyVolatileStatus {
  const _$PokemonMoveEffectApplyVolatileStatusImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      required this.volatileStatusId,
      final String? $type})
      : $type = $type ?? 'apply_volatile_status',
        super._();

  factory _$PokemonMoveEffectApplyVolatileStatusImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectApplyVolatileStatusImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String volatileStatusId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.applyVolatileStatus(targetScope: $targetScope, chance: $chance, volatileStatusId: $volatileStatusId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectApplyVolatileStatusImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.volatileStatusId, volatileStatusId) ||
                other.volatileStatusId == volatileStatusId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, volatileStatusId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith<
          _$PokemonMoveEffectApplyVolatileStatusImpl>
      get copyWith => __$$PokemonMoveEffectApplyVolatileStatusImplCopyWithImpl<
          _$PokemonMoveEffectApplyVolatileStatusImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return applyVolatileStatus(targetScope, chance, volatileStatusId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return applyVolatileStatus?.call(targetScope, chance, volatileStatusId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (applyVolatileStatus != null) {
      return applyVolatileStatus(targetScope, chance, volatileStatusId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return applyVolatileStatus(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return applyVolatileStatus?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (applyVolatileStatus != null) {
      return applyVolatileStatus(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectApplyVolatileStatusImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectApplyVolatileStatus extends PokemonMoveEffect {
  const factory PokemonMoveEffectApplyVolatileStatus(
          {final PokemonMoveEffectTargetScope targetScope,
          final int? chance,
          required final String volatileStatusId}) =
      _$PokemonMoveEffectApplyVolatileStatusImpl;
  const PokemonMoveEffectApplyVolatileStatus._() : super._();

  factory PokemonMoveEffectApplyVolatileStatus.fromJson(
          Map<String, dynamic> json) =
      _$PokemonMoveEffectApplyVolatileStatusImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get volatileStatusId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectApplyVolatileStatusImplCopyWith<
          _$PokemonMoveEffectApplyVolatileStatusImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectModifyStatsImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectModifyStatsImplCopyWith(
          _$PokemonMoveEffectModifyStatsImpl value,
          $Res Function(_$PokemonMoveEffectModifyStatsImpl) then) =
      __$$PokemonMoveEffectModifyStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      List<PokemonMoveStatStageChange> stageChanges});
}

/// @nodoc
class __$$PokemonMoveEffectModifyStatsImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectModifyStatsImpl>
    implements _$$PokemonMoveEffectModifyStatsImplCopyWith<$Res> {
  __$$PokemonMoveEffectModifyStatsImplCopyWithImpl(
      _$PokemonMoveEffectModifyStatsImpl _value,
      $Res Function(_$PokemonMoveEffectModifyStatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? stageChanges = null,
  }) {
    return _then(_$PokemonMoveEffectModifyStatsImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      stageChanges: null == stageChanges
          ? _value._stageChanges
          : stageChanges // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveStatStageChange>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectModifyStatsImpl extends PokemonMoveEffectModifyStats {
  const _$PokemonMoveEffectModifyStatsImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      final List<PokemonMoveStatStageChange> stageChanges =
          const <PokemonMoveStatStageChange>[],
      final String? $type})
      : _stageChanges = stageChanges,
        $type = $type ?? 'modify_stats',
        super._();

  factory _$PokemonMoveEffectModifyStatsImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectModifyStatsImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  final List<PokemonMoveStatStageChange> _stageChanges;
  @override
  @JsonKey()
  List<PokemonMoveStatStageChange> get stageChanges {
    if (_stageChanges is EqualUnmodifiableListView) return _stageChanges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stageChanges);
  }

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.modifyStats(targetScope: $targetScope, chance: $chance, stageChanges: $stageChanges)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectModifyStatsImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            const DeepCollectionEquality()
                .equals(other._stageChanges, _stageChanges));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance,
      const DeepCollectionEquality().hash(_stageChanges));

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectModifyStatsImplCopyWith<
          _$PokemonMoveEffectModifyStatsImpl>
      get copyWith => __$$PokemonMoveEffectModifyStatsImplCopyWithImpl<
          _$PokemonMoveEffectModifyStatsImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return modifyStats(targetScope, chance, stageChanges);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return modifyStats?.call(targetScope, chance, stageChanges);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (modifyStats != null) {
      return modifyStats(targetScope, chance, stageChanges);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return modifyStats(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return modifyStats?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (modifyStats != null) {
      return modifyStats(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectModifyStatsImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectModifyStats extends PokemonMoveEffect {
  const factory PokemonMoveEffectModifyStats(
          {final PokemonMoveEffectTargetScope targetScope,
          final int? chance,
          final List<PokemonMoveStatStageChange> stageChanges}) =
      _$PokemonMoveEffectModifyStatsImpl;
  const PokemonMoveEffectModifyStats._() : super._();

  factory PokemonMoveEffectModifyStats.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectModifyStatsImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  List<PokemonMoveStatStageChange> get stageChanges;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectModifyStatsImplCopyWith<
          _$PokemonMoveEffectModifyStatsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectHealImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectHealImplCopyWith(
          _$PokemonMoveEffectHealImpl value,
          $Res Function(_$PokemonMoveEffectHealImpl) then) =
      __$$PokemonMoveEffectHealImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int numerator,
      int denominator});
}

/// @nodoc
class __$$PokemonMoveEffectHealImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res, _$PokemonMoveEffectHealImpl>
    implements _$$PokemonMoveEffectHealImplCopyWith<$Res> {
  __$$PokemonMoveEffectHealImplCopyWithImpl(_$PokemonMoveEffectHealImpl _value,
      $Res Function(_$PokemonMoveEffectHealImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? numerator = null,
    Object? denominator = null,
  }) {
    return _then(_$PokemonMoveEffectHealImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      numerator: null == numerator
          ? _value.numerator
          : numerator // ignore: cast_nullable_to_non_nullable
              as int,
      denominator: null == denominator
          ? _value.denominator
          : denominator // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectHealImpl extends PokemonMoveEffectHeal {
  const _$PokemonMoveEffectHealImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      required this.numerator,
      required this.denominator,
      final String? $type})
      : $type = $type ?? 'heal',
        super._();

  factory _$PokemonMoveEffectHealImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveEffectHealImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final int numerator;
  @override
  final int denominator;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.heal(targetScope: $targetScope, chance: $chance, numerator: $numerator, denominator: $denominator)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectHealImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.numerator, numerator) ||
                other.numerator == numerator) &&
            (identical(other.denominator, denominator) ||
                other.denominator == denominator));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, numerator, denominator);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectHealImplCopyWith<_$PokemonMoveEffectHealImpl>
      get copyWith => __$$PokemonMoveEffectHealImplCopyWithImpl<
          _$PokemonMoveEffectHealImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return heal(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return heal?.call(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (heal != null) {
      return heal(targetScope, chance, numerator, denominator);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return heal(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return heal?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (heal != null) {
      return heal(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectHealImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectHeal extends PokemonMoveEffect {
  const factory PokemonMoveEffectHeal(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final int numerator,
      required final int denominator}) = _$PokemonMoveEffectHealImpl;
  const PokemonMoveEffectHeal._() : super._();

  factory PokemonMoveEffectHeal.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectHealImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  int get numerator;
  int get denominator;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectHealImplCopyWith<_$PokemonMoveEffectHealImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectDrainImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectDrainImplCopyWith(
          _$PokemonMoveEffectDrainImpl value,
          $Res Function(_$PokemonMoveEffectDrainImpl) then) =
      __$$PokemonMoveEffectDrainImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int numerator,
      int denominator});
}

/// @nodoc
class __$$PokemonMoveEffectDrainImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res, _$PokemonMoveEffectDrainImpl>
    implements _$$PokemonMoveEffectDrainImplCopyWith<$Res> {
  __$$PokemonMoveEffectDrainImplCopyWithImpl(
      _$PokemonMoveEffectDrainImpl _value,
      $Res Function(_$PokemonMoveEffectDrainImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? numerator = null,
    Object? denominator = null,
  }) {
    return _then(_$PokemonMoveEffectDrainImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      numerator: null == numerator
          ? _value.numerator
          : numerator // ignore: cast_nullable_to_non_nullable
              as int,
      denominator: null == denominator
          ? _value.denominator
          : denominator // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectDrainImpl extends PokemonMoveEffectDrain {
  const _$PokemonMoveEffectDrainImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      required this.numerator,
      required this.denominator,
      final String? $type})
      : $type = $type ?? 'drain',
        super._();

  factory _$PokemonMoveEffectDrainImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveEffectDrainImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final int numerator;
  @override
  final int denominator;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.drain(targetScope: $targetScope, chance: $chance, numerator: $numerator, denominator: $denominator)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectDrainImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.numerator, numerator) ||
                other.numerator == numerator) &&
            (identical(other.denominator, denominator) ||
                other.denominator == denominator));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, numerator, denominator);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectDrainImplCopyWith<_$PokemonMoveEffectDrainImpl>
      get copyWith => __$$PokemonMoveEffectDrainImplCopyWithImpl<
          _$PokemonMoveEffectDrainImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return drain(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return drain?.call(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (drain != null) {
      return drain(targetScope, chance, numerator, denominator);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return drain(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return drain?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (drain != null) {
      return drain(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectDrainImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectDrain extends PokemonMoveEffect {
  const factory PokemonMoveEffectDrain(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final int numerator,
      required final int denominator}) = _$PokemonMoveEffectDrainImpl;
  const PokemonMoveEffectDrain._() : super._();

  factory PokemonMoveEffectDrain.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectDrainImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  int get numerator;
  int get denominator;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectDrainImplCopyWith<_$PokemonMoveEffectDrainImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectRecoilImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectRecoilImplCopyWith(
          _$PokemonMoveEffectRecoilImpl value,
          $Res Function(_$PokemonMoveEffectRecoilImpl) then) =
      __$$PokemonMoveEffectRecoilImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      int numerator,
      int denominator});
}

/// @nodoc
class __$$PokemonMoveEffectRecoilImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res, _$PokemonMoveEffectRecoilImpl>
    implements _$$PokemonMoveEffectRecoilImplCopyWith<$Res> {
  __$$PokemonMoveEffectRecoilImplCopyWithImpl(
      _$PokemonMoveEffectRecoilImpl _value,
      $Res Function(_$PokemonMoveEffectRecoilImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? numerator = null,
    Object? denominator = null,
  }) {
    return _then(_$PokemonMoveEffectRecoilImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      numerator: null == numerator
          ? _value.numerator
          : numerator // ignore: cast_nullable_to_non_nullable
              as int,
      denominator: null == denominator
          ? _value.denominator
          : denominator // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectRecoilImpl extends PokemonMoveEffectRecoil {
  const _$PokemonMoveEffectRecoilImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      required this.numerator,
      required this.denominator,
      final String? $type})
      : $type = $type ?? 'recoil',
        super._();

  factory _$PokemonMoveEffectRecoilImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveEffectRecoilImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final int numerator;
  @override
  final int denominator;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.recoil(targetScope: $targetScope, chance: $chance, numerator: $numerator, denominator: $denominator)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectRecoilImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.numerator, numerator) ||
                other.numerator == numerator) &&
            (identical(other.denominator, denominator) ||
                other.denominator == denominator));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, numerator, denominator);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectRecoilImplCopyWith<_$PokemonMoveEffectRecoilImpl>
      get copyWith => __$$PokemonMoveEffectRecoilImplCopyWithImpl<
          _$PokemonMoveEffectRecoilImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return recoil(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return recoil?.call(targetScope, chance, numerator, denominator);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (recoil != null) {
      return recoil(targetScope, chance, numerator, denominator);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return recoil(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return recoil?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (recoil != null) {
      return recoil(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectRecoilImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectRecoil extends PokemonMoveEffect {
  const factory PokemonMoveEffectRecoil(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final int numerator,
      required final int denominator}) = _$PokemonMoveEffectRecoilImpl;
  const PokemonMoveEffectRecoil._() : super._();

  factory PokemonMoveEffectRecoil.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectRecoilImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  int get numerator;
  int get denominator;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectRecoilImplCopyWith<_$PokemonMoveEffectRecoilImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSetWeatherImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSetWeatherImplCopyWith(
          _$PokemonMoveEffectSetWeatherImpl value,
          $Res Function(_$PokemonMoveEffectSetWeatherImpl) then) =
      __$$PokemonMoveEffectSetWeatherImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String weatherId});
}

/// @nodoc
class __$$PokemonMoveEffectSetWeatherImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSetWeatherImpl>
    implements _$$PokemonMoveEffectSetWeatherImplCopyWith<$Res> {
  __$$PokemonMoveEffectSetWeatherImplCopyWithImpl(
      _$PokemonMoveEffectSetWeatherImpl _value,
      $Res Function(_$PokemonMoveEffectSetWeatherImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? weatherId = null,
  }) {
    return _then(_$PokemonMoveEffectSetWeatherImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      weatherId: null == weatherId
          ? _value.weatherId
          : weatherId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSetWeatherImpl extends PokemonMoveEffectSetWeather {
  const _$PokemonMoveEffectSetWeatherImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.field,
      this.chance,
      required this.weatherId,
      final String? $type})
      : $type = $type ?? 'set_weather',
        super._();

  factory _$PokemonMoveEffectSetWeatherImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSetWeatherImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String weatherId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.setWeather(targetScope: $targetScope, chance: $chance, weatherId: $weatherId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSetWeatherImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.weatherId, weatherId) ||
                other.weatherId == weatherId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance, weatherId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSetWeatherImplCopyWith<_$PokemonMoveEffectSetWeatherImpl>
      get copyWith => __$$PokemonMoveEffectSetWeatherImplCopyWithImpl<
          _$PokemonMoveEffectSetWeatherImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return setWeather(targetScope, chance, weatherId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return setWeather?.call(targetScope, chance, weatherId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (setWeather != null) {
      return setWeather(targetScope, chance, weatherId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return setWeather(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return setWeather?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (setWeather != null) {
      return setWeather(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSetWeatherImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSetWeather extends PokemonMoveEffect {
  const factory PokemonMoveEffectSetWeather(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final String weatherId}) = _$PokemonMoveEffectSetWeatherImpl;
  const PokemonMoveEffectSetWeather._() : super._();

  factory PokemonMoveEffectSetWeather.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectSetWeatherImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get weatherId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSetWeatherImplCopyWith<_$PokemonMoveEffectSetWeatherImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSetTerrainImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSetTerrainImplCopyWith(
          _$PokemonMoveEffectSetTerrainImpl value,
          $Res Function(_$PokemonMoveEffectSetTerrainImpl) then) =
      __$$PokemonMoveEffectSetTerrainImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String terrainId});
}

/// @nodoc
class __$$PokemonMoveEffectSetTerrainImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSetTerrainImpl>
    implements _$$PokemonMoveEffectSetTerrainImplCopyWith<$Res> {
  __$$PokemonMoveEffectSetTerrainImplCopyWithImpl(
      _$PokemonMoveEffectSetTerrainImpl _value,
      $Res Function(_$PokemonMoveEffectSetTerrainImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? terrainId = null,
  }) {
    return _then(_$PokemonMoveEffectSetTerrainImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      terrainId: null == terrainId
          ? _value.terrainId
          : terrainId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSetTerrainImpl extends PokemonMoveEffectSetTerrain {
  const _$PokemonMoveEffectSetTerrainImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.field,
      this.chance,
      required this.terrainId,
      final String? $type})
      : $type = $type ?? 'set_terrain',
        super._();

  factory _$PokemonMoveEffectSetTerrainImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSetTerrainImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String terrainId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.setTerrain(targetScope: $targetScope, chance: $chance, terrainId: $terrainId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSetTerrainImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.terrainId, terrainId) ||
                other.terrainId == terrainId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance, terrainId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSetTerrainImplCopyWith<_$PokemonMoveEffectSetTerrainImpl>
      get copyWith => __$$PokemonMoveEffectSetTerrainImplCopyWithImpl<
          _$PokemonMoveEffectSetTerrainImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return setTerrain(targetScope, chance, terrainId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return setTerrain?.call(targetScope, chance, terrainId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (setTerrain != null) {
      return setTerrain(targetScope, chance, terrainId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return setTerrain(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return setTerrain?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (setTerrain != null) {
      return setTerrain(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSetTerrainImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSetTerrain extends PokemonMoveEffect {
  const factory PokemonMoveEffectSetTerrain(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      required final String terrainId}) = _$PokemonMoveEffectSetTerrainImpl;
  const PokemonMoveEffectSetTerrain._() : super._();

  factory PokemonMoveEffectSetTerrain.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectSetTerrainImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get terrainId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSetTerrainImplCopyWith<_$PokemonMoveEffectSetTerrainImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSelfSwitchImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSelfSwitchImplCopyWith(
          _$PokemonMoveEffectSelfSwitchImpl value,
          $Res Function(_$PokemonMoveEffectSelfSwitchImpl) then) =
      __$$PokemonMoveEffectSelfSwitchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope, int? chance, String? mode});
}

/// @nodoc
class __$$PokemonMoveEffectSelfSwitchImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSelfSwitchImpl>
    implements _$$PokemonMoveEffectSelfSwitchImplCopyWith<$Res> {
  __$$PokemonMoveEffectSelfSwitchImplCopyWithImpl(
      _$PokemonMoveEffectSelfSwitchImpl _value,
      $Res Function(_$PokemonMoveEffectSelfSwitchImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? mode = freezed,
  }) {
    return _then(_$PokemonMoveEffectSelfSwitchImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      mode: freezed == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSelfSwitchImpl extends PokemonMoveEffectSelfSwitch {
  const _$PokemonMoveEffectSelfSwitchImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      this.mode,
      final String? $type})
      : $type = $type ?? 'self_switch',
        super._();

  factory _$PokemonMoveEffectSelfSwitchImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSelfSwitchImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  /// Exemples futurs : `copyvolatile`, `shedtail`, `simple`.
  @override
  final String? mode;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.selfSwitch(targetScope: $targetScope, chance: $chance, mode: $mode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSelfSwitchImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.mode, mode) || other.mode == mode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance, mode);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSelfSwitchImplCopyWith<_$PokemonMoveEffectSelfSwitchImpl>
      get copyWith => __$$PokemonMoveEffectSelfSwitchImplCopyWithImpl<
          _$PokemonMoveEffectSelfSwitchImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return selfSwitch(targetScope, chance, mode);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return selfSwitch?.call(targetScope, chance, mode);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (selfSwitch != null) {
      return selfSwitch(targetScope, chance, mode);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return selfSwitch(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return selfSwitch?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (selfSwitch != null) {
      return selfSwitch(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSelfSwitchImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSelfSwitch extends PokemonMoveEffect {
  const factory PokemonMoveEffectSelfSwitch(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      final String? mode}) = _$PokemonMoveEffectSelfSwitchImpl;
  const PokemonMoveEffectSelfSwitch._() : super._();

  factory PokemonMoveEffectSelfSwitch.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectSelfSwitchImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Exemples futurs : `copyvolatile`, `shedtail`, `simple`.
  String? get mode;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSelfSwitchImplCopyWith<_$PokemonMoveEffectSelfSwitchImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectForceSwitchImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectForceSwitchImplCopyWith(
          _$PokemonMoveEffectForceSwitchImpl value,
          $Res Function(_$PokemonMoveEffectForceSwitchImpl) then) =
      __$$PokemonMoveEffectForceSwitchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PokemonMoveEffectTargetScope targetScope, int? chance});
}

/// @nodoc
class __$$PokemonMoveEffectForceSwitchImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectForceSwitchImpl>
    implements _$$PokemonMoveEffectForceSwitchImplCopyWith<$Res> {
  __$$PokemonMoveEffectForceSwitchImplCopyWithImpl(
      _$PokemonMoveEffectForceSwitchImpl _value,
      $Res Function(_$PokemonMoveEffectForceSwitchImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
  }) {
    return _then(_$PokemonMoveEffectForceSwitchImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectForceSwitchImpl extends PokemonMoveEffectForceSwitch {
  const _$PokemonMoveEffectForceSwitchImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      final String? $type})
      : $type = $type ?? 'force_switch',
        super._();

  factory _$PokemonMoveEffectForceSwitchImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectForceSwitchImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.forceSwitch(targetScope: $targetScope, chance: $chance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectForceSwitchImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectForceSwitchImplCopyWith<
          _$PokemonMoveEffectForceSwitchImpl>
      get copyWith => __$$PokemonMoveEffectForceSwitchImplCopyWithImpl<
          _$PokemonMoveEffectForceSwitchImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return forceSwitch(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return forceSwitch?.call(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (forceSwitch != null) {
      return forceSwitch(targetScope, chance);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return forceSwitch(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return forceSwitch?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (forceSwitch != null) {
      return forceSwitch(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectForceSwitchImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectForceSwitch extends PokemonMoveEffect {
  const factory PokemonMoveEffectForceSwitch(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance}) = _$PokemonMoveEffectForceSwitchImpl;
  const PokemonMoveEffectForceSwitch._() : super._();

  factory PokemonMoveEffectForceSwitch.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectForceSwitchImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectForceSwitchImplCopyWith<
          _$PokemonMoveEffectForceSwitchImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectBreakProtectImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectBreakProtectImplCopyWith(
          _$PokemonMoveEffectBreakProtectImpl value,
          $Res Function(_$PokemonMoveEffectBreakProtectImpl) then) =
      __$$PokemonMoveEffectBreakProtectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PokemonMoveEffectTargetScope targetScope, int? chance});
}

/// @nodoc
class __$$PokemonMoveEffectBreakProtectImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectBreakProtectImpl>
    implements _$$PokemonMoveEffectBreakProtectImplCopyWith<$Res> {
  __$$PokemonMoveEffectBreakProtectImplCopyWithImpl(
      _$PokemonMoveEffectBreakProtectImpl _value,
      $Res Function(_$PokemonMoveEffectBreakProtectImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
  }) {
    return _then(_$PokemonMoveEffectBreakProtectImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectBreakProtectImpl
    extends PokemonMoveEffectBreakProtect {
  const _$PokemonMoveEffectBreakProtectImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.target,
      this.chance,
      final String? $type})
      : $type = $type ?? 'break_protect',
        super._();

  factory _$PokemonMoveEffectBreakProtectImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectBreakProtectImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.breakProtect(targetScope: $targetScope, chance: $chance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectBreakProtectImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectBreakProtectImplCopyWith<
          _$PokemonMoveEffectBreakProtectImpl>
      get copyWith => __$$PokemonMoveEffectBreakProtectImplCopyWithImpl<
          _$PokemonMoveEffectBreakProtectImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return breakProtect(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return breakProtect?.call(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (breakProtect != null) {
      return breakProtect(targetScope, chance);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return breakProtect(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return breakProtect?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (breakProtect != null) {
      return breakProtect(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectBreakProtectImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectBreakProtect extends PokemonMoveEffect {
  const factory PokemonMoveEffectBreakProtect(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance}) = _$PokemonMoveEffectBreakProtectImpl;
  const PokemonMoveEffectBreakProtect._() : super._();

  factory PokemonMoveEffectBreakProtect.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectBreakProtectImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectBreakProtectImplCopyWith<
          _$PokemonMoveEffectBreakProtectImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectRequireRechargeImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectRequireRechargeImplCopyWith(
          _$PokemonMoveEffectRequireRechargeImpl value,
          $Res Function(_$PokemonMoveEffectRequireRechargeImpl) then) =
      __$$PokemonMoveEffectRequireRechargeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PokemonMoveEffectTargetScope targetScope, int? chance});
}

/// @nodoc
class __$$PokemonMoveEffectRequireRechargeImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectRequireRechargeImpl>
    implements _$$PokemonMoveEffectRequireRechargeImplCopyWith<$Res> {
  __$$PokemonMoveEffectRequireRechargeImplCopyWithImpl(
      _$PokemonMoveEffectRequireRechargeImpl _value,
      $Res Function(_$PokemonMoveEffectRequireRechargeImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
  }) {
    return _then(_$PokemonMoveEffectRequireRechargeImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectRequireRechargeImpl
    extends PokemonMoveEffectRequireRecharge {
  const _$PokemonMoveEffectRequireRechargeImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      final String? $type})
      : $type = $type ?? 'require_recharge',
        super._();

  factory _$PokemonMoveEffectRequireRechargeImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectRequireRechargeImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.requireRecharge(targetScope: $targetScope, chance: $chance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectRequireRechargeImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, targetScope, chance);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectRequireRechargeImplCopyWith<
          _$PokemonMoveEffectRequireRechargeImpl>
      get copyWith => __$$PokemonMoveEffectRequireRechargeImplCopyWithImpl<
          _$PokemonMoveEffectRequireRechargeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return requireRecharge(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return requireRecharge?.call(targetScope, chance);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (requireRecharge != null) {
      return requireRecharge(targetScope, chance);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return requireRecharge(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return requireRecharge?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (requireRecharge != null) {
      return requireRecharge(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectRequireRechargeImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectRequireRecharge extends PokemonMoveEffect {
  const factory PokemonMoveEffectRequireRecharge(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance}) = _$PokemonMoveEffectRequireRechargeImpl;
  const PokemonMoveEffectRequireRecharge._() : super._();

  factory PokemonMoveEffectRequireRecharge.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveEffectRequireRechargeImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectRequireRechargeImplCopyWith<
          _$PokemonMoveEffectRequireRechargeImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectChargeThenStrikeImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectChargeThenStrikeImplCopyWith(
          _$PokemonMoveEffectChargeThenStrikeImpl value,
          $Res Function(_$PokemonMoveEffectChargeThenStrikeImpl) then) =
      __$$PokemonMoveEffectChargeThenStrikeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String? chargeStateId});
}

/// @nodoc
class __$$PokemonMoveEffectChargeThenStrikeImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectChargeThenStrikeImpl>
    implements _$$PokemonMoveEffectChargeThenStrikeImplCopyWith<$Res> {
  __$$PokemonMoveEffectChargeThenStrikeImplCopyWithImpl(
      _$PokemonMoveEffectChargeThenStrikeImpl _value,
      $Res Function(_$PokemonMoveEffectChargeThenStrikeImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? chargeStateId = freezed,
  }) {
    return _then(_$PokemonMoveEffectChargeThenStrikeImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      chargeStateId: freezed == chargeStateId
          ? _value.chargeStateId
          : chargeStateId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectChargeThenStrikeImpl
    extends PokemonMoveEffectChargeThenStrike {
  const _$PokemonMoveEffectChargeThenStrikeImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.self,
      this.chance,
      this.chargeStateId,
      final String? $type})
      : $type = $type ?? 'charge_then_strike',
        super._();

  factory _$PokemonMoveEffectChargeThenStrikeImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectChargeThenStrikeImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;

  /// Permet plus tard d'associer un volatile ou un marqueur de charge.
  @override
  final String? chargeStateId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.chargeThenStrike(targetScope: $targetScope, chance: $chance, chargeStateId: $chargeStateId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectChargeThenStrikeImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.chargeStateId, chargeStateId) ||
                other.chargeStateId == chargeStateId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, chargeStateId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectChargeThenStrikeImplCopyWith<
          _$PokemonMoveEffectChargeThenStrikeImpl>
      get copyWith => __$$PokemonMoveEffectChargeThenStrikeImplCopyWithImpl<
          _$PokemonMoveEffectChargeThenStrikeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return chargeThenStrike(targetScope, chance, chargeStateId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return chargeThenStrike?.call(targetScope, chance, chargeStateId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (chargeThenStrike != null) {
      return chargeThenStrike(targetScope, chance, chargeStateId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return chargeThenStrike(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return chargeThenStrike?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (chargeThenStrike != null) {
      return chargeThenStrike(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectChargeThenStrikeImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectChargeThenStrike extends PokemonMoveEffect {
  const factory PokemonMoveEffectChargeThenStrike(
      {final PokemonMoveEffectTargetScope targetScope,
      final int? chance,
      final String? chargeStateId}) = _$PokemonMoveEffectChargeThenStrikeImpl;
  const PokemonMoveEffectChargeThenStrike._() : super._();

  factory PokemonMoveEffectChargeThenStrike.fromJson(
          Map<String, dynamic> json) =
      _$PokemonMoveEffectChargeThenStrikeImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;

  /// Permet plus tard d'associer un volatile ou un marqueur de charge.
  String? get chargeStateId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectChargeThenStrikeImplCopyWith<
          _$PokemonMoveEffectChargeThenStrikeImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSetSideConditionImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSetSideConditionImplCopyWith(
          _$PokemonMoveEffectSetSideConditionImpl value,
          $Res Function(_$PokemonMoveEffectSetSideConditionImpl) then) =
      __$$PokemonMoveEffectSetSideConditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String conditionId});
}

/// @nodoc
class __$$PokemonMoveEffectSetSideConditionImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSetSideConditionImpl>
    implements _$$PokemonMoveEffectSetSideConditionImplCopyWith<$Res> {
  __$$PokemonMoveEffectSetSideConditionImplCopyWithImpl(
      _$PokemonMoveEffectSetSideConditionImpl _value,
      $Res Function(_$PokemonMoveEffectSetSideConditionImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? conditionId = null,
  }) {
    return _then(_$PokemonMoveEffectSetSideConditionImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      conditionId: null == conditionId
          ? _value.conditionId
          : conditionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSetSideConditionImpl
    extends PokemonMoveEffectSetSideCondition {
  const _$PokemonMoveEffectSetSideConditionImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.foeSide,
      this.chance,
      required this.conditionId,
      final String? $type})
      : $type = $type ?? 'set_side_condition',
        super._();

  factory _$PokemonMoveEffectSetSideConditionImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSetSideConditionImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String conditionId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.setSideCondition(targetScope: $targetScope, chance: $chance, conditionId: $conditionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSetSideConditionImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.conditionId, conditionId) ||
                other.conditionId == conditionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, conditionId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSetSideConditionImplCopyWith<
          _$PokemonMoveEffectSetSideConditionImpl>
      get copyWith => __$$PokemonMoveEffectSetSideConditionImplCopyWithImpl<
          _$PokemonMoveEffectSetSideConditionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return setSideCondition(targetScope, chance, conditionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return setSideCondition?.call(targetScope, chance, conditionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (setSideCondition != null) {
      return setSideCondition(targetScope, chance, conditionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return setSideCondition(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return setSideCondition?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (setSideCondition != null) {
      return setSideCondition(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSetSideConditionImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSetSideCondition extends PokemonMoveEffect {
  const factory PokemonMoveEffectSetSideCondition(
          {final PokemonMoveEffectTargetScope targetScope,
          final int? chance,
          required final String conditionId}) =
      _$PokemonMoveEffectSetSideConditionImpl;
  const PokemonMoveEffectSetSideCondition._() : super._();

  factory PokemonMoveEffectSetSideCondition.fromJson(
          Map<String, dynamic> json) =
      _$PokemonMoveEffectSetSideConditionImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get conditionId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSetSideConditionImplCopyWith<
          _$PokemonMoveEffectSetSideConditionImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveEffectSetSlotConditionImplCopyWith<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  factory _$$PokemonMoveEffectSetSlotConditionImplCopyWith(
          _$PokemonMoveEffectSetSlotConditionImpl value,
          $Res Function(_$PokemonMoveEffectSetSlotConditionImpl) then) =
      __$$PokemonMoveEffectSetSlotConditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PokemonMoveEffectTargetScope targetScope,
      int? chance,
      String conditionId});
}

/// @nodoc
class __$$PokemonMoveEffectSetSlotConditionImplCopyWithImpl<$Res>
    extends _$PokemonMoveEffectCopyWithImpl<$Res,
        _$PokemonMoveEffectSetSlotConditionImpl>
    implements _$$PokemonMoveEffectSetSlotConditionImplCopyWith<$Res> {
  __$$PokemonMoveEffectSetSlotConditionImplCopyWithImpl(
      _$PokemonMoveEffectSetSlotConditionImpl _value,
      $Res Function(_$PokemonMoveEffectSetSlotConditionImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetScope = null,
    Object? chance = freezed,
    Object? conditionId = null,
  }) {
    return _then(_$PokemonMoveEffectSetSlotConditionImpl(
      targetScope: null == targetScope
          ? _value.targetScope
          : targetScope // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEffectTargetScope,
      chance: freezed == chance
          ? _value.chance
          : chance // ignore: cast_nullable_to_non_nullable
              as int?,
      conditionId: null == conditionId
          ? _value.conditionId
          : conditionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveEffectSetSlotConditionImpl
    extends PokemonMoveEffectSetSlotCondition {
  const _$PokemonMoveEffectSetSlotConditionImpl(
      {this.targetScope = PokemonMoveEffectTargetScope.slot,
      this.chance,
      required this.conditionId,
      final String? $type})
      : $type = $type ?? 'set_slot_condition',
        super._();

  factory _$PokemonMoveEffectSetSlotConditionImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveEffectSetSlotConditionImplFromJson(json);

  @override
  @JsonKey()
  final PokemonMoveEffectTargetScope targetScope;
  @override
  final int? chance;
  @override
  final String conditionId;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveEffect.setSlotCondition(targetScope: $targetScope, chance: $chance, conditionId: $conditionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveEffectSetSlotConditionImpl &&
            (identical(other.targetScope, targetScope) ||
                other.targetScope == targetScope) &&
            (identical(other.chance, chance) || other.chance == chance) &&
            (identical(other.conditionId, conditionId) ||
                other.conditionId == conditionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, targetScope, chance, conditionId);

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveEffectSetSlotConditionImplCopyWith<
          _$PokemonMoveEffectSetSlotConditionImpl>
      get copyWith => __$$PokemonMoveEffectSetSlotConditionImplCopyWithImpl<
          _$PokemonMoveEffectSetSlotConditionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        dealDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int? value, bool usesUserLevel)
        fixedDamage,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int minHits, int maxHits)
        multiHit,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String statusId)
        applyStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String volatileStatusId)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, List<PokemonMoveStatStageChange> stageChanges)
        modifyStats,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        heal,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        drain,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, int numerator, int denominator)
        recoil,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String weatherId)
        setWeather,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String terrainId)
        setTerrain,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance, String? mode)
        selfSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        forceSwitch,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        breakProtect,
    required TResult Function(
            PokemonMoveEffectTargetScope targetScope, int? chance)
        requireRecharge,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String? chargeStateId)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSideCondition,
    required TResult Function(PokemonMoveEffectTargetScope targetScope,
            int? chance, String conditionId)
        setSlotCondition,
  }) {
    return setSlotCondition(targetScope, chance, conditionId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
  }) {
    return setSlotCondition?.call(targetScope, chance, conditionId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        dealDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int? value, bool usesUserLevel)?
        fixedDamage,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int minHits, int maxHits)?
        multiHit,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String statusId)?
        applyStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String volatileStatusId)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            List<PokemonMoveStatStageChange> stageChanges)?
        modifyStats,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        heal,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        drain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            int numerator, int denominator)?
        recoil,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String weatherId)?
        setWeather,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String terrainId)?
        setTerrain,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? mode)?
        selfSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        forceSwitch,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        breakProtect,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance)?
        requireRecharge,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String? chargeStateId)?
        chargeThenStrike,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSideCondition,
    TResult Function(PokemonMoveEffectTargetScope targetScope, int? chance,
            String conditionId)?
        setSlotCondition,
    required TResult orElse(),
  }) {
    if (setSlotCondition != null) {
      return setSlotCondition(targetScope, chance, conditionId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveEffectDealDamage value) dealDamage,
    required TResult Function(PokemonMoveEffectFixedDamage value) fixedDamage,
    required TResult Function(PokemonMoveEffectMultiHit value) multiHit,
    required TResult Function(PokemonMoveEffectApplyStatus value) applyStatus,
    required TResult Function(PokemonMoveEffectApplyVolatileStatus value)
        applyVolatileStatus,
    required TResult Function(PokemonMoveEffectModifyStats value) modifyStats,
    required TResult Function(PokemonMoveEffectHeal value) heal,
    required TResult Function(PokemonMoveEffectDrain value) drain,
    required TResult Function(PokemonMoveEffectRecoil value) recoil,
    required TResult Function(PokemonMoveEffectSetWeather value) setWeather,
    required TResult Function(PokemonMoveEffectSetTerrain value) setTerrain,
    required TResult Function(PokemonMoveEffectSelfSwitch value) selfSwitch,
    required TResult Function(PokemonMoveEffectForceSwitch value) forceSwitch,
    required TResult Function(PokemonMoveEffectBreakProtect value) breakProtect,
    required TResult Function(PokemonMoveEffectRequireRecharge value)
        requireRecharge,
    required TResult Function(PokemonMoveEffectChargeThenStrike value)
        chargeThenStrike,
    required TResult Function(PokemonMoveEffectSetSideCondition value)
        setSideCondition,
    required TResult Function(PokemonMoveEffectSetSlotCondition value)
        setSlotCondition,
  }) {
    return setSlotCondition(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult? Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult? Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult? Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult? Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult? Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult? Function(PokemonMoveEffectHeal value)? heal,
    TResult? Function(PokemonMoveEffectDrain value)? drain,
    TResult? Function(PokemonMoveEffectRecoil value)? recoil,
    TResult? Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult? Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult? Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult? Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult? Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult? Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult? Function(PokemonMoveEffectChargeThenStrike value)?
        chargeThenStrike,
    TResult? Function(PokemonMoveEffectSetSideCondition value)?
        setSideCondition,
    TResult? Function(PokemonMoveEffectSetSlotCondition value)?
        setSlotCondition,
  }) {
    return setSlotCondition?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveEffectDealDamage value)? dealDamage,
    TResult Function(PokemonMoveEffectFixedDamage value)? fixedDamage,
    TResult Function(PokemonMoveEffectMultiHit value)? multiHit,
    TResult Function(PokemonMoveEffectApplyStatus value)? applyStatus,
    TResult Function(PokemonMoveEffectApplyVolatileStatus value)?
        applyVolatileStatus,
    TResult Function(PokemonMoveEffectModifyStats value)? modifyStats,
    TResult Function(PokemonMoveEffectHeal value)? heal,
    TResult Function(PokemonMoveEffectDrain value)? drain,
    TResult Function(PokemonMoveEffectRecoil value)? recoil,
    TResult Function(PokemonMoveEffectSetWeather value)? setWeather,
    TResult Function(PokemonMoveEffectSetTerrain value)? setTerrain,
    TResult Function(PokemonMoveEffectSelfSwitch value)? selfSwitch,
    TResult Function(PokemonMoveEffectForceSwitch value)? forceSwitch,
    TResult Function(PokemonMoveEffectBreakProtect value)? breakProtect,
    TResult Function(PokemonMoveEffectRequireRecharge value)? requireRecharge,
    TResult Function(PokemonMoveEffectChargeThenStrike value)? chargeThenStrike,
    TResult Function(PokemonMoveEffectSetSideCondition value)? setSideCondition,
    TResult Function(PokemonMoveEffectSetSlotCondition value)? setSlotCondition,
    required TResult orElse(),
  }) {
    if (setSlotCondition != null) {
      return setSlotCondition(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveEffectSetSlotConditionImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveEffectSetSlotCondition extends PokemonMoveEffect {
  const factory PokemonMoveEffectSetSlotCondition(
          {final PokemonMoveEffectTargetScope targetScope,
          final int? chance,
          required final String conditionId}) =
      _$PokemonMoveEffectSetSlotConditionImpl;
  const PokemonMoveEffectSetSlotCondition._() : super._();

  factory PokemonMoveEffectSetSlotCondition.fromJson(
          Map<String, dynamic> json) =
      _$PokemonMoveEffectSetSlotConditionImpl.fromJson;

  @override
  PokemonMoveEffectTargetScope get targetScope;
  @override
  int? get chance;
  String get conditionId;

  /// Create a copy of PokemonMoveEffect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveEffectSetSlotConditionImplCopyWith<
          _$PokemonMoveEffectSetSlotConditionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
