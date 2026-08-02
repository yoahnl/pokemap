// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'smart_tile_field.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SmartTileField _$SmartTileFieldFromJson(Map<String, dynamic> json) {
  switch (json['kind']) {
    case 'cell':
      return SmartTileCellField.fromJson(json);
    case 'corner':
      return SmartTileCornerField.fromJson(json);
    case 'edge':
      return SmartTileEdgeField.fromJson(json);
    case 'mixed':
      return SmartTileMixedField.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'kind', 'SmartTileField',
          'Invalid union type "${json['kind']}"!');
  }
}

/// @nodoc
mixin _$SmartTileField {
  List<int> get semanticCells => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<int> semanticCells) cell,
    required TResult Function(List<int> semanticCells, List<int> corners)
        corner,
    required TResult Function(List<int> semanticCells,
            List<int> horizontalEdges, List<int> verticalEdges)
        edge,
    required TResult Function(
            List<int> semanticCells,
            List<int> horizontalEdges,
            List<int> verticalEdges,
            List<int> corners)
        mixed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<int> semanticCells)? cell,
    TResult? Function(List<int> semanticCells, List<int> corners)? corner,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<int> semanticCells)? cell,
    TResult Function(List<int> semanticCells, List<int> corners)? corner,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SmartTileCellField value) cell,
    required TResult Function(SmartTileCornerField value) corner,
    required TResult Function(SmartTileEdgeField value) edge,
    required TResult Function(SmartTileMixedField value) mixed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SmartTileCellField value)? cell,
    TResult? Function(SmartTileCornerField value)? corner,
    TResult? Function(SmartTileEdgeField value)? edge,
    TResult? Function(SmartTileMixedField value)? mixed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SmartTileCellField value)? cell,
    TResult Function(SmartTileCornerField value)? corner,
    TResult Function(SmartTileEdgeField value)? edge,
    TResult Function(SmartTileMixedField value)? mixed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this SmartTileField to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SmartTileFieldCopyWith<SmartTileField> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SmartTileFieldCopyWith<$Res> {
  factory $SmartTileFieldCopyWith(
          SmartTileField value, $Res Function(SmartTileField) then) =
      _$SmartTileFieldCopyWithImpl<$Res, SmartTileField>;
  @useResult
  $Res call({List<int> semanticCells});
}

/// @nodoc
class _$SmartTileFieldCopyWithImpl<$Res, $Val extends SmartTileField>
    implements $SmartTileFieldCopyWith<$Res> {
  _$SmartTileFieldCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? semanticCells = null,
  }) {
    return _then(_value.copyWith(
      semanticCells: null == semanticCells
          ? _value.semanticCells
          : semanticCells // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SmartTileCellFieldImplCopyWith<$Res>
    implements $SmartTileFieldCopyWith<$Res> {
  factory _$$SmartTileCellFieldImplCopyWith(_$SmartTileCellFieldImpl value,
          $Res Function(_$SmartTileCellFieldImpl) then) =
      __$$SmartTileCellFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<int> semanticCells});
}

/// @nodoc
class __$$SmartTileCellFieldImplCopyWithImpl<$Res>
    extends _$SmartTileFieldCopyWithImpl<$Res, _$SmartTileCellFieldImpl>
    implements _$$SmartTileCellFieldImplCopyWith<$Res> {
  __$$SmartTileCellFieldImplCopyWithImpl(_$SmartTileCellFieldImpl _value,
      $Res Function(_$SmartTileCellFieldImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? semanticCells = null,
  }) {
    return _then(_$SmartTileCellFieldImpl(
      semanticCells: null == semanticCells
          ? _value._semanticCells
          : semanticCells // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SmartTileCellFieldImpl implements SmartTileCellField {
  const _$SmartTileCellFieldImpl(
      {final List<int> semanticCells = const <int>[], final String? $type})
      : _semanticCells = semanticCells,
        $type = $type ?? 'cell';

  factory _$SmartTileCellFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileCellFieldImplFromJson(json);

  final List<int> _semanticCells;
  @override
  @JsonKey()
  List<int> get semanticCells {
    if (_semanticCells is EqualUnmodifiableListView) return _semanticCells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_semanticCells);
  }

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'SmartTileField.cell(semanticCells: $semanticCells)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileCellFieldImpl &&
            const DeepCollectionEquality()
                .equals(other._semanticCells, _semanticCells));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_semanticCells));

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileCellFieldImplCopyWith<_$SmartTileCellFieldImpl> get copyWith =>
      __$$SmartTileCellFieldImplCopyWithImpl<_$SmartTileCellFieldImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<int> semanticCells) cell,
    required TResult Function(List<int> semanticCells, List<int> corners)
        corner,
    required TResult Function(List<int> semanticCells,
            List<int> horizontalEdges, List<int> verticalEdges)
        edge,
    required TResult Function(
            List<int> semanticCells,
            List<int> horizontalEdges,
            List<int> verticalEdges,
            List<int> corners)
        mixed,
  }) {
    return cell(semanticCells);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<int> semanticCells)? cell,
    TResult? Function(List<int> semanticCells, List<int> corners)? corner,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
  }) {
    return cell?.call(semanticCells);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<int> semanticCells)? cell,
    TResult Function(List<int> semanticCells, List<int> corners)? corner,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
    required TResult orElse(),
  }) {
    if (cell != null) {
      return cell(semanticCells);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SmartTileCellField value) cell,
    required TResult Function(SmartTileCornerField value) corner,
    required TResult Function(SmartTileEdgeField value) edge,
    required TResult Function(SmartTileMixedField value) mixed,
  }) {
    return cell(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SmartTileCellField value)? cell,
    TResult? Function(SmartTileCornerField value)? corner,
    TResult? Function(SmartTileEdgeField value)? edge,
    TResult? Function(SmartTileMixedField value)? mixed,
  }) {
    return cell?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SmartTileCellField value)? cell,
    TResult Function(SmartTileCornerField value)? corner,
    TResult Function(SmartTileEdgeField value)? edge,
    TResult Function(SmartTileMixedField value)? mixed,
    required TResult orElse(),
  }) {
    if (cell != null) {
      return cell(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileCellFieldImplToJson(
      this,
    );
  }
}

abstract class SmartTileCellField implements SmartTileField {
  const factory SmartTileCellField({final List<int> semanticCells}) =
      _$SmartTileCellFieldImpl;

  factory SmartTileCellField.fromJson(Map<String, dynamic> json) =
      _$SmartTileCellFieldImpl.fromJson;

  @override
  List<int> get semanticCells;

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileCellFieldImplCopyWith<_$SmartTileCellFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SmartTileCornerFieldImplCopyWith<$Res>
    implements $SmartTileFieldCopyWith<$Res> {
  factory _$$SmartTileCornerFieldImplCopyWith(_$SmartTileCornerFieldImpl value,
          $Res Function(_$SmartTileCornerFieldImpl) then) =
      __$$SmartTileCornerFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<int> semanticCells, List<int> corners});
}

/// @nodoc
class __$$SmartTileCornerFieldImplCopyWithImpl<$Res>
    extends _$SmartTileFieldCopyWithImpl<$Res, _$SmartTileCornerFieldImpl>
    implements _$$SmartTileCornerFieldImplCopyWith<$Res> {
  __$$SmartTileCornerFieldImplCopyWithImpl(_$SmartTileCornerFieldImpl _value,
      $Res Function(_$SmartTileCornerFieldImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? semanticCells = null,
    Object? corners = null,
  }) {
    return _then(_$SmartTileCornerFieldImpl(
      semanticCells: null == semanticCells
          ? _value._semanticCells
          : semanticCells // ignore: cast_nullable_to_non_nullable
              as List<int>,
      corners: null == corners
          ? _value._corners
          : corners // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SmartTileCornerFieldImpl implements SmartTileCornerField {
  const _$SmartTileCornerFieldImpl(
      {final List<int> semanticCells = const <int>[],
      final List<int> corners = const <int>[],
      final String? $type})
      : _semanticCells = semanticCells,
        _corners = corners,
        $type = $type ?? 'corner';

  factory _$SmartTileCornerFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileCornerFieldImplFromJson(json);

  final List<int> _semanticCells;
  @override
  @JsonKey()
  List<int> get semanticCells {
    if (_semanticCells is EqualUnmodifiableListView) return _semanticCells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_semanticCells);
  }

  final List<int> _corners;
  @override
  @JsonKey()
  List<int> get corners {
    if (_corners is EqualUnmodifiableListView) return _corners;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_corners);
  }

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'SmartTileField.corner(semanticCells: $semanticCells, corners: $corners)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileCornerFieldImpl &&
            const DeepCollectionEquality()
                .equals(other._semanticCells, _semanticCells) &&
            const DeepCollectionEquality().equals(other._corners, _corners));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_semanticCells),
      const DeepCollectionEquality().hash(_corners));

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileCornerFieldImplCopyWith<_$SmartTileCornerFieldImpl>
      get copyWith =>
          __$$SmartTileCornerFieldImplCopyWithImpl<_$SmartTileCornerFieldImpl>(
              this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<int> semanticCells) cell,
    required TResult Function(List<int> semanticCells, List<int> corners)
        corner,
    required TResult Function(List<int> semanticCells,
            List<int> horizontalEdges, List<int> verticalEdges)
        edge,
    required TResult Function(
            List<int> semanticCells,
            List<int> horizontalEdges,
            List<int> verticalEdges,
            List<int> corners)
        mixed,
  }) {
    return corner(semanticCells, corners);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<int> semanticCells)? cell,
    TResult? Function(List<int> semanticCells, List<int> corners)? corner,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
  }) {
    return corner?.call(semanticCells, corners);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<int> semanticCells)? cell,
    TResult Function(List<int> semanticCells, List<int> corners)? corner,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
    required TResult orElse(),
  }) {
    if (corner != null) {
      return corner(semanticCells, corners);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SmartTileCellField value) cell,
    required TResult Function(SmartTileCornerField value) corner,
    required TResult Function(SmartTileEdgeField value) edge,
    required TResult Function(SmartTileMixedField value) mixed,
  }) {
    return corner(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SmartTileCellField value)? cell,
    TResult? Function(SmartTileCornerField value)? corner,
    TResult? Function(SmartTileEdgeField value)? edge,
    TResult? Function(SmartTileMixedField value)? mixed,
  }) {
    return corner?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SmartTileCellField value)? cell,
    TResult Function(SmartTileCornerField value)? corner,
    TResult Function(SmartTileEdgeField value)? edge,
    TResult Function(SmartTileMixedField value)? mixed,
    required TResult orElse(),
  }) {
    if (corner != null) {
      return corner(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileCornerFieldImplToJson(
      this,
    );
  }
}

abstract class SmartTileCornerField implements SmartTileField {
  const factory SmartTileCornerField(
      {final List<int> semanticCells,
      final List<int> corners}) = _$SmartTileCornerFieldImpl;

  factory SmartTileCornerField.fromJson(Map<String, dynamic> json) =
      _$SmartTileCornerFieldImpl.fromJson;

  @override
  List<int> get semanticCells;
  List<int> get corners;

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileCornerFieldImplCopyWith<_$SmartTileCornerFieldImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SmartTileEdgeFieldImplCopyWith<$Res>
    implements $SmartTileFieldCopyWith<$Res> {
  factory _$$SmartTileEdgeFieldImplCopyWith(_$SmartTileEdgeFieldImpl value,
          $Res Function(_$SmartTileEdgeFieldImpl) then) =
      __$$SmartTileEdgeFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<int> semanticCells,
      List<int> horizontalEdges,
      List<int> verticalEdges});
}

/// @nodoc
class __$$SmartTileEdgeFieldImplCopyWithImpl<$Res>
    extends _$SmartTileFieldCopyWithImpl<$Res, _$SmartTileEdgeFieldImpl>
    implements _$$SmartTileEdgeFieldImplCopyWith<$Res> {
  __$$SmartTileEdgeFieldImplCopyWithImpl(_$SmartTileEdgeFieldImpl _value,
      $Res Function(_$SmartTileEdgeFieldImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? semanticCells = null,
    Object? horizontalEdges = null,
    Object? verticalEdges = null,
  }) {
    return _then(_$SmartTileEdgeFieldImpl(
      semanticCells: null == semanticCells
          ? _value._semanticCells
          : semanticCells // ignore: cast_nullable_to_non_nullable
              as List<int>,
      horizontalEdges: null == horizontalEdges
          ? _value._horizontalEdges
          : horizontalEdges // ignore: cast_nullable_to_non_nullable
              as List<int>,
      verticalEdges: null == verticalEdges
          ? _value._verticalEdges
          : verticalEdges // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SmartTileEdgeFieldImpl implements SmartTileEdgeField {
  const _$SmartTileEdgeFieldImpl(
      {final List<int> semanticCells = const <int>[],
      final List<int> horizontalEdges = const <int>[],
      final List<int> verticalEdges = const <int>[],
      final String? $type})
      : _semanticCells = semanticCells,
        _horizontalEdges = horizontalEdges,
        _verticalEdges = verticalEdges,
        $type = $type ?? 'edge';

  factory _$SmartTileEdgeFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileEdgeFieldImplFromJson(json);

  final List<int> _semanticCells;
  @override
  @JsonKey()
  List<int> get semanticCells {
    if (_semanticCells is EqualUnmodifiableListView) return _semanticCells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_semanticCells);
  }

  final List<int> _horizontalEdges;
  @override
  @JsonKey()
  List<int> get horizontalEdges {
    if (_horizontalEdges is EqualUnmodifiableListView) return _horizontalEdges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_horizontalEdges);
  }

  final List<int> _verticalEdges;
  @override
  @JsonKey()
  List<int> get verticalEdges {
    if (_verticalEdges is EqualUnmodifiableListView) return _verticalEdges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_verticalEdges);
  }

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'SmartTileField.edge(semanticCells: $semanticCells, horizontalEdges: $horizontalEdges, verticalEdges: $verticalEdges)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileEdgeFieldImpl &&
            const DeepCollectionEquality()
                .equals(other._semanticCells, _semanticCells) &&
            const DeepCollectionEquality()
                .equals(other._horizontalEdges, _horizontalEdges) &&
            const DeepCollectionEquality()
                .equals(other._verticalEdges, _verticalEdges));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_semanticCells),
      const DeepCollectionEquality().hash(_horizontalEdges),
      const DeepCollectionEquality().hash(_verticalEdges));

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileEdgeFieldImplCopyWith<_$SmartTileEdgeFieldImpl> get copyWith =>
      __$$SmartTileEdgeFieldImplCopyWithImpl<_$SmartTileEdgeFieldImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<int> semanticCells) cell,
    required TResult Function(List<int> semanticCells, List<int> corners)
        corner,
    required TResult Function(List<int> semanticCells,
            List<int> horizontalEdges, List<int> verticalEdges)
        edge,
    required TResult Function(
            List<int> semanticCells,
            List<int> horizontalEdges,
            List<int> verticalEdges,
            List<int> corners)
        mixed,
  }) {
    return edge(semanticCells, horizontalEdges, verticalEdges);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<int> semanticCells)? cell,
    TResult? Function(List<int> semanticCells, List<int> corners)? corner,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
  }) {
    return edge?.call(semanticCells, horizontalEdges, verticalEdges);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<int> semanticCells)? cell,
    TResult Function(List<int> semanticCells, List<int> corners)? corner,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
    required TResult orElse(),
  }) {
    if (edge != null) {
      return edge(semanticCells, horizontalEdges, verticalEdges);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SmartTileCellField value) cell,
    required TResult Function(SmartTileCornerField value) corner,
    required TResult Function(SmartTileEdgeField value) edge,
    required TResult Function(SmartTileMixedField value) mixed,
  }) {
    return edge(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SmartTileCellField value)? cell,
    TResult? Function(SmartTileCornerField value)? corner,
    TResult? Function(SmartTileEdgeField value)? edge,
    TResult? Function(SmartTileMixedField value)? mixed,
  }) {
    return edge?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SmartTileCellField value)? cell,
    TResult Function(SmartTileCornerField value)? corner,
    TResult Function(SmartTileEdgeField value)? edge,
    TResult Function(SmartTileMixedField value)? mixed,
    required TResult orElse(),
  }) {
    if (edge != null) {
      return edge(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileEdgeFieldImplToJson(
      this,
    );
  }
}

abstract class SmartTileEdgeField implements SmartTileField {
  const factory SmartTileEdgeField(
      {final List<int> semanticCells,
      final List<int> horizontalEdges,
      final List<int> verticalEdges}) = _$SmartTileEdgeFieldImpl;

  factory SmartTileEdgeField.fromJson(Map<String, dynamic> json) =
      _$SmartTileEdgeFieldImpl.fromJson;

  @override
  List<int> get semanticCells;
  List<int> get horizontalEdges;
  List<int> get verticalEdges;

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileEdgeFieldImplCopyWith<_$SmartTileEdgeFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SmartTileMixedFieldImplCopyWith<$Res>
    implements $SmartTileFieldCopyWith<$Res> {
  factory _$$SmartTileMixedFieldImplCopyWith(_$SmartTileMixedFieldImpl value,
          $Res Function(_$SmartTileMixedFieldImpl) then) =
      __$$SmartTileMixedFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<int> semanticCells,
      List<int> horizontalEdges,
      List<int> verticalEdges,
      List<int> corners});
}

/// @nodoc
class __$$SmartTileMixedFieldImplCopyWithImpl<$Res>
    extends _$SmartTileFieldCopyWithImpl<$Res, _$SmartTileMixedFieldImpl>
    implements _$$SmartTileMixedFieldImplCopyWith<$Res> {
  __$$SmartTileMixedFieldImplCopyWithImpl(_$SmartTileMixedFieldImpl _value,
      $Res Function(_$SmartTileMixedFieldImpl) _then)
      : super(_value, _then);

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? semanticCells = null,
    Object? horizontalEdges = null,
    Object? verticalEdges = null,
    Object? corners = null,
  }) {
    return _then(_$SmartTileMixedFieldImpl(
      semanticCells: null == semanticCells
          ? _value._semanticCells
          : semanticCells // ignore: cast_nullable_to_non_nullable
              as List<int>,
      horizontalEdges: null == horizontalEdges
          ? _value._horizontalEdges
          : horizontalEdges // ignore: cast_nullable_to_non_nullable
              as List<int>,
      verticalEdges: null == verticalEdges
          ? _value._verticalEdges
          : verticalEdges // ignore: cast_nullable_to_non_nullable
              as List<int>,
      corners: null == corners
          ? _value._corners
          : corners // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SmartTileMixedFieldImpl implements SmartTileMixedField {
  const _$SmartTileMixedFieldImpl(
      {final List<int> semanticCells = const <int>[],
      final List<int> horizontalEdges = const <int>[],
      final List<int> verticalEdges = const <int>[],
      final List<int> corners = const <int>[],
      final String? $type})
      : _semanticCells = semanticCells,
        _horizontalEdges = horizontalEdges,
        _verticalEdges = verticalEdges,
        _corners = corners,
        $type = $type ?? 'mixed';

  factory _$SmartTileMixedFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$SmartTileMixedFieldImplFromJson(json);

  final List<int> _semanticCells;
  @override
  @JsonKey()
  List<int> get semanticCells {
    if (_semanticCells is EqualUnmodifiableListView) return _semanticCells;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_semanticCells);
  }

  final List<int> _horizontalEdges;
  @override
  @JsonKey()
  List<int> get horizontalEdges {
    if (_horizontalEdges is EqualUnmodifiableListView) return _horizontalEdges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_horizontalEdges);
  }

  final List<int> _verticalEdges;
  @override
  @JsonKey()
  List<int> get verticalEdges {
    if (_verticalEdges is EqualUnmodifiableListView) return _verticalEdges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_verticalEdges);
  }

  final List<int> _corners;
  @override
  @JsonKey()
  List<int> get corners {
    if (_corners is EqualUnmodifiableListView) return _corners;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_corners);
  }

  @JsonKey(name: 'kind')
  final String $type;

  @override
  String toString() {
    return 'SmartTileField.mixed(semanticCells: $semanticCells, horizontalEdges: $horizontalEdges, verticalEdges: $verticalEdges, corners: $corners)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SmartTileMixedFieldImpl &&
            const DeepCollectionEquality()
                .equals(other._semanticCells, _semanticCells) &&
            const DeepCollectionEquality()
                .equals(other._horizontalEdges, _horizontalEdges) &&
            const DeepCollectionEquality()
                .equals(other._verticalEdges, _verticalEdges) &&
            const DeepCollectionEquality().equals(other._corners, _corners));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_semanticCells),
      const DeepCollectionEquality().hash(_horizontalEdges),
      const DeepCollectionEquality().hash(_verticalEdges),
      const DeepCollectionEquality().hash(_corners));

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SmartTileMixedFieldImplCopyWith<_$SmartTileMixedFieldImpl> get copyWith =>
      __$$SmartTileMixedFieldImplCopyWithImpl<_$SmartTileMixedFieldImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<int> semanticCells) cell,
    required TResult Function(List<int> semanticCells, List<int> corners)
        corner,
    required TResult Function(List<int> semanticCells,
            List<int> horizontalEdges, List<int> verticalEdges)
        edge,
    required TResult Function(
            List<int> semanticCells,
            List<int> horizontalEdges,
            List<int> verticalEdges,
            List<int> corners)
        mixed,
  }) {
    return mixed(semanticCells, horizontalEdges, verticalEdges, corners);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<int> semanticCells)? cell,
    TResult? Function(List<int> semanticCells, List<int> corners)? corner,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult? Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
  }) {
    return mixed?.call(semanticCells, horizontalEdges, verticalEdges, corners);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<int> semanticCells)? cell,
    TResult Function(List<int> semanticCells, List<int> corners)? corner,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges)?
        edge,
    TResult Function(List<int> semanticCells, List<int> horizontalEdges,
            List<int> verticalEdges, List<int> corners)?
        mixed,
    required TResult orElse(),
  }) {
    if (mixed != null) {
      return mixed(semanticCells, horizontalEdges, verticalEdges, corners);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SmartTileCellField value) cell,
    required TResult Function(SmartTileCornerField value) corner,
    required TResult Function(SmartTileEdgeField value) edge,
    required TResult Function(SmartTileMixedField value) mixed,
  }) {
    return mixed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SmartTileCellField value)? cell,
    TResult? Function(SmartTileCornerField value)? corner,
    TResult? Function(SmartTileEdgeField value)? edge,
    TResult? Function(SmartTileMixedField value)? mixed,
  }) {
    return mixed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SmartTileCellField value)? cell,
    TResult Function(SmartTileCornerField value)? corner,
    TResult Function(SmartTileEdgeField value)? edge,
    TResult Function(SmartTileMixedField value)? mixed,
    required TResult orElse(),
  }) {
    if (mixed != null) {
      return mixed(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$SmartTileMixedFieldImplToJson(
      this,
    );
  }
}

abstract class SmartTileMixedField implements SmartTileField {
  const factory SmartTileMixedField(
      {final List<int> semanticCells,
      final List<int> horizontalEdges,
      final List<int> verticalEdges,
      final List<int> corners}) = _$SmartTileMixedFieldImpl;

  factory SmartTileMixedField.fromJson(Map<String, dynamic> json) =
      _$SmartTileMixedFieldImpl.fromJson;

  @override
  List<int> get semanticCells;
  List<int> get horizontalEdges;
  List<int> get verticalEdges;
  List<int> get corners;

  /// Create a copy of SmartTileField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SmartTileMixedFieldImplCopyWith<_$SmartTileMixedFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
