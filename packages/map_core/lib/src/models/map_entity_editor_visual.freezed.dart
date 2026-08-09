// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_entity_editor_visual.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MapEntityEditorVisual {

 String get elementId;/// Force le rendu de cette entité "élément projet" au-dessus du décor
/// avant-plan.
///
/// Cas visé :
/// - petits props décoratifs représentés comme entités (ex. Poké Ball
///   posée sur une table) ;
/// - besoin de garder un objet volontairement visible au-dessus d'un
///   overlay de tiles qui masquerait sinon l'entité.
///
/// Non-objectif :
/// - ce n'est pas un système générique de z-index ;
/// - ce flag n'a pas vocation à remplacer le tri "par les pieds" des
///   vrais acteurs gameplay ;
/// - il sert seulement à faire passer l'entité dans la passe foreground
///   quand elle est rendue comme ProjectElementEntry.
 bool get renderInForeground;
/// Create a copy of MapEntityEditorVisual
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapEntityEditorVisualCopyWith<MapEntityEditorVisual> get copyWith => _$MapEntityEditorVisualCopyWithImpl<MapEntityEditorVisual>(this as MapEntityEditorVisual, _$identity);

  /// Serializes this MapEntityEditorVisual to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapEntityEditorVisual&&(identical(other.elementId, elementId) || other.elementId == elementId)&&(identical(other.renderInForeground, renderInForeground) || other.renderInForeground == renderInForeground));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,elementId,renderInForeground);

@override
String toString() {
  return 'MapEntityEditorVisual(elementId: $elementId, renderInForeground: $renderInForeground)';
}


}

/// @nodoc
abstract mixin class $MapEntityEditorVisualCopyWith<$Res>  {
  factory $MapEntityEditorVisualCopyWith(MapEntityEditorVisual value, $Res Function(MapEntityEditorVisual) _then) = _$MapEntityEditorVisualCopyWithImpl;
@useResult
$Res call({
 String elementId, bool renderInForeground
});




}
/// @nodoc
class _$MapEntityEditorVisualCopyWithImpl<$Res>
    implements $MapEntityEditorVisualCopyWith<$Res> {
  _$MapEntityEditorVisualCopyWithImpl(this._self, this._then);

  final MapEntityEditorVisual _self;
  final $Res Function(MapEntityEditorVisual) _then;

/// Create a copy of MapEntityEditorVisual
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? elementId = null,Object? renderInForeground = null,}) {
  return _then(_self.copyWith(
elementId: null == elementId ? _self.elementId : elementId // ignore: cast_nullable_to_non_nullable
as String,renderInForeground: null == renderInForeground ? _self.renderInForeground : renderInForeground // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MapEntityEditorVisual].
extension MapEntityEditorVisualPatterns on MapEntityEditorVisual {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapEntityEditorVisual value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapEntityEditorVisual() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapEntityEditorVisual value)  $default,){
final _that = this;
switch (_that) {
case _MapEntityEditorVisual():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapEntityEditorVisual value)?  $default,){
final _that = this;
switch (_that) {
case _MapEntityEditorVisual() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String elementId,  bool renderInForeground)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapEntityEditorVisual() when $default != null:
return $default(_that.elementId,_that.renderInForeground);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String elementId,  bool renderInForeground)  $default,) {final _that = this;
switch (_that) {
case _MapEntityEditorVisual():
return $default(_that.elementId,_that.renderInForeground);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String elementId,  bool renderInForeground)?  $default,) {final _that = this;
switch (_that) {
case _MapEntityEditorVisual() when $default != null:
return $default(_that.elementId,_that.renderInForeground);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _MapEntityEditorVisual implements MapEntityEditorVisual {
  const _MapEntityEditorVisual({required this.elementId, this.renderInForeground = false});
  factory _MapEntityEditorVisual.fromJson(Map<String, dynamic> json) => _$MapEntityEditorVisualFromJson(json);

@override final  String elementId;
/// Force le rendu de cette entité "élément projet" au-dessus du décor
/// avant-plan.
///
/// Cas visé :
/// - petits props décoratifs représentés comme entités (ex. Poké Ball
///   posée sur une table) ;
/// - besoin de garder un objet volontairement visible au-dessus d'un
///   overlay de tiles qui masquerait sinon l'entité.
///
/// Non-objectif :
/// - ce n'est pas un système générique de z-index ;
/// - ce flag n'a pas vocation à remplacer le tri "par les pieds" des
///   vrais acteurs gameplay ;
/// - il sert seulement à faire passer l'entité dans la passe foreground
///   quand elle est rendue comme ProjectElementEntry.
@override@JsonKey() final  bool renderInForeground;

/// Create a copy of MapEntityEditorVisual
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapEntityEditorVisualCopyWith<_MapEntityEditorVisual> get copyWith => __$MapEntityEditorVisualCopyWithImpl<_MapEntityEditorVisual>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MapEntityEditorVisualToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapEntityEditorVisual&&(identical(other.elementId, elementId) || other.elementId == elementId)&&(identical(other.renderInForeground, renderInForeground) || other.renderInForeground == renderInForeground));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,elementId,renderInForeground);

@override
String toString() {
  return 'MapEntityEditorVisual(elementId: $elementId, renderInForeground: $renderInForeground)';
}


}

/// @nodoc
abstract mixin class _$MapEntityEditorVisualCopyWith<$Res> implements $MapEntityEditorVisualCopyWith<$Res> {
  factory _$MapEntityEditorVisualCopyWith(_MapEntityEditorVisual value, $Res Function(_MapEntityEditorVisual) _then) = __$MapEntityEditorVisualCopyWithImpl;
@override @useResult
$Res call({
 String elementId, bool renderInForeground
});




}
/// @nodoc
class __$MapEntityEditorVisualCopyWithImpl<$Res>
    implements _$MapEntityEditorVisualCopyWith<$Res> {
  __$MapEntityEditorVisualCopyWithImpl(this._self, this._then);

  final _MapEntityEditorVisual _self;
  final $Res Function(_MapEntityEditorVisual) _then;

/// Create a copy of MapEntityEditorVisual
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? elementId = null,Object? renderInForeground = null,}) {
  return _then(_MapEntityEditorVisual(
elementId: null == elementId ? _self.elementId : elementId // ignore: cast_nullable_to_non_nullable
as String,renderInForeground: null == renderInForeground ? _self.renderInForeground : renderInForeground // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
