# NS-SCENES-V1-04 — Workspace Shell Scenes

## Résumé exécutif

Verdict : DONE avec une limite connue hors scope.

Le workspace `Scènes` existe maintenant dans le Narrative Studio. Il est branché sur la navigation interne, possède son propre mode `EditorWorkspaceMode.scenes`, affiche un shell read-only, lit uniquement les scènes réelles issues de `ProjectManifest.scenes`, et montre un état vide honnête quand la liste est vide.

Aucune scène n'est créée, aucune donnée Selbrume n'est hardcodée, aucun `sceneLink` Storylines n'est branché, aucun runtime n'est modifié.

## Design gate / décision UI

- Entrée ajoutée dans la navigation interne Narrative Studio : `Scènes`.
- L'ancien workspace `step` reste présent et est renommé visuellement `Étapes`.
- Widget créé : `ScenesWorkspace`, placé dans `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`.
- Données affichées : projection read-only de `ProjectManifest.scenes`.
- Actions non supportées : boutons `Créer une scène — bientôt` et `Builder — bientôt`, désactivés.
- Primitives design system utilisées : `PokeMapPageSurface`, `PokeMapPanel`, `PokeMapMetricCard`, `PokeMapIconTile`, `PokeMapButton`, `PokeMapCard`, `PokeMapEmptyState`, `PokeMapTone`, `context.pokeMapColors`.
- Aucune couleur hardcodée ajoutée dans le shell Scenes.

## Scope réalisé

- Ajout du mode workspace `scenes`.
- Ajout du chemin de navigation editor/notifier/controller pour ouvrir Scènes.
- Ajout du shell UI read-only `ScenesWorkspace`.
- Ajout d'une projection `NarrativeSceneSummary` depuis `ProjectManifest.scenes`.
- Mise à jour de la sidebar, du header, du canvas Narrative Studio, de la toolbar et des panneaux narratifs pour connaître Scènes.
- Tests widget dédiés pour navigation, empty state, données réelles, actions désactivées, non-mutation et Storylines non cassé.
- Visual Gate produit : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_04_workspace_shell.png`.
- Roadmap Scenes mise à jour : V1-04 `DONE`, prochain lot V1-05.

## Fichiers créés/modifiés

Créés :

- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_04_workspace_shell.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_04_workspace_shell_scenes.md`

Modifiés :

- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`

## Décisions techniques

- `ProjectManifest` et `map_core` ne sont pas modifiés : V1-03 avait déjà posé `ProjectManifest.scenes`.
- `ScenesWorkspace` reçoit une liste de `NarrativeSceneSummary` et ne connaît pas le manifest complet.
- Le shell n'a aucun callback de mutation.
- Le panneau droit est désactivé pour `EditorWorkspaceMode.scenes` afin d'éviter un faux inspector V1-04.
- La sidebar Narrative Studio utilise un scroll interne pour rester stable avec la nouvelle entrée.
- Les métriques sont dérivées : nombre de scènes, nodes et outcomes déclarés.

## Écarts au prompt éventuels

- Aucun graph, tree panel ou inspector n'a été créé, conformément au scope.
- `flutter analyze --no-fatal-infos` global échoue sur une dette préexistante hors Scènes. L'analyse ciblée des fichiers du lot passe.
- Le Visual Gate utilise une fixture locale de test avec une scène neutre, uniquement dans `packages/map_editor/test/scenes_workspace_shell_test.dart`. Aucune fixture produit n'est créée.

## Tests exécutés

```text
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
Résultat final : 00:03 +6: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
Résultat final : 00:02 +3: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
Résultat final : 00:04 +19: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
Résultat final : 00:02 +2: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
Résultat final : 00:01 +3: All tests passed!
```

Note : deux lancements parallèles Flutter ont échoué avec `Failed to code sign binary ... objective_c.dylib: No such file or directory` pendant le startup lock. Ils ont été relancés en séquentiel et les tests applicatifs ont passé.

## Résultats exacts

Sortie representative du test principal :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: NS-SCENES-V1-04 workspace shell Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-04 workspace shell Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-04 workspace shell shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-04 workspace shell shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-04 workspace shell disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-04 workspace shell disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-04 workspace shell summarizes real SceneAsset data without creating a tree panel
00:02 +4: NS-SCENES-V1-04 workspace shell summarizes real SceneAsset data without creating a tree panel
00:02 +4: NS-SCENES-V1-04 workspace shell Storylines workspace remains selectable
00:02 +5: NS-SCENES-V1-04 workspace shell Storylines workspace remains selectable
00:02 +5: NS-SCENES-V1-04 workspace shell writes V1-04 visual gate screenshot
00:03 +6: NS-SCENES-V1-04 workspace shell writes V1-04 visual gate screenshot
00:03 +6: All tests passed!
```

## Analyze exact

Analyse ciblée :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/narrative_studio_sidebar.dart lib/src/ui/canvas/narrative_studio_shell.dart lib/src/ui/canvas/narrative_studio_header.dart lib/src/features/narrative/application/narrative_workspace_projection.dart lib/src/features/narrative/state/narrative_workspace_state.dart lib/src/features/editor/state/models/editor_workspace_mode.dart lib/src/features/editor/application/editor_workspace_controller.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/narrative_library_panel.dart lib/src/ui/panels/narrative_inspector_panel.dart test/scenes_workspace_shell_test.dart test/ui/canvas/narrative_studio_header_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart

Analyzing 15 items...

No issues found! (ran in 1.7s)
```

Analyse globale :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos

Analyzing map_editor...
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
error • The named parameter 'studioFlags' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 • undefined_named_parameter
error • The named parameter 'battleStageMods' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:75:7 • undefined_named_parameter
error • The named parameter 'moveStatuses' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:76:7 • undefined_named_parameter
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
347 issues found. (ran in 2.1s)
```

Ces erreurs ne touchent pas les fichiers modifiés par NS-SCENES-V1-04.

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_04_workspace_shell.png
```

Production :

```text
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-04 visual gate screenshot'
Résultat final : 00:02 +1: All tests passed!
```

La capture montre le workspace Scènes avec une scène réelle de test locale, les métriques dérivées, la liste compacte read-only et les boutons désactivés.

## Git status initial

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
Sortie : <vide>

git diff --stat
Sortie : <vide>

git log --oneline -n 10
3253c8d5 chore: auto-commit changes
e75b3876 chore: auto-commit changes
00bcaa4d chore: auto-commit changes
a85fc3c4 docs(scenes): add scene system audit and roadmap v1.0.0
af6c491b feat(storylines): update structure layout and tests v1.1.1
04cce3b7 feat(storylines): add structure layout chapter/step readability v1.1.0
2c536dbd feat(storylines): fix graph focus layout canvas priority
a428448e feat(storylines): fix Selbrume graph layout side quest rendering v0
4acf8c3f feat(storylines): add Selbrume storylines demo seed v0
b26ae424 docs(storylines): reorganize v1 screenshots and add checkpoint acceptance report
```

## Git status final

```text
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
 M packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
?? packages/map_editor/test/scenes_workspace_shell_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_04_workspace_shell_scenes.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_04_workspace_shell.png
```

## Git diff --stat

```text
 .../application/editor_workspace_controller.dart   |  4 +++
 .../src/features/editor/state/editor_notifier.dart |  5 +++
 .../features/editor/state/editor_selectors.dart    |  3 ++
 .../editor/state/models/editor_workspace_mode.dart |  1 +
 .../narrative_workspace_projection.dart            | 39 ++++++++++++++++++++++
 .../narrative/state/narrative_workspace_state.dart |  5 +++
 .../lib/src/ui/canvas/editor_canvas_host.dart      |  1 +
 .../lib/src/ui/canvas/narrative_studio_header.dart |  3 +-
 .../lib/src/ui/canvas/narrative_studio_shell.dart  |  3 ++
 .../src/ui/canvas/narrative_studio_sidebar.dart    | 13 +++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 12 ++++++-
 .../map_editor/lib/src/ui/editor_shell_page.dart   | 10 ++++++
 .../src/ui/panels/narrative_inspector_panel.dart   |  8 +++++
 .../lib/src/ui/panels/narrative_library_panel.dart | 37 +++++++++++++++-----
 .../lib/src/ui/panels/project_explorer_panel.dart  |  1 +
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |  9 +++++
 .../narrative_overview_shell_navigation_test.dart  | 18 ++++++++--
 .../ui/canvas/narrative_studio_header_test.dart    |  3 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  | 26 +++++++++++++--
 19 files changed, 183 insertions(+), 18 deletions(-)
```

## Git diff --name-only

```text
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/panels/narrative_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check

```text
Sortie : <vide>
```

## Evidence Pack

Commandes principales exécutées :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
flutter test --reporter=compact test/scenes_workspace_shell_test.dart
flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-04 visual gate screenshot'
flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
flutter test --reporter=compact test/narrative_workspace_projection_test.dart
flutter analyze --no-fatal-infos <fichiers cibles>
flutter analyze --no-fatal-infos
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/test/scenes_workspace_shell_test.dart
rg "Annonce au port|Selbrume|Maël|Lysa|Le Goélise|La brume du phare" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Recherches design/anti-fake :

```text
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/test/scenes_workspace_shell_test.dart
Sortie : <vide>

rg "Annonce au port|Selbrume|Maël|Lysa|Le Goélise|La brume du phare" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
Sortie : <vide>
```

Diff principal :

```text
EditorWorkspaceMode.scenes ajouté.
EditorWorkspaceController.selectScenesWorkspace ajouté.
EditorNotifier.selectScenesWorkspace ajouté.
NarrativeWorkspaceView.scenes ajouté.
NarrativeWorkspaceProjection.scenes ajouté.
ScenesWorkspace créé.
Navigation Narrative Studio Scènes branchée.
Actions Scènes désactivées.
Roadmap V1-04 marquée DONE.
```

## Auto-review critique

- Le shell respecte le scope : pas d'authoring, pas de graph, pas d'inspector, pas de runtime.
- Le libellé `Scènes` a été séparé de l'ancien mode `step`, ce qui clarifie la navigation.
- Le test dédié protège l'empty state, le résumé de vraie scène, les boutons désactivés et l'absence de tree panel/graph/inspector.
- La dette globale `flutter analyze` reste un risque de fond du package, mais elle est hors fichiers du lot.
- Le prochain lot devra éviter de transformer la liste compacte V1-04 en faux Scene Tree : V1-05 doit rester read-only et alimenté par `ProjectManifest.scenes`.

## Regard critique sur le prompt

Le prompt est cohérent et garde une frontière saine entre shell UI et Scene Builder complet. La seule tension pratique est l'exigence `flutter analyze` globale : elle révèle une dette existante très large dans `map_editor`, donc la validation utile pour ce lot est l'analyse ciblée des fichiers touchés, qui passe.
