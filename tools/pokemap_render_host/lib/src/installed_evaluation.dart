import 'dart:io';

import 'package:pokemap_loader/evaluation.dart';

Future<Map<String, Object?>> evaluateInstalledRequest(
  Map<String, Object?> args,
) async {
  const enabled = bool.fromEnvironment('AVELUNE_RUNTIME_COMPANION');
  if (!enabled) {
    throw const FormatException('Installed evaluation is unavailable.');
  }
  if (args.keys.any(
        (key) => !{
          'workRoot',
          'request',
          'target',
          'playbackRate',
          'projectIdentity',
        }.contains(key),
      ) ||
      args['workRoot'] is! String ||
      args['request'] is! Map<String, Object?> ||
      !{'headless', 'interactive'}.contains(args['target'])) {
    throw const FormatException('Invalid installed evaluation request.');
  }
  final root = Directory(args['workRoot']! as String);
  if (!root.isAbsolute || await root.resolveSymbolicLinks() != root.path) {
    throw const FormatException('Invalid evaluation working root.');
  }
  final request = EvaluationWorkerRequest.fromJson(
    args['request']! as Map<String, Object?>,
  );
  final identity = args['projectIdentity'];
  if (identity is! String || identity.isEmpty || identity.length > 512) {
    throw const FormatException('Invalid evaluation project identity.');
  }
  final provenance = EvaluationBuildProvenance(
    commit: const String.fromEnvironment('AVELUNE_BUILD_COMMIT'),
    codeDigest: const String.fromEnvironment('AVELUNE_EVALUATION_CODE_DIGEST'),
  );
  final playbackRate = args['playbackRate'] ?? 1;
  if (playbackRate is! num ||
      !playbackRate.isFinite ||
      playbackRate <= 0 ||
      playbackRate > 4) {
    throw const FormatException('Invalid evaluation playback rate.');
  }
  final result = args['target'] == 'headless'
      ? await runHeadlessEvaluationRequest(
          request,
          hostRoot: root,
          buildProvenance: provenance,
          projectIdentity: identity,
        )
      : await InteractiveWorkerClient(
          repositoryRoot: root,
          packageRoot: root,
          processRunner: _InstalledInteractiveProcessRunner(identity),
          buildProvenance: provenance,
          stderrSink: (_) {},
        ).run(request, playbackRate: playbackRate.toDouble());
  return result.toJson();
}

final class _InstalledInteractiveProcessRunner
    implements InteractiveProcessRunner {
  const _InstalledInteractiveProcessRunner(this.projectIdentity);
  final String projectIdentity;

  @override
  Future<InteractiveChildProcess> start(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required bool runInShell,
  }) async {
    final environment = <String, String>{
      'AVELUNE_RUNTIME_MODE': 'interactive',
      'AVELUNE_OWNER_PID': '$pid',
      'AVELUNE_EVALUATION_PROJECT_ID': projectIdentity,
    };
    for (final argument in arguments) {
      if (argument.startsWith('--dart-define=POKEMAP_EVAL_')) {
        final value = argument.substring('--dart-define='.length);
        final separator = value.indexOf('=');
        environment[value.substring(0, separator)] = value.substring(
          separator + 1,
        );
      }
    }
    return _InstalledInteractiveChild(
      await Process.start(
        Platform.resolvedExecutable,
        const [],
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: false,
      ),
    );
  }
}

final class _InstalledInteractiveChild implements InteractiveChildProcess {
  _InstalledInteractiveChild(this.process);
  final Process process;
  @override
  int get pid => process.pid;
  @override
  Stream<List<int>> get stdout => process.stdout;
  @override
  Stream<List<int>> get stderr => process.stderr;
  @override
  Future<int> get exitCode => process.exitCode;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      process.kill(signal);
}
