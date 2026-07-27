// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ShopEntryDefinition _$ShopEntryDefinitionFromJson(Map<String, dynamic> json) {
  return _ShopEntryDefinition.fromJson(json);
}

/// @nodoc
mixin _$ShopEntryDefinition {
  String get itemId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _shopIntegerFromJson)
  int get price => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _shopNullableIntegerFromJson)
  int? get sellPrice => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _shopNullableIntegerFromJson)
  int? get stock => throw _privateConstructorUsedError;

  /// Serializes this ShopEntryDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShopEntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShopEntryDefinitionCopyWith<ShopEntryDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShopEntryDefinitionCopyWith<$Res> {
  factory $ShopEntryDefinitionCopyWith(
          ShopEntryDefinition value, $Res Function(ShopEntryDefinition) then) =
      _$ShopEntryDefinitionCopyWithImpl<$Res, ShopEntryDefinition>;
  @useResult
  $Res call(
      {String itemId,
      @JsonKey(fromJson: _shopIntegerFromJson) int price,
      @JsonKey(fromJson: _shopNullableIntegerFromJson) int? sellPrice,
      @JsonKey(fromJson: _shopNullableIntegerFromJson) int? stock});
}

/// @nodoc
class _$ShopEntryDefinitionCopyWithImpl<$Res, $Val extends ShopEntryDefinition>
    implements $ShopEntryDefinitionCopyWith<$Res> {
  _$ShopEntryDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShopEntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? price = null,
    Object? sellPrice = freezed,
    Object? stock = freezed,
  }) {
    return _then(_value.copyWith(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as int,
      sellPrice: freezed == sellPrice
          ? _value.sellPrice
          : sellPrice // ignore: cast_nullable_to_non_nullable
              as int?,
      stock: freezed == stock
          ? _value.stock
          : stock // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShopEntryDefinitionImplCopyWith<$Res>
    implements $ShopEntryDefinitionCopyWith<$Res> {
  factory _$$ShopEntryDefinitionImplCopyWith(_$ShopEntryDefinitionImpl value,
          $Res Function(_$ShopEntryDefinitionImpl) then) =
      __$$ShopEntryDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String itemId,
      @JsonKey(fromJson: _shopIntegerFromJson) int price,
      @JsonKey(fromJson: _shopNullableIntegerFromJson) int? sellPrice,
      @JsonKey(fromJson: _shopNullableIntegerFromJson) int? stock});
}

/// @nodoc
class __$$ShopEntryDefinitionImplCopyWithImpl<$Res>
    extends _$ShopEntryDefinitionCopyWithImpl<$Res, _$ShopEntryDefinitionImpl>
    implements _$$ShopEntryDefinitionImplCopyWith<$Res> {
  __$$ShopEntryDefinitionImplCopyWithImpl(_$ShopEntryDefinitionImpl _value,
      $Res Function(_$ShopEntryDefinitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ShopEntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? price = null,
    Object? sellPrice = freezed,
    Object? stock = freezed,
  }) {
    return _then(_$ShopEntryDefinitionImpl(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as int,
      sellPrice: freezed == sellPrice
          ? _value.sellPrice
          : sellPrice // ignore: cast_nullable_to_non_nullable
              as int?,
      stock: freezed == stock
          ? _value.stock
          : stock // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ShopEntryDefinitionImpl extends _ShopEntryDefinition {
  const _$ShopEntryDefinitionImpl(
      {required this.itemId,
      @JsonKey(fromJson: _shopIntegerFromJson) required this.price,
      @JsonKey(fromJson: _shopNullableIntegerFromJson) this.sellPrice,
      @JsonKey(fromJson: _shopNullableIntegerFromJson) this.stock})
      : super._();

  factory _$ShopEntryDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShopEntryDefinitionImplFromJson(json);

  @override
  final String itemId;
  @override
  @JsonKey(fromJson: _shopIntegerFromJson)
  final int price;
  @override
  @JsonKey(fromJson: _shopNullableIntegerFromJson)
  final int? sellPrice;
  @override
  @JsonKey(fromJson: _shopNullableIntegerFromJson)
  final int? stock;

  @override
  String toString() {
    return 'ShopEntryDefinition(itemId: $itemId, price: $price, sellPrice: $sellPrice, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShopEntryDefinitionImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.sellPrice, sellPrice) ||
                other.sellPrice == sellPrice) &&
            (identical(other.stock, stock) || other.stock == stock));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, itemId, price, sellPrice, stock);

  /// Create a copy of ShopEntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShopEntryDefinitionImplCopyWith<_$ShopEntryDefinitionImpl> get copyWith =>
      __$$ShopEntryDefinitionImplCopyWithImpl<_$ShopEntryDefinitionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShopEntryDefinitionImplToJson(
      this,
    );
  }
}

abstract class _ShopEntryDefinition extends ShopEntryDefinition {
  const factory _ShopEntryDefinition(
          {required final String itemId,
          @JsonKey(fromJson: _shopIntegerFromJson) required final int price,
          @JsonKey(fromJson: _shopNullableIntegerFromJson) final int? sellPrice,
          @JsonKey(fromJson: _shopNullableIntegerFromJson) final int? stock}) =
      _$ShopEntryDefinitionImpl;
  const _ShopEntryDefinition._() : super._();

  factory _ShopEntryDefinition.fromJson(Map<String, dynamic> json) =
      _$ShopEntryDefinitionImpl.fromJson;

  @override
  String get itemId;
  @override
  @JsonKey(fromJson: _shopIntegerFromJson)
  int get price;
  @override
  @JsonKey(fromJson: _shopNullableIntegerFromJson)
  int? get sellPrice;
  @override
  @JsonKey(fromJson: _shopNullableIntegerFromJson)
  int? get stock;

  /// Create a copy of ShopEntryDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShopEntryDefinitionImplCopyWith<_$ShopEntryDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ShopDefinition _$ShopDefinitionFromJson(Map<String, dynamic> json) {
  return _ShopDefinition.fromJson(json);
}

/// @nodoc
mixin _$ShopDefinition {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  List<ShopEntryDefinition> get entries => throw _privateConstructorUsedError;
  List<ShopStateDefinition> get states => throw _privateConstructorUsedError;

  /// Serializes this ShopDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShopDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShopDefinitionCopyWith<ShopDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShopDefinitionCopyWith<$Res> {
  factory $ShopDefinitionCopyWith(
          ShopDefinition value, $Res Function(ShopDefinition) then) =
      _$ShopDefinitionCopyWithImpl<$Res, ShopDefinition>;
  @useResult
  $Res call(
      {String id,
      String label,
      List<ShopEntryDefinition> entries,
      List<ShopStateDefinition> states});
}

/// @nodoc
class _$ShopDefinitionCopyWithImpl<$Res, $Val extends ShopDefinition>
    implements $ShopDefinitionCopyWith<$Res> {
  _$ShopDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShopDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? entries = null,
    Object? states = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<ShopEntryDefinition>,
      states: null == states
          ? _value.states
          : states // ignore: cast_nullable_to_non_nullable
              as List<ShopStateDefinition>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShopDefinitionImplCopyWith<$Res>
    implements $ShopDefinitionCopyWith<$Res> {
  factory _$$ShopDefinitionImplCopyWith(_$ShopDefinitionImpl value,
          $Res Function(_$ShopDefinitionImpl) then) =
      __$$ShopDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      List<ShopEntryDefinition> entries,
      List<ShopStateDefinition> states});
}

/// @nodoc
class __$$ShopDefinitionImplCopyWithImpl<$Res>
    extends _$ShopDefinitionCopyWithImpl<$Res, _$ShopDefinitionImpl>
    implements _$$ShopDefinitionImplCopyWith<$Res> {
  __$$ShopDefinitionImplCopyWithImpl(
      _$ShopDefinitionImpl _value, $Res Function(_$ShopDefinitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ShopDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? entries = null,
    Object? states = null,
  }) {
    return _then(_$ShopDefinitionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      entries: null == entries
          ? _value._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<ShopEntryDefinition>,
      states: null == states
          ? _value._states
          : states // ignore: cast_nullable_to_non_nullable
              as List<ShopStateDefinition>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ShopDefinitionImpl extends _ShopDefinition {
  const _$ShopDefinitionImpl(
      {required this.id,
      required this.label,
      final List<ShopEntryDefinition> entries = const [],
      final List<ShopStateDefinition> states = const []})
      : _entries = entries,
        _states = states,
        super._();

  factory _$ShopDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShopDefinitionImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  final List<ShopEntryDefinition> _entries;
  @override
  @JsonKey()
  List<ShopEntryDefinition> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  final List<ShopStateDefinition> _states;
  @override
  @JsonKey()
  List<ShopStateDefinition> get states {
    if (_states is EqualUnmodifiableListView) return _states;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_states);
  }

  @override
  String toString() {
    return 'ShopDefinition(id: $id, label: $label, entries: $entries, states: $states)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShopDefinitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            const DeepCollectionEquality().equals(other._entries, _entries) &&
            const DeepCollectionEquality().equals(other._states, _states));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      label,
      const DeepCollectionEquality().hash(_entries),
      const DeepCollectionEquality().hash(_states));

  /// Create a copy of ShopDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShopDefinitionImplCopyWith<_$ShopDefinitionImpl> get copyWith =>
      __$$ShopDefinitionImplCopyWithImpl<_$ShopDefinitionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShopDefinitionImplToJson(
      this,
    );
  }
}

abstract class _ShopDefinition extends ShopDefinition {
  const factory _ShopDefinition(
      {required final String id,
      required final String label,
      final List<ShopEntryDefinition> entries,
      final List<ShopStateDefinition> states}) = _$ShopDefinitionImpl;
  const _ShopDefinition._() : super._();

  factory _ShopDefinition.fromJson(Map<String, dynamic> json) =
      _$ShopDefinitionImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  List<ShopEntryDefinition> get entries;
  @override
  List<ShopStateDefinition> get states;

  /// Create a copy of ShopDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShopDefinitionImplCopyWith<_$ShopDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
