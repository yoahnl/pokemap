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

final class NarrativeEventStateTransactions {
  NarrativeEventStateTransactions(GameState initialGameState)
      : _gameState = initialGameState;

  GameState _gameState;
  Future<void> _tail = Future<void>.value();
  Future<void> _outboxTail = Future<void>.value();

  Future<T> transact<T>(NarrativeEventStateTransactionCallback<T> callback) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        final decision = await callback(_gameState);
        if (decision is NarrativeEventStateTransactionCommit<T>) {
          _gameState = decision.gameState;
        }
        completer.complete(decision.value);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
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
