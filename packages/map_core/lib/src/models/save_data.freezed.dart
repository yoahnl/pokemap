// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PokemonStatSpread {

 int get hp; int get attack; int get defense; int get specialAttack; int get specialDefense; int get speed;
/// Create a copy of PokemonStatSpread
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonStatSpreadCopyWith<PokemonStatSpread> get copyWith => _$PokemonStatSpreadCopyWithImpl<PokemonStatSpread>(this as PokemonStatSpread, _$identity);

  /// Serializes this PokemonStatSpread to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonStatSpread&&(identical(other.hp, hp) || other.hp == hp)&&(identical(other.attack, attack) || other.attack == attack)&&(identical(other.defense, defense) || other.defense == defense)&&(identical(other.specialAttack, specialAttack) || other.specialAttack == specialAttack)&&(identical(other.specialDefense, specialDefense) || other.specialDefense == specialDefense)&&(identical(other.speed, speed) || other.speed == speed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hp,attack,defense,specialAttack,specialDefense,speed);

@override
String toString() {
  return 'PokemonStatSpread(hp: $hp, attack: $attack, defense: $defense, specialAttack: $specialAttack, specialDefense: $specialDefense, speed: $speed)';
}


}

/// @nodoc
abstract mixin class $PokemonStatSpreadCopyWith<$Res>  {
  factory $PokemonStatSpreadCopyWith(PokemonStatSpread value, $Res Function(PokemonStatSpread) _then) = _$PokemonStatSpreadCopyWithImpl;
@useResult
$Res call({
 int hp, int attack, int defense, int specialAttack, int specialDefense, int speed
});




}
/// @nodoc
class _$PokemonStatSpreadCopyWithImpl<$Res>
    implements $PokemonStatSpreadCopyWith<$Res> {
  _$PokemonStatSpreadCopyWithImpl(this._self, this._then);

  final PokemonStatSpread _self;
  final $Res Function(PokemonStatSpread) _then;

/// Create a copy of PokemonStatSpread
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hp = null,Object? attack = null,Object? defense = null,Object? specialAttack = null,Object? specialDefense = null,Object? speed = null,}) {
  return _then(_self.copyWith(
hp: null == hp ? _self.hp : hp // ignore: cast_nullable_to_non_nullable
as int,attack: null == attack ? _self.attack : attack // ignore: cast_nullable_to_non_nullable
as int,defense: null == defense ? _self.defense : defense // ignore: cast_nullable_to_non_nullable
as int,specialAttack: null == specialAttack ? _self.specialAttack : specialAttack // ignore: cast_nullable_to_non_nullable
as int,specialDefense: null == specialDefense ? _self.specialDefense : specialDefense // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PokemonStatSpread].
extension PokemonStatSpreadPatterns on PokemonStatSpread {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PokemonStatSpread value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PokemonStatSpread() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PokemonStatSpread value)  $default,){
final _that = this;
switch (_that) {
case _PokemonStatSpread():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PokemonStatSpread value)?  $default,){
final _that = this;
switch (_that) {
case _PokemonStatSpread() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int hp,  int attack,  int defense,  int specialAttack,  int specialDefense,  int speed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PokemonStatSpread() when $default != null:
return $default(_that.hp,_that.attack,_that.defense,_that.specialAttack,_that.specialDefense,_that.speed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int hp,  int attack,  int defense,  int specialAttack,  int specialDefense,  int speed)  $default,) {final _that = this;
switch (_that) {
case _PokemonStatSpread():
return $default(_that.hp,_that.attack,_that.defense,_that.specialAttack,_that.specialDefense,_that.speed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int hp,  int attack,  int defense,  int specialAttack,  int specialDefense,  int speed)?  $default,) {final _that = this;
switch (_that) {
case _PokemonStatSpread() when $default != null:
return $default(_that.hp,_that.attack,_that.defense,_that.specialAttack,_that.specialDefense,_that.speed);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PokemonStatSpread extends PokemonStatSpread {
  const _PokemonStatSpread({this.hp = 0, this.attack = 0, this.defense = 0, this.specialAttack = 0, this.specialDefense = 0, this.speed = 0}): super._();
  factory _PokemonStatSpread.fromJson(Map<String, dynamic> json) => _$PokemonStatSpreadFromJson(json);

@override@JsonKey() final  int hp;
@override@JsonKey() final  int attack;
@override@JsonKey() final  int defense;
@override@JsonKey() final  int specialAttack;
@override@JsonKey() final  int specialDefense;
@override@JsonKey() final  int speed;

/// Create a copy of PokemonStatSpread
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PokemonStatSpreadCopyWith<_PokemonStatSpread> get copyWith => __$PokemonStatSpreadCopyWithImpl<_PokemonStatSpread>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonStatSpreadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PokemonStatSpread&&(identical(other.hp, hp) || other.hp == hp)&&(identical(other.attack, attack) || other.attack == attack)&&(identical(other.defense, defense) || other.defense == defense)&&(identical(other.specialAttack, specialAttack) || other.specialAttack == specialAttack)&&(identical(other.specialDefense, specialDefense) || other.specialDefense == specialDefense)&&(identical(other.speed, speed) || other.speed == speed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hp,attack,defense,specialAttack,specialDefense,speed);

@override
String toString() {
  return 'PokemonStatSpread(hp: $hp, attack: $attack, defense: $defense, specialAttack: $specialAttack, specialDefense: $specialDefense, speed: $speed)';
}


}

/// @nodoc
abstract mixin class _$PokemonStatSpreadCopyWith<$Res> implements $PokemonStatSpreadCopyWith<$Res> {
  factory _$PokemonStatSpreadCopyWith(_PokemonStatSpread value, $Res Function(_PokemonStatSpread) _then) = __$PokemonStatSpreadCopyWithImpl;
@override @useResult
$Res call({
 int hp, int attack, int defense, int specialAttack, int specialDefense, int speed
});




}
/// @nodoc
class __$PokemonStatSpreadCopyWithImpl<$Res>
    implements _$PokemonStatSpreadCopyWith<$Res> {
  __$PokemonStatSpreadCopyWithImpl(this._self, this._then);

  final _PokemonStatSpread _self;
  final $Res Function(_PokemonStatSpread) _then;

/// Create a copy of PokemonStatSpread
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hp = null,Object? attack = null,Object? defense = null,Object? specialAttack = null,Object? specialDefense = null,Object? speed = null,}) {
  return _then(_PokemonStatSpread(
hp: null == hp ? _self.hp : hp // ignore: cast_nullable_to_non_nullable
as int,attack: null == attack ? _self.attack : attack // ignore: cast_nullable_to_non_nullable
as int,defense: null == defense ? _self.defense : defense // ignore: cast_nullable_to_non_nullable
as int,specialAttack: null == specialAttack ? _self.specialAttack : specialAttack // ignore: cast_nullable_to_non_nullable
as int,specialDefense: null == specialDefense ? _self.specialDefense : specialDefense // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlayerPokemonProvenance {

 PlayerPokemonOriginKind get kind; String get mapId; String get sourceId; String get ballItemId; int? get metLevel;
/// Create a copy of PlayerPokemonProvenance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerPokemonProvenanceCopyWith<PlayerPokemonProvenance> get copyWith => _$PlayerPokemonProvenanceCopyWithImpl<PlayerPokemonProvenance>(this as PlayerPokemonProvenance, _$identity);

  /// Serializes this PlayerPokemonProvenance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerPokemonProvenance&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.mapId, mapId) || other.mapId == mapId)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.ballItemId, ballItemId) || other.ballItemId == ballItemId)&&(identical(other.metLevel, metLevel) || other.metLevel == metLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,mapId,sourceId,ballItemId,metLevel);

@override
String toString() {
  return 'PlayerPokemonProvenance(kind: $kind, mapId: $mapId, sourceId: $sourceId, ballItemId: $ballItemId, metLevel: $metLevel)';
}


}

/// @nodoc
abstract mixin class $PlayerPokemonProvenanceCopyWith<$Res>  {
  factory $PlayerPokemonProvenanceCopyWith(PlayerPokemonProvenance value, $Res Function(PlayerPokemonProvenance) _then) = _$PlayerPokemonProvenanceCopyWithImpl;
@useResult
$Res call({
 PlayerPokemonOriginKind kind, String mapId, String sourceId, String ballItemId, int? metLevel
});




}
/// @nodoc
class _$PlayerPokemonProvenanceCopyWithImpl<$Res>
    implements $PlayerPokemonProvenanceCopyWith<$Res> {
  _$PlayerPokemonProvenanceCopyWithImpl(this._self, this._then);

  final PlayerPokemonProvenance _self;
  final $Res Function(PlayerPokemonProvenance) _then;

/// Create a copy of PlayerPokemonProvenance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? mapId = null,Object? sourceId = null,Object? ballItemId = null,Object? metLevel = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PlayerPokemonOriginKind,mapId: null == mapId ? _self.mapId : mapId // ignore: cast_nullable_to_non_nullable
as String,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,ballItemId: null == ballItemId ? _self.ballItemId : ballItemId // ignore: cast_nullable_to_non_nullable
as String,metLevel: freezed == metLevel ? _self.metLevel : metLevel // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerPokemonProvenance].
extension PlayerPokemonProvenancePatterns on PlayerPokemonProvenance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerPokemonProvenance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerPokemonProvenance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerPokemonProvenance value)  $default,){
final _that = this;
switch (_that) {
case _PlayerPokemonProvenance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerPokemonProvenance value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerPokemonProvenance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerPokemonOriginKind kind,  String mapId,  String sourceId,  String ballItemId,  int? metLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerPokemonProvenance() when $default != null:
return $default(_that.kind,_that.mapId,_that.sourceId,_that.ballItemId,_that.metLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerPokemonOriginKind kind,  String mapId,  String sourceId,  String ballItemId,  int? metLevel)  $default,) {final _that = this;
switch (_that) {
case _PlayerPokemonProvenance():
return $default(_that.kind,_that.mapId,_that.sourceId,_that.ballItemId,_that.metLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerPokemonOriginKind kind,  String mapId,  String sourceId,  String ballItemId,  int? metLevel)?  $default,) {final _that = this;
switch (_that) {
case _PlayerPokemonProvenance() when $default != null:
return $default(_that.kind,_that.mapId,_that.sourceId,_that.ballItemId,_that.metLevel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerPokemonProvenance extends PlayerPokemonProvenance {
  const _PlayerPokemonProvenance({this.kind = PlayerPokemonOriginKind.unknown, this.mapId = '', this.sourceId = '', this.ballItemId = '', this.metLevel}): super._();
  factory _PlayerPokemonProvenance.fromJson(Map<String, dynamic> json) => _$PlayerPokemonProvenanceFromJson(json);

@override@JsonKey() final  PlayerPokemonOriginKind kind;
@override@JsonKey() final  String mapId;
@override@JsonKey() final  String sourceId;
@override@JsonKey() final  String ballItemId;
@override final  int? metLevel;

/// Create a copy of PlayerPokemonProvenance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerPokemonProvenanceCopyWith<_PlayerPokemonProvenance> get copyWith => __$PlayerPokemonProvenanceCopyWithImpl<_PlayerPokemonProvenance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerPokemonProvenanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerPokemonProvenance&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.mapId, mapId) || other.mapId == mapId)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.ballItemId, ballItemId) || other.ballItemId == ballItemId)&&(identical(other.metLevel, metLevel) || other.metLevel == metLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,mapId,sourceId,ballItemId,metLevel);

@override
String toString() {
  return 'PlayerPokemonProvenance(kind: $kind, mapId: $mapId, sourceId: $sourceId, ballItemId: $ballItemId, metLevel: $metLevel)';
}


}

/// @nodoc
abstract mixin class _$PlayerPokemonProvenanceCopyWith<$Res> implements $PlayerPokemonProvenanceCopyWith<$Res> {
  factory _$PlayerPokemonProvenanceCopyWith(_PlayerPokemonProvenance value, $Res Function(_PlayerPokemonProvenance) _then) = __$PlayerPokemonProvenanceCopyWithImpl;
@override @useResult
$Res call({
 PlayerPokemonOriginKind kind, String mapId, String sourceId, String ballItemId, int? metLevel
});




}
/// @nodoc
class __$PlayerPokemonProvenanceCopyWithImpl<$Res>
    implements _$PlayerPokemonProvenanceCopyWith<$Res> {
  __$PlayerPokemonProvenanceCopyWithImpl(this._self, this._then);

  final _PlayerPokemonProvenance _self;
  final $Res Function(_PlayerPokemonProvenance) _then;

/// Create a copy of PlayerPokemonProvenance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? mapId = null,Object? sourceId = null,Object? ballItemId = null,Object? metLevel = freezed,}) {
  return _then(_PlayerPokemonProvenance(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PlayerPokemonOriginKind,mapId: null == mapId ? _self.mapId : mapId // ignore: cast_nullable_to_non_nullable
as String,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,ballItemId: null == ballItemId ? _self.ballItemId : ballItemId // ignore: cast_nullable_to_non_nullable
as String,metLevel: freezed == metLevel ? _self.metLevel : metLevel // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$PlayerPokemon {

 String get individualId; String get speciesId; String get formId; String get natureId; String get abilityId; String? get gender; int get level; PokemonStatSpread get ivs; PokemonStatSpread get evs; List<String> get knownMoveIds;/// Total cumulative experience.
///
/// `null` is deliberately preserved for saves created before FG-021. It
/// must not be interpreted as zero because that would silently regress a
/// legacy levelled Pokemon to the level-one experience floor.
 int? get experience;/// Current PP indexed by canonical move id.
///
/// `null` is the legacy migration sentinel. An empty non-null map is a
/// fully hydrated Pokemon with no known moves; max PP stays catalogue
/// derived and therefore does not belong in this persistence contract.
 Map<String, int>? get currentPpByMoveId; int get currentHp; String get statusId; bool get isShiny; String get heldItemId; String get nickname; int get friendship; PlayerPokemonProvenance? get provenance;
/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerPokemonCopyWith<PlayerPokemon> get copyWith => _$PlayerPokemonCopyWithImpl<PlayerPokemon>(this as PlayerPokemon, _$identity);

  /// Serializes this PlayerPokemon to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerPokemon&&(identical(other.individualId, individualId) || other.individualId == individualId)&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.formId, formId) || other.formId == formId)&&(identical(other.natureId, natureId) || other.natureId == natureId)&&(identical(other.abilityId, abilityId) || other.abilityId == abilityId)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.level, level) || other.level == level)&&(identical(other.ivs, ivs) || other.ivs == ivs)&&(identical(other.evs, evs) || other.evs == evs)&&const DeepCollectionEquality().equals(other.knownMoveIds, knownMoveIds)&&(identical(other.experience, experience) || other.experience == experience)&&const DeepCollectionEquality().equals(other.currentPpByMoveId, currentPpByMoveId)&&(identical(other.currentHp, currentHp) || other.currentHp == currentHp)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.isShiny, isShiny) || other.isShiny == isShiny)&&(identical(other.heldItemId, heldItemId) || other.heldItemId == heldItemId)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.friendship, friendship) || other.friendship == friendship)&&(identical(other.provenance, provenance) || other.provenance == provenance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,individualId,speciesId,formId,natureId,abilityId,gender,level,ivs,evs,const DeepCollectionEquality().hash(knownMoveIds),experience,const DeepCollectionEquality().hash(currentPpByMoveId),currentHp,statusId,isShiny,heldItemId,nickname,friendship,provenance]);

@override
String toString() {
  return 'PlayerPokemon(individualId: $individualId, speciesId: $speciesId, formId: $formId, natureId: $natureId, abilityId: $abilityId, gender: $gender, level: $level, ivs: $ivs, evs: $evs, knownMoveIds: $knownMoveIds, experience: $experience, currentPpByMoveId: $currentPpByMoveId, currentHp: $currentHp, statusId: $statusId, isShiny: $isShiny, heldItemId: $heldItemId, nickname: $nickname, friendship: $friendship, provenance: $provenance)';
}


}

/// @nodoc
abstract mixin class $PlayerPokemonCopyWith<$Res>  {
  factory $PlayerPokemonCopyWith(PlayerPokemon value, $Res Function(PlayerPokemon) _then) = _$PlayerPokemonCopyWithImpl;
@useResult
$Res call({
 String individualId, String speciesId, String formId, String natureId, String abilityId, String? gender, int level, PokemonStatSpread ivs, PokemonStatSpread evs, List<String> knownMoveIds, int? experience, Map<String, int>? currentPpByMoveId, int currentHp, String statusId, bool isShiny, String heldItemId, String nickname, int friendship, PlayerPokemonProvenance? provenance
});


$PokemonStatSpreadCopyWith<$Res> get ivs;$PokemonStatSpreadCopyWith<$Res> get evs;$PlayerPokemonProvenanceCopyWith<$Res>? get provenance;

}
/// @nodoc
class _$PlayerPokemonCopyWithImpl<$Res>
    implements $PlayerPokemonCopyWith<$Res> {
  _$PlayerPokemonCopyWithImpl(this._self, this._then);

  final PlayerPokemon _self;
  final $Res Function(PlayerPokemon) _then;

/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? individualId = null,Object? speciesId = null,Object? formId = null,Object? natureId = null,Object? abilityId = null,Object? gender = freezed,Object? level = null,Object? ivs = null,Object? evs = null,Object? knownMoveIds = null,Object? experience = freezed,Object? currentPpByMoveId = freezed,Object? currentHp = null,Object? statusId = null,Object? isShiny = null,Object? heldItemId = null,Object? nickname = null,Object? friendship = null,Object? provenance = freezed,}) {
  return _then(_self.copyWith(
individualId: null == individualId ? _self.individualId : individualId // ignore: cast_nullable_to_non_nullable
as String,speciesId: null == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String,formId: null == formId ? _self.formId : formId // ignore: cast_nullable_to_non_nullable
as String,natureId: null == natureId ? _self.natureId : natureId // ignore: cast_nullable_to_non_nullable
as String,abilityId: null == abilityId ? _self.abilityId : abilityId // ignore: cast_nullable_to_non_nullable
as String,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,ivs: null == ivs ? _self.ivs : ivs // ignore: cast_nullable_to_non_nullable
as PokemonStatSpread,evs: null == evs ? _self.evs : evs // ignore: cast_nullable_to_non_nullable
as PokemonStatSpread,knownMoveIds: null == knownMoveIds ? _self.knownMoveIds : knownMoveIds // ignore: cast_nullable_to_non_nullable
as List<String>,experience: freezed == experience ? _self.experience : experience // ignore: cast_nullable_to_non_nullable
as int?,currentPpByMoveId: freezed == currentPpByMoveId ? _self.currentPpByMoveId : currentPpByMoveId // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,currentHp: null == currentHp ? _self.currentHp : currentHp // ignore: cast_nullable_to_non_nullable
as int,statusId: null == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as String,isShiny: null == isShiny ? _self.isShiny : isShiny // ignore: cast_nullable_to_non_nullable
as bool,heldItemId: null == heldItemId ? _self.heldItemId : heldItemId // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,friendship: null == friendship ? _self.friendship : friendship // ignore: cast_nullable_to_non_nullable
as int,provenance: freezed == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as PlayerPokemonProvenance?,
  ));
}
/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonStatSpreadCopyWith<$Res> get ivs {

  return $PokemonStatSpreadCopyWith<$Res>(_self.ivs, (value) {
    return _then(_self.copyWith(ivs: value));
  });
}/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonStatSpreadCopyWith<$Res> get evs {

  return $PokemonStatSpreadCopyWith<$Res>(_self.evs, (value) {
    return _then(_self.copyWith(evs: value));
  });
}/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerPokemonProvenanceCopyWith<$Res>? get provenance {
    if (_self.provenance == null) {
    return null;
  }

  return $PlayerPokemonProvenanceCopyWith<$Res>(_self.provenance!, (value) {
    return _then(_self.copyWith(provenance: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlayerPokemon].
extension PlayerPokemonPatterns on PlayerPokemon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerPokemon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerPokemon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerPokemon value)  $default,){
final _that = this;
switch (_that) {
case _PlayerPokemon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerPokemon value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerPokemon() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String individualId,  String speciesId,  String formId,  String natureId,  String abilityId,  String? gender,  int level,  PokemonStatSpread ivs,  PokemonStatSpread evs,  List<String> knownMoveIds,  int? experience,  Map<String, int>? currentPpByMoveId,  int currentHp,  String statusId,  bool isShiny,  String heldItemId,  String nickname,  int friendship,  PlayerPokemonProvenance? provenance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerPokemon() when $default != null:
return $default(_that.individualId,_that.speciesId,_that.formId,_that.natureId,_that.abilityId,_that.gender,_that.level,_that.ivs,_that.evs,_that.knownMoveIds,_that.experience,_that.currentPpByMoveId,_that.currentHp,_that.statusId,_that.isShiny,_that.heldItemId,_that.nickname,_that.friendship,_that.provenance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String individualId,  String speciesId,  String formId,  String natureId,  String abilityId,  String? gender,  int level,  PokemonStatSpread ivs,  PokemonStatSpread evs,  List<String> knownMoveIds,  int? experience,  Map<String, int>? currentPpByMoveId,  int currentHp,  String statusId,  bool isShiny,  String heldItemId,  String nickname,  int friendship,  PlayerPokemonProvenance? provenance)  $default,) {final _that = this;
switch (_that) {
case _PlayerPokemon():
return $default(_that.individualId,_that.speciesId,_that.formId,_that.natureId,_that.abilityId,_that.gender,_that.level,_that.ivs,_that.evs,_that.knownMoveIds,_that.experience,_that.currentPpByMoveId,_that.currentHp,_that.statusId,_that.isShiny,_that.heldItemId,_that.nickname,_that.friendship,_that.provenance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String individualId,  String speciesId,  String formId,  String natureId,  String abilityId,  String? gender,  int level,  PokemonStatSpread ivs,  PokemonStatSpread evs,  List<String> knownMoveIds,  int? experience,  Map<String, int>? currentPpByMoveId,  int currentHp,  String statusId,  bool isShiny,  String heldItemId,  String nickname,  int friendship,  PlayerPokemonProvenance? provenance)?  $default,) {final _that = this;
switch (_that) {
case _PlayerPokemon() when $default != null:
return $default(_that.individualId,_that.speciesId,_that.formId,_that.natureId,_that.abilityId,_that.gender,_that.level,_that.ivs,_that.evs,_that.knownMoveIds,_that.experience,_that.currentPpByMoveId,_that.currentHp,_that.statusId,_that.isShiny,_that.heldItemId,_that.nickname,_that.friendship,_that.provenance);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PlayerPokemon extends PlayerPokemon {
  const _PlayerPokemon({this.individualId = '', required this.speciesId, this.formId = '', required this.natureId, required this.abilityId, this.gender, this.level = 1, this.ivs = const PokemonStatSpread(), this.evs = const PokemonStatSpread(), final  List<String> knownMoveIds = const [], this.experience, final  Map<String, int>? currentPpByMoveId, this.currentHp = 1, this.statusId = '', this.isShiny = false, this.heldItemId = '', this.nickname = '', this.friendship = 0, this.provenance}): _knownMoveIds = knownMoveIds,_currentPpByMoveId = currentPpByMoveId,super._();
  factory _PlayerPokemon.fromJson(Map<String, dynamic> json) => _$PlayerPokemonFromJson(json);

@override@JsonKey() final  String individualId;
@override final  String speciesId;
@override@JsonKey() final  String formId;
@override final  String natureId;
@override final  String abilityId;
@override final  String? gender;
@override@JsonKey() final  int level;
@override@JsonKey() final  PokemonStatSpread ivs;
@override@JsonKey() final  PokemonStatSpread evs;
 final  List<String> _knownMoveIds;
@override@JsonKey() List<String> get knownMoveIds {
  if (_knownMoveIds is EqualUnmodifiableListView) return _knownMoveIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_knownMoveIds);
}

/// Total cumulative experience.
///
/// `null` is deliberately preserved for saves created before FG-021. It
/// must not be interpreted as zero because that would silently regress a
/// legacy levelled Pokemon to the level-one experience floor.
@override final  int? experience;
/// Current PP indexed by canonical move id.
///
/// `null` is the legacy migration sentinel. An empty non-null map is a
/// fully hydrated Pokemon with no known moves; max PP stays catalogue
/// derived and therefore does not belong in this persistence contract.
 final  Map<String, int>? _currentPpByMoveId;
/// Current PP indexed by canonical move id.
///
/// `null` is the legacy migration sentinel. An empty non-null map is a
/// fully hydrated Pokemon with no known moves; max PP stays catalogue
/// derived and therefore does not belong in this persistence contract.
@override Map<String, int>? get currentPpByMoveId {
  final value = _currentPpByMoveId;
  if (value == null) return null;
  if (_currentPpByMoveId is EqualUnmodifiableMapView) return _currentPpByMoveId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  int currentHp;
@override@JsonKey() final  String statusId;
@override@JsonKey() final  bool isShiny;
@override@JsonKey() final  String heldItemId;
@override@JsonKey() final  String nickname;
@override@JsonKey() final  int friendship;
@override final  PlayerPokemonProvenance? provenance;

/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerPokemonCopyWith<_PlayerPokemon> get copyWith => __$PlayerPokemonCopyWithImpl<_PlayerPokemon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerPokemonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerPokemon&&(identical(other.individualId, individualId) || other.individualId == individualId)&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.formId, formId) || other.formId == formId)&&(identical(other.natureId, natureId) || other.natureId == natureId)&&(identical(other.abilityId, abilityId) || other.abilityId == abilityId)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.level, level) || other.level == level)&&(identical(other.ivs, ivs) || other.ivs == ivs)&&(identical(other.evs, evs) || other.evs == evs)&&const DeepCollectionEquality().equals(other._knownMoveIds, _knownMoveIds)&&(identical(other.experience, experience) || other.experience == experience)&&const DeepCollectionEquality().equals(other._currentPpByMoveId, _currentPpByMoveId)&&(identical(other.currentHp, currentHp) || other.currentHp == currentHp)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.isShiny, isShiny) || other.isShiny == isShiny)&&(identical(other.heldItemId, heldItemId) || other.heldItemId == heldItemId)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.friendship, friendship) || other.friendship == friendship)&&(identical(other.provenance, provenance) || other.provenance == provenance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,individualId,speciesId,formId,natureId,abilityId,gender,level,ivs,evs,const DeepCollectionEquality().hash(_knownMoveIds),experience,const DeepCollectionEquality().hash(_currentPpByMoveId),currentHp,statusId,isShiny,heldItemId,nickname,friendship,provenance]);

@override
String toString() {
  return 'PlayerPokemon(individualId: $individualId, speciesId: $speciesId, formId: $formId, natureId: $natureId, abilityId: $abilityId, gender: $gender, level: $level, ivs: $ivs, evs: $evs, knownMoveIds: $knownMoveIds, experience: $experience, currentPpByMoveId: $currentPpByMoveId, currentHp: $currentHp, statusId: $statusId, isShiny: $isShiny, heldItemId: $heldItemId, nickname: $nickname, friendship: $friendship, provenance: $provenance)';
}


}

/// @nodoc
abstract mixin class _$PlayerPokemonCopyWith<$Res> implements $PlayerPokemonCopyWith<$Res> {
  factory _$PlayerPokemonCopyWith(_PlayerPokemon value, $Res Function(_PlayerPokemon) _then) = __$PlayerPokemonCopyWithImpl;
@override @useResult
$Res call({
 String individualId, String speciesId, String formId, String natureId, String abilityId, String? gender, int level, PokemonStatSpread ivs, PokemonStatSpread evs, List<String> knownMoveIds, int? experience, Map<String, int>? currentPpByMoveId, int currentHp, String statusId, bool isShiny, String heldItemId, String nickname, int friendship, PlayerPokemonProvenance? provenance
});


@override $PokemonStatSpreadCopyWith<$Res> get ivs;@override $PokemonStatSpreadCopyWith<$Res> get evs;@override $PlayerPokemonProvenanceCopyWith<$Res>? get provenance;

}
/// @nodoc
class __$PlayerPokemonCopyWithImpl<$Res>
    implements _$PlayerPokemonCopyWith<$Res> {
  __$PlayerPokemonCopyWithImpl(this._self, this._then);

  final _PlayerPokemon _self;
  final $Res Function(_PlayerPokemon) _then;

/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? individualId = null,Object? speciesId = null,Object? formId = null,Object? natureId = null,Object? abilityId = null,Object? gender = freezed,Object? level = null,Object? ivs = null,Object? evs = null,Object? knownMoveIds = null,Object? experience = freezed,Object? currentPpByMoveId = freezed,Object? currentHp = null,Object? statusId = null,Object? isShiny = null,Object? heldItemId = null,Object? nickname = null,Object? friendship = null,Object? provenance = freezed,}) {
  return _then(_PlayerPokemon(
individualId: null == individualId ? _self.individualId : individualId // ignore: cast_nullable_to_non_nullable
as String,speciesId: null == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String,formId: null == formId ? _self.formId : formId // ignore: cast_nullable_to_non_nullable
as String,natureId: null == natureId ? _self.natureId : natureId // ignore: cast_nullable_to_non_nullable
as String,abilityId: null == abilityId ? _self.abilityId : abilityId // ignore: cast_nullable_to_non_nullable
as String,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,ivs: null == ivs ? _self.ivs : ivs // ignore: cast_nullable_to_non_nullable
as PokemonStatSpread,evs: null == evs ? _self.evs : evs // ignore: cast_nullable_to_non_nullable
as PokemonStatSpread,knownMoveIds: null == knownMoveIds ? _self._knownMoveIds : knownMoveIds // ignore: cast_nullable_to_non_nullable
as List<String>,experience: freezed == experience ? _self.experience : experience // ignore: cast_nullable_to_non_nullable
as int?,currentPpByMoveId: freezed == currentPpByMoveId ? _self._currentPpByMoveId : currentPpByMoveId // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,currentHp: null == currentHp ? _self.currentHp : currentHp // ignore: cast_nullable_to_non_nullable
as int,statusId: null == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as String,isShiny: null == isShiny ? _self.isShiny : isShiny // ignore: cast_nullable_to_non_nullable
as bool,heldItemId: null == heldItemId ? _self.heldItemId : heldItemId // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,friendship: null == friendship ? _self.friendship : friendship // ignore: cast_nullable_to_non_nullable
as int,provenance: freezed == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as PlayerPokemonProvenance?,
  ));
}

/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonStatSpreadCopyWith<$Res> get ivs {

  return $PokemonStatSpreadCopyWith<$Res>(_self.ivs, (value) {
    return _then(_self.copyWith(ivs: value));
  });
}/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonStatSpreadCopyWith<$Res> get evs {

  return $PokemonStatSpreadCopyWith<$Res>(_self.evs, (value) {
    return _then(_self.copyWith(evs: value));
  });
}/// Create a copy of PlayerPokemon
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerPokemonProvenanceCopyWith<$Res>? get provenance {
    if (_self.provenance == null) {
    return null;
  }

  return $PlayerPokemonProvenanceCopyWith<$Res>(_self.provenance!, (value) {
    return _then(_self.copyWith(provenance: value));
  });
}
}


/// @nodoc
mixin _$PlayerParty {

 List<PlayerPokemon> get members;
/// Create a copy of PlayerParty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerPartyCopyWith<PlayerParty> get copyWith => _$PlayerPartyCopyWithImpl<PlayerParty>(this as PlayerParty, _$identity);

  /// Serializes this PlayerParty to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerParty&&const DeepCollectionEquality().equals(other.members, members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(members));

@override
String toString() {
  return 'PlayerParty(members: $members)';
}


}

/// @nodoc
abstract mixin class $PlayerPartyCopyWith<$Res>  {
  factory $PlayerPartyCopyWith(PlayerParty value, $Res Function(PlayerParty) _then) = _$PlayerPartyCopyWithImpl;
@useResult
$Res call({
 List<PlayerPokemon> members
});




}
/// @nodoc
class _$PlayerPartyCopyWithImpl<$Res>
    implements $PlayerPartyCopyWith<$Res> {
  _$PlayerPartyCopyWithImpl(this._self, this._then);

  final PlayerParty _self;
  final $Res Function(PlayerParty) _then;

/// Create a copy of PlayerParty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? members = null,}) {
  return _then(_self.copyWith(
members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<PlayerPokemon>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerParty].
extension PlayerPartyPatterns on PlayerParty {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerParty value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerParty() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerParty value)  $default,){
final _that = this;
switch (_that) {
case _PlayerParty():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerParty value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerParty() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PlayerPokemon> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerParty() when $default != null:
return $default(_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PlayerPokemon> members)  $default,) {final _that = this;
switch (_that) {
case _PlayerParty():
return $default(_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PlayerPokemon> members)?  $default,) {final _that = this;
switch (_that) {
case _PlayerParty() when $default != null:
return $default(_that.members);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PlayerParty extends PlayerParty {
  const _PlayerParty({final  List<PlayerPokemon> members = const []}): _members = members,super._();
  factory _PlayerParty.fromJson(Map<String, dynamic> json) => _$PlayerPartyFromJson(json);

 final  List<PlayerPokemon> _members;
@override@JsonKey() List<PlayerPokemon> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of PlayerParty
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerPartyCopyWith<_PlayerParty> get copyWith => __$PlayerPartyCopyWithImpl<_PlayerParty>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerPartyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerParty&&const DeepCollectionEquality().equals(other._members, _members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_members));

@override
String toString() {
  return 'PlayerParty(members: $members)';
}


}

/// @nodoc
abstract mixin class _$PlayerPartyCopyWith<$Res> implements $PlayerPartyCopyWith<$Res> {
  factory _$PlayerPartyCopyWith(_PlayerParty value, $Res Function(_PlayerParty) _then) = __$PlayerPartyCopyWithImpl;
@override @useResult
$Res call({
 List<PlayerPokemon> members
});




}
/// @nodoc
class __$PlayerPartyCopyWithImpl<$Res>
    implements _$PlayerPartyCopyWith<$Res> {
  __$PlayerPartyCopyWithImpl(this._self, this._then);

  final _PlayerParty _self;
  final $Res Function(_PlayerParty) _then;

/// Create a copy of PlayerParty
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? members = null,}) {
  return _then(_PlayerParty(
members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<PlayerPokemon>,
  ));
}


}


/// @nodoc
mixin _$PokemonBox {

 String get id; String get label; int get capacity; List<PlayerPokemon> get pokemon;
/// Create a copy of PokemonBox
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonBoxCopyWith<PokemonBox> get copyWith => _$PokemonBoxCopyWithImpl<PokemonBox>(this as PokemonBox, _$identity);

  /// Serializes this PokemonBox to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonBox&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&const DeepCollectionEquality().equals(other.pokemon, pokemon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,capacity,const DeepCollectionEquality().hash(pokemon));

@override
String toString() {
  return 'PokemonBox(id: $id, label: $label, capacity: $capacity, pokemon: $pokemon)';
}


}

/// @nodoc
abstract mixin class $PokemonBoxCopyWith<$Res>  {
  factory $PokemonBoxCopyWith(PokemonBox value, $Res Function(PokemonBox) _then) = _$PokemonBoxCopyWithImpl;
@useResult
$Res call({
 String id, String label, int capacity, List<PlayerPokemon> pokemon
});




}
/// @nodoc
class _$PokemonBoxCopyWithImpl<$Res>
    implements $PokemonBoxCopyWith<$Res> {
  _$PokemonBoxCopyWithImpl(this._self, this._then);

  final PokemonBox _self;
  final $Res Function(PokemonBox) _then;

/// Create a copy of PokemonBox
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? capacity = null,Object? pokemon = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,pokemon: null == pokemon ? _self.pokemon : pokemon // ignore: cast_nullable_to_non_nullable
as List<PlayerPokemon>,
  ));
}

}


/// Adds pattern-matching-related methods to [PokemonBox].
extension PokemonBoxPatterns on PokemonBox {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PokemonBox value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PokemonBox() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PokemonBox value)  $default,){
final _that = this;
switch (_that) {
case _PokemonBox():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PokemonBox value)?  $default,){
final _that = this;
switch (_that) {
case _PokemonBox() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  int capacity,  List<PlayerPokemon> pokemon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PokemonBox() when $default != null:
return $default(_that.id,_that.label,_that.capacity,_that.pokemon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  int capacity,  List<PlayerPokemon> pokemon)  $default,) {final _that = this;
switch (_that) {
case _PokemonBox():
return $default(_that.id,_that.label,_that.capacity,_that.pokemon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  int capacity,  List<PlayerPokemon> pokemon)?  $default,) {final _that = this;
switch (_that) {
case _PokemonBox() when $default != null:
return $default(_that.id,_that.label,_that.capacity,_that.pokemon);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PokemonBox extends PokemonBox {
  const _PokemonBox({required this.id, required this.label, this.capacity = pokemonBoxCapacity, final  List<PlayerPokemon> pokemon = const []}): _pokemon = pokemon,super._();
  factory _PokemonBox.fromJson(Map<String, dynamic> json) => _$PokemonBoxFromJson(json);

@override final  String id;
@override final  String label;
@override@JsonKey() final  int capacity;
 final  List<PlayerPokemon> _pokemon;
@override@JsonKey() List<PlayerPokemon> get pokemon {
  if (_pokemon is EqualUnmodifiableListView) return _pokemon;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pokemon);
}


/// Create a copy of PokemonBox
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PokemonBoxCopyWith<_PokemonBox> get copyWith => __$PokemonBoxCopyWithImpl<_PokemonBox>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonBoxToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PokemonBox&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&const DeepCollectionEquality().equals(other._pokemon, _pokemon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,capacity,const DeepCollectionEquality().hash(_pokemon));

@override
String toString() {
  return 'PokemonBox(id: $id, label: $label, capacity: $capacity, pokemon: $pokemon)';
}


}

/// @nodoc
abstract mixin class _$PokemonBoxCopyWith<$Res> implements $PokemonBoxCopyWith<$Res> {
  factory _$PokemonBoxCopyWith(_PokemonBox value, $Res Function(_PokemonBox) _then) = __$PokemonBoxCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, int capacity, List<PlayerPokemon> pokemon
});




}
/// @nodoc
class __$PokemonBoxCopyWithImpl<$Res>
    implements _$PokemonBoxCopyWith<$Res> {
  __$PokemonBoxCopyWithImpl(this._self, this._then);

  final _PokemonBox _self;
  final $Res Function(_PokemonBox) _then;

/// Create a copy of PokemonBox
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? capacity = null,Object? pokemon = null,}) {
  return _then(_PokemonBox(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,pokemon: null == pokemon ? _self._pokemon : pokemon // ignore: cast_nullable_to_non_nullable
as List<PlayerPokemon>,
  ));
}


}


/// @nodoc
mixin _$PlayerProgression {

 List<FieldAbility> get unlockedFieldAbilities; List<String> get storyFlags; Map<String, int> get shopPurchaseCounts; List<String> get completedStepIds; List<String> get completedCutsceneIds; List<String> get seenSpeciesIds; List<String> get caughtSpeciesIds;
/// Create a copy of PlayerProgression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerProgressionCopyWith<PlayerProgression> get copyWith => _$PlayerProgressionCopyWithImpl<PlayerProgression>(this as PlayerProgression, _$identity);

  /// Serializes this PlayerProgression to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerProgression&&const DeepCollectionEquality().equals(other.unlockedFieldAbilities, unlockedFieldAbilities)&&const DeepCollectionEquality().equals(other.storyFlags, storyFlags)&&const DeepCollectionEquality().equals(other.shopPurchaseCounts, shopPurchaseCounts)&&const DeepCollectionEquality().equals(other.completedStepIds, completedStepIds)&&const DeepCollectionEquality().equals(other.completedCutsceneIds, completedCutsceneIds)&&const DeepCollectionEquality().equals(other.seenSpeciesIds, seenSpeciesIds)&&const DeepCollectionEquality().equals(other.caughtSpeciesIds, caughtSpeciesIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(unlockedFieldAbilities),const DeepCollectionEquality().hash(storyFlags),const DeepCollectionEquality().hash(shopPurchaseCounts),const DeepCollectionEquality().hash(completedStepIds),const DeepCollectionEquality().hash(completedCutsceneIds),const DeepCollectionEquality().hash(seenSpeciesIds),const DeepCollectionEquality().hash(caughtSpeciesIds));

@override
String toString() {
  return 'PlayerProgression(unlockedFieldAbilities: $unlockedFieldAbilities, storyFlags: $storyFlags, shopPurchaseCounts: $shopPurchaseCounts, completedStepIds: $completedStepIds, completedCutsceneIds: $completedCutsceneIds, seenSpeciesIds: $seenSpeciesIds, caughtSpeciesIds: $caughtSpeciesIds)';
}


}

/// @nodoc
abstract mixin class $PlayerProgressionCopyWith<$Res>  {
  factory $PlayerProgressionCopyWith(PlayerProgression value, $Res Function(PlayerProgression) _then) = _$PlayerProgressionCopyWithImpl;
@useResult
$Res call({
 List<FieldAbility> unlockedFieldAbilities, List<String> storyFlags, Map<String, int> shopPurchaseCounts, List<String> completedStepIds, List<String> completedCutsceneIds, List<String> seenSpeciesIds, List<String> caughtSpeciesIds
});




}
/// @nodoc
class _$PlayerProgressionCopyWithImpl<$Res>
    implements $PlayerProgressionCopyWith<$Res> {
  _$PlayerProgressionCopyWithImpl(this._self, this._then);

  final PlayerProgression _self;
  final $Res Function(PlayerProgression) _then;

/// Create a copy of PlayerProgression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unlockedFieldAbilities = null,Object? storyFlags = null,Object? shopPurchaseCounts = null,Object? completedStepIds = null,Object? completedCutsceneIds = null,Object? seenSpeciesIds = null,Object? caughtSpeciesIds = null,}) {
  return _then(_self.copyWith(
unlockedFieldAbilities: null == unlockedFieldAbilities ? _self.unlockedFieldAbilities : unlockedFieldAbilities // ignore: cast_nullable_to_non_nullable
as List<FieldAbility>,storyFlags: null == storyFlags ? _self.storyFlags : storyFlags // ignore: cast_nullable_to_non_nullable
as List<String>,shopPurchaseCounts: null == shopPurchaseCounts ? _self.shopPurchaseCounts : shopPurchaseCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,completedStepIds: null == completedStepIds ? _self.completedStepIds : completedStepIds // ignore: cast_nullable_to_non_nullable
as List<String>,completedCutsceneIds: null == completedCutsceneIds ? _self.completedCutsceneIds : completedCutsceneIds // ignore: cast_nullable_to_non_nullable
as List<String>,seenSpeciesIds: null == seenSpeciesIds ? _self.seenSpeciesIds : seenSpeciesIds // ignore: cast_nullable_to_non_nullable
as List<String>,caughtSpeciesIds: null == caughtSpeciesIds ? _self.caughtSpeciesIds : caughtSpeciesIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerProgression].
extension PlayerProgressionPatterns on PlayerProgression {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerProgression value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerProgression() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerProgression value)  $default,){
final _that = this;
switch (_that) {
case _PlayerProgression():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerProgression value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerProgression() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FieldAbility> unlockedFieldAbilities,  List<String> storyFlags,  Map<String, int> shopPurchaseCounts,  List<String> completedStepIds,  List<String> completedCutsceneIds,  List<String> seenSpeciesIds,  List<String> caughtSpeciesIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerProgression() when $default != null:
return $default(_that.unlockedFieldAbilities,_that.storyFlags,_that.shopPurchaseCounts,_that.completedStepIds,_that.completedCutsceneIds,_that.seenSpeciesIds,_that.caughtSpeciesIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FieldAbility> unlockedFieldAbilities,  List<String> storyFlags,  Map<String, int> shopPurchaseCounts,  List<String> completedStepIds,  List<String> completedCutsceneIds,  List<String> seenSpeciesIds,  List<String> caughtSpeciesIds)  $default,) {final _that = this;
switch (_that) {
case _PlayerProgression():
return $default(_that.unlockedFieldAbilities,_that.storyFlags,_that.shopPurchaseCounts,_that.completedStepIds,_that.completedCutsceneIds,_that.seenSpeciesIds,_that.caughtSpeciesIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FieldAbility> unlockedFieldAbilities,  List<String> storyFlags,  Map<String, int> shopPurchaseCounts,  List<String> completedStepIds,  List<String> completedCutsceneIds,  List<String> seenSpeciesIds,  List<String> caughtSpeciesIds)?  $default,) {final _that = this;
switch (_that) {
case _PlayerProgression() when $default != null:
return $default(_that.unlockedFieldAbilities,_that.storyFlags,_that.shopPurchaseCounts,_that.completedStepIds,_that.completedCutsceneIds,_that.seenSpeciesIds,_that.caughtSpeciesIds);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _PlayerProgression extends PlayerProgression {
  const _PlayerProgression({final  List<FieldAbility> unlockedFieldAbilities = const [], final  List<String> storyFlags = const [], final  Map<String, int> shopPurchaseCounts = const {}, final  List<String> completedStepIds = const [], final  List<String> completedCutsceneIds = const [], final  List<String> seenSpeciesIds = const [], final  List<String> caughtSpeciesIds = const []}): _unlockedFieldAbilities = unlockedFieldAbilities,_storyFlags = storyFlags,_shopPurchaseCounts = shopPurchaseCounts,_completedStepIds = completedStepIds,_completedCutsceneIds = completedCutsceneIds,_seenSpeciesIds = seenSpeciesIds,_caughtSpeciesIds = caughtSpeciesIds,super._();
  factory _PlayerProgression.fromJson(Map<String, dynamic> json) => _$PlayerProgressionFromJson(json);

 final  List<FieldAbility> _unlockedFieldAbilities;
@override@JsonKey() List<FieldAbility> get unlockedFieldAbilities {
  if (_unlockedFieldAbilities is EqualUnmodifiableListView) return _unlockedFieldAbilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unlockedFieldAbilities);
}

 final  List<String> _storyFlags;
@override@JsonKey() List<String> get storyFlags {
  if (_storyFlags is EqualUnmodifiableListView) return _storyFlags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_storyFlags);
}

 final  Map<String, int> _shopPurchaseCounts;
@override@JsonKey() Map<String, int> get shopPurchaseCounts {
  if (_shopPurchaseCounts is EqualUnmodifiableMapView) return _shopPurchaseCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_shopPurchaseCounts);
}

 final  List<String> _completedStepIds;
@override@JsonKey() List<String> get completedStepIds {
  if (_completedStepIds is EqualUnmodifiableListView) return _completedStepIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completedStepIds);
}

 final  List<String> _completedCutsceneIds;
@override@JsonKey() List<String> get completedCutsceneIds {
  if (_completedCutsceneIds is EqualUnmodifiableListView) return _completedCutsceneIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completedCutsceneIds);
}

 final  List<String> _seenSpeciesIds;
@override@JsonKey() List<String> get seenSpeciesIds {
  if (_seenSpeciesIds is EqualUnmodifiableListView) return _seenSpeciesIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seenSpeciesIds);
}

 final  List<String> _caughtSpeciesIds;
@override@JsonKey() List<String> get caughtSpeciesIds {
  if (_caughtSpeciesIds is EqualUnmodifiableListView) return _caughtSpeciesIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_caughtSpeciesIds);
}


/// Create a copy of PlayerProgression
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerProgressionCopyWith<_PlayerProgression> get copyWith => __$PlayerProgressionCopyWithImpl<_PlayerProgression>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerProgressionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerProgression&&const DeepCollectionEquality().equals(other._unlockedFieldAbilities, _unlockedFieldAbilities)&&const DeepCollectionEquality().equals(other._storyFlags, _storyFlags)&&const DeepCollectionEquality().equals(other._shopPurchaseCounts, _shopPurchaseCounts)&&const DeepCollectionEquality().equals(other._completedStepIds, _completedStepIds)&&const DeepCollectionEquality().equals(other._completedCutsceneIds, _completedCutsceneIds)&&const DeepCollectionEquality().equals(other._seenSpeciesIds, _seenSpeciesIds)&&const DeepCollectionEquality().equals(other._caughtSpeciesIds, _caughtSpeciesIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_unlockedFieldAbilities),const DeepCollectionEquality().hash(_storyFlags),const DeepCollectionEquality().hash(_shopPurchaseCounts),const DeepCollectionEquality().hash(_completedStepIds),const DeepCollectionEquality().hash(_completedCutsceneIds),const DeepCollectionEquality().hash(_seenSpeciesIds),const DeepCollectionEquality().hash(_caughtSpeciesIds));

@override
String toString() {
  return 'PlayerProgression(unlockedFieldAbilities: $unlockedFieldAbilities, storyFlags: $storyFlags, shopPurchaseCounts: $shopPurchaseCounts, completedStepIds: $completedStepIds, completedCutsceneIds: $completedCutsceneIds, seenSpeciesIds: $seenSpeciesIds, caughtSpeciesIds: $caughtSpeciesIds)';
}


}

/// @nodoc
abstract mixin class _$PlayerProgressionCopyWith<$Res> implements $PlayerProgressionCopyWith<$Res> {
  factory _$PlayerProgressionCopyWith(_PlayerProgression value, $Res Function(_PlayerProgression) _then) = __$PlayerProgressionCopyWithImpl;
@override @useResult
$Res call({
 List<FieldAbility> unlockedFieldAbilities, List<String> storyFlags, Map<String, int> shopPurchaseCounts, List<String> completedStepIds, List<String> completedCutsceneIds, List<String> seenSpeciesIds, List<String> caughtSpeciesIds
});




}
/// @nodoc
class __$PlayerProgressionCopyWithImpl<$Res>
    implements _$PlayerProgressionCopyWith<$Res> {
  __$PlayerProgressionCopyWithImpl(this._self, this._then);

  final _PlayerProgression _self;
  final $Res Function(_PlayerProgression) _then;

/// Create a copy of PlayerProgression
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unlockedFieldAbilities = null,Object? storyFlags = null,Object? shopPurchaseCounts = null,Object? completedStepIds = null,Object? completedCutsceneIds = null,Object? seenSpeciesIds = null,Object? caughtSpeciesIds = null,}) {
  return _then(_PlayerProgression(
unlockedFieldAbilities: null == unlockedFieldAbilities ? _self._unlockedFieldAbilities : unlockedFieldAbilities // ignore: cast_nullable_to_non_nullable
as List<FieldAbility>,storyFlags: null == storyFlags ? _self._storyFlags : storyFlags // ignore: cast_nullable_to_non_nullable
as List<String>,shopPurchaseCounts: null == shopPurchaseCounts ? _self._shopPurchaseCounts : shopPurchaseCounts // ignore: cast_nullable_to_non_nullable
as Map<String, int>,completedStepIds: null == completedStepIds ? _self._completedStepIds : completedStepIds // ignore: cast_nullable_to_non_nullable
as List<String>,completedCutsceneIds: null == completedCutsceneIds ? _self._completedCutsceneIds : completedCutsceneIds // ignore: cast_nullable_to_non_nullable
as List<String>,seenSpeciesIds: null == seenSpeciesIds ? _self._seenSpeciesIds : seenSpeciesIds // ignore: cast_nullable_to_non_nullable
as List<String>,caughtSpeciesIds: null == caughtSpeciesIds ? _self._caughtSpeciesIds : caughtSpeciesIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$TrainerProfile {

 String get name; String? get avatarCharacterId; PlayerPronounSet get pronounSet; List<String> get badgeIds; int get money; int get playtimeSeconds;
/// Create a copy of TrainerProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainerProfileCopyWith<TrainerProfile> get copyWith => _$TrainerProfileCopyWithImpl<TrainerProfile>(this as TrainerProfile, _$identity);

  /// Serializes this TrainerProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainerProfile&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarCharacterId, avatarCharacterId) || other.avatarCharacterId == avatarCharacterId)&&(identical(other.pronounSet, pronounSet) || other.pronounSet == pronounSet)&&const DeepCollectionEquality().equals(other.badgeIds, badgeIds)&&(identical(other.money, money) || other.money == money)&&(identical(other.playtimeSeconds, playtimeSeconds) || other.playtimeSeconds == playtimeSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,avatarCharacterId,pronounSet,const DeepCollectionEquality().hash(badgeIds),money,playtimeSeconds);

@override
String toString() {
  return 'TrainerProfile(name: $name, avatarCharacterId: $avatarCharacterId, pronounSet: $pronounSet, badgeIds: $badgeIds, money: $money, playtimeSeconds: $playtimeSeconds)';
}


}

/// @nodoc
abstract mixin class $TrainerProfileCopyWith<$Res>  {
  factory $TrainerProfileCopyWith(TrainerProfile value, $Res Function(TrainerProfile) _then) = _$TrainerProfileCopyWithImpl;
@useResult
$Res call({
 String name, String? avatarCharacterId, PlayerPronounSet pronounSet, List<String> badgeIds, int money, int playtimeSeconds
});




}
/// @nodoc
class _$TrainerProfileCopyWithImpl<$Res>
    implements $TrainerProfileCopyWith<$Res> {
  _$TrainerProfileCopyWithImpl(this._self, this._then);

  final TrainerProfile _self;
  final $Res Function(TrainerProfile) _then;

/// Create a copy of TrainerProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? avatarCharacterId = freezed,Object? pronounSet = null,Object? badgeIds = null,Object? money = null,Object? playtimeSeconds = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarCharacterId: freezed == avatarCharacterId ? _self.avatarCharacterId : avatarCharacterId // ignore: cast_nullable_to_non_nullable
as String?,pronounSet: null == pronounSet ? _self.pronounSet : pronounSet // ignore: cast_nullable_to_non_nullable
as PlayerPronounSet,badgeIds: null == badgeIds ? _self.badgeIds : badgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,money: null == money ? _self.money : money // ignore: cast_nullable_to_non_nullable
as int,playtimeSeconds: null == playtimeSeconds ? _self.playtimeSeconds : playtimeSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainerProfile].
extension TrainerProfilePatterns on TrainerProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainerProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainerProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainerProfile value)  $default,){
final _that = this;
switch (_that) {
case _TrainerProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainerProfile value)?  $default,){
final _that = this;
switch (_that) {
case _TrainerProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? avatarCharacterId,  PlayerPronounSet pronounSet,  List<String> badgeIds,  int money,  int playtimeSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainerProfile() when $default != null:
return $default(_that.name,_that.avatarCharacterId,_that.pronounSet,_that.badgeIds,_that.money,_that.playtimeSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? avatarCharacterId,  PlayerPronounSet pronounSet,  List<String> badgeIds,  int money,  int playtimeSeconds)  $default,) {final _that = this;
switch (_that) {
case _TrainerProfile():
return $default(_that.name,_that.avatarCharacterId,_that.pronounSet,_that.badgeIds,_that.money,_that.playtimeSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? avatarCharacterId,  PlayerPronounSet pronounSet,  List<String> badgeIds,  int money,  int playtimeSeconds)?  $default,) {final _that = this;
switch (_that) {
case _TrainerProfile() when $default != null:
return $default(_that.name,_that.avatarCharacterId,_that.pronounSet,_that.badgeIds,_that.money,_that.playtimeSeconds);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _TrainerProfile extends TrainerProfile {
  const _TrainerProfile({required this.name, this.avatarCharacterId, this.pronounSet = PlayerPronounSet.neutral, final  List<String> badgeIds = const [], this.money = 0, this.playtimeSeconds = 0}): _badgeIds = badgeIds,super._();
  factory _TrainerProfile.fromJson(Map<String, dynamic> json) => _$TrainerProfileFromJson(json);

@override final  String name;
@override final  String? avatarCharacterId;
@override@JsonKey() final  PlayerPronounSet pronounSet;
 final  List<String> _badgeIds;
@override@JsonKey() List<String> get badgeIds {
  if (_badgeIds is EqualUnmodifiableListView) return _badgeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badgeIds);
}

@override@JsonKey() final  int money;
@override@JsonKey() final  int playtimeSeconds;

/// Create a copy of TrainerProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainerProfileCopyWith<_TrainerProfile> get copyWith => __$TrainerProfileCopyWithImpl<_TrainerProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainerProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainerProfile&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarCharacterId, avatarCharacterId) || other.avatarCharacterId == avatarCharacterId)&&(identical(other.pronounSet, pronounSet) || other.pronounSet == pronounSet)&&const DeepCollectionEquality().equals(other._badgeIds, _badgeIds)&&(identical(other.money, money) || other.money == money)&&(identical(other.playtimeSeconds, playtimeSeconds) || other.playtimeSeconds == playtimeSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,avatarCharacterId,pronounSet,const DeepCollectionEquality().hash(_badgeIds),money,playtimeSeconds);

@override
String toString() {
  return 'TrainerProfile(name: $name, avatarCharacterId: $avatarCharacterId, pronounSet: $pronounSet, badgeIds: $badgeIds, money: $money, playtimeSeconds: $playtimeSeconds)';
}


}

/// @nodoc
abstract mixin class _$TrainerProfileCopyWith<$Res> implements $TrainerProfileCopyWith<$Res> {
  factory _$TrainerProfileCopyWith(_TrainerProfile value, $Res Function(_TrainerProfile) _then) = __$TrainerProfileCopyWithImpl;
@override @useResult
$Res call({
 String name, String? avatarCharacterId, PlayerPronounSet pronounSet, List<String> badgeIds, int money, int playtimeSeconds
});




}
/// @nodoc
class __$TrainerProfileCopyWithImpl<$Res>
    implements _$TrainerProfileCopyWith<$Res> {
  __$TrainerProfileCopyWithImpl(this._self, this._then);

  final _TrainerProfile _self;
  final $Res Function(_TrainerProfile) _then;

/// Create a copy of TrainerProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? avatarCharacterId = freezed,Object? pronounSet = null,Object? badgeIds = null,Object? money = null,Object? playtimeSeconds = null,}) {
  return _then(_TrainerProfile(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarCharacterId: freezed == avatarCharacterId ? _self.avatarCharacterId : avatarCharacterId // ignore: cast_nullable_to_non_nullable
as String?,pronounSet: null == pronounSet ? _self.pronounSet : pronounSet // ignore: cast_nullable_to_non_nullable
as PlayerPronounSet,badgeIds: null == badgeIds ? _self._badgeIds : badgeIds // ignore: cast_nullable_to_non_nullable
as List<String>,money: null == money ? _self.money : money // ignore: cast_nullable_to_non_nullable
as int,playtimeSeconds: null == playtimeSeconds ? _self.playtimeSeconds : playtimeSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$BagEntry {

 String get itemId; int get quantity;
/// Create a copy of BagEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BagEntryCopyWith<BagEntry> get copyWith => _$BagEntryCopyWithImpl<BagEntry>(this as BagEntry, _$identity);

  /// Serializes this BagEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BagEntry&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,quantity);

@override
String toString() {
  return 'BagEntry(itemId: $itemId, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $BagEntryCopyWith<$Res>  {
  factory $BagEntryCopyWith(BagEntry value, $Res Function(BagEntry) _then) = _$BagEntryCopyWithImpl;
@useResult
$Res call({
 String itemId, int quantity
});




}
/// @nodoc
class _$BagEntryCopyWithImpl<$Res>
    implements $BagEntryCopyWith<$Res> {
  _$BagEntryCopyWithImpl(this._self, this._then);

  final BagEntry _self;
  final $Res Function(BagEntry) _then;

/// Create a copy of BagEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BagEntry].
extension BagEntryPatterns on BagEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BagEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BagEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BagEntry value)  $default,){
final _that = this;
switch (_that) {
case _BagEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BagEntry value)?  $default,){
final _that = this;
switch (_that) {
case _BagEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId,  int quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BagEntry() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId,  int quantity)  $default,) {final _that = this;
switch (_that) {
case _BagEntry():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId,  int quantity)?  $default,) {final _that = this;
switch (_that) {
case _BagEntry() when $default != null:
return $default(_that.itemId,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _BagEntry extends BagEntry {
  const _BagEntry({required this.itemId, required this.quantity}): super._();
  factory _BagEntry.fromJson(Map<String, dynamic> json) => _$BagEntryFromJson(json);

@override final  String itemId;
@override final  int quantity;

/// Create a copy of BagEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BagEntryCopyWith<_BagEntry> get copyWith => __$BagEntryCopyWithImpl<_BagEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BagEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BagEntry&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,quantity);

@override
String toString() {
  return 'BagEntry(itemId: $itemId, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$BagEntryCopyWith<$Res> implements $BagEntryCopyWith<$Res> {
  factory _$BagEntryCopyWith(_BagEntry value, $Res Function(_BagEntry) _then) = __$BagEntryCopyWithImpl;
@override @useResult
$Res call({
 String itemId, int quantity
});




}
/// @nodoc
class __$BagEntryCopyWithImpl<$Res>
    implements _$BagEntryCopyWith<$Res> {
  __$BagEntryCopyWithImpl(this._self, this._then);

  final _BagEntry _self;
  final $Res Function(_BagEntry) _then;

/// Create a copy of BagEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? quantity = null,}) {
  return _then(_BagEntry(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Bag {

 List<BagEntry> get entries;
/// Create a copy of Bag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BagCopyWith<Bag> get copyWith => _$BagCopyWithImpl<Bag>(this as Bag, _$identity);

  /// Serializes this Bag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bag&&const DeepCollectionEquality().equals(other.entries, entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'Bag(entries: $entries)';
}


}

/// @nodoc
abstract mixin class $BagCopyWith<$Res>  {
  factory $BagCopyWith(Bag value, $Res Function(Bag) _then) = _$BagCopyWithImpl;
@useResult
$Res call({
 List<BagEntry> entries
});




}
/// @nodoc
class _$BagCopyWithImpl<$Res>
    implements $BagCopyWith<$Res> {
  _$BagCopyWithImpl(this._self, this._then);

  final Bag _self;
  final $Res Function(Bag) _then;

/// Create a copy of Bag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,}) {
  return _then(_self.copyWith(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<BagEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [Bag].
extension BagPatterns on Bag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Bag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Bag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Bag value)  $default,){
final _that = this;
switch (_that) {
case _Bag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Bag value)?  $default,){
final _that = this;
switch (_that) {
case _Bag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BagEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Bag() when $default != null:
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BagEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _Bag():
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BagEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _Bag() when $default != null:
return $default(_that.entries);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Bag extends Bag {
  const _Bag({final  List<BagEntry> entries = const []}): _entries = entries,super._();
  factory _Bag.fromJson(Map<String, dynamic> json) => _$BagFromJson(json);

 final  List<BagEntry> _entries;
@override@JsonKey() List<BagEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of Bag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BagCopyWith<_Bag> get copyWith => __$BagCopyWithImpl<_Bag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Bag&&const DeepCollectionEquality().equals(other._entries, _entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'Bag(entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$BagCopyWith<$Res> implements $BagCopyWith<$Res> {
  factory _$BagCopyWith(_Bag value, $Res Function(_Bag) _then) = __$BagCopyWithImpl;
@override @useResult
$Res call({
 List<BagEntry> entries
});




}
/// @nodoc
class __$BagCopyWithImpl<$Res>
    implements _$BagCopyWith<$Res> {
  __$BagCopyWithImpl(this._self, this._then);

  final _Bag _self;
  final $Res Function(_Bag) _then;

/// Create a copy of Bag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,}) {
  return _then(_Bag(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<BagEntry>,
  ));
}


}


/// @nodoc
mixin _$SaveData {

 String get saveId; int get itemSystemSchemaVersion; String get currentMapId; GridPos get playerPosition; EntityFacing get playerFacing; PlayerParty get party; PokemonStorage get pokemonStorage; TrainerProfile get trainerProfile; Bag get bag; PlayerProgression get progression;@JsonKey(readValue: readNarrativeFactRuntimeStateJson) NarrativeFactRuntimeState get narrativeFactRuntimeState;@JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) NarrativeEventProgress get narrativeEventProgress; PlayerPauseMenuState get pauseMenuState; Set<String> get completedBattleRequestIds; Set<String> get appliedPokemonGrantOperationIds; Map<String, String> get properties;
/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveDataCopyWith<SaveData> get copyWith => _$SaveDataCopyWithImpl<SaveData>(this as SaveData, _$identity);

  /// Serializes this SaveData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveData&&(identical(other.saveId, saveId) || other.saveId == saveId)&&(identical(other.itemSystemSchemaVersion, itemSystemSchemaVersion) || other.itemSystemSchemaVersion == itemSystemSchemaVersion)&&(identical(other.currentMapId, currentMapId) || other.currentMapId == currentMapId)&&(identical(other.playerPosition, playerPosition) || other.playerPosition == playerPosition)&&(identical(other.playerFacing, playerFacing) || other.playerFacing == playerFacing)&&(identical(other.party, party) || other.party == party)&&(identical(other.pokemonStorage, pokemonStorage) || other.pokemonStorage == pokemonStorage)&&(identical(other.trainerProfile, trainerProfile) || other.trainerProfile == trainerProfile)&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.progression, progression) || other.progression == progression)&&(identical(other.narrativeFactRuntimeState, narrativeFactRuntimeState) || other.narrativeFactRuntimeState == narrativeFactRuntimeState)&&(identical(other.narrativeEventProgress, narrativeEventProgress) || other.narrativeEventProgress == narrativeEventProgress)&&(identical(other.pauseMenuState, pauseMenuState) || other.pauseMenuState == pauseMenuState)&&const DeepCollectionEquality().equals(other.completedBattleRequestIds, completedBattleRequestIds)&&const DeepCollectionEquality().equals(other.appliedPokemonGrantOperationIds, appliedPokemonGrantOperationIds)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,saveId,itemSystemSchemaVersion,currentMapId,playerPosition,playerFacing,party,pokemonStorage,trainerProfile,bag,progression,narrativeFactRuntimeState,narrativeEventProgress,pauseMenuState,const DeepCollectionEquality().hash(completedBattleRequestIds),const DeepCollectionEquality().hash(appliedPokemonGrantOperationIds),const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'SaveData(saveId: $saveId, itemSystemSchemaVersion: $itemSystemSchemaVersion, currentMapId: $currentMapId, playerPosition: $playerPosition, playerFacing: $playerFacing, party: $party, pokemonStorage: $pokemonStorage, trainerProfile: $trainerProfile, bag: $bag, progression: $progression, narrativeFactRuntimeState: $narrativeFactRuntimeState, narrativeEventProgress: $narrativeEventProgress, pauseMenuState: $pauseMenuState, completedBattleRequestIds: $completedBattleRequestIds, appliedPokemonGrantOperationIds: $appliedPokemonGrantOperationIds, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $SaveDataCopyWith<$Res>  {
  factory $SaveDataCopyWith(SaveData value, $Res Function(SaveData) _then) = _$SaveDataCopyWithImpl;
@useResult
$Res call({
 String saveId, int itemSystemSchemaVersion, String currentMapId, GridPos playerPosition, EntityFacing playerFacing, PlayerParty party, PokemonStorage pokemonStorage, TrainerProfile trainerProfile, Bag bag, PlayerProgression progression,@JsonKey(readValue: readNarrativeFactRuntimeStateJson) NarrativeFactRuntimeState narrativeFactRuntimeState,@JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) NarrativeEventProgress narrativeEventProgress, PlayerPauseMenuState pauseMenuState, Set<String> completedBattleRequestIds, Set<String> appliedPokemonGrantOperationIds, Map<String, String> properties
});


$GridPosCopyWith<$Res> get playerPosition;$PlayerPartyCopyWith<$Res> get party;$TrainerProfileCopyWith<$Res> get trainerProfile;$BagCopyWith<$Res> get bag;$PlayerProgressionCopyWith<$Res> get progression;

}
/// @nodoc
class _$SaveDataCopyWithImpl<$Res>
    implements $SaveDataCopyWith<$Res> {
  _$SaveDataCopyWithImpl(this._self, this._then);

  final SaveData _self;
  final $Res Function(SaveData) _then;

/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? saveId = null,Object? itemSystemSchemaVersion = null,Object? currentMapId = null,Object? playerPosition = null,Object? playerFacing = null,Object? party = null,Object? pokemonStorage = null,Object? trainerProfile = null,Object? bag = null,Object? progression = null,Object? narrativeFactRuntimeState = null,Object? narrativeEventProgress = null,Object? pauseMenuState = null,Object? completedBattleRequestIds = null,Object? appliedPokemonGrantOperationIds = null,Object? properties = null,}) {
  return _then(_self.copyWith(
saveId: null == saveId ? _self.saveId : saveId // ignore: cast_nullable_to_non_nullable
as String,itemSystemSchemaVersion: null == itemSystemSchemaVersion ? _self.itemSystemSchemaVersion : itemSystemSchemaVersion // ignore: cast_nullable_to_non_nullable
as int,currentMapId: null == currentMapId ? _self.currentMapId : currentMapId // ignore: cast_nullable_to_non_nullable
as String,playerPosition: null == playerPosition ? _self.playerPosition : playerPosition // ignore: cast_nullable_to_non_nullable
as GridPos,playerFacing: null == playerFacing ? _self.playerFacing : playerFacing // ignore: cast_nullable_to_non_nullable
as EntityFacing,party: null == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as PlayerParty,pokemonStorage: null == pokemonStorage ? _self.pokemonStorage : pokemonStorage // ignore: cast_nullable_to_non_nullable
as PokemonStorage,trainerProfile: null == trainerProfile ? _self.trainerProfile : trainerProfile // ignore: cast_nullable_to_non_nullable
as TrainerProfile,bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as Bag,progression: null == progression ? _self.progression : progression // ignore: cast_nullable_to_non_nullable
as PlayerProgression,narrativeFactRuntimeState: null == narrativeFactRuntimeState ? _self.narrativeFactRuntimeState : narrativeFactRuntimeState // ignore: cast_nullable_to_non_nullable
as NarrativeFactRuntimeState,narrativeEventProgress: null == narrativeEventProgress ? _self.narrativeEventProgress : narrativeEventProgress // ignore: cast_nullable_to_non_nullable
as NarrativeEventProgress,pauseMenuState: null == pauseMenuState ? _self.pauseMenuState : pauseMenuState // ignore: cast_nullable_to_non_nullable
as PlayerPauseMenuState,completedBattleRequestIds: null == completedBattleRequestIds ? _self.completedBattleRequestIds : completedBattleRequestIds // ignore: cast_nullable_to_non_nullable
as Set<String>,appliedPokemonGrantOperationIds: null == appliedPokemonGrantOperationIds ? _self.appliedPokemonGrantOperationIds : appliedPokemonGrantOperationIds // ignore: cast_nullable_to_non_nullable
as Set<String>,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get playerPosition {

  return $GridPosCopyWith<$Res>(_self.playerPosition, (value) {
    return _then(_self.copyWith(playerPosition: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerPartyCopyWith<$Res> get party {

  return $PlayerPartyCopyWith<$Res>(_self.party, (value) {
    return _then(_self.copyWith(party: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainerProfileCopyWith<$Res> get trainerProfile {

  return $TrainerProfileCopyWith<$Res>(_self.trainerProfile, (value) {
    return _then(_self.copyWith(trainerProfile: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BagCopyWith<$Res> get bag {

  return $BagCopyWith<$Res>(_self.bag, (value) {
    return _then(_self.copyWith(bag: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerProgressionCopyWith<$Res> get progression {

  return $PlayerProgressionCopyWith<$Res>(_self.progression, (value) {
    return _then(_self.copyWith(progression: value));
  });
}
}


/// Adds pattern-matching-related methods to [SaveData].
extension SaveDataPatterns on SaveData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SaveData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SaveData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SaveData value)  $default,){
final _that = this;
switch (_that) {
case _SaveData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SaveData value)?  $default,){
final _that = this;
switch (_that) {
case _SaveData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String saveId,  int itemSystemSchemaVersion,  String currentMapId,  GridPos playerPosition,  EntityFacing playerFacing,  PlayerParty party,  PokemonStorage pokemonStorage,  TrainerProfile trainerProfile,  Bag bag,  PlayerProgression progression, @JsonKey(readValue: readNarrativeFactRuntimeStateJson)  NarrativeFactRuntimeState narrativeFactRuntimeState, @JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson)  NarrativeEventProgress narrativeEventProgress,  PlayerPauseMenuState pauseMenuState,  Set<String> completedBattleRequestIds,  Set<String> appliedPokemonGrantOperationIds,  Map<String, String> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SaveData() when $default != null:
return $default(_that.saveId,_that.itemSystemSchemaVersion,_that.currentMapId,_that.playerPosition,_that.playerFacing,_that.party,_that.pokemonStorage,_that.trainerProfile,_that.bag,_that.progression,_that.narrativeFactRuntimeState,_that.narrativeEventProgress,_that.pauseMenuState,_that.completedBattleRequestIds,_that.appliedPokemonGrantOperationIds,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String saveId,  int itemSystemSchemaVersion,  String currentMapId,  GridPos playerPosition,  EntityFacing playerFacing,  PlayerParty party,  PokemonStorage pokemonStorage,  TrainerProfile trainerProfile,  Bag bag,  PlayerProgression progression, @JsonKey(readValue: readNarrativeFactRuntimeStateJson)  NarrativeFactRuntimeState narrativeFactRuntimeState, @JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson)  NarrativeEventProgress narrativeEventProgress,  PlayerPauseMenuState pauseMenuState,  Set<String> completedBattleRequestIds,  Set<String> appliedPokemonGrantOperationIds,  Map<String, String> properties)  $default,) {final _that = this;
switch (_that) {
case _SaveData():
return $default(_that.saveId,_that.itemSystemSchemaVersion,_that.currentMapId,_that.playerPosition,_that.playerFacing,_that.party,_that.pokemonStorage,_that.trainerProfile,_that.bag,_that.progression,_that.narrativeFactRuntimeState,_that.narrativeEventProgress,_that.pauseMenuState,_that.completedBattleRequestIds,_that.appliedPokemonGrantOperationIds,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String saveId,  int itemSystemSchemaVersion,  String currentMapId,  GridPos playerPosition,  EntityFacing playerFacing,  PlayerParty party,  PokemonStorage pokemonStorage,  TrainerProfile trainerProfile,  Bag bag,  PlayerProgression progression, @JsonKey(readValue: readNarrativeFactRuntimeStateJson)  NarrativeFactRuntimeState narrativeFactRuntimeState, @JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson)  NarrativeEventProgress narrativeEventProgress,  PlayerPauseMenuState pauseMenuState,  Set<String> completedBattleRequestIds,  Set<String> appliedPokemonGrantOperationIds,  Map<String, String> properties)?  $default,) {final _that = this;
switch (_that) {
case _SaveData() when $default != null:
return $default(_that.saveId,_that.itemSystemSchemaVersion,_that.currentMapId,_that.playerPosition,_that.playerFacing,_that.party,_that.pokemonStorage,_that.trainerProfile,_that.bag,_that.progression,_that.narrativeFactRuntimeState,_that.narrativeEventProgress,_that.pauseMenuState,_that.completedBattleRequestIds,_that.appliedPokemonGrantOperationIds,_that.properties);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SaveData extends SaveData {
  const _SaveData({required this.saveId, this.itemSystemSchemaVersion = currentItemSystemSaveSchemaVersion, this.currentMapId = '', this.playerPosition = const GridPos(x: 0, y: 0), this.playerFacing = EntityFacing.south, this.party = const PlayerParty(), this.pokemonStorage = const PokemonStorage(), this.trainerProfile = const TrainerProfile(name: 'Player'), this.bag = const Bag(), this.progression = const PlayerProgression(), @JsonKey(readValue: readNarrativeFactRuntimeStateJson) this.narrativeFactRuntimeState = const NarrativeFactRuntimeState.empty(), @JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) this.narrativeEventProgress = const NarrativeEventProgress.empty(), this.pauseMenuState = const PlayerPauseMenuState.empty(), final  Set<String> completedBattleRequestIds = const {}, final  Set<String> appliedPokemonGrantOperationIds = const {}, final  Map<String, String> properties = const {}}): _completedBattleRequestIds = completedBattleRequestIds,_appliedPokemonGrantOperationIds = appliedPokemonGrantOperationIds,_properties = properties,super._();
  factory _SaveData.fromJson(Map<String, dynamic> json) => _$SaveDataFromJson(json);

@override final  String saveId;
@override@JsonKey() final  int itemSystemSchemaVersion;
@override@JsonKey() final  String currentMapId;
@override@JsonKey() final  GridPos playerPosition;
@override@JsonKey() final  EntityFacing playerFacing;
@override@JsonKey() final  PlayerParty party;
@override@JsonKey() final  PokemonStorage pokemonStorage;
@override@JsonKey() final  TrainerProfile trainerProfile;
@override@JsonKey() final  Bag bag;
@override@JsonKey() final  PlayerProgression progression;
@override@JsonKey(readValue: readNarrativeFactRuntimeStateJson) final  NarrativeFactRuntimeState narrativeFactRuntimeState;
@override@JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) final  NarrativeEventProgress narrativeEventProgress;
@override@JsonKey() final  PlayerPauseMenuState pauseMenuState;
 final  Set<String> _completedBattleRequestIds;
@override@JsonKey() Set<String> get completedBattleRequestIds {
  if (_completedBattleRequestIds is EqualUnmodifiableSetView) return _completedBattleRequestIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_completedBattleRequestIds);
}

 final  Set<String> _appliedPokemonGrantOperationIds;
@override@JsonKey() Set<String> get appliedPokemonGrantOperationIds {
  if (_appliedPokemonGrantOperationIds is EqualUnmodifiableSetView) return _appliedPokemonGrantOperationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_appliedPokemonGrantOperationIds);
}

 final  Map<String, String> _properties;
@override@JsonKey() Map<String, String> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveDataCopyWith<_SaveData> get copyWith => __$SaveDataCopyWithImpl<_SaveData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SaveDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveData&&(identical(other.saveId, saveId) || other.saveId == saveId)&&(identical(other.itemSystemSchemaVersion, itemSystemSchemaVersion) || other.itemSystemSchemaVersion == itemSystemSchemaVersion)&&(identical(other.currentMapId, currentMapId) || other.currentMapId == currentMapId)&&(identical(other.playerPosition, playerPosition) || other.playerPosition == playerPosition)&&(identical(other.playerFacing, playerFacing) || other.playerFacing == playerFacing)&&(identical(other.party, party) || other.party == party)&&(identical(other.pokemonStorage, pokemonStorage) || other.pokemonStorage == pokemonStorage)&&(identical(other.trainerProfile, trainerProfile) || other.trainerProfile == trainerProfile)&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.progression, progression) || other.progression == progression)&&(identical(other.narrativeFactRuntimeState, narrativeFactRuntimeState) || other.narrativeFactRuntimeState == narrativeFactRuntimeState)&&(identical(other.narrativeEventProgress, narrativeEventProgress) || other.narrativeEventProgress == narrativeEventProgress)&&(identical(other.pauseMenuState, pauseMenuState) || other.pauseMenuState == pauseMenuState)&&const DeepCollectionEquality().equals(other._completedBattleRequestIds, _completedBattleRequestIds)&&const DeepCollectionEquality().equals(other._appliedPokemonGrantOperationIds, _appliedPokemonGrantOperationIds)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,saveId,itemSystemSchemaVersion,currentMapId,playerPosition,playerFacing,party,pokemonStorage,trainerProfile,bag,progression,narrativeFactRuntimeState,narrativeEventProgress,pauseMenuState,const DeepCollectionEquality().hash(_completedBattleRequestIds),const DeepCollectionEquality().hash(_appliedPokemonGrantOperationIds),const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'SaveData(saveId: $saveId, itemSystemSchemaVersion: $itemSystemSchemaVersion, currentMapId: $currentMapId, playerPosition: $playerPosition, playerFacing: $playerFacing, party: $party, pokemonStorage: $pokemonStorage, trainerProfile: $trainerProfile, bag: $bag, progression: $progression, narrativeFactRuntimeState: $narrativeFactRuntimeState, narrativeEventProgress: $narrativeEventProgress, pauseMenuState: $pauseMenuState, completedBattleRequestIds: $completedBattleRequestIds, appliedPokemonGrantOperationIds: $appliedPokemonGrantOperationIds, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$SaveDataCopyWith<$Res> implements $SaveDataCopyWith<$Res> {
  factory _$SaveDataCopyWith(_SaveData value, $Res Function(_SaveData) _then) = __$SaveDataCopyWithImpl;
@override @useResult
$Res call({
 String saveId, int itemSystemSchemaVersion, String currentMapId, GridPos playerPosition, EntityFacing playerFacing, PlayerParty party, PokemonStorage pokemonStorage, TrainerProfile trainerProfile, Bag bag, PlayerProgression progression,@JsonKey(readValue: readNarrativeFactRuntimeStateJson) NarrativeFactRuntimeState narrativeFactRuntimeState,@JsonKey(readValue: readNarrativeEventProgressJson, toJson: narrativeEventProgressToJson) NarrativeEventProgress narrativeEventProgress, PlayerPauseMenuState pauseMenuState, Set<String> completedBattleRequestIds, Set<String> appliedPokemonGrantOperationIds, Map<String, String> properties
});


@override $GridPosCopyWith<$Res> get playerPosition;@override $PlayerPartyCopyWith<$Res> get party;@override $TrainerProfileCopyWith<$Res> get trainerProfile;@override $BagCopyWith<$Res> get bag;@override $PlayerProgressionCopyWith<$Res> get progression;

}
/// @nodoc
class __$SaveDataCopyWithImpl<$Res>
    implements _$SaveDataCopyWith<$Res> {
  __$SaveDataCopyWithImpl(this._self, this._then);

  final _SaveData _self;
  final $Res Function(_SaveData) _then;

/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? saveId = null,Object? itemSystemSchemaVersion = null,Object? currentMapId = null,Object? playerPosition = null,Object? playerFacing = null,Object? party = null,Object? pokemonStorage = null,Object? trainerProfile = null,Object? bag = null,Object? progression = null,Object? narrativeFactRuntimeState = null,Object? narrativeEventProgress = null,Object? pauseMenuState = null,Object? completedBattleRequestIds = null,Object? appliedPokemonGrantOperationIds = null,Object? properties = null,}) {
  return _then(_SaveData(
saveId: null == saveId ? _self.saveId : saveId // ignore: cast_nullable_to_non_nullable
as String,itemSystemSchemaVersion: null == itemSystemSchemaVersion ? _self.itemSystemSchemaVersion : itemSystemSchemaVersion // ignore: cast_nullable_to_non_nullable
as int,currentMapId: null == currentMapId ? _self.currentMapId : currentMapId // ignore: cast_nullable_to_non_nullable
as String,playerPosition: null == playerPosition ? _self.playerPosition : playerPosition // ignore: cast_nullable_to_non_nullable
as GridPos,playerFacing: null == playerFacing ? _self.playerFacing : playerFacing // ignore: cast_nullable_to_non_nullable
as EntityFacing,party: null == party ? _self.party : party // ignore: cast_nullable_to_non_nullable
as PlayerParty,pokemonStorage: null == pokemonStorage ? _self.pokemonStorage : pokemonStorage // ignore: cast_nullable_to_non_nullable
as PokemonStorage,trainerProfile: null == trainerProfile ? _self.trainerProfile : trainerProfile // ignore: cast_nullable_to_non_nullable
as TrainerProfile,bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as Bag,progression: null == progression ? _self.progression : progression // ignore: cast_nullable_to_non_nullable
as PlayerProgression,narrativeFactRuntimeState: null == narrativeFactRuntimeState ? _self.narrativeFactRuntimeState : narrativeFactRuntimeState // ignore: cast_nullable_to_non_nullable
as NarrativeFactRuntimeState,narrativeEventProgress: null == narrativeEventProgress ? _self.narrativeEventProgress : narrativeEventProgress // ignore: cast_nullable_to_non_nullable
as NarrativeEventProgress,pauseMenuState: null == pauseMenuState ? _self.pauseMenuState : pauseMenuState // ignore: cast_nullable_to_non_nullable
as PlayerPauseMenuState,completedBattleRequestIds: null == completedBattleRequestIds ? _self._completedBattleRequestIds : completedBattleRequestIds // ignore: cast_nullable_to_non_nullable
as Set<String>,appliedPokemonGrantOperationIds: null == appliedPokemonGrantOperationIds ? _self._appliedPokemonGrantOperationIds : appliedPokemonGrantOperationIds // ignore: cast_nullable_to_non_nullable
as Set<String>,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res> get playerPosition {

  return $GridPosCopyWith<$Res>(_self.playerPosition, (value) {
    return _then(_self.copyWith(playerPosition: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerPartyCopyWith<$Res> get party {

  return $PlayerPartyCopyWith<$Res>(_self.party, (value) {
    return _then(_self.copyWith(party: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainerProfileCopyWith<$Res> get trainerProfile {

  return $TrainerProfileCopyWith<$Res>(_self.trainerProfile, (value) {
    return _then(_self.copyWith(trainerProfile: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BagCopyWith<$Res> get bag {

  return $BagCopyWith<$Res>(_self.bag, (value) {
    return _then(_self.copyWith(bag: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlayerProgressionCopyWith<$Res> get progression {

  return $PlayerProgressionCopyWith<$Res>(_self.progression, (value) {
    return _then(_self.copyWith(progression: value));
  });
}
}

// dart format on
