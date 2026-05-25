// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScriptVariableValue _$ScriptVariableValueFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'bool':
      return ScriptVariableValueBool.fromJson(json);
    case 'int':
      return ScriptVariableValueInt.fromJson(json);
    case 'string':
      return ScriptVariableValueString.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'ScriptVariableValue',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$ScriptVariableValue {
  Object get value => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool value) bool,
    required TResult Function(int value) int,
    required TResult Function(String value) string,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool value)? bool,
    TResult? Function(int value)? int,
    TResult? Function(String value)? string,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool value)? bool,
    TResult Function(int value)? int,
    TResult Function(String value)? string,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptVariableValueBool value) bool,
    required TResult Function(ScriptVariableValueInt value) int,
    required TResult Function(ScriptVariableValueString value) string,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptVariableValueBool value)? bool,
    TResult? Function(ScriptVariableValueInt value)? int,
    TResult? Function(ScriptVariableValueString value)? string,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptVariableValueBool value)? bool,
    TResult Function(ScriptVariableValueInt value)? int,
    TResult Function(ScriptVariableValueString value)? string,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ScriptVariableValue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptVariableValueCopyWith<$Res> {
  factory $ScriptVariableValueCopyWith(
          ScriptVariableValue value, $Res Function(ScriptVariableValue) then) =
      _$ScriptVariableValueCopyWithImpl<$Res, ScriptVariableValue>;
}

/// @nodoc
class _$ScriptVariableValueCopyWithImpl<$Res, $Val extends ScriptVariableValue>
    implements $ScriptVariableValueCopyWith<$Res> {
  _$ScriptVariableValueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ScriptVariableValueBoolImplCopyWith<$Res> {
  factory _$$ScriptVariableValueBoolImplCopyWith(
          _$ScriptVariableValueBoolImpl value,
          $Res Function(_$ScriptVariableValueBoolImpl) then) =
      __$$ScriptVariableValueBoolImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool value});
}

/// @nodoc
class __$$ScriptVariableValueBoolImplCopyWithImpl<$Res>
    extends _$ScriptVariableValueCopyWithImpl<$Res,
        _$ScriptVariableValueBoolImpl>
    implements _$$ScriptVariableValueBoolImplCopyWith<$Res> {
  __$$ScriptVariableValueBoolImplCopyWithImpl(
      _$ScriptVariableValueBoolImpl _value,
      $Res Function(_$ScriptVariableValueBoolImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$ScriptVariableValueBoolImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScriptVariableValueBoolImpl implements ScriptVariableValueBool {
  const _$ScriptVariableValueBoolImpl(this.value, {final String? $type})
      : $type = $type ?? 'bool';

  factory _$ScriptVariableValueBoolImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptVariableValueBoolImplFromJson(json);

  @override
  final bool value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ScriptVariableValue.bool(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptVariableValueBoolImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptVariableValueBoolImplCopyWith<_$ScriptVariableValueBoolImpl>
      get copyWith => __$$ScriptVariableValueBoolImplCopyWithImpl<
          _$ScriptVariableValueBoolImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool value) bool,
    required TResult Function(int value) int,
    required TResult Function(String value) string,
  }) {
    return bool(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool value)? bool,
    TResult? Function(int value)? int,
    TResult? Function(String value)? string,
  }) {
    return bool?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool value)? bool,
    TResult Function(int value)? int,
    TResult Function(String value)? string,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptVariableValueBool value) bool,
    required TResult Function(ScriptVariableValueInt value) int,
    required TResult Function(ScriptVariableValueString value) string,
  }) {
    return bool(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptVariableValueBool value)? bool,
    TResult? Function(ScriptVariableValueInt value)? int,
    TResult? Function(ScriptVariableValueString value)? string,
  }) {
    return bool?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptVariableValueBool value)? bool,
    TResult Function(ScriptVariableValueInt value)? int,
    TResult Function(ScriptVariableValueString value)? string,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptVariableValueBoolImplToJson(
      this,
    );
  }
}

abstract class ScriptVariableValueBool implements ScriptVariableValue {
  const factory ScriptVariableValueBool(final bool value) =
      _$ScriptVariableValueBoolImpl;

  factory ScriptVariableValueBool.fromJson(Map<String, dynamic> json) =
      _$ScriptVariableValueBoolImpl.fromJson;

  @override
  bool get value;

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptVariableValueBoolImplCopyWith<_$ScriptVariableValueBoolImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ScriptVariableValueIntImplCopyWith<$Res> {
  factory _$$ScriptVariableValueIntImplCopyWith(
          _$ScriptVariableValueIntImpl value,
          $Res Function(_$ScriptVariableValueIntImpl) then) =
      __$$ScriptVariableValueIntImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int value});
}

/// @nodoc
class __$$ScriptVariableValueIntImplCopyWithImpl<$Res>
    extends _$ScriptVariableValueCopyWithImpl<$Res,
        _$ScriptVariableValueIntImpl>
    implements _$$ScriptVariableValueIntImplCopyWith<$Res> {
  __$$ScriptVariableValueIntImplCopyWithImpl(
      _$ScriptVariableValueIntImpl _value,
      $Res Function(_$ScriptVariableValueIntImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$ScriptVariableValueIntImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScriptVariableValueIntImpl implements ScriptVariableValueInt {
  const _$ScriptVariableValueIntImpl(this.value, {final String? $type})
      : $type = $type ?? 'int';

  factory _$ScriptVariableValueIntImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptVariableValueIntImplFromJson(json);

  @override
  final int value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ScriptVariableValue.int(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptVariableValueIntImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptVariableValueIntImplCopyWith<_$ScriptVariableValueIntImpl>
      get copyWith => __$$ScriptVariableValueIntImplCopyWithImpl<
          _$ScriptVariableValueIntImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool value) bool,
    required TResult Function(int value) int,
    required TResult Function(String value) string,
  }) {
    return int(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool value)? bool,
    TResult? Function(int value)? int,
    TResult? Function(String value)? string,
  }) {
    return int?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool value)? bool,
    TResult Function(int value)? int,
    TResult Function(String value)? string,
    required TResult orElse(),
  }) {
    if (int != null) {
      return int(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptVariableValueBool value) bool,
    required TResult Function(ScriptVariableValueInt value) int,
    required TResult Function(ScriptVariableValueString value) string,
  }) {
    return int(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptVariableValueBool value)? bool,
    TResult? Function(ScriptVariableValueInt value)? int,
    TResult? Function(ScriptVariableValueString value)? string,
  }) {
    return int?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptVariableValueBool value)? bool,
    TResult Function(ScriptVariableValueInt value)? int,
    TResult Function(ScriptVariableValueString value)? string,
    required TResult orElse(),
  }) {
    if (int != null) {
      return int(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptVariableValueIntImplToJson(
      this,
    );
  }
}

abstract class ScriptVariableValueInt implements ScriptVariableValue {
  const factory ScriptVariableValueInt(final int value) =
      _$ScriptVariableValueIntImpl;

  factory ScriptVariableValueInt.fromJson(Map<String, dynamic> json) =
      _$ScriptVariableValueIntImpl.fromJson;

  @override
  int get value;

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptVariableValueIntImplCopyWith<_$ScriptVariableValueIntImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ScriptVariableValueStringImplCopyWith<$Res> {
  factory _$$ScriptVariableValueStringImplCopyWith(
          _$ScriptVariableValueStringImpl value,
          $Res Function(_$ScriptVariableValueStringImpl) then) =
      __$$ScriptVariableValueStringImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$ScriptVariableValueStringImplCopyWithImpl<$Res>
    extends _$ScriptVariableValueCopyWithImpl<$Res,
        _$ScriptVariableValueStringImpl>
    implements _$$ScriptVariableValueStringImplCopyWith<$Res> {
  __$$ScriptVariableValueStringImplCopyWithImpl(
      _$ScriptVariableValueStringImpl _value,
      $Res Function(_$ScriptVariableValueStringImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$ScriptVariableValueStringImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScriptVariableValueStringImpl implements ScriptVariableValueString {
  const _$ScriptVariableValueStringImpl(this.value, {final String? $type})
      : $type = $type ?? 'string';

  factory _$ScriptVariableValueStringImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptVariableValueStringImplFromJson(json);

  @override
  final String value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ScriptVariableValue.string(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptVariableValueStringImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptVariableValueStringImplCopyWith<_$ScriptVariableValueStringImpl>
      get copyWith => __$$ScriptVariableValueStringImplCopyWithImpl<
          _$ScriptVariableValueStringImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool value) bool,
    required TResult Function(int value) int,
    required TResult Function(String value) string,
  }) {
    return string(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool value)? bool,
    TResult? Function(int value)? int,
    TResult? Function(String value)? string,
  }) {
    return string?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool value)? bool,
    TResult Function(int value)? int,
    TResult Function(String value)? string,
    required TResult orElse(),
  }) {
    if (string != null) {
      return string(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptVariableValueBool value) bool,
    required TResult Function(ScriptVariableValueInt value) int,
    required TResult Function(ScriptVariableValueString value) string,
  }) {
    return string(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptVariableValueBool value)? bool,
    TResult? Function(ScriptVariableValueInt value)? int,
    TResult? Function(ScriptVariableValueString value)? string,
  }) {
    return string?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptVariableValueBool value)? bool,
    TResult Function(ScriptVariableValueInt value)? int,
    TResult Function(ScriptVariableValueString value)? string,
    required TResult orElse(),
  }) {
    if (string != null) {
      return string(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptVariableValueStringImplToJson(
      this,
    );
  }
}

abstract class ScriptVariableValueString implements ScriptVariableValue {
  const factory ScriptVariableValueString(final String value) =
      _$ScriptVariableValueStringImpl;

  factory ScriptVariableValueString.fromJson(Map<String, dynamic> json) =
      _$ScriptVariableValueStringImpl.fromJson;

  @override
  String get value;

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptVariableValueStringImplCopyWith<_$ScriptVariableValueStringImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ScriptVariables _$ScriptVariablesFromJson(Map<String, dynamic> json) {
  return _ScriptVariables.fromJson(json);
}

/// @nodoc
mixin _$ScriptVariables {
  Map<String, ScriptVariableValue> get values =>
      throw _privateConstructorUsedError;

  /// Serializes this ScriptVariables to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScriptVariablesCopyWith<ScriptVariables> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptVariablesCopyWith<$Res> {
  factory $ScriptVariablesCopyWith(
          ScriptVariables value, $Res Function(ScriptVariables) then) =
      _$ScriptVariablesCopyWithImpl<$Res, ScriptVariables>;
  @useResult
  $Res call({Map<String, ScriptVariableValue> values});
}

/// @nodoc
class _$ScriptVariablesCopyWithImpl<$Res, $Val extends ScriptVariables>
    implements $ScriptVariablesCopyWith<$Res> {
  _$ScriptVariablesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? values = null,
  }) {
    return _then(_value.copyWith(
      values: null == values
          ? _value.values
          : values // ignore: cast_nullable_to_non_nullable
              as Map<String, ScriptVariableValue>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScriptVariablesImplCopyWith<$Res>
    implements $ScriptVariablesCopyWith<$Res> {
  factory _$$ScriptVariablesImplCopyWith(_$ScriptVariablesImpl value,
          $Res Function(_$ScriptVariablesImpl) then) =
      __$$ScriptVariablesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, ScriptVariableValue> values});
}

/// @nodoc
class __$$ScriptVariablesImplCopyWithImpl<$Res>
    extends _$ScriptVariablesCopyWithImpl<$Res, _$ScriptVariablesImpl>
    implements _$$ScriptVariablesImplCopyWith<$Res> {
  __$$ScriptVariablesImplCopyWithImpl(
      _$ScriptVariablesImpl _value, $Res Function(_$ScriptVariablesImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? values = null,
  }) {
    return _then(_$ScriptVariablesImpl(
      values: null == values
          ? _value._values
          : values // ignore: cast_nullable_to_non_nullable
              as Map<String, ScriptVariableValue>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ScriptVariablesImpl implements _ScriptVariables {
  const _$ScriptVariablesImpl(
      {final Map<String, ScriptVariableValue> values = const {}})
      : _values = values;

  factory _$ScriptVariablesImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptVariablesImplFromJson(json);

  final Map<String, ScriptVariableValue> _values;
  @override
  @JsonKey()
  Map<String, ScriptVariableValue> get values {
    if (_values is EqualUnmodifiableMapView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_values);
  }

  @override
  String toString() {
    return 'ScriptVariables(values: $values)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptVariablesImpl &&
            const DeepCollectionEquality().equals(other._values, _values));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_values));

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptVariablesImplCopyWith<_$ScriptVariablesImpl> get copyWith =>
      __$$ScriptVariablesImplCopyWithImpl<_$ScriptVariablesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptVariablesImplToJson(
      this,
    );
  }
}

abstract class _ScriptVariables implements ScriptVariables {
  const factory _ScriptVariables(
      {final Map<String, ScriptVariableValue> values}) = _$ScriptVariablesImpl;

  factory _ScriptVariables.fromJson(Map<String, dynamic> json) =
      _$ScriptVariablesImpl.fromJson;

  @override
  Map<String, ScriptVariableValue> get values;

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptVariablesImplCopyWith<_$ScriptVariablesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoryFlags _$StoryFlagsFromJson(Map<String, dynamic> json) {
  return _StoryFlags.fromJson(json);
}

/// @nodoc
mixin _$StoryFlags {
  Set<String> get activeFlags => throw _privateConstructorUsedError;

  /// Serializes this StoryFlags to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoryFlagsCopyWith<StoryFlags> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoryFlagsCopyWith<$Res> {
  factory $StoryFlagsCopyWith(
          StoryFlags value, $Res Function(StoryFlags) then) =
      _$StoryFlagsCopyWithImpl<$Res, StoryFlags>;
  @useResult
  $Res call({Set<String> activeFlags});
}

/// @nodoc
class _$StoryFlagsCopyWithImpl<$Res, $Val extends StoryFlags>
    implements $StoryFlagsCopyWith<$Res> {
  _$StoryFlagsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeFlags = null,
  }) {
    return _then(_value.copyWith(
      activeFlags: null == activeFlags
          ? _value.activeFlags
          : activeFlags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoryFlagsImplCopyWith<$Res>
    implements $StoryFlagsCopyWith<$Res> {
  factory _$$StoryFlagsImplCopyWith(
          _$StoryFlagsImpl value, $Res Function(_$StoryFlagsImpl) then) =
      __$$StoryFlagsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Set<String> activeFlags});
}

/// @nodoc
class __$$StoryFlagsImplCopyWithImpl<$Res>
    extends _$StoryFlagsCopyWithImpl<$Res, _$StoryFlagsImpl>
    implements _$$StoryFlagsImplCopyWith<$Res> {
  __$$StoryFlagsImplCopyWithImpl(
      _$StoryFlagsImpl _value, $Res Function(_$StoryFlagsImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeFlags = null,
  }) {
    return _then(_$StoryFlagsImpl(
      activeFlags: null == activeFlags
          ? _value._activeFlags
          : activeFlags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoryFlagsImpl implements _StoryFlags {
  const _$StoryFlagsImpl({final Set<String> activeFlags = const {}})
      : _activeFlags = activeFlags;

  factory _$StoryFlagsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoryFlagsImplFromJson(json);

  final Set<String> _activeFlags;
  @override
  @JsonKey()
  Set<String> get activeFlags {
    if (_activeFlags is EqualUnmodifiableSetView) return _activeFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_activeFlags);
  }

  @override
  String toString() {
    return 'StoryFlags(activeFlags: $activeFlags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoryFlagsImpl &&
            const DeepCollectionEquality()
                .equals(other._activeFlags, _activeFlags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_activeFlags));

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoryFlagsImplCopyWith<_$StoryFlagsImpl> get copyWith =>
      __$$StoryFlagsImplCopyWithImpl<_$StoryFlagsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoryFlagsImplToJson(
      this,
    );
  }
}

abstract class _StoryFlags implements StoryFlags {
  const factory _StoryFlags({final Set<String> activeFlags}) = _$StoryFlagsImpl;

  factory _StoryFlags.fromJson(Map<String, dynamic> json) =
      _$StoryFlagsImpl.fromJson;

  @override
  Set<String> get activeFlags;

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoryFlagsImplCopyWith<_$StoryFlagsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GameState _$GameStateFromJson(Map<String, dynamic> json) {
  return _GameState.fromJson(json);
}

/// @nodoc
mixin _$GameState {
  /// Identifiant unique de la sauvegarde.
  String get saveId => throw _privateConstructorUsedError;

  /// Map actuelle du joueur.
  String get currentMapId => throw _privateConstructorUsedError;

  /// Position du joueur sur la map.
  GridPos get playerPosition => throw _privateConstructorUsedError;

  /// Orientation du joueur.
  EntityFacing get playerFacing => throw _privateConstructorUsedError;

  /// Mode de déplacement actuel (walk / surf).
  MovementMode get playerMovementMode => throw _privateConstructorUsedError;

  /// Équipe du joueur.
  PlayerParty get party => throw _privateConstructorUsedError;
  PokemonStorage get pokemonStorage => throw _privateConstructorUsedError;
  TrainerProfile get trainerProfile => throw _privateConstructorUsedError;
  Bag get bag => throw _privateConstructorUsedError;

  /// Progression narrative et capacités.
  PlayerProgression get progression => throw _privateConstructorUsedError;

  /// Variables de script (int/bool/string).
  ScriptVariables get scriptVariables => throw _privateConstructorUsedError;

  /// Flags narratifs (booléens).
  StoryFlags get storyFlags => throw _privateConstructorUsedError;

  /// IDs d'événements déjà consommés (objets ramassés, etc.).
  Set<String> get consumedEventIds => throw _privateConstructorUsedError;

  /// Métadonnées internes (timestamp, version, etc.).
  Map<String, String> get metadata => throw _privateConstructorUsedError;

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call(
      {String saveId,
      String currentMapId,
      GridPos playerPosition,
      EntityFacing playerFacing,
      MovementMode playerMovementMode,
      PlayerParty party,
      PokemonStorage pokemonStorage,
      TrainerProfile trainerProfile,
      Bag bag,
      PlayerProgression progression,
      ScriptVariables scriptVariables,
      StoryFlags storyFlags,
      Set<String> consumedEventIds,
      Map<String, String> metadata});

  $GridPosCopyWith<$Res> get playerPosition;
  $PlayerPartyCopyWith<$Res> get party;
  $PokemonStorageCopyWith<$Res> get pokemonStorage;
  $TrainerProfileCopyWith<$Res> get trainerProfile;
  $BagCopyWith<$Res> get bag;
  $PlayerProgressionCopyWith<$Res> get progression;
  $ScriptVariablesCopyWith<$Res> get scriptVariables;
  $StoryFlagsCopyWith<$Res> get storyFlags;
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saveId = null,
    Object? currentMapId = null,
    Object? playerPosition = null,
    Object? playerFacing = null,
    Object? playerMovementMode = null,
    Object? party = null,
    Object? pokemonStorage = null,
    Object? trainerProfile = null,
    Object? bag = null,
    Object? progression = null,
    Object? scriptVariables = null,
    Object? storyFlags = null,
    Object? consumedEventIds = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      saveId: null == saveId
          ? _value.saveId
          : saveId // ignore: cast_nullable_to_non_nullable
              as String,
      currentMapId: null == currentMapId
          ? _value.currentMapId
          : currentMapId // ignore: cast_nullable_to_non_nullable
              as String,
      playerPosition: null == playerPosition
          ? _value.playerPosition
          : playerPosition // ignore: cast_nullable_to_non_nullable
              as GridPos,
      playerFacing: null == playerFacing
          ? _value.playerFacing
          : playerFacing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      playerMovementMode: null == playerMovementMode
          ? _value.playerMovementMode
          : playerMovementMode // ignore: cast_nullable_to_non_nullable
              as MovementMode,
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PlayerParty,
      pokemonStorage: null == pokemonStorage
          ? _value.pokemonStorage
          : pokemonStorage // ignore: cast_nullable_to_non_nullable
              as PokemonStorage,
      trainerProfile: null == trainerProfile
          ? _value.trainerProfile
          : trainerProfile // ignore: cast_nullable_to_non_nullable
              as TrainerProfile,
      bag: null == bag
          ? _value.bag
          : bag // ignore: cast_nullable_to_non_nullable
              as Bag,
      progression: null == progression
          ? _value.progression
          : progression // ignore: cast_nullable_to_non_nullable
              as PlayerProgression,
      scriptVariables: null == scriptVariables
          ? _value.scriptVariables
          : scriptVariables // ignore: cast_nullable_to_non_nullable
              as ScriptVariables,
      storyFlags: null == storyFlags
          ? _value.storyFlags
          : storyFlags // ignore: cast_nullable_to_non_nullable
              as StoryFlags,
      consumedEventIds: null == consumedEventIds
          ? _value.consumedEventIds
          : consumedEventIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get playerPosition {
    return $GridPosCopyWith<$Res>(_value.playerPosition, (value) {
      return _then(_value.copyWith(playerPosition: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerPartyCopyWith<$Res> get party {
    return $PlayerPartyCopyWith<$Res>(_value.party, (value) {
      return _then(_value.copyWith(party: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PokemonStorageCopyWith<$Res> get pokemonStorage {
    return $PokemonStorageCopyWith<$Res>(_value.pokemonStorage, (value) {
      return _then(_value.copyWith(pokemonStorage: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TrainerProfileCopyWith<$Res> get trainerProfile {
    return $TrainerProfileCopyWith<$Res>(_value.trainerProfile, (value) {
      return _then(_value.copyWith(trainerProfile: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BagCopyWith<$Res> get bag {
    return $BagCopyWith<$Res>(_value.bag, (value) {
      return _then(_value.copyWith(bag: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerProgressionCopyWith<$Res> get progression {
    return $PlayerProgressionCopyWith<$Res>(_value.progression, (value) {
      return _then(_value.copyWith(progression: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptVariablesCopyWith<$Res> get scriptVariables {
    return $ScriptVariablesCopyWith<$Res>(_value.scriptVariables, (value) {
      return _then(_value.copyWith(scriptVariables: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoryFlagsCopyWith<$Res> get storyFlags {
    return $StoryFlagsCopyWith<$Res>(_value.storyFlags, (value) {
      return _then(_value.copyWith(storyFlags: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
          _$GameStateImpl value, $Res Function(_$GameStateImpl) then) =
      __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String saveId,
      String currentMapId,
      GridPos playerPosition,
      EntityFacing playerFacing,
      MovementMode playerMovementMode,
      PlayerParty party,
      PokemonStorage pokemonStorage,
      TrainerProfile trainerProfile,
      Bag bag,
      PlayerProgression progression,
      ScriptVariables scriptVariables,
      StoryFlags storyFlags,
      Set<String> consumedEventIds,
      Map<String, String> metadata});

  @override
  $GridPosCopyWith<$Res> get playerPosition;
  @override
  $PlayerPartyCopyWith<$Res> get party;
  @override
  $PokemonStorageCopyWith<$Res> get pokemonStorage;
  @override
  $TrainerProfileCopyWith<$Res> get trainerProfile;
  @override
  $BagCopyWith<$Res> get bag;
  @override
  $PlayerProgressionCopyWith<$Res> get progression;
  @override
  $ScriptVariablesCopyWith<$Res> get scriptVariables;
  @override
  $StoryFlagsCopyWith<$Res> get storyFlags;
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
      _$GameStateImpl _value, $Res Function(_$GameStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saveId = null,
    Object? currentMapId = null,
    Object? playerPosition = null,
    Object? playerFacing = null,
    Object? playerMovementMode = null,
    Object? party = null,
    Object? pokemonStorage = null,
    Object? trainerProfile = null,
    Object? bag = null,
    Object? progression = null,
    Object? scriptVariables = null,
    Object? storyFlags = null,
    Object? consumedEventIds = null,
    Object? metadata = null,
  }) {
    return _then(_$GameStateImpl(
      saveId: null == saveId
          ? _value.saveId
          : saveId // ignore: cast_nullable_to_non_nullable
              as String,
      currentMapId: null == currentMapId
          ? _value.currentMapId
          : currentMapId // ignore: cast_nullable_to_non_nullable
              as String,
      playerPosition: null == playerPosition
          ? _value.playerPosition
          : playerPosition // ignore: cast_nullable_to_non_nullable
              as GridPos,
      playerFacing: null == playerFacing
          ? _value.playerFacing
          : playerFacing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      playerMovementMode: null == playerMovementMode
          ? _value.playerMovementMode
          : playerMovementMode // ignore: cast_nullable_to_non_nullable
              as MovementMode,
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PlayerParty,
      pokemonStorage: null == pokemonStorage
          ? _value.pokemonStorage
          : pokemonStorage // ignore: cast_nullable_to_non_nullable
              as PokemonStorage,
      trainerProfile: null == trainerProfile
          ? _value.trainerProfile
          : trainerProfile // ignore: cast_nullable_to_non_nullable
              as TrainerProfile,
      bag: null == bag
          ? _value.bag
          : bag // ignore: cast_nullable_to_non_nullable
              as Bag,
      progression: null == progression
          ? _value.progression
          : progression // ignore: cast_nullable_to_non_nullable
              as PlayerProgression,
      scriptVariables: null == scriptVariables
          ? _value.scriptVariables
          : scriptVariables // ignore: cast_nullable_to_non_nullable
              as ScriptVariables,
      storyFlags: null == storyFlags
          ? _value.storyFlags
          : storyFlags // ignore: cast_nullable_to_non_nullable
              as StoryFlags,
      consumedEventIds: null == consumedEventIds
          ? _value._consumedEventIds
          : consumedEventIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$GameStateImpl implements _GameState {
  const _$GameStateImpl(
      {required this.saveId,
      this.currentMapId = '',
      this.playerPosition = const GridPos(x: 0, y: 0),
      this.playerFacing = EntityFacing.south,
      this.playerMovementMode = MovementMode.walk,
      this.party = const PlayerParty(),
      this.pokemonStorage = const PokemonStorage(),
      this.trainerProfile = const TrainerProfile(name: 'Player'),
      this.bag = const Bag(),
      this.progression = const PlayerProgression(),
      this.scriptVariables = const ScriptVariables(),
      this.storyFlags = const StoryFlags(),
      final Set<String> consumedEventIds = const {},
      final Map<String, String> metadata = const {}})
      : _consumedEventIds = consumedEventIds,
        _metadata = metadata;

  factory _$GameStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStateImplFromJson(json);

  /// Identifiant unique de la sauvegarde.
  @override
  final String saveId;

  /// Map actuelle du joueur.
  @override
  @JsonKey()
  final String currentMapId;

  /// Position du joueur sur la map.
  @override
  @JsonKey()
  final GridPos playerPosition;

  /// Orientation du joueur.
  @override
  @JsonKey()
  final EntityFacing playerFacing;

  /// Mode de déplacement actuel (walk / surf).
  @override
  @JsonKey()
  final MovementMode playerMovementMode;

  /// Équipe du joueur.
  @override
  @JsonKey()
  final PlayerParty party;
  @override
  @JsonKey()
  final PokemonStorage pokemonStorage;
  @override
  @JsonKey()
  final TrainerProfile trainerProfile;
  @override
  @JsonKey()
  final Bag bag;

  /// Progression narrative et capacités.
  @override
  @JsonKey()
  final PlayerProgression progression;

  /// Variables de script (int/bool/string).
  @override
  @JsonKey()
  final ScriptVariables scriptVariables;

  /// Flags narratifs (booléens).
  @override
  @JsonKey()
  final StoryFlags storyFlags;

  /// IDs d'événements déjà consommés (objets ramassés, etc.).
  final Set<String> _consumedEventIds;

  /// IDs d'événements déjà consommés (objets ramassés, etc.).
  @override
  @JsonKey()
  Set<String> get consumedEventIds {
    if (_consumedEventIds is EqualUnmodifiableSetView) return _consumedEventIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_consumedEventIds);
  }

  /// Métadonnées internes (timestamp, version, etc.).
  final Map<String, String> _metadata;

  /// Métadonnées internes (timestamp, version, etc.).
  @override
  @JsonKey()
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'GameState(saveId: $saveId, currentMapId: $currentMapId, playerPosition: $playerPosition, playerFacing: $playerFacing, playerMovementMode: $playerMovementMode, party: $party, pokemonStorage: $pokemonStorage, trainerProfile: $trainerProfile, bag: $bag, progression: $progression, scriptVariables: $scriptVariables, storyFlags: $storyFlags, consumedEventIds: $consumedEventIds, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.saveId, saveId) || other.saveId == saveId) &&
            (identical(other.currentMapId, currentMapId) ||
                other.currentMapId == currentMapId) &&
            (identical(other.playerPosition, playerPosition) ||
                other.playerPosition == playerPosition) &&
            (identical(other.playerFacing, playerFacing) ||
                other.playerFacing == playerFacing) &&
            (identical(other.playerMovementMode, playerMovementMode) ||
                other.playerMovementMode == playerMovementMode) &&
            (identical(other.party, party) || other.party == party) &&
            (identical(other.pokemonStorage, pokemonStorage) ||
                other.pokemonStorage == pokemonStorage) &&
            (identical(other.trainerProfile, trainerProfile) ||
                other.trainerProfile == trainerProfile) &&
            (identical(other.bag, bag) || other.bag == bag) &&
            (identical(other.progression, progression) ||
                other.progression == progression) &&
            (identical(other.scriptVariables, scriptVariables) ||
                other.scriptVariables == scriptVariables) &&
            (identical(other.storyFlags, storyFlags) ||
                other.storyFlags == storyFlags) &&
            const DeepCollectionEquality()
                .equals(other._consumedEventIds, _consumedEventIds) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      saveId,
      currentMapId,
      playerPosition,
      playerFacing,
      playerMovementMode,
      party,
      pokemonStorage,
      trainerProfile,
      bag,
      progression,
      scriptVariables,
      storyFlags,
      const DeepCollectionEquality().hash(_consumedEventIds),
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStateImplToJson(
      this,
    );
  }
}

abstract class _GameState implements GameState {
  const factory _GameState(
      {required final String saveId,
      final String currentMapId,
      final GridPos playerPosition,
      final EntityFacing playerFacing,
      final MovementMode playerMovementMode,
      final PlayerParty party,
      final PokemonStorage pokemonStorage,
      final TrainerProfile trainerProfile,
      final Bag bag,
      final PlayerProgression progression,
      final ScriptVariables scriptVariables,
      final StoryFlags storyFlags,
      final Set<String> consumedEventIds,
      final Map<String, String> metadata}) = _$GameStateImpl;

  factory _GameState.fromJson(Map<String, dynamic> json) =
      _$GameStateImpl.fromJson;

  /// Identifiant unique de la sauvegarde.
  @override
  String get saveId;

  /// Map actuelle du joueur.
  @override
  String get currentMapId;

  /// Position du joueur sur la map.
  @override
  GridPos get playerPosition;

  /// Orientation du joueur.
  @override
  EntityFacing get playerFacing;

  /// Mode de déplacement actuel (walk / surf).
  @override
  MovementMode get playerMovementMode;

  /// Équipe du joueur.
  @override
  PlayerParty get party;
  @override
  PokemonStorage get pokemonStorage;
  @override
  TrainerProfile get trainerProfile;
  @override
  Bag get bag;

  /// Progression narrative et capacités.
  @override
  PlayerProgression get progression;

  /// Variables de script (int/bool/string).
  @override
  ScriptVariables get scriptVariables;

  /// Flags narratifs (booléens).
  @override
  StoryFlags get storyFlags;

  /// IDs d'événements déjà consommés (objets ramassés, etc.).
  @override
  Set<String> get consumedEventIds;

  /// Métadonnées internes (timestamp, version, etc.).
  @override
  Map<String, String> get metadata;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
