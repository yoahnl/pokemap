// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_history_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MapHistorySnapshot {

 MapData get map; String? get activeLayerId; String? get selectedEntityId; String? get selectedWarpId; String? get selectedTriggerId; String? get selectedMapEventId; String? get selectedGameplayZoneId; String? get selectedPlacedElementInstanceId; String? get npcWaypointPlacementEntityId; bool get wasDirty;
/// Create a copy of MapHistorySnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapHistorySnapshotCopyWith<MapHistorySnapshot> get copyWith => _$MapHistorySnapshotCopyWithImpl<MapHistorySnapshot>(this as MapHistorySnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapHistorySnapshot&&(identical(other.map, map) || other.map == map)&&(identical(other.activeLayerId, activeLayerId) || other.activeLayerId == activeLayerId)&&(identical(other.selectedEntityId, selectedEntityId) || other.selectedEntityId == selectedEntityId)&&(identical(other.selectedWarpId, selectedWarpId) || other.selectedWarpId == selectedWarpId)&&(identical(other.selectedTriggerId, selectedTriggerId) || other.selectedTriggerId == selectedTriggerId)&&(identical(other.selectedMapEventId, selectedMapEventId) || other.selectedMapEventId == selectedMapEventId)&&(identical(other.selectedGameplayZoneId, selectedGameplayZoneId) || other.selectedGameplayZoneId == selectedGameplayZoneId)&&(identical(other.selectedPlacedElementInstanceId, selectedPlacedElementInstanceId) || other.selectedPlacedElementInstanceId == selectedPlacedElementInstanceId)&&(identical(other.npcWaypointPlacementEntityId, npcWaypointPlacementEntityId) || other.npcWaypointPlacementEntityId == npcWaypointPlacementEntityId)&&(identical(other.wasDirty, wasDirty) || other.wasDirty == wasDirty));
}


@override
int get hashCode => Object.hash(runtimeType,map,activeLayerId,selectedEntityId,selectedWarpId,selectedTriggerId,selectedMapEventId,selectedGameplayZoneId,selectedPlacedElementInstanceId,npcWaypointPlacementEntityId,wasDirty);

@override
String toString() {
  return 'MapHistorySnapshot(map: $map, activeLayerId: $activeLayerId, selectedEntityId: $selectedEntityId, selectedWarpId: $selectedWarpId, selectedTriggerId: $selectedTriggerId, selectedMapEventId: $selectedMapEventId, selectedGameplayZoneId: $selectedGameplayZoneId, selectedPlacedElementInstanceId: $selectedPlacedElementInstanceId, npcWaypointPlacementEntityId: $npcWaypointPlacementEntityId, wasDirty: $wasDirty)';
}


}

/// @nodoc
abstract mixin class $MapHistorySnapshotCopyWith<$Res>  {
  factory $MapHistorySnapshotCopyWith(MapHistorySnapshot value, $Res Function(MapHistorySnapshot) _then) = _$MapHistorySnapshotCopyWithImpl;
@useResult
$Res call({
 MapData map, String? activeLayerId, String? selectedEntityId, String? selectedWarpId, String? selectedTriggerId, String? selectedMapEventId, String? selectedGameplayZoneId, String? selectedPlacedElementInstanceId, String? npcWaypointPlacementEntityId, bool wasDirty
});


$MapDataCopyWith<$Res> get map;

}
/// @nodoc
class _$MapHistorySnapshotCopyWithImpl<$Res>
    implements $MapHistorySnapshotCopyWith<$Res> {
  _$MapHistorySnapshotCopyWithImpl(this._self, this._then);

  final MapHistorySnapshot _self;
  final $Res Function(MapHistorySnapshot) _then;

/// Create a copy of MapHistorySnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? map = null,Object? activeLayerId = freezed,Object? selectedEntityId = freezed,Object? selectedWarpId = freezed,Object? selectedTriggerId = freezed,Object? selectedMapEventId = freezed,Object? selectedGameplayZoneId = freezed,Object? selectedPlacedElementInstanceId = freezed,Object? npcWaypointPlacementEntityId = freezed,Object? wasDirty = null,}) {
  return _then(_self.copyWith(
map: null == map ? _self.map : map // ignore: cast_nullable_to_non_nullable
as MapData,activeLayerId: freezed == activeLayerId ? _self.activeLayerId : activeLayerId // ignore: cast_nullable_to_non_nullable
as String?,selectedEntityId: freezed == selectedEntityId ? _self.selectedEntityId : selectedEntityId // ignore: cast_nullable_to_non_nullable
as String?,selectedWarpId: freezed == selectedWarpId ? _self.selectedWarpId : selectedWarpId // ignore: cast_nullable_to_non_nullable
as String?,selectedTriggerId: freezed == selectedTriggerId ? _self.selectedTriggerId : selectedTriggerId // ignore: cast_nullable_to_non_nullable
as String?,selectedMapEventId: freezed == selectedMapEventId ? _self.selectedMapEventId : selectedMapEventId // ignore: cast_nullable_to_non_nullable
as String?,selectedGameplayZoneId: freezed == selectedGameplayZoneId ? _self.selectedGameplayZoneId : selectedGameplayZoneId // ignore: cast_nullable_to_non_nullable
as String?,selectedPlacedElementInstanceId: freezed == selectedPlacedElementInstanceId ? _self.selectedPlacedElementInstanceId : selectedPlacedElementInstanceId // ignore: cast_nullable_to_non_nullable
as String?,npcWaypointPlacementEntityId: freezed == npcWaypointPlacementEntityId ? _self.npcWaypointPlacementEntityId : npcWaypointPlacementEntityId // ignore: cast_nullable_to_non_nullable
as String?,wasDirty: null == wasDirty ? _self.wasDirty : wasDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of MapHistorySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapDataCopyWith<$Res> get map {
  
  return $MapDataCopyWith<$Res>(_self.map, (value) {
    return _then(_self.copyWith(map: value));
  });
}
}


/// Adds pattern-matching-related methods to [MapHistorySnapshot].
extension MapHistorySnapshotPatterns on MapHistorySnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapHistorySnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapHistorySnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapHistorySnapshot value)  $default,){
final _that = this;
switch (_that) {
case _MapHistorySnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapHistorySnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _MapHistorySnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MapData map,  String? activeLayerId,  String? selectedEntityId,  String? selectedWarpId,  String? selectedTriggerId,  String? selectedMapEventId,  String? selectedGameplayZoneId,  String? selectedPlacedElementInstanceId,  String? npcWaypointPlacementEntityId,  bool wasDirty)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapHistorySnapshot() when $default != null:
return $default(_that.map,_that.activeLayerId,_that.selectedEntityId,_that.selectedWarpId,_that.selectedTriggerId,_that.selectedMapEventId,_that.selectedGameplayZoneId,_that.selectedPlacedElementInstanceId,_that.npcWaypointPlacementEntityId,_that.wasDirty);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MapData map,  String? activeLayerId,  String? selectedEntityId,  String? selectedWarpId,  String? selectedTriggerId,  String? selectedMapEventId,  String? selectedGameplayZoneId,  String? selectedPlacedElementInstanceId,  String? npcWaypointPlacementEntityId,  bool wasDirty)  $default,) {final _that = this;
switch (_that) {
case _MapHistorySnapshot():
return $default(_that.map,_that.activeLayerId,_that.selectedEntityId,_that.selectedWarpId,_that.selectedTriggerId,_that.selectedMapEventId,_that.selectedGameplayZoneId,_that.selectedPlacedElementInstanceId,_that.npcWaypointPlacementEntityId,_that.wasDirty);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MapData map,  String? activeLayerId,  String? selectedEntityId,  String? selectedWarpId,  String? selectedTriggerId,  String? selectedMapEventId,  String? selectedGameplayZoneId,  String? selectedPlacedElementInstanceId,  String? npcWaypointPlacementEntityId,  bool wasDirty)?  $default,) {final _that = this;
switch (_that) {
case _MapHistorySnapshot() when $default != null:
return $default(_that.map,_that.activeLayerId,_that.selectedEntityId,_that.selectedWarpId,_that.selectedTriggerId,_that.selectedMapEventId,_that.selectedGameplayZoneId,_that.selectedPlacedElementInstanceId,_that.npcWaypointPlacementEntityId,_that.wasDirty);case _:
  return null;

}
}

}

/// @nodoc


class _MapHistorySnapshot extends MapHistorySnapshot {
  const _MapHistorySnapshot({required this.map, this.activeLayerId, this.selectedEntityId, this.selectedWarpId, this.selectedTriggerId, this.selectedMapEventId, this.selectedGameplayZoneId, this.selectedPlacedElementInstanceId, this.npcWaypointPlacementEntityId, this.wasDirty = false}): super._();
  

@override final  MapData map;
@override final  String? activeLayerId;
@override final  String? selectedEntityId;
@override final  String? selectedWarpId;
@override final  String? selectedTriggerId;
@override final  String? selectedMapEventId;
@override final  String? selectedGameplayZoneId;
@override final  String? selectedPlacedElementInstanceId;
@override final  String? npcWaypointPlacementEntityId;
@override@JsonKey() final  bool wasDirty;

/// Create a copy of MapHistorySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapHistorySnapshotCopyWith<_MapHistorySnapshot> get copyWith => __$MapHistorySnapshotCopyWithImpl<_MapHistorySnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapHistorySnapshot&&(identical(other.map, map) || other.map == map)&&(identical(other.activeLayerId, activeLayerId) || other.activeLayerId == activeLayerId)&&(identical(other.selectedEntityId, selectedEntityId) || other.selectedEntityId == selectedEntityId)&&(identical(other.selectedWarpId, selectedWarpId) || other.selectedWarpId == selectedWarpId)&&(identical(other.selectedTriggerId, selectedTriggerId) || other.selectedTriggerId == selectedTriggerId)&&(identical(other.selectedMapEventId, selectedMapEventId) || other.selectedMapEventId == selectedMapEventId)&&(identical(other.selectedGameplayZoneId, selectedGameplayZoneId) || other.selectedGameplayZoneId == selectedGameplayZoneId)&&(identical(other.selectedPlacedElementInstanceId, selectedPlacedElementInstanceId) || other.selectedPlacedElementInstanceId == selectedPlacedElementInstanceId)&&(identical(other.npcWaypointPlacementEntityId, npcWaypointPlacementEntityId) || other.npcWaypointPlacementEntityId == npcWaypointPlacementEntityId)&&(identical(other.wasDirty, wasDirty) || other.wasDirty == wasDirty));
}


@override
int get hashCode => Object.hash(runtimeType,map,activeLayerId,selectedEntityId,selectedWarpId,selectedTriggerId,selectedMapEventId,selectedGameplayZoneId,selectedPlacedElementInstanceId,npcWaypointPlacementEntityId,wasDirty);

@override
String toString() {
  return 'MapHistorySnapshot(map: $map, activeLayerId: $activeLayerId, selectedEntityId: $selectedEntityId, selectedWarpId: $selectedWarpId, selectedTriggerId: $selectedTriggerId, selectedMapEventId: $selectedMapEventId, selectedGameplayZoneId: $selectedGameplayZoneId, selectedPlacedElementInstanceId: $selectedPlacedElementInstanceId, npcWaypointPlacementEntityId: $npcWaypointPlacementEntityId, wasDirty: $wasDirty)';
}


}

/// @nodoc
abstract mixin class _$MapHistorySnapshotCopyWith<$Res> implements $MapHistorySnapshotCopyWith<$Res> {
  factory _$MapHistorySnapshotCopyWith(_MapHistorySnapshot value, $Res Function(_MapHistorySnapshot) _then) = __$MapHistorySnapshotCopyWithImpl;
@override @useResult
$Res call({
 MapData map, String? activeLayerId, String? selectedEntityId, String? selectedWarpId, String? selectedTriggerId, String? selectedMapEventId, String? selectedGameplayZoneId, String? selectedPlacedElementInstanceId, String? npcWaypointPlacementEntityId, bool wasDirty
});


@override $MapDataCopyWith<$Res> get map;

}
/// @nodoc
class __$MapHistorySnapshotCopyWithImpl<$Res>
    implements _$MapHistorySnapshotCopyWith<$Res> {
  __$MapHistorySnapshotCopyWithImpl(this._self, this._then);

  final _MapHistorySnapshot _self;
  final $Res Function(_MapHistorySnapshot) _then;

/// Create a copy of MapHistorySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? map = null,Object? activeLayerId = freezed,Object? selectedEntityId = freezed,Object? selectedWarpId = freezed,Object? selectedTriggerId = freezed,Object? selectedMapEventId = freezed,Object? selectedGameplayZoneId = freezed,Object? selectedPlacedElementInstanceId = freezed,Object? npcWaypointPlacementEntityId = freezed,Object? wasDirty = null,}) {
  return _then(_MapHistorySnapshot(
map: null == map ? _self.map : map // ignore: cast_nullable_to_non_nullable
as MapData,activeLayerId: freezed == activeLayerId ? _self.activeLayerId : activeLayerId // ignore: cast_nullable_to_non_nullable
as String?,selectedEntityId: freezed == selectedEntityId ? _self.selectedEntityId : selectedEntityId // ignore: cast_nullable_to_non_nullable
as String?,selectedWarpId: freezed == selectedWarpId ? _self.selectedWarpId : selectedWarpId // ignore: cast_nullable_to_non_nullable
as String?,selectedTriggerId: freezed == selectedTriggerId ? _self.selectedTriggerId : selectedTriggerId // ignore: cast_nullable_to_non_nullable
as String?,selectedMapEventId: freezed == selectedMapEventId ? _self.selectedMapEventId : selectedMapEventId // ignore: cast_nullable_to_non_nullable
as String?,selectedGameplayZoneId: freezed == selectedGameplayZoneId ? _self.selectedGameplayZoneId : selectedGameplayZoneId // ignore: cast_nullable_to_non_nullable
as String?,selectedPlacedElementInstanceId: freezed == selectedPlacedElementInstanceId ? _self.selectedPlacedElementInstanceId : selectedPlacedElementInstanceId // ignore: cast_nullable_to_non_nullable
as String?,npcWaypointPlacementEntityId: freezed == npcWaypointPlacementEntityId ? _self.npcWaypointPlacementEntityId : npcWaypointPlacementEntityId // ignore: cast_nullable_to_non_nullable
as String?,wasDirty: null == wasDirty ? _self.wasDirty : wasDirty // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of MapHistorySnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MapDataCopyWith<$Res> get map {
  
  return $MapDataCopyWith<$Res>(_self.map, (value) {
    return _then(_self.copyWith(map: value));
  });
}
}

// dart format on
