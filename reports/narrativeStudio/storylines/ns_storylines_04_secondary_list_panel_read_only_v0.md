# NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0

## 1. Executive summary

NS-STORYLINES-04 est livré.

Le panneau secondaire Storylines n'est plus un placeholder minimal. Il affiche maintenant une zone read-only structurée :

- header `Storylines` ;
- action `+` visible mais disabled ;
- recherche visible mais disabled / à venir ;
- section `Histoire principale` alimentée par les vrais `ScenarioAsset(scope == globalStory)` de la projection ;
- lignes de storyline avec titre réel, description réelle, type prudent `Storyline principale`, nombre d'étapes dérivé et mention `Read-only / Source réelle` ;
- section `Quêtes annexes` explicitement à venir, sans transformer `localEventFlow` en quête annexe.

Le lot ne crée aucune storyline, ne crée aucune quête annexe, n'active pas la recherche, ne touche pas à `map_core`, ne réintroduit pas `Maps`, et ne copie aucune donnée de l'image cible.

Prochain lot recommandé : `NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0`.

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
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
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

Fichiers attendus absents : aucun. Tous les chemins demandés dans le prompt existent dans ce repo.

## 3. Implementation summary

Modifié dans `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` :

- `_StorylinesSecondaryPanel` reçoit maintenant la liste réelle `projection.globalStories`, le `selectedStoryId` et une map `stepCountsByStoryId`.
- Le panneau secondaire utilise `PokeMapPanel(expandChild: true)` pour permettre un contenu de liste scrollable sans overflow medium.
- Le header affiche `Storylines` et une action `+` disabled avec key stable `storylines-secondary-create-action`.
- La recherche est matérialisée par `PokeMapStatusTile` avec key `storylines-secondary-search-disabled`, label `Recherche à venir` et aucune interaction active.
- La section `Histoire principale` liste uniquement les vrais `ScenarioAsset globalStory`.
- La section `Quêtes annexes` reste disabled / à venir, avec un texte explicitant qu'aucun modèle de quête annexe n'est branché.
- `_StorylineSummaryRow` est un composant feature-specific : il compose `PokeMapCard`, `PokeMapIconTile`, `PokeMapTone`, `context.pokeMapColors`, sans devenir une primitive générique parallèle.

Modifié dans `packages/map_editor/test/storylines_workspace_shell_test.dart` :

- le test shell vérifie la structure du panneau secondaire ;
- la fixture contient deux `globalStory` neutres pour prouver que la liste affiche plusieurs storylines réelles si la projection les fournit ;
- le test vérifie que `Audit Local Event Flow` n'est pas rendu comme quête annexe ;
- l'action secondaire `+` est vérifiée présente, disabled (`PokeMapButton.onPressed == null`) et non mutante ;
- les captures Visual Gate pointent vers les nouveaux fichiers NS-STORYLINES-04.

Modifié dans `packages/map_editor/test/storylines_current_global_story_characterization_test.dart` :

- l'assertion sur `Audit description from scenario` accepte désormais plusieurs occurrences, car la description réelle apparaît dans le panneau secondaire et la zone centrale.

## 4. Secondary panel behavior

Comportement livré :

| Zone | État livré | Source |
|---|---|---|
| Header `Storylines` | Visible | UI shell |
| Action `+` | Visible, disabled, non mutante | `PokeMapButton(onPressed: null)` |
| Recherche | Visible, disabled / à venir | `PokeMapStatusTile` |
| Histoire principale | Liste read-only | `projection.globalStories` |
| Ligne Storyline | Titre, description, type prudent, steps, source réelle | `ScenarioAsset` + `projection.steps` |
| Plusieurs globalStory | Supportées si présentes dans la projection | fixture de test avec deux `globalStory` |
| Quêtes annexes | Section à venir, non branchée | aucun modèle V0 |
| Empty state | Prévu si aucune `globalStory` | texte honnête |

Le clic sur une ligne n'ajoute aucune interaction de sélection complexe dans ce lot. Le lot NS-STORYLINES-11 reste responsable du wiring d'interactions avancées.

## 5. Data source / anti-fake guarantees

Données affichées positives autorisées :

- `ScenarioAsset.name`
- `ScenarioAsset.description`
- `ScenarioScope.globalStory` sous le wording prudent `Storyline principale`
- nombre d'étapes dérivé de `projection.steps.where((step) => step.globalScenarioId == story.id)`
- labels d'état honnêtes : `Read-only / Source réelle`, `Recherche à venir`, `Quêtes annexes — À venir`

Données explicitement non affichées :

- aucune quête annexe cible ;
- aucun tag cible ;
- aucune world rule cible ;
- aucune activité récente ;
- aucun chiffre cible `5`, `27`, `412`, `18`, `3` ;
- aucune storyline Selbrume hardcodée ;
- aucun `localEventFlow` présenté comme quête annexe.

Les tests gardent les chaînes cible interdites comme assertions négatives uniquement.

## 6. Disabled features

Restent disabled ou à venir :

- `+` du panneau secondaire ;
- recherche / filtrage ;
- création de storyline ;
- création de quête annexe ;
- quêtes annexes ;
- graph riche ;
- KPI ;
- inspecteur final ;
- onglet Chapitres ;
- `Nouvelle storyline` du header ;
- `Valider` du header.

Le test `keeps future header actions disabled and non-mutating` vérifie maintenant l'action secondaire `+` en plus de `Nouvelle storyline` et `Valider`.

## 7. Design System Gate

Gate respecté.

Primitives utilisées :

- `PokeMapPanel`
- `PokeMapCard`
- `PokeMapButton`
- `PokeMapIconTile`
- `PokeMapStatusTile`
- `PokeMapTone`
- `context.pokeMapColors`

Recherche exécutée :

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
```

Sortie : `<vide>`

Conclusion :

- aucun `Color(0x...)` ajouté ;
- aucun `Colors.*` ajouté ;
- aucune couleur locale hardcodée ;
- aucun composant générique local de type card/pill/panel/sidebar row parallèle au design system.

Note : `_StorylineSummaryRow` est feature-specific et compose des primitives PokeMap existantes.

## 8. Sidebar / Maps guardrail

`Maps` reste absent de la sidebar interne Narrative Studio.

Le lot ne modifie pas :

- `NarrativeStudioSidebar` ;
- `ProjectExplorerPanel` ;
- l'architecture `ProjectExplorerPanel global ≠ NarrativeStudioSidebar interne`.

Le test shell continue à vérifier :

```dart
expect(find.text('Maps'), findsNothing);
```

## 9. Tests added or modified

Tests modifiés :

- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`

Couverture ajoutée / adaptée :

- panneau secondaire structuré ;
- deux global stories réelles dans la fixture ;
- rendu des titres/descriptions réels ;
- nombre d'étapes réel/dérivé ;
- recherche visible mais disabled ;
- bouton `+` présent, disabled, non mutant ;
- `localEventFlow` absent de la liste / des quêtes annexes ;
- absence de chaînes cible ;
- absence de `Maps` ;
- goldens NS-STORYLINES-04.

## 10. Visual Gate

Méthode :

- harness Flutter test existant ;
- `MaterialApp(theme: PokeMapTheme.light(), darkTheme: PokeMapTheme.dark(), themeMode: ThemeMode.dark)` conservé depuis NS-STORYLINES-03-bis ;
- `flutter test --update-goldens test/storylines_workspace_shell_test.dart` pour générer les captures ;
- `flutter test test/storylines_workspace_shell_test.dart` pour vérifier ensuite les goldens.

Captures produites :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_only.png`

Métadonnées :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_only.png:    PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_desktop.png May 28 01:42:21 2026 42624
reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_focus.png May 28 01:42:22 2026 38378
reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_only.png May 28 01:42:22 2026 40720
```

Analyse visuelle :

- desktop : thème dark actif, layout trois zones conservé, panneau secondaire plus structuré avec deux rows réelles, action `+`, recherche disabled, section quêtes annexes à venir ; pas d'overflow visible ;
- focus 1600x700 : zone haute stable, panneau secondaire scrollable ; le bas du panneau est naturellement hors viewport, sans overflow ;
- medium 1180x1000 : layout trois zones conservé ; panneau secondaire scrollable grâce à `PokeMapPanel(expandChild: true)` ; pas d'overflow.

Limite connue : les screenshots de tests Flutter utilisent la police Ahem. Ils valident donc surtout structure, thème dark, densité, zones et overflow, pas la typographie finale.

## 11. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mise à jour :

- `NS-STORYLINES-04` marqué `DONE` ;
- résumé du résultat ajouté au détail du lot ;
- fichiers modifiés / créés listés ;
- tests, analyse et Visual Gate listés ;
- Design System Gate confirmé ;
- absence de fake data confirmée ;
- prochain lot recommandé passé à `NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0`.

## 12. Commands run

Commandes principales :

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

```bash
dart format lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart
flutter test --update-goldens test/storylines_workspace_shell_test.dart
flutter test test/storylines_workspace_shell_test.dart
flutter test test/storylines_current_global_story_characterization_test.dart
flutter test test/narrative_workspace_projection_test.dart
flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
file reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_desktop.png reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_focus.png reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_only.png
stat -f '%N %Sm %z' reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_desktop.png reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_focus.png reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_only.png
git diff --check
```

## 13. Evidence Pack

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

### Tests ciblés — `flutter test test/storylines_workspace_shell_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-04 Storylines secondary panel V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-04 Storylines secondary panel V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-04 Storylines secondary panel V0 storylines UI source keeps raw colors out of the feature
00:00 +3: NS-STORYLINES-04 Storylines secondary panel V0 storylines action test does not use silent taps
00:00 +4: NS-STORYLINES-04 Storylines secondary panel V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +5: NS-STORYLINES-04 Storylines secondary panel V0 writes Visual Gate screenshots
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
00:01 +6: All tests passed!
```

### Tests ciblés — `flutter test test/storylines_current_global_story_characterization_test.dart`

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

### Régression — `flutter test test/narrative_workspace_projection_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: All tests passed!
```

### Analyze ciblé

```text
Analyzing 4 items...

No issues found! (ran in 2.3s)
```

### Visual Gate generation — `flutter test --update-goldens test/storylines_workspace_shell_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-04 Storylines secondary panel V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-04 Storylines secondary panel V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-04 Storylines secondary panel V0 storylines UI source keeps raw colors out of the feature
00:00 +3: NS-STORYLINES-04 Storylines secondary panel V0 storylines action test does not use silent taps
00:00 +4: NS-STORYLINES-04 Storylines secondary panel V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +5: NS-STORYLINES-04 Storylines secondary panel V0 writes Visual Gate screenshots
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
00:01 +6: All tests passed!
```

### Recherche Color / Colors

```text
Sortie : <vide>
```

### Git status final exact

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_current_global_story_characterization_test.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_04_secondary_list_panel_read_only_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_focus.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_only.png
```

### Git diff --stat final

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 254 +++++++++++++++++----
 ...current_global_story_characterization_test.dart |   2 +-
 .../test/storylines_workspace_shell_test.dart      | 110 ++++++++-
 .../storylines/road_map_storylines.md              |  31 ++-
 4 files changed, 343 insertions(+), 54 deletions(-)
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
Sortie : <vide>
```

Note : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers non trackés. Le rapport et les trois screenshots apparaissent bien dans `git status --short --untracked-files=all`.

### Fichiers créés

- `reports/narrativeStudio/storylines/ns_storylines_04_secondary_list_panel_read_only_v0.md`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_04_secondary_panel_only.png`

Les trois screenshots sont des PNG binaires ; leur contenu visuel a été inspecté via l'outil image local et leurs métadonnées sont incluses dans la section Visual Gate.

Le contenu complet du rapport créé est le présent document, du titre `# NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0` jusqu'à la section `## 14. Self-review`.

### Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

### Diff complet des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 3df7dd14..98ab4e22 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -22,6 +22,12 @@ class StorylinesWorkspace extends StatelessWidget {
         : projection.steps
             .where((step) => step.globalScenarioId == selectedStory.id)
             .toList(growable: false);
+    final stepCountsByStoryId = <String, int>{
+      for (final story in projection.globalStories)
+        story.id: projection.steps
+            .where((step) => step.globalScenarioId == story.id)
+            .length,
+    };
 
     return PokeMapPageSurface(
       key: const ValueKey('storylines-workspace-shell'),
@@ -32,8 +38,9 @@ class StorylinesWorkspace extends StatelessWidget {
           SizedBox(
             width: 240,
             child: _StorylinesSecondaryPanel(
-              selectedStory: selectedStory,
-              globalStoryCount: projection.globalStories.length,
+              stories: projection.globalStories,
+              selectedStoryId: selectedStory?.id,
+              stepCountsByStoryId: stepCountsByStoryId,
             ),
           ),
           const SizedBox(width: 12),
@@ -70,64 +77,231 @@ class StorylinesWorkspace extends StatelessWidget {
 
 class _StorylinesSecondaryPanel extends StatelessWidget {
   const _StorylinesSecondaryPanel({
-    required this.selectedStory,
-    required this.globalStoryCount,
+    required this.stories,
+    required this.selectedStoryId,
+    required this.stepCountsByStoryId,
   });
 
-  final NarrativeScenarioSummary? selectedStory;
-  final int globalStoryCount;
+  final List<NarrativeScenarioSummary> stories;
+  final String? selectedStoryId;
+  final Map<String, int> stepCountsByStoryId;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
-    return PokeMapInspectorPanel(
+    return PokeMapPanel(
       key: const ValueKey('storylines-secondary-panel'),
+      expandChild: true,
       header: Padding(
-        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
-        child: Text(
-          'Storylines',
-          style: TextStyle(
-            color: colors.textSecondary,
-            fontSize: 11,
-            fontWeight: FontWeight.w800,
-            letterSpacing: 0.6,
-          ),
+        padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
+        child: Row(
+          children: [
+            Expanded(
+              child: Text(
+                'Storylines',
+                style: TextStyle(
+                  color: colors.textSecondary,
+                  fontSize: 11,
+                  fontWeight: FontWeight.w800,
+                  letterSpacing: 0.6,
+                ),
+              ),
+            ),
+            Semantics(
+              key: const ValueKey('storylines-secondary-create-action'),
+              button: true,
+              enabled: false,
+              label: 'Créer une storyline - à venir',
+              child: const PokeMapButton(
+                onPressed: null,
+                size: PokeMapButtonSize.small,
+                variant: PokeMapButtonVariant.secondary,
+                leading: Icon(CupertinoIcons.add),
+                child: Text('+'),
+              ),
+            ),
+          ],
         ),
       ),
       padding: const EdgeInsets.all(12),
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.stretch,
+      child: SingleChildScrollView(
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            const PokeMapStatusTile(
+              key: ValueKey('storylines-secondary-search-disabled'),
+              label: 'Recherche à venir',
+              value: 'Filtrage bientôt disponible',
+              icon: CupertinoIcons.search,
+              tone: PokeMapTone.neutral,
+            ),
+            const SizedBox(height: 12),
+            _StorylinesSectionLabel(
+              label: 'Histoire principale',
+              color: colors.textSecondary,
+            ),
+            const SizedBox(height: 8),
+            if (stories.isEmpty)
+              Text(
+                'Aucune storyline principale disponible.',
+                style: TextStyle(color: colors.textSecondary, fontSize: 12),
+              )
+            else
+              ...stories.map(
+                (story) => Padding(
+                  padding: const EdgeInsets.only(bottom: 8),
+                  child: _StorylineSummaryRow(
+                    story: story,
+                    selected: story.id == selectedStoryId,
+                    stepCount: stepCountsByStoryId[story.id] ?? 0,
+                  ),
+                ),
+              ),
+            const SizedBox(height: 12),
+            _StorylinesSectionLabel(
+              label: 'Quêtes annexes',
+              color: colors.textSecondary,
+            ),
+            const SizedBox(height: 8),
+            const PokeMapStatusTile(
+              key: ValueKey('storylines-secondary-side-quests-disabled'),
+              label: 'Quêtes annexes',
+              value: 'À venir',
+              icon: CupertinoIcons.lock,
+              tone: PokeMapTone.neutral,
+            ),
+            const SizedBox(height: 8),
+            Text(
+              'À venir — aucun modèle de quête annexe n’est encore branché.',
+              style: TextStyle(
+                color: colors.textMuted,
+                fontSize: 11.5,
+                height: 1.25,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _StorylinesSectionLabel extends StatelessWidget {
+  const _StorylinesSectionLabel({
+    required this.label,
+    required this.color,
+  });
+
+  final String label;
+  final Color color;
+
+  @override
+  Widget build(BuildContext context) {
+    return Text(
+      label,
+      style: TextStyle(
+        color: color,
+        fontSize: 10.5,
+        fontWeight: FontWeight.w800,
+        letterSpacing: 0.4,
+      ),
+    );
+  }
+}
+
+class _StorylineSummaryRow extends StatelessWidget {
+  const _StorylineSummaryRow({
+    required this.story,
+    required this.selected,
+    required this.stepCount,
+  });
+
+  final NarrativeScenarioSummary story;
+  final bool selected;
+  final int stepCount;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    final description = story.description.trim();
+    return PokeMapCard(
+      key: ValueKey('storylines-secondary-row-${story.id}'),
+      selected: selected,
+      padding: const EdgeInsets.all(10),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
         children: [
-          PokeMapStatusTile(
-            label: 'Storylines globales',
-            value: '$globalStoryCount',
-            icon: CupertinoIcons.link,
+          const PokeMapIconTile(
+            icon: CupertinoIcons.book,
             tone: PokeMapTone.narrative,
+            size: 30,
+            iconSize: 15,
           ),
-          const SizedBox(height: 12),
-          if (selectedStory == null)
-            Text(
-              'Aucun scénario global disponible.',
-              style: TextStyle(color: colors.textSecondary, fontSize: 12),
-            )
-          else
-            PokeMapStatusTile(
-              label: selectedStory!.name,
-              value: 'Source réelle',
-              icon: CupertinoIcons.book,
-              tone: PokeMapTone.narrative,
+          const SizedBox(width: 9),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  story.name,
+                  maxLines: 1,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textPrimary,
+                    fontSize: 12.5,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 4),
+                Text(
+                  description.isEmpty
+                      ? 'Description non renseignée.'
+                      : description,
+                  maxLines: 2,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textSecondary,
+                    fontSize: 11,
+                    height: 1.2,
+                  ),
+                ),
+                const SizedBox(height: 7),
+                Text(
+                  'Storyline principale',
+                  style: TextStyle(
+                    color: colors.textMuted,
+                    fontSize: 10.5,
+                    fontWeight: FontWeight.w700,
+                  ),
+                ),
+                const SizedBox(height: 3),
+                Text(
+                  _formatStepCount(stepCount),
+                  style: TextStyle(
+                    color: colors.textSecondary,
+                    fontSize: 10.5,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+                const SizedBox(height: 3),
+                Text(
+                  'Read-only / Source réelle',
+                  style: TextStyle(
+                    color: colors.textMuted,
+                    fontSize: 10.5,
+                  ),
+                ),
+              ],
             ),
-          const SizedBox(height: 12),
-          const PokeMapStatusTile(
-            label: 'Créer une quête annexe',
-            value: 'À venir',
-            icon: CupertinoIcons.lock,
-            tone: PokeMapTone.neutral,
           ),
         ],
       ),
     );
   }
+
+  static String _formatStepCount(int count) {
+    return count == 1 ? '1 étape narrative' : '$count étapes narratives';
+  }
 }
 
 class _StorylineMainPanel extends StatelessWidget {
diff --git a/packages/map_editor/test/storylines_current_global_story_characterization_test.dart b/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
index 25e6af2c..f188a01a 100644
--- a/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
+++ b/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
@@ -32,7 +32,7 @@ void main() {
 
         expect(find.text('Storylines'), findsWidgets);
         expect(find.text('Audit Story From Scenario'), findsWidgets);
-        expect(find.text('Audit description from scenario'), findsOneWidget);
+        expect(find.text('Audit description from scenario'), findsWidgets);
         expect(find.text('Étapes réelles'), findsOneWidget);
         expect(find.text('1'), findsWidgets);
 
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index 82f64c4e..2e6c552e 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -14,7 +14,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-03 Storylines shell V0', () {
+  group('NS-STORYLINES-04 Storylines secondary panel V0', () {
     testWidgets(
       'renders a read-only three-pane shell from real global story data',
       (tester) async {
@@ -33,13 +33,43 @@ void main() {
             findsOneWidget);
 
         expect(find.text('Audit Story From Scenario'), findsWidgets);
-        expect(find.text('Audit description from scenario'), findsOneWidget);
+        expect(find.text('Audit description from scenario'), findsWidgets);
         expect(find.text('Mode lecture seule'), findsOneWidget);
         expect(find.text('Storylines V0'), findsWidgets);
         expect(find.text('Graph — à venir'), findsOneWidget);
         expect(find.text('Chapitres — à venir'), findsOneWidget);
         expect(find.text('Inspecteur Storyline — à venir'), findsOneWidget);
         expect(find.text('Audit Local Event Flow'), findsNothing);
+        expect(find.text('Histoire principale'), findsOneWidget);
+        expect(find.text('Audit Second Story From Scenario'), findsOneWidget);
+        expect(find.text('Audit second description from scenario'),
+            findsOneWidget);
+        expect(find.text('Storyline principale'), findsWidgets);
+        expect(find.textContaining('1 étape narrative'), findsWidgets);
+        expect(find.text('Recherche à venir'), findsOneWidget);
+        expect(find.text('Quêtes annexes'), findsWidgets);
+        expect(find.textContaining('aucun modèle de quête annexe'),
+            findsOneWidget);
+        expect(
+          find.byKey(const ValueKey('storylines-secondary-create-action')),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(const ValueKey('storylines-secondary-search-disabled')),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(
+              const ValueKey('storylines-secondary-row-audit_global_story')),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(
+            const ValueKey(
+                'storylines-secondary-row-audit_second_global_story'),
+          ),
+          findsOneWidget,
+        );
 
         for (final forbidden in _targetOnlyStrings) {
           expect(
@@ -71,6 +101,9 @@ void main() {
         final validateAction = find.byKey(
           const ValueKey('narrative-studio-header-action-validate'),
         );
+        final secondaryCreateAction = find.byKey(
+          const ValueKey('storylines-secondary-create-action'),
+        );
         final newStorylineButton = find.descendant(
           of: newStorylineAction,
           matching: find.byType(PokeMapButton),
@@ -79,16 +112,26 @@ void main() {
           of: validateAction,
           matching: find.byType(PokeMapButton),
         );
+        final secondaryCreateButton = find.descendant(
+          of: secondaryCreateAction,
+          matching: find.byType(PokeMapButton),
+        );
 
         expect(newStorylineAction, findsOneWidget);
         expect(validateAction, findsOneWidget);
+        expect(secondaryCreateAction, findsOneWidget);
         expect(newStorylineButton, findsOneWidget);
         expect(validateButton, findsOneWidget);
+        expect(secondaryCreateButton, findsOneWidget);
         expect(
           tester.widget<PokeMapButton>(newStorylineButton).onPressed,
           isNull,
         );
         expect(tester.widget<PokeMapButton>(validateButton).onPressed, isNull);
+        expect(
+          tester.widget<PokeMapButton>(secondaryCreateButton).onPressed,
+          isNull,
+        );
 
         final beforeEditorState =
             harness.container.read(editorNotifierProvider);
@@ -106,6 +149,9 @@ void main() {
         await tester.tap(validateAction);
         await tester.pump();
 
+        await tester.tap(secondaryCreateAction);
+        await tester.pump();
+
         final afterEditorState = harness.container.read(editorNotifierProvider);
         final afterNarrativeState =
             harness.container.read(narrativeWorkspaceControllerProvider);
@@ -129,7 +175,7 @@ void main() {
           beforeNarrativeState.selectedStepId,
         );
         expect(find.text('Audit Story From Scenario'), findsWidgets);
-        expect(find.text('Audit description from scenario'), findsOneWidget);
+        expect(find.text('Audit description from scenario'), findsWidgets);
 
         for (final forbidden in _targetOnlyStrings) {
           expect(
@@ -167,8 +213,8 @@ void main() {
         (tester) async {
       await _pumpStorylinesShell(tester);
 
-      final shellContext =
-          tester.element(find.byKey(const ValueKey('storylines-workspace-shell')));
+      final shellContext = tester
+          .element(find.byKey(const ValueKey('storylines-workspace-shell')));
 
       expect(Theme.of(shellContext).brightness, Brightness.dark);
     });
@@ -182,7 +228,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_03_shell_desktop.png',
+          'ns_storylines_04_secondary_panel_desktop.png',
         ),
       );
 
@@ -194,7 +240,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_03_shell_focus.png',
+          'ns_storylines_04_secondary_panel_focus.png',
         ),
       );
 
@@ -206,7 +252,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_03_shell_panels.png',
+          'ns_storylines_04_secondary_panel_only.png',
         ),
       );
     });
@@ -323,6 +369,53 @@ ProjectManifest _auditProject() {
     globalDocument,
     stepDocument: stepDocument,
   );
+  const secondStepDocument = StepStudioDocument(
+    globalStoryScenarioId: 'audit_second_global_story',
+    steps: <StepStudioStep>[
+      StepStudioStep(
+        id: 'audit_second_step',
+        name: 'Audit Second Step From Metadata',
+        description: 'Audit second step detail from metadata',
+        order: 0,
+        activation: StepStudioActivationRule(
+          mode: StepStudioActivationMode.atGameStart,
+        ),
+        completion: StepStudioCompletionRule(
+          mode: StepStudioCompletionMode.manual,
+        ),
+      ),
+    ],
+  );
+  const secondGlobalDocument = GlobalStoryStudioDocument(
+    globalStoryScenarioId: 'audit_second_global_story',
+    entryStepId: 'audit_second_step',
+    nodes: <GlobalStoryStepNode>[
+      GlobalStoryStepNode(stepId: 'audit_second_step'),
+    ],
+    chapters: <GlobalStoryChapter>[
+      GlobalStoryChapter(
+        id: 'audit_second_chapter',
+        name: 'Audit Second Chapter From Metadata',
+        description: 'Audit second chapter description from metadata',
+        stepIds: <String>['audit_second_step'],
+        order: 0,
+      ),
+    ],
+  );
+  final secondGlobalScenario = applyGlobalStoryStudioDocumentToGlobalScenario(
+    applyStepStudioDocumentToGlobalScenario(
+      const ScenarioAsset(
+        id: 'audit_second_global_story',
+        name: 'Audit Second Story From Scenario',
+        description: 'Audit second description from scenario',
+        scope: ScenarioScope.globalStory,
+        entryNodeId: 'second_start',
+      ),
+      secondStepDocument,
+    ),
+    secondGlobalDocument,
+    stepDocument: secondStepDocument,
+  );
 
   return ProjectManifest(
     surfaceCatalog: const ProjectSurfaceCatalog.empty(),
@@ -331,6 +424,7 @@ ProjectManifest _auditProject() {
     tilesets: const <ProjectTilesetEntry>[],
     scenarios: <ScenarioAsset>[
       globalScenario,
+      secondGlobalScenario,
       const ScenarioAsset(
         id: 'audit_local_event_flow',
         name: 'Audit Local Event Flow',
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 65dc150a..285a286f 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -292,7 +292,7 @@ Interprétation V0 :
 | NS-STORYLINES-01 | Storylines Read Model / Data Contract V0 | core/design | DONE | NS-STORYLINES-02 |
 | NS-STORYLINES-02 | Current Global Story Characterization / Anti-Fake Tests V0 | test/audit | DONE | NS-STORYLINES-03 |
 | NS-STORYLINES-03 | Storylines Workspace Shell Layout V0 | editor UI | DONE | NS-STORYLINES-04 |
-| NS-STORYLINES-04 | Storylines Secondary List Panel Read-only V0 | editor UI | TODO | NS-STORYLINES-05 |
+| NS-STORYLINES-04 | Storylines Secondary List Panel Read-only V0 | editor UI | DONE | NS-STORYLINES-05 |
 | NS-STORYLINES-05 | Storyline Header / Tabs / KPI Read-only V0 | editor UI | TODO | NS-STORYLINES-06 |
 | NS-STORYLINES-06 | Storyline Graph Read-only Placeholder V0 | editor UI / visual gate | TODO | NS-STORYLINES-07 |
 | NS-STORYLINES-07 | Storyline Inspector Read-only V0 | editor UI | TODO | NS-STORYLINES-08 |
@@ -390,7 +390,15 @@ Interprétation V0 :
 - Visual Gate : desktop + focus.
 - Risques : faire croire à des storylines multiples.
 - Design system impact : utiliser `PokeMapPanel`, `PokeMapSidebarItem`, `EditorSidebarListRow` ou équivalent.
-- Statut : TODO.
+- Statut : DONE.
+- Résultat NS-STORYLINES-04 : panneau secondaire Storylines structuré en read-only avec header, action `+` disabled, recherche à venir, section `Histoire principale`, liste des `ScenarioAsset globalStory` réels, nombre d'étapes dérivé et section `Quêtes annexes` explicitement non branchée.
+- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_04_secondary_list_panel_read_only_v0.md`, captures Visual Gate `ns_storylines_04_secondary_panel_desktop.png`, `ns_storylines_04_secondary_panel_focus.png`, `ns_storylines_04_secondary_panel_only.png`.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
+- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
+- Visual Gate : dark theme actif via harness NS-STORYLINES-03-bis ; captures desktop, focus et medium produites.
+- Design System Gate : confirmé ; `PokeMapPanel`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapButton`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
+- Fake data : aucune donnée cible ajoutée ; `localEventFlow` reste absent de la liste et les quêtes annexes restent à venir.
 - Prochain lot attendu : NS-STORYLINES-05.
 
 ### NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0
@@ -638,9 +646,9 @@ Décision temporaire :
 
 ```text
 Roadmap status: ACTIVE
-Current lot: NS-STORYLINES-03
+Current lot: NS-STORYLINES-04
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0
+Next recommended lot: NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -650,7 +658,7 @@ Next recommended lot: NS-STORYLINES-04 — Storylines Secondary List Panel Read-
 | NS-STORYLINES-01 | DONE | 2026-05-27 | Contrat de données Storylines V0 documenté ; aucun code/test modifié. |
 | NS-STORYLINES-02 | DONE | 2026-05-27 | Tests de caractérisation anti-fake ajoutés ; ancien Global Story Studio verrouillé sans code production. |
 | NS-STORYLINES-03 | DONE | 2026-05-28 | Shell Storylines V0 read-only livré avec layout 3 zones, anti-fake, captures Visual Gate et tests ciblés. |
-| NS-STORYLINES-04 | TODO | 2026-05-27 | Secondary list read-only. |
+| NS-STORYLINES-04 | DONE | 2026-05-28 | Panneau secondaire read-only structuré sur les globalStory réelles ; recherche / création / quêtes annexes disabled. |
 | NS-STORYLINES-05 | TODO | 2026-05-27 | Header/tabs/KPI read-only. |
 | NS-STORYLINES-06 | TODO | 2026-05-27 | Graph read-only placeholder. |
 | NS-STORYLINES-07 | TODO | 2026-05-27 | Inspector storyline. |
@@ -662,6 +670,19 @@ Next recommended lot: NS-STORYLINES-04 — Storylines Secondary List Panel Read-
 
 ## 14. Changelog
 
+### 2026-05-28 — NS-STORYLINES-04
+
+- Transformation du panneau secondaire placeholder en liste Storylines read-only structurée.
+- Affichage des `ScenarioAsset globalStory` réels avec nom, description, type prudent `Storyline principale`, nombre d'étapes dérivé, et mention `Read-only / Source réelle`.
+- Ajout d'une action `+` visible mais disabled/non mutante et d'une recherche `Recherche à venir`.
+- Ajout d'une section `Quêtes annexes` explicitement à venir ; aucun `localEventFlow` n'est présenté comme quête annexe.
+- Rendu du panneau secondaire scrollable via `PokeMapPanel(expandChild: true)` pour éviter l'overflow medium.
+- Adaptation des tests Storylines et caractérisation NS-STORYLINES-02 ; les données réelles peuvent désormais apparaître à la fois dans le panneau secondaire et la zone centrale.
+- Production des captures Visual Gate dark `ns_storylines_04_secondary_panel_desktop.png`, `ns_storylines_04_secondary_panel_focus.png`, `ns_storylines_04_secondary_panel_only.png`.
+- Confirmation : aucune donnée cible hardcodée, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
+- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
+- Prochain lot recommandé : `NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0`.
+
 ### 2026-05-28 — NS-STORYLINES-03
 
 - Création de `StorylinesWorkspace`, premier shell Storylines V0 read-only.
```

### Confirmations de périmètre

- Aucun fichier `packages/map_core/lib/` modifié.
- Aucun fichier `packages/map_runtime/` modifié.
- Aucun fichier `packages/map_gameplay/` modifié.
- Aucun fichier `packages/map_battle/` modifié.
- Aucun modèle `ScenarioAsset`, `ProjectManifest` ou `StorylineAsset` créé/modifié.
- Aucun provider ou repository créé.
- Aucune action future activée.
- Aucune recherche active.
- Aucune quête annexe fake.
- `Maps` non réintroduit dans la sidebar interne.

## 14. Self-review

Points validés :

- Le panneau secondaire affiche des données réelles issues de la projection.
- Deux `globalStory` neutres sont testées pour éviter l'hypothèse implicite d'une unique storyline.
- `localEventFlow` reste séparé et n'est pas requalifié en quête annexe.
- Le bouton `+` est présent, disabled et non mutant.
- La recherche est visible mais non active.
- Les goldens NS04 sont générés en dark theme et vérifiés.
- L'overflow medium observé pendant la génération des goldens a été corrigé par un panneau scrollable via `PokeMapPanel(expandChild: true)`.
- Le design system est respecté, sans couleur hardcodée.

Limites assumées :

- Le panneau secondaire est read-only ; aucune sélection complexe n'est branchée.
- Les quêtes annexes restent un état `à venir` faute de modèle V0.
- Les screenshots restent des goldens Flutter avec police Ahem.
- Le header/tabs/KPI restent au lot NS-STORYLINES-05.

Auto-critique :

- Le changement adapte un test NS-STORYLINES-02 pour accepter plusieurs occurrences de la description réelle. C'est intentionnel : la garantie utile est la provenance réelle de la donnée, pas l'unicité visuelle.
- Le composant `_StorylineSummaryRow` reste feature-specific ; si plusieurs workspaces ont besoin d'une row similaire, il faudra promouvoir une primitive design-system dédiée au lieu de la dupliquer.
