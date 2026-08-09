// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pokemon_move_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PokemonMoveStatStageChange {

 PokemonMoveStatId get stat; int get stages;
/// Create a copy of PokemonMoveStatStageChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveStatStageChangeCopyWith<PokemonMoveStatStageChange> get copyWith => _$PokemonMoveStatStageChangeCopyWithImpl<PokemonMoveStatStageChange>(this as PokemonMoveStatStageChange, _$identity);

  /// Serializes this PokemonMoveStatStageChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveStatStageChange&&(identical(other.stat, stat) || other.stat == stat)&&(identical(other.stages, stages) || other.stages == stages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stat,stages);

@override
String toString() {
  return 'PokemonMoveStatStageChange(stat: $stat, stages: $stages)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveStatStageChangeCopyWith<$Res>  {
  factory $PokemonMoveStatStageChangeCopyWith(PokemonMoveStatStageChange value, $Res Function(PokemonMoveStatStageChange) _then) = _$PokemonMoveStatStageChangeCopyWithImpl;
@useResult
$Res call({
 PokemonMoveStatId stat, int stages
});




}
/// @nodoc
class _$PokemonMoveStatStageChangeCopyWithImpl<$Res>
    implements $PokemonMoveStatStageChangeCopyWith<$Res> {
  _$PokemonMoveStatStageChangeCopyWithImpl(this._self, this._then);

  final PokemonMoveStatStageChange _self;
  final $Res Function(PokemonMoveStatStageChange) _then;

/// Create a copy of PokemonMoveStatStageChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stat = null,Object? stages = null,}) {
  return _then(_self.copyWith(
stat: null == stat ? _self.stat : stat // ignore: cast_nullable_to_non_nullable
as PokemonMoveStatId,stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PokemonMoveStatStageChange].
extension PokemonMoveStatStageChangePatterns on PokemonMoveStatStageChange {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PokemonMoveStatStageChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PokemonMoveStatStageChange() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PokemonMoveStatStageChange value)  $default,){
final _that = this;
switch (_that) {
case _PokemonMoveStatStageChange():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PokemonMoveStatStageChange value)?  $default,){
final _that = this;
switch (_that) {
case _PokemonMoveStatStageChange() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PokemonMoveStatId stat,  int stages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PokemonMoveStatStageChange() when $default != null:
return $default(_that.stat,_that.stages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PokemonMoveStatId stat,  int stages)  $default,) {final _that = this;
switch (_that) {
case _PokemonMoveStatStageChange():
return $default(_that.stat,_that.stages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PokemonMoveStatId stat,  int stages)?  $default,) {final _that = this;
switch (_that) {
case _PokemonMoveStatStageChange() when $default != null:
return $default(_that.stat,_that.stages);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PokemonMoveStatStageChange implements PokemonMoveStatStageChange {
  const _PokemonMoveStatStageChange({required this.stat, required this.stages});
  factory _PokemonMoveStatStageChange.fromJson(Map<String, dynamic> json) => _$PokemonMoveStatStageChangeFromJson(json);

@override final  PokemonMoveStatId stat;
@override final  int stages;

/// Create a copy of PokemonMoveStatStageChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PokemonMoveStatStageChangeCopyWith<_PokemonMoveStatStageChange> get copyWith => __$PokemonMoveStatStageChangeCopyWithImpl<_PokemonMoveStatStageChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveStatStageChangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PokemonMoveStatStageChange&&(identical(other.stat, stat) || other.stat == stat)&&(identical(other.stages, stages) || other.stages == stages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stat,stages);

@override
String toString() {
  return 'PokemonMoveStatStageChange(stat: $stat, stages: $stages)';
}


}

/// @nodoc
abstract mixin class _$PokemonMoveStatStageChangeCopyWith<$Res> implements $PokemonMoveStatStageChangeCopyWith<$Res> {
  factory _$PokemonMoveStatStageChangeCopyWith(_PokemonMoveStatStageChange value, $Res Function(_PokemonMoveStatStageChange) _then) = __$PokemonMoveStatStageChangeCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveStatId stat, int stages
});




}
/// @nodoc
class __$PokemonMoveStatStageChangeCopyWithImpl<$Res>
    implements _$PokemonMoveStatStageChangeCopyWith<$Res> {
  __$PokemonMoveStatStageChangeCopyWithImpl(this._self, this._then);

  final _PokemonMoveStatStageChange _self;
  final $Res Function(_PokemonMoveStatStageChange) _then;

/// Create a copy of PokemonMoveStatStageChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stat = null,Object? stages = null,}) {
  return _then(_PokemonMoveStatStageChange(
stat: null == stat ? _self.stat : stat // ignore: cast_nullable_to_non_nullable
as PokemonMoveStatId,stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

PokemonMoveEffect _$PokemonMoveEffectFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'fixed_damage':
          return PokemonMoveEffectFixedDamage.fromJson(
            json
          );
                case 'multi_hit':
          return PokemonMoveEffectMultiHit.fromJson(
            json
          );
                case 'apply_status':
          return PokemonMoveEffectApplyStatus.fromJson(
            json
          );
                case 'apply_volatile_status':
          return PokemonMoveEffectApplyVolatileStatus.fromJson(
            json
          );
                case 'modify_stats':
          return PokemonMoveEffectModifyStats.fromJson(
            json
          );
                case 'heal':
          return PokemonMoveEffectHeal.fromJson(
            json
          );
                case 'drain':
          return PokemonMoveEffectDrain.fromJson(
            json
          );
                case 'recoil':
          return PokemonMoveEffectRecoil.fromJson(
            json
          );
                case 'set_weather':
          return PokemonMoveEffectSetWeather.fromJson(
            json
          );
                case 'set_terrain':
          return PokemonMoveEffectSetTerrain.fromJson(
            json
          );
                case 'set_pseudo_weather':
          return PokemonMoveEffectSetPseudoWeather.fromJson(
            json
          );
                case 'self_switch':
          return PokemonMoveEffectSelfSwitch.fromJson(
            json
          );
                case 'force_switch':
          return PokemonMoveEffectForceSwitch.fromJson(
            json
          );
                case 'break_protect':
          return PokemonMoveEffectBreakProtect.fromJson(
            json
          );
                case 'require_recharge':
          return PokemonMoveEffectRequireRecharge.fromJson(
            json
          );
                case 'charge_then_strike':
          return PokemonMoveEffectChargeThenStrike.fromJson(
            json
          );
                case 'set_side_condition':
          return PokemonMoveEffectSetSideCondition.fromJson(
            json
          );
                case 'set_slot_condition':
          return PokemonMoveEffectSetSlotCondition.fromJson(
            json
          );

          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'PokemonMoveEffect',
  'Invalid union type "${json['kind']}"!'
);
        }

}

/// @nodoc
mixin _$PokemonMoveEffect {

 PokemonMoveEffectTargetScope get targetScope; int? get chance;
/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectCopyWith<PokemonMoveEffect> get copyWith => _$PokemonMoveEffectCopyWithImpl<PokemonMoveEffect>(this as PokemonMoveEffect, _$identity);

  /// Serializes this PokemonMoveEffect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffect&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance);

@override
String toString() {
  return 'PokemonMoveEffect(targetScope: $targetScope, chance: $chance)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectCopyWith<$Res>  {
  factory $PokemonMoveEffectCopyWith(PokemonMoveEffect value, $Res Function(PokemonMoveEffect) _then) = _$PokemonMoveEffectCopyWithImpl;
@useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance
});




}
/// @nodoc
class _$PokemonMoveEffectCopyWithImpl<$Res>
    implements $PokemonMoveEffectCopyWith<$Res> {
  _$PokemonMoveEffectCopyWithImpl(this._self, this._then);

  final PokemonMoveEffect _self;
  final $Res Function(PokemonMoveEffect) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetScope = null,Object? chance = freezed,}) {
  return _then(_self.copyWith(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PokemonMoveEffect].
extension PokemonMoveEffectPatterns on PokemonMoveEffect {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PokemonMoveEffectFixedDamage value)?  fixedDamage,TResult Function( PokemonMoveEffectMultiHit value)?  multiHit,TResult Function( PokemonMoveEffectApplyStatus value)?  applyStatus,TResult Function( PokemonMoveEffectApplyVolatileStatus value)?  applyVolatileStatus,TResult Function( PokemonMoveEffectModifyStats value)?  modifyStats,TResult Function( PokemonMoveEffectHeal value)?  heal,TResult Function( PokemonMoveEffectDrain value)?  drain,TResult Function( PokemonMoveEffectRecoil value)?  recoil,TResult Function( PokemonMoveEffectSetWeather value)?  setWeather,TResult Function( PokemonMoveEffectSetTerrain value)?  setTerrain,TResult Function( PokemonMoveEffectSetPseudoWeather value)?  setPseudoWeather,TResult Function( PokemonMoveEffectSelfSwitch value)?  selfSwitch,TResult Function( PokemonMoveEffectForceSwitch value)?  forceSwitch,TResult Function( PokemonMoveEffectBreakProtect value)?  breakProtect,TResult Function( PokemonMoveEffectRequireRecharge value)?  requireRecharge,TResult Function( PokemonMoveEffectChargeThenStrike value)?  chargeThenStrike,TResult Function( PokemonMoveEffectSetSideCondition value)?  setSideCondition,TResult Function( PokemonMoveEffectSetSlotCondition value)?  setSlotCondition,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PokemonMoveEffectFixedDamage() when fixedDamage != null:
return fixedDamage(_that);case PokemonMoveEffectMultiHit() when multiHit != null:
return multiHit(_that);case PokemonMoveEffectApplyStatus() when applyStatus != null:
return applyStatus(_that);case PokemonMoveEffectApplyVolatileStatus() when applyVolatileStatus != null:
return applyVolatileStatus(_that);case PokemonMoveEffectModifyStats() when modifyStats != null:
return modifyStats(_that);case PokemonMoveEffectHeal() when heal != null:
return heal(_that);case PokemonMoveEffectDrain() when drain != null:
return drain(_that);case PokemonMoveEffectRecoil() when recoil != null:
return recoil(_that);case PokemonMoveEffectSetWeather() when setWeather != null:
return setWeather(_that);case PokemonMoveEffectSetTerrain() when setTerrain != null:
return setTerrain(_that);case PokemonMoveEffectSetPseudoWeather() when setPseudoWeather != null:
return setPseudoWeather(_that);case PokemonMoveEffectSelfSwitch() when selfSwitch != null:
return selfSwitch(_that);case PokemonMoveEffectForceSwitch() when forceSwitch != null:
return forceSwitch(_that);case PokemonMoveEffectBreakProtect() when breakProtect != null:
return breakProtect(_that);case PokemonMoveEffectRequireRecharge() when requireRecharge != null:
return requireRecharge(_that);case PokemonMoveEffectChargeThenStrike() when chargeThenStrike != null:
return chargeThenStrike(_that);case PokemonMoveEffectSetSideCondition() when setSideCondition != null:
return setSideCondition(_that);case PokemonMoveEffectSetSlotCondition() when setSlotCondition != null:
return setSlotCondition(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PokemonMoveEffectFixedDamage value)  fixedDamage,required TResult Function( PokemonMoveEffectMultiHit value)  multiHit,required TResult Function( PokemonMoveEffectApplyStatus value)  applyStatus,required TResult Function( PokemonMoveEffectApplyVolatileStatus value)  applyVolatileStatus,required TResult Function( PokemonMoveEffectModifyStats value)  modifyStats,required TResult Function( PokemonMoveEffectHeal value)  heal,required TResult Function( PokemonMoveEffectDrain value)  drain,required TResult Function( PokemonMoveEffectRecoil value)  recoil,required TResult Function( PokemonMoveEffectSetWeather value)  setWeather,required TResult Function( PokemonMoveEffectSetTerrain value)  setTerrain,required TResult Function( PokemonMoveEffectSetPseudoWeather value)  setPseudoWeather,required TResult Function( PokemonMoveEffectSelfSwitch value)  selfSwitch,required TResult Function( PokemonMoveEffectForceSwitch value)  forceSwitch,required TResult Function( PokemonMoveEffectBreakProtect value)  breakProtect,required TResult Function( PokemonMoveEffectRequireRecharge value)  requireRecharge,required TResult Function( PokemonMoveEffectChargeThenStrike value)  chargeThenStrike,required TResult Function( PokemonMoveEffectSetSideCondition value)  setSideCondition,required TResult Function( PokemonMoveEffectSetSlotCondition value)  setSlotCondition,}){
final _that = this;
switch (_that) {
case PokemonMoveEffectFixedDamage():
return fixedDamage(_that);case PokemonMoveEffectMultiHit():
return multiHit(_that);case PokemonMoveEffectApplyStatus():
return applyStatus(_that);case PokemonMoveEffectApplyVolatileStatus():
return applyVolatileStatus(_that);case PokemonMoveEffectModifyStats():
return modifyStats(_that);case PokemonMoveEffectHeal():
return heal(_that);case PokemonMoveEffectDrain():
return drain(_that);case PokemonMoveEffectRecoil():
return recoil(_that);case PokemonMoveEffectSetWeather():
return setWeather(_that);case PokemonMoveEffectSetTerrain():
return setTerrain(_that);case PokemonMoveEffectSetPseudoWeather():
return setPseudoWeather(_that);case PokemonMoveEffectSelfSwitch():
return selfSwitch(_that);case PokemonMoveEffectForceSwitch():
return forceSwitch(_that);case PokemonMoveEffectBreakProtect():
return breakProtect(_that);case PokemonMoveEffectRequireRecharge():
return requireRecharge(_that);case PokemonMoveEffectChargeThenStrike():
return chargeThenStrike(_that);case PokemonMoveEffectSetSideCondition():
return setSideCondition(_that);case PokemonMoveEffectSetSlotCondition():
return setSlotCondition(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PokemonMoveEffectFixedDamage value)?  fixedDamage,TResult? Function( PokemonMoveEffectMultiHit value)?  multiHit,TResult? Function( PokemonMoveEffectApplyStatus value)?  applyStatus,TResult? Function( PokemonMoveEffectApplyVolatileStatus value)?  applyVolatileStatus,TResult? Function( PokemonMoveEffectModifyStats value)?  modifyStats,TResult? Function( PokemonMoveEffectHeal value)?  heal,TResult? Function( PokemonMoveEffectDrain value)?  drain,TResult? Function( PokemonMoveEffectRecoil value)?  recoil,TResult? Function( PokemonMoveEffectSetWeather value)?  setWeather,TResult? Function( PokemonMoveEffectSetTerrain value)?  setTerrain,TResult? Function( PokemonMoveEffectSetPseudoWeather value)?  setPseudoWeather,TResult? Function( PokemonMoveEffectSelfSwitch value)?  selfSwitch,TResult? Function( PokemonMoveEffectForceSwitch value)?  forceSwitch,TResult? Function( PokemonMoveEffectBreakProtect value)?  breakProtect,TResult? Function( PokemonMoveEffectRequireRecharge value)?  requireRecharge,TResult? Function( PokemonMoveEffectChargeThenStrike value)?  chargeThenStrike,TResult? Function( PokemonMoveEffectSetSideCondition value)?  setSideCondition,TResult? Function( PokemonMoveEffectSetSlotCondition value)?  setSlotCondition,}){
final _that = this;
switch (_that) {
case PokemonMoveEffectFixedDamage() when fixedDamage != null:
return fixedDamage(_that);case PokemonMoveEffectMultiHit() when multiHit != null:
return multiHit(_that);case PokemonMoveEffectApplyStatus() when applyStatus != null:
return applyStatus(_that);case PokemonMoveEffectApplyVolatileStatus() when applyVolatileStatus != null:
return applyVolatileStatus(_that);case PokemonMoveEffectModifyStats() when modifyStats != null:
return modifyStats(_that);case PokemonMoveEffectHeal() when heal != null:
return heal(_that);case PokemonMoveEffectDrain() when drain != null:
return drain(_that);case PokemonMoveEffectRecoil() when recoil != null:
return recoil(_that);case PokemonMoveEffectSetWeather() when setWeather != null:
return setWeather(_that);case PokemonMoveEffectSetTerrain() when setTerrain != null:
return setTerrain(_that);case PokemonMoveEffectSetPseudoWeather() when setPseudoWeather != null:
return setPseudoWeather(_that);case PokemonMoveEffectSelfSwitch() when selfSwitch != null:
return selfSwitch(_that);case PokemonMoveEffectForceSwitch() when forceSwitch != null:
return forceSwitch(_that);case PokemonMoveEffectBreakProtect() when breakProtect != null:
return breakProtect(_that);case PokemonMoveEffectRequireRecharge() when requireRecharge != null:
return requireRecharge(_that);case PokemonMoveEffectChargeThenStrike() when chargeThenStrike != null:
return chargeThenStrike(_that);case PokemonMoveEffectSetSideCondition() when setSideCondition != null:
return setSideCondition(_that);case PokemonMoveEffectSetSlotCondition() when setSlotCondition != null:
return setSlotCondition(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int? value,  bool usesUserLevel)?  fixedDamage,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int minHits,  int maxHits)?  multiHit,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String statusId)?  applyStatus,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String volatileStatusId)?  applyVolatileStatus,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  List<PokemonMoveStatStageChange> stageChanges)?  modifyStats,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int numerator,  int denominator)?  heal,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int numerator,  int denominator)?  drain,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int numerator,  int denominator)?  recoil,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String weatherId)?  setWeather,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String terrainId)?  setTerrain,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String pseudoWeatherId)?  setPseudoWeather,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String? mode)?  selfSwitch,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance)?  forceSwitch,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance)?  breakProtect,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance)?  requireRecharge,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String? chargeStateId)?  chargeThenStrike,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String conditionId)?  setSideCondition,TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String conditionId)?  setSlotCondition,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PokemonMoveEffectFixedDamage() when fixedDamage != null:
return fixedDamage(_that.targetScope,_that.chance,_that.value,_that.usesUserLevel);case PokemonMoveEffectMultiHit() when multiHit != null:
return multiHit(_that.targetScope,_that.chance,_that.minHits,_that.maxHits);case PokemonMoveEffectApplyStatus() when applyStatus != null:
return applyStatus(_that.targetScope,_that.chance,_that.statusId);case PokemonMoveEffectApplyVolatileStatus() when applyVolatileStatus != null:
return applyVolatileStatus(_that.targetScope,_that.chance,_that.volatileStatusId);case PokemonMoveEffectModifyStats() when modifyStats != null:
return modifyStats(_that.targetScope,_that.chance,_that.stageChanges);case PokemonMoveEffectHeal() when heal != null:
return heal(_that.targetScope,_that.chance,_that.numerator,_that.denominator);case PokemonMoveEffectDrain() when drain != null:
return drain(_that.targetScope,_that.chance,_that.numerator,_that.denominator);case PokemonMoveEffectRecoil() when recoil != null:
return recoil(_that.targetScope,_that.chance,_that.numerator,_that.denominator);case PokemonMoveEffectSetWeather() when setWeather != null:
return setWeather(_that.targetScope,_that.chance,_that.weatherId);case PokemonMoveEffectSetTerrain() when setTerrain != null:
return setTerrain(_that.targetScope,_that.chance,_that.terrainId);case PokemonMoveEffectSetPseudoWeather() when setPseudoWeather != null:
return setPseudoWeather(_that.targetScope,_that.chance,_that.pseudoWeatherId);case PokemonMoveEffectSelfSwitch() when selfSwitch != null:
return selfSwitch(_that.targetScope,_that.chance,_that.mode);case PokemonMoveEffectForceSwitch() when forceSwitch != null:
return forceSwitch(_that.targetScope,_that.chance);case PokemonMoveEffectBreakProtect() when breakProtect != null:
return breakProtect(_that.targetScope,_that.chance);case PokemonMoveEffectRequireRecharge() when requireRecharge != null:
return requireRecharge(_that.targetScope,_that.chance);case PokemonMoveEffectChargeThenStrike() when chargeThenStrike != null:
return chargeThenStrike(_that.targetScope,_that.chance,_that.chargeStateId);case PokemonMoveEffectSetSideCondition() when setSideCondition != null:
return setSideCondition(_that.targetScope,_that.chance,_that.conditionId);case PokemonMoveEffectSetSlotCondition() when setSlotCondition != null:
return setSlotCondition(_that.targetScope,_that.chance,_that.conditionId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int? value,  bool usesUserLevel)  fixedDamage,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int minHits,  int maxHits)  multiHit,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String statusId)  applyStatus,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String volatileStatusId)  applyVolatileStatus,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  List<PokemonMoveStatStageChange> stageChanges)  modifyStats,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int numerator,  int denominator)  heal,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int numerator,  int denominator)  drain,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int numerator,  int denominator)  recoil,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String weatherId)  setWeather,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String terrainId)  setTerrain,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String pseudoWeatherId)  setPseudoWeather,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String? mode)  selfSwitch,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance)  forceSwitch,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance)  breakProtect,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance)  requireRecharge,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String? chargeStateId)  chargeThenStrike,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String conditionId)  setSideCondition,required TResult Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String conditionId)  setSlotCondition,}) {final _that = this;
switch (_that) {
case PokemonMoveEffectFixedDamage():
return fixedDamage(_that.targetScope,_that.chance,_that.value,_that.usesUserLevel);case PokemonMoveEffectMultiHit():
return multiHit(_that.targetScope,_that.chance,_that.minHits,_that.maxHits);case PokemonMoveEffectApplyStatus():
return applyStatus(_that.targetScope,_that.chance,_that.statusId);case PokemonMoveEffectApplyVolatileStatus():
return applyVolatileStatus(_that.targetScope,_that.chance,_that.volatileStatusId);case PokemonMoveEffectModifyStats():
return modifyStats(_that.targetScope,_that.chance,_that.stageChanges);case PokemonMoveEffectHeal():
return heal(_that.targetScope,_that.chance,_that.numerator,_that.denominator);case PokemonMoveEffectDrain():
return drain(_that.targetScope,_that.chance,_that.numerator,_that.denominator);case PokemonMoveEffectRecoil():
return recoil(_that.targetScope,_that.chance,_that.numerator,_that.denominator);case PokemonMoveEffectSetWeather():
return setWeather(_that.targetScope,_that.chance,_that.weatherId);case PokemonMoveEffectSetTerrain():
return setTerrain(_that.targetScope,_that.chance,_that.terrainId);case PokemonMoveEffectSetPseudoWeather():
return setPseudoWeather(_that.targetScope,_that.chance,_that.pseudoWeatherId);case PokemonMoveEffectSelfSwitch():
return selfSwitch(_that.targetScope,_that.chance,_that.mode);case PokemonMoveEffectForceSwitch():
return forceSwitch(_that.targetScope,_that.chance);case PokemonMoveEffectBreakProtect():
return breakProtect(_that.targetScope,_that.chance);case PokemonMoveEffectRequireRecharge():
return requireRecharge(_that.targetScope,_that.chance);case PokemonMoveEffectChargeThenStrike():
return chargeThenStrike(_that.targetScope,_that.chance,_that.chargeStateId);case PokemonMoveEffectSetSideCondition():
return setSideCondition(_that.targetScope,_that.chance,_that.conditionId);case PokemonMoveEffectSetSlotCondition():
return setSlotCondition(_that.targetScope,_that.chance,_that.conditionId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int? value,  bool usesUserLevel)?  fixedDamage,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int minHits,  int maxHits)?  multiHit,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String statusId)?  applyStatus,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String volatileStatusId)?  applyVolatileStatus,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  List<PokemonMoveStatStageChange> stageChanges)?  modifyStats,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int numerator,  int denominator)?  heal,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int numerator,  int denominator)?  drain,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  int numerator,  int denominator)?  recoil,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String weatherId)?  setWeather,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String terrainId)?  setTerrain,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String pseudoWeatherId)?  setPseudoWeather,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String? mode)?  selfSwitch,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance)?  forceSwitch,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance)?  breakProtect,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance)?  requireRecharge,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String? chargeStateId)?  chargeThenStrike,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String conditionId)?  setSideCondition,TResult? Function( PokemonMoveEffectTargetScope targetScope,  int? chance,  String conditionId)?  setSlotCondition,}) {final _that = this;
switch (_that) {
case PokemonMoveEffectFixedDamage() when fixedDamage != null:
return fixedDamage(_that.targetScope,_that.chance,_that.value,_that.usesUserLevel);case PokemonMoveEffectMultiHit() when multiHit != null:
return multiHit(_that.targetScope,_that.chance,_that.minHits,_that.maxHits);case PokemonMoveEffectApplyStatus() when applyStatus != null:
return applyStatus(_that.targetScope,_that.chance,_that.statusId);case PokemonMoveEffectApplyVolatileStatus() when applyVolatileStatus != null:
return applyVolatileStatus(_that.targetScope,_that.chance,_that.volatileStatusId);case PokemonMoveEffectModifyStats() when modifyStats != null:
return modifyStats(_that.targetScope,_that.chance,_that.stageChanges);case PokemonMoveEffectHeal() when heal != null:
return heal(_that.targetScope,_that.chance,_that.numerator,_that.denominator);case PokemonMoveEffectDrain() when drain != null:
return drain(_that.targetScope,_that.chance,_that.numerator,_that.denominator);case PokemonMoveEffectRecoil() when recoil != null:
return recoil(_that.targetScope,_that.chance,_that.numerator,_that.denominator);case PokemonMoveEffectSetWeather() when setWeather != null:
return setWeather(_that.targetScope,_that.chance,_that.weatherId);case PokemonMoveEffectSetTerrain() when setTerrain != null:
return setTerrain(_that.targetScope,_that.chance,_that.terrainId);case PokemonMoveEffectSetPseudoWeather() when setPseudoWeather != null:
return setPseudoWeather(_that.targetScope,_that.chance,_that.pseudoWeatherId);case PokemonMoveEffectSelfSwitch() when selfSwitch != null:
return selfSwitch(_that.targetScope,_that.chance,_that.mode);case PokemonMoveEffectForceSwitch() when forceSwitch != null:
return forceSwitch(_that.targetScope,_that.chance);case PokemonMoveEffectBreakProtect() when breakProtect != null:
return breakProtect(_that.targetScope,_that.chance);case PokemonMoveEffectRequireRecharge() when requireRecharge != null:
return requireRecharge(_that.targetScope,_that.chance);case PokemonMoveEffectChargeThenStrike() when chargeThenStrike != null:
return chargeThenStrike(_that.targetScope,_that.chance,_that.chargeStateId);case PokemonMoveEffectSetSideCondition() when setSideCondition != null:
return setSideCondition(_that.targetScope,_that.chance,_that.conditionId);case PokemonMoveEffectSetSlotCondition() when setSlotCondition != null:
return setSlotCondition(_that.targetScope,_that.chance,_that.conditionId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectFixedDamage extends PokemonMoveEffect {
  const PokemonMoveEffectFixedDamage({this.targetScope = PokemonMoveEffectTargetScope.target, this.chance, this.value, this.usesUserLevel = false, final  String? $type}): $type = $type ?? 'fixed_damage',super._();
  factory PokemonMoveEffectFixedDamage.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectFixedDamageFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
/// Valeur fixe exacte quand le move inflige un montant constant.
 final  int? value;
/// Garde-fou minimal pour les cas "fixed damage = niveau du lanceur".
@JsonKey() final  bool usesUserLevel;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectFixedDamageCopyWith<PokemonMoveEffectFixedDamage> get copyWith => _$PokemonMoveEffectFixedDamageCopyWithImpl<PokemonMoveEffectFixedDamage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectFixedDamageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectFixedDamage&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.value, value) || other.value == value)&&(identical(other.usesUserLevel, usesUserLevel) || other.usesUserLevel == usesUserLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,value,usesUserLevel);

@override
String toString() {
  return 'PokemonMoveEffect.fixedDamage(targetScope: $targetScope, chance: $chance, value: $value, usesUserLevel: $usesUserLevel)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectFixedDamageCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectFixedDamageCopyWith(PokemonMoveEffectFixedDamage value, $Res Function(PokemonMoveEffectFixedDamage) _then) = _$PokemonMoveEffectFixedDamageCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, int? value, bool usesUserLevel
});




}
/// @nodoc
class _$PokemonMoveEffectFixedDamageCopyWithImpl<$Res>
    implements $PokemonMoveEffectFixedDamageCopyWith<$Res> {
  _$PokemonMoveEffectFixedDamageCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectFixedDamage _self;
  final $Res Function(PokemonMoveEffectFixedDamage) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? value = freezed,Object? usesUserLevel = null,}) {
  return _then(PokemonMoveEffectFixedDamage(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int?,usesUserLevel: null == usesUserLevel ? _self.usesUserLevel : usesUserLevel // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectMultiHit extends PokemonMoveEffect {
  const PokemonMoveEffectMultiHit({this.targetScope = PokemonMoveEffectTargetScope.target, this.chance, required this.minHits, required this.maxHits, final  String? $type}): $type = $type ?? 'multi_hit',super._();
  factory PokemonMoveEffectMultiHit.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectMultiHitFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  int minHits;
 final  int maxHits;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectMultiHitCopyWith<PokemonMoveEffectMultiHit> get copyWith => _$PokemonMoveEffectMultiHitCopyWithImpl<PokemonMoveEffectMultiHit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectMultiHitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectMultiHit&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.minHits, minHits) || other.minHits == minHits)&&(identical(other.maxHits, maxHits) || other.maxHits == maxHits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,minHits,maxHits);

@override
String toString() {
  return 'PokemonMoveEffect.multiHit(targetScope: $targetScope, chance: $chance, minHits: $minHits, maxHits: $maxHits)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectMultiHitCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectMultiHitCopyWith(PokemonMoveEffectMultiHit value, $Res Function(PokemonMoveEffectMultiHit) _then) = _$PokemonMoveEffectMultiHitCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, int minHits, int maxHits
});




}
/// @nodoc
class _$PokemonMoveEffectMultiHitCopyWithImpl<$Res>
    implements $PokemonMoveEffectMultiHitCopyWith<$Res> {
  _$PokemonMoveEffectMultiHitCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectMultiHit _self;
  final $Res Function(PokemonMoveEffectMultiHit) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? minHits = null,Object? maxHits = null,}) {
  return _then(PokemonMoveEffectMultiHit(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,minHits: null == minHits ? _self.minHits : minHits // ignore: cast_nullable_to_non_nullable
as int,maxHits: null == maxHits ? _self.maxHits : maxHits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectApplyStatus extends PokemonMoveEffect {
  const PokemonMoveEffectApplyStatus({this.targetScope = PokemonMoveEffectTargetScope.target, this.chance, required this.statusId, final  String? $type}): $type = $type ?? 'apply_status',super._();
  factory PokemonMoveEffectApplyStatus.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectApplyStatusFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  String statusId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectApplyStatusCopyWith<PokemonMoveEffectApplyStatus> get copyWith => _$PokemonMoveEffectApplyStatusCopyWithImpl<PokemonMoveEffectApplyStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectApplyStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectApplyStatus&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.statusId, statusId) || other.statusId == statusId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,statusId);

@override
String toString() {
  return 'PokemonMoveEffect.applyStatus(targetScope: $targetScope, chance: $chance, statusId: $statusId)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectApplyStatusCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectApplyStatusCopyWith(PokemonMoveEffectApplyStatus value, $Res Function(PokemonMoveEffectApplyStatus) _then) = _$PokemonMoveEffectApplyStatusCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, String statusId
});




}
/// @nodoc
class _$PokemonMoveEffectApplyStatusCopyWithImpl<$Res>
    implements $PokemonMoveEffectApplyStatusCopyWith<$Res> {
  _$PokemonMoveEffectApplyStatusCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectApplyStatus _self;
  final $Res Function(PokemonMoveEffectApplyStatus) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? statusId = null,}) {
  return _then(PokemonMoveEffectApplyStatus(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,statusId: null == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectApplyVolatileStatus extends PokemonMoveEffect {
  const PokemonMoveEffectApplyVolatileStatus({this.targetScope = PokemonMoveEffectTargetScope.target, this.chance, required this.volatileStatusId, final  String? $type}): $type = $type ?? 'apply_volatile_status',super._();
  factory PokemonMoveEffectApplyVolatileStatus.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectApplyVolatileStatusFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  String volatileStatusId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectApplyVolatileStatusCopyWith<PokemonMoveEffectApplyVolatileStatus> get copyWith => _$PokemonMoveEffectApplyVolatileStatusCopyWithImpl<PokemonMoveEffectApplyVolatileStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectApplyVolatileStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectApplyVolatileStatus&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.volatileStatusId, volatileStatusId) || other.volatileStatusId == volatileStatusId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,volatileStatusId);

@override
String toString() {
  return 'PokemonMoveEffect.applyVolatileStatus(targetScope: $targetScope, chance: $chance, volatileStatusId: $volatileStatusId)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectApplyVolatileStatusCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectApplyVolatileStatusCopyWith(PokemonMoveEffectApplyVolatileStatus value, $Res Function(PokemonMoveEffectApplyVolatileStatus) _then) = _$PokemonMoveEffectApplyVolatileStatusCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, String volatileStatusId
});




}
/// @nodoc
class _$PokemonMoveEffectApplyVolatileStatusCopyWithImpl<$Res>
    implements $PokemonMoveEffectApplyVolatileStatusCopyWith<$Res> {
  _$PokemonMoveEffectApplyVolatileStatusCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectApplyVolatileStatus _self;
  final $Res Function(PokemonMoveEffectApplyVolatileStatus) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? volatileStatusId = null,}) {
  return _then(PokemonMoveEffectApplyVolatileStatus(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,volatileStatusId: null == volatileStatusId ? _self.volatileStatusId : volatileStatusId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectModifyStats extends PokemonMoveEffect {
  const PokemonMoveEffectModifyStats({this.targetScope = PokemonMoveEffectTargetScope.target, this.chance, final  List<PokemonMoveStatStageChange> stageChanges = const <PokemonMoveStatStageChange>[], final  String? $type}): _stageChanges = stageChanges,$type = $type ?? 'modify_stats',super._();
  factory PokemonMoveEffectModifyStats.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectModifyStatsFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  List<PokemonMoveStatStageChange> _stageChanges;
@JsonKey() List<PokemonMoveStatStageChange> get stageChanges {
  if (_stageChanges is EqualUnmodifiableListView) return _stageChanges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stageChanges);
}


@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectModifyStatsCopyWith<PokemonMoveEffectModifyStats> get copyWith => _$PokemonMoveEffectModifyStatsCopyWithImpl<PokemonMoveEffectModifyStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectModifyStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectModifyStats&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&const DeepCollectionEquality().equals(other._stageChanges, _stageChanges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,const DeepCollectionEquality().hash(_stageChanges));

@override
String toString() {
  return 'PokemonMoveEffect.modifyStats(targetScope: $targetScope, chance: $chance, stageChanges: $stageChanges)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectModifyStatsCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectModifyStatsCopyWith(PokemonMoveEffectModifyStats value, $Res Function(PokemonMoveEffectModifyStats) _then) = _$PokemonMoveEffectModifyStatsCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, List<PokemonMoveStatStageChange> stageChanges
});




}
/// @nodoc
class _$PokemonMoveEffectModifyStatsCopyWithImpl<$Res>
    implements $PokemonMoveEffectModifyStatsCopyWith<$Res> {
  _$PokemonMoveEffectModifyStatsCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectModifyStats _self;
  final $Res Function(PokemonMoveEffectModifyStats) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? stageChanges = null,}) {
  return _then(PokemonMoveEffectModifyStats(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,stageChanges: null == stageChanges ? _self._stageChanges : stageChanges // ignore: cast_nullable_to_non_nullable
as List<PokemonMoveStatStageChange>,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectHeal extends PokemonMoveEffect {
  const PokemonMoveEffectHeal({this.targetScope = PokemonMoveEffectTargetScope.self, this.chance, required this.numerator, required this.denominator, final  String? $type}): $type = $type ?? 'heal',super._();
  factory PokemonMoveEffectHeal.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectHealFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  int numerator;
 final  int denominator;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectHealCopyWith<PokemonMoveEffectHeal> get copyWith => _$PokemonMoveEffectHealCopyWithImpl<PokemonMoveEffectHeal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectHealToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectHeal&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.numerator, numerator) || other.numerator == numerator)&&(identical(other.denominator, denominator) || other.denominator == denominator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,numerator,denominator);

@override
String toString() {
  return 'PokemonMoveEffect.heal(targetScope: $targetScope, chance: $chance, numerator: $numerator, denominator: $denominator)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectHealCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectHealCopyWith(PokemonMoveEffectHeal value, $Res Function(PokemonMoveEffectHeal) _then) = _$PokemonMoveEffectHealCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, int numerator, int denominator
});




}
/// @nodoc
class _$PokemonMoveEffectHealCopyWithImpl<$Res>
    implements $PokemonMoveEffectHealCopyWith<$Res> {
  _$PokemonMoveEffectHealCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectHeal _self;
  final $Res Function(PokemonMoveEffectHeal) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? numerator = null,Object? denominator = null,}) {
  return _then(PokemonMoveEffectHeal(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,numerator: null == numerator ? _self.numerator : numerator // ignore: cast_nullable_to_non_nullable
as int,denominator: null == denominator ? _self.denominator : denominator // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectDrain extends PokemonMoveEffect {
  const PokemonMoveEffectDrain({this.targetScope = PokemonMoveEffectTargetScope.self, this.chance, required this.numerator, required this.denominator, final  String? $type}): $type = $type ?? 'drain',super._();
  factory PokemonMoveEffectDrain.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectDrainFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  int numerator;
 final  int denominator;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectDrainCopyWith<PokemonMoveEffectDrain> get copyWith => _$PokemonMoveEffectDrainCopyWithImpl<PokemonMoveEffectDrain>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectDrainToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectDrain&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.numerator, numerator) || other.numerator == numerator)&&(identical(other.denominator, denominator) || other.denominator == denominator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,numerator,denominator);

@override
String toString() {
  return 'PokemonMoveEffect.drain(targetScope: $targetScope, chance: $chance, numerator: $numerator, denominator: $denominator)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectDrainCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectDrainCopyWith(PokemonMoveEffectDrain value, $Res Function(PokemonMoveEffectDrain) _then) = _$PokemonMoveEffectDrainCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, int numerator, int denominator
});




}
/// @nodoc
class _$PokemonMoveEffectDrainCopyWithImpl<$Res>
    implements $PokemonMoveEffectDrainCopyWith<$Res> {
  _$PokemonMoveEffectDrainCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectDrain _self;
  final $Res Function(PokemonMoveEffectDrain) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? numerator = null,Object? denominator = null,}) {
  return _then(PokemonMoveEffectDrain(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,numerator: null == numerator ? _self.numerator : numerator // ignore: cast_nullable_to_non_nullable
as int,denominator: null == denominator ? _self.denominator : denominator // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectRecoil extends PokemonMoveEffect {
  const PokemonMoveEffectRecoil({this.targetScope = PokemonMoveEffectTargetScope.self, this.chance, required this.numerator, required this.denominator, final  String? $type}): $type = $type ?? 'recoil',super._();
  factory PokemonMoveEffectRecoil.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectRecoilFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  int numerator;
 final  int denominator;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectRecoilCopyWith<PokemonMoveEffectRecoil> get copyWith => _$PokemonMoveEffectRecoilCopyWithImpl<PokemonMoveEffectRecoil>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectRecoilToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectRecoil&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.numerator, numerator) || other.numerator == numerator)&&(identical(other.denominator, denominator) || other.denominator == denominator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,numerator,denominator);

@override
String toString() {
  return 'PokemonMoveEffect.recoil(targetScope: $targetScope, chance: $chance, numerator: $numerator, denominator: $denominator)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectRecoilCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectRecoilCopyWith(PokemonMoveEffectRecoil value, $Res Function(PokemonMoveEffectRecoil) _then) = _$PokemonMoveEffectRecoilCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, int numerator, int denominator
});




}
/// @nodoc
class _$PokemonMoveEffectRecoilCopyWithImpl<$Res>
    implements $PokemonMoveEffectRecoilCopyWith<$Res> {
  _$PokemonMoveEffectRecoilCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectRecoil _self;
  final $Res Function(PokemonMoveEffectRecoil) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? numerator = null,Object? denominator = null,}) {
  return _then(PokemonMoveEffectRecoil(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,numerator: null == numerator ? _self.numerator : numerator // ignore: cast_nullable_to_non_nullable
as int,denominator: null == denominator ? _self.denominator : denominator // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectSetWeather extends PokemonMoveEffect {
  const PokemonMoveEffectSetWeather({this.targetScope = PokemonMoveEffectTargetScope.field, this.chance, required this.weatherId, final  String? $type}): $type = $type ?? 'set_weather',super._();
  factory PokemonMoveEffectSetWeather.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectSetWeatherFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  String weatherId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectSetWeatherCopyWith<PokemonMoveEffectSetWeather> get copyWith => _$PokemonMoveEffectSetWeatherCopyWithImpl<PokemonMoveEffectSetWeather>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectSetWeatherToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectSetWeather&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.weatherId, weatherId) || other.weatherId == weatherId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,weatherId);

@override
String toString() {
  return 'PokemonMoveEffect.setWeather(targetScope: $targetScope, chance: $chance, weatherId: $weatherId)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectSetWeatherCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectSetWeatherCopyWith(PokemonMoveEffectSetWeather value, $Res Function(PokemonMoveEffectSetWeather) _then) = _$PokemonMoveEffectSetWeatherCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, String weatherId
});




}
/// @nodoc
class _$PokemonMoveEffectSetWeatherCopyWithImpl<$Res>
    implements $PokemonMoveEffectSetWeatherCopyWith<$Res> {
  _$PokemonMoveEffectSetWeatherCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectSetWeather _self;
  final $Res Function(PokemonMoveEffectSetWeather) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? weatherId = null,}) {
  return _then(PokemonMoveEffectSetWeather(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,weatherId: null == weatherId ? _self.weatherId : weatherId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectSetTerrain extends PokemonMoveEffect {
  const PokemonMoveEffectSetTerrain({this.targetScope = PokemonMoveEffectTargetScope.field, this.chance, required this.terrainId, final  String? $type}): $type = $type ?? 'set_terrain',super._();
  factory PokemonMoveEffectSetTerrain.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectSetTerrainFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  String terrainId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectSetTerrainCopyWith<PokemonMoveEffectSetTerrain> get copyWith => _$PokemonMoveEffectSetTerrainCopyWithImpl<PokemonMoveEffectSetTerrain>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectSetTerrainToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectSetTerrain&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.terrainId, terrainId) || other.terrainId == terrainId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,terrainId);

@override
String toString() {
  return 'PokemonMoveEffect.setTerrain(targetScope: $targetScope, chance: $chance, terrainId: $terrainId)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectSetTerrainCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectSetTerrainCopyWith(PokemonMoveEffectSetTerrain value, $Res Function(PokemonMoveEffectSetTerrain) _then) = _$PokemonMoveEffectSetTerrainCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, String terrainId
});




}
/// @nodoc
class _$PokemonMoveEffectSetTerrainCopyWithImpl<$Res>
    implements $PokemonMoveEffectSetTerrainCopyWith<$Res> {
  _$PokemonMoveEffectSetTerrainCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectSetTerrain _self;
  final $Res Function(PokemonMoveEffectSetTerrain) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? terrainId = null,}) {
  return _then(PokemonMoveEffectSetTerrain(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,terrainId: null == terrainId ? _self.terrainId : terrainId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectSetPseudoWeather extends PokemonMoveEffect {
  const PokemonMoveEffectSetPseudoWeather({this.targetScope = PokemonMoveEffectTargetScope.field, this.chance, required this.pseudoWeatherId, final  String? $type}): $type = $type ?? 'set_pseudo_weather',super._();
  factory PokemonMoveEffectSetPseudoWeather.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectSetPseudoWeatherFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  String pseudoWeatherId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectSetPseudoWeatherCopyWith<PokemonMoveEffectSetPseudoWeather> get copyWith => _$PokemonMoveEffectSetPseudoWeatherCopyWithImpl<PokemonMoveEffectSetPseudoWeather>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectSetPseudoWeatherToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectSetPseudoWeather&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.pseudoWeatherId, pseudoWeatherId) || other.pseudoWeatherId == pseudoWeatherId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,pseudoWeatherId);

@override
String toString() {
  return 'PokemonMoveEffect.setPseudoWeather(targetScope: $targetScope, chance: $chance, pseudoWeatherId: $pseudoWeatherId)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectSetPseudoWeatherCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectSetPseudoWeatherCopyWith(PokemonMoveEffectSetPseudoWeather value, $Res Function(PokemonMoveEffectSetPseudoWeather) _then) = _$PokemonMoveEffectSetPseudoWeatherCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, String pseudoWeatherId
});




}
/// @nodoc
class _$PokemonMoveEffectSetPseudoWeatherCopyWithImpl<$Res>
    implements $PokemonMoveEffectSetPseudoWeatherCopyWith<$Res> {
  _$PokemonMoveEffectSetPseudoWeatherCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectSetPseudoWeather _self;
  final $Res Function(PokemonMoveEffectSetPseudoWeather) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? pseudoWeatherId = null,}) {
  return _then(PokemonMoveEffectSetPseudoWeather(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,pseudoWeatherId: null == pseudoWeatherId ? _self.pseudoWeatherId : pseudoWeatherId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectSelfSwitch extends PokemonMoveEffect {
  const PokemonMoveEffectSelfSwitch({this.targetScope = PokemonMoveEffectTargetScope.self, this.chance, this.mode, final  String? $type}): $type = $type ?? 'self_switch',super._();
  factory PokemonMoveEffectSelfSwitch.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectSelfSwitchFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
/// Exemples futurs : `copyvolatile`, `shedtail`, `simple`.
 final  String? mode;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectSelfSwitchCopyWith<PokemonMoveEffectSelfSwitch> get copyWith => _$PokemonMoveEffectSelfSwitchCopyWithImpl<PokemonMoveEffectSelfSwitch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectSelfSwitchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectSelfSwitch&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,mode);

@override
String toString() {
  return 'PokemonMoveEffect.selfSwitch(targetScope: $targetScope, chance: $chance, mode: $mode)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectSelfSwitchCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectSelfSwitchCopyWith(PokemonMoveEffectSelfSwitch value, $Res Function(PokemonMoveEffectSelfSwitch) _then) = _$PokemonMoveEffectSelfSwitchCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, String? mode
});




}
/// @nodoc
class _$PokemonMoveEffectSelfSwitchCopyWithImpl<$Res>
    implements $PokemonMoveEffectSelfSwitchCopyWith<$Res> {
  _$PokemonMoveEffectSelfSwitchCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectSelfSwitch _self;
  final $Res Function(PokemonMoveEffectSelfSwitch) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? mode = freezed,}) {
  return _then(PokemonMoveEffectSelfSwitch(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectForceSwitch extends PokemonMoveEffect {
  const PokemonMoveEffectForceSwitch({this.targetScope = PokemonMoveEffectTargetScope.target, this.chance, final  String? $type}): $type = $type ?? 'force_switch',super._();
  factory PokemonMoveEffectForceSwitch.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectForceSwitchFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectForceSwitchCopyWith<PokemonMoveEffectForceSwitch> get copyWith => _$PokemonMoveEffectForceSwitchCopyWithImpl<PokemonMoveEffectForceSwitch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectForceSwitchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectForceSwitch&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance);

@override
String toString() {
  return 'PokemonMoveEffect.forceSwitch(targetScope: $targetScope, chance: $chance)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectForceSwitchCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectForceSwitchCopyWith(PokemonMoveEffectForceSwitch value, $Res Function(PokemonMoveEffectForceSwitch) _then) = _$PokemonMoveEffectForceSwitchCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance
});




}
/// @nodoc
class _$PokemonMoveEffectForceSwitchCopyWithImpl<$Res>
    implements $PokemonMoveEffectForceSwitchCopyWith<$Res> {
  _$PokemonMoveEffectForceSwitchCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectForceSwitch _self;
  final $Res Function(PokemonMoveEffectForceSwitch) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,}) {
  return _then(PokemonMoveEffectForceSwitch(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectBreakProtect extends PokemonMoveEffect {
  const PokemonMoveEffectBreakProtect({this.targetScope = PokemonMoveEffectTargetScope.target, this.chance, final  String? $type}): $type = $type ?? 'break_protect',super._();
  factory PokemonMoveEffectBreakProtect.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectBreakProtectFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectBreakProtectCopyWith<PokemonMoveEffectBreakProtect> get copyWith => _$PokemonMoveEffectBreakProtectCopyWithImpl<PokemonMoveEffectBreakProtect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectBreakProtectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectBreakProtect&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance);

@override
String toString() {
  return 'PokemonMoveEffect.breakProtect(targetScope: $targetScope, chance: $chance)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectBreakProtectCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectBreakProtectCopyWith(PokemonMoveEffectBreakProtect value, $Res Function(PokemonMoveEffectBreakProtect) _then) = _$PokemonMoveEffectBreakProtectCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance
});




}
/// @nodoc
class _$PokemonMoveEffectBreakProtectCopyWithImpl<$Res>
    implements $PokemonMoveEffectBreakProtectCopyWith<$Res> {
  _$PokemonMoveEffectBreakProtectCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectBreakProtect _self;
  final $Res Function(PokemonMoveEffectBreakProtect) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,}) {
  return _then(PokemonMoveEffectBreakProtect(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectRequireRecharge extends PokemonMoveEffect {
  const PokemonMoveEffectRequireRecharge({this.targetScope = PokemonMoveEffectTargetScope.self, this.chance, final  String? $type}): $type = $type ?? 'require_recharge',super._();
  factory PokemonMoveEffectRequireRecharge.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectRequireRechargeFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectRequireRechargeCopyWith<PokemonMoveEffectRequireRecharge> get copyWith => _$PokemonMoveEffectRequireRechargeCopyWithImpl<PokemonMoveEffectRequireRecharge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectRequireRechargeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectRequireRecharge&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance);

@override
String toString() {
  return 'PokemonMoveEffect.requireRecharge(targetScope: $targetScope, chance: $chance)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectRequireRechargeCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectRequireRechargeCopyWith(PokemonMoveEffectRequireRecharge value, $Res Function(PokemonMoveEffectRequireRecharge) _then) = _$PokemonMoveEffectRequireRechargeCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance
});




}
/// @nodoc
class _$PokemonMoveEffectRequireRechargeCopyWithImpl<$Res>
    implements $PokemonMoveEffectRequireRechargeCopyWith<$Res> {
  _$PokemonMoveEffectRequireRechargeCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectRequireRecharge _self;
  final $Res Function(PokemonMoveEffectRequireRecharge) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,}) {
  return _then(PokemonMoveEffectRequireRecharge(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectChargeThenStrike extends PokemonMoveEffect {
  const PokemonMoveEffectChargeThenStrike({this.targetScope = PokemonMoveEffectTargetScope.self, this.chance, this.chargeStateId, final  String? $type}): $type = $type ?? 'charge_then_strike',super._();
  factory PokemonMoveEffectChargeThenStrike.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectChargeThenStrikeFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
/// Permet plus tard d'associer un volatile ou un marqueur de charge.
 final  String? chargeStateId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectChargeThenStrikeCopyWith<PokemonMoveEffectChargeThenStrike> get copyWith => _$PokemonMoveEffectChargeThenStrikeCopyWithImpl<PokemonMoveEffectChargeThenStrike>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectChargeThenStrikeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectChargeThenStrike&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.chargeStateId, chargeStateId) || other.chargeStateId == chargeStateId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,chargeStateId);

@override
String toString() {
  return 'PokemonMoveEffect.chargeThenStrike(targetScope: $targetScope, chance: $chance, chargeStateId: $chargeStateId)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectChargeThenStrikeCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectChargeThenStrikeCopyWith(PokemonMoveEffectChargeThenStrike value, $Res Function(PokemonMoveEffectChargeThenStrike) _then) = _$PokemonMoveEffectChargeThenStrikeCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, String? chargeStateId
});




}
/// @nodoc
class _$PokemonMoveEffectChargeThenStrikeCopyWithImpl<$Res>
    implements $PokemonMoveEffectChargeThenStrikeCopyWith<$Res> {
  _$PokemonMoveEffectChargeThenStrikeCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectChargeThenStrike _self;
  final $Res Function(PokemonMoveEffectChargeThenStrike) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? chargeStateId = freezed,}) {
  return _then(PokemonMoveEffectChargeThenStrike(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,chargeStateId: freezed == chargeStateId ? _self.chargeStateId : chargeStateId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectSetSideCondition extends PokemonMoveEffect {
  const PokemonMoveEffectSetSideCondition({this.targetScope = PokemonMoveEffectTargetScope.foeSide, this.chance, required this.conditionId, final  String? $type}): $type = $type ?? 'set_side_condition',super._();
  factory PokemonMoveEffectSetSideCondition.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectSetSideConditionFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  String conditionId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectSetSideConditionCopyWith<PokemonMoveEffectSetSideCondition> get copyWith => _$PokemonMoveEffectSetSideConditionCopyWithImpl<PokemonMoveEffectSetSideCondition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectSetSideConditionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectSetSideCondition&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,conditionId);

@override
String toString() {
  return 'PokemonMoveEffect.setSideCondition(targetScope: $targetScope, chance: $chance, conditionId: $conditionId)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectSetSideConditionCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectSetSideConditionCopyWith(PokemonMoveEffectSetSideCondition value, $Res Function(PokemonMoveEffectSetSideCondition) _then) = _$PokemonMoveEffectSetSideConditionCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, String conditionId
});




}
/// @nodoc
class _$PokemonMoveEffectSetSideConditionCopyWithImpl<$Res>
    implements $PokemonMoveEffectSetSideConditionCopyWith<$Res> {
  _$PokemonMoveEffectSetSideConditionCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectSetSideCondition _self;
  final $Res Function(PokemonMoveEffectSetSideCondition) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? conditionId = null,}) {
  return _then(PokemonMoveEffectSetSideCondition(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,conditionId: null == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveEffectSetSlotCondition extends PokemonMoveEffect {
  const PokemonMoveEffectSetSlotCondition({this.targetScope = PokemonMoveEffectTargetScope.slot, this.chance, required this.conditionId, final  String? $type}): $type = $type ?? 'set_slot_condition',super._();
  factory PokemonMoveEffectSetSlotCondition.fromJson(Map<String, dynamic> json) => _$PokemonMoveEffectSetSlotConditionFromJson(json);

@override@JsonKey() final  PokemonMoveEffectTargetScope targetScope;
@override final  int? chance;
 final  String conditionId;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveEffectSetSlotConditionCopyWith<PokemonMoveEffectSetSlotCondition> get copyWith => _$PokemonMoveEffectSetSlotConditionCopyWithImpl<PokemonMoveEffectSetSlotCondition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveEffectSetSlotConditionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveEffectSetSlotCondition&&(identical(other.targetScope, targetScope) || other.targetScope == targetScope)&&(identical(other.chance, chance) || other.chance == chance)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetScope,chance,conditionId);

@override
String toString() {
  return 'PokemonMoveEffect.setSlotCondition(targetScope: $targetScope, chance: $chance, conditionId: $conditionId)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveEffectSetSlotConditionCopyWith<$Res> implements $PokemonMoveEffectCopyWith<$Res> {
  factory $PokemonMoveEffectSetSlotConditionCopyWith(PokemonMoveEffectSetSlotCondition value, $Res Function(PokemonMoveEffectSetSlotCondition) _then) = _$PokemonMoveEffectSetSlotConditionCopyWithImpl;
@override @useResult
$Res call({
 PokemonMoveEffectTargetScope targetScope, int? chance, String conditionId
});




}
/// @nodoc
class _$PokemonMoveEffectSetSlotConditionCopyWithImpl<$Res>
    implements $PokemonMoveEffectSetSlotConditionCopyWith<$Res> {
  _$PokemonMoveEffectSetSlotConditionCopyWithImpl(this._self, this._then);

  final PokemonMoveEffectSetSlotCondition _self;
  final $Res Function(PokemonMoveEffectSetSlotCondition) _then;

/// Create a copy of PokemonMoveEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetScope = null,Object? chance = freezed,Object? conditionId = null,}) {
  return _then(PokemonMoveEffectSetSlotCondition(
targetScope: null == targetScope ? _self.targetScope : targetScope // ignore: cast_nullable_to_non_nullable
as PokemonMoveEffectTargetScope,chance: freezed == chance ? _self.chance : chance // ignore: cast_nullable_to_non_nullable
as int?,conditionId: null == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
