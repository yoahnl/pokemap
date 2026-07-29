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

      expect(
        dashboard.markdown,
        contains(
          '| FG-180 | Readiness | TODO | 2 | '
          'a/fg_180_a.md<br>z/fg_180_z.md | — | — | — | MISSING |',
        ),
      );
      expect(
        dashboard.markdown,
        contains(
          '| FG-181 | Golden Fixture | TODO | 0 | — | — | — | — | MISSING |',
        ),
      );
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

    test('one fresh structured receipt can prove several canonical lots', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `DONE` | receipt |
| FG-181 | Fixture | `PARTIAL` | receipt |
''',
        gameplayReports: const {},
        candidateSha: 'candidate-sha',
        requireFreshEvidence: true,
        structuredEvidenceReceipts: const {
          'reports/gameplay/evidence/phase0.fg-evidence.json': '''
{
  "schemaVersion": 1,
  "lotIds": ["FG-180", "FG-181"],
  "statusByLot": {"FG-180": "DONE", "FG-181": "PARTIAL"},
  "candidateSha": "candidate-sha",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {
      "command": "dart test",
      "exitCode": 0,
      "outputDigest": "sha256:green"
    }
  ],
  "sourcePaths": ["packages/map_core"]
}
''',
        },
      );

      expect(
        dashboard.entries.map((entry) => entry.evidenceState),
        everyElement(GameplayRoadmapEvidenceState.fresh),
      );
      expect(
        dashboard.entries.first.structuredEvidencePaths,
        ['reports/gameplay/evidence/phase0.fg-evidence.json'],
      );
      expect(dashboard.diagnostics, isEmpty);
    });

    test('stale SHA never proves a DONE lot and strict mode blocks it', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `DONE` | receipt |
''',
        gameplayReports: const {},
        candidateSha: 'new-sha',
        requireFreshEvidence: true,
        structuredEvidenceReceipts: const {
          'nested/fg180.fg-evidence.json': '''
{
  "schemaVersion": 1,
  "lotIds": ["FG-180"],
  "statusByLot": {"FG-180": "DONE"},
  "candidateSha": "old-sha",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {"command": "dart test", "exitCode": 0, "outputDigest": "sha256:green"}
  ],
  "sourcePaths": ["packages/map_core"]
}
''',
        },
      );

      expect(
        dashboard.entries.single.evidenceState,
        GameplayRoadmapEvidenceState.stale,
      );
      expect(
        dashboard.diagnostics.map((item) => item.code),
        containsAll([
          GameplayRoadmapDiagnosticCode.staleEvidenceReceipt,
          GameplayRoadmapDiagnosticCode.missingFreshEvidence,
        ]),
      );
      expect(dashboard.hasBlockingDiagnostics, isTrue);
    });

    test('conflicting receipts are blocking evidence', () {
      String receipt(String status, int exitCode) => '''
{
  "schemaVersion": 1,
  "lotIds": ["FG-180"],
  "statusByLot": {"FG-180": "$status"},
  "candidateSha": "candidate-sha",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {
      "command": "dart test",
      "exitCode": $exitCode,
      "outputDigest": "sha256:result"
    }
  ],
  "sourcePaths": ["packages/map_core"]
}
''';

      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `DONE` | receipt |
''',
        gameplayReports: const {},
        candidateSha: 'candidate-sha',
        structuredEvidenceReceipts: {
          'a.fg-evidence.json': receipt('DONE', 1),
          'b.fg-evidence.json': receipt('PARTIAL', 0),
        },
      );

      expect(
        dashboard.entries.single.evidenceState,
        GameplayRoadmapEvidenceState.contradictory,
      );
      expect(
        dashboard.diagnostics.map((item) => item.code),
        contains(GameplayRoadmapDiagnosticCode.conflictingEvidenceReceipts),
      );
      expect(dashboard.hasBlockingDiagnostics, isTrue);
    });

    test('a failed receipt command cannot prove its lot', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `DONE` | receipt |
''',
        gameplayReports: const {},
        candidateSha: 'candidate-sha',
        structuredEvidenceReceipts: const {
          'failed.fg-evidence.json': '''
{
  "schemaVersion": 1,
  "lotIds": ["FG-180"],
  "statusByLot": {"FG-180": "DONE"},
  "candidateSha": "candidate-sha",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {"command": "dart test", "exitCode": 1, "outputDigest": "sha256:red"}
  ],
  "sourcePaths": ["packages/map_core"]
}
''',
        },
      );

      expect(
        dashboard.entries.single.evidenceState,
        GameplayRoadmapEvidenceState.failed,
      );
      expect(
        dashboard.diagnostics.map((item) => item.code),
        contains(GameplayRoadmapDiagnosticCode.failedEvidenceCommand),
      );
      expect(dashboard.hasBlockingDiagnostics, isTrue);
    });

    test('historical statuses do not contradict a fresh candidate receipt', () {
      String receipt(String sha, String status) => '''
{
  "schemaVersion": 1,
  "lotIds": ["FG-180"],
  "statusByLot": {"FG-180": "$status"},
  "candidateSha": "$sha",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {"command": "dart test", "exitCode": 0, "outputDigest": "sha256:result"}
  ],
  "sourcePaths": ["packages/map_core"]
}
''';

      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `DONE` | receipt |
''',
        gameplayReports: const {},
        candidateSha: 'current-sha',
        requireFreshEvidence: true,
        structuredEvidenceReceipts: {
          'historical.fg-evidence.json': receipt('old-sha', 'PARTIAL'),
          'current.fg-evidence.json': receipt('current-sha', 'DONE'),
        },
      );

      expect(
        dashboard.entries.single.evidenceState,
        GameplayRoadmapEvidenceState.fresh,
      );
      expect(
        dashboard.diagnostics.map((item) => item.code),
        isNot(contains(
          GameplayRoadmapDiagnosticCode.conflictingEvidenceReceipts,
        )),
      );
      expect(dashboard.hasBlockingDiagnostics, isFalse);
    });

    test('a historical failed command cannot poison a fresh candidate', () {
      String receipt(String sha, int exitCode) => '''
{
  "schemaVersion": 1,
  "lotIds": ["FG-180"],
  "statusByLot": {"FG-180": "DONE"},
  "candidateSha": "$sha",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {"command": "dart test", "exitCode": $exitCode, "outputDigest": "sha256:result"}
  ],
  "sourcePaths": ["packages/map_core"]
}
''';

      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `DONE` | receipt |
''',
        gameplayReports: const {},
        candidateSha: 'current-sha',
        requireFreshEvidence: true,
        structuredEvidenceReceipts: {
          'historical.fg-evidence.json': receipt('old-sha', 1),
          'current.fg-evidence.json': receipt('current-sha', 0),
        },
      );

      expect(
        dashboard.entries.single.evidenceState,
        GameplayRoadmapEvidenceState.fresh,
      );
      expect(
        dashboard.diagnostics.map((item) => item.code),
        isNot(contains(GameplayRoadmapDiagnosticCode.failedEvidenceCommand)),
      );
      expect(dashboard.hasBlockingDiagnostics, isFalse);
    });

    test('renders structured source, candidate and command details', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `DONE` | receipt |
''',
        gameplayReports: const {},
        candidateSha: 'candidate-sha',
        structuredEvidenceReceipts: const {
          'external:phase0.fg-evidence.json': '''
{
  "schemaVersion": 1,
  "lotIds": ["FG-180"],
  "statusByLot": {"FG-180": "DONE"},
  "candidateSha": "candidate-sha",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {"command": "dart test", "exitCode": 0, "outputDigest": "sha256:result"}
  ],
  "sourcePaths": ["packages/map_core"]
}
''',
        },
      );

      expect(
        dashboard.markdown,
        contains('external:phase0.fg-evidence.json'),
      );
      expect(dashboard.markdown, contains('candidate-sha'));
      expect(dashboard.markdown, contains('packages/map_core'));
      expect(
        dashboard.markdown,
        contains('dart test (exit 0, sha256:result)'),
      );
    });

    test('strict freshness marks a DONE lot without a receipt unproven', () {
      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `DONE` | old report |
''',
        gameplayReports: const {
          'reports/gameplay/fg_180_old.md': 'Proposed status: DONE',
        },
        candidateSha: 'candidate-sha',
        requireFreshEvidence: true,
      );

      expect(
        dashboard.entries.single.evidenceState,
        GameplayRoadmapEvidenceState.missing,
      );
      expect(
        dashboard.diagnostics.single.code,
        GameplayRoadmapDiagnosticCode.missingFreshEvidence,
      );
      expect(dashboard.hasBlockingDiagnostics, isTrue);
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
          '[--check] [--candidate-sha SHA] [--require-fresh-evidence] '
          '[--evidence-directory PATH] '
          '[repository-root]',
        ),
      );
    });

    test('CLI preserves dashboard generation without check mode', () async {
      final temporaryRoot =
          await Directory.systemTemp.createTemp('pokemap_dashboard_render_');
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
| FG-180 | Readiness | `TODO` | — |
''');

      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/generate_gameplay_roadmap_dashboard.dart',
          temporaryRoot.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0);
      expect(result.stdout, contains('# Gameplay Roadmap Dashboard'));
      expect(result.stderr, isEmpty);
    });

    test('CLI recursively loads reports and fresh multi-lot receipts',
        () async {
      final temporaryRoot =
          await Directory.systemTemp.createTemp('pokemap_dashboard_nested_');
      addTearDown(() => temporaryRoot.delete(recursive: true));
      final nested = await Directory(
        '${temporaryRoot.path}${Platform.pathSeparator}reports'
        '${Platform.pathSeparator}gameplay${Platform.pathSeparator}nested',
      ).create(recursive: true);
      await File(
        '${temporaryRoot.path}${Platform.pathSeparator}'
        'pokemap_roadmap_mecaniques_fangame.md',
      ).writeAsString('''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `DONE` | receipt |
| FG-181 | Fixture | `PARTIAL` | receipt |
''');
      await File('${nested.path}${Platform.pathSeparator}fg_180_note.md')
          .writeAsString('Proposed status: DONE');
      await File(
        '${nested.path}${Platform.pathSeparator}phase0.fg-evidence.json',
      ).writeAsString('''
{
  "schemaVersion": 1,
  "lotIds": ["FG-180", "FG-181"],
  "statusByLot": {"FG-180": "DONE", "FG-181": "PARTIAL"},
  "candidateSha": "candidate-sha",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {"command": "dart test", "exitCode": 0, "outputDigest": "sha256:green"}
  ],
  "sourcePaths": ["packages/map_core"]
}
''');

      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/generate_gameplay_roadmap_dashboard.dart',
          '--check',
          '--candidate-sha',
          'candidate-sha',
          '--require-fresh-evidence',
          temporaryRoot.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0);
      expect(
        result.stdout,
        contains('| FG-180 | Readiness | DONE | 2 |'),
      );
      expect(
        result.stdout,
        contains('| FG-181 | Fixture | PARTIAL | 1 |'),
      );
      expect(result.stdout, contains('| FRESH |'));
      expect(result.stderr, isEmpty);
    });

    test('CLI accepts post-checkout receipts from an external directory',
        () async {
      final temporaryRoot =
          await Directory.systemTemp.createTemp('pokemap_dashboard_external_');
      final externalEvidence = await Directory.systemTemp.createTemp(
        'pokemap_dashboard_external_receipts_',
      );
      addTearDown(() => temporaryRoot.delete(recursive: true));
      addTearDown(() => externalEvidence.delete(recursive: true));
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
| FG-180 | Readiness | `DONE` | receipt |
''');
      await File(
        '${externalEvidence.path}${Platform.pathSeparator}'
        'phase0.fg-evidence.json',
      ).writeAsString('''
{
  "schemaVersion": 1,
  "lotIds": ["FG-180"],
  "statusByLot": {"FG-180": "DONE"},
  "candidateSha": "candidate-sha",
  "capturedAtUtc": "2026-07-28T10:00:00Z",
  "commands": [
    {"command": "dart test", "exitCode": 0, "outputDigest": "sha256:result"}
  ],
  "sourcePaths": ["packages/map_core"]
}
''');

      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/generate_gameplay_roadmap_dashboard.dart',
          '--check',
          '--candidate-sha',
          'candidate-sha',
          '--require-fresh-evidence',
          '--evidence-directory',
          externalEvidence.path,
          temporaryRoot.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0);
      expect(result.stdout, contains('external:phase0.fg-evidence.json'));
      expect(result.stdout, contains('| FRESH |'));
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
