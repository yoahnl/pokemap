// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pokemon_move.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PokemonMoveSourceRefs _$PokemonMoveSourceRefsFromJson(
    Map<String, dynamic> json) {
  return _PokemonMoveSourceRefs.fromJson(json);
}

/// @nodoc
mixin _$PokemonMoveSourceRefs {
  String? get showdownMoveId => throw _privateConstructorUsedError;
  List<String> get showdownHooksPresent => throw _privateConstructorUsedError;

  /// Serializes this PokemonMoveSourceRefs to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonMoveSourceRefsCopyWith<PokemonMoveSourceRefs> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonMoveSourceRefsCopyWith<$Res> {
  factory $PokemonMoveSourceRefsCopyWith(PokemonMoveSourceRefs value,
          $Res Function(PokemonMoveSourceRefs) then) =
      _$PokemonMoveSourceRefsCopyWithImpl<$Res, PokemonMoveSourceRefs>;
  @useResult
  $Res call({String? showdownMoveId, List<String> showdownHooksPresent});
}

/// @nodoc
class _$PokemonMoveSourceRefsCopyWithImpl<$Res,
        $Val extends PokemonMoveSourceRefs>
    implements $PokemonMoveSourceRefsCopyWith<$Res> {
  _$PokemonMoveSourceRefsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showdownMoveId = freezed,
    Object? showdownHooksPresent = null,
  }) {
    return _then(_value.copyWith(
      showdownMoveId: freezed == showdownMoveId
          ? _value.showdownMoveId
          : showdownMoveId // ignore: cast_nullable_to_non_nullable
              as String?,
      showdownHooksPresent: null == showdownHooksPresent
          ? _value.showdownHooksPresent
          : showdownHooksPresent // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PokemonMoveSourceRefsImplCopyWith<$Res>
    implements $PokemonMoveSourceRefsCopyWith<$Res> {
  factory _$$PokemonMoveSourceRefsImplCopyWith(
          _$PokemonMoveSourceRefsImpl value,
          $Res Function(_$PokemonMoveSourceRefsImpl) then) =
      __$$PokemonMoveSourceRefsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? showdownMoveId, List<String> showdownHooksPresent});
}

/// @nodoc
class __$$PokemonMoveSourceRefsImplCopyWithImpl<$Res>
    extends _$PokemonMoveSourceRefsCopyWithImpl<$Res,
        _$PokemonMoveSourceRefsImpl>
    implements _$$PokemonMoveSourceRefsImplCopyWith<$Res> {
  __$$PokemonMoveSourceRefsImplCopyWithImpl(_$PokemonMoveSourceRefsImpl _value,
      $Res Function(_$PokemonMoveSourceRefsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showdownMoveId = freezed,
    Object? showdownHooksPresent = null,
  }) {
    return _then(_$PokemonMoveSourceRefsImpl(
      showdownMoveId: freezed == showdownMoveId
          ? _value.showdownMoveId
          : showdownMoveId // ignore: cast_nullable_to_non_nullable
              as String?,
      showdownHooksPresent: null == showdownHooksPresent
          ? _value._showdownHooksPresent
          : showdownHooksPresent // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveSourceRefsImpl extends _PokemonMoveSourceRefs {
  const _$PokemonMoveSourceRefsImpl(
      {this.showdownMoveId,
      final List<String> showdownHooksPresent = const <String>[]})
      : _showdownHooksPresent = showdownHooksPresent,
        super._();

  factory _$PokemonMoveSourceRefsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveSourceRefsImplFromJson(json);

  @override
  final String? showdownMoveId;
  final List<String> _showdownHooksPresent;
  @override
  @JsonKey()
  List<String> get showdownHooksPresent {
    if (_showdownHooksPresent is EqualUnmodifiableListView)
      return _showdownHooksPresent;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_showdownHooksPresent);
  }

  @override
  String toString() {
    return 'PokemonMoveSourceRefs(showdownMoveId: $showdownMoveId, showdownHooksPresent: $showdownHooksPresent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveSourceRefsImpl &&
            (identical(other.showdownMoveId, showdownMoveId) ||
                other.showdownMoveId == showdownMoveId) &&
            const DeepCollectionEquality()
                .equals(other._showdownHooksPresent, _showdownHooksPresent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, showdownMoveId,
      const DeepCollectionEquality().hash(_showdownHooksPresent));

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveSourceRefsImplCopyWith<_$PokemonMoveSourceRefsImpl>
      get copyWith => __$$PokemonMoveSourceRefsImplCopyWithImpl<
          _$PokemonMoveSourceRefsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveSourceRefsImplToJson(
      this,
    );
  }
}

abstract class _PokemonMoveSourceRefs extends PokemonMoveSourceRefs {
  const factory _PokemonMoveSourceRefs(
      {final String? showdownMoveId,
      final List<String> showdownHooksPresent}) = _$PokemonMoveSourceRefsImpl;
  const _PokemonMoveSourceRefs._() : super._();

  factory _PokemonMoveSourceRefs.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveSourceRefsImpl.fromJson;

  @override
  String? get showdownMoveId;
  @override
  List<String> get showdownHooksPresent;

  /// Create a copy of PokemonMoveSourceRefs
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveSourceRefsImplCopyWith<_$PokemonMoveSourceRefsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PokemonMove _$PokemonMoveFromJson(Map<String, dynamic> json) {
  return _PokemonMove.fromJson(json);
}

/// @nodoc
mixin _$PokemonMove {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  Map<String, String> get names => throw _privateConstructorUsedError;
  int? get generation => throw _privateConstructorUsedError;

  /// `showdown`, `seed`, `project_custom`, etc.
  String get source => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  PokemonMoveCategory get category => throw _privateConstructorUsedError;
  PokemonMoveTarget get target => throw _privateConstructorUsedError;
  int get basePower => throw _privateConstructorUsedError;
  PokemonMoveAccuracy get accuracy => throw _privateConstructorUsedError;
  int get pp => throw _privateConstructorUsedError;
  bool get noPpBoosts => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  int get critRatio => throw _privateConstructorUsedError;

  /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
  List<PokemonMoveFlag> get flags => throw _privateConstructorUsedError;

  /// Tous les comportements applicatifs vivent ici.
  List<PokemonMoveEffect> get effects => throw _privateConstructorUsedError;
  String get shortDescription => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  PokemonMoveEngineSupportLevel get engineSupportLevel =>
      throw _privateConstructorUsedError;
  List<String> get unsupportedReasons => throw _privateConstructorUsedError;
  PokemonMoveSourceRefs get sourceRefs => throw _privateConstructorUsedError;

  /// Serializes this PokemonMove to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonMoveCopyWith<PokemonMove> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonMoveCopyWith<$Res> {
  factory $PokemonMoveCopyWith(
          PokemonMove value, $Res Function(PokemonMove) then) =
      _$PokemonMoveCopyWithImpl<$Res, PokemonMove>;
  @useResult
  $Res call(
      {String id,
      String name,
      Map<String, String> names,
      int? generation,
      String source,
      String type,
      PokemonMoveCategory category,
      PokemonMoveTarget target,
      int basePower,
      PokemonMoveAccuracy accuracy,
      int pp,
      bool noPpBoosts,
      int priority,
      int critRatio,
      List<PokemonMoveFlag> flags,
      List<PokemonMoveEffect> effects,
      String shortDescription,
      String description,
      PokemonMoveEngineSupportLevel engineSupportLevel,
      List<String> unsupportedReasons,
      PokemonMoveSourceRefs sourceRefs});

  $PokemonMoveAccuracyCopyWith<$Res> get accuracy;
  $PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs;
}

/// @nodoc
class _$PokemonMoveCopyWithImpl<$Res, $Val extends PokemonMove>
    implements $PokemonMoveCopyWith<$Res> {
  _$PokemonMoveCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? names = null,
    Object? generation = freezed,
    Object? source = null,
    Object? type = null,
    Object? category = null,
    Object? target = null,
    Object? basePower = null,
    Object? accuracy = null,
    Object? pp = null,
    Object? noPpBoosts = null,
    Object? priority = null,
    Object? critRatio = null,
    Object? flags = null,
    Object? effects = null,
    Object? shortDescription = null,
    Object? description = null,
    Object? engineSupportLevel = null,
    Object? unsupportedReasons = null,
    Object? sourceRefs = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      names: null == names
          ? _value.names
          : names // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      generation: freezed == generation
          ? _value.generation
          : generation // ignore: cast_nullable_to_non_nullable
              as int?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PokemonMoveCategory,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as PokemonMoveTarget,
      basePower: null == basePower
          ? _value.basePower
          : basePower // ignore: cast_nullable_to_non_nullable
              as int,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as PokemonMoveAccuracy,
      pp: null == pp
          ? _value.pp
          : pp // ignore: cast_nullable_to_non_nullable
              as int,
      noPpBoosts: null == noPpBoosts
          ? _value.noPpBoosts
          : noPpBoosts // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      critRatio: null == critRatio
          ? _value.critRatio
          : critRatio // ignore: cast_nullable_to_non_nullable
              as int,
      flags: null == flags
          ? _value.flags
          : flags // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveFlag>,
      effects: null == effects
          ? _value.effects
          : effects // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveEffect>,
      shortDescription: null == shortDescription
          ? _value.shortDescription
          : shortDescription // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      engineSupportLevel: null == engineSupportLevel
          ? _value.engineSupportLevel
          : engineSupportLevel // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEngineSupportLevel,
      unsupportedReasons: null == unsupportedReasons
          ? _value.unsupportedReasons
          : unsupportedReasons // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sourceRefs: null == sourceRefs
          ? _value.sourceRefs
          : sourceRefs // ignore: cast_nullable_to_non_nullable
              as PokemonMoveSourceRefs,
    ) as $Val);
  }

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PokemonMoveAccuracyCopyWith<$Res> get accuracy {
    return $PokemonMoveAccuracyCopyWith<$Res>(_value.accuracy, (value) {
      return _then(_value.copyWith(accuracy: value) as $Val);
    });
  }

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs {
    return $PokemonMoveSourceRefsCopyWith<$Res>(_value.sourceRefs, (value) {
      return _then(_value.copyWith(sourceRefs: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PokemonMoveImplCopyWith<$Res>
    implements $PokemonMoveCopyWith<$Res> {
  factory _$$PokemonMoveImplCopyWith(
          _$PokemonMoveImpl value, $Res Function(_$PokemonMoveImpl) then) =
      __$$PokemonMoveImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      Map<String, String> names,
      int? generation,
      String source,
      String type,
      PokemonMoveCategory category,
      PokemonMoveTarget target,
      int basePower,
      PokemonMoveAccuracy accuracy,
      int pp,
      bool noPpBoosts,
      int priority,
      int critRatio,
      List<PokemonMoveFlag> flags,
      List<PokemonMoveEffect> effects,
      String shortDescription,
      String description,
      PokemonMoveEngineSupportLevel engineSupportLevel,
      List<String> unsupportedReasons,
      PokemonMoveSourceRefs sourceRefs});

  @override
  $PokemonMoveAccuracyCopyWith<$Res> get accuracy;
  @override
  $PokemonMoveSourceRefsCopyWith<$Res> get sourceRefs;
}

/// @nodoc
class __$$PokemonMoveImplCopyWithImpl<$Res>
    extends _$PokemonMoveCopyWithImpl<$Res, _$PokemonMoveImpl>
    implements _$$PokemonMoveImplCopyWith<$Res> {
  __$$PokemonMoveImplCopyWithImpl(
      _$PokemonMoveImpl _value, $Res Function(_$PokemonMoveImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? names = null,
    Object? generation = freezed,
    Object? source = null,
    Object? type = null,
    Object? category = null,
    Object? target = null,
    Object? basePower = null,
    Object? accuracy = null,
    Object? pp = null,
    Object? noPpBoosts = null,
    Object? priority = null,
    Object? critRatio = null,
    Object? flags = null,
    Object? effects = null,
    Object? shortDescription = null,
    Object? description = null,
    Object? engineSupportLevel = null,
    Object? unsupportedReasons = null,
    Object? sourceRefs = null,
  }) {
    return _then(_$PokemonMoveImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      names: null == names
          ? _value._names
          : names // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      generation: freezed == generation
          ? _value.generation
          : generation // ignore: cast_nullable_to_non_nullable
              as int?,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PokemonMoveCategory,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as PokemonMoveTarget,
      basePower: null == basePower
          ? _value.basePower
          : basePower // ignore: cast_nullable_to_non_nullable
              as int,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as PokemonMoveAccuracy,
      pp: null == pp
          ? _value.pp
          : pp // ignore: cast_nullable_to_non_nullable
              as int,
      noPpBoosts: null == noPpBoosts
          ? _value.noPpBoosts
          : noPpBoosts // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      critRatio: null == critRatio
          ? _value.critRatio
          : critRatio // ignore: cast_nullable_to_non_nullable
              as int,
      flags: null == flags
          ? _value._flags
          : flags // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveFlag>,
      effects: null == effects
          ? _value._effects
          : effects // ignore: cast_nullable_to_non_nullable
              as List<PokemonMoveEffect>,
      shortDescription: null == shortDescription
          ? _value.shortDescription
          : shortDescription // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      engineSupportLevel: null == engineSupportLevel
          ? _value.engineSupportLevel
          : engineSupportLevel // ignore: cast_nullable_to_non_nullable
              as PokemonMoveEngineSupportLevel,
      unsupportedReasons: null == unsupportedReasons
          ? _value._unsupportedReasons
          : unsupportedReasons // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sourceRefs: null == sourceRefs
          ? _value.sourceRefs
          : sourceRefs // ignore: cast_nullable_to_non_nullable
              as PokemonMoveSourceRefs,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonMoveImpl extends _PokemonMove {
  const _$PokemonMoveImpl(
      {required this.id,
      required this.name,
      final Map<String, String> names = const <String, String>{},
      this.generation,
      this.source = '',
      required this.type,
      required this.category,
      this.target = PokemonMoveTarget.normal,
      this.basePower = 0,
      required this.accuracy,
      this.pp = 0,
      this.noPpBoosts = false,
      this.priority = 0,
      this.critRatio = 1,
      final List<PokemonMoveFlag> flags = const <PokemonMoveFlag>[],
      final List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
      this.shortDescription = '',
      this.description = '',
      this.engineSupportLevel = PokemonMoveEngineSupportLevel.catalogOnly,
      final List<String> unsupportedReasons = const <String>[],
      this.sourceRefs = const PokemonMoveSourceRefs()})
      : _names = names,
        _flags = flags,
        _effects = effects,
        _unsupportedReasons = unsupportedReasons,
        super._();

  factory _$PokemonMoveImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonMoveImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final Map<String, String> _names;
  @override
  @JsonKey()
  Map<String, String> get names {
    if (_names is EqualUnmodifiableMapView) return _names;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_names);
  }

  @override
  final int? generation;

  /// `showdown`, `seed`, `project_custom`, etc.
  @override
  @JsonKey()
  final String source;
  @override
  final String type;
  @override
  final PokemonMoveCategory category;
  @override
  @JsonKey()
  final PokemonMoveTarget target;
  @override
  @JsonKey()
  final int basePower;
  @override
  final PokemonMoveAccuracy accuracy;
  @override
  @JsonKey()
  final int pp;
  @override
  @JsonKey()
  final bool noPpBoosts;
  @override
  @JsonKey()
  final int priority;
  @override
  @JsonKey()
  final int critRatio;

  /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
  final List<PokemonMoveFlag> _flags;

  /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
  @override
  @JsonKey()
  List<PokemonMoveFlag> get flags {
    if (_flags is EqualUnmodifiableListView) return _flags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_flags);
  }

  /// Tous les comportements applicatifs vivent ici.
  final List<PokemonMoveEffect> _effects;

  /// Tous les comportements applicatifs vivent ici.
  @override
  @JsonKey()
  List<PokemonMoveEffect> get effects {
    if (_effects is EqualUnmodifiableListView) return _effects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_effects);
  }

  @override
  @JsonKey()
  final String shortDescription;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final PokemonMoveEngineSupportLevel engineSupportLevel;
  final List<String> _unsupportedReasons;
  @override
  @JsonKey()
  List<String> get unsupportedReasons {
    if (_unsupportedReasons is EqualUnmodifiableListView)
      return _unsupportedReasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unsupportedReasons);
  }

  @override
  @JsonKey()
  final PokemonMoveSourceRefs sourceRefs;

  @override
  String toString() {
    return 'PokemonMove(id: $id, name: $name, names: $names, generation: $generation, source: $source, type: $type, category: $category, target: $target, basePower: $basePower, accuracy: $accuracy, pp: $pp, noPpBoosts: $noPpBoosts, priority: $priority, critRatio: $critRatio, flags: $flags, effects: $effects, shortDescription: $shortDescription, description: $description, engineSupportLevel: $engineSupportLevel, unsupportedReasons: $unsupportedReasons, sourceRefs: $sourceRefs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonMoveImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._names, _names) &&
            (identical(other.generation, generation) ||
                other.generation == generation) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.basePower, basePower) ||
                other.basePower == basePower) &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy) &&
            (identical(other.pp, pp) || other.pp == pp) &&
            (identical(other.noPpBoosts, noPpBoosts) ||
                other.noPpBoosts == noPpBoosts) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.critRatio, critRatio) ||
                other.critRatio == critRatio) &&
            const DeepCollectionEquality().equals(other._flags, _flags) &&
            const DeepCollectionEquality().equals(other._effects, _effects) &&
            (identical(other.shortDescription, shortDescription) ||
                other.shortDescription == shortDescription) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.engineSupportLevel, engineSupportLevel) ||
                other.engineSupportLevel == engineSupportLevel) &&
            const DeepCollectionEquality()
                .equals(other._unsupportedReasons, _unsupportedReasons) &&
            (identical(other.sourceRefs, sourceRefs) ||
                other.sourceRefs == sourceRefs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        const DeepCollectionEquality().hash(_names),
        generation,
        source,
        type,
        category,
        target,
        basePower,
        accuracy,
        pp,
        noPpBoosts,
        priority,
        critRatio,
        const DeepCollectionEquality().hash(_flags),
        const DeepCollectionEquality().hash(_effects),
        shortDescription,
        description,
        engineSupportLevel,
        const DeepCollectionEquality().hash(_unsupportedReasons),
        sourceRefs
      ]);

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonMoveImplCopyWith<_$PokemonMoveImpl> get copyWith =>
      __$$PokemonMoveImplCopyWithImpl<_$PokemonMoveImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonMoveImplToJson(
      this,
    );
  }
}

abstract class _PokemonMove extends PokemonMove {
  const factory _PokemonMove(
      {required final String id,
      required final String name,
      final Map<String, String> names,
      final int? generation,
      final String source,
      required final String type,
      required final PokemonMoveCategory category,
      final PokemonMoveTarget target,
      final int basePower,
      required final PokemonMoveAccuracy accuracy,
      final int pp,
      final bool noPpBoosts,
      final int priority,
      final int critRatio,
      final List<PokemonMoveFlag> flags,
      final List<PokemonMoveEffect> effects,
      final String shortDescription,
      final String description,
      final PokemonMoveEngineSupportLevel engineSupportLevel,
      final List<String> unsupportedReasons,
      final PokemonMoveSourceRefs sourceRefs}) = _$PokemonMoveImpl;
  const _PokemonMove._() : super._();

  factory _PokemonMove.fromJson(Map<String, dynamic> json) =
      _$PokemonMoveImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  Map<String, String> get names;
  @override
  int? get generation;

  /// `showdown`, `seed`, `project_custom`, etc.
  @override
  String get source;
  @override
  String get type;
  @override
  PokemonMoveCategory get category;
  @override
  PokemonMoveTarget get target;
  @override
  int get basePower;
  @override
  PokemonMoveAccuracy get accuracy;
  @override
  int get pp;
  @override
  bool get noPpBoosts;
  @override
  int get priority;
  @override
  int get critRatio;

  /// Sémantiquement un ensemble, stocké comme liste sérialisable stable.
  @override
  List<PokemonMoveFlag> get flags;

  /// Tous les comportements applicatifs vivent ici.
  @override
  List<PokemonMoveEffect> get effects;
  @override
  String get shortDescription;
  @override
  String get description;
  @override
  PokemonMoveEngineSupportLevel get engineSupportLevel;
  @override
  List<String> get unsupportedReasons;
  @override
  PokemonMoveSourceRefs get sourceRefs;

  /// Create a copy of PokemonMove
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonMoveImplCopyWith<_$PokemonMoveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
