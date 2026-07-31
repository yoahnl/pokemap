import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_command_catalog.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_scenario_parser.dart';

void main() {
  const parser = EvaluationScenarioParser();

  test('parses a strict V1 command, assertion, and criterion', () {
    final scenario = parser.parseString('''
    {
      "schemaVersion": 1,
      "id": "selbrume.shop",
      "title": "Shop",
      "projectId": "selbrume",
      "policy": "probe",
      "start": {"checkpointId": "after-lysa"},
      "criteria": [
        {"id": "purchase", "stepIds": ["buy", "money"]}
      ],
      "steps": [
        {
          "id": "buy",
          "command": "service.shop.buy",
          "itemId": "potion",
          "quantity": 1
        },
        {
          "id": "money",
          "assert": "state.money",
          "equals": 750
        }
      ]
    }
    ''');

    expect(scenario.id, 'selbrume.shop');
    expect(scenario.policy, EvaluationPolicy.probe);
    expect(
      (scenario.start as EvaluationCheckpointStart).checkpointId,
      'after-lysa',
    );
    expect(
      scenario.steps.first,
      isA<EvaluationCommandStep>()
          .having((step) => step.operation, 'operation', 'service.shop.buy')
          .having((step) => step.arguments['quantity'], 'quantity', 1),
    );
    expect(
      scenario.steps.last,
      isA<EvaluationAssertionStep>()
          .having((step) => step.matcher, 'matcher', 'equals')
          .having((step) => step.expected, 'expected', 750),
    );
    expect(scenario.criteria.single.stepIds, <String>['buy', 'money']);
  });

  test('catalog declares the complete V1 allowlist', () {
    expect(evaluationCommandCatalog, hasLength(48));
    expect(
      evaluationCommandCatalog['service.shop.buy']?.requiredKeys,
      <String>{'itemId', 'quantity'},
    );
    expect(evaluationCommandCatalog['game.new']?.probeOnly, isFalse);
    expect(
      evaluationCommandCatalog['movement.enterGameplayZone']?.requiredKeys,
      <String>{'zoneId'},
    );
    expect(
      evaluationCommandCatalog['world.enterTrigger']?.optionalKeys,
      <String>{'expectBattle'},
    );
    expect(
      evaluationCommandCatalog['battle.resolve']?.requiredKeys,
      <String>{'strategy'},
    );
    expect(evaluationCommandCatalog['probe.goto']?.probeOnly, isTrue);
  });

  test('rejects unknown root fields and commands', () {
    expect(
      () => parser.parseString(
        _scenarioWith(
          '{"id":"start","command":"game.new"}',
          extraRoot: '"shell":"rm -rf ."',
        ),
      ),
      throwsA(
        isA<EvaluationScenarioFormatException>().having(
          (error) => error.path,
          'path',
          r'$.shell',
        ),
      ),
    );
    expect(
      () => parser.parseString(
        _scenarioWith('{"id":"start","command":"process.exec"}'),
      ),
      throwsA(
        isA<EvaluationScenarioFormatException>().having(
          (error) => error.message,
          'message',
          contains('Unknown command'),
        ),
      ),
    );
  });

  test('rejects missing, unknown, and invalid command arguments', () {
    expect(
      () => parser.parseString(
        _scenarioWith(
          '{"id":"buy","command":"service.shop.buy","itemId":"potion"}',
        ),
      ),
      throwsA(
        isA<EvaluationScenarioFormatException>().having(
          (error) => error.message,
          'message',
          contains('quantity'),
        ),
      ),
    );
    expect(
      () => parser.parseString(
        _scenarioWith(
          '{"id":"new","command":"game.new","unexpected":true}',
        ),
      ),
      throwsA(
        isA<EvaluationScenarioFormatException>().having(
          (error) => error.path,
          'path',
          r'$.steps[0].unexpected',
        ),
      ),
    );
    expect(
      () => parser.parseString(
        _scenarioWith(
          '{"id":"wait","command":"world.waitForFact",'
          '"factId":"ready","timeoutMilliseconds":0}',
        ),
      ),
      throwsA(isA<EvaluationScenarioFormatException>()),
    );
  });

  test('rejects absolute strings and malformed assertion matchers', () {
    expect(
      () => parser.parseString(
        _scenarioWith(
          '{"id":"interact","command":"world.interact",'
          '"entityId":"/tmp/forbidden"}',
        ),
      ),
      throwsA(
        isA<EvaluationScenarioFormatException>().having(
          (error) => error.path,
          'path',
          r'$.steps[0].entityId',
        ),
      ),
    );
    expect(
      () => parser.parseString(
        _scenarioWith(
          '{"id":"money","assert":"state.money","approximately":750}',
        ),
      ),
      throwsA(
        isA<EvaluationScenarioFormatException>().having(
          (error) => error.message,
          'message',
          contains('matcher'),
        ),
      ),
    );
  });

  test('rejects duplicate ids and dangling criterion references', () {
    expect(
      () => parser.parseString(
        _scenarioWith(
          '{"id":"same","command":"game.new"},'
          '{"id":"same","command":"save.write"}',
        ),
      ),
      throwsA(isA<EvaluationScenarioFormatException>()),
    );
    expect(
      () => parser.parseString('''
      {
        "schemaVersion": 1,
        "id": "selbrume.criteria",
        "title": "Criteria",
        "projectId": "selbrume",
        "policy": "certify",
        "start": {"newGame": true},
        "criteria": [{"id": "missing", "stepIds": ["unknown"]}],
        "steps": [{"id": "start", "command": "game.new"}]
      }
      '''),
      throwsA(isA<EvaluationScenarioFormatException>()),
    );
  });
}

String _scenarioWith(String steps, {String? extraRoot}) {
  return '''
  {
    "schemaVersion": 1,
    "id": "selbrume.test",
    "title": "Test",
    "projectId": "selbrume",
    "policy": "probe",
    "start": {"newGame": true},
    "steps": [$steps]
    ${extraRoot == null ? '' : ',$extraRoot'}
  }
  ''';
}
