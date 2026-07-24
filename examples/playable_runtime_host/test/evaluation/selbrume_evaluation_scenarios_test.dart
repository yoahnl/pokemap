import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_state_snapshot.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_release_adapter.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_state_diff.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_scenario_parser.dart';

void main() {
  test('all committed Selbrume scenarios parse and declare unique IDs', () {
    final scenarios = _scenarioFiles()
        .map((file) => _parseScenario(file))
        .toList(growable: false);

    expect(scenarios, hasLength(4));
    expect(
      scenarios.map((scenario) => scenario.id).toSet(),
      hasLength(scenarios.length),
    );
  });

  test('targeted scenarios are self-contained diagnostic probes', () {
    final scenarios = _scenarioFiles()
        .where((file) => !file.path.endsWith('mvp_certification.json'))
        .map((file) => _parseScenario(file));

    for (final scenario in scenarios) {
      expect(scenario.policy, EvaluationPolicy.probe);
      expect(scenario.start, isA<EvaluationNewGameStart>());
      expect(
        scenario.steps.whereType<EvaluationCommandStep>().map(
              (step) => step.operation,
            ),
        contains(startsWith('probe.')),
      );
    }
  });

  test('MVP certification starts from a new game without probe commands', () {
    final scenario = _loadScenario('mvp_certification.json');

    expect(scenario.id, 'selbrume.mvp');
    expect(scenario.policy, EvaluationPolicy.certify);
    expect(scenario.start, isA<EvaluationNewGameStart>());
    expect(
      scenario.steps.whereType<EvaluationCommandStep>().map(
            (step) => step.operation,
          ),
      everyElement(isNot(startsWith('probe.'))),
    );
  });

  test('MVP certification maps every release criterion to real steps', () {
    final scenario = _loadScenario('mvp_certification.json');
    final expectedIds =
        MvpProductCriterion.values.map((criterion) => criterion.id).toSet();

    expect(
      scenario.criteria.map((criterion) => criterion.id).toSet(),
      expectedIds,
    );
    expect(
      scenario.criteria.expand((criterion) => criterion.stepIds),
      everyElement(isIn(scenario.steps.map((step) => step.id))),
    );
  });

  test('release adapter rejects mismatched and incomplete receipts', () {
    const adapter = EvaluationReleaseAdapter();
    final receipt = _receipt(
      commit: 'commit-a',
      projectTreeHash: _digestA,
      criteria: <EvaluationProductCriterionResult>[
        EvaluationProductCriterionResult(
          id: 'MVP-01',
          summary: 'new game passed',
          passed: true,
        ),
      ],
      declaredCriterionIds: const <String>['MVP-01'],
    );

    expect(
      () => adapter.productCriteria(
        receipt,
        expectedCommit: 'commit-b',
        expectedProjectTreeHash: _digestA,
      ),
      throwsArgumentError,
    );
    expect(
      () => adapter.productCriteria(
        receipt,
        expectedCommit: 'commit-a',
        expectedProjectTreeHash: _digestA,
      ),
      throwsStateError,
    );
  });

  test('release adapter links one passed source per MVP criterion', () {
    const adapter = EvaluationReleaseAdapter();
    final criteria = <EvaluationProductCriterionResult>[
      for (final criterion in MvpProductCriterion.values)
        EvaluationProductCriterionResult(
          id: criterion.id,
          summary: '${criterion.id} passed',
          passed: true,
        ),
    ];
    final receipt = _receipt(
      commit: 'commit-a',
      projectTreeHash: _digestA,
      criteria: criteria,
      declaredCriterionIds: criteria.map((criterion) => criterion.id).toList(),
    );

    final evidence = adapter.productCriteria(
      receipt,
      expectedCommit: 'commit-a',
      expectedProjectTreeHash: _digestA,
    );

    expect(evidence, hasLength(MvpProductCriterion.values.length));
    expect(
      evidence.map((item) => item.criterion),
      orderedEquals(MvpProductCriterion.values),
    );
    expect(
      evidence.map((item) => item.source).toSet(),
      hasLength(MvpProductCriterion.values.length),
    );
    expect(
      evidence.map((item) => item.source),
      everyElement(startsWith('build/pokemap-eval/runs/run-mvp/receipt.json#')),
    );
    expect(
      jsonEncode(
        adapter
            .productCriteriaJson(
              receipt.toJson(),
              expectedCommit: 'commit-a',
              expectedProjectTreeHash: _digestA,
            )
            .map((item) => item.toJson())
            .toList(),
      ),
      jsonEncode(evidence.map((item) => item.toJson()).toList()),
    );
  });
}

const _digestA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

List<File> _scenarioFiles() {
  final directory = Directory('evaluation/scenarios/selbrume');
  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
  return files;
}

EvaluationScenario _loadScenario(String name) {
  return _parseScenario(File('evaluation/scenarios/selbrume/$name'));
}

EvaluationScenario _parseScenario(File file) {
  return const EvaluationScenarioParser().parseString(
    file.readAsStringSync(),
  );
}

EvaluationReceipt _receipt({
  required String commit,
  required String projectTreeHash,
  required List<EvaluationProductCriterionResult> criteria,
  required List<String> declaredCriterionIds,
}) {
  final snapshot = EvaluationStateSnapshot(
    projectId: 'selbrume',
    runId: 'run-mvp',
    mapId: 'map_bourg_selbrume',
    x: 0,
    y: 0,
    movementMode: 'walk',
    money: 0,
  );
  return EvaluationReceipt.validated(
    runId: 'run-mvp',
    projectId: 'selbrume',
    scenarioId: 'selbrume.mvp',
    scenarioVersion: 1,
    policy: EvaluationPolicy.certify,
    target: EvaluationTarget.headless,
    evidenceLevel: EvaluationEvidenceLevel.releaseEvidence,
    commit: commit,
    projectTreeHash: projectTreeHash,
    commandDigest: _digestA,
    outputDigest: _digestA,
    startedAt: DateTime.utc(2026, 7, 24),
    finishedAt: DateTime.utc(2026, 7, 24, 0, 1),
    duration: const Duration(minutes: 1),
    status: EvaluationRunStatus.succeeded,
    exitCode: 0,
    initialState: snapshot,
    finalState: snapshot,
    diff: EvaluationStateDiff(const <EvaluationStateChange>[]),
    stepResults: const <EvaluationStepResult>[],
    shortcutsUsed: const <String>[],
    artifacts: const <String>['events.jsonl'],
    relativeReceiptPath: 'build/pokemap-eval/runs/run-mvp/receipt.json',
    declaredCriterionIds: declaredCriterionIds,
    productCriteria: criteria,
  );
}
