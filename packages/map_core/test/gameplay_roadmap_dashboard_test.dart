import 'dart:io';

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

    test('keeps roadmap statuses authoritative over report proposals', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: roadmap,
        gameplayReports: const <String, String>{
          'reports/gameplay/fg_180_readiness.md': 'Proposed status: **DONE**\n',
          'reports/gameplay/fg_182_e2e.md': 'Proposed status: PARTIAL\n',
        },
      );

      expect(dashboard.entries, hasLength(3));
      expect(dashboard.entries[0].id, 'FG-180');
      expect(dashboard.entries[0].status, GameplayRoadmapStatus.todo);
      expect(dashboard.entries[1].status, GameplayRoadmapStatus.todo);
      expect(dashboard.entries[2].status, GameplayRoadmapStatus.partial);
      expect(dashboard.count(GameplayRoadmapStatus.done), 0);
      expect(dashboard.count(GameplayRoadmapStatus.partial), 1);
      expect(dashboard.count(GameplayRoadmapStatus.todo), 2);
      expect(
        dashboard.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          GameplayRoadmapDiagnosticCode.reportRoadmapStatusContradiction,
        ),
      );
      expect(dashboard.hasBlockingDiagnostics, isTrue);
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

    test('reports contradictions between explicit report proposals', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: roadmap,
        gameplayReports: const <String, String>{
          'reports/gameplay/fg_180_a.md': 'Proposed status: DONE',
          'reports/gameplay/fg_180_b.md': 'Proposed status: TODO',
        },
      );

      expect(dashboard.entries.first.status, GameplayRoadmapStatus.todo);
      expect(
        dashboard.diagnostics.map((diagnostic) => diagnostic.code),
        contains(GameplayRoadmapDiagnosticCode.conflictingReportStatuses),
      );
    });

    test('keeps BLOCKED distinct from PARTIAL in contradiction checks', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-185 | Release gate | `BLOCKED` | — |
''',
        gameplayReports: const <String, String>{
          'reports/gameplay/fg_185_gate.md': 'Proposed status: PARTIAL',
        },
      );

      expect(dashboard.entries.single.status, GameplayRoadmapStatus.blocked);
      expect(
        dashboard.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          GameplayRoadmapDiagnosticCode.reportRoadmapStatusContradiction,
        ),
      );
    });

    test('preserves DEFERRED as a canonical non-blocking lot status', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-200 | Double battles | `DEFERRED` | post-MVP |
''',
        gameplayReports: const <String, String>{},
      );

      expect(dashboard.entries.single.status, GameplayRoadmapStatus.deferred);
      expect(dashboard.count(GameplayRoadmapStatus.deferred), 1);
      expect(dashboard.markdown,
          contains('| FG-200 | Double battles | DEFERRED |'));
      expect(dashboard.diagnostics, isEmpty);
    });

    test('renders a deterministic Markdown status table', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: roadmap,
        gameplayReports: const <String, String>{
          'z/fg_180_z.md': 'Proposed status: DONE',
          'a/fg_180_a.md': 'Proposed status: DONE',
        },
      );

      expect(dashboard.markdown, contains('| FG-180 | Readiness | TODO | 2 |'));
      expect(dashboard.markdown,
          contains('| FG-181 | Golden Fixture | TODO | 0 |'));
      expect(dashboard.markdown.indexOf('FG-180'),
          lessThan(dashboard.markdown.indexOf('FG-181')));
      expect(
        dashboard.entries.first.evidencePaths,
        orderedEquals(<String>['a/fg_180_a.md', 'z/fg_180_z.md']),
      );
    });

    test('reports malformed FG candidate rows as blocking diagnostics', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '$roadmap\n| FG-X | broken | ??? |',
        gameplayReports: const <String, String>{},
      );

      expect(dashboard.entries.map((entry) => entry.id),
          orderedEquals(<String>['FG-180', 'FG-181', 'FG-182']));
      expect(
        dashboard.diagnostics.single.code,
        GameplayRoadmapDiagnosticCode.malformedCanonicalLotRow,
      );
      expect(dashboard.diagnostics.single.lineNumber, 7);
      expect(dashboard.hasBlockingDiagnostics, isTrue);
    });

    test('parses escaped pipes in valid Markdown table cells', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: r'''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-022 | Party \| PC storage | `DONE` | report |
''',
        gameplayReports: const <String, String>{},
      );

      expect(dashboard.entries.single.title, 'Party | PC storage');
      expect(dashboard.entries.single.status, GameplayRoadmapStatus.done);
      expect(dashboard.diagnostics, isEmpty);
    });

    test('rejects ambiguous or decorated canonical status text', () {
      for (final invalidStatus in const <String>[
        'BLOCKED/PARTIAL',
        'NOT DONE',
        'TODO-ish',
      ]) {
        final dashboard = GameplayRoadmapDashboard.build(
          roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-185 | Release gate | `$invalidStatus` | — |
''',
          gameplayReports: const <String, String>{},
        );

        expect(
          dashboard.diagnostics.single.code,
          GameplayRoadmapDiagnosticCode.malformedCanonicalLotRow,
          reason: invalidStatus,
        );
      }
    });

    test('reports duplicate canonical lot identifiers', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-024 | Capture | `✅ DONE` | report |
| FG-024 | Capture duplicate | `⬜ TODO` | — |
''',
        gameplayReports: const <String, String>{},
      );

      expect(dashboard.entries.map((entry) => entry.id), <String>['FG-024']);
      expect(
        dashboard.diagnostics.single.code,
        GameplayRoadmapDiagnosticCode.duplicateCanonicalLotId,
      );
      expect(dashboard.diagnostics.single.lotId, 'FG-024');
      expect(dashboard.hasBlockingDiagnostics, isTrue);
    });

    test('ignores FG candidate rows inside fenced code blocks', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-024 | Capture | `✅ DONE` | report |

```md
| FG-024 | Example duplicate | `⬜ TODO` | — |
| FG-X | malformed example | ??? | — |
```
''',
        gameplayReports: const <String, String>{},
      );

      expect(dashboard.entries.map((entry) => entry.id), <String>['FG-024']);
      expect(dashboard.diagnostics, isEmpty);
      expect(dashboard.hasBlockingDiagnostics, isFalse);
    });

    test('CLI rejects unknown options with a usage error', () async {
      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/generate_gameplay_roadmap_dashboard.dart',
          '--unknown',
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 64);
      expect(
        result.stderr,
        contains(
          'Usage: dart run tool/generate_gameplay_roadmap_dashboard.dart '
          '[--check] [repository-root]',
        ),
      );
    });

    test('CLI preserves dashboard generation without check mode', () async {
      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>['run', 'tool/generate_gameplay_roadmap_dashboard.dart'],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0);
      expect(result.stdout, contains('# Gameplay Roadmap Dashboard'));
      expect(result.stderr, isEmpty);
    });

    test('CLI exits nonzero when a blocking diagnostic is found', () async {
      final temporaryRoot =
          await Directory.systemTemp.createTemp('pokemap_dashboard_check_');
      addTearDown(() => temporaryRoot.delete(recursive: true));
      await Directory(
        '${temporaryRoot.path}${Platform.pathSeparator}reports'
        '${Platform.pathSeparator}gameplay',
      ).create(recursive: true);
      await File(
        '${temporaryRoot.path}${Platform.pathSeparator}'
        'pokemap_roadmap_mecaniques_fangame.md',
      ).writeAsString('''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `⬜ TODO` | — |
| FG-180 | Duplicate | `✅ DONE` | report |
''');
      await File(
        '${temporaryRoot.path}${Platform.pathSeparator}reports'
        '${Platform.pathSeparator}gameplay${Platform.pathSeparator}'
        'fg_180_readiness.md',
      ).writeAsString('Proposed status: **DONE**\n');

      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/generate_gameplay_roadmap_dashboard.dart',
          '--check',
          temporaryRoot.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 1);
      expect(result.stderr, contains('duplicateCanonicalLotId'));
      expect(result.stderr, contains('reportRoadmapStatusContradiction'));
    });
  });
}
