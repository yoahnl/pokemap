// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_manifest.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProjectManifest _$ProjectManifestFromJson(Map<String, dynamic> json) {
  return _ProjectManifest.fromJson(json);
}

/// @nodoc
mixin _$ProjectManifest {
  String get name => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;
  List<ProjectMapEntry> get maps => throw _privateConstructorUsedError;
  List<ProjectTilesetEntry> get tilesets => throw _privateConstructorUsedError;
  Map<String, dynamic> get globalProperties =>
      throw _privateConstructorUsedError;

  /// Serializes this ProjectManifest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectManifestCopyWith<ProjectManifest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectManifestCopyWith<$Res> {
  factory $ProjectManifestCopyWith(
          ProjectManifest value, $Res Function(ProjectManifest) then) =
      _$ProjectManifestCopyWithImpl<$Res, ProjectManifest>;
  @useResult
  $Res call(
      {String name,
      String version,
      List<ProjectMapEntry> maps,
      List<ProjectTilesetEntry> tilesets,
      Map<String, dynamic> globalProperties});
}

/// @nodoc
class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
    implements $ProjectManifestCopyWith<$Res> {
  _$ProjectManifestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? version = null,
    Object? maps = null,
    Object? tilesets = null,
    Object? globalProperties = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      maps: null == maps
          ? _value.maps
          : maps // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapEntry>,
      tilesets: null == tilesets
          ? _value.tilesets
          : tilesets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetEntry>,
      globalProperties: null == globalProperties
          ? _value.globalProperties
          : globalProperties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectManifestImplCopyWith<$Res>
    implements $ProjectManifestCopyWith<$Res> {
  factory _$$ProjectManifestImplCopyWith(_$ProjectManifestImpl value,
          $Res Function(_$ProjectManifestImpl) then) =
      __$$ProjectManifestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String version,
      List<ProjectMapEntry> maps,
      List<ProjectTilesetEntry> tilesets,
      Map<String, dynamic> globalProperties});
}

/// @nodoc
class __$$ProjectManifestImplCopyWithImpl<$Res>
    extends _$ProjectManifestCopyWithImpl<$Res, _$ProjectManifestImpl>
    implements _$$ProjectManifestImplCopyWith<$Res> {
  __$$ProjectManifestImplCopyWithImpl(
      _$ProjectManifestImpl _value, $Res Function(_$ProjectManifestImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? version = null,
    Object? maps = null,
    Object? tilesets = null,
    Object? globalProperties = null,
  }) {
    return _then(_$ProjectManifestImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      maps: null == maps
          ? _value._maps
          : maps // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapEntry>,
      tilesets: null == tilesets
          ? _value._tilesets
          : tilesets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetEntry>,
      globalProperties: null == globalProperties
          ? _value._globalProperties
          : globalProperties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectManifestImpl implements _ProjectManifest {
  const _$ProjectManifestImpl(
      {required this.name,
      this.version = 'v1',
      required final List<ProjectMapEntry> maps,
      required final List<ProjectTilesetEntry> tilesets,
      final Map<String, dynamic> globalProperties = const {}})
      : _maps = maps,
        _tilesets = tilesets,
        _globalProperties = globalProperties;

  factory _$ProjectManifestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectManifestImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final String version;
  final List<ProjectMapEntry> _maps;
  @override
  List<ProjectMapEntry> get maps {
    if (_maps is EqualUnmodifiableListView) return _maps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_maps);
  }

  final List<ProjectTilesetEntry> _tilesets;
  @override
  List<ProjectTilesetEntry> get tilesets {
    if (_tilesets is EqualUnmodifiableListView) return _tilesets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tilesets);
  }

  final Map<String, dynamic> _globalProperties;
  @override
  @JsonKey()
  Map<String, dynamic> get globalProperties {
    if (_globalProperties is EqualUnmodifiableMapView) return _globalProperties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_globalProperties);
  }

  @override
  String toString() {
    return 'ProjectManifest(name: $name, version: $version, maps: $maps, tilesets: $tilesets, globalProperties: $globalProperties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectManifestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality().equals(other._maps, _maps) &&
            const DeepCollectionEquality().equals(other._tilesets, _tilesets) &&
            const DeepCollectionEquality()
                .equals(other._globalProperties, _globalProperties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      version,
      const DeepCollectionEquality().hash(_maps),
      const DeepCollectionEquality().hash(_tilesets),
      const DeepCollectionEquality().hash(_globalProperties));

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectManifestImplCopyWith<_$ProjectManifestImpl> get copyWith =>
      __$$ProjectManifestImplCopyWithImpl<_$ProjectManifestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectManifestImplToJson(
      this,
    );
  }
}

abstract class _ProjectManifest implements ProjectManifest {
  const factory _ProjectManifest(
      {required final String name,
      final String version,
      required final List<ProjectMapEntry> maps,
      required final List<ProjectTilesetEntry> tilesets,
      final Map<String, dynamic> globalProperties}) = _$ProjectManifestImpl;

  factory _ProjectManifest.fromJson(Map<String, dynamic> json) =
      _$ProjectManifestImpl.fromJson;

  @override
  String get name;
  @override
  String get version;
  @override
  List<ProjectMapEntry> get maps;
  @override
  List<ProjectTilesetEntry> get tilesets;
  @override
  Map<String, dynamic> get globalProperties;

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectManifestImplCopyWith<_$ProjectManifestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectMapEntry _$ProjectMapEntryFromJson(Map<String, dynamic> json) {
  return _ProjectMapEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectMapEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get relativePath => throw _privateConstructorUsedError;

  /// Serializes this ProjectMapEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectMapEntryCopyWith<ProjectMapEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectMapEntryCopyWith<$Res> {
  factory $ProjectMapEntryCopyWith(
          ProjectMapEntry value, $Res Function(ProjectMapEntry) then) =
      _$ProjectMapEntryCopyWithImpl<$Res, ProjectMapEntry>;
  @useResult
  $Res call({String id, String name, String relativePath});
}

/// @nodoc
class _$ProjectMapEntryCopyWithImpl<$Res, $Val extends ProjectMapEntry>
    implements $ProjectMapEntryCopyWith<$Res> {
  _$ProjectMapEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectMapEntryImplCopyWith<$Res>
    implements $ProjectMapEntryCopyWith<$Res> {
  factory _$$ProjectMapEntryImplCopyWith(_$ProjectMapEntryImpl value,
          $Res Function(_$ProjectMapEntryImpl) then) =
      __$$ProjectMapEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String relativePath});
}

/// @nodoc
class __$$ProjectMapEntryImplCopyWithImpl<$Res>
    extends _$ProjectMapEntryCopyWithImpl<$Res, _$ProjectMapEntryImpl>
    implements _$$ProjectMapEntryImplCopyWith<$Res> {
  __$$ProjectMapEntryImplCopyWithImpl(
      _$ProjectMapEntryImpl _value, $Res Function(_$ProjectMapEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
  }) {
    return _then(_$ProjectMapEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectMapEntryImpl implements _ProjectMapEntry {
  const _$ProjectMapEntryImpl(
      {required this.id, required this.name, required this.relativePath});

  factory _$ProjectMapEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectMapEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String relativePath;

  @override
  String toString() {
    return 'ProjectMapEntry(id: $id, name: $name, relativePath: $relativePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectMapEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, relativePath);

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectMapEntryImplCopyWith<_$ProjectMapEntryImpl> get copyWith =>
      __$$ProjectMapEntryImplCopyWithImpl<_$ProjectMapEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectMapEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectMapEntry implements ProjectMapEntry {
  const factory _ProjectMapEntry(
      {required final String id,
      required final String name,
      required final String relativePath}) = _$ProjectMapEntryImpl;

  factory _ProjectMapEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectMapEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get relativePath;

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectMapEntryImplCopyWith<_$ProjectMapEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectTilesetEntry _$ProjectTilesetEntryFromJson(Map<String, dynamic> json) {
  return _ProjectTilesetEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectTilesetEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get relativePath => throw _privateConstructorUsedError;

  /// Serializes this ProjectTilesetEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTilesetEntryCopyWith<ProjectTilesetEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTilesetEntryCopyWith<$Res> {
  factory $ProjectTilesetEntryCopyWith(
          ProjectTilesetEntry value, $Res Function(ProjectTilesetEntry) then) =
      _$ProjectTilesetEntryCopyWithImpl<$Res, ProjectTilesetEntry>;
  @useResult
  $Res call({String id, String name, String relativePath});
}

/// @nodoc
class _$ProjectTilesetEntryCopyWithImpl<$Res, $Val extends ProjectTilesetEntry>
    implements $ProjectTilesetEntryCopyWith<$Res> {
  _$ProjectTilesetEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTilesetEntryImplCopyWith<$Res>
    implements $ProjectTilesetEntryCopyWith<$Res> {
  factory _$$ProjectTilesetEntryImplCopyWith(_$ProjectTilesetEntryImpl value,
          $Res Function(_$ProjectTilesetEntryImpl) then) =
      __$$ProjectTilesetEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String relativePath});
}

/// @nodoc
class __$$ProjectTilesetEntryImplCopyWithImpl<$Res>
    extends _$ProjectTilesetEntryCopyWithImpl<$Res, _$ProjectTilesetEntryImpl>
    implements _$$ProjectTilesetEntryImplCopyWith<$Res> {
  __$$ProjectTilesetEntryImplCopyWithImpl(_$ProjectTilesetEntryImpl _value,
      $Res Function(_$ProjectTilesetEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
  }) {
    return _then(_$ProjectTilesetEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTilesetEntryImpl implements _ProjectTilesetEntry {
  const _$ProjectTilesetEntryImpl(
      {required this.id, required this.name, required this.relativePath});

  factory _$ProjectTilesetEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTilesetEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String relativePath;

  @override
  String toString() {
    return 'ProjectTilesetEntry(id: $id, name: $name, relativePath: $relativePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTilesetEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, relativePath);

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTilesetEntryImplCopyWith<_$ProjectTilesetEntryImpl> get copyWith =>
      __$$ProjectTilesetEntryImplCopyWithImpl<_$ProjectTilesetEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTilesetEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectTilesetEntry implements ProjectTilesetEntry {
  const factory _ProjectTilesetEntry(
      {required final String id,
      required final String name,
      required final String relativePath}) = _$ProjectTilesetEntryImpl;

  factory _ProjectTilesetEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectTilesetEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get relativePath;

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTilesetEntryImplCopyWith<_$ProjectTilesetEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
