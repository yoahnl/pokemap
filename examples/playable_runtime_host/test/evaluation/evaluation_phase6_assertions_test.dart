import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_state_snapshot.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_assertion_evaluator.dart';

void main() {
  test('scene and outcome fields are first-class assertion roots', () {
    final snapshot = EvaluationStateSnapshot(
      projectId: 'selbrume',
      runId: 'run-071',
      mapId: 'map_port',
      x: 2,
      y: 3,
      movementMode: 'walk',
      money: 100,
      activeScene: const <String, Object?>{
        'active': true,
        'pendingBattle': false,
      },
      outcome: const <String, Object?>{
        'flowPhase': 'scene',
        'gameCompleted': false,
      },
    );
    const evaluator = EvaluationAssertionEvaluator();

    expect(
      evaluator
          .evaluate(
            EvaluationAssertionStep(
              id: 'scene-active',
              path: 'scene.active',
              matcher: 'isTrue',
              expected: true,
            ),
            snapshot,
          )
          .passed,
      isTrue,
    );
    expect(
      evaluator
          .evaluate(
            EvaluationAssertionStep(
              id: 'outcome-phase',
              path: 'outcome.flowPhase',
              matcher: 'equals',
              expected: 'scene',
            ),
            snapshot,
          )
          .passed,
      isTrue,
    );
  });
}
