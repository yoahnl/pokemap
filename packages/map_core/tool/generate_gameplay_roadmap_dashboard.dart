import 'dart:io';

import 'package:map_core/map_core.dart';

const _usage = 'Usage: dart run tool/generate_gameplay_roadmap_dashboard.dart '
    '[--check] [--candidate-sha SHA] [--require-fresh-evidence] '
    '[--evidence-directory PATH] '
    '[repository-root]';

Future<void> main(List<String> arguments) async {
  var check = false;
  var requireFreshEvidence = false;
  String? candidateSha;
  String? evidenceDirectoryArgument;
  String? repositoryRootArgument;
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--check' && !check) {
      check = true;
      continue;
    }
    if (argument == '--require-fresh-evidence' && !requireFreshEvidence) {
      requireFreshEvidence = true;
      continue;
    }
    if (argument == '--candidate-sha' && candidateSha == null) {
      if (index + 1 >= arguments.length) {
        stderr.writeln(_usage);
        exitCode = 64;
        return;
      }
      candidateSha = arguments[++index].trim();
      if (candidateSha.isEmpty || candidateSha.startsWith('-')) {
        stderr.writeln(_usage);
        exitCode = 64;
        return;
      }
      continue;
    }
    if (argument == '--evidence-directory' &&
        evidenceDirectoryArgument == null) {
      if (index + 1 >= arguments.length) {
        stderr.writeln(_usage);
        exitCode = 64;
        return;
      }
      evidenceDirectoryArgument = arguments[++index].trim();
      if (evidenceDirectoryArgument.isEmpty ||
          evidenceDirectoryArgument.startsWith('-')) {
        stderr.writeln(_usage);
        exitCode = 64;
        return;
      }
      continue;
    }
    if (argument.startsWith('-') || repositoryRootArgument != null) {
      stderr.writeln(_usage);
      exitCode = 64;
      return;
    }
    repositoryRootArgument = argument;
  }
  if (arguments.where((argument) => argument == '--check').length > 1) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }
  if (requireFreshEvidence && candidateSha == null) {
    stderr.writeln(
      '--require-fresh-evidence needs an explicit --candidate-sha.',
    );
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  final repoRoot = repositoryRootArgument == null
      ? File.fromUri(Platform.script).parent.parent.parent.parent.absolute.path
      : Directory(repositoryRootArgument).absolute.path;
  final roadmapFile = File(
    '$repoRoot${Platform.pathSeparator}'
    'pokemap_roadmap_mecaniques_fangame.md',
  );
  final reportsDirectory = Directory(
    '$repoRoot${Platform.pathSeparator}'
    'documentation${Platform.pathSeparator}'
    'reports${Platform.pathSeparator}gameplay',
  );

  if (!await roadmapFile.exists()) {
    stderr.writeln('Roadmap not found: ${roadmapFile.path}');
    exitCode = 2;
    return;
  }
  if (!await reportsDirectory.exists()) {
    stderr.writeln(
      'Gameplay reports directory not found: ${reportsDirectory.path}',
    );
    exitCode = 2;
    return;
  }

  final reports = <String, String>{};
  final receipts = <String, String>{};
  await for (final entity in reportsDirectory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
      if (entity is File &&
          entity.path.toLowerCase().endsWith('.fg-evidence.json')) {
        receipts[_relativePath(repoRoot, entity.path)] =
            await entity.readAsString();
      }
    } else {
      reports[_relativePath(repoRoot, entity.path)] =
          await entity.readAsString();
    }
  }
  if (evidenceDirectoryArgument != null) {
    final externalEvidenceDirectory =
        Directory(evidenceDirectoryArgument).absolute;
    if (!await externalEvidenceDirectory.exists()) {
      stderr.writeln(
        'Evidence directory not found: ${externalEvidenceDirectory.path}',
      );
      exitCode = 2;
      return;
    }
    await for (final entity in externalEvidenceDirectory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File ||
          !entity.path.toLowerCase().endsWith('.fg-evidence.json')) {
        continue;
      }
      receipts['external:${_relativePath(
        externalEvidenceDirectory.path,
        entity.path,
      )}'] = await entity.readAsString();
    }
  }
  final dashboard = GameplayRoadmapDashboard.build(
    roadmapMarkdown: await roadmapFile.readAsString(),
    gameplayReports: reports,
    structuredEvidenceReceipts: receipts,
    candidateSha: candidateSha,
    requireFreshEvidence: requireFreshEvidence,
  );
  stdout.writeln(dashboard.markdown);

  if (dashboard.hasBlockingDiagnostics) {
    if (check) exitCode = 1;
  }
  for (final diagnostic in dashboard.diagnostics) {
    stderr.writeln(
      '${diagnostic.severity.name}: '
      '${diagnostic.code.name}: ${diagnostic.message}',
    );
  }
}

String _relativePath(String root, String path) {
  final normalizedRoot = Directory(root).absolute.path;
  final normalizedPath = File(path).absolute.path;
  if (!normalizedPath.startsWith('$normalizedRoot${Platform.pathSeparator}')) {
    return normalizedPath;
  }
  return normalizedPath
      .substring(normalizedRoot.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}
