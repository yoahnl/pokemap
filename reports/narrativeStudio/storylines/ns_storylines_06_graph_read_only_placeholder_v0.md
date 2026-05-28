# NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0

## 1. Executive summary

NS-STORYLINES-06 est livré.

La zone centrale basse du workspace Storylines remplace le placeholder `Graph — à venir / Placeholder read-only` par une première zone `Graph read-only`.

Ce graph V0 :

- affiche les vraies étapes narratives liées à la storyline sélectionnée ;
- lit `NarrativeStepSummary.name` et `NarrativeStepSummary.description` ;
- indique explicitement `Source Step Studio` ;
- garde les relations détaillées à venir ;
- affiche un empty state honnête si un document Step Studio est explicitement vide ;
- ne crée aucune quête annexe, branche riche, mini-map, zoom control ou interaction graph.

Le prochain lot recommandé reste `NS-STORYLINES-07 — Storyline Inspector Read-only V0`.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md` : fourni dans le prompt et règles appliquées.
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

Fichiers absents mais attendus :

```text
Sortie : <vide>
```

## 3. Implementation summary

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

Fichiers créés :

- `reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_center.png`

Résumé technique :

- `_StorylineMainPanel` reçoit désormais la liste des `relatedSteps`.
- Le placeholder inférieur est remplacé par `_StorylineGraphSection`.
- `_StorylineGraphSection` compose `PokeMapPageSurface`, `PokeMapIconTile` et `PokeMapStatusTile`.
- `_StorylineGraphNodeList` affiche les steps en lecture linéaire prudente.
- `_StorylineGraphNode` compose `PokeMapCard` et affiche le nom/description de la step.
- `_StorylineGraphEmptyState` couvre le cas d'un document Step Studio vide.
- Les tests Visual Gate pointent vers les captures NS06.

## 4. Graph placeholder behavior

Le graph affiche :

- `Graph read-only` ;
- un sous-texte : lecture linéaire prudente des étapes disponibles ;
- `Étapes narratives réelles` avec compteur réel ;
- `Source Step Studio` ;
- `Relations détaillées à venir` ;
- une card par step réelle.

La représentation est volontairement linéaire. Elle ne prétend pas afficher les relations macro complètes, car le lot ne branche pas encore un read model graph riche.

## 5. Data source / anti-fake guarantees

Données affichées :

- `NarrativeStepSummary.name`
- `NarrativeStepSummary.description`
- `NarrativeStepSummary.globalScenarioId`
- `steps.length`

Filtrage :

```text
projection.steps.where((step) => step.globalScenarioId == selectedStory.id)
```

Garanties :

- `Audit Local Event Flow` ne devient pas un node graph ;
- aucune quête annexe n'est affichée ;
- aucune donnée Selbrume cible n'est ajoutée ;
- aucun node `Ch.1`, `Le port`, `Les marais`, `Le phare`, `Épilogue` n'est inventé ;
- aucun chiffre cible `5`, `27`, `412`, `18`, `3` n'est codé comme donnée positive.

## 6. Empty state behavior

Un test couvre une fixture avec `StepStudioDocument(steps: <StepStudioStep>[])`.

Dans ce cas, le graph affiche :

```text
Aucune étape narrative disponible pour cette storyline.
```

Note : un scénario global sans metadata Step Studio déclenche le fallback legacy existant du parser Step Studio. Pour tester un vrai état vide, la fixture fournit donc explicitement un document Step Studio vide.

## 7. Disabled interactions

Le lot ne crée aucune interaction graph :

- pas de drag/drop ;
- pas d'ajout de node ;
- pas de suppression ;
- pas d'édition ;
- pas de zoom ;
- pas de mini-map ;
- pas de clic de sélection graph.

Les protections existantes restent couvertes :

- tabs futures non mutantes ;
- `Nouvelle storyline` disabled / non mutante ;
- `Valider` disabled / non mutant ;
- bouton `+` du panneau secondaire disabled / non mutant.

## 8. Design System Gate

Primitives utilisées :

- `PokeMapPageSurface`
- `PokeMapCard`
- `PokeMapIconTile`
- `PokeMapStatusTile`
- `PokeMapTone`
- `context.pokeMapColors`

Composants privés ajoutés :

- `_StorylineGraphSection`
- `_StorylineGraphNodeList`
- `_StorylineGraphNode`
- `_StorylineGraphEmptyState`

Ces composants sont feature-specific et composent les primitives PokeMap. Aucun composant générique local n'a été créé.

Commande :

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
```

Sortie :

```text
Sortie : <vide>
```

Note : `rg` retourne le code 1 quand aucune occurrence n'est trouvée.

## 9. Sidebar / Maps guardrail

`Maps` reste absent de la sidebar interne Narrative Studio.

Le lot ne modifie pas :

- `narrative_studio_sidebar.dart` ;
- `ProjectExplorerPanel` ;
- `map_core` ;
- `map_runtime` ;
- `map_gameplay` ;
- `map_battle`.

## 10. Tests added or modified

Tests modifiés :

- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`

Couverture ajoutée :

- zone graph visible via key `storylines-graph-read-only` ;
- affichage `Graph read-only` ;
- affichage `Étapes narratives réelles` ;
- affichage de `Audit Step From Metadata` ;
- affichage de `Audit Step Detail From Metadata` ;
- source `Source Step Studio` dans le graph ;
- relations détaillées à venir ;
- absence de l'ancien placeholder `Graph — à venir` ;
- empty state avec document Step Studio vide ;
- absence de `Audit Local Event Flow` dans le graph ;
- chemins Visual Gate NS06.

## 11. Visual Gate

Captures produites :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_center.png`

Métadonnées :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_center.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png May 28 09:38:39 2026 53336
reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_focus.png May 28 09:38:39 2026 45360
reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_center.png May 28 09:38:39 2026 47419
```

Analyse visuelle :

- Desktop : thème dark actif, trois zones stables, panneau secondaire NS04 conservé, header/tabs/KPI NS05 conservés, graph read-only visible.
- Focus : le graph occupe bien la zone basse, sans mini-map ni zoom controls.
- Center/medium : le layout reste stable et le graph s'empile correctement sous les KPI.

Limite : les screenshots Flutter golden utilisent la police Ahem ; ils prouvent surtout structure, thème, densité et overflow.

## 12. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- `NS-STORYLINES-06` marqué `DONE` ;
- résumé du résultat ajouté ;
- fichiers créés/modifiés listés ;
- tests et analyse listés ;
- captures Visual Gate listées ;
- Design System Gate confirmé ;
- absence de fake data confirmée ;
- absence de couleurs hardcodées confirmée ;
- prochain lot recommandé : `NS-STORYLINES-07 — Storyline Inspector Read-only V0`.

## 13. Commands run

Commande initiale :

```bash
git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git diff --check
```

Sortie initiale :

```text
main
```

Interprétation : branche `main`, status initial vide, diff stat initial vide, diff name-only initial vide, diff check initial sans sortie.

Commande TDD red :

```bash
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
```

Sortie red pertinente :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'storylines-graph-read-only'>]: []>

Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'storylines-graph-read-only'>]: []>

Could not be compared against non-existent file:
"../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png"
```

Commande update goldens :

```bash
cd packages/map_editor && dart format lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart && flutter test --update-goldens test/storylines_workspace_shell_test.dart
```

Sortie :

```text
Formatted test/storylines_workspace_shell_test.dart
Formatted 2 files (1 changed) in 0.01 seconds.
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-06 Storyline graph placeholder V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-06 Storyline graph placeholder V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-06 Storyline graph placeholder V0 keeps Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +3: NS-STORYLINES-06 Storyline graph placeholder V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +4: NS-STORYLINES-06 Storyline graph placeholder V0 storylines UI source keeps raw colors out of the feature
00:00 +5: NS-STORYLINES-06 Storyline graph placeholder V0 storylines action test does not use silent taps
00:00 +6: NS-STORYLINES-06 Storyline graph placeholder V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +7: NS-STORYLINES-06 Storyline graph placeholder V0 writes Visual Gate screenshots
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
00:01 +8: All tests passed!
```

Commande test Storylines :

```bash
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-06 Storyline graph placeholder V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-06 Storyline graph placeholder V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-06 Storyline graph placeholder V0 keeps Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +3: NS-STORYLINES-06 Storyline graph placeholder V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +4: NS-STORYLINES-06 Storyline graph placeholder V0 storylines UI source keeps raw colors out of the feature
00:00 +5: NS-STORYLINES-06 Storyline graph placeholder V0 storylines action test does not use silent taps
00:00 +6: NS-STORYLINES-06 Storyline graph placeholder V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +7: NS-STORYLINES-06 Storyline graph placeholder V0 writes Visual Gate screenshots
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
00:01 +8: All tests passed!
```

Commande caractérisation :

```bash
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

Commande projection :

```bash
cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart
```

Sortie :

```text
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: All tests passed!
```

Commande analyse ciblée :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart
```

Sortie :

```text
Analyzing 4 items...

No issues found! (ran in 2.6s)
```

Commande screenshots :

```bash
file reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_focus.png reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_center.png && stat -f '%N %Sm %z' reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_focus.png reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_center.png
```

Sortie : voir section `11. Visual Gate`.

Commande final git evidence :

```bash
git status --short --untracked-files=all && git diff --stat && git diff --name-only && git diff --check
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_current_global_story_characterization_test.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_focus.png
 .../lib/src/ui/canvas/storylines_workspace.dart    | 262 ++++++++++++++++++---
 ...current_global_story_characterization_test.dart |   5 +-
 .../test/storylines_workspace_shell_test.dart      |  92 +++++++-
 .../storylines/road_map_storylines.md              |  33 ++-
 4 files changed, 344 insertions(+), 48 deletions(-)
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

La partie `git diff --check` n'a produit aucune ligne après `git diff --name-only`.

## 14. Evidence Pack

Git branch initiale :

```text
main
```

Git status initial exact :

```text
Sortie : <vide>
```

Git diff --stat initial :

```text
Sortie : <vide>
```

Git diff --name-only initial :

```text
Sortie : <vide>
```

Git diff --check initial :

```text
Sortie : <vide>
```

Git status final exact :

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_current_global_story_characterization_test.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_focus.png
```

Git diff --stat final :

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 262 ++++++++++++++++++---
 ...current_global_story_characterization_test.dart |   5 +-
 .../test/storylines_workspace_shell_test.dart      |  92 +++++++-
 .../storylines/road_map_storylines.md              |  33 ++-
 4 files changed, 344 insertions(+), 48 deletions(-)
```

Git diff --name-only final :

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

Git diff --check final :

```text
Sortie : <vide>
```

Liste des fichiers lus : voir section `2. Inputs read`.

Liste des fichiers absents mais attendus :

```text
Sortie : <vide>
```

Contenu complet du rapport créé : le présent fichier constitue le contenu complet du rapport créé.

Contenu complet des fichiers créés :

- Rapport Markdown : le présent fichier.
- Screenshots PNG : fichiers binaires listés et vérifiés par `file` / `stat`.

Diff complet des fichiers modifiés :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 2fc40476..ccfec830 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -52,6 +52,7 @@ class StorylinesWorkspace extends StatelessWidget {
           Expanded(
             child: _StorylineMainPanel(
               selectedStory: selectedStory,
+              steps: relatedSteps,
               stepCount: relatedSteps.length,
               globalStoryCount: projection.globalStories.length,
               linkedCutsceneCount: linkedCutsceneCount,
@@ -314,19 +315,20 @@ class _StorylineSummaryRow extends StatelessWidget {
 class _StorylineMainPanel extends StatelessWidget {
   const _StorylineMainPanel({
     required this.selectedStory,
+    required this.steps,
     required this.stepCount,
     required this.globalStoryCount,
     required this.linkedCutsceneCount,
   });
 
   final NarrativeScenarioSummary? selectedStory;
+  final List<NarrativeStepSummary> steps;
   final int stepCount;
   final int globalStoryCount;
   final int linkedCutsceneCount;
 
   @override
   Widget build(BuildContext context) {
-    final colors = context.pokeMapColors;
     return PokeMapPanel(
       key: const ValueKey('storylines-main-panel'),
       expandChild: true,
@@ -347,45 +349,241 @@ class _StorylineMainPanel extends StatelessWidget {
           ),
           const SizedBox(height: 16),
           Expanded(
-            child: PokeMapPageSurface(
-              padding: const EdgeInsets.all(18),
-              child: SingleChildScrollView(
-                child: Column(
-                  crossAxisAlignment: CrossAxisAlignment.start,
-                  children: [
-                    Text(
-                      'Zone centrale Storyline',
-                      style: TextStyle(
-                        color: colors.textPrimary,
-                        fontSize: 15,
-                        fontWeight: FontWeight.w800,
-                      ),
-                    ),
-                    const SizedBox(height: 8),
-                    Text(
-                      'Le graph macro reste read-only tant que ses relations ne sont pas stabilisées.',
-                      style: TextStyle(
-                        color: colors.textSecondary,
-                        fontSize: 12.5,
-                        height: 1.35,
-                      ),
-                    ),
-                    const SizedBox(height: 16),
-                    const PokeMapStatusTile(
-                      label: 'Graph — à venir',
-                      value: 'Placeholder read-only',
-                      icon: CupertinoIcons.arrow_branch,
-                      tone: PokeMapTone.neutral,
-                    ),
-                    const SizedBox(height: 10),
-                    const PokeMapStatusTile(
-                      label: 'Chapitres — à venir',
-                      value: 'Read model futur',
-                      icon: CupertinoIcons.square_list,
-                      tone: PokeMapTone.neutral,
-                    ),
-                  ],
-                ),
-              ),
-            ),
+            child: _StorylineGraphSection(steps: steps),
           ),
         ],
       ),
```

Les fichiers non trackés ne sont pas listés par `git diff --name-only`; ils sont listés par `git status final exact` et dans la section fichiers créés.

## 15. Self-review

Ce qui est prouvé :

- le graph read-only existe ;
- il affiche la step réelle `Audit Step From Metadata` ;
- il affiche la description réelle `Audit Step Detail From Metadata` ;
- il affiche une source prudente `Source Step Studio` ;
- il marque les relations détaillées comme à venir ;
- il couvre un empty state avec document Step Studio vide ;
- `Audit Local Event Flow` n'apparaît pas dans le graph ;
- les tabs/actions futures restent non mutantes ;
- les tests ciblés passent ;
- l'analyse ciblée passe ;
- les screenshots dark NS06 existent et ont été inspectés.

Ce qui reste volontairement hors scope :

- graph riche ;
- mini-map ;
- zoom controls ;
- édition de nodes ou edges ;
- quêtes annexes ;
- branches conditionnelles ;
- inspecteur final ;
- onglet Chapitres actif.

Risque résiduel :

- la représentation linéaire est une projection de lecture, pas encore un graph métier complet. C'est volontaire pour éviter de simuler des relations non prouvées.
