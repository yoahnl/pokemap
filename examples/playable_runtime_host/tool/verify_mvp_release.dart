import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/runner/evaluation_release_adapter.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';
import 'package:pokemap_loader/src/evaluation/worker/headless_worker_process.dart';
import 'package:pokemap_loader/src/mvp_release_command_matrix.dart';
import 'package:pokemap_loader/src/mvp_release_evidence_collector.dart';
import 'package:pokemap_loader/src/project_tree_digest.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final hostRoot = Directory.current.absolute;
    final repositoryRoot = Directory(
      p.normalize(p.join(hostRoot.path, '..', '..')),
    );
    final projectFile = File(options.projectPath);
    if (!await projectFile.exists()) {
      throw ArgumentError.value(
        options.projectPath,
        '--project',
        'does not exist',
      );
    }
    final package = File(options.packagePath);
    if (!await package.exists()) {
      throw StateError(
        'Release package is missing: ${package.path}. '
        'Run tool/package_selbrume_macos.dart first.',
      );
    }
    await _requireCleanCandidate(repositoryRoot);
    final commit = await _gitHead(repositoryRoot);
    final projectRoot = projectFile.parent;
    final treeHash = await const ProjectTreeDigest().compute(projectRoot);
    final packageHash = await sha256.bind(package.openRead()).first;

    final evaluationRunId =
        'release-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final evaluationOutput = 'build/pokemap-eval/runs/$evaluationRunId';
    final evaluationResult = await HeadlessWorkerProcess(
      hostRoot: repositoryRoot,
      packageRoot: hostRoot,
      stderrSink: stderr.write,
    ).run(
      EvaluationWorkerRequest.run(
        runId: evaluationRunId,
        projectRoot: p
            .relative(projectRoot.path, from: repositoryRoot.path)
            .replaceAll(r'\', '/'),
        expectedProjectTreeHash: treeHash,
        scenarioPath:
            'examples/playable_runtime_host/evaluation/scenarios/selbrume/'
            'mvp_certification.json',
        outputDirectory: evaluationOutput,
      ),
    );
    if (evaluationResult.exitCode != 0 ||
        evaluationResult.receiptPath == null) {
      throw StateError(
        'The reusable Selbrume evaluation failed: '
        '${evaluationResult.message ?? evaluationResult.status.name}.',
      );
    }
    final evaluationReceipt = jsonDecode(
      await File(
        p.join(repositoryRoot.path, evaluationResult.receiptPath),
      ).readAsString(),
    ) as Map<String, dynamic>;
    final productCriteria =
        const EvaluationReleaseAdapter().productCriteriaJson(
      evaluationReceipt,
      expectedCommit: commit,
      expectedProjectTreeHash: treeHash,
    );

    final matrix = options.full
        ? MvpReleaseCommandMatrix.full(repositoryRoot.path)
        : MvpReleaseCommandMatrix.quick(repositoryRoot.path);
    final results = await matrix.execute(
      (command) async {
        stdout.writeln('release-gate: ${command.id}');
        return executeMvpReleaseCommand(
          command,
          stdoutSink: stdout,
          stderrSink: stderr,
        );
      },
    );
    final capturedAt = DateTime.now().toUtc();
    final artifacts = const MvpReleaseEvidenceCollector().collect(
      command: options.displayCommand,
      workingDirectory: hostRoot.path,
      releaseCandidateCommit: commit,
      capturedAtUtc: capturedAt,
      projectTreeHashSha256: treeHash,
      packageSha256: packageHash.toString(),
      productCriteria: productCriteria,
      commandResults: results,
    );
    final validation = const MvpReleaseEvidenceCollector().validate(
      receipt: artifacts.receipt,
      expectedReleaseCandidateCommit: commit,
      expectedProjectTreeHashSha256: treeHash,
      expectedPackageSha256: packageHash.toString(),
      nowUtc: capturedAt,
    );
    await _writeAtomically(File(options.outputPath), artifacts.json);
    await _writeAtomically(
      File('${p.withoutExtension(options.outputPath)}.md'),
      artifacts.markdown,
    );
    stdout.writeln(jsonEncode(artifacts.receipt.toJson()));
    if (!validation.isValid) {
      for (final issue in validation.issues) {
        stderr.writeln('release-gate: $issue');
      }
      exitCode = 1;
    }
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('MVP release verification failed: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  }
}

Future<String> _gitHead(Directory repositoryRoot) async {
  final result = await Process.run(
    'git',
    const ['rev-parse', 'HEAD'],
    workingDirectory: repositoryRoot.path,
  );
  if (result.exitCode != 0) {
    throw StateError('Unable to resolve release candidate commit.');
  }
  return (result.stdout as String).trim();
}

Future<void> _requireCleanCandidate(Directory repositoryRoot) async {
  final result = await Process.run(
    'git',
    const ['status', '--porcelain', '--untracked-files=all'],
    workingDirectory: repositoryRoot.path,
  );
  if (result.exitCode != 0) {
    throw StateError('Unable to inspect release candidate worktree.');
  }
  final changes = (result.stdout as String).trim();
  if (changes.isNotEmpty) {
    throw StateError(
      'Release candidate worktree is not clean. Commit code and project data '
      'before collecting evidence.',
    );
  }
}

Future<void> _writeAtomically(File target, String content) async {
  await target.parent.create(recursive: true);
  final temporary = File('${target.path}.tmp');
  await temporary.writeAsString(content, flush: true);
  if (await target.exists()) await target.delete();
  await temporary.rename(target.path);
}

final class _Options {
  const _Options({
    required this.projectPath,
    required this.packagePath,
    required this.outputPath,
    required this.full,
    required this.displayCommand,
  });

  final String projectPath;
  final String packagePath;
  final String outputPath;
  final bool full;
  final String displayCommand;

  static _Options parse(List<String> arguments) {
    var projectPath = p.join('..', '..', 'selbrume', 'project.json');
    var packagePath = p.join('build', 'mvp-release', 'selbrume-macos.zip');
    var outputPath = p.join('build', 'mvp-release', 'evidence.json');
    var full = false;
    for (var index = 0; index < arguments.length; index += 1) {
      final argument = arguments[index];
      switch (argument) {
        case '--project':
          projectPath = _value(arguments, ++index, argument);
        case '--package':
          packagePath = _value(arguments, ++index, argument);
        case '--output':
          outputPath = _value(arguments, ++index, argument);
        case '--full':
          full = true;
        case '--quick':
          full = false;
        default:
          throw ArgumentError('Unknown argument: $argument');
      }
    }
    return _Options(
      projectPath: p.normalize(p.absolute(projectPath)),
      packagePath: p.normalize(p.absolute(packagePath)),
      outputPath: p.normalize(p.absolute(outputPath)),
      full: full,
      displayCommand:
          'dart run tool/verify_mvp_release.dart ${arguments.map(_shellWord).join(' ')}'
              .trim(),
    );
  }
}

String _value(List<String> arguments, int index, String option) {
  if (index >= arguments.length) {
    throw ArgumentError('Missing value for $option');
  }
  return arguments[index];
}

String _shellWord(String value) {
  if (RegExp(r'^[A-Za-z0-9_./:=+-]+$').hasMatch(value)) return value;
  return "'${value.replaceAll("'", "'\"'\"'")}'";
}
