import 'dart:async';

import 'package:map_core/map_core.dart';

abstract final class NarrativeEventStateTransaction {
  static NarrativeEventStateTransactionDecision<T> commit<T>(
    GameState gameState,
    T value,
  ) {
    return NarrativeEventStateTransactionCommit<T>(gameState, value);
  }

  static NarrativeEventStateTransactionDecision<T> rollback<T>(T value) {
    return NarrativeEventStateTransactionRollback<T>(value);
  }
}

sealed class NarrativeEventStateTransactionDecision<T> {
  const NarrativeEventStateTransactionDecision(this.value);

  final T value;
}

final class NarrativeEventStateTransactionCommit<T>
    extends NarrativeEventStateTransactionDecision<T> {
  const NarrativeEventStateTransactionCommit(this.gameState, super.value);

  final GameState gameState;
}

final class NarrativeEventStateTransactionRollback<T>
    extends NarrativeEventStateTransactionDecision<T> {
  const NarrativeEventStateTransactionRollback(super.value);
}

typedef NarrativeEventStateTransactionCallback<T>
    = FutureOr<NarrativeEventStateTransactionDecision<T>> Function(
  GameState gameState,
);

typedef NarrativeEventAfterCommitCallback = FutureOr<void> Function(
  GameState committedGameState,
);

final Object _narrativeTransactionZoneKey = Object();

final class _NarrativeEventTransactionContext {
  _NarrativeEventTransactionContext(this.owner, this.rollbackState);

  GameState rollbackState;
  bool active = true;
  bool closing = false;
  bool checkpointBusy = false;
  Future<void>? pendingCheckpoint;
  final rebases = <GameState Function(GameState)>[];

  final NarrativeEventStateTransactions owner;
  final List<NarrativeEventAfterCommitCallback> afterCommitCallbacks =
      <NarrativeEventAfterCommitCallback>[];
}

final class NarrativeEventStateTransactions {
  NarrativeEventStateTransactions(GameState initialGameState)
      : _gameState = initialGameState;

  GameState _gameState;
  Future<void> _tail = Future<void>.value();
  Future<void> _outboxTail = Future<void>.value();
  _NarrativeEventTransactionContext? _activeContext;

  Future<T> transact<T>(NarrativeEventStateTransactionCallback<T> callback) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      final context = _NarrativeEventTransactionContext(this, _gameState);
      _activeContext = context;
      try {
        final decision = await runZoned(
          () => callback(_gameState),
          zoneValues: <Object, Object>{
            _narrativeTransactionZoneKey: context,
          },
        );
        context.closing = true;
        await context.pendingCheckpoint;
        if (decision is NarrativeEventStateTransactionCommit<T>) {
          var committed = decision.gameState;
          for (final rebase in context.rebases) {
            committed = rebase(committed);
          }
          _gameState = committed;
          for (final afterCommit in context.afterCommitCallbacks) {
            await afterCommit(_gameState);
          }
        }
        completer.complete(decision.value);
      } catch (error, stackTrace) {
        context.closing = true;
        await context.pendingCheckpoint;
        _gameState = context.rollbackState;
        completer.completeError(error, stackTrace);
      } finally {
        context.active = false;
        if (identical(_activeContext, context)) _activeContext = null;
      }
    });
    return completer.future;
  }

  /// Registers work that must run after the surrounding transaction commits.
  ///
  /// The callback executes outside the user transaction callback, but before
  /// [transact] completes. A callback failure restores the transaction's
  /// previous in-memory state and surfaces as a transaction failure. Returns
  /// `false` when called outside this transaction queue.
  bool deferAfterCurrentCommit(NarrativeEventAfterCommitCallback callback) {
    final context = Zone.current[_narrativeTransactionZoneKey];
    if (context is! _NarrativeEventTransactionContext ||
        !identical(context.owner, this)) {
      return false;
    }
    context.afterCommitCallbacks.add(callback);
    return true;
  }

  NarrativeEventStateCheckpointOwner? captureCheckpointOwner() {
    final context = Zone.current[_narrativeTransactionZoneKey];
    if (context is! _NarrativeEventTransactionContext ||
        !identical(context.owner, this) ||
        !context.active ||
        context.closing ||
        !identical(_activeContext, context)) {
      return null;
    }
    return NarrativeEventStateCheckpointOwner._(this, context);
  }

  Future<void> _checkpoint(
    NarrativeEventStateCheckpointOwner owner, {
    required GameState expectedBase,
    required GameState durableState,
    required Future<void> Function(GameState) persist,
    required GameState Function(GameState) rebase,
  }) async {
    final context = owner._context;
    if (!identical(owner._owner, this) ||
        !identical(_activeContext, context) ||
        !context.active ||
        context.closing ||
        context.checkpointBusy ||
        !identical(_gameState, expectedBase) ||
        durableState.saveId != expectedBase.saveId) {
      throw StateError('The narrative checkpoint owner or baseline is stale.');
    }
    context.checkpointBusy = true;
    final settled = Completer<void>();
    context.pendingCheckpoint = settled.future;
    try {
      await persist(durableState);
      context.rollbackState = durableState;
      context.rebases.add(rebase);
      _gameState = durableState;
    } finally {
      context.checkpointBusy = false;
      settled.complete();
    }
  }

  Future<T> serializeOutbox<T>(Future<T> Function() callback) {
    final completer = Completer<T>();
    _outboxTail = _outboxTail.then((_) async {
      try {
        completer.complete(await callback());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<GameState> read() {
    return transact(
      (gameState) => NarrativeEventStateTransaction.rollback(gameState),
    );
  }
}

final class NarrativeEventStateCheckpointOwner {
  NarrativeEventStateCheckpointOwner._(this._owner, this._context);
  final NarrativeEventStateTransactions _owner;
  final _NarrativeEventTransactionContext _context;

  GameState get latestCheckpointState {
    if (!_context.active || !identical(_owner._activeContext, _context)) {
      throw StateError('The narrative checkpoint owner is no longer active.');
    }
    return _context.rollbackState;
  }

  GameState get committedState {
    if (!_context.active ||
        _context.closing ||
        !identical(_owner._activeContext, _context)) {
      throw StateError('The narrative checkpoint owner is no longer active.');
    }
    return _owner._gameState;
  }

  Future<void> checkpoint(
          {required GameState expectedBase,
          required GameState durableState,
          required Future<void> Function(GameState) persist,
          required GameState Function(GameState) rebase}) =>
      _owner._checkpoint(this,
          expectedBase: expectedBase,
          durableState: durableState,
          persist: persist,
          rebase: rebase);
}
