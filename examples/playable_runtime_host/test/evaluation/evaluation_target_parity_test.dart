import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/interactive/interactive_worker_client.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';
import 'package:pokemap_loader/src/evaluation/worker/headless_worker_process.dart';

void main() {
  test(
    'Shop probe produces the same business diff on both targets',
    () async {
      final repositoryRoot = Directory(
        p.normalize(p.join(Directory.current.path, '..', '..')),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final headlessRunId = 'parity-headless-$suffix';
      final interactiveRunId = 'parity-interactive-$suffix';
      final headlessOutput = 'build/pokemap-eval/runs/$headlessRunId';
      final interactiveOutput = 'build/pokemap-eval/runs/$interactiveRunId';
      addTearDown(() async {
        for (final relative in <String>[headlessOutput, interactiveOutput]) {
          final directory = Directory(p.join(repositoryRoot.path, relative));
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
        }
      });

      final headless = await HeadlessWorkerProcess(
        hostRoot: repositoryRoot,
        stderrSink: (_) {},
      ).run(
        _request(
          runId: headlessRunId,
          outputDirectory: headlessOutput,
        ),
      );
      final interactive = await InteractiveWorkerClient(
        repositoryRoot: repositoryRoot,
        stderrSink: (_) {},
        readyTimeout: const Duration(minutes: 3),
      ).run(
        _request(
          runId: interactiveRunId,
          outputDirectory: interactiveOutput,
        ),
        playbackRate: 2,
      );

      expect(
        headless.status,
        EvaluationRunStatus.succeeded,
        reason: headless.message,
      );
      expect(
        interactive.status,
        EvaluationRunStatus.succeeded,
        reason: interactive.message,
      );
      final headlessReceipt = await _receipt(repositoryRoot, headless);
      final interactiveReceipt = await _receipt(repositoryRoot, interactive);

      expect(
        _businessChanges(interactiveReceipt),
        _businessChanges(headlessReceipt),
      );
    },
    skip: !Platform.isMacOS,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

EvaluationWorkerRequest _request({
  required String runId,
  required String outputDirectory,
}) {
  return EvaluationWorkerRequest.run(
    runId: runId,
    projectRoot: 'selbrume',
    scenarioPath:
        'examples/playable_runtime_host/evaluation/scenarios/selbrume/'
        'shop_after_lysa.json',
    outputDirectory: outputDirectory,
  );
}

Future<EvaluationReceipt> _receipt(
  Directory repositoryRoot,
  EvaluationWorkerResult result,
) async {
  final path = result.receiptPath;
  expect(path, isNotNull);
  return EvaluationReceipt.fromJson(
    Map<String, Object?>.from(
      jsonDecode(
        await File(p.join(repositoryRoot.path, path)).readAsString(),
      ) as Map,
    ),
  );
}

List<Map<String, Object?>> _businessChanges(EvaluationReceipt receipt) {
  const businessRoots = <String>{
    'facts',
    'eventLedger',
    'progression',
    'trainer',
    'bag',
    'shop',
    'party',
    'storage',
  };
  const volatilePaths = <String>{
    'eventLedger.appliedNarrativeResetTokens',
  };
  return receipt.diff.changes
      .where(
        (change) =>
            businessRoots.contains(change.path.split('.').first) &&
            !volatilePaths.contains(change.path),
      )
      .map((change) => change.toJson())
      .toList(growable: false);
}
