// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pokemon_move_accuracy.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
PokemonMoveAccuracy _$PokemonMoveAccuracyFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'percent':
          return PokemonMoveAccuracyPercent.fromJson(
            json
          );
                case 'always_hits':
          return PokemonMoveAccuracyAlwaysHits.fromJson(
            json
          );

          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'PokemonMoveAccuracy',
  'Invalid union type "${json['kind']}"!'
);
        }

}

/// @nodoc
mixin _$PokemonMoveAccuracy {



  /// Serializes this PokemonMoveAccuracy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveAccuracy);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PokemonMoveAccuracy()';
}


}

/// @nodoc
class $PokemonMoveAccuracyCopyWith<$Res>  {
$PokemonMoveAccuracyCopyWith(PokemonMoveAccuracy _, $Res Function(PokemonMoveAccuracy) __);
}


/// Adds pattern-matching-related methods to [PokemonMoveAccuracy].
extension PokemonMoveAccuracyPatterns on PokemonMoveAccuracy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PokemonMoveAccuracyPercent value)?  percent,TResult Function( PokemonMoveAccuracyAlwaysHits value)?  alwaysHits,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PokemonMoveAccuracyPercent() when percent != null:
return percent(_that);case PokemonMoveAccuracyAlwaysHits() when alwaysHits != null:
return alwaysHits(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PokemonMoveAccuracyPercent value)  percent,required TResult Function( PokemonMoveAccuracyAlwaysHits value)  alwaysHits,}){
final _that = this;
switch (_that) {
case PokemonMoveAccuracyPercent():
return percent(_that);case PokemonMoveAccuracyAlwaysHits():
return alwaysHits(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PokemonMoveAccuracyPercent value)?  percent,TResult? Function( PokemonMoveAccuracyAlwaysHits value)?  alwaysHits,}){
final _that = this;
switch (_that) {
case PokemonMoveAccuracyPercent() when percent != null:
return percent(_that);case PokemonMoveAccuracyAlwaysHits() when alwaysHits != null:
return alwaysHits(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int value)?  percent,TResult Function()?  alwaysHits,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PokemonMoveAccuracyPercent() when percent != null:
return percent(_that.value);case PokemonMoveAccuracyAlwaysHits() when alwaysHits != null:
return alwaysHits();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int value)  percent,required TResult Function()  alwaysHits,}) {final _that = this;
switch (_that) {
case PokemonMoveAccuracyPercent():
return percent(_that.value);case PokemonMoveAccuracyAlwaysHits():
return alwaysHits();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int value)?  percent,TResult? Function()?  alwaysHits,}) {final _that = this;
switch (_that) {
case PokemonMoveAccuracyPercent() when percent != null:
return percent(_that.value);case PokemonMoveAccuracyAlwaysHits() when alwaysHits != null:
return alwaysHits();case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveAccuracyPercent extends PokemonMoveAccuracy {
  const PokemonMoveAccuracyPercent({required this.value, final  String? $type}): $type = $type ?? 'percent',super._();
  factory PokemonMoveAccuracyPercent.fromJson(Map<String, dynamic> json) => _$PokemonMoveAccuracyPercentFromJson(json);

 final  int value;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of PokemonMoveAccuracy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PokemonMoveAccuracyPercentCopyWith<PokemonMoveAccuracyPercent> get copyWith => _$PokemonMoveAccuracyPercentCopyWithImpl<PokemonMoveAccuracyPercent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveAccuracyPercentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveAccuracyPercent&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'PokemonMoveAccuracy.percent(value: $value)';
}


}

/// @nodoc
abstract mixin class $PokemonMoveAccuracyPercentCopyWith<$Res> implements $PokemonMoveAccuracyCopyWith<$Res> {
  factory $PokemonMoveAccuracyPercentCopyWith(PokemonMoveAccuracyPercent value, $Res Function(PokemonMoveAccuracyPercent) _then) = _$PokemonMoveAccuracyPercentCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$PokemonMoveAccuracyPercentCopyWithImpl<$Res>
    implements $PokemonMoveAccuracyPercentCopyWith<$Res> {
  _$PokemonMoveAccuracyPercentCopyWithImpl(this._self, this._then);

  final PokemonMoveAccuracyPercent _self;
  final $Res Function(PokemonMoveAccuracyPercent) _then;

/// Create a copy of PokemonMoveAccuracy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(PokemonMoveAccuracyPercent(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class PokemonMoveAccuracyAlwaysHits extends PokemonMoveAccuracy {
  const PokemonMoveAccuracyAlwaysHits({final  String? $type}): $type = $type ?? 'always_hits',super._();
  factory PokemonMoveAccuracyAlwaysHits.fromJson(Map<String, dynamic> json) => _$PokemonMoveAccuracyAlwaysHitsFromJson(json);



@JsonKey(name: 'kind')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$PokemonMoveAccuracyAlwaysHitsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PokemonMoveAccuracyAlwaysHits);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PokemonMoveAccuracy.alwaysHits()';
}


}




// dart format on
