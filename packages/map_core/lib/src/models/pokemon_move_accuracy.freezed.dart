// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pokemon_move_accuracy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PokemonMoveAccuracy _$PokemonMoveAccuracyFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'percent':
      return PokemonMoveAccuracyPercent.fromJson(json);
    case 'always_hits':
      return PokemonMoveAccuracyAlwaysHits.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'kind', 'PokemonMoveAccuracy',
          'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$PokemonMoveAccuracy {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int value) percent,
    required TResult Function() alwaysHits,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int value)? percent,
    TResult? Function()? alwaysHits,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int value)? percent,
    TResult Function()? alwaysHits,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveAccuracyPercent value) percent,
    required TResult Function(PokemonMoveAccuracyAlwaysHits value) alwaysHits,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveAccuracyPercent value)? percent,
    TResult? Function(PokemonMoveAccuracyAlwaysHits value)? alwaysHits,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveAccuracyPercent value)? percent,
    TResult Function(PokemonMoveAccuracyAlwaysHits value)? alwaysHits,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this PokemonMoveAccuracy to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonMoveAccuracyCopyWith<$Res> {
  factory $PokemonMoveAccuracyCopyWith(
          PokemonMoveAccuracy value, $Res Function(PokemonMoveAccuracy) then) =
      _$PokemonMoveAccuracyCopyWithImpl<$Res, PokemonMoveAccuracy>;
}

/// @nodoc
class _$PokemonMoveAccuracyCopyWithImpl<$Res, $Val extends PokemonMoveAccuracy>
    implements $PokemonMoveAccuracyCopyWith<$Res> {
  _$PokemonMoveAccuracyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonMoveAccuracy
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PokemonMoveAccuracyPercentImplCopyWith<$Res> {
  factory _$$PokemonMoveAccuracyPercentImplCopyWith(
          _$PokemonMoveAccuracyPercentImpl value,
          $Res Function(_$PokemonMoveAccuracyPercentImpl) then) =
      __$$PokemonMoveAccuracyPercentImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int value});
}

/// @nodoc
class __$$PokemonMoveAccuracyPercentImplCopyWithImpl<$Res>
    extends _$PokemonMoveAccuracyCopyWithImpl<$Res,
        _$PokemonMoveAccuracyPercentImpl>
    implements _$$PokemonMoveAccuracyPercentImplCopyWith<$Res> {
  __$$PokemonMoveAccuracyPercentImplCopyWithImpl(
      _$PokemonMoveAccuracyPercentImpl _value,
      $Res Function(_$PokemonMoveAccuracyPercentImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveAccuracy
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$PokemonMoveAccuracyPercentImpl(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveAccuracyPercentImpl extends PokemonMoveAccuracyPercent {
  const _$PokemonMoveAccuracyPercentImpl(
      {required this.value, final String? $type})
      : $type = $type ?? 'percent',
        super._();

  factory _$PokemonMoveAccuracyPercentImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveAccuracyPercentImplFromJson(json);

  @override
  final int value;

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveAccuracy.percent(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveAccuracyPercentImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of PokemonMoveAccuracy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveAccuracyPercentImplCopyWith<_$PokemonMoveAccuracyPercentImpl>
      get copyWith => __$$PokemonMoveAccuracyPercentImplCopyWithImpl<
          _$PokemonMoveAccuracyPercentImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int value) percent,
    required TResult Function() alwaysHits,
  }) {
    return percent(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int value)? percent,
    TResult? Function()? alwaysHits,
  }) {
    return percent?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int value)? percent,
    TResult Function()? alwaysHits,
    required TResult orElse(),
  }) {
    if (percent != null) {
      return percent(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveAccuracyPercent value) percent,
    required TResult Function(PokemonMoveAccuracyAlwaysHits value) alwaysHits,
  }) {
    return percent(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveAccuracyPercent value)? percent,
    TResult? Function(PokemonMoveAccuracyAlwaysHits value)? alwaysHits,
  }) {
    return percent?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveAccuracyPercent value)? percent,
    TResult Function(PokemonMoveAccuracyAlwaysHits value)? alwaysHits,
    required TResult orElse(),
  }) {
    if (percent != null) {
      return percent(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveAccuracyPercentImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveAccuracyPercent extends PokemonMoveAccuracy {
  const factory PokemonMoveAccuracyPercent({required final int value}) =
      _$PokemonMoveAccuracyPercentImpl;
  const PokemonMoveAccuracyPercent._() : super._();

  factory PokemonMoveAccuracyPercent.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveAccuracyPercentImpl.fromJson;

  int get value;

  /// Create a copy of PokemonMoveAccuracy
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveAccuracyPercentImplCopyWith<_$PokemonMoveAccuracyPercentImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PokemonMoveAccuracyAlwaysHitsImplCopyWith<$Res> {
  factory _$$PokemonMoveAccuracyAlwaysHitsImplCopyWith(
          _$PokemonMoveAccuracyAlwaysHitsImpl value,
          $Res Function(_$PokemonMoveAccuracyAlwaysHitsImpl) then) =
      __$$PokemonMoveAccuracyAlwaysHitsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PokemonMoveAccuracyAlwaysHitsImplCopyWithImpl<$Res>
    extends _$PokemonMoveAccuracyCopyWithImpl<$Res,
        _$PokemonMoveAccuracyAlwaysHitsImpl>
    implements _$$PokemonMoveAccuracyAlwaysHitsImplCopyWith<$Res> {
  __$$PokemonMoveAccuracyAlwaysHitsImplCopyWithImpl(
      _$PokemonMoveAccuracyAlwaysHitsImpl _value,
      $Res Function(_$PokemonMoveAccuracyAlwaysHitsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveAccuracy
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveAccuracyAlwaysHitsImpl
    extends PokemonMoveAccuracyAlwaysHits {
  const _$PokemonMoveAccuracyAlwaysHitsImpl({final String? $type})
      : $type = $type ?? 'always_hits',
        super._();

  factory _$PokemonMoveAccuracyAlwaysHitsImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$PokemonMoveAccuracyAlwaysHitsImplFromJson(json);

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'PokemonMoveAccuracy.alwaysHits()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveAccuracyAlwaysHitsImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int value) percent,
    required TResult Function() alwaysHits,
  }) {
    return alwaysHits();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int value)? percent,
    TResult? Function()? alwaysHits,
  }) {
    return alwaysHits?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int value)? percent,
    TResult Function()? alwaysHits,
    required TResult orElse(),
  }) {
    if (alwaysHits != null) {
      return alwaysHits();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PokemonMoveAccuracyPercent value) percent,
    required TResult Function(PokemonMoveAccuracyAlwaysHits value) alwaysHits,
  }) {
    return alwaysHits(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PokemonMoveAccuracyPercent value)? percent,
    TResult? Function(PokemonMoveAccuracyAlwaysHits value)? alwaysHits,
  }) {
    return alwaysHits?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PokemonMoveAccuracyPercent value)? percent,
    TResult Function(PokemonMoveAccuracyAlwaysHits value)? alwaysHits,
    required TResult orElse(),
  }) {
    if (alwaysHits != null) {
      return alwaysHits(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveAccuracyAlwaysHitsImplToJson(
      this,
    );
  }
}

abstract class PokemonMoveAccuracyAlwaysHits extends PokemonMoveAccuracy {
  const factory PokemonMoveAccuracyAlwaysHits() =
      _$PokemonMoveAccuracyAlwaysHitsImpl;
  const PokemonMoveAccuracyAlwaysHits._() : super._();

  factory PokemonMoveAccuracyAlwaysHits.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveAccuracyAlwaysHitsImpl.fromJson;
}
