import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_event.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_state_snapshot.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_state_diff.dart';

void main() {
  group('EvaluationStateSnapshot', () {
    test('digest ignores map insertion order and run id', () {
      final left = _snapshot(
        runId: 'run-left',
        facts: <String, Object?>{'b': true, 'a': false},
        bag: <String, int>{'potion': 1, 'antidote': 2},
      );
      final right = _snapshot(
        runId: 'run-right',
        facts: <String, Object?>{'a': false, 'b': true},
        bag: <String, int>{'antidote': 2, 'potion': 1},
      );

      expect(left.canonicalJson, right.canonicalJson);
      expect(left.digestSha256, right.digestSha256);
      expect(left.toJson()['runId'], 'run-left');
    });

    test('copies nested state collections defensively', () {
      final facts = <String, Object?>{
        'quest': <String, Object?>{'started': true},
      };
      final snapshot = _snapshot(facts: facts);

      (facts['quest']! as Map<String, Object?>)['started'] = false;

      expect(
        (snapshot.facts['quest']! as Map<String, Object?>)['started'],
        isTrue,
      );
      expect(
        () => (snapshot.facts['quest']! as Map<String, Object?>)['started'] =
            false,
        throwsUnsupportedError,
      );
    });
  });

  group('EvaluationStateDiffer', () {
    test('identifies added, removed, and changed paths in stable order', () {
      final diff = const EvaluationStateDiffer().compare(
        _snapshot(
          money: 1000,
          bag: <String, int>{'potion': 0, 'antidote': 1},
        ),
        _snapshot(
          money: 750,
          bag: <String, int>{'potion': 1, 'poke-ball': 5},
        ),
      );

      expect(diff.changeAt('trainer.money')?.before, 1000);
      expect(diff.changeAt('trainer.money')?.after, 750);
      expect(diff.changeAt('bag.potion')?.kind, EvaluationChangeKind.changed);
      expect(diff.changeAt('bag.antidote')?.kind, EvaluationChangeKind.removed);
      expect(diff.changeAt('bag.poke-ball')?.kind, EvaluationChangeKind.added);
      expect(
        diff.changes.map((change) => change.path),
        orderedEquals(
          diff.changes.map((change) => change.path).toList()..sort(),
        ),
      );
    });

    test('only retains unchanged values when explicitly requested', () {
      final withoutUnchanged = const EvaluationStateDiffer().compare(
        _snapshot(money: 1000),
        _snapshot(money: 1000),
      );
      final withUnchanged =
          const EvaluationStateDiffer(includeUnchanged: true).compare(
        _snapshot(money: 1000),
        _snapshot(money: 1000),
      );

      expect(withoutUnchanged.changeAt('trainer.money'), isNull);
      expect(
        withUnchanged.changeAt('trainer.money')?.kind,
        EvaluationChangeKind.unchanged,
      );
    });
  });

  group('EvaluationEvent', () {
    test('serializes the schema and freezes nested payload values', () {
      final payload = <String, Object?>{
        'state': <String, Object?>{'money': 1000},
      };
      final event = EvaluationEvent(
        runId: 'run-001',
        sequence: 1,
        type: 'run.started',
        payload: payload,
      );

      (payload['state']! as Map<String, Object?>)['money'] = 0;

      expect(event.toJson()['schemaVersion'], 1);
      expect(
        (event.payload['state']! as Map<String, Object?>)['money'],
        1000,
      );
      expect(
        () => (event.payload['state']! as Map<String, Object?>)['money'] = 0,
        throwsUnsupportedError,
      );
    });

    test('rejects invalid sequence numbers', () {
      expect(
        () => EvaluationEvent(
          runId: 'run-001',
          sequence: 0,
          type: 'run.started',
          payload: const <String, Object?>{},
        ),
        throwsArgumentError,
      );
    });
  });

  group('EvaluationReceipt', () {
    test('rejects absolute and escaping artifact paths', () {
      expect(
        () => _receipt(artifacts: <String>['/tmp/capture.png']),
        throwsArgumentError,
      );
      expect(
        () => _receipt(artifacts: <String>['../capture.png']),
        throwsArgumentError,
      );
    });

    test('rejects invalid hashes, duration, and status exit-code pairs', () {
      expect(
        () => _receipt(projectTreeHash: 'not-a-hash'),
        throwsArgumentError,
      );
      expect(
        () => _receipt(duration: const Duration(milliseconds: -1)),
        throwsArgumentError,
      );
      expect(
        () => _receipt(
          status: EvaluationRunStatus.failed,
          exitCode: 0,
          evidenceLevel: EvaluationEvidenceLevel.diagnosticOnly,
        ),
        throwsArgumentError,
      );
    });

    test('requires ordered steps and complete passing release criteria', () {
      expect(
        () => _receipt(
          stepResults: <EvaluationStepResult>[
            EvaluationStepResult(
              index: 1,
              stepId: 'second',
              passed: true,
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => _receipt(
          evidenceLevel: EvaluationEvidenceLevel.releaseEvidence,
          productCriteria: <EvaluationProductCriterionResult>[
            EvaluationProductCriterionResult(
              id: 'new-game',
              summary: 'New game starts.',
              passed: false,
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => _receipt(
          evidenceLevel: EvaluationEvidenceLevel.releaseEvidence,
          declaredCriterionIds: <String>['new-game', 'save-reload'],
          productCriteria: <EvaluationProductCriterionResult>[
            EvaluationProductCriterionResult(
              id: 'new-game',
              summary: 'New game starts.',
              passed: true,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('exposes successful criteria and portable JSON', () {
      final receipt = _receipt(
        evidenceLevel: EvaluationEvidenceLevel.releaseEvidence,
        productCriteria: <EvaluationProductCriterionResult>[
          EvaluationProductCriterionResult(
            id: 'new-game',
            summary: 'New game starts.',
            passed: true,
          ),
        ],
        artifacts: <String>['artifacts/start.png'],
      );

      expect(receipt.isSuccessful, isTrue);
      expect(receipt.passedProductCriteria.single.id, 'new-game');
      expect(receipt.toJson()['relativeReceiptPath'], 'receipt.json');
      expect(receipt.toJson()['artifacts'], <String>['artifacts/start.png']);
    });

    test('round-trips timestamps with sub-millisecond precision', () {
      final json = _receipt().toJson()
        ..['startedAt'] = '2026-07-24T08:00:00.000123Z'
        ..['finishedAt'] = '2026-07-24T08:00:01.000999Z'
        ..['durationMilliseconds'] = 1000;

      final receipt = EvaluationReceipt.fromJson(json);

      expect(receipt.duration, const Duration(microseconds: 1000876));
      expect(receipt.toJson()['durationMilliseconds'], 1000);
    });
  });
}

EvaluationStateSnapshot _snapshot({
  String runId = 'run-001',
  int money = 1000,
  Map<String, Object?> facts = const <String, Object?>{},
  Map<String, int> bag = const <String, int>{},
}) {
  return EvaluationStateSnapshot(
    projectId: 'selbrume',
    runId: runId,
    mapId: 'map_port_brisants',
    x: 12,
    y: 8,
    movementMode: 'walk',
    facts: facts,
    money: money,
    bag: bag,
  );
}

EvaluationReceipt _receipt({
  String projectTreeHash = _hashA,
  Duration duration = const Duration(seconds: 1),
  EvaluationRunStatus status = EvaluationRunStatus.succeeded,
  int exitCode = 0,
  EvaluationEvidenceLevel evidenceLevel =
      EvaluationEvidenceLevel.segmentEvidence,
  List<EvaluationStepResult> stepResults = const <EvaluationStepResult>[],
  List<EvaluationProductCriterionResult> productCriteria =
      const <EvaluationProductCriterionResult>[],
  List<String>? declaredCriterionIds,
  List<String> artifacts = const <String>[],
}) {
  final initial = _snapshot(money: 1000);
  final finalState = _snapshot(money: 750);
  return EvaluationReceipt.validated(
    runId: 'run-001',
    projectId: 'selbrume',
    scenarioId: 'selbrume.shop',
    scenarioVersion: 1,
    policy: EvaluationPolicy.certify,
    target: EvaluationTarget.headless,
    evidenceLevel: evidenceLevel,
    commit: '3c4b2b97',
    projectTreeHash: projectTreeHash,
    commandDigest: _hashB,
    outputDigest: _hashC,
    startedAt: DateTime.utc(2026, 7, 24, 8),
    finishedAt: DateTime.utc(2026, 7, 24, 8, 0, 1),
    duration: duration,
    status: status,
    exitCode: exitCode,
    initialState: initial,
    finalState: finalState,
    diff: const EvaluationStateDiffer().compare(initial, finalState),
    stepResults: stepResults,
    shortcutsUsed: const <String>[],
    artifacts: artifacts,
    relativeReceiptPath: 'receipt.json',
    declaredCriterionIds: declaredCriterionIds ??
        productCriteria.map((criterion) => criterion.id).toList(),
    productCriteria: productCriteria,
  );
}

const _hashA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _hashB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _hashC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
