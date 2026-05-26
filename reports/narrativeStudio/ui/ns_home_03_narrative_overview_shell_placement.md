# NS-HOME-03 — Narrative Overview Shell Placement V0

## 1. Résumé exécutif

NS-HOME-03 branche une entrée minimale `Aperçu` dans le Narrative Studio existant.

Résultat :

- un mode `EditorWorkspaceMode.narrativeOverview` existe ;
- le shell éditeur route ce mode vers le Narrative Studio ;
- `NarrativeWorkspaceCanvas` affiche un nouveau `NarrativeOverviewWorkspace` ;
- l’écran V0 consomme `NarrativeOverviewReadModel` via `buildNarrativeOverviewReadModel(project: editor.project!)` ;
- l’écran affiche un titre, un sous-titre auteur, le nom projet, des disponibilités de données et un statut éditorial honnête ;
- `Non évalué` est affiché sans validator ;
- `Quêtes`, `Facts`, `Activité récente` et `Notifications` ne sont pas présentées comme données réelles ;
- aucun compteur de l’image n’est hardcodé ;
- aucune donnée Selbrume n’est hardcodée ;
- les studios existants restent accessibles.

Ce lot ne construit pas la page finale de l’image : pas de KPI cards premium, pas de grande carte Histoire principale, pas de grille complète de modules, pas de panneau droit Structure narrative, pas d’activité récente, pas de notifications et pas de top bar finale.

## 2. Rappel des décisions NS-HOME-01 / NS-HOME-02

Décisions reprises :

- la page `Aperçu` est un dashboard auteur, pas un dashboard runtime joueur ;
- les widgets ne doivent pas recalculer les métriques depuis `ProjectManifest` ;
- les widgets consomment le read model overview ;
- les données absentes doivent rester `outOfScope`, `needsModel`, `unavailable`, `empty` ou `notEvaluated` ;
- `À jour` n’est jamais produit sans validation ;
- les nombres de l’image ne doivent pas être recopiés ;
- Selbrume, `La brume du phare`, les tags de l’image et les activités de l’image ne doivent pas être codés.

## 3. Fichiers créés / modifiés

Fichiers créés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
reports/narrativeStudio/ui/ns_home_03_narrative_overview_shell_placement.md
```

Fichiers modifiés :

```text
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
```

Fichiers interdits non modifiés :

```text
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/**
```

## 4. Choix de branchement dans le shell

Choix retenu : nouveau mode `EditorWorkspaceMode.narrativeOverview`.

Raison :

- le shell existant route déjà les surfaces centrales via `EditorWorkspaceMode` ;
- `EditorCanvasHost` sait router les workspaces narratifs vers `NarrativeWorkspaceCanvas` ;
- `NarrativeWorkspaceCanvas` possède déjà la bande interne `Global Story / Step / Cutscene / Dialogue` ;
- ajouter `Aperçu` comme mode narratif est le plus petit branchement cohérent avec l’architecture actuelle.

Branchements :

- `EditorWorkspaceController.selectNarrativeOverviewWorkspace(...)` ouvre le mode ;
- `EditorNotifier.selectNarrativeOverviewWorkspace()` expose l’action aux widgets ;
- `EditorCanvasHost` route `narrativeOverview` vers `NarrativeWorkspaceCanvas` ;
- `NarrativeWorkspaceCanvas` ajoute le chip `Aperçu` et instancie `NarrativeOverviewWorkspace` ;
- `NarrativeLibraryPanel` expose `Aperçu` dans les quick actions ;
- `ProjectExplorerPanel`, `EditorShellPage`, `TopToolbar` et `editor_selectors.dart` connaissent le nouveau mode.

Le panneau droit est désactivé pour `narrativeOverview` dans `EditorShellPage`, car le panneau complet `Structure narrative` est explicitement hors scope de NS-HOME-03.

## 5. UI créée

Widget créé :

```text
NarrativeOverviewWorkspace
```

Contenu V0 affiché :

- titre `Aperçu` ;
- sous-titre `Vue d’ensemble auteur du Narrative Studio.` ;
- nom projet depuis `readModel.projectName` ;
- statut éditorial depuis `readModel.editorialStatus.validationState` ;
- project health depuis `readModel.projectHealth.healthKind` ;
- lignes de disponibilité depuis `readModel.metrics` et `readModel.recentActivity` / `readModel.notifications` ;
- message de limite V0 : `Les sections détaillées seront construites dans les lots suivants.`

Le widget ne lit pas directement `ProjectManifest.scenarios`, ne parse pas de metadata et ne crée aucun compteur.

## 6. Ce qui est volontairement absent de l’écran V0

Absent volontairement :

- les 6 KPI cards finales ;
- la carte complète `Histoire principale` ;
- les chips de chapitres finalisées ;
- la grille complète des modules narratifs ;
- le panneau droit `Structure narrative` ;
- l’activité récente réelle ;
- les notifications ;
- le footer final ;
- la top bar finale de l’image ;
- les actions globales finales `Nouvelle storyline`, `Aperçu`, `Valider` au format image ;
- toute copie pixel-perfect de l’image.

## 7. Tests ajoutés

Tests créés :

```text
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Couverture :

- l’écran `Aperçu` rend sans crash sur un projet minimal ;
- le nom projet vient du read model ;
- `Non évalué` apparaît sans validator ;
- `Selbrume`, `La brume du phare`, `42`, `1 236`, `1236` ne sont pas affichés ;
- `Quêtes`, `Facts`, `Activité récente`, `Notifications` restent honnêtement hors scope / needs model ;
- `NarrativeWorkspaceCanvas` route le mode overview vers le shell overview ;
- `NarrativeLibraryPanel` expose `Aperçu` ;
- les entrées `Histoire globale`, `Étape`, `Cinématique`, `Dialogue` restent visibles ;
- le tap sur `Aperçu` bascule vers `EditorWorkspaceMode.narrativeOverview`.

## 8. Commandes exécutées

Gate 0 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

RED :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Format :

```bash
cd packages/map_editor && dart format lib/src/features/editor/state/models/editor_workspace_mode.dart lib/src/features/editor/application/editor_workspace_controller.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/editor_selectors.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/panels/narrative_library_panel.dart lib/src/ui/panels/project_explorer_panel.dart lib/src/ui/editor_shell_page.dart lib/src/ui/shared/top_toolbar.dart test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Nettoyage mécanique du reflow non désiré :

```bash
python3 - <<'PY'
...
PY
```

Justification : `dart format` avait reflow des fichiers longs existants au-delà du changement réel. Le script a restauré le contenu HEAD de ces fichiers puis réappliqué uniquement les insertions NS-HOME-03.

GREEN ciblé :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Régressions ciblées :

```bash
cd packages/map_editor && flutter test test/editor_workspace_controller_test.dart test/editor_selectors_test.dart test/pokemon_catalogs_project_explorer_entry_test.dart test/top_toolbar_test.dart
```

Analyse globale :

```bash
cd packages/map_editor && flutter analyze
```

Analyse ciblée :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/features/editor/state/models/editor_workspace_mode.dart lib/src/features/editor/application/editor_workspace_controller.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/editor_selectors.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/panels/narrative_library_panel.dart lib/src/ui/panels/project_explorer_panel.dart lib/src/ui/editor_shell_page.dart lib/src/ui/shared/top_toolbar.dart test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Git :

```bash
git diff --check
git status --short --untracked-files=all
git diff --stat
git diff --name-only
```

## 9. Résultats des tests

### RED

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
test/ui/canvas/narrative_overview_workspace_test.dart:6:8: Error: Error when reading 'lib/src/ui/canvas/narrative_overview_workspace.dart': No such file or directory
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';
       ^
test/ui/canvas/narrative_overview_workspace_test.dart:24:24: Error: Method not found: 'NarrativeOverviewWorkspace'.
                child: NarrativeOverviewWorkspace(readModel: readModel),
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^
test/ui/canvas/narrative_overview_workspace_test.dart:62:24: Error: Method not found: 'NarrativeOverviewWorkspace'.
                child: NarrativeOverviewWorkspace(readModel: readModel),
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: test/ui/canvas/narrative_overview_workspace_test.dart:6:8: Error: Error when reading 'lib/src/ui/canvas/narrative_overview_workspace.dart': No such file or directory
  import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';
         ^
  test/ui/canvas/narrative_overview_workspace_test.dart:24:24: Error: Method not found: 'NarrativeOverviewWorkspace'.
                  child: NarrativeOverviewWorkspace(readModel: readModel),
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^
  test/ui/canvas/narrative_overview_workspace_test.dart:62:24: Error: Method not found: 'NarrativeOverviewWorkspace'.
                  child: NarrativeOverviewWorkspace(readModel: readModel),
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^
  .
  Error: The Dart compiler exited unexpectedly.
  package:flutter_tools/src/base/common.dart 34:3  throwToolExit
  package:flutter_tools/src/compile.dart 939:11    DefaultResidentCompiler._compile.<fn>
  dart:async/zone_root.dart 48:47                  _rootRunUnary
  dart:async/zone.dart 733:19                      _CustomZone.runUnary
  dart:async/future_impl.dart 948:45               Future._propagateToListeners.handleValueCallback
  dart:async/future_impl.dart 977:13               Future._propagateToListeners
  dart:async/future_impl.dart 862:9                Future._propagateToListeners
  dart:async/future_impl.dart 720:5                Future._completeWithValue
  dart:async/future_impl.dart 804:7                Future._asyncCompleteWithValue.<fn>
  dart:async/zone_root.dart 35:13                  _rootRun
  dart:async/zone.dart 726:19                      _CustomZone.run
  dart:async/zone.dart 625:7                       _CustomZone.runGuarded
  dart:async/zone.dart 666:23                      _CustomZone.bindCallbackGuarded.<fn>
  dart:async/schedule_microtask.dart 40:35         _microtaskLoop
  dart:async/schedule_microtask.dart 49:5          _startMicrotaskLoop
  dart:isolate-patch/isolate_patch.dart 127:13     _runPendingImmediateCallback
  dart:isolate-patch/isolate_patch.dart 194:5      _RawReceivePort._handleMessage
  
test/ui/canvas/narrative_overview_shell_navigation_test.dart:19:44: Error: Member not found: 'narrativeOverview'.
        workspaceMode: EditorWorkspaceMode.narrativeOverview,
                                           ^^^^^^^^^^^^^^^^^
test/ui/canvas/narrative_overview_shell_navigation_test.dart:88:29: Error: Member not found: 'narrativeOverview'.
        EditorWorkspaceMode.narrativeOverview,
                            ^^^^^^^^^^^^^^^^^
00:00 +0 -2: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: test/ui/canvas/narrative_overview_shell_navigation_test.dart:19:44: Error: Member not found: 'narrativeOverview'.
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
                                             ^^^^^^^^^^^^^^^^^
  test/ui/canvas/narrative_overview_shell_navigation_test.dart:88:29: Error: Member not found: 'narrativeOverview'.
          EditorWorkspaceMode.narrativeOverview,
                              ^^^^^^^^^^^^^^^^^
  .
00:00 +0 -2: Some tests failed.
```

### GREEN ciblé final

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeLibraryPanel exposes overview without removing existing studios
00:01 +4: All tests passed!
```

### Régressions ciblées

Sortie exacte :

```text
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokedexWorkspace switches mode and clears stale errors
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectTrainerWorkspace switches mode and clears stale errors
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectDialogueWorkspace keeps project session and only changes mode
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectEnvironmentStudioWorkspace switches mode and clears stale errors
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart: EditorWorkspaceController selectPokemonCatalogSection opens the parent workspace and stores the section
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorShellSnapshotProvider derives map title and save affordance
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorToolbarSnapshotProvider resolves selected tileset from layer
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors Path Studio snapshots hide map save and history actions
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorProjectExplorerSnapshotProvider exposes active map selection
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorShellSnapshotProvider exposes trainer studio labels
00:00 +9 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorShellSnapshotProvider exposes trainer studio labels [E]
  Expected: contains 'battle-ready rosters'
    Actual: 'Créez des dresseurs, des équipes et des listes prêtes au combat sans éditer de JSON brut.'
     Which: does not contain 'battle-ready rosters'
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test/editor_selectors_test.dart 154:7               main.<fn>.<fn>
  
00:00 +9 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorShellSnapshotProvider exposes Pokémon catalogs labels
00:00 +10 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorShellSnapshotProvider exposes clean Environment Studio labels
00:00 +11 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorTerrainLibrarySnapshotProvider exposes preset selection inputs
00:00 +12 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorTilesetPaletteSnapshotProvider exposes palette panel state
00:00 +13 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart: ProjectExplorerPanel shows Catalogues Pokémon with Pokédex, Moves and Items child entries
00:01 +14 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart: ProjectExplorerPanel taps update the active catalog section
00:01 +15 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the app brand and project workspace label
00:01 +16 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar falls back to the workspace label when no project is loaded
00:01 +17 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the toolbar status chip when a status is present
00:01 +18 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the trainer studio label for the trainer workspace
00:02 +19 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Path Studio
00:02 +20 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:02 +21 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar enables project save and disables map history in Environment Studio
00:02 +22 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows Environment Studio in the workspace brand strip
00:02 +23 -1: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar keeps map save action in map workspace
00:02 +24 -1: Some tests failed.
```

Conclusion sur cette régression : l’échec porte sur un libellé Trainer Studio déjà en français dans `editor_selectors.dart`. NS-HOME-03 n’a pas modifié cette branche `trainer`.

## 10. Limites

- `NarrativeOverviewWorkspace` est un shell V0, pas le dashboard final.
- Le widget affiche des lignes textuelles simples, pas des cards premium.
- Les diagnostics ne sont pas déclenchés depuis l’UI.
- Le read model est construit sans `NarrativeValidationReport`, donc le statut attendu est `Non évalué`.
- L’activité récente et les notifications restent hors scope V0.
- Le panneau droit final `Structure narrative` n’est pas encore créé.

## 11. Prochain lot recommandé

Prochain lot exact recommandé :

```text
NS-HOME-04 — Narrative Overview KPI Cards / Availability States V0
```

Objectif recommandé : transformer les lignes de disponibilité principales en premières cartes KPI honnêtes, branchées uniquement aux métriques du read model et avec états `available / empty / unavailable / notEvaluated / outOfScope / needsModel`.

## 12. Evidence Pack

### Branche courante

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

### Git status initial

Sortie :

```text
Sortie : <vide>
```

### Git diff --stat initial

Sortie :

```text
Sortie : <vide>
```

### Git diff --name-only initial

Sortie :

```text
Sortie : <vide>
```

### Git log initial

Sortie :

```text
0bc7bb9c docs: update narrative overview read model report
e0b389e7 feat(narrative-studio): add narrative overview read model
ef3224a0 docs: add narrative studio UI home overview data contract
6239b5fd docs: add narrative studio UI home overview roadmap proposal
0e2beef8 docs: add Phase 7 narrative studio information architecture and creator journey design
9a95f1b5 docs: add Phase 7 modern app shell and narrative studio UX inventory audit
1de262a2 docs: add Phase 7 roadmap bootstrap and narrative studio modern UI scope audit
1ca0154d docs: add Phase 7 roadmap and P6 checkpoint 01 Selbrume beta slice readiness review
f7612f05 feat(P6-08): add Selbrume playable runtime smoke tests and report
8258c5cb feat(P6-07): add Selbrume beta validator pass tests and report
```

### Sources lues

```text
AGENTS.md
agent_rules.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md
reports/narrativeStudio/ui/ns_home_01_overview_data_contract.md
reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/features/editor/state/editor_state.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
```

### Contenu complet du widget créé

```dart
import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Shell V0 de la page "Aperçu" du Narrative Studio.
///
/// Ce widget reste volontairement sobre : il prouve le point d'entrée UI et la
/// consommation du read model sans construire le dashboard final.
class NarrativeOverviewWorkspace extends StatelessWidget {
  const NarrativeOverviewWorkspace({
    super.key,
    required this.readModel,
  });

  final NarrativeOverviewReadModel readModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        Text(
          'Aperçu',
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Vue d’ensemble auteur du Narrative Studio.',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        _OverviewSection(
          title: 'Projet',
          children: [
            _OverviewLine(label: 'Nom', value: readModel.projectName),
            _OverviewLine(
              label: 'Statut éditorial',
              value: _editorialStatusLabel(
                readModel.editorialStatus.validationState,
              ),
            ),
            _OverviewLine(
              label: 'Project Health',
              value: _projectHealthLabel(readModel.projectHealth.healthKind),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _OverviewSection(
          title: 'Disponibilité des données principales',
          children: [
            _MetricLine(metric: readModel.metrics.dialogues),
            _MetricLine(metric: readModel.metrics.chapters),
            _MetricLine(metric: readModel.metrics.scenes),
            _MetricLine(metric: readModel.metrics.openIssues),
            _MetricLine(metric: readModel.metrics.quests),
            _MetricLine(metric: readModel.metrics.facts),
            _FeatureLine(feature: readModel.recentActivity),
            _FeatureLine(feature: readModel.notifications),
          ],
        ),
        const SizedBox(height: 12),
        const _OverviewSection(
          title: 'V0 volontairement limitée',
          children: [
            Text(
              'Les sections détaillées seront construites dans les lots suivants.',
            ),
            SizedBox(height: 6),
            Text(
              'Aucun compteur fake, aucune activité récente inventée, aucune notification simulée.',
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.metric});

  final NarrativeMetricSummary metric;

  @override
  Widget build(BuildContext context) {
    return Text('${metric.label} : ${_metricValue(metric)}');
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.feature});

  final NarrativeOverviewFeatureSummary feature;

  @override
  Widget build(BuildContext context) {
    return Text(
        '${feature.label} : ${_availabilityValue(feature.availability)}');
  }
}

class _OverviewLine extends StatelessWidget {
  const _OverviewLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text('$label : $value');
  }
}

String _metricValue(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${metric.count ?? 0}',
    _ => _availabilityValue(metric.availability),
  };
}

String _availabilityValue(NarrativeOverviewAvailability availability) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => 'disponible',
    NarrativeOverviewAvailability.empty => '0',
    NarrativeOverviewAvailability.unavailable => 'indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'non évalué',
    NarrativeOverviewAvailability.outOfScope => 'hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'nécessite un modèle',
  };
}

String _editorialStatusLabel(NarrativeEditorialValidationState state) {
  return switch (state) {
    NarrativeEditorialValidationState.notEvaluated => 'Non évalué',
    NarrativeEditorialValidationState.upToDate => 'À jour',
    NarrativeEditorialValidationState.toReview => 'À revoir',
    NarrativeEditorialValidationState.blocking => 'Bloquant',
  };
}

String _projectHealthLabel(NarrativeProjectHealthKind healthKind) {
  return switch (healthKind) {
    NarrativeProjectHealthKind.notEvaluated => 'Non évalué',
    NarrativeProjectHealthKind.healthy => 'Sain',
    NarrativeProjectHealthKind.reviewNeeded => 'À revoir',
    NarrativeProjectHealthKind.blocked => 'Bloqué',
  };
}
```

### Contenu complet des tests créés

`packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/overview/narrative_overview_read_model.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';

void main() {
  testWidgets(
    'NarrativeOverviewWorkspace renders a minimal authoring overview from the read model',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.light(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 900,
                height: 640,
                child: NarrativeOverviewWorkspace(readModel: readModel),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Aperçu'), findsOneWidget);
      expect(
        find.text('Vue d’ensemble auteur du Narrative Studio.'),
        findsOneWidget,
      );
      expect(find.textContaining('test_project'), findsOneWidget);
      expect(find.textContaining('Non évalué'), findsWidgets);
      expect(
        find.textContaining(
          'Les sections détaillées seront construites dans les lots suivants.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace does not present unavailable modules as real data',
    (tester) async {
      final readModel = buildNarrativeOverviewReadModel(
        project: _minimalProject('test_project'),
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.light(),
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 900,
                height: 640,
                child: NarrativeOverviewWorkspace(readModel: readModel),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Dialogues : 0'), findsOneWidget);
      expect(find.textContaining('Chapitres : 0'), findsOneWidget);
      expect(find.textContaining('Quêtes : hors scope V0'), findsOneWidget);
      expect(
          find.textContaining('Facts : nécessite un modèle'), findsOneWidget);
      expect(
        find.textContaining('Activité récente : hors scope V0'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Notifications : hors scope V0'),
        findsOneWidget,
      );

      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.textContaining('La brume du phare'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('1 236'), findsNothing);
      expect(find.text('1236'), findsNothing);
    },
  );
}

ProjectManifest _minimalProject(String name) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: name,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
  );
}
```

`packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/panels/narrative_library_panel.dart';

void main() {
  testWidgets(
    'NarrativeWorkspaceCanvas routes overview mode to the overview shell',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorNotifierProvider.overrideWith(
              () => _SeededEditorNotifier(
                EditorState(
                  workspaceMode: EditorWorkspaceMode.narrativeOverview,
                  project: _minimalProject('test_project'),
                ),
              ),
            ),
          ],
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 1000,
                  height: 720,
                  child: NarrativeWorkspaceCanvas(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Aperçu'), findsWidgets);
      expect(find.textContaining('test_project'), findsOneWidget);
      expect(find.textContaining('Non évalué'), findsWidgets);
      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.text('42'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'NarrativeLibraryPanel exposes overview without removing existing studios',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorNotifierProvider.overrideWith(
              () => _SeededEditorNotifier(
                EditorState(
                  workspaceMode: EditorWorkspaceMode.globalStory,
                  project: _minimalProject('test_project'),
                ),
              ),
            ),
          ],
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 360,
                  height: 640,
                  child: Column(
                    children: [
                      Expanded(child: NarrativeLibraryPanel(embedded: true)),
                      _WorkspaceModeProbe(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Aperçu'), findsOneWidget);
      expect(find.text('Histoire globale'), findsOneWidget);
      expect(find.text('Étape'), findsOneWidget);
      expect(find.text('Cinématique'), findsOneWidget);
      expect(find.text('Dialogue'), findsOneWidget);

      await tester.tap(find.text('Aperçu'));
      await tester.pumpAndSettle();

      expect(
        find.text('workspace:narrativeOverview'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}

ProjectManifest _minimalProject(String name) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: name,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
  );
}

class _WorkspaceModeProbe extends ConsumerWidget {
  const _WorkspaceModeProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(editorNotifierProvider).workspaceMode;
    return Text('workspace:${mode.name}');
  }
}

class _SeededEditorNotifier extends EditorNotifier {
  _SeededEditorNotifier(this.initialState);

  final EditorState initialState;

  @override
  EditorState build() {
    return initialState;
  }
}
```

### Analyse globale

Résultat : échec global sur dette préexistante hors NS-HOME-03.

Extrait pertinent :

```text
Analyzing map_editor...

  error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
  error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
  error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
  error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
  error • The named parameter 'studioFlags' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 • undefined_named_parameter
  error • The named parameter 'battleStageMods' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:75:7 • undefined_named_parameter
  error • The named parameter 'moveStatuses' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:76:7 • undefined_named_parameter
  error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
  error • Undefined class 'PokemonMoveFlags' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:284:3 • undefined_class
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name

348 issues found. (ran in 3.1s)
```

Les erreurs globales concernent les services Pokémon SDK / Pokédex et non les fichiers NS-HOME-03.

### Analyse ciblée

Sortie exacte :

```text
Analyzing 13 items...


   info • Use 'const' with the constructor to improve performance • lib/src/ui/canvas/narrative_workspace_canvas.dart:423:32 • prefer_const_constructors

1 issue found. (ran in 1.4s)
```

La commande a terminé avec code 0 grâce à `--no-fatal-infos`. L’info restante est une suggestion `const` sur un `Icon` existant dans `narrative_workspace_canvas.dart`, hors changement fonctionnel NS-HOME-03.

### Git diff --check

Sortie :

```text
Sortie : <vide>
```

### Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
?? packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
?? packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? reports/narrativeStudio/ui/ns_home_03_narrative_overview_shell_placement.md
```

### Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../editor/application/editor_workspace_controller.dart  |  4 ++++
 .../lib/src/features/editor/state/editor_notifier.dart   |  8 ++++++++
 .../lib/src/features/editor/state/editor_selectors.dart  |  3 +++
 .../editor/state/models/editor_workspace_mode.dart       |  1 +
 .../map_editor/lib/src/ui/canvas/editor_canvas_host.dart |  1 +
 .../lib/src/ui/canvas/narrative_workspace_canvas.dart    | 16 ++++++++++++++++
 packages/map_editor/lib/src/ui/editor_shell_page.dart    | 10 ++++++++++
 .../lib/src/ui/panels/narrative_library_panel.dart       |  8 ++++++++
 .../lib/src/ui/panels/project_explorer_panel.dart        |  3 ++-
 packages/map_editor/lib/src/ui/shared/top_toolbar.dart   | 10 ++++++++++
 10 files changed, 63 insertions(+), 1 deletion(-)
```

Note : les fichiers créés sont non suivis, donc ils apparaissent dans `git status` mais pas dans `git diff --stat`.

### Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
```

### Extraits complets des modifications suivies

```diff
diff --git a/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart b/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
index 031af05c..d715f840 100644
--- a/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
+++ b/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
@@ -42,6 +42,10 @@ class EditorWorkspaceController {
     return _openWorkspace(current, EditorWorkspaceMode.trainer);
   }
 
+  EditorState selectNarrativeOverviewWorkspace(EditorState current) {
+    return _openWorkspace(current, EditorWorkspaceMode.narrativeOverview);
+  }
+
   EditorState selectGlobalStoryWorkspace(EditorState current) {
     return _openWorkspace(current, EditorWorkspaceMode.globalStory);
   }
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index c43e01fe..bb67057e 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -1515,6 +1515,14 @@ class EditorNotifier extends _$EditorNotifier {
     state = _editorWorkspaceController.selectTrainerWorkspace(state);
   }
 
+  /// Ouvre le workspace central "Aperçu" du Narrative Studio.
+  ///
+  /// Navigation pure de shell : les données affichées sont dérivées par le
+  /// read model overview, pas recalculées dans le notifier.
+  void selectNarrativeOverviewWorkspace() {
+    state = _editorWorkspaceController.selectNarrativeOverviewWorkspace(state);
+  }
+
   /// Ouvre le workspace central "Global Story".
   ///
   /// Ce changement est purement une navigation d'espace de travail:
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart b/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
index 5a3181bd..31e0b91d 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
@@ -147,6 +147,7 @@ final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
     EditorWorkspaceMode.tileset => selectedTileset?.name ?? 'Tileset Studio',
     EditorWorkspaceMode.trainer => 'Trainer Studio',
     EditorWorkspaceMode.pokedex => 'Catalogues Pokémon',
+    EditorWorkspaceMode.narrativeOverview => 'Narrative Studio / Aperçu',
     EditorWorkspaceMode.globalStory => 'Global Story Workspace',
     EditorWorkspaceMode.step => 'Step Studio',
     EditorWorkspaceMode.cutscene => 'Cutscene Studio',
@@ -166,6 +167,8 @@ final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
       'Créez des dresseurs, des équipes et des listes prêtes au combat sans éditer de JSON brut.',
     EditorWorkspaceMode.pokedex =>
       'Pokédex, Moves et Items réunis dans un même pôle de catalogues Pokémon.',
+    EditorWorkspaceMode.narrativeOverview =>
+      'Vue d’ensemble auteur : métriques disponibles, statuts honnêtes et prochaines sections du dashboard.',
     EditorWorkspaceMode.globalStory =>
       'Progression narrative macro : arcs, jalons et branches de haut niveau.',
     EditorWorkspaceMode.step =>
diff --git a/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart b/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
index 7cda6500..1fd3b8d6 100644
--- a/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
+++ b/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
@@ -30,6 +30,7 @@ enum EditorWorkspaceMode {
   //   premier plan (pas comme des "petits panneaux" latéraux).
   // - la colonne gauche sert à naviguer/ouvrir.
   // - la colonne droite sert à inspecter le contexte sélectionné.
+  narrativeOverview,
   globalStory,
   step,
   cutscene,
diff --git a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
index 5fb0e2be..94dfa86e 100644
--- a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
+++ b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
@@ -23,6 +23,7 @@ class EditorCanvasHost extends ConsumerWidget {
       EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
       EditorWorkspaceMode.trainer => const TrainerLibraryPanel(),
       EditorWorkspaceMode.pokedex => const PokemonCatalogsWorkspace(),
+      EditorWorkspaceMode.narrativeOverview ||
       EditorWorkspaceMode.globalStory ||
       EditorWorkspaceMode.step ||
       EditorWorkspaceMode.cutscene ||
diff --git a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
index db77b3a8..620beee5 100644
--- a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
@@ -4,6 +4,7 @@ import 'package:map_core/map_core.dart';
 
 import '../../features/editor/state/editor_notifier.dart';
 import '../../features/editor/state/editor_state.dart';
+import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
 import '../../features/narrative/application/narrative_workspace_projection.dart';
 import '../../features/narrative/state/narrative_workspace_providers.dart';
 import '../../features/narrative/state/narrative_workspace_state.dart';
@@ -11,6 +12,7 @@ import '../shared/cupertino_editor_widgets.dart';
 import 'cutscene_studio_workspace.dart';
 import 'dialogue_studio_workspace.dart';
 import 'global_story_studio_workspace.dart';
+import 'narrative_overview_workspace.dart';
 import 'step_studio_workspace.dart';
 
 /// Workspace central du studio narratif.
@@ -72,6 +74,7 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget {
       children: [
         _NarrativeModeStrip(
           workspaceMode: editor.workspaceMode,
+          onSelectOverview: editorNotifier.selectNarrativeOverviewWorkspace,
           onSelectGlobal: () {
             editorNotifier.selectGlobalStoryWorkspace();
             narrativeController.openGlobalStory(
@@ -96,6 +99,11 @@ class NarrativeWorkspaceCanvas extends ConsumerWidget {
         const SizedBox(height: 12),
         Expanded(
           child: switch (editor.workspaceMode) {
+            EditorWorkspaceMode.narrativeOverview => NarrativeOverviewWorkspace(
+                readModel: buildNarrativeOverviewReadModel(
+                  project: editor.project!,
+                ),
+              ),
             EditorWorkspaceMode.globalStory => GlobalStoryStudioWorkspace(
                 editorNotifier: editorNotifier,
                 project: editor.project,
@@ -218,6 +226,7 @@ NarrativeStepSummary? _resolveStepById(
 class _NarrativeModeStrip extends StatelessWidget {
   const _NarrativeModeStrip({
     required this.workspaceMode,
+    required this.onSelectOverview,
     required this.onSelectGlobal,
     required this.onSelectStep,
     required this.onSelectCutscene,
@@ -225,6 +234,7 @@ class _NarrativeModeStrip extends StatelessWidget {
   });
 
   final EditorWorkspaceMode workspaceMode;
+  final VoidCallback onSelectOverview;
   final VoidCallback onSelectGlobal;
   final VoidCallback onSelectStep;
   final VoidCallback onSelectCutscene;
@@ -234,6 +244,12 @@ class _NarrativeModeStrip extends StatelessWidget {
   Widget build(BuildContext context) {
     return Row(
       children: [
+        _ModeChip(
+          label: 'Aperçu',
+          selected: workspaceMode == EditorWorkspaceMode.narrativeOverview,
+          onTap: onSelectOverview,
+        ),
+        const SizedBox(width: 8),
         _ModeChip(
           label: 'Global Story',
           selected: workspaceMode == EditorWorkspaceMode.globalStory,
diff --git a/packages/map_editor/lib/src/ui/editor_shell_page.dart b/packages/map_editor/lib/src/ui/editor_shell_page.dart
index a3538ca9..6023b4ff 100644
--- a/packages/map_editor/lib/src/ui/editor_shell_page.dart
+++ b/packages/map_editor/lib/src/ui/editor_shell_page.dart
@@ -101,6 +101,7 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage>
     final workspaceMode = shell.workspaceMode;
     final notifier = ref.read(editorNotifierProvider.notifier);
     final supportsRightInspector = switch (workspaceMode) {
+      EditorWorkspaceMode.narrativeOverview => false,
       EditorWorkspaceMode.pokedex => false,
       EditorWorkspaceMode.pathStudio => false,
       EditorWorkspaceMode.environmentStudio => false,
@@ -122,6 +123,7 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage>
     });
 
     final isNarrativeWorkspace = switch (workspaceMode) {
+      EditorWorkspaceMode.narrativeOverview ||
       EditorWorkspaceMode.globalStory ||
       EditorWorkspaceMode.step ||
       EditorWorkspaceMode.cutscene ||
@@ -461,6 +463,8 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage>
                                                   EditorChrome.islandWarmTint,
                                                 EditorWorkspaceMode.pokedex =>
                                                   EditorChrome.islandWarmTint,
+                                                EditorWorkspaceMode.narrativeOverview =>
+                                                  EditorChrome.islandCoolTint,
                                                 EditorWorkspaceMode.globalStory =>
                                                   EditorChrome.islandCoolTint,
                                                 EditorWorkspaceMode.step =>
@@ -483,6 +487,8 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage>
                                                   const _EmptyWorkspaceInspector(),
                                                 EditorWorkspaceMode.pokedex =>
                                                   const _EmptyWorkspaceInspector(),
+                                                EditorWorkspaceMode.narrativeOverview =>
+                                                  const _EmptyWorkspaceInspector(),
                                                 EditorWorkspaceMode.pathStudio =>
                                                   const _EmptyWorkspaceInspector(),
                                                 EditorWorkspaceMode.environmentStudio =>
@@ -627,6 +633,7 @@ class _WorkspaceStageHeader extends ConsumerWidget {
       EditorWorkspaceMode.tileset => colors.brandCyan,
       EditorWorkspaceMode.trainer => colors.combat,
       EditorWorkspaceMode.pokedex => colors.reward,
+      EditorWorkspaceMode.narrativeOverview ||
       EditorWorkspaceMode.globalStory ||
       EditorWorkspaceMode.step ||
       EditorWorkspaceMode.cutscene ||
@@ -640,6 +647,7 @@ class _WorkspaceStageHeader extends ConsumerWidget {
       EditorWorkspaceMode.tileset => PokeMapBadgeVariant.neutral,
       EditorWorkspaceMode.trainer => PokeMapBadgeVariant.combat,
       EditorWorkspaceMode.pokedex => PokeMapBadgeVariant.info,
+      EditorWorkspaceMode.narrativeOverview ||
       EditorWorkspaceMode.globalStory ||
       EditorWorkspaceMode.step ||
       EditorWorkspaceMode.cutscene ||
@@ -652,6 +660,7 @@ class _WorkspaceStageHeader extends ConsumerWidget {
       EditorWorkspaceMode.tileset => 'Bibliothèque',
       EditorWorkspaceMode.trainer => 'Dresseurs',
       EditorWorkspaceMode.pokedex => 'Catalogues',
+      EditorWorkspaceMode.narrativeOverview => 'Aperçu',
       EditorWorkspaceMode.globalStory => 'Macro-Récit',
       EditorWorkspaceMode.step => 'Étapes',
       EditorWorkspaceMode.cutscene => 'Cinématiques',
@@ -796,6 +805,7 @@ class _WorkspaceStageHeader extends ConsumerWidget {
               EditorWorkspaceMode.tileset => CupertinoIcons.square_grid_2x2,
               EditorWorkspaceMode.trainer => CupertinoIcons.person_3_fill,
               EditorWorkspaceMode.pokedex => CupertinoIcons.book,
+              EditorWorkspaceMode.narrativeOverview => CupertinoIcons.house,
               EditorWorkspaceMode.globalStory => CupertinoIcons.link,
               EditorWorkspaceMode.step => CupertinoIcons.flag,
               EditorWorkspaceMode.cutscene => CupertinoIcons.play_rectangle,
diff --git a/packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart b/packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
index f0b27bf4..a695ae08 100644
--- a/packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
@@ -58,6 +58,7 @@ class NarrativeLibraryPanel extends ConsumerWidget {
       children: [
         _WorkspaceQuickActions(
           editor: editor,
+          onOverview: notifier.selectNarrativeOverviewWorkspace,
           onGlobal: () {
             notifier.selectGlobalStoryWorkspace();
             narrativeController.openGlobalStory(
@@ -184,6 +185,7 @@ class NarrativeLibraryPanel extends ConsumerWidget {
 class _WorkspaceQuickActions extends StatelessWidget {
   const _WorkspaceQuickActions({
     required this.editor,
+    required this.onOverview,
     required this.onGlobal,
     required this.onStep,
     required this.onCutscene,
@@ -191,6 +193,7 @@ class _WorkspaceQuickActions extends StatelessWidget {
   });
 
   final EditorState editor;
+  final VoidCallback onOverview;
   final VoidCallback onGlobal;
   final VoidCallback onStep;
   final VoidCallback onCutscene;
@@ -202,6 +205,11 @@ class _WorkspaceQuickActions extends StatelessWidget {
       spacing: 6,
       runSpacing: 6,
       children: [
+        _ActionChip(
+          label: 'Aperçu',
+          selected: editor.workspaceMode == EditorWorkspaceMode.narrativeOverview,
+          onTap: onOverview,
+        ),
         _ActionChip(
           label: 'Histoire globale',
           selected: editor.workspaceMode == EditorWorkspaceMode.globalStory,
diff --git a/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart b/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
index 82f37c97..52e19e31 100644
--- a/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
@@ -348,7 +348,8 @@ class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
           icon: CupertinoIcons.link_circle_fill,
           accentColor: colors.narrative,
           count: project.scenarios.length,
-          selected: snapshot.workspaceMode == EditorWorkspaceMode.globalStory ||
+          selected: snapshot.workspaceMode == EditorWorkspaceMode.narrativeOverview ||
+              snapshot.workspaceMode == EditorWorkspaceMode.globalStory ||
               snapshot.workspaceMode == EditorWorkspaceMode.step ||
               snapshot.workspaceMode == EditorWorkspaceMode.cutscene ||
               snapshot.workspaceMode == EditorWorkspaceMode.dialogue,
diff --git a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
index e1536c9a..c0ca9bda 100644
--- a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
+++ b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
@@ -435,6 +435,15 @@ class TopToolbar extends ConsumerWidget {
                 ? notifier.selectPokedexWorkspace
                 : null,
           ),
+          ToolbarCapsuleButton(
+            icon: CupertinoIcons.house,
+            tooltip: 'Switch to Narrative Overview',
+            selected:
+                toolbar.workspaceMode == EditorWorkspaceMode.narrativeOverview,
+            onPressed: toolbar.project != null
+                ? notifier.selectNarrativeOverviewWorkspace
+                : null,
+          ),
           ToolbarCapsuleButton(
             icon: CupertinoIcons.link,
             tooltip: 'Switch to global story workspace',
@@ -519,6 +528,7 @@ class TopToolbar extends ConsumerWidget {
           EditorWorkspaceMode.tileset => 'Tileset Studio',
           EditorWorkspaceMode.trainer => 'Trainer Studio',
           EditorWorkspaceMode.pokedex => 'Catalogues Pokémon',
+          EditorWorkspaceMode.narrativeOverview => 'Narrative Overview',
           EditorWorkspaceMode.globalStory => 'Global Story',
           EditorWorkspaceMode.step => 'Step Studio',
           EditorWorkspaceMode.cutscene => 'Cutscene Studio',
```

## 13. Auto-review critique

Ai-je codé la page finale de l’image ?

Réponse : non. J’ai créé un shell V0 minimal.

Ai-je créé toute la grille KPI / modules / panneau droit ?

Réponse : non.

Ai-je consommé `NarrativeOverviewReadModel` ?

Réponse : oui, via `buildNarrativeOverviewReadModel(project: editor.project!)` dans `NarrativeWorkspaceCanvas`, puis `NarrativeOverviewWorkspace(readModel: ...)`.

Ai-je évité les faux compteurs ?

Réponse : oui. Les seules valeurs numériques affichées viennent du read model. Les données hors scope restent libellées comme telles.

Ai-je hardcodé Selbrume ou les chiffres de l’image ?

Réponse : non. Les tests vérifient l’absence de `Selbrume`, `La brume du phare`, `42`, `1 236`, `1236`.

Ai-je modifié runtime/gameplay/battle/map_core ?

Réponse : non.

Ai-je gardé les studios existants ?

Réponse : oui. `Histoire globale`, `Étape`, `Cinématique`, `Dialogue` restent visibles dans `NarrativeLibraryPanel`.

Ai-je lancé build_runner ?

Réponse : non.

Ai-je fait un commit ou stage ?

Réponse : non.

## 14. Regard critique sur le prompt

Le prompt est clair sur la frontière : ouvrir le point d’entrée sans construire le dashboard final. La seule tension est la mention de navigation / top bar : j’ai interprété l’ajout dans `TopToolbar` comme une entrée de workspace existante, pas comme la top bar finale de l’image. La top bar premium avec `Nouvelle storyline`, `Aperçu`, `Valider`, recherche et notifications reste hors scope.
