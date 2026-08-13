import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('repository roadmap has unique coherent canonical gameplay lots',
      () async {
    final roadmapFile = File('../../pokemap_roadmap_mecaniques_fangame.md');
    final reportsDirectory = Directory('../../documentation/reports/gameplay');
    final reports = <String, String>{};
    await for (final entity in reportsDirectory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
        continue;
      }
      final relativePath = entity.path
          .substring(reportsDirectory.path.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
      reports['documentation/reports/gameplay/$relativePath'] =
          await entity.readAsString();
    }

    final dashboard = GameplayRoadmapDashboard.build(
      roadmapMarkdown: await roadmapFile.readAsString(),
      gameplayReports: reports,
    );
    final ids = dashboard.entries.map((entry) => entry.id).toList();

    expect(dashboard.diagnostics, isEmpty);
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.where((id) => id == 'FG-024'), hasLength(1));
  });
}
