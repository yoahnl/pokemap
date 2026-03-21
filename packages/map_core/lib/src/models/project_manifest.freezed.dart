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
  List<ProjectElementCategory> get elementCategories =>
      throw _privateConstructorUsedError;
  List<ProjectElementEntry> get elements => throw _privateConstructorUsedError;
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
      List<ProjectElementCategory> elementCategories,
      List<ProjectElementEntry> elements,
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
    Object? elementCategories = null,
    Object? elements = null,
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
      elementCategories: null == elementCategories
          ? _value.elementCategories
          : elementCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectElementCategory>,
      elements: null == elements
          ? _value.elements
          : elements // ignore: cast_nullable_to_non_nullable
              as List<ProjectElementEntry>,
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
      List<ProjectElementCategory> elementCategories,
      List<ProjectElementEntry> elements,
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
    Object? elementCategories = null,
    Object? elements = null,
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
      elementCategories: null == elementCategories
          ? _value._elementCategories
          : elementCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectElementCategory>,
      elements: null == elements
          ? _value._elements
          : elements // ignore: cast_nullable_to_non_nullable
              as List<ProjectElementEntry>,
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
      final List<ProjectElementCategory> elementCategories = const [],
      final List<ProjectElementEntry> elements = const [],
      this.settings = const ProjectSettings(),
      final Map<String, dynamic> globalProperties = const {}})
      : _maps = maps,
        _groups = groups,
        _tilesets = tilesets,
        _elementCategories = elementCategories,
        _elements = elements,
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

  final List<ProjectElementCategory> _elementCategories;
  @override
  @JsonKey()
  List<ProjectElementCategory> get elementCategories {
    if (_elementCategories is EqualUnmodifiableListView)
      return _elementCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_elementCategories);
  }

  final List<ProjectElementEntry> _elements;
  @override
  @JsonKey()
  List<ProjectElementEntry> get elements {
    if (_elements is EqualUnmodifiableListView) return _elements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_elements);
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
    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, settings: $settings, globalProperties: $globalProperties)';
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
            const DeepCollectionEquality()
                .equals(other._elementCategories, _elementCategories) &&
            const DeepCollectionEquality().equals(other._elements, _elements) &&
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
      const DeepCollectionEquality().hash(_elementCategories),
      const DeepCollectionEquality().hash(_elements),
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
      final List<ProjectElementCategory> elementCategories,
      final List<ProjectElementEntry> elements,
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
  List<ProjectElementCategory> get elementCategories;
  @override
  List<ProjectElementEntry> get elements;
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
  TilesetScope get scope => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  bool get isWorldTileset => throw _privateConstructorUsedError;
  List<TilesetElementGroup> get elementGroups =>
      throw _privateConstructorUsedError;
  List<TilesetPaletteEntry> get paletteEntries =>
      throw _privateConstructorUsedError;

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
  $Res call(
      {String id,
      String name,
      String relativePath,
      TilesetScope scope,
      String? groupId,
      int sortOrder,
      bool isWorldTileset,
      List<TilesetElementGroup> elementGroups,
      List<TilesetPaletteEntry> paletteEntries});
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
    Object? scope = null,
    Object? groupId = freezed,
    Object? sortOrder = null,
    Object? isWorldTileset = null,
    Object? elementGroups = null,
    Object? paletteEntries = null,
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
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as TilesetScope,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isWorldTileset: null == isWorldTileset
          ? _value.isWorldTileset
          : isWorldTileset // ignore: cast_nullable_to_non_nullable
              as bool,
      elementGroups: null == elementGroups
          ? _value.elementGroups
          : elementGroups // ignore: cast_nullable_to_non_nullable
              as List<TilesetElementGroup>,
      paletteEntries: null == paletteEntries
          ? _value.paletteEntries
          : paletteEntries // ignore: cast_nullable_to_non_nullable
              as List<TilesetPaletteEntry>,
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
  $Res call(
      {String id,
      String name,
      String relativePath,
      TilesetScope scope,
      String? groupId,
      int sortOrder,
      bool isWorldTileset,
      List<TilesetElementGroup> elementGroups,
      List<TilesetPaletteEntry> paletteEntries});
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
    Object? scope = null,
    Object? groupId = freezed,
    Object? sortOrder = null,
    Object? isWorldTileset = null,
    Object? elementGroups = null,
    Object? paletteEntries = null,
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
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as TilesetScope,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isWorldTileset: null == isWorldTileset
          ? _value.isWorldTileset
          : isWorldTileset // ignore: cast_nullable_to_non_nullable
              as bool,
      elementGroups: null == elementGroups
          ? _value._elementGroups
          : elementGroups // ignore: cast_nullable_to_non_nullable
              as List<TilesetElementGroup>,
      paletteEntries: null == paletteEntries
          ? _value._paletteEntries
          : paletteEntries // ignore: cast_nullable_to_non_nullable
              as List<TilesetPaletteEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTilesetEntryImpl implements _ProjectTilesetEntry {
  const _$ProjectTilesetEntryImpl(
      {required this.id,
      required this.name,
      required this.relativePath,
      this.scope = TilesetScope.global,
      this.groupId,
      this.sortOrder = 0,
      this.isWorldTileset = false,
      final List<TilesetElementGroup> elementGroups = const [],
      final List<TilesetPaletteEntry> paletteEntries = const []})
      : _elementGroups = elementGroups,
        _paletteEntries = paletteEntries;

  factory _$ProjectTilesetEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTilesetEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String relativePath;
  @override
  @JsonKey()
  final TilesetScope scope;
  @override
  final String? groupId;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  @JsonKey()
  final bool isWorldTileset;
  final List<TilesetElementGroup> _elementGroups;
  @override
  @JsonKey()
  List<TilesetElementGroup> get elementGroups {
    if (_elementGroups is EqualUnmodifiableListView) return _elementGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_elementGroups);
  }

  final List<TilesetPaletteEntry> _paletteEntries;
  @override
  @JsonKey()
  List<TilesetPaletteEntry> get paletteEntries {
    if (_paletteEntries is EqualUnmodifiableListView) return _paletteEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_paletteEntries);
  }

  @override
  String toString() {
    return 'ProjectTilesetEntry(id: $id, name: $name, relativePath: $relativePath, scope: $scope, groupId: $groupId, sortOrder: $sortOrder, isWorldTileset: $isWorldTileset, elementGroups: $elementGroups, paletteEntries: $paletteEntries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTilesetEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isWorldTileset, isWorldTileset) ||
                other.isWorldTileset == isWorldTileset) &&
            const DeepCollectionEquality()
                .equals(other._elementGroups, _elementGroups) &&
            const DeepCollectionEquality()
                .equals(other._paletteEntries, _paletteEntries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      relativePath,
      scope,
      groupId,
      sortOrder,
      isWorldTileset,
      const DeepCollectionEquality().hash(_elementGroups),
      const DeepCollectionEquality().hash(_paletteEntries));

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
          required final String relativePath,
          final TilesetScope scope,
          final String? groupId,
          final int sortOrder,
          final bool isWorldTileset,
          final List<TilesetElementGroup> elementGroups,
          final List<TilesetPaletteEntry> paletteEntries}) =
      _$ProjectTilesetEntryImpl;

  factory _ProjectTilesetEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectTilesetEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get relativePath;
  @override
  TilesetScope get scope;
  @override
  String? get groupId;
  @override
  int get sortOrder;
  @override
  bool get isWorldTileset;
  @override
  List<TilesetElementGroup> get elementGroups;
  @override
  List<TilesetPaletteEntry> get paletteEntries;

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTilesetEntryImplCopyWith<_$ProjectTilesetEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TilesetPaletteEntry _$TilesetPaletteEntryFromJson(Map<String, dynamic> json) {
  return _TilesetPaletteEntry.fromJson(json);
}

/// @nodoc
mixin _$TilesetPaletteEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  PaletteCategory get category => throw _privateConstructorUsedError;
  TilesetSourceRect get source => throw _privateConstructorUsedError;
  String? get recommendedLayerId => throw _privateConstructorUsedError;

  /// Serializes this TilesetPaletteEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilesetPaletteEntryCopyWith<TilesetPaletteEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilesetPaletteEntryCopyWith<$Res> {
  factory $TilesetPaletteEntryCopyWith(
          TilesetPaletteEntry value, $Res Function(TilesetPaletteEntry) then) =
      _$TilesetPaletteEntryCopyWithImpl<$Res, TilesetPaletteEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      PaletteCategory category,
      TilesetSourceRect source,
      String? recommendedLayerId});

  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class _$TilesetPaletteEntryCopyWithImpl<$Res, $Val extends TilesetPaletteEntry>
    implements $TilesetPaletteEntryCopyWith<$Res> {
  _$TilesetPaletteEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? source = null,
    Object? recommendedLayerId = freezed,
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
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PaletteCategory,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TilesetSourceRectCopyWith<$Res> get source {
    return $TilesetSourceRectCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TilesetPaletteEntryImplCopyWith<$Res>
    implements $TilesetPaletteEntryCopyWith<$Res> {
  factory _$$TilesetPaletteEntryImplCopyWith(_$TilesetPaletteEntryImpl value,
          $Res Function(_$TilesetPaletteEntryImpl) then) =
      __$$TilesetPaletteEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      PaletteCategory category,
      TilesetSourceRect source,
      String? recommendedLayerId});

  @override
  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class __$$TilesetPaletteEntryImplCopyWithImpl<$Res>
    extends _$TilesetPaletteEntryCopyWithImpl<$Res, _$TilesetPaletteEntryImpl>
    implements _$$TilesetPaletteEntryImplCopyWith<$Res> {
  __$$TilesetPaletteEntryImplCopyWithImpl(_$TilesetPaletteEntryImpl _value,
      $Res Function(_$TilesetPaletteEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? source = null,
    Object? recommendedLayerId = freezed,
  }) {
    return _then(_$TilesetPaletteEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PaletteCategory,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TilesetPaletteEntryImpl implements _TilesetPaletteEntry {
  const _$TilesetPaletteEntryImpl(
      {required this.id,
      this.name = '',
      this.category = PaletteCategory.uncategorized,
      required this.source,
      this.recommendedLayerId});

  factory _$TilesetPaletteEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilesetPaletteEntryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final PaletteCategory category;
  @override
  final TilesetSourceRect source;
  @override
  final String? recommendedLayerId;

  @override
  String toString() {
    return 'TilesetPaletteEntry(id: $id, name: $name, category: $category, source: $source, recommendedLayerId: $recommendedLayerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilesetPaletteEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.recommendedLayerId, recommendedLayerId) ||
                other.recommendedLayerId == recommendedLayerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, category, source, recommendedLayerId);

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilesetPaletteEntryImplCopyWith<_$TilesetPaletteEntryImpl> get copyWith =>
      __$$TilesetPaletteEntryImplCopyWithImpl<_$TilesetPaletteEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilesetPaletteEntryImplToJson(
      this,
    );
  }
}

abstract class _TilesetPaletteEntry implements TilesetPaletteEntry {
  const factory _TilesetPaletteEntry(
      {required final String id,
      final String name,
      final PaletteCategory category,
      required final TilesetSourceRect source,
      final String? recommendedLayerId}) = _$TilesetPaletteEntryImpl;

  factory _TilesetPaletteEntry.fromJson(Map<String, dynamic> json) =
      _$TilesetPaletteEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  PaletteCategory get category;
  @override
  TilesetSourceRect get source;
  @override
  String? get recommendedLayerId;

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilesetPaletteEntryImplCopyWith<_$TilesetPaletteEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TilesetSourceRect _$TilesetSourceRectFromJson(Map<String, dynamic> json) {
  return _TilesetSourceRect.fromJson(json);
}

/// @nodoc
mixin _$TilesetSourceRect {
  int get x => throw _privateConstructorUsedError;
  int get y => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;

  /// Serializes this TilesetSourceRect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilesetSourceRectCopyWith<TilesetSourceRect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilesetSourceRectCopyWith<$Res> {
  factory $TilesetSourceRectCopyWith(
          TilesetSourceRect value, $Res Function(TilesetSourceRect) then) =
      _$TilesetSourceRectCopyWithImpl<$Res, TilesetSourceRect>;
  @useResult
  $Res call({int x, int y, int width, int height});
}

/// @nodoc
class _$TilesetSourceRectCopyWithImpl<$Res, $Val extends TilesetSourceRect>
    implements $TilesetSourceRectCopyWith<$Res> {
  _$TilesetSourceRectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TilesetSourceRectImplCopyWith<$Res>
    implements $TilesetSourceRectCopyWith<$Res> {
  factory _$$TilesetSourceRectImplCopyWith(_$TilesetSourceRectImpl value,
          $Res Function(_$TilesetSourceRectImpl) then) =
      __$$TilesetSourceRectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int x, int y, int width, int height});
}

/// @nodoc
class __$$TilesetSourceRectImplCopyWithImpl<$Res>
    extends _$TilesetSourceRectCopyWithImpl<$Res, _$TilesetSourceRectImpl>
    implements _$$TilesetSourceRectImplCopyWith<$Res> {
  __$$TilesetSourceRectImplCopyWithImpl(_$TilesetSourceRectImpl _value,
      $Res Function(_$TilesetSourceRectImpl) _then)
      : super(_value, _then);

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$TilesetSourceRectImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TilesetSourceRectImpl implements _TilesetSourceRect {
  const _$TilesetSourceRectImpl(
      {required this.x, required this.y, this.width = 1, this.height = 1});

  factory _$TilesetSourceRectImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilesetSourceRectImplFromJson(json);

  @override
  final int x;
  @override
  final int y;
  @override
  @JsonKey()
  final int width;
  @override
  @JsonKey()
  final int height;

  @override
  String toString() {
    return 'TilesetSourceRect(x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilesetSourceRectImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y, width, height);

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilesetSourceRectImplCopyWith<_$TilesetSourceRectImpl> get copyWith =>
      __$$TilesetSourceRectImplCopyWithImpl<_$TilesetSourceRectImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilesetSourceRectImplToJson(
      this,
    );
  }
}

abstract class _TilesetSourceRect implements TilesetSourceRect {
  const factory _TilesetSourceRect(
      {required final int x,
      required final int y,
      final int width,
      final int height}) = _$TilesetSourceRectImpl;

  factory _TilesetSourceRect.fromJson(Map<String, dynamic> json) =
      _$TilesetSourceRectImpl.fromJson;

  @override
  int get x;
  @override
  int get y;
  @override
  int get width;
  @override
  int get height;

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilesetSourceRectImplCopyWith<_$TilesetSourceRectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TilesetElementGroup _$TilesetElementGroupFromJson(Map<String, dynamic> json) {
  return _TilesetElementGroup.fromJson(json);
}

/// @nodoc
mixin _$TilesetElementGroup {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentGroupId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this TilesetElementGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilesetElementGroupCopyWith<TilesetElementGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilesetElementGroupCopyWith<$Res> {
  factory $TilesetElementGroupCopyWith(
          TilesetElementGroup value, $Res Function(TilesetElementGroup) then) =
      _$TilesetElementGroupCopyWithImpl<$Res, TilesetElementGroup>;
  @useResult
  $Res call({String id, String name, String? parentGroupId, int sortOrder});
}

/// @nodoc
class _$TilesetElementGroupCopyWithImpl<$Res, $Val extends TilesetElementGroup>
    implements $TilesetElementGroupCopyWith<$Res> {
  _$TilesetElementGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentGroupId = freezed,
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
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TilesetElementGroupImplCopyWith<$Res>
    implements $TilesetElementGroupCopyWith<$Res> {
  factory _$$TilesetElementGroupImplCopyWith(_$TilesetElementGroupImpl value,
          $Res Function(_$TilesetElementGroupImpl) then) =
      __$$TilesetElementGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentGroupId, int sortOrder});
}

/// @nodoc
class __$$TilesetElementGroupImplCopyWithImpl<$Res>
    extends _$TilesetElementGroupCopyWithImpl<$Res, _$TilesetElementGroupImpl>
    implements _$$TilesetElementGroupImplCopyWith<$Res> {
  __$$TilesetElementGroupImplCopyWithImpl(_$TilesetElementGroupImpl _value,
      $Res Function(_$TilesetElementGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentGroupId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$TilesetElementGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TilesetElementGroupImpl implements _TilesetElementGroup {
  const _$TilesetElementGroupImpl(
      {required this.id,
      required this.name,
      this.parentGroupId,
      this.sortOrder = 0});

  factory _$TilesetElementGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilesetElementGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentGroupId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'TilesetElementGroup(id: $id, name: $name, parentGroupId: $parentGroupId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilesetElementGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentGroupId, parentGroupId) ||
                other.parentGroupId == parentGroupId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, parentGroupId, sortOrder);

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilesetElementGroupImplCopyWith<_$TilesetElementGroupImpl> get copyWith =>
      __$$TilesetElementGroupImplCopyWithImpl<_$TilesetElementGroupImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilesetElementGroupImplToJson(
      this,
    );
  }
}

abstract class _TilesetElementGroup implements TilesetElementGroup {
  const factory _TilesetElementGroup(
      {required final String id,
      required final String name,
      final String? parentGroupId,
      final int sortOrder}) = _$TilesetElementGroupImpl;

  factory _TilesetElementGroup.fromJson(Map<String, dynamic> json) =
      _$TilesetElementGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentGroupId;
  @override
  int get sortOrder;

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilesetElementGroupImplCopyWith<_$TilesetElementGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectElementCategory _$ProjectElementCategoryFromJson(
    Map<String, dynamic> json) {
  return _ProjectElementCategory.fromJson(json);
}

/// @nodoc
mixin _$ProjectElementCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentCategoryId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectElementCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectElementCategoryCopyWith<ProjectElementCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectElementCategoryCopyWith<$Res> {
  factory $ProjectElementCategoryCopyWith(ProjectElementCategory value,
          $Res Function(ProjectElementCategory) then) =
      _$ProjectElementCategoryCopyWithImpl<$Res, ProjectElementCategory>;
  @useResult
  $Res call({String id, String name, String? parentCategoryId, int sortOrder});
}

/// @nodoc
class _$ProjectElementCategoryCopyWithImpl<$Res,
        $Val extends ProjectElementCategory>
    implements $ProjectElementCategoryCopyWith<$Res> {
  _$ProjectElementCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentCategoryId = freezed,
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
      parentCategoryId: freezed == parentCategoryId
          ? _value.parentCategoryId
          : parentCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectElementCategoryImplCopyWith<$Res>
    implements $ProjectElementCategoryCopyWith<$Res> {
  factory _$$ProjectElementCategoryImplCopyWith(
          _$ProjectElementCategoryImpl value,
          $Res Function(_$ProjectElementCategoryImpl) then) =
      __$$ProjectElementCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentCategoryId, int sortOrder});
}

/// @nodoc
class __$$ProjectElementCategoryImplCopyWithImpl<$Res>
    extends _$ProjectElementCategoryCopyWithImpl<$Res,
        _$ProjectElementCategoryImpl>
    implements _$$ProjectElementCategoryImplCopyWith<$Res> {
  __$$ProjectElementCategoryImplCopyWithImpl(
      _$ProjectElementCategoryImpl _value,
      $Res Function(_$ProjectElementCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentCategoryId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectElementCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentCategoryId: freezed == parentCategoryId
          ? _value.parentCategoryId
          : parentCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectElementCategoryImpl implements _ProjectElementCategory {
  const _$ProjectElementCategoryImpl(
      {required this.id,
      required this.name,
      this.parentCategoryId,
      this.sortOrder = 0});

  factory _$ProjectElementCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectElementCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentCategoryId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectElementCategory(id: $id, name: $name, parentCategoryId: $parentCategoryId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectElementCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentCategoryId, parentCategoryId) ||
                other.parentCategoryId == parentCategoryId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, parentCategoryId, sortOrder);

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectElementCategoryImplCopyWith<_$ProjectElementCategoryImpl>
      get copyWith => __$$ProjectElementCategoryImplCopyWithImpl<
          _$ProjectElementCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectElementCategoryImplToJson(
      this,
    );
  }
}

abstract class _ProjectElementCategory implements ProjectElementCategory {
  const factory _ProjectElementCategory(
      {required final String id,
      required final String name,
      final String? parentCategoryId,
      final int sortOrder}) = _$ProjectElementCategoryImpl;

  factory _ProjectElementCategory.fromJson(Map<String, dynamic> json) =
      _$ProjectElementCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentCategoryId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectElementCategoryImplCopyWith<_$ProjectElementCategoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectElementEntry _$ProjectElementEntryFromJson(Map<String, dynamic> json) {
  return _ProjectElementEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectElementEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  String? get tilesetGroupId => throw _privateConstructorUsedError;
  TilesetSourceRect get source => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  String? get recommendedLayerId => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectElementEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectElementEntryCopyWith<ProjectElementEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectElementEntryCopyWith<$Res> {
  factory $ProjectElementEntryCopyWith(
          ProjectElementEntry value, $Res Function(ProjectElementEntry) then) =
      _$ProjectElementEntryCopyWithImpl<$Res, ProjectElementEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      String categoryId,
      String? tilesetGroupId,
      TilesetSourceRect source,
      String? groupId,
      String? recommendedLayerId,
      List<String> tags,
      int sortOrder});

  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class _$ProjectElementEntryCopyWithImpl<$Res, $Val extends ProjectElementEntry>
    implements $ProjectElementEntryCopyWith<$Res> {
  _$ProjectElementEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? categoryId = null,
    Object? tilesetGroupId = freezed,
    Object? source = null,
    Object? groupId = freezed,
    Object? recommendedLayerId = freezed,
    Object? tags = null,
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
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetGroupId: freezed == tilesetGroupId
          ? _value.tilesetGroupId
          : tilesetGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TilesetSourceRectCopyWith<$Res> get source {
    return $TilesetSourceRectCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectElementEntryImplCopyWith<$Res>
    implements $ProjectElementEntryCopyWith<$Res> {
  factory _$$ProjectElementEntryImplCopyWith(_$ProjectElementEntryImpl value,
          $Res Function(_$ProjectElementEntryImpl) then) =
      __$$ProjectElementEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      String categoryId,
      String? tilesetGroupId,
      TilesetSourceRect source,
      String? groupId,
      String? recommendedLayerId,
      List<String> tags,
      int sortOrder});

  @override
  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class __$$ProjectElementEntryImplCopyWithImpl<$Res>
    extends _$ProjectElementEntryCopyWithImpl<$Res, _$ProjectElementEntryImpl>
    implements _$$ProjectElementEntryImplCopyWith<$Res> {
  __$$ProjectElementEntryImplCopyWithImpl(_$ProjectElementEntryImpl _value,
      $Res Function(_$ProjectElementEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? categoryId = null,
    Object? tilesetGroupId = freezed,
    Object? source = null,
    Object? groupId = freezed,
    Object? recommendedLayerId = freezed,
    Object? tags = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectElementEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetGroupId: freezed == tilesetGroupId
          ? _value.tilesetGroupId
          : tilesetGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectElementEntryImpl implements _ProjectElementEntry {
  const _$ProjectElementEntryImpl(
      {required this.id,
      required this.name,
      required this.tilesetId,
      required this.categoryId,
      this.tilesetGroupId,
      required this.source,
      this.groupId,
      this.recommendedLayerId,
      final List<String> tags = const [],
      this.sortOrder = 0})
      : _tags = tags;

  factory _$ProjectElementEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectElementEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String tilesetId;
  @override
  final String categoryId;
  @override
  final String? tilesetGroupId;
  @override
  final TilesetSourceRect source;
  @override
  final String? groupId;
  @override
  final String? recommendedLayerId;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectElementEntry(id: $id, name: $name, tilesetId: $tilesetId, categoryId: $categoryId, tilesetGroupId: $tilesetGroupId, source: $source, groupId: $groupId, recommendedLayerId: $recommendedLayerId, tags: $tags, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectElementEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.tilesetGroupId, tilesetGroupId) ||
                other.tilesetGroupId == tilesetGroupId) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.recommendedLayerId, recommendedLayerId) ||
                other.recommendedLayerId == recommendedLayerId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      tilesetId,
      categoryId,
      tilesetGroupId,
      source,
      groupId,
      recommendedLayerId,
      const DeepCollectionEquality().hash(_tags),
      sortOrder);

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectElementEntryImplCopyWith<_$ProjectElementEntryImpl> get copyWith =>
      __$$ProjectElementEntryImplCopyWithImpl<_$ProjectElementEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectElementEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectElementEntry implements ProjectElementEntry {
  const factory _ProjectElementEntry(
      {required final String id,
      required final String name,
      required final String tilesetId,
      required final String categoryId,
      final String? tilesetGroupId,
      required final TilesetSourceRect source,
      final String? groupId,
      final String? recommendedLayerId,
      final List<String> tags,
      final int sortOrder}) = _$ProjectElementEntryImpl;

  factory _ProjectElementEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectElementEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get tilesetId;
  @override
  String get categoryId;
  @override
  String? get tilesetGroupId;
  @override
  TilesetSourceRect get source;
  @override
  String? get groupId;
  @override
  String? get recommendedLayerId;
  @override
  List<String> get tags;
  @override
  int get sortOrder;

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectElementEntryImplCopyWith<_$ProjectElementEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
