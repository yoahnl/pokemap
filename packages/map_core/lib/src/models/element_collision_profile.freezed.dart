// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'element_collision_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ElementCollisionProfile _$ElementCollisionProfileFromJson(
    Map<String, dynamic> json) {
  return _ElementCollisionProfile.fromJson(json);
}

/// @nodoc
mixin _$ElementCollisionProfile {
  ElementCollisionProfileSource get source =>
      throw _privateConstructorUsedError;
  WarpTriggerPadding get padding =>
      throw _privateConstructorUsedError; // Runtime truth: the gameplay/runtime layers only read these final cells.
// Editor-only concepts such as base cells or paint modes must be resolved
// before data reaches this field.
  List<GridPos> get cells =>
      throw _privateConstructorUsedError; // Authoring intent: cells explicitly added on top of the base shape derived
// from padding. Keeping this intent lets the editor recompute `cells`
// deterministically whenever padding changes.
  List<GridPos> get manualAddedCells =>
      throw _privateConstructorUsedError; // Authoring intent: cells explicitly removed from the base shape derived
// from padding. Runtime ignores this field; the editor folds it into
// `cells` before save/use.
  List<GridPos> get manualRemovedCells => throw _privateConstructorUsedError;

  /// Serializes this ElementCollisionProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ElementCollisionProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ElementCollisionProfileCopyWith<ElementCollisionProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ElementCollisionProfileCopyWith<$Res> {
  factory $ElementCollisionProfileCopyWith(ElementCollisionProfile value,
          $Res Function(ElementCollisionProfile) then) =
      _$ElementCollisionProfileCopyWithImpl<$Res, ElementCollisionProfile>;
  @useResult
  $Res call(
      {ElementCollisionProfileSource source,
      WarpTriggerPadding padding,
      List<GridPos> cells,
      List<GridPos> manualAddedCells,
      List<GridPos> manualRemovedCells});

  $WarpTriggerPaddingCopyWith<$Res> get padding;
}

/// @nodoc
class _$ElementCollisionProfileCopyWithImpl<$Res,
        $Val extends ElementCollisionProfile>
    implements $ElementCollisionProfileCopyWith<$Res> {
  _$ElementCollisionProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ElementCollisionProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? padding = null,
    Object? cells = null,
    Object? manualAddedCells = null,
    Object? manualRemovedCells = null,
  }) {
    return _then(_value.copyWith(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ElementCollisionProfileSource,
      padding: null == padding
          ? _value.padding
          : padding // ignore: cast_nullable_to_non_nullable
              as WarpTriggerPadding,
      cells: null == cells
          ? _value.cells
          : cells // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
      manualAddedCells: null == manualAddedCells
          ? _value.manualAddedCells
          : manualAddedCells // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
      manualRemovedCells: null == manualRemovedCells
          ? _value.manualRemovedCells
          : manualRemovedCells // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
    ) as $Val);
  }

  /// Create a copy of ElementCollisionProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WarpTriggerPaddingCopyWith<$Res> get padding {
    return $WarpTriggerPaddingCopyWith<$Res>(_value.padding, (value) {
      return _then(_value.copyWith(padding: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ElementCollisionProfileImplCopyWith<$Res>
    implements $ElementCollisionProfileCopyWith<$Res> {
  factory _$$ElementCollisionProfileImplCopyWith(
          _$ElementCollisionProfileImpl value,
          $Res Function(_$ElementCollisionProfileImpl) then) =
      __$$ElementCollisionProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ElementCollisionProfileSource source,
      WarpTriggerPadding padding,
      List<GridPos> cells,
      List<GridPos> manualAddedCells,
      List<GridPos> manualRemovedCells});

  @override
  $WarpTriggerPaddingCopyWith<$Res> get padding;
}

/// @nodoc
class __$$ElementCollisionProfileImplCopyWithImpl<$Res>
    extends _$ElementCollisionProfileCopyWithImpl<$Res,
        _$ElementCollisionProfileImpl>
    implements _$$ElementCollisionProfileImplCopyWith<$Res> {
  __$$ElementCollisionProfileImplCopyWithImpl(
      _$ElementCollisionProfileImpl _value,
      $Res Function(_$ElementCollisionProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ElementCollisionProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? padding = null,
    Object? cells = null,
    Object? manualAddedCells = null,
    Object? manualRemovedCells = null,
  }) {
    return _then(_$ElementCollisionProfileImpl(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ElementCollisionProfileSource,
      padding: null == padding
          ? _value.padding
          : padding // ignore: cast_nullable_to_non_nullable
              as WarpTriggerPadding,
      cells: null == cells
          ? _value._cells
          : cells // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
      manualAddedCells: null == manualAddedCells
          ? _value._manualAddedCells
          : manualAddedCells // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
      manualRemovedCells: null == manualRemovedCells
          ? _value._manualRemovedCells
          : manualRemovedCells // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ElementCollisionProfileImpl implements _ElementCollisionProfile {
  const _$ElementCollisionProfileImpl(
      {this.source = ElementCollisionProfileSource.generated,
      this.padding = const WarpTriggerPadding(),
      final List<GridPos> cells = const [],
      final List<GridPos> manualAddedCells = const [],
      final List<GridPos> manualRemovedCells = const []})
      : _cells = cells,
        _manualAddedCells = manualAddedCells,
        _manualRemovedCells = manualRemovedCells;

  factory _$ElementCollisionProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ElementCollisionProfileImplFromJson(json);

  @override
  @JsonKey()
  final ElementCollisionProfileSource source;
  @override
  @JsonKey()
  final WarpTriggerPadding padding;
// Runtime truth: the gameplay/runtime layers only read these final cells.
// Editor-only concepts such as base cells or paint modes must be resolved
// before data reaches this field.
  final List<GridPos> _cells;
// Runtime truth: the gameplay/runtime layers only read these final cells.
// Editor-only concepts such as base cells or paint modes must be resolved
// before data reaches this field.
  @override
  @JsonKey()
  List<GridPos> get cells {
    if (_cells is EqualUnmodifiableListView) return _cells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cells);
  }

// Authoring intent: cells explicitly added on top of the base shape derived
// from padding. Keeping this intent lets the editor recompute `cells`
// deterministically whenever padding changes.
  final List<GridPos> _manualAddedCells;
// Authoring intent: cells explicitly added on top of the base shape derived
// from padding. Keeping this intent lets the editor recompute `cells`
// deterministically whenever padding changes.
  @override
  @JsonKey()
  List<GridPos> get manualAddedCells {
    if (_manualAddedCells is EqualUnmodifiableListView)
      return _manualAddedCells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_manualAddedCells);
  }

// Authoring intent: cells explicitly removed from the base shape derived
// from padding. Runtime ignores this field; the editor folds it into
// `cells` before save/use.
  final List<GridPos> _manualRemovedCells;
// Authoring intent: cells explicitly removed from the base shape derived
// from padding. Runtime ignores this field; the editor folds it into
// `cells` before save/use.
  @override
  @JsonKey()
  List<GridPos> get manualRemovedCells {
    if (_manualRemovedCells is EqualUnmodifiableListView)
      return _manualRemovedCells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_manualRemovedCells);
  }

  @override
  String toString() {
    return 'ElementCollisionProfile(source: $source, padding: $padding, cells: $cells, manualAddedCells: $manualAddedCells, manualRemovedCells: $manualRemovedCells)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ElementCollisionProfileImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.padding, padding) || other.padding == padding) &&
            const DeepCollectionEquality().equals(other._cells, _cells) &&
            const DeepCollectionEquality()
                .equals(other._manualAddedCells, _manualAddedCells) &&
            const DeepCollectionEquality()
                .equals(other._manualRemovedCells, _manualRemovedCells));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      source,
      padding,
      const DeepCollectionEquality().hash(_cells),
      const DeepCollectionEquality().hash(_manualAddedCells),
      const DeepCollectionEquality().hash(_manualRemovedCells));

  /// Create a copy of ElementCollisionProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ElementCollisionProfileImplCopyWith<_$ElementCollisionProfileImpl>
      get copyWith => __$$ElementCollisionProfileImplCopyWithImpl<
          _$ElementCollisionProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ElementCollisionProfileImplToJson(
      this,
    );
  }
}

abstract class _ElementCollisionProfile implements ElementCollisionProfile {
  const factory _ElementCollisionProfile(
      {final ElementCollisionProfileSource source,
      final WarpTriggerPadding padding,
      final List<GridPos> cells,
      final List<GridPos> manualAddedCells,
      final List<GridPos> manualRemovedCells}) = _$ElementCollisionProfileImpl;

  factory _ElementCollisionProfile.fromJson(Map<String, dynamic> json) =
      _$ElementCollisionProfileImpl.fromJson;

  @override
  ElementCollisionProfileSource get source;
  @override
  WarpTriggerPadding
      get padding; // Runtime truth: the gameplay/runtime layers only read these final cells.
// Editor-only concepts such as base cells or paint modes must be resolved
// before data reaches this field.
  @override
  List<GridPos>
      get cells; // Authoring intent: cells explicitly added on top of the base shape derived
// from padding. Keeping this intent lets the editor recompute `cells`
// deterministically whenever padding changes.
  @override
  List<GridPos>
      get manualAddedCells; // Authoring intent: cells explicitly removed from the base shape derived
// from padding. Runtime ignores this field; the editor folds it into
// `cells` before save/use.
  @override
  List<GridPos> get manualRemovedCells;

  /// Create a copy of ElementCollisionProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ElementCollisionProfileImplCopyWith<_$ElementCollisionProfileImpl>
      get copyWith => throw _privateConstructorUsedError;
}
