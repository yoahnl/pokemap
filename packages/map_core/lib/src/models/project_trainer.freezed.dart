// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_trainer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProjectTrainerPokemonEntry _$ProjectTrainerPokemonEntryFromJson(
    Map<String, dynamic> json) {
  return _ProjectTrainerPokemonEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectTrainerPokemonEntry {
  String get speciesId => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;

  /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
  List<String> get moves => throw _privateConstructorUsedError;
  String? get heldItemId => throw _privateConstructorUsedError;
  String? get formId => throw _privateConstructorUsedError;

  /// Genre libre : "male", "female", "any", ou null = non spécifié.
  String? get gender => throw _privateConstructorUsedError;
  bool get shiny => throw _privateConstructorUsedError;

  /// Serializes this ProjectTrainerPokemonEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTrainerPokemonEntryCopyWith<ProjectTrainerPokemonEntry>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTrainerPokemonEntryCopyWith<$Res> {
  factory $ProjectTrainerPokemonEntryCopyWith(ProjectTrainerPokemonEntry value,
          $Res Function(ProjectTrainerPokemonEntry) then) =
      _$ProjectTrainerPokemonEntryCopyWithImpl<$Res,
          ProjectTrainerPokemonEntry>;
  @useResult
  $Res call(
      {String speciesId,
      int level,
      List<String> moves,
      String? heldItemId,
      String? formId,
      String? gender,
      bool shiny});
}

/// @nodoc
class _$ProjectTrainerPokemonEntryCopyWithImpl<$Res,
        $Val extends ProjectTrainerPokemonEntry>
    implements $ProjectTrainerPokemonEntryCopyWith<$Res> {
  _$ProjectTrainerPokemonEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? level = null,
    Object? moves = null,
    Object? heldItemId = freezed,
    Object? formId = freezed,
    Object? gender = freezed,
    Object? shiny = null,
  }) {
    return _then(_value.copyWith(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      moves: null == moves
          ? _value.moves
          : moves // ignore: cast_nullable_to_non_nullable
              as List<String>,
      heldItemId: freezed == heldItemId
          ? _value.heldItemId
          : heldItemId // ignore: cast_nullable_to_non_nullable
              as String?,
      formId: freezed == formId
          ? _value.formId
          : formId // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      shiny: null == shiny
          ? _value.shiny
          : shiny // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTrainerPokemonEntryImplCopyWith<$Res>
    implements $ProjectTrainerPokemonEntryCopyWith<$Res> {
  factory _$$ProjectTrainerPokemonEntryImplCopyWith(
          _$ProjectTrainerPokemonEntryImpl value,
          $Res Function(_$ProjectTrainerPokemonEntryImpl) then) =
      __$$ProjectTrainerPokemonEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String speciesId,
      int level,
      List<String> moves,
      String? heldItemId,
      String? formId,
      String? gender,
      bool shiny});
}

/// @nodoc
class __$$ProjectTrainerPokemonEntryImplCopyWithImpl<$Res>
    extends _$ProjectTrainerPokemonEntryCopyWithImpl<$Res,
        _$ProjectTrainerPokemonEntryImpl>
    implements _$$ProjectTrainerPokemonEntryImplCopyWith<$Res> {
  __$$ProjectTrainerPokemonEntryImplCopyWithImpl(
      _$ProjectTrainerPokemonEntryImpl _value,
      $Res Function(_$ProjectTrainerPokemonEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? level = null,
    Object? moves = null,
    Object? heldItemId = freezed,
    Object? formId = freezed,
    Object? gender = freezed,
    Object? shiny = null,
  }) {
    return _then(_$ProjectTrainerPokemonEntryImpl(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      moves: null == moves
          ? _value._moves
          : moves // ignore: cast_nullable_to_non_nullable
              as List<String>,
      heldItemId: freezed == heldItemId
          ? _value.heldItemId
          : heldItemId // ignore: cast_nullable_to_non_nullable
              as String?,
      formId: freezed == formId
          ? _value.formId
          : formId // ignore: cast_nullable_to_non_nullable
              as String?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      shiny: null == shiny
          ? _value.shiny
          : shiny // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTrainerPokemonEntryImpl implements _ProjectTrainerPokemonEntry {
  const _$ProjectTrainerPokemonEntryImpl(
      {required this.speciesId,
      required this.level,
      final List<String> moves = const [],
      this.heldItemId,
      this.formId,
      this.gender,
      this.shiny = false})
      : _moves = moves;

  factory _$ProjectTrainerPokemonEntryImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ProjectTrainerPokemonEntryImplFromJson(json);

  @override
  final String speciesId;
  @override
  final int level;

  /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
  final List<String> _moves;

  /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
  @override
  @JsonKey()
  List<String> get moves {
    if (_moves is EqualUnmodifiableListView) return _moves;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_moves);
  }

  @override
  final String? heldItemId;
  @override
  final String? formId;

  /// Genre libre : "male", "female", "any", ou null = non spécifié.
  @override
  final String? gender;
  @override
  @JsonKey()
  final bool shiny;

  @override
  String toString() {
    return 'ProjectTrainerPokemonEntry(speciesId: $speciesId, level: $level, moves: $moves, heldItemId: $heldItemId, formId: $formId, gender: $gender, shiny: $shiny)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTrainerPokemonEntryImpl &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality().equals(other._moves, _moves) &&
            (identical(other.heldItemId, heldItemId) ||
                other.heldItemId == heldItemId) &&
            (identical(other.formId, formId) || other.formId == formId) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.shiny, shiny) || other.shiny == shiny));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      speciesId,
      level,
      const DeepCollectionEquality().hash(_moves),
      heldItemId,
      formId,
      gender,
      shiny);

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTrainerPokemonEntryImplCopyWith<_$ProjectTrainerPokemonEntryImpl>
      get copyWith => __$$ProjectTrainerPokemonEntryImplCopyWithImpl<
          _$ProjectTrainerPokemonEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTrainerPokemonEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectTrainerPokemonEntry
    implements ProjectTrainerPokemonEntry {
  const factory _ProjectTrainerPokemonEntry(
      {required final String speciesId,
      required final int level,
      final List<String> moves,
      final String? heldItemId,
      final String? formId,
      final String? gender,
      final bool shiny}) = _$ProjectTrainerPokemonEntryImpl;

  factory _ProjectTrainerPokemonEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectTrainerPokemonEntryImpl.fromJson;

  @override
  String get speciesId;
  @override
  int get level;

  /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
  @override
  List<String> get moves;
  @override
  String? get heldItemId;
  @override
  String? get formId;

  /// Genre libre : "male", "female", "any", ou null = non spécifié.
  @override
  String? get gender;
  @override
  bool get shiny;

  /// Create a copy of ProjectTrainerPokemonEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTrainerPokemonEntryImplCopyWith<_$ProjectTrainerPokemonEntryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectTrainerEntry _$ProjectTrainerEntryFromJson(Map<String, dynamic> json) {
  return _ProjectTrainerEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectTrainerEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
  String get trainerClass => throw _privateConstructorUsedError;

  /// Référence à un [ProjectElementEntry.id] pour le portrait (éditeur).
  String? get portraitElementId => throw _privateConstructorUsedError;
  String? get battleThemeId => throw _privateConstructorUsedError;
  String? get victoryThemeId => throw _privateConstructorUsedError;
  List<ProjectTrainerPokemonEntry> get team =>
      throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this ProjectTrainerEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTrainerEntryCopyWith<ProjectTrainerEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTrainerEntryCopyWith<$Res> {
  factory $ProjectTrainerEntryCopyWith(
          ProjectTrainerEntry value, $Res Function(ProjectTrainerEntry) then) =
      _$ProjectTrainerEntryCopyWithImpl<$Res, ProjectTrainerEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String trainerClass,
      String? portraitElementId,
      String? battleThemeId,
      String? victoryThemeId,
      List<ProjectTrainerPokemonEntry> team,
      List<String> tags});
}

/// @nodoc
class _$ProjectTrainerEntryCopyWithImpl<$Res, $Val extends ProjectTrainerEntry>
    implements $ProjectTrainerEntryCopyWith<$Res> {
  _$ProjectTrainerEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? trainerClass = null,
    Object? portraitElementId = freezed,
    Object? battleThemeId = freezed,
    Object? victoryThemeId = freezed,
    Object? team = null,
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
      trainerClass: null == trainerClass
          ? _value.trainerClass
          : trainerClass // ignore: cast_nullable_to_non_nullable
              as String,
      portraitElementId: freezed == portraitElementId
          ? _value.portraitElementId
          : portraitElementId // ignore: cast_nullable_to_non_nullable
              as String?,
      battleThemeId: freezed == battleThemeId
          ? _value.battleThemeId
          : battleThemeId // ignore: cast_nullable_to_non_nullable
              as String?,
      victoryThemeId: freezed == victoryThemeId
          ? _value.victoryThemeId
          : victoryThemeId // ignore: cast_nullable_to_non_nullable
              as String?,
      team: null == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerPokemonEntry>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTrainerEntryImplCopyWith<$Res>
    implements $ProjectTrainerEntryCopyWith<$Res> {
  factory _$$ProjectTrainerEntryImplCopyWith(_$ProjectTrainerEntryImpl value,
          $Res Function(_$ProjectTrainerEntryImpl) then) =
      __$$ProjectTrainerEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String trainerClass,
      String? portraitElementId,
      String? battleThemeId,
      String? victoryThemeId,
      List<ProjectTrainerPokemonEntry> team,
      List<String> tags});
}

/// @nodoc
class __$$ProjectTrainerEntryImplCopyWithImpl<$Res>
    extends _$ProjectTrainerEntryCopyWithImpl<$Res, _$ProjectTrainerEntryImpl>
    implements _$$ProjectTrainerEntryImplCopyWith<$Res> {
  __$$ProjectTrainerEntryImplCopyWithImpl(_$ProjectTrainerEntryImpl _value,
      $Res Function(_$ProjectTrainerEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? trainerClass = null,
    Object? portraitElementId = freezed,
    Object? battleThemeId = freezed,
    Object? victoryThemeId = freezed,
    Object? team = null,
    Object? tags = null,
  }) {
    return _then(_$ProjectTrainerEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      trainerClass: null == trainerClass
          ? _value.trainerClass
          : trainerClass // ignore: cast_nullable_to_non_nullable
              as String,
      portraitElementId: freezed == portraitElementId
          ? _value.portraitElementId
          : portraitElementId // ignore: cast_nullable_to_non_nullable
              as String?,
      battleThemeId: freezed == battleThemeId
          ? _value.battleThemeId
          : battleThemeId // ignore: cast_nullable_to_non_nullable
              as String?,
      victoryThemeId: freezed == victoryThemeId
          ? _value.victoryThemeId
          : victoryThemeId // ignore: cast_nullable_to_non_nullable
              as String?,
      team: null == team
          ? _value._team
          : team // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerPokemonEntry>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectTrainerEntryImpl implements _ProjectTrainerEntry {
  const _$ProjectTrainerEntryImpl(
      {required this.id,
      required this.name,
      required this.trainerClass,
      this.portraitElementId,
      this.battleThemeId,
      this.victoryThemeId,
      final List<ProjectTrainerPokemonEntry> team = const [],
      final List<String> tags = const []})
      : _team = team,
        _tags = tags;

  factory _$ProjectTrainerEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTrainerEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  /// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
  @override
  final String trainerClass;

  /// Référence à un [ProjectElementEntry.id] pour le portrait (éditeur).
  @override
  final String? portraitElementId;
  @override
  final String? battleThemeId;
  @override
  final String? victoryThemeId;
  final List<ProjectTrainerPokemonEntry> _team;
  @override
  @JsonKey()
  List<ProjectTrainerPokemonEntry> get team {
    if (_team is EqualUnmodifiableListView) return _team;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_team);
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
    return 'ProjectTrainerEntry(id: $id, name: $name, trainerClass: $trainerClass, portraitElementId: $portraitElementId, battleThemeId: $battleThemeId, victoryThemeId: $victoryThemeId, team: $team, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTrainerEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.trainerClass, trainerClass) ||
                other.trainerClass == trainerClass) &&
            (identical(other.portraitElementId, portraitElementId) ||
                other.portraitElementId == portraitElementId) &&
            (identical(other.battleThemeId, battleThemeId) ||
                other.battleThemeId == battleThemeId) &&
            (identical(other.victoryThemeId, victoryThemeId) ||
                other.victoryThemeId == victoryThemeId) &&
            const DeepCollectionEquality().equals(other._team, _team) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      trainerClass,
      portraitElementId,
      battleThemeId,
      victoryThemeId,
      const DeepCollectionEquality().hash(_team),
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTrainerEntryImplCopyWith<_$ProjectTrainerEntryImpl> get copyWith =>
      __$$ProjectTrainerEntryImplCopyWithImpl<_$ProjectTrainerEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTrainerEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectTrainerEntry implements ProjectTrainerEntry {
  const factory _ProjectTrainerEntry(
      {required final String id,
      required final String name,
      required final String trainerClass,
      final String? portraitElementId,
      final String? battleThemeId,
      final String? victoryThemeId,
      final List<ProjectTrainerPokemonEntry> team,
      final List<String> tags}) = _$ProjectTrainerEntryImpl;

  factory _ProjectTrainerEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectTrainerEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
  @override
  String get trainerClass;

  /// Référence à un [ProjectElementEntry.id] pour le portrait (éditeur).
  @override
  String? get portraitElementId;
  @override
  String? get battleThemeId;
  @override
  String? get victoryThemeId;
  @override
  List<ProjectTrainerPokemonEntry> get team;
  @override
  List<String> get tags;

  /// Create a copy of ProjectTrainerEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTrainerEntryImplCopyWith<_$ProjectTrainerEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
