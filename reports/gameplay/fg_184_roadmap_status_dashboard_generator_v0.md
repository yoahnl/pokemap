# FG-184 — Roadmap Status Dashboard Generator V0

Date: 2026-07-21

Proposed status: **DONE**

## Résumé exécutif

FG-184 ajoute une projection read-only et déterministe de la roadmap gameplay.
Le générateur rapproche les lignes `FG-*` du fichier canonique avec les
Evidence Packs présents dans `reports/gameplay`, puis écrit un tableau Markdown
sur la sortie standard. Il ne modifie ni la roadmap ni les rapports.

## Confirmation du scope

- Inclus : parsing Markdown tolérant, association des rapports par identifiant
  de lot, prise en compte des propositions explicites, sortie Markdown, CLI.
- Inclus : comportement fail-closed lorsqu'au moins deux rapports explicites se
  contredisent (`PARTIAL`).
- Hors scope : écriture automatique de la roadmap, lancement des tests, calcul
  de couverture et décision de release FG-185.

## Audit initial

- Branche : `main`.
- HEAD initial : `05a6f9fa`.
- Worktree initial : propre avant le test TDD du lot.
- La roadmap contient 101 lots `FG-*`, mais aucun outil n'en produisait une vue
  synthétique réconciliée avec les Evidence Packs.
- Les rapports FG-180 à FG-183 proposent déjà explicitement `DONE`; FG-185
  reste canoniquement `PARTIAL`.
- Risque principal : afficher un faux `DONE` à partir d'un rapport descriptif
  ou contradictoire. Le parseur n'accepte donc que `Proposed status:` explicite.

## Fichiers modifiés

| Chemin | Zone | Raison et impact |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | barrel public | Exporte le dashboard aux consommateurs de `map_core`. |
| `packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart` | nouveau modèle/outillage pur Dart | Parse, réconcilie et rend les statuts sans I/O. |
| `packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart` | nouvelle CLI | Lit le dépôt et écrit uniquement sur stdout. |
| `packages/map_core/test/gameplay_roadmap_dashboard_test.dart` | nouveaux tests | Prouve cas positif, garde-fous et déterminisme. |
| `reports/gameplay/fg_184_roadmap_status_dashboard_generator_v0.md` | nouvel Evidence Pack | Trace l'audit, l'implémentation et les preuves fraîches. |

## Diff précis des fichiers modifiés

`packages/map_core/lib/map_core.dart` :

```diff
 export 'src/read_models/project_gameplay_readiness.dart';
+export 'src/tooling/gameplay_roadmap_dashboard.dart';
 export 'src/read_models/linked_asset_public_contracts.dart';
```

## Tests créés

Le fichier `gameplay_roadmap_dashboard_test.dart` couvre :

1. la surcharge du statut canonique par une proposition explicite ;
2. un rapport sans proposition, compté comme preuve mais sans effet de statut ;
3. deux propositions contradictoires, ramenées à `PARTIAL` ;
4. l'ordre déterministe des lots et des chemins de preuves ;
5. l'ignorance sans exception des lignes mal formées.

## Commandes et résultats exacts

```text
cd packages/map_core
dart test test/gameplay_roadmap_dashboard_test.dart
=> +5: All tests passed!

dart run tool/generate_gameplay_roadmap_dashboard.dart /Users/karim/Project/pokemonProject
=> DONE: 5 · PARTIAL: 1 · TODO: 95
=> FG-180..FG-183: DONE ; FG-184: TODO avant cet Evidence Pack ; FG-185: PARTIAL
=> READ_ONLY_OK (état git identique avant/après)

dart test
=> 01:52 +4333: All tests passed!

dart analyze
=> Analyzing map_core...
=> No issues found!
```

Build complet : non applicable à ce lot de bibliothèque pure Dart. La meilleure
validation alternative est la compilation implicite des 4 333 tests et
`dart analyze`, tous deux verts.

## État git final avant commit

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart
?? packages/map_core/test/gameplay_roadmap_dashboard_test.dart
?? packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart
?? reports/gameplay/fg_184_roadmap_status_dashboard_generator_v0.md
```

## Passes obligatoires

| Passe nommée | Verdict |
|---|---|
| Audit / Architecture | PASS — logique pure dans `map_core`, I/O isolées dans `tool/` |
| Implémentation | PASS — projection déterministe, aucune écriture de projet |
| Tests | PASS — ciblé `+5`, suite complète `+4333` |
| Build / Validation | PASS — analyse sans erreur; build applicatif non applicable |
| Critique finale | PASS — statuts implicites ignorés, contradictions fail-closed |

## Limites et risques conservés

- Le dashboard projette les Evidence Packs mais ne remplace pas la roadmap
  canonique et ne la modifie jamais.
- Il ne vérifie pas que les commandes citées dans les rapports ont réellement
  été exécutées; cette preuve reste la responsabilité de l'Evidence Pack.
- `BLOCKED` est présenté comme `PARTIAL`, le V0 n'exposant volontairement que
  trois états de synthèse.
- Le statut FG-185 reste `PARTIAL` jusqu'à satisfaction de toutes ses preuves,
  notamment l'approbation explicite du périmètre MVP.

## Auto-critique

Le format Markdown de la roadmap reste une interface textuelle fragile. Le
parseur est volontairement petit et couvert, mais une future évolution vers un
registre structuré réduirait ce risque. Ajouter une écriture automatique aurait
créé un risque de dérive documentaire et a été explicitement écarté.

## Prochaine étape proposée

FG-185 — exécuter la matrice exhaustive, réévaluer les cinq preuves de release
et maintenir le verdict `NO-GO` tant que l'une d'elles reste non vérifiée.

## Annexe A — contenu complet des fichiers créés

### `packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart`

```dart
enum GameplayRoadmapStatus {
  done,
  partial,
  todo,
}

final class GameplayRoadmapDashboardEntry {
  GameplayRoadmapDashboardEntry({
    required this.id,
    required this.title,
    required this.status,
    required Iterable<String> evidencePaths,
  }) : evidencePaths = List.unmodifiable(
          evidencePaths.toList(growable: false)..sort(),
        );

  final String id;
  final String title;
  final GameplayRoadmapStatus status;
  final List<String> evidencePaths;
}

/// Read-only projection of canonical roadmap lots and report status proposals.
final class GameplayRoadmapDashboard {
  GameplayRoadmapDashboard._(Iterable<GameplayRoadmapDashboardEntry> entries)
      : entries = List.unmodifiable(entries);

  factory GameplayRoadmapDashboard.build({
    required String roadmapMarkdown,
    required Map<String, String> gameplayReports,
  }) {
    final reportEvidence = <String, List<_ReportEvidence>>{};
    for (final entry in gameplayReports.entries) {
      final lotId = _lotIdFromReportPath(entry.key);
      if (lotId == null) continue;
      reportEvidence.putIfAbsent(lotId, () => []).add(
            _ReportEvidence(
              path: entry.key,
              proposedStatus: _proposedStatus(entry.value),
            ),
          );
    }

    final entries = <GameplayRoadmapDashboardEntry>[];
    for (final line in roadmapMarkdown.split('\n')) {
      final cells = line.split('|').map((cell) => cell.trim()).toList();
      if (cells.length < 5 || !RegExp(r'^FG-\d{3}$').hasMatch(cells[1])) {
        continue;
      }
      final id = cells[1];
      final roadmapStatus = _roadmapStatus(cells[3]);
      if (roadmapStatus == null) continue;
      final reports = reportEvidence[id] ?? const <_ReportEvidence>[];
      entries.add(
        GameplayRoadmapDashboardEntry(
          id: id,
          title: cells[2],
          status: _effectiveStatus(roadmapStatus, reports),
          evidencePaths: reports.map((report) => report.path),
        ),
      );
    }
    entries.sort((left, right) => left.id.compareTo(right.id));
    return GameplayRoadmapDashboard._(entries);
  }

  final List<GameplayRoadmapDashboardEntry> entries;

  int count(GameplayRoadmapStatus status) =>
      entries.where((entry) => entry.status == status).length;

  String get markdown {
    final buffer = StringBuffer()
      ..writeln('# Gameplay Roadmap Dashboard')
      ..writeln()
      ..writeln(
        'DONE: ${count(GameplayRoadmapStatus.done)} · '
        'PARTIAL: ${count(GameplayRoadmapStatus.partial)} · '
        'TODO: ${count(GameplayRoadmapStatus.todo)}',
      )
      ..writeln()
      ..writeln('| ID | Lot | Status | Evidence reports |')
      ..writeln('|---|---|---|---:|');
    for (final entry in entries) {
      buffer.writeln(
        '| ${entry.id} | ${_escapeCell(entry.title)} | '
        '${entry.status.name.toUpperCase()} | ${entry.evidencePaths.length} |',
      );
    }
    return buffer.toString().trimRight();
  }
}

final class _ReportEvidence {
  const _ReportEvidence({
    required this.path,
    required this.proposedStatus,
  });

  final String path;
  final GameplayRoadmapStatus? proposedStatus;
}

String? _lotIdFromReportPath(String path) {
  final match = RegExp(
    r'(?:^|/)fg_(\d{3})(?:_|\.)',
    caseSensitive: false,
  ).firstMatch(path.replaceAll('\\', '/'));
  return match == null ? null : 'FG-${match.group(1)}';
}

GameplayRoadmapStatus? _proposedStatus(String report) {
  final match = RegExp(
    r'Proposed status:\s*(?:\*\*)?(DONE|PARTIAL|TODO|BLOCKED)',
    caseSensitive: false,
  ).firstMatch(report);
  if (match == null) return null;
  return _statusFromName(match.group(1)!);
}

GameplayRoadmapStatus? _roadmapStatus(String cell) {
  for (final name in const <String>['DONE', 'PARTIAL', 'BLOCKED', 'TODO']) {
    if (cell.toUpperCase().contains(name)) return _statusFromName(name);
  }
  return null;
}

GameplayRoadmapStatus _statusFromName(String name) {
  return switch (name.toUpperCase()) {
    'DONE' => GameplayRoadmapStatus.done,
    'PARTIAL' || 'BLOCKED' => GameplayRoadmapStatus.partial,
    _ => GameplayRoadmapStatus.todo,
  };
}

GameplayRoadmapStatus _effectiveStatus(
  GameplayRoadmapStatus roadmapStatus,
  List<_ReportEvidence> reports,
) {
  final proposals = reports
      .map((report) => report.proposedStatus)
      .whereType<GameplayRoadmapStatus>()
      .toSet();
  if (proposals.isEmpty) return roadmapStatus;
  if (proposals.length > 1) return GameplayRoadmapStatus.partial;
  return proposals.single;
}

String _escapeCell(String value) =>
    value.replaceAll('|', r'\|').replaceAll('\n', ' ').trim();
```

### `packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart`

```dart
import 'dart:io';

import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  final repoRoot = arguments.isEmpty
      ? File.fromUri(Platform.script)
          .parent
          .parent
          .parent
          .parent
          .absolute
          .path
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
}
```

### `packages/map_core/test/gameplay_roadmap_dashboard_test.dart`

```dart
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
```
