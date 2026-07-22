// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'badge_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BadgeDefinition _$BadgeDefinitionFromJson(Map<String, dynamic> json) {
  return _BadgeDefinition.fromJson(json);
}

/// @nodoc
mixin _$BadgeDefinition {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String? get iconRelativePath => throw _privateConstructorUsedError;
  FieldAbility? get fieldAbilityUnlock => throw _privateConstructorUsedError;

  /// Serializes this BadgeDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BadgeDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BadgeDefinitionCopyWith<BadgeDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BadgeDefinitionCopyWith<$Res> {
  factory $BadgeDefinitionCopyWith(
          BadgeDefinition value, $Res Function(BadgeDefinition) then) =
      _$BadgeDefinitionCopyWithImpl<$Res, BadgeDefinition>;
  @useResult
  $Res call(
      {String id,
      String label,
      String? iconRelativePath,
      FieldAbility? fieldAbilityUnlock});
}

/// @nodoc
class _$BadgeDefinitionCopyWithImpl<$Res, $Val extends BadgeDefinition>
    implements $BadgeDefinitionCopyWith<$Res> {
  _$BadgeDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BadgeDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? iconRelativePath = freezed,
    Object? fieldAbilityUnlock = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      iconRelativePath: freezed == iconRelativePath
          ? _value.iconRelativePath
          : iconRelativePath // ignore: cast_nullable_to_non_nullable
              as String?,
      fieldAbilityUnlock: freezed == fieldAbilityUnlock
          ? _value.fieldAbilityUnlock
          : fieldAbilityUnlock // ignore: cast_nullable_to_non_nullable
              as FieldAbility?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BadgeDefinitionImplCopyWith<$Res>
    implements $BadgeDefinitionCopyWith<$Res> {
  factory _$$BadgeDefinitionImplCopyWith(_$BadgeDefinitionImpl value,
          $Res Function(_$BadgeDefinitionImpl) then) =
      __$$BadgeDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      String? iconRelativePath,
      FieldAbility? fieldAbilityUnlock});
}

/// @nodoc
class __$$BadgeDefinitionImplCopyWithImpl<$Res>
    extends _$BadgeDefinitionCopyWithImpl<$Res, _$BadgeDefinitionImpl>
    implements _$$BadgeDefinitionImplCopyWith<$Res> {
  __$$BadgeDefinitionImplCopyWithImpl(
      _$BadgeDefinitionImpl _value, $Res Function(_$BadgeDefinitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of BadgeDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? iconRelativePath = freezed,
    Object? fieldAbilityUnlock = freezed,
  }) {
    return _then(_$BadgeDefinitionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      iconRelativePath: freezed == iconRelativePath
          ? _value.iconRelativePath
          : iconRelativePath // ignore: cast_nullable_to_non_nullable
              as String?,
      fieldAbilityUnlock: freezed == fieldAbilityUnlock
          ? _value.fieldAbilityUnlock
          : fieldAbilityUnlock // ignore: cast_nullable_to_non_nullable
              as FieldAbility?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BadgeDefinitionImpl extends _BadgeDefinition {
  const _$BadgeDefinitionImpl(
      {required this.id,
      required this.label,
      this.iconRelativePath,
      this.fieldAbilityUnlock})
      : super._();

  factory _$BadgeDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$BadgeDefinitionImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final String? iconRelativePath;
  @override
  final FieldAbility? fieldAbilityUnlock;

  @override
  String toString() {
    return 'BadgeDefinition(id: $id, label: $label, iconRelativePath: $iconRelativePath, fieldAbilityUnlock: $fieldAbilityUnlock)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BadgeDefinitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.iconRelativePath, iconRelativePath) ||
                other.iconRelativePath == iconRelativePath) &&
            (identical(other.fieldAbilityUnlock, fieldAbilityUnlock) ||
                other.fieldAbilityUnlock == fieldAbilityUnlock));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, label, iconRelativePath, fieldAbilityUnlock);

  /// Create a copy of BadgeDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BadgeDefinitionImplCopyWith<_$BadgeDefinitionImpl> get copyWith =>
      __$$BadgeDefinitionImplCopyWithImpl<_$BadgeDefinitionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BadgeDefinitionImplToJson(
      this,
    );
  }
}

abstract class _BadgeDefinition extends BadgeDefinition {
  const factory _BadgeDefinition(
      {required final String id,
      required final String label,
      final String? iconRelativePath,
      final FieldAbility? fieldAbilityUnlock}) = _$BadgeDefinitionImpl;
  const _BadgeDefinition._() : super._();

  factory _BadgeDefinition.fromJson(Map<String, dynamic> json) =
      _$BadgeDefinitionImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  String? get iconRelativePath;
  @override
  FieldAbility? get fieldAbilityUnlock;

  /// Create a copy of BadgeDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BadgeDefinitionImplCopyWith<_$BadgeDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
