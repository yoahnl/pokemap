import 'dart:io';

import 'package:map_core/map_core.dart';

const _usage = 'Usage: dart run tool/generate_gameplay_roadmap_dashboard.dart '
    '[--check] [repository-root]';

Future<void> main(List<String> arguments) async {
  var check = false;
  String? repositoryRootArgument;
  for (final argument in arguments) {
    if (argument == '--check' && !check) {
      check = true;
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

  final repoRoot = repositoryRootArgument == null
      ? File.fromUri(Platform.script).parent.parent.parent.parent.absolute.path
      : Directory(repositoryRootArgument).absolute.path;
  final roadmapFile = File(
    '$repoRoot${Platform.pathSeparator}'
    'pokemap_roadmap_mecaniques_fangame.md',
  );
  final reportsDirectory = Directory(
    '$repoRoot${Platform.pathSeparator}reports${Platform.pathSeparator}gameplay',
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
  await for (final entity in reportsDirectory.list()) {
    if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
      continue;
    }
    reports[entity.path] = await entity.readAsString();
  }
  final dashboard = GameplayRoadmapDashboard.build(
    roadmapMarkdown: await roadmapFile.readAsString(),
    gameplayReports: reports,
  );
  stdout.writeln(dashboard.markdown);

  if (dashboard.hasBlockingDiagnostics) {
    for (final diagnostic in dashboard.diagnostics) {
      stderr.writeln('${diagnostic.code.name}: ${diagnostic.message}');
    }
    if (check) exitCode = 1;
  }
}
