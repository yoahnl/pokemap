import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_headless_worker.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';
import 'package:pokemap_loader/src/evaluation/worker/headless_worker_process.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final requestPath = Platform.environment[pokeMapEvalRequestEnvironmentKey];
  test(
    'PokeMap Eval headless worker',
    () async {
      final request = EvaluationWorkerRequest.fromJson(
        jsonDecode(await File(requestPath!).readAsString())
            as Map<String, Object?>,
      );
      await runHeadlessEvaluationRequest(request);
    },
    skip: requestPath == null
        ? 'Worker entry is launched by PokeMap Eval.'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
