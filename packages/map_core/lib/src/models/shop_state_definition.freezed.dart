// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_state_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ShopStateDefinition _$ShopStateDefinitionFromJson(Map<String, dynamic> json) {
  return _ShopStateDefinition.fromJson(json);
}

/// @nodoc
mixin _$ShopStateDefinition {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _shopStateIntegerFromJson)
  int get priority => throw _privateConstructorUsedError;
  ScriptCondition get activation => throw _privateConstructorUsedError;
  bool get isOpen => throw _privateConstructorUsedError;
  String? get storefrontLabel => throw _privateConstructorUsedError;
  String get welcomeMessage => throw _privateConstructorUsedError;
  String get closedMessage => throw _privateConstructorUsedError;
  List<ShopEntryDefinition> get entries => throw _privateConstructorUsedError;

  /// Serializes this ShopStateDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShopStateDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShopStateDefinitionCopyWith<ShopStateDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShopStateDefinitionCopyWith<$Res> {
  factory $ShopStateDefinitionCopyWith(
          ShopStateDefinition value, $Res Function(ShopStateDefinition) then) =
      _$ShopStateDefinitionCopyWithImpl<$Res, ShopStateDefinition>;
  @useResult
  $Res call(
      {String id,
      String label,
      @JsonKey(fromJson: _shopStateIntegerFromJson) int priority,
      ScriptCondition activation,
      bool isOpen,
      String? storefrontLabel,
      String welcomeMessage,
      String closedMessage,
      List<ShopEntryDefinition> entries});

  $ScriptConditionCopyWith<$Res> get activation;
}

/// @nodoc
class _$ShopStateDefinitionCopyWithImpl<$Res, $Val extends ShopStateDefinition>
    implements $ShopStateDefinitionCopyWith<$Res> {
  _$ShopStateDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShopStateDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? priority = null,
    Object? activation = null,
    Object? isOpen = null,
    Object? storefrontLabel = freezed,
    Object? welcomeMessage = null,
    Object? closedMessage = null,
    Object? entries = null,
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
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      activation: null == activation
          ? _value.activation
          : activation // ignore: cast_nullable_to_non_nullable
              as ScriptCondition,
      isOpen: null == isOpen
          ? _value.isOpen
          : isOpen // ignore: cast_nullable_to_non_nullable
              as bool,
      storefrontLabel: freezed == storefrontLabel
          ? _value.storefrontLabel
          : storefrontLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      welcomeMessage: null == welcomeMessage
          ? _value.welcomeMessage
          : welcomeMessage // ignore: cast_nullable_to_non_nullable
              as String,
      closedMessage: null == closedMessage
          ? _value.closedMessage
          : closedMessage // ignore: cast_nullable_to_non_nullable
              as String,
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<ShopEntryDefinition>,
    ) as $Val);
  }

  /// Create a copy of ShopStateDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptConditionCopyWith<$Res> get activation {
    return $ScriptConditionCopyWith<$Res>(_value.activation, (value) {
      return _then(_value.copyWith(activation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ShopStateDefinitionImplCopyWith<$Res>
    implements $ShopStateDefinitionCopyWith<$Res> {
  factory _$$ShopStateDefinitionImplCopyWith(_$ShopStateDefinitionImpl value,
          $Res Function(_$ShopStateDefinitionImpl) then) =
      __$$ShopStateDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      @JsonKey(fromJson: _shopStateIntegerFromJson) int priority,
      ScriptCondition activation,
      bool isOpen,
      String? storefrontLabel,
      String welcomeMessage,
      String closedMessage,
      List<ShopEntryDefinition> entries});

  @override
  $ScriptConditionCopyWith<$Res> get activation;
}

/// @nodoc
class __$$ShopStateDefinitionImplCopyWithImpl<$Res>
    extends _$ShopStateDefinitionCopyWithImpl<$Res, _$ShopStateDefinitionImpl>
    implements _$$ShopStateDefinitionImplCopyWith<$Res> {
  __$$ShopStateDefinitionImplCopyWithImpl(_$ShopStateDefinitionImpl _value,
      $Res Function(_$ShopStateDefinitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ShopStateDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? priority = null,
    Object? activation = null,
    Object? isOpen = null,
    Object? storefrontLabel = freezed,
    Object? welcomeMessage = null,
    Object? closedMessage = null,
    Object? entries = null,
  }) {
    return _then(_$ShopStateDefinitionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      activation: null == activation
          ? _value.activation
          : activation // ignore: cast_nullable_to_non_nullable
              as ScriptCondition,
      isOpen: null == isOpen
          ? _value.isOpen
          : isOpen // ignore: cast_nullable_to_non_nullable
              as bool,
      storefrontLabel: freezed == storefrontLabel
          ? _value.storefrontLabel
          : storefrontLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      welcomeMessage: null == welcomeMessage
          ? _value.welcomeMessage
          : welcomeMessage // ignore: cast_nullable_to_non_nullable
              as String,
      closedMessage: null == closedMessage
          ? _value.closedMessage
          : closedMessage // ignore: cast_nullable_to_non_nullable
              as String,
      entries: null == entries
          ? _value._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<ShopEntryDefinition>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ShopStateDefinitionImpl extends _ShopStateDefinition {
  const _$ShopStateDefinitionImpl(
      {required this.id,
      required this.label,
      @JsonKey(fromJson: _shopStateIntegerFromJson) this.priority = 0,
      required this.activation,
      this.isOpen = true,
      this.storefrontLabel,
      this.welcomeMessage = '',
      this.closedMessage = '',
      final List<ShopEntryDefinition> entries = const <ShopEntryDefinition>[]})
      : _entries = entries,
        super._();

  factory _$ShopStateDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShopStateDefinitionImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  @JsonKey(fromJson: _shopStateIntegerFromJson)
  final int priority;
  @override
  final ScriptCondition activation;
  @override
  @JsonKey()
  final bool isOpen;
  @override
  final String? storefrontLabel;
  @override
  @JsonKey()
  final String welcomeMessage;
  @override
  @JsonKey()
  final String closedMessage;
  final List<ShopEntryDefinition> _entries;
  @override
  @JsonKey()
  List<ShopEntryDefinition> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @override
  String toString() {
    return 'ShopStateDefinition(id: $id, label: $label, priority: $priority, activation: $activation, isOpen: $isOpen, storefrontLabel: $storefrontLabel, welcomeMessage: $welcomeMessage, closedMessage: $closedMessage, entries: $entries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShopStateDefinitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.activation, activation) ||
                other.activation == activation) &&
            (identical(other.isOpen, isOpen) || other.isOpen == isOpen) &&
            (identical(other.storefrontLabel, storefrontLabel) ||
                other.storefrontLabel == storefrontLabel) &&
            (identical(other.welcomeMessage, welcomeMessage) ||
                other.welcomeMessage == welcomeMessage) &&
            (identical(other.closedMessage, closedMessage) ||
                other.closedMessage == closedMessage) &&
            const DeepCollectionEquality().equals(other._entries, _entries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      label,
      priority,
      activation,
      isOpen,
      storefrontLabel,
      welcomeMessage,
      closedMessage,
      const DeepCollectionEquality().hash(_entries));

  /// Create a copy of ShopStateDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShopStateDefinitionImplCopyWith<_$ShopStateDefinitionImpl> get copyWith =>
      __$$ShopStateDefinitionImplCopyWithImpl<_$ShopStateDefinitionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShopStateDefinitionImplToJson(
      this,
    );
  }
}

abstract class _ShopStateDefinition extends ShopStateDefinition {
  const factory _ShopStateDefinition(
      {required final String id,
      required final String label,
      @JsonKey(fromJson: _shopStateIntegerFromJson) final int priority,
      required final ScriptCondition activation,
      final bool isOpen,
      final String? storefrontLabel,
      final String welcomeMessage,
      final String closedMessage,
      final List<ShopEntryDefinition> entries}) = _$ShopStateDefinitionImpl;
  const _ShopStateDefinition._() : super._();

  factory _ShopStateDefinition.fromJson(Map<String, dynamic> json) =
      _$ShopStateDefinitionImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  @JsonKey(fromJson: _shopStateIntegerFromJson)
  int get priority;
  @override
  ScriptCondition get activation;
  @override
  bool get isOpen;
  @override
  String? get storefrontLabel;
  @override
  String get welcomeMessage;
  @override
  String get closedMessage;
  @override
  List<ShopEntryDefinition> get entries;

  /// Create a copy of ShopStateDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShopStateDefinitionImplCopyWith<_$ShopStateDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
