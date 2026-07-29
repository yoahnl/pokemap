// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_palette_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EditorPaletteContextKey {
  String get mapId => throw _privateConstructorUsedError;
  String get layerId => throw _privateConstructorUsedError;

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditorPaletteContextKeyCopyWith<EditorPaletteContextKey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorPaletteContextKeyCopyWith<$Res> {
  factory $EditorPaletteContextKeyCopyWith(EditorPaletteContextKey value,
          $Res Function(EditorPaletteContextKey) then) =
      _$EditorPaletteContextKeyCopyWithImpl<$Res, EditorPaletteContextKey>;
  @useResult
  $Res call({String mapId, String layerId});
}

/// @nodoc
class _$EditorPaletteContextKeyCopyWithImpl<$Res,
        $Val extends EditorPaletteContextKey>
    implements $EditorPaletteContextKeyCopyWith<$Res> {
  _$EditorPaletteContextKeyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mapId = null,
    Object? layerId = null,
  }) {
    return _then(_value.copyWith(
      mapId: null == mapId
          ? _value.mapId
          : mapId // ignore: cast_nullable_to_non_nullable
              as String,
      layerId: null == layerId
          ? _value.layerId
          : layerId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EditorPaletteContextKeyImplCopyWith<$Res>
    implements $EditorPaletteContextKeyCopyWith<$Res> {
  factory _$$EditorPaletteContextKeyImplCopyWith(
          _$EditorPaletteContextKeyImpl value,
          $Res Function(_$EditorPaletteContextKeyImpl) then) =
      __$$EditorPaletteContextKeyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String mapId, String layerId});
}

/// @nodoc
class __$$EditorPaletteContextKeyImplCopyWithImpl<$Res>
    extends _$EditorPaletteContextKeyCopyWithImpl<$Res,
        _$EditorPaletteContextKeyImpl>
    implements _$$EditorPaletteContextKeyImplCopyWith<$Res> {
  __$$EditorPaletteContextKeyImplCopyWithImpl(
      _$EditorPaletteContextKeyImpl _value,
      $Res Function(_$EditorPaletteContextKeyImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mapId = null,
    Object? layerId = null,
  }) {
    return _then(_$EditorPaletteContextKeyImpl(
      mapId: null == mapId
          ? _value.mapId
          : mapId // ignore: cast_nullable_to_non_nullable
              as String,
      layerId: null == layerId
          ? _value.layerId
          : layerId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$EditorPaletteContextKeyImpl implements _EditorPaletteContextKey {
  const _$EditorPaletteContextKeyImpl(
      {required this.mapId, required this.layerId});

  @override
  final String mapId;
  @override
  final String layerId;

  @override
  String toString() {
    return 'EditorPaletteContextKey(mapId: $mapId, layerId: $layerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorPaletteContextKeyImpl &&
            (identical(other.mapId, mapId) || other.mapId == mapId) &&
            (identical(other.layerId, layerId) || other.layerId == layerId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, mapId, layerId);

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorPaletteContextKeyImplCopyWith<_$EditorPaletteContextKeyImpl>
      get copyWith => __$$EditorPaletteContextKeyImplCopyWithImpl<
          _$EditorPaletteContextKeyImpl>(this, _$identity);
}

abstract class _EditorPaletteContextKey implements EditorPaletteContextKey {
  const factory _EditorPaletteContextKey(
      {required final String mapId,
      required final String layerId}) = _$EditorPaletteContextKeyImpl;

  @override
  String get mapId;
  @override
  String get layerId;

  /// Create a copy of EditorPaletteContextKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditorPaletteContextKeyImplCopyWith<_$EditorPaletteContextKeyImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EditorPaletteBrushMemory {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorPaletteBrushMemoryCopyWith<$Res> {
  factory $EditorPaletteBrushMemoryCopyWith(EditorPaletteBrushMemory value,
          $Res Function(EditorPaletteBrushMemory) then) =
      _$EditorPaletteBrushMemoryCopyWithImpl<$Res, EditorPaletteBrushMemory>;
}

/// @nodoc
class _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        $Val extends EditorPaletteBrushMemory>
    implements $EditorPaletteBrushMemoryCopyWith<$Res> {
  _$EditorPaletteBrushMemoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NoEditorPaletteBrushMemoryImplCopyWith<$Res> {
  factory _$$NoEditorPaletteBrushMemoryImplCopyWith(
          _$NoEditorPaletteBrushMemoryImpl value,
          $Res Function(_$NoEditorPaletteBrushMemoryImpl) then) =
      __$$NoEditorPaletteBrushMemoryImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NoEditorPaletteBrushMemoryImplCopyWithImpl<$Res>
    extends _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        _$NoEditorPaletteBrushMemoryImpl>
    implements _$$NoEditorPaletteBrushMemoryImplCopyWith<$Res> {
  __$$NoEditorPaletteBrushMemoryImplCopyWithImpl(
      _$NoEditorPaletteBrushMemoryImpl _value,
      $Res Function(_$NoEditorPaletteBrushMemoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NoEditorPaletteBrushMemoryImpl implements NoEditorPaletteBrushMemory {
  const _$NoEditorPaletteBrushMemoryImpl();

  @override
  String toString() {
    return 'EditorPaletteBrushMemory.none()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoEditorPaletteBrushMemoryImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) {
    return none();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) {
    return none?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) {
    return none(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) {
    return none?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none(this);
    }
    return orElse();
  }
}

abstract class NoEditorPaletteBrushMemory implements EditorPaletteBrushMemory {
  const factory NoEditorPaletteBrushMemory() = _$NoEditorPaletteBrushMemoryImpl;
}

/// @nodoc
abstract class _$$TileEditorPaletteBrushMemoryImplCopyWith<$Res> {
  factory _$$TileEditorPaletteBrushMemoryImplCopyWith(
          _$TileEditorPaletteBrushMemoryImpl value,
          $Res Function(_$TileEditorPaletteBrushMemoryImpl) then) =
      __$$TileEditorPaletteBrushMemoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int tileId, String tilesetId});
}

/// @nodoc
class __$$TileEditorPaletteBrushMemoryImplCopyWithImpl<$Res>
    extends _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        _$TileEditorPaletteBrushMemoryImpl>
    implements _$$TileEditorPaletteBrushMemoryImplCopyWith<$Res> {
  __$$TileEditorPaletteBrushMemoryImplCopyWithImpl(
      _$TileEditorPaletteBrushMemoryImpl _value,
      $Res Function(_$TileEditorPaletteBrushMemoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileId = null,
    Object? tilesetId = null,
  }) {
    return _then(_$TileEditorPaletteBrushMemoryImpl(
      tileId: null == tileId
          ? _value.tileId
          : tileId // ignore: cast_nullable_to_non_nullable
              as int,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TileEditorPaletteBrushMemoryImpl
    implements TileEditorPaletteBrushMemory {
  const _$TileEditorPaletteBrushMemoryImpl(
      {required this.tileId, required this.tilesetId});

  @override
  final int tileId;
  @override
  final String tilesetId;

  @override
  String toString() {
    return 'EditorPaletteBrushMemory.tile(tileId: $tileId, tilesetId: $tilesetId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TileEditorPaletteBrushMemoryImpl &&
            (identical(other.tileId, tileId) || other.tileId == tileId) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tileId, tilesetId);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TileEditorPaletteBrushMemoryImplCopyWith<
          _$TileEditorPaletteBrushMemoryImpl>
      get copyWith => __$$TileEditorPaletteBrushMemoryImplCopyWithImpl<
          _$TileEditorPaletteBrushMemoryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) {
    return tile(tileId, tilesetId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) {
    return tile?.call(tileId, tilesetId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) {
    if (tile != null) {
      return tile(tileId, tilesetId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) {
    return tile(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) {
    return tile?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) {
    if (tile != null) {
      return tile(this);
    }
    return orElse();
  }
}

abstract class TileEditorPaletteBrushMemory
    implements EditorPaletteBrushMemory {
  const factory TileEditorPaletteBrushMemory(
      {required final int tileId,
      required final String tilesetId}) = _$TileEditorPaletteBrushMemoryImpl;

  int get tileId;
  String get tilesetId;

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TileEditorPaletteBrushMemoryImplCopyWith<
          _$TileEditorPaletteBrushMemoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith<$Res> {
  factory _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith(
          _$PaletteEntryEditorPaletteBrushMemoryImpl value,
          $Res Function(_$PaletteEntryEditorPaletteBrushMemoryImpl) then) =
      __$$PaletteEntryEditorPaletteBrushMemoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String entryId, String tilesetId});
}

/// @nodoc
class __$$PaletteEntryEditorPaletteBrushMemoryImplCopyWithImpl<$Res>
    extends _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        _$PaletteEntryEditorPaletteBrushMemoryImpl>
    implements _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith<$Res> {
  __$$PaletteEntryEditorPaletteBrushMemoryImplCopyWithImpl(
      _$PaletteEntryEditorPaletteBrushMemoryImpl _value,
      $Res Function(_$PaletteEntryEditorPaletteBrushMemoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entryId = null,
    Object? tilesetId = null,
  }) {
    return _then(_$PaletteEntryEditorPaletteBrushMemoryImpl(
      entryId: null == entryId
          ? _value.entryId
          : entryId // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PaletteEntryEditorPaletteBrushMemoryImpl
    implements PaletteEntryEditorPaletteBrushMemory {
  const _$PaletteEntryEditorPaletteBrushMemoryImpl(
      {required this.entryId, required this.tilesetId});

  @override
  final String entryId;
  @override
  final String tilesetId;

  @override
  String toString() {
    return 'EditorPaletteBrushMemory.paletteEntry(entryId: $entryId, tilesetId: $tilesetId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaletteEntryEditorPaletteBrushMemoryImpl &&
            (identical(other.entryId, entryId) || other.entryId == entryId) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, entryId, tilesetId);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith<
          _$PaletteEntryEditorPaletteBrushMemoryImpl>
      get copyWith => __$$PaletteEntryEditorPaletteBrushMemoryImplCopyWithImpl<
          _$PaletteEntryEditorPaletteBrushMemoryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) {
    return paletteEntry(entryId, tilesetId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) {
    return paletteEntry?.call(entryId, tilesetId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) {
    if (paletteEntry != null) {
      return paletteEntry(entryId, tilesetId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) {
    return paletteEntry(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) {
    return paletteEntry?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) {
    if (paletteEntry != null) {
      return paletteEntry(this);
    }
    return orElse();
  }
}

abstract class PaletteEntryEditorPaletteBrushMemory
    implements EditorPaletteBrushMemory {
  const factory PaletteEntryEditorPaletteBrushMemory(
          {required final String entryId, required final String tilesetId}) =
      _$PaletteEntryEditorPaletteBrushMemoryImpl;

  String get entryId;
  String get tilesetId;

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaletteEntryEditorPaletteBrushMemoryImplCopyWith<
          _$PaletteEntryEditorPaletteBrushMemoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith<$Res> {
  factory _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith(
          _$ProjectElementEditorPaletteBrushMemoryImpl value,
          $Res Function(_$ProjectElementEditorPaletteBrushMemoryImpl) then) =
      __$$ProjectElementEditorPaletteBrushMemoryImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String elementId});
}

/// @nodoc
class __$$ProjectElementEditorPaletteBrushMemoryImplCopyWithImpl<$Res>
    extends _$EditorPaletteBrushMemoryCopyWithImpl<$Res,
        _$ProjectElementEditorPaletteBrushMemoryImpl>
    implements _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith<$Res> {
  __$$ProjectElementEditorPaletteBrushMemoryImplCopyWithImpl(
      _$ProjectElementEditorPaletteBrushMemoryImpl _value,
      $Res Function(_$ProjectElementEditorPaletteBrushMemoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? elementId = null,
  }) {
    return _then(_$ProjectElementEditorPaletteBrushMemoryImpl(
      elementId: null == elementId
          ? _value.elementId
          : elementId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ProjectElementEditorPaletteBrushMemoryImpl
    implements ProjectElementEditorPaletteBrushMemory {
  const _$ProjectElementEditorPaletteBrushMemoryImpl({required this.elementId});

  @override
  final String elementId;

  @override
  String toString() {
    return 'EditorPaletteBrushMemory.projectElement(elementId: $elementId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectElementEditorPaletteBrushMemoryImpl &&
            (identical(other.elementId, elementId) ||
                other.elementId == elementId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, elementId);

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith<
          _$ProjectElementEditorPaletteBrushMemoryImpl>
      get copyWith =>
          __$$ProjectElementEditorPaletteBrushMemoryImplCopyWithImpl<
              _$ProjectElementEditorPaletteBrushMemoryImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() none,
    required TResult Function(int tileId, String tilesetId) tile,
    required TResult Function(String entryId, String tilesetId) paletteEntry,
    required TResult Function(String elementId) projectElement,
  }) {
    return projectElement(elementId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? none,
    TResult? Function(int tileId, String tilesetId)? tile,
    TResult? Function(String entryId, String tilesetId)? paletteEntry,
    TResult? Function(String elementId)? projectElement,
  }) {
    return projectElement?.call(elementId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? none,
    TResult Function(int tileId, String tilesetId)? tile,
    TResult Function(String entryId, String tilesetId)? paletteEntry,
    TResult Function(String elementId)? projectElement,
    required TResult orElse(),
  }) {
    if (projectElement != null) {
      return projectElement(elementId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NoEditorPaletteBrushMemory value) none,
    required TResult Function(TileEditorPaletteBrushMemory value) tile,
    required TResult Function(PaletteEntryEditorPaletteBrushMemory value)
        paletteEntry,
    required TResult Function(ProjectElementEditorPaletteBrushMemory value)
        projectElement,
  }) {
    return projectElement(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NoEditorPaletteBrushMemory value)? none,
    TResult? Function(TileEditorPaletteBrushMemory value)? tile,
    TResult? Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult? Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
  }) {
    return projectElement?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NoEditorPaletteBrushMemory value)? none,
    TResult Function(TileEditorPaletteBrushMemory value)? tile,
    TResult Function(PaletteEntryEditorPaletteBrushMemory value)? paletteEntry,
    TResult Function(ProjectElementEditorPaletteBrushMemory value)?
        projectElement,
    required TResult orElse(),
  }) {
    if (projectElement != null) {
      return projectElement(this);
    }
    return orElse();
  }
}

abstract class ProjectElementEditorPaletteBrushMemory
    implements EditorPaletteBrushMemory {
  const factory ProjectElementEditorPaletteBrushMemory(
          {required final String elementId}) =
      _$ProjectElementEditorPaletteBrushMemoryImpl;

  String get elementId;

  /// Create a copy of EditorPaletteBrushMemory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectElementEditorPaletteBrushMemoryImplCopyWith<
          _$ProjectElementEditorPaletteBrushMemoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EditorLayerPaletteContext {
  String? get selectedTilesetId => throw _privateConstructorUsedError;
  String? get selectedElementGroupId => throw _privateConstructorUsedError;
  PaletteCategory? get paletteCategoryFilter =>
      throw _privateConstructorUsedError;
  EditorPaletteBrushMemory get activeBrush =>
      throw _privateConstructorUsedError;
  TilesElementsPanelMode get panelMode => throw _privateConstructorUsedError;
  String get browserQuery => throw _privateConstructorUsedError;
  String? get browserFolderId => throw _privateConstructorUsedError;
  String? get projectElementCategoryId => throw _privateConstructorUsedError;
  EditorPaletteAssetCollection get browserCollection =>
      throw _privateConstructorUsedError;
  bool get showIncompatible => throw _privateConstructorUsedError;

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditorLayerPaletteContextCopyWith<EditorLayerPaletteContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorLayerPaletteContextCopyWith<$Res> {
  factory $EditorLayerPaletteContextCopyWith(EditorLayerPaletteContext value,
          $Res Function(EditorLayerPaletteContext) then) =
      _$EditorLayerPaletteContextCopyWithImpl<$Res, EditorLayerPaletteContext>;
  @useResult
  $Res call(
      {String? selectedTilesetId,
      String? selectedElementGroupId,
      PaletteCategory? paletteCategoryFilter,
      EditorPaletteBrushMemory activeBrush,
      TilesElementsPanelMode panelMode,
      String browserQuery,
      String? browserFolderId,
      String? projectElementCategoryId,
      EditorPaletteAssetCollection browserCollection,
      bool showIncompatible});

  $EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush;
}

/// @nodoc
class _$EditorLayerPaletteContextCopyWithImpl<$Res,
        $Val extends EditorLayerPaletteContext>
    implements $EditorLayerPaletteContextCopyWith<$Res> {
  _$EditorLayerPaletteContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedTilesetId = freezed,
    Object? selectedElementGroupId = freezed,
    Object? paletteCategoryFilter = freezed,
    Object? activeBrush = null,
    Object? panelMode = null,
    Object? browserQuery = null,
    Object? browserFolderId = freezed,
    Object? projectElementCategoryId = freezed,
    Object? browserCollection = null,
    Object? showIncompatible = null,
  }) {
    return _then(_value.copyWith(
      selectedTilesetId: freezed == selectedTilesetId
          ? _value.selectedTilesetId
          : selectedTilesetId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedElementGroupId: freezed == selectedElementGroupId
          ? _value.selectedElementGroupId
          : selectedElementGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      paletteCategoryFilter: freezed == paletteCategoryFilter
          ? _value.paletteCategoryFilter
          : paletteCategoryFilter // ignore: cast_nullable_to_non_nullable
              as PaletteCategory?,
      activeBrush: null == activeBrush
          ? _value.activeBrush
          : activeBrush // ignore: cast_nullable_to_non_nullable
              as EditorPaletteBrushMemory,
      panelMode: null == panelMode
          ? _value.panelMode
          : panelMode // ignore: cast_nullable_to_non_nullable
              as TilesElementsPanelMode,
      browserQuery: null == browserQuery
          ? _value.browserQuery
          : browserQuery // ignore: cast_nullable_to_non_nullable
              as String,
      browserFolderId: freezed == browserFolderId
          ? _value.browserFolderId
          : browserFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      projectElementCategoryId: freezed == projectElementCategoryId
          ? _value.projectElementCategoryId
          : projectElementCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      browserCollection: null == browserCollection
          ? _value.browserCollection
          : browserCollection // ignore: cast_nullable_to_non_nullable
              as EditorPaletteAssetCollection,
      showIncompatible: null == showIncompatible
          ? _value.showIncompatible
          : showIncompatible // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush {
    return $EditorPaletteBrushMemoryCopyWith<$Res>(_value.activeBrush, (value) {
      return _then(_value.copyWith(activeBrush: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EditorLayerPaletteContextImplCopyWith<$Res>
    implements $EditorLayerPaletteContextCopyWith<$Res> {
  factory _$$EditorLayerPaletteContextImplCopyWith(
          _$EditorLayerPaletteContextImpl value,
          $Res Function(_$EditorLayerPaletteContextImpl) then) =
      __$$EditorLayerPaletteContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? selectedTilesetId,
      String? selectedElementGroupId,
      PaletteCategory? paletteCategoryFilter,
      EditorPaletteBrushMemory activeBrush,
      TilesElementsPanelMode panelMode,
      String browserQuery,
      String? browserFolderId,
      String? projectElementCategoryId,
      EditorPaletteAssetCollection browserCollection,
      bool showIncompatible});

  @override
  $EditorPaletteBrushMemoryCopyWith<$Res> get activeBrush;
}

/// @nodoc
class __$$EditorLayerPaletteContextImplCopyWithImpl<$Res>
    extends _$EditorLayerPaletteContextCopyWithImpl<$Res,
        _$EditorLayerPaletteContextImpl>
    implements _$$EditorLayerPaletteContextImplCopyWith<$Res> {
  __$$EditorLayerPaletteContextImplCopyWithImpl(
      _$EditorLayerPaletteContextImpl _value,
      $Res Function(_$EditorLayerPaletteContextImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedTilesetId = freezed,
    Object? selectedElementGroupId = freezed,
    Object? paletteCategoryFilter = freezed,
    Object? activeBrush = null,
    Object? panelMode = null,
    Object? browserQuery = null,
    Object? browserFolderId = freezed,
    Object? projectElementCategoryId = freezed,
    Object? browserCollection = null,
    Object? showIncompatible = null,
  }) {
    return _then(_$EditorLayerPaletteContextImpl(
      selectedTilesetId: freezed == selectedTilesetId
          ? _value.selectedTilesetId
          : selectedTilesetId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedElementGroupId: freezed == selectedElementGroupId
          ? _value.selectedElementGroupId
          : selectedElementGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      paletteCategoryFilter: freezed == paletteCategoryFilter
          ? _value.paletteCategoryFilter
          : paletteCategoryFilter // ignore: cast_nullable_to_non_nullable
              as PaletteCategory?,
      activeBrush: null == activeBrush
          ? _value.activeBrush
          : activeBrush // ignore: cast_nullable_to_non_nullable
              as EditorPaletteBrushMemory,
      panelMode: null == panelMode
          ? _value.panelMode
          : panelMode // ignore: cast_nullable_to_non_nullable
              as TilesElementsPanelMode,
      browserQuery: null == browserQuery
          ? _value.browserQuery
          : browserQuery // ignore: cast_nullable_to_non_nullable
              as String,
      browserFolderId: freezed == browserFolderId
          ? _value.browserFolderId
          : browserFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      projectElementCategoryId: freezed == projectElementCategoryId
          ? _value.projectElementCategoryId
          : projectElementCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      browserCollection: null == browserCollection
          ? _value.browserCollection
          : browserCollection // ignore: cast_nullable_to_non_nullable
              as EditorPaletteAssetCollection,
      showIncompatible: null == showIncompatible
          ? _value.showIncompatible
          : showIncompatible // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$EditorLayerPaletteContextImpl implements _EditorLayerPaletteContext {
  const _$EditorLayerPaletteContextImpl(
      {this.selectedTilesetId,
      this.selectedElementGroupId,
      this.paletteCategoryFilter,
      this.activeBrush = const EditorPaletteBrushMemory.none(),
      this.panelMode = TilesElementsPanelMode.palette,
      this.browserQuery = '',
      this.browserFolderId,
      this.projectElementCategoryId,
      this.browserCollection = EditorPaletteAssetCollection.all,
      this.showIncompatible = false});

  @override
  final String? selectedTilesetId;
  @override
  final String? selectedElementGroupId;
  @override
  final PaletteCategory? paletteCategoryFilter;
  @override
  @JsonKey()
  final EditorPaletteBrushMemory activeBrush;
  @override
  @JsonKey()
  final TilesElementsPanelMode panelMode;
  @override
  @JsonKey()
  final String browserQuery;
  @override
  final String? browserFolderId;
  @override
  final String? projectElementCategoryId;
  @override
  @JsonKey()
  final EditorPaletteAssetCollection browserCollection;
  @override
  @JsonKey()
  final bool showIncompatible;

  @override
  String toString() {
    return 'EditorLayerPaletteContext(selectedTilesetId: $selectedTilesetId, selectedElementGroupId: $selectedElementGroupId, paletteCategoryFilter: $paletteCategoryFilter, activeBrush: $activeBrush, panelMode: $panelMode, browserQuery: $browserQuery, browserFolderId: $browserFolderId, projectElementCategoryId: $projectElementCategoryId, browserCollection: $browserCollection, showIncompatible: $showIncompatible)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorLayerPaletteContextImpl &&
            (identical(other.selectedTilesetId, selectedTilesetId) ||
                other.selectedTilesetId == selectedTilesetId) &&
            (identical(other.selectedElementGroupId, selectedElementGroupId) ||
                other.selectedElementGroupId == selectedElementGroupId) &&
            (identical(other.paletteCategoryFilter, paletteCategoryFilter) ||
                other.paletteCategoryFilter == paletteCategoryFilter) &&
            (identical(other.activeBrush, activeBrush) ||
                other.activeBrush == activeBrush) &&
            (identical(other.panelMode, panelMode) ||
                other.panelMode == panelMode) &&
            (identical(other.browserQuery, browserQuery) ||
                other.browserQuery == browserQuery) &&
            (identical(other.browserFolderId, browserFolderId) ||
                other.browserFolderId == browserFolderId) &&
            (identical(
                    other.projectElementCategoryId, projectElementCategoryId) ||
                other.projectElementCategoryId == projectElementCategoryId) &&
            (identical(other.browserCollection, browserCollection) ||
                other.browserCollection == browserCollection) &&
            (identical(other.showIncompatible, showIncompatible) ||
                other.showIncompatible == showIncompatible));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      selectedTilesetId,
      selectedElementGroupId,
      paletteCategoryFilter,
      activeBrush,
      panelMode,
      browserQuery,
      browserFolderId,
      projectElementCategoryId,
      browserCollection,
      showIncompatible);

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorLayerPaletteContextImplCopyWith<_$EditorLayerPaletteContextImpl>
      get copyWith => __$$EditorLayerPaletteContextImplCopyWithImpl<
          _$EditorLayerPaletteContextImpl>(this, _$identity);
}

abstract class _EditorLayerPaletteContext implements EditorLayerPaletteContext {
  const factory _EditorLayerPaletteContext(
      {final String? selectedTilesetId,
      final String? selectedElementGroupId,
      final PaletteCategory? paletteCategoryFilter,
      final EditorPaletteBrushMemory activeBrush,
      final TilesElementsPanelMode panelMode,
      final String browserQuery,
      final String? browserFolderId,
      final String? projectElementCategoryId,
      final EditorPaletteAssetCollection browserCollection,
      final bool showIncompatible}) = _$EditorLayerPaletteContextImpl;

  @override
  String? get selectedTilesetId;
  @override
  String? get selectedElementGroupId;
  @override
  PaletteCategory? get paletteCategoryFilter;
  @override
  EditorPaletteBrushMemory get activeBrush;
  @override
  TilesElementsPanelMode get panelMode;
  @override
  String get browserQuery;
  @override
  String? get browserFolderId;
  @override
  String? get projectElementCategoryId;
  @override
  EditorPaletteAssetCollection get browserCollection;
  @override
  bool get showIncompatible;

  /// Create a copy of EditorLayerPaletteContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditorLayerPaletteContextImplCopyWith<_$EditorLayerPaletteContextImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EditorPaletteSession {
  EditorPaletteContextKey? get activeKey => throw _privateConstructorUsedError;
  Map<EditorPaletteContextKey, EditorLayerPaletteContext> get contexts =>
      throw _privateConstructorUsedError;
  List<String> get recentTilesetIds => throw _privateConstructorUsedError;
  List<String> get favoriteTilesetIds => throw _privateConstructorUsedError;

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditorPaletteSessionCopyWith<EditorPaletteSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorPaletteSessionCopyWith<$Res> {
  factory $EditorPaletteSessionCopyWith(EditorPaletteSession value,
          $Res Function(EditorPaletteSession) then) =
      _$EditorPaletteSessionCopyWithImpl<$Res, EditorPaletteSession>;
  @useResult
  $Res call(
      {EditorPaletteContextKey? activeKey,
      Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,
      List<String> recentTilesetIds,
      List<String> favoriteTilesetIds});

  $EditorPaletteContextKeyCopyWith<$Res>? get activeKey;
}

/// @nodoc
class _$EditorPaletteSessionCopyWithImpl<$Res,
        $Val extends EditorPaletteSession>
    implements $EditorPaletteSessionCopyWith<$Res> {
  _$EditorPaletteSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeKey = freezed,
    Object? contexts = null,
    Object? recentTilesetIds = null,
    Object? favoriteTilesetIds = null,
  }) {
    return _then(_value.copyWith(
      activeKey: freezed == activeKey
          ? _value.activeKey
          : activeKey // ignore: cast_nullable_to_non_nullable
              as EditorPaletteContextKey?,
      contexts: null == contexts
          ? _value.contexts
          : contexts // ignore: cast_nullable_to_non_nullable
              as Map<EditorPaletteContextKey, EditorLayerPaletteContext>,
      recentTilesetIds: null == recentTilesetIds
          ? _value.recentTilesetIds
          : recentTilesetIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      favoriteTilesetIds: null == favoriteTilesetIds
          ? _value.favoriteTilesetIds
          : favoriteTilesetIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EditorPaletteContextKeyCopyWith<$Res>? get activeKey {
    if (_value.activeKey == null) {
      return null;
    }

    return $EditorPaletteContextKeyCopyWith<$Res>(_value.activeKey!, (value) {
      return _then(_value.copyWith(activeKey: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EditorPaletteSessionImplCopyWith<$Res>
    implements $EditorPaletteSessionCopyWith<$Res> {
  factory _$$EditorPaletteSessionImplCopyWith(_$EditorPaletteSessionImpl value,
          $Res Function(_$EditorPaletteSessionImpl) then) =
      __$$EditorPaletteSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {EditorPaletteContextKey? activeKey,
      Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,
      List<String> recentTilesetIds,
      List<String> favoriteTilesetIds});

  @override
  $EditorPaletteContextKeyCopyWith<$Res>? get activeKey;
}

/// @nodoc
class __$$EditorPaletteSessionImplCopyWithImpl<$Res>
    extends _$EditorPaletteSessionCopyWithImpl<$Res, _$EditorPaletteSessionImpl>
    implements _$$EditorPaletteSessionImplCopyWith<$Res> {
  __$$EditorPaletteSessionImplCopyWithImpl(_$EditorPaletteSessionImpl _value,
      $Res Function(_$EditorPaletteSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeKey = freezed,
    Object? contexts = null,
    Object? recentTilesetIds = null,
    Object? favoriteTilesetIds = null,
  }) {
    return _then(_$EditorPaletteSessionImpl(
      activeKey: freezed == activeKey
          ? _value.activeKey
          : activeKey // ignore: cast_nullable_to_non_nullable
              as EditorPaletteContextKey?,
      contexts: null == contexts
          ? _value._contexts
          : contexts // ignore: cast_nullable_to_non_nullable
              as Map<EditorPaletteContextKey, EditorLayerPaletteContext>,
      recentTilesetIds: null == recentTilesetIds
          ? _value._recentTilesetIds
          : recentTilesetIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      favoriteTilesetIds: null == favoriteTilesetIds
          ? _value._favoriteTilesetIds
          : favoriteTilesetIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$EditorPaletteSessionImpl implements _EditorPaletteSession {
  const _$EditorPaletteSessionImpl(
      {this.activeKey,
      final Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts =
          const <EditorPaletteContextKey, EditorLayerPaletteContext>{},
      final List<String> recentTilesetIds = const <String>[],
      final List<String> favoriteTilesetIds = const <String>[]})
      : _contexts = contexts,
        _recentTilesetIds = recentTilesetIds,
        _favoriteTilesetIds = favoriteTilesetIds;

  @override
  final EditorPaletteContextKey? activeKey;
  final Map<EditorPaletteContextKey, EditorLayerPaletteContext> _contexts;
  @override
  @JsonKey()
  Map<EditorPaletteContextKey, EditorLayerPaletteContext> get contexts {
    if (_contexts is EqualUnmodifiableMapView) return _contexts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_contexts);
  }

  final List<String> _recentTilesetIds;
  @override
  @JsonKey()
  List<String> get recentTilesetIds {
    if (_recentTilesetIds is EqualUnmodifiableListView)
      return _recentTilesetIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentTilesetIds);
  }

  final List<String> _favoriteTilesetIds;
  @override
  @JsonKey()
  List<String> get favoriteTilesetIds {
    if (_favoriteTilesetIds is EqualUnmodifiableListView)
      return _favoriteTilesetIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_favoriteTilesetIds);
  }

  @override
  String toString() {
    return 'EditorPaletteSession(activeKey: $activeKey, contexts: $contexts, recentTilesetIds: $recentTilesetIds, favoriteTilesetIds: $favoriteTilesetIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorPaletteSessionImpl &&
            (identical(other.activeKey, activeKey) ||
                other.activeKey == activeKey) &&
            const DeepCollectionEquality().equals(other._contexts, _contexts) &&
            const DeepCollectionEquality()
                .equals(other._recentTilesetIds, _recentTilesetIds) &&
            const DeepCollectionEquality()
                .equals(other._favoriteTilesetIds, _favoriteTilesetIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      activeKey,
      const DeepCollectionEquality().hash(_contexts),
      const DeepCollectionEquality().hash(_recentTilesetIds),
      const DeepCollectionEquality().hash(_favoriteTilesetIds));

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorPaletteSessionImplCopyWith<_$EditorPaletteSessionImpl>
      get copyWith =>
          __$$EditorPaletteSessionImplCopyWithImpl<_$EditorPaletteSessionImpl>(
              this, _$identity);
}

abstract class _EditorPaletteSession implements EditorPaletteSession {
  const factory _EditorPaletteSession(
      {final EditorPaletteContextKey? activeKey,
      final Map<EditorPaletteContextKey, EditorLayerPaletteContext> contexts,
      final List<String> recentTilesetIds,
      final List<String> favoriteTilesetIds}) = _$EditorPaletteSessionImpl;

  @override
  EditorPaletteContextKey? get activeKey;
  @override
  Map<EditorPaletteContextKey, EditorLayerPaletteContext> get contexts;
  @override
  List<String> get recentTilesetIds;
  @override
  List<String> get favoriteTilesetIds;

  /// Create a copy of EditorPaletteSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditorPaletteSessionImplCopyWith<_$EditorPaletteSessionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
