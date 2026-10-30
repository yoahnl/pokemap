import '../../domain/repositories/game_save_repository.dart';

enum NarrativeRuntimeActivity {
  idle,
  dispatching,
  sceneActive,
  sceneSuspended,
  outboxProcessing,
}

enum NarrativeRuntimeCheckpointOperation { save, load }

final class NarrativeRuntimeCheckpointBlockedException
    extends GameSaveException {
  NarrativeRuntimeCheckpointBlockedException({
    required this.operation,
    required this.activity,
    required this.reasonCode,
  }) : super(
         'Narrative runtime checkpoint blocked: '
         '${operation.name}/$reasonCode.',
       );

  final NarrativeRuntimeCheckpointOperation operation;
  final NarrativeRuntimeActivity activity;
  final String reasonCode;
}

final class NarrativeRuntimeActivityBlockedException implements Exception {
  const NarrativeRuntimeActivityBlockedException(this.activity);

  final NarrativeRuntimeActivity activity;
}

final class NarrativeRuntimeActivityLease {
  NarrativeRuntimeActivityLease._(this._gate, this._token);

  NarrativeRuntimeActivityGate? _gate;
  final Object _token;

  void close() {
    _gate?._leave(_token);
    _gate = null;
  }
}

final class NarrativeRuntimeActivityGate {
  NarrativeRuntimeActivityGate();

  final List<(Object, NarrativeRuntimeActivity)> _activities = [];
  bool _checkpointInProgress = false;

  NarrativeRuntimeActivity get activity =>
      _activities.isEmpty ? NarrativeRuntimeActivity.idle : _activities.last.$2;

  bool get checkpointInProgress => _checkpointInProgress;

  NarrativeRuntimeActivityLease enter(NarrativeRuntimeActivity next) {
    if (next == NarrativeRuntimeActivity.idle) {
      throw ArgumentError.value(next, 'next');
    }
    if (_checkpointInProgress) {
      throw NarrativeRuntimeActivityBlockedException(next);
    }
    final token = Object();
    _activities.add((token, next));
    return NarrativeRuntimeActivityLease._(this, token);
  }

  Future<T> runWithActivity<T>(
    NarrativeRuntimeActivity next,
    Future<T> Function() action,
  ) async {
    final lease = enter(next);
    try {
      return await action();
    } finally {
      lease.close();
    }
  }

  Future<T> runCheckpoint<T>(
    NarrativeRuntimeCheckpointOperation operation,
    Future<T> Function() action,
  ) async {
    if (_checkpointInProgress) {
      throw NarrativeRuntimeCheckpointBlockedException(
        operation: operation,
        activity: NarrativeRuntimeActivity.idle,
        reasonCode: 'checkpointInProgress',
      );
    }
    final current = activity;
    if (current != NarrativeRuntimeActivity.idle) {
      throw NarrativeRuntimeCheckpointBlockedException(
        operation: operation,
        activity: current,
        reasonCode: current.name,
      );
    }
    _checkpointInProgress = true;
    try {
      return await action();
    } finally {
      _checkpointInProgress = false;
    }
  }

  NarrativeRuntimeSceneCheckpointOwner captureSceneCheckpointOwner() {
    if (_checkpointInProgress ||
        activity != NarrativeRuntimeActivity.sceneActive) {
      throw StateError('An active Scene must own its service checkpoint.');
    }
    return NarrativeRuntimeSceneCheckpointOwner._(this, [
      for (final entry in _activities) entry.$1,
    ]);
  }

  Future<T> runSceneCheckpoint<T>(
    NarrativeRuntimeSceneCheckpointOwner owner,
    Future<T> Function() action,
  ) async {
    if (!identical(owner._gate, this) ||
        _checkpointInProgress ||
        activity != NarrativeRuntimeActivity.sceneActive ||
        owner._tokens.length != _activities.length ||
        Iterable<int>.generate(_activities.length).any(
          (index) => !identical(owner._tokens[index], _activities[index].$1),
        )) {
      throw StateError('The Scene checkpoint activity owner is stale.');
    }
    _checkpointInProgress = true;
    try {
      return await action();
    } finally {
      _checkpointInProgress = false;
    }
  }

  void _leave(Object token) {
    _activities.removeWhere((entry) => identical(entry.$1, token));
  }
}

final class NarrativeRuntimeSceneCheckpointOwner {
  NarrativeRuntimeSceneCheckpointOwner._(this._gate, this._tokens);
  final NarrativeRuntimeActivityGate _gate;
  final List<Object> _tokens;
}
