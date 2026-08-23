// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'smart_tile_encounter_behavior.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SmartTileEncounterBehavior {

 String get materialId; int get priority; EncounterZonePayload get encounter;
/// Create a copy of SmartTileEncounterBehavior
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileEncounterBehaviorCopyWith<SmartTileEncounterBehavior> get copyWith => _$SmartTileEncounterBehaviorCopyWithImpl<SmartTileEncounterBehavior>(this as SmartTileEncounterBehavior, _$identity);

  /// Serializes this SmartTileEncounterBehavior to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileEncounterBehavior&&(identical(other.materialId, materialId) || other.materialId == materialId)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.encounter, encounter) || other.encounter == encounter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,materialId,priority,encounter);

@override
String toString() {
  return 'SmartTileEncounterBehavior(materialId: $materialId, priority: $priority, encounter: $encounter)';
}


}

/// @nodoc
abstract mixin class $SmartTileEncounterBehaviorCopyWith<$Res>  {
  factory $SmartTileEncounterBehaviorCopyWith(SmartTileEncounterBehavior value, $Res Function(SmartTileEncounterBehavior) _then) = _$SmartTileEncounterBehaviorCopyWithImpl;
@useResult
$Res call({
 String materialId, int priority, EncounterZonePayload encounter
});


$EncounterZonePayloadCopyWith<$Res> get encounter;

}
/// @nodoc
class _$SmartTileEncounterBehaviorCopyWithImpl<$Res>
    implements $SmartTileEncounterBehaviorCopyWith<$Res> {
  _$SmartTileEncounterBehaviorCopyWithImpl(this._self, this._then);

  final SmartTileEncounterBehavior _self;
  final $Res Function(SmartTileEncounterBehavior) _then;

/// Create a copy of SmartTileEncounterBehavior
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? materialId = null,Object? priority = null,Object? encounter = null,}) {
  return _then(_self.copyWith(
materialId: null == materialId ? _self.materialId : materialId // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,encounter: null == encounter ? _self.encounter : encounter // ignore: cast_nullable_to_non_nullable
as EncounterZonePayload,
  ));
}
/// Create a copy of SmartTileEncounterBehavior
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EncounterZonePayloadCopyWith<$Res> get encounter {

  return $EncounterZonePayloadCopyWith<$Res>(_self.encounter, (value) {
    return _then(_self.copyWith(encounter: value));
  });
}
}


/// Adds pattern-matching-related methods to [SmartTileEncounterBehavior].
extension SmartTileEncounterBehaviorPatterns on SmartTileEncounterBehavior {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartTileEncounterBehavior value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartTileEncounterBehavior() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartTileEncounterBehavior value)  $default,){
final _that = this;
switch (_that) {
case _SmartTileEncounterBehavior():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartTileEncounterBehavior value)?  $default,){
final _that = this;
switch (_that) {
case _SmartTileEncounterBehavior() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String materialId,  int priority,  EncounterZonePayload encounter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartTileEncounterBehavior() when $default != null:
return $default(_that.materialId,_that.priority,_that.encounter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String materialId,  int priority,  EncounterZonePayload encounter)  $default,) {final _that = this;
switch (_that) {
case _SmartTileEncounterBehavior():
return $default(_that.materialId,_that.priority,_that.encounter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String materialId,  int priority,  EncounterZonePayload encounter)?  $default,) {final _that = this;
switch (_that) {
case _SmartTileEncounterBehavior() when $default != null:
return $default(_that.materialId,_that.priority,_that.encounter);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SmartTileEncounterBehavior implements SmartTileEncounterBehavior {
  const _SmartTileEncounterBehavior({required this.materialId, this.priority = 0, required this.encounter});
  factory _SmartTileEncounterBehavior.fromJson(Map<String, dynamic> json) => _$SmartTileEncounterBehaviorFromJson(json);

@override final  String materialId;
@override@JsonKey() final  int priority;
@override final  EncounterZonePayload encounter;

/// Create a copy of SmartTileEncounterBehavior
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartTileEncounterBehaviorCopyWith<_SmartTileEncounterBehavior> get copyWith => __$SmartTileEncounterBehaviorCopyWithImpl<_SmartTileEncounterBehavior>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileEncounterBehaviorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartTileEncounterBehavior&&(identical(other.materialId, materialId) || other.materialId == materialId)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.encounter, encounter) || other.encounter == encounter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,materialId,priority,encounter);

@override
String toString() {
  return 'SmartTileEncounterBehavior(materialId: $materialId, priority: $priority, encounter: $encounter)';
}


}

/// @nodoc
abstract mixin class _$SmartTileEncounterBehaviorCopyWith<$Res> implements $SmartTileEncounterBehaviorCopyWith<$Res> {
  factory _$SmartTileEncounterBehaviorCopyWith(_SmartTileEncounterBehavior value, $Res Function(_SmartTileEncounterBehavior) _then) = __$SmartTileEncounterBehaviorCopyWithImpl;
@override @useResult
$Res call({
 String materialId, int priority, EncounterZonePayload encounter
});


@override $EncounterZonePayloadCopyWith<$Res> get encounter;

}
/// @nodoc
class __$SmartTileEncounterBehaviorCopyWithImpl<$Res>
    implements _$SmartTileEncounterBehaviorCopyWith<$Res> {
  __$SmartTileEncounterBehaviorCopyWithImpl(this._self, this._then);

  final _SmartTileEncounterBehavior _self;
  final $Res Function(_SmartTileEncounterBehavior) _then;

/// Create a copy of SmartTileEncounterBehavior
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? materialId = null,Object? priority = null,Object? encounter = null,}) {
  return _then(_SmartTileEncounterBehavior(
materialId: null == materialId ? _self.materialId : materialId // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,encounter: null == encounter ? _self.encounter : encounter // ignore: cast_nullable_to_non_nullable
as EncounterZonePayload,
  ));
}

/// Create a copy of SmartTileEncounterBehavior
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EncounterZonePayloadCopyWith<$Res> get encounter {

  return $EncounterZonePayloadCopyWith<$Res>(_self.encounter, (value) {
    return _then(_self.copyWith(encounter: value));
  });
}
}

// dart format on
