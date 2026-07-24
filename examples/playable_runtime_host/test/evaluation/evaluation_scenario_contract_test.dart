import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';

void main() {
  group('EvaluationScenario', () {
    test('keeps policy and execution target independent', () {
      final scenario = EvaluationScenario(
        schemaVersion: 1,
        id: 'selbrume.smoke',
        title: 'Selbrume smoke',
        projectId: 'selbrume',
        policy: EvaluationPolicy.certify,
        start: const EvaluationStart.newGame(),
        steps: const <EvaluationStep>[],
      );

      expect(scenario.policy, EvaluationPolicy.certify);
      expect(EvaluationTarget.values, contains(EvaluationTarget.headless));
      expect(EvaluationTarget.values, contains(EvaluationTarget.interactive));
    });

    test('copies scenario and command collections defensively', () {
      final arguments = <String, Object?>{'entityId': 'npc_soline'};
      final steps = <EvaluationStep>[
        EvaluationCommandStep(
          id: 'open-shop',
          operation: 'world.interact',
          arguments: arguments,
        ),
      ];
      final criterionStepIds = <String>['open-shop'];
      final criteria = <EvaluationCriterionDefinition>[
        EvaluationCriterionDefinition(
          id: 'shop-opened',
          stepIds: criterionStepIds,
        ),
      ];
      final scenario = EvaluationScenario(
        schemaVersion: 1,
        id: 'selbrume.shop',
        title: 'Shop',
        projectId: 'selbrume',
        policy: EvaluationPolicy.probe,
        start: const EvaluationStart.newGame(),
        steps: steps,
        criteria: criteria,
      );

      arguments['entityId'] = 'changed';
      steps.clear();
      criterionStepIds.clear();
      criteria.clear();

      final command = scenario.steps.single as EvaluationCommandStep;
      expect(command.arguments, <String, Object?>{'entityId': 'npc_soline'});
      expect(scenario.criteria.single.stepIds, <String>['open-shop']);
      expect(
        () => command.arguments['entityId'] = 'changed-again',
        throwsUnsupportedError,
      );
      expect(
        () => scenario.steps.add(command),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid metadata and unsupported schema versions', () {
      EvaluationScenario build({
        int schemaVersion = 1,
        String id = 'selbrume.valid',
        String title = 'Valid',
        String projectId = 'selbrume',
      }) {
        return EvaluationScenario(
          schemaVersion: schemaVersion,
          id: id,
          title: title,
          projectId: projectId,
          policy: EvaluationPolicy.probe,
          start: const EvaluationStart.newGame(),
          steps: const <EvaluationStep>[],
        );
      }

      expect(() => build(schemaVersion: 2), throwsArgumentError);
      expect(() => build(id: '  '), throwsArgumentError);
      expect(() => build(title: ''), throwsArgumentError);
      expect(() => build(projectId: '\t'), throwsArgumentError);
    });

    test('rejects duplicate steps and dangling criterion references', () {
      final first = EvaluationCommandStep(
        id: 'same',
        operation: 'game.new',
        arguments: const <String, Object?>{},
      );
      final second = EvaluationCommandStep(
        id: 'same',
        operation: 'save.write',
        arguments: const <String, Object?>{},
      );

      expect(
        () => EvaluationScenario(
          schemaVersion: 1,
          id: 'selbrume.duplicates',
          title: 'Duplicates',
          projectId: 'selbrume',
          policy: EvaluationPolicy.probe,
          start: const EvaluationStart.newGame(),
          steps: <EvaluationStep>[first, second],
        ),
        throwsArgumentError,
      );
      expect(
        () => EvaluationScenario(
          schemaVersion: 1,
          id: 'selbrume.criteria',
          title: 'Criteria',
          projectId: 'selbrume',
          policy: EvaluationPolicy.certify,
          start: const EvaluationStart.newGame(),
          steps: <EvaluationStep>[first],
          criteria: <EvaluationCriterionDefinition>[
            EvaluationCriterionDefinition(
              id: 'missing-step',
              stepIds: <String>['unknown'],
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
