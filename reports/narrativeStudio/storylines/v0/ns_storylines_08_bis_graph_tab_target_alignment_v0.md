# NS-STORYLINES-08-bis — Graph Tab Target Alignment / Default View V0

## 1. Executive summary

NS-STORYLINES-08-bis est livré.

Le Graph reste la vue par défaut du workspace Storylines et se rapproche davantage de l'image cible : canvas sombre dominant, grille subtile, flux principal, nodes macro de chapitres réels, previews de steps réelles, légende et contrôles read-only non actifs.

Aucun modèle métier, provider, runtime, gameplay, battle ou donnée core n'a été modifié. La tab `Chapitres` NS08 continue de fonctionner, les tabs futures restent non mutantes, et aucune donnée Selbrume cible n'est introduite.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md`
- `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_02_current_global_story_characterization_anti_fake_tests_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_03_storylines_workspace_shell_layout_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_03_bis_disabled_header_actions_dark_visual_gate_hardening.md`
- `reports/narrativeStudio/storylines/ns_storylines_04_secondary_list_panel_read_only_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`
- `packages/map_editor/lib/src/theme/theme.dart`
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart`
- cible image locale `/Users/karim/Desktop/assets/pokeMap/définitive/1 - storyline/1 - global storyline.png`
- skill `superpowers:test-driven-development`
- skill `superpowers:verification-before-completion`

Fichiers absents mais attendus :

```text
Sortie : <vide>
```

## 3. Visual issue summary

Le Graph NS06/NS08 restait trop proche d'une liste de cards verticale. Le problème corrigé ici : rendre l'onglet `Graph` plus central, plus visuel, plus proche de la composition cible, sans transformer l'image en source de données.

## 4. Implementation summary

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

Fichiers créés :

- `reports/narrativeStudio/storylines/ns_storylines_08_bis_graph_tab_target_alignment_v0.md`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_center.png`

Changements principaux :

- `_StorylineGraphSection` affiche maintenant `storylines-graph-target-read-only`.
- Ajout d'un canvas graph feature-specific avec key `storylines-graph-canvas`.
- Ajout d'un flux principal `storylines-graph-main-flow`.
- Les chapitres réels deviennent des nodes macro quand `NarrativeChapterSummary` est disponible.
- Les steps réelles apparaissent comme preview dans les nodes de chapitres.
- Fallback par steps réelles si aucun chapitre n'est disponible.
- Empty state honnête conservé si aucune step n'existe.
- Légende read-only `storylines-graph-legend`.
- Ligne de contrôles non actifs `Mini-map et zoom à venir`.
- KPI strip rendu horizontalement scrollable pour éviter que les KPI repoussent le graph hors de la vue par défaut sur widths réduites.

## 5. Target image interpretation

Target image used as visual/layout reference only, never as data source.

Interprétation appliquée :

- composition générale dark premium ;
- graph central plus dominant ;
- canvas sombre avec grille subtile ;
- nodes espacés ;
- lecture gauche vers droite ;
- légende / note read-only ;
- conservation du panneau secondaire, header, tabs, KPI et inspecteur.

Interprétation explicitement refusée :

- noms Selbrume ;
- quêtes annexes cible ;
- chiffres cible ;
- tags ;
- world rules ;
- activité récente ;
- statuts `Active`, `Haute`, `Défini` ;
- mini-map ou zoom actifs fake.

## 6. Graph layout behavior

Comportement livré :

- `Graph` reste actif par défaut.
- Le graph affiche une surface `storylines-graph-canvas` avec grille tokenisée via `context.pokeMapColors`.
- `storylines-graph-main-flow` contient : `Début de lecture`, nodes de chapitres réels, connecteurs simples, note `Relations à venir`.
- Chaque node chapitre affiche `Chapitre N`, le titre réel du chapitre, la description réelle si présente, le nombre réel d'étapes et les previews des steps réelles.
- Si aucun chapitre n'est disponible mais des steps existent, le graph affiche des nodes de steps réelles.
- Si aucune step n'est disponible, le graph affiche `Aucune étape narrative disponible pour cette storyline.`
- La tab `Chapitres` reste accessible et affiche `storylines-chapters-read-only`.

## 7. Data source / anti-fake guarantees

Données affichées positives :

- `NarrativeChapterSummary.name`
- `NarrativeChapterSummary.description`
- `NarrativeChapterSummary.order`
- `NarrativeChapterSummary.steps`
- `NarrativeStepSummary.name`
- `NarrativeStepSummary.description`
- compteurs dérivés de `chapters.length`, `chapter.steps.length`, `steps.length`

Garanties :

- aucun `localEventFlow` dans le graph ;
- aucune quête annexe fake ;
- aucun nom Selbrume cible ;
- aucun chiffre cible `5 chapitres`, `27 scènes`, `412 dialogues`, `18 facts`, `3 problèmes` ;
- aucune branche conditionnelle inventée ;
- aucune ligne optionnelle fake ;
- aucune mini-map active ;
- aucun zoom actif.

## 8. Disabled interactions

Interactions absentes ou non actives :

- pas de création de storyline ;
- pas de validation globale ;
- pas de bouton `+` actif ;
- pas de création de chapitre ;
- pas de drag/drop ;
- pas d'édition node/edge ;
- pas de mini-map active ;
- pas de zoom actif ;
- tabs `Étapes`, `Scènes`, `Statistiques`, `Tests` non mutantes.

## 9. Design System Gate

Gate respecté :

- surfaces : `PokeMapPageSurface`, `PokeMapCard` ;
- primitives : `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapMetricCard`, `PokeMapSegmentedTabs` ;
- tons : `PokeMapTone` ;
- couleurs : `context.pokeMapColors` uniquement ;
- grid painter feature-specific avec couleurs injectées depuis tokens ;
- aucun `Color(0x...)` ajouté ;
- aucun `Colors.*` ajouté ;
- aucun composant générique local hors design system.

Recherche couleur :

```text
Commande : rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
Sortie : <vide>
```

## 10. Tests added or modified

Tests modifiés dans `packages/map_editor/test/storylines_workspace_shell_test.dart` :

- le test shell cherche `storylines-graph-target-read-only` ;
- vérifie `storylines-graph-canvas` ;
- vérifie `storylines-graph-main-flow` ;
- vérifie les nodes `storylines-graph-node-audit_chapter` et `storylines-graph-node-audit_second_chapter` ;
- vérifie `storylines-graph-legend` ;
- vérifie que les chapitres et steps neutres de fixture apparaissent dans le graph par défaut ;
- vérifie que `storylines-chapters-read-only` reste accessible après clic `Chapitres` ;
- maintient les garanties anti-fake, localEventFlow absent, actions/tabs non mutantes, dark theme harness, no silent taps, color guard.

TDD RED observé :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-08-bis Graph target alignment V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'storylines-graph-target-read-only'>]: []>
00:01 +7 -4: Some tests failed.
```

## 11. Visual Gate

Captures créées :

```text
-rw-r--r--  1 karim  staff  52993 May 28 14:36 reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_center.png
-rw-r--r--  1 karim  staff  63841 May 28 14:36 reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_desktop.png
-rw-r--r--  1 karim  staff  47931 May 28 14:36 reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_focus.png
```

Résultat :

- dark theme actif via harness PokeMap ;
- shell complet conservé ;
- onglet Graph actif ;
- graph cible visible ;
- nodes de chapitres réels visibles ;
- steps réelles visibles dans les nodes ;
- canvas sombre avec grille ;
- aucune donnée cible fake ;
- pas d'overflow lors du test golden final.

## 12. Roadmap update

Roadmap mise à jour :

- `NS-STORYLINES-08` reste `DONE` ;
- ajout d'une note `NS-STORYLINES-08-bis` ;
- fichiers modifiés / créés listés ;
- tests et analyse listés ;
- Visual Gate listé ;
- Design System Gate confirmé ;
- absence de fake data confirmée ;
- prochain lot inchangé : `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

## 13. Commands run

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
dart format test/storylines_workspace_shell_test.dart && flutter test test/storylines_workspace_shell_test.dart
dart format lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart && flutter test test/storylines_workspace_shell_test.dart
flutter test --update-goldens test/storylines_workspace_shell_test.dart
flutter test test/storylines_workspace_shell_test.dart
flutter test test/storylines_current_global_story_characterization_test.dart
flutter test test/narrative_workspace_projection_test.dart
flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

## 14. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
Sortie : <vide>
```

### Git diff --stat initial

```text
Sortie : <vide>
```

### Git diff --name-only initial

```text
Sortie : <vide>
```

### Git diff --check initial

```text
Sortie : <vide>
```

### Liste des fichiers lus

Voir section 2.

### Liste des fichiers absents mais attendus

```text
Sortie : <vide>
```

### Git status final exact après création du rapport

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_08_bis_graph_tab_target_alignment_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_focus.png
```

### Git diff --stat final au moment de création du rapport

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 862 ++++++++++++++++-----
 .../test/storylines_workspace_shell_test.dart      |  88 ++-
 .../storylines/road_map_storylines.md              |  31 +-
 3 files changed, 788 insertions(+), 193 deletions(-)
```

### Git diff --name-only final au moment de création du rapport

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final au moment de création du rapport

```text
Sortie : <vide>
```

### Sortie exacte — flutter test test/storylines_workspace_shell_test.dart

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-08-bis Graph target alignment V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-08-bis Graph target alignment V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-08-bis Graph target alignment V0 shows the Chapters tab from Global Story Studio metadata read-only
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +3: NS-STORYLINES-08-bis Graph target alignment V0 shows an honest Chapters empty state
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:01 +4: NS-STORYLINES-08-bis Graph target alignment V0 renders an honest inspector empty state without global story
00:01 +5: NS-STORYLINES-08-bis Graph target alignment V0 keeps future Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +6: NS-STORYLINES-08-bis Graph target alignment V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +7: NS-STORYLINES-08-bis Graph target alignment V0 storylines UI source keeps raw colors out of the feature
00:01 +8: NS-STORYLINES-08-bis Graph target alignment V0 storylines action test does not use silent taps
00:01 +9: NS-STORYLINES-08-bis Graph target alignment V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +10: NS-STORYLINES-08-bis Graph target alignment V0 writes Visual Gate screenshots
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +11: All tests passed!
```

### Sortie exacte — flutter test test/storylines_current_global_story_characterization_test.dart

```text
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

### Sortie exacte — flutter test test/narrative_workspace_projection_test.dart

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:00 +3: All tests passed!
```

### Sortie exacte — analyse ciblée

```text
Analyzing 4 items...                                            

No issues found! (ran in 2.5s)
```

### Résultats Visual Gate

```text
-rw-r--r--  1 karim  staff  52993 May 28 14:36 reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_center.png
-rw-r--r--  1 karim  staff  63841 May 28 14:36 reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_desktop.png
-rw-r--r--  1 karim  staff  47931 May 28 14:36 reports/narrativeStudio/storylines/screenshots/ns_storylines_08_bis_graph_target_focus.png
```

### Mini audit Design System

- Aucune couleur hardcodée ajoutée dans les fichiers touchés.
- `_StorylineGraphCanvas`, `_StorylineGraphChapterNode`, `_StorylineGraphStepNode`, `_StorylineGraphLegend` et `_StorylineGraphReadOnlyControls` sont feature-specific.
- Les edges simples utilisent `Icon(CupertinoIcons.arrow_right)` et `colors.textMuted`.
- La grille utilise un `CustomPainter` feature-specific avec `colors.borderSubtle` et `colors.brandPrimaryBorder` injectés depuis `context.pokeMapColors`.

### Recherche Color / Colors

```text
Sortie : <vide>
```

### Diff complet des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 34d69145..6c148455 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -389,7 +389,10 @@ class _StorylineMainPanel extends StatelessWidget {
           Expanded(
             child: selectedTab == _StorylineContentTab.chapters
                 ? _StorylineChaptersSection(chapters: chapters)
-                : _StorylineGraphSection(steps: steps),
+                : _StorylineGraphSection(
+                    chapters: chapters,
+                    steps: steps,
+                  ),
           ),
         ],
       ),
@@ -404,50 +407,321 @@ enum _StorylineContentTab {
 
 class _StorylineGraphSection extends StatelessWidget {
   const _StorylineGraphSection({
+    required this.chapters,
     required this.steps,
   });
 
+  final List<NarrativeChapterSummary> chapters;
   final List<NarrativeStepSummary> steps;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final hasChapters = chapters.isNotEmpty;
     return PokeMapPageSurface(
-      key: const ValueKey('storylines-graph-read-only'),
+      key: const ValueKey('storylines-graph-target-read-only'),
       padding: const EdgeInsets.all(18),
-      child: SingleChildScrollView(
+      child: LayoutBuilder(
+        builder: (context, constraints) {
+          final availableCanvasHeight = constraints.maxHeight.isFinite
+              ? constraints.maxHeight - 132
+              : 380.0;
+          final canvasHeight =
+              availableCanvasHeight < 320 ? 320.0 : availableCanvasHeight;
+          return SingleChildScrollView(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.stretch,
+              children: [
+                Row(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    const PokeMapIconTile(
+                      icon: CupertinoIcons.arrow_branch,
+                      tone: PokeMapTone.narrative,
+                      size: 38,
+                      iconSize: 18,
+                    ),
+                    const SizedBox(width: 12),
+                    Expanded(
+                      child: Column(
+                        crossAxisAlignment: CrossAxisAlignment.start,
+                        children: [
+                          Text(
+                            'Graph read-only',
+                            style: TextStyle(
+                              color: colors.textPrimary,
+                              fontSize: 15,
+                              fontWeight: FontWeight.w800,
+                            ),
+                          ),
+                          const SizedBox(height: 6),
+                          Text(
+                            hasChapters
+                                ? 'Canvas de lecture macro des chapitres réels. Les steps restent visibles en aperçu, sans relations inventées.'
+                                : 'Lecture linéaire prudente des étapes disponibles. Les relations détaillées restent non branchées.',
+                            style: TextStyle(
+                              color: colors.textSecondary,
+                              fontSize: 12.5,
+                              height: 1.35,
+                            ),
+                          ),
+                        ],
+                      ),
+                    ),
+                  ],
+                ),
+                const SizedBox(height: 14),
+                Wrap(
+                  spacing: 10,
+                  runSpacing: 10,
+                  children: [
+                    PokeMapStatusTile(
+                      label: hasChapters
+                          ? 'Chapitres réels'
+                          : 'Étapes narratives réelles',
+                      value: hasChapters
+                          ? '${chapters.length}'
+                          : '${steps.length}',
+                      icon: hasChapters
+                          ? CupertinoIcons.square_list
+                          : CupertinoIcons.list_bullet,
+                      tone: PokeMapTone.info,
+                    ),
+                    const PokeMapStatusTile(
+                      label: 'Source',
+                      value: 'Global Story Studio / Step Studio',
+                      icon: CupertinoIcons.doc_text,
+                      tone: PokeMapTone.neutral,
+                    ),
+                    const PokeMapStatusTile(
+                      label: 'Relations détaillées à venir',
+                      value: 'Non branchées',
+                      icon: CupertinoIcons.link,
+                      tone: PokeMapTone.neutral,
+                    ),
+                  ],
+                ),
+                const SizedBox(height: 16),
+                if (chapters.isEmpty && steps.isEmpty)
+                  const _StorylineGraphEmptyState()
+                else
+                  SizedBox(
+                    height: canvasHeight,
+                    child: _StorylineGraphCanvas(
+                      chapters: chapters,
+                      steps: steps,
+                    ),
+                  ),
+              ],
+            ),
+          );
+        },
+      ),
+    );
+  }
+}
+
+class _StorylineGraphCanvas extends StatelessWidget {
+  const _StorylineGraphCanvas({
+    required this.chapters,
+    required this.steps,
+  });
+
+  final List<NarrativeChapterSummary> chapters;
+  final List<NarrativeStepSummary> steps;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return LayoutBuilder(
+      builder: (context, constraints) {
+        final minCanvasWidth =
+            constraints.maxWidth.isFinite && constraints.maxWidth > 48
+                ? constraints.maxWidth - 32
+                : 720.0;
+        final minCanvasHeight =
+            constraints.maxHeight.isFinite && constraints.maxHeight > 0
+                ? constraints.maxHeight
+                : 360.0;
+        return Container(
+          key: const ValueKey('storylines-graph-canvas'),
+          constraints: BoxConstraints(
+            minWidth: minCanvasWidth,
+            minHeight: minCanvasHeight,
+          ),
+          clipBehavior: Clip.antiAlias,
+          decoration: BoxDecoration(
+            color: colors.surfaceSubtle,
+            borderRadius: BorderRadius.circular(10),
+            border: Border.all(color: colors.borderSubtle),
+          ),
+          child: Stack(
+            children: [
+              Positioned.fill(
+                child: CustomPaint(
+                  painter: _StorylineGraphGridPainter(
+                    lineColor: colors.borderSubtle.withValues(alpha: 0.46),
+                    accentLineColor:
+                        colors.brandPrimaryBorder.withValues(alpha: 0.16),
+                  ),
+                ),
+              ),
+              Positioned.fill(
+                child: SingleChildScrollView(
+                  padding: const EdgeInsets.all(18),
+                  child: ConstrainedBox(
+                    constraints: BoxConstraints(minWidth: minCanvasWidth),
+                    child: Column(
+                      crossAxisAlignment: CrossAxisAlignment.stretch,
+                      children: [
+                        KeyedSubtree(
+                          key: const ValueKey('storylines-graph-main-flow'),
+                          child: Wrap(
+                            alignment: WrapAlignment.center,
+                            crossAxisAlignment: WrapCrossAlignment.center,
+                            spacing: 12,
+                            runSpacing: 18,
+                            children: chapters.isNotEmpty
+                                ? _chapterFlowNodes()
+                                : _stepFlowNodes(),
+                          ),
+                        ),
+                        const SizedBox(height: 22),
+                        _StorylineGraphLegend(
+                          chapterCount: chapters.length,
+                          stepCount: steps.length,
+                        ),
+                        const SizedBox(height: 10),
+                        const _StorylineGraphReadOnlyControls(),
+                      ],
+                    ),
+                  ),
+                ),
+              ),
+            ],
+          ),
+        );
+      },
+    );
+  }
+
+  List<Widget> _chapterFlowNodes() {
+    final nodes = <Widget>[
+      const _StorylineGraphBoundaryNode(
+        key: ValueKey('storylines-graph-node-start'),
+        title: 'Début de lecture',
+        subtitle: 'Projection read-only',
+        icon: CupertinoIcons.play_circle,
+        tone: PokeMapTone.success,
+      ),
+    ];
+    for (final chapter in chapters) {
+      nodes
+        ..add(const _StorylineGraphConnector())
+        ..add(_StorylineGraphChapterNode(chapter: chapter));
+    }
+    nodes
+      ..add(const _StorylineGraphConnector())
+      ..add(
+        const _StorylineGraphBoundaryNode(
+          key: ValueKey('storylines-graph-node-read-only-note'),
+          title: 'Relations à venir',
+          subtitle: 'Aucune branche inventée',
+          icon: CupertinoIcons.lock,
+          tone: PokeMapTone.neutral,
+        ),
+      );
+    return nodes;
+  }
+
+  List<Widget> _stepFlowNodes() {
+    final nodes = <Widget>[
+      const _StorylineGraphBoundaryNode(
+        key: ValueKey('storylines-graph-node-start'),
+        title: 'Début de lecture',
+        subtitle: 'Projection read-only',
+        icon: CupertinoIcons.play_circle,
+        tone: PokeMapTone.success,
+      ),
+    ];
+    for (var index = 0; index < steps.length; index++) {
+      nodes
+        ..add(const _StorylineGraphConnector())
+        ..add(
+          _StorylineGraphStepNode(
+            step: steps[index],
+            position: index + 1,
+          ),
+        );
+    }
+    nodes
+      ..add(const _StorylineGraphConnector())
+      ..add(
+        const _StorylineGraphBoundaryNode(
+          key: ValueKey('storylines-graph-node-read-only-note'),
+          title: 'Relations à venir',
+          subtitle: 'Aucune branche inventée',
+          icon: CupertinoIcons.lock,
+          tone: PokeMapTone.neutral,
+        ),
+      );
+    return nodes;
+  }
+}
+
+class _StorylineGraphChapterNode extends StatelessWidget {
+  const _StorylineGraphChapterNode({
+    required this.chapter,
+  });
+
+  final NarrativeChapterSummary chapter;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    final description = chapter.description.trim();
+    final visibleSteps = chapter.steps.take(3).toList(growable: false);
+    final remainingStepCount = chapter.steps.length - visibleSteps.length;
+    return SizedBox(
+      key: ValueKey('storylines-graph-node-${chapter.id}'),
+      width: 220,
+      child: PokeMapCard(
+        padding: const EdgeInsets.all(13),
         child: Column(
-          crossAxisAlignment: CrossAxisAlignment.stretch,
+          crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const PokeMapIconTile(
-                  icon: CupertinoIcons.arrow_branch,
+                  icon: CupertinoIcons.book,
                   tone: PokeMapTone.narrative,
-                  size: 38,
-                  iconSize: 18,
+                  size: 34,
+                  iconSize: 16,
                 ),
-                const SizedBox(width: 12),
+                const SizedBox(width: 10),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
-                        'Graph read-only',
+                        'Chapitre ${chapter.order + 1}',
                         style: TextStyle(
-                          color: colors.textPrimary,
-                          fontSize: 15,
+                          color: colors.textMuted,
+                          fontSize: 10.5,
                           fontWeight: FontWeight.w800,
+                          letterSpacing: 0.4,
                         ),
                       ),
-                      const SizedBox(height: 6),
+                      const SizedBox(height: 4),
                       Text(
-                        'Lecture linéaire prudente des étapes disponibles. Les relations détaillées restent non branchées.',
+                        chapter.name,
+                        maxLines: 2,
+                        overflow: TextOverflow.ellipsis,
                         style: TextStyle(
-                          color: colors.textSecondary,
-                          fontSize: 12.5,
-                          height: 1.35,
+                          color: colors.textPrimary,
+                          fontSize: 13.5,
+                          fontWeight: FontWeight.w800,
                         ),
                       ),
                     ],
@@ -455,36 +729,145 @@ class _StorylineGraphSection extends StatelessWidget {
                 ),
               ],
             ),
-            const SizedBox(height: 14),
-            Wrap(
-              spacing: 10,
-              runSpacing: 10,
+            if (description.isNotEmpty) ...[
+              const SizedBox(height: 8),
+              Text(
+                description,
+                maxLines: 2,
+                overflow: TextOverflow.ellipsis,
+                style: TextStyle(
+                  color: colors.textSecondary,
+                  fontSize: 11.5,
+                  height: 1.3,
+                  fontWeight: FontWeight.w500,
+                ),
+              ),
+            ],
+            const SizedBox(height: 10),
+            PokeMapStatusTile(
+              label: 'Étapes narratives liées',
+              value: _formatFrenchCount(
+                chapter.steps.length,
+                singular: 'étape narrative',
+                plural: 'étapes narratives',
+              ),
+              icon: CupertinoIcons.list_bullet,
+              tone: PokeMapTone.info,
+            ),
+            const SizedBox(height: 10),
+            if (visibleSteps.isEmpty)
+              Text(
+                'Aucune étape narrative liée à ce chapitre.',
+                style: TextStyle(
+                  color: colors.textSecondary,
+                  fontSize: 11.5,
+                  height: 1.3,
+                ),
+              )
+            else
+              Column(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  for (final step in visibleSteps) ...[
+                    _StorylineGraphStepPreview(step: step),
+                    if (step != visibleSteps.last) const SizedBox(height: 8),
+                  ],
+                  if (remainingStepCount > 0) ...[
+                    const SizedBox(height: 8),
+                    Text(
+                      '+ ${_formatFrenchCount(
+                        remainingStepCount,
+                        singular: 'étape narrative réelle',
+                        plural: 'étapes narratives réelles',
+                      )}',
+                      style: TextStyle(
+                        color: colors.textMuted,
+                        fontSize: 11,
+                        fontWeight: FontWeight.w700,
+                      ),
+                    ),
+                  ],
+                ],
+              ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylineGraphStepNode extends StatelessWidget {
+  const _StorylineGraphStepNode({
+    required this.step,
+    required this.position,
+  });
+
+  final NarrativeStepSummary step;
+  final int position;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    final description = step.description.trim();
+    return SizedBox(
+      key: ValueKey('storylines-graph-step-node-${step.id}'),
+      width: 220,
+      child: PokeMapCard(
+        padding: const EdgeInsets.all(13),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Row(
+              crossAxisAlignment: CrossAxisAlignment.start,
               children: [
-                PokeMapStatusTile(
-                  label: 'Étapes narratives réelles',
-                  value: '${steps.length}',
-                  icon: CupertinoIcons.list_bullet,
+                const PokeMapIconTile(
+                  icon: CupertinoIcons.smallcircle_fill_circle,
                   tone: PokeMapTone.info,
+                  size: 34,
+                  iconSize: 15,
                 ),
-                const PokeMapStatusTile(
-                  label: 'Source',
-                  value: 'Source Step Studio',
-                  icon: CupertinoIcons.doc_text,
-                  tone: PokeMapTone.neutral,
-                ),
-                const PokeMapStatusTile(
-                  label: 'Relations détaillées à venir',
-                  value: 'Non branchées',
-                  icon: CupertinoIcons.link,
-                  tone: PokeMapTone.neutral,
+                const SizedBox(width: 10),
+                Expanded(
+                  child: Column(
+                    crossAxisAlignment: CrossAxisAlignment.start,
+                    children: [
+                      Text(
+                        'Étape narrative $position',
+                        style: TextStyle(
+                          color: colors.textMuted,
+                          fontSize: 11,
+                          fontWeight: FontWeight.w700,
+                        ),
+                      ),
+                      const SizedBox(height: 5),
+                      Text(
+                        step.name,
+                        maxLines: 2,
+                        overflow: TextOverflow.ellipsis,
+                        style: TextStyle(
+                          color: colors.textPrimary,
+                          fontSize: 13.5,
+                          fontWeight: FontWeight.w800,
+                        ),
+                      ),
+                    ],
+                  ),
                 ),
               ],
             ),
-            const SizedBox(height: 16),
-            if (steps.isEmpty)
-              const _StorylineGraphEmptyState()
-            else
-              _StorylineGraphNodeList(steps: steps),
+            if (description.isNotEmpty) ...[
+              const SizedBox(height: 8),
+              Text(
+                description,
+                maxLines: 3,
+                overflow: TextOverflow.ellipsis,
+                style: TextStyle(
+                  color: colors.textSecondary,
+                  fontSize: 11.5,
+                  height: 1.3,
+                ),
+              ),
+            ],
           ],
         ),
       ),
@@ -492,107 +875,112 @@ class _StorylineGraphSection extends StatelessWidget {
   }
 }
 
-class _StorylineGraphNodeList extends StatelessWidget {
-  const _StorylineGraphNodeList({
-    required this.steps,
+class _StorylineGraphStepPreview extends StatelessWidget {
+  const _StorylineGraphStepPreview({
+    required this.step,
   });
 
-  final List<NarrativeStepSummary> steps;
+  final NarrativeStepSummary step;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
-    return Column(
+    final description = step.description.trim();
+    return Row(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
-        for (var index = 0; index < steps.length; index++) ...[
-          _StorylineGraphNode(
-            step: steps[index],
-            position: index + 1,
-          ),
-          if (index < steps.length - 1)
-            Padding(
-              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
-              child: Text(
-                '↓',
+        const PokeMapIconTile(
+          icon: CupertinoIcons.smallcircle_fill_circle,
+          tone: PokeMapTone.info,
+          size: 24,
+          iconSize: 10,
+        ),
+        const SizedBox(width: 8),
+        Expanded(
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              Text(
+                step.name,
+                maxLines: 1,
+                overflow: TextOverflow.ellipsis,
                 style: TextStyle(
-                  color: colors.textMuted,
-                  fontSize: 16,
+                  color: colors.textPrimary,
+                  fontSize: 11.5,
                   fontWeight: FontWeight.w800,
                 ),
               ),
-            ),
-        ],
+              if (description.isNotEmpty) ...[
+                const SizedBox(height: 3),
+                Text(
+                  description,
+                  maxLines: 2,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textSecondary,
+                    fontSize: 10.5,
+                    height: 1.25,
+                  ),
+                ),
+              ],
+            ],
+          ),
+        ),
       ],
     );
   }
 }
 
-class _StorylineGraphNode extends StatelessWidget {
-  const _StorylineGraphNode({
-    required this.step,
-    required this.position,
+class _StorylineGraphBoundaryNode extends StatelessWidget {
+  const _StorylineGraphBoundaryNode({
+    super.key,
+    required this.title,
+    required this.subtitle,
+    required this.icon,
+    required this.tone,
   });
 
-  final NarrativeStepSummary step;
-  final int position;
+  final String title;
+  final String subtitle;
+  final IconData icon;
+  final PokeMapTone tone;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
-    final description = step.description.trim();
-    return ConstrainedBox(
-      constraints: const BoxConstraints(maxWidth: 520),
+    return SizedBox(
+      width: 156,
       child: PokeMapCard(
-        key: ValueKey('storylines-graph-node-${step.id}'),
-        padding: const EdgeInsets.all(14),
-        child: Row(
+        padding: const EdgeInsets.all(12),
+        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
-            const PokeMapIconTile(
-              icon: CupertinoIcons.link_circle_fill,
-              tone: PokeMapTone.narrative,
-              size: 34,
+            PokeMapIconTile(
+              icon: icon,
+              tone: tone,
+              size: 32,
               iconSize: 15,
             ),
-            const SizedBox(width: 12),
-            Expanded(
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  Text(
-                    'Étape narrative $position',
-                    style: TextStyle(
-                      color: colors.textMuted,
-                      fontSize: 11,
-                      fontWeight: FontWeight.w700,
-                    ),
-                  ),
-                  const SizedBox(height: 5),
-                  Text(
-                    step.name,
-                    maxLines: 1,
-                    overflow: TextOverflow.ellipsis,
-                    style: TextStyle(
-                      color: colors.textPrimary,
-                      fontSize: 14,
-                      fontWeight: FontWeight.w800,
-                    ),
-                  ),
-                  if (description.isNotEmpty) ...[
-                    const SizedBox(height: 6),
-                    Text(
-                      description,
-                      maxLines: 2,
-                      overflow: TextOverflow.ellipsis,
-                      style: TextStyle(
-                        color: colors.textSecondary,
-                        fontSize: 12,
-                        height: 1.3,
-                      ),
-                    ),
-                  ],
-                ],
+            const SizedBox(height: 9),
+            Text(
+              title,
+              maxLines: 2,
+              overflow: TextOverflow.ellipsis,
+              style: TextStyle(
+                color: colors.textPrimary,
+                fontSize: 12.5,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 4),
+            Text(
+              subtitle,
+              maxLines: 2,
+              overflow: TextOverflow.ellipsis,
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 10.5,
+                height: 1.25,
               ),
             ),
           ],
@@ -602,6 +990,129 @@ class _StorylineGraphNode extends StatelessWidget {
   }
 }
 
+class _StorylineGraphConnector extends StatelessWidget {
+  const _StorylineGraphConnector();
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return SizedBox(
+      width: 28,
+      child: Icon(
+        CupertinoIcons.arrow_right,
+        color: colors.textMuted,
+        size: 18,
+      ),
+    );
+  }
+}
+
+class _StorylineGraphLegend extends StatelessWidget {
+  const _StorylineGraphLegend({
+    required this.chapterCount,
+    required this.stepCount,
+  });
+
+  final int chapterCount;
+  final int stepCount;
+
+  @override
+  Widget build(BuildContext context) {
+    return KeyedSubtree(
+      key: const ValueKey('storylines-graph-legend'),
+      child: Wrap(
+        alignment: WrapAlignment.center,
+        spacing: 10,
+        runSpacing: 10,
+        children: [
+          const PokeMapStatusTile(
+            label: 'Début / lecture',
+            value: 'Projection',
+            icon: CupertinoIcons.play_circle,
+            tone: PokeMapTone.success,
+          ),
+          PokeMapStatusTile(
+            label: 'Chapitre réel',
+            value: '$chapterCount',
+            icon: CupertinoIcons.book,
+            tone: PokeMapTone.narrative,
+          ),
+          PokeMapStatusTile(
+            label: 'Étape narrative',
+            value: '$stepCount',
+            icon: CupertinoIcons.list_bullet,
+            tone: PokeMapTone.info,
+          ),
+          const PokeMapStatusTile(
+            label: 'À venir / non branché',
+            value: 'Relations',
+            icon: CupertinoIcons.lock,
+            tone: PokeMapTone.neutral,
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylineGraphReadOnlyControls extends StatelessWidget {
+  const _StorylineGraphReadOnlyControls();
+
+  @override
+  Widget build(BuildContext context) {
+    return const KeyedSubtree(
+      key: ValueKey('storylines-graph-read-only-controls'),
+      child: Center(
+        child: PokeMapStatusTile(
+          label: 'Mini-map et zoom à venir',
+          value: 'Contrôles non actifs',
+          icon: CupertinoIcons.lock,
+          tone: PokeMapTone.neutral,
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylineGraphGridPainter extends CustomPainter {
+  const _StorylineGraphGridPainter({
+    required this.lineColor,
+    required this.accentLineColor,
+  });
+
+  final Color lineColor;
+  final Color accentLineColor;
+
+  @override
+  void paint(Canvas canvas, Size size) {
+    final linePaint = Paint()
+      ..color = lineColor
+      ..strokeWidth = 1;
+    final accentPaint = Paint()
+      ..color = accentLineColor
+      ..strokeWidth = 1;
+
+    for (var x = 0.0; x <= size.width; x += 28) {
+      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
+    }
+    for (var y = 0.0; y <= size.height; y += 28) {
+      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
+    }
+    for (var x = 0.0; x <= size.width; x += 112) {
+      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
+    }
+    for (var y = 0.0; y <= size.height; y += 112) {
+      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
+    }
+  }
+
+  @override
+  bool shouldRepaint(covariant _StorylineGraphGridPainter oldDelegate) {
+    return oldDelegate.lineColor != lineColor ||
+        oldDelegate.accentLineColor != accentLineColor;
+  }
+}
+
 class _StorylineGraphEmptyState extends StatelessWidget {
   const _StorylineGraphEmptyState();
 
@@ -1153,71 +1664,76 @@ class _StorylineKpiStrip extends StatelessWidget {
   Widget build(BuildContext context) {
     return KeyedSubtree(
       key: const ValueKey('storylines-kpi-strip'),
-      child: Wrap(
-        spacing: 10,
-        runSpacing: 10,
-        children: [
-          SizedBox(
-            key: const ValueKey('storylines-kpi-global-stories'),
-            width: 150,
-            height: 128,
-            child: PokeMapMetricCard(
-              title: 'Storylines globales',
-              value: '$globalStoryCount',
-              subtitle: 'Source manifest',
-              icon: CupertinoIcons.link,
-              tone: PokeMapTone.narrative,
+      child: SingleChildScrollView(
+        scrollDirection: Axis.horizontal,
+        child: Row(
+          children: [
+            SizedBox(
+              key: const ValueKey('storylines-kpi-global-stories'),
+              width: 150,
+              height: 128,
+              child: PokeMapMetricCard(
+                title: 'Storylines globales',
+                value: '$globalStoryCount',
+                subtitle: 'Source manifest',
+                icon: CupertinoIcons.link,
+                tone: PokeMapTone.narrative,
+              ),
             ),
-          ),
-          SizedBox(
-            key: const ValueKey('storylines-kpi-steps'),
-            width: 150,
-            height: 128,
-            child: PokeMapMetricCard(
-              title: 'Étapes narratives',
-              value: '$stepCount',
-              subtitle: 'Source Step Studio',
-              icon: CupertinoIcons.list_bullet,
-              tone: PokeMapTone.info,
+            const SizedBox(width: 10),
+            SizedBox(
+              key: const ValueKey('storylines-kpi-steps'),
+              width: 150,
+              height: 128,
+              child: PokeMapMetricCard(
+                title: 'Étapes narratives',
+                value: '$stepCount',
+                subtitle: 'Source Step Studio',
+                icon: CupertinoIcons.list_bullet,
+                tone: PokeMapTone.info,
+              ),
             ),
-          ),
-          SizedBox(
-            key: const ValueKey('storylines-kpi-cutscenes'),
-            width: 150,
-            height: 128,
-            child: PokeMapMetricCard(
-              title: 'Cutscenes liées',
-              value: '$linkedCutsceneCount',
-              subtitle: 'Références Step',
-              icon: CupertinoIcons.film,
-              tone: PokeMapTone.neutral,
+            const SizedBox(width: 10),
+            SizedBox(
+              key: const ValueKey('storylines-kpi-cutscenes'),
+              width: 150,
+              height: 128,
+              child: PokeMapMetricCard(
+                title: 'Cutscenes liées',
+                value: '$linkedCutsceneCount',
+                subtitle: 'Références Step',
+                icon: CupertinoIcons.film,
+                tone: PokeMapTone.neutral,
+              ),
             ),
-          ),
-          SizedBox(
-            key: const ValueKey('storylines-kpi-chapters'),
-            width: 150,
-            height: 128,
-            child: PokeMapMetricCard(
-              title: 'Chapitres',
-              value: '$chapterCount',
-              subtitle: 'Source Global Story',
-              icon: CupertinoIcons.square_list,
-              tone: PokeMapTone.neutral,
+            const SizedBox(width: 10),
+            SizedBox(
+              key: const ValueKey('storylines-kpi-chapters'),
+              width: 150,
+              height: 128,
+              child: PokeMapMetricCard(
+                title: 'Chapitres',
+                value: '$chapterCount',
+                subtitle: 'Source Global Story',
+                icon: CupertinoIcons.square_list,
+                tone: PokeMapTone.neutral,
+              ),
             ),
-          ),
-          const SizedBox(
-            key: ValueKey('storylines-kpi-diagnostics'),
-            width: 150,
-            height: 128,
-            child: PokeMapMetricCard(
-              title: 'Avertissements structurels',
-              value: 'À venir',
-              subtitle: 'Validator absent',
-              icon: CupertinoIcons.exclamationmark_triangle,
-              tone: PokeMapTone.neutral,
+            const SizedBox(width: 10),
+            const SizedBox(
+              key: ValueKey('storylines-kpi-diagnostics'),
+              width: 150,
+              height: 128,
+              child: PokeMapMetricCard(
+                title: 'Avertissements structurels',
+                value: 'À venir',
+                subtitle: 'Validator absent',
+                icon: CupertinoIcons.exclamationmark_triangle,
+                tone: PokeMapTone.neutral,
+              ),
             ),
-          ),
-        ],
+          ],
+        ),
       ),
     );
   }
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index 65026439..3710166f 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -14,7 +14,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-08 Chapters tab read-only V0', () {
+  group('NS-STORYLINES-08-bis Graph target alignment V0', () {
     testWidgets(
       'renders a read-only three-pane shell from real global story data',
       (tester) async {
@@ -45,8 +45,29 @@ void main() {
         expect(find.text('Audit description from scenario'), findsWidgets);
         expect(find.text('Mode lecture seule'), findsOneWidget);
         expect(find.text('Storylines V0'), findsWidgets);
+        final graph =
+            find.byKey(const ValueKey('storylines-graph-target-read-only'));
+        expect(graph, findsOneWidget);
         expect(
-          find.byKey(const ValueKey('storylines-graph-read-only')),
+          find.byKey(const ValueKey('storylines-graph-canvas')),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(const ValueKey('storylines-graph-main-flow')),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(const ValueKey('storylines-graph-node-audit_chapter')),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(
+            const ValueKey('storylines-graph-node-audit_second_chapter'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(const ValueKey('storylines-graph-legend')),
           findsOneWidget,
         );
         expect(
@@ -54,13 +75,15 @@ void main() {
           findsNothing,
         );
         expect(find.text('Graph read-only'), findsOneWidget);
-        expect(find.text('Étapes narratives réelles'), findsOneWidget);
+        expect(find.text('Audit Chapter From Metadata'), findsOneWidget);
+        expect(find.text('Audit Second Chapter From Metadata'), findsOneWidget);
         expect(find.text('Audit Step From Metadata'), findsOneWidget);
+        expect(find.text('Audit Second Step From Metadata'), findsOneWidget);
         expect(find.text('Audit Step Detail From Metadata'), findsOneWidget);
         expect(
           find.descendant(
-            of: find.byKey(const ValueKey('storylines-graph-read-only')),
-            matching: find.text('Source Step Studio'),
+            of: graph,
+            matching: find.textContaining('Global Story Studio'),
           ),
           findsOneWidget,
         );
@@ -98,7 +121,7 @@ void main() {
         );
         expect(
           find.descendant(
-              of: inspector, matching: find.text('1 étape narrative')),
+              of: inspector, matching: find.text('2 étapes narratives')),
           findsOneWidget,
         );
         expect(
@@ -138,6 +161,7 @@ void main() {
             findsOneWidget);
         expect(find.text('Storyline principale'), findsWidgets);
         expect(find.textContaining('1 étape narrative'), findsWidgets);
+        expect(find.textContaining('2 étapes narratives'), findsWidgets);
         expect(find.text('Recherche à venir'), findsOneWidget);
         expect(find.text('Quêtes annexes'), findsWidgets);
         expect(find.textContaining('aucun modèle de quête annexe'),
@@ -168,7 +192,7 @@ void main() {
         expect(
           find.descendant(
             of: find.byKey(const ValueKey('storylines-kpi-steps')),
-            matching: find.text('1'),
+            matching: find.text('2'),
           ),
           findsOneWidget,
         );
@@ -242,7 +266,7 @@ void main() {
         );
 
         expect(
-          find.byKey(const ValueKey('storylines-graph-read-only')),
+          find.byKey(const ValueKey('storylines-graph-target-read-only')),
           findsOneWidget,
         );
         expect(find.text('Graph read-only'), findsOneWidget);
@@ -276,7 +300,7 @@ void main() {
             find.byKey(const ValueKey('storylines-chapters-create-action'));
 
         expect(chapters, findsOneWidget);
-        expect(find.byKey(const ValueKey('storylines-graph-read-only')),
+        expect(find.byKey(const ValueKey('storylines-graph-target-read-only')),
             findsNothing);
         expect(
           find.descendant(of: chapters, matching: find.text('Chapitres')),
@@ -306,7 +330,7 @@ void main() {
         expect(
           find.descendant(
               of: chapters, matching: find.text('1 étape narrative')),
-          findsOneWidget,
+          findsWidgets,
         );
         expect(
           find.descendant(
@@ -601,12 +625,11 @@ void main() {
         tester,
         surfaceSize: const Size(1600, 1000),
       );
-      await _openChaptersTab(tester);
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_08_chapters_tab_desktop.png',
+          'ns_storylines_08_bis_graph_target_desktop.png',
         ),
       );
 
@@ -614,12 +637,11 @@ void main() {
         tester,
         surfaceSize: const Size(1600, 700),
       );
-      await _openChaptersTab(tester);
       await expectLater(
-        find.byKey(const ValueKey('storylines-workspace-shell')),
+        find.byKey(const ValueKey('storylines-graph-target-read-only')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_08_chapters_tab_focus.png',
+          'ns_storylines_08_bis_graph_target_focus.png',
         ),
       );
 
@@ -627,12 +649,11 @@ void main() {
         tester,
         surfaceSize: const Size(1180, 1000),
       );
-      await _openChaptersTab(tester);
       await expectLater(
-        find.byKey(const ValueKey('storylines-workspace-shell')),
+        find.byKey(const ValueKey('storylines-graph-target-read-only')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_08_chapters_tab_center.png',
+          'ns_storylines_08_bis_graph_target_center.png',
         ),
       );
     });
@@ -644,10 +665,18 @@ const _targetOnlyStrings = <String>[
   'Les cristaux de sel',
   'Le Goélise du port',
   'La cabane du phare',
+  'Souvenirs oubliés',
+  'Tutoriel : Premiers pas',
+  'Épilogue : Le phare rallumé',
   'Mystère',
   'Exploration',
   'Phare',
   'Côtiers',
+  '5 chapitres',
+  '27 scènes',
+  '412 dialogues',
+  '18 facts',
+  '3 problèmes',
   '412',
   '18',
   'RÈGLES DU MONDE AFFECTÉES',
@@ -659,6 +688,8 @@ const _targetOnlyStrings = <String>[
   'Défini',
   'Brouillon',
   'En cours',
+  'Scènes du chapitre',
+  'Quête annexe',
 ];
 
 Future<void> _openChaptersTab(WidgetTester tester) async {
@@ -735,6 +766,19 @@ ProjectManifest _auditProject() {
           mode: StepStudioCompletionMode.manual,
         ),
       ),
+      StepStudioStep(
+        id: 'audit_followup_step',
+        name: 'Audit Second Step From Metadata',
+        description: 'Audit second step detail from metadata',
+        order: 1,
+        activation: StepStudioActivationRule(
+          mode: StepStudioActivationMode.afterStep,
+          stepId: 'audit_step',
+        ),
+        completion: StepStudioCompletionRule(
+          mode: StepStudioCompletionMode.manual,
+        ),
+      ),
     ],
   );
   const globalDocument = GlobalStoryStudioDocument(
@@ -742,6 +786,7 @@ ProjectManifest _auditProject() {
     entryStepId: 'audit_step',
     nodes: <GlobalStoryStepNode>[
       GlobalStoryStepNode(stepId: 'audit_step'),
+      GlobalStoryStepNode(stepId: 'audit_followup_step'),
     ],
     chapters: <GlobalStoryChapter>[
       GlobalStoryChapter(
@@ -751,6 +796,13 @@ ProjectManifest _auditProject() {
         stepIds: <String>['audit_step'],
         order: 0,
       ),
+      GlobalStoryChapter(
+        id: 'audit_second_chapter',
+        name: 'Audit Second Chapter From Metadata',
+        description: 'Audit second chapter description from metadata',
+        stepIds: <String>['audit_followup_step'],
+        order: 1,
+      ),
     ],
   );
 
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 63ec2767..c2ac454d 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -506,6 +506,21 @@ Interprétation V0 :
 - Fake data : aucun statut éditorial, scène, quête annexe, donnée Selbrume, world rule, fact, activité récente ou chiffre cible ajouté ; `localEventFlow` reste absent de la tab Chapitres.
 - Prochain lot attendu : NS-STORYLINES-09.
 
+#### NS-STORYLINES-08-bis — Graph Tab Target Alignment / Default View V0
+
+- Statut : DONE, sans changer le statut de `NS-STORYLINES-08`.
+- Résultat : l'onglet `Graph` reste la vue par défaut et devient une vue canvas plus dominante, avec grille subtile, flux principal, nodes de chapitres réels et previews de steps réelles.
+- Source : nodes macro depuis les `NarrativeChapterSummary` disponibles ; fallback read-only par steps si aucun chapitre ; empty state honnête si aucune step.
+- Image cible : utilisée comme référence visuelle/layout uniquement, jamais comme source de données.
+- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_08_bis_graph_tab_target_alignment_v0.md`, captures Visual Gate `ns_storylines_08_bis_graph_target_desktop.png`, `ns_storylines_08_bis_graph_target_focus.png`, `ns_storylines_08_bis_graph_target_center.png`.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
+- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
+- Visual Gate : dark theme actif ; captures desktop, focus et center produites pour le Graph aligné cible.
+- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté ; surfaces et accents via primitives PokeMap et `context.pokeMapColors`.
+- Fake data : aucune quête annexe fake, aucun nom/chiffre Selbrume cible, aucune mini-map ou zoom actif ajouté ; `localEventFlow` reste absent du graph.
+- Prochain lot recommandé inchangé : NS-STORYLINES-09.
+
 ### NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0
 
 - Type : editor UI.
@@ -687,7 +702,7 @@ Décision temporaire :
 
 ```text
 Roadmap status: ACTIVE
-Current lot: NS-STORYLINES-08
+Current lot: NS-STORYLINES-08 / NS-STORYLINES-08-bis
 Current lot status: DONE
 Next recommended lot: NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0
 ```
@@ -703,7 +718,7 @@ Next recommended lot: NS-STORYLINES-09 — Chapters Inspector / Scene Ordering R
 | NS-STORYLINES-05 | DONE | 2026-05-28 | Header/tabs/KPI read-only livrés avec KPI sourcés ou disabled. |
 | NS-STORYLINES-06 | DONE | 2026-05-28 | Graph read-only placeholder livré avec steps réelles et empty state. |
 | NS-STORYLINES-07 | DONE | 2026-05-28 | Inspector read-only livré avec données réelles, sections futures disabled et empty state. |
-| NS-STORYLINES-08 | DONE | 2026-05-28 | Onglet Chapitres read-only livré avec chapters réels, steps liées et empty state. |
+| NS-STORYLINES-08 | DONE | 2026-05-28 | Onglet Chapitres read-only livré ; bis Graph target alignment livré sans changer le statut NS08. |
 | NS-STORYLINES-09 | TODO | 2026-05-27 | Chapters inspector/order. |
 | NS-STORYLINES-10 | TODO | 2026-05-27 | Visual harmonization. |
 | NS-STORYLINES-11 | TODO | 2026-05-27 | Interaction wiring. |
@@ -711,6 +726,18 @@ Next recommended lot: NS-STORYLINES-09 — Chapters Inspector / Scene Ordering R
 
 ## 14. Changelog
 
+### 2026-05-28 — NS-STORYLINES-08-bis
+
+- Réalignement visuel de l'onglet `Graph` avec l'image cible principale, utilisée uniquement comme référence de composition.
+- Conservation de `Graph` comme vue par défaut.
+- Remplacement de la lecture graph trop verticale par un canvas sombre avec grille tokenisée, flux principal, nodes macro de chapitres réels et previews de steps réelles.
+- Conservation de la tab `Chapitres` NS-STORYLINES-08 et des tabs futures non mutantes.
+- Conservation des actions futures disabled / non mutantes : `Nouvelle storyline`, `Valider`, `+`, `Nouveau chapitre`.
+- Aucun changement métier, aucun modèle core, aucun provider, aucun runtime/gameplay/battle.
+- Production des captures Visual Gate dark `ns_storylines_08_bis_graph_target_desktop.png`, `ns_storylines_08_bis_graph_target_focus.png`, `ns_storylines_08_bis_graph_target_center.png`.
+- Confirmation : aucune donnée cible hardcodée, aucune quête annexe fake, aucune mini-map / zoom actif, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
+- Prochain lot recommandé inchangé : `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.
+
 ### 2026-05-28 — NS-STORYLINES-08
 
 - Ajout d'un read model editor-side `NarrativeChapterSummary` dans la projection narrative.
```

### Contenu complet du rapport créé

Le contenu complet du rapport créé est ce fichier Markdown, de son titre à la section `Self-review` incluse.

## 15. Self-review

Preuves solides :

- le test RED a échoué sur l'absence de `storylines-graph-target-read-only` ;
- le test final Storylines passe avec 11 tests ;
- le test de caractérisation anti-fake passe ;
- le test projection passe ;
- l'analyse ciblée est clean ;
- le guard `Color(0x...)` / `Colors.*` est vide ;
- les screenshots Visual Gate NS08-bis existent.

Limites assumées :

- le graph reste une projection read-only de lecture, pas un vrai graph relationnel complet ;
- les connexions sont des connecteurs simples de lecture, pas des relations métier prouvées ;
- la mini-map et le zoom restent textuels / non actifs ;
- la capture golden utilise toujours la police de test Flutter, donc elle valide structure, densité, thème et overflow plutôt que la typographie finale.

Contrôle critique :

- aucune donnée de l'image cible n'a été utilisée comme donnée produit ;
- aucune quête annexe réelle n'a été inventée ;
- `localEventFlow` n'est pas transformé en node graph ;
- le prochain lot reste `NS-STORYLINES-09`.
