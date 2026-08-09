// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'badge_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BadgeDefinition {

 String get id; String get label; String? get iconRelativePath; FieldAbility? get fieldAbilityUnlock;
/// Create a copy of BadgeDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadgeDefinitionCopyWith<BadgeDefinition> get copyWith => _$BadgeDefinitionCopyWithImpl<BadgeDefinition>(this as BadgeDefinition, _$identity);

  /// Serializes this BadgeDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BadgeDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.iconRelativePath, iconRelativePath) || other.iconRelativePath == iconRelativePath)&&(identical(other.fieldAbilityUnlock, fieldAbilityUnlock) || other.fieldAbilityUnlock == fieldAbilityUnlock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,iconRelativePath,fieldAbilityUnlock);

@override
String toString() {
  return 'BadgeDefinition(id: $id, label: $label, iconRelativePath: $iconRelativePath, fieldAbilityUnlock: $fieldAbilityUnlock)';
}


}

/// @nodoc
abstract mixin class $BadgeDefinitionCopyWith<$Res>  {
  factory $BadgeDefinitionCopyWith(BadgeDefinition value, $Res Function(BadgeDefinition) _then) = _$BadgeDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String label, String? iconRelativePath, FieldAbility? fieldAbilityUnlock
});




}
/// @nodoc
class _$BadgeDefinitionCopyWithImpl<$Res>
    implements $BadgeDefinitionCopyWith<$Res> {
  _$BadgeDefinitionCopyWithImpl(this._self, this._then);

  final BadgeDefinition _self;
  final $Res Function(BadgeDefinition) _then;

/// Create a copy of BadgeDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? iconRelativePath = freezed,Object? fieldAbilityUnlock = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,iconRelativePath: freezed == iconRelativePath ? _self.iconRelativePath : iconRelativePath // ignore: cast_nullable_to_non_nullable
as String?,fieldAbilityUnlock: freezed == fieldAbilityUnlock ? _self.fieldAbilityUnlock : fieldAbilityUnlock // ignore: cast_nullable_to_non_nullable
as FieldAbility?,
  ));
}

}


/// Adds pattern-matching-related methods to [BadgeDefinition].
extension BadgeDefinitionPatterns on BadgeDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BadgeDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BadgeDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BadgeDefinition value)  $default,){
final _that = this;
switch (_that) {
case _BadgeDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BadgeDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _BadgeDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String? iconRelativePath,  FieldAbility? fieldAbilityUnlock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BadgeDefinition() when $default != null:
return $default(_that.id,_that.label,_that.iconRelativePath,_that.fieldAbilityUnlock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String? iconRelativePath,  FieldAbility? fieldAbilityUnlock)  $default,) {final _that = this;
switch (_that) {
case _BadgeDefinition():
return $default(_that.id,_that.label,_that.iconRelativePath,_that.fieldAbilityUnlock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String? iconRelativePath,  FieldAbility? fieldAbilityUnlock)?  $default,) {final _that = this;
switch (_that) {
case _BadgeDefinition() when $default != null:
return $default(_that.id,_that.label,_that.iconRelativePath,_that.fieldAbilityUnlock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BadgeDefinition extends BadgeDefinition {
  const _BadgeDefinition({required this.id, required this.label, this.iconRelativePath, this.fieldAbilityUnlock}): super._();
  factory _BadgeDefinition.fromJson(Map<String, dynamic> json) => _$BadgeDefinitionFromJson(json);

@override final  String id;
@override final  String label;
@override final  String? iconRelativePath;
@override final  FieldAbility? fieldAbilityUnlock;

/// Create a copy of BadgeDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BadgeDefinitionCopyWith<_BadgeDefinition> get copyWith => __$BadgeDefinitionCopyWithImpl<_BadgeDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BadgeDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BadgeDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.iconRelativePath, iconRelativePath) || other.iconRelativePath == iconRelativePath)&&(identical(other.fieldAbilityUnlock, fieldAbilityUnlock) || other.fieldAbilityUnlock == fieldAbilityUnlock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,iconRelativePath,fieldAbilityUnlock);

@override
String toString() {
  return 'BadgeDefinition(id: $id, label: $label, iconRelativePath: $iconRelativePath, fieldAbilityUnlock: $fieldAbilityUnlock)';
}


}

/// @nodoc
abstract mixin class _$BadgeDefinitionCopyWith<$Res> implements $BadgeDefinitionCopyWith<$Res> {
  factory _$BadgeDefinitionCopyWith(_BadgeDefinition value, $Res Function(_BadgeDefinition) _then) = __$BadgeDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String? iconRelativePath, FieldAbility? fieldAbilityUnlock
});




}
/// @nodoc
class __$BadgeDefinitionCopyWithImpl<$Res>
    implements _$BadgeDefinitionCopyWith<$Res> {
  __$BadgeDefinitionCopyWithImpl(this._self, this._then);

  final _BadgeDefinition _self;
  final $Res Function(_BadgeDefinition) _then;

/// Create a copy of BadgeDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? iconRelativePath = freezed,Object? fieldAbilityUnlock = freezed,}) {
  return _then(_BadgeDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,iconRelativePath: freezed == iconRelativePath ? _self.iconRelativePath : iconRelativePath // ignore: cast_nullable_to_non_nullable
as String?,fieldAbilityUnlock: freezed == fieldAbilityUnlock ? _self.fieldAbilityUnlock : fieldAbilityUnlock // ignore: cast_nullable_to_non_nullable
as FieldAbility?,
  ));
}


}

// dart format on
