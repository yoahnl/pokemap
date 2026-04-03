// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_entity_payloads.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DialogueRef _$DialogueRefFromJson(Map<String, dynamic> json) {
  return _DialogueRef.fromJson(json);
}

/// @nodoc
mixin _$DialogueRef {
  /// Identifiant stable : typiquement [ProjectDialogueEntry.id] lorsque [scriptPathRelative] est vide.
  String get dialogueId => throw _privateConstructorUsedError;

  /// Vide = résolution via le registre projet ; non vide = script explicite (legacy ou override).
  String get scriptPathRelative => throw _privateConstructorUsedError;

  /// Nœud d’entrée optionnel (ex. titre de nœud Yarn).
  String? get startNode => throw _privateConstructorUsedError;

  /// Serializes this DialogueRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DialogueRefCopyWith<DialogueRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DialogueRefCopyWith<$Res> {
  factory $DialogueRefCopyWith(
          DialogueRef value, $Res Function(DialogueRef) then) =
      _$DialogueRefCopyWithImpl<$Res, DialogueRef>;
  @useResult
  $Res call({String dialogueId, String scriptPathRelative, String? startNode});
}

/// @nodoc
class _$DialogueRefCopyWithImpl<$Res, $Val extends DialogueRef>
    implements $DialogueRefCopyWith<$Res> {
  _$DialogueRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dialogueId = null,
    Object? scriptPathRelative = null,
    Object? startNode = freezed,
  }) {
    return _then(_value.copyWith(
      dialogueId: null == dialogueId
          ? _value.dialogueId
          : dialogueId // ignore: cast_nullable_to_non_nullable
              as String,
      scriptPathRelative: null == scriptPathRelative
          ? _value.scriptPathRelative
          : scriptPathRelative // ignore: cast_nullable_to_non_nullable
              as String,
      startNode: freezed == startNode
          ? _value.startNode
          : startNode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DialogueRefImplCopyWith<$Res>
    implements $DialogueRefCopyWith<$Res> {
  factory _$$DialogueRefImplCopyWith(
          _$DialogueRefImpl value, $Res Function(_$DialogueRefImpl) then) =
      __$$DialogueRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String dialogueId, String scriptPathRelative, String? startNode});
}

/// @nodoc
class __$$DialogueRefImplCopyWithImpl<$Res>
    extends _$DialogueRefCopyWithImpl<$Res, _$DialogueRefImpl>
    implements _$$DialogueRefImplCopyWith<$Res> {
  __$$DialogueRefImplCopyWithImpl(
      _$DialogueRefImpl _value, $Res Function(_$DialogueRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of DialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dialogueId = null,
    Object? scriptPathRelative = null,
    Object? startNode = freezed,
  }) {
    return _then(_$DialogueRefImpl(
      dialogueId: null == dialogueId
          ? _value.dialogueId
          : dialogueId // ignore: cast_nullable_to_non_nullable
              as String,
      scriptPathRelative: null == scriptPathRelative
          ? _value.scriptPathRelative
          : scriptPathRelative // ignore: cast_nullable_to_non_nullable
              as String,
      startNode: freezed == startNode
          ? _value.startNode
          : startNode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$DialogueRefImpl implements _DialogueRef {
  const _$DialogueRefImpl(
      {required this.dialogueId, this.scriptPathRelative = '', this.startNode});

  factory _$DialogueRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$DialogueRefImplFromJson(json);

  /// Identifiant stable : typiquement [ProjectDialogueEntry.id] lorsque [scriptPathRelative] est vide.
  @override
  final String dialogueId;

  /// Vide = résolution via le registre projet ; non vide = script explicite (legacy ou override).
  @override
  @JsonKey()
  final String scriptPathRelative;

  /// Nœud d’entrée optionnel (ex. titre de nœud Yarn).
  @override
  final String? startNode;

  @override
  String toString() {
    return 'DialogueRef(dialogueId: $dialogueId, scriptPathRelative: $scriptPathRelative, startNode: $startNode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DialogueRefImpl &&
            (identical(other.dialogueId, dialogueId) ||
                other.dialogueId == dialogueId) &&
            (identical(other.scriptPathRelative, scriptPathRelative) ||
                other.scriptPathRelative == scriptPathRelative) &&
            (identical(other.startNode, startNode) ||
                other.startNode == startNode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, dialogueId, scriptPathRelative, startNode);

  /// Create a copy of DialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DialogueRefImplCopyWith<_$DialogueRefImpl> get copyWith =>
      __$$DialogueRefImplCopyWithImpl<_$DialogueRefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DialogueRefImplToJson(
      this,
    );
  }
}

abstract class _DialogueRef implements DialogueRef {
  const factory _DialogueRef(
      {required final String dialogueId,
      final String scriptPathRelative,
      final String? startNode}) = _$DialogueRefImpl;

  factory _DialogueRef.fromJson(Map<String, dynamic> json) =
      _$DialogueRefImpl.fromJson;

  /// Identifiant stable : typiquement [ProjectDialogueEntry.id] lorsque [scriptPathRelative] est vide.
  @override
  String get dialogueId;

  /// Vide = résolution via le registre projet ; non vide = script explicite (legacy ou override).
  @override
  String get scriptPathRelative;

  /// Nœud d’entrée optionnel (ex. titre de nœud Yarn).
  @override
  String? get startNode;

  /// Create a copy of DialogueRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DialogueRefImplCopyWith<_$DialogueRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapEntityNpcData _$MapEntityNpcDataFromJson(Map<String, dynamic> json) {
  return _MapEntityNpcData.fromJson(json);
}

/// @nodoc
mixin _$MapEntityNpcData {
  String get displayName => throw _privateConstructorUsedError;
  DialogueRef? get dialogue => throw _privateConstructorUsedError;
  EntityFacing get facing => throw _privateConstructorUsedError;
  String get visualElementId => throw _privateConstructorUsedError;
  String? get trainerId => throw _privateConstructorUsedError;
  int get lineOfSightRange => throw _privateConstructorUsedError;
  DialogueRef? get defeatDialogueRef => throw _privateConstructorUsedError;
  String? get characterId => throw _privateConstructorUsedError;
  MapEntityNpcMovementConfig get movement => throw _privateConstructorUsedError;

  /// Serializes this MapEntityNpcData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEntityNpcData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEntityNpcDataCopyWith<MapEntityNpcData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEntityNpcDataCopyWith<$Res> {
  factory $MapEntityNpcDataCopyWith(
          MapEntityNpcData value, $Res Function(MapEntityNpcData) then) =
      _$MapEntityNpcDataCopyWithImpl<$Res, MapEntityNpcData>;
  @useResult
  $Res call(
      {String displayName,
      DialogueRef? dialogue,
      EntityFacing facing,
      String visualElementId,
      String? trainerId,
      int lineOfSightRange,
      DialogueRef? defeatDialogueRef,
      String? characterId,
      MapEntityNpcMovementConfig movement});

  $DialogueRefCopyWith<$Res>? get dialogue;
  $DialogueRefCopyWith<$Res>? get defeatDialogueRef;
  $MapEntityNpcMovementConfigCopyWith<$Res> get movement;
}

/// @nodoc
class _$MapEntityNpcDataCopyWithImpl<$Res, $Val extends MapEntityNpcData>
    implements $MapEntityNpcDataCopyWith<$Res> {
  _$MapEntityNpcDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEntityNpcData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = null,
    Object? dialogue = freezed,
    Object? facing = null,
    Object? visualElementId = null,
    Object? trainerId = freezed,
    Object? lineOfSightRange = null,
    Object? defeatDialogueRef = freezed,
    Object? characterId = freezed,
    Object? movement = null,
  }) {
    return _then(_value.copyWith(
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      dialogue: freezed == dialogue
          ? _value.dialogue
          : dialogue // ignore: cast_nullable_to_non_nullable
              as DialogueRef?,
      facing: null == facing
          ? _value.facing
          : facing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      visualElementId: null == visualElementId
          ? _value.visualElementId
          : visualElementId // ignore: cast_nullable_to_non_nullable
              as String,
      trainerId: freezed == trainerId
          ? _value.trainerId
          : trainerId // ignore: cast_nullable_to_non_nullable
              as String?,
      lineOfSightRange: null == lineOfSightRange
          ? _value.lineOfSightRange
          : lineOfSightRange // ignore: cast_nullable_to_non_nullable
              as int,
      defeatDialogueRef: freezed == defeatDialogueRef
          ? _value.defeatDialogueRef
          : defeatDialogueRef // ignore: cast_nullable_to_non_nullable
              as DialogueRef?,
      characterId: freezed == characterId
          ? _value.characterId
          : characterId // ignore: cast_nullable_to_non_nullable
              as String?,
      movement: null == movement
          ? _value.movement
          : movement // ignore: cast_nullable_to_non_nullable
              as MapEntityNpcMovementConfig,
    ) as $Val);
  }

  /// Create a copy of MapEntityNpcData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DialogueRefCopyWith<$Res>? get dialogue {
    if (_value.dialogue == null) {
      return null;
    }

    return $DialogueRefCopyWith<$Res>(_value.dialogue!, (value) {
      return _then(_value.copyWith(dialogue: value) as $Val);
    });
  }

  /// Create a copy of MapEntityNpcData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DialogueRefCopyWith<$Res>? get defeatDialogueRef {
    if (_value.defeatDialogueRef == null) {
      return null;
    }

    return $DialogueRefCopyWith<$Res>(_value.defeatDialogueRef!, (value) {
      return _then(_value.copyWith(defeatDialogueRef: value) as $Val);
    });
  }

  /// Create a copy of MapEntityNpcData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEntityNpcMovementConfigCopyWith<$Res> get movement {
    return $MapEntityNpcMovementConfigCopyWith<$Res>(_value.movement, (value) {
      return _then(_value.copyWith(movement: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapEntityNpcDataImplCopyWith<$Res>
    implements $MapEntityNpcDataCopyWith<$Res> {
  factory _$$MapEntityNpcDataImplCopyWith(_$MapEntityNpcDataImpl value,
          $Res Function(_$MapEntityNpcDataImpl) then) =
      __$$MapEntityNpcDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String displayName,
      DialogueRef? dialogue,
      EntityFacing facing,
      String visualElementId,
      String? trainerId,
      int lineOfSightRange,
      DialogueRef? defeatDialogueRef,
      String? characterId,
      MapEntityNpcMovementConfig movement});

  @override
  $DialogueRefCopyWith<$Res>? get dialogue;
  @override
  $DialogueRefCopyWith<$Res>? get defeatDialogueRef;
  @override
  $MapEntityNpcMovementConfigCopyWith<$Res> get movement;
}

/// @nodoc
class __$$MapEntityNpcDataImplCopyWithImpl<$Res>
    extends _$MapEntityNpcDataCopyWithImpl<$Res, _$MapEntityNpcDataImpl>
    implements _$$MapEntityNpcDataImplCopyWith<$Res> {
  __$$MapEntityNpcDataImplCopyWithImpl(_$MapEntityNpcDataImpl _value,
      $Res Function(_$MapEntityNpcDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEntityNpcData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = null,
    Object? dialogue = freezed,
    Object? facing = null,
    Object? visualElementId = null,
    Object? trainerId = freezed,
    Object? lineOfSightRange = null,
    Object? defeatDialogueRef = freezed,
    Object? characterId = freezed,
    Object? movement = null,
  }) {
    return _then(_$MapEntityNpcDataImpl(
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      dialogue: freezed == dialogue
          ? _value.dialogue
          : dialogue // ignore: cast_nullable_to_non_nullable
              as DialogueRef?,
      facing: null == facing
          ? _value.facing
          : facing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      visualElementId: null == visualElementId
          ? _value.visualElementId
          : visualElementId // ignore: cast_nullable_to_non_nullable
              as String,
      trainerId: freezed == trainerId
          ? _value.trainerId
          : trainerId // ignore: cast_nullable_to_non_nullable
              as String?,
      lineOfSightRange: null == lineOfSightRange
          ? _value.lineOfSightRange
          : lineOfSightRange // ignore: cast_nullable_to_non_nullable
              as int,
      defeatDialogueRef: freezed == defeatDialogueRef
          ? _value.defeatDialogueRef
          : defeatDialogueRef // ignore: cast_nullable_to_non_nullable
              as DialogueRef?,
      characterId: freezed == characterId
          ? _value.characterId
          : characterId // ignore: cast_nullable_to_non_nullable
              as String?,
      movement: null == movement
          ? _value.movement
          : movement // ignore: cast_nullable_to_non_nullable
              as MapEntityNpcMovementConfig,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEntityNpcDataImpl implements _MapEntityNpcData {
  const _$MapEntityNpcDataImpl(
      {this.displayName = '',
      this.dialogue,
      this.facing = EntityFacing.south,
      this.visualElementId = '',
      this.trainerId,
      this.lineOfSightRange = 0,
      this.defeatDialogueRef,
      this.characterId,
      this.movement = const MapEntityNpcMovementConfig()});

  factory _$MapEntityNpcDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEntityNpcDataImplFromJson(json);

  @override
  @JsonKey()
  final String displayName;
  @override
  final DialogueRef? dialogue;
  @override
  @JsonKey()
  final EntityFacing facing;
  @override
  @JsonKey()
  final String visualElementId;
  @override
  final String? trainerId;
  @override
  @JsonKey()
  final int lineOfSightRange;
  @override
  final DialogueRef? defeatDialogueRef;
  @override
  final String? characterId;
  @override
  @JsonKey()
  final MapEntityNpcMovementConfig movement;

  @override
  String toString() {
    return 'MapEntityNpcData(displayName: $displayName, dialogue: $dialogue, facing: $facing, visualElementId: $visualElementId, trainerId: $trainerId, lineOfSightRange: $lineOfSightRange, defeatDialogueRef: $defeatDialogueRef, characterId: $characterId, movement: $movement)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEntityNpcDataImpl &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.dialogue, dialogue) ||
                other.dialogue == dialogue) &&
            (identical(other.facing, facing) || other.facing == facing) &&
            (identical(other.visualElementId, visualElementId) ||
                other.visualElementId == visualElementId) &&
            (identical(other.trainerId, trainerId) ||
                other.trainerId == trainerId) &&
            (identical(other.lineOfSightRange, lineOfSightRange) ||
                other.lineOfSightRange == lineOfSightRange) &&
            (identical(other.defeatDialogueRef, defeatDialogueRef) ||
                other.defeatDialogueRef == defeatDialogueRef) &&
            (identical(other.characterId, characterId) ||
                other.characterId == characterId) &&
            (identical(other.movement, movement) ||
                other.movement == movement));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      displayName,
      dialogue,
      facing,
      visualElementId,
      trainerId,
      lineOfSightRange,
      defeatDialogueRef,
      characterId,
      movement);

  /// Create a copy of MapEntityNpcData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEntityNpcDataImplCopyWith<_$MapEntityNpcDataImpl> get copyWith =>
      __$$MapEntityNpcDataImplCopyWithImpl<_$MapEntityNpcDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEntityNpcDataImplToJson(
      this,
    );
  }
}

abstract class _MapEntityNpcData implements MapEntityNpcData {
  const factory _MapEntityNpcData(
      {final String displayName,
      final DialogueRef? dialogue,
      final EntityFacing facing,
      final String visualElementId,
      final String? trainerId,
      final int lineOfSightRange,
      final DialogueRef? defeatDialogueRef,
      final String? characterId,
      final MapEntityNpcMovementConfig movement}) = _$MapEntityNpcDataImpl;

  factory _MapEntityNpcData.fromJson(Map<String, dynamic> json) =
      _$MapEntityNpcDataImpl.fromJson;

  @override
  String get displayName;
  @override
  DialogueRef? get dialogue;
  @override
  EntityFacing get facing;
  @override
  String get visualElementId;
  @override
  String? get trainerId;
  @override
  int get lineOfSightRange;
  @override
  DialogueRef? get defeatDialogueRef;
  @override
  String? get characterId;
  @override
  MapEntityNpcMovementConfig get movement;

  /// Create a copy of MapEntityNpcData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEntityNpcDataImplCopyWith<_$MapEntityNpcDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapEntityNpcMovementConfig _$MapEntityNpcMovementConfigFromJson(
    Map<String, dynamic> json) {
  return _MapEntityNpcMovementConfig.fromJson(json);
}

/// @nodoc
mixin _$MapEntityNpcMovementConfig {
  MapEntityNpcMovementMode get mode => throw _privateConstructorUsedError;
  List<GridPos> get waypoints => throw _privateConstructorUsedError;
  bool get loop => throw _privateConstructorUsedError;
  int get pauseDurationMs => throw _privateConstructorUsedError;
  int get stepDurationMs => throw _privateConstructorUsedError;

  /// Serializes this MapEntityNpcMovementConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEntityNpcMovementConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEntityNpcMovementConfigCopyWith<MapEntityNpcMovementConfig>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEntityNpcMovementConfigCopyWith<$Res> {
  factory $MapEntityNpcMovementConfigCopyWith(MapEntityNpcMovementConfig value,
          $Res Function(MapEntityNpcMovementConfig) then) =
      _$MapEntityNpcMovementConfigCopyWithImpl<$Res,
          MapEntityNpcMovementConfig>;
  @useResult
  $Res call(
      {MapEntityNpcMovementMode mode,
      List<GridPos> waypoints,
      bool loop,
      int pauseDurationMs,
      int stepDurationMs});
}

/// @nodoc
class _$MapEntityNpcMovementConfigCopyWithImpl<$Res,
        $Val extends MapEntityNpcMovementConfig>
    implements $MapEntityNpcMovementConfigCopyWith<$Res> {
  _$MapEntityNpcMovementConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEntityNpcMovementConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? waypoints = null,
    Object? loop = null,
    Object? pauseDurationMs = null,
    Object? stepDurationMs = null,
  }) {
    return _then(_value.copyWith(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as MapEntityNpcMovementMode,
      waypoints: null == waypoints
          ? _value.waypoints
          : waypoints // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
      loop: null == loop
          ? _value.loop
          : loop // ignore: cast_nullable_to_non_nullable
              as bool,
      pauseDurationMs: null == pauseDurationMs
          ? _value.pauseDurationMs
          : pauseDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      stepDurationMs: null == stepDurationMs
          ? _value.stepDurationMs
          : stepDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MapEntityNpcMovementConfigImplCopyWith<$Res>
    implements $MapEntityNpcMovementConfigCopyWith<$Res> {
  factory _$$MapEntityNpcMovementConfigImplCopyWith(
          _$MapEntityNpcMovementConfigImpl value,
          $Res Function(_$MapEntityNpcMovementConfigImpl) then) =
      __$$MapEntityNpcMovementConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {MapEntityNpcMovementMode mode,
      List<GridPos> waypoints,
      bool loop,
      int pauseDurationMs,
      int stepDurationMs});
}

/// @nodoc
class __$$MapEntityNpcMovementConfigImplCopyWithImpl<$Res>
    extends _$MapEntityNpcMovementConfigCopyWithImpl<$Res,
        _$MapEntityNpcMovementConfigImpl>
    implements _$$MapEntityNpcMovementConfigImplCopyWith<$Res> {
  __$$MapEntityNpcMovementConfigImplCopyWithImpl(
      _$MapEntityNpcMovementConfigImpl _value,
      $Res Function(_$MapEntityNpcMovementConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEntityNpcMovementConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? waypoints = null,
    Object? loop = null,
    Object? pauseDurationMs = null,
    Object? stepDurationMs = null,
  }) {
    return _then(_$MapEntityNpcMovementConfigImpl(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as MapEntityNpcMovementMode,
      waypoints: null == waypoints
          ? _value._waypoints
          : waypoints // ignore: cast_nullable_to_non_nullable
              as List<GridPos>,
      loop: null == loop
          ? _value.loop
          : loop // ignore: cast_nullable_to_non_nullable
              as bool,
      pauseDurationMs: null == pauseDurationMs
          ? _value.pauseDurationMs
          : pauseDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      stepDurationMs: null == stepDurationMs
          ? _value.stepDurationMs
          : stepDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEntityNpcMovementConfigImpl implements _MapEntityNpcMovementConfig {
  const _$MapEntityNpcMovementConfigImpl(
      {this.mode = MapEntityNpcMovementMode.idle,
      final List<GridPos> waypoints = const <GridPos>[],
      this.loop = true,
      this.pauseDurationMs = 0,
      this.stepDurationMs = 200})
      : _waypoints = waypoints;

  factory _$MapEntityNpcMovementConfigImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$MapEntityNpcMovementConfigImplFromJson(json);

  @override
  @JsonKey()
  final MapEntityNpcMovementMode mode;
  final List<GridPos> _waypoints;
  @override
  @JsonKey()
  List<GridPos> get waypoints {
    if (_waypoints is EqualUnmodifiableListView) return _waypoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_waypoints);
  }

  @override
  @JsonKey()
  final bool loop;
  @override
  @JsonKey()
  final int pauseDurationMs;
  @override
  @JsonKey()
  final int stepDurationMs;

  @override
  String toString() {
    return 'MapEntityNpcMovementConfig(mode: $mode, waypoints: $waypoints, loop: $loop, pauseDurationMs: $pauseDurationMs, stepDurationMs: $stepDurationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEntityNpcMovementConfigImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            const DeepCollectionEquality()
                .equals(other._waypoints, _waypoints) &&
            (identical(other.loop, loop) || other.loop == loop) &&
            (identical(other.pauseDurationMs, pauseDurationMs) ||
                other.pauseDurationMs == pauseDurationMs) &&
            (identical(other.stepDurationMs, stepDurationMs) ||
                other.stepDurationMs == stepDurationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      mode,
      const DeepCollectionEquality().hash(_waypoints),
      loop,
      pauseDurationMs,
      stepDurationMs);

  /// Create a copy of MapEntityNpcMovementConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEntityNpcMovementConfigImplCopyWith<_$MapEntityNpcMovementConfigImpl>
      get copyWith => __$$MapEntityNpcMovementConfigImplCopyWithImpl<
          _$MapEntityNpcMovementConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEntityNpcMovementConfigImplToJson(
      this,
    );
  }
}

abstract class _MapEntityNpcMovementConfig
    implements MapEntityNpcMovementConfig {
  const factory _MapEntityNpcMovementConfig(
      {final MapEntityNpcMovementMode mode,
      final List<GridPos> waypoints,
      final bool loop,
      final int pauseDurationMs,
      final int stepDurationMs}) = _$MapEntityNpcMovementConfigImpl;

  factory _MapEntityNpcMovementConfig.fromJson(Map<String, dynamic> json) =
      _$MapEntityNpcMovementConfigImpl.fromJson;

  @override
  MapEntityNpcMovementMode get mode;
  @override
  List<GridPos> get waypoints;
  @override
  bool get loop;
  @override
  int get pauseDurationMs;
  @override
  int get stepDurationMs;

  /// Create a copy of MapEntityNpcMovementConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEntityNpcMovementConfigImplCopyWith<_$MapEntityNpcMovementConfigImpl>
      get copyWith => throw _privateConstructorUsedError;
}

MapEntitySignData _$MapEntitySignDataFromJson(Map<String, dynamic> json) {
  return _MapEntitySignData.fromJson(json);
}

/// @nodoc
mixin _$MapEntitySignData {
  String get title => throw _privateConstructorUsedError;
  DialogueRef? get dialogue => throw _privateConstructorUsedError;

  /// Texte affiché si pas de dialogue scripté (panneau simple).
  String get plainText => throw _privateConstructorUsedError;

  /// Serializes this MapEntitySignData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEntitySignData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEntitySignDataCopyWith<MapEntitySignData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEntitySignDataCopyWith<$Res> {
  factory $MapEntitySignDataCopyWith(
          MapEntitySignData value, $Res Function(MapEntitySignData) then) =
      _$MapEntitySignDataCopyWithImpl<$Res, MapEntitySignData>;
  @useResult
  $Res call({String title, DialogueRef? dialogue, String plainText});

  $DialogueRefCopyWith<$Res>? get dialogue;
}

/// @nodoc
class _$MapEntitySignDataCopyWithImpl<$Res, $Val extends MapEntitySignData>
    implements $MapEntitySignDataCopyWith<$Res> {
  _$MapEntitySignDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEntitySignData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? dialogue = freezed,
    Object? plainText = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dialogue: freezed == dialogue
          ? _value.dialogue
          : dialogue // ignore: cast_nullable_to_non_nullable
              as DialogueRef?,
      plainText: null == plainText
          ? _value.plainText
          : plainText // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of MapEntitySignData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DialogueRefCopyWith<$Res>? get dialogue {
    if (_value.dialogue == null) {
      return null;
    }

    return $DialogueRefCopyWith<$Res>(_value.dialogue!, (value) {
      return _then(_value.copyWith(dialogue: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapEntitySignDataImplCopyWith<$Res>
    implements $MapEntitySignDataCopyWith<$Res> {
  factory _$$MapEntitySignDataImplCopyWith(_$MapEntitySignDataImpl value,
          $Res Function(_$MapEntitySignDataImpl) then) =
      __$$MapEntitySignDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, DialogueRef? dialogue, String plainText});

  @override
  $DialogueRefCopyWith<$Res>? get dialogue;
}

/// @nodoc
class __$$MapEntitySignDataImplCopyWithImpl<$Res>
    extends _$MapEntitySignDataCopyWithImpl<$Res, _$MapEntitySignDataImpl>
    implements _$$MapEntitySignDataImplCopyWith<$Res> {
  __$$MapEntitySignDataImplCopyWithImpl(_$MapEntitySignDataImpl _value,
      $Res Function(_$MapEntitySignDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEntitySignData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? dialogue = freezed,
    Object? plainText = null,
  }) {
    return _then(_$MapEntitySignDataImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dialogue: freezed == dialogue
          ? _value.dialogue
          : dialogue // ignore: cast_nullable_to_non_nullable
              as DialogueRef?,
      plainText: null == plainText
          ? _value.plainText
          : plainText // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEntitySignDataImpl implements _MapEntitySignData {
  const _$MapEntitySignDataImpl(
      {this.title = '', this.dialogue, this.plainText = ''});

  factory _$MapEntitySignDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEntitySignDataImplFromJson(json);

  @override
  @JsonKey()
  final String title;
  @override
  final DialogueRef? dialogue;

  /// Texte affiché si pas de dialogue scripté (panneau simple).
  @override
  @JsonKey()
  final String plainText;

  @override
  String toString() {
    return 'MapEntitySignData(title: $title, dialogue: $dialogue, plainText: $plainText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEntitySignDataImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dialogue, dialogue) ||
                other.dialogue == dialogue) &&
            (identical(other.plainText, plainText) ||
                other.plainText == plainText));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, dialogue, plainText);

  /// Create a copy of MapEntitySignData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEntitySignDataImplCopyWith<_$MapEntitySignDataImpl> get copyWith =>
      __$$MapEntitySignDataImplCopyWithImpl<_$MapEntitySignDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEntitySignDataImplToJson(
      this,
    );
  }
}

abstract class _MapEntitySignData implements MapEntitySignData {
  const factory _MapEntitySignData(
      {final String title,
      final DialogueRef? dialogue,
      final String plainText}) = _$MapEntitySignDataImpl;

  factory _MapEntitySignData.fromJson(Map<String, dynamic> json) =
      _$MapEntitySignDataImpl.fromJson;

  @override
  String get title;
  @override
  DialogueRef? get dialogue;

  /// Texte affiché si pas de dialogue scripté (panneau simple).
  @override
  String get plainText;

  /// Create a copy of MapEntitySignData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEntitySignDataImplCopyWith<_$MapEntitySignDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapEntityItemData _$MapEntityItemDataFromJson(Map<String, dynamic> json) {
  return _MapEntityItemData.fromJson(json);
}

/// @nodoc
mixin _$MapEntityItemData {
  String get gameItemId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  ItemPickupMode get pickupMode => throw _privateConstructorUsedError;
  ItemRespawnPolicy get respawnPolicy => throw _privateConstructorUsedError;

  /// Serializes this MapEntityItemData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEntityItemData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEntityItemDataCopyWith<MapEntityItemData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEntityItemDataCopyWith<$Res> {
  factory $MapEntityItemDataCopyWith(
          MapEntityItemData value, $Res Function(MapEntityItemData) then) =
      _$MapEntityItemDataCopyWithImpl<$Res, MapEntityItemData>;
  @useResult
  $Res call(
      {String gameItemId,
      int quantity,
      ItemPickupMode pickupMode,
      ItemRespawnPolicy respawnPolicy});
}

/// @nodoc
class _$MapEntityItemDataCopyWithImpl<$Res, $Val extends MapEntityItemData>
    implements $MapEntityItemDataCopyWith<$Res> {
  _$MapEntityItemDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEntityItemData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameItemId = null,
    Object? quantity = null,
    Object? pickupMode = null,
    Object? respawnPolicy = null,
  }) {
    return _then(_value.copyWith(
      gameItemId: null == gameItemId
          ? _value.gameItemId
          : gameItemId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      pickupMode: null == pickupMode
          ? _value.pickupMode
          : pickupMode // ignore: cast_nullable_to_non_nullable
              as ItemPickupMode,
      respawnPolicy: null == respawnPolicy
          ? _value.respawnPolicy
          : respawnPolicy // ignore: cast_nullable_to_non_nullable
              as ItemRespawnPolicy,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MapEntityItemDataImplCopyWith<$Res>
    implements $MapEntityItemDataCopyWith<$Res> {
  factory _$$MapEntityItemDataImplCopyWith(_$MapEntityItemDataImpl value,
          $Res Function(_$MapEntityItemDataImpl) then) =
      __$$MapEntityItemDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String gameItemId,
      int quantity,
      ItemPickupMode pickupMode,
      ItemRespawnPolicy respawnPolicy});
}

/// @nodoc
class __$$MapEntityItemDataImplCopyWithImpl<$Res>
    extends _$MapEntityItemDataCopyWithImpl<$Res, _$MapEntityItemDataImpl>
    implements _$$MapEntityItemDataImplCopyWith<$Res> {
  __$$MapEntityItemDataImplCopyWithImpl(_$MapEntityItemDataImpl _value,
      $Res Function(_$MapEntityItemDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEntityItemData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameItemId = null,
    Object? quantity = null,
    Object? pickupMode = null,
    Object? respawnPolicy = null,
  }) {
    return _then(_$MapEntityItemDataImpl(
      gameItemId: null == gameItemId
          ? _value.gameItemId
          : gameItemId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      pickupMode: null == pickupMode
          ? _value.pickupMode
          : pickupMode // ignore: cast_nullable_to_non_nullable
              as ItemPickupMode,
      respawnPolicy: null == respawnPolicy
          ? _value.respawnPolicy
          : respawnPolicy // ignore: cast_nullable_to_non_nullable
              as ItemRespawnPolicy,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEntityItemDataImpl implements _MapEntityItemData {
  const _$MapEntityItemDataImpl(
      {this.gameItemId = '',
      this.quantity = 1,
      this.pickupMode = ItemPickupMode.once,
      this.respawnPolicy = ItemRespawnPolicy.none});

  factory _$MapEntityItemDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEntityItemDataImplFromJson(json);

  @override
  @JsonKey()
  final String gameItemId;
  @override
  @JsonKey()
  final int quantity;
  @override
  @JsonKey()
  final ItemPickupMode pickupMode;
  @override
  @JsonKey()
  final ItemRespawnPolicy respawnPolicy;

  @override
  String toString() {
    return 'MapEntityItemData(gameItemId: $gameItemId, quantity: $quantity, pickupMode: $pickupMode, respawnPolicy: $respawnPolicy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEntityItemDataImpl &&
            (identical(other.gameItemId, gameItemId) ||
                other.gameItemId == gameItemId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.pickupMode, pickupMode) ||
                other.pickupMode == pickupMode) &&
            (identical(other.respawnPolicy, respawnPolicy) ||
                other.respawnPolicy == respawnPolicy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, gameItemId, quantity, pickupMode, respawnPolicy);

  /// Create a copy of MapEntityItemData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEntityItemDataImplCopyWith<_$MapEntityItemDataImpl> get copyWith =>
      __$$MapEntityItemDataImplCopyWithImpl<_$MapEntityItemDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEntityItemDataImplToJson(
      this,
    );
  }
}

abstract class _MapEntityItemData implements MapEntityItemData {
  const factory _MapEntityItemData(
      {final String gameItemId,
      final int quantity,
      final ItemPickupMode pickupMode,
      final ItemRespawnPolicy respawnPolicy}) = _$MapEntityItemDataImpl;

  factory _MapEntityItemData.fromJson(Map<String, dynamic> json) =
      _$MapEntityItemDataImpl.fromJson;

  @override
  String get gameItemId;
  @override
  int get quantity;
  @override
  ItemPickupMode get pickupMode;
  @override
  ItemRespawnPolicy get respawnPolicy;

  /// Create a copy of MapEntityItemData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEntityItemDataImplCopyWith<_$MapEntityItemDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapEntitySpawnData _$MapEntitySpawnDataFromJson(Map<String, dynamic> json) {
  return _MapEntitySpawnData.fromJson(json);
}

/// @nodoc
mixin _$MapEntitySpawnData {
  String get spawnKey => throw _privateConstructorUsedError;
  EntitySpawnRole get role => throw _privateConstructorUsedError;
  EntityFacing get facing => throw _privateConstructorUsedError;
  String get categoryTag => throw _privateConstructorUsedError;

  /// Serializes this MapEntitySpawnData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEntitySpawnData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEntitySpawnDataCopyWith<MapEntitySpawnData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEntitySpawnDataCopyWith<$Res> {
  factory $MapEntitySpawnDataCopyWith(
          MapEntitySpawnData value, $Res Function(MapEntitySpawnData) then) =
      _$MapEntitySpawnDataCopyWithImpl<$Res, MapEntitySpawnData>;
  @useResult
  $Res call(
      {String spawnKey,
      EntitySpawnRole role,
      EntityFacing facing,
      String categoryTag});
}

/// @nodoc
class _$MapEntitySpawnDataCopyWithImpl<$Res, $Val extends MapEntitySpawnData>
    implements $MapEntitySpawnDataCopyWith<$Res> {
  _$MapEntitySpawnDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEntitySpawnData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? spawnKey = null,
    Object? role = null,
    Object? facing = null,
    Object? categoryTag = null,
  }) {
    return _then(_value.copyWith(
      spawnKey: null == spawnKey
          ? _value.spawnKey
          : spawnKey // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as EntitySpawnRole,
      facing: null == facing
          ? _value.facing
          : facing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      categoryTag: null == categoryTag
          ? _value.categoryTag
          : categoryTag // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MapEntitySpawnDataImplCopyWith<$Res>
    implements $MapEntitySpawnDataCopyWith<$Res> {
  factory _$$MapEntitySpawnDataImplCopyWith(_$MapEntitySpawnDataImpl value,
          $Res Function(_$MapEntitySpawnDataImpl) then) =
      __$$MapEntitySpawnDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String spawnKey,
      EntitySpawnRole role,
      EntityFacing facing,
      String categoryTag});
}

/// @nodoc
class __$$MapEntitySpawnDataImplCopyWithImpl<$Res>
    extends _$MapEntitySpawnDataCopyWithImpl<$Res, _$MapEntitySpawnDataImpl>
    implements _$$MapEntitySpawnDataImplCopyWith<$Res> {
  __$$MapEntitySpawnDataImplCopyWithImpl(_$MapEntitySpawnDataImpl _value,
      $Res Function(_$MapEntitySpawnDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEntitySpawnData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? spawnKey = null,
    Object? role = null,
    Object? facing = null,
    Object? categoryTag = null,
  }) {
    return _then(_$MapEntitySpawnDataImpl(
      spawnKey: null == spawnKey
          ? _value.spawnKey
          : spawnKey // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as EntitySpawnRole,
      facing: null == facing
          ? _value.facing
          : facing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      categoryTag: null == categoryTag
          ? _value.categoryTag
          : categoryTag // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEntitySpawnDataImpl implements _MapEntitySpawnData {
  const _$MapEntitySpawnDataImpl(
      {this.spawnKey = '',
      this.role = EntitySpawnRole.playerStart,
      this.facing = EntityFacing.south,
      this.categoryTag = ''});

  factory _$MapEntitySpawnDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEntitySpawnDataImplFromJson(json);

  @override
  @JsonKey()
  final String spawnKey;
  @override
  @JsonKey()
  final EntitySpawnRole role;
  @override
  @JsonKey()
  final EntityFacing facing;
  @override
  @JsonKey()
  final String categoryTag;

  @override
  String toString() {
    return 'MapEntitySpawnData(spawnKey: $spawnKey, role: $role, facing: $facing, categoryTag: $categoryTag)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEntitySpawnDataImpl &&
            (identical(other.spawnKey, spawnKey) ||
                other.spawnKey == spawnKey) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.facing, facing) || other.facing == facing) &&
            (identical(other.categoryTag, categoryTag) ||
                other.categoryTag == categoryTag));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, spawnKey, role, facing, categoryTag);

  /// Create a copy of MapEntitySpawnData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEntitySpawnDataImplCopyWith<_$MapEntitySpawnDataImpl> get copyWith =>
      __$$MapEntitySpawnDataImplCopyWithImpl<_$MapEntitySpawnDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEntitySpawnDataImplToJson(
      this,
    );
  }
}

abstract class _MapEntitySpawnData implements MapEntitySpawnData {
  const factory _MapEntitySpawnData(
      {final String spawnKey,
      final EntitySpawnRole role,
      final EntityFacing facing,
      final String categoryTag}) = _$MapEntitySpawnDataImpl;

  factory _MapEntitySpawnData.fromJson(Map<String, dynamic> json) =
      _$MapEntitySpawnDataImpl.fromJson;

  @override
  String get spawnKey;
  @override
  EntitySpawnRole get role;
  @override
  EntityFacing get facing;
  @override
  String get categoryTag;

  /// Create a copy of MapEntitySpawnData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEntitySpawnDataImplCopyWith<_$MapEntitySpawnDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
