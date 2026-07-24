import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'evaluation_worker_protocol.dart';

const pokeMapEvalRequestEnvironmentKey = 'POKEMAP_EVAL_REQUEST';
const pokeMapEvalHostRootEnvironmentKey = 'POKEMAP_EVAL_HOST_ROOT';
const evaluationWorkerResultFileName = 'worker-result.json';

typedef WorkerStderrSink = void Function(String chunk);

final class HeadlessWorkerProcess {
  HeadlessWorkerProcess({
    this.flutterExecutable = 'flutter',
    Directory? hostRoot,
    Directory? packageRoot,
    WorkerStderrSink? stderrSink,
  })  : hostRoot = hostRoot ?? _discoverHostRoot(),
        packageRoot = packageRoot ??
            Directory(
              p.join(
                (hostRoot ?? _discoverHostRoot()).path,
                'examples',
                'playable_runtime_host',
              ),
            ),
        stderrSink = stderrSink ?? stderr.write;

  final String flutterExecutable;
  final Directory hostRoot;
  final Directory packageRoot;
  final WorkerStderrSink stderrSink;

  Future<EvaluationWorkerResult> run(
    EvaluationWorkerRequest request,
  ) async {
    final outputDirectory = Directory(
      p.join(hostRoot.path, request.outputDirectory),
    );
    final requestFile = File(
      p.join(outputDirectory.path, 'worker-request.json'),
    );
    final resultFile = File(
      p.join(outputDirectory.path, evaluationWorkerResultFileName),
    );
    try {
      await outputDirectory.create(recursive: true);
      if (await resultFile.exists()) await resultFile.delete();
      await _writeJsonAtomically(requestFile, request.toJson());

      final process = await Process.start(
        flutterExecutable,
        const <String>[
          'test',
          '--reporter',
          'compact',
          'test/evaluation/pokemap_eval_headless_worker_test.dart',
          '--plain-name',
          'PokeMap Eval headless worker',
        ],
        workingDirectory: packageRoot.path,
        environment: <String, String>{
          ...Platform.environment,
          pokeMapEvalRequestEnvironmentKey: requestFile.absolute.path,
          pokeMapEvalHostRootEnvironmentKey: hostRoot.absolute.path,
        },
        runInShell: false,
      );
      final stdoutDone = process.stdout.drain<void>();
      final stderrDone =
          process.stderr.transform(utf8.decoder).forEach(stderrSink);
      final processExitCode = await process.exitCode;
      await Future.wait<void>(<Future<void>>[stdoutDone, stderrDone]);

      if (!await resultFile.exists()) {
        return EvaluationWorkerResult.infrastructureFailure(
          runId: request.runId,
          message: 'Headless Flutter worker exited with code '
              '$processExitCode without a result envelope.',
        );
      }
      final decoded = jsonDecode(await resultFile.readAsString());
      if (decoded is! Map) {
        throw const FormatException('Worker result must be a JSON object.');
      }
      final result = EvaluationWorkerResult.fromJson(
        Map<String, Object?>.from(decoded),
      );
      if (result.runId != request.runId) {
        return EvaluationWorkerResult.infrastructureFailure(
          runId: request.runId,
          message: 'Worker result runId does not match its request.',
        );
      }
      return result;
    } on ProcessException catch (failure) {
      return EvaluationWorkerResult.infrastructureFailure(
        runId: request.runId,
        message: 'Unable to launch Flutter worker: ${failure.message}',
      );
    } on Object catch (failure) {
      return EvaluationWorkerResult.infrastructureFailure(
        runId: request.runId,
        message: 'Invalid Flutter worker result: $failure',
      );
    }
  }
}

Future<void> _writeJsonAtomically(
  File destination,
  Map<String, Object?> json,
) async {
  final temporary = File('${destination.path}.tmp');
  await temporary.writeAsString(jsonEncode(json), flush: true);
  if (await destination.exists()) await destination.delete();
  await temporary.rename(destination.path);
}

Directory _discoverHostRoot() {
  final current = Directory.current.absolute;
  if (File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
    return current;
  }
  return Directory(p.normalize(p.join(current.path, '..', '..')));
}
