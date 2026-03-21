// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EditorState {
// Context
  ProjectFileSystem? get fileSystem => throw _privateConstructorUsedError;

  ProjectManifest? get project =>
      throw _privateConstructorUsedError; // Active Map
  MapData? get activeMap => throw _privateConstructorUsedError;

  String? get activeMapPath =>
      throw _privateConstructorUsedError; // Active Tools & Selection
  EditorToolType get activeTool => throw _privateConstructorUsedError;

  String? get activeLayerId => throw _privateConstructorUsedError;

  GridPos? get hoveredTile => throw _privateConstructorUsedError; // Viewport
  double get zoom => throw _privateConstructorUsedError;

  Offset get panOffset => throw _privateConstructorUsedError; // Status
  bool get isDirty => throw _privateConstructorUsedError;

  bool get isSaving => throw _privateConstructorUsedError;

  String? get statusMessage => throw _privateConstructorUsedError;

  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditorStateCopyWith<EditorState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditorStateCopyWith<$Res> {
  factory $EditorStateCopyWith(
          EditorState value, $Res Function(EditorState) then) =
      _$EditorStateCopyWithImpl<$Res, EditorState>;

  @useResult
  $Res call(
      {ProjectFileSystem? fileSystem,
      ProjectManifest? project,
      MapData? activeMap,
      String? activeMapPath,
      EditorToolType activeTool,
      String? activeLayerId,
      GridPos? hoveredTile,
      double zoom,
      Offset panOffset,
      bool isDirty,
      bool isSaving,
      String? statusMessage,
      String? errorMessage});

  $ProjectManifestCopyWith<$Res>? get project;

  $MapDataCopyWith<$Res>? get activeMap;

  $GridPosCopyWith<$Res>? get hoveredTile;
}

/// @nodoc
class _$EditorStateCopyWithImpl<$Res, $Val extends EditorState>
    implements $EditorStateCopyWith<$Res> {
  _$EditorStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileSystem = freezed,
    Object? project = freezed,
    Object? activeMap = freezed,
    Object? activeMapPath = freezed,
    Object? activeTool = null,
    Object? activeLayerId = freezed,
    Object? hoveredTile = freezed,
    Object? zoom = null,
    Object? panOffset = null,
    Object? isDirty = null,
    Object? isSaving = null,
    Object? statusMessage = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      fileSystem: freezed == fileSystem
          ? _value.fileSystem
          : fileSystem // ignore: cast_nullable_to_non_nullable
              as ProjectFileSystem?,
      project: freezed == project
          ? _value.project
          : project // ignore: cast_nullable_to_non_nullable
              as ProjectManifest?,
      activeMap: freezed == activeMap
          ? _value.activeMap
          : activeMap // ignore: cast_nullable_to_non_nullable
              as MapData?,
      activeMapPath: freezed == activeMapPath
          ? _value.activeMapPath
          : activeMapPath // ignore: cast_nullable_to_non_nullable
              as String?,
      activeTool: null == activeTool
          ? _value.activeTool
          : activeTool // ignore: cast_nullable_to_non_nullable
              as EditorToolType,
      activeLayerId: freezed == activeLayerId
          ? _value.activeLayerId
          : activeLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      hoveredTile: freezed == hoveredTile
          ? _value.hoveredTile
          : hoveredTile // ignore: cast_nullable_to_non_nullable
              as GridPos?,
      zoom: null == zoom
          ? _value.zoom
          : zoom // ignore: cast_nullable_to_non_nullable
              as double,
      panOffset: null == panOffset
          ? _value.panOffset
          : panOffset // ignore: cast_nullable_to_non_nullable
              as Offset,
      isDirty: null == isDirty
          ? _value.isDirty
          : isDirty // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      statusMessage: freezed == statusMessage
          ? _value.statusMessage
          : statusMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectManifestCopyWith<$Res>? get project {
    if (_value.project == null) {
      return null;
    }

    return $ProjectManifestCopyWith<$Res>(_value.project!, (value) {
      return _then(_value.copyWith(project: value) as $Val);
    });
  }

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MapDataCopyWith<$Res>? get activeMap {
    if (_value.activeMap == null) {
      return null;
    }

    return $MapDataCopyWith<$Res>(_value.activeMap!, (value) {
      return _then(_value.copyWith(activeMap: value) as $Val);
    });
  }

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res>? get hoveredTile {
    if (_value.hoveredTile == null) {
      return null;
    }

    return $GridPosCopyWith<$Res>(_value.hoveredTile!, (value) {
      return _then(_value.copyWith(hoveredTile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EditorStateImplCopyWith<$Res>
    implements $EditorStateCopyWith<$Res> {
  factory _$$EditorStateImplCopyWith(
          _$EditorStateImpl value, $Res Function(_$EditorStateImpl) then) =
      __$$EditorStateImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {ProjectFileSystem? fileSystem,
      ProjectManifest? project,
      MapData? activeMap,
      String? activeMapPath,
      EditorToolType activeTool,
      String? activeLayerId,
      GridPos? hoveredTile,
      double zoom,
      Offset panOffset,
      bool isDirty,
      bool isSaving,
      String? statusMessage,
      String? errorMessage});

  @override
  $ProjectManifestCopyWith<$Res>? get project;

  @override
  $MapDataCopyWith<$Res>? get activeMap;

  @override
  $GridPosCopyWith<$Res>? get hoveredTile;
}

/// @nodoc
class __$$EditorStateImplCopyWithImpl<$Res>
    extends _$EditorStateCopyWithImpl<$Res, _$EditorStateImpl>
    implements _$$EditorStateImplCopyWith<$Res> {
  __$$EditorStateImplCopyWithImpl(
      _$EditorStateImpl _value, $Res Function(_$EditorStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileSystem = freezed,
    Object? project = freezed,
    Object? activeMap = freezed,
    Object? activeMapPath = freezed,
    Object? activeTool = null,
    Object? activeLayerId = freezed,
    Object? hoveredTile = freezed,
    Object? zoom = null,
    Object? panOffset = null,
    Object? isDirty = null,
    Object? isSaving = null,
    Object? statusMessage = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$EditorStateImpl(
      fileSystem: freezed == fileSystem
          ? _value.fileSystem
          : fileSystem // ignore: cast_nullable_to_non_nullable
              as ProjectFileSystem?,
      project: freezed == project
          ? _value.project
          : project // ignore: cast_nullable_to_non_nullable
              as ProjectManifest?,
      activeMap: freezed == activeMap
          ? _value.activeMap
          : activeMap // ignore: cast_nullable_to_non_nullable
              as MapData?,
      activeMapPath: freezed == activeMapPath
          ? _value.activeMapPath
          : activeMapPath // ignore: cast_nullable_to_non_nullable
              as String?,
      activeTool: null == activeTool
          ? _value.activeTool
          : activeTool // ignore: cast_nullable_to_non_nullable
              as EditorToolType,
      activeLayerId: freezed == activeLayerId
          ? _value.activeLayerId
          : activeLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      hoveredTile: freezed == hoveredTile
          ? _value.hoveredTile
          : hoveredTile // ignore: cast_nullable_to_non_nullable
              as GridPos?,
      zoom: null == zoom
          ? _value.zoom
          : zoom // ignore: cast_nullable_to_non_nullable
              as double,
      panOffset: null == panOffset
          ? _value.panOffset
          : panOffset // ignore: cast_nullable_to_non_nullable
              as Offset,
      isDirty: null == isDirty
          ? _value.isDirty
          : isDirty // ignore: cast_nullable_to_non_nullable
              as bool,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      statusMessage: freezed == statusMessage
          ? _value.statusMessage
          : statusMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$EditorStateImpl implements _EditorState {
  const _$EditorStateImpl(
      {this.fileSystem,
      this.project,
      this.activeMap,
      this.activeMapPath,
      this.activeTool = EditorToolType.selection,
      this.activeLayerId,
      this.hoveredTile,
      this.zoom = 1.0,
      this.panOffset = Offset.zero,
      this.isDirty = false,
      this.isSaving = false,
      this.statusMessage,
      this.errorMessage});

// Context
  @override
  final ProjectFileSystem? fileSystem;
  @override
  final ProjectManifest? project;

// Active Map
  @override
  final MapData? activeMap;
  @override
  final String? activeMapPath;

// Active Tools & Selection
  @override
  @JsonKey()
  final EditorToolType activeTool;
  @override
  final String? activeLayerId;
  @override
  final GridPos? hoveredTile;

// Viewport
  @override
  @JsonKey()
  final double zoom;
  @override
  @JsonKey()
  final Offset panOffset;

// Status
  @override
  @JsonKey()
  final bool isDirty;
  @override
  @JsonKey()
  final bool isSaving;
  @override
  final String? statusMessage;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'EditorState(fileSystem: $fileSystem, project: $project, activeMap: $activeMap, activeMapPath: $activeMapPath, activeTool: $activeTool, activeLayerId: $activeLayerId, hoveredTile: $hoveredTile, zoom: $zoom, panOffset: $panOffset, isDirty: $isDirty, isSaving: $isSaving, statusMessage: $statusMessage, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditorStateImpl &&
            (identical(other.fileSystem, fileSystem) ||
                other.fileSystem == fileSystem) &&
            (identical(other.project, project) || other.project == project) &&
            (identical(other.activeMap, activeMap) ||
                other.activeMap == activeMap) &&
            (identical(other.activeMapPath, activeMapPath) ||
                other.activeMapPath == activeMapPath) &&
            (identical(other.activeTool, activeTool) ||
                other.activeTool == activeTool) &&
            (identical(other.activeLayerId, activeLayerId) ||
                other.activeLayerId == activeLayerId) &&
            (identical(other.hoveredTile, hoveredTile) ||
                other.hoveredTile == hoveredTile) &&
            (identical(other.zoom, zoom) || other.zoom == zoom) &&
            (identical(other.panOffset, panOffset) ||
                other.panOffset == panOffset) &&
            (identical(other.isDirty, isDirty) || other.isDirty == isDirty) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            (identical(other.statusMessage, statusMessage) ||
                other.statusMessage == statusMessage) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      fileSystem,
      project,
      activeMap,
      activeMapPath,
      activeTool,
      activeLayerId,
      hoveredTile,
      zoom,
      panOffset,
      isDirty,
      isSaving,
      statusMessage,
      errorMessage);

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditorStateImplCopyWith<_$EditorStateImpl> get copyWith =>
      __$$EditorStateImplCopyWithImpl<_$EditorStateImpl>(this, _$identity);
}

abstract class _EditorState implements EditorState {
  const factory _EditorState(
      {final ProjectFileSystem? fileSystem,
      final ProjectManifest? project,
      final MapData? activeMap,
      final String? activeMapPath,
      final EditorToolType activeTool,
      final String? activeLayerId,
      final GridPos? hoveredTile,
      final double zoom,
      final Offset panOffset,
      final bool isDirty,
      final bool isSaving,
      final String? statusMessage,
      final String? errorMessage}) = _$EditorStateImpl;

// Context
  @override
  ProjectFileSystem? get fileSystem;

  @override
  ProjectManifest? get project; // Active Map
  @override
  MapData? get activeMap;

  @override
  String? get activeMapPath; // Active Tools & Selection
  @override
  EditorToolType get activeTool;

  @override
  String? get activeLayerId;

  @override
  GridPos? get hoveredTile; // Viewport
  @override
  double get zoom;

  @override
  Offset get panOffset; // Status
  @override
  bool get isDirty;

  @override
  bool get isSaving;

  @override
  String? get statusMessage;

  @override
  String? get errorMessage;

  /// Create a copy of EditorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditorStateImplCopyWith<_$EditorStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
