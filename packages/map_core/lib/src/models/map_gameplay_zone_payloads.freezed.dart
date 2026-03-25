// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_gameplay_zone_payloads.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EncounterZonePayload _$EncounterZonePayloadFromJson(Map<String, dynamic> json) {
  return _EncounterZonePayload.fromJson(json);
}

/// @nodoc
mixin _$EncounterZonePayload {
  /// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
  String? get encounterTableId => throw _privateConstructorUsedError;

  /// Type de rencontre déclenchée dans cette zone.
  EncounterKind get encounterKind => throw _privateConstructorUsedError;

  /// Serializes this EncounterZonePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EncounterZonePayloadCopyWith<EncounterZonePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EncounterZonePayloadCopyWith<$Res> {
  factory $EncounterZonePayloadCopyWith(EncounterZonePayload value,
          $Res Function(EncounterZonePayload) then) =
      _$EncounterZonePayloadCopyWithImpl<$Res, EncounterZonePayload>;
  @useResult
  $Res call({String? encounterTableId, EncounterKind encounterKind});
}

/// @nodoc
class _$EncounterZonePayloadCopyWithImpl<$Res,
        $Val extends EncounterZonePayload>
    implements $EncounterZonePayloadCopyWith<$Res> {
  _$EncounterZonePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? encounterTableId = freezed,
    Object? encounterKind = null,
  }) {
    return _then(_value.copyWith(
      encounterTableId: freezed == encounterTableId
          ? _value.encounterTableId
          : encounterTableId // ignore: cast_nullable_to_non_nullable
              as String?,
      encounterKind: null == encounterKind
          ? _value.encounterKind
          : encounterKind // ignore: cast_nullable_to_non_nullable
              as EncounterKind,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EncounterZonePayloadImplCopyWith<$Res>
    implements $EncounterZonePayloadCopyWith<$Res> {
  factory _$$EncounterZonePayloadImplCopyWith(_$EncounterZonePayloadImpl value,
          $Res Function(_$EncounterZonePayloadImpl) then) =
      __$$EncounterZonePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? encounterTableId, EncounterKind encounterKind});
}

/// @nodoc
class __$$EncounterZonePayloadImplCopyWithImpl<$Res>
    extends _$EncounterZonePayloadCopyWithImpl<$Res, _$EncounterZonePayloadImpl>
    implements _$$EncounterZonePayloadImplCopyWith<$Res> {
  __$$EncounterZonePayloadImplCopyWithImpl(_$EncounterZonePayloadImpl _value,
      $Res Function(_$EncounterZonePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? encounterTableId = freezed,
    Object? encounterKind = null,
  }) {
    return _then(_$EncounterZonePayloadImpl(
      encounterTableId: freezed == encounterTableId
          ? _value.encounterTableId
          : encounterTableId // ignore: cast_nullable_to_non_nullable
              as String?,
      encounterKind: null == encounterKind
          ? _value.encounterKind
          : encounterKind // ignore: cast_nullable_to_non_nullable
              as EncounterKind,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$EncounterZonePayloadImpl implements _EncounterZonePayload {
  const _$EncounterZonePayloadImpl(
      {this.encounterTableId, this.encounterKind = EncounterKind.walk});

  factory _$EncounterZonePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$EncounterZonePayloadImplFromJson(json);

  /// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
  @override
  final String? encounterTableId;

  /// Type de rencontre déclenchée dans cette zone.
  @override
  @JsonKey()
  final EncounterKind encounterKind;

  @override
  String toString() {
    return 'EncounterZonePayload(encounterTableId: $encounterTableId, encounterKind: $encounterKind)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EncounterZonePayloadImpl &&
            (identical(other.encounterTableId, encounterTableId) ||
                other.encounterTableId == encounterTableId) &&
            (identical(other.encounterKind, encounterKind) ||
                other.encounterKind == encounterKind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, encounterTableId, encounterKind);

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EncounterZonePayloadImplCopyWith<_$EncounterZonePayloadImpl>
      get copyWith =>
          __$$EncounterZonePayloadImplCopyWithImpl<_$EncounterZonePayloadImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EncounterZonePayloadImplToJson(
      this,
    );
  }
}

abstract class _EncounterZonePayload implements EncounterZonePayload {
  const factory _EncounterZonePayload(
      {final String? encounterTableId,
      final EncounterKind encounterKind}) = _$EncounterZonePayloadImpl;

  factory _EncounterZonePayload.fromJson(Map<String, dynamic> json) =
      _$EncounterZonePayloadImpl.fromJson;

  /// ID de la [ProjectEncounterTable] du projet (optionnel — zone sans table = inerte).
  @override
  String? get encounterTableId;

  /// Type de rencontre déclenchée dans cette zone.
  @override
  EncounterKind get encounterKind;

  /// Create a copy of EncounterZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EncounterZonePayloadImplCopyWith<_$EncounterZonePayloadImpl>
      get copyWith => throw _privateConstructorUsedError;
}

MovementZonePayload _$MovementZonePayloadFromJson(Map<String, dynamic> json) {
  return _MovementZonePayload.fromJson(json);
}

/// @nodoc
mixin _$MovementZonePayload {
  /// Mode de déplacement requis pour traverser la zone.
  MovementMode get requiredMode => throw _privateConstructorUsedError;

  /// Modes supplémentaires autorisés en plus de [requiredMode].
  List<MovementMode> get allowedModes => throw _privateConstructorUsedError;

  /// Serializes this MovementZonePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MovementZonePayloadCopyWith<MovementZonePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MovementZonePayloadCopyWith<$Res> {
  factory $MovementZonePayloadCopyWith(
          MovementZonePayload value, $Res Function(MovementZonePayload) then) =
      _$MovementZonePayloadCopyWithImpl<$Res, MovementZonePayload>;
  @useResult
  $Res call({MovementMode requiredMode, List<MovementMode> allowedModes});
}

/// @nodoc
class _$MovementZonePayloadCopyWithImpl<$Res, $Val extends MovementZonePayload>
    implements $MovementZonePayloadCopyWith<$Res> {
  _$MovementZonePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requiredMode = null,
    Object? allowedModes = null,
  }) {
    return _then(_value.copyWith(
      requiredMode: null == requiredMode
          ? _value.requiredMode
          : requiredMode // ignore: cast_nullable_to_non_nullable
              as MovementMode,
      allowedModes: null == allowedModes
          ? _value.allowedModes
          : allowedModes // ignore: cast_nullable_to_non_nullable
              as List<MovementMode>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MovementZonePayloadImplCopyWith<$Res>
    implements $MovementZonePayloadCopyWith<$Res> {
  factory _$$MovementZonePayloadImplCopyWith(_$MovementZonePayloadImpl value,
          $Res Function(_$MovementZonePayloadImpl) then) =
      __$$MovementZonePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MovementMode requiredMode, List<MovementMode> allowedModes});
}

/// @nodoc
class __$$MovementZonePayloadImplCopyWithImpl<$Res>
    extends _$MovementZonePayloadCopyWithImpl<$Res, _$MovementZonePayloadImpl>
    implements _$$MovementZonePayloadImplCopyWith<$Res> {
  __$$MovementZonePayloadImplCopyWithImpl(_$MovementZonePayloadImpl _value,
      $Res Function(_$MovementZonePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requiredMode = null,
    Object? allowedModes = null,
  }) {
    return _then(_$MovementZonePayloadImpl(
      requiredMode: null == requiredMode
          ? _value.requiredMode
          : requiredMode // ignore: cast_nullable_to_non_nullable
              as MovementMode,
      allowedModes: null == allowedModes
          ? _value._allowedModes
          : allowedModes // ignore: cast_nullable_to_non_nullable
              as List<MovementMode>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MovementZonePayloadImpl implements _MovementZonePayload {
  const _$MovementZonePayloadImpl(
      {this.requiredMode = MovementMode.walk,
      final List<MovementMode> allowedModes = const []})
      : _allowedModes = allowedModes;

  factory _$MovementZonePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$MovementZonePayloadImplFromJson(json);

  /// Mode de déplacement requis pour traverser la zone.
  @override
  @JsonKey()
  final MovementMode requiredMode;

  /// Modes supplémentaires autorisés en plus de [requiredMode].
  final List<MovementMode> _allowedModes;

  /// Modes supplémentaires autorisés en plus de [requiredMode].
  @override
  @JsonKey()
  List<MovementMode> get allowedModes {
    if (_allowedModes is EqualUnmodifiableListView) return _allowedModes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allowedModes);
  }

  @override
  String toString() {
    return 'MovementZonePayload(requiredMode: $requiredMode, allowedModes: $allowedModes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MovementZonePayloadImpl &&
            (identical(other.requiredMode, requiredMode) ||
                other.requiredMode == requiredMode) &&
            const DeepCollectionEquality()
                .equals(other._allowedModes, _allowedModes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, requiredMode,
      const DeepCollectionEquality().hash(_allowedModes));

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MovementZonePayloadImplCopyWith<_$MovementZonePayloadImpl> get copyWith =>
      __$$MovementZonePayloadImplCopyWithImpl<_$MovementZonePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MovementZonePayloadImplToJson(
      this,
    );
  }
}

abstract class _MovementZonePayload implements MovementZonePayload {
  const factory _MovementZonePayload(
      {final MovementMode requiredMode,
      final List<MovementMode> allowedModes}) = _$MovementZonePayloadImpl;

  factory _MovementZonePayload.fromJson(Map<String, dynamic> json) =
      _$MovementZonePayloadImpl.fromJson;

  /// Mode de déplacement requis pour traverser la zone.
  @override
  MovementMode get requiredMode;

  /// Modes supplémentaires autorisés en plus de [requiredMode].
  @override
  List<MovementMode> get allowedModes;

  /// Create a copy of MovementZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MovementZonePayloadImplCopyWith<_$MovementZonePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HazardZonePayload _$HazardZonePayloadFromJson(Map<String, dynamic> json) {
  return _HazardZonePayload.fromJson(json);
}

/// @nodoc
mixin _$HazardZonePayload {
  HazardKind get hazardKind => throw _privateConstructorUsedError;

  /// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
  int get damagePerStep => throw _privateConstructorUsedError;

  /// Serializes this HazardZonePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HazardZonePayloadCopyWith<HazardZonePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HazardZonePayloadCopyWith<$Res> {
  factory $HazardZonePayloadCopyWith(
          HazardZonePayload value, $Res Function(HazardZonePayload) then) =
      _$HazardZonePayloadCopyWithImpl<$Res, HazardZonePayload>;
  @useResult
  $Res call({HazardKind hazardKind, int damagePerStep});
}

/// @nodoc
class _$HazardZonePayloadCopyWithImpl<$Res, $Val extends HazardZonePayload>
    implements $HazardZonePayloadCopyWith<$Res> {
  _$HazardZonePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hazardKind = null,
    Object? damagePerStep = null,
  }) {
    return _then(_value.copyWith(
      hazardKind: null == hazardKind
          ? _value.hazardKind
          : hazardKind // ignore: cast_nullable_to_non_nullable
              as HazardKind,
      damagePerStep: null == damagePerStep
          ? _value.damagePerStep
          : damagePerStep // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HazardZonePayloadImplCopyWith<$Res>
    implements $HazardZonePayloadCopyWith<$Res> {
  factory _$$HazardZonePayloadImplCopyWith(_$HazardZonePayloadImpl value,
          $Res Function(_$HazardZonePayloadImpl) then) =
      __$$HazardZonePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({HazardKind hazardKind, int damagePerStep});
}

/// @nodoc
class __$$HazardZonePayloadImplCopyWithImpl<$Res>
    extends _$HazardZonePayloadCopyWithImpl<$Res, _$HazardZonePayloadImpl>
    implements _$$HazardZonePayloadImplCopyWith<$Res> {
  __$$HazardZonePayloadImplCopyWithImpl(_$HazardZonePayloadImpl _value,
      $Res Function(_$HazardZonePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hazardKind = null,
    Object? damagePerStep = null,
  }) {
    return _then(_$HazardZonePayloadImpl(
      hazardKind: null == hazardKind
          ? _value.hazardKind
          : hazardKind // ignore: cast_nullable_to_non_nullable
              as HazardKind,
      damagePerStep: null == damagePerStep
          ? _value.damagePerStep
          : damagePerStep // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$HazardZonePayloadImpl implements _HazardZonePayload {
  const _$HazardZonePayloadImpl(
      {this.hazardKind = HazardKind.other, this.damagePerStep = 0});

  factory _$HazardZonePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$HazardZonePayloadImplFromJson(json);

  @override
  @JsonKey()
  final HazardKind hazardKind;

  /// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
  @override
  @JsonKey()
  final int damagePerStep;

  @override
  String toString() {
    return 'HazardZonePayload(hazardKind: $hazardKind, damagePerStep: $damagePerStep)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HazardZonePayloadImpl &&
            (identical(other.hazardKind, hazardKind) ||
                other.hazardKind == hazardKind) &&
            (identical(other.damagePerStep, damagePerStep) ||
                other.damagePerStep == damagePerStep));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, hazardKind, damagePerStep);

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HazardZonePayloadImplCopyWith<_$HazardZonePayloadImpl> get copyWith =>
      __$$HazardZonePayloadImplCopyWithImpl<_$HazardZonePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HazardZonePayloadImplToJson(
      this,
    );
  }
}

abstract class _HazardZonePayload implements HazardZonePayload {
  const factory _HazardZonePayload(
      {final HazardKind hazardKind,
      final int damagePerStep}) = _$HazardZonePayloadImpl;

  factory _HazardZonePayload.fromJson(Map<String, dynamic> json) =
      _$HazardZonePayloadImpl.fromJson;

  @override
  HazardKind get hazardKind;

  /// Dommages infligés à chaque pas dans la zone (0 = aucun dommage direct).
  @override
  int get damagePerStep;

  /// Create a copy of HazardZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HazardZonePayloadImplCopyWith<_$HazardZonePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpecialZonePayload _$SpecialZonePayloadFromJson(Map<String, dynamic> json) {
  return _SpecialZonePayload.fromJson(json);
}

/// @nodoc
mixin _$SpecialZonePayload {
  /// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
  String? get scriptKey => throw _privateConstructorUsedError;

  /// Propriétés libres (clé → valeur).
  Map<String, String> get properties => throw _privateConstructorUsedError;

  /// Serializes this SpecialZonePayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SpecialZonePayloadCopyWith<SpecialZonePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpecialZonePayloadCopyWith<$Res> {
  factory $SpecialZonePayloadCopyWith(
          SpecialZonePayload value, $Res Function(SpecialZonePayload) then) =
      _$SpecialZonePayloadCopyWithImpl<$Res, SpecialZonePayload>;
  @useResult
  $Res call({String? scriptKey, Map<String, String> properties});
}

/// @nodoc
class _$SpecialZonePayloadCopyWithImpl<$Res, $Val extends SpecialZonePayload>
    implements $SpecialZonePayloadCopyWith<$Res> {
  _$SpecialZonePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scriptKey = freezed,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      scriptKey: freezed == scriptKey
          ? _value.scriptKey
          : scriptKey // ignore: cast_nullable_to_non_nullable
              as String?,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SpecialZonePayloadImplCopyWith<$Res>
    implements $SpecialZonePayloadCopyWith<$Res> {
  factory _$$SpecialZonePayloadImplCopyWith(_$SpecialZonePayloadImpl value,
          $Res Function(_$SpecialZonePayloadImpl) then) =
      __$$SpecialZonePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? scriptKey, Map<String, String> properties});
}

/// @nodoc
class __$$SpecialZonePayloadImplCopyWithImpl<$Res>
    extends _$SpecialZonePayloadCopyWithImpl<$Res, _$SpecialZonePayloadImpl>
    implements _$$SpecialZonePayloadImplCopyWith<$Res> {
  __$$SpecialZonePayloadImplCopyWithImpl(_$SpecialZonePayloadImpl _value,
      $Res Function(_$SpecialZonePayloadImpl) _then)
      : super(_value, _then);

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scriptKey = freezed,
    Object? properties = null,
  }) {
    return _then(_$SpecialZonePayloadImpl(
      scriptKey: freezed == scriptKey
          ? _value.scriptKey
          : scriptKey // ignore: cast_nullable_to_non_nullable
              as String?,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SpecialZonePayloadImpl implements _SpecialZonePayload {
  const _$SpecialZonePayloadImpl(
      {this.scriptKey, final Map<String, String> properties = const {}})
      : _properties = properties;

  factory _$SpecialZonePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpecialZonePayloadImplFromJson(json);

  /// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
  @override
  final String? scriptKey;

  /// Propriétés libres (clé → valeur).
  final Map<String, String> _properties;

  /// Propriétés libres (clé → valeur).
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'SpecialZonePayload(scriptKey: $scriptKey, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpecialZonePayloadImpl &&
            (identical(other.scriptKey, scriptKey) ||
                other.scriptKey == scriptKey) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, scriptKey, const DeepCollectionEquality().hash(_properties));

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SpecialZonePayloadImplCopyWith<_$SpecialZonePayloadImpl> get copyWith =>
      __$$SpecialZonePayloadImplCopyWithImpl<_$SpecialZonePayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpecialZonePayloadImplToJson(
      this,
    );
  }
}

abstract class _SpecialZonePayload implements SpecialZonePayload {
  const factory _SpecialZonePayload(
      {final String? scriptKey,
      final Map<String, String> properties}) = _$SpecialZonePayloadImpl;

  factory _SpecialZonePayload.fromJson(Map<String, dynamic> json) =
      _$SpecialZonePayloadImpl.fromJson;

  /// Clé de script rattachée à cette zone (ex. identifiant Yarn / EventGraph).
  @override
  String? get scriptKey;

  /// Propriétés libres (clé → valeur).
  @override
  Map<String, String> get properties;

  /// Create a copy of SpecialZonePayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SpecialZonePayloadImplCopyWith<_$SpecialZonePayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
