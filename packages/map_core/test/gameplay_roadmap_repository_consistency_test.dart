import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('repository roadmap has unique coherent canonical gameplay lots',
      () async {
    final roadmapFile = File('../../pokemap_roadmap_mecaniques_fangame.md');
    final reportsDirectory = Directory('../../reports/gameplay');
    final reports = <String, String>{};
    await for (final entity in reportsDirectory.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      reports['reports/gameplay/$name'] = await entity.readAsString();
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
