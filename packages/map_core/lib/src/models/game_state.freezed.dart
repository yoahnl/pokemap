// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
ScriptVariableValue _$ScriptVariableValueFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'bool':
          return ScriptVariableValueBool.fromJson(
            json
          );
                case 'int':
          return ScriptVariableValueInt.fromJson(
            json
          );
                case 'string':
          return ScriptVariableValueString.fromJson(
            json
          );

          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'ScriptVariableValue',
  'Invalid union type "${json['runtimeType']}"!'
);
        }

}

/// @nodoc
mixin _$ScriptVariableValue {

 Object get value;

  /// Serializes this ScriptVariableValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptVariableValue&&const DeepCollectionEquality().equals(other.value, value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'ScriptVariableValue(value: $value)';
}


}

/// @nodoc
class $ScriptVariableValueCopyWith<$Res>  {
$ScriptVariableValueCopyWith(ScriptVariableValue _, $Res Function(ScriptVariableValue) __);
}


/// Adds pattern-matching-related methods to [ScriptVariableValue].
extension ScriptVariableValuePatterns on ScriptVariableValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ScriptVariableValueBool value)?  bool,TResult Function( ScriptVariableValueInt value)?  int,TResult Function( ScriptVariableValueString value)?  string,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ScriptVariableValueBool() when bool != null:
return bool(_that);case ScriptVariableValueInt() when int != null:
return int(_that);case ScriptVariableValueString() when string != null:
return string(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ScriptVariableValueBool value)  bool,required TResult Function( ScriptVariableValueInt value)  int,required TResult Function( ScriptVariableValueString value)  string,}){
final _that = this;
switch (_that) {
case ScriptVariableValueBool():
return bool(_that);case ScriptVariableValueInt():
return int(_that);case ScriptVariableValueString():
return string(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ScriptVariableValueBool value)?  bool,TResult? Function( ScriptVariableValueInt value)?  int,TResult? Function( ScriptVariableValueString value)?  string,}){
final _that = this;
switch (_that) {
case ScriptVariableValueBool() when bool != null:
return bool(_that);case ScriptVariableValueInt() when int != null:
return int(_that);case ScriptVariableValueString() when string != null:
return string(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool value)?  bool,TResult Function( int value)?  int,TResult Function( String value)?  string,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ScriptVariableValueBool() when bool != null:
return bool(_that.value);case ScriptVariableValueInt() when int != null:
return int(_that.value);case ScriptVariableValueString() when string != null:
return string(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool value)  bool,required TResult Function( int value)  int,required TResult Function( String value)  string,}) {final _that = this;
switch (_that) {
case ScriptVariableValueBool():
return bool(_that.value);case ScriptVariableValueInt():
return int(_that.value);case ScriptVariableValueString():
return string(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool value)?  bool,TResult? Function( int value)?  int,TResult? Function( String value)?  string,}) {final _that = this;
switch (_that) {
case ScriptVariableValueBool() when bool != null:
return bool(_that.value);case ScriptVariableValueInt() when int != null:
return int(_that.value);case ScriptVariableValueString() when string != null:
return string(_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ScriptVariableValueBool implements ScriptVariableValue {
  const ScriptVariableValueBool(this.value, {final  String? $type}): $type = $type ?? 'bool';
  factory ScriptVariableValueBool.fromJson(Map<String, dynamic> json) => _$ScriptVariableValueBoolFromJson(json);

@override final  bool value;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ScriptVariableValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScriptVariableValueBoolCopyWith<ScriptVariableValueBool> get copyWith => _$ScriptVariableValueBoolCopyWithImpl<ScriptVariableValueBool>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScriptVariableValueBoolToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptVariableValueBool&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'ScriptVariableValue.bool(value: $value)';
}


}

/// @nodoc
abstract mixin class $ScriptVariableValueBoolCopyWith<$Res> implements $ScriptVariableValueCopyWith<$Res> {
  factory $ScriptVariableValueBoolCopyWith(ScriptVariableValueBool value, $Res Function(ScriptVariableValueBool) _then) = _$ScriptVariableValueBoolCopyWithImpl;
@useResult
$Res call({
 bool value
});




}
/// @nodoc
class _$ScriptVariableValueBoolCopyWithImpl<$Res>
    implements $ScriptVariableValueBoolCopyWith<$Res> {
  _$ScriptVariableValueBoolCopyWithImpl(this._self, this._then);

  final ScriptVariableValueBool _self;
  final $Res Function(ScriptVariableValueBool) _then;

/// Create a copy of ScriptVariableValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(ScriptVariableValueBool(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ScriptVariableValueInt implements ScriptVariableValue {
  const ScriptVariableValueInt(this.value, {final  String? $type}): $type = $type ?? 'int';
  factory ScriptVariableValueInt.fromJson(Map<String, dynamic> json) => _$ScriptVariableValueIntFromJson(json);

@override final  int value;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ScriptVariableValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScriptVariableValueIntCopyWith<ScriptVariableValueInt> get copyWith => _$ScriptVariableValueIntCopyWithImpl<ScriptVariableValueInt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScriptVariableValueIntToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptVariableValueInt&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'ScriptVariableValue.int(value: $value)';
}


}

/// @nodoc
abstract mixin class $ScriptVariableValueIntCopyWith<$Res> implements $ScriptVariableValueCopyWith<$Res> {
  factory $ScriptVariableValueIntCopyWith(ScriptVariableValueInt value, $Res Function(ScriptVariableValueInt) _then) = _$ScriptVariableValueIntCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$ScriptVariableValueIntCopyWithImpl<$Res>
    implements $ScriptVariableValueIntCopyWith<$Res> {
  _$ScriptVariableValueIntCopyWithImpl(this._self, this._then);

  final ScriptVariableValueInt _self;
  final $Res Function(ScriptVariableValueInt) _then;

/// Create a copy of ScriptVariableValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(ScriptVariableValueInt(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ScriptVariableValueString implements ScriptVariableValue {
  const ScriptVariableValueString(this.value, {final  String? $type}): $type = $type ?? 'string';
  factory ScriptVariableValueString.fromJson(Map<String, dynamic> json) => _$ScriptVariableValueStringFromJson(json);

@override final  String value;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ScriptVariableValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScriptVariableValueStringCopyWith<ScriptVariableValueString> get copyWith => _$ScriptVariableValueStringCopyWithImpl<ScriptVariableValueString>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScriptVariableValueStringToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptVariableValueString&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'ScriptVariableValue.string(value: $value)';
}


}

/// @nodoc
abstract mixin class $ScriptVariableValueStringCopyWith<$Res> implements $ScriptVariableValueCopyWith<$Res> {
  factory $ScriptVariableValueStringCopyWith(ScriptVariableValueString value, $Res Function(ScriptVariableValueString) _then) = _$ScriptVariableValueStringCopyWithImpl;
@useResult
$Res call({
 String value
});




}
/// @nodoc
class _$ScriptVariableValueStringCopyWithImpl<$Res>
    implements $ScriptVariableValueStringCopyWith<$Res> {
  _$ScriptVariableValueStringCopyWithImpl(this._self, this._then);

  final ScriptVariableValueString _self;
  final $Res Function(ScriptVariableValueString) _then;

/// Create a copy of ScriptVariableValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(ScriptVariableValueString(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ScriptVariables {

 Map<String, ScriptVariableValue> get values;
/// Create a copy of ScriptVariables
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScriptVariablesCopyWith<ScriptVariables> get copyWith => _$ScriptVariablesCopyWithImpl<ScriptVariables>(this as ScriptVariables, _$identity);

  /// Serializes this ScriptVariables to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScriptVariables&&const DeepCollectionEquality().equals(other.values, values));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(values));

@override
String toString() {
  return 'ScriptVariables(values: $values)';
}


}

/// @nodoc
abstract mixin class $ScriptVariablesCopyWith<$Res>  {
  factory $ScriptVariablesCopyWith(ScriptVariables value, $Res Function(ScriptVariables) _then) = _$ScriptVariablesCopyWithImpl;
@useResult
$Res call({
 Map<String, ScriptVariableValue> values
});




}
/// @nodoc
class _$ScriptVariablesCopyWithImpl<$Res>
    implements $ScriptVariablesCopyWith<$Res> {
  _$ScriptVariablesCopyWithImpl(this._self, this._then);

  final ScriptVariables _self;
  final $Res Function(ScriptVariables) _then;

/// Create a copy of ScriptVariables
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? values = null,}) {
  return _then(_self.copyWith(
values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as Map<String, ScriptVariableValue>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScriptVariables].
extension ScriptVariablesPatterns on ScriptVariables {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScriptVariables value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScriptVariables() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScriptVariables value)  $default,){
final _that = this;
switch (_that) {
case _ScriptVariables():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScriptVariables value)?  $default,){
final _that = this;
switch (_that) {
case _ScriptVariables() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, ScriptVariableValue> values)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScriptVariables() when $default != null:
return $default(_that.values);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, ScriptVariableValue> values)  $default,) {final _that = this;
switch (_that) {
case _ScriptVariables():
return $default(_that.values);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, ScriptVariableValue> values)?  $default,) {final _that = this;
switch (_that) {
case _ScriptVariables() when $default != null:
return $default(_that.values);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ScriptVariables implements ScriptVariables {
  const _ScriptVariables({final  Map<String, ScriptVariableValue> values = const {}}): _values = values;
  factory _ScriptVariables.fromJson(Map<String, dynamic> json) => _$ScriptVariablesFromJson(json);

 final  Map<String, ScriptVariableValue> _values;
@override@JsonKey() Map<String, ScriptVariableValue> get values {
  if (_values is EqualUnmodifiableMapView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_values);
}


/// Create a copy of ScriptVariables
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScriptVariablesCopyWith<_ScriptVariables> get copyWith => __$ScriptVariablesCopyWithImpl<_ScriptVariables>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScriptVariablesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScriptVariables&&const DeepCollectionEquality().equals(other._values, _values));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'ScriptVariables(values: $values)';
}


}

/// @nodoc
abstract mixin class _$ScriptVariablesCopyWith<$Res> implements $ScriptVariablesCopyWith<$Res> {
  factory _$ScriptVariablesCopyWith(_ScriptVariables value, $Res Function(_ScriptVariables) _then) = __$ScriptVariablesCopyWithImpl;
@override @useResult
$Res call({
 Map<String, ScriptVariableValue> values
});




}
/// @nodoc
class __$ScriptVariablesCopyWithImpl<$Res>
    implements _$ScriptVariablesCopyWith<$Res> {
  __$ScriptVariablesCopyWithImpl(this._self, this._then);

  final _ScriptVariables _self;
  final $Res Function(_ScriptVariables) _then;

/// Create a copy of ScriptVariables
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? values = null,}) {
  return _then(_ScriptVariables(
values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as Map<String, ScriptVariableValue>,
  ));
}


}


/// @nodoc
mixin _$StoryFlags {

 Set<String> get activeFlags;
/// Create a copy of StoryFlags
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryFlagsCopyWith<StoryFlags> get copyWith => _$StoryFlagsCopyWithImpl<StoryFlags>(this as StoryFlags, _$identity);

  /// Serializes this StoryFlags to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryFlags&&const DeepCollectionEquality().equals(other.activeFlags, activeFlags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(activeFlags));

@override
String toString() {
  return 'StoryFlags(activeFlags: $activeFlags)';
}


}

/// @nodoc
abstract mixin class $StoryFlagsCopyWith<$Res>  {
  factory $StoryFlagsCopyWith(StoryFlags value, $Res Function(StoryFlags) _then) = _$StoryFlagsCopyWithImpl;
@useResult
$Res call({
 Set<String> activeFlags
});




}
/// @nodoc
class _$StoryFlagsCopyWithImpl<$Res>
    implements $StoryFlagsCopyWith<$Res> {
  _$StoryFlagsCopyWithImpl(this._self, this._then);

  final StoryFlags _self;
  final $Res Function(StoryFlags) _then;

/// Create a copy of StoryFlags
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeFlags = null,}) {
  return _then(_self.copyWith(
activeFlags: null == activeFlags ? _self.activeFlags : activeFlags // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [StoryFlags].
extension StoryFlagsPatterns on StoryFlags {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoryFlags value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoryFlags() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoryFlags value)  $default,){
final _that = this;
switch (_that) {
case _StoryFlags():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoryFlags value)?  $default,){
final _that = this;
switch (_that) {
case _StoryFlags() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<String> activeFlags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoryFlags() when $default != null:
return $default(_that.activeFlags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<String> activeFlags)  $default,) {final _that = this;
switch (_that) {
case _StoryFlags():
return $default(_that.activeFlags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<String> activeFlags)?  $default,) {final _that = this;
switch (_that) {
case _StoryFlags() when $default != null:
return $default(_that.activeFlags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoryFlags implements StoryFlags {
  const _StoryFlags({final  Set<String> activeFlags = const {}}): _activeFlags = activeFlags;
  factory _StoryFlags.fromJson(Map<String, dynamic> json) => _$StoryFlagsFromJson(json);

 final  Set<String> _activeFlags;
@override@JsonKey() Set<String> get activeFlags {
  if (_activeFlags is EqualUnmodifiableSetView) return _activeFlags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activeFlags);
}


/// Create a copy of StoryFlags
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoryFlagsCopyWith<_StoryFlags> get copyWith => __$StoryFlagsCopyWithImpl<_StoryFlags>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoryFlagsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoryFlags&&const DeepCollectionEquality().equals(other._activeFlags, _activeFlags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_activeFlags));

@override
String toString() {
  return 'StoryFlags(activeFlags: $activeFlags)';
}


}

/// @nodoc
abstract mixin class _$StoryFlagsCopyWith<$Res> implements $StoryFlagsCopyWith<$Res> {
  factory _$StoryFlagsCopyWith(_StoryFlags value, $Res Function(_StoryFlags) _then) = __$StoryFlagsCopyWithImpl;
@override @useResult
$Res call({
 Set<String> activeFlags
});




}
/// @nodoc
class __$StoryFlagsCopyWithImpl<$Res>
    implements _$StoryFlagsCopyWith<$Res> {
  __$StoryFlagsCopyWithImpl(this._self, this._then);

  final _StoryFlags _self;
  final $Res Function(_StoryFlags) _then;

/// Create a copy of StoryFlags
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeFlags = null,}) {
  return _then(_StoryFlags(
activeFlags: null == activeFlags ? _self._activeFlags : activeFlags // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}


/// @nodoc
mixin _$GameState {

/// Identifiant unique de la sauvegarde.
 String get saveId;/// Map actuelle du joueur.
 String get currentMapId;/// Position du joueur sur la map.
 GridPos get playerPosition;/// Orientation du joueur.
 EntityFacing get playerFacing;/// Mode de déplacement actuel (walk / surf).
 MovementMode get playerMovementMode;/// Équipe du joueur.
 PlayerParty get party; PokemonStorage get pokemonStorage; TrainerProfile get trainerProfile; Bag get bag;/// Progression narrative et capacités.
 PlayerProgression get progression;/// Variables de script (int/bool/string).
 ScriptVariables get scriptVariables;/// Flags narratifs (booléens).
 StoryFlags get storyFlags;@JsonKey(readValue: readNarrativeFactRuntimeStateJson) NarrativeFactRuntimeState get narrativeFactRuntimeState;@JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) NarrativeEventProgress get narrativeEventProgress; Set<String> get completedBattleRequestIds; Set<String> get appliedPokemonGrantOperationIds;/// IDs d'événements déjà consommés (objets ramassés, etc.).
 Set<String> get consumedEventIds;/// Métadonnées internes (timestamp, version, etc.).
 Map<String, String> get metadata;
/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateCopyWith<GameState> get copyWith => _$GameStateCopyWithImpl<GameState>(this as GameState, _$identity);

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameState&&(identical(other.saveId, saveId) || other.saveId == saveId)&&(identical(other.currentMapId, currentMapId) || other.currentMapId == currentMapId)&&(identical(other.playerPosition, playerPosition) || other.playerPosition == playerPosition)&&(identical(other.playerFacing, playerFacing) || other.playerFacing == playerFacing)&&(identical(other.playerMovementMode, playerMovementMode) || other.playerMovementMode == playerMovementMode)&&(identical(other.party, party) || other.party == party)&&(identical(other.pokemonStorage, pokemonStorage) || other.pokemonStorage == pokemonStorage)&&(identical(other.trainerProfile, trainerProfile) || other.trainerProfile == trainerProfile)&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.progression, progression) || other.progression == progression)&&(identical(other.scriptVariables, scriptVariables) || other.scriptVariables == scriptVariables)&&(identical(other.storyFlags, storyFlags) || other.storyFlags == storyFlags)&&(identical(other.narrativeFactRuntimeState, narrativeFactRuntimeState) || other.narrativeFactRuntimeState == narrativeFactRuntimeState)&&(identical(other.narrativeEventProgress, narrativeEventProgress) || other.narrativeEventProgress == narrativeEventProgress)&&const DeepCollectionEquality().equals(other.completedBattleRequestIds, completedBattleRequestIds)&&const DeepCollectionEquality().equals(other.appliedPokemonGrantOperationIds, appliedPokemonGrantOperationIds)&&const DeepCollectionEquality().equals(other.consumedEventIds, consumedEventIds)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,saveId,currentMapId,playerPosition,playerFacing,playerMovementMode,party,pokemonStorage,trainerProfile,bag,progression,scriptVariables,storyFlags,narrativeFactRuntimeState,narrativeEventProgress,const DeepCollectionEquality().hash(completedBattleRequestIds),const DeepCollectionEquality().hash(appliedPokemonGrantOperationIds),const DeepCollectionEquality().hash(consumedEventIds),const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'GameState(saveId: $saveId, currentMapId: $currentMapId, playerPosition: $playerPosition, playerFacing: $playerFacing, playerMovementMode: $playerMovementMode, party: $party, pokemonStorage: $pokemonStorage, trainerProfile: $trainerProfile, bag: $bag, progression: $progression, scriptVariables: $scriptVariables, storyFlags: $storyFlags, narrativeFactRuntimeState: $narrativeFactRuntimeState, narrativeEventProgress: $narrativeEventProgress, completedBattleRequestIds: $completedBattleRequestIds, appliedPokemonGrantOperationIds: $appliedPokemonGrantOperationIds, consumedEventIds: $consumedEventIds, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $GameStateCopyWith<$Res>  {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) _then) = _$GameStateCopyWithImpl;
@useResult
$Res call({
 String saveId, String currentMapId, GridPos playerPosition, EntityFacing playerFacing, MovementMode playerMovementMode, PlayerParty party, PokemonStorage pokemonStorage, TrainerProfile trainerProfile, Bag bag, PlayerProgression progression, ScriptVariables scriptVariables, StoryFlags storyFlags,@JsonKey(readValue: readNarrativeFactRuntimeStateJson) NarrativeFactRuntimeState narrativeFactRuntimeState,@JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) NarrativeEventProgress narrativeEventProgress, Set<String> completedBattleRequestIds, Set<String> appliedPokemonGrantOperationIds, Set<String> consumedEventIds, Map<String, String> metadata
});


$GridPosCopyWith<$Res> get playerPosition;$PlayerPartyCopyWith<$Res> get party;$TrainerProfileCopyWith<$Res> get trainerProfile;$BagCopyWith<$Res> get bag;$PlayerProgressionCopyWith<$Res> get progression;$ScriptVariablesCopyWith<$Res> get scriptVariables;$StoryFlagsCopyWith<$Res> get storyFlags;

}
/// @nodoc
class _$GameStateCopyWithImpl<$Res>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._self, this._then);

  final GameState _self;
  final $Res Function(GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? saveId = null,Object? currentMapId = null,Object? playerPosition = null,Object? playerFacing = null,Object? playerMovementMode = null,Object? party = null,Object? pokemonStorage = null,Object? trainerProfile = null,Object? bag = null,Object? progression = null,Object? scriptVariables = null,Object? storyFlags = null,Object? narrativeFactRuntimeState = null,Object? narrativeEventProgress = null,Object? completedBattleRequestIds = null,Object? appliedPokemonGrantOperationIds = null,Object? consumedEventIds = null,Object? metadata = null,}) {
  return _then(_self.copyWith(
saveId: null == saveId ? _self.saveId : saveId // ignore: cast_nullable_to_non_nullable
as String,currentMapId: null == currentMapId ? _self.currentMapId : currentMapId // ignore: cast_nullable_to_non_nullable
as String,playerPosition: null == playerPosition ? _self.playerPosition : playerPosition // ignore: cast_nullable_to_non_nullable
as GridPos,playerFacing: null == playerFacing ? _self.playerFacing : playerFacing // ignore: cast_nullable_to_non_nullable
as EntityFacing,playerMovementMode: null == playerMovementMode ? _self.playerMovementMode : playerMovementMode // ignore: cast_nullable_to_non_nullable
as MovementMode,party: null == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as PlayerParty,pokemonStorage: null == pokemonStorage ? _self.pokemonStorage : pokemonStorage // ignore: cast_nullable_to_non_nullable
as PokemonStorage,trainerProfile: null == trainerProfile ? _self.trainerProfile : trainerProfile // ignore: cast_nullable_to_non_nullable
as TrainerProfile,bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as Bag,progression: null == progression ? _self.progression : progression // ignore: cast_nullable_to_non_nullable
as PlayerProgression,scriptVariables: null == scriptVariables ? _self.scriptVariables : scriptVariables // ignore: cast_nullable_to_non_nullable
as ScriptVariables,storyFlags: null == storyFlags ? _self.storyFlags : storyFlags // ignore: cast_nullable_to_non_nullable
as StoryFlags,narrativeFactRuntimeState: null == narrativeFactRuntimeState ? _self.narrativeFactRuntimeState : narrativeFactRuntimeState // ignore: cast_nullable_to_non_nullable
as NarrativeFactRuntimeState,narrativeEventProgress: null == narrativeEventProgress ? _self.narrativeEventProgress : narrativeEventProgress // ignore: cast_nullable_to_non_nullable
as NarrativeEventProgress,completedBattleRequestIds: null == completedBattleRequestIds ? _self.completedBattleRequestIds : completedBattleRequestIds // ignore: cast_nullable_to_non_nullable
as Set<String>,appliedPokemonGrantOperationIds: null == appliedPokemonGrantOperationIds ? _self.appliedPokemonGrantOperationIds : appliedPokemonGrantOperationIds // ignore: cast_nullable_to_non_nullable
as Set<String>,consumedEventIds: null == consumedEventIds ? _self.consumedEventIds : consumedEventIds // ignore: cast_nullable_to_non_nullable
as Set<String>,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get playerPosition {

  return $GridPosCopyWith<$Res>(_self.playerPosition, (value) {
    return _then(_self.copyWith(playerPosition: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerPartyCopyWith<$Res> get party {

  return $PlayerPartyCopyWith<$Res>(_self.party, (value) {
    return _then(_self.copyWith(party: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainerProfileCopyWith<$Res> get trainerProfile {

  return $TrainerProfileCopyWith<$Res>(_self.trainerProfile, (value) {
    return _then(_self.copyWith(trainerProfile: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BagCopyWith<$Res> get bag {

  return $BagCopyWith<$Res>(_self.bag, (value) {
    return _then(_self.copyWith(bag: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerProgressionCopyWith<$Res> get progression {

  return $PlayerProgressionCopyWith<$Res>(_self.progression, (value) {
    return _then(_self.copyWith(progression: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptVariablesCopyWith<$Res> get scriptVariables {

  return $ScriptVariablesCopyWith<$Res>(_self.scriptVariables, (value) {
    return _then(_self.copyWith(scriptVariables: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoryFlagsCopyWith<$Res> get storyFlags {

  return $StoryFlagsCopyWith<$Res>(_self.storyFlags, (value) {
    return _then(_self.copyWith(storyFlags: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameState].
extension GameStatePatterns on GameState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameState value)  $default,){
final _that = this;
switch (_that) {
case _GameState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameState value)?  $default,){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String saveId,  String currentMapId,  GridPos playerPosition,  EntityFacing playerFacing,  MovementMode playerMovementMode,  PlayerParty party,  PokemonStorage pokemonStorage,  TrainerProfile trainerProfile,  Bag bag,  PlayerProgression progression,  ScriptVariables scriptVariables,  StoryFlags storyFlags, @JsonKey(readValue: readNarrativeFactRuntimeStateJson)  NarrativeFactRuntimeState narrativeFactRuntimeState, @JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson)  NarrativeEventProgress narrativeEventProgress,  Set<String> completedBattleRequestIds,  Set<String> appliedPokemonGrantOperationIds,  Set<String> consumedEventIds,  Map<String, String> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.saveId,_that.currentMapId,_that.playerPosition,_that.playerFacing,_that.playerMovementMode,_that.party,_that.pokemonStorage,_that.trainerProfile,_that.bag,_that.progression,_that.scriptVariables,_that.storyFlags,_that.narrativeFactRuntimeState,_that.narrativeEventProgress,_that.completedBattleRequestIds,_that.appliedPokemonGrantOperationIds,_that.consumedEventIds,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String saveId,  String currentMapId,  GridPos playerPosition,  EntityFacing playerFacing,  MovementMode playerMovementMode,  PlayerParty party,  PokemonStorage pokemonStorage,  TrainerProfile trainerProfile,  Bag bag,  PlayerProgression progression,  ScriptVariables scriptVariables,  StoryFlags storyFlags, @JsonKey(readValue: readNarrativeFactRuntimeStateJson)  NarrativeFactRuntimeState narrativeFactRuntimeState, @JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson)  NarrativeEventProgress narrativeEventProgress,  Set<String> completedBattleRequestIds,  Set<String> appliedPokemonGrantOperationIds,  Set<String> consumedEventIds,  Map<String, String> metadata)  $default,) {final _that = this;
switch (_that) {
case _GameState():
return $default(_that.saveId,_that.currentMapId,_that.playerPosition,_that.playerFacing,_that.playerMovementMode,_that.party,_that.pokemonStorage,_that.trainerProfile,_that.bag,_that.progression,_that.scriptVariables,_that.storyFlags,_that.narrativeFactRuntimeState,_that.narrativeEventProgress,_that.completedBattleRequestIds,_that.appliedPokemonGrantOperationIds,_that.consumedEventIds,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String saveId,  String currentMapId,  GridPos playerPosition,  EntityFacing playerFacing,  MovementMode playerMovementMode,  PlayerParty party,  PokemonStorage pokemonStorage,  TrainerProfile trainerProfile,  Bag bag,  PlayerProgression progression,  ScriptVariables scriptVariables,  StoryFlags storyFlags, @JsonKey(readValue: readNarrativeFactRuntimeStateJson)  NarrativeFactRuntimeState narrativeFactRuntimeState, @JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson)  NarrativeEventProgress narrativeEventProgress,  Set<String> completedBattleRequestIds,  Set<String> appliedPokemonGrantOperationIds,  Set<String> consumedEventIds,  Map<String, String> metadata)?  $default,) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.saveId,_that.currentMapId,_that.playerPosition,_that.playerFacing,_that.playerMovementMode,_that.party,_that.pokemonStorage,_that.trainerProfile,_that.bag,_that.progression,_that.scriptVariables,_that.storyFlags,_that.narrativeFactRuntimeState,_that.narrativeEventProgress,_that.completedBattleRequestIds,_that.appliedPokemonGrantOperationIds,_that.consumedEventIds,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GameState implements GameState {
  const _GameState({required this.saveId, this.currentMapId = '', this.playerPosition = const GridPos(x: 0, y: 0), this.playerFacing = EntityFacing.south, this.playerMovementMode = MovementMode.walk, this.party = const PlayerParty(), this.pokemonStorage = const PokemonStorage(), this.trainerProfile = const TrainerProfile(name: 'Player'), this.bag = const Bag(), this.progression = const PlayerProgression(), this.scriptVariables = const ScriptVariables(), this.storyFlags = const StoryFlags(), @JsonKey(readValue: readNarrativeFactRuntimeStateJson) this.narrativeFactRuntimeState = const NarrativeFactRuntimeState.empty(), @JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) this.narrativeEventProgress = const NarrativeEventProgress.empty(), final  Set<String> completedBattleRequestIds = const {}, final  Set<String> appliedPokemonGrantOperationIds = const {}, final  Set<String> consumedEventIds = const {}, final  Map<String, String> metadata = const {}}): _completedBattleRequestIds = completedBattleRequestIds,_appliedPokemonGrantOperationIds = appliedPokemonGrantOperationIds,_consumedEventIds = consumedEventIds,_metadata = metadata;
  factory _GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);

/// Identifiant unique de la sauvegarde.
@override final  String saveId;
/// Map actuelle du joueur.
@override@JsonKey() final  String currentMapId;
/// Position du joueur sur la map.
@override@JsonKey() final  GridPos playerPosition;
/// Orientation du joueur.
@override@JsonKey() final  EntityFacing playerFacing;
/// Mode de déplacement actuel (walk / surf).
@override@JsonKey() final  MovementMode playerMovementMode;
/// Équipe du joueur.
@override@JsonKey() final  PlayerParty party;
@override@JsonKey() final  PokemonStorage pokemonStorage;
@override@JsonKey() final  TrainerProfile trainerProfile;
@override@JsonKey() final  Bag bag;
/// Progression narrative et capacités.
@override@JsonKey() final  PlayerProgression progression;
/// Variables de script (int/bool/string).
@override@JsonKey() final  ScriptVariables scriptVariables;
/// Flags narratifs (booléens).
@override@JsonKey() final  StoryFlags storyFlags;
@override@JsonKey(readValue: readNarrativeFactRuntimeStateJson) final  NarrativeFactRuntimeState narrativeFactRuntimeState;
@override@JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) final  NarrativeEventProgress narrativeEventProgress;
 final  Set<String> _completedBattleRequestIds;
@override@JsonKey() Set<String> get completedBattleRequestIds {
  if (_completedBattleRequestIds is EqualUnmodifiableSetView) return _completedBattleRequestIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_completedBattleRequestIds);
}

 final  Set<String> _appliedPokemonGrantOperationIds;
@override@JsonKey() Set<String> get appliedPokemonGrantOperationIds {
  if (_appliedPokemonGrantOperationIds is EqualUnmodifiableSetView) return _appliedPokemonGrantOperationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_appliedPokemonGrantOperationIds);
}

/// IDs d'événements déjà consommés (objets ramassés, etc.).
 final  Set<String> _consumedEventIds;
/// IDs d'événements déjà consommés (objets ramassés, etc.).
@override@JsonKey() Set<String> get consumedEventIds {
  if (_consumedEventIds is EqualUnmodifiableSetView) return _consumedEventIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_consumedEventIds);
}

/// Métadonnées internes (timestamp, version, etc.).
 final  Map<String, String> _metadata;
/// Métadonnées internes (timestamp, version, etc.).
@override@JsonKey() Map<String, String> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameStateCopyWith<_GameState> get copyWith => __$GameStateCopyWithImpl<_GameState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameState&&(identical(other.saveId, saveId) || other.saveId == saveId)&&(identical(other.currentMapId, currentMapId) || other.currentMapId == currentMapId)&&(identical(other.playerPosition, playerPosition) || other.playerPosition == playerPosition)&&(identical(other.playerFacing, playerFacing) || other.playerFacing == playerFacing)&&(identical(other.playerMovementMode, playerMovementMode) || other.playerMovementMode == playerMovementMode)&&(identical(other.party, party) || other.party == party)&&(identical(other.pokemonStorage, pokemonStorage) || other.pokemonStorage == pokemonStorage)&&(identical(other.trainerProfile, trainerProfile) || other.trainerProfile == trainerProfile)&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.progression, progression) || other.progression == progression)&&(identical(other.scriptVariables, scriptVariables) || other.scriptVariables == scriptVariables)&&(identical(other.storyFlags, storyFlags) || other.storyFlags == storyFlags)&&(identical(other.narrativeFactRuntimeState, narrativeFactRuntimeState) || other.narrativeFactRuntimeState == narrativeFactRuntimeState)&&(identical(other.narrativeEventProgress, narrativeEventProgress) || other.narrativeEventProgress == narrativeEventProgress)&&const DeepCollectionEquality().equals(other._completedBattleRequestIds, _completedBattleRequestIds)&&const DeepCollectionEquality().equals(other._appliedPokemonGrantOperationIds, _appliedPokemonGrantOperationIds)&&const DeepCollectionEquality().equals(other._consumedEventIds, _consumedEventIds)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,saveId,currentMapId,playerPosition,playerFacing,playerMovementMode,party,pokemonStorage,trainerProfile,bag,progression,scriptVariables,storyFlags,narrativeFactRuntimeState,narrativeEventProgress,const DeepCollectionEquality().hash(_completedBattleRequestIds),const DeepCollectionEquality().hash(_appliedPokemonGrantOperationIds),const DeepCollectionEquality().hash(_consumedEventIds),const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'GameState(saveId: $saveId, currentMapId: $currentMapId, playerPosition: $playerPosition, playerFacing: $playerFacing, playerMovementMode: $playerMovementMode, party: $party, pokemonStorage: $pokemonStorage, trainerProfile: $trainerProfile, bag: $bag, progression: $progression, scriptVariables: $scriptVariables, storyFlags: $storyFlags, narrativeFactRuntimeState: $narrativeFactRuntimeState, narrativeEventProgress: $narrativeEventProgress, completedBattleRequestIds: $completedBattleRequestIds, appliedPokemonGrantOperationIds: $appliedPokemonGrantOperationIds, consumedEventIds: $consumedEventIds, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$GameStateCopyWith<$Res> implements $GameStateCopyWith<$Res> {
  factory _$GameStateCopyWith(_GameState value, $Res Function(_GameState) _then) = __$GameStateCopyWithImpl;
@override @useResult
$Res call({
 String saveId, String currentMapId, GridPos playerPosition, EntityFacing playerFacing, MovementMode playerMovementMode, PlayerParty party, PokemonStorage pokemonStorage, TrainerProfile trainerProfile, Bag bag, PlayerProgression progression, ScriptVariables scriptVariables, StoryFlags storyFlags,@JsonKey(readValue: readNarrativeFactRuntimeStateJson) NarrativeFactRuntimeState narrativeFactRuntimeState,@JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) NarrativeEventProgress narrativeEventProgress, Set<String> completedBattleRequestIds, Set<String> appliedPokemonGrantOperationIds, Set<String> consumedEventIds, Map<String, String> metadata
});


@override $GridPosCopyWith<$Res> get playerPosition;@override $PlayerPartyCopyWith<$Res> get party;@override $TrainerProfileCopyWith<$Res> get trainerProfile;@override $BagCopyWith<$Res> get bag;@override $PlayerProgressionCopyWith<$Res> get progression;@override $ScriptVariablesCopyWith<$Res> get scriptVariables;@override $StoryFlagsCopyWith<$Res> get storyFlags;

}
/// @nodoc
class __$GameStateCopyWithImpl<$Res>
    implements _$GameStateCopyWith<$Res> {
  __$GameStateCopyWithImpl(this._self, this._then);

  final _GameState _self;
  final $Res Function(_GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? saveId = null,Object? currentMapId = null,Object? playerPosition = null,Object? playerFacing = null,Object? playerMovementMode = null,Object? party = null,Object? pokemonStorage = null,Object? trainerProfile = null,Object? bag = null,Object? progression = null,Object? scriptVariables = null,Object? storyFlags = null,Object? narrativeFactRuntimeState = null,Object? narrativeEventProgress = null,Object? completedBattleRequestIds = null,Object? appliedPokemonGrantOperationIds = null,Object? consumedEventIds = null,Object? metadata = null,}) {
  return _then(_GameState(
saveId: null == saveId ? _self.saveId : saveId // ignore: cast_nullable_to_non_nullable
as String,currentMapId: null == currentMapId ? _self.currentMapId : currentMapId // ignore: cast_nullable_to_non_nullable
as String,playerPosition: null == playerPosition ? _self.playerPosition : playerPosition // ignore: cast_nullable_to_non_nullable
as GridPos,playerFacing: null == playerFacing ? _self.playerFacing : playerFacing // ignore: cast_nullable_to_non_nullable
as EntityFacing,playerMovementMode: null == playerMovementMode ? _self.playerMovementMode : playerMovementMode // ignore: cast_nullable_to_non_nullable
as MovementMode,party: null == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as PlayerParty,pokemonStorage: null == pokemonStorage ? _self.pokemonStorage : pokemonStorage // ignore: cast_nullable_to_non_nullable
as PokemonStorage,trainerProfile: null == trainerProfile ? _self.trainerProfile : trainerProfile // ignore: cast_nullable_to_non_nullable
as TrainerProfile,bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as Bag,progression: null == progression ? _self.progression : progression // ignore: cast_nullable_to_non_nullable
as PlayerProgression,scriptVariables: null == scriptVariables ? _self.scriptVariables : scriptVariables // ignore: cast_nullable_to_non_nullable
as ScriptVariables,storyFlags: null == storyFlags ? _self.storyFlags : storyFlags // ignore: cast_nullable_to_non_nullable
as StoryFlags,narrativeFactRuntimeState: null == narrativeFactRuntimeState ? _self.narrativeFactRuntimeState : narrativeFactRuntimeState // ignore: cast_nullable_to_non_nullable
as NarrativeFactRuntimeState,narrativeEventProgress: null == narrativeEventProgress ? _self.narrativeEventProgress : narrativeEventProgress // ignore: cast_nullable_to_non_nullable
as NarrativeEventProgress,completedBattleRequestIds: null == completedBattleRequestIds ? _self._completedBattleRequestIds : completedBattleRequestIds // ignore: cast_nullable_to_non_nullable
as Set<String>,appliedPokemonGrantOperationIds: null == appliedPokemonGrantOperationIds ? _self._appliedPokemonGrantOperationIds : appliedPokemonGrantOperationIds // ignore: cast_nullable_to_non_nullable
as Set<String>,consumedEventIds: null == consumedEventIds ? _self._consumedEventIds : consumedEventIds // ignore: cast_nullable_to_non_nullable
as Set<String>,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get playerPosition {

  return $GridPosCopyWith<$Res>(_self.playerPosition, (value) {
    return _then(_self.copyWith(playerPosition: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerPartyCopyWith<$Res> get party {

  return $PlayerPartyCopyWith<$Res>(_self.party, (value) {
    return _then(_self.copyWith(party: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainerProfileCopyWith<$Res> get trainerProfile {

  return $TrainerProfileCopyWith<$Res>(_self.trainerProfile, (value) {
    return _then(_self.copyWith(trainerProfile: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BagCopyWith<$Res> get bag {

  return $BagCopyWith<$Res>(_self.bag, (value) {
    return _then(_self.copyWith(bag: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerProgressionCopyWith<$Res> get progression {

  return $PlayerProgressionCopyWith<$Res>(_self.progression, (value) {
    return _then(_self.copyWith(progression: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptVariablesCopyWith<$Res> get scriptVariables {

  return $ScriptVariablesCopyWith<$Res>(_self.scriptVariables, (value) {
    return _then(_self.copyWith(scriptVariables: value));
  });
}/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StoryFlagsCopyWith<$Res> get storyFlags {

  return $StoryFlagsCopyWith<$Res>(_self.storyFlags, (value) {
    return _then(_self.copyWith(storyFlags: value));
  });
}
}

// dart format on
