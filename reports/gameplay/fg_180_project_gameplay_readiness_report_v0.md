# FG-180 — Project Gameplay Readiness Report V0

Date: 2026-07-21

Proposed status: **DONE**

## Résumé exécutif

Le lot fournit un agrégateur fail-closed pur Dart pour les onze dimensions de
jouabilité exigées par FG-180. Il produit un résumé lisible par le créateur et
un tableau détaillé pour les agents, avec les sévérités `error`, `warning` et
`info`. Les preuves manquantes, dupliquées ou prétendument réussies sans
source exploitable empêchent le statut jouable.

## Scope et architecture

- Lot exact : `FG-180 — Project Gameplay Readiness Report V0`.
- `map_core` reste sans dépendance Flutter/Flame et ne lit pas le filesystem.
- Les validateurs, tests et smokes externes fournissent des preuves sourcées.
- Hors scope : lancer les tests depuis le modèle, corriger un projet cassé,
  modifier la roadmap canonique.

## Audit initial

- Branche : `main`.
- HEAD initial : `65cae2520`.
- Worktree initial : propre.
- Le `BetaPlayabilityValidator` couvrait le démarrage, les trainers, la
  capture et la sauvegarde, mais aucun rapport unique ne représentait les onze
  dimensions FG-180 ni une présentation créateur/agent.
- Le contrat FG-185 existant a inspiré la normalisation fail-closed, sans être
  détourné comme rapport de projet.

## Fichiers et zones modifiées

| Fichier | Zone | Raison | Impact |
|---|---|---|---|
| `docs/superpowers/plans/2026-07-21-phase-10-playable-game-validation.md` | plan complet | Séquencer FG-180–185 et leurs gates | Exécution vérifiable sans placeholder |
| `packages/map_core/lib/src/read_models/project_gameplay_readiness.dart` | nouveau read model | Agréger et présenter les onze preuves | Décision jouable fail-closed |
| `packages/map_core/lib/map_core.dart` | barrel read models | Exposer l'API publique | Utilisable par editor/runtime/tooling |
| `packages/map_core/test/project_gameplay_readiness_test.dart` | nouvelle suite | Healthy/broken/missing/invalid/duplicate | Régression du contrat |
| `reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md` | Evidence Pack | Clôture traçable | Preuve du lot |

Diff précis du barrel : ajout de
`export 'src/read_models/project_gameplay_readiness.dart';` après les read
models Golden Slice et MVP release gate.

## TDD et validations

RED observé :

```text
Undefined name 'ProjectGameplayReadinessReport'.
Undefined name 'ProjectGameplayReadinessCheck'.
Some tests failed.
```

Commandes fraîches :

```bash
cd packages/map_core
dart test test/project_gameplay_readiness_test.dart
dart test
dart analyze
```

Résultats exacts :

```text
+5: All tests passed!
01:54 +4328: All tests passed!
Analyzing map_core...
No issues found!
```

## Passes obligatoires

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — read model pur et preuves externes sourcées |
| Implémentation | PASS — onze checks, normalisation et deux rendus |
| Tests | PASS — cas sain, cassé, absent, invalide et contradictoire |
| Build / Validation | PASS — suite et analyse Core vertes |
| Critique | PASS avec limite — la fraîcheur reste la responsabilité du producteur de preuve |

## Limites et risques

- Un rapport n'invente pas les preuves : les lots FG-181/182 doivent produire
  la Golden Slice fraîche.
- `warning` bloque volontairement `isPlayable` pour ne pas transformer une
  absence de preuve en GO.
- Aucun statut de la roadmap canonique n'est modifié dans ce lot.

## État Git avant commit

Le worktree contient uniquement le plan Phase 10 et les fichiers FG-180 listés
ci-dessus. `git diff --check` doit rester vert avant le commit dédié.

## Annexe — contenu complet des fichiers créés

### `docs/superpowers/plans/2026-07-21-phase-10-playable-game-validation.md`

```md
# Phase 10 — Playable Game Validation Implementation Plan

> **Execution mode:** inline, because sub-agent delegation is disabled for this session.
> Apply `executing-plans`, `test-driven-development`, and
> `verification-before-completion` throughout. Commit every FG lot separately.

**Goal:** Close FG-180 through FG-185 with a fail-closed gameplay-readiness
report, a versioned three-map Golden Slice, a production-backed end-to-end
smoke, a regression matrix, an executable roadmap dashboard, and a fresh MVP
release decision.

**Architecture:** Keep project inspection and release evidence in pure Dart.
`map_core` owns readiness/report contracts. `map_gameplay` owns the missing
pure shop transaction. The runtime-host fixture and test compose existing
production APIs; they do not implement parallel gameplay rules. Documentation
and dashboard tooling consume evidence but never mutate product code.

**Tech Stack:** Dart 3, Flutter test, `package:test`, existing PokeMap package
APIs, JSON fixtures, Markdown Evidence Packs.

---

## Task 1 — FG-180 Project Gameplay Readiness Report V0

**Files:**

- Create: `packages/map_core/lib/src/read_models/project_gameplay_readiness.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Create: `packages/map_core/test/project_gameplay_readiness_test.dart`
- Create: `reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md`

**Steps:**

1. Write failing tests for a complete fixture, a broken fixture, missing
   evidence, severity ordering, creator summary, and agent detail rendering.
2. Run only `project_gameplay_readiness_test.dart` and record the expected RED.
3. Implement the eleven canonical FG-180 checks as typed evidence with
   `passed`, `failed`, and `unverified` states. Normalize each state into
   `info`, `error`, and `warning` diagnostics respectively.
4. Make passed evidence fail closed when its summary or source is blank.
5. Expose `isPlayable`, severity counts, creator-facing Markdown, and detailed
   agent Markdown without filesystem access.
6. Export the API from `map_core.dart`, format, run the targeted test, then run
   the full `map_core` test and analysis gates.
7. Write the FG-180 Evidence Pack and commit only this lot.

## Task 2 — FG-181 Golden Slice Fangame Fixture V0

**Files:**

- Create: `examples/playable_runtime_host/golden_fangame_slice/project.json`
- Create: `examples/playable_runtime_host/golden_fangame_slice/maps/golden_town.json`
- Create: `examples/playable_runtime_host/golden_fangame_slice/maps/golden_route.json`
- Create: `examples/playable_runtime_host/golden_fangame_slice/maps/golden_summit.json`
- Create: `examples/playable_runtime_host/golden_fangame_slice/walkthrough.json`
- Copy minimal Pokémon JSON data from the existing versioned battle fixture.
- Create: `examples/playable_runtime_host/test/golden_fangame_slice_fixture_test.dart`
- Create: `reports/gameplay/fg_181_golden_slice_fangame_fixture_v0.md`

**Steps:**

1. Write a failing fixture contract test expecting three loadable maps,
   authored New Game and starter data, encounter/trainer content, and the full
   ordered walkthrough contract.
2. Add the smallest JSON fixture able to express the journey. Use no raster
   assets and reuse only the existing minimal species/move catalog JSON.
3. Validate `ProjectManifest`, every `MapData`, map references, spawn points,
   encounter tables, trainer references, and walkthrough IDs.
4. Run the targeted host fixture test, then host analysis.
5. Document the expected walkthrough and preserved non-goals; commit the lot.

## Task 3 — FG-182 Golden Slice End-to-End Smoke V0

**Files:**

- Modify: `packages/map_gameplay/lib/src/game_state_mutations.dart`
- Modify: `packages/map_gameplay/lib/map_gameplay.dart`
- Modify: `packages/map_gameplay/test/party_bag_heal_operations_test.dart`
- Create: `examples/playable_runtime_host/test/golden_fangame_slice_e2e_test.dart`
- Create: `reports/gameplay/fg_182_golden_slice_end_to_end_smoke_v0.md`

**Steps:**

1. RED: specify a typed `ShopPurchaseResult` and `purchaseItem` mutation that
   rejects invalid quantity/price, insufficient money, and overflow, and that
   atomically deducts money plus grants the item on success.
2. GREEN: implement the minimal pure shop transaction in `map_gameplay` and
   export it. Do not add UI, catalogs, or hardcoded prices.
3. RED: write one automated Golden Slice journey smoke that must prove all
   eleven FG-182 checkpoints in order.
4. GREEN: load the real fixture and compose production APIs for New Game and
   starter selection, deterministic encounter and combat, capture destination,
   trainer victory, reward/level-up, shop purchase, heal recovery, story flag,
   Surf unlock, save/JSON reload, and story end.
5. Assert every intermediate and reloaded state, not only a final boolean.
6. Run targeted gameplay and host tests, then both full suites and analyses.
7. Write the walkthrough evidence and commit the lot.

## Task 4 — FG-183 Regression Matrix V0

**Files:**

- Create: `reports/gameplay/fg_183_regression_matrix_v0.md`

**Steps:**

1. Inventory every test package and the Phase 10 targeted files.
2. Map FG-180 through FG-185 to exact fast commands and full package gates.
3. Include runtime/host Phase A smokes, Selbrume journey coverage, analyzer
   commands, and macOS build commands.
4. Verify every documented path and command exists; run the fast Phase 10
   matrix fresh.
5. Record exact results and commit the documentation-only lot.

## Task 5 — FG-184 Roadmap Status Dashboard Generator V0

**Files:**

- Create: `packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Create: `packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart`
- Create: `packages/map_core/test/gameplay_roadmap_dashboard_test.dart`
- Create: `reports/gameplay/fg_184_roadmap_status_dashboard_generator_v0.md`

**Steps:**

1. RED: test roadmap-lot parsing, report-evidence discovery, explicit proposed
   status extraction, TODO/PARTIAL/DONE output, deterministic sorting, and
   malformed-report handling.
2. Implement a pure read model that combines the canonical roadmap with report
   text supplied by the caller.
3. Add a read-only CLI which reads `pokemap_roadmap_mecaniques_fangame.md` and
   `reports/gameplay`, prints a Markdown table to stdout, and performs no writes.
4. Test the parser, run the CLI against the repository, and verify that
   `git status --short` is unchanged by execution.
5. Run full `map_core` tests/analyze, write the Evidence Pack, and commit.

## Task 6 — FG-185 MVP Release Gate V0

**Files:**

- Modify: `packages/map_core/test/mvp_release_gate_test.dart`
- Modify: `reports/gameplay/fg_185_mvp_release_gate_v0.md`
- Create: `reports/gameplay/fg_180_185_phase_10_playable_game_validation_completion.md`

**Steps:**

1. Add a release-gate characterization test using the fresh Phase 10 evidence
   sources. Preserve fail-closed behavior for absent user scope approval.
2. Run every pure-Dart package suite and analysis, then runtime, editor, and
   runtime-host suites and analyses package by package.
3. Run the Golden Slice smoke, Selbrume player journey, runtime battle smokes,
   editor seed check, and macOS debug builds for editor and host.
4. Evaluate all five FG-185 criteria from the fresh evidence. Do not promote
   user scope approval from implementation authorization; leave it
   `unverified` unless the user explicitly approves the documented MVP cutoff.
5. Update the FG-185 report and create the Phase 10 completion Evidence Pack
   with initial/final Git state, complete file inventory, commands, exact
   results, named review passes, limitations, and self-critique.
6. Commit the technical release-gate lot. Do not push unless explicitly asked.

## Final Verification Gate

Run from each package, never from a nonexistent monorepo orchestrator:

```bash
cd packages/map_core && dart test && dart analyze
cd packages/map_gameplay && dart test && dart analyze
cd packages/map_battle && dart test && dart analyze
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
cd examples/playable_runtime_host && flutter test && flutter analyze
cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
cd examples/playable_runtime_host && flutter test test/golden_fangame_slice_e2e_test.dart
cd examples/playable_runtime_host && flutter test test/selbrume_player_journey_e2e_test.dart
cd packages/map_editor && flutter build macos --debug
cd examples/playable_runtime_host && flutter build macos --debug
```

Final hygiene:

```bash
git diff --check
git status --short --untracked-files=all
```
```

### `packages/map_core/lib/src/read_models/project_gameplay_readiness.dart`

```dart
/// Canonical gameplay-readiness checks required by `FG-180`.
enum ProjectGameplayReadinessCheck {
  startState,
  starterConfiguration,
  playablePartyPath,
  encounterTables,
  trainerReferences,
  shopItems,
  eventCommands,
  requiredFlagsReachable,
  fieldAbilityUnlockReachable,
  storyEndReachable,
  battleBridgeCoverage,
}

/// State of one externally produced readiness proof.
enum ProjectGameplayReadinessEvidenceStatus {
  passed,
  failed,
  unverified,
}

/// Severity exposed to creators and automated consumers.
enum ProjectGameplayReadinessSeverity {
  error,
  warning,
  info,
}

/// One source-backed proof for a canonical readiness check.
final class ProjectGameplayReadinessEvidence {
  const ProjectGameplayReadinessEvidence({
    required this.check,
    required this.status,
    required this.summary,
    this.source,
  });

  final ProjectGameplayReadinessCheck check;
  final ProjectGameplayReadinessEvidenceStatus status;
  final String summary;
  final String? source;
}

/// Normalized creator/agent diagnostic derived from readiness evidence.
final class ProjectGameplayReadinessDiagnostic {
  const ProjectGameplayReadinessDiagnostic({
    required this.check,
    required this.severity,
    required this.summary,
    this.source,
  });

  final ProjectGameplayReadinessCheck check;
  final ProjectGameplayReadinessSeverity severity;
  final String summary;
  final String? source;
}

/// Fail-closed FG-180 report for a playable project.
///
/// The report aggregates evidence produced by project validators, integration
/// tests and runtime smokes. It deliberately performs no filesystem access so
/// `map_core` remains pure Dart and callers decide how fresh evidence is
/// collected.
final class ProjectGameplayReadinessReport {
  ProjectGameplayReadinessReport._(
    Iterable<ProjectGameplayReadinessDiagnostic> diagnostics,
  ) : diagnostics = List.unmodifiable(diagnostics);

  factory ProjectGameplayReadinessReport.evaluate(
    Iterable<ProjectGameplayReadinessEvidence> evidence,
  ) {
    final supplied = <ProjectGameplayReadinessCheck,
        List<ProjectGameplayReadinessEvidence>>{};
    for (final item in evidence) {
      supplied.putIfAbsent(item.check, () => []).add(item);
    }

    final diagnostics = <ProjectGameplayReadinessDiagnostic>[];
    for (final check in ProjectGameplayReadinessCheck.values) {
      final candidates = supplied[check] ?? const [];
      if (candidates.isEmpty) {
        diagnostics.add(
          ProjectGameplayReadinessDiagnostic(
            check: check,
            severity: ProjectGameplayReadinessSeverity.warning,
            summary: 'Aucune preuve fournie pour ${_labelFor(check)}.',
          ),
        );
        continue;
      }
      if (candidates.length != 1) {
        diagnostics.add(
          ProjectGameplayReadinessDiagnostic(
            check: check,
            severity: ProjectGameplayReadinessSeverity.error,
            summary: 'Plusieurs preuves contradictoires ont été fournies pour '
                '${_labelFor(check)}.',
          ),
        );
        continue;
      }

      diagnostics.add(_normalize(candidates.single));
    }

    return ProjectGameplayReadinessReport._(diagnostics);
  }

  final List<ProjectGameplayReadinessDiagnostic> diagnostics;

  List<ProjectGameplayReadinessDiagnostic> get errors => List.unmodifiable(
        diagnostics.where(
          (item) => item.severity == ProjectGameplayReadinessSeverity.error,
        ),
      );

  List<ProjectGameplayReadinessDiagnostic> get warnings => List.unmodifiable(
        diagnostics.where(
          (item) => item.severity == ProjectGameplayReadinessSeverity.warning,
        ),
      );

  List<ProjectGameplayReadinessDiagnostic> get infos => List.unmodifiable(
        diagnostics.where(
          (item) => item.severity == ProjectGameplayReadinessSeverity.info,
        ),
      );

  bool get isPlayable =>
      errors.isEmpty &&
      warnings.isEmpty &&
      diagnostics.length == ProjectGameplayReadinessCheck.values.length;

  String get creatorMarkdown {
    final buffer = StringBuffer()
      ..writeln(isPlayable ? '# Projet jouable' : '# Projet incomplet')
      ..writeln()
      ..writeln(
        '${infos.length}/${ProjectGameplayReadinessCheck.values.length} '
        'vérifications réussies.',
      );
    if (errors.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## ${errors.length} erreur(s) à corriger');
      for (final diagnostic in errors) {
        buffer.writeln('- ${diagnostic.summary}');
      }
    }
    if (warnings.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          '## ${warnings.length} vérification(s) à confirmer',
        );
      for (final diagnostic in warnings) {
        buffer.writeln('- ${diagnostic.summary}');
      }
    }
    return buffer.toString().trimRight();
  }

  String get agentMarkdown {
    final buffer = StringBuffer()
      ..writeln('# Project Gameplay Readiness — agent detail')
      ..writeln()
      ..writeln('| Check | Severity | Summary | Source |')
      ..writeln('|---|---|---|---|');
    for (final diagnostic in diagnostics) {
      buffer.writeln(
        '| `${diagnostic.check.name}` | '
        '`${diagnostic.severity.name}` | '
        '${_escapeCell(diagnostic.summary)} | '
        '${_escapeCell(diagnostic.source ?? '—')} |',
      );
    }
    return buffer.toString().trimRight();
  }
}

ProjectGameplayReadinessDiagnostic _normalize(
  ProjectGameplayReadinessEvidence evidence,
) {
  if (evidence.status == ProjectGameplayReadinessEvidenceStatus.passed &&
      (evidence.summary.trim().isEmpty ||
          evidence.source == null ||
          evidence.source!.trim().isEmpty)) {
    return ProjectGameplayReadinessDiagnostic(
      check: evidence.check,
      severity: ProjectGameplayReadinessSeverity.error,
      summary: 'La preuve réussie pour ${_labelFor(evidence.check)} est '
          'inexploitable : résumé et source sont obligatoires.',
      source: evidence.source,
    );
  }

  final severity = switch (evidence.status) {
    ProjectGameplayReadinessEvidenceStatus.passed =>
      ProjectGameplayReadinessSeverity.info,
    ProjectGameplayReadinessEvidenceStatus.failed =>
      ProjectGameplayReadinessSeverity.error,
    ProjectGameplayReadinessEvidenceStatus.unverified =>
      ProjectGameplayReadinessSeverity.warning,
  };
  return ProjectGameplayReadinessDiagnostic(
    check: evidence.check,
    severity: severity,
    summary: evidence.summary.trim().isEmpty
        ? 'Aucun détail fourni pour ${_labelFor(evidence.check)}.'
        : evidence.summary.trim(),
    source: evidence.source?.trim(),
  );
}

String _labelFor(ProjectGameplayReadinessCheck check) => switch (check) {
      ProjectGameplayReadinessCheck.startState => 'l’état de départ',
      ProjectGameplayReadinessCheck.starterConfiguration =>
        'la configuration du starter',
      ProjectGameplayReadinessCheck.playablePartyPath =>
        'le chemin vers une équipe jouable',
      ProjectGameplayReadinessCheck.encounterTables =>
        'les tables de rencontre',
      ProjectGameplayReadinessCheck.trainerReferences =>
        'les références de dresseurs',
      ProjectGameplayReadinessCheck.shopItems => 'les objets de boutique',
      ProjectGameplayReadinessCheck.eventCommands =>
        'les commandes événementielles',
      ProjectGameplayReadinessCheck.requiredFlagsReachable =>
        'les flags requis',
      ProjectGameplayReadinessCheck.fieldAbilityUnlockReachable =>
        'le déblocage d’une capacité de terrain',
      ProjectGameplayReadinessCheck.storyEndReachable => 'la fin de l’histoire',
      ProjectGameplayReadinessCheck.battleBridgeCoverage =>
        'la couverture du bridge de combat',
    };

String _escapeCell(String value) =>
    value.replaceAll('|', r'\|').replaceAll('\n', ' ').trim();
```

### `packages/map_core/test/project_gameplay_readiness_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectGameplayReadinessReport', () {
    test('healthy fixture is playable and renders creator and agent reports',
        () {
      final report = ProjectGameplayReadinessReport.evaluate(
        _passedEvidence(),
      );

      expect(report.isPlayable, isTrue);
      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(
          report.infos, hasLength(ProjectGameplayReadinessCheck.values.length));
      expect(report.creatorMarkdown, contains('Projet jouable'));
      expect(report.creatorMarkdown, contains('11/11 vérifications réussies'));
      expect(report.agentMarkdown, contains('`battleBridgeCoverage`'));
      expect(report.agentMarkdown, contains('reports/gameplay/proof.md'));
    });

    test('broken fixture exposes errors and unverified checks as warnings', () {
      final evidence = <ProjectGameplayReadinessEvidence>[
        ..._passedEvidence().where(
          (item) =>
              item.check != ProjectGameplayReadinessCheck.startState &&
              item.check !=
                  ProjectGameplayReadinessCheck.starterConfiguration &&
              item.check != ProjectGameplayReadinessCheck.storyEndReachable,
        ),
        const ProjectGameplayReadinessEvidence(
          check: ProjectGameplayReadinessCheck.startState,
          status: ProjectGameplayReadinessEvidenceStatus.failed,
          summary: 'Aucune map de départ utilisable.',
          source: 'fixture:broken',
        ),
        const ProjectGameplayReadinessEvidence(
          check: ProjectGameplayReadinessCheck.starterConfiguration,
          status: ProjectGameplayReadinessEvidenceStatus.failed,
          summary: 'La configuration starter est absente.',
          source: 'fixture:broken',
        ),
      ];

      final report = ProjectGameplayReadinessReport.evaluate(evidence);

      expect(report.isPlayable, isFalse);
      expect(report.errors, hasLength(2));
      expect(report.warnings, hasLength(1));
      expect(
        report.warnings.single.check,
        ProjectGameplayReadinessCheck.storyEndReachable,
      );
      expect(report.creatorMarkdown, contains('Projet incomplet'));
      expect(report.creatorMarkdown, contains('2 erreur(s)'));
      expect(report.creatorMarkdown, contains('1 vérification(s) à confirmer'));
    });

    test('missing evidence fails closed as an unverified warning', () {
      final report = ProjectGameplayReadinessReport.evaluate(
        _passedEvidence().where(
          (item) =>
              item.check !=
              ProjectGameplayReadinessCheck.fieldAbilityUnlockReachable,
        ),
      );

      expect(report.isPlayable, isFalse);
      expect(report.warnings, hasLength(1));
      expect(
        report.warnings.single.check,
        ProjectGameplayReadinessCheck.fieldAbilityUnlockReachable,
      );
      expect(report.warnings.single.summary, contains('Aucune preuve'));
    });

    test('passed evidence without usable metadata becomes an error', () {
      final evidence = _passedEvidence()
          .map(
            (item) => item.check == ProjectGameplayReadinessCheck.shopItems
                ? const ProjectGameplayReadinessEvidence(
                    check: ProjectGameplayReadinessCheck.shopItems,
                    status: ProjectGameplayReadinessEvidenceStatus.passed,
                    summary: ' ',
                    source: '',
                  )
                : item,
          )
          .toList(growable: false);

      final report = ProjectGameplayReadinessReport.evaluate(evidence);

      expect(report.isPlayable, isFalse);
      expect(report.errors, hasLength(1));
      expect(
          report.errors.single.check, ProjectGameplayReadinessCheck.shopItems);
      expect(report.errors.single.summary, contains('inexploitable'));
    });

    test('duplicate evidence is rejected instead of laundering readiness', () {
      final report = ProjectGameplayReadinessReport.evaluate(
        <ProjectGameplayReadinessEvidence>[
          ..._passedEvidence(),
          const ProjectGameplayReadinessEvidence(
            check: ProjectGameplayReadinessCheck.eventCommands,
            status: ProjectGameplayReadinessEvidenceStatus.failed,
            summary: 'Une commande invalide contredit la preuve.',
            source: 'fixture:contradiction',
          ),
        ],
      );

      expect(report.isPlayable, isFalse);
      expect(report.errors, hasLength(1));
      expect(report.errors.single.check,
          ProjectGameplayReadinessCheck.eventCommands);
      expect(report.errors.single.summary, contains('contradictoires'));
    });
  });
}

List<ProjectGameplayReadinessEvidence> _passedEvidence() =>
    ProjectGameplayReadinessCheck.values
        .map(
          (check) => ProjectGameplayReadinessEvidence(
            check: check,
            status: ProjectGameplayReadinessEvidenceStatus.passed,
            summary: '${check.name} est vérifié.',
            source: 'reports/gameplay/proof.md',
          ),
        )
        .toList(growable: false);
```

