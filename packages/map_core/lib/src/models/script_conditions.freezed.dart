// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'script_conditions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScriptCondition _$ScriptConditionFromJson(Map<String, dynamic> json) {
  return _ScriptCondition.fromJson(json);
}

/// @nodoc
mixin _$ScriptCondition {
  ScriptConditionType get type => throw _privateConstructorUsedError;

  /// Paramètres de la condition (dépend du type).
  Map<String, String> get params => throw _privateConstructorUsedError;

  /// Sous-conditions pour allOf/anyOf/not.
  List<ScriptCondition> get children => throw _privateConstructorUsedError;

  /// Serializes this ScriptCondition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScriptCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScriptConditionCopyWith<ScriptCondition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptConditionCopyWith<$Res> {
  factory $ScriptConditionCopyWith(
          ScriptCondition value, $Res Function(ScriptCondition) then) =
      _$ScriptConditionCopyWithImpl<$Res, ScriptCondition>;
  @useResult
  $Res call(
      {ScriptConditionType type,
      Map<String, String> params,
      List<ScriptCondition> children});
}

/// @nodoc
class _$ScriptConditionCopyWithImpl<$Res, $Val extends ScriptCondition>
    implements $ScriptConditionCopyWith<$Res> {
  _$ScriptConditionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? params = null,
    Object? children = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ScriptConditionType,
      params: null == params
          ? _value.params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      children: null == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as List<ScriptCondition>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScriptConditionImplCopyWith<$Res>
    implements $ScriptConditionCopyWith<$Res> {
  factory _$$ScriptConditionImplCopyWith(_$ScriptConditionImpl value,
          $Res Function(_$ScriptConditionImpl) then) =
      __$$ScriptConditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ScriptConditionType type,
      Map<String, String> params,
      List<ScriptCondition> children});
}

/// @nodoc
class __$$ScriptConditionImplCopyWithImpl<$Res>
    extends _$ScriptConditionCopyWithImpl<$Res, _$ScriptConditionImpl>
    implements _$$ScriptConditionImplCopyWith<$Res> {
  __$$ScriptConditionImplCopyWithImpl(
      _$ScriptConditionImpl _value, $Res Function(_$ScriptConditionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? params = null,
    Object? children = null,
  }) {
    return _then(_$ScriptConditionImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ScriptConditionType,
      params: null == params
          ? _value._params
          : params // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      children: null == children
          ? _value._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<ScriptCondition>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ScriptConditionImpl implements _ScriptCondition {
  const _$ScriptConditionImpl(
      {required this.type,
      final Map<String, String> params = const {},
      final List<ScriptCondition> children = const []})
      : _params = params,
        _children = children;

  factory _$ScriptConditionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptConditionImplFromJson(json);

  @override
  final ScriptConditionType type;

  /// Paramètres de la condition (dépend du type).
  final Map<String, String> _params;

  /// Paramètres de la condition (dépend du type).
  @override
  @JsonKey()
  Map<String, String> get params {
    if (_params is EqualUnmodifiableMapView) return _params;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_params);
  }

  /// Sous-conditions pour allOf/anyOf/not.
  final List<ScriptCondition> _children;

  /// Sous-conditions pour allOf/anyOf/not.
  @override
  @JsonKey()
  List<ScriptCondition> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  @override
  String toString() {
    return 'ScriptCondition(type: $type, params: $params, children: $children)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptConditionImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._params, _params) &&
            const DeepCollectionEquality().equals(other._children, _children));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      const DeepCollectionEquality().hash(_params),
      const DeepCollectionEquality().hash(_children));

  /// Create a copy of ScriptCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptConditionImplCopyWith<_$ScriptConditionImpl> get copyWith =>
      __$$ScriptConditionImplCopyWithImpl<_$ScriptConditionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptConditionImplToJson(
      this,
    );
  }
}

abstract class _ScriptCondition implements ScriptCondition {
  const factory _ScriptCondition(
      {required final ScriptConditionType type,
      final Map<String, String> params,
      final List<ScriptCondition> children}) = _$ScriptConditionImpl;

  factory _ScriptCondition.fromJson(Map<String, dynamic> json) =
      _$ScriptConditionImpl.fromJson;

  @override
  ScriptConditionType get type;

  /// Paramètres de la condition (dépend du type).
  @override
  Map<String, String> get params;

  /// Sous-conditions pour allOf/anyOf/not.
  @override
  List<ScriptCondition> get children;

  /// Create a copy of ScriptCondition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptConditionImplCopyWith<_$ScriptConditionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
