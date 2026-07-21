import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('GameplayRoadmapDashboard', () {
    const roadmap = '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `⬜ TODO` | — |
| FG-181 | Golden Fixture | `⬜ TODO` | — |
| FG-182 | Golden E2E | `🟨 PARTIAL` | old report |
''';

    test('combines roadmap lots with explicit report status proposals', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: roadmap,
        gameplayReports: const <String, String>{
          'reports/gameplay/fg_180_readiness.md': 'Proposed status: **DONE**\n',
          'reports/gameplay/fg_182_e2e.md': 'Proposed status: PARTIAL\n',
        },
      );

      expect(dashboard.entries, hasLength(3));
      expect(dashboard.entries[0].id, 'FG-180');
      expect(dashboard.entries[0].status, GameplayRoadmapStatus.done);
      expect(dashboard.entries[1].status, GameplayRoadmapStatus.todo);
      expect(dashboard.entries[2].status, GameplayRoadmapStatus.partial);
      expect(dashboard.count(GameplayRoadmapStatus.done), 1);
      expect(dashboard.count(GameplayRoadmapStatus.partial), 1);
      expect(dashboard.count(GameplayRoadmapStatus.todo), 1);
    });

    test('ignores reports without an explicit status proposal', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: roadmap,
        gameplayReports: const <String, String>{
          'reports/gameplay/fg_181_visual_note.md':
              '# FG-181 visual note\nEverything looks nice.\n',
        },
      );

      final entry =
          dashboard.entries.singleWhere((item) => item.id == 'FG-181');
      expect(entry.status, GameplayRoadmapStatus.todo);
      expect(entry.evidencePaths, hasLength(1));
    });

    test('fails closed to PARTIAL when explicit reports contradict each other',
        () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: roadmap,
        gameplayReports: const <String, String>{
          'reports/gameplay/fg_180_a.md': 'Proposed status: DONE',
          'reports/gameplay/fg_180_b.md': 'Proposed status: TODO',
        },
      );

      expect(dashboard.entries.first.status, GameplayRoadmapStatus.partial);
    });

    test('renders a deterministic Markdown status table', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: roadmap,
        gameplayReports: const <String, String>{
          'z/fg_180_z.md': 'Proposed status: DONE',
          'a/fg_180_a.md': 'Proposed status: DONE',
        },
      );

      expect(dashboard.markdown, contains('| FG-180 | Readiness | DONE | 2 |'));
      expect(dashboard.markdown,
          contains('| FG-181 | Golden Fixture | TODO | 0 |'));
      expect(dashboard.markdown.indexOf('FG-180'),
          lessThan(dashboard.markdown.indexOf('FG-181')));
      expect(
        dashboard.entries.first.evidencePaths,
        orderedEquals(<String>['a/fg_180_a.md', 'z/fg_180_z.md']),
      );
    });

    test('skips malformed rows without throwing', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '$roadmap\n| FG-X | broken | ??? |',
        gameplayReports: const <String, String>{},
      );

      expect(dashboard.entries.map((entry) => entry.id),
          orderedEquals(<String>['FG-180', 'FG-181', 'FG-182']));
    });
  });
}
