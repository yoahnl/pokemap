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
  List<ProjectTilesetFolder> get tilesetFolders =>
      throw _privateConstructorUsedError;
  List<ProjectTilesetEntry> get tilesets => throw _privateConstructorUsedError;
  List<ProjectElementCategory> get elementCategories =>
      throw _privateConstructorUsedError;
  List<ProjectElementEntry> get elements => throw _privateConstructorUsedError;
  List<ProjectPresetCategory> get terrainCategories =>
      throw _privateConstructorUsedError;
  List<ProjectPresetCategory> get pathCategories =>
      throw _privateConstructorUsedError;
  List<ProjectTerrainPreset> get terrainPresets =>
      throw _privateConstructorUsedError;
  List<ProjectPathPreset> get pathPresets => throw _privateConstructorUsedError;
  List<ProjectEncounterTable> get encounterTables =>
      throw _privateConstructorUsedError;
  List<ProjectDialogueFolder> get dialogueFolders =>
      throw _privateConstructorUsedError;
  List<ProjectDialogueEntry> get dialogues =>
      throw _privateConstructorUsedError;
  List<ProjectTrainerEntry> get trainers => throw _privateConstructorUsedError;
  List<ProjectCharacterEntry> get characters =>
      throw _privateConstructorUsedError;
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
      List<ProjectTilesetFolder> tilesetFolders,
      List<ProjectTilesetEntry> tilesets,
      List<ProjectElementCategory> elementCategories,
      List<ProjectElementEntry> elements,
      List<ProjectPresetCategory> terrainCategories,
      List<ProjectPresetCategory> pathCategories,
      List<ProjectTerrainPreset> terrainPresets,
      List<ProjectPathPreset> pathPresets,
      List<ProjectEncounterTable> encounterTables,
      List<ProjectDialogueFolder> dialogueFolders,
      List<ProjectDialogueEntry> dialogues,
      List<ProjectTrainerEntry> trainers,
      List<ProjectCharacterEntry> characters,
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
    Object? tilesetFolders = null,
    Object? tilesets = null,
    Object? elementCategories = null,
    Object? elements = null,
    Object? terrainCategories = null,
    Object? pathCategories = null,
    Object? terrainPresets = null,
    Object? pathPresets = null,
    Object? encounterTables = null,
    Object? dialogueFolders = null,
    Object? dialogues = null,
    Object? trainers = null,
    Object? characters = null,
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
      tilesetFolders: null == tilesetFolders
          ? _value.tilesetFolders
          : tilesetFolders // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetFolder>,
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
      terrainCategories: null == terrainCategories
          ? _value.terrainCategories
          : terrainCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectPresetCategory>,
      pathCategories: null == pathCategories
          ? _value.pathCategories
          : pathCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectPresetCategory>,
      terrainPresets: null == terrainPresets
          ? _value.terrainPresets
          : terrainPresets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTerrainPreset>,
      pathPresets: null == pathPresets
          ? _value.pathPresets
          : pathPresets // ignore: cast_nullable_to_non_nullable
              as List<ProjectPathPreset>,
      encounterTables: null == encounterTables
          ? _value.encounterTables
          : encounterTables // ignore: cast_nullable_to_non_nullable
              as List<ProjectEncounterTable>,
      dialogueFolders: null == dialogueFolders
          ? _value.dialogueFolders
          : dialogueFolders // ignore: cast_nullable_to_non_nullable
              as List<ProjectDialogueFolder>,
      dialogues: null == dialogues
          ? _value.dialogues
          : dialogues // ignore: cast_nullable_to_non_nullable
              as List<ProjectDialogueEntry>,
      trainers: null == trainers
          ? _value.trainers
          : trainers // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerEntry>,
      characters: null == characters
          ? _value.characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<ProjectCharacterEntry>,
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
      List<ProjectTilesetFolder> tilesetFolders,
      List<ProjectTilesetEntry> tilesets,
      List<ProjectElementCategory> elementCategories,
      List<ProjectElementEntry> elements,
      List<ProjectPresetCategory> terrainCategories,
      List<ProjectPresetCategory> pathCategories,
      List<ProjectTerrainPreset> terrainPresets,
      List<ProjectPathPreset> pathPresets,
      List<ProjectEncounterTable> encounterTables,
      List<ProjectDialogueFolder> dialogueFolders,
      List<ProjectDialogueEntry> dialogues,
      List<ProjectTrainerEntry> trainers,
      List<ProjectCharacterEntry> characters,
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
    Object? tilesetFolders = null,
    Object? tilesets = null,
    Object? elementCategories = null,
    Object? elements = null,
    Object? terrainCategories = null,
    Object? pathCategories = null,
    Object? terrainPresets = null,
    Object? pathPresets = null,
    Object? encounterTables = null,
    Object? dialogueFolders = null,
    Object? dialogues = null,
    Object? trainers = null,
    Object? characters = null,
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
      tilesetFolders: null == tilesetFolders
          ? _value._tilesetFolders
          : tilesetFolders // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetFolder>,
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
      terrainCategories: null == terrainCategories
          ? _value._terrainCategories
          : terrainCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectPresetCategory>,
      pathCategories: null == pathCategories
          ? _value._pathCategories
          : pathCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectPresetCategory>,
      terrainPresets: null == terrainPresets
          ? _value._terrainPresets
          : terrainPresets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTerrainPreset>,
      pathPresets: null == pathPresets
          ? _value._pathPresets
          : pathPresets // ignore: cast_nullable_to_non_nullable
              as List<ProjectPathPreset>,
      encounterTables: null == encounterTables
          ? _value._encounterTables
          : encounterTables // ignore: cast_nullable_to_non_nullable
              as List<ProjectEncounterTable>,
      dialogueFolders: null == dialogueFolders
          ? _value._dialogueFolders
          : dialogueFolders // ignore: cast_nullable_to_non_nullable
              as List<ProjectDialogueFolder>,
      dialogues: null == dialogues
          ? _value._dialogues
          : dialogues // ignore: cast_nullable_to_non_nullable
              as List<ProjectDialogueEntry>,
      trainers: null == trainers
          ? _value._trainers
          : trainers // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerEntry>,
      characters: null == characters
          ? _value._characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<ProjectCharacterEntry>,
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
      final List<ProjectTilesetFolder> tilesetFolders = const [],
      required final List<ProjectTilesetEntry> tilesets,
      final List<ProjectElementCategory> elementCategories = const [],
      final List<ProjectElementEntry> elements = const [],
      final List<ProjectPresetCategory> terrainCategories = const [],
      final List<ProjectPresetCategory> pathCategories = const [],
      final List<ProjectTerrainPreset> terrainPresets = const [],
      final List<ProjectPathPreset> pathPresets = const [],
      final List<ProjectEncounterTable> encounterTables = const [],
      final List<ProjectDialogueFolder> dialogueFolders = const [],
      final List<ProjectDialogueEntry> dialogues = const [],
      final List<ProjectTrainerEntry> trainers = const [],
      final List<ProjectCharacterEntry> characters = const [],
      this.settings = const ProjectSettings(),
      final Map<String, dynamic> globalProperties = const {}})
      : _maps = maps,
        _groups = groups,
        _tilesetFolders = tilesetFolders,
        _tilesets = tilesets,
        _elementCategories = elementCategories,
        _elements = elements,
        _terrainCategories = terrainCategories,
        _pathCategories = pathCategories,
        _terrainPresets = terrainPresets,
        _pathPresets = pathPresets,
        _encounterTables = encounterTables,
        _dialogueFolders = dialogueFolders,
        _dialogues = dialogues,
        _trainers = trainers,
        _characters = characters,
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

  final List<ProjectTilesetFolder> _tilesetFolders;
  @override
  @JsonKey()
  List<ProjectTilesetFolder> get tilesetFolders {
    if (_tilesetFolders is EqualUnmodifiableListView) return _tilesetFolders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tilesetFolders);
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

  final List<ProjectPresetCategory> _terrainCategories;
  @override
  @JsonKey()
  List<ProjectPresetCategory> get terrainCategories {
    if (_terrainCategories is EqualUnmodifiableListView)
      return _terrainCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_terrainCategories);
  }

  final List<ProjectPresetCategory> _pathCategories;
  @override
  @JsonKey()
  List<ProjectPresetCategory> get pathCategories {
    if (_pathCategories is EqualUnmodifiableListView) return _pathCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pathCategories);
  }

  final List<ProjectTerrainPreset> _terrainPresets;
  @override
  @JsonKey()
  List<ProjectTerrainPreset> get terrainPresets {
    if (_terrainPresets is EqualUnmodifiableListView) return _terrainPresets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_terrainPresets);
  }

  final List<ProjectPathPreset> _pathPresets;
  @override
  @JsonKey()
  List<ProjectPathPreset> get pathPresets {
    if (_pathPresets is EqualUnmodifiableListView) return _pathPresets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pathPresets);
  }

  final List<ProjectEncounterTable> _encounterTables;
  @override
  @JsonKey()
  List<ProjectEncounterTable> get encounterTables {
    if (_encounterTables is EqualUnmodifiableListView) return _encounterTables;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_encounterTables);
  }

  final List<ProjectDialogueFolder> _dialogueFolders;
  @override
  @JsonKey()
  List<ProjectDialogueFolder> get dialogueFolders {
    if (_dialogueFolders is EqualUnmodifiableListView) return _dialogueFolders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dialogueFolders);
  }

  final List<ProjectDialogueEntry> _dialogues;
  @override
  @JsonKey()
  List<ProjectDialogueEntry> get dialogues {
    if (_dialogues is EqualUnmodifiableListView) return _dialogues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dialogues);
  }

  final List<ProjectTrainerEntry> _trainers;
  @override
  @JsonKey()
  List<ProjectTrainerEntry> get trainers {
    if (_trainers is EqualUnmodifiableListView) return _trainers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_trainers);
  }

  final List<ProjectCharacterEntry> _characters;
  @override
  @JsonKey()
  List<ProjectCharacterEntry> get characters {
    if (_characters is EqualUnmodifiableListView) return _characters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_characters);
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
    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, trainers: $trainers, characters: $characters, settings: $settings, globalProperties: $globalProperties)';
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
            const DeepCollectionEquality()
                .equals(other._tilesetFolders, _tilesetFolders) &&
            const DeepCollectionEquality().equals(other._tilesets, _tilesets) &&
            const DeepCollectionEquality()
                .equals(other._elementCategories, _elementCategories) &&
            const DeepCollectionEquality().equals(other._elements, _elements) &&
            const DeepCollectionEquality()
                .equals(other._terrainCategories, _terrainCategories) &&
            const DeepCollectionEquality()
                .equals(other._pathCategories, _pathCategories) &&
            const DeepCollectionEquality()
                .equals(other._terrainPresets, _terrainPresets) &&
            const DeepCollectionEquality()
                .equals(other._pathPresets, _pathPresets) &&
            const DeepCollectionEquality()
                .equals(other._encounterTables, _encounterTables) &&
            const DeepCollectionEquality()
                .equals(other._dialogueFolders, _dialogueFolders) &&
            const DeepCollectionEquality()
                .equals(other._dialogues, _dialogues) &&
            const DeepCollectionEquality().equals(other._trainers, _trainers) &&
            const DeepCollectionEquality()
                .equals(other._characters, _characters) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            const DeepCollectionEquality()
                .equals(other._globalProperties, _globalProperties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        name,
        version,
        const DeepCollectionEquality().hash(_maps),
        const DeepCollectionEquality().hash(_groups),
        const DeepCollectionEquality().hash(_tilesetFolders),
        const DeepCollectionEquality().hash(_tilesets),
        const DeepCollectionEquality().hash(_elementCategories),
        const DeepCollectionEquality().hash(_elements),
        const DeepCollectionEquality().hash(_terrainCategories),
        const DeepCollectionEquality().hash(_pathCategories),
        const DeepCollectionEquality().hash(_terrainPresets),
        const DeepCollectionEquality().hash(_pathPresets),
        const DeepCollectionEquality().hash(_encounterTables),
        const DeepCollectionEquality().hash(_dialogueFolders),
        const DeepCollectionEquality().hash(_dialogues),
        const DeepCollectionEquality().hash(_trainers),
        const DeepCollectionEquality().hash(_characters),
        settings,
        const DeepCollectionEquality().hash(_globalProperties)
      ]);

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
      final List<ProjectTilesetFolder> tilesetFolders,
      required final List<ProjectTilesetEntry> tilesets,
      final List<ProjectElementCategory> elementCategories,
      final List<ProjectElementEntry> elements,
      final List<ProjectPresetCategory> terrainCategories,
      final List<ProjectPresetCategory> pathCategories,
      final List<ProjectTerrainPreset> terrainPresets,
      final List<ProjectPathPreset> pathPresets,
      final List<ProjectEncounterTable> encounterTables,
      final List<ProjectDialogueFolder> dialogueFolders,
      final List<ProjectDialogueEntry> dialogues,
      final List<ProjectTrainerEntry> trainers,
      final List<ProjectCharacterEntry> characters,
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
  List<ProjectTilesetFolder> get tilesetFolders;
  @override
  List<ProjectTilesetEntry> get tilesets;
  @override
  List<ProjectElementCategory> get elementCategories;
  @override
  List<ProjectElementEntry> get elements;
  @override
  List<ProjectPresetCategory> get terrainCategories;
  @override
  List<ProjectPresetCategory> get pathCategories;
  @override
  List<ProjectTerrainPreset> get terrainPresets;
  @override
  List<ProjectPathPreset> get pathPresets;
  @override
  List<ProjectEncounterTable> get encounterTables;
  @override
  List<ProjectDialogueFolder> get dialogueFolders;
  @override
  List<ProjectDialogueEntry> get dialogues;
  @override
  List<ProjectTrainerEntry> get trainers;
  @override
  List<ProjectCharacterEntry> get characters;
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
  @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId)
  String? get defaultPlayerCharacterId => throw _privateConstructorUsedError;

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
      int defaultMapHeight,
      @JsonKey(
          name: 'defaultPlayerCharacterId',
          readValue: _readDefaultPlayerCharacterId)
      String? defaultPlayerCharacterId});
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
    Object? defaultPlayerCharacterId = freezed,
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
      defaultPlayerCharacterId: freezed == defaultPlayerCharacterId
          ? _value.defaultPlayerCharacterId
          : defaultPlayerCharacterId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      int defaultMapHeight,
      @JsonKey(
          name: 'defaultPlayerCharacterId',
          readValue: _readDefaultPlayerCharacterId)
      String? defaultPlayerCharacterId});
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
    Object? defaultPlayerCharacterId = freezed,
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
      defaultPlayerCharacterId: freezed == defaultPlayerCharacterId
          ? _value.defaultPlayerCharacterId
          : defaultPlayerCharacterId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      this.defaultMapHeight = 15,
      @JsonKey(
          name: 'defaultPlayerCharacterId',
          readValue: _readDefaultPlayerCharacterId)
      this.defaultPlayerCharacterId});

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
  @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId)
  final String? defaultPlayerCharacterId;

  @override
  String toString() {
    return 'ProjectSettings(tileWidth: $tileWidth, tileHeight: $tileHeight, displayScale: $displayScale, defaultMapWidth: $defaultMapWidth, defaultMapHeight: $defaultMapHeight, defaultPlayerCharacterId: $defaultPlayerCharacterId)';
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
                other.defaultMapHeight == defaultMapHeight) &&
            (identical(
                    other.defaultPlayerCharacterId, defaultPlayerCharacterId) ||
                other.defaultPlayerCharacterId == defaultPlayerCharacterId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      tileWidth,
      tileHeight,
      displayScale,
      defaultMapWidth,
      defaultMapHeight,
      defaultPlayerCharacterId);

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
      final int defaultMapHeight,
      @JsonKey(
          name: 'defaultPlayerCharacterId',
          readValue: _readDefaultPlayerCharacterId)
      final String? defaultPlayerCharacterId}) = _$ProjectSettingsImpl;

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
  @override
  @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId)
  String? get defaultPlayerCharacterId;

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

ProjectDialogueFolder _$ProjectDialogueFolderFromJson(
    Map<String, dynamic> json) {
  return _ProjectDialogueFolder.fromJson(json);
}

/// @nodoc
mixin _$ProjectDialogueFolder {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentFolderId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectDialogueFolder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectDialogueFolderCopyWith<ProjectDialogueFolder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectDialogueFolderCopyWith<$Res> {
  factory $ProjectDialogueFolderCopyWith(ProjectDialogueFolder value,
          $Res Function(ProjectDialogueFolder) then) =
      _$ProjectDialogueFolderCopyWithImpl<$Res, ProjectDialogueFolder>;
  @useResult
  $Res call({String id, String name, String? parentFolderId, int sortOrder});
}

/// @nodoc
class _$ProjectDialogueFolderCopyWithImpl<$Res,
        $Val extends ProjectDialogueFolder>
    implements $ProjectDialogueFolderCopyWith<$Res> {
  _$ProjectDialogueFolderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentFolderId = freezed,
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
      parentFolderId: freezed == parentFolderId
          ? _value.parentFolderId
          : parentFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectDialogueFolderImplCopyWith<$Res>
    implements $ProjectDialogueFolderCopyWith<$Res> {
  factory _$$ProjectDialogueFolderImplCopyWith(
          _$ProjectDialogueFolderImpl value,
          $Res Function(_$ProjectDialogueFolderImpl) then) =
      __$$ProjectDialogueFolderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentFolderId, int sortOrder});
}

/// @nodoc
class __$$ProjectDialogueFolderImplCopyWithImpl<$Res>
    extends _$ProjectDialogueFolderCopyWithImpl<$Res,
        _$ProjectDialogueFolderImpl>
    implements _$$ProjectDialogueFolderImplCopyWith<$Res> {
  __$$ProjectDialogueFolderImplCopyWithImpl(_$ProjectDialogueFolderImpl _value,
      $Res Function(_$ProjectDialogueFolderImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentFolderId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectDialogueFolderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentFolderId: freezed == parentFolderId
          ? _value.parentFolderId
          : parentFolderId // ignore: cast_nullable_to_non_nullable
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
class _$ProjectDialogueFolderImpl implements _ProjectDialogueFolder {
  const _$ProjectDialogueFolderImpl(
      {required this.id,
      required this.name,
      this.parentFolderId,
      this.sortOrder = 0});

  factory _$ProjectDialogueFolderImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectDialogueFolderImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentFolderId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectDialogueFolder(id: $id, name: $name, parentFolderId: $parentFolderId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectDialogueFolderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentFolderId, parentFolderId) ||
                other.parentFolderId == parentFolderId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, parentFolderId, sortOrder);

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectDialogueFolderImplCopyWith<_$ProjectDialogueFolderImpl>
      get copyWith => __$$ProjectDialogueFolderImplCopyWithImpl<
          _$ProjectDialogueFolderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectDialogueFolderImplToJson(
      this,
    );
  }
}

abstract class _ProjectDialogueFolder implements ProjectDialogueFolder {
  const factory _ProjectDialogueFolder(
      {required final String id,
      required final String name,
      final String? parentFolderId,
      final int sortOrder}) = _$ProjectDialogueFolderImpl;

  factory _ProjectDialogueFolder.fromJson(Map<String, dynamic> json) =
      _$ProjectDialogueFolderImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentFolderId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectDialogueFolderImplCopyWith<_$ProjectDialogueFolderImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectDialogueEntry _$ProjectDialogueEntryFromJson(Map<String, dynamic> json) {
  return _ProjectDialogueEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectDialogueEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
  String get relativePath => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
  String? get defaultStartNode => throw _privateConstructorUsedError;

  /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
  String? get folderId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectDialogueEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectDialogueEntryCopyWith<ProjectDialogueEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectDialogueEntryCopyWith<$Res> {
  factory $ProjectDialogueEntryCopyWith(ProjectDialogueEntry value,
          $Res Function(ProjectDialogueEntry) then) =
      _$ProjectDialogueEntryCopyWithImpl<$Res, ProjectDialogueEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      List<String> tags,
      String description,
      String? defaultStartNode,
      String? folderId,
      int sortOrder});
}

/// @nodoc
class _$ProjectDialogueEntryCopyWithImpl<$Res,
        $Val extends ProjectDialogueEntry>
    implements $ProjectDialogueEntryCopyWith<$Res> {
  _$ProjectDialogueEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? tags = null,
    Object? description = null,
    Object? defaultStartNode = freezed,
    Object? folderId = freezed,
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
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      defaultStartNode: freezed == defaultStartNode
          ? _value.defaultStartNode
          : defaultStartNode // ignore: cast_nullable_to_non_nullable
              as String?,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectDialogueEntryImplCopyWith<$Res>
    implements $ProjectDialogueEntryCopyWith<$Res> {
  factory _$$ProjectDialogueEntryImplCopyWith(_$ProjectDialogueEntryImpl value,
          $Res Function(_$ProjectDialogueEntryImpl) then) =
      __$$ProjectDialogueEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      List<String> tags,
      String description,
      String? defaultStartNode,
      String? folderId,
      int sortOrder});
}

/// @nodoc
class __$$ProjectDialogueEntryImplCopyWithImpl<$Res>
    extends _$ProjectDialogueEntryCopyWithImpl<$Res, _$ProjectDialogueEntryImpl>
    implements _$$ProjectDialogueEntryImplCopyWith<$Res> {
  __$$ProjectDialogueEntryImplCopyWithImpl(_$ProjectDialogueEntryImpl _value,
      $Res Function(_$ProjectDialogueEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? tags = null,
    Object? description = null,
    Object? defaultStartNode = freezed,
    Object? folderId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectDialogueEntryImpl(
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
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      defaultStartNode: freezed == defaultStartNode
          ? _value.defaultStartNode
          : defaultStartNode // ignore: cast_nullable_to_non_nullable
              as String?,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectDialogueEntryImpl implements _ProjectDialogueEntry {
  const _$ProjectDialogueEntryImpl(
      {required this.id,
      required this.name,
      required this.relativePath,
      final List<String> tags = const [],
      this.description = '',
      this.defaultStartNode,
      this.folderId,
      this.sortOrder = 0})
      : _tags = tags;

  factory _$ProjectDialogueEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectDialogueEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
  @override
  final String relativePath;
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
  final String description;

  /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
  @override
  final String? defaultStartNode;

  /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
  @override
  final String? folderId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectDialogueEntry(id: $id, name: $name, relativePath: $relativePath, tags: $tags, description: $description, defaultStartNode: $defaultStartNode, folderId: $folderId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectDialogueEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.defaultStartNode, defaultStartNode) ||
                other.defaultStartNode == defaultStartNode) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      relativePath,
      const DeepCollectionEquality().hash(_tags),
      description,
      defaultStartNode,
      folderId,
      sortOrder);

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectDialogueEntryImplCopyWith<_$ProjectDialogueEntryImpl>
      get copyWith =>
          __$$ProjectDialogueEntryImplCopyWithImpl<_$ProjectDialogueEntryImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectDialogueEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectDialogueEntry implements ProjectDialogueEntry {
  const factory _ProjectDialogueEntry(
      {required final String id,
      required final String name,
      required final String relativePath,
      final List<String> tags,
      final String description,
      final String? defaultStartNode,
      final String? folderId,
      final int sortOrder}) = _$ProjectDialogueEntryImpl;

  factory _ProjectDialogueEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectDialogueEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
  @override
  String get relativePath;
  @override
  List<String> get tags;
  @override
  String get description;

  /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
  @override
  String? get defaultStartNode;

  /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
  @override
  String? get folderId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectDialogueEntryImplCopyWith<_$ProjectDialogueEntryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectTilesetFolder _$ProjectTilesetFolderFromJson(Map<String, dynamic> json) {
  return _ProjectTilesetFolder.fromJson(json);
}

/// @nodoc
mixin _$ProjectTilesetFolder {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentFolderId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectTilesetFolder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTilesetFolderCopyWith<ProjectTilesetFolder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTilesetFolderCopyWith<$Res> {
  factory $ProjectTilesetFolderCopyWith(ProjectTilesetFolder value,
          $Res Function(ProjectTilesetFolder) then) =
      _$ProjectTilesetFolderCopyWithImpl<$Res, ProjectTilesetFolder>;
  @useResult
  $Res call({String id, String name, String? parentFolderId, int sortOrder});
}

/// @nodoc
class _$ProjectTilesetFolderCopyWithImpl<$Res,
        $Val extends ProjectTilesetFolder>
    implements $ProjectTilesetFolderCopyWith<$Res> {
  _$ProjectTilesetFolderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentFolderId = freezed,
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
      parentFolderId: freezed == parentFolderId
          ? _value.parentFolderId
          : parentFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTilesetFolderImplCopyWith<$Res>
    implements $ProjectTilesetFolderCopyWith<$Res> {
  factory _$$ProjectTilesetFolderImplCopyWith(_$ProjectTilesetFolderImpl value,
          $Res Function(_$ProjectTilesetFolderImpl) then) =
      __$$ProjectTilesetFolderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentFolderId, int sortOrder});
}

/// @nodoc
class __$$ProjectTilesetFolderImplCopyWithImpl<$Res>
    extends _$ProjectTilesetFolderCopyWithImpl<$Res, _$ProjectTilesetFolderImpl>
    implements _$$ProjectTilesetFolderImplCopyWith<$Res> {
  __$$ProjectTilesetFolderImplCopyWithImpl(_$ProjectTilesetFolderImpl _value,
      $Res Function(_$ProjectTilesetFolderImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentFolderId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectTilesetFolderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentFolderId: freezed == parentFolderId
          ? _value.parentFolderId
          : parentFolderId // ignore: cast_nullable_to_non_nullable
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
class _$ProjectTilesetFolderImpl implements _ProjectTilesetFolder {
  const _$ProjectTilesetFolderImpl(
      {required this.id,
      required this.name,
      this.parentFolderId,
      this.sortOrder = 0});

  factory _$ProjectTilesetFolderImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTilesetFolderImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentFolderId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectTilesetFolder(id: $id, name: $name, parentFolderId: $parentFolderId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTilesetFolderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentFolderId, parentFolderId) ||
                other.parentFolderId == parentFolderId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, parentFolderId, sortOrder);

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTilesetFolderImplCopyWith<_$ProjectTilesetFolderImpl>
      get copyWith =>
          __$$ProjectTilesetFolderImplCopyWithImpl<_$ProjectTilesetFolderImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTilesetFolderImplToJson(
      this,
    );
  }
}

abstract class _ProjectTilesetFolder implements ProjectTilesetFolder {
  const factory _ProjectTilesetFolder(
      {required final String id,
      required final String name,
      final String? parentFolderId,
      final int sortOrder}) = _$ProjectTilesetFolderImpl;

  factory _ProjectTilesetFolder.fromJson(Map<String, dynamic> json) =
      _$ProjectTilesetFolderImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentFolderId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTilesetFolderImplCopyWith<_$ProjectTilesetFolderImpl>
      get copyWith => throw _privateConstructorUsedError;
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

  /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
  String? get folderId => throw _privateConstructorUsedError;
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
      String? folderId,
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
    Object? folderId = freezed,
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
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
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
      String? folderId,
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
    Object? folderId = freezed,
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
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
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
      this.folderId,
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

  /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
  @override
  final String? folderId;
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
    return 'ProjectTilesetEntry(id: $id, name: $name, relativePath: $relativePath, scope: $scope, groupId: $groupId, folderId: $folderId, sortOrder: $sortOrder, isWorldTileset: $isWorldTileset, elementGroups: $elementGroups, paletteEntries: $paletteEntries)';
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
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
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
      folderId,
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
          final String? folderId,
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

  /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
  @override
  String? get folderId;
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

  /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
  List<TilesetVisualFrame> get frames => throw _privateConstructorUsedError;
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
      List<TilesetVisualFrame> frames,
      String? recommendedLayerId});
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
    Object? frames = null,
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
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
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
      List<TilesetVisualFrame> frames,
      String? recommendedLayerId});
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
    Object? frames = null,
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
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TilesetPaletteEntryImpl implements _TilesetPaletteEntry {
  const _$TilesetPaletteEntryImpl(
      {required this.id,
      this.name = '',
      this.category = PaletteCategory.uncategorized,
      required final List<TilesetVisualFrame> frames,
      this.recommendedLayerId})
      : _frames = frames;

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

  /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
  final List<TilesetVisualFrame> _frames;

  /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
  @override
  List<TilesetVisualFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  final String? recommendedLayerId;

  @override
  String toString() {
    return 'TilesetPaletteEntry(id: $id, name: $name, category: $category, frames: $frames, recommendedLayerId: $recommendedLayerId)';
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
            const DeepCollectionEquality().equals(other._frames, _frames) &&
            (identical(other.recommendedLayerId, recommendedLayerId) ||
                other.recommendedLayerId == recommendedLayerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, category,
      const DeepCollectionEquality().hash(_frames), recommendedLayerId);

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
      required final List<TilesetVisualFrame> frames,
      final String? recommendedLayerId}) = _$TilesetPaletteEntryImpl;

  factory _TilesetPaletteEntry.fromJson(Map<String, dynamic> json) =
      _$TilesetPaletteEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  PaletteCategory get category;

  /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
  @override
  List<TilesetVisualFrame> get frames;
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

TilesetVisualFrame _$TilesetVisualFrameFromJson(Map<String, dynamic> json) {
  return _TilesetVisualFrame.fromJson(json);
}

/// @nodoc
mixin _$TilesetVisualFrame {
  String get tilesetId => throw _privateConstructorUsedError;
  TilesetSourceRect get source => throw _privateConstructorUsedError;

  /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
  int? get durationMs => throw _privateConstructorUsedError;

  /// Serializes this TilesetVisualFrame to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilesetVisualFrameCopyWith<TilesetVisualFrame> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilesetVisualFrameCopyWith<$Res> {
  factory $TilesetVisualFrameCopyWith(
          TilesetVisualFrame value, $Res Function(TilesetVisualFrame) then) =
      _$TilesetVisualFrameCopyWithImpl<$Res, TilesetVisualFrame>;
  @useResult
  $Res call({String tilesetId, TilesetSourceRect source, int? durationMs});

  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class _$TilesetVisualFrameCopyWithImpl<$Res, $Val extends TilesetVisualFrame>
    implements $TilesetVisualFrameCopyWith<$Res> {
  _$TilesetVisualFrameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tilesetId = null,
    Object? source = null,
    Object? durationMs = freezed,
  }) {
    return _then(_value.copyWith(
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      durationMs: freezed == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  /// Create a copy of TilesetVisualFrame
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
abstract class _$$TilesetVisualFrameImplCopyWith<$Res>
    implements $TilesetVisualFrameCopyWith<$Res> {
  factory _$$TilesetVisualFrameImplCopyWith(_$TilesetVisualFrameImpl value,
          $Res Function(_$TilesetVisualFrameImpl) then) =
      __$$TilesetVisualFrameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String tilesetId, TilesetSourceRect source, int? durationMs});

  @override
  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class __$$TilesetVisualFrameImplCopyWithImpl<$Res>
    extends _$TilesetVisualFrameCopyWithImpl<$Res, _$TilesetVisualFrameImpl>
    implements _$$TilesetVisualFrameImplCopyWith<$Res> {
  __$$TilesetVisualFrameImplCopyWithImpl(_$TilesetVisualFrameImpl _value,
      $Res Function(_$TilesetVisualFrameImpl) _then)
      : super(_value, _then);

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tilesetId = null,
    Object? source = null,
    Object? durationMs = freezed,
  }) {
    return _then(_$TilesetVisualFrameImpl(
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      durationMs: freezed == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TilesetVisualFrameImpl implements _TilesetVisualFrame {
  const _$TilesetVisualFrameImpl(
      {this.tilesetId = '', required this.source, this.durationMs});

  factory _$TilesetVisualFrameImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilesetVisualFrameImplFromJson(json);

  @override
  @JsonKey()
  final String tilesetId;
  @override
  final TilesetSourceRect source;

  /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
  @override
  final int? durationMs;

  @override
  String toString() {
    return 'TilesetVisualFrame(tilesetId: $tilesetId, source: $source, durationMs: $durationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilesetVisualFrameImpl &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tilesetId, source, durationMs);

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilesetVisualFrameImplCopyWith<_$TilesetVisualFrameImpl> get copyWith =>
      __$$TilesetVisualFrameImplCopyWithImpl<_$TilesetVisualFrameImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilesetVisualFrameImplToJson(
      this,
    );
  }
}

abstract class _TilesetVisualFrame implements TilesetVisualFrame {
  const factory _TilesetVisualFrame(
      {final String tilesetId,
      required final TilesetSourceRect source,
      final int? durationMs}) = _$TilesetVisualFrameImpl;

  factory _TilesetVisualFrame.fromJson(Map<String, dynamic> json) =
      _$TilesetVisualFrameImpl.fromJson;

  @override
  String get tilesetId;
  @override
  TilesetSourceRect get source;

  /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
  @override
  int? get durationMs;

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilesetVisualFrameImplCopyWith<_$TilesetVisualFrameImpl> get copyWith =>
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

  /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
  List<TilesetVisualFrame> get frames => throw _privateConstructorUsedError;
  ElementPresetKind get presetKind => throw _privateConstructorUsedError;
  ElementCollisionProfile? get collisionProfile =>
      throw _privateConstructorUsedError;
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
      List<TilesetVisualFrame> frames,
      ElementPresetKind presetKind,
      ElementCollisionProfile? collisionProfile,
      String? groupId,
      String? recommendedLayerId,
      List<String> tags,
      int sortOrder});

  $ElementCollisionProfileCopyWith<$Res>? get collisionProfile;
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
    Object? frames = null,
    Object? presetKind = null,
    Object? collisionProfile = freezed,
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
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      presetKind: null == presetKind
          ? _value.presetKind
          : presetKind // ignore: cast_nullable_to_non_nullable
              as ElementPresetKind,
      collisionProfile: freezed == collisionProfile
          ? _value.collisionProfile
          : collisionProfile // ignore: cast_nullable_to_non_nullable
              as ElementCollisionProfile?,
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
  $ElementCollisionProfileCopyWith<$Res>? get collisionProfile {
    if (_value.collisionProfile == null) {
      return null;
    }

    return $ElementCollisionProfileCopyWith<$Res>(_value.collisionProfile!,
        (value) {
      return _then(_value.copyWith(collisionProfile: value) as $Val);
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
      List<TilesetVisualFrame> frames,
      ElementPresetKind presetKind,
      ElementCollisionProfile? collisionProfile,
      String? groupId,
      String? recommendedLayerId,
      List<String> tags,
      int sortOrder});

  @override
  $ElementCollisionProfileCopyWith<$Res>? get collisionProfile;
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
    Object? frames = null,
    Object? presetKind = null,
    Object? collisionProfile = freezed,
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
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      presetKind: null == presetKind
          ? _value.presetKind
          : presetKind // ignore: cast_nullable_to_non_nullable
              as ElementPresetKind,
      collisionProfile: freezed == collisionProfile
          ? _value.collisionProfile
          : collisionProfile // ignore: cast_nullable_to_non_nullable
              as ElementCollisionProfile?,
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

@JsonSerializable(explicitToJson: true)
class _$ProjectElementEntryImpl implements _ProjectElementEntry {
  const _$ProjectElementEntryImpl(
      {required this.id,
      required this.name,
      required this.tilesetId,
      required this.categoryId,
      this.tilesetGroupId,
      required final List<TilesetVisualFrame> frames,
      this.presetKind = ElementPresetKind.generic,
      this.collisionProfile,
      this.groupId,
      this.recommendedLayerId,
      final List<String> tags = const [],
      this.sortOrder = 0})
      : _frames = frames,
        _tags = tags;

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

  /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
  final List<TilesetVisualFrame> _frames;

  /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
  @override
  List<TilesetVisualFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  @JsonKey()
  final ElementPresetKind presetKind;
  @override
  final ElementCollisionProfile? collisionProfile;
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
    return 'ProjectElementEntry(id: $id, name: $name, tilesetId: $tilesetId, categoryId: $categoryId, tilesetGroupId: $tilesetGroupId, frames: $frames, presetKind: $presetKind, collisionProfile: $collisionProfile, groupId: $groupId, recommendedLayerId: $recommendedLayerId, tags: $tags, sortOrder: $sortOrder)';
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
            const DeepCollectionEquality().equals(other._frames, _frames) &&
            (identical(other.presetKind, presetKind) ||
                other.presetKind == presetKind) &&
            (identical(other.collisionProfile, collisionProfile) ||
                other.collisionProfile == collisionProfile) &&
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
      const DeepCollectionEquality().hash(_frames),
      presetKind,
      collisionProfile,
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
      required final List<TilesetVisualFrame> frames,
      final ElementPresetKind presetKind,
      final ElementCollisionProfile? collisionProfile,
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

  /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
  @override
  List<TilesetVisualFrame> get frames;
  @override
  ElementPresetKind get presetKind;
  @override
  ElementCollisionProfile? get collisionProfile;
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

ProjectTerrainPreset _$ProjectTerrainPresetFromJson(Map<String, dynamic> json) {
  return _ProjectTerrainPreset.fromJson(json);
}

/// @nodoc
mixin _$ProjectTerrainPreset {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  TerrainType get terrainType => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  List<TerrainPresetVariant> get variants => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectTerrainPreset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTerrainPresetCopyWith<ProjectTerrainPreset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTerrainPresetCopyWith<$Res> {
  factory $ProjectTerrainPresetCopyWith(ProjectTerrainPreset value,
          $Res Function(ProjectTerrainPreset) then) =
      _$ProjectTerrainPresetCopyWithImpl<$Res, ProjectTerrainPreset>;
  @useResult
  $Res call(
      {String id,
      String name,
      TerrainType terrainType,
      String? categoryId,
      String tilesetId,
      List<TerrainPresetVariant> variants,
      int sortOrder});
}

/// @nodoc
class _$ProjectTerrainPresetCopyWithImpl<$Res,
        $Val extends ProjectTerrainPreset>
    implements $ProjectTerrainPresetCopyWith<$Res> {
  _$ProjectTerrainPresetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? terrainType = null,
    Object? categoryId = freezed,
    Object? tilesetId = null,
    Object? variants = null,
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
      terrainType: null == terrainType
          ? _value.terrainType
          : terrainType // ignore: cast_nullable_to_non_nullable
              as TerrainType,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      variants: null == variants
          ? _value.variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<TerrainPresetVariant>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTerrainPresetImplCopyWith<$Res>
    implements $ProjectTerrainPresetCopyWith<$Res> {
  factory _$$ProjectTerrainPresetImplCopyWith(_$ProjectTerrainPresetImpl value,
          $Res Function(_$ProjectTerrainPresetImpl) then) =
      __$$ProjectTerrainPresetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      TerrainType terrainType,
      String? categoryId,
      String tilesetId,
      List<TerrainPresetVariant> variants,
      int sortOrder});
}

/// @nodoc
class __$$ProjectTerrainPresetImplCopyWithImpl<$Res>
    extends _$ProjectTerrainPresetCopyWithImpl<$Res, _$ProjectTerrainPresetImpl>
    implements _$$ProjectTerrainPresetImplCopyWith<$Res> {
  __$$ProjectTerrainPresetImplCopyWithImpl(_$ProjectTerrainPresetImpl _value,
      $Res Function(_$ProjectTerrainPresetImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? terrainType = null,
    Object? categoryId = freezed,
    Object? tilesetId = null,
    Object? variants = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectTerrainPresetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      terrainType: null == terrainType
          ? _value.terrainType
          : terrainType // ignore: cast_nullable_to_non_nullable
              as TerrainType,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      variants: null == variants
          ? _value._variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<TerrainPresetVariant>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTerrainPresetImpl implements _ProjectTerrainPreset {
  const _$ProjectTerrainPresetImpl(
      {required this.id,
      required this.name,
      required this.terrainType,
      this.categoryId,
      this.tilesetId = '',
      final List<TerrainPresetVariant> variants = const [],
      this.sortOrder = 0})
      : _variants = variants;

  factory _$ProjectTerrainPresetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTerrainPresetImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final TerrainType terrainType;
  @override
  final String? categoryId;
  @override
  @JsonKey()
  final String tilesetId;
  final List<TerrainPresetVariant> _variants;
  @override
  @JsonKey()
  List<TerrainPresetVariant> get variants {
    if (_variants is EqualUnmodifiableListView) return _variants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_variants);
  }

  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectTerrainPreset(id: $id, name: $name, terrainType: $terrainType, categoryId: $categoryId, tilesetId: $tilesetId, variants: $variants, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTerrainPresetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.terrainType, terrainType) ||
                other.terrainType == terrainType) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            const DeepCollectionEquality().equals(other._variants, _variants) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      terrainType,
      categoryId,
      tilesetId,
      const DeepCollectionEquality().hash(_variants),
      sortOrder);

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTerrainPresetImplCopyWith<_$ProjectTerrainPresetImpl>
      get copyWith =>
          __$$ProjectTerrainPresetImplCopyWithImpl<_$ProjectTerrainPresetImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTerrainPresetImplToJson(
      this,
    );
  }
}

abstract class _ProjectTerrainPreset implements ProjectTerrainPreset {
  const factory _ProjectTerrainPreset(
      {required final String id,
      required final String name,
      required final TerrainType terrainType,
      final String? categoryId,
      final String tilesetId,
      final List<TerrainPresetVariant> variants,
      final int sortOrder}) = _$ProjectTerrainPresetImpl;

  factory _ProjectTerrainPreset.fromJson(Map<String, dynamic> json) =
      _$ProjectTerrainPresetImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  TerrainType get terrainType;
  @override
  String? get categoryId;
  @override
  String get tilesetId;
  @override
  List<TerrainPresetVariant> get variants;
  @override
  int get sortOrder;

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTerrainPresetImplCopyWith<_$ProjectTerrainPresetImpl>
      get copyWith => throw _privateConstructorUsedError;
}

TerrainPresetVariant _$TerrainPresetVariantFromJson(Map<String, dynamic> json) {
  return _TerrainPresetVariant.fromJson(json);
}

/// @nodoc
mixin _$TerrainPresetVariant {
  /// Au moins une frame ; rendu éditeur = première frame.
  List<TilesetVisualFrame> get frames => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;

  /// Serializes this TerrainPresetVariant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TerrainPresetVariantCopyWith<TerrainPresetVariant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TerrainPresetVariantCopyWith<$Res> {
  factory $TerrainPresetVariantCopyWith(TerrainPresetVariant value,
          $Res Function(TerrainPresetVariant) then) =
      _$TerrainPresetVariantCopyWithImpl<$Res, TerrainPresetVariant>;
  @useResult
  $Res call({List<TilesetVisualFrame> frames, int weight});
}

/// @nodoc
class _$TerrainPresetVariantCopyWithImpl<$Res,
        $Val extends TerrainPresetVariant>
    implements $TerrainPresetVariantCopyWith<$Res> {
  _$TerrainPresetVariantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frames = null,
    Object? weight = null,
  }) {
    return _then(_value.copyWith(
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TerrainPresetVariantImplCopyWith<$Res>
    implements $TerrainPresetVariantCopyWith<$Res> {
  factory _$$TerrainPresetVariantImplCopyWith(_$TerrainPresetVariantImpl value,
          $Res Function(_$TerrainPresetVariantImpl) then) =
      __$$TerrainPresetVariantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<TilesetVisualFrame> frames, int weight});
}

/// @nodoc
class __$$TerrainPresetVariantImplCopyWithImpl<$Res>
    extends _$TerrainPresetVariantCopyWithImpl<$Res, _$TerrainPresetVariantImpl>
    implements _$$TerrainPresetVariantImplCopyWith<$Res> {
  __$$TerrainPresetVariantImplCopyWithImpl(_$TerrainPresetVariantImpl _value,
      $Res Function(_$TerrainPresetVariantImpl) _then)
      : super(_value, _then);

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frames = null,
    Object? weight = null,
  }) {
    return _then(_$TerrainPresetVariantImpl(
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TerrainPresetVariantImpl implements _TerrainPresetVariant {
  const _$TerrainPresetVariantImpl(
      {required final List<TilesetVisualFrame> frames, this.weight = 1})
      : _frames = frames;

  factory _$TerrainPresetVariantImpl.fromJson(Map<String, dynamic> json) =>
      _$$TerrainPresetVariantImplFromJson(json);

  /// Au moins une frame ; rendu éditeur = première frame.
  final List<TilesetVisualFrame> _frames;

  /// Au moins une frame ; rendu éditeur = première frame.
  @override
  List<TilesetVisualFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  @JsonKey()
  final int weight;

  @override
  String toString() {
    return 'TerrainPresetVariant(frames: $frames, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TerrainPresetVariantImpl &&
            const DeepCollectionEquality().equals(other._frames, _frames) &&
            (identical(other.weight, weight) || other.weight == weight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_frames), weight);

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TerrainPresetVariantImplCopyWith<_$TerrainPresetVariantImpl>
      get copyWith =>
          __$$TerrainPresetVariantImplCopyWithImpl<_$TerrainPresetVariantImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TerrainPresetVariantImplToJson(
      this,
    );
  }
}

abstract class _TerrainPresetVariant implements TerrainPresetVariant {
  const factory _TerrainPresetVariant(
      {required final List<TilesetVisualFrame> frames,
      final int weight}) = _$TerrainPresetVariantImpl;

  factory _TerrainPresetVariant.fromJson(Map<String, dynamic> json) =
      _$TerrainPresetVariantImpl.fromJson;

  /// Au moins une frame ; rendu éditeur = première frame.
  @override
  List<TilesetVisualFrame> get frames;
  @override
  int get weight;

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TerrainPresetVariantImplCopyWith<_$TerrainPresetVariantImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectPathPreset _$ProjectPathPresetFromJson(Map<String, dynamic> json) {
  return _ProjectPathPreset.fromJson(json);
}

/// @nodoc
mixin _$ProjectPathPreset {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  PathSurfaceKind get surfaceKind => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  List<PathPresetVariantMapping> get variants =>
      throw _privateConstructorUsedError;
  List<PathAnimationTriggerRule> get animationTriggers =>
      throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectPathPreset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectPathPresetCopyWith<ProjectPathPreset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectPathPresetCopyWith<$Res> {
  factory $ProjectPathPresetCopyWith(
          ProjectPathPreset value, $Res Function(ProjectPathPreset) then) =
      _$ProjectPathPresetCopyWithImpl<$Res, ProjectPathPreset>;
  @useResult
  $Res call(
      {String id,
      String name,
      PathSurfaceKind surfaceKind,
      String? categoryId,
      String tilesetId,
      List<PathPresetVariantMapping> variants,
      List<PathAnimationTriggerRule> animationTriggers,
      int sortOrder});
}

/// @nodoc
class _$ProjectPathPresetCopyWithImpl<$Res, $Val extends ProjectPathPreset>
    implements $ProjectPathPresetCopyWith<$Res> {
  _$ProjectPathPresetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? surfaceKind = null,
    Object? categoryId = freezed,
    Object? tilesetId = null,
    Object? variants = null,
    Object? animationTriggers = null,
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
      surfaceKind: null == surfaceKind
          ? _value.surfaceKind
          : surfaceKind // ignore: cast_nullable_to_non_nullable
              as PathSurfaceKind,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      variants: null == variants
          ? _value.variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<PathPresetVariantMapping>,
      animationTriggers: null == animationTriggers
          ? _value.animationTriggers
          : animationTriggers // ignore: cast_nullable_to_non_nullable
              as List<PathAnimationTriggerRule>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectPathPresetImplCopyWith<$Res>
    implements $ProjectPathPresetCopyWith<$Res> {
  factory _$$ProjectPathPresetImplCopyWith(_$ProjectPathPresetImpl value,
          $Res Function(_$ProjectPathPresetImpl) then) =
      __$$ProjectPathPresetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      PathSurfaceKind surfaceKind,
      String? categoryId,
      String tilesetId,
      List<PathPresetVariantMapping> variants,
      List<PathAnimationTriggerRule> animationTriggers,
      int sortOrder});
}

/// @nodoc
class __$$ProjectPathPresetImplCopyWithImpl<$Res>
    extends _$ProjectPathPresetCopyWithImpl<$Res, _$ProjectPathPresetImpl>
    implements _$$ProjectPathPresetImplCopyWith<$Res> {
  __$$ProjectPathPresetImplCopyWithImpl(_$ProjectPathPresetImpl _value,
      $Res Function(_$ProjectPathPresetImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? surfaceKind = null,
    Object? categoryId = freezed,
    Object? tilesetId = null,
    Object? variants = null,
    Object? animationTriggers = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectPathPresetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      surfaceKind: null == surfaceKind
          ? _value.surfaceKind
          : surfaceKind // ignore: cast_nullable_to_non_nullable
              as PathSurfaceKind,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      variants: null == variants
          ? _value._variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<PathPresetVariantMapping>,
      animationTriggers: null == animationTriggers
          ? _value._animationTriggers
          : animationTriggers // ignore: cast_nullable_to_non_nullable
              as List<PathAnimationTriggerRule>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectPathPresetImpl implements _ProjectPathPreset {
  const _$ProjectPathPresetImpl(
      {required this.id,
      required this.name,
      this.surfaceKind = PathSurfaceKind.path,
      this.categoryId,
      this.tilesetId = '',
      final List<PathPresetVariantMapping> variants = const [],
      final List<PathAnimationTriggerRule> animationTriggers = const [],
      this.sortOrder = 0})
      : _variants = variants,
        _animationTriggers = animationTriggers;

  factory _$ProjectPathPresetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectPathPresetImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final PathSurfaceKind surfaceKind;
  @override
  final String? categoryId;
  @override
  @JsonKey()
  final String tilesetId;
  final List<PathPresetVariantMapping> _variants;
  @override
  @JsonKey()
  List<PathPresetVariantMapping> get variants {
    if (_variants is EqualUnmodifiableListView) return _variants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_variants);
  }

  final List<PathAnimationTriggerRule> _animationTriggers;
  @override
  @JsonKey()
  List<PathAnimationTriggerRule> get animationTriggers {
    if (_animationTriggers is EqualUnmodifiableListView)
      return _animationTriggers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_animationTriggers);
  }

  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectPathPreset(id: $id, name: $name, surfaceKind: $surfaceKind, categoryId: $categoryId, tilesetId: $tilesetId, variants: $variants, animationTriggers: $animationTriggers, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectPathPresetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.surfaceKind, surfaceKind) ||
                other.surfaceKind == surfaceKind) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            const DeepCollectionEquality().equals(other._variants, _variants) &&
            const DeepCollectionEquality()
                .equals(other._animationTriggers, _animationTriggers) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      surfaceKind,
      categoryId,
      tilesetId,
      const DeepCollectionEquality().hash(_variants),
      const DeepCollectionEquality().hash(_animationTriggers),
      sortOrder);

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectPathPresetImplCopyWith<_$ProjectPathPresetImpl> get copyWith =>
      __$$ProjectPathPresetImplCopyWithImpl<_$ProjectPathPresetImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectPathPresetImplToJson(
      this,
    );
  }
}

abstract class _ProjectPathPreset implements ProjectPathPreset {
  const factory _ProjectPathPreset(
      {required final String id,
      required final String name,
      final PathSurfaceKind surfaceKind,
      final String? categoryId,
      final String tilesetId,
      final List<PathPresetVariantMapping> variants,
      final List<PathAnimationTriggerRule> animationTriggers,
      final int sortOrder}) = _$ProjectPathPresetImpl;

  factory _ProjectPathPreset.fromJson(Map<String, dynamic> json) =
      _$ProjectPathPresetImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  PathSurfaceKind get surfaceKind;
  @override
  String? get categoryId;
  @override
  String get tilesetId;
  @override
  List<PathPresetVariantMapping> get variants;
  @override
  List<PathAnimationTriggerRule> get animationTriggers;
  @override
  int get sortOrder;

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectPathPresetImplCopyWith<_$ProjectPathPresetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PathPresetVariantMapping _$PathPresetVariantMappingFromJson(
    Map<String, dynamic> json) {
  return _PathPresetVariantMapping.fromJson(json);
}

/// @nodoc
mixin _$PathPresetVariantMapping {
  TerrainPathVariant get variant => throw _privateConstructorUsedError;

  /// Au moins une frame ; rendu éditeur / autotile = première frame.
  List<TilesetVisualFrame> get frames => throw _privateConstructorUsedError;

  /// Serializes this PathPresetVariantMapping to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PathPresetVariantMappingCopyWith<PathPresetVariantMapping> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PathPresetVariantMappingCopyWith<$Res> {
  factory $PathPresetVariantMappingCopyWith(PathPresetVariantMapping value,
          $Res Function(PathPresetVariantMapping) then) =
      _$PathPresetVariantMappingCopyWithImpl<$Res, PathPresetVariantMapping>;
  @useResult
  $Res call({TerrainPathVariant variant, List<TilesetVisualFrame> frames});
}

/// @nodoc
class _$PathPresetVariantMappingCopyWithImpl<$Res,
        $Val extends PathPresetVariantMapping>
    implements $PathPresetVariantMappingCopyWith<$Res> {
  _$PathPresetVariantMappingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? variant = null,
    Object? frames = null,
  }) {
    return _then(_value.copyWith(
      variant: null == variant
          ? _value.variant
          : variant // ignore: cast_nullable_to_non_nullable
              as TerrainPathVariant,
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PathPresetVariantMappingImplCopyWith<$Res>
    implements $PathPresetVariantMappingCopyWith<$Res> {
  factory _$$PathPresetVariantMappingImplCopyWith(
          _$PathPresetVariantMappingImpl value,
          $Res Function(_$PathPresetVariantMappingImpl) then) =
      __$$PathPresetVariantMappingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TerrainPathVariant variant, List<TilesetVisualFrame> frames});
}

/// @nodoc
class __$$PathPresetVariantMappingImplCopyWithImpl<$Res>
    extends _$PathPresetVariantMappingCopyWithImpl<$Res,
        _$PathPresetVariantMappingImpl>
    implements _$$PathPresetVariantMappingImplCopyWith<$Res> {
  __$$PathPresetVariantMappingImplCopyWithImpl(
      _$PathPresetVariantMappingImpl _value,
      $Res Function(_$PathPresetVariantMappingImpl) _then)
      : super(_value, _then);

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? variant = null,
    Object? frames = null,
  }) {
    return _then(_$PathPresetVariantMappingImpl(
      variant: null == variant
          ? _value.variant
          : variant // ignore: cast_nullable_to_non_nullable
              as TerrainPathVariant,
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PathPresetVariantMappingImpl implements _PathPresetVariantMapping {
  const _$PathPresetVariantMappingImpl(
      {required this.variant, required final List<TilesetVisualFrame> frames})
      : _frames = frames;

  factory _$PathPresetVariantMappingImpl.fromJson(Map<String, dynamic> json) =>
      _$$PathPresetVariantMappingImplFromJson(json);

  @override
  final TerrainPathVariant variant;

  /// Au moins une frame ; rendu éditeur / autotile = première frame.
  final List<TilesetVisualFrame> _frames;

  /// Au moins une frame ; rendu éditeur / autotile = première frame.
  @override
  List<TilesetVisualFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  String toString() {
    return 'PathPresetVariantMapping(variant: $variant, frames: $frames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PathPresetVariantMappingImpl &&
            (identical(other.variant, variant) || other.variant == variant) &&
            const DeepCollectionEquality().equals(other._frames, _frames));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, variant, const DeepCollectionEquality().hash(_frames));

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PathPresetVariantMappingImplCopyWith<_$PathPresetVariantMappingImpl>
      get copyWith => __$$PathPresetVariantMappingImplCopyWithImpl<
          _$PathPresetVariantMappingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PathPresetVariantMappingImplToJson(
      this,
    );
  }
}

abstract class _PathPresetVariantMapping implements PathPresetVariantMapping {
  const factory _PathPresetVariantMapping(
          {required final TerrainPathVariant variant,
          required final List<TilesetVisualFrame> frames}) =
      _$PathPresetVariantMappingImpl;

  factory _PathPresetVariantMapping.fromJson(Map<String, dynamic> json) =
      _$PathPresetVariantMappingImpl.fromJson;

  @override
  TerrainPathVariant get variant;

  /// Au moins une frame ; rendu éditeur / autotile = première frame.
  @override
  List<TilesetVisualFrame> get frames;

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PathPresetVariantMappingImplCopyWith<_$PathPresetVariantMappingImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PathAnimationTriggerRule _$PathAnimationTriggerRuleFromJson(
    Map<String, dynamic> json) {
  return _PathAnimationTriggerRule.fromJson(json);
}

/// @nodoc
mixin _$PathAnimationTriggerRule {
  String get id => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  PathAnimationTriggerType get trigger => throw _privateConstructorUsedError;
  PathAnimationPlaybackMode get mode => throw _privateConstructorUsedError;

  /// Serializes this PathAnimationTriggerRule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PathAnimationTriggerRuleCopyWith<PathAnimationTriggerRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PathAnimationTriggerRuleCopyWith<$Res> {
  factory $PathAnimationTriggerRuleCopyWith(PathAnimationTriggerRule value,
          $Res Function(PathAnimationTriggerRule) then) =
      _$PathAnimationTriggerRuleCopyWithImpl<$Res, PathAnimationTriggerRule>;
  @useResult
  $Res call(
      {String id,
      bool enabled,
      PathAnimationTriggerType trigger,
      PathAnimationPlaybackMode mode});
}

/// @nodoc
class _$PathAnimationTriggerRuleCopyWithImpl<$Res,
        $Val extends PathAnimationTriggerRule>
    implements $PathAnimationTriggerRuleCopyWith<$Res> {
  _$PathAnimationTriggerRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? enabled = null,
    Object? trigger = null,
    Object? mode = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      trigger: null == trigger
          ? _value.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as PathAnimationTriggerType,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as PathAnimationPlaybackMode,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PathAnimationTriggerRuleImplCopyWith<$Res>
    implements $PathAnimationTriggerRuleCopyWith<$Res> {
  factory _$$PathAnimationTriggerRuleImplCopyWith(
          _$PathAnimationTriggerRuleImpl value,
          $Res Function(_$PathAnimationTriggerRuleImpl) then) =
      __$$PathAnimationTriggerRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      bool enabled,
      PathAnimationTriggerType trigger,
      PathAnimationPlaybackMode mode});
}

/// @nodoc
class __$$PathAnimationTriggerRuleImplCopyWithImpl<$Res>
    extends _$PathAnimationTriggerRuleCopyWithImpl<$Res,
        _$PathAnimationTriggerRuleImpl>
    implements _$$PathAnimationTriggerRuleImplCopyWith<$Res> {
  __$$PathAnimationTriggerRuleImplCopyWithImpl(
      _$PathAnimationTriggerRuleImpl _value,
      $Res Function(_$PathAnimationTriggerRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? enabled = null,
    Object? trigger = null,
    Object? mode = null,
  }) {
    return _then(_$PathAnimationTriggerRuleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      trigger: null == trigger
          ? _value.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as PathAnimationTriggerType,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as PathAnimationPlaybackMode,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PathAnimationTriggerRuleImpl implements _PathAnimationTriggerRule {
  const _$PathAnimationTriggerRuleImpl(
      {this.id = '',
      this.enabled = true,
      this.trigger = PathAnimationTriggerType.onStep,
      this.mode = PathAnimationPlaybackMode.restartOnTrigger});

  factory _$PathAnimationTriggerRuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$PathAnimationTriggerRuleImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final PathAnimationTriggerType trigger;
  @override
  @JsonKey()
  final PathAnimationPlaybackMode mode;

  @override
  String toString() {
    return 'PathAnimationTriggerRule(id: $id, enabled: $enabled, trigger: $trigger, mode: $mode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PathAnimationTriggerRuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.trigger, trigger) || other.trigger == trigger) &&
            (identical(other.mode, mode) || other.mode == mode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, enabled, trigger, mode);

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PathAnimationTriggerRuleImplCopyWith<_$PathAnimationTriggerRuleImpl>
      get copyWith => __$$PathAnimationTriggerRuleImplCopyWithImpl<
          _$PathAnimationTriggerRuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PathAnimationTriggerRuleImplToJson(
      this,
    );
  }
}

abstract class _PathAnimationTriggerRule implements PathAnimationTriggerRule {
  const factory _PathAnimationTriggerRule(
      {final String id,
      final bool enabled,
      final PathAnimationTriggerType trigger,
      final PathAnimationPlaybackMode mode}) = _$PathAnimationTriggerRuleImpl;

  factory _PathAnimationTriggerRule.fromJson(Map<String, dynamic> json) =
      _$PathAnimationTriggerRuleImpl.fromJson;

  @override
  String get id;
  @override
  bool get enabled;
  @override
  PathAnimationTriggerType get trigger;
  @override
  PathAnimationPlaybackMode get mode;

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PathAnimationTriggerRuleImplCopyWith<_$PathAnimationTriggerRuleImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectPresetCategory _$ProjectPresetCategoryFromJson(
    Map<String, dynamic> json) {
  return _ProjectPresetCategory.fromJson(json);
}

/// @nodoc
mixin _$ProjectPresetCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentCategoryId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectPresetCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectPresetCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectPresetCategoryCopyWith<ProjectPresetCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectPresetCategoryCopyWith<$Res> {
  factory $ProjectPresetCategoryCopyWith(ProjectPresetCategory value,
          $Res Function(ProjectPresetCategory) then) =
      _$ProjectPresetCategoryCopyWithImpl<$Res, ProjectPresetCategory>;
  @useResult
  $Res call({String id, String name, String? parentCategoryId, int sortOrder});
}

/// @nodoc
class _$ProjectPresetCategoryCopyWithImpl<$Res,
        $Val extends ProjectPresetCategory>
    implements $ProjectPresetCategoryCopyWith<$Res> {
  _$ProjectPresetCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectPresetCategory
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
abstract class _$$ProjectPresetCategoryImplCopyWith<$Res>
    implements $ProjectPresetCategoryCopyWith<$Res> {
  factory _$$ProjectPresetCategoryImplCopyWith(
          _$ProjectPresetCategoryImpl value,
          $Res Function(_$ProjectPresetCategoryImpl) then) =
      __$$ProjectPresetCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentCategoryId, int sortOrder});
}

/// @nodoc
class __$$ProjectPresetCategoryImplCopyWithImpl<$Res>
    extends _$ProjectPresetCategoryCopyWithImpl<$Res,
        _$ProjectPresetCategoryImpl>
    implements _$$ProjectPresetCategoryImplCopyWith<$Res> {
  __$$ProjectPresetCategoryImplCopyWithImpl(_$ProjectPresetCategoryImpl _value,
      $Res Function(_$ProjectPresetCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectPresetCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentCategoryId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectPresetCategoryImpl(
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
class _$ProjectPresetCategoryImpl implements _ProjectPresetCategory {
  const _$ProjectPresetCategoryImpl(
      {required this.id,
      required this.name,
      this.parentCategoryId,
      this.sortOrder = 0});

  factory _$ProjectPresetCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectPresetCategoryImplFromJson(json);

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
    return 'ProjectPresetCategory(id: $id, name: $name, parentCategoryId: $parentCategoryId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectPresetCategoryImpl &&
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

  /// Create a copy of ProjectPresetCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectPresetCategoryImplCopyWith<_$ProjectPresetCategoryImpl>
      get copyWith => __$$ProjectPresetCategoryImplCopyWithImpl<
          _$ProjectPresetCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectPresetCategoryImplToJson(
      this,
    );
  }
}

abstract class _ProjectPresetCategory implements ProjectPresetCategory {
  const factory _ProjectPresetCategory(
      {required final String id,
      required final String name,
      final String? parentCategoryId,
      final int sortOrder}) = _$ProjectPresetCategoryImpl;

  factory _ProjectPresetCategory.fromJson(Map<String, dynamic> json) =
      _$ProjectPresetCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentCategoryId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectPresetCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectPresetCategoryImplCopyWith<_$ProjectPresetCategoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectEncounterEntry _$ProjectEncounterEntryFromJson(
    Map<String, dynamic> json) {
  return _ProjectEncounterEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectEncounterEntry {
  /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
  String get speciesId => throw _privateConstructorUsedError;
  int get minLevel => throw _privateConstructorUsedError;
  int get maxLevel => throw _privateConstructorUsedError;

  /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
  int get weight => throw _privateConstructorUsedError;

  /// Serializes this ProjectEncounterEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectEncounterEntryCopyWith<ProjectEncounterEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectEncounterEntryCopyWith<$Res> {
  factory $ProjectEncounterEntryCopyWith(ProjectEncounterEntry value,
          $Res Function(ProjectEncounterEntry) then) =
      _$ProjectEncounterEntryCopyWithImpl<$Res, ProjectEncounterEntry>;
  @useResult
  $Res call({String speciesId, int minLevel, int maxLevel, int weight});
}

/// @nodoc
class _$ProjectEncounterEntryCopyWithImpl<$Res,
        $Val extends ProjectEncounterEntry>
    implements $ProjectEncounterEntryCopyWith<$Res> {
  _$ProjectEncounterEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? minLevel = null,
    Object? maxLevel = null,
    Object? weight = null,
  }) {
    return _then(_value.copyWith(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      minLevel: null == minLevel
          ? _value.minLevel
          : minLevel // ignore: cast_nullable_to_non_nullable
              as int,
      maxLevel: null == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectEncounterEntryImplCopyWith<$Res>
    implements $ProjectEncounterEntryCopyWith<$Res> {
  factory _$$ProjectEncounterEntryImplCopyWith(
          _$ProjectEncounterEntryImpl value,
          $Res Function(_$ProjectEncounterEntryImpl) then) =
      __$$ProjectEncounterEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String speciesId, int minLevel, int maxLevel, int weight});
}

/// @nodoc
class __$$ProjectEncounterEntryImplCopyWithImpl<$Res>
    extends _$ProjectEncounterEntryCopyWithImpl<$Res,
        _$ProjectEncounterEntryImpl>
    implements _$$ProjectEncounterEntryImplCopyWith<$Res> {
  __$$ProjectEncounterEntryImplCopyWithImpl(_$ProjectEncounterEntryImpl _value,
      $Res Function(_$ProjectEncounterEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? minLevel = null,
    Object? maxLevel = null,
    Object? weight = null,
  }) {
    return _then(_$ProjectEncounterEntryImpl(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      minLevel: null == minLevel
          ? _value.minLevel
          : minLevel // ignore: cast_nullable_to_non_nullable
              as int,
      maxLevel: null == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectEncounterEntryImpl implements _ProjectEncounterEntry {
  const _$ProjectEncounterEntryImpl(
      {required this.speciesId,
      required this.minLevel,
      required this.maxLevel,
      this.weight = 1});

  factory _$ProjectEncounterEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectEncounterEntryImplFromJson(json);

  /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
  @override
  final String speciesId;
  @override
  final int minLevel;
  @override
  final int maxLevel;

  /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
  @override
  @JsonKey()
  final int weight;

  @override
  String toString() {
    return 'ProjectEncounterEntry(speciesId: $speciesId, minLevel: $minLevel, maxLevel: $maxLevel, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectEncounterEntryImpl &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.minLevel, minLevel) ||
                other.minLevel == minLevel) &&
            (identical(other.maxLevel, maxLevel) ||
                other.maxLevel == maxLevel) &&
            (identical(other.weight, weight) || other.weight == weight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, speciesId, minLevel, maxLevel, weight);

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectEncounterEntryImplCopyWith<_$ProjectEncounterEntryImpl>
      get copyWith => __$$ProjectEncounterEntryImplCopyWithImpl<
          _$ProjectEncounterEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectEncounterEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectEncounterEntry implements ProjectEncounterEntry {
  const factory _ProjectEncounterEntry(
      {required final String speciesId,
      required final int minLevel,
      required final int maxLevel,
      final int weight}) = _$ProjectEncounterEntryImpl;

  factory _ProjectEncounterEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectEncounterEntryImpl.fromJson;

  /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
  @override
  String get speciesId;
  @override
  int get minLevel;
  @override
  int get maxLevel;

  /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
  @override
  int get weight;

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectEncounterEntryImplCopyWith<_$ProjectEncounterEntryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectEncounterTable _$ProjectEncounterTableFromJson(
    Map<String, dynamic> json) {
  return _ProjectEncounterTable.fromJson(json);
}

/// @nodoc
mixin _$ProjectEncounterTable {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  EncounterKind get encounterKind => throw _privateConstructorUsedError;
  List<ProjectEncounterEntry> get entries => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this ProjectEncounterTable to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectEncounterTableCopyWith<ProjectEncounterTable> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectEncounterTableCopyWith<$Res> {
  factory $ProjectEncounterTableCopyWith(ProjectEncounterTable value,
          $Res Function(ProjectEncounterTable) then) =
      _$ProjectEncounterTableCopyWithImpl<$Res, ProjectEncounterTable>;
  @useResult
  $Res call(
      {String id,
      String name,
      EncounterKind encounterKind,
      List<ProjectEncounterEntry> entries,
      List<String> tags});
}

/// @nodoc
class _$ProjectEncounterTableCopyWithImpl<$Res,
        $Val extends ProjectEncounterTable>
    implements $ProjectEncounterTableCopyWith<$Res> {
  _$ProjectEncounterTableCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? encounterKind = null,
    Object? entries = null,
    Object? tags = null,
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
      encounterKind: null == encounterKind
          ? _value.encounterKind
          : encounterKind // ignore: cast_nullable_to_non_nullable
              as EncounterKind,
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<ProjectEncounterEntry>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectEncounterTableImplCopyWith<$Res>
    implements $ProjectEncounterTableCopyWith<$Res> {
  factory _$$ProjectEncounterTableImplCopyWith(
          _$ProjectEncounterTableImpl value,
          $Res Function(_$ProjectEncounterTableImpl) then) =
      __$$ProjectEncounterTableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      EncounterKind encounterKind,
      List<ProjectEncounterEntry> entries,
      List<String> tags});
}

/// @nodoc
class __$$ProjectEncounterTableImplCopyWithImpl<$Res>
    extends _$ProjectEncounterTableCopyWithImpl<$Res,
        _$ProjectEncounterTableImpl>
    implements _$$ProjectEncounterTableImplCopyWith<$Res> {
  __$$ProjectEncounterTableImplCopyWithImpl(_$ProjectEncounterTableImpl _value,
      $Res Function(_$ProjectEncounterTableImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? encounterKind = null,
    Object? entries = null,
    Object? tags = null,
  }) {
    return _then(_$ProjectEncounterTableImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      encounterKind: null == encounterKind
          ? _value.encounterKind
          : encounterKind // ignore: cast_nullable_to_non_nullable
              as EncounterKind,
      entries: null == entries
          ? _value._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<ProjectEncounterEntry>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectEncounterTableImpl implements _ProjectEncounterTable {
  const _$ProjectEncounterTableImpl(
      {required this.id,
      required this.name,
      required this.encounterKind,
      final List<ProjectEncounterEntry> entries = const [],
      final List<String> tags = const []})
      : _entries = entries,
        _tags = tags;

  factory _$ProjectEncounterTableImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectEncounterTableImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final EncounterKind encounterKind;
  final List<ProjectEncounterEntry> _entries;
  @override
  @JsonKey()
  List<ProjectEncounterEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

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
    return 'ProjectEncounterTable(id: $id, name: $name, encounterKind: $encounterKind, entries: $entries, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectEncounterTableImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.encounterKind, encounterKind) ||
                other.encounterKind == encounterKind) &&
            const DeepCollectionEquality().equals(other._entries, _entries) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      encounterKind,
      const DeepCollectionEquality().hash(_entries),
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectEncounterTableImplCopyWith<_$ProjectEncounterTableImpl>
      get copyWith => __$$ProjectEncounterTableImplCopyWithImpl<
          _$ProjectEncounterTableImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectEncounterTableImplToJson(
      this,
    );
  }
}

abstract class _ProjectEncounterTable implements ProjectEncounterTable {
  const factory _ProjectEncounterTable(
      {required final String id,
      required final String name,
      required final EncounterKind encounterKind,
      final List<ProjectEncounterEntry> entries,
      final List<String> tags}) = _$ProjectEncounterTableImpl;

  factory _ProjectEncounterTable.fromJson(Map<String, dynamic> json) =
      _$ProjectEncounterTableImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  EncounterKind get encounterKind;
  @override
  List<ProjectEncounterEntry> get entries;
  @override
  List<String> get tags;

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectEncounterTableImplCopyWith<_$ProjectEncounterTableImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectCharacterEntry _$ProjectCharacterEntryFromJson(
    Map<String, dynamic> json) {
  return _ProjectCharacterEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectCharacterEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  int get frameWidth => throw _privateConstructorUsedError;
  int get frameHeight => throw _privateConstructorUsedError;
  List<CharacterAnimation> get animations => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectCharacterEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectCharacterEntryCopyWith<ProjectCharacterEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCharacterEntryCopyWith<$Res> {
  factory $ProjectCharacterEntryCopyWith(ProjectCharacterEntry value,
          $Res Function(ProjectCharacterEntry) then) =
      _$ProjectCharacterEntryCopyWithImpl<$Res, ProjectCharacterEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      int frameWidth,
      int frameHeight,
      List<CharacterAnimation> animations,
      List<String> tags,
      int sortOrder});
}

/// @nodoc
class _$ProjectCharacterEntryCopyWithImpl<$Res,
        $Val extends ProjectCharacterEntry>
    implements $ProjectCharacterEntryCopyWith<$Res> {
  _$ProjectCharacterEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? frameWidth = null,
    Object? frameHeight = null,
    Object? animations = null,
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
      frameWidth: null == frameWidth
          ? _value.frameWidth
          : frameWidth // ignore: cast_nullable_to_non_nullable
              as int,
      frameHeight: null == frameHeight
          ? _value.frameHeight
          : frameHeight // ignore: cast_nullable_to_non_nullable
              as int,
      animations: null == animations
          ? _value.animations
          : animations // ignore: cast_nullable_to_non_nullable
              as List<CharacterAnimation>,
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
}

/// @nodoc
abstract class _$$ProjectCharacterEntryImplCopyWith<$Res>
    implements $ProjectCharacterEntryCopyWith<$Res> {
  factory _$$ProjectCharacterEntryImplCopyWith(
          _$ProjectCharacterEntryImpl value,
          $Res Function(_$ProjectCharacterEntryImpl) then) =
      __$$ProjectCharacterEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      int frameWidth,
      int frameHeight,
      List<CharacterAnimation> animations,
      List<String> tags,
      int sortOrder});
}

/// @nodoc
class __$$ProjectCharacterEntryImplCopyWithImpl<$Res>
    extends _$ProjectCharacterEntryCopyWithImpl<$Res,
        _$ProjectCharacterEntryImpl>
    implements _$$ProjectCharacterEntryImplCopyWith<$Res> {
  __$$ProjectCharacterEntryImplCopyWithImpl(_$ProjectCharacterEntryImpl _value,
      $Res Function(_$ProjectCharacterEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? frameWidth = null,
    Object? frameHeight = null,
    Object? animations = null,
    Object? tags = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectCharacterEntryImpl(
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
      frameWidth: null == frameWidth
          ? _value.frameWidth
          : frameWidth // ignore: cast_nullable_to_non_nullable
              as int,
      frameHeight: null == frameHeight
          ? _value.frameHeight
          : frameHeight // ignore: cast_nullable_to_non_nullable
              as int,
      animations: null == animations
          ? _value._animations
          : animations // ignore: cast_nullable_to_non_nullable
              as List<CharacterAnimation>,
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

@JsonSerializable(explicitToJson: true)
class _$ProjectCharacterEntryImpl implements _ProjectCharacterEntry {
  const _$ProjectCharacterEntryImpl(
      {required this.id,
      required this.name,
      required this.tilesetId,
      this.frameWidth = 1,
      this.frameHeight = 2,
      final List<CharacterAnimation> animations = const [],
      final List<String> tags = const [],
      this.sortOrder = 0})
      : _animations = animations,
        _tags = tags;

  factory _$ProjectCharacterEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectCharacterEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String tilesetId;
  @override
  @JsonKey()
  final int frameWidth;
  @override
  @JsonKey()
  final int frameHeight;
  final List<CharacterAnimation> _animations;
  @override
  @JsonKey()
  List<CharacterAnimation> get animations {
    if (_animations is EqualUnmodifiableListView) return _animations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_animations);
  }

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
    return 'ProjectCharacterEntry(id: $id, name: $name, tilesetId: $tilesetId, frameWidth: $frameWidth, frameHeight: $frameHeight, animations: $animations, tags: $tags, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectCharacterEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            (identical(other.frameWidth, frameWidth) ||
                other.frameWidth == frameWidth) &&
            (identical(other.frameHeight, frameHeight) ||
                other.frameHeight == frameHeight) &&
            const DeepCollectionEquality()
                .equals(other._animations, _animations) &&
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
      frameWidth,
      frameHeight,
      const DeepCollectionEquality().hash(_animations),
      const DeepCollectionEquality().hash(_tags),
      sortOrder);

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectCharacterEntryImplCopyWith<_$ProjectCharacterEntryImpl>
      get copyWith => __$$ProjectCharacterEntryImplCopyWithImpl<
          _$ProjectCharacterEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectCharacterEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectCharacterEntry implements ProjectCharacterEntry {
  const factory _ProjectCharacterEntry(
      {required final String id,
      required final String name,
      required final String tilesetId,
      final int frameWidth,
      final int frameHeight,
      final List<CharacterAnimation> animations,
      final List<String> tags,
      final int sortOrder}) = _$ProjectCharacterEntryImpl;

  factory _ProjectCharacterEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectCharacterEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get tilesetId;
  @override
  int get frameWidth;
  @override
  int get frameHeight;
  @override
  List<CharacterAnimation> get animations;
  @override
  List<String> get tags;
  @override
  int get sortOrder;

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectCharacterEntryImplCopyWith<_$ProjectCharacterEntryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CharacterAnimation _$CharacterAnimationFromJson(Map<String, dynamic> json) {
  return _CharacterAnimation.fromJson(json);
}

/// @nodoc
mixin _$CharacterAnimation {
  CharacterAnimationState get state => throw _privateConstructorUsedError;
  EntityFacing get direction => throw _privateConstructorUsedError;
  List<CharacterAnimationFrame> get frames =>
      throw _privateConstructorUsedError;

  /// Serializes this CharacterAnimation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterAnimationCopyWith<CharacterAnimation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterAnimationCopyWith<$Res> {
  factory $CharacterAnimationCopyWith(
          CharacterAnimation value, $Res Function(CharacterAnimation) then) =
      _$CharacterAnimationCopyWithImpl<$Res, CharacterAnimation>;
  @useResult
  $Res call(
      {CharacterAnimationState state,
      EntityFacing direction,
      List<CharacterAnimationFrame> frames});
}

/// @nodoc
class _$CharacterAnimationCopyWithImpl<$Res, $Val extends CharacterAnimation>
    implements $CharacterAnimationCopyWith<$Res> {
  _$CharacterAnimationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? direction = null,
    Object? frames = null,
  }) {
    return _then(_value.copyWith(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as CharacterAnimationState,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<CharacterAnimationFrame>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CharacterAnimationImplCopyWith<$Res>
    implements $CharacterAnimationCopyWith<$Res> {
  factory _$$CharacterAnimationImplCopyWith(_$CharacterAnimationImpl value,
          $Res Function(_$CharacterAnimationImpl) then) =
      __$$CharacterAnimationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CharacterAnimationState state,
      EntityFacing direction,
      List<CharacterAnimationFrame> frames});
}

/// @nodoc
class __$$CharacterAnimationImplCopyWithImpl<$Res>
    extends _$CharacterAnimationCopyWithImpl<$Res, _$CharacterAnimationImpl>
    implements _$$CharacterAnimationImplCopyWith<$Res> {
  __$$CharacterAnimationImplCopyWithImpl(_$CharacterAnimationImpl _value,
      $Res Function(_$CharacterAnimationImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? direction = null,
    Object? frames = null,
  }) {
    return _then(_$CharacterAnimationImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as CharacterAnimationState,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<CharacterAnimationFrame>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$CharacterAnimationImpl implements _CharacterAnimation {
  const _$CharacterAnimationImpl(
      {required this.state,
      required this.direction,
      final List<CharacterAnimationFrame> frames = const []})
      : _frames = frames;

  factory _$CharacterAnimationImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterAnimationImplFromJson(json);

  @override
  final CharacterAnimationState state;
  @override
  final EntityFacing direction;
  final List<CharacterAnimationFrame> _frames;
  @override
  @JsonKey()
  List<CharacterAnimationFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  String toString() {
    return 'CharacterAnimation(state: $state, direction: $direction, frames: $frames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterAnimationImpl &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            const DeepCollectionEquality().equals(other._frames, _frames));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, state, direction,
      const DeepCollectionEquality().hash(_frames));

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterAnimationImplCopyWith<_$CharacterAnimationImpl> get copyWith =>
      __$$CharacterAnimationImplCopyWithImpl<_$CharacterAnimationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterAnimationImplToJson(
      this,
    );
  }
}

abstract class _CharacterAnimation implements CharacterAnimation {
  const factory _CharacterAnimation(
      {required final CharacterAnimationState state,
      required final EntityFacing direction,
      final List<CharacterAnimationFrame> frames}) = _$CharacterAnimationImpl;

  factory _CharacterAnimation.fromJson(Map<String, dynamic> json) =
      _$CharacterAnimationImpl.fromJson;

  @override
  CharacterAnimationState get state;
  @override
  EntityFacing get direction;
  @override
  List<CharacterAnimationFrame> get frames;

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterAnimationImplCopyWith<_$CharacterAnimationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CharacterAnimationFrame _$CharacterAnimationFrameFromJson(
    Map<String, dynamic> json) {
  return _CharacterAnimationFrame.fromJson(json);
}

/// @nodoc
mixin _$CharacterAnimationFrame {
  TilesetSourceRect get source => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;

  /// Serializes this CharacterAnimationFrame to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterAnimationFrameCopyWith<CharacterAnimationFrame> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterAnimationFrameCopyWith<$Res> {
  factory $CharacterAnimationFrameCopyWith(CharacterAnimationFrame value,
          $Res Function(CharacterAnimationFrame) then) =
      _$CharacterAnimationFrameCopyWithImpl<$Res, CharacterAnimationFrame>;
  @useResult
  $Res call({TilesetSourceRect source, int durationMs});

  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class _$CharacterAnimationFrameCopyWithImpl<$Res,
        $Val extends CharacterAnimationFrame>
    implements $CharacterAnimationFrameCopyWith<$Res> {
  _$CharacterAnimationFrameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? durationMs = null,
  }) {
    return _then(_value.copyWith(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of CharacterAnimationFrame
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
abstract class _$$CharacterAnimationFrameImplCopyWith<$Res>
    implements $CharacterAnimationFrameCopyWith<$Res> {
  factory _$$CharacterAnimationFrameImplCopyWith(
          _$CharacterAnimationFrameImpl value,
          $Res Function(_$CharacterAnimationFrameImpl) then) =
      __$$CharacterAnimationFrameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TilesetSourceRect source, int durationMs});

  @override
  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class __$$CharacterAnimationFrameImplCopyWithImpl<$Res>
    extends _$CharacterAnimationFrameCopyWithImpl<$Res,
        _$CharacterAnimationFrameImpl>
    implements _$$CharacterAnimationFrameImplCopyWith<$Res> {
  __$$CharacterAnimationFrameImplCopyWithImpl(
      _$CharacterAnimationFrameImpl _value,
      $Res Function(_$CharacterAnimationFrameImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? durationMs = null,
  }) {
    return _then(_$CharacterAnimationFrameImpl(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$CharacterAnimationFrameImpl implements _CharacterAnimationFrame {
  const _$CharacterAnimationFrameImpl(
      {required this.source, this.durationMs = 150});

  factory _$CharacterAnimationFrameImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterAnimationFrameImplFromJson(json);

  @override
  final TilesetSourceRect source;
  @override
  @JsonKey()
  final int durationMs;

  @override
  String toString() {
    return 'CharacterAnimationFrame(source: $source, durationMs: $durationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterAnimationFrameImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, source, durationMs);

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterAnimationFrameImplCopyWith<_$CharacterAnimationFrameImpl>
      get copyWith => __$$CharacterAnimationFrameImplCopyWithImpl<
          _$CharacterAnimationFrameImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterAnimationFrameImplToJson(
      this,
    );
  }
}

abstract class _CharacterAnimationFrame implements CharacterAnimationFrame {
  const factory _CharacterAnimationFrame(
      {required final TilesetSourceRect source,
      final int durationMs}) = _$CharacterAnimationFrameImpl;

  factory _CharacterAnimationFrame.fromJson(Map<String, dynamic> json) =
      _$CharacterAnimationFrameImpl.fromJson;

  @override
  TilesetSourceRect get source;
  @override
  int get durationMs;

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterAnimationFrameImplCopyWith<_$CharacterAnimationFrameImpl>
      get copyWith => throw _privateConstructorUsedError;
}
