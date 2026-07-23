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
  _NarrativeEventTransactionContext(this.owner);

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

  Future<T> transact<T>(NarrativeEventStateTransactionCallback<T> callback) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      final previousState = _gameState;
      final context = _NarrativeEventTransactionContext(this);
      try {
        final decision = await runZoned(
          () => callback(_gameState),
          zoneValues: <Object, Object>{
            _narrativeTransactionZoneKey: context,
          },
        );
        if (decision is NarrativeEventStateTransactionCommit<T>) {
          _gameState = decision.gameState;
          for (final afterCommit in context.afterCommitCallbacks) {
            await afterCommit(_gameState);
          }
        }
        completer.complete(decision.value);
      } catch (error, stackTrace) {
        _gameState = previousState;
        completer.completeError(error, stackTrace);
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
