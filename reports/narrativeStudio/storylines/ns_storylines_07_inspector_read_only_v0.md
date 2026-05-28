# NS-STORYLINES-07 — Storyline Inspector Read-only V0

## 1. Executive summary

NS-STORYLINES-07 est livré.

Le panneau droit placeholder du workspace Storylines est remplacé par un inspecteur `Détails de la storyline` read-only.

L'inspecteur V0 affiche uniquement :

- le nom réel de la storyline sélectionnée ;
- la description réelle ou un fallback honnête ;
- le type prudent `Storyline principale` ;
- la source `ScenarioAsset globalStory` ;
- le mode `Lecture seule` ;
- les compteurs réels/dérivés d'étapes narratives et de cutscenes liées ;
- des sections futures explicitement disabled / non branchées.

Le lot ne crée aucun tag réel, world rule, fact, activité récente, quête liée, priorité, statut actif ou action mutante.

Le prochain lot recommandé est `NS-STORYLINES-08 — Chapters Tab Read-only V0`.

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
- `reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md`
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
- `Superpowers test-driven-development` skill.
- `Superpowers verification-before-completion` skill.

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

- `reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_panel.png`

Résumé technique :

- `_StorylineInspectorPlaceholder` est remplacé par `_StorylineInspectorPanel`.
- `_StorylineInspectorPanel` reçoit `selectedStory`, `stepCount` et `linkedCutsceneCount`.
- L'inspecteur utilise `PokeMapInspectorPanel` avec la key `storylines-inspector-read-only`.
- Le contenu est scrollable dans la hauteur disponible pour éviter l'overflow sur le Visual Gate medium.
- `_StorylineInspectorContent` affiche identité, source, mode, structure et sections futures.
- `_StorylineInspectorEmptyState` couvre le cas sans globalStory disponible.
- `_formatFrenchCount` garde un wording lisible pour `1 étape narrative` et `0 cutscene liée`.

## 4. Inspector behavior

Avec une storyline sélectionnée, l'inspecteur affiche :

- `Détails de la storyline`
- le titre réel, par exemple `Audit Story From Scenario` dans la fixture ;
- la description réelle, par exemple `Audit description from scenario` ;
- `Storyline principale` ;
- `ScenarioAsset globalStory` ;
- `Lecture seule` ;
- `1 étape narrative` dans la fixture principale ;
- `0 cutscene liée` dans la fixture principale ;
- une section `Fonctionnalités à venir`.

L'inspecteur ne propose pas de bouton final actif comme `Ouvrir la storyline`, `Modifier` ou `Valider`.

## 5. Data source / anti-fake guarantees

Données utilisées :

- `NarrativeScenarioSummary.name`
- `NarrativeScenarioSummary.description`
- `NarrativeScenarioSummary.id`
- `projection.steps.where((step) => step.globalScenarioId == selectedStory.id)`
- `NarrativeStepSummary.linkedCutsceneIds`

Garanties anti-fake :

- aucun `localEventFlow` n'est affiché dans l'inspecteur ;
- aucun tag réel n'est créé ;
- aucune règle du monde réelle n'est inventée ;
- aucun fact réel n'est inventé ;
- aucune activité récente n'est inventée ;
- aucune priorité `Haute`, aucun statut `Active`, aucun état `Validé` ou `À jour` n'est affiché ;
- aucune donnée Selbrume cible n'est hardcodée ;
- aucun chiffre cible `5`, `27`, `412`, `18`, `3` n'est codé comme donnée positive.

## 6. Disabled sections

Sections futures affichées dans l'inspecteur :

| Section | État V0 | Raison |
|---|---|---|
| Tags | `À venir` | modèle absent en V0 |
| Règles du monde | `Non branché` | source fake risk |
| Facts | `Non branché` | source fake risk |
| Activité récente | `À venir` | aucune source d'activité récente |
| Quêtes liées | `Modèle absent en V0` | pas de modèle de quêtes annexes |

Ces sections sont informatives et read-only. Elles ne sont pas traitées comme des données réelles.

## 7. Empty state behavior

Un test couvre un projet sans `ScenarioAsset(scope == globalStory)`.

Dans ce cas, l'inspecteur affiche :

```text
Aucune storyline sélectionnée.
```

Il n'affiche pas :

```text
ScenarioAsset globalStory
Audit Local Event Flow
```

## 8. Disabled interactions

Le lot ne crée aucune interaction d'inspecteur :

- pas d'édition ;
- pas d'ouverture d'un détail complet ;
- pas de validation ;
- pas de navigation Maps ;
- pas de création de tag ;
- pas de création de world rule ;
- pas de création de fact ;
- pas d'activité récente calculée.

Les protections existantes restent couvertes :

- tabs futures non mutantes ;
- `Nouvelle storyline` disabled / non mutante ;
- `Valider` disabled / non mutant ;
- bouton `+` du panneau secondaire disabled / non mutant.

## 9. Design System Gate

Primitives utilisées :

- `PokeMapInspectorPanel`
- `PokeMapCard`
- `PokeMapIconTile`
- `PokeMapStatusTile`
- `PokeMapTone`
- `context.pokeMapColors`

Composants privés ajoutés :

- `_StorylineInspectorPanel`
- `_StorylineInspectorContent`
- `_StorylineInspectorSection`
- `_StorylineInspectorTextLine`
- `_StorylineInspectorFutureSection`
- `_StorylineInspectorEmptyState`

Ces composants sont feature-specific et composent les primitives PokeMap. Ils ne créent pas une card, pill, panel, status row ou inspector section générique parallèle au design system.

Commande :

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
```

Sortie :

```text
Sortie : <vide>
```

Note : `rg` retourne le code 1 quand aucune occurrence n'est trouvée.

## 10. Sidebar / Maps guardrail

`Maps` reste absent de la sidebar interne Narrative Studio.

Le lot ne modifie pas :

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `ProjectExplorerPanel`
- `packages/map_core/lib/`
- `packages/map_runtime/`
- `packages/map_gameplay/`
- `packages/map_battle/`

Les cartes restent hors de la sidebar interne Storylines. Si elles deviennent nécessaires, elles devront être traitées plus tard comme `Lieux liés` ou `Cartes liées` dans un inspecteur sourcé.

## 11. Tests added or modified

Tests modifiés :

- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`

Couverture ajoutée ou ajustée :

- key stable `storylines-inspector-read-only` ;
- disparition du placeholder `Inspecteur Storyline — à venir` ;
- affichage `Détails de la storyline` ;
- affichage titre / description réels ;
- affichage `ScenarioAsset globalStory` ;
- affichage `1 étape narrative` ;
- affichage `0 cutscene liée` ;
- sections futures `Tags`, `Facts`, `Activité récente`, `Quêtes liées` ;
- états `Non branché` et `À venir` dans l'inspecteur ;
- empty state sans globalStory ;
- absence de `Audit Local Event Flow` dans l'inspecteur ;
- anti-fake renforcé avec `Active`, `Haute`, `Validé`, `À jour` comme chaînes interdites.

## 12. Visual Gate

Captures produites :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_panel.png`

Métadonnées :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_panel.png:   PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_desktop.png 2026-05-28 10:06:18 CEST 57878
reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_focus.png 2026-05-28 10:06:18 CEST 47660
reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_panel.png 2026-05-28 10:06:18 CEST 51804
```

Résultat visuel contrôlé :

- dark theme actif ;
- panneau secondaire NS04 conservé ;
- header/tabs/KPI NS05 conservés ;
- graph read-only NS06 conservé ;
- inspecteur droit remplacé par un panneau read-only structuré ;
- sections futures disabled ;
- pas de tags fake ;
- pas de world rules fake ;
- pas d'activité récente fake ;
- layout trois zones stable ;
- pas d'overflow visible.

## 13. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- `NS-STORYLINES-07` est marqué `DONE` ;
- le résumé du résultat a été ajouté ;
- les fichiers créés / modifiés sont listés ;
- les tests, l'analyse ciblée et les captures Visual Gate sont listés ;
- le Design System Gate est confirmé ;
- l'absence de fake data est confirmée ;
- l'absence de couleurs hardcodées est confirmée ;
- le prochain lot recommandé est `NS-STORYLINES-08 — Chapters Tab Read-only V0`.

## 14. Commands run

### Git initial

Commande :

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie initiale capturée au démarrage du lot avant les modifications NS-STORYLINES-07 :

```text
main
M  packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
M  packages/map_editor/test/storylines_current_global_story_characterization_test.dart
M  packages/map_editor/test/storylines_workspace_shell_test.dart
A  reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md
M  reports/narrativeStudio/storylines/road_map_storylines.md
A  reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_center.png
A  reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_desktop.png
A  reports/narrativeStudio/storylines/screenshots/ns_storylines_06_graph_placeholder_focus.png
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
cd packages/map_editor && dart format test/storylines_workspace_shell_test.dart && flutter test test/storylines_workspace_shell_test.dart
```

Sortie utile :

```text
Formatted test/storylines_workspace_shell_test.dart
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'storylines-inspector-read-only'>]: []>
Could not be compared against non-existent file:
"../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_desktop.png"
```

### Format + Visual Gate generation

Commande :

```bash
cd packages/map_editor && dart format lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart && flutter test --update-goldens test/storylines_workspace_shell_test.dart
```

Sortie exacte :

```text
Formatted lib/src/ui/canvas/storylines_workspace.dart
Formatted 2 files (1 changed) in 0.01 seconds.
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-07 Storyline inspector read-only V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-07 Storyline inspector read-only V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-07 Storyline inspector read-only V0 renders an honest inspector empty state without global story
00:00 +3: NS-STORYLINES-07 Storyline inspector read-only V0 keeps Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +4: NS-STORYLINES-07 Storyline inspector read-only V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +5: NS-STORYLINES-07 Storyline inspector read-only V0 storylines UI source keeps raw colors out of the feature
00:00 +6: NS-STORYLINES-07 Storyline inspector read-only V0 storylines action test does not use silent taps
00:00 +7: NS-STORYLINES-07 Storyline inspector read-only V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +8: NS-STORYLINES-07 Storyline inspector read-only V0 writes Visual Gate screenshots
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
00:01 +9: All tests passed!
```

### Storylines workspace shell test

Commande :

```bash
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-07 Storyline inspector read-only V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-07 Storyline inspector read-only V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-07 Storyline inspector read-only V0 renders an honest inspector empty state without global story
00:00 +3: NS-STORYLINES-07 Storyline inspector read-only V0 keeps Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +4: NS-STORYLINES-07 Storyline inspector read-only V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +5: NS-STORYLINES-07 Storyline inspector read-only V0 storylines UI source keeps raw colors out of the feature
00:00 +6: NS-STORYLINES-07 Storyline inspector read-only V0 storylines action test does not use silent taps
00:00 +7: NS-STORYLINES-07 Storyline inspector read-only V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +8: NS-STORYLINES-07 Storyline inspector read-only V0 writes Visual Gate screenshots
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
00:01 +9: All tests passed!
```

### Current global story characterization test

Commande :

```bash
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
```

Sortie exacte :

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

### Narrative workspace projection test

Commande :

```bash
cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart
```

Sortie exacte :

```text
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: All tests passed!
```

### Targeted analyze

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart
```

Sortie exacte :

```text
Analyzing 4 items...

No issues found! (ran in 1.9s)
```

## 15. Evidence Pack

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
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_current_global_story_characterization_test.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_focus.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_panel.png
 .../lib/src/ui/canvas/storylines_workspace.dart    | 352 ++++++++++++++++++---
 ...current_global_story_characterization_test.dart |   2 +-
 .../test/storylines_workspace_shell_test.dart      | 130 +++++++-
 .../storylines/road_map_storylines.md              |  34 +-
 4 files changed, 454 insertions(+), 64 deletions(-)
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

Sortie `git diff --check` finale :

```text
Sortie : <vide>
```

### Fichiers lus

Voir section `2. Inputs read`.

### Fichiers absents mais attendus

```text
Sortie : <vide>
```

### Contenu complet du rapport créé

Le contenu complet du rapport créé est le présent fichier Markdown, de l'en-tête `# NS-STORYLINES-07 — Storyline Inspector Read-only V0` à la section `16. Self-review`.

### Contenu complet des fichiers créés

Fichier Markdown créé :

- `reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md`

Captures PNG créées :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_desktop.png` : 1600 x 1000, 57878 bytes.
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_focus.png` : 1600 x 700, 47660 bytes.
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_07_inspector_panel.png` : 1180 x 1000, 51804 bytes.

### Diff complet des fichiers modifiés

Résumé exact du diff avant création du rapport :

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 352 ++++++++++++++++++---
 ...current_global_story_characterization_test.dart |   2 +-
 .../test/storylines_workspace_shell_test.dart      | 130 +++++++-
 3 files changed, 425 insertions(+), 59 deletions(-)
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
```

Diff roadmap ajouté pendant la clôture du lot :

```diff
-| NS-STORYLINES-07 | Storyline Inspector Read-only V0 | editor UI | TODO | NS-STORYLINES-08 |
+| NS-STORYLINES-07 | Storyline Inspector Read-only V0 | editor UI | DONE | NS-STORYLINES-08 |
...
- Statut : TODO.
+- Statut : DONE.
+- Résultat NS-STORYLINES-07 : inspecteur droit remplacé par un panneau `Détails de la storyline` read-only, sourcé par la storyline sélectionnée.
+- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md`, captures Visual Gate `ns_storylines_07_inspector_desktop.png`, `ns_storylines_07_inspector_focus.png`, `ns_storylines_07_inspector_panel.png`.
+- Données : nom et description réels via `NarrativeScenarioSummary`, type prudent `Storyline principale`, source `ScenarioAsset globalStory`, compteurs d'étapes et cutscenes liées dérivés des steps filtrées.
+- Sections futures : `Tags`, `Règles du monde`, `Facts`, `Activité récente`, `Quêtes liées` affichées uniquement comme `À venir`, `Non branché` ou `Modèle absent en V0`.
+- Empty state : absence de globalStory couverte par test avec `Aucune storyline sélectionnée.`.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
+- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
+- Visual Gate : dark theme actif ; captures desktop, focus et panel produites.
+- Design System Gate : confirmé ; `PokeMapInspectorPanel`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
+- Fake data : aucun tag réel, world rule, fact, activité récente, priorité, statut `Active`, niveau `Haute`, donnée Selbrume ou chiffre cible ajouté ; `localEventFlow` reste absent de l'inspecteur.
...
-Current lot: NS-STORYLINES-06
+Current lot: NS-STORYLINES-07
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-07 — Storyline Inspector Read-only V0
+Next recommended lot: NS-STORYLINES-08 — Chapters Tab Read-only V0
...
-| NS-STORYLINES-07 | TODO | 2026-05-27 | Inspector storyline. |
+| NS-STORYLINES-07 | DONE | 2026-05-28 | Inspector read-only livré avec données réelles, sections futures disabled et empty state. |
```

### Sorties exactes des tests ciblés

Voir section `14. Commands run`.

### Sortie exacte de l'analyse ciblée

Voir section `14. Commands run`.

### Résultats du Visual Gate

Voir section `12. Visual Gate`.

### Mini audit Design System

- Aucun `Color(0x...)` ajouté.
- Aucun `Colors.*` ajouté.
- Aucun composant générique local hors design system ajouté.
- Les nouveaux composants privés sont métier Storylines et composent les primitives PokeMap.
- Les futures sections sont disabled / non branchées.

### Recherche `Color(0x...)` / `Colors.*`

Commande :

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
```

Sortie :

```text
Sortie : <vide>
```

## 16. Self-review

Points validés :

- L'inspecteur Storyline read-only existe et remplace le placeholder.
- Les données affichées viennent de la storyline sélectionnée et des steps filtrées.
- Les sections `Tags`, `Règles du monde`, `Facts`, `Activité récente`, `Quêtes liées` restent disabled / à venir.
- `localEventFlow` ne devient pas une donnée d'inspecteur.
- `Maps` reste absent de la sidebar interne.
- Les actions futures restent non mutantes via les tests existants.
- Le Visual Gate dark est produit.
- Les tests ciblés passent.
- L'analyse ciblée est propre.

Limites assumées :

- L'inspecteur ne sait pas encore ouvrir une vue détail, éditer, valider ou naviguer.
- Les world rules, facts, tags, activité récente et quêtes liées restent volontairement non branchés.
- L'onglet `Chapitres` n'est pas implémenté dans ce lot.

Décision de suite :

- Continuer avec `NS-STORYLINES-08 — Chapters Tab Read-only V0`.
