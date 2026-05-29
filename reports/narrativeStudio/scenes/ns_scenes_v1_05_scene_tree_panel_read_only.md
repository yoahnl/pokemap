# NS-SCENES-V1-05 — Scene Tree Panel Read-only

## Résumé exécutif

Verdict : DONE.

Le workspace `Scènes` passe d'un shell simple V1-04 à une vue read-only structurée : panneau gauche `Arborescence des scènes`, sélection locale d'une scène réelle, résumé central read-only, header local compact, actions désactivées. Les données viennent uniquement de `ProjectManifest.scenes` via la projection narrative.

Aucun graph canvas, aucun node inspector, aucun authoring, aucun runtime, aucun seed et aucune donnée Selbrume ne sont ajoutés.

## Design gate / décision UI

- Panneau gauche placé dans `ScenesWorkspace`, largeur fixe desktop `300`, titre `Arborescence des scènes`.
- Les scènes sont groupées par `storylineId`, puis `chapterId` quand ces champs existent ; sinon `Sans storyline` / `Sans chapitre`.
- Sélection locale : première scène réelle sélectionnée automatiquement, puis clic local sur item. Ce state ne sort pas du widget et ne mute pas le projet.
- Résumé central : nom, description, ID, storylineId, chapterId, tags, nodes, edges, outcomes déclarés.
- Read-only strict : tous les boutons d'authoring restent disabled.
- Préparation V1-06 : placeholder textuel `Graph — bientôt`, sans canvas, node, edge ou port.
- Micro-polish header : remplacement du bandeau V1-04 par un header compact en `PokeMapPanel`, padding réduit, métriques inline, bouton disabled plus petit.
- Primitives utilisées : `PokeMapPageSurface`, `PokeMapPanel`, `PokeMapSidebarItem`, `PokeMapStatusTile`, `PokeMapButton`, `PokeMapCard`, `PokeMapEmptyState`, `PokeMapIconTile`, `PokeMapTone`, `context.pokeMapColors`.

## Scope réalisé

- `ScenesWorkspace` devient stateful pour gérer uniquement la sélection locale.
- Ajout du panneau `scenes-tree-panel`.
- Ajout des états vides `scenes-tree-empty-state` et `scenes-summary-empty-state`.
- Ajout du résumé sélectionné `scenes-selected-summary-<sceneId>`.
- Ajout des champs de projection `storylineId`, `chapterId`, `declaredOutcomes`.
- Les scènes conservent l'ordre du manifest dans la projection.
- Tests V1-04 adaptés en tests V1-05 et enrichis.
- Screenshot Visual Gate V1-05 créé.
- Roadmap mise à jour : V1-05 `DONE`, prochain lot V1-06.

## Fichiers créés/modifiés

Créés par ce lot :

- `reports/narrativeStudio/scenes/ns_scenes_v1_05_scene_tree_panel_read_only.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_05_scene_tree_panel_read_only.png`

Modifiés par ce lot :

- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`

Changements préexistants au début du lot :

- Les fichiers V1-04 non commités listés dans le status initial, dont `ScenesWorkspace`, navigation `scenes`, tests shell V1-04, rapport V1-04 et screenshot V1-04.

## Décisions techniques

- La sélection automatique de la première scène réelle est retenue : utile pour afficher un résumé immédiatement, mais reste locale et non persistée.
- Le groupement V0 utilise les IDs réels `storylineId` / `chapterId`; aucun chapitre Storylines n'est inventé.
- La zone centrale ne lit pas les payloads détaillés : V1-05 reste listing/résumé, pas inspector.
- Le placeholder du graph n'a pas la key `scene-graph-canvas`, afin de prouver qu'aucun canvas graph n'est rendu.

## Micro-polish header réalisé

- Padding du workspace Scènes réduit de `16` à `12`.
- Header local compact : une seule ligne principale, métriques inline, bouton disabled petit.
- Suppression des grosses cards KPI V1-04 dans la vue Scènes.
- Plus d'espace vertical rendu au panneau et au résumé.

## Écarts au prompt éventuels

- Aucun écart fonctionnel.
- Le groupement par storyline/chapter est simple et basé sur les IDs existants, sans résolution vers les titres Storylines. C'est volontaire pour éviter d'inventer des données ou d'élargir le scope.
- Les tests utilisent une fixture locale neutre (`Test Scene Intro`, `Second Test Scene`), uniquement dans `packages/map_editor/test/scenes_workspace_shell_test.dart`.

## Tests exécutés

Test rouge TDD :

```text
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'shows real SceneAsset data in the read-only tree and summary'

Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'scenes-tree-panel'>]: []>
Test failed.
```

Tests verts :

```text
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
00:02 +7: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:05 +19: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
00:02 +3: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
00:01 +3: All tests passed!
```

Note : un lancement parallèle header/projection a échoué sur le startup lock natif Flutter (`objective_c.dylib`). Les commandes ont été relancées en séquentiel et ont passé.

## Résultats exacts

Sortie principale V1-05 :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: NS-SCENES-V1-05 scene tree panel read-only Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-05 scene tree panel read-only Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-05 scene tree panel read-only shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-05 scene tree panel read-only shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-05 scene tree panel read-only disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-05 scene tree panel read-only disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-05 scene tree panel read-only shows real SceneAsset data in the read-only tree and summary
00:02 +4: NS-SCENES-V1-05 scene tree panel read-only shows real SceneAsset data in the read-only tree and summary
00:02 +4: NS-SCENES-V1-05 scene tree panel read-only local scene selection updates summary without mutating project
00:02 +5: NS-SCENES-V1-05 scene tree panel read-only local scene selection updates summary without mutating project
00:02 +5: NS-SCENES-V1-05 scene tree panel read-only Storylines workspace remains selectable
00:02 +6: NS-SCENES-V1-05 scene tree panel read-only Storylines workspace remains selectable
00:02 +6: NS-SCENES-V1-05 scene tree panel read-only writes V1-05 visual gate screenshot
00:02 +7: NS-SCENES-V1-05 scene tree panel read-only writes V1-05 visual gate screenshot
00:02 +7: All tests passed!
```

## Analyze exact

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/features/narrative/application/narrative_workspace_projection.dart test/scenes_workspace_shell_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_studio_header_test.dart test/narrative_workspace_projection_test.dart

Analyzing 6 items...

No issues found! (ran in 1.6s)
```

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_05_scene_tree_panel_read_only.png
```

Commande :

```text
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-05 visual gate screenshot'
00:02 +1: All tests passed!
```

Visible dans la capture : workspace Scènes, panneau gauche `Arborescence des scènes`, deux scènes de test locales, résumé read-only de la scène sélectionnée, header compact, actions désactivées, aucun canvas graph, aucun inspector complet.

## Git status initial

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
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

git diff --stat
19 files changed, 183 insertions(+), 18 deletions(-)

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
?? reports/narrativeStudio/scenes/ns_scenes_v1_05_scene_tree_panel_read_only.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_04_workspace_shell.png
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_05_scene_tree_panel_read_only.png
```

## Git diff --stat

```text
 .../application/editor_workspace_controller.dart   |  4 ++
 .../src/features/editor/state/editor_notifier.dart |  5 +++
 .../features/editor/state/editor_selectors.dart    |  3 ++
 .../editor/state/models/editor_workspace_mode.dart |  1 +
 .../narrative_workspace_projection.dart            | 51 ++++++++++++++++++++++
 .../narrative/state/narrative_workspace_state.dart |  5 +++
 .../lib/src/ui/canvas/editor_canvas_host.dart      |  1 +
 .../lib/src/ui/canvas/narrative_studio_header.dart |  3 +-
 .../lib/src/ui/canvas/narrative_studio_shell.dart  |  3 ++
 .../src/ui/canvas/narrative_studio_sidebar.dart    | 13 +++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 12 ++++-
 .../map_editor/lib/src/ui/editor_shell_page.dart   | 10 +++++
 .../src/ui/panels/narrative_inspector_panel.dart   |  8 ++++
 .../lib/src/ui/panels/narrative_library_panel.dart | 37 ++++++++++++----
 .../lib/src/ui/panels/project_explorer_panel.dart  |  1 +
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |  9 ++++
 .../narrative_overview_shell_navigation_test.dart  | 18 ++++++--
 .../ui/canvas/narrative_studio_header_test.dart    |  3 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  | 46 +++++++++++++++++--
 19 files changed, 214 insertions(+), 19 deletions(-)
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

Fichiers lus : tous les chemins obligatoires existent. Aucun fichier attendu absent.

Commandes principales :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'shows real SceneAsset data in the read-only tree and summary'
flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-05 visual gate screenshot'
flutter test --reporter=compact test/scenes_workspace_shell_test.dart
flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
flutter test --reporter=compact test/narrative_workspace_projection_test.dart
flutter analyze --no-fatal-infos <fichiers cibles V1-05>
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/test/scenes_workspace_shell_test.dart
rg "fakeScenes|demoScenes|hardcodedSceneList|Annonce au port|Selbrume Demo|Maël|Lysa|Port des Brisants|La brume du phare|Le Goélise" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Recherches :

```text
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/test/scenes_workspace_shell_test.dart
Sortie : <vide>

rg "fakeScenes|demoScenes|hardcodedSceneList|Annonce au port|Selbrume Demo|Maël|Lysa|Port des Brisants|La brume du phare|Le Goélise" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
Sortie : <vide>
```

Sections modifiées clefs :

```text
NarrativeSceneSummary ajoute storylineId, chapterId et declaredOutcomes.
_buildSceneSummaries lit ces champs depuis SceneAsset et conserve l'ordre ProjectManifest.scenes.
ScenesWorkspace ajoute _SceneTreePanel, _SceneTreeList, _SceneReadOnlySummary, _SelectedSceneSummary.
Tests ajoutent tree panel, empty state, vraie SceneAsset, sélection locale, non-mutation, absence graph/inspector.
road_map_scenes.md marque V1-05 DONE et recommande V1-06.
```

## Auto-review critique

- Le lot reste strictement read-only.
- La sélection locale est utile et testée sans mutation.
- Le groupement par IDs est honnête mais basique ; V1-06 ou un futur lot pourra résoudre les titres via read model si nécessaire.
- Le placeholder central indique le futur graph sans créer de faux canvas.
- Le screenshot utilise une fixture test neutre, pas une donnée produit.

## Regard critique sur le prompt

Le prompt est clair et bien borné. Le seul point à surveiller est la proximité visuelle avec l'image cible : V1-05 reprend l'esprit `tree + content`, mais ne doit pas copier le Scene Builder complet avant V1-06/V1-07.
