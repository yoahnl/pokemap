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
  ProjectVersion get version => throw _privateConstructorUsedError;
  List<ProjectMapEntry> get maps => throw _privateConstructorUsedError;
  List<ProjectMapGroup> get groups => throw _privateConstructorUsedError;
  List<ProjectTilesetEntry> get tilesets => throw _privateConstructorUsedError;
  ProjectSettings get settings => throw _privateConstructorUsedError;
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
      ProjectVersion version,
      List<ProjectMapEntry> maps,
      List<ProjectMapGroup> groups,
      List<ProjectTilesetEntry> tilesets,
      ProjectSettings settings,
      Map<String, dynamic> globalProperties});

  $ProjectSettingsCopyWith<$Res> get settings;
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
    Object? groups = null,
    Object? tilesets = null,
    Object? settings = null,
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
              as ProjectVersion,
      maps: null == maps
          ? _value.maps
          : maps // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapEntry>,
      groups: null == groups
          ? _value.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapGroup>,
      tilesets: null == tilesets
          ? _value.tilesets
          : tilesets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetEntry>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as ProjectSettings,
      globalProperties: null == globalProperties
          ? _value.globalProperties
          : globalProperties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectSettingsCopyWith<$Res> get settings {
    return $ProjectSettingsCopyWith<$Res>(_value.settings, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
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
      ProjectVersion version,
      List<ProjectMapEntry> maps,
      List<ProjectMapGroup> groups,
      List<ProjectTilesetEntry> tilesets,
      ProjectSettings settings,
      Map<String, dynamic> globalProperties});

  @override
  $ProjectSettingsCopyWith<$Res> get settings;
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
    Object? groups = null,
    Object? tilesets = null,
    Object? settings = null,
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
              as ProjectVersion,
      maps: null == maps
          ? _value._maps
          : maps // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapEntry>,
      groups: null == groups
          ? _value._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapGroup>,
      tilesets: null == tilesets
          ? _value._tilesets
          : tilesets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetEntry>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as ProjectSettings,
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
      this.version = ProjectVersion.v1,
      required final List<ProjectMapEntry> maps,
      final List<ProjectMapGroup> groups = const [],
      required final List<ProjectTilesetEntry> tilesets,
      this.settings = const ProjectSettings(),
      final Map<String, dynamic> globalProperties = const {}})
      : _maps = maps,
        _groups = groups,
        _tilesets = tilesets,
        _globalProperties = globalProperties;

  factory _$ProjectManifestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectManifestImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final ProjectVersion version;
  final List<ProjectMapEntry> _maps;
  @override
  List<ProjectMapEntry> get maps {
    if (_maps is EqualUnmodifiableListView) return _maps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_maps);
  }

  final List<ProjectMapGroup> _groups;
  @override
  @JsonKey()
  List<ProjectMapGroup> get groups {
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_groups);
  }

  final List<ProjectTilesetEntry> _tilesets;
  @override
  List<ProjectTilesetEntry> get tilesets {
    if (_tilesets is EqualUnmodifiableListView) return _tilesets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tilesets);
  }

  @override
  @JsonKey()
  final ProjectSettings settings;
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
    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesets: $tilesets, settings: $settings, globalProperties: $globalProperties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectManifestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality().equals(other._maps, _maps) &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            const DeepCollectionEquality().equals(other._tilesets, _tilesets) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
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
      const DeepCollectionEquality().hash(_groups),
      const DeepCollectionEquality().hash(_tilesets),
      settings,
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
      final ProjectVersion version,
      required final List<ProjectMapEntry> maps,
      final List<ProjectMapGroup> groups,
      required final List<ProjectTilesetEntry> tilesets,
      final ProjectSettings settings,
      final Map<String, dynamic> globalProperties}) = _$ProjectManifestImpl;

  factory _ProjectManifest.fromJson(Map<String, dynamic> json) =
      _$ProjectManifestImpl.fromJson;

  @override
  String get name;
  @override
  ProjectVersion get version;
  @override
  List<ProjectMapEntry> get maps;
  @override
  List<ProjectMapGroup> get groups;
  @override
  List<ProjectTilesetEntry> get tilesets;
  @override
  ProjectSettings get settings;
  @override
  Map<String, dynamic> get globalProperties;

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectManifestImplCopyWith<_$ProjectManifestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectSettings _$ProjectSettingsFromJson(Map<String, dynamic> json) {
  return _ProjectSettings.fromJson(json);
}

/// @nodoc
mixin _$ProjectSettings {
  int get tileWidth => throw _privateConstructorUsedError;
  int get tileHeight => throw _privateConstructorUsedError;
  double get displayScale => throw _privateConstructorUsedError;
  int get defaultMapWidth => throw _privateConstructorUsedError;
  int get defaultMapHeight => throw _privateConstructorUsedError;

  /// Serializes this ProjectSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectSettingsCopyWith<ProjectSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectSettingsCopyWith<$Res> {
  factory $ProjectSettingsCopyWith(
          ProjectSettings value, $Res Function(ProjectSettings) then) =
      _$ProjectSettingsCopyWithImpl<$Res, ProjectSettings>;
  @useResult
  $Res call(
      {int tileWidth,
      int tileHeight,
      double displayScale,
      int defaultMapWidth,
      int defaultMapHeight});
}

/// @nodoc
class _$ProjectSettingsCopyWithImpl<$Res, $Val extends ProjectSettings>
    implements $ProjectSettingsCopyWith<$Res> {
  _$ProjectSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileWidth = null,
    Object? tileHeight = null,
    Object? displayScale = null,
    Object? defaultMapWidth = null,
    Object? defaultMapHeight = null,
  }) {
    return _then(_value.copyWith(
      tileWidth: null == tileWidth
          ? _value.tileWidth
          : tileWidth // ignore: cast_nullable_to_non_nullable
              as int,
      tileHeight: null == tileHeight
          ? _value.tileHeight
          : tileHeight // ignore: cast_nullable_to_non_nullable
              as int,
      displayScale: null == displayScale
          ? _value.displayScale
          : displayScale // ignore: cast_nullable_to_non_nullable
              as double,
      defaultMapWidth: null == defaultMapWidth
          ? _value.defaultMapWidth
          : defaultMapWidth // ignore: cast_nullable_to_non_nullable
              as int,
      defaultMapHeight: null == defaultMapHeight
          ? _value.defaultMapHeight
          : defaultMapHeight // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectSettingsImplCopyWith<$Res>
    implements $ProjectSettingsCopyWith<$Res> {
  factory _$$ProjectSettingsImplCopyWith(_$ProjectSettingsImpl value,
          $Res Function(_$ProjectSettingsImpl) then) =
      __$$ProjectSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int tileWidth,
      int tileHeight,
      double displayScale,
      int defaultMapWidth,
      int defaultMapHeight});
}

/// @nodoc
class __$$ProjectSettingsImplCopyWithImpl<$Res>
    extends _$ProjectSettingsCopyWithImpl<$Res, _$ProjectSettingsImpl>
    implements _$$ProjectSettingsImplCopyWith<$Res> {
  __$$ProjectSettingsImplCopyWithImpl(
      _$ProjectSettingsImpl _value, $Res Function(_$ProjectSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileWidth = null,
    Object? tileHeight = null,
    Object? displayScale = null,
    Object? defaultMapWidth = null,
    Object? defaultMapHeight = null,
  }) {
    return _then(_$ProjectSettingsImpl(
      tileWidth: null == tileWidth
          ? _value.tileWidth
          : tileWidth // ignore: cast_nullable_to_non_nullable
              as int,
      tileHeight: null == tileHeight
          ? _value.tileHeight
          : tileHeight // ignore: cast_nullable_to_non_nullable
              as int,
      displayScale: null == displayScale
          ? _value.displayScale
          : displayScale // ignore: cast_nullable_to_non_nullable
              as double,
      defaultMapWidth: null == defaultMapWidth
          ? _value.defaultMapWidth
          : defaultMapWidth // ignore: cast_nullable_to_non_nullable
              as int,
      defaultMapHeight: null == defaultMapHeight
          ? _value.defaultMapHeight
          : defaultMapHeight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectSettingsImpl implements _ProjectSettings {
  const _$ProjectSettingsImpl(
      {this.tileWidth = 16,
      this.tileHeight = 16,
      this.displayScale = 2.0,
      this.defaultMapWidth = 20,
      this.defaultMapHeight = 15});

  factory _$ProjectSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectSettingsImplFromJson(json);

  @override
  @JsonKey()
  final int tileWidth;
  @override
  @JsonKey()
  final int tileHeight;
  @override
  @JsonKey()
  final double displayScale;
  @override
  @JsonKey()
  final int defaultMapWidth;
  @override
  @JsonKey()
  final int defaultMapHeight;

  @override
  String toString() {
    return 'ProjectSettings(tileWidth: $tileWidth, tileHeight: $tileHeight, displayScale: $displayScale, defaultMapWidth: $defaultMapWidth, defaultMapHeight: $defaultMapHeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectSettingsImpl &&
            (identical(other.tileWidth, tileWidth) ||
                other.tileWidth == tileWidth) &&
            (identical(other.tileHeight, tileHeight) ||
                other.tileHeight == tileHeight) &&
            (identical(other.displayScale, displayScale) ||
                other.displayScale == displayScale) &&
            (identical(other.defaultMapWidth, defaultMapWidth) ||
                other.defaultMapWidth == defaultMapWidth) &&
            (identical(other.defaultMapHeight, defaultMapHeight) ||
                other.defaultMapHeight == defaultMapHeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tileWidth, tileHeight,
      displayScale, defaultMapWidth, defaultMapHeight);

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectSettingsImplCopyWith<_$ProjectSettingsImpl> get copyWith =>
      __$$ProjectSettingsImplCopyWithImpl<_$ProjectSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectSettingsImplToJson(
      this,
    );
  }
}

abstract class _ProjectSettings implements ProjectSettings {
  const factory _ProjectSettings(
      {final int tileWidth,
      final int tileHeight,
      final double displayScale,
      final int defaultMapWidth,
      final int defaultMapHeight}) = _$ProjectSettingsImpl;

  factory _ProjectSettings.fromJson(Map<String, dynamic> json) =
      _$ProjectSettingsImpl.fromJson;

  @override
  int get tileWidth;
  @override
  int get tileHeight;
  @override
  double get displayScale;
  @override
  int get defaultMapWidth;
  @override
  int get defaultMapHeight;

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectSettingsImplCopyWith<_$ProjectSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectMapGroup _$ProjectMapGroupFromJson(Map<String, dynamic> json) {
  return _ProjectMapGroup.fromJson(json);
}

/// @nodoc
mixin _$ProjectMapGroup {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  MapGroupType get type => throw _privateConstructorUsedError;
  String? get parentGroupId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;

  /// Serializes this ProjectMapGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectMapGroupCopyWith<ProjectMapGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectMapGroupCopyWith<$Res> {
  factory $ProjectMapGroupCopyWith(
          ProjectMapGroup value, $Res Function(ProjectMapGroup) then) =
      _$ProjectMapGroupCopyWithImpl<$Res, ProjectMapGroup>;
  @useResult
  $Res call(
      {String id,
      String name,
      MapGroupType type,
      String? parentGroupId,
      int sortOrder,
      List<String> tags,
      Map<String, dynamic> properties});
}

/// @nodoc
class _$ProjectMapGroupCopyWithImpl<$Res, $Val extends ProjectMapGroup>
    implements $ProjectMapGroupCopyWith<$Res> {
  _$ProjectMapGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? parentGroupId = freezed,
    Object? sortOrder = null,
    Object? tags = null,
    Object? properties = null,
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MapGroupType,
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectMapGroupImplCopyWith<$Res>
    implements $ProjectMapGroupCopyWith<$Res> {
  factory _$$ProjectMapGroupImplCopyWith(_$ProjectMapGroupImpl value,
          $Res Function(_$ProjectMapGroupImpl) then) =
      __$$ProjectMapGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      MapGroupType type,
      String? parentGroupId,
      int sortOrder,
      List<String> tags,
      Map<String, dynamic> properties});
}

/// @nodoc
class __$$ProjectMapGroupImplCopyWithImpl<$Res>
    extends _$ProjectMapGroupCopyWithImpl<$Res, _$ProjectMapGroupImpl>
    implements _$$ProjectMapGroupImplCopyWith<$Res> {
  __$$ProjectMapGroupImplCopyWithImpl(
      _$ProjectMapGroupImpl _value, $Res Function(_$ProjectMapGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? parentGroupId = freezed,
    Object? sortOrder = null,
    Object? tags = null,
    Object? properties = null,
  }) {
    return _then(_$ProjectMapGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MapGroupType,
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectMapGroupImpl implements _ProjectMapGroup {
  const _$ProjectMapGroupImpl(
      {required this.id,
      required this.name,
      required this.type,
      this.parentGroupId,
      this.sortOrder = 0,
      final List<String> tags = const [],
      final Map<String, dynamic> properties = const {}})
      : _tags = tags,
        _properties = properties;

  factory _$ProjectMapGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectMapGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final MapGroupType type;
  @override
  final String? parentGroupId;
  @override
  @JsonKey()
  final int sortOrder;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final Map<String, dynamic> _properties;
  @override
  @JsonKey()
  Map<String, dynamic> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'ProjectMapGroup(id: $id, name: $name, type: $type, parentGroupId: $parentGroupId, sortOrder: $sortOrder, tags: $tags, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectMapGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.parentGroupId, parentGroupId) ||
                other.parentGroupId == parentGroupId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      parentGroupId,
      sortOrder,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectMapGroupImplCopyWith<_$ProjectMapGroupImpl> get copyWith =>
      __$$ProjectMapGroupImplCopyWithImpl<_$ProjectMapGroupImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectMapGroupImplToJson(
      this,
    );
  }
}

abstract class _ProjectMapGroup implements ProjectMapGroup {
  const factory _ProjectMapGroup(
      {required final String id,
      required final String name,
      required final MapGroupType type,
      final String? parentGroupId,
      final int sortOrder,
      final List<String> tags,
      final Map<String, dynamic> properties}) = _$ProjectMapGroupImpl;

  factory _ProjectMapGroup.fromJson(Map<String, dynamic> json) =
      _$ProjectMapGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  MapGroupType get type;
  @override
  String? get parentGroupId;
  @override
  int get sortOrder;
  @override
  List<String> get tags;
  @override
  Map<String, dynamic> get properties;

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectMapGroupImplCopyWith<_$ProjectMapGroupImpl> get copyWith =>
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
  String? get groupId => throw _privateConstructorUsedError;
  MapRole get role => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

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
  $Res call(
      {String id,
      String name,
      String relativePath,
      String? groupId,
      MapRole role,
      int sortOrder});
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
    Object? groupId = freezed,
    Object? role = null,
    Object? sortOrder = null,
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
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MapRole,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
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
  $Res call(
      {String id,
      String name,
      String relativePath,
      String? groupId,
      MapRole role,
      int sortOrder});
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
    Object? groupId = freezed,
    Object? role = null,
    Object? sortOrder = null,
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
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MapRole,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectMapEntryImpl implements _ProjectMapEntry {
  const _$ProjectMapEntryImpl(
      {required this.id,
      required this.name,
      required this.relativePath,
      this.groupId,
      this.role = MapRole.exterior,
      this.sortOrder = 0});

  factory _$ProjectMapEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectMapEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String relativePath;
  @override
  final String? groupId;
  @override
  @JsonKey()
  final MapRole role;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectMapEntry(id: $id, name: $name, relativePath: $relativePath, groupId: $groupId, role: $role, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectMapEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, relativePath, groupId, role, sortOrder);

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
      required final String relativePath,
      final String? groupId,
      final MapRole role,
      final int sortOrder}) = _$ProjectMapEntryImpl;

  factory _ProjectMapEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectMapEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get relativePath;
  @override
  String? get groupId;
  @override
  MapRole get role;
  @override
  int get sortOrder;

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
