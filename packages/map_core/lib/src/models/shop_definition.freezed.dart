// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShopEntryDefinition {

 String get itemId;@JsonKey(fromJson: _shopIntegerFromJson) int get price;@JsonKey(fromJson: _shopNullableIntegerFromJson) int? get sellPrice;@JsonKey(fromJson: _shopNullableIntegerFromJson) int? get stock;
/// Create a copy of ShopEntryDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopEntryDefinitionCopyWith<ShopEntryDefinition> get copyWith => _$ShopEntryDefinitionCopyWithImpl<ShopEntryDefinition>(this as ShopEntryDefinition, _$identity);

  /// Serializes this ShopEntryDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopEntryDefinition&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.price, price) || other.price == price)&&(identical(other.sellPrice, sellPrice) || other.sellPrice == sellPrice)&&(identical(other.stock, stock) || other.stock == stock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,price,sellPrice,stock);

@override
String toString() {
  return 'ShopEntryDefinition(itemId: $itemId, price: $price, sellPrice: $sellPrice, stock: $stock)';
}


}

/// @nodoc
abstract mixin class $ShopEntryDefinitionCopyWith<$Res>  {
  factory $ShopEntryDefinitionCopyWith(ShopEntryDefinition value, $Res Function(ShopEntryDefinition) _then) = _$ShopEntryDefinitionCopyWithImpl;
@useResult
$Res call({
 String itemId,@JsonKey(fromJson: _shopIntegerFromJson) int price,@JsonKey(fromJson: _shopNullableIntegerFromJson) int? sellPrice,@JsonKey(fromJson: _shopNullableIntegerFromJson) int? stock
});




}
/// @nodoc
class _$ShopEntryDefinitionCopyWithImpl<$Res>
    implements $ShopEntryDefinitionCopyWith<$Res> {
  _$ShopEntryDefinitionCopyWithImpl(this._self, this._then);

  final ShopEntryDefinition _self;
  final $Res Function(ShopEntryDefinition) _then;

/// Create a copy of ShopEntryDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = null,Object? price = null,Object? sellPrice = freezed,Object? stock = freezed,}) {
  return _then(_self.copyWith(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,sellPrice: freezed == sellPrice ? _self.sellPrice : sellPrice // ignore: cast_nullable_to_non_nullable
as int?,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopEntryDefinition].
extension ShopEntryDefinitionPatterns on ShopEntryDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopEntryDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopEntryDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopEntryDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ShopEntryDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopEntryDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ShopEntryDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemId, @JsonKey(fromJson: _shopIntegerFromJson)  int price, @JsonKey(fromJson: _shopNullableIntegerFromJson)  int? sellPrice, @JsonKey(fromJson: _shopNullableIntegerFromJson)  int? stock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopEntryDefinition() when $default != null:
return $default(_that.itemId,_that.price,_that.sellPrice,_that.stock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemId, @JsonKey(fromJson: _shopIntegerFromJson)  int price, @JsonKey(fromJson: _shopNullableIntegerFromJson)  int? sellPrice, @JsonKey(fromJson: _shopNullableIntegerFromJson)  int? stock)  $default,) {final _that = this;
switch (_that) {
case _ShopEntryDefinition():
return $default(_that.itemId,_that.price,_that.sellPrice,_that.stock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemId, @JsonKey(fromJson: _shopIntegerFromJson)  int price, @JsonKey(fromJson: _shopNullableIntegerFromJson)  int? sellPrice, @JsonKey(fromJson: _shopNullableIntegerFromJson)  int? stock)?  $default,) {final _that = this;
switch (_that) {
case _ShopEntryDefinition() when $default != null:
return $default(_that.itemId,_that.price,_that.sellPrice,_that.stock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShopEntryDefinition extends ShopEntryDefinition {
  const _ShopEntryDefinition({required this.itemId, @JsonKey(fromJson: _shopIntegerFromJson) required this.price, @JsonKey(fromJson: _shopNullableIntegerFromJson) this.sellPrice, @JsonKey(fromJson: _shopNullableIntegerFromJson) this.stock}): super._();
  factory _ShopEntryDefinition.fromJson(Map<String, dynamic> json) => _$ShopEntryDefinitionFromJson(json);

@override final  String itemId;
@override@JsonKey(fromJson: _shopIntegerFromJson) final  int price;
@override@JsonKey(fromJson: _shopNullableIntegerFromJson) final  int? sellPrice;
@override@JsonKey(fromJson: _shopNullableIntegerFromJson) final  int? stock;

/// Create a copy of ShopEntryDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopEntryDefinitionCopyWith<_ShopEntryDefinition> get copyWith => __$ShopEntryDefinitionCopyWithImpl<_ShopEntryDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopEntryDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopEntryDefinition&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.price, price) || other.price == price)&&(identical(other.sellPrice, sellPrice) || other.sellPrice == sellPrice)&&(identical(other.stock, stock) || other.stock == stock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemId,price,sellPrice,stock);

@override
String toString() {
  return 'ShopEntryDefinition(itemId: $itemId, price: $price, sellPrice: $sellPrice, stock: $stock)';
}


}

/// @nodoc
abstract mixin class _$ShopEntryDefinitionCopyWith<$Res> implements $ShopEntryDefinitionCopyWith<$Res> {
  factory _$ShopEntryDefinitionCopyWith(_ShopEntryDefinition value, $Res Function(_ShopEntryDefinition) _then) = __$ShopEntryDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String itemId,@JsonKey(fromJson: _shopIntegerFromJson) int price,@JsonKey(fromJson: _shopNullableIntegerFromJson) int? sellPrice,@JsonKey(fromJson: _shopNullableIntegerFromJson) int? stock
});




}
/// @nodoc
class __$ShopEntryDefinitionCopyWithImpl<$Res>
    implements _$ShopEntryDefinitionCopyWith<$Res> {
  __$ShopEntryDefinitionCopyWithImpl(this._self, this._then);

  final _ShopEntryDefinition _self;
  final $Res Function(_ShopEntryDefinition) _then;

/// Create a copy of ShopEntryDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? price = null,Object? sellPrice = freezed,Object? stock = freezed,}) {
  return _then(_ShopEntryDefinition(
itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,sellPrice: freezed == sellPrice ? _self.sellPrice : sellPrice // ignore: cast_nullable_to_non_nullable
as int?,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ShopDefinition {

 String get id; String get label; List<ShopEntryDefinition> get entries; List<ShopStateDefinition> get states;
/// Create a copy of ShopDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopDefinitionCopyWith<ShopDefinition> get copyWith => _$ShopDefinitionCopyWithImpl<ShopDefinition>(this as ShopDefinition, _$identity);

  /// Serializes this ShopDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.states, states));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(states));

@override
String toString() {
  return 'ShopDefinition(id: $id, label: $label, entries: $entries, states: $states)';
}


}

/// @nodoc
abstract mixin class $ShopDefinitionCopyWith<$Res>  {
  factory $ShopDefinitionCopyWith(ShopDefinition value, $Res Function(ShopDefinition) _then) = _$ShopDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String label, List<ShopEntryDefinition> entries, List<ShopStateDefinition> states
});




}
/// @nodoc
class _$ShopDefinitionCopyWithImpl<$Res>
    implements $ShopDefinitionCopyWith<$Res> {
  _$ShopDefinitionCopyWithImpl(this._self, this._then);

  final ShopDefinition _self;
  final $Res Function(ShopDefinition) _then;

/// Create a copy of ShopDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? entries = null,Object? states = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<ShopEntryDefinition>,states: null == states ? _self.states : states // ignore: cast_nullable_to_non_nullable
as List<ShopStateDefinition>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopDefinition].
extension ShopDefinitionPatterns on ShopDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ShopDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ShopDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  List<ShopEntryDefinition> entries,  List<ShopStateDefinition> states)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopDefinition() when $default != null:
return $default(_that.id,_that.label,_that.entries,_that.states);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  List<ShopEntryDefinition> entries,  List<ShopStateDefinition> states)  $default,) {final _that = this;
switch (_that) {
case _ShopDefinition():
return $default(_that.id,_that.label,_that.entries,_that.states);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  List<ShopEntryDefinition> entries,  List<ShopStateDefinition> states)?  $default,) {final _that = this;
switch (_that) {
case _ShopDefinition() when $default != null:
return $default(_that.id,_that.label,_that.entries,_that.states);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ShopDefinition extends ShopDefinition {
  const _ShopDefinition({required this.id, required this.label, final  List<ShopEntryDefinition> entries = const [], final  List<ShopStateDefinition> states = const []}): _entries = entries,_states = states,super._();
  factory _ShopDefinition.fromJson(Map<String, dynamic> json) => _$ShopDefinitionFromJson(json);

@override final  String id;
@override final  String label;
 final  List<ShopEntryDefinition> _entries;
@override@JsonKey() List<ShopEntryDefinition> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<ShopStateDefinition> _states;
@override@JsonKey() List<ShopStateDefinition> get states {
  if (_states is EqualUnmodifiableListView) return _states;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_states);
}


/// Create a copy of ShopDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopDefinitionCopyWith<_ShopDefinition> get copyWith => __$ShopDefinitionCopyWithImpl<_ShopDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._states, _states));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_states));

@override
String toString() {
  return 'ShopDefinition(id: $id, label: $label, entries: $entries, states: $states)';
}


}

/// @nodoc
abstract mixin class _$ShopDefinitionCopyWith<$Res> implements $ShopDefinitionCopyWith<$Res> {
  factory _$ShopDefinitionCopyWith(_ShopDefinition value, $Res Function(_ShopDefinition) _then) = __$ShopDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, List<ShopEntryDefinition> entries, List<ShopStateDefinition> states
});




}
/// @nodoc
class __$ShopDefinitionCopyWithImpl<$Res>
    implements _$ShopDefinitionCopyWith<$Res> {
  __$ShopDefinitionCopyWithImpl(this._self, this._then);

  final _ShopDefinition _self;
  final $Res Function(_ShopDefinition) _then;

/// Create a copy of ShopDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? entries = null,Object? states = null,}) {
  return _then(_ShopDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<ShopEntryDefinition>,states: null == states ? _self._states : states // ignore: cast_nullable_to_non_nullable
as List<ShopStateDefinition>,
  ));
}


}

// dart format on
