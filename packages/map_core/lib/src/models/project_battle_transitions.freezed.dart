// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_battle_transitions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectBattleTransitionConfig {

@JsonKey(includeIfNull: false) String? get wildTransitionId;@JsonKey(includeIfNull: false) String? get trainerTransitionId; List<BattleTransitionDefinition> get definitions;
/// Create a copy of ProjectBattleTransitionConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectBattleTransitionConfigCopyWith<ProjectBattleTransitionConfig> get copyWith => _$ProjectBattleTransitionConfigCopyWithImpl<ProjectBattleTransitionConfig>(this as ProjectBattleTransitionConfig, _$identity);

  /// Serializes this ProjectBattleTransitionConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectBattleTransitionConfig&&(identical(other.wildTransitionId, wildTransitionId) || other.wildTransitionId == wildTransitionId)&&(identical(other.trainerTransitionId, trainerTransitionId) || other.trainerTransitionId == trainerTransitionId)&&const DeepCollectionEquality().equals(other.definitions, definitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wildTransitionId,trainerTransitionId,const DeepCollectionEquality().hash(definitions));

@override
String toString() {
  return 'ProjectBattleTransitionConfig(wildTransitionId: $wildTransitionId, trainerTransitionId: $trainerTransitionId, definitions: $definitions)';
}


}

/// @nodoc
abstract mixin class $ProjectBattleTransitionConfigCopyWith<$Res>  {
  factory $ProjectBattleTransitionConfigCopyWith(ProjectBattleTransitionConfig value, $Res Function(ProjectBattleTransitionConfig) _then) = _$ProjectBattleTransitionConfigCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? wildTransitionId,@JsonKey(includeIfNull: false) String? trainerTransitionId, List<BattleTransitionDefinition> definitions
});




}
/// @nodoc
class _$ProjectBattleTransitionConfigCopyWithImpl<$Res>
    implements $ProjectBattleTransitionConfigCopyWith<$Res> {
  _$ProjectBattleTransitionConfigCopyWithImpl(this._self, this._then);

  final ProjectBattleTransitionConfig _self;
  final $Res Function(ProjectBattleTransitionConfig) _then;

/// Create a copy of ProjectBattleTransitionConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wildTransitionId = freezed,Object? trainerTransitionId = freezed,Object? definitions = null,}) {
  return _then(_self.copyWith(
wildTransitionId: freezed == wildTransitionId ? _self.wildTransitionId : wildTransitionId // ignore: cast_nullable_to_non_nullable
as String?,trainerTransitionId: freezed == trainerTransitionId ? _self.trainerTransitionId : trainerTransitionId // ignore: cast_nullable_to_non_nullable
as String?,definitions: null == definitions ? _self.definitions : definitions // ignore: cast_nullable_to_non_nullable
as List<BattleTransitionDefinition>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectBattleTransitionConfig].
extension ProjectBattleTransitionConfigPatterns on ProjectBattleTransitionConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectBattleTransitionConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectBattleTransitionConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectBattleTransitionConfig value)  $default,){
final _that = this;
switch (_that) {
case _ProjectBattleTransitionConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectBattleTransitionConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectBattleTransitionConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? wildTransitionId, @JsonKey(includeIfNull: false)  String? trainerTransitionId,  List<BattleTransitionDefinition> definitions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectBattleTransitionConfig() when $default != null:
return $default(_that.wildTransitionId,_that.trainerTransitionId,_that.definitions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? wildTransitionId, @JsonKey(includeIfNull: false)  String? trainerTransitionId,  List<BattleTransitionDefinition> definitions)  $default,) {final _that = this;
switch (_that) {
case _ProjectBattleTransitionConfig():
return $default(_that.wildTransitionId,_that.trainerTransitionId,_that.definitions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? wildTransitionId, @JsonKey(includeIfNull: false)  String? trainerTransitionId,  List<BattleTransitionDefinition> definitions)?  $default,) {final _that = this;
switch (_that) {
case _ProjectBattleTransitionConfig() when $default != null:
return $default(_that.wildTransitionId,_that.trainerTransitionId,_that.definitions);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectBattleTransitionConfig extends ProjectBattleTransitionConfig {
  const _ProjectBattleTransitionConfig({@JsonKey(includeIfNull: false) this.wildTransitionId, @JsonKey(includeIfNull: false) this.trainerTransitionId, final  List<BattleTransitionDefinition> definitions = const <BattleTransitionDefinition>[]}): _definitions = definitions,super._();
  factory _ProjectBattleTransitionConfig.fromJson(Map<String, dynamic> json) => _$ProjectBattleTransitionConfigFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? wildTransitionId;
@override@JsonKey(includeIfNull: false) final  String? trainerTransitionId;
 final  List<BattleTransitionDefinition> _definitions;
@override@JsonKey() List<BattleTransitionDefinition> get definitions {
  if (_definitions is EqualUnmodifiableListView) return _definitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_definitions);
}


/// Create a copy of ProjectBattleTransitionConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectBattleTransitionConfigCopyWith<_ProjectBattleTransitionConfig> get copyWith => __$ProjectBattleTransitionConfigCopyWithImpl<_ProjectBattleTransitionConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectBattleTransitionConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectBattleTransitionConfig&&(identical(other.wildTransitionId, wildTransitionId) || other.wildTransitionId == wildTransitionId)&&(identical(other.trainerTransitionId, trainerTransitionId) || other.trainerTransitionId == trainerTransitionId)&&const DeepCollectionEquality().equals(other._definitions, _definitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wildTransitionId,trainerTransitionId,const DeepCollectionEquality().hash(_definitions));

@override
String toString() {
  return 'ProjectBattleTransitionConfig(wildTransitionId: $wildTransitionId, trainerTransitionId: $trainerTransitionId, definitions: $definitions)';
}


}

/// @nodoc
abstract mixin class _$ProjectBattleTransitionConfigCopyWith<$Res> implements $ProjectBattleTransitionConfigCopyWith<$Res> {
  factory _$ProjectBattleTransitionConfigCopyWith(_ProjectBattleTransitionConfig value, $Res Function(_ProjectBattleTransitionConfig) _then) = __$ProjectBattleTransitionConfigCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? wildTransitionId,@JsonKey(includeIfNull: false) String? trainerTransitionId, List<BattleTransitionDefinition> definitions
});




}
/// @nodoc
class __$ProjectBattleTransitionConfigCopyWithImpl<$Res>
    implements _$ProjectBattleTransitionConfigCopyWith<$Res> {
  __$ProjectBattleTransitionConfigCopyWithImpl(this._self, this._then);

  final _ProjectBattleTransitionConfig _self;
  final $Res Function(_ProjectBattleTransitionConfig) _then;

/// Create a copy of ProjectBattleTransitionConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wildTransitionId = freezed,Object? trainerTransitionId = freezed,Object? definitions = null,}) {
  return _then(_ProjectBattleTransitionConfig(
wildTransitionId: freezed == wildTransitionId ? _self.wildTransitionId : wildTransitionId // ignore: cast_nullable_to_non_nullable
as String?,trainerTransitionId: freezed == trainerTransitionId ? _self.trainerTransitionId : trainerTransitionId // ignore: cast_nullable_to_non_nullable
as String?,definitions: null == definitions ? _self._definitions : definitions // ignore: cast_nullable_to_non_nullable
as List<BattleTransitionDefinition>,
  ));
}


}

// dart format on
