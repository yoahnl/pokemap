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

ElementCollisionPixelMask _$ElementCollisionPixelMaskFromJson(
    Map<String, dynamic> json) {
  return _ElementCollisionPixelMask.fromJson(json);
}

/// @nodoc
mixin _$ElementCollisionPixelMask {
  int get widthPx => throw _privateConstructorUsedError;
  int get heightPx => throw _privateConstructorUsedError;
  ElementCollisionMaskEncoding get encoding =>
      throw _privateConstructorUsedError;
  String get dataBase64 => throw _privateConstructorUsedError;

  /// Serializes this ElementCollisionPixelMask to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ElementCollisionPixelMask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ElementCollisionPixelMaskCopyWith<ElementCollisionPixelMask> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ElementCollisionPixelMaskCopyWith<$Res> {
  factory $ElementCollisionPixelMaskCopyWith(ElementCollisionPixelMask value,
          $Res Function(ElementCollisionPixelMask) then) =
      _$ElementCollisionPixelMaskCopyWithImpl<$Res, ElementCollisionPixelMask>;
  @useResult
  $Res call(
      {int widthPx,
      int heightPx,
      ElementCollisionMaskEncoding encoding,
      String dataBase64});
}

/// @nodoc
class _$ElementCollisionPixelMaskCopyWithImpl<$Res,
        $Val extends ElementCollisionPixelMask>
    implements $ElementCollisionPixelMaskCopyWith<$Res> {
  _$ElementCollisionPixelMaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ElementCollisionPixelMask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? widthPx = null,
    Object? heightPx = null,
    Object? encoding = null,
    Object? dataBase64 = null,
  }) {
    return _then(_value.copyWith(
      widthPx: null == widthPx
          ? _value.widthPx
          : widthPx // ignore: cast_nullable_to_non_nullable
              as int,
      heightPx: null == heightPx
          ? _value.heightPx
          : heightPx // ignore: cast_nullable_to_non_nullable
              as int,
      encoding: null == encoding
          ? _value.encoding
          : encoding // ignore: cast_nullable_to_non_nullable
              as ElementCollisionMaskEncoding,
      dataBase64: null == dataBase64
          ? _value.dataBase64
          : dataBase64 // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ElementCollisionPixelMaskImplCopyWith<$Res>
    implements $ElementCollisionPixelMaskCopyWith<$Res> {
  factory _$$ElementCollisionPixelMaskImplCopyWith(
          _$ElementCollisionPixelMaskImpl value,
          $Res Function(_$ElementCollisionPixelMaskImpl) then) =
      __$$ElementCollisionPixelMaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int widthPx,
      int heightPx,
      ElementCollisionMaskEncoding encoding,
      String dataBase64});
}

/// @nodoc
class __$$ElementCollisionPixelMaskImplCopyWithImpl<$Res>
    extends _$ElementCollisionPixelMaskCopyWithImpl<$Res,
        _$ElementCollisionPixelMaskImpl>
    implements _$$ElementCollisionPixelMaskImplCopyWith<$Res> {
  __$$ElementCollisionPixelMaskImplCopyWithImpl(
      _$ElementCollisionPixelMaskImpl _value,
      $Res Function(_$ElementCollisionPixelMaskImpl) _then)
      : super(_value, _then);

  /// Create a copy of ElementCollisionPixelMask
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? widthPx = null,
    Object? heightPx = null,
    Object? encoding = null,
    Object? dataBase64 = null,
  }) {
    return _then(_$ElementCollisionPixelMaskImpl(
      widthPx: null == widthPx
          ? _value.widthPx
          : widthPx // ignore: cast_nullable_to_non_nullable
              as int,
      heightPx: null == heightPx
          ? _value.heightPx
          : heightPx // ignore: cast_nullable_to_non_nullable
              as int,
      encoding: null == encoding
          ? _value.encoding
          : encoding // ignore: cast_nullable_to_non_nullable
              as ElementCollisionMaskEncoding,
      dataBase64: null == dataBase64
          ? _value.dataBase64
          : dataBase64 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ElementCollisionPixelMaskImpl implements _ElementCollisionPixelMask {
  const _$ElementCollisionPixelMaskImpl(
      {required this.widthPx,
      required this.heightPx,
      this.encoding = ElementCollisionMaskEncoding.packedBitsV1,
      this.dataBase64 = ''});

  factory _$ElementCollisionPixelMaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$ElementCollisionPixelMaskImplFromJson(json);

  @override
  final int widthPx;
  @override
  final int heightPx;
  @override
  @JsonKey()
  final ElementCollisionMaskEncoding encoding;
  @override
  @JsonKey()
  final String dataBase64;

  @override
  String toString() {
    return 'ElementCollisionPixelMask(widthPx: $widthPx, heightPx: $heightPx, encoding: $encoding, dataBase64: $dataBase64)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ElementCollisionPixelMaskImpl &&
            (identical(other.widthPx, widthPx) || other.widthPx == widthPx) &&
            (identical(other.heightPx, heightPx) ||
                other.heightPx == heightPx) &&
            (identical(other.encoding, encoding) ||
                other.encoding == encoding) &&
            (identical(other.dataBase64, dataBase64) ||
                other.dataBase64 == dataBase64));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, widthPx, heightPx, encoding, dataBase64);

  /// Create a copy of ElementCollisionPixelMask
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ElementCollisionPixelMaskImplCopyWith<_$ElementCollisionPixelMaskImpl>
      get copyWith => __$$ElementCollisionPixelMaskImplCopyWithImpl<
          _$ElementCollisionPixelMaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ElementCollisionPixelMaskImplToJson(
      this,
    );
  }
}

abstract class _ElementCollisionPixelMask implements ElementCollisionPixelMask {
  const factory _ElementCollisionPixelMask(
      {required final int widthPx,
      required final int heightPx,
      final ElementCollisionMaskEncoding encoding,
      final String dataBase64}) = _$ElementCollisionPixelMaskImpl;

  factory _ElementCollisionPixelMask.fromJson(Map<String, dynamic> json) =
      _$ElementCollisionPixelMaskImpl.fromJson;

  @override
  int get widthPx;
  @override
  int get heightPx;
  @override
  ElementCollisionMaskEncoding get encoding;
  @override
  String get dataBase64;

  /// Create a copy of ElementCollisionPixelMask
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ElementCollisionPixelMaskImplCopyWith<_$ElementCollisionPixelMaskImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ElementCollisionProfile _$ElementCollisionProfileFromJson(
    Map<String, dynamic> json) {
  return _ElementCollisionProfile.fromJson(json);
}

/// @nodoc
mixin _$ElementCollisionProfile {
  ElementCollisionProfileSource get source =>
      throw _privateConstructorUsedError;
  ElementCollisionPixelMask? get visualMask =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'pixelMask')
  ElementCollisionPixelMask? get collisionMask =>
      throw _privateConstructorUsedError;
  ElementCollisionPixelMask? get occlusionMask =>
      throw _privateConstructorUsedError;
  WarpTriggerPadding get padding =>
      throw _privateConstructorUsedError; // Authoring base when `source == manual`.
//
// This field is editor-facing only. It stores the main collision shape as
// authored by the user (for example a lasso/polygon around a building).
//
// Important product invariant:
// - when this manual shape exists, it is the primary collision base
// - padding stays available as a secondary helper only
// - runtime still ignores this field and consumes only `cells`
  List<GridPos> get shapeCells =>
      throw _privateConstructorUsedError; // Runtime truth: the gameplay/runtime layers only read these final cells.
// Editor-only concepts such as base cells or paint modes must be resolved
// before data reaches this field.
  List<GridPos> get cells =>
      throw _privateConstructorUsedError; // Authoring intent: cells explicitly added on top of the current primary
// base.
//
// That base is:
// - the padding-derived rectangle when `source == generated`
// - the author polygon/shape when `source == manual`
  List<GridPos> get manualAddedCells =>
      throw _privateConstructorUsedError; // Authoring intent: cells explicitly removed from the current primary base.
// Runtime ignores this field; the editor folds it into `cells` before
// save/use.
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
      ElementCollisionPixelMask? visualMask,
      @JsonKey(name: 'pixelMask') ElementCollisionPixelMask? collisionMask,
      ElementCollisionPixelMask? occlusionMask,
      WarpTriggerPadding padding,
      List<GridPos> shapeCells,
      List<GridPos> cells,
      List<GridPos> manualAddedCells,
      List<GridPos> manualRemovedCells});

  $ElementCollisionPixelMaskCopyWith<$Res>? get visualMask;
  $ElementCollisionPixelMaskCopyWith<$Res>? get collisionMask;
  $ElementCollisionPixelMaskCopyWith<$Res>? get occlusionMask;
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
    Object? visualMask = freezed,
    Object? collisionMask = freezed,
    Object? occlusionMask = freezed,
    Object? padding = null,
    Object? shapeCells = null,
    Object? cells = null,
    Object? manualAddedCells = null,
    Object? manualRemovedCells = null,
  }) {
    return _then(_value.copyWith(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ElementCollisionProfileSource,
      visualMask: freezed == visualMask
          ? _value.visualMask
          : visualMask // ignore: cast_nullable_to_non_nullable
              as ElementCollisionPixelMask?,
      collisionMask: freezed == collisionMask
          ? _value.collisionMask
          : collisionMask // ignore: cast_nullable_to_non_nullable
              as ElementCollisionPixelMask?,
      occlusionMask: freezed == occlusionMask
          ? _value.occlusionMask
          : occlusionMask // ignore: cast_nullable_to_non_nullable
              as ElementCollisionPixelMask?,
      padding: null == padding
          ? _value.padding
          : padding // ignore: cast_nullable_to_non_nullable
              as WarpTriggerPadding,
      shapeCells: null == shapeCells
          ? _value.shapeCells
          : shapeCells // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
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
  $ElementCollisionPixelMaskCopyWith<$Res>? get visualMask {
    if (_value.visualMask == null) {
      return null;
    }

    return $ElementCollisionPixelMaskCopyWith<$Res>(_value.visualMask!,
        (value) {
      return _then(_value.copyWith(visualMask: value) as $Val);
    });
  }

  /// Create a copy of ElementCollisionProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ElementCollisionPixelMaskCopyWith<$Res>? get collisionMask {
    if (_value.collisionMask == null) {
      return null;
    }

    return $ElementCollisionPixelMaskCopyWith<$Res>(_value.collisionMask!,
        (value) {
      return _then(_value.copyWith(collisionMask: value) as $Val);
    });
  }

  /// Create a copy of ElementCollisionProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ElementCollisionPixelMaskCopyWith<$Res>? get occlusionMask {
    if (_value.occlusionMask == null) {
      return null;
    }

    return $ElementCollisionPixelMaskCopyWith<$Res>(_value.occlusionMask!,
        (value) {
      return _then(_value.copyWith(occlusionMask: value) as $Val);
    });
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
      ElementCollisionPixelMask? visualMask,
      @JsonKey(name: 'pixelMask') ElementCollisionPixelMask? collisionMask,
      ElementCollisionPixelMask? occlusionMask,
      WarpTriggerPadding padding,
      List<GridPos> shapeCells,
      List<GridPos> cells,
      List<GridPos> manualAddedCells,
      List<GridPos> manualRemovedCells});

  @override
  $ElementCollisionPixelMaskCopyWith<$Res>? get visualMask;
  @override
  $ElementCollisionPixelMaskCopyWith<$Res>? get collisionMask;
  @override
  $ElementCollisionPixelMaskCopyWith<$Res>? get occlusionMask;
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
    Object? visualMask = freezed,
    Object? collisionMask = freezed,
    Object? occlusionMask = freezed,
    Object? padding = null,
    Object? shapeCells = null,
    Object? cells = null,
    Object? manualAddedCells = null,
    Object? manualRemovedCells = null,
  }) {
    return _then(_$ElementCollisionProfileImpl(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as ElementCollisionProfileSource,
      visualMask: freezed == visualMask
          ? _value.visualMask
          : visualMask // ignore: cast_nullable_to_non_nullable
              as ElementCollisionPixelMask?,
      collisionMask: freezed == collisionMask
          ? _value.collisionMask
          : collisionMask // ignore: cast_nullable_to_non_nullable
              as ElementCollisionPixelMask?,
      occlusionMask: freezed == occlusionMask
          ? _value.occlusionMask
          : occlusionMask // ignore: cast_nullable_to_non_nullable
              as ElementCollisionPixelMask?,
      padding: null == padding
          ? _value.padding
          : padding // ignore: cast_nullable_to_non_nullable
              as WarpTriggerPadding,
      shapeCells: null == shapeCells
          ? _value._shapeCells
          : shapeCells // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
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
      this.visualMask,
      @JsonKey(name: 'pixelMask') this.collisionMask,
      this.occlusionMask,
      this.padding = const WarpTriggerPadding(),
      final List<GridPos> shapeCells = const [],
      final List<GridPos> cells = const [],
      final List<GridPos> manualAddedCells = const [],
      final List<GridPos> manualRemovedCells = const []})
      : _shapeCells = shapeCells,
        _cells = cells,
        _manualAddedCells = manualAddedCells,
        _manualRemovedCells = manualRemovedCells;

  factory _$ElementCollisionProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ElementCollisionProfileImplFromJson(json);

  @override
  @JsonKey()
  final ElementCollisionProfileSource source;
  @override
  final ElementCollisionPixelMask? visualMask;
  @override
  @JsonKey(name: 'pixelMask')
  final ElementCollisionPixelMask? collisionMask;
  @override
  final ElementCollisionPixelMask? occlusionMask;
  @override
  @JsonKey()
  final WarpTriggerPadding padding;
// Authoring base when `source == manual`.
//
// This field is editor-facing only. It stores the main collision shape as
// authored by the user (for example a lasso/polygon around a building).
//
// Important product invariant:
// - when this manual shape exists, it is the primary collision base
// - padding stays available as a secondary helper only
// - runtime still ignores this field and consumes only `cells`
  final List<GridPos> _shapeCells;
// Authoring base when `source == manual`.
//
// This field is editor-facing only. It stores the main collision shape as
// authored by the user (for example a lasso/polygon around a building).
//
// Important product invariant:
// - when this manual shape exists, it is the primary collision base
// - padding stays available as a secondary helper only
// - runtime still ignores this field and consumes only `cells`
  @override
  @JsonKey()
  List<GridPos> get shapeCells {
    if (_shapeCells is EqualUnmodifiableListView) return _shapeCells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_shapeCells);
  }

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

// Authoring intent: cells explicitly added on top of the current primary
// base.
//
// That base is:
// - the padding-derived rectangle when `source == generated`
// - the author polygon/shape when `source == manual`
  final List<GridPos> _manualAddedCells;
// Authoring intent: cells explicitly added on top of the current primary
// base.
//
// That base is:
// - the padding-derived rectangle when `source == generated`
// - the author polygon/shape when `source == manual`
  @override
  @JsonKey()
  List<GridPos> get manualAddedCells {
    if (_manualAddedCells is EqualUnmodifiableListView)
      return _manualAddedCells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_manualAddedCells);
  }

// Authoring intent: cells explicitly removed from the current primary base.
// Runtime ignores this field; the editor folds it into `cells` before
// save/use.
  final List<GridPos> _manualRemovedCells;
// Authoring intent: cells explicitly removed from the current primary base.
// Runtime ignores this field; the editor folds it into `cells` before
// save/use.
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
    return 'ElementCollisionProfile(source: $source, visualMask: $visualMask, collisionMask: $collisionMask, occlusionMask: $occlusionMask, padding: $padding, shapeCells: $shapeCells, cells: $cells, manualAddedCells: $manualAddedCells, manualRemovedCells: $manualRemovedCells)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ElementCollisionProfileImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.visualMask, visualMask) ||
                other.visualMask == visualMask) &&
            (identical(other.collisionMask, collisionMask) ||
                other.collisionMask == collisionMask) &&
            (identical(other.occlusionMask, occlusionMask) ||
                other.occlusionMask == occlusionMask) &&
            (identical(other.padding, padding) || other.padding == padding) &&
            const DeepCollectionEquality()
                .equals(other._shapeCells, _shapeCells) &&
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
      visualMask,
      collisionMask,
      occlusionMask,
      padding,
      const DeepCollectionEquality().hash(_shapeCells),
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
      final ElementCollisionPixelMask? visualMask,
      @JsonKey(name: 'pixelMask')
      final ElementCollisionPixelMask? collisionMask,
      final ElementCollisionPixelMask? occlusionMask,
      final WarpTriggerPadding padding,
      final List<GridPos> shapeCells,
      final List<GridPos> cells,
      final List<GridPos> manualAddedCells,
      final List<GridPos> manualRemovedCells}) = _$ElementCollisionProfileImpl;

  factory _ElementCollisionProfile.fromJson(Map<String, dynamic> json) =
      _$ElementCollisionProfileImpl.fromJson;

  @override
  ElementCollisionProfileSource get source;
  @override
  ElementCollisionPixelMask? get visualMask;
  @override
  @JsonKey(name: 'pixelMask')
  ElementCollisionPixelMask? get collisionMask;
  @override
  ElementCollisionPixelMask? get occlusionMask;
  @override
  WarpTriggerPadding get padding; // Authoring base when `source == manual`.
//
// This field is editor-facing only. It stores the main collision shape as
// authored by the user (for example a lasso/polygon around a building).
//
// Important product invariant:
// - when this manual shape exists, it is the primary collision base
// - padding stays available as a secondary helper only
// - runtime still ignores this field and consumes only `cells`
  @override
  List<GridPos>
      get shapeCells; // Runtime truth: the gameplay/runtime layers only read these final cells.
// Editor-only concepts such as base cells or paint modes must be resolved
// before data reaches this field.
  @override
  List<GridPos>
      get cells; // Authoring intent: cells explicitly added on top of the current primary
// base.
//
// That base is:
// - the padding-derived rectangle when `source == generated`
// - the author polygon/shape when `source == manual`
  @override
  List<GridPos>
      get manualAddedCells; // Authoring intent: cells explicitly removed from the current primary base.
// Runtime ignores this field; the editor folds it into `cells` before
// save/use.
  @override
  List<GridPos> get manualRemovedCells;

  /// Create a copy of ElementCollisionProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ElementCollisionProfileImplCopyWith<_$ElementCollisionProfileImpl>
      get copyWith => throw _privateConstructorUsedError;
}
