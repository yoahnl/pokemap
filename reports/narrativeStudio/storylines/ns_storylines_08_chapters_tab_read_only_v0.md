# NS-STORYLINES-08 — Chapters Tab Read-only V0

## 1. Executive summary

NS-STORYLINES-08 est livré.

L'onglet `Chapitres` du workspace Storylines affiche maintenant un contenu read-only réel :

- les chapitres viennent de `GlobalStoryStudioDocument.chapters` via un read model editor-side ;
- les étapes liées sont résolues depuis les `NarrativeStepSummary` réelles ;
- `Graph` reste l'onglet par défaut ;
- `Chapitres` bascule uniquement un état UI local ;
- `Étapes`, `Scènes`, `Statistiques`, `Tests` restent non branchés / non mutants ;
- `Nouveau chapitre` est visible mais disabled ;
- aucun statut éditorial, scène, quête annexe ou donnée cible fake n'est ajouté.

Le prochain lot recommandé est `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

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
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/test/global_story_studio_authoring_test.dart`
- `packages/map_editor/test/global_story_studio_workspace_test.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`
- `packages/map_editor/lib/src/theme/theme.dart`
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart`
- `Superpowers test-driven-development` skill.
- `Superpowers verification-before-completion` skill.

Fichiers absents mais attendus :

```text
Sortie : <vide>
```

## 3. Implementation summary

Fichiers modifiés :

- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

Fichiers créés :

- `reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_center.png`

Résumé technique :

- Ajout de `NarrativeChapterSummary` dans `narrative_workspace_projection.dart`.
- Ajout de `NarrativeWorkspaceProjection.chapters`.
- Extraction des chapitres depuis `parseGlobalStoryStudioDocumentFromGlobalScenario`.
- Détection des `missingStepIds` depuis la metadata brute avant normalisation.
- Conversion de `StorylinesWorkspace` en `StatefulWidget` avec état local `_StorylineContentTab`.
- Ajout de `_StorylineChaptersSection`, `_StorylineChapterCard`, `_StorylineChapterStepPreview` et `_StorylineChaptersEmptyState`.
- Mise à jour des tabs : `Graph` et `Chapitres` sont affichables, les autres tabs restent non branchées.
- Mise à jour du KPI `Chapitres` avec un compteur réel dérivé.

## 4. Chapter data source

Source canonique V0 :

```text
GlobalStoryStudioDocument.chapters
```

Pipeline :

```text
ScenarioAsset globalStory
→ StepStudioDocument
→ GlobalStoryStudioDocument normalisé
→ NarrativeChapterSummary
→ StorylinesWorkspace
```

Champs exposés :

- `id`
- `globalScenarioId`
- `name`
- `description`
- `order`
- `stepIds`
- `steps`
- `missingStepIds`

La projection reste dans `map_editor`; aucun modèle `map_core` n'est modifié.

## 5. Chapters tab behavior

Comportement :

- `Graph` reste actif par défaut.
- Clic sur `Chapitres` affiche `storylines-chapters-read-only`.
- Le graph disparaît de la vue active quand `Chapitres` est affiché.
- Clic sur `Graph` revient au graph.
- Clic sur `Étapes`, `Scènes`, `Statistiques`, `Tests` ne change pas la vue et ne mute rien.
- `Nouveau chapitre` est disabled.

Contenu affiché :

- `Chapitres`
- `Lecture read-only des chapitres issus de Global Story Studio.`
- `Chapitres réels`
- `Global Story Studio`
- `Lecture seule`
- cartes des chapitres réels.

## 6. Step preview behavior

Chaque chapitre affiche :

- ordre dérivé : `Chapitre N` ;
- nom réel du chapitre ;
- description réelle ou fallback honnête ;
- compteur `Étapes narratives liées` ;
- état `Lecture seule` ;
- section `Étapes du chapitre` ;
- aperçu des steps résolues avec nom et description réels.

Le wording `Scènes du chapitre` n'est pas utilisé.

## 7. Empty state behavior

Une fixture avec un document Step Studio explicitement vide vérifie l'état vide.

Wording :

```text
Aucun chapitre disponible pour cette storyline.
```

Le lot ne crée pas de chapitre par défaut artificiel dans l'UI si aucune step n'existe.

## 8. Disabled interactions

Interactions autorisées :

- bascule locale `Graph` ↔ `Chapitres`.

Interactions interdites et absentes :

- création de chapitre ;
- édition de chapitre ;
- suppression de chapitre ;
- réordonnancement ;
- drag/drop ;
- édition de step ;
- navigation vers Step Studio ;
- activation de `Scènes`, `Statistiques`, `Tests`.

`Nouveau chapitre` est un `PokeMapButton` avec `onPressed == null`.

## 9. Data source / anti-fake guarantees

Garanties :

- les chapitres viennent de `GlobalStoryStudioDocument.chapters` ;
- les steps viennent des `NarrativeStepSummary` filtrées par `globalScenarioId` ;
- les chapitres sont ordonnés via `GlobalStoryChapter.order` ;
- les `localEventFlow` ne contribuent pas aux chapitres ;
- les step ids manquants sont détectés depuis la metadata brute ;
- aucune quête annexe n'est créée ;
- aucun statut `Défini`, `Brouillon`, `En cours`, `Active`, `Haute`, `Validé`, `À jour` n'est affiché ;
- aucune donnée Selbrume cible n'est hardcodée ;
- aucun chiffre cible `5`, `27`, `412`, `18`, `3` n'est codé comme donnée positive.

## 10. Design System Gate

Primitives utilisées :

- `PokeMapPageSurface`
- `PokeMapCard`
- `PokeMapIconTile`
- `PokeMapStatusTile`
- `PokeMapMetricCard`
- `PokeMapSegmentedTabs`
- `PokeMapButton`
- `PokeMapTone`
- `context.pokeMapColors`

Composants privés ajoutés :

- `_StorylineChaptersSection`
- `_StorylineChapterList`
- `_StorylineChapterCard`
- `_StorylineChapterStepPreview`
- `_StorylineChaptersEmptyState`

Ces composants sont feature-specific et composent les primitives PokeMap. Ils ne créent pas de design system local parallèle.

Commande :

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/features/narrative/application packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart
```

Sortie :

```text
Sortie : <vide>
```

## 11. Sidebar / Maps guardrail

`Maps` reste absent de la sidebar interne Narrative Studio.

Le lot ne modifie pas :

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `ProjectExplorerPanel`
- `packages/map_core/lib/`
- `packages/map_runtime/`
- `packages/map_gameplay/`
- `packages/map_battle/`

## 12. Tests added or modified

Tests modifiés :

- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`

Couverture ajoutée :

- projection des chapitres depuis Global Story Studio metadata ;
- ordre des chapitres ;
- résolution des `stepIds` vers les steps réelles ;
- détection d'une step manquante dans la metadata brute ;
- exclusion de `localEventFlow` ;
- `Graph` actif par défaut ;
- tab `Chapitres` affichable ;
- graph masqué quand `Chapitres` est actif ;
- bouton `Nouveau chapitre` disabled ;
- empty state chapitres ;
- tabs futures non mutantes ;
- anti-fake `Scènes du chapitre`, `Défini`, `Brouillon`, `En cours`.

## 13. Visual Gate

Captures produites :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_center.png`

Métadonnées :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_center.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_desktop.png 2026-05-28 11:12:57 CEST 61817
reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_focus.png 2026-05-28 11:12:57 CEST 48501
reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_center.png 2026-05-28 11:12:57 CEST 51819
```

Résultat visuel contrôlé :

- dark theme actif ;
- panneau secondaire NS04 conservé ;
- header/tabs/KPI NS05 conservés ;
- inspecteur NS07 conservé ;
- tab `Chapitres` active ;
- contenu Chapitres read-only visible ;
- étapes liées visibles ;
- pas de `Scènes du chapitre` ;
- pas de statut éditorial fake ;
- pas d'overflow visible.

## 14. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- `NS-STORYLINES-08` est marqué `DONE` ;
- le résumé du résultat a été ajouté ;
- les fichiers créés / modifiés sont listés ;
- les tests, l'analyse ciblée et les captures Visual Gate sont listés ;
- le Design System Gate est confirmé ;
- l'absence de fake data est confirmée ;
- l'absence de couleurs hardcodées est confirmée ;
- le prochain lot recommandé est `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

## 15. Commands run

### Git initial

Commande :

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie initiale :

```text
main
```

Sortie `git status --short --untracked-files=all` initiale :

```text
Sortie : <vide>
```

Sortie `git diff --stat` initiale :

```text
Sortie : <vide>
```

Sortie `git diff --name-only` initiale :

```text
Sortie : <vide>
```

Sortie `git diff --check` initiale :

```text
Sortie : <vide>
```

### TDD red

Commande :

```bash
cd packages/map_editor && dart format test/storylines_workspace_shell_test.dart test/narrative_workspace_projection_test.dart && flutter test test/narrative_workspace_projection_test.dart test/storylines_workspace_shell_test.dart
```

Sortie utile :

```text
Formatted test/narrative_workspace_projection_test.dart
Formatted 2 files (1 changed) in 0.01 seconds.
test/narrative_workspace_projection_test.dart:253:25: Error: The getter 'chapters' isn't defined for the type 'NarrativeWorkspaceProjection'.
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'storylines-chapters-read-only'>]: []>
Expected: one widget whose rasterized image matches golden image
"../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_desktop.png"
  Actual: _KeyWidgetFinder:<Found 1 widget with key [<'storylines-workspace-shell'>]>
   Which: Could not be compared against non-existent file:
"../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_desktop.png"
```

### Visual Gate generation

Commande :

```bash
cd packages/map_editor && dart format test/storylines_workspace_shell_test.dart && flutter test --update-goldens test/storylines_workspace_shell_test.dart
```

Sortie exacte :

```text
Formatted 1 file (0 changed) in 0.02 seconds.
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-08 Chapters tab read-only V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-08 Chapters tab read-only V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-08 Chapters tab read-only V0 shows the Chapters tab from Global Story Studio metadata read-only
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +3: NS-STORYLINES-08 Chapters tab read-only V0 shows an honest Chapters empty state
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:01 +4: NS-STORYLINES-08 Chapters tab read-only V0 renders an honest inspector empty state without global story
00:01 +5: NS-STORYLINES-08 Chapters tab read-only V0 keeps future Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +6: NS-STORYLINES-08 Chapters tab read-only V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +7: NS-STORYLINES-08 Chapters tab read-only V0 storylines UI source keeps raw colors out of the feature
00:01 +8: NS-STORYLINES-08 Chapters tab read-only V0 storylines action test does not use silent taps
00:01 +9: NS-STORYLINES-08 Chapters tab read-only V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +10: NS-STORYLINES-08 Chapters tab read-only V0 writes Visual Gate screenshots
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

### Final targeted tests

Commande :

```bash
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart && flutter test test/storylines_current_global_story_characterization_test.dart && flutter test test/narrative_workspace_projection_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-08 Chapters tab read-only V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-08 Chapters tab read-only V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-08 Chapters tab read-only V0 shows the Chapters tab from Global Story Studio metadata read-only
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +3: NS-STORYLINES-08 Chapters tab read-only V0 shows an honest Chapters empty state
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:01 +4: NS-STORYLINES-08 Chapters tab read-only V0 renders an honest inspector empty state without global story
00:01 +5: NS-STORYLINES-08 Chapters tab read-only V0 keeps future Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +6: NS-STORYLINES-08 Chapters tab read-only V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +7: NS-STORYLINES-08 Chapters tab read-only V0 storylines UI source keeps raw colors out of the feature
00:01 +8: NS-STORYLINES-08 Chapters tab read-only V0 storylines action test does not use silent taps
00:01 +9: NS-STORYLINES-08 Chapters tab read-only V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +10: NS-STORYLINES-08 Chapters tab read-only V0 writes Visual Gate screenshots
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
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:00 +3: All tests passed!
```

### Targeted analyze

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/features/narrative/application/narrative_workspace_projection.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart
```

Sortie exacte :

```text
Analyzing 6 items...
No issues found! (ran in 3.1s)
```

## 16. Evidence Pack

### Git final

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie finale :

```text
 M packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/narrative_workspace_projection_test.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_focus.png
 .../narrative_workspace_projection.dart            | 119 ++++++
 .../lib/src/ui/canvas/storylines_workspace.dart    | 454 +++++++++++++++++++--
 .../test/narrative_workspace_projection_test.dart  | 115 +++++-
 .../test/storylines_workspace_shell_test.dart      | 157 ++++++-
 .../storylines/road_map_storylines.md              |  33 +-
 5 files changed, 840 insertions(+), 38 deletions(-)
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/narrative_workspace_projection_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

Sortie `git diff --check` finale :

```text
Sortie : <vide>
```

### Liste des fichiers lus

Voir section `2. Inputs read`.

### Liste des fichiers absents mais attendus

```text
Sortie : <vide>
```

### Contenu complet du rapport créé

Le contenu complet du rapport créé est le présent fichier Markdown.

### Contenu complet des fichiers créés

Fichier Markdown créé :

- `reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md`

Captures PNG créées :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_desktop.png` : 1600 x 1000, 61817 bytes.
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_focus.png` : 1600 x 700, 48501 bytes.
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_chapters_tab_center.png` : 1180 x 1000, 51819 bytes.

### Diff des fichiers modifiés

Stat final avant création du rapport :

```text
 .../narrative_workspace_projection.dart            | 119 ++++++
 .../lib/src/ui/canvas/storylines_workspace.dart    | 454 +++++++++++++++++++--
 .../test/narrative_workspace_projection_test.dart  | 115 +++++-
 .../test/storylines_workspace_shell_test.dart      | 157 ++++++-
 .../storylines/road_map_storylines.md              |  33 +-
 5 files changed, 840 insertions(+), 38 deletions(-)
```

Fichiers modifiés :

```text
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/narrative_workspace_projection_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

Principaux hunks exacts :

```diff
+class NarrativeChapterSummary {
+  const NarrativeChapterSummary({
+    required this.id,
+    required this.globalScenarioId,
+    required this.name,
+    required this.description,
+    required this.order,
+    required this.stepIds,
+    required this.steps,
+    required this.missingStepIds,
+  });
+}
```

```diff
+  final List<NarrativeChapterSummary> chapters;
```

```diff
+final chapters = _buildChapterSummaries(
+  rawGlobalStoryScenarios: rawGlobalStoryScenarios,
+  steps: steps,
+);
```

```diff
+class _StorylineChaptersSection extends StatelessWidget {
+  const _StorylineChaptersSection({
+    required this.chapters,
+  });
+}
```

```diff
+Future<void> _openChaptersTab(WidgetTester tester) async {
+  await tester.tap(
+    find.descendant(
+      of: find.byKey(const ValueKey('storylines-tabs')),
+      matching: find.text('Chapitres'),
+    ),
+  );
+  await tester.pump();
+}
```

### Sorties exactes des tests ciblés

Voir section `15. Commands run`.

### Sortie exacte de l'analyse ciblée

Voir section `15. Commands run`.

### Résultats du Visual Gate

Voir section `13. Visual Gate`.

### Mini audit Design System

- Aucun `Color(0x...)` ajouté.
- Aucun `Colors.*` ajouté.
- Aucun composant générique local hors design system ajouté.
- Les composants privés ajoutés sont métier Storylines et composent des primitives PokeMap.
- `Nouveau chapitre` utilise `PokeMapButton` disabled.
- Les surfaces utilisent `PokeMapPageSurface` / `PokeMapCard`.

### Recherche `Color(0x...)` / `Colors.*`

Commande :

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/features/narrative/application packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart
```

Sortie :

```text
Sortie : <vide>
```

## 17. Self-review

Points validés :

- L'onglet `Chapitres` peut être affiché en read-only.
- Les chapitres viennent de `GlobalStoryStudioDocument.chapters`.
- Les étapes liées viennent des `NarrativeStepSummary` réelles.
- L'ordre des chapitres est respecté.
- L'empty state est honnête.
- Aucun statut éditorial fake n'est affiché.
- Aucun wording `Scènes du chapitre` n'est utilisé.
- Aucun `localEventFlow` n'est affiché comme chapitre ou étape.
- Aucune création / édition / suppression / réorganisation n'est activée.
- Les tabs futures restent non mutantes.
- Maps reste absent de la sidebar interne.
- Aucun chiffre cible n'est hardcodé.
- Aucun `Color(0x...)` / `Colors.*` n'est ajouté.
- Les tests ciblés passent.
- L'analyse ciblée est propre.
- Le Visual Gate dark est produit.

Limites assumées :

- L'onglet `Chapitres` ne sélectionne pas encore un chapitre pour un inspecteur dédié.
- Les étapes affichées sont des previews read-only, pas un ordre éditable.
- Les step ids manquants sont détectés dans le read model, mais aucun workflow de correction n'est actif dans ce lot.

Décision de suite :

- Continuer avec `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.
