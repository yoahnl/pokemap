// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayerPokemon _$PlayerPokemonFromJson(Map<String, dynamic> json) {
  return _PlayerPokemon.fromJson(json);
}

/// @nodoc
mixin _$PlayerPokemon {
  String get id => throw _privateConstructorUsedError;
  String get speciesId => throw _privateConstructorUsedError;
  String get nickname => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  List<String> get knownMoveIds => throw _privateConstructorUsedError;
  bool get isFainted => throw _privateConstructorUsedError;

  /// Serializes this PlayerPokemon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerPokemonCopyWith<PlayerPokemon> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerPokemonCopyWith<$Res> {
  factory $PlayerPokemonCopyWith(
          PlayerPokemon value, $Res Function(PlayerPokemon) then) =
      _$PlayerPokemonCopyWithImpl<$Res, PlayerPokemon>;
  @useResult
  $Res call(
      {String id,
      String speciesId,
      String nickname,
      int level,
      List<String> knownMoveIds,
      bool isFainted});
}

/// @nodoc
class _$PlayerPokemonCopyWithImpl<$Res, $Val extends PlayerPokemon>
    implements $PlayerPokemonCopyWith<$Res> {
  _$PlayerPokemonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? speciesId = null,
    Object? nickname = null,
    Object? level = null,
    Object? knownMoveIds = null,
    Object? isFainted = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      knownMoveIds: null == knownMoveIds
          ? _value.knownMoveIds
          : knownMoveIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isFainted: null == isFainted
          ? _value.isFainted
          : isFainted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerPokemonImplCopyWith<$Res>
    implements $PlayerPokemonCopyWith<$Res> {
  factory _$$PlayerPokemonImplCopyWith(
          _$PlayerPokemonImpl value, $Res Function(_$PlayerPokemonImpl) then) =
      __$$PlayerPokemonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String speciesId,
      String nickname,
      int level,
      List<String> knownMoveIds,
      bool isFainted});
}

/// @nodoc
class __$$PlayerPokemonImplCopyWithImpl<$Res>
    extends _$PlayerPokemonCopyWithImpl<$Res, _$PlayerPokemonImpl>
    implements _$$PlayerPokemonImplCopyWith<$Res> {
  __$$PlayerPokemonImplCopyWithImpl(
      _$PlayerPokemonImpl _value, $Res Function(_$PlayerPokemonImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? speciesId = null,
    Object? nickname = null,
    Object? level = null,
    Object? knownMoveIds = null,
    Object? isFainted = null,
  }) {
    return _then(_$PlayerPokemonImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: null == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      knownMoveIds: null == knownMoveIds
          ? _value._knownMoveIds
          : knownMoveIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isFainted: null == isFainted
          ? _value.isFainted
          : isFainted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PlayerPokemonImpl implements _PlayerPokemon {
  const _$PlayerPokemonImpl(
      {required this.id,
      required this.speciesId,
      this.nickname = '',
      this.level = 1,
      final List<String> knownMoveIds = const [],
      this.isFainted = false})
      : _knownMoveIds = knownMoveIds;

  factory _$PlayerPokemonImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerPokemonImplFromJson(json);

  @override
  final String id;
  @override
  final String speciesId;
  @override
  @JsonKey()
  final String nickname;
  @override
  @JsonKey()
  final int level;
  final List<String> _knownMoveIds;
  @override
  @JsonKey()
  List<String> get knownMoveIds {
    if (_knownMoveIds is EqualUnmodifiableListView) return _knownMoveIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_knownMoveIds);
  }

  @override
  @JsonKey()
  final bool isFainted;

  @override
  String toString() {
    return 'PlayerPokemon(id: $id, speciesId: $speciesId, nickname: $nickname, level: $level, knownMoveIds: $knownMoveIds, isFainted: $isFainted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerPokemonImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality()
                .equals(other._knownMoveIds, _knownMoveIds) &&
            (identical(other.isFainted, isFainted) ||
                other.isFainted == isFainted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, speciesId, nickname, level,
      const DeepCollectionEquality().hash(_knownMoveIds), isFainted);

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerPokemonImplCopyWith<_$PlayerPokemonImpl> get copyWith =>
      __$$PlayerPokemonImplCopyWithImpl<_$PlayerPokemonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerPokemonImplToJson(
      this,
    );
  }
}

abstract class _PlayerPokemon implements PlayerPokemon {
  const factory _PlayerPokemon(
      {required final String id,
      required final String speciesId,
      final String nickname,
      final int level,
      final List<String> knownMoveIds,
      final bool isFainted}) = _$PlayerPokemonImpl;

  factory _PlayerPokemon.fromJson(Map<String, dynamic> json) =
      _$PlayerPokemonImpl.fromJson;

  @override
  String get id;
  @override
  String get speciesId;
  @override
  String get nickname;
  @override
  int get level;
  @override
  List<String> get knownMoveIds;
  @override
  bool get isFainted;

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerPokemonImplCopyWith<_$PlayerPokemonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerParty _$PlayerPartyFromJson(Map<String, dynamic> json) {
  return _PlayerParty.fromJson(json);
}

/// @nodoc
mixin _$PlayerParty {
  List<PlayerPokemon> get members => throw _privateConstructorUsedError;

  /// Serializes this PlayerParty to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerPartyCopyWith<PlayerParty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerPartyCopyWith<$Res> {
  factory $PlayerPartyCopyWith(
          PlayerParty value, $Res Function(PlayerParty) then) =
      _$PlayerPartyCopyWithImpl<$Res, PlayerParty>;
  @useResult
  $Res call({List<PlayerPokemon> members});
}

/// @nodoc
class _$PlayerPartyCopyWithImpl<$Res, $Val extends PlayerParty>
    implements $PlayerPartyCopyWith<$Res> {
  _$PlayerPartyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? members = null,
  }) {
    return _then(_value.copyWith(
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<PlayerPokemon>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerPartyImplCopyWith<$Res>
    implements $PlayerPartyCopyWith<$Res> {
  factory _$$PlayerPartyImplCopyWith(
          _$PlayerPartyImpl value, $Res Function(_$PlayerPartyImpl) then) =
      __$$PlayerPartyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<PlayerPokemon> members});
}

/// @nodoc
class __$$PlayerPartyImplCopyWithImpl<$Res>
    extends _$PlayerPartyCopyWithImpl<$Res, _$PlayerPartyImpl>
    implements _$$PlayerPartyImplCopyWith<$Res> {
  __$$PlayerPartyImplCopyWithImpl(
      _$PlayerPartyImpl _value, $Res Function(_$PlayerPartyImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? members = null,
  }) {
    return _then(_$PlayerPartyImpl(
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<PlayerPokemon>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PlayerPartyImpl implements _PlayerParty {
  const _$PlayerPartyImpl({final List<PlayerPokemon> members = const []})
      : _members = members;

  factory _$PlayerPartyImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerPartyImplFromJson(json);

  final List<PlayerPokemon> _members;
  @override
  @JsonKey()
  List<PlayerPokemon> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  String toString() {
    return 'PlayerParty(members: $members)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerPartyImpl &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_members));

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerPartyImplCopyWith<_$PlayerPartyImpl> get copyWith =>
      __$$PlayerPartyImplCopyWithImpl<_$PlayerPartyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerPartyImplToJson(
      this,
    );
  }
}

abstract class _PlayerParty implements PlayerParty {
  const factory _PlayerParty({final List<PlayerPokemon> members}) =
      _$PlayerPartyImpl;

  factory _PlayerParty.fromJson(Map<String, dynamic> json) =
      _$PlayerPartyImpl.fromJson;

  @override
  List<PlayerPokemon> get members;

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerPartyImplCopyWith<_$PlayerPartyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerProgression _$PlayerProgressionFromJson(Map<String, dynamic> json) {
  return _PlayerProgression.fromJson(json);
}

/// @nodoc
mixin _$PlayerProgression {
  List<FieldAbility> get unlockedFieldAbilities =>
      throw _privateConstructorUsedError;
  List<String> get storyFlags => throw _privateConstructorUsedError;

  /// Steps du document `authoring.stepStudioDocument` marquées comme
  /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
  List<String> get completedStepIds => throw _privateConstructorUsedError;

  /// Serializes this PlayerProgression to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerProgressionCopyWith<PlayerProgression> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerProgressionCopyWith<$Res> {
  factory $PlayerProgressionCopyWith(
          PlayerProgression value, $Res Function(PlayerProgression) then) =
      _$PlayerProgressionCopyWithImpl<$Res, PlayerProgression>;
  @useResult
  $Res call(
      {List<FieldAbility> unlockedFieldAbilities,
      List<String> storyFlags,
      List<String> completedStepIds});
}

/// @nodoc
class _$PlayerProgressionCopyWithImpl<$Res, $Val extends PlayerProgression>
    implements $PlayerProgressionCopyWith<$Res> {
  _$PlayerProgressionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unlockedFieldAbilities = null,
    Object? storyFlags = null,
    Object? completedStepIds = null,
  }) {
    return _then(_value.copyWith(
      unlockedFieldAbilities: null == unlockedFieldAbilities
          ? _value.unlockedFieldAbilities
          : unlockedFieldAbilities // ignore: cast_nullable_to_non_nullable
              as List<FieldAbility>,
      storyFlags: null == storyFlags
          ? _value.storyFlags
          : storyFlags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      completedStepIds: null == completedStepIds
          ? _value.completedStepIds
          : completedStepIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerProgressionImplCopyWith<$Res>
    implements $PlayerProgressionCopyWith<$Res> {
  factory _$$PlayerProgressionImplCopyWith(_$PlayerProgressionImpl value,
          $Res Function(_$PlayerProgressionImpl) then) =
      __$$PlayerProgressionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<FieldAbility> unlockedFieldAbilities,
      List<String> storyFlags,
      List<String> completedStepIds});
}

/// @nodoc
class __$$PlayerProgressionImplCopyWithImpl<$Res>
    extends _$PlayerProgressionCopyWithImpl<$Res, _$PlayerProgressionImpl>
    implements _$$PlayerProgressionImplCopyWith<$Res> {
  __$$PlayerProgressionImplCopyWithImpl(_$PlayerProgressionImpl _value,
      $Res Function(_$PlayerProgressionImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unlockedFieldAbilities = null,
    Object? storyFlags = null,
    Object? completedStepIds = null,
  }) {
    return _then(_$PlayerProgressionImpl(
      unlockedFieldAbilities: null == unlockedFieldAbilities
          ? _value._unlockedFieldAbilities
          : unlockedFieldAbilities // ignore: cast_nullable_to_non_nullable
              as List<FieldAbility>,
      storyFlags: null == storyFlags
          ? _value._storyFlags
          : storyFlags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      completedStepIds: null == completedStepIds
          ? _value._completedStepIds
          : completedStepIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PlayerProgressionImpl implements _PlayerProgression {
  const _$PlayerProgressionImpl(
      {final List<FieldAbility> unlockedFieldAbilities = const [],
      final List<String> storyFlags = const [],
      final List<String> completedStepIds = const []})
      : _unlockedFieldAbilities = unlockedFieldAbilities,
        _storyFlags = storyFlags,
        _completedStepIds = completedStepIds;

  factory _$PlayerProgressionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerProgressionImplFromJson(json);

  final List<FieldAbility> _unlockedFieldAbilities;
  @override
  @JsonKey()
  List<FieldAbility> get unlockedFieldAbilities {
    if (_unlockedFieldAbilities is EqualUnmodifiableListView)
      return _unlockedFieldAbilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unlockedFieldAbilities);
  }

  final List<String> _storyFlags;
  @override
  @JsonKey()
  List<String> get storyFlags {
    if (_storyFlags is EqualUnmodifiableListView) return _storyFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_storyFlags);
  }

  /// Steps du document `authoring.stepStudioDocument` marquées comme
  /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
  final List<String> _completedStepIds;

  /// Steps du document `authoring.stepStudioDocument` marquées comme
  /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
  @override
  @JsonKey()
  List<String> get completedStepIds {
    if (_completedStepIds is EqualUnmodifiableListView)
      return _completedStepIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedStepIds);
  }

  @override
  String toString() {
    return 'PlayerProgression(unlockedFieldAbilities: $unlockedFieldAbilities, storyFlags: $storyFlags, completedStepIds: $completedStepIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerProgressionImpl &&
            const DeepCollectionEquality().equals(
                other._unlockedFieldAbilities, _unlockedFieldAbilities) &&
            const DeepCollectionEquality()
                .equals(other._storyFlags, _storyFlags) &&
            const DeepCollectionEquality()
                .equals(other._completedStepIds, _completedStepIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_unlockedFieldAbilities),
      const DeepCollectionEquality().hash(_storyFlags),
      const DeepCollectionEquality().hash(_completedStepIds));

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerProgressionImplCopyWith<_$PlayerProgressionImpl> get copyWith =>
      __$$PlayerProgressionImplCopyWithImpl<_$PlayerProgressionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerProgressionImplToJson(
      this,
    );
  }
}

abstract class _PlayerProgression implements PlayerProgression {
  const factory _PlayerProgression(
      {final List<FieldAbility> unlockedFieldAbilities,
      final List<String> storyFlags,
      final List<String> completedStepIds}) = _$PlayerProgressionImpl;

  factory _PlayerProgression.fromJson(Map<String, dynamic> json) =
      _$PlayerProgressionImpl.fromJson;

  @override
  List<FieldAbility> get unlockedFieldAbilities;
  @override
  List<String> get storyFlags;

  /// Steps du document `authoring.stepStudioDocument` marquées comme
  /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
  @override
  List<String> get completedStepIds;

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerProgressionImplCopyWith<_$PlayerProgressionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SaveData _$SaveDataFromJson(Map<String, dynamic> json) {
  return _SaveData.fromJson(json);
}

/// @nodoc
mixin _$SaveData {
  String get saveId => throw _privateConstructorUsedError;
  String get currentMapId => throw _privateConstructorUsedError;
  GridPos get playerPosition => throw _privateConstructorUsedError;
  EntityFacing get playerFacing => throw _privateConstructorUsedError;
  PlayerParty get party => throw _privateConstructorUsedError;
  PlayerProgression get progression => throw _privateConstructorUsedError;
  Map<String, String> get properties => throw _privateConstructorUsedError;

  /// Serializes this SaveData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaveDataCopyWith<SaveData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaveDataCopyWith<$Res> {
  factory $SaveDataCopyWith(SaveData value, $Res Function(SaveData) then) =
      _$SaveDataCopyWithImpl<$Res, SaveData>;
  @useResult
  $Res call(
      {String saveId,
      String currentMapId,
      GridPos playerPosition,
      EntityFacing playerFacing,
      PlayerParty party,
      PlayerProgression progression,
      Map<String, String> properties});

  $GridPosCopyWith<$Res> get playerPosition;
  $PlayerPartyCopyWith<$Res> get party;
  $PlayerProgressionCopyWith<$Res> get progression;
}

/// @nodoc
class _$SaveDataCopyWithImpl<$Res, $Val extends SaveData>
    implements $SaveDataCopyWith<$Res> {
  _$SaveDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saveId = null,
    Object? currentMapId = null,
    Object? playerPosition = null,
    Object? playerFacing = null,
    Object? party = null,
    Object? progression = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      saveId: null == saveId
          ? _value.saveId
          : saveId // ignore: cast_nullable_to_non_nullable
              as String,
      currentMapId: null == currentMapId
          ? _value.currentMapId
          : currentMapId // ignore: cast_nullable_to_non_nullable
              as String,
      playerPosition: null == playerPosition
          ? _value.playerPosition
          : playerPosition // ignore: cast_nullable_to_non_nullable
              as GridPos,
      playerFacing: null == playerFacing
          ? _value.playerFacing
          : playerFacing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PlayerParty,
      progression: null == progression
          ? _value.progression
          : progression // ignore: cast_nullable_to_non_nullable
              as PlayerProgression,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get playerPosition {
    return $GridPosCopyWith<$Res>(_value.playerPosition, (value) {
      return _then(_value.copyWith(playerPosition: value) as $Val);
    });
  }

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerPartyCopyWith<$Res> get party {
    return $PlayerPartyCopyWith<$Res>(_value.party, (value) {
      return _then(_value.copyWith(party: value) as $Val);
    });
  }

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerProgressionCopyWith<$Res> get progression {
    return $PlayerProgressionCopyWith<$Res>(_value.progression, (value) {
      return _then(_value.copyWith(progression: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SaveDataImplCopyWith<$Res>
    implements $SaveDataCopyWith<$Res> {
  factory _$$SaveDataImplCopyWith(
          _$SaveDataImpl value, $Res Function(_$SaveDataImpl) then) =
      __$$SaveDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String saveId,
      String currentMapId,
      GridPos playerPosition,
      EntityFacing playerFacing,
      PlayerParty party,
      PlayerProgression progression,
      Map<String, String> properties});

  @override
  $GridPosCopyWith<$Res> get playerPosition;
  @override
  $PlayerPartyCopyWith<$Res> get party;
  @override
  $PlayerProgressionCopyWith<$Res> get progression;
}

/// @nodoc
class __$$SaveDataImplCopyWithImpl<$Res>
    extends _$SaveDataCopyWithImpl<$Res, _$SaveDataImpl>
    implements _$$SaveDataImplCopyWith<$Res> {
  __$$SaveDataImplCopyWithImpl(
      _$SaveDataImpl _value, $Res Function(_$SaveDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saveId = null,
    Object? currentMapId = null,
    Object? playerPosition = null,
    Object? playerFacing = null,
    Object? party = null,
    Object? progression = null,
    Object? properties = null,
  }) {
    return _then(_$SaveDataImpl(
      saveId: null == saveId
          ? _value.saveId
          : saveId // ignore: cast_nullable_to_non_nullable
              as String,
      currentMapId: null == currentMapId
          ? _value.currentMapId
          : currentMapId // ignore: cast_nullable_to_non_nullable
              as String,
      playerPosition: null == playerPosition
          ? _value.playerPosition
          : playerPosition // ignore: cast_nullable_to_non_nullable
              as GridPos,
      playerFacing: null == playerFacing
          ? _value.playerFacing
          : playerFacing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PlayerParty,
      progression: null == progression
          ? _value.progression
          : progression // ignore: cast_nullable_to_non_nullable
              as PlayerProgression,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SaveDataImpl implements _SaveData {
  const _$SaveDataImpl(
      {required this.saveId,
      this.currentMapId = '',
      this.playerPosition = const GridPos(x: 0, y: 0),
      this.playerFacing = EntityFacing.south,
      this.party = const PlayerParty(),
      this.progression = const PlayerProgression(),
      final Map<String, String> properties = const {}})
      : _properties = properties;

  factory _$SaveDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SaveDataImplFromJson(json);

  @override
  final String saveId;
  @override
  @JsonKey()
  final String currentMapId;
  @override
  @JsonKey()
  final GridPos playerPosition;
  @override
  @JsonKey()
  final EntityFacing playerFacing;
  @override
  @JsonKey()
  final PlayerParty party;
  @override
  @JsonKey()
  final PlayerProgression progression;
  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'SaveData(saveId: $saveId, currentMapId: $currentMapId, playerPosition: $playerPosition, playerFacing: $playerFacing, party: $party, progression: $progression, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaveDataImpl &&
            (identical(other.saveId, saveId) || other.saveId == saveId) &&
            (identical(other.currentMapId, currentMapId) ||
                other.currentMapId == currentMapId) &&
            (identical(other.playerPosition, playerPosition) ||
                other.playerPosition == playerPosition) &&
            (identical(other.playerFacing, playerFacing) ||
                other.playerFacing == playerFacing) &&
            (identical(other.party, party) || other.party == party) &&
            (identical(other.progression, progression) ||
                other.progression == progression) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      saveId,
      currentMapId,
      playerPosition,
      playerFacing,
      party,
      progression,
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaveDataImplCopyWith<_$SaveDataImpl> get copyWith =>
      __$$SaveDataImplCopyWithImpl<_$SaveDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SaveDataImplToJson(
      this,
    );
  }
}

abstract class _SaveData implements SaveData {
  const factory _SaveData(
      {required final String saveId,
      final String currentMapId,
      final GridPos playerPosition,
      final EntityFacing playerFacing,
      final PlayerParty party,
      final PlayerProgression progression,
      final Map<String, String> properties}) = _$SaveDataImpl;

  factory _SaveData.fromJson(Map<String, dynamic> json) =
      _$SaveDataImpl.fromJson;

  @override
  String get saveId;
  @override
  String get currentMapId;
  @override
  GridPos get playerPosition;
  @override
  EntityFacing get playerFacing;
  @override
  PlayerParty get party;
  @override
  PlayerProgression get progression;
  @override
  Map<String, String> get properties;

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaveDataImplCopyWith<_$SaveDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
