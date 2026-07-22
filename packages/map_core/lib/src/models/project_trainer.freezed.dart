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

ProjectTrainerItemGrant _$ProjectTrainerItemGrantFromJson(
    Map<String, dynamic> json) {
  return _ProjectTrainerItemGrant.fromJson(json);
}

/// @nodoc
mixin _$ProjectTrainerItemGrant {
  String get itemId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _projectTrainerItemQuantityFromJson)
  int get quantity => throw _privateConstructorUsedError;

  /// Serializes this ProjectTrainerItemGrant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTrainerItemGrant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTrainerItemGrantCopyWith<ProjectTrainerItemGrant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTrainerItemGrantCopyWith<$Res> {
  factory $ProjectTrainerItemGrantCopyWith(ProjectTrainerItemGrant value,
          $Res Function(ProjectTrainerItemGrant) then) =
      _$ProjectTrainerItemGrantCopyWithImpl<$Res, ProjectTrainerItemGrant>;
  @useResult
  $Res call(
      {String itemId,
      @JsonKey(fromJson: _projectTrainerItemQuantityFromJson) int quantity});
}

/// @nodoc
class _$ProjectTrainerItemGrantCopyWithImpl<$Res,
        $Val extends ProjectTrainerItemGrant>
    implements $ProjectTrainerItemGrantCopyWith<$Res> {
  _$ProjectTrainerItemGrantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTrainerItemGrant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? quantity = null,
  }) {
    return _then(_value.copyWith(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTrainerItemGrantImplCopyWith<$Res>
    implements $ProjectTrainerItemGrantCopyWith<$Res> {
  factory _$$ProjectTrainerItemGrantImplCopyWith(
          _$ProjectTrainerItemGrantImpl value,
          $Res Function(_$ProjectTrainerItemGrantImpl) then) =
      __$$ProjectTrainerItemGrantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String itemId,
      @JsonKey(fromJson: _projectTrainerItemQuantityFromJson) int quantity});
}

/// @nodoc
class __$$ProjectTrainerItemGrantImplCopyWithImpl<$Res>
    extends _$ProjectTrainerItemGrantCopyWithImpl<$Res,
        _$ProjectTrainerItemGrantImpl>
    implements _$$ProjectTrainerItemGrantImplCopyWith<$Res> {
  __$$ProjectTrainerItemGrantImplCopyWithImpl(
      _$ProjectTrainerItemGrantImpl _value,
      $Res Function(_$ProjectTrainerItemGrantImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTrainerItemGrant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? quantity = null,
  }) {
    return _then(_$ProjectTrainerItemGrantImpl(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTrainerItemGrantImpl implements _ProjectTrainerItemGrant {
  const _$ProjectTrainerItemGrantImpl(
      {required this.itemId,
      @JsonKey(fromJson: _projectTrainerItemQuantityFromJson)
      this.quantity = 1});

  factory _$ProjectTrainerItemGrantImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTrainerItemGrantImplFromJson(json);

  @override
  final String itemId;
  @override
  @JsonKey(fromJson: _projectTrainerItemQuantityFromJson)
  final int quantity;

  @override
  String toString() {
    return 'ProjectTrainerItemGrant(itemId: $itemId, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTrainerItemGrantImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, itemId, quantity);

  /// Create a copy of ProjectTrainerItemGrant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTrainerItemGrantImplCopyWith<_$ProjectTrainerItemGrantImpl>
      get copyWith => __$$ProjectTrainerItemGrantImplCopyWithImpl<
          _$ProjectTrainerItemGrantImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTrainerItemGrantImplToJson(
      this,
    );
  }
}

abstract class _ProjectTrainerItemGrant implements ProjectTrainerItemGrant {
  const factory _ProjectTrainerItemGrant(
      {required final String itemId,
      @JsonKey(fromJson: _projectTrainerItemQuantityFromJson)
      final int quantity}) = _$ProjectTrainerItemGrantImpl;

  factory _ProjectTrainerItemGrant.fromJson(Map<String, dynamic> json) =
      _$ProjectTrainerItemGrantImpl.fromJson;

  @override
  String get itemId;
  @override
  @JsonKey(fromJson: _projectTrainerItemQuantityFromJson)
  int get quantity;

  /// Create a copy of ProjectTrainerItemGrant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTrainerItemGrantImplCopyWith<_$ProjectTrainerItemGrantImpl>
      get copyWith => throw _privateConstructorUsedError;
}

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

  /// Difficulté produit battle exprimée sur l'échelle lisible `1..10`.
  ///
  /// Ce champ reste volontairement optionnel pour deux raisons :
  /// - préserver les anciens trainers du dépôt sans migration forcée ;
  /// - laisser le runtime retomber sur le comportement historique quand
  ///   aucune difficulté explicite n'a encore été authored.
  ///
  /// Interprétation de périmètre :
  /// - cette valeur ne décrit que la sélection d'action adverse en combat ;
  /// - elle n'ouvre ni scripts trainer, ni phases boss, ni switch/replacement
  ///   intelligents ;
  /// - le routing réel vers quelques profils battle-local reste fait côté
  ///   runtime + `map_battle`, pas dans ce modèle data.
  int? get battleDifficulty => throw _privateConstructorUsedError;

  /// Image de fond de combat explicitement authored pour ce trainer.
  ///
  /// Ce champ reste volontairement petit et purement data :
  /// - il stocke un chemin relatif au projet, pas un asset handle global ;
  /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
  ///   métier battle ;
  /// - il permet simplement au runtime de prioriser un fond explicite
  ///   trainer avant le fond contextuel du lot 2 ;
  /// - s'il est absent ou inutilisable, le runtime retombe honnêtement sur
  ///   sa chaîne `explicite > contextuel > fallback`.
  String? get battleBackgroundRelativePath =>
      throw _privateConstructorUsedError;
  String? get characterId => throw _privateConstructorUsedError;
  String? get portraitElementId => throw _privateConstructorUsedError;
  String? get battleThemeId => throw _privateConstructorUsedError;
  String? get victoryThemeId => throw _privateConstructorUsedError;

  /// Récompenses auteur neutres par défaut pour préserver les projets
  /// historiques. Leur application runtime appartient aux lots suivants.
  @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson)
  int get moneyReward => throw _privateConstructorUsedError;
  List<ProjectTrainerItemGrant> get rewardItemGrants =>
      throw _privateConstructorUsedError;
  List<String> get rewardFlagIds => throw _privateConstructorUsedError;
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
      int? battleDifficulty,
      String? battleBackgroundRelativePath,
      String? characterId,
      String? portraitElementId,
      String? battleThemeId,
      String? victoryThemeId,
      @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson) int moneyReward,
      List<ProjectTrainerItemGrant> rewardItemGrants,
      List<String> rewardFlagIds,
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
    Object? battleDifficulty = freezed,
    Object? battleBackgroundRelativePath = freezed,
    Object? characterId = freezed,
    Object? portraitElementId = freezed,
    Object? battleThemeId = freezed,
    Object? victoryThemeId = freezed,
    Object? moneyReward = null,
    Object? rewardItemGrants = null,
    Object? rewardFlagIds = null,
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
      battleDifficulty: freezed == battleDifficulty
          ? _value.battleDifficulty
          : battleDifficulty // ignore: cast_nullable_to_non_nullable
              as int?,
      battleBackgroundRelativePath: freezed == battleBackgroundRelativePath
          ? _value.battleBackgroundRelativePath
          : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
              as String?,
      characterId: freezed == characterId
          ? _value.characterId
          : characterId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      moneyReward: null == moneyReward
          ? _value.moneyReward
          : moneyReward // ignore: cast_nullable_to_non_nullable
              as int,
      rewardItemGrants: null == rewardItemGrants
          ? _value.rewardItemGrants
          : rewardItemGrants // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerItemGrant>,
      rewardFlagIds: null == rewardFlagIds
          ? _value.rewardFlagIds
          : rewardFlagIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      int? battleDifficulty,
      String? battleBackgroundRelativePath,
      String? characterId,
      String? portraitElementId,
      String? battleThemeId,
      String? victoryThemeId,
      @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson) int moneyReward,
      List<ProjectTrainerItemGrant> rewardItemGrants,
      List<String> rewardFlagIds,
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
    Object? battleDifficulty = freezed,
    Object? battleBackgroundRelativePath = freezed,
    Object? characterId = freezed,
    Object? portraitElementId = freezed,
    Object? battleThemeId = freezed,
    Object? victoryThemeId = freezed,
    Object? moneyReward = null,
    Object? rewardItemGrants = null,
    Object? rewardFlagIds = null,
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
      battleDifficulty: freezed == battleDifficulty
          ? _value.battleDifficulty
          : battleDifficulty // ignore: cast_nullable_to_non_nullable
              as int?,
      battleBackgroundRelativePath: freezed == battleBackgroundRelativePath
          ? _value.battleBackgroundRelativePath
          : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
              as String?,
      characterId: freezed == characterId
          ? _value.characterId
          : characterId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      moneyReward: null == moneyReward
          ? _value.moneyReward
          : moneyReward // ignore: cast_nullable_to_non_nullable
              as int,
      rewardItemGrants: null == rewardItemGrants
          ? _value._rewardItemGrants
          : rewardItemGrants // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerItemGrant>,
      rewardFlagIds: null == rewardFlagIds
          ? _value._rewardFlagIds
          : rewardFlagIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      this.battleDifficulty,
      this.battleBackgroundRelativePath,
      this.characterId,
      this.portraitElementId,
      this.battleThemeId,
      this.victoryThemeId,
      @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson)
      this.moneyReward = 0,
      final List<ProjectTrainerItemGrant> rewardItemGrants = const [],
      final List<String> rewardFlagIds = const [],
      final List<ProjectTrainerPokemonEntry> team = const [],
      final List<String> tags = const []})
      : _rewardItemGrants = rewardItemGrants,
        _rewardFlagIds = rewardFlagIds,
        _team = team,
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

  /// Difficulté produit battle exprimée sur l'échelle lisible `1..10`.
  ///
  /// Ce champ reste volontairement optionnel pour deux raisons :
  /// - préserver les anciens trainers du dépôt sans migration forcée ;
  /// - laisser le runtime retomber sur le comportement historique quand
  ///   aucune difficulté explicite n'a encore été authored.
  ///
  /// Interprétation de périmètre :
  /// - cette valeur ne décrit que la sélection d'action adverse en combat ;
  /// - elle n'ouvre ni scripts trainer, ni phases boss, ni switch/replacement
  ///   intelligents ;
  /// - le routing réel vers quelques profils battle-local reste fait côté
  ///   runtime + `map_battle`, pas dans ce modèle data.
  @override
  final int? battleDifficulty;

  /// Image de fond de combat explicitement authored pour ce trainer.
  ///
  /// Ce champ reste volontairement petit et purement data :
  /// - il stocke un chemin relatif au projet, pas un asset handle global ;
  /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
  ///   métier battle ;
  /// - il permet simplement au runtime de prioriser un fond explicite
  ///   trainer avant le fond contextuel du lot 2 ;
  /// - s'il est absent ou inutilisable, le runtime retombe honnêtement sur
  ///   sa chaîne `explicite > contextuel > fallback`.
  @override
  final String? battleBackgroundRelativePath;
  @override
  final String? characterId;
  @override
  final String? portraitElementId;
  @override
  final String? battleThemeId;
  @override
  final String? victoryThemeId;

  /// Récompenses auteur neutres par défaut pour préserver les projets
  /// historiques. Leur application runtime appartient aux lots suivants.
  @override
  @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson)
  final int moneyReward;
  final List<ProjectTrainerItemGrant> _rewardItemGrants;
  @override
  @JsonKey()
  List<ProjectTrainerItemGrant> get rewardItemGrants {
    if (_rewardItemGrants is EqualUnmodifiableListView)
      return _rewardItemGrants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rewardItemGrants);
  }

  final List<String> _rewardFlagIds;
  @override
  @JsonKey()
  List<String> get rewardFlagIds {
    if (_rewardFlagIds is EqualUnmodifiableListView) return _rewardFlagIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rewardFlagIds);
  }

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
    return 'ProjectTrainerEntry(id: $id, name: $name, trainerClass: $trainerClass, battleDifficulty: $battleDifficulty, battleBackgroundRelativePath: $battleBackgroundRelativePath, characterId: $characterId, portraitElementId: $portraitElementId, battleThemeId: $battleThemeId, victoryThemeId: $victoryThemeId, moneyReward: $moneyReward, rewardItemGrants: $rewardItemGrants, rewardFlagIds: $rewardFlagIds, team: $team, tags: $tags)';
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
            (identical(other.battleDifficulty, battleDifficulty) ||
                other.battleDifficulty == battleDifficulty) &&
            (identical(other.battleBackgroundRelativePath,
                    battleBackgroundRelativePath) ||
                other.battleBackgroundRelativePath ==
                    battleBackgroundRelativePath) &&
            (identical(other.characterId, characterId) ||
                other.characterId == characterId) &&
            (identical(other.portraitElementId, portraitElementId) ||
                other.portraitElementId == portraitElementId) &&
            (identical(other.battleThemeId, battleThemeId) ||
                other.battleThemeId == battleThemeId) &&
            (identical(other.victoryThemeId, victoryThemeId) ||
                other.victoryThemeId == victoryThemeId) &&
            (identical(other.moneyReward, moneyReward) ||
                other.moneyReward == moneyReward) &&
            const DeepCollectionEquality()
                .equals(other._rewardItemGrants, _rewardItemGrants) &&
            const DeepCollectionEquality()
                .equals(other._rewardFlagIds, _rewardFlagIds) &&
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
      battleDifficulty,
      battleBackgroundRelativePath,
      characterId,
      portraitElementId,
      battleThemeId,
      victoryThemeId,
      moneyReward,
      const DeepCollectionEquality().hash(_rewardItemGrants),
      const DeepCollectionEquality().hash(_rewardFlagIds),
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
      final int? battleDifficulty,
      final String? battleBackgroundRelativePath,
      final String? characterId,
      final String? portraitElementId,
      final String? battleThemeId,
      final String? victoryThemeId,
      @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson)
      final int moneyReward,
      final List<ProjectTrainerItemGrant> rewardItemGrants,
      final List<String> rewardFlagIds,
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

  /// Difficulté produit battle exprimée sur l'échelle lisible `1..10`.
  ///
  /// Ce champ reste volontairement optionnel pour deux raisons :
  /// - préserver les anciens trainers du dépôt sans migration forcée ;
  /// - laisser le runtime retomber sur le comportement historique quand
  ///   aucune difficulté explicite n'a encore été authored.
  ///
  /// Interprétation de périmètre :
  /// - cette valeur ne décrit que la sélection d'action adverse en combat ;
  /// - elle n'ouvre ni scripts trainer, ni phases boss, ni switch/replacement
  ///   intelligents ;
  /// - le routing réel vers quelques profils battle-local reste fait côté
  ///   runtime + `map_battle`, pas dans ce modèle data.
  @override
  int? get battleDifficulty;

  /// Image de fond de combat explicitement authored pour ce trainer.
  ///
  /// Ce champ reste volontairement petit et purement data :
  /// - il stocke un chemin relatif au projet, pas un asset handle global ;
  /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
  ///   métier battle ;
  /// - il permet simplement au runtime de prioriser un fond explicite
  ///   trainer avant le fond contextuel du lot 2 ;
  /// - s'il est absent ou inutilisable, le runtime retombe honnêtement sur
  ///   sa chaîne `explicite > contextuel > fallback`.
  @override
  String? get battleBackgroundRelativePath;
  @override
  String? get characterId;
  @override
  String? get portraitElementId;
  @override
  String? get battleThemeId;
  @override
  String? get victoryThemeId;

  /// Récompenses auteur neutres par défaut pour préserver les projets
  /// historiques. Leur application runtime appartient aux lots suivants.
  @override
  @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson)
  int get moneyReward;
  @override
  List<ProjectTrainerItemGrant> get rewardItemGrants;
  @override
  List<String> get rewardFlagIds;
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
