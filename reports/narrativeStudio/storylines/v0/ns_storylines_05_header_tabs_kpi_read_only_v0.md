# NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0

## 1. Executive summary

NS-STORYLINES-05 est livré.

La zone centrale haute du workspace Storylines affiche maintenant :

- un header Storyline V0 read-only basé sur la `globalStory` sélectionnée ;
- le vrai titre et la vraie description issus du scénario ;
- un type prudent `Storyline principale` ;
- des statuts honnêtes `Lecture seule`, `Source réelle`, `Storylines V0` ;
- une rangée de tabs Storyline visible, non mutante ;
- une rangée de KPI read-only avec valeurs réelles/dérivées ou état `À venir`.

Aucune donnée cible fake n'a été ajoutée. Aucun `localEventFlow` n'est transformé en quête, storyline ou KPI. `Maps` reste absent de la sidebar interne Narrative Studio. Le prochain lot recommandé reste `NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0`.

## 2. Inputs read

Fichiers obligatoires lus ou relus :

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

Tous les chemins obligatoires vérifiés pour ce lot existent.

## 3. Implementation summary

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

Fichiers créés :

- `reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png`

Changements principaux :

- `_StorylineMainPanel` utilise désormais `PokeMapPanel(expandChild: true)` pour contenir proprement la zone centrale.
- Ajout de `_StorylineHeaderSection`, composant feature-specific qui compose `PokeMapIconTile` et `PokeMapStatusTile`.
- Ajout de `_StorylineTabsRow`, composant feature-specific qui compose `PokeMapSegmentedTabs`.
- Ajout de `_StorylineKpiStrip`, composant feature-specific qui compose `PokeMapMetricCard`.
- Calcul de `linkedCutsceneCount` depuis les `linkedCutsceneIds` des steps liées au scénario sélectionné.
- Conservation du panneau secondaire NS04 et de l'inspecteur placeholder.
- Adaptation des tests de caractérisation, car le libellé `Étapes narratives` apparaît maintenant dans les KPI.

## 4. Header behavior

Le header central affiche uniquement des données réelles ou des statuts V0 honnêtes :

- titre : `selectedStory.name`, donc `ScenarioAsset.name` via `NarrativeWorkspaceProjection` ;
- description : `selectedStory.description`, donc `ScenarioAsset.description` ;
- fallback description : `Description non renseignée dans le scénario.` si aucune description réelle n'existe ;
- type : `Storyline principale`, wording prudent pour `ScenarioScope.globalStory` ;
- état : `Lecture seule` ;
- source : `Source réelle` ;
- mode : `Storylines V0`.

Le header n'affiche pas `Active`, `Haute`, `Défini`, `Validé` ou `À jour`, car ces statuts ne sont pas sourcés pour Storylines V0.

## 5. Tabs behavior

Tabs visibles :

- `Graph` ;
- `Chapitres` ;
- `Étapes` ;
- `Scènes` ;
- `Statistiques` ;
- `Tests`.

Comportement V0 :

- `Graph` est la tab principale / sélectionnée visuellement.
- Les autres tabs sont visibles mais non branchées : aucun `onTap`, aucune mutation projet, aucun changement de workspace.
- La rangée est scrollable horizontalement pour éviter les overflows medium.
- `Scènes` reste une destination prudente / non active, car le mapping scene/step/cutscene n'est pas prouvé.

## 6. KPI behavior

KPI affichés :

| KPI | Valeur | Source | Décision V0 |
|---|---:|---|---|
| Storylines globales | réelle | `projection.globalStories.length` | Display in V0 |
| Étapes narratives | réelle | steps filtrées par `globalScenarioId` | Display in V0 |
| Cutscenes liées | dérivée | union des `linkedCutsceneIds` non vides des steps liées | Display in V0 |
| Chapitres | `À venir` | pas exposé au widget par le read model actuel | Disable in V0 |
| Avertissements structurels | `À venir` | pas de diagnostics/validator global branché | Disable in V0 |

KPI volontairement non affichés comme actifs :

- `Scènes liées` ;
- `Dialogues lignes` ;
- `Facts modifiés` ;
- `World Rules affectées` ;
- `Quêtes liées` ;
- `Activité récente` ;
- `Problèmes globaux` ;
- `Validation globale`.

## 7. Data source / anti-fake guarantees

Garanties anti-fake conservées :

- aucun chiffre cible `5`, `27`, `412`, `18`, `3` n'est codé comme donnée positive ;
- aucune donnée Selbrume cible n'est ajoutée ;
- aucun tag cible n'est affiché ;
- aucune world rule cible n'est affichée ;
- aucune activité récente cible n'est affichée ;
- `Audit Local Event Flow` n'apparaît pas dans la liste des storylines, les quêtes annexes, les tabs ou les KPI ;
- les valeurs de test `2`, `1`, `0` proviennent de la fixture neutre et des données réelles/dérivées.

Chaînes cible interdites vérifiées par tests :

- `La brume du phare`
- `Les cristaux de sel`
- `Le Goélise du port`
- `La cabane du phare`
- `Mystère`
- `Exploration`
- `Phare`
- `Côtiers`
- `412`
- `18`
- `RÈGLES DU MONDE AFFECTÉES`
- `DERNIÈRE ACTIVITÉ`

## 8. Disabled features

Fonctionnalités encore disabled / non branchées :

- création de storyline ;
- validation globale ;
- recherche active ;
- notifications ;
- bouton `+` du panneau secondaire ;
- quêtes annexes ;
- tabs futures ;
- graph riche ;
- onglet Chapitres réel ;
- statistiques ;
- tests Storylines ;
- facts ;
- world rules ;
- activité récente.

Les tests NS03-bis et NS04 restent verts et protègent la non-mutation des actions futures.

## 9. Design System Gate

Primitives utilisées :

- `PokeMapPanel`
- `PokeMapPageSurface`
- `PokeMapIconTile`
- `PokeMapStatusTile`
- `PokeMapMetricCard`
- `PokeMapSegmentedTabs`
- `PokeMapSegmentedTab`
- `PokeMapTone`
- `context.pokeMapColors`

Audit :

- aucun `Color(0x...)` ajouté ;
- aucun `Colors.*` ajouté ;
- aucune couleur locale hardcodée ;
- aucun composant générique local ;
- les nouveaux widgets privés sont feature-specific et composent les primitives PokeMap.

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

`Maps` n'est pas réintroduit dans `NarrativeStudioSidebar`.

Le lot ne modifie pas :

- `narrative_studio_sidebar.dart` ;
- `ProjectExplorerPanel` ;
- `map_core` ;
- `map_runtime` ;
- `map_gameplay` ;
- `map_battle`.

Les tests continuent de vérifier que `Maps` est absent de la sidebar interne Narrative Studio.

## 11. Tests added or modified

Tests modifiés :

- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`

Couvertures ajoutées ou renforcées :

- présence du header central Storyline ;
- présence des tabs Storyline ;
- présence du strip KPI ;
- valeurs KPI réelles/dérivées ;
- non-mutation des tabs futures ;
- absence de `Audit Local Event Flow` comme storyline/quête/KPI ;
- chemins Visual Gate NS05 ;
- libellé `Étapes narratives` dans le test de caractérisation.

## 12. Visual Gate

Captures produites :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png`

Métadonnées :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png May 28 08:08:00 2026 49340
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png May 28 08:08:00 2026 43862
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png May 28 08:08:00 2026 47030
```

Analyse visuelle :

- Desktop : thème dark actif, layout trois zones stable, panneau secondaire NS04 conservé, header/tabs/KPI visibles, inspecteur placeholder conservé.
- Focus : la zone centrale haute est lisible, les tabs sont visibles et les KPI tiennent dans la largeur desktop/focus.
- Center/medium : les KPI passent en grille compacte sans overflow visible ; les tabs restent contenues via scroll horizontal.

Limite connue : les screenshots Flutter golden utilisent la police de test Ahem ; ils prouvent surtout le thème, la structure, la densité et l'absence d'overflow, pas la typographie finale.

## 13. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- `NS-STORYLINES-05` marqué `DONE` ;
- résumé du résultat ajouté ;
- fichiers créés/modifiés listés ;
- tests et analyse listés ;
- captures Visual Gate listées ;
- Design System Gate confirmé ;
- absence de fake data confirmée ;
- absence de couleurs hardcodées confirmée ;
- prochain lot recommandé : `NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0`.

## 14. Commands run

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
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'storylines-header-section'>]: []>

Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'storylines-tabs'>]: []>

Could not be compared against non-existent file:
"../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png"
```

Commande format + goldens :

```bash
cd packages/map_editor && dart format lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart && flutter test --update-goldens test/storylines_workspace_shell_test.dart
```

Sortie :

```text
Formatted 2 files (0 changed) in 0.01 seconds.
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-05 Storyline header tabs KPI V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-05 Storyline header tabs KPI V0 keeps Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-05 Storyline header tabs KPI V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +3: NS-STORYLINES-05 Storyline header tabs KPI V0 storylines UI source keeps raw colors out of the feature
00:00 +4: NS-STORYLINES-05 Storyline header tabs KPI V0 storylines action test does not use silent taps
00:00 +5: NS-STORYLINES-05 Storyline header tabs KPI V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +6: NS-STORYLINES-05 Storyline header tabs KPI V0 writes Visual Gate screenshots
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
00:01 +7: All tests passed!
```

Commande ciblée Storylines :

```bash
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-05 Storyline header tabs KPI V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-05 Storyline header tabs KPI V0 keeps Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-05 Storyline header tabs KPI V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +3: NS-STORYLINES-05 Storyline header tabs KPI V0 storylines UI source keeps raw colors out of the feature
00:00 +4: NS-STORYLINES-05 Storyline header tabs KPI V0 storylines action test does not use silent taps
00:00 +5: NS-STORYLINES-05 Storyline header tabs KPI V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +6: NS-STORYLINES-05 Storyline header tabs KPI V0 writes Visual Gate screenshots
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
00:01 +7: All tests passed!
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
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
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

No issues found! (ran in 2.1s)
```

Commande fichiers screenshots :

```bash
file reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png && stat -f '%N %Sm %z' reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png
```

Sortie :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png May 28 08:08:00 2026 49340
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png May 28 08:08:00 2026 43862
reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png May 28 08:08:00 2026 47030
```

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
?? reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png
 .../lib/src/ui/canvas/storylines_workspace.dart    | 358 ++++++++++++++++-----
 ...current_global_story_characterization_test.dart |   2 +-
 .../test/storylines_workspace_shell_test.dart      | 123 ++++++-
 .../storylines/road_map_storylines.md              |  32 +-
 4 files changed, 416 insertions(+), 99 deletions(-)
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

La partie `git diff --check` n'a produit aucune ligne après `git diff --name-only`.

## 15. Evidence Pack

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
?? reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_05_header_tabs_kpi_focus.png
```

Git diff --stat final :

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 358 ++++++++++++++++-----
 ...current_global_story_characterization_test.dart |   2 +-
 .../test/storylines_workspace_shell_test.dart      | 123 ++++++-
 .../storylines/road_map_storylines.md              |  32 +-
 4 files changed, 416 insertions(+), 99 deletions(-)
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

Note : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers non trackés. Les fichiers créés par ce lot sont donc compensés par le `git status final exact`, la section `3. Implementation summary` et les métadonnées Visual Gate.

Liste des fichiers lus : voir section `2. Inputs read`.

Liste des fichiers absents mais attendus :

```text
Sortie : <vide>
```

Contenu complet du rapport créé : le présent fichier constitue le contenu complet du rapport créé, du titre `# NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0` jusqu'à `## 16. Self-review`.

Contenu complet des fichiers créés :

- Rapport Markdown : le présent fichier.
- Screenshots PNG : fichiers binaires listés et vérifiés par `file` / `stat` dans la section Visual Gate.

Diff complet des fichiers modifiés :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 98ab4e22..2fc40476 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -28,6 +28,11 @@ class StorylinesWorkspace extends StatelessWidget {
             .where((step) => step.globalScenarioId == story.id)
             .length,
     };
+    final linkedCutsceneCount = relatedSteps
+        .expand((step) => step.linkedCutsceneIds)
+        .where((id) => id.trim().isNotEmpty)
+        .toSet()
+        .length;
 
     return PokeMapPageSurface(
       key: const ValueKey('storylines-workspace-shell'),
@@ -48,6 +53,8 @@ class StorylinesWorkspace extends StatelessWidget {
             child: _StorylineMainPanel(
               selectedStory: selectedStory,
               stepCount: relatedSteps.length,
+              globalStoryCount: projection.globalStories.length,
+              linkedCutsceneCount: linkedCutsceneCount,
             ),
           ),
           const SizedBox(width: 12),
@@ -308,130 +315,303 @@ class _StorylineMainPanel extends StatelessWidget {
   const _StorylineMainPanel({
     required this.selectedStory,
     required this.stepCount,
+    required this.globalStoryCount,
+    required this.linkedCutsceneCount,
   });
 
   final NarrativeScenarioSummary? selectedStory;
   final int stepCount;
+  final int globalStoryCount;
+  final int linkedCutsceneCount;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
-    final description = selectedStory?.description.trim();
-    return PokeMapInspectorPanel(
+    return PokeMapPanel(
       key: const ValueKey('storylines-main-panel'),
+      expandChild: true,
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
-          Row(
-            crossAxisAlignment: CrossAxisAlignment.start,
-            children: [
-              const PokeMapIconTile(
-                icon: CupertinoIcons.link,
-                tone: PokeMapTone.narrative,
-                size: 42,
-                iconSize: 20,
-              ),
-              const SizedBox(width: 12),
-              Expanded(
+          _StorylineHeaderSection(
+            selectedStory: selectedStory,
+          ),
+          const SizedBox(height: 12),
+          const _StorylineTabsRow(),
+          const SizedBox(height: 12),
+          _StorylineKpiStrip(
+            globalStoryCount: globalStoryCount,
+            stepCount: stepCount,
+            linkedCutsceneCount: linkedCutsceneCount,
+          ),
+          const SizedBox(height: 16),
+          Expanded(
+            child: PokeMapPageSurface(
+              padding: const EdgeInsets.all(18),
+              child: SingleChildScrollView(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
-                      selectedStory?.name ?? 'Storyline non disponible',
-                      maxLines: 1,
-                      overflow: TextOverflow.ellipsis,
+                      'Zone centrale Storyline',
                       style: TextStyle(
                         color: colors.textPrimary,
-                        fontSize: 21,
+                        fontSize: 15,
                         fontWeight: FontWeight.w800,
                       ),
                     ),
-                    const SizedBox(height: 6),
+                    const SizedBox(height: 8),
                     Text(
-                      description == null || description.isEmpty
-                          ? 'Description non renseignée dans le scénario.'
-                          : description,
-                      maxLines: 2,
-                      overflow: TextOverflow.ellipsis,
+                      'Le graph macro reste read-only tant que ses relations ne sont pas stabilisées.',
                       style: TextStyle(
                         color: colors.textSecondary,
                         fontSize: 12.5,
-                        height: 1.3,
-                        fontWeight: FontWeight.w500,
+                        height: 1.35,
                       ),
                     ),
+                    const SizedBox(height: 16),
+                    const PokeMapStatusTile(
+                      label: 'Graph — à venir',
+                      value: 'Placeholder read-only',
+                      icon: CupertinoIcons.arrow_branch,
+                      tone: PokeMapTone.neutral,
+                    ),
+                    const SizedBox(height: 10),
+                    const PokeMapStatusTile(
+                      label: 'Chapitres — à venir',
+                      value: 'Read model futur',
+                      icon: CupertinoIcons.square_list,
+                      tone: PokeMapTone.neutral,
+                    ),
                   ],
                 ),
               ),
-              const SizedBox(width: 12),
-              const PokeMapStatusTile(
-                label: 'Mode lecture seule',
-                value: 'Storylines V0',
-                icon: CupertinoIcons.lock,
-                tone: PokeMapTone.info,
-              ),
-            ],
+            ),
           ),
-          const SizedBox(height: 18),
-          Wrap(
-            spacing: 10,
-            runSpacing: 10,
-            children: [
-              PokeMapStatusTile(
-                label: 'Étapes réelles',
-                value: '$stepCount',
-                icon: CupertinoIcons.list_bullet,
-                tone: PokeMapTone.narrative,
-              ),
-              const PokeMapStatusTile(
-                label: 'Graph — à venir',
-                value: 'Placeholder',
-                icon: CupertinoIcons.arrow_branch,
-                tone: PokeMapTone.neutral,
-              ),
-              const PokeMapStatusTile(
-                label: 'Chapitres — à venir',
-                value: 'Read model prochain',
-                icon: CupertinoIcons.square_list,
-                tone: PokeMapTone.neutral,
-              ),
-            ],
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylineHeaderSection extends StatelessWidget {
+  const _StorylineHeaderSection({
+    required this.selectedStory,
+  });
+
+  final NarrativeScenarioSummary? selectedStory;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    final description = selectedStory?.description.trim();
+    return KeyedSubtree(
+      key: const ValueKey('storylines-header-section'),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          const PokeMapIconTile(
+            icon: CupertinoIcons.link,
+            tone: PokeMapTone.narrative,
+            size: 46,
+            iconSize: 21,
           ),
-          const SizedBox(height: 18),
-          SizedBox(
-            height: 360,
-            child: PokeMapPageSurface(
-              padding: const EdgeInsets.all(18),
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  Text(
-                    'Zone centrale Storyline',
-                    style: TextStyle(
-                      color: colors.textPrimary,
-                      fontSize: 15,
-                      fontWeight: FontWeight.w800,
-                    ),
+          const SizedBox(width: 12),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  selectedStory?.name ?? 'Storyline non disponible',
+                  maxLines: 1,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textPrimary,
+                    fontSize: 21,
+                    fontWeight: FontWeight.w800,
                   ),
-                  const SizedBox(height: 8),
-                  Text(
-                    'Le graph macro et les chapitres resteront read-only tant que leurs sources ne sont pas stabilisées.',
-                    style: TextStyle(
-                      color: colors.textSecondary,
-                      fontSize: 12.5,
-                      height: 1.35,
-                    ),
+                ),
+                const SizedBox(height: 6),
+                Text(
+                  description == null || description.isEmpty
+                      ? 'Description non renseignée dans le scénario.'
+                      : description,
+                  maxLines: 2,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textSecondary,
+                    fontSize: 12.5,
+                    height: 1.3,
+                    fontWeight: FontWeight.w500,
                   ),
-                  const SizedBox(height: 48),
-                  const PokeMapStatusTile(
-                    label: 'Créer un chapitre',
-                    value: 'À venir',
-                    icon: CupertinoIcons.lock,
-                    tone: PokeMapTone.neutral,
+                ),
+                const SizedBox(height: 10),
+                const Wrap(
+                  spacing: 8,
+                  runSpacing: 8,
+                  children: [
+                    PokeMapStatusTile(
+                      label: 'Type',
+                      value: 'Storyline principale',
+                      icon: CupertinoIcons.book,
+                      tone: PokeMapTone.narrative,
+                    ),
+                    PokeMapStatusTile(
+                      label: 'État',
+                      value: 'Lecture seule',
+                      icon: CupertinoIcons.lock,
+                      tone: PokeMapTone.info,
+                    ),
+                    PokeMapStatusTile(
+                      label: 'Source',
+                      value: 'Source réelle',
+                      icon: CupertinoIcons.doc_text,
+                      tone: PokeMapTone.neutral,
+                    ),
+                  ],
+                ),
+              ],
+            ),
+          ),
+          const SizedBox(width: 12),
+          const PokeMapStatusTile(
+            label: 'Mode lecture seule',
+            value: 'Storylines V0',
+            icon: CupertinoIcons.lock,
+            tone: PokeMapTone.info,
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylineTabsRow extends StatelessWidget {
+  const _StorylineTabsRow();
+
+  @override
+  Widget build(BuildContext context) {
+    return const KeyedSubtree(
+      key: ValueKey('storylines-tabs'),
+      child: SingleChildScrollView(
+        scrollDirection: Axis.horizontal,
+        child: PokeMapSegmentedTabs(
+          tabs: [
+            PokeMapSegmentedTab(
+              label: 'Graph',
+              selected: true,
+              icon: CupertinoIcons.arrow_branch,
+            ),
+            PokeMapSegmentedTab(
+              label: 'Chapitres',
+              selected: false,
+              icon: CupertinoIcons.square_list,
+            ),
+            PokeMapSegmentedTab(
+              label: 'Étapes',
+              selected: false,
+              icon: CupertinoIcons.list_bullet,
+            ),
+            PokeMapSegmentedTab(
+              label: 'Scènes',
+              selected: false,
+              icon: CupertinoIcons.film,
+            ),
+            PokeMapSegmentedTab(
+              label: 'Statistiques',
+              selected: false,
+              icon: CupertinoIcons.chart_bar,
+            ),
+            PokeMapSegmentedTab(
+              label: 'Tests',
+              selected: false,
+              icon: CupertinoIcons.checkmark_shield,
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylineKpiStrip extends StatelessWidget {
+  const _StorylineKpiStrip({
+    required this.globalStoryCount,
+    required this.stepCount,
+    required this.linkedCutsceneCount,
+  });
+
+  final int globalStoryCount;
+  final int stepCount;
+  final int linkedCutsceneCount;
+
+  @override
+  Widget build(BuildContext context) {
+    return KeyedSubtree(
+      key: const ValueKey('storylines-kpi-strip'),
+      child: Wrap(
+        spacing: 10,
+        runSpacing: 10,
+        children: [
+          SizedBox(
+            key: const ValueKey('storylines-kpi-global-stories'),
+            width: 150,
+            height: 128,
+            child: PokeMapMetricCard(
+              title: 'Storylines globales',
+              value: '$globalStoryCount',
+              subtitle: 'Source manifest',
+              icon: CupertinoIcons.link,
+              tone: PokeMapTone.narrative,
+            ),
+          ),
+          SizedBox(
+            key: const ValueKey('storylines-kpi-steps'),
+            width: 150,
+            height: 128,
+            child: PokeMapMetricCard(
+              title: 'Étapes narratives',
+              value: '$stepCount',
+              subtitle: 'Source Step Studio',
+              icon: CupertinoIcons.list_bullet,
+              tone: PokeMapTone.info,
+            ),
+          ),
+          SizedBox(
+            key: const ValueKey('storylines-kpi-cutscenes'),
+            width: 150,
+            height: 128,
+            child: PokeMapMetricCard(
+              title: 'Cutscenes liées',
+              value: '$linkedCutsceneCount',
+              subtitle: 'Références Step',
+              icon: CupertinoIcons.film,
+              tone: PokeMapTone.neutral,
+            ),
+          ),
+          const SizedBox(
+            key: ValueKey('storylines-kpi-chapters'),
+            width: 150,
+            height: 128,
+            child: PokeMapMetricCard(
+              title: 'Chapitres',
+              value: 'À venir',
+              subtitle: 'Read model futur',
+              icon: CupertinoIcons.square_list,
+              tone: PokeMapTone.neutral,
+            ),
+          ),
+          const SizedBox(
+            key: ValueKey('storylines-kpi-diagnostics'),
+            width: 150,
+            height: 128,
+            child: PokeMapMetricCard(
+              title: 'Avertissements structurels',
+              value: 'À venir',
+              subtitle: 'Validator absent',
+              icon: CupertinoIcons.exclamationmark_triangle,
+              tone: PokeMapTone.neutral,
             ),
           ),
         ],
diff --git a/packages/map_editor/test/storylines_current_global_story_characterization_test.dart b/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
index f188a01a..95e0dac3 100644
--- a/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
+++ b/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
@@ -33,7 +33,7 @@ void main() {
         expect(find.text('Storylines'), findsWidgets);
         expect(find.text('Audit Story From Scenario'), findsWidgets);
         expect(find.text('Audit description from scenario'), findsWidgets);
-        expect(find.text('Étapes réelles'), findsOneWidget);
+        expect(find.text('Étapes narratives'), findsWidgets);
         expect(find.text('1'), findsWidgets);
 
         expect(find.text('Mode lecture seule'), findsOneWidget);
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index 2e6c552e..5435c62a 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -14,7 +14,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-04 Storylines secondary panel V0', () {
+  group('NS-STORYLINES-05 Storyline header tabs KPI V0', () {
     testWidgets(
       'renders a read-only three-pane shell from real global story data',
       (tester) async {
@@ -31,6 +31,13 @@ void main() {
             findsOneWidget);
         expect(find.byKey(const ValueKey('storylines-inspector-placeholder')),
             findsOneWidget);
+        expect(find.byKey(const ValueKey('storylines-header-section')),
+            findsOneWidget);
+        expect(find.byKey(const ValueKey('storylines-tabs')), findsOneWidget);
+        expect(
+          find.byKey(const ValueKey('storylines-kpi-strip')),
+          findsOneWidget,
+        );
 
         expect(find.text('Audit Story From Scenario'), findsWidgets);
         expect(find.text('Audit description from scenario'), findsWidgets);
@@ -50,6 +57,55 @@ void main() {
         expect(find.text('Quêtes annexes'), findsWidgets);
         expect(find.textContaining('aucun modèle de quête annexe'),
             findsOneWidget);
+        expect(find.text('Lecture seule'), findsWidgets);
+        expect(find.text('Source réelle'), findsWidgets);
+        expect(find.text('Graph'), findsOneWidget);
+        expect(find.text('Chapitres'), findsWidgets);
+        expect(find.text('Étapes'), findsWidgets);
+        expect(find.text('Scènes'), findsWidgets);
+        expect(find.text('Statistiques'), findsOneWidget);
+        expect(find.text('Tests'), findsOneWidget);
+        expect(
+          find.byKey(const ValueKey('storylines-kpi-global-stories')),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: find.byKey(const ValueKey('storylines-kpi-global-stories')),
+            matching: find.text('2'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(const ValueKey('storylines-kpi-steps')),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: find.byKey(const ValueKey('storylines-kpi-steps')),
+            matching: find.text('1'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(const ValueKey('storylines-kpi-cutscenes')),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: find.byKey(const ValueKey('storylines-kpi-cutscenes')),
+            matching: find.text('0'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(const ValueKey('storylines-kpi-chapters')),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(const ValueKey('storylines-kpi-diagnostics')),
+          findsOneWidget,
+        );
         expect(
           find.byKey(const ValueKey('storylines-secondary-create-action')),
           findsOneWidget,
@@ -91,6 +147,65 @@ void main() {
       },
     );
 
+    testWidgets(
+      'keeps Storyline tabs read-only and non-mutating',
+      (tester) async {
+        final harness = await _pumpStorylinesShell(tester);
+        final tabs = find.byKey(const ValueKey('storylines-tabs'));
+
+        expect(tabs, findsOneWidget);
+        expect(
+          find.descendant(of: tabs, matching: find.text('Graph')),
+          findsOneWidget,
+        );
+
+        final beforeEditorState =
+            harness.container.read(editorNotifierProvider);
+        final beforeNarrativeState =
+            harness.container.read(narrativeWorkspaceControllerProvider);
+        final beforeProject = beforeEditorState.project!;
+        final beforeScenarioIds = beforeProject.scenarios
+            .map((scenario) => scenario.id)
+            .toList(growable: false);
+
+        for (final label in <String>[
+          'Chapitres',
+          'Étapes',
+          'Scènes',
+          'Statistiques',
+          'Tests',
+        ]) {
+          await tester
+              .tap(find.descendant(of: tabs, matching: find.text(label)));
+          await tester.pump();
+        }
+
+        final afterEditorState = harness.container.read(editorNotifierProvider);
+        final afterNarrativeState =
+            harness.container.read(narrativeWorkspaceControllerProvider);
+
+        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
+        expect(afterEditorState.workspaceMode, EditorWorkspaceMode.globalStory);
+        expect(afterEditorState.project, same(beforeProject));
+        expect(
+          afterEditorState.project!.scenarios
+              .map((scenario) => scenario.id)
+              .toList(growable: false),
+          beforeScenarioIds,
+        );
+        expect(
+          afterNarrativeState.selectedGlobalStoryId,
+          beforeNarrativeState.selectedGlobalStoryId,
+        );
+        expect(
+          afterNarrativeState.selectedStepId,
+          beforeNarrativeState.selectedStepId,
+        );
+        expect(find.text('Zone centrale Storyline'), findsOneWidget);
+        expect(find.text('Audit Local Event Flow'), findsNothing);
+      },
+    );
+
     testWidgets(
       'keeps future header actions disabled and non-mutating',
       (tester) async {
@@ -228,7 +343,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_04_secondary_panel_desktop.png',
+          'ns_storylines_05_header_tabs_kpi_desktop.png',
         ),
       );
 
@@ -240,7 +355,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_04_secondary_panel_focus.png',
+          'ns_storylines_05_header_tabs_kpi_focus.png',
         ),
       );
 
@@ -252,7 +367,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_04_secondary_panel_only.png',
+          'ns_storylines_05_header_tabs_kpi_center.png',
         ),
       );
     });
```

Sorties exactes des tests ciblés : voir section `14. Commands run`.

Sortie exacte de l'analyse ciblée : voir section `14. Commands run`.

Résultats du Visual Gate : voir section `12. Visual Gate`.

Mini audit Design System : voir section `9. Design System Gate`.

Recherche `Color(0x...)` / `Colors.*` : voir section `9. Design System Gate`.

## 16. Self-review

Ce qui est prouvé :

- le shell Storylines rend toujours sans crash ;
- le header central affiche le vrai titre et la vraie description de la fixture ;
- les tabs Storyline sont présentes ;
- les tabs futures ne mutent pas le workspace, le projet ni la sélection ;
- les KPI `Storylines globales`, `Étapes narratives`, `Cutscenes liées` utilisent des valeurs réelles/dérivées ;
- `Chapitres` et `Avertissements structurels` restent `À venir` ;
- les données cible interdites restent absentes ;
- `localEventFlow` ne devient pas une quête/storyline/KPI ;
- `Maps` reste absent de la sidebar interne ;
- les tests ciblés et l'analyse ciblée passent ;
- les screenshots dark NS05 existent et ont été inspectés.

Ce qui n'est pas fait volontairement :

- graph riche ;
- mini-map ;
- zoom controls ;
- inspector final ;
- onglet Chapitres actif ;
- statistiques ;
- tests Storylines actifs ;
- création de storyline ;
- validation globale ;
- recherche active ;
- données tags/facts/world rules/activité récente.

Risque résiduel :

- `Chapitres` est disponible dans des metadata historiques mais n'est pas encore exposé proprement au widget Storylines actuel ; il reste donc disabled jusqu'à un read model dédié.
- Les screenshots golden utilisent Ahem ; la typographie finale devra être jugée plus tard dans un Visual Gate produit complet.
