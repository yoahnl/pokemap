// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_event_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MapEventDefinition _$MapEventDefinitionFromJson(Map<String, dynamic> json) {
  return _MapEventDefinition.fromJson(json);
}

/// @nodoc
mixin _$MapEventDefinition {
  /// Identifiant unique de l'événement.
  String get id => throw _privateConstructorUsedError;

  /// Titre optionnel (pour l'éditeur / debug).
  String get title => throw _privateConstructorUsedError;

  /// Pages de l'événement.
  /// La première page valide (dans l'ordre) est active.
  List<MapEventPage> get pages => throw _privateConstructorUsedError;

  /// Position de l'événement sur la map.
  EventPosition get position => throw _privateConstructorUsedError;

  /// Type d'événement (détermine le rendu / comportement).
  MapEventType get type => throw _privateConstructorUsedError;

  /// Métadonnées.
  Map<String, String> get metadata => throw _privateConstructorUsedError;

  /// Serializes this MapEventDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEventDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEventDefinitionCopyWith<MapEventDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEventDefinitionCopyWith<$Res> {
  factory $MapEventDefinitionCopyWith(
          MapEventDefinition value, $Res Function(MapEventDefinition) then) =
      _$MapEventDefinitionCopyWithImpl<$Res, MapEventDefinition>;
  @useResult
  $Res call(
      {String id,
      String title,
      List<MapEventPage> pages,
      EventPosition position,
      MapEventType type,
      Map<String, String> metadata});

  $EventPositionCopyWith<$Res> get position;
}

/// @nodoc
class _$MapEventDefinitionCopyWithImpl<$Res, $Val extends MapEventDefinition>
    implements $MapEventDefinitionCopyWith<$Res> {
  _$MapEventDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEventDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? pages = null,
    Object? position = null,
    Object? type = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      pages: null == pages
          ? _value.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as List<MapEventPage>,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as EventPosition,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MapEventType,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of MapEventDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EventPositionCopyWith<$Res> get position {
    return $EventPositionCopyWith<$Res>(_value.position, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapEventDefinitionImplCopyWith<$Res>
    implements $MapEventDefinitionCopyWith<$Res> {
  factory _$$MapEventDefinitionImplCopyWith(_$MapEventDefinitionImpl value,
          $Res Function(_$MapEventDefinitionImpl) then) =
      __$$MapEventDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      List<MapEventPage> pages,
      EventPosition position,
      MapEventType type,
      Map<String, String> metadata});

  @override
  $EventPositionCopyWith<$Res> get position;
}

/// @nodoc
class __$$MapEventDefinitionImplCopyWithImpl<$Res>
    extends _$MapEventDefinitionCopyWithImpl<$Res, _$MapEventDefinitionImpl>
    implements _$$MapEventDefinitionImplCopyWith<$Res> {
  __$$MapEventDefinitionImplCopyWithImpl(_$MapEventDefinitionImpl _value,
      $Res Function(_$MapEventDefinitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEventDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? pages = null,
    Object? position = null,
    Object? type = null,
    Object? metadata = null,
  }) {
    return _then(_$MapEventDefinitionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      pages: null == pages
          ? _value._pages
          : pages // ignore: cast_nullable_to_non_nullable
              as List<MapEventPage>,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as EventPosition,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MapEventType,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEventDefinitionImpl implements _MapEventDefinition {
  const _$MapEventDefinitionImpl(
      {required this.id,
      this.title = '',
      required final List<MapEventPage> pages,
      required this.position,
      this.type = MapEventType.actor,
      final Map<String, String> metadata = const {}})
      : _pages = pages,
        _metadata = metadata;

  factory _$MapEventDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEventDefinitionImplFromJson(json);

  /// Identifiant unique de l'événement.
  @override
  final String id;

  /// Titre optionnel (pour l'éditeur / debug).
  @override
  @JsonKey()
  final String title;

  /// Pages de l'événement.
  /// La première page valide (dans l'ordre) est active.
  final List<MapEventPage> _pages;

  /// Pages de l'événement.
  /// La première page valide (dans l'ordre) est active.
  @override
  List<MapEventPage> get pages {
    if (_pages is EqualUnmodifiableListView) return _pages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pages);
  }

  /// Position de l'événement sur la map.
  @override
  final EventPosition position;

  /// Type d'événement (détermine le rendu / comportement).
  @override
  @JsonKey()
  final MapEventType type;

  /// Métadonnées.
  final Map<String, String> _metadata;

  /// Métadonnées.
  @override
  @JsonKey()
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'MapEventDefinition(id: $id, title: $title, pages: $pages, position: $position, type: $type, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEventDefinitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._pages, _pages) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      const DeepCollectionEquality().hash(_pages),
      position,
      type,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of MapEventDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEventDefinitionImplCopyWith<_$MapEventDefinitionImpl> get copyWith =>
      __$$MapEventDefinitionImplCopyWithImpl<_$MapEventDefinitionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEventDefinitionImplToJson(
      this,
    );
  }
}

abstract class _MapEventDefinition implements MapEventDefinition {
  const factory _MapEventDefinition(
      {required final String id,
      final String title,
      required final List<MapEventPage> pages,
      required final EventPosition position,
      final MapEventType type,
      final Map<String, String> metadata}) = _$MapEventDefinitionImpl;

  factory _MapEventDefinition.fromJson(Map<String, dynamic> json) =
      _$MapEventDefinitionImpl.fromJson;

  /// Identifiant unique de l'événement.
  @override
  String get id;

  /// Titre optionnel (pour l'éditeur / debug).
  @override
  String get title;

  /// Pages de l'événement.
  /// La première page valide (dans l'ordre) est active.
  @override
  List<MapEventPage> get pages;

  /// Position de l'événement sur la map.
  @override
  EventPosition get position;

  /// Type d'événement (détermine le rendu / comportement).
  @override
  MapEventType get type;

  /// Métadonnées.
  @override
  Map<String, String> get metadata;

  /// Create a copy of MapEventDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEventDefinitionImplCopyWith<_$MapEventDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EventPosition _$EventPositionFromJson(Map<String, dynamic> json) {
  return _EventPosition.fromJson(json);
}

/// @nodoc
mixin _$EventPosition {
  /// Layer ID où placer l'événement.
  String get layerId => throw _privateConstructorUsedError;

  /// Coordonnée X.
  int get x => throw _privateConstructorUsedError;

  /// Coordonnée Y.
  int get y => throw _privateConstructorUsedError;

  /// Serializes this EventPosition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EventPosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventPositionCopyWith<EventPosition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventPositionCopyWith<$Res> {
  factory $EventPositionCopyWith(
          EventPosition value, $Res Function(EventPosition) then) =
      _$EventPositionCopyWithImpl<$Res, EventPosition>;
  @useResult
  $Res call({String layerId, int x, int y});
}

/// @nodoc
class _$EventPositionCopyWithImpl<$Res, $Val extends EventPosition>
    implements $EventPositionCopyWith<$Res> {
  _$EventPositionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventPosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? layerId = null,
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_value.copyWith(
      layerId: null == layerId
          ? _value.layerId
          : layerId // ignore: cast_nullable_to_non_nullable
              as String,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EventPositionImplCopyWith<$Res>
    implements $EventPositionCopyWith<$Res> {
  factory _$$EventPositionImplCopyWith(
          _$EventPositionImpl value, $Res Function(_$EventPositionImpl) then) =
      __$$EventPositionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String layerId, int x, int y});
}

/// @nodoc
class __$$EventPositionImplCopyWithImpl<$Res>
    extends _$EventPositionCopyWithImpl<$Res, _$EventPositionImpl>
    implements _$$EventPositionImplCopyWith<$Res> {
  __$$EventPositionImplCopyWithImpl(
      _$EventPositionImpl _value, $Res Function(_$EventPositionImpl) _then)
      : super(_value, _then);

  /// Create a copy of EventPosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? layerId = null,
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_$EventPositionImpl(
      layerId: null == layerId
          ? _value.layerId
          : layerId // ignore: cast_nullable_to_non_nullable
              as String,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventPositionImpl implements _EventPosition {
  const _$EventPositionImpl(
      {required this.layerId, required this.x, required this.y});

  factory _$EventPositionImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventPositionImplFromJson(json);

  /// Layer ID où placer l'événement.
  @override
  final String layerId;

  /// Coordonnée X.
  @override
  final int x;

  /// Coordonnée Y.
  @override
  final int y;

  @override
  String toString() {
    return 'EventPosition(layerId: $layerId, x: $x, y: $y)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventPositionImpl &&
            (identical(other.layerId, layerId) || other.layerId == layerId) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, layerId, x, y);

  /// Create a copy of EventPosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventPositionImplCopyWith<_$EventPositionImpl> get copyWith =>
      __$$EventPositionImplCopyWithImpl<_$EventPositionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventPositionImplToJson(
      this,
    );
  }
}

abstract class _EventPosition implements EventPosition {
  const factory _EventPosition(
      {required final String layerId,
      required final int x,
      required final int y}) = _$EventPositionImpl;

  factory _EventPosition.fromJson(Map<String, dynamic> json) =
      _$EventPositionImpl.fromJson;

  /// Layer ID où placer l'événement.
  @override
  String get layerId;

  /// Coordonnée X.
  @override
  int get x;

  /// Coordonnée Y.
  @override
  int get y;

  /// Create a copy of EventPosition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventPositionImplCopyWith<_$EventPositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MapEventPage _$MapEventPageFromJson(Map<String, dynamic> json) {
  return _MapEventPage.fromJson(json);
}

/// @nodoc
mixin _$MapEventPage {
  /// Numéro de page (0-based, pour référence).
  int get pageNumber => throw _privateConstructorUsedError;

  /// Conditions pour que cette page soit active.
  /// Si null ou vide, la page est toujours active (fallback).
  ScriptCondition? get condition => throw _privateConstructorUsedError;

  /// Référence au script à exécuter lors de l'interaction.
  ScriptRef? get script => throw _privateConstructorUsedError;

  /// ID du sprite / visuel.
  String? get spriteId => throw _privateConstructorUsedError;

  /// Message à afficher (alternative simple au script).
  String? get message => throw _privateConstructorUsedError;

  /// Si true, l'événement est invisible mais toujours interactif.
  bool get isHidden => throw _privateConstructorUsedError;

  /// Si true, l'événement est désactivé (pas d'interaction).
  bool get isDisabled => throw _privateConstructorUsedError;

  /// Métadonnées.
  Map<String, String> get metadata => throw _privateConstructorUsedError;

  /// Serializes this MapEventPage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEventPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEventPageCopyWith<MapEventPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEventPageCopyWith<$Res> {
  factory $MapEventPageCopyWith(
          MapEventPage value, $Res Function(MapEventPage) then) =
      _$MapEventPageCopyWithImpl<$Res, MapEventPage>;
  @useResult
  $Res call(
      {int pageNumber,
      ScriptCondition? condition,
      ScriptRef? script,
      String? spriteId,
      String? message,
      bool isHidden,
      bool isDisabled,
      Map<String, String> metadata});

  $ScriptConditionCopyWith<$Res>? get condition;
  $ScriptRefCopyWith<$Res>? get script;
}

/// @nodoc
class _$MapEventPageCopyWithImpl<$Res, $Val extends MapEventPage>
    implements $MapEventPageCopyWith<$Res> {
  _$MapEventPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEventPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pageNumber = null,
    Object? condition = freezed,
    Object? script = freezed,
    Object? spriteId = freezed,
    Object? message = freezed,
    Object? isHidden = null,
    Object? isDisabled = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      pageNumber: null == pageNumber
          ? _value.pageNumber
          : pageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      condition: freezed == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as ScriptCondition?,
      script: freezed == script
          ? _value.script
          : script // ignore: cast_nullable_to_non_nullable
              as ScriptRef?,
      spriteId: freezed == spriteId
          ? _value.spriteId
          : spriteId // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      isHidden: null == isHidden
          ? _value.isHidden
          : isHidden // ignore: cast_nullable_to_non_nullable
              as bool,
      isDisabled: null == isDisabled
          ? _value.isDisabled
          : isDisabled // ignore: cast_nullable_to_non_nullable
              as bool,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of MapEventPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptConditionCopyWith<$Res>? get condition {
    if (_value.condition == null) {
      return null;
    }

    return $ScriptConditionCopyWith<$Res>(_value.condition!, (value) {
      return _then(_value.copyWith(condition: value) as $Val);
    });
  }

  /// Create a copy of MapEventPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptRefCopyWith<$Res>? get script {
    if (_value.script == null) {
      return null;
    }

    return $ScriptRefCopyWith<$Res>(_value.script!, (value) {
      return _then(_value.copyWith(script: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapEventPageImplCopyWith<$Res>
    implements $MapEventPageCopyWith<$Res> {
  factory _$$MapEventPageImplCopyWith(
          _$MapEventPageImpl value, $Res Function(_$MapEventPageImpl) then) =
      __$$MapEventPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int pageNumber,
      ScriptCondition? condition,
      ScriptRef? script,
      String? spriteId,
      String? message,
      bool isHidden,
      bool isDisabled,
      Map<String, String> metadata});

  @override
  $ScriptConditionCopyWith<$Res>? get condition;
  @override
  $ScriptRefCopyWith<$Res>? get script;
}

/// @nodoc
class __$$MapEventPageImplCopyWithImpl<$Res>
    extends _$MapEventPageCopyWithImpl<$Res, _$MapEventPageImpl>
    implements _$$MapEventPageImplCopyWith<$Res> {
  __$$MapEventPageImplCopyWithImpl(
      _$MapEventPageImpl _value, $Res Function(_$MapEventPageImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEventPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pageNumber = null,
    Object? condition = freezed,
    Object? script = freezed,
    Object? spriteId = freezed,
    Object? message = freezed,
    Object? isHidden = null,
    Object? isDisabled = null,
    Object? metadata = null,
  }) {
    return _then(_$MapEventPageImpl(
      pageNumber: null == pageNumber
          ? _value.pageNumber
          : pageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      condition: freezed == condition
          ? _value.condition
          : condition // ignore: cast_nullable_to_non_nullable
              as ScriptCondition?,
      script: freezed == script
          ? _value.script
          : script // ignore: cast_nullable_to_non_nullable
              as ScriptRef?,
      spriteId: freezed == spriteId
          ? _value.spriteId
          : spriteId // ignore: cast_nullable_to_non_nullable
              as String?,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      isHidden: null == isHidden
          ? _value.isHidden
          : isHidden // ignore: cast_nullable_to_non_nullable
              as bool,
      isDisabled: null == isDisabled
          ? _value.isDisabled
          : isDisabled // ignore: cast_nullable_to_non_nullable
              as bool,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEventPageImpl implements _MapEventPage {
  const _$MapEventPageImpl(
      {required this.pageNumber,
      this.condition,
      this.script,
      this.spriteId,
      this.message,
      this.isHidden = false,
      this.isDisabled = false,
      final Map<String, String> metadata = const {}})
      : _metadata = metadata;

  factory _$MapEventPageImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEventPageImplFromJson(json);

  /// Numéro de page (0-based, pour référence).
  @override
  final int pageNumber;

  /// Conditions pour que cette page soit active.
  /// Si null ou vide, la page est toujours active (fallback).
  @override
  final ScriptCondition? condition;

  /// Référence au script à exécuter lors de l'interaction.
  @override
  final ScriptRef? script;

  /// ID du sprite / visuel.
  @override
  final String? spriteId;

  /// Message à afficher (alternative simple au script).
  @override
  final String? message;

  /// Si true, l'événement est invisible mais toujours interactif.
  @override
  @JsonKey()
  final bool isHidden;

  /// Si true, l'événement est désactivé (pas d'interaction).
  @override
  @JsonKey()
  final bool isDisabled;

  /// Métadonnées.
  final Map<String, String> _metadata;

  /// Métadonnées.
  @override
  @JsonKey()
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'MapEventPage(pageNumber: $pageNumber, condition: $condition, script: $script, spriteId: $spriteId, message: $message, isHidden: $isHidden, isDisabled: $isDisabled, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEventPageImpl &&
            (identical(other.pageNumber, pageNumber) ||
                other.pageNumber == pageNumber) &&
            (identical(other.condition, condition) ||
                other.condition == condition) &&
            (identical(other.script, script) || other.script == script) &&
            (identical(other.spriteId, spriteId) ||
                other.spriteId == spriteId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.isHidden, isHidden) ||
                other.isHidden == isHidden) &&
            (identical(other.isDisabled, isDisabled) ||
                other.isDisabled == isDisabled) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      pageNumber,
      condition,
      script,
      spriteId,
      message,
      isHidden,
      isDisabled,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of MapEventPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEventPageImplCopyWith<_$MapEventPageImpl> get copyWith =>
      __$$MapEventPageImplCopyWithImpl<_$MapEventPageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEventPageImplToJson(
      this,
    );
  }
}

abstract class _MapEventPage implements MapEventPage {
  const factory _MapEventPage(
      {required final int pageNumber,
      final ScriptCondition? condition,
      final ScriptRef? script,
      final String? spriteId,
      final String? message,
      final bool isHidden,
      final bool isDisabled,
      final Map<String, String> metadata}) = _$MapEventPageImpl;

  factory _MapEventPage.fromJson(Map<String, dynamic> json) =
      _$MapEventPageImpl.fromJson;

  /// Numéro de page (0-based, pour référence).
  @override
  int get pageNumber;

  /// Conditions pour que cette page soit active.
  /// Si null ou vide, la page est toujours active (fallback).
  @override
  ScriptCondition? get condition;

  /// Référence au script à exécuter lors de l'interaction.
  @override
  ScriptRef? get script;

  /// ID du sprite / visuel.
  @override
  String? get spriteId;

  /// Message à afficher (alternative simple au script).
  @override
  String? get message;

  /// Si true, l'événement est invisible mais toujours interactif.
  @override
  bool get isHidden;

  /// Si true, l'événement est désactivé (pas d'interaction).
  @override
  bool get isDisabled;

  /// Métadonnées.
  @override
  Map<String, String> get metadata;

  /// Create a copy of MapEventPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEventPageImplCopyWith<_$MapEventPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ScriptRef _$ScriptRefFromJson(Map<String, dynamic> json) {
  return _ScriptRef.fromJson(json);
}

/// @nodoc
mixin _$ScriptRef {
  /// ID du script asset.
  String get scriptId => throw _privateConstructorUsedError;

  /// Noeud de démarrage.
  /// Si null, utilise le defaultStartNode du script.
  String? get startNode => throw _privateConstructorUsedError;

  /// Serializes this ScriptRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScriptRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScriptRefCopyWith<ScriptRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptRefCopyWith<$Res> {
  factory $ScriptRefCopyWith(ScriptRef value, $Res Function(ScriptRef) then) =
      _$ScriptRefCopyWithImpl<$Res, ScriptRef>;
  @useResult
  $Res call({String scriptId, String? startNode});
}

/// @nodoc
class _$ScriptRefCopyWithImpl<$Res, $Val extends ScriptRef>
    implements $ScriptRefCopyWith<$Res> {
  _$ScriptRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scriptId = null,
    Object? startNode = freezed,
  }) {
    return _then(_value.copyWith(
      scriptId: null == scriptId
          ? _value.scriptId
          : scriptId // ignore: cast_nullable_to_non_nullable
              as String,
      startNode: freezed == startNode
          ? _value.startNode
          : startNode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScriptRefImplCopyWith<$Res>
    implements $ScriptRefCopyWith<$Res> {
  factory _$$ScriptRefImplCopyWith(
          _$ScriptRefImpl value, $Res Function(_$ScriptRefImpl) then) =
      __$$ScriptRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String scriptId, String? startNode});
}

/// @nodoc
class __$$ScriptRefImplCopyWithImpl<$Res>
    extends _$ScriptRefCopyWithImpl<$Res, _$ScriptRefImpl>
    implements _$$ScriptRefImplCopyWith<$Res> {
  __$$ScriptRefImplCopyWithImpl(
      _$ScriptRefImpl _value, $Res Function(_$ScriptRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scriptId = null,
    Object? startNode = freezed,
  }) {
    return _then(_$ScriptRefImpl(
      scriptId: null == scriptId
          ? _value.scriptId
          : scriptId // ignore: cast_nullable_to_non_nullable
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
class _$ScriptRefImpl implements _ScriptRef {
  const _$ScriptRefImpl({required this.scriptId, this.startNode});

  factory _$ScriptRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptRefImplFromJson(json);

  /// ID du script asset.
  @override
  final String scriptId;

  /// Noeud de démarrage.
  /// Si null, utilise le defaultStartNode du script.
  @override
  final String? startNode;

  @override
  String toString() {
    return 'ScriptRef(scriptId: $scriptId, startNode: $startNode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptRefImpl &&
            (identical(other.scriptId, scriptId) ||
                other.scriptId == scriptId) &&
            (identical(other.startNode, startNode) ||
                other.startNode == startNode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, scriptId, startNode);

  /// Create a copy of ScriptRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptRefImplCopyWith<_$ScriptRefImpl> get copyWith =>
      __$$ScriptRefImplCopyWithImpl<_$ScriptRefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptRefImplToJson(
      this,
    );
  }
}

abstract class _ScriptRef implements ScriptRef {
  const factory _ScriptRef(
      {required final String scriptId,
      final String? startNode}) = _$ScriptRefImpl;

  factory _ScriptRef.fromJson(Map<String, dynamic> json) =
      _$ScriptRefImpl.fromJson;

  /// ID du script asset.
  @override
  String get scriptId;

  /// Noeud de démarrage.
  /// Si null, utilise le defaultStartNode du script.
  @override
  String? get startNode;

  /// Create a copy of ScriptRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptRefImplCopyWith<_$ScriptRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ActiveEventPage _$ActiveEventPageFromJson(Map<String, dynamic> json) {
  return _ActiveEventPage.fromJson(json);
}

/// @nodoc
mixin _$ActiveEventPage {
  /// ID de l'événement.
  String get eventId => throw _privateConstructorUsedError;

  /// Page active.
  MapEventPage get page => throw _privateConstructorUsedError;

  /// Index de la page dans la liste.
  int get pageIndex => throw _privateConstructorUsedError;

  /// Serializes this ActiveEventPage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActiveEventPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActiveEventPageCopyWith<ActiveEventPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActiveEventPageCopyWith<$Res> {
  factory $ActiveEventPageCopyWith(
          ActiveEventPage value, $Res Function(ActiveEventPage) then) =
      _$ActiveEventPageCopyWithImpl<$Res, ActiveEventPage>;
  @useResult
  $Res call({String eventId, MapEventPage page, int pageIndex});

  $MapEventPageCopyWith<$Res> get page;
}

/// @nodoc
class _$ActiveEventPageCopyWithImpl<$Res, $Val extends ActiveEventPage>
    implements $ActiveEventPageCopyWith<$Res> {
  _$ActiveEventPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActiveEventPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? page = null,
    Object? pageIndex = null,
  }) {
    return _then(_value.copyWith(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as MapEventPage,
      pageIndex: null == pageIndex
          ? _value.pageIndex
          : pageIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of ActiveEventPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapEventPageCopyWith<$Res> get page {
    return $MapEventPageCopyWith<$Res>(_value.page, (value) {
      return _then(_value.copyWith(page: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ActiveEventPageImplCopyWith<$Res>
    implements $ActiveEventPageCopyWith<$Res> {
  factory _$$ActiveEventPageImplCopyWith(_$ActiveEventPageImpl value,
          $Res Function(_$ActiveEventPageImpl) then) =
      __$$ActiveEventPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String eventId, MapEventPage page, int pageIndex});

  @override
  $MapEventPageCopyWith<$Res> get page;
}

/// @nodoc
class __$$ActiveEventPageImplCopyWithImpl<$Res>
    extends _$ActiveEventPageCopyWithImpl<$Res, _$ActiveEventPageImpl>
    implements _$$ActiveEventPageImplCopyWith<$Res> {
  __$$ActiveEventPageImplCopyWithImpl(
      _$ActiveEventPageImpl _value, $Res Function(_$ActiveEventPageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ActiveEventPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? page = null,
    Object? pageIndex = null,
  }) {
    return _then(_$ActiveEventPageImpl(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as MapEventPage,
      pageIndex: null == pageIndex
          ? _value.pageIndex
          : pageIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ActiveEventPageImpl implements _ActiveEventPage {
  const _$ActiveEventPageImpl(
      {required this.eventId, required this.page, required this.pageIndex});

  factory _$ActiveEventPageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActiveEventPageImplFromJson(json);

  /// ID de l'événement.
  @override
  final String eventId;

  /// Page active.
  @override
  final MapEventPage page;

  /// Index de la page dans la liste.
  @override
  final int pageIndex;

  @override
  String toString() {
    return 'ActiveEventPage(eventId: $eventId, page: $page, pageIndex: $pageIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActiveEventPageImpl &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pageIndex, pageIndex) ||
                other.pageIndex == pageIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, eventId, page, pageIndex);

  /// Create a copy of ActiveEventPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActiveEventPageImplCopyWith<_$ActiveEventPageImpl> get copyWith =>
      __$$ActiveEventPageImplCopyWithImpl<_$ActiveEventPageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActiveEventPageImplToJson(
      this,
    );
  }
}

abstract class _ActiveEventPage implements ActiveEventPage {
  const factory _ActiveEventPage(
      {required final String eventId,
      required final MapEventPage page,
      required final int pageIndex}) = _$ActiveEventPageImpl;

  factory _ActiveEventPage.fromJson(Map<String, dynamic> json) =
      _$ActiveEventPageImpl.fromJson;

  /// ID de l'événement.
  @override
  String get eventId;

  /// Page active.
  @override
  MapEventPage get page;

  /// Index de la page dans la liste.
  @override
  int get pageIndex;

  /// Create a copy of ActiveEventPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActiveEventPageImplCopyWith<_$ActiveEventPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
