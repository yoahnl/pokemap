// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rail_journey.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RailJourneyEndpointDoor {

 RailJourneyDoorSide get side; String get stationPlacedElementId; String get vehiclePlacedElementId;
/// Create a copy of RailJourneyEndpointDoor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RailJourneyEndpointDoorCopyWith<RailJourneyEndpointDoor> get copyWith => _$RailJourneyEndpointDoorCopyWithImpl<RailJourneyEndpointDoor>(this as RailJourneyEndpointDoor, _$identity);

  /// Serializes this RailJourneyEndpointDoor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RailJourneyEndpointDoor&&(identical(other.side, side) || other.side == side)&&(identical(other.stationPlacedElementId, stationPlacedElementId) || other.stationPlacedElementId == stationPlacedElementId)&&(identical(other.vehiclePlacedElementId, vehiclePlacedElementId) || other.vehiclePlacedElementId == vehiclePlacedElementId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,side,stationPlacedElementId,vehiclePlacedElementId);

@override
String toString() {
  return 'RailJourneyEndpointDoor(side: $side, stationPlacedElementId: $stationPlacedElementId, vehiclePlacedElementId: $vehiclePlacedElementId)';
}


}

/// @nodoc
abstract mixin class $RailJourneyEndpointDoorCopyWith<$Res>  {
  factory $RailJourneyEndpointDoorCopyWith(RailJourneyEndpointDoor value, $Res Function(RailJourneyEndpointDoor) _then) = _$RailJourneyEndpointDoorCopyWithImpl;
@useResult
$Res call({
 RailJourneyDoorSide side, String stationPlacedElementId, String vehiclePlacedElementId
});




}
/// @nodoc
class _$RailJourneyEndpointDoorCopyWithImpl<$Res>
    implements $RailJourneyEndpointDoorCopyWith<$Res> {
  _$RailJourneyEndpointDoorCopyWithImpl(this._self, this._then);

  final RailJourneyEndpointDoor _self;
  final $Res Function(RailJourneyEndpointDoor) _then;

/// Create a copy of RailJourneyEndpointDoor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? side = null,Object? stationPlacedElementId = null,Object? vehiclePlacedElementId = null,}) {
  return _then(_self.copyWith(
side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as RailJourneyDoorSide,stationPlacedElementId: null == stationPlacedElementId ? _self.stationPlacedElementId : stationPlacedElementId // ignore: cast_nullable_to_non_nullable
as String,vehiclePlacedElementId: null == vehiclePlacedElementId ? _self.vehiclePlacedElementId : vehiclePlacedElementId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RailJourneyEndpointDoor].
extension RailJourneyEndpointDoorPatterns on RailJourneyEndpointDoor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RailJourneyEndpointDoor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RailJourneyEndpointDoor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RailJourneyEndpointDoor value)  $default,){
final _that = this;
switch (_that) {
case _RailJourneyEndpointDoor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RailJourneyEndpointDoor value)?  $default,){
final _that = this;
switch (_that) {
case _RailJourneyEndpointDoor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RailJourneyDoorSide side,  String stationPlacedElementId,  String vehiclePlacedElementId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RailJourneyEndpointDoor() when $default != null:
return $default(_that.side,_that.stationPlacedElementId,_that.vehiclePlacedElementId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RailJourneyDoorSide side,  String stationPlacedElementId,  String vehiclePlacedElementId)  $default,) {final _that = this;
switch (_that) {
case _RailJourneyEndpointDoor():
return $default(_that.side,_that.stationPlacedElementId,_that.vehiclePlacedElementId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RailJourneyDoorSide side,  String stationPlacedElementId,  String vehiclePlacedElementId)?  $default,) {final _that = this;
switch (_that) {
case _RailJourneyEndpointDoor() when $default != null:
return $default(_that.side,_that.stationPlacedElementId,_that.vehiclePlacedElementId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RailJourneyEndpointDoor extends RailJourneyEndpointDoor {
  const _RailJourneyEndpointDoor({required this.side, required this.stationPlacedElementId, required this.vehiclePlacedElementId}): super._();
  factory _RailJourneyEndpointDoor.fromJson(Map<String, dynamic> json) => _$RailJourneyEndpointDoorFromJson(json);

@override final  RailJourneyDoorSide side;
@override final  String stationPlacedElementId;
@override final  String vehiclePlacedElementId;

/// Create a copy of RailJourneyEndpointDoor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RailJourneyEndpointDoorCopyWith<_RailJourneyEndpointDoor> get copyWith => __$RailJourneyEndpointDoorCopyWithImpl<_RailJourneyEndpointDoor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RailJourneyEndpointDoorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RailJourneyEndpointDoor&&(identical(other.side, side) || other.side == side)&&(identical(other.stationPlacedElementId, stationPlacedElementId) || other.stationPlacedElementId == stationPlacedElementId)&&(identical(other.vehiclePlacedElementId, vehiclePlacedElementId) || other.vehiclePlacedElementId == vehiclePlacedElementId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,side,stationPlacedElementId,vehiclePlacedElementId);

@override
String toString() {
  return 'RailJourneyEndpointDoor(side: $side, stationPlacedElementId: $stationPlacedElementId, vehiclePlacedElementId: $vehiclePlacedElementId)';
}


}

/// @nodoc
abstract mixin class _$RailJourneyEndpointDoorCopyWith<$Res> implements $RailJourneyEndpointDoorCopyWith<$Res> {
  factory _$RailJourneyEndpointDoorCopyWith(_RailJourneyEndpointDoor value, $Res Function(_RailJourneyEndpointDoor) _then) = __$RailJourneyEndpointDoorCopyWithImpl;
@override @useResult
$Res call({
 RailJourneyDoorSide side, String stationPlacedElementId, String vehiclePlacedElementId
});




}
/// @nodoc
class __$RailJourneyEndpointDoorCopyWithImpl<$Res>
    implements _$RailJourneyEndpointDoorCopyWith<$Res> {
  __$RailJourneyEndpointDoorCopyWithImpl(this._self, this._then);

  final _RailJourneyEndpointDoor _self;
  final $Res Function(_RailJourneyEndpointDoor) _then;

/// Create a copy of RailJourneyEndpointDoor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? side = null,Object? stationPlacedElementId = null,Object? vehiclePlacedElementId = null,}) {
  return _then(_RailJourneyEndpointDoor(
side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as RailJourneyDoorSide,stationPlacedElementId: null == stationPlacedElementId ? _self.stationPlacedElementId : stationPlacedElementId // ignore: cast_nullable_to_non_nullable
as String,vehiclePlacedElementId: null == vehiclePlacedElementId ? _self.vehiclePlacedElementId : vehiclePlacedElementId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RailJourneyFare {

 RailJourneyFarePolicy get policy; String? get semanticCurrencyId;@JsonKey(fromJson: _railJourneyIntFromJson) int get amount;
/// Create a copy of RailJourneyFare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RailJourneyFareCopyWith<RailJourneyFare> get copyWith => _$RailJourneyFareCopyWithImpl<RailJourneyFare>(this as RailJourneyFare, _$identity);

  /// Serializes this RailJourneyFare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RailJourneyFare&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.semanticCurrencyId, semanticCurrencyId) || other.semanticCurrencyId == semanticCurrencyId)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,policy,semanticCurrencyId,amount);

@override
String toString() {
  return 'RailJourneyFare(policy: $policy, semanticCurrencyId: $semanticCurrencyId, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $RailJourneyFareCopyWith<$Res>  {
  factory $RailJourneyFareCopyWith(RailJourneyFare value, $Res Function(RailJourneyFare) _then) = _$RailJourneyFareCopyWithImpl;
@useResult
$Res call({
 RailJourneyFarePolicy policy, String? semanticCurrencyId,@JsonKey(fromJson: _railJourneyIntFromJson) int amount
});




}
/// @nodoc
class _$RailJourneyFareCopyWithImpl<$Res>
    implements $RailJourneyFareCopyWith<$Res> {
  _$RailJourneyFareCopyWithImpl(this._self, this._then);

  final RailJourneyFare _self;
  final $Res Function(RailJourneyFare) _then;

/// Create a copy of RailJourneyFare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? policy = null,Object? semanticCurrencyId = freezed,Object? amount = null,}) {
  return _then(_self.copyWith(
policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as RailJourneyFarePolicy,semanticCurrencyId: freezed == semanticCurrencyId ? _self.semanticCurrencyId : semanticCurrencyId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RailJourneyFare].
extension RailJourneyFarePatterns on RailJourneyFare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RailJourneyFare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RailJourneyFare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RailJourneyFare value)  $default,){
final _that = this;
switch (_that) {
case _RailJourneyFare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RailJourneyFare value)?  $default,){
final _that = this;
switch (_that) {
case _RailJourneyFare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RailJourneyFarePolicy policy,  String? semanticCurrencyId, @JsonKey(fromJson: _railJourneyIntFromJson)  int amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RailJourneyFare() when $default != null:
return $default(_that.policy,_that.semanticCurrencyId,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RailJourneyFarePolicy policy,  String? semanticCurrencyId, @JsonKey(fromJson: _railJourneyIntFromJson)  int amount)  $default,) {final _that = this;
switch (_that) {
case _RailJourneyFare():
return $default(_that.policy,_that.semanticCurrencyId,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RailJourneyFarePolicy policy,  String? semanticCurrencyId, @JsonKey(fromJson: _railJourneyIntFromJson)  int amount)?  $default,) {final _that = this;
switch (_that) {
case _RailJourneyFare() when $default != null:
return $default(_that.policy,_that.semanticCurrencyId,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RailJourneyFare extends RailJourneyFare {
  const _RailJourneyFare({required this.policy, this.semanticCurrencyId, @JsonKey(fromJson: _railJourneyIntFromJson) this.amount = 0}): super._();
  factory _RailJourneyFare.fromJson(Map<String, dynamic> json) => _$RailJourneyFareFromJson(json);

@override final  RailJourneyFarePolicy policy;
@override final  String? semanticCurrencyId;
@override@JsonKey(fromJson: _railJourneyIntFromJson) final  int amount;

/// Create a copy of RailJourneyFare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RailJourneyFareCopyWith<_RailJourneyFare> get copyWith => __$RailJourneyFareCopyWithImpl<_RailJourneyFare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RailJourneyFareToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RailJourneyFare&&(identical(other.policy, policy) || other.policy == policy)&&(identical(other.semanticCurrencyId, semanticCurrencyId) || other.semanticCurrencyId == semanticCurrencyId)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,policy,semanticCurrencyId,amount);

@override
String toString() {
  return 'RailJourneyFare(policy: $policy, semanticCurrencyId: $semanticCurrencyId, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$RailJourneyFareCopyWith<$Res> implements $RailJourneyFareCopyWith<$Res> {
  factory _$RailJourneyFareCopyWith(_RailJourneyFare value, $Res Function(_RailJourneyFare) _then) = __$RailJourneyFareCopyWithImpl;
@override @useResult
$Res call({
 RailJourneyFarePolicy policy, String? semanticCurrencyId,@JsonKey(fromJson: _railJourneyIntFromJson) int amount
});




}
/// @nodoc
class __$RailJourneyFareCopyWithImpl<$Res>
    implements _$RailJourneyFareCopyWith<$Res> {
  __$RailJourneyFareCopyWithImpl(this._self, this._then);

  final _RailJourneyFare _self;
  final $Res Function(_RailJourneyFare) _then;

/// Create a copy of RailJourneyFare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? policy = null,Object? semanticCurrencyId = freezed,Object? amount = null,}) {
  return _then(_RailJourneyFare(
policy: null == policy ? _self.policy : policy // ignore: cast_nullable_to_non_nullable
as RailJourneyFarePolicy,semanticCurrencyId: freezed == semanticCurrencyId ? _self.semanticCurrencyId : semanticCurrencyId // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RailJourneyRequirements {

 Set<String> get completedStoryStepIds; Set<String> get requiredFactIds; Set<String> get requiredAnyFactIds; Set<String> get requiredItemIds; Set<String> get requiredStampIds;
/// Create a copy of RailJourneyRequirements
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RailJourneyRequirementsCopyWith<RailJourneyRequirements> get copyWith => _$RailJourneyRequirementsCopyWithImpl<RailJourneyRequirements>(this as RailJourneyRequirements, _$identity);

  /// Serializes this RailJourneyRequirements to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RailJourneyRequirements&&const DeepCollectionEquality().equals(other.completedStoryStepIds, completedStoryStepIds)&&const DeepCollectionEquality().equals(other.requiredFactIds, requiredFactIds)&&const DeepCollectionEquality().equals(other.requiredAnyFactIds, requiredAnyFactIds)&&const DeepCollectionEquality().equals(other.requiredItemIds, requiredItemIds)&&const DeepCollectionEquality().equals(other.requiredStampIds, requiredStampIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(completedStoryStepIds),const DeepCollectionEquality().hash(requiredFactIds),const DeepCollectionEquality().hash(requiredAnyFactIds),const DeepCollectionEquality().hash(requiredItemIds),const DeepCollectionEquality().hash(requiredStampIds));

@override
String toString() {
  return 'RailJourneyRequirements(completedStoryStepIds: $completedStoryStepIds, requiredFactIds: $requiredFactIds, requiredAnyFactIds: $requiredAnyFactIds, requiredItemIds: $requiredItemIds, requiredStampIds: $requiredStampIds)';
}


}

/// @nodoc
abstract mixin class $RailJourneyRequirementsCopyWith<$Res>  {
  factory $RailJourneyRequirementsCopyWith(RailJourneyRequirements value, $Res Function(RailJourneyRequirements) _then) = _$RailJourneyRequirementsCopyWithImpl;
@useResult
$Res call({
 Set<String> completedStoryStepIds, Set<String> requiredFactIds, Set<String> requiredAnyFactIds, Set<String> requiredItemIds, Set<String> requiredStampIds
});




}
/// @nodoc
class _$RailJourneyRequirementsCopyWithImpl<$Res>
    implements $RailJourneyRequirementsCopyWith<$Res> {
  _$RailJourneyRequirementsCopyWithImpl(this._self, this._then);

  final RailJourneyRequirements _self;
  final $Res Function(RailJourneyRequirements) _then;

/// Create a copy of RailJourneyRequirements
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completedStoryStepIds = null,Object? requiredFactIds = null,Object? requiredAnyFactIds = null,Object? requiredItemIds = null,Object? requiredStampIds = null,}) {
  return _then(_self.copyWith(
completedStoryStepIds: null == completedStoryStepIds ? _self.completedStoryStepIds : completedStoryStepIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requiredFactIds: null == requiredFactIds ? _self.requiredFactIds : requiredFactIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requiredAnyFactIds: null == requiredAnyFactIds ? _self.requiredAnyFactIds : requiredAnyFactIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requiredItemIds: null == requiredItemIds ? _self.requiredItemIds : requiredItemIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requiredStampIds: null == requiredStampIds ? _self.requiredStampIds : requiredStampIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RailJourneyRequirements].
extension RailJourneyRequirementsPatterns on RailJourneyRequirements {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RailJourneyRequirements value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RailJourneyRequirements() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RailJourneyRequirements value)  $default,){
final _that = this;
switch (_that) {
case _RailJourneyRequirements():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RailJourneyRequirements value)?  $default,){
final _that = this;
switch (_that) {
case _RailJourneyRequirements() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<String> completedStoryStepIds,  Set<String> requiredFactIds,  Set<String> requiredAnyFactIds,  Set<String> requiredItemIds,  Set<String> requiredStampIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RailJourneyRequirements() when $default != null:
return $default(_that.completedStoryStepIds,_that.requiredFactIds,_that.requiredAnyFactIds,_that.requiredItemIds,_that.requiredStampIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<String> completedStoryStepIds,  Set<String> requiredFactIds,  Set<String> requiredAnyFactIds,  Set<String> requiredItemIds,  Set<String> requiredStampIds)  $default,) {final _that = this;
switch (_that) {
case _RailJourneyRequirements():
return $default(_that.completedStoryStepIds,_that.requiredFactIds,_that.requiredAnyFactIds,_that.requiredItemIds,_that.requiredStampIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<String> completedStoryStepIds,  Set<String> requiredFactIds,  Set<String> requiredAnyFactIds,  Set<String> requiredItemIds,  Set<String> requiredStampIds)?  $default,) {final _that = this;
switch (_that) {
case _RailJourneyRequirements() when $default != null:
return $default(_that.completedStoryStepIds,_that.requiredFactIds,_that.requiredAnyFactIds,_that.requiredItemIds,_that.requiredStampIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RailJourneyRequirements extends RailJourneyRequirements {
  const _RailJourneyRequirements({final  Set<String> completedStoryStepIds = const <String>{}, final  Set<String> requiredFactIds = const <String>{}, final  Set<String> requiredAnyFactIds = const <String>{}, final  Set<String> requiredItemIds = const <String>{}, final  Set<String> requiredStampIds = const <String>{}}): _completedStoryStepIds = completedStoryStepIds,_requiredFactIds = requiredFactIds,_requiredAnyFactIds = requiredAnyFactIds,_requiredItemIds = requiredItemIds,_requiredStampIds = requiredStampIds,super._();
  factory _RailJourneyRequirements.fromJson(Map<String, dynamic> json) => _$RailJourneyRequirementsFromJson(json);

 final  Set<String> _completedStoryStepIds;
@override@JsonKey() Set<String> get completedStoryStepIds {
  if (_completedStoryStepIds is EqualUnmodifiableSetView) return _completedStoryStepIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_completedStoryStepIds);
}

 final  Set<String> _requiredFactIds;
@override@JsonKey() Set<String> get requiredFactIds {
  if (_requiredFactIds is EqualUnmodifiableSetView) return _requiredFactIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_requiredFactIds);
}

 final  Set<String> _requiredAnyFactIds;
@override@JsonKey() Set<String> get requiredAnyFactIds {
  if (_requiredAnyFactIds is EqualUnmodifiableSetView) return _requiredAnyFactIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_requiredAnyFactIds);
}

 final  Set<String> _requiredItemIds;
@override@JsonKey() Set<String> get requiredItemIds {
  if (_requiredItemIds is EqualUnmodifiableSetView) return _requiredItemIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_requiredItemIds);
}

 final  Set<String> _requiredStampIds;
@override@JsonKey() Set<String> get requiredStampIds {
  if (_requiredStampIds is EqualUnmodifiableSetView) return _requiredStampIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_requiredStampIds);
}


/// Create a copy of RailJourneyRequirements
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RailJourneyRequirementsCopyWith<_RailJourneyRequirements> get copyWith => __$RailJourneyRequirementsCopyWithImpl<_RailJourneyRequirements>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RailJourneyRequirementsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RailJourneyRequirements&&const DeepCollectionEquality().equals(other._completedStoryStepIds, _completedStoryStepIds)&&const DeepCollectionEquality().equals(other._requiredFactIds, _requiredFactIds)&&const DeepCollectionEquality().equals(other._requiredAnyFactIds, _requiredAnyFactIds)&&const DeepCollectionEquality().equals(other._requiredItemIds, _requiredItemIds)&&const DeepCollectionEquality().equals(other._requiredStampIds, _requiredStampIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_completedStoryStepIds),const DeepCollectionEquality().hash(_requiredFactIds),const DeepCollectionEquality().hash(_requiredAnyFactIds),const DeepCollectionEquality().hash(_requiredItemIds),const DeepCollectionEquality().hash(_requiredStampIds));

@override
String toString() {
  return 'RailJourneyRequirements(completedStoryStepIds: $completedStoryStepIds, requiredFactIds: $requiredFactIds, requiredAnyFactIds: $requiredAnyFactIds, requiredItemIds: $requiredItemIds, requiredStampIds: $requiredStampIds)';
}


}

/// @nodoc
abstract mixin class _$RailJourneyRequirementsCopyWith<$Res> implements $RailJourneyRequirementsCopyWith<$Res> {
  factory _$RailJourneyRequirementsCopyWith(_RailJourneyRequirements value, $Res Function(_RailJourneyRequirements) _then) = __$RailJourneyRequirementsCopyWithImpl;
@override @useResult
$Res call({
 Set<String> completedStoryStepIds, Set<String> requiredFactIds, Set<String> requiredAnyFactIds, Set<String> requiredItemIds, Set<String> requiredStampIds
});




}
/// @nodoc
class __$RailJourneyRequirementsCopyWithImpl<$Res>
    implements _$RailJourneyRequirementsCopyWith<$Res> {
  __$RailJourneyRequirementsCopyWithImpl(this._self, this._then);

  final _RailJourneyRequirements _self;
  final $Res Function(_RailJourneyRequirements) _then;

/// Create a copy of RailJourneyRequirements
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completedStoryStepIds = null,Object? requiredFactIds = null,Object? requiredAnyFactIds = null,Object? requiredItemIds = null,Object? requiredStampIds = null,}) {
  return _then(_RailJourneyRequirements(
completedStoryStepIds: null == completedStoryStepIds ? _self._completedStoryStepIds : completedStoryStepIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requiredFactIds: null == requiredFactIds ? _self._requiredFactIds : requiredFactIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requiredAnyFactIds: null == requiredAnyFactIds ? _self._requiredAnyFactIds : requiredAnyFactIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requiredItemIds: null == requiredItemIds ? _self._requiredItemIds : requiredItemIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requiredStampIds: null == requiredStampIds ? _self._requiredStampIds : requiredStampIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}


/// @nodoc
mixin _$RailJourneyEndpoint {

 String get stationMapId;@JsonKey(fromJson: _mapRectFromJson, toJson: _mapRectToJson) MapRect get boardingArea; GridPos get trainEntryPos; GridPos get stationArrivalPos; List<RailJourneyEndpointDoor> get doors;
/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RailJourneyEndpointCopyWith<RailJourneyEndpoint> get copyWith => _$RailJourneyEndpointCopyWithImpl<RailJourneyEndpoint>(this as RailJourneyEndpoint, _$identity);

  /// Serializes this RailJourneyEndpoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RailJourneyEndpoint&&(identical(other.stationMapId, stationMapId) || other.stationMapId == stationMapId)&&(identical(other.boardingArea, boardingArea) || other.boardingArea == boardingArea)&&(identical(other.trainEntryPos, trainEntryPos) || other.trainEntryPos == trainEntryPos)&&(identical(other.stationArrivalPos, stationArrivalPos) || other.stationArrivalPos == stationArrivalPos)&&const DeepCollectionEquality().equals(other.doors, doors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stationMapId,boardingArea,trainEntryPos,stationArrivalPos,const DeepCollectionEquality().hash(doors));

@override
String toString() {
  return 'RailJourneyEndpoint(stationMapId: $stationMapId, boardingArea: $boardingArea, trainEntryPos: $trainEntryPos, stationArrivalPos: $stationArrivalPos, doors: $doors)';
}


}

/// @nodoc
abstract mixin class $RailJourneyEndpointCopyWith<$Res>  {
  factory $RailJourneyEndpointCopyWith(RailJourneyEndpoint value, $Res Function(RailJourneyEndpoint) _then) = _$RailJourneyEndpointCopyWithImpl;
@useResult
$Res call({
 String stationMapId,@JsonKey(fromJson: _mapRectFromJson, toJson: _mapRectToJson) MapRect boardingArea, GridPos trainEntryPos, GridPos stationArrivalPos, List<RailJourneyEndpointDoor> doors
});


$MapRectCopyWith<$Res> get boardingArea;$GridPosCopyWith<$Res> get trainEntryPos;$GridPosCopyWith<$Res> get stationArrivalPos;

}
/// @nodoc
class _$RailJourneyEndpointCopyWithImpl<$Res>
    implements $RailJourneyEndpointCopyWith<$Res> {
  _$RailJourneyEndpointCopyWithImpl(this._self, this._then);

  final RailJourneyEndpoint _self;
  final $Res Function(RailJourneyEndpoint) _then;

/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stationMapId = null,Object? boardingArea = null,Object? trainEntryPos = null,Object? stationArrivalPos = null,Object? doors = null,}) {
  return _then(_self.copyWith(
stationMapId: null == stationMapId ? _self.stationMapId : stationMapId // ignore: cast_nullable_to_non_nullable
as String,boardingArea: null == boardingArea ? _self.boardingArea : boardingArea // ignore: cast_nullable_to_non_nullable
as MapRect,trainEntryPos: null == trainEntryPos ? _self.trainEntryPos : trainEntryPos // ignore: cast_nullable_to_non_nullable
as GridPos,stationArrivalPos: null == stationArrivalPos ? _self.stationArrivalPos : stationArrivalPos // ignore: cast_nullable_to_non_nullable
as GridPos,doors: null == doors ? _self.doors : doors // ignore: cast_nullable_to_non_nullable
as List<RailJourneyEndpointDoor>,
  ));
}
/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapRectCopyWith<$Res> get boardingArea {
  
  return $MapRectCopyWith<$Res>(_self.boardingArea, (value) {
    return _then(_self.copyWith(boardingArea: value));
  });
}/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get trainEntryPos {
  
  return $GridPosCopyWith<$Res>(_self.trainEntryPos, (value) {
    return _then(_self.copyWith(trainEntryPos: value));
  });
}/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get stationArrivalPos {
  
  return $GridPosCopyWith<$Res>(_self.stationArrivalPos, (value) {
    return _then(_self.copyWith(stationArrivalPos: value));
  });
}
}


/// Adds pattern-matching-related methods to [RailJourneyEndpoint].
extension RailJourneyEndpointPatterns on RailJourneyEndpoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RailJourneyEndpoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RailJourneyEndpoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RailJourneyEndpoint value)  $default,){
final _that = this;
switch (_that) {
case _RailJourneyEndpoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RailJourneyEndpoint value)?  $default,){
final _that = this;
switch (_that) {
case _RailJourneyEndpoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stationMapId, @JsonKey(fromJson: _mapRectFromJson, toJson: _mapRectToJson)  MapRect boardingArea,  GridPos trainEntryPos,  GridPos stationArrivalPos,  List<RailJourneyEndpointDoor> doors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RailJourneyEndpoint() when $default != null:
return $default(_that.stationMapId,_that.boardingArea,_that.trainEntryPos,_that.stationArrivalPos,_that.doors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stationMapId, @JsonKey(fromJson: _mapRectFromJson, toJson: _mapRectToJson)  MapRect boardingArea,  GridPos trainEntryPos,  GridPos stationArrivalPos,  List<RailJourneyEndpointDoor> doors)  $default,) {final _that = this;
switch (_that) {
case _RailJourneyEndpoint():
return $default(_that.stationMapId,_that.boardingArea,_that.trainEntryPos,_that.stationArrivalPos,_that.doors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stationMapId, @JsonKey(fromJson: _mapRectFromJson, toJson: _mapRectToJson)  MapRect boardingArea,  GridPos trainEntryPos,  GridPos stationArrivalPos,  List<RailJourneyEndpointDoor> doors)?  $default,) {final _that = this;
switch (_that) {
case _RailJourneyEndpoint() when $default != null:
return $default(_that.stationMapId,_that.boardingArea,_that.trainEntryPos,_that.stationArrivalPos,_that.doors);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _RailJourneyEndpoint extends RailJourneyEndpoint {
  const _RailJourneyEndpoint({required this.stationMapId, @JsonKey(fromJson: _mapRectFromJson, toJson: _mapRectToJson) required this.boardingArea, required this.trainEntryPos, required this.stationArrivalPos, required final  List<RailJourneyEndpointDoor> doors}): _doors = doors,super._();
  factory _RailJourneyEndpoint.fromJson(Map<String, dynamic> json) => _$RailJourneyEndpointFromJson(json);

@override final  String stationMapId;
@override@JsonKey(fromJson: _mapRectFromJson, toJson: _mapRectToJson) final  MapRect boardingArea;
@override final  GridPos trainEntryPos;
@override final  GridPos stationArrivalPos;
 final  List<RailJourneyEndpointDoor> _doors;
@override List<RailJourneyEndpointDoor> get doors {
  if (_doors is EqualUnmodifiableListView) return _doors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_doors);
}


/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RailJourneyEndpointCopyWith<_RailJourneyEndpoint> get copyWith => __$RailJourneyEndpointCopyWithImpl<_RailJourneyEndpoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RailJourneyEndpointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RailJourneyEndpoint&&(identical(other.stationMapId, stationMapId) || other.stationMapId == stationMapId)&&(identical(other.boardingArea, boardingArea) || other.boardingArea == boardingArea)&&(identical(other.trainEntryPos, trainEntryPos) || other.trainEntryPos == trainEntryPos)&&(identical(other.stationArrivalPos, stationArrivalPos) || other.stationArrivalPos == stationArrivalPos)&&const DeepCollectionEquality().equals(other._doors, _doors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stationMapId,boardingArea,trainEntryPos,stationArrivalPos,const DeepCollectionEquality().hash(_doors));

@override
String toString() {
  return 'RailJourneyEndpoint(stationMapId: $stationMapId, boardingArea: $boardingArea, trainEntryPos: $trainEntryPos, stationArrivalPos: $stationArrivalPos, doors: $doors)';
}


}

/// @nodoc
abstract mixin class _$RailJourneyEndpointCopyWith<$Res> implements $RailJourneyEndpointCopyWith<$Res> {
  factory _$RailJourneyEndpointCopyWith(_RailJourneyEndpoint value, $Res Function(_RailJourneyEndpoint) _then) = __$RailJourneyEndpointCopyWithImpl;
@override @useResult
$Res call({
 String stationMapId,@JsonKey(fromJson: _mapRectFromJson, toJson: _mapRectToJson) MapRect boardingArea, GridPos trainEntryPos, GridPos stationArrivalPos, List<RailJourneyEndpointDoor> doors
});


@override $MapRectCopyWith<$Res> get boardingArea;@override $GridPosCopyWith<$Res> get trainEntryPos;@override $GridPosCopyWith<$Res> get stationArrivalPos;

}
/// @nodoc
class __$RailJourneyEndpointCopyWithImpl<$Res>
    implements _$RailJourneyEndpointCopyWith<$Res> {
  __$RailJourneyEndpointCopyWithImpl(this._self, this._then);

  final _RailJourneyEndpoint _self;
  final $Res Function(_RailJourneyEndpoint) _then;

/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stationMapId = null,Object? boardingArea = null,Object? trainEntryPos = null,Object? stationArrivalPos = null,Object? doors = null,}) {
  return _then(_RailJourneyEndpoint(
stationMapId: null == stationMapId ? _self.stationMapId : stationMapId // ignore: cast_nullable_to_non_nullable
as String,boardingArea: null == boardingArea ? _self.boardingArea : boardingArea // ignore: cast_nullable_to_non_nullable
as MapRect,trainEntryPos: null == trainEntryPos ? _self.trainEntryPos : trainEntryPos // ignore: cast_nullable_to_non_nullable
as GridPos,stationArrivalPos: null == stationArrivalPos ? _self.stationArrivalPos : stationArrivalPos // ignore: cast_nullable_to_non_nullable
as GridPos,doors: null == doors ? _self._doors : doors // ignore: cast_nullable_to_non_nullable
as List<RailJourneyEndpointDoor>,
  ));
}

/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapRectCopyWith<$Res> get boardingArea {
  
  return $MapRectCopyWith<$Res>(_self.boardingArea, (value) {
    return _then(_self.copyWith(boardingArea: value));
  });
}/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get trainEntryPos {
  
  return $GridPosCopyWith<$Res>(_self.trainEntryPos, (value) {
    return _then(_self.copyWith(trainEntryPos: value));
  });
}/// Create a copy of RailJourneyEndpoint
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get stationArrivalPos {
  
  return $GridPosCopyWith<$Res>(_self.stationArrivalPos, (value) {
    return _then(_self.copyWith(stationArrivalPos: value));
  });
}
}


/// @nodoc
mixin _$RailJourneyDefinition {

 String get id; String get label; RailJourneyEndpoint get origin; RailJourneyEndpoint get destination; String get vehicleMapId; RailJourneyVehicleVariant get vehicleVariant; String get shellState; RailJourneyFare get fare; RailJourneyRequirements get requirements;
/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RailJourneyDefinitionCopyWith<RailJourneyDefinition> get copyWith => _$RailJourneyDefinitionCopyWithImpl<RailJourneyDefinition>(this as RailJourneyDefinition, _$identity);

  /// Serializes this RailJourneyDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RailJourneyDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.vehicleMapId, vehicleMapId) || other.vehicleMapId == vehicleMapId)&&(identical(other.vehicleVariant, vehicleVariant) || other.vehicleVariant == vehicleVariant)&&(identical(other.shellState, shellState) || other.shellState == shellState)&&(identical(other.fare, fare) || other.fare == fare)&&(identical(other.requirements, requirements) || other.requirements == requirements));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,origin,destination,vehicleMapId,vehicleVariant,shellState,fare,requirements);

@override
String toString() {
  return 'RailJourneyDefinition(id: $id, label: $label, origin: $origin, destination: $destination, vehicleMapId: $vehicleMapId, vehicleVariant: $vehicleVariant, shellState: $shellState, fare: $fare, requirements: $requirements)';
}


}

/// @nodoc
abstract mixin class $RailJourneyDefinitionCopyWith<$Res>  {
  factory $RailJourneyDefinitionCopyWith(RailJourneyDefinition value, $Res Function(RailJourneyDefinition) _then) = _$RailJourneyDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String label, RailJourneyEndpoint origin, RailJourneyEndpoint destination, String vehicleMapId, RailJourneyVehicleVariant vehicleVariant, String shellState, RailJourneyFare fare, RailJourneyRequirements requirements
});


$RailJourneyEndpointCopyWith<$Res> get origin;$RailJourneyEndpointCopyWith<$Res> get destination;$RailJourneyFareCopyWith<$Res> get fare;$RailJourneyRequirementsCopyWith<$Res> get requirements;

}
/// @nodoc
class _$RailJourneyDefinitionCopyWithImpl<$Res>
    implements $RailJourneyDefinitionCopyWith<$Res> {
  _$RailJourneyDefinitionCopyWithImpl(this._self, this._then);

  final RailJourneyDefinition _self;
  final $Res Function(RailJourneyDefinition) _then;

/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? origin = null,Object? destination = null,Object? vehicleMapId = null,Object? vehicleVariant = null,Object? shellState = null,Object? fare = null,Object? requirements = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as RailJourneyEndpoint,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as RailJourneyEndpoint,vehicleMapId: null == vehicleMapId ? _self.vehicleMapId : vehicleMapId // ignore: cast_nullable_to_non_nullable
as String,vehicleVariant: null == vehicleVariant ? _self.vehicleVariant : vehicleVariant // ignore: cast_nullable_to_non_nullable
as RailJourneyVehicleVariant,shellState: null == shellState ? _self.shellState : shellState // ignore: cast_nullable_to_non_nullable
as String,fare: null == fare ? _self.fare : fare // ignore: cast_nullable_to_non_nullable
as RailJourneyFare,requirements: null == requirements ? _self.requirements : requirements // ignore: cast_nullable_to_non_nullable
as RailJourneyRequirements,
  ));
}
/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyEndpointCopyWith<$Res> get origin {
  
  return $RailJourneyEndpointCopyWith<$Res>(_self.origin, (value) {
    return _then(_self.copyWith(origin: value));
  });
}/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyEndpointCopyWith<$Res> get destination {
  
  return $RailJourneyEndpointCopyWith<$Res>(_self.destination, (value) {
    return _then(_self.copyWith(destination: value));
  });
}/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyFareCopyWith<$Res> get fare {
  
  return $RailJourneyFareCopyWith<$Res>(_self.fare, (value) {
    return _then(_self.copyWith(fare: value));
  });
}/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyRequirementsCopyWith<$Res> get requirements {
  
  return $RailJourneyRequirementsCopyWith<$Res>(_self.requirements, (value) {
    return _then(_self.copyWith(requirements: value));
  });
}
}


/// Adds pattern-matching-related methods to [RailJourneyDefinition].
extension RailJourneyDefinitionPatterns on RailJourneyDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RailJourneyDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RailJourneyDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RailJourneyDefinition value)  $default,){
final _that = this;
switch (_that) {
case _RailJourneyDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RailJourneyDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _RailJourneyDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  RailJourneyEndpoint origin,  RailJourneyEndpoint destination,  String vehicleMapId,  RailJourneyVehicleVariant vehicleVariant,  String shellState,  RailJourneyFare fare,  RailJourneyRequirements requirements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RailJourneyDefinition() when $default != null:
return $default(_that.id,_that.label,_that.origin,_that.destination,_that.vehicleMapId,_that.vehicleVariant,_that.shellState,_that.fare,_that.requirements);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  RailJourneyEndpoint origin,  RailJourneyEndpoint destination,  String vehicleMapId,  RailJourneyVehicleVariant vehicleVariant,  String shellState,  RailJourneyFare fare,  RailJourneyRequirements requirements)  $default,) {final _that = this;
switch (_that) {
case _RailJourneyDefinition():
return $default(_that.id,_that.label,_that.origin,_that.destination,_that.vehicleMapId,_that.vehicleVariant,_that.shellState,_that.fare,_that.requirements);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  RailJourneyEndpoint origin,  RailJourneyEndpoint destination,  String vehicleMapId,  RailJourneyVehicleVariant vehicleVariant,  String shellState,  RailJourneyFare fare,  RailJourneyRequirements requirements)?  $default,) {final _that = this;
switch (_that) {
case _RailJourneyDefinition() when $default != null:
return $default(_that.id,_that.label,_that.origin,_that.destination,_that.vehicleMapId,_that.vehicleVariant,_that.shellState,_that.fare,_that.requirements);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _RailJourneyDefinition extends RailJourneyDefinition {
  const _RailJourneyDefinition({required this.id, required this.label, required this.origin, required this.destination, required this.vehicleMapId, required this.vehicleVariant, required this.shellState, required this.fare, this.requirements = const RailJourneyRequirements()}): super._();
  factory _RailJourneyDefinition.fromJson(Map<String, dynamic> json) => _$RailJourneyDefinitionFromJson(json);

@override final  String id;
@override final  String label;
@override final  RailJourneyEndpoint origin;
@override final  RailJourneyEndpoint destination;
@override final  String vehicleMapId;
@override final  RailJourneyVehicleVariant vehicleVariant;
@override final  String shellState;
@override final  RailJourneyFare fare;
@override@JsonKey() final  RailJourneyRequirements requirements;

/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RailJourneyDefinitionCopyWith<_RailJourneyDefinition> get copyWith => __$RailJourneyDefinitionCopyWithImpl<_RailJourneyDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RailJourneyDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RailJourneyDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.destination, destination) || other.destination == destination)&&(identical(other.vehicleMapId, vehicleMapId) || other.vehicleMapId == vehicleMapId)&&(identical(other.vehicleVariant, vehicleVariant) || other.vehicleVariant == vehicleVariant)&&(identical(other.shellState, shellState) || other.shellState == shellState)&&(identical(other.fare, fare) || other.fare == fare)&&(identical(other.requirements, requirements) || other.requirements == requirements));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,origin,destination,vehicleMapId,vehicleVariant,shellState,fare,requirements);

@override
String toString() {
  return 'RailJourneyDefinition(id: $id, label: $label, origin: $origin, destination: $destination, vehicleMapId: $vehicleMapId, vehicleVariant: $vehicleVariant, shellState: $shellState, fare: $fare, requirements: $requirements)';
}


}

/// @nodoc
abstract mixin class _$RailJourneyDefinitionCopyWith<$Res> implements $RailJourneyDefinitionCopyWith<$Res> {
  factory _$RailJourneyDefinitionCopyWith(_RailJourneyDefinition value, $Res Function(_RailJourneyDefinition) _then) = __$RailJourneyDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, RailJourneyEndpoint origin, RailJourneyEndpoint destination, String vehicleMapId, RailJourneyVehicleVariant vehicleVariant, String shellState, RailJourneyFare fare, RailJourneyRequirements requirements
});


@override $RailJourneyEndpointCopyWith<$Res> get origin;@override $RailJourneyEndpointCopyWith<$Res> get destination;@override $RailJourneyFareCopyWith<$Res> get fare;@override $RailJourneyRequirementsCopyWith<$Res> get requirements;

}
/// @nodoc
class __$RailJourneyDefinitionCopyWithImpl<$Res>
    implements _$RailJourneyDefinitionCopyWith<$Res> {
  __$RailJourneyDefinitionCopyWithImpl(this._self, this._then);

  final _RailJourneyDefinition _self;
  final $Res Function(_RailJourneyDefinition) _then;

/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? origin = null,Object? destination = null,Object? vehicleMapId = null,Object? vehicleVariant = null,Object? shellState = null,Object? fare = null,Object? requirements = null,}) {
  return _then(_RailJourneyDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as RailJourneyEndpoint,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as RailJourneyEndpoint,vehicleMapId: null == vehicleMapId ? _self.vehicleMapId : vehicleMapId // ignore: cast_nullable_to_non_nullable
as String,vehicleVariant: null == vehicleVariant ? _self.vehicleVariant : vehicleVariant // ignore: cast_nullable_to_non_nullable
as RailJourneyVehicleVariant,shellState: null == shellState ? _self.shellState : shellState // ignore: cast_nullable_to_non_nullable
as String,fare: null == fare ? _self.fare : fare // ignore: cast_nullable_to_non_nullable
as RailJourneyFare,requirements: null == requirements ? _self.requirements : requirements // ignore: cast_nullable_to_non_nullable
as RailJourneyRequirements,
  ));
}

/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyEndpointCopyWith<$Res> get origin {
  
  return $RailJourneyEndpointCopyWith<$Res>(_self.origin, (value) {
    return _then(_self.copyWith(origin: value));
  });
}/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyEndpointCopyWith<$Res> get destination {
  
  return $RailJourneyEndpointCopyWith<$Res>(_self.destination, (value) {
    return _then(_self.copyWith(destination: value));
  });
}/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyFareCopyWith<$Res> get fare {
  
  return $RailJourneyFareCopyWith<$Res>(_self.fare, (value) {
    return _then(_self.copyWith(fare: value));
  });
}/// Create a copy of RailJourneyDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyRequirementsCopyWith<$Res> get requirements {
  
  return $RailJourneyRequirementsCopyWith<$Res>(_self.requirements, (value) {
    return _then(_self.copyWith(requirements: value));
  });
}
}


/// @nodoc
mixin _$RailJourneyCatalog {

@JsonKey(fromJson: _railJourneyIntFromJson) int get schemaVersion; List<RailJourneyDefinition> get journeys;
/// Create a copy of RailJourneyCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RailJourneyCatalogCopyWith<RailJourneyCatalog> get copyWith => _$RailJourneyCatalogCopyWithImpl<RailJourneyCatalog>(this as RailJourneyCatalog, _$identity);

  /// Serializes this RailJourneyCatalog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RailJourneyCatalog&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other.journeys, journeys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,const DeepCollectionEquality().hash(journeys));

@override
String toString() {
  return 'RailJourneyCatalog(schemaVersion: $schemaVersion, journeys: $journeys)';
}


}

/// @nodoc
abstract mixin class $RailJourneyCatalogCopyWith<$Res>  {
  factory $RailJourneyCatalogCopyWith(RailJourneyCatalog value, $Res Function(RailJourneyCatalog) _then) = _$RailJourneyCatalogCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _railJourneyIntFromJson) int schemaVersion, List<RailJourneyDefinition> journeys
});




}
/// @nodoc
class _$RailJourneyCatalogCopyWithImpl<$Res>
    implements $RailJourneyCatalogCopyWith<$Res> {
  _$RailJourneyCatalogCopyWithImpl(this._self, this._then);

  final RailJourneyCatalog _self;
  final $Res Function(RailJourneyCatalog) _then;

/// Create a copy of RailJourneyCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? journeys = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,journeys: null == journeys ? _self.journeys : journeys // ignore: cast_nullable_to_non_nullable
as List<RailJourneyDefinition>,
  ));
}

}


/// Adds pattern-matching-related methods to [RailJourneyCatalog].
extension RailJourneyCatalogPatterns on RailJourneyCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RailJourneyCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RailJourneyCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RailJourneyCatalog value)  $default,){
final _that = this;
switch (_that) {
case _RailJourneyCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RailJourneyCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _RailJourneyCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _railJourneyIntFromJson)  int schemaVersion,  List<RailJourneyDefinition> journeys)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RailJourneyCatalog() when $default != null:
return $default(_that.schemaVersion,_that.journeys);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _railJourneyIntFromJson)  int schemaVersion,  List<RailJourneyDefinition> journeys)  $default,) {final _that = this;
switch (_that) {
case _RailJourneyCatalog():
return $default(_that.schemaVersion,_that.journeys);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _railJourneyIntFromJson)  int schemaVersion,  List<RailJourneyDefinition> journeys)?  $default,) {final _that = this;
switch (_that) {
case _RailJourneyCatalog() when $default != null:
return $default(_that.schemaVersion,_that.journeys);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _RailJourneyCatalog extends RailJourneyCatalog {
  const _RailJourneyCatalog({@JsonKey(fromJson: _railJourneyIntFromJson) this.schemaVersion = railJourneySchemaVersion, final  List<RailJourneyDefinition> journeys = const <RailJourneyDefinition>[]}): _journeys = journeys,super._();
  factory _RailJourneyCatalog.fromJson(Map<String, dynamic> json) => _$RailJourneyCatalogFromJson(json);

@override@JsonKey(fromJson: _railJourneyIntFromJson) final  int schemaVersion;
 final  List<RailJourneyDefinition> _journeys;
@override@JsonKey() List<RailJourneyDefinition> get journeys {
  if (_journeys is EqualUnmodifiableListView) return _journeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_journeys);
}


/// Create a copy of RailJourneyCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RailJourneyCatalogCopyWith<_RailJourneyCatalog> get copyWith => __$RailJourneyCatalogCopyWithImpl<_RailJourneyCatalog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RailJourneyCatalogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RailJourneyCatalog&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other._journeys, _journeys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,const DeepCollectionEquality().hash(_journeys));

@override
String toString() {
  return 'RailJourneyCatalog(schemaVersion: $schemaVersion, journeys: $journeys)';
}


}

/// @nodoc
abstract mixin class _$RailJourneyCatalogCopyWith<$Res> implements $RailJourneyCatalogCopyWith<$Res> {
  factory _$RailJourneyCatalogCopyWith(_RailJourneyCatalog value, $Res Function(_RailJourneyCatalog) _then) = __$RailJourneyCatalogCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _railJourneyIntFromJson) int schemaVersion, List<RailJourneyDefinition> journeys
});




}
/// @nodoc
class __$RailJourneyCatalogCopyWithImpl<$Res>
    implements _$RailJourneyCatalogCopyWith<$Res> {
  __$RailJourneyCatalogCopyWithImpl(this._self, this._then);

  final _RailJourneyCatalog _self;
  final $Res Function(_RailJourneyCatalog) _then;

/// Create a copy of RailJourneyCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? journeys = null,}) {
  return _then(_RailJourneyCatalog(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,journeys: null == journeys ? _self._journeys : journeys // ignore: cast_nullable_to_non_nullable
as List<RailJourneyDefinition>,
  ));
}


}


/// @nodoc
mixin _$RailJourneyOperationBinding {

 RailJourneyOperationKind get kind; String get journeyId; RailJourneyDirection get direction; String? get stationMapId; RailJourneyDoorSide? get doorSide;
/// Create a copy of RailJourneyOperationBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RailJourneyOperationBindingCopyWith<RailJourneyOperationBinding> get copyWith => _$RailJourneyOperationBindingCopyWithImpl<RailJourneyOperationBinding>(this as RailJourneyOperationBinding, _$identity);

  /// Serializes this RailJourneyOperationBinding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RailJourneyOperationBinding&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.journeyId, journeyId) || other.journeyId == journeyId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.stationMapId, stationMapId) || other.stationMapId == stationMapId)&&(identical(other.doorSide, doorSide) || other.doorSide == doorSide));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,journeyId,direction,stationMapId,doorSide);

@override
String toString() {
  return 'RailJourneyOperationBinding(kind: $kind, journeyId: $journeyId, direction: $direction, stationMapId: $stationMapId, doorSide: $doorSide)';
}


}

/// @nodoc
abstract mixin class $RailJourneyOperationBindingCopyWith<$Res>  {
  factory $RailJourneyOperationBindingCopyWith(RailJourneyOperationBinding value, $Res Function(RailJourneyOperationBinding) _then) = _$RailJourneyOperationBindingCopyWithImpl;
@useResult
$Res call({
 RailJourneyOperationKind kind, String journeyId, RailJourneyDirection direction, String? stationMapId, RailJourneyDoorSide? doorSide
});




}
/// @nodoc
class _$RailJourneyOperationBindingCopyWithImpl<$Res>
    implements $RailJourneyOperationBindingCopyWith<$Res> {
  _$RailJourneyOperationBindingCopyWithImpl(this._self, this._then);

  final RailJourneyOperationBinding _self;
  final $Res Function(RailJourneyOperationBinding) _then;

/// Create a copy of RailJourneyOperationBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? journeyId = null,Object? direction = null,Object? stationMapId = freezed,Object? doorSide = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RailJourneyOperationKind,journeyId: null == journeyId ? _self.journeyId : journeyId // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as RailJourneyDirection,stationMapId: freezed == stationMapId ? _self.stationMapId : stationMapId // ignore: cast_nullable_to_non_nullable
as String?,doorSide: freezed == doorSide ? _self.doorSide : doorSide // ignore: cast_nullable_to_non_nullable
as RailJourneyDoorSide?,
  ));
}

}


/// Adds pattern-matching-related methods to [RailJourneyOperationBinding].
extension RailJourneyOperationBindingPatterns on RailJourneyOperationBinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RailJourneyOperationBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RailJourneyOperationBinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RailJourneyOperationBinding value)  $default,){
final _that = this;
switch (_that) {
case _RailJourneyOperationBinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RailJourneyOperationBinding value)?  $default,){
final _that = this;
switch (_that) {
case _RailJourneyOperationBinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RailJourneyOperationKind kind,  String journeyId,  RailJourneyDirection direction,  String? stationMapId,  RailJourneyDoorSide? doorSide)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RailJourneyOperationBinding() when $default != null:
return $default(_that.kind,_that.journeyId,_that.direction,_that.stationMapId,_that.doorSide);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RailJourneyOperationKind kind,  String journeyId,  RailJourneyDirection direction,  String? stationMapId,  RailJourneyDoorSide? doorSide)  $default,) {final _that = this;
switch (_that) {
case _RailJourneyOperationBinding():
return $default(_that.kind,_that.journeyId,_that.direction,_that.stationMapId,_that.doorSide);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RailJourneyOperationKind kind,  String journeyId,  RailJourneyDirection direction,  String? stationMapId,  RailJourneyDoorSide? doorSide)?  $default,) {final _that = this;
switch (_that) {
case _RailJourneyOperationBinding() when $default != null:
return $default(_that.kind,_that.journeyId,_that.direction,_that.stationMapId,_that.doorSide);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RailJourneyOperationBinding extends RailJourneyOperationBinding {
  const _RailJourneyOperationBinding({required this.kind, required this.journeyId, required this.direction, this.stationMapId, this.doorSide}): super._();
  factory _RailJourneyOperationBinding.fromJson(Map<String, dynamic> json) => _$RailJourneyOperationBindingFromJson(json);

@override final  RailJourneyOperationKind kind;
@override final  String journeyId;
@override final  RailJourneyDirection direction;
@override final  String? stationMapId;
@override final  RailJourneyDoorSide? doorSide;

/// Create a copy of RailJourneyOperationBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RailJourneyOperationBindingCopyWith<_RailJourneyOperationBinding> get copyWith => __$RailJourneyOperationBindingCopyWithImpl<_RailJourneyOperationBinding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RailJourneyOperationBindingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RailJourneyOperationBinding&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.journeyId, journeyId) || other.journeyId == journeyId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.stationMapId, stationMapId) || other.stationMapId == stationMapId)&&(identical(other.doorSide, doorSide) || other.doorSide == doorSide));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,journeyId,direction,stationMapId,doorSide);

@override
String toString() {
  return 'RailJourneyOperationBinding(kind: $kind, journeyId: $journeyId, direction: $direction, stationMapId: $stationMapId, doorSide: $doorSide)';
}


}

/// @nodoc
abstract mixin class _$RailJourneyOperationBindingCopyWith<$Res> implements $RailJourneyOperationBindingCopyWith<$Res> {
  factory _$RailJourneyOperationBindingCopyWith(_RailJourneyOperationBinding value, $Res Function(_RailJourneyOperationBinding) _then) = __$RailJourneyOperationBindingCopyWithImpl;
@override @useResult
$Res call({
 RailJourneyOperationKind kind, String journeyId, RailJourneyDirection direction, String? stationMapId, RailJourneyDoorSide? doorSide
});




}
/// @nodoc
class __$RailJourneyOperationBindingCopyWithImpl<$Res>
    implements _$RailJourneyOperationBindingCopyWith<$Res> {
  __$RailJourneyOperationBindingCopyWithImpl(this._self, this._then);

  final _RailJourneyOperationBinding _self;
  final $Res Function(_RailJourneyOperationBinding) _then;

/// Create a copy of RailJourneyOperationBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? journeyId = null,Object? direction = null,Object? stationMapId = freezed,Object? doorSide = freezed,}) {
  return _then(_RailJourneyOperationBinding(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RailJourneyOperationKind,journeyId: null == journeyId ? _self.journeyId : journeyId // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as RailJourneyDirection,stationMapId: freezed == stationMapId ? _self.stationMapId : stationMapId // ignore: cast_nullable_to_non_nullable
as String?,doorSide: freezed == doorSide ? _self.doorSide : doorSide // ignore: cast_nullable_to_non_nullable
as RailJourneyDoorSide?,
  ));
}


}


/// @nodoc
mixin _$RailProgressionOperationBinding {

 RailProgressionOperationKind get kind; String get semanticId;@JsonKey(fromJson: _railJourneyIntFromJson) int get amount;
/// Create a copy of RailProgressionOperationBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RailProgressionOperationBindingCopyWith<RailProgressionOperationBinding> get copyWith => _$RailProgressionOperationBindingCopyWithImpl<RailProgressionOperationBinding>(this as RailProgressionOperationBinding, _$identity);

  /// Serializes this RailProgressionOperationBinding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RailProgressionOperationBinding&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.semanticId, semanticId) || other.semanticId == semanticId)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,semanticId,amount);

@override
String toString() {
  return 'RailProgressionOperationBinding(kind: $kind, semanticId: $semanticId, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $RailProgressionOperationBindingCopyWith<$Res>  {
  factory $RailProgressionOperationBindingCopyWith(RailProgressionOperationBinding value, $Res Function(RailProgressionOperationBinding) _then) = _$RailProgressionOperationBindingCopyWithImpl;
@useResult
$Res call({
 RailProgressionOperationKind kind, String semanticId,@JsonKey(fromJson: _railJourneyIntFromJson) int amount
});




}
/// @nodoc
class _$RailProgressionOperationBindingCopyWithImpl<$Res>
    implements $RailProgressionOperationBindingCopyWith<$Res> {
  _$RailProgressionOperationBindingCopyWithImpl(this._self, this._then);

  final RailProgressionOperationBinding _self;
  final $Res Function(RailProgressionOperationBinding) _then;

/// Create a copy of RailProgressionOperationBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? semanticId = null,Object? amount = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RailProgressionOperationKind,semanticId: null == semanticId ? _self.semanticId : semanticId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RailProgressionOperationBinding].
extension RailProgressionOperationBindingPatterns on RailProgressionOperationBinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RailProgressionOperationBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RailProgressionOperationBinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RailProgressionOperationBinding value)  $default,){
final _that = this;
switch (_that) {
case _RailProgressionOperationBinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RailProgressionOperationBinding value)?  $default,){
final _that = this;
switch (_that) {
case _RailProgressionOperationBinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RailProgressionOperationKind kind,  String semanticId, @JsonKey(fromJson: _railJourneyIntFromJson)  int amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RailProgressionOperationBinding() when $default != null:
return $default(_that.kind,_that.semanticId,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RailProgressionOperationKind kind,  String semanticId, @JsonKey(fromJson: _railJourneyIntFromJson)  int amount)  $default,) {final _that = this;
switch (_that) {
case _RailProgressionOperationBinding():
return $default(_that.kind,_that.semanticId,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RailProgressionOperationKind kind,  String semanticId, @JsonKey(fromJson: _railJourneyIntFromJson)  int amount)?  $default,) {final _that = this;
switch (_that) {
case _RailProgressionOperationBinding() when $default != null:
return $default(_that.kind,_that.semanticId,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RailProgressionOperationBinding extends RailProgressionOperationBinding {
  const _RailProgressionOperationBinding({required this.kind, required this.semanticId, @JsonKey(fromJson: _railJourneyIntFromJson) this.amount = 0}): super._();
  factory _RailProgressionOperationBinding.fromJson(Map<String, dynamic> json) => _$RailProgressionOperationBindingFromJson(json);

@override final  RailProgressionOperationKind kind;
@override final  String semanticId;
@override@JsonKey(fromJson: _railJourneyIntFromJson) final  int amount;

/// Create a copy of RailProgressionOperationBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RailProgressionOperationBindingCopyWith<_RailProgressionOperationBinding> get copyWith => __$RailProgressionOperationBindingCopyWithImpl<_RailProgressionOperationBinding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RailProgressionOperationBindingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RailProgressionOperationBinding&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.semanticId, semanticId) || other.semanticId == semanticId)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,semanticId,amount);

@override
String toString() {
  return 'RailProgressionOperationBinding(kind: $kind, semanticId: $semanticId, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$RailProgressionOperationBindingCopyWith<$Res> implements $RailProgressionOperationBindingCopyWith<$Res> {
  factory _$RailProgressionOperationBindingCopyWith(_RailProgressionOperationBinding value, $Res Function(_RailProgressionOperationBinding) _then) = __$RailProgressionOperationBindingCopyWithImpl;
@override @useResult
$Res call({
 RailProgressionOperationKind kind, String semanticId,@JsonKey(fromJson: _railJourneyIntFromJson) int amount
});




}
/// @nodoc
class __$RailProgressionOperationBindingCopyWithImpl<$Res>
    implements _$RailProgressionOperationBindingCopyWith<$Res> {
  __$RailProgressionOperationBindingCopyWithImpl(this._self, this._then);

  final _RailProgressionOperationBinding _self;
  final $Res Function(_RailProgressionOperationBinding) _then;

/// Create a copy of RailProgressionOperationBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? semanticId = null,Object? amount = null,}) {
  return _then(_RailProgressionOperationBinding(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RailProgressionOperationKind,semanticId: null == semanticId ? _self.semanticId : semanticId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RailJourneyProgress {

 String? get activeJourneyId; RailJourneyDirection? get direction; RailJourneyLifecycle get lifecycle; Set<String> get unlockedJourneyIds; Set<String> get firstUnlockPaidJourneyIds; Set<String> get unlockedStationMapIds; Set<String> get earnedStampIds;@JsonKey(fromJson: _currencyBalancesFromJson, toJson: _currencyBalancesToJson) Map<String, int> get semanticCurrencyBalances; Map<String, RailJourneyOperationBinding> get appliedOperations; Map<String, RailProgressionOperationBinding> get appliedProgressionOperations;
/// Create a copy of RailJourneyProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RailJourneyProgressCopyWith<RailJourneyProgress> get copyWith => _$RailJourneyProgressCopyWithImpl<RailJourneyProgress>(this as RailJourneyProgress, _$identity);

  /// Serializes this RailJourneyProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RailJourneyProgress&&(identical(other.activeJourneyId, activeJourneyId) || other.activeJourneyId == activeJourneyId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&const DeepCollectionEquality().equals(other.unlockedJourneyIds, unlockedJourneyIds)&&const DeepCollectionEquality().equals(other.firstUnlockPaidJourneyIds, firstUnlockPaidJourneyIds)&&const DeepCollectionEquality().equals(other.unlockedStationMapIds, unlockedStationMapIds)&&const DeepCollectionEquality().equals(other.earnedStampIds, earnedStampIds)&&const DeepCollectionEquality().equals(other.semanticCurrencyBalances, semanticCurrencyBalances)&&const DeepCollectionEquality().equals(other.appliedOperations, appliedOperations)&&const DeepCollectionEquality().equals(other.appliedProgressionOperations, appliedProgressionOperations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeJourneyId,direction,lifecycle,const DeepCollectionEquality().hash(unlockedJourneyIds),const DeepCollectionEquality().hash(firstUnlockPaidJourneyIds),const DeepCollectionEquality().hash(unlockedStationMapIds),const DeepCollectionEquality().hash(earnedStampIds),const DeepCollectionEquality().hash(semanticCurrencyBalances),const DeepCollectionEquality().hash(appliedOperations),const DeepCollectionEquality().hash(appliedProgressionOperations));

@override
String toString() {
  return 'RailJourneyProgress(activeJourneyId: $activeJourneyId, direction: $direction, lifecycle: $lifecycle, unlockedJourneyIds: $unlockedJourneyIds, firstUnlockPaidJourneyIds: $firstUnlockPaidJourneyIds, unlockedStationMapIds: $unlockedStationMapIds, earnedStampIds: $earnedStampIds, semanticCurrencyBalances: $semanticCurrencyBalances, appliedOperations: $appliedOperations, appliedProgressionOperations: $appliedProgressionOperations)';
}


}

/// @nodoc
abstract mixin class $RailJourneyProgressCopyWith<$Res>  {
  factory $RailJourneyProgressCopyWith(RailJourneyProgress value, $Res Function(RailJourneyProgress) _then) = _$RailJourneyProgressCopyWithImpl;
@useResult
$Res call({
 String? activeJourneyId, RailJourneyDirection? direction, RailJourneyLifecycle lifecycle, Set<String> unlockedJourneyIds, Set<String> firstUnlockPaidJourneyIds, Set<String> unlockedStationMapIds, Set<String> earnedStampIds,@JsonKey(fromJson: _currencyBalancesFromJson, toJson: _currencyBalancesToJson) Map<String, int> semanticCurrencyBalances, Map<String, RailJourneyOperationBinding> appliedOperations, Map<String, RailProgressionOperationBinding> appliedProgressionOperations
});




}
/// @nodoc
class _$RailJourneyProgressCopyWithImpl<$Res>
    implements $RailJourneyProgressCopyWith<$Res> {
  _$RailJourneyProgressCopyWithImpl(this._self, this._then);

  final RailJourneyProgress _self;
  final $Res Function(RailJourneyProgress) _then;

/// Create a copy of RailJourneyProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeJourneyId = freezed,Object? direction = freezed,Object? lifecycle = null,Object? unlockedJourneyIds = null,Object? firstUnlockPaidJourneyIds = null,Object? unlockedStationMapIds = null,Object? earnedStampIds = null,Object? semanticCurrencyBalances = null,Object? appliedOperations = null,Object? appliedProgressionOperations = null,}) {
  return _then(_self.copyWith(
activeJourneyId: freezed == activeJourneyId ? _self.activeJourneyId : activeJourneyId // ignore: cast_nullable_to_non_nullable
as String?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as RailJourneyDirection?,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as RailJourneyLifecycle,unlockedJourneyIds: null == unlockedJourneyIds ? _self.unlockedJourneyIds : unlockedJourneyIds // ignore: cast_nullable_to_non_nullable
as Set<String>,firstUnlockPaidJourneyIds: null == firstUnlockPaidJourneyIds ? _self.firstUnlockPaidJourneyIds : firstUnlockPaidJourneyIds // ignore: cast_nullable_to_non_nullable
as Set<String>,unlockedStationMapIds: null == unlockedStationMapIds ? _self.unlockedStationMapIds : unlockedStationMapIds // ignore: cast_nullable_to_non_nullable
as Set<String>,earnedStampIds: null == earnedStampIds ? _self.earnedStampIds : earnedStampIds // ignore: cast_nullable_to_non_nullable
as Set<String>,semanticCurrencyBalances: null == semanticCurrencyBalances ? _self.semanticCurrencyBalances : semanticCurrencyBalances // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appliedOperations: null == appliedOperations ? _self.appliedOperations : appliedOperations // ignore: cast_nullable_to_non_nullable
as Map<String, RailJourneyOperationBinding>,appliedProgressionOperations: null == appliedProgressionOperations ? _self.appliedProgressionOperations : appliedProgressionOperations // ignore: cast_nullable_to_non_nullable
as Map<String, RailProgressionOperationBinding>,
  ));
}

}


/// Adds pattern-matching-related methods to [RailJourneyProgress].
extension RailJourneyProgressPatterns on RailJourneyProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RailJourneyProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RailJourneyProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RailJourneyProgress value)  $default,){
final _that = this;
switch (_that) {
case _RailJourneyProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RailJourneyProgress value)?  $default,){
final _that = this;
switch (_that) {
case _RailJourneyProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? activeJourneyId,  RailJourneyDirection? direction,  RailJourneyLifecycle lifecycle,  Set<String> unlockedJourneyIds,  Set<String> firstUnlockPaidJourneyIds,  Set<String> unlockedStationMapIds,  Set<String> earnedStampIds, @JsonKey(fromJson: _currencyBalancesFromJson, toJson: _currencyBalancesToJson)  Map<String, int> semanticCurrencyBalances,  Map<String, RailJourneyOperationBinding> appliedOperations,  Map<String, RailProgressionOperationBinding> appliedProgressionOperations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RailJourneyProgress() when $default != null:
return $default(_that.activeJourneyId,_that.direction,_that.lifecycle,_that.unlockedJourneyIds,_that.firstUnlockPaidJourneyIds,_that.unlockedStationMapIds,_that.earnedStampIds,_that.semanticCurrencyBalances,_that.appliedOperations,_that.appliedProgressionOperations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? activeJourneyId,  RailJourneyDirection? direction,  RailJourneyLifecycle lifecycle,  Set<String> unlockedJourneyIds,  Set<String> firstUnlockPaidJourneyIds,  Set<String> unlockedStationMapIds,  Set<String> earnedStampIds, @JsonKey(fromJson: _currencyBalancesFromJson, toJson: _currencyBalancesToJson)  Map<String, int> semanticCurrencyBalances,  Map<String, RailJourneyOperationBinding> appliedOperations,  Map<String, RailProgressionOperationBinding> appliedProgressionOperations)  $default,) {final _that = this;
switch (_that) {
case _RailJourneyProgress():
return $default(_that.activeJourneyId,_that.direction,_that.lifecycle,_that.unlockedJourneyIds,_that.firstUnlockPaidJourneyIds,_that.unlockedStationMapIds,_that.earnedStampIds,_that.semanticCurrencyBalances,_that.appliedOperations,_that.appliedProgressionOperations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? activeJourneyId,  RailJourneyDirection? direction,  RailJourneyLifecycle lifecycle,  Set<String> unlockedJourneyIds,  Set<String> firstUnlockPaidJourneyIds,  Set<String> unlockedStationMapIds,  Set<String> earnedStampIds, @JsonKey(fromJson: _currencyBalancesFromJson, toJson: _currencyBalancesToJson)  Map<String, int> semanticCurrencyBalances,  Map<String, RailJourneyOperationBinding> appliedOperations,  Map<String, RailProgressionOperationBinding> appliedProgressionOperations)?  $default,) {final _that = this;
switch (_that) {
case _RailJourneyProgress() when $default != null:
return $default(_that.activeJourneyId,_that.direction,_that.lifecycle,_that.unlockedJourneyIds,_that.firstUnlockPaidJourneyIds,_that.unlockedStationMapIds,_that.earnedStampIds,_that.semanticCurrencyBalances,_that.appliedOperations,_that.appliedProgressionOperations);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _RailJourneyProgress extends RailJourneyProgress {
  const _RailJourneyProgress({this.activeJourneyId, this.direction, this.lifecycle = RailJourneyLifecycle.idleAtOrigin, final  Set<String> unlockedJourneyIds = const <String>{}, final  Set<String> firstUnlockPaidJourneyIds = const <String>{}, final  Set<String> unlockedStationMapIds = const <String>{}, final  Set<String> earnedStampIds = const <String>{}, @JsonKey(fromJson: _currencyBalancesFromJson, toJson: _currencyBalancesToJson) final  Map<String, int> semanticCurrencyBalances = const <String, int>{}, final  Map<String, RailJourneyOperationBinding> appliedOperations = const <String, RailJourneyOperationBinding>{}, final  Map<String, RailProgressionOperationBinding> appliedProgressionOperations = const <String, RailProgressionOperationBinding>{}}): _unlockedJourneyIds = unlockedJourneyIds,_firstUnlockPaidJourneyIds = firstUnlockPaidJourneyIds,_unlockedStationMapIds = unlockedStationMapIds,_earnedStampIds = earnedStampIds,_semanticCurrencyBalances = semanticCurrencyBalances,_appliedOperations = appliedOperations,_appliedProgressionOperations = appliedProgressionOperations,super._();
  factory _RailJourneyProgress.fromJson(Map<String, dynamic> json) => _$RailJourneyProgressFromJson(json);

@override final  String? activeJourneyId;
@override final  RailJourneyDirection? direction;
@override@JsonKey() final  RailJourneyLifecycle lifecycle;
 final  Set<String> _unlockedJourneyIds;
@override@JsonKey() Set<String> get unlockedJourneyIds {
  if (_unlockedJourneyIds is EqualUnmodifiableSetView) return _unlockedJourneyIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_unlockedJourneyIds);
}

 final  Set<String> _firstUnlockPaidJourneyIds;
@override@JsonKey() Set<String> get firstUnlockPaidJourneyIds {
  if (_firstUnlockPaidJourneyIds is EqualUnmodifiableSetView) return _firstUnlockPaidJourneyIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_firstUnlockPaidJourneyIds);
}

 final  Set<String> _unlockedStationMapIds;
@override@JsonKey() Set<String> get unlockedStationMapIds {
  if (_unlockedStationMapIds is EqualUnmodifiableSetView) return _unlockedStationMapIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_unlockedStationMapIds);
}

 final  Set<String> _earnedStampIds;
@override@JsonKey() Set<String> get earnedStampIds {
  if (_earnedStampIds is EqualUnmodifiableSetView) return _earnedStampIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_earnedStampIds);
}

 final  Map<String, int> _semanticCurrencyBalances;
@override@JsonKey(fromJson: _currencyBalancesFromJson, toJson: _currencyBalancesToJson) Map<String, int> get semanticCurrencyBalances {
  if (_semanticCurrencyBalances is EqualUnmodifiableMapView) return _semanticCurrencyBalances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_semanticCurrencyBalances);
}

 final  Map<String, RailJourneyOperationBinding> _appliedOperations;
@override@JsonKey() Map<String, RailJourneyOperationBinding> get appliedOperations {
  if (_appliedOperations is EqualUnmodifiableMapView) return _appliedOperations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_appliedOperations);
}

 final  Map<String, RailProgressionOperationBinding> _appliedProgressionOperations;
@override@JsonKey() Map<String, RailProgressionOperationBinding> get appliedProgressionOperations {
  if (_appliedProgressionOperations is EqualUnmodifiableMapView) return _appliedProgressionOperations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_appliedProgressionOperations);
}


/// Create a copy of RailJourneyProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RailJourneyProgressCopyWith<_RailJourneyProgress> get copyWith => __$RailJourneyProgressCopyWithImpl<_RailJourneyProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RailJourneyProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RailJourneyProgress&&(identical(other.activeJourneyId, activeJourneyId) || other.activeJourneyId == activeJourneyId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&const DeepCollectionEquality().equals(other._unlockedJourneyIds, _unlockedJourneyIds)&&const DeepCollectionEquality().equals(other._firstUnlockPaidJourneyIds, _firstUnlockPaidJourneyIds)&&const DeepCollectionEquality().equals(other._unlockedStationMapIds, _unlockedStationMapIds)&&const DeepCollectionEquality().equals(other._earnedStampIds, _earnedStampIds)&&const DeepCollectionEquality().equals(other._semanticCurrencyBalances, _semanticCurrencyBalances)&&const DeepCollectionEquality().equals(other._appliedOperations, _appliedOperations)&&const DeepCollectionEquality().equals(other._appliedProgressionOperations, _appliedProgressionOperations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeJourneyId,direction,lifecycle,const DeepCollectionEquality().hash(_unlockedJourneyIds),const DeepCollectionEquality().hash(_firstUnlockPaidJourneyIds),const DeepCollectionEquality().hash(_unlockedStationMapIds),const DeepCollectionEquality().hash(_earnedStampIds),const DeepCollectionEquality().hash(_semanticCurrencyBalances),const DeepCollectionEquality().hash(_appliedOperations),const DeepCollectionEquality().hash(_appliedProgressionOperations));

@override
String toString() {
  return 'RailJourneyProgress(activeJourneyId: $activeJourneyId, direction: $direction, lifecycle: $lifecycle, unlockedJourneyIds: $unlockedJourneyIds, firstUnlockPaidJourneyIds: $firstUnlockPaidJourneyIds, unlockedStationMapIds: $unlockedStationMapIds, earnedStampIds: $earnedStampIds, semanticCurrencyBalances: $semanticCurrencyBalances, appliedOperations: $appliedOperations, appliedProgressionOperations: $appliedProgressionOperations)';
}


}

/// @nodoc
abstract mixin class _$RailJourneyProgressCopyWith<$Res> implements $RailJourneyProgressCopyWith<$Res> {
  factory _$RailJourneyProgressCopyWith(_RailJourneyProgress value, $Res Function(_RailJourneyProgress) _then) = __$RailJourneyProgressCopyWithImpl;
@override @useResult
$Res call({
 String? activeJourneyId, RailJourneyDirection? direction, RailJourneyLifecycle lifecycle, Set<String> unlockedJourneyIds, Set<String> firstUnlockPaidJourneyIds, Set<String> unlockedStationMapIds, Set<String> earnedStampIds,@JsonKey(fromJson: _currencyBalancesFromJson, toJson: _currencyBalancesToJson) Map<String, int> semanticCurrencyBalances, Map<String, RailJourneyOperationBinding> appliedOperations, Map<String, RailProgressionOperationBinding> appliedProgressionOperations
});




}
/// @nodoc
class __$RailJourneyProgressCopyWithImpl<$Res>
    implements _$RailJourneyProgressCopyWith<$Res> {
  __$RailJourneyProgressCopyWithImpl(this._self, this._then);

  final _RailJourneyProgress _self;
  final $Res Function(_RailJourneyProgress) _then;

/// Create a copy of RailJourneyProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeJourneyId = freezed,Object? direction = freezed,Object? lifecycle = null,Object? unlockedJourneyIds = null,Object? firstUnlockPaidJourneyIds = null,Object? unlockedStationMapIds = null,Object? earnedStampIds = null,Object? semanticCurrencyBalances = null,Object? appliedOperations = null,Object? appliedProgressionOperations = null,}) {
  return _then(_RailJourneyProgress(
activeJourneyId: freezed == activeJourneyId ? _self.activeJourneyId : activeJourneyId // ignore: cast_nullable_to_non_nullable
as String?,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as RailJourneyDirection?,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as RailJourneyLifecycle,unlockedJourneyIds: null == unlockedJourneyIds ? _self._unlockedJourneyIds : unlockedJourneyIds // ignore: cast_nullable_to_non_nullable
as Set<String>,firstUnlockPaidJourneyIds: null == firstUnlockPaidJourneyIds ? _self._firstUnlockPaidJourneyIds : firstUnlockPaidJourneyIds // ignore: cast_nullable_to_non_nullable
as Set<String>,unlockedStationMapIds: null == unlockedStationMapIds ? _self._unlockedStationMapIds : unlockedStationMapIds // ignore: cast_nullable_to_non_nullable
as Set<String>,earnedStampIds: null == earnedStampIds ? _self._earnedStampIds : earnedStampIds // ignore: cast_nullable_to_non_nullable
as Set<String>,semanticCurrencyBalances: null == semanticCurrencyBalances ? _self._semanticCurrencyBalances : semanticCurrencyBalances // ignore: cast_nullable_to_non_nullable
as Map<String, int>,appliedOperations: null == appliedOperations ? _self._appliedOperations : appliedOperations // ignore: cast_nullable_to_non_nullable
as Map<String, RailJourneyOperationBinding>,appliedProgressionOperations: null == appliedProgressionOperations ? _self._appliedProgressionOperations : appliedProgressionOperations // ignore: cast_nullable_to_non_nullable
as Map<String, RailProgressionOperationBinding>,
  ));
}


}

// dart format on
