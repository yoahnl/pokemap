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

PokemonStatSpread _$PokemonStatSpreadFromJson(Map<String, dynamic> json) {
  return _PokemonStatSpread.fromJson(json);
}

/// @nodoc
mixin _$PokemonStatSpread {
  int get hp => throw _privateConstructorUsedError;
  int get attack => throw _privateConstructorUsedError;
  int get defense => throw _privateConstructorUsedError;
  int get specialAttack => throw _privateConstructorUsedError;
  int get specialDefense => throw _privateConstructorUsedError;
  int get speed => throw _privateConstructorUsedError;

  /// Serializes this PokemonStatSpread to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonStatSpreadCopyWith<PokemonStatSpread> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonStatSpreadCopyWith<$Res> {
  factory $PokemonStatSpreadCopyWith(
          PokemonStatSpread value, $Res Function(PokemonStatSpread) then) =
      _$PokemonStatSpreadCopyWithImpl<$Res, PokemonStatSpread>;
  @useResult
  $Res call(
      {int hp,
      int attack,
      int defense,
      int specialAttack,
      int specialDefense,
      int speed});
}

/// @nodoc
class _$PokemonStatSpreadCopyWithImpl<$Res, $Val extends PokemonStatSpread>
    implements $PokemonStatSpreadCopyWith<$Res> {
  _$PokemonStatSpreadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hp = null,
    Object? attack = null,
    Object? defense = null,
    Object? specialAttack = null,
    Object? specialDefense = null,
    Object? speed = null,
  }) {
    return _then(_value.copyWith(
      hp: null == hp
          ? _value.hp
          : hp // ignore: cast_nullable_to_non_nullable
              as int,
      attack: null == attack
          ? _value.attack
          : attack // ignore: cast_nullable_to_non_nullable
              as int,
      defense: null == defense
          ? _value.defense
          : defense // ignore: cast_nullable_to_non_nullable
              as int,
      specialAttack: null == specialAttack
          ? _value.specialAttack
          : specialAttack // ignore: cast_nullable_to_non_nullable
              as int,
      specialDefense: null == specialDefense
          ? _value.specialDefense
          : specialDefense // ignore: cast_nullable_to_non_nullable
              as int,
      speed: null == speed
          ? _value.speed
          : speed // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PokemonStatSpreadImplCopyWith<$Res>
    implements $PokemonStatSpreadCopyWith<$Res> {
  factory _$$PokemonStatSpreadImplCopyWith(_$PokemonStatSpreadImpl value,
          $Res Function(_$PokemonStatSpreadImpl) then) =
      __$$PokemonStatSpreadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int hp,
      int attack,
      int defense,
      int specialAttack,
      int specialDefense,
      int speed});
}

/// @nodoc
class __$$PokemonStatSpreadImplCopyWithImpl<$Res>
    extends _$PokemonStatSpreadCopyWithImpl<$Res, _$PokemonStatSpreadImpl>
    implements _$$PokemonStatSpreadImplCopyWith<$Res> {
  __$$PokemonStatSpreadImplCopyWithImpl(_$PokemonStatSpreadImpl _value,
      $Res Function(_$PokemonStatSpreadImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hp = null,
    Object? attack = null,
    Object? defense = null,
    Object? specialAttack = null,
    Object? specialDefense = null,
    Object? speed = null,
  }) {
    return _then(_$PokemonStatSpreadImpl(
      hp: null == hp
          ? _value.hp
          : hp // ignore: cast_nullable_to_non_nullable
              as int,
      attack: null == attack
          ? _value.attack
          : attack // ignore: cast_nullable_to_non_nullable
              as int,
      defense: null == defense
          ? _value.defense
          : defense // ignore: cast_nullable_to_non_nullable
              as int,
      specialAttack: null == specialAttack
          ? _value.specialAttack
          : specialAttack // ignore: cast_nullable_to_non_nullable
              as int,
      specialDefense: null == specialDefense
          ? _value.specialDefense
          : specialDefense // ignore: cast_nullable_to_non_nullable
              as int,
      speed: null == speed
          ? _value.speed
          : speed // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonStatSpreadImpl extends _PokemonStatSpread {
  const _$PokemonStatSpreadImpl(
      {this.hp = 0,
      this.attack = 0,
      this.defense = 0,
      this.specialAttack = 0,
      this.specialDefense = 0,
      this.speed = 0})
      : super._();

  factory _$PokemonStatSpreadImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonStatSpreadImplFromJson(json);

  @override
  @JsonKey()
  final int hp;
  @override
  @JsonKey()
  final int attack;
  @override
  @JsonKey()
  final int defense;
  @override
  @JsonKey()
  final int specialAttack;
  @override
  @JsonKey()
  final int specialDefense;
  @override
  @JsonKey()
  final int speed;

  @override
  String toString() {
    return 'PokemonStatSpread(hp: $hp, attack: $attack, defense: $defense, specialAttack: $specialAttack, specialDefense: $specialDefense, speed: $speed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonStatSpreadImpl &&
            (identical(other.hp, hp) || other.hp == hp) &&
            (identical(other.attack, attack) || other.attack == attack) &&
            (identical(other.defense, defense) || other.defense == defense) &&
            (identical(other.specialAttack, specialAttack) ||
                other.specialAttack == specialAttack) &&
            (identical(other.specialDefense, specialDefense) ||
                other.specialDefense == specialDefense) &&
            (identical(other.speed, speed) || other.speed == speed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, hp, attack, defense, specialAttack, specialDefense, speed);

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonStatSpreadImplCopyWith<_$PokemonStatSpreadImpl> get copyWith =>
      __$$PokemonStatSpreadImplCopyWithImpl<_$PokemonStatSpreadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonStatSpreadImplToJson(
      this,
    );
  }
}

abstract class _PokemonStatSpread extends PokemonStatSpread {
  const factory _PokemonStatSpread(
      {final int hp,
      final int attack,
      final int defense,
      final int specialAttack,
      final int specialDefense,
      final int speed}) = _$PokemonStatSpreadImpl;
  const _PokemonStatSpread._() : super._();

  factory _PokemonStatSpread.fromJson(Map<String, dynamic> json) =
      _$PokemonStatSpreadImpl.fromJson;

  @override
  int get hp;
  @override
  int get attack;
  @override
  int get defense;
  @override
  int get specialAttack;
  @override
  int get specialDefense;
  @override
  int get speed;

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonStatSpreadImplCopyWith<_$PokemonStatSpreadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerPokemon _$PlayerPokemonFromJson(Map<String, dynamic> json) {
  return _PlayerPokemon.fromJson(json);
}

/// @nodoc
mixin _$PlayerPokemon {
  String get speciesId => throw _privateConstructorUsedError;
  String get natureId => throw _privateConstructorUsedError;
  String get abilityId => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  PokemonStatSpread get ivs => throw _privateConstructorUsedError;
  PokemonStatSpread get evs => throw _privateConstructorUsedError;
  List<String> get knownMoveIds => throw _privateConstructorUsedError;
  int get currentHp => throw _privateConstructorUsedError;
  String get statusId => throw _privateConstructorUsedError;
  bool get isShiny => throw _privateConstructorUsedError;
  String get heldItemId => throw _privateConstructorUsedError;

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
      {String speciesId,
      String natureId,
      String abilityId,
      int level,
      PokemonStatSpread ivs,
      PokemonStatSpread evs,
      List<String> knownMoveIds,
      int currentHp,
      String statusId,
      bool isShiny,
      String heldItemId});

  $PokemonStatSpreadCopyWith<$Res> get ivs;
  $PokemonStatSpreadCopyWith<$Res> get evs;
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
    Object? speciesId = null,
    Object? natureId = null,
    Object? abilityId = null,
    Object? level = null,
    Object? ivs = null,
    Object? evs = null,
    Object? knownMoveIds = null,
    Object? currentHp = null,
    Object? statusId = null,
    Object? isShiny = null,
    Object? heldItemId = null,
  }) {
    return _then(_value.copyWith(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      natureId: null == natureId
          ? _value.natureId
          : natureId // ignore: cast_nullable_to_non_nullable
              as String,
      abilityId: null == abilityId
          ? _value.abilityId
          : abilityId // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      ivs: null == ivs
          ? _value.ivs
          : ivs // ignore: cast_nullable_to_non_nullable
              as PokemonStatSpread,
      evs: null == evs
          ? _value.evs
          : evs // ignore: cast_nullable_to_non_nullable
              as PokemonStatSpread,
      knownMoveIds: null == knownMoveIds
          ? _value.knownMoveIds
          : knownMoveIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentHp: null == currentHp
          ? _value.currentHp
          : currentHp // ignore: cast_nullable_to_non_nullable
              as int,
      statusId: null == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as String,
      isShiny: null == isShiny
          ? _value.isShiny
          : isShiny // ignore: cast_nullable_to_non_nullable
              as bool,
      heldItemId: null == heldItemId
          ? _value.heldItemId
          : heldItemId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PokemonStatSpreadCopyWith<$Res> get ivs {
    return $PokemonStatSpreadCopyWith<$Res>(_value.ivs, (value) {
      return _then(_value.copyWith(ivs: value) as $Val);
    });
  }

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PokemonStatSpreadCopyWith<$Res> get evs {
    return $PokemonStatSpreadCopyWith<$Res>(_value.evs, (value) {
      return _then(_value.copyWith(evs: value) as $Val);
    });
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
      {String speciesId,
      String natureId,
      String abilityId,
      int level,
      PokemonStatSpread ivs,
      PokemonStatSpread evs,
      List<String> knownMoveIds,
      int currentHp,
      String statusId,
      bool isShiny,
      String heldItemId});

  @override
  $PokemonStatSpreadCopyWith<$Res> get ivs;
  @override
  $PokemonStatSpreadCopyWith<$Res> get evs;
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
    Object? speciesId = null,
    Object? natureId = null,
    Object? abilityId = null,
    Object? level = null,
    Object? ivs = null,
    Object? evs = null,
    Object? knownMoveIds = null,
    Object? currentHp = null,
    Object? statusId = null,
    Object? isShiny = null,
    Object? heldItemId = null,
  }) {
    return _then(_$PlayerPokemonImpl(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      natureId: null == natureId
          ? _value.natureId
          : natureId // ignore: cast_nullable_to_non_nullable
              as String,
      abilityId: null == abilityId
          ? _value.abilityId
          : abilityId // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      ivs: null == ivs
          ? _value.ivs
          : ivs // ignore: cast_nullable_to_non_nullable
              as PokemonStatSpread,
      evs: null == evs
          ? _value.evs
          : evs // ignore: cast_nullable_to_non_nullable
              as PokemonStatSpread,
      knownMoveIds: null == knownMoveIds
          ? _value._knownMoveIds
          : knownMoveIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentHp: null == currentHp
          ? _value.currentHp
          : currentHp // ignore: cast_nullable_to_non_nullable
              as int,
      statusId: null == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as String,
      isShiny: null == isShiny
          ? _value.isShiny
          : isShiny // ignore: cast_nullable_to_non_nullable
              as bool,
      heldItemId: null == heldItemId
          ? _value.heldItemId
          : heldItemId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PlayerPokemonImpl extends _PlayerPokemon {
  const _$PlayerPokemonImpl(
      {required this.speciesId,
      required this.natureId,
      required this.abilityId,
      this.level = 1,
      this.ivs = const PokemonStatSpread(),
      this.evs = const PokemonStatSpread(),
      final List<String> knownMoveIds = const [],
      this.currentHp = 1,
      this.statusId = '',
      this.isShiny = false,
      this.heldItemId = ''})
      : _knownMoveIds = knownMoveIds,
        super._();

  factory _$PlayerPokemonImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerPokemonImplFromJson(json);

  @override
  final String speciesId;
  @override
  final String natureId;
  @override
  final String abilityId;
  @override
  @JsonKey()
  final int level;
  @override
  @JsonKey()
  final PokemonStatSpread ivs;
  @override
  @JsonKey()
  final PokemonStatSpread evs;
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
  final int currentHp;
  @override
  @JsonKey()
  final String statusId;
  @override
  @JsonKey()
  final bool isShiny;
  @override
  @JsonKey()
  final String heldItemId;

  @override
  String toString() {
    return 'PlayerPokemon(speciesId: $speciesId, natureId: $natureId, abilityId: $abilityId, level: $level, ivs: $ivs, evs: $evs, knownMoveIds: $knownMoveIds, currentHp: $currentHp, statusId: $statusId, isShiny: $isShiny, heldItemId: $heldItemId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerPokemonImpl &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.natureId, natureId) ||
                other.natureId == natureId) &&
            (identical(other.abilityId, abilityId) ||
                other.abilityId == abilityId) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.ivs, ivs) || other.ivs == ivs) &&
            (identical(other.evs, evs) || other.evs == evs) &&
            const DeepCollectionEquality()
                .equals(other._knownMoveIds, _knownMoveIds) &&
            (identical(other.currentHp, currentHp) ||
                other.currentHp == currentHp) &&
            (identical(other.statusId, statusId) ||
                other.statusId == statusId) &&
            (identical(other.isShiny, isShiny) || other.isShiny == isShiny) &&
            (identical(other.heldItemId, heldItemId) ||
                other.heldItemId == heldItemId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      speciesId,
      natureId,
      abilityId,
      level,
      ivs,
      evs,
      const DeepCollectionEquality().hash(_knownMoveIds),
      currentHp,
      statusId,
      isShiny,
      heldItemId);

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

abstract class _PlayerPokemon extends PlayerPokemon {
  const factory _PlayerPokemon(
      {required final String speciesId,
      required final String natureId,
      required final String abilityId,
      final int level,
      final PokemonStatSpread ivs,
      final PokemonStatSpread evs,
      final List<String> knownMoveIds,
      final int currentHp,
      final String statusId,
      final bool isShiny,
      final String heldItemId}) = _$PlayerPokemonImpl;
  const _PlayerPokemon._() : super._();

  factory _PlayerPokemon.fromJson(Map<String, dynamic> json) =
      _$PlayerPokemonImpl.fromJson;

  @override
  String get speciesId;
  @override
  String get natureId;
  @override
  String get abilityId;
  @override
  int get level;
  @override
  PokemonStatSpread get ivs;
  @override
  PokemonStatSpread get evs;
  @override
  List<String> get knownMoveIds;
  @override
  int get currentHp;
  @override
  String get statusId;
  @override
  bool get isShiny;
  @override
  String get heldItemId;

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
class _$PlayerPartyImpl extends _PlayerParty {
  const _$PlayerPartyImpl({final List<PlayerPokemon> members = const []})
      : _members = members,
        super._();

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

abstract class _PlayerParty extends PlayerParty {
  const factory _PlayerParty({final List<PlayerPokemon> members}) =
      _$PlayerPartyImpl;
  const _PlayerParty._() : super._();

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

  /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
  /// au moins une fois dans cette partie — utilisé pour prédicats
  /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
  List<String> get completedCutsceneIds => throw _privateConstructorUsedError;

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
      List<String> completedStepIds,
      List<String> completedCutsceneIds});
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
    Object? completedCutsceneIds = null,
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
      completedCutsceneIds: null == completedCutsceneIds
          ? _value.completedCutsceneIds
          : completedCutsceneIds // ignore: cast_nullable_to_non_nullable
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
      List<String> completedStepIds,
      List<String> completedCutsceneIds});
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
    Object? completedCutsceneIds = null,
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
      completedCutsceneIds: null == completedCutsceneIds
          ? _value._completedCutsceneIds
          : completedCutsceneIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PlayerProgressionImpl extends _PlayerProgression {
  const _$PlayerProgressionImpl(
      {final List<FieldAbility> unlockedFieldAbilities = const [],
      final List<String> storyFlags = const [],
      final List<String> completedStepIds = const [],
      final List<String> completedCutsceneIds = const []})
      : _unlockedFieldAbilities = unlockedFieldAbilities,
        _storyFlags = storyFlags,
        _completedStepIds = completedStepIds,
        _completedCutsceneIds = completedCutsceneIds,
        super._();

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

  /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
  /// au moins une fois dans cette partie — utilisé pour prédicats
  /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
  final List<String> _completedCutsceneIds;

  /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
  /// au moins une fois dans cette partie — utilisé pour prédicats
  /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
  @override
  @JsonKey()
  List<String> get completedCutsceneIds {
    if (_completedCutsceneIds is EqualUnmodifiableListView)
      return _completedCutsceneIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedCutsceneIds);
  }

  @override
  String toString() {
    return 'PlayerProgression(unlockedFieldAbilities: $unlockedFieldAbilities, storyFlags: $storyFlags, completedStepIds: $completedStepIds, completedCutsceneIds: $completedCutsceneIds)';
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
                .equals(other._completedStepIds, _completedStepIds) &&
            const DeepCollectionEquality()
                .equals(other._completedCutsceneIds, _completedCutsceneIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_unlockedFieldAbilities),
      const DeepCollectionEquality().hash(_storyFlags),
      const DeepCollectionEquality().hash(_completedStepIds),
      const DeepCollectionEquality().hash(_completedCutsceneIds));

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

abstract class _PlayerProgression extends PlayerProgression {
  const factory _PlayerProgression(
      {final List<FieldAbility> unlockedFieldAbilities,
      final List<String> storyFlags,
      final List<String> completedStepIds,
      final List<String> completedCutsceneIds}) = _$PlayerProgressionImpl;
  const _PlayerProgression._() : super._();

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

  /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
  /// au moins une fois dans cette partie — utilisé pour prédicats
  /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
  @override
  List<String> get completedCutsceneIds;

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerProgressionImplCopyWith<_$PlayerProgressionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrainerProfile _$TrainerProfileFromJson(Map<String, dynamic> json) {
  return _TrainerProfile.fromJson(json);
}

/// @nodoc
mixin _$TrainerProfile {
  String get name => throw _privateConstructorUsedError;
  List<String> get badgeIds => throw _privateConstructorUsedError;
  int get money => throw _privateConstructorUsedError;
  int get playtimeSeconds => throw _privateConstructorUsedError;

  /// Serializes this TrainerProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrainerProfileCopyWith<TrainerProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrainerProfileCopyWith<$Res> {
  factory $TrainerProfileCopyWith(
          TrainerProfile value, $Res Function(TrainerProfile) then) =
      _$TrainerProfileCopyWithImpl<$Res, TrainerProfile>;
  @useResult
  $Res call(
      {String name, List<String> badgeIds, int money, int playtimeSeconds});
}

/// @nodoc
class _$TrainerProfileCopyWithImpl<$Res, $Val extends TrainerProfile>
    implements $TrainerProfileCopyWith<$Res> {
  _$TrainerProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? badgeIds = null,
    Object? money = null,
    Object? playtimeSeconds = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      badgeIds: null == badgeIds
          ? _value.badgeIds
          : badgeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      money: null == money
          ? _value.money
          : money // ignore: cast_nullable_to_non_nullable
              as int,
      playtimeSeconds: null == playtimeSeconds
          ? _value.playtimeSeconds
          : playtimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrainerProfileImplCopyWith<$Res>
    implements $TrainerProfileCopyWith<$Res> {
  factory _$$TrainerProfileImplCopyWith(_$TrainerProfileImpl value,
          $Res Function(_$TrainerProfileImpl) then) =
      __$$TrainerProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name, List<String> badgeIds, int money, int playtimeSeconds});
}

/// @nodoc
class __$$TrainerProfileImplCopyWithImpl<$Res>
    extends _$TrainerProfileCopyWithImpl<$Res, _$TrainerProfileImpl>
    implements _$$TrainerProfileImplCopyWith<$Res> {
  __$$TrainerProfileImplCopyWithImpl(
      _$TrainerProfileImpl _value, $Res Function(_$TrainerProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? badgeIds = null,
    Object? money = null,
    Object? playtimeSeconds = null,
  }) {
    return _then(_$TrainerProfileImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      badgeIds: null == badgeIds
          ? _value._badgeIds
          : badgeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      money: null == money
          ? _value.money
          : money // ignore: cast_nullable_to_non_nullable
              as int,
      playtimeSeconds: null == playtimeSeconds
          ? _value.playtimeSeconds
          : playtimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TrainerProfileImpl extends _TrainerProfile {
  const _$TrainerProfileImpl(
      {required this.name,
      final List<String> badgeIds = const [],
      this.money = 0,
      this.playtimeSeconds = 0})
      : _badgeIds = badgeIds,
        super._();

  factory _$TrainerProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrainerProfileImplFromJson(json);

  @override
  final String name;
  final List<String> _badgeIds;
  @override
  @JsonKey()
  List<String> get badgeIds {
    if (_badgeIds is EqualUnmodifiableListView) return _badgeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_badgeIds);
  }

  @override
  @JsonKey()
  final int money;
  @override
  @JsonKey()
  final int playtimeSeconds;

  @override
  String toString() {
    return 'TrainerProfile(name: $name, badgeIds: $badgeIds, money: $money, playtimeSeconds: $playtimeSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrainerProfileImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._badgeIds, _badgeIds) &&
            (identical(other.money, money) || other.money == money) &&
            (identical(other.playtimeSeconds, playtimeSeconds) ||
                other.playtimeSeconds == playtimeSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name,
      const DeepCollectionEquality().hash(_badgeIds), money, playtimeSeconds);

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrainerProfileImplCopyWith<_$TrainerProfileImpl> get copyWith =>
      __$$TrainerProfileImplCopyWithImpl<_$TrainerProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrainerProfileImplToJson(
      this,
    );
  }
}

abstract class _TrainerProfile extends TrainerProfile {
  const factory _TrainerProfile(
      {required final String name,
      final List<String> badgeIds,
      final int money,
      final int playtimeSeconds}) = _$TrainerProfileImpl;
  const _TrainerProfile._() : super._();

  factory _TrainerProfile.fromJson(Map<String, dynamic> json) =
      _$TrainerProfileImpl.fromJson;

  @override
  String get name;
  @override
  List<String> get badgeIds;
  @override
  int get money;
  @override
  int get playtimeSeconds;

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrainerProfileImplCopyWith<_$TrainerProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BagEntry _$BagEntryFromJson(Map<String, dynamic> json) {
  return _BagEntry.fromJson(json);
}

/// @nodoc
mixin _$BagEntry {
  String get itemId => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;

  /// Serializes this BagEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BagEntryCopyWith<BagEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BagEntryCopyWith<$Res> {
  factory $BagEntryCopyWith(BagEntry value, $Res Function(BagEntry) then) =
      _$BagEntryCopyWithImpl<$Res, BagEntry>;
  @useResult
  $Res call({String itemId, String categoryId, int quantity});
}

/// @nodoc
class _$BagEntryCopyWithImpl<$Res, $Val extends BagEntry>
    implements $BagEntryCopyWith<$Res> {
  _$BagEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? categoryId = null,
    Object? quantity = null,
  }) {
    return _then(_value.copyWith(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BagEntryImplCopyWith<$Res>
    implements $BagEntryCopyWith<$Res> {
  factory _$$BagEntryImplCopyWith(
          _$BagEntryImpl value, $Res Function(_$BagEntryImpl) then) =
      __$$BagEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String itemId, String categoryId, int quantity});
}

/// @nodoc
class __$$BagEntryImplCopyWithImpl<$Res>
    extends _$BagEntryCopyWithImpl<$Res, _$BagEntryImpl>
    implements _$$BagEntryImplCopyWith<$Res> {
  __$$BagEntryImplCopyWithImpl(
      _$BagEntryImpl _value, $Res Function(_$BagEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? categoryId = null,
    Object? quantity = null,
  }) {
    return _then(_$BagEntryImpl(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$BagEntryImpl extends _BagEntry {
  const _$BagEntryImpl(
      {required this.itemId, required this.categoryId, required this.quantity})
      : super._();

  factory _$BagEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$BagEntryImplFromJson(json);

  @override
  final String itemId;
  @override
  final String categoryId;
  @override
  final int quantity;

  @override
  String toString() {
    return 'BagEntry(itemId: $itemId, categoryId: $categoryId, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BagEntryImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, itemId, categoryId, quantity);

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BagEntryImplCopyWith<_$BagEntryImpl> get copyWith =>
      __$$BagEntryImplCopyWithImpl<_$BagEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BagEntryImplToJson(
      this,
    );
  }
}

abstract class _BagEntry extends BagEntry {
  const factory _BagEntry(
      {required final String itemId,
      required final String categoryId,
      required final int quantity}) = _$BagEntryImpl;
  const _BagEntry._() : super._();

  factory _BagEntry.fromJson(Map<String, dynamic> json) =
      _$BagEntryImpl.fromJson;

  @override
  String get itemId;
  @override
  String get categoryId;
  @override
  int get quantity;

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BagEntryImplCopyWith<_$BagEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Bag _$BagFromJson(Map<String, dynamic> json) {
  return _Bag.fromJson(json);
}

/// @nodoc
mixin _$Bag {
  List<BagEntry> get entries => throw _privateConstructorUsedError;

  /// Serializes this Bag to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BagCopyWith<Bag> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BagCopyWith<$Res> {
  factory $BagCopyWith(Bag value, $Res Function(Bag) then) =
      _$BagCopyWithImpl<$Res, Bag>;
  @useResult
  $Res call({List<BagEntry> entries});
}

/// @nodoc
class _$BagCopyWithImpl<$Res, $Val extends Bag> implements $BagCopyWith<$Res> {
  _$BagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entries = null,
  }) {
    return _then(_value.copyWith(
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<BagEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BagImplCopyWith<$Res> implements $BagCopyWith<$Res> {
  factory _$$BagImplCopyWith(_$BagImpl value, $Res Function(_$BagImpl) then) =
      __$$BagImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<BagEntry> entries});
}

/// @nodoc
class __$$BagImplCopyWithImpl<$Res> extends _$BagCopyWithImpl<$Res, _$BagImpl>
    implements _$$BagImplCopyWith<$Res> {
  __$$BagImplCopyWithImpl(_$BagImpl _value, $Res Function(_$BagImpl) _then)
      : super(_value, _then);

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entries = null,
  }) {
    return _then(_$BagImpl(
      entries: null == entries
          ? _value._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<BagEntry>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$BagImpl extends _Bag {
  const _$BagImpl({final List<BagEntry> entries = const []})
      : _entries = entries,
        super._();

  factory _$BagImpl.fromJson(Map<String, dynamic> json) =>
      _$$BagImplFromJson(json);

  final List<BagEntry> _entries;
  @override
  @JsonKey()
  List<BagEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @override
  String toString() {
    return 'Bag(entries: $entries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BagImpl &&
            const DeepCollectionEquality().equals(other._entries, _entries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_entries));

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BagImplCopyWith<_$BagImpl> get copyWith =>
      __$$BagImplCopyWithImpl<_$BagImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BagImplToJson(
      this,
    );
  }
}

abstract class _Bag extends Bag {
  const factory _Bag({final List<BagEntry> entries}) = _$BagImpl;
  const _Bag._() : super._();

  factory _Bag.fromJson(Map<String, dynamic> json) = _$BagImpl.fromJson;

  @override
  List<BagEntry> get entries;

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BagImplCopyWith<_$BagImpl> get copyWith =>
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
  TrainerProfile get trainerProfile => throw _privateConstructorUsedError;
  Bag get bag => throw _privateConstructorUsedError;
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
      TrainerProfile trainerProfile,
      Bag bag,
      PlayerProgression progression,
      Map<String, String> properties});

  $GridPosCopyWith<$Res> get playerPosition;
  $PlayerPartyCopyWith<$Res> get party;
  $TrainerProfileCopyWith<$Res> get trainerProfile;
  $BagCopyWith<$Res> get bag;
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
    Object? trainerProfile = null,
    Object? bag = null,
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
      trainerProfile: null == trainerProfile
          ? _value.trainerProfile
          : trainerProfile // ignore: cast_nullable_to_non_nullable
              as TrainerProfile,
      bag: null == bag
          ? _value.bag
          : bag // ignore: cast_nullable_to_non_nullable
              as Bag,
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
  $TrainerProfileCopyWith<$Res> get trainerProfile {
    return $TrainerProfileCopyWith<$Res>(_value.trainerProfile, (value) {
      return _then(_value.copyWith(trainerProfile: value) as $Val);
    });
  }

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BagCopyWith<$Res> get bag {
    return $BagCopyWith<$Res>(_value.bag, (value) {
      return _then(_value.copyWith(bag: value) as $Val);
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
      TrainerProfile trainerProfile,
      Bag bag,
      PlayerProgression progression,
      Map<String, String> properties});

  @override
  $GridPosCopyWith<$Res> get playerPosition;
  @override
  $PlayerPartyCopyWith<$Res> get party;
  @override
  $TrainerProfileCopyWith<$Res> get trainerProfile;
  @override
  $BagCopyWith<$Res> get bag;
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
    Object? trainerProfile = null,
    Object? bag = null,
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
      trainerProfile: null == trainerProfile
          ? _value.trainerProfile
          : trainerProfile // ignore: cast_nullable_to_non_nullable
              as TrainerProfile,
      bag: null == bag
          ? _value.bag
          : bag // ignore: cast_nullable_to_non_nullable
              as Bag,
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
class _$SaveDataImpl extends _SaveData {
  const _$SaveDataImpl(
      {required this.saveId,
      this.currentMapId = '',
      this.playerPosition = const GridPos(x: 0, y: 0),
      this.playerFacing = EntityFacing.south,
      this.party = const PlayerParty(),
      this.trainerProfile = const TrainerProfile(name: 'Player'),
      this.bag = const Bag(),
      this.progression = const PlayerProgression(),
      final Map<String, String> properties = const {}})
      : _properties = properties,
        super._();

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
  final TrainerProfile trainerProfile;
  @override
  @JsonKey()
  final Bag bag;
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
    return 'SaveData(saveId: $saveId, currentMapId: $currentMapId, playerPosition: $playerPosition, playerFacing: $playerFacing, party: $party, trainerProfile: $trainerProfile, bag: $bag, progression: $progression, properties: $properties)';
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
            (identical(other.trainerProfile, trainerProfile) ||
                other.trainerProfile == trainerProfile) &&
            (identical(other.bag, bag) || other.bag == bag) &&
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
      trainerProfile,
      bag,
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

abstract class _SaveData extends SaveData {
  const factory _SaveData(
      {required final String saveId,
      final String currentMapId,
      final GridPos playerPosition,
      final EntityFacing playerFacing,
      final PlayerParty party,
      final TrainerProfile trainerProfile,
      final Bag bag,
      final PlayerProgression progression,
      final Map<String, String> properties}) = _$SaveDataImpl;
  const _SaveData._() : super._();

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
  TrainerProfile get trainerProfile;
  @override
  Bag get bag;
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
