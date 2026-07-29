// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'world_map_workspace_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$WorldMapWorkspaceSession {
  bool get explorerExpanded => throw _privateConstructorUsedError;
  bool get inspectorVisible => throw _privateConstructorUsedError;
  double get inspectorWidth => throw _privateConstructorUsedError;
  WorldMapToolFamily get activeFamily => throw _privateConstructorUsedError;
  WorldMapPaintSubtool get lastPaintSubtool =>
      throw _privateConstructorUsedError;
  WorldMapPlacementSubtool get lastPlacementSubtool =>
      throw _privateConstructorUsedError;
  Map<String, WorldMapPaintSubtool> get lastPaintSubtoolByLayerId =>
      throw _privateConstructorUsedError;
  WorldMapInspectorKind? get pinnedInspectorKind =>
      throw _privateConstructorUsedError;
  GridPos? get selectedCell => throw _privateConstructorUsedError;
  String? get selectedCellMapId => throw _privateConstructorUsedError;

  /// Create a copy of WorldMapWorkspaceSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorldMapWorkspaceSessionCopyWith<WorldMapWorkspaceSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorldMapWorkspaceSessionCopyWith<$Res> {
  factory $WorldMapWorkspaceSessionCopyWith(WorldMapWorkspaceSession value,
          $Res Function(WorldMapWorkspaceSession) then) =
      _$WorldMapWorkspaceSessionCopyWithImpl<$Res, WorldMapWorkspaceSession>;
  @useResult
  $Res call(
      {bool explorerExpanded,
      bool inspectorVisible,
      double inspectorWidth,
      WorldMapToolFamily activeFamily,
      WorldMapPaintSubtool lastPaintSubtool,
      WorldMapPlacementSubtool lastPlacementSubtool,
      Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId,
      WorldMapInspectorKind? pinnedInspectorKind,
      GridPos? selectedCell,
      String? selectedCellMapId});

  $GridPosCopyWith<$Res>? get selectedCell;
}

/// @nodoc
class _$WorldMapWorkspaceSessionCopyWithImpl<$Res,
        $Val extends WorldMapWorkspaceSession>
    implements $WorldMapWorkspaceSessionCopyWith<$Res> {
  _$WorldMapWorkspaceSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorldMapWorkspaceSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? explorerExpanded = null,
    Object? inspectorVisible = null,
    Object? inspectorWidth = null,
    Object? activeFamily = null,
    Object? lastPaintSubtool = null,
    Object? lastPlacementSubtool = null,
    Object? lastPaintSubtoolByLayerId = null,
    Object? pinnedInspectorKind = freezed,
    Object? selectedCell = freezed,
    Object? selectedCellMapId = freezed,
  }) {
    return _then(_value.copyWith(
      explorerExpanded: null == explorerExpanded
          ? _value.explorerExpanded
          : explorerExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
      inspectorVisible: null == inspectorVisible
          ? _value.inspectorVisible
          : inspectorVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      inspectorWidth: null == inspectorWidth
          ? _value.inspectorWidth
          : inspectorWidth // ignore: cast_nullable_to_non_nullable
              as double,
      activeFamily: null == activeFamily
          ? _value.activeFamily
          : activeFamily // ignore: cast_nullable_to_non_nullable
              as WorldMapToolFamily,
      lastPaintSubtool: null == lastPaintSubtool
          ? _value.lastPaintSubtool
          : lastPaintSubtool // ignore: cast_nullable_to_non_nullable
              as WorldMapPaintSubtool,
      lastPlacementSubtool: null == lastPlacementSubtool
          ? _value.lastPlacementSubtool
          : lastPlacementSubtool // ignore: cast_nullable_to_non_nullable
              as WorldMapPlacementSubtool,
      lastPaintSubtoolByLayerId: null == lastPaintSubtoolByLayerId
          ? _value.lastPaintSubtoolByLayerId
          : lastPaintSubtoolByLayerId // ignore: cast_nullable_to_non_nullable
              as Map<String, WorldMapPaintSubtool>,
      pinnedInspectorKind: freezed == pinnedInspectorKind
          ? _value.pinnedInspectorKind
          : pinnedInspectorKind // ignore: cast_nullable_to_non_nullable
              as WorldMapInspectorKind?,
      selectedCell: freezed == selectedCell
          ? _value.selectedCell
          : selectedCell // ignore: cast_nullable_to_non_nullable
              as GridPos?,
      selectedCellMapId: freezed == selectedCellMapId
          ? _value.selectedCellMapId
          : selectedCellMapId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of WorldMapWorkspaceSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res>? get selectedCell {
    if (_value.selectedCell == null) {
      return null;
    }

    return $GridPosCopyWith<$Res>(_value.selectedCell!, (value) {
      return _then(_value.copyWith(selectedCell: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WorldMapWorkspaceSessionImplCopyWith<$Res>
    implements $WorldMapWorkspaceSessionCopyWith<$Res> {
  factory _$$WorldMapWorkspaceSessionImplCopyWith(
          _$WorldMapWorkspaceSessionImpl value,
          $Res Function(_$WorldMapWorkspaceSessionImpl) then) =
      __$$WorldMapWorkspaceSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool explorerExpanded,
      bool inspectorVisible,
      double inspectorWidth,
      WorldMapToolFamily activeFamily,
      WorldMapPaintSubtool lastPaintSubtool,
      WorldMapPlacementSubtool lastPlacementSubtool,
      Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId,
      WorldMapInspectorKind? pinnedInspectorKind,
      GridPos? selectedCell,
      String? selectedCellMapId});

  @override
  $GridPosCopyWith<$Res>? get selectedCell;
}

/// @nodoc
class __$$WorldMapWorkspaceSessionImplCopyWithImpl<$Res>
    extends _$WorldMapWorkspaceSessionCopyWithImpl<$Res,
        _$WorldMapWorkspaceSessionImpl>
    implements _$$WorldMapWorkspaceSessionImplCopyWith<$Res> {
  __$$WorldMapWorkspaceSessionImplCopyWithImpl(
      _$WorldMapWorkspaceSessionImpl _value,
      $Res Function(_$WorldMapWorkspaceSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorldMapWorkspaceSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? explorerExpanded = null,
    Object? inspectorVisible = null,
    Object? inspectorWidth = null,
    Object? activeFamily = null,
    Object? lastPaintSubtool = null,
    Object? lastPlacementSubtool = null,
    Object? lastPaintSubtoolByLayerId = null,
    Object? pinnedInspectorKind = freezed,
    Object? selectedCell = freezed,
    Object? selectedCellMapId = freezed,
  }) {
    return _then(_$WorldMapWorkspaceSessionImpl(
      explorerExpanded: null == explorerExpanded
          ? _value.explorerExpanded
          : explorerExpanded // ignore: cast_nullable_to_non_nullable
              as bool,
      inspectorVisible: null == inspectorVisible
          ? _value.inspectorVisible
          : inspectorVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      inspectorWidth: null == inspectorWidth
          ? _value.inspectorWidth
          : inspectorWidth // ignore: cast_nullable_to_non_nullable
              as double,
      activeFamily: null == activeFamily
          ? _value.activeFamily
          : activeFamily // ignore: cast_nullable_to_non_nullable
              as WorldMapToolFamily,
      lastPaintSubtool: null == lastPaintSubtool
          ? _value.lastPaintSubtool
          : lastPaintSubtool // ignore: cast_nullable_to_non_nullable
              as WorldMapPaintSubtool,
      lastPlacementSubtool: null == lastPlacementSubtool
          ? _value.lastPlacementSubtool
          : lastPlacementSubtool // ignore: cast_nullable_to_non_nullable
              as WorldMapPlacementSubtool,
      lastPaintSubtoolByLayerId: null == lastPaintSubtoolByLayerId
          ? _value._lastPaintSubtoolByLayerId
          : lastPaintSubtoolByLayerId // ignore: cast_nullable_to_non_nullable
              as Map<String, WorldMapPaintSubtool>,
      pinnedInspectorKind: freezed == pinnedInspectorKind
          ? _value.pinnedInspectorKind
          : pinnedInspectorKind // ignore: cast_nullable_to_non_nullable
              as WorldMapInspectorKind?,
      selectedCell: freezed == selectedCell
          ? _value.selectedCell
          : selectedCell // ignore: cast_nullable_to_non_nullable
              as GridPos?,
      selectedCellMapId: freezed == selectedCellMapId
          ? _value.selectedCellMapId
          : selectedCellMapId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$WorldMapWorkspaceSessionImpl implements _WorldMapWorkspaceSession {
  const _$WorldMapWorkspaceSessionImpl(
      {this.explorerExpanded = true,
      this.inspectorVisible = true,
      this.inspectorWidth = PokeMapDesktopLayoutTokens.inspectorWidth,
      this.activeFamily = WorldMapToolFamily.selection,
      this.lastPaintSubtool = WorldMapPaintSubtool.tile,
      this.lastPlacementSubtool = WorldMapPlacementSubtool.object,
      final Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId =
          const <String, WorldMapPaintSubtool>{},
      this.pinnedInspectorKind,
      this.selectedCell,
      this.selectedCellMapId})
      : _lastPaintSubtoolByLayerId = lastPaintSubtoolByLayerId;

  @override
  @JsonKey()
  final bool explorerExpanded;
  @override
  @JsonKey()
  final bool inspectorVisible;
  @override
  @JsonKey()
  final double inspectorWidth;
  @override
  @JsonKey()
  final WorldMapToolFamily activeFamily;
  @override
  @JsonKey()
  final WorldMapPaintSubtool lastPaintSubtool;
  @override
  @JsonKey()
  final WorldMapPlacementSubtool lastPlacementSubtool;
  final Map<String, WorldMapPaintSubtool> _lastPaintSubtoolByLayerId;
  @override
  @JsonKey()
  Map<String, WorldMapPaintSubtool> get lastPaintSubtoolByLayerId {
    if (_lastPaintSubtoolByLayerId is EqualUnmodifiableMapView)
      return _lastPaintSubtoolByLayerId;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_lastPaintSubtoolByLayerId);
  }

  @override
  final WorldMapInspectorKind? pinnedInspectorKind;
  @override
  final GridPos? selectedCell;
  @override
  final String? selectedCellMapId;

  @override
  String toString() {
    return 'WorldMapWorkspaceSession(explorerExpanded: $explorerExpanded, inspectorVisible: $inspectorVisible, inspectorWidth: $inspectorWidth, activeFamily: $activeFamily, lastPaintSubtool: $lastPaintSubtool, lastPlacementSubtool: $lastPlacementSubtool, lastPaintSubtoolByLayerId: $lastPaintSubtoolByLayerId, pinnedInspectorKind: $pinnedInspectorKind, selectedCell: $selectedCell, selectedCellMapId: $selectedCellMapId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorldMapWorkspaceSessionImpl &&
            (identical(other.explorerExpanded, explorerExpanded) ||
                other.explorerExpanded == explorerExpanded) &&
            (identical(other.inspectorVisible, inspectorVisible) ||
                other.inspectorVisible == inspectorVisible) &&
            (identical(other.inspectorWidth, inspectorWidth) ||
                other.inspectorWidth == inspectorWidth) &&
            (identical(other.activeFamily, activeFamily) ||
                other.activeFamily == activeFamily) &&
            (identical(other.lastPaintSubtool, lastPaintSubtool) ||
                other.lastPaintSubtool == lastPaintSubtool) &&
            (identical(other.lastPlacementSubtool, lastPlacementSubtool) ||
                other.lastPlacementSubtool == lastPlacementSubtool) &&
            const DeepCollectionEquality().equals(
                other._lastPaintSubtoolByLayerId, _lastPaintSubtoolByLayerId) &&
            (identical(other.pinnedInspectorKind, pinnedInspectorKind) ||
                other.pinnedInspectorKind == pinnedInspectorKind) &&
            (identical(other.selectedCell, selectedCell) ||
                other.selectedCell == selectedCell) &&
            (identical(other.selectedCellMapId, selectedCellMapId) ||
                other.selectedCellMapId == selectedCellMapId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      explorerExpanded,
      inspectorVisible,
      inspectorWidth,
      activeFamily,
      lastPaintSubtool,
      lastPlacementSubtool,
      const DeepCollectionEquality().hash(_lastPaintSubtoolByLayerId),
      pinnedInspectorKind,
      selectedCell,
      selectedCellMapId);

  /// Create a copy of WorldMapWorkspaceSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorldMapWorkspaceSessionImplCopyWith<_$WorldMapWorkspaceSessionImpl>
      get copyWith => __$$WorldMapWorkspaceSessionImplCopyWithImpl<
          _$WorldMapWorkspaceSessionImpl>(this, _$identity);
}

abstract class _WorldMapWorkspaceSession implements WorldMapWorkspaceSession {
  const factory _WorldMapWorkspaceSession(
      {final bool explorerExpanded,
      final bool inspectorVisible,
      final double inspectorWidth,
      final WorldMapToolFamily activeFamily,
      final WorldMapPaintSubtool lastPaintSubtool,
      final WorldMapPlacementSubtool lastPlacementSubtool,
      final Map<String, WorldMapPaintSubtool> lastPaintSubtoolByLayerId,
      final WorldMapInspectorKind? pinnedInspectorKind,
      final GridPos? selectedCell,
      final String? selectedCellMapId}) = _$WorldMapWorkspaceSessionImpl;

  @override
  bool get explorerExpanded;
  @override
  bool get inspectorVisible;
  @override
  double get inspectorWidth;
  @override
  WorldMapToolFamily get activeFamily;
  @override
  WorldMapPaintSubtool get lastPaintSubtool;
  @override
  WorldMapPlacementSubtool get lastPlacementSubtool;
  @override
  Map<String, WorldMapPaintSubtool> get lastPaintSubtoolByLayerId;
  @override
  WorldMapInspectorKind? get pinnedInspectorKind;
  @override
  GridPos? get selectedCell;
  @override
  String? get selectedCellMapId;

  /// Create a copy of WorldMapWorkspaceSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorldMapWorkspaceSessionImplCopyWith<_$WorldMapWorkspaceSessionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
