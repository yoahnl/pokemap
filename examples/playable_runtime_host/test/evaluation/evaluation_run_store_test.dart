import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_event.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_state_snapshot.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_state_diff.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_run_store.dart';

void main() {
  late Directory historyRoot;
  late EvaluationRunStore store;

  setUp(() async {
    historyRoot = await Directory.systemTemp.createTemp('pokemap-eval-store-');
    store = EvaluationRunStore(historyRoot: historyRoot);
  });

  tearDown(() async {
    await store.close();
    if (historyRoot.existsSync()) {
      await historyRoot.delete(recursive: true);
    }
  });

  test('store publishes ordered events to run subscribers', () async {
    final observed = <EvaluationEvent>[];
    final subscription = store.eventsFor('run-001').listen(observed.add);
    addTearDown(subscription.cancel);

    store.create(_descriptor('run-001'));
    store.append(_event('run-001', sequence: 1, type: 'run.started'));
    store.append(_event('run-001', sequence: 2, type: 'step.started'));
    await pumpEventQueue();

    expect(observed.map((item) => item.sequence), <int>[1, 2]);
    expect(store.requireRun('run-001').events, hasLength(2));
    expect(
      () => store.requireRun('run-001').events.add(
            _event('run-001', sequence: 3, type: 'step.completed'),
          ),
      throwsUnsupportedError,
    );
  });

  test('store rejects non-contiguous event sequences', () {
    store.create(_descriptor('run-001'));

    expect(
      () => store.append(
        _event('run-001', sequence: 2, type: 'step.started'),
      ),
      throwsStateError,
    );
  });

  test('run.finished derives the terminal lifecycle from its status', () {
    store.create(_descriptor('run-success'));
    store.append(
      EvaluationEvent(
        runId: 'run-success',
        sequence: 1,
        type: 'run.finished',
        payload: const <String, Object?>{'status': 'succeeded'},
      ),
    );

    expect(
      store.requireRun('run-success').lifecycle,
      EvaluationRunLifecycle.succeeded,
    );
  });

  test('history loads only validated portable receipt paths', () async {
    await _writeReceipt(
      historyRoot,
      directoryRunId: 'run-valid',
      receipt: _receipt('run-valid'),
    );
    await _writeReceipt(
      historyRoot,
      directoryRunId: 'run-escaping',
      receipt: _receipt('run-escaping'),
      mutate: (json) => json['relativeReceiptPath'] = '../receipt.json',
    );
    final malformed = File(
      p.join(historyRoot.path, 'runs', 'run-malformed', 'receipt.json'),
    );
    await malformed.parent.create(recursive: true);
    await malformed.writeAsString('{broken');
    await File(
      p.join(historyRoot.path, 'runs', 'run-valid', 'receipt.json.tmp'),
    ).writeAsString('{}');

    final history = await store.loadHistory();

    expect(history.map((item) => item.runId), <String>['run-valid']);
    expect(history.single.receiptPath, 'runs/run-valid/receipt.json');
    expect(history.single.receipt.scenarioId, 'selbrume.shop.after-lysa');
    expect(store.invalidHistoryEntryCount, 2);
  });
}

EvaluationRunDescriptor _descriptor(String runId) {
  return EvaluationRunDescriptor(
    runId: runId,
    projectId: 'selbrume',
    scenarioId: 'selbrume.shop.after-lysa',
    policy: EvaluationPolicy.probe,
    target: EvaluationTarget.headless,
    createdAt: DateTime.utc(2026, 7, 24, 10),
  );
}

EvaluationEvent _event(
  String runId, {
  required int sequence,
  required String type,
}) {
  return EvaluationEvent(
    runId: runId,
    sequence: sequence,
    type: type,
    payload: const <String, Object?>{},
  );
}

Future<void> _writeReceipt(
  Directory historyRoot, {
  required String directoryRunId,
  required EvaluationReceipt receipt,
  void Function(Map<String, Object?> json)? mutate,
}) async {
  final file = File(
    p.join(historyRoot.path, 'runs', directoryRunId, 'receipt.json'),
  );
  await file.parent.create(recursive: true);
  final json = receipt.toJson();
  mutate?.call(json);
  await file.writeAsString(jsonEncode(json));
}

EvaluationReceipt _receipt(String runId) {
  final initial = _snapshot(runId: runId, money: 1000);
  final finalState = _snapshot(runId: runId, money: 800);
  return EvaluationReceipt.validated(
    runId: runId,
    projectId: 'selbrume',
    scenarioId: 'selbrume.shop.after-lysa',
    scenarioVersion: 1,
    policy: EvaluationPolicy.probe,
    target: EvaluationTarget.headless,
    evidenceLevel: EvaluationEvidenceLevel.diagnosticOnly,
    commit: '015268d7',
    projectTreeHash: _hashA,
    commandDigest: _hashB,
    outputDigest: _hashC,
    startedAt: DateTime.utc(2026, 7, 24, 10),
    finishedAt: DateTime.utc(2026, 7, 24, 10, 0, 1),
    duration: const Duration(seconds: 1),
    status: EvaluationRunStatus.succeeded,
    exitCode: 0,
    initialState: initial,
    finalState: finalState,
    diff: const EvaluationStateDiffer().compare(initial, finalState),
    stepResults: <EvaluationStepResult>[
      EvaluationStepResult(
        index: 0,
        stepId: 'new-game',
        passed: true,
      ),
    ],
    shortcutsUsed: const <String>['probe.checkpoint'],
    artifacts: const <String>['events.jsonl'],
    relativeReceiptPath: 'receipt.json',
    declaredCriterionIds: const <String>[],
    productCriteria: const <EvaluationProductCriterionResult>[],
  );
}

EvaluationStateSnapshot _snapshot({
  required String runId,
  required int money,
}) {
  return EvaluationStateSnapshot(
    projectId: 'selbrume',
    runId: runId,
    mapId: 'map_port_brisants',
    x: 12,
    y: 8,
    movementMode: 'walk',
    facts: const <String, Object?>{'rival_defeated': true},
    money: money,
    badges: const <String>['badge-brume'],
    bag: const <String, int>{'potion': 2},
    party: const <Map<String, Object?>>[
      <String, Object?>{'species': 'grenousse', 'level': 8},
    ],
  );
}

const _hashA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _hashB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _hashC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
