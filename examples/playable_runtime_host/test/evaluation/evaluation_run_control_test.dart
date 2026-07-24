import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_run_control.dart';

void main() {
  test('step releases exactly one pending scenario boundary', () async {
    final control = EvaluationRunControl.paused();
    var completed = 0;

    final first = control.beforeStep().then((_) => completed += 1);
    final second =
        first.then((_) => control.beforeStep()).then((_) => completed += 1);

    control.step();
    await first;
    await pumpEventQueue();
    expect(completed, 1);
    expect(control.state, EvaluationControlState.paused);

    control.step();
    await second;
    expect(completed, 2);
  });

  test('resume releases every waiter and future boundaries', () async {
    final control = EvaluationRunControl.paused();
    var completed = 0;
    final waits = <Future<void>>[
      control.beforeStep().then((_) => completed += 1),
      control.beforeStep().then((_) => completed += 1),
    ];

    control.resume();
    await Future.wait(waits);
    await control.beforeStep();

    expect(completed, 2);
    expect(control.state, EvaluationControlState.running);
  });

  test('cancel fails current waiters and every future boundary', () async {
    final control = EvaluationRunControl.paused();
    final waiting = control.beforeStep();

    control.cancel();

    await expectLater(waiting, throwsA(isA<EvaluationRunCancelled>()));
    await expectLater(
      control.beforeStep(),
      throwsA(isA<EvaluationRunCancelled>()),
    );
    expect(control.state, EvaluationControlState.cancelled);
  });

  test('publishes only effective state transitions', () async {
    final control = EvaluationRunControl.running();
    final transitions = <EvaluationRunControlTransition>[];
    final subscription = control.transitions.listen(transitions.add);
    addTearDown(subscription.cancel);

    control.pause();
    control.pause();
    control.resume();
    control.resume();
    control.cancel();
    control.cancel();
    await pumpEventQueue();

    expect(
      transitions.map((transition) => transition.state),
      <EvaluationControlState>[
        EvaluationControlState.paused,
        EvaluationControlState.running,
        EvaluationControlState.cancelled,
      ],
    );
  });
}
