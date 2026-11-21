import 'dart:async';

enum EvaluationControlState {
  running,
  paused,
  cancelled,
}

final class EvaluationRunControlTransition {
  const EvaluationRunControlTransition({
    required this.previousState,
    required this.state,
  });

  final EvaluationControlState previousState;
  final EvaluationControlState state;

  String get eventType => switch (state) {
        EvaluationControlState.running => 'run.resumed',
        EvaluationControlState.paused => 'run.paused',
        EvaluationControlState.cancelled => 'run.cancelled',
      };
}

final class EvaluationRunCancelled implements Exception {
  const EvaluationRunCancelled();

  @override
  String toString() => 'Evaluation run cancelled.';
}

final class EvaluationRunControl {
  EvaluationRunControl.running() : _state = EvaluationControlState.running;

  EvaluationRunControl.paused() : _state = EvaluationControlState.paused;

  EvaluationControlState _state;
  int _stepPermits = 0;
  final List<Completer<void>> _waiters = <Completer<void>>[];
  final StreamController<EvaluationRunControlTransition> _transitions =
      StreamController<EvaluationRunControlTransition>.broadcast(sync: true);

  EvaluationControlState get state => _state;
  Stream<EvaluationRunControlTransition> get transitions => _transitions.stream;

  Future<void> beforeStep() async {
    if (_state == EvaluationControlState.cancelled) {
      throw const EvaluationRunCancelled();
    }
    if (_state == EvaluationControlState.running) return;
    if (_stepPermits > 0) {
      _stepPermits -= 1;
      return;
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    await waiter.future;
  }

  void pause() {
    _requireActive();
    if (_state == EvaluationControlState.paused) return;
    _transitionTo(EvaluationControlState.paused);
  }

  void step() {
    _requireActive();
    if (_state != EvaluationControlState.paused) {
      throw StateError('Step is available only while a run is paused.');
    }
    if (_waiters.isEmpty) {
      _stepPermits += 1;
      return;
    }
    _waiters.removeAt(0).complete();
  }

  void resume() {
    _requireActive();
    if (_state == EvaluationControlState.running) return;
    _stepPermits = 0;
    _transitionTo(EvaluationControlState.running);
    final waiters = List<Completer<void>>.of(_waiters);
    _waiters.clear();
    for (final waiter in waiters) {
      waiter.complete();
    }
  }

  void cancel() {
    if (_state == EvaluationControlState.cancelled) return;
    _stepPermits = 0;
    _transitionTo(EvaluationControlState.cancelled);
    final waiters = List<Completer<void>>.of(_waiters);
    _waiters.clear();
    for (final waiter in waiters) {
      waiter.completeError(const EvaluationRunCancelled());
    }
  }

  Future<void> close() async {
    if (!_transitions.isClosed) {
      await _transitions.close();
    }
  }

  void _requireActive() {
    if (_state == EvaluationControlState.cancelled) {
      throw const EvaluationRunCancelled();
    }
  }

  void _transitionTo(EvaluationControlState next) {
    final previous = _state;
    if (previous == next) return;
    _state = next;
    if (!_transitions.isClosed) {
      _transitions.add(
        EvaluationRunControlTransition(
          previousState: previous,
          state: next,
        ),
      );
    }
  }
}
