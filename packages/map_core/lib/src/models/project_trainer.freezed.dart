// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_trainer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectTrainerItemGrant {

 String get itemId;@JsonKey(fromJson: _projectTrainerItemQuantityFromJson) int get quantity;
/// Create a copy of ProjectTrainerItemGrant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTrainerItemGrantCopyWith<ProjectTrainerItemGrant> get copyWith => _$ProjectTrainerItemGrantCopyWithImpl<ProjectTrainerItemGrant>(this as ProjectTrainerItemGrant, _$identity);

  /// Serializes this ProjectTrainerItemGrant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTrainerItemGrant&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,quantity);

@override
String toString() {
  return 'ProjectTrainerItemGrant(itemId: $itemId, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $ProjectTrainerItemGrantCopyWith<$Res>  {
  factory $ProjectTrainerItemGrantCopyWith(ProjectTrainerItemGrant value, $Res Function(ProjectTrainerItemGrant) _then) = _$ProjectTrainerItemGrantCopyWithImpl;
@useResult
$Res call({
 String itemId,@JsonKey(fromJson: _projectTrainerItemQuantityFromJson) int quantity
});




}
/// @nodoc
class _$ProjectTrainerItemGrantCopyWithImpl<$Res>
    implements $ProjectTrainerItemGrantCopyWith<$Res> {
  _$ProjectTrainerItemGrantCopyWithImpl(this._self, this._then);

  final ProjectTrainerItemGrant _self;
  final $Res Function(ProjectTrainerItemGrant) _then;

/// Create a copy of ProjectTrainerItemGrant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTrainerItemGrant].
extension ProjectTrainerItemGrantPatterns on ProjectTrainerItemGrant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTrainerItemGrant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTrainerItemGrant() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTrainerItemGrant value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTrainerItemGrant():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTrainerItemGrant value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTrainerItemGrant() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId, @JsonKey(fromJson: _projectTrainerItemQuantityFromJson)  int quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTrainerItemGrant() when $default != null:
return $default(_that.itemId,_that.quantity);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId, @JsonKey(fromJson: _projectTrainerItemQuantityFromJson)  int quantity)  $default,) {final _that = this;
switch (_that) {
case _ProjectTrainerItemGrant():
return $default(_that.itemId,_that.quantity);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId, @JsonKey(fromJson: _projectTrainerItemQuantityFromJson)  int quantity)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTrainerItemGrant() when $default != null:
return $default(_that.itemId,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectTrainerItemGrant implements ProjectTrainerItemGrant {
  const _ProjectTrainerItemGrant({required this.itemId, @JsonKey(fromJson: _projectTrainerItemQuantityFromJson) this.quantity = 1});
  factory _ProjectTrainerItemGrant.fromJson(Map<String, dynamic> json) => _$ProjectTrainerItemGrantFromJson(json);

@override final  String itemId;
@override@JsonKey(fromJson: _projectTrainerItemQuantityFromJson) final  int quantity;

/// Create a copy of ProjectTrainerItemGrant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTrainerItemGrantCopyWith<_ProjectTrainerItemGrant> get copyWith => __$ProjectTrainerItemGrantCopyWithImpl<_ProjectTrainerItemGrant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTrainerItemGrantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTrainerItemGrant&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,quantity);

@override
String toString() {
  return 'ProjectTrainerItemGrant(itemId: $itemId, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$ProjectTrainerItemGrantCopyWith<$Res> implements $ProjectTrainerItemGrantCopyWith<$Res> {
  factory _$ProjectTrainerItemGrantCopyWith(_ProjectTrainerItemGrant value, $Res Function(_ProjectTrainerItemGrant) _then) = __$ProjectTrainerItemGrantCopyWithImpl;
@override @useResult
$Res call({
 String itemId,@JsonKey(fromJson: _projectTrainerItemQuantityFromJson) int quantity
});




}
/// @nodoc
class __$ProjectTrainerItemGrantCopyWithImpl<$Res>
    implements _$ProjectTrainerItemGrantCopyWith<$Res> {
  __$ProjectTrainerItemGrantCopyWithImpl(this._self, this._then);

  final _ProjectTrainerItemGrant _self;
  final $Res Function(_ProjectTrainerItemGrant) _then;

/// Create a copy of ProjectTrainerItemGrant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? quantity = null,}) {
  return _then(_ProjectTrainerItemGrant(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectTrainerPokemonEntry {

 String get speciesId; int get level;/// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
 List<String> get moves; String? get heldItemId;/// Override d'ability authoré — BETA-TRN-003.
///
/// Absent, le runtime retombe sur l'ability primaire de l'espèce, le
/// comportement historique. Renseigné, il doit exister dans le catalogue
/// d'abilities du projet : la validation de jouabilité le bloque sinon.
 String? get abilityId; String? get formId;/// Genre libre : "male", "female", "any", ou null = non spécifié.
 String? get gender; bool get shiny;
/// Create a copy of ProjectTrainerPokemonEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTrainerPokemonEntryCopyWith<ProjectTrainerPokemonEntry> get copyWith => _$ProjectTrainerPokemonEntryCopyWithImpl<ProjectTrainerPokemonEntry>(this as ProjectTrainerPokemonEntry, _$identity);

  /// Serializes this ProjectTrainerPokemonEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTrainerPokemonEntry&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other.moves, moves)&&(identical(other.heldItemId, heldItemId) || other.heldItemId == heldItemId)&&(identical(other.abilityId, abilityId) || other.abilityId == abilityId)&&(identical(other.formId, formId) || other.formId == formId)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.shiny, shiny) || other.shiny == shiny));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,speciesId,level,const DeepCollectionEquality().hash(moves),heldItemId,abilityId,formId,gender,shiny);

@override
String toString() {
  return 'ProjectTrainerPokemonEntry(speciesId: $speciesId, level: $level, moves: $moves, heldItemId: $heldItemId, abilityId: $abilityId, formId: $formId, gender: $gender, shiny: $shiny)';
}


}

/// @nodoc
abstract mixin class $ProjectTrainerPokemonEntryCopyWith<$Res>  {
  factory $ProjectTrainerPokemonEntryCopyWith(ProjectTrainerPokemonEntry value, $Res Function(ProjectTrainerPokemonEntry) _then) = _$ProjectTrainerPokemonEntryCopyWithImpl;
@useResult
$Res call({
 String speciesId, int level, List<String> moves, String? heldItemId, String? abilityId, String? formId, String? gender, bool shiny
});




}
/// @nodoc
class _$ProjectTrainerPokemonEntryCopyWithImpl<$Res>
    implements $ProjectTrainerPokemonEntryCopyWith<$Res> {
  _$ProjectTrainerPokemonEntryCopyWithImpl(this._self, this._then);

  final ProjectTrainerPokemonEntry _self;
  final $Res Function(ProjectTrainerPokemonEntry) _then;

/// Create a copy of ProjectTrainerPokemonEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? speciesId = null,Object? level = null,Object? moves = null,Object? heldItemId = freezed,Object? abilityId = freezed,Object? formId = freezed,Object? gender = freezed,Object? shiny = null,}) {
  return _then(_self.copyWith(
speciesId: null == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,moves: null == moves ? _self.moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,heldItemId: freezed == heldItemId ? _self.heldItemId : heldItemId // ignore: cast_nullable_to_non_nullable
as String?,abilityId: freezed == abilityId ? _self.abilityId : abilityId // ignore: cast_nullable_to_non_nullable
as String?,formId: freezed == formId ? _self.formId : formId // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,shiny: null == shiny ? _self.shiny : shiny // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTrainerPokemonEntry].
extension ProjectTrainerPokemonEntryPatterns on ProjectTrainerPokemonEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTrainerPokemonEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTrainerPokemonEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTrainerPokemonEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTrainerPokemonEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTrainerPokemonEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTrainerPokemonEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String speciesId,  int level,  List<String> moves,  String? heldItemId,  String? abilityId,  String? formId,  String? gender,  bool shiny)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTrainerPokemonEntry() when $default != null:
return $default(_that.speciesId,_that.level,_that.moves,_that.heldItemId,_that.abilityId,_that.formId,_that.gender,_that.shiny);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String speciesId,  int level,  List<String> moves,  String? heldItemId,  String? abilityId,  String? formId,  String? gender,  bool shiny)  $default,) {final _that = this;
switch (_that) {
case _ProjectTrainerPokemonEntry():
return $default(_that.speciesId,_that.level,_that.moves,_that.heldItemId,_that.abilityId,_that.formId,_that.gender,_that.shiny);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String speciesId,  int level,  List<String> moves,  String? heldItemId,  String? abilityId,  String? formId,  String? gender,  bool shiny)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTrainerPokemonEntry() when $default != null:
return $default(_that.speciesId,_that.level,_that.moves,_that.heldItemId,_that.abilityId,_that.formId,_that.gender,_that.shiny);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectTrainerPokemonEntry implements ProjectTrainerPokemonEntry {
  const _ProjectTrainerPokemonEntry({required this.speciesId, required this.level, final  List<String> moves = const [], this.heldItemId, this.abilityId, this.formId, this.gender, this.shiny = false}): _moves = moves;
  factory _ProjectTrainerPokemonEntry.fromJson(Map<String, dynamic> json) => _$ProjectTrainerPokemonEntryFromJson(json);

@override final  String speciesId;
@override final  int level;
/// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
 final  List<String> _moves;
/// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
@override@JsonKey() List<String> get moves {
  if (_moves is EqualUnmodifiableListView) return _moves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moves);
}

@override final  String? heldItemId;
/// Override d'ability authoré — BETA-TRN-003.
///
/// Absent, le runtime retombe sur l'ability primaire de l'espèce, le
/// comportement historique. Renseigné, il doit exister dans le catalogue
/// d'abilities du projet : la validation de jouabilité le bloque sinon.
@override final  String? abilityId;
@override final  String? formId;
/// Genre libre : "male", "female", "any", ou null = non spécifié.
@override final  String? gender;
@override@JsonKey() final  bool shiny;

/// Create a copy of ProjectTrainerPokemonEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTrainerPokemonEntryCopyWith<_ProjectTrainerPokemonEntry> get copyWith => __$ProjectTrainerPokemonEntryCopyWithImpl<_ProjectTrainerPokemonEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTrainerPokemonEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTrainerPokemonEntry&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other._moves, _moves)&&(identical(other.heldItemId, heldItemId) || other.heldItemId == heldItemId)&&(identical(other.abilityId, abilityId) || other.abilityId == abilityId)&&(identical(other.formId, formId) || other.formId == formId)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.shiny, shiny) || other.shiny == shiny));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,speciesId,level,const DeepCollectionEquality().hash(_moves),heldItemId,abilityId,formId,gender,shiny);

@override
String toString() {
  return 'ProjectTrainerPokemonEntry(speciesId: $speciesId, level: $level, moves: $moves, heldItemId: $heldItemId, abilityId: $abilityId, formId: $formId, gender: $gender, shiny: $shiny)';
}


}

/// @nodoc
abstract mixin class _$ProjectTrainerPokemonEntryCopyWith<$Res> implements $ProjectTrainerPokemonEntryCopyWith<$Res> {
  factory _$ProjectTrainerPokemonEntryCopyWith(_ProjectTrainerPokemonEntry value, $Res Function(_ProjectTrainerPokemonEntry) _then) = __$ProjectTrainerPokemonEntryCopyWithImpl;
@override @useResult
$Res call({
 String speciesId, int level, List<String> moves, String? heldItemId, String? abilityId, String? formId, String? gender, bool shiny
});




}
/// @nodoc
class __$ProjectTrainerPokemonEntryCopyWithImpl<$Res>
    implements _$ProjectTrainerPokemonEntryCopyWith<$Res> {
  __$ProjectTrainerPokemonEntryCopyWithImpl(this._self, this._then);

  final _ProjectTrainerPokemonEntry _self;
  final $Res Function(_ProjectTrainerPokemonEntry) _then;

/// Create a copy of ProjectTrainerPokemonEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? speciesId = null,Object? level = null,Object? moves = null,Object? heldItemId = freezed,Object? abilityId = freezed,Object? formId = freezed,Object? gender = freezed,Object? shiny = null,}) {
  return _then(_ProjectTrainerPokemonEntry(
speciesId: null == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,moves: null == moves ? _self._moves : moves // ignore: cast_nullable_to_non_nullable
as List<String>,heldItemId: freezed == heldItemId ? _self.heldItemId : heldItemId // ignore: cast_nullable_to_non_nullable
as String?,abilityId: freezed == abilityId ? _self.abilityId : abilityId // ignore: cast_nullable_to_non_nullable
as String?,formId: freezed == formId ? _self.formId : formId // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,shiny: null == shiny ? _self.shiny : shiny // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ProjectTrainerEntry {

 String get id; String get name;/// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
 String get trainerClass;/// Difficulté produit battle exprimée sur l'échelle lisible `1..10`.
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
 int? get battleDifficulty;/// Image de fond de combat explicitement authored pour ce trainer.
///
/// Ce champ reste volontairement petit et purement data :
/// - il stocke un chemin relatif au projet, pas un asset handle global ;
/// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
///   métier battle ;
/// - il permet simplement au runtime de prioriser un fond explicite
///   trainer avant le fond contextuel du lot 2 ;
/// - s'il est absent ou inutilisable, le runtime retombe honnêtement sur
///   sa chaîne `explicite > contextuel > fallback`.
 String? get battleBackgroundRelativePath; String? get characterId; String? get portraitElementId; String? get battleThemeId; String? get victoryThemeId;/// Récompenses auteur neutres par défaut pour préserver les projets
/// historiques. Leur application runtime appartient aux lots suivants.
@JsonKey(fromJson: _projectTrainerMoneyRewardFromJson) int get moneyReward; List<ProjectTrainerItemGrant> get rewardItemGrants; List<String> get rewardFlagIds;@JsonKey(includeIfNull: false) String? get rewardBadgeId;@JsonKey(includeIfNull: false) FieldAbility? get rewardFieldAbilityUnlock;@JsonKey(includeIfNull: false) ProjectTrainerTemplateKind? get templateKind;@JsonKey(includeIfNull: false) ProjectTrainerRematchPolicy? get rematchPolicy;@JsonKey(includeIfNull: false) String? get preBattleDialogueId;@JsonKey(includeIfNull: false) String? get victoryDialogueId;@JsonKey(includeIfNull: false) String? get defeatDialogueId; List<ProjectTrainerPokemonEntry> get team; List<String> get tags;
/// Create a copy of ProjectTrainerEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTrainerEntryCopyWith<ProjectTrainerEntry> get copyWith => _$ProjectTrainerEntryCopyWithImpl<ProjectTrainerEntry>(this as ProjectTrainerEntry, _$identity);

  /// Serializes this ProjectTrainerEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTrainerEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.trainerClass, trainerClass) || other.trainerClass == trainerClass)&&(identical(other.battleDifficulty, battleDifficulty) || other.battleDifficulty == battleDifficulty)&&(identical(other.battleBackgroundRelativePath, battleBackgroundRelativePath) || other.battleBackgroundRelativePath == battleBackgroundRelativePath)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.portraitElementId, portraitElementId) || other.portraitElementId == portraitElementId)&&(identical(other.battleThemeId, battleThemeId) || other.battleThemeId == battleThemeId)&&(identical(other.victoryThemeId, victoryThemeId) || other.victoryThemeId == victoryThemeId)&&(identical(other.moneyReward, moneyReward) || other.moneyReward == moneyReward)&&const DeepCollectionEquality().equals(other.rewardItemGrants, rewardItemGrants)&&const DeepCollectionEquality().equals(other.rewardFlagIds, rewardFlagIds)&&(identical(other.rewardBadgeId, rewardBadgeId) || other.rewardBadgeId == rewardBadgeId)&&(identical(other.rewardFieldAbilityUnlock, rewardFieldAbilityUnlock) || other.rewardFieldAbilityUnlock == rewardFieldAbilityUnlock)&&(identical(other.templateKind, templateKind) || other.templateKind == templateKind)&&(identical(other.rematchPolicy, rematchPolicy) || other.rematchPolicy == rematchPolicy)&&(identical(other.preBattleDialogueId, preBattleDialogueId) || other.preBattleDialogueId == preBattleDialogueId)&&(identical(other.victoryDialogueId, victoryDialogueId) || other.victoryDialogueId == victoryDialogueId)&&(identical(other.defeatDialogueId, defeatDialogueId) || other.defeatDialogueId == defeatDialogueId)&&const DeepCollectionEquality().equals(other.team, team)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,trainerClass,battleDifficulty,battleBackgroundRelativePath,characterId,portraitElementId,battleThemeId,victoryThemeId,moneyReward,const DeepCollectionEquality().hash(rewardItemGrants),const DeepCollectionEquality().hash(rewardFlagIds),rewardBadgeId,rewardFieldAbilityUnlock,templateKind,rematchPolicy,preBattleDialogueId,victoryDialogueId,defeatDialogueId,const DeepCollectionEquality().hash(team),const DeepCollectionEquality().hash(tags)]);

@override
String toString() {
  return 'ProjectTrainerEntry(id: $id, name: $name, trainerClass: $trainerClass, battleDifficulty: $battleDifficulty, battleBackgroundRelativePath: $battleBackgroundRelativePath, characterId: $characterId, portraitElementId: $portraitElementId, battleThemeId: $battleThemeId, victoryThemeId: $victoryThemeId, moneyReward: $moneyReward, rewardItemGrants: $rewardItemGrants, rewardFlagIds: $rewardFlagIds, rewardBadgeId: $rewardBadgeId, rewardFieldAbilityUnlock: $rewardFieldAbilityUnlock, templateKind: $templateKind, rematchPolicy: $rematchPolicy, preBattleDialogueId: $preBattleDialogueId, victoryDialogueId: $victoryDialogueId, defeatDialogueId: $defeatDialogueId, team: $team, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $ProjectTrainerEntryCopyWith<$Res>  {
  factory $ProjectTrainerEntryCopyWith(ProjectTrainerEntry value, $Res Function(ProjectTrainerEntry) _then) = _$ProjectTrainerEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String trainerClass, int? battleDifficulty, String? battleBackgroundRelativePath, String? characterId, String? portraitElementId, String? battleThemeId, String? victoryThemeId,@JsonKey(fromJson: _projectTrainerMoneyRewardFromJson) int moneyReward, List<ProjectTrainerItemGrant> rewardItemGrants, List<String> rewardFlagIds,@JsonKey(includeIfNull: false) String? rewardBadgeId,@JsonKey(includeIfNull: false) FieldAbility? rewardFieldAbilityUnlock,@JsonKey(includeIfNull: false) ProjectTrainerTemplateKind? templateKind,@JsonKey(includeIfNull: false) ProjectTrainerRematchPolicy? rematchPolicy,@JsonKey(includeIfNull: false) String? preBattleDialogueId,@JsonKey(includeIfNull: false) String? victoryDialogueId,@JsonKey(includeIfNull: false) String? defeatDialogueId, List<ProjectTrainerPokemonEntry> team, List<String> tags
});




}
/// @nodoc
class _$ProjectTrainerEntryCopyWithImpl<$Res>
    implements $ProjectTrainerEntryCopyWith<$Res> {
  _$ProjectTrainerEntryCopyWithImpl(this._self, this._then);

  final ProjectTrainerEntry _self;
  final $Res Function(ProjectTrainerEntry) _then;

/// Create a copy of ProjectTrainerEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? trainerClass = null,Object? battleDifficulty = freezed,Object? battleBackgroundRelativePath = freezed,Object? characterId = freezed,Object? portraitElementId = freezed,Object? battleThemeId = freezed,Object? victoryThemeId = freezed,Object? moneyReward = null,Object? rewardItemGrants = null,Object? rewardFlagIds = null,Object? rewardBadgeId = freezed,Object? rewardFieldAbilityUnlock = freezed,Object? templateKind = freezed,Object? rematchPolicy = freezed,Object? preBattleDialogueId = freezed,Object? victoryDialogueId = freezed,Object? defeatDialogueId = freezed,Object? team = null,Object? tags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trainerClass: null == trainerClass ? _self.trainerClass : trainerClass // ignore: cast_nullable_to_non_nullable
as String,battleDifficulty: freezed == battleDifficulty ? _self.battleDifficulty : battleDifficulty // ignore: cast_nullable_to_non_nullable
as int?,battleBackgroundRelativePath: freezed == battleBackgroundRelativePath ? _self.battleBackgroundRelativePath : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
as String?,characterId: freezed == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String?,portraitElementId: freezed == portraitElementId ? _self.portraitElementId : portraitElementId // ignore: cast_nullable_to_non_nullable
as String?,battleThemeId: freezed == battleThemeId ? _self.battleThemeId : battleThemeId // ignore: cast_nullable_to_non_nullable
as String?,victoryThemeId: freezed == victoryThemeId ? _self.victoryThemeId : victoryThemeId // ignore: cast_nullable_to_non_nullable
as String?,moneyReward: null == moneyReward ? _self.moneyReward : moneyReward // ignore: cast_nullable_to_non_nullable
as int,rewardItemGrants: null == rewardItemGrants ? _self.rewardItemGrants : rewardItemGrants // ignore: cast_nullable_to_non_nullable
as List<ProjectTrainerItemGrant>,rewardFlagIds: null == rewardFlagIds ? _self.rewardFlagIds : rewardFlagIds // ignore: cast_nullable_to_non_nullable
as List<String>,rewardBadgeId: freezed == rewardBadgeId ? _self.rewardBadgeId : rewardBadgeId // ignore: cast_nullable_to_non_nullable
as String?,rewardFieldAbilityUnlock: freezed == rewardFieldAbilityUnlock ? _self.rewardFieldAbilityUnlock : rewardFieldAbilityUnlock // ignore: cast_nullable_to_non_nullable
as FieldAbility?,templateKind: freezed == templateKind ? _self.templateKind : templateKind // ignore: cast_nullable_to_non_nullable
as ProjectTrainerTemplateKind?,rematchPolicy: freezed == rematchPolicy ? _self.rematchPolicy : rematchPolicy // ignore: cast_nullable_to_non_nullable
as ProjectTrainerRematchPolicy?,preBattleDialogueId: freezed == preBattleDialogueId ? _self.preBattleDialogueId : preBattleDialogueId // ignore: cast_nullable_to_non_nullable
as String?,victoryDialogueId: freezed == victoryDialogueId ? _self.victoryDialogueId : victoryDialogueId // ignore: cast_nullable_to_non_nullable
as String?,defeatDialogueId: freezed == defeatDialogueId ? _self.defeatDialogueId : defeatDialogueId // ignore: cast_nullable_to_non_nullable
as String?,team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as List<ProjectTrainerPokemonEntry>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTrainerEntry].
extension ProjectTrainerEntryPatterns on ProjectTrainerEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTrainerEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTrainerEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTrainerEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTrainerEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTrainerEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTrainerEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String trainerClass,  int? battleDifficulty,  String? battleBackgroundRelativePath,  String? characterId,  String? portraitElementId,  String? battleThemeId,  String? victoryThemeId, @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson)  int moneyReward,  List<ProjectTrainerItemGrant> rewardItemGrants,  List<String> rewardFlagIds, @JsonKey(includeIfNull: false)  String? rewardBadgeId, @JsonKey(includeIfNull: false)  FieldAbility? rewardFieldAbilityUnlock, @JsonKey(includeIfNull: false)  ProjectTrainerTemplateKind? templateKind, @JsonKey(includeIfNull: false)  ProjectTrainerRematchPolicy? rematchPolicy, @JsonKey(includeIfNull: false)  String? preBattleDialogueId, @JsonKey(includeIfNull: false)  String? victoryDialogueId, @JsonKey(includeIfNull: false)  String? defeatDialogueId,  List<ProjectTrainerPokemonEntry> team,  List<String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTrainerEntry() when $default != null:
return $default(_that.id,_that.name,_that.trainerClass,_that.battleDifficulty,_that.battleBackgroundRelativePath,_that.characterId,_that.portraitElementId,_that.battleThemeId,_that.victoryThemeId,_that.moneyReward,_that.rewardItemGrants,_that.rewardFlagIds,_that.rewardBadgeId,_that.rewardFieldAbilityUnlock,_that.templateKind,_that.rematchPolicy,_that.preBattleDialogueId,_that.victoryDialogueId,_that.defeatDialogueId,_that.team,_that.tags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String trainerClass,  int? battleDifficulty,  String? battleBackgroundRelativePath,  String? characterId,  String? portraitElementId,  String? battleThemeId,  String? victoryThemeId, @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson)  int moneyReward,  List<ProjectTrainerItemGrant> rewardItemGrants,  List<String> rewardFlagIds, @JsonKey(includeIfNull: false)  String? rewardBadgeId, @JsonKey(includeIfNull: false)  FieldAbility? rewardFieldAbilityUnlock, @JsonKey(includeIfNull: false)  ProjectTrainerTemplateKind? templateKind, @JsonKey(includeIfNull: false)  ProjectTrainerRematchPolicy? rematchPolicy, @JsonKey(includeIfNull: false)  String? preBattleDialogueId, @JsonKey(includeIfNull: false)  String? victoryDialogueId, @JsonKey(includeIfNull: false)  String? defeatDialogueId,  List<ProjectTrainerPokemonEntry> team,  List<String> tags)  $default,) {final _that = this;
switch (_that) {
case _ProjectTrainerEntry():
return $default(_that.id,_that.name,_that.trainerClass,_that.battleDifficulty,_that.battleBackgroundRelativePath,_that.characterId,_that.portraitElementId,_that.battleThemeId,_that.victoryThemeId,_that.moneyReward,_that.rewardItemGrants,_that.rewardFlagIds,_that.rewardBadgeId,_that.rewardFieldAbilityUnlock,_that.templateKind,_that.rematchPolicy,_that.preBattleDialogueId,_that.victoryDialogueId,_that.defeatDialogueId,_that.team,_that.tags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String trainerClass,  int? battleDifficulty,  String? battleBackgroundRelativePath,  String? characterId,  String? portraitElementId,  String? battleThemeId,  String? victoryThemeId, @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson)  int moneyReward,  List<ProjectTrainerItemGrant> rewardItemGrants,  List<String> rewardFlagIds, @JsonKey(includeIfNull: false)  String? rewardBadgeId, @JsonKey(includeIfNull: false)  FieldAbility? rewardFieldAbilityUnlock, @JsonKey(includeIfNull: false)  ProjectTrainerTemplateKind? templateKind, @JsonKey(includeIfNull: false)  ProjectTrainerRematchPolicy? rematchPolicy, @JsonKey(includeIfNull: false)  String? preBattleDialogueId, @JsonKey(includeIfNull: false)  String? victoryDialogueId, @JsonKey(includeIfNull: false)  String? defeatDialogueId,  List<ProjectTrainerPokemonEntry> team,  List<String> tags)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTrainerEntry() when $default != null:
return $default(_that.id,_that.name,_that.trainerClass,_that.battleDifficulty,_that.battleBackgroundRelativePath,_that.characterId,_that.portraitElementId,_that.battleThemeId,_that.victoryThemeId,_that.moneyReward,_that.rewardItemGrants,_that.rewardFlagIds,_that.rewardBadgeId,_that.rewardFieldAbilityUnlock,_that.templateKind,_that.rematchPolicy,_that.preBattleDialogueId,_that.victoryDialogueId,_that.defeatDialogueId,_that.team,_that.tags);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectTrainerEntry implements ProjectTrainerEntry {
  const _ProjectTrainerEntry({required this.id, required this.name, required this.trainerClass, this.battleDifficulty, this.battleBackgroundRelativePath, this.characterId, this.portraitElementId, this.battleThemeId, this.victoryThemeId, @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson) this.moneyReward = 0, final  List<ProjectTrainerItemGrant> rewardItemGrants = const [], final  List<String> rewardFlagIds = const [], @JsonKey(includeIfNull: false) this.rewardBadgeId, @JsonKey(includeIfNull: false) this.rewardFieldAbilityUnlock, @JsonKey(includeIfNull: false) this.templateKind, @JsonKey(includeIfNull: false) this.rematchPolicy, @JsonKey(includeIfNull: false) this.preBattleDialogueId, @JsonKey(includeIfNull: false) this.victoryDialogueId, @JsonKey(includeIfNull: false) this.defeatDialogueId, final  List<ProjectTrainerPokemonEntry> team = const [], final  List<String> tags = const []}): _rewardItemGrants = rewardItemGrants,_rewardFlagIds = rewardFlagIds,_team = team,_tags = tags;
  factory _ProjectTrainerEntry.fromJson(Map<String, dynamic> json) => _$ProjectTrainerEntryFromJson(json);

@override final  String id;
@override final  String name;
/// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
@override final  String trainerClass;
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
@override final  int? battleDifficulty;
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
@override final  String? battleBackgroundRelativePath;
@override final  String? characterId;
@override final  String? portraitElementId;
@override final  String? battleThemeId;
@override final  String? victoryThemeId;
/// Récompenses auteur neutres par défaut pour préserver les projets
/// historiques. Leur application runtime appartient aux lots suivants.
@override@JsonKey(fromJson: _projectTrainerMoneyRewardFromJson) final  int moneyReward;
 final  List<ProjectTrainerItemGrant> _rewardItemGrants;
@override@JsonKey() List<ProjectTrainerItemGrant> get rewardItemGrants {
  if (_rewardItemGrants is EqualUnmodifiableListView) return _rewardItemGrants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rewardItemGrants);
}

 final  List<String> _rewardFlagIds;
@override@JsonKey() List<String> get rewardFlagIds {
  if (_rewardFlagIds is EqualUnmodifiableListView) return _rewardFlagIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rewardFlagIds);
}

@override@JsonKey(includeIfNull: false) final  String? rewardBadgeId;
@override@JsonKey(includeIfNull: false) final  FieldAbility? rewardFieldAbilityUnlock;
@override@JsonKey(includeIfNull: false) final  ProjectTrainerTemplateKind? templateKind;
@override@JsonKey(includeIfNull: false) final  ProjectTrainerRematchPolicy? rematchPolicy;
@override@JsonKey(includeIfNull: false) final  String? preBattleDialogueId;
@override@JsonKey(includeIfNull: false) final  String? victoryDialogueId;
@override@JsonKey(includeIfNull: false) final  String? defeatDialogueId;
 final  List<ProjectTrainerPokemonEntry> _team;
@override@JsonKey() List<ProjectTrainerPokemonEntry> get team {
  if (_team is EqualUnmodifiableListView) return _team;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_team);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of ProjectTrainerEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTrainerEntryCopyWith<_ProjectTrainerEntry> get copyWith => __$ProjectTrainerEntryCopyWithImpl<_ProjectTrainerEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTrainerEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTrainerEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.trainerClass, trainerClass) || other.trainerClass == trainerClass)&&(identical(other.battleDifficulty, battleDifficulty) || other.battleDifficulty == battleDifficulty)&&(identical(other.battleBackgroundRelativePath, battleBackgroundRelativePath) || other.battleBackgroundRelativePath == battleBackgroundRelativePath)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.portraitElementId, portraitElementId) || other.portraitElementId == portraitElementId)&&(identical(other.battleThemeId, battleThemeId) || other.battleThemeId == battleThemeId)&&(identical(other.victoryThemeId, victoryThemeId) || other.victoryThemeId == victoryThemeId)&&(identical(other.moneyReward, moneyReward) || other.moneyReward == moneyReward)&&const DeepCollectionEquality().equals(other._rewardItemGrants, _rewardItemGrants)&&const DeepCollectionEquality().equals(other._rewardFlagIds, _rewardFlagIds)&&(identical(other.rewardBadgeId, rewardBadgeId) || other.rewardBadgeId == rewardBadgeId)&&(identical(other.rewardFieldAbilityUnlock, rewardFieldAbilityUnlock) || other.rewardFieldAbilityUnlock == rewardFieldAbilityUnlock)&&(identical(other.templateKind, templateKind) || other.templateKind == templateKind)&&(identical(other.rematchPolicy, rematchPolicy) || other.rematchPolicy == rematchPolicy)&&(identical(other.preBattleDialogueId, preBattleDialogueId) || other.preBattleDialogueId == preBattleDialogueId)&&(identical(other.victoryDialogueId, victoryDialogueId) || other.victoryDialogueId == victoryDialogueId)&&(identical(other.defeatDialogueId, defeatDialogueId) || other.defeatDialogueId == defeatDialogueId)&&const DeepCollectionEquality().equals(other._team, _team)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,trainerClass,battleDifficulty,battleBackgroundRelativePath,characterId,portraitElementId,battleThemeId,victoryThemeId,moneyReward,const DeepCollectionEquality().hash(_rewardItemGrants),const DeepCollectionEquality().hash(_rewardFlagIds),rewardBadgeId,rewardFieldAbilityUnlock,templateKind,rematchPolicy,preBattleDialogueId,victoryDialogueId,defeatDialogueId,const DeepCollectionEquality().hash(_team),const DeepCollectionEquality().hash(_tags)]);

@override
String toString() {
  return 'ProjectTrainerEntry(id: $id, name: $name, trainerClass: $trainerClass, battleDifficulty: $battleDifficulty, battleBackgroundRelativePath: $battleBackgroundRelativePath, characterId: $characterId, portraitElementId: $portraitElementId, battleThemeId: $battleThemeId, victoryThemeId: $victoryThemeId, moneyReward: $moneyReward, rewardItemGrants: $rewardItemGrants, rewardFlagIds: $rewardFlagIds, rewardBadgeId: $rewardBadgeId, rewardFieldAbilityUnlock: $rewardFieldAbilityUnlock, templateKind: $templateKind, rematchPolicy: $rematchPolicy, preBattleDialogueId: $preBattleDialogueId, victoryDialogueId: $victoryDialogueId, defeatDialogueId: $defeatDialogueId, team: $team, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$ProjectTrainerEntryCopyWith<$Res> implements $ProjectTrainerEntryCopyWith<$Res> {
  factory _$ProjectTrainerEntryCopyWith(_ProjectTrainerEntry value, $Res Function(_ProjectTrainerEntry) _then) = __$ProjectTrainerEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String trainerClass, int? battleDifficulty, String? battleBackgroundRelativePath, String? characterId, String? portraitElementId, String? battleThemeId, String? victoryThemeId,@JsonKey(fromJson: _projectTrainerMoneyRewardFromJson) int moneyReward, List<ProjectTrainerItemGrant> rewardItemGrants, List<String> rewardFlagIds,@JsonKey(includeIfNull: false) String? rewardBadgeId,@JsonKey(includeIfNull: false) FieldAbility? rewardFieldAbilityUnlock,@JsonKey(includeIfNull: false) ProjectTrainerTemplateKind? templateKind,@JsonKey(includeIfNull: false) ProjectTrainerRematchPolicy? rematchPolicy,@JsonKey(includeIfNull: false) String? preBattleDialogueId,@JsonKey(includeIfNull: false) String? victoryDialogueId,@JsonKey(includeIfNull: false) String? defeatDialogueId, List<ProjectTrainerPokemonEntry> team, List<String> tags
});




}
/// @nodoc
class __$ProjectTrainerEntryCopyWithImpl<$Res>
    implements _$ProjectTrainerEntryCopyWith<$Res> {
  __$ProjectTrainerEntryCopyWithImpl(this._self, this._then);

  final _ProjectTrainerEntry _self;
  final $Res Function(_ProjectTrainerEntry) _then;

/// Create a copy of ProjectTrainerEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? trainerClass = null,Object? battleDifficulty = freezed,Object? battleBackgroundRelativePath = freezed,Object? characterId = freezed,Object? portraitElementId = freezed,Object? battleThemeId = freezed,Object? victoryThemeId = freezed,Object? moneyReward = null,Object? rewardItemGrants = null,Object? rewardFlagIds = null,Object? rewardBadgeId = freezed,Object? rewardFieldAbilityUnlock = freezed,Object? templateKind = freezed,Object? rematchPolicy = freezed,Object? preBattleDialogueId = freezed,Object? victoryDialogueId = freezed,Object? defeatDialogueId = freezed,Object? team = null,Object? tags = null,}) {
  return _then(_ProjectTrainerEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trainerClass: null == trainerClass ? _self.trainerClass : trainerClass // ignore: cast_nullable_to_non_nullable
as String,battleDifficulty: freezed == battleDifficulty ? _self.battleDifficulty : battleDifficulty // ignore: cast_nullable_to_non_nullable
as int?,battleBackgroundRelativePath: freezed == battleBackgroundRelativePath ? _self.battleBackgroundRelativePath : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
as String?,characterId: freezed == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String?,portraitElementId: freezed == portraitElementId ? _self.portraitElementId : portraitElementId // ignore: cast_nullable_to_non_nullable
as String?,battleThemeId: freezed == battleThemeId ? _self.battleThemeId : battleThemeId // ignore: cast_nullable_to_non_nullable
as String?,victoryThemeId: freezed == victoryThemeId ? _self.victoryThemeId : victoryThemeId // ignore: cast_nullable_to_non_nullable
as String?,moneyReward: null == moneyReward ? _self.moneyReward : moneyReward // ignore: cast_nullable_to_non_nullable
as int,rewardItemGrants: null == rewardItemGrants ? _self._rewardItemGrants : rewardItemGrants // ignore: cast_nullable_to_non_nullable
as List<ProjectTrainerItemGrant>,rewardFlagIds: null == rewardFlagIds ? _self._rewardFlagIds : rewardFlagIds // ignore: cast_nullable_to_non_nullable
as List<String>,rewardBadgeId: freezed == rewardBadgeId ? _self.rewardBadgeId : rewardBadgeId // ignore: cast_nullable_to_non_nullable
as String?,rewardFieldAbilityUnlock: freezed == rewardFieldAbilityUnlock ? _self.rewardFieldAbilityUnlock : rewardFieldAbilityUnlock // ignore: cast_nullable_to_non_nullable
as FieldAbility?,templateKind: freezed == templateKind ? _self.templateKind : templateKind // ignore: cast_nullable_to_non_nullable
as ProjectTrainerTemplateKind?,rematchPolicy: freezed == rematchPolicy ? _self.rematchPolicy : rematchPolicy // ignore: cast_nullable_to_non_nullable
as ProjectTrainerRematchPolicy?,preBattleDialogueId: freezed == preBattleDialogueId ? _self.preBattleDialogueId : preBattleDialogueId // ignore: cast_nullable_to_non_nullable
as String?,victoryDialogueId: freezed == victoryDialogueId ? _self.victoryDialogueId : victoryDialogueId // ignore: cast_nullable_to_non_nullable
as String?,defeatDialogueId: freezed == defeatDialogueId ? _self.defeatDialogueId : defeatDialogueId // ignore: cast_nullable_to_non_nullable
as String?,team: null == team ? _self._team : team // ignore: cast_nullable_to_non_nullable
as List<ProjectTrainerPokemonEntry>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
