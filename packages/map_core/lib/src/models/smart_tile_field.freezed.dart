// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'smart_tile_field.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
SmartTileField _$SmartTileFieldFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'cell':
          return SmartTileCellField.fromJson(
            json
          );
                case 'corner':
          return SmartTileCornerField.fromJson(
            json
          );
                case 'edge':
          return SmartTileEdgeField.fromJson(
            json
          );
                case 'mixed':
          return SmartTileMixedField.fromJson(
            json
          );

          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'SmartTileField',
  'Invalid union type "${json['kind']}"!'
);
        }

}

/// @nodoc
mixin _$SmartTileField {

 List<int> get semanticCells;
/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileFieldCopyWith<SmartTileField> get copyWith => _$SmartTileFieldCopyWithImpl<SmartTileField>(this as SmartTileField, _$identity);

  /// Serializes this SmartTileField to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileField&&const DeepCollectionEquality().equals(other.semanticCells, semanticCells));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(semanticCells));

@override
String toString() {
  return 'SmartTileField(semanticCells: $semanticCells)';
}


}

/// @nodoc
abstract mixin class $SmartTileFieldCopyWith<$Res>  {
  factory $SmartTileFieldCopyWith(SmartTileField value, $Res Function(SmartTileField) _then) = _$SmartTileFieldCopyWithImpl;
@useResult
$Res call({
 List<int> semanticCells
});




}
/// @nodoc
class _$SmartTileFieldCopyWithImpl<$Res>
    implements $SmartTileFieldCopyWith<$Res> {
  _$SmartTileFieldCopyWithImpl(this._self, this._then);

  final SmartTileField _self;
  final $Res Function(SmartTileField) _then;

/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? semanticCells = null,}) {
  return _then(_self.copyWith(
semanticCells: null == semanticCells ? _self.semanticCells : semanticCells // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartTileField].
extension SmartTileFieldPatterns on SmartTileField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SmartTileCellField value)?  cell,TResult Function( SmartTileCornerField value)?  corner,TResult Function( SmartTileEdgeField value)?  edge,TResult Function( SmartTileMixedField value)?  mixed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SmartTileCellField() when cell != null:
return cell(_that);case SmartTileCornerField() when corner != null:
return corner(_that);case SmartTileEdgeField() when edge != null:
return edge(_that);case SmartTileMixedField() when mixed != null:
return mixed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SmartTileCellField value)  cell,required TResult Function( SmartTileCornerField value)  corner,required TResult Function( SmartTileEdgeField value)  edge,required TResult Function( SmartTileMixedField value)  mixed,}){
final _that = this;
switch (_that) {
case SmartTileCellField():
return cell(_that);case SmartTileCornerField():
return corner(_that);case SmartTileEdgeField():
return edge(_that);case SmartTileMixedField():
return mixed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SmartTileCellField value)?  cell,TResult? Function( SmartTileCornerField value)?  corner,TResult? Function( SmartTileEdgeField value)?  edge,TResult? Function( SmartTileMixedField value)?  mixed,}){
final _that = this;
switch (_that) {
case SmartTileCellField() when cell != null:
return cell(_that);case SmartTileCornerField() when corner != null:
return corner(_that);case SmartTileEdgeField() when edge != null:
return edge(_that);case SmartTileMixedField() when mixed != null:
return mixed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<int> semanticCells)?  cell,TResult Function( List<int> semanticCells,  List<int> corners)?  corner,TResult Function( List<int> semanticCells,  List<int> horizontalEdges,  List<int> verticalEdges)?  edge,TResult Function( List<int> semanticCells,  List<int> horizontalEdges,  List<int> verticalEdges,  List<int> corners)?  mixed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SmartTileCellField() when cell != null:
return cell(_that.semanticCells);case SmartTileCornerField() when corner != null:
return corner(_that.semanticCells,_that.corners);case SmartTileEdgeField() when edge != null:
return edge(_that.semanticCells,_that.horizontalEdges,_that.verticalEdges);case SmartTileMixedField() when mixed != null:
return mixed(_that.semanticCells,_that.horizontalEdges,_that.verticalEdges,_that.corners);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<int> semanticCells)  cell,required TResult Function( List<int> semanticCells,  List<int> corners)  corner,required TResult Function( List<int> semanticCells,  List<int> horizontalEdges,  List<int> verticalEdges)  edge,required TResult Function( List<int> semanticCells,  List<int> horizontalEdges,  List<int> verticalEdges,  List<int> corners)  mixed,}) {final _that = this;
switch (_that) {
case SmartTileCellField():
return cell(_that.semanticCells);case SmartTileCornerField():
return corner(_that.semanticCells,_that.corners);case SmartTileEdgeField():
return edge(_that.semanticCells,_that.horizontalEdges,_that.verticalEdges);case SmartTileMixedField():
return mixed(_that.semanticCells,_that.horizontalEdges,_that.verticalEdges,_that.corners);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<int> semanticCells)?  cell,TResult? Function( List<int> semanticCells,  List<int> corners)?  corner,TResult? Function( List<int> semanticCells,  List<int> horizontalEdges,  List<int> verticalEdges)?  edge,TResult? Function( List<int> semanticCells,  List<int> horizontalEdges,  List<int> verticalEdges,  List<int> corners)?  mixed,}) {final _that = this;
switch (_that) {
case SmartTileCellField() when cell != null:
return cell(_that.semanticCells);case SmartTileCornerField() when corner != null:
return corner(_that.semanticCells,_that.corners);case SmartTileEdgeField() when edge != null:
return edge(_that.semanticCells,_that.horizontalEdges,_that.verticalEdges);case SmartTileMixedField() when mixed != null:
return mixed(_that.semanticCells,_that.horizontalEdges,_that.verticalEdges,_that.corners);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class SmartTileCellField implements SmartTileField {
  const SmartTileCellField({final  List<int> semanticCells = const <int>[], final  String? $type}): _semanticCells = semanticCells,$type = $type ?? 'cell';
  factory SmartTileCellField.fromJson(Map<String, dynamic> json) => _$SmartTileCellFieldFromJson(json);

 final  List<int> _semanticCells;
@override@JsonKey() List<int> get semanticCells {
  if (_semanticCells is EqualUnmodifiableListView) return _semanticCells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_semanticCells);
}


@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileCellFieldCopyWith<SmartTileCellField> get copyWith => _$SmartTileCellFieldCopyWithImpl<SmartTileCellField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileCellFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileCellField&&const DeepCollectionEquality().equals(other._semanticCells, _semanticCells));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_semanticCells));

@override
String toString() {
  return 'SmartTileField.cell(semanticCells: $semanticCells)';
}


}

/// @nodoc
abstract mixin class $SmartTileCellFieldCopyWith<$Res> implements $SmartTileFieldCopyWith<$Res> {
  factory $SmartTileCellFieldCopyWith(SmartTileCellField value, $Res Function(SmartTileCellField) _then) = _$SmartTileCellFieldCopyWithImpl;
@override @useResult
$Res call({
 List<int> semanticCells
});




}
/// @nodoc
class _$SmartTileCellFieldCopyWithImpl<$Res>
    implements $SmartTileCellFieldCopyWith<$Res> {
  _$SmartTileCellFieldCopyWithImpl(this._self, this._then);

  final SmartTileCellField _self;
  final $Res Function(SmartTileCellField) _then;

/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? semanticCells = null,}) {
  return _then(SmartTileCellField(
semanticCells: null == semanticCells ? _self._semanticCells : semanticCells // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SmartTileCornerField implements SmartTileField {
  const SmartTileCornerField({final  List<int> semanticCells = const <int>[], final  List<int> corners = const <int>[], final  String? $type}): _semanticCells = semanticCells,_corners = corners,$type = $type ?? 'corner';
  factory SmartTileCornerField.fromJson(Map<String, dynamic> json) => _$SmartTileCornerFieldFromJson(json);

 final  List<int> _semanticCells;
@override@JsonKey() List<int> get semanticCells {
  if (_semanticCells is EqualUnmodifiableListView) return _semanticCells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_semanticCells);
}

 final  List<int> _corners;
@JsonKey() List<int> get corners {
  if (_corners is EqualUnmodifiableListView) return _corners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_corners);
}


@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileCornerFieldCopyWith<SmartTileCornerField> get copyWith => _$SmartTileCornerFieldCopyWithImpl<SmartTileCornerField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileCornerFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileCornerField&&const DeepCollectionEquality().equals(other._semanticCells, _semanticCells)&&const DeepCollectionEquality().equals(other._corners, _corners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_semanticCells),const DeepCollectionEquality().hash(_corners));

@override
String toString() {
  return 'SmartTileField.corner(semanticCells: $semanticCells, corners: $corners)';
}


}

/// @nodoc
abstract mixin class $SmartTileCornerFieldCopyWith<$Res> implements $SmartTileFieldCopyWith<$Res> {
  factory $SmartTileCornerFieldCopyWith(SmartTileCornerField value, $Res Function(SmartTileCornerField) _then) = _$SmartTileCornerFieldCopyWithImpl;
@override @useResult
$Res call({
 List<int> semanticCells, List<int> corners
});




}
/// @nodoc
class _$SmartTileCornerFieldCopyWithImpl<$Res>
    implements $SmartTileCornerFieldCopyWith<$Res> {
  _$SmartTileCornerFieldCopyWithImpl(this._self, this._then);

  final SmartTileCornerField _self;
  final $Res Function(SmartTileCornerField) _then;

/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? semanticCells = null,Object? corners = null,}) {
  return _then(SmartTileCornerField(
semanticCells: null == semanticCells ? _self._semanticCells : semanticCells // ignore: cast_nullable_to_non_nullable
as List<int>,corners: null == corners ? _self._corners : corners // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SmartTileEdgeField implements SmartTileField {
  const SmartTileEdgeField({final  List<int> semanticCells = const <int>[], final  List<int> horizontalEdges = const <int>[], final  List<int> verticalEdges = const <int>[], final  String? $type}): _semanticCells = semanticCells,_horizontalEdges = horizontalEdges,_verticalEdges = verticalEdges,$type = $type ?? 'edge';
  factory SmartTileEdgeField.fromJson(Map<String, dynamic> json) => _$SmartTileEdgeFieldFromJson(json);

 final  List<int> _semanticCells;
@override@JsonKey() List<int> get semanticCells {
  if (_semanticCells is EqualUnmodifiableListView) return _semanticCells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_semanticCells);
}

 final  List<int> _horizontalEdges;
@JsonKey() List<int> get horizontalEdges {
  if (_horizontalEdges is EqualUnmodifiableListView) return _horizontalEdges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_horizontalEdges);
}

 final  List<int> _verticalEdges;
@JsonKey() List<int> get verticalEdges {
  if (_verticalEdges is EqualUnmodifiableListView) return _verticalEdges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_verticalEdges);
}


@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileEdgeFieldCopyWith<SmartTileEdgeField> get copyWith => _$SmartTileEdgeFieldCopyWithImpl<SmartTileEdgeField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileEdgeFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileEdgeField&&const DeepCollectionEquality().equals(other._semanticCells, _semanticCells)&&const DeepCollectionEquality().equals(other._horizontalEdges, _horizontalEdges)&&const DeepCollectionEquality().equals(other._verticalEdges, _verticalEdges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_semanticCells),const DeepCollectionEquality().hash(_horizontalEdges),const DeepCollectionEquality().hash(_verticalEdges));

@override
String toString() {
  return 'SmartTileField.edge(semanticCells: $semanticCells, horizontalEdges: $horizontalEdges, verticalEdges: $verticalEdges)';
}


}

/// @nodoc
abstract mixin class $SmartTileEdgeFieldCopyWith<$Res> implements $SmartTileFieldCopyWith<$Res> {
  factory $SmartTileEdgeFieldCopyWith(SmartTileEdgeField value, $Res Function(SmartTileEdgeField) _then) = _$SmartTileEdgeFieldCopyWithImpl;
@override @useResult
$Res call({
 List<int> semanticCells, List<int> horizontalEdges, List<int> verticalEdges
});




}
/// @nodoc
class _$SmartTileEdgeFieldCopyWithImpl<$Res>
    implements $SmartTileEdgeFieldCopyWith<$Res> {
  _$SmartTileEdgeFieldCopyWithImpl(this._self, this._then);

  final SmartTileEdgeField _self;
  final $Res Function(SmartTileEdgeField) _then;

/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? semanticCells = null,Object? horizontalEdges = null,Object? verticalEdges = null,}) {
  return _then(SmartTileEdgeField(
semanticCells: null == semanticCells ? _self._semanticCells : semanticCells // ignore: cast_nullable_to_non_nullable
as List<int>,horizontalEdges: null == horizontalEdges ? _self._horizontalEdges : horizontalEdges // ignore: cast_nullable_to_non_nullable
as List<int>,verticalEdges: null == verticalEdges ? _self._verticalEdges : verticalEdges // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SmartTileMixedField implements SmartTileField {
  const SmartTileMixedField({final  List<int> semanticCells = const <int>[], final  List<int> horizontalEdges = const <int>[], final  List<int> verticalEdges = const <int>[], final  List<int> corners = const <int>[], final  String? $type}): _semanticCells = semanticCells,_horizontalEdges = horizontalEdges,_verticalEdges = verticalEdges,_corners = corners,$type = $type ?? 'mixed';
  factory SmartTileMixedField.fromJson(Map<String, dynamic> json) => _$SmartTileMixedFieldFromJson(json);

 final  List<int> _semanticCells;
@override@JsonKey() List<int> get semanticCells {
  if (_semanticCells is EqualUnmodifiableListView) return _semanticCells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_semanticCells);
}

 final  List<int> _horizontalEdges;
@JsonKey() List<int> get horizontalEdges {
  if (_horizontalEdges is EqualUnmodifiableListView) return _horizontalEdges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_horizontalEdges);
}

 final  List<int> _verticalEdges;
@JsonKey() List<int> get verticalEdges {
  if (_verticalEdges is EqualUnmodifiableListView) return _verticalEdges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_verticalEdges);
}

 final  List<int> _corners;
@JsonKey() List<int> get corners {
  if (_corners is EqualUnmodifiableListView) return _corners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_corners);
}


@JsonKey(name: 'kind')
final String $type;


/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartTileMixedFieldCopyWith<SmartTileMixedField> get copyWith => _$SmartTileMixedFieldCopyWithImpl<SmartTileMixedField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartTileMixedFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartTileMixedField&&const DeepCollectionEquality().equals(other._semanticCells, _semanticCells)&&const DeepCollectionEquality().equals(other._horizontalEdges, _horizontalEdges)&&const DeepCollectionEquality().equals(other._verticalEdges, _verticalEdges)&&const DeepCollectionEquality().equals(other._corners, _corners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_semanticCells),const DeepCollectionEquality().hash(_horizontalEdges),const DeepCollectionEquality().hash(_verticalEdges),const DeepCollectionEquality().hash(_corners));

@override
String toString() {
  return 'SmartTileField.mixed(semanticCells: $semanticCells, horizontalEdges: $horizontalEdges, verticalEdges: $verticalEdges, corners: $corners)';
}


}

/// @nodoc
abstract mixin class $SmartTileMixedFieldCopyWith<$Res> implements $SmartTileFieldCopyWith<$Res> {
  factory $SmartTileMixedFieldCopyWith(SmartTileMixedField value, $Res Function(SmartTileMixedField) _then) = _$SmartTileMixedFieldCopyWithImpl;
@override @useResult
$Res call({
 List<int> semanticCells, List<int> horizontalEdges, List<int> verticalEdges, List<int> corners
});




}
/// @nodoc
class _$SmartTileMixedFieldCopyWithImpl<$Res>
    implements $SmartTileMixedFieldCopyWith<$Res> {
  _$SmartTileMixedFieldCopyWithImpl(this._self, this._then);

  final SmartTileMixedField _self;
  final $Res Function(SmartTileMixedField) _then;

/// Create a copy of SmartTileField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? semanticCells = null,Object? horizontalEdges = null,Object? verticalEdges = null,Object? corners = null,}) {
  return _then(SmartTileMixedField(
semanticCells: null == semanticCells ? _self._semanticCells : semanticCells // ignore: cast_nullable_to_non_nullable
as List<int>,horizontalEdges: null == horizontalEdges ? _self._horizontalEdges : horizontalEdges // ignore: cast_nullable_to_non_nullable
as List<int>,verticalEdges: null == verticalEdges ? _self._verticalEdges : verticalEdges // ignore: cast_nullable_to_non_nullable
as List<int>,corners: null == corners ? _self._corners : corners // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
