// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_history_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MapHistorySnapshot {
  MapData get map => throw _privateConstructorUsedError;
  String? get activeLayerId => throw _privateConstructorUsedError;
  String? get selectedWarpId => throw _privateConstructorUsedError;
  String? get selectedTriggerId => throw _privateConstructorUsedError;

  /// Create a copy of MapHistorySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MapHistorySnapshotCopyWith<MapHistorySnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MapHistorySnapshotCopyWith<$Res> {
  factory $MapHistorySnapshotCopyWith(
          MapHistorySnapshot value, $Res Function(MapHistorySnapshot) then) =
      _$MapHistorySnapshotCopyWithImpl<$Res, MapHistorySnapshot>;
  @useResult
  $Res call(
      {MapData map,
      String? activeLayerId,
      String? selectedWarpId,
      String? selectedTriggerId});

  $MapDataCopyWith<$Res> get map;
}

/// @nodoc
class _$MapHistorySnapshotCopyWithImpl<$Res, $Val extends MapHistorySnapshot>
    implements $MapHistorySnapshotCopyWith<$Res> {
  _$MapHistorySnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MapHistorySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? map = null,
    Object? activeLayerId = freezed,
    Object? selectedWarpId = freezed,
    Object? selectedTriggerId = freezed,
  }) {
    return _then(_value.copyWith(
      map: null == map
          ? _value.map
          : map // ignore: cast_nullable_to_non_nullable
              as MapData,
      activeLayerId: freezed == activeLayerId
          ? _value.activeLayerId
          : activeLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedWarpId: freezed == selectedWarpId
          ? _value.selectedWarpId
          : selectedWarpId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedTriggerId: freezed == selectedTriggerId
          ? _value.selectedTriggerId
          : selectedTriggerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of MapHistorySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapDataCopyWith<$Res> get map {
    return $MapDataCopyWith<$Res>(_value.map, (value) {
      return _then(_value.copyWith(map: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MapHistorySnapshotImplCopyWith<$Res>
    implements $MapHistorySnapshotCopyWith<$Res> {
  factory _$$MapHistorySnapshotImplCopyWith(_$MapHistorySnapshotImpl value,
          $Res Function(_$MapHistorySnapshotImpl) then) =
      __$$MapHistorySnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {MapData map,
      String? activeLayerId,
      String? selectedWarpId,
      String? selectedTriggerId});

  @override
  $MapDataCopyWith<$Res> get map;
}

/// @nodoc
class __$$MapHistorySnapshotImplCopyWithImpl<$Res>
    extends _$MapHistorySnapshotCopyWithImpl<$Res, _$MapHistorySnapshotImpl>
    implements _$$MapHistorySnapshotImplCopyWith<$Res> {
  __$$MapHistorySnapshotImplCopyWithImpl(_$MapHistorySnapshotImpl _value,
      $Res Function(_$MapHistorySnapshotImpl) _then)
      : super(_value, _then);

  /// Create a copy of MapHistorySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? map = null,
    Object? activeLayerId = freezed,
    Object? selectedWarpId = freezed,
    Object? selectedTriggerId = freezed,
  }) {
    return _then(_$MapHistorySnapshotImpl(
      map: null == map
          ? _value.map
          : map // ignore: cast_nullable_to_non_nullable
              as MapData,
      activeLayerId: freezed == activeLayerId
          ? _value.activeLayerId
          : activeLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedWarpId: freezed == selectedWarpId
          ? _value.selectedWarpId
          : selectedWarpId // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedTriggerId: freezed == selectedTriggerId
          ? _value.selectedTriggerId
          : selectedTriggerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MapHistorySnapshotImpl implements _MapHistorySnapshot {
  const _$MapHistorySnapshotImpl(
      {required this.map,
      this.activeLayerId,
      this.selectedWarpId,
      this.selectedTriggerId});

  @override
  final MapData map;
  @override
  final String? activeLayerId;
  @override
  final String? selectedWarpId;
  @override
  final String? selectedTriggerId;

  @override
  String toString() {
    return 'MapHistorySnapshot(map: $map, activeLayerId: $activeLayerId, selectedWarpId: $selectedWarpId, selectedTriggerId: $selectedTriggerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MapHistorySnapshotImpl &&
            (identical(other.map, map) || other.map == map) &&
            (identical(other.activeLayerId, activeLayerId) ||
                other.activeLayerId == activeLayerId) &&
            (identical(other.selectedWarpId, selectedWarpId) ||
                other.selectedWarpId == selectedWarpId) &&
            (identical(other.selectedTriggerId, selectedTriggerId) ||
                other.selectedTriggerId == selectedTriggerId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, map, activeLayerId, selectedWarpId, selectedTriggerId);

  /// Create a copy of MapHistorySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MapHistorySnapshotImplCopyWith<_$MapHistorySnapshotImpl> get copyWith =>
      __$$MapHistorySnapshotImplCopyWithImpl<_$MapHistorySnapshotImpl>(
          this, _$identity);
}

abstract class _MapHistorySnapshot implements MapHistorySnapshot {
  const factory _MapHistorySnapshot(
      {required final MapData map,
      final String? activeLayerId,
      final String? selectedWarpId,
      final String? selectedTriggerId}) = _$MapHistorySnapshotImpl;

  @override
  MapData get map;
  @override
  String? get activeLayerId;
  @override
  String? get selectedWarpId;
  @override
  String? get selectedTriggerId;

  /// Create a copy of MapHistorySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MapHistorySnapshotImplCopyWith<_$MapHistorySnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
