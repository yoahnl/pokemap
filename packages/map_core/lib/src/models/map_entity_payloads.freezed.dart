// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_entity_payloads.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DialogueRef {

/// Identifiant stable : typiquement [ProjectDialogueEntry.id] lorsque [scriptPathRelative] est vide.
 String get dialogueId;/// Vide = résolution via le registre projet ; non vide = script explicite (legacy ou override).
 String get scriptPathRelative;/// Nœud d’entrée optionnel (ex. titre de nœud Yarn).
 String? get startNode;
/// Create a copy of DialogueRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<DialogueRef> get copyWith => _$DialogueRefCopyWithImpl<DialogueRef>(this as DialogueRef, _$identity);

  /// Serializes this DialogueRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DialogueRef&&(identical(other.dialogueId, dialogueId) || other.dialogueId == dialogueId)&&(identical(other.scriptPathRelative, scriptPathRelative) || other.scriptPathRelative == scriptPathRelative)&&(identical(other.startNode, startNode) || other.startNode == startNode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dialogueId,scriptPathRelative,startNode);

@override
String toString() {
  return 'DialogueRef(dialogueId: $dialogueId, scriptPathRelative: $scriptPathRelative, startNode: $startNode)';
}


}

/// @nodoc
abstract mixin class $DialogueRefCopyWith<$Res>  {
  factory $DialogueRefCopyWith(DialogueRef value, $Res Function(DialogueRef) _then) = _$DialogueRefCopyWithImpl;
@useResult
$Res call({
 String dialogueId, String scriptPathRelative, String? startNode
});




}
/// @nodoc
class _$DialogueRefCopyWithImpl<$Res>
    implements $DialogueRefCopyWith<$Res> {
  _$DialogueRefCopyWithImpl(this._self, this._then);

  final DialogueRef _self;
  final $Res Function(DialogueRef) _then;

/// Create a copy of DialogueRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dialogueId = null,Object? scriptPathRelative = null,Object? startNode = freezed,}) {
  return _then(_self.copyWith(
dialogueId: null == dialogueId ? _self.dialogueId : dialogueId // ignore: cast_nullable_to_non_nullable
as String,scriptPathRelative: null == scriptPathRelative ? _self.scriptPathRelative : scriptPathRelative // ignore: cast_nullable_to_non_nullable
as String,startNode: freezed == startNode ? _self.startNode : startNode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DialogueRef].
extension DialogueRefPatterns on DialogueRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DialogueRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DialogueRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DialogueRef value)  $default,){
final _that = this;
switch (_that) {
case _DialogueRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DialogueRef value)?  $default,){
final _that = this;
switch (_that) {
case _DialogueRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String dialogueId,  String scriptPathRelative,  String? startNode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DialogueRef() when $default != null:
return $default(_that.dialogueId,_that.scriptPathRelative,_that.startNode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String dialogueId,  String scriptPathRelative,  String? startNode)  $default,) {final _that = this;
switch (_that) {
case _DialogueRef():
return $default(_that.dialogueId,_that.scriptPathRelative,_that.startNode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String dialogueId,  String scriptPathRelative,  String? startNode)?  $default,) {final _that = this;
switch (_that) {
case _DialogueRef() when $default != null:
return $default(_that.dialogueId,_that.scriptPathRelative,_that.startNode);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _DialogueRef implements DialogueRef {
  const _DialogueRef({required this.dialogueId, this.scriptPathRelative = '', this.startNode});
  factory _DialogueRef.fromJson(Map<String, dynamic> json) => _$DialogueRefFromJson(json);

/// Identifiant stable : typiquement [ProjectDialogueEntry.id] lorsque [scriptPathRelative] est vide.
@override final  String dialogueId;
/// Vide = résolution via le registre projet ; non vide = script explicite (legacy ou override).
@override@JsonKey() final  String scriptPathRelative;
/// Nœud d’entrée optionnel (ex. titre de nœud Yarn).
@override final  String? startNode;

/// Create a copy of DialogueRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DialogueRefCopyWith<_DialogueRef> get copyWith => __$DialogueRefCopyWithImpl<_DialogueRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DialogueRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DialogueRef&&(identical(other.dialogueId, dialogueId) || other.dialogueId == dialogueId)&&(identical(other.scriptPathRelative, scriptPathRelative) || other.scriptPathRelative == scriptPathRelative)&&(identical(other.startNode, startNode) || other.startNode == startNode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dialogueId,scriptPathRelative,startNode);

@override
String toString() {
  return 'DialogueRef(dialogueId: $dialogueId, scriptPathRelative: $scriptPathRelative, startNode: $startNode)';
}


}

/// @nodoc
abstract mixin class _$DialogueRefCopyWith<$Res> implements $DialogueRefCopyWith<$Res> {
  factory _$DialogueRefCopyWith(_DialogueRef value, $Res Function(_DialogueRef) _then) = __$DialogueRefCopyWithImpl;
@override @useResult
$Res call({
 String dialogueId, String scriptPathRelative, String? startNode
});




}
/// @nodoc
class __$DialogueRefCopyWithImpl<$Res>
    implements _$DialogueRefCopyWith<$Res> {
  __$DialogueRefCopyWithImpl(this._self, this._then);

  final _DialogueRef _self;
  final $Res Function(_DialogueRef) _then;

/// Create a copy of DialogueRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dialogueId = null,Object? scriptPathRelative = null,Object? startNode = freezed,}) {
  return _then(_DialogueRef(
dialogueId: null == dialogueId ? _self.dialogueId : dialogueId // ignore: cast_nullable_to_non_nullable
as String,scriptPathRelative: null == scriptPathRelative ? _self.scriptPathRelative : scriptPathRelative // ignore: cast_nullable_to_non_nullable
as String,startNode: freezed == startNode ? _self.startNode : startNode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MapEntityRuntimePredicate {

 MapEntityRuntimePredicateKind get kind;/// Id métier selon [kind] : nom de flag, id de step, id de chapitre,
/// id de scénario local (cutscene).
 String get refId;
/// Create a copy of MapEntityRuntimePredicate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntityRuntimePredicateCopyWith<MapEntityRuntimePredicate> get copyWith => _$MapEntityRuntimePredicateCopyWithImpl<MapEntityRuntimePredicate>(this as MapEntityRuntimePredicate, _$identity);

  /// Serializes this MapEntityRuntimePredicate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntityRuntimePredicate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.refId, refId) || other.refId == refId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,refId);

@override
String toString() {
  return 'MapEntityRuntimePredicate(kind: $kind, refId: $refId)';
}


}

/// @nodoc
abstract mixin class $MapEntityRuntimePredicateCopyWith<$Res>  {
  factory $MapEntityRuntimePredicateCopyWith(MapEntityRuntimePredicate value, $Res Function(MapEntityRuntimePredicate) _then) = _$MapEntityRuntimePredicateCopyWithImpl;
@useResult
$Res call({
 MapEntityRuntimePredicateKind kind, String refId
});




}
/// @nodoc
class _$MapEntityRuntimePredicateCopyWithImpl<$Res>
    implements $MapEntityRuntimePredicateCopyWith<$Res> {
  _$MapEntityRuntimePredicateCopyWithImpl(this._self, this._then);

  final MapEntityRuntimePredicate _self;
  final $Res Function(MapEntityRuntimePredicate) _then;

/// Create a copy of MapEntityRuntimePredicate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? refId = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MapEntityRuntimePredicateKind,refId: null == refId ? _self.refId : refId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MapEntityRuntimePredicate].
extension MapEntityRuntimePredicatePatterns on MapEntityRuntimePredicate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntityRuntimePredicate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntityRuntimePredicate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntityRuntimePredicate value)  $default,){
final _that = this;
switch (_that) {
case _MapEntityRuntimePredicate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntityRuntimePredicate value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntityRuntimePredicate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MapEntityRuntimePredicateKind kind,  String refId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntityRuntimePredicate() when $default != null:
return $default(_that.kind,_that.refId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MapEntityRuntimePredicateKind kind,  String refId)  $default,) {final _that = this;
switch (_that) {
case _MapEntityRuntimePredicate():
return $default(_that.kind,_that.refId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MapEntityRuntimePredicateKind kind,  String refId)?  $default,) {final _that = this;
switch (_that) {
case _MapEntityRuntimePredicate() when $default != null:
return $default(_that.kind,_that.refId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntityRuntimePredicate implements MapEntityRuntimePredicate {
  const _MapEntityRuntimePredicate({required this.kind, this.refId = ''});
  factory _MapEntityRuntimePredicate.fromJson(Map<String, dynamic> json) => _$MapEntityRuntimePredicateFromJson(json);

@override final  MapEntityRuntimePredicateKind kind;
/// Id métier selon [kind] : nom de flag, id de step, id de chapitre,
/// id de scénario local (cutscene).
@override@JsonKey() final  String refId;

/// Create a copy of MapEntityRuntimePredicate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntityRuntimePredicateCopyWith<_MapEntityRuntimePredicate> get copyWith => __$MapEntityRuntimePredicateCopyWithImpl<_MapEntityRuntimePredicate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntityRuntimePredicateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntityRuntimePredicate&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.refId, refId) || other.refId == refId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,refId);

@override
String toString() {
  return 'MapEntityRuntimePredicate(kind: $kind, refId: $refId)';
}


}

/// @nodoc
abstract mixin class _$MapEntityRuntimePredicateCopyWith<$Res> implements $MapEntityRuntimePredicateCopyWith<$Res> {
  factory _$MapEntityRuntimePredicateCopyWith(_MapEntityRuntimePredicate value, $Res Function(_MapEntityRuntimePredicate) _then) = __$MapEntityRuntimePredicateCopyWithImpl;
@override @useResult
$Res call({
 MapEntityRuntimePredicateKind kind, String refId
});




}
/// @nodoc
class __$MapEntityRuntimePredicateCopyWithImpl<$Res>
    implements _$MapEntityRuntimePredicateCopyWith<$Res> {
  __$MapEntityRuntimePredicateCopyWithImpl(this._self, this._then);

  final _MapEntityRuntimePredicate _self;
  final $Res Function(_MapEntityRuntimePredicate) _then;

/// Create a copy of MapEntityRuntimePredicate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? refId = null,}) {
  return _then(_MapEntityRuntimePredicate(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MapEntityRuntimePredicateKind,refId: null == refId ? _self.refId : refId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MapEntityNpcVisibilityRule {

 MapEntityNpcVisibilityMode get mode; MapEntityRuntimePredicate? get predicate;
/// Create a copy of MapEntityNpcVisibilityRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntityNpcVisibilityRuleCopyWith<MapEntityNpcVisibilityRule> get copyWith => _$MapEntityNpcVisibilityRuleCopyWithImpl<MapEntityNpcVisibilityRule>(this as MapEntityNpcVisibilityRule, _$identity);

  /// Serializes this MapEntityNpcVisibilityRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntityNpcVisibilityRule&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.predicate, predicate) || other.predicate == predicate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,predicate);

@override
String toString() {
  return 'MapEntityNpcVisibilityRule(mode: $mode, predicate: $predicate)';
}


}

/// @nodoc
abstract mixin class $MapEntityNpcVisibilityRuleCopyWith<$Res>  {
  factory $MapEntityNpcVisibilityRuleCopyWith(MapEntityNpcVisibilityRule value, $Res Function(MapEntityNpcVisibilityRule) _then) = _$MapEntityNpcVisibilityRuleCopyWithImpl;
@useResult
$Res call({
 MapEntityNpcVisibilityMode mode, MapEntityRuntimePredicate? predicate
});


$MapEntityRuntimePredicateCopyWith<$Res>? get predicate;

}
/// @nodoc
class _$MapEntityNpcVisibilityRuleCopyWithImpl<$Res>
    implements $MapEntityNpcVisibilityRuleCopyWith<$Res> {
  _$MapEntityNpcVisibilityRuleCopyWithImpl(this._self, this._then);

  final MapEntityNpcVisibilityRule _self;
  final $Res Function(MapEntityNpcVisibilityRule) _then;

/// Create a copy of MapEntityNpcVisibilityRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? predicate = freezed,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MapEntityNpcVisibilityMode,predicate: freezed == predicate ? _self.predicate : predicate // ignore: cast_nullable_to_non_nullable
as MapEntityRuntimePredicate?,
  ));
}
/// Create a copy of MapEntityNpcVisibilityRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityRuntimePredicateCopyWith<$Res>? get predicate {
    if (_self.predicate == null) {
    return null;
  }

  return $MapEntityRuntimePredicateCopyWith<$Res>(_self.predicate!, (value) {
    return _then(_self.copyWith(predicate: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapEntityNpcVisibilityRule].
extension MapEntityNpcVisibilityRulePatterns on MapEntityNpcVisibilityRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntityNpcVisibilityRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntityNpcVisibilityRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntityNpcVisibilityRule value)  $default,){
final _that = this;
switch (_that) {
case _MapEntityNpcVisibilityRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntityNpcVisibilityRule value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntityNpcVisibilityRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MapEntityNpcVisibilityMode mode,  MapEntityRuntimePredicate? predicate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntityNpcVisibilityRule() when $default != null:
return $default(_that.mode,_that.predicate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MapEntityNpcVisibilityMode mode,  MapEntityRuntimePredicate? predicate)  $default,) {final _that = this;
switch (_that) {
case _MapEntityNpcVisibilityRule():
return $default(_that.mode,_that.predicate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MapEntityNpcVisibilityMode mode,  MapEntityRuntimePredicate? predicate)?  $default,) {final _that = this;
switch (_that) {
case _MapEntityNpcVisibilityRule() when $default != null:
return $default(_that.mode,_that.predicate);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntityNpcVisibilityRule implements MapEntityNpcVisibilityRule {
  const _MapEntityNpcVisibilityRule({required this.mode, this.predicate});
  factory _MapEntityNpcVisibilityRule.fromJson(Map<String, dynamic> json) => _$MapEntityNpcVisibilityRuleFromJson(json);

@override final  MapEntityNpcVisibilityMode mode;
@override final  MapEntityRuntimePredicate? predicate;

/// Create a copy of MapEntityNpcVisibilityRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntityNpcVisibilityRuleCopyWith<_MapEntityNpcVisibilityRule> get copyWith => __$MapEntityNpcVisibilityRuleCopyWithImpl<_MapEntityNpcVisibilityRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntityNpcVisibilityRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntityNpcVisibilityRule&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.predicate, predicate) || other.predicate == predicate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,predicate);

@override
String toString() {
  return 'MapEntityNpcVisibilityRule(mode: $mode, predicate: $predicate)';
}


}

/// @nodoc
abstract mixin class _$MapEntityNpcVisibilityRuleCopyWith<$Res> implements $MapEntityNpcVisibilityRuleCopyWith<$Res> {
  factory _$MapEntityNpcVisibilityRuleCopyWith(_MapEntityNpcVisibilityRule value, $Res Function(_MapEntityNpcVisibilityRule) _then) = __$MapEntityNpcVisibilityRuleCopyWithImpl;
@override @useResult
$Res call({
 MapEntityNpcVisibilityMode mode, MapEntityRuntimePredicate? predicate
});


@override $MapEntityRuntimePredicateCopyWith<$Res>? get predicate;

}
/// @nodoc
class __$MapEntityNpcVisibilityRuleCopyWithImpl<$Res>
    implements _$MapEntityNpcVisibilityRuleCopyWith<$Res> {
  __$MapEntityNpcVisibilityRuleCopyWithImpl(this._self, this._then);

  final _MapEntityNpcVisibilityRule _self;
  final $Res Function(_MapEntityNpcVisibilityRule) _then;

/// Create a copy of MapEntityNpcVisibilityRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? predicate = freezed,}) {
  return _then(_MapEntityNpcVisibilityRule(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MapEntityNpcVisibilityMode,predicate: freezed == predicate ? _self.predicate : predicate // ignore: cast_nullable_to_non_nullable
as MapEntityRuntimePredicate?,
  ));
}

/// Create a copy of MapEntityNpcVisibilityRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityRuntimePredicateCopyWith<$Res>? get predicate {
    if (_self.predicate == null) {
    return null;
  }

  return $MapEntityRuntimePredicateCopyWith<$Res>(_self.predicate!, (value) {
    return _then(_self.copyWith(predicate: value));
  });
}
}


/// @nodoc
mixin _$MapEntityConditionalDialogue {

 MapEntityRuntimePredicate get when; DialogueRef get dialogue;
/// Create a copy of MapEntityConditionalDialogue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntityConditionalDialogueCopyWith<MapEntityConditionalDialogue> get copyWith => _$MapEntityConditionalDialogueCopyWithImpl<MapEntityConditionalDialogue>(this as MapEntityConditionalDialogue, _$identity);

  /// Serializes this MapEntityConditionalDialogue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntityConditionalDialogue&&(identical(other.when, when) || other.when == when)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,when,dialogue);

@override
String toString() {
  return 'MapEntityConditionalDialogue(when: $when, dialogue: $dialogue)';
}


}

/// @nodoc
abstract mixin class $MapEntityConditionalDialogueCopyWith<$Res>  {
  factory $MapEntityConditionalDialogueCopyWith(MapEntityConditionalDialogue value, $Res Function(MapEntityConditionalDialogue) _then) = _$MapEntityConditionalDialogueCopyWithImpl;
@useResult
$Res call({
 MapEntityRuntimePredicate when, DialogueRef dialogue
});


$MapEntityRuntimePredicateCopyWith<$Res> get when;$DialogueRefCopyWith<$Res> get dialogue;

}
/// @nodoc
class _$MapEntityConditionalDialogueCopyWithImpl<$Res>
    implements $MapEntityConditionalDialogueCopyWith<$Res> {
  _$MapEntityConditionalDialogueCopyWithImpl(this._self, this._then);

  final MapEntityConditionalDialogue _self;
  final $Res Function(MapEntityConditionalDialogue) _then;

/// Create a copy of MapEntityConditionalDialogue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? when = null,Object? dialogue = null,}) {
  return _then(_self.copyWith(
when: null == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as MapEntityRuntimePredicate,dialogue: null == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as DialogueRef,
  ));
}
/// Create a copy of MapEntityConditionalDialogue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityRuntimePredicateCopyWith<$Res> get when {

  return $MapEntityRuntimePredicateCopyWith<$Res>(_self.when, (value) {
    return _then(_self.copyWith(when: value));
  });
}/// Create a copy of MapEntityConditionalDialogue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res> get dialogue {

  return $DialogueRefCopyWith<$Res>(_self.dialogue, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapEntityConditionalDialogue].
extension MapEntityConditionalDialoguePatterns on MapEntityConditionalDialogue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntityConditionalDialogue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntityConditionalDialogue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntityConditionalDialogue value)  $default,){
final _that = this;
switch (_that) {
case _MapEntityConditionalDialogue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntityConditionalDialogue value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntityConditionalDialogue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MapEntityRuntimePredicate when,  DialogueRef dialogue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntityConditionalDialogue() when $default != null:
return $default(_that.when,_that.dialogue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MapEntityRuntimePredicate when,  DialogueRef dialogue)  $default,) {final _that = this;
switch (_that) {
case _MapEntityConditionalDialogue():
return $default(_that.when,_that.dialogue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MapEntityRuntimePredicate when,  DialogueRef dialogue)?  $default,) {final _that = this;
switch (_that) {
case _MapEntityConditionalDialogue() when $default != null:
return $default(_that.when,_that.dialogue);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntityConditionalDialogue implements MapEntityConditionalDialogue {
  const _MapEntityConditionalDialogue({required this.when, required this.dialogue});
  factory _MapEntityConditionalDialogue.fromJson(Map<String, dynamic> json) => _$MapEntityConditionalDialogueFromJson(json);

@override final  MapEntityRuntimePredicate when;
@override final  DialogueRef dialogue;

/// Create a copy of MapEntityConditionalDialogue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntityConditionalDialogueCopyWith<_MapEntityConditionalDialogue> get copyWith => __$MapEntityConditionalDialogueCopyWithImpl<_MapEntityConditionalDialogue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntityConditionalDialogueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntityConditionalDialogue&&(identical(other.when, when) || other.when == when)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,when,dialogue);

@override
String toString() {
  return 'MapEntityConditionalDialogue(when: $when, dialogue: $dialogue)';
}


}

/// @nodoc
abstract mixin class _$MapEntityConditionalDialogueCopyWith<$Res> implements $MapEntityConditionalDialogueCopyWith<$Res> {
  factory _$MapEntityConditionalDialogueCopyWith(_MapEntityConditionalDialogue value, $Res Function(_MapEntityConditionalDialogue) _then) = __$MapEntityConditionalDialogueCopyWithImpl;
@override @useResult
$Res call({
 MapEntityRuntimePredicate when, DialogueRef dialogue
});


@override $MapEntityRuntimePredicateCopyWith<$Res> get when;@override $DialogueRefCopyWith<$Res> get dialogue;

}
/// @nodoc
class __$MapEntityConditionalDialogueCopyWithImpl<$Res>
    implements _$MapEntityConditionalDialogueCopyWith<$Res> {
  __$MapEntityConditionalDialogueCopyWithImpl(this._self, this._then);

  final _MapEntityConditionalDialogue _self;
  final $Res Function(_MapEntityConditionalDialogue) _then;

/// Create a copy of MapEntityConditionalDialogue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? when = null,Object? dialogue = null,}) {
  return _then(_MapEntityConditionalDialogue(
when: null == when ? _self.when : when // ignore: cast_nullable_to_non_nullable
as MapEntityRuntimePredicate,dialogue: null == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as DialogueRef,
  ));
}

/// Create a copy of MapEntityConditionalDialogue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityRuntimePredicateCopyWith<$Res> get when {

  return $MapEntityRuntimePredicateCopyWith<$Res>(_self.when, (value) {
    return _then(_self.copyWith(when: value));
  });
}/// Create a copy of MapEntityConditionalDialogue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res> get dialogue {

  return $DialogueRefCopyWith<$Res>(_self.dialogue, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}
}


/// @nodoc
mixin _$MapEntityNpcData {

 String get displayName; DialogueRef? get dialogue; EntityFacing get facing; String get visualElementId; String? get trainerId; int get lineOfSightRange; DialogueRef? get defeatDialogueRef; String? get characterId; MapEntityNpcMovementConfig get movement;/// `null` ou mode [MapEntityNpcVisibilityMode.always] = toujours visible.
 MapEntityNpcVisibilityRule? get visibilityRule;/// Variantes testées **dans l’ordre** avant [dialogue] par défaut.
 List<MapEntityConditionalDialogue> get conditionalDialogues;
/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntityNpcDataCopyWith<MapEntityNpcData> get copyWith => _$MapEntityNpcDataCopyWithImpl<MapEntityNpcData>(this as MapEntityNpcData, _$identity);

  /// Serializes this MapEntityNpcData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntityNpcData&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.facing, facing) || other.facing == facing)&&(identical(other.visualElementId, visualElementId) || other.visualElementId == visualElementId)&&(identical(other.trainerId, trainerId) || other.trainerId == trainerId)&&(identical(other.lineOfSightRange, lineOfSightRange) || other.lineOfSightRange == lineOfSightRange)&&(identical(other.defeatDialogueRef, defeatDialogueRef) || other.defeatDialogueRef == defeatDialogueRef)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.movement, movement) || other.movement == movement)&&(identical(other.visibilityRule, visibilityRule) || other.visibilityRule == visibilityRule)&&const DeepCollectionEquality().equals(other.conditionalDialogues, conditionalDialogues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,dialogue,facing,visualElementId,trainerId,lineOfSightRange,defeatDialogueRef,characterId,movement,visibilityRule,const DeepCollectionEquality().hash(conditionalDialogues));

@override
String toString() {
  return 'MapEntityNpcData(displayName: $displayName, dialogue: $dialogue, facing: $facing, visualElementId: $visualElementId, trainerId: $trainerId, lineOfSightRange: $lineOfSightRange, defeatDialogueRef: $defeatDialogueRef, characterId: $characterId, movement: $movement, visibilityRule: $visibilityRule, conditionalDialogues: $conditionalDialogues)';
}


}

/// @nodoc
abstract mixin class $MapEntityNpcDataCopyWith<$Res>  {
  factory $MapEntityNpcDataCopyWith(MapEntityNpcData value, $Res Function(MapEntityNpcData) _then) = _$MapEntityNpcDataCopyWithImpl;
@useResult
$Res call({
 String displayName, DialogueRef? dialogue, EntityFacing facing, String visualElementId, String? trainerId, int lineOfSightRange, DialogueRef? defeatDialogueRef, String? characterId, MapEntityNpcMovementConfig movement, MapEntityNpcVisibilityRule? visibilityRule, List<MapEntityConditionalDialogue> conditionalDialogues
});


$DialogueRefCopyWith<$Res>? get dialogue;$DialogueRefCopyWith<$Res>? get defeatDialogueRef;$MapEntityNpcMovementConfigCopyWith<$Res> get movement;$MapEntityNpcVisibilityRuleCopyWith<$Res>? get visibilityRule;

}
/// @nodoc
class _$MapEntityNpcDataCopyWithImpl<$Res>
    implements $MapEntityNpcDataCopyWith<$Res> {
  _$MapEntityNpcDataCopyWithImpl(this._self, this._then);

  final MapEntityNpcData _self;
  final $Res Function(MapEntityNpcData) _then;

/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? dialogue = freezed,Object? facing = null,Object? visualElementId = null,Object? trainerId = freezed,Object? lineOfSightRange = null,Object? defeatDialogueRef = freezed,Object? characterId = freezed,Object? movement = null,Object? visibilityRule = freezed,Object? conditionalDialogues = null,}) {
  return _then(_self.copyWith(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,dialogue: freezed == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as DialogueRef?,facing: null == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as EntityFacing,visualElementId: null == visualElementId ? _self.visualElementId : visualElementId // ignore: cast_nullable_to_non_nullable
as String,trainerId: freezed == trainerId ? _self.trainerId : trainerId // ignore: cast_nullable_to_non_nullable
as String?,lineOfSightRange: null == lineOfSightRange ? _self.lineOfSightRange : lineOfSightRange // ignore: cast_nullable_to_non_nullable
as int,defeatDialogueRef: freezed == defeatDialogueRef ? _self.defeatDialogueRef : defeatDialogueRef // ignore: cast_nullable_to_non_nullable
as DialogueRef?,characterId: freezed == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String?,movement: null == movement ? _self.movement : movement // ignore: cast_nullable_to_non_nullable
as MapEntityNpcMovementConfig,visibilityRule: freezed == visibilityRule ? _self.visibilityRule : visibilityRule // ignore: cast_nullable_to_non_nullable
as MapEntityNpcVisibilityRule?,conditionalDialogues: null == conditionalDialogues ? _self.conditionalDialogues : conditionalDialogues // ignore: cast_nullable_to_non_nullable
as List<MapEntityConditionalDialogue>,
  ));
}
/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res>? get dialogue {
    if (_self.dialogue == null) {
    return null;
  }

  return $DialogueRefCopyWith<$Res>(_self.dialogue!, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res>? get defeatDialogueRef {
    if (_self.defeatDialogueRef == null) {
    return null;
  }

  return $DialogueRefCopyWith<$Res>(_self.defeatDialogueRef!, (value) {
    return _then(_self.copyWith(defeatDialogueRef: value));
  });
}/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityNpcMovementConfigCopyWith<$Res> get movement {

  return $MapEntityNpcMovementConfigCopyWith<$Res>(_self.movement, (value) {
    return _then(_self.copyWith(movement: value));
  });
}/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityNpcVisibilityRuleCopyWith<$Res>? get visibilityRule {
    if (_self.visibilityRule == null) {
    return null;
  }

  return $MapEntityNpcVisibilityRuleCopyWith<$Res>(_self.visibilityRule!, (value) {
    return _then(_self.copyWith(visibilityRule: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapEntityNpcData].
extension MapEntityNpcDataPatterns on MapEntityNpcData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntityNpcData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntityNpcData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntityNpcData value)  $default,){
final _that = this;
switch (_that) {
case _MapEntityNpcData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntityNpcData value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntityNpcData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  DialogueRef? dialogue,  EntityFacing facing,  String visualElementId,  String? trainerId,  int lineOfSightRange,  DialogueRef? defeatDialogueRef,  String? characterId,  MapEntityNpcMovementConfig movement,  MapEntityNpcVisibilityRule? visibilityRule,  List<MapEntityConditionalDialogue> conditionalDialogues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntityNpcData() when $default != null:
return $default(_that.displayName,_that.dialogue,_that.facing,_that.visualElementId,_that.trainerId,_that.lineOfSightRange,_that.defeatDialogueRef,_that.characterId,_that.movement,_that.visibilityRule,_that.conditionalDialogues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  DialogueRef? dialogue,  EntityFacing facing,  String visualElementId,  String? trainerId,  int lineOfSightRange,  DialogueRef? defeatDialogueRef,  String? characterId,  MapEntityNpcMovementConfig movement,  MapEntityNpcVisibilityRule? visibilityRule,  List<MapEntityConditionalDialogue> conditionalDialogues)  $default,) {final _that = this;
switch (_that) {
case _MapEntityNpcData():
return $default(_that.displayName,_that.dialogue,_that.facing,_that.visualElementId,_that.trainerId,_that.lineOfSightRange,_that.defeatDialogueRef,_that.characterId,_that.movement,_that.visibilityRule,_that.conditionalDialogues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  DialogueRef? dialogue,  EntityFacing facing,  String visualElementId,  String? trainerId,  int lineOfSightRange,  DialogueRef? defeatDialogueRef,  String? characterId,  MapEntityNpcMovementConfig movement,  MapEntityNpcVisibilityRule? visibilityRule,  List<MapEntityConditionalDialogue> conditionalDialogues)?  $default,) {final _that = this;
switch (_that) {
case _MapEntityNpcData() when $default != null:
return $default(_that.displayName,_that.dialogue,_that.facing,_that.visualElementId,_that.trainerId,_that.lineOfSightRange,_that.defeatDialogueRef,_that.characterId,_that.movement,_that.visibilityRule,_that.conditionalDialogues);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntityNpcData implements MapEntityNpcData {
  const _MapEntityNpcData({this.displayName = '', this.dialogue, this.facing = EntityFacing.south, this.visualElementId = '', this.trainerId, this.lineOfSightRange = 0, this.defeatDialogueRef, this.characterId, this.movement = const MapEntityNpcMovementConfig(), this.visibilityRule, final  List<MapEntityConditionalDialogue> conditionalDialogues = const <MapEntityConditionalDialogue>[]}): _conditionalDialogues = conditionalDialogues;
  factory _MapEntityNpcData.fromJson(Map<String, dynamic> json) => _$MapEntityNpcDataFromJson(json);

@override@JsonKey() final  String displayName;
@override final  DialogueRef? dialogue;
@override@JsonKey() final  EntityFacing facing;
@override@JsonKey() final  String visualElementId;
@override final  String? trainerId;
@override@JsonKey() final  int lineOfSightRange;
@override final  DialogueRef? defeatDialogueRef;
@override final  String? characterId;
@override@JsonKey() final  MapEntityNpcMovementConfig movement;
/// `null` ou mode [MapEntityNpcVisibilityMode.always] = toujours visible.
@override final  MapEntityNpcVisibilityRule? visibilityRule;
/// Variantes testées **dans l’ordre** avant [dialogue] par défaut.
 final  List<MapEntityConditionalDialogue> _conditionalDialogues;
/// Variantes testées **dans l’ordre** avant [dialogue] par défaut.
@override@JsonKey() List<MapEntityConditionalDialogue> get conditionalDialogues {
  if (_conditionalDialogues is EqualUnmodifiableListView) return _conditionalDialogues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conditionalDialogues);
}


/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntityNpcDataCopyWith<_MapEntityNpcData> get copyWith => __$MapEntityNpcDataCopyWithImpl<_MapEntityNpcData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntityNpcDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntityNpcData&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.facing, facing) || other.facing == facing)&&(identical(other.visualElementId, visualElementId) || other.visualElementId == visualElementId)&&(identical(other.trainerId, trainerId) || other.trainerId == trainerId)&&(identical(other.lineOfSightRange, lineOfSightRange) || other.lineOfSightRange == lineOfSightRange)&&(identical(other.defeatDialogueRef, defeatDialogueRef) || other.defeatDialogueRef == defeatDialogueRef)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.movement, movement) || other.movement == movement)&&(identical(other.visibilityRule, visibilityRule) || other.visibilityRule == visibilityRule)&&const DeepCollectionEquality().equals(other._conditionalDialogues, _conditionalDialogues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,dialogue,facing,visualElementId,trainerId,lineOfSightRange,defeatDialogueRef,characterId,movement,visibilityRule,const DeepCollectionEquality().hash(_conditionalDialogues));

@override
String toString() {
  return 'MapEntityNpcData(displayName: $displayName, dialogue: $dialogue, facing: $facing, visualElementId: $visualElementId, trainerId: $trainerId, lineOfSightRange: $lineOfSightRange, defeatDialogueRef: $defeatDialogueRef, characterId: $characterId, movement: $movement, visibilityRule: $visibilityRule, conditionalDialogues: $conditionalDialogues)';
}


}

/// @nodoc
abstract mixin class _$MapEntityNpcDataCopyWith<$Res> implements $MapEntityNpcDataCopyWith<$Res> {
  factory _$MapEntityNpcDataCopyWith(_MapEntityNpcData value, $Res Function(_MapEntityNpcData) _then) = __$MapEntityNpcDataCopyWithImpl;
@override @useResult
$Res call({
 String displayName, DialogueRef? dialogue, EntityFacing facing, String visualElementId, String? trainerId, int lineOfSightRange, DialogueRef? defeatDialogueRef, String? characterId, MapEntityNpcMovementConfig movement, MapEntityNpcVisibilityRule? visibilityRule, List<MapEntityConditionalDialogue> conditionalDialogues
});


@override $DialogueRefCopyWith<$Res>? get dialogue;@override $DialogueRefCopyWith<$Res>? get defeatDialogueRef;@override $MapEntityNpcMovementConfigCopyWith<$Res> get movement;@override $MapEntityNpcVisibilityRuleCopyWith<$Res>? get visibilityRule;

}
/// @nodoc
class __$MapEntityNpcDataCopyWithImpl<$Res>
    implements _$MapEntityNpcDataCopyWith<$Res> {
  __$MapEntityNpcDataCopyWithImpl(this._self, this._then);

  final _MapEntityNpcData _self;
  final $Res Function(_MapEntityNpcData) _then;

/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? dialogue = freezed,Object? facing = null,Object? visualElementId = null,Object? trainerId = freezed,Object? lineOfSightRange = null,Object? defeatDialogueRef = freezed,Object? characterId = freezed,Object? movement = null,Object? visibilityRule = freezed,Object? conditionalDialogues = null,}) {
  return _then(_MapEntityNpcData(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,dialogue: freezed == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as DialogueRef?,facing: null == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as EntityFacing,visualElementId: null == visualElementId ? _self.visualElementId : visualElementId // ignore: cast_nullable_to_non_nullable
as String,trainerId: freezed == trainerId ? _self.trainerId : trainerId // ignore: cast_nullable_to_non_nullable
as String?,lineOfSightRange: null == lineOfSightRange ? _self.lineOfSightRange : lineOfSightRange // ignore: cast_nullable_to_non_nullable
as int,defeatDialogueRef: freezed == defeatDialogueRef ? _self.defeatDialogueRef : defeatDialogueRef // ignore: cast_nullable_to_non_nullable
as DialogueRef?,characterId: freezed == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String?,movement: null == movement ? _self.movement : movement // ignore: cast_nullable_to_non_nullable
as MapEntityNpcMovementConfig,visibilityRule: freezed == visibilityRule ? _self.visibilityRule : visibilityRule // ignore: cast_nullable_to_non_nullable
as MapEntityNpcVisibilityRule?,conditionalDialogues: null == conditionalDialogues ? _self._conditionalDialogues : conditionalDialogues // ignore: cast_nullable_to_non_nullable
as List<MapEntityConditionalDialogue>,
  ));
}

/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res>? get dialogue {
    if (_self.dialogue == null) {
    return null;
  }

  return $DialogueRefCopyWith<$Res>(_self.dialogue!, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res>? get defeatDialogueRef {
    if (_self.defeatDialogueRef == null) {
    return null;
  }

  return $DialogueRefCopyWith<$Res>(_self.defeatDialogueRef!, (value) {
    return _then(_self.copyWith(defeatDialogueRef: value));
  });
}/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityNpcMovementConfigCopyWith<$Res> get movement {

  return $MapEntityNpcMovementConfigCopyWith<$Res>(_self.movement, (value) {
    return _then(_self.copyWith(movement: value));
  });
}/// Create a copy of MapEntityNpcData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapEntityNpcVisibilityRuleCopyWith<$Res>? get visibilityRule {
    if (_self.visibilityRule == null) {
    return null;
  }

  return $MapEntityNpcVisibilityRuleCopyWith<$Res>(_self.visibilityRule!, (value) {
    return _then(_self.copyWith(visibilityRule: value));
  });
}
}


/// @nodoc
mixin _$MapEntityNpcMovementConfig {

 MapEntityNpcMovementMode get mode; List<GridPos> get waypoints; bool get loop; int get pauseDurationMs; int get stepDurationMs;
/// Create a copy of MapEntityNpcMovementConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntityNpcMovementConfigCopyWith<MapEntityNpcMovementConfig> get copyWith => _$MapEntityNpcMovementConfigCopyWithImpl<MapEntityNpcMovementConfig>(this as MapEntityNpcMovementConfig, _$identity);

  /// Serializes this MapEntityNpcMovementConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntityNpcMovementConfig&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other.waypoints, waypoints)&&(identical(other.loop, loop) || other.loop == loop)&&(identical(other.pauseDurationMs, pauseDurationMs) || other.pauseDurationMs == pauseDurationMs)&&(identical(other.stepDurationMs, stepDurationMs) || other.stepDurationMs == stepDurationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,const DeepCollectionEquality().hash(waypoints),loop,pauseDurationMs,stepDurationMs);

@override
String toString() {
  return 'MapEntityNpcMovementConfig(mode: $mode, waypoints: $waypoints, loop: $loop, pauseDurationMs: $pauseDurationMs, stepDurationMs: $stepDurationMs)';
}


}

/// @nodoc
abstract mixin class $MapEntityNpcMovementConfigCopyWith<$Res>  {
  factory $MapEntityNpcMovementConfigCopyWith(MapEntityNpcMovementConfig value, $Res Function(MapEntityNpcMovementConfig) _then) = _$MapEntityNpcMovementConfigCopyWithImpl;
@useResult
$Res call({
 MapEntityNpcMovementMode mode, List<GridPos> waypoints, bool loop, int pauseDurationMs, int stepDurationMs
});




}
/// @nodoc
class _$MapEntityNpcMovementConfigCopyWithImpl<$Res>
    implements $MapEntityNpcMovementConfigCopyWith<$Res> {
  _$MapEntityNpcMovementConfigCopyWithImpl(this._self, this._then);

  final MapEntityNpcMovementConfig _self;
  final $Res Function(MapEntityNpcMovementConfig) _then;

/// Create a copy of MapEntityNpcMovementConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? waypoints = null,Object? loop = null,Object? pauseDurationMs = null,Object? stepDurationMs = null,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MapEntityNpcMovementMode,waypoints: null == waypoints ? _self.waypoints : waypoints // ignore: cast_nullable_to_non_nullable
as List<GridPos>,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,pauseDurationMs: null == pauseDurationMs ? _self.pauseDurationMs : pauseDurationMs // ignore: cast_nullable_to_non_nullable
as int,stepDurationMs: null == stepDurationMs ? _self.stepDurationMs : stepDurationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MapEntityNpcMovementConfig].
extension MapEntityNpcMovementConfigPatterns on MapEntityNpcMovementConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntityNpcMovementConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntityNpcMovementConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntityNpcMovementConfig value)  $default,){
final _that = this;
switch (_that) {
case _MapEntityNpcMovementConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntityNpcMovementConfig value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntityNpcMovementConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MapEntityNpcMovementMode mode,  List<GridPos> waypoints,  bool loop,  int pauseDurationMs,  int stepDurationMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntityNpcMovementConfig() when $default != null:
return $default(_that.mode,_that.waypoints,_that.loop,_that.pauseDurationMs,_that.stepDurationMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MapEntityNpcMovementMode mode,  List<GridPos> waypoints,  bool loop,  int pauseDurationMs,  int stepDurationMs)  $default,) {final _that = this;
switch (_that) {
case _MapEntityNpcMovementConfig():
return $default(_that.mode,_that.waypoints,_that.loop,_that.pauseDurationMs,_that.stepDurationMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MapEntityNpcMovementMode mode,  List<GridPos> waypoints,  bool loop,  int pauseDurationMs,  int stepDurationMs)?  $default,) {final _that = this;
switch (_that) {
case _MapEntityNpcMovementConfig() when $default != null:
return $default(_that.mode,_that.waypoints,_that.loop,_that.pauseDurationMs,_that.stepDurationMs);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntityNpcMovementConfig implements MapEntityNpcMovementConfig {
  const _MapEntityNpcMovementConfig({this.mode = MapEntityNpcMovementMode.idle, final  List<GridPos> waypoints = const <GridPos>[], this.loop = true, this.pauseDurationMs = 0, this.stepDurationMs = 200}): _waypoints = waypoints;
  factory _MapEntityNpcMovementConfig.fromJson(Map<String, dynamic> json) => _$MapEntityNpcMovementConfigFromJson(json);

@override@JsonKey() final  MapEntityNpcMovementMode mode;
 final  List<GridPos> _waypoints;
@override@JsonKey() List<GridPos> get waypoints {
  if (_waypoints is EqualUnmodifiableListView) return _waypoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_waypoints);
}

@override@JsonKey() final  bool loop;
@override@JsonKey() final  int pauseDurationMs;
@override@JsonKey() final  int stepDurationMs;

/// Create a copy of MapEntityNpcMovementConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntityNpcMovementConfigCopyWith<_MapEntityNpcMovementConfig> get copyWith => __$MapEntityNpcMovementConfigCopyWithImpl<_MapEntityNpcMovementConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntityNpcMovementConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntityNpcMovementConfig&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other._waypoints, _waypoints)&&(identical(other.loop, loop) || other.loop == loop)&&(identical(other.pauseDurationMs, pauseDurationMs) || other.pauseDurationMs == pauseDurationMs)&&(identical(other.stepDurationMs, stepDurationMs) || other.stepDurationMs == stepDurationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode,const DeepCollectionEquality().hash(_waypoints),loop,pauseDurationMs,stepDurationMs);

@override
String toString() {
  return 'MapEntityNpcMovementConfig(mode: $mode, waypoints: $waypoints, loop: $loop, pauseDurationMs: $pauseDurationMs, stepDurationMs: $stepDurationMs)';
}


}

/// @nodoc
abstract mixin class _$MapEntityNpcMovementConfigCopyWith<$Res> implements $MapEntityNpcMovementConfigCopyWith<$Res> {
  factory _$MapEntityNpcMovementConfigCopyWith(_MapEntityNpcMovementConfig value, $Res Function(_MapEntityNpcMovementConfig) _then) = __$MapEntityNpcMovementConfigCopyWithImpl;
@override @useResult
$Res call({
 MapEntityNpcMovementMode mode, List<GridPos> waypoints, bool loop, int pauseDurationMs, int stepDurationMs
});




}
/// @nodoc
class __$MapEntityNpcMovementConfigCopyWithImpl<$Res>
    implements _$MapEntityNpcMovementConfigCopyWith<$Res> {
  __$MapEntityNpcMovementConfigCopyWithImpl(this._self, this._then);

  final _MapEntityNpcMovementConfig _self;
  final $Res Function(_MapEntityNpcMovementConfig) _then;

/// Create a copy of MapEntityNpcMovementConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? waypoints = null,Object? loop = null,Object? pauseDurationMs = null,Object? stepDurationMs = null,}) {
  return _then(_MapEntityNpcMovementConfig(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as MapEntityNpcMovementMode,waypoints: null == waypoints ? _self._waypoints : waypoints // ignore: cast_nullable_to_non_nullable
as List<GridPos>,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,pauseDurationMs: null == pauseDurationMs ? _self.pauseDurationMs : pauseDurationMs // ignore: cast_nullable_to_non_nullable
as int,stepDurationMs: null == stepDurationMs ? _self.stepDurationMs : stepDurationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MapEntitySignData {

 String get title; DialogueRef? get dialogue;/// Texte affiché si pas de dialogue scripté (panneau simple).
 String get plainText;
/// Create a copy of MapEntitySignData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntitySignDataCopyWith<MapEntitySignData> get copyWith => _$MapEntitySignDataCopyWithImpl<MapEntitySignData>(this as MapEntitySignData, _$identity);

  /// Serializes this MapEntitySignData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntitySignData&&(identical(other.title, title) || other.title == title)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.plainText, plainText) || other.plainText == plainText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,dialogue,plainText);

@override
String toString() {
  return 'MapEntitySignData(title: $title, dialogue: $dialogue, plainText: $plainText)';
}


}

/// @nodoc
abstract mixin class $MapEntitySignDataCopyWith<$Res>  {
  factory $MapEntitySignDataCopyWith(MapEntitySignData value, $Res Function(MapEntitySignData) _then) = _$MapEntitySignDataCopyWithImpl;
@useResult
$Res call({
 String title, DialogueRef? dialogue, String plainText
});


$DialogueRefCopyWith<$Res>? get dialogue;

}
/// @nodoc
class _$MapEntitySignDataCopyWithImpl<$Res>
    implements $MapEntitySignDataCopyWith<$Res> {
  _$MapEntitySignDataCopyWithImpl(this._self, this._then);

  final MapEntitySignData _self;
  final $Res Function(MapEntitySignData) _then;

/// Create a copy of MapEntitySignData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? dialogue = freezed,Object? plainText = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,dialogue: freezed == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as DialogueRef?,plainText: null == plainText ? _self.plainText : plainText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of MapEntitySignData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res>? get dialogue {
    if (_self.dialogue == null) {
    return null;
  }

  return $DialogueRefCopyWith<$Res>(_self.dialogue!, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapEntitySignData].
extension MapEntitySignDataPatterns on MapEntitySignData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntitySignData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntitySignData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntitySignData value)  $default,){
final _that = this;
switch (_that) {
case _MapEntitySignData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntitySignData value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntitySignData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  DialogueRef? dialogue,  String plainText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntitySignData() when $default != null:
return $default(_that.title,_that.dialogue,_that.plainText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  DialogueRef? dialogue,  String plainText)  $default,) {final _that = this;
switch (_that) {
case _MapEntitySignData():
return $default(_that.title,_that.dialogue,_that.plainText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  DialogueRef? dialogue,  String plainText)?  $default,) {final _that = this;
switch (_that) {
case _MapEntitySignData() when $default != null:
return $default(_that.title,_that.dialogue,_that.plainText);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntitySignData implements MapEntitySignData {
  const _MapEntitySignData({this.title = '', this.dialogue, this.plainText = ''});
  factory _MapEntitySignData.fromJson(Map<String, dynamic> json) => _$MapEntitySignDataFromJson(json);

@override@JsonKey() final  String title;
@override final  DialogueRef? dialogue;
/// Texte affiché si pas de dialogue scripté (panneau simple).
@override@JsonKey() final  String plainText;

/// Create a copy of MapEntitySignData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntitySignDataCopyWith<_MapEntitySignData> get copyWith => __$MapEntitySignDataCopyWithImpl<_MapEntitySignData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntitySignDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntitySignData&&(identical(other.title, title) || other.title == title)&&(identical(other.dialogue, dialogue) || other.dialogue == dialogue)&&(identical(other.plainText, plainText) || other.plainText == plainText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,dialogue,plainText);

@override
String toString() {
  return 'MapEntitySignData(title: $title, dialogue: $dialogue, plainText: $plainText)';
}


}

/// @nodoc
abstract mixin class _$MapEntitySignDataCopyWith<$Res> implements $MapEntitySignDataCopyWith<$Res> {
  factory _$MapEntitySignDataCopyWith(_MapEntitySignData value, $Res Function(_MapEntitySignData) _then) = __$MapEntitySignDataCopyWithImpl;
@override @useResult
$Res call({
 String title, DialogueRef? dialogue, String plainText
});


@override $DialogueRefCopyWith<$Res>? get dialogue;

}
/// @nodoc
class __$MapEntitySignDataCopyWithImpl<$Res>
    implements _$MapEntitySignDataCopyWith<$Res> {
  __$MapEntitySignDataCopyWithImpl(this._self, this._then);

  final _MapEntitySignData _self;
  final $Res Function(_MapEntitySignData) _then;

/// Create a copy of MapEntitySignData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? dialogue = freezed,Object? plainText = null,}) {
  return _then(_MapEntitySignData(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,dialogue: freezed == dialogue ? _self.dialogue : dialogue // ignore: cast_nullable_to_non_nullable
as DialogueRef?,plainText: null == plainText ? _self.plainText : plainText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of MapEntitySignData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DialogueRefCopyWith<$Res>? get dialogue {
    if (_self.dialogue == null) {
    return null;
  }

  return $DialogueRefCopyWith<$Res>(_self.dialogue!, (value) {
    return _then(_self.copyWith(dialogue: value));
  });
}
}


/// @nodoc
mixin _$MapEntityItemData {

 String get gameItemId; int get quantity; ItemPickupMode get pickupMode; ItemRespawnPolicy get respawnPolicy; MapEntityItemVisibility get visibility;
/// Create a copy of MapEntityItemData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntityItemDataCopyWith<MapEntityItemData> get copyWith => _$MapEntityItemDataCopyWithImpl<MapEntityItemData>(this as MapEntityItemData, _$identity);

  /// Serializes this MapEntityItemData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntityItemData&&(identical(other.gameItemId, gameItemId) || other.gameItemId == gameItemId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.pickupMode, pickupMode) || other.pickupMode == pickupMode)&&(identical(other.respawnPolicy, respawnPolicy) || other.respawnPolicy == respawnPolicy)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameItemId,quantity,pickupMode,respawnPolicy,visibility);

@override
String toString() {
  return 'MapEntityItemData(gameItemId: $gameItemId, quantity: $quantity, pickupMode: $pickupMode, respawnPolicy: $respawnPolicy, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class $MapEntityItemDataCopyWith<$Res>  {
  factory $MapEntityItemDataCopyWith(MapEntityItemData value, $Res Function(MapEntityItemData) _then) = _$MapEntityItemDataCopyWithImpl;
@useResult
$Res call({
 String gameItemId, int quantity, ItemPickupMode pickupMode, ItemRespawnPolicy respawnPolicy, MapEntityItemVisibility visibility
});




}
/// @nodoc
class _$MapEntityItemDataCopyWithImpl<$Res>
    implements $MapEntityItemDataCopyWith<$Res> {
  _$MapEntityItemDataCopyWithImpl(this._self, this._then);

  final MapEntityItemData _self;
  final $Res Function(MapEntityItemData) _then;

/// Create a copy of MapEntityItemData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameItemId = null,Object? quantity = null,Object? pickupMode = null,Object? respawnPolicy = null,Object? visibility = null,}) {
  return _then(_self.copyWith(
gameItemId: null == gameItemId ? _self.gameItemId : gameItemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,pickupMode: null == pickupMode ? _self.pickupMode : pickupMode // ignore: cast_nullable_to_non_nullable
as ItemPickupMode,respawnPolicy: null == respawnPolicy ? _self.respawnPolicy : respawnPolicy // ignore: cast_nullable_to_non_nullable
as ItemRespawnPolicy,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as MapEntityItemVisibility,
  ));
}

}


/// Adds pattern-matching-related methods to [MapEntityItemData].
extension MapEntityItemDataPatterns on MapEntityItemData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntityItemData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntityItemData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntityItemData value)  $default,){
final _that = this;
switch (_that) {
case _MapEntityItemData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntityItemData value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntityItemData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameItemId,  int quantity,  ItemPickupMode pickupMode,  ItemRespawnPolicy respawnPolicy,  MapEntityItemVisibility visibility)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntityItemData() when $default != null:
return $default(_that.gameItemId,_that.quantity,_that.pickupMode,_that.respawnPolicy,_that.visibility);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameItemId,  int quantity,  ItemPickupMode pickupMode,  ItemRespawnPolicy respawnPolicy,  MapEntityItemVisibility visibility)  $default,) {final _that = this;
switch (_that) {
case _MapEntityItemData():
return $default(_that.gameItemId,_that.quantity,_that.pickupMode,_that.respawnPolicy,_that.visibility);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameItemId,  int quantity,  ItemPickupMode pickupMode,  ItemRespawnPolicy respawnPolicy,  MapEntityItemVisibility visibility)?  $default,) {final _that = this;
switch (_that) {
case _MapEntityItemData() when $default != null:
return $default(_that.gameItemId,_that.quantity,_that.pickupMode,_that.respawnPolicy,_that.visibility);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntityItemData implements MapEntityItemData {
  const _MapEntityItemData({this.gameItemId = '', this.quantity = 1, this.pickupMode = ItemPickupMode.once, this.respawnPolicy = ItemRespawnPolicy.none, this.visibility = MapEntityItemVisibility.visible});
  factory _MapEntityItemData.fromJson(Map<String, dynamic> json) => _$MapEntityItemDataFromJson(json);

@override@JsonKey() final  String gameItemId;
@override@JsonKey() final  int quantity;
@override@JsonKey() final  ItemPickupMode pickupMode;
@override@JsonKey() final  ItemRespawnPolicy respawnPolicy;
@override@JsonKey() final  MapEntityItemVisibility visibility;

/// Create a copy of MapEntityItemData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntityItemDataCopyWith<_MapEntityItemData> get copyWith => __$MapEntityItemDataCopyWithImpl<_MapEntityItemData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntityItemDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntityItemData&&(identical(other.gameItemId, gameItemId) || other.gameItemId == gameItemId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.pickupMode, pickupMode) || other.pickupMode == pickupMode)&&(identical(other.respawnPolicy, respawnPolicy) || other.respawnPolicy == respawnPolicy)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameItemId,quantity,pickupMode,respawnPolicy,visibility);

@override
String toString() {
  return 'MapEntityItemData(gameItemId: $gameItemId, quantity: $quantity, pickupMode: $pickupMode, respawnPolicy: $respawnPolicy, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class _$MapEntityItemDataCopyWith<$Res> implements $MapEntityItemDataCopyWith<$Res> {
  factory _$MapEntityItemDataCopyWith(_MapEntityItemData value, $Res Function(_MapEntityItemData) _then) = __$MapEntityItemDataCopyWithImpl;
@override @useResult
$Res call({
 String gameItemId, int quantity, ItemPickupMode pickupMode, ItemRespawnPolicy respawnPolicy, MapEntityItemVisibility visibility
});




}
/// @nodoc
class __$MapEntityItemDataCopyWithImpl<$Res>
    implements _$MapEntityItemDataCopyWith<$Res> {
  __$MapEntityItemDataCopyWithImpl(this._self, this._then);

  final _MapEntityItemData _self;
  final $Res Function(_MapEntityItemData) _then;

/// Create a copy of MapEntityItemData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameItemId = null,Object? quantity = null,Object? pickupMode = null,Object? respawnPolicy = null,Object? visibility = null,}) {
  return _then(_MapEntityItemData(
gameItemId: null == gameItemId ? _self.gameItemId : gameItemId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,pickupMode: null == pickupMode ? _self.pickupMode : pickupMode // ignore: cast_nullable_to_non_nullable
as ItemPickupMode,respawnPolicy: null == respawnPolicy ? _self.respawnPolicy : respawnPolicy // ignore: cast_nullable_to_non_nullable
as ItemRespawnPolicy,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as MapEntityItemVisibility,
  ));
}


}


/// @nodoc
mixin _$MapEntitySpawnData {

 String get spawnKey; EntitySpawnRole get role; EntityFacing get facing; String get categoryTag;
/// Create a copy of MapEntitySpawnData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntitySpawnDataCopyWith<MapEntitySpawnData> get copyWith => _$MapEntitySpawnDataCopyWithImpl<MapEntitySpawnData>(this as MapEntitySpawnData, _$identity);

  /// Serializes this MapEntitySpawnData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntitySpawnData&&(identical(other.spawnKey, spawnKey) || other.spawnKey == spawnKey)&&(identical(other.role, role) || other.role == role)&&(identical(other.facing, facing) || other.facing == facing)&&(identical(other.categoryTag, categoryTag) || other.categoryTag == categoryTag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,spawnKey,role,facing,categoryTag);

@override
String toString() {
  return 'MapEntitySpawnData(spawnKey: $spawnKey, role: $role, facing: $facing, categoryTag: $categoryTag)';
}


}

/// @nodoc
abstract mixin class $MapEntitySpawnDataCopyWith<$Res>  {
  factory $MapEntitySpawnDataCopyWith(MapEntitySpawnData value, $Res Function(MapEntitySpawnData) _then) = _$MapEntitySpawnDataCopyWithImpl;
@useResult
$Res call({
 String spawnKey, EntitySpawnRole role, EntityFacing facing, String categoryTag
});




}
/// @nodoc
class _$MapEntitySpawnDataCopyWithImpl<$Res>
    implements $MapEntitySpawnDataCopyWith<$Res> {
  _$MapEntitySpawnDataCopyWithImpl(this._self, this._then);

  final MapEntitySpawnData _self;
  final $Res Function(MapEntitySpawnData) _then;

/// Create a copy of MapEntitySpawnData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? spawnKey = null,Object? role = null,Object? facing = null,Object? categoryTag = null,}) {
  return _then(_self.copyWith(
spawnKey: null == spawnKey ? _self.spawnKey : spawnKey // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as EntitySpawnRole,facing: null == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as EntityFacing,categoryTag: null == categoryTag ? _self.categoryTag : categoryTag // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MapEntitySpawnData].
extension MapEntitySpawnDataPatterns on MapEntitySpawnData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntitySpawnData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntitySpawnData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntitySpawnData value)  $default,){
final _that = this;
switch (_that) {
case _MapEntitySpawnData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntitySpawnData value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntitySpawnData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String spawnKey,  EntitySpawnRole role,  EntityFacing facing,  String categoryTag)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntitySpawnData() when $default != null:
return $default(_that.spawnKey,_that.role,_that.facing,_that.categoryTag);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String spawnKey,  EntitySpawnRole role,  EntityFacing facing,  String categoryTag)  $default,) {final _that = this;
switch (_that) {
case _MapEntitySpawnData():
return $default(_that.spawnKey,_that.role,_that.facing,_that.categoryTag);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String spawnKey,  EntitySpawnRole role,  EntityFacing facing,  String categoryTag)?  $default,) {final _that = this;
switch (_that) {
case _MapEntitySpawnData() when $default != null:
return $default(_that.spawnKey,_that.role,_that.facing,_that.categoryTag);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntitySpawnData implements MapEntitySpawnData {
  const _MapEntitySpawnData({this.spawnKey = '', this.role = EntitySpawnRole.playerStart, this.facing = EntityFacing.south, this.categoryTag = ''});
  factory _MapEntitySpawnData.fromJson(Map<String, dynamic> json) => _$MapEntitySpawnDataFromJson(json);

@override@JsonKey() final  String spawnKey;
@override@JsonKey() final  EntitySpawnRole role;
@override@JsonKey() final  EntityFacing facing;
@override@JsonKey() final  String categoryTag;

/// Create a copy of MapEntitySpawnData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntitySpawnDataCopyWith<_MapEntitySpawnData> get copyWith => __$MapEntitySpawnDataCopyWithImpl<_MapEntitySpawnData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntitySpawnDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntitySpawnData&&(identical(other.spawnKey, spawnKey) || other.spawnKey == spawnKey)&&(identical(other.role, role) || other.role == role)&&(identical(other.facing, facing) || other.facing == facing)&&(identical(other.categoryTag, categoryTag) || other.categoryTag == categoryTag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,spawnKey,role,facing,categoryTag);

@override
String toString() {
  return 'MapEntitySpawnData(spawnKey: $spawnKey, role: $role, facing: $facing, categoryTag: $categoryTag)';
}


}

/// @nodoc
abstract mixin class _$MapEntitySpawnDataCopyWith<$Res> implements $MapEntitySpawnDataCopyWith<$Res> {
  factory _$MapEntitySpawnDataCopyWith(_MapEntitySpawnData value, $Res Function(_MapEntitySpawnData) _then) = __$MapEntitySpawnDataCopyWithImpl;
@override @useResult
$Res call({
 String spawnKey, EntitySpawnRole role, EntityFacing facing, String categoryTag
});




}
/// @nodoc
class __$MapEntitySpawnDataCopyWithImpl<$Res>
    implements _$MapEntitySpawnDataCopyWith<$Res> {
  __$MapEntitySpawnDataCopyWithImpl(this._self, this._then);

  final _MapEntitySpawnData _self;
  final $Res Function(_MapEntitySpawnData) _then;

/// Create a copy of MapEntitySpawnData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? spawnKey = null,Object? role = null,Object? facing = null,Object? categoryTag = null,}) {
  return _then(_MapEntitySpawnData(
spawnKey: null == spawnKey ? _self.spawnKey : spawnKey // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as EntitySpawnRole,facing: null == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as EntityFacing,categoryTag: null == categoryTag ? _self.categoryTag : categoryTag // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
