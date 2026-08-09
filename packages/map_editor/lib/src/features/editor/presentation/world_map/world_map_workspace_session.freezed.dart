// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'world_map_workspace_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorldMapWorkspaceSession {

 bool get explorerExpanded; bool get inspectorVisible; double get inspectorWidth; WorldMapToolFamily get activeFamily; WorldMapPaintSubtool get lastPaintSubtool; WorldMapPlacementSubtool get lastPlacementSubtool; Map<String, WorldMapPaintSubtool> get lastPaintSubtoolByLayerId; WorldMapInspectorKind? get pinnedInspectorKind; GridPos? get selectedCell; String? get selectedCellMapId;
/// Create a copy of WorldMapWorkspaceSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorldMapWorkspaceSessionCopyWith<WorldMapWorkspaceSession> get copyWith => _$WorldMapWorkspaceSessionCopyWithImpl<WorldMapWorkspaceSession>(this as WorldMapWorkspaceSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorldMapWorkspaceSession&&(identical(other.explorerExpanded, explorerExpanded) || other.explorerExpanded == explorerExpanded)&&(identical(other.inspectorVisible, inspectorVisible) || other.inspectorVisible == inspectorVisible)&&(identical(other.inspectorWidth, inspectorWidth) || other.inspectorWidth == inspectorWidth)&&(identical(other.activeFamily, activeFamily) || other.activeFamily == activeFamily)&&(identical(other.lastPaintSubtool, lastPaintSubtool) || other.lastPaintSubtool == lastPaintSubtool)&&(identical(other.lastPlacementSubtool, lastPlacementSubtool) || other.lastPlacementSubtool == lastPlacementSubtool)&&const DeepCollectionEquality().equals(other.lastPaintSubtoolByLayerId, lastPaintSubtoolByLayerId)&&(identical(other.pinnedInspectorKind, pinnedInspectorKind) || other.pinnedInspectorKind == pinnedInspectorKind)&&(identical(other.selectedCell, selectedCell) || other.selectedCell == selectedCell)&&(identical(other.selectedCellMapId, selectedCellMapId) || other.selectedCellMapId == selectedCellMapId));
}


@override
int get hashCode => Object.hash(runtimeType,explorerExpanded,inspectorVisible,inspectorWidth,activeFamily,lastPaintSubtool,lastPlacementSubtool,const DeepCollectionEquality().hash(lastPaintSubtoolByLayerId),pinnedInspectorKind,selectedCell,selectedCellMapId);

@override
String toString() {
  return 'WorldMapWorkspaceSession(explorerExpanded: $explorerExpanded, inspectorVisible: $inspectorVisible, inspectorWidth: $inspectorWidth, activeFamily: $activeFamily, lastPaintSubtool: $lastPaintSubtool, lastPlacementSubtool: $lastPlacementSubtool, lastPaintSubtoolByLayerId: $lastPaintSubtoolByLayerId, pinnedInspectorKind: $pinnedInspectorKind, selectedCell: $selectedCell, selectedCellMapId: $selectedCellMapId)';
}


}

/// @nodoc
abstract mixin class $WorldMapWorkspaceSessionCopyWith<$Res>  {
  factory $WorldMapWorkspaceSessionCopyWith(WorldMapWorkspaceSession value, $Res Function(WorldMapWorkspaceSession) _then) = _$WorldMapWorkspaceSessionCopyWithImpl;
@useResult
$Res call({
 bool explorerExpanded, bool inspectorVisible, double inspectorWidth, WorldMapToolFamily activeFamily, WorldMapPaintSubtool lastPaintSubtool, WorldMapPlacementSubtool lastPlacementSubtool, Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId, WorldMapInspectorKind? pinnedInspectorKind, GridPos? selectedCell, String? selectedCellMapId
});


$GridPosCopyWith<$Res>? get selectedCell;

}
/// @nodoc
class _$WorldMapWorkspaceSessionCopyWithImpl<$Res>
    implements $WorldMapWorkspaceSessionCopyWith<$Res> {
  _$WorldMapWorkspaceSessionCopyWithImpl(this._self, this._then);

  final WorldMapWorkspaceSession _self;
  final $Res Function(WorldMapWorkspaceSession) _then;

/// Create a copy of WorldMapWorkspaceSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? explorerExpanded = null,Object? inspectorVisible = null,Object? inspectorWidth = null,Object? activeFamily = null,Object? lastPaintSubtool = null,Object? lastPlacementSubtool = null,Object? lastPaintSubtoolByLayerId = null,Object? pinnedInspectorKind = freezed,Object? selectedCell = freezed,Object? selectedCellMapId = freezed,}) {
  return _then(_self.copyWith(
explorerExpanded: null == explorerExpanded ? _self.explorerExpanded : explorerExpanded // ignore: cast_nullable_to_non_nullable
as bool,inspectorVisible: null == inspectorVisible ? _self.inspectorVisible : inspectorVisible // ignore: cast_nullable_to_non_nullable
as bool,inspectorWidth: null == inspectorWidth ? _self.inspectorWidth : inspectorWidth // ignore: cast_nullable_to_non_nullable
as double,activeFamily: null == activeFamily ? _self.activeFamily : activeFamily // ignore: cast_nullable_to_non_nullable
as WorldMapToolFamily,lastPaintSubtool: null == lastPaintSubtool ? _self.lastPaintSubtool : lastPaintSubtool // ignore: cast_nullable_to_non_nullable
as WorldMapPaintSubtool,lastPlacementSubtool: null == lastPlacementSubtool ? _self.lastPlacementSubtool : lastPlacementSubtool // ignore: cast_nullable_to_non_nullable
as WorldMapPlacementSubtool,lastPaintSubtoolByLayerId: null == lastPaintSubtoolByLayerId ? _self.lastPaintSubtoolByLayerId : lastPaintSubtoolByLayerId // ignore: cast_nullable_to_non_nullable
as Map<String, WorldMapPaintSubtool>,pinnedInspectorKind: freezed == pinnedInspectorKind ? _self.pinnedInspectorKind : pinnedInspectorKind // ignore: cast_nullable_to_non_nullable
as WorldMapInspectorKind?,selectedCell: freezed == selectedCell ? _self.selectedCell : selectedCell // ignore: cast_nullable_to_non_nullable
as GridPos?,selectedCellMapId: freezed == selectedCellMapId ? _self.selectedCellMapId : selectedCellMapId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of WorldMapWorkspaceSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res>? get selectedCell {
    if (_self.selectedCell == null) {
    return null;
  }

  return $GridPosCopyWith<$Res>(_self.selectedCell!, (value) {
    return _then(_self.copyWith(selectedCell: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorldMapWorkspaceSession].
extension WorldMapWorkspaceSessionPatterns on WorldMapWorkspaceSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorldMapWorkspaceSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorldMapWorkspaceSession() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorldMapWorkspaceSession value)  $default,){
final _that = this;
switch (_that) {
case _WorldMapWorkspaceSession():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorldMapWorkspaceSession value)?  $default,){
final _that = this;
switch (_that) {
case _WorldMapWorkspaceSession() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool explorerExpanded,  bool inspectorVisible,  double inspectorWidth,  WorldMapToolFamily activeFamily,  WorldMapPaintSubtool lastPaintSubtool,  WorldMapPlacementSubtool lastPlacementSubtool,  Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId,  WorldMapInspectorKind? pinnedInspectorKind,  GridPos? selectedCell,  String? selectedCellMapId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorldMapWorkspaceSession() when $default != null:
return $default(_that.explorerExpanded,_that.inspectorVisible,_that.inspectorWidth,_that.activeFamily,_that.lastPaintSubtool,_that.lastPlacementSubtool,_that.lastPaintSubtoolByLayerId,_that.pinnedInspectorKind,_that.selectedCell,_that.selectedCellMapId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool explorerExpanded,  bool inspectorVisible,  double inspectorWidth,  WorldMapToolFamily activeFamily,  WorldMapPaintSubtool lastPaintSubtool,  WorldMapPlacementSubtool lastPlacementSubtool,  Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId,  WorldMapInspectorKind? pinnedInspectorKind,  GridPos? selectedCell,  String? selectedCellMapId)  $default,) {final _that = this;
switch (_that) {
case _WorldMapWorkspaceSession():
return $default(_that.explorerExpanded,_that.inspectorVisible,_that.inspectorWidth,_that.activeFamily,_that.lastPaintSubtool,_that.lastPlacementSubtool,_that.lastPaintSubtoolByLayerId,_that.pinnedInspectorKind,_that.selectedCell,_that.selectedCellMapId);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool explorerExpanded,  bool inspectorVisible,  double inspectorWidth,  WorldMapToolFamily activeFamily,  WorldMapPaintSubtool lastPaintSubtool,  WorldMapPlacementSubtool lastPlacementSubtool,  Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId,  WorldMapInspectorKind? pinnedInspectorKind,  GridPos? selectedCell,  String? selectedCellMapId)?  $default,) {final _that = this;
switch (_that) {
case _WorldMapWorkspaceSession() when $default != null:
return $default(_that.explorerExpanded,_that.inspectorVisible,_that.inspectorWidth,_that.activeFamily,_that.lastPaintSubtool,_that.lastPlacementSubtool,_that.lastPaintSubtoolByLayerId,_that.pinnedInspectorKind,_that.selectedCell,_that.selectedCellMapId);case _:
  return null;

}
}

}

/// @nodoc


class _WorldMapWorkspaceSession implements WorldMapWorkspaceSession {
  const _WorldMapWorkspaceSession({this.explorerExpanded = true, this.inspectorVisible = true, this.inspectorWidth = PokeMapDesktopLayoutTokens.inspectorWidth, this.activeFamily = WorldMapToolFamily.selection, this.lastPaintSubtool = WorldMapPaintSubtool.tile, this.lastPlacementSubtool = WorldMapPlacementSubtool.object, final  Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId = const <String, WorldMapPaintSubtool>{}, this.pinnedInspectorKind, this.selectedCell, this.selectedCellMapId}): _lastPaintSubtoolByLayerId = lastPaintSubtoolByLayerId;
  

@override@JsonKey() final  bool explorerExpanded;
@override@JsonKey() final  bool inspectorVisible;
@override@JsonKey() final  double inspectorWidth;
@override@JsonKey() final  WorldMapToolFamily activeFamily;
@override@JsonKey() final  WorldMapPaintSubtool lastPaintSubtool;
@override@JsonKey() final  WorldMapPlacementSubtool lastPlacementSubtool;
 final  Map<String, WorldMapPaintSubtool> _lastPaintSubtoolByLayerId;
@override@JsonKey() Map<String, WorldMapPaintSubtool> get lastPaintSubtoolByLayerId {
  if (_lastPaintSubtoolByLayerId is EqualUnmodifiableMapView) return _lastPaintSubtoolByLayerId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_lastPaintSubtoolByLayerId);
}

@override final  WorldMapInspectorKind? pinnedInspectorKind;
@override final  GridPos? selectedCell;
@override final  String? selectedCellMapId;

/// Create a copy of WorldMapWorkspaceSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorldMapWorkspaceSessionCopyWith<_WorldMapWorkspaceSession> get copyWith => __$WorldMapWorkspaceSessionCopyWithImpl<_WorldMapWorkspaceSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorldMapWorkspaceSession&&(identical(other.explorerExpanded, explorerExpanded) || other.explorerExpanded == explorerExpanded)&&(identical(other.inspectorVisible, inspectorVisible) || other.inspectorVisible == inspectorVisible)&&(identical(other.inspectorWidth, inspectorWidth) || other.inspectorWidth == inspectorWidth)&&(identical(other.activeFamily, activeFamily) || other.activeFamily == activeFamily)&&(identical(other.lastPaintSubtool, lastPaintSubtool) || other.lastPaintSubtool == lastPaintSubtool)&&(identical(other.lastPlacementSubtool, lastPlacementSubtool) || other.lastPlacementSubtool == lastPlacementSubtool)&&const DeepCollectionEquality().equals(other._lastPaintSubtoolByLayerId, _lastPaintSubtoolByLayerId)&&(identical(other.pinnedInspectorKind, pinnedInspectorKind) || other.pinnedInspectorKind == pinnedInspectorKind)&&(identical(other.selectedCell, selectedCell) || other.selectedCell == selectedCell)&&(identical(other.selectedCellMapId, selectedCellMapId) || other.selectedCellMapId == selectedCellMapId));
}


@override
int get hashCode => Object.hash(runtimeType,explorerExpanded,inspectorVisible,inspectorWidth,activeFamily,lastPaintSubtool,lastPlacementSubtool,const DeepCollectionEquality().hash(_lastPaintSubtoolByLayerId),pinnedInspectorKind,selectedCell,selectedCellMapId);

@override
String toString() {
  return 'WorldMapWorkspaceSession(explorerExpanded: $explorerExpanded, inspectorVisible: $inspectorVisible, inspectorWidth: $inspectorWidth, activeFamily: $activeFamily, lastPaintSubtool: $lastPaintSubtool, lastPlacementSubtool: $lastPlacementSubtool, lastPaintSubtoolByLayerId: $lastPaintSubtoolByLayerId, pinnedInspectorKind: $pinnedInspectorKind, selectedCell: $selectedCell, selectedCellMapId: $selectedCellMapId)';
}


}

/// @nodoc
abstract mixin class _$WorldMapWorkspaceSessionCopyWith<$Res> implements $WorldMapWorkspaceSessionCopyWith<$Res> {
  factory _$WorldMapWorkspaceSessionCopyWith(_WorldMapWorkspaceSession value, $Res Function(_WorldMapWorkspaceSession) _then) = __$WorldMapWorkspaceSessionCopyWithImpl;
@override @useResult
$Res call({
 bool explorerExpanded, bool inspectorVisible, double inspectorWidth, WorldMapToolFamily activeFamily, WorldMapPaintSubtool lastPaintSubtool, WorldMapPlacementSubtool lastPlacementSubtool, Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId, WorldMapInspectorKind? pinnedInspectorKind, GridPos? selectedCell, String? selectedCellMapId
});


@override $GridPosCopyWith<$Res>? get selectedCell;

}
/// @nodoc
class __$WorldMapWorkspaceSessionCopyWithImpl<$Res>
    implements _$WorldMapWorkspaceSessionCopyWith<$Res> {
  __$WorldMapWorkspaceSessionCopyWithImpl(this._self, this._then);

  final _WorldMapWorkspaceSession _self;
  final $Res Function(_WorldMapWorkspaceSession) _then;

/// Create a copy of WorldMapWorkspaceSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? explorerExpanded = null,Object? inspectorVisible = null,Object? inspectorWidth = null,Object? activeFamily = null,Object? lastPaintSubtool = null,Object? lastPlacementSubtool = null,Object? lastPaintSubtoolByLayerId = null,Object? pinnedInspectorKind = freezed,Object? selectedCell = freezed,Object? selectedCellMapId = freezed,}) {
  return _then(_WorldMapWorkspaceSession(
explorerExpanded: null == explorerExpanded ? _self.explorerExpanded : explorerExpanded // ignore: cast_nullable_to_non_nullable
as bool,inspectorVisible: null == inspectorVisible ? _self.inspectorVisible : inspectorVisible // ignore: cast_nullable_to_non_nullable
as bool,inspectorWidth: null == inspectorWidth ? _self.inspectorWidth : inspectorWidth // ignore: cast_nullable_to_non_nullable
as double,activeFamily: null == activeFamily ? _self.activeFamily : activeFamily // ignore: cast_nullable_to_non_nullable
as WorldMapToolFamily,lastPaintSubtool: null == lastPaintSubtool ? _self.lastPaintSubtool : lastPaintSubtool // ignore: cast_nullable_to_non_nullable
as WorldMapPaintSubtool,lastPlacementSubtool: null == lastPlacementSubtool ? _self.lastPlacementSubtool : lastPlacementSubtool // ignore: cast_nullable_to_non_nullable
as WorldMapPlacementSubtool,lastPaintSubtoolByLayerId: null == lastPaintSubtoolByLayerId ? _self._lastPaintSubtoolByLayerId : lastPaintSubtoolByLayerId // ignore: cast_nullable_to_non_nullable
as Map<String, WorldMapPaintSubtool>,pinnedInspectorKind: freezed == pinnedInspectorKind ? _self.pinnedInspectorKind : pinnedInspectorKind // ignore: cast_nullable_to_non_nullable
as WorldMapInspectorKind?,selectedCell: freezed == selectedCell ? _self.selectedCell : selectedCell // ignore: cast_nullable_to_non_nullable
as GridPos?,selectedCellMapId: freezed == selectedCellMapId ? _self.selectedCellMapId : selectedCellMapId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of WorldMapWorkspaceSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GridPosCopyWith<$Res>? get selectedCell {
    if (_self.selectedCell == null) {
    return null;
  }

  return $GridPosCopyWith<$Res>(_self.selectedCell!, (value) {
    return _then(_self.copyWith(selectedCell: value));
  });
}
}

// dart format on
