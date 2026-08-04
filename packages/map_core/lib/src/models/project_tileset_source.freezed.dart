// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_tileset_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VisualTileProperty _$VisualTilePropertyFromJson(Map<String, dynamic> json) {
  return _VisualTileProperty.fromJson(json);
}

/// @nodoc
mixin _$VisualTileProperty {
  int get tileId => throw _privateConstructorUsedError;
  bool get passable => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this VisualTileProperty to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VisualTilePropertyCopyWith<VisualTileProperty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisualTilePropertyCopyWith<$Res> {
  factory $VisualTilePropertyCopyWith(
          VisualTileProperty value, $Res Function(VisualTileProperty) then) =
      _$VisualTilePropertyCopyWithImpl<$Res, VisualTileProperty>;
  @useResult
  $Res call({int tileId, bool passable, List<String> tags});
}

/// @nodoc
class _$VisualTilePropertyCopyWithImpl<$Res, $Val extends VisualTileProperty>
    implements $VisualTilePropertyCopyWith<$Res> {
  _$VisualTilePropertyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? passable = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      passable: null == passable
          ? _value.passable
          : passable // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VisualTilePropertyImplCopyWith<$Res>
    implements $VisualTilePropertyCopyWith<$Res> {
  factory _$$VisualTilePropertyImplCopyWith(_$VisualTilePropertyImpl value,
          $Res Function(_$VisualTilePropertyImpl) then) =
      __$$VisualTilePropertyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int tileId, bool passable, List<String> tags});
}

/// @nodoc
class __$$VisualTilePropertyImplCopyWithImpl<$Res>
    extends _$VisualTilePropertyCopyWithImpl<$Res, _$VisualTilePropertyImpl>
    implements _$$VisualTilePropertyImplCopyWith<$Res> {
  __$$VisualTilePropertyImplCopyWithImpl(_$VisualTilePropertyImpl _value,
      $Res Function(_$VisualTilePropertyImpl) _then)
      : super(_value, _then);

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? passable = null,
    Object? tags = null,
  }) {
    return _then(_$VisualTilePropertyImpl(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      passable: null == passable
          ? _value.passable
          : passable // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VisualTilePropertyImpl implements _VisualTileProperty {
  const _$VisualTilePropertyImpl(
      {required this.tileId,
      this.passable = true,
      final List<String> tags = const <String>[]})
      : _tags = tags;

  factory _$VisualTilePropertyImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisualTilePropertyImplFromJson(json);

  @override
  final int tileId;
  @override
  @JsonKey()
  final bool passable;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'VisualTileProperty(tileId: $tileId, passable: $passable, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisualTilePropertyImpl &&
            (identical(other.tileId, tileId) || other.tileId == tileId) &&
            (identical(other.passable, passable) ||
                other.passable == passable) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tileId, passable,
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VisualTilePropertyImplCopyWith<_$VisualTilePropertyImpl> get copyWith =>
      __$$VisualTilePropertyImplCopyWithImpl<_$VisualTilePropertyImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisualTilePropertyImplToJson(
      this,
    );
  }
}

abstract class _VisualTileProperty implements VisualTileProperty {
  const factory _VisualTileProperty(
      {required final int tileId,
      final bool passable,
      final List<String> tags}) = _$VisualTilePropertyImpl;

  factory _VisualTileProperty.fromJson(Map<String, dynamic> json) =
      _$VisualTilePropertyImpl.fromJson;

  @override
  int get tileId;
  @override
  bool get passable;
  @override
  List<String> get tags;

  /// Create a copy of VisualTileProperty
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VisualTilePropertyImplCopyWith<_$VisualTilePropertyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
