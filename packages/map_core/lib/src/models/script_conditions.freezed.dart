// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'script_conditions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScriptCondition {

 ScriptConditionType get type;/// Paramètres de la condition (dépend du type).
 Map<String, String> get params;/// Sous-conditions pour allOf/anyOf/not.
 List<ScriptCondition> get children;
/// Create a copy of ScriptCondition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScriptConditionCopyWith<ScriptCondition> get copyWith => _$ScriptConditionCopyWithImpl<ScriptCondition>(this as ScriptCondition, _$identity);

  /// Serializes this ScriptCondition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptCondition&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.params, params)&&const DeepCollectionEquality().equals(other.children, children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(params),const DeepCollectionEquality().hash(children));

@override
String toString() {
  return 'ScriptCondition(type: $type, params: $params, children: $children)';
}


}

/// @nodoc
abstract mixin class $ScriptConditionCopyWith<$Res>  {
  factory $ScriptConditionCopyWith(ScriptCondition value, $Res Function(ScriptCondition) _then) = _$ScriptConditionCopyWithImpl;
@useResult
$Res call({
 ScriptConditionType type, Map<String, String> params, List<ScriptCondition> children
});




}
/// @nodoc
class _$ScriptConditionCopyWithImpl<$Res>
    implements $ScriptConditionCopyWith<$Res> {
  _$ScriptConditionCopyWithImpl(this._self, this._then);

  final ScriptCondition _self;
  final $Res Function(ScriptCondition) _then;

/// Create a copy of ScriptCondition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? params = null,Object? children = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ScriptConditionType,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<ScriptCondition>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScriptCondition].
extension ScriptConditionPatterns on ScriptCondition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScriptCondition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScriptCondition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScriptCondition value)  $default,){
final _that = this;
switch (_that) {
case _ScriptCondition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScriptCondition value)?  $default,){
final _that = this;
switch (_that) {
case _ScriptCondition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScriptConditionType type,  Map<String, String> params,  List<ScriptCondition> children)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScriptCondition() when $default != null:
return $default(_that.type,_that.params,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScriptConditionType type,  Map<String, String> params,  List<ScriptCondition> children)  $default,) {final _that = this;
switch (_that) {
case _ScriptCondition():
return $default(_that.type,_that.params,_that.children);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScriptConditionType type,  Map<String, String> params,  List<ScriptCondition> children)?  $default,) {final _that = this;
switch (_that) {
case _ScriptCondition() when $default != null:
return $default(_that.type,_that.params,_that.children);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ScriptCondition implements ScriptCondition {
  const _ScriptCondition({required this.type, final  Map<String, String> params = const {}, final  List<ScriptCondition> children = const []}): _params = params,_children = children;
  factory _ScriptCondition.fromJson(Map<String, dynamic> json) => _$ScriptConditionFromJson(json);

@override final  ScriptConditionType type;
/// Paramètres de la condition (dépend du type).
 final  Map<String, String> _params;
/// Paramètres de la condition (dépend du type).
@override@JsonKey() Map<String, String> get params {
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_params);
}

/// Sous-conditions pour allOf/anyOf/not.
 final  List<ScriptCondition> _children;
/// Sous-conditions pour allOf/anyOf/not.
@override@JsonKey() List<ScriptCondition> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of ScriptCondition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScriptConditionCopyWith<_ScriptCondition> get copyWith => __$ScriptConditionCopyWithImpl<_ScriptCondition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScriptConditionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScriptCondition&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._params, _params)&&const DeepCollectionEquality().equals(other._children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_params),const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'ScriptCondition(type: $type, params: $params, children: $children)';
}


}

/// @nodoc
abstract mixin class _$ScriptConditionCopyWith<$Res> implements $ScriptConditionCopyWith<$Res> {
  factory _$ScriptConditionCopyWith(_ScriptCondition value, $Res Function(_ScriptCondition) _then) = __$ScriptConditionCopyWithImpl;
@override @useResult
$Res call({
 ScriptConditionType type, Map<String, String> params, List<ScriptCondition> children
});




}
/// @nodoc
class __$ScriptConditionCopyWithImpl<$Res>
    implements _$ScriptConditionCopyWith<$Res> {
  __$ScriptConditionCopyWithImpl(this._self, this._then);

  final _ScriptCondition _self;
  final $Res Function(_ScriptCondition) _then;

/// Create a copy of ScriptCondition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? params = null,Object? children = null,}) {
  return _then(_ScriptCondition(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ScriptConditionType,params: null == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, String>,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<ScriptCondition>,
  ));
}


}

// dart format on
