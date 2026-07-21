import 'dart:io';

import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  final repoRoot = arguments.isEmpty
      ? File.fromUri(Platform.script).parent.parent.parent.parent.absolute.path
      : Directory(arguments.single).absolute.path;
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
        'Gameplay reports directory not found: ${reportsDirectory.path}');
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
}
