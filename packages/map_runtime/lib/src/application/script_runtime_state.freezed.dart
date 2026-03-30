// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'script_runtime_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ScriptExecutionState {
  /// Script en cours d'exécution.
  ScriptAsset get script => throw _privateConstructorUsedError;

  /// Noeud actuel.
  String get currentNodeId => throw _privateConstructorUsedError;

  /// Index de la commande en cours dans le noeud.
  int get currentCommandIndex => throw _privateConstructorUsedError;

  /// true si le script est en attente (dialogue, etc.).
  bool get isSuspended => throw _privateConstructorUsedError;

  /// Raison de la suspension.
  ScriptSuspendReason? get suspendReason => throw _privateConstructorUsedError;

  /// Référence au dialogue en cours (si suspendu pour dialogue).
  YarnDialogueRef? get pendingDialogue => throw _privateConstructorUsedError;

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScriptExecutionStateCopyWith<ScriptExecutionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptExecutionStateCopyWith<$Res> {
  factory $ScriptExecutionStateCopyWith(ScriptExecutionState value,
          $Res Function(ScriptExecutionState) then) =
      _$ScriptExecutionStateCopyWithImpl<$Res, ScriptExecutionState>;
  @useResult
  $Res call(
      {ScriptAsset script,
      String currentNodeId,
      int currentCommandIndex,
      bool isSuspended,
      ScriptSuspendReason? suspendReason,
      YarnDialogueRef? pendingDialogue});

  $ScriptAssetCopyWith<$Res> get script;
  $YarnDialogueRefCopyWith<$Res>? get pendingDialogue;
}

/// @nodoc
class _$ScriptExecutionStateCopyWithImpl<$Res,
        $Val extends ScriptExecutionState>
    implements $ScriptExecutionStateCopyWith<$Res> {
  _$ScriptExecutionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? script = null,
    Object? currentNodeId = null,
    Object? currentCommandIndex = null,
    Object? isSuspended = null,
    Object? suspendReason = freezed,
    Object? pendingDialogue = freezed,
  }) {
    return _then(_value.copyWith(
      script: null == script
          ? _value.script
          : script // ignore: cast_nullable_to_non_nullable
              as ScriptAsset,
      currentNodeId: null == currentNodeId
          ? _value.currentNodeId
          : currentNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      currentCommandIndex: null == currentCommandIndex
          ? _value.currentCommandIndex
          : currentCommandIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isSuspended: null == isSuspended
          ? _value.isSuspended
          : isSuspended // ignore: cast_nullable_to_non_nullable
              as bool,
      suspendReason: freezed == suspendReason
          ? _value.suspendReason
          : suspendReason // ignore: cast_nullable_to_non_nullable
              as ScriptSuspendReason?,
      pendingDialogue: freezed == pendingDialogue
          ? _value.pendingDialogue
          : pendingDialogue // ignore: cast_nullable_to_non_nullable
              as YarnDialogueRef?,
    ) as $Val);
  }

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptAssetCopyWith<$Res> get script {
    return $ScriptAssetCopyWith<$Res>(_value.script, (value) {
      return _then(_value.copyWith(script: value) as $Val);
    });
  }

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $YarnDialogueRefCopyWith<$Res>? get pendingDialogue {
    if (_value.pendingDialogue == null) {
      return null;
    }

    return $YarnDialogueRefCopyWith<$Res>(_value.pendingDialogue!, (value) {
      return _then(_value.copyWith(pendingDialogue: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ScriptExecutionStateImplCopyWith<$Res>
    implements $ScriptExecutionStateCopyWith<$Res> {
  factory _$$ScriptExecutionStateImplCopyWith(_$ScriptExecutionStateImpl value,
          $Res Function(_$ScriptExecutionStateImpl) then) =
      __$$ScriptExecutionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ScriptAsset script,
      String currentNodeId,
      int currentCommandIndex,
      bool isSuspended,
      ScriptSuspendReason? suspendReason,
      YarnDialogueRef? pendingDialogue});

  @override
  $ScriptAssetCopyWith<$Res> get script;
  @override
  $YarnDialogueRefCopyWith<$Res>? get pendingDialogue;
}

/// @nodoc
class __$$ScriptExecutionStateImplCopyWithImpl<$Res>
    extends _$ScriptExecutionStateCopyWithImpl<$Res, _$ScriptExecutionStateImpl>
    implements _$$ScriptExecutionStateImplCopyWith<$Res> {
  __$$ScriptExecutionStateImplCopyWithImpl(_$ScriptExecutionStateImpl _value,
      $Res Function(_$ScriptExecutionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? script = null,
    Object? currentNodeId = null,
    Object? currentCommandIndex = null,
    Object? isSuspended = null,
    Object? suspendReason = freezed,
    Object? pendingDialogue = freezed,
  }) {
    return _then(_$ScriptExecutionStateImpl(
      script: null == script
          ? _value.script
          : script // ignore: cast_nullable_to_non_nullable
              as ScriptAsset,
      currentNodeId: null == currentNodeId
          ? _value.currentNodeId
          : currentNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      currentCommandIndex: null == currentCommandIndex
          ? _value.currentCommandIndex
          : currentCommandIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isSuspended: null == isSuspended
          ? _value.isSuspended
          : isSuspended // ignore: cast_nullable_to_non_nullable
              as bool,
      suspendReason: freezed == suspendReason
          ? _value.suspendReason
          : suspendReason // ignore: cast_nullable_to_non_nullable
              as ScriptSuspendReason?,
      pendingDialogue: freezed == pendingDialogue
          ? _value.pendingDialogue
          : pendingDialogue // ignore: cast_nullable_to_non_nullable
              as YarnDialogueRef?,
    ));
  }
}

/// @nodoc

class _$ScriptExecutionStateImpl implements _ScriptExecutionState {
  const _$ScriptExecutionStateImpl(
      {required this.script,
      required this.currentNodeId,
      this.currentCommandIndex = 0,
      this.isSuspended = false,
      this.suspendReason,
      this.pendingDialogue});

  /// Script en cours d'exécution.
  @override
  final ScriptAsset script;

  /// Noeud actuel.
  @override
  final String currentNodeId;

  /// Index de la commande en cours dans le noeud.
  @override
  @JsonKey()
  final int currentCommandIndex;

  /// true si le script est en attente (dialogue, etc.).
  @override
  @JsonKey()
  final bool isSuspended;

  /// Raison de la suspension.
  @override
  final ScriptSuspendReason? suspendReason;

  /// Référence au dialogue en cours (si suspendu pour dialogue).
  @override
  final YarnDialogueRef? pendingDialogue;

  @override
  String toString() {
    return 'ScriptExecutionState(script: $script, currentNodeId: $currentNodeId, currentCommandIndex: $currentCommandIndex, isSuspended: $isSuspended, suspendReason: $suspendReason, pendingDialogue: $pendingDialogue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptExecutionStateImpl &&
            (identical(other.script, script) || other.script == script) &&
            (identical(other.currentNodeId, currentNodeId) ||
                other.currentNodeId == currentNodeId) &&
            (identical(other.currentCommandIndex, currentCommandIndex) ||
                other.currentCommandIndex == currentCommandIndex) &&
            (identical(other.isSuspended, isSuspended) ||
                other.isSuspended == isSuspended) &&
            (identical(other.suspendReason, suspendReason) ||
                other.suspendReason == suspendReason) &&
            (identical(other.pendingDialogue, pendingDialogue) ||
                other.pendingDialogue == pendingDialogue));
  }

  @override
  int get hashCode => Object.hash(runtimeType, script, currentNodeId,
      currentCommandIndex, isSuspended, suspendReason, pendingDialogue);

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptExecutionStateImplCopyWith<_$ScriptExecutionStateImpl>
      get copyWith =>
          __$$ScriptExecutionStateImplCopyWithImpl<_$ScriptExecutionStateImpl>(
              this, _$identity);
}

abstract class _ScriptExecutionState implements ScriptExecutionState {
  const factory _ScriptExecutionState(
      {required final ScriptAsset script,
      required final String currentNodeId,
      final int currentCommandIndex,
      final bool isSuspended,
      final ScriptSuspendReason? suspendReason,
      final YarnDialogueRef? pendingDialogue}) = _$ScriptExecutionStateImpl;

  /// Script en cours d'exécution.
  @override
  ScriptAsset get script;

  /// Noeud actuel.
  @override
  String get currentNodeId;

  /// Index de la commande en cours dans le noeud.
  @override
  int get currentCommandIndex;

  /// true si le script est en attente (dialogue, etc.).
  @override
  bool get isSuspended;

  /// Raison de la suspension.
  @override
  ScriptSuspendReason? get suspendReason;

  /// Référence au dialogue en cours (si suspendu pour dialogue).
  @override
  YarnDialogueRef? get pendingDialogue;

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptExecutionStateImplCopyWith<_$ScriptExecutionStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ScriptCommandResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() completed,
    required TResult Function(
            ScriptSuspendReason reason, YarnDialogueRef? dialogue)
        suspended,
    required TResult Function(String nodeId) jumpToNode,
    required TResult Function() terminated,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? completed,
    TResult? Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult? Function(String nodeId)? jumpToNode,
    TResult? Function()? terminated,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? completed,
    TResult Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult Function(String nodeId)? jumpToNode,
    TResult Function()? terminated,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptCommandResultCompleted value) completed,
    required TResult Function(ScriptCommandResultSuspended value) suspended,
    required TResult Function(ScriptCommandResultJumpToNode value) jumpToNode,
    required TResult Function(ScriptCommandResultTerminated value) terminated,
    required TResult Function(ScriptCommandResultError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptCommandResultCompleted value)? completed,
    TResult? Function(ScriptCommandResultSuspended value)? suspended,
    TResult? Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult? Function(ScriptCommandResultTerminated value)? terminated,
    TResult? Function(ScriptCommandResultError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptCommandResultCompleted value)? completed,
    TResult Function(ScriptCommandResultSuspended value)? suspended,
    TResult Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult Function(ScriptCommandResultTerminated value)? terminated,
    TResult Function(ScriptCommandResultError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptCommandResultCopyWith<$Res> {
  factory $ScriptCommandResultCopyWith(
          ScriptCommandResult value, $Res Function(ScriptCommandResult) then) =
      _$ScriptCommandResultCopyWithImpl<$Res, ScriptCommandResult>;
}

/// @nodoc
class _$ScriptCommandResultCopyWithImpl<$Res, $Val extends ScriptCommandResult>
    implements $ScriptCommandResultCopyWith<$Res> {
  _$ScriptCommandResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ScriptCommandResultCompletedImplCopyWith<$Res> {
  factory _$$ScriptCommandResultCompletedImplCopyWith(
          _$ScriptCommandResultCompletedImpl value,
          $Res Function(_$ScriptCommandResultCompletedImpl) then) =
      __$$ScriptCommandResultCompletedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ScriptCommandResultCompletedImplCopyWithImpl<$Res>
    extends _$ScriptCommandResultCopyWithImpl<$Res,
        _$ScriptCommandResultCompletedImpl>
    implements _$$ScriptCommandResultCompletedImplCopyWith<$Res> {
  __$$ScriptCommandResultCompletedImplCopyWithImpl(
      _$ScriptCommandResultCompletedImpl _value,
      $Res Function(_$ScriptCommandResultCompletedImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ScriptCommandResultCompletedImpl
    implements ScriptCommandResultCompleted {
  const _$ScriptCommandResultCompletedImpl();

  @override
  String toString() {
    return 'ScriptCommandResult.completed()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptCommandResultCompletedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() completed,
    required TResult Function(
            ScriptSuspendReason reason, YarnDialogueRef? dialogue)
        suspended,
    required TResult Function(String nodeId) jumpToNode,
    required TResult Function() terminated,
    required TResult Function(String message) error,
  }) {
    return completed();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? completed,
    TResult? Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult? Function(String nodeId)? jumpToNode,
    TResult? Function()? terminated,
    TResult? Function(String message)? error,
  }) {
    return completed?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? completed,
    TResult Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult Function(String nodeId)? jumpToNode,
    TResult Function()? terminated,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptCommandResultCompleted value) completed,
    required TResult Function(ScriptCommandResultSuspended value) suspended,
    required TResult Function(ScriptCommandResultJumpToNode value) jumpToNode,
    required TResult Function(ScriptCommandResultTerminated value) terminated,
    required TResult Function(ScriptCommandResultError value) error,
  }) {
    return completed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptCommandResultCompleted value)? completed,
    TResult? Function(ScriptCommandResultSuspended value)? suspended,
    TResult? Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult? Function(ScriptCommandResultTerminated value)? terminated,
    TResult? Function(ScriptCommandResultError value)? error,
  }) {
    return completed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptCommandResultCompleted value)? completed,
    TResult Function(ScriptCommandResultSuspended value)? suspended,
    TResult Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult Function(ScriptCommandResultTerminated value)? terminated,
    TResult Function(ScriptCommandResultError value)? error,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(this);
    }
    return orElse();
  }
}

abstract class ScriptCommandResultCompleted implements ScriptCommandResult {
  const factory ScriptCommandResultCompleted() =
      _$ScriptCommandResultCompletedImpl;
}

/// @nodoc
abstract class _$$ScriptCommandResultSuspendedImplCopyWith<$Res> {
  factory _$$ScriptCommandResultSuspendedImplCopyWith(
          _$ScriptCommandResultSuspendedImpl value,
          $Res Function(_$ScriptCommandResultSuspendedImpl) then) =
      __$$ScriptCommandResultSuspendedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ScriptSuspendReason reason, YarnDialogueRef? dialogue});

  $YarnDialogueRefCopyWith<$Res>? get dialogue;
}

/// @nodoc
class __$$ScriptCommandResultSuspendedImplCopyWithImpl<$Res>
    extends _$ScriptCommandResultCopyWithImpl<$Res,
        _$ScriptCommandResultSuspendedImpl>
    implements _$$ScriptCommandResultSuspendedImplCopyWith<$Res> {
  __$$ScriptCommandResultSuspendedImplCopyWithImpl(
      _$ScriptCommandResultSuspendedImpl _value,
      $Res Function(_$ScriptCommandResultSuspendedImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reason = null,
    Object? dialogue = freezed,
  }) {
    return _then(_$ScriptCommandResultSuspendedImpl(
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as ScriptSuspendReason,
      dialogue: freezed == dialogue
          ? _value.dialogue
          : dialogue // ignore: cast_nullable_to_non_nullable
              as YarnDialogueRef?,
    ));
  }

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $YarnDialogueRefCopyWith<$Res>? get dialogue {
    if (_value.dialogue == null) {
      return null;
    }

    return $YarnDialogueRefCopyWith<$Res>(_value.dialogue!, (value) {
      return _then(_value.copyWith(dialogue: value));
    });
  }
}

/// @nodoc

class _$ScriptCommandResultSuspendedImpl
    implements ScriptCommandResultSuspended {
  const _$ScriptCommandResultSuspendedImpl(
      {required this.reason, this.dialogue});

  @override
  final ScriptSuspendReason reason;
  @override
  final YarnDialogueRef? dialogue;

  @override
  String toString() {
    return 'ScriptCommandResult.suspended(reason: $reason, dialogue: $dialogue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptCommandResultSuspendedImpl &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.dialogue, dialogue) ||
                other.dialogue == dialogue));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason, dialogue);

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptCommandResultSuspendedImplCopyWith<
          _$ScriptCommandResultSuspendedImpl>
      get copyWith => __$$ScriptCommandResultSuspendedImplCopyWithImpl<
          _$ScriptCommandResultSuspendedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() completed,
    required TResult Function(
            ScriptSuspendReason reason, YarnDialogueRef? dialogue)
        suspended,
    required TResult Function(String nodeId) jumpToNode,
    required TResult Function() terminated,
    required TResult Function(String message) error,
  }) {
    return suspended(reason, dialogue);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? completed,
    TResult? Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult? Function(String nodeId)? jumpToNode,
    TResult? Function()? terminated,
    TResult? Function(String message)? error,
  }) {
    return suspended?.call(reason, dialogue);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? completed,
    TResult Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult Function(String nodeId)? jumpToNode,
    TResult Function()? terminated,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (suspended != null) {
      return suspended(reason, dialogue);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptCommandResultCompleted value) completed,
    required TResult Function(ScriptCommandResultSuspended value) suspended,
    required TResult Function(ScriptCommandResultJumpToNode value) jumpToNode,
    required TResult Function(ScriptCommandResultTerminated value) terminated,
    required TResult Function(ScriptCommandResultError value) error,
  }) {
    return suspended(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptCommandResultCompleted value)? completed,
    TResult? Function(ScriptCommandResultSuspended value)? suspended,
    TResult? Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult? Function(ScriptCommandResultTerminated value)? terminated,
    TResult? Function(ScriptCommandResultError value)? error,
  }) {
    return suspended?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptCommandResultCompleted value)? completed,
    TResult Function(ScriptCommandResultSuspended value)? suspended,
    TResult Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult Function(ScriptCommandResultTerminated value)? terminated,
    TResult Function(ScriptCommandResultError value)? error,
    required TResult orElse(),
  }) {
    if (suspended != null) {
      return suspended(this);
    }
    return orElse();
  }
}

abstract class ScriptCommandResultSuspended implements ScriptCommandResult {
  const factory ScriptCommandResultSuspended(
      {required final ScriptSuspendReason reason,
      final YarnDialogueRef? dialogue}) = _$ScriptCommandResultSuspendedImpl;

  ScriptSuspendReason get reason;
  YarnDialogueRef? get dialogue;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptCommandResultSuspendedImplCopyWith<
          _$ScriptCommandResultSuspendedImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ScriptCommandResultJumpToNodeImplCopyWith<$Res> {
  factory _$$ScriptCommandResultJumpToNodeImplCopyWith(
          _$ScriptCommandResultJumpToNodeImpl value,
          $Res Function(_$ScriptCommandResultJumpToNodeImpl) then) =
      __$$ScriptCommandResultJumpToNodeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String nodeId});
}

/// @nodoc
class __$$ScriptCommandResultJumpToNodeImplCopyWithImpl<$Res>
    extends _$ScriptCommandResultCopyWithImpl<$Res,
        _$ScriptCommandResultJumpToNodeImpl>
    implements _$$ScriptCommandResultJumpToNodeImplCopyWith<$Res> {
  __$$ScriptCommandResultJumpToNodeImplCopyWithImpl(
      _$ScriptCommandResultJumpToNodeImpl _value,
      $Res Function(_$ScriptCommandResultJumpToNodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nodeId = null,
  }) {
    return _then(_$ScriptCommandResultJumpToNodeImpl(
      null == nodeId
          ? _value.nodeId
          : nodeId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ScriptCommandResultJumpToNodeImpl
    implements ScriptCommandResultJumpToNode {
  const _$ScriptCommandResultJumpToNodeImpl(this.nodeId);

  @override
  final String nodeId;

  @override
  String toString() {
    return 'ScriptCommandResult.jumpToNode(nodeId: $nodeId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptCommandResultJumpToNodeImpl &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, nodeId);

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptCommandResultJumpToNodeImplCopyWith<
          _$ScriptCommandResultJumpToNodeImpl>
      get copyWith => __$$ScriptCommandResultJumpToNodeImplCopyWithImpl<
          _$ScriptCommandResultJumpToNodeImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() completed,
    required TResult Function(
            ScriptSuspendReason reason, YarnDialogueRef? dialogue)
        suspended,
    required TResult Function(String nodeId) jumpToNode,
    required TResult Function() terminated,
    required TResult Function(String message) error,
  }) {
    return jumpToNode(nodeId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? completed,
    TResult? Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult? Function(String nodeId)? jumpToNode,
    TResult? Function()? terminated,
    TResult? Function(String message)? error,
  }) {
    return jumpToNode?.call(nodeId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? completed,
    TResult Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult Function(String nodeId)? jumpToNode,
    TResult Function()? terminated,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (jumpToNode != null) {
      return jumpToNode(nodeId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptCommandResultCompleted value) completed,
    required TResult Function(ScriptCommandResultSuspended value) suspended,
    required TResult Function(ScriptCommandResultJumpToNode value) jumpToNode,
    required TResult Function(ScriptCommandResultTerminated value) terminated,
    required TResult Function(ScriptCommandResultError value) error,
  }) {
    return jumpToNode(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptCommandResultCompleted value)? completed,
    TResult? Function(ScriptCommandResultSuspended value)? suspended,
    TResult? Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult? Function(ScriptCommandResultTerminated value)? terminated,
    TResult? Function(ScriptCommandResultError value)? error,
  }) {
    return jumpToNode?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptCommandResultCompleted value)? completed,
    TResult Function(ScriptCommandResultSuspended value)? suspended,
    TResult Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult Function(ScriptCommandResultTerminated value)? terminated,
    TResult Function(ScriptCommandResultError value)? error,
    required TResult orElse(),
  }) {
    if (jumpToNode != null) {
      return jumpToNode(this);
    }
    return orElse();
  }
}

abstract class ScriptCommandResultJumpToNode implements ScriptCommandResult {
  const factory ScriptCommandResultJumpToNode(final String nodeId) =
      _$ScriptCommandResultJumpToNodeImpl;

  String get nodeId;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptCommandResultJumpToNodeImplCopyWith<
          _$ScriptCommandResultJumpToNodeImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ScriptCommandResultTerminatedImplCopyWith<$Res> {
  factory _$$ScriptCommandResultTerminatedImplCopyWith(
          _$ScriptCommandResultTerminatedImpl value,
          $Res Function(_$ScriptCommandResultTerminatedImpl) then) =
      __$$ScriptCommandResultTerminatedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ScriptCommandResultTerminatedImplCopyWithImpl<$Res>
    extends _$ScriptCommandResultCopyWithImpl<$Res,
        _$ScriptCommandResultTerminatedImpl>
    implements _$$ScriptCommandResultTerminatedImplCopyWith<$Res> {
  __$$ScriptCommandResultTerminatedImplCopyWithImpl(
      _$ScriptCommandResultTerminatedImpl _value,
      $Res Function(_$ScriptCommandResultTerminatedImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ScriptCommandResultTerminatedImpl
    implements ScriptCommandResultTerminated {
  const _$ScriptCommandResultTerminatedImpl();

  @override
  String toString() {
    return 'ScriptCommandResult.terminated()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptCommandResultTerminatedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() completed,
    required TResult Function(
            ScriptSuspendReason reason, YarnDialogueRef? dialogue)
        suspended,
    required TResult Function(String nodeId) jumpToNode,
    required TResult Function() terminated,
    required TResult Function(String message) error,
  }) {
    return terminated();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? completed,
    TResult? Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult? Function(String nodeId)? jumpToNode,
    TResult? Function()? terminated,
    TResult? Function(String message)? error,
  }) {
    return terminated?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? completed,
    TResult Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult Function(String nodeId)? jumpToNode,
    TResult Function()? terminated,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (terminated != null) {
      return terminated();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptCommandResultCompleted value) completed,
    required TResult Function(ScriptCommandResultSuspended value) suspended,
    required TResult Function(ScriptCommandResultJumpToNode value) jumpToNode,
    required TResult Function(ScriptCommandResultTerminated value) terminated,
    required TResult Function(ScriptCommandResultError value) error,
  }) {
    return terminated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptCommandResultCompleted value)? completed,
    TResult? Function(ScriptCommandResultSuspended value)? suspended,
    TResult? Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult? Function(ScriptCommandResultTerminated value)? terminated,
    TResult? Function(ScriptCommandResultError value)? error,
  }) {
    return terminated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptCommandResultCompleted value)? completed,
    TResult Function(ScriptCommandResultSuspended value)? suspended,
    TResult Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult Function(ScriptCommandResultTerminated value)? terminated,
    TResult Function(ScriptCommandResultError value)? error,
    required TResult orElse(),
  }) {
    if (terminated != null) {
      return terminated(this);
    }
    return orElse();
  }
}

abstract class ScriptCommandResultTerminated implements ScriptCommandResult {
  const factory ScriptCommandResultTerminated() =
      _$ScriptCommandResultTerminatedImpl;
}

/// @nodoc
abstract class _$$ScriptCommandResultErrorImplCopyWith<$Res> {
  factory _$$ScriptCommandResultErrorImplCopyWith(
          _$ScriptCommandResultErrorImpl value,
          $Res Function(_$ScriptCommandResultErrorImpl) then) =
      __$$ScriptCommandResultErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ScriptCommandResultErrorImplCopyWithImpl<$Res>
    extends _$ScriptCommandResultCopyWithImpl<$Res,
        _$ScriptCommandResultErrorImpl>
    implements _$$ScriptCommandResultErrorImplCopyWith<$Res> {
  __$$ScriptCommandResultErrorImplCopyWithImpl(
      _$ScriptCommandResultErrorImpl _value,
      $Res Function(_$ScriptCommandResultErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ScriptCommandResultErrorImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ScriptCommandResultErrorImpl implements ScriptCommandResultError {
  const _$ScriptCommandResultErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'ScriptCommandResult.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptCommandResultErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptCommandResultErrorImplCopyWith<_$ScriptCommandResultErrorImpl>
      get copyWith => __$$ScriptCommandResultErrorImplCopyWithImpl<
          _$ScriptCommandResultErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() completed,
    required TResult Function(
            ScriptSuspendReason reason, YarnDialogueRef? dialogue)
        suspended,
    required TResult Function(String nodeId) jumpToNode,
    required TResult Function() terminated,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? completed,
    TResult? Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult? Function(String nodeId)? jumpToNode,
    TResult? Function()? terminated,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? completed,
    TResult Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult Function(String nodeId)? jumpToNode,
    TResult Function()? terminated,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptCommandResultCompleted value) completed,
    required TResult Function(ScriptCommandResultSuspended value) suspended,
    required TResult Function(ScriptCommandResultJumpToNode value) jumpToNode,
    required TResult Function(ScriptCommandResultTerminated value) terminated,
    required TResult Function(ScriptCommandResultError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptCommandResultCompleted value)? completed,
    TResult? Function(ScriptCommandResultSuspended value)? suspended,
    TResult? Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult? Function(ScriptCommandResultTerminated value)? terminated,
    TResult? Function(ScriptCommandResultError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptCommandResultCompleted value)? completed,
    TResult Function(ScriptCommandResultSuspended value)? suspended,
    TResult Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult Function(ScriptCommandResultTerminated value)? terminated,
    TResult Function(ScriptCommandResultError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class ScriptCommandResultError implements ScriptCommandResult {
  const factory ScriptCommandResultError(final String message) =
      _$ScriptCommandResultErrorImpl;

  String get message;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptCommandResultErrorImplCopyWith<_$ScriptCommandResultErrorImpl>
      get copyWith => throw _privateConstructorUsedError;
}
