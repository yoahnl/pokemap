// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_state_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShopStateDefinition {

 String get id; String get label;@JsonKey(fromJson: _shopStateIntegerFromJson) int get priority; ScriptCondition get activation; bool get isOpen; String? get storefrontLabel; String get welcomeMessage; String get closedMessage; List<ShopEntryDefinition> get entries;
/// Create a copy of ShopStateDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopStateDefinitionCopyWith<ShopStateDefinition> get copyWith => _$ShopStateDefinitionCopyWithImpl<ShopStateDefinition>(this as ShopStateDefinition, _$identity);

  /// Serializes this ShopStateDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopStateDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.activation, activation) || other.activation == activation)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.storefrontLabel, storefrontLabel) || other.storefrontLabel == storefrontLabel)&&(identical(other.welcomeMessage, welcomeMessage) || other.welcomeMessage == welcomeMessage)&&(identical(other.closedMessage, closedMessage) || other.closedMessage == closedMessage)&&const DeepCollectionEquality().equals(other.entries, entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,priority,activation,isOpen,storefrontLabel,welcomeMessage,closedMessage,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'ShopStateDefinition(id: $id, label: $label, priority: $priority, activation: $activation, isOpen: $isOpen, storefrontLabel: $storefrontLabel, welcomeMessage: $welcomeMessage, closedMessage: $closedMessage, entries: $entries)';
}


}

/// @nodoc
abstract mixin class $ShopStateDefinitionCopyWith<$Res>  {
  factory $ShopStateDefinitionCopyWith(ShopStateDefinition value, $Res Function(ShopStateDefinition) _then) = _$ShopStateDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String label,@JsonKey(fromJson: _shopStateIntegerFromJson) int priority, ScriptCondition activation, bool isOpen, String? storefrontLabel, String welcomeMessage, String closedMessage, List<ShopEntryDefinition> entries
});


$ScriptConditionCopyWith<$Res> get activation;

}
/// @nodoc
class _$ShopStateDefinitionCopyWithImpl<$Res>
    implements $ShopStateDefinitionCopyWith<$Res> {
  _$ShopStateDefinitionCopyWithImpl(this._self, this._then);

  final ShopStateDefinition _self;
  final $Res Function(ShopStateDefinition) _then;

/// Create a copy of ShopStateDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? priority = null,Object? activation = null,Object? isOpen = null,Object? storefrontLabel = freezed,Object? welcomeMessage = null,Object? closedMessage = null,Object? entries = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,activation: null == activation ? _self.activation : activation // ignore: cast_nullable_to_non_nullable
as ScriptCondition,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,storefrontLabel: freezed == storefrontLabel ? _self.storefrontLabel : storefrontLabel // ignore: cast_nullable_to_non_nullable
as String?,welcomeMessage: null == welcomeMessage ? _self.welcomeMessage : welcomeMessage // ignore: cast_nullable_to_non_nullable
as String,closedMessage: null == closedMessage ? _self.closedMessage : closedMessage // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<ShopEntryDefinition>,
  ));
}
/// Create a copy of ShopStateDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptConditionCopyWith<$Res> get activation {

  return $ScriptConditionCopyWith<$Res>(_self.activation, (value) {
    return _then(_self.copyWith(activation: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShopStateDefinition].
extension ShopStateDefinitionPatterns on ShopStateDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopStateDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopStateDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopStateDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ShopStateDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopStateDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ShopStateDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label, @JsonKey(fromJson: _shopStateIntegerFromJson)  int priority,  ScriptCondition activation,  bool isOpen,  String? storefrontLabel,  String welcomeMessage,  String closedMessage,  List<ShopEntryDefinition> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopStateDefinition() when $default != null:
return $default(_that.id,_that.label,_that.priority,_that.activation,_that.isOpen,_that.storefrontLabel,_that.welcomeMessage,_that.closedMessage,_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label, @JsonKey(fromJson: _shopStateIntegerFromJson)  int priority,  ScriptCondition activation,  bool isOpen,  String? storefrontLabel,  String welcomeMessage,  String closedMessage,  List<ShopEntryDefinition> entries)  $default,) {final _that = this;
switch (_that) {
case _ShopStateDefinition():
return $default(_that.id,_that.label,_that.priority,_that.activation,_that.isOpen,_that.storefrontLabel,_that.welcomeMessage,_that.closedMessage,_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label, @JsonKey(fromJson: _shopStateIntegerFromJson)  int priority,  ScriptCondition activation,  bool isOpen,  String? storefrontLabel,  String welcomeMessage,  String closedMessage,  List<ShopEntryDefinition> entries)?  $default,) {final _that = this;
switch (_that) {
case _ShopStateDefinition() when $default != null:
return $default(_that.id,_that.label,_that.priority,_that.activation,_that.isOpen,_that.storefrontLabel,_that.welcomeMessage,_that.closedMessage,_that.entries);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ShopStateDefinition extends ShopStateDefinition {
  const _ShopStateDefinition({required this.id, required this.label, @JsonKey(fromJson: _shopStateIntegerFromJson) this.priority = 0, required this.activation, this.isOpen = true, this.storefrontLabel, this.welcomeMessage = '', this.closedMessage = '', final  List<ShopEntryDefinition> entries = const <ShopEntryDefinition>[]}): _entries = entries,super._();
  factory _ShopStateDefinition.fromJson(Map<String, dynamic> json) => _$ShopStateDefinitionFromJson(json);

@override final  String id;
@override final  String label;
@override@JsonKey(fromJson: _shopStateIntegerFromJson) final  int priority;
@override final  ScriptCondition activation;
@override@JsonKey() final  bool isOpen;
@override final  String? storefrontLabel;
@override@JsonKey() final  String welcomeMessage;
@override@JsonKey() final  String closedMessage;
 final  List<ShopEntryDefinition> _entries;
@override@JsonKey() List<ShopEntryDefinition> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of ShopStateDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopStateDefinitionCopyWith<_ShopStateDefinition> get copyWith => __$ShopStateDefinitionCopyWithImpl<_ShopStateDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopStateDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopStateDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.activation, activation) || other.activation == activation)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.storefrontLabel, storefrontLabel) || other.storefrontLabel == storefrontLabel)&&(identical(other.welcomeMessage, welcomeMessage) || other.welcomeMessage == welcomeMessage)&&(identical(other.closedMessage, closedMessage) || other.closedMessage == closedMessage)&&const DeepCollectionEquality().equals(other._entries, _entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,priority,activation,isOpen,storefrontLabel,welcomeMessage,closedMessage,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'ShopStateDefinition(id: $id, label: $label, priority: $priority, activation: $activation, isOpen: $isOpen, storefrontLabel: $storefrontLabel, welcomeMessage: $welcomeMessage, closedMessage: $closedMessage, entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$ShopStateDefinitionCopyWith<$Res> implements $ShopStateDefinitionCopyWith<$Res> {
  factory _$ShopStateDefinitionCopyWith(_ShopStateDefinition value, $Res Function(_ShopStateDefinition) _then) = __$ShopStateDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label,@JsonKey(fromJson: _shopStateIntegerFromJson) int priority, ScriptCondition activation, bool isOpen, String? storefrontLabel, String welcomeMessage, String closedMessage, List<ShopEntryDefinition> entries
});


@override $ScriptConditionCopyWith<$Res> get activation;

}
/// @nodoc
class __$ShopStateDefinitionCopyWithImpl<$Res>
    implements _$ShopStateDefinitionCopyWith<$Res> {
  __$ShopStateDefinitionCopyWithImpl(this._self, this._then);

  final _ShopStateDefinition _self;
  final $Res Function(_ShopStateDefinition) _then;

/// Create a copy of ShopStateDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? priority = null,Object? activation = null,Object? isOpen = null,Object? storefrontLabel = freezed,Object? welcomeMessage = null,Object? closedMessage = null,Object? entries = null,}) {
  return _then(_ShopStateDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,activation: null == activation ? _self.activation : activation // ignore: cast_nullable_to_non_nullable
as ScriptCondition,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,storefrontLabel: freezed == storefrontLabel ? _self.storefrontLabel : storefrontLabel // ignore: cast_nullable_to_non_nullable
as String?,welcomeMessage: null == welcomeMessage ? _self.welcomeMessage : welcomeMessage // ignore: cast_nullable_to_non_nullable
as String,closedMessage: null == closedMessage ? _self.closedMessage : closedMessage // ignore: cast_nullable_to_non_nullable
as String,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<ShopEntryDefinition>,
  ));
}

/// Create a copy of ShopStateDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptConditionCopyWith<$Res> get activation {

  return $ScriptConditionCopyWith<$Res>(_self.activation, (value) {
    return _then(_self.copyWith(activation: value));
  });
}
}

// dart format on
