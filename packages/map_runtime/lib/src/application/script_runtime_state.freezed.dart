// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'script_runtime_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScriptExecutionState {
  /// Script en cours d'exécution.
  ScriptAsset get script;

  /// Noeud actuel.
  String get currentNodeId;

  /// Index de la commande en cours dans le noeud.
  int get currentCommandIndex;

  /// true si le script est en attente (dialogue, etc.).
  bool get isSuspended;

  /// Raison de la suspension.
  ScriptSuspendReason? get suspendReason;

  /// Référence au dialogue en cours (si suspendu pour dialogue).
  YarnDialogueRef? get pendingDialogue;

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScriptExecutionStateCopyWith<ScriptExecutionState> get copyWith =>
      _$ScriptExecutionStateCopyWithImpl<ScriptExecutionState>(
          this as ScriptExecutionState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScriptExecutionState &&
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

  @override
  String toString() {
    return 'ScriptExecutionState(script: $script, currentNodeId: $currentNodeId, currentCommandIndex: $currentCommandIndex, isSuspended: $isSuspended, suspendReason: $suspendReason, pendingDialogue: $pendingDialogue)';
  }
}

/// @nodoc
abstract mixin class $ScriptExecutionStateCopyWith<$Res> {
  factory $ScriptExecutionStateCopyWith(ScriptExecutionState value,
          $Res Function(ScriptExecutionState) _then) =
      _$ScriptExecutionStateCopyWithImpl;
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
class _$ScriptExecutionStateCopyWithImpl<$Res>
    implements $ScriptExecutionStateCopyWith<$Res> {
  _$ScriptExecutionStateCopyWithImpl(this._self, this._then);

  final ScriptExecutionState _self;
  final $Res Function(ScriptExecutionState) _then;

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
    return _then(_self.copyWith(
      script: null == script
          ? _self.script
          : script // ignore: cast_nullable_to_non_nullable
              as ScriptAsset,
      currentNodeId: null == currentNodeId
          ? _self.currentNodeId
          : currentNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      currentCommandIndex: null == currentCommandIndex
          ? _self.currentCommandIndex
          : currentCommandIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isSuspended: null == isSuspended
          ? _self.isSuspended
          : isSuspended // ignore: cast_nullable_to_non_nullable
              as bool,
      suspendReason: freezed == suspendReason
          ? _self.suspendReason
          : suspendReason // ignore: cast_nullable_to_non_nullable
              as ScriptSuspendReason?,
      pendingDialogue: freezed == pendingDialogue
          ? _self.pendingDialogue
          : pendingDialogue // ignore: cast_nullable_to_non_nullable
              as YarnDialogueRef?,
    ));
  }

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptAssetCopyWith<$Res> get script {
    return $ScriptAssetCopyWith<$Res>(_self.script, (value) {
      return _then(_self.copyWith(script: value));
    });
  }

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $YarnDialogueRefCopyWith<$Res>? get pendingDialogue {
    if (_self.pendingDialogue == null) {
      return null;
    }

    return $YarnDialogueRefCopyWith<$Res>(_self.pendingDialogue!, (value) {
      return _then(_self.copyWith(pendingDialogue: value));
    });
  }
}

/// Adds pattern-matching-related methods to [ScriptExecutionState].
extension ScriptExecutionStatePatterns on ScriptExecutionState {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ScriptExecutionState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScriptExecutionState() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ScriptExecutionState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScriptExecutionState():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ScriptExecutionState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScriptExecutionState() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            ScriptAsset script,
            String currentNodeId,
            int currentCommandIndex,
            bool isSuspended,
            ScriptSuspendReason? suspendReason,
            YarnDialogueRef? pendingDialogue)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScriptExecutionState() when $default != null:
        return $default(
            _that.script,
            _that.currentNodeId,
            _that.currentCommandIndex,
            _that.isSuspended,
            _that.suspendReason,
            _that.pendingDialogue);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            ScriptAsset script,
            String currentNodeId,
            int currentCommandIndex,
            bool isSuspended,
            ScriptSuspendReason? suspendReason,
            YarnDialogueRef? pendingDialogue)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScriptExecutionState():
        return $default(
            _that.script,
            _that.currentNodeId,
            _that.currentCommandIndex,
            _that.isSuspended,
            _that.suspendReason,
            _that.pendingDialogue);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            ScriptAsset script,
            String currentNodeId,
            int currentCommandIndex,
            bool isSuspended,
            ScriptSuspendReason? suspendReason,
            YarnDialogueRef? pendingDialogue)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScriptExecutionState() when $default != null:
        return $default(
            _that.script,
            _that.currentNodeId,
            _that.currentCommandIndex,
            _that.isSuspended,
            _that.suspendReason,
            _that.pendingDialogue);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ScriptExecutionState implements ScriptExecutionState {
  const _ScriptExecutionState(
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

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScriptExecutionStateCopyWith<_ScriptExecutionState> get copyWith =>
      __$ScriptExecutionStateCopyWithImpl<_ScriptExecutionState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScriptExecutionState &&
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

  @override
  String toString() {
    return 'ScriptExecutionState(script: $script, currentNodeId: $currentNodeId, currentCommandIndex: $currentCommandIndex, isSuspended: $isSuspended, suspendReason: $suspendReason, pendingDialogue: $pendingDialogue)';
  }
}

/// @nodoc
abstract mixin class _$ScriptExecutionStateCopyWith<$Res>
    implements $ScriptExecutionStateCopyWith<$Res> {
  factory _$ScriptExecutionStateCopyWith(_ScriptExecutionState value,
          $Res Function(_ScriptExecutionState) _then) =
      __$ScriptExecutionStateCopyWithImpl;
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
class __$ScriptExecutionStateCopyWithImpl<$Res>
    implements _$ScriptExecutionStateCopyWith<$Res> {
  __$ScriptExecutionStateCopyWithImpl(this._self, this._then);

  final _ScriptExecutionState _self;
  final $Res Function(_ScriptExecutionState) _then;

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? script = null,
    Object? currentNodeId = null,
    Object? currentCommandIndex = null,
    Object? isSuspended = null,
    Object? suspendReason = freezed,
    Object? pendingDialogue = freezed,
  }) {
    return _then(_ScriptExecutionState(
      script: null == script
          ? _self.script
          : script // ignore: cast_nullable_to_non_nullable
              as ScriptAsset,
      currentNodeId: null == currentNodeId
          ? _self.currentNodeId
          : currentNodeId // ignore: cast_nullable_to_non_nullable
              as String,
      currentCommandIndex: null == currentCommandIndex
          ? _self.currentCommandIndex
          : currentCommandIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isSuspended: null == isSuspended
          ? _self.isSuspended
          : isSuspended // ignore: cast_nullable_to_non_nullable
              as bool,
      suspendReason: freezed == suspendReason
          ? _self.suspendReason
          : suspendReason // ignore: cast_nullable_to_non_nullable
              as ScriptSuspendReason?,
      pendingDialogue: freezed == pendingDialogue
          ? _self.pendingDialogue
          : pendingDialogue // ignore: cast_nullable_to_non_nullable
              as YarnDialogueRef?,
    ));
  }

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptAssetCopyWith<$Res> get script {
    return $ScriptAssetCopyWith<$Res>(_self.script, (value) {
      return _then(_self.copyWith(script: value));
    });
  }

  /// Create a copy of ScriptExecutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $YarnDialogueRefCopyWith<$Res>? get pendingDialogue {
    if (_self.pendingDialogue == null) {
      return null;
    }

    return $YarnDialogueRefCopyWith<$Res>(_self.pendingDialogue!, (value) {
      return _then(_self.copyWith(pendingDialogue: value));
    });
  }
}

/// @nodoc
mixin _$ScriptCommandResult {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ScriptCommandResult);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ScriptCommandResult()';
  }
}

/// @nodoc
class $ScriptCommandResultCopyWith<$Res> {
  $ScriptCommandResultCopyWith(
      ScriptCommandResult _, $Res Function(ScriptCommandResult) __);
}

/// Adds pattern-matching-related methods to [ScriptCommandResult].
extension ScriptCommandResultPatterns on ScriptCommandResult {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptCommandResultCompleted value)? completed,
    TResult Function(ScriptCommandResultSuspended value)? suspended,
    TResult Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult Function(ScriptCommandResultTerminated value)? terminated,
    TResult Function(ScriptCommandResultError value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ScriptCommandResultCompleted() when completed != null:
        return completed(_that);
      case ScriptCommandResultSuspended() when suspended != null:
        return suspended(_that);
      case ScriptCommandResultJumpToNode() when jumpToNode != null:
        return jumpToNode(_that);
      case ScriptCommandResultTerminated() when terminated != null:
        return terminated(_that);
      case ScriptCommandResultError() when error != null:
        return error(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptCommandResultCompleted value) completed,
    required TResult Function(ScriptCommandResultSuspended value) suspended,
    required TResult Function(ScriptCommandResultJumpToNode value) jumpToNode,
    required TResult Function(ScriptCommandResultTerminated value) terminated,
    required TResult Function(ScriptCommandResultError value) error,
  }) {
    final _that = this;
    switch (_that) {
      case ScriptCommandResultCompleted():
        return completed(_that);
      case ScriptCommandResultSuspended():
        return suspended(_that);
      case ScriptCommandResultJumpToNode():
        return jumpToNode(_that);
      case ScriptCommandResultTerminated():
        return terminated(_that);
      case ScriptCommandResultError():
        return error(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptCommandResultCompleted value)? completed,
    TResult? Function(ScriptCommandResultSuspended value)? suspended,
    TResult? Function(ScriptCommandResultJumpToNode value)? jumpToNode,
    TResult? Function(ScriptCommandResultTerminated value)? terminated,
    TResult? Function(ScriptCommandResultError value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case ScriptCommandResultCompleted() when completed != null:
        return completed(_that);
      case ScriptCommandResultSuspended() when suspended != null:
        return suspended(_that);
      case ScriptCommandResultJumpToNode() when jumpToNode != null:
        return jumpToNode(_that);
      case ScriptCommandResultTerminated() when terminated != null:
        return terminated(_that);
      case ScriptCommandResultError() when error != null:
        return error(_that);
      case _:
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
    final _that = this;
    switch (_that) {
      case ScriptCommandResultCompleted() when completed != null:
        return completed();
      case ScriptCommandResultSuspended() when suspended != null:
        return suspended(_that.reason, _that.dialogue);
      case ScriptCommandResultJumpToNode() when jumpToNode != null:
        return jumpToNode(_that.nodeId);
      case ScriptCommandResultTerminated() when terminated != null:
        return terminated();
      case ScriptCommandResultError() when error != null:
        return error(_that.message);
      case _:
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
    final _that = this;
    switch (_that) {
      case ScriptCommandResultCompleted():
        return completed();
      case ScriptCommandResultSuspended():
        return suspended(_that.reason, _that.dialogue);
      case ScriptCommandResultJumpToNode():
        return jumpToNode(_that.nodeId);
      case ScriptCommandResultTerminated():
        return terminated();
      case ScriptCommandResultError():
        return error(_that.message);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? completed,
    TResult? Function(ScriptSuspendReason reason, YarnDialogueRef? dialogue)?
        suspended,
    TResult? Function(String nodeId)? jumpToNode,
    TResult? Function()? terminated,
    TResult? Function(String message)? error,
  }) {
    final _that = this;
    switch (_that) {
      case ScriptCommandResultCompleted() when completed != null:
        return completed();
      case ScriptCommandResultSuspended() when suspended != null:
        return suspended(_that.reason, _that.dialogue);
      case ScriptCommandResultJumpToNode() when jumpToNode != null:
        return jumpToNode(_that.nodeId);
      case ScriptCommandResultTerminated() when terminated != null:
        return terminated();
      case ScriptCommandResultError() when error != null:
        return error(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ScriptCommandResultCompleted implements ScriptCommandResult {
  const ScriptCommandResultCompleted();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScriptCommandResultCompleted);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ScriptCommandResult.completed()';
  }
}

/// @nodoc

class ScriptCommandResultSuspended implements ScriptCommandResult {
  const ScriptCommandResultSuspended({required this.reason, this.dialogue});

  final ScriptSuspendReason reason;
  final YarnDialogueRef? dialogue;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScriptCommandResultSuspendedCopyWith<ScriptCommandResultSuspended>
      get copyWith => _$ScriptCommandResultSuspendedCopyWithImpl<
          ScriptCommandResultSuspended>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScriptCommandResultSuspended &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.dialogue, dialogue) ||
                other.dialogue == dialogue));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason, dialogue);

  @override
  String toString() {
    return 'ScriptCommandResult.suspended(reason: $reason, dialogue: $dialogue)';
  }
}

/// @nodoc
abstract mixin class $ScriptCommandResultSuspendedCopyWith<$Res>
    implements $ScriptCommandResultCopyWith<$Res> {
  factory $ScriptCommandResultSuspendedCopyWith(
          ScriptCommandResultSuspended value,
          $Res Function(ScriptCommandResultSuspended) _then) =
      _$ScriptCommandResultSuspendedCopyWithImpl;
  @useResult
  $Res call({ScriptSuspendReason reason, YarnDialogueRef? dialogue});

  $YarnDialogueRefCopyWith<$Res>? get dialogue;
}

/// @nodoc
class _$ScriptCommandResultSuspendedCopyWithImpl<$Res>
    implements $ScriptCommandResultSuspendedCopyWith<$Res> {
  _$ScriptCommandResultSuspendedCopyWithImpl(this._self, this._then);

  final ScriptCommandResultSuspended _self;
  final $Res Function(ScriptCommandResultSuspended) _then;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? reason = null,
    Object? dialogue = freezed,
  }) {
    return _then(ScriptCommandResultSuspended(
      reason: null == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as ScriptSuspendReason,
      dialogue: freezed == dialogue
          ? _self.dialogue
          : dialogue // ignore: cast_nullable_to_non_nullable
              as YarnDialogueRef?,
    ));
  }

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $YarnDialogueRefCopyWith<$Res>? get dialogue {
    if (_self.dialogue == null) {
      return null;
    }

    return $YarnDialogueRefCopyWith<$Res>(_self.dialogue!, (value) {
      return _then(_self.copyWith(dialogue: value));
    });
  }
}

/// @nodoc

class ScriptCommandResultJumpToNode implements ScriptCommandResult {
  const ScriptCommandResultJumpToNode(this.nodeId);

  final String nodeId;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScriptCommandResultJumpToNodeCopyWith<ScriptCommandResultJumpToNode>
      get copyWith => _$ScriptCommandResultJumpToNodeCopyWithImpl<
          ScriptCommandResultJumpToNode>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScriptCommandResultJumpToNode &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, nodeId);

  @override
  String toString() {
    return 'ScriptCommandResult.jumpToNode(nodeId: $nodeId)';
  }
}

/// @nodoc
abstract mixin class $ScriptCommandResultJumpToNodeCopyWith<$Res>
    implements $ScriptCommandResultCopyWith<$Res> {
  factory $ScriptCommandResultJumpToNodeCopyWith(
          ScriptCommandResultJumpToNode value,
          $Res Function(ScriptCommandResultJumpToNode) _then) =
      _$ScriptCommandResultJumpToNodeCopyWithImpl;
  @useResult
  $Res call({String nodeId});
}

/// @nodoc
class _$ScriptCommandResultJumpToNodeCopyWithImpl<$Res>
    implements $ScriptCommandResultJumpToNodeCopyWith<$Res> {
  _$ScriptCommandResultJumpToNodeCopyWithImpl(this._self, this._then);

  final ScriptCommandResultJumpToNode _self;
  final $Res Function(ScriptCommandResultJumpToNode) _then;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? nodeId = null,
  }) {
    return _then(ScriptCommandResultJumpToNode(
      null == nodeId
          ? _self.nodeId
          : nodeId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class ScriptCommandResultTerminated implements ScriptCommandResult {
  const ScriptCommandResultTerminated();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScriptCommandResultTerminated);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ScriptCommandResult.terminated()';
  }
}

/// @nodoc

class ScriptCommandResultError implements ScriptCommandResult {
  const ScriptCommandResultError(this.message);

  final String message;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScriptCommandResultErrorCopyWith<ScriptCommandResultError> get copyWith =>
      _$ScriptCommandResultErrorCopyWithImpl<ScriptCommandResultError>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScriptCommandResultError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'ScriptCommandResult.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $ScriptCommandResultErrorCopyWith<$Res>
    implements $ScriptCommandResultCopyWith<$Res> {
  factory $ScriptCommandResultErrorCopyWith(ScriptCommandResultError value,
          $Res Function(ScriptCommandResultError) _then) =
      _$ScriptCommandResultErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$ScriptCommandResultErrorCopyWithImpl<$Res>
    implements $ScriptCommandResultErrorCopyWith<$Res> {
  _$ScriptCommandResultErrorCopyWithImpl(this._self, this._then);

  final ScriptCommandResultError _self;
  final $Res Function(ScriptCommandResultError) _then;

  /// Create a copy of ScriptCommandResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(ScriptCommandResultError(
      null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
