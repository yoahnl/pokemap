// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_entity_editor_visual.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MapEntityEditorVisual _$MapEntityEditorVisualFromJson(
    Map<String, dynamic> json) {
  return _MapEntityEditorVisual.fromJson(json);
}

/// @nodoc
mixin _$MapEntityEditorVisual {
  String get elementId => throw _privateConstructorUsedError;

  /// Force le rendu de cette entité "élément projet" au-dessus du décor
  /// avant-plan.
  ///
  /// Cas visé :
  /// - petits props décoratifs représentés comme entités (ex. Poké Ball
  ///   posée sur une table) ;
  /// - besoin de garder un objet volontairement visible au-dessus d'un
  ///   overlay de tiles qui masquerait sinon l'entité.
  ///
  /// Non-objectif :
  /// - ce n'est pas un système générique de z-index ;
  /// - ce flag n'a pas vocation à remplacer le tri "par les pieds" des
  ///   vrais acteurs gameplay ;
  /// - il sert seulement à faire passer l'entité dans la passe foreground
  ///   quand elle est rendue comme ProjectElementEntry.
  bool get renderInForeground => throw _privateConstructorUsedError;

  /// Serializes this MapEntityEditorVisual to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MapEntityEditorVisual
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapEntityEditorVisualCopyWith<MapEntityEditorVisual> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapEntityEditorVisualCopyWith<$Res> {
  factory $MapEntityEditorVisualCopyWith(MapEntityEditorVisual value,
          $Res Function(MapEntityEditorVisual) then) =
      _$MapEntityEditorVisualCopyWithImpl<$Res, MapEntityEditorVisual>;
  @useResult
  $Res call({String elementId, bool renderInForeground});
}

/// @nodoc
class _$MapEntityEditorVisualCopyWithImpl<$Res,
        $Val extends MapEntityEditorVisual>
    implements $MapEntityEditorVisualCopyWith<$Res> {
  _$MapEntityEditorVisualCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapEntityEditorVisual
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? elementId = null,
    Object? renderInForeground = null,
  }) {
    return _then(_value.copyWith(
      elementId: null == elementId
          ? _value.elementId
          : elementId // ignore: cast_nullable_to_non_nullable
              as String,
      renderInForeground: null == renderInForeground
          ? _value.renderInForeground
          : renderInForeground // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MapEntityEditorVisualImplCopyWith<$Res>
    implements $MapEntityEditorVisualCopyWith<$Res> {
  factory _$$MapEntityEditorVisualImplCopyWith(
          _$MapEntityEditorVisualImpl value,
          $Res Function(_$MapEntityEditorVisualImpl) then) =
      __$$MapEntityEditorVisualImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String elementId, bool renderInForeground});
}

/// @nodoc
class __$$MapEntityEditorVisualImplCopyWithImpl<$Res>
    extends _$MapEntityEditorVisualCopyWithImpl<$Res,
        _$MapEntityEditorVisualImpl>
    implements _$$MapEntityEditorVisualImplCopyWith<$Res> {
  __$$MapEntityEditorVisualImplCopyWithImpl(_$MapEntityEditorVisualImpl _value,
      $Res Function(_$MapEntityEditorVisualImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapEntityEditorVisual
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? elementId = null,
    Object? renderInForeground = null,
  }) {
    return _then(_$MapEntityEditorVisualImpl(
      elementId: null == elementId
          ? _value.elementId
          : elementId // ignore: cast_nullable_to_non_nullable
              as String,
      renderInForeground: null == renderInForeground
          ? _value.renderInForeground
          : renderInForeground // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$MapEntityEditorVisualImpl implements _MapEntityEditorVisual {
  const _$MapEntityEditorVisualImpl(
      {required this.elementId, this.renderInForeground = false});

  factory _$MapEntityEditorVisualImpl.fromJson(Map<String, dynamic> json) =>
      _$$MapEntityEditorVisualImplFromJson(json);

  @override
  final String elementId;

  /// Force le rendu de cette entité "élément projet" au-dessus du décor
  /// avant-plan.
  ///
  /// Cas visé :
  /// - petits props décoratifs représentés comme entités (ex. Poké Ball
  ///   posée sur une table) ;
  /// - besoin de garder un objet volontairement visible au-dessus d'un
  ///   overlay de tiles qui masquerait sinon l'entité.
  ///
  /// Non-objectif :
  /// - ce n'est pas un système générique de z-index ;
  /// - ce flag n'a pas vocation à remplacer le tri "par les pieds" des
  ///   vrais acteurs gameplay ;
  /// - il sert seulement à faire passer l'entité dans la passe foreground
  ///   quand elle est rendue comme ProjectElementEntry.
  @override
  @JsonKey()
  final bool renderInForeground;

  @override
  String toString() {
    return 'MapEntityEditorVisual(elementId: $elementId, renderInForeground: $renderInForeground)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapEntityEditorVisualImpl &&
            (identical(other.elementId, elementId) ||
                other.elementId == elementId) &&
            (identical(other.renderInForeground, renderInForeground) ||
                other.renderInForeground == renderInForeground));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, elementId, renderInForeground);

  /// Create a copy of MapEntityEditorVisual
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapEntityEditorVisualImplCopyWith<_$MapEntityEditorVisualImpl>
      get copyWith => __$$MapEntityEditorVisualImplCopyWithImpl<
          _$MapEntityEditorVisualImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MapEntityEditorVisualImplToJson(
      this,
    );
  }
}

abstract class _MapEntityEditorVisual implements MapEntityEditorVisual {
  const factory _MapEntityEditorVisual(
      {required final String elementId,
      final bool renderInForeground}) = _$MapEntityEditorVisualImpl;

  factory _MapEntityEditorVisual.fromJson(Map<String, dynamic> json) =
      _$MapEntityEditorVisualImpl.fromJson;

  @override
  String get elementId;

  /// Force le rendu de cette entité "élément projet" au-dessus du décor
  /// avant-plan.
  ///
  /// Cas visé :
  /// - petits props décoratifs représentés comme entités (ex. Poké Ball
  ///   posée sur une table) ;
  /// - besoin de garder un objet volontairement visible au-dessus d'un
  ///   overlay de tiles qui masquerait sinon l'entité.
  ///
  /// Non-objectif :
  /// - ce n'est pas un système générique de z-index ;
  /// - ce flag n'a pas vocation à remplacer le tri "par les pieds" des
  ///   vrais acteurs gameplay ;
  /// - il sert seulement à faire passer l'entité dans la passe foreground
  ///   quand elle est rendue comme ProjectElementEntry.
  @override
  bool get renderInForeground;

  /// Create a copy of MapEntityEditorVisual
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapEntityEditorVisualImplCopyWith<_$MapEntityEditorVisualImpl>
      get copyWith => throw _privateConstructorUsedError;
}
