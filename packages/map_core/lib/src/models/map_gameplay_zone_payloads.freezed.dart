// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_gameplay_zone_payloads.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EncounterZonePayload {

/// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
 String? get encounterTableId;/// Type de rencontre déclenchée dans cette zone.
 EncounterKind get encounterKind;/// Image de fond de combat authorée explicitement pour cette zone.
///
/// Le chemin reste project-local et optionnel :
/// - aucune bibliothèque média globale n'est introduite ici ;
/// - le runtime pourra l'utiliser comme override visuel du fond contextuel ;
/// - l'absence de valeur garde le comportement contextuel existant.
 String? get battleBackgroundRelativePath;/// Musique des combats déclenchés dans cette zone — BETA-BAT-015.
///
/// Même sémantique que le fond : chemin project-local optionnel. La
/// chaîne runtime la place entre le thème explicite du dresseur et la
/// musique de combat de la carte ; vide = la chaîne continue.
 String? get battleMusicPath;/// Musique de rencontre jouée quand un dresseur repère le joueur dans
/// cette zone — BETA-BAT-015. Gagne sur le défaut projet ; vide = défaut.
 String? get encounterMusicPath;/// Transitions de début de combat de cette zone — BETA-BAT-019.
///
/// Des ids du registre moteur (`battleTransitionRegistry`). Plusieurs
/// valeurs = le runtime en tire une par rencontre (déterministe par
/// requête, donc rejouable). Vide = le défaut projet puis le défaut
/// moteur ; un id inconnu retombe sur le défaut du type sans jamais
/// casser l'entrée en combat.
 List<String> get battleTransitionIds;
/// Create a copy of EncounterZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EncounterZonePayloadCopyWith<EncounterZonePayload> get copyWith => _$EncounterZonePayloadCopyWithImpl<EncounterZonePayload>(this as EncounterZonePayload, _$identity);

  /// Serializes this EncounterZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EncounterZonePayload&&(identical(other.encounterTableId, encounterTableId) || other.encounterTableId == encounterTableId)&&(identical(other.encounterKind, encounterKind) || other.encounterKind == encounterKind)&&(identical(other.battleBackgroundRelativePath, battleBackgroundRelativePath) || other.battleBackgroundRelativePath == battleBackgroundRelativePath)&&(identical(other.battleMusicPath, battleMusicPath) || other.battleMusicPath == battleMusicPath)&&(identical(other.encounterMusicPath, encounterMusicPath) || other.encounterMusicPath == encounterMusicPath)&&const DeepCollectionEquality().equals(other.battleTransitionIds, battleTransitionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,encounterTableId,encounterKind,battleBackgroundRelativePath,battleMusicPath,encounterMusicPath,const DeepCollectionEquality().hash(battleTransitionIds));

@override
String toString() {
  return 'EncounterZonePayload(encounterTableId: $encounterTableId, encounterKind: $encounterKind, battleBackgroundRelativePath: $battleBackgroundRelativePath, battleMusicPath: $battleMusicPath, encounterMusicPath: $encounterMusicPath, battleTransitionIds: $battleTransitionIds)';
}


}

/// @nodoc
abstract mixin class $EncounterZonePayloadCopyWith<$Res>  {
  factory $EncounterZonePayloadCopyWith(EncounterZonePayload value, $Res Function(EncounterZonePayload) _then) = _$EncounterZonePayloadCopyWithImpl;
@useResult
$Res call({
 String? encounterTableId, EncounterKind encounterKind, String? battleBackgroundRelativePath, String? battleMusicPath, String? encounterMusicPath, List<String> battleTransitionIds
});




}
/// @nodoc
class _$EncounterZonePayloadCopyWithImpl<$Res>
    implements $EncounterZonePayloadCopyWith<$Res> {
  _$EncounterZonePayloadCopyWithImpl(this._self, this._then);

  final EncounterZonePayload _self;
  final $Res Function(EncounterZonePayload) _then;

/// Create a copy of EncounterZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? encounterTableId = freezed,Object? encounterKind = null,Object? battleBackgroundRelativePath = freezed,Object? battleMusicPath = freezed,Object? encounterMusicPath = freezed,Object? battleTransitionIds = null,}) {
  return _then(_self.copyWith(
encounterTableId: freezed == encounterTableId ? _self.encounterTableId : encounterTableId // ignore: cast_nullable_to_non_nullable
as String?,encounterKind: null == encounterKind ? _self.encounterKind : encounterKind // ignore: cast_nullable_to_non_nullable
as EncounterKind,battleBackgroundRelativePath: freezed == battleBackgroundRelativePath ? _self.battleBackgroundRelativePath : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
as String?,battleMusicPath: freezed == battleMusicPath ? _self.battleMusicPath : battleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,encounterMusicPath: freezed == encounterMusicPath ? _self.encounterMusicPath : encounterMusicPath // ignore: cast_nullable_to_non_nullable
as String?,battleTransitionIds: null == battleTransitionIds ? _self.battleTransitionIds : battleTransitionIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [EncounterZonePayload].
extension EncounterZonePayloadPatterns on EncounterZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EncounterZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EncounterZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EncounterZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _EncounterZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EncounterZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _EncounterZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? encounterTableId,  EncounterKind encounterKind,  String? battleBackgroundRelativePath,  String? battleMusicPath,  String? encounterMusicPath,  List<String> battleTransitionIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EncounterZonePayload() when $default != null:
return $default(_that.encounterTableId,_that.encounterKind,_that.battleBackgroundRelativePath,_that.battleMusicPath,_that.encounterMusicPath,_that.battleTransitionIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? encounterTableId,  EncounterKind encounterKind,  String? battleBackgroundRelativePath,  String? battleMusicPath,  String? encounterMusicPath,  List<String> battleTransitionIds)  $default,) {final _that = this;
switch (_that) {
case _EncounterZonePayload():
return $default(_that.encounterTableId,_that.encounterKind,_that.battleBackgroundRelativePath,_that.battleMusicPath,_that.encounterMusicPath,_that.battleTransitionIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? encounterTableId,  EncounterKind encounterKind,  String? battleBackgroundRelativePath,  String? battleMusicPath,  String? encounterMusicPath,  List<String> battleTransitionIds)?  $default,) {final _that = this;
switch (_that) {
case _EncounterZonePayload() when $default != null:
return $default(_that.encounterTableId,_that.encounterKind,_that.battleBackgroundRelativePath,_that.battleMusicPath,_that.encounterMusicPath,_that.battleTransitionIds);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _EncounterZonePayload implements EncounterZonePayload {
  const _EncounterZonePayload({this.encounterTableId, this.encounterKind = EncounterKind.walk, this.battleBackgroundRelativePath, this.battleMusicPath, this.encounterMusicPath, final  List<String> battleTransitionIds = const <String>[]}): _battleTransitionIds = battleTransitionIds;
  factory _EncounterZonePayload.fromJson(Map<String, dynamic> json) => _$EncounterZonePayloadFromJson(json);

/// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
@override final  String? encounterTableId;
/// Type de rencontre déclenchée dans cette zone.
@override@JsonKey() final  EncounterKind encounterKind;
/// Image de fond de combat authorée explicitement pour cette zone.
///
/// Le chemin reste project-local et optionnel :
/// - aucune bibliothèque média globale n'est introduite ici ;
/// - le runtime pourra l'utiliser comme override visuel du fond contextuel ;
/// - l'absence de valeur garde le comportement contextuel existant.
@override final  String? battleBackgroundRelativePath;
/// Musique des combats déclenchés dans cette zone — BETA-BAT-015.
///
/// Même sémantique que le fond : chemin project-local optionnel. La
/// chaîne runtime la place entre le thème explicite du dresseur et la
/// musique de combat de la carte ; vide = la chaîne continue.
@override final  String? battleMusicPath;
/// Musique de rencontre jouée quand un dresseur repère le joueur dans
/// cette zone — BETA-BAT-015. Gagne sur le défaut projet ; vide = défaut.
@override final  String? encounterMusicPath;
/// Transitions de début de combat de cette zone — BETA-BAT-019.
///
/// Des ids du registre moteur (`battleTransitionRegistry`). Plusieurs
/// valeurs = le runtime en tire une par rencontre (déterministe par
/// requête, donc rejouable). Vide = le défaut projet puis le défaut
/// moteur ; un id inconnu retombe sur le défaut du type sans jamais
/// casser l'entrée en combat.
 final  List<String> _battleTransitionIds;
/// Transitions de début de combat de cette zone — BETA-BAT-019.
///
/// Des ids du registre moteur (`battleTransitionRegistry`). Plusieurs
/// valeurs = le runtime en tire une par rencontre (déterministe par
/// requête, donc rejouable). Vide = le défaut projet puis le défaut
/// moteur ; un id inconnu retombe sur le défaut du type sans jamais
/// casser l'entrée en combat.
@override@JsonKey() List<String> get battleTransitionIds {
  if (_battleTransitionIds is EqualUnmodifiableListView) return _battleTransitionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_battleTransitionIds);
}


/// Create a copy of EncounterZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EncounterZonePayloadCopyWith<_EncounterZonePayload> get copyWith => __$EncounterZonePayloadCopyWithImpl<_EncounterZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EncounterZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EncounterZonePayload&&(identical(other.encounterTableId, encounterTableId) || other.encounterTableId == encounterTableId)&&(identical(other.encounterKind, encounterKind) || other.encounterKind == encounterKind)&&(identical(other.battleBackgroundRelativePath, battleBackgroundRelativePath) || other.battleBackgroundRelativePath == battleBackgroundRelativePath)&&(identical(other.battleMusicPath, battleMusicPath) || other.battleMusicPath == battleMusicPath)&&(identical(other.encounterMusicPath, encounterMusicPath) || other.encounterMusicPath == encounterMusicPath)&&const DeepCollectionEquality().equals(other._battleTransitionIds, _battleTransitionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,encounterTableId,encounterKind,battleBackgroundRelativePath,battleMusicPath,encounterMusicPath,const DeepCollectionEquality().hash(_battleTransitionIds));

@override
String toString() {
  return 'EncounterZonePayload(encounterTableId: $encounterTableId, encounterKind: $encounterKind, battleBackgroundRelativePath: $battleBackgroundRelativePath, battleMusicPath: $battleMusicPath, encounterMusicPath: $encounterMusicPath, battleTransitionIds: $battleTransitionIds)';
}


}

/// @nodoc
abstract mixin class _$EncounterZonePayloadCopyWith<$Res> implements $EncounterZonePayloadCopyWith<$Res> {
  factory _$EncounterZonePayloadCopyWith(_EncounterZonePayload value, $Res Function(_EncounterZonePayload) _then) = __$EncounterZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 String? encounterTableId, EncounterKind encounterKind, String? battleBackgroundRelativePath, String? battleMusicPath, String? encounterMusicPath, List<String> battleTransitionIds
});




}
/// @nodoc
class __$EncounterZonePayloadCopyWithImpl<$Res>
    implements _$EncounterZonePayloadCopyWith<$Res> {
  __$EncounterZonePayloadCopyWithImpl(this._self, this._then);

  final _EncounterZonePayload _self;
  final $Res Function(_EncounterZonePayload) _then;

/// Create a copy of EncounterZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? encounterTableId = freezed,Object? encounterKind = null,Object? battleBackgroundRelativePath = freezed,Object? battleMusicPath = freezed,Object? encounterMusicPath = freezed,Object? battleTransitionIds = null,}) {
  return _then(_EncounterZonePayload(
encounterTableId: freezed == encounterTableId ? _self.encounterTableId : encounterTableId // ignore: cast_nullable_to_non_nullable
as String?,encounterKind: null == encounterKind ? _self.encounterKind : encounterKind // ignore: cast_nullable_to_non_nullable
as EncounterKind,battleBackgroundRelativePath: freezed == battleBackgroundRelativePath ? _self.battleBackgroundRelativePath : battleBackgroundRelativePath // ignore: cast_nullable_to_non_nullable
as String?,battleMusicPath: freezed == battleMusicPath ? _self.battleMusicPath : battleMusicPath // ignore: cast_nullable_to_non_nullable
as String?,encounterMusicPath: freezed == encounterMusicPath ? _self.encounterMusicPath : encounterMusicPath // ignore: cast_nullable_to_non_nullable
as String?,battleTransitionIds: null == battleTransitionIds ? _self._battleTransitionIds : battleTransitionIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$MovementZonePayload {

/// Mode de déplacement requis pour traverser la zone.
 MovementMode get requiredMode;/// Modes supplémentaires autorisés en plus de [requiredMode].
 List<MovementMode> get allowedModes;
/// Create a copy of MovementZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementZonePayloadCopyWith<MovementZonePayload> get copyWith => _$MovementZonePayloadCopyWithImpl<MovementZonePayload>(this as MovementZonePayload, _$identity);

  /// Serializes this MovementZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementZonePayload&&(identical(other.requiredMode, requiredMode) || other.requiredMode == requiredMode)&&const DeepCollectionEquality().equals(other.allowedModes, allowedModes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requiredMode,const DeepCollectionEquality().hash(allowedModes));

@override
String toString() {
  return 'MovementZonePayload(requiredMode: $requiredMode, allowedModes: $allowedModes)';
}


}

/// @nodoc
abstract mixin class $MovementZonePayloadCopyWith<$Res>  {
  factory $MovementZonePayloadCopyWith(MovementZonePayload value, $Res Function(MovementZonePayload) _then) = _$MovementZonePayloadCopyWithImpl;
@useResult
$Res call({
 MovementMode requiredMode, List<MovementMode> allowedModes
});




}
/// @nodoc
class _$MovementZonePayloadCopyWithImpl<$Res>
    implements $MovementZonePayloadCopyWith<$Res> {
  _$MovementZonePayloadCopyWithImpl(this._self, this._then);

  final MovementZonePayload _self;
  final $Res Function(MovementZonePayload) _then;

/// Create a copy of MovementZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requiredMode = null,Object? allowedModes = null,}) {
  return _then(_self.copyWith(
requiredMode: null == requiredMode ? _self.requiredMode : requiredMode // ignore: cast_nullable_to_non_nullable
as MovementMode,allowedModes: null == allowedModes ? _self.allowedModes : allowedModes // ignore: cast_nullable_to_non_nullable
as List<MovementMode>,
  ));
}

}


/// Adds pattern-matching-related methods to [MovementZonePayload].
extension MovementZonePayloadPatterns on MovementZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovementZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovementZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovementZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _MovementZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovementZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _MovementZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MovementMode requiredMode,  List<MovementMode> allowedModes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovementZonePayload() when $default != null:
return $default(_that.requiredMode,_that.allowedModes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MovementMode requiredMode,  List<MovementMode> allowedModes)  $default,) {final _that = this;
switch (_that) {
case _MovementZonePayload():
return $default(_that.requiredMode,_that.allowedModes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MovementMode requiredMode,  List<MovementMode> allowedModes)?  $default,) {final _that = this;
switch (_that) {
case _MovementZonePayload() when $default != null:
return $default(_that.requiredMode,_that.allowedModes);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MovementZonePayload implements MovementZonePayload {
  const _MovementZonePayload({this.requiredMode = MovementMode.walk, final  List<MovementMode> allowedModes = const []}): _allowedModes = allowedModes;
  factory _MovementZonePayload.fromJson(Map<String, dynamic> json) => _$MovementZonePayloadFromJson(json);

/// Mode de déplacement requis pour traverser la zone.
@override@JsonKey() final  MovementMode requiredMode;
/// Modes supplémentaires autorisés en plus de [requiredMode].
 final  List<MovementMode> _allowedModes;
/// Modes supplémentaires autorisés en plus de [requiredMode].
@override@JsonKey() List<MovementMode> get allowedModes {
  if (_allowedModes is EqualUnmodifiableListView) return _allowedModes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allowedModes);
}


/// Create a copy of MovementZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovementZonePayloadCopyWith<_MovementZonePayload> get copyWith => __$MovementZonePayloadCopyWithImpl<_MovementZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MovementZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovementZonePayload&&(identical(other.requiredMode, requiredMode) || other.requiredMode == requiredMode)&&const DeepCollectionEquality().equals(other._allowedModes, _allowedModes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requiredMode,const DeepCollectionEquality().hash(_allowedModes));

@override
String toString() {
  return 'MovementZonePayload(requiredMode: $requiredMode, allowedModes: $allowedModes)';
}


}

/// @nodoc
abstract mixin class _$MovementZonePayloadCopyWith<$Res> implements $MovementZonePayloadCopyWith<$Res> {
  factory _$MovementZonePayloadCopyWith(_MovementZonePayload value, $Res Function(_MovementZonePayload) _then) = __$MovementZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 MovementMode requiredMode, List<MovementMode> allowedModes
});




}
/// @nodoc
class __$MovementZonePayloadCopyWithImpl<$Res>
    implements _$MovementZonePayloadCopyWith<$Res> {
  __$MovementZonePayloadCopyWithImpl(this._self, this._then);

  final _MovementZonePayload _self;
  final $Res Function(_MovementZonePayload) _then;

/// Create a copy of MovementZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requiredMode = null,Object? allowedModes = null,}) {
  return _then(_MovementZonePayload(
requiredMode: null == requiredMode ? _self.requiredMode : requiredMode // ignore: cast_nullable_to_non_nullable
as MovementMode,allowedModes: null == allowedModes ? _self._allowedModes : allowedModes // ignore: cast_nullable_to_non_nullable
as List<MovementMode>,
  ));
}


}


/// @nodoc
mixin _$MovementEffectZonePayload {

 MovementEffectZoneKind get effectKind;/// Coût entier positif pour [MovementEffectZoneKind.movementCost].
///
/// Pour [MovementEffectZoneKind.slide], la valeur est conservée par défaut
/// pour garder un JSON stable, mais elle n'est pas consommée.
 int get movementCost;
/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementEffectZonePayloadCopyWith<MovementEffectZonePayload> get copyWith => _$MovementEffectZonePayloadCopyWithImpl<MovementEffectZonePayload>(this as MovementEffectZonePayload, _$identity);

  /// Serializes this MovementEffectZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementEffectZonePayload&&(identical(other.effectKind, effectKind) || other.effectKind == effectKind)&&(identical(other.movementCost, movementCost) || other.movementCost == movementCost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,effectKind,movementCost);

@override
String toString() {
  return 'MovementEffectZonePayload(effectKind: $effectKind, movementCost: $movementCost)';
}


}

/// @nodoc
abstract mixin class $MovementEffectZonePayloadCopyWith<$Res>  {
  factory $MovementEffectZonePayloadCopyWith(MovementEffectZonePayload value, $Res Function(MovementEffectZonePayload) _then) = _$MovementEffectZonePayloadCopyWithImpl;
@useResult
$Res call({
 MovementEffectZoneKind effectKind, int movementCost
});




}
/// @nodoc
class _$MovementEffectZonePayloadCopyWithImpl<$Res>
    implements $MovementEffectZonePayloadCopyWith<$Res> {
  _$MovementEffectZonePayloadCopyWithImpl(this._self, this._then);

  final MovementEffectZonePayload _self;
  final $Res Function(MovementEffectZonePayload) _then;

/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? effectKind = null,Object? movementCost = null,}) {
  return _then(_self.copyWith(
effectKind: null == effectKind ? _self.effectKind : effectKind // ignore: cast_nullable_to_non_nullable
as MovementEffectZoneKind,movementCost: null == movementCost ? _self.movementCost : movementCost // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MovementEffectZonePayload].
extension MovementEffectZonePayloadPatterns on MovementEffectZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovementEffectZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovementEffectZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovementEffectZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _MovementEffectZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovementEffectZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _MovementEffectZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MovementEffectZoneKind effectKind,  int movementCost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovementEffectZonePayload() when $default != null:
return $default(_that.effectKind,_that.movementCost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MovementEffectZoneKind effectKind,  int movementCost)  $default,) {final _that = this;
switch (_that) {
case _MovementEffectZonePayload():
return $default(_that.effectKind,_that.movementCost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MovementEffectZoneKind effectKind,  int movementCost)?  $default,) {final _that = this;
switch (_that) {
case _MovementEffectZonePayload() when $default != null:
return $default(_that.effectKind,_that.movementCost);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MovementEffectZonePayload implements MovementEffectZonePayload {
  const _MovementEffectZonePayload({this.effectKind = MovementEffectZoneKind.slide, this.movementCost = 1});
  factory _MovementEffectZonePayload.fromJson(Map<String, dynamic> json) => _$MovementEffectZonePayloadFromJson(json);

@override@JsonKey() final  MovementEffectZoneKind effectKind;
/// Coût entier positif pour [MovementEffectZoneKind.movementCost].
///
/// Pour [MovementEffectZoneKind.slide], la valeur est conservée par défaut
/// pour garder un JSON stable, mais elle n'est pas consommée.
@override@JsonKey() final  int movementCost;

/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovementEffectZonePayloadCopyWith<_MovementEffectZonePayload> get copyWith => __$MovementEffectZonePayloadCopyWithImpl<_MovementEffectZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MovementEffectZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovementEffectZonePayload&&(identical(other.effectKind, effectKind) || other.effectKind == effectKind)&&(identical(other.movementCost, movementCost) || other.movementCost == movementCost));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,effectKind,movementCost);

@override
String toString() {
  return 'MovementEffectZonePayload(effectKind: $effectKind, movementCost: $movementCost)';
}


}

/// @nodoc
abstract mixin class _$MovementEffectZonePayloadCopyWith<$Res> implements $MovementEffectZonePayloadCopyWith<$Res> {
  factory _$MovementEffectZonePayloadCopyWith(_MovementEffectZonePayload value, $Res Function(_MovementEffectZonePayload) _then) = __$MovementEffectZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 MovementEffectZoneKind effectKind, int movementCost
});




}
/// @nodoc
class __$MovementEffectZonePayloadCopyWithImpl<$Res>
    implements _$MovementEffectZonePayloadCopyWith<$Res> {
  __$MovementEffectZonePayloadCopyWithImpl(this._self, this._then);

  final _MovementEffectZonePayload _self;
  final $Res Function(_MovementEffectZonePayload) _then;

/// Create a copy of MovementEffectZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? effectKind = null,Object? movementCost = null,}) {
  return _then(_MovementEffectZonePayload(
effectKind: null == effectKind ? _self.effectKind : effectKind // ignore: cast_nullable_to_non_nullable
as MovementEffectZoneKind,movementCost: null == movementCost ? _self.movementCost : movementCost // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$HazardZonePayload {

 HazardKind get hazardKind;/// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
 int get damagePerStep;
/// Create a copy of HazardZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HazardZonePayloadCopyWith<HazardZonePayload> get copyWith => _$HazardZonePayloadCopyWithImpl<HazardZonePayload>(this as HazardZonePayload, _$identity);

  /// Serializes this HazardZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HazardZonePayload&&(identical(other.hazardKind, hazardKind) || other.hazardKind == hazardKind)&&(identical(other.damagePerStep, damagePerStep) || other.damagePerStep == damagePerStep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hazardKind,damagePerStep);

@override
String toString() {
  return 'HazardZonePayload(hazardKind: $hazardKind, damagePerStep: $damagePerStep)';
}


}

/// @nodoc
abstract mixin class $HazardZonePayloadCopyWith<$Res>  {
  factory $HazardZonePayloadCopyWith(HazardZonePayload value, $Res Function(HazardZonePayload) _then) = _$HazardZonePayloadCopyWithImpl;
@useResult
$Res call({
 HazardKind hazardKind, int damagePerStep
});




}
/// @nodoc
class _$HazardZonePayloadCopyWithImpl<$Res>
    implements $HazardZonePayloadCopyWith<$Res> {
  _$HazardZonePayloadCopyWithImpl(this._self, this._then);

  final HazardZonePayload _self;
  final $Res Function(HazardZonePayload) _then;

/// Create a copy of HazardZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hazardKind = null,Object? damagePerStep = null,}) {
  return _then(_self.copyWith(
hazardKind: null == hazardKind ? _self.hazardKind : hazardKind // ignore: cast_nullable_to_non_nullable
as HazardKind,damagePerStep: null == damagePerStep ? _self.damagePerStep : damagePerStep // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HazardZonePayload].
extension HazardZonePayloadPatterns on HazardZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HazardZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HazardZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HazardZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _HazardZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HazardZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _HazardZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HazardKind hazardKind,  int damagePerStep)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HazardZonePayload() when $default != null:
return $default(_that.hazardKind,_that.damagePerStep);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HazardKind hazardKind,  int damagePerStep)  $default,) {final _that = this;
switch (_that) {
case _HazardZonePayload():
return $default(_that.hazardKind,_that.damagePerStep);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HazardKind hazardKind,  int damagePerStep)?  $default,) {final _that = this;
switch (_that) {
case _HazardZonePayload() when $default != null:
return $default(_that.hazardKind,_that.damagePerStep);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _HazardZonePayload implements HazardZonePayload {
  const _HazardZonePayload({this.hazardKind = HazardKind.other, this.damagePerStep = 0});
  factory _HazardZonePayload.fromJson(Map<String, dynamic> json) => _$HazardZonePayloadFromJson(json);

@override@JsonKey() final  HazardKind hazardKind;
/// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
@override@JsonKey() final  int damagePerStep;

/// Create a copy of HazardZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HazardZonePayloadCopyWith<_HazardZonePayload> get copyWith => __$HazardZonePayloadCopyWithImpl<_HazardZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HazardZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HazardZonePayload&&(identical(other.hazardKind, hazardKind) || other.hazardKind == hazardKind)&&(identical(other.damagePerStep, damagePerStep) || other.damagePerStep == damagePerStep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hazardKind,damagePerStep);

@override
String toString() {
  return 'HazardZonePayload(hazardKind: $hazardKind, damagePerStep: $damagePerStep)';
}


}

/// @nodoc
abstract mixin class _$HazardZonePayloadCopyWith<$Res> implements $HazardZonePayloadCopyWith<$Res> {
  factory _$HazardZonePayloadCopyWith(_HazardZonePayload value, $Res Function(_HazardZonePayload) _then) = __$HazardZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 HazardKind hazardKind, int damagePerStep
});




}
/// @nodoc
class __$HazardZonePayloadCopyWithImpl<$Res>
    implements _$HazardZonePayloadCopyWith<$Res> {
  __$HazardZonePayloadCopyWithImpl(this._self, this._then);

  final _HazardZonePayload _self;
  final $Res Function(_HazardZonePayload) _then;

/// Create a copy of HazardZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hazardKind = null,Object? damagePerStep = null,}) {
  return _then(_HazardZonePayload(
hazardKind: null == hazardKind ? _self.hazardKind : hazardKind // ignore: cast_nullable_to_non_nullable
as HazardKind,damagePerStep: null == damagePerStep ? _self.damagePerStep : damagePerStep // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SpecialZonePayload {

/// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
 String? get scriptKey;/// Propriétés libres (clé → valeur).
 Map<String, String> get properties;
/// Create a copy of SpecialZonePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpecialZonePayloadCopyWith<SpecialZonePayload> get copyWith => _$SpecialZonePayloadCopyWithImpl<SpecialZonePayload>(this as SpecialZonePayload, _$identity);

  /// Serializes this SpecialZonePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpecialZonePayload&&(identical(other.scriptKey, scriptKey) || other.scriptKey == scriptKey)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scriptKey,const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'SpecialZonePayload(scriptKey: $scriptKey, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $SpecialZonePayloadCopyWith<$Res>  {
  factory $SpecialZonePayloadCopyWith(SpecialZonePayload value, $Res Function(SpecialZonePayload) _then) = _$SpecialZonePayloadCopyWithImpl;
@useResult
$Res call({
 String? scriptKey, Map<String, String> properties
});




}
/// @nodoc
class _$SpecialZonePayloadCopyWithImpl<$Res>
    implements $SpecialZonePayloadCopyWith<$Res> {
  _$SpecialZonePayloadCopyWithImpl(this._self, this._then);

  final SpecialZonePayload _self;
  final $Res Function(SpecialZonePayload) _then;

/// Create a copy of SpecialZonePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scriptKey = freezed,Object? properties = null,}) {
  return _then(_self.copyWith(
scriptKey: freezed == scriptKey ? _self.scriptKey : scriptKey // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [SpecialZonePayload].
extension SpecialZonePayloadPatterns on SpecialZonePayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpecialZonePayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpecialZonePayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpecialZonePayload value)  $default,){
final _that = this;
switch (_that) {
case _SpecialZonePayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpecialZonePayload value)?  $default,){
final _that = this;
switch (_that) {
case _SpecialZonePayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? scriptKey,  Map<String, String> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpecialZonePayload() when $default != null:
return $default(_that.scriptKey,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? scriptKey,  Map<String, String> properties)  $default,) {final _that = this;
switch (_that) {
case _SpecialZonePayload():
return $default(_that.scriptKey,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? scriptKey,  Map<String, String> properties)?  $default,) {final _that = this;
switch (_that) {
case _SpecialZonePayload() when $default != null:
return $default(_that.scriptKey,_that.properties);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SpecialZonePayload implements SpecialZonePayload {
  const _SpecialZonePayload({this.scriptKey, final  Map<String, String> properties = const {}}): _properties = properties;
  factory _SpecialZonePayload.fromJson(Map<String, dynamic> json) => _$SpecialZonePayloadFromJson(json);

/// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
@override final  String? scriptKey;
/// Propriétés libres (clé → valeur).
 final  Map<String, String> _properties;
/// Propriétés libres (clé → valeur).
@override@JsonKey() Map<String, String> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of SpecialZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpecialZonePayloadCopyWith<_SpecialZonePayload> get copyWith => __$SpecialZonePayloadCopyWithImpl<_SpecialZonePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpecialZonePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpecialZonePayload&&(identical(other.scriptKey, scriptKey) || other.scriptKey == scriptKey)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scriptKey,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'SpecialZonePayload(scriptKey: $scriptKey, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$SpecialZonePayloadCopyWith<$Res> implements $SpecialZonePayloadCopyWith<$Res> {
  factory _$SpecialZonePayloadCopyWith(_SpecialZonePayload value, $Res Function(_SpecialZonePayload) _then) = __$SpecialZonePayloadCopyWithImpl;
@override @useResult
$Res call({
 String? scriptKey, Map<String, String> properties
});




}
/// @nodoc
class __$SpecialZonePayloadCopyWithImpl<$Res>
    implements _$SpecialZonePayloadCopyWith<$Res> {
  __$SpecialZonePayloadCopyWithImpl(this._self, this._then);

  final _SpecialZonePayload _self;
  final $Res Function(_SpecialZonePayload) _then;

/// Create a copy of SpecialZonePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scriptKey = freezed,Object? properties = null,}) {
  return _then(_SpecialZonePayload(
scriptKey: freezed == scriptKey ? _self.scriptKey : scriptKey // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
