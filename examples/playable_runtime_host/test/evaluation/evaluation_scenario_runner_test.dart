import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_event.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_state_snapshot.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_assertion_evaluator.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_run_control.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_scenario_runner.dart';

void main() {
  test('runner emits strictly ordered events and a state diff', () async {
    final driver = _FakeEvaluationDriver(initialMoney: 1000);
    final events = <EvaluationEvent>[];
    final result = await EvaluationScenarioRunner(
      driver: driver,
      eventSink: events.add,
      runIdFactory: () => 'run-shop',
      checkpointProvenance: const <String, Object?>{
        'scenarioId': 'selbrume.shared-checkpoints',
        'saveSchemaVersion': 1,
      },
    ).run(_shopScenario());

    expect(
      events.map((event) => event.sequence),
      orderedEquals(
        List<int>.generate(events.length, (index) => index + 1),
      ),
    );
    expect(events.first.type, 'run.started');
    expect(
      events.first.payload['checkpointProvenance'],
      const <String, Object?>{
        'scenarioId': 'selbrume.shared-checkpoints',
        'saveSchemaVersion': 1,
      },
    );
    expect(events.last.type, 'run.finished');
    expect(result.status, EvaluationRunStatus.succeeded);
    expect(result.diff.changeAt('trainer.money')?.after, 750);
    expect(result.productCriteria.single.passed, isTrue);
  });

  test('runner applies control only between complete scenario steps', () async {
    final driver = _FakeEvaluationDriver(initialMoney: 1000);
    final control = EvaluationRunControl.paused();
    addTearDown(control.close);
    final events = <EvaluationEvent>[];
    var finished = false;

    final run = EvaluationScenarioRunner(
      driver: driver,
      eventSink: events.add,
      runIdFactory: () => 'run-controlled',
      runControl: control,
    ).run(_shopScenario()).whenComplete(() => finished = true);
    await pumpEventQueue();

    expect(driver._money, 1000);
    expect(finished, isFalse);
    expect(events.map((event) => event.type), contains('run.paused'));

    control.step();
    await pumpEventQueue();

    expect(driver._money, 750);
    expect(finished, isFalse);

    control.resume();
    final result = await run;

    expect(result.status, EvaluationRunStatus.succeeded);
    expect(events.map((event) => event.type), contains('run.resumed'));
  });

  test('certification stops on the first failed assertion', () async {
    final driver = _FakeEvaluationDriver(initialMoney: 1000);
    final result = await EvaluationScenarioRunner(
      driver: driver,
      runIdFactory: () => 'run-assertion',
    ).run(
      _scenarioWithAssertions(<EvaluationAssertionStep>[
        _assertion('wrong-money', 'state.money', 'equals', 999),
        _assertion('never-run', 'state.money', 'equals', 1000),
      ]),
    );

    expect(result.status, EvaluationRunStatus.failed);
    expect(result.stepResults, hasLength(1));
    expect(result.stepResults.single.stepId, 'wrong-money');
    expect(result.stepResults.single.passed, isFalse);
  });

  test('unknown assertion paths are invalid scenarios', () async {
    final result = await EvaluationScenarioRunner(
      driver: _FakeEvaluationDriver(initialMoney: 1000),
      runIdFactory: () => 'run-invalid',
    ).run(
      _scenarioWithAssertions(<EvaluationAssertionStep>[
        _assertion('unknown', 'runtime.privateField', 'equals', 1),
      ]),
    );

    expect(result.status, EvaluationRunStatus.invalidScenario);
    expect(result.stepResults.single.passed, isFalse);
  });

  test('assertion evaluator supports the complete declarative matcher set', () {
    const evaluator = EvaluationAssertionEvaluator();
    final snapshot = EvaluationStateSnapshot(
      projectId: 'selbrume',
      runId: 'run-matchers',
      mapId: 'map_port_brisants',
      x: 12,
      y: 8,
      movementMode: 'walk',
      facts: const <String, Object?>{'enabled': true, 'disabled': false},
      money: 1000,
      bag: const <String, int>{'potion': 1},
    );
    final assertions = <EvaluationAssertionStep>[
      _assertion('equals', 'trainer.money', 'equals', 1000),
      _assertion('not-equals', 'trainer.money', 'notEquals', 999),
      _assertion('contains', 'bag', 'contains', 'potion'),
      _assertion('not-contains', 'bag', 'notContains', 'revive'),
      _assertion('greater', 'trainer.money', 'greaterThan', 999),
      _assertion('less', 'trainer.money', 'lessThan', 1001),
      _assertion('true', 'facts.enabled', 'isTrue', null),
      _assertion('false', 'facts.disabled', 'isFalse', null),
      _assertion('null', 'dialogue', 'isNull', null),
      _assertion('not-null', 'world.mapId', 'isNotNull', null),
    ];

    expect(
      assertions.map((assertion) => evaluator.evaluate(assertion, snapshot)),
      everyElement(
        isA<EvaluationAssertionResult>().having(
          (result) => result.passed,
          'passed',
          isTrue,
        ),
      ),
    );
  });
}

EvaluationScenario _shopScenario() {
  return EvaluationScenario(
    schemaVersion: 1,
    id: 'selbrume.shop-runner',
    title: 'Shop runner',
    projectId: 'selbrume',
    policy: EvaluationPolicy.certify,
    start: const EvaluationStart.newGame(),
    steps: <EvaluationStep>[
      EvaluationCommandStep(
        id: 'buy-potion',
        operation: 'service.shop.buy',
        arguments: const <String, Object?>{
          'itemId': 'potion',
          'quantity': 1,
        },
      ),
      EvaluationAssertionStep(
        id: 'money-spent',
        path: 'trainer.money',
        matcher: 'equals',
        expected: 750,
      ),
    ],
    criteria: <EvaluationCriterionDefinition>[
      EvaluationCriterionDefinition(
        id: 'shop-purchase',
        stepIds: <String>['buy-potion', 'money-spent'],
      ),
    ],
  );
}

EvaluationScenario _scenarioWithAssertions(
  List<EvaluationAssertionStep> assertions,
) {
  return EvaluationScenario(
    schemaVersion: 1,
    id: 'selbrume.assertions',
    title: 'Assertions',
    projectId: 'selbrume',
    policy: EvaluationPolicy.certify,
    start: const EvaluationStart.newGame(),
    steps: assertions,
  );
}

EvaluationAssertionStep _assertion(
  String id,
  String path,
  String matcher,
  Object? expected,
) {
  return EvaluationAssertionStep(
    id: id,
    path: path,
    matcher: matcher,
    expected: expected,
  );
}

final class _FakeEvaluationDriver implements EvaluationDriver {
  _FakeEvaluationDriver({required int initialMoney}) : _money = initialMoney;

  int _money;

  @override
  EvaluationStateSnapshot snapshot() {
    return EvaluationStateSnapshot(
      projectId: 'selbrume',
      runId: 'driver-run',
      mapId: 'map_port_brisants',
      x: 12,
      y: 8,
      movementMode: 'walk',
      money: _money,
    );
  }

  @override
  Future<void> startNewGame() async {}

  @override
  Future<void> buy(String itemId, int quantity) async {
    _money -= 250 * quantity;
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
